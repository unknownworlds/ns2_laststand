All files with the ending ".entry" will be loaded. 
Priority defines the order of loading multiple mods. A mod of priority 10 will be
loaded first, mods with priority 1 last.

content for an example.entry file:

modEntry = [[
	Client: lua/TestClient.lua,
	Server: lua/TestServer.lua,
	Predict: lua/TestPredict.lua,
        Shared: lua/TestShared.lua,
	Priority: 5
]]

You can also write lua code in the entry files, but for increasing the likely hood of compatibility between mods,
its strongly recommended to not do so and stick with the suggested convention.