--[[
	PATH: /buildOS/modules/01_permission.lua
	TYPE: Core Module
	LAST CHANGE: 04/22/17
	DESCRIPTION:
		This module is responsible for the user
		system and their permission to edit in certain directories.
]]


-- Variables
local users = {} -- contains every user and his password
local sha = require("sha")
local fs = fs
local loggedUser = nil
local loggedPw = nil
local oldUser = nil
local oldPw = nil

-- Init

local function hash(str, salt)
	local pw = sha(str, salt, 3):toHex()
	return tostring(pw)
end

if fs.exists("/buildOS/system/usrData") then
	local file = fs.open("/buildOS/system/usrData", "r")
	local inhalt = file.readAll()
	file.close()
	users = {}
	inhalt = textutils.unserialize(inhalt)
	for user, pw in pairs(inhalt) do
		users[user] = pw
	end
else
	local file = fs.open("/buildOS/system/usrData", "w")
	file.write("{}")
	file.close()
	users = {}
end

local forbidden = {"/buildOS/system", "/buildOS/modules"}

local perm = {
	permission = {},
	user = {}
}

-- Functions

local function writeData()
	local file = fs.open("/buildOS/system/usrData", "w")
	file.write(textutils.serialize(users))
	file.close()
end

function perm.printData()
	return textutils.serialize(users)
end

function perm.user.login(name, password)
	if #name < 1 or #password < 1 then return false, "username, password expected" end
	if users[name] == nil then return false, "user does not exist" end
	if users[name] == hash(password, name) then
		loggedUser = name
		loggedPw = hash(password, name)
		return true
	else
		return false, "wrong password"
	end
end

function perm.user.getLoggedUser()
	return loggedUser
end

function perm.user.add(name, password)
	if #name < 1 or #password < 1 then return false, "username, password expected" end
	if name == "root" then return false, "root aready registered" end
	if users[name] then return false, "user already exists" end
	users[name] = hash(password, name)
	writeData()
	return true
end

function perm.user.remove(name, password)
	if #name < 1 or #password < 1 then return false, "username, password expected" end
	if name == "root" then return false, "root can not be removed" end
	if users[name] == nil then return false, "user does not exist" end
	if perm.user.getLoggedUser() == "root" then
		users[name] = nil
		writeData()
	elseif perm.user.getLoggedUser() ~= name then
		if users[name] == hash(password, name) then
			users[name] = nil
			writeData()
		else
			return false, "wrong password"
		end
	else
		if users[name] == hash(password, name) then
			users[name] = nil
			writeData()
			loggedUser = nil
			loggedPw = nil
		else
			return false, "wrong password"
		end
	end
	return true
end

function perm.user.switch()
	if loggedUser == "root" then
		local swap = {name = oldUser, pw = oldPw}
		oldUser = "root"
		oldPw = nil
		loggedUser = swap.name
		loggedPw = swap.pw
	else
		oldUser = loggedUser
		oldPw = loggedPw
		loggedUser = "root"
		loggedPw = nil
	end
	return true
end

function perm.permission.check(name, path)
	if string.sub(path, 1, 1) ~= "/" then path = "/"..path end
	local h, j = nil, nil
	for a, b in ipairs(forbidden) do
		h, j = path:find(b)
		if h ~= 1 then
			h, j = nil, nil
		else
			break
		end
	end
	if (path:find("home/") == 1 or path:find("home/") == 2) and not (path:find("home/"..perm.user.getLoggedUser()) == 1 or path:find("home/"..perm.user.getLoggedUser()) == 2) then
		-- If the user is in the wrong home directory
		return "x"
	end
	-- wx = write access; x = read access
	if h then
		if perm.user.getLoggedUser() ~= "root" then
			return "x"
		else
			return "wx"
		end
	end
	return "wx"
end

_G['perm'] = perm