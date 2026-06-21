-----------------------------------------------------------------------------
-- LUIS UI Editor
-----------------------------------------------------------------------------
-- A visual layout editor for LUIS that supports every widget type, nested
-- FlexContainers, and safe JSON save / load.
--
--   Widgets dropdown ... pick a widget, then click the canvas to place it
--   Left drag .......... move a widget (drop onto a container to nest, drag out to un-nest)
--   Right drag ......... resize a widget
--   Enter .............. mark/enter the FlexContainer under the cursor: add / move /
--                        resize / delete then operate on THAT container's children
--   Backspace .......... step back out to the parent container (or the canvas)
--   Delete ............. remove the selected widget
--   File dropdown ...... New / Load / Save
--   Mode button ........ toggle Edit / Use (Use lets widgets react to input)
--   Tab ................ toggle grid / outlines / layer names
--   Escape ............. return to the sample launcher
-----------------------------------------------------------------------------

local initLuis = require("luis.init")
local luis = initLuis("luis/widgets")
luis.flux = require("luis.3rdparty.flux")
local json = require("luis.3rdparty.json")
local utils = require("luis.3rdparty.utils")
local pointInRect = utils.pointInRect

local alternativeTheme = require("luis.themes.styles.alternativeTheme")
alternativeTheme.text.font = love.graphics.newFont("luis/themes/fonts/Monocraft.ttf", 18)

local LAYOUT_FILE  = "layout.json"
local DEFAULT_ICON = "samples/complex_ui/assets/images/icon.png"
local UI_LAYER     = "editor_ui"
local CANVAS_LAYER = "canvas"

local editor = {
    mode = "edit",          -- "edit" or "use"
    selectedType = nil,     -- widget type chosen for placement
    placing = false,
    moving = nil,
    resizing = nil,
    selected = nil,         -- currently selected widget (for delete / highlight)
    activeContainer = nil,  -- marked container: edit operations target its children (nil = canvas)
    dragDX = 0, dragDY = 0, -- grab offset while moving
    widgets = {},           -- top-level widgets on CANVAS_LAYER (children live inside containers)
    gridSize = 20,
    status = "", statusTimer = 0, statusColor = {0.8, 1, 0.8},
}

local function noop() end

local function setStatus(msg, color)
    editor.status = msg
    editor.statusTimer = 5
    editor.statusColor = color or {0.8, 1, 0.8}
    print("[editor] " .. msg)
end

--===========================================================================
-- Widget registry: one entry per type with a default size, a constructor
-- (builds the raw widget from a property table) and a serializer. Keeping
-- create/serialize side by side makes save and load symmetric and complete.
--===========================================================================

