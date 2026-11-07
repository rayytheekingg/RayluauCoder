--!strict
-- IconAtlas: icon name -> where it sits on an uploaded sprite sheet.
-- Place at: ReplicatedStorage/Shared/IconAtlas (Rojo: src/shared/IconAtlas.luau)
-- tools/build_icon_atlas.py generates this file. After uploading each atlas PNG, replace ATLAS_0 etc.
-- with the real asset IDs. The entries below are an example layout for 128 px icons on one sheet.

export type Icon = {
	image: string,
	offset: Vector2,
	size: Vector2,
}

local ATLAS_0 = "rbxassetid://0"

local ICONS: { [string]: Icon } = {
	coin = { image = ATLAS_0, offset = Vector2.new(0, 0), size = Vector2.new(128, 128) },
	gem = { image = ATLAS_0, offset = Vector2.new(128, 0), size = Vector2.new(128, 128) },
	shop = { image = ATLAS_0, offset = Vector2.new(256, 0), size = Vector2.new(128, 128) },
	close = { image = ATLAS_0, offset = Vector2.new(384, 0), size = Vector2.new(128, 128) },
	sword = { image = ATLAS_0, offset = Vector2.new(0, 128), size = Vector2.new(128, 128) },
	settings = { image = ATLAS_0, offset = Vector2.new(128, 128), size = Vector2.new(128, 128) },
}

local IconAtlas = {}

--[=[
	Returns the atlas entry for `name`, or nil if it is not in the atlas.
]=]
function IconAtlas.get(name: string): Icon?
	return ICONS[name]
end

--[=[
	Points `target` at the icon `name`. Returns false (and leaves target unchanged) if the icon is missing.
]=]
function IconAtlas.apply(target: ImageLabel | ImageButton, name: string): boolean
	local icon = ICONS[name]
	if not icon then
		warn(`[IconAtlas] unknown icon {name}`)
		return false
	end
	-- Separate branches keep both solvers happy; ImageLabel and ImageButton share these properties.
	-- selene: allow(if_same_then_else)
	if target:IsA("ImageButton") then
		target.Image = icon.image
		target.ImageRectOffset = icon.offset
		target.ImageRectSize = icon.size
		target.ScaleType = Enum.ScaleType.Fit
	elseif target:IsA("ImageLabel") then
		target.Image = icon.image
		target.ImageRectOffset = icon.offset
		target.ImageRectSize = icon.size
		target.ScaleType = Enum.ScaleType.Fit
	end
	return true
end

return IconAtlas
