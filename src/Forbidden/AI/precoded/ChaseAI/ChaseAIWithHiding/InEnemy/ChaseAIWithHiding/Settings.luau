local config = {}

--[[ # KEY # 
	
	/!\ Commonly edited settings.
	"indentation" Dependent on setting above.

]]--

-- # NPC Parts /!\
config.enemy_char 		= script.Parent.Parent -- (default: script.Parent.Parent)
config.enemy_hrt 		= config.enemy_char:WaitForChild("HumanoidRootPart") -- (default: config.enemy_char:WaitForChild("HumanoidRootPart"))
config.enemy_head		= config.enemy_char:WaitForChild("Head") -- (default: config.enemy_char:WaitForChild("Head"))
config.enemy_human 		= config.enemy_char:WaitForChild("Humanoid") -- (default: config.enemy_char:WaitForChild("Humanoid"))


-- # Activation Handling
config.AI_Init_Time 				= 3 		-- In order to prevent errors, this is recommended. (default: 3)
config.isActive 					= true		-- Dictates whether the AI is activated. (default: true)
config.AntiLag 						= true		-- Dictates whether the AI antilag is activated. (places anti-lag script from Forbidden automatically) (default: true)
	-- Note about anti-lag:: the player will appear to be hit from a position it is not at, this is server->client ping, it is also modeled when running locally.
	-- By using anti-lag, many bugs disappear due to the server handling all calculations and not handing off the processing to the client.
	-- if not using the default anti-lag, you must write your own, for solo-games, you can pretty much just set the AI network owner to the player for the best experience.

	
-- //
-- Chase AI with hiding settings
config.LockerChase					= true				-- If true, the AI chases the player to the locker. (should it see them hide.)
	-- for further editing, go to the hooks. all implementation of this system, in connection to the original script, is done in there.
-- \\

-- # Behaviors
config.PreventAIFromSitting			= true		-- (default: true)
config.PreventAIFromRagdolling		= true		-- (default: true)



-- # Damaging / Hitbox System /!\
config.damageDelay 					= 1			-- In seconds, how long until the AI can damage again (or move if setting below is enabled) (default: 1)
config.damageDone 					= 100		-- (default: 100)
config.hitboxes						= {}		-- As default, HumanoidRootPart is used (NOT recommended to do GetChildren() on AI). (default: {})
config.disableAIWhileDamaging 		= false		-- (default: false)


-- # Detection Elements /!\
config.detectionRange				= 100
config.detectionFOV					= 70		-- In degrees, the detection FOV of the AI. LIMIT: 180 for full 360 degrees.
config.detectionBubble				= 5			-- In studs, if the AI should autodetect a player, regardless of angle, within a range.
config.OffsetFromPlayer 			= 0			-- In studs, the distance the AI will try to stay away from the player.
config.seeThroughTransparent 		= true		-- Whether or not the AI can see through transparent parts
config.seeThroughCanCollide			= true		-- Whether or not the AI can see through non-collidable parts.
config.LostSightTimer				= 1			-- For how long does the AI know where the player is after losing line of sight.
													-- purpose: think about kiting an AI around a bookshelf, without it, it won't check the corner the player ran around.


-- # Speeds /!\
config.wanderSpeed					= 16
config.chaseSpeed					= 20


-- # Pathfinding Settings
config.standardPathfindSettings 	= {
	AgentRadius = 2, 		-- default 2
	AgentHeight = 5, 		-- default 5
	AgentCanJump = true,	-- default true
	AgentCanClimb = false,	-- default false
	Cost = {}				-- default {}
}		-- should your AI get stuck on corners, tweak these as followed in https://create.roblox.com/docs/characters/pathfinding (Agent-Radius, etc..)
-- see bottom for example.


-- # Feature Enabling
config.doWander 					= true		-- Whether or not the AI will use the wander function when not chasing. (default: true)
	config.doRandomWander				= false		-- If true, calls "getRandomLocationInMap" (and gets pos above floors prov.), otherwise, calls "getRandomNode" for a part to go to. (default: false)
		config.debug_rand_pos 				= false 	-- If using the random wander function (default: false)
	config.nodes_table					= {}		-- If using random wander, give all valid floors. If not, give manually made nodes. (any models use primary part, if not, they are tossed) (default: {} -- empty) 
	config.WanderPauseTimer				= 0			-- Pause at node for x time. (default: 0)
	config.EnableNodeOrder				= false		-- Will follow the nodes in the order provided. (in the table) (default: false)

config.BadPathProtection			= true		-- ignores targets the AI fails to path to (for a period of time). (default: true)


-- Visualization /!\
config.Visualize					= false		-- Visualizes the pathfinding algorithm. (default: false)
	config.ViewCone						= false					-- Visualizes the view cone (if less than 90) (default: false)


-- # Chase Features
config.optimalChasing				= false		-- If there are nodes in front of the NPC when it reaches a corner where a player was, it will go to a random one before wandering anywhere else. -- [not active] (default: false)
config.NotInSightDoSprint			= true		-- if the player is not in sight, yet the AI is pathing to a location where it last saw it, should it sprint? (default: true)


-- # Limiting ChaseRange (ask in discord for use case or watch video)
-- Let's say you have a boss, you would want to limit the range it could move.
-- Or let's say you want an AI to guard its path, it could guard up until a certain range, as determined by the settings below.
-- Recommended to use both visualization options to determine your use case.
config.LimitChaseRange = false -- (default: false)
	config.MaxChaseRange				= config.detectionRange * 2 -- this is where the AI will give up. and retreat to its anchor point. (default: config.detectionRange * 2)
	config.AnchorPoint						 = config.enemy_hrt.CFrame.Position -- where the AI bases all of its information for chasing on. (at least as a default, necessary if doWander is false) (default: config.enemy_hrt.CFrame.Position)
	config.MeasureChaseRangeFromWhereStarted = not(config.doWander) -- (normally, distance is measured from AI vs from Anchor Point, if true, the distance will be from the anchor point) (default: not(config.doWander))
	config.MustReturnToAnchorPoint			 = false -- if false, the AI can kind chase after individuals endlessly, especially in tandem with the above setting false. (default: false)


-- # Hooks Customizing

-- # Attack Range Hook Settings
config.MinAttackRange 					= config.OffsetFromPlayer + 5
	config.CallAttackRangeHooksWhenChange	= true		-- If false, calls constantly per tick. If true, only a change in the state (i.e. Outside/Inside attack range.)
	config.CallOutsideAttackRangeOnDeath	= true 		-- Will call the `OutsideAttackRange` hook on player Death. (passes player instead.)


-- # Flow Control (AP = After Pause (ChaseAI.PauseAI() hook))
-- Should you manually pause the AI in Hooks, these functions control the retargeting, (i.e. if you pause and do an attack, how should the target be reacquired)
config.AP_FocusPreviousTarget	= true	-- Attempts to chase the previous target (unless out of chase range / FOV below). (default: true)
	config.AP_FOVIncrease			= config.detectionFOV -- only checks it with increased FOV for the previous target. (default: config.detectionFOV)
		config.AP_FOVIncreaseOnForAll	= false -- applys the above FOV check for all targets. (default: false)


--[[ Example
config.standardPathfindSettings 	= {			-- optimized for default dummies.
	AgentRadius = 2.25, 	-- default 2
	AgentHeight = 5.5, 		-- default 5
	AgentCanJump = true,	-- default true
	AgentCanClimb = false,	-- default false
	Cost = {}				-- default {}
}		-- note: map design is crucial, Forbidden cannot alter Roblox's algorithm, always make sure meshes have CanQuery off (then make a hitbox around it).

]]

return config