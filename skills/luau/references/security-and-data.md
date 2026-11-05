# Security and data

Checked against Roblox's docs on 2026-11-05.

Sources: [security tactics](https://create.roblox.com/docs/scripting/security/security-tactics), [client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary), [defensive design](https://create.roblox.com/docs/scripting/security/defensive-design), [server-side detection](https://create.roblox.com/docs/scripting/security/server-side-detection), [network ownership](https://create.roblox.com/docs/scripting/security/network-ownership), [data store best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices), [data store limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits), [player data and purchasing](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing), [text filtering](https://create.roblox.com/docs/ui/text-filtering), [developer products](https://create.roblox.com/docs/production/monetization/developer-products), [paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items)

## What exploiters can do

- Read and decompile client scripts and anything in `ReplicatedStorage`.
- Fire any remote, with any arguments, as often as the network allows.
- Change anything local, including GUIs, local scripts, and their own `Humanoid.WalkSpeed`, without any event firing.
- Fully control physics for parts they own, including their character: teleport, fly, pass through walls, or set extreme, `NaN`, or infinite velocities that can fling other parts.
- Decide whether `Touched` fires for parts they own.

For each feature, ask:

1. What is the worst result of any value a client could send?
2. What happens at 1,000 calls per second?
3. What server state does this expose that clients do not need?
4. Can the design make the abuse impossible or worthless? Prevention beats detection.

## Design out the cheat first

- Calculate damage on the server from server-side weapon stats.
- Give sequential objectives, such as obby stages, server-checked checkpoints in order.
- Reduce the payoff for abuse, such as fewer points for kills on newly spawned players.
- Add server cooldowns, and check each trade or purchase against the player's current inventory.

## Remote validation

Use `templates/code/ServerRemote.server.luau` as a starting point. Validate in this order:

1. **Rate limit:** per player, per remote, on the server. Drop excess calls silently. Clear limiter state on `PlayerRemoving`.
2. **Types:** use `typeof(value)`. The first server parameter is always the real sender.
3. **Numbers:** use `math.isfinite(value)`, which rejects `NaN` and both infinities. `NaN` passes `typeof` checks and fails every comparison. Then check range, and whether it must be a whole number above zero.
4. **Strings:** limit length, and compare with an allow list. For text you store, reject invalid UTF-8 with `utf8.len(text)`, which returns nil for it.
5. **Instances:** a table can be sent in place of an Instance, so check `typeof(value) == "Instance"`. Then check its class and `value:IsDescendantOf(expectedParent)`. Never accept arbitrary paths or instances to delete or change.
6. **Tables:** limit size, and check every key and value. Prefer simple arguments.
7. **Game rules:** ownership, cooldown, distance, alive state, and round state.
8. **Act:** change server state, then tell clients.

Don't load assets or call `require` based on remote arguments.

Remote transfer rules:

- Tables are copied, so identity and metatables are lost.
- Non-string keys such as Instances become strings. Avoid mixed number and string keys, and `nil` values.
- Functions arrive as `nil`.
- `RemoteEvent` and `RemoteFunction` order relative to each other isn't guaranteed. Use one remote type or your own sequence numbers when order matters.

## Client-triggered instances

These fire from the client, so they need the same checks as remotes:

| Instance | What the server can't rely on |
| --- | --- |
| `ProximityPrompt` | It can fire while `Enabled` is false on the server. Clients can change `Enabled`, `MaxActivationDistance`, and `RequiresLineOfSight`. Hold time isn't enforced. Only `Triggered` has a server distance check |
| `ClickDetector` | Events have no server checks, and can fire at any distance or while disabled |
| `DragDetector` | Inherited click events are unchecked. Dragging respects `Enabled` and `PermissionPolicy` only |
| `Touched` | Clients decide it for parts they own |

Check enabled state, player state, distance, rate, and minimum interaction time on the server. Use anchored parts or manual network ownership for critical actions.

Relaying between clients? The server must validate before `FireAllClients` or `FireClient`, not just pass data along.

## Combat

- Check that the shot origin is near the character, with a latency allowance.
- Check that the hit position is close to the reported part.
- Raycast for static obstructions between origin and target.
- Track fire rate, ammo, team, target alive state, and blocking states such as reloading.

## Movement

- Automatic ownership gives clients nearby unanchored parts. Use `BasePart:SetNetworkOwner` for critical ones.
- No single movement check suits every game. Simple distance-over-time checks can suit shooters but fail with vehicles or flight.
- Allow for latency, and average positions over time. Basic checks can flag players with bad connections.
- Use an accumulator that drains over time to allow bursts but catch sustained speed. Check only XZ for ground movement. Exempt your own teleports.
- [Server authority](https://create.roblox.com/docs/projects/server-authority), in beta, is the most reliable fix for competitive games. See `systems.md`.

## Detection and consequences

Validation and rate limits come first. Detection only supplements them.

- Decide on the server. Never ban from client-side detection.
- Neutralize first, such as moving a speed hacker back to the last valid position.
- Treat signals as hints: impossible completion times, resource gain above the legitimate maximum, and robotically even timing.
- Keep a suspicion score. Act only after several different signals.
- A remote no client script uses can act as a honeypot. Firing one is a high-confidence signal.
- Escalate: silent logging, quiet mitigation, temporary restrictions, then kicks and bans. Delay visible consequences, so exploiters can't learn what triggered them.
- Use `Players:BanAsync` for persistent offenders. Prefer reversible actions when confidence is low, because a skilled player can look like a cheater.

## Text filtering

This is a platform requirement. Roblox can remove a game that skips it. Use `templates/code/FilterText.luau`.

- Filter on the server, after the player submits, not as they type.
- Filter text you don't fully control: player input, generated words, web content, and stored text such as pet names.
- Use `TextService:FilterStringAsync`. Then use `TextFilterResult:GetNonChatStringForBroadcastAsync` for everyone, or `TextFilterResult:GetNonChatStringForUserAsync` for one player.
- Wrap each call in `pcall`. If filtering fails, show nothing.
- Chat through `TextChatService` is filtered automatically.

## DataStore rules

Use `templates/code/PlayerData.luau` as a starting point. Roblox's own sample is for reference only and warns against shipping it as-is.

Limits:

| Limit | Value |
| --- | --- |
| Store name, key, or scope | 50 characters |
| Value per key | 4 MB, serialized |
| Metadata | Key 50 and value 250 characters, 300 total |
| Per-key throughput | Read 25 MB and write 4 MB per minute |
| Budget per server, per minute | Read, write, and remove: 60 + players x 40. List: 5 + players x 2 |
| Budget per experience, per minute | Read: 300 + players x 40. Write: 300 + players x 20 |
| Request queues | 4 queues, 30 requests each |

`UpdateAsync` uses both the read and write budgets.

Rules:

- Call DataStores from server scripts only. Use a small, fixed set of stores with one key per player. For new games, use prefixes and listing instead of scopes.
- Values must be serializable: no Instances, functions, mixed-key tables, `NaN` or nil indexes, or invalid UTF-8. Cap player-controlled strings and tables, so they can't grow without limit.
- Keep a session copy on the server, and save on an interval with random offsets, on `PlayerRemoving`, at `DataModel:BindToClose`, and after purchases.
- Wrap every call in `pcall`. Retry temporary failures with capped backoff and jitter. See `debugging.md` for which error codes not to retry.
- Keep operations for one key in order, because a late retry can overwrite newer data.
- A failed call may still have written. The result is sometimes unknown.
- Prefer `UpdateAsync` when writes depend on current data. Its callback must not yield, and it may run more than once. Return `nil` to cancel.
- `GetAsync` can return a value up to 4 seconds old from a local cache. For a verification read, pass `DataStoreGetOptions` with `UseCache` set to false.
- When writing a key with metadata, always pass the metadata again, or it is lost.
- If a load fails, mark the session as failed, and never save it over real data.
- Show players when loading or saving failed, and wait for data to load before allowing purchases.
- Use versions for schema changes, and fill in missing fields at load.
- Use `MemoryStoreService` for temporary data.
- You must delete a user's personal data for right-to-be-forgotten requests. Roblox sends a daily message, and you're responsible even with automation set up. See [RTBF](https://create.roblox.com/docs/cloud-services/data-stores/right-to-be-forgotten).
- Use session locks for trading and duplication-sensitive data. Roblox stores the lock ID in the key's metadata, written in the same `UpdateAsync` that reads the data. ProfileStore handles this.

Studio needs a published place and "Enable Studio Access to API Services". Use a separate store name for testing, because Studio can write to real data.

## Purchases

Use `templates/code/ProductReceipts.luau`.

- Set `MarketplaceService.ProcessReceipt` in one server script only.
- A purchase counts as handled only when it hasn't been handled before, it's applied to the session, and it's saved.
- Store each `PurchaseId` with the player's data, because Roblox can send the same receipt again.
- Wait for the player's data to load. Stop waiting if they leave.
- Return `PurchaseGranted` only after the save succeeds. Otherwise return `NotProcessedYet`, and Roblox retries when the player next joins.
- Never grant items because of `PromptProductPurchaseFinished`, which can be spoofed.
- Check passes on the server with `MarketplaceService:UserOwnsGamePassAsync`.

### Paid random items

If Robux, or anything bought with Robux, can get a random reward:

- Block the feature with `PolicyService:GetPolicyInfoForPlayerAsync` for players where `ArePaidRandomItemsRestricted` is true.
- Show the odds before the player spends, including when they spend in-game keys or tokens bought with Robux.

## Secrets

- Keep API keys in [Secrets stores](https://create.roblox.com/docs/cloud-services/secrets) or server-only code, never in `ReplicatedStorage` or client scripts.
- Do not print secrets or player data to Output.
- Review third-party models and plugins. See `companions.md` for trust rules.

## Review checklist

- [ ] Every remote handler has a server-side rate limit.
- [ ] Every remote argument is type-checked and range-checked.
- [ ] Numbers use `math.isfinite`, and Instances are checked for class and location.
- [ ] The client never sends a price, reward, damage value, or another player's new state.
- [ ] Purchases check server-side price, funds, ownership, and distance.
- [ ] `ProximityPrompt`, `ClickDetector`, and `Touched` handlers repeat their checks on the server.
- [ ] Relayed messages are validated before they reach other clients.
- [ ] `InvokeClient` is not used.
- [ ] Server-only logic and secrets are not in `ReplicatedStorage`.
- [ ] Displayed text from players or outside sources is filtered on the server.
- [ ] Every DataStore call uses `pcall`, with retries only for temporary errors.
- [ ] A failed load cannot overwrite real data.
- [ ] Data saves at interval, on leave, at shutdown, and after purchases.
- [ ] `ProcessReceipt` is idempotent, and returns the correct decision.
- [ ] Paid random items check `PolicyService` and show odds.
- [ ] Rate-limit and session tables are cleared on `PlayerRemoving`.
