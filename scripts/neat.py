#!/usr/bin/env python3
"""Report Luau code that breaks the RayluauCoder style rules.

Exit codes: 0 neat, 1 findings, 2 path or config error, 3 --fix needs stylua.
"""
import argparse
import fnmatch
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TEMPLATE = ROOT / "templates" / "rojo-project"
CONFIG_NAME = "rayluau-neat.json"
SKIP_DIRS = {".git", "DevPackages", "node_modules", "Packages", "ServerPackages"}
RULES = {
    "line-length",
    "function-length",
    "file-length",
    "nesting",
    "naming",
    "order",
    "commented-code",
    "todo",
    "leftover-print",
}
DEFAULTS = {
    "max_line_length": 120,
    "max_function_lines": 50,
    "max_file_lines": 400,
    "max_nesting": 4,
    "disabled_rules": [],
    "ignore": [],
}
TAB_WIDTH = 4

LONG_OPEN = re.compile(r"\[(=*)\[")
TOKEN = re.compile(
    r"[A-Za-z_]\w*|\d[\w.]*|\.\.\.|\.\.=|\.\.|//=|//|==|~=|<=|>=|\+=|-=|\*=|/=|%=|\^=|::|->|\S"
)
# An "if" after one of these tokens starts an if-expression, which has no matching "end".
BEFORE_IF_EXPRESSION = {
    "=", "(", ",", "[", "{", "return", "and", "or", "not", "+", "-", "*", "/", "%", "^", "#", "..",
    "==", "~=", "<", ">", "<=", ">=", "+=", "-=", "*=", "/=", "%=", "^=", "..=", "//=", "//", "::",
}

SERVICE_LINE = re.compile(r"^\s*local\s+(\w+)\s*(?::[^=]+)?=\s*game:GetService\(\s*[\"'](\w+)[\"']")
REQUIRE_LINE = re.compile(r"^\s*local\s+(\w+)\s*(?::[^=]+)?=\s*require\(")
ALIAS_LINE = re.compile(
    r"^\s*local\s+\w+\s*(?::[^=]+)?=\s*[A-Za-z_][\w.]*"
    r"(?::(?:WaitForChild|FindFirstChild)\(\"\"\)(?:\.[\w.]+)?)*(?:\s*::\s*[\w.?]+)?\s*;?\s*$"
)
LOCAL_NAMES = re.compile(r"\blocal\s+(?!function\b)(.+?)(?:(?<![=~<>])=(?!=)|$)")
FOR_NAMES = re.compile(r"\bfor\s+(.+?)\s+(?:in\b|=)")
FUNCTION_HEAD = re.compile(r"\bfunction\s*([\w.:]*)\s*(?:<[^>]*>)?\s*\((.*)")
TYPE_LINE = re.compile(r"^\s*(?:export\s+)?type\s+(\w+)\s*(?:<[^=]*>)?\s*=")
REMOTE_NEW = re.compile(
    r"\blocal\s+(\w+)\s*=\s*Instance\.new\(\s*[\"'](?:RemoteEvent|UnreliableRemoteEvent|RemoteFunction)[\"']\s*\)"
)
REMOTE_NAME = re.compile(r"^\s*(\w+)\.Name\s*=\s*[\"']([^\"']*)[\"']")
TODO_WORD = re.compile(r"\b(TODO|FIXME|XXX|HACK)\b(.*)")
PRINT_CALL = re.compile(r"(?<![\w.:])print\s*\((.*)$")
STRING_TEXT = re.compile(r"\"((?:[^\"\\]|\\.)*)\"|'((?:[^'\\]|\\.)*)'|`((?:[^`\\]|\\.)*)`")
DEBUG_TEXT = re.compile(
    r"^\W*(?:here|got here|reached|test|testing|debug\b.*|asdf|foo|bar|hi|hello|ok|okay|yes|no|working|works|x|\d+)\W*$",
    re.I,
)
COMMENTED_CODE = re.compile(
    r"""^\s*(?:
        local\s+\w+\s*[:=,] |
        local\s+function\s+\w+ |
        function\s+[\w.:]+\s*\( |
        (?:if|elseif)\s.+\sthen\s*$ |
        (?:for|while)\s.+\sdo\s*$ |
        end[\s)]*$ |
        return\s*$ |
        return\s+(?:true|false|nil|[\w.]*[.:(\[{"'`].*)$ |
        [\w.:\[\]"]+\(.*\)\s*;?\s*$ |
        [A-Za-z_][\w.\[\]"]*\s*(?:=|\+=|-=|\*=|/=|\.\.=)\s*\S.*$
    )""",
    re.X,
)


