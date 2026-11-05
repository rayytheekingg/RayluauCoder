#!/usr/bin/env python3
"""Look up Roblox classes, members, enums, libraries, and data types.

Classes and enums come from the live Studio API dump. Libraries, data types, and globals
come from an index built from Roblox's documentation source (see maintain.py).

Exit codes: 0 found, 1 not found, 2 found but deprecated, 4 could not get the dump.
"""
import argparse
import difflib
import functools
import gzip
import json
import os
import re
import shutil
import sys
import time
import urllib.request
from pathlib import Path

VERSION_URL = "https://clientsettings.roblox.com/v2/client-version/WindowsStudio64"
DUMP_URL = "https://setup.rbxcdn.com/{version}-Full-API-Dump.json"
# A new name, because older versions cached a dump from an address frozen in 2023.
DUMP_NAME = "Full-API-Dump-live.json"
DEFINITIONS_URL = "https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.None.d.luau"
DEFINITIONS_NAME = "globalTypes.None.d.luau"
DOCS = "https://create.roblox.com/docs/reference/engine"
DOCS_INDEX = Path(__file__).resolve().parent / "data" / "docs-index.json.gz"
USER_AGENT = "RayluauCoder/1.0.6"
MAX_AGE_DAYS = 14

EXIT_FOUND, EXIT_NOT_FOUND, EXIT_DEPRECATED, EXIT_NO_DUMP = 0, 1, 2, 4

LEGACY_GLOBALS = {
    "delay": "task.delay",
    "spawn": "task.spawn",
    "tick": "os.clock or workspace:GetServerTimeNow",
    "wait": "task.wait",
}
GLOBAL_ALIASES = {"game": "DataModel", "workspace": "Workspace"}


@functools.lru_cache(maxsize=1)
def docs_index():
    try:
        with gzip.open(DOCS_INDEX, "rt", encoding="utf-8") as file:
            return json.load(file)
    except (OSError, ValueError) as error:
        print(f"Note: docs index unavailable ({error}). Run scripts/run maintain.", file=sys.stderr)
        return {"extras": {}, "deprecated": {}, "pages": []}


def extras_in_group(*groups):
    return {name for name, entry in docs_index()["extras"].items() if entry["group"] in groups}


def global_names():
    names = set()
    for entry in docs_index()["extras"].values():
        if entry["group"] == "globals":
            names |= set(entry["members"])
    return names


LIBRARIES = extras_in_group("libraries")
DATATYPES = extras_in_group("datatypes")
GLOBALS = global_names()


def cache_dir():
    override = os.environ.get("RAYLUAU_CACHE")
    if override:
        return Path(override)
    base = os.environ.get("LOCALAPPDATA") or os.environ.get("XDG_CACHE_HOME")
    return Path(base) / "rayluaucoder" if base else Path.home() / ".cache" / "rayluaucoder"


def dump_path():
    return cache_dir() / DUMP_NAME


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    with urllib.request.urlopen(request, timeout=90) as response:
        return response.read()


def write_cache(path, raw):
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_suffix(".tmp")
    temp.write_bytes(raw)
    temp.replace(path)
    print(f"Cached {len(raw) / 1048576:.1f} MB at {path}", file=sys.stderr)


def download():
    version = json.loads(fetch(VERSION_URL))["clientVersionUpload"]
    if not re.fullmatch(r"version-[0-9a-f]+", version):
        raise ValueError(f"unexpected Roblox version string: {version!r}")
    print(f"Downloading Roblox API dump {version} from setup.rbxcdn.com ...", file=sys.stderr)
    raw = fetch(DUMP_URL.format(version=version))
    json.loads(raw)
    write_cache(dump_path(), raw)
    (dump_path().parent / "version.txt").write_text(version, encoding="ascii")


def download_definitions():
    print("Downloading Roblox type definitions from the luau-lsp repo ...", file=sys.stderr)
    write_cache(cache_dir() / DEFINITIONS_NAME, fetch(DEFINITIONS_URL))


def age_in_days(path):
    return (time.time() - path.stat().st_mtime) / 86400


