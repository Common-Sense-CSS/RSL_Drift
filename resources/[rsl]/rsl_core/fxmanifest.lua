fx_version 'cerulean'
game 'gta5'

author 'RSL'
description 'RSL Core — custom framework for the RSL Drift server'
version '0.3.0'

dependencies {
    'spawnmanager',
    'oxmysql',
    'ox_lib',
}

shared_scripts {
    'data/rsl_config.lua',
    'data/rsl_character_options.lua',
    'data/rsl_vehicles.lua',
    'data/rsl_garages.lua',
    'data/rsl_dealerships.lua',
    'data/rsl_items.lua',
    'modules/core/game_state_sh.lua',
    'modules/player/progression_sh.lua',
}

client_scripts {
    'modules/core/game_state_c.lua',
    'modules/core/helpers_c.lua',
    'modules/notify/notify_c.lua',
    'modules/hud/hud_c.lua',
    'modules/garage/garage_c.lua',
    'modules/dealership/dealership_c.lua',
    'modules/inventory/inventory_c.lua',
    'modules/admin/admin_c.lua',
    'modules/character/appearance_c.lua',
    'modules/character/appearance_sync_c.lua',
    'modules/character/character_select_c.lua',
    'modules/character/character_creator_c.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'modules/core/game_state_s.lua',
    'modules/player/player_data_s.lua',
    'modules/character/character_s.lua',
    'modules/garage/garage_s.lua',
    'modules/dealership/dealership_s.lua',
    'modules/inventory/inventory_s.lua',
    'modules/admin/admin_s.lua',
}

ui_page 'html/index.html'

files {
    'html/**/*',
    'sql/schema.sql',
}
