local Concord = require("lib.concord")
local EntityUtil = require("ecs.util.entity")

local ContactFlashSystem = Concord.system()

-- Spawn shield ripple effect at collision point for an entity with a shield
local function trySpawnShieldRipple(entity, contact)
  if not EntityUtil.isAliveAndHas(entity, "shield") then
    return
  end

  local shield = entity.shield
  if shield.current <= 0 then
    return
  end

  if not entity:has("physics_body") or not entity.physics_body.body then
    return
  end

  local body = entity.physics_body.body
  local tx, ty = body:getPosition()
  local angle = body:getAngle()

  -- Get contact world position
  local x1, y1, x2, y2 = contact:getPositions()
  local impactX = x1 or tx
  local impactY = y1 or ty

  -- Convert to local coordinates relative to entity
  local dx = impactX - tx
  local dy = impactY - ty
  local cosA = math.cos(-angle)
  local sinA = math.sin(-angle)
  local localX = dx * cosA - dy * sinA
  local localY = dx * sinA + dy * cosA

  -- Add hit to shield_hit component
  entity:ensure("shield_hit")
  table.insert(entity.shield_hit.hits, {
    localX = localX,
    localY = localY,
    time = 0,
    duration = 0.4
  })
end

function ContactFlashSystem:onContact(a, b, contact)
  if EntityUtil.isAliveAndHas(a, "renderable") then
    a:ensure("hit_flash")
    a.hit_flash.t = a.hit_flash.duration
  end

  if EntityUtil.isAliveAndHas(b, "renderable") then
    b:ensure("hit_flash")
    b.hit_flash.t = b.hit_flash.duration
  end

  -- Spawn shield ripple for physical collisions
  trySpawnShieldRipple(a, contact)
  trySpawnShieldRipple(b, contact)
end

return ContactFlashSystem
