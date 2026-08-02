fx_version 'cerulean'
game 'gta5'

author 'RSL'
description 'RSL Core — custom framework for the RSL Drift server'
version '0.1.0'

dependencies {
    'spawnmanager',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    'data/rsl_config.lua',
    'modules/core/game_state_sh.lua',
    'modules/player/progression_sh.lua',
}

client_scripts {
    'modules/core/spawn_c.lua',
    'modules/core/game_state_c.lua',
    'modules/notify/notify_c.lua',
    'modules/hud/hud_c.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/core/game_state_s.lua',
    'modules/player/player_data_s.lua',
}

ui_page 'html/index.html'

files {
    'html/**/*',
    'sql/schema.sql',
}
