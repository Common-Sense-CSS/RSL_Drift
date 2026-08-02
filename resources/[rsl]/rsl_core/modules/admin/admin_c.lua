-- RSL admin commands — client
-- Executes the in-world side of admin commands issued server-side in
-- modules/admin/admin_s.lua, after the ACE permission check has passed.

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

RegisterNetEvent('rsl_admin:spawnCar', function(model)
    local hash = GetHashKey(model)
    if not loadModel(hash) then
        exports['rsl_core']:ShowNotification({ title = ('Unknown vehicle model: %s'):format(model), type = 'error' })
        return
    end

    local ped = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 5.0, 0.0)
    local heading = GetEntityHeading(ped)
    local veh = CreateVehicle(hash, coords.x, coords.y, coords.z, heading, true, false)
    PlaceObjectOnGroundProperly(veh)
    SetModelAsNoLongerNeeded(hash)
    TaskWarpPedIntoVehicle(ped, veh, -1)
end)

RegisterNetEvent('rsl_admin:teleport', function(x, y, z)
    SetEntityCoords(PlayerPedId(), x + 0.0, y + 0.0, z + 0.0, false, false, false, true)
end)

RegisterNetEvent('rsl_admin:deleteVehicle', function()
    local ped = PlayerPedId()
    local veh = IsPedInAnyVehicle(ped, false) and GetVehiclePedIsIn(ped, false) or GetVehiclePedIsUsing(ped)
    if veh == 0 then return end
    SetEntityAsMissionEntity(veh, true, true)
    DeleteVehicle(veh)
end)
