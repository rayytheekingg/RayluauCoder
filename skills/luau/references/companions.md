# Companion Studio plugins and tools

Status checked on 2026-11-04. Recheck after 6 months. Install only what the current job needs. RayluauCoder bundles none of these.

## Use first

| Companion | Gives Claude or the developer | Cost | Install | Status |
| --- | --- | --- | --- | --- |
| [Roblox Studio MCP](https://create.roblox.com/docs/studio/mcp) | Claude can read and edit scripts in the open place, run Luau, start playtests, read Output, and take screenshots | Free | Built into Studio. See "Connect Studio" below | Official |
| [Rojo](https://rojo.space/docs/v7/getting-started/installation/) | Code lives in files and git, so `check` gets full sourcemap coverage | Free | `rojo plugin install`, or the [store page](https://www.roblox.com/library/13916111004/Rojo) | Active. v7.7.1, 2026-10-02, MPL-2.0 |
| [Script Sync](https://create.roblox.com/docs/scripting/sync) | Scripts in an existing place become files without a Rojo project | Free | Built in. Right-click a folder in Explorer, then "Sync to…" | Official. Full release 2026-06-17 |
| [UI Labs](https://create.roblox.com/store/asset/14293316215/UI-Labs) | Previews UI code with hot reload, without running the game. Supports Fusion, React, Roact, Vide, Iris, and generic stories | Free | Creator Store | Active. v1.6.1, 2026-08-13, GPL-3.0 |

Choose Rojo or Script Sync, not both, for the same scripts.

- Rojo treats files as the source of truth. Use it for new projects, git, and teams.
- Script Sync suits a place that already lives in Studio. It ignores attributes and tags, so don't sync scripts that have them, because data loss can result. Script names must also be valid, unique file names.

## Built into Studio

Don't install plugins for these:

- **Tags:** the built-in tag editor replaces the old Tag Editor plugin. Check your Studio version first.
- **Frame timing:** MicroProfiler, opened with Ctrl+F6 or Cmd+F6. Label your own code with `debug.profilebegin()` and `debug.profileend()`.
- **AI analysis of a paused capture:** Assistant can analyse a MicroProfiler capture. This also works through the Studio MCP.

## Add for a specific need

| Companion | Choose when | Cost | Status |
| --- | --- | --- | --- |
| [Chrrxs/robloxstudio-mcp](https://github.com/Chrrxs/robloxstudio-mcp) | The built-in MCP can't do the job, such as per-peer server and client testing, or profiler and memory captures | Free | Active. v3.4.2, 2026-10-26, MIT. Third party |
| [Argon](https://github.com/argon-rbx/argon) | The project already uses it. Otherwise use Rojo | Free | v2.0.29, 2026-05-19, Apache-2.0 |
| [Codify](https://create.roblox.com/store/asset/4749111907/Codify-Convert-anything-to-code) by cxmeels | Turning small hand-made UI or instances into code. Script length limits rule out a whole UI | Paid. The demo only outputs `Instance.new` | Third party. Another plugin shares the name, so check the author |

For the Chrrxs server, a read-only Inspector edition exists. Install one edition only. Update the version only after you have checked it, and give any Open Cloud key only the scopes you want Claude to have:

```bash
claude mcp add robloxstudio-inspector -- npx -y @chrrxs/robloxstudio-mcp-inspector@3.4.2 --auto-install-plugin
```

## For building and animation

Claude can't drive these. They help the person working in Studio.

| Plugin | Use | Cost | Creator |
| --- | --- | --- | --- |
| [Building Tools by F3X](https://create.roblox.com/store/asset/144950355/Building-Tools-by-F3X-Plugin) | Precise resizing, snapping, material and colour painting | Free | GigsD4X |
| [GapFill & Extrude](https://create.roblox.com/store/asset/165687726/Stravant-GapFill-Extrude) | Fills gaps between edges and extrudes faces | Free | stravant |
| [Moon Animator 2](https://create.roblox.com/store/asset/4725618216/Moon-Animator-2) | Full animation editor | Paid. $19.99 when checked | xsixx |

Asset 142785488 is F3X's in-game model, not the Studio plugin.

## Connect Studio

1. Update Roblox Studio.
2. In Studio, open Assistant, then "…", then Manage MCP Servers.
3. Turn on **Enable Studio as MCP server**.
4. In Assistant Settings, under MCP Servers, turn on Claude Code in the Quick connect list.
5. If Claude Code isn't listed, add the server by hand. On Windows, run this from a Command Prompt:

```bash
claude mcp add Roblox_Studio -- cmd.exe /c %LOCALAPPDATA%\Roblox\mcp.bat
```

In Git Bash, use this instead, because Git Bash rewrites `/c` otherwise. `--scope user` makes it available in every project:

```bash
MSYS_NO_PATHCONV=1 claude mcp add --scope user --transport stdio Roblox_Studio -- cmd.exe /c "%LOCALAPPDATA%\Roblox\mcp.bat"
```

On macOS, run:

```bash
claude mcp add Roblox_Studio -- /Applications/RobloxStudio.app/Contents/MacOS/StudioMCP
```

6. Restart Claude Code. A green indicator in Manage MCP Servers shows the connected clients.

## Using the Studio MCP

When these tools are available:

1. Call `list_roblox_studios` to get the `studio_id` of the right window.
2. Use `search_game_tree`, `inspect_instance`, `script_read`, and `script_grep` to read the place before editing.
3. Use `multi_edit` only for places that don't use Rojo or Script Sync. In a synced project, edit the files, or the sync can overwrite the change.
4. Use `start_stop_play`, `get_console_output`, and `screen_capture` to test runtime behaviour. Stop the playtest when you finish. For test steps and safety rules, read `references/studio-testing.md`.
5. Treat `execute_luau` as able to change the open place. Use it for reads and for changes the user asked for.

A solo playtest doesn't prove multiplayer behaviour. Report what still needs a test with two players.

## Trust rules

Plugins run with wide access to the open place.

- Install from the original creator's page. Avoid "free" or "cracked" re-uploads of paid plugins.
- Look at the creator, votes, and last update before installing.
- Grant script injection and web request permissions only when the plugin's purpose needs them.
- Never paste a `.ROBLOSECURITY` cookie or an account password into a plugin.
- If scripts appear that nobody wrote, disable recently added plugins and search the place for `require(` calls with asset IDs and for `getfenv`.

## Sources

- https://create.roblox.com/docs/studio/mcp
- https://create.roblox.com/docs/scripting/sync
- https://devforum.roblox.com/t/full-release-studio-script-sync/4688454
- https://create.roblox.com/docs/performance-optimization/microprofiler
- https://devforum.roblox.com/t/automated-performance-profiling-with-microprofiler-and-assistant/4704417
- https://ui-labs.luau.page/docs/getstarted
- https://rohire.dev/blog/5-free-roblox-studio-plugins-2026
- https://picoo.io/blog/best-roblox-studio-plugins-2026
- https://devforum.roblox.com/t/what%E2%80%99s-your-setup-to-use-claude-code/4684713
