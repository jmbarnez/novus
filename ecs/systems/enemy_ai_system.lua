local Concord = require("lib.concord")
local Math = require("util.math")
local WeaponLogic = require("ecs.systems.weapon_logic")

local EnemyAISystem = Concord.system({
    enemies = { "enemy", "ai_brain", "ship_input", "physics_body" },
})

local atan2 = Math.atan2
local normalizeAngle = Math.normalizeAngle
local clamp = Math.clamp

function EnemyAISystem:init(world)
    self.world = world
end

-- Get player ship position and velocity
function EnemyAISystem:_getPlayerState()
    local player = self.world:getResource("player")
    if not player or not player:has("pilot") then
        return nil
    end

    local ship = player.pilot.ship
    if not ship or not ship:has("physics_body") then
        return nil
    end

    local body = ship.physics_body.body
    local x, y = body:getPosition()
    local vx, vy = body:getLinearVelocity()

    return { x = x, y = y, vx = vx, vy = vy, ship = ship }
end

function EnemyAISystem:fixedUpdate(dt)
    local playerState = self:_getPlayerState()
    if not playerState then
        -- No player, idle all enemies
        for i = 1, self.enemies.size do
            local e = self.enemies[i]
            e.ship_input.thrust = 0
            e.ship_input.turn = 0
            e.ship_input.strafe = 0
            e.ship_input.brake = 0
        end
        return
    end

    local physicsWorld = self.world:getResource("physics")

    for i = 1, self.enemies.size do
        local e = self.enemies[i]
        local brain = e.ai_brain
        local body = e.physics_body.body

        local ex, ey = body:getPosition()
        local eAngle = body:getAngle()

        -- Predict where the player will be
        local predX = playerState.x + playerState.vx * brain.predictionTime
        local predY = playerState.y + playerState.vy * brain.predictionTime

        local dx = predX - ex
        local dy = predY - ey
        local dist = math.sqrt(dx * dx + dy * dy)

        -- Determine desired angle to face target
        local desiredAngle = atan2(dy, dx)
        local angleDiff = normalizeAngle(desiredAngle - eAngle)

        -- Decide behavior state
        if dist <= brain.engageRange then
            brain.state = "engage"
        else
            brain.state = "pursue"
        end

        -- Default inputs
        local thrust = 0
        local turn = 0
        local brake = 0

        if brain.state == "pursue" then
            -- Turn toward predicted position
            if math.abs(angleDiff) > 0.05 then
                turn = clamp(angleDiff * 2, -1, 1)
            end

            -- Only thrust if roughly facing target
            if math.abs(angleDiff) < brain.turnThreshold then
                thrust = 1
            end
        elseif brain.state == "engage" then
            -- In range: face player but stop moving closer
            if math.abs(angleDiff) > 0.05 then
                turn = clamp(angleDiff * 2, -1, 1)
            end

            -- Brake to hold position
            local vx, vy = body:getLinearVelocity()
            local speed = math.sqrt(vx * vx + vy * vy)
            if speed > 10 then
                brake = 1
            end

            -- Fire weapon if facing target and have weapon
            if e:has("auto_cannon") and physicsWorld then
                local weapon = e.auto_cannon
                weapon.timer = math.max(0, (weapon.timer or 0) - dt)

                -- Fire if roughly facing target
                if math.abs(angleDiff) < weapon.coneHalfAngle then
                    WeaponLogic.fireAtTarget(self.world, physicsWorld, e, weapon, playerState.ship)
                end
            end
        end

        e.ship_input.thrust = thrust
        e.ship_input.turn = turn
        e.ship_input.strafe = 0
        e.ship_input.brake = brake
    end
end

return EnemyAISystem
