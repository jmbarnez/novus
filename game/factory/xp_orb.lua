local M = {}

local function orbColor()
  return { 1.0, 0.95, 0.35, 0.98 } -- electric yellow
end

local function computeSize(amount)
  local base = 4.0
  local scaled = base + math.sqrt(math.max(amount or 0, 0)) * 0.5
  return math.min(math.max(scaled, 4.0), 9.0) -- clamp to avoid huge orbs
end

--- Spawn an XP orb in the world
---@param world table Concord world
---@param physicsWorld table Box2D physics world
---@param amount number xp contained
---@param x number world X
---@param y number world Y
---@param vx number|nil initial vx
---@param vy number|nil initial vy
---@return table|nil
function M.spawn(world, physicsWorld, amount, x, y, vx, vy)
  if not world or not physicsWorld then
    return nil
  end

  local size = computeSize(amount)

  local body = love.physics.newBody(physicsWorld, x, y, "dynamic")
  body:setLinearDamping(3.0)
  body:setAngularDamping(5.0)

  local radius = size
  local shape = love.physics.newCircleShape(radius)
  local fixture = love.physics.newFixture(body, shape, 0.15)
  fixture:setSensor(true)
  fixture:setCategory(16)
  fixture:setMask(1, 2, 4, 8, 16)

  if vx or vy then
    body:setLinearVelocity(vx or 0, vy or 0)
  end

  local phase = love.math.random() * math.pi * 2

  local e = world:newEntity()
      :give("physics_body", body, shape, fixture)
      :give("renderable", "xp_orb", orbColor())
      :give("xp_orb", amount, phase, size)

  fixture:setUserData(e)
  return e
end

return M
