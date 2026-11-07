--!strict
-- ShopUI: example HUD + shop menu built with Theme, UIKit and MenuManager.
-- Place at: StarterPlayer/StarterPlayerScripts/Client/ShopUI (LocalScript)
--           (Rojo: src/client/ShopUI.client.luau)
-- The client only asks to buy. ShopService on the server checks the price and the player's coins.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cleaner = require(ReplicatedStorage.Shared.Cleaner)
local IconAtlas = require(ReplicatedStorage.Shared.IconAtlas)
local MenuManager = require(ReplicatedStorage.Shared.MenuManager)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local ShopCatalog = require(ReplicatedStorage.Shared.ShopCatalog)
local UIKit = require(ReplicatedStorage.Shared.UIKit)

local SHOP_MENU = "Shop"
local PENDING_TIMEOUT_SECONDS = 5

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local cleaner = Cleaner.new()

local hud = UIKit.screen("HUD", 0, playerGui)
local menus = UIKit.screen("Menus", 10, playerGui)
local popups = UIKit.screen("Popups", 20, playerGui)

-- HUD: shop button in the top right corner.
UIKit.iconButton({
	name = "OpenShop",
	icon = "shop",
	variant = "Accent",
	size = UDim2.fromScale(0.07, 0.07),
	position = UDim2.new(1, -16, 0, 16),
	anchorPoint = Vector2.new(1, 0),
	parent = hud,
	onActivated = function()
		MenuManager.open(SHOP_MENU)
	end,
})

local shop = UIKit.modal("Shop", UDim2.fromScale(0.6, 0.7), menus, MenuManager.back)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(720, 560)
limit.Parent = shop.panel

local grid = Instance.new("UIGridLayout")
grid.CellSize = UDim2.fromScale(0.3, 0.45)
grid.CellPadding = UDim2.fromScale(0.03, 0.04)
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = shop.content

local pending: { [string]: boolean } = {}
local firstBuyButton: TextButton? = nil

for index, item in ShopCatalog.all() do
	local card = UIKit.panel({ name = item.id, variant = "Card", padding = 8, parent = shop.content })
	card.LayoutOrder = index

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 0.45)
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = icon
	IconAtlas.apply(icon, item.icon)
	icon.Parent = card

	UIKit.label({
		name = "Name",
		text = item.name,
		style = "body",
		size = UDim2.fromScale(1, 0.18),
		position = UDim2.fromScale(0, 0.47),
		parent = card,
	})

	local buyButton = UIKit.button({
		name = "Buy",
		text = `{item.price} coins`,
		variant = "Primary",
		size = UDim2.fromScale(1, 0.28),
		position = UDim2.fromScale(0, 0.7),
		parent = card,
	})
	firstBuyButton = firstBuyButton or buyButton

	cleaner:connect(buyButton.Activated, function()
		if pending[item.id] then
			return -- one request at a time per item; the server answers through Notify
		end
		pending[item.id] = true
		buyButton.Interactable = false
		Remotes.RequestPurchase:FireServer(item.id)
		task.delay(PENDING_TIMEOUT_SECONDS, function()
			pending[item.id] = nil
			buyButton.Interactable = true
		end)
	end)
end

MenuManager.register(SHOP_MENU, {
	open = shop.open,
	close = shop.close,
	firstSelectable = firstBuyButton,
})

cleaner:connect(Remotes.Notify.OnClientEvent, function(kind: unknown, message: unknown)
	if typeof(message) ~= "string" then
		return
	end
	table.clear(pending)
	for _, card in shop.content:GetChildren() do
		local buy = card:FindFirstChild("Buy")
		if buy and buy:IsA("TextButton") then
			buy.Interactable = true
		end
	end
	UIKit.toast(popups, message, if kind == "success" then "Secondary" else "Danger")
end)

MenuManager.start()
