local Concord = require("lib.concord")

Concord.component("pickup", function(c, id, count)
  c.id = id
  c.count = count or 1
end)

return true
