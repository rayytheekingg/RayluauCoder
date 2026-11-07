---
name: ray-luau-coder
description: Write, review, and fix Roblox and Luau code, and design Roblox UI and maps, to the current (Nov 2026) engine. Use for Roblox, Luau, Roblox Studio, game scripts, ModuleScripts, DataStore, RemoteEvent, ProcessReceipt, Rojo, Studio plugin, Server Authority, Input Action System, UI, GUI, HUD, shop UI, menus, icons, studs, studded or toy style, maps, lighting, obby, building, and fixing or cleaning up existing Roblox code.
---

# Ray Luau Coder

Version 2.1.0. Verified against Roblox and Luau as of 2026-11-06.

This skill makes Claude write Roblox code that is current, secure, and clean, and fix existing code with the smallest safe change. Read this file first. Open a reference file only when the task touches its topic.

## When to use

- Writing any Roblox script, LocalScript, ModuleScript, Studio plugin, or Rojo project file
- Reviewing or fixing Roblox code the user pastes, attaches, or has open in Studio
- Questions about Roblox APIs, Luau types, DataStores, remotes, monetization, input, UI, performance, or tooling
- Designing or building in-game UI (HUD, shop, menus, icons) and bright studded maps with lighting

## Core rules (always apply)

1. `--!strict` is the first line of every file. Code must type check under the New Type Solver.
2. The server decides every outcome. Clients send intent; the server validates rate, type, range, ownership and state.
3. Never `RemoteFunction:InvokeClient`.
4. Player data: `UpdateAsync` with a session lock, save on `PlayerRemoving`, save all players in `BindToClose`, `pcall` with backoff on every call. Never `SetAsync` for player data.
5. Developer products: grant only in `ProcessReceipt` or `BindReceiptHandler`, dedupe on `PurchaseId`, return granted only after the save succeeds.
6. Use `task.wait`, `task.spawn`, `task.defer`, `task.delay`. Never `wait`, `spawn`, `delay`.
7. No deprecated APIs (references/deprecations.md). Common ones: `FindPartOnRay`, `SetPrimaryPartCFrame`, `Humanoid:LoadAnimation`, `Player:LoadCharacter`, `GetProductInfo`.
8. Spatial queries use `RaycastParams.ExcludeInstances` / `IncludeInstances` and reuse the params object.
9. New gameplay input uses the Input Action System. Server Authority games move characters inside `RunService:BindToSimulation`.
10. Every per-player or per-character connection is tracked by a Cleaner and released. Every table keyed by Player is cleared on leave.
11. Write client code as if StreamingEnabled is on.
12. Services once at the top with `game:GetService`. No magic numbers. Tunables live in a Config module.
13. Typed signatures on every function; `export type` for public shapes; `unknown` for remote arguments; `any` only with a comment.
14. Early returns, functions under about 40 lines, one responsibility per module.
15. Do not rewrite working code that is not broken. When fixing, change what is wrong and leave the rest.
16. UI colors, fonts, sizes and timings come from Theme tokens; UI sends requests and never decides rewards or prices.
17. UI works on touch, mouse and gamepad: `Activated` not `MouseButton1Click`, 44 px targets, safe-area insets, gamepad selection on open.

## Reference index

| File | Open when the task involves |
|---|---|
| references/luau-language.md | Types, generics, syntax, `buffer`, `vector`, native codegen, type solver questions |
| references/engine-runtime.md | task library, RunService events, require, Parallel Luau, streaming, characters, physics, spatial queries |
| references/networking-security.md | Remotes, validation, exploits, Server Authority |
| references/data-persistence.md | DataStores, session locks, limits, MemoryStore, MessagingService, leaderboards |
| references/input-ui.md | Input Action System, UserInputService, UI layout, chat, localization |
| references/monetization.md | Developer products, game passes, ProcessReceipt, BindReceiptHandler, policy |
| references/performance.md | Lag, memory leaks, per-frame cost, profiling |
| references/tooling.md | Rojo, luau-lsp, Selene, StyLua, packages, tests, Open Cloud, Studio MCP |
| references/studio-plugins.md | Writing Studio plugins, undo recording, dock widgets |
| references/deprecations.md | Any review or fix; any API you are not sure is current |
| references/clean-code-standard.md | Formatting, naming, layout, comments, folder structure |
| references/ui-design.md | Styling API, StyleQuery, UIShadow, layout, gamepad and touch, menus, frameworks, Figma import, UI testing |
| references/ui-style-guide.md | Style directions (Studded Classic, Candy Pop, Neon Night), tokens, palettes, UI do and don't |
| references/icons.md | Free icon sets and licenses, CREDITS, SVG to atlas pipeline, uploading |
| references/map-building.md | Stud look, color for bright worlds, level design by genre, Procedural Models, map performance |
| references/lighting-presets.md | Unified Lighting, LightingStyle, preset values per mood |
| references/design-workflow.md | Spec, mockup, build, screenshot, critique loop; Studio MCP rules for design |

Source links and approved references live in research/. Check research/ui-maps-reference-catalog.md and research/coding-sources.md before citing a source or adding a new one. Only use references marked approved.

## Templates

Copy and adapt. All pass luau-lsp analyze (old and New Type Solver), Selene and StyLua with zero issues.

