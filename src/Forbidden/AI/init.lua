local API = {}

-- [ Services ] --
local rs = game:GetService("ReplicatedStorage")
local pfservice = game:GetService("PathfindingService")
local debris = game:GetService("Debris")

-- [ Dependencies ] --
local Forbidden = rs:WaitForChild("Forbidden")
local std = require(Forbidden:WaitForChild("Standard"))

local processes = {}

-- [ Signals ] --
local signals = script:WaitForChild("signals")
local stopAI = signals:WaitForChild("StopAI")

-- [ Type Definitions ] --
type RaycastSettings = {range: number, SeeThroughTransparentParts: boolean, filterTable: {}}
type SmartPathfindSettings = {

	-- see https://create.roblox.com/docs/characters/pathfinding
	StandardPathfindSettings: {
		AgentRadius: number,
		AgentHeight: number,
		AgentCanJump: number,
		AgentCanClimb: boolean,
		Cost: {}
	},
	-- other settings.
	Visualize: boolean, 
	Tracking: boolean, 
	SwapMovementMethodDistance: number, 
		SMMD_RaycastParams: RaycastSettings, 
	RetrackTimer: number, 
	SkipToWaypoint: number, 
	PathfindStopType: "API.PathfindStopType"?, 
	StopTimer: number, 
	PredictiveMoveTo: number,
	TargetPositionOffset: Vector3,
	CollinearTargetPositionOffset: number,
	-- hooks for functionability.
	Hooks: {
		UsingMoveToLogic: (location: Vector3) -> nil,
		--PathfindLoaded: () -> nil,
		ComputedWaypoints: (waypoints: {PathWaypoint}) -> nil,
		WaypointsFolderCreated: (waypointsFolder: Folder) -> nil,
		MovingToWaypoint: (waypoint: PathWaypoint) -> nil,
		GoalReached: (goal: any) -> nil,
		UnableToPath: (goal: any, message: string) -> nil,
		Stuck: (goal: any, waypoint: PathWaypoint) -> nil,
		PathfindingLinkReached: (waypoint: PathWaypoint) -> boolean
	}
}
API.PathfindStopType = {
	LastWaypoint = 1,
	CurrentPosition = 2
}

API.PathingStates = {
	ACTIVE = 1,
	STOP = 2,
	STOPACKNOWLEDGED = 3
}

setmetatable(API.PathfindStopType, {
	__newindex = function(_, key, value)
		error("Attempt to modify read-only table")
	end
})

setmetatable(API.PathingStates, {
	__newindex = function(_, key, value)
		error("Attempt to modify read-only table")
	end
})

-- [ Assisting Functions ] --
API.Stuck = function(humanoid: Humanoid)
	-- 9/3/24 @rman501, forgot to add position of the NPC causing AI to go to ~0,0,0
	local pos = humanoid.Parent:FindFirstChild("HumanoidRootPart").CFrame.Position
	humanoid:MoveTo(Vector3.new(math.random(-3,3) + pos.X, pos.Y, math.random(-3,3) + pos.Z)) -- 9/30/24 @rman501, stuck fix, pos wasnt added.
	humanoid.Jump = true
end

local function reset(NPC)
	local human : Humanoid = NPC:FindFirstChild("Humanoid")
	if human == nil then warn("[AI.Reset] Humanoid was nil on reset.") end

	local sacp = NPC:FindFirstChild("StopAtCurrentPosition")
	if sacp ~= nil then
		-- Override the waypoint MoveTo
		task.wait(sacp.Value)
		local hrt = NPC:FindFirstChild("HumanoidRootPart")
		human:MoveTo(hrt.CFrame.p)
		return
	end

	local cW = NPC:FindFirstChild("CurrentWaypoint")
	if cW ~= nil then
		if cW.Value == Vector3.new(math.huge, math.huge, math.huge) then local hrt = NPC:FindFirstChild("HumanoidRootPart") human:MoveTo(hrt.CFrame.p)  return end -- 10/20/24 @rman501, stop from continuing to nowhere.
		human:MoveTo(cW.Value)
	end
end

-- [ Debug ] --
local doPrints = false
if doPrints then print("[DEBUG] AI") end
local function debugPrint(message: string)
	if not doPrints then return end
	print(message)
end


local function nullbind() end -- for hooks.

