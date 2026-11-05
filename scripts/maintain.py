#!/usr/bin/env python3
"""Maintenance check: refresh the docs index from Roblox's docs source, and audit this plugin against it.

Steps: get Roblox's creator-docs source, rebuild data/docs-index.json.gz, report guide pages added or
removed since the last index, then check every API the plugin's guides mention.

Exit codes: 0 no problems, 1 problems found, 2 could not get the docs.
"""
import argparse
import contextlib
import datetime
import gzip
import io
import json
import re
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

import api_lookup

ROOT = Path(__file__).resolve().parent.parent
DOCS_REPO = "https://github.com/Roblox/creator-docs.git"
NOTE_LENGTH = 240
STATUS_MAX_AGE_DAYS = 183
TOKEN = re.compile(r"`([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)+)(?:\([^`]*\))?`")
# Placeholders the guides use on purpose.
SKIP_TOKENS = {"Enum.Name.Item"}


def git(*args, cwd=None):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True, encoding="utf-8", errors="replace")


def get_docs():
    """Keep a sparse checkout of the docs' text files in the cache folder."""
    if not shutil.which("git"):
        raise OSError("git is not installed")
    target = api_lookup.cache_dir() / "creator-docs"
    if (target / ".git").is_dir():
        git("fetch", "--depth", "1", "origin", "main", cwd=target)
        git("reset", "--hard", "FETCH_HEAD", cwd=target)
        return target
    target.parent.mkdir(parents=True, exist_ok=True)
    git("clone", "--depth", "1", "--filter=blob:none", "--no-checkout", DOCS_REPO, str(target))
    git("sparse-checkout", "init", "--no-cone", cwd=target)
    git("sparse-checkout", "set", "/content/en-us/**/*.md", "/content/en-us/**/*.yaml", cwd=target)
    git("checkout", cwd=target)
    return target


def parse_members(path):
    """Read a reference file's named members, without needing a YAML library."""
    parsed = {"deprecation_message": "", "sections": {}}
    section, item, block_key, block_indent = None, None, None, 0
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if block_key:
            if not line.strip() or len(line) - len(line.lstrip()) >= block_indent:
                item[block_key] = (item.get(block_key, "") + " " + line.strip()).strip()
                continue
            block_key = None
        top = re.match(r"^(\w+):\s*(.*)$", line)
        if top:
            section, item = top.group(1), None
            value = top.group(2).strip().strip("'\"")
            if section == "deprecation_message":
                if value in ("|", ">", "|-", ">-"):
                    item, block_key, block_indent = parsed, section, 2
                else:
                    parsed[section] = value
            continue
        start = re.match(r"^  - name: (.+)$", line)
        if start and section:
            item = {"name": start.group(1).strip().strip("'\"")}
            parsed["sections"].setdefault(section, []).append(item)
            continue
        field = re.match(r"^    deprecation_message:\s*(.*)$", line)
        if field and item is not None and item is not parsed:
            value = field.group(1).strip().strip("'\"")
            if value in ("|", ">", "|-", ">-"):
                item["deprecation_message"] = ""
                block_key, block_indent = "deprecation_message", 6
            else:
                item["deprecation_message"] = value
    return parsed


def clean_note(text):
    text = re.sub(r"`(?:Class|Datatype|Enum|Library|Global)\.[^`|]*\|([^`]*)`", r"`\1`", text)
    text = re.sub(r"`(?:Class|Datatype|Library|Global)\.([^`]*)`", r"`\1`", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"\s+", " ", text).strip()
    return text[:NOTE_LENGTH]


def build_index(docs):
    content = docs / "content" / "en-us"
    engine = content / "reference" / "engine"
    extras, deprecated = {}, {}
    for group in ("libraries", "datatypes", "globals"):
        for path in sorted((engine / group).glob("*.yaml")):
            parsed = parse_members(path)
            members = {}
            for section, items in parsed["sections"].items():
                if section == "math_operations":
                    continue
                for item in items:
                    info = {"kind": section}
                    note = clean_note(item.get("deprecation_message", ""))
                    if note:
                        info["deprecated"] = note
                    members[item["name"]] = info
            extras[path.stem] = {"group": group, "members": members}
    for path in sorted((engine / "classes").glob("*.yaml")):
        parsed = parse_members(path)
        note = clean_note(parsed["deprecation_message"])
        if note:
            deprecated[path.stem] = note
        for items in parsed["sections"].values():
            for item in items:
                note = clean_note(item.get("deprecation_message", ""))
                if note:
                    deprecated[item["name"]] = note
    pages = sorted(
        path.relative_to(content).as_posix()
        for path in content.rglob("*.md")
        if not path.relative_to(content).as_posix().startswith(("reference/", "includes/"))
    )
    commit = subprocess.run(
        ["git", "log", "-1", "--format=%h %cs"], cwd=docs, capture_output=True, text=True, check=False
    ).stdout.strip()
    return {"commit": commit, "extras": extras, "deprecated": deprecated, "pages": pages}


