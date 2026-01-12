--- Space input handler module
--- Routes input events to appropriate handlers
local Gamestate = require("lib.hump.gamestate")
local MathUtil = require("util.math")
local Settings = require("game.settings")

local SpaceInput = {}

--- Get interpolated ship position for smooth camera targeting
local function getInterpolatedTarget(ship, alpha)
    local shipBody = ship and ship.physics_body and ship.physics_body.body
    if not shipBody then
        return nil, nil
    end

    local x, y = shipBody:getPosition()
    local pb = ship.physics_body
    if pb and pb.prevX ~= nil and pb.prevY ~= nil and alpha ~= nil and alpha ~= 1 then
        x = MathUtil.lerp(pb.prevX, x, alpha)
        y = MathUtil.lerp(pb.prevY, y, alpha)
    end

    return x, y
end

--- Handle keyboard input
---@param state table Space state object
---@param key string Key pressed
---@param Pause table Pause state module
---@param Space table Space state module (for restart)
function SpaceInput.keypressed(state, key, Pause, Space)
    local uiCapture = state.ecsWorld and state.ecsWorld:getResource("ui_capture")
    if uiCapture and uiCapture.active then
        if state.hudSystem then
            state.hudSystem:keypressed(key)
        end
        return
    end

    if key == "escape" then
        Gamestate.push(Pause)
    elseif key == "f1" and state.profiler then
        state.profiler:setEnabled(not state.profiler.enabled)
    elseif key == "f2" then
        local getVsync = love.window and love.window.getVSync
        local setVsync = love.window and love.window.setVSync
        if setVsync then
            local cur = (getVsync and getVsync()) or 0
            setVsync(cur == 0 and 1 or 0)
        end
    elseif key == "f11" then
        local isFullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not isFullscreen)
    elseif state.hudSystem and state.hudSystem:keypressed(key) then
        return
    elseif key == "b" then
        state.showBackground = not state.showBackground
    elseif Settings.isKeyForControl("zoom_in", key) then
        if state.camera then
            state.camera:zoomIn()
        end
    elseif Settings.isKeyForControl("zoom_out", key) then
        if state.camera then
            state.camera:zoomOut()
        end
    elseif key == "r" then
        Gamestate.switch(Space, state.worldSeed)
    end
end

--- Handle text input
---@param state table Space state object
---@param text string Text entered
function SpaceInput.textinput(state, text)
    local uiCapture = state.ecsWorld and state.ecsWorld:getResource("ui_capture")
    if uiCapture and uiCapture.active then
        if state.hudSystem then
            state.hudSystem:textinput(text)
        end
        return
    end

    if state.hudSystem and state.hudSystem:textinput(text) then
        return
    end
end

--- Handle mouse wheel
---@param state table Space state object
---@param x number Horizontal wheel movement
---@param y number Vertical wheel movement
function SpaceInput.wheelmoved(state, x, y)
    if y == 0 then
        return
    end

    local uiCapture = state.ecsWorld and state.ecsWorld:getResource("ui_capture")
    if uiCapture and uiCapture.active then
        if state.hudSystem then
            state.hudSystem:wheelmoved(x, y)
        end
        return
    end

    if state.hudSystem and state.hudSystem:wheelmoved(x, y) then
        return
    end

    if not state.camera then
        return
    end

    if y > 0 then
        state.camera:zoomIn()
    else
        state.camera:zoomOut()
    end
end

--- Handle mouse press
---@param state table Space state object
---@param x number Screen X
---@param y number Screen Y
---@param button number Mouse button
function SpaceInput.mousepressed(state, x, y, button)
    if not state.camera or not state.ecsWorld then
        return
    end

    local uiCapture = state.ecsWorld:getResource("ui_capture")
    if uiCapture and uiCapture.active then
        if state.hudSystem then
            state.hudSystem:mousepressed(x, y, button)
        end
        return
    end

    if state.hudSystem and state.hudSystem:mousepressed(x, y, button) then
        return
    end

    if button ~= 1 then
        return
    end

    local screenW, screenH = love.graphics.getDimensions()

    local pilotedShip = state.ship
    local player = state.ecsWorld:getResource("player")
    if player and player.pilot and player.pilot.ship then
        pilotedShip = player.pilot.ship
    end

    local alpha = state.ecsWorld and state.ecsWorld.getResource and state.ecsWorld:getResource("render_alpha")
    if alpha == nil then
        alpha = 1
    end
    alpha = MathUtil.clamp(alpha, 0, 1)

    local targetX, targetY = getInterpolatedTarget(pilotedShip, alpha)

    local view = state.camera:getView(screenW, screenH, targetX, targetY, state.view)
    local worldX = (x / view.zoom) + view.camX
    local worldY = (y / view.zoom) + view.camY

    state.ecsWorld:emit("onTargetClick", worldX, worldY, button)
end

--- Handle mouse release
---@param state table Space state object
---@param x number Screen X
---@param y number Screen Y
---@param button number Mouse button
function SpaceInput.mousereleased(state, x, y, button)
    if state.hudSystem then
        state.hudSystem:mousereleased(x, y, button)
    end
end

--- Handle mouse movement
---@param state table Space state object
---@param x number Screen X
---@param y number Screen Y
---@param dx number Delta X
---@param dy number Delta Y
function SpaceInput.mousemoved(state, x, y, dx, dy)
    if state.hudSystem then
        state.hudSystem:mousemoved(x, y, dx, dy)
    end
end

return SpaceInput