-- p carries grid-unit geometry (p.w, p.h, p.row, p.col) plus saved properties.
local WidgetSpec = {
    FlexContainer = {
        w = 12, h = 8,
        create = function(p) return luis.newFlexContainer(p.w, p.h, p.row, p.col, nil, p.name or "FlexContainer") end,
        serialize = function(w) return { name = w.name } end,  -- children handled by serializeWidget
    },
    Button = {
        w = 6, h = 2,
        create = function(p) return luis.newButton(p.text or "Button", p.w, p.h, noop, noop, p.row, p.col) end,
        serialize = function(w) return { text = w.text } end,
    },
    Label = {
        w = 6, h = 2,
        create = function(p) return luis.newLabel(p.text or "Label", p.w, p.h, p.row, p.col, p.align or "left") end,
        serialize = function(w) return { text = w.value, align = w.align } end,
    },
    Icon = {
        w = 2, h = 2,  -- icons are square (sized by width)
        create = function(p) return luis.newIcon(p.iconPath or DEFAULT_ICON, p.w, p.row, p.col) end,
        serialize = function(w) return { iconPath = w.iconPath } end,
    },
    Slider = {
        w = 6, h = 2,
        create = function(p) return luis.newSlider(p.min or 0, p.max or 100, p.value or 50, p.w, p.h, noop, p.row, p.col) end,
        serialize = function(w) return { min = w.min, max = w.max, value = w.value } end,
    },
    Switch = {
        w = 4, h = 2,
        create = function(p) return luis.newSwitch(p.value or false, p.w, p.h, noop, p.row, p.col) end,
        serialize = function(w) return { value = w.value } end,
    },
    CheckBox = {
        w = 2, h = 2,  -- square (sized by width)
        create = function(p) return luis.newCheckBox(p.value or false, p.w, noop, p.row, p.col) end,
        serialize = function(w) return { value = w.value } end,
    },
    RadioButton = {
        w = 2, h = 2,  -- square (sized by width)
        create = function(p) return luis.newRadioButton(p.group or "group1", p.value or false, p.w, noop, p.row, p.col) end,
        serialize = function(w) return { group = w.group, value = w.value } end,
    },
    DropDown = {
        w = 8, h = 2,
        create = function(p)
            return luis.newDropDown(p.items or {"Option 1", "Option 2", "Option 3"}, p.value or 1,
                p.w, p.h, noop, p.row, p.col, p.maxVisibleItems or 3, nil, p.title)
        end,
        serialize = function(w) return { items = w.items, value = w.value, title = w.title, maxVisibleItems = w.maxVisibleItems } end,
    },
    TextInput = {
        w = 8, h = 2,
        create = function(p) return luis.newTextInput(p.w, p.h, p.placeholder or "Input text", noop, p.row, p.col) end,
        restore = function(w, p) if p.text and p.text ~= "" then w:setText(p.text) end end,
        serialize = function(w) return { placeholder = w.placeholder, text = w.value } end,
    },
    TextInputMultiLine = {
        w = 8, h = 4,
        create = function(p) return luis.newTextInputMultiLine(p.w, p.h, p.placeholder or "Input multiline text", noop, p.row, p.col) end,
        restore = function(w, p) if p.text and p.text ~= "" then w:setText(p.text) end end,
        serialize = function(w) return { placeholder = w.placeholder, text = w:getText() } end,
    },
    ProgressBar = {
        w = 6, h = 1,
        create = function(p) return luis.newProgressBar(p.value or 0.75, p.w, p.h, p.row, p.col) end,
        serialize = function(w) return { value = w.value } end,
    },
    ColorPicker = {
        w = 10, h = 3,
        create = function(p) return luis.newColorPicker(p.w, p.h, p.row, p.col, noop) end,
        restore = function(w, p)
            if p.hue then
                w.hue, w.saturation, w.value = p.hue, p.saturation or 1, p.value or 1
                w:updateColor()
            end
        end,
        serialize = function(w) return { hue = w.hue, saturation = w.saturation, value = w.value } end,
    },
}

-- Palette order (also the Widgets dropdown order)
local PALETTE = {
    "FlexContainer", "Button", "Label", "Icon", "Slider", "Switch", "CheckBox",
    "RadioButton", "DropDown", "TextInput", "TextInputMultiLine", "ProgressBar", "ColorPicker",
}

--===========================================================================
-- Edit/Use interaction toggling
--===========================================================================

-- In edit mode the placed widgets must not react to clicks (so the editor can
-- move/resize them). Swap out both click and release (recursing into children).
local function setInteractive(widget, enabled)
    if enabled then
        if widget._click   ~= nil then widget.click   = widget._click;   widget._click   = nil end
        if widget._release ~= nil then widget.release = widget._release; widget._release = nil end
    else
        if widget.click   and widget._click   == nil then widget._click   = widget.click;   widget.click   = function() return false end end
        if widget.release and widget._release == nil then widget._release = widget.release; widget.release = function() return false end end
    end
    if widget.children then
        for _, child in ipairs(widget.children) do setInteractive(child, enabled) end
    end
end

local function applyMode()
    local interactive = (editor.mode == "use")
    for _, w in ipairs(editor.widgets) do setInteractive(w, interactive) end
end

--===========================================================================
-- (De)serialization
--===========================================================================

local function serializeWidget(widget)
    local spec = WidgetSpec[widget.type]
    if not spec then return nil end
    local entry = {
        type  = widget.type,
        col   = widget.position.x / luis.gridSize + 1,
        row   = widget.position.y / luis.gridSize + 1,
        w     = widget.width  / luis.gridSize,
        h     = widget.height / luis.gridSize,
        props = spec.serialize(widget) or {},
    }
    if widget.type == "FlexContainer" then
        entry.props.children = {}
        for _, child in ipairs(widget.children) do
            local childEntry = serializeWidget(child)
            if childEntry then table.insert(entry.props.children, childEntry) end
        end
    end
    return entry
end

