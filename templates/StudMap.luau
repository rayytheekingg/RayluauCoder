--!strict
-- StudMap: helpers for building bright studded maps from code, plus a seeded obby section generator
-- and a server-side kill brick / checkpoint handler.
-- Place at: ServerScriptService/Server/StudMap (Rojo: src/server/StudMap.luau)
-- Run the builders from the command bar, through the Studio MCP server, or once at server start.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

export type MapPalette = {
	platform: Color3,
	platformAlt: Color3,
	hazard: Color3,
	checkpoint: Color3,
	ground: Color3,
}

export type PartProps = {
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	studs: boolean?,
	tag: string?,
	name: string?,
	parent: Instance,
}

export type ObbyProps = {
	origin: CFrame,
	seed: number,
	jumps: number,
	palette: MapPalette,
	parent: Instance,
}

local KILL_TAG = "KillBrick"
local CHECKPOINT_TAG = "Checkpoint"
local CHECKPOINT_EVERY = 6
local HAZARD_EVERY = 4
local PLATFORM_SIZE = Vector3.new(8, 1, 8)
local MIN_GAP = 4
local MAX_GAP = 9
local MAX_RISE = 2.5
local MAX_SIDE_STEP = 6

local StudMap = {}

--[=[
	A preset palette in the Studded Classic colors. Copy and edit for each zone.
]=]
StudMap.classicPalette = {
	platform = Color3.fromHex("1E63D6"),
	platformAlt = Color3.fromHex("FFC21A"),
	hazard = Color3.fromHex("E23B2E"),
	checkpoint = Color3.fromHex("2BB24C"),
	ground = Color3.fromHex("6FBF4A"),
} :: MapPalette

--[=[
	Creates one anchored part. `studs` puts classic studs on top and inlets underneath.
]=]
function StudMap.part(props: PartProps): Part
	local part = Instance.new("Part")
	part.Name = props.name or "Brick"
	part.Anchored = true
	part.Size = props.size
	part.CFrame = props.cframe
	part.Color = props.color
	part.Material = props.material or Enum.Material.Plastic
	if props.studs ~= false then
		part.TopSurface = Enum.SurfaceType.Studs
		part.BottomSurface = Enum.SurfaceType.Inlet
	end
	if props.tag then
		CollectionService:AddTag(part, props.tag)
	end
	part.Parent = props.parent
	return part
end

--[=[
	A checkered stud floor made of `tilesX` x `tilesZ` tiles, alternating two colors.
	Big tiles keep the part count low; 16 to 32 studs per tile is a good start.
]=]
function StudMap.floor(
	origin: CFrame,
	tilesX: number,
	tilesZ: number,
	tileSize: number,
	colors: { Color3 },
	parent: Instance
): Model
	local model = Instance.new("Model")
	model.Name = "StudFloor"
	for x = 0, tilesX - 1 do
		for z = 0, tilesZ - 1 do
			local offset = Vector3.new((x - (tilesX - 1) / 2) * tileSize, 0, (z - (tilesZ - 1) / 2) * tileSize)
			StudMap.part({
				name = "Tile",
				size = Vector3.new(tileSize, 1, tileSize),
				cframe = origin * CFrame.new(offset),
				color = colors[(x + z) % #colors + 1],
				parent = model,
			})
		end
	end
	model.Parent = parent
	return model
end

--[=[
	Generates an obby section: platforms with seeded random gaps, rises and side steps, a hazard strip
	every few jumps (tagged KillBrick) and a checkpoint every few jumps (tagged Checkpoint).
	The same seed always builds the same section. Returns the model.
]=]
function StudMap.obbySection(props: ObbyProps): Model
	local random = Random.new(props.seed)
	local model = Instance.new("Model")
	model.Name = `ObbySection_{props.seed}`

	local cursor = props.origin
	for jump = 1, props.jumps do
		local isCheckpoint = jump % CHECKPOINT_EVERY == 0
		local color = if isCheckpoint
			then props.palette.checkpoint
			elseif jump % 2 == 0 then props.palette.platformAlt
			else props.palette.platform

		local platform = StudMap.part({
			name = if isCheckpoint then `Checkpoint{jump}` else `Platform{jump}`,
			size = PLATFORM_SIZE,
			cframe = cursor,
			color = color,
			tag = if isCheckpoint then CHECKPOINT_TAG else nil,
			parent = model,
		})
		if isCheckpoint then
			platform:SetAttribute("Stage", jump // CHECKPOINT_EVERY)
		end

		if jump % HAZARD_EVERY == 0 and not isCheckpoint then
			-- A thin neon strip across the middle: readable, avoidable, always the hazard color.
			StudMap.part({
				name = "Hazard",
				size = Vector3.new(PLATFORM_SIZE.X, 0.4, 1.5),
				cframe = cursor * CFrame.new(0, PLATFORM_SIZE.Y / 2 + 0.2, 0),
				color = props.palette.hazard,
				material = Enum.Material.Neon,
				studs = false,
				tag = KILL_TAG,
				parent = model,
			})
		end

		local gap = random:NextNumber(MIN_GAP, MAX_GAP)
		local rise = random:NextNumber(0, MAX_RISE)
		local side = random:NextNumber(-MAX_SIDE_STEP, MAX_SIDE_STEP)
		cursor = cursor * CFrame.new(side, rise, -(PLATFORM_SIZE.Z + gap))
	end

	model.Parent = props.parent
	return model
end

--[=[
	Server only. Kills players who touch KillBrick parts and remembers the last Checkpoint each
	player touched (as the "Stage" attribute on the player). Works for parts added later, so
	streamed or generated sections are covered.
]=]
function StudMap.startHazards()
	local function characterHumanoid(hit: BasePart): (Player?, Humanoid?)
		local character = hit.Parent
		if not character or not character:IsA("Model") then
			return nil, nil
		end
		local player = Players:GetPlayerFromCharacter(character)
		return player, character:FindFirstChildOfClass("Humanoid")
	end

	local function onKillBrick(instance: Instance)
		if not instance:IsA("BasePart") then
			return
		end
		instance.Touched:Connect(function(hit: BasePart)
			local _, humanoid = characterHumanoid(hit)
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
	end

	local function onCheckpoint(instance: Instance)
		if not instance:IsA("BasePart") then
			return
		end
		instance.Touched:Connect(function(hit: BasePart)
			local player = characterHumanoid(hit)
			local stage = instance:GetAttribute("Stage")
			if not player or typeof(stage) ~= "number" then
				return
			end
			local saved = player:GetAttribute("Stage")
			local current = if typeof(saved) == "number" then saved else 0
			if stage > current then
				player:SetAttribute("Stage", stage)
			end
		end)
	end

	for _, part in CollectionService:GetTagged(KILL_TAG) do
		onKillBrick(part)
	end
	CollectionService:GetInstanceAddedSignal(KILL_TAG):Connect(onKillBrick)

	for _, part in CollectionService:GetTagged(CHECKPOINT_TAG) do
		onCheckpoint(part)
	end
	CollectionService:GetInstanceAddedSignal(CHECKPOINT_TAG):Connect(onCheckpoint)
end

return StudMap
