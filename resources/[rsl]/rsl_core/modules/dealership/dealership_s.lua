-- RSL dealership — server

---@param garageId string
---@return table?
local function findGarage(garageId)
    for _, g in ipairs(RSLGarages) do
        if g.id == garageId then return g end
    end
    return nil
end

RegisterNetEvent('rsl_dealership:requestGarages', function()
    local src = source
    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    local list = {}
    for _, g in ipairs(RSLGarages) do
        local count = exports['rsl_core']:GetGarageVehicleCount(characterId, g.id)
        list[#list + 1] = {
            id = g.id,
            name = exports['rsl_core']:GetGarageName(src, g.id),
            count = count,
            max = RSLConfig.GARAGE_MAX_VEHICLES,
            full = count >= RSLConfig.GARAGE_MAX_VEHICLES,
        }
    end
    TriggerClientEvent('rsl_dealership:garages', src, list)
end)

RegisterNetEvent('rsl_dealership:purchase', function(model, dealershipId, mode, garageId)
    local src = source
    if type(model) ~= 'string' or type(dealershipId) ~= 'string' then return end
    if mode ~= 'drive' and mode ~= 'garage' then return end

    local vehicle = RSLVehicles[model]
    if not vehicle then return end

    local dealership
    for _, d in ipairs(RSLDealerships) do
        if d.id == dealershipId then dealership = d break end
    end
    if not dealership then return end

    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    -- A garage is required either way now — "drive now" needs a real home
    -- garage too, so a later auto-swap (see garage_s.lua's
    -- spawnVehicleForCharacter) has somewhere to actually return it instead
    -- of a fixed default the player never chose.
    if type(garageId) ~= 'string' or not findGarage(garageId) then return end
    local count = exports['rsl_core']:GetGarageVehicleCount(characterId, garageId)
    if count >= RSLConfig.GARAGE_MAX_VEHICLES then
        TriggerClientEvent('rsl_dealership:purchaseResult', src, false, 'That garage is full.')
        return
    end

    local ok = exports['rsl_core']:RemovePlayerCash(src, vehicle.price)
    if not ok then
        TriggerClientEvent('rsl_dealership:purchaseResult', src, false, 'Not enough cash.')
        return
    end

    local vehicleId = exports['rsl_core']:AddVehicleToGarage(characterId, model, garageId)

    if mode == 'drive' then
        exports['rsl_core']:SpawnOwnedVehicle(src, characterId, vehicleId, dealership.spawnCoords)
        TriggerClientEvent('rsl_dealership:purchaseResult', src, true, ('Purchased %s!'):format(vehicle.label))
    else
        local garageName = exports['rsl_core']:GetGarageName(src, garageId)
        TriggerClientEvent('rsl_dealership:purchaseResult', src, true, ('Purchased %s! Sent to %s.'):format(vehicle.label, garageName))
    end
end)
