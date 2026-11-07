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
    -- 'server/test_harness.lua', -- DISABLED IN PRODUCTION (EnableStagingTestHarness must remain false)
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
}

files {
    -- NOTE: config/shared.lua intentionally excluded — NUI has no need for server config.
    -- It is loaded via shared_scripts (server+client only).
    'web/index.html',
    'web/css/style.css',
    'web/js/app.js',
    'web/images/vehicles/*.webp',
}

dependencies {
    'ox_lib',
    'oxmysql',
}
