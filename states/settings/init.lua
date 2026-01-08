-- Settings state main orchestrator
-- Manages window frame and delegates to section modules
local Gamestate = require("lib.hump.gamestate")
local Theme = require("game.theme")
local WindowFrame = require("game.hud.window_frame")
local Rect = require("util.rect")

local DisplaySection = require("states.settings.sections.display")
local AudioSection = require("states.settings.sections.audio")
local ControlsSection = require("states.settings.sections.controls")
local GraphicsSection = require("states.settings.sections.graphics")

local pointInRect = Rect.pointInRect

local SettingsState = {}

function SettingsState:init()
    self.frame = WindowFrame.new()
    self.hover = nil
    self.pressed = nil
    self.bounds = nil

    -- Scroll state
    self.scrollY = 0
    self.contentHeight = 0
    self.viewportHeight = 0

    -- Initialize sections
    self.sections = {
        graphics = GraphicsSection.new(),
        display = DisplaySection.new(),
        audio = AudioSection.new(),
        controls = ControlsSection.new(),
    }

    -- Section order for layout/drawing
    self.sectionOrder = { "graphics", "display", "audio", "controls" }
    self.sectionLabels = {
        graphics = "Graphics",
        display = "Display",
        audio = "Sound",
        controls = "Keybindings",
    }
end

function SettingsState:enter(from)
    self.from = from
    self.hover = nil
    self.pressed = nil
    self.bounds = nil
    self.scrollY = 0

    -- Reinitialize sections to pick up any setting changes
    self.sections = {
        graphics = GraphicsSection.new(),
        display = DisplaySection.new(),
        audio = AudioSection.new(),
        controls = ControlsSection.new(),
    }

    -- Register callback to invalidate layout when resolution changes
    -- (WindowFrame handles proportional repositioning automatically)
    GraphicsSection.setResizeCallback(function()
        self.bounds = nil
    end)
end

function SettingsState:_ctx()
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

function SettingsState:_layout(ctx)
    local screenW, screenH = ctx.screenW, ctx.screenH
    local hudTheme = Theme.hud
    local margin = (hudTheme.layout and hudTheme.layout.margin) or 16
    local pad = 12
    local headerH = 28
    local footerH = 46 -- Footer for Back button

    local winW = math.min(520, math.floor(screenW * 0.65))
    local winH = math.min(650, math.floor(screenH * 0.85))

    local x0 = math.floor((screenW - winW) * 0.5)
    local y0 = math.floor((screenH - winH) * 0.5)

    if self.frame.x == nil or self.frame.y == nil then
        self.frame.x = x0
        self.frame.y = y0
    end

    local bounds = self.frame:compute(ctx, winW, winH, {
        headerH = headerH,
        footerH = footerH,
        closeSize = 18,
        closePad = 6,
        margin = margin,
    })

    bounds.pad = pad

    -- Content body area (between header and footer)
    local bodyY = bounds.y + headerH
    local bodyH = bounds.h - headerH - footerH
    bounds.bodyRect = {
        x = bounds.x + pad,
        y = bodyY,
        w = bounds.w - pad * 2,
        h = bodyH,
    }

    local contentX = bounds.bodyRect.x
    local contentW = bounds.bodyRect.w
    local btnH = 30

    -- Footer buttons: Reset (left) and Apply (right)
    local btnW = 100
    local btnGap = 20
    local totalBtnW = btnW * 2 + btnGap
    local btnStartX = bounds.x + (bounds.w - totalBtnW) / 2

    bounds.btnReset = {
        x = btnStartX,
        y = bounds.y + bounds.h - footerH + (footerH - btnH) / 2,
        w = btnW,
        h = btnH
    }
    bounds.btnApply = {
        x = btnStartX + btnW + btnGap,
        y = bounds.y + bounds.h - footerH + (footerH - btnH) / 2,
        w = btnW,
        h = btnH
    }

    -- Layout sections with scroll offset applied
    bounds.sections = {}
    local cy = bounds.bodyRect.y + 8 - self.scrollY -- Start with small padding, offset by scroll
    local sectionGap = 16

    for _, name in ipairs(self.sectionOrder) do
        local section = self.sections[name]

        bounds.sections[name] = {
            label = { x = contentX, y = cy, w = contentW, h = 20 },
            startY = cy + 24,
        }

        cy = cy + 24
        local sectionHeight = section:layout(contentX, cy, contentW)
        bounds.sections[name].height = sectionHeight
        cy = cy + sectionHeight + sectionGap
    end

    -- Calculate total content height for scrolling
    self.contentHeight = (cy + self.scrollY) - (bounds.bodyRect.y + 8)
    self.viewportHeight = bounds.bodyRect.h

    -- Clamp scroll to valid range
    local maxScroll = math.max(0, self.contentHeight - self.viewportHeight)
    self.scrollY = math.max(0, math.min(self.scrollY, maxScroll))

    self.bounds = bounds
    return bounds
