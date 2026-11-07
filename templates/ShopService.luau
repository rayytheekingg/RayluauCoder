--!strict
-- ShopService: validates shop requests and spends coins on the server. The client only asks.
-- Place at: ServerScriptService/Server/Services/ShopService (Rojo: src/server/Services/ShopService.luau)
-- Requires: PlayerData (same folder), RemoteHandler, Remotes and ShopCatalog.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerData = require(script.Parent.PlayerData)
local RemoteHandler = require(ServerScriptService.Server.RemoteHandler)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)

local MAX_ITEM_ID_LENGTH = 40

local function validateItemId(itemId: unknown): ShopCatalog.Item?
	if not RemoteHandler.isShortString(itemId, MAX_ITEM_ID_LENGTH) then
		return nil
	end
	return ShopCatalog.get(itemId :: string)
end

local function notify(player: Player, kind: string, message: string)
	Remotes.Notify:FireClient(player, kind, message)
end

local function onPurchase(player: Player, item: ShopCatalog.Item)
	local profile = PlayerData.get(player)
	if not profile then
		notify(player, "error", "Your data is still loading.")
		return
	end

	local owned = profile.inventory[item.id] or 0
	if owned >= item.maxOwned then
		notify(player, "error", `You already own {item.name}.`)
		return
	end
	if profile.coins < item.price then
		notify(player, "error", "Not enough coins.")
		return
	end

	profile.coins -= item.price
	profile.inventory[item.id] = owned + 1
	notify(player, "success", `Bought {item.name}!`)
end

local ShopService = {}

--[=[
	Connects the purchase remote with a tight rate limit.
]=]
function ShopService.start()
	RemoteHandler.connect(Remotes.RequestPurchase, validateItemId, onPurchase, { capacity = 3, refillPerSecond = 1 })
end

return ShopService
