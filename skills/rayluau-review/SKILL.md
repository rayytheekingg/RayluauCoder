---
name: rayluau-review
description: Review Roblox Luau code against the security and performance checklists
argument-hint: [path]
disable-model-invocation: true
---

Review the Luau code at this path, or the current folder if none was given: `$ARGUMENTS`

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "<path>"` once.
2. Read the review checklists in `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/security-and-data.md` and `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/performance.md`.
3. Read the code. Start with remotes, data saving, purchases, and per-frame code.
4. Use `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" api-lookup "<Class.Member>"` for any API you are unsure about.

Report findings, most severe first, as `path:line: severity: problem. fix.` Use the severities `critical`, `high`, `medium`, and `low`. A critical finding lets a client gain items or currency, change other players, or lose saved data. Add the check script's `RESULT` line. State that runtime behaviour was not tested in Studio.

Do not edit files unless the user asked for fixes.
