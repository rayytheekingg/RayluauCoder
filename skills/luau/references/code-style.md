# Neat Luau code

These rules apply to new and changed code. In an existing project, match its established style unless asked to change it. `scripts/run neat` checks the rules marked **(checked)**.

Sources: [Roblox Lua style guide](https://roblox.github.io/lua-style-guide/), [Luau syntax](https://luau.org/syntax)

## Naming **(checked)**

| Thing | Style | Example |
| --- | --- | --- |
| Module, class, service local | PascalCase | `PlayerData`, `Players` |
| Function, method | camelCase | `loadData`, `tracker:destroy()` |
| UI component, constructor-like function | PascalCase allowed | `CoinLabel` |
| Variable, parameter | camelCase | `coinCount` |
| Constant | SCREAMING_SNAKE_CASE | `MAX_ATTEMPTS` |
| Private field | Leading underscore | `_connections` |
| Unused value | `_` or a leading underscore | `for _, player in list do` |
| Type | PascalCase | `RateWindow` |
| Remote | PascalCase verb phrase | `PurchaseItem` |
| Boolean | Reads as a question | `isReady`, `hasKey` |

- Name a service local exactly after its service. Write `UserInputService`, not `UIS`.
- Prefer full words. Short names are fine for small loops and well-known terms such as `id`.
- Use a name that says what a value means, not its type.
- Don't fully capitalize acronyms in longer names: write `makeHttpCall` and `JsonData`. Sets of letters such as `RGB` and `XYZ` are the exception.
- Name a module's file and its local after the object it returns.

## File order **(services and requires are checked)**

1. Directives such as `--!strict`
2. A short comment, only if the file's purpose isn't obvious
3. Services
4. Requires
5. Constants
6. Types
7. State
8. Functions
9. Connections and startup
10. `return`

Short path aliases such as `local Shared = ReplicatedStorage:WaitForChild("Shared")` may sit between services and requires. Sort requires alphabetically within related groups when the project does.

## Functions

- One job per function. If the name needs "and", consider splitting it.
- Keep functions under 50 lines. **(checked)**
- Keep nesting at 4 levels or less. **(checked)**
- Use early returns to keep the main path flat.
- Prefer a few clear parameters. Use one options table when there are many.
- Don't use boolean parameters when a named option would be clearer.

## Files and modules

- One job per file, and under 400 lines. **(checked)**
- Return a small, clear API. Keep helpers as `local` functions.
- Keep state inside the module. Expose functions, not mutable tables.
- Do no work at require time beyond setting up the module. Use a `start` function.
- Put shared types with the module that owns them.
- Put code in the right place, as shown in the skill's script placement table.

## Comments

- Explain why, not what. Good code already shows what it does.
- Explain unusual decisions, limits, and workarounds.
- Delete comments that repeat the code.
- Delete commented-out code. Git keeps history. **(checked)**
- Give each TODO enough detail to act on. **(checked)**

## Clean finish

- Remove dead code and unused variables.
- Remove leftover debug prints. Keep only useful logs with clear messages. **(checked)**
- Move unexplained numbers into named constants. Obvious values, such as `0`, `1`, and `2` in simple math, can stay.
- Lines stay within 120 characters. **(checked)**
- Format with StyLua.

## Examples

### Early returns

Before:

```lua
local function buy(player: Player, itemId: string): boolean
	local data = PlayerData.get(player)
	if data then
		local price = PRICES[itemId]
		if price then
			if data.coins >= price then
				data.coins -= price
				return true
			end
		end
	end
	return false
end
```

After:

```lua
local function buy(player: Player, itemId: string): boolean
	local data = PlayerData.get(player)
	local price = PRICES[itemId]
	if not data or not price or data.coins < price then
		return false
	end

	data.coins -= price
	return true
end
```

### Names and constants

Before:

```lua
local ps = game:GetService("Players")
local t = {}

local function do_stuff(p)
	if os.clock() - (t[p] or 0) < 2.5 then
		return false
	end
	t[p] = os.clock()
	return true
end
```

After:

```lua
local Players = game:GetService("Players")

local COOLDOWN_SECONDS = 2.5

local lastUsedAt: { [Player]: number } = {}

local function canUseAbility(player: Player): boolean
	local now = os.clock()
	if now - (lastUsedAt[player] or 0) < COOLDOWN_SECONDS then
		return false
	end
	lastUsedAt[player] = now
	return true
end

Players.PlayerRemoving:Connect(function(player: Player)
	lastUsedAt[player] = nil
end)
```

### Comments and leftovers

Before:

```lua
-- add 1 to count
count += 1
print(count)
-- humanoid.WalkSpeed = 32
```

After:

```lua
count += 1
```

### Module API

Before:

```lua
local Inventory = {}

Inventory.items = {}

function Inventory.helper(item)
	return item.stack > 1
end

return Inventory
```

After:

```lua
local Inventory = {}

local items: { [Player]: { Item } } = {}

local function isStack(item: Item): boolean
	return item.stack > 1
end

function Inventory.countStacks(player: Player): number
	local count = 0
	for _, item in items[player] or {} do
		if isStack(item) then
			count += 1
		end
	end
	return count
end

return Inventory
```

## Safe tidying

- Tidying must not change behaviour.
- Don't tidy unrelated code unless asked.
- Don't rename public APIs, remotes, attributes, tags, Instances, DataStore names, or DataStore keys without checking every use. Renaming DataStore names or keys can lose access to saved data, so report those instead of changing them.
- Run `check` after tidying.

## Configuring neat

Add `rayluau-neat.json` to the project root. Every field is optional:

```json
{
  "max_line_length": 120,
  "max_function_lines": 50,
  "max_file_lines": 400,
  "max_nesting": 4,
  "disabled_rules": ["naming"],
  "ignore": ["src/vendor/*"]
}
```

Rules: `line-length`, `function-length`, `file-length`, `nesting`, `naming`, `order`, `commented-code`, `todo`, `leftover-print`.

To accept one case, add `-- neat: ignore` on that line or the line above. To skip a generated file, add `-- neat: ignore-file` to the file.
