local Utils = require("ecs.systems.draw.render_utils")

local RewardOrbDraw = {}

local function pulse(t, speed, minScale, maxScale)
  local s = (math.sin(t * speed) + 1) * 0.5 -- 0..1
  return minScale + (maxScale - minScale) * s
end

local function ringAlpha(t, speed)
  local s = (math.sin(t * speed) + 1) * 0.5
  return 0.15 + 0.2 * s
end

function RewardOrbDraw.draw(ctx, e, body, x, y)
  if not e:has("reward_orb") then
    return
  end

  local c = e.reward_orb
  local baseColor = e.renderable.color or { 1, 1, 1, 0.95 }

  -- Time-based wobble
  local t = love.timer.getTime() + (c.phase or 0)
  local scale = pulse(t, 3.5, 0.92, 1.10)

  -- Outer faint ring
  love.graphics.setColor(baseColor[1], baseColor[2], baseColor[3], ringAlpha(t, 2.6))
  love.graphics.circle("line", x, y, 11 * scale)

  -- Core orb
  local r, g, b, a = Utils.applyFlashToColor(e, baseColor[1], baseColor[2], baseColor[3], baseColor[4])
  love.graphics.setColor(r, g, b, a)
  love.graphics.circle("fill", x, y, 6.5 * scale)

  -- Inner spark
  love.graphics.setColor(1, 1, 1, 0.35 + 0.25 * math.sin(t * 5.2))
  love.graphics.circle("fill", x + math.sin(t * 4) * 1.2, y + math.cos(t * 4) * 1.2, 3.2 * scale)
end

return RewardOrbDraw
