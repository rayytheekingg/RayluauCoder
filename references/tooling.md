# Tooling Reference

Verified as of 2026-11-06. Versions checked against each project's GitHub releases page unless marked.

## 1. Versions

| Tool | Version | Date | Status | Source |
|---|---|---|---|---|
| Rojo | 7.7.1 | 2026-10-02 | released (7.7.0, 2026-07-02, moved sync to websockets + MessagePack) | github.com/rojo-rbx/rojo/releases |
| luau-lsp | 1.70.1 | 2026-09-27 | released | github.com/JohnnyMorganz/luau-lsp/releases |
| StyLua | 2.5.2 | 2026-05-16 | released | github.com/JohnnyMorganz/StyLua/releases |
| Selene | 0.32.0 | 2026-10-01 | released (parses `if local` and `if const`) | github.com/Kampfkarren/selene/releases |
| Luau CLI (`luau-analyze`) | 0.745 | 2026-10-30 | released | github.com/luau-lang/luau/releases |
| Lune | 0.11.1 | 2026-10-21 | released; 0.12.x [UNVERIFIED] | github.com/lune-org/lune/releases |
| Rokit | 1.2.0 | [UNVERIFIED year] | released | github.com/rojo-rbx/rokit/releases |
| Wally | 0.3.2 stable; 0.4.0-alpha.1 | 2023-06-05; [UNVERIFIED] | released / pre-release | github.com/UpliftGames/wally/releases |
| pesde | 0.7.3 on GitHub; 0.7.4 on crates.io | 2026-03-18; [UNVERIFIED] | released | github.com/pesde-pkg/pesde |
| Jest-Lua | 3.10.0 | 2024-10-02 | released, no newer | github.com/jsdotlua/jest-lua |

The luau-lsp, Selene and StyLua versions above were downloaded and run on 2026-11-06 to lint this skill's templates.

## 2. Two workflows

**Studio only (no external editor)**
- Studio Script Sync, full release 2026-06-17 (devforum.roblox.com/t/full-release-studio-script-sync/4688454), syncs scripts to files on disk so Git and AI tools can see them without Rojo.
- Turn on strict mode per file with `--!strict`, and the New Type Solver for strict scripts with `Workspace.UseNewLuauTypeSolver`.

**Rojo + VS Code**
- `rokit init`, then `rokit add rojo-rbx/rojo`, `rokit add JohnnyMorganz/StyLua`, `rokit add Kampfkarren/selene`, `rokit add JohnnyMorganz/luau-lsp` pins tool versions per project.
- `rojo serve` plus the Rojo Studio plugin syncs files into Studio.
- VS Code extensions: Luau Language Server (luau-lsp), StyLua, Selene, Rojo.
- `rojo sourcemap --watch -o sourcemap.json` lets luau-lsp resolve instance-path requires.
- Packages: Wally (`wally.toml`) or pesde. Commit the lockfile.
- Project file: templates/default.project.json. Lint configs: templates/selene.toml, templates/stylua.toml. Editor config: templates/.luaurc.

## 3. Lint and format commands

```bash
stylua src/                      # format
stylua --check src/              # CI: fail on unformatted files
selene src/                      # lint (needs selene.toml with std = "roblox")
luau-lsp analyze --platform=roblox --definitions=@roblox=globalTypes.d.luau --sourcemap=sourcemap.json src/
```

Download the Roblox type definitions used by `luau-lsp analyze` from `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau`. The definitions file also carries `@[deprecated {use = "..."}]` attributes, which is the fastest way to check whether an API is deprecated (see deprecations.md).

## 4. Testing

- Jest-Lua for unit tests of pure modules. Run in Studio with a test runner script, or headless through Lune or the Open Cloud Luau Execution API.
- TestEZ is legacy; keep existing TestEZ suites, write new ones in Jest-Lua.
- Test the pure logic (damage math, inventory rules, data migration) and keep Roblox API calls at the edges so the logic is testable.

## 5. Open Cloud and Luau Execution

- Luau Execution API: `POST /cloud/v2/universes/{universe_id}/places/{place_id}/luau-execution-session-tasks` (marked Stable). Up to 5 minutes per task, 10 concurrent tasks per place (create.roblox.com/docs/cloud/reference/features/luau-execution). Use it for CI tests and headless scripts against a real place.
- Open Cloud DataStore calls share the per-experience budget with live servers since 2026-07-29 (data-persistence.md).
- Roblox open-sourced a CLI for running local Luau projects on Open Cloud and a Signals library in April 2026 (devforum weekly recap 4568634).
- Legacy game pass and developer product web endpoints were deprecated 2026-04-23 in favor of Open Cloud.

## 6. AI assistants and the Studio MCP server

- Studio has a built-in MCP server (2026-03-05, devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643). Enable it in Assistant, Manage MCP Servers. It is the recommended path; the open-source `studio-rust-mcp-server` is no longer actively developed.
- Every MCP tool takes a `studio_id` so several Studio windows and agents can work at once (devforum.roblox.com/t/studio-mcp-multi-agent-improvements-and-connected-ai-clients/4820583).
- 2026-11-04 (updated 2026-11-05): MCP gained `open_cloud_invoke`, which calls Open Cloud APIs with no API key (devforum.roblox.com/t/studio-mcp-server-updates-open-cloud-access-in-your-mcp-client-and-asset-import-workflows/4975849). Permissions are set per game by the user and the agent cannot enable them itself: Open Cloud scopes, upload folders, "Save & load data" (whether DataStore and MemoryStore calls work from `execute_luau`) and internet access (HTTP domains). Also new: asset import from tools like Blender (uploads are permanent and moderated), the skills `rbx-open-cloud-usage`, `rbx-permissions` and `rbx-import-asset`, an MCP status indicator, and background playtests. Known issue: `execute_luau` cannot make HTTP requests in an unsaved place; save first.
- Playtest automation lets an AI client start a playtest, read output and stop it.

Rules when Claude is connected to Studio through MCP:
- MCP-run Luau is code execution with write access to the open place. Read before writing, and change only what the user asked.
- Prefer editing script sources over running one-off command-bar code that mutates the place.
- Wrap place edits in a ChangeHistoryService recording so the user can undo them (studio-plugins.md).
- Never call `open_cloud_invoke` on DataStore write endpoints without the user confirming; it spends the live game's budget and touches real player data.
- After a change, run a playtest and read the output before reporting success.
