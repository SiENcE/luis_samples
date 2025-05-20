local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")

local booleanProperty = {}

local luis
function booleanProperty.setluis(luisObj)
    luis = luisObj
end

function booleanProperty.new(propertyName, useSwitch, onChange)
    local editor = {}
    
    -- Note: This property editor doesn't use a FlexContainer
    -- It directly uses a Switch or CheckBox widget, which don't have
    -- dragging or resizing behavior by default
    
    if useSwitch then
        -- Use a switch control
        editor.container = luis.newSwitch(false, 3, 1, function(value)
            if editor.targetWidget and editor.propertyName then
                editor.targetWidget[editor.propertyName] = value
                if onChange then
                    onChange(editor.targetWidget, value)
                end
            end
        end, 1, 1)
    else
        -- Use a checkbox control
        editor.container = luis.newCheckBox(false, 1, function(value)
            if editor.targetWidget and editor.propertyName then
                editor.targetWidget[editor.propertyName] = value
                if onChange then
                    onChange(editor.targetWidget, value)
                end
            end
        end, 1, 1)
    end
    
    -- Initialize with property info
    editor.propertyName = propertyName
    editor.targetWidget = nil
    
    -- Method to update the target widget
    editor.setTarget = function(self, widget)
        self.targetWidget = widget
        if widget and self.propertyName and widget[self.propertyName] ~= nil then
            local value = widget[self.propertyName]
            self.container:setValue(value)
        else
            self.container:setValue(false)
        end
    end
    
    return editor
end

return booleanProperty