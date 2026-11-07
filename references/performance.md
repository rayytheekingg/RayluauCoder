# Performance Reference

Verified as of 2026-11-06. [REL] = github.com/luau-lang/luau/releases. [SQ] = devforum.roblox.com/t/new-spatial-query-filters/4563575. [SA] = devforum.roblox.com/t/full-release-ship-fair-and-competitive-games-with-server-authority/4727993. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. Measure first

| Tool | Answers |
|---|---|
| MicroProfiler (Ctrl+F6 in client, or the Studio menu) | Where frame time goes: scripts, physics, rendering, replication |
| Script Profiler (Developer Console or Studio) | Which Luau functions use the most CPU |
| Developer Console Memory tab | Which categories hold memory (LuauHeap, Instances, Sounds, Textures) |
| Developer Console Network tab | Remote and replication traffic per second |
| Studio network simulation | Latency and packet loss testing (expanded in 2026, devforum 4665487) |

`MicroProfilerService` and `ScriptProfilerService` exist as services [DEFS]. [UNVERIFIED this cycle: any 2026 UI changes to the profilers.]

Rule: do not optimize without a profile. Every performance change in a code review cites what the profiler showed or is marked "speculative, low priority".

## 2. Per-frame code

```lua
--!strict
-- Bad: allocates a new params object and table every frame.
RunService.PostSimulation:Connect(function()
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, direction, params)
end)

-- Good: build once, reuse.
local params = RaycastParams.new()
params.ExcludeInstances = { character }

RunService.PostSimulation:Connect(function()
	local result = workspace:Raycast(origin, direction, params)
end)
```

- Reuse `RaycastParams` and `OverlapParams`. Reassigning the same table to `ExcludeInstances` is cheap because Roblox caches it [SQ].
- Cache services and frequently used instances in locals at the top of the script.
- Avoid string building, `table.insert` into new tables, closures created per frame, and `:GetChildren()` / `:GetDescendants()` every frame.
- Preallocate with `table.create(n)` and reuse with `table.clear(t)`; both are fastcalls since Luau 0.745 [REL].
- Throttle work that does not need 60 Hz: run it every N frames or on `task.wait(interval)`.

## 3. Many objects

- One loop that updates a list beats one connection per object. 500 coins should share one PostSimulation connection, not 500.
- Use CollectionService tags to find objects instead of scanning Workspace.
- Pool frequently created and destroyed objects (projectiles, damage numbers): hide and reuse instead of `Instance.new` and `Destroy`.
- Anchor everything that does not need physics. Set `CanCollide`, `CanTouch` and `CanQuery` to false on decorative parts.
- `Touched` events on many parts are expensive and unreliable for hit detection; prefer spatial queries on a timer for gameplay.

## 4. Native code and Parallel Luau

- `--!native` / `@native` speed up pure Luau math, not Roblox API calls (luau-language.md section 7).
- Luau 0.745 auto-promotes hot functions to native in the OSS runtime [REL]; Roblox rollout [UNVERIFIED].
- Parallel Luau (Actors) helps when many independent computations run every frame (engine-runtime.md section 5).

## 5. Memory leaks

Most Roblox memory leaks are connections that outlive their purpose:
- Connections to `Players`, `RunService`, or another long-lived object made per player or per character and never disconnected.
- Tables keyed by `Player` that are never cleared on `PlayerRemoving`.
- Instances parented to nil but still referenced from a table.

Fix: every per-player or per-character system owns a Cleaner (templates/Cleaner.luau) destroyed on `PlayerRemoving` or `CharacterRemoving`. Every table keyed by Player gets `[player] = nil` on `PlayerRemoving`.

## 6. Replication cost

- Every property change on a replicated instance is network traffic. Changing a part's CFrame every frame from the server replicates every frame.
- Visual-only motion (spinning coins, bobbing pickups, UI effects) runs on the client.
- Server Authority increases compute on both server and client [SA]; profile after enabling it.
- `ClientAnimatorThrottling` is always on since 2026-04-29 (weekly recap 4568634): distant characters animate at reduced rate; do not tie gameplay to client animation timing.

## 7. Streaming and content

- StreamingEnabled reduces client memory and join time on large maps (engine-runtime.md section 6).
- Reuse meshes and textures by asset ID; each unique texture costs memory.
- `ContentProvider:PreloadAsync` only the assets needed for the first screen; `Preload` is deprecated [DEFS].
