#!/usr/bin/env python3
"""Look up Roblox classes, members and enums in a cached copy of Roblox's API dump.

Exit codes: 0 found, 1 not found, 2 found but deprecated, 3 exists outside the dump.
"""
import argparse
import difflib
import json
import os
import re
import shutil
import sys
import time
import urllib.request
from pathlib import Path

VERSION_URL = "https://setup.rbxcdn.com/versionQTStudio"
DUMP_URL = "https://setup.rbxcdn.com/{version}-Full-API-Dump.json"
DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau"
DEFINITIONS_NAME = "globalTypes.None.d.luau"
DOCS = "https://create.roblox.com/docs/reference/engine"
USER_AGENT = "RayluauCoder/1.0.4"
MAX_AGE_DAYS = 14

EXIT_FOUND, EXIT_NOT_FOUND, EXIT_DEPRECATED, EXIT_OUTSIDE_DUMP = 0, 1, 2, 3

# The dump only covers engine classes and enums, so these need their own answer.
LIBRARIES = {
    "bit32", "buffer", "coroutine", "debug", "math", "os", "string", "table", "task", "utf8", "vector",
}
DATATYPES = {
    "Axes", "BrickColor", "CFrame", "CatalogSearchParams", "Color3", "ColorSequence",
    "ColorSequenceKeypoint", "Content", "DateTime", "DockWidgetPluginGuiInfo", "EnumItem", "Enums",
    "Faces", "FloatCurveKey", "Font", "NumberRange", "NumberSequence", "NumberSequenceKeypoint",
    "OverlapParams", "PathWaypoint", "PhysicalProperties", "RBXScriptConnection", "RBXScriptSignal",
    "Random", "Ray", "RaycastParams", "RaycastResult", "Rect", "Region3", "Region3int16",
    "RotationCurveKey", "Secret", "SharedTable", "TweenInfo", "UDim", "UDim2", "Vector2",
    "Vector2int16", "Vector3", "Vector3int16",
}
GLOBALS = {
    "assert", "collectgarbage", "delay", "elapsedTime", "error", "game", "gcinfo", "getfenv",
    "getmetatable", "ipairs", "loadstring", "newproxy", "next", "pairs", "pcall", "plugin", "print",
    "rawequal", "rawget", "rawlen", "rawset", "require", "script", "select", "setfenv", "setmetatable",
    "settings", "shared", "spawn", "stats", "tick", "time", "tonumber", "tostring", "type", "typeof",
    "unpack", "version", "wait", "warn", "workspace", "xpcall",
}
LEGACY_GLOBALS = {
    "delay": "task.delay",
    "spawn": "task.spawn",
    "tick": "os.clock or workspace:GetServerTimeNow",
    "wait": "task.wait",
}


def cache_dir():
    override = os.environ.get("RAYLUAU_CACHE")
    if override:
        return Path(override)
    base = os.environ.get("LOCALAPPDATA") or os.environ.get("XDG_CACHE_HOME")
    return Path(base) / "rayluaucoder" if base else Path.home() / ".cache" / "rayluaucoder"


def dump_path():
    return cache_dir() / "Full-API-Dump.json"


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def download():
    version = fetch(VERSION_URL).decode("ascii").strip()
    if not re.fullmatch(r"version-[0-9a-f]+", version):
        raise ValueError(f"unexpected Roblox version string: {version!r}")
    url = DUMP_URL.format(version=version)
    print(f"Downloading Roblox API dump {version} from setup.rbxcdn.com ...", file=sys.stderr)
    raw = fetch(url)
    json.loads(raw)
    path = dump_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    temp.write_bytes(raw)
    temp.replace(path)
    (path.parent / "version.txt").write_text(version, encoding="ascii")
    print(f"Cached {len(raw) / 1048576:.1f} MB at {path}", file=sys.stderr)


def download_definitions():
    print("Downloading Roblox type definitions from the luau-lsp repo ...", file=sys.stderr)
    raw = fetch(DEFINITIONS_URL)
    path = cache_dir() / DEFINITIONS_NAME
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    temp.write_bytes(raw)
    temp.replace(path)
    print(f"Cached {len(raw) / 1048576:.1f} MB at {path}", file=sys.stderr)


def definitions_path():
    """Return the Roblox definitions file for luau-lsp, downloading it on first use."""
    path = cache_dir() / DEFINITIONS_NAME
    if not path.exists():
        download_definitions()
    age_days = (time.time() - path.stat().st_mtime) / 86400
    if age_days > MAX_AGE_DAYS:
        print(f"Note: Roblox definitions are {age_days:.0f} days old. Refresh with api-lookup --update.", file=sys.stderr)
    return path


