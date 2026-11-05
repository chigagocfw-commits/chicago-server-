-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
fx_version "cerulean"
use_experimental_fxv2_oal "yes"
nui_callback_strict_mode "true"
lua54 "yes"
game "gta5"

name 'wasabi_multichar'
description 'Wasabi Multi-Character System'
author 'Wasabi Scripts'
version '2.0.3'

ui_page 'ui/build/index.html'

files {
    'ui/build/index.html',
    'ui/build/**/*',
    'locales/*.json',
}

shared_scripts {
    '@ox_lib/init.lua',
    'locales/init.lua',
    'escrow/module_system.lua',
    'config/shared/*.lua',
    '**/shared/*.lua'
}

client_scripts {
    'config/client/*.lua',
    "bridge/**/client.lua",
    "**/client/modules/**/*.lua",
    "**/client/main.lua"
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "config/server/*.lua",
    "bridge/**/server.lua",
    "escrow/common/server/*.lua",
    "**/server/modules/**/*.lua",
    "**/server/main.lua"
}

escrow_ignore {
    "bridge/**/**/*.lua",
    "bridge/**/*.lua",
    "config/**/*.lua"
}

provides { 'esx_multicharacter' }

dependencies { 'ox_lib' }

dependency '/assetpacks'