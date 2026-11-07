# Map Building Reference: Vibrant Studded Worlds

Verified as of 2026-11-06. IDs point to research/ui-maps-reference-catalog.md. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. Getting the stud look

| Method | How | Pros | Cons | Source |
|---|---|---|---|---|
| Surface type | `part.TopSurface = Enum.SurfaceType.Studs` (and `BottomSurface = Inlet` for classic bricks) | Free, no uploads, exact classic look | Only on simple parts; [UNVERIFIED] which materials render surfaces (test Plastic and SmoothPlastic) | [E1], [DEFS] |
| Texture layering | `Texture` on a face with your own stud image, `StudsPerTileU/V` matched to the stud size, transparency tuned over a base material | Works on any material, tweakable | Needs a stud image asset you made or own; one Texture per face | [DEFS] |
| MaterialVariant | Material Manager: a variant of Plastic with your own stud color and normal maps; assign via `part.MaterialVariant` | One setting per part, works with lighting | Needs texture maps you made or own | [DEFS] |

Default for this skill: Surface type Studs on floors and platforms (cheapest, most "Roblox"), Texture layering when a part needs a non-plastic material underneath.

## 2. Color for bright worlds

- **60-30-10**: 60 percent calm base (grass, floor, sky tint), 30 percent supporting color (paths, buildings), 10 percent loud accent (interactables, rewards).
- **Saturation hierarchy**: interactive things are the most saturated and brightest. Scenery is one step less saturated. Background is least saturated. Players read "bright = touch it".
- **Hazards**: red or orange with a consistent material (Neon or glowing) everywhere. Never use the hazard color for decoration.
- **Safe and checkpoint**: green or blue, consistent across the whole game.
- **Value contrast**: a platform must differ from what is behind it in brightness, not only hue. Check by viewing a screenshot in grayscale.
- **Palette per world**: pick 5 to 7 colors per zone and stick to them. The UI palettes in templates/palettes.json can seed map palettes (Studded Classic: blue, green, yellow, red on a neutral base).

## 3. Level design by genre

**Obby / tower**
- One readable path. The next jump is always visible from the current platform.
- Difficulty rises slowly, with a rest platform after every hard section.
- Checkpoints every 5 to 10 jumps, color-coded and tagged `Checkpoint`.
- Kill parts tagged `KillBrick`, one consistent hazard color.
- Landmarks (a big colored tower, a floating island) so players know where they are.

**Simulator / tycoon**
- Spawn hub with the shop, rebirth and pets visible within a few seconds of walking.
- Zones unlock outward; each zone gets its own palette so progress is visible.
- Collectibles brighter than the ground; spawn them on a grid away from walls.

**Sword fighting / arena**
- Symmetric or fair layouts, cover at regular spacing, no unreachable high ground.
- Lighting even across the arena so no side has a visibility advantage.
- Spawn areas protected and visually distinct.

## 4. Building with code

Use templates/StudMap.luau for repeatable pieces: stud floors, platforms, and a seeded obby section generator that tags checkpoints and kill bricks. Run it from the command bar, from the Studio MCP server, or once at server start.

Procedural Models [E8]: a `ProceduralModel` points its `Generator` property at a ModuleScript that returns `Attributes` (defaults) and `OnGenerate(params, targetContainer)`. Changing the model's Size or attributes regenerates it, at edit time and in game. Good for resizable stud platforms, stairs, fences and bridges.

```lua
--!strict
-- Generator module for a ProceduralModel: a stud platform that follows the model's Size.
local Generator = {}

Generator.Attributes = {
	Color = Color3.fromHex("1E63D6"),
}

function Generator.OnGenerate(params: any, targetContainer: Instance)
	-- any: params comes from the engine; fields Attributes and Size per the Procedural Models docs
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = params.Size
	part.Color = params.Attributes.Color
	part.TopSurface = Enum.SurfaceType.Studs
	part.Parent = targetContainer
end

return Generator
```

Rules from the docs: build around the origin, write only into `targetContainer`, call `params:Pause()` inside long loops to avoid script timeouts, and do not generate inside Actors. Release status is [UNVERIFIED] (the docs carry no beta label; the April 2026 announcement was a Studio beta). Confirm in Studio Beta Features before relying on it in a live game.


## 5. Performance budgets [E12]

- Pick a baseline device (an Entry level phone in the Device Simulator plus a real low-end phone) and test on it throughout.
- One developer's example budget: under 1,000 draw calls and under 1,000,000 triangles on the baseline device. Treat as a starting point, not a rule.
- Reuse the same parts, meshes and textures. Duplicated assets with different IDs cost more; convert repeated props into packages.
- Built-in materials cost much less memory than custom textures.
- Transparency only 0 or 1 where possible; partial transparency causes overdraw.
- StreamingEnabled on for any map bigger than one screen (required for Server Authority anyway).
- Busy social spaces: `Workspace.EnableSLIMAvatars` and SLIM level of detail on world models [E12].
- Decorative parts: `CanCollide = false`, `CanTouch = false`, `CanQuery = false`, `Anchored = true`.
- Avoid Unions for repeated props; use meshes or simple parts.
- Studio's emulator is accurate for aspect ratio and controls but not memory; check memory on a real device [E12].

## 6. Map review loop

1. Block out with gray parts; playtest the path.
2. Apply the palette (60-30-10), then studs, then lighting (lighting-presets.md).
3. Screenshot from spawn, mid-level and an overview; view in grayscale to check value contrast.
4. Run checklists/map-review.md.
5. Profile on the baseline device; cut parts or effects until it holds frame rate.