def load_dump(allow_download=True):
    path = dump_path()
    if not path.exists():
        if not allow_download:
            return None
        download()
    age_days = (time.time() - path.stat().st_mtime) / 86400
    if age_days > MAX_AGE_DAYS:
        print(f"Note: API dump is {age_days:.0f} days old. Refresh with --update.", file=sys.stderr)
    return json.loads(path.read_text(encoding="utf-8"))


def class_names():
    """Return known class and enum names for check.py, or an empty set when offline."""
    try:
        dump = load_dump()
    except (OSError, ValueError) as error:
        print(f"Note: API dump unavailable ({error}).", file=sys.stderr)
        return set()
    return {c["Name"] for c in dump["Classes"]} | {f"Enum.{e['Name']}" for e in dump["Enums"]}


def tag_names(entry):
    return [t for t in entry.get("Tags", []) if isinstance(t, str)]


def preferred(entry):
    for tag in entry.get("Tags", []):
        if isinstance(tag, dict) and tag.get("PreferredDescriptorName"):
            return tag["PreferredDescriptorName"]
    return None


def params(member):
    parts = []
    for parameter in member.get("Parameters", []):
        text = f"{parameter['Name']}: {parameter['Type']['Name']}"
        if "Default" in parameter:
            text += f" = {parameter['Default']}"
        parts.append(text)
    return ", ".join(parts)


def signature(owner, member):
    kind = member["MemberType"]
    name = member["Name"]
    if kind == "Property":
        return f"Property {owner}.{name}: {member['ValueType']['Name']}"
    if kind == "Event":
        return f"Event {owner}.{name}({params(member)})"
    returns = member["ReturnType"]["Name"]
    returns = "()" if returns == "null" else returns
    if kind == "Function":
        return f"Function {owner}:{name}({params(member)}) -> {returns}"
    return f"Callback {owner}.{name}({params(member)}) -> {returns}"


def security_levels(member):
    security = member.get("Security", "None")
    values = security.values() if isinstance(security, dict) else [security]
    return sorted({v for v in values if v != "None"})


def report_member(owner, member, requested_class):
    print(signature(owner, member))
    if owner != requested_class:
        print(f"Inherited by {requested_class} from {owner}")
    tags = tag_names(member)
    if tags:
        print("Tags: " + ", ".join(tags))
    levels = security_levels(member)
    if levels:
        print("Security: " + ", ".join(levels) + " (not callable from normal game scripts)")
    if "NotScriptable" in tags:
        print("WARNING: not scriptable.")
    print(f"Docs: {DOCS}/classes/{owner}#{member['Name']}")
    if "Deprecated" in tags:
        replacement = preferred(member)
        print("STATUS: DEPRECATED" + (f". Use {replacement}." if replacement else "."))
        return EXIT_DEPRECATED
    print("STATUS: OK")
    return EXIT_FOUND


def report_class(cls, classes, show_members):
    print(f"Class {cls['Name']}" + (f" : {cls['Superclass']}" if cls.get("Superclass") else ""))
    tags = tag_names(cls)
    if tags:
        print("Tags: " + ", ".join(tags))
    print(f"Docs: {DOCS}/classes/{cls['Name']}")
    if show_members:
        for owner, member in chain_members(cls, classes):
            if "Deprecated" not in tag_names(member) and "Hidden" not in tag_names(member):
                print("  " + signature(owner, member))
    if "Deprecated" in tags:
        replacement = preferred(cls)
        print("STATUS: DEPRECATED" + (f". Use {replacement}." if replacement else "."))
        return EXIT_DEPRECATED
    print("STATUS: OK")
    return EXIT_FOUND


def chain_members(cls, classes):
    current = cls
    while current:
        for member in current.get("Members", []):
            yield current["Name"], member
        current = classes.get(current.get("Superclass"))


def not_found(query, candidates):
    lowered = {c.lower(): c for c in candidates}
    matches = difflib.get_close_matches(query.lower(), list(lowered), n=5, cutoff=0.6)
    print(f"STATUS: NOT FOUND: {query} is not in the API dump. Names are case-sensitive.")
    if matches:
        print("Did you mean: " + ", ".join(lowered[m] for m in matches))
    return EXIT_NOT_FOUND


