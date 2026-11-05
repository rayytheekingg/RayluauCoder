---
name: luau
description: Write, review, debug, and check Roblox game code in Luau. Use for ANY Roblox, Roblox Studio, Rojo, or Luau task, including .luau files, Script, LocalScript, ModuleScript, RemoteEvent, DataStore, protecting a game from exploiters, Output errors, lag, and "my Roblox game" requests.
---

# Roblox Luau

Write Roblox code that is secure, typed, cleaned up, and checked. Never guess an API.

## Tools

`RUN` means `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run"`. If the variable is empty, `scripts/run` is two folders above this file.

| Command | Use |
| --- | --- |
| `RUN api-lookup Class.Member` | Verify an API. Also takes `Class`, `Enum.Name.Item`, and `--members` |
| `RUN check <path>` | Run the type checker, selene, stylua, neat, and the deprecated-API scan |
| `RUN neat <path>` | Check style rules. `--fix` runs StyLua only |
| `RUN setup` | Print install steps for missing tools |
| `RUN maintain` | Refresh the docs index, and audit this plugin against Roblox's docs. Add `--links` to check links |

`api-lookup` also takes libraries, data types, and globals, such as `task.wait` and `Vector3.new`. It uses the live Studio API, and shows what replaces a deprecated API.

`api-lookup` exit codes: 0 found, 1 not found, 2 deprecated, 4 could not get the dump.
`check` exit codes: 0 pass, 1 problems, 2 incomplete.
`neat` exit codes: 0 neat, 1 findings, 2 path or config error, 3 `--fix` needs StyLua.

`check` reports which type checker ran:

- **luau-lsp:** checks Roblox API calls with Roblox definitions. Without a sourcemap, it cannot resolve child instance paths or requires, and it says how many it skipped. With one, it reports broken `require` paths, but a misspelled child used outside `require` can still pass.
- **luau-analyze:** the fallback. It treats Roblox names as `any`, so use `api-lookup` for Roblox APIs. `table.insert(list, robloxCall())` can report a false overload error. Assign the call to a local first.

If the Roblox Studio MCP tools are available, such as `mcp__Roblox_Studio__execute_luau`, you can run code in a real playtest. Read `references/studio-testing.md` first.

Commands for the user: `/rayluau-new`, `/rayluau-check`, `/rayluau-review`, `/rayluau-choose`, `/rayluau-neat`, `/rayluau-test`.

## Workflow

1. Read the existing code and match its structure. Find out whether it uses Rojo or Studio only.
2. Decide what runs on the server and what runs on the client.
3. When a task needs a framework, library, data system, UI system, networking system, or architecture choice, read `references/systems.md` and follow its choosing rules.
4. Read only the other references that the task needs.
5. Start from `templates/code/` when a template fits. See `samples/` for complete examples.
6. Run `api-lookup` whenever you are unsure that an API exists or is current.
7. Write the code, following `references/code-style.md`.
8. Run `check` after every code change. Fix what it reports and run it again.
9. If Roblox Studio MCP tools are available and the change affects runtime behaviour, playtest it and read the Output. Follow `references/studio-testing.md`. `references/companions.md` covers connecting Studio and editing through it.
10. Report the results using the rules under "Honest reporting".

## References

| Read | When |
| --- | --- |
| `references/systems.md` | Choosing frameworks, libraries, tools, and game architecture |
| `references/companions.md` | Studio plugins, connecting Studio, using the Studio MCP tools |
| `references/code-style.md` | Writing or tidying code, naming, file order, neat config |
| `references/studio-testing.md` | Running code in a Studio playtest |
| `references/language.md` | Luau syntax, types, generics, tables |
| `references/services.md` | Roblox services, script lifecycle, task library, replication |
| `references/security-and-data.md` | Remotes, purchases, exploits, DataStores |
| `references/performance.md` | Lag, memory, per-frame code, network traffic |
| `references/pitfalls.md` | Code runs but behaves incorrectly |
| `references/debugging.md` | Output errors and stack traces |

## Script placement

| Code | Type | Location |
| --- | --- | --- |
| Server logic, currency, saving | `Script` | `ServerScriptService` |
| Server-only modules | `ModuleScript` | `ServerScriptService` or `ServerStorage` |
| Input, camera, player effects | `LocalScript` | `StarterPlayerScripts` |
| Character-specific client code | `LocalScript` | `StarterCharacterScripts` |
| UI code | `LocalScript` | `StarterGui` or `StarterPlayerScripts` |
| Code shared by both sides | `ModuleScript` | `ReplicatedStorage` |
| Remotes | `RemoteEvent` | `ReplicatedStorage` |

