local Concord = require("lib.concord")

-- Tracks equipped weapons and active slot for hotbar
Concord.component("weapon_loadout", function(c, slots, activeSlot)
    -- Array of weapon IDs (strings like "pulse_laser", "mining_laser")
    -- nil entries represent empty slots
    c.slots = slots or {}
    c.activeSlot = activeSlot or 1
    c.maxSlots = 5
end)

return true
