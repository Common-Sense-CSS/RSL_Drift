-- RSL player data & economy — server
-- One persistent row per player (license identifier). Loaded before the
-- player is allowed to join, cached in memory while connected, flushed to
-- the database on an interval, on drop, and on explicit PersistPlayer calls.

local dbReady = false
local players = {} ---@type table<string, table> keyed by identifier: { source, name, cash, xp, level, data, dirty }
local sourceToIdentifier = {} ---@type table<integer, string>

MySQL.ready(function()
    local schema = LoadResourceFile(GetCurrentResourceName(), 'sql/schema.sql')
    for statement in schema:gmatch('[^;]+') do
        if statement:match('%S') then
            MySQL.query.await(statement)
        end
    end
    dbReady = true
end)

-- Path utilities for the flexible `data` JSON column ------------------------

---@param t table
---@param path string
---@return any
local function resolvePath(t, path)
    local node = t
    for part in path:gmatch('[^.]+') do
        if type(node) ~= 'table' then return nil end
        node = node[part]
    end
    return node
end

---@param t table
---@param path string
---@param value any
local function mutatePath(t, path, value)
    local parts = {}
    for part in path:gmatch('[^.]+') do
        parts[#parts + 1] = part
    end
    local node = t
    for i = 1, #parts - 1 do
        local part = parts[i]
        if type(node[part]) ~= 'table' then
            node[part] = {}
        end
        node = node[part]
    end
    node[parts[#parts]] = value
end

-- Load / persist --------------------------------------------------------

---@param identifier string
---@param name string
---@return table
local function loadOrCreatePlayer(identifier, name)
    local row = MySQL.single.await('SELECT * FROM rsl_players WHERE identifier = ?', { identifier })

    if not row then
        MySQL.insert.await(
            'INSERT INTO rsl_players (identifier, name, cash, xp, level, data) VALUES (?, ?, ?, ?, ?, ?)',
            { identifier, name, RSLConfig.STARTING_CASH, 0, 1, '{}' }
        )
        return {
            identifier = identifier,
            name = name,
            cash = RSLConfig.STARTING_CASH,
            xp = 0,
            level = 1,
            data = {},
            dirty = false,
        }
    end

    local ok, decoded = pcall(json.decode, row.data)
    return {
        identifier = identifier,
        name = row.name,
        cash = row.cash,
        xp = row.xp,
        level = row.level,
        data = (ok and type(decoded) == 'table') and decoded or {},
        dirty = false,
    }
end

---@param identifier string
local function persistPlayer(identifier)
    local player = players[identifier]
    if not player or not player.dirty then return end

    MySQL.update.await(
        'UPDATE rsl_players SET name = ?, cash = ?, xp = ?, level = ?, data = ?, last_seen_at = NOW(3) WHERE identifier = ?',
        { player.name, player.cash, player.xp, player.level, json.encode(player.data), identifier }
    )
    player.dirty = false
end

CreateThread(function()
    while true do
        Wait(RSLConfig.SAVE_INTERVAL_MS)
        for identifier in pairs(players) do
            persistPlayer(identifier)
        end
    end
end)

-- Connection lifecycle --------------------------------------------------

AddEventHandler('playerConnecting', function(_name, _setKickReason, deferrals)
    local src = source
    deferrals.defer()
    Wait(0)

    if not dbReady then
        deferrals.update('Waiting for database connection...')
        local waited = 0
        while not dbReady and waited < 15000 do
            Wait(250)
            waited = waited + 250
        end
        if not dbReady then
            deferrals.done('Database is not ready. Please try reconnecting shortly.')
            return
        end
    end

    deferrals.update('Loading your driver profile...')

    local identifier = GetPlayerIdentifierByType(src --[[@as string]], 'license')
    if not identifier then
        deferrals.done('Could not verify your license identifier.')
        return
    end

    local name = GetPlayerName(src) or 'Driver'
    local player = loadOrCreatePlayer(identifier, name)
    players[identifier] = player
    sourceToIdentifier[src] = identifier

    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src = source --[[@as integer]]
    local identifier = sourceToIdentifier[src]
    if not identifier then return end

    persistPlayer(identifier)
    players[identifier] = nil
    sourceToIdentifier[src] = nil
end)

-- Internal helper ---------------------------------------------------------

---@param source integer
---@return table?
local function getPlayer(source)
    local identifier = sourceToIdentifier[source]
    if not identifier then return nil end
    return players[identifier]
end

-- Exports -----------------------------------------------------------------

---@param source integer
---@return boolean
local function hasPlayerLoaded(source)
    return getPlayer(source) ~= nil
end

---@param source integer
---@return number
local function getPlayerCash(source)
    local player = getPlayer(source)
    return player and player.cash or 0
end

---@param source integer
---@param amount number
---@return boolean
local function addPlayerCash(source, amount)
    local player = getPlayer(source)
    if not player or type(amount) ~= 'number' or amount <= 0 then return false end
    player.cash = player.cash + math.floor(amount)
    player.dirty = true
    TriggerClientEvent('rsl_core:cashUpdated', source, player.cash)
    return true
end

---@param source integer
---@param amount number
---@return boolean
local function removePlayerCash(source, amount)
    local player = getPlayer(source)
    if not player or type(amount) ~= 'number' or amount <= 0 then return false end
    if player.cash < amount then return false end
    player.cash = player.cash - math.floor(amount)
    player.dirty = true
    TriggerClientEvent('rsl_core:cashUpdated', source, player.cash)
    return true
end

---@param source integer
---@param amount number
---@return boolean
local function setPlayerCash(source, amount)
    local player = getPlayer(source)
    if not player or type(amount) ~= 'number' or amount < 0 then return false end
    player.cash = math.floor(amount)
    player.dirty = true
    TriggerClientEvent('rsl_core:cashUpdated', source, player.cash)
    return true
end

---@param source integer
---@return integer
local function getPlayerLevel(source)
    local player = getPlayer(source)
    return player and player.level or 1
end

---@param source integer
---@param level integer
---@return boolean
local function setPlayerLevel(source, level)
    local player = getPlayer(source)
    if not player or type(level) ~= 'number' then return false end
    level = math.floor(level)
    if level < 1 or level > RSLProgressionConfig.PLAYER_MAX_LEVEL then return false end

    player.level = level
    player.xp = 0
    for l = 1, level - 1 do
        player.xp = player.xp + RSLProgression.XpForLevel(l)
    end
    player.dirty = true
    TriggerClientEvent('rsl_core:xpUpdated', source, player.xp, player.level, { xpGained = 0, oldLevel = level, newLevel = level, levelUps = 0 })
    return true
end

---@param source integer
---@return integer
local function getPlayerXp(source)
    local player = getPlayer(source)
    return player and player.xp or 0
end

---@param source integer
---@param amount number
---@return table?
local function awardPlayerXp(source, amount)
    local player = getPlayer(source)
    if not player or type(amount) ~= 'number' or amount <= 0 then return nil end

    local oldLevel = player.level
    player.xp = player.xp + math.floor(amount)
    local newLevel = RSLProgression.LevelFromXp(player.xp)
    player.level = newLevel
    player.dirty = true

    local result = { xpGained = math.floor(amount), oldLevel = oldLevel, newLevel = newLevel, levelUps = newLevel - oldLevel }
    TriggerClientEvent('rsl_core:xpUpdated', source, player.xp, player.level, result)
    return result
end

---@param source integer
---@param path string
---@return any
local function readPlayerData(source, path)
    local player = getPlayer(source)
    if not player or type(path) ~= 'string' then return nil end
    return resolvePath(player.data, path)
end

---@param source integer
---@param path string
---@param value any
---@return boolean
local function writePlayerData(source, path, value)
    local player = getPlayer(source)
    if not player or type(path) ~= 'string' then return false end
    mutatePath(player.data, path, value)
    player.dirty = true
    return true
end

---@param source integer
---@return boolean
local function persistPlayerExport(source)
    local identifier = sourceToIdentifier[source]
    if not identifier then return false end
    persistPlayer(identifier)
    return true
end

exports('HasPlayerLoaded', hasPlayerLoaded)
exports('GetPlayerCash', getPlayerCash)
exports('AddPlayerCash', addPlayerCash)
exports('RemovePlayerCash', removePlayerCash)
exports('SetPlayerCash', setPlayerCash)
exports('GetPlayerLevel', getPlayerLevel)
exports('SetPlayerLevel', setPlayerLevel)
exports('GetPlayerXp', getPlayerXp)
exports('AwardPlayerXp', awardPlayerXp)
exports('ReadPlayerData', readPlayerData)
exports('WritePlayerData', writePlayerData)
exports('PersistPlayer', persistPlayerExport)
