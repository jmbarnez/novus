--- Effects utility module for spawning visual effects
local Effects = {}

--- Spawn a shatter/spark effect at the specified position
---@param world table The ECS world
---@param physicsWorld table The Box2D physics world
---@param x number World X position
---@param y number World Y position
---@param color? table Optional RGBA color {r, g, b, a}
function Effects.spawnShatter(world, physicsWorld, x, y, color)
    if not physicsWorld then return end

    color = color or { 1, 1, 1, 1 }
    local r = color[1] or 1
    local g = color[2] or 1
    local b = color[3] or 1
    local a = color[4] or 1

    local effectBody = love.physics.newBody(physicsWorld, x, y, "static")
    local effectShape = love.physics.newCircleShape(1)
    local effectFixture = love.physics.newFixture(effectBody, effectShape, 0)

    effectFixture:setSensor(true)
    effectFixture:setCategory(8)
    effectFixture:setMask(1, 2, 4, 8)

    world:newEntity()
        :give("physics_body", effectBody, effectShape, effectFixture)
        :give("renderable", "shatter", { r, g, b, a })
        :give("shatter")
end

return Effects
