local API = {}
local config = require(script.Parent.Parent:WaitForChild("Settings"))
local Animations = require(script.Parent:WaitForChild("Animations"))

-- 10/26/24 @rman501, changed to reflect distance around AI body.

--[[
	Gets the distance to the NPC from the part provided.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>Part</strong>: BasePart</code>
	<em>The object to measure the distance from</em>
	
	This method is more accurate than your normal call as it considers the NPCs height,
	therefore getting the actual closest point. (assuming the radius is 0, but the radius can be considered externally if you need so).
	
	
	<strong>Example Code</strong>
	<code>
		local common = require(...) -- path to module
		
		local part = ...
	
		local dist = common.GetDistanceToPart(part)
		print("Distance: " .. dist)
	</code>
]]--
API.GetDistanceToPart = function(Part: BasePart): number
	
	if Part == nil then return math.huge end
	
	-- various details about enemy and target
	local hrtPos	= config.enemy_hrt.CFrame.Position
	local hipheight = config.enemy_human.HipHeight
	local feetPos 	= hrtPos - Vector3.new(0, hipheight + config.enemy_hrt.Size.Y / 2, 0)
	local headPos	= config.enemy_head.CFrame.Position
	local targetPartPos  = Part.CFrame.Position

	local isBelow	= feetPos.Y > targetPartPos.Y
	local isBetween	= feetPos.Y <= targetPartPos.Y and headPos.Y >= targetPartPos.Y
	local isAbove	= headPos.Y < targetPartPos.Y

	if isBelow then
		return (feetPos - targetPartPos).Magnitude
	end

	if isBetween then
		return (Vector3.new(hrtPos.X, targetPartPos.Y, hrtPos.Z) - targetPartPos).Magnitude
	end

	if isAbove then
		return (headPos - targetPartPos).Magnitude
	end
end

--[[
	Gets the distance to the NPC from the character provided.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>Character</strong>: Character</code>
	<em>The character to measure the distance from</em>
	
	This method is more accurate than your normal call as it considers the NPCs height,
	therefore getting the actual closest point. (assuming the radius is 0, but the radius can be considered externally if you need so).
	
	
	<strong>Example Code</strong>
	<code>
		local common = require(...) -- path to module
		
		local part = ...
	
		local dist = common.GetDistanceToPart(part)
		print("Distance: " .. dist)
	</code>
]]--
API.GetDistanceToCharacter = function(Character: Model): number
	if Character == nil then return math.huge end
	
	local hrt = Character:FindFirstChild("HumanoidRootPart")
	if hrt == nil then return math.huge end
	
	return API.GetDistanceToPart(hrt)
end

--[[
	Gets the distance to the NPC from the player provided.
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>Player</strong>: Player</code>
	<em>The player to measure the distance from</em>
	
	This method is more accurate than your normal call as it considers the NPCs height,
	therefore getting the actual closest point. (assuming the radius is 0, but the radius can be considered externally if you need so).
	
	
	<strong>Example Code</strong>
	<code>
		local common = require(...) -- path to module
		
		local part = ...
	
		local dist = common.GetDistanceToPart(part)
		print("Distance: " .. dist)
	</code>
]]--
API.GetDistanceToPlayer = function(Player: Player): number
	if Player == nil then return math.huge end
	
	return API.GetDistanceToCharacter(Player.Character)
end


--[[
	Returns true if the player is died, alive, or exploded (lol).
	<em>Expand this window for explanation of calls, settings, and example scripts.</em>
	
	<code><strong>Character</strong>: Character</code>
	<em>The character to check</em>
	
	
	<strong>Example Code</strong>
	<code>
		local common = require(...) -- path to module
		
		local target = ...
	
		local isDead = common.CharacterIsDead(target)
		if isDead then print("DEAD!") end
	</code>
]]--
API.CharacterIsDead = function(Character: Model): boolean
	if Character == nil then return true end
	if Character:FindFirstChild("HumanoidRootPart") == nil then return true end
	
	local human = Character:FindFirstChild("Humanoid")
	if human == nil then return true end
	if human.Health <= 0 then return true end
	
	return false
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
API.LoadAnimation = function(AnimationId: number?, CacheAnimation: boolean): AnimationTrack
	return Animations.LoadAnimation(AnimationId, CacheAnimation)
end

return API