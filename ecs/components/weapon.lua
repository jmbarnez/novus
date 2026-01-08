local Concord = require("lib.concord")

Concord.component("weapon", function(c, def)
    c.type = def.type or "projectile" -- projectile, beam, missile

    -- Generics
    c.cooldown = def.cooldown or 0.5
    c.timer = 0
    c.range = def.range or 1000
    c.damage = def.damage or 10
    c.spread = def.spread or 0
    c.count = def.count or 1
    c.miningEfficiency = def.miningEfficiency or 1.0

    -- Cone / Aiming
    c.coneHalfAngle = def.coneHalfAngle or math.rad(15)
    c.coneVis = 0
    c.coneVisHold = 0.5
    c.coneVisFade = 0.5
    c.aimX = 0
    c.aimY = 0

    -- Projectile Specific
    c.projectileSpeed = def.projectileSpeed or 800
    c.projectileTtl = def.projectileTtl or 1.5
    c.projectileColor = def.projectileColor or { 1, 1, 1, 1 }
    c.projectileSize = def.projectileSize or 3

    -- Missile Specific
    c.missileSpeed = def.missileSpeed or 600
    c.missileTurnRate = def.missileTurnRate or 5
    c.missileAccel = def.missileAccel or 800
    c.missileSprite = def.missileSprite -- if string, load texture?

    -- Beam Specific
    c.beamDuration = def.beamDuration or 0.1
    c.beamWidth = def.beamWidth or 4
    c.beamColor = def.beamColor or { 1, 0, 1, 1 }

    c.target = nil
end)

return true
