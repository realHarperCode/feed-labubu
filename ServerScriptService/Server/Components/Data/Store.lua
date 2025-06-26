-- @ScriptType: ModuleScript
return {
	--// Gamepasses

	
	
	--// Products
	
	["2x Growth"] = {
		Type = 2,
		Multiplier = 2,
		ProductId = 3313449947
	},
	["5x Growth"] = {
		Type = 2,
		Multiplier = 5,
		ProductId = 3313450117,
		Requires = 3313449947
	},
	["10x Growth"] = {
		Type = 2,
		Multiplier = 10,
		ProductId = 3313450433,
		Requires = 3313450117
	},
	["20x Growth"] = {
		Type = 2,
		Multiplier = 20,
		ProductId = 3313450567,
		Requires = 3313450433
	},
	["50x Growth"] = {
		Type = 2,
		Multiplier = 50,
		ProductId = 3314612966,
		Requires = 3313450567
	},
	["100x Growth"] = {
		Type = 2,
		Multiplier = 100,
		ProductId = 3314614252,
		Requires = 3314612966
	},
	["200x Growth"] = {
		Type = 2,
		Multiplier = 200,
		ProductId = 3314620913,
		Requires = 3314614252
	},
	["500x Growth"] = {
		Type = 2,
		Multiplier = 500,
		ProductId = 3315872996,
		Requires = 3314620913
	},
	["1000x Growth"] = {
		Type = 2,
		Multiplier = 1000,
		ProductId = 3315873116,
		Requires = 3315872996
	},
	
	-- Time skips
	["+30m"] = {
		TimeSkip = 1800,
		ProductId = 3314696806,
		Type = 2
	},
	["+3h"] = {
		TimeSkip = 10800,
		ProductId = 3315261136,
		Type = 2
	},
	["+24h"] = {
		TimeSkip = 86400,
		ProductId = 3315261359,
		Type = 2
	},
	["+72h"] = {
		TimeSkip = 259200,
		ProductId = 3315261476,
		Type = 2
	},
	["+240h"] = {
		TimeSkip = 864000,
		ProductId = 3315261613,
		Type = 2
	},
}