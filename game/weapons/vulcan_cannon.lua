return {
    name = "Vulcan Cannon",
    type = "projectile",
    cooldown = 0.18,
    damage = 8,
    range = 1000,
    projectileSpeed = 700,
    projectileTtl = 1.0,
    projectileColor = { 1, 0.6, 0.2, 1 }, -- Orange
    projectileSize = 1.0,
    coneHalfAngle = math.rad(5),
    miningEfficiency = 0.5,
    description = "High rate of fire kinetic weapon.",
    icon = {
        kind = "poly",
        -- Gatling gun barrels shape (side view)
        points = {
            -0.5, -0.35, -- back top
            0.5, -0.2,   -- front top
            0.55, 0.0,   -- tip
            0.5, 0.2,    -- front bottom
            -0.5, 0.35,  -- back bottom
            -0.55, 0.0,  -- back center
        },
        shadow = { dx = 0.06, dy = 0.06, a = 0.4 },
        fillA = 0.95,
        outline = { a = 0.8, width = 1 },
        -- Barrel lines detail
        highlight = {
            kind = "polyline",
            points = { -0.3, -0.15, 0.35, -0.08, -0.3, 0.15, 0.35, 0.08 },
            a = 0.25,
            width = 1,
        },
    },
}
