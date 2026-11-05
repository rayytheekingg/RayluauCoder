---
name: rayluau-choose
description: Recommend Roblox systems for a game or feature
argument-hint: <game or feature description>
disable-model-invocation: true
---

Recommend systems for this game or feature: `$ARGUMENTS`

If the description is missing, ask for it.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/systems.md`, including its choosing rules.
2. Read the project with as few calls as possible. Check `default.project.json`, `wally.toml`, `pesde.toml`, `rokit.toml`, `Packages/`, and existing `require` calls. If there is no project, say so.
3. Use the existing system in any category unless it causes a real problem.
4. Choose only the categories this request needs.
5. If the guide's checked date is over 6 months old, recheck the status of any third-party option before recommending it. If you cannot, say that the status may be out of date.

For each category, recommend exactly one option:

- **Recommendation:** what to use.
- **Reason:** the specific need it meets in this project.
- **Tradeoff:** what it costs.
- **Fallback:** one option to use if the reason turns out false.

Every third-party recommendation must name the need that justifies the dependency. If the need depends on a measurement that doesn't exist yet, recommend the simpler option and say what to measure.

Do not install anything or edit files unless the user asks.