-- Build a raw widget (not added to any layer) from a serialized entry.
-- Children of FlexContainers are created recursively and parented here.
local function instantiate(entry)
    if type(entry) ~= "table" or type(entry.type) ~= "string" then return nil end
    local spec = WidgetSpec[entry.type]
    if not spec then
        setStatus("Skipped unknown widget type: " .. tostring(entry.type), {1, 0.7, 0.3})
        return nil
    end

    local props = type(entry.props) == "table" and entry.props or {}
    local p = {
        w   = tonumber(entry.w)   or spec.w,
        h   = tonumber(entry.h)   or spec.h,
        row = tonumber(entry.row) or 1,
        col = tonumber(entry.col) or 1,
    }
    for k, v in pairs(props) do p[k] = v end

    local ok, widget = pcall(spec.create, p)
    if not ok or not widget then
        setStatus("Failed to create " .. entry.type, {1, 0.5, 0.5})
        return nil
    end
    if spec.restore then pcall(spec.restore, widget, p) end

    if entry.type == "FlexContainer" and type(props.children) == "table" then
        for _, childEntry in ipairs(props.children) do
            local child = instantiate(childEntry)
            if child then widget:addChild(child) end
        end
    end
    return widget
end

--===========================================================================
-- Canvas widget management
--===========================================================================

local function addTopLevel(widget)
    luis.createElement(CANVAS_LAYER, widget.type, widget)
    table.insert(editor.widgets, widget)
    setInteractive(widget, editor.mode == "use")
end

local function detachTopLevel(widget)
    for i, w in ipairs(editor.widgets) do
        if w == widget then table.remove(editor.widgets, i) break end
    end
    luis.removeElement(CANVAS_LAYER, widget)
end

local function clearCanvas()
    for i = #editor.widgets, 1, -1 do
        luis.removeElement(CANVAS_LAYER, editor.widgets[i])
    end
    editor.widgets = {}
    editor.selected, editor.moving, editor.resizing = nil, nil, nil
    editor.activeContainer = nil
end

-- The widget list the editor currently operates on: a marked container's children,
-- or the top-level canvas widgets when no container is active.
local function currentList()
    if editor.activeContainer then return editor.activeContainer.children end
    return editor.widgets
end

-- Find the parent FlexContainer of a widget (searches nested), or nil if top-level.
local function findParent(target, list)
    for _, w in ipairs(list or editor.widgets) do
        if w.children then
            for _, c in ipairs(w.children) do
                if c == target then return w end
            end
            local deeper = findParent(target, w.children)
            if deeper then return deeper end
        end
    end
    return nil
end

local function deleteWidget(widget)
    if not widget then return end
    local parent = findParent(widget)
    if parent then
        parent:removeChild(widget)
    else
        detachTopLevel(widget)
    end
    if editor.selected  == widget then editor.selected  = nil end
    if editor.moving    == widget then editor.moving    = nil end
    if editor.resizing  == widget then editor.resizing  = nil end
    setStatus("Deleted " .. widget.type, {1, 0.8, 0.6})
end

-- Topmost widget under a point, within the active context (container children or canvas).
local function pickWidget(mx, my)
    local list = currentList()
    for i = #list, 1, -1 do
        local w = list[i]
        if pointInRect(mx, my, w.position.x, w.position.y, w.width, w.height) then
            return w
        end
    end
    return nil
end

-- Topmost FlexContainer under a point in the active context, excluding `exclude`.
local function pickContainer(mx, my, exclude)
    local list = currentList()
    for i = #list, 1, -1 do
        local w = list[i]
        if w ~= exclude and w.type == "FlexContainer" and w:isInContainer(mx, my) then
            return w
        end
    end
    return nil
end

-- Is `node` somewhere inside `ancestor`'s subtree? (used to prevent nesting cycles)
local function isDescendant(node, ancestor)
    if not ancestor.children then return false end
    for _, c in ipairs(ancestor.children) do
        if c == node or isDescendant(node, c) then return true end
    end
    return false
end

-- Deepest FlexContainer under a point across the whole tree, excluding `exclude`.
local function findContainerAt(mx, my, exclude, list)
    list = list or editor.widgets
    local found = nil
    for _, c in ipairs(list) do
        if c.type == "FlexContainer" and c ~= exclude and c:isInContainer(mx, my) then
            found = findContainerAt(mx, my, exclude, c.children) or c
        end
    end
    return found
