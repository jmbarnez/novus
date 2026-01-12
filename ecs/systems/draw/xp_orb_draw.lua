local Utils = require("ecs.systems.draw.render_utils")

local XpOrbDraw = {}

local function pulse(t, speed, minScale, maxScale)
  local s = (math.sin(t * speed) + 1) * 0.5 -- 0..1
  return minScale + (maxScale - minScale) * s
end

local function ringAlpha(t, speed)
  local s = (math.sin(t * speed) + 1) * 0.5
  return 0.18 + 0.25 * s
end

function XpOrbDraw.draw(ctx, e, body, x, y)
  if not e:has("xp_orb") then
    return
  end

  local c = e.xp_orb
  local baseColor = e.renderable.color or { 1, 0.95, 0.35, 0.98 }
  local size = (c.size or 6) * 0.8 -- draw slightly smaller than physics radius

  local t = love.timer.getTime() + (c.phase or 0)
  local scale = pulse(t, 4.1, 0.9, 1.12)

  local ringR = size * 1.8 * scale
  local coreR = size * 1.1 * scale
  local sparkR = size * 0.5 * scale

  -- Electric outer ring
  love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], ringAlpha(t, 3.0))
  love.graphics.setLineWidth(2)
  love.graphics.circle("line", x, y, ringR)

  -- Core orb
  local r, g, b, a = Utils.applyFlashToColor(e, baseColor[1], baseColor[2], baseColor[3], baseColor[4])
  love.graphics.setColor(r, g, b, a)
  love.graphics.circle("fill", x, y, coreR)

  -- Inner spark drifting
  love.graphics.setColor(1, 1, 1, 0.45 + 0.25 * math.sin(t * 5.7))
  love.graphics.circle("fill", x + math.sin(t * 4.5) * size * 0.25, y + math.cos(t * 4.5) * size * 0.25, sparkR)
end

return XpOrbDraw
