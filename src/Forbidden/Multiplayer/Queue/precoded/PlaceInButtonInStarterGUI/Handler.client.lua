-- Services
local rs = game:GetService("ReplicatedStorage")

-- Referencing
local forbidden = rs:WaitForChild("Forbidden")
local multiplayer = forbidden:WaitForChild("Multiplayer")
local queue = multiplayer:WaitForChild("Queue")

local signals = queue:WaitForChild("signals")
local join = signals:WaitForChild("join")
local leave = signals:WaitForChild("leave")
local matchmade = signals:WaitForChild("toClientMatchInfo")





-- USER OPTIONS BELOW 
-- USER OPTIONS BELOW 
-- USER OPTIONS BELOW 
-- USER OPTIONS BELOW 
-- USER OPTIONS BELOW 




-- Settings
local button = script.Parent
local TimeToLeaveQueue = 0 -- Change if you want the player to wait (x) seconds before the leave request is sent to the server



local queuing = false
local db = false
local db2 = false




local function MatchFound(players) -- players is a table of all players (including this player)
	
	--button.Visible = false -- example
	
end

local function JoinRequestSent()
	
end

local function LeaveRequestSent()

	-- your code here
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


-- required

local function Join()
	
	if db2 then return end
	

	db2 = true
	join:InvokeServer()
	JoinRequestSent()
	db2 = false
end

local function Leave()
	
	if db2 then return end
	
	db2 = true
	task.wait(TimeToLeaveQueue)
	leave:InvokeServer()
	LeaveRequestSent()
	db2 = false
end

local function onPress()
	
	if queuing then
		
		queuing = false
		db = true
		Leave()
	end
	
	if db then db = false return end
	
	if not queuing then
		
		queuing = true
		Join()
	end
end

button.MouseButton1Up:Connect(onPress)
matchmade.OnClientEvent:Connect(MatchFound)