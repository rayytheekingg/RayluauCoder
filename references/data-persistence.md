# Data Persistence Reference

Verified as of 2026-11-06. [UNI] = devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240 (2026-07-29). [REC] = devforum.roblox.com/t/weekly-recap-april-6-10-2026/4568634. [EXT] = devforum.roblox.com/t/extended-services-for-data-stores-is-now-available/4504347. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06). [ERR] = create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits.

## 1. Limits in 2026

| Limit | Value | Since | Source |
|---|---|---|---|
| Request budget | Per experience, per request type, per minute: `base + CCU x multiplier`, base 300 | access limits rolled out 2026-04-09 to 2026-04-23 | [REC], [UNI] |
| Open Cloud and in-game calls | Share one per-experience budget, same counter per request type | 2026-07-29 (announced 2026-07-15) | [UNI] |
| Storage | 500 MB + 1 MB x lifetime players | 2026-07-29 | [UNI] |
| Over storage | Billed through Extended Services, not throttled | 2026 | [EXT] |
| Over request budget | Throttled; new throttling error codes | 2026 | [ERR] |
| Per-key value size | 4 MB | unchanged | [UNI] |
| BindToClose callbacks | 30 seconds total | long-standing | create.roblox.com player data guide |

Implications:
- External tools (web dashboards, Open Cloud scripts, the Studio MCP `open_cloud_invoke` tool) now spend the same budget as your game servers. A runaway admin script can throttle live players.
- Check budget before bulk work: `DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.UpdateAsync)` [DEFS].
- Monitor in Creator Hub: Data Stores Observability and Data Stores Manager.
- Automated Right-to-be-Forgotten processing for data stores is in beta (April 2026) [REC].

## 2. API rules

| Call | Use it for | Never use it for |
|---|---|---|
| `UpdateAsync(key, transform)` | Player data, anything another server might also write, session locks | n/a |
| `GetAsync(key)` | Read-only lookups of data no one else writes in this session | Loading data you will later save (use UpdateAsync to take the lock) |
| `SetAsync(key, value)` | Write-only blobs only this server owns (server config snapshots) | Player data. It overwrites blindly and loses other servers' writes |
| `IncrementAsync(key, delta)` | Global counters | Player currency (no session lock) |
| `RemoveAsync(key)` | Deleting a key (GDPR requests) | Resetting data mid-session |

`UpdateAsync` signature [DEFS]: `UpdateAsync(key: string, transform: (any, DataStoreKeyInfo) -> (any, { number }?, {}?)): (any, DataStoreKeyInfo)`. The transform returns the new value, optional user IDs (for GDPR tagging), and optional metadata.

Transform function rules:
- It may run more than once if another server wrote at the same time. It must have no side effects: no yields, no remotes, no granting items.
- Return `nil` to cancel the write. The call then returns `nil`.
- Do not read player state that can change during the call; compute everything first.

## 3. Session locking

Without a lock, a player who rejoins fast (or teleports) can be loaded on server B before server A finishes saving, and server A's late save overwrites server B's progress. That is the root of most duplication and rollback bugs.

Pattern (implemented in templates/PlayerData.luau):
1. Load with `UpdateAsync`. If the record has a lock from a different `game.JobId` that is newer than `LOCK_TIMEOUT_SECONDS`, cancel and retry a few times, then kick with a clear message.
2. Otherwise write your own lock (`lockJobId = game.JobId`, `lockedAt = os.time()`) and keep the data.
3. Autosave every 1 to 3 minutes with `UpdateAsync`, refusing to write if the lock belongs to someone else.
4. On `PlayerRemoving`, save and release the lock (`lockJobId = nil`).
5. On `BindToClose`, save every loaded player in parallel and wait for all of them.

Community libraries that implement this (ProfileStore, the successor to ProfileService) are fine to use instead. If the user's code uses one, keep it; do not replace a working library with the template.

## 4. Retries and errors

- Wrap every DataStore call in `pcall`. They yield and they fail (throttling, outages, size limits).
- Retry with exponential backoff and jitter: wait `min(2^attempt, 30) + random()` seconds, up to about 5 attempts.
- Never retry forever on `PlayerAdded`; kick the player with a message rather than letting them play with default data that will overwrite their real save.
- Log failures with context: `warn(("[PlayerData] load %d failed: %s"):format(userId, err))`.
- Use a key prefix or versioned store name (`PlayerData_v1`) so a schema migration can read the old store and write the new one.

## 5. Schema and migration

```lua
--!strict
local CURRENT_VERSION = 3

export type Profile = {
	version: number,
	coins: number,
	inventory: { [string]: number },
	receipts: { [string]: boolean },
}

local function migrate(raw: { [string]: any }): Profile
	local version = raw.version or 1
	if version < 2 then
		raw.inventory = raw.inventory or {}
	end
	if version < 3 then
		raw.receipts = raw.receipts or {}
	end
	raw.version = CURRENT_VERSION
	return raw :: any -- validated shape after migration
end
```

- Store plain tables: numbers, strings, booleans, nested tables with string keys or array indices. No Instances, no Vector3 or CFrame (serialize to arrays), no mixed array and dictionary tables, no NaN.
- Keep a `version` field and migrate on load.
- Fill missing fields from a default profile (reconcile) so adding a field never breaks old saves.

## 6. Versioning and metadata

- `DataStoreSetOptions` carries metadata on writes; `DataStoreKeyInfo` (second return of `GetAsync` and `UpdateAsync`) exposes `Version`, `CreatedTime`, `UpdatedTime`, `GetUserIds()`, `GetMetadata()`.
- `DataStore:ListVersionsAsync(key, ...)` and `GetVersionAsync(key, version)` let you restore a player after a bad update.
[UNVERIFIED this cycle: exact parameter lists of ListVersionsAsync and GetVersionAtTimeAsync. Check the DataStore API page before writing restore tooling.]

## 7. MemoryStoreService and MessagingService

From [DEFS]:
- `MemoryStoreService:GetSortedMap(name)`, `GetQueue(name, invisibilityTimeout?)`, `GetHashMap(name)`
- `MessagingService:PublishAsync(topic, message)` and `SubscribeAsync(topic, callback): RBXScriptConnection`

| Need | Use |
|---|---|
| Cross-server matchmaking queue | MemoryStore queue |
| Live leaderboard that resets often | MemoryStore sorted map |
| Short-lived shared state (party info, server list) | MemoryStore hash map with expiration |
| "Broadcast this to all servers now" | MessagingService |
| Anything that must survive a week | DataStore |

MemoryStore data expires (max expiration applies) and has its own quota based on CCU. MessagingService delivery is best-effort and has per-topic and per-server limits. [UNVERIFIED this cycle: current MemoryStore and MessagingService quota numbers. Check create.roblox.com/docs before quoting numbers in code comments.]

## 8. Ordered data stores (leaderboards)

- `DataStoreService:GetOrderedDataStore(name)`, values are integers.
- `GetSortedAsync(ascending, pageSize)` returns pages; cache the top N for 60 seconds or more on each server instead of querying per player.
- Write the player's score on save, not on every change.
