# UI Design and Engineering Reference

Verified as of 2026-11-06. IDs in brackets point to research/ui-maps-reference-catalog.md. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. What is current in Roblox UI

| Feature | What it does | Status | Source |
|---|---|---|---|
| UI Styling: `StyleSheet`, `StyleRule`, `StyleDerive`, `StyleLink`, tokens, Style Editor | CSS-like rules and design tokens applied to whole GUI trees | Released 2026-01-20 | [A1], [A4] |
| `StyleQuery` | Conditional styles: MinSize, MaxSize, AspectRatioRange, ViewportDisplaySize, PreferredInput, ReducedMotionEnabled, PreferredTextSize | Released 2026-05-11 | [A2] |
| Styling Transitions | Tweens defined in StyleSheets; fire on style changes such as GuiState Hover | Released 2026-07-27 | [A3] |
| `UIShadow` | Native shadows: BlurRadius, Color, Offset, Spread, Transparency, Mode (Shape or Text), Inset, ShowBehindParent | Released early 2026 | [A6] |
| Upgraded UIShadow | Text shadows, inset shadows, knockout shadows, UIGradient on shadows | Studio beta 2026-10-14, cannot publish | [A7] |
| `Path2D` | Lines and curves in UI | Released | [A10] |
| Flex layout | `UIListLayout` HorizontalFlex, VerticalFlex, ItemLineAlignment, Wraps; `UIFlexItem` on children | Released | [A5], [DEFS] |
| Device Simulator + Network Simulator | Phone, tablet, console, headset presets; touch and controller emulation; latency and packet loss | Out of beta week of 2026-10-12 | [A11], [A12] |
| `UIBlur`, `ParticleEmitter2D` | Present in the API definitions, no announcement or docs | Do not use | [A8], [A9] |

## 2. Structure of a game's UI

```
StarterGui (or built at runtime by a client controller)
  HUD          ScreenGui  DisplayOrder 0   always visible: currency, health, quest
  Menus        ScreenGui  DisplayOrder 10  shop, inventory, settings (one open at a time)
  Popups       ScreenGui  DisplayOrder 20  toasts, reward reveals, confirmations
  StyleLink under each ScreenGui pointing at the shared design StyleSheet
```

Rules:
- Three ScreenGuis is enough for most games. Every extra ScreenGui adds draw and layout cost.
- `ResetOnSpawn = false` on every ScreenGui, so menus keep state when the character respawns [DEFS].
- `ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets` for HUD and menus so nothing sits under the notch or the Roblox top bar. `DeviceSafeInsets` only for full-bleed backgrounds [DEFS].
- One Theme module (templates/Theme.luau) owns every color, size, font and timing. Components never hardcode a color.
- One MenuManager (templates/MenuManager.luau) opens and closes menus. Opening a menu closes the previous one and remembers it for Back.
- UI state mirrors server state. The server sends coins, inventory and results through Remotes or player attributes; the UI displays them and sends requests. UI never changes currency or grants items itself.

## 3. Styling API (released)

Tokens are attributes on a StyleSheet. Rules reference tokens as `"$Name"` strings. A StyleLink under a ScreenGui applies a sheet to that tree; only one sheet applies to a given tree [A4].

```lua
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Token sheet
local tokens = Instance.new("StyleSheet")
tokens.Name = "Tokens"
tokens:SetAttribute("Primary", Color3.fromHex("1E63D6"))
tokens:SetAttribute("OnPrimary", Color3.fromHex("FFFFFF"))
tokens:SetAttribute("Panel", Color3.fromHex("1F2C40"))
tokens.Parent = ReplicatedStorage

-- Design sheet derives the tokens
local design = Instance.new("StyleSheet")
design.Name = "Design"
local derive = Instance.new("StyleDerive")
derive.StyleSheet = tokens
derive.Parent = design
design.Parent = ReplicatedStorage

-- Every element tagged ButtonPrimary gets the primary look
local primaryButton = Instance.new("StyleRule")
primaryButton.Selector = ".ButtonPrimary"
primaryButton:SetProperties({
	BackgroundColor3 = "$Primary",
	TextColor3 = "$OnPrimary",
	BorderSizePixel = 0,
})
primaryButton.Parent = design

-- Apply to a ScreenGui
local function linkDesign(screenGui: ScreenGui)
	local link = Instance.new("StyleLink")
	link.StyleSheet = design
	link.Parent = screenGui
end
```

