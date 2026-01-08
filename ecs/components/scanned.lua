local Concord = require("lib.concord")

-- Marker component indicating an asteroid has been scanned
-- Added after target lock is held for sufficient duration
Concord.component("scanned", function(c)
    c.scannedAt = love.timer.getTime()
end)

return true
