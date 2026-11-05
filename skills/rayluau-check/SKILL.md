---
name: rayluau-check
description: Run all available Luau checks on a file or folder
argument-hint: [path]
disable-model-invocation: true
---

Run this command with the given path, or `.` if none was given: `$ARGUMENTS`

`bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "<path>"`

Report the `RESULT` line exactly, each problem with its location, and every skipped tool. Treat `INCOMPLETE` as not fully checked, never as a pass. If a tool was skipped, offer to show `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" setup`. Do not edit files unless the user asked for fixes.
