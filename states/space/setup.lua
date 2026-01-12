--- Space state setup module
--- Handles ECS world initialization and sector spawning
local Concord = require("lib.concord")
local Systems = require("ecs.systems")
local factory = require("game.factory")
local Sound = require("game.sound")

local SpaceSetup = {}

--- Setup ECS world with all resources and systems
---@param state table The Space state object
---@param sectorConfig table Sector configuration
function SpaceSetup.setupEcsWorld(state, sectorConfig)
    state.ecsWorld = Concord.world()
    state.ecsWorld:setResource("input", state.input)
    state.ecsWorld:setResource("sector", {
        width = state.sectorWidth,
        height = state.sectorHeight,
        x = state.currentSector.x,
        y = state.currentSector.y,
        originX = state.sectorOriginX,
        originY = state.sectorOriginY,
    })
    state.ecsWorld:setResource("physics", state.physicsWorld)
    state.ecsWorld:setResource("mouse_world", state.mouseWorld)
    state.ecsWorld:setResource("ui_capture", { active = false })
    state.ecsWorld:setResource("map_ui",
        { open = false, zoom = 1.0, centerX = nil, centerY = nil, waypointX = nil, waypointY = nil })
    state.ecsWorld:setResource("world_seed", state.worldSeed)
    state.ecsWorld:setResource("world_rngs", state.worldRngs)
    state.ecsWorld:setResource("station_ui", require("game.hud.station_state").new())
    state.ecsWorld:setResource("refinery_ui", require("game.hud.refinery_state").new())
    state.ecsWorld:setResource("player_died", false)

    state.ecsWorld:addSystems(
        Systems.PhysicsSnapshotSystem,
        Systems.InputSystem,
        Systems.TargetingSystem,
        Systems.ShipControlSystem,
        Systems.ContactFlashSystem,
        Systems.ProjectileHitSystem,
        Systems.HitFlashSystem,
        Systems.EngineTrailSystem,
        Systems.WeaponSystem,
        Systems.HealthSystem,
        Systems.ProjectileSystem,
        Systems.PickupSystem,
        Systems.MagnetSystem,
        Systems.ShatterSystem,
        Systems.RenderSystem,
        Systems.FloatingTextSystem,
        Systems.HudSystem,
        Systems.QuestSystem,
        Systems.RefinerySystem,
        Systems.SoundSystem,
        Systems.EnemyAISystem,
        Systems.ExplosionSystem,
        Systems.ShieldRippleSystem
    )

    state.ecsWorld.__profiler = state.profiler.concord

    -- Assign profile names to all registered systems
    for name, systemClass in pairs(Systems) do
        local s = state.ecsWorld:getSystem(systemClass)
        if s then s.__profileName = name end
    end

    state.hudSystem = state.ecsWorld:getSystem(Systems.HudSystem)
end

--- Spawn sector contents (stations, player, asteroids, enemies)
---@param state table The Space state object
---@param sectorConfig table Sector configuration
function SpaceSetup.spawnSectorContents(state, sectorConfig)
    factory.createWalls(state.physicsWorld, state.sectorWidth, state.sectorHeight)

    -- Create stations from config
    local hubX, hubY
    for _, stationDef in ipairs(sectorConfig.stations) do
        local stationX = stationDef.position.x * state.sectorWidth
        local stationY = stationDef.position.y * state.sectorHeight

        if stationDef.type == "hub" then
            state.spaceStation = factory.createSpaceStation(state.ecsWorld, state.physicsWorld, stationX, stationY, "hub")
            hubX, hubY = stationX, stationY
        elseif stationDef.type == "refinery" then
            state.refineryStation = factory.createRefineryStation(state.ecsWorld, state.physicsWorld, stationX, stationY)
        end
    end

    -- Player spawn relative to hub station
    hubX = hubX or sectorConfig.stations[1].position.x * state.sectorWidth
    hubY = hubY or sectorConfig.stations[1].position.y * state.sectorHeight
    state.spawnX = hubX + sectorConfig.player.spawnOffset.x
    state.spawnY = hubY + sectorConfig.player.spawnOffset.y

    state.ship = factory.createShip(state.ecsWorld, state.physicsWorld, state.spawnX, state.spawnY)
    state.player = factory.createPlayer(state.ecsWorld, state.ship)
    state.ecsWorld:setResource("player", state.player)

    -- Spawn asteroids
    local shipBody = state.ship.physics_body and state.ship.physics_body.body
    local avoidX, avoidY = shipBody:getPosition()
    factory.spawnAsteroids(
        state.ecsWorld, state.physicsWorld,
        sectorConfig.asteroids.count,
        state.sectorWidth, state.sectorHeight,
        avoidX, avoidY,
        sectorConfig.asteroids.avoidRadius,
        state.worldRngs.asteroids
    )

    -- Spawn enemies
    local enemySafeRadius = sectorConfig.enemies.safeRadius

    -- Helper to find a safe spawn position
    local function getSafeEnemySpawn()
        local ex, ey
        repeat
            ex = love.math.random(0, state.sectorWidth)
            ey = love.math.random(0, state.sectorHeight)
            local dx = ex - hubX
            local dy = ey - hubY
            local distSq = dx * dx + dy * dy
        until distSq > enemySafeRadius * enemySafeRadius
        return ex, ey
    end

    -- Spawn specific enemies if defined
    if sectorConfig.enemies.specific then
        for _, spec in ipairs(sectorConfig.enemies.specific) do
            for _ = 1, spec.count do
                local ex, ey = getSafeEnemySpawn()
                factory.createEnemyShip(state.ecsWorld, state.physicsWorld, ex, ey, { id = spec.id })
            end
        end
    end

    -- Spawn random enemies
    for _ = 1, sectorConfig.enemies.count do
        local ex, ey = getSafeEnemySpawn()
        factory.createEnemyShip(state.ecsWorld, state.physicsWorld, ex, ey, { random = true })
    end

    -- Initialize sound
    Sound.load()
    Sound.playMusic("space_ambient1")
end

return SpaceSetup
