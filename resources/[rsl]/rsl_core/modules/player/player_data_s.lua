-- RSL player data & economy — server
-- Accounts (license identifiers) hold up to RSLConfig.CHARACTER_SLOTS
-- characters in `rsl_characters`. Nothing is "the active player" until a
-- character is selected/created — see modules/character/character_s.lua for
-- the net-event layer that drives GetCharacterSlots/SelectCharacter/
-- CreateCharacter/DeleteCharacter below. Economy/progression/data exports
-- all operate on whichever character is currently active for `source`.

local dbReady = false
local identifiers = {} ---@type table<integer, string> source -> license identifier
local activeCharacter = {} ---@type table<integer, string> source -> character id
local characters = {} ---@type table<string, table> character id -> cached row

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

---@param json_ string
---@return table
local function decodeOrEmpty(json_)
    local ok, decoded = pcall(json.decode, json_)
    return (ok and type(decoded) == 'table') and decoded or {}
end

-- Persist ---------------------------------------------------------------

---@param characterId string
local function persistCharacter(characterId)
    local char = characters[characterId]
    if not char or not char.dirty then return end

    MySQL.update.await(
        'UPDATE rsl_characters SET name = ?, cash = ?, xp = ?, level = ?, appearance = ?, data = ?, last_played_at = NOW(3) WHERE id = ?',
        { char.name, char.cash, char.xp, char.level, json.encode(char.appearance), json.encode(char.data), characterId }
    )
    char.dirty = false
end

CreateThread(function()
    while true do
        Wait(RSLConfig.SAVE_INTERVAL_MS)
        for characterId in pairs(characters) do
            persistCharacter(characterId)
        end
    end
end)

-- Connection lifecycle --------------------------------------------------

AddEventHandler('playerConnecting', function(_name, _setKickReason, deferrals)
    local src = source
    print(('^3[rsl_playerConnecting]^7 fired for #%d, dbReady=%s'):format(src, tostring(dbReady)))
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
            print(('^1[rsl_playerConnecting]^7 #%d rejected: database never became ready'):format(src))
            deferrals.done('Database is not ready. Please try reconnecting shortly.')
            return
        end
    end

    deferrals.update('Verifying your account...')

    local identifier = GetPlayerIdentifierByType(src --[[@as string]], 'license')
    print(('^3[rsl_playerConnecting]^7 #%d GetPlayerIdentifierByType(license) = %s'):format(src, tostring(identifier)))
    if not identifier then
        print(('^1[rsl_playerConnecting]^7 #%d rejected: no license identifier'):format(src))
        deferrals.done('Could not verify your license identifier.')
        return
    end

    identifiers[src] = identifier
    print(('^2[rsl_playerConnecting]^7 #%d identifier stored, calling deferrals.done()'):format(src))
    deferrals.done()
end)

AddEventHandler('playerDropped', function()
    local src = source --[[@as integer]]
    local characterId = activeCharacter[src]
    if characterId then
        persistCharacter(characterId)
        characters[characterId] = nil
        activeCharacter[src] = nil
    end
    identifiers[src] = nil
end)

-- Internal helper ---------------------------------------------------------

---@param source integer
---@return table?
local function getPlayer(source)
    local characterId = activeCharacter[source]
    if not characterId then return nil end
    return characters[characterId]
end

-- Character CRUD ------------------------------------------------------------

---@param row table raw DB row
---@return table cached character
local function cacheCharacterRow(row)
    local char = {
        id = row.id,
        ownerIdentifier = row.owner_identifier,
        slotIndex = row.slot_index,
        name = row.name,
        model = row.model,
        appearance = decodeOrEmpty(row.appearance),
        cash = row.cash,
        xp = row.xp,
        level = row.level,
        data = decodeOrEmpty(row.data),
        dirty = false,
    }
    characters[char.id] = char
    return char
end

