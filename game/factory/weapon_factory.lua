local WeaponFactory = {}

-- Only allow these weapons; everything else falls back to vulcan_cannon.
local WEAPON_PATH = "game.weapons."
local ALLOWED = {
    vulcan_cannon = "vulcan_cannon",
    plasma_splitter = "plasma_splitter", -- scatter-shot
    mining_laser = "mining_laser",       -- continuous beam, good mining
    pulse_laser = "pulse_laser",         -- slow fire, high damage, short beam
}
local FALLBACK = "vulcan_cannon"

function WeaponFactory.create(entity, weaponName)
    weaponName = ALLOWED[weaponName] or FALLBACK

    local status, def = pcall(require, WEAPON_PATH .. weaponName)
    if not status then
        print("Error loading weapon: " .. weaponName .. " -> " .. tostring(def))
        return nil
    end

    entity:give("weapon", def)
    return entity
end

return WeaponFactory
