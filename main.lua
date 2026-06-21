-----------------------------------------------
-- LUIS Sample Launcher
-----------------------------------------------
-- Pick a sample from the list and press Enter (or click it) to start.
-- Inside a sample, press Escape to return to this launcher.
--
--   Up / Down ....... move selection
--   Enter / Click ... launch the selected sample
--   Mouse wheel ..... scroll the list
--   Escape .......... quit (from the launcher) / return here (from a sample)
--
-- Each sample's main.lua overrides the global love.* callbacks when required,
-- so the launcher clears its own callbacks before handing control to the sample.
-- Samples return here by calling love.event.quit("restart"), which relaunches
-- this main.lua in a fresh Lua state (clean menu, no leftover sample state).

local samples = {
	-- Samples with Mouse/Gamepad/Keyboard support
	{ module = "samples.complex_ui.main",       name = "complex_ui",       desc = "Full-featured demo (themes, menus, gamepad)" },
	{ module = "samples.virtual_gamepad.main",  name = "virtual_gamepad",  desc = "On-screen gamepad + snake / ball arena" },
	{ module = "samples.flexContainer.main",    name = "flexContainer",    desc = "Flexible container layout + nodes" },
	{ module = "samples.nodegraph.main",        name = "nodegraph",        desc = "Node graph / logic gates" },
	{ module = "samples.editor.main",           name = "editor",           desc = "In-app widget editor" },
	{ module = "samples.propertyGrid.main",     name = "propertyGrid",     desc = "Property grid inspector" },
	-- Other samples
	{ module = "samples.demo_ui.main",          name = "demo_ui",          desc = "Simple settings UI" },
	{ module = "samples.basic_ui.main",         name = "basic_ui",         desc = "Core library with its own retro widgets" },
	{ module = "samples.gridLayoutTest.main",   name = "gridLayoutTest",   desc = "Grid layout test" },
	{ module = "samples.difficulty_curve.main", name = "difficulty_curve", desc = "Difficulty curve tuning sliders" },
	{ module = "samples.demo_game.main",        name = "demo_game",        desc = "Mini dungeon RPG with battle" },
	{ module = "samples.guess_game.main",       name = "guess_game",       desc = "Number guessing game" },
	{ module = "samples.AI_Test.main",          name = "AI_Test",          desc = "AI-generated menu test" },
	{ module = "samples.jrpg_battlemenu.main",  name = "jrpg_battlemenu",  desc = "JRPG battle menu" },
	{ module = "samples.test.main",             name = "test",             desc = "Minimal custom widget test" },
	{ module = "samples.dialogueBox.main",      name = "dialogueBox",      desc = "Animated dialogue box" },
	{ module = "samples.preCreatedWidgets.main",name = "preCreatedWidgets",desc = "Pre-created widget objects" },
}

local launcher = {
	selected = 1,
	scroll = 0,        -- index offset of the first visible item
	itemHeight = 40,
	headerHeight = 110,
	fonts = {},
}

-- Every love callback the launcher installs. Cleared before launching a sample so
-- no leftover launcher callback runs against a sample that doesn't redefine it.
local LAUNCHER_CALLBACKS = {
	"load", "update", "draw", "keypressed", "keyreleased", "textinput",
	"mousepressed", "mousereleased", "mousemoved", "wheelmoved", "resize",
	"gamepadpressed", "gamepadreleased", "joystickadded", "joystickremoved",
}

local function visibleCount()
	local h = love.graphics.getHeight()
	return math.max(1, math.floor((h - launcher.headerHeight - 20) / launcher.itemHeight))
end

