local Utils = require("ecs.systems.draw.render_utils")
local WeaponDraw = require("ecs.systems.draw.weapon_draw")

local ShipDraw = {}

local function drawPlayerShip(ctx, e, shape)
  -- Sleek starter drone palette: deep charcoal + cyan accents
  local r, g, b, a = Utils.applyFlashToColor(e, 0.10, 0.14, 0.18, 1)
  love.graphics.setColor(r, g, b, a)
  love.graphics.polygon("fill", shape:getPoints())

  -- Narrow mid-plate (scaled down)
  local pr, pg, pb, pa = Utils.applyFlashToColor(e, 0.16, 0.22, 0.30, 1)
  love.graphics.setColor(pr, pg, pb, pa)
  love.graphics.polygon("fill",
    8, 0,
    3.5, 3,
    0, 4.2,
    -6, 3,
    -7, 0,
    -6, -3,
    0, -4.2,
    3.5, -3
  )

  -- Spine highlight (scaled down)
  local hr, hg, hb, ha = Utils.applyFlashToColor(e, 0.22, 0.30, 0.40, 1)
  love.graphics.setColor(hr, hg, hb, ha)
  love.graphics.polygon("fill",
    6, 0,
    2.5, 2,
    -2, 2.8,
    -5, 1.8,
    -6, 0,
    -5, -1.8,
    -2, -2.8,
    2.5, -2
  )

  -- Outline
  love.graphics.setColor(0, 0, 0, 0.95)
  love.graphics.setLineWidth(1)
  love.graphics.polygon("line", shape:getPoints())

  -- Wing blades (thin cyan, smaller reach)
  local ar, ag, ab, aa = Utils.applyFlashToColor(e, 0.00, 0.95, 1.00, 0.8)
  love.graphics.setColor(ar, ag, ab, aa)
  love.graphics.polygon("fill", 8, 4.2, 1.8, 8.5, -4, 5, 1.8, 3.0)
  love.graphics.polygon("fill", 8, -4.2, 1.8, -8.5, -4, -5, 1.8, -3.0)
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.setLineWidth(0.7)
  love.graphics.polygon("line", 8, 4.2, 1.8, 8.5, -4, 5, 1.8, 3.0)
  love.graphics.polygon("line", 8, -4.2, 1.8, -8.5, -4, -5, 1.8, -3.0)

  -- Motion stripes
  love.graphics.setColor(0, 0, 0, 0.4)
  love.graphics.setLineWidth(0.7)
  love.graphics.line(6, 0, -8, 0)
  love.graphics.line(4, 2, -5, 2)
  love.graphics.line(4, -2, -5, -2)

  -- Cockpit bubble
  local cr, cg, cb, ca = Utils.applyFlashToColor(e, 0.04, 0.16, 0.22, 0.95)
  love.graphics.setColor(cr, cg, cb, ca)
  love.graphics.ellipse("fill", 3.2, 0, 2.6, 1.8)
  love.graphics.setColor(0, 0, 0, 0.85)
  love.graphics.setLineWidth(0.9)
  love.graphics.ellipse("line", 3.2, 0, 2.6, 1.8)
  love.graphics.setColor(0.45, 0.75, 0.9, 0.35)
  love.graphics.ellipse("fill", 4.2, -0.5, 1.2, 0.8)

  -- Rear pods + glow (scaled down)
  love.graphics.setColor(0, 0, 0, 0.55)
  love.graphics.line(-5, 6.5, -11, 4.5)
  love.graphics.line(-5, -6.5, -11, -4.5)

  local er, eg, eb, ea = Utils.applyFlashToColor(e, 0.08, 0.10, 0.14, 1)
  love.graphics.setColor(er, eg, eb, ea)
  love.graphics.circle("fill", -9, 6, 1.8)
  love.graphics.circle("fill", -9, -6, 1.8)
  love.graphics.setColor(0.00, 0.95, 1.00, 0.8)
  love.graphics.circle("fill", -9, 6, 1.0)
  love.graphics.circle("fill", -9, -6, 1.0)
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.setLineWidth(0.8)
  love.graphics.circle("line", -9, 6, 1.8)
  love.graphics.circle("line", -9, -6, 1.8)

  -- Nose sensor
  love.graphics.setColor(0.00, 1.00, 1.00, 0.9)
  love.graphics.circle("fill", 12, 0, 1.6)
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.circle("line", 12, 0, 1.6)

  -- Vent slits
  love.graphics.setColor(0, 0, 0, 0.6)
  love.graphics.rectangle("fill", -3.5, 3.8, 1.8, 0.7)
  love.graphics.rectangle("fill", -3.5, -4.6, 1.8, 0.7)
  love.graphics.setColor(0.00, 0.8, 0.9, 0.4)
  love.graphics.rectangle("fill", -3.2, 3.9, 1.2, 0.45)
  love.graphics.rectangle("fill", -3.2, -4.45, 1.2, 0.45)
