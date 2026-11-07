# Map Review Checklist

Mark each item Pass, Fail or N/A. Severity for a Fail: **High** (players get stuck, killed unfairly, or the game lags), **Medium** (hard to read), **Low** (polish).

## Playability (High)
- [ ] The next platform or path is visible from the current one
- [ ] Every jump is possible with default WalkSpeed and JumpPower; tested in a playtest
- [ ] Checkpoints every 5 to 10 jumps in obbies; spawn areas safe in combat maps
- [ ] Kill parts use the hazard color everywhere and nowhere else; kill handling runs on the server
- [ ] No gaps players can fall through by accident (seams, thin walls)

## Readability (Medium)
- [ ] 60-30-10 color split; interactables are the most saturated things on screen
- [ ] Grayscale screenshot: platforms still stand out from what is behind them
- [ ] Hazards red or orange, safe and checkpoint green or blue, consistent across the game
- [ ] Each zone has its own small palette and at least one landmark
- [ ] Studs used consistently (Surface Studs or one stud texture, not a mix)

## Lighting (Medium)
- [ ] One preset per zone (lighting-presets.md); transitions tween over 2 to 4 seconds
- [ ] LightingStyle chosen in Studio (Soft or Realistic) by comparing both
- [ ] Bloom threshold high enough that only Neon parts and the sun glow
- [ ] Night and spooky zones still readable on a phone at low brightness

## Performance (High)
- [ ] Tested on a baseline low-end device (Device Simulator Entry level plus a real phone)
- [ ] StreamingEnabled on for maps bigger than one screen
- [ ] Repeated props reuse the same meshes and textures (packages), not copies with new IDs
- [ ] Decorative parts: Anchored, CanCollide, CanTouch and CanQuery off
- [ ] Transparency only 0 or 1 where possible
- [ ] Part count reasonable: big floor tiles, no thousands of 1-stud parts
- [ ] Post effects (Bloom, SunRays, Atmosphere) checked for frame cost on phone

## Assets (Medium)
- [ ] Every Creator Store model checked for hidden scripts and its license
- [ ] Generated meshes and textures match the palette and stud scale, reviewed before publishing
- [ ] Procedural Model generators write only into their container and use params:Pause() in long loops
