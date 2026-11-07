# Lighting Presets

Verified as of 2026-11-06 for property names [DEFS]. The values below are starting points chosen for this skill, not Roblox recommendations: tune by eye in Studio. templates/LightingPresets.luau applies them in code and can tween between them.

## 1. What changed: Unified Lighting

- `Lighting.Technology` is marked deprecated in the API reference. `Enum.Technology` now includes `Unified` alongside Voxel, ShadowMap, Future, Compatibility and Legacy [DEFS]. The DevForum thread "Let There Be (Unified) Light!" is now titled "Unified Lighting is Fully Live" (exact date [UNVERIFIED]; the forum was in maintenance during this research).
- New Lighting properties: `LightingStyle` (`Enum.LightingStyle.Realistic` or `Soft`) and `PrioritizeLightingQuality` (boolean) [DEFS].
- Practical rule: set `LightingStyle` in Studio's Properties panel, not in scripts. Try **Soft** first for the toy and studded look and compare with **Realistic**; which one reads better depends on the map (the exact rendering difference is [UNVERIFIED], so judge visually).
- `ColorGradingEffect` with `TonemapperPreset` (`Default` or `Retro`) controls tone mapping [E7], [DEFS]. Retro gives a flatter, older look; Default is the modern curve.

## 2. Property map

| Object (parent) | Properties used here |
|---|---|
| Lighting | ClockTime, Brightness, Ambient, OutdoorAmbient, ExposureCompensation, EnvironmentDiffuseScale, EnvironmentSpecularScale, ShadowSoftness, GlobalShadows |
| Atmosphere (Lighting) | Density, Offset, Color, Decay, Glare, Haze |
| ColorCorrectionEffect (Lighting) | Brightness, Contrast, Saturation, TintColor |
| BloomEffect (Lighting) | Intensity, Size, Threshold |
| SunRaysEffect (Lighting) | Intensity, Spread |
| ColorGradingEffect (Lighting) | TonemapperPreset |
| Clouds (Workspace.Terrain) | Cover, Density, Color |

## 3. Presets

| Property | SunnyToy | Sunset | NeonNight | Spooky |
|---|---|---|---|---|
| ClockTime | 13 | 17.8 | 0 | 20.5 |
| Brightness | 3 | 2.5 | 1 | 0.8 |
| Ambient | 110, 110, 120 | 90, 70, 80 | 40, 30, 70 | 35, 40, 45 |
| OutdoorAmbient | 150, 150, 160 | 170, 120, 110 | 60, 50, 110 | 55, 65, 70 |
| ExposureCompensation | 0.1 | 0.2 | 0.3 | 0 |
| ShadowSoftness | 0.25 | 0.3 | 0.4 | 0.5 |
| Atmosphere Density / Offset | 0.25 / 0.1 | 0.35 / 0.15 | 0.4 / 0.2 | 0.55 / 0.25 |
| Atmosphere Color / Decay | #C7E4FF / #6FA8DC | #FFC9A3 / #B4567A | #4B3A8C / #1A1240 | #8A9AA8 / #2F3A40 |
| Atmosphere Glare / Haze | 0.2 / 1 | 0.6 / 2 | 0 / 1.5 | 0 / 3 |
| ColorCorrection Contrast / Saturation | 0.1 / 0.25 | 0.12 / 0.3 | 0.15 / 0.35 | 0.05 / -0.25 |
| ColorCorrection Tint | #FFFFFF | #FFE9D6 | #E6DFFF | #D8E6E0 |
| Bloom Intensity / Size / Threshold | 0.4 / 24 / 0.95 | 0.6 / 30 / 0.9 | 1 / 36 / 0.85 | 0.3 / 20 / 1.2 |
| SunRays Intensity / Spread | 0.06 / 0.6 | 0.15 / 0.8 | 0 / 0 | 0 / 0 |
| Suggested LightingStyle (Studio) | Soft | Soft | Realistic | Realistic |

## 4. Rules for vibrant maps

- Saturation does most of the work. Push ColorCorrection Saturation to 0.2 to 0.35 for bright toy worlds; do not crank Brightness instead (it washes colors out).
- Keep Ambient and OutdoorAmbient a little cool (blue-gray) in daylight so shadows have color instead of going black.
- Bloom: high Threshold (0.9 or more) so only Neon parts and the sun glow; low threshold blurs the whole screen.
- Neon parts are the hazard and reward color source at night; pair NeonNight with Neon material accents.
- One preset per zone or per round state. Tween between them over 2 to 4 seconds on zone change; never snap.
- Lighting set by the server replicates to every player. For per-player moods (one player entering a cave), set lighting from a LocalScript instead.
- Test every preset on an Entry level phone in the Device Simulator; post effects cost frame time.
