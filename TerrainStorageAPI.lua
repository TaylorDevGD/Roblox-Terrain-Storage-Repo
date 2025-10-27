-- MODULE SETTINGS:
local AllowOverride = false

------------------

local module = {}
local Terrains = {}

local function GetRegion3int16(part)
	local ogparent = part.Parent
	part.Parent = game.Workspace

	local minWorld = part.Position - (0.5 * part.Size)
	local maxWorld = part.Position + (0.5 * part.Size)

	local function toVoxel(pos)
		return Vector3int16.new(
			math.floor(pos.X / 4),
			math.floor(pos.Y / 4),
			math.floor(pos.Z / 4)
		)
	end

	local minVoxel = toVoxel(minWorld)
	local maxVoxel = toVoxel(maxWorld)
	part.Parent = ogparent
	return Region3int16.new(minVoxel, maxVoxel)
end

local function GetRegion3(part)
	local minWorld = part.Position - (0.5 * part.Size)
	local maxWorld = part.Position + (0.5 * part.Size)

	return Region3.new(minWorld, maxWorld):ExpandToGrid(4)
end

local function GetVector3Int16(part)
	local pos = part.Position
	return Vector3int16.new(
		math.floor(pos.X / 4),
		math.floor(pos.Y / 4),
		math.floor(pos.Z / 4)
	)
end

function module:SetupTerrainInfo(name, part, deleteoncopy)
	local regionInt16 = GetRegion3int16(part)
	local region = GetRegion3(part)

	local copiedRegion = workspace.Terrain:CopyRegion(regionInt16)
	if copiedRegion and name ~= nil then
		local overridepossible = Terrains[name]
		if overridepossible and AllowOverride or not overridepossible then
			Terrains[name] = {
				TerrainRegion = copiedRegion,
				Region3Int16 = regionInt16,
				Region3 = region,
				Vector3Int16 = regionInt16.Min
			}
		else
			warn("TerrainRegion was not saved because it would override a previous save and you have AllowOverride set to false. If you want it to override then go into the module script and set AllowOverride to true")
		end
		if deleteoncopy == true or deleteoncopy == nil then
			workspace.Terrain:FillRegion(region, 4, Enum.Material.Air)
		end
	else
		error("No terrain could copied under part ", part.Name.." for ".. name..". Either the part is not touching any terrain OR you forgot to define Name.")
	end
end

function module:PasteTerrainInfo(name, newlocation)
	if Terrains[name] and newlocation == nil then
		workspace.Terrain:PasteRegion(Terrains[name].TerrainRegion, Terrains[name].Vector3Int16, true)
	elseif Terrains[name] and newlocation then
		local newRegion = GetRegion3int16(newlocation)
		if newRegion ~= nil then
			workspace.Terrain:PasteRegion(Terrains[name].TerrainRegion, newRegion.Min, true)
		else
			error("Could not paste terrain at new region because Region3int16 could not be calculated. Result:", newRegion)
		end
	else
		error("Could not find terrain data for ", name..". Data was set to: ".. Terrains[name])
	end
end

function module:DestroyTerrain(location)
	if type(location) == "string" and location ~= nil then
		workspace.Terrain:FillRegion(Terrains[location].Region3, 4, Enum.Material.Air)
	elseif location ~= nil then
		local regionInt16 = GetRegion3int16(location)
		workspace.Terrain:FillRegion(regionInt16, 4, Enum.Material.Air)
	else
		error("No selected area of terrain to destory. Did you forget the part instence or forget to put the part over terrain")
	end
end

function module:DeleteTerrainSaveSlot(name)
	if name ~= nil then
		Terrains[name] = nil
	else
		error("Could not find ", name.." in Terrain Regions Save Slots.")
	end
end

function module:GetTerrainInfo(name)
	return Terrains[name]
end

function module:GetAllTerrainInfo()
	return Terrains
end

return module
