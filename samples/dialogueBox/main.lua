-- LUIS DialogueBox Sample

local initLuis = require("luis.init")
local luis = initLuis()  -- Initialize LUIS

local dialogue = nil
local dialogueIndex = 1
local dialogueState = "start"  -- States: start, fadeIn, active, fadeOut, complete

-- Sample dialogue script
local dialogueScript = {
    {speaker = "Penny", text = "One time I found a really old piece of pottery. It had writing on it that I couldn't read."},
    {speaker = "Player", text = "That sounds interesting! Where did you find it?"},
    {speaker = "Penny", text = "In the mountains, near the old mine entrance. I was looking for interesting rocks for my collection."},
    {speaker = "Player", text = "Did you take it to the museum?"},
    {speaker = "Penny", text = "I did! Gunther said it was around 5,000 years old. Can you imagine?"},
    {speaker = "", text = "A soft breeze rustles through the leaves as you both sit in comfortable silence."}
}

function love.load()
    -- Set window dimensions
    love.window.setMode(800, 600, {resizable = true})
    
    -- Set up LUIS grid size and scaling
    luis.gridSize = 20
    luis.baseWidth = 800
    luis.baseHeight = 600
    
    -- Create a UI layer
    luis.newLayer("ui")
    luis.enableLayer("ui")
    
    -- Create a nice custom theme
    local customTheme = {
        boxColor = {0.92, 0.85, 0.65, 0.95},       -- Slightly transparent beige
        nameBoxColor = {0.92, 0.85, 0.65, 0.95},   -- Same for name box
        textColor = {0.25, 0.20, 0.16, 1},         -- Dark brown text
        borderRadius = 18,                          -- Rounder corners
        shadowColor = {0.1, 0.1, 0.1, 0.6},        -- Darker shadow
        shadowOffset = 5,                           -- Larger shadow
        padding = 20,                               -- More padding
        font = love.graphics.getFont() or love.graphics.newFont(16),
        nameFont = love.graphics.getFont() or love.graphics.newFont(18),
        indicatorColor = {0.2, 0.2, 0.2, 0.8},      -- Indicator triangle color
        textSpeed = 40,                             -- Characters per second
        fadeInDuration = 0.4,                       -- Slower fade-in
        fadeOutDuration = 0.3                       -- Standard fade-out
    }
    
    -- Add to UI layer
    dialogue = luis.createElement("ui", "DialogueBox",
        dialogueScript[dialogueIndex].text,
        dialogueScript[dialogueIndex].speaker,
        30, 6, 20, 5,
        customTheme)
    
    -- Start with fade-in animation only on the first entry
    dialogue:setVisible(true)  -- Make sure it's visible
    dialogue:fadeIn()          -- Start fade-in animation for the first dialogue entry
    dialogueState = "fadeIn"
    
    -- Load a background image
    background = love.graphics.newImage("samples/dialogueBox/background.png")
    
    -- Instruction text
    instructions = "Click the dialogue box or press SPACE to advance\nPress UP/DOWN to change text speed\nPress R to restart dialogue"
end

function love.update(dt)
    -- Update LUIS (which will update our dialogue box)
    luis.updateScale()  -- Handle window resizing
    luis.update(dt)
    
    -- Track dialogue animation state
    if dialogueState == "fadeIn" and dialogue.opacity >= 1 then
        -- Initial fade-in complete, dialogue is now active
        dialogueState = "active"
    elseif dialogueState == "fadeOut" and dialogue.opacity <= 0 then
        -- Final fade-out complete, dialogue is now done
        dialogueState = "complete"
    end
end

