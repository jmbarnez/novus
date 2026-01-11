local enemy_ship = {}

local WeaponFactory = require("game.factory.weapon_factory")

function enemy_ship.createEnemyShip(ecsWorld, physicsWorld, x, y, opts)
    -- ... (opts) ...
    opts = opts or {}

    local body = love.physics.newBody(physicsWorld, x, y, "dynamic")
    body:setLinearDamping(0.5)
    body:setAngularDamping(6.0)
    body:setBullet(true)

    local shape = love.physics.newPolygonShape(
        12, 0,
        6, 5,
        0, 10,
        -10, 5,
        -12, 0,
        -10, -5,
        0, -10,
        6, -5
    )

    local fixture = love.physics.newFixture(body, shape, 1)
    fixture:setDensity(4)
    body:resetMassData()
    fixture:setRestitution(0.2)
    fixture:setFriction(0.4)

    -- Enemy collision category (3)
    fixture:setCategory(3)

    -- Red-tinted color to distinguish from player
    local color = opts.color or { 1.0, 0.4, 0.4, 1.0 }

    local e = ecsWorld:newEntity()
        :give("physics_body", body, shape, fixture)
        :give("renderable", "ship", color)
        :give("ship")
        :give("ship_control", {
            thrustForce = opts.thrustForce or 35,
            strafeForce = opts.strafeForce or 20,
            rcsPower = opts.rcsPower or 160,
            stabilization = 1.0,
            brakeDamping = 0.5,
            maxLinearSpeed = 250,
        })
        :give("ship_input")
        :give("enemy", opts.faction or "hostile")
        :give("ai_brain", {
            engageRange = opts.engageRange or 650,
            predictionTime = opts.predictionTime or 0.5,
            turnThresholdDeg = opts.turnThresholdDeg or 30,
        })
        -- Remove auto_cannon
        :give("engine_trail", {
            offsetX = -12,
            offsetY = 0,
            color = { 1.0, 0.3, 0.1, 0.95 },
        })
        :give("hull", opts.hull or 50)

    -- Equip weapon (default to pulse laser if not specified)
    WeaponFactory.create(e, opts.weapon or "pulse_laser")

    fixture:setUserData(e)

    return e
end

return enemy_ship
