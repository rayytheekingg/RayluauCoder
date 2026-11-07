# UI and Maps Reference Catalog (for Ray Luau Coder 2.1.0)

Collected 2026-11-06. Every link was opened or its license file read on that date unless marked [UNVERIFIED].

## Approved 2026-11-06 (used to build 2.1.0)

Core set: A1, A2, A3, A4, A5, A6, A10, A11, A12, D1, D2, D3, D8, D10, E1, E4, E5, E6, E7, E8, E12, F1, F2, F3.
Extras added by Emir: A7 (Upgraded UIShadow beta, documented as Studio-only), B1, B2, B3 (frameworks as options), C1, C2 (Figma tools), D9 (game-icons.net with credit line).
Not used: A8, A9, C3, D4, D5, D6, D7, D11, E2, E3, E9, E10, E11, F4 to F7, G1, G2. A8 and A9 appear only as "do not use" notes.

Legend: **R** = recommended core, **O** = optional, **S** = skip (tracked only).

## Corrections this research found in v2.0.0
- input-ui.md says StyleQuery is in Studio beta. It is fully released since 2026-05-11 (A2). Will be fixed in 2.1.0.
- Styling Transitions are released (A3); v2.0.0 does not mention them.

## A. Official Roblox UI features and docs

| ID | Reference | Link | What it gives the skill | Status / date | Pick |
|---|---|---|---|---|---|
| A1 | UI Styling full release: StyleSheet, StyleRule, StyleDerive, StyleLink, tokens, Style Editor | devforum.roblox.com/t/full-release-ui-styling-is-officially-released/4275082 | Theme tokens and reusable styles without per-element code | Released 2026-01-20 | R |
| A2 | StyleQuery full release: MinSize, MaxSize, AspectRatioRange, ViewportDisplaySize, PreferredInput, ReducedMotionEnabled, PreferredTextSize; multiple and nested pseudo-instances | devforum.roblox.com/t/full-release-stylequery-more-styling-features/4566519 | Responsive UI and reduced-motion support with no scripts | Announced 2026-04-09, released 2026-05-11 | R |
| A3 | Styling Transitions (tweens defined in StyleSheets, `StyleRule:SetPropertyTransitions`) | devforum.roblox.com/t/studio-beta-styling-transitions/4646870 | Hover and press animations without TweenService code | Beta 2026-05-21, released 2026-07-27 | R |
| A4 | Styling docs and Style Editor docs | create.roblox.com/docs/ui/styling, /docs/ui/styling/editor | Official syntax for selectors, tokens, rules | Current | R |
| A5 | Creator Hub UI guides (containers, frames, labels, buttons, position and size, list/flex, grid/table, size and appearance modifiers, animation, drag detectors) | create.roblox.com/docs/ui | Correct layout and modifier usage | Current | R |
| A6 | UIShadow API reference (BlurRadius, Color, Inset, Mode, Offset, ShowBehindParent, Spread, Transparency, ZIndex) | create.roblox.com/docs/reference/engine/classes/UIShadow | Native drop shadows for the chunky toy look | Released (launched early 2026 per A7) | R |
| A7 | Upgraded UIShadow Studio beta: text, inset, knockout and gradient shadows; keep under 100 shadows on screen | devforum.roblox.com/t/studio-beta-upgraded-uishadow-capabilities/4934553 | Text shadows and pressed-button insets | Studio beta 2026-10-14, cannot publish yet | O |
| A8 | UIBlur (Color, Enabled, Strength, Transparency) | Present in API definitions only; community request devforum.roblox.com/t/ui-blur-capability/4528915 | Frosted-glass panels | No announcement or docs found [UNVERIFIED] | S |
| A9 | ParticleEmitter2D | Present in API definitions only | Particles inside UI (reward bursts) | No announcement found [UNVERIFIED] | S |
| A10 | Path2D full release | devforum.roblox.com/t/path2d-full-release/3027288 | Curved lines and shapes in UI | Released (2024) | R |
| A11 | Device Simulator and Network Simulator | create.roblox.com/docs/studio/device-simulator | Test UI on phone, tablet, console, headset; touch and controller emulation | Out of beta week of 2026-10-12 per A12 (docs page still says beta) | R |
| A12 | Weekly Recap Oct 12 to 18, 2026 | devforum.roblox.com/t/weekly-recap-october-12-18-2026/4938638 | Source for A7, A11, E10 | 2026-10-16 | R |

