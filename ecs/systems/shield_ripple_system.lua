local Concord = require("lib.concord")

local ShieldRippleSystem = Concord.system({
    pool = { "shield_hit" }
})

function ShieldRippleSystem:update(dt)
    for i = self.pool.size, 1, -1 do
        local e = self.pool[i]
        local shieldHit = e.shield_hit

        -- Update each hit's time and remove expired ones
        for j = #shieldHit.hits, 1, -1 do
            local hit = shieldHit.hits[j]
            hit.time = hit.time + dt

            if hit.time >= hit.duration then
                table.remove(shieldHit.hits, j)
            end
        end

        -- Remove component if no active hits remain
        if #shieldHit.hits == 0 then
            e:remove("shield_hit")
        end
    end
end

return ShieldRippleSystem
