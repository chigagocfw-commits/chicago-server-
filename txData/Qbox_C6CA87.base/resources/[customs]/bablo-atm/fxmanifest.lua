
fx_version 'cerulean'
game 'gta5'

author 'bablo'
description 'ATM Resource with Multi-Framework Support'
version '1.0.1'


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'frameworks/esx/server.lua',
    'frameworks/qb/server.lua',
    'frameworks/qbox/server.lua',
    'src/resource/server/functions.lua',
    'src/resource/server/main.lua',
}

shared_scripts {
    '@ox_lib/init.lua',
    'src/resource/shared/locales.lua',
    'src/resource/shared/table.lua',
    'config.lua',
    'src/resource/shared/logger.lua',
    'src/resource/shared/main.lua',
    'src/resource/shared/callbacks.lua',
}

client_scripts {
    'frameworks/esx/client.lua',
    'frameworks/qb/client.lua',
    'frameworks/qbox/client.lua',
    'src/resource/client/core/constants.lua',
    'src/resource/client/core/atm.lua',
    'src/resource/client/core/detection.lua',
    'src/resource/client/core/dui.lua',
    'src/resource/client/core/texture_manager.lua',
    'src/resource/client/core/controls.lua',
    'src/resource/client/core/ui.lua',
    'src/resource/client/core/preset_navigation.lua',
    'src/resource/client/core/transactions.lua',
    'src/resource/client/utils.lua',
    'src/resource/client/modules/dui.lua',
    'src/resource/client/modules/variants.lua',
    'src/resource/client/modules/camera.lua',
    'src/resource/client/modules/animations.lua',
    'src/resource/client/modules/keypad.lua',
    'src/resource/client/const.lua',
    'src/resource/client/helpers.lua',
    'src/resource/client/functions.lua',
    'src/resource/client/main.lua',
}

-- ui_page 'src/resource/software/index.html'

files {
    'src/resource/software/colors.css',
    'src/resource/software/index.html',
    'src/resource/software/assets/**',
    'src/resource/client/assets/fleeca/index.html',
    'src/resource/client/assets/fleeca/texture.png',
}

escrow_ignore {
    'config.lua',
    'frameworks/**',
    'src/resource/software/colors.css'
}

dependency '/assetpacks'
