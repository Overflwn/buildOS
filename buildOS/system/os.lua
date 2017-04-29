--[[
	PATH: /buildOS/system/os.lua
	TYPE: Main OS Script
	LAST CHANGE: 04/29/17
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
local taskBar = window.create(originalTerm, 1, 2, 4, maxY-1, false)
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
		
		local ok, err = taskmanager.createTask(tasklist, name, "/buildOS/apps/"..name..".app/startup", env, false, "/buildOS/apps/"..name..".app/")
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
	local oldt = term.current()
	--the task on the bottom of the taskmanager
	local last = 0
	--the task on the top of the taskmanager
	local lastbegin = 1
	term.redirect(taskBar)
	--table containing every Y position of every task in the taskmanager
	local positions = {}
	--the imaginary cursor position
	local cpos = 1
	for each, task in ipairs(tasklist.tasks) do
		local cx, cy = term.getCursorPos()
		
		--If a part of the image still fits into the taskbar
		if cpos < maxY-1 then
			local img
			if fs.exists(tostring(task.path).."icon") then
				img = paintutils.loadImage(tostring(task.path).."icon")
			else
				img = paintutils.loadImage("/buildOS/system/dummyIcon")
			end
			paintutils.drawImage(img, cx, cy)
			term.setCursorPos(4, cy)
			term.setBackgroundColor(colors.red)
			term.setTextColor(colors.white)
			term.write("X")
			term.setBackgroundColor(colors.blue)
			term.setCursorPos(3, cy)
			term.write(">")	
		end
		
		--If there is still space left, set the cursorpos. Else set what the last task on the screen is and increase the imaginary cursor position
		table.insert(positions, cpos)
		if cy+5 < maxY-1 then
			term.setCursorPos(1, cy+5)
		elseif last == 0 then
			last = #positions
		end
		cpos = cpos+5
	end
	term.redirect(oldt)
	
	--If there are more icons to draw than they fit on the screen, set "left" to the remaining pixels
	if (positions[#positions] + 4) - (maxY-1) > 0 then
		left = left + (positions[#positions] + 4) - (maxY-1)
	end
	
	--Main loop
	while true do
		local event, button, x, y = os.pullEventRaw()
		if event == "mouse_click" and button == 1 and x == 4 and y > 1 then
			--Kill a task
			y = y-1
			for a, b in ipairs(positions) do
				if b - missing == y and not tasklist.tasks[a].core then
					windows[tasklist.tasks[a].name] = nil
					table.remove(tasklist.tasks, a)
					drawTaskBar()
					return true
				end
			end
		elseif event == "mouse_click" and button == 1 and x == 3 and y > 1 then
			--Resume a task
			y = y-1
			for a, b in ipairs(positions) do
				if b - missing == y and not tasklist.tasks[a].core then
					resumeApp(a)
					return false
				end
			end
		elseif event == "mouse_scroll" then
			-- -1 = up; 1 = down
			if button == -1 then
				if missing > 0 then
					left = left+1
					missing = missing-1
					taskBar.scroll(-1)
					taskBar.setCursorPos(1,1)
					
					--If you scrolled so far that the a new task appeared at the top, set it as the new top
					if positions[lastbegin]-missing > 1 then
						lastbegin = lastbegin-1
					end
					
					--If you scrolled so far that the old bottom task is gone completely, set the task that came before it as the new bottom
					if positions[last]-missing > maxY-1 then
						last = last-1
					end
					
					local oldt = term.current()
					term.redirect(taskBar)
					local img
					if fs.exists(tostring(tasklist.tasks[lastbegin].path).."icon") then
						img = paintutils.loadImage(tostring(tasklist.tasks[lastbegin].path).."icon")
					else
						img = paintutils.loadImage("/buildOS/system/dummyIcon")
					end
					paintutils.drawImage(img, 1, positions[lastbegin]-missing)
					if positions[lastbegin]-missing > 0 then
						--If the first row of pixels of the taskicon is visible, draw the X and > buttons
						term.setCursorPos(3, positions[lastbegin]-missing)
						term.setBackgroundColor(colors.blue)
						term.write(">")
						term.setBackgroundColor(colors.red)
						term.write("X")
						term.setBackgroundColor(colors.lightGray)
					end
					term.redirect(oldt)
				end
			elseif button == 1 then
				if left > 0 then
					taskBar.scroll(1)
					taskBar.setCursorPos(1, maxY-1)
					local found = false
					for a, b in ipairs(positions) do
						if maxY-1+missing+1 == b then
							--If you scrolled so far down that you already start to see the a new task
							local img
							if fs.exists(tostring(tasklist.tasks[a].path).."icon") then
								img = paintutils.loadImage(tostring(tasklist.tasks[a].path).."icon")
							else
								img = paintutils.loadImage("/buildOS/system/dummyIcon")
							end
							local oldt = term.current()
							term.redirect(taskBar)
							paintutils.drawImage(img, 1, maxY-1)
							term.setBackgroundColor(colors.blue)
							term.setCursorPos(3, maxY-1)
							term.write(">")
							term.setBackgroundColor(colors.red)
							term.write("X")
							term.setBackgroundColor(colors.lightGray)
							term.redirect(oldt)
							last = a
							found = true
							break
						end
					end
					if not found then
						--If the 'last' task is still the same, just redraw it
						local oldt = term.current()
						term.redirect(taskBar)
						term.setCursorPos(1, positions[last] - ( missing+1 ))
						local img
						if fs.exists(tostring(tasklist.tasks[last].path).."icon") then
							img = paintutils.loadImage(tostring(tasklist.tasks[last].path).."icon")
						else
							img = paintutils.loadImage("/buildOS/system/dummyIcon")
						end
						paintutils.drawImage(img, 1, positions[last] - ( missing+1 ))
						term.setBackgroundColor(colors.blue)
						term.setCursorPos(3, positions[last] - ( missing+1 ))
						term.write(">")
						term.setBackgroundColor(colors.red)
						term.write("X")
						term.setBackgroundColor(colors.lightGray)
						term.redirect(oldt)
						
					end
					missing = missing + 1
					left = left - 1
					
					--Check if you scrolled so far that the old task on the top is gone completely
					for h, j in ipairs(positions) do
						if j-missing == 1 then
							lastbegin = h
							break
						end
					end
				end
			end
		elseif event == "mouse_click" and button == 1 and x == 1 and y == 1 then
			--Close the taskmanager
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
local ok, err = taskmanager.createTask(tasklist, "desktop", "/buildOS/coreapps/desktop.app/startup", _G, true)
windows.desktop = window.create(appWindow, 1, 1, maxX, maxY-1)
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
		windows.desktop.setVisible(true)
		windows.desktop.redraw()
		menuBar.redraw()
		inApp = false
		curApp = 0
		local redraw = drawTaskBar()
		if redraw then
			windows.desktop.redraw()
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
		windows.desktop.setVisible(true)
		windows.desktop.redraw()
		menuBar.redraw()
		inApp = false
	elseif inApp and event == "mouse_click" and button == 1 and x == maxX-1 and y == 1 then
		tasklist.tasks[1].front = true
		windows[tasklist.tasks[curApp].name] = nil
		windows.desktop.setVisible(true)
		windows.desktop.redraw()
		menuBar.redraw()
		inApp = false
		table.remove(tasklist.tasks, curApp)
	elseif event == "mouse_click" and button == 1 and x == math.floor(maxX/2) and y == 1 then
		windows.desktop.setVisible(true)
		windows.desktop.redraw()
		menuBar.redraw()
		inApp = false
		curApp = 0
		local redraw = drawExtendedMenu()
		if redraw then
			windows.desktop.redraw()
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
			windows.desktop.setVisible(true)
			windows.desktop.redraw()
			menuBar.redraw()
			inApp = false
			table.remove(tasklist.tasks, found)
		end
	end
end
--[[TASKMANAGEMENT END]]--