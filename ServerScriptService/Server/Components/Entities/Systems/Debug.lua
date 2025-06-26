-- @ScriptType: ModuleScript
local Module = {
	__tostring = function()
		return "Debug";
	end,
}

--> Services:
local ReplicatedStorage = game:GetService("ReplicatedStorage");
local HttpService = game:GetService("HttpService");
local RunService = game:GetService("RunService");
local LogService = game:GetService("LogService");
local Players = game:GetService("Players");

--> Variables:
local ModuleLoader = require(ReplicatedStorage:WaitForChild("ModuleLoader"));

--// Framework Modules:
local Network = ModuleLoader.Import("Database/Security/Network");

--// Tables:
local ServerErrors = {
	
}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Local Functions:


--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Module Functions:

function Module:Reconcile(Player: Player)
	for Identity, Message in pairs(ServerErrors) do
		Network:SendTo(Player, "Debug", Message, "Print");
	end
end

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Events:

LogService.MessageOut:Connect(function(Message: string, MesasgeType: Enum.MessageType)
	if (RunService:IsStudio() == false) then
		local Identity = HttpService:GenerateGUID(false);
		ServerErrors[Identity] = Message;
		
		for _, Player in ipairs(Players:GetPlayers()) do
			if (MesasgeType == Enum.MessageType.MessageError) then
				Network:SendTo(Player, "Debug", Message, "Warn");
				
			elseif (MesasgeType == Enum.MessageType.MessageWarning) then
				Network:SendTo(Player, "Debug", Message, "Warn");	
				
			elseif (MesasgeType == Enum.MessageType.MessageInfo) or (MesasgeType == Enum.MessageType.MessageOutput) then
				Network:SendTo(Player, "Debug", Message, "Print");
				
			end
		end
	end
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Setup:

ModuleLoader:OnStart(function()
	for _, Player in ipairs(Players:GetPlayers()) do
		Module:Reconcile(Player);
	end	
	
	Players.PlayerAdded:Connect(function(Player: Player)
		Module:Reconcile(Player);
	end)
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Return:

return Module;