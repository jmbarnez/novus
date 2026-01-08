local ExplosionFactory = {}

function ExplosionFactory.createExplosion(world, x, y, angle, shipEntity, shipShape)
    if not world then return end

    -- 1. Create Canvas
    -- We need a size large enough to hold the ship and the explosion expansion.
    -- Ship size approx 30x30. Explosion expands 2x-3x.
    local size = 160 -- Increased from 128 to give more room for expansion
    local canvas = love.graphics.newCanvas(size, size)

    -- 2. Render Ship to Canvas
    love.graphics.push("all")
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)

    -- Center the drawing
    love.graphics.translate(size / 2, size / 2)
    -- We draw the ship upright (angle 0) because we will rotate the whole explosion entity
    -- But wait, `shipEntity` draw logic might assume it's at (0,0) in local space?
    -- ShipDraw.draw calls `drawPlayerShip` or `drawEnemyShip`.
    -- These commands draw polygons relative to (0,0).

    -- We need to invoke the specific drawing code logic from ShipDraw.
    -- Assuming `ShipDraw` is requiring us or we can require it?
    -- Circular dependency risk if ShipDraw calls us? No, HealthSystem calls us.
    local ShipDraw = require("ecs.systems.draw.ship_draw")
    local RenderUtils = require("ecs.systems.draw.render_utils")

    -- Mock context for drawing (we don't need full context, just nil usually works)
    local ctx = { playerShip = nil, capture = true }
    if shipEntity:has("pilot") then ctx.playerShip = shipEntity end

    -- We need to mock the "draw" call but ONLY the visuals, not the translation/rotation logic
    -- which is inside `ShipDraw.draw`.
    -- Actually `ShipDraw.draw` does push->translate->rotate->drawSpecific->pop.
    -- If we call it with x=0, y=0, angle=0, it will draw centered at current transform.
    -- Which is what we want (size/2, size/2).

    ShipDraw.draw(ctx, shipEntity, nil, shipShape, 0, 0, 0)

    love.graphics.setCanvas()
    love.graphics.pop()

    -- 3. Create Explosion Entity
    local e = world:newEntity()
        :give("explosion", canvas, 2.0) -- duration increased to 2.0s
        :give("physics_body", nil)      -- Dummy for RenderSystem compatibility if needed, or we just use coords

    -- We'll manually store position since it's just a visual effect
    e.explosion.x = x
    e.explosion.y = y
    e.explosion.angle = angle
    e.explosion.size = size

    return e
end

return ExplosionFactory
