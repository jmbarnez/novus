return {
    name = "Plasma Splitter",
    type = "projectile",
    cooldown = 0.8,
    damage = 15,
    range = 600,
    projectileSpeed = 900,
    projectileTtl = 0.8,
    projectileColor = { 0.2, 1.0, 0.2, 1 }, -- Green
    projectileSize = 4,
    coneHalfAngle = math.rad(25),         -- Wide
    count = 5,                            -- Shotgun (Need to implement 'count' logic in WeaponLogic or here?)
    -- 'count' wasn't explicitly handled in WeaponLogic yet! I need to fix that or trust spread logic?
    -- I'll implement proper multi-shot support in WeaponLogic briefly or use a loop there.
    -- For now defining it here.
    spread = math.rad(20),
    miningEfficiency = 1.2,
    description = "Wide spread plasma bursts."
}
