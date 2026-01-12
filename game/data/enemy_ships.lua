local EnemyShipDefs = {}

-- Dynamically load all enemy definitions from game/data/enemies/
local function loadEnemyDefs()
    local defs = {}
    local enemiesPath = "game/data/enemies"
    local items = love.filesystem.getDirectoryItems(enemiesPath)
    for _, filename in ipairs(items) do
        if filename:match("%.lua$") then
            local moduleName = filename:gsub("%.lua$", "")
            local ok, def = pcall(require, "game.data.enemies." .. moduleName)
            if ok and def and def.id then
                defs[def.id] = def
            end
        end
    end
    return defs
end

EnemyShipDefs.list = loadEnemyDefs()

EnemyShipDefs.defaultId = "goblin"

function EnemyShipDefs.pickRandomId(rng)
    rng = rng or love.math
    local keys = {}
    for id in pairs(EnemyShipDefs.list) do
        table.insert(keys, id)
    end
    return keys[rng.random(#keys)]
end

function EnemyShipDefs.all()
    return EnemyShipDefs.list
end

return EnemyShipDefs
