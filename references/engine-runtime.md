# Engine Runtime Reference

Verified as of 2026-11-06. [DEFS] = luau-lsp `globalTypes.d.luau` (main, fetched 2026-11-06). [SA] = devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993 (2026-07-09). [RBS] = devforum.roblox.com/t/introducing-require-by-string/3405078.

## 1. task library (scheduling)

| Use | Instead of | Notes |
|---|---|---|
| `task.wait(seconds)` | `wait()` | Global `wait`, `spawn`, `delay` are marked deprecated in [DEFS] |
| `task.spawn(fn, ...)` | `spawn(fn)` | Runs immediately, synchronously until the first yield |
| `task.defer(fn, ...)` | `spawn(fn)` | Runs at the end of the current resumption cycle |
| `task.delay(seconds, fn, ...)` | `delay(t, fn)` | Returns a thread you can cancel |
| `task.cancel(thread)` | flags and `if cancelled` | Cancels a spawned or delayed thread |
| `task.desynchronize()` / `task.synchronize()` | n/a | Parallel Luau only (Actors) |

```lua
--!strict
local respawnThread = task.delay(5, function()
	print("Respawning")
end)
-- Player left early: stop the pending work.
task.cancel(respawnThread)
```

Never write `while true do wait() end`. Use a RunService event or `task.wait(interval)` with a stop condition.

## 2. RunService frame events

Signatures from [DEFS]: `PreRender`, `PreAnimation`, `PreSimulation`, `PostSimulation`, `Heartbeat` (all `RBXScriptSignal<number>`), `Stepped` (`(number, number)`), `RenderStepped`.

| Event | Runs | Use for | Old equivalent |
|---|---|---|---|
| `PreRender` | Client, before the frame renders | Camera, visual-only effects | `RenderStepped` |
| `PreAnimation` | Before animations step | Procedural animation that must apply this frame | none |
| `PreSimulation` | Before physics | Setting forces or velocities | `Stepped` |
| `PostSimulation` | After physics | Reading results of physics | `Heartbeat` |
| `Heartbeat` | After physics | Still works, same timing as PostSimulation | n/a |

Rule: new code uses the Pre/Post names. `Heartbeat`, `Stepped` and `RenderStepped` are not marked deprecated in [DEFS], so do not flag existing uses as errors. Flag them as Low severity style items.

### Server Authority simulation hooks (released 2026-07-09)

From [DEFS] and [SA]:
- `RunService:BindToSimulation(fn, frequency: Enum.StepFrequency?, priority: number?): RBXScriptConnection`
- `RunService:BindToSimulationParallel(...)`, `BindToAnimation(...)`, `BindToAnimationParallel(...)`
- `Enum.StepFrequency`: `Hz1`, `Hz5`, `Hz10`, `Hz15`, `Hz30`, `Hz60`
- `RunService.Misprediction`, `RunService.Rollback`, `RunService:IsResimulating()`, `RunService:GetPredictionStatus(context)`, `RunService:SetPredictionMode(context, mode)`

When `Workspace.AuthorityMode = Server`, gameplay simulation code (movement, abilities that move characters) must run inside `BindToSimulation` so the client can predict it and the server can replay it. Code inside a simulation callback can run more than once per frame during resimulation, so it must be deterministic: no `print` spam, no RemoteEvent fires, no random numbers without a seed, no yields.

```lua
--!strict
local RunService = game:GetService("RunService")

local DASH_SPEED = 80

local connection = RunService:BindToSimulation(function(deltaTime: number)
	-- Deterministic: same inputs give the same result on client and server.
	-- Read InputAction state here, apply velocity, do not fire remotes.
end, Enum.StepFrequency.Hz60)
```

See networking-security.md section 4 for the full Server Authority setup.

## 3. Script types and RunContext

