-- RSL inventory — client
-- TAB toggles a grid of RSLConfig.INVENTORY_SLOTS cells. Server is
-- authoritative for every move/use/drop — this file only requests state and
-- renders whatever the server sends back; it never applies a move locally.

local isOpen = false

local function closeInventory()
    if not isOpen then return end
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'inventory:hide' })
end

local function openInventory()
    if isOpen then return end
    isOpen = true
    SetNuiFocus(true, true)
    TriggerServerEvent('rsl_inventory:requestInventory')
end

-- Server only knows item_key/quantity/slot — enrich with the shared
-- RSLItems registry before handing off to NUI, same pattern
-- dealership_c.lua uses to build its catalog from RSLVehicles.
RegisterNetEvent('rsl_inventory:list', function(rows, weight)
    local items = {}
    for _, row in ipairs(rows) do
        local def = RSLItems[row.item_key]
        items[#items + 1] = {
            slot = row.slot,
            itemKey = row.item_key,
            quantity = row.quantity,
            label = def and def.label or row.item_key,
            description = def and def.description or '',
            weight = def and def.weight or 0,
            usable = def and def.usable or false,
        }
    end

    SendNUIMessage({
        action = 'inventory:show',
        items = items,
        slots = RSLConfig.INVENTORY_SLOTS,
        weight = weight,
        maxWeight = RSLConfig.INVENTORY_MAX_WEIGHT,
    })
end)

RegisterNetEvent('rsl_inventory:used', function(label)
    exports['rsl_core']:ShowNotification({ title = ('Used %s.'):format(label), type = 'success' })
end)

RegisterNUICallback('inventory:close', function(_, cb)
    closeInventory()
    cb('ok')
end)

RegisterNUICallback('inventory:move', function(data, cb)
    TriggerServerEvent('rsl_inventory:moveItem', data.from, data.to)
    cb('ok')
end)

RegisterNUICallback('inventory:use', function(data, cb)
    TriggerServerEvent('rsl_inventory:useItem', data.slot)
    cb('ok')
end)

RegisterNUICallback('inventory:drop', function(data, cb)
    TriggerServerEvent('rsl_inventory:dropItem', data.slot)
    cb('ok')
end)

RegisterKeyMapping('rsl_toggleinventory', 'Toggle Inventory', 'keyboard', 'TAB')
RegisterCommand('rsl_toggleinventory', function()
    if exports['rsl_core']:GetGameState() ~= GameState.FREEROAM then return end
    if isOpen then
        closeInventory()
    else
        openInventory()
    end
end, false)

AddEventHandler('rsl_core:gameStateChanged', function(newState)
    if newState ~= GameState.FREEROAM then
        closeInventory()
    end
end)
