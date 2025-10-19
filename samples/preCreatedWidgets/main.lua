-- LUIS Pre-created Widget Sample
-- Demonstrates using pre-created widget objects with createElement()

local initLuis = require("luis.init")
-- Direct this to your widgets folder.
local luis = initLuis("luis/widgets")

-- register flux in luis, because the widgets of complex_ui need this
luis.flux = require("luis.3rdparty.flux")

local materialTheme = require("luis.themes.styles.materialTheme")

function love.load()
    luis.setTheme(materialTheme)
 
    -- Create main menu layer
    luis.newLayer("mainMenu")
    luis.enableLayer("mainMenu")
    
    -- Example 1: Pre-create a button with decorator
    local startButton = luis.newButton("Start Game", 20, 4, 
        function() print("Starting game...") end,
        function() print("Start button released") end,
        5, 10)
    
    -- Add decorator before adding to layer
    startButton:setDecorator("GlowDecorator", {0, 1, 0, 0.8}, 12)
    
    -- Add to layer
    luis.createElement("mainMenu", "Button", startButton)
    
    
    -- Example 2: Build a FlexContainer with children
    local settingsContainer = luis.newFlexContainer(26, 18, 10, 5)
    
    -- Create title
    local title = luis.newLabel("Settings", 24, 2, 1, 1)
    
    -- Create volume slider
    local volumeSlider = luis.newSlider(0, 100, 75, 25, 3, 
        function(value) print("Volume:", value) end, 
        1, 1)
    
    -- Create toggle switches
    local fullscreenSwitch = luis.newSwitch(true, 15, 3,
        function(value) print("Fullscreen:", value) end,
        1, 1)
    
    local musicSwitch = luis.newSwitch(true, 15, 3,
        function(value) print("Music:", value) end,
        1, 1)
    
    -- Create close button
    local closeButton = luis.newButton("Close", 15, 3,
        function() settingsContainer:hide() end,
        nil, 1, 1)
    
    -- Add all children to container
    settingsContainer:addChild(title)
    settingsContainer:addChild(volumeSlider)
    settingsContainer:addChild(fullscreenSwitch)
    settingsContainer:addChild(musicSwitch)
    settingsContainer:addChild(closeButton)
    
    -- Style the container
    settingsContainer:setDecorator("GlassmorphismDecorator", 
        {1, 1, 1, 0.5}, 15)
    
    -- Initially hidden
    settingsContainer:hide()
    
    -- Add container to layer
    luis.createElement("mainMenu", "FlexContainer", settingsContainer)
    
    
    -- Example 3: Settings button to show container
    local settingsButton = luis.newButton("Settings", 20, 4,
        function() settingsContainer:show() end,
        nil, 12, 10)
    
    settingsButton:setDecorator("GlowDecorator", {0.3, 0.5, 1, 0.8}, 12)
    luis.createElement("mainMenu", "Button", settingsButton)
    
    
    -- Example 4: Conditional widget creation
    local debugMode = true
    
    if debugMode then
        local debugLabel = luis.newLabel("DEBUG MODE", 14, 2, 1, 1)
        -- Customize before adding
        debugLabel.color = {1, 0, 0, 1}
        luis.createElement("mainMenu", "Label", debugLabel)
    end
end

function love.update(dt)
    luis.update(dt)
end

function love.draw()
    luis.draw()
end

function love.mousepressed(x, y, button, istouch)
    luis.mousepressed(x, y, button, istouch)
end

function love.mousereleased(x, y, button, istouch)
    luis.mousereleased(x, y, button, istouch)
end

function love.keypressed(key)
    if key == "tab" then
        luis.showGrid = not luis.showGrid
        luis.showElementOutlines = not luis.showElementOutlines
    end
    luis.keypressed(key)
end