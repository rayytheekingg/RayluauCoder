--!strict
-- UIKit: builds styled, scale-based UI pieces from Theme tokens. Client-side only.
-- Place at: ReplicatedStorage/Shared/UIKit (Rojo: src/shared/UIKit.luau)
-- Requires: Theme and IconAtlas in the same folder.
--
-- Every element gets a CollectionService tag (Panel, ButtonPrimary, ...) so the Theme StyleSheet
-- can restyle it when the palette changes. Connections are made on the element itself, so
-- Destroy() on the element cleans them up; no Cleaner needed inside this module.

local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local IconAtlas = require(script.Parent.IconAtlas)
local Theme = require(script.Parent.Theme)

export type ButtonVariant = "Primary" | "Secondary" | "Accent" | "Danger"
export type PanelVariant = "Panel" | "Card" | "Page"
export type TextStyle = Theme.TextStyle

-- Prop types are flat (no intersections) so table literals type check cleanly in both solvers.
type FrameProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
}

export type PanelProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
	variant: PanelVariant?,
	studded: boolean?,
	padding: number?,
}

export type LabelProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
	text: string,
	style: TextStyle?,
	muted: boolean?,
	alignment: Enum.TextXAlignment?,
}

export type ButtonProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
	text: string,
	variant: ButtonVariant?,
	onActivated: (() -> ())?,
}

export type IconButtonProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
	icon: string,
	variant: ButtonVariant?,
	onActivated: (() -> ())?,
}

export type ProgressBarProps = {
	name: string?,
	size: UDim2?,
	position: UDim2?,
	anchorPoint: Vector2?,
	parent: Instance?,
	fill: Theme.ColorToken?,
}

export type Modal = {
	root: Frame,
	panel: Frame,
	content: Frame,
	closeButton: TextButton,
	open: () -> (),
	close: () -> (),
}

export type ProgressBar = {
	root: Frame,
	setProgress: (fraction: number) -> (),
}

local PRESS_SCALE = 0.95
local HOVER_SCALE = 1.05
local MIN_TOUCH_PX = 44
local TOAST_SECONDS = 2.5
local MODAL_DIM_TRANSPARENCY = 0.45

local VARIANT_TOKENS: { [ButtonVariant]: { fill: Theme.ColorToken, label: Theme.ColorToken } } = {
	Primary = { fill = "primary", label = "onPrimary" },
	Secondary = { fill = "secondary", label = "onSecondary" },
	Accent = { fill = "accent", label = "onAccent" },
	Danger = { fill = "danger", label = "onDanger" },
}

local clickSound: Sound? = nil

local function playClick()
	if Theme.assets.clickSound == "rbxassetid://0" then
		return
	end
	if not clickSound then
		local sound = Instance.new("Sound")
		sound.Name = "UIKitClick"
		sound.SoundId = Theme.assets.clickSound
		sound.Volume = 0.4
		sound.Parent = SoundService
		clickSound = sound
	end
	SoundService:PlayLocalSound(clickSound :: Sound)
end

local function applyFrameProps(
	instance: GuiObject,
	props: FrameProps | PanelProps | LabelProps | ButtonProps | IconButtonProps | ProgressBarProps
)
	instance.Name = props.name or instance.ClassName
	instance.Size = props.size or instance.Size
	instance.Position = props.position or instance.Position
	instance.AnchorPoint = props.anchorPoint or instance.AnchorPoint
end

local function addCorner(instance: GuiObject, radius: UDim)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = radius
	corner.Parent = instance
end