| Container | Runs on | Typical home |
|---|---|---|
| `Script` (RunContext Legacy) | Server | ServerScriptService |
| `Script` (RunContext Server) | Server, anywhere in the DataModel | Packages, tools that must run in Workspace |
| `Script` (RunContext Client) | Client, anywhere it replicates | Client code inside a tool or model |
| `LocalScript` | Client, only under player containers | StarterPlayerScripts, StarterCharacterScripts, StarterGui |
| `ModuleScript` | Whoever requires it | ReplicatedStorage (shared), ServerScriptService or ServerStorage (server only) |

[UNVERIFIED this cycle: RunContext enum names are long-standing; recheck if Roblox changes script containers.]

Rule: server secrets (DataStore keys, admin lists, damage formulas you do not want exploiters to read) live in ServerScriptService or ServerStorage, never in ReplicatedStorage.

## 4. require

Two valid forms:

```lua
--!strict
-- Instance path: always works.
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)

-- Require-by-string (platform-wide since 2025-05-20, @game alias early 2026) [RBS]
local Sibling = require("./Sibling") -- next to this script
local Up = require("../Shared/Util") -- parent folder
local Child = require("@self/Child") -- a child of this script
local Abs = require("@game/ReplicatedStorage/Shared/Config") -- absolute from game
```

Rules from [RBS]:
- The first path component must be `.`, `..` or `@`. `require("Config")` with no prefix is an error.
- Implicit `Init` child requiring is not supported and errors with migration instructions. Use `@self/Child` or an explicit path.
- Custom aliases from `.luaurc` are announced but [UNVERIFIED] as shipped in Studio. Use `@game`, `@self` and relative paths in game code.
- Rojo projects: require-by-string works on the filesystem layout through luau-lsp, so editor go-to-definition works the same as in Studio.

## 5. Parallel Luau

- Put scripts under an `Actor` to run them in parallel.
- `signal:ConnectParallel(fn)` runs the handler in parallel [DEFS].
- Inside parallel code, call `task.synchronize()` before writing to the DataModel, and `task.desynchronize()` to go back to parallel work.
- `SharedTable` (and `SharedTableRegistry`) shares data between Actors [DEFS].
- API reference pages tag members "Read Parallel", "Safe" or "Simulation Access". Writing a property not marked safe from parallel code throws.

Use Parallel Luau for heavy pure computation over many independent items (hundreds of NPC brains, terrain generation, line-of-sight checks). Do not use it for a handful of objects; the overhead outweighs the gain.

## 6. Streaming

- `Workspace.StreamingEnabled` is mandatory when Server Authority is on [SA]. Write all client code as if streaming is on.
- Client code never assumes a part exists. Use `WaitForChild(name, timeout)` with a timeout and handle `nil`, or listen with `CollectionService:GetInstanceAddedSignal(tag)`.
- `Player:RequestStreamAroundAsync(position)` before teleporting a player far away.
- Models that must arrive whole use `ModelStreamingMode = Atomic`. Models the client must always have use `Persistent` sparingly.
- Workspace streaming properties in [DEFS]: `StreamingMinRadius`, `StreamingTargetRadius`, `StreamingIntegrityMode`, `StreamingAdaptiveRadius`, `PredictiveStreamingMode`, `ApplyRecommendedStreamingSettings()`.
- Roblox shipped an Instance Streaming Conversion skill through the Studio MCP server to help migrate places [SA].

```lua
--!strict
local CollectionService = game:GetService("CollectionService")

local function onCoinAdded(coin: Instance)
	-- Runs for coins that already streamed in and every coin that streams in later.
end

for _, coin in CollectionService:GetTagged("Coin") do
	task.spawn(onCoinAdded, coin)
end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(onCoinAdded)
```

## 7. Signals and deferred behavior

- Server Authority requires `Workspace.SignalBehavior = Deferred` [SA]. Many places already use Deferred.
- Deferred means event handlers run later in the frame, not immediately when the event fires. Never write code that assumes a handler already ran on the next line.
- `signal:Once(fn)` connects for exactly one fire and disconnects itself [DEFS].

