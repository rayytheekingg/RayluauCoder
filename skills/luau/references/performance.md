# Performance

Checked against Roblox's docs on 2026-11-05.

Sources: [improve performance](https://create.roblox.com/docs/performance-optimization/improve), [transparent batching](https://create.roblox.com/docs/scripting/transparent-batching), [assemblies](https://create.roblox.com/docs/physics/assemblies), [highlighting](https://create.roblox.com/docs/effects/highlighting)

Measure before optimizing unless the problem is obvious. Studio's own stats are skewed by Studio, so view frame rate on a real client.

## Profiling tools

- **MicroProfiler:** finds slow frames. Add labels with `debug.profilebegin("Name")` and `debug.profileend()`.
- **Developer Console (F9):** check `LuaHeap`, `InstanceCount`, `PlaceScriptMemory`, and network use.
- **Render Stats (Shift+F2):** check draw calls on the client.

## Scripts

- Keep work out of `RunService` handlers unless it must run every frame. Use a slower loop when possible.
- Split long jobs across frames with `task.wait()`.
- Move heavy computation that does not touch the DataModel to Actors and parallel Luau.
- Avoid repeated `GetDescendants`, `FindFirstChild` chains, and deep table clones in hot code.
- Cache services and frequently used instances in local variables.
- Use `CollectionService` tags instead of scanning `Workspace`.
- Use `table.create(n)` when an array's size is known.
- Try `--!native` only on hot, computation-heavy server scripts, then measure.
- Start repeated `MarketplaceService:UserOwnsGamePassAsync`, `MarketplaceService:GetProductInfoAsync`, and similar calls together with `task.spawn`. The engine batches concurrent calls into fewer requests, while serial loops get no benefit. Wrap each in `pcall`.

## Memory leaks

- A connection stays alive until it is disconnected, or its instance is destroyed. It keeps what it captures alive too.
- Use `Instance:Destroy()` instead of only setting `Parent = nil`.
- Players and characters are not always destroyed automatically after leaving. Enable `Workspace.PlayerCharacterDestroyBehavior` in Studio's Properties window, because scripts can't set it. Otherwise destroy them yourself.
- Remove player-keyed table entries on `PlayerRemoving`.
- Watch caches, lists, and queues that only grow.

## Networking

- Send only what changed, at the lowest rate that works.
- Keep payloads small. Avoid sending whole tables or inventories on every change.
- Use `UnreliableRemoteEvent` for continuous cosmetic data. Add timestamps or sequence numbers to ignore old messages.
- Do not replicate server tweens. Tell clients the target and tween locally.
- Run visual effects on the client.

## Physics

- Anchor static parts. To anchor an assembly, anchor only its root part, because anchoring every part creates more assemblies.
- Use constraints and assembly velocity properties, not the deprecated body movers. For an initial push, set `BasePart.AssemblyLinearVelocity` once. For constant speed, use `LinearVelocity`.
- Use Adaptive Timestepping unless you need fixed 240 Hz physics.
- Reduce joints, self-collision, and collision fidelity. Use `Box` or `Hull` where precision is not needed.
- Disable `CanTouch` and `CanQuery` on parts that do not need them.

## Humanoids and NPCs

- Avoid `Humanoid` on static NPCs.
- Disable unused humanoid states.
- Play NPC animations on the client where possible.
- Pool models that respawn often.

## Loading and rendering

- Enable instance streaming for large maps.
- Keep `ReplicatedFirst` and `ReplicatedStorage` lean.
- Preload only essential assets, and spread startup work across frames.
- Reuse meshes and textures. Reduce unnecessary parts, transparency, and shadows.
- Large, overlapping particles are costly on the GPU, and reusing textures saves memory.
- Only 255 `Highlight` slots exist, and disabled highlights still use one. Delete highlights you no longer need.

## Review checklist

- [ ] Per-frame handlers do only what must run per frame.
- [ ] No per-frame `GetDescendants`, deep clones, or remote fires without a limit.
- [ ] Long jobs yield or use parallel Luau.
- [ ] Connections are disconnected, or owned by destroyed instances.
- [ ] Temporary instances use `Destroy` or `Debris`.
- [ ] Player-keyed tables are cleared on leave.
- [ ] Remotes send small payloads, only on change or at a limited rate.
- [ ] Effects and cosmetic tweens run on clients.
- [ ] Static parts are anchored, with sensible collision settings.
- [ ] Large maps consider instance streaming.
