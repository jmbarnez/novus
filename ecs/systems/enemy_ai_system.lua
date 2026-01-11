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
    if not body then
        return nil
    end
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
        local jitterRadius = brain.aimJitterRadius or 0
        if jitterRadius > 0 then
            brain._aimJitterTimer = (brain._aimJitterTimer or 0) - dt
            if not brain._aimJitterDX or not brain._aimJitterDY or brain._aimJitterTimer <= 0 then
                local angle = love.math.random() * math.pi * 2
                local radius = math.sqrt(love.math.random()) * jitterRadius -- sqrt for uniform disc
                brain._aimJitterDX = math.cos(angle) * radius
                brain._aimJitterDY = math.sin(angle) * radius
                brain._aimJitterTimer = brain.aimJitterHold or 0.35
            end
            predX = predX + brain._aimJitterDX
            predY = predY + brain._aimJitterDY
        end

        local dx = predX - ex
        local dy = predY - ey
        local dist = math.sqrt(dx * dx + dy * dy)

        -- Determine desired angle to face target
        local desiredAngle = atan2(dy, dx)
        local angleDiff = normalizeAngle(desiredAngle - eAngle)

        -- Decide behavior state
        -- Only react within detectionRange (>= engageRange).
        local detectionRange = brain.detectionRange or brain.engageRange

        if dist > detectionRange then
            brain.state = "idle"
        elseif dist > brain.engageRange then
            brain.state = "chase"
        else
            brain.state = "engage"
        end

        -- Default inputs
        local thrust = 0
        local turn = 0
        local brake = 0

        if brain.state == "idle" then
            -- Do nothing, maybe brake slowly if passing by
            e.ship_input.thrust = 0
            e.ship_input.turn = 0

            -- Optional: slow down if drifting
            local vx, vy = body:getLinearVelocity()
            if (vx * vx + vy * vy) > 10 then
                brake = 0.5
            end
        elseif brain.state == "chase" then
            -- Turn towards player and thrust
            if math.abs(angleDiff) > 0.05 then
                turn = clamp(angleDiff * 3, -1, 1)
            end

            -- Only thrust if facing roughly towards target
            if math.abs(angleDiff) < 0.5 then
                thrust = 1.0
            end

            -- Brake if we are going too fast or need to turn sharply?
            -- ship_control handles max speed, so full thrust is okay.
        elseif brain.state == "engage" then
            -- In range: face player but stop moving closer (or maintain distance)
            if math.abs(angleDiff) > 0.05 then
                turn = clamp(angleDiff * 2, -1, 1)
            end

            -- Brake to hold position or strafe?
            -- For now, brake to stop closure
            local vx, vy = body:getLinearVelocity()
            local speed = math.sqrt(vx * vx + vy * vy)
            if speed > 10 then
                brake = 1
            end

            -- Only FIRE if actually within reasonable weapon range (650)
            -- The brain.engageRange might be higher (e.g. 1000) for "approach" logic,
            -- but we only pull the trigger when close enough.
            if dist <= 650 and e:has("weapon") and physicsWorld then
                local weapon = e.weapon
                weapon.timer = math.max(0, (weapon.timer or 0) - dt)

                -- Fire if roughly facing target
                if math.abs(angleDiff) < weapon.coneHalfAngle then
                    WeaponLogic.fireAtTarget(self.world, physicsWorld, e, weapon, playerState.ship, dt)
                else
                    if weapon.type == "beam" then WeaponLogic.stopBeam(weapon) end
                end
            else
                -- Out of range or no weapon, ensure beam stops if it was active
                if e:has("weapon") then
                    local weapon = e.weapon
                    if weapon.type == "beam" then WeaponLogic.stopBeam(weapon) end
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
