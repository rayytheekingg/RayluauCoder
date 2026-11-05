# Roblox services and runtime

Sources: [client-server model](https://create.roblox.com/docs/projects/client-server), [task library](https://create.roblox.com/docs/reference/engine/libraries/task), [remote events](https://create.roblox.com/docs/scripting/events/remote), [engine reference](https://create.roblox.com/docs/reference/engine)

Verify exact members with `api-lookup`.

## Client and server

- The server is the authority. Each client has a partial copy of the world.
- Server changes to `Workspace` and `ReplicatedStorage` replicate to clients.
- Client changes normally stay on that client, except physics on parts the client owns and a few character behaviours.
- `ServerScriptService` and `ServerStorage` do not replicate to clients.
- `Players.LocalPlayer` is `nil` on the server.
- Instances visible to only one side arrive as `nil` when passed through a remote.

## Common services

| Service | Use |
| --- | --- |
| `Players` | Player join and leave, `GetPlayers`, `LocalPlayer` |
| `ReplicatedStorage` | Shared modules, remotes, assets |
| `ServerScriptService` | Server scripts and modules |
| `ServerStorage` | Server-only assets |
| `RunService` | Frame events, `IsServer`, `IsClient`, `IsStudio` |
| `UserInputService` | Keyboard, mouse, touch, and gamepad input |
| `ContextActionService` | Bind actions to input |
| `TweenService` | Animate properties, preferably on the client |
| `CollectionService` | Tag instances and react to tagged instances |
| `DataStoreService` | Persistent data |
| `MemoryStoreService` | Temporary cross-server data |
| `MessagingService` | Cross-server messages |
| `MarketplaceService` | Purchases and `ProcessReceipt` |
| `TeleportService` | Moving players between places |
| `PathfindingService` | NPC paths |
| `HttpService` | JSON and web requests from the server |
| `SoundService` | Sound settings and groups |
| `Debris` | Delayed cleanup |

## Remote types

| Type | Use | Notes |
| --- | --- | --- |
| `RemoteEvent` | Reliable one-way messages | Ordered. Queued if no handler is connected yet, up to a limit |
| `UnreliableRemoteEvent` | Frequent non-critical updates | May drop or reorder. Payloads over 1,000 bytes may drop. Not queued without a handler |
| `RemoteFunction` | Client asks the server and needs an answer | The caller yields. Never use `InvokeClient` from the server |
| `BindableEvent` | Same-side messages | Copies tables, like remotes |

Clients cannot message each other directly. Relay through the server and validate.

## Task library

| Function | Behaviour |
| --- | --- |
| `task.spawn(fn, ...)` | Runs now, until its first yield |
| `task.defer(fn, ...)` | Runs at the end of the current resumption cycle |
| `task.delay(seconds, fn, ...)` | Runs on the first Heartbeat after the delay |
| `task.wait(seconds)` | Yields, then returns the actual elapsed time |
| `task.cancel(thread)` | Stops a thread. Do not cancel the running thread |
| `task.desynchronize()` | Moves an Actor script to the parallel phase |
| `task.synchronize()` | Moves an Actor script to the serial phase |

## Frame events

| Event | Side | Use |
| --- | --- | --- |
| `RunService.PreRender` | Client | Camera and visuals |
| `RunService.PreAnimation` | Both | Change animations before they run |
| `RunService.PreSimulation` | Both | Change physics inputs |
| `RunService.PostSimulation` | Both | Read physics results |
| `RunService.Heartbeat` | Both | General per-frame logic, same timing as `PostSimulation` |

Handlers receive the elapsed time. Use it instead of assuming a frame rate.

## Player lifecycle

```lua
local function onPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		humanoid.Died:Once(function()
			print(`{player.Name} died`)
		end)
	end)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
```

`Once` disconnects itself after one call. `StarterCharacterScripts` run again on each respawn. `StarterPlayerScripts` run once per session.

## Instance streaming

With `Workspace.StreamingEnabled`, clients may not have distant parts.

- Use `WaitForChild` or `CollectionService` signals for instances that may stream in.
- Do not assume a part in `Workspace` exists on the client.
- A part reference can become invalid when it streams out.
- Mark important models as `Persistent` through `ModelStreamingMode` when they must always exist.

## Rojo

- A project file needs `name` and `tree`.
- Instance entries use `$className`, `$path`, `$properties`, and `$ignoreUnknownInstances`. Any other key is a child instance.
- Details: [Rojo project format](https://rojo.space/docs/v7/project-format/)

Run `rojo serve`, then connect from the Rojo plugin in Studio. `rojo build -o game.rbxlx` creates a place file.
