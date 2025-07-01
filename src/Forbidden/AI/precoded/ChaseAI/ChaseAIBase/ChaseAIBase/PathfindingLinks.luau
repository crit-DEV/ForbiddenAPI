local PathfindingLinks = {}

-- Useful inclusions
local config = require(script.Parent:WaitForChild("Settings"))
local common = require(script.Parent:WaitForChild("Hooks"):WaitForChild("Common"))

-- DO NOT TOUCH
PathfindingLinks.MANAGER = function(wp: PathWaypoint): boolean

	if wp.Label == "" then
		return PathfindingLinks.NoLabelProvided(wp)
	end

	if PathfindingLinks[wp.Label] then
		return PathfindingLinks[wp.Label](wp.Position)
	end

	return PathfindingLinks.Default(wp)
end

-- If there is no specific code for a waypoint, this function is called
-- You could just make this teleport the AI then return true
PathfindingLinks.Default = function(wp: PathWaypoint): boolean
	warn("[ChaseAI.PathfindingLinks] Pathfinding Link (" .. wp.Label .. ") had no code associated with it.")
	return true
end

-- If the label is blank "", it defaults to this function
PathfindingLinks.NoLabelProvided = function(wp: PathWaypoint): boolean
	warn("[ChaseAI.PathfindingLinks] Pathfinding Link (" .. wp.Label .. ") had no code associated with it.")
	return true
end

-- Example (there is a pathfinding link with the label PF1)
-- TP Enemy, Wait 3 Seconds, Resume Pathfind
-- Set the Name of the function to the label.
-- Return true to resume normal pathfind operation
PathfindingLinks.PF1 = function(WaypointPosition: Vector3): boolean
	config.enemy_hrt.CFrame = CFrame.new(WaypointPosition + Vector3.new(0,3,0))
	task.wait(3)
	return true
end

return PathfindingLinks