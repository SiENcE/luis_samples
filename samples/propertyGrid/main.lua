-- Initialize LUIS
local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")

-- register flux in luis, for the default widget animations
luis.flux = require("luis.3rdparty.flux")

-- load predefined themes
local defaultTheme = require("luis.themes.styles.defaultTheme")
defaultTheme.text.font = love.graphics.newFont("luis/themes/fonts/DungeonFont.ttf", 22)
defaultTheme.flexContainer.cornerRadius = 2
defaultTheme.flexContainer.handleSize = 4

local function loadCustomWidgets(luis, customWidgetPath)
    local lfs = love.filesystem

    -- Ensure the custom widget path exists
    if not lfs.getInfo(customWidgetPath, "directory") then
        print("Custom widget directory not found: " .. customWidgetPath)
        return false
    end

    -- Get all widget files from the custom directory
    local widget_files = lfs.getDirectoryItems(customWidgetPath)
    
    -- Load each widget file
    for _, file in ipairs(widget_files) do
        local widget_name = file:match("(.+)%.lua$")
        if widget_name then
            -- Convert path format for require
            local require_path = customWidgetPath:gsub("/", ".") .. "." .. widget_name
            
            -- Require the widget module
            local widget = require(require_path)
            
            -- Pass the core library to the widget
            widget.setluis(luis)
            
            -- Store the widget and create convenience function
            luis.widgets[widget_name] = widget
            luis["new" .. widget_name:gsub("^%l", string.upper)] = widget.new
            
            print("Loaded custom widget: " .. widget_name)
        end
    end
    
    return true
end

loadCustomWidgets(luis, "samples/propertyGrid/widgets")

function love.load()
    -- Create main editor layer
    luis.newLayer("editor")
    luis.enableLayer("editor")
    
    -- Create a button to test property editing
    testButton = luis.createElement("editor", "Button", "Test Button", 10, 3, function() end, nil, 10, 5)
    
    -- Create property grid
    propertyGrid = luis.newPropertyGrid(20, 20, 5, 15)
	propertyGrid.isResizing = false
	propertyGrid.isDragging = false
    
    -- Add property editors
    propertyGrid:addProperty(" Text", luis.newTextProperty("text"))
    propertyGrid:addProperty(" Width", luis.newNumberProperty("width", 10, 100, true))
    propertyGrid:addProperty(" Height", luis.newNumberProperty("height", 10, 50, true))
    propertyGrid:addProperty(" Position X", luis.newNumberProperty("position.x", 0, 800, false, function(self, value) print('x', value) end))
    propertyGrid:addProperty(" Position Y", luis.newNumberProperty("position.y", 0, 600, false, function(self, value) print('y', value) end))
    propertyGrid:addProperty(" Hover", luis.newBooleanProperty("hover", true))
    propertyGrid:addProperty(" Color", luis.newColorProperty("color"))
	propertyGrid:addProperty(" Color", luis.newVector2Property("Vector"))
    
    -- Set the target widget
    propertyGrid:setTarget(testButton)
    
    -- Add property grid to the editor
    luis.createElement("editor", "FlexContainer", propertyGrid)
	
	-- set Theme
	luis.setTheme(defaultTheme)
end

local time = 0
function love.update(dt)
	time = time + dt
	if time >= 1/60 then	
		luis.flux.update(time)
		time = 0
	end
	
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

function love.textinput(text)
    luis.textinput(text)
end

function love.keypressed(key, scancode, isrepeat)
	if key == "tab" then
        luis.showGrid = not luis.showGrid
        luis.showElementOutlines = not luis.showElementOutlines
        luis.showLayerNames = not luis.showLayerNames
		luis.showMetrics = not luis.showMetrics
	end
	luis.keypressed(key, scancode, isrepeat)
end

function love.keyreleased(key)
	luis.keyreleased(key, scancode )
end
