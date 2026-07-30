fx_version 'cerulean'
game 'gta5'

author 'RSL'
description 'RSL Drift — drift gameplay built on rsl_core'
version '0.1.0'

dependencies {
    'oxmysql',
    'ox_lib',
    'rsl_core',
}

client_scripts {
    'modules/init_c.lua',
}

server_scripts {
    'modules/init_s.lua',
}

-- Zone data, scoring, tandem detection, ghosts, tuning, and the drift lobby
-- UI land in later phases. This resource currently only proves it starts
-- cleanly on top of rsl_core's exports.
