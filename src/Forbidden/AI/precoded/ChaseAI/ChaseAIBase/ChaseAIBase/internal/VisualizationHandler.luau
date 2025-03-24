local API = {}

local config = require(script.Parent.Parent:WaitForChild("Settings"))

-- 10/22/24 @rman501, to visualize the chase range system.
API.weldVisualParts = function()

	local visualizedFolder = config.enemy_char:FindFirstChild("Visualized Chase Range")
	if visualizedFolder == nil then return end

	local weldsForVisualizationFolder = config.enemy_hrt:FindFirstChild("Forbidden-WeldsForVisualization")
	if weldsForVisualizationFolder == nil then return end

	if #weldsForVisualizationFolder:GetChildren() > 0 then return end -- ignore.

	local location 	= config.enemy_hrt.CFrame.Position - Vector3.new(0, config.enemy_hrt.Size.Y, 0)
	local rot 		= CFrame.Angles(0, 0, math.rad(90))

	local startChaseCylinder 	= visualizedFolder:FindFirstChild("StartChaseCylinder")
	startChaseCylinder.CFrame 	= CFrame.new(location + Vector3.new(0,0.5,0)) * rot

	local maxChaseCylinder 		= visualizedFolder:FindFirstChild("MaxChaseCylinder")
	maxChaseCylinder.CFrame 	= CFrame.new(location + Vector3.new(0,0,0)) * rot

	startChaseCylinder.Anchored = false
	maxChaseCylinder.Anchored 	= false


	local weld1 = Instance.new("WeldConstraint")
	weld1.Name 		= "Weld1"
	weld1.Part0 	= config.enemy_hrt
	weld1.Part1 	= startChaseCylinder
	weld1.Parent 	= weldsForVisualizationFolder
	weld1.Enabled	= true

	local weld2 = Instance.new("WeldConstraint")
	weld1.Name 		= "Weld2"
	weld2.Part0 	= config.enemy_hrt
	weld2.Part1 	= maxChaseCylinder
	weld2.Parent 	= weldsForVisualizationFolder
	weld2.Enabled	= true
end

-- 10/22/24 @rman501, to visualize the chase range system.
API.unweldVisualParts = function()
	local visualizedFolder = config.enemy_char:FindFirstChild("Visualized Chase Range")
	if visualizedFolder == nil then return end

	local weldsForVisualizationFolder = config.enemy_hrt:FindFirstChild("Forbidden-WeldsForVisualization")
	if weldsForVisualizationFolder == nil then return end

	for i, v in pairs(weldsForVisualizationFolder:GetChildren()) do
		v:Destroy()
	end

	for i, v in pairs(visualizedFolder:GetChildren()) do
		v.Anchored = true
	end
end

