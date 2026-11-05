--!strict
-- Grants developer products exactly once. A purchase only counts as handled after it is saved.
-- Needs PlayerData as a sibling ModuleScript. ProcessReceipt can only be set in one place, so call start() once.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)

local DATA_WAIT_SECONDS = 30
local DATA_POLL_SECONDS = 0.25

-- Replace with your developer product IDs and what each one grants.
local PRODUCT_GRANTS: { [number]: (data: any) -> () } = {
	[0] = function(data: any)
		data.coins += 100
	end,
}

type Receipt = {
	PlayerId: number,
	ProductId: number,
	PurchaseId: string,
}

local ProductReceipts = {}

local function waitForData(player: Player): any
	local deadline = os.clock() + DATA_WAIT_SECONDS
	while player.Parent == Players and os.clock() < deadline do
		local data = PlayerData.get(player)
		if data then
			return data
		end
		task.wait(DATA_POLL_SECONDS)
	end
	return nil
end

function ProductReceipts.process(receipt: Receipt): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	local grant = PRODUCT_GRANTS[receipt.ProductId]
	if not player or not grant then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local data = waitForData(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Roblox can send the same receipt again, so only grant a purchase ID once.
	if not data.purchaseIds[receipt.PurchaseId] then
		grant(data)
		data.purchaseIds[receipt.PurchaseId] = true
	end

	-- If this save fails, Roblox retries later, and the check above prevents a second grant.
	if PlayerData.saveNow(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function ProductReceipts.start()
	MarketplaceService.ProcessReceipt = ProductReceipts.process
end

return ProductReceipts
