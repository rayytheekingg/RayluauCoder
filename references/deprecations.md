# Deprecations: Old API to Replacement

Verified as of 2026-11-06. Rows tagged [DEFS] come from `@[deprecated {use = "..."}]` attributes in luau-lsp `scripts/globalTypes.d.luau` (main branch, fetched 2026-11-06), which is generated from the Roblox API dump. Other rows cite their announcement.

How to use this file in a review: search the user's code for each name in the first column. Every hit is at least a Medium finding. Hits in the "removed" rows are High, because the code no longer works.

To refresh this table, download the definitions file and run:
```bash
grep -n -A1 "@\[deprecated" globalTypes.d.luau
```

## 1. Scheduling and globals

| Deprecated | Replacement | Source |
|---|---|---|
| `wait(t)`, `Wait(t)` | `task.wait(t)` | [DEFS] |
| `spawn(fn)` | `task.spawn(fn)` or `task.defer(fn)` | [DEFS] |
| `delay(t, fn)`, `Delay(t, fn)` | `task.delay(t, fn)` | [DEFS] |
| `ElapsedTime()` | `elapsedTime()` | [DEFS] |
| `Version()` | `version()` | [DEFS] |
| `stats()`, `Stats()` | `game:GetService("Stats")` | [DEFS] |
| `collectgarbage("count")` | `gcinfo()` | [DEFS] |
| `PluginManager()` | `plugin` | [DEFS] |
| `game:getService`, `game:service` | `game:GetService` | [DEFS] |
| `instance:isA` | `instance:IsA` | [DEFS] |
| Lowercase Instance methods: `clone`, `destroy`, `findFirstChild`, `getChildren`, `children`, `isDescendantOf` | PascalCase versions | [DEFS] |
| `Instance:Remove()` | `Instance:Destroy()` | long-standing [UNVERIFIED this cycle] |

## 2. Physics, parts and models

| Deprecated | Replacement | Source |
|---|---|---|
| `workspace:FindPartOnRay`, `FindPartOnRayWithIgnoreList`, `FindPartOnRayWithWhitelist` | `workspace:Raycast(origin, direction, params)` | [DEFS] |
| `workspace:FindPartsInRegion3*`, `IsRegion3Empty*` | `workspace:GetPartBoundsInBox`, `GetPartsInPart` | [DEFS] |
| `RaycastParams.FilterDescendantsInstances` + `FilterType` | `ExcludeInstances` / `IncludeInstances` (2026-04-07). Not yet flagged deprecated; Roblox plans to deprecate later | devforum 4563575 |
| `Model:SetPrimaryPartCFrame` | `Model:PivotTo` | [DEFS] |
| `Model:GetPrimaryPartCFrame`, `GetModelCFrame` | `Model:GetPivot` | [DEFS] |
| `Model:GetModelSize` | `Model:GetExtentsSize` | [DEFS] |
| `Model:MoveTo` lowercase variants `move`, `moveTo` | `Model:MoveTo` | [DEFS] |
| `BasePart:GetRootPart` | `BasePart.AssemblyRootPart` | [DEFS] |
| `PhysicsService:SetPartCollisionGroup` | `part.CollisionGroup = name` | [DEFS] |
| `PhysicsService:CreateCollisionGroup` / `RemoveCollisionGroup` | `RegisterCollisionGroup` / `UnregisterCollisionGroup` | [DEFS] |
| `PhysicsService:GetCollisionGroups` | `GetRegisteredCollisionGroups` | [DEFS] |
| `PhysicsService:GetCollisionGroupId`, `GetCollisionGroupName`, `CollisionGroupContainsPart` | `BasePart.CollisionGroup` | [DEFS] |
| `BodyVelocity`, `BodyGyro`, `BodyPosition`, `BodyAngularVelocity`, `BodyForce` | `LinearVelocity`, `AlignOrientation`, `AlignPosition`, `AngularVelocity`, `VectorForce` | legacy movers [UNVERIFIED this cycle: class-level deprecation flag] |
| `Attachment:GetAxis` / `SetAxis` | `Attachment.Axis` | [DEFS] |
| `PathfindingService:ComputeRawPathAsync`, `ComputeSmoothPathAsync` | `PathfindingService:CreatePath(agentParams)` then `path:ComputeAsync(start, finish)`, or `PathfindingService:FindPathAsync(start, finish)` | [DEFS] |
| `Path:GetPointCoordinates` | `Path:GetWaypoints` | [DEFS] |

