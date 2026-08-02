-- RSL game state machine — client
-- A small state machine that gates which gameplay systems are active.
-- Other resources register states via exports['rsl_core']:RegisterGameState
-- and transition with exports['rsl_core']:SetGameState.

local states = {} ---@type table<string, { onEnter: function?, onExit: function?, onTick: function?, tickWait: integer? }>
local currentState = nil ---@type string?
local tickThread = nil

local function runTickLoop(stateId, def)
    CreateThread(function()
        while currentState == stateId do
            def.onTick()
            Wait(def.tickWait or 0)
        end
    end)
end

---@param id string
---@param def { onEnter: function?, onExit: function?, onTick: function?, tickWait: integer? }
local function registerGameState(id, def)
    if type(id) ~= 'string' or type(def) ~= 'table' then return false end
    states[id] = def
    return true
end

---@param id string
---@return boolean
local function setGameState(id)
    if type(id) ~= 'string' or not states[id] then return false end
    if currentState == id then return true end

    local previous = currentState
    local previousDef = previous and states[previous]
    if previousDef and previousDef.onExit then
        previousDef.onExit(id)
    end

    currentState = id
    TriggerServerEvent('rsl_core:setPlayerGameState', id)

    local def = states[id]
    if def.onEnter then
        def.onEnter(previous)
    end
    if def.onTick then
        runTickLoop(id, def)
    end

    TriggerEvent('rsl_core:gameStateChanged', id, previous)
    return true
end

local function getGameState()
    return currentState
end

exports('RegisterGameState', registerGameState)
exports('SetGameState', setGameState)
exports('GetGameState', getGameState)

-- Built-in states have no special enter/exit behavior by default; other
-- modules (garage_c, dealership_c, hud_c, etc.) hook rsl_core:gameStateChanged
-- to react instead of owning the state's lifecycle here.
for _, id in pairs(GameState) do
    registerGameState(id, {})
end

CreateThread(function()
    Wait(0)
    setGameState(GameState.MAIN_MENU)
end)
