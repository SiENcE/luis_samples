local initLuis = require("luis.init")
-- Direct this to your widgets folder.
local luis = initLuis("luis/widgets")

-- register flux in luis, because the widgets of complex_ui need this
luis.flux = require("luis.3rdparty.flux")

local json = require("luis.3rdparty.json")
local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")

local defaultTheme = require("luis.themes.styles.defaultTheme")
local customTheme = require("luis.themes.styles.customTheme")
local materialTheme = require("luis.themes.styles.materialTheme")
local alternativeTheme = require("luis.themes.styles.alternativeTheme")

local resolutions = love.window.getFullscreenModes()
table.sort(resolutions, function(a, b) return a.width*a.height < b.width*b.height end)   -- sort from smallest to largest

local function addVirtualKeyboardGamepad()
	print('addVirtualKeyboardGamepad')
	-- create Virtual Analog Stick to emulate Löve2D Gamepad API
	local vjoystick = {}
	-- first virtual Analog Stick
	vjoystick.getName = function()
		return "Virtual Gamepad #1"
	end
	vjoystick.getConnectedIndex = function()
		return 1
	end
	vjoystick.isGamepadDown = function(self, button)
	end
	vjoystick.getGamepadAxis = function(self, axis)
		return 0
	end
	luis.setActiveJoystick(1, vjoystick)
end

local function removeVirtualKeyboardGamepad()
	print('removeVirtualKeyboardGamepad')
	luis.removeJoystick(1)
end

local function addNameAttribute(modes)
    for i, mode in ipairs(modes) do
        mode.name = tostring(mode.width) .. "x" .. tostring(mode.height)
    end
end
addNameAttribute(resolutions)

local function keepTop15Resolutions(modes)
    -- Sort the array by resolution (width * height)
    table.sort(modes, function(a, b)
        return (a.width * a.height) > (b.width * b.height)
    end)
    
    -- Only keep the top 15 resolutions
    while #modes > 15 do
        table.remove(modes)
    end
end

keepTop15Resolutions(resolutions)

-- Game settings
local gameSettings = {
    fullscreen = false,
    musicVolume = 50,
    sfxVolume = 50,
    difficulty = "Normal",
    controlScheme = "Default",
    showFPS = false,
    vsync = true,
    fsaa = 1,  -- 1 corresponds to "Off" in the dropdown
    resizable = true,
    pixelPerfect = false,
    highDpi = false,
	width = luis.baseWidth,
	height = luis.baseWidth
}

local currentTheme = "Custom"
local function toggleTheme()
    if currentTheme == "Default" then
        luis.setTheme(defaultTheme)  -- Reset to default theme
		currentTheme = "Custom"
    elseif currentTheme == "Custom" then
        luis.setTheme(customTheme)
		currentTheme = "Alternative"
    elseif currentTheme == "Alternative" then
        luis.setTheme(materialTheme)
		currentTheme = "Material"
    elseif currentTheme == "Material" then
        luis.setTheme(alternativeTheme)
		currentTheme = "Default"
    end
end

local function getCurrentResolutionIndex()
    local currentWidth, currentHeight = luis.baseWidth, luis.baseHeight
    for i, res in ipairs(resolutions) do
        if res.width == currentWidth and res.height == currentHeight then
            return i
        end
    end
    return 1  -- Default to the first resolution if current is not in the list
end

-- The CustomView can be used to render gameplay
-- Snake Minigame
local snake = {
    body = {{x = 5, y = 5}},
    direction = {x = 1, y = 0},
    grow = false
}
local food = {x = 10, y = 10}
local gridSize = luis.gridSize
local moveTimer = 0
local moveInterval = 0.1
local function updateSnake()
    local head = snake.body[1]
    local newHead = {x = head.x + snake.direction.x, y = head.y + snake.direction.y}
    
    -- Check for collisions
    if newHead.x < 0 or newHead.x >= gridSize or newHead.y < 0 or newHead.y >= gridSize then
        -- Game over - reset snake
        snake.body = {{x = 5, y = 5}}
        snake.direction = {x = 1, y = 0}
        return
    end
    
    for i = 2, #snake.body do
        if newHead.x == snake.body[i].x and newHead.y == snake.body[i].y then
            -- Game over - reset snake
            snake.body = {{x = 5, y = 5}}
            snake.direction = {x = 1, y = 0}
            return
        end
    end
    
    table.insert(snake.body, 1, newHead)
    
    if newHead.x == food.x and newHead.y == food.y then
        -- Eat food
        snake.grow = true
        -- New food position
        food.x = love.math.random(0, gridSize - 1)
        food.y = love.math.random(0, gridSize - 1)
    end
    
    if not snake.grow then
        table.remove(snake.body)
    else
        snake.grow = false
    end
