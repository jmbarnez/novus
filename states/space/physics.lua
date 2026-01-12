--- Space physics contact handling module
local SpacePhysics = {}

--- Begin contact callback - buffers contact for processing after physics step
---@param state table Space state object
---@param fixtureA userdata Box2D fixture A
---@param fixtureB userdata Box2D fixture B
---@param contact userdata Box2D contact
function SpacePhysics.beginContact(state, fixtureA, fixtureB, contact)
    local a = fixtureA:getUserData()
    local b = fixtureB:getUserData()

    if a == nil and b == nil then
        return
    end

    state.pendingContacts[#state.pendingContacts + 1] = { a = a, b = b, contact = contact }
end

--- End contact callback (currently unused)
---@param state table Space state object
---@param fixtureA userdata Box2D fixture A
---@param fixtureB userdata Box2D fixture B
---@param contact userdata Box2D contact
function SpacePhysics.endContact(state, fixtureA, fixtureB, contact)
    -- Currently unused, but available for future features
end

--- Process buffered contacts after physics step
---@param state table Space state object
function SpacePhysics.drainContacts(state)
    if #state.pendingContacts == 0 then
        return
    end

    for i = 1, #state.pendingContacts do
        local c = state.pendingContacts[i]
        state.ecsWorld:emit("onContact", c.a, c.b, c.contact)
    end

    state.pendingContacts = {}
end

return SpacePhysics
