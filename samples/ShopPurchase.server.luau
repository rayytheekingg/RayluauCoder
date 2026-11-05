--!strict
-- Sample: server-validated shop. The client sends only an item ID. The server owns prices and coins.
-- Needs a Part named ShopCounter in Workspace, and templates/code/PlayerData.luau as a sibling ModuleScript.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData = require(script.Parent.PlayerData)

local MAX_SHOP_DISTANCE = 20
local MAX_REQUESTS_PER_WINDOW = 3
local RATE_WINDOW_SECONDS = 2
local MAX_ITEM_ID_LENGTH = 32
local PRICES: { [string]: number } = {
	speed_coil = 100,
	gravity_coil = 250,
}

type RateWindow = {
	count: number,
	startedAt: number,
}

local rateWindows: { [Player]: RateWindow } = {}
local shopCounter = workspace:WaitForChild("ShopCounter") :: BasePart

local remote = Instance.new("RemoteEvent")
remote.Name = "PurchaseItem"
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

local function isNearShop(player: Player): boolean
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end
	return (root.Position - shopCounter.Position).Magnitude <= MAX_SHOP_DISTANCE
end

local function updateCoinDisplay(player: Player, coins: number)
	local leaderstats = player:FindFirstChild("leaderstats")
	local display = leaderstats and leaderstats:FindFirstChild("Coins")
	if display and display:IsA("IntValue") then
		display.Value = coins
	end
end

local function purchase(player: Player, itemId: unknown): string
	if typeof(itemId) ~= "string" or #itemId > MAX_ITEM_ID_LENGTH then
		return "InvalidItem"
	end
	local price = PRICES[itemId]
	if not price then
		return "InvalidItem"
	end
	if not isNearShop(player) then
		return "TooFar"
	end
	local data = PlayerData.get(player)
	if not data then
		return "DataNotReady"
	end
	if data.owned[itemId] then
		return "AlreadyOwned"
	end
	if data.coins < price then
		return "NotEnoughCoins"
	end

	data.coins -= price
	data.owned[itemId] = true
	updateCoinDisplay(player, data.coins)
	task.spawn(PlayerData.saveNow, player)
	return "Purchased"
end

remote.OnServerEvent:Connect(function(player: Player, itemId: unknown)
	if allowRequest(player) then
		remote:FireClient(player, purchase(player, itemId))
	end
end)

Players.PlayerRemoving:Connect(function(player: Player)
	rateWindows[player] = nil
end)

PlayerData.start()
