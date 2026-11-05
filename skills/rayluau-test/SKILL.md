---
name: rayluau-test
description: Test Roblox code in a Studio playtest without changing the place
argument-hint: [file, folder, or feature]
disable-model-invocation: true
---

Test this code or feature in Roblox Studio: `$ARGUMENTS`

If nothing was given, use the code changed in this conversation. If there is none, ask what to test.

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/luau/references/studio-testing.md`, and follow its safety rules.
2. Find the Roblox Studio MCP tools, which are usually named like `mcp__Roblox_Studio__execute_luau`. If they aren't available, show the Studio section of `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" setup`, tell the user to start a new chat with Studio open, and stop.
3. For code in files, run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/run" check "<path>"`. Fix failures in code you were asked to change. Otherwise report them and ask before testing.
4. List the behaviours to prove, including what should be rejected.
5. Check the Studio state, then tell the user a playtest is starting.
6. Run the tests in the Server and Client contexts. Use `MockDataStore` instead of real data stores.
7. Read the results and the console output.
8. Always stop the playtest, and confirm that Studio is back in Edit mode.

Do not change the place in Edit mode, save, or publish unless the user asked.

Report each behaviour as PASS or FAIL, any console errors, and what could not be tested, such as multiple players or real services.
