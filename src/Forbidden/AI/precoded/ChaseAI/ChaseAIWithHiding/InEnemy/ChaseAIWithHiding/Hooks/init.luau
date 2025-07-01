--!nocheck
-- Collapse everything up to the start of `binds. ` for ease of reading

-- GO TO THE BOTTOM TO EDIT.
function nullbind() end

-- For functions to hook to in the script.
type BINDS_IN_TYPEDEF = {
	StopChasing: () -> Player?, 						-- If chasing, will stop chasing than start a wander, returns the player it was chasing or nil
	Chase: (Player: Player) -> nil,
	Wander: (optNode: BasePart) -> boolean,				-- Will wander to a different location as long as its not chasing someone, returns false if chasing.
	ForceStartWander: (optNode: BasePart) -> nil,		-- If chasing player, will stop that call and wander as well.
	GetPlayerChasing: () -> Player?,					-- Gets the current player the AI is chasing, or returns nil.
	IsWandering: () -> boolean,
	PauseAI: (optionalPauseTimer: number?) -> nil,		-- Pauses the AI for x seconds
	ResumeAI: () -> nil,								-- Resumes the AI if it is paused.
	GetBadPathVictims: () -> { {Player: Player, Time: number} },	-- Returns a table of players that are ignored for bad pathing.
	SetBadPathVictims: (blacklist: { {Player: Player, Time: number} }) -> nil -- Sets the blacklist table.
	--SetListOfAlternativeTargets: (List: {Model}) -> nil -- A table of NPCs the AI could target. (since naturally it only targets players)
}

-- For functions created by this.
type BINDS_OUT_TYPEDEF = {
	INIT: () -> nil,								-- On INIT call by main script.
	TouchedTargetPlayer: (Character: Model) -> nil,		-- Calls when the target player is touched.
	TouchedOtherPlayer: (Character: Model) -> nil,		-- Calls when a player other than the target is touched.
	PlayerChaseBegan: (Player: Player?) -> nil,			-- Passes the player the AI has begun to chase.
	PlayerChaseEnded: (Player: Player?) -> nil,			-- Passes the player the AI has stopped chasing.
	WanderStarted: (location: Vector3) -> nil,			-- Passes the location the AI has started to wander to.
	WanderCompleted: (location: Vector3) -> nil,		-- Passes the location the AI has completed its wander to.
	InsideAttackRange: (Character: Model, dist: number) -> nil,		-- Called whenever the player enters the attack range (or continuously if not CallAttackRangeHooksWhenChange) 
	OutsideAttackRange: (Character: Model, dist: number) -> nil,	-- Called whenever the player exits the attack range  (or continuously if not CallAttackRangeHooksWhenChange) 
	ContinueChasing: (Player: Player?) -> boolean,		-- Asks if the AI should continue chasing the TargetPlayer.
	IsATarget: (Player: Player?) -> boolean,			-- Should the player be considered as a target for the AI, could also be a model if an NPC (SetListOfAlternativeTargets) was passed.
}

type BINDS_ANIMATE_TYPEDEF = {
	MotionStopped: () -> nil,
	MotionActivated: () -> nil
}

type HOOKS_TYPEDEF = {
	In: BINDS_IN_TYPEDEF,
	Out: BINDS_OUT_TYPEDEF,
	Animator: BINDS_ANIMATE_TYPEDEF
}

-- look above for info
local Hooks: HOOKS_TYPEDEF = {
	In = { -- These are binds you can use.
		StopChasing = nullbind,
		Wander = nullbind,
		ForceStartWander = nullbind,
		GetPlayerChasing = nullbind,
		IsWandering = nullbind,
		PauseAI = nullbind,
		ResumeAI = nullbind,
		GetBadPathVictims = nullbind,
		SetBadPathVictims = nullbind
		--SetListOfAlternativeTargets = nullbind
	},
	Out = {
		INIT = nullbind,
		TouchedTargetPlayer = nullbind,
		TouchedOtherPlayer = nullbind,
		PlayerChaseBegan = nullbind,
		PlayerChaseEnded = nullbind,
		InsideAttackRange = nullbind,
		OutsideAttackRange = nullbind,
		WanderStarted = nullbind,
		WanderCompleted = nullbind,
		ContinueChasing = nullbind,
		IsATarget = nullbind
	},
	Animator = {
		MotionStopped = nullbind,
		MotionActivated = nullbind
	}
}

