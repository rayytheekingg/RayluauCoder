--!strict
-- PlayerData: loads, autosaves and saves player profiles with a session lock, retries and BindToClose.
-- Place at: ServerScriptService/Server/Services/PlayerData (Rojo: src/server/Services/PlayerData.luau)
--
-- Why a session lock: without one, a player who rejoins fast can load on server B before server A
-- finishes saving, and server A's late save overwrites the new progress (rollbacks and item dupes).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local STORE_NAME = "PlayerData_v1"
local SCHEMA_VERSION = 1
local AUTOSAVE_SECONDS = 120
-- A lock not refreshed for 3 autosave cycles belongs to a server that crashed.
local LOCK_TIMEOUT_SECONDS = AUTOSAVE_SECONDS * 3
local LOCK_WAIT_ATTEMPTS = 5
local LOCK_WAIT_SECONDS = 6
local MAX_RETRIES = 5
local MAX_BACKOFF_SECONDS = 30
local CLOSE_TIMEOUT_SECONDS = 25 -- BindToClose has 30 seconds in total

export type Profile = {
	version: number,
	coins: number,
	inventory: { [string]: number },
	recentPurchaseIds: { string }, -- used by ProcessReceipt to avoid double grants
}

type Record = {
	data: Profile,
	lockJobId: string?,
	lockedAt: number?,
}

type Session = {
	profile: Profile,
	released: boolean,
}

local store = DataStoreService:GetDataStore(STORE_NAME)
-- Studio has no JobId; give each Studio session its own id so locks still work in playtests.
local serverId = if game.JobId ~= "" then game.JobId else `studio-{HttpService:GenerateGUID(false)}`

local sessions: { [Player]: Session } = {}

local function defaultProfile(): Profile
	return {
		version = SCHEMA_VERSION,
		coins = 0,
		inventory = {},
		recentPurchaseIds = {},
	}
end

-- Fills fields added after the player's last save, so new fields never break old data.
local function reconcile(saved: { [string]: any }): Profile
	local template = defaultProfile()
	for key, value in template :: any do
		if saved[key] == nil then
			saved[key] = value
		end
	end
	saved.version = SCHEMA_VERSION
	-- any: shape is guaranteed by the loop above filling every Profile field.
	return saved :: any
end

local function withRetry<T>(label: string, callback: () -> T): (boolean, T?)
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(callback)
		if ok then
			return true, result
		end
		warn(`[PlayerData] {label} attempt {attempt} failed: {result}`)
		if attempt < MAX_RETRIES then
			task.wait(math.min(2 ^ attempt, MAX_BACKOFF_SECONDS) + math.random())
		end
	end
	return false, nil
end

local function isLockedByOtherServer(record: Record?): boolean
	if not record or not record.lockJobId or record.lockJobId == serverId then
		return false
	end
	return os.time() - (record.lockedAt or 0) < LOCK_TIMEOUT_SECONDS
end

local function tryAcquire(userId: number): (boolean, Profile?)
	local key = tostring(userId)
	local ok, record = withRetry(`load {key}`, function(): Record?
		local result = store:UpdateAsync(key, function(old: Record?): (Record?, { number }?)
			if isLockedByOtherServer(old) then
				return nil, nil -- cancel: another live server owns this player
			end
			local data = if old and old.data then reconcile(old.data :: any) else defaultProfile()
			return { data = data, lockJobId = serverId, lockedAt = os.time() }, { userId }
		end)
		return result
	end)
	if not ok then
		return false, nil -- DataStore is failing
	end
	if record == nil or record.lockJobId ~= serverId then
		return true, nil -- locked by another server
	end
	return true, record.data
end

local function load(player: Player): Profile?
	for _ = 1, LOCK_WAIT_ATTEMPTS do
		local ok, profile = tryAcquire(player.UserId)
		if not ok then
			return nil
		end
		if profile then
			return profile
		end
		if not player.Parent then
			return nil
		end
		task.wait(LOCK_WAIT_SECONDS)
	end
	return nil
end

local function save(userId: number, session: Session, release: boolean): boolean
	if session.released then
		return true
	end
	local key = tostring(userId)
	local lostLock = false
	local ok = withRetry(`save {key}`, function(): boolean
		store:UpdateAsync(key, function(old: Record?): (Record?, { number }?)
			if session.released then
				return nil, nil -- another save already released this session
			end
			if old and old.lockJobId ~= serverId then
				lostLock = true
				return nil, nil -- never overwrite data another server now owns
			end
			return {
				data = session.profile,
				lockJobId = if release then nil else serverId,
				lockedAt = os.time(),
			}, { userId }
		end)
		return true
	end)
	if lostLock then
		warn(`[PlayerData] lost session lock for {key}; save skipped`)
		session.released = true
		-- Progress from here on could not be saved, so stop the session instead of letting them play on.
		local player = Players:GetPlayerByUserId(userId)
		if player and not release then
			player:Kick("Your data session moved to another server. Please rejoin.")
		end
		return false
	end
	if ok and release then
		session.released = true
	end
	return ok
end

local PlayerData = {}

--[=[
	Returns the loaded profile for `player`, or nil if it is not loaded yet or failed to load.
	Mutate the returned table directly; it is saved on autosave, on leave and on shutdown.
]=]
function PlayerData.get(player: Player): Profile?
	local session = sessions[player]
	return if session and not session.released then session.profile else nil
end

--[=[
	Saves `player`'s profile now and keeps the lock. Yields. Returns true on success.
	ProcessReceipt calls this before returning PurchaseGranted.
]=]
function PlayerData.saveNow(player: Player): boolean
	local session = sessions[player]
	if not session then
		return false
	end
	return save(player.UserId, session, false)
end

local function onPlayerAdded(player: Player)
	local profile = load(player)
	if not profile then
		if player.Parent then
			player:Kick("Your data could not be loaded. Please rejoin in a minute.")
		end
		return
	end
	local session: Session = { profile = profile, released = false }
	if not player.Parent then
		-- Left while loading: release the lock right away.
		save(player.UserId, session, true)
		return
	end
	sessions[player] = session
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	save(player.UserId, session, true)
	sessions[player] = nil
end

--[=[
	Connects player events, autosave and shutdown saving. Call once from the server bootstrap.
]=]
function PlayerData.start()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, session in sessions do
				task.spawn(save, player.UserId, session, false)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player, session in sessions do
			pending += 1
			task.spawn(function()
				save(player.UserId, session, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < CLOSE_TIMEOUT_SECONDS do
			task.wait(0.1)
		end
	end)
end

return PlayerData
