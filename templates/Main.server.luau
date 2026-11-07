--!strict
-- Server bootstrap: the only Script on the server. Requires every service, then init(), then start().
-- Place at: ServerScriptService/Server/Main (Script) (Rojo: src/server/Main.server.luau)
-- Services live in the sibling Services folder. A client bootstrap mirrors this with Controllers.

type Service = {
	init: (() -> ())?,
	start: (() -> ())?,
}

local servicesFolder = script.Parent:WaitForChild("Services")

local services: { [string]: Service } = {}

for _, child in servicesFolder:GetChildren() do
	if child:IsA("ModuleScript") then
		local ok, result = pcall(require, child)
		if ok and typeof(result) == "table" then
			services[child.Name] = result :: any -- any: modules are checked against Service by shape at runtime
		else
			warn(`[Main] failed to load service {child.Name}: {result}`)
		end
	end
end

for name, service in services do
	local init = service.init
	if init then
		xpcall(init, function(err: unknown)
			warn(`[Main] {name}.init failed: {err}\n{debug.traceback()}`)
		end)
	end
end

for name, service in services do
	local start = service.start
	if start then
		task.spawn(function()
			xpcall(start, function(err: unknown)
				warn(`[Main] {name}.start failed: {err}\n{debug.traceback()}`)
			end)
		end)
	end
end
