local Concord = require("lib.concord")

Concord.component("ai_brain", function(c, opts)
    opts = opts or {}
    c.state = opts.state or "pursue"
    c.engageRange = opts.engageRange or 300               -- Distance to stop pursuit
    -- Detection should be at least engage range; allow a small configurable buffer
    local detectionBuffer = opts.detectionBuffer
    if detectionBuffer == nil then
        detectionBuffer = 100
    end
    c.detectionRange = opts.detectionRange or (c.engageRange + detectionBuffer)
    c.predictionTime = opts.predictionTime or 0.5         -- Seconds ahead to predict player position
    c.turnThreshold = math.rad(opts.turnThresholdDeg or 30) -- Angle within which to thrust
    -- Aim inaccuracy: small positional jitter to predicted target to keep enemies imperfect
    c.aimJitterRadius = opts.aimJitterRadius or 60        -- max offset in pixels
    c.aimJitterHold = opts.aimJitterHold or 0.35          -- seconds before refreshing jitter
end)

return true
