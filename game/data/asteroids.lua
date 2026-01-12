--- Asteroid generation configuration
return {
    -- Chance for an asteroid to have ore
    oreChance = 0.22,

    -- Resource composition percentages
    composition = {
        stone = { min = 60, max = 85 },
        mithrilChance = 0.35, -- chance to have any mithril
        mithrilMax = 15,
    },

    -- Shape generation parameters
    shape = {
        vertices = { min = 7, max = 8 },
        renderVertices = { min = 26, max = 40 },
        dentCount = { min = 2, max = 5 },
        dentWidth = { min = 0.18, max = 0.42 },
        dentDepth = { min = 0.06, max = 0.18 },
        squash = { min = 0.78, max = 1.22 },
    },

    -- Radius range when spawning
    radius = { min = 18, max = 46 },

    -- Physics properties
    physics = {
        linearDamping = 0.02,
        angularDamping = 0.01,
        restitution = 0.9,
        friction = 0.4,
        initialVelocity = { min = -8, max = 8 },
        initialAngularVelocity = { min = -0.12, max = 0.12 },
    },
}
