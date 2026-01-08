-- Graphics settings section: Window mode, Resolution, Gamma, UI Scale
local Settings = require("game.settings")
local Dropdown = require("states.settings.components.dropdown")
local Slider = require("states.settings.components.slider")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local Graphics = {}

-- Common resolutions (will add native at runtime)
local BASE_RESOLUTIONS = {
    { w = 1280, h = 720 },
    { w = 1366, h = 768 },
    { w = 1600, h = 900 },
    { w = 1920, h = 1080 },
    { w = 2560, h = 1440 },
    { w = 3840, h = 2160 },
}

local WINDOW_MODES = {
    { label = "Windowed",   value = "windowed" },
    { label = "Fullscreen", value = "fullscreen" },
    { label = "Borderless", value = "borderless" },
}

function Graphics.new()
    local self = setmetatable({}, { __index = Graphics })

    -- Build resolution options with native
    local nativeW, nativeH = love.window.getDesktopDimensions()
    local resOptions = { { label = "Native (" .. nativeW .. "x" .. nativeH .. ")", value = { w = nativeW, h = nativeH, native = true } } }
    for _, res in ipairs(BASE_RESOLUTIONS) do
        -- Don't duplicate if same as native
        if res.w ~= nativeW or res.h ~= nativeH then
            table.insert(resOptions, { label = res.w .. "x" .. res.h, value = { w = res.w, h = res.h } })
        end
    end

    -- Window Mode dropdown
    local currentMode = Settings.get("windowMode") or "windowed"
    local modeIndex = 1
    for i, opt in ipairs(WINDOW_MODES) do
        if opt.value == currentMode then
            modeIndex = i
            break
        end
    end

    self.windowModeDropdown = Dropdown.new({
        options = WINDOW_MODES,
        selectedIndex = modeIndex,
        onChange = function(value)
            Settings.set("windowMode", value)
            Graphics.applyWindowMode(value)
        end
    })

    -- Resolution dropdown
    local currentRes = Settings.get("resolution") or { w = 1280, h = 720 }
    local resIndex = 1
    for i, opt in ipairs(resOptions) do
        if opt.value.w == currentRes.w and opt.value.h == currentRes.h then
            resIndex = i
            break
        end
    end

    self.resolutionDropdown = Dropdown.new({
        options = resOptions,
        selectedIndex = resIndex,
        onChange = function(value)
            Settings.set("resolution", { w = value.w, h = value.h })
            Graphics.applyResolution(value)
        end
    })

    -- Gamma slider (0.5 to 2.0, default 1.0)
    local currentGamma = Settings.get("gamma") or 1.0
    self.gammaSlider = Slider.new({
        min = 0.5,
        max = 2.0,
        value = currentGamma,
        step = 0.05,
        onChange = function(value)
            Settings.set("gamma", value)
        end,
        format = "%.2f",
        displayMultiplier = 1,
    })

    -- UI Scale slider (0.75 to 1.5, default 1.0)
    local currentScale = Settings.get("uiScale") or 1.0
    self.uiScaleSlider = Slider.new({
        min = 0.75,
        max = 1.5,
        value = currentScale,
        step = 0.05,
        onChange = function(value)
            Settings.set("uiScale", value)
        end,
        format = "%.0f%%",
        displayMultiplier = 100,
    })

    self.bounds = {}
    self.onResize = nil -- Callback for when resolution changes
    return self
end

-- Set callback for when window size changes
function Graphics:setOnResize(callback)
    self.onResize = callback
end

function Graphics.applyWindowMode(mode)
    local Settings = require("game.settings")
    local res = Settings.get("resolution") or { w = 1280, h = 720 }

    if mode == "fullscreen" then
        love.window.setMode(res.w, res.h, {
            fullscreen = true,
            fullscreentype = "exclusive",
            vsync = Settings.get("vsync") and 1 or 0,
            resizable = false,
        })
    elseif mode == "borderless" then
        local dw, dh = love.window.getDesktopDimensions()
        love.window.setMode(dw, dh, {
            fullscreen = true,
            fullscreentype = "desktop",
            vsync = Settings.get("vsync") and 1 or 0,
            resizable = false,
        })
    else -- windowed
        love.window.setMode(res.w, res.h, {
            fullscreen = false,
            vsync = Settings.get("vsync") and 1 or 0,
            resizable = true,
            minwidth = 800,
            minheight = 600,
        })
    end

    -- Trigger resize to update canvas
    local w, h = love.graphics.getDimensions()
    if love.resize then love.resize(w, h) end

    -- Notify callback (so settings panel can recenter)
    if Graphics._resizeCallback then Graphics._resizeCallback() end
end

