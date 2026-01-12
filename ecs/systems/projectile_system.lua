local Concord = require("lib.concord")
local Physics = require("ecs.util.physics")

local cos, sin, pi = math.cos, math.sin, math.pi
local random = math.random

local ProjectileSystem = Concord.system({
  projectiles = { "projectile", "physics_body" },
})

--------------------------------------------------------------------------------
-- Default expire effect (small shatter)
--------------------------------------------------------------------------------

local function spawnExpireEffect(world, physicsWorld, x, y, color)
  if not physicsWorld then return end

  local effectBody = love.physics.newBody(physicsWorld, x, y, "static")
  local effectShape = love.physics.newCircleShape(1)
  local effectFixture = love.physics.newFixture(effectBody, effectShape, 0)

  effectFixture:setSensor(true)
  effectFixture:setCategory(8)
  effectFixture:setMask(1, 2, 4, 8)

  world:newEntity()
      :give("physics_body", effectBody, effectShape, effectFixture)
      :give("renderable", "shatter", color or { 1, 1, 1, 1 })
      :give("shatter")
end

--------------------------------------------------------------------------------
-- Helper: Spawn a fragment projectile
--------------------------------------------------------------------------------

local function spawnFragment(world, physicsWorld, x, y, angle, config, owner)
  local body = love.physics.newBody(physicsWorld, x, y, "dynamic")
  body:setBullet(true)
  body:setLinearDamping(0)
  body:setAngularDamping(0)
  if body.setGravityScale then
    body:setGravityScale(0)
  end

  local size = config.projectileSize or 4
  local shape = love.physics.newCircleShape(size)
  local fixture = love.physics.newFixture(body, shape, 0.1)
  fixture:setSensor(true)
  fixture:setCategory(4)

  -- Inherit owner's collision mask
  local ownerCat = 2
  if owner and owner.physics_body and owner.physics_body.fixture then
    ownerCat = owner.physics_body.fixture:getCategory()
  end
  fixture:setMask(4, ownerCat)

  local speed = config.projectileSpeed or 700
  body:setLinearVelocity(cos(angle) * speed, sin(angle) * speed)

  local projectile = world:newEntity()
      :give("physics_body", body, shape, fixture)
      :give("renderable", "projectile", config.projectileColor or { 1, 1, 1, 1 })
      :give("projectile", config.damage or 10, config.projectileTtl or 0.6, owner, config.miningEfficiency)

  fixture:setUserData(projectile)
end

--------------------------------------------------------------------------------
-- Expire Behavior Registry
-- Each behavior is a function(world, physicsWorld, x, y, projectile, config)
--------------------------------------------------------------------------------

local ExpireBehaviors = {}

-- "scatter": Explode into random projectiles in all directions
ExpireBehaviors.scatter = function(world, physicsWorld, x, y, projectile, config)
  local countRange = config.scatterCount or { 6, 10 }
  local minCount = countRange[1] or 6
  local maxCount = countRange[2] or minCount
  local count = random(minCount, maxCount)

  for i = 1, count do
    local angle = random() * 2 * pi
    spawnFragment(world, physicsWorld, x, y, angle, config, projectile.owner)
  end

  spawnExpireEffect(world, physicsWorld, x, y, config.projectileColor)
end

-- "split": Split into a fixed number of projectiles in a cone pattern
ExpireBehaviors.split = function(world, physicsWorld, x, y, projectile, config)
  local count = config.splitCount or 3
  local spreadAngle = config.splitSpread or (pi / 4) -- 45 degree spread

  -- Get projectile's current direction
  local body = projectile.owner and projectile.owner.physics_body and projectile.owner.physics_body.body
  local baseAngle = 0
  if body then
    local vx, vy = body:getLinearVelocity()
    if vx ~= 0 or vy ~= 0 then
      baseAngle = math.atan(vy, vx)
    end
  end

  local startAngle = baseAngle - spreadAngle / 2
  local step = count > 1 and (spreadAngle / (count - 1)) or 0

  for i = 0, count - 1 do
    local angle = startAngle + step * i
    spawnFragment(world, physicsWorld, x, y, angle, config, projectile.owner)
  end

  spawnExpireEffect(world, physicsWorld, x, y, config.projectileColor)
end

-- "explode": Area damage explosion (could be extended with actual AoE damage)
ExpireBehaviors.explode = function(world, physicsWorld, x, y, projectile, config)
  -- For now just a bigger visual effect, AoE damage can be added later
  local color = config.explosionColor or config.projectileColor or { 1, 0.5, 0, 1 }
  spawnExpireEffect(world, physicsWorld, x, y, color)

  -- TODO: Query nearby entities and apply damage based on config.explosionRadius
end

-- "scatter_away": Scatter projectiles in a 180-degree arc opposite to the impact direction
-- Requires config.impactAngle to be set at call time
ExpireBehaviors.scatter_away = function(world, physicsWorld, x, y, projectile, config)
  local countRange = config.scatterCount or { 6, 10 }
  local minCount = countRange[1] or 6
  local maxCount = countRange[2] or minCount
  local count = random(minCount, maxCount)

  -- impactAngle points FROM projectile TO target, so we scatter in the opposite half-circle
  local impactAngle = config.impactAngle or 0
  local awayAngle = impactAngle + pi -- Opposite direction

  for i = 1, count do
    -- Spread within a 180-degree arc (pi radians) centered on awayAngle
    local spread = (random() - 0.5) * pi
    local angle = awayAngle + spread
    spawnFragment(world, physicsWorld, x, y, angle, config, projectile.owner)
  end

  spawnExpireEffect(world, physicsWorld, x, y, config.projectileColor)
end

--------------------------------------------------------------------------------
-- System Update
--------------------------------------------------------------------------------

function ProjectileSystem:update(dt)
  for i = self.projectiles.size, 1, -1 do
    local e = self.projectiles[i]
    local proj = e.projectile
    proj.ttl = proj.ttl - dt

    if proj.ttl <= 0 then
      local body = e.physics_body and e.physics_body.body
      local world = e:getWorld()
      local physicsWorld = world and world:getResource("physics")

      if body and world then
        local x, y = body:getPosition()

        -- Dispatch to registered behavior or default effect
        local behavior = proj.expireBehavior
        local handler = behavior and ExpireBehaviors[behavior]

        if handler then
          handler(world, physicsWorld, x, y, proj, proj.expireConfig or {})
        else
          spawnExpireEffect(world, physicsWorld, x, y)
        end
      end

      Physics.destroyPhysics(e)
      e:destroy()
    end
  end
end

--------------------------------------------------------------------------------
-- Public API for registering custom behaviors from other modules
--------------------------------------------------------------------------------

function ProjectileSystem.registerExpireBehavior(name, handler)
  ExpireBehaviors[name] = handler
end

-- Trigger an impact behavior (called from projectile_hit_system)
function ProjectileSystem.triggerImpactBehavior(behaviorName, world, physicsWorld, x, y, proj, config)
  local handler = ExpireBehaviors[behaviorName]
  if handler then
    handler(world, physicsWorld, x, y, proj, config)
  end
end

return ProjectileSystem