function love.draw()
    -- Draw background
    if background then
        love.graphics.draw(background, 0, 0, 0, 
            love.graphics.getWidth() / background:getWidth(), 
            love.graphics.getHeight() / background:getHeight())
    else
        -- Fallback background if image doesn't exist
        love.graphics.setColor(0.2, 0.4, 0.6)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end
    
    -- Draw LUIS elements
    luis.draw()
    
    -- Draw instructions
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.printf(instructions, 20, 20, love.graphics.getWidth() - 40, "left")
    
    -- Display text speed and animation state
    love.graphics.printf("Text Speed: " .. dialogue.theme.textSpeed, 20, 80, love.graphics.getWidth() - 40, "left")
    love.graphics.printf("Dialogue State: " .. dialogueState, 20, 100, love.graphics.getWidth() - 40, "left")
    love.graphics.printf("Dialogue: " .. dialogueIndex .. "/" .. #dialogueScript, 20, 120, love.graphics.getWidth() - 40, "left")
    love.graphics.printf("Opacity: " .. string.format("%.2f", dialogue.opacity), 20, 140, love.graphics.getWidth() - 40, "left")
end

-- Function to advance to next dialogue entry
function advanceDialogue()
    if dialogueState ~= "active" then
        return  -- Don't advance if not in active state
    end
    
    if dialogue.isComplete then
        -- Check if this is the last dialogue entry
        if dialogueIndex < #dialogueScript then
            -- Not the last entry, just update text without fading
            dialogueIndex = dialogueIndex + 1
            dialogue:setText(dialogueScript[dialogueIndex].text, dialogueScript[dialogueIndex].speaker)
        else
            -- This was the last entry, start the final fade out
            dialogue:fadeOut()
            dialogueState = "fadeOut"
        end
    else
        -- Text is still animating, just show it all immediately
        dialogue:showFullText()
    end
end

-- Function to restart the dialogue from the beginning
function restartDialogue()
    dialogueIndex = 1
    dialogue:setText(dialogueScript[dialogueIndex].text, dialogueScript[dialogueIndex].speaker)
    dialogue:setVisible(true)
    dialogue:fadeIn()
    dialogueState = "fadeIn"
end

function love.keypressed(key)
    -- Handle key presses (forward to LUIS)
    luis.keypressed(key)
    
    if key == "space" then
        advanceDialogue()
    elseif key == "up" then
        -- Increase text speed
        dialogue:setTextSpeed(dialogue.theme.textSpeed + 10)
    elseif key == "down" then
        -- Decrease text speed (minimum 10)
        dialogue:setTextSpeed(math.max(10, dialogue.theme.textSpeed - 10))
    elseif key == "r" then
        -- Restart dialogue
        restartDialogue()
    elseif key == "tab" then
        luis.showGrid = not luis.showGrid
        luis.showElementOutlines = not luis.showElementOutlines
        luis.showLayerNames = not luis.showLayerNames
		luis.showMetrics = not luis.showMetrics
    end
end

function love.keyreleased(key)
    luis.keyreleased(key)
end

function love.textinput(text)
    luis.textinput(text)
end

function love.mousepressed(x, y, button)
	if not dialogue.isComplete then
        advanceDialogue()
	else
		-- Pass to LUIS first
		local handled = luis.mousepressed(x, y, button)
    
		-- If LUIS handled it and it was our dialogue being clicked
		if handled then
			advanceDialogue()
		end
	end
end

function love.mousereleased(x, y, button)
    luis.mousereleased(x, y, button)
end

function love.wheelmoved(x, y)
    luis.wheelmoved(x, y)
end

-- Gamepad support
function love.joystickadded(joystick)
    luis.initJoysticks()
end

function love.joystickremoved(joystick)
    luis.removeJoystick(joystick)
end

function love.gamepadpressed(joystick, button)
	if not dialogue.isComplete then
        advanceDialogue()
	else
		luis.gamepadpressed(joystick, button)
		
		-- Also handle dialogue advancement with gamepad
		if button == "a" or button == "b" then
			advanceDialogue()
		end
	end
end

function love.gamepadreleased(joystick, button)
    luis.gamepadreleased(joystick, button)
end

-- Window resize handling (LUIS handles scaling)
function love.resize(w, h)
    luis.updateScale()
end
