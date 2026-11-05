--!strict
-- Typed class with cleanup. Rename Tracker and replace its state with your own.

local Tracker = {}
Tracker.__index = Tracker

export type Tracker = typeof(setmetatable(
	{} :: {
		count: number,
		_connections: { RBXScriptConnection },
		_destroyed: boolean,
	},
	Tracker
))

function Tracker.new(): Tracker
	return setmetatable({
		count = 0,
		_connections = {},
		_destroyed = false,
	}, Tracker)
end

function Tracker.track(self: Tracker, signal: RBXScriptSignal)
	assert(not self._destroyed, "Tracker was destroyed")
	local connection = signal:Connect(function()
		self.count += 1
	end)
	table.insert(self._connections, connection)
end

function Tracker.destroy(self: Tracker)
	if self._destroyed then
		return
	end
	self._destroyed = true
	for _, connection in self._connections do
		connection:Disconnect()
	end
	table.clear(self._connections)
end

return Tracker
