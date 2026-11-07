# Ray Luau Coder Design Cheat Sheet (2.1.0)

## Palettes (all pass WCAG contrast)

| Token | Studded Classic | Candy Pop | Neon Night |
|---|---|---|---|
| primary / on | #1E63D6 / #FFFFFF | #C2185B / #FFFFFF | #00E5FF / #04141A |
| secondary / on | #1A7F34 / #FFFFFF | #6A3DE8 / #FFFFFF | #B14CFF / #12051C |
| accent / on | #FFC21A / #1B1B1B | #00B3C7 / #0B2A30 | #39FF88 / #04190C |
| danger / on | #E23B2E / #FFFFFF | #FF5A5F / #3A0A0C | #FF3B6B / #1A0309 |
| bg0 / bg1 / bg2 | #16202E / #1F2C40 / #2A3A55 | #FFF5FA / #FFE6F2 / #FFD6EA | #0A0D18 / #121829 / #1C2440 |
| text / muted | #FFFFFF / #C3CEE2 | #341A45 / #5E3F72 | #F2F6FF / #A9B4D0 |

Fonts: Fredoka One titles, Builder Sans Medium body, Builder Sans Bold buttons.

## Sizes

| Spacing | 4, 8, 12, 16, 24, 32 px |
|---|---|
| Radius | 8 small, 12 buttons, 16 panels, pill 0.5 scale |
| Stroke | 1.5 thin, 3 normal, 4 thick |
| Text (1080p) | display 48, title 32, heading 24, body 18, caption 14; min 12 |
| Touch target | 44 px minimum |
| Shadow | offset 0, 4 px; blur 6 px; transparency 0.6; under 100 on screen |

## Motion

| Use | Time | Easing |
|---|---|---|
| Hover, press | 0.12 s | Quad Out (scale 1.05 hover, 0.95 press) |
| Open panel | 0.2 s | Back Out (scale 0.9 to 1) |
| Close panel | 0.12 to 0.15 s | Quad Out |
| List stagger | 0.03 s per item, max 0.3 s | |
| Number tick-up | 0.3 to 0.6 s | |
| Reduced motion | fade only | |

## Layout

- Scale for size and position; UISizeConstraint caps panels on big screens.
- ScreenInsets = CoreUISafeInsets. ResetOnSpawn = false. Three ScreenGuis: HUD 0, Menus 10, Popups 20.
- HUD: currency top left, shop and settings top right, actions bottom right, bottom left empty for the thumbstick.
- One primary button per screen. `Activated`, never `MouseButton1Click`.

## Lighting presets (starting values)

| | SunnyToy | Sunset | NeonNight | Spooky |
|---|---|---|---|---|
| ClockTime | 13 | 17.8 | 0 | 20.5 |
| Brightness | 3 | 2.5 | 1 | 0.8 |
| Saturation (ColorCorrection) | 0.25 | 0.3 | 0.35 | -0.25 |
| Bloom threshold | 0.95 | 0.9 | 0.85 | 1.2 |
| LightingStyle (set in Studio) | Soft | Soft | Realistic | Realistic |

`Lighting.Technology` is deprecated. Use LightingStyle and compare Soft vs Realistic by eye.

## Map color rules

60 percent base, 30 percent support, 10 percent accent. Interactables brightest. Hazards red or orange Neon, tagged KillBrick. Checkpoints green, tagged Checkpoint. Check value contrast in grayscale.

## Icon sources (approved)

| Set | License | Credit |
|---|---|---|
| Lucide | ISC | credits line |
| Tabler | MIT | credits line |
| Phosphor | MIT | credits line |
| Kenney | CC0 | none |
| game-icons.net | CC BY 3.0 | name each author |
| Builder fonts | Roblox Builder font license | none |

Pipeline: white SVG, 128 px cells with 12 px padding, `python3 tools/build_icon_atlas.py icons/ out/`, upload atlas_0.png, paste the ID into IconAtlas.luau, tint with ImageColor3.

## Status to remember

| Feature | Status 2026-11-06 |
|---|---|
| UI Styling, StyleQuery, Styling Transitions | Released |
| UIShadow | Released |
| Upgraded UIShadow (text, inset, knockout, gradient) | Studio beta, do not publish |
| Device Simulator + Network Simulator | Out of beta |
| Procedural Models | Docs live; release status unverified |
| UIBlur, ParticleEmitter2D | In API, not announced; do not use |
