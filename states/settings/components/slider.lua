-- Reusable slider component for settings
local Theme = require("game.theme")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local Slider = {}
Slider.__index = Slider

function Slider.new(config)
    local self = setmetatable({}, Slider)
    self.min = config.min or 0
    self.max = config.max or 1
    self.value = config.value or self.min
    self.step = config.step                     -- optional snap step
    self.onChange = config.onChange             -- callback(value)
    self.format = config.format or "%.0f%%"     -- display format
    self.displayMultiplier = config.displayMultiplier or 100  -- for percentage display
    self.isDragging = false
    self.isHovered = false
    return self
end

function Slider:getValue()
    return self.value
end

function Slider:setValue(v)
    self.value = math.max(self.min, math.min(self.max, v))
    if self.step then
        self.value = math.floor(self.value / self.step + 0.5) * self.step
    end
end

function Slider:getNormalized()
    return (self.value - self.min) / (self.max - self.min)
end

function Slider:setFromNormalized(n)
    n = math.max(0, math.min(1, n))
    local newValue = self.min + n * (self.max - self.min)
    if self.step then
        newValue = math.floor(newValue / self.step + 0.5) * self.step
    end
    self.value = math.max(self.min, math.min(self.max, newValue))
end

function Slider:layout(x, y, w, h)
    return {
        track = { x = x, y = y, w = w, h = h }
    }
end

function Slider:mousepressed(x, y, bounds)
    if pointInRect(x, y, bounds.track) then
        self.isDragging = true
        local pct = (x - bounds.track.x) / bounds.track.w
        self:setFromNormalized(pct)
        if self.onChange then
            self.onChange(self.value)
        end
        return true
    end
    return false
end

function Slider:mousereleased()
    self.isDragging = false
end

function Slider:mousemoved(x, y, bounds)
    self.isHovered = pointInRect(x, y, bounds.track)
    
    if self.isDragging then
        local pct = (x - bounds.track.x) / bounds.track.w
        self:setFromNormalized(pct)
        if self.onChange then
            self.onChange(self.value)
        end
        return true
    end
    return self.isHovered
end

function Slider:draw(bounds)
    local colors = Theme.hud.colors
    local font = love.graphics.getFont()
    local track = bounds.track
    local normalized = self:getNormalized()
    local thumbX = track.x + normalized * track.w
    local isActive = self.isHovered or self.isDragging
    
    -- Track background
    love.graphics.setColor(0.12, 0.12, 0.12, 1)
    love.graphics.rectangle("fill", track.x, track.y, track.w, track.h, 3)
    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], 0.5)
    love.graphics.rectangle("line", track.x, track.y, track.w, track.h, 3)
    
    -- Fill
    love.graphics.setColor(0.3, 0.6, 1, 0.6)
    love.graphics.rectangle("fill", track.x, track.y, track.w * normalized, track.h, 3)
    
    -- Thumb
    love.graphics.setColor(1, 1, 1, isActive and 1 or 0.8)
    love.graphics.rectangle("fill", thumbX - 6, track.y - 3, 12, track.h + 6, 3)
    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], isActive and 0.9 or 0.5)
    love.graphics.rectangle("line", thumbX - 6, track.y - 3, 12, track.h + 6, 3)
    
    -- Value text
    local displayVal = self.value * self.displayMultiplier
    local text = string.format(self.format, displayVal)
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(text, track.x + track.w + 8, track.y + (track.h - font:getHeight()) / 2)
end

return Slider
