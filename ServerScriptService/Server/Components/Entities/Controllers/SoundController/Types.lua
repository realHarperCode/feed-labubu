-- @ScriptType: ModuleScript
local Types = { };

export type SoundProperties = {
	RollOffMaxDistance: number?,
	RollOffMinDistance: number?,
	TimePosition: number?,
	Looped: boolean?,
	Volume: number?,
	Range: number?,
}

export type SoundTracks = {
	[string]: {
		Properties: SoundProperties,
		Ids: { number },
	}
}

export type PlayServerSound = {
	Parent: instance?,
	Class: string,
	Path: string?,
	Name: string,
}

export type PlaySound = {
	Parent: Instance?,
	Sound: string,
	Path: string?,
}

return Types;