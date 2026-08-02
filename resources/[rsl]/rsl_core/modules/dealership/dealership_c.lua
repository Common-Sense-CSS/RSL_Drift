-- RSL dealership — client
-- Proximity prompt near each RSLDealerships entry; opens a NUI catalog
-- browser backed by the shared RSLVehicles table.

local isOpen = false
local currentDealershipId = nil

local function closeDealership()
    if not isOpen then return end
    isOpen = false
    currentDealershipId = nil
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'dealership:hide' })
end

local function openDealership(dealership)
    isOpen = true
    currentDealershipId = dealership.id

    local catalog = {}
    for model, entry in pairs(RSLVehicles) do
        catalog[#catalog + 1] = {
            model = model,
            label = entry.label,
            brand = entry.brand,
            price = entry.price,
            category = entry.category,
        }
    end
    table.sort(catalog, function(a, b) return a.price < b.price end)

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'dealership:show', vehicles = catalog })
end

RegisterNetEvent('rsl_dealership:purchaseResult', function(ok, message)
    exports['rsl_core']:ShowNotification({ title = message, type = ok and 'success' or 'error' })
end)

RegisterNUICallback('dealership:close', function(_, cb)
    closeDealership()
    cb('ok')
end)

RegisterNUICallback('dealership:buy', function(data, cb)
    if currentDealershipId then
        TriggerServerEvent('rsl_dealership:purchase', data.model, currentDealershipId)
    end
    cb('ok')
end)

CreateThread(function()
    for _, dealership in ipairs(RSLDealerships) do
        RSLHelpers.CreateBlip(dealership.coords, 225, 5, dealership.name)
    end
end)

CreateThread(function()
    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local drawing = false

        for _, dealership in ipairs(RSLDealerships) do
            local dist = #(playerCoords - dealership.coords)
            if dist < 30.0 then
                drawing = true
                RSLHelpers.DrawLocationMarker(dealership.coords)
            end
            if dist < 8.0 then
                RSLHelpers.DrawText3D(dealership.coords, ('[E] %s'):format(dealership.name))
                if dist < 2.5 and IsControlJustReleased(0, 38) and not isOpen then
                    openDealership(dealership)
                end
            end
        end

        Wait(drawing and 0 or 400)
    end
end)
