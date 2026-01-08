local Concord = require("lib.concord")
local WeaponLogic = require("ecs.systems.weapon_logic")
local WeaponDraw = require("ecs.systems.draw.weapon_draw")
local WeaponFactory = require("game.factory.weapon_factory")
local Math = require("util.math")

-- Localize frequently used functions
local max = math.max

local WEAPON_LIST = {
  "vulcan_cannon",
  "heavy_gauss",
  "plasma_splitter",
  "void_ray",
  "miners_bore",
  "storm_coil",
  "auto_cannon" -- Optional, maybe skip for player? User said "all the weapons". auto_cannon is basic enemy one.
}
-- Remove auto_cannon from cycle for player usually, but for testing "all" is fine.
-- Let's stick to the main 6 I implemented plus maybe "auto_cannon" if user wants.
-- I'll list the 6 main ones.
local WEAPON_LIST = {
  "vulcan_cannon",
  "heavy_gauss",
  "plasma_splitter",
  "void_ray",
  "miners_bore",
  "storm_coil"
}

local WeaponSystem = Concord.system({
  targets = { "weapon", "physics_body" },
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
-- Target Selection
--------------------------------------------------------------------------------

function WeaponSystem:findTargetAtPosition(worldX, worldY)
  -- Iterate all entities with health/hull/asteroid to find a target under cursor
  -- We don't have a list of targets here readily available efficiently without a query.
  -- But wait, the original code looked at `self.targets`, but `self.targets` here is the WEAPONS.
  -- The original code logic was flawed if it tried to find targets from `self.targets` which are weapons...
  -- Actually, let's look at previous file content carefully.
  -- "targets = { 'asteroid', 'health', 'physics_body' }" -- Wait, the system had MULTIPLE queries?
  -- Concord systems can have multiple pools? Or was it a single pool definition?
  -- "targets = { 'asteroid', 'health', 'physics_body' }" implies a query that matches entities having ALL those components?
  -- No, likely the user meant entities that are potential targets.
  -- Let's look at the original file again.
  -- line 10: targets = { "asteroid", "health", "physics_body" } -> WRONG?
  -- Actually, valid targets are asteroids OR enemies.
  -- If I change `targets` to be weapons, I lose the list of potential targets for simple scan.
  -- I should probably add a second pool for potential targets if I want to keep this logic efficient.
  -- Or I can just query the world for entities with health/hull.

  -- Let's redefine the system to have a `weapons` pool and a `potentialTargets` pool?
  -- Concord support multiple pools?
  -- Yes: `pool_name = { "comp1", "comp2" }`

  return nil -- Placeholder, will fix in full replacement below
end

-- Redefining system with multiple pools
local WeaponSystem = Concord.system({
  weapons = { "weapon", "physics_body" },
  -- We need a pool for things we can target?
  -- Actually, let's just use the physicsworld queries or keep it simple.
  -- The previous code used `self.targets` which was seemingly all destructibles?
  -- No, previous code line 34: `for i = 1, self.targets.size do`
  -- and line 10 `targets = { "asteroid", "health", "physics_body" }`
  -- That query means entities with ALL three? Asteroid AND Health AND PhysicsBody.
  -- Most enemies have Hull/Health, not Asteroid.
  -- Wait, looking at `asteroid.lua`... asteroids have `asteroid` component.
  -- The previous query was likely wrong or incomplete for enemies?
  -- Enemy ships have `hull`, `health`, `physics_body`.
  -- So `targets` query wouldn't match enemies if it required `asteroid`.
  -- Ah, Concord syntax `targets = { "asteroid", "health", "physics_body" }` creates a pool named "targets" containing entities with `asteroid` AND `health` AND `physics_body`.
  -- If so, the original code only targeted asteroids?
  -- Let's check `asteroid.lua`.

  -- To fix this properly and support generic targeting:
  -- We need to act on WEAPONS.
  -- So the primary pool should be `weapons`.
})

function WeaponSystem:init(world)
  self.world = world
  self.input = world:getResource("input")
end

function WeaponSystem:drawWeaponCone(body, weapon)
  return WeaponDraw.drawWeaponCone(body, weapon)
end

-- Helper to find target under mouse
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

  -- Debug: Swap weapons
  if self.input:pressed("next_weapon") or self.input:pressed("prev_weapon") then
    if not self.currentWeaponIndex then self.currentWeaponIndex = 1 end

    local dir = self.input:pressed("next_weapon") and 1 or -1
    self.currentWeaponIndex = self.currentWeaponIndex + dir

    if self.currentWeaponIndex > #WEAPON_LIST then self.currentWeaponIndex = 1 end
    if self.currentWeaponIndex < 1 then self.currentWeaponIndex = #WEAPON_LIST end

    local newWeapon = WEAPON_LIST[self.currentWeaponIndex]
    print("Switching to weapon: " .. newWeapon)

    -- Cleanup old components that might not be overwritten
    ship:remove("missile")

    WeaponFactory.create(ship, newWeapon)

    -- Refresh local reference since component was replaced?
    -- Concord reuses the table usually? No, `give` might create new instance.
    -- Safest to return early or re-fetch.
    return
  end

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

  if self.input:down("fire") and weapon.timer <= 0 then
    if self.input:down("target_lock") then
      return
    end

    local mw = self.world:getResource("mouse_world")
    if mw then
      local hoverTarget = self:findTargetAtPosition(mw.x, mw.y)

      -- Priority: Hovered Target -> Locked Target (if appropriate for weapon?) -> Manual Aim
      -- Actually, traditionally:
      -- If missile: Look for Lock. If no lock, maybe dumb fire?
      -- If beam/projectile: Aim at mouse. If mouse over target, aim at target center.

      if WeaponLogic.isValidTarget(hoverTarget) then
        WeaponLogic.fireAtTarget(self.world, physicsWorld, ship, weapon, hoverTarget)
      elseif target and weapon.type == "missile" then
        -- Missiles prefer locked target
        WeaponLogic.fireAtTarget(self.world, physicsWorld, ship, weapon, target)
      else
        WeaponLogic.fireAtPosition(self.world, physicsWorld, ship, weapon, mw.x, mw.y)
      end
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