## B. UI code frameworks (optional alternatives to plain Luau)

| ID | Reference | Link | License | Latest | Pick |
|---|---|---|---|---|---|
| B1 | Fusion | github.com/dphfox/Fusion | MIT | 0.3 (tagged v0.3-beta; year not shown) | O |
| B2 | Vide | github.com/centau/vide | MIT | 0.4.1, 2026-07-11 (pre-release) | O |
| B3 | React-lua | github.com/jsdotlua/react-lua | MIT (Roblox Corp) | v17.2.1 (year not shown) | O |

Plan if approved: the skill defaults to plain Luau UIKit + the Styling API (A1 to A3) and documents B1 to B3 as options, not requirements.

## C. Figma to Roblox tools (community)

| ID | Reference | Link | Cost | Date | Pick |
|---|---|---|---|---|---|
| C1 | UILint v2: lints Figma UI, exports, rebuilds as native Roblox UI | devforum.roblox.com/t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869 | Free tier, paid sync features | 2026-07-30 | O |
| C2 | Framewisp: Figma frame to native Roblox UI, tag-based interactivity | devforum.roblox.com/t/framewisp-%E2%80%94-turn-a-figma-frame-into-native-roblox-ui-in-one-click/4759239 | 7-day trial, then subscription | 2026-07-27 | O |
| C3 | Bloxig: Figma to Studio | bloxig.onrender.com | [UNVERIFIED] | [UNVERIFIED] | O |

## D. Free icons and fonts

| ID | Set | Link | License (read 2026-11-06) | Credit needed | Pick |
|---|---|---|---|---|---|
| D1 | Lucide | lucide.dev, github.com/lucide-icons/lucide | ISC | Keep the license notice; safest is a credits line in the game description | R |
| D2 | Tabler Icons | tabler.io/icons, github.com/tabler/tabler-icons | MIT | Same as D1 | R |
| D3 | Phosphor (regular, bold, fill, duotone weights fit the toy look) | phosphoricons.com, github.com/phosphor-icons/core | MIT | Same as D1 | R |
| D4 | Heroicons | heroicons.com | MIT | Same as D1 | O |
| D5 | Material Symbols | fonts.google.com/icons | Apache 2.0 | Keep license text with project files | O |
| D6 | Iconoir | iconoir.com | MIT | Same as D1 | O |
| D7 | Remix Icon | remixicon.com | Remix Icon License v1.0 (Jan 2026): commercial use in products allowed, no standalone icon resale | Not required | O |
| D8 | Kenney game assets (UI packs: buttons, panels, icons) | kenney.nl | CC0 (public domain) | Not required; do not use the Kenney logo | R |
| D9 | game-icons.net (about 4,178 game icons: swords, potions, loot) | game-icons.net | CC BY 3.0 | Required: credit each author | O |
| D10 | Builder Sans, Builder Extended, Builder Mono fonts | create.roblox.com/docs/resources/builder-font-license | Roblox Builder font license: allowed in experiences and their promos | Not required | R |
| D11 | BuilderIcons font (Roblox internal icon font found by the community) | devforum.roblox.com/t/robloxs-secret-buildericons-font-and-how-to-use-it/4620737 | Not covered by the Builder font license; undocumented path, icons may be removed | n/a | S |

Pipeline (applies to every approved set): SVG to white PNG at 64/128/256 px with padding, tint with `ImageColor3`, pack into an atlas with `ImageRectOffset` / `ImageRectSize`, upload through Asset Manager or Open Cloud, keep a CREDITS.md listing every set used.

## E. Studded maps, lighting, generation, performance

