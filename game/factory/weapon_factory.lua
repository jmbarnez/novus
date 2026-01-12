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

-- Optional overrides lets callers tweak a loaded weapon definition (damage, colors, etc.)
function WeaponFactory.create(entity, weaponName, overrides)
    weaponName = ALLOWED[weaponName] or FALLBACK

    local status, def = pcall(require, WEAPON_PATH .. weaponName)
    if not status then
        print("Error loading weapon: " .. weaponName .. " -> " .. tostring(def))
        return nil
    end

    if overrides and type(overrides) == "table" then
        -- Shallow copy then apply overrides
        local patched = {}
        for k, v in pairs(def) do patched[k] = v end
        for k, v in pairs(overrides) do patched[k] = v end
        def = patched
    end

    entity:give("weapon", def)
    return entity
end

return WeaponFactory