## 3. Characters and players

| Deprecated | Replacement | Source |
|---|---|---|
| `Humanoid:LoadAnimation` | `Animator:LoadAnimation` | [DEFS] |
| `Humanoid:GetPlayingAnimationTracks` | `Animator:GetPlayingAnimationTracks` | [DEFS] |
| `Humanoid:ApplyDescription`, `ApplyDescriptionReset` | `ApplyDescriptionAsync`, `ApplyDescriptionResetAsync` | [DEFS] |
| `Humanoid:PlayEmote` | `Humanoid:PlayEmoteAsync` | [DEFS] |
| `Humanoid:ApplyAvatarRules` | `Humanoid:ApplyAvatarRulesAsync` | [DEFS] |
| `Player:LoadCharacter` | `Player:LoadCharacterAsync` | [DEFS] |
| `Player:LoadCharacterWithHumanoidDescription` | `LoadCharacterWithHumanoidDescriptionAsync` | [DEFS] |
| `Player:IsInGroup` | `Player:IsInGroupAsync` | [DEFS] |
| `Player:GetRankInGroup`, `GetRoleInGroup`, and their `Async` versions | `GroupService:GetRolesInGroupAsync(userId, groupId)` | [DEFS] |
| `Player:IsFriendsWith` | `Player:IsFriendsWithAsync` | [DEFS] |
| `Player:GetFriendsOnline` | `Player:GetFriendsOnlineAsync` | [DEFS] |
| `Player:SaveNumber`, `LoadNumber` and other Data Persistence methods | DataStoreService | [DEFS] |
| `Players:GetHumanoidDescriptionFromUserId` / `FromOutfitId` | `...Async` versions | [DEFS] |
| `Players:CreateHumanoidModelFromDescription` / `FromUserId` | `...Async` versions | [DEFS] |
| `Players:playerFromCharacter`, `getPlayers`, `players` | `Players:GetPlayerFromCharacter`, `GetPlayers` | [DEFS] |
| `StarterPlayer.EnableDynamicHeads`, `Workspace.MeshPartHeadsAndAccessories` | always on | removed April 2026 (weekly recap 4568634) |
| `ClientAnimatorThrottling` toggle | always on | removed 2026-04-29 (weekly recap 4568634) |

## 4. Input, UI and chat

| Deprecated | Replacement | Source |
|---|---|---|
| `ContextActionService:BindAction` for new gameplay input | Input Action System | IAS full release 2026-06-11 (devforum 4678416); CAS not flagged deprecated |
| `ContextActionService:BindActionToInputTypes` | `ContextActionService:BindAction` | [DEFS] |
| `InputAction:Fire` | Drive state through bindings | [DEFS] |
| `Player.InputContexts.CameraContext.CameraAction` | `Player:GetCameraState()` | removed 2026-07-09 (devforum 4727993) |
| `UserInputService:GetUserCFrame` | `VRService:GetUserCFrame` | [DEFS] |
| `Chat:FilterStringForPlayerAsync` | `TextService:FilterStringAsync` | [DEFS] (says `Chat:FilterStringAsync`; TextService is the current filter API) |
| Legacy Chat service UI | `TextChatService` | [UNVERIFIED this cycle: retirement date] |
| `GuiService:AddSelectionParent`, `AddSelectionTuple`, `RemoveSelectionGroup` | `GuiBase2d.SelectionGroup` | [DEFS] |
| `LocalizationService:GetTranslatorForPlayer` | `GetTranslatorForPlayerAsync` | [DEFS] |
| `Sound:play`, `pause`, `stop` (lowercase) | `Play`, `Pause`, `Stop` | [DEFS] |

## 5. Monetization, assets and services

