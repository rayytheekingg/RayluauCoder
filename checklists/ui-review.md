# UI Review Checklist

Mark each item Pass, Fail or N/A. Severity for a Fail: **Critical** (money or rewards decided on the client), **High** (unusable on a device), **Medium** (hard to read or use), **Low** (polish).

## Server authority (Critical)
- [ ] No price, reward, currency or item change happens in UI code; buttons send requests through Remotes
- [ ] Purchase buttons show a pending state and cannot double-send
- [ ] Developer products use MarketplaceService prompts; granting stays in ProcessReceipt

## Devices (High)
- [ ] Checked in Device Simulator: Entry level phone, Flagship phone, tablet, PC, console
- [ ] Screenshots at 1920x1080, 1024x768 and 390x844 show no overflow, clipping or overlap
- [ ] `ScreenInsets = CoreUISafeInsets` on HUD and menus; nothing under the notch or top bar
- [ ] Touch targets at least 44 px on the smallest phone
- [ ] Every menu opens, works and closes with a gamepad (Controller Emulator); first button selected on open
- [ ] Back works with Escape and ButtonB; every menu also has a visible close button
- [ ] On-screen keyboard does not cover a focused text field on phones
- [ ] Bottom-left stays clear for the mobile thumbstick; action buttons bottom-right

## Readability (Medium)
- [ ] All colors come from Theme tokens; no hardcoded Color3 in components
- [ ] tools/check_contrast.py passes for the palette in use
- [ ] Text never below about 14 px on the smallest phone; UITextSizeConstraint on scaled text
- [ ] Meaning is never carried by color alone (icon or label too)
- [ ] One primary action per screen; secondary actions visually quieter
- [ ] Icons from one or two sets per screen, same weight; icon-only buttons have a label or tooltip

## Feel (Low)
- [ ] Hover and press feedback on every button (mouse and gamepad selection)
- [ ] Open animation 0.25 s or less; close faster than open; reduced-motion respected
- [ ] Changing numbers tick up instead of jumping
- [ ] Click sound short and quiet; no sound spam on rapid clicks

## Structure and performance (Medium)
- [ ] Three ScreenGuis or fewer (HUD, Menus, Popups); `ResetOnSpawn = false`
- [ ] MenuManager controls menus: one open at a time, back stack works
- [ ] No per-frame UI updates; updates happen on change events
- [ ] Closed menus use `Visible = false`, not off-screen positions
- [ ] Under 100 UIShadows visible at once; CanvasGroup only where needed
- [ ] Icons come from an atlas; CREDITS lists every icon set used (game-icons.net authors named)

## Styling (Low)
- [ ] Same corner radius family and stroke weight everywhere
- [ ] Studded panels: stud tile subtle (transparency about 0.9), text still readable over it
- [ ] Beta-only features (Upgraded UIShadow text/inset modes) are not used in a published game
