--- Projectile spawner module
--- Handles creation of standard projectile entities
local Math = require("util.math")

local atan2 = Math.atan2
local cos, sin = math.cos, math.sin

local ProjectileSpawner = {}

--- Get owner collision category for masking
local function getOwnerCategory(ship)
    if ship.physics_body and ship.physics_body.fixture then
        return ship.physics_body.fixture:getCategory()
    end
    return 2 -- Default to player category
end

--- Spawn a standard projectile
---@param world table ECS world
---@param physicsWorld table Box2D physics world
---@param muzzleX number Spawn X position
---@param muzzleY number Spawn Y position
---@param dirX number Direction X (normalized)
---@param dirY number Direction Y (normalized)
---@param weapon table Weapon component/config
---@param ship table Owner ship entity
---@return boolean success
function ProjectileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
    -- Create physics body
    local body = love.physics.newBody(physicsWorld, muzzleX, muzzleY, "dynamic")
    body:setBullet(true)
    body:setLinearDamping(0)
    body:setAngularDamping(0)
    if body.setGravityScale then
        body:setGravityScale(0)
    end

    -- Create shape and fixture
    local shape = love.physics.newCircleShape(weapon.projectileSize or 3)
    local fixture = love.physics.newFixture(body, shape, 0.1)
    fixture:setSensor(true)
    fixture:setCategory(4)

    -- Mask collision with owner's category to avoid self-collision
    local ownerCat = getOwnerCategory(ship)
    fixture:setMask(4, ownerCat) -- Ignore projectiles (4) and owner category

    -- Set velocity
    local speed = weapon.projectileSpeed or 1200
    body:setLinearVelocity(dirX * speed, dirY * speed)

    -- Calculate time-to-live
    local ttl = weapon.projectileTtl or 1.2

    -- Create projectile entity
    local miningEfficiency = weapon.miningEfficiency or 1.0
    local projectile = world:newEntity()
        :give("physics_body", body, shape, fixture)
        :give("renderable", "projectile", weapon.projectileColor or { 0.00, 1.00, 1.00, 0.95 })
        :give("projectile", weapon.damage, ttl, ship, miningEfficiency)

    fixture:setUserData(projectile)
    return true
end

--- Spawn multiple projectiles in a spread pattern
---@param world table ECS world
---@param physicsWorld table Box2D physics world
---@param muzzleX number Spawn X position
---@param muzzleY number Spawn Y position
---@param aimAngle number Center aim angle in radians
---@param weapon table Weapon component/config
---@param ship table Owner ship entity
---@return boolean success
function ProjectileSpawner.spawnSpread(world, physicsWorld, muzzleX, muzzleY, aimAngle, weapon, ship)
    local count = weapon.count or 1
    local spread = weapon.spread or 0

    if count == 1 then
        local dirX, dirY = cos(aimAngle), sin(aimAngle)
        return ProjectileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
    end

    -- Multiple projectiles in spread pattern
    local startA = aimAngle - spread / 2
    local step = spread / (count - 1)

    for i = 0, count - 1 do
        local a = startA + step * i
        local dirX, dirY = cos(a), sin(a)
        ProjectileSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, dirX, dirY, weapon, ship)
    end

    return true
end

return ProjectileSpawner
