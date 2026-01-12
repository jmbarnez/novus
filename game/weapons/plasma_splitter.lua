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
    description = "Fires an orb that explodes into plasma fragments at the target location."
}
