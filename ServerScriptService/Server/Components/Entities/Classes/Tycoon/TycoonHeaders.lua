-- @ScriptType: ModuleScript
--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Dependencies

--// Services
local PathfindingService = game:GetService("PathfindingService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Network = require(ReplicatedStorage.Database.Security.Network)

--// Modules
local NumberFormat = require(ReplicatedStorage.Database.Custom.NumberFormat)
local NumberSpinner = require(ReplicatedStorage.Packages.NumberSpinner)

local Maid = require(ReplicatedStorage.Packages.Maid)

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Module Variables

--// Private Variables
local MAX_ORE_COUNT = 30

--// Types


--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Initialize Module

local TycoonHeaders: TycoonHeaders = {}
TycoonHeaders.__index = TycoonHeaders

--// Internals
TycoonHeaders._Janitor = Maid.new()
TycoonHeaders._Model = Instance.new("Model")
TycoonHeaders._onDestroyCallback = nil

--// Runtime State
TycoonHeaders.Player = nil
TycoonHeaders.tycoonModel = nil

--// Player Stats
TycoonHeaders.Coins = 0

TycoonHeaders.Farms = {}

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Public Methods

function TycoonHeaders:GetPlayer()
	return self.Player
end

function TycoonHeaders:GetCoins()
	return self.Coins
end

function TycoonHeaders:HasUnlocked(buttonName: string): boolean
	return table.find(self.UnlockedButtons, buttonName) ~= nil
end

function TycoonHeaders:CanAffordButton(price: number?, rebirthPrice: number?, gamepass: boolean?): boolean
	if gamepass then return false end
	if not price and not rebirthPrice then return true end
	return (price and self.Coins >= price) or (rebirthPrice and self.Rebirths >= rebirthPrice)
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##

return TycoonHeaders