def outside_dump(name):
    if name in LIBRARIES:
        url = f"{DOCS}/libraries/{name}"
        kind = "library"
    elif name in DATATYPES:
        url = f"{DOCS}/datatypes/{name}"
        kind = "data type"
    elif name in GLOBALS:
        url = "https://create.roblox.com/docs/reference/engine/globals/RobloxGlobals"
        kind = "global"
    else:
        return None
    print(f"{name} is a {kind}. The API dump does not list its members.")
    print(f"Verify in the docs: {url}")
    if name in LEGACY_GLOBALS:
        print(f"STATUS: DEPRECATED STYLE. Use {LEGACY_GLOBALS[name]}.")
        return EXIT_DEPRECATED
    print("STATUS: OUTSIDE DUMP")
    return EXIT_OUTSIDE_DUMP


def lookup_enum(parts, enums):
    if len(parts) == 1:
        return not_found("Enum", enums)
    enum = enums.get(parts[1])
    if not enum:
        return not_found("Enum." + parts[1], [f"Enum.{name}" for name in enums])
    if len(parts) == 2:
        print(f"Enum {enum['Name']}: " + ", ".join(i["Name"] for i in enum["Items"]))
        print(f"Docs: {DOCS}/enums/{enum['Name']}")
        print("STATUS: OK")
        return EXIT_FOUND
    item = next((i for i in enum["Items"] if i["Name"] == parts[2]), None)
    if not item:
        return not_found(".".join(parts), [f"Enum.{enum['Name']}.{i['Name']}" for i in enum["Items"]])
    print(f"Enum.{enum['Name']}.{item['Name']} = {item['Value']}")
    if "Deprecated" in tag_names(item):
        print("STATUS: DEPRECATED")
        return EXIT_DEPRECATED
    print("STATUS: OK")
    return EXIT_FOUND


def search_member(name, classes):
    hits = [(c, m) for c in classes.values() for m in c.get("Members", []) if m["Name"] == name]
    for cls, member in hits[:15]:
        deprecated = " [DEPRECATED]" if "Deprecated" in tag_names(member) else ""
        print(signature(cls["Name"], member) + deprecated)
    if len(hits) > 15:
        print(f"... and {len(hits) - 15} more. Query Class.Member for one class.")
    return hits


def lookup(query, dump, show_members):
    classes = {c["Name"]: c for c in dump["Classes"]}
    enums = {e["Name"]: e for e in dump["Enums"]}
    parts = [p for p in re.split(r"[.:]", query.strip()) if p]
    if not parts or len(parts) > 3:
        return not_found(query, classes)
    if parts[0] == "Enum":
        return lookup_enum(parts, enums)
    if parts[0] == "Instance" and parts[1:] in (["new"], ["fromExisting"]):
        print(f"Instance.{parts[1]} is a constructor, documented at {DOCS}/datatypes/Instance")
        print("STATUS: OK")
        return EXIT_FOUND

    cls = classes.get(parts[0])
    if len(parts) == 1:
        if cls:
            return report_class(cls, classes, show_members)
        if parts[0] in enums:
            return lookup_enum(["Enum", parts[0]], enums)
        answer = outside_dump(parts[0])
        if answer is not None:
            return answer
        if search_member(parts[0], classes):
            print("STATUS: OK (member name exists on the classes above)")
            return EXIT_FOUND
        members = {m["Name"] for c in classes.values() for m in c.get("Members", [])}
        return not_found(parts[0], set(classes) | members)

    if not cls:
        answer = outside_dump(parts[0])
        if answer is not None:
            return answer
        return not_found(parts[0], classes)
    chain = list(chain_members(cls, classes))
    for owner, member in chain:
        if member["Name"] == parts[1]:
            return report_member(owner, member, cls["Name"])
    return not_found(f"{parts[0]}.{parts[1]}", {f"{parts[0]}.{m['Name']}" for _, m in chain})


def main():
    parser = argparse.ArgumentParser(description="Verify Roblox APIs against a cached API dump.")
    parser.add_argument("query", nargs="?", help="Part, Part.Anchored, Instance:Destroy, Enum.Material.Plastic")
    parser.add_argument("--members", action="store_true", help="list current members of a class")
    parser.add_argument("--update", action="store_true", help="download the latest dump")
    args = parser.parse_args()
    if not args.query and not args.update:
        parser.error("give a query or --update")
    try:
        if args.update:
            download()
            if shutil.which("luau-lsp") or (cache_dir() / DEFINITIONS_NAME).exists():
                download_definitions()
        if not args.query:
            return EXIT_FOUND
        dump = load_dump()
    except (OSError, ValueError) as error:
        print(f"ERROR: cannot get the API dump: {error}", file=sys.stderr)
        print("STATUS: UNVERIFIED. Do not treat the API as confirmed.")
        return 4
    return lookup(args.query, dump, args.members)


if __name__ == "__main__":
    sys.exit(main())
