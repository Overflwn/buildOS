--[[
	PATH: /buildOS/modules/02_filesystem.lua
	TYPE: Core Module
	LAST CHANGE: 04/23/17
	DESCRIPTION:
		This module is responsible for the FS API,
		which checks whether the user is allowed to edit
		certain files or not.
]]

local oldfs = fs
local _fs = {}

for a, b in pairs(oldfs) do
	_fs[a] = b
end

function _fs.delete(path)
	if perm.permission.check(perm.user.getLoggedUser(), path) == "wx" then
		return oldfs.delete(path)
	else
		return false, "no permissions"
	end
end

function _fs.move(path1, path2)
	if perm.permission.check(perm.user.getLoggedUser(), path2) == "wx" and perm.permission.check(perm.user.getLoggedUser(), path1) == "wx" then
		return oldfs.move(path1, path2)
	else
		return false, "no permissions"
	end
end

function _fs.copy(path1, path2)
	if perm.permission.check(perm.user.getLoggedUser(), path2) == "wx" then
		return oldfs.copy(path1, path2)
	else
		return false, "no permissions"
	end
end

function _fs.open(path, mode)
	if mode == "w" or mode == "wb" or mode == "a" or mode == "ab" then
		if perm.permission.check(perm.user.getLoggedUser(), path) == "wx" then
			return oldfs.open(path, mode)
		else
			return false, "no permissions"
		end
	else
		return oldfs.open(path, mode)
	end
end

function _fs.makeDir(path)
	if perm.permission.check(perm.user.getLoggedUser(), path) == "wx" then
		return oldfs.makeDir(path)
	else
		return false, "no permissions"
	end
end

_G.fs = _fs