API.VisualizeCone = function()
	--if config.detectionFOV > 90 then print("not visualizing cone with greater than 90deg angle.") return end

	-- TESTING
	--local config = {}
	--config.detectionFOV = 70
	--config.detectionRange = 50
	--config.enemy_char = workspace:WaitForChild("AI"):WaitForChild("Ravaga")

	local cone_side_length = config.detectionRange * math.tan(math.rad(config.detectionFOV))
	cone_side_length *= 2

	local cone_template = Instance.new("Part")
	cone_template.Shape		= Enum.PartType.CornerWedge
	cone_template.Size		= Vector3.new(cone_side_length, config.detectionRange * 2, cone_side_length)
	cone_template.Transparency = 0.5
	cone_template.Material = Enum.Material.SmoothPlastic
	cone_template.Color = BrickColor.Red().Color
	cone_template.CanCollide = false
	cone_template.CanTouch = false
	cone_template.CanQuery = false
	cone_template.Anchored = true
	cone_template.CFrame = CFrame.new(Vector3.new(0,0,0))
	cone_template.Name = "PartOfViewCone"

	local cloned_parts = {}
	local coneCorner0: Part = nil
	for i=0, 3, 1 do 
		local angle = i * 90
		local cloned = cone_template:Clone()
		cloned.Parent = workspace
		cloned.CFrame = cone_template.CFrame * CFrame.Angles(0, math.rad(360-angle), 0)
		cloned.Name = cloned.Name .. tostring(i)
		if i == 0 then coneCorner0 = cloned continue end
		cloned_parts[i] = cloned
	end

	local diff = config.enemy_head.CFrame.Position.Y - config.enemy_hrt.CFrame.Position.Y + config.enemy_human.HipHeight + config.enemy_hrt.Size.Y / 2

	coneCorner0.CFrame 	   = coneCorner0.CFrame 	+ Vector3.new(-cone_side_length / 2, 0, cone_side_length / 2 + diff / 2)
	cloned_parts[1].CFrame = cloned_parts[1].CFrame + Vector3.new(-cone_side_length / 2, 0,-cone_side_length / 2 - diff / 2)
	cloned_parts[2].CFrame = cloned_parts[2].CFrame + Vector3.new(cone_side_length / 2, 0, -cone_side_length / 2 - diff / 2)
	cloned_parts[3].CFrame = cloned_parts[3].CFrame + Vector3.new(cone_side_length / 2, 0, cone_side_length / 2 + diff / 2)

	local wedgeLeft = Instance.new("Part")
	wedgeLeft.Shape			= Enum.PartType.Wedge
	wedgeLeft.Size			= Vector3.new(config.enemy_human.HipHeight + config.enemy_hrt.Size.Y * 2, config.detectionRange * 2, cone_side_length)
	wedgeLeft.Transparency 	= 0.5
	wedgeLeft.Material 		= Enum.Material.SmoothPlastic
	wedgeLeft.Color 		= BrickColor.Red().Color
	wedgeLeft.CanCollide 	= false
	wedgeLeft.CanTouch 		= false
	wedgeLeft.CanQuery 		= false
	wedgeLeft.Anchored 		= true
	wedgeLeft.CFrame 		= CFrame.new(Vector3.new(-cone_side_length / 2, 0, 0)) * CFrame.Angles(0, math.rad(90), 0)
	wedgeLeft.Name 			= "PartOfViewCone4"
	wedgeLeft.Parent 		= workspace

	local wedgeRight = wedgeLeft:Clone()
	wedgeRight.Parent		= workspace
	wedgeRight.Name			= "PartOfViewCone5"
	wedgeRight.CFrame 		= CFrame.new(cone_side_length / 2,0,0) * CFrame.Angles(0, math.rad(270), 0)

	table.insert(cloned_parts, wedgeLeft)
	table.insert(cloned_parts, wedgeRight)

	local union: UnionOperation = coneCorner0:UnionAsync(cloned_parts)
	union.CFrame = CFrame.new(Vector3.new(0,0,0))
	union.Parent = workspace
	cone_template:Destroy()

	coneCorner0:Destroy()
	for i, v in pairs(cloned_parts) do v:Destroy() end

	local distanceBall = Instance.new("Part")
	distanceBall.Shape			= Enum.PartType.Ball
	distanceBall.Size			= Vector3.new(config.detectionRange * 2, config.detectionRange * 2, config.detectionRange * 2)
	distanceBall.Transparency 	= 0.5
	distanceBall.Color 			= BrickColor.Red().Color
	distanceBall.Material 		= Enum.Material.SmoothPlastic
	distanceBall.CanCollide 	= false
	distanceBall.CanTouch 		= false
	distanceBall.CanQuery 		= false
	distanceBall.Anchored 		= true
	distanceBall.Parent 		= workspace
	distanceBall.CFrame 		= CFrame.new(Vector3.new(0, 0, config.detectionRange + diff / 2))

	local distanceBall2 = distanceBall:Clone()
	distanceBall2.Parent		= workspace
	distanceBall2.CFrame 		= CFrame.new(Vector3.new(0, 0, config.detectionRange - diff / 2))

	local rectangle = Instance.new("Part")
	rectangle.Shape			= Enum.PartType.Cylinder
	rectangle.Size			= Vector3.new(diff , config.detectionRange * 2, config.detectionRange * 2)
	rectangle.Transparency 	= 0.5
	rectangle.Material 		= Enum.Material.SmoothPlastic
	rectangle.Color 		= BrickColor.Red().Color
	rectangle.CanCollide 	= false
	rectangle.CanTouch 		= false
	rectangle.CanQuery 		= false
	rectangle.Anchored 		= true
	rectangle.CFrame 		= CFrame.new(Vector3.new(0, 0, config.detectionRange)) * CFrame.Angles(0, math.rad(90), 0)
	rectangle.Parent 		= workspace

	local unionSphere: UnionOperation = distanceBall:UnionAsync({distanceBall2, rectangle})
	unionSphere.CFrame 		= CFrame.new(Vector3.new(0, config.detectionRange, 0))
	unionSphere.Name		= "UnionSphere"
	unionSphere.Parent 		= workspace

	distanceBall:Destroy()
	distanceBall2:Destroy()
	rectangle:Destroy()

	local intersect: UnionOperation = unionSphere:IntersectAsync({union})
	intersect.Material 		= Enum.Material.SmoothPlastic
	intersect.Color 		= BrickColor.Red().Color
	intersect.CanCollide 	= false
	intersect.Massless 		= true
	intersect.CanTouch 		= false
	intersect.CanQuery 		= false
	intersect.Anchored 		= false
	intersect.CFrame 		= config.enemy_hrt.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	intersect.CFrame		= intersect.CFrame:ToWorldSpace(CFrame.new(Vector3.new(0,-config.detectionRange / 2,0))) -Vector3.new(0, config.enemy_hrt.Size.Y / 2)
	intersect.Parent 		= config.enemy_hrt

	union:Destroy()
	unionSphere:Destroy()


	local weld_constraint = Instance.new("WeldConstraint")
	weld_constraint.Part0 = config.enemy_hrt
	weld_constraint.Part1 = intersect
	weld_constraint.Name = "Forbidden-ConeVisualizationWeld"
	weld_constraint.Enabled = true
	weld_constraint.Parent = config.enemy_hrt
