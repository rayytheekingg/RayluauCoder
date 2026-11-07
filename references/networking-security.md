# Networking and Security Reference

Verified as of 2026-11-06. [SA] = devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993 (2026-07-09). [URE] = devforum.roblox.com/t/introducing-unreliableremoteevents/2724155 (updated 2025-03-12). [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. The one rule

The client is controlled by the player, and some players run exploits. Anything a client sends is a request, never a fact. The server decides every outcome that matters: damage, currency, inventory, purchases, position for competitive games, cooldowns, win conditions.

## 2. Remote types

| Type | Direction | Guarantees | Use for |
|---|---|---|---|
| `RemoteEvent` | Both | Reliable, ordered | Requests and state changes |
| `UnreliableRemoteEvent` | Both | May drop or arrive out of order; payload limit 1,000 bytes on client and server, larger fires are dropped [URE] | Cosmetic, high-frequency data (look direction, VFX hints) |
| `RemoteFunction` | Both | Request and response | Client asks server for data. Never `InvokeClient` |
| `BindableEvent` / `BindableFunction` | Same side only | n/a | Script-to-script on one machine. Prefer a module with a signal |

`RemoteFunction:InvokeClient` is banned in this skill: if the client never returns, the server thread yields forever, and an exploiter can return anything or error on purpose.

## 3. Validation checklist for every OnServerEvent and OnServerInvoke

1. **Rate**: token bucket per player per remote (templates/RemoteHandler.luau).
2. **Type**: every argument is `unknown`; check with `typeof`. `typeof(x) == "number"` also accepts NaN and infinity, so check `x == x` and `math.abs(x) ~= math.huge`.
3. **Range**: clamp or reject numbers outside allowed limits. Check string length before using a string.
4. **Ownership**: the player may only act on things they own (their own tool, their own plot, an item in their inventory).
5. **Distance and line of sight**: for interactions, check the player's character is close enough on the server.
6. **State**: alive, not stunned, cooldown elapsed, round active. The server tracks cooldowns; client timers are UI only.
7. **Instances**: if the client sends an Instance, check `typeof(x) == "Instance"`, `x:IsA(...)`, and `x:IsDescendantOf(expectedParent)`. Clients can only send instances that exist on the server, but can send any of them.

```lua
--!strict
-- Bad: client decides damage and target.
DamageRemote.OnServerEvent:Connect(function(player, target, damage)
	target.Humanoid:TakeDamage(damage)
end)

-- Good: client only says who it swung at. Server validates and computes damage.
local SWORD_RANGE = 12
local SWORD_DAMAGE = 25
local SWING_COOLDOWN = 0.6

local lastSwing: { [Player]: number } = {}

SwingRemote.OnServerEvent:Connect(function(player: Player, targetArg: unknown)
	if typeof(targetArg) ~= "Instance" or not targetArg:IsA("Model") then
		return
	end
	local target = targetArg :: Model

	local now = os.clock()
	if now - (lastSwing[player] or 0) < SWING_COOLDOWN then
		return
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetRoot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not root or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end
	if (root.Position - targetRoot.Position).Magnitude > SWORD_RANGE then
		return
	end

	lastSwing[player] = now
	targetHumanoid:TakeDamage(SWORD_DAMAGE)
end)
```

## 4. Server Authority (released 2026-07-09)

What it is [SA]: the server simulates physics and character movement as the source of truth. The client predicts locally for responsiveness and rolls back when the server disagrees. The server automatically rejects invalid client movement, which removes most speed and fly hacks without custom anti-cheat.

Opt in: `Workspace.AuthorityMode = Server` (Enum.AuthorityMode: `Automatic`, `Server` [DEFS]). Turning it on forces:
- `NextGenerationReplication` on
- `PlayerScriptsUseInputActionSystem` on (input moves to the Input Action System, see input-ui.md)
- `SignalBehavior = Deferred`
- `StreamingEnabled = true`
- `UseFixedSimulation` on (fixed-rate simulation step)

What changes in code:
- Movement and ability physics run in `RunService:BindToSimulation(fn, Enum.StepFrequency.Hz60)` (engine-runtime.md section 2).
- Player input that drives simulation comes from `InputAction` state, read inside the simulation callback.
- Breaking change: `Player.InputContexts.CameraContext.CameraAction` was removed. Use `Player:GetCameraState()`, which returns `CFrame`, `FieldOfView` and `ViewportSize` [SA], [DEFS].
- Simulation callbacks must be deterministic and must not fire remotes, yield, or print every step.

Known limits at launch [SA]:
- RemoteEvents are not synchronized with the shared simulation timeline. A remote fired with a hit claim does not line up with a specific simulation frame.
- Attributes are limited to 64 per instance with limited string size.
- 8 active animation tracks per Animator.
- Mobile and console client updates lag desktop.
- Server and client compute cost goes up (devforum.roblox.com/t/studio-beta-build-fair-responsive-games-with-server-authority/4139157). Budget for it.

Roadmap only, do not code against: server-side rewind hit detection API, Android hardware attestation anti-cheat (Creator Roadmap Fall 2026 update).

When to turn it on: competitive PvP, racing, movement-skill games. When to leave it off: social hangouts, tycoons, simulators with no movement competition, games with heavy custom physics not yet ported to BindToSimulation.

## 5. Remotes module pattern

One module creates and exposes every remote, so names are typed and never misspelled:

```lua
--!strict
-- ReplicatedStorage/Shared/Remotes.luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"

local function getFolder(): Folder
	if RunService:IsServer() then
		local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		if existing then
			return existing :: Folder
		end
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	return ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
end

local folder = getFolder()

local function remoteEvent(name: string): RemoteEvent
	if RunService:IsServer() then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	return folder:WaitForChild(name) :: RemoteEvent
end

return {
	Swing = remoteEvent("Swing"),
	RequestPurchase = remoteEvent("RequestPurchase"),
}
```

## 6. Common exploit vectors and the fix

| Exploit | Cause | Fix |
|---|---|---|
| Infinite money | Client sends amount to add | Server computes rewards from server state |
| Kill aura or reach | Server trusts client hit claims | Distance, cooldown and line-of-sight checks on the server |
| Speed or fly hack | Client owns its character physics | Server Authority, or server-side position sanity checks |
| Remote spam lag | No rate limit | Token bucket per player per remote |
| Item duplication | Two servers write the same player's data, or trade not atomic | Session lock (data-persistence.md), server-side trades with one UpdateAsync |
| Free purchases | Granting on `PromptProductPurchaseFinished` | Grant only in ProcessReceipt (monetization.md) |
| Reading secrets | Server logic in ReplicatedStorage | Server-only modules in ServerScriptService or ServerStorage |
| Teleporting unanchored parts | Client network ownership | `SetNetworkOwner(nil)` on server for important parts |
| Malformed data crash | Server indexes client tables without checks | Type check every field, never trust nested tables |

## 7. Bandwidth rules

- Send intent, not state: "player pressed attack" instead of "player's sword is at CFrame X".
- Batch per-frame updates into one fire on an interval.
- Do not fire remotes inside PostSimulation for every player every frame unless the data is cosmetic and on an UnreliableRemoteEvent.
- Use attributes or ValueObjects for state that every client needs and that changes rarely; replication handles it.
- Pack large arrays of numbers into a `buffer` before sending.
