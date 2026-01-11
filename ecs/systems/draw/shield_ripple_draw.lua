local ShieldRippleDraw = {}

local shader = love.graphics.newShader("game/shaders/shield_ripple.glsl")

-- Create a mesh with proper UV coordinates (0-1)
local mesh
local texture

local function ensureMesh()
    if mesh then return end

    -- Create unit quad with UVs
    mesh = love.graphics.newMesh({
        { 0, 0, 0, 0 }, -- x, y, u, v
        { 1, 0, 1, 0 },
        { 1, 1, 1, 1 },
        { 0, 1, 0, 1 },
    }, "fan", "static")

    -- Create 1x1 white texture for shader
    local data = love.image.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 1)
    texture = love.graphics.newImage(data)
    mesh:setTexture(texture)
end

function ShieldRippleDraw.draw(e, x, y)
    -- Only draw when there's an active impact effect
    if not e:has("shield") then return end
    if not e:has("shield_hit") then return end

    local shieldHit = e.shield_hit
    if #shieldHit.hits == 0 then return end

    local shield = e.shield
    if shield.current <= 0 then return end

    ensureMesh()

    -- Use shield radius from component (or default)
    local shieldRadius = shield.radius or 28
    local visualSize = shieldRadius * 2
    local halfSize = shieldRadius

    -- Get entity rotation for proper hit position transformation
    local angle = 0
    if e:has("physics_body") and e.physics_body.body then
        angle = e.physics_body.body:getAngle()
    end

    love.graphics.push()
    love.graphics.translate(x, y)

    love.graphics.setBlendMode("add")
    love.graphics.setShader(shader)

    -- Draw each ripple effect
    for _, hit in ipairs(shieldHit.hits) do
        -- Transform local hit position by entity angle
        local cosA = math.cos(angle)
        local sinA = math.sin(angle)
        local worldLocalX = hit.localX * cosA - hit.localY * sinA
        local worldLocalY = hit.localX * sinA + hit.localY * cosA

        -- Normalize to 0-1 range
        local normHitX = (worldLocalX + halfSize) / visualSize
        local normHitY = (worldLocalY + halfSize) / visualSize

        shader:send("time", hit.time)
        shader:send("duration", hit.duration)
        shader:send("hitPos", { normHitX, normHitY })
        shader:send("shieldRadius", 0.45)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(mesh, -halfSize, -halfSize, 0, visualSize, visualSize)
    end

    love.graphics.setShader()
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()
end

return ShieldRippleDraw
