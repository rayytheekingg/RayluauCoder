# Choosing Roblox systems

Checked: 2026-11-04. If this date is over 6 months old, recheck a third-party option's latest release, archived flag, and license on its repo before recommending it.

**Status words:** Active means a commit since 2026-05-04. Quiet means not archived, with no commit since then. Quiet does not mean abandoned, but expect to fix problems yourself. Archived means do not start new work with it.

## Choosing rules

1. Follow the project's existing systems unless they cause a real problem. Name the problem before suggesting a migration.
2. Prefer Roblox built-ins, then the simplest option that meets the need.
3. Add a dependency only for a specific need, and name that need.
4. Don't recommend a library based on popularity alone.
5. Measure before choosing a tool for performance reasons.
6. Choose for the team too. A skilled solo developer and a large team can reasonably pick differently.

## How to decide

1. Check `default.project.json`, `wally.toml`, `pesde.toml`, `rokit.toml`, `Packages/`, and existing `require` calls.
2. Ask what the feature needs: players per server, entity counts, trading, competition, UI size, and team size.
3. Start at the default in the matching category below.
4. Move to an alternative only if its "Choose when" condition is true now, not someday.

## Project structure

**Default:** plain service modules.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Plain service modules | Almost always. Each service has a `start` function, and one bootstrap script starts them in order | A team already works well in a framework | Low complexity, no performance cost, no dependencies | Built in |
| [Knit](https://github.com/Sleitnick/Knit) | Maintaining a project that already uses it | New projects | Framework lock-in, plus its Promise-based startup | Archived. v1.7.0, 2024-02-04, MIT |
| [Flamework](https://github.com/rbxts-flamework/core) | The team already uses roblox-ts and wants generated type guards | Luau-only projects, because it requires TypeScript | High: compiler, transformer, and TypeScript toolchain | Quiet. v1.2.3, 2024-06-04, last commit 2025-09-04, MIT |

A bootstrap script can require each service, then call `start` on each one. Avoid cross-service work at require time, which prevents most circular dependency problems.

## Player data

**Default:** the built-in DataStore wrapper in `templates/code/PlayerData.luau`, unless duplication or loss would seriously hurt the game.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Built-in wrapper | No trading, low-value data, and simple saves | Trading, valuable items, or frequent teleports | Low. You own the code and its bugs | Built in |
| [ProfileStore](https://github.com/MadStudioRoblox/ProfileStore) | Trading, valuable items, or teleport-heavy games that need session locking | Leaderboards, global state, or frequent writes from many servers | Low: one ModuleScript, plus a session wait on join | Quiet. No tagged releases, last commit 2025-07-31, Apache-2.0 |
| Custom session locking | ProfileStore truly cannot fit | Almost always | High. Crashes, teleports, and expired locks are easy to get wrong | Your responsibility |

Don't start new work on DataStore2. Roblox's [best practices page](https://create.roblox.com/docs/cloud-services/data-stores/best-practices) calls it legacy. Store shared or global data separately from session-locked player profiles.

## Networking

**Default:** `RemoteEvent`.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| `RemoteEvent` | Reliable one-way messages | Very frequent cosmetic updates | Low complexity, no dependencies. Generic encoding uses more bandwidth | Built in |
| `UnreliableRemoteEvent` | Frequent cosmetic or replaceable data | Anything that must arrive, or payloads over 1,000 bytes | Low. Handle drops and stale messages | Built in |
| `RemoteFunction` | A client needs an answer from the server | The server invoking clients, which can hang it | Low. Callers yield | Built in |
| [Blink](https://github.com/1Axen/blink) | You measured a bandwidth or CPU problem and send many typed packets | Small games, or no measured problem | Medium: schema file, build step, generated code | Active. v0.18.9, 2026-09-19, MIT |
| [Zap](https://zap.redblox.dev/) | Same need as Blink | Same as Blink | Medium: schema file, build step, generated code | Active. v0.6.29, 2026-06-23, MIT |

Blink and Zap both use a schema language and packed buffers, and both validate received data. If neither is already used, test one real packet in each and keep the better measured result.

Packet validation only proves the data has the right shape. Keep rate limits and game rule checks on the server.

## UI

**Default:** plain Instances, built in Studio or code.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Plain Instances | Small or mostly static UI, or designers working in Studio | Large UI with many state-driven lists | Low, no dependencies. Manual updates grow messy | Built in |
| [React Lua](https://github.com/jsdotlua/react-lua) | Large UI, a team that knows React, or a Roact project moving forward | Small UI, or no package setup | Medium: package manager, more concepts, and rendering overhead | Quiet. v17.2.1, 2024-12-04, last commit 2025-05-23, MIT |
| [Fusion](https://github.com/dphfox/Fusion) | A project already using Fusion, or a team that prefers its reactive style | Teams that need a stable 1.0 API | Medium. The latest release is a pre-1.0 beta | Quiet. v0.3-beta, 2024-08-30, last commit 2026-02-02, MIT |
| [Vide](https://github.com/centau/vide) | You want typed, fine-grained updates in the style of Solid | Teams that need tagged releases | Medium. New concepts, few dependencies. Pin a commit | Active. No tagged releases, last commit 2026-10-26, MIT |

Don't mix UI libraries inside one project without a migration plan.

## State

**Default:** plain tables on the server, with changes sent through remotes.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Plain tables | Most game state | Many separate systems need the same changing values | Low, no dependencies. You write the sync code | Built in |
| Attributes | Small values on an Instance that clients should see | Tables, private values, or frequently changing data | Low. They replicate from the server automatically | Built in |
| [Charm](https://github.com/littensy/charm) | Many systems share derived state, or you want delta sync with charm-sync | Small games, or simple state | Medium: reactive concepts and packages | Active. v0.11.1, 2026-10-01, MIT |
| [Reflex](https://github.com/littensy/reflex) | Maintaining a project that uses it | New projects without a specific need for it | Medium: producer and selector structure | Quiet. v4.3.1, 2023-11-28, last commit 2025-12-21, MIT |

Client state is only a display copy. The server's state decides what is true.

## Game objects

**Default:** modules, with `CollectionService` tags for repeated world objects.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Modules | Most game objects and features | Thousands of objects with mixed behaviour | Low, no dependencies | Built in |
| `CollectionService` tags | Many world objects share a behaviour, such as doors or kill bricks | Objects with no Instance | Low. Handle streaming with tag signals | Built in |
| [jecs](https://github.com/Ukendio/jecs) | Measured need for very high entity counts, or heavy behaviour composition | Small games, or a team new to ECS | High concept cost, no dependencies, and strong iteration speed. Pre-1.0 API | Active. v0.11.0, 2026-03-10, last commit 2026-10-22, MIT |
| [Matter](https://github.com/matter-ecs/matter) | Maintaining a project that uses it | New projects, when jecs meets the need | High concept cost | Quiet. v0.8.5, 2024-12-09, last commit 2024-12-31, MIT |

## Utilities

**Default:** Roblox signals, connection lists, and yielding code with `pcall`.

| Need | Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- | --- |
| Signals | `BindableEvent` | Occasional same-side events | You must pass table identity, because it copies tables | None | Built in |
| Signals | [GoodSignal](https://github.com/stravant/goodsignal) | You need a small signal class with no copying | The project already has a signal class | Low | Quiet. v0.2.2, 2022-06-27, last commit 2025-08-28, MIT |
| Signals | [LemonSignal](https://github.com/Data-Oriented-House/LemonSignal) | Same need, with active maintenance preferred | Same as GoodSignal | Low | Active. v2.0.0, 2026-07-13, MIT |
| Cleanup | Connection list | A few connections, as in `templates/code/TypedModule.luau` | Many mixed resources | None | Built in |
| Cleanup | [Trove](https://github.com/Sleitnick/RbxUtil) | Many mixed resources and nested lifetimes | Simple objects | Low | Active. Part of RbxUtil, last commit 2026-08-11, MIT |
| Cleanup | [Janitor](https://github.com/howmanysmall/Janitor) | Same need, or a project already using it | Simple objects | Low | Active. v1.17.0, 2024-08-12, last commit 2026-07-28, MIT |
| Async | `task` and `pcall` | Almost always | You need chaining, racing, or cancellation across many operations | None | Built in |
| Async | [Promise](https://github.com/evaera/roblox-lua-promise) | You need those features, or a project already uses it | Simple one-at-a-time async code | Medium: every caller must learn it | Quiet. v4.0.0, 2022-03-03, last commit 2024-08-06, MIT |

## Combat

**Default:** the client sends an intent, and the server validates it and applies the result. Everything here is built in.

| Technique | Choose when | Avoid when | Cost |
| --- | --- | --- | --- |
| `Workspace:Raycast` | Bullets, line of sight, ground checks | Thick projectiles. Rays have a 15,000 stud limit | Low |
| `Blockcast`, `Spherecast`, `Shapecast` | Thick projectiles and sweeps | A ray is enough | Moderate |
| `GetPartBoundsInBox`, `GetPartBoundsInRadius`, `GetPartsInPart` | Melee and area damage | Long, thin checks | Moderate. Use filters |
| `Touched` | Simple non-competitive contact | Combat, because clients can trigger it for parts they control | Low, but unreliable for fairness |
| Server validation | Almost all combat | No exceptions in multiplayer | Medium. Check cooldown, weapon, distance, line of sight, and an allowance for latency |
| [Server authority](https://create.roblox.com/docs/projects/server-authority) | Competitive shooters, racing, sports, and combat, where flying and speed hacks must be impossible | Casual games, or games that depend on Tools, which aren't fully supported yet | High. Beta, and it changes the input, simulation, and prediction design |

Use `CanQuery = false` on parts that should not be hit. With streaming, clients may not have distant parts, so do final hit decisions on the server.

Setting `Workspace.AuthorityMode` to `Server` also sets next-generation replication, the Input Action System, deferred events, fixed simulation, and streaming. Game logic then moves into a module that runs on both sides inside `RunService:BindToSimulation`:

- Use `InputAction` for simulation input, and `time()` for simulation timing.
- Don't call `Destroy` or change `Parent` inside bound functions.
- Don't keep `AnimationTrack` references across frames. Use `Animator:GetTrackByAnimationId`.
- Make visual effects able to undo themselves, because mispredictions get corrected.

## NPCs

**Default:** a state machine. Everything here is built in or your own code.

| Option | Choose when | Avoid when | Cost |
| --- | --- | --- | --- |
| State machine | A few clear states, such as idle, chase, and attack | Dozens of interacting behaviours | Low. Update on a timer, not every frame |
| Behavior tree | Many behaviours that need tuning and reuse | Simple enemies | Medium to high. You write or choose a library, and debugging takes more work |
| `PathfindingService` | Moving around obstacles | Open spaces where direct movement works | Moderate. Calls yield. Limit recomputes, and handle blocked paths |
| Direct movement | Open arenas and short chases | Maps with obstacles | Low |

Avoid `Humanoid` on NPCs that don't need it, and play NPC animations on clients where possible.

## Multi-server

**Default:** avoid cross-server systems until the game needs them. Everything here is built in.

| Service | Choose when | Avoid when | Cost |
| --- | --- | --- | --- |
| [MemoryStore](https://create.roblox.com/docs/cloud-services/memory-stores) sorted map | Global leaderboards and auctions | Permanent data | Medium. Data expires, and quotas apply |
| MemoryStore queue | Matchmaking and work queues | Permanent data | Medium |
| MemoryStore hash map | Shared temporary data accessed by key | Permanent data, or when ordering is required | Medium |
| [MessagingService](https://create.roblox.com/docs/cloud-services/cross-server-messaging) | Live announcements and best-effort server signals | Currency, or anything that must arrive | Low. Messages can be missed |
| [TeleportService](https://create.roblox.com/docs/projects/teleport) | Moving players between places, and reserved servers | Passing trusted data through the client | Medium. Save data first, and handle failed teleports |
| DataStore | Data that must persist | Fast-changing shared data | Medium. Request limits apply |

## Purchases

**Default:** game passes for permanent one-time perks, and developer products with `ProcessReceipt` for repeat purchases. Everything here is built in.

| Option | Choose when | Avoid when | Cost |
| --- | --- | --- | --- |
| Game pass | A permanent one-time perk | Currency or consumables | Low. Check ownership on the server |
| [Developer product](https://create.roblox.com/docs/production/monetization/developer-products) | Currency and repeat purchases | Permanent perks | Medium. Needs a correct `ProcessReceipt` |
| Receipt tracking | Every developer product | No exceptions | Low. Store handled `PurchaseId`s with the player's data |

Rules:

- Set `ProcessReceipt` in one server script only.
- Return `PurchaseGranted` only after the grant is saved. Otherwise return `NotProcessedYet`, and Roblox tries again when the player next joins.
- Roblox doesn't keep per-player product history for you, so store it yourself if you need it.
- Never use `PromptProductPurchaseFinished` to grant items.
- Paid random items must check `PolicyService` and show odds. See `security-and-data.md`.
- Start from `templates/code/ProductReceipts.luau`.

## Input, chat, audio, and movement

**Default:** the newest built-in option listed for each. Everything here is built in.

| Need | Option | Choose when | Avoid when | Cost |
| --- | --- | --- | --- | --- |
| Input | [Input Action System](https://create.roblox.com/docs/input/input-action-system) | New games, cross-device controls, or server authority | Simple raw checks | Low. Needs `Workspace.PlayerScriptsUseInputActionSystem` for PlayerScripts |
| Input | `UserInputService` | Raw input, device type, and mouse position | Actions that need all devices and contexts | Low. You handle each device |
| Chat | [`TextChatService`](https://create.roblox.com/docs/chat/in-experience-text-chat) | All chat. It is filtered for you | Not applicable. Don't build chat on your own text filtering | Low. Commands use `TextChatCommand` |
| Audio | [`AudioPlayer` and audio objects](https://create.roblox.com/docs/audio/objects) | Effects chains, voice, and dynamic mixing | Simple one-shot sounds | Medium. You connect objects with wires |
| Audio | `Sound` | Simple sounds | Dynamic effects | Low |
| Movement | `LinearVelocity`, `AlignPosition`, and other constraints | Ongoing physics movement | A single initial push | Low. Set `BasePart.AssemblyLinearVelocity` for a push |
| Characters | [Character Controller Library](https://create.roblox.com/docs/characters/character-controller-library) | Custom character abilities | Standard characters that already work | Medium. Check that it fits your Studio version |
| Matchmaking | [Built-in matchmaking](https://create.roblox.com/docs/matchmaking) | Tuning which servers players join | Your own match rules between places | Low. Configured with server scoring |

## Tooling

**Default:** Studio for beginners and very small projects. Rojo for anything using git or several developers.

| Option | Choose when | Avoid when | Cost | Status |
| --- | --- | --- | --- | --- |
| Studio only | Small projects and new developers | Git, code review, or external tools | None | Built in |
| [Rojo](https://github.com/rojo-rbx/rojo) | Code should live in files and git | Everything is edited in Studio by non-coders | Low to medium. Needs sync discipline | Active. v7.7.1, 2026-10-02, MPL-2.0 |
| [Script Sync](https://create.roblox.com/docs/scripting/sync) | An existing Studio place needs its scripts in files | Scripts with attributes or tags, which it ignores. Data loss can result | Low | Built in. Full release 2026-06-17 |
| [Rokit](https://github.com/rojo-rbx/rokit) | Installing and pinning tools per project | Studio-only projects | Low | Active. v1.2.0, 2025-09-30, last commit 2026-09-27, MIT |
| [Wally](https://github.com/UpliftGames/wally) | You need packages, or the project already uses it | No dependencies | Low to medium | Active repo. Last release v0.3.2, 2023-06-05, MPL-2.0 |
| [pesde](https://github.com/pesde-pkg/pesde) | You need packages, and a needed package or workflow fits it better | The project already uses Wally | Low to medium | Active. v0.7.4, 2026-09-09, MIT |
| [Lune](https://github.com/lune-org/lune) | Build scripts, or testing pure logic outside Roblox | Tests that need real engine behaviour | Low | Active. v0.11.1, 2026-10-21, MPL-2.0 |
| [Jest Lua](https://github.com/jsdotlua/jest-lua) | Bigger projects that need a test runner | Tiny projects | Medium. Runs in a Roblox environment | Quiet. v3.10.0, 2024-12-23, MIT |
| [TestEZ](https://github.com/Roblox/testez) | Maintaining existing TestEZ tests | New tests | Medium | Archived. v0.4.2, 2022-01-05, Apache-2.0 |
| [luau-lsp](https://github.com/JohnnyMorganz/luau-lsp) | Any project using files outside Studio | Studio-only projects | Low | Active. 1.70.1, 2026-09-27, MIT |

Put pure logic in modules so it can be tested without Studio. Test multiplayer behaviour in Studio with a local server and 2 players.

## Starting setups

| Size | Typical project | Setup |
| --- | --- | --- |
| Small | Solo, one place, no trading | Studio or Rojo. Service modules, `RemoteEvent`, plain UI, built-in data wrapper, `check` |
| Medium | Small team, trading or lots of UI | Rojo, Rokit, luau-lsp, a package manager. Service modules, ProfileStore if there is trading, one UI library if the UI needs it |
| Large | Several developers, many systems, or high traffic | Medium setup plus code review, automated checks, tests, and profiling. Add Blink or Zap, Charm, or jecs only for measured needs |

## Common game types

These are starting points. The rules above still apply.

| Game type | Main risks | Start with | Add when |
| --- | --- | --- | --- |
| Simulator | Currency exploits, big inventories, and many pickups | Server-side rewards, tags for pickups, effects on clients, built-in data wrapper | ProfileStore if pets or items trade. Delta sync if measured traffic is high |
| Tycoon | Plot ownership, purchase checks, and part counts | One plot service, server-checked purchases, tags for droppers, anchored parts, cleanup when players leave | ProfileStore if items trade. Streaming on large maps |
| Round-based | Stuck rounds, players leaving, and cleanup | A server state machine like `samples/RoundSystem.server.luau`, attributes for round state | TeleportService for separate match places. MemoryStore queue for cross-server matchmaking |
| Shooter | Fake hits, latency, and network traffic | Server-validated raycasts, cosmetic tracers on clients, `UnreliableRemoteEvent` for cosmetic updates | Blink or Zap if measured. Server authority for competitive play |
| RPG | Item duplication, data size, and many systems | ProfileStore, service modules, tags for world objects, state machine NPCs | React Lua or Vide for large inventory UI. jecs only for measured entity needs |

## Recommendation format

Give one option, with:

- **Recommendation:** what to use.
- **Reason:** the specific need it meets.
- **Tradeoff:** what it costs.
- **Fallback:** what to use if the reason turns out false.

Say when a status is older than 6 months, or a claim was not measured in this project.
