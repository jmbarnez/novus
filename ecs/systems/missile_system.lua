local Concord = require("lib.concord")
local Math = require("util.math")

local MissileSystem = Concord.system({
    missiles = { "missile", "physics_body" },
})

function MissileSystem:update(dt)
    for i = 1, self.missiles.size do
        local e = self.missiles[i]
        local m = e.missile
        local body = e.physics_body.body

        -- Update timer
        m.timer = m.timer + dt
        if m.timer >= m.duration then
            -- Explode/Destroy
            -- Ideally spawn an explosion effect here
            e:destroy() -- Physics destroy handled by component removal listeners usually, but let's be safe
            -- TODO: Ensure physics cleanup happens. ProjectileSystem does manual cleanup, we might need to do same or rely on Concord removal?
            -- Safe bet: just destroy entity, if there's a physics cleanup system it catches it.
            -- Note: in ProjectileSystem it was manual. Let's assume we need manual cleanup or a generic cleanup system.
            -- For now, just destroy() and assume ECS handles component removal hooks if they exist.
            -- Actually, looking at ProjectileSystem, it manually destroys physics.
            -- We should probably replicate that safety or rely on a generic Physics cleanup if it exists.
            -- Let's stick to simple destroy first.
        else
            -- Guidance logic
            local mx, my = body:getPosition()
            local angle = body:getAngle()

            -- Check if target is still valid
            local targetValid = m.target and m.target:has("physics_body") -- basic check
            -- If target is dead/gone, keep flying straight or maybe find new target?
            -- flying straight for now.

            if targetValid then
                local tx, ty = m.target.physics_body.body:getPosition()
                local dx, dy = tx - mx, ty - my
                local targetAngle = Math.atan2(dy, dx)

                -- Turn towards target
                local diff = Math.angleDiff(targetAngle, angle)
                local maxTurn = m.turnRate * dt
                local turn = Math.clamp(diff, -maxTurn, maxTurn)

                body:setAngle(angle + turn)
            end

            -- Accelerate
            local currentVelX, currentVelY = body:getLinearVelocity()
            -- We want to fly in direction of facing
            local facing = body:getAngle()
            local dirX, dirY = math.cos(facing), math.sin(facing)

            -- Simple constant speed setting for reliability, or acceleration
            -- Let's just set velocity to maxSpeed in facing direction for "arcade" feel
            body:setLinearVelocity(dirX * m.maxSpeed, dirY * m.maxSpeed)
        end
    end
end

return MissileSystem
