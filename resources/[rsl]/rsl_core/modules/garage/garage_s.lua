-- RSL garage — server
-- Vehicle ownership storage. Rows live in `rsl_vehicles`; `stored = 1` means
-- parked in the garage, `stored = 0` means currently out in the world.
-- Ownership is scoped to the active character, not the account.

local PLATE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

local function generatePlate()
    for _ = 1, 20 do
        local chars = {}
        for i = 1, 8 do
            local idx = math.random(1, #PLATE_CHARS)
            chars[i] = PLATE_CHARS:sub(idx, idx)
        end
        local plate = table.concat(chars)
        local existing = MySQL.scalar.await('SELECT 1 FROM rsl_vehicles WHERE plate = ?', { plate })
        if not existing then return plate end
    end
    error('rsl_garage: failed to generate a unique plate after 20 attempts')
end

-- Some MySQL drivers return TINYINT(1) as a boolean instead of 0/1. Normalize
-- to a plain number so every consumer (server, client, NUI) sees one shape.
---@param row table
---@return table
local function normalizeStored(row)
    row.stored = (row.stored == true or row.stored == 1) and 1 or 0
    return row
end

---@param characterId string
---@param model string
---@param garageId string
---@return string vehicleId
local function addVehicleToGarage(characterId, model, garageId)
    local id = MySQL.scalar.await('SELECT UUID()')
    local plate = generatePlate()
    MySQL.insert.await(
        'INSERT INTO rsl_vehicles (id, owner_character_id, model, plate, garage_id, stored, mods, tuning) VALUES (?, ?, ?, ?, ?, 1, ?, ?)',
        { id, characterId, model, plate, garageId, '{}', '{}' }
    )
    return id
end

---@param source integer
---@return table
local function getOwnedVehicles(source)
    local characterId = exports['rsl_core']:GetActiveCharacterId(source)
    if not characterId then return {} end
    local rows = MySQL.query.await(
        'SELECT id, model, plate, garage_id, stored, xp, level FROM rsl_vehicles WHERE owner_character_id = ? ORDER BY created_at ASC',
        { characterId }
    )
    for _, row in ipairs(rows) do normalizeStored(row) end
    return rows
end

RegisterNetEvent('rsl_garage:requestList', function(garageId)
    local src = source
    if type(garageId) ~= 'string' then return end
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    local vehicles = MySQL.query.await(
        'SELECT id, model, plate, garage_id, stored FROM rsl_vehicles WHERE owner_character_id = ? AND garage_id = ? ORDER BY created_at ASC',
        { characterId, garageId }
    )
    for _, row in ipairs(vehicles) do normalizeStored(row) end
    TriggerClientEvent('rsl_garage:list', src, vehicles, garageId)
end)

RegisterNetEvent('rsl_garage:spawnVehicle', function(vehicleId)
    local src = source
    if type(vehicleId) ~= 'string' then return end
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    local row = MySQL.single.await(
        'SELECT id, model, plate, garage_id, stored FROM rsl_vehicles WHERE id = ? AND owner_character_id = ?',
        { vehicleId, characterId }
    )
    if not row then return end
    normalizeStored(row)
    if row.stored == 0 then return end

    MySQL.update.await('UPDATE rsl_vehicles SET stored = 0 WHERE id = ?', { vehicleId })
    TriggerClientEvent('rsl_garage:doSpawn', src, row)
end)

RegisterNetEvent('rsl_garage:storeVehicle', function(vehicleId, plate)
    local src = source
    if type(vehicleId) ~= 'string' or type(plate) ~= 'string' then return end
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    local row = MySQL.single.await(
        'SELECT id, plate, stored FROM rsl_vehicles WHERE id = ? AND owner_character_id = ?',
        { vehicleId, characterId }
    )
    if not row then return end
    normalizeStored(row)
    if row.stored == 1 or row.plate ~= plate then return end

    MySQL.update.await('UPDATE rsl_vehicles SET stored = 1 WHERE id = ?', { vehicleId })
    TriggerClientEvent('rsl_garage:stored', src, vehicleId)
end)

exports('GetOwnedVehicles', getOwnedVehicles)
exports('AddVehicleToGarage', addVehicleToGarage)
