return {
    name = "Void Ray",
    type = "beam",
    -- To fake continuous, we use low cooldown.
    cooldown = 0.1,
    damage = 5,                         -- Per tick (0.1s) = 50 DPS
    range = 1200,
    beamColor = { 0.8, 0.0, 1.0, 0.8 }, -- Purple
    beamWidth = 5,
    beamDuration = 0.15,                -- Slightly longer than cooldown to smooth visuals
    miningEfficiency = 0.1,             -- Bad at mining
    description = "Purple energy beam that melts shields."
}
