local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")

local colorProperty = {}

local luis
function colorProperty.setluis(luisObj)
    luis = luisObj
end

function colorProperty.new(propertyName, onChange)
    local editor = {}
    
    -- Create a color picker and a container
    editor.container = luis.newFlexContainer(10, 1, 1, 1, nil, "Color Editor")
    
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
    
    -- Add a color preview button that opens the picker
    editor.previewButton = luis.newButton("", 2, 1, function()
        editor.showPicker = not editor.showPicker
        editor.updateVisibility()
    end, nil, 1, 1)
    
    editor.container:addChild(editor.previewButton)
    
    -- Create a color picker (it will be shown/hidden as needed)
    editor.colorPicker = luis.newColorPicker(8, 8, 3, 2, function(color)
        if editor.targetWidget and editor.propertyName then
            editor.targetWidget[editor.propertyName] = color
            -- Update preview button color
            editor.updatePreviewColor(color)
            if onChange then
                onChange(editor.targetWidget, color)
            end
        end
    end)
    
    -- Default to hidden
    editor.showPicker = false
    
    -- Initialize with property info
    editor.propertyName = propertyName
    editor.targetWidget = nil
    
    -- Method to update visibility of color picker
    editor.updateVisibility = function()
        if editor.showPicker then
            editor.container:addChild(editor.colorPicker)
        else
            editor.container:removeChild(editor.colorPicker)
        end
    end
    
    -- Method to update preview button color
    editor.updatePreviewColor = function(color)
        editor.previewButton.colorR = color[1]
        editor.previewButton.colorG = color[2]
        editor.previewButton.colorB = color[3]
        editor.previewButton.colorA = color[4] or 1
    end
    
    -- Method to update the target widget
    editor.setTarget = function(self, widget)
        self.targetWidget = widget
        if widget and self.propertyName and widget[self.propertyName] then
            local color = widget[self.propertyName]
            self.updatePreviewColor(color)
        else
            self.updatePreviewColor({0.5, 0.5, 0.5, 1})
        end
    end
    
    return editor
end

return colorProperty