local Concord = require("lib.concord")
local Math = require("util.math")
local Effects = require("ecs.util.effects")
local ProjectileSpawner = require("ecs.systems.spawn.projectile_spawner")
local MissileSpawner = require("ecs.systems.spawn.missile_spawner")
local ScatterOrbSpawner = require("ecs.systems.spawn.scatter_orb_spawner")

local clamp = Math.clamp
local normalizeAngle = Math.normalizeAngle
local atan2 = Math.atan2
local cos, sin, sqrt, min, pi = math.cos, math.sin, math.sqrt, math.min, math.pi

local WeaponLogic = {}

function WeaponLogic.isValidTarget(e)
  return e
      and e.inWorld
      and e:inWorld()
      and (e:has("physics_body") or e:has("space_station"))
      and (
        (e:has("health") and e.health.current > 0) or
        (e:has("hull") and e.hull.current > 0) or
        e:has("asteroid") or
        e:has("space_station")
      )
end

-- Wrapper for beam impacts with reduced alpha
local function spawnImpactEffect(world, physicsWorld, x, y, color)
  if not color then
    Effects.spawnShatter(world, physicsWorld, x, y)
    return
  end
  -- Reduced alpha for beam spark effect
  local r, g, b, a = color[1] or 1, color[2] or 1, color[3] or 1, color[4] or 1
  Effects.spawnShatter(world, physicsWorld, x, y, { r, g, b, a * 0.8 })
end

function WeaponLogic.getClampedAimDir(shipBody, dx, dy, coneHalfAngle)
  local dist2 = dx * dx + dy * dy
  if dist2 <= 0.0001 then
    return nil
  end

  local dist = sqrt(dist2)
  local dirX, dirY = dx / dist, dy / dist

  -- No cone restriction
  if not coneHalfAngle or coneHalfAngle >= pi then
    return dirX, dirY
  end

  -- Clamp aim direction within firing cone
  local shipAngle = shipBody:getAngle()
  local aimAngle = atan2(dirY, dirX)
  local delta = normalizeAngle(aimAngle - shipAngle)
  local clampedDelta = clamp(delta, -coneHalfAngle, coneHalfAngle)
  local finalAngle = shipAngle + clampedDelta

  return cos(finalAngle), sin(finalAngle)
end

-- Turret mount offset from ship center (in ship-local coordinates)
local TURRET_OFFSET_X = 12 -- Forward, near ship nose
local TURRET_OFFSET_Y = 0  -- Centered

function WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  local sx, sy = shipBody:getPosition()
  local shipAngle = shipBody:getAngle()

  -- Transform turret offset from ship-local to world coordinates
  local cosA, sinA = cos(shipAngle), sin(shipAngle)
  local turretX = sx + TURRET_OFFSET_X * cosA - TURRET_OFFSET_Y * sinA
  local turretY = sy + TURRET_OFFSET_X * sinA + TURRET_OFFSET_Y * cosA

  return turretX, turretY
end

--------------------------------------------------------------------------------
-- Spawner Wrappers (delegate to modules)
--------------------------------------------------------------------------------

local function spawnProjectile(world, physicsWorld, ship, weapon, dirX, dirY)
  local shipBody = ship.physics_body.body
  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  return ProjectileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
end

local function spawnMissile(world, physicsWorld, ship, weapon, dirX, dirY)
  local shipBody = ship.physics_body.body
  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  return MissileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
end

local function spawnScatterOrb(world, physicsWorld, ship, weapon, targetX, targetY)
  local shipBody = ship.physics_body.body
  local sx, sy = shipBody:getPosition()
  local dx, dy = targetX - sx, targetY - sy
  local dist = sqrt(dx * dx + dy * dy)
  if dist < 1 then dx, dy, dist = 1, 0, 1 end
  local dirX, dirY = dx / dist, dy / dist
  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  return ScatterOrbSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, targetX, targetY, weapon, ship)
end

--------------------------------------------------------------------------------
-- Beam Weapon (kept inline due to raycast/damage integration)
--------------------------------------------------------------------------------

