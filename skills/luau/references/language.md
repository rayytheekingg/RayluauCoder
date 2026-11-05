# Luau language

Sources: [Luau types](https://luau.org/types), [Luau syntax](https://luau.org/syntax), [Luau library](https://luau.org/library)

## Type-check modes

Put one at the top of a file:

- `--!strict`: tracks types across statements and finds the most errors. Use it for new code.
- `--!nonstrict`: the default. Unclear types become `any`.
- `--!nocheck`: no type checking.

## Type syntax

```lua
local count: number = 0
local name: string? = nil -- string or nil
local ids: { number } = {} -- array
local scores: { [string]: number } = {} -- dictionary
local point: { x: number, y: number } = { x = 0, y = 0 } -- table shape

type Result = "ok" | "failed" -- literal union
type Callback = (player: Player, amount: number) -> boolean
export type Item = { id: string, price: number } -- visible to modules that require this one

local function first<T>(list: { T }): T?
	return list[1]
end

local part = instance :: BasePart -- cast
```

- Casts are checked, but they do not validate at runtime. Check the value first when it can vary.
- A cast on a multi-value call keeps only the first value.
- Table types are structural: Luau compares their shape, not their name.
- Use `unknown` for untrusted values. Narrow them with `typeof(value) == "string"` before use.
- Use `any` only when the type truly cannot be known.

## Syntax beyond Lua 5.1

```lua
count += 1 -- also -=, *=, /=, //=, %=, ^=, ..=
local label = if count > 0 then "yes" else "no"
local text = `Coins: {count}`
local half = count // 2 -- floor division

for index, value in list do -- no pairs or ipairs needed
	if value == nil then
		continue
	end
end
```

## Core behaviour

- Arrays start at 1.
- Every number is a 64-bit float. There is no separate integer type.
- `nil` removes a table entry. `#t` is not reliable when an array has holes.
- Only `nil` and `false` are falsy. `0` and `""` are truthy.
- `~=` means not equal.
- `a and b or c` returns `c` when `b` is falsy. Use an `if` expression instead.
- `typeof` knows Roblox types such as `Vector3` and `Instance`. `type` reports them as `userdata`.
- Removing entries from a list while walking it forward skips items. Walk backward with `table.remove`.
- Setting existing dictionary keys to `nil` during iteration is safe. Adding new keys is not.

## Useful library functions

- `table.create`, `table.find`, `table.clear`, `table.clone`, `table.freeze`, `table.insert`, `table.remove`
- `string.split`, `string.format`, `string.gsub`, `string.match`
- `math.clamp`, `math.round`, `math.floor`, `math.random`
- `buffer` for compact binary data
- `os.clock` for measuring elapsed time

`table.clone` is shallow. Nested tables stay shared.

## Modules

A `ModuleScript` returns one value. `require` runs it once per environment (server, or each client), then returns the same cached value.

```lua
local Module = {}

function Module.doThing(): number
	return 1
end

return Module
```

- Avoid side effects at require time. Prefer an explicit `start` function.
- Circular requires fail or yield forever. Move shared code into a third module.
- The server and client each get their own copy, so module state does not cross between them.

## Native and optimization directives

- `--!native` compiles a script to native code on the server. Use it only for hot computational code after profiling.
- `@native` applies the same thing to one function.
