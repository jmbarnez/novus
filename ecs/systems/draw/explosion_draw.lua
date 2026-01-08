local ExplosionDraw = {}

local shader = love.graphics.newShader("game/shaders/explosion.glsl")

function ExplosionDraw.draw(e)
    local c = e.explosion
    if not c or not c.canvas then return end

    -- Setup Shader
    love.graphics.setShader(shader)
    shader:send("time", c.time)
    shader:send("duration", c.duration)

    -- Draw Canvas
    love.graphics.setColor(1, 1, 1, 1)

    -- Center it
    local offset = c.size / 2

    love.graphics.push()
    love.graphics.translate(c.x, c.y)
    love.graphics.rotate(c.angle)

    -- Draw the canvas
    love.graphics.draw(c.canvas, -offset, -offset)

    love.graphics.pop()

    -- Reset Shader
    love.graphics.setShader()
end

return ExplosionDraw
