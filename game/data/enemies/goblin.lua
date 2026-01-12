-- Goblin scout enemy ship definition
return {
    id = "goblin",
    label = "Goblin (scout)",

    -- Visual/geometry/physics design
    design = {
        -- Polygon points defining the ship hull (clockwise)
        shape = {
            9, 0,
            5, 4,
            0, 8,
            -8, 4,
            -9, 0,
            -8, -4,
            0, -8,
            5, -4,
        },
        body = {
            linearDamping = 0.55,
            angularDamping = 6.0,
            bullet = true,
        },
        fixture = {
            density = 3.5,
            restitution = 0.25,
            friction = 0.4,
            category = 3, -- enemy collision category
        },
    },

    color = { 0.3, 0.85, 0.35, 1.0 },      -- green hull
    accentColor = { 0.2, 0.6, 0.25, 1.0 }, -- darker green accent
    engineTrailColor = { 0.25, 0.95, 0.35, 0.95 },

    -- Ship handling
    thrustForce = 24,
    strafeForce = 16,
    rcsPower = 140,
    stabilization = 1.05,
    brakeDamping = 0.55,
    maxLinearSpeed = 175,

    -- Survivability
    hull = 50,
    level = 1,

    -- AI tuning
    engageRange = 600,
    detectionRange = nil,
    predictionTime = 0.5,
    turnThresholdDeg = 30,
    aimJitterRadius = nil,
    aimJitterHold = nil,

    -- Loadout
    weapon = "pulse_laser",
    weaponOverrides = {
        damage = 16,                              -- reduced damage
        projectileColor = { 0.2, 1.0, 0.3, 1.0 }, -- green bolts
    },
    faction = "hostile",

    -- Loot drops on death
    lootTable = {
        { id = "credits", countMin = 5, countMax = 15, chance = 0.9 },
        { id = "iron",    countMin = 1, countMax = 3,  chance = 0.3 },
    },
}
