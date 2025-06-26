-- @ScriptType: ModuleScript
--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Dependencies

--// Services
local PathfindingService = game:GetService("PathfindingService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local TweenService = game:GetService("TweenService")
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
local PetData = require(ReplicatedStorage.Database.Custom.PetData)
local FoodData = require(ReplicatedStorage.Database.Custom.FoodData)

local PetUtils = require(ReplicatedStorage.Packages.PetUtils)

--// Types

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Initialize Module

local Pet = {}
Pet.__index = Pet

--// Constructor
function Pet.new(tycoonFolder: Model, onDestroyCallback)
	local self: tycoonType = setmetatable({}, { __index = Pet })
	
	self.tycoonFolder = tycoonFolder
	
	self.Janitor = Maid.new()
	
	self:PreloadTycoon()
	
	return self
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Private Methods

function Pet:_updatePetSize()
	local petInfo = PetUtils:FindPetInfo(self.Weight)
	if not petInfo then
		warn("No pet info found for weight:", self.Weight)
		return
	end
	
	local minWeight = petInfo.SizeLimit.Min
	local maxWeight = petInfo.SizeLimit.Max
	
	local normalized = (self.Weight - minWeight) / (maxWeight - minWeight)
	
	local minScale, maxScale = 0.7, 3
	local scaledSize = minScale + (normalized * (maxScale - minScale))
	
	self.PetModel:ScaleTo(math.clamp(scaledSize, minScale, maxScale))
end

function Pet:_updatePetModel()
	self.PetModel = ReplicatedStorage.Components.Objects:FindFirstChild(PetUtils:FindPetInfo(self.data.PetWeight), true):Clone()
	self.PetModel.Parent = workspace
	self.PetModel:PivotTo(self.tycoonFolder.PetSpawn)
	
	self:updatePetSize()
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Public Methods

function Pet:PreloadPet(data)
	self.data = data
	self.PetModel = PetData[data.PetNumber]
end

--// Deconstructor
function Pet:Destroy()
	if not self._Janitor then
		return
	end
	
	self._Janitor:Destroy()
	self = nil
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##

return Pet