def save_index(index):
    api_lookup.DOCS_INDEX.parent.mkdir(parents=True, exist_ok=True)
    with open(api_lookup.DOCS_INDEX, "wb") as raw, gzip.GzipFile(fileobj=raw, mode="wb", mtime=0) as file:
        file.write(json.dumps(index, separators=(",", ":"), sort_keys=True).encode("utf-8"))
    api_lookup.docs_index.cache_clear()


def guide_files():
    return [*sorted((ROOT / "skills").rglob("*.md")), ROOT / "README.md"]


def audit_api_mentions():
    """Look up every API-shaped name in the guides. Only names with a known Roblox head are checked."""
    dump = api_lookup.load_dump()
    known = {c["Name"] for c in dump["Classes"]} | api_lookup.LIBRARIES | api_lookup.DATATYPES
    known |= {"Enum", "game", "workspace"}
    problems, checked = [], set()
    for path in guide_files():
        text = re.sub(r"```.*?```", lambda match: match.group(0).replace("`", ""), path.read_text(encoding="utf-8"), flags=re.S)
        for token in sorted(set(TOKEN.findall(text))):
            parts = re.split(r"[.:]", token)
            # Paths such as ReplicatedStorage.Shared.Config name children in a place, not APIs.
            if token in SKIP_TOKENS or parts[0] not in known or (len(parts) > 2 and parts[0] != "Enum"):
                continue
            checked.add(token)
            with contextlib.redirect_stdout(io.StringIO()):
                code = api_lookup.lookup(token, dump, False)
            if code == api_lookup.EXIT_NOT_FOUND:
                problems.append(f"{path.relative_to(ROOT).as_posix()}: {token} does not exist")
            elif code == api_lookup.EXIT_DEPRECATED:
                problems.append(f"{path.relative_to(ROOT).as_posix()}: {token} is deprecated")
    return problems, len(checked)


def audit_links():
    urls = set()
    for path in guide_files():
        urls |= set(re.findall(r"https?://[^\s)\"'<>`\\]+", path.read_text(encoding="utf-8")))
    failures = []
    for url in sorted(urls):
        request = urllib.request.Request(url.split("#")[0], headers={"User-Agent": api_lookup.USER_AGENT})
        try:
            with urllib.request.urlopen(request, timeout=30):
                pass
        except urllib.error.HTTPError as error:
            failures.append(f"{error.code} {url}")
        except OSError as error:
            failures.append(f"{error} {url}")
    return failures, len(urls)


def status_age():
    text = (ROOT / "skills/luau/references/systems.md").read_text(encoding="utf-8")
    match = re.search(r"Checked: (\d{4}-\d{2}-\d{2})", text)
    if not match:
        return None
    return (datetime.date.today() - datetime.date.fromisoformat(match.group(1))).days


def main():
    parser = argparse.ArgumentParser(description="Refresh the docs index and audit this plugin.")
    parser.add_argument("--docs", help="use an existing creator-docs checkout instead of downloading one")
    parser.add_argument("--links", action="store_true", help="also check every link in the guides")
    args = parser.parse_args()

    old_pages = set(api_lookup.docs_index().get("pages", []))
    try:
        docs = Path(args.docs) if args.docs else get_docs()
        index = build_index(docs)
    except (OSError, subprocess.SubprocessError) as error:
        print(f"ERROR: cannot get Roblox's docs source: {error}", file=sys.stderr)
        return 2
    save_index(index)
    members = sum(len(entry["members"]) for entry in index["extras"].values())
    print(f"Docs {index['commit']}: {len(index['pages'])} guide pages, {members} library, data type, and global members.")

    new_pages = sorted(set(index["pages"]) - old_pages)
    removed = sorted(old_pages - set(index["pages"]))
    if old_pages:
        print(f"Guide pages added since the last index: {len(new_pages)}, removed: {len(removed)}")
        for page in [*new_pages, *removed]:
            print(f"  {page}")

    api_lookup.download()
    problems, checked = audit_api_mentions()
    print(f"API names checked in the guides: {checked}")
    for problem in problems:
        print(f"  {problem}")

    if args.links:
        failures, count = audit_links()
        print(f"Links checked: {count}, failed: {len(failures)}")
        for failure in failures:
            print(f"  {failure}")
        problems += failures

    age = status_age()
    if age is not None and age > STATUS_MAX_AGE_DAYS:
        problems.append("systems.md statuses are over 6 months old")
        print(f"systems.md statuses are {age} days old. Recheck each third-party option.")

    print(f"RESULT: {len(problems)} problem(s). Read any new pages above, then update the guides they affect.")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
