return {
  id = "credits",
  name = "Credits",
  color = { 0.95, 0.88, 0.25, 0.95 },
  unitVolume = 0,           -- Does not consume cargo space
  maxStackVolume = 1000000, -- Effectively unlimited per stack
  icon = {
    kind = "poly",
    points = {
      -0.55, -0.05,
      -0.35, -0.45,
      0.40, -0.50,
      0.55, 0.00,
      0.35, 0.45,
      -0.25, 0.50,
    },
    shadow = { dx = 0.08, dy = 0.08, a = 0.25 },
    fillA = 0.95,
    outline = { a = 0.9, width = 1.2 },
    highlight = {
      kind = "polyline",
      points = {
        -0.20, -0.10,
        0.35, -0.05,
        0.15, 0.25,
      },
      a = 0.22,
      width = 1.2,
    },
    detail = {
      kind = "line",
      points = {
        -0.15, -0.20,
        0.00, 0.30,
      },
      a = 0.30,
      width = 1.0,
    },
  },
}
