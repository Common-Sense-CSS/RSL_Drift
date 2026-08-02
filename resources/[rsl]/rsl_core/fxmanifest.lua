fx_version 'cerulean'
game 'gta5'

author 'RSL'
description 'RSL Core — custom framework for the RSL Drift server'
version '0.2.0'

dependencies {
    'spawnmanager',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    'data/rsl_config.lua',
    'data/rsl_vehicles.lua',
    'data/rsl_garages.lua',
    'data/rsl_dealerships.lua',
    'modules/core/game_state_sh.lua',
    'modules/player/progression_sh.lua',
}

client_scripts {
    'modules/core/spawn_c.lua',
    'modules/core/game_state_c.lua',
    'modules/core/helpers_c.lua',
    'modules/notify/notify_c.lua',
    'modules/hud/hud_c.lua',
    'modules/garage/garage_c.lua',
    'modules/dealership/dealership_c.lua',
    'modules/admin/admin_c.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/core/game_state_s.lua',
    'modules/player/player_data_s.lua',
    'modules/garage/garage_s.lua',
    'modules/dealership/dealership_s.lua',
    'modules/admin/admin_s.lua',
}

ui_page 'html/index.html'

files {
    'html/**/*',
    'sql/schema.sql',
}
