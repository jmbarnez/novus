return {
  id = "credits",
  name = "Credits",
  color = { 0.4, 0.6, 0.95, 0.98 }, -- Blue token color
  maxStack = 999999,                -- Large stacks for credits
  icon = {
    kind = "circle",
    radius = 0.45,
    shadow = { dx = 0.06, dy = 0.06, a = 0.4 },
    fillA = 1.0,

    layers = {
      -- 1. Outer Rim (Blue metallic)
      { kind = "circle", radius = 0.45, width = 3.0, mode = "line", color = { 0.5, 0.7, 1.0, 1.0 } },

      -- 2. Inner Recess/Groove (Darker Blue)
      { kind = "circle", radius = 0.35, width = 1.5, mode = "line", color = { 0.2, 0.4, 0.7, 0.8 } },

      -- 3. Center "N" shape (stylized Novus logo)
      {
        kind = "poly",
        -- N shape: left bar, diagonal, right bar
        points = {
          -0.15, 0.22, -0.15, -0.22, -0.08, -0.22, -- left bar bottom
          0.08, 0.10, 0.08, -0.22, 0.15, -0.22,    -- diagonal to right bar bottom
          0.15, 0.22, 0.08, 0.22,                  -- right bar top
          -0.08, -0.10, -0.08, 0.22                -- diagonal back to left bar top
        },
        color = { 0.15, 0.25, 0.45, 0.9 }
      },

      -- 4. Tech Arc Details (subtle glow)
      {
        kind = "arc",
        radius = 0.28,
        startAngle = 0.5,
        endAngle = 2.0,
        width = 1.5,
        color = { 0.7, 0.85, 1, 0.35 }
      },
      {
        kind = "arc",
        radius = 0.28,
        startAngle = 3.6,
        endAngle = 5.1,
        width = 1.5,
        color = { 0.7, 0.85, 1, 0.35 }
      },

      -- 5. Specular Highlight (Rim)
      {
        kind = "arc",
        radius = 0.45,
        startAngle = 3.8,
        endAngle = 4.8,
        width = 2.0,
        color = { 1, 1, 1, 0.5 }
      }
    },
  },
}
