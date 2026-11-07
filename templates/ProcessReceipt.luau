--!strict
-- ProcessReceipt: grants developer products exactly once and only after the grant is saved.
-- Place at: ServerScriptService/Server/Services/ProcessReceipt (Rojo: src/server/Services/ProcessReceipt.luau)
-- Requires: PlayerData in the same folder.
--
-- Rules (monetization.md section 2):
--   1. This is the only place MarketplaceService.ProcessReceipt is assigned.
--   2. Player not here or data not loaded -> NotProcessedYet (Roblox retries, including on rejoin).
--   3. Dedupe on PurchaseId; grant and record it in the same profile write.
--   4. PurchaseGranted only after PlayerData.saveNow succeeds.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local PlayerData = require(script.Parent.PlayerData)

type Grant = (profile: PlayerData.Profile) -> ()

local MAX_RECEIPT_HISTORY = 100

-- Product ID -> grant function. Replace the example IDs with real developer product IDs.
local GRANTS: { [number]: Grant } = {
	[1111111111] = function(profile)
		profile.coins += 100
	end,
	[2222222222] = function(profile)
		profile.inventory.SpeedPotion = (profile.inventory.SpeedPotion or 0) + 1
	end,
}

local function rememberPurchase(profile: PlayerData.Profile, purchaseId: string)
	local history = profile.recentPurchaseIds
	table.insert(history, purchaseId)
	while #history > MAX_RECEIPT_HISTORY do
		table.remove(history, 1)
	end
end

local function processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local playerId = receiptInfo.PlayerId :: number
	local productId = receiptInfo.ProductId :: number
	local purchaseId = tostring(receiptInfo.PurchaseId)

	local grant = GRANTS[productId]
	if not grant then
		warn(`[Receipt] no grant configured for product {productId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(playerId)
	local profile = player and PlayerData.get(player)
	if not player or not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if not table.find(profile.recentPurchaseIds, purchaseId) then
		-- Grant and record with no yield in between, so a re-delivered receipt cannot grant twice.
		local granted = xpcall(grant, function(err: unknown)
			warn(`[Receipt] grant {purchaseId} for product {productId} failed: {err}`)
		end, profile)
		if not granted then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		rememberPurchase(profile, purchaseId)
	end

	if not PlayerData.saveNow(player) then
		-- The grant stays in memory with its PurchaseId recorded; the retry will only re-save.
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local ProcessReceipt = {}

--[=[
	Assigns MarketplaceService.ProcessReceipt. Call once from the server bootstrap.
]=]
function ProcessReceipt.start()
	MarketplaceService.ProcessReceipt = processReceipt
end

return ProcessReceipt