end

local function drawEnemyShip(e, shape)
  local colors = e.renderable and e.renderable.color or {}
  local primary = colors.primary or colors[1] and colors or { 0.8, 0.2, 0.2, 1 }
  local accent = colors.accent or primary

  -- Base hull
  local r, g, b, a = Utils.applyFlashToColor(e, primary[1] or 0.8, primary[2] or 0.2, primary[3] or 0.2, primary[4] or 1)
  love.graphics.setColor(r, g, b, a)
  love.graphics.polygon("fill", shape:getPoints())

  -- Hull highlight (accent)
  local hr, hg, hb, ha = Utils.applyFlashToColor(e, accent[1] or 0.28, accent[2] or 0.12, accent[3] or 0.14,
    accent[4] or 1)
  love.graphics.setColor(hr, hg, hb, ha)
  love.graphics.polygon("fill",
    10, 0,
    4, 4,
    -6, 3,
    -8, 0,
    -6, -3,
    4, -4
  )

  -- Outline
  love.graphics.setColor(0, 0, 0, 0.9)
  love.graphics.setLineWidth(1.5)
  love.graphics.polygon("line", shape:getPoints())

  -- Detail lines
  love.graphics.setColor(0, 0, 0, 0.5)
  love.graphics.setLineWidth(1)
  love.graphics.line(6, 0, -8, 0)
  love.graphics.circle("line", 3, 0, 2.5)

  -- Engine struts (scaled to fit shape)
  love.graphics.line(-5, 7, -10, 4)
  love.graphics.line(-5, -7, -10, -4)

  -- Engines (accent glow)
  love.graphics.setColor(accent[1] or 0.8, accent[2] or 0.2, accent[3] or 0.1, (accent[4] or 1) * 0.85)
  love.graphics.circle("fill", -9, 5, 2)
  love.graphics.circle("fill", -9, -5, 2)
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.circle("line", -9, 5, 2)
  love.graphics.circle("line", -9, -5, 2)

  -- Cockpit
  love.graphics.setColor(accent[1] or 0.6, accent[2] or 0.1, accent[3] or 0.1, (accent[4] or 1) * 0.7)
  love.graphics.circle("fill", 3, 0, 2.2)
  love.graphics.setColor(0, 0, 0, 0.7)
  love.graphics.circle("line", 3, 0, 2.2)
end

local function drawLaserBeam(e)
  if not e:has("laser_beam") then
    return
  end

  local beam = e.laser_beam
  local t = beam.duration and beam.duration > 0 and (beam.t / beam.duration) or 0

  local color = beam.color or { 0.00, 1.00, 1.00, 0.65 }
  local width = beam.width or 3
  local outerWidth = width * 2
  local coreWidth = math.max(1, width * 0.5)

  -- Outer glow
  love.graphics.setLineWidth(outerWidth)
  love.graphics.setColor(color[1] or 0, color[2] or 1, color[3] or 1, (color[4] or 1) * 0.35 * t)
  love.graphics.line(beam.startX, beam.startY, beam.endX, beam.endY)

  -- Main beam
  love.graphics.setLineWidth(width)
  love.graphics.setColor(color[1] or 0, color[2] or 1, color[3] or 1, (color[4] or 1) * 0.9 * t)
  love.graphics.line(beam.startX, beam.startY, beam.endX, beam.endY)

  -- Core
  love.graphics.setLineWidth(coreWidth)
  love.graphics.setColor(1.00, 1.00, 1.00, 0.4 * t)
  love.graphics.line(beam.startX, beam.startY, beam.endX, beam.endY)

  love.graphics.setLineWidth(2)
end

