--!strict
-- In-memory stand-in for a DataStore in Studio playtests, so tests never touch saved data.
-- Set failGets, failUpdates, and failMessage to simulate service errors.

local HttpService = game:GetService("HttpService")

local MockDataStore = {
	calls = { get = 0, set = 0, update = 0 },
	data = {} :: { [string]: any },
	failGets = 0,
	failUpdates = 0,
	failMessage = "503: temporary failure",
}

-- Tables are copied through JSON because a real store never shares tables with the session.
local function store(key: string, value: any)
	MockDataStore.data[key] = HttpService:JSONDecode(HttpService:JSONEncode(value))
end

function MockDataStore:GetAsync(key: string): any
	MockDataStore.calls.get += 1
	if MockDataStore.failGets > 0 then
		MockDataStore.failGets -= 1
		-- Level 0 keeps the message starting with its code, like real DataStore errors.
		error(MockDataStore.failMessage, 0)
	end
	return MockDataStore.data[key]
end

function MockDataStore:SetAsync(key: string, value: any)
	MockDataStore.calls.set += 1
	store(key, value)
end

function MockDataStore:UpdateAsync(key: string, transform: (any) -> any): any
	MockDataStore.calls.update += 1
	if MockDataStore.failUpdates > 0 then
		MockDataStore.failUpdates -= 1
		error(MockDataStore.failMessage, 0)
	end
	local nextValue = transform(MockDataStore.data[key])
	if nextValue ~= nil then
		store(key, nextValue)
	end
	return nextValue
end

return MockDataStore