end

function SettingsState:wheelmoved(x, y)
    -- Scroll by 30 pixels per wheel notch
    self.scrollY = self.scrollY - y * 30

    -- Clamp immediately
    local maxScroll = math.max(0, self.contentHeight - self.viewportHeight)
    self.scrollY = math.max(0, math.min(self.scrollY, maxScroll))
end

function SettingsState:keypressed(key)
    -- Let controls section handle keybinds first
    if self.sections.controls:keypressed(key) then
        return
    end

    if key == "escape" then
        Gamestate.pop()
    end
end

function SettingsState:mousepressed(x, y, button)
    -- If controls section is listening for input, let it handle
    if self.sections.controls:isListening() then
        self.sections.controls:mousepressed(x, y, button)
        return true
    end

    local ctx = self:_ctx()
    local b = self:_layout(ctx)

    if not pointInRect(x, y, b) then return false end

    -- Handle window drag/close
    local consumed, didClose = self.frame:mousepressed(ctx, b, x, y, button)
    if didClose then
        Gamestate.pop()
        return true
    end
    if consumed then return true end

    -- Footer buttons (always clickable)
    if pointInRect(x, y, b.btnApply) then
        self.pressed = "Apply"
        return true
    end
    if pointInRect(x, y, b.btnReset) then
        self.pressed = "Reset"
        return true
    end

    -- Only handle section clicks if within body area
    if not pointInRect(x, y, b.bodyRect) then
        return true
    end

    -- Close any open dropdowns if clicking elsewhere
    local clickedDropdown = false

    -- Check sections (reverse order to handle overlays first)
    for i = #self.sectionOrder, 1, -1 do
        local name = self.sectionOrder[i]
        local section = self.sections[name]
        if section:mousepressed(x, y, button) then
            clickedDropdown = section:hasOpenDropdown()
            -- Close other sections' dropdowns
            for _, otherName in ipairs(self.sectionOrder) do
                if otherName ~= name then
                    self.sections[otherName]:closeDropdowns()
                end
            end
            return true
        end
    end

    -- If no section handled, close all dropdowns
    if not clickedDropdown then
        for _, name in ipairs(self.sectionOrder) do
            self.sections[name]:closeDropdowns()
        end
    end

    return true
end

function SettingsState:mousereleased(x, y, button)
    if self.sections.controls:isListening() then return end

    local ctx = self:_ctx()
    local b = self:_layout(ctx)
    self.frame:mousereleased(ctx, x, y, button)

    -- Release sliders
    for _, name in ipairs(self.sectionOrder) do
        self.sections[name]:mousereleased(x, y, button)
    end

    if self.pressed == "Apply" and pointInRect(x, y, b.btnApply) then
        -- Settings are already auto-saved, just close
        Gamestate.pop()
    end
    if self.pressed == "Reset" and pointInRect(x, y, b.btnReset) then
        -- Reset all settings to defaults
        local Settings = require("game.settings")
        Settings.resetToDefaults()
        -- Reinitialize sections to reflect defaults
        self.sections = {
            graphics = GraphicsSection.new(),
            display = DisplaySection.new(),
            audio = AudioSection.new(),
            controls = ControlsSection.new(),
        }
        self.scrollY = 0
    end
    self.pressed = nil
end

function SettingsState:mousemoved(x, y, dx, dy)
    if self.sections.controls:isListening() then return end

    local ctx = self:_ctx()
    local b = self:_layout(ctx)
    self.frame:mousemoved(ctx, x, y, dx, dy)

    self.hover = nil
    if pointInRect(x, y, b.btnApply) then
        self.hover = "Apply"
    end
    if pointInRect(x, y, b.btnReset) then
        self.hover = "Reset"
    end

    -- Update sections
    for _, name in ipairs(self.sectionOrder) do
        self.sections[name]:mousemoved(x, y)
    end
