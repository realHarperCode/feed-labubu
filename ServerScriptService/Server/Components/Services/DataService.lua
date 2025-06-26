-- @ScriptType: ModuleScript
--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Services

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Network = require(ReplicatedStorage.Database.Security.Network)

local DataService = {}

DataService.LoadedData = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Modules

local TycoonService = require(ServerScriptService.Server.Components.Services.TycoonService)

local ProfileService = require(ReplicatedStorage.ProfileService)
local Observer = require(ReplicatedStorage.Packages.Observer)
local Promise = require(ReplicatedStorage.Packages.Promise)
local Maid = ModuleLoader.Import("Packages/Maid")

local Staff = require(ReplicatedStorage.Database.Custom.Configs.Staff)
local Store = require(ServerScriptService.Server.Components.Data.Store)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Variables

-- TODO: Move all these tables to their own files

local ProfileTemplate = {
	--// Data
	LogInTimes = 0,
	LastOnline = 0,
	DailyReward = {
		Streak = 1,
		Claimed = {}
	},
	
	--// Player Values
	Coins = 0,
	TotalEarnedCoins = 0,
	Items = {},
	
	Rebirths = 0,
	
	Codes = {},
	
	--// Robux Purchased Upgrade Data
	Upgrades = {
		Global = {
			NextGrowthUpgrade = Store["2x Growth"],
			Purchases = {},
			Multiplier = 1
		},
		Clicker = {
			NextGrowthUpgrade = Store["2x Growth"],
			Purchases = {},
			Autoclicker = false,
			Multiplier = 1
		},
		["Fruit Patch"] = {
			NextGrowthUpgrade = Store["2x Growth"],
			Purchases = {},
			Multiplier = 1
		}
	},
	
	Tycoon = {
		--// Pet
		Pet = {
			PetNumber = 1,
			PetWeight = 0
		},
		
		--// Machines
		Farms = {},
	},
	
	Settings = {
		ShadowsEnabled = true,
		MusicVolume = 0.3,
		
		GroupVolume = {
			Magic = 1,
			Human = 1,
			Vampire = 1,
			Interface = 1
		},
		
		Keybinds = {},
		ActionSlots = {}
	}
}


local playerDataMain = ProfileService.GetProfileStore(
	"PlayerDataStore74713491",
	ProfileTemplate
)

--local ProfileStorage = {}
local PlayerStorage = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Functions



--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Public Functions

--function DataStoreServer:CreateStore(profileKey: string, profileData: {any})
--	ProfileStorage[profileKey] = ProfileService.GetProfileStore(
--		profileKey,
--		profileData
--	)

--	PlayerStorage[profileKey] = {}
--end

function DataService:LoadProfile(playerUserID: number)
	if not PlayerStorage[playerUserID] then
		PlayerStorage[playerUserID] = playerDataMain:LoadProfileAsync(tostring(playerUserID))
		
		if PlayerStorage[playerUserID] then
			PlayerStorage[playerUserID]:AddUserId(playerUserID)
			PlayerStorage[playerUserID]:Reconcile()
		end
		
		local playerUser = Players:GetPlayerByUserId(playerUserID)
		
		PlayerStorage[playerUserID]:ListenToRelease(function()
			PlayerStorage[playerUserID] = nil
			
			if not playerUser then
				return
			end
			
			--playerUser:Kick("Data released") -- NOTE RE-ADD WHEN OUT OF DEVELOPMENT
			--warn("kickwarns:DataService")
		end)
		
		--if not playerUser:IsDescendantOf(Players) then
		--	PlayerStorage[playerUserID]:Release()
		--end
	end
	
	return PlayerStorage[playerUserID].Data
end

--function DataStoreServer:ResetProfile(profileKey: string, playerUserID: number)
--	if not profileStores[profileKey] then
--		warn("NOT FOUND PROFILESTORE")
--		return
--	end

--	if not playerStores[profileKey][playerUserID] then
--		return
--	end

--	playerStores[profileKey][playerUserID].Data = {}
--	playerStores[profileKey][playerUserID]:Reconcile()

--end

function DataService:promiseLoad(playerUserID: number)
	return Promise.new(function(resolve, reject)
		local playerUser = Players:GetPlayerByUserId(playerUserID)
		
		local loadedData = DataService:LoadProfile(playerUserID)
		
		resolve(loadedData)
	end)
end