| Template | Purpose | Place at |
|---|---|---|
| templates/Main.server.luau | Server bootstrap: require services, init, start | ServerScriptService/Server/Main |
| templates/Service.luau | Service skeleton with a validated, rate-limited remote | ServerScriptService/Server/Services |
| templates/ModuleTemplate.luau | Pure shared module shape (Inventory example) | ReplicatedStorage/Shared |
| templates/Cleaner.luau | Track and release connections, instances, threads | ReplicatedStorage/Shared |
| templates/Remotes.luau | Single source of all RemoteEvents | ReplicatedStorage/Shared |
| templates/RemoteHandler.luau | Rate limit + validation wrapper for OnServerEvent | ServerScriptService/Server |
| templates/PlayerData.luau | Session-locked DataStore profiles with retries and BindToClose | ServerScriptService/Server/Services |
| templates/ProcessReceipt.luau | Idempotent developer product grants | ServerScriptService/Server/Services |
| templates/Theme.luau + palettes.json | Design tokens, 3 palettes, StyleSheet builder, palette switching | ReplicatedStorage/Shared |
| templates/UIKit.luau | screen, panel, label, button, iconButton, modal, tabs, toast, progressBar | ReplicatedStorage/Shared |
| templates/MenuManager.luau | One menu at a time, back stack, gamepad selection, Back action (IAS) | ReplicatedStorage/Shared |
| templates/IconAtlas.luau | Icon name to sprite-sheet rect (generated by tools/build_icon_atlas.py) | ReplicatedStorage/Shared |
| templates/ShopCatalog.luau, ShopService.luau, ShopUI.client.luau | Full shop: shared catalog, server validation, client UI | Shared / Services / StarterPlayerScripts |
| templates/LightingPresets.luau | Apply or tween SunnyToy, Sunset, NeonNight, Spooky | ReplicatedStorage/Shared |
| templates/StudMap.luau | Stud parts, checkered floors, seeded obby sections, kill brick and checkpoint handling | ServerScriptService/Server |
| tools/build_icon_atlas.py, tools/check_contrast.py | Icon atlas builder; WCAG contrast check for palettes | project tools |
| templates/default.project.json | Rojo project layout | project root |
| templates/selene.toml, stylua.toml, .luaurc | Lint, format, strict mode | project root |

## Workflow: write new code

1. Settle the context: server, client or shared; Studio-only or Rojo; Server Authority on or off.
2. Start from the closest template. Keep its layout order.
3. Decide what the server owns. Design remotes as intent ("RequestPurchase(itemId)"), never results.
4. Write the code to the core rules. Open the matching reference for anything beyond basics.
5. Self-check against checklists/code-review.md before answering.
6. Output: file path above each code block, full files, no placeholders like `-- rest of code here`. If an ID must be filled in (product ID, asset ID), use an obvious example value and say so in one line.

## Workflow: design UI

1. Spec first: screen goal, style direction (references/ui-style-guide.md), palette, elements, what the server owns.
2. Mock up in HTML or SVG with the palette hex values when the user wants to see it first (references/design-workflow.md).
3. Build with Theme, UIKit and MenuManager. Three ScreenGuis max (HUD, Menus, Popups). Icons from the atlas.
4. Every purchase or reward goes through Remotes to a server service (see ShopService).
5. Check with checklists/ui-review.md; with Studio MCP, screenshot at 1920x1080, 1024x768, 390x844 and fix (max 2 loops).

## Workflow: build a map

1. Block out the path with gray parts and playtest it.
2. Apply a zone palette (60-30-10), studs (references/map-building.md), then a lighting preset (LightingPresets).
3. Use StudMap or Procedural Models for repeated pieces; tag hazards and checkpoints; run StudMap.startHazards on the server.
4. Check with checklists/map-review.md and profile on a low-end device.

## Workflow: review

1. Run checklists/code-review.md against the code.
2. Report findings ranked Critical, High, Medium, Low, one line each, with the line or function name.
3. If nothing is wrong at a level, say so plainly. Do not invent findings.

## Workflow: fix (full detail in checklists/fix-workflow.md)

When given code:
1. Identify script type and context (server / client / module, RunContext).
2. Flag deprecated APIs using references/deprecations.md.
3. Security holes (trusting the client, missing validation).
4. Data-loss risks (SetAsync overwrites, no session lock, no BindToClose).
5. Performance problems.
6. Type errors under `--!strict`.
7. Style violations.

Output corrected full files plus a short change list ranked by severity. Do not rewrite working logic that is not broken.

## Working in Studio through MCP

- Studio's built-in MCP server is the supported bridge (references/tooling.md section 6).
- Read the script or instance before changing it. Change only what was asked.
- Wrap place edits in a ChangeHistoryService recording so the user can undo.
- After edits, playtest and read the output before saying it works.
- Never write to live DataStores through `open_cloud_invoke` without the user confirming.

## Verification commands

```bash
stylua --check src/
selene src/
luau-lsp analyze --platform=roblox --definitions=@roblox=globalTypes.d.luau --sourcemap=sourcemap.json src/
```

The Roblox definitions file is at `https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau`. Its `@[deprecated {use = "..."}]` attributes are the fastest deprecation check.

## Response style

- Code first, then a short list of what changed or what to configure. No Luau basics unless asked.
- One line per change in change lists.
- If something could not be verified or run, say so in one line.
- No em dashes in prose.
