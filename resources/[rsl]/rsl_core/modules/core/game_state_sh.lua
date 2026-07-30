-- RSL game state machine — shared state id constants.
-- Add-on resources (rsl_drift, etc.) can register additional states with
-- exports['rsl_core']:RegisterGameState(id, def) rather than editing this file.

GameState = {
    FREEROAM      = 'freeroam',
    GARAGE        = 'garage',
    DEALERSHIP    = 'dealership',
    TUNING_SHOP   = 'tuning_shop',
    DRIFT_EVENT   = 'drift_event',
    DRIFT_LOBBY   = 'drift_lobby',
    DRIFT_BATTLE  = 'drift_battle',
}
