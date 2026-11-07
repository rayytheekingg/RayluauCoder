# Fix Workflow

Use this when the user gives code and asks to fix, review, update or clean it. The goal is working, safe, current code with the smallest diff that achieves it.

## Step 0: Scope
- What did the user ask for? A specific bug, a full review, or "make it current"? Fix what was asked. Report other Critical and High findings, but only change them if they are in the code you were given and the fix is safe.
- Do not rewrite working logic that is not broken. Do not restyle untouched lines unless the user asks for a full cleanup.

## Step 1: Identify context
For each file, record:
- Container: Script, LocalScript or ModuleScript; RunContext if a Script
- Side: server, client or shared
- Where it lives (ServerScriptService, ReplicatedStorage, StarterPlayerScripts, a tool, a model)
- Server Authority on or off (ask or infer from `Workspace.AuthorityMode` or `BindToSimulation` use)
- Data library in use (custom, ProfileStore, DataStore2). Keep the user's library

## Step 2: Deprecated APIs
Scan against references/deprecations.md. Replace with the listed replacement. Note any behavior difference (for example `LoadCharacterAsync` yields).

## Step 3: Security
Walk every remote handler through networking-security.md section 3. Move any client-decided outcome to the server.

## Step 4: Data loss
Check saving against data-persistence.md: UpdateAsync, session lock, PlayerRemoving, BindToClose, retries, receipt handling.

## Step 5: Performance
Per-frame allocations, untracked connections, one connection per object, server-side visual effects, unprofiled `--!native`.

## Step 6: Types
Add `--!strict`. Type function signatures. Replace `any` with real types or document it. Values from remotes become `unknown` and are narrowed.

## Step 7: Style
Apply clean-code-standard.md to the lines you changed (or everything, if asked).

## Step 8: Verify
- Read the final code top to bottom once as the server, once as the client.
- If tools are available: `stylua --check`, `selene`, `luau-lsp analyze --platform=roblox` with the Roblox definitions file.
- If connected to Studio through MCP: playtest and read the output.
- If nothing can be run, say so.

## Output format

1. **Change list**, ranked by severity:
   ```
   Critical
   - Swing remote trusted client damage -> server now computes damage with range and cooldown checks
   High
   - Humanoid:LoadAnimation (deprecated) -> Animator:LoadAnimation
   Medium
   - DataStore GetAsync had no pcall -> wrapped with retries
   Low
   - Added --!strict and types to public functions
   ```
2. **Corrected full files**, each in its own code block with the file path above it.
3. **Not changed** (only if relevant): findings you reported but did not fix, and why.

Keep explanations to one line per change. The user wants working code, not a lecture.
