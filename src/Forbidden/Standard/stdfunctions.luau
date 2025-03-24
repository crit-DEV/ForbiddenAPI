local API = {}

local Debug = true

local function log(str: any)
	
	if Debug then
		print(str)
	end
end

API.GetType = function(Variable: any): any
	
	-- Should not be used for scripts that are on loops. Only exists for the Forbidden
	-- library so I can reliably detect everything on things that aren't looped without making it unreadable. 
	-- (i.e. GetPlayer function allowing basically any data type)
	
	if typeof(Variable) == "Instance" then

		if Variable:IsA("Player") then return "Player" end
		if Variable:IsA("GuiBase") then return "GUI" end
		if Variable:IsA("BasePart") then return "Part" end
		if Variable:IsA("Model") then return "Model" end
		if Variable:IsA("ValueBase") then return "Value" end
		if Variable:IsA("BaseScript") then return "Script" end
	end
	
	if typeof(Variable) == "table" then -- tables/metatables filtered inside statement

		if getmetatable(Variable) ~= nil then return "metatable" end -- detects metatables, returns nil if none present.

		return "table"
	end
	return typeof(Variable)
end

API.Teleport = function(playerOrCharacter, destination: any, yOffset: number)
	
	local PLR_Type = API.GetType(playerOrCharacter)
	local DEST_TYPE = API.GetType(destination)
	
	local plr_final_part = nil
	local dest_final_info = nil
	
	
	-- affectee standardization
	if PLR_Type == "Player" then
		
		plr_final_part = playerOrCharacter.Character.PrimaryPart
	end
	
	if PLR_Type == "Model" then
		
		plr_final_part = playerOrCharacter.PrimaryPart
	end
	
	if plr_final_part == nil then error("Failed!") return false end
	
	
	
	-- destination standardization
	if DEST_TYPE == "Model" then
		
		dest_final_info = destination.PrimaryPart.CFrame
	end
	
	if DEST_TYPE == "Part" then
		
		dest_final_info = destination.CFrame
	end
	
	if DEST_TYPE == "Vector3" then
		
		dest_final_info = CFrame.new(destination)
	end
	
	if DEST_TYPE == "CFrame" then
		
		dest_final_info = destination
	end
	
	if dest_final_info == nil then error("Failed!") return false end
	
	
	
	--- function code below
	
		
	plr_final_part.CFrame = CFrame.new(dest_final_info.X, dest_final_info.Y+yOffset,dest_final_info.Z)
	
	return true
end

-- @Deprecated
-- if you do, (Yields = false), it returns the track so you can stop it.
API.Animate = function(NPC: Model, AnimId: number, Yields: boolean)
	
	local humanoid = NPC.Humanoid
	local animator = humanoid:FindFirstChild("Animator")
	
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	
	local base = "rbxassetid://"
	local id = tostring(AnimId)
	
	local finalId = base..id
	
	local animation = Instance.new("Animation")
	animation.Parent = animator
	animation.AnimationId = finalId
	
	local track = animator:LoadAnimation(animation)
	
	if Yields then
		track:Play()
		track.Ended:Wait()
	end
	
	if not Yields or Yields == nil then
		track:Play()
	end
	
	return track
end

return API