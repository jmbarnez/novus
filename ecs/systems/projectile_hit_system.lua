local Concord = require("lib.concord")
local PhysicsCleanup = require("ecs.physics_cleanup")
local EntityUtil = require("ecs.util.entity")
local ImpactUtil = require("ecs.util.impact")
local FloatingText = require("ecs.util.floating_text")

local ProjectileHitSystem = Concord.system()

--------------------------------------------------------------------------------
-- Utility functions
--------------------------------------------------------------------------------

local function isValidProjectile(projectile)
  return EntityUtil.isAliveAndHas(projectile, "projectile")
end

local function isValidTarget(projectile, target)
  if not EntityUtil.isAlive(target) then
    return false
  end

  if not target:has("health") and not target:has("hull") and not target:has("space_station") then
    return false
  end

  -- Prevent self-damage
  local owner = projectile.projectile.owner
  if owner ~= nil and owner == target then
    return false
  end

  return true
end

--------------------------------------------------------------------------------
-- Visual effects
--------------------------------------------------------------------------------

local function spawnImpactEffect(world, physicsWorld, x, y, color)
  if not physicsWorld then
    return
  end

  color = color or { 1, 1, 1, 1 }
  color = { color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1 }

  local effectBody = love.physics.newBody(physicsWorld, x, y, "static")
  local effectShape = love.physics.newCircleShape(1)
  local effectFixture = love.physics.newFixture(effectBody, effectShape, 0)

  effectFixture:setSensor(true)
  effectFixture:setCategory(8)
  effectFixture:setMask(1, 2, 4, 8)

  world:newEntity()
      :give("physics_body", effectBody, effectShape, effectFixture)
      :give("renderable", "shatter", color)
      :give("shatter")
end

--------------------------------------------------------------------------------
-- Damage application
--------------------------------------------------------------------------------

local function applyDamage(target, damage)
  target.health.current = target.health.current - damage
  target:ensure("hit_flash")
  target.hit_flash.t = target.hit_flash.duration
end

--------------------------------------------------------------------------------
-- Main hit processing
--------------------------------------------------------------------------------

local function tryHit(projectile, target, contact)
  if not isValidProjectile(projectile) then
    return
  end

  if not isValidTarget(projectile, target) then
    return
  end

  local isStation = target:has("space_station")
  local hasHealth = target:has("health")
  local hasHull = target:has("hull")
  local damage = isStation and 0 or (projectile.projectile.damage or 1)

  if damage > 0 then
    if target:has("shield") then
      local shield = target.shield
      if shield.current > 0 then
        local absorbed = math.min(shield.current, damage)
        shield.current = shield.current - absorbed
        damage = damage - absorbed

        -- Spawn shield hit visual effect
        if target:has("physics_body") and target.physics_body.body then
          local targetBody = target.physics_body.body
          local tx, ty = targetBody:getPosition()
          local targetAngle = targetBody:getAngle()

          -- Get impact world position
          local impactX, impactY = ImpactUtil.calculateImpactPosition(projectile, target, contact)

          -- Convert to local coordinates relative to target
          local dx = impactX - tx
          local dy = impactY - ty
          local cosA = math.cos(-targetAngle)
          local sinA = math.sin(-targetAngle)
          local localX = dx * cosA - dy * sinA
          local localY = dx * sinA + dy * cosA

          -- Add hit to shield_hit component
          target:ensure("shield_hit")
          table.insert(target.shield_hit.hits, {
            localX = localX,
            localY = localY,
            time = 0,
            duration = 0.4
          })
        end
      end
    end

    if damage > 0 then
      if hasHull then
        target.hull.current = target.hull.current - damage
        target:ensure("hit_flash")
        target.hit_flash.t = target.hit_flash.duration
      elseif hasHealth then
        applyDamage(target, damage)
      end
    end
  end

  if target:has("asteroid") then
    local eff = projectile.projectile.miningEfficiency
    if eff == nil then
      eff = 1.0
    end
    target.asteroid.lastMiningEfficiency = eff
  end

  if projectile:has("physics_body") and projectile.physics_body.body then
    local world = projectile:getWorld()
    local physicsWorld = world and world:getResource("physics")
    local x, y = ImpactUtil.calculateImpactPosition(projectile, target, contact)

    local color = projectile.renderable and projectile.renderable.color
    spawnImpactEffect(world, physicsWorld, x, y, color)

    if world then
      world:emit("onProjectileImpact", x, y)
    end

    if world and damage > 0 then
      FloatingText.spawn(world, x, y - 6, tostring(damage), {
        kind = "damage",
        riseSpeed = 70,
        duration = 0.55,
        scale = 1.0,
      })
    end
  end

  PhysicsCleanup.destroyPhysics(projectile)
  projectile:destroy()
end

--------------------------------------------------------------------------------
-- System callbacks
--------------------------------------------------------------------------------

function ProjectileHitSystem:onContact(a, b, contact)
  tryHit(a, b, contact)
  tryHit(b, a, contact)
end

return ProjectileHitSystem
