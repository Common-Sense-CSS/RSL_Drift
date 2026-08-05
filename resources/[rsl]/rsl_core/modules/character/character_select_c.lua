-- RSL character select — client
-- Owns the MAIN_MENU state: freezes the player at RSLConfig.CHARACTER_PREVIEW,
-- shows a fixed preview camera, and lets the player pick/delete a slot or
-- head into creation (handled by character_creator_c.lua) for an empty one.
-- Also owns the shared "finalize into freeroam" handler used by both the
-- select and create flows, since confirming either ends the same way.

local cam = nil
local slots = {}

RSLCharacterState = { pendingSlotIndex = nil } ---@type table read by character_creator_c.lua

---@return integer ped
local function previewPed()
    return PlayerPedId()
end

local function enterPreviewPose()
    local ped = previewPed()
    local coords = RSLConfig.CHARACTER_PREVIEW
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    SetEntityHeading(ped, coords.w)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetEntityVisible(ped, true, false)

    if not cam then
        cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    end
    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.6, 0.4)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    local headPos = GetEntityCoords(ped)
    PointCamAtCoord(cam, headPos.x, headPos.y, headPos.z + 0.55)
    SetCamActive(cam, true)
    RenderScriptCams(true, false, 0, true, false)

    DisplayRadar(false)
end

local function exitPreviewPose()
    local ped = previewPed()
    FreezeEntityPosition(ped, false)
    SetEntityInvincible(ped, false)
    if cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(cam, false)
        cam = nil
    end
    DisplayRadar(true)
end

local nuiReady = false
local slotsRequestPending = false

local function requestSlots()
    TriggerServerEvent('rsl_debug:log', ('requestSlots(), nuiReady=%s'):format(tostring(nuiReady)))
    if nuiReady then
        TriggerServerEvent('rsl_character:requestSlots')
    else
        -- NUI (the CEF browser page) hasn't finished loading yet — this is
        -- common on a fresh connect since MAIN_MENU is entered almost
        -- immediately. Defer until character-select.js pings us back.
        slotsRequestPending = true
    end
end

RegisterNUICallback('characterSelect:ready', function(_, cb)
    TriggerServerEvent('rsl_debug:log', 'characterSelect:ready NUI callback fired')
    nuiReady = true
    if slotsRequestPending then
        slotsRequestPending = false
        TriggerServerEvent('rsl_character:requestSlots')
    end
    cb('ok')
end)

CreateThread(function()
    Wait(8000)
    if not nuiReady then
        TriggerServerEvent('rsl_debug:log', 'NUI never signaled ready after 8s')
    end
end)

RegisterNetEvent('rsl_character:slots', function(newSlots)
    slots = newSlots
    SendNUIMessage({ action = 'characterSelect:show', slots = slots })
end)

-- Shared finalize handler: fires whether a character was just selected or
-- just created (see character_s.lua — both paths emit the same event).
RegisterNetEvent('rsl_character:selected', function(character)
    exitPreviewPose()
    SendNUIMessage({ action = 'characterSelect:hide' })
    SendNUIMessage({ action = 'characterCreator:hide' })
    SetNuiFocus(false, false)

    RSLHelpers.SpawnPlayer(character.model, RSLConfig.DEFAULT_SPAWN, function()
        local ped = PlayerPedId()
        RSLAppearance.Apply(ped, character.model, character.appearance)
        Entity(ped).state:set('rsl:appearance', { model = character.model, appearance = character.appearance }, true)
        exports['rsl_core']:SetGameState(GameState.FREEROAM)
    end)
end)

RegisterNetEvent('rsl_character:selectFailed', function(message)
    exports['rsl_core']:ShowNotification({ title = message, type = 'error' })
end)

RegisterNUICallback('characterSelect:preview', function(data, cb)
    local slot = slots[data.slotIndex]
    if slot and slot.occupied then
        local hash = GetHashKey(slot.model)
        RSLHelpers.LoadModel(hash)
        SetPlayerModel(PlayerId(), hash)
        SetModelAsNoLongerNeeded(hash)
        RSLAppearance.Apply(previewPed(), slot.model, slot.appearance)
    end
    cb('ok')
end)

RegisterNUICallback('characterSelect:play', function(data, cb)
    TriggerServerEvent('rsl_character:select', data.id)
    cb('ok')
end)

RegisterNUICallback('characterSelect:create', function(data, cb)
    RSLCharacterState.pendingSlotIndex = data.slotIndex
    exports['rsl_core']:SetGameState(GameState.AVATAR)
    cb('ok')
end)

RegisterNUICallback('characterSelect:delete', function(data, cb)
    TriggerServerEvent('rsl_character:delete', data.id)
    cb('ok')
end)

exports['rsl_core']:RegisterGameState(GameState.MAIN_MENU, {
    onEnter = function()
        TriggerServerEvent('rsl_debug:log', 'MAIN_MENU onEnter fired')
        enterPreviewPose()
        SetNuiFocus(true, true)
        requestSlots()
    end,
    onExit = function(nextState)
        if nextState ~= GameState.AVATAR then
            SetNuiFocus(false, false)
        end
    end,
})
