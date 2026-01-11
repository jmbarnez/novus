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
    description = "Slow-firing high-speed pulse bolt."
}
