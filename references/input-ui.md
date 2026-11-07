# Input and UI Reference

Verified as of 2026-11-06. [IAS] = devforum.roblox.com/t/full-release-input-action-system-ias-newly-converted-player-scripts/4678416 (2026-06-11). [IASB] = devforum.roblox.com/t/client-beta-input-action-system-is-now-available-to-publish-in-experiences/3890979. [IAM] = devforum.roblox.com/t/studio-beta-input-action-manager/4737890. [DEFS] = luau-lsp `globalTypes.d.luau` (fetched 2026-11-06).

## 1. Which input API

| API | Status | Use for |
|---|---|---|
| Input Action System (`InputContext`, `InputAction`, `InputBinding`) | Full release 2026-06-11 [IAS] | All new gameplay input. Required under Server Authority |
| `UserInputService` | Current | Raw device state: last input type, gamepad connected, touch enabled, mouse lock |
| `ContextActionService` | Legacy for new code | Existing code only. Do not rewrite working CAS code unless the user asks or Server Authority is on |

Default PlayerScripts are migrating to IAS in phases; `Workspace.PlayerScriptsUseInputActionSystem` (Enum.RolloutState) controls it [IAS], [DEFS]. Phase 1: defaults to Disabled, set Enabled to opt in. Phase 2 (ETA early 2027): defaults to Enabled. Test custom camera and control scripts with it Enabled now so the default flip does not break them [IAS].

## 2. IAS object model

From [DEFS]:

`InputContext` (Instance): `Enabled`, `Priority: number`, `Sink: boolean`, `GetInputActions()`, `InputActionsChanged`.

`InputAction` (Instance): `Type: Enum.InputActionType`, `Enabled`, `DisplayName`, `Pressed`, `Released`, `StateChanged: RBXScriptSignal<any>`, `GetState(): any`, `GetInputBindings()`, `PreferredBinding`, `GetPreferredBindingList(count?)`. `Fire()` is deprecated.

`Enum.InputActionType`: `Bool`, `Direction1D`, `Direction2D`, `Direction3D`, `ViewportPosition`.

`InputBinding` (Instance): `KeyCode`, `Up`, `Down`, `Left`, `Right`, `Forward`, `Backward`, `PrimaryModifier`, `SecondaryModifier`, `UIButton: GuiButton`, `UIModifier: GuiButton`, `Scale`, `Vector2Scale`, `Deadzone: NumberRange`, `PressedThreshold`, `ReleasedThreshold`, `ResponseCurve`, `ClampMagnitudeToOne` (default true), `PointerIndex`, `Type`.

Behavior notes:
- An InputBinding listens to one input source at a time since 2026-02-24 [IASB].
- Touch keycodes `TouchPosition`, `TouchPinch`, `TouchDelta`; mouse and trackpad `MouseDelta`, `MouseWheel`, `TrackpadPan`, `TrackpadPinch` map to directional actions [IASB].
- Higher `Priority` contexts receive input first; `Sink = true` stops lower contexts from also receiving it. Use this for menus that should block gameplay input.
- Input Action Manager, a Studio editor for contexts and bindings, is in Studio beta [IAM].

## 3. IAS example: sprint and attack

Instances can be authored in Studio (or the Input Action Manager) and found by name, or created in code. Code version:

```lua
--!strict
-- StarterPlayerScripts/Client/InputController.client.luau
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function makeAction(context: InputContext, name: string, actionType: Enum.InputActionType): InputAction
	local action = Instance.new("InputAction")
	action.Name = name
	action.Type = actionType
	action.Parent = context
	return action
end

local function bindKey(action: InputAction, keyCode: Enum.KeyCode)
	local binding = Instance.new("InputBinding")
	binding.KeyCode = keyCode
	binding.Parent = action
end

local gameplay = Instance.new("InputContext")
gameplay.Name = "Gameplay"
gameplay.Priority = 100
gameplay.Parent = player:WaitForChild("PlayerScripts")

local sprint = makeAction(gameplay, "Sprint", Enum.InputActionType.Bool)
bindKey(sprint, Enum.KeyCode.LeftShift)
bindKey(sprint, Enum.KeyCode.ButtonL3)

local attack = makeAction(gameplay, "Attack", Enum.InputActionType.Bool)
bindKey(attack, Enum.KeyCode.MouseLeftButton)
bindKey(attack, Enum.KeyCode.ButtonR2)

attack.Pressed:Connect(function()
	-- Send intent to the server; server validates (networking-security.md).
end)

sprint.StateChanged:Connect(function(isDown: boolean)
	-- UI feedback only. Movement speed is decided on the server or in BindToSimulation.
end)
```

`Enum.KeyCode.MouseLeftButton`, `ButtonR2` and `ButtonL3` exist in the KeyCode enum [DEFS]. For touch, add a binding with `UIButton` set to an on-screen GuiButton. Test every binding on keyboard, gamepad and touch in Studio's device emulator.

Under Server Authority, read `action:GetState()` inside `RunService:BindToSimulation` instead of reacting to `Pressed` for anything that moves the character.

## 4. UserInputService essentials

```lua
--!strict
local UserInputService = game:GetService("UserInputService")

local function isTouchDevice(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

UserInputService.LastInputTypeChanged:Connect(function(inputType: Enum.UserInputType)
	-- Swap button prompts between keyboard, gamepad and touch icons.
end)
```

`UserInputService:GetUserCFrame` is deprecated; use `VRService:GetUserCFrame` [DEFS].

## 5. UI rules

- Build for mobile first. Use `Scale`, not `Offset`, for layout. Pair with `UIAspectRatioConstraint` and `UISizeConstraint`.
- Touch targets at least 44 px. Respect the safe area (`ScreenGui.ScreenInsets`).
- Layout instances: `UIListLayout` (with flex support through `UIFlexItem`), `UIGridLayout`, `UIPadding`, `UICorner`, `UIStroke`, `UIGradient`, `UIScale`. All are creatable per [DEFS].
- `UIDragDetector` gives drag behavior to GuiObjects without custom input code; `DragDetector` does the same for 3D parts [DEFS].
- Styling: `StyleSheet`, `StyleRule`, `StyleDerive`, `StyleLink` released 2026-01-20; `StyleQuery` released 2026-05-11; Styling Transitions released 2026-07-27. Full guidance in ui-design.md and ui-style-guide.md.
- UI is never the source of truth. A shop button sends a purchase request; the server decides.
- Tween UI with `TweenService`; keep durations at or below 0.25 s for responsive menus; clean up tweens and connections when the UI closes.

## 6. Chat

- `TextChatService` is the chat system [DEFS]. The legacy `Chat` service methods such as `FilterStringForPlayerAsync` are deprecated [DEFS].
- Any text one player writes that another player sees (pet names, signs, custom messages) must be filtered on the server with `TextService:FilterStringAsync` and the result's `GetNonChatStringForBroadcastAsync` or `GetNonChatStringForUserAsync`.
- Chat commands: `TextChatCommand` instances under `TextChatService`, validated on the server.
[UNVERIFIED this cycle: legacy chat retirement date.]

## 7. Localization

- Put player-facing strings in a `LocalizationTable`; translate with `LocalizationService:GetTranslatorForPlayerAsync(player)`. The non-Async `GetTranslatorForPlayer` is deprecated [DEFS].
- Never concatenate translated fragments; use format keys with parameters.
