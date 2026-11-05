# RayluauCoder

A Claude Code plugin that helps Claude write, check, and debug Roblox games in Luau.

It adds:

- A `luau` skill with Roblox rules for script placement, security, data, performance, debugging, and neat code.
- A guide for choosing frameworks, libraries, tools, and game architecture.
- Commands for starting, checking, reviewing, tidying, and choosing systems.
- Type checking that understands Roblox APIs, when `luau-lsp` is installed.
- Testing in real Studio playtests, without changing your place, when Studio is connected.
- A lookup tool that verifies Roblox APIs against Roblox's API dump.
- A Rojo project template and reusable code templates.

## Install

Requires Claude Code, Git Bash on Windows, and Python 3.8 or newer.

In a terminal, run:

```bash
claude plugin install rayluaucoder --marketplace rayytheekingg/RayluauCoder
```

Or, inside a Claude Code session, run:

```text
/plugin install rayluaucoder --marketplace rayytheekingg/RayluauCoder
```

The one-line forms need Claude Code v2.1.292 in a terminal, or v2.1.275 in a session. On older versions, run these two commands in a terminal:

```bash
claude plugin marketplace add rayytheekingg/RayluauCoder
```

```bash
claude plugin install rayluaucoder@rayluau
```

To get a new version later, run:

```bash
claude plugin update rayluaucoder@rayluau
```

