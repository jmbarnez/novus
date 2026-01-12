local Concord = require("lib.concord")

Concord.component("xp_orb", function(c, amount, phase)
  c.amount = amount or 1
  c.phase = phase or 0 -- Used for draw animation offset
end)

return true
