-- RSL garage — client
-- Proximity prompt near each RSLGarages entry; opens a NUI list of the
-- player's vehicles stored at that garage.

local isOpen = false
local currentGarageId = nil
local garageNames = {} ---@type table<string, string> garageId -> effective name (nickname or default)
local garageBlips = {} ---@type table<string, integer> garageId -> blip handle

local function closeGarage()
    if not isOpen then return end
    isOpen = false
    currentGarageId = nil
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

---@param garage table
---@return string
local function blipLabel(garage)
    return garageNames[garage.id] or garage.name
end

local function refreshBlipLabels()
    for _, garage in ipairs(RSLGarages) do
        local blip = garageBlips[garage.id]
        if blip then
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(blipLabel(garage))
            EndTextCommandSetBlipName(blip)
        end
    end
end

RegisterNetEvent('rsl_garage:names', function(names)
    garageNames = names or {}
    refreshBlipLabels()
end)

RegisterNetEvent('rsl_garage:renamed', function(garageId, name)
    garageNames[garageId] = name
    refreshBlipLabels()
    SendNUIMessage({ action = 'garage:renamed', garageId = garageId, name = name })
end)

AddEventHandler('rsl_core:gameStateChanged', function(newState)
    if newState == GameState.FREEROAM then
        TriggerServerEvent('rsl_garage:requestNames')
    end
end)

RegisterNetEvent('rsl_garage:list', function(vehicles, garageId, meta)
    isOpen = true
    currentGarageId = garageId
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'garage:show', vehicles = vehicles, garageId = garageId, meta = meta })
end)

RegisterNetEvent('rsl_garage:storeFailed', function(message)
    exports['rsl_core']:ShowNotification({ title = message, type = 'error' })
end)

-- If the client can't actually place a vehicle (unresolved garage data,
-- model load timeout, etc.) the server has already flipped it to `stored =
-- 0` before telling us to spawn it — without this, that failure would
-- silently strand the vehicle as neither stored nor in the world. Tell the
-- server to revert it and let the player know instead.
---@param vehicleId string
local function reportSpawnFailed(vehicleId)
    TriggerServerEvent('rsl_garage:spawnFailed', vehicleId)
    exports['rsl_core']:ShowNotification({ title = 'Could not spawn that vehicle — returned to storage.', type = 'error' })
end

RegisterNetEvent('rsl_garage:doSpawn', function(vehicle, previousList, coordsOverride)
    -- Auto-return: delete any vehicle the server says this character had out
    -- elsewhere, before spawning the newly requested one.
    for _, prev in ipairs(previousList or {}) do
        if prev.netId then
            local ent = NetworkGetEntityFromNetworkId(prev.netId)
            if ent ~= 0 and DoesEntityExist(ent) then
                SetEntityAsMissionEntity(ent, true, true)
                DeleteVehicle(ent)
            end
        end
    end

    local garage
    for _, g in ipairs(RSLGarages) do
        if g.id == vehicle.garage_id then garage = g break end
    end
    local spawn = coordsOverride or (garage and garage.spawnCoords)
    if not spawn then
        reportSpawnFailed(vehicle.id)
        return
    end

    local hash = GetHashKey(vehicle.model)
    if not loadModel(hash) then
        reportSpawnFailed(vehicle.id)
        return
    end

    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, false)
    PlaceObjectOnGroundProperly(veh)
    SetVehicleNumberPlateText(veh, vehicle.plate)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)

    TaskWarpPedIntoVehicle(PlayerPedId(), veh, -1)
    TriggerServerEvent('rsl_garage:reportSpawned', vehicle.id, VehToNet(veh))
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

-- Stores whatever vehicle the player is currently driving, at whichever
-- garage's modal is open — not necessarily that vehicle's own home garage,
-- so this also covers dropping a car off somewhere new.
RegisterNUICallback('garage:store', function(_, cb)
    if not currentGarageId then cb('ok') return end

    local ped = PlayerPedId()
    local plate = nil
    if IsPedInAnyVehicle(ped, false) then
        local veh = GetVehiclePedIsIn(ped, false)
        if GetPedInVehicleSeat(veh, -1) == ped then
            plate = GetVehicleNumberPlateText(veh):gsub('%s+$', '')
        end
    end

    if plate then
        TriggerServerEvent('rsl_garage:storeVehicle', currentGarageId, plate)
    else
        exports['rsl_core']:ShowNotification({ title = 'You need to be driving the vehicle to store it here.', type = 'error' })
    end
    cb('ok')
end)

RegisterNUICallback('garage:rename', function(data, cb)
    TriggerServerEvent('rsl_garage:rename', data.garageId, data.name)
    cb('ok')
end)

CreateThread(function()
    for _, garage in ipairs(RSLGarages) do
        garageBlips[garage.id] = RSLHelpers.CreateBlip(garage.coords, 357, 3, blipLabel(garage))
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
                RSLHelpers.DrawText3D(garage.coords, ('[E] %s'):format(blipLabel(garage)))
                if dist < 2.5 and IsControlJustReleased(0, 38) and not isOpen
                    and exports['rsl_core']:GetGameState() == GameState.FREEROAM then
                    TriggerServerEvent('rsl_garage:requestList', garage.id)
                end
            end
        end

        Wait(drawing and 0 or 400)
    end
end)
