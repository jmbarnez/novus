local Utils = require("ecs.systems.draw.render_utils")

local ProjectileDraw = {}

function ProjectileDraw.draw(ctx, e, body, x, y)
  local drawIt = true
  if ctx.viewLeft then
    local rCull = 18
    if x + rCull < ctx.viewLeft - ctx.cullPad or x - rCull > ctx.viewRight + ctx.cullPad
        or y + rCull < ctx.viewTop - ctx.cullPad or y - rCull > ctx.viewBottom + ctx.cullPad then
      drawIt = false
    end
  end

  if not drawIt then
    return
  end

  local vx, vy = body:getLinearVelocity()
  local speed2 = vx * vx + vy * vy

  local nx, ny = 1, 0
  if speed2 > 0.001 then
    local inv = 1 / math.sqrt(speed2)
    nx, ny = vx * inv, vy * inv
  end

  -- Derive visual length from fixture radius (default 8 if unknown)
  -- Keep a very small minimum so tiny projectiles look tiny.
  local len = 8
  local fixtures = body:getFixtures()
  if fixtures and fixtures[1] and fixtures[1]:getShape():typeOf("CircleShape") then
    local r = fixtures[1]:getShape():getRadius()
    len = math.max(1, r * 3)
  end

  local outerWidth = math.max(1, len * 0.6)
  local innerWidth = math.max(0.6, len * 0.35)

  love.graphics.setLineWidth(outerWidth)
  love.graphics.setColor(0, 0, 0, 1)
  love.graphics.line(x - nx * len * 0.5, y - ny * len * 0.5, x + nx * len * 0.5, y + ny * len * 0.5)
  love.graphics.setLineWidth(innerWidth)

  -- Use color from renderable component or default to cyan
  local color = e.renderable.color or { 0.00, 1.00, 1.00, 0.95 }
  love.graphics.setColor(unpack(color))
  love.graphics.line(x - nx * len * 0.5, y - ny * len * 0.5, x + nx * len * 0.5, y + ny * len * 0.5)
  love.graphics.setLineWidth(innerWidth)
end

return ProjectileDraw
