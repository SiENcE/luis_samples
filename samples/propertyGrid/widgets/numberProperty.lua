local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")
local utf8 = require("utf8")

local numberProperty = {}

local luis
function numberProperty.setluis(luisObj)
    luis = luisObj
end

function numberProperty.new(propertyName, min, max, useSlider, onChange)
    local editor = {}
    min = min or 0
    max = max or 100
    
    -- Helper function to set property on target widget
    local function setProperty(widget, propName, value)
        if not widget or not propName then return end
        
        -- Handle nested properties (like "position.x")
        if propName:find("%.") then
            local parts = {}
            for part in propName:gmatch("([^.]+)") do
                table.insert(parts, part)
            end
            
            if #parts == 2 then
                -- Handle simple nested property (e.g., "position.x")
                local obj = widget[parts[1]]
                if obj then
                    obj[parts[2]] = value
                end
            end
        else
            -- Direct property access
            widget[propName] = value
        end
    end
    
    -- Helper function to get property from target widget
    local function getProperty(widget, propName)
        if not widget or not propName then return nil end
        
        -- Handle nested properties
        if propName:find("%.") then
            local parts = {}
            for part in propName:gmatch("([^.]+)") do
                table.insert(parts, part)
            end
            
            if #parts == 2 and widget[parts[1]] then
                return widget[parts[1]][parts[2]]
            end
            return nil
        else
            return widget[propName]
        end
    end
    
    if useSlider then
        -- Use a slider for the input
        editor.container = luis.newSlider(min, max, 0, 8, 1, function(value)
            if editor.targetWidget then
                setProperty(editor.targetWidget, editor.propertyName, value)
                if onChange then
                    onChange(editor.targetWidget, value)
                end
            end
        end, 1, 1)
    else
        -- Key change: Use TextInput DIRECTLY as the container (no FlexContainer)
        editor.container = luis.newTextInput(8, 1, "", function(text)
            local numValue = tonumber(text)
            if numValue then
                numValue = math.max(min, math.min(max, numValue))
                if editor.targetWidget then
                    setProperty(editor.targetWidget, editor.propertyName, numValue)
                    if onChange then
                        onChange(editor.targetWidget, numValue)
                    end
                end
            end
        end, 1, 1)
        
        -- Extend the TextInput to handle numeric validation
        local originalTextInput = editor.container.textinput
        editor.container.textinput = function(self, text)
            -- Only allow numbers, decimal point, and minus sign
            if text:match("^[0-9%.%-]$") then
                -- If we already have a decimal point, don't allow another
                if text == "." and self.value:find("%.") then
                    return
                end
                -- If we already have a minus sign or it's not at the beginning, don't allow it
                if text == "-" and (self.value:find("%-") or self.cursorPos > 0) then
                    return
                end
                
                return originalTextInput(self, text)
            end
        end
        
        -- Override the key processing to validate after changes
        local originalKeypressed = editor.container.keypressed
        editor.container.keypressed = function(self, key, scancode, isrepeat)
            if key == "return" or key == "kpenter" then
                -- Validate on enter
                local numValue = tonumber(self.value)
                if numValue then
                    numValue = math.max(min, math.min(max, numValue))
                    self:setText(tostring(numValue))
                    
                    if editor.targetWidget then
                        setProperty(editor.targetWidget, editor.propertyName, numValue)
                        if onChange then
                            onChange(editor.targetWidget, numValue)
                        end
                    end
                else
                    -- Reset to previous valid value or 0
                    local oldValue = editor.targetWidget and getProperty(editor.targetWidget, editor.propertyName) or 0
                    self:setText(tostring(oldValue))
                end
            end
            
            return originalKeypressed(self, key, scancode, isrepeat)
        end
    end
    
    -- Initialize with property info
    editor.propertyName = propertyName
    editor.targetWidget = nil
    
    -- Method to update the target widget
    editor.setTarget = function(self, widget)
        self.targetWidget = widget
        if widget then
            local value = getProperty(widget, self.propertyName)
            
            if value ~= nil then
                if useSlider then
                    self.container.value = value
                    self.container:setValue(value)
                else
                    self.container:setText(tostring(value))
                end
            else
                if useSlider then
                    self.container.value = min
                    self.container:setValue(min)
                else
                    self.container:setText("")
                end
            end
        else
            if useSlider then
                self.container.value = min
                self.container:setValue(min)
            else
                self.container:setText("")
            end
        end
    end
    
    return editor
end

return numberProperty
