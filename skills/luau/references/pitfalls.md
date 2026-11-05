# Common pitfalls

Use this when code runs without an obvious error but behaves incorrectly. Check claims about an API with `api-lookup` and the official docs.

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| A value changes on your screen but not for others | The change was made on the client | Ask the server through a validated remote |
| A currency exploit works | The client sends the price or amount | Send only an item ID. Look up the price on the server |
| A LocalScript never runs | It is in a location that does not run client scripts | Move it to `StarterPlayerScripts`, `StarterCharacterScripts`, or `StarterGui` |
| A Script does not run | It is disabled, or in `ReplicatedStorage` or `ServerStorage` | Move it to `ServerScriptService` |
| The first player gets no setup in Studio | They joined before `PlayerAdded` connected | Also loop over `Players:GetPlayers()` |
| Character setup stops after respawn | Code ran once on the old character | Use `CharacterAdded` |
| `player.Character` is `nil` | The character has not spawned, or has been removed | Use `player.Character or player.CharacterAdded:Wait()`, or handle `nil` |
| A client script finds no instance that exists in Studio | It has not replicated or streamed in yet | Use `WaitForChild`, and handle streaming |
| A remote receives shifted arguments | `OnServerEvent` gets `player` first | Declare `function(player, ...)` |
| A remote sends a table without its data or methods | Remotes copy tables, drop metatables, and change some keys | Send plain data with string keys or an array |
| `FireClient` never reaches the client | No handler yet, or it was dropped after the queue limit | Connect early. Let the client request the current state when ready |
| The server freezes on a client request | It uses `InvokeClient`, or a handler yields forever | Use RemoteEvents, and add timeouts |
| Data is reset to defaults | A failed load created defaults, which were saved later | Keep load failures from saving. See `templates/code/PlayerData.luau` |
| Data is lost on shutdown | No `BindToClose` wait | Wait for all saves in `BindToClose` |
| Items are duplicated by teleports or rejoining | A second server loaded before the first save finished | Add session locks |
| Memory rises slowly | Connections or player tables are not cleaned up | Disconnect them, and clear entries on leave |
| Everything slows over time | Leaked loops or parts | Check `InstanceCount` and running loops. Stop each loop with its owner |
| A loop stops running forever | An error ended the thread | Wrap each iteration in `pcall`, and log errors |
| `a and b or c` gives the wrong value | `b` was `false` or `nil` | Use `if a then b else c` |
| An array has the wrong length | `nil` holes affect `#` | Use `table.remove`, or keep a separate count |
| Items are skipped while removing | The list shifted during a forward loop | Iterate backward |
| A `.Touched` handler fires repeatedly | The event fires for each part and contact | Add a debounce, and find the player from the hit part |
| Parts fall through or jitter | Unanchored parts, or a network owner change | Anchor static parts. Set ownership deliberately with `SetNetworkOwner` |
| A tween appears choppy for players | It runs on the server | Run the tween on the client |
| Attribute or value changes miss the first value | The listener connected late | Read the current value, then connect the change listener |
| A `Humanoid.Died` handler never fires | Humanoid was replaced, or its health never reached 0 | Reconnect on `CharacterAdded`, and use the current humanoid |
| Random values repeat as a pattern | `Random.new` was called with the same seed | Create one `Random` and reuse it, with no fixed seed |
| Comparing floats fails | Rounding error | Compare with a small tolerance |
| Time differs between clients | Client clocks vary | Use `workspace:GetServerTimeNow()` |
| Code uses a removed API from an old tutorial | The tutorial is outdated | Run `api-lookup` and use the listed replacement |
