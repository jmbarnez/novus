--- Sector 01 Configuration
--- All positions are relative to sector size (0.0 to 1.0)
return {
    name = "Starting Sector",

    -- Sector dimensions
    width = 10000,
    height = 10000,

    -- Station placements
    stations = {
        {
            type = "hub",
            position = { x = 0.5, y = 0.5 }, -- sector center
        },
        {
            type = "refinery",
            position = { x = 0.65, y = 0.42 }, -- offset from hub
        },
    },

    -- Player spawn configuration
    player = {
        spawnOffset = { x = 650, y = 0 }, -- offset from first hub station
    },

    -- Asteroid field settings
    asteroids = {
        count = 70,
        avoidRadius = 650, -- safe radius around player spawn
    },

    -- Enemy spawn settings
    enemies = {
        count = 5,
        safeRadius = 800, -- can't spawn within this radius of stations
        variants = "random",
        -- Specific spawns for testing
        specific = {
            { id = "fly", count = 3 },
        },
    },
}
