fx_version 'cerulean'
game 'gta5'
lua54 'yes'
author '9labs'
description 'Scoot Bunker'
version '3.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/bs.lua',
    'locales/de.lua',
    'shared/locale.lua',
    'shared/color.lua',
    'shared/assets.lua',
    'shared/curves.lua',
}

client_scripts {
    'client/glow.lua',
    'client/logo.lua',
    'client/bunker.lua',
    'client/audio.lua',
    'client/cycle.lua',
    'client/blips.lua',
    'client/ui.lua',
    'client/placement.lua',
    'client/diag.lua',
    'client/main.lua',
}

server_scripts {
    'server/bridge.lua',
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'logo/*.png',
    'web/index.html',
    'web/logo.html',
    'web/glow.html',
    'web/*.js',
    'web/*.css',
    'web/fonts/*',
    'web/sounds/*.ogg',
    'stream/scoot_bunker.ytyp',
    'stream/scoot_bunker_col.ytyp',
}

data_file 'DLC_ITYP_REQUEST' 'stream/scoot_bunker.ytyp'
data_file 'DLC_ITYP_REQUEST' 'stream/scoot_bunker_col.ytyp'

escrow_ignore {
    'config.lua',
    'logo/*',
    'locales/*.lua',
    'server/bridge.lua',
    'locations.json',
    'rentals.json',
}

dependencies { 'ox_lib', '/onesync' }
