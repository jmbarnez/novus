local Concord = require("lib.concord")
local WeaponLogic = require("ecs.systems.weapon_logic")
local WeaponDraw = require("ecs.systems.draw.weapon_draw")
local Math = require("util.math")

local max = math.max

local WeaponSystem = Concord.system({
  weapons = { "weapon", "physics_body" },
})

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function WeaponSystem:init(world)
  self.world = world
  self.input = world:getResource("input")
end

function WeaponSystem:drawWeaponCone(body, weapon)
  return WeaponDraw.drawWeaponCone(body, weapon)
end

--------------------------------------------------------------------------------
-- Target Selection (uses physics world query for efficiency)
--------------------------------------------------------------------------------

function WeaponSystem:findTargetAtPosition(worldX, worldY)
  -- Query physics world for efficiency
  local physics = self.world:getResource("physics")
  if not physics then return nil end

  local best = nil

  local callback = function(fixture)
    local e = fixture:getUserData()
    if e and WeaponLogic.isValidTarget(e) then
      -- refine check (point vs circle/shape test handled by callback trigger?)
      -- queryAABB is coarse.
      best = e
      return false -- Stop after first valid? or find best?
      -- For now just pick first valid
    end
    return true
  end

  -- Small box around mouse
  physics:queryBoundingBox(worldX - 5, worldY - 5, worldX + 5, worldY + 5, callback)

  return best
end

-- ... event handlers ...

function WeaponSystem:onTargetClick(worldX, worldY, button)
  if button ~= 1 then return end

  local uiCapture = self.world and self.world:getResource("ui_capture")
  if uiCapture and uiCapture.active then return end

  if not self.input:down("target_lock") then return end

  local player = self.world:getResource("player")
  if not player or not player:has("pilot") then return end

  local ship = player.pilot.ship
  if not ship or not ship:has("weapon") then return end

  local weapon = ship.weapon
  local target = self:findTargetAtPosition(worldX, worldY)
  weapon.target = target
end

function WeaponSystem:update(dt)
  -- We only really care about processing the PLAYER's weapon for input?
  -- Or existing `auto_cannon` logic which might be for player only?
  -- The previous code fetched `player` explicitly.

  local player = self.world:getResource("player")
  if not player or not player:has("pilot") then return end

  local uiCapture = self.world and self.world:getResource("ui_capture")
  if uiCapture and uiCapture.active then return end

  local physicsWorld = self.world:getResource("physics")
  if not physicsWorld then return end

  local ship = player.pilot.ship
  if not ship or not ship:has("weapon") or not ship:has("physics_body") then return end

  local weapon = ship.weapon

  -- Update timers
  weapon.timer = max(0, weapon.timer - dt)
  if weapon.coneVis then
    weapon.coneVis = max(0, weapon.coneVis - dt)
  end

  -- Validate current target (if any, used for homing or lock-on visualization)
  local target = weapon.target
  if target and not WeaponLogic.isValidTarget(target) then
    weapon.target = nil
    target = nil
  elseif target and weapon.range and weapon.range > 0 then
    local sx, sy = ship.physics_body.body:getPosition()
    local tx, ty = target.physics_body.body:getPosition()
    local dist2 = (tx - sx) ^ 2 + (ty - sy) ^ 2
    if dist2 > weapon.range * weapon.range then
      weapon.target = nil
      target = nil
    end
  end

  if self.input:down("fire") then
    if self.input:down("target_lock") then
      return
    end

    local mw = self.world:getResource("mouse_world")
    if mw then
      local hoverTarget = self:findTargetAtPosition(mw.x, mw.y)
      local targetToUse = nil
      local targetX, targetY = mw.x, mw.y

      -- Determine Target
      if WeaponLogic.isValidTarget(hoverTarget) then
        targetToUse = hoverTarget
        targetX, targetY = hoverTarget.physics_body.body:getPosition()
      elseif target and weapon.type == "missile" then
        targetToUse = target
        targetX, targetY = target.physics_body.body:getPosition()
      end

      -- If Beam, maintain it (Visual + Tick)
      if weapon.type == "beam" then
        WeaponLogic.maintainBeam(self.world, physicsWorld, ship, weapon, targetX, targetY, dt)
      elseif weapon.timer <= 0 then
        -- Conventional Fire
        if targetToUse then
          WeaponLogic.fireAtTarget(self.world, physicsWorld, ship, weapon, targetToUse)
        else
          WeaponLogic.fireAtPosition(self.world, physicsWorld, ship, weapon, targetX, targetY)
        end
      end
    end
  else
    -- Fire button released or not pressed
    if weapon.type == "beam" then
      WeaponLogic.stopBeam(weapon)
    end
  end

  -- Scale up cone visualization while right clicking
  if self.input:down("aim") then
    local mw = self.world:getResource("mouse_world")
    if mw then
      weapon.aimX = mw.x
      weapon.aimY = mw.y

      -- If we have a locked target, snap aim to it for visualization
      if target and target.physics_body and target.physics_body.body then
        weapon.aimX, weapon.aimY = target.physics_body.body:getPosition()
      end

      -- Calculate smoothed visual angle
      local sx, sy = ship.physics_body.body:getPosition()
      local sa = ship.physics_body.body:getAngle()
      local noseOffset = 12
      local startX = sx + math.cos(sa) * noseOffset
      local startY = sy + math.sin(sa) * noseOffset

      local dx = weapon.aimX - startX
      local dy = weapon.aimY - startY
      local aimAngle = Math.atan2(dy, dx)

      local diff = Math.angleDiff(aimAngle, sa)
      local clampedDiff = Math.clamp(diff, -weapon.coneHalfAngle, weapon.coneHalfAngle)
      local goalAngle = sa + clampedDiff

      if not weapon.visualAimAngle then
        weapon.visualAimAngle = goalAngle
      end

      -- Smoothly interpolate towards goal
      weapon.visualAimAngle = Math.lerpAngle(weapon.visualAimAngle, goalAngle, dt * 20)

      weapon.coneVis = weapon.coneVisHold
    end
  else
    weapon.coneVis = 0
    weapon.visualAimAngle = nil
  end
end

return WeaponSystem
