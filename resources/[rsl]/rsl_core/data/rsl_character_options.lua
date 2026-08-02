-- RSL character creator — shared options, defaults, and input sanitization.
-- Kept shared (not client-only) so the server can validate/clamp appearance
-- payloads from CreateCharacter before they're ever stored or broadcast to
-- other clients via the appearance state bag.

RSLCharacterOptions = {
    MODELS = { 'mp_m_freemode_01', 'mp_f_freemode_01' },
    HERITAGE_PRESET_COUNT = 21,  -- GTA freemode heritage face ids 0-20
    HAIR_STYLE_COUNT = 38,       -- clamped generously; invalid indices just show the closest valid style in-game
    FACE_FEATURE_COUNT = 20,
    CLOTHING_COMPONENTS = {
        top   = 11,
        under = 8,
        legs  = 4,
        shoes = 6,
    },
}

---@param n number
---@param min number
---@param max number
---@return number
local function clamp(n, min, max)
    if type(n) ~= 'number' then return min end
    if n < min then return min end
    if n > max then return max end
    return n
end

---@param n any
---@param min integer
---@param max integer
---@param default integer
---@return integer
local function clampInt(n, min, max, default)
    if type(n) ~= 'number' then return default end
    return math.floor(clamp(n, min, max))
end

---@param gender 'mp_m_freemode_01'|'mp_f_freemode_01'
---@return table
function RSLCharacterOptions.DefaultAppearance(gender)
    local faceFeatures = {}
    for i = 1, RSLCharacterOptions.FACE_FEATURE_COUNT do
        faceFeatures[i] = 0.0
    end

    return {
        headBlend = {
            shapeFirst = 0, shapeSecond = 0, shapeThird = 0,
            skinFirst = 0, skinSecond = 0, skinThird = 0,
            shapeMix = 0.5, skinMix = 0.5, thirdMix = 0.0,
        },
        faceFeatures = faceFeatures,
        hair = { style = 0, color = 0, highlight = 0 },
        eyebrows = { style = 0, color = 0, opacity = 1.0 },
        facialHair = { style = -1, color = 0, opacity = 1.0 },
        eyeColor = 0,
        overlays = {
            blemishes  = { index = -1, opacity = 1.0 },
            ageing     = { index = -1, opacity = 1.0 },
            complexion = { index = -1, opacity = 1.0 },
            sunDamage  = { index = -1, opacity = 1.0 },
        },
        clothing = {
            top   = { drawable = 0, texture = 0 },
            under = { drawable = 0, texture = 0 },
            legs  = { drawable = 0, texture = 0 },
            shoes = { drawable = 0, texture = 0 },
        },
    }
end

-- Clamps/validates an untrusted appearance table (e.g. from a client's
-- CreateCharacter request) into a well-shaped table safe to store and
-- broadcast. Missing/invalid fields fall back to defaults rather than
-- rejecting the whole payload.
---@param raw table?
---@param gender string
---@return table
function RSLCharacterOptions.SanitizeAppearance(raw, gender)
    local default = RSLCharacterOptions.DefaultAppearance(gender)
    if type(raw) ~= 'table' then return default end

    local hb = type(raw.headBlend) == 'table' and raw.headBlend or {}
    local heritageMax = RSLCharacterOptions.HERITAGE_PRESET_COUNT - 1
    default.headBlend = {
        shapeFirst  = clampInt(hb.shapeFirst, 0, heritageMax, 0),
        shapeSecond = clampInt(hb.shapeSecond, 0, heritageMax, 0),
        shapeThird  = clampInt(hb.shapeThird, 0, heritageMax, 0),
        skinFirst   = clampInt(hb.skinFirst, 0, heritageMax, 0),
        skinSecond  = clampInt(hb.skinSecond, 0, heritageMax, 0),
        skinThird   = clampInt(hb.skinThird, 0, heritageMax, 0),
        shapeMix    = clamp(hb.shapeMix, 0.0, 1.0),
        skinMix     = clamp(hb.skinMix, 0.0, 1.0),
        thirdMix    = clamp(hb.thirdMix, 0.0, 1.0),
    }

    local ff = type(raw.faceFeatures) == 'table' and raw.faceFeatures or {}
    local faceFeatures = {}
    for i = 1, RSLCharacterOptions.FACE_FEATURE_COUNT do
        faceFeatures[i] = clamp(ff[i], -1.0, 1.0)
    end
    default.faceFeatures = faceFeatures

    local hair = type(raw.hair) == 'table' and raw.hair or {}
    default.hair = {
        style     = clampInt(hair.style, 0, RSLCharacterOptions.HAIR_STYLE_COUNT, 0),
        color     = clampInt(hair.color, 0, 63, 0),
        highlight = clampInt(hair.highlight, 0, 63, 0),
    }

    local brows = type(raw.eyebrows) == 'table' and raw.eyebrows or {}
    default.eyebrows = {
        style   = clampInt(brows.style, 0, 33, 0),
        color   = clampInt(brows.color, 0, 63, 0),
        opacity = clamp(brows.opacity, 0.0, 1.0),
    }

    local facial = type(raw.facialHair) == 'table' and raw.facialHair or {}
    default.facialHair = {
        style   = clampInt(facial.style, -1, 28, -1),
        color   = clampInt(facial.color, 0, 63, 0),
        opacity = clamp(facial.opacity, 0.0, 1.0),
    }

    default.eyeColor = clampInt(raw.eyeColor, 0, 31, 0)

    local overlays = type(raw.overlays) == 'table' and raw.overlays or {}
    for key, bounds in pairs({
        blemishes  = 23,
        ageing     = 14,
        complexion = 11,
        sunDamage  = 10,
    }) do
        local o = type(overlays[key]) == 'table' and overlays[key] or {}
        default.overlays[key] = {
            index   = clampInt(o.index, -1, bounds, -1),
            opacity = clamp(o.opacity, 0.0, 1.0),
        }
    end

    local clothing = type(raw.clothing) == 'table' and raw.clothing or {}
    for slot in pairs(RSLCharacterOptions.CLOTHING_COMPONENTS) do
        local c = type(clothing[slot]) == 'table' and clothing[slot] or {}
        default.clothing[slot] = {
            drawable = clampInt(c.drawable, 0, 200, 0),
            texture  = clampInt(c.texture, 0, 20, 0),
        }
    end

    return default
end
