local API = {}

local dss = game:GetService("DataStoreService")
local dsName = "Forbidden"

local store = nil

API.ForceSave = function(plr: Player) -- it will already save automatically on leave and close but this is for the developers peace of mind
	
	if store == nil then error("Store not found!") return end
	
	local player_data = {} -- condense to one table with (index = value)
	
	for i, stat in pairs(plr:WaitForChild("leaderstats"):GetChildren()) do -- grab all data in the leaderboard
		player_data[stat.Name] = stat.Value
	end

	for i, stat in pairs(plr:WaitForChild("StoredValues"):GetChildren()) do -- grab all data that is stored.
		player_data[stat.Name] = stat.Value
	end
	
	local attempts = 0
	local maxAttempts = 3 -- attempts alloted to the save
	
	local function save()
		
		local success, err = pcall(function()
			store:SetAsync("Player_" .. plr.UserId, player_data)
		end)
		
		if err then
			return false
		end
		
		if success then
			return true
		end
	end
	
	while attempts < maxAttempts do -- give it 3 attempts to save successfully
		
		attempts+=1
		local result = save()
		if result then break end
	end
end

API.Activate = function(leaderstats: "Table; Key = DefaultValue", StoredValues: "Table; Key = DefaultValue", optionalDataStoreName: string)
	
	local function create(plr: Player) -- create values.
	
		local leaderstatsFOLD = Instance.new("Folder")  --Sets up leaderstats folder
		leaderstatsFOLD.Name = "leaderstats"
		leaderstatsFOLD.Parent = plr

		local storedvaluesFOLD = Instance.new("Folder") --stuff that doesN'T go to leaderboard, but still is stored in the player.
		storedvaluesFOLD.Name = "StoredValues"
		storedvaluesFOLD.Parent = plr
		
		for i, v in pairs(leaderstats) do
			local value = Instance.new("NumberValue")
			value.Parent = leaderstatsFOLD
			value.Value = v
			value.Name = i
		end

		for i, v in pairs(StoredValues) do
			local value = Instance.new("NumberValue")
			value.Parent = storedvaluesFOLD
			value.Value = v
			value.Name = i
		end
		
	end
	
	local function load(plr: Player) -- load data
		
		create(plr)
		
		if optionalDataStoreName then dsName = optionalDataStoreName end
		
		store = dss:GetDataStore(dsName)
		local data = store:GetAsync("Player_" .. plr.UserId)
		
		if data then -- load data, defaults already loaded before this is called (index = value)\
			
			for i, v in pairs(plr:WaitForChild("leaderstats"):GetChildren()) do
				if data[v.Name] ~= nil then
					v.Value = data[v.Name]
				end
			end
			
			for i, v in pairs(plr:WaitForChild("StoredValues"):GetChildren()) do
				if data[v.Name] ~= nil then
					v.Value = data[v.Name]
				end
			end
			
		end
	end
	
	game.Players.PlayerAdded:Connect(load)
	game.Players.PlayerRemoving:Connect(API.ForceSave)
	game:BindToClose(function()
		for i, v in pairs(game:GetService("Players"):GetChildren()) do
			API.ForceSave(v) -- force save players in match on close.
		end
	end)
end

return API
