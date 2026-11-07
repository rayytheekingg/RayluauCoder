--!strict
-- RemoteHandler: connects server handlers to RemoteEvents with a per-player rate limit and argument validation.
-- Place at: ServerScriptService/Server/RemoteHandler (Rojo: src/server/RemoteHandler.luau)
--
-- Usage:
--   RemoteHandler.connect(Remotes.Swing, function(target: unknown): Model?
--       if typeof(target) == "Instance" and target:IsA("Model") then
--           return target
--       end
--       return nil
--   end, function(player: Player, target: Model)
--       -- target is validated; now check distance, cooldown, ownership
--   end)

local Players = game:GetService("Players")

export type RateOptions = {
	capacity: number, -- burst size
	refillPerSecond: number,
}

type Bucket = { tokens: number, last: number }

local DEFAULT_RATE: RateOptions = { capacity = 10, refillPerSecond = 5 }
local MAX_STRING_LENGTH = 200

local bucketsByRemote: { [RemoteEvent]: { [Player]: Bucket } } = {}

local function takeToken(buckets: { [Player]: Bucket }, player: Player, rate: RateOptions): boolean
	local now = os.clock()
	local bucket = buckets[player]
	if not bucket then
		bucket = { tokens = rate.capacity, last = now }
		buckets[player] = bucket
	end
	bucket.tokens = math.min(rate.capacity, bucket.tokens + (now - bucket.last) * rate.refillPerSecond)
	bucket.last = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end

Players.PlayerRemoving:Connect(function(player: Player)
	for _, buckets in bucketsByRemote do
		buckets[player] = nil
	end
end)

local RemoteHandler = {}

--[=[
	Connects `handler` to `remote.OnServerEvent`. Each fire is rate limited per player, then passed
	to `validate`, which receives the raw arguments and returns a typed value or nil to reject.
	Returns the connection.
]=]
function RemoteHandler.connect<A>(
	remote: RemoteEvent,
	validate: (...unknown) -> A?,
	handler: (Player, A) -> (),
	rate: RateOptions?
): RBXScriptConnection
	local limits = rate or DEFAULT_RATE
	local buckets: { [Player]: Bucket } = {}
	bucketsByRemote[remote] = buckets

	return remote.OnServerEvent:Connect(function(player: Player, ...: unknown)
		if not takeToken(buckets, player, limits) then
			return
		end
		local ok, args = pcall(validate, ...)
		if not ok or args == nil then
			warn(`[Remote:{remote.Name}] rejected arguments from {player.UserId}`)
			return
		end
		handler(player, args)
	end)
end

--[=[
	True if `value` is a real number (not NaN, not infinite) between `min` and `max`.
]=]
function RemoteHandler.isNumberInRange(value: unknown, min: number, max: number): boolean
	if typeof(value) ~= "number" then
		return false
	end
	local number = value :: number
	return number == number and number >= min and number <= max
end

--[=[
	True if `value` is a string no longer than `maxLength` (default 200).
]=]
function RemoteHandler.isShortString(value: unknown, maxLength: number?): boolean
	return typeof(value) == "string" and #(value :: string) <= (maxLength or MAX_STRING_LENGTH)
end

--[=[
	Returns `value` as an Instance of `className` that is a descendant of `ancestor`, or nil.
]=]
function RemoteHandler.instanceUnder(value: unknown, className: string, ancestor: Instance): Instance?
	if typeof(value) ~= "Instance" then
		return nil
	end
	local instance = value :: Instance
	if instance:IsA(className) and instance:IsDescendantOf(ancestor) then
		return instance
	end
	return nil
end

return RemoteHandler
