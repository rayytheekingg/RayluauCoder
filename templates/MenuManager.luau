--!strict
-- MenuManager: one menu open at a time, a back stack, gamepad selection, and a Back action
-- (Escape / ButtonB) through the Input Action System. Client-side only.
-- Place at: ReplicatedStorage/Shared/MenuManager (Rojo: src/shared/MenuManager.luau)
--
-- Usage:
--   MenuManager.register("Shop", { open = modal.open, close = modal.close, firstSelectable = buyButton })
--   MenuManager.open("Shop")
--   MenuManager.back()

local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

export type Menu = {
	open: () -> (),
	close: () -> (),
	firstSelectable: GuiObject?,
}

local BACK_CONTEXT_PRIORITY = 1000

local menus: { [string]: Menu } = {}
local stack: { string } = {}
local opened = Instance.new("BindableEvent")

local backContext: InputContext? = nil

local function usingGamepad(): boolean
	local lastInput = UserInputService:GetLastInputType()
	return lastInput.Name:sub(1, 7) == "Gamepad"
end

local function top(): string?
	return stack[#stack]
end

local function setBackEnabled()
	if backContext then
		backContext.Enabled = #stack > 0
	end
end

local function show(name: string)
	local menu = menus[name]
	menu.open()
	if menu.firstSelectable and usingGamepad() then
		GuiService.SelectedObject = menu.firstSelectable
	end
	opened:Fire(name)
end

local function hide(name: string)
	menus[name].close()
	GuiService.SelectedObject = nil
end

local MenuManager = {}

--[=[
	Fires with the menu name whenever a menu becomes the visible one, or with nil when all close.
]=]
MenuManager.changed = opened.Event

--[=[
	Registers a menu under `name`. Registering the same name twice replaces the old entry.
]=]
function MenuManager.register(name: string, menu: Menu)
	menus[name] = menu
end

--[=[
	Opens `name`, hiding the current menu and remembering it for back().
	Opening the menu that is already on top does nothing.
]=]
function MenuManager.open(name: string)
	assert(menus[name], `MenuManager.open: unknown menu {name}`)
	local current = top()
	if current == name then
		return
	end
	if current then
		hide(current)
	end
	local existing = table.find(stack, name)
	if existing then
		table.remove(stack, existing)
	end
	table.insert(stack, name)
	show(name)
	setBackEnabled()
end

--[=[
	Closes the top menu and reopens the one below it, if any.
]=]
function MenuManager.back()
	local current = table.remove(stack)
	if not current then
		return
	end
	hide(current)
	local previous = top()
	if previous then
		show(previous)
	else
		opened:Fire(nil)
	end
	setBackEnabled()
end

--[=[
	Closes every open menu.
]=]
function MenuManager.closeAll()
	local current = top()
	if current then
		hide(current)
	end
	table.clear(stack)
	opened:Fire(nil)
	setBackEnabled()
end

--[=[
	Returns true if `name` is the menu currently shown.
]=]
function MenuManager.isOpen(name: string): boolean
	return top() == name
end

--[=[
	Creates the Back input action (Escape, ButtonB). Call once after the player's scripts load.
	The context is only enabled while a menu is open, so Escape and B keep their normal use otherwise.
]=]
function MenuManager.start()
	local player = Players.LocalPlayer
	local context = Instance.new("InputContext")
	context.Name = "MenuBackContext"
	context.Priority = BACK_CONTEXT_PRIORITY
	context.Enabled = false

	local action = Instance.new("InputAction")
	action.Name = "MenuBack"
	action.Type = Enum.InputActionType.Bool
	action.Parent = context

	for _, keyCode in { Enum.KeyCode.Escape, Enum.KeyCode.ButtonB } do
		local binding = Instance.new("InputBinding")
		binding.KeyCode = keyCode
		binding.Parent = action
	end

	action.Pressed:Connect(MenuManager.back)
	context.Parent = player:WaitForChild("PlayerScripts")
	backContext = context
end

return MenuManager
