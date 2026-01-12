local M = {}

local function randomColor(kind)
  if kind == "xp" then
    return { 1.0, 0.92, 0.35, 0.95 } -- vivid yellow
  elseif kind == "credits" then
    return { 0.35, 0.95, 0.85, 0.95 } -- aqua-green
  end
  return { 0.9, 0.9, 0.9, 0.95 }
end

--- Spawn a reward orb (credits/xp) in the world
---@param world table Concord world
---@param physicsWorld table Box2D physics world
---@param kind string "credits" | "xp"
---@param amount number amount of reward contained
---@param x number world X
---@param y number world Y
---@param vx number|nil initial vx
---@param vy number|nil initial vy
---@return table|nil
function M.spawn(world, physicsWorld, kind, amount, x, y, vx, vy)
  if not world or not physicsWorld then
    return nil
  end

  local body = love.physics.newBody(physicsWorld, x, y, "dynamic")
  body:setLinearDamping(3.4)
  body:setAngularDamping(5.0)

  local radius = 7
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
      :give("renderable", "reward_orb", randomColor(kind))
      :give("reward_orb", kind, amount, phase)

  fixture:setUserData(e)
  return e
end

return M
