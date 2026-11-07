--!strict
-- ShopCatalog: the items the shop sells. Shared so the client can display them; the server
-- (ShopService) reads prices from here too and never trusts a price sent by the client.
-- Place at: ReplicatedStorage/Shared/ShopCatalog (Rojo: src/shared/ShopCatalog.luau)

export type Item = {
	id: string,
	name: string,
	price: number,
	icon: string, -- IconAtlas name
	maxOwned: number,
}

local ITEMS: { Item } = {
	{ id = "Sword", name = "Classic Sword", price = 100, icon = "sword", maxOwned = 1 },
	{ id = "SpeedPotion", name = "Speed Potion", price = 25, icon = "gem", maxOwned = 99 },
}

local byId: { [string]: Item } = {}
for _, item in ITEMS do
	byId[item.id] = item
end

local ShopCatalog = {}

--[=[
	Returns every item in display order.
]=]
function ShopCatalog.all(): { Item }
	return ITEMS
end

--[=[
	Returns the item with `id`, or nil.
]=]
function ShopCatalog.get(id: string): Item?
	return byId[id]
end

return ShopCatalog
