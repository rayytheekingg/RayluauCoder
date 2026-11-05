#!/usr/bin/env python3
"""Check Luau code with a type checker, selene, stylua, the neat rules, and a deprecated-API scan.

Type checking uses luau-lsp with Roblox definitions, and falls back to luau-analyze.
Exit codes: 0 pass, 1 problems found, 2 no problems found but a tool was skipped.
"""
import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import api_lookup
import neat
from neat import TEMPLATE, collect_files, find_up

MAX_OUTPUT_LINES = 40
TIMEOUT_SECONDS = 300
BATCH_SIZE = 100

ROBLOX_GLOBALS = (
    api_lookup.LIBRARIES
    | api_lookup.DATATYPES
    | api_lookup.GLOBALS
    | {"Enum", "Instance", "UserSettings"}
)
ANALYZE_LINE = re.compile(r"^(.+?)\((\d+),(\d+)\): (\w+): (.*)$")
ANSI = re.compile(r"\x1b\[[0-9;]*m")
LSP_LOG_LINE = re.compile(r"^\[(INFO|WARN)\]")
LSP_MISSING_KEY = re.compile(r"Key '[^']+' not found in (?:external type|class) '(\w+)'")
CHILD_CONTAINER_CLASSES = {
    "Actor", "Backpack", "Configuration", "Folder", "Instance", "Lighting", "LocalScript", "Model",
    "ModuleScript", "PlayerGui", "PlayerScripts", "ReplicatedFirst", "ReplicatedStorage", "Script",
    "ScreenGui", "ServerScriptService", "ServerStorage", "SoundService", "StarterCharacterScripts", "StarterGui",
    "StarterPack", "StarterPlayer", "StarterPlayerScripts", "Teams", "Tool", "Workspace",
}

# Each rule is (pattern, advice). Rules run on code with comments and string contents removed.
CODE_RULES = [
    (r"(?<![\w.:])wait\s*\(", "wait is legacy. Use task.wait."),
    (r"(?<![\w.:])spawn\s*\(", "spawn is legacy. Use task.spawn."),
    (r"(?<![\w.:])delay\s*\(", "delay is legacy. Use task.delay."),
    (r"(?<![\w.:])tick\s*\(", "tick is discouraged. Use os.clock or workspace:GetServerTimeNow."),
    (r"(?<![\w.:])(getfenv|setfenv)\s*\(", "getfenv and setfenv disable Luau optimizations."),
    (r"(?<![\w.:])loadstring\s*\(", "loadstring is risky and disabled by default."),
    (r":(connect|disconnect)\s*\(", "Lowercase signal methods are deprecated. Use :Connect or :Disconnect."),
    (r":Remove\s*\(", "Instance:Remove is deprecated. Use :Destroy."),
    (r":(SetPrimaryPartCFrame)\s*\(", "SetPrimaryPartCFrame is deprecated. Use :PivotTo."),
    (r":(GetPrimaryPartCFrame)\s*\(", "GetPrimaryPartCFrame is deprecated. Use :GetPivot."),
    (r":FindPartOnRay\w*\s*\(", "FindPartOnRay is deprecated. Use workspace:Raycast."),
    (r":FindPartsInRegion3\w*\s*\(", "FindPartsInRegion3 is deprecated. Use workspace:GetPartBoundsInBox."),
    (r"[Hh]umanoid:LoadAnimation\s*\(", "Humanoid:LoadAnimation is deprecated. Use Animator:LoadAnimation."),
    (r"\.KeyDown\b|\.KeyUp\b", "Mouse key events are deprecated. Use UserInputService."),
    (r"Instance\.new\s*\(\s*\"\"\s*,", "Set Parent last. Do not use the Instance.new parent argument."),
    (r":InvokeClient\s*\(", "InvokeClient can hang the server. Use RemoteEvents."),
]
# These rules need the string contents.
TEXT_RULES = [
    (
        r"Instance\.new\s*\(\s*[\"'](Body\w+|RocketPropulsion|Message|Hint|Hat)[\"']",
        "Deprecated class. Check it with api-lookup and use the listed replacement.",
    ),
]