To try it for one session without installing it, download the [repo zip](https://github.com/rayytheekingg/RayluauCoder/archive/refs/heads/main.zip) and unzip it, then run:

```bash
claude --plugin-dir "/path/to/RayluauCoder-main"
```

## Use

Ask Claude for any Roblox, Studio, Rojo, or Luau task. The skill loads automatically.

Try these prompts:

- "Make a server-checked shop where players buy a speed boost with coins."
- "Why does my DataStore lose player data when the server shuts down? Find the bug and fix it."
- "Review my remotes for exploits that could give players free currency."

| Command | What it does |
| --- | --- |
| `/rayluau-new <name> [folder]` | Starts a Rojo project from the template |
| `/rayluau-check [path]` | Runs all available checks on a file or folder |
| `/rayluau-review [path]` | Reviews code against the security and performance checklists |
| `/rayluau-choose <description>` | Recommends systems, with the reason, tradeoff, and fallback |
| `/rayluau-neat [path]` | Tidies requested code without changing what it does |
| `/rayluau-test [path or feature]` | Tests code in a Studio playtest, without changing your place |

Claude Code may show these commands as `/rayluaucoder:rayluau-new` and so on.

You can also run the scripts yourself:

```bash
bash scripts/run check path/to/src
```

```bash
bash scripts/run neat path/to/src
```

```bash
bash scripts/run neat path/to/src --fix
```

```bash
bash scripts/run api-lookup Part.Anchored
```

```bash
bash scripts/run setup
```

## Neat code

`neat` reports long lines, functions, and files, deep nesting, naming problems, misplaced services and requires, commented-out code, vague TODOs, and print calls that look like leftovers.

`neat --fix` only runs StyLua, so it changes formatting and never restructures code. `/rayluau-neat` handles the other fixes.

Change limits or turn off rules with `rayluau-neat.json` in your project. Details are in `skills/luau/references/code-style.md`.

## Studio testing

`/rayluau-test` uses the MCP server built into Roblox Studio to run code in a real playtest. Changes made during a playtest are discarded when it stops, and tests use `templates/code/MockDataStore.luau` instead of real data stores.

To connect:

1. In Studio, open Assistant, choose **Manage MCP Servers**, and turn on **Enable Studio as MCP server**.
2. Register it with Claude Code once:

Windows, in Git Bash:

```bash
MSYS_NO_PATHCONV=1 claude mcp add --scope user --transport stdio Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"
```

macOS, from Roblox's documented path (not tested by this project):

```bash
claude mcp add --scope user --transport stdio Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
```

3. Start a new chat with Studio open.

**Warning:** connected tools can read and change your open place, and run code in it. Only connect tools you trust, and save your work first.

To disconnect:

```bash
claude mcp remove Roblox_Studio -s user
```

## Optional tools

None of these are required or bundled. `setup` prints install steps and installs nothing.

| Tool | Used for | If missing |
| --- | --- | --- |
| `luau-lsp` | Syntax and types, including Roblox API calls | Falls back to `luau-analyze` |
| `luau-analyze` | Syntax and types, without Roblox API types | Used only as the fallback. If both are missing, syntax and types are not checked |
| `selene` | Roblox lint rules | Lint is skipped |
| `stylua` | Formatting, and `neat --fix` | Formatting is skipped |
| `rojo` | Syncing `/rayluau-new` projects to Studio, and fresh sourcemaps | Copy code into Studio by hand. Use an existing `sourcemap.json` if you have one |

## Companion Studio plugins

Studio plugins install through your own Roblox account, so RayluauCoder can't install them for you. `bash scripts/run setup` shows which ones it can detect and links the rest.

| Companion | Why | Cost |
| --- | --- | --- |
| [Roblox Studio MCP](https://create.roblox.com/docs/studio/mcp) | Lets Claude read scripts, playtest, read Output, and take screenshots. Built into Studio | Free |
| [Rojo](https://rojo.space/docs/v7/getting-started/installation/) | Keeps code in files and git, for new projects and teams | Free |
| [Script Sync](https://create.roblox.com/docs/scripting/sync) | Puts an existing place's scripts in files. Built into Studio | Free |
| [UI Labs](https://create.roblox.com/store/asset/14293316215/UI-Labs) | Previews UI code with hot reload | Free |

The full list, connection steps, and plugin safety rules are in `skills/luau/references/companions.md`. It also covers building and animation plugins.

## Limits

- The status details in `companions.md` were checked on 2026-11-04 and will age.
- `check` always states which type checker ran.
- `check` reports `INCOMPLETE` when selene, StyLua, or both type checkers are missing. `PASS` with the fallback warns that Roblox API calls were not type-checked.
- `luau-lsp` needs a sourcemap to resolve requires and child instance paths such as `ReplicatedStorage.Shared.Config`. Without one, `check` skips those references and reports how many. With one, broken `require` paths are reported, but a misspelled child used outside `require` can still pass.
- `neat` uses patterns, not a full parser. It can miss problems or flag a rare false positive. Use `-- neat: ignore` for those.
- The built-in deprecated-API scan looks for patterns only. It does not check syntax or types.
- `api-lookup` covers engine classes, members, and enums. Libraries and data types such as `task` and `Vector3` return a docs link instead.
- The system status in `systems.md` was checked on 2026-11-04 and will age. Recheck it after 6 months.
- The `check` and `neat` scripts don't run your game. Use `/rayluau-test` or test in Roblox Studio yourself.
- `/rayluau-test` runs one player. It can't prove behaviour that needs several players, real DataStores, purchases, teleports, phones, or real network conditions.
- `templates/code/PlayerData.luau` has no session locking. Add it or use ProfileStore for trading or other duplication-sensitive data.

## What it runs

- **Python scripts:** `scripts/run` starts the plugin's own readable Python scripts on your computer.
- **Your installed tools:** `check` and `neat` run `luau-lsp`, `luau-analyze`, `selene`, `stylua`, and `rojo` if you have them. `neat --fix` rewrites formatting with StyLua.
- **Roblox Studio, if connected:** `/rayluau-test` starts and stops playtests and runs test code in them through Studio's MCP server.
- **New projects:** `/rayluau-new` copies the template into the folder you choose.

The plugin has no hooks, background processes, or MCP servers of its own, and it installs nothing. `setup` only prints install steps.

## Privacy

RayluauCoder collects nothing and sends no code or personal data. See [PRIVACY.md](PRIVACY.md).

## Network use

These files download on first use, and are stored in `%LOCALAPPDATA%\rayluaucoder`, or `~/.cache/rayluaucoder` on other systems:

| File | Source | Size | Used by |
| --- | --- | --- | --- |
| Roblox API dump | `setup.rbxcdn.com` | About 4.4 MB | `api-lookup`, and the `luau-analyze` fallback |
| Roblox type definitions | The `luau-lsp` GitHub repo | About 0.7 MB | `check`, when `luau-lsp` is installed |

Set `RAYLUAU_CACHE` to use another folder. Refresh them with `bash scripts/run api-lookup --update`.

## License

MIT. Roblox is a trademark of Roblox Corporation. This project is not affiliated with or endorsed by Roblox or Anthropic.