---@param source integer
---@return table[] 3 slots: { slotIndex, occupied, id?, name?, model?, level? }
local function getCharacterSlots(source)
    local identifier = identifiers[source]
    if not identifier then
        print(('^1[rsl_playerConnecting]^7 getCharacterSlots(#%d): no cached identifier'):format(source))
        return {}
    end

    local rows = MySQL.query.await(
        'SELECT id, slot_index, name, model, level, appearance FROM rsl_characters WHERE owner_identifier = ?',
        { identifier }
    )

    local slots = {}
    for i = 1, RSLConfig.CHARACTER_SLOTS do
        slots[i] = { slotIndex = i, occupied = false }
    end
    for _, row in ipairs(rows) do
        if slots[row.slot_index] then
            slots[row.slot_index] = {
                slotIndex = row.slot_index,
                occupied = true,
                id = row.id,
                name = row.name,
                model = row.model,
                level = row.level,
                appearance = decodeOrEmpty(row.appearance),
            }
        end
    end
    return slots
end

---@param source integer
---@param characterId string
---@return table? character data for the client to apply/spawn with
local function selectCharacter(source, characterId)
    local identifier = identifiers[source]
    if not identifier or type(characterId) ~= 'string' then return nil end

    local row = MySQL.single.await(
        'SELECT * FROM rsl_characters WHERE id = ? AND owner_identifier = ?',
        { characterId, identifier }
    )
    if not row then return nil end

    local char = cacheCharacterRow(row)
    activeCharacter[source] = char.id
    return char
end

---@param source integer
---@param slotIndex integer
---@param name string
---@param model string
---@param appearance table
---@return table? character data for the client to apply/spawn with
local function createCharacter(source, slotIndex, name, model, appearance)
    local identifier = identifiers[source]
    if not identifier then return nil end
    if type(slotIndex) ~= 'number' or slotIndex < 1 or slotIndex > RSLConfig.CHARACTER_SLOTS then return nil end
    if type(name) ~= 'string' or #name < 1 or #name > 32 then return nil end
    if model ~= 'mp_m_freemode_01' and model ~= 'mp_f_freemode_01' then return nil end
    appearance = RSLCharacterOptions.SanitizeAppearance(appearance, model)

    local existing = MySQL.scalar.await(
        'SELECT 1 FROM rsl_characters WHERE owner_identifier = ? AND slot_index = ?',
        { identifier, slotIndex }
    )
    if existing then return nil end

    local id = MySQL.scalar.await('SELECT UUID()')
    MySQL.insert.await(
        'INSERT INTO rsl_characters (id, owner_identifier, slot_index, name, model, appearance, cash, xp, level, data) VALUES (?, ?, ?, ?, ?, ?, ?, 0, 1, ?)',
        { id, identifier, slotIndex, name, model, json.encode(appearance), RSLConfig.STARTING_CASH, '{}' }
    )

    local char = cacheCharacterRow({
        id = id, owner_identifier = identifier, slot_index = slotIndex, name = name, model = model,
        appearance = json.encode(appearance), cash = RSLConfig.STARTING_CASH, xp = 0, level = 1, data = '{}',
    })
    activeCharacter[source] = char.id
    return char
end

---@param source integer
---@param characterId string
---@return boolean
local function deleteCharacter(source, characterId)
    local identifier = identifiers[source]
    if not identifier or type(characterId) ~= 'string' then return false end

    local owned = MySQL.scalar.await('SELECT 1 FROM rsl_characters WHERE id = ? AND owner_identifier = ?', { characterId, identifier })
    if not owned then return false end

    MySQL.query.await('DELETE FROM rsl_characters WHERE id = ?', { characterId })
    characters[characterId] = nil
    if activeCharacter[source] == characterId then
        activeCharacter[source] = nil
    end
    return true
end

---@param source integer
---@return string?
local function getActiveCharacterId(source)
    return activeCharacter[source]
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
    local characterId = activeCharacter[source]
    if not characterId then return false end
    persistCharacter(characterId)
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

exports('GetCharacterSlots', getCharacterSlots)
exports('SelectCharacter', selectCharacter)
exports('CreateCharacter', createCharacter)
exports('DeleteCharacter', deleteCharacter)
exports('GetActiveCharacterId', getActiveCharacterId)