## 8. Instance lifecycle

- `instance:Destroy()` sets Parent to nil, locks Parent, disconnects all connections on that instance and its descendants, and destroys descendants.
- It does not disconnect connections you made on other objects (for example `Players.PlayerRemoving`, `RunService.PostSimulation`). Track those with a Cleaner (templates/Cleaner.luau).
- Player characters: connect per-character logic in `player.CharacterAdded` and clean it up in `humanoid.Died` or the next `CharacterAdded`.
- `Debris:AddItem(instance, seconds)` for fire-and-forget cleanup of effects.

## 9. Characters and physics

- **Character Controller Library** (Luau `AvatarAbilities`, alternative to the legacy Humanoid controller) is available for live experiences since 2026-04-20 (devforum.roblox.com/t/full-release-the-future-of-character-movement-character-controller-library/4565267). Toggle in Avatar Settings, Movement. Defaulted on in the Classic Obby template.
- `Humanoid:LoadAnimation` is deprecated; use `humanoid:FindFirstChildOfClass("Animator"):LoadAnimation(anim)` [DEFS].
- `Player:LoadCharacter()` is deprecated; use `Player:LoadCharacterAsync()` [DEFS].
- `Humanoid:ApplyDescription` and `ApplyDescriptionReset` are deprecated; use the `Async` versions [DEFS].
- Moving models: `model:PivotTo(cframe)` and `model:GetPivot()`. `SetPrimaryPartCFrame` and `GetPrimaryPartCFrame` are deprecated [DEFS].
- Collision groups: `PhysicsService:RegisterCollisionGroup(name)`, `PhysicsService:CollisionGroupSetCollidable(a, b, bool)`, `part.CollisionGroup = name`. `SetPartCollisionGroup`, `CreateCollisionGroup` and `RemoveCollisionGroup` are deprecated [DEFS].
- Movers: use `LinearVelocity`, `AngularVelocity`, `AlignPosition`, `AlignOrientation`, `VectorForce`. `BodyVelocity`, `BodyGyro`, `BodyPosition` still exist but are legacy [UNVERIFIED this cycle: official deprecation flag].
- `ClientAnimatorThrottling` is always on since 2026-04-29 (weekly recap 4568634). Distant characters animate at reduced rate on clients.

### Spatial queries

Signatures from [DEFS]:
- `workspace:Raycast(origin, direction, params?)`
- `workspace:Blockcast(cframe, size, direction, params?)`
- `workspace:Spherecast(position, radius, direction, params?)`
- `workspace:Shapecast(part, direction, params?, cframeOverride?, sizeOverride?)`
- `workspace:GetPartBoundsInBox(cframe, size, overlapParams?)`, `GetPartBoundsInRadius`, `GetPartsInPart(part, overlapParams?)`

New filters (2026-04-07, devforum.roblox.com/t/new-spatial-query-filters/4563575): `RaycastParams.ExcludeInstances` and `RaycastParams.IncludeInstances` (same on `OverlapParams`). Faster than `FilterDescendantsInstances` + `FilterType`, which Roblox plans to deprecate later. Assigning the same table again is cheap because Roblox caches it.

```lua
--!strict
local params = RaycastParams.new()
params.ExcludeInstances = { character }

local result = workspace:Raycast(origin, direction * 300, params)
if result then
	local hitPart = result.Instance
end
```

`FindPartOnRay`, `FindPartOnRayWithIgnoreList`, `FindPartsInRegion3` and `IsRegion3Empty` are deprecated [DEFS].

### Network ownership

- Unanchored parts near a player are owned by that client by default, which lets exploiters move them. For anything gameplay-critical, call `part:SetNetworkOwner(nil)` on the server, or turn on Server Authority.
- Under Server Authority, the server owns the simulation and rejects invalid movement automatically [SA].
