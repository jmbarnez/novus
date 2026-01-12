return {
  id = "credits",
  name = "Credits",
  color = { 0.95, 0.80, 0.30, 0.98 }, -- Gold coin color
  unitVolume = 0,           -- Does not consume cargo space
  maxStackVolume = 1000000, -- Effectively unlimited per stack
  icon = {
    kind = "circle",
    radius = 0.50,
    shadow = { dx = 0.08, dy = 0.08, a = 0.35 },
    fillA = 0.96,
    outline = { a = 0.95, width = 1.5 },
    innerRing = {
      kind = "circle",
      radius = 0.38,
      a = 0.70,
      width = 1.2,
    },
    detail = {
      kind = "arc",
      -- "C" shape in center
      radius = 0.22,
      startAngle = 0.5,
      endAngle = 5.8,
      color = { 0.40, 0.30, 0.10, 0.95 },
      a = 0.95,
      width = 2.5,
    },
    highlight = {
      kind = "arc",
      radius = 0.42,
      startAngle = 3.5,
      endAngle = 4.7,
      a = 0.40,
      width = 1.2,
    },
  },
}
