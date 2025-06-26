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

local TycoonHeaders = require("@self/TycoonHeaders")
local Fruit = require("./Fruit")

local PlayerVisualUtils = require(ReplicatedStorage.Packages.PlayerVisualUtils)

--// Private Variables
local DEFAULT_PATH_CONFIG = {
	AgentRadius = 0.5,
	AgentHeight = 3,
	AgentCanJump = true,
	WaypointSpacing = 1,
	Costs = {
		Water = 20
	}
}

local MAX_ORE_COUNT = 30

local PetData = require(ReplicatedStorage.Database.Custom.PetData)
local FoodData = require(ReplicatedStorage.Database.Custom.FoodData)
local FarmData = require(ReplicatedStorage.Database.Custom.FarmData)

local farmSpotTable = {
	Flags = {},
	
	PlantWeight = 0
}

--// Types

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Initialize Module

local Tycoon = setmetatable({}, { __index = TycoonHeaders })
Tycoon.__index = Tycoon

type tycoonType = typeof(Tycoon) & typeof(TycoonHeaders)

--// Constructor
function Tycoon.new(tycoonFolder: Model, onDestroyCallback): tycoonType
	local self: tycoonType = setmetatable({}, { __index = Tycoon })
	
	self.tycoonFolder = tycoonFolder
	
	self._onDestroyCallback = onDestroyCallback
	
	self._Janitor = Maid.new()
	
	--// Per Server Data, do not name same as actual player data stuff
	self.tycoonFarms = {}
	
	self:PreloadTycoon()
	
	return self
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Private Methods

function Tycoon:_getFarmSpots(farmModel: Model)
	local farmSpots = {}
	
	for _, farmObject in next, farmModel:GetChildren() do
		if farmObject.Name == "FruitPart" and farmObject:GetAttribute("Slot") then
			table.insert(farmSpots, farmObject:GetAttribute("Slot"))
		end
	end
	
	return farmSpots
end

function Tycoon:_getFarmSlot(farmModel: Model, slotNumber: number)
	print(farmModel, slotNumber)
	
	for _, farmObject in next, farmModel:GetChildren() do
		if farmObject.Name == "FruitPart" and farmObject:GetAttribute("Slot") == slotNumber then
			return farmObject
		end
	end
end

function Tycoon:_makeFarmData(data)
	for farmName, farmData in next, FarmData do
		local farmItemData = data.Farms[farmName]
		if not farmItemData then
			data.Farms[farmName] = {}
			farmItemData = data.Farms[farmName]
		end
		
		farmItemData.Purchased = farmItemData.Purchased or (farmName == "Click Machine" and true or false)
		farmItemData.Flags = farmItemData.Flags or {}
		farmItemData.FarmPlots = farmItemData.FarmPlots or {}
		farmItemData.FarmStats = farmItemData.FarmStats or {}
		farmItemData.FarmStats.Multiplier = farmItemData.FarmStats.Multiplier or 1
		
		for _, farmSpotItem in next, self:_getFarmSpots(self.tycoonFolder.Farms[farmName]) do
			local farmSpotData = data.Farms[farmName].FarmPlots[farmSpotItem]
			if not farmSpotData then
				data.Farms[farmName].FarmPlots[farmSpotItem] = {}
				farmSpotData = data.Farms[farmName].FarmPlots[farmSpotItem]
			end
			
			farmSpotData.Flags = farmSpotData.Flags or {}
			farmSpotData.FarmWeight = farmSpotData.FarmWeight or 0
		end
	end
end

function Tycoon:_updateFarms()
	for farmName, farmData in next, self.Tycoon.Farms do
		self:_hideModel(self.tycoonFolder.Farms:FindFirstChild(farmName))
		self:_hideSign(self.tycoonFolder.Farms:FindFirstChild(farmName))
		
		if farmName == "Expansion" then
			if farmData.Purchased then
				Tycoon:_showExpansion()
				continue
			end
			
			if self.TotalEarnedCoins < FarmData[farmName].RequiredToShowCoins then
				warn("Not enough coins earned for this farm")
				self:_createPurchaseSign(self.tycoonFolder.Farms.Expansion)
				continue
			end
			
			continue
		end
		
		if not FarmData[farmName] then
			warn("No farm")
			continue
		end
		
		if self.TotalEarnedCoins < FarmData[farmName].RequiredToShowCoins then
			warn("Not enough coins earned for this farm")
			self:_hideSign(self.tycoonFolder.Farms:FindFirstChild(farmName))
			continue
		end
		
		self:_createPurchaseSign(self.tycoonFolder.Farms:FindFirstChild(farmName))
		
		if not farmData.Purchased then
			warn("Not purchased")
			continue
		end
		
		self:_createNormalSign(self.tycoonFolder.Farms:FindFirstChild(farmName))
		self:_showModel(self.tycoonFolder.Farms:FindFirstChild(farmName))
	end
end

function Tycoon:_spawnFruits()
	for farmName, farmData in next, self.Tycoon.Farms do
		if not farmData.FarmPlots then
			continue
		end
		
		print(farmName, farmData)
		
		if not farmData.Purchased then
			continue
		end
		
		for farmSpotNumber, farmSpot in next, farmData.FarmPlots do
			local fruitObject = Fruit.new(self.tycoonFolder, self:_getFarmSlot(self.tycoonFolder.Farms[farmName], farmSpotNumber).Position)
			table.insert(self.tycoonFarms, fruitObject)
			
			print(farmSpot)
			
			fruitObject:PreloadFruit(farmSpot)
			
			self._Janitor:GiveTask(function()
				farmSpot = fruitObject.data
				
				fruitObject:Destroy()
			end)
		end
	end