def find_up(start, name):
    current = start if start.is_dir() else start.parent
    for folder in [current, *current.parents]:
        if (folder / name).is_file():
            return folder
    return None


def collect_files(target):
    if target.is_file():
        return [target]
    files = []
    for path in sorted(target.rglob("*")):
        if path.suffix in (".luau", ".lua") and path.is_file():
            if not SKIP_DIRS.intersection(path.parts):
                files.append(path)
    return files


def stylua_config_args(target):
    if find_up(target, "stylua.toml") or find_up(target, ".stylua.toml"):
        return ["--search-parent-directories"]
    return ["--config-path", str(TEMPLATE / "stylua.toml")]


def load_config(target):
    """Return merged settings. Raises ValueError for a config that cannot be trusted."""
    config = {**DEFAULTS, "root": None}
    folder = find_up(target, CONFIG_NAME)
    if not folder:
        return config
    path = folder / CONFIG_NAME
    try:
        loaded = json.loads(path.read_text(encoding="utf-8"))
    except ValueError as error:
        raise ValueError(f"{path} is not valid JSON: {error}") from error
    if not isinstance(loaded, dict):
        raise ValueError(f"{path} must contain a JSON object")
    for key, value in loaded.items():
        if key not in DEFAULTS:
            raise ValueError(f"{path}: unknown setting {key!r}")
        if not isinstance(value, type(DEFAULTS[key])) or isinstance(value, bool):
            raise ValueError(f"{path}: wrong type for {key!r}")
    unknown = set(loaded.get("disabled_rules", [])) - RULES
    if unknown:
        raise ValueError(f"{path}: unknown rules {sorted(unknown)}")
    config.update(loaded)
    config["root"] = folder
    return config


def mask(text):
    """Return code lines with string contents and comments removed, plus the comments.

    Each comment is (line number, text, kind), where kind is "line", "trailing", or "block".
    """
    out, comments = [], []
    index, line, length = 0, 1, len(text)
    line_has_code = False
    while index < length:
        char = text[index]
        if text.startswith("--", index):
            long_open = LONG_OPEN.match(text, index + 2)
            if long_open:
                close = "]" + long_open.group(1) + "]"
                end = text.find(close, long_open.end())
                end = length if end < 0 else end + len(close)
                body = text[index:end]
                for offset, part in enumerate(body.split("\n")):
                    comments.append((line + offset, part, "block"))
                newlines = body.count("\n")
                out.append("\n" * newlines)
                line += newlines
                index = end
                continue
            end = text.find("\n", index)
            end = length if end < 0 else end
            comments.append((line, text[index + 2 : end], "trailing" if line_has_code else "line"))
            index = end
            continue
        long_open = LONG_OPEN.match(text, index) if char == "[" else None
        if long_open:
            close = "]" + long_open.group(1) + "]"
            end = text.find(close, long_open.end())
            end = length if end < 0 else end + len(close)
        elif char in "\"'`":
            end = index + 1
            while end < length and text[end] != char:
                if text[end] == "\\":
                    end += 1
                elif text[end] == "\n" and char != "`":
                    break
                end += 1
            end = min(end + 1, length)
        else:
            end = None
        if end is not None:
            newlines = text.count("\n", index, end)
            out.append('""' + "\n" * newlines)
            line += newlines
            index = end
            line_has_code = newlines == 0
            continue
        if char == "\n":
            line += 1
            line_has_code = False
        elif not char.isspace():
            line_has_code = True
        out.append(char)
        index += 1
    return "".join(out).split("\n"), comments


