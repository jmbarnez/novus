return {
    name = "Mining Laser",
    type = "beam",
    -- Rapid ticks to appear continuous; beam duration slightly longer than cooldown.
    cooldown = 0.05,
    damage = 1,                         -- Per tick; ~20 DPS vs ships (reduced from 60)
    range = 600,
    beamColor = { 0.0, 1.0, 1.0, 0.9 }, -- Cyan
    beamWidth = 3,                      -- Thinner beam
    beamDuration = 0.02,                -- Disappear immediately on release
    miningEfficiency = 5.0,             -- Excellent at mining
    description = "Continuous mining beam with high efficiency.",
    icon = {
        kind = "poly",
        -- Mining beam emitter (pickaxe/tool shape)
        points = {
            0.5, 0.0,     -- beam tip
            0.2, -0.15,   -- top neck
            -0.2, -0.35,  -- handle top
            -0.45, -0.25, -- handle corner
            -0.45, 0.25,  -- handle corner
            -0.2, 0.35,   -- handle bottom
            0.2, 0.15,    -- bottom neck
        },
        shadow = { dx = 0.06, dy = 0.06, a = 0.4 },
        fillA = 0.95,
        outline = { a = 0.8, width = 1 },
        highlight = {
            kind = "polyline",
            points = { 0.35, 0.0, 0.55, 0.0 },
            a = 0.5,
            width = 3,
        },
    },
}
