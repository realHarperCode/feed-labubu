-- @ScriptType: ModuleScript
local Module = {
	__tostring = function()
		return "Animation";
	end,
}

--> Services:
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local Players = game:GetService("Players");

--> Variables:
local ModuleLoader = require(ReplicatedStorage:WaitForChild("ModuleLoader"));

--// Framework Modules:
local Janitor = ModuleLoader.Import("Packages/Janitor");
local Promise = ModuleLoader.Import("Packages/Promise");

--// Types:
type AnimationModel = Model & {
	AnimationController: AnimationController & {
		Animator: Animator
	}
}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Local Functions:

local function Yield(Animation: AnimationTrack)
	while (Animation.Length == 0) do
		task.wait();
	end	
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Module Functions:

function Module:Query(Index: string)
	local AnimationTrack = self.Animations[Index];

	return Promise.new(function(Resolve, Reject)
		if AnimationTrack then
			Resolve(AnimationTrack);
			return
		end
	end)	
end

--//

function Module:AdjustAnimationSpeed(Animation: string, TargetSpeed: number)
	local NewPromise = self:Query(Animation);
	
	return NewPromise:andThen(function(Animation: AnimationTrack)
		Animation:AdjustSpeed(TargetSpeed / Animation.Length);
	end)
end

--//

function Module:Play(Animation: string)
	local NewPromise = self:Query(Animation)
	self.CurrentAnimation = Animation;
	
	return Promise.getPromiseValues(NewPromise:andThen(function(Animation: AnimationTrack)
		Yield(Animation);
		
		if not Animation.IsPlaying then 
			Animation:Play();
		end
		
		return Animation
	end))
end

--//

function Module:Stop(Animation: string)
	local NewPromise = self:Query(Animation)
	
	return NewPromise:andThen(function(Animation: AnimationTrack)
		if Animation.IsPlaying then
			Animation:Stop()
		end
	end)
end

function Module:StopAnimations()
	local Animations: { [string]: AnimationTrack } = self.Animations;
	
	for Animation, AnimationTrack in pairs(Animations) do
		if AnimationTrack.IsPlaying then
			AnimationTrack:Stop();
		end
	end
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Constructor:

function Module.new(Model: AnimationModel, Animations: Folder & { Animation })
	
	local self = setmetatable({}, {
		__index = Module,
	})
	
	--// Janitor:

	self.Janitor = Janitor.new();

	--// Indicies:
	
	self.Animations = {};
	
	--// Events:

	local Animator = (if Model:FindFirstChild("Humanoid") then Model.Humanoid.Animator else Model.AnimationController.Animator);
	
	for _, Animation in ipairs(Animations:GetChildren()) do
		local AnimationTrack = Animator:LoadAnimation(Animation);
		
		self.Animations[Animation.Name] = AnimationTrack;
		
		self.Janitor:Add(function()
			AnimationTrack:Destroy()
		end);
	end
	
	--// Cleanup:

	self.Janitor:Add(function()
		table.clear(self.Animations)	
	end)
	
	--// Return:
	
	return self;
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Deconstructor:

function Module:Destroy()
	for _, AnimationTrack in pairs(self.Animations) do
		AnimationTrack:Stop();
	end
	
	self.Janitor:Destroy();
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Return:

return Module;