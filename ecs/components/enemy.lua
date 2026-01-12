local Concord = require("lib.concord")

-- Accept either a faction string or a table { faction = ..., level = ... }
Concord.component("enemy", function(c, opts)
    if type(opts) == "table" then
        c.faction = opts.faction or "hostile"
        c.level = opts.level or 1
    else
        c.faction = opts or "hostile"
        c.level = 1
    end
end)

return true
