-- RSL dealership — server

RegisterNetEvent('rsl_dealership:purchase', function(model, dealershipId)
    local src = source
    if type(model) ~= 'string' or type(dealershipId) ~= 'string' then return end

    local vehicle = RSLVehicles[model]
    if not vehicle then return end

    local dealership
    for _, d in ipairs(RSLDealerships) do
        if d.id == dealershipId then dealership = d break end
    end
    if not dealership then return end

    local characterId = exports['rsl_core']:GetActiveCharacterId(src)
    if not characterId then return end

    local ok = exports['rsl_core']:RemovePlayerCash(src, vehicle.price)
    if not ok then
        TriggerClientEvent('rsl_dealership:purchaseResult', src, false, 'Not enough cash.')
        return
    end

    exports['rsl_core']:AddVehicleToGarage(characterId, model, dealership.defaultGarageId)
    TriggerClientEvent('rsl_dealership:purchaseResult', src, true, ('Purchased %s! Check the garage.'):format(vehicle.label))
end)
