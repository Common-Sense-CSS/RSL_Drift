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
