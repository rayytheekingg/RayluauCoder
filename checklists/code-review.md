# Code Review Checklist

Mark each item Pass, Fail or N/A. Every Fail becomes a finding with a severity:
- **Critical**: security hole, data loss, money (free items, double grants, lost purchases)
- **High**: broken or removed API, crash, deprecated API with a behavior difference, memory leak that grows per player
- **Medium**: deprecated API that still works, performance issue confirmed or very likely, missing error handling on a web call
- **Low**: types, naming, style, comments, newer API name available (Heartbeat to PostSimulation)

## Security (Critical)
- [ ] Every `OnServerEvent` / `OnServerInvoke` checks rate, type, range, ownership and state for every argument
- [ ] No damage, price, currency amount, position or result is taken from the client
- [ ] No `RemoteFunction:InvokeClient`
- [ ] Numbers from clients are checked for NaN and infinity
- [ ] Instances from clients are checked with `IsA` and `IsDescendantOf`
- [ ] Server-only logic and secrets are not in ReplicatedStorage
- [ ] Gameplay-critical unanchored parts are server-owned (`SetNetworkOwner(nil)`) or Server Authority is on
- [ ] Player-written text shown to others is filtered with TextService

## Data (Critical)
- [ ] Player data uses `UpdateAsync`, not `SetAsync`
- [ ] Session lock prevents two servers writing the same player
- [ ] `PlayerRemoving` saves and releases the lock
- [ ] `BindToClose` saves every player in parallel and waits (under 30 s)
- [ ] Load failure kicks with a message instead of playing on default data
- [ ] Every DataStore call is in `pcall` with bounded retries and backoff
- [ ] Saved data is plain tables (no Instances, no Vector3/CFrame, no mixed tables, no NaN)
- [ ] Schema has a version field and missing fields are reconciled

## Monetization (Critical)
- [ ] `ProcessReceipt` is assigned exactly once
- [ ] Receipt dedupes on `PurchaseId`
- [ ] `PurchaseGranted` is returned only after the grant is saved
- [ ] Player missing or data not loaded returns `NotProcessedYet`
- [ ] Nothing is granted on `PromptProductPurchaseFinished`
- [ ] Game pass perks re-check `UserOwnsGamePassAsync` on the server

## APIs (High / Medium)
- [ ] No hits from references/deprecations.md
- [ ] No `wait`, `spawn`, `delay` globals
- [ ] No `FindPartOnRay`, `FindPartsInRegion3`, `SetPrimaryPartCFrame`, `Humanoid:LoadAnimation`, `Player:LoadCharacter`
- [ ] New spatial queries use `ExcludeInstances` / `IncludeInstances`
- [ ] New gameplay input uses the Input Action System (required when Server Authority is on)
- [ ] Server Authority code runs movement in `BindToSimulation` and is deterministic
- [ ] Require-by-string paths start with `./`, `../`, `@self/` or `@game/`; no implicit `Init`

## Lifecycle and performance (High / Medium)
- [ ] Every per-player and per-character connection is tracked and disconnected
- [ ] Every table keyed by Player is cleared on `PlayerRemoving`
- [ ] No `RaycastParams.new()`, table creation or `GetDescendants()` inside per-frame callbacks
- [ ] One shared loop for many similar objects instead of one connection each
- [ ] Client code works with StreamingEnabled (no unchecked `WaitForChild` without timeout on streamed parts)
- [ ] `--!native` only on profiled hot paths

## Code quality (Low)
- [ ] `--!strict` on every file; zero type errors in luau-lsp analyze
- [ ] File layout order: header, services, requires, types, constants, state, private, public, return
- [ ] Naming: PascalCase modules/types, camelCase locals/functions, UPPER_SNAKE constants
- [ ] No magic numbers; tunables in Config
- [ ] Public functions typed and doc-commented
- [ ] `any` only with a comment
- [ ] Early returns instead of deep nesting
- [ ] Comments explain why, not what; no commented-out code
- [ ] StyLua and Selene clean
