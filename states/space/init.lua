--- Space game state
--- Main game loop coordinator - delegates setup/input/physics to modules
local Gamestate = require("lib.hump.gamestate")
local baton = require("lib.baton")

require("ecs.components")

local SpaceBackground = require("game.backgrounds.space_background")
local Camera = require("game.camera")
local Profiler = require("util.profiler")
local Seed = require("util.seed")
local Pause = require("states.pause")
local Death = require("states.death")
local MathUtil = require("util.math")
local factory = require("game.factory")

-- Modular components
local SpaceSetup = require("states.space.setup")
local SpaceInput = require("states.space.input")
local SpacePhysics = require("states.space.physics")

local function getInterpolatedTarget(ship, alpha)
  local shipBody = ship and ship.physics_body and ship.physics_body.body
  if not shipBody then
    return nil, nil
  end

  local x, y = shipBody:getPosition()
  local pb = ship.physics_body
  if pb and pb.prevX ~= nil and pb.prevY ~= nil and alpha ~= nil and alpha ~= 1 then
    x = MathUtil.lerp(pb.prevX, x, alpha)
    y = MathUtil.lerp(pb.prevY, y, alpha)
  end

  return x, y
end

local Space = {}

function Space:init()
  self.fixedDt = 1 / 60
end

function Space:enter(_, worldSeed)
  local SectorConfig = require("game.data.sectors.sector_01")

  self.accumulator = 0
  self.pendingContacts = {}
  self.mouseWorld = { x = 0, y = 0 }

  love.mouse.setVisible(false)

  -- Initialize world seed and RNGs
  self.showBackground = true
  self.worldSeed = Seed.normalize(worldSeed or love.math.random(1, 2147483646))
  self.worldRngs = {
    background = love.math.newRandomGenerator(Seed.derive(self.worldSeed, "background")),
    asteroids = love.math.newRandomGenerator(Seed.derive(self.worldSeed, "asteroids")),
  }
  self.background = SpaceBackground.new({
    seed = Seed.derive(self.worldSeed, "starfield"),
    nebulaSeed = Seed.derive(self.worldSeed, "nebula")
  })

  self.view = {}
  self.profiler = Profiler.new()

  -- Sector dimensions
  self.currentSector = { x = 0, y = 0 }
  self.sectorWidth = SectorConfig.width
  self.sectorHeight = SectorConfig.height
  self.sectorOriginX = self.currentSector.x * self.sectorWidth
  self.sectorOriginY = self.currentSector.y * self.sectorHeight

  self.camera = Camera.new({
    zoom = 1.0,
    minZoom = 0.5,
    maxZoom = 2.0,
    boundsW = self.sectorWidth,
    boundsH = self.sectorHeight,
  })

  local InputConfig = require("game.input_config")
  self.input = baton.new(InputConfig)

  -- Physics world with contact callbacks
  self.physicsWorld = love.physics.newWorld(0, 0, true)
  self.physicsWorld:setCallbacks(
    function(a, b, contact) SpacePhysics.beginContact(self, a, b, contact) end,
    function(a, b, contact) SpacePhysics.endContact(self, a, b, contact) end
  )

  -- Delegate ECS setup and spawning to modules
  SpaceSetup.setupEcsWorld(self, SectorConfig)
  SpaceSetup.spawnSectorContents(self, SectorConfig)
end

function Space:respawn()
  self.ship = factory.createShip(self.ecsWorld, self.physicsWorld, self.spawnX, self.spawnY)

  if self.player and self.player:has("pilot") then
    self.player.pilot.ship = self.ship
  end

  self.ecsWorld:setResource("player", self.player)
  self.ecsWorld:setResource("player_died", false)
  love.mouse.setVisible(false)
end

function Space:resume()
  if self.input then
    local InputConfig = require("game.input_config")
    package.loaded["game.input_config"] = nil
    InputConfig = require("game.input_config")

    self.input = baton.new(InputConfig)

    if self.ecsWorld then
      self.ecsWorld:setResource("input", self.input)
    end
  end
end