local function addStroke(instance: GuiObject, thickness: number, mode: Enum.ApplyStrokeMode?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.color("stroke")
	stroke.Thickness = thickness
	stroke.ApplyStrokeMode = mode or Enum.ApplyStrokeMode.Border
	stroke.Parent = instance
end

local function addShadow(instance: GuiObject)
	local shadow = Instance.new("UIShadow")
	shadow.Color = Color3.new(0, 0, 0)
	shadow.Offset = Theme.shadow.offset
	shadow.BlurRadius = Theme.shadow.blur
	shadow.Transparency = Theme.shadow.transparency
	shadow.Parent = instance
end

local function addPadding(instance: GuiObject, pixels: number)
	local padding = Instance.new("UIPadding")
	local amount = UDim.new(0, pixels)
	padding.PaddingTop = amount
	padding.PaddingBottom = amount
	padding.PaddingLeft = amount
	padding.PaddingRight = amount
	padding.Parent = instance
end

-- Callers set TextScaled = true themselves; this adds the min and max size clamp.
local function addTextLimits(label: GuiObject, style: TextStyle)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = Theme.textSize[style]
	limit.MinTextSize = Theme.minTextSize
	limit.Parent = label
end

-- Hover and press feedback through a UIScale, so layout is never disturbed.
local function addFeedback(button: GuiButton)
	local scale = Instance.new("UIScale")
	scale.Parent = button

	local function scaleTo(target: number)
		if Theme.reducedMotion then
			return
		end
		TweenService:Create(scale, Theme.tweenInfo("fast"), { Scale = target }):Play()
	end

	button.MouseEnter:Connect(function()
		scaleTo(HOVER_SCALE)
	end)
	button.MouseLeave:Connect(function()
		scaleTo(1)
	end)
	button.SelectionGained:Connect(function()
		scaleTo(HOVER_SCALE)
	end)
	button.SelectionLost:Connect(function()
		scaleTo(1)
	end)
	button.InputBegan:Connect(function(input: InputObject)
		local inputType = input.UserInputType
		if
			inputType == Enum.UserInputType.MouseButton1
			or inputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			scaleTo(PRESS_SCALE)
		end
	end)
	button.InputEnded:Connect(function()
		scaleTo(1)
	end)
end

local UIKit = {}

--[=[
	Creates a ScreenGui with safe-area insets, no reset on spawn, and the Theme StyleSheet linked.
	Parent it to the local player's PlayerGui.
]=]
function UIKit.screen(name: string, displayOrder: number, parent: Instance): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = name
	screenGui.DisplayOrder = displayOrder
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets

	local link = Instance.new("StyleLink")
	link.StyleSheet = Theme.getStyleSheet()
	link.Parent = screenGui

	screenGui.Parent = parent
	return screenGui
end

--[=[
	A rounded, outlined container. `studded` adds the faint stud tile behind content.
]=]
function UIKit.panel(props: PanelProps): Frame
	local variant: PanelVariant = props.variant or "Panel"
	local frame = Instance.new("Frame")
	applyFrameProps(frame, props)
	frame.BackgroundColor3 = Theme.color(if variant == "Card" then "bg2" elseif variant == "Page" then "bg0" else "bg1")
	frame.BorderSizePixel = 0
	CollectionService:AddTag(frame, variant)

	addCorner(frame, Theme.radius.large)
	addStroke(frame, Theme.stroke.normal)
	addShadow(frame)

	if props.studded and Theme.assets.studTile ~= "rbxassetid://0" then
		local studs = Instance.new("ImageLabel")
		studs.Name = "Studs"
		studs.BackgroundTransparency = 1
		studs.Size = UDim2.fromScale(1, 1)
		studs.Image = Theme.assets.studTile
		studs.ImageColor3 = Theme.color("studTint")
		studs.ImageTransparency = Theme.studTransparency
		studs.ScaleType = Enum.ScaleType.Tile
		studs.TileSize = Theme.studTileSize
		studs.ZIndex = 0
		addCorner(studs, Theme.radius.large)
		studs.Parent = frame
	end

	addPadding(frame, props.padding or Theme.spacing.lg)
	frame.Parent = props.parent
	return frame
end

--[=[
	A text label sized by Scale with readable min and max text sizes.
]=]
function UIKit.label(props: LabelProps): TextLabel
	local style: TextStyle = props.style or "body"
	local label = Instance.new("TextLabel")
	applyFrameProps(label, props)
	label.BackgroundTransparency = 1
	label.Text = props.text
	label.FontFace = if style == "display" or style == "title" then Theme.fonts.title else Theme.fonts.body
	label.TextColor3 = Theme.color(if props.muted then "textMuted" else "text")
	label.TextXAlignment = props.alignment or Enum.TextXAlignment.Center
	label.TextWrapped = true
	label.TextScaled = true
	CollectionService:AddTag(label, if props.muted then "TextMuted" else "TextBody")
	addTextLimits(label, style)

	if style == "display" or style == "title" then
		addStroke(label, Theme.stroke.normal, Enum.ApplyStrokeMode.Contextual)
	end

	label.Parent = props.parent
	return label
end

--[=[
	A chunky text button with hover, press, click sound and gamepad selection support.
]=]
function UIKit.button(props: ButtonProps): TextButton
	local variant: ButtonVariant = props.variant or "Primary"
	local tokens = VARIANT_TOKENS[variant]
	local button = Instance.new("TextButton")
	applyFrameProps(button, props)
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.color(tokens.fill)
	button.BorderSizePixel = 0
	button.Text = props.text
	button.TextColor3 = Theme.color(tokens.label)
	button.FontFace = Theme.fonts.bodyBold
	button.Selectable = true
	button.TextScaled = true
	CollectionService:AddTag(button, `Button{variant}`)

	addTextLimits(button, "heading")
	addCorner(button, Theme.radius.medium)
	addStroke(button, Theme.stroke.normal)
	addShadow(button)

	local minSize = Instance.new("UISizeConstraint")
	minSize.MinSize = Vector2.new(MIN_TOUCH_PX, MIN_TOUCH_PX)
	minSize.Parent = button

	addFeedback(button)
	local onActivated = props.onActivated
	button.Activated:Connect(function()
		playClick()
		if onActivated then
			onActivated()
		end
	end)

	button.Parent = props.parent
	return button
end

--[=[
	A square button with an atlas icon tinted to the variant's label color.
]=]
function UIKit.iconButton(props: IconButtonProps): ImageButton
	local variant: ButtonVariant = props.variant or "Primary"
	local tokens = VARIANT_TOKENS[variant]
	local button = Instance.new("ImageButton")
	applyFrameProps(button, props)
	button.AutoButtonColor = false
	button.BackgroundColor3 = Theme.color(tokens.fill)
	button.BorderSizePixel = 0
	button.Selectable = true
	CollectionService:AddTag(button, `Button{variant}`)

	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = button

	local minSize = Instance.new("UISizeConstraint")
	minSize.MinSize = Vector2.new(MIN_TOUCH_PX, MIN_TOUCH_PX)
	minSize.Parent = button

	addCorner(button, Theme.radius.medium)
	addStroke(button, Theme.stroke.normal)
	addShadow(button)

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.BackgroundTransparency = 1
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.Position = UDim2.fromScale(0.5, 0.5)
	icon.Size = UDim2.fromScale(0.65, 0.65)
	icon.ImageColor3 = Theme.color(tokens.label)
	IconAtlas.apply(icon, props.icon)
	icon.Parent = button

	addFeedback(button)
	local onActivated = props.onActivated
	button.Activated:Connect(function()
		playClick()
		if onActivated then
			onActivated()
		end
	end)

	button.Parent = props.parent
	return button
end

--[=[
	A centered modal: dimmed backdrop, titled panel, content frame and close button.
	Starts hidden; call open() / close(), or register it with MenuManager.
	`onCloseRequested` runs when the close button is pressed (pass MenuManager.back); without it the
	close button just hides the modal.
]=]
function UIKit.modal(title: string, size: UDim2, parent: Instance, onCloseRequested: (() -> ())?): Modal
	local root = Instance.new("Frame")
	root.Name = `{title}Modal`
	root.Size = UDim2.fromScale(1, 1)
	root.BackgroundColor3 = Color3.new(0, 0, 0)
	root.BackgroundTransparency = MODAL_DIM_TRANSPARENCY
	root.Active = true -- blocks clicks from reaching the game behind the modal
	root.Visible = false

	local panel = UIKit.panel({
		name = "Panel",
		size = size,
		position = UDim2.fromScale(0.5, 0.5),
		anchorPoint = Vector2.new(0.5, 0.5),
		studded = true,
		parent = root,
	})
	local openScale = Instance.new("UIScale")
	openScale.Name = "OpenScale"
	openScale.Parent = panel
	panel.SelectionGroup = true

	UIKit.label({
		name = "Title",
		text = title,
		style = "title",
		size = UDim2.fromScale(0.8, 0.14),
		position = UDim2.fromScale(0.5, 0),
		anchorPoint = Vector2.new(0.5, 0),
		parent = panel,
	})

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Size = UDim2.fromScale(1, 0.82)
	content.Position = UDim2.fromScale(0, 0.18)
	content.Parent = panel

	local modal: Modal

	local closeButton = UIKit.button({
		name = "Close",
		text = "X",
		variant = "Danger",
		size = UDim2.fromScale(0.1, 0.12),
		position = UDim2.fromScale(1, 0),
		anchorPoint = Vector2.new(0.6, 0.4),
		parent = panel,
		onActivated = function()
			if onCloseRequested then
				onCloseRequested()
			else
				modal.close()
			end
		end,
	})
	local square = Instance.new("UIAspectRatioConstraint")
	square.AspectRatio = 1
	square.Parent = closeButton

	local function open()
		root.Visible = true
		openScale.Scale = if Theme.reducedMotion then 1 else 0.9
		TweenService:Create(openScale, Theme.tweenInfo("normal", Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end

	local function close()
		root.Visible = false
	end

	modal = {
		root = root,
		panel = panel,
		content = content,
		closeButton = closeButton,
		open = open,
		close = close,
	}
	root.Parent = parent
	return modal
end

--[=[
	A row of tab buttons. Calls onChanged with the selected tab name; the first tab starts selected.
]=]
function UIKit.tabs(names: { string }, parent: Instance, onChanged: (name: string) -> ()): Frame
	local row = Instance.new("Frame")
	row.Name = "Tabs"
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 0.12)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalFlex = Enum.UIFlexAlignment.Fill
	layout.Padding = UDim.new(0, Theme.spacing.sm)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = row

	local buttons: { [string]: TextButton } = {}

	local function selectTab(selected: string)
		for name, button in buttons do
			local variant: ButtonVariant = if name == selected then "Primary" else "Secondary"
			local tokens = VARIANT_TOKENS[variant]
			-- Swap tags so a linked StyleSheet restyles the tab; set colors too for unstyled use.
			CollectionService:RemoveTag(button, "ButtonPrimary")
			CollectionService:RemoveTag(button, "ButtonSecondary")
			CollectionService:AddTag(button, `Button{variant}`)
			button.BackgroundColor3 = Theme.color(tokens.fill)
			button.TextColor3 = Theme.color(tokens.label)
		end
		onChanged(selected)
	end

	for index, name in names do
		local button = UIKit.button({
			name = name,
			text = name,
			variant = "Secondary",
			size = UDim2.fromScale(0, 1),
			parent = row,
			onActivated = function()
				selectTab(name)
			end,
		})
		button.LayoutOrder = index
		buttons[name] = button
	end

	row.Parent = parent
	if names[1] then
		selectTab(names[1])
	end
	return row
end

--[=[
	Shows a short message at the top of `parent` and removes it after a few seconds.
]=]
function UIKit.toast(parent: Instance, text: string, variant: ButtonVariant?)
	local chosen: ButtonVariant = variant or "Primary"
	local tokens = VARIANT_TOKENS[chosen]
	local toast = Instance.new("TextLabel")
	toast.Name = "Toast"
	toast.AnchorPoint = Vector2.new(0.5, 0)
	toast.Position = UDim2.fromScale(0.5, 0.04)
	toast.Size = UDim2.fromScale(0.4, 0.07)
	toast.BackgroundColor3 = Theme.color(tokens.fill)
	toast.TextColor3 = Theme.color(tokens.label)
	toast.FontFace = Theme.fonts.bodyBold
	toast.Text = text
	toast.TextScaled = true
	addTextLimits(toast, "body")
	addCorner(toast, Theme.radius.pill)
	addStroke(toast, Theme.stroke.normal)
	addShadow(toast)
	toast.Parent = parent

	task.delay(TOAST_SECONDS, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

--[=[
	A horizontal progress bar. setProgress takes 0 to 1 and animates the fill.
]=]
function UIKit.progressBar(props: ProgressBarProps): ProgressBar
	local root = Instance.new("Frame")
	applyFrameProps(root, props)
	root.BackgroundColor3 = Theme.color("bg2")
	root.BorderSizePixel = 0
	addCorner(root, Theme.radius.pill)
	addStroke(root, Theme.stroke.normal)

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.BackgroundColor3 = Theme.color(props.fill or "success")
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(0, 1)
	addCorner(fill, Theme.radius.pill)
	fill.Parent = root

	root.Parent = props.parent

	local function setProgress(fraction: number)
		local clamped = math.clamp(fraction, 0, 1)
		TweenService:Create(fill, Theme.tweenInfo("normal"), { Size = UDim2.fromScale(clamped, 1) }):Play()
	end

	return { root = root, setProgress = setProgress }
end

return UIKit
