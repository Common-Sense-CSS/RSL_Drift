-- RSL client helpers — shared by garage/dealership/etc. prompts.

RSLHelpers = {}

-- Disable spawnmanager's autospawn immediately at resource start (not just
-- inside SpawnPlayer below). basic-gamemode turns autospawn ON and registers
-- its own random points when IT starts — both it and rsl_core start once at
-- server boot, before any player connects, so doing this here (not reactively
-- once a character is selected) wins that race. Without this, a player who
-- connects and gets their client-side spawn assigned before the character
-- select NUI round-trip finishes gets randomly placed by vanilla spawnmanager
-- first, which is exactly the "random spawn like base FiveM" symptom.
exports.spawnmanager:setAutoSpawn(false)

-- FXServer's built-in "Awaiting scripts" connecting screen is normally
-- dismissed automatically once the player gets a prompt vanilla spawn — but
-- we deliberately defer spawning until character select is finished, which
-- can take as long as the player wants. Left waiting, the client can fall
-- back to its own default placement logic, independent of spawnmanager
-- entirely (this is what produced the Zancudo River spawn, not the
-- autospawn race above). Every framework doing custom character selection
-- (ESX, QBCore, etc.) explicitly hands off from the connect screen instead
-- of waiting on a vanilla spawn — do the same, immediately at resource start.
ShutdownLoadingScreen()
ShutdownLoadingScreenNui()

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
