---
name: rayluau-new
description: Start a Roblox Rojo project from the RayluauCoder template
argument-hint: <project-name> [folder]
disable-model-invocation: true
---

Create a Rojo project from these arguments: `$ARGUMENTS`

1. Read the project name and optional folder. The folder defaults to `./<project-name>`. If the name is missing, ask for it. The name may use only letters, digits, `_`, and `-`.
2. If the folder already has files, stop and ask before changing anything.
3. Copy the template:
   `mkdir -p "<folder>" && cp -r "${CLAUDE_PLUGIN_ROOT}/templates/rojo-project/." "<folder>/"`
4. Replace `__PROJECT_NAME__` with the project name in `default.project.json` and `src/shared/Config.luau`.
5. Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "<folder>"` and report the result exactly.
6. If `rojo` is available, tell the user to run `rojo serve` in the folder and connect from the Rojo plugin in Studio. If it is missing, show the output of `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" setup`.

Do not install tools or create a git repository unless asked. Do not say the project ran in Studio.
