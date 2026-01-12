-- Weapon icon rendering utility
-- Uses same pattern as item_icons.lua for polygon-based weapon icons

local WeaponIcons = {}

local WEAPON_PATH = "game.weapons."

-- Cache loaded weapon definitions
local weaponDefs = {}

local function getWeaponDef(weaponId)
    if weaponDefs[weaponId] then
        return weaponDefs[weaponId]
    end

    local ok, def = pcall(require, WEAPON_PATH .. weaponId)
    if ok and def then
        weaponDefs[weaponId] = def
        return def
    end
    return nil
end

local function buildScaledPoints(cx, cy, size, points)
    local s = size * 0.5
    local out = {}
    for i = 1, #points, 2 do
        out[i] = cx + points[i] * s
        out[i + 1] = cy + points[i + 1] * s
    end
    return out
end

local function drawFromDef(def, cx, cy, size, opts)
    local icon = def and def.icon
    if not icon or type(icon) ~= "table" then
        return false
    end

    -- Use weapon's projectile/beam color as base, fallback to white
    local baseColor = def.projectileColor or def.beamColor or def.orbColor or { 1, 1, 1, 1 }
    local r, g, b = baseColor[1], baseColor[2], baseColor[3]
    local alpha = (opts and opts.alpha) or 1

    -- Tint support
    if opts and opts.tint then
        local t = opts.tint
        r, g, b = r * t[1], g * t[2], b * t[3]
        alpha = alpha * (t[4] or 1)
    end

    local halfSize = size * 0.5

    -- 1. Shadow
    if icon.shadow then
        local s = icon.shadow
        local dx = (s.dx or 0) * size
        local dy = (s.dy or 0) * size

        love.graphics.push()
        love.graphics.translate(dx, dy)
        love.graphics.setColor(0, 0, 0, (s.a or 0.5) * alpha)
        if icon.kind == "poly" and icon.points then
            local pts = buildScaledPoints(cx, cy, size, icon.points)
            love.graphics.polygon("fill", pts)
        elseif icon.kind == "circle" and icon.radius then
            love.graphics.circle("fill", cx, cy, icon.radius * halfSize)
        end
        love.graphics.pop()
    end

    -- 2. Base fill
    love.graphics.setColor(r, g, b, (icon.fillA or 1) * alpha)
    if icon.kind == "poly" and icon.points then
        local pts = buildScaledPoints(cx, cy, size, icon.points)
        love.graphics.polygon("fill", pts)
    elseif icon.kind == "circle" and icon.radius then
        love.graphics.circle("fill", cx, cy, icon.radius * halfSize)
    end

    -- 3. Highlight (single)
    if icon.highlight then
        local h = icon.highlight
        if h.kind == "polyline" and h.points then
            local pts = buildScaledPoints(cx, cy, size, h.points)
            love.graphics.setColor(1, 1, 1, (h.a or 0.3) * alpha)
            love.graphics.setLineWidth(h.width or 1)
            love.graphics.line(pts)
        end
    end

    -- 3b. Layers (multiple highlights/details)
    if icon.layers then
        for _, layer in ipairs(icon.layers) do
            if layer.kind == "polyline" and layer.points then
                local pts = buildScaledPoints(cx, cy, size, layer.points)
                love.graphics.setColor(1, 1, 1, (layer.a or 0.3) * alpha)
                love.graphics.setLineWidth(layer.width or 1)
                love.graphics.line(pts)
            end
        end
    end

    -- 4. Outline
    if icon.outline then
        love.graphics.setColor(0, 0, 0, (icon.outline.a or 1) * alpha)
        love.graphics.setLineWidth(icon.outline.width or 1)
        if icon.kind == "poly" and icon.points then
            local pts = buildScaledPoints(cx, cy, size, icon.points)
            love.graphics.polygon("line", pts)
        elseif icon.kind == "circle" and icon.radius then
            love.graphics.circle("line", cx, cy, icon.radius * halfSize)
        end
    end

    return true
end

function WeaponIcons.draw(weaponId, x, y, w, h, opts)
    local def = getWeaponDef(weaponId)
    if not def then return false end

    local size = math.min(w, h)
    local cx = x + w * 0.5
    local cy = y + h * 0.5

    love.graphics.push("all")
    local result = drawFromDef(def, cx, cy, size, opts)
    love.graphics.pop()
    return result
end

function WeaponIcons.drawCentered(weaponId, cx, cy, size, opts)
    local def = getWeaponDef(weaponId)
    if not def then return false end

    love.graphics.push("all")
    local result = drawFromDef(def, cx, cy, size, opts)
    love.graphics.pop()
    return result
end

function WeaponIcons.getWeaponDef(weaponId)
    return getWeaponDef(weaponId)
end

return WeaponIcons
