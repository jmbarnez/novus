local Concord = require("lib.concord")

Concord.component("missile", function(c, target, damage, speed, turnRate, accel, duration)
    c.target = target -- Entity or nil
    c.damage = damage or 10

    c.speed = speed or 400
    c.maxSpeed = speed or 800
    c.currentSpeed = 0 -- Start slow?

    c.turnRate = turnRate or 2
    c.accel = accel or 500

    c.duration = duration or 3.0
    c.timer = 0
end)

return true
