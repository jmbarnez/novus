-- Asteroid Tooltip: displays resource composition above scanned asteroids
local AsteroidTooltip = {}

local Theme = require("game.theme")
local ItemIcons = require("game.item_icons")
local Items = require("game.items")

-- Convert world coordinates to screen coordinates using camera view
local function worldToScreen(worldX, worldY, cameraView)
    if not cameraView then
        return nil, nil
    end
    local screenX = (worldX - cameraView.camX) * cameraView.zoom
    local screenY = (worldY - cameraView.camY) * cameraView.zoom
    return screenX, screenY
end

function AsteroidTooltip.hitTest()
    -- Tooltip is not interactive
    return false
end

function AsteroidTooltip.draw(ctx)
    if not ctx or not ctx.world then
        return
    end

    local targeting = ctx.world:getResource("targeting")
    local target = targeting and targeting.selected

    -- Only show for asteroids that have been scanned
    if not target or not target.inWorld or not target:inWorld() then
        return
    end

    if not target:has("asteroid") or not target:has("scanned") then
        return
    end

    if not target:has("asteroid_composition") then
        return
    end

    local composition = target.asteroid_composition.resources
    if not composition or #composition == 0 then
        return
    end

    -- Get target world position
    local body = target.physics_body and target.physics_body.body
    if not body then
        return
    end

    local worldX, worldY = body:getPosition()
    local asteroidRadius = (target.asteroid and target.asteroid.radius) or 30

    -- Convert to screen space
    local cameraView = ctx.world:getResource("camera_view")
    local screenX, screenY = worldToScreen(worldX, worldY - asteroidRadius - 35, cameraView)
    if not screenX or not screenY then
        return
    end

    -- Don't draw if offscreen
    local screenW = ctx.screenW or love.graphics.getWidth()
    local screenH = ctx.screenH or love.graphics.getHeight()
    if screenX < -100 or screenX > screenW + 100 or screenY < -100 or screenY > screenH + 100 then
        return
    end

    -- Calculate tooltip dimensions
    local theme = (ctx and ctx.theme) or Theme
    local hudTheme = theme.hud
    local colors = hudTheme.colors
    local ps = hudTheme.panelStyle or {}

    local iconSize = 18
    local rowHeight = 22
    local padding = 8
    local textGap = 4

    local font = love.graphics.getFont()
    local maxTextWidth = 0
    for _, entry in ipairs(composition) do
        local text = string.format("%d%%", entry.pct)
        local w = font:getWidth(text)
        if w > maxTextWidth then
            maxTextWidth = w
        end
    end

    local tooltipW = padding * 2 + iconSize + textGap + maxTextWidth + 8
    local tooltipH = padding * 2 + #composition * rowHeight - (rowHeight - iconSize)

    -- Center horizontally on asteroid
    local x0 = math.floor(screenX - tooltipW * 0.5)
    local y0 = math.floor(screenY - tooltipH)

    -- Clamp to screen bounds
    x0 = math.max(4, math.min(screenW - tooltipW - 4, x0))
    y0 = math.max(4, y0)

    -- Draw panel background
    local r = ps.radius or 4
    local shadowOffset = ps.shadowOffset or 2
    local shadowAlpha = ps.shadowAlpha or 0.3

    if shadowOffset ~= 0 and shadowAlpha > 0 then
        love.graphics.setColor(0, 0, 0, shadowAlpha)
        love.graphics.rectangle("fill", x0 + shadowOffset, y0 + shadowOffset, tooltipW, tooltipH, r, r)
    end

    love.graphics.setColor(colors.panelBg[1], colors.panelBg[2], colors.panelBg[3], 0.92)
    love.graphics.rectangle("fill", x0, y0, tooltipW, tooltipH, r, r)

    love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], colors.panelBorder[4])
    love.graphics.setLineWidth(ps.borderWidth or 1)
    love.graphics.rectangle("line", x0, y0, tooltipW, tooltipH, r, r)
    love.graphics.setLineWidth(1)

    -- Draw resource rows
    local rowY = y0 + padding
    for _, entry in ipairs(composition) do
        local itemDef = Items.get(entry.id)
        local iconX = x0 + padding
        local iconY = rowY

        -- Draw icon
        if itemDef then
            ItemIcons.draw(entry.id, iconX, iconY, iconSize, iconSize)
        end

        -- Draw percentage text
        local text = string.format("%d%%", entry.pct)
        local textX = iconX + iconSize + textGap
        local textY = iconY + (iconSize - font:getHeight()) * 0.5

        -- Text shadow
        love.graphics.setColor(colors.textShadow[1], colors.textShadow[2], colors.textShadow[3], colors.textShadow[4])
        love.graphics.print(text, textX + 1, textY + 1)

        -- Text color based on rarity
        local textColor = colors.text
        if entry.id == "mithril" then
            textColor = { 0.45, 0.55, 0.85, 1.0 }
        elseif entry.id == "iron" then
            textColor = { 0.72, 0.72, 0.74, 1.0 }
        elseif entry.id == "stone" then
            textColor = { 0.65, 0.65, 0.65, 1.0 }
        end

        love.graphics.setColor(textColor[1], textColor[2], textColor[3], textColor[4])
        love.graphics.print(text, textX, textY)

        rowY = rowY + rowHeight
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return AsteroidTooltip