end

local function createSnakeMiniGame()
	local container = luis.newFlexContainer(22, 22, 7, 38)

	local customView = luis.newCustom(function()
		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("line", 0, 0, 20*gridSize, 20*gridSize)

		love.graphics.setColor(1, 1, 0)
		local cellSize = 400 / gridSize
		for _, segment in ipairs(snake.body) do
			love.graphics.rectangle("fill", segment.x * cellSize, segment.y * cellSize, cellSize, cellSize)
		end
		
		love.graphics.setColor(1, 0, 1)
		love.graphics.rectangle("fill", food.x * cellSize, food.y * cellSize, cellSize, cellSize)
	end, 20, 20, 0, 0)

	-- add a custom keypress to our custom widget (a custom widget has initially only a draw function)
	customView.keypressed = function(self, key)
		-- Check for joystick button press when focused
		local x,y = love.mouse.getPosition()
		local hovered = utils.pointInRect( x,y, self.position.x, self.position.y, self.width, self.height)
		if self.focused or hovered then
			if key == "up" and snake.direction.y == 0 then
				snake.direction = {x = 0, y = -1}
			elseif key == "down" and snake.direction.y == 0 then
				snake.direction = {x = 0, y = 1}
			elseif key == "left" and snake.direction.x == 0 then
				snake.direction = {x = -1, y = 0}
			elseif key == "right" and snake.direction.x == 0 then
				snake.direction = {x = 1, y = 0}
			end
		end
	end
			
	container:addChild(customView)
	
	-- Add the container to your LUIS layer
    luis.createElement("custom", "FlexContainer", container)
end
-- Snake Minigame End

local mainMenuElements = {}
local function createMainMenu()
    luis.createElement("main", "Label", "Main Menu", 96, 4, 4, 44)
    local menuItems = {"Start Game", "Settings", "Highscore", "Quit"}
    for i, item in ipairs(menuItems) do
        local btn = luis.createElement("main", "Button", item, 15, 3, function() handleMainMenuSelection(item) end, function() end, 25 + i * 5, 41)
		table.insert(mainMenuElements, btn)
    end
end

local function createSettingsMenu()
    luis.createElement("settings", "Label", "Settings", 96, 4, 4, 45)
    local settingsItems = {"Video", "Audio", "Gameplay", "Controls", "Back"}
    for i, item in ipairs(settingsItems) do
        luis.createElement("settings", "Button", item, 15, 3, function() handleSettingsMenuSelection(item) end, function() end, 20 + i * 5, 41)
    end
end

