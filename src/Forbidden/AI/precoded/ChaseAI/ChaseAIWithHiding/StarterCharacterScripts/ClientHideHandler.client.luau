-- Services
local UIS 					= game:GetService("UserInputService")
local rs 					= game:GetService("ReplicatedStorage")
-- Objects
local lockers 				= workspace:WaitForChild("Interactables"):WaitForChild("Lockers")
local char					= script.Parent
local hrt 					= char:WaitForChild("HumanoidRootPart")
local human					= char:WaitForChild("Humanoid")

-- Signals
local remotes				= rs:WaitForChild("signals"):WaitForChild("remotes")

local RE_HideEvent			= remotes:WaitForChild("events"):WaitForChild("HideEvent")
local RF_RequestLocker		= remotes:WaitForChild("functions"):WaitForChild("RequestLocker")

local ContextActionService = game:GetService("ContextActionService")
local FREEZE_ACTION = "freezeMovement"

-- Settings
local hideButtons 			= {
	Enum.KeyCode.E,
	--Enum.KeyCode.R,
	Enum.UserInputType.MouseButton1,
	--Enum.UserInputType.Gamepad2,
}
local interactDistance 		= 5
local enterTime				= 0.1
local exitTime				= 0.1



-- Hook
local function beganHiding(locker: Model)
	-- play animations and sfx here!
end

local function stoppedHiding(locker: Model)
	-- play animations and sfx here!
end


-- Variables
local isHiding = false
local currentLocker = nil

local db = false

local function hide()
	if db then return end

	-- STARTING TO HIDE
	if not isHiding then

		for i, locker in pairs(lockers:GetChildren()) do
			local dist = (locker.PrimaryPart.Position - hrt.Position).Magnitude
			if dist <= interactDistance then

				local isAvailableObj = locker:WaitForChild("isAvailable")
				if isAvailableObj == nil then error("Could not find isAvailable bool object in the locker!") end

				if not isAvailableObj.Value then continue end -- try to find an open locker.

				isHiding = true
				beganHiding(locker)
				currentLocker = locker

				db = true
				task.wait(enterTime)
				db = false

				RE_HideEvent:FireServer(true, currentLocker)
				-- To freeze
				ContextActionService:BindAction(
					FREEZE_ACTION,
					function() return Enum.ContextActionResult.Sink end,
					false,
					unpack(Enum.PlayerActions:GetEnumItems())
				)

				break

			end
		end

		return
	end

	-- STOPPING HIDE
	if isHiding then

		isHiding = false
		stoppedHiding(currentLocker)

		db = true
		task.wait(enterTime)
		db = false

		RE_HideEvent:FireServer(false, currentLocker)
		currentLocker = nil
		-- To unfreeze
		ContextActionService:UnbindAction(FREEZE_ACTION)


		return
	end
end

local function inputBegan(input: InputObject, chat)
	
	if chat then return end
	
	-- Mouse / Gamepad Handler
	if input.KeyCode == Enum.KeyCode.Unknown then
		for i, v in pairs(hideButtons) do
			if v.EnumType ~= input.UserInputType.EnumType then continue end -- if it is Keyboard related
			if v == input.UserInputType then
				hide()
				return -- stop duplicate execution
			end
		end
	end
	
	-- Keyboard Handler
	if input.KeyCode ~= Enum.KeyCode.Unknown then
		for i, v in pairs(hideButtons) do
			if v.EnumType ~= input.KeyCode.EnumType then continue end
			if v == input.KeyCode then
				hide()
				return -- stop duplicate execution
			end
		end
	end
end

-- Called twice, 	 isCaught is false whenever the AI is approaching the locker, but true whenever the AI has reached the locker. 
local function hideEventFired(isCaught: boolean)

	if not isCaught then return end

	-- player was caught, maybe do some cool stuff here (on the client).
end

local function RequestLocker()
	return currentLocker
end

local function playerDied()
	-- To unfreeze
	ContextActionService:UnbindAction(FREEZE_ACTION)

end

UIS.InputBegan:Connect(inputBegan)
RE_HideEvent.OnClientEvent:Connect(hideEventFired)
RF_RequestLocker.OnClientInvoke = RequestLocker
human.Died:Connect(playerDied)

---- To freeze
--ContextActionService:BindAction(
--	FREEZE_ACTION,
--	function() return Enum.ContextActionResult.Sink end,
--	false,
--	unpack(Enum.PlayerActions:GetEnumItems())
--)


---- To unfreeze
--ContextActionService:UnbindAction(FREEZE_ACTION)
