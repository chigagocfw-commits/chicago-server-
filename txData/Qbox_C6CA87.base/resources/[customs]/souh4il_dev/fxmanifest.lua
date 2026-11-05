fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'souh4il_dev'
description 'SOUH4IL-DEV — Professional In-Game Developer Control Panel (CHICAGO ROLEPLAY)'
author 'SOUH4IL / Antigravity'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config/permissions.lua',
    'config/secrets.lua',
    'server/identifiers.lua',
    'server/security.lua',
    'server/permissions.lua',
    'server/logger.lua',
    'server/outbox.lua',
    'server/test_harness.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

files {
    'config/shared.lua',
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
