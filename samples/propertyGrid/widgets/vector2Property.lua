local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")

local vector2Property = {}

local luis
function vector2Property.setluis(luisObj)
    luis = luisObj
end

function vector2Property.new(propertyName, onChange)
    local editor = {}
    
    -- Create a container with two number inputs
    editor.container = luis.newFlexContainer(10, 1, 1, 1, nil, "Vector2 Editor")
    
    -- Disable dragging and resizing
    local originalClick = editor.container.click
    editor.container.click = function(self, x, y, button, istouch, presses)
        -- Only handle clicks on children, not for dragging or resizing
        if self:isInContainer(x, y) then
            for _, child in ipairs(self.children) do
                if child.click and child:click(x, y, button, istouch, presses) then
                    return true
                end
            end
            -- Return true to indicate the click was handled, but don't start dragging
            return true
        end
        return false
    end
    
    -- Create X input
    editor.xInput = luis.newTextInput(4, 1, "", function(value)
        local numValue = tonumber(value)
        if numValue and editor.targetWidget and editor.propertyName then
            editor.targetWidget[editor.propertyName].x = numValue
            if onChange then
                onChange(editor.targetWidget, editor.targetWidget[editor.propertyName])
            end
        end
    end, 1, 1)
    
    -- Create Y input
    editor.yInput = luis.newTextInput(4, 1, "", function(value)
        local numValue = tonumber(value)
        if numValue and editor.targetWidget and editor.propertyName then
            editor.targetWidget[editor.propertyName].y = numValue
            if onChange then
                onChange(editor.targetWidget, editor.targetWidget[editor.propertyName])
            end
        end
    end, 1, 1)
    
    -- Create X/Y labels
    local xLabel = luis.newLabel(" x:", 1, 1, 1, 1)
    local yLabel = luis.newLabel(" y:", 1, 1, 1, 5)
    
    -- Add all components to container
    editor.container:addChild(xLabel)
    editor.container:addChild(editor.xInput)
    editor.container:addChild(yLabel)
    editor.container:addChild(editor.yInput)
    
    -- Initialize with property info
    editor.propertyName = propertyName
    editor.targetWidget = nil
    
    -- Method to update the target widget
    editor.setTarget = function(self, widget)
        self.targetWidget = widget
        if widget and self.propertyName and widget[self.propertyName] then
            local vector = widget[self.propertyName]
            self.xInput:setText(tostring(vector.x))
            self.yInput:setText(tostring(vector.y))
        else
            self.xInput:setText("")
            self.yInput:setText("")
        end
    end
    
    return editor
end

return vector2Property