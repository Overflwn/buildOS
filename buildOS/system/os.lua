--[[
	PATH: /buildOS/system/os.lua
	TYPE: Main OS Script
	LAST CHANGE: 04/26/17
	DESCRIPTION:
		This script is responsible for setting
		everything GUI-related up and is basically
		the main script of the OS.
]]

-- Variables

local taskmanager = require("taskmanager")
local curLog = tostring(os.time())
local originalTerm = term.current()
local maxX, maxY = term.getSize()
local tasklist = taskmanager.createList()
local toolBar = window.create(originalTerm, maxX-2, 1, 2, 1)
local menuBar = window.create(originalTerm, 1, 1, maxX, 1)
local taskBar = window.create(originalTerm, 1, 2, maxX, maxY-1, false)
local appWindow = window.create(originalTerm, 1, 2, maxX, maxY-1)
local menuBarExtension = window.create(originalTerm, 1, 2, maxX, 1, false)
local inApp = false
local curApp = 0
_G.shell = shell
function _G.printError(str)
	term.setTextColor(colors.red)
	print(str)
end
-- This table contains the windows for the corresponding tasks (delete upon killing the task)
local windows = {}

-- Functions

local function startApp(name)
	-- Global function available for every task
	if fs.exists("/buildOS/apps/"..name..".app/startup") then
		log("Starting up "..name)
		local env = {}
		setmetatable(env, {__index = _G})
		for each, task in ipairs(tasklist.tasks) do
			if task.front then
				task.front = false
				windows[task.name].setVisible(false)
			end
		end
		
		local ok, err = taskmanager.createTask(tasklist, name, "/buildOS/apps/"..name..".app/startup", env)
		if not ok then
			local curTerm = term.current()
			local errWin = window.create(originalTerm, math.floor(maxX/4), math.floor(maxY/4), math.floor(maxX/2), math.floor(maxY/2))
			term.redirect(errWin)
			term.setBackgroundColor(colors.lightGray)
			term.setTextColor(colors.red)
			term.clear()
			print("There was an error with your program. Check the logfiles!")
			term.redirect(curTerm)
			sleep(2)
			errWin = nil
			curTerm.redraw()
			return false
		end
		windows[tasklist.tasks[#tasklist.tasks].name] = window.create(appWindow, 1, 1, maxX, maxY-1)
		toolBar.redraw()
		inApp = true
		curApp = #tasklist.tasks
		return true
	else
		log("Tried to start "..name..", but startup was not found.")
		return false
	end
end

local function resumeApp(id)
	for each, task in ipairs(tasklist.tasks) do
	if task.front then
			task.front = false
			windows[task.name].setVisible(false)
		end
	end
	tasklist.tasks[id].front = true
	windows[tasklist.tasks[id].name].setVisible(true)
	inApp = true
	curApp = id
	toolBar.redraw()
end

_G.log = function(str)
	local file = fs.open("/buildOS/log/"..curLog, "a")
	file.writeLine(str)
	file.close()
end

local function drawExtendedMenu()
	menuBarExtension.setVisible(true)
	menuBarExtension.setCursorPos(1,1)
	menuBarExtension.setTextColor(colors.white)
	menuBarExtension.write("Programs Settings")
	while true do
		local event, button, x, y = os.pullEventRaw("mouse_click")
		if button == 1 and x == math.floor(maxX/2) and y == 1 then
			menuBarExtension.setVisible(false)
			return true
		elseif button == 1 and x >= 1 and x <= 8 and y == 2 then
			startApp("programs")
			return false
		end
	end
end

local function drawTaskBar()
	taskBar.setVisible(true)
	taskBar.setCursorPos(1,1)
	taskBar.setBackgroundColor(colors.lightGray)
	taskBar.setTextColor(colors.white)
	taskBar.clear()
	local missing = 0
	local left = 0
	for each, task in ipairs(tasklist.tasks) do
		if each <= maxY-1 then
			taskBar.write(task.name)
			local cx, cy = taskBar.getCursorPos()
			taskBar.setCursorPos(maxX-1, cy)
			taskBar.setBackgroundColor(colors.blue)
			taskBar.write(">")
			taskBar.setBackgroundColor(colors.red)
			taskBar.write("X")
			taskBar.setBackgroundColor(colors.lightGray)
			if each < maxY-1 then
				taskBar.setCursorPos(1, cy+1)
			end
		end
	end
	if (#tasklist.tasks - (maxY-1)) < 0 then left = 0 else left = (#tasklist.tasks - (maxY-1)) end
	while true do
		local event, button, x, y = os.pullEventRaw()
		if event == "mouse_click" and button == 1 and x == maxX and y > 1 then
			y = y-1
			if tasklist.tasks[missing+y] and not tasklist.tasks[missing+y].core then
				windows[tasklist.tasks[missing+y].name] = nil
				table.remove(tasklist.tasks, missing+y)
				drawTaskBar()
				return true
			end
		elseif event == "mouse_click" and button == 1 and x == maxX-1 and y > 1 then
			y = y-1
			if tasklist.tasks[missing+y] and not tasklist.tasks[missing+y].core then
				resumeApp(missing+y)
				return false
			end
		elseif event == "mouse_scroll" then
			-- -1 = up; 1 = down
			if button == -1 then
				if missing > 0 then
					left = left+1
					taskBar.scroll(-1)
					taskBar.setCursorPos(1,1)
					taskBar.write(tasklist.tasks[missing].name)
					taskBar.setCursorPos(maxX-1, 1)
					taskBar.setBackgroundColor(colors.blue)
					taskBar.write(">")
					taskBar.setBackgroundColor(colors.red)
					taskBar.write("X")
					taskBar.setBackgroundColor(colors.lightGray)
					missing = missing-1
				end
			elseif button == 1 then
				if left > 0 then
					taskBar.scroll(1)
					taskBar.setCursorPos(1, maxY-1)
					taskBar.write(tasklist.tasks[missing+(maxY-1)+1].name)
					taskBar.setCursorPos(maxX-1, maxY-1)
					taskBar.setBackgroundColor(colors.blue)
					taskBar.write(">")
					taskBar.setBackgroundColor(colors.red)
					taskBar.write("X")
					taskBar.setBackgroundColor(colors.lightGray)
					missing = missing + 1
					left = left - 1
				end
			end
		elseif event == "mouse_click" and button == 1 and x == 1 and y == 1 then
			taskBar.setVisible(false)
			return true
		end
	end
end

_G.startApp = startApp

-- Code


--[[SCREEN SETUP]]--
toolBar.setBackgroundColor(colors.yellow)
toolBar.setTextColor(colors.white)
toolBar.write("_")
toolBar.setBackgroundColor(colors.red)
toolBar.write("X")
menuBar.setBackgroundColor(colors.lightGray)
menuBar.setTextColor(colors.white)
menuBar.clear()
menuBar.write("@")
menuBar.setCursorPos(maxX, 1)
menuBar.setBackgroundColor(colors.red)
menuBar.write("!")
menuBar.setCursorPos(math.floor(maxX/2), 1)
menuBar.setBackgroundColor(colors.lightGray)
menuBar.write("v")
menuBarExtension.setBackgroundColor(colors.lightGray)
menuBarExtension.clear()
taskBar.setBackgroundColor(colors.lightGray)
taskBar.setTextColor(colors.white)
taskBar.clear()
appWindow.setBackgroundColor(colors.black)
appWindow.setTextColor(colors.white)
appWindow.clear()
--[[SCREEN SETUP END]]--

--[[CORE TASK SETUP]]--
local ok, err = taskmanager.createTask(tasklist, "Desktop", "/buildOS/coreapps/desktop.app/startup", _G, true)
windows.Desktop = window.create(appWindow, 1, 1, maxX, maxY-1)
--[[CORE TASK SETUP END]]--



--[[TASKMANAGEMENT]]--
local evt = {}
while true do
	for each, task in ipairs(tasklist.tasks) do
		local v = {}
		for a, b in ipairs(evt) do
			table.insert(v, b)
		end
		term.redirect(windows[task.name])
		if #v > 0 then
			if string.find(v[1], "mouse") then
				-- Set the Y coordinate of the mouse event one up, cuz the app window is by 1 pixel smaller
				v[4] = v[4]-1
			end
			if (string.find(v[1], "mouse") or string.find(v[1], "key") or string.find(v[1], "char")) and not task.front then
				v = {}
			end
		end
		ok, err = task:resume(v)
		term.redirect(originalTerm)
	end
	evt = {os.pullEventRaw()}
	local event, button, x, y = unpack(evt)
	if event == "mouse_click" and button == 1 and x == maxX and y == 1 then
		os.shutdown()
	elseif event == "mouse_click" and button == 1 and x == 1 and y == 1 then
		windows.Desktop.setVisible(true)
		windows.Desktop.redraw()
		menuBar.redraw()
		inApp = false
		curApp = 0
		local redraw = drawTaskBar()
		if redraw then
			windows.Desktop.redraw()
			tasklist.tasks[1].front = true
		end
	elseif inApp and event == "mouse_click" and button == 1 and x == maxX-2 and y == 1 then
		for each, task in ipairs(tasklist.tasks) do
			if task.front then
				task.front = false
				windows[task.name].setVisible(false)
			end
		end
		tasklist.tasks[1].front = true
		windows.Desktop.setVisible(true)
		windows.Desktop.redraw()
		menuBar.redraw()
		inApp = false
	elseif inApp and event == "mouse_click" and button == 1 and x == maxX-1 and y == 1 then
		tasklist.tasks[1].front = true
		windows[tasklist.tasks[curApp].name] = nil
		windows.Desktop.setVisible(true)
		windows.Desktop.redraw()
		menuBar.redraw()
		inApp = false
		table.remove(tasklist.tasks, curApp)
	elseif event == "mouse_click" and button == 1 and x == math.floor(maxX/2) and y == 1 then
		windows.Desktop.setVisible(true)
		windows.Desktop.redraw()
		menuBar.redraw()
		inApp = false
		curApp = 0
		local redraw = drawExtendedMenu()
		if redraw then
			windows.Desktop.redraw()
			tasklist.tasks[1].front = true
		end
	elseif event == "os_killApp" and button then
		local found = false
		for each, task in ipairs(tasklist.tasks) do
			if task.name == button then
				found = each
			end
			if task.name == "Desktop" then
				task.front = true
			end
		end
		if found then
			windows[tasklist.tasks[found].name] = nil
			windows.Desktop.setVisible(true)
			windows.Desktop.redraw()
			menuBar.redraw()
			inApp = false
			table.remove(tasklist.tasks, found)
		end
	end
end
--[[TASKMANAGEMENT END]]--