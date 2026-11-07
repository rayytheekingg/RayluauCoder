--!strict
-- Remotes: the single place every RemoteEvent is created (server) or found (client).
-- Place at: ReplicatedStorage/Shared/Remotes (Rojo: src/shared/Remotes.luau)
--
-- Add a remote by adding one line to the returned table. Never create remotes anywhere else.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "Remotes"
local CLIENT_WAIT_SECONDS = 30

local IS_SERVER = RunService:IsServer()

local function getFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if IS_SERVER then
		local folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
		return folder
	end
	local found = ReplicatedStorage:WaitForChild(FOLDER_NAME, CLIENT_WAIT_SECONDS)
	assert(found and found:IsA("Folder"), "[Remotes] Remotes folder never replicated")
	return found
end

local folder = getFolder()

local function remoteEvent(name: string): RemoteEvent
	if IS_SERVER then
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	local found = folder:WaitForChild(name, CLIENT_WAIT_SECONDS)
	assert(found and found:IsA("RemoteEvent"), `[Remotes] missing RemoteEvent {name}`)
	return found
end

local function unreliableRemoteEvent(name: string): UnreliableRemoteEvent
	if IS_SERVER then
		local remote = Instance.new("UnreliableRemoteEvent")
		remote.Name = name
		remote.Parent = folder
		return remote
	end
	local found = folder:WaitForChild(name, CLIENT_WAIT_SECONDS)
	assert(found and found:IsA("UnreliableRemoteEvent"), `[Remotes] missing UnreliableRemoteEvent {name}`)
	return found
end

return {
	-- Client -> server requests (validated by RemoteHandler on the server)
	Swing = remoteEvent("Swing"),
	RequestPurchase = remoteEvent("RequestPurchase"),

	-- Server -> client notifications
	Notify = remoteEvent("Notify"),

	-- Cosmetic, high-frequency, may drop (payload under 1,000 bytes)
	LookDirection = unreliableRemoteEvent("LookDirection"),
}
