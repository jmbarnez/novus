--- Missile spawner module
--- Handles creation of homing missile entities
local Math = require("util.math")

local atan2 = Math.atan2

local MissileSpawner = {}

--- Get owner collision category for masking
local function getOwnerCategory(ship)
    if ship.physics_body and ship.physics_body.fixture then
        return ship.physics_body.fixture:getCategory()
    end
    return 2 -- Default to player category
end

--- Spawn a homing missile
---@param world table ECS world
---@param physicsWorld table Box2D physics world
---@param muzzleX number Spawn X position
---@param muzzleY number Spawn Y position
---@param dirX number Direction X (normalized)
---@param dirY number Direction Y (normalized)
---@param weapon table Weapon component/config
---@param ship table Owner ship entity
---@return boolean success
function MissileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
    -- Missiles launch slightly slower then accelerate
    local launchSpeed = (weapon.missileSpeed or 600) * 0.5

    -- Body
    local body = love.physics.newBody(physicsWorld, muzzleX, muzzleY, "dynamic")
    body:setLinearDamping(0.5) -- Some drag
    body:setAngularDamping(2) -- Stable turning

    local shape = love.physics.newCircleShape(4)
    local fixture = love.physics.newFixture(body, shape, 0.5)
    fixture:setSensor(true) -- Contact only
    fixture:setCategory(4) -- Projectile category

    local ownerCat = getOwnerCategory(ship)
    fixture:setMask(4, ownerCat)

    body:setLinearVelocity(dirX * launchSpeed, dirY * launchSpeed)
    body:setAngle(atan2(dirY, dirX))

    local missile = world:newEntity()
        :give("physics_body", body, shape, fixture)
        -- Uses projectile renderer; color pulled from weapon definition
        :give("renderable", "projectile", weapon.projectileColor or { 1, 0.2, 0.2, 1 })
        :give("projectile", weapon.damage, weapon.projectileTtl or 5, ship, weapon.miningEfficiency)
        :give("missile", weapon.target, weapon.damage, weapon.missileSpeed, weapon.missileTurnRate, weapon.missileAccel,
            weapon.projectileTtl)
        :give("engine_trail", { 1, 0.5, 0, 0.8 }) -- Visual flair

    fixture:setUserData(missile)
    return true
end

return MissileSpawner
