local utils = require("luis.3rdparty.utils")
local Vector2D = require("luis.3rdparty.vector")
local decorators = require("luis.3rdparty.decorators")

local propertyGrid = {}

local luis
function propertyGrid.setluis(luisObj)
    luis = luisObj
end

function propertyGrid.new(width, height, row, col, customTheme)
    local propertyGridTheme = customTheme or luis.theme.flexContainer
    
    -- Create a container for our properties
    local container = luis.newFlexContainer(width, height, row, col, propertyGridTheme, "Property Grid")
    -- Add styling specific to property grid
    container.backgroundColor = propertyGridTheme.backgroundColor or {0.2, 0.2, 0.2, 0.8}
    
    -- Add collapsed state properties
    container.isCollapsed = false
    container.originalHeight = height
    container.headerHeight = 1  -- Height of the header in grid units
    container.lastClickTime = 0
    container.doubleClickDelay = 0.5  -- Increased from 0.3 to 0.5 seconds for more flexibility
    container.headerElement = nil
    
    -- Preserve the original click handler but extend it to handle double-clicks on header
    local originalClick = container.click
    container.click = function(self, x, y, button, istouch, presses)
        -- Check for double-click on header
        local currentTime = love.timer.getTime()
        local isDoubleClick = (currentTime - self.lastClickTime) < self.doubleClickDelay
        self.lastClickTime = currentTime
        
        -- Check if click is on the header
        local isHeaderClick = false
        if self.headerElement then
            local headerY = self.headerElement.position.y
            local headerHeight = self.headerElement.height
            -- Make full width of the property grid clickable for the header
            isHeaderClick = (y >= headerY and y <= headerY + headerHeight) and 
                           (x >= self.position.x and x <= self.position.x + self.width)
        end
        
        -- Handle double-click on header to toggle collapse
        if isDoubleClick and isHeaderClick and button == 1 then
            self:toggleCollapse()
            return true
        end
        
        -- If not a double-click on header, use original behavior to allow drag/resize
        return originalClick(self, x, y, button, istouch, presses)
    end
    
    -- Override the isInResizeHandle method to prevent resizing when collapsed
    local originalIsInResizeHandle = container.isInResizeHandle
    container.isInResizeHandle = function(self, x, y)
        if self.isCollapsed then
            return false  -- Prevent resizing when collapsed
        end
        return originalIsInResizeHandle(self, x, y)
    end
    
    -- Extend the container with property grid functionality
    container.properties = {}
    container.targetWidget = nil
    
    -- Add method to toggle collapse state
    container.toggleCollapse = function(self)
        if self.isCollapsed then
            -- Expand
            self:expand()
        else
            -- Collapse
            self:collapse()
        end
    end
    
    -- Method to collapse the property grid
    container.collapse = function(self)
        if self.isCollapsed then return end
        
        self.isCollapsed = true
        self.originalHeight = self.height
        
        -- Hide all children except the header and header background
        for i, child in ipairs(self.children) do
            if i > 1 then  -- Skip the header
                child.visible = false
            end
        end
        
        -- Resize to just show the header
        local headerHeight = self.headerHeight * luis.gridSize
        self.height = headerHeight + propertyGridTheme.padding * 2
        
        -- Update header text to indicate collapsed state
        if self.headerElement and self.headerElement.value then
            self.collapsedHeaderText = self.headerElement.value
            self.headerElement.value = "▶ " .. self.headerElement.value:gsub("^▼ ", "")
        end
    end
    
    -- Method to expand the property grid
    container.expand = function(self)
        if not self.isCollapsed then return end
        
        self.isCollapsed = false
        
        -- Show all children
        for i, child in ipairs(self.children) do
            child.visible = true
        end
        
        -- Restore original height
        self.height = self.originalHeight
        
        -- Update header text to indicate expanded state
        if self.headerElement and self.headerElement.value then
            self.headerElement.value = "▼ " .. self.headerElement.value:gsub("^▶ ", "")
        end
        
        -- Re-arrange children
        self:arrangeChildren()
    end
    
    -- Add method to set the target widget
    container.setTarget = function(self, widget)
        self.targetWidget = widget
        self:refreshProperties()
    end
    
    -- Add method for adding properties
    container.addProperty = function(self, name, propertyEditor)
        table.insert(self.properties, {
            name = name,
            editor = propertyEditor
        })
        
        -- If we already have a target, update the property editor
        if self.targetWidget then
            propertyEditor:setTarget(self.targetWidget)
        end
        
        -- Add to container's children
        self:addChild(propertyEditor.container)
    end
    
    -- Method to refresh all properties
    container.refreshProperties = function(self)
        -- Clear existing children
        while #self.children > 0 do
            self:removeChild(self.children[1])
        end
        
        if not self.targetWidget then return end
        
        -- Create a header label with collapse/expand indicator
        local headerPrefix = self.isCollapsed and "▶ " or "▼ "
        local header = luis.newLabel(headerPrefix .. "Properties: " .. (self.targetWidget.type or "Unknown"), width-1, 1, 1, 1)
        
        -- Add the header text
        self:addChild(header)
        self.headerElement = header
        
        -- Add each property editor
        for _, prop in ipairs(self.properties) do
            -- Create a row container for this property
            local row = luis.newFlexContainer(width-1, 2, 1, 1, nil, "Property Row")
            
            -- Set visibility based on collapsed state
            row.visible = not self.isCollapsed
            
            -- Disable dragging and resizing for property rows
            local rowOriginalClick = row.click
            row.click = function(rowSelf, x, y, button, istouch, presses)
                -- Only handle clicks on children, not for dragging or resizing
                if rowSelf:isInContainer(x, y) then
                    for _, child in ipairs(rowSelf.children) do
                        if child.click and child:click(x, y, button, istouch, presses) then
                            return true
                        end
                    end
                    -- Return true to indicate the click was handled, but don't start dragging
                    return true
                end
                return false
            end
            
            -- Add label for property name
            local nameLabel = luis.newLabel(prop.name .. ":", math.floor(width/3)-1, 1, 1, 1)
            row:addChild(nameLabel)
            
            -- Update property editor with current widget
            prop.editor:setTarget(self.targetWidget)
            
            -- Add the editor component
            row:addChild(prop.editor.container)
            
            -- Add the row to the main container
            self:addChild(row)
        end
        
        -- If collapsed, adjust height to show only header
        if self.isCollapsed then
            self.originalHeight = height * luis.gridSize
            local headerHeight = self.headerHeight * luis.gridSize
            self.height = headerHeight + propertyGridTheme.padding * 2
        end
        
        -- Re-arrange everything
        self:arrangeChildren()
    end
    
    -- Add keyboard event handling to forward keypressed events to active text input widgets
    container.keypressed = function(self, key, scancode, isrepeat)
        -- First check if we have any TextInput widgets that are active
        for _, child in ipairs(self.children) do
            -- If it's a FlexContainer (row), check its children
            if child.type == "FlexContainer" and child.children then
                for _, grandChild in ipairs(child.children) do
                    if grandChild.type == "TextInput" and grandChild.active and grandChild.keypressed then
                        return grandChild:keypressed(key, scancode, isrepeat)
                    end
                end
            -- Otherwise check if it's a TextInput directly
            elseif child.type == "TextInput" and child.active and child.keypressed then
                return child:keypressed(key, scancode, isrepeat)
            end
        end
        return false
    end
    
    -- Forward textinput events as well
    container.textinput = function(self, text)
        -- Check for active TextInput widgets
        for _, child in ipairs(self.children) do
            -- If it's a FlexContainer (row), check its children
            if child.type == "FlexContainer" and child.children then
                for _, grandChild in ipairs(child.children) do
                    if grandChild.type == "TextInput" and grandChild.active and grandChild.textinput then
                        return grandChild:textinput(text)
                    end
                end
            -- Otherwise check if it's a TextInput directly
            elseif child.type == "TextInput" and child.active and child.textinput then
                return child:textinput(text)
            end
        end
        return false
    end
    
    -- Forward keyreleased events
    container.keyreleased = function(self, key, scancode)
        -- Check for active TextInput widgets
        for _, child in ipairs(self.children) do
            -- If it's a FlexContainer (row), check its children
            if child.type == "FlexContainer" and child.children then
                for _, grandChild in ipairs(child.children) do
                    if grandChild.type == "TextInput" and grandChild.active and grandChild.keyreleased then
                        return grandChild:keyreleased(key, scancode)
                    end
                end
            -- Otherwise check if it's a TextInput directly
            elseif child.type == "TextInput" and child.active and child.keyreleased then
                return child:keyreleased(key, scancode)
            end
        end
        return false
    end
    
    -- We should still modify any nested property editors that use FlexContainers
    -- to prevent them from being draggable/resizable
    local originalAddProperty = container.addProperty
    container.addProperty = function(self, name, propertyEditor)
        -- If the property editor has a container that is a FlexContainer, disable dragging/resizing
        if propertyEditor.container and propertyEditor.container.type == "FlexContainer" then
            local editorContainer = propertyEditor.container
            local editorOriginalClick = editorContainer.click
            editorContainer.click = function(editorSelf, x, y, button, istouch, presses)
                -- Only handle clicks on children, not for dragging or resizing
                if editorSelf:isInContainer(x, y) then
                    for _, child in ipairs(editorSelf.children) do
                        if child.click and child:click(x, y, button, istouch, presses) then
                            return true
                        end
                    end
                    -- Return true to indicate the click was handled, but don't start dragging
                    return true
                end
                return false
            end
        end
        
        -- Call the original method
        return originalAddProperty(self, name, propertyEditor)
    end
    
    return container
end

return propertyGrid