function DataService:promiseLoadGuild(guildName: string)
	return Promise.new(function(resolve, reject)
		local loadedData = DataService:LoadGuildProfile(guildName)
		
		resolve(loadedData.Data)
		
		loadedData:Release()
	end)
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Initialize

ModuleLoader:OnStart(function()
	
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Events

MessagingService:SubscribeAsync("DataAdded", function(receivedPlayer)
	table.insert(DataService.LoadedData, receivedPlayer.Data)
end)

MessagingService:SubscribeAsync("DataRemoved", function(receivedPlayer)
	table.remove(DataService.LoadedData, table.find(DataService.LoadedData, receivedPlayer.Data))
end)

Network:CreateListener("Read Data", function(player, dataValue)
	if not player or not dataValue then
		return
	end
	
	local playerData = PlayerStorage[player.UserId]
	if not playerData then
		warn("DataService: No data found for player", player.UserId)
		return
	end
	
	local keys = string.split(dataValue, ".")
	local currentData = table.clone(playerData.Data)
	
	for _, key in ipairs(keys) do
		if typeof(currentData) == "table" and currentData[key] ~= nil then
			currentData = currentData[key]
		else
			warn("DataService: Invalid data key -", dataValue)
			return
		end
	end
	
	Network:SendTo(player, "Receive Data", currentData)
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Connections

local function setCollisionGroup(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Players"
		end
	end
end

Observer.ObservePlayers(function(Player)
	print(Player.Name)
	
	--MessagingService:PublishAsync("DataAdded", Player.UserId)
	
	local playerData = DataService:LoadProfile(Player.UserId)
	
	playerData.LogInTimes += 1
	
	print(Player.Name, "has joined game", playerData.LogInTimes, "times")
	
	Network:SendTo(Player, "Receive Data", playerData)
	
	for _, tycoon in ipairs(TycoonService.playerTycoons) do
		if not tycoon.Player then
			tycoon:SetPlayer(Player)
			
			tycoon.Coins = playerData.Coins
			
			tycoon:LoadData(playerData)
			
			tycoon.Loaded = true
			
			for key, value in pairs(playerData.Tycoon) do
				if tycoon[key] ~= nil and playerData.Tycoon[key] ~= nil then
					tycoon[key] = value
				end
			end
			
			break
		end
	end
	
	Network:SendTo(Player, "InitializeTycoon", playerData)
	
	if Player:GetJoinData().ReferredByPlayerId and not playerData.GotReferralReward then
		playerData.GotReferralReward = true
		
		playerData.Tycoon.Cash += 100000
	end
	
	for settingName,settingItem in next, playerData.Settings do
		Network:SendTo(Player, "Change Setting", settingName, settingItem)
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	if PlayerStorage[Player.UserId] then
		local data = PlayerStorage[Player.UserId].Data
		
		data.LastOnline = os.time()
		
		for _, tycoon in ipairs(TycoonService.playerTycoons) do
			if tycoon.Player == Player and tycoon.Loaded then
				for key, _ in pairs(data.Tycoon) do
					if tycoon[key] ~= nil and data.Tycoon[key] ~= nil then
						print(key, _)
						
						data[key] = tycoon[key] or data.Tycoon[key]
					end
				end
				
				break
			end
		end
		
		PlayerStorage[Player.UserId]:Release()
		
		PlayerStorage[Player.UserId] = nil
	end
end)

Network:CreateListener("Set Settings", function(Player: Player, settingName: string, newValue)
	local playerData = DataService:LoadProfile(Player.UserId)
	
	if typeof(playerData.Settings[settingName]) == nil then
		return
	end
	
	if typeof(settingName) ~= "boolean" and typeof(settingName) ~= "number" then
		return
	end
	
	playerData.Settings[settingName] = newValue
end)

Network:CreateListener("DEBUG Reset Data Store", function(Player)
	if Staff[Player.UserId] and Staff[Player.UserId].Rank >= 3 then
		warn("RESET PLAYERS DATA")
		
		PlayerStorage[Player.UserId].Data = ProfileTemplate
		Network:SendTo(Player, "Growth Bought", PlayerStorage[Player.UserId].Data.Upgrades.Global)
		Network:SendTo(Player, "Update Daily", PlayerStorage[Player.UserId].Data.DailyReward)
		--local playerData = DataService:LoadProfile(Player.UserId)
		--warn(playerData)
		--warn('--')
		--playerData = {ProfileTemplate}
		--warn(playerData)
	else
		warn("You do not have permission to reset data store")
	end
end)

return DataService