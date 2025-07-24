-- Made by crit0271, Forbidden API <3
local config		= require(script:WaitForChild("Settings"))

-- # Services
local players 			= game:GetService("Players")
local rs 				= game:GetService("ReplicatedStorage")
local run 				= game:GetService("RunService")
local debris			= game:GetService("Debris")

-- # Forbidden Modules
local int_forbidden 	= rs:WaitForChild("Forbidden")
local int_ai			= int_forbidden:WaitForChild("AI")
local forbidden			= require(int_forbidden)
local std 				= forbidden.Standard
local ai 				= forbidden.AI

-- # Settings
local _hooks_mod 		= script:WaitForChild("Hooks")
local hooks 		= require(_hooks_mod)
local common		= require(_hooks_mod:WaitForChild("Common"))

local internal_folder	= script:WaitForChild("internal")
local visualization 		= require(internal_folder:WaitForChild("VisualizationHandler"))
local targeting				= require(internal_folder:WaitForChild("Targeting"))
local PathfindingLinks		= require(script:WaitForChild("PathfindingLinks"))

-- variables (DO NOT TOUCH)
local isWandering 		= false
local isChasing 		= false
local plrChasing 		= nil
local lastCallTime		= 0
local doOptChase 		= false -- after a chase, an optimal chase will be done if active.

local creditKill 		= false
local damaged_recently 	= false

-- 10/22/24 @rman501, ai anchor point logic.
local returnToAnchorPoint	= false
local anchorPoint			= config.AnchorPoint

local badPathVictims	= {} -- tracks the players the AI cannot path to so it doesnt try to for a little while.

-- 11/3/24 @rman501, startup consolidation
local function onStartup()

	if config.AntiLag then
		if config.enemy_char:FindFirstChild("antilag") then return end

		local c_al	 = int_ai:WaitForChild("antilag"):Clone()
		c_al.Parent 	= config.enemy_char
		c_al.Enabled 	= true
	end

	-- States.
	if config.PreventAIFromSitting then
		config.enemy_human:SetStateEnabled(Enum.HumanoidStateType.Seated, false) -- prevents NPC from sitting
	end

	if config.PreventAIFromRagdolling then

		local function stateChanged()
			config.enemy_human:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
			config.enemy_human:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
			config.enemy_human:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
		end

		config.enemy_human.StateChanged:Connect(stateChanged)
	end
end




-- User Defineable Functions

-- 10/18/24 @rman501, debug prints function.
local doPrints = false
if doPrints then
	print("[ChaseAI] Debug Prints")
end
local function debugPrint(message: any)
	if not doPrints then return end
	print(message)
end

local function isValidTarget(Player: Player)
	local plr_char = Player.Character
	if plr_char == nil then return false end

	local plr_hrt = plr_char:FindFirstChild("HumanoidRootPart")
	if plr_hrt == nil then return false end

	local plr_human = plr_char:FindFirstChild("Humanoid")
	if plr_human == nil then return false end

	return true
end

-- disables AI for a while it is killing (if enabled)
local function damage_delay_handler()

	creditKill = true -- if the player is lost and it doesnt think it killed it (based on this variable) then it will call LostPlayer
	damaged_recently = true

	if config.disableAIWhileDamaging then
		spawn(function()
			hooks.In.PauseAI(config.damageDelay)
			task.wait(config.damageDelay)
			damaged_recently = false
		end)
	end

	if not(config.disableAIWhileDamaging) then
		spawn(function()
			task.wait(config.damageDelay)
			damaged_recently = false
		end)
	end
end


-- Called if a player that is not targeted is touched.
local function TouchedOther(other_plr_char: Model)
	spawn(function() hooks.Out.TouchedOtherPlayer(other_plr_char) end)
end

-- Called when the targeted player is touched.
local function Damage(player: Player)


	if damaged_recently then return end
	if not config.isActive then return end


	local plr_char = player.Character
	if plr_char == nil then return end
	if plr_char.Name ~= plrChasing.Name then return end -- redundant


	local plr_human = plr_char.Humanoid
	if plr_human.Health <= 0 then return end

	-- Damage player, SFX, animations, etc...
	plr_human.Health -= config.damageDone

	spawn(function() hooks.Out.TouchedTargetPlayer(player.Character) end) -- ignore error

	damage_delay_handler() -- mandatory ...

	if plr_human.Health <= 0 then
		-- player is dead now.
	end