Rojo file names: `name.server.luau` is a `Script`, `name.client.luau` is a `LocalScript`, and `name.luau` is a `ModuleScript`. `init.server.luau`, `init.client.luau`, or `init.luau` turns its folder into that script.

Everything in `ReplicatedStorage` can be read by exploiters. Keep secrets and server-only rules out of it.

## Required rules

### Never trust the client

- Treat every remote argument as hostile. Annotate it as `unknown` until validated.
- Validate in this order: rate limit, types, allowed values, game rules, then act.
- Reject `NaN` and infinite numbers with `math.isfinite`.
- Check that an Instance argument really is one, with the expected class and location.
- The server owns prices, currency, damage, cooldowns, inventory, and rewards.
- The client sends what it wants, such as an item ID. It never sends a price or a result.
- Check distance on the server for interactions and combat. Repeat checks for `ProximityPrompt`, `ClickDetector`, and `Touched`, which clients can trigger.

### Meet platform rules

- Filter displayed text you don't fully control on the server, using `templates/code/FilterText.luau`. Chat through `TextChatService` is filtered for you.
- If Robux can lead to a random reward, check `PolicyService` for each player and show the odds first.
- Delete personal data when right-to-be-forgotten requests arrive.

### Handle data failures

- Wrap every DataStore call in `pcall`.
- Retry temporary failures with capped exponential backoff and jitter. Do not retry invalid requests.
- Prefer `UpdateAsync` when a write depends on current data or several servers could write.
- Keep a server-side session copy. Save periodically, on `PlayerRemoving`, at `BindToClose`, and after purchases.
- If a load fails, do not save defaults over the player's real data.
- Use stable user IDs in keys, never display names.
- Use session locks for trading and other duplication-sensitive data.
- Grant developer products through `templates/code/ProductReceipts.luau`: once per `PurchaseId`, and report success only after saving.

### Clean up

- Disconnect every connection that outlives its purpose.
- Remove per-player table entries on `PlayerRemoving`.
- Give classes and long-lived objects a destroy method.
- Cancel loops and threads when their owner goes away.

### Use current APIs

- Use `task.wait`, `task.spawn`, `task.defer`, and `task.delay`. Never use the legacy `wait`, `spawn`, or `delay`.
- Use `:Connect`, `:Destroy`, `:PivotTo`, `workspace:Raycast`, and `Animator:LoadAnimation`.
- Get services with `game:GetService`.
- Set `Parent` last when creating an instance.
- Check method names from memory or old tutorials with `api-lookup`, because many now have `Async` replacements.
- Expect deferred events: handlers run after the current code yields, not during the fire.

### Type where practical

- Start new files with `--!strict`.
- Annotate function parameters, return values, module exports, and empty tables.
- Use `export type` for shared shapes.
- Avoid `any` except at real boundaries, such as data loaded from a DataStore. Validate after those boundaries.
- Use `::` casts only when you have checked the value or the engine guarantees it.

### Write dependable code

- Use `WaitForChild` on the client for replicated instances. Handle `nil` when using `FindFirstChild`.
- Connect `PlayerAdded`, then loop over `Players:GetPlayers()` for players who already joined.
- Assume characters can be missing, dead, or replaced at any time.
- Keep `RunService` handlers small. Use the lowest update rate that works.
- Wrap long-running game loops so one error does not stop them forever.
- Do not add a framework or package unless the project uses one, the user asks, or `references/systems.md` identifies a specific need.

### Keep code neat

New and changed code must pass `neat` and the quality bar in `references/code-style.md` before the work is called finished.

- Use clear names, small functions, early returns, and the standard file order.
- Explain why in comments, not what.
- Leave no dead code, commented-out code, leftover debug prints, or unexplained numbers.
- Tidying must not change behaviour. Don't tidy unrelated code unless asked.
- If existing code you did not touch has findings, report them instead of changing them.

## Honest reporting

Finish with what you changed and the `check` result.

- Quote the `RESULT` line. `INCOMPLETE` is not a pass.
- List every skipped tool, and say which type checker ran.
- If no type checker ran, state that syntax and types were not checked.
- If `luau-analyze` was the type checker, state that Roblox API calls were not type-checked.
- Say whether unverified APIs remain.
- Never claim code was tested in Roblox Studio unless it was.
- Name what still needs a Studio test, such as remotes with two players, data saving, physics, and UI.

Automated playtests use `templates/code/MockDataStore.luau`. For manual DataStore testing in Studio, say that the place must be published and "Enable Studio Access to API Services" must be on, and warn that Studio can then write to real data.

## Source of truth

If a reference conflicts with an official doc or `api-lookup`, trust those sources:

- https://create.roblox.com/docs
- https://luau.org