def nesting_depth(stack):
    depth = sum(1 for entry in stack if entry["kind"] != "expression")
    first = next((entry for entry in stack if entry["kind"] != "expression"), None)
    return depth - 1 if first and first["kind"] == "function" else depth


def scan_blocks(code_lines, max_nesting):
    """Walk the block structure. Returns functions, nesting findings, and depth at each line start."""
    stack, functions, too_deep = [], [], []
    tokens = [(number, word) for number, line in enumerate(code_lines, 1) for word in TOKEN.findall(line)]
    block_at_line, bracket_at_line = {}, {}
    brackets, previous, was_too_deep = 0, None, False

    for position, (number, word) in enumerate(tokens):
        block_at_line.setdefault(number, sum(1 for entry in stack if entry["kind"] != "expression"))
        bracket_at_line.setdefault(number, brackets)
        if word in ("(", "{", "["):
            brackets += 1
        elif word in (")", "}", "]"):
            brackets = max(0, brackets - 1)
        elif word == "function":
            name_tokens = []
            for _, following in tokens[position + 1 :]:
                if following in ("(", "<"):
                    break
                name_tokens.append(following)
            stack.append({"kind": "function", "line": number, "name": "".join(name_tokens) or "anonymous function"})
        elif word == "if":
            inside_expression = previous in ("then", "else") and stack and stack[-1]["kind"] == "expression"
            kind = "expression" if previous in BEFORE_IF_EXPRESSION or inside_expression else "if"
            stack.append({"kind": kind, "line": number})
        elif word == "else" and stack and stack[-1]["kind"] == "expression":
            stack.pop()
        elif word in ("do", "repeat"):
            stack.append({"kind": word, "line": number})
        elif word == "until":
            if stack and stack[-1]["kind"] == "repeat":
                stack.pop()
        elif word == "end" and stack:
            entry = stack.pop()
            if entry["kind"] == "function":
                functions.append((entry["name"], entry["line"], number))
        depth = nesting_depth(stack)
        if depth > max_nesting and not was_too_deep:
            too_deep.append((number, depth))
        was_too_deep = depth > max_nesting
        previous = word
    return functions, too_deep, block_at_line, bracket_at_line


def split_names(text):
    names, depth, current = [], 0, ""
    for char in text:
        if char in "({[<":
            depth += 1
        elif char in ")}]>":
            depth -= 1
        if char == "," and depth <= 0:
            names.append(current)
            current = ""
        else:
            current += char
    names.append(current)
    cleaned = []
    for name in names:
        name = name.split(":", 1)[0].strip()
        if re.fullmatch(r"[A-Za-z_]\w*", name):
            cleaned.append(name)
    return cleaned


def bad_variable_name(name):
    if name.startswith("_") or "_" not in name:
        return False
    return not re.fullmatch(r"[A-Z][A-Z0-9_]*", name)


def signature_params(rest):
    depth, end = 1, None
    for position, char in enumerate(rest):
        if char in "({[":
            depth += 1
        elif char in ")}]":
            depth -= 1
            if depth == 0:
                end = position
                break
    return split_names(rest[:end] if end is not None else rest)


