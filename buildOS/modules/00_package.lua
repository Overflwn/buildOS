--[[
	PATH: /buildOS/modules/00_package.lua
	TYPE: Core Module
	LAST CHANGE: 04/22/17
	DESCRIPTION:
		This core module is responsible for
		loading APIs. (--> 'require(blah)' )
]]

local loadedAPIs = {} -- table containing every loaded API

local function require(name)
	if not fs.exists("/buildOS/libs/"..name) or fs.isDir("/buildOS/libs/"..name) then return false, "no such library" end
	if loadedAPIs[name] then return loadedAPIs[name] end
	local file, err = loadfile("/buildOS/libs/"..name)
	if not file then return false, err end
	local env = {}
	setmetatable(env, {__index = _G})
	setfenv(file, env)
	local ok, err = pcall(file)
	if not ok then return false, err end
	loadedAPIs[name] = err
	return loadedAPIs[name]
end

local function unload(name)
	if not loadedAPIs[name] then return false, "library not loaded" end
	loadedAPIs[name] = nil
	return true
end

_G['require'] = require
_G['unload'] = unload