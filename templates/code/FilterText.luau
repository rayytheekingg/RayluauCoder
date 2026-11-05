--!strict
-- Filters player text on the server. Roblox requires filtering for displayed text you don't fully control.
-- Both functions return nil on failure, so callers never have unfiltered text to show.

local TextService = game:GetService("TextService")

local FilterText = {}

local function getFilterResult(text: string, fromUserId: number): TextFilterResult?
	local ok, result = pcall(function(): TextFilterResult
		return TextService:FilterStringAsync(text, fromUserId)
	end)
	if ok then
		return result
	end
	warn(`Text filter failed: {result}`)
	return nil
end

-- Use for text that everyone in the server can see, such as a shop sign.
function FilterText.forEveryone(text: string, fromUserId: number): string?
	local filterResult = getFilterResult(text, fromUserId)
	if not filterResult then
		return nil
	end
	local ok, filtered = pcall(function(): string
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)
	return if ok then filtered else nil
end

-- Use for text that only one player can see, such as a private note. It is filtered for that player's age.
function FilterText.forPlayer(text: string, fromUserId: number, toUserId: number): string?
	local filterResult = getFilterResult(text, fromUserId)
	if not filterResult then
		return nil
	end
	local ok, filtered = pcall(function(): string
		return filterResult:GetNonChatStringForUserAsync(toUserId)
	end)
	return if ok then filtered else nil
end

return FilterText
