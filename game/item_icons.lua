local Items = require("game.items")

local ItemIcons = {}

local function resolveColor(id, opts)
  local def = Items.get(id)
  local base = (def and def.color) or { 1, 1, 1, 1 }

  local c = (opts and opts.color) or base
  local t = opts and opts.tint

  if not t then
    return c[1], c[2], c[3], c[4]
  end

  return c[1] * t[1], c[2] * t[2], c[3] * t[3], (c[4] or 1) * (t[4] or 1)
end

local function buildScaledPoints(cx, cy, size, points)
  local s = size * 0.5
  local out = {}
  for i = 1, #points, 2 do
    out[i] = cx + points[i] * s
    out[i + 1] = cy + points[i + 1] * s
  end
  return out
end

local function applyRelativeOffset(dst, src, dx, dy)
  for i = 1, #src, 2 do
    dst[i] = src[i] + dx
    dst[i + 1] = src[i + 1] + dy
  end
end

local function drawFromParams(id, cx, cy, size, opts)
  local def = Items.get(id)
  local icon = def and def.icon
  if not icon or type(icon) ~= "table" then
    return false
  end

  local r, g, b, a = resolveColor(id, opts)
  local alpha = a or 1

  -- Parse common transformation
  local function getTransform(def)
    return {
      radius = (def.radius or 0.5) * size,
      width = (def.width or 1),
      startAngle = def.startAngle or 0,
      endAngle = def.endAngle or (math.pi * 2),
    }
  end

  -- Shape primitives
  local function drawShape(def, mode, col)
    if not def then return end

    local c = col or { 0, 0, 0, 0 }
    love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * alpha * (def.a or 1))

    if def.width then love.graphics.setLineWidth(def.width) end

    if def.kind == "poly" and def.points then
      local pts = buildScaledPoints(cx, cy, size, def.points)
      love.graphics.polygon(mode, pts)
    elseif def.kind == "circle" then
      local t = getTransform(def)
      love.graphics.circle(mode, cx, cy, t.radius)
    elseif def.kind == "arc" then
      local t = getTransform(def)
      love.graphics.arc(mode, def.arcType or "open", cx, cy, t.radius, t.startAngle, t.endAngle)
    end
  end

  -- 1. Shadow
  if icon.shadow then
    local s = icon.shadow
    local dx = (s.dx or 0) * size
    local dy = (s.dy or 0) * size

    love.graphics.push()
    love.graphics.translate(dx, dy)
    drawShape(icon, "fill", { 0, 0, 0, s.a or 0.5 })
    love.graphics.pop()
  end

  -- 2. Base Fill
  drawShape(icon, "fill", { r, g, b, icon.fillA or 1 })

  -- 3. Features (Inner Ring, Detail, Highlight)
  -- Support generic list of layers or named legacy fields
  local layers = icon.layers or { icon.innerRing, icon.detail, icon.highlight }

  for _, layer in ipairs(layers) do
    if layer then
      -- Determine mode: arcs and lines are "line", others "fill" unless specified
      local mode = layer.mode or (layer.kind == "arc" or layer.kind == "line" or layer.kind == "polyline") and "line" or
      "fill"

      -- For highlights/details, default to white/black if no color specified, but allow overrides
      local lc = layer.color or (mode == "line" and { 1, 1, 1, layer.a } or { 0, 0, 0, layer.a })
      -- If layer has explicit color, use it. If it's a "highlight", default white. If "detail", default black/dark.
      if not layer.color then
        if layer == icon.highlight then lc = { 1, 1, 1, 1 } end
        if layer == icon.detail then lc = { 0, 0, 0, 1 } end
        if layer == icon.innerRing then lc = { 0, 0, 0, 1 } end
      end

      drawShape(layer, mode, lc)
    end
  end

  -- 4. Outline (Global)
  if icon.outline then
    drawShape(icon, "line", { 0, 0, 0, icon.outline.a or 1 })
  end

  return true
end

function ItemIcons.draw(id, x, y, w, h, opts)
  local size = math.min(w, h)
  local cx = x + w * 0.5
  local cy = y + h * 0.5

  love.graphics.push("all")
  drawFromParams(id, cx, cy, size, opts)
  love.graphics.pop()
end

function ItemIcons.drawCentered(id, cx, cy, size, opts)
  love.graphics.push("all")
  drawFromParams(id, cx, cy, size, opts)
  love.graphics.pop()
end

return ItemIcons