end

function Tycoon:_startFarm(farmModel: Model)
	
end

function Tycoon:_setModelState(model: Model, visible: boolean)
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			if visible then
				descendant.Transparency = descendant:GetAttribute("VisibilityStuff") or 0
				descendant.CanCollide = descendant:GetAttribute("CollisionStuff") ~= false
			else
				if not descendant:GetAttribute("VisibilityStuff") and not descendant:GetAttribute("CollisionStuff") then
					descendant:SetAttribute("VisibilityStuff", descendant.Transparency)
					descendant:SetAttribute("CollisionStuff", descendant.CanCollide)
				end
				
				descendant.Transparency = 1
				descendant.CanCollide = false
			end
		elseif descendant:IsA("Beam") then
			if visible then
				descendant.Enabled = true
			else
				descendant.Enabled = false
			end
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("BillboardGui") or descendant:IsA("SurfaceGui") then
			descendant.Enabled = visible
		end
	end
end

function Tycoon:_hideModel(farmModel: Model)
	self:_setModelState(farmModel.Model, false)
	
	return farmModel
end

function Tycoon:_showModel(farmModel: Model)
	self:_setModelState(farmModel.Model, true)
	
	local model = farmModel.Model
	
	if not model.PrimaryPart then
		model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart")
	end
	
	if model.PrimaryPart then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local originalSize = part.Size
				local originalTransparency = part:GetAttribute("VisibilityStuff") or 0
				
				part.Size = originalSize
				part.Transparency = originalTransparency
			end
		end
	end
	
	return farmModel
end

function Tycoon:_hideSign(farmModel: Model)
	for _,signPart in next, farmModel.Sign:GetChildren() do
		if signPart:IsA("BasePart") then
			signPart.Transparency = 1
		end
		
		if signPart:FindFirstChild("SurfaceGui") then
			signPart.SurfaceGui.Enabled = false
		end
	end
end

function Tycoon:_showSign(farmModel: Model)
	for _,signPart in next, farmModel.Sign:GetChildren() do
		if signPart:IsA("BasePart") then
			signPart.Transparency = 0
		end
		
		if signPart:FindFirstChild("SurfaceGui") then
			signPart.SurfaceGui.Enabled = true
		end
	end
end

function Tycoon:_hideExpansion()
	self:_setModelState(self.tycoonFolder, false)
end

function Tycoon:_showExpansion()
	self:_setModelState(self.tycoonFolder, true)
end

function Tycoon:_createNormalSign(farmModel: Model)
	self:_showSign(farmModel)
end

function Tycoon:_createPurchaseSign(farmModel: Model)
	self:_showSign(farmModel)
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##
--> Public Methods

function Tycoon:GrowFarmTime(growTime: number)
	assert(typeof(growTime) == "number", "This needs to be a number")
	
	for _, plantItem in next, self.Plants do
		plantItem:GrowPlant(growTime)
	end
end

function Tycoon:FeedPet(growthAmount: number)
	assert(typeof(growthAmount) == "number", "Food amount isn't number")
	
	self.Pet:FeedPet(growthAmount)
end

function Tycoon:PreloadTycoon()
	for _, tycoonButton in next, self.tycoonFolder.Farms:GetChildren() do
		self:_hideModel(tycoonButton)
		
		self:_hideSign(tycoonButton)
	end
	
end

function Tycoon:LoadData(playerData)
	for tycoonDataName,tycoonDataItem in next, playerData do
		self[tycoonDataName] = tycoonDataItem
	end
	
	print(playerData)
	
	self:_makeFarmData(playerData.Tycoon)
	
	--// TODO: Change this code entirely
	self:_updateFarms()
	
	--// TODO: Make it so we don't gotta do this
	self:_showModel(self.tycoonFolder.Farms["Click Machine"])
	self:_createNormalSign(self.tycoonFolder.Farms["Click Machine"])
	
	self:_spawnFruits()
	
	PlayerVisualUtils:MakePlayerVisual(self.Player, self.tycoonFolder.Map.NameBillboard.BillboardGui)
	
	self._Janitor:GiveTask(function()
		self.tycoonFolder.Map.NameBillboard.BillboardGui.Enabled = false
	end)
end

function Tycoon:SetPlayer(Player: Player)
	assert(not self.Player, "Tycoon already has a player")
	
	self.Player = Player

	self:TeleportPlayer(self.Player)
	
	self._Janitor:GiveTask(Players.PlayerRemoving:Connect(function(playerRemoving: Player)
		if playerRemoving ~= self.Player then
			return
		end
		
		local tycoonFolder = self.tycoonFolder
		local onDestroyCallback = self._onDestroyCallback
		
		self:PreloadTycoon()
		self:Destroy()
		
		local newTycoon = Tycoon.new(tycoonFolder, onDestroyCallback)
		
		if onDestroyCallback then
			onDestroyCallback(newTycoon)
		end
	end))
	
	if MarketplaceService:UserOwnsGamePassAsync(self.Player.UserId, 1234567890) then
		self.Has2xOre = true
	end
end

function Tycoon:TeleportPlayer()
	if not self.Player or not self.tycoonFolder then return end

	local character = self.Player.Character or self.Player.CharacterAdded:Wait()
	local spawnLocation = self.tycoonFolder:FindFirstChild("Map") and self.tycoonFolder.Map:FindFirstChild("Spawn")

	if character and spawnLocation then
		character:PivotTo(spawnLocation:GetPivot() * CFrame.new(0, 2, 0))
	end
end

--// Deconstructor
function Tycoon:Destroy()
	if not self._Janitor then
		return
	end
	
	self._Janitor:Destroy()
	self = nil
end

--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##--##

return Tycoon