def definitions_path():
    """Return the Roblox definitions file for luau-lsp, downloading it on first use."""
    path = cache_dir() / DEFINITIONS_NAME
    if not path.exists():
        download_definitions()
    elif age_in_days(path) > MAX_AGE_DAYS:
        try:
            download_definitions()
        except (OSError, ValueError) as error:
            print(f"Note: using old Roblox definitions ({error}).", file=sys.stderr)
    return path


def load_dump(allow_download=True):
    path = dump_path()
    if not path.exists():
        if not allow_download:
            return None
        download()
    elif allow_download and age_in_days(path) > MAX_AGE_DAYS:
        try:
            download()
        except (OSError, ValueError, KeyError) as error:
            print(f"Note: using an API dump {age_in_days(path):.0f} days old ({error}).", file=sys.stderr)
    return json.loads(path.read_text(encoding="utf-8"))


def class_names():
    """Return known class and enum names for check.py, or an empty set when offline."""
    try:
        dump = load_dump()
    except (OSError, ValueError, KeyError) as error:
        print(f"Note: API dump unavailable ({error}).", file=sys.stderr)
        return set()
    return {c["Name"] for c in dump["Classes"]} | {f"Enum.{e['Name']}" for e in dump["Enums"]}


def deprecated_names():
    """Return (method name -> owner, class names) for names that are deprecated everywhere they appear."""
    try:
        dump = load_dump()
    except (OSError, ValueError, KeyError) as error:
        print(f"Note: API dump unavailable ({error}).", file=sys.stderr)
        return {}, set()
    active, methods, classes = set(), {}, set()
    for cls in dump["Classes"]:
        if "Deprecated" in tag_names(cls):
            classes.add(cls["Name"])
        for member in cls.get("Members", []):
            if "Deprecated" not in tag_names(member):
                active.add(member["Name"])
            elif member["MemberType"] == "Function":
                methods[member["Name"]] = cls["Name"]
    return {name: owner for name, owner in methods.items() if name not in active}, classes


def tag_names(entry):
    return [t for t in (entry.get("Tags") or []) if isinstance(t, str)]


def preferred(entry):
    for tag in entry.get("Tags") or []:
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


def docs_note(*keys):
    notes = docs_index()["deprecated"]
    return next((notes[key] for key in keys if key in notes), "")


def report_deprecated(entry, *note_keys):
    replacement = preferred(entry)
    print("STATUS: DEPRECATED" + (f". Use {replacement}." if replacement else "."))
    note = docs_note(*note_keys)
    if note:
        print(f"Roblox docs: {note}")
    return EXIT_DEPRECATED


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
    print(f"Docs: {DOCS}/classes/{owner}#{member['Name']}")
    if "Deprecated" in tags:
        return report_deprecated(member, f"{owner}.{member['Name']}", f"{owner}:{member['Name']}")
    if "NotScriptable" in tags:
        print("STATUS: NOT SCRIPTABLE. Set it in Studio's Properties window, not from a script.")
    else:
        print("STATUS: OK")
    return EXIT_FOUND


def chain_members(cls, classes):
    current = cls
    while current:
        for member in current.get("Members", []):
            yield current["Name"], member
        current = classes.get(current.get("Superclass"))


def report_class(cls, classes, show_members):
    print(f"Class {cls['Name']}" + (f" : {cls['Superclass']}" if cls.get("Superclass") else ""))
    tags = tag_names(cls)
    if tags:
        print("Tags: " + ", ".join(tags))
    print(f"Docs: {DOCS}/classes/{cls['Name']}")
    if show_members:
        for owner, member in chain_members(cls, classes):
            member_tags = tag_names(member)
            if "Deprecated" not in member_tags and "Hidden" not in member_tags:
                print("  " + signature(owner, member))
    if "Deprecated" in tags:
        return report_deprecated(cls, cls["Name"])
    print("STATUS: OK")
    return EXIT_FOUND


def not_found(query, candidates):
    lowered = {c.lower(): c for c in candidates}
    matches = difflib.get_close_matches(query.lower(), list(lowered), n=5, cutoff=0.6)
    print(f"STATUS: NOT FOUND: {query} does not exist in the current API. Names are case-sensitive.")
    if matches:
        print("Did you mean: " + ", ".join(lowered[m] for m in matches))
    return EXIT_NOT_FOUND


