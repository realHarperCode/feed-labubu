-- @ScriptType: ModuleScript
--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Services

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Network = require(ReplicatedStorage.Database.Security.Network)

local TycoonService = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Modules

local Tycoon = require(ServerScriptService.Server.Components.Entities.Classes.Tycoon)

local Observer = require(ReplicatedStorage.Packages.Observer)

local NumberFormat = require(ReplicatedStorage.Database.Custom.NumberFormat)

local PetData = require(ReplicatedStorage.Database.Custom.PetData)
local FoodData = require(ReplicatedStorage.Database.Custom.FoodData)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Variables

TycoonService.playerTycoons = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Functions

local function setCollisionGroup(model)
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			part.CollisionGroup = "Player"
		end
	end
end

local function Format(Int)
	return string.format("%02i", Int)
end

local function convertToHMS(Seconds)
	local Minutes = (Seconds - Seconds%60)/60
	Seconds = Seconds - Minutes*60
	local Hours = (Minutes - Minutes%60)/60
	Minutes = Minutes - Hours*60
	local Days = (Hours - Hours%24)/24
	Hours = Hours - Days*24
	return Format(Days) .. Format(Hours).." hours,"..Format(Minutes).." minutes, "..Format(Seconds) .. " seconds"
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Public Functions

function TycoonService:RegisterTycoon(tycoon)
	table.insert(TycoonService.playerTycoons, tycoon)
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Initialize

ModuleLoader:OnStart(function()
	
	for petNumber, petInfo in next, PetData do
		print(petNumber)
	end
	
	for _, tycoonModel in next, workspace.Tycoons:GetChildren() do
		local tycoonItem = Tycoon.new(tycoonModel, function(newTycoon)
			TycoonService:RegisterTycoon(newTycoon)
		end)
		table.insert(TycoonService.playerTycoons, tycoonItem)
	end
	
	Observer.ObservePlayers(function(Player)
		Player.CharacterAdded:Connect(function(char)
			setCollisionGroup(char)
		end)
		
		if Player.Character then
			setCollisionGroup(Player.Character)
		end
	end)
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Events

Network:CreateListener("Teleport", function(player)
	for _, tycoon in ipairs(TycoonService.playerTycoons) do
		if tycoon.Player == player then
			tycoon:TeleportPlayer()
			break
		end
	end
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Connections

return TycoonService