Selector forms confirmed in the docs: class name (`"TextButton"`), tag (`".ButtonPrimary"`, tag added with CollectionService), tag plus pseudo-instance (`"Frame.RoundedCorner20::UICorner"`), and query (`"@Small"` for a StyleQuery named Small) [A4]. GuiState selectors exist for Hover, Idle, Press and NonInteractable [A1], [DEFS]; the exact string form (for example `"TextButton:Hover"`) is [UNVERIFIED]. Confirm in the Style Editor before relying on it in code.

Themes: build one token sheet per palette with the same attribute names, and point the design sheet's StyleDerive at the active one. Swapping `derive.StyleSheet` switches the whole UI theme at once.

StyleQuery for responsive layouts: add a `StyleQuery` named `Compact` under the root GuiObject with a MaxSize condition (Style Editor is the safest way to author conditions; in code use `query:SetCondition(name, value)` [DEFS], value types [UNVERIFIED]). Then a rule with `Selector = "@Compact"` applies only while the query's `IsActive` is true, for example to stack a two-column shop into one column on phones. Global queries for `PreferredInput`, `ReducedMotionEnabled` and `PreferredTextSize` auto-populate in the Style Editor [A2].

Styling Transitions: `rule:SetPropertyTransition("BackgroundColor3", params)` or `SetDefaultPropertyTransition(params)` [DEFS]. Params use duration, easing style, easing direction and delay like TweenService [A3]. The rule holding the transition needs a higher Priority than the base rule. Transitions fire on style changes (tags, GuiState) only, not on layout-driven size changes.

When to use what:
- Colors, fonts, corner radii and strokes shared by many elements: Styling API.
- One-off animations, reward reveals, sequences: TweenService in code (templates/UIKit.luau).
- Both can coexist. Styles override instance properties [A1], so code may set defaults (UIKit does) and a linked StyleSheet restyles them. Do not animate a styled property from code; animate a UIScale or a property no rule touches.

## 4. Layout rules

- Size and Position in Scale. Use Offset only for small fixed values (stroke width, 4 to 16 px padding).
- `AnchorPoint = Vector2.new(0.5, 0.5)` for anything centered; corner anchors for HUD pieces.
- `UIAspectRatioConstraint` on square items (icons, item slots) so they never stretch.
- `UISizeConstraint` to cap panel size on large monitors and keep a minimum on phones.
- Text: prefer `UITextSizeConstraint` with `TextScaled = true` over plain TextScaled, so text cannot grow huge or shrink unreadable.
- `UIListLayout` with `HorizontalFlex` / `VerticalFlex` and `Wraps` for toolbars and item grids that adapt to width; `UIFlexItem` on a child to let it grow or shrink.
- `AutomaticSize` for lists whose length changes (inventory, chat-like feeds) inside a `ScrollingFrame` with `AutomaticCanvasSize`.

## 5. Input: one UI that works on touch, mouse and gamepad

- Use `GuiButton.Activated`, never `MouseButton1Click`. Activated fires for mouse, touch and gamepad A [DEFS].
- Hover feedback: `MouseEnter` / `MouseLeave` for mouse, `SelectionGained` / `SelectionLost` for gamepad.
- When a menu opens with a gamepad, set `GuiService.SelectedObject` to its first button. Use `SelectionGroup` on the menu container and `NextSelectionUp/Down/Left/Right` where the automatic order is wrong.
- Touch targets at least 44 px on the shortest side at the smallest supported phone. With Scale sizing, check this in the Device Simulator on an Entry level phone [A11].
- Back and close: an Input Action System action bound to Escape and ButtonB closes the top menu (templates/MenuManager.luau). Every menu also has a visible close button for touch.
- Keyboard shortcuts are extras, never the only way.

