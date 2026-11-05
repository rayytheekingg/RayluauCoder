# Security and data

Sources: [security tactics](https://create.roblox.com/docs/scripting/security/security-tactics), [remote events](https://create.roblox.com/docs/scripting/events/remote), [data store best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices), [data store errors and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits), [developer product receipts](https://create.roblox.com/docs/production/monetization/developer-products)

## What exploiters can do

- Read and decompile client scripts and anything in `ReplicatedStorage`.
- Fire any remote, with any arguments, as often as the network allows.
- Change anything local, including GUIs and local scripts.
- Control physics for parts they own, including their own character.
- Trigger client-side `Touched` events and `ProximityPrompt` activations from any range.

For each feature, ask three questions:

1. What is the worst result of any value a client could send?
2. What happens at 1,000 calls per second?
3. What server state does this expose that clients do not need?

## Remote validation

Use `templates/code/ServerRemote.server.luau` as a starting point. Validate in this order:

1. **Rate limit:** per player, per remote. Drop excess calls silently.
2. **Types:** `typeof(value)`. The first server parameter is always the real sender.
3. **Numbers:** reject `NaN` with `value ~= value`, reject infinities, and clamp to a range.
4. **Strings:** limit the length and compare with an allow list.
5. **Instances:** can be `nil`. Check the class, and check that the instance is one the player may use.
6. **Tables:** limit size, check every key and value. Do not trust their shape. Prefer simple arguments.
7. **Game rules:** ownership, cooldown, distance, currency, alive state, round state.
8. **Act:** make the server state change, then tell clients.

Remote transfer rules:

- Tables are copied, so identity is lost, along with metatables.
- Non-string keys such as Instances become strings. Avoid mixing number and string keys. Avoid `nil` inside arrays.
- Functions arrive as `nil`.

## Server authority

- Calculate damage, rewards, drops, and prices on the server.
- Check movement limits on the server if movement affects fairness.
- Competitive games can use Roblox's server authority feature, where clients send inputs and the server simulates. See the security tactics page.
- Do not rely on hidden remote names, client-side checks, or obfuscation.

## DataStore rules

Use `templates/code/PlayerData.luau` as a starting point.

- Use a small, fixed set of stores with one key per player, built from `UserId`.
- A value must be under 4 MB, and must be serializable: no Instances, functions, or mixed-key tables.
- Keep a session copy on the server. Do not call the store on every change.
- Save on an interval, on `PlayerRemoving`, at `BindToClose`, and after purchases. Add random offsets to intervals.
- Wrap every call in `pcall`. Retry temporary failures with capped backoff and jitter.
- Do not retry invalid requests, such as 10x errors for bad keys, values, or sizes.
- Keep retries for one key in order, because a late retry can overwrite newer data.
- Remember that a failed call may still have written. The result is sometimes unknown.
- Prefer `UpdateAsync` when writes depend on current data. Use `SetAsync` only for values that do not.
- `UpdateAsync` callbacks must not yield, and they may run more than once. Return `nil` to cancel.
- If a load fails, do not create a default session that later overwrites real data.
- Use versions for schema changes and fill in missing fields at load.
- Use `MemoryStoreService` for temporary data.
- Provide a way to erase a user's data for right-to-be-forgotten requests.
- Use session locks for trading and duplication-sensitive data. Review ownership and maintenance before adopting a third-party data module.

Studio needs a published place and "Enable Studio Access to API Services". Use a separate store name for testing to protect live data.

## Purchases

- Grant developer products in `MarketplaceService.ProcessReceipt` on the server.
- Assign only one `ProcessReceipt` callback in the experience.
- Return `PurchaseGranted` only after the grant is safely saved. Otherwise return `NotProcessedYet`.
- Track `PurchaseId` to avoid double grants.
- Never grant a paid item because a client said it was bought.

## Secrets

- Keep API keys in Secrets or server-only code, never in `ReplicatedStorage` or client scripts.
- Do not print secrets or player data to Output.

## Review checklist

- [ ] Every server remote handler has a rate limit.
- [ ] Every remote argument is type-checked and range-checked.
- [ ] Numbers reject `NaN` and infinities.
- [ ] The client never sends a price, reward, damage value, or target player's new state.
- [ ] Purchases check server-side price, funds, ownership, and distance.
- [ ] Remote handlers do not trust an Instance without checking it.
- [ ] `InvokeClient` is not used.
- [ ] Server-only logic and secrets are not in `ReplicatedStorage`.
- [ ] Every DataStore call uses `pcall` with retries.
- [ ] A failed load cannot overwrite real data.
- [ ] Data saves at interval, on leave, at shutdown, and after purchases.
- [ ] `ProcessReceipt` is idempotent and returns the correct decision.
- [ ] Rate-limit and session tables are cleared on `PlayerRemoving`.
