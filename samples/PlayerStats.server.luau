--!strict
-- Sample: saved coins shown on the leaderboard, earned on a server timer.
-- Needs templates/code/PlayerData.luau as a sibling ModuleScript.

local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)

local EARN_INTERVAL_SECONDS = 60
local EARN_AMOUNT = 10

local function createLeaderstats(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.coins
	coins.Parent = leaderstats

	leaderstats.Parent = player
end

local function awardCoins(player: Player)
	local data = PlayerData.get(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if data and coins and coins:IsA("IntValue") then
		data.coins += EARN_AMOUNT
		coins.Value = data.coins
	end
end

PlayerData.Loaded:Connect(createLeaderstats)
PlayerData.start()

-- Another script may have started PlayerData first.
for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		createLeaderstats(player)
	end
end

while true do
	task.wait(EARN_INTERVAL_SECONDS)
	for _, player in Players:GetPlayers() do
		awardCoins(player)
	end
end
