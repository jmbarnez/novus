--- Scatter orb spawner module
--- Handles creation of scatter orb projectiles that explode into fragments
local sqrt = math.sqrt

local ScatterOrbSpawner = {}

--- Get owner collision category for masking
local function getOwnerCategory(ship)
    if ship.physics_body and ship.physics_body.fixture then
        return ship.physics_body.fixture:getCategory()
    end
    return 2 -- Default to player category
end

--- Spawn a scatter orb that travels to target and explodes
---@param world table ECS world
---@param physicsWorld table Box2D physics world
---@param muzzleX number Spawn X position
---@param muzzleY number Spawn Y position
---@param targetX number Target X position
---@param targetY number Target Y position
---@param weapon table Weapon component/config
---@param ship table Owner ship entity
---@return boolean success
function ScatterOrbSpawner.spawn(world, physicsWorld, muzzleX, muzzleY, targetX, targetY, weapon, ship)
    -- Calculate direction to target
    local dx, dy = targetX - muzzleX, targetY - muzzleY
    local dist = sqrt(dx * dx + dy * dy)
    if dist < 1 then
        dx, dy = 1, 0
        dist = 1
    end
    local dirX, dirY = dx / dist, dy / dist

    -- Create physics body for the orb
    local body = love.physics.newBody(physicsWorld, muzzleX, muzzleY, "dynamic")
    body:setBullet(true)
    body:setLinearDamping(0)
    body:setAngularDamping(0)
    if body.setGravityScale then
        body:setGravityScale(0)
    end

    local shape = love.physics.newCircleShape(weapon.orbSize or 6)
    local fixture = love.physics.newFixture(body, shape, 0.1)
    fixture:setSensor(true)
    fixture:setCategory(4)

    local ownerCat = getOwnerCategory(ship)
    fixture:setMask(4, ownerCat)

    -- Set velocity toward target
    local speed = weapon.orbSpeed or 600
    body:setLinearVelocity(dirX * speed, dirY * speed)

    -- TTL = time to reach target + small buffer
    local ttl = (dist / speed) + 0.05

    -- Config for the scatter explosion behavior (shared between expire and impact)
    local scatterConfig = {
        damage = weapon.damage,
        projectileSpeed = weapon.projectileSpeed or 700,
        projectileTtl = weapon.projectileTtl or 0.6,
        projectileColor = weapon.projectileColor,
        projectileSize = weapon.projectileSize or 4,
        scatterCount = weapon.scatterCount or { 6, 10 },
        miningEfficiency = weapon.miningEfficiency,
    }

    -- On impact: scatter_away (spawns fragments in opposite direction of impact)
    -- On expire (reaching target): scatter (spawns fragments in all directions)
    local orb = world:newEntity()
        :give("physics_body", body, shape, fixture)
        :give("renderable", "projectile", weapon.orbColor or { 0.4, 1.0, 0.2, 1 })
        :give("projectile", weapon.damage, ttl, ship, weapon.miningEfficiency, "scatter", scatterConfig, "scatter_away",
            scatterConfig)

    fixture:setUserData(orb)
    return true
end

return ScatterOrbSpawner
