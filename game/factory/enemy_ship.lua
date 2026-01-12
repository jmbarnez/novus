local enemy_ship = {}

local WeaponFactory = require("game.factory.weapon_factory")
local EnemyShipDefs = require("game.data.enemy_ships")

function enemy_ship.createEnemyShip(ecsWorld, physicsWorld, x, y, opts)
    opts = opts or {}

    -- Select definition
    local defId
    if opts.random then
        defId = EnemyShipDefs.pickRandomId(opts.rng)
    else
        defId = opts.id or opts.variant or EnemyShipDefs.defaultId
    end
    local def = EnemyShipDefs.list[defId] or EnemyShipDefs.list[EnemyShipDefs.defaultId]

    local function val(key, fallback)
        if opts[key] ~= nil then return opts[key] end
        if def and def[key] ~= nil then return def[key] end
        return fallback
    end

    local design = val("design", {}) or {}
    local designBody = design.body or {}
    local designFixture = design.fixture or {}
    local shapePoints = (design.shape and type(design.shape) == "table" and #design.shape >= 6) and design.shape or {
        12, 0,
        6, 5,
        0, 10,
        -10, 5,
        -12, 0,
        -10, -5,
        0, -10,
        6, -5,
    }

    local body = love.physics.newBody(physicsWorld, x, y, "dynamic")
    body:setLinearDamping(designBody.linearDamping or 0.5)
    body:setAngularDamping(designBody.angularDamping or 6.0)
    body:setBullet(designBody.bullet ~= false) -- default true

    local shape = love.physics.newPolygonShape(shapePoints)

    local fixture = love.physics.newFixture(body, shape, 1)
    fixture:setDensity(designFixture.density or 4)
    body:resetMassData()
    fixture:setRestitution(designFixture.restitution or 0.2)
    fixture:setFriction(designFixture.friction or 0.4)

    -- Enemy collision category (3)
    fixture:setCategory(designFixture.category or 3)

    local color = val("color", { 1.0, 0.4, 0.4, 1.0 })
    local accentColor = val("accentColor", nil)

    local e = ecsWorld:newEntity()
        :give("physics_body", body, shape, fixture)
        :give("renderable", "ship", { primary = color, accent = accentColor or color })
        :give("ship")
        :give("ship_control", {
            thrustForce = val("thrustForce", 35),
            strafeForce = val("strafeForce", 20),
            rcsPower = val("rcsPower", 160),
            stabilization = val("stabilization", 1.0),
            brakeDamping = val("brakeDamping", 0.5),
            maxLinearSpeed = val("maxLinearSpeed", 250),
        })
        :give("ship_input")
        :give("enemy", {
            faction = val("faction", "hostile"),
            level = val("level", 1),
        })
        :give("ai_brain", {
            engageRange = val("engageRange", 650),
            detectionRange = val("detectionRange", nil),
            predictionTime = val("predictionTime", 0.5),
            turnThresholdDeg = val("turnThresholdDeg", 30),
            aimJitterRadius = val("aimJitterRadius", nil),
            aimJitterHold = val("aimJitterHold", nil),
        })
        :give("engine_trail", {
            offsetX = -12,
            offsetY = 0,
            color = val("engineTrailColor", { 1.0, 0.3, 0.1, 0.95 }),
        })
        :give("hull", val("hull", 50))

    -- Equip weapon (default to pulse laser if not specified)
    WeaponFactory.create(e, val("weapon", "pulse_laser"), val("weaponOverrides", nil))

    fixture:setUserData(e)

    return e
end

return enemy_ship
