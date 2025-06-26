-- @ScriptType: ModuleScript
local Module = {
	__tostring = function()
		return "SoundController"
	end,
}

--> Services:
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

--> Variables:
local ModuleLoader = require(ReplicatedStorage:WaitForChild("ModuleLoader"))

--// Framework Modules:
local GetInstance = ModuleLoader.Import("Packages/GetInstance")
local Janitor = ModuleLoader.Import("Packages/Janitor")

--// Script Modules:
local GameSounds = Instance.new("Folder", ReplicatedStorage)
GameSounds.Name = "Sounds"

--// Script Assets:
local Types = require(script:WaitForChild("Types"))

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Local Functions:

local function CreateSoundInstance(Identifier: string, Id: number, Properties: Types.SoundProperties): Sound
	local Sound = Instance.new("Sound")
	Sound.SoundId = `rbxassetid://{Id}`
	Sound.Name = Identifier
	
	Sound.RollOffMaxDistance = (Properties.RollOffMaxDistance or 10000)
	Sound.RollOffMinDistance = (Properties.RollOffMinDistance or 10)
	Sound.TimePosition = (Properties.TimePosition or 0)
	Sound.Looped = (Properties.Looped or false)
	Sound.Volume = (Properties.Volume or 0.5)
	
	return Sound
end

local function SelectSound(SoundFolder: Folder & { Sound }): Sound
	local Container = SoundFolder:GetChildren()
	local Name = math.random(1, #Container)
	return SoundFolder[Name]:Clone()
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Class Functions:

function Module:Play(Server: Types.PlaySound)
	assert(Server.Parent or Server.Path, `ServerSoundController couldn't locate sound parent for {Server.Sound}`)
	
	local SoundFolder = self.Sounds:FindFirstChild(Server.Sound)
	assert(SoundFolder, `{Server.Sound} is not a part of sound group {self.SoundGroup}`)
	
	local ServerId = HttpService:GenerateGUID(false)
	local Parent = (if (Server.Path) then GetInstance(game, Server.Path) else Server.Parent)
	
	if Parent then
		local NewSound: Sound = SelectSound(SoundFolder)
		NewSound.Parent = Parent
		NewSound.Looped = Server.Looped or false
		NewSound.Name = ServerId
		
		--//
		self.Janitor:Add(NewSound)
		NewSound:Play()
		
		if not NewSound.Looped then
			self.Janitor:Add(NewSound.Ended:Once(function()
				NewSound:Destroy()
			end))
		end
		
		return NewSound
	end
end

function Module:Stop(SoundIdentifier: string, Parent: Instance)
	for _, sound in ipairs(Parent:GetChildren()) do
		if sound:IsA("Sound") and sound.Name == SoundIdentifier then
			sound:Stop()
			sound:Destroy()
			break
		end
	end
end

function Module:Iterate(Callback: (Name: string) -> nil)
	local Container = self.Sounds:GetChildren()
	for _, SoundFolder: Folder in ipairs(Container) do
		Callback(SoundFolder.Name)
	end
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Module Functions:

function Module:CreateSoundGroup(SoundGroup: string, SoundTracks: Types.SoundTracks)
	local GroupFolder = Instance.new("Folder", GameSounds)
	GroupFolder.Name = SoundGroup 
	
	for Index, Class in pairs(SoundTracks) do
		local SoundFolder = Instance.new("Folder", GroupFolder)
		SoundFolder.Name = Index
		
		for Number, Id in ipairs(Class.Ids) do
			local Sound: Sound = CreateSoundInstance(Number, Id, Class.Properties)
			Sound.Parent = SoundFolder
		end
	end
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Setup:

ModuleLoader:OnStart(function(Resolve, Reject)
	local Container = GetInstance(ReplicatedStorage, "game?soundService/Database/Audio", true)
	
	for _, ModuleScript: ModuleScript in ipairs(Container:GetChildren()) do
		local SoundTracks = ModuleLoader.ImportFrom("Database/Audio", ModuleScript.Name)
		SoundTracks = SoundTracks:Get()
		
		if SoundTracks then
			Module:CreateSoundGroup(ModuleScript.Name, SoundTracks)
		end
	end
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Constructor:

function Module.new(SoundGroup: string)
	local Sounds = GameSounds:FindFirstChild(SoundGroup)
	assert(Sounds, `{SoundGroup} is not a valid sound group in game.sounds`)
	
	--// Metatable:
	local self = setmetatable({}, {
		__index = Module,
	})
	
	--// Utility
	self.Janitor = Janitor.new()
	
	--// Indices:
	self.SoundGroup = SoundGroup
	self.Sounds = Sounds
	
	return self
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Deconstructor:

function Module:Destroy()
	self.Janitor:Destroy()
	setmetatable(self, nil)
	table.clear(self)
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Return:

return Module