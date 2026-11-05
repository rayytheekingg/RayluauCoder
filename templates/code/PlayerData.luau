--!strict
-- Server-only player data with retries. Saves on an interval, on leave, at shutdown, and on request.
-- This does not session-lock. Add session locks before using it for trading or other duplication-sensitive data.
-- Listen to PlayerData.Loaded, then call PlayerData.start() once from a server Script.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local STORE_NAME = "PlayerData_v1"
local MAX_ATTEMPTS = 5
local BASE_RETRY_SECONDS = 1
local MAX_RETRY_SECONDS = 16
local AUTOSAVE_SECONDS = 180

export type Data = {
	revision: number,
	coins: number,
	owned: { [string]: boolean },
}

local store = DataStoreService:GetDataStore(STORE_NAME)
local loadedEvent = Instance.new("BindableEvent")
local sessions: { [Player]: Data } = {}
local savingKeys: { [string]: boolean } = {}
local activeSaves = 0
local started = false

local PlayerData = {}
PlayerData.Loaded = loadedEvent.Event

local function defaultData(): Data
	return {
		revision = 0,
		coins = 0,
		owned = {},
	}
end

local function keyFor(userId: number): string
	return `player_{userId}`
end

local function withRetries<T>(label: string, operation: () -> T): (boolean, T?)
	for attempt = 1, MAX_ATTEMPTS do
		local ok, result = pcall(operation)
		if ok then
			return true, result
		end
		warn(`{label} failed on attempt {attempt}/{MAX_ATTEMPTS}: {result}`)

		-- 10x errors mean the request is invalid, so another attempt cannot succeed.
		if attempt == MAX_ATTEMPTS or string.match(tostring(result), "^10%d") then
			break
		end
		local delaySeconds = math.min(BASE_RETRY_SECONDS * 2 ^ (attempt - 1), MAX_RETRY_SECONDS)
		task.wait(delaySeconds + math.random() * delaySeconds * 0.25)
	end
	return false, nil
end

local function reconcile(stored: any): Data
	local merged: any = defaultData()
	if typeof(stored) == "table" then
		for key, value in stored do
			merged[key] = value
		end
	end
	return merged
end

local function loadData(userId: number): (boolean, Data?)
	local key = keyFor(userId)
	local ok, stored = withRetries(`Load {key}`, function(): any
		local value = store:GetAsync(key)
		return value
	end)
	if not ok then
		return false, nil
	end
	return true, reconcile(stored)
end

local function saveData(userId: number, data: Data): boolean
	local key = keyFor(userId)
	activeSaves += 1
	while savingKeys[key] do
		task.wait(0.1)
	end
	savingKeys[key] = true
	data.revision += 1

	local ok, saved = withRetries(`Save {key}`, function(): any
		local value = store:UpdateAsync(key, function(current: any): any
			-- Returning nil cancels the write, which protects newer data from another server.
			if typeof(current) == "table" and (current.revision or 0) > data.revision then
				return nil
			end
			return data
		end)
		return value
	end)

	savingKeys[key] = nil
	activeSaves -= 1
	return ok and saved ~= nil
end

local function onPlayerAdded(player: Player)
	local ok, data = loadData(player.UserId)
	if player.Parent ~= Players then
		return
	end
	if not ok or not data then
		player:Kick("Your data could not be loaded. Please rejoin.")
		return
	end

	sessions[player] = data
	loadedEvent:Fire(player)

	task.wait(math.random() * AUTOSAVE_SECONDS)
	while sessions[player] == data do
		saveData(player.UserId, data)
		task.wait(AUTOSAVE_SECONDS)
	end
end

local function onPlayerRemoving(player: Player)
	local data = sessions[player]
	if data then
		sessions[player] = nil
		saveData(player.UserId, data)
	end
end

local function onClose()
	for player, data in sessions do
		sessions[player] = nil
		task.spawn(saveData, player.UserId, data)
	end
	while activeSaves > 0 do
		task.wait(0.1)
	end
end

function PlayerData.get(player: Player): Data?
	return sessions[player]
end

function PlayerData.saveNow(player: Player): boolean
	local data = sessions[player]
	if not data then
		return false
	end
	return saveData(player.UserId, data)
end

function PlayerData.start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(onClose)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return PlayerData