def naming_findings(code_lines, raw_lines):
    findings, remotes = [], set()
    for number, (code, raw) in enumerate(zip(code_lines, raw_lines), 1):
        for match in LOCAL_NAMES.finditer(code):
            for name in split_names(match.group(1)):
                if bad_variable_name(name):
                    findings.append((number, f"'{name}' should be camelCase, or SCREAMING_SNAKE_CASE for a constant"))
        for match in FOR_NAMES.finditer(code):
            for name in split_names(match.group(1)):
                if bad_variable_name(name):
                    findings.append((number, f"loop variable '{name}' should be camelCase"))
        for match in FUNCTION_HEAD.finditer(code):
            last = re.split(r"[.:]", match.group(1))[-1]
            if last and bad_variable_name(last):
                findings.append((number, f"function '{match.group(1)}' should use camelCase"))
            for name in signature_params(match.group(2)):
                if bad_variable_name(name):
                    findings.append((number, f"parameter '{name}' should be camelCase"))
        type_match = TYPE_LINE.match(code)
        if type_match and not type_match.group(1)[0].isupper():
            findings.append((number, f"type '{type_match.group(1)}' should be PascalCase"))
        service = SERVICE_LINE.match(raw)
        if service and service.group(1) != service.group(2):
            findings.append((number, f"service local '{service.group(1)}' should be named '{service.group(2)}'"))
        module = REQUIRE_LINE.match(code)
        if module and module.group(1)[0].islower():
            findings.append((number, f"module local '{module.group(1)}' should be PascalCase"))
        remote = REMOTE_NEW.search(raw)
        if remote:
            remotes.add(remote.group(1))
        remote_name = REMOTE_NAME.match(raw)
        if remote_name and remote_name.group(1) in remotes:
            if not re.fullmatch(r"[A-Z][A-Za-z0-9]*", remote_name.group(2)):
                findings.append((number, f"remote name '{remote_name.group(2)}' should be PascalCase"))
    return findings


def order_findings(code_lines, block_at_line, bracket_at_line):
    findings, other_line, seen_require = [], None, False
    for number, code in enumerate(code_lines, 1):
        if not code.strip() or block_at_line.get(number, 0) or bracket_at_line.get(number, 0):
            continue
        is_service = "game:GetService(" in code and re.match(r"^\s*local\s", code)
        is_require = REQUIRE_LINE.match(code)
        if is_service:
            if other_line:
                findings.append((number, f"service is below other code (line {other_line}). Move it to the top"))
            elif seen_require:
                findings.append((number, "service is below a require. Put services first"))
        elif is_require:
            seen_require = True
            if other_line:
                findings.append((number, f"require is below other code (line {other_line}). Move it to the top"))
        elif not ALIAS_LINE.match(code) and other_line is None:
            other_line = number
    return findings


def comment_findings(comments):
    findings = []
    for number, text, kind in comments:
        todo = TODO_WORD.search(text)
        if todo and len(re.findall(r"[A-Za-z0-9']+", todo.group(2))) < 3:
            findings.append(("todo", number, f"{todo.group(1)} needs more detail, or remove it"))
        if kind != "line" or text.startswith(("-", "!")):
            continue
        if COMMENTED_CODE.match(text):
            findings.append(("commented-code", number, "looks like commented-out code. Delete it"))
    return findings


def print_findings(code_lines, raw_lines):
    findings = []
    for number, (code, raw) in enumerate(zip(code_lines, raw_lines), 1):
        if not PRINT_CALL.search(code):
            continue
        arguments = PRINT_CALL.search(raw)
        if not arguments:
            continue
        text = arguments.group(1).strip()
        if not text:
            continue
        string = STRING_TEXT.search(text)
        if string is None:
            findings.append((number, "print looks like leftover debugging. Remove it or add a clear message"))
            continue
        content = next(part for part in string.groups() if part is not None)
        if DEBUG_TEXT.match(content):
            findings.append((number, f'print("{content}") looks like leftover debugging. Remove it'))
    return findings


def ignored_lines(comments):
    ignored = set()
    for number, text, kind in comments:
        if "neat: ignore" in text and "neat: ignore-file" not in text:
            ignored.add(number)
            if kind == "line":
                ignored.add(number + 1)
    return ignored


