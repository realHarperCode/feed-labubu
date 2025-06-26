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

local Maid = require(ReplicatedStorage.Packages.Maid)

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Module Variables

--// Private Variables
local PetData = require(ReplicatedStorage.Database.Custom.PetData)
local FoodData = require(ReplicatedStorage.Database.Custom.FoodData)

local FruitUtils = require(ReplicatedStorage.Packages.FruitUtils)

--// Types

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Initialize Module

local Fruit = {}
Fruit.__index = Fruit

--// Constructor
function Fruit.new(tycoonFolder: Model, farmPosition: Vector3, onDestroyCallback)
	local self: tycoonType = setmetatable({}, { __index = Fruit })
	
	self.tycoonFolder = tycoonFolder
	
	self.farmPosition = farmPosition
	
	self.Janitor = Maid.new()
	
	return self
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Private Methods

function Fruit:_updateFruitSize()
	local petInfo = FruitUtils:FindFruitInfo(self.data.PlantWeight)
	if not petInfo then
		warn("No pet info found for weight:", self.data.PlantWeight)
		return
	end
	
	local minWeight = petInfo.SizeLimit.Min
	local maxWeight = petInfo.SizeLimit.Max
	
	local normalized = (self.data.PlantWeight - minWeight) / (maxWeight - minWeight)
	
	local minScale, maxScale = 0.7, 3
	local scaledSize = minScale + (normalized * (maxScale - minScale))
	
	self.FruitModel:ScaleTo(math.clamp(scaledSize, minScale, maxScale))
end

function Fruit:_updateFruitModel()
	if self.FruitModel then
		self.FruitModel:Destroy()
		
		warn("Destroyed old fruit model")
	end
	
	self.FruitModel = ReplicatedStorage.Components.Objects:FindFirstChild(FruitUtils:FindFruitInfo(self.data.PlantWeight).Name, true):Clone()
	self.FruitModel.Parent = workspace
	self.FruitModel:PivotTo(CFrame.new(self.farmPosition))
	
	self:_updateFruitSize()
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Public Methods

function Fruit:GrowPlant(fruitWeight: number)
	self.data.PlantWeight += fruitWeight
	
	self:_updateFruitModel()
end

function Fruit:PreloadFruit(data)
	self.data = data
	
	self:_updateFruitModel()
end

--// Deconstructor
function Fruit:Destroy()
	if not self._Janitor then
		return
	end
	
	self._Janitor:Destroy()
	self = nil
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##

return Fruit