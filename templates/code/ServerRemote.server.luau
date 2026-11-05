--!strict
-- Server-validated RemoteEvent. Order: rate limit, types, allowed values, game rules, then act.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MAX_REQUESTS_PER_WINDOW = 5
local RATE_WINDOW_SECONDS = 1
local MAX_ITEM_ID_LENGTH = 32
local MAX_SLOT = 8
local ALLOWED_ITEMS: { [string]: boolean } = {
	sword = true,
	shield = true,
}

type RateWindow = {
	count: number,
	startedAt: number,
}

local rateWindows: { [Player]: RateWindow } = {}

local remote = Instance.new("RemoteEvent")
remote.Name = "EquipItem"
remote.Parent = ReplicatedStorage

local function allowRequest(player: Player): boolean
	local now = os.clock()
	local window = rateWindows[player]
	if not window or now - window.startedAt >= RATE_WINDOW_SECONDS then
		rateWindows[player] = { count = 1, startedAt = now }
		return true
	end
	window.count += 1
	return window.count <= MAX_REQUESTS_PER_WINDOW
end

remote.OnServerEvent:Connect(function(player: Player, itemId: unknown, slot: unknown)
	if not allowRequest(player) then
		return
	end
	if typeof(itemId) ~= "string" or #itemId > MAX_ITEM_ID_LENGTH or not ALLOWED_ITEMS[itemId] then
		return
	end
	if typeof(slot) ~= "number" or not math.isfinite(slot) then
		return
	end
	if slot ~= math.floor(slot) or slot < 1 or slot > MAX_SLOT then
		return
	end

	-- Check game rules here, such as ownership, then change server state.
	remote:FireClient(player, itemId, slot)
end)

Players.PlayerRemoving:Connect(function(player: Player)
	rateWindows[player] = nil
end)
