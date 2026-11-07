# UI Style Guide

The design standard for every UI Ray Luau Coder builds. Tokens live in templates/Theme.luau and templates/palettes.json. Every palette pair passes tools/check_contrast.py (results in CHANGELOG.md).

## 1. Three style directions

| Direction | Look | Fonts | Shapes | Best for |
|---|---|---|---|---|
| **Studded Classic** (default) | Toy-brick: saturated primaries on deep navy panels, thick dark outlines, faint stud pattern on panels, chunky drop shadows | Fredoka One for titles, Builder Sans Bold for body | Corner radius 12 to 16 px, stroke 3 px, shadow offset 0, 4 px | Obbies, tower games, classic-style hangouts, sword fighting |
| **Candy Pop** | Light pastel backgrounds, deep pink and purple actions, soft shadows | Fredoka One titles, Builder Sans body | Radius 18 to 24 px, stroke 2 px light, soft blur shadows | Simulators, pets, tycoons, younger audiences |
| **Neon Night** | Near-black panels, glowing cyan, violet and green accents, thin bright strokes | Builder Sans Bold / Extended | Radius 8 to 10 px, stroke 1.5 to 2 px bright, glow via UIShadow with colored shadow | Competitive, sci-fi, night maps, PvP |

Fonts: `Enum.Font.FredokaOne` and `Enum.Font.BuilderSans` ship with Roblox [DEFS]. Builder fonts are licensed for use in experiences and their promotions [D10]. Load weights with `Font.fromName("BuilderSans", Enum.FontWeight.Bold)` [DEFS].

## 2. Tokens

| Token group | Values |
|---|---|
| Colors | primary, onPrimary, secondary, onSecondary, accent, onAccent, success, onSuccess, danger, onDanger, bg0 (page), bg1 (panel), bg2 (raised card), text, textMuted, stroke, studTint |
| Type scale (px at 1080p, scale down with UITextSizeConstraint) | display 48, title 32, heading 24, body 18, caption 14 |
| Spacing | 4, 8, 12, 16, 24, 32 |
| Radius | small 8, medium 12, large 16, pill = UDim.new(0.5, 0) |
| Stroke | thin 1.5, normal 3, thick 4 |
| Shadow | offset (0, 4 px), blur 6 px, transparency 0.6 |
| Motion | fast 0.12 s, normal 0.2 s, slow 0.35 s; easing Quad Out for most, Back Out for pop-ins |

## 3. Palettes (hex)

| Token | Studded Classic | Candy Pop | Neon Night |
|---|---|---|---|
| primary / onPrimary | #1E63D6 / #FFFFFF | #C2185B / #FFFFFF | #00E5FF / #04141A |
| secondary / onSecondary | #1A7F34 / #FFFFFF | #6A3DE8 / #FFFFFF | #B14CFF / #12051C |
| accent / onAccent | #FFC21A / #1B1B1B | #00B3C7 / #0B2A30 | #39FF88 / #04190C |
| success / onSuccess | #2BB24C / #0E2A14 | #2ECC71 / #0B2E1A | #39FF88 / #04190C |
| danger / onDanger | #E23B2E / #FFFFFF | #FF5A5F / #3A0A0C | #FF3B6B / #1A0309 |
| bg0 / bg1 / bg2 | #16202E / #1F2C40 / #2A3A55 | #FFF5FA / #FFE6F2 / #FFD6EA | #0A0D18 / #121829 / #1C2440 |
| text / textMuted | #FFFFFF / #C3CEE2 | #341A45 / #5E3F72 | #F2F6FF / #A9B4D0 |
| stroke / studTint | #0B111A / #FFFFFF | #E8A3C6 / #FFFFFF | #2E3A63 / #B14CFF |

## 4. Rules with examples

### Color comes from tokens
```lua
-- Bad
button.BackgroundColor3 = Color3.fromRGB(30, 99, 214)

-- Good
button.BackgroundColor3 = Theme.color("primary")
```

### Every button has a label color made for its fill
```lua
-- Bad: white text on yellow is unreadable (about 1.6:1)
accentButton.TextColor3 = Color3.new(1, 1, 1)

-- Good: onAccent passes 4.5:1
accentButton.TextColor3 = Theme.color("onAccent")
```

### Scale, not Offset
```lua
-- Bad: 400 px wide looks huge on a phone and tiny on 4K
panel.Size = UDim2.fromOffset(400, 300)

-- Good
panel.Size = UDim2.fromScale(0.4, 0.5)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(560, 420)
limit.Parent = panel
```

### Safe area
```lua
-- Bad: HUD hidden under the notch and the Roblox top bar
hud.ScreenInsets = Enum.ScreenInsets.None

-- Good
hud.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
```

### Layout: HUD in the corners, center clear
- Top left: currency and level. Top right: settings, shop shortcut. Bottom right: action buttons (mobile thumb zone). Bottom left: mobile joystick area, keep it empty.
- Center: only temporary popups (rewards, prompts). Gameplay must stay visible.

### One primary action per screen
```
Bad:  [Buy] [Equip] [Gift] [Sell] all bright blue
Good: [Buy] primary, [Equip] secondary, [Gift] [Sell] as quiet text buttons
```

### Motion is short and skippable
```lua
-- Bad: 1 second bounce on every open
TweenInfo.new(1, Enum.EasingStyle.Bounce)

-- Good
TweenInfo.new(Theme.motion.normal, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
```

### UI never decides outcomes
```lua
-- Bad
buyButton.Activated:Connect(function()
	coins.Value -= 100
	giveSword()
end)

-- Good
buyButton.Activated:Connect(function()
	Remotes.RequestPurchase:FireServer("Sword")
end)
```

## 5. The studded look in UI

- Stud pattern: a tiled `ImageLabel` (ScaleType Tile, TileSize about 24 to 32 px) behind panel content, tinted with `studTint` at 85 to 92 percent transparency. Subtle is the point; text must stay readable.
- Chunky depth: dark `UIStroke` (stroke token, 3 px) plus a `UIShadow` with Offset (0, 4 px) and low blur so buttons look like bricks.
- Pressed state: shift the button down 2 to 3 px and shrink the shadow offset, so it looks pushed in. When Upgraded UIShadow ships to clients, `Inset = true` gives a real pressed look [A7].
- Titles in Fredoka One, outlined with a `UIStroke` on the TextLabel (ApplyStrokeMode Contextual) in the stroke color.
- Icons: filled or bold weights (Phosphor fill or bold, Kenney packs) read better at small sizes than thin outlines in this style.

## 6. Do and don't

| Do | Don't |
|---|---|
| 2 to 3 colors doing the work, plus neutrals | Rainbow buttons |
| Same corner radius family on every element | Mixing sharp and round at random |
| Icons from one or two sets per screen, same stroke weight | Mixing outline and filled icons in one toolbar |
| Show currency change with a short tick-up | Silent jumps the player misses |
| Close buttons in the same corner on every menu | Close in different places per menu |
