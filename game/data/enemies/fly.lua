-- Fly enemy ship definition - fast and shielded
return {
    id = "fly",
    label = "Fly (interceptor)",

    -- Visual/geometry/physics design - smaller, sleek shape
    design = {
        shape = {
            8, 0,
            4, 3,
            0, 5,
            -6, 3,
            -7, 0,
            -6, -3,
            0, -5,
            4, -3,
        },
        body = {
            linearDamping = 0.4,  -- less drag for speed
            angularDamping = 5.0, -- more agile turning
            bullet = true,
        },
        fixture = {
            density = 2.5, -- lighter for speed
            restitution = 0.3,
            friction = 0.3,
            category = 3,
        },
    },

    color = { 0.3, 0.7, 0.95, 1.0 },      -- light blue hull
    accentColor = { 0.2, 0.5, 0.8, 1.0 }, -- darker blue accent
    engineTrailColor = { 0.4, 0.8, 1.0, 0.95 },

    -- Fast ship handling
    thrustForce = 55,
    strafeForce = 35,
    rcsPower = 180,
    stabilization = 0.9,
    brakeDamping = 0.4,
    maxLinearSpeed = 320,

    -- Survivability - lower hull but has shields
    hull = 30,
    shield = 50,     -- shield capacity
    shieldRegen = 2, -- regeneration per second
    shieldRadius = 20,
    level = 2,

    -- AI tuning - aggressive interceptor behavior
    engageRange = 550,
    detectionRange = nil,
    predictionTime = 0.4,
    turnThresholdDeg = 25,
    aimJitterRadius = nil,
    aimJitterHold = nil,

    -- Loadout
    weapon = "pulse_laser",
    weaponOverrides = {
        damage = 12,
        fireRate = 8, -- faster firing
        projectileSpeed = 750,
        projectileColor = { 0.3, 0.8, 1.0, 1.0 },
    },
    faction = "hostile",

    -- Loot drops on death
    lootTable = {
        { id = "credits", countMin = 8, countMax = 20, chance = 0.95 },
        { id = "copper",  countMin = 1, countMax = 2,  chance = 0.25 },
    },
}