end

-- Breadcrumb path of the active container, e.g. "canvas > Panel > Row".
local function contextPath()
    if not editor.activeContainer then return "canvas (top level)" end
    local names, c = {}, editor.activeContainer
    while c do table.insert(names, 1, c.name); c = findParent(c) end
    return "canvas > " .. table.concat(names, " > ")
end

--===========================================================================
-- Save / Load
--===========================================================================

local function saveLayout()
    local layout = { version = 1, gridSize = luis.gridSize, widgets = {} }
    for _, w in ipairs(editor.widgets) do
        local entry = serializeWidget(w)
        if entry then table.insert(layout.widgets, entry) end
    end

    local ok, encoded = pcall(json.encode, layout)
    if not ok then
        setStatus("Save failed (encode error)", {1, 0.5, 0.5})
        return
    end
    local success, message = love.filesystem.write(LAYOUT_FILE, encoded)
    if success then
        setStatus("Saved " .. #layout.widgets .. " widget(s) -> " .. LAYOUT_FILE, {0.8, 1, 0.8})
    else
        setStatus("Save failed: " .. tostring(message), {1, 0.5, 0.5})
    end
end

local function loadLayout()
    if not love.filesystem.getInfo(LAYOUT_FILE) then
        setStatus("No layout file found (" .. LAYOUT_FILE .. ")", {1, 0.7, 0.3})
        return
    end
    local content = love.filesystem.read(LAYOUT_FILE)
    if not content then
        setStatus("Could not read " .. LAYOUT_FILE, {1, 0.5, 0.5})
        return
    end
    local ok, layout = pcall(json.decode, content)
    if not ok or type(layout) ~= "table" or type(layout.widgets) ~= "table" then
        setStatus("Invalid / corrupt layout file", {1, 0.5, 0.5})
        return
    end

    clearCanvas()
    local count = 0
    for _, entry in ipairs(layout.widgets) do
        local widget = instantiate(entry)
        if widget then
            addTopLevel(widget)
            count = count + 1
        end
    end
    setStatus("Loaded " .. count .. " widget(s) from " .. LAYOUT_FILE, {0.8, 1, 0.8})
end

--===========================================================================
-- Placement
--===========================================================================

local function placeWidget(mx, my)
    local spec = WidgetSpec[editor.selectedType]
    if spec then
        local entry = {
            type = editor.selectedType,
            col  = math.floor(mx / editor.gridSize) + 1,
            row  = math.floor(my / editor.gridSize) + 1,
            w = spec.w, h = spec.h, props = {},
        }
        local widget = instantiate(entry)
        if widget then
            if editor.activeContainer then
                editor.activeContainer:addChild(widget)
                setInteractive(widget, editor.mode == "use")
                setStatus("Placed " .. widget.type .. " in " .. editor.activeContainer.name, {0.8, 1, 0.8})
            else
                addTopLevel(widget)
                setStatus("Placed " .. widget.type, {0.8, 1, 0.8})
            end
            editor.selected = widget
        end
    end
    editor.placing = false
    editor.selectedType = nil
end

--===========================================================================
-- LÖVE callbacks
--===========================================================================

function love.load()
    -- Stable save directory so Save/Load always target the same place.
    love.filesystem.setIdentity("luis_editor")

    luis.baseWidth, luis.baseHeight = 1280, 1024
    love.window.setMode(luis.baseWidth, luis.baseHeight, { resizable = true })
    love.graphics.setDefaultFilter("nearest", "nearest")

    luis.setGridSize(editor.gridSize)
    luis.setTheme(alternativeTheme)

    luis.newLayer(CANVAS_LAYER)
    luis.enableLayer(CANVAS_LAYER)
    luis.newLayer(UI_LAYER)
    luis.enableLayer(UI_LAYER)

    -- File menu
    local fileMenu = {"New", "Load Layout", "Save Layout", "Exit"}
    luis.createElement(UI_LAYER, "DropDown", fileMenu, 1, 8, 2,
        function(item)
            if item == "New" then clearCanvas(); setStatus("New layout", {0.8, 1, 0.8})
            elseif item == "Load Layout" then loadLayout()
            elseif item == "Save Layout" then saveLayout()
            elseif item == "Exit" then love.event.quit("restart") end
        end, 1, 1, 4, nil, "File")

    -- Widgets palette
    luis.createElement(UI_LAYER, "DropDown", PALETTE, 1, 8, 2,
        function(item)
            if editor.mode == "edit" then
                editor.selectedType = item
                editor.placing = true
                setStatus("Click the canvas to place a " .. item, {0.8, 0.9, 1})
            else
                setStatus("Switch to Edit mode to place widgets", {1, 0.7, 0.3})
            end
        end, 1, 9, #PALETTE, nil, "Widgets")

    -- Mode toggle
    luis.createElement(UI_LAYER, "Button", "Mode: Edit", 8, 2,
        function(this)
            editor.mode = (editor.mode == "edit") and "use" or "edit"
            this.text = "Mode: " .. (editor.mode == "edit" and "Edit" or "Use")
            applyMode()
            editor.placing, editor.moving, editor.resizing, editor.selectedType = false, nil, nil, nil
        end, noop, 1, 17)

    setStatus("Save dir: " .. love.filesystem.getSaveDirectory(), {0.7, 0.7, 0.7})
end

local accumulator = 0
function love.update(dt)
    accumulator = accumulator + dt
    if accumulator >= 1/60 then
        luis.flux.update(accumulator)
        accumulator = 0
    end
    luis.updateScale()
    luis.update(dt)

    if editor.statusTimer > 0 then editor.statusTimer = editor.statusTimer - dt end
    if editor.mode ~= "edit" then return end

    local mx, my = love.mouse.getPosition()
    mx, my = mx / luis.scale, my / luis.scale

    if editor.moving then
        local nx = math.floor((mx - editor.dragDX) / luis.gridSize) * luis.gridSize
        local ny = math.floor((my - editor.dragDY) / luis.gridSize) * luis.gridSize
        editor.moving.position.x = math.max(0, nx)
        editor.moving.position.y = math.max(0, ny)
        if editor.moving.type == "FlexContainer" then editor.moving:arrangeChildren() end
    elseif editor.resizing then
        local w = editor.resizing
        local newW = math.max(luis.gridSize, math.floor((mx - w.position.x) / luis.gridSize) * luis.gridSize)
        local newH = math.max(luis.gridSize, math.floor((my - w.position.y) / luis.gridSize) * luis.gridSize)
        if w.type == "FlexContainer" then
            w:resize(newW, newH)
        else
            w.width, w.height = newW, newH
        end
    end
end

local function drawOutlines(list)
    for _, w in ipairs(list) do
        love.graphics.rectangle("line",
            w.position.x * luis.scale, w.position.y * luis.scale,
            w.width * luis.scale, w.height * luis.scale)
        if w.children then drawOutlines(w.children) end
    end
end

function love.draw()
    luis.draw()

    if editor.mode == "edit" then
        -- Outlines for all placed widgets (and their children)
        love.graphics.setColor(1, 1, 0, 0.4)
        drawOutlines(editor.widgets)

        -- Highlight the active (marked) container in magenta so it's clear edits go inside it
        if editor.activeContainer then
            local c = editor.activeContainer
            love.graphics.setColor(1, 0.2, 1, 0.9)
            love.graphics.setLineWidth(2)
            love.graphics.rectangle("line",
                c.position.x * luis.scale - 3, c.position.y * luis.scale - 3,
                c.width * luis.scale + 6, c.height * luis.scale + 6)
            love.graphics.setLineWidth(1)
        end

        -- Highlight the selected / moving / resizing widget
        local hot = editor.moving or editor.resizing or editor.selected
        if hot then
            love.graphics.setColor(0, 1, 1, 0.8)
            love.graphics.rectangle("line",
                hot.position.x * luis.scale, hot.position.y * luis.scale,
                hot.width * luis.scale, hot.height * luis.scale)
        end

        -- Placement preview
        if editor.placing and editor.selectedType then
            local spec = WidgetSpec[editor.selectedType]
            local mx, my = love.mouse.getPosition()
            local gx = math.floor(mx / luis.scale / editor.gridSize) * editor.gridSize * luis.scale
            local gy = math.floor(my / luis.scale / editor.gridSize) * editor.gridSize * luis.scale
            love.graphics.setColor(0, 1, 0, 0.35)
            love.graphics.rectangle("fill", gx, gy,
                spec.w * editor.gridSize * luis.scale, spec.h * editor.gridSize * luis.scale)
        end
    end

    -- HUD: mode + context + status + help
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", 0, love.graphics.getHeight() - 70, love.graphics.getWidth(), 70)
    love.graphics.setColor(editor.mode == "edit" and {1, 1, 0.6} or {0.6, 1, 0.6})
    love.graphics.print("Mode: " .. editor.mode .. "   |   Editing: " .. contextPath(), 10, love.graphics.getHeight() - 66)
    love.graphics.setColor(0.75, 0.75, 0.8)
    love.graphics.print("L-drag move (drop on a container to nest, drag out to un-nest)   |   R-drag resize   |   Del delete   |   Enter: edit inside container   |   Backspace: step out", 10, love.graphics.getHeight() - 44)
    if editor.statusTimer > 0 then
        love.graphics.setColor(editor.statusColor)
        love.graphics.print(editor.status, 10, love.graphics.getHeight() - 22)
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    -- Raw coords: luis divides by luis.scale internally.
    if luis.mousepressed(x, y, button, istouch, presses) then return end
    if editor.mode ~= "edit" then return end

    local mx, my = x / luis.scale, y / luis.scale

    if editor.placing and editor.selectedType and button == 1 then
        placeWidget(mx, my)
        return
    end

    local hit = pickWidget(mx, my)
    editor.selected = hit
    if hit then
        if button == 1 then
            editor.moving = hit
            editor.dragDX = mx - hit.position.x
            editor.dragDY = my - hit.position.y
        elseif button == 2 then
            editor.resizing = hit
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    luis.mousereleased(x, y, button, istouch, presses)
    if editor.mode ~= "edit" then return end

    if button == 1 and editor.moving then
        local w = editor.moving
        local mx, my = x / luis.scale, y / luis.scale
        local parent = findParent(w)

        -- Deepest container under the cursor (whole tree), never w or w's own subtree.
        local target = findContainerAt(mx, my, w)
        if target and isDescendant(target, w) then target = nil end

        local function detach()
            if parent then parent:removeChild(w) else detachTopLevel(w) end
        end

        if target and target ~= parent then
            -- Re-parent into a (possibly nested) container.
            detach()
            target:addChild(w)
            setInteractive(w, editor.mode == "use")
            setStatus(w.type .. " moved into " .. target.name, {0.8, 0.9, 1})
        elseif parent and not parent:isInContainer(mx, my) then
            -- Dragged out of its container -> promote to the top-level canvas.
            detach()
            addTopLevel(w)
            w.position.x = math.max(0, math.floor(mx / luis.gridSize) * luis.gridSize)
            w.position.y = math.max(0, math.floor(my / luis.gridSize) * luis.gridSize)
            setStatus(w.type .. " moved to canvas", {0.8, 0.9, 1})
        end
        editor.moving = nil
    elseif button == 2 then
        editor.resizing = nil
    end
end

function love.wheelmoved(x, y)
    luis.wheelmoved(x, y)
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" then
        love.event.quit("restart")  -- return to the sample launcher
    elseif key == "delete" and editor.mode == "edit" then
        deleteWidget(editor.selected)
    elseif (key == "return" or key == "kpenter") and editor.mode == "edit" then
        -- Mark/enter the FlexContainer under the cursor so edits target its children.
        local mx, my = love.mouse.getPosition()
        mx, my = mx / luis.scale, my / luis.scale
        local c = pickContainer(mx, my, nil)
        if c then
            editor.activeContainer = c
            editor.selected = nil
            setStatus("Editing inside: " .. contextPath(), {0.8, 0.9, 1})
        else
            setStatus("Hover a FlexContainer and press Enter to edit inside it", {1, 0.7, 0.3})
        end
    elseif key == "backspace" and editor.mode == "edit" then
        -- Step out to the parent container (or the canvas).
        if editor.activeContainer then
            editor.activeContainer = findParent(editor.activeContainer)
            editor.selected = nil
            setStatus("Editing inside: " .. contextPath(), {0.8, 0.9, 1})
        end
    elseif key == "tab" then
        luis.showGrid = not luis.showGrid
        luis.showElementOutlines = not luis.showElementOutlines
        luis.showLayerNames = not luis.showLayerNames
    else
        luis.keypressed(key, scancode, isrepeat)
    end
end

function love.keyreleased(key, scancode)
    luis.keyreleased(key, scancode)
end

function love.textinput(text)
    luis.textinput(text)
end
