-- RSL HUD — client
-- Minimal speedometer for phase 1. rsl_drift hooks into the same NUI page
-- later to add drift score/combo readouts alongside this.

local enabled = true
local visible = false

---@param on boolean
---@return boolean
local function setHudEnabled(on)
    if type(on) ~= 'boolean' then return false end
    enabled = on
    if not on and visible then
        visible = false
        SendNUIMessage({ action = 'hud:hide' })
    end
    return true
end

CreateThread(function()
    while true do
        Wait(100)

        if not enabled then goto continue end

        local ped = PlayerPedId()
        local inVehicle = IsPedInAnyVehicle(ped, false) and GetPedInVehicleSeat(GetVehiclePedIsIn(ped, false), -1) == ped

        if inVehicle then
            if not visible then
                visible = true
                SendNUIMessage({ action = 'hud:show' })
            end

            local veh = GetVehiclePedIsIn(ped, false)
            local speedMs = GetEntitySpeed(veh)
            local unit = RSLConfig.SPEED_UNIT
            local speed = unit == 'kmh' and (speedMs * 3.6) or (speedMs * 2.23694)
            local maxSpeedMs = GetVehicleEstimatedMaxSpeed(veh)
            local maxSpeed = unit == 'kmh' and (maxSpeedMs * 3.6) or (maxSpeedMs * 2.23694)

            SendNUIMessage({
                action = 'hud:update',
                speed = speed,
                maxSpeed = maxSpeed,
                gear = GetVehicleCurrentGear(veh),
                unit = unit,
            })
        elseif visible then
            visible = false
            SendNUIMessage({ action = 'hud:hide' })
        end

        ::continue::
    end
end)

exports('SetHudEnabled', setHudEnabled)
