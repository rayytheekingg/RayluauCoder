# Monetization Reference

Verified as of 2026-11-06. [DP] = create.roblox.com/docs/production/monetization/developer-products. [MS] = create.roblox.com/docs/reference/engine/classes/MarketplaceService. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. Product types

| Type | Bought | Ownership check | Grant location |
|---|---|---|---|
| Game Pass | Once per user | `MarketplaceService:UserOwnsGamePassAsync(userId, passId)` | On join and on `PromptGamePassPurchaseFinished` (server re-checks ownership) |
| Developer Product | Many times | none, consumable | `ProcessReceipt` or `BindReceiptHandler` only |
| Subscription | Recurring | Subscription status APIs | Server, on join and on status change [UNVERIFIED this cycle: current subscription API names] |
| Robux transfer | Player to player | n/a | `BindReceiptHandler` with `RobuxTransferSender` / `RobuxTransferReceiver` receipt types |

Roblox Plus subscription launched 2026-04-30 (devforum weekly recap 4568634). It is a Roblox membership, not a product you sell.

## 2. ProcessReceipt rules (non-negotiable)

1. Set `MarketplaceService.ProcessReceipt` exactly once, in one server Script. A second assignment silently replaces the first.
2. Look up the player by `receiptInfo.PlayerId`. If they are not in this server or their data is not loaded, return `Enum.ProductPurchaseDecision.NotProcessedYet`. Roblox retries later, including when they rejoin.
3. Deduplicate on `receiptInfo.PurchaseId`. Roblox can deliver the same receipt more than once.
4. Grant the item and record the PurchaseId in the same data write.
5. Return `PurchaseGranted` only after that data is durably saved. If the save fails, return `NotProcessedYet`.
6. Never grant in `PromptProductPurchaseFinished`. That event fires on the client side of the flow and can be faked or fire without payment [DP].
7. Never yield forever inside the callback. Bounded retries only.

Callback type [DEFS]: `ProcessReceipt: (receiptInfo: { [string]: any }) -> Enum.ProductPurchaseDecision`.

templates/ProcessReceipt.luau implements this with templates/PlayerData.luau.

## 3. BindReceiptHandler (2026)

Signature [DEFS]: `MarketplaceService:BindReceiptHandler(transactionType: Enum.ReceiptType, handler, filter: { any }?): RBXScriptConnection`.

- `Enum.ReceiptType`: `DeveloperProduct`, `RobuxTransferReceiver`, `RobuxTransferSender` (and others; check the enum) [DEFS].
- Handlers return `Enum.ReceiptDecision.Processed` or `Enum.ReceiptDecision.NotProcessedYet` [DEFS], [MS code sample].
- `filter` limits a handler to specific product IDs, so separate systems (shop, gacha, donations) can each own their products without one giant ProcessReceipt.
- Ship date: [UNVERIFIED]. Third-party API trackers say April 2026; the earliest dated official record is a Roblox staff reply on 2026-06-02 (devforum 4664756). Known bug reports on transfer receipts arriving late (devforum 4664756, 4658449).

Rule: use ProcessReceipt for simple games with one shop. Use BindReceiptHandler when several independent systems sell developer products or when handling Robux transfers. Do not mix both for the same product IDs.

```lua
--!strict
local MarketplaceService = game:GetService("MarketplaceService")

local DONATION_PRODUCT_IDS = { 0, 0 } -- replace with real product IDs

MarketplaceService:BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, function(receiptInfo: { [string]: any }): Enum.ReceiptDecision
	-- Same rules as ProcessReceipt: dedupe on PurchaseId, save before returning Processed.
	return Enum.ReceiptDecision.NotProcessedYet
end, DONATION_PRODUCT_IDS)
```

## 4. External sales and auditing (2026)

- Listed developer products and game passes can appear outside your game (home page, search) [DP]. Start date around 2026-09-22 per a community thread [UNVERIFIED official date]. Unlisted products never appear outside the game. External sales do not change earnings.
- Roblox checks your ProcessReceipt implementation on an ongoing basis. Flagged products stop appearing outside the game (they stay buyable inside it), and a banner in Creator Hub, Monetization, Shop links to a report. Fix in Studio, publish, then click "Mark as fixed" in the report [DP].
- Because a buyer may not be in any server when they buy, the `NotProcessedYet` path is now a normal path, not an edge case. Receipts must be granted when the player next joins.
- Game passes need no receipt code but must be Listed to appear externally [DP].
- Cross-game developer product sales were disabled 2026-05-30. Use Robux transfers for cross-experience payments [DP].

## 5. Deprecated monetization APIs [DEFS]

| Deprecated | Use |
|---|---|
| `MarketplaceService:GetProductInfo` | `GetProductInfoAsync` |
| `MarketplaceService:PlayerOwnsAsset` | `PlayerOwnsAssetAsync` |
| `MarketplaceService:PlayerOwnsBundle` | `PlayerOwnsBundleAsync` |
| `MarketplaceService:PromptPremiumPurchase` | `PromptRobloxSubscriptionPurchase` |
| `BadgeService:AwardBadge` | `AwardBadgeAsync` |
| Legacy game pass and developer product web endpoints | Open Cloud APIs (deprecated 2026-04-23, weekly recap 4568634) |

## 6. Game pass pattern

```lua
--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local VIP_PASS_ID = 0 -- replace with the real pass ID

local function ownsPass(player: Player, passId: number): boolean
	local ok, owns = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, passId)
	if not ok then
		warn(("[Passes] ownership check failed for %d: %s"):format(player.UserId, tostring(owns)))
		return false
	end
	return owns
end

local function applyVip(player: Player)
	player:SetAttribute("IsVip", true)
end

Players.PlayerAdded:Connect(function(player)
	if ownsPass(player, VIP_PASS_ID) then
		applyVip(player)
	end
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
	-- Re-check on the server instead of trusting the event payload.
	if purchased and passId == VIP_PASS_ID and ownsPass(player, VIP_PASS_ID) then
		applyVip(player)
	end
end)
```

## 7. Policy and compliance

- Paid random items (loot boxes, gacha) are restricted in some regions. Check `PolicyService:GetPolicyInfoForPlayerAsync(player)` [DEFS] and hide or disable the feature where the policy says so. [UNVERIFIED this cycle: current field names in the returned table; read the PolicyService page.]
- Show odds for paid random items.
- Never sell an item whose effect is "chance to win Robux" or real-world value.
