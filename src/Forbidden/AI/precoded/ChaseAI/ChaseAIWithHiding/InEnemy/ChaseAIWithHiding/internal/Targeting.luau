local API = {}

-- # References --
local players	= game:GetService("Players")
local rs		= game:GetService("ReplicatedStorage")

local int_Forbidden	= rs:WaitForChild("Forbidden")
local std			= require(int_Forbidden:WaitForChild("Standard"))

local c_ai_script 	= script.Parent.Parent
local config 		= require(c_ai_script:WaitForChild("Settings"))
local hooks_mod		= c_ai_script:WaitForChild("Hooks")
local hooks			= require(hooks_mod)
local common		= require(hooks_mod:WaitForChild("Common"))

-- 10/31/24 @rman501, refactored to use Math module
local chasePart 	= nil
API.isInView = function(plr_char: Model, overridenFOV: number?) -- Determines if a model is in the view of the AI.

	if chasePart == nil then
		chasePart = config.enemy_char:FindFirstChild("ChasePartForNPC-Forbidden")
	end
	

	local tempVar = overridenFOV
	if tempVar == nil then
		tempVar = config.detectionFOV
	end

	-- idiot protection (me protection :) )
	if typeof(tempVar) ~= "number" then error("[ChaseAI] FOV provided is not a number") end
	tempVar = math.min(180, math.max(0, tempVar))

	local result = std.math.IsInView(config.enemy_char, plr_char, tempVar, true, {range = config.MaxChaseRange, SeeThroughTransparentParts = config.seeThroughTransparent, SeeThroughNonCollidable = config.seeThroughCanCollide, filterTable = {config.enemy_char, chasePart} })
	return result
end

local AP_PREV_TARGET: Model? = nil -- 10/31/24 @rman501, character because if plr died, this would become nil. 
API.SetPreviousTarget = function(newTarget: Model?)
	AP_PREV_TARGET = newTarget
end

local pausedFlag = false
API.SetPausedFlag = function()
	pausedFlag = true
end

--local NPC_List = {}
API.GetNearestVisiblePlayer = function()

	local playersInLOS = {}

	-- Make sure no bad paths exist.
	local newTable = {}

	for i, v: {player: Player, bpt: number} in pairs(hooks.In.GetBadPathVictims()) do
		if v[1] == nil then continue end
		if os.clock() - 3 < v[2] then
			table.insert(newTable, v)
		end
	end

	hooks.In.SetBadPathVictims(newTable)

	for i, player in pairs(players:GetChildren()) do

		if common.CharacterIsDead(player.Character) then continue end

		if not hooks.Out.IsATarget(player) then continue end

		local plr_char = player.Character
		local plr_human = plr_char:FindFirstChild("Humanoid")
		local plr_hrt = plr_char:FindFirstChild("HumanoidRootPart")

		-- 10/22/24 @rman501, LimitChaseRange
		local dist = common.GetDistanceToPlayer(player)
		if config.detectionRange < dist then continue end -- 10/24/24 @rman501, inverse comparison error.



		-- 10/20/24 @rman501, if dead, then consider it.
		if plr_human.Health <= 0 then continue end

		-- 9/28/24 BadPathProtection, Added.
		if config.BadPathProtection then
			
			local function isBPV()
				for i, v: {player: Player, bpt: number} in pairs(newTable) do
					if v[1] == player then
						return true
					end
				end

				return false
			end

			if isBPV() then
				continue
			end
		end

		-- 10/31/24 @rman501, increased FOV check after pause 
		if config.AP_FOVIncrease ~= config.detectionFOV and AP_PREV_TARGET ~= nil then
			if AP_PREV_TARGET == plr_char then -- already did nil check above.
				if API.isInView(plr_char, config.AP_FOVIncrease) then
					table.insert(playersInLOS, {dist, player})
				end
				continue
			end

			if config.AP_FOVIncreaseOnForAll then
				if API.isInView(plr_char, config.AP_FOVIncrease) then
					table.insert(playersInLOS, {dist, player})
				end
				continue
			end
		end

		if API.isInView(plr_char, nil) then
			table.insert(playersInLOS, {dist, player})
			continue
		end

		if dist <= config.detectionBubble then --untested

			local result = std.math.LineOfSight(config.enemy_char, plr_char, {range = config.detectionRange, SeeThroughTransparentParts = config.seeThroughTransparent, SeeThroughNonCollidable = config.seeThroughCanCollide, filterTable = {config.enemy_char, chasePart}})

			if result then
				table.insert(playersInLOS, {dist, player})
				continue
			end
		end

	end

	local nearestPlr = nil
	local nearestDist = math.huge
	
	for i, data in pairs(playersInLOS) do

		if data[2] == nil then continue end -- just in case

		if nearestDist > data[1] then
			nearestDist = data[1]
			nearestPlr = data[2]
		end

		-- 10/31/24 @rman501, target previous player after stun if possible.
		if AP_PREV_TARGET ~= nil and config.AP_FocusPreviousTarget and pausedFlag then
			if data[2].Character == AP_PREV_TARGET then
				nearestPlr = data[2]
				break
			end
		end

	end

	-- reset paused flag
	if pausedFlag then
		pausedFlag = false
	end

	AP_PREV_TARGET = nil -- 10/31/24 @rman501, reset AP sys.
	return nearestPlr
end

return API