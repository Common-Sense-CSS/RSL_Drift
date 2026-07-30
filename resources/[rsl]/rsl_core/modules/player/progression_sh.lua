-- RSL progression — shared XP curve helpers.
-- xpForLevel(n) = XP required to go from level n to level n+1.

RSLProgression = {}

---@param level integer
---@return integer
function RSLProgression.XpForLevel(level)
    local cfg = RSLProgressionConfig
    return math.floor(cfg.XP_CURVE_BASE + (level * cfg.XP_CURVE_LINEAR) + (level ^ 2 * cfg.XP_CURVE_QUADRATIC))
end

---@param xp integer
---@return integer level
---@return integer xpIntoLevel
---@return integer xpForNextLevel
function RSLProgression.LevelFromXp(xp)
    local level = 1
    local remaining = xp
    local maxLevel = RSLProgressionConfig.PLAYER_MAX_LEVEL

    while level < maxLevel do
        local needed = RSLProgression.XpForLevel(level)
        if remaining < needed then
            return level, remaining, needed
        end
        remaining = remaining - needed
        level = level + 1
    end

    return maxLevel, remaining, 0
end
