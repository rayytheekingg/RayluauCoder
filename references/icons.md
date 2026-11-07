# Icons Reference

Verified as of 2026-11-06. License files were read directly from each project on that date. IDs point to research/ui-maps-reference-catalog.md. This is not legal advice; when in doubt, add a credit line.

## 1. Approved icon sources

| ID | Set | Get it | License | Credit | Style notes |
|---|---|---|---|---|---|
| D1 | Lucide | lucide.dev, github.com/lucide-icons/lucide | ISC | Keep the license notice: add to CREDITS | Clean 24 px outline, 2 px stroke; best for Candy Pop and Neon Night |
| D2 | Tabler Icons | tabler.io/icons, github.com/tabler/tabler-icons | MIT | Keep the license notice: add to CREDITS | Huge outline set plus filled variants |
| D3 | Phosphor | phosphoricons.com, github.com/phosphor-icons/core | MIT | Keep the license notice: add to CREDITS | Six weights; use Bold or Fill for Studded Classic |
| D8 | Kenney | kenney.nl | CC0 (public domain) | None required; do not use the Kenney logo | Game UI packs: buttons, panels, game icons; fits the toy look |
| D9 | game-icons.net | game-icons.net | CC BY 3.0 | **Required**: credit each icon's author | About 4,178 game icons: weapons, potions, loot, skills |
| D10 | Builder Sans / Extended / Mono (fonts) | ships with Roblox | Roblox Builder font license: allowed in experiences and their promotions | None required | Body and UI text |

Not approved: the internal BuilderIcons font [D11]. It loads from an undocumented path, icons can be removed without notice, and the Builder font license does not cover it.

Rule for MIT and ISC sets: the license says the copyright and permission notice must be kept with copies. A CREDITS section in the game description plus the license files in your repo is the practical way to do that. CC0 needs nothing. CC BY needs the author name for every icon used.

## 2. CREDITS template

Keep a CREDITS.md in the project and paste the short version into the game description:

```
Icons: Lucide (ISC), Tabler Icons (MIT), Phosphor Icons (MIT), Kenney (CC0).
Game icons by Lorc, Delapouite and contributors, game-icons.net (CC BY 3.0).
```

List the actual game-icons.net authors you used (each icon page shows its author).

## 3. Pipeline: SVG to Roblox

1. **Pick** icons from one or two sets per screen with matching stroke weight.
2. **Export white**: replace `currentColor` and fills with `#FFFFFF`. White glyphs can be tinted to any color with `ImageColor3`, so one upload serves every palette.
3. **Size**: render at 128 px (crisp on phones and 1080p). Use 256 px only for large hero icons. Add 8 to 12 percent padding so strokes are not clipped.
4. **Pack into an atlas**: tools/build_icon_atlas.py packs many icons into one PNG sheet and writes an IconAtlas.luau map (name to image, rect offset, rect size). One upload instead of 40. Keep each sheet at or under 1024 x 1024 px; Roblox downscales larger uploads [UNVERIFIED current limit].
5. **Upload** the sheet through the Asset Manager (or Open Cloud assets API, or the Studio MCP asset tools). Images go through moderation; plain white glyphs pass quickly.
6. **Paste the asset ID** into the generated IconAtlas.luau (`rbxassetid://ATLAS_0` placeholders).
7. **Use** with `IconAtlas.apply(imageLabel, "sword")`, then tint with `ImageColor3 = Theme.color("onPrimary")`.

Commands:
```bash
# Lucide example: copy the SVGs you want into icons/svg/, then
python3 tools/build_icon_atlas.py icons/svg out/ --size 128 --padding 12
# out/atlas_0.png  -> upload, copy the asset ID
# out/IconAtlas.luau -> replace ATLAS_0 with the ID, drop into ReplicatedStorage/Shared
```

The script needs `rsvg-convert` (librsvg) or the `cairosvg` Python package, plus Pillow.

## 4. Using atlas icons in UI

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IconAtlas = require(ReplicatedStorage.Shared.IconAtlas)
local Theme = require(ReplicatedStorage.Shared.Theme)

local icon = Instance.new("ImageLabel")
icon.BackgroundTransparency = 1
icon.Size = UDim2.fromScale(0.6, 0.6)
icon.AnchorPoint = Vector2.new(0.5, 0.5)
icon.Position = UDim2.fromScale(0.5, 0.5)
IconAtlas.apply(icon, "sword")
icon.ImageColor3 = Theme.color("onPrimary")
```

`ImageRectOffset` and `ImageRectSize` cut the icon out of the sheet. Keep `ScaleType = Fit` and add a `UIAspectRatioConstraint` (ratio 1) so icons never stretch.

## 5. Rules

- One icon set per style family per screen. Outline icons with Lucide or Tabler; filled or bold with Phosphor Fill/Bold or Kenney.
- Same visual size: icons sit in a square slot at 60 to 70 percent of the button height.
- Every icon-only button has a tooltip or label nearby for clarity, and a text alternative on gamepad prompts.
- Currency and rarity icons get color (tint) from tokens, never baked colors, except multi-color art (Kenney items) which stays as uploaded.
- Free models and icon packs from the Creator Store: check the license and inspect for hidden scripts before inserting anything.
