--[[

Forbidden v0.0.10 [Alpha]

Thank you for using Forbidden! Remember to look inside the modules you are using
for detailed explanations.

For more info on how to use modules go to Crit on YT (@CritDev) 
https://www.youtube.com/channel/UCD3EEMeX-fLtHfd1pg09SSQ

Discord: discord.com/invite/7vTTmRC2Zm

Please Like and Subscribe to Support the Project
Send your projects using Forbidden in a comment section!

Much love, @rman501


UPDATE LOGS BELOW
UPDATE LOGS BELOW
UPDATE LOGS BELOW
UPDATE LOGS BELOW
UPDATE LOGS BELOW


Known bugs:

	Modules can take up to 20 seconds to load in (noticable by shadows being updated visually; I believe it is a Roblox high graphics settings issue)
	
	Module loading in while facing attempted usage will brick any script without error codes, leading to confusion - solution, AI_Init_Time in precoded examples.
	
	Lock Icon not shown when player loads. (all functionality remains.) - Pets (not impl. yet)


Common Fixes:
	
	Restart Studio. Confirmed issue with Roblox Studio for many issues.
	
	
If none of the above works, send a comment, or a bug report in the discord, with the following information:
	
	>	Module used
	
	> 	Error (either quantative or qualitive)
	
	> 	Call to module
	
	> 	Example (optional)
	
	> 	Video	  (optional)
	
	> 	A possible way to replicate (optional)


------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------
------------------------------------------------------------------------------
--FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN----FORBIDDEN--
------------------------------------------------------------------------------


								UPDATE LOGS
						@rman501 > Lead Developer
						
UPDATE v0.0.18 - "The Big One"

	- AI 	| Rewritten for ideal concurrency handling and reliability.
			| Now, do not use ai.Stop if an immediate recall is imminent.
		
		>	Rewrote the concurrency handler (4 tiers of detection, {STATE, TOKEN, CALL_TIME, CONCURRENT_CALL_STATE})
		
		>	MoveToTargetRoot issue patched where the AI would run off to nowhere
		
		>	MoveToTargetRoot can now guess when the AI needs to jump, (only if AgentCanJump is true)
		
		>	If any of the waypoints skipped has a jump call, then the AI will jump.
		
	- ChaseAI
	
		>	Hooks added
		
		>	The core scripts of ChaseAI & ChaseAIWithHiding are now identical
		
		>	ChaseAIWithHiding can now be updated by only updating the actual script and leaving the hooks unless otherwise stated.
		
		>	ai.Stop's removed as the new AI module has optimal concurrency handling if they are.
	
	
	- Future
	
		>	Alternate targets support for ChaseAI (i.e. other NPCs).
		
		
		
UPDATE v0.0.17

	- AI
		
		>	Removed Anti Stuck call when UnableToPath is called.

	- Math
	
		>	IsInView
		
			>	Folder support added.
						
						
						
UPDATE v0.0.16

	- AI
	
		>	Stutter Solved
		
		>	Persistant Pathing
		
			-	Former correct path will be listened to when tracking fails. ( # Reverted # )
				
		
	- ChaseAI
	
		>	README added
			
			-	Ungroup folders
			
			-	Video Links



UPDATE v0.0.15

	- AI
	
		>	Made non-tracking calls more accurate
		
		>	moveToTargetRoot now runs faster and more accurately (refactored moveToHRT).
		
		>	Made the code more reliable in general.
		
		>	Predictive MoveTo settings added


	- ChaseAI
		
		>	Added NPC Death Detection in core loop
		
		>	Fixed a bug where the AI would spam call wander? (this bug is random and could be patched 🤷)
		
		>	Bad Pathing protection added.
		
		>	optimalChasing setting not implemented.



UPDATE v0.0.14

	- AI
	
		>	Type handling for Target was not handled properly.
	
	
	- GPS (addon in discord for free)
	
		>	Updated to latest SmartPathfind variation.
		
		>	Tracks both movement of player and target now.
		
		>	Fixed related bugs to move.
				
			
			
UPDATE v0.0.14

	- AI
	
		>	Patched a bug where if all hooks weren't provided the script errored stating it couldn't find a function.
			
			
			
UPDATE v0.0.13

	- AI.Precoded
	
		>	Fixed AI wandering to ~0,0,0 bug.
		
		>	Vector3 / CFrame Support
		
		>	ToGround System to prevent AI from getting juked in the Air/Freefall
		
		>	Bad MoveTo protection
		
		>	Various error handling / refactoring changes
				
				
	- AI
					
		>	Hooks Added
			
			>	To connect, add to the settings `Settings.Hooks.chosenHook = function(the, params) -- your code end`

			ComputedWaypoints: (waypoints: {PathWaypoint}) -> nil,
			WaypointsFolderCreated: (waypointsFolder: Folder) -> nil,
			MovingToWaypoint: (waypoint: PathWaypoint) -> nil,
			GoalReached: (goal: any) -> nil,
			UnableToPath: (goal: any, message: string) -> nil,
			Stuck: (goal: any, waypoint: PathWaypoint) -> nil
			
			
					
UPDATE v0.0.12

	- DeveloperProductHandler
	
		>	An easy to use and configure DeveloperProductHandler, to get all the spaghetti code out of the way!
		
		
	- (DISCORD ONLY, still free) WaypointVisualizer
	
		>	For those who wanted to guide a player for like a quest. This would do that.
		
		>	See #Forbidden-addons in the discord, link for it is at top of doc.
	
	
	- AI.precoded
	
		>	ClientHideHandler now accepts multiple input types (all).
			
			
	- Information
	
		>	Cleaned update log.
		
		
		
UPDATE v0.0.11

	- AI.precoded
		
		>	Added optimalTracking If enabled, when the AI loses the player it will track to a node in front of the AI (implemented very roughly, fix soon)
		
		>	Updated config.nodes_table to allow for multiple tables, auto-handling of various types, etc... to reduce errors and improve QoL.
		
		>	Fixed Visualize not visualizing portions of the AI.
	
	
	- Math.LineOfSight
	
		>	Fixed an issue where SeeThroughTransparentParts would have maximum iterations exceeded, or may not even work.
		
		
		
UPDATE v0.0.10

	- Added Documentation
	
	
	- DataStore
	
		>	Removed.
				
		
		
UPDATE v0.0.9

	- AI.SmartPathfind
	
		>	Added a StopTimer, and PathfindStopType for choosing how the pathfind will end on AI.Stop
			StopTimer only applies to CurrentPosition due to asynchronous threads.
			
			
	- Math.LineOfSight
		
		>	Various Bug Fixes
	
	
	- Math->IsInView
	
		>	Added.
		
		> 	RaycastParameters added.
				
				
				
UPDATE v0.0.8

	-	AI System rewrite.
	
	 *	"Actually looks like a script, and not c***kwired!" - @rman501
	
		>	Thank you for the play testers who helped once and for all solve the issues with the AI system and dependents
				- @RJCowles, @Fastboy_Gaming
			Check out the games I'm making with them, they will be on my channel (very bad games, but just to demonstrate Forbidden!)
		
		
									
UPDATE v0.0.7

	- Notable Changes
	
		>	AI Precoded Examples Rewrite.
	
	
	- NEW! Math->IsInView
	
		>	Check if an NPC or any humanoid can see a part in the game!
		
		%% LookVector of character head.
		

	- NAME CHANGE! Math.IsOnScreen
	
		>	Changed to IsInView to IsOnScreen to more appropiately reference that is to check if something is on the players screen.


	- AI
			
		>	As good practice, it is recommended to require the AI module on the server-side and do, ai.Stop(npc: Model) through there
		otherwise, the delay in the event may mess up certain scripts (tracking, nextbots, etc...)	
				
			
			
UPDATE v0.0.6

	- AI.precoded.ChaseAI.ChaseAIWithHiding
	
		> 	A basic hiding system to get you started, implemented using the ChaseAIBase!
		
		
	- AI.precoded.ChaseAI
	
		>	Cleaning of settings, finishing of StandardPathfindSettings, setting.
		
		>	Added AntiLag setting.
		
		
	- Bug Fixes
	
		>	Missed passed parameters in calls to hooked functions in ChaseAIBase.
		
		>	AI.SmartPathfind - StandardPathfindSettings was not defaulted correctly.
		
		>	AI.precoded - PlayerChaseBegan was not hooked.
		
		>	AI.precoded - AI now has a setting to disable sitting.
		
		>	AI.precoded - cleanNodesTable did not remove non-BaseParts from the table.
		
		>	AI.precoded - cleanNodesTable did not remove iteratively, added concurrency protection as well.
		
		>	AI.precoded - reduced network ownership api usage to reduce induced lag.
		
		
	- Major Bug Fixes
		>	AI.precoded.ChaseAI - NPC would sometimes nope out, and just turn around. Very complex ALLT solution (Anti Lock Lost Timing)
			Note: Awful, but it serves to protect against most problems

		%% note from present (0.0.12), this is solved.


UPDATE v0.0.5

	- AI.precoded.ChaseAI.ChaseAIBase
	
		> An example script with settings and functions to get you started.
			Yes the code is pretty difficult to read, yes it is my fault.
			Leave a comment in a video saying you want me to comment it and I will but the key functions are labeled
			for your use :). (please edit them, make it your own!)
			
			
	- AI.SmartPathfind
	
		> Fixed an issue where the waypoints would not delete unless Settings.Visualize was set to true. 


UPDATE v0.0.4

	- AI.SmartPathfind
	
		>	Added 'SwapMovementMethodDistance' setting: allows control of the distance at which the ai stops pathfinding and just tries to move to the player if its in LoS.
		
		>	If no path is available, the script now returns Enum.PathStatus.NoPath (only when Yield = true as no value is returned otherwise.)



UPDATE v0.0.3

	- AI.SmartPathfind
	
		>	Added 'Tracking' setting
		
		>	Fixed major bug where two pathfinds would conflict
		
		>	Fixed multithreading issues.
	
	
	- NEW! Math.Round
		
		> 	Vector3
		
		> 	Number
		
		> 	Int
		
		> 	adding more soon...
	
	
	- Math
	
		> 	LineOfSight bug fix



UPDATE v0.0.2

	Multiplayer.Queue
	
		>	Added precoded queue functions (Multiplayer.Queue)
	
	
	Standard
	
		>	Added teleport with extreme flexibility
	
	
	AI
	
		>	Major bug fixes
		
	
	
Release
	
	- AI
	
		>	SmartPathfind
		>	Stop
		>	Signals
		
		
	- Deque by Pierre "Maxwell" Chapius (github)
	
	
	- Math
		
		>	LineOfSight
			
			>	SeeThroughTransparentParts (LOS check functionality update)
		
		
	- Standard
		
		> GetType
		
		
		
@rman501, @CritDEV on YT. Thank you for using Forbidden.
]]--