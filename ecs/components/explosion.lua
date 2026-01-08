local Concord = require("lib.concord")

Concord.component("explosion", function(c, canvas, duration)
    c.canvas = canvas
    c.duration = duration or 1.0
    c.time = 0
end)

return true