end

API.VisualizeLimitChase = function()
	local visualizedFolder 	= Instance.new("Folder")
	visualizedFolder.Name		= "Visualized Chase Range"
	visualizedFolder.Parent		= config.enemy_char

	--print(visualizedFolder)

	local function makeVisualizedCylinderWithSize(size)
		local cylinder = Instance.new("Part")
		cylinder.Material		= Enum.Material.SmoothPlastic
		cylinder.Shape			= Enum.PartType.Cylinder
		cylinder.Size			= Vector3.new(0.25, size, size) * 2
		cylinder.Transparency 	= 0.5
		cylinder.Parent			= visualizedFolder
		cylinder.Anchored 		= true
		cylinder.CanCollide 	= false
		cylinder.Massless 		= true
		return cylinder
	end

	local location 	= config.enemy_hrt.CFrame.Position - Vector3.new(0, config.enemy_human.HipHeight + config.enemy_hrt.Size.Y / 2 - 0.125, 0)
	local rot 		= CFrame.Angles(0, 0, math.rad(90))

	local startChaseCylinder 	= makeVisualizedCylinderWithSize(config.detectionRange)
	startChaseCylinder.Name		= "StartChaseCylinder"
	startChaseCylinder.Color	= BrickColor.Red().Color
	startChaseCylinder.CFrame 	= CFrame.new(location + Vector3.new(0,0.5,0)) * rot

	local maxChaseCylinder 		= makeVisualizedCylinderWithSize(config.MaxChaseRange)
	maxChaseCylinder.Name		= "MaxChaseCylinder"
	maxChaseCylinder.Color		= BrickColor.Green().Color
	maxChaseCylinder.CFrame 	= CFrame.new(location + Vector3.new(0,0,0)) * rot

	startChaseCylinder.Anchored = false
	maxChaseCylinder.Anchored 	= false

	local weldsForVisualizationFolder = Instance.new("Folder")
	weldsForVisualizationFolder.Name	= "Forbidden-WeldsForVisualization"
	weldsForVisualizationFolder.Parent 	= config.enemy_hrt

	local weld1 = Instance.new("WeldConstraint")
	weld1.Name 		= "Weld1"
	weld1.Part0 	= config.enemy_hrt
	weld1.Part1 	= startChaseCylinder
	weld1.Parent 	= weldsForVisualizationFolder
	weld1.Enabled	= true

	local weld2 = Instance.new("WeldConstraint")
	weld1.Name 		= "Weld2"
	weld2.Part0 	= config.enemy_hrt
	weld2.Part1 	= maxChaseCylinder
	weld2.Parent 	= weldsForVisualizationFolder
	weld2.Enabled	= true
end

return API