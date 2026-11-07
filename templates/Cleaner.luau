--!strict
-- Cleaner: tracks connections, instances, threads and cleanup callbacks, and releases them in reverse order.
-- Place at: ReplicatedStorage/Shared/Cleaner (Rojo: src/shared/Cleaner.luau)
--
-- Usage:
--   local cleaner = Cleaner.new()
--   cleaner:add(RunService.PostSimulation:Connect(onStep))
--   cleaner:connect(humanoid.Died, onDied)
--   cleaner:add(function() print("custom cleanup") end)
--   cleaner:destroy()

export type Task = RBXScriptConnection | Instance | thread | () -> ()

type CleanerFields = {
	_tasks: { Task },
	_destroyed: boolean,
}

local Cleaner = {}
Cleaner.__index = Cleaner

export type Cleaner = typeof(setmetatable({} :: CleanerFields, Cleaner))

local VALID_KINDS = {
	RBXScriptConnection = true,
	Instance = true,
	thread = true,
	["function"] = true,
}

local function cleanTask(item: Task)
	if typeof(item) == "RBXScriptConnection" then
		item:Disconnect()
	elseif typeof(item) == "Instance" then
		item:Destroy()
	elseif type(item) == "thread" then
		-- task.cancel errors on the currently running thread; pcall keeps cleanup going.
		pcall(task.cancel, item)
	elseif type(item) == "function" then
		item()
	end
end

--[=[
	Creates an empty Cleaner.
]=]
function Cleaner.new(): Cleaner
	local self: CleanerFields = { _tasks = {}, _destroyed = false }
	return setmetatable(self, Cleaner)
end

--[=[
	Tracks a connection, Instance, thread or cleanup function and returns it unchanged.
	If the Cleaner was already destroyed, the item is cleaned immediately.
]=]
function Cleaner.add<T>(self: Cleaner, item: T): T
	assert(
		VALID_KINDS[typeof(item)],
		`Cleaner:add expected a connection, Instance, thread or function, got {typeof(item)}`
	)
	-- any: the assert above guarantees item is a Task; Luau cannot narrow a generic T.
	local trackable = (item :: any) :: Task
	if self._destroyed then
		cleanTask(trackable)
	else
		table.insert(self._tasks, trackable)
	end
	return item
end

--[=[
	Connects `callback` to `signal` and tracks the connection.
]=]
function Cleaner.connect<A...>(self: Cleaner, signal: RBXScriptSignal<A...>, callback: (A...) -> ()): RBXScriptConnection
	return self:add(signal:Connect(callback))
end

--[=[
	Releases every tracked item, newest first. Safe to call more than once.
]=]
function Cleaner.destroy(self: Cleaner)
	self._destroyed = true
	local tasks = self._tasks
	for index = #tasks, 1, -1 do
		local item = tasks[index]
		tasks[index] = nil
		cleanTask(item)
	end
end

return Cleaner
