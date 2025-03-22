-- Services
local rs = game:GetService("ReplicatedStorage")
local players = game:GetService("Players")

-- Signals
local RE_HideEvent = rs:WaitForChild("signals"):WaitForChild("remotes"):WaitForChild("events"):WaitForChild("HideEvent")

local lockers = {} -- if a player leaves, this tracks the locker they could be in and clears it!

local function onHideEvent(player: Player, hide: boolean, locker: Model)
	local hideValue = player:WaitForChild("TemporaryValues"):WaitForChild("isHiding")
	
	hideValue.Value = hide
	
	if hide then
		
		local char = player.Character
		if char == nil then error("Character is nil!") end 
		
		local tpToPart = locker:WaitForChild("floor")
		if tpToPart == nil then error("Could not find floor to TP to!") end
		
		local yRotVal = tpToPart:WaitForChild("PlayerYRotation")
		if yRotVal == nil then error("Could not find PlayerYRotation value inside of the tp part!") end
		
		local isAvailableObj = locker:WaitForChild("isAvailable")
		if isAvailableObj == nil then error("Could not find isAvailable bool object inside of the locker!") end
		if not isAvailableObj.Value then return end -- The locker is full!
		
		local hrt = char:WaitForChild("HumanoidRootPart")
		hrt.CFrame = (CFrame.new(0, 3 + tpToPart.Size.Y / 2, 0) + tpToPart.Position) * CFrame.Angles(0, math.rad(yRotVal.Value), 0) -- 3 is standard humanoid height.
		
		lockers[player.UserId] = locker
		isAvailableObj.Value = false
		
		return
	end
	
	if not hide then
		
		local char = player.Character
		if char == nil then error("Character is nil!") return end
		
		local tpToPart = locker:WaitForChild("front")
		if tpToPart == nil then error("Could not find floor to TP to!") end
		
		local yRotVal = tpToPart:WaitForChild("PlayerYRotation")
		if yRotVal == nil then error("Could not find PlayerYRotation value inside of the tp part!") end
		
		local isAvailableObj = locker:WaitForChild("isAvailable")
		if isAvailableObj == nil then error("Could not find isAvailable bool object inside of the locker!") end
		
		local hrt = char:WaitForChild("HumanoidRootPart")
		hrt.CFrame = (CFrame.new(0, 3 + tpToPart.Size.Y / 2, 0) + tpToPart.Position) * CFrame.Angles(0, math.rad(yRotVal.Value), 0) -- 3 is standard humanoid height.
		
		lockers[player.UserId] = nil
		isAvailableObj.Value = true
		
		return
	end
end

local function characterAdded(char: Model)
	
	local player = players:FindFirstChild(char.Name)
	if player == nil then error("Could not find player from character!") end
	
	local isHidingObj = player:WaitForChild("TemporaryValues"):WaitForChild("isHiding")
	isHidingObj.Value = false
	
	local human = char:WaitForChild("Humanoid")
	human.Died:Connect(function()
		if lockers[player.UserId] ~= nil then
			local isAvailableObj = lockers[player.UserId]:WaitForChild("isAvailable")
			if isAvailableObj == nil then error("Could not find isAvailable bool object inside the locker!") end
			isAvailableObj.Value = true
		end
	end)
end

-- Connect Reset.
local function giveTemporaryValues(player: Player)
	local tV = player:FindFirstChild("TemporaryValues")
	if tV == nil then 
		tV = Instance.new("Folder")
		tV.Name = "TemporaryValues"
		tV.Parent = player
	end
	
	local isHidingObj = Instance.new("BoolValue")
	isHidingObj.Name = "isHiding"
	isHidingObj.Value = false
	isHidingObj.Parent = tV
	
end

local function attachCharAdded(player: Player)
	player.CharacterAdded:Connect(characterAdded)
end

for i, plr in pairs(players:GetChildren()) do 
	giveTemporaryValues(plr)
	attachCharAdded(plr)
end

players.PlayerAdded:Connect(function(plr: Player) 
	giveTemporaryValues(plr)
	attachCharAdded(plr)
end)

players.PlayerRemoving:Connect(function(player: Player) -- Clear up the lockers whenever a player leaves !
	if lockers[player.UserId] ~= nil then
		local isAvailableObj = lockers[player.UserId]:WaitForChild("isAvailable")
		if isAvailableObj == nil then error("Could not find isAvailable bool object inside the locker!") end
		isAvailableObj.Value = true
	end
end)

RE_HideEvent.OnServerEvent:Connect(onHideEvent)