function Graphics.applyResolution(res)
    local Settings = require("game.settings")
    local mode = Settings.get("windowMode") or "windowed"

    -- Only apply resolution in windowed or fullscreen (borderless uses desktop size)
    if mode ~= "borderless" then
        love.window.setMode(res.w, res.h, {
            fullscreen = mode == "fullscreen",
            fullscreentype = mode == "fullscreen" and "exclusive" or nil,
            vsync = Settings.get("vsync") and 1 or 0,
            resizable = mode == "windowed",
            minwidth = 800,
            minheight = 600,
        })
    end

    -- Trigger resize to update canvas
    local w, h = love.graphics.getDimensions()
    if love.resize then love.resize(w, h) end

    -- Notify callback (so settings panel can recenter)
    if Graphics._resizeCallback then Graphics._resizeCallback() end
end

-- Static callback setter (used by settings init)
function Graphics.setResizeCallback(callback)
    Graphics._resizeCallback = callback
end

function Graphics:layout(x, y, w)
    local rowH = 24
    local rowGap = 8
    local labelW = 100
    local controlX = x + labelW + 10
    local controlW = 160
    local sliderW = 180

    local cy = y

    -- Window Mode
    self.bounds.windowModeLabel = { x = x, y = cy, w = labelW, h = rowH }
    self.bounds.windowModeDropdown = self.windowModeDropdown:layout(controlX, cy, controlW, rowH)
    cy = cy + rowH + rowGap

    -- Resolution
    self.bounds.resolutionLabel = { x = x, y = cy, w = labelW, h = rowH }
    self.bounds.resolutionDropdown = self.resolutionDropdown:layout(controlX, cy, controlW, rowH)
    cy = cy + rowH + rowGap

    -- Gamma
    self.bounds.gammaLabel = { x = x, y = cy, w = labelW, h = rowH }
    self.bounds.gammaSlider = self.gammaSlider:layout(controlX, cy + 4, sliderW, rowH - 8)
    cy = cy + rowH + rowGap

    -- UI Scale
    self.bounds.uiScaleLabel = { x = x, y = cy, w = labelW, h = rowH }
    self.bounds.uiScaleSlider = self.uiScaleSlider:layout(controlX, cy + 4, sliderW, rowH - 8)
    cy = cy + rowH + rowGap

    return cy - y
end

function Graphics:mousepressed(x, y, button)
    -- Window mode dropdown
    if self.windowModeDropdown:mousepressed(x, y, self.bounds.windowModeDropdown) then
        self.resolutionDropdown:close()
        return true
    end

    -- Resolution dropdown
    if self.resolutionDropdown:mousepressed(x, y, self.bounds.resolutionDropdown) then
        self.windowModeDropdown:close()
        return true
    end

    -- Gamma slider
    if self.gammaSlider:mousepressed(x, y, self.bounds.gammaSlider) then
        return true
    end

    -- UI Scale slider
    if self.uiScaleSlider:mousepressed(x, y, self.bounds.uiScaleSlider) then
        return true
    end

    return false
end

function Graphics:mousereleased(x, y, button)
    self.gammaSlider:mousereleased()
    self.uiScaleSlider:mousereleased()
end

function Graphics:mousemoved(x, y)
    self.windowModeDropdown:mousemoved(x, y, self.bounds.windowModeDropdown)
    self.resolutionDropdown:mousemoved(x, y, self.bounds.resolutionDropdown)
    self.gammaSlider:mousemoved(x, y, self.bounds.gammaSlider)
    self.uiScaleSlider:mousemoved(x, y, self.bounds.uiScaleSlider)
end

function Graphics:draw()
    -- Window Mode
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Window:", self.bounds.windowModeLabel.x, self.bounds.windowModeLabel.y + 4)
    self.windowModeDropdown:draw(self.bounds.windowModeDropdown)

    -- Resolution
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Resolution:", self.bounds.resolutionLabel.x, self.bounds.resolutionLabel.y + 4)
    self.resolutionDropdown:draw(self.bounds.resolutionDropdown)

    -- Gamma
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("Gamma:", self.bounds.gammaLabel.x, self.bounds.gammaLabel.y + 4)
    self.gammaSlider:draw(self.bounds.gammaSlider)

    -- UI Scale
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.print("UI Scale:", self.bounds.uiScaleLabel.x, self.bounds.uiScaleLabel.y + 4)
    self.uiScaleSlider:draw(self.bounds.uiScaleSlider)
end

function Graphics:drawOverlay()
    -- Draw dropdowns last (on top)
    self.windowModeDropdown:drawOptions(self.bounds.windowModeDropdown)
    self.resolutionDropdown:drawOptions(self.bounds.resolutionDropdown)
end

function Graphics:hasOpenDropdown()
    return self.windowModeDropdown.isOpen or self.resolutionDropdown.isOpen
end

function Graphics:closeDropdowns()
    self.windowModeDropdown:close()
    self.resolutionDropdown:close()
end

return Graphics
