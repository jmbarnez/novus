local Gamestate = require("lib.hump.gamestate")
local Theme = require("game.theme")
local WindowFrame = require("game.hud.window_frame")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local Death = {}

function Death:init()
    self.selection = 1
    self.items = { "Respawn", "Quit" }
    self.frame = WindowFrame.new()
    self.hover = nil
    self.pressed = nil
    self.bounds = nil
end

function Death:enter(from)
    self.from = from
    self.selection = 1
    self.hover = nil
    self.pressed = nil
    self.bounds = nil

    self.prevMouseVisible = love.mouse.isVisible()
    love.mouse.setVisible(true)
end

function Death:leave()
    if self.prevMouseVisible ~= nil then
        love.mouse.setVisible(self.prevMouseVisible)
    end
end

function Death:_ctx()
    local screenW, screenH = love.graphics.getDimensions()
    return {
        theme = Theme,
        screenW = screenW,
        screenH = screenH,
        layout = {
            margin = (Theme.hud and Theme.hud.layout and Theme.hud.layout.margin) or 16,
        },
    }
end

function Death:_layout(ctx)
    local screenW, screenH = ctx.screenW, ctx.screenH
    local hudTheme = Theme.hud
    local margin = (hudTheme.layout and hudTheme.layout.margin) or 16
    local pad = 10
    local headerH = 28
    local footerH = 0

    local winW = math.min(280, math.max(220, math.floor(screenW * 0.30)))
    local winH = 150

    local x0 = math.floor((screenW - winW) * 0.5)
    local y0 = math.floor((screenH - winH) * 0.40)

    if self.frame.x == nil or self.frame.y == nil then
        self.frame.x = math.max(margin, x0)
        self.frame.y = math.max(margin, y0)
    end

    local bounds = self.frame:compute(ctx, winW, winH, {
        headerH = headerH,
        footerH = footerH,
        closeSize = 0, -- No close button for death screen
        closePad = 0,
        margin = margin,
    })

    bounds.pad = pad
    local btnH = 30
    local btnW = math.min(200, bounds.w - pad * 2)
    local btnX = bounds.x + math.floor((bounds.w - btnW) * 0.5)

    -- Two buttons stacked vertically
    local btnY0 = bounds.y + bounds.h - pad - (btnH * 2 + 10)

    bounds.btnRespawn = { x = btnX, y = btnY0, w = btnW, h = btnH }
    bounds.btnQuit = { x = btnX, y = btnY0 + btnH + 10, w = btnW, h = btnH }

    self.bounds = bounds
    return bounds
end

function Death:_activate(item)
    if item == "Respawn" then
        if self.from and self.from.respawn then
            self.from:respawn()
        end
        Gamestate.pop()
    elseif item == "Quit" then
        love.event.quit()
    end
end

function Death:keypressed(key)
    -- No escape to close death screen - must choose an option
    if key == "up" then
        self.selection = self.selection - 1
        if self.selection < 1 then
            self.selection = #self.items
        end
    elseif key == "down" then
        self.selection = self.selection + 1
        if self.selection > #self.items then
            self.selection = 1
        end
    elseif key == "return" or key == "kpenter" or key == "space" then
        self:_activate(self.items[self.selection])
    end
end

function Death:mousemoved(x, y, dx, dy)
    local ctx = self:_ctx()
    local b = self:_layout(ctx)

    if self.frame:mousemoved(ctx, x, y, dx, dy) then
        self.hover = nil
        return true
    end

    if pointInRect(x, y, b.btnRespawn) then
        self.hover = "Respawn"
        self.selection = 1
        return true
    end
    if pointInRect(x, y, b.btnQuit) then
        self.hover = "Quit"
        self.selection = 2
        return true
    end

    self.hover = nil
    return pointInRect(x, y, b)
end

function Death:mousepressed(x, y, button)
    local ctx = self:_ctx()
    local b = self:_layout(ctx)

    if not pointInRect(x, y, b) then
        return false
    end

    local consumed, didClose, didDrag = self.frame:mousepressed(ctx, b, x, y, button)
    if didDrag then
        return true
    end

    if button ~= 1 then
        return true
    end

    if pointInRect(x, y, b.btnRespawn) then
        self.pressed = "Respawn"
        return true
    end
    if pointInRect(x, y, b.btnQuit) then
        self.pressed = "Quit"
        return true
    end

    return true
end

function Death:mousereleased(x, y, button)
    local ctx = self:_ctx()
    local b = self:_layout(ctx)

    if self.frame:mousereleased(ctx, x, y, button) then
        return true
    end

    if button ~= 1 then
        self.pressed = nil
        return false
    end

    local pressed = self.pressed
    self.pressed = nil

    if pressed == "Respawn" and pointInRect(x, y, b.btnRespawn) then
        self:_activate("Respawn")
        return true
    end
    if pressed == "Quit" and pointInRect(x, y, b.btnQuit) then
        self:_activate("Quit")
        return true
    end

    return pointInRect(x, y, b)
end

function Death:draw()
    -- Draw the underlying game state (frozen)
    if self.from and self.from.draw then
        self.from:draw()
    end

    love.graphics.push("all")

    local ctx = self:_ctx()
    local b = self:_layout(ctx)
    local hudTheme = Theme.hud
    local colors = hudTheme.colors
    local ps = hudTheme.panelStyle or {}
    local r = ps.radius or 0

    -- Dark overlay matching theme
    love.graphics.setColor(0, 0, 0, 0.75)
    love.graphics.rectangle("fill", 0, 0, ctx.screenW, ctx.screenH)

    -- Draw window frame with death title
    self.frame:draw(ctx, b, { title = "YOU DIED", titlePad = b.pad })

    local font = love.graphics.getFont()
    local mx, my = love.mouse.getPosition()

    local function drawButton(rect, label, isSelected)
        local isHover = pointInRect(mx, my, rect)
        local isPressed = (self.pressed == label)
        local alpha = isSelected and 0.55 or 0.35
        if isHover then
            alpha = 0.60
        end
        if isPressed then
            alpha = 0.70
        end

        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.rectangle("fill", rect.x, rect.y, rect.w, rect.h, r, r)
        love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3],
            isHover and 0.55 or 0.35)
        love.graphics.rectangle("line", rect.x, rect.y, rect.w, rect.h, r, r)

        local lw = font:getWidth(label)
        local lh = font:getHeight()
        local lx = rect.x + math.floor((rect.w - lw) * 0.5)
        local ly = rect.y + math.floor((rect.h - lh) * 0.5)
        love.graphics.setColor(colors.textShadow[1], colors.textShadow[2], colors.textShadow[3], 0.75)
        love.graphics.print(label, lx + 1, ly + 1)
        love.graphics.setColor(colors.text[1], colors.text[2], colors.text[3], 0.9)
        love.graphics.print(label, lx, ly)
    end

    drawButton(b.btnRespawn, "Respawn", self.selection == 1)
    drawButton(b.btnQuit, "Quit", self.selection == 2)

    love.graphics.pop()
end

return Death