local function createVideoMenu()
    luis.createElement("video", "Label", "Video Settings", 96, 4, 4, 43)

    -- Fullscreen
    luis.createElement("video", "Label", "Fullscreen", 10, 3, 10, 40)
    luis.createElement("video", "Switch", gameSettings.fullscreen, 5, 3, function(value) 
        gameSettings.fullscreen = value
		--love.window.setFullscreen(value, "desktop")
    end, 10, 50)

    -- Show FPS
    luis.createElement("video", "Label", "Show FPS", 10, 3, 15, 40)
    luis.createElement("video", "CheckBox", gameSettings.showFPS, 3, function(value)
        gameSettings.showFPS = value
    end, 15, 50)
    
    -- VSync
    luis.createElement("video", "Label", "VSync", 10, 3, 20, 40)
    luis.createElement("video", "Switch", gameSettings.vsync, 5, 3, function(value)
        gameSettings.vsync = value
        --love.window.setVSync(value and 1 or 0)
    end, 20, 50)

	-- Resolution
	luis.createElement("video", "Label", "Resolution", 10, 3, 25, 40)
	local resolutionNames = {}
	for _, res in ipairs(resolutions) do
		table.insert(resolutionNames, res.name)
	end
	luis.createElement("video", "DropDown", resolutionNames, getCurrentResolutionIndex(), 15, 3, function(item, index)
		local newRes = resolutions[index]
		gameSettings.width = newRes.width
		gameSettings.height = newRes.height
		-- when chainging the resolution, we have to always tell this luis!
		luis.baseWidth = gameSettings.width
		luis.baseHeight = gameSettings.height
		-- apply new mode seetings
		love.window.updateMode(luis.baseWidth, luis.baseHeight, {
			minwidth=800,
			minheight=600,
			fullscreen = gameSettings.fullscreen,
			vsync = gameSettings.vsync and 1 or 0,
			msaa = gameSettings.fsaa == 1 and 0 or (2 ^ (gameSettings.fsaa - 1)),
			resizable = gameSettings.resizable,
			highdpi = gameSettings.highDpi
		})
	end, 25, 50, 6)

    -- Resizable
    luis.createElement("video", "Label", "Resizable", 10, 3, 30, 40)
    luis.createElement("video", "CheckBox", gameSettings.resizable, 3, function(value)
        gameSettings.resizable = value
        --love.window.updateMode(love.graphics.getWidth(), love.graphics.getHeight(), {resizable = value})
    end, 30, 50)

	-- FSAA (Full-Screen Anti-Aliasing)
	luis.createElement("video", "Label", "FSAA", 10, 3, 35, 40)
	luis.createElement("video", "DropDown", {"Off", "2x", "4x", "8x"}, gameSettings.fsaa, 10, 3, function(item, index)
		gameSettings.fsaa = index
		local fsaaValue = {0, 2, 4, 8}
		--love.window.updateMode(love.graphics.getWidth(), love.graphics.getHeight(), {msaa = fsaaValue[index]})
	end, 35, 50)

    -- High DPI
    luis.createElement("video", "Label", "High DPI", 10, 3, 40, 40)
    luis.createElement("video", "CheckBox", gameSettings.highDpi, 3, function(value)
        gameSettings.highDpi = value
        --love.window.updateMode(love.graphics.getWidth(), love.graphics.getHeight(), {highdpi = value})
    end, 40, 50)

    luis.createElement("video", "Button", "Save/Back", 15, 3, function()
			-- apply new mode seetings
			love.window.updateMode(luis.baseWidth, luis.baseHeight, {
				minwidth=800,
				minheight=600,
				fullscreen = gameSettings.fullscreen,
				vsync = gameSettings.vsync and 1 or 0,
				msaa = gameSettings.fsaa == 1 and 0 or (2 ^ (gameSettings.fsaa - 1)),
				resizable = gameSettings.resizable,
				highdpi = gameSettings.highDpi
			})

			-- and we call popMenu
			popMenu()
		end,
		function() end, 45, 41)
end

local function createAudioMenu()
    luis.createElement("audio", "Label", "Audio Settings", 96, 4, 4, 43)
    
    luis.createElement("audio", "Label", "Music Volume", 10, 3, 20, 30)
    luis.createElement("audio", "Slider", 0, 100, gameSettings.musicVolume, 20, 3, function(value) 
        gameSettings.musicVolume = value
        -- Update actual music volume here
    end, 20, 45)
    
    luis.createElement("audio", "Label", "SFX Volume", 10, 3, 28, 30)
    luis.createElement("audio", "Slider", 0, 100, gameSettings.sfxVolume, 20, 3, function(value) 
        gameSettings.sfxVolume = value
        -- Update actual SFX volume here
    end, 28, 45)
    
    luis.createElement("audio", "Button", "Back", 15, 3, popMenu, function() end, 45, 41)
end

