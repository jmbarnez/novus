local Items = require("game.items")

local Inventory = {}

local function isEmpty(slot)
  return not slot or not slot.id or (slot.count or 0) <= 0
end

function Inventory.isEmpty(slot)
  return isEmpty(slot)
end

function Inventory.clear(slot)
  slot.id = nil
  slot.count = 0
end

function Inventory.clone(slot)
  if isEmpty(slot) then
    return { id = nil, count = 0 }
  end
  return { id = slot.id, count = slot.count }
end

function Inventory.maxStack(id)
  local def = Items.get(id)
  return (def and def.maxStack) or 999
end

function Inventory.mergeInto(dst, src)
  if isEmpty(src) then
    return true
  end

  if isEmpty(dst) then
    dst.id = src.id
    dst.count = src.count
    Inventory.clear(src)
    return true
  end

  if dst.id ~= src.id then
    return false
  end

  local maxStack = Inventory.maxStack(dst.id)
  if dst.count >= maxStack then
    return false
  end

  local room = maxStack - dst.count
  local take = math.min(room, src.count)
  dst.count = dst.count + take
  src.count = src.count - take
  if src.count <= 0 then
    Inventory.clear(src)
  end

  return true
end

function Inventory.swap(a, b)
  local aId, aCount = a.id, a.count
  a.id, a.count = b.id, b.count
  b.id, b.count = aId, aCount
end

function Inventory.totalCount(slots)
  local c = 0
  for i = 1, #slots do
    local s = slots[i]
    if s and s.id and (s.count or 0) > 0 then
      c = c + s.count
    end
  end
  return c
end

function Inventory.addToSlots(slots, id, count)
  local remaining = count or 0
  if not id or remaining <= 0 then
    return 0
  end

  local maxStack = Inventory.maxStack(id)

  -- First pass: fill existing stacks
  for i = 1, #slots do
    local s = slots[i]
    if s and s.id == id and (s.count or 0) > 0 and s.count < maxStack then
      local room = maxStack - s.count
      local take = math.min(room, remaining)
      s.count = s.count + take
      remaining = remaining - take
      if remaining <= 0 then
        return 0
      end
    end
  end

  -- Second pass: use empty slots
  for i = 1, #slots do
    local s = slots[i]
    if s and Inventory.isEmpty(s) then
      local take = math.min(maxStack, remaining)
      s.id = id
      s.count = take
      remaining = remaining - take
      if remaining <= 0 then
        return 0
      end
    end
  end

  return remaining
end

return Inventory
