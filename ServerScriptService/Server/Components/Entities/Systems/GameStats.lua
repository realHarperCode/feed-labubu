-- @ScriptType: ModuleScript
local Module = {
	__tostring = function()
		return "GameStats";
	end,
}

--> Services:
local RunService = game:GetService("RunService");

--> Variables:
local TimePassed = 0

--// Tables:
local DeltaTimeEntries = {
	
}

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Events:

RunService.Heartbeat:Connect(function(DeltaTime)
	table.insert(DeltaTimeEntries, DeltaTime)
	TimePassed += DeltaTime


	if TimePassed >= 1 then
		local ServerFPS = math.ceil(1 / (TimePassed / #DeltaTimeEntries))
		workspace:SetAttribute("ServerFPS", ServerFPS)

		table.clear(DeltaTimeEntries)
		TimePassed -= 1
	end
end)

--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==--==
--> Return:

return Module;