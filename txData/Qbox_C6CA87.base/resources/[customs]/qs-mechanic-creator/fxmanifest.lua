fx_version 'cerulean'
game 'gta5'
lua54 'yes'

description 'Quasar Mechanic Creator'
author 'Quasar Store'
version '1.4.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/**',
    'locales/**'
}

client_scripts {
    'client/custom/**',
    'client/modules/**',
    'client/client.lua',
    'client/postfix/carlift_safety.lua',
    'client/postfix/carlift_stream_reload.lua',
    'client/postfix/tuneshop_visual.lua',
    'client/postfix/tuneshop_preview_safe.lua',
    'client/postfix/tuneshop_freelook_input.lua',
    'client/postfix/tuneshop_camera_world_fix.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/custom/**',
    'server/modules/**',
    'server/server.lua'
}

data_file 'DLC_ITYP_REQUEST' 'stream/qs-carlift.ytyp'

ui_page 'html/index.html'

files {
    'html/**',
    'stream/qs-carlift.ytyp',
    'stream/qs-carlift.ydr',
    'stream/qs-carlift-platform.ydr',
    'stream/core.ypt',
    'stream/vehicle_paint_ramps.ytd',
}

escrow_ignore {
    'stream/core.ypt',
    'shared/**',
    'locales/**',
    'client/custom/**',
    'server/custom/**'
}

dependencies {
    '/onesync',
    'ox_lib',
    'oxmysql'
}

-- dependency '/assetpacks' -- optional Quasar carlift stream pack