local function createGameplayMenu()
    luis.createElement("gameplay", "Label", "Gameplay Settings", 96, 4, 4, 41)

	-- custom widget Theme
    local radiobuttonTheme = {
        circleColor = {0,0,0,0},
        dotColor = {0,128,128},
    }
    local textLabel = {
        color = {128,128,0},
        font = love.graphics.newFont("luis/themes/fonts/DungeonFont.ttf", 32),
        align = "left",
    }    
    luis.createElement("gameplay", "Label", "Difficulty", 10, 3, 20, 28, nil, textLabel)
    local difficulties = {"Easy", "Normal", "Hard"}
	-- create  radio Buttons
    for i, diff in ipairs(difficulties) do
        local btn = luis.createElement("gameplay", "RadioButton", "difficulty", gameSettings.difficulty == diff, 3, function(value)
            if value then
                gameSettings.difficulty = diff
                -- Update actual difficulty here
            end
        end, 20, 27 + i * 10, radiobuttonTheme)
		-- optional Decorator applied
		btn:setDecorator("GlassmorphismDecorator", {
			opacity = 0.6,
			blur = 15,
			borderRadius = 12,
			backgroundColor = {1, 1, 1, 0.15},
			shadowOffsetX = 8,
			shadowOffsetY = 8
		})
		-- create a Label for each Button
        luis.createElement("gameplay", "Label", diff, 10, 3, 20, 31 + i * 10, nil, textLabel)
    end

	-- In your LUIS initialization code:
	luis.createElement("gameplay", "ColorPicker", 10, 3, 30, 42,
		function(color)
			print("Selected color:", color[1], color[2], color[3])
		end)

	luis.createElement("gameplay", "TextInput", 20, 3, "Enter text here...", function(text) print(text) end, 40, 38)

	-------------------------------------------------------

	-- Create with any number of segments
	local wheel = luis.createElement("gameplay", "DialogueWheel", 
		{"Option1", "Option2", "Option3", "Option4"}, -- Can be any number
		20, 20,
		function(segmentText, segment)
			print(segmentText, segment)
		end,
		25, 10
	)

	-- You can pass options with enabled state
	local options = {
		{ text = "Attack", enabled = true },
		{ text = "Defend", enabled = false },
		{ text = "Magic", enabled = true },
		{ text = "Item", enabled = true }
	}

	-- Or toggle them later
	wheel:setSegmentEnabled(2, false)  -- Disable second segment
	wheel:setSegmentEnabled(2, true)   -- Enable second segment


	-- Update with new options
	wheel:setOptions(options)

	-- Or with detailed options
	wheel:setOptions({
		{ text = "Yes!", enabled = true },
		{ text = "No!", enabled = true },
		{ text = "Maybe!", enabled = true },
		{ text = "Test!", enabled = true },
	})
	-------------------------------------------------------

    luis.createElement("gameplay", "Button", "Back", 15, 3, popMenu, function() end, 45, 41)
end

