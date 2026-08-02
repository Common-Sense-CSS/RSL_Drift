-- RSL garage — client
-- Proximity prompt near each RSLGarages entry; opens a NUI list of the
-- player's vehicles stored at that garage.

local isOpen = false

local function closeGarage()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'garage:hide' })
end

---@param hash integer
---@return boolean
local function loadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(50)
        timeout = timeout + 50
    end
    return HasModelLoaded(hash)
end

RegisterNetEvent('rsl_garage:list', function(vehicles, garageId)
    isOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'garage:show', vehicles = vehicles, garageId = garageId })
end)

RegisterNetEvent('rsl_garage:doSpawn', function(vehicle)
    local garage
    for _, g in ipairs(RSLGarages) do
        if g.id == vehicle.garage_id then garage = g break end
    end
    if not garage then return end

    local hash = GetHashKey(vehicle.model)
    if not loadModel(hash) then return end

    local spawn = garage.spawnCoords
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    PlaceObjectOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, vehicle.plate)
    SetModelAsNoLongerNeeded(hash)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    closeGarage()
end)

RegisterNetEvent('rsl_garage:stored', function(_vehicleId)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        SetEntityAsMissionEntity(veh, true, true)
        DeleteVehicle(veh)
    end
    closeGarage()
end)

RegisterNUICallback('garage:close', function(_, cb)
    closeGarage()
    cb('ok')
end)

RegisterNUICallback('garage:spawn', function(data, cb)
    TriggerServerEvent('rsl_garage:spawnVehicle', data.id)
    cb('ok')
end)

RegisterNUICallback('garage:store', function(data, cb)
    local ped = PlayerPedId()
    local plate = nil
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) == ped then
            plate = GetVehicleNumberPlateText(veh):gsub('%s+$', '')
        end
    end
    if plate then
        TriggerServerEvent('rsl_garage:storeVehicle', data.id, plate)
    end
    cb('ok')
end)

CreateThread(function()
    for _, garage in ipairs(RSLGarages) do
        RSLHelpers.CreateBlip(garage.coords, 357, 3, garage.name)
    end
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local drawing = false

        for _, garage in ipairs(RSLGarages) do
            local dist = #(playerCoords - garage.coords)
            if dist < 30.0 then
                drawing = true
                RSLHelpers.DrawLocationMarker(garage.coords)
            end
            if dist < 8.0 then
                RSLHelpers.DrawText3D(garage.coords, ('[E] %s'):format(garage.name))
                if dist < 2.5 and IsControlJustReleased(0, 38) and not isOpen then
                    TriggerServerEvent('rsl_garage:requestList', garage.id)
                end
            end
        end

        Wait(drawing and 0 or 400)
    end
end)
