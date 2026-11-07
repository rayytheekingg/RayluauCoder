# Changelog

## UNVERIFIED items (re-check on next refresh)

Phase 0 note: the existing Ray Luau Coder repo was not available during this update (no public repo found, no files attached). Nothing below was compared against your previous rules. When merging, keep any custom rule of yours that this version does not contradict, and log any rule you drop.

- `const` locals in Roblox Studio: in Luau OSS 0.711 (RFC #166) and reported working by developers, no official Roblox announcement found.
- `MarketplaceService:BindReceiptHandler` ship date: third-party trackers say April 2026; earliest official record is a staff reply on 2026-06-02 (devforum 4664756). The API and `Enum.ReceiptDecision` themselves are verified in the API definitions.
- External sales of Listed products start date (about 2026-09-22, community thread only).
- Shared `self` types in the New Type Solver (RFC published, Roblox ship status unknown).
- Custom require aliases from `.luaurc` in Studio.
- Math constant names from RFC "Math constants".
- Luau 0.745 native auto-promotion rollout to Roblox servers.
- Lune 0.12.x, Rokit 1.2.0 release year, Wally 0.4.0-alpha.1 date, pesde 0.7.4.
- ReflectionService documentation and Extended Services plugin API details.
- 2.1.0: exact GuiState selector string form for StyleRules (for example `"TextButton:Hover"`); StyleQuery `SetCondition` value types.
- 2.1.0: which materials render `SurfaceType.Studs` (test Plastic and SmoothPlastic).
- 2.1.0: Unified Lighting full-release date and the exact rendering difference between `LightingStyle` Soft and Realistic (DevForum was in maintenance during research).
- 2.1.0: Procedural Models release status (docs carry no beta label; the April 2026 announcement was a Studio beta).
- 2.1.0: current Roblox image upload size limit (atlas sheets kept at 1024 px or less).
- 2.1.0: Fusion 0.3 and React-lua v17.2.1 release years (GitHub pages showed day and month only); UIBlur and ParticleEmitter2D exist in the API definitions with no announcement (not used).
- Not re-checked this cycle (long-standing, believed current): RunContext names, Parallel Luau API details, MemoryStore and MessagingService quota numbers, DataStore version API parameter lists, PolicyService field names, legacy chat retirement date, BodyMover class-level deprecation, `Instance:Remove`, `ChangeHistoryService:SetWaypoint` deprecation flag, profiler UI changes, subscription API names.

## 2.1.0 (2026-11-06): UI design, icons and studded maps

Minor version: adds content; no 2.0.0 rule or template changed behavior. Built only from the references Emir approved (research/ui-maps-reference-catalog.md, "Approved" section).

### Added
- references/: ui-design.md, ui-style-guide.md, icons.md, map-building.md, lighting-presets.md, design-workflow.md.
- templates/: Theme.luau, palettes.json, UIKit.luau, MenuManager.luau, IconAtlas.luau, ShopCatalog.luau, ShopService.luau, ShopUI.client.luau, LightingPresets.luau, StudMap.luau.
- tools/: build_icon_atlas.py (SVG or PNG to sprite sheets plus IconAtlas.luau), check_contrast.py (WCAG contrast for every palette pair).
- checklists/: ui-review.md, map-review.md.
- research/ui-maps-reference-catalog.md: 50 references with IDs, links, licenses, status and the approved set.
- SKILL.md: rules 16 and 17, "design UI" and "build a map" workflows, new index rows, UI and map trigger words.

### Changed
- input-ui.md: StyleQuery is released (2026-05-11), not beta; Styling Transitions released (2026-07-27). Points to ui-design.md.

### Research highlights
- UI Styling (StyleSheet, StyleRule, StyleDerive, StyleLink, tokens) released 2026-01-20; StyleQuery released 2026-05-11; Styling Transitions released 2026-07-27.
- UIShadow released early 2026; Upgraded UIShadow (text, inset, knockout, gradient shadows) is a Studio beta since 2026-10-14 and cannot be published yet; keep under 100 shadows on screen.
- Device Simulator and Network Simulator out of beta the week of 2026-10-12.
- `Lighting.Technology` is deprecated; new `LightingStyle` (Realistic, Soft) and `PrioritizeLightingQuality`; `ColorGradingEffect.TonemapperPreset` (Default, Retro).
- Icon licenses read from source on 2026-11-06: Lucide ISC, Tabler MIT, Phosphor MIT, Kenney CC0, game-icons.net CC BY 3.0 (credit authors), Builder fonts under Roblox's Builder font license. Remix Icon moved to a custom license in January 2026 (not used).
- The community-found BuilderIcons font is not covered by the Builder font license and is not used.

### Verification
- All 17 Luau templates (2.0.0 and 2.1.0) plus a generated IconAtlas.luau: `luau-lsp analyze` 1.70.1 with Roblox definitions and a Rojo 7.7.1 sourcemap, strict, 0 errors with the old solver and 0 with `LuauSolverV2`.
- StyLua 2.5.2 `--check`: clean. Selene 0.32.0 (luau std plus Roblox globals): 0 errors, 0 warnings.
- 40 Luau code blocks across all reference files parse.
- tools/build_icon_atlas.py on 10 Lucide icons: one 1024 x 256 sheet; every cell white, non-empty, inside its padding, and matching its IconAtlas.luau offset.
- tools/check_contrast.py: all 30 palette pairs pass (body text 4.5:1, large labels 3:1). Studded Classic secondary darkened from #1E8C3A to #1A7F34 to pass.
- Studio MCP was not connected, so no in-Studio screenshots were taken. Run the UI and map review checklists in Studio before shipping.

## 2.0.0 (2026-11-06)

Major version: templates change behavior (session-lock semantics, receipt idempotency, spatial query filters, init/start bootstrap) and the trigger description widened. If your repo was already past 1.x, bump the major from whatever it was.

### Added
- SKILL.md: 15 core rules, reference index, template index, write / review / fix workflows, Studio MCP rules, verification commands.
- references/ (11 files): luau-language, engine-runtime, networking-security, data-persistence, input-ui, monetization, performance, tooling, studio-plugins, deprecations, clean-code-standard.
- templates/: Main.server.luau (bootstrap), Service.luau, ModuleTemplate.luau, Cleaner.luau, Remotes.luau, RemoteHandler.luau, PlayerData.luau, ProcessReceipt.luau, default.project.json, selene.toml, stylua.toml, .luaurc.
- checklists/: code-review.md (pass/fail with severities), fix-workflow.md.

### Changed vs common pre-2025 practice (now enforced by the skill)
- Write for the New Type Solver (general release 2025-11-20).
- Require-by-string with `./`, `../`, `@self`, `@game`; implicit `Init` no longer supported.
- `RaycastParams.ExcludeInstances` / `IncludeInstances` (2026-04-07) instead of `FilterDescendantsInstances`.
- Input Action System (full release 2026-06-11) for new gameplay input.
- Server Authority (full release 2026-07-09): `Workspace.AuthorityMode = Server`, `BindToSimulation`, `Player:GetCameraState()`.
- DataStore budgets per experience, shared with Open Cloud since 2026-07-29; storage 500 MB + 1 MB per lifetime player.
- `BindReceiptHandler` for multi-system shops and Robux transfers; cross-game developer product sales removed 2026-05-30.
- Deprecations added from the API definitions: `Player:LoadCharacter` (use `LoadCharacterAsync`), `Plugin:CreateDockWidgetPluginGui` (use `...Async`), `Player:IsInGroup` and group rank methods (use `IsInGroupAsync` / `GroupService:GetRolesInGroupAsync`), `MarketplaceService:GetProductInfo` (use `GetProductInfoAsync`), and the rest of the table in references/deprecations.md.
- Studio built-in MCP server replaces the open-source bridge; `open_cloud_invoke` added 2026-11-04.

### Verification (Phase 4)
- Templates: `luau-lsp analyze` 1.70.1 with Roblox definitions and a Rojo 7.7.1 sourcemap, strict mode: 0 errors under the old solver, 0 errors with `LuauSolverV2` enabled.
- Templates: StyLua 2.5.2 `--check`: clean.
- Templates: Selene 0.32.0: 0 errors, 0 warnings. The full `roblox` std could not be generated in the build environment (Roblox API dump download blocked), so Selene ran with the `luau` base std plus Roblox globals. Run `selene generate-roblox-std` and re-lint locally to confirm.
- Reference docs: all 31 Luau code blocks parse (StyLua, Luau syntax). Snippets that reference example variables were type checked with unknown-global errors ignored; no other type errors.
- API names: every class, member, enum and signature used in templates and docs was checked against luau-lsp `globalTypes.d.luau` (main, fetched 2026-11-06). Corrections made: pathfinding replacement, TeleportOptions field.
- Spot checks against cited sources (7 web pages, 2026-11-06): Server Authority release, unified DataStore limits, spatial filters, IAS release, New Type Solver GA, Studio MCP Open Cloud update, developer products docs. All matched; three entries refined (MCP post date 2026-11-04, unified limits announced 2026-07-15 and live 2026-07-29, external-sales wording and date marked unverified).
- Fix workflow test on your own code: not run, because no test code was provided. Run it on one of your scripts and add the result to the PR.

## Sources (verified as of 2026-11-06)

Official Roblox:
- New Type Solver GA: devforum.roblox.com/t/general-release-luau%E2%80%99s-new-type-solver/4084991
- Require-by-string: devforum.roblox.com/t/introducing-require-by-string/3405078
- Server Authority: devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993, /4606949, /4503827, /4139157
- Input Action System: devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416, /3890979, Input Action Manager /4737890
- Character Controller Library: devforum.roblox.com/t/full-release-the-future-of-character-movement-character-controller-library/4565267, /4403904
- Spatial query filters: devforum.roblox.com/t/new-spatial-query-filters/4563575
- DataStores: devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240, /4504347; create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits
- Weekly recap April 2026: devforum.roblox.com/t/weekly-recap-april-6-10-2026/4568634
- UnreliableRemoteEvents: devforum.roblox.com/t/introducing-unreliableremoteevents/2724155
- Studio MCP: devforum.roblox.com/t/assistant-updates-studio-built-in-mcp-server-and-playtest-automation/4474643, /4820583, /4975849
- Studio Script Sync: devforum.roblox.com/t/full-release-studio-script-sync/4688454
- Creator Roadmap Fall 2026: devforum.roblox.com/t/creator-roadmap-2026-fall-update/4880208
- Docs: create.roblox.com/docs/production/monetization/developer-products, /reference/engine/classes/MarketplaceService, /reference/engine/classes/InputAction, /cloud/reference/features/luau-execution

Luau and tools:
- github.com/luau-lang/luau/releases (0.739 to 0.745), luau.org/types/generics, rfcs.luau.org
- github.com/JohnnyMorganz/luau-lsp (releases and scripts/globalTypes.d.luau)
- github.com/rojo-rbx/rojo/releases, github.com/Kampfkarren/selene/releases, github.com/JohnnyMorganz/StyLua/releases
- github.com/lune-org/lune, github.com/rojo-rbx/rokit, github.com/UpliftGames/wally, github.com/pesde-pkg/pesde, github.com/jsdotlua/jest-lua

## Update procedure

To refresh: re-run Phase 1 limited to release notes and DevForum announcements since the last verified date, patch only affected files, re-run Phase 4, bump the version, open a new dated branch and PR.

Quick deprecation refresh:
```bash
curl -sSLO https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau
grep -n -A1 "@\[deprecated" globalTypes.d.luau > deprecated-now.txt
```
Diff `deprecated-now.txt` against the previous run and add new rows to references/deprecations.md.
