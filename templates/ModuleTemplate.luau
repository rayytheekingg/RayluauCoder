--!strict
-- Inventory: pure shared logic for item stacks. No Roblox services, so it is easy to unit test.
-- Place at: ReplicatedStorage/Shared/Inventory (Rojo: src/shared/Inventory.luau)
-- Use this file as the shape for any ModuleScript: header, types, constants, private, public, return.

export type ItemId = string
export type Inventory = { [ItemId]: number }

local MAX_STACK = 99

local Inventory = {}

--[=[
	Returns a new empty inventory.
]=]
function Inventory.new(): Inventory
	return {}
end

--[=[
	Adds `amount` of `itemId`, capped at the stack limit. Returns how many were actually added.
]=]
function Inventory.add(inventory: Inventory, itemId: ItemId, amount: number): number
	assert(amount > 0 and amount % 1 == 0, "Inventory.add expects a positive whole number")
	local current = inventory[itemId] or 0
	local added = math.min(amount, MAX_STACK - current)
	if added > 0 then
		inventory[itemId] = current + added
	end
	return added
end

--[=[
	Removes `amount` of `itemId`. Returns false and changes nothing if there are not enough.
]=]
function Inventory.remove(inventory: Inventory, itemId: ItemId, amount: number): boolean
	assert(amount > 0 and amount % 1 == 0, "Inventory.remove expects a positive whole number")
	local current = inventory[itemId] or 0
	if current < amount then
		return false
	end
	local remaining = current - amount
	if remaining > 0 then
		inventory[itemId] = remaining
	else
		inventory[itemId] = nil -- drop empty stacks so saves stay small
	end
	return true
end

--[=[
	Returns how many of `itemId` the inventory holds.
]=]
function Inventory.count(inventory: Inventory, itemId: ItemId): number
	return inventory[itemId] or 0
end

return Inventory
