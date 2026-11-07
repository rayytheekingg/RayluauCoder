# Clean Luau Coding Standard

The house style for every file Ray Luau Coder writes or fixes. Each rule has a bad and a good example. When fixing user code, apply these rules only to lines you are already changing, unless the user asks for a full cleanup.

## 1. File header

Every file starts with `--!strict`. Add `--!native` only with a profiler result to justify it.

```lua
-- Bad
local Players = game:GetService("Players")

-- Good
--!strict
local Players = game:GetService("Players")
```

## 2. File layout order

Every file follows the same order, so anyone can find anything:

```lua
--!strict
-- 1. One-line purpose comment
-- Handles sword swings: validates hits and applies damage.

-- 2. Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 3. Requires
local Config = require(ReplicatedStorage.Shared.Config)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

-- 4. Types
type SwingState = { lastSwing: number }

-- 5. Constants
local SWING_COOLDOWN = 0.6

-- 6. Private state
local states: { [Player]: SwingState } = {}

-- 7. Private functions
local function canSwing(state: SwingState, now: number): boolean
	return now - state.lastSwing >= SWING_COOLDOWN
end

-- 8. Public API or connections
-- 9. return (ModuleScripts only)
```

## 3. Naming

| Kind | Style | Example |
|---|---|---|
| Services, modules, classes, types | PascalCase | `PlayerData`, `type Inventory` |
| Locals, functions, parameters | camelCase | `local coinCount`, `local function giveCoins()` |
| Constants | UPPER_SNAKE | `local MAX_HEALTH = 100` |
| Private module members | leading underscore | `self._connections` |
| Booleans | is/has/can/should prefix | `isAlive`, `hasPass`, `canSwing` |
| Remotes and actions | Verb or VerbNoun | `Swing`, `RequestPurchase` |

```lua
-- Bad
local d = 5
local function Calc(p, a) end
local enabled = true

-- Good
local RESPAWN_DELAY = 5
local function calculateDamage(attacker: Player, baseDamage: number): number
	return baseDamage * (if attacker:GetAttribute("IsVip") then 1.1 else 1)
end
local isShopOpen = true
```

Single-letter names are allowed only for loop indices (`i`, `j`) and short math (`x`, `y`, `z`, `t` for time in tweens).

## 4. Services once, at the top

```lua
-- Bad
game.Players.PlayerAdded:Connect(function(player)
	game.ReplicatedStorage.Remotes.Hello:FireClient(player)
end)

-- Good
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.Shared.Remotes)

Players.PlayerAdded:Connect(function(player: Player)
	Remotes.Hello:FireClient(player)
end)
```

Use `game:GetService` even for services with a global (`workspace` is fine to use directly).

## 5. Requires

```lua
-- Bad: long parent chains break when folders move.
local Util = require(script.Parent.Parent.Parent.Shared.Util)

-- Good: require-by-string (engine-runtime.md section 4)
local Util = require("@game/ReplicatedStorage/Shared/Util")
local Helper = require("./Helper")
```

Either form is fine. Be consistent within a project.

## 6. No magic numbers

```lua
-- Bad
if humanoid.WalkSpeed > 32 then end
task.wait(120)

-- Good
local Config = require(ReplicatedStorage.Shared.Config)
if humanoid.WalkSpeed > Config.MAX_WALK_SPEED then end
task.wait(Config.AUTOSAVE_SECONDS)
```

Tunable gameplay numbers live in a Config module. Constants used by one file only live at the top of that file. `0`, `1` and `-1` used as identities are fine.

## 7. Types

```lua
-- Bad
function Inventory.give(p, item, n)
	return true
end

-- Good
export type ItemId = string

--[=[
	Adds `amount` of `itemId` to the player's inventory.
	Returns false if the inventory is full.
]=]
function Inventory.give(player: Player, itemId: ItemId, amount: number): boolean
	return true
end
```

- Every public function has typed parameters and a typed return.
- Public data shapes are `export type`.
- `any` needs a comment: `-- any: DataStore returns untyped JSON, validated by migrate()`.
- Values from remotes are `unknown` until checked.
- Prefer `f<<T>>()` over `nil :: T` for explicit generics.

## 8. Errors

```lua
-- Bad
local data = store:GetAsync(key)

-- Bad: swallows the error silently
pcall(function()
	store:SetAsync(key, data)
end)

-- Good
local ok, result = pcall(store.GetAsync, store, key)
if not ok then
	warn(("[PlayerData] GetAsync %s failed: %s"):format(key, tostring(result)))
	return nil
end
```

