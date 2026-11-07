--!strict
-- Theme: every color, font, size, radius and timing the UI uses. Components read from here only.
-- Place at: ReplicatedStorage/Shared/Theme (Rojo: src/shared/Theme.luau)
-- Palettes mirror templates/palettes.json. When you change a hex value, change both and run
-- tools/check_contrast.py.

export type PaletteName = "StuddedClassic" | "CandyPop" | "NeonNight"

export type ColorToken =
	"primary"
	| "onPrimary"
	| "secondary"
	| "onSecondary"
	| "accent"
	| "onAccent"
	| "success"
	| "onSuccess"
	| "danger"
	| "onDanger"
	| "bg0"
	| "bg1"
	| "bg2"
	| "text"
	| "textMuted"
	| "stroke"
	| "studTint"

export type TextStyle = "display" | "title" | "heading" | "body" | "caption"
export type MotionSpeed = "fast" | "normal" | "slow"

type Palette = { [ColorToken]: string }

local PALETTES: { [PaletteName]: Palette } = {
	StuddedClassic = {
		primary = "1E63D6",
		onPrimary = "FFFFFF",
		secondary = "1A7F34",
		onSecondary = "FFFFFF",
		accent = "FFC21A",
		onAccent = "1B1B1B",
		success = "2BB24C",
		onSuccess = "0E2A14",
		danger = "E23B2E",
		onDanger = "FFFFFF",
		bg0 = "16202E",
		bg1 = "1F2C40",
		bg2 = "2A3A55",
		text = "FFFFFF",
		textMuted = "C3CEE2",
		stroke = "0B111A",
		studTint = "FFFFFF",
	},
	CandyPop = {
		primary = "C2185B",
		onPrimary = "FFFFFF",
		secondary = "6A3DE8",
		onSecondary = "FFFFFF",
		accent = "00B3C7",
		onAccent = "0B2A30",
		success = "2ECC71",
		onSuccess = "0B2E1A",
		danger = "FF5A5F",
		onDanger = "3A0A0C",
		bg0 = "FFF5FA",
		bg1 = "FFE6F2",
		bg2 = "FFD6EA",
		text = "341A45",
		textMuted = "5E3F72",
		stroke = "E8A3C6",
		studTint = "FFFFFF",
	},
	NeonNight = {
		primary = "00E5FF",
		onPrimary = "04141A",
		secondary = "B14CFF",
		onSecondary = "12051C",
		accent = "39FF88",
		onAccent = "04190C",
		success = "39FF88",
		onSuccess = "04190C",
		danger = "FF3B6B",
		onDanger = "1A0309",
		bg0 = "0A0D18",
		bg1 = "121829",
		bg2 = "1C2440",
		text = "F2F6FF",
		textMuted = "A9B4D0",
		stroke = "2E3A63",
		studTint = "B14CFF",
	},
}

-- Tag -> properties mapped to tokens. UIKit tags every element it creates, so a StyleSheet built
-- from this table restyles the whole UI when the palette changes.
local TAG_RULES: { [string]: { [string]: ColorToken } } = {
	Panel = { BackgroundColor3 = "bg1" },
	Card = { BackgroundColor3 = "bg2" },
	Page = { BackgroundColor3 = "bg0" },
	ButtonPrimary = { BackgroundColor3 = "primary", TextColor3 = "onPrimary" },
	ButtonSecondary = { BackgroundColor3 = "secondary", TextColor3 = "onSecondary" },
	ButtonAccent = { BackgroundColor3 = "accent", TextColor3 = "onAccent" },
	ButtonDanger = { BackgroundColor3 = "danger", TextColor3 = "onDanger" },
	TextBody = { TextColor3 = "text" },
	TextMuted = { TextColor3 = "textMuted" },
}

local paletteChanged = Instance.new("BindableEvent")
local currentPalette: PaletteName = "StuddedClassic"
local tokenSheet: StyleSheet? = nil
local designSheet: StyleSheet? = nil

local Theme = {}

