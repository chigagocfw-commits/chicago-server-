fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'apex_loading'
author 'Apex Scripts'
description 'APEX LOADING - a loading screen your server builds in game, with an AI assistant'
version '1.1.3'

loadscreen 'web/load.html'
loadscreen_manual_shutdown 'yes'

ui_page 'web/index.html'

shared_scripts {
    'shared/config.lua',
    'shared/locales.lua',
}

client_scripts {
    'client/cl_main.lua',
}

server_scripts {
    'server/sv_access.lua',
    'server/sv_uplink.lua',     -- before sv_media / sv_main: they register on it
    'server/sv_ai.lua',
    'server/sv_media.lua',
    'server/sv_yt.lua',
    'server/sv_main.lua',
}

files {
    'web/load.html',
    'web/index.html',
    'web/yt.html',
    'web/css/load.css',
    'web/css/creator.css',
    'web/js/icons.js',
    'web/js/theme.js',
    'web/js/store.js',
    'web/js/mock.js',
    'web/js/progress.js',
    'web/js/yt.js',
    'web/js/music.js',
    'web/js/bg.js',
    'web/js/widgets.js',
    'web/js/runtime.js',
    'web/js/ai.js',
    'web/js/creator.js',
    'web/fonts/geist-latin.woff2',
    'web/fonts/geist-mono-latin.woff2',
    'web/assets/Logo.png',
    'web/media/**',
}

-- ────────────────────────────────────────────────────────────────────────────
-- ESCROW build: config, locales, the server-side files an owner legitimately
-- needs to point at their own AI provider / access rules, the saved design and
-- the CSS themes stay editable. The creator's JavaScript and the client logic
-- are protected.
--
-- Files are listed one by one, never as a directory glob: escrow matches the
-- patterns literally.
escrow_ignore {
    'shared/config.lua',
    'shared/locales.lua',
    'server/sv_access.lua',
    'server/sv_ai.lua',
    'server/sv_media.lua',
    'server/sv_yt.lua',
    'data/design.json',
    'web/css/load.css',
    'web/css/creator.css',
}

dependency '/assetpacks'