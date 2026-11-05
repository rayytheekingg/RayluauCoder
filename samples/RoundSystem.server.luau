--!strict
-- Sample: last-player-standing rounds. Clients read Phase, TimeLeft, and Winner attributes on the RoundState folder.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MIN_PLAYERS = 2
local INTERMISSION_SECONDS = 15
local ROUND_SECONDS = 120
local RESULTS_SECONDS = 5
local TICK_SECONDS = 0.25
local RETRY_AFTER_ERROR_SECONDS = 5

local roundState = Instance.new("Folder")
roundState.Name = "RoundState"
roundState:SetAttribute("Phase", "Waiting")
roundState:SetAttribute("TimeLeft", 0)
roundState.Parent = ReplicatedStorage

local function setPhase(phase: string)
	roundState:SetAttribute("Phase", phase)
end

-- Returns true if shouldStop ended the countdown early.
local function countdown(seconds: number, shouldStop: () -> boolean): boolean
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		if shouldStop() then
			return true
		end
		roundState:SetAttribute("TimeLeft", math.ceil(deadline - os.clock()))
		task.wait(TICK_SECONDS)
	end
	roundState:SetAttribute("TimeLeft", 0)
	return false
end

local function hasTooFewPlayers(): boolean
	return #Players:GetPlayers() < MIN_PLAYERS
end

local function countAlive(alive: { [Player]: boolean }): number
	local count = 0
	for _ in alive do
		count += 1
	end
	return count
end

local function runRound(): Player?
	local alive: { [Player]: boolean } = {}
	local connections: { RBXScriptConnection } = {}

	local function eliminate(player: Player)
		alive[player] = nil
	end

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			alive[player] = true
			local diedConnection = humanoid.Died:Once(function()
				eliminate(player)
			end)
			table.insert(connections, diedConnection)
		end
	end
	local removingConnection = Players.PlayerRemoving:Connect(eliminate)
	table.insert(connections, removingConnection)

	countdown(ROUND_SECONDS, function(): boolean
		return countAlive(alive) <= 1
	end)

	for _, connection in connections do
		connection:Disconnect()
	end

	if countAlive(alive) == 1 then
		local winner = next(alive)
		return winner
	end
	return nil
end

local function runCycle()
	if hasTooFewPlayers() then
		setPhase("Waiting")
		task.wait(1)
		return
	end

	setPhase("Intermission")
	if countdown(INTERMISSION_SECONDS, hasTooFewPlayers) then
		return
	end

	setPhase("Playing")
	roundState:SetAttribute("Winner", nil)
	local winner = runRound()

	setPhase("Results")
	roundState:SetAttribute("Winner", if winner then winner.Name else nil)
	task.wait(RESULTS_SECONDS)
end

local function logCycleError(message: unknown)
	warn(`Round cycle failed: {message}`)
end

while true do
	local ok = xpcall(runCycle, logCycleError)
	if not ok then
		task.wait(RETRY_AFTER_ERROR_SECONDS)
	end
end
