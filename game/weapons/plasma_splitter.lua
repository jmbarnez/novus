return {
    name = "Plasma Splitter",
    type = "scatter",
    cooldown = 0.8,
    damage = 15,
    range = 600,

    -- Orb properties
    orbSpeed = 600,
    orbColor = { 0.4, 1.0, 0.2, 1 }, -- Bright green orb
    orbSize = 8,

    -- Explosion projectile properties
    projectileSpeed = 700,
    projectileTtl = 0.6,
    projectileColor = { 0.2, 1.0, 0.2, 1 }, -- Green fragments
    projectileSize = 4,
    scatterCount = { 6, 10 },               -- Random between 6 and 10 projectiles

    miningEfficiency = 1.2,
    description = "Fires an orb that explodes into plasma fragments at the target location.",
    icon = {
        kind = "circle",
        radius = 0.3,
        shadow = { dx = 0.06, dy = 0.06, a = 0.4 },
        fillA = 0.95,
        outline = { a = 0.8, width = 1 },
        -- Explosion rays radiating outward
        layers = {
            {
                kind = "polyline",
                points = { 0.35, 0.0, 0.55, 0.0 },
                a = 0.7,
                width = 2,
            },
            {
                kind = "polyline",
                points = { 0.25, 0.25, 0.4, 0.4 },
                a = 0.6,
                width = 2,
            },
            {
                kind = "polyline",
                points = { 0.0, 0.35, 0.0, 0.55 },
                a = 0.7,
                width = 2,
            },
            {
                kind = "polyline",
                points = { -0.25, 0.25, -0.4, 0.4 },
                a = 0.6,
                width = 2,
            },
        },
    },
}