local function clampScroll()
	local maxScroll = math.max(0, #samples - visibleCount())
	if launcher.scroll < 0 then launcher.scroll = 0 end
	if launcher.scroll > maxScroll then launcher.scroll = maxScroll end
end

-- Keep the selected item inside the visible window.
local function ensureVisible()
	local count = visibleCount()
	if launcher.selected < launcher.scroll + 1 then
		launcher.scroll = launcher.selected - 1
	elseif launcher.selected > launcher.scroll + count then
		launcher.scroll = launcher.selected - count
	end
	clampScroll()
end

function launchSample(index)
	local sample = samples[index]
	if not sample then return end

	-- Hand over control: drop the launcher's callbacks, then require the sample,
	-- which (re)installs its own love.* callbacks. Finally run its love.load if any.
	for _, name in ipairs(LAUNCHER_CALLBACKS) do
		love[name] = nil
	end

	require(sample.module)

	if love.load then
		love.load()
	end
end

function love.load()
	love.window.setMode(900, 720, { resizable = true, highdpi = false })
	love.window.setTitle("LUIS - Sample Launcher")
	launcher.fonts.title = love.graphics.newFont(30)
	launcher.fonts.sub   = love.graphics.newFont(14)
	launcher.fonts.item  = love.graphics.newFont(18)
	launcher.fonts.desc  = love.graphics.newFont(12)
end

function love.draw()
	love.graphics.setBackgroundColor(0.10, 0.11, 0.13)

	-- Header
	love.graphics.setColor(1, 1, 1)
	love.graphics.setFont(launcher.fonts.title)
	love.graphics.print("LUIS Samples", 30, 26)

	love.graphics.setColor(0.6, 0.6, 0.65)
	love.graphics.setFont(launcher.fonts.sub)
	love.graphics.print("Up/Down to select   -   Enter or click to launch   -   Wheel to scroll   -   Esc to quit   (Esc inside a sample returns here)", 32, 70)

	-- List
	local count = visibleCount()
	local x, w = 24, love.graphics.getWidth() - 48
	for row = 1, count do
		local index = launcher.scroll + row
		local sample = samples[index]
		if sample then
			local y = launcher.headerHeight + (row - 1) * launcher.itemHeight
			local isSel = (index == launcher.selected)

			if isSel then
				love.graphics.setColor(0.20, 0.42, 0.72, 1)
			else
				love.graphics.setColor(0.16, 0.17, 0.20, 1)
			end
			love.graphics.rectangle("fill", x, y, w, launcher.itemHeight - 6, 6, 6)

			love.graphics.setColor(1, 1, 1)
			love.graphics.setFont(launcher.fonts.item)
			love.graphics.print(string.format("%2d. %s", index, sample.name), x + 14, y + 4)

			love.graphics.setColor(isSel and {0.85, 0.9, 1} or {0.55, 0.56, 0.6})
			love.graphics.setFont(launcher.fonts.desc)
			love.graphics.print(sample.desc, x + 230, y + 9)
		end
	end

	-- Scroll indicator
	if #samples > count then
		love.graphics.setColor(0.5, 0.5, 0.55)
		love.graphics.setFont(launcher.fonts.desc)
		love.graphics.printf(
			string.format("%d-%d / %d", launcher.scroll + 1, math.min(launcher.scroll + count, #samples), #samples),
			0, love.graphics.getHeight() - 22, love.graphics.getWidth() - 30, "right")
	end
end

-- Which list row (if any) is under a screen point.
local function indexAt(px, py)
	local count = visibleCount()
	local x, w = 24, love.graphics.getWidth() - 48
	for row = 1, count do
		local index = launcher.scroll + row
		if samples[index] then
			local y = launcher.headerHeight + (row - 1) * launcher.itemHeight
			if px >= x and px <= x + w and py >= y and py <= y + launcher.itemHeight - 6 then
				return index
			end
		end
	end
	return nil
end

function love.mousemoved(x, y)
	local index = indexAt(x, y)
	if index then launcher.selected = index end
end

function love.mousepressed(x, y, button)
	if button ~= 1 then return end
	local index = indexAt(x, y)
	if index then
		launcher.selected = index
		launchSample(index)
	end
end

function love.wheelmoved(_, dy)
	launcher.scroll = launcher.scroll - dy
	clampScroll()
end

function love.keypressed(key)
	if key == "escape" then
		love.event.quit()
	elseif key == "down" then
		launcher.selected = math.min(#samples, launcher.selected + 1)
		ensureVisible()
	elseif key == "up" then
		launcher.selected = math.max(1, launcher.selected - 1)
		ensureVisible()
	elseif key == "home" then
		launcher.selected = 1
		ensureVisible()
	elseif key == "end" then
		launcher.selected = #samples
		ensureVisible()
	elseif key == "return" or key == "kpenter" or key == "space" then
		launchSample(launcher.selected)
	end
end

function love.resize()
	ensureVisible()
end
