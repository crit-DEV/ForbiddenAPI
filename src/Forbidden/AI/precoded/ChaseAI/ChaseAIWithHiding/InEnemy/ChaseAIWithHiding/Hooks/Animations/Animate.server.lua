local NPC					= script.Parent

local c_ai_script			= NPC:WaitForChild("ChaseAIBase")

local hooks_module		= c_ai_script:WaitForChild("Hooks")
local Hooks					= require(hooks_module)
local Animations			= require(hooks_module:WaitForChild("Animations"))
local config				= require(c_ai_script:WaitForChild("Settings"))

local animationsFolder 		= NPC:WaitForChild("Forbidden-AnimationsFolder")
--local activeAnimations = {}
local motionActive = false
local isRunning = false
local isWalking = false

local human = config.enemy_human

type ForbiddenAnimation = {
	AnimationId: number,
	Priority: Enum.AnimationPriority,
	Looped: boolean,
	Speed: number
}

local function stopAllAnimationsExcept(exempt: {AnimationName: string})
	for index, value in pairs(Animations) do
		if table.find(exempt, index) ~= nil then continue end -- if it is exempt, ignore it.
		if Animations.isInDefaultAnimScript(index) then
			Animations.LoadAnimation(Animations[index][1], true):Stop()
		end
	end
end

local function stopAnimation(animation: ForbiddenAnimation)
	local track = Animations.LoadAnimation(animation[1], true)
	if track == nil then return end
	track:Stop()
end

local function playAnimation(animation: ForbiddenAnimation)
	local track = Animations.LoadAnimation(animation[1], true)
	if track == nil then return end
	if animation[3] then track.Looped = true end
	if typeof(animation[4]) == "number" then track.Speed = animation[4] end
	track:Play()
end

local function doStandard(animation: ForbiddenAnimation, active: boolean)
	if animation[1] == 0 then return end
	if not active then stopAnimation(animation) return end

	playAnimation(animation)
end

local function onJumping(active: boolean)
	if not active then return end -- ignore
	doStandard(Animations.Jumping, active)
end

local function onWalk(active: boolean)
	if not motionActive then return end
	if active and isWalking then return end
	if active then isWalking = true end
	if not active then isWalking = false end
	doStandard(Animations.Wandering, active)
end

local function onRunning(active: boolean)
	if not motionActive then return end
	if active and isRunning then return end
	if active then isRunning = true end
	if not active then isRunning = false end
	doStandard(Animations.Chasing, active)
end

local function onStopping(active: boolean) -- ik param is stupid
	isRunning = false
	isWalking = false
	stopAnimation(Animations.Wandering)
	stopAnimation(Animations.Chasing)
end

local function onDeath(active: boolean)
	doStandard(Animations.Died[1], active)
end

local function onFreefall(active: boolean)
	doStandard(Animations.Freefall, active)
end

local function onTrip(active: boolean)
	doStandard(Animations.Tripped, active)
end

local function onRagdoll(active: boolean)
	doStandard(Animations.Ragdoll, active)
end

local function onNoState(active: boolean)
	stopAllAnimationsExcept({})
end

local function onClimbing(active: boolean)
	doStandard(Animations.Climbing, active)
end

local function onLanded(active: boolean)
	if not active then return end -- ignore
	doStandard(Animations.Landed, active)
end

local function onSwimming(active: boolean)
	doStandard(Animations.Swimming, active)
end

local function onSeated(active: boolean)
	doStandard(Animations.Seated, active)
end

local function onStateChanged(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)


	local function findFunction(state: Enum.HumanoidStateType, active: boolean)

		if state == Enum.HumanoidStateType.Dead then
			onDeath(active)
		end

		if state == Enum.HumanoidStateType.Jumping then

			if config.standardPathfindSettings ~= nil then
				if not config.standardPathfindSettings["AgentCanJump"] then return end
			end

			onJumping(active)
		end

		if state == Enum.HumanoidStateType.Ragdoll then
			if config.PreventAIFromRagdolling then return end
			onRagdoll(active)
		end

		if state == Enum.HumanoidStateType.None then
			onNoState(active)
		end

		if state == Enum.HumanoidStateType.Freefall then
			onFreefall(active)
		end

		if state == Enum.HumanoidStateType.FallingDown then
			if config.PreventAIFromRagdolling then return end
			onTrip(active)
		end

		if state == Enum.HumanoidStateType.Climbing then

			if config.standardPathfindSettings ~= nil then
				if not config.standardPathfindSettings["AgentCanJump"] then return end
			end

			onClimbing(active)
		end

		if state == Enum.HumanoidStateType.Landed then
			onLanded(active)
		end

		if state == Enum.HumanoidStateType.Seated then
			onSeated(active)
		end

		if state == Enum.HumanoidStateType.Swimming then
			onSwimming(active)
		end
	end

	findFunction(oldState, false)
	findFunction(newState, true)

end 

local function MovementHandler(speed: number)

	if not Animations.EnableScript then return end
	if not motionActive then return end

	if speed <= 0 then
		-- stop other movement anims
		if not(Hooks.In.IsWandering()) and Hooks.In.GetPlayerChasing() == nil then
			onStopping(true)
		end
	end

	if Animations.Wandering == 0 then
		-- only play chase anim
		onRunning(true)
	end

	if Animations.Chasing == 0 then
		-- only play wander anim
		onWalk(true)
	end

	-- Wander Anim (WALK)
	if 0 < speed and speed <= config.wanderSpeed then
		if not Hooks.In.IsWandering() then return end
		onRunning(false)
		onWalk(true)
	end

	-- Chase Anim (RUN)
	if config.wanderSpeed < speed then
		if Hooks.In.GetPlayerChasing() == nil then return end
		onWalk(false)
		onRunning(true)
	end
end

human.StateChanged:Connect(function(oldState: Enum.HumanoidStateType, newState: Enum.HumanoidStateType)
	if not Animations.EnableScript then return end
	onStateChanged(oldState, newState)
end)

human.Running:Connect(MovementHandler)

Hooks.Animator.MotionStopped = function()


	doStandard(Animations.Idle, true) -- 11/2/24 @rman501, idle never called.

	if isWalking then
		onWalk(false)
	end

	if isRunning then
		onRunning(false)
	end

	-- 3/10/25 @rman501, was at top of function and the above functions did not function correctly.
	motionActive = false
end

Hooks.Animator.MotionActivated = function()
	motionActive = true

	doStandard(Animations.Idle, false) -- 11/2/24 @rman501, idle never called.
end

-- Preload
local function preload()
	for index, value in pairs(Animations) do
		if Animations.isInDefaultAnimScript(index) then
			Animations.LoadAnimation(Animations[index][1], true)
		end
	end
end

preload()

--[[ TEST
local Crawl = Animations.LoadAnimation(Animations.Crawl, true)
Crawl.Looped = true
print(Crawl)
Crawl:Play()
wait(3)
Crawl:Stop()
]]-- 