-- Display settings section: FPS limit, VSync
local Settings = require("game.settings")
local Dropdown = require("states.settings.components.dropdown")

local Display = {}

local FPS_OPTIONS = {
    { label = "30",        value = 30 },
    { label = "60",        value = 60 },
    { label = "120",       value = 120 },
    { label = "144",       value = 144 },
    { label = "240",       value = 240 },
    { label = "360",       value = 360 },
    { label = "Unlimited", value = 0 },
}

function Display.new()
    local self = setmetatable({}, { __index = Display })

    -- Initialize FPS dropdown
    local currentFps = Settings.get("maxFps") or 60
    local fpsIndex = 2 -- default to 60
    for i, opt in ipairs(FPS_OPTIONS) do
        if opt.value == currentFps then
            fpsIndex = i
            break
        end
    end

    self.fpsDropdown = Dropdown.new({
        options = FPS_OPTIONS,
        selectedIndex = fpsIndex,
        onChange = function(value)
            Settings.set("maxFps", value)
        end
    })

    self.bounds = {}
    self.hover = nil
    return self
end

function Display:layout(x, y, w)
    local rowH = 24
    local labelW = 100
    local controlX = x + labelW + 10
    local controlW = 140

    self.bounds = {
        fpsLabel = { x = x, y = y, w = labelW, h = rowH },
        fpsDropdown = self.fpsDropdown:layout(controlX, y, controlW, rowH),
        vsyncLabel = { x = x, y = y + 32, w = labelW, h = rowH },
        vsyncBtn = { x = controlX, y = y + 32, w = controlW, h = rowH },
    }

    -- Return height consumed by this section
    return 64
end

function Display:mousepressed(x, y, button)
    local Rect = require("util.rect")
    local pointInRect = Rect.pointInRect

    -- FPS dropdown
    if self.fpsDropdown:mousepressed(x, y, self.bounds.fpsDropdown) then
        return true
    end

    -- VSync toggle
    if pointInRect(x, y, self.bounds.vsyncBtn) then
        local current = Settings.get("vsync")
        Settings.set("vsync", not current)
        love.window.setVSync((not current) and 1 or 0)
        return true
    end

    return false
end

function Display:mousereleased(x, y, button)
    -- Nothing to release
end

function Display:mousemoved(x, y)
    local Rect = require("util.rect")
    local pointInRect = Rect.pointInRect

    self.hover = nil
    self.fpsDropdown:mousemoved(x, y, self.bounds.fpsDropdown)

    if pointInRect(x, y, self.bounds.vsyncBtn) then
        self.hover = "vsync"
    end
end

function Display:draw()
    local Theme = require("game.theme")
    local colors = Theme.hud.colors
    local font = love.graphics.getFont()

    -- FPS Label
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Max FPS:", self.bounds.fpsLabel.x, self.bounds.fpsLabel.y + 4)

    -- FPS Dropdown
    self.fpsDropdown:draw(self.bounds.fpsDropdown)

    -- VSync Label
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("VSync:", self.bounds.vsyncLabel.x, self.bounds.vsyncLabel.y + 4)

    -- VSync Button
    local vsyncOn = Settings.get("vsync")
    local vsyncText = vsyncOn and "Enabled" or "Disabled"
    local vw = font:getWidth(vsyncText)
    local btn = self.bounds.vsyncBtn
    local isHover = self.hover == "vsync"

    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.rectangle("fill", btn.x, btn.y, btn.w, btn.h, 4)

    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3],
        isHover and 0.8 or 0.4)
    love.graphics.rectangle("line", btn.x, btn.y, btn.w, btn.h, 4)

    love.graphics.setColor(1, 1, 1, isHover and 1 or 0.9)
    love.graphics.print(vsyncText, btn.x + (btn.w - vw) / 2, btn.y + 4)
end

-- Draw overlays (dropdowns) last
function Display:drawOverlay()
    self.fpsDropdown:drawOptions(self.bounds.fpsDropdown)
end

function Display:hasOpenDropdown()
    return self.fpsDropdown.isOpen
end

function Display:closeDropdowns()
    self.fpsDropdown:close()
end

return Display
