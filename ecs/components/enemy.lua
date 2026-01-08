local Concord = require("lib.concord")

Concord.component("enemy", function(c, faction)
    c.faction = faction or "hostile"
end)

return true
