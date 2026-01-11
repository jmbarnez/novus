local Concord = require("lib.concord")

Concord.component("shield", function(c, max, regen)
  c.max = max or 50
  c.current = c.max
  c.regen = regen or 0
  c.fixture = nil -- Shield physics fixture (created by shield system)
  c.radius = 28   -- Shield radius (slightly larger than ship)
end)

return true
