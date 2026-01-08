local WeaponFactory = {}

-- Map weapon names to file paths
local WEAPON_PATH = "game.weapons."

function WeaponFactory.create(entity, weaponName)
    local status, def = pcall(require, WEAPON_PATH .. weaponName)
    if not status then
        print("Error loading weapon: " .. weaponName .. " -> " .. tostring(def))
        return nil
    end

    -- Add the generic weapon component using the loaded definition
    entity:give("weapon", def)

    return entity
end

return WeaponFactory