## 6. Feel

- Hover: scale to 1.05 or brighten; press: scale to 0.95; release: back to 1. Use a `UIScale` child so layout is not affected.
- Open: fade and scale from 0.9 to 1 in 0.18 to 0.25 s with Quad or Back easing Out. Close faster than open (0.12 to 0.15 s).
- Stagger list items by 0.03 s, capped at 0.3 s total.
- Click sound through `SoundService:PlayLocalSound(sound)` [DEFS]. One short sound per action type; keep volume low.
- Numbers that change (coins, XP) tick up over 0.3 to 0.6 s instead of jumping.
- Respect reduced motion: when a `StyleQuery` with `ReducedMotionEnabled` is active (or a settings toggle is on), replace scale and slide with a short fade.

## 7. Accessibility

- Contrast: body text at least 4.5:1 against its background; large bold labels at least 3:1. tools/check_contrast.py checks every palette pair.
- Never use color alone for meaning: pair red and green states with an icon or label.
- Support larger text: a `StyleQuery` on `PreferredTextSize` can raise text tokens [A2].
- Minimum text size about 14 px at the smallest phone; 18 px for primary labels.

## 8. Performance

- Do not update UI every frame. Update on change events (attribute changed, remote received).
- Fewer ScreenGuis and fewer deeply nested frames.
- `CanvasGroup` re-renders its whole subtree into a texture; use it only for fading complex groups, not as a default container.
- Keep under 100 UIShadows on screen at once (Roblox guidance in [A7]).
- Pack icons into atlases (references/icons.md) to cut image memory and load time.
- Hide closed menus with `Visible = false` (or disable their ScreenGui), do not just move them off screen.

## 9. Frameworks (optional) [B1], [B2], [B3]

| Library | License | Latest seen 2026-11-06 | Use when |
|---|---|---|---|
| Fusion (github.com/dphfox/Fusion) | MIT | 0.3 (tagged v0.3-beta) | You want reactive state (values update UI automatically) with Luau-style syntax |
| Vide (github.com/centau/vide) | MIT | 0.4.1, 2026-07-11, pre-release | Small, fast reactive library; comfortable with pre-release |
| React-lua (github.com/jsdotlua/react-lua) | MIT | v17.2.1 | You already know React; large UI with many screens |

Default for this skill: plain Luau with templates/UIKit.luau and the Styling API. It has no dependency and is easiest to fix. Switch to a framework only when the user asks or the project already uses one; never mix two frameworks in one project.

## 10. Figma to Roblox (optional) [C1], [C2]

| Tool | What it does | Cost |
|---|---|---|
| UILint v2 | Lints Figma UI for Roblox problems (scaling, overflow, overlap, ZIndex), exports, rebuilds native UI in Studio | Free tier; paid sync features |
| Framewisp | Converts a Figma frame to native Roblox UI; tag-based buttons (`_open:Shop`, `_close`, `_toggle`); hover and press states | 7-day trial, then subscription; one corner radius per element, no blend modes or backdrop blur |

After import, always: rename instances, replace baked text images with real TextLabels where possible, wire buttons through MenuManager, and run checklists/ui-review.md. Imported UI that sets prices or rewards on the client must be rewired to the server.

## 11. Testing

1. Device Simulator: phone (Entry level and Flagship), tablet, console, PC. Check safe area, overflow, tap size and the on-screen keyboard [A11].
2. Controller Emulator for console: every menu reachable and closable with a gamepad.
3. Network Simulator with latency: purchase buttons show a pending state and do not double-send.
4. Screenshot at 1920x1080, 1024x768 and 390x844 (design-workflow.md).
