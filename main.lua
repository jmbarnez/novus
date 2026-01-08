local Gamestate = require("lib.hump.gamestate")
local Space = require("states.space")
local Seed = require("util.seed")
local Settings = require("game.settings")

-- Post-processing resources (initialized in love.load)
local gammaShader
local mainCanvas

function love.load()
  love.physics.setMeter(64)
  local seed1 = os.time()
  local seed2 = math.floor(love.timer.getTime() * 1000000)
  local worldSeed = Seed.normalize(seed1 * 1000000 + seed2)
  love.math.setRandomSeed(worldSeed, Seed.derive(worldSeed, "global"))
  love.math.random()
  love.math.random()
  love.math.random()

  love.graphics.setDefaultFilter("nearest", "nearest")

  local vsync = Settings.get("vsync")
  love.window.setVSync(vsync and 1 or 0)

  -- Load gamma shader for post-processing
  gammaShader = love.graphics.newShader("game/shaders/gamma.glsl")

  -- Create canvas for post-processing (resized on window resize)
  local w, h = love.graphics.getDimensions()
  mainCanvas = love.graphics.newCanvas(w, h)

  Gamestate.registerEvents()
  Gamestate.switch(Space, worldSeed)
end

-- Recreate canvas on resize
function love.resize(w, h)
  mainCanvas = love.graphics.newCanvas(w, h)
end

-- Custom main loop for FPS limiting
function love.run()
  if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

  -- We don't want the first frame's dt to include time taken by love.load.
  if love.timer then love.timer.step() end

  local dt = 0
  local frameStart = love.timer.getTime()

  -- Main loop time.
  return function()
    frameStart = love.timer.getTime()

    -- Process events.
    if love.event then
      love.event.pump()
      for name, a, b, c, d, e, f in love.event.poll() do
        if name == "quit" then
          if not love.quit or not love.quit() then
            return a or 0
          end
        end
        love.handlers[name](a, b, c, d, e, f)
      end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then dt = love.timer.step() end

    -- Call update and draw
    if love.update then love.update(dt) end

    if love.graphics and love.graphics.isActive() then
      -- Render everything to canvas first
      love.graphics.setCanvas(mainCanvas)
      love.graphics.origin()
      love.graphics.clear(love.graphics.getBackgroundColor())

      if love.draw then love.draw() end

      love.graphics.setCanvas()

      -- Apply gamma correction shader when drawing canvas to screen
      local gamma = Settings.get("gamma") or 1.0
      gammaShader:send("gamma", gamma)

      love.graphics.setShader(gammaShader)
      love.graphics.draw(mainCanvas, 0, 0)
      love.graphics.setShader()

      love.graphics.present()
    end

    -- FPS Limiter: sleep to hit target frame time
    local maxFps = Settings.get("maxFps") or 60
    if love.timer and maxFps > 0 then
      local targetDt = 1.0 / maxFps
      local elapsed = love.timer.getTime() - frameStart
      local remaining = targetDt - elapsed

      -- Sleep for most of the remaining time (leave small buffer for precision)
      if remaining > 0.002 then
        love.timer.sleep(remaining - 0.001)
      end

      -- Busy-wait for the final bit for precision
      while love.timer.getTime() - frameStart < targetDt do
        -- spin
      end
    end
  end
end