local textInput_widget
local function createControlsMenu()
    luis.createElement("controls", "Label", "Control Settings", 96, 4, 4, 42)

    luis.createElement("controls", "Label", "Control Scheme", 14, 3, 20, 23)
    local schemes = {"Default", "Alternative", "Custom"}
    for i, scheme in ipairs(schemes) do
        luis.createElement("controls", "RadioButton", "controlScheme", gameSettings.controlScheme == scheme, 3, function(value)
            if value then
                gameSettings.controlScheme = scheme
                -- Update actual control scheme here
            end
        end, 20, 24 + i * 12)
        luis.createElement("controls", "Label", scheme, 8, 3, 20, 28 + i * 12)
    end

	local progressBar = {
        backgroundColor = {0.1, 0.5, 0.8, 1},
        fillColor = {0.15, 0.15, 0.15, 1},
        borderColor = {1, 1, 1, 1},
    }
	luis.createElement("controls", "ProgressBar", 0.5, 10, 1, 25, 43, progressBar)
	icon_widget = luis.createElement("controls", "Icon", "samples/complex_ui/assets/images/icon.png", 3, 30, 43)

	----------------------------------------------------------------
	-- Create a FlexContainer
	local container = luis.newFlexContainer(21, 11, 37, 38)
	
	-- if you don't want to resize the container manually, disable this
	--container.release = function() end
	--container.click = function() end
	
	local customButtonTheme = {
		color = {0.5, 0.1, 0.9, 1},
		hoverColor = {0.15, 0.45, 0.85, 1},
		pressedColor = {0.35, 0.35, 0.35, 1},
		textColor = {0.1, 0.1, 0.1, 1},
		align = "center",	-- left, right, center
		cornerRadius = 15,
		elevation = 0,
		elevationHover = 0,
		elevationPressed = 10,
		transitionDuration = 1.5,
	}
	local button_widget  = luis.newButton( "Toggle Theme", 15, 3, toggleTheme, function() end, 40, 41, customButtonTheme)
	local dropdown = luis.newDropDown(  {"Option 1", "Option 2", "Option 3"}, 3, 10, 2, function(item, index) print("Selected:", item, index) end, 35, 43)
	textInput_widget = luis.newTextInput( 20, 3, "Enter text here...", function(text) print(text) end, 45, 38)
	container:addChild(button_widget)
	container:addChild(textInput_widget)
	container:addChild(dropdown)
	
	-- Resize the container (this will rearrange the children)
	--container:resize(30 * luis.gridSize, 20 * luis.gridSize)
	
	-- Add the container to your controls layer
	luis.createElement("controls", "FlexContainer", container)
	----------------------------------------------------------------

	local btn = luis.createElement("controls", "Button", "Back (Slice9)", 15, 3, popMenu, function() end, 50, 41)
	    -- Load the slice-9 image
    local buttonImage = love.graphics.newImage("samples/complex_ui/assets/images/button_slice9.png")
	btn:setDecorator("Slice9Decorator", buttonImage, 8, 8, 8, 8)
end

function love.load()
    -- Create layers for different menus
    luis.newLayer("main", 96, 54)
    luis.newLayer("settings", 96, 54)
    luis.newLayer("video", 96, 54)
    luis.newLayer("audio", 96, 54)
    luis.newLayer("gameplay", 96, 54)
    luis.newLayer("controls", 96, 54)
	luis.newLayer("custom", 10, 10)

	-- Create UI elements for all menus
	createSnakeMiniGame()
    createMainMenu()
    createSettingsMenu()
    createVideoMenu()
    createAudioMenu()
    createGameplayMenu()
    createControlsMenu()

	-- load last widget state
    if love.filesystem.getInfo('config.json') then
        local jsonString = love.filesystem.read('config.json')
		local config = json.decode(jsonString)
		luis.setConfig(config)
    end

	luis.setTheme(customTheme)

	luis.enableLayer("custom")

	print('love.load - resolution:',luis.baseWidth, luis.baseHeight)

    love.window.setMode(luis.baseWidth, luis.baseHeight, {
		minwidth=800,
		minheight=600,
        fullscreen = gameSettings.fullscreen,
        vsync = gameSettings.vsync and 1 or 0,
        msaa = gameSettings.fsaa == 1 and 0 or (2 ^ (gameSettings.fsaa - 1)),
        resizable = gameSettings.resizable,
        highdpi = gameSettings.highDpi
    })
	love.graphics.setDefaultFilter('nearest', 'nearest')
	love.keyboard.setKeyRepeat(true)

    pushMenu("main")
end

local time = 0
function love.update(dt)
	time = time + dt
	if time >= 1/60 then	
		luis.flux.update(time)
		time = 0
	end

    -- Check for joystick button presses for focus navigation
    if luis.joystickJustPressed(1, 'dpdown') then
        luis.moveFocus("next")
    elseif luis.joystickJustPressed(1, 'dpup') then
        luis.moveFocus("previous")
    end

    luis.updateScale()

    luis.update(dt)

	icon_widget.position = Vector2D.new(math.sin(time*10)+900, math.sin(time*10)+600)
	
	-- for our snake minigame
    moveTimer = moveTimer + dt
    if moveTimer >= moveInterval then
        updateSnake()
        moveTimer = 0
    end
end