end

-- t3's purpose is for char.tool.Handle
local function partDescendantOfChar(part) -- HELPER FOR TOUCH HANDLER

	local t1 = part.Parent
	local t2 = nil
	local t3 = nil
	if t1 ~= nil then
		t2 = t1.Parent
		if t2 ~= nil then
			t3 = t2.Parent
		end
	end

	if t1 ~= nil then
		if t1:FindFirstChild("Humanoid") then return t1 end
	else
		return false
	end

	if t2 ~= nil then
		if t2:FindFirstChild("Humanoid") then return t2 end
	else
		return false
	end

	if t3 ~= nil then
		if t3:FindFirstChild("Humanoid") then return t3 end
	else
		return false
	end

	return false

end

-- Determines if a player was touched
local function touchHandler(hit) -- HELPER

	if not config.isActive then return end

	local char = partDescendantOfChar(hit)
	if not(char) then return end

	local player = players:FindFirstChild(char.Name)
	if player == nil then return end

	local plr_human = char:FindFirstChild("Humanoid")
	if plr_human == nil then return end
	if plr_human.Health <= 0 then return end

	if player == plrChasing then
		Damage(plrChasing)
	else
		TouchedOther(char)
	end

end

-- During the continous loop to ensure the player should still be chased, your own input. If false, it stops.
local function ContinueChasing(TargetedPlayer: Player)

	
	-- 10/22/24 @rman501, limit AI Chase range
	if not isValidTarget(TargetedPlayer) then return end
	
	local char = TargetedPlayer.Character
	if char == nil then return false end
	
	local plr_human = char:FindFirstChild("Humanoid")
	if plr_human.Health <= 0 then return false end
	
	local plr_hrt = char:FindFirstChild("HumanoidRootPart")
	if plr_hrt == nil then return false end
	
	-- 6/15/25 @rman501, chasing hook never called
	if not hooks.Out.ContinueChasing(TargetedPlayer) then return false end

	if config.LimitChaseRange then

		if config.MeasureChaseRangeFromWhereStarted then
			if (plr_hrt.CFrame.Position - anchorPoint).Magnitude > config.MaxChaseRange then
				return false
			end
		end

		if not config.MeasureChaseRangeFromWhereStarted then
			if common.GetDistanceToPlayer(TargetedPlayer) > config.MaxChaseRange then
				return false
			end
		end
	end

	return true -- for no effect.
end

-- CALLED WHENEVER THE AI STARTS TO CHASE A PLAYER
local function PlayerChaseBegan(TargetedPlayer: Player)

	-- 10/22/24 @rman501, movable targeting sys
	if config.doWander or not config.MeasureChaseRangeFromWhereStarted then
		anchorPoint = config.enemy_hrt.CFrame.Position
	end 
	returnToAnchorPoint = true
	if config.MeasureChaseRangeFromWhereStarted and config.Visualize then
		visualization.unweldVisualParts()
	end

	spawn(function() 
		hooks.Animator.MotionActivated()
		hooks.Out.PlayerChaseBegan(TargetedPlayer) 
	end)

	return true -- for no effect
end

-- If you want ConfirmPlayerLost, you will need to go to Chase, due to a variety of reasons for the player to be lost.

-- CALLED WHENEVER THE AI LOSES THE TARGETED PLAYER!
local function LostPlayer(TargetedPlayer: Player, overrideNetworkReset: boolean)

	creditKill = false
	config.enemy_human.WalkSpeed = config.wanderSpeed
	
	if config.MeasureChaseRangeFromWhereStarted and config.Visualize then
		visualization.weldVisualParts()
	end

	spawn(function()
		if not config.doWander and not (config.LimitChaseRange) then hooks.Animator.MotionStopped() end -- if it is not going to wander, then stop animations
		hooks.Out.PlayerChaseEnded(TargetedPlayer) 
	end)

	local char = TargetedPlayer.Character
	if char == nil then return end

	local human = char:FindFirstChild("Humanoid")
	if human == nil then return end  

	if config.NotInSightDoSprint then
		if human.Health > 0 then
			config.enemy_human.WalkSpeed = config.chaseSpeed
		end
	end
	

