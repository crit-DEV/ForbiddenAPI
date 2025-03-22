-- Settings
local playersRequired = 2
-- Services
local rs = game:GetService("ReplicatedStorage")

local forbidden = rs:WaitForChild("Forbidden")
local multiplayer = forbidden:WaitForChild("Multiplayer")
local queueMOD = require(multiplayer:WaitForChild("Queue"))
local std = require(forbidden:WaitForChild("Standard"))

local queueFOL = multiplayer:WaitForChild("Queue")
local signals = queueFOL:WaitForChild("signals")
local join = signals:WaitForChild("join")
local leave = signals:WaitForChild("leave")
local matchmade = signals:WaitForChild("toClientMatchInfo")
local server_matchmade = signals:WaitForChild("toServerMatchInfo")



local function MatchFound(players)
	
	--[[ ex. code (when match is found teleport the players)
	print(players)
	
	local destination = Vector3.new(0,0,0) -- can be a vector3, CFrame, part, or model
	
	for i, plr in pairs(players) do
		std.basic.Teleport(plr, destination, 1)
	end
	]]--
end








------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------



local queue = queueMOD.New()


local function Matchmaking()
	
	local length = queueMOD.Length(queue)
	
	if playersRequired > length then return end
	
	local match = {}
	
	for i=1,length,1 do
		
		match[i] = queueMOD.RemoveFront(queue)
	end
	
	for i, plr in pairs(match) do
		matchmade:FireClient(plr, match)
	end
	
	server_matchmade:Fire(match)
	MatchFound(match)
end

function joinRequest(plr)
	
	queueMOD.AddToBack(queue, plr)
	
	Matchmaking()
end

function leaveRequest(plr)
	
	queueMOD.Remove(queue, plr)
end

join.OnServerInvoke = joinRequest
leave.OnServerInvoke = leaveRequest