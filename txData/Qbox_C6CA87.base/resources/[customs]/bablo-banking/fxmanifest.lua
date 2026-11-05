games {
    "gta5"
}

version "1.1.3"

fx_version "cerulean"

nui_callback_strict_mode "true"

use_experimental_fxv2_oal "yes"

lua54 "yes"

ui_page "src/web/dist/index.html"

files {
    "src/web/dist/index.html",
    "src/web/dist/**/*",
    "src/web/dist/fonts/*.otf",
    "src/web/dist/fonts/*.ttf",
    "colors.css"
}

shared_scripts {
    "@ox_lib/init.lua",
    "config.lua",
    "src/resource/shared/society_compat.lua",
    "src/resource/shared/modules/callbacks.lua",
    "src/resource/shared/**/*.lua",
    "src/resource/utils/*.lua",
    "locales/*.lua"
}

client_scripts {
    "src/resource/client/**/*.lua",
    'src/target/*.lua',
    'src/interactions/*.lua',
    "frameworks/qbox/client.lua",
    'frameworks/custom/client.lua',
    "frameworks/esx/client.lua",
    "frameworks/qbcore/client.lua",
    'src/inventories/*.lua',
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    'src/resource/server/**/*.lua',
    'frameworks/qbox/server.lua',
    'frameworks/custom/server.lua',
    'frameworks/esx/server.lua',
    'frameworks/qbcore/server.lua',
    'src/inventories/*.lua',
    'webhooks.lua'
}

dependencies {
    "ox_lib"
}

escrow_ignore {
    "config.lua",
    "webhooks.lua",
    "controls.json",
    'frameworks/**/*.lua',
    "locales/*.lua",
    "src/resource/shared/funcs.lua",
    "src/resource/shared/society_compat.lua",
    "src/resource/client/modules/*.lua",
    "colors.css",
    'src/inventories/*.lua',
    'src/target/*.lua',
    'src/interactions/*.lua',
    'src/menus/*.lua',
}

dependency '/assetpacks'