Theme.spacing = { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }
Theme.radius = {
	small = UDim.new(0, 8),
	medium = UDim.new(0, 12),
	large = UDim.new(0, 16),
	pill = UDim.new(0.5, 0),
}
Theme.stroke = { thin = 1.5, normal = 3, thick = 4 }
local TEXT_SIZE: { [TextStyle]: number } = { display = 48, title = 32, heading = 24, body = 18, caption = 14 }
local MOTION: { [MotionSpeed]: number } = { fast = 0.12, normal = 0.2, slow = 0.35 }
Theme.textSize = TEXT_SIZE
Theme.minTextSize = 12
Theme.motion = MOTION
Theme.shadow = {
	offset = UDim2.fromOffset(0, 4),
	blur = UDim.new(0, 6),
	transparency = 0.6,
}
Theme.fonts = {
	title = Font.fromEnum(Enum.Font.FredokaOne),
	body = Font.fromEnum(Enum.Font.BuilderSansMedium),
	bodyBold = Font.fromEnum(Enum.Font.BuilderSansBold),
}
-- Replace with your uploaded assets. "rbxassetid://0" means "not set" and is skipped by UIKit.
Theme.assets = {
	studTile = "rbxassetid://0",
	clickSound = "rbxassetid://0",
}
Theme.studTileSize = UDim2.fromOffset(28, 28)
Theme.studTransparency = 0.9
-- Set from a settings menu or a ReducedMotionEnabled StyleQuery; UIKit then fades instead of scaling.
Theme.reducedMotion = false

--[=[
	Fires with the new palette name after Theme.setPalette.
]=]
Theme.paletteChanged = paletteChanged.Event

--[=[
	Returns the Color3 for `token` in the current palette.
]=]
function Theme.color(token: ColorToken): Color3
	return Color3.fromHex(PALETTES[currentPalette][token])
end

--[=[
	Returns the name of the active palette.
]=]
function Theme.getPalette(): PaletteName
	return currentPalette
end

local function writeTokens(sheet: StyleSheet)
	for token, hex in PALETTES[currentPalette] do
		sheet:SetAttribute(token, Color3.fromHex(hex))
	end
end

--[=[
	Switches the active palette. Styled UI (linked to Theme.getStyleSheet) updates immediately;
	code that read Theme.color earlier should listen to Theme.paletteChanged.
]=]
function Theme.setPalette(name: PaletteName)
	assert(PALETTES[name], `Theme.setPalette: unknown palette {name}`)
	currentPalette = name
	if tokenSheet then
		writeTokens(tokenSheet)
	end
	paletteChanged:Fire(name)
end

--[=[
	Returns a TweenInfo for a motion speed, or a zero-length tween when reduced motion is on.
]=]
function Theme.tweenInfo(speed: MotionSpeed, style: Enum.EasingStyle?): TweenInfo
	if Theme.reducedMotion then
		return TweenInfo.new(0)
	end
	return TweenInfo.new(Theme.motion[speed], style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
end

--[=[
	Returns the design StyleSheet (created once). Link it to a ScreenGui with a StyleLink;
	UIKit.screen does this for you. Tokens are attributes on a token sheet; rules reference them as "$token".
]=]
function Theme.getStyleSheet(): StyleSheet
	if designSheet then
		return designSheet
	end

	local tokens = Instance.new("StyleSheet")
	tokens.Name = "ThemeTokens"
	writeTokens(tokens)

	local design = Instance.new("StyleSheet")
	design.Name = "ThemeDesign"
	local derive = Instance.new("StyleDerive")
	derive.StyleSheet = tokens
	derive.Parent = design

	for tag, properties in TAG_RULES do
		local rule = Instance.new("StyleRule")
		rule.Name = tag
		rule.Selector = `.{tag}`
		local styled: { [string]: string } = {}
		for property, token in properties do
			styled[property] = `${token}`
		end
		rule:SetProperties(styled)
		rule.Parent = design
	end

	tokens.Parent = design
	-- The docs keep sheets in the DataModel; on the client this local copy is only visible to that player.
	design.Parent = game:GetService("ReplicatedStorage")
	tokenSheet = tokens
	designSheet = design
	return design
end

return Theme
