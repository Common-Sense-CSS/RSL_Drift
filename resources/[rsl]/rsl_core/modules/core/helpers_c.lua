-- RSL client helpers — shared by garage/dealership/etc. prompts.

RSLHelpers = {}

---@param coords vector3
---@param text string
function RSLHelpers.DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(true)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    DrawText(x, y)

    local factor = #text / 370
    DrawRect(x, y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 130)
end

---@param coords vector3
---@param sprite integer
---@param colour integer
---@param label string
function RSLHelpers.CreateBlip(coords, sprite, colour, label)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, colour)
    SetBlipScale(blip, 0.85)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

---@param coords vector3
function RSLHelpers.DrawLocationMarker(coords)
    DrawMarker(1, coords.x, coords.y, coords.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 3.0, 3.0, 1.0, 139, 61, 255, 140, false, false, 2, false, nil, nil, false)
end

---@param hash integer
---@return boolean
function RSLHelpers.LoadModel(hash)
    if HasModelLoaded(hash) then return true end
    RequestModel(hash)
    local timeout = 0
    while not HasModelLoaded(hash) and timeout < 5000 do
        Wait(50)
        timeout = timeout + 50
    end
    return HasModelLoaded(hash)
end

-- Spawns/warps the local player into the world with the given model at
-- coords (vector4, w = heading). Bypasses spawnmanager's registered-points
-- pool (basic-gamemode also registers points there) so it's deterministic.
-- `cb`, if given, runs once spawnmanager reports the spawn complete (the new
-- ped handle is only guaranteed stable at that point, not immediately after
-- this call returns).
---@param model string
---@param coords vector4
---@param cb function?
function RSLHelpers.SpawnPlayer(model, coords, cb)
    exports.spawnmanager:setAutoSpawn(false)
    exports.spawnmanager:spawnPlayer({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = coords.w,
        model = model,
    }, cb)
end
