# Studio Plugin Reference

Verified as of 2026-11-06. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. Core APIs

| API | Signature [DEFS] | Notes |
|---|---|---|
| Plugin global | `plugin: Plugin` | Only defined in plugin scripts |
| Toolbar | `plugin:CreateToolbar(name: string): PluginToolbar` | |
| Button | `toolbar:CreateButton(id: string, toolTip: string, iconAsset: string, text: string?): PluginToolbarButton` | `button.Click` fires on press |
| Dock widget | `plugin:CreateDockWidgetPluginGuiAsync(pluginGuiId: string, info: DockWidgetPluginGuiInfo): DockWidgetPluginGui` | The non-Async `CreateDockWidgetPluginGui` is deprecated |
| Settings | `plugin:GetSetting(key: string): any`, `plugin:SetSetting(key: string, value: any)` | Per user, per plugin |
| Selection | `game:GetService("Selection"):Get()`, `Selection.SelectionChanged` | |
| Undo recording | `ChangeHistoryService:TryBeginRecording(name: string, displayName: string?): string?` then `FinishRecording(identifier: string, operation: Enum.FinishRecordingOperation, finalOptions?)` | `SetWaypoint` is the legacy path |

Other deprecated plugin methods [DEFS]: `ImportFbxAnimation` and `ImportFbxRig` (use the `Async` versions), `PromptSaveSelection` (use `PromptSaveSelectionAsync`). Global `PluginManager()` is deprecated; use `plugin`.

## 2. Plugin skeleton

```lua
--!strict
-- A Studio plugin that anchors every selected part, with undo support.
local ChangeHistoryService = game:GetService("ChangeHistoryService")
local Selection = game:GetService("Selection")

local TOOLBAR_NAME = "Ray Tools"
local BUTTON_ID = "AnchorSelection"

local toolbar = plugin:CreateToolbar(TOOLBAR_NAME)
local button = toolbar:CreateButton(BUTTON_ID, "Anchor all selected parts", "rbxassetid://0", "Anchor")
button.ClickableWhenViewportHidden = false

local function anchorSelection()
	local recording = ChangeHistoryService:TryBeginRecording("AnchorSelection", "Anchor Selection")
	if not recording then
		warn("[RayTools] Another recording is in progress; try again.")
		return
	end

	local ok, err = pcall(function()
		for _, item in Selection:Get() do
			if item:IsA("BasePart") then
				item.Anchored = true
			end
			for _, descendant in item:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.Anchored = true
				end
			end
		end
	end)

	local operation = if ok then Enum.FinishRecordingOperation.Commit else Enum.FinishRecordingOperation.Cancel
	ChangeHistoryService:FinishRecording(recording, operation)
	if not ok then
		warn(("[RayTools] Anchor failed: %s"):format(tostring(err)))
	end
end

button.Click:Connect(anchorSelection)
```

## 3. Dock widget

```lua
--!strict
local WIDGET_ID = "RayToolsPanel"

local info = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Right, -- initial dock
	false, -- initially enabled
	false, -- override previous enabled state
	300, -- default width
	400, -- default height
	200, -- min width
	200 -- min height
)

local widget = plugin:CreateDockWidgetPluginGuiAsync(WIDGET_ID, info)
widget.Title = "Ray Tools"
```

## 4. Rules

- Every edit to the place goes through a ChangeHistoryService recording so Ctrl+Z works. Cancel the recording on error.
- Never edit the place when the user did not click something. Plugins that change the place on load are hostile.
- Save user preferences with `plugin:GetSetting` / `SetSetting`, not in the place.
- Clean up on `plugin.Unloading`: disconnect connections, destroy widgets you created.
- Plugins need user-granted permissions for HTTP requests and script injection. Request only what you use and explain why in the plugin description.
- Test plugins with "Save as Local Plugin" before publishing.

## 5. Plugin-related services in 2026

- `ReflectionService` exists [DEFS] and exposes engine API metadata to plugins so they can adapt without bundled API dumps [UNVERIFIED official documentation page; seen in third-party coverage].
- Extended Services updates expanded which Luau services are available to plugins and the command bar (devforum.roblox.com/t/extended-services-update/4070634) [UNVERIFIED details].
- For AI-assisted editing, the Studio built-in MCP server replaces most custom "bridge" plugins (tooling.md section 6).