function love.draw()
	local startTime = love.timer.getTime()

    luis.draw()

	local endTime = love.timer.getTime()
	
	if gameSettings.showFPS then
		local elapsed_time = (endTime - startTime) * 1000
		if elapsed_time >= 7 then
			love.graphics.setColor(1, 0, 0)
		else
			love.graphics.setColor(1, 1, 1)
		end
		local stats = love.graphics.getStats()
		love.graphics.print(string.format('FPS: %d (%.3f ms) (%d draw calls, %d batched)', love.timer.getFPS(), elapsed_time, stats.drawcalls, stats.drawcallsbatched), 0, love.graphics.getHeight() - 32)
	end
end

function love.resize(w, h)
    luis.updateScale()
end

function pushMenu(menuName)
    luis.setCurrentLayer(menuName)	-- disable current + set new current + enable Layer for drawing
end

function popMenu()
    luis.popLayer()	-- disable current + pop new current from Stack + enable Layer for drawing
end

function handleMainMenuSelection(selected)
    if selected == "Start Game" then
        print("Starting game...")
    elseif selected == "Settings" then
		luis.disableLayer("custom")
        pushMenu("settings")
    elseif selected == "Highscore" then
        print("Showing highscores...")
    elseif selected == "Quit" then
        love.event.quit()
    end
end

function handleSettingsMenuSelection(selected)
    if selected == "Video" then
        pushMenu("video")
    elseif selected == "Audio" then
        pushMenu("audio")
    elseif selected == "Gameplay" then
        pushMenu("gameplay")
    elseif selected == "Controls" then
        pushMenu("controls")
    elseif selected == "Back" then
		-- save last widget state
		local config = luis.getConfig()
		local jsonString = json.encode(config)
		love.filesystem.write('config.json', jsonString)

		luis.enableLayer("custom")
        popMenu()
    end
end

function love.textinput(text)
    luis.textinput(text)
end

function love.mousepressed(x, y, button, istouch)
    luis.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    luis.mousereleased(x, y, button, istouch)
end

function love.wheelmoved(x, y)
    luis.wheelmoved(x, y)
end

-- Because of the keeping the focus ... Keyboard vs Mouse/Touch vs Gamepad do not work good together!
function love.keypressed(key, scancode, isrepeat)
	-- Add virtual gamepad for keyboard support
	if #luis.activeJoysticks == 0 then
		addVirtualKeyboardGamepad()
	end
    if key == "escape" then
        if luis.currentLayer == "main" then
            love.event.quit()
        else
            popMenu()
        end
    elseif key == "tab" then
        luis.showGrid = not luis.showGrid
        luis.showElementOutlines = not luis.showElementOutlines
        luis.showLayerNames = not luis.showLayerNames
	elseif key == "1" then
		-- set current Focus to "Start Game"
		luis.setCurrentFocus(mainMenuElements[1])
	elseif key == "2" then
		-- set current Focus to nil
		luis.setCurrentFocus(nil)
    elseif luis.currentFocus then
		if key == "down" then
			luis.moveFocus("next")
			return
		elseif key == "up" then
			luis.moveFocus("previous")
			return
		elseif key == "return" or key == "a" then
			luis.gamepadpressed(luis.getActiveJoystick(1), key)
			return
		end
	end
	luis.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key)
    if luis.currentFocus then
		if luis.currentFocus then
			if key == "a" then
				luis.gamepadreleased(luis.getActiveJoystick(1), key)
				return
			end
		end
	end

	luis.keyreleased(key, scancode )
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    love.mousepressed(x, y, 1, true)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    love.mousereleased(x, y, 1, true)
end

function love.joystickadded(joystick)
	print('joystickadded', joystick)
	
	-- REMOVE keyboard emulated gamepad
	if luis.getActiveJoystick(1) and luis.getActiveJoystick(1):getName() == "Virtual Gamepad #1" then
		removeVirtualKeyboardGamepad()
	end

    luis.initJoysticks()  -- Reinitialize joysticks when a new one is added
end

function love.joystickremoved(joystick)
	print('joystickremoved', joystick)
	luis.removeJoystick(joystick)
end

function love.gamepadpressed(joystick, button)
	print('love.gamepadpressed', joystick, button)
    luis.gamepadpressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
	print('love.gamepadreleased', joystick, button)
    luis.gamepadreleased(joystick, button)
end