end

function SettingsState:draw()
    if self.from and self.from.draw then
        self.from:draw()
    end

    love.graphics.push("all")

    local ctx = self:_ctx()
    local b = self:_layout(ctx)
    local colors = Theme.hud.colors
    local r = Theme.hud.panelStyle.radius

    -- Dim background
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, ctx.screenW, ctx.screenH)

    -- Window Frame
    self.frame:draw(ctx, b, { title = "SETTINGS", titlePad = b.pad })

    local mx, my = love.mouse.getPosition()

    -- Set scissor to clip content to body area
    love.graphics.setScissor(b.bodyRect.x, b.bodyRect.y, b.bodyRect.w, b.bodyRect.h)

    -- Draw sections (clipped to body)
    for _, name in ipairs(self.sectionOrder) do
        local section = self.sections[name]
        local sb = b.sections[name]

        -- Only draw if visible in viewport
        local sectionBottom = sb.label.y + 24 + (sb.height or 0)
        local sectionTop = sb.label.y

        if sectionBottom >= b.bodyRect.y and sectionTop <= b.bodyRect.y + b.bodyRect.h then
            -- Section label with underline
            love.graphics.setColor(0.6, 0.6, 0.6, 1)
            love.graphics.print(self.sectionLabels[name], sb.label.x, sb.label.y)
            love.graphics.line(sb.label.x, sb.label.y + 18, sb.label.x + sb.label.w, sb.label.y + 18)

            -- Section content
            section:draw()
        end
    end

    -- Draw section overlays within scissor (dropdowns)
    for i = #self.sectionOrder, 1, -1 do
        local name = self.sectionOrder[i]
        self.sections[name]:drawOverlay()
    end

    -- Clear scissor for footer/UI outside body
    love.graphics.setScissor()

    -- Draw scroll indicator if content overflows
    if self.contentHeight > self.viewportHeight then
        local scrollbarH = math.max(20, (self.viewportHeight / self.contentHeight) * self.viewportHeight)
        local maxScroll = self.contentHeight - self.viewportHeight
        local scrollbarY = b.bodyRect.y + (self.scrollY / maxScroll) * (self.viewportHeight - scrollbarH)

        -- Scrollbar track
        love.graphics.setColor(0.2, 0.2, 0.2, 0.5)
        love.graphics.rectangle("fill", b.bodyRect.x + b.bodyRect.w - 6, b.bodyRect.y, 4, b.bodyRect.h, 2)

        -- Scrollbar thumb
        love.graphics.setColor(0.5, 0.5, 0.5, 0.8)
        love.graphics.rectangle("fill", b.bodyRect.x + b.bodyRect.w - 6, scrollbarY, 4, scrollbarH, 2)
    end

    -- Footer buttons (outside scissor)
    local font = love.graphics.getFont()

    -- Reset Button
    local isResetHover = pointInRect(mx, my, b.btnReset)
    love.graphics.setColor(0.8, 0.3, 0.3, isResetHover and 1 or 0.7)
    love.graphics.rectangle("line", b.btnReset.x, b.btnReset.y, b.btnReset.w, b.btnReset.h, r)
    local resetText = "Reset"
    local rw = font:getWidth(resetText)
    love.graphics.setColor(colors.text[1], colors.text[2], colors.text[3], isResetHover and 1 or 0.8)
    love.graphics.print(resetText, b.btnReset.x + (b.btnReset.w - rw) / 2, b.btnReset.y + 6)

    -- Apply Button
    local isApplyHover = pointInRect(mx, my, b.btnApply)
    love.graphics.setColor(0.3, 0.7, 0.4, isApplyHover and 1 or 0.7)
    love.graphics.rectangle("line", b.btnApply.x, b.btnApply.y, b.btnApply.w, b.btnApply.h, r)
    local applyText = "Apply"
    local aw = font:getWidth(applyText)
    love.graphics.setColor(colors.text[1], colors.text[2], colors.text[3], isApplyHover and 1 or 0.8)
    love.graphics.print(applyText, b.btnApply.x + (b.btnApply.w - aw) / 2, b.btnApply.y + 6)

    love.graphics.pop()
end

return SettingsState
