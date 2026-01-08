local Concord = require("lib.concord")
local Math = require("util.math")

local clamp = Math.clamp
local normalizeAngle = Math.normalizeAngle
local atan2 = Math.atan2
local cos, sin, sqrt, min, pi = math.cos, math.sin, math.sqrt, math.min, math.pi

local WeaponLogic = {}

function WeaponLogic.isValidTarget(e)
  return e
      and e.inWorld
      and e:inWorld()
      and e:has("physics_body")
      and (
        (e:has("health") and e.health.current > 0) or
        (e:has("hull") and e.hull.current > 0)
      )
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

function WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)
  local sx, sy = shipBody:getPosition()
  local muzzleOffset = 18
  return sx + dirX * muzzleOffset, sy + dirY * muzzleOffset
end

--------------------------------------------------------------------------------
-- Weapon Types
--------------------------------------------------------------------------------

local function spawnProjectile(world, physicsWorld, ship, weapon, dirX, dirY)
  local shipBody = ship.physics_body.body
  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)

  -- Create physics body
  local body = love.physics.newBody(physicsWorld, muzzleX, muzzleY, "dynamic")
  body:setBullet(true)
  body:setLinearDamping(0)
  body:setAngularDamping(0)
  if body.setGravityScale then
    body:setGravityScale(0)
  end

  -- Create shape and fixture
  local shape = love.physics.newCircleShape(weapon.projectileSize or 3)
  local fixture = love.physics.newFixture(body, shape, 0.1)
  fixture:setSensor(true)
  fixture:setCategory(4)

  -- Mask collision with owner's category to avoid self-collision
  local ownerCat = 2 -- Default to player category
  if ship.physics_body and ship.physics_body.fixture then
    ownerCat = ship.physics_body.fixture:getCategory()
  end
  fixture:setMask(4, ownerCat) -- Ignore projectiles (4) and owner category

  -- Set velocity
  local speed = weapon.projectileSpeed or 1200
  body:setLinearVelocity(dirX * speed, dirY * speed)

  -- Calculate time-to-live
  local ttl = weapon.projectileTtl or 1.2

  -- Create projectile entity
  local miningEfficiency = weapon.miningEfficiency or 1.0
  local projectile = world:newEntity()
      :give("physics_body", body, shape, fixture)
      :give("renderable", "projectile", weapon.projectileColor or { 0.00, 1.00, 1.00, 0.95 })
      :give("projectile", weapon.damage, ttl, ship, miningEfficiency)

  fixture:setUserData(projectile)
  return true
end

local function spawnMissile(world, physicsWorld, ship, weapon, dirX, dirY)
  local shipBody = ship.physics_body.body
  local muzzleX, muzzleY = WeaponLogic.getMuzzlePosition(shipBody, dirX, dirY)

  -- Missiles launch slightly slower then accelerate
  local launchSpeed = (weapon.missileSpeed or 600) * 0.5

  -- Body
  local body = love.physics.newBody(physicsWorld, muzzleX, muzzleY, "dynamic")
  body:setLinearDamping(0.5) -- Some drag
  body:setAngularDamping(2)  -- Stable turning

  local shape = love.physics.newCircleShape(4)
  local fixture = love.physics.newFixture(body, shape, 0.5)
  fixture:setSensor(true) -- Contact only
  fixture:setCategory(4)  -- Projectile category

  local ownerCat = 2
  if ship.physics_body and ship.physics_body.fixture then
    ownerCat = ship.physics_body.fixture:getCategory()
  end
  fixture:setMask(4, ownerCat)

  body:setLinearVelocity(dirX * launchSpeed, dirY * launchSpeed)
  body:setAngle(atan2(dirY, dirX))

  local missile = world:newEntity()
      :give("physics_body", body, shape, fixture)
      -- Uses projectile renderer for now, or specific missile sprite
      :give("renderable", "projectile", { 1, 0.2, 0.2, 1 })
      :give("projectile", weapon.damage, weapon.projectileTtl or 5, ship, weapon.miningEfficiency)
      :give("missile", weapon.target, weapon.damage, weapon.missileSpeed, weapon.missileTurnRate, weapon.missileAccel,
        weapon.projectileTtl)
      :give("engine_trail", { 1, 0.5, 0, 0.8 }) -- Visual flair

  fixture:setUserData(missile)
  return true
end

local function spawnBeam(world, physicsWorld, ship, weapon, dirX, dirY)
  -- Beams are instant hitscan or continuous areas.
  -- For "Void Ray" style, we might want a persistent entity attached to ship?
  -- For now implementing simple "instant beam" visual + damage tick

  -- TODO: For continuous beams, we need a different architecture (hold to fire).
  -- This function is "fire once".
  -- Let's make it create a generic "laser_beam" entity that lives for a short time.

  local shipBody = ship.physics_body.body
  local sx, sy = shipBody:getPosition()
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
    if hitEntity:has("health") then
      hitEntity.health.current = hitEntity.health.current - weapon.damage
      world:emit("onDamageTaken", hitEntity, weapon.damage, ship)
    elseif hitEntity:has("asteroid") then
      -- Mining?
      world:emit("onAsteroidHit", hitEntity, weapon.damage, ship, weapon.miningEfficiency)
    end
  end

  -- visuals
  world:newEntity()
      :give("laser_beam", sx, sy, hitX, hitY, weapon.beamColor or { 1, 0, 1, 1 }, weapon.beamDuration or 0.1,
        weapon.beamWidth or 2)

  return true
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

function WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, targetX, targetY)
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
    return spawnBeam(world, physicsWorld, ship, weapon, dirX, dirY)
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

function WeaponLogic.fireAtTarget(world, physicsWorld, ship, weapon, target)
  if not WeaponLogic.isValidTarget(target) then
    return false
  end

  -- If homing, ensure target is set
  if weapon.type == "missile" then
    weapon.target = target
  end

  local tx, ty = target.physics_body.body:getPosition()
  return WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, tx, ty)
end

function WeaponLogic.fireAtPosition(world, physicsWorld, ship, weapon, worldX, worldY)
  -- Clear target if firing at position manually
  weapon.target = nil
  return WeaponLogic.fireWeapon(world, physicsWorld, ship, weapon, worldX, worldY)
end

return WeaponLogic