function Space:update(dt)
  if self.profiler then
    self.profiler:beginFrame()
  end

  local maxFrameDt = 0.10
  if dt > maxFrameDt then
    dt = maxFrameDt
  end

  local stationUI = self.ecsWorld and self.ecsWorld:getResource("station_ui")
  local isDocked = stationUI and stationUI.open

  if not isDocked and self.background then
    self.background:update(dt)
  end

  -- Update mouse world position
  do
    local screenW, screenH = love.graphics.getDimensions()
    local pilotedShip = self.ship
    if self.player and self.player.pilot and self.player.pilot.ship then
      pilotedShip = self.player.pilot.ship
    end

    local shipBody = pilotedShip and pilotedShip.physics_body and pilotedShip.physics_body.body
    if shipBody then
      local targetX, targetY = shipBody:getPosition()
      local view = self.camera:getView(screenW, screenH, targetX, targetY, self.view)
      local mx, my = love.mouse.getPosition()
      self.mouseWorld.x = (mx / view.zoom) + view.camX
      self.mouseWorld.y = (my / view.zoom) + view.camY
    end
  end

  if not isDocked then
    do
      local t0 = love.timer.getTime()
      self.ecsWorld:emit("update", dt)
      if self.profiler then
        self.profiler:add("ecs:update", (love.timer.getTime() - t0) * 1000)
      end
    end

    -- Fixed timestep physics
    local maxSubSteps = 6
    local maxAccum = self.fixedDt * maxSubSteps
    self.accumulator = math.min(self.accumulator + dt, maxAccum)

    local steps = 0
    while self.accumulator >= self.fixedDt and steps < maxSubSteps do
      local t0 = love.timer.getTime()
      self.ecsWorld:emit("fixedUpdate", self.fixedDt)
      self.physicsWorld:update(self.fixedDt)
      if self.profiler then
        self.profiler:add("fixed+physics", (love.timer.getTime() - t0) * 1000)
      end
      SpacePhysics.drainContacts(self)
      self.accumulator = self.accumulator - self.fixedDt
      steps = steps + 1
    end

    if self.ecsWorld and self.fixedDt > 0 then
      self.ecsWorld:setResource("render_alpha", self.accumulator / self.fixedDt)
    end

    -- Check for player death
    local playerDied = self.ecsWorld and self.ecsWorld:getResource("player_died")
    if playerDied then
      self.ecsWorld:setResource("player_died", false)
      Gamestate.push(Death)
    end
  end
end

function Space:draw()
  love.graphics.clear(0.02, 0.04, 0.08, 1)

  local screenW, screenH = love.graphics.getDimensions()
  local pilotedShip = self.ship
  if self.player and self.player.pilot and self.player.pilot.ship then
    pilotedShip = self.player.pilot.ship
  end

  local alpha = self.ecsWorld and self.ecsWorld.getResource and self.ecsWorld:getResource("render_alpha")
  if alpha == nil then alpha = 1 end
  alpha = MathUtil.clamp(alpha, 0, 1)

  local targetX, targetY = getInterpolatedTarget(pilotedShip, alpha)

  local view = self.camera:getView(screenW, screenH, targetX, targetY, self.view)
  if self.ecsWorld then
    self.ecsWorld:setResource("camera_view", view)
  end

  if self.showBackground and self.background then
    local t0 = love.timer.getTime()
    self.background:draw(view.focusX, view.focusY)
    if self.profiler then
      self.profiler:add("background:draw", (love.timer.getTime() - t0) * 1000)
    end
  end

  love.graphics.push()
  love.graphics.scale(view.zoom)
  love.graphics.translate(-view.camX, -view.camY)
  love.graphics.setColor(0.25, 0.35, 0.55, 0.6)
  love.graphics.rectangle("line", 0, 0, self.sectorWidth, self.sectorHeight)
  love.graphics.setColor(1, 1, 1, 1)
  do
    local t0 = love.timer.getTime()
    self.ecsWorld:emit("drawWorld")
    if self.profiler then
      self.profiler:add("ecs:drawWorld", (love.timer.getTime() - t0) * 1000)
    end
  end
  love.graphics.pop()

  do
    local t0 = love.timer.getTime()
    self.ecsWorld:emit("drawHud")
    if self.profiler then
      self.profiler:add("ecs:drawHud", (love.timer.getTime() - t0) * 1000)
    end
  end

  if self.profiler then
    self.profiler:endFrame()
    self.profiler:drawOverlay(12, 12)
  end
end

-- Input handlers delegate to module
function Space:keypressed(key)
  SpaceInput.keypressed(self, key, Pause, Space)
end

function Space:textinput(text)
  SpaceInput.textinput(self, text)
end

function Space:wheelmoved(x, y)
  SpaceInput.wheelmoved(self, x, y)
end

function Space:mousepressed(x, y, button)
  SpaceInput.mousepressed(self, x, y, button)
end

function Space:mousereleased(x, y, button)
  SpaceInput.mousereleased(self, x, y, button)
end

function Space:mousemoved(x, y, dx, dy)
  SpaceInput.mousemoved(self, x, y, dx, dy)
end

function Space:leave()
  love.mouse.setVisible(true)
end

return Space
