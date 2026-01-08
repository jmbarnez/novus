-- Reusable dropdown component for settings
local Theme = require("game.theme")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local Dropdown = {}
Dropdown.__index = Dropdown

function Dropdown.new(config)
    local self = setmetatable({}, Dropdown)
    self.options = config.options or {} -- { { label = "...", value = ... }, ... }
    self.selectedIndex = config.selectedIndex or 1
    self.onChange = config.onChange     -- callback(value, index)
    self.isOpen = false
    self.hoverIndex = nil
    return self
end

function Dropdown:getSelectedValue()
    local opt = self.options[self.selectedIndex]
    return opt and opt.value
end

function Dropdown:getSelectedLabel()
    local opt = self.options[self.selectedIndex]
    return opt and opt.label or "---"
end

function Dropdown:setSelectedByValue(value)
    for i, opt in ipairs(self.options) do
        if opt.value == value then
            self.selectedIndex = i
            return true
        end
    end
    return false
end

-- Returns bounds for the dropdown button and options panel
function Dropdown:layout(x, y, w, h)
    local optionH = h
    local bounds = {
        button = { x = x, y = y, w = w, h = h },
        options = {},
        panel = nil,
    }

    for i = 1, #self.options do
        bounds.options[i] = {
            x = x,
            y = y + h + (i - 1) * optionH,
            w = w,
            h = optionH
        }
    end

    bounds.panel = {
        x = x,
        y = y + h,
        w = w,
        h = #self.options * optionH
    }

    return bounds
end

function Dropdown:mousepressed(x, y, bounds)
    if self.isOpen then
        for i, optRect in ipairs(bounds.options) do
            if pointInRect(x, y, optRect) then
                self.selectedIndex = i
                self.isOpen = false
                if self.onChange then
                    self.onChange(self.options[i].value, i)
                end
                return true
            end
        end
        -- Clicked outside, close
        self.isOpen = false
        return true
    else
        if pointInRect(x, y, bounds.button) then
            self.isOpen = true
            return true
        end
    end
    return false
end

function Dropdown:mousemoved(x, y, bounds)
    self.hoverIndex = nil
    if self.isOpen then
        for i, optRect in ipairs(bounds.options) do
            if pointInRect(x, y, optRect) then
                self.hoverIndex = i
                return true
            end
        end
    end
    return pointInRect(x, y, bounds.button)
end

function Dropdown:draw(bounds)
    local colors = Theme.hud.colors
    local font = love.graphics.getFont()
    local btn = bounds.button

    -- Button background
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4)

    -- Button border
    local isHover = self.hoverIndex == nil and self.isOpen == false
    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3],
        (isHover or self.isOpen) and 0.8 or 0.4)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 4)

    -- Button text
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print(self:getSelectedLabel(), btn.x + 8, btn.y + (btn.h - font:getHeight()) / 2)

    -- Arrow indicator
    local arrowX = btn.x + btn.w - 16
    local arrowY = btn.y + btn.h / 2
    love.graphics.setColor(1, 1, 1, 0.7)
    if self.isOpen then
        love.graphics.polygon("fill", arrowX - 4, arrowY + 2, arrowX + 4, arrowY + 2, arrowX, arrowY - 4)
    else
        love.graphics.polygon("fill", arrowX - 4, arrowY - 2, arrowX + 4, arrowY - 2, arrowX, arrowY + 4)
    end
end

-- Draw the options panel (call after all other UI to render on top)
function Dropdown:drawOptions(bounds)
    if not self.isOpen then return end

    local colors = Theme.hud.colors
    local font = love.graphics.getFont()
    local panel = bounds.panel

    -- Panel background
    love.graphics.setColor(0.08, 0.08, 0.08, 0.98)
    love.graphics.rectangle("fill", panel.x, panel.y, panel.w, panel.h, 4)

    -- Panel border
    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], 0.6)
    love.graphics.rectangle("line", panel.x, panel.y, panel.w, panel.h, 4)

    -- Options
    for i, optRect in ipairs(bounds.options) do
        local isHovered = self.hoverIndex == i
        local isSelected = i == self.selectedIndex

        if isHovered then
            love.graphics.setColor(0.3, 0.5, 0.8, 0.4)
            love.graphics.rectangle("fill", optRect.x + 2, optRect.y, optRect.w - 4, optRect.h)
        end

        if isSelected then
            love.graphics.setColor(0.4, 0.8, 1, 1)
        else
            love.graphics.setColor(1, 1, 1, isHovered and 1 or 0.8)
        end
        love.graphics.print(self.options[i].label, optRect.x + 8, optRect.y + (optRect.h - font:getHeight()) / 2)

        if isSelected then
            love.graphics.setColor(0.4, 0.8, 1, 1)
            love.graphics.print("*", optRect.x + optRect.w - 16, optRect.y + (optRect.h - font:getHeight()) / 2)
        end
    end
end

function Dropdown:close()
    self.isOpen = false
end

return Dropdown