-- [ Functions ] --
--[[
	Starts a pathfind from the NPC to the Target.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>NPC</strong>: Character</code>
	<em>The NPC to pathfind with.</em>
	
	<code><strong>Target</strong>: any</code>
	<em>The Target to pathfind to, can be mostly anything.</em>
	
	<code><strong>Yields</strong>: boolean</code>
	<em>Whether or not the script waits for the pathfind to complete run the code after to run.</em>
	
	<code><strong>userSettings</strong>: SmartPathfindSettings</code>
	<em>A variety of settings for the user to change, documentation below.</em>
	
	<code><em>userSettings</em></code>
	
	<code><strong>StandardPathfindSettings</strong></code>: {
			AgentRadius: number, 		default: 2
			AgentHeight: number, 		default: 5
			AgentCanJump: boolean,		default: true
			AgentCanClimb: boolean,		default: true
			Cost: {},
		},
		<em>For more information, see: </em> <strong>https://create.roblox.com/docs/characters/pathfinding</strong>
		
		<code><strong>Visualize</strong>: boolean</code>
		<em>Visualizes the API</em>
		default: true
		
		<code><strong>Tracking</strong>: boolean</code> 
		<em>Tracks the target; continues till AI:Stop(NPC) or different pathfind is started.</em>
		default: false
		
		<code><strong>SwapMovementMethodDistance</strong>: number</code> SwapMovementMethodDistance
		<em>Intelligently uses distance to and the beneath line of sight settings to have more accurate close range tracking</em>
		default: 25
		
		<code><strong>SMMD_RaycastParams</strong></code>: {
			range,							default: 30 (slighty higher than SwapMovementMethodDistance)
			SeeThroughTransparentParts,		default: false
		}
		<em>When Tracking is true only.
		Stands for SwapMovementMethodDistance_RaycastParams. 
		The idea is that we can swap the movement method to a direct MoveTo system if these parameters are met.
		</em>
		
		<code><strong>RetrackTimer</strong>: number</code>
		<em>When Tracking is true only.
		How often should the AI recalculate (only when the target has moved) the pathfind.</em>
		default: 1/60
		
		<code><strong>SkipToWaypoint</strong>: number</code>, 
		<em>With repetitive recalls, sometimes the AI is too late in the recalculation and tries to go to a node behind it.
		This system skips a couple waypoints (automatically 3 when Tracking is true, unless overriden).
		Alternatively, you can set WaypointSpacing in StandardPathfindSettings.</em>
		default: 1 (Tracking: 3)
		
		<code><strong>PathfindStopType</strong>: API.PathfindStopType</code>
		<em>What kind of stop will be performed when AI.Stop() is called.</em>
		default: API.PathfindStopType.CurrentPosition
		
		<code>
			> API.PathfindStopType.CurrentPosition
			> API.PathfindStopType.LastWaypoint
		</code>
		
		<code><strong>StopTimer</strong>: number</code>
		<em>If PathfindStopType is set to CurrentPosition, then this is how long it will take for the MoveTo to be called.</em>
		default: 4/60
		
		<code><strong>PredictiveMoveTo</strong>: number</code>
		<em>When tracking (usually for players), what is the pursuit distance.</em>
		default: 0.25
		
		<code><strong>CollinearTargetPositionOffset</strong>: number</code>
		<em> Offset the pathing position by a vector of this magnitude toward the NPC.
		Keeps the AI 'x' distance away from the Target</em>
		default: 0
		
		<code><strong>TargetPositionOffset</strong>: Vector3</code>
		<em>NOT RELATIVE
		Offset the pathing position by this value.</em>
		default: (0,0,0)
		
		
	<strong>Hooks</strong>
	<em>Connect a function to these to manipulate the information in some way as it gets processed in the script (see example call below).</em>
	{
		UsingMoveToLogic: (location: Vector3) -> nil,
		ComputedWaypoints: (waypoints: {PathWaypoint}) -> nil,
		WaypointsFolderCreated: (waypointsFolder: Folder) -> nil,
		MovingToWaypoint: (waypoint: PathWaypoint) -> nil,
		GoalReached: (goal: any) -> nil,
		UnableToPath: (goal: any, message: string) -> nil,
		Stuck: (goal: any, waypoint: PathWaypoint) -> nil,
		PathfindingLinkReached: (waypoint: PathWaypoint) -> boolean -- SYNCHRONOUS, RETURN TRUE TO CONTINUE PF.
	}
	
	
	<code><em>End of userSettings</em></code>
	
	<strong>Basic Call</strong>
	<code>
		local rs = game:GetService("ReplicatedStorage")
		local forbidden = rs:WaitForChild("Forbidden")
		local ai = require(forbidden:WaitForChild("AI"))
		
		local NPC = script.Parent
		local Target = workspace:WaitForChild("Dummy")
		
		ai.SmartPathfind(NPC, Target, true, {Visualize = true})
		print("Reached dummy!")
	</code>
	
	<strong>Hooks</strong>
	<em>Normally, things happening inside the script would be unable to be seen, but hooks provide a variety of functions for the user to hook to.</em>
	<code>
		local rs = game:GetService("ReplicatedStorage")
		local forbidden = rs:WaitForChild("Forbidden")
		local ai = require(forbidden:WaitForChild("AI"))
		
		local NPC = script.Parent
		local Target = workspace:WaitForChild("Dummy")
		
		local function onUnableToPath(goal: any, message: string)
			print("Unable to path to " .. goal.Name) -- goal could also be a Vector3, CFrame, or whatever was provided.
		end
		
		ai.SmartPathfind(NPC, Target, true, {Visualize = true, Hooks = {UnableToPath = onUnableToPath}})
	</code>
]]--
API.SmartPathfind = function(NPC: any, Target: any, Yields: boolean, userSettings: SmartPathfindSettings): Enum.PathStatus?

	-- Update settings, with provided settings while keeping non-conflicting defaults.
	local pfSettings: SmartPathfindSettings = {
		StandardPathfindSettings = { -- these defaults were messed up, smh
			AgentRadius = 2, -- was 3: default 2
			AgentHeight = 5, -- was 6: default 5
			AgentCanJump = true,
			AgentCanClimb = false,
			Cost = {},
		},
		Visualize = false,
		Tracking = false, -- continues till AI:Stop(NPC) or different pathfind is started.
		SwapMovementMethodDistance = 25, -- Intelligently uses distance to and the beneath line of sight settings to have more accurate close range tracking
		SMMD_RaycastParams = {
			range = 30, -- should be slightly higher than SwapMovementMethodDistance
			SeeThroughTransparentParts = false
		},
		RetrackTimer = 1/60,
		SkipToWaypoint = 1, -- how many waypoints should it skip (-1)? For tracking this fixes the stutter bugs. Alternatively, you can alter waypoint spacing in StandardPathfindSettings.
		PathfindStopType = API.PathfindStopType.CurrentPosition, -- What kind of stop will be performed when AI.Stop() is called.
		StopTimer = 4/60, -- If PathfindStopType is set to CurrentPosition, then this is how long it will take for the MoveTo to be called.
		PredictiveMoveTo = 0.25, -- When tracking (usually for players), what is the pursuit distance.
		TargetPositionOffset = Vector3.new(0,0,0), -- Offset the pathing position by this value.
		CollinearTargetPositionOffset = 0, -- Offset the pathing position by a vector of this magnitude toward the NPC.
		Hooks = {
			UsingMoveToLogic = nullbind,
			--PathfindLoaded = nullbind,
			ComputedWaypoints = nullbind,
			WaypointsFolderCreated = nullbind,
			Stuck = nullbind,
			MovingToWaypoint = nullbind,
			GoalReached = nullbind,
			UnableToPath = nullbind,
			PathfindingLinkReached = nullbind
		}
	}
	
	if processes[NPC] == nil then processes[NPC] = {API.PathingStates.STOPACKNOWLEDGED, 0, os.clock(), false} end -- {enabledState, tokenForInitialCall, tokenForTracking, isRecalling?}

	-- bug patch 9/19/24 - if all hooks not indexed then errors due to nothing existing (hooks overriden, needs nullbinds)
	local allHooksIndexed = {}
	for i, v in pairs(pfSettings.Hooks) do
		allHooksIndexed[i] = v
	end

	if userSettings then
		for setting, v in pairs(userSettings) do
			pfSettings[setting] = v
		end

		-- If the AI is tracking, and it the SkipToWaypoint setting was not explicity set, this is a better default
		if not userSettings["SkipToWaypoint"] and pfSettings["Tracking"] then
			pfSettings["SkipToWaypoint"] = 3
		end
	end

	-- bug patch 9/19/24
	for i, v in pairs(allHooksIndexed) do
		if pfSettings.Hooks[i] ~= nil then continue end
		pfSettings.Hooks[i] = v
	end
	

	local function createNumVal()
		local numObj = Instance.new("NumberValue")
		numObj.Value = pfSettings.StopTimer
		numObj.Name = "StopAtCurrentPosition"
		numObj.Parent = NPC
	end

	local sacp = NPC:FindFirstChild("StopAtCurrentPosition")
	if sacp == nil then
		if pfSettings.PathfindStopType == API.PathfindStopType.CurrentPosition then
			createNumVal()
		end
	else -- sacp ~= nil
		if pfSettings.PathfindStopType == API.PathfindStopType.CurrentPosition then
			sacp.Value = pfSettings.StopTimer
		else -- PathfindStopType == API.PathfindStopType.LastPosition
			sacp:Destroy()
		end
	end

	local i = 0

	local enemyRoot = nil
	local enemyHuman = nil
	local targetRoot = nil

	local function updateBasedOnType(obj,type) -- if you're trying to understand this script collapse this function and IGNORE it.

		i+=1

		-- change 8/27/24: Torso support
		local function updateVars(char)

			if i == 1 then -- for tracker


				enemyRoot = char:FindFirstChild("HumanoidRootPart")
				if enemyRoot == nil then 
					enemyRoot = char:FindFirstChild("Torso")
					if enemyRoot == nil then error("Torso / HRT does not exist in char.") end
				end
				enemyHuman = char:FindFirstChild("Humanoid")
				if enemyHuman == nil then error("Could not find Humanoid. change to waitforchild to bypass") return end


			end

			-- untested, @rman501, was enemyRoot & stuff instead of target?
			if i == 2 then -- for target

				targetRoot = char:FindFirstChild("HumanoidRootPart")
				if targetRoot == nil then 
					targetRoot = char:FindFirstChild("Torso")
					if targetRoot == nil then error("Torso / HRT does not exist in char.") end
				end
			end
		end
		if (typeof(obj)) == "userdata" then -- checks for Humanoid

			if obj:IsA("Humanoid") then

				updateVars(obj.Parent)
			end
		end


		-- untested 9/23/24 @rman501, wow this was awful code. and was completely wrong !!
		if type == "Model" then -- checks to see if it is a char

			if i == 1 then

				if obj:FindFirstChild("Humanoid") then
					updateVars(obj)
				else
					error("[Forbidden.AI] Model passed but not a character or is not loaded.")
				end
			end

			if i == 2 then

				if obj:FindFirstChild("Humanoid") then
					updateVars(obj)
					return
				end

				if Target.PrimaryPart ~= nil then
					targetRoot = Target.PrimaryPart
					return
				end

				targetRoot = Target:GetChildren()[1]
				return
			end
		end
		if type == "Player" then -- checks to see if it is a player

			if obj.Character ~= nil then updateVars(obj.Character) end
			if obj.Character == nil then return "char not found" end -- protects against Players:GetChildren() loop errors
		end

		if type == "Part" then -- finds humanoid from part, if humanoid then send.
			
			-- in case of nil parent ... rare 1/17/25 @rman501
			if obj.Parent ~= nil then
				if obj.Parent:FindFirstChild("Humanoid") then

					updateVars(obj.Parent)
				end

				if obj.Parent.Parent:FindFirstChild("Humanoid") then

					updateVars(obj.Parent.Parent)
				end
			end

			if i == 1 then error("Are you sure you passed in the right part for the character, could not find a Humanoid") return end

			if i == 2 then -- for normality
				targetRoot = obj
			end
		end

		local pos = nil
		if type == "CFrame" then
			pos = obj.Position
		end

		if type == "Vector3" then
			pos = obj
		end

		if pos ~= nil then
			local modeledPart = Instance.new("Part")
			modeledPart.Size = Vector3.new(1,1,1)
			modeledPart.Anchored = true
			modeledPart.Transparency = 1
			modeledPart.Shape 		= Enum.PartType.Ball
			modeledPart.CanCollide 	= false
			modeledPart.CFrame 		= CFrame.new(pos)
			modeledPart.Name		= NPC.Name .. " Target"
			modeledPart.Parent		= NPC
			modeledPart.Color		= BrickColor.Yellow().Color
			modeledPart.Material	= Enum.Material.Neon
			if pfSettings.Visualize then modeledPart.Transparency = 0 end

			targetRoot = modeledPart
			modeledPart = nil -- for debris service
		end
	end

	if NPC ~= nil then updateBasedOnType(NPC,std.basic.GetType(NPC)) else error("Enemy/Tracker does not exist.") end
	if Target ~= nil then updateBasedOnType(Target,std.basic.GetType(Target)) else return "target not found" end
	
	--print(userSettings.StandardPathfindSettings)
	local path = pfservice:CreatePath(pfSettings.StandardPathfindSettings)
	--print(waypoints)

	-- 9/3/24 @rman501, used to support Vector3 / CFrame targets.
	local function isDataTypeTarget()
		local typeOfTarget = std.basic.GetType(Target) 
		if typeOfTarget == "CFrame" or typeOfTarget == "Vector3" then
			return true
		end

		return false
	end
	
	-- Gets a collinear point offset between the enemyRoot and the targetRoot with an offset magnitude of the CollinearTargetPositionOffset setting. 
	-- 10/24/24 @rman501, offset.
	local function getCollinearPointOffset()
		if pfSettings.CollinearTargetPositionOffset == 0 then
			return Vector3.new(0,0,0)
		end
		local cpo = enemyRoot.CFrame.Position - targetRoot.CFrame.Position
		cpo = Vector3.new(cpo.X, 0, cpo.Z)
		cpo = cpo.Unit
		cpo *= pfSettings.CollinearTargetPositionOffset
		--print(cpo)
		return cpo
	end

	-- Determine if the NPC can view the target.
	local function losCheck()
		local result
		local idtt = isDataTypeTarget() -- 9/3/24 @rman501, support Vector3 / CFrame targets.
		if not idtt then result = std.math.LineOfSight(NPC, Target, pfSettings.SMMD_RaycastParams) end
		if idtt then result = std.math.LineOfSight(NPC, enemyRoot, pfSettings.SMMD_RaycastParams) end

		if result then
			return true
		end
		
		debugPrint()

		return false
	end

	-- 9/3/24 @rman501, Celling Experimental

	--local function isSpaceEmpty(position)
	--	local agr  = pfSettings.StandardPathfindSettings.AgentRadius
	--	local region = Region3.new(position - Vector3.new(agr,agr,agr), position + Vector3.new(agr,agr,agr))
	--	return game.Workspace:IsRegion3Empty(region)
	--end

	---- Gets the nearest, unblocked area.
	--local function Celling()
	--	local targetPos = Vector3.new(0,0,0)
	--	local count = 0
	--	repeat
	--		local xoff = math.random(5,10)
	--		if math.random() > .5 then
	--			xoff = xoff * -1
	--		end
	--		local zoff = math.random(5, 10)
	--		if math.random() > .5 then
	--			zoff = zoff * -1
	--		end

	--		targetPos = Vector3.new(enemyRoot.Position.X + xoff, enemyRoot.Position.Y, enemyRoot.Position.Z + zoff)
	--		if isSpaceEmpty(targetPos) then
	--			return targetPos
	--		else
	--			targetPos = targetPos + Vector3.new(0,4,0)
	--		end

	--		if isSpaceEmpty(targetPos) then
	--			return targetPos
	--		end
	--		count = count + 1
	--	until count > 10
	--	return nil
	--end

	-- Destroy any and all waypoint folders inside of the NPC, these should be previous ones so beware of the call.
	local function destroyWP()
		for i, v in pairs(NPC:GetChildren()) do
			if v.Name == "Waypoints" then
				debris:AddItem(v, 0)
			end
		end
	end

	local function dummyGoalReached()
		local typeOfTarget = std.basic.GetType(Target) 
		if isDataTypeTarget() then
			local targetPart = NPC:FindFirstChild(NPC.Name .. " Target")
			if targetPart ~= nil then debris:AddItem(targetPart, 0) end
			targetPart = nil
			targetRoot = nil
		end
		spawn(function() pfSettings.Hooks.GoalReached(Target) end)
	end

	-- The target is reached if the Y position does not very too differently from the AI's height, and the position is about on target.
	-- unverified change 9/23/24 @rman501, no Y in 2nd test.
	local function targetReached()
		if math.abs(enemyRoot.CFrame.Position.Y - targetRoot.CFrame.Position.Y) > pfSettings.StandardPathfindSettings.AgentHeight / 2 then return false end
		local noYer = Vector3.new(enemyRoot.CFrame.Position.X, 0, enemyRoot.CFrame.Position.Z)
		local noYtr = Vector3.new(targetRoot.CFrame.Position.X, 0, targetRoot.CFrame.Position.Z)
		if (noYer - noYtr).Magnitude > 0.1 then return false end
		return true
	end

	-- Process the pathfind
	-- Concurrency: token is passed to ensure concurrency logic does not affect latest call.
	local function pathfind(token: number)
		
		local timeWhenCalled = os.clock()

		-- Supporting features.
		local VECTOR3VAL_currentWaypoint = NPC:FindFirstChild("CurrentWaypoint")
		if VECTOR3VAL_currentWaypoint == nil then VECTOR3VAL_currentWaypoint = Instance.new("Vector3Value", NPC) VECTOR3VAL_currentWaypoint.Name = "CurrentWaypoint" end
		VECTOR3VAL_currentWaypoint.Value = Vector3.new(math.huge, math.huge, math.huge)
		
		-- Move to the enemy's HRT, should be called whenever the Line of Sight check returns true and the 
		local adjustedTargetPos = nil -- update when calling anything !!
		local function moveToTargetRoot()
			
			processes[NPC][3] = timeWhenCalled -- 10/20/24 @rman501, only register this call whenever it should truly begin.
			if processes[NPC][2] == token then
				processes[NPC][4] = false
			end

			if targetRoot == nil then return end
			local tR_Pos = adjustedTargetPos

			-- 10/20/24 @rman501, whenever there was no velocity of the body, .Unit had a div by 0 error and was NaN, NaN, NaN
			local tR_Velo_Corrected = Vector3.new(targetRoot.AssemblyLinearVelocity.X, 0, targetRoot.AssemblyLinearVelocity.Z)
			local tR_Velo_Normalized = Vector3.new(0,0,0)

			if tR_Velo_Corrected ~= Vector3.new(0,0,0) then
				tR_Velo_Normalized = tR_Velo_Corrected.Unit
			end

			-- Predict the position with the normalized velocity * a magnitude of prediction.
			tR_Pos = tR_Pos + tR_Velo_Normalized * pfSettings.PredictiveMoveTo

			local function JumpCondition() 
				-- tR_Pos.Y  - enemyRoot.CFrame.Position.Y  > 2 and 
				if enemyRoot.AssemblyLinearVelocity.Magnitude < enemyHuman.WalkSpeed * .33 and (tR_Pos - enemyRoot.CFrame.Position).Magnitude > 2 then -- 10/21/24 @rman501, kinda allows wall hugging
					return true
				end 
				
				return false
			end

			-- 10/20/24 @rman501, Jump if enabled.
			-- Jump only when appearing to be stuck and double check.
			if pfSettings.StandardPathfindSettings["AgentCanJump"] then
				if JumpCondition() then
					delay(1/10, function() if JumpCondition() then enemyHuman.Jump = true end end)
				end
			end

			--print("this shit: " .. tostring(tR_Pos))
			enemyHuman:MoveTo(tR_Pos)
			spawn(function() pfSettings.Hooks.UsingMoveToLogic(tR_Pos) end) -- 10/21/24 @rman501, hook for when MoveToLogic is used.
		end
		
		-- Initial test, is the target in line of sight ?
		if (enemyRoot.CFrame.Position - targetRoot.CFrame.Position).Magnitude < pfSettings.SwapMovementMethodDistance then 
			if pfSettings.Tracking and losCheck() then
				adjustedTargetPos = targetRoot.CFrame.Position + pfSettings.TargetPositionOffset + getCollinearPointOffset()
				moveToTargetRoot()
				if targetReached() then spawn(dummyGoalReached) end
				return Enum.PathStatus.Success
			end
		end

		
		-- updaet adjTargetPos
		adjustedTargetPos = targetRoot.CFrame.Position + pfSettings.TargetPositionOffset + getCollinearPointOffset()
		-- If in air, get point on ground for compute. (credit: Roblox's Zombie AI sys) -- Change 8/27/24 @rman501
		local function getGroundedPoint(part: BasePart, ignoreModel: Model?, useAdjRoot: boolean)
			
			-- 10/24/24 @rman501, added adjustedTargetPos.
			local raycastParams = RaycastParams.new()
			local filterTable = {NPC}
			raycastParams.FilterDescendantsInstances = filterTable
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			raycastParams.RespectCanCollide = true
			
			local posToTarget = part.CFrame.Position
			if useAdjRoot then
				posToTarget = adjustedTargetPos
			end
			local result = workspace:Raycast(adjustedTargetPos, Vector3.new(0, -1, 0) * 100, raycastParams)
			if result == nil then return nil end -- 10/26/24 @rman501, edge case.
			if result.Instance then
				--print(part.CFrame.Position - hitPoint)
				return result.Position + Vector3.new(0,2,0) -- 8/31/24 add slight y offset
			end
		end

		-- 10/24/24 @rman501, added adjustedTargetPos.
		local function groundingHandler(part: Instance, useAdjRoot: boolean)

			-- Has Character Route
			-- @rman501 1/17/25: nil parent protection
			local human = nil
			if part.Parent ~= nil then
				human = part.Parent:FindFirstChild("Humanoid")
			end
			if human then
				local humanoidState = human:GetState()
				if humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
					local result = getGroundedPoint(part, part.Parent, useAdjRoot)
					if result then return result end
					if not result and useAdjRoot then return adjustedTargetPos end
					return part.CFrame.Position
				end
				return part.CFrame.Position
			end

			-- One Off Route
			local result = getGroundedPoint(part, part, useAdjRoot)
			if result then return result end
			if not result and useAdjRoot then return adjustedTargetPos end
			return part.CFrame.Position
		end

		-- In order to ensure the AI can always path :)
		local erp = groundingHandler(enemyRoot, false)
		local trp = groundingHandler(targetRoot, false)
		local trp_adj = groundingHandler(targetRoot, true)

		-- Compute the pathfind and get the waypoints.
		-- 10/25/24 -- try to compute adjustedTargetPos path first.
		path:ComputeAsync(erp,trp_adj)
		if path.Status == Enum.PathStatus.NoPath and adjustedTargetPos ~= targetRoot.CFrame.Position then
			path:ComputeAsync(erp,trp)
		end
		local waypoints = path:GetWaypoints()

		-- Was path generation a failure ?
		if path.Status == Enum.PathStatus.NoPath then 
			warn("No path could be found. This is an issue with Roblox, not Forbidden. The NPC might also not be able to fit where the waypoint is, please see 'AgentRadius' ") 
			spawn(function () pfSettings.Hooks.UnableToPath(Target, Enum.PathStatus.NoPath.Name .. ": Roblox's API could not find a solution.") end)
			return Enum.PathStatus.NoPath  -- ensures the previous best path is not overrided.
		end -- if no possible path.


		-- Generate physical waypoints.
		local thisFolder = nil
		if path.Status == Enum.PathStatus.Success then
			
			-- Concurrent execution for the script to run better.
			local folder = Instance.new("Folder")
			folder.Name = "Waypoints"

			spawn(function()

				for i, waypoint in ipairs(waypoints) do

					local part = Instance.new("Part")
					part.Shape = Enum.PartType.Ball
					part.Color = Color3.new(0.384314, 0.341176, 1)
					part.Material = Enum.Material.Neon
					part.CFrame = CFrame.new(waypoint.Position)
					part.Parent = folder
					part.Name = i
					part.Anchored = true
					part.Size = Vector3.new(1,1,1)
					part.CanCollide = false

					if not pfSettings.Visualize then
						part.Transparency = 1
					end

				end

				thisFolder = folder
				pfSettings.Hooks.ComputedWaypoints(waypoints)

			end)
		else
			spawn(function() pfSettings.Hooks.UnableToPath(Target, path.Status.Name) end)
			API.Stuck(enemyHuman) -- possibility?
		end

		-- 9/3/24 @rman501 - Prevent folder from not being not instantiating.
		
		spawn(function()
			destroyWP()

			local limit = 300
			local thisIt = 0
			while thisFolder == nil do thisIt+=1 if thisIt > limit then pfSettings.Hooks.UnableToPath(Target, "Folder not instantiated.") error("[Forbidden.AI] Folder did not instantiate.") end task.wait() end
			thisFolder.Parent = NPC
			pfSettings.Hooks.WaypointsFolderCreated(thisFolder)
		end)

		local firstWP = pfSettings.SkipToWaypoint
		local wasPathing = true
		
		--print(waypoints)
		--print(waypoints)
		local function loopWP()
			
			processes[NPC][3] = timeWhenCalled -- 10/20/24 @rman501, only register this call whenever it should truly begin.
			if processes[NPC][2] == token then -- 10/20/24 @rman501, let the API know the next call loaded.
				processes[NPC][4] = false
			end
			
			--local iReached = 0
			for i, wp: PathWaypoint in ipairs(waypoints) do

				--iReached = i
				-- Ensure the waypoint still needs to be followed.
				if processes[NPC][1] == API.PathingStates.STOP then 
					--print("1")
					wasPathing = false 
					break 
				end
				
				-- If a new concurrent call was made and loaded allow it to run. (this is for a new call to the actual API itself)
				if processes[NPC][2] ~= token and not processes[NPC][4] then
					--print("2")
					wasPathing = false
					break
				end
			
				-- ensure 2 pathfinds are not running at once. (this is for a call like tracking where the token is the same.)
				if processes[NPC][3] ~= timeWhenCalled and not processes[NPC][4] then
					--print("3")
					wasPathing = false
					break
				end
				
				-- CUSTOM, pf link
				-- 2/28/25 @rman501, added custom waypoints, pf link support
				if wp.Action == Enum.PathWaypointAction.Custom then
					local pflink_result = pfSettings.Hooks.PathfindingLinkReached(wp)
					if pflink_result == 2 then return end
					if pflink_result then
						continue
					end
					error("Provide inside of hooks a custom, PathfindingLinkReached, function. PathfindingLinkReached(wp: PathWaypoint) -> boolean, return true for success, 2 for a cancel.")
				end
				
				-- Make sure the AI does not go backwards
				-- 10/21/24 @rman501, skipped waypoints would have jump ignored.
				if i < firstWP and not (firstWP > #waypoints) then if wp.Action == Enum.PathWaypointAction.Jump then enemyHuman.Jump = true print("jump") end continue end

				-- Is the AI alive ?
				if enemyHuman.Health <= 0 then break end

				-- Jump
				if wp.Action == Enum.PathWaypointAction.Jump then enemyHuman.Jump = true end

				-- Move to position and update value, so cancelling later can be done smoothly
				enemyHuman:MoveTo(wp.Position)
				spawn(function() pfSettings.Hooks.MovingToWaypoint(wp) end)
				VECTOR3VAL_currentWaypoint.Value = wp.Position

				-- Handle movement successes
				local moveSuccess = enemyHuman.MoveToFinished:Wait()
				if not moveSuccess and processes[NPC][1] == API.PathingStates.ACTIVE then -- if not successful in movement and was a result of this thread.
					-- stuck.
					warn("[Forbidden.AI] The AI was not successful in a movement: (" .. NPC.Name .. ")")
					API.Stuck(enemyHuman)
					spawn(function() pfSettings.Hooks.Stuck(wp) end)
					break
				end

			end
			
			---- If it never ran, than override the CurrentWaypoint val. (shouldnt need this tbh)
			--if iReached == firstWP then
			--	VECTOR3VAL_currentWaypoint.Value = Vector3.new(math.huge, math.huge, math.huge) 
			--end

			if not pfSettings.Tracking and wasPathing then
				spawn(dummyGoalReached)
			end

			return Enum.PathStatus.Success
		end

		-- Concurrency logic
		if processes[NPC][1] ~= API.PathingStates.ACTIVE then
			if processes[NPC][1] == API.PathingStates.STOP then
				processes[NPC][1] = API.PathingStates.STOPACKNOWLEDGED
			end
			return 
		end
		
		-- 10/21/24 @rman501, stops extraneous calls
		if processes[NPC][2] ~= token then
			return
		end
		
		if not pfSettings.Tracking then
			local status = loopWP()

			-- If reset externally, communicate that.
			if processes[NPC][1] == API.PathingStates.STOP then
				reset(NPC)
				processes[NPC][1] = API.PathingStates.STOPACKNOWLEDGED
			end
			
			-- If pathfind is done, reset (make sure it is same token) 10/21/24 @rman501, this used to conflict. solved by using token.
			if processes[NPC][2] == token then
				processes[NPC][1] = API.PathingStates.STOPACKNOWLEDGED
			end
			
			-- Let concurrency checker know it worked.
			processes[NPC][4] = false
			
			return status
		end
		
		if pfSettings.Tracking then
			spawn(loopWP)
			return Enum.PathStatus.Success
		end

	end
	
	-- Pathfind to a target, normally.
	local function pathStateEnumName(enum)
		for name, index in pairs(API.PathingStates) do
			if enum == index then
				debugPrint(name)
			end
		end
	end

	-- Track a target.
	local function track(token: number) -- token acts as an assurance it will stop.

		-- Initial Setup
		local lastPositionOfTarget = Vector3.new(math.huge, math.huge, math.huge)
		
		-- While the process remains active, chase the targeted object.
		-- Concurrency: This function actually stops, bc if target is in line of sight then it will restart quick, otherwise last pathfindwill still be used.
		while processes[NPC][1] == API.PathingStates.ACTIVE and processes[NPC][2] == token do
			-- Stop sequence when disabled or target is lost.
			if Target == nil then break end
			--if processes[NPC][1] == API.PathingStates.STOP then break end -- not needed, see condition.

			-- Has the target moved, if so, recall the pathfind to update the target.
			local targetPositionNow = std.math.Round(targetRoot.CFrame.Position)

			if targetPositionNow ~= lastPositionOfTarget then
				
				local status = pathfind(token)

				-- 9/30/24 @rman501, Tracking when NoPath is returned.
				if status == Enum.PathStatus.NoPath then
					-- new code can go here.
				end

				lastPositionOfTarget = targetPositionNow
			end

			task.wait(pfSettings.RetrackTimer)
		end
		
		--print("Call ended.")
		if processes[NPC][1] == API.PathingStates.STOP then
			processes[NPC][1] = API.PathingStates.STOPACKNOWLEDGED
		end
		processes[NPC][4] = false -- if concurrency was used, then reset it.
	end


	-- Determines the type of pathfind and handles cleanup.
	local function determiner()
		
		--[[ processes[NPC]
		
		[1] = STATE
		[2] = TOKEN
		[3] = LATEST LOADED TIME
		[4] = CONCURRENT RECALL (T/F)
		
		]]--
		
		-- Acquire token for this unique call.
		local token = processes[NPC][2] + 1
		processes[NPC][2] = token
		
		-- IF STOP WAS CALLED IN PAST, WAIT FOR IT TO REGISTER.
		if processes[NPC][1] == API.PathingStates.STOP then
			local att = 0
			while att < 100 and processes[NPC][1] == API.PathingStates.STOP do
				att += 1
				if token ~= processes[NPC][2] then return end -- no longer latest call.
				task.wait()
			end
		end
		
		if processes[NPC][1] == API.PathingStates.ACTIVE then
			-- Concurrent recall
			processes[NPC][4] = true
			
		end
		
		if processes[NPC][1] == API.PathingStates.STOPACKNOWLEDGED then
			
			-- Not a concurrent recall
			processes[NPC][1] = API.PathingStates.ACTIVE
			processes[NPC][4] = false
		end
		
		
		
		-- Start pathfinding.
		if pfSettings.Tracking then return track(token) end
		if not pfSettings.Tracking then return pathfind(token) end
	end


	-- Yield / No yield handler.
	if Yields or Yields == nil then return determiner() end
	if not Yields then spawn(determiner) return end

end

local function onStoppage(NPC)
	
	-- Ensure it needs to be stopped.
	if NPC == nil then debugPrint("NPC passed is nil") return end
	if processes[NPC] == nil then return end
	if processes[NPC][1] == API.PathingStates.STOP or processes[NPC][1] == API.PathingStates.STOPACKNOWLEDGED then return end 
	
	-- Send signal to stop.
	processes[NPC][1] = API.PathingStates.STOP

	-- Destroy any and all waypoint folders inside of the NPC, these should be previous ones so beware of the call.
	local function destroyWP()
		
		-- 10/20/24 @rman501, more effective system.
		while NPC:FindFirstChild("Waypoints") do
			debris:AddItem(NPC:FindFirstChild("Waypoints"), 0)
		end
		

		while NPC:FindFirstChild(NPC.Name .. " Target") do
			debris:AddItem(NPC:FindFirstChild(NPC.Name .. " Target"), 0)
		end
	end
	
	reset(NPC) -- bc at stop point.
	destroyWP()
end

--[[
	Stops the pathfind with the latest NPC. 
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>NPC</strong>: Character</code>
	<em>The NPC to stop.</em>
	
	<strong>Basic Call</strong>
	<code>
		local rs = game:GetService("ReplicatedStorage")
		local forbidden = rs:WaitForChild("Forbidden")
		local ai = require(forbidden:WaitForChild("AI"))
		
		local NPC = script.Parent
		local Target = workspace:WaitForChild("Dummy")
		
		print("Call started!")
		ai.SmartPathfind(NPC, Target, false, {Visualize = true})
		
		task.wait(3)
		
		print("Stopping!")
		ai.Stop(NPC)
	</code>
]]--
API.Stop = function(NPC: Model)
	onStoppage(NPC)
end

stopAI.Event:Connect(onStoppage)

return API

-- @rman501, howdy O):]