def run_tool(command, cwd=None):
    result = subprocess.run(
        command,
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=TIMEOUT_SECONDS,
    )
    return result.returncode, ANSI.sub("", result.stdout + result.stderr)


def normal_path(path):
    return str(path).replace("\\", "/")


def parse_analyze_output(output):
    entries = []
    for line in output.splitlines():
        if not line.strip():
            continue
        match = ANALYZE_LINE.match(line)
        if match:
            path, row, column, kind, message = match.groups()
            entries.append(
                {
                    "path": normal_path(path),
                    "line": int(row),
                    "column": int(column),
                    "kind": kind,
                    "message": message,
                    "extra": [],
                }
            )
        elif entries:
            entries[-1]["extra"].append(line)
        else:
            entries.append({"path": None, "message": line, "extra": []})
    return entries


def analyze(exe, paths):
    entries = []
    for start in range(0, len(paths), BATCH_SIZE):
        _, output = run_tool([exe, *paths[start : start + BATCH_SIZE]])
        entries += parse_analyze_output(output)
    return entries


def roblox_name(message, classes):
    """Return (kind, name) when an unknown name is part of Roblox, not a typo."""
    match = re.match(r"Unknown (global|type) '([\w.]+)'", message)
    if not match:
        return None
    kind, name = match.groups()
    if kind == "global" and (name in ROBLOX_GLOBALS or name in classes):
        return kind, name
    if kind == "type" and (name in classes or name in api_lookup.DATATYPES or name == "Instance"):
        return kind, name
    return None


def build_prelude(names):
    parts = [f"type {name} = any;" for kind, name in sorted(names) if kind == "type" and "." not in name]
    parts += [f"local {name}: any = nil;" for kind, name in sorted(names) if kind == "global"]
    return " ".join(parts) + " " if parts else ""


def add_prelude(text, prelude):
    """Add the prelude after any --! directives without changing line numbers."""
    lines = text.split("\n")
    index = 0
    for number, line in enumerate(lines):
        stripped = line.strip()
        if stripped.startswith("--!"):
            index = number + 1
        elif stripped and (not stripped.startswith("--") or stripped.startswith("--[")):
            break
    if index == len(lines):
        lines.append("")
    lines[index] = prelude + lines[index]
    return "\n".join(lines), index + 1


def format_entry(entry, temp_root, base, offsets):
    if entry["path"] is None:
        return [entry["message"]]
    path = entry["path"]
    column = entry["column"]
    if path.lower().startswith(temp_root.lower()):
        relative = path[len(temp_root) :]
        prelude_line, prelude_length = offsets.get(relative.lower(), (0, 0))
        if entry["line"] == prelude_line and column > prelude_length:
            column -= prelude_length
        path = normal_path(base) + relative
    return [f"{path}({entry['line']},{column}): {entry['kind']}: {entry['message']}", *entry["extra"]]


def run_luau_analyze(exe, files, base):
    """Plain luau-analyze has no Roblox definitions, so check temp copies that declare Roblox names as any."""
    classes = api_lookup.class_names()
    names_by_file = {}
    for entry in analyze(exe, [str(path) for path in files]):
        name = roblox_name(entry["message"], classes)
        if name and entry["path"]:
            names_by_file.setdefault(entry["path"].lower(), set()).add(name)

    problems, offsets = [], {}
    with tempfile.TemporaryDirectory(prefix="rayluau-") as temp:
        temp_root = normal_path(temp)
        config_dir = find_up(base, ".luaurc")
        if config_dir:
            shutil.copy(config_dir / ".luaurc", Path(temp) / ".luaurc")
        copies = []
        for path in files:
            relative = path.relative_to(base)
            copy = Path(temp) / relative
            copy.parent.mkdir(parents=True, exist_ok=True)
            text = path.read_text(encoding="utf-8", errors="replace")
            prelude = build_prelude(names_by_file.get(normal_path(path).lower(), set()))
            if prelude:
                text, line = add_prelude(text, prelude)
                offsets["/" + relative.as_posix().lower()] = (line, len(prelude))
            copy.write_text(text, encoding="utf-8")
            copies.append(str(copy))
        for entry in analyze(exe, copies):
            message = entry["message"]
            if message.startswith("Unknown require") or roblox_name(message, classes):
                continue
            problems += format_entry(entry, temp_root, base, offsets)

    count = len(set().union(*names_by_file.values())) if names_by_file else 0
    note = f"treated {count} Roblox names as any, so Roblox API calls are not type-checked by this tool"
    return problems, note


