#!/usr/bin/env python3
"""Print the status of optional tools and how to install them. Installs nothing."""
import os
import shutil
import sys

COMPANIONS_DOC = "skills/luau/references/companions.md"
STORE_PLUGINS = [
    ("Rojo", "after installing the rojo tool, run: rojo plugin install"),
    ("UI Labs", "https://create.roblox.com/store/asset/14293316215/UI-Labs"),
]


def studio_mcp_path():
    if sys.platform == "win32":
        return os.path.join(os.environ.get("LOCALAPPDATA", ""), "Roblox", "mcp.bat")
    if sys.platform == "darwin":
        return "/Applications/RobloxStudio.app/Contents/MacOS/StudioMCP"
    return None


def print_studio_status():
    print("\nRoblox Studio companions:\n")
    path = studio_mcp_path()
    if path and os.path.exists(path):
        print(f"[found]   Studio MCP launcher: {path}")
        print("    This does not show that Claude is connected. Check Manage MCP Servers in Studio.")
    else:
        print("[missing] Studio MCP launcher: install or update Roblox Studio on Windows or macOS.")
    print(f"    Connection steps: {COMPANIONS_DOC}")
    print("\nStudio plugins install through your Roblox account and can't be detected here:")
    for name, how in STORE_PLUGINS:
        print(f"  {name}: {how}")
    print(f"Full list and safety rules: {COMPANIONS_DOC}")
    print("\nWarning: tools connected to Studio can read and change your open place, and run code in it.")

ROKIT = "https://github.com/rojo-rbx/rokit#installation"
TOOLS = [
    (
        "luau-lsp",
        "type checks Roblox API calls, with Roblox definitions downloaded on first use",
        f"Install Rokit ({ROKIT}), then run: rokit add JohnnyMorganz/luau-lsp\n"
        "    Or download it from https://github.com/JohnnyMorganz/luau-lsp/releases/latest\n"
        "    For full checks, use Rojo or run: rojo sourcemap default.project.json --output sourcemap.json",
    ),
    (
        "luau-analyze",
        "fallback type check and syntax check, without Roblox API types",
        "Download luau-windows.zip, luau-ubuntu.zip or luau-macos.zip from "
        "https://github.com/luau-lang/luau/releases/latest\n"
        "    Put luau-analyze on your PATH.",
    ),
    (
        "selene",
        "lints Luau with Roblox rules",
        f"Install Rokit ({ROKIT}), then run: rokit add Kampfkarren/selene",
    ),
    (
        "stylua",
        "checks formatting",
        f"Install Rokit ({ROKIT}), then run: rokit add JohnnyMorganz/StyLua",
    ),
    (
        "rojo",
        "syncs files to Roblox Studio for /rayluau-new projects",
        f"Install Rokit ({ROKIT}), then run: rokit add rojo-rbx/rojo\n"
        "    Then run: rojo plugin install",
    ),
]


def main():
    missing = 0
    print("RayluauCoder optional tools (this script installs nothing):\n")
    for name, purpose, steps in TOOLS:
        path = shutil.which(name)
        if path:
            print(f"[found]   {name}: {path}")
        else:
            missing += 1
            print(f"[missing] {name}: {purpose}\n    {steps}")
    print(f"\n{len(TOOLS) - missing} found, {missing} missing.")
    if missing:
        print("All of these are optional. Check results list anything that was skipped.")
    print_studio_status()


if __name__ == "__main__":
    main()
