-- @ScriptType: ModuleScript
--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Services
local ServerScriptService = game:GetService("ServerScriptService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ModuleLoader = require(ReplicatedStorage.ModuleLoader)
local Network = require(ReplicatedStorage.Database.Security.Network)

local StoreService = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Modules

local TycoonService = ModuleLoader.Import("Server/Services/TycoonService")
local DataService = require(ServerScriptService.Server.Components.Services.DataService)
local Observer = require(ReplicatedStorage.Packages.Observer)

local Store = require(ServerScriptService.Server.Components.Data.Store)
local Codes = ModuleLoader.Import("Server/Data/Codes")

local Playtime = require(ServerScriptService.Server.Components.Data.Playtime)
local Daily = require(ServerScriptService.Server.Components.Data.Daily)


local MessagingServiceUtils = require(ReplicatedStorage.Nevermore.MessagingServiceUtils)
local MarketplaceUtils = require(ReplicatedStorage.Nevermore.MarketplaceUtils)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Variables

local playerPlaytime = {}

local CurrentPurchase: {[number]: string} = {}

local ProductPrices = {}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Private Functions

local function getDayStamp(timeStamp)
	local date = os.date("*t", timeStamp)
	return os.time({year = date.year, month = date.month, day = date.day, hour = 0})
end

local function daysBetween(startTime, endTime)
	local startDay = getDayStamp(startTime)
	local endDay = getDayStamp(endTime)
	return math.floor((endDay - startDay) / 86400)
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Public Functions

function StoreService:RequestPurchase(Player: Player, purchaseName: string, purchaseScope: string, giftRecipient: number?)
	if purchaseScope then
		CurrentPurchase[Player.UserId] = purchaseScope
	end
	
	local purchaseItem = Store[purchaseName]
	if not purchaseName or not purchaseItem then
		CurrentPurchase[Player.UserId] = nil
		Player:Kick("Not actual purchase")
		return
	end
	
	if purchaseItem.Type == 1 then
		MarketplaceService:PromptGamePassPurchase(Player, purchaseItem.ProductId)
	elseif purchaseItem.Type == 2 then
		MarketplaceService:PromptProductPurchase(Player, purchaseItem.ProductId)
	end
	--CurrentPurchase[Player.UserId] = nil
end

function StoreService:GiveRewards(Player: Player, rewardType: string, reward: string | number)
	if rewardType == "Playtime" then
		for purchaseName, purchaseData in next, Playtime do
			if playerPlaytime[Player] + purchaseData.Time <= os.clock() then
				for _, frame in ipairs(Player.PlayerGui.Frames.Playtime.Container.Content:GetChildren()) do
					if frame:IsA("Frame") and frame:GetAttribute("Timer") == purchaseData.Time then
						if frame:GetAttribute("Claimed") then
							break
						end
						
						frame:SetAttribute("Claimed", true)
						
						DataService:promiseLoad(Player.UserId):andThen(function(dataResults)
							if purchaseData.Type == 1 then
								dataResults.Tycoon.Multiplier *= purchaseData.Reward
							end
						end)
						
						break
					end
				end
			end
		end
	elseif rewardType == "Daily" then
		DataService:promiseLoad(Player.UserId) -- TODO MOVE THIS TO PLAYER SPAWNED IN
			:andThen(function(res)
				
				reward = tonumber(reward)
				
				if res.DailyReward.Claimed[reward] then
					warn("Already claimed this reward")
					return
				end
				
				if res.DailyReward.Streak < reward then
					warn("Insufficient day streak for reward")
					return
				end
				
				res.DailyReward.Claimed[reward] = true
				
				if Daily[reward] then -- TODO add code for legacy tables when cycle switches per month!!! or store in special data service sector
					if Daily[reward].Multiplier then
						if res.Tycoon and res.Tycoon.Multiplier then
							res.Tycoon.Multiplier *= Daily[reward].Multiplier -- TODO Add section to make permanent?
						end
					end
					--TODO add more reward types than mult as they come
					Network:SendTo(Player, "Update Daily", res.DailyReward)
				else
					warn("This reward does not exist")
				end

			end)
			:catch(function(err)
				warn("Could not retrieve player data: ", err)
			end)
	end
end

function StoreService:RedeemCode(Player: Player, codeName: string)
	if not codeName then
		Player:Kick("Not actual code")
		return
	end
	
	local codeStuuuf = Codes[codeName]
	
	if not Codes[codeName] then
		return false
	end
	
	DataService:promiseLoad(Player.UserId):andThen(function(dataResults)
		if dataResults.Codes[codeName] then
			return
		end
		
		table.insert(dataResults.Codes, codeName)
		
		if codeStuuuf.Type == 1 then
			dataResults.Coins += codeStuuuf.Reward
		end
	end)
	
	return true
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Initialize

ModuleLoader:OnStart(function()
	for _, purchaseItem in next, Store do
		MarketplaceUtils.promiseProductInfo(purchaseItem.ProductId, purchaseItem.Type == 1 and Enum.InfoType.GamePass or Enum.InfoType.Product)
			:andThen(function(result)
				ProductPrices[purchaseItem.ProductId] = result.PriceInRobux
			end)
			:catch(function(err)
				warn("Could not retrieve product info: ")
				warn(err)
			end)
	end
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Events

Network:CreateListener("Redeem Code", function(...)
	StoreService:RedeemCode(...)
end)

Network:CreateListener("Request Purchase", function(...)
	StoreService:RequestPurchase(...)
end)

Network:CreateListener("Claim Playtime Rewards", function(...)
	StoreService:GiveRewards(...)
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Connections

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(Player: Player, purchaseId: number, hasPurchased: boolean)
	if not hasPurchased then
		return
	end
	
	for purchaseName, purchaseData in next, Store do
		if purchaseData.ProductId == purchaseId then
			DataService:promiseLoad(Player):andThen(function(dataResults)
				if purchaseData.Type == 1 then
					dataResults.Tycoon.Multiplier *= purchaseData.Multiplier
				end
			end)
			break
		end
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(playerId: Player, purchaseId: number, hasPurchased: boolean)
	local Player = Players:GetPlayerByUserId(playerId)
	
	local playerPurchase = CurrentPurchase[playerId]
	if not playerPurchase then
		warn("No player purchase goal")
		return
	end
	
	if not hasPurchased then
		warn("Purchase was cancelled")
		CurrentPurchase[playerId] = nil
		return
	end
	
	for purchaseName, purchaseData in next, Store do
		if purchaseData.ProductId == purchaseId then
			DataService:promiseLoad(playerId):andThen(function(dataResults)
				if purchaseData.Type == 2 then
					if purchaseData.Multiplier then
						if dataResults.Upgrades[playerPurchase].Purchases[purchaseData.ProductId] then
							warn("already bought this")
							return
						end
						warn(purchaseData.Requires)
						warn(dataResults.Upgrades[playerPurchase].Purchases)
						warn(dataResults.Upgrades[playerPurchase].Purchases[purchaseData.Requires])
						warn(typeof(purchaseData.Requires))
						if purchaseData.Requires
							and not dataResults.Upgrades[playerPurchase].Purchases[purchaseData.Requires] then
							warn("prior requirements not met")
							return
						end
						dataResults.Upgrades[playerPurchase].Purchases[purchaseData.ProductId] = true
						for _, growth in next, Store do
							if growth.Requires == purchaseData.ProductId then
								dataResults.Upgrades[playerPurchase].NextGrowthUpgrade = growth
							end
						end
						
						dataResults.Upgrades[playerPurchase].Multiplier *= purchaseData.Multiplier
						
						Network:SendTo(Player, "Growth Bought", dataResults.Upgrades[playerPurchase])
					elseif purchaseData.TimeSkip then
						-- todo add send to
					end
					
					Network:Replicate("SystemChatMessage", `[SERVER] {Player.DisplayName} has purchased {purchaseName} for {utf8.char(0xE002)}{ProductPrices[purchaseData.ProductId]}`)
					
					--if ProductPrices[purchaseData.ProductId] >= 800 then
					--	MessagingServiceUtils:promisePublish("Product Purchase", {`[GLOBAL] {Player.DisplayName} has purchased {purchaseName} for {utf8.char(0xE002)}{ProductPrices[purchaseData.ProductId]}`}):andThen(function()
							
					--	end):catch(function()
							
					--	end)
					--end
					
				end
			end)
			
			break
		end
	end
	
	CurrentPurchase[Player] = nil
end)


Observer.ObservePlayers(function(Player)
	DataService:promiseLoad(Player.UserId) -- TODO MOVE THIS TO PLAYER SPAWNED IN
		:andThen(function(res)
			warn("promise runs")
			local currentTime = os.time()
			local lastOnline = res.LastOnline

			if daysBetween(lastOnline, currentTime) >= 1 then
				res.LastOnline = currentTime
				res.DailyReward.Streak += 1
				-- reward ready set to day streak
			end

			Network:SendTo(Player, "Update Daily", res.DailyReward)
		end)
		:catch(function(err)
			warn("Could not retrieve player data: ", err)
		end)
end)


Players.PlayerAdded:Connect(function(Player: Player) -- TODO ADD THE 28 DAY LIMIT??
	playerPlaytime[Player] = os.clock()
end)

--MessagingServiceUtils.promiseSubscribe("Product Purchase", function(productMessage)
--	Network:Replicate("SystemChatMessage", productMessage.Data[1])
--end)
--	:andThen(function(connection)
--		print("Successfully subscribed to 'Product Purchase' topic.")
--	end)
--	:catch(function(err)
--		warn("Failed to subscribe to 'Product Purchase':", err)
--	end)

return StoreService