local function drawEngineThrust(e, isPlayerShip)
  local thrust = (e.ship_input and e.ship_input.thrust) or 0
  if thrust <= 0 or e:has("engine_trail") then
    return
  end

  local flicker = 0.8 + 0.35 * love.math.random()
  local len = 9 * thrust * flicker -- Half size

  if isPlayerShip then
    -- Main flame
    love.graphics.setColor(1.0, 0.65, 0.15, 0.95)
    love.graphics.polygon("fill", -11, -3, -11 - len, 0, -11, 3)

    -- Inner flame
    love.graphics.setColor(1.0, 0.85, 0.4, 0.9)
    love.graphics.polygon("fill", -10.5, -2, -10.5 - (len * 0.65), 0, -10.5, 2)

    -- Core
    love.graphics.setColor(1.0, 0.95, 0.7, 0.85)
    love.graphics.polygon("fill", -10, -1, -10 - (len * 0.35), 0, -10, 1)

    -- Side engine flames
    local sideLen = len * 0.5
    love.graphics.setColor(1.0, 0.20, 0.85, 0.8)
    love.graphics.polygon("fill", -9, 4, -9 - sideLen, 5, -9, 6)
    love.graphics.polygon("fill", -9, -4, -9 - sideLen, -5, -9, -6)

    love.graphics.setColor(1.0, 0.6, 0.95, 0.6)
    love.graphics.polygon("fill", -8.5, 4.5, -8.5 - (sideLen * 0.5), 5, -8.5, 5.5)
    love.graphics.polygon("fill", -8.5, -4.5, -8.5 - (sideLen * 0.5), -5, -8.5, -5.5)
  else
    -- Enemy thrust (red-orange, positioned at scaled-down engines)
    love.graphics.setColor(1.0, 0.4, 0.1, 0.9)
    love.graphics.polygon("fill", -11, -4, -11 - len * 1.5, -5, -11, -6)
    love.graphics.polygon("fill", -11, 4, -11 - len * 1.5, 5, -11, 6)
    love.graphics.setColor(1.0, 0.7, 0.3, 0.85)
    love.graphics.polygon("fill", -10, -4.5, -10 - len, -5, -10, -5.5)
    love.graphics.polygon("fill", -10, 4.5, -10 - len, 5, -10, 5.5)
  end
end



local function drawHealthBar(ctx, e, angle)
  if ctx.capture then return end
  if not e:has("hull") then return end

  local hull = e.hull
  local ratio = hull.current / hull.max
  ratio = math.max(0, math.min(1, ratio))

  -- Get level from enemy component
  local level = 1
  if e:has("enemy") and e.enemy.level then
    level = e.enemy.level
  end

  -- Dimensions
  local r = 14
  local barW = 24
  local barH = 6
  local levelBoxW = 10
  local levelBoxH = barH * 2
  local gap = 2 -- Gap between level box and health bar

  -- Total width of level box + gap + health bar
  local totalW = levelBoxW + gap + barW
  -- Center everything above the ship
  local startX = -totalW / 2
  local barY = -(r + 12)

  love.graphics.push()
  love.graphics.rotate(-angle) -- Keep horizontal

  -- Level box Y position (vertically centered with health bar)
  local levelBoxY = barY - (levelBoxH - barH) / 2

  -- Level box background (solid red)
  love.graphics.setColor(0.9, 0.2, 0.2, 1)
  love.graphics.rectangle("fill", startX, levelBoxY, levelBoxW, levelBoxH)

  -- Level box outline (black)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.setLineWidth(1)
  love.graphics.rectangle("line", startX, levelBoxY, levelBoxW, levelBoxH)

  -- Level text (black, centered)
  love.graphics.setColor(0, 0, 0, 1)
  local font = love.graphics.getFont()
  local levelStr = tostring(level)
  local textW = font:getWidth(levelStr)
  local textH = font:getHeight()
  local textX = startX + (levelBoxW - textW) / 2
  local textY = levelBoxY + (levelBoxH - textH) / 2
  love.graphics.print(levelStr, textX, textY)

  -- Health bar position (after level box + gap)
  local healthBarX = startX + levelBoxW + gap

  -- Health bar background
  love.graphics.setColor(0.15, 0.15, 0.15, 0.9)
  love.graphics.rectangle("fill", healthBarX, barY, barW, barH)

  -- Health bar outline
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.rectangle("line", healthBarX, barY, barW, barH)

  -- Health bar fill (Red)
  love.graphics.setColor(1.0, 0.2, 0.2, 0.9)
  love.graphics.rectangle("fill", healthBarX + 1, barY + 1, (barW - 2) * ratio, barH - 2)

  love.graphics.pop()
end

function ShipDraw.draw(ctx, e, body, shape, x, y, angle)
  love.graphics.push()
  love.graphics.translate(x, y)
  love.graphics.rotate(angle)

  local isPlayerShip = (ctx.playerShip ~= nil and e == ctx.playerShip)

  if isPlayerShip then
    drawPlayerShip(ctx, e, shape)
  else
    drawEnemyShip(e, shape)
    -- Draw bar for enemies
    drawHealthBar(ctx, e, angle)
  end

  drawLaserBeam(e)
  drawEngineThrust(e, isPlayerShip)

  love.graphics.setLineWidth(2)
  love.graphics.pop()

  -- Check for weapon visualization (generic 'weapon' or legacy 'auto_cannon')
  local weapon = e.weapon or e.auto_cannon
  if weapon and isPlayerShip then
    if weapon.coneVis and weapon.coneVis > 0 and weapon.aimX and weapon.aimY then
      WeaponDraw.drawAimIndicator(body, weapon)
    end
  end
end

return ShipDraw
