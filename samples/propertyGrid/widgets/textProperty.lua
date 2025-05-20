local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")

local textProperty = {}

local luis
function textProperty.setluis(luisObj)
    luis = luisObj
end

function textProperty.new(propertyName, onChange)
    local editor = {}
    
    -- Note: This property editor doesn't use a FlexContainer
    -- It directly uses a TextInput widget, which doesn't have
    -- dragging or resizing behavior by default
    
    -- Create a text input for editing
    local inputWidth = 10
    editor.container = luis.newTextInput(inputWidth, 1, "", function(value)
        if editor.targetWidget and editor.propertyName then
            editor.targetWidget[editor.propertyName] = value
            if onChange then
                onChange(editor.targetWidget, value)
            end
        end
    end, 1, 1)
    
    -- Ensure TextInput events can be properly handled
    editor.container.active = true  -- Make it active to receive input
    
    -- Extend the TextInput to ensure keyboard events get passed correctly
    local originalClick = editor.container.click
    editor.container.click = function(self, x, y, button, istouch, presses)
        -- When clicked, this TextInput becomes the active one
        self.active = true
        return originalClick(self, x, y, button, istouch, presses)
    end
    
    -- Initialize with property info
    editor.propertyName = propertyName
    editor.targetWidget = nil
    
    -- Method to update the target widget
    editor.setTarget = function(self, widget)
        self.targetWidget = widget
        if widget and self.propertyName and widget[self.propertyName] then
            self.container:setText(tostring(widget[self.propertyName]))
        else
            self.container:setText("")
        end
    end
    
    return editor
end

return textProperty