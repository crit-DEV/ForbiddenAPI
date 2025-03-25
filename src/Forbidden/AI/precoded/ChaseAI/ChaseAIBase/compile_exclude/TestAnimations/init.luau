--!nocheck
local Animations = {}

-- Default hooked animations.
-- Set to 0 to disable.
local char = script.Parent.Parent.Parent
local config = require(script.Parent.Parent:WaitForChild("Settings"))

local animationsFolder = char:FindFirstChild("Forbidden-AnimationsFolder")
if animationsFolder == nil then
	animationsFolder = Instance.new("Folder") animationsFolder.Name = "Forbidden-AnimationsFolder" animationsFolder.Parent = config.enemy_char
end

-- [ Defaults ] --
-- Do not make a custom with this name, default roblox animate script values are overriden with this.
-- Can be strings or numbers (i.e. 1234567, "rbxassetid://1234567")
local defaultAnims = {"Idle", "Died", "Jumping", "Freefall", "Landed", "Climbing", "Ragdoll", "Chasing", "Wandering"}

local function MakeAnimation(AnimationId: any, Priority: Enum.AnimationPriority, Looped: boolean, Speed: number)
	return {AnimationId, Priority, Looped, Speed}
end

Animations.EnableScript	= true -- set to false to disable the default animation handler.

--Animations.Idle			= MakeAnimation(0, Enum.AnimationPriority.Idle, true) -- ID, PRIORITY, LOOPED?, SPEED (default: 1.0)
Animations.Idle			= MakeAnimation(92745889277946, Enum.AnimationPriority.Idle, true)
Animations.Died			= MakeAnimation(0, Enum.AnimationPriority.Action4, false)
Animations.Jumping		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)
Animations.Freefall		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)
Animations.Landed		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)
Animations.Climbing		= MakeAnimation(0, Enum.AnimationPriority.Action, true)
Animations.Ragdoll		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)
Animations.Tripped		= MakeAnimation(0, Enum.AnimationPriority.Action, false)
Animations.Seated		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)
Animations.Swimming		= MakeAnimation(0, Enum.AnimationPriority.Movement, false)

-- auto-hooked movement anims.
Animations.Chasing 		= MakeAnimation(136910744497279, Enum.AnimationPriority.Movement, true) -- run anim
Animations.Wandering	= MakeAnimation(126212996576090, Enum.AnimationPriority.Movement, true) -- walk anim

-- [ Custom ] --
-- these you have to implement somewhere in hooks or another script.
--Animations.Crawl 	= 111314563083709 (ex)
--Animations.Kick	= 71341955243063 (ex) see Hooks Example Attack


-- Loads / Functions



local cache = {}
local animator: Animator = config.enemy_human:WaitForChild("Animator")
if animator == nil then warn("[ChaseAI.Common] Animator could not be found in enemy human.") end

local SILENCE_ANIMATE_OBTAINER = false

local AnimateScript = nil
if not SILENCE_ANIMATE_OBTAINER then
	AnimateScript = config.enemy_char:WaitForChild("Animate", 1)
	if AnimateScript == nil then warn("[ChaseAI.Animations] Animate script does not exist, set `SILENCE_ANIMATE_OBTAINER` to true if expected.") end
	if AnimateScript ~= nil then
		if not AnimateScript:FindFirstChild("ForbiddenAnimate") then warn("[ChaseAI.Animations] Animate script is not Forbidden's, get the `Animate` script from inside the ChaseAI folder or  set `SILENCE_ANIMATE_OBTAINER` to true if expected.") end
	end
end

--[[
	Determines if the Animation name is in the default animation script.
	I.e. the Chase, Wander, Jump, Idle etc... auto-handler.
	
	<code><strong>name</strong>: string</code>
	<em>The name of the animation to check</em>
	
	<em><strong>Returns</strong>: boolean</em>
	Is the animation in the default animation script
]]--
Animations.isInDefaultAnimScript = function(name: string): boolean

	if table.find(defaultAnims, name) == nil then return false end

	return true
end

--[[
	Loads an animation to the <strong>NPC</strong>.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>AnimationId</strong>: number, string</code>
	<em>The Animation ID to load can be the following formats:
	> 1234567
	> "rbxassetid://1234567"
	</em>
	
	<code><strong>CacheAnimation</strong>: boolean</code>
	<em>For most cases, set to <strong>TRUE</strong></em>
	<em>Caches the animation, if false, a new one is loaded each time. This can be used to get an already loaded or in action Animation Track</em>
	
	<em><strong>Returns</strong>: AnimationTrack</em>
	The loaded animation to the NPCs humanoid.
	
	
	<strong>Example Code</strong>
	<code>
		local common = require(...) -- path to module
		
		local animationId = 1234567
		local animationId = "rbxassetid://1234567"
	
		local animTrack = common.LoadAnimation(animationId, true)
		animTrack.Looped = true
		animTrack:Play()
	</code>
]]--
Animations.LoadAnimation = function(AnimationId: number?, CacheAnimation: boolean): AnimationTrack?
	if typeof(AnimationId) == "number" then
		if AnimationId == 0 then return nil end
	end

	-- Return animation from cache
	local temp_animId = AnimationId
	if typeof(AnimationId) ~= "string" then
		if typeof(AnimationId) ~= "number" then warn("[ChaseAI.Animations] AnimationId not provided properly.") return end
		temp_animId = "rbxassetid://" .. tostring(AnimationId)
	end

	if CacheAnimation then
		if cache[temp_animId] ~= nil then
			return cache[temp_animId]
		end
	end

	-- Load animation
	local animation = Instance.new("Animation")


	animation.AnimationId = temp_animId

	local animationTrack = animator:LoadAnimation(animation)
	if animationTrack then
		--print("Loaded animation track:", animationTrack.Animation.AnimationId)
	else
		warn("[ChaseAI.Animations] Failed to load animation track for ID:", AnimationId)
	end


	-- Cache animation
	if CacheAnimation and animationTrack then
		cache[temp_animId] = animationTrack
	end

	return animationTrack
end

--[[
	Stops all animations ongoing in the supplied `Animate` script.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	This does <strong>not</strong> stop <strong>your custom animations</strong>
	
	<code>Animations.PauseAnimations()</code> calls this function.
]]--
Animations.StopAllDefaultAnimations = function()
	for i, v in pairs(Animations) do
		if Animations.isInDefaultAnimScript(i) then
			local anim = Animations.LoadAnimation(i, true)
			if anim == nil then continue end
			anim:Stop()
		end
	end
end

--[[
	Pauses the supplied `Animate` script.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>Time</strong>: number</code>
	<em>Pauses the script for x time</em>
	> OPTIONAL
	
	To <strong>resume</strong>, set Animations.EnableScript to True
	
	<em><strong>Do not call this sucessively if using the `Time` parameter!</strong></em>
]]--
Animations.PauseAnimations = function(Time: number)
	Animations.EnableScript = false
	Animations.StopAllDefaultAnimations()
	if Time == nil or Time <= 0 then 
		return
	end
	task.wait(Time)
	Animations.EnableScript = true
end

return Animations