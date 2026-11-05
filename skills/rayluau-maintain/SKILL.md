---
name: rayluau-maintain
description: Check RayluauCoder against Roblox's and Luau's latest documentation
argument-hint: [--links]
disable-model-invocation: true
---

Run a maintenance check on this plugin. Use as little usage as possible.

1. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" maintain $ARGUMENTS`. It needs git. It rebuilds the docs index, lists guide pages added or removed since the last check, and audits every API name in the guides.
2. Fix every reported problem.
3. For each new guide page that affects scripting, security, data, performance, or input, read it, and update the matching reference in `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/`.
4. Check the Luau docs at https://luau.org for new syntax, and update `language.md`. Confirm any new syntax in current tools before using it in templates.
5. If `systems.md` is over 6 months old, recheck each third-party option's latest release, archived flag, and license, then update its date.
6. Update the "Checked against" date in each reference you reviewed.
7. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "${CLAUDE_PLUGIN_ROOT}/templates"`, and the same for `samples`.
8. If Studio tools are available, playtest the changed templates. Follow `references/studio-testing.md`.

Don't copy documentation text into the guides. Write short rules in your own words, with links.

Report what changed, what you read, and anything you didn't check. Don't commit or publish unless asked.
