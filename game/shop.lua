--- Shop module
--- Provides access to all purchasable items and handles transactions

local Items = require("game.items")
local Inventory = require("game.inventory")

local Shop = {}

-- Get all items available for purchase with prices
function Shop.getItems()
    local shopItems = {}
    for id, def in pairs(Items.all()) do
        table.insert(shopItems, {
            id = id,
            name = def.name or id,
            color = def.color,
            icon = def.icon,
            price = Shop.getPrice(id),
            def = def,
        })
    end
    -- Sort alphabetically
    table.sort(shopItems, function(a, b) return a.name < b.name end)
    return shopItems
end

-- Get base price for an item
function Shop.getPrice(itemId)
    local prices = {
        stone = 5,
        iron = 15,
        mithril = 50,
        iron_ingot = 35,
        mithril_ingot = 120,
        credits = 1, -- Credits can be traded 1:1
    }
    return prices[itemId] or 10
end

-- Get sell price (80% of buy price)
function Shop.getSellPrice(itemId)
    return math.floor(Shop.getPrice(itemId) * 0.8)
end

-- Attempt to buy an item
function Shop.buyItem(player, ship, itemId, quantity)
    quantity = quantity or 1
    if not player or not ship then
        return false, "No player or ship"
    end

    local price = Shop.getPrice(itemId) * quantity

    -- Check credits
    if not player:has("credits") or player.credits.balance < price then
        return false, "Not enough credits"
    end

    -- Check cargo hold exists
    local hold = ship.cargo_hold
    if not hold then
        return false, "No cargo hold"
    end

    -- Try to add to inventory (grid naturally limits capacity)
    local remaining = Inventory.addToSlots(hold.slots, itemId, quantity)
    local added = quantity - remaining

    if added <= 0 then
        return false, "No available slot"
    end

    -- Deduct credits (prorated if partial purchase)
    local actualPrice = Shop.getPrice(itemId) * added
    player.credits.balance = player.credits.balance - actualPrice

    local itemDef = Items.get(itemId)
    return true, "Purchased " .. added .. " " .. (itemDef and itemDef.name or itemId)
end

-- Attempt to sell an item
function Shop.sellItem(player, ship, itemId, quantity)
    quantity = quantity or 1
    if not player or not ship then
        return false, "No player or ship"
    end

    local hold = ship.cargo_hold
    if not hold then
        return false, "No cargo hold"
    end

    -- Find slot with this item
    local slot = nil
    for i, s in ipairs(hold.slots) do
        if s.id == itemId and (s.count or 0) >= quantity then
            slot = s
            break
        end
    end

    if not slot then
        return false, "Not enough items to sell"
    end

    -- Remove from cargo
    slot.count = slot.count - quantity
    if slot.count <= 0 then
        Inventory.clear(slot)
    end

    -- Add credits
    local sellPrice = Shop.getSellPrice(itemId) * quantity
    if player:has("credits") then
        player.credits.balance = player.credits.balance + sellPrice
    end

    local itemDef = Items.get(itemId)
    return true, "Sold " .. quantity .. " " .. (itemDef and itemDef.name or itemId)
end

return Shop
