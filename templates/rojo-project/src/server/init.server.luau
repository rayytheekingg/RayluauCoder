--!strict
-- Server entry point. Child ModuleScripts in this folder are not visible to clients.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

print(`[{Config.GameName}] Server started`)
