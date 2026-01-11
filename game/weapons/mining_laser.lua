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
    description = "Continuous mining beam with high efficiency."
}
