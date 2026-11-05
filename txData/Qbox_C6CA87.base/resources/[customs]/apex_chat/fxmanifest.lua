--[[
    Apex Chat — Fully-custom, category-based chat for FiveM.
    ox_inventory/ox_lib aesthetic · live themes · unlimited
    permissioned categories · area channels · screen photo capture.
    Replaces the stock `chat` resource (provide 'chat') while
    keeping the standard chat:* API + legacy okokChat events.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author      'Apex Scriptz'
description 'Apex Chat — custom NUI chat, categories, themes, screen photos & 3D bubbles'
version     '3.0.3'

shared_scripts {
    'shared/config.lua',
    'shared/locales.lua',
    'shared/framework.lua',
    'shared/utils.lua',
    'shared/categories.lua',
}

client_scripts {
    'build/client/main.lua',
    'build/client/modules/settings.lua',
    'build/client/modules/chat_client.lua',
    'build/client/modules/bubbles3d.lua',
    'build/client/modules/shortcuts.lua',
}

server_scripts {
    'build/server/main.lua',
    'build/server/modules/webhook.lua',
    'build/server/modules/categories.lua',
    'build/server/modules/tags.lua',
    'build/server/modules/admin.lua',
    'build/server/modules/social.lua',
    'build/server/modules/messages.lua',
    'build/server/modules/chat.lua',
}

ui_page 'build/html/index.html'

files {
    'build/html/index.html',
    'build/html/css/*.css',
    'build/html/js/*.js',
    -- Fonts + Font Awesome are bundled, NOT pulled from a CDN. A remote
    -- stylesheet in a NUI page is render-blocking and is fetched during the
    -- join, so one slow/blocked CDN lookup stretches every player's load.
    'build/html/fonts/*.woff2',
    'build/html/webfonts/*.woff2',
}

-- ESCROWED BUILD. Only what a server owner needs to edit stays readable:
-- config, locales, the framework bridge and the third-party fonts (their
-- licence notices must stay readable). Everything else is protected.
escrow_ignore {
    'fxmanifest.lua',
    'README.md',
    'shared/config.lua',
    'shared/locales.lua',
    'shared/framework.lua',
    'build/html/css/fonts.css',
    'build/html/css/fontawesome.min.css',
    'build/html/fonts/Inter-400-latin-ext.woff2',
    'build/html/fonts/Inter-400-latin.woff2',
    'build/html/fonts/Inter-500-latin-ext.woff2',
    'build/html/fonts/Inter-500-latin.woff2',
    'build/html/fonts/Inter-600-latin-ext.woff2',
    'build/html/fonts/Inter-600-latin.woff2',
    'build/html/fonts/Inter-700-latin-ext.woff2',
    'build/html/fonts/Inter-700-latin.woff2',
    'build/html/fonts/Inter-800-latin-ext.woff2',
    'build/html/fonts/Inter-800-latin.woff2',
    'build/html/fonts/Inter-900-latin-ext.woff2',
    'build/html/fonts/Inter-900-latin.woff2',
    'build/html/fonts/TitilliumWeb-300-latin-ext.woff2',
    'build/html/fonts/TitilliumWeb-300-latin.woff2',
    'build/html/fonts/TitilliumWeb-400-latin-ext.woff2',
    'build/html/fonts/TitilliumWeb-400-latin.woff2',
    'build/html/fonts/TitilliumWeb-600-latin-ext.woff2',
    'build/html/fonts/TitilliumWeb-600-latin.woff2',
    'build/html/fonts/TitilliumWeb-700-latin-ext.woff2',
    'build/html/fonts/TitilliumWeb-700-latin.woff2',
    'build/html/webfonts/fa-brands-400.woff2',
    'build/html/webfonts/fa-regular-400.woff2',
    'build/html/webfonts/fa-solid-900.woff2',
    'build/html/webfonts/fa-v4compatibility.woff2',
}

-- We render our own UI + input and supersede the default chat,
-- while implementing the full chat:* API for ecosystem compat.
provide 'chat'
provide 'apex_chat'

-- Hard requirement: a recent FXServer. Frameworks (qb-core / qbx_core /
-- es_extended) are detected at runtime via the bridge — no manifest dep, so
-- the resource starts on any of them. `screenshot-basic` is OPTIONAL and only
-- needed for the in-game photo tool (the code degrades gracefully without it).
dependency '/server:5104'

dependency '/assetpacks'