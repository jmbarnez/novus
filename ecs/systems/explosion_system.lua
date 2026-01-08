local Concord = require("lib.concord")

local ExplosionSystem = Concord.system({
    pool = { "explosion" }
})

function ExplosionSystem:update(dt)
    for i = self.pool.size, 1, -1 do
        local e = self.pool[i]
        local c = e.explosion

        c.time = c.time + dt

        if c.time >= c.duration then
            e:destroy()
        end
    end
end

return ExplosionSystem
