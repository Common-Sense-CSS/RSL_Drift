-- RSL Drift Framework — global configuration
-- Shared between client and server. Edit these values to customize the framework.

RSLConfig = {
    STARTING_CASH        = 5000,
    SAVE_INTERVAL_MS      = 5 * 60 * 1000, -- flush player cache to DB every 5 minutes
    SPEED_UNIT            = 'mph',          -- 'mph' or 'kmh'
    DEFAULT_SPAWN         = vector4(-211.234, -1015.918, 24.35, 40.0),
    CHARACTER_SLOTS       = 3,
    -- Character select/creation preview spot. Reuses DEFAULT_SPAWN's
    -- confirmed on-ground coordinates rather than an unverified new location.
    CHARACTER_PREVIEW     = vector4(-211.234, -1018.918, 24.35, 220.0),
}

RSLProgressionConfig = {
    PLAYER_MAX_LEVEL      = 100,
    XP_CURVE_BASE          = 60,   -- xp required for level 2
    XP_CURVE_LINEAR        = 20,   -- linear growth per level
    XP_CURVE_QUADRATIC     = 1.5,  -- quadratic growth per level
}