def scan_text(text, config):
    """Return (rule, line, message) findings for one file's text."""
    raw_lines = text.split("\n")
    code_lines, comments = mask(text)
    if any("neat: ignore-file" in comment[1] for comment in comments):
        return []
    while len(code_lines) < len(raw_lines):
        code_lines.append("")

    functions, too_deep, block_at_line, bracket_at_line = scan_blocks(code_lines, config["max_nesting"])
    findings = []
    for number, line in enumerate(raw_lines, 1):
        width = len(line.rstrip("\r").expandtabs(TAB_WIDTH))
        if width > config["max_line_length"] and "http" not in line:
            findings.append(("line-length", number, f"line is {width} characters (limit {config['max_line_length']})"))
    total = len(raw_lines) - (1 if raw_lines and not raw_lines[-1].strip() else 0)
    if total > config["max_file_lines"]:
        findings.append(("file-length", 1, f"file is {total} lines (limit {config['max_file_lines']}). Split it"))
    for name, start, end in functions:
        size = end - start + 1
        if size > config["max_function_lines"]:
            limit = config["max_function_lines"]
            findings.append(("function-length", start, f"{name} is {size} lines (limit {limit}). Split it"))
    for number, depth in too_deep:
        limit = config["max_nesting"]
        findings.append(("nesting", number, f"nesting reaches {depth} levels (limit {limit}). Use early returns or helpers"))
    findings += [("naming", number, message) for number, message in naming_findings(code_lines, raw_lines)]
    findings += [("order", number, message) for number, message in order_findings(code_lines, block_at_line, bracket_at_line)]
    findings += comment_findings(comments)
    findings += [("leftover-print", number, message) for number, message in print_findings(code_lines, raw_lines)]

    ignored = ignored_lines(comments)
    disabled = set(config["disabled_rules"])
    kept = [finding for finding in findings if finding[0] not in disabled and finding[1] not in ignored]
    return sorted(kept, key=lambda finding: (finding[1], finding[0]))


def is_ignored(path, config):
    if not config["root"] or not config["ignore"]:
        return False
    try:
        relative = path.relative_to(config["root"]).as_posix()
    except ValueError:
        return False
    return any(fnmatch.fnmatch(relative, pattern) for pattern in config["ignore"])


def scan_files(files, config):
    lines = []
    for path in files:
        if is_ignored(path, config):
            continue
        text = path.read_text(encoding="utf-8", errors="replace").replace("\r\n", "\n")
        for rule, number, message in scan_text(text, config):
            lines.append(f"{path}:{number}: {rule}: {message}")
    return lines


def fix_formatting(target):
    """Run StyLua only. This must never restructure code."""
    stylua = shutil.which("stylua")
    if not stylua:
        print("ERROR: --fix needs stylua, and it is not installed. No files were changed.", file=sys.stderr)
        print("Run scripts/run setup for install steps.", file=sys.stderr)
        return False
    result = subprocess.run(
        [stylua, *stylua_config_args(target), str(target)],
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if result.returncode != 0:
        print(f"ERROR: stylua could not format the code:\n{result.stdout}{result.stderr}", file=sys.stderr)
        return False
    print("[stylua] formatted. Formatting only: no code was restructured.")
    return True


def main():
    parser = argparse.ArgumentParser(description="Check Luau files against the neat code rules.")
    parser.add_argument("path", nargs="?", default=".", help="file or folder (default: current folder)")
    parser.add_argument("--fix", action="store_true", help="format with StyLua first. Changes formatting only")
    args = parser.parse_args()
    target = Path(args.path).resolve()
    if not target.exists():
        print(f"ERROR: path not found: {target}", file=sys.stderr)
        return 2
    try:
        config = load_config(target)
    except ValueError as error:
        print(f"ERROR: {error}", file=sys.stderr)
        return 2
    if args.fix and not fix_formatting(target):
        return 3

    files = collect_files(target)
    findings = scan_files(files, config)
    print(f"RayluauCoder neat: {target} ({len(files)} Luau file(s))")
    for line in findings:
        print(f"  {line}")
    if findings:
        print(f"RESULT: NOT NEAT. {len(findings)} finding(s).")
        return 1
    print("RESULT: NEAT.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
