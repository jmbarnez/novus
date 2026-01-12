local Concord = require("lib.concord")

Concord.component("xp_orb", function(c, amount, phase, size)
  c.amount = amount or 1
  c.phase = phase or 0 -- Used for draw animation offset
  c.size = size or 6
end)

return true