- Every yielding web call is wrapped: DataStore, MemoryStore, MessagingService, MarketplaceService, HttpService, TeleportService, BadgeService, GroupService, Players `...Async` lookups.
- Retry with exponential backoff and jitter for transient failures (templates/PlayerData.luau `withRetry`).
- Never ignore the `ok` result. If you truly do not care, log it.
- `error()` for programmer mistakes (wrong arguments to your own module). `warn()` plus graceful fallback for runtime failures.
- `assert(condition, message)` for invariants inside your own code, with a message.

## 9. Lifecycle and cleanup

```lua
-- Bad: connection lives forever, keeps character in memory after death.
player.CharacterAdded:Connect(function(character)
	RunService.PostSimulation:Connect(function()
		updateAura(character)
	end)
end)

-- Good
local Cleaner = require(ReplicatedStorage.Shared.Cleaner)

player.CharacterAdded:Connect(function(character: Model)
	local cleaner = Cleaner.new()
	cleaner:add(RunService.PostSimulation:Connect(function()
		updateAura(character)
	end))
	cleaner:add(character.AncestryChanged:Connect(function(_, parent)
		if parent == nil then
			cleaner:destroy()
		end
	end))
end)
```

- Every connection to a long-lived object (Players, RunService, a service-level signal) made per player, per character or per round is tracked and disconnected.
- Every table keyed by Player is cleared on `PlayerRemoving`.
- Server data saves on `PlayerRemoving` and `BindToClose`.

## 10. Networking

- One Remotes module creates and exposes every remote (networking-security.md section 5).
- Server handlers validate rate, type, range, ownership and state for every argument.
- Clients send intent ("I swung"), never results ("I did 50 damage").

## 11. Functions

```lua
-- Bad: deep nesting
local function onTouched(hit)
	if hit.Parent then
		local humanoid = hit.Parent:FindFirstChild("Humanoid")
		if humanoid then
			if humanoid.Health > 0 then
				humanoid:TakeDamage(10)
			end
		end
	end
end

-- Good: early returns
local LAVA_DAMAGE = 10

local function onTouched(hit: BasePart)
	local character = hit.Parent
	if not character then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return
	end
	humanoid:TakeDamage(LAVA_DAMAGE)
end
```

- One job per function. If you need "and" to describe it, split it.
- Aim for under 40 lines per function and under 400 lines per module. Larger means it has more than one responsibility.
- Use `FindFirstChildOfClass("Humanoid")` instead of `FindFirstChild("Humanoid")` when the name could change.

## 12. Comments

```lua
-- Bad: repeats the code
-- add 1 to rank
rank += 1

-- Good: explains why
-- Leaderboard ranks are 1-based, the sorted array index is 0-based.
rank += 1
```

- A doc comment (`--[=[ ]=]`) on every public function: what it does, what it returns, when it yields.
- A `-- TODO(name): reason` is allowed; a bare `-- TODO` is not.
- Delete commented-out code; Git keeps history.

## 13. Formatting and linting

- StyLua with templates/stylua.toml: tabs, 120 columns, double quotes, `syntax = "Luau"`.
- Selene with templates/selene.toml: `std = "roblox"`, globals denied, unused variables and shadowing warned.
- luau-lsp analyze with zero type errors in strict mode.
- CI runs `stylua --check`, `selene`, and `luau-lsp analyze` on every push.

## 14. Folder layouts

**Rojo** (templates/default.project.json)
```
src/
  shared/      -> ReplicatedStorage.Shared       (Config, Remotes, Types, Cleaner, pure logic)
  server/      -> ServerScriptService.Server     (Main.server.luau, Services/*.luau)
  client/      -> StarterPlayer.StarterPlayerScripts.Client (Main.client.luau, Controllers/*.luau)
```
File suffixes: `.server.luau` becomes a Script, `.client.luau` becomes a LocalScript, plain `.luau` becomes a ModuleScript.

**Studio only**
```
ReplicatedStorage
  Shared (Folder): Config, Remotes, Types, Cleaner, shared modules
ServerScriptService
  Server (Folder): Main (Script), Services (Folder of ModuleScripts)
ServerStorage
  Assets and server-only modules
StarterPlayer.StarterPlayerScripts
  Client (Folder): Main (LocalScript), Controllers (Folder of ModuleScripts)
```

One Script and one LocalScript bootstrap everything by requiring services and controllers in order. Avoid dozens of loose Scripts that each run on their own, because their start order is not guaranteed.

## 15. Service and controller pattern

Services (server) and controllers (client) are ModuleScripts with two phases:
- `init()`: create state, no yielding, no connections to other services.
- `start()`: connect events, may yield, may call other services.

The bootstrap script requires every module, calls every `init()`, then every `start()` (templates/Service.luau). This removes start-order bugs.
