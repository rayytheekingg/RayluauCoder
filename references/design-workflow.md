# Design Workflow: UI and Maps with Claude

How Claude designs and builds UI and maps without wasting turns. IDs point to research/ui-maps-reference-catalog.md.

## 1. The loop

1. **Spec** (no code): goal of the screen or zone, platform priority (mobile first), style direction (ui-style-guide.md), palette, list of elements and actions, what the server owns.
2. **Mockup**: an HTML or SVG mockup in chat or as an artifact, using the palette hex values. Approve or adjust here; changes are cheap.
3. **Build**: Luau from the templates (Theme, UIKit, MenuManager, StudMap, LightingPresets). If Studio is connected through MCP, build directly in the place; otherwise output the scripts with their paths.
4. **Screenshot**: 1920x1080, 1024x768 and 390x844 (phone portrait-ish), plus a console preset in the Device Simulator [A11].
5. **Critique**: list every visible flaw against checklists/ui-review.md or checklists/map-review.md: overflow, misalignment, low contrast, cramped spacing, unreadable text, wrong safe area.
6. **Fix and repeat**: at most 2 loops. Then report what is left instead of looping forever.

## 2. Reading the user's references

- Style reference games [F1 to F3]: study layout, hierarchy, color use and motion. Never copy art, logos, icons, or exact layouts.
- Screenshots the user attaches: extract tokens (colors, corner radii, stroke weights, font feel) into a Theme palette before building.
- Figma files: import with UILint or Framewisp [C1, C2], then clean up and wire logic through MenuManager and Remotes (ui-design.md section 10).

## 3. Studio MCP rules for design work

- Build UI into a fresh ScreenGui named after the feature; never edit unrelated GUIs.
- Wrap edits in a ChangeHistoryService recording so the user can undo.
- Use `execute_luau` for building instances, then save the generator code as a script in the place so the result is reproducible.
- Upload assets (icon atlases, textures) only after the user confirms; uploads are permanent and moderated.
- After building, run a playtest, take screenshots at the sizes above, and read the output log for errors before reporting.
- If MCP is not connected, say so and deliver scripts plus a short "how to run" note.

## 4. Assets and generation

- Icons: references/icons.md pipeline; one atlas per screen family.
- Materials: stud surfaces or your own stud textures for the studded look (map-building.md).
- 3D props: simple part builds or meshes you own; check style match against the palette.
- Procedural Models [E8] for parts that need to be resized often (platforms, bridges, stairs).
- Every generated or imported asset gets reviewed for style, scale (studs), anchoring and moderation risk before it ships.

## 5. Definition of done

A UI is done when it passes checklists/ui-review.md on phone, tablet, PC and console presets, every action goes through the server, and the contrast script passes. A map zone is done when it passes checklists/map-review.md and holds frame rate on the baseline device.
