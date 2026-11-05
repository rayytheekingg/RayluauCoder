# Luau language

Checked against Luau's docs on 2026-11-05.

Sources: [Luau types](https://luau.org/types), [Luau syntax](https://luau.org/syntax), [Luau library](https://luau.org/library), [attributes](https://luau.org/attributes), [lint rules](https://luau.org/lint), [Luau performance](https://luau.org/performance)

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
const MAX_COINS = 100 -- can't be reassigned, but a table's contents can still change
const function double(value: number): number
	return value * 2
end

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

`const` works in live Studio and in current luau-lsp, selene, and StyLua. Match the project, because older tool versions can't parse it.

## Advanced types

- `unknown` holds any value but needs narrowing before use. `never` has no values.
- Add a literal type with `"ok" | "failed"`, and optional fields with `field: string?`.
- Generic functions use `<T>`, and generic types use `type Box<T> = { value: T }`.
- Enum types work by name: `local material: Enum.Material = part.Material`.
- `x:IsA("TextLabel")` narrows an Instance to that class.
- `keyof<T>` and `index<T, K>` are built-in type functions.
- `type function` runs at analysis time to compute types. Use it only when ordinary types can't express the shape.
- Typed classes use `typeof(setmetatable(...))`, as in `templates/code/TypedModule.luau`.

## Attributes and lint control

- `@native` above a function compiles that function natively. It doesn't apply to functions defined inside it.
- `@deprecated` above a function makes the linter warn wherever it's called. Use it for your own old APIs.
- `--!nolint LocalUnused` turns off one lint in a file, such as `LocalShadow`, `UnknownGlobal`, or `DeprecatedApi`. Fix the cause first, and silence a lint only when it's wrong.

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
- Don't use a weak table to track whether an Instance still exists, because Luau can collect the reference while it's alive. Use `Instance.AncestryChanged` or `CollectionService:GetInstanceRemovedSignal`.
- Multi-return values shrink to one value unless they are last in a list. Wrap a call in parentheses to keep only the first.

## Useful library functions

- `table.create`, `table.find`, `table.clear`, `table.clone`, `table.freeze`, `table.insert`, `table.remove`, `table.move`
- `string.split`, `string.format`, `string.gsub`, `string.match`
- `math.clamp`, `math.round`, `math.floor`, `math.random`, `math.isfinite`, `math.isnan`, `math.lerp`
- `vector.create`, `vector.magnitude`, `vector.dot`, `vector.cross` for fast vector math
- `buffer.create` and the other `buffer` functions for compact binary data
- `utf8.len` for checking that text is valid UTF-8
- `os.clock` for measuring elapsed time

`table.clone` is shallow. Nested tables stay shared.

Run `api-lookup math.lerp` to check any library member. Selene's list can lag behind Roblox, so `check` ignores its error for members Roblox documents.

## Write code the VM can optimize

- Use `object.field` and `object:method()`. Caching methods or globals in locals isn't productive in Luau.
- Make `__index` point directly at a table. Avoid `__index` functions and deep `__index` chains.
- Set all of an object's fields in one table literal, instead of adding them one at a time.
- Use `table.insert` to append when the size is unknown, or `table.create` when it's known.
- `for key, value in t`, `pairs`, and `ipairs` perform about the same. Use whichever reads best.
- Avoid `getfenv`, `setfenv`, and `loadstring`, which turn off optimizations for the whole script.

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

- `--!native` compiles a script to native code on the server. Use it only for hot computational code after profiling. [Native code guide](https://create.roblox.com/docs/luau/native-code-gen)
- `@native` applies the same thing to one function. Prefer it, because compiled code has a total size limit in each game, and code past that limit runs normally.
- Add type annotations to native code. They let it generate faster code.
