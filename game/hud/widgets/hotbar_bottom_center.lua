-- Hotbar widget for weapon selection
-- Displays 5 slots at bottom center with 1-5 keybinds

local HotbarBottomCenter = {}

local Theme = require("game.theme")
local WeaponIcons = require("game.weapon_icons")
local WeaponFactory = require("game.factory.weapon_factory")
local Rect = require("util.rect")

local pointInRect = Rect.pointInRect

local function getMapOpen(ctx)
    local world = ctx and ctx.world
    local mapUi = world and world.getResource and world:getResource("map_ui")
    return mapUi and mapUi.open
end

local function getPlayerShip(ctx)
    if not ctx or not ctx.playerEntity then return nil end
    local player = ctx.playerEntity
    if player:has("pilot") and player.pilot.ship then
        return player.pilot.ship
    end
    return nil
end

local function makeHotbarBottomCenter()
    local self = {
        bounds = nil,
        slotBounds = {},
        hoverSlot = nil,
    }

    local SLOT_SIZE = 48
    local SLOT_GAP = 6
    local SLOT_COUNT = 5
    local PADDING = 8
    local HEADER_H = 10 -- Space for keybind numbers
    local MARGIN_BOTTOM = 16

    local function recompute(ctx)
        local screenW = ctx and ctx.screenW or love.graphics.getWidth()
        local screenH = ctx and ctx.screenH or love.graphics.getHeight()

        local totalW = (SLOT_SIZE * SLOT_COUNT) + (SLOT_GAP * (SLOT_COUNT - 1)) + (PADDING * 2)
        local totalH = SLOT_SIZE + HEADER_H + (PADDING * 2)

        local x = (screenW - totalW) / 2
        local y = screenH - totalH - MARGIN_BOTTOM

        self.bounds = {
            x = x,
            y = y,
            w = totalW,
            h = totalH,
        }

        -- Compute individual slot bounds (below header)
        self.slotBounds = {}
        for i = 1, SLOT_COUNT do
            local slotX = x + PADDING + (i - 1) * (SLOT_SIZE + SLOT_GAP)
            local slotY = y + PADDING + HEADER_H
            self.slotBounds[i] = {
                x = slotX,
                y = slotY,
                w = SLOT_SIZE,
                h = SLOT_SIZE,
            }
        end
    end

    local function getSlotAt(x, y)
        for i, b in ipairs(self.slotBounds) do
            if pointInRect(x, y, b) then
                return i
            end
        end
        return nil
    end

    local function switchToSlot(ctx, slotIndex)
        local ship = getPlayerShip(ctx)
        if not ship or not ship:has("weapon_loadout") then return false end

        local loadout = ship.weapon_loadout
        local weaponId = loadout.slots[slotIndex]

        if not weaponId then return false end
        if loadout.activeSlot == slotIndex then return true end

        loadout.activeSlot = slotIndex

        -- Clean up any active beam before switching (prevents frozen beams)
        if ship:has("weapon") then
            local WeaponLogic = require("ecs.systems.weapon_logic")
            if ship.weapon.type == "beam" then
                WeaponLogic.stopBeam(ship.weapon)
            end
            ship:remove("weapon")
        end
        WeaponFactory.create(ship, weaponId)

        return true
    end

    function self.hitTest(ctx, x, y)
        if not ctx or getMapOpen(ctx) then return false end
        recompute(ctx)
        return self.bounds and pointInRect(x, y, self.bounds)
    end

    function self.draw(ctx)
        if not ctx or getMapOpen(ctx) then return end
        recompute(ctx)

        local b = self.bounds
        if not b then return end

        local theme = (ctx and ctx.theme) or Theme
        local hudTheme = theme.hud
        local colors = hudTheme.colors

        local ship = getPlayerShip(ctx)
        local loadout = ship and ship:has("weapon_loadout") and ship.weapon_loadout
        local activeSlot = loadout and loadout.activeSlot or 1
        local slots = loadout and loadout.slots or {}

        -- Background frame
        love.graphics.setColor(colors.panelBg[1], colors.panelBg[2], colors.panelBg[3], 0.85)
        love.graphics.rectangle("fill", b.x, b.y, b.w, b.h, 6, 6)
        love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], 0.6)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", b.x, b.y, b.w, b.h, 6, 6)

        -- Draw each slot
        local font = love.graphics.getFont()
        local mx, my = love.mouse.getPosition()

        for i, sb in ipairs(self.slotBounds) do
            local isActive = (i == activeSlot)
            local isHover = pointInRect(mx, my, sb)
            local weaponId = slots[i]

            -- Slot background
            if isActive then
                love.graphics.setColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.4)
            elseif isHover then
                love.graphics.setColor(1, 1, 1, 0.15)
            else
                love.graphics.setColor(0, 0, 0, 0.3)
            end
            love.graphics.rectangle("fill", sb.x, sb.y, sb.w, sb.h, 4, 4)

            -- Slot border
            if isActive then
                love.graphics.setColor(colors.accent[1], colors.accent[2], colors.accent[3], 0.9)
                love.graphics.setLineWidth(2)
            else
                love.graphics.setColor(colors.panelBorder[1], colors.panelBorder[2], colors.panelBorder[3], 0.5)
                love.graphics.setLineWidth(1)
            end
            love.graphics.rectangle("line", sb.x, sb.y, sb.w, sb.h, 4, 4)

            -- Draw weapon icon
            if weaponId then
                local iconSize = SLOT_SIZE - 12
                WeaponIcons.draw(weaponId, sb.x + 6, sb.y + 6, iconSize, iconSize, { alpha = isActive and 1 or 0.7 })
            end

            -- Keybind number (in header area above slot)
            local keyStr = tostring(i)
            local keyW = font:getWidth(keyStr)
            local keyH = font:getHeight()
            local keyX = sb.x + (sb.w - keyW) / 2
            local keyY = sb.y - HEADER_H + (HEADER_H - keyH) / 2 -- Centered in header

            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.print(keyStr, keyX + 1, keyY + 1)
            love.graphics.setColor(1, 1, 1, 0.9)
            love.graphics.print(keyStr, keyX, keyY)
        end

        love.graphics.setColor(1, 1, 1, 1)
    end

    function self.mousepressed(ctx, x, y, button)
        if not ctx or getMapOpen(ctx) then return false end
        recompute(ctx)

        if not self.bounds or not pointInRect(x, y, self.bounds) then
            return false
        end

        if button == 1 then
            local slot = getSlotAt(x, y)
            if slot then
                switchToSlot(ctx, slot)
                return true
            end
        end

        return false
    end

    function self.keypressed(ctx, key)
        if not ctx or getMapOpen(ctx) then return false end

        -- Check for 1-5 keys
        local slotNum = tonumber(key)
        if slotNum and slotNum >= 1 and slotNum <= 5 then
            return switchToSlot(ctx, slotNum)
        end

        return false
    end

    return self
end

return makeHotbarBottomCenter()
