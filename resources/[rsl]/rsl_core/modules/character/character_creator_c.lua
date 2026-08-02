-- RSL character creator — client
-- Owns the AVATAR state. Live-previews every slider/option on the ped as the
-- NUI posts changes, then hands off to the server on confirm. The shared
-- "finalize into freeroam" handling lives in character_select_c.lua since
-- both the select and create flows end the same way.

local cam = nil
local framing = 'face' ---@type 'face'|'body'
local slotIndex = nil
local model = 'mp_m_freemode_01'
local appearance = nil
local name = ''

---@return integer
local function previewPed()
    return PlayerPedId()
end

---@param t table
---@param path string
---@param value any
local function setPath(t, path, value)
    local parts = {}
    for part in path:gmatch('[^.]+') do parts[#parts + 1] = part end
    local node = t
    for i = 1, #parts - 1 do
        local key = tonumber(parts[i]) or parts[i]
        node = node[key]
        if type(node) ~= 'table' then return end
    end
    local lastKey = tonumber(parts[#parts]) or parts[#parts]
    node[lastKey] = value
end

local function applyLive()
    RSLAppearance.Apply(previewPed(), model, appearance)
end

local function updateCamera()
    local ped = previewPed()
    local dy, dz = 1.15, 0.68
    if framing == 'body' then dy, dz = 3.0, 0.05 end

    local camPos = GetOffsetFromEntityInWorldCoords(ped, 0.0, dy, dz)
    SetCamCoord(cam, camPos.x, camPos.y, camPos.z)
    local headPos = GetEntityCoords(ped)
    PointCamAtCoord(cam, headPos.x, headPos.y, headPos.z + dz)
end

local function setGender(gender)
    model = gender == 'female' and 'mp_f_freemode_01' or 'mp_m_freemode_01'
    appearance = RSLCharacterOptions.DefaultAppearance(model)

    local hash = GetHashKey(model)
    RSLHelpers.LoadModel(hash)
    SetPlayerModel(PlayerId(), hash)
    SetModelAsNoLongerNeeded(hash)
    local ped = previewPed()
    SetEntityCoords(ped, RSLConfig.CHARACTER_PREVIEW.x, RSLConfig.CHARACTER_PREVIEW.y, RSLConfig.CHARACTER_PREVIEW.z, false, false, false, false)
    SetEntityHeading(ped, RSLConfig.CHARACTER_PREVIEW.w)
    FreezeEntityPosition(ped, true)
    applyLive()

    SendNUIMessage({ action = 'characterCreator:resetControls', appearance = appearance, gender = gender })
end

RegisterNUICallback('creator:setGender', function(data, cb)
    setGender(data.gender)
    cb('ok')
end)

RegisterNUICallback('creator:setName', function(data, cb)
    name = type(data.name) == 'string' and data.name:sub(1, 32) or ''
    cb('ok')
end)

RegisterNUICallback('creator:update', function(data, cb)
    setPath(appearance, data.path, data.value)
    applyLive()
    cb('ok')
end)

RegisterNUICallback('creator:setFraming', function(data, cb)
    framing = data.framing == 'body' and 'body' or 'face'
    cb('ok')
end)

RegisterNUICallback('creator:rotate', function(data, cb)
    local ped = previewPed()
    local delta = (tonumber(data.delta) or 0.0)
    SetEntityHeading(ped, (GetEntityHeading(ped) + delta) % 360.0)
    cb('ok')
end)

RegisterNUICallback('creator:back', function(_, cb)
    exports['rsl_core']:SetGameState(GameState.MAIN_MENU)
    cb('ok')
end)

RegisterNUICallback('creator:confirm', function(_, cb)
    if slotIndex and name ~= '' then
        TriggerServerEvent('rsl_character:create', slotIndex, name, model, appearance)
    end
    cb('ok')
end)

exports['rsl_core']:RegisterGameState(GameState.AVATAR, {
    onEnter = function()
        slotIndex = RSLCharacterState.pendingSlotIndex
        name = ''
        framing = 'face'

        if not cam then
            cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
        end
        SetCamActive(cam, true)
        RenderScriptCams(true, false, 0, true, false)
        DisplayRadar(false)

        setGender('male')
        updateCamera()

        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'characterCreator:show', appearance = appearance, gender = 'male' })
    end,
    onTick = function()
        if cam then updateCamera() end
    end,
    tickWait = 0,
    onExit = function(nextState)
        FreezeEntityPosition(previewPed(), false)
        if cam then
            RenderScriptCams(false, false, 0, true, false)
            DestroyCam(cam, false)
            cam = nil
        end
        DisplayRadar(true)
        if nextState ~= GameState.MAIN_MENU then
            SetNuiFocus(false, false)
        end
    end,
})
