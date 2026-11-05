---
name: rayluau-neat
description: Tidy requested Luau code without changing what it does
argument-hint: [path]
disable-model-invocation: true
---

Tidy the Luau code at this path: `$ARGUMENTS`

If no path was given, use the code changed in this conversation. If there is none, ask which code to tidy.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/code-style.md`.
2. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" neat "<path>" --fix`. It only runs StyLua. If StyLua is missing, run it without `--fix` and report that formatting was skipped.
3. Read each finding, then fix it in the requested code. Also apply the guide's rules that the script cannot check, such as clear names, comments that explain why, and named constants.
4. Do not change behaviour. Keep logic, order of effects, public APIs, and return values the same.
5. Do not rename remotes, attributes, tags, Instances, DataStore names, or DataStore keys unless you can update every use safely. Report DataStore names and keys instead of changing them, because renaming them can lose access to saved data.
6. Do not tidy unrelated code.
7. If a finding is a real false positive, add `-- neat: ignore` and tell the user why.
8. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "<path>"`, and fix what your changes caused.

Report what changed, what was left, and the `RESULT` line. State that behaviour was not tested in Roblox Studio.
