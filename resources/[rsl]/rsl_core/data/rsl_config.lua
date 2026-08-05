-- RSL Drift Framework — global configuration
-- Shared between client and server. Edit these values to customize the framework.

RSLConfig = {
    STARTING_CASH        = 5000,
    SAVE_INTERVAL_MS      = 5 * 60 * 1000, -- flush player cache to DB every 5 minutes
    SPEED_UNIT            = 'mph',          -- 'mph' or 'kmh'
    DEFAULT_SPAWN         = vector4(-263.7985, -966.8971, 31.2243, 205.2894),
    CHARACTER_SLOTS       = 3,
    GARAGE_MAX_VEHICLES   = 15, -- per character, per garage
    -- Character select/creation preview spot. Identical x/y/z to
    -- DEFAULT_SPAWN (the only coordinate actually confirmed clear of nearby
    -- geometry by real testing) — only heading differs. A previous version
    -- of this used a nearby-but-unverified offset and the preview camera
    -- clipped into something there.
    CHARACTER_PREVIEW     = vector4(-263.7985, -966.8971, 31.2243, 205.2894),
}

RSLProgressionConfig = {
    PLAYER_MAX_LEVEL      = 100,
    XP_CURVE_BASE          = 60,   -- xp required for level 2
    XP_CURVE_LINEAR        = 20,   -- linear growth per level
    XP_CURVE_QUADRATIC     = 1.5,  -- quadratic growth per level
}