local function spawnBeam(world, physicsWorld, ship, weapon, dirX, dirY)
  -- Beams are instant hitscan or continuous areas.
  -- For "Void Ray" style, we might want a persistent entity attached to ship?
  -- For now implementing simple "instant beam" visual + damage tick

  -- TODO: For continuous beams, we need a different architecture (hold to fire).
  -- This function is "fire once".
  -- Let's make it create a generic "laser_beam" entity that lives for a short time.

  local shipBody = ship.physics_body.body

  -- Clamp aim to turret cone, fall back to ship forward if aim unavailable.
  local clampedX, clampedY = WeaponLogic.getClampedAimDir(shipBody, dirX, dirY, weapon.coneHalfAngle)
  if not clampedX then
    clampedX, clampedY = shipBody:getWorldVector(1, 0)
  end
  dirX, dirY = clampedX, clampedY

  local sx, sy = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  local range = weapon.range or 1000

  -- Raycast
  local tx = sx + dirX * range
  local ty = sy + dirY * range

  local closestFraction = 1
  local hitEntity = nil
  local hitX, hitY = tx, ty

  local function rayCallback(fixture, x, y, xn, yn, fraction)
    -- Ignore owner and sensors
    if fixture:isSensor() then return -1 end

    local entity = fixture:getUserData()
    if entity == ship then return -1 end

    -- Ignore if mask says so? (simplify for now)

    if fraction < closestFraction then
      closestFraction = fraction
      hitEntity = entity
      hitX, hitY = x, y
    end
    return 1
  end

  physicsWorld:rayCast(sx, sy, tx, ty, rayCallback)

  -- Apply damage if hit
  if hitEntity then
    local damage = weapon.damage

    -- Check shield first
    if hitEntity:has("shield") and hitEntity.shield.current > 0 then
      local shield = hitEntity.shield
      local absorbed = math.min(shield.current, damage)
      shield.current = shield.current - absorbed
      damage = damage - absorbed
    end

    if damage > 0 then
      if hitEntity:has("health") then
        hitEntity.health.current = hitEntity.health.current - damage
        world:emit("onDamageTaken", hitEntity, damage, ship)
      elseif hitEntity:has("asteroid") then
        -- Mining?
        world:emit("onAsteroidHit", hitEntity, weapon.damage, ship, weapon.miningEfficiency)
      end
    end
  end

  -- visuals
  world:newEntity()
      :give("laser_beam",
        weapon.beamDuration or 0.1, -- duration
        sx, sy,                     -- start
        hitX, hitY,                 -- end
        weapon.beamColor or { 1, 0, 1, 1 },
        weapon.beamWidth or 2)

  return true
end

function WeaponLogic.stopBeam(weapon)
  if weapon.beamEntity then
    if weapon.beamEntity:inWorld() then
      weapon.beamEntity:destroy()
    end
    weapon.beamEntity = nil
  end
end

function WeaponLogic.maintainBeam(world, physicsWorld, ship, weapon, targetX, targetY, dt)
  local shipBody = ship.physics_body.body

  -- Clamp aim to turret cone, fall back to ship forward if aim unavailable.
  local clampedX, clampedY = WeaponLogic.getClampedAimDir(shipBody, targetX - shipBody:getX(), targetY - shipBody:getY(),
    weapon.coneHalfAngle)
  if not clampedX then
    clampedX, clampedY = shipBody:getWorldVector(1, 0)
  end

  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, clampedX, clampedY)

  local range = weapon.range or 1000
  local tx = muzzleX + clampedX * range
  local ty = muzzleY + clampedY * range

  -- Raycast
  local closestFraction = 1
  local hitEntity = nil
  local hitX, hitY = tx, ty

  local function rayCallback(fixture, x, y, xn, yn, fraction)
    if fixture:isSensor() then return -1 end
    local entity = fixture:getUserData()
    if entity == ship then return -1 end

    if fraction < closestFraction then
      closestFraction = fraction
      hitEntity = entity
      hitX, hitY = x, y
    end
    return 1
  end

  physicsWorld:rayCast(muzzleX, muzzleY, tx, ty, rayCallback)

  -- VISUAL UPDATE
  local beamEntity = weapon.beamEntity
  if beamEntity and (not beamEntity.laser_beam or not beamEntity:inWorld()) then
    weapon.beamEntity = nil
    beamEntity = nil
  end

  if not beamEntity then
    -- Create new
    beamEntity = world:newEntity()
        :give("laser_beam",
          weapon.beamDuration or 0.1,
          muzzleX, muzzleY, hitX, hitY,
          weapon.beamColor or { 0, 1, 1, 1 },
          weapon.beamWidth or 2
        )
    weapon.beamEntity = beamEntity
  else
    -- Update existing
    local beam = beamEntity.laser_beam
    beam.startX, beam.startY = muzzleX, muzzleY
    beam.endX, beam.endY = hitX, hitY
    beam.color = weapon.beamColor or { 0, 1, 1, 1 }
    beam.width = weapon.beamWidth or 2

    -- Keep alive
    beam.t = beam.duration -- Reset timer so it doesn't die while held
  end

  -- DAMAGE TICK
  if weapon.timer <= 0 then
    if hitEntity then
      local damage = weapon.damage

      -- Check shield first
      if hitEntity:has("shield") and hitEntity.shield.current > 0 then
        local shield = hitEntity.shield
        local absorbed = math.min(shield.current, damage)
        shield.current = shield.current - absorbed
        damage = damage - absorbed

        -- Spawn shield ripple effect
        if hitEntity:has("physics_body") and hitEntity.physics_body.body then
          local body = hitEntity.physics_body.body
          local tx, ty = body:getPosition()
          local angle = body:getAngle()
          local dx = hitX - tx
          local dy = hitY - ty
          local cosA = math.cos(-angle)
          local sinA = math.sin(-angle)
          local localX = dx * cosA - dy * sinA
          local localY = dx * sinA + dy * cosA

          hitEntity:ensure("shield_hit")
          table.insert(hitEntity.shield_hit.hits, {
            localX = localX,
            localY = localY,
            time = 0,
            duration = 0.4
          })
        end
      end

      if damage > 0 then
        -- Apply remaining damage to hull/health
        if hitEntity:has("health") then
          hitEntity.health.current = hitEntity.health.current - damage
          world:emit("onDamageTaken", hitEntity, damage, ship)
        elseif hitEntity:has("asteroid") then
          world:emit("onAsteroidHit", hitEntity, weapon.damage, ship, weapon.miningEfficiency)
        elseif hitEntity:has("hull") then
          hitEntity.hull.current = hitEntity.hull.current - damage
          hitEntity:ensure("hit_flash")
          hitEntity.hit_flash.t = hitEntity.hit_flash.duration
        end
      end

      -- Spawn hit effect
      spawnImpactEffect(world, physicsWorld, hitX, hitY, weapon.beamColor)
    end

    -- Reset Timer
    weapon.timer = weapon.cooldown
  end
