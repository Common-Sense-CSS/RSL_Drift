fx_version 'cerulean'
game 'gta5'

author 'RSL'
description 'RSL Drift — custom loading screen'
version '1.0.0'

-- No loadscreen_manual_shutdown here on purpose: it dismisses on FXServer's
-- own default timing (same as the stock screen would). rsl_core separately
-- calls ShutdownLoadingScreen()/ShutdownLoadingScreenNui() at its own start
-- to fix an unrelated bug (the "Awaiting scripts" corner indicator sticking
-- around past this screen) — tying this screen's dismissal to rsl_core
-- starting successfully would mean a broken rsl_core start strands the
-- player here forever. Keeping the two independent is safer.
loadscreen 'html/index.html'

files {
    'html/index.html',
}