end

-- Called when the AI starts to wander.
local function WanderStarted(location: Vector3) -- wander ends when a player is begun to be chased.
	spawn(function() 
		hooks.Animator.MotionActivated()
		hooks.Out.WanderStarted(location) 
	end)
end








-- Suggested not to mess with the functions below, they are the core functions, but if you need
-- to change something, by all means do it!








-- For optimal chasing, whenever the AI loses the player, the next wander will be a node in front of it (towards the where the player should be)
local function getPossibleNodes()

	if config.nodes_table == nil then error("config.nodes_table is nil.") end
	if config.nodes_table == {} then error("No nodes!") end -- 10/26/24 @rman501, changed to {} comparison.

	if not config.optimalChasing or not doOptChase then return config.nodes_table end

	-- If the nodes should be those in front of the NPC. (optimalChasing)
	local optNodes = {}

	for i, node in pairs(config.nodes_table) do 
		if not std.math.IsInView(config.enemy_char, node, 70, false) then continue end
		table.insert(optNodes, node)
	end

	if #optNodes <= 0 then
		return config.nodes_table
	end

	return optNodes 
end

-- If config.doRandomWander is TRUE
-- Uses the config.nodes_table and makes a node above those floors at a random point.
local prev_debug_nodes = {}
local function getRandomLocationInMap()

	local floors = getPossibleNodes()
	local randomFloor = nil

	-- Honestly, I do not know why, I do not want to know why, nor do I care why. But this loop fixed a bug! I love this loop! It is pointless! But I love it! I am going insane!
	while randomFloor == nil do
		run.Heartbeat:Wait()

		local randInt = math.random(1, #floors)
		local __randomFloor = floors[randInt]
		if __randomFloor:IsA("BasePart") then
			randomFloor = __randomFloor
		end
	end


	-- Gets a random location above the floor given.
	local rf_pos = randomFloor.Position
	local sizeRand = Vector3.new(math.random(- randomFloor.Size.X / 2, randomFloor.Size.X / 2), 0, math.random(- randomFloor.Size.Z / 2, randomFloor.Size.Z / 2))
	local vec3 = Vector3.new(rf_pos.X + sizeRand.X, rf_pos.Y + randomFloor.Size.Y / 2 + 2, rf_pos.Z + sizeRand.Z)

	--print("Making node at ")
	--print(vec3)
	for i, v in prev_debug_nodes do
		v:Destroy()
	end

	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Color = Color3.fromRGB(255,255,0)
	part.Transparency = 1
	part.Size = Vector3.new(2,2,2)
	part.Position = vec3
	part.Parent = workspace
	--print(part)
	table.insert(prev_debug_nodes, part)

	if config.debug_rand_pos then part.Transparency = 0.25 end

	return part
end

-- If config.doRandomWander is FALSE
-- Returns a random node from the possible nodes for the AI to wander to.
local function getRandomNode()	
	local nodes = getPossibleNodes()
	-- 2/19/25 @rman501, added error detection for this issue.
	if nodes == nil then error("Wander is active: and `nodes_table` setting is empty") end
	if #nodes == 0 then error("Wander is active: and `nodes_table` setting is empty") end
	return nodes[math.random(1, #nodes)]
end

-- Track to the last known position
local chasePart = Instance.new("Part")
chasePart.Shape = Enum.PartType.Ball
chasePart.Color = Color3.new(0.384314, 0.341176, 1)
chasePart.Material = Enum.Material.Neon
chasePart.Anchored = true
chasePart.Size = Vector3.new(1,1,1)
chasePart.CanCollide = false
chasePart.CanTouch = false
chasePart.CanQuery = false
chasePart.Transparency = 1
chasePart.Massless = true
if config.Visualize then
	chasePart.Transparency = 0.5
end
chasePart.Name = "ChasePartForNPC-Forbidden"
chasePart.Parent = config.enemy_char

-- ASYNC
-- 10/26/24 @rman501, added for attack systems.
local attackedPlayer = nil
local isInRange = false
local noLongerValid = false
local function attackRangeHandler(escaped: boolean) -- escaped could be due to death or loss of target, etc...

	if escaped then -- if not valid (dead or smth.)

		if (not noLongerValid or not config.CallAttackRangeHooksWhenChange) then
			noLongerValid = true


			if attackedPlayer.Character == nil then
				if not config.CallOutsideAttackRangeOnDeath then return end
				hooks.Out.OutsideAttackRange(attackedPlayer, common.GetDistanceToPlayer(attackedPlayer))
				return
			end

			local target_human = attackedPlayer.Character:FindFirstChild("Humanoid")
			if target_human ~= nil then 
				if target_human.Health == 0 and not config.CallOutsideAttackRangeOnDeath then return end
			end

			hooks.Out.OutsideAttackRange(attackedPlayer.Character, common.GetDistanceToPlayer(attackedPlayer))	
		end

		return
	end

	noLongerValid = false

	local dist = common.GetDistanceToPlayer(attackedPlayer)
	if dist == math.huge then return end

	if ((not isInRange) or (not config.CallAttackRangeHooksWhenChange)) and dist < config.MinAttackRange then
		hooks.Out.InsideAttackRange(attackedPlayer.Character, common.GetDistanceToPlayer(attackedPlayer)) 
		isInRange = true
	end

	if (isInRange or (not config.CallAttackRangeHooksWhenChange)) and dist > config.MinAttackRange then
		hooks.Out.OutsideAttackRange(attackedPlayer.Character, common.GetDistanceToPlayer(attackedPlayer))
		isInRange = false
	end
end

local canChaseToCorner = false
local function Chase(player: Player?)
	if isChasing then return end
	if player == nil then return end
	if player ~= attackedPlayer then -- if new player reset.
		isInRange = false
		noLongerValid = false
		attackedPlayer = player
	end
	isWandering = false

	local function stopChasing() -- if the AI stops chasing someone
		config.enemy_human.WalkSpeed = config.wanderSpeed
		plrChasing = nil
		isChasing = false

		-- 10/22/24 @rman501, for those not using doWander
		if not config.doWander then

			if not config.LimitChaseRange then
				ai.Stop(config.enemy_char)
			end

			if not config.isActive then return end -- 10/30/24 @rman501, not listening to ChaseAI.PauseAI()

			if config.LimitChaseRange then
				local thisCallTime = os.clock()
				lastCallTime = thisCallTime
				isWandering = true
				spawn(function()
					
					-- 3/13/25 @rman501, refactored, added PFLink Handler
					local specSettings = {
						StandardPathfindSettings = config.standardPathfindSettings, 
						SMMD_RaycastParams = {
							range = 25, 
							filterTable = {
								config.enemy_char,
								chasePart
							}
						}, 
						Visualize = config.Visualize,
						Hooks = {
							PathfindingLinkReached = PathfindingLinks.MANAGER
						}
					}
					
					if config.standardPathfindSettings ~= {} and config.standardPathfindSettings ~= nil then 
						specSettings["StandardPathfindSettings"] = config.standardPathfindSettings
					end
					
					ai.SmartPathfind(config.enemy_char, anchorPoint, true, specSettings) -- start player chase.
					


					returnToAnchorPoint = false
					if lastCallTime ~= thisCallTime then return end
					lastCallTime = 0
					isWandering = false
				end)
			end

		end

		if config.doWander then
			if config.LimitChaseRange then
				hooks.In.Wander(anchorPoint)
				returnToAnchorPoint = false
			end
		end
	end

	local plr_char = player.Character
	if plr_char == nil then warn("Player is nil!"); return end

	local core_failures = 0

	-- 9/28/24 Bad Pathing Protection Added.
	local function coreTrack_UnableToPath()
		core_failures += 1
		if core_failures > 5 then return end
		--print("Rerouting!")
		isWandering = false
		isChasing = false
		table.insert(badPathVictims, {player, os.clock()})
		stopChasing()
	end

	local function dummy_coreTrack_UnableToPath(goal, message)
		--print("Bad Path!")
		if not config.BadPathProtection then return end
		coreTrack_UnableToPath()
	end

	local function trackPlayer()
		
		-- 3/13/25 @rman501, added PFLink Handler
		local specSettings = {
			Tracking = true, 
			SMMD_RaycastParams = {
				range = 25, 
				filterTable = {config.enemy_char, chasePart}
			}, 
			Visualize = config.Visualize, 
			Hooks = {
				UnableToPath = dummy_coreTrack_UnableToPath,
				PathfindingLinkReached = PathfindingLinks.MANAGER
			},
			CollinearTargetPositionOffset = config.OffsetFromPlayer
		}
		
		if config.standardPathfindSettings ~= {} and config.standardPathfindSettings ~= nil then 
			specSettings.StandardPathfindSettings = config.standardPathfindSettings
		end

		ai.SmartPathfind(config.enemy_char, player.Character, false, specSettings) -- start player chase.
		lastCallTime = os.clock()
	end

	-- Stop a previous pathfind. 10/20/24 @rman501, lastCallTime might be unimportant.
	if lastCallTime > 0 then lastCallTime = 0 end

	-- Start player tracking.
	trackPlayer()

	local plr_hrt = plr_char.HumanoidRootPart

	-- Chase
	isChasing = true
	plrChasing = player

	local specRelease = false

	PlayerChaseBegan(player)
	targeting.SetPreviousTarget(plrChasing.Character)

	local LastSeenTime = os.clock()
	while isChasing do
		run.Heartbeat:Wait()
		if not config.isActive then break end
		config.enemy_human.WalkSpeed = config.chaseSpeed

		if plr_char == nil then break end
		local plr_human = plr_char:FindFirstChild("Humanoid")
		if plr_human and plr_human.Health <= 0 then stopChasing(); break end

		if not ContinueChasing(player) then break end

		spawn(function() attackRangeHandler(false) end) -- 10/26/24 @rman501, added for attack systems

		-- 7/1/25 @rman501, isolated
		local function canSee()
			return std.math.LineOfSight(config.enemy_char, plr_char, {range = config.detectionRange, SeeThroughTransparentParts = config.seeThroughTransparent, filterTable = {config.enemy_char, chasePart}})
		end

		-- 7/1/25 @rman501, for LostSightTimer, that way the AI does not lose targets too easily
		local function LostSightLongerThanTimer()
			if config.LostSightTimer == 0 then return true end
			return LastSeenTime + config.LostSightTimer < os.clock()
		end

		-- 7/1/25 @rman501, changed the if condition to incude LostSightTimer.
		-- If the NPC loses sight of the player, then chase to its last known location (which in reality is extrapolated by LostSightTimer)
		if canSee() or not LostSightLongerThanTimer() then -- 7/18/25 @rman501, fixed boolean statement.
			LastSeenTime = os.clock()
			chasePart.Position = plr_hrt.Position
			if not config.MeasureChaseRangeFromWhereStarted then -- 10/26/24 @rman501, MeasureChaseRange fix.
				anchorPoint = config.enemy_hrt.CFrame.Position
			end
			canChaseToCorner = true
		else

			-- 10/24/24 @rman501, stutter solved.
			if config.LimitChaseRange then break end

			if plrChasing == nil then return end -- Player is gone, or the chase was cancelled.

			-- Make sure the call is not redundant, if it is then just update position.
			if not canChaseToCorner then break end
			canChaseToCorner = false

			-- Make the NPC believe it is wandering.
			isWandering = true 

			task.wait() -- prevents tracking from being idiotic.


			-- Announce the player is lost, so that if along the way the NPC finds another player, it will chase them instead
			specRelease = true
			doOptChase = true
			spawn(function()
				local result = nil
				local timeNow = os.clock()
				lastCallTime = timeNow
				
				-- 3/13/25 @rman501, refactored, added PFLink Handler 
				local specSettings = {
					SkipToWaypoint = 2, 
					SMMD_RaycastParams = {
						range = 25
					}, 
					Visualize = config.Visualize,
					Hooks = {
						PathfindingLinkReached = PathfindingLinks.MANAGER
					}
				}
				
				if config.standardPathfindSettings ~= {} and config.standardPathfindSettings ~= nil then 
					specSettings["StandardPathfindSettings"] = config.standardPathfindSettings
				end
				
				result = ai.SmartPathfind(config.enemy_char, chasePart, true, specSettings) -- start player chase.
				
				if result == Enum.PathStatus.NoPath then end

				-- When the pathfind is done, either because it got cancelled, or etc...
				if lastCallTime ~= timeNow then return end
				isWandering = false
				lastCallTime = 0

				--if config.NotInSightDoSprint then config.enemy_human.WalkSpeed = config.wanderSpeed end
			end)

			task.wait() -- always nice to wait a lil bit for the pathing to activate.

			break
		end
	end

	stopChasing()
	spawn(function() attackRangeHandler(true) end) -- 10/26/24 @rman501, added for attack systems
	if config.NotInSightDoSprint and specRelease then config.enemy_human.WalkSpeed = config.chaseSpeed end
	if not specRelease then lastCallTime = 0 end
	LostPlayer(player, specRelease)
end

local forcedNode: BasePart? = nil -- 10/21/24 @rman501, for hooks.
local nodeWanderIndex		= 1
local function Wander()

	if isChasing then 
		--print("A") 
		return 
	end

	if isWandering then 
		--print("B") 
		return 
	end

	if lastCallTime > 0 then 
		--print("C") 
		return 
	end

	isWandering = true

	config.enemy_human.WalkSpeed = config.wanderSpeed

	-- 9/28/24 @rman501, refactored and taken out of async.
	local forcedNodeUsed = false
	local function tryPathfind()

		local randomLocation = nil

		if forcedNode == nil and not config.EnableNodeOrder then
			if config.doRandomWander then
				randomLocation = getRandomLocationInMap()
			end

			if not config.doRandomWander then
				randomLocation = getRandomNode()
			end
		end

		if forcedNode == nil and config.EnableNodeOrder then
			randomLocation = config.nodes_table[nodeWanderIndex]
		end

		-- 10/21/24 @rman501, allow people to choose a node to target with hooks
		if forcedNode ~= nil then
			randomLocation = forcedNode
			forcedNodeUsed = true
		end

		doOptChase = false

		if randomLocation == nil then warn("Random Location was nil, please make sure all the nodes are correct!"); return Enum.PathStatus.NoPath end

		-- 10/22/24 @rman501, support Vector3 & CFrame
		-- 10/25/24 @rman501, only call if successful.
		local db = false
		local function onSuccessfulComputation()
			if db then return end -- db just in case.
			local locType = typeof(randomLocation)
			db = true
			if locType == "Vector3" then
				WanderStarted(randomLocation)
			end

			if locType == "CFrame" then
				WanderStarted(randomLocation.Position)
			end

			if locType == "Instance" then
				WanderStarted(randomLocation.CFrame.Position)
			end
		end

		local function onGoalReached(goal: any)
			local goalType = typeof(randomLocation)

			local function wanderCompleteCall(correctGoal)
				if config.WanderPauseTimer > 0 then hooks.Animator.MotionStopped() end -- only stop motion animations if there is a pause timer.
				spawn(function() hooks.Out.WanderCompleted(correctGoal) end)
			end

			if goalType == "Vector3" then
				wanderCompleteCall(goal)
			end

			if goalType == "CFrame" then
				wanderCompleteCall(goal.Position)
			end

			if goalType == "Instance" then
				wanderCompleteCall(goal.CFrame.Position)
			end
		end
		
		-- 3/13/25 @rman501, added PFLink Handler
		local specSets = {
			SMMD_RaycastParams = {
				range = 25, 
				filterTable = {
					config.enemy_char, 
					chasePart
				}
			}, 
			Visualize = config.Visualize, 
			Hooks = {
				ComputedWaypoints = onSuccessfulComputation, 
				GoalReached = onGoalReached,
				PathfindingLinkReached = PathfindingLinks.MANAGER
			} -- used for accuracy of WanderStarted hook.
		}
		if config.standardPathfindSettings ~= {} and config.standardPathfindSettings ~= nil then
			specSets.StandardPathfindSettings = config.standardPathfindSettings
		end

		return ai.SmartPathfind(config.enemy_char, randomLocation, true, specSets) -- start player chase.
	end

	-- 9/28/24 @rman501, moved things around.
	local tStarted = os.clock()
	lastCallTime = tStarted
	spawn(function()

		-- Repeat a pathfind until it likes its location, while ensuring nothing is going haywire in the background.
		if tStarted ~= lastCallTime then return end

		while tryPathfind() == Enum.PathStatus.NoPath do
			if config.enemy_char == nil then return end
			if forcedNodeUsed then forcedNode = nil; forcedNodeUsed = false end -- 10/21/24 @rman501, allow people to choose a node to target with hooks
			run.Heartbeat:Wait()
			if tStarted ~= lastCallTime then return end
			if isChasing then return end
			if not isWandering then return end
			tStarted = os.clock()
			lastCallTime = tStarted
		end

		if forcedNodeUsed then forcedNode = nil; forcedNodeUsed = false end -- 10/21/24 @rman501, allow people to choose a node to target with hooks
		if isChasing then return end
		if tStarted ~= lastCallTime then return end

		if config.EnableNodeOrder then
			nodeWanderIndex += 1
			if nodeWanderIndex > #config.nodes_table then
				nodeWanderIndex = 1
			end
		end

		lastCallTime = 0
		if config.WanderPauseTimer > 0 and config.WanderPauseTimer ~= nil then
			task.wait(config.WanderPauseTimer)
		end

		isWandering = false
	end)

end

-- Protection against bad nodes.
local function cleanNodesTable()

	if config.nodes_table == nil then error("Nodes table is nil!") end

	-- If the user provides a folder, this converts it into the proper format.
	if typeof(config.nodes_table) == "Instance" then config.nodes_table = {config.nodes_table} end

	-- Recursively expands all provided tables
	local expandingComplete = false
	while not expandingComplete do
		expandingComplete = true
		for i, potentialTable in pairs(config.nodes_table) do

			local function doExpansion(tab)
				table.remove(config.nodes_table, i)
				for _, node in pairs(tab) do
					table.insert(config.nodes_table, node)
				end
				expandingComplete = false
			end

			if typeof(potentialTable) == "Instance" then
				if potentialTable:IsA("Folder") then
					doExpansion(potentialTable:GetChildren())
					break
				end
			end

			if typeof(potentialTable) == "table" then
				doExpansion(potentialTable)
				break
			end

		end
	end

	-- Removes unusable nodes.
	local indicesToRemove = {}
	for i, v: Instance in pairs(config.nodes_table) do
		if v:IsA("BasePart") then continue end -- good node.
		table.insert(indicesToRemove, 1, i)
	end

	-- Removes all bad nodes in reverse order.
	for _, index in ipairs(indicesToRemove) do
		table.remove(config.nodes_table, index)
	end

end

-- Help visualize chase ranges
-- 10/22/24 @rman501, ChaseRange
local function visualizeConeAndLimits()

	if not config.Visualize then return end

	if config.LimitChaseRange then
		visualization.VisualizeLimitChase()
	end

	if config.ViewCone then
		visualization.VisualizeCone()
	end
end

-- The core loop
local function Main()

	visualizeConeAndLimits()
	cleanNodesTable()

	while config.enemy_human.Health > 0 do -- 9/28/24 @rman501, make sure AI is alive :bangbang:

		run.Heartbeat:Wait()


		if config.isActive then

			-- 10/27/24 @rman501, if the AI must return to anchor point, wait to chase.
			local nearestVisPlayer = nil
			if not(config.LimitChaseRange and config.MustReturnToAnchorPoint and returnToAnchorPoint) then 
				nearestVisPlayer = targeting.GetNearestVisiblePlayer()
			end
			--print(nearestVisPlayer)
			if nearestVisPlayer ~= nil then
				Chase(nearestVisPlayer)
			else
				if config.enemy_human.MoveDirection.Magnitude < 0.25 and config.doWander then -- if its not chasing then wander
					Wander()
				end
			end
		end

	end

end

local function stopAI()
	config.isActive = false
	plrChasing = nil
	isChasing = false
	config.enemy_human.WalkSpeed = config.wanderSpeed
end

local function startAI()
	config.isActive = true
end

config.enemy_hrt.Touched:Connect(touchHandler)
for i, hitbox in pairs(config.hitboxes) do
	hitbox.Touched:Connect(touchHandler)
end

--[[

HOOKING INITIALIZATION

]]--

local HOOKS_IN = {}

HOOKS_IN.StopChasing = function(doUnstuck: boolean)

	if not config.isActive then return end

	if not plrChasing then return nil end
	local playerChased = plrChasing

	if doUnstuck then
		table.insert(badPathVictims, {plrChasing, os.clock()})
	end

	plrChasing = nil
	isChasing = false
	config.enemy_human.WalkSpeed = config.wanderSpeed
	lastCallTime = 0
	--LostPlayer(playerChased, true) -- 11/4/24 @rman501, not necessary


	return playerChased
end

-- TODO
--local chase_it = 0 -- this stops the previous track to nowhereville if active.
--HOOKS_IN.Chase = function(Player: Player)
--	if isChasing then
--		HOOKS_IN.StopChasing(false)
--	end

--	local found = 0
--	for i, v in pairs(badPathVictims) do
--		if v[1] == Player then
--			found = i
--			break
--		end
--	end

--	-- remove from badpath so it can chase.
--	if found ~= 0 then
--		table.remove(badPathVictims, found)
--	end


--end

HOOKS_IN.Wander = function(optNode: BasePart)
	if optNode == nil then return end
	if not config.isActive then return end
	if isChasing then return end

	forcedNode = optNode

	isChasing = false
	isWandering = false
	lastCallTime = 0
end

HOOKS_IN.ForceStartWander = function(optNode: BasePart)
	if optNode == nil then return end
	if not config.isActive then return end
	if isChasing then
		HOOKS_IN.StopChasing(true)
	end

	if not isChasing then
		HOOKS_IN.Wander(optNode)
	end
end

HOOKS_IN.GetPlayerChasing = function()
	return plrChasing
end

HOOKS_IN.IsWandering = function()
	return isWandering
end

local timeToRelease = 0
local infaPause = false
HOOKS_IN.PauseAI = function(optionalPauseTimer: number)

	if optionalPauseTimer == nil then optionalPauseTimer = 0 end
	if optionalPauseTimer == 0 then infaPause = true; timeToRelease = 0 end

	-- Update Pause Timer
	local isAlreadyCalled = timeToRelease ~= 0
	local newTime = os.clock() + optionalPauseTimer
	if timeToRelease < newTime then
		timeToRelease = newTime
		if isAlreadyCalled then return end -- cancel this thread.
	end

	config.isActive = false
	targeting.SetPausedFlag()
	ai.Stop(config.enemy_char)

	if isChasing then
		HOOKS_IN.StopChasing(false)
	end

	if isWandering then
		ai.Stop(config.enemy_char)
		targeting.SetPreviousTarget(nil) -- 10/31/24 @rman501, chase auto updates target, here we set it to nil if we dont want it.
		isChasing = false
		isWandering = false
		lastCallTime = 0
	end

	--if optionalPauseTimer <= 0 then HOOKS_IN.ResumeAI() return end -- infa pause

	-- Keep paused until time is elapsed.
	spawn(function()
		while timeToRelease > os.clock() do
			task.wait(timeToRelease - os.clock())
		end

		if infaPause then return end
		timeToRelease = 0

		HOOKS_IN.ResumeAI() -- ignore
	end)
end

HOOKS_IN.ResumeAI = function()
	timeToRelease = 0
	infaPause = false
	config.isActive = true
end

HOOKS_IN.GetBadPathVictims = function()
	return badPathVictims
end

HOOKS_IN.SetBadPathVictims = function (newTable: {})
	badPathVictims = newTable
end


--HOOKS_IN.SetListOfAlternativeTargets = function(newList: {Model})
--	NPC_List = newList
--end

hooks.In = HOOKS_IN -- ignore

--[[

HOOKING INITIALIZATION

]]--
task.wait(config.AI_Init_Time) -- recommended

hooks.Out.INIT()
onStartup()
Main()

-- opachki