-- [APIs] --
local ChaseAI: BINDS_IN_TYPEDEF = nil -- will be loaded. (these are hooks to the script) 
	-- i.e. ChaseAI.Damage(player)
local Common = require(script:WaitForChild("Common"))
local config = require(script.Parent:WaitForChild("Settings"))
local Animations = require(script:WaitForChild("Animations")) -- some default animation examples.

local LoadedCustomAnims = {}

-- [APIs] --
local deathFlag	= false

local binds: BINDS_OUT_TYPEDEF = {}

--[[ Definitions of ASYNC / SYNC
	ASYNC: the code is will not be halted by your code.
	SYNC: the code will wait for your code to return a value (it "yields").
]]--


-- EXAMPLE
-- CHASE AI WITH HIDING
-- EXAMPLE
-- # Events
local rs 				= game:GetService("ReplicatedStorage")

local remotes			= rs:WaitForChild("signals"):WaitForChild("remotes")

local RE_HideEvent		= remotes:WaitForChild("events"):WaitForChild("HideEvent")
local RF_RequestLocker	= remotes:WaitForChild("functions"):WaitForChild("RequestLocker")

local int_Forbidden		= rs:WaitForChild("Forbidden")
local ai				= require(int_Forbidden:WaitForChild("AI"))

local function reachedLockerWherePlayerWasHiding(Player: Player)
	-- for testing purposes
	local char = Player.Character
	local human = char:WaitForChild("Humanoid")
	RE_HideEvent:FireClient(Player, true)
	human.Health -= 100 -- insta kill!
end

local function isPlayerHiding(TargetedPlayer: Player)
	local tV = TargetedPlayer:FindFirstChild("TemporaryValues")
	if tV == nil then return false end

	local isHidingObj = tV:FindFirstChild("isHiding")
	if isHidingObj == nil then return false end

	return isHidingObj.Value
end

local function sawPlayerHide(Player: Player)

	local lockerHidingIn = RF_RequestLocker:InvokeClient(Player)
	if lockerHidingIn == nil then warn("No locker found! Player: "  .. Player.Name); return end

	local partToGo: BasePart = lockerHidingIn:WaitForChild("front")
	if partToGo == nil then warn("No spot for the AI to go in front of the locker to!"); return end

	ChaseAI.PauseAI()
	ai.Stop(config.enemy_char)

	local done = false
	local result = nil

	local escaped = false
	spawn(function()
		while result == nil do
			if not isPlayerHiding(Player) then ChaseAI.ResumeAI(); ai.Stop(); escaped = true; return end -- Handoff to normalcy if the player stops hiding.
			task.wait()
		end
	end)

	RE_HideEvent:FireClient(Player, false)
	if #config.standardPathfindSettings > 0 then 
		result = ai.SmartPathfind(config.enemy_char, partToGo, true, {StandardPathfindSettings = config.standardPathfindSettings, ["Hooks"] = {GoalReached = function() reachedLockerWherePlayerWasHiding(Player) end}})
	else
		result = ai.SmartPathfind(config.enemy_char, partToGo, true, {["Hooks"] = {GoalReached = function() reachedLockerWherePlayerWasHiding(Player) end}})
	end

	if escaped then return end -- if the player left the locker than let the handler, handle it.

	ai.Stop(config.enemy_char) -- idk if needed, just for insurance.
	ChaseAI.ResumeAI()
	if result == Enum.PathStatus.NoPath then done = true; warn("No path found! (could be caused by locker chase cancel)"); return end 

	return 
end

-- ASYNC
binds.TouchedTargetPlayer = function(Character: Model)
	print("Target Player Touched: " .. Character.Name)
end

-- ASYNC
binds.TouchedOtherPlayer = function(Character: Model)
	print("Other Player Touched: " .. Character.Name)
end

-- ASYNC
binds.PlayerChaseBegan = function(Player: Player)
	print("Player Chase Began: " .. Player.Name)
end

-- ASYNC
-- READ: Use WanderStarted for a true lost player, since this is also called when the AI begins to track to the position it last saw the player.
binds.PlayerChaseEnded = function(Player: Player)
	print("Player Line of Sight Lost: " .. Player.Name)
	if isPlayerHiding(Player) and config.LockerChase then 
		sawPlayerHide(Player)
	end
end

-- ASYNC
-- A wander has started to the location provided.
binds.WanderStarted = function(location: Vector3)
	--print("Wander Started to Location: " .. tostring(location))
	print("Wander Started")
end

-- ASYNC
-- A wander was completed to the location provided, uninterrupted. (will not fire upon the completion of when the AI tracks to the position it last saw the player -> non-limitchase)
binds.WanderCompleted = function(location: Vector3)
	print("Wander Completed.")
end

local doingAttack = false
local function doAttack(Character: model, dist: number)
	--[[
	
		ChaseAI.PauseAI(3)
		-- ATTACK

		or 

		ChaseAI.PauseAI()
		-- start attack
		-- monitor for exit condition
		ChaseAI.ResumeAI()
		
		or
		
		ChaseAI.PauseAI()
		ModuleScript.Attack() -- yields
		ChaseAI.ResumeAI()
		
	-- maybe use these, depending on situation.
	Animations.EnableScript = false
	Animations.PauseAnimations(3)
	]]--
	
	--if doingAttack then return end
	--doingAttack = true
	
	--ChaseAI.PauseAI(1.5)
	
	--local kickTrack = Animations.LoadAnimation(Animations.Kick, true) -- animations are cached so this returns an already loaded anim
	--kickTrack:Play()
	----kickTrack.Ended:Wait() PauseAI has defined time.
	--doingAttack = false
	
	
end 	

-- ASYNC
binds.InsideAttackRange = function(Character: Model, dist: number)
	print("Inside Attack Range: " .. Character.Name)
	--local dist = Common.GetDistanceToCharacter(Character)
	doAttack(Character, dist)
	
end

-- ASYNC
binds.OutsideAttackRange = function(Character: Model?, dist: number) -- if `CallOutsideAttackRangeOnDeath` is true, it can be a player (only when char == nil).
	print("Outside Attack Range: " .. Character.Name)
	--local dist = Common.GetDistanceToCharacter(Character)
end

-- SYNC
-- Add special code here to influence if the AI should keep chasing the player.
binds.ContinueChasing = function(player: Player)
	if isPlayerHiding(player) then return false end 
	-- by doing, this omniscient timer is removed, preventing bugs (such as pathing into locker i.e. causing it to become stagnant)
	return true
end

-- SYNC
-- Return false to remove a player as a possible target (for that cycle)
binds.IsATarget = function(player: Player)
	return not isPlayerHiding(player) -- 2/19/25 @rman501, line was missing
end
-- SYNC
-- Called when the script loads all the BINDS_IN.
binds.INIT = function()
	ChaseAI = Hooks.In
end

-- Set hooks out to the binds created.
Hooks.Out = binds


-- [ Others ] --
local function onDeath()
	deathFlag = true
end

config.enemy_human.Died:Connect(onDeath)

-- Load and register animations
for i, v in pairs(Animations) do
	local typeofval = typeof(v) 
	if typeofval ~= "number" and typeofval ~= "string" then continue end
	if Animations.isInDefaultAnimScript(i) then continue end -- loaded elsewhere
	LoadedCustomAnims[i] = nil
end


return Hooks