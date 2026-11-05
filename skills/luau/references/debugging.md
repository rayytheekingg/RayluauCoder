# Debugging Output errors

Sources: [Output window](https://create.roblox.com/docs/studio/output), [script debugging](https://create.roblox.com/docs/studio/debugging), [data store errors](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

Exact wording can change. Match on the meaning.

## Method

1. Read the first error, not the last. Later errors are often side effects.
2. Find the location in `ServerScriptService.Main:12`: the script path and the line.
3. Read the stack from top to bottom. The top is where it failed. Lower lines show who called it.
4. Note whether it came from the server or the client. Studio's Output tags and colors messages by source.
5. Reproduce it. Add a temporary `print` or breakpoint just before the failing line.
6. Fix the first cause, then remove the temporary logging.
7. Run `check` again.

## Common errors

| Error | Meaning | Check |
| --- | --- | --- |
| `attempt to index nil with 'X'` | The value before `.X` is `nil` | Which value is `nil`, then why: missing instance, failed lookup, or a function with no return |
| `X is not a valid member of Y` | `Y` has no property or child called `X` | Spelling and case, then `api-lookup`. Use `WaitForChild` if it arrives later |
| `Infinite yield possible on 'A:WaitForChild("B")'` | `B` did not appear within a few seconds | Spelling, path, which side created it, and streaming |
| `attempt to call a nil value` | The called function does not exist | Spelling, module return value, and `.` versus `:` |
| `attempt to perform arithmetic (add) on nil and number` | An operand is `nil` | The missing value, or a wrong key |
| `attempt to compare nil < number` | One side is `nil` or a different type | Defaults, and convert with `tonumber` where needed |
| `attempt to concatenate nil with string` | A value in `..` is `nil` | Use `tostring`, or string interpolation |
| `invalid argument #1 to 'X' (Y expected, got Z)` | Wrong argument type | The call's arguments. With `:` versus `.`, the arguments may be shifted |
| `Unable to assign property X. Y expected, got Z` | Wrong value type for the property | Property type, using `api-lookup` |
| `Unable to cast value to Object` | A non-Instance was passed where an Instance is required | Argument order, especially `FireClient(player, ...)` |
| `Argument 1 missing or nil` | A required argument is missing | Call site, and `.` versus `:` |
| `Requested module experienced an error while loading` | The module threw while running | The earlier error from inside the module |
| `Attempted to call require with invalid argument(s)` | `require` got something other than a ModuleScript or asset ID | The path, and whether it is `nil` |
| `FireServer can only be called from the client` | Wrong side | Script type and location |
| `OnServerEvent can only be used on the server` | Wrong side | Script type and location |
| `The current thread cannot ...` or `lacking capability` | Security level is too low | `api-lookup` security level. Plugin-only APIs do not work in game scripts |
| `Script timeout: exhausted allowed execution time` | A loop ran without yielding | Add a yield, fix the exit condition, or split the work |
| `stack overflow` | Unbounded recursion, often a `__index` or property change loop | The repeating stack lines |
| `Maximum event re-entrancy depth exceeded` | Events keep firing each other, past a depth of 10 | Add a guard, or avoid setting the watched property |
| `cannot resume dead coroutine` | A finished thread was resumed | Thread lifecycle. Do not resume threads twice |
| `Remote event invocation queue exhausted` | A remote has no listener, and messages piled up | Connect the handler earlier, or fire less |
| `Http requests are not enabled` | HTTP is disabled | Game Settings, then Security. It only works from the server |

## DataStore errors

| Error | Meaning | Action |
| --- | --- | --- |
| `You must publish this place to the web` | Place is not published | Publish it |
| `403`, or `StudioAccessToApisNotAllowed` | Studio API access is off | Turn on "Enable Studio Access to API Services". Do not retry |
| `101` to `107` | Invalid request, such as a bad key, or a value that's too large or can't be saved | Fix the code. Do not retry |
| `511` to `513` | Invalid metadata or user IDs | Fix the code. Do not retry |
| `509` | Writes are blocked in this environment | Do not retry |
| `301` to `306`, or "added to queue" | A request queue is full, at 30 requests | Reduce the request rate, then retry later |
| `401`, `402` | The experience is shutting down | Finish what you can in `BindToClose` |
| `502` | API Services rejected the request | Retry with backoff |
| `404`, `501`, `503`, `504`, `505` | The response couldn't be read, and the data may be corrupted | Retry with backoff. If it persists, inspect the key in Data Stores Manager |
| Names ending in `Throttled` | A budget was exceeded for the experience, server, store, or key | Back off, and reduce requests |

## Tools

- `print` and `warn` for values, `debug.traceback()` for call paths.
- Studio breakpoints and Watch for stepping through code.
- Developer Console (F9) for errors in a live game.
- `xpcall(fn, debug.traceback)` to keep the stack from a caught error.
- A Start Server test with 2 players in Studio's Test tab for replication and remote bugs. Play Solo can hide these.
- `RunService:IsStudio()` for test-only behaviour. Do not let it control security or saved data rules.

## When no error appears

- Add a `print` at the script's start. If it does not show, check its location, type, and `Enabled`.
- Print whether each connection fires.
- Check for a yield that never returns, such as `WaitForChild` or a stuck `while`.
- Use Pause or breakpoints in Studio to find where a thread stops.
- Then check `references/pitfalls.md`.
