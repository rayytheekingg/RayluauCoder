--!strict
-- ExampleService: server service skeleton with init/start phases.
-- Place at: ServerScriptService/Server/Services/<Name> (Rojo: src/server/Services/<Name>.luau)
-- Copy, rename, delete what you do not need. The bootstrap (Main.server.luau) calls init() on every
-- service first, then start(), so services can safely call each other inside start().

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cleaner = require(ReplicatedStorage.Shared.Cleaner)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local RemoteHandler = require(ServerScriptService.Server.RemoteHandler)

type PlayerState = {
	cleaner: Cleaner.Cleaner,
	lastSwing: number,
}

local SWING_COOLDOWN = 0.6
local SWING_RANGE = 12
local SWING_DAMAGE = 25

local states: { [Player]: PlayerState } = {}

local function getRootPart(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function validateSwing(target: unknown): Model?
	local instance = RemoteHandler.instanceUnder(target, "Model", workspace)
	return if instance then instance :: Model else nil
end

local function onSwing(player: Player, target: Model)
	local state = states[player]
	local character = player.Character
	if not state or not character then
		return
	end

	local now = os.clock()
	if now - state.lastSwing < SWING_COOLDOWN then
		return
	end

	local root = getRootPart(character)
	local targetRoot = getRootPart(target)
	local targetHumanoid = target:FindFirstChildOfClass("Humanoid")
	if not root or not targetRoot or not targetHumanoid or targetHumanoid.Health <= 0 then
		return
	end
	if (root.Position - targetRoot.Position).Magnitude > SWING_RANGE then
		return
	end

	state.lastSwing = now
	targetHumanoid:TakeDamage(SWING_DAMAGE)
end

local function onPlayerAdded(player: Player)
	local cleaner = Cleaner.new()
	states[player] = { cleaner = cleaner, lastSwing = 0 }

	cleaner:connect(player.CharacterAdded, function(_character: Model)
		-- Per-character setup goes here. Track anything you connect with the cleaner.
	end)
end

local function onPlayerRemoving(player: Player)
	local state = states[player]
	if state then
		state.cleaner:destroy()
		states[player] = nil
	end
end

local ExampleService = {}

--[=[
	Phase 1: create state. Must not yield or call other services.
]=]
function ExampleService.init()
	table.clear(states)
end

--[=[
	Phase 2: connect events. May yield and may call other services.
]=]
function ExampleService.start()
	RemoteHandler.connect(Remotes.Swing, validateSwing, onSwing, { capacity = 4, refillPerSecond = 2 })
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return ExampleService
