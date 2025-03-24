
--[[

# Overview

	Simple pathfinding module with tracking and precoded solutions.
		
		The module can track, yield the thread, and has various options.


# Troubleshooting

	Most of the time any issues that arise will be with Forbidden. But there are cases where common issues and misunderstandings 
	arise
	
		1. Make sure the target doesn't disappear (this actually happens alot, bc unanchored or other reasons)
		2. Make sure the terrain is actually passable.
		3. Terrain is a big issue with Roblox's pathfinding system so keep that in mind.
		4. Any lag that appears when the NPC goes close to a player is caused by the parts not doing "part:SetNetworkOwner(nil)" 
		The antilag included is not the best fix to this issue, just my attempt to mitigate this issue as much as possible for
		new developers.
		
		5. Forbidden DOES NOT support trusses.
		
		
		Any questions or issues please DM crit#0271 on discord.
	
# Functions

	> API.SmartPathfind(NPC: Model, Target: Part or Model, Yields: Boolean, Settings: Table)
	
		NPC - The NPC you want to move. Can be R6, R15. Newer models untested but should work.
		
		Target - A part or model that you want it to pathfind to. Will support positional data in the future.
		
		Yields - Whether the script the function was called from will yield until the AI reaches its destination
		
		SmartPathfindSettings - 
		{
			StandardPathfindSettings: { -- see https://create.roblox.com/docs/characters/pathfinding
				AgentRadius = 2,
				AgentHeight = 5,
				AgentCanJump = true,
				AgentCanClimb = false,
				Cost = {}
			}, 
			Visualize: boolean, 						-- Visualizes the pathfinding waypoints.
			Tracking: boolean, 							-- continues till AI:Stop(NPC) or different pathfind is started. Updates Pathfind when target loc changes.
			SwapMovementMethodDistance: number -		-- Intelligently uses this setting and the beneath line of sight settings to have more accurate close range tracking when the AI is close to the target,
			SMMD_RaycastParams: RaycastParams
			{
				range: number,  							-- the range of the raycast.
				SeeThroughTransparentParts: boolean,  		-- whether or not transparent parts are accounted for in the LoS check.
				filterTable: {} 							-- parts (and their descendants) the raycast should ignore.
			}	
			RetrackTimer: number, 						-- How long will Tracking wait to check if the pathfind should be recalled.
			SkipToWaypoint: number,  					-- how many waypoints should the NPC skip? For tracking this fixes the stutter bugs. Alternatively, you can alter waypoint spacing in StandardPathfindSettings.
			PathfindStopType: "API.PathfindStopType"? 	-- What kind of stop will be performed when AI.Stop() is called.
			StopTimer: number, 							-- If PathfindStopType is set to CurrentPosition, then this is how long it will take for the MoveTo to be called.
			Hooks: {
				WaypointsCreated: (waypointsFolder: Folder) -> {},
				Stuck: () -> {},
				MovingToWaypoint: (waypoint: Waypoint) -> {},
				GoalReached: (goal) -> {},
				UnableToPath: (goal) -> {}
			}
		}

	> API.Stop(NPC: Model)
	
		Halts the specified model if it is pathfinding. could take a bit to stop depending on pf state (see StopTimer setting)
		
	> API.Stuck(NPC: Model)
	
		Unsticks the NPC



@rman501 (RBLX)  @CritDEV (YT)
]]--