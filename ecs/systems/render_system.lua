local Concord = require("lib.concord")

local Utils = require("ecs.systems.draw.render_utils")
local ShipDraw = require("ecs.systems.draw.ship_draw")
local AsteroidDraw = require("ecs.systems.draw.asteroid_draw")
local ProjectileDraw = require("ecs.systems.draw.projectile_draw")
local PickupDraw = require("ecs.systems.draw.pickup_draw")
local ShatterDraw = require("ecs.systems.draw.shatter_draw")
local MapUiDraw = require("ecs.systems.draw.map_ui_draw")
local ExplosionDraw = require("ecs.systems.draw.explosion_draw")
local SpaceStationDraw = require("ecs.systems.draw.space_station_draw")
local RefineryStationDraw = require("ecs.systems.draw.refinery_station_draw")

local RenderSystem = Concord.system({
  renderables = { "physics_body", "renderable" },
  explosions = { "explosion" },
  beams = { "laser_beam" }
})

local beamShader
local beamMesh
local beamTexture

function RenderSystem:init(world)
  self.world = world

  if not beamShader then
    beamShader = love.graphics.newShader("game/shaders/beam.glsl")
  end

  if not beamMesh then
    -- Unit quad with UVs (0..1) so shader can use normalized coords.
    beamMesh = love.graphics.newMesh({
      { 0, 0, 0, 0 },
      { 1, 0, 1, 0 },
      { 0, 1, 0, 1 },
      { 1, 1, 1, 1 },
    }, "strip", "dynamic")
  end

  if not beamTexture then
    local data = love.image.newImageData(1, 1)
    data:setPixel(0, 0, 1, 1, 1, 1)
    beamTexture = love.graphics.newImage(data)
  end
end

function RenderSystem:drawWorld()
  love.graphics.setLineWidth(2)

  local playerShip = nil
  if self.world then
    local player = self.world:getResource("player")
    if player and player:has("pilot") and player.pilot.ship then
      playerShip = player.pilot.ship
    end
  end

  local mapUi = self.world and self.world.getResource and self.world:getResource("map_ui")
  MapUiDraw.draw(mapUi)

  local view = self.world and self.world.getResource and self.world:getResource("camera_view")
  local alpha = self.world and self.world.getResource and self.world:getResource("render_alpha")
  local targeting = self.world and self.world.getResource and self.world:getResource("targeting")
  local hovered = targeting and targeting.hovered or nil
  local selected = targeting and targeting.selected or nil
  if alpha == nil then
    alpha = 1
  end
  if alpha < 0 then
    alpha = 0
  elseif alpha > 1 then
    alpha = 1
  end

  local viewLeft, viewTop, viewRight, viewBottom
  if view then
    viewLeft = view.camX
    viewTop = view.camY
    viewRight = view.camX + view.viewW
    viewBottom = view.camY + view.viewH
  end

  local cullPad = 140

  local ctx = {
    playerShip = playerShip,
    mouse_world = self.world and self.world:getResource("mouse_world"),
    hovered = hovered,
    selected = selected,
    cullPad = cullPad,
    viewLeft = viewLeft,
    viewRight = viewRight,
    viewTop = viewTop,
    viewBottom = viewBottom,
  }

  for i = 1, self.renderables.size do
    local e = self.renderables[i]

    local pb = e.physics_body
    local body = pb.body
    local shape = pb.shape

    local x, y = body:getPosition()
    local angle = body:getAngle()
    if pb.prevX ~= nil and pb.prevY ~= nil and pb.prevA ~= nil and alpha ~= 1 then
      x = Utils.lerp(pb.prevX, x, alpha)
      y = Utils.lerp(pb.prevY, y, alpha)
      angle = Utils.lerpAngle(pb.prevA, angle, alpha)
    end

    if e.renderable.kind == "ship" then
      ShipDraw.draw(ctx, e, body, shape, x, y, angle)
    elseif e.renderable.kind == "asteroid" then
      AsteroidDraw.draw(ctx, e, body, shape, x, y, angle)
    elseif e.renderable.kind == "projectile" then
      ProjectileDraw.draw(ctx, e, body, x, y)
    elseif e.renderable.kind == "pickup" then
      PickupDraw.draw(ctx, e, body, x, y)
    elseif e.renderable.kind == "shatter" and e:has("shatter") then
      ShatterDraw.draw(e, body, x, y)
    elseif e.renderable.kind == "space_station" then
      SpaceStationDraw.draw(ctx, e, body, shape, x, y, angle)
    elseif e.renderable.kind == "refinery_station" then
      RefineryStationDraw.draw(ctx, e, body, shape, x, y, angle)
    end
  end

  -- DRAW BEAMS (Additive + shader)
  love.graphics.setBlendMode("add")
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.setShader(beamShader)
  for i = 1, self.beams.size do
    local e = self.beams[i]
    local beam = e.laser_beam

    local dx = beam.endX - beam.startX
    local dy = beam.endY - beam.startY
    local len = math.sqrt(dx * dx + dy * dy)
    local angle
    if math.atan2 then
      angle = math.atan2(dy, dx)
    else
      -- Lua 5.1 fallback: atan(y/x) with quadrant handling
      if dx == 0 then
        angle = (dy >= 0) and math.pi * 0.5 or -math.pi * 0.5
      else
        angle = math.atan(dy / dx)
        if dx < 0 then
          angle = angle + math.pi
        end
      end
    end
    local width = (beam.width or 4) * 2.3
    local r, g, b, a = unpack(beam.color or { 0, 1, 1, 1 })

    beamShader:send("time", love.timer.getTime())
    beamShader:send("beamColor", { r, g, b })
    beamShader:send("beamAlpha", a or 1)

    -- Update quad geometry to match current beam size (strip order: TL, TR, BL, BR).
    local halfW = width * 0.5
    beamMesh:setVertex(1, 0, -halfW, 0, 0)
    beamMesh:setVertex(2, len, -halfW, 1, 0)
    beamMesh:setVertex(3, 0, halfW, 0, 1)
    beamMesh:setVertex(4, len, halfW, 1, 1)
    beamMesh:setTexture(beamTexture)

    love.graphics.push()
    love.graphics.translate(beam.startX, beam.startY)
    love.graphics.rotate(angle)
    love.graphics.draw(beamMesh)
    love.graphics.pop()
  end
  love.graphics.setShader()
  love.graphics.setBlendMode("alpha")

  -- DRAW EXPLOSIONS (Additive)
  love.graphics.setBlendMode("add")
  for i = 1, self.explosions.size do
    ExplosionDraw.draw(self.explosions[i])
  end
  love.graphics.setBlendMode("alpha")

  love.graphics.setColor(1, 1, 1, 1)
end

function RenderSystem:draw()
  return self:drawWorld()
end

return RenderSystem
