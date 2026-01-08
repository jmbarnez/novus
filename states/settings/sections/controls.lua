-- Controls settings section: Keybindings
local Settings = require("game.settings")
local Theme = require("game.theme")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local Controls = {}

function Controls.new()
    local self = setmetatable({}, { __index = Controls })
    self.bounds = {}
    self.listening = nil -- { action = "thrust", index = 1 }
    self.hover = nil
    return self
end

function Controls:layout(x, y, w)
    local controls = Settings.get("controls")
    local rowH = 32

    -- Sort actions for consistent order
    local actions = {}
    for k in pairs(controls) do
        table.insert(actions, k)
    end
    table.sort(actions)

    self.bounds = { binds = {} }
    local cy = y

    for _, action in ipairs(actions) do
        local keys = controls[action]
        local actionLabel = action:gsub("_", " "):gsub("^%l", string.upper)

        -- Action label
        table.insert(self.bounds.binds, {
            type = "label",
            text = actionLabel,
            rect = { x = x, y = cy, w = 140, h = 24 }
        })

        -- Key 1
        table.insert(self.bounds.binds, {
            type = "key",
            action = action,
            index = 1,
            key = keys[1] or "---",
            rect = { x = x + 150, y = cy, w = 120, h = 24 }
        })

        -- Key 2
        table.insert(self.bounds.binds, {
            type = "key",
            action = action,
            index = 2,
            key = keys[2] or "---",
            rect = { x = x + 280, y = cy, w = 120, h = 24 }
        })

        cy = cy + rowH
    end

    -- Return height consumed
    return #actions * rowH
end

function Controls:keypressed(key)
    if self.listening then
        local action = self.listening.action
        local index = self.listening.index
        local controls = Settings.get("controls")

        if key == "escape" then
            self.listening = nil
        else
            local newBind = "key:" .. key
            controls[action][index] = newBind
            Settings.setControl(action, controls[action])
            self.listening = nil
        end
        return true
    end
    return false
end

function Controls:mousepressed(x, y, button)
    if self.listening then
        local action = self.listening.action
        local index = self.listening.index
        local controls = Settings.get("controls")

        local newBind = "mouse:" .. button
        controls[action][index] = newBind
        Settings.setControl(action, controls[action])
        self.listening = nil
        return true
    end

    for _, item in ipairs(self.bounds.binds) do
        if item.type == "key" and pointInRect(x, y, item.rect) then
            self.listening = { action = item.action, index = item.index }
            return true
        end
    end

    return false
end

function Controls:mousereleased(x, y, button)
    -- Nothing to release
end

function Controls:mousemoved(x, y)
    self.hover = nil
    for _, item in ipairs(self.bounds.binds) do
        if item.type == "key" and pointInRect(x, y, item.rect) then
            self.hover = item
        end
    end
end

function Controls:draw()
    local colors = Theme.hud.colors
    local font = love.graphics.getFont()

    for _, item in ipairs(self.bounds.binds) do
        if item.type == "label" then
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(item.text, item.rect.x, item.rect.y + 4)
        elseif item.type == "key" then
            local isListening = self.listening and
                self.listening.action == item.action and
                self.listening.index == item.index
            local isHover = self.hover == item

            love.graphics.setColor(0.1, 0.1, 0.1, 1)
            love.graphics.rectangle("fill", item.rect.x, item.rect.y, item.rect.w, item.rect.h, 4)

            love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3],
                (isHover or isListening) and 0.8 or 0.4)
            love.graphics.rectangle("line", item.rect.x, item.rect.y, item.rect.w, item.rect.h, 4)

            local text = isListening and "Press key..." or item.key
            if not isListening then
                text = text:gsub("key:", ""):gsub("mouse:", "MB ")
            end

            local textW = font:getWidth(text)
            love.graphics.setColor(1, 1, 1, isListening and 1 or 0.8)
            love.graphics.print(text, item.rect.x + (item.rect.w - textW) / 2, item.rect.y + 4)
        end
    end
end

function Controls:drawOverlay()
    -- No overlays
end

function Controls:hasOpenDropdown()
    return false
end

function Controls:closeDropdowns()
    -- No dropdowns
end

function Controls:isListening()
    return self.listening ~= nil
end

return Controls
