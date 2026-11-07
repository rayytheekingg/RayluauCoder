# Roblox and Luau Changes Since 2024 That Change How You Code

Verified as of 2026-11-06. One page. Details and sources are in the Ray Luau Coder reference files.

**1. Types: New Type Solver is live (2025-11-20).** Default for nonstrict and nocheck scripts. Strict scripts opt in with `Workspace.UseNewLuauTypeSolver = Enabled`. Old solver stays through 2026. Keep `--!strict` on every file and write code that passes the new solver. Use `f<<T>>()` for explicit generics.

**2. Requires: use paths.** `require("./Sibling")`, `require("../Shared/Util")`, `require("@self/Child")`, `require("@game/ReplicatedStorage/Shared/Config")`. A bare name with no prefix is an error, and implicit `Init` children are no longer supported.

**3. Server Authority (2026-07-09).** Set `Workspace.AuthorityMode = Server` for PvP, racing and movement games. The server simulates, the client predicts, and speed or fly hacks get rejected automatically. Movement code moves into `RunService:BindToSimulation` and must be deterministic. `CameraAction` is gone; use `Player:GetCameraState()`.

**4. Input Action System (2026-06-11).** `InputContext`, `InputAction`, `InputBinding` replace ContextActionService for new gameplay input, with one set of actions across keyboard, gamepad and touch. Required under Server Authority. Default PlayerScripts flip to IAS by default in early 2027, so test custom controls with `PlayerScriptsUseInputActionSystem = Enabled` now.

**5. DataStores: one budget per experience (2026-07-29).** In-game and Open Cloud calls share the same per-minute limit (base 300 plus a CCU multiplier). Storage is 500 MB plus 1 MB per lifetime player. A runaway admin tool can now throttle live players. Session-locked `UpdateAsync` stays the only safe way to save player data.

**6. Purchases are audited.** Listed developer products can sell outside your game, and Roblox checks your ProcessReceipt continuously. Broken ones get a Creator Hub banner and stop appearing outside the game. Dedupe on `PurchaseId`, save before returning `PurchaseGranted`, and treat "player not in this server" as normal. `BindReceiptHandler` lets separate systems own their own product IDs. Cross-game product sales ended 2026-05-30.

**7. Raycasts: new filters (2026-04-07).** `params.ExcludeInstances = { character }` replaces `FilterDescendantsInstances` plus `FilterType`. Faster, and the old pair will be deprecated later.

**8. More methods became Async.** `Player:LoadCharacterAsync`, `IsInGroupAsync`, `GetProductInfoAsync`, `PlayerOwnsAssetAsync`, `ApplyDescriptionAsync`, `PlayEmoteAsync`, `CreateDockWidgetPluginGuiAsync`. Group rank and role checks move to `GroupService:GetRolesInGroupAsync`. Async methods yield, so wrap them in `pcall`.

**9. Characters.** The Luau Character Controller Library is available for live games (2026-04-20) as an alternative to the Humanoid controller. Client animation throttling for distant characters is always on.

**10. Tooling and AI.** Studio has a built-in MCP server (2026-03-05), and since 2026-11-04 it can call Open Cloud APIs with per-game permissions you control. Studio Script Sync (2026-06-17) puts scripts on disk without Rojo. Current tool versions: Rojo 7.7.1, luau-lsp 1.70.1, Selene 0.32.0, StyLua 2.5.2, Luau 0.745.

**What did not change:** the client is never trusted, `task.*` replaces `wait/spawn/delay`, `Destroy` does not clean up connections you made on other objects, and profiling comes before optimizing.
