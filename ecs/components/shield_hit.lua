local Concord = require("lib.concord")

-- Tracks active shield hit ripples on an entity
-- Each hit stores: localX, localY (position relative to entity center), time, duration
Concord.component("shield_hit", function(c)
    c.hits = {}
end)

return true