def prepare_sourcemap(base, temp):
    """Return (working folder, sourcemap path or None, description). Prefer a fresh Rojo sourcemap."""
    rojo = shutil.which("rojo")
    project = find_up(base, "default.project.json")
    if rojo and project:
        output = Path(temp) / "sourcemap.json"
        try:
            code, _ = run_tool([rojo, "sourcemap", "default.project.json", "--output", str(output)], cwd=project)
        except (OSError, subprocess.SubprocessError):
            code = 1
        if code == 0 and output.exists():
            return project, output, "sourcemap generated with rojo"
    existing = find_up(base, "sourcemap.json")
    if existing:
        return existing, existing / "sourcemap.json", "existing sourcemap.json"
    return base, None, "no sourcemap"


def is_unresolved_child(message):
    """Without a sourcemap, luau-lsp cannot know about children that exist only in the place."""
    if message.startswith("Unknown require") or message == "Value of type 'Instance?' could be nil":
        return True
    match = LSP_MISSING_KEY.match(message)
    return bool(match and match.group(1) in CHILD_CONTAINER_CLASSES)


def run_luau_lsp(exe, files, base):
    definitions = api_lookup.definitions_path()
    entries, unresolved = [], 0
    with tempfile.TemporaryDirectory(prefix="rayluau-") as temp:
        root, sourcemap, description = prepare_sourcemap(base, temp)
        command = [exe, "analyze", "--platform=roblox", f"--definitions=@roblox={definitions}"]
        if sourcemap:
            command.append(f"--sourcemap={sourcemap}")
        relative = [os.path.relpath(path, root) for path in files]
        for start in range(0, len(relative), BATCH_SIZE):
            _, output = run_tool([*command, *relative[start : start + BATCH_SIZE]], cwd=root)
            kept = "\n".join(line for line in output.splitlines() if not LSP_LOG_LINE.match(line))
            entries += parse_analyze_output(kept)

    problems = []
    for entry in entries:
        if entry["path"] is None:
            problems.append(entry["message"])
        elif not sourcemap and is_unresolved_child(entry["message"]):
            unresolved += 1
        else:
            path = normal_path(Path(root) / entry["path"])
            problems += [f"{path}({entry['line']},{entry['column']}): {entry['kind']}: {entry['message']}", *entry["extra"]]
    note = f"Roblox definitions, {description}"
    if not sourcemap:
        note += f"; {unresolved} child or require references could not be resolved. Add a Rojo sourcemap to resolve them"
    return problems, note


def run_type_check(files, base):
    """Return (method name, problems, note), or None when no type checker could run."""
    lsp = shutil.which("luau-lsp")
    if lsp:
        try:
            return ("luau-lsp", *run_luau_lsp(lsp, files, base))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"[luau-lsp] could not run: {error}. Falling back to luau-analyze.")
    analyzer = shutil.which("luau-analyze")
    if analyzer:
        try:
            return ("luau-analyze", *run_luau_analyze(analyzer, files, base))
        except (OSError, subprocess.SubprocessError) as error:
            print(f"[luau-analyze] could not run: {error}")
    return None


def run_selene(exe, target):
    config_dir = find_up(target, "selene.toml")
    command = [exe, "--display-style=quiet"]
    if not config_dir:
        command += ["--config", str(TEMPLATE / "selene.toml")]
    code, output = run_tool([*command, str(target)], cwd=config_dir)
    problems = [line for line in output.splitlines() if re.search(r"\b(warning|error)\[", line)]
    if code != 0 and not problems:
        problems = [line for line in output.splitlines() if line.strip()] or [f"selene exited with {code}"]
    return problems, "" if config_dir else "used the template selene.toml"


def run_stylua(exe, target):
    config_args = neat.stylua_config_args(target)
    code, output = run_tool([exe, "--check", "--color", "never", *config_args, str(target)])
    if code == 0:
        return [], "used the template stylua.toml" if "--config-path" in config_args else ""
    problems = [line for line in output.splitlines() if line.strip()] or [f"stylua exited with {code}"]
    return problems, "fix with: scripts/run neat <path> --fix"


