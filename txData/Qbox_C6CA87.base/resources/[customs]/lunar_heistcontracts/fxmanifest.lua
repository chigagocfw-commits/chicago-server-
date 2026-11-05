-- =====================================================
--  Fixed & Cleaned by Reddev Development (Not AK Studios)
--  Support: https://discord.gg/VW4wBRpj8c AK Studios
--  Cleaned By Reddev Using Codex 5.5
-- =====================================================
-- Resource Metadata
fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Lunar Scripts'
description 'Heist Contracts'
version '1.6.0'

-- What to run
escrow_ignore {
    'config/**/*.lua'
}

dependency 'lunar_bridge'

files {
    'locales/*.json',
    'web/build/**/*',
    'install/images/*.png'
}

ui_page 'web/build/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'init.lua',
    'config/config.lua',
    'config/contracts/*.lua'
}

client_scripts {
    '@lunar_bridge/framework/esx/client.lua',
    '@lunar_bridge/framework/qb/client.lua',
    '@mka-lasers/client/client.lua',
    'config/minigames.lua',
    'config/cl_edit.lua',
    'client/ui.lua',
    'client/main.lua',
    'client/common.lua',
    'client/binds.lua',
    'client/doors.lua',
    'client/drill.lua',
    'client/leaderboard.lua',
    'client/loot.lua',
    'client/minigames.lua',
    'client/occupied.lua',
    'client/rpc.lua',
    'client/scenes.lua',
    'client/shop.lua',
    'client/contracts/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    '@lunar_bridge/framework/esx/server.lua',
    '@lunar_bridge/framework/qb/server.lua',
    'config/sv_config.lua',
    'config/sv_edit.lua',
    'server/*.lua',
    'server/contracts/*.lua'
}
dependency '/assetpacks'
