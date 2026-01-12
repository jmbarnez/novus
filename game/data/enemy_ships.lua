local EnemyShipDefs = {}

-- List of enemy ship designs. Add/edit here to tweak stats or add new ships.
-- Weapon names must be allowed by game.factory.weapon_factory.
EnemyShipDefs.list = {
    goblin = {
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

        renderable = { color = { 0.9, 0.25, 0.25, 1.0 }, accent = { 0.3, 0.9, 0.35, 1.0 } }, -- red/green
        engineTrail = {
            offsetX = -12,
            offsetY = 0,
            color = { 0.25, 0.95, 0.35, 0.95 },
        },

        -- Ship handling
        thrustForce = 28,
        strafeForce = 16,
        rcsPower = 140,
        stabilization = 1.05,
        brakeDamping = 0.55,
        maxLinearSpeed = 220,

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
            damage = 16, -- reduced damage
            projectileColor = { 0.2, 1.0, 0.3, 1.0 }, -- green bolts
        },
        faction = "hostile",
    },
}

EnemyShipDefs.defaultId = "goblin"

function EnemyShipDefs.pickRandomId(rng)
    rng = rng or love.math
    local keys = {}
    for id in pairs(EnemyShipDefs.list) do
        table.insert(keys, id)
    end
    return keys[rng.random(#keys)]
end

function EnemyShipDefs.all()
    return EnemyShipDefs.list
end

return EnemyShipDefs
