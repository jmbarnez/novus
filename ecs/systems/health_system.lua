local Concord = require("lib.concord")
local Physics = require("ecs.util.physics")
local ExplosionFactory = require("game.factory.explosion_factory")

local HealthSystem = Concord.system({
  healths = { "health" },
  hulls = { "hull" }
})

function HealthSystem:init(world)
  self.world = world
end

function HealthSystem:update()
  -- Process Health (Asteroids, etc)
  for i = self.healths.size, 1, -1 do
    local e = self.healths[i]

    if e.health.current > e.health.max then
      e.health.current = e.health.max
    end

    if e.health.current <= 0 then
      if self.world and e:has("asteroid") and e:has("physics_body") and e.physics_body.body then
        local x, y = e.physics_body.body:getPosition()
        local r = (e.asteroid and e.asteroid.radius) or 30
        self.world:emit("onAsteroidDestroyed", e, x, y, r)
      end
      Physics.destroyPhysics(e)
      e:destroy()
    end
  end

  -- Process Hulls (Ships)
  for i = self.hulls.size, 1, -1 do
    local e = self.hulls[i]

    if e.hull.current > e.hull.max then
      e.hull.current = e.hull.max
    end

    if e.hull.current <= 0 then
      -- Check if this is the player's ship before destruction
      local player = self.world:getResource("player")
      local isPlayerShip = player and player.pilot and player.pilot.ship == e

      if isPlayerShip then
        -- Set resource flag for gamestate to detect and show death screen
        self.world:setResource("player_died", true)
      else
        -- Emit event for enemy ship destruction (rewards, quests)
        if e:has("physics_body") and e.physics_body.body then
          local x, y = e.physics_body.body:getPosition()
          self.world:emit("onShipDestroyed", e, x, y)
        end
      end

      if e:has("ship") and e:has("physics_body") and e.physics_body.body then
        -- EPIC EXPLOSION TRIGGER
        local x, y = e.physics_body.body:getPosition()
        local angle = e.physics_body.body:getAngle()
        local shape = e.physics_body.shape

        ExplosionFactory.createExplosion(self.world, x, y, angle, e, shape)
      end

      Physics.destroyPhysics(e)
      e:destroy()
    end
  end
end

return HealthSystem
