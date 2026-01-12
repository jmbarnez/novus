return {
    name = "Pulse Laser",
    type = "projectile",
    cooldown = 0.8,                         -- Slower fire rate (was 0.5)
    damage = 25,                            -- Increased damage to compensate
    range = 800,                            -- Increased range
    projectileSpeed = 800,                  -- Faster projectile (was 550)
    projectileTtl = 1.0,
    projectileColor = { 0.2, 1.0, 1.0, 1 }, -- Cyan pulse bolt
    projectileSize = 1.2,
    coneHalfAngle = math.rad(2),
    miningEfficiency = 0.3,
    description = "Slow-firing high-speed pulse bolt.",
    icon = {
        kind = "poly",
        -- Laser bolt shape (pointed projectile)
        points = {
            0.55, 0.0,   -- tip
            0.1, -0.2,   -- top edge
            -0.5, -0.12, -- back top
            -0.45, 0.0,  -- back center
            -0.5, 0.12,  -- back bottom
            0.1, 0.2,    -- bottom edge
        },
        shadow = { dx = 0.06, dy = 0.06, a = 0.4 },
        fillA = 0.95,
        outline = { a = 0.8, width = 1 },
        highlight = {
            kind = "polyline",
            points = { 0.4, 0.0, -0.2, 0.0 },
            a = 0.4,
            width = 2,
        },
    },
}
