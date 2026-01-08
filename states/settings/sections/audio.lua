-- Audio settings section: Master, SFX, Music volume sliders
local Sound = require("game.sound")
local Slider = require("states.settings.components.slider")

local Audio = {}

local CHANNELS = {
    { label = "Master", channel = "master" },
    { label = "SFX",    channel = "sfx" },
    { label = "Music",  channel = "music" },
}

function Audio.new()
    local self = setmetatable({}, { __index = Audio })

    -- Sync with saved settings
    Sound.load()

    -- Create sliders for each channel
    self.sliders = {}
    for _, ch in ipairs(CHANNELS) do
        self.sliders[ch.channel] = Slider.new({
            min = 0,
            max = 1,
            value = Sound.getVolume(ch.channel),
            onChange = function(value)
                Sound.setVolume(ch.channel, value)
            end,
            format = "%.0f%%",
            displayMultiplier = 100,
        })
    end

    self.bounds = {}
    return self
end

function Audio:layout(x, y, w)
    local rowH = 28
    local rowGap = 6
    local labelW = 100
    local sliderX = x + labelW + 10
    local sliderW = 180

    self.bounds = { rows = {} }
    local cy = y

    for i, ch in ipairs(CHANNELS) do
        local slider = self.sliders[ch.channel]
        self.bounds.rows[i] = {
            label = { x = x, y = cy, w = labelW, h = rowH },
            slider = slider:layout(sliderX, cy + 4, sliderW, rowH - 8),
            channel = ch.channel,
            text = ch.label,
            sliderRef = slider,
        }
        cy = cy + rowH + rowGap
    end

    -- Return height consumed
    return #CHANNELS * (rowH + rowGap)
end

function Audio:mousepressed(x, y, button)
    for _, row in ipairs(self.bounds.rows) do
        if row.sliderRef:mousepressed(x, y, row.slider) then
            return true
        end
    end
    return false
end

function Audio:mousereleased(x, y, button)
    for _, row in ipairs(self.bounds.rows) do
        row.sliderRef:mousereleased()
    end
end

function Audio:mousemoved(x, y)
    for _, row in ipairs(self.bounds.rows) do
        row.sliderRef:mousemoved(x, y, row.slider)
    end
end

function Audio:draw()
    local font = love.graphics.getFont()

    for _, row in ipairs(self.bounds.rows) do
        -- Label
        love.graphics.setColor(1, 1, 1, 0.9)
        love.graphics.print(row.text .. ":", row.label.x, row.label.y + 4)

        -- Slider
        row.sliderRef:draw(row.slider)
    end
end

function Audio:drawOverlay()
    -- No overlays
end

function Audio:hasOpenDropdown()
    return false
end

function Audio:closeDropdowns()
    -- No dropdowns
end

return Audio
