--!strict
-- Client entry point. Exploiters can read and change anything that runs here.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

print(`[{Config.GameName}] Client started for {Players.LocalPlayer.Name}`)
