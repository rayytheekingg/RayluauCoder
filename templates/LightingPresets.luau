--!strict
-- LightingPresets: apply a named lighting mood, optionally tweening from the current one.
-- Place at: ReplicatedStorage/Shared/LightingPresets (Rojo: src/shared/LightingPresets.luau)
-- Server use: changes replicate to everyone. Client use (LocalScript): per-player moods.
-- Values are starting points from references/lighting-presets.md; tune them by eye.
-- Set Lighting.LightingStyle (Soft or Realistic) in Studio, not here.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

export type PresetName = "SunnyToy" | "Sunset" | "NeonNight" | "Spooky"

type Preset = {
	lighting: { [string]: any },
	atmosphere: { [string]: any },
	colorCorrection: { [string]: any },
	bloom: { [string]: any },
	sunRays: { [string]: any },
	tonemapper: Enum.TonemapperPreset,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local PRESETS: { [PresetName]: Preset } = {
	SunnyToy = {
		lighting = {
			ClockTime = 13,
			Brightness = 3,
			Ambient = rgb(110, 110, 120),
			OutdoorAmbient = rgb(150, 150, 160),
			ExposureCompensation = 0.1,
			ShadowSoftness = 0.25,
		},
		atmosphere = {
			Density = 0.25,
			Offset = 0.1,
			Color = Color3.fromHex("C7E4FF"),
			Decay = Color3.fromHex("6FA8DC"),
			Glare = 0.2,
			Haze = 1,
		},
		colorCorrection = { Brightness = 0.03, Contrast = 0.1, Saturation = 0.25, TintColor = rgb(255, 255, 255) },
		bloom = { Intensity = 0.4, Size = 24, Threshold = 0.95 },
		sunRays = { Intensity = 0.06, Spread = 0.6 },
		tonemapper = Enum.TonemapperPreset.Default,
	},
	Sunset = {
		lighting = {
			ClockTime = 17.8,
			Brightness = 2.5,
			Ambient = rgb(90, 70, 80),
			OutdoorAmbient = rgb(170, 120, 110),
			ExposureCompensation = 0.2,
			ShadowSoftness = 0.3,
		},
		atmosphere = {
			Density = 0.35,
			Offset = 0.15,
			Color = Color3.fromHex("FFC9A3"),
			Decay = Color3.fromHex("B4567A"),
			Glare = 0.6,
			Haze = 2,
		},
		colorCorrection = { Brightness = 0, Contrast = 0.12, Saturation = 0.3, TintColor = Color3.fromHex("FFE9D6") },
		bloom = { Intensity = 0.6, Size = 30, Threshold = 0.9 },
		sunRays = { Intensity = 0.15, Spread = 0.8 },
		tonemapper = Enum.TonemapperPreset.Default,
	},
	NeonNight = {
		lighting = {
			ClockTime = 0,
			Brightness = 1,
			Ambient = rgb(40, 30, 70),
			OutdoorAmbient = rgb(60, 50, 110),
			ExposureCompensation = 0.3,
			ShadowSoftness = 0.4,
		},
		atmosphere = {
			Density = 0.4,
			Offset = 0.2,
			Color = Color3.fromHex("4B3A8C"),
			Decay = Color3.fromHex("1A1240"),
			Glare = 0,
			Haze = 1.5,
		},
		colorCorrection = { Brightness = 0, Contrast = 0.15, Saturation = 0.35, TintColor = Color3.fromHex("E6DFFF") },
		bloom = { Intensity = 1, Size = 36, Threshold = 0.85 },
		sunRays = { Intensity = 0, Spread = 0 },
		tonemapper = Enum.TonemapperPreset.Default,
	},
	Spooky = {
		lighting = {
			ClockTime = 20.5,
			Brightness = 0.8,
			Ambient = rgb(35, 40, 45),
			OutdoorAmbient = rgb(55, 65, 70),
			ExposureCompensation = 0,
			ShadowSoftness = 0.5,
		},
		atmosphere = {
			Density = 0.55,
			Offset = 0.25,
			Color = Color3.fromHex("8A9AA8"),
			Decay = Color3.fromHex("2F3A40"),
			Glare = 0,
			Haze = 3,
		},
		colorCorrection = { Brightness = 0, Contrast = 0.05, Saturation = -0.25, TintColor = Color3.fromHex("D8E6E0") },
		bloom = { Intensity = 0.3, Size = 20, Threshold = 1.2 },
		sunRays = { Intensity = 0, Spread = 0 },
		tonemapper = Enum.TonemapperPreset.Default,
	},
}

local EFFECT_PREFIX = "Preset"

-- Finds or creates the one effect of `className` this module manages under Lighting.
local function getEffect(className: string): Instance
	local name = `{EFFECT_PREFIX}{className}`
	local existing = Lighting:FindFirstChild(name)
	if existing then
		return existing
	end
	local effect = Instance.new(className)
	effect.Name = name
	effect.Parent = Lighting
	return effect
end

local function setOrTween(instance: Instance, goals: { [string]: any }, info: TweenInfo?)
	if info then
		TweenService:Create(instance, info, goals):Play()
		return
	end
	for property, value in goals do
		(instance :: any)[property] = value -- any: property names come from the typed preset table
	end
end

local LightingPresets = {}

--[=[
	Applies preset `name`. With `tweenSeconds`, numbers and colors tween smoothly
	(ClockTime tweens the long way round when crossing midnight; keep zone presets on the same side).
]=]
function LightingPresets.apply(name: PresetName, tweenSeconds: number?)
	local preset = PRESETS[name]
	assert(preset, `LightingPresets.apply: unknown preset {name}`)
	local info = if tweenSeconds and tweenSeconds > 0
		then TweenInfo.new(tweenSeconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		else nil

	setOrTween(Lighting, preset.lighting, info)
	setOrTween(getEffect("Atmosphere"), preset.atmosphere, info)
	setOrTween(getEffect("ColorCorrectionEffect"), preset.colorCorrection, info)
	setOrTween(getEffect("BloomEffect"), preset.bloom, info)
	setOrTween(getEffect("SunRaysEffect"), preset.sunRays, info)

	local grading = getEffect("ColorGradingEffect") :: ColorGradingEffect
	grading.TonemapperPreset = preset.tonemapper
end

--[=[
	Returns every preset name, for a settings or debug menu.
]=]
function LightingPresets.names(): { PresetName }
	return { "SunnyToy", "Sunset", "NeonNight", "Spooky" }
end

return LightingPresets
