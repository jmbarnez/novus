local Concord = require("lib.concord")

Concord.component("reward_orb", function(c, kind, amount, phase)
  c.kind = kind or "xp"        -- "credits" | "xp"
  c.amount = amount or 1
  c.phase = phase or 0         -- Used for draw animation offset
end)

return true
