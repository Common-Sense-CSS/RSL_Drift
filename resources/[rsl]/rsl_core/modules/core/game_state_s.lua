-- RSL game state machine — server
-- Tracks each connected player's last-reported client-side game state so
-- server logic (economy, drift scoring, etc.) can gate on it.

local playerStates = {} ---@type table<integer, string>

RegisterNetEvent('rsl_core:setPlayerGameState', function(id)
    local src = source
    if type(id) ~= 'string' then return end
    playerStates[src] = id
end)

AddEventHandler('playerDropped', function()
    playerStates[source] = nil
end)

---@param source integer
---@return string?
local function getPlayerGameState(source)
    return playerStates[source]
end

exports('GetPlayerGameState', getPlayerGameState)
