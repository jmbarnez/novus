local Concord = require("lib.concord")

-- Stores resource composition as an array of {id, pct} entries
-- Example: { {id="stone", pct=70}, {id="iron", pct=25}, {id="mithril", pct=5} }
Concord.component("asteroid_composition", function(c, resources)
    c.resources = resources or {}
end)

return true
