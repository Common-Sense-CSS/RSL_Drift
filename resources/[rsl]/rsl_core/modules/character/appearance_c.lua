-- RSL character appearance — client
-- Applies a sanitized appearance table (see data/rsl_character_options.lua)
-- to any ped: the creator's live preview, the select-screen preview, the
-- local player on spawn, or a remote player's ped via the state bag handler
-- in modules/character/appearance_sync_c.lua.

RSLAppearance = {}

-- GTA head overlay indices (fixed by the game, not configurable).
local OVERLAY_BLEMISHES  = 0
local OVERLAY_FACIALHAIR = 1
local OVERLAY_EYEBROWS   = 2
local OVERLAY_AGEING     = 3
local OVERLAY_COMPLEXION = 6
local OVERLAY_SUNDAMAGE  = 7

---@param ped integer
---@param model string
---@param appearance table
function RSLAppearance.Apply(ped, model, appearance)
    SetPedDefaultComponentVariation(ped)

    local hb = appearance.headBlend
    SetPedHeadBlendData(ped, hb.shapeFirst, hb.shapeSecond, hb.shapeThird, hb.skinFirst, hb.skinSecond, hb.skinThird, hb.shapeMix, hb.skinMix, hb.thirdMix, false)

    for i = 1, RSLCharacterOptions.FACE_FEATURE_COUNT do
        SetPedFaceFeature(ped, i - 1, appearance.faceFeatures[i] or 0.0)
    end

    SetPedComponentVariation(ped, 2, appearance.hair.style, 0, 0)
    SetPedHairColor(ped, appearance.hair.color, appearance.hair.highlight)

    SetPedHeadOverlay(ped, OVERLAY_EYEBROWS, appearance.eyebrows.style, appearance.eyebrows.opacity)
    SetPedHeadOverlayColor(ped, OVERLAY_EYEBROWS, 1, appearance.eyebrows.color, appearance.eyebrows.color)

    if appearance.facialHair.style >= 0 then
        SetPedHeadOverlay(ped, OVERLAY_FACIALHAIR, appearance.facialHair.style, appearance.facialHair.opacity)
        SetPedHeadOverlayColor(ped, OVERLAY_FACIALHAIR, 1, appearance.facialHair.color, appearance.facialHair.color)
    else
        SetPedHeadOverlay(ped, OVERLAY_FACIALHAIR, 255, 0.0)
    end

    SetPedEyeColor(ped, appearance.eyeColor)

    local overlays = {
        { key = 'blemishes',  index = OVERLAY_BLEMISHES },
        { key = 'ageing',     index = OVERLAY_AGEING },
        { key = 'complexion', index = OVERLAY_COMPLEXION },
        { key = 'sunDamage',  index = OVERLAY_SUNDAMAGE },
    }
    for _, entry in ipairs(overlays) do
        local o = appearance.overlays[entry.key]
        if o.index >= 0 then
            SetPedHeadOverlay(ped, entry.index, o.index, o.opacity)
        else
            SetPedHeadOverlay(ped, entry.index, 255, 0.0)
        end
    end

    for slot, componentId in pairs(RSLCharacterOptions.CLOTHING_COMPONENTS) do
        local c = appearance.clothing[slot]
        SetPedComponentVariation(ped, componentId, c.drawable, c.texture, 0)
    end
end
