local Concord = require("lib.concord")

-- Projectile component with optional data-driven expiration behavior
-- expireBehavior: string key for the behavior type (e.g. "scatter", "explode", "split")
-- expireConfig: table with behavior-specific configuration
Concord.component("projectile", function(c, damage, ttl, owner, miningEfficiency, expireBehavior, expireConfig)
  c.damage = damage or 1
  c.ttl = ttl or 1.0
  c.owner = owner
  c.miningEfficiency = miningEfficiency
  c.expireBehavior = expireBehavior -- nil = default shatter effect
  c.expireConfig = expireConfig     -- behavior-specific data
end)

return true