def group_docs_url(name, entry):
    if entry["group"] == "globals":
        return f"{DOCS}/globals/{name}"
    return f"{DOCS}/{entry['group']}/{name}"


def report_extra_member(full_name, info, url):
    print(f"{info['kind'].rstrip('s').capitalize()} {full_name}")
    print(f"Docs: {url}")
    if info.get("deprecated"):
        print("STATUS: DEPRECATED")
        print(f"Roblox docs: {info['deprecated']}")
        return EXIT_DEPRECATED
    print("STATUS: OK")
    return EXIT_FOUND


def lookup_global(name):
    for group_name, entry in docs_index()["extras"].items():
        if entry["group"] == "globals" and name in entry["members"]:
            url = group_docs_url(group_name, entry)
            if name in LEGACY_GLOBALS:
                print(f"Global {name}\nDocs: {url}\nSTATUS: DEPRECATED. Use {LEGACY_GLOBALS[name]}.")
                return EXIT_DEPRECATED
            return report_extra_member(name, entry["members"][name], url)
    return None


def lookup_extra(parts):
    """Answer for a library or data type. Returns None when the name isn't one."""
    entry = docs_index()["extras"].get(parts[0])
    if not entry or entry["group"] == "globals":
        return None
    url = group_docs_url(parts[0], entry)
    if len(parts) == 1:
        names = sorted(re.split(r"[.:]", name)[-1] for name in entry["members"])
        print(f"{parts[0]} is a {entry['group'].rstrip('s').replace('librarie', 'library')}: " + ", ".join(names))
        print(f"Docs: {url}\nSTATUS: OK")
        return EXIT_FOUND
    for full_name, info in entry["members"].items():
        if re.split(r"[.:]", full_name)[-1] == parts[1]:
            return report_extra_member(full_name, info, f"{url}#{parts[1]}")
    return not_found(".".join(parts), entry["members"])


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


def lookup_single(name, classes, enums, show_members):
    if name in classes:
        return report_class(classes[name], classes, show_members)
    if name in enums:
        return lookup_enum(["Enum", name], enums)
    for answer in (lookup_extra([name]), lookup_global(name)):
        if answer is not None:
            return answer
    if search_member(name, classes):
        print("STATUS: OK (member name exists on the classes above)")
        return EXIT_FOUND
    members = {m["Name"] for c in classes.values() for m in c.get("Members", [])}
    return not_found(name, set(classes) | members | LIBRARIES | DATATYPES | GLOBALS)


def lookup(query, dump, show_members):
    classes = {c["Name"]: c for c in dump["Classes"]}
    enums = {e["Name"]: e for e in dump["Enums"]}
    parts = [p for p in re.split(r"[.:]", query.strip()) if p]
    if not parts or len(parts) > 3:
        return not_found(query, classes)
    if parts[0] == "Enum":
        return lookup_enum(parts, enums)
    if len(parts) == 1:
        return lookup_single(parts[0], classes, enums, show_members)

    head = GLOBAL_ALIASES.get(parts[0], parts[0])
    cls = classes.get(head)
    if cls:
        chain = list(chain_members(cls, classes))
        for owner, member in chain:
            if member["Name"] == parts[1]:
                return report_member(owner, member, cls["Name"])
        if head in docs_index()["extras"]:
            return lookup_extra([head, parts[1]])
        return not_found(f"{head}.{parts[1]}", {f"{head}.{m['Name']}" for _, m in chain})
    answer = lookup_extra([head, parts[1]])
    if answer is not None:
        return answer
    return not_found(head, set(classes) | LIBRARIES | DATATYPES)


def main():
    parser = argparse.ArgumentParser(description="Verify Roblox APIs against the live API dump and Roblox's docs.")
    parser.add_argument("query", nargs="?", help="Part, Part.Anchored, task.wait, Vector3.new, Enum.Material.Plastic")
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
    except (OSError, ValueError, KeyError) as error:
        print(f"ERROR: cannot get the API dump: {error}", file=sys.stderr)
        print("STATUS: UNVERIFIED. Do not treat the API as confirmed.")
        return EXIT_NO_DUMP
    return lookup(args.query, dump, args.members)


if __name__ == "__main__":
    sys.exit(main())
