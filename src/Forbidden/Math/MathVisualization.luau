local API = {}

type tInstance = {
    originPart: BasePart,
    endPart: BasePart,
    connectingPart: BasePart
}

local instanceTable: { [Instance]: tInstance} = {}
local forbiddenVSTable: Folder = nil

local function getInstance(origin: Instance): tInstance
    if forbiddenVSTable == nil then
       forbiddenVSTable         = Instance.new("Folder")
       forbiddenVSTable.Name    = "ForbiddenMathVisualizerParts"
       forbiddenVSTable.Parent  = workspace 
    end
    
    if instanceTable[origin] then return instanceTable[origin] end

    -- new entry
    instanceTable[origin] = {}

    -- originPart
    local newTIntFolder = Instance.new("Folder")
    newTIntFolder.Name      = origin.Name
    newTIntFolder.Parent    = forbiddenVSTable

    local function makeNewPart(name: string): BasePart
        local newPart = Instance.new("Part")
        newPart.Size         = Vector3.new(1,1,1)
        newPart.Material     = Enum.Material.Neon
        newPart.CanCollide   = false
        newPart.CanQuery     = false
        newPart.CanTouch     = false
        newPart.Anchored     = true
        newPart.CastShadow   = false
        newPart.Transparency = 0.5
        return newPart
    end

    local op = makeNewPart("originPart")
    op.Shape        = Enum.PartType.Ball
    op.Parent       = newTIntFolder
    instanceTable[origin]["originPart"] = op

    local ep = makeNewPart("endPart")
    ep.Shape        = Enum.PartType.Ball
    ep.Parent       = newTIntFolder
    instanceTable[origin]["endPart"] = ep

    local cp = makeNewPart("connectingPart")
    cp.Parent       = newTIntFolder
    instanceTable[origin]["connectingPart"] = cp

    return instanceTable[origin]
end

local function isValidVector3(v: Vector3): boolean
	return v.X == v.X and v.Y == v.Y and v.Z == v.Z -- checks for NaN
end

API.VisualizeRaycast = function(ORIGIN_INT: Instance, origin: Vector3, target: Vector3, success: boolean)
	local tInt = getInstance(ORIGIN_INT)
	local originPart        = tInt["originPart"]
	local endPart           = tInt["endPart"]
	local connectingPart    = tInt["connectingPart"]

	-- validate origin and target
	if not (isValidVector3(origin) and isValidVector3(target)) then
		warn("Invalid Vector3 detected. Skipping visualization.")
		return
	end

	originPart.Position = origin
	endPart.Position = target

	local newPos = (origin + target) / 2
	if isValidVector3(newPos) then
		connectingPart.CFrame = CFrame.lookAt(newPos, target)
	end

	local function ChangeColor(color: BrickColor)
		originPart.BrickColor = color
		endPart.BrickColor = color
		connectingPart.BrickColor = color
	end

	if success then ChangeColor(BrickColor.Green()) end
	if not success then ChangeColor(BrickColor.Red()) end
end

return API