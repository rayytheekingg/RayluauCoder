# Luau Language Reference

Verified as of 2026-11-06. Source tags: [NTS] = devforum.roblox.com/t/general-release-luau%E2%80%99s-new-type-solver/4084991 (2025-11-20). [REL] = github.com/luau-lang/luau/releases. [RFC] = rfcs.luau.org. [DEFS] = luau-lsp `scripts/globalTypes.d.luau` (main branch, fetched 2026-11-06). Items marked [UNVERIFIED] were not re-confirmed this cycle.

## 1. Versions and type solver

| Item | Current state | Status | Source |
|---|---|---|---|
| Luau OSS version | 0.745 (2026-10-30), weekly cadence | released | [REL] |
| Studio Luau build | Ships its own build; do not assume it equals the latest OSS tag | n/a | [REL] |
| New Type Solver | General release 2025-11-20. Default for `--!nocheck` and `--!nonstrict`. Strict scripts opt in with `Workspace.UseNewLuauTypeSolver = Enabled` | released | [NTS] |
| Old solver | Kept available "through 2026" | deprecated path | [NTS] |
| Studio Beta toggle for NTS | Removed 2026-01-07; use the Workspace property | removed | [NTS] |
| Default type mode | `Workspace.LuauTypeCheckMode` (Default, NoCheck, Nonstrict, Strict) sets the place default | released | [NTS], [DEFS] |

Rules for the skill:
- Every file still starts with `--!strict`. The per-file directive overrides the place default, so code stays strict no matter how the place is configured.
- Write code that type checks under the New Type Solver. Under the old solver, it also usually passes. The reverse is not always true.
- New nonstrict mode reports only errors that are certain to fail at runtime. Strict mode reports everything. Strict is the standard.

## 2. Type annotations you must use

```lua
--!strict
export type Inventory = {
	coins: number,
	items: { [string]: number },
	equipped: string?,
}

local function addCoins(inventory: Inventory, amount: number): number
	inventory.coins += amount
	return inventory.coins
end
```

- `T?` is shorthand for `T | nil`.
- `{ T }` is an array. `{ [K]: V }` is a map.
- `typeof(value)` in a type position copies the type of an expression: `type Config = typeof(require("./Config"))`.
- Use `unknown` for values from the network or the client, then narrow with `typeof`. Never use `any` for remote arguments.
- Casts use `::`. Only cast when you know more than the checker. `(x :: any) :: T` is a red flag and needs a comment.

## 3. Generics

```lua
--!strict
local function first<T>(list: { T }): T?
	return list[1]
end

-- Explicit instantiation (RFC: explicit-type-parameter-instantiation, Implemented)
local Cache = {}
function Cache.new<V>(): { [string]: V }
	return {}
end
local weaponCache = Cache.new<<Tool>>()
```

- `f<<T>>()` replaces the old `nil :: T` trick for generics that cannot be inferred from arguments. Source: luau.org/types/generics, [RFC] explicit-type-parameter-instantiation.
- StyLua needs `syntax = "Luau"` to format `<<T>>` (see templates/stylua.toml).

## 4. New Type Solver features

- **User-defined type functions**: `type function` runs at type-check time to compute types. Use for advanced libraries only. Game code rarely needs them.
- **Read and write property modifiers**: `{ read name: string }` declares a property that can be read but not assigned. Use on public module state you do not want callers to mutate.
- **Method `self` typing**: under the New Type Solver, the inferred type of `self` in `:` methods can be read-only. Annotate class types explicitly (see the class pattern below). Shared self types have an RFC (rfcs.luau.org/shared-self-types.html) [UNVERIFIED shipped in Roblox].

Class pattern that type checks cleanly in both solvers:

```lua
--!strict
local Counter = {}
Counter.__index = Counter

export type Counter = typeof(setmetatable({} :: { value: number }, Counter))

function Counter.new(start: number): Counter
	return setmetatable({ value = start }, Counter)
end

function Counter.increment(self: Counter, by: number): number
	self.value += by
	return self.value
end

return Counter
```

## 5. Syntax reference

| Feature | Example | Status |
|---|---|---|
| String interpolation | `` `Score: {score}` `` | stable [UNVERIFIED this cycle, long-standing] |
| If-expression | `local label = if hp > 0 then "Alive" else "Dead"` | stable |
| Compound assignment | `x += 1`, `s ..= "!"` | stable |
| Floor division | `7 // 2 == 3` | stable |
| `continue` | inside loops | stable |
| Generalized iteration | `for key, value in tbl do` (no `pairs` needed) | stable |
| `const` locals | `const MAX_HEALTH = 100` | Luau 0.711, RFC #166. Developer reports say it works in Studio since May 2026 [UNVERIFIED official Roblox announcement] |
| Attributes | `@native`, `@checked`, `@deprecated` on functions | stable |
| Experimental only | `if local`, `while local`, exact tables by default | experimental in OSS 0.739 to 0.745. Do not use in game code |

Skill rule: until Roblox officially announces `const`, write `local UPPER_SNAKE = value` for constants. Accept `const` in user code without flagging it.

## 6. Built-in types: buffer and vector

```lua
--!strict
-- buffer: fixed-size mutable bytes. Fast serialization, compact network payloads.
local packet = buffer.create(8)
buffer.writeu16(packet, 0, 1234) -- itemId
buffer.writef32(packet, 2, 98.5) -- health
local itemId = buffer.readu16(packet, 0)

-- vector: native 3-component value type, the library behind Vector3 math in Luau.
local v = vector.create(1, 2, 3)
local length = vector.magnitude(v)
```

Use `buffer` for UnreliableRemoteEvent payloads that must stay under 1,000 bytes (see networking-security.md). [UNVERIFIED this cycle: buffer and vector library function lists; check luau.org/library before relying on a function not shown here.]

## 7. Native code generation

- `--!native` at the top of a script compiles every function in it to native code. `@native` on a single function compiles only that function.
- Native code helps math-heavy, loop-heavy pure Luau (noise, pathfinding grids, custom physics, serialization). It does nothing for code that mostly calls Roblox APIs.
- Luau 0.745 added automatic promotion of hot functions to native based on call and loop counts [REL]. Roblox rollout of auto-promotion is [UNVERIFIED].
- Rule: add `--!native` or `@native` only when the Script Profiler shows the function is hot. Leave a comment with what the profiler showed.

```lua
--!strict
@native
local function sampleHeightMap(grid: { number }, width: number, x: number, z: number): number
	return grid[z * width + x + 1]
end
```

## 8. Standard library changes worth knowing

| Change | Version | Status |
|---|---|---|
| `table.create(n, value?)` and `table.clear(t)` are now fastcalls | 0.745 | released [REL] |
| `string.split` optimized | 0.740 | released [REL] |
| New math constants (RFC "Math constants") | 0.711 | released [REL]; exact constant names [UNVERIFIED] |

Prefer `table.create(n)` when you know the final array size. Prefer `table.clear(t)` over assigning a new table when the table is reused every frame.

## 9. Things that are not Luau

- `loadstring` is disabled in Roblox games by default. Never generate code that depends on it.
- `getfenv` and `setfenv` deoptimize the whole script. Never use them.
- `goto` does not exist.
- Global variables (assigning without `local`) are an error under the clean-code standard and a Selene `global_usage` error.