| Deprecated | Replacement | Source |
|---|---|---|
| `MarketplaceService:GetProductInfo` | `GetProductInfoAsync` | [DEFS] |
| `MarketplaceService:PlayerOwnsAsset`, `PlayerOwnsBundle` | `...Async` versions | [DEFS] |
| `MarketplaceService:PromptPremiumPurchase` | `PromptRobloxSubscriptionPurchase` | [DEFS] |
| Granting on `PromptProductPurchaseFinished` | `ProcessReceipt` / `BindReceiptHandler` | create.roblox.com developer products docs |
| Cross-game developer product sales | Robux transfers | removed 2026-05-30 (developer products docs) |
| Legacy game pass / developer product web endpoints | Open Cloud APIs | deprecated 2026-04-23 (weekly recap 4568634) |
| `BadgeService:AwardBadge` | `AwardBadgeAsync` | [DEFS] |
| `ContentProvider:Preload` | `ContentProvider:PreloadAsync` | [DEFS] |
| `CollectionService:GetCollection` | `CollectionService:GetTagged` | [DEFS] |
| `InsertService:GetFreeModels`, `GetFreeDecals` | `...Async` versions | [DEFS] |
| `AssetService:GetAssetIdsForPackage`, `SearchAudio` | `...Async` versions | [DEFS] |
| `AvatarEditorService` non-Async methods (`GetInventory`, `SearchCatalog`, `GetItemDetails`, others) | `...Async` versions | [DEFS] |
| `KeyframeSequenceProvider:GetKeyframeSequence*`, `AnimationClipProvider:GetAnimationClip*` | `...Async` versions | [DEFS] |
| `SocialService:PromptLinkSharing` | `PromptLinkSharingAsync` | [DEFS] |
| `TeleportService:ReserveServerAsync` | `TeleportService:TeleportAsync(placeId, players, options)`; reserve with `ReserveServer` and pass `TeleportOptions.ReservedServerId` | [DEFS] |

## 6. Language and modules

| Deprecated | Replacement | Source |
|---|---|---|
| Implicit `Init` child in require-by-string | `require("@self/Child")` or an explicit path | removed (devforum 3405078) |
| `require("Name")` with no prefix | `./`, `../`, `@self/`, `@game/` | devforum 3405078 |
| `getfenv` / `setfenv` | Module tables and parameters | disables optimizations [UNVERIFIED this cycle: deprecation flag] |
| New Type Solver Studio Beta toggle | `Workspace.UseNewLuauTypeSolver` | removed 2026-01-07 (devforum 4084991) |

## 7. Studio, plugins and tools

| Deprecated | Replacement | Source |
|---|---|---|
| `Plugin:CreateDockWidgetPluginGui` | `CreateDockWidgetPluginGuiAsync` | [DEFS] |
| `Plugin:ImportFbxAnimation`, `ImportFbxRig`, `PromptSaveSelection` | `...Async` versions | [DEFS] |
| `StudioService:PromptImportFile`, `PromptImportFiles` | `...Async` versions | [DEFS] |
| `ChangeHistoryService:SetWaypoint` for plugin edits | `TryBeginRecording` / `FinishRecording` | API reference [UNVERIFIED this cycle: deprecation flag] |
| Open-source `studio-rust-mcp-server` | Studio built-in MCP server | no longer actively developed (devforum 4474643) |
| `TestService:Run` | `TestService:RunAsync` | [DEFS] |
| TestEZ for new tests | Jest-Lua | ecosystem practice |

## 8. Not deprecated (do not flag)

These look old but are current in [DEFS] with no deprecation attribute as of 2026-11-06:
- `RunService.Heartbeat`, `Stepped`, `RenderStepped` (prefer the Pre/Post names in new code, Low severity only).
- `UserInputService` and `ContextActionService` themselves.
- `TeleportService:ReserveServer` (non-Async).
- `RaycastParams.FilterDescendantsInstances` (superseded, not yet deprecated).
- `tick()` and `time()` (prefer `os.clock()` for timing and `os.time()` / `DateTime` for timestamps).