| ID | Reference | Link | What it gives the skill | Status / date | Pick |
|---|---|---|---|---|---|
| E1 | `Enum.SurfaceType.Studs` still exists | Roblox API definitions (luau-lsp globalTypes.d.luau, 2026-11-06) | Real stud surfaces on parts, no textures needed | Current | R |
| E2 | Stud layering method: base texture + classic stud Texture, matched StudsPerTileU/V | devforum.roblox.com/t/trendy-stud-texture/4876870 | Modern "trendy" stud look on any material | Community, 2026-09-17 | O |
| E3 | HD upscaled studs through MaterialService | devforum.roblox.com/t/hd-upscaled-studs-from-2008-2022-using-materialservice/1911578 | MaterialVariant stud materials | Community; asset license [UNVERIFIED] | O |
| E4 | Lighting and effects docs (Lighting, Atmosphere, Sky, Clouds, post effects) | create.roblox.com/docs/environment | Official property guidance for presets | Current | R |
| E5 | Future lighting tutorial | create.roblox.com/docs/tutorials/3D-art/enhancing-outdoor-environments-with-future-lighting | Outdoor lighting workflow | Current | R |
| E6 | Customize global lighting tutorial | create.roblox.com/docs/tutorials/curriculums/core/building/customize-global-lighting | Step-by-step mood setup | Current | R |
| E7 | ColorGradingEffect (TonemapperPreset: Default, Retro) | create.roblox.com/docs/reference/engine/classes/ColorGradingEffect | Tone mapping control for bright, punchy color | Current | R |
| E8 | Procedural Models: ProceduralModel + generator module (`Attributes`, `OnGenerate(params, targetContainer)`), runs at edit time and in game | create.roblox.com/docs/parts/procedural-models; beta post devforum 4592056 (2026-04-23) | Resizable stud platforms, stairs, obby pieces generated by code or AI | Docs carry no beta label; release status [UNVERIFIED] | R |
| E9 | Material Generator | create.roblox.com/docs/studio/material-generator | Custom stud or toy materials from prompts | Available to everyone | O |
| E10 | Texture Generation Quality Mode (4K PBR maps) | Recap A12 | Higher quality generated textures | Beta, week of 2026-10-12 | O |
| E11 | "Roblox Studio going agentic": Planning Mode, Mesh Generation, Procedural Models, Playtesting Agent | about.roblox.com/newsroom/2026/04/roblox-studio-going-agentic | AI build workflow options inside Studio | 2026-04-15; Playtesting Agent beta | O |
| E12 | Design for performance | create.roblox.com/docs/performance-optimization/design | Example budget under 1,000 draw calls and 1M triangles on a baseline device; reuse meshes; transparency 0 or 1 only; streaming; SLIM avatars | Current | R |

## F. Style reference games (study only, never copy assets)

Player counts are a June 2026 snapshot (rowatcher.com/news/the-most-popular-roblox-games-right-now-ranked-by-live-players). Recheck the front page before building.

| ID | Game | What to study | Pick |
|---|---|---|---|
| F1 | Adopt Me! | Friendly, rounded, high-contrast UI; shop and inventory flow | R |
| F2 | Pet Simulator 99 | Simulator HUD, egg/reward reveal screens, currency counters | R |
| F3 | +1 Speed Keyboard Escape | Bright candy-colored obby, readable path and hazards | R |
| F4 | RIVALS | Clean competitive HUD, minimal clutter | O |
| F5 | Dress To Impress | Polished menus and transitions | O |
| F6 | Sell Lemons / Kick a Lucky Block | Idle and RNG UI, big tappable buttons on mobile | O |
| F7 | DevForum thread on low-detail "studs" aesthetic games | devforum.roblox.com/t/looking-for-games-and-showcases-that-execute-the-low-detail-studs-aesthetic-pretty-well/120873 | O |

## G. Design guides (community)

| ID | Reference | Link | Pick |
|---|---|---|---|
| G1 | UI Design Guide (sketch, framework, emphasis, readability, one font family, color balance) | devforum.roblox.com/t/ui-design-guide/2975811 (2024) | O |
| G2 | roblox-vfx skill (ParticleEmitter, Beam, Trail, Highlight rules) | skillselion.com/skills/nonlooped/roblox-suite/roblox-vfx | O |

## Recommended core set

A1, A2, A3, A4, A5, A6, A10, A11, A12, D1, D2, D3, D8, D10, E1, E4, E5, E6, E7, E8, E12, F1, F2, F3.

Everything marked O is safe to add if you want it. Everything marked S stays out unless you say otherwise.