end

--------------------------------------------------------------------------------
-- Public Logic
--------------------------------------------------------------------------------

local function triggerConeVisual(weapon)
  local hold = weapon.coneVisHold or 0
  local fade = weapon.coneVisFade or 0
  if hold + fade > 0 then
    weapon.coneVis = hold + fade
  end
end

function WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, targetX, targetY, dt)
  if weapon.type == "beam" and dt then
    WeaponLogic.maintainBeam(world, physicsWorld, ship, weapon, targetX, targetY, dt)
    return true
  end

  if weapon.timer > 0 then
    return false
  end

  local shipBody = ship.physics_body.body
  local sx, sy = shipBody:getPosition()
  local dx, dy = targetX - sx, targetY - sy

  local dirX, dirY = WeaponLogic.getClampedAimDir(shipBody, dx, dy, weapon.coneHalfAngle)
  if not dirX then
    return false
  end

  weapon.timer = weapon.cooldown
  triggerConeVisual(weapon)
  world:emit("onWeaponFired", ship, weapon)

  if weapon.type == "missile" then
    return spawnMissile(world, physicsWorld, ship, weapon, dirX, dirY)
  elseif weapon.type == "beam" then
    -- Fallback if no dt provided (shouldn't happen if updated correctly)
    return spawnBeam(world, physicsWorld, ship, weapon, dirX, dirY)
  elseif weapon.type == "scatter" then
    -- Scatter orb travels to target position then explodes
    return spawnScatterOrb(world, physicsWorld, ship, weapon, targetX, targetY)
  else
    -- Projectile (handle count/spread)
    local count = weapon.count or 1
    local spread = weapon.spread or 0
    local aimAngle = atan2(dirY, dirX)

    -- Calculate start angle (centered around aim)
    -- e.g. count=3, spread=20deg. Angles: -10, 0, +10? Or spread is per-shot variance?
    -- Usually "spread" is total cone or random variance?
    -- "Plasma Splitter": spread=20deg, count=5.
    -- Let's do evenly spaced if count > 1, or random if spread specified but count=1?
    -- Let's treat it as: evenly distributed across `spread` Angle centered on aim.

    local startA = aimAngle - spread / 2
    local step = 0
    if count > 1 then
      step = spread / (count - 1)
    end
    -- If spread is 0, all go straight (maybe slightly clustered to avoid stack collision?)

    -- If spread is intended as "random accuracy", that's different.
    -- For "Plasma Splitter" (shotgun), fixed pattern is nice.
    -- For "Vulcan" (rapid), random spread is nice? Vulcan def has cone 5 deg.
    -- Currently we clamp AIM to cone.
    -- Let's assume `spread` = fixed pattern spread arc.
    -- If count=1 and spread>0, maybe random?

    if count == 1 then
      -- Single shot
      spawnProjectile(world, physicsWorld, ship, weapon, dirX, dirY)
    else
      for i = 0, count - 1 do
        local a = startA + step * i
        -- Add some random jitter if needed? Nah.
        local adx, ady = math.cos(a), math.sin(a)
        spawnProjectile(world, physicsWorld, ship, weapon, adx, ady)
      end
    end

    return true
  end
end

function WeaponLogic.fireAtTarget(world, physicsWorld, ship, weapon, target, dt)
  if not WeaponLogic.isValidTarget(target) then
    return false
  end

  -- If homing, ensure target is set
  if weapon.type == "missile" then
    weapon.target = target
  end

  local tx, ty = target.physics_body.body:getPosition()
  return WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, tx, ty, dt)
end

function WeaponLogic.fireAtPosition(world, physicsWorld, ship, weapon, worldX, worldY, dt)
  -- Clear target if firing at position manually
  weapon.target = nil
  return WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, worldX, worldY, dt)
end

return WeaponLogic
