# Roblox services and runtime

Checked against Roblox's docs on 2026-11-05.

Sources: [client-server model](https://create.roblox.com/docs/projects/client-server), [task library](https://create.roblox.com/docs/reference/engine/libraries/task), [remote events](https://create.roblox.com/docs/scripting/events/remote), [deferred events](https://create.roblox.com/docs/scripting/events/deferred), [Parallel Luau](https://create.roblox.com/docs/scripting/multithreading), [Input Action System](https://create.roblox.com/docs/input/input-action-system), [users](https://create.roblox.com/docs/players/users), [engine reference](https://create.roblox.com/docs/reference/engine)

Verify exact members with `api-lookup`. Many older methods now have `Async` replacements, such as `Player:LoadCharacterAsync`, `BadgeService:AwardBadgeAsync`, and `Player:IsInGroupAsync`, so don't copy names from old tutorials.

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
| `TextService` | Filtering text, and measuring it. See `security-and-data.md` |
| `TextChatService` | In-game chat, channels, and chat commands. Chat is filtered for you |
| `PolicyService` | Per-player rules, such as whether paid random items are allowed |
| `BadgeService` | Awarding and checking badges |
| `PhysicsService` | Collision groups. Register them in one script, to avoid race conditions |
| `ContentProvider` | Preloading assets with `ContentProvider:PreloadAsync` |
| `GuiService` | Menus, selection, and screen insets |
| `LocalizationService` | Translating text |
| `SocialService` | Friend invites and calendar events |
| `GroupService` | Roblox group information |
| `AssetService` | Runtime assets, and listing the places in an experience |
| `LogService`, `ScriptContext` | Reading Output, and catching script errors for your own logging |
| `AnalyticsService` | Custom, economy, and funnel analytics events |

## Events run deferred in new places

New place templates set `Workspace.SignalBehavior` to `Deferred`. Set it in Studio's Properties window. `Default` currently acts like `Immediate`, but will change.

- Handlers queue and run at the next resumption point, not during the fire. Code that fires an event and checks a flag on the next line sees the old value.
- Scripts can see stable state between resumption points.
- `Disconnect` drops pending handler calls. `Destroy` disconnects, but pending handlers still run, and the instance may already be gone inside them.
- Use `RBXScriptSignal:Once` for first-occurrence listeners, instead of disconnecting inside the handler.
- Events that keep firing each other stop at a depth of 10.
- `BindableEvent` handlers run in an unpredictable order. If order matters, use one handler.

## Player identity

- `Player.UserId` and `Player.User.Id` always match, so existing data keys keep working. `Player.User` is recommended in new code.
- Scoped user IDs haven't rolled out broadly. After they do, the same number can mean different people in different experiences, so never use a bare ID to identify someone across experiences. Save `User:ToString()` for that.

## Input

| Option | Use when |
| --- | --- |
| Input Action System | New games. Define actions and map them to keyboard, gamepad, and touch, and switch sets of actions by context |
| `UserInputService` | Reading raw input, device type, and mouse position |
| `ContextActionService` | Existing code that binds actions at runtime |

- `InputContext` groups actions. Set `Priority` and `Sink` to block lower contexts, such as gameplay input while a menu is open.
- `InputAction` has a `Type`. `Pressed` and `Released` fire only for `Bool` actions. `StateChanged` fires for all types.
- `InputBinding` maps a key with `KeyCode`, or a touch button with `UIButton`.
- Give each action bindings for all devices. Reserved keys, such as Esc and F9, can't be overridden.

## Parallel Luau

- Scripts must be under an `Actor`. Scripts in one Actor run in order, so use several Actors for real parallelism. Don't nest them.
- Use `RBXScriptSignal:ConnectParallel`, or `task.desynchronize`, to enter the parallel phase. Use `task.synchronize` before changing instances.
- `require` doesn't work in a parallel phase. Require modules first.
- Check each API's thread safety with `api-lookup`, and on its reference page. The default is Unsafe.
- Use `SharedTable` to share data between Actors. Send messages with `Actor:SendMessage`, and receive with `Actor:BindToMessage` or `Actor:BindToMessageParallel`.
- Keep setup and state changes serial. Only heavy computation needs to be parallel.

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
- Client raycasts can't hit parts that aren't streamed in, or the low-detail stand-ins for distant models.
- Set `Model.ModelStreamingMode` to `Persistent` only in rare cases. Overuse hurts performance. Prefer server scripts, or client scripts that tolerate parts coming and going.
- Keep `Workspace.StreamingTargetRadius` larger than `Workspace.StreamingMinRadius`, so there's a buffer.

## Rojo

- A project file needs `name` and `tree`.
- Instance entries use `$className`, `$path`, `$properties`, and `$ignoreUnknownInstances`. Any other key is a child instance.
- Details: [Rojo project format](https://rojo.space/docs/v7/project-format/)

Run `rojo serve`, then connect from the Rojo plugin in Studio. `rojo build -o game.rbxlx` creates a place file.