def blank_long_blocks(text):
    def blank(match):
        return "\n" * match.group(0).count("\n")

    return re.sub(r"(?:--)?\[(=*)\[.*?\]\1\]", blank, text, flags=re.S)


def strip_line(line):
    code = re.sub(r"\"(?:[^\"\\]|\\.)*\"|'(?:[^'\\]|\\.)*'|`(?:[^`\\]|\\.)*`", '""', line)
    return code.split("--", 1)[0]


def scan_deprecated(files):
    problems = []
    for path in files:
        text = path.read_text(encoding="utf-8", errors="replace")
        for number, line in enumerate(blank_long_blocks(text).splitlines(), 1):
            if line.lstrip().startswith("--"):
                continue
            code = strip_line(line)
            hits = [advice for pattern, advice in CODE_RULES if re.search(pattern, code)]
            hits += [advice for pattern, advice in TEXT_RULES if re.search(pattern, line)]
            problems += [f"{path}:{number}: {advice}" for advice in hits]
    return problems, "built-in pattern scan; it does not check syntax or types"


def show(name, problems, note):
    detail = f" ({note})" if note else ""
    print(f"[{name}] {len(problems)} problem(s){detail}")
    for line in problems[:MAX_OUTPUT_LINES]:
        print(f"  {line}")
    if len(problems) > MAX_OUTPUT_LINES:
        print(f"  ... {len(problems) - MAX_OUTPUT_LINES} more lines not shown")


def main():
    parser = argparse.ArgumentParser(description="Check Luau files or folders.")
    parser.add_argument("path", nargs="?", default=".", help="file or folder to check (default: current folder)")
    target = Path(parser.parse_args().path).resolve()
    if not target.exists():
        print(f"ERROR: path not found: {target}", file=sys.stderr)
        return 1
    files = collect_files(target)
    print(f"RayluauCoder check: {target} ({len(files)} Luau file(s))")
    if not files:
        print("RESULT: NOT CHECKED. No .luau or .lua files found.")
        return 2

    try:
        neat_config = neat.load_config(target)
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 1

    total, skipped = 0, []
    base = target if target.is_dir() else target.parent
    type_check = run_type_check(files, base)
    if type_check:
        method, problems, note = type_check
        print(f"[types] method: {method}")
        show(method, problems, note)
        total += len(problems)
    else:
        method = None
        skipped.append("type checker (luau-lsp or luau-analyze)")
        print("[types] SKIPPED: neither luau-lsp nor luau-analyze is installed")

    tools = [
        ("selene", lambda exe: run_selene(exe, target)),
        ("stylua", lambda exe: run_stylua(exe, target)),
    ]
    for name, runner in tools:
        exe = shutil.which(name)
        if not exe:
            skipped.append(name)
            print(f"[{name}] SKIPPED: not installed")
            continue
        try:
            problems, note = runner(exe)
        except (OSError, subprocess.SubprocessError) as error:
            skipped.append(name)
            print(f"[{name}] SKIPPED: could not run: {error}")
            continue
        show(name, problems, note)
        total += len(problems)

    problems = neat.scan_files(files, neat_config)
    show("neat", problems, "built-in style rules")
    total += len(problems)

    problems, note = scan_deprecated(files)
    show("deprecated-scan", problems, note)
    total += len(problems)

    if method is None:
        print("WARNING: syntax and types were NOT checked.")
    elif method == "luau-analyze":
        print("WARNING: fallback used, so Roblox API calls were NOT type-checked. Install luau-lsp to check them.")
    if total:
        suffix = f" Not run: {', '.join(skipped)}." if skipped else ""
        print(f"RESULT: FAIL. {total} problem(s).{suffix}")
        return 1
    if skipped:
        print(f"RESULT: INCOMPLETE. No problems found, but not run: {', '.join(skipped)}.")
        print("Run scripts/run setup for install steps.")
        return 2
    print("RESULT: PASS. Runtime behaviour was not tested. Test it in Roblox Studio.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
