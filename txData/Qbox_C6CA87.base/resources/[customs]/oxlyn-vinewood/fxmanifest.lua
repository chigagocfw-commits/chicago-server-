

fx_version 'cerulean'
game 'gta5'
this_is_a_map 'yes'

name        'oxlyn-vinewood'
description 'OXLYN Advanced Vinewood Editor - replace the Vinewood sign with physical 3D letters, flat text and images from an in-game freecam editor (ESX / QBCore / Qbox / standalone)'
author      'OXLYN'
version     '2.6.1'

-- Locales load between the config and the schema so every shared message is translatable.
-- The glob picks up every shipped language; the loader is idempotent, so matching it again is harmless.
shared_scripts {
    'config.lua',
    'locales/loader.lua',
    'locales/*.lua',
    'shared/glyphs.lua',
    'shared/schema.lua',
}

client_scripts {
    'client/math.lua',
    'shared/layout.lua',
    'shared/effects.lua',
    'client/images.lua',
    'client/color.lua',
    'client/fonts.lua',
    'client/solid.lua',
    'client/render.lua',
    'client/main.lua',
    'client/editor.lua',
}

server_scripts {
    'server/permissions.lua',   -- ESX / QBCore / Qbox / ACE: who may open the editor
    'server/assets.lua',
    'server/main.lua',
}

-- The interface ships as a minified build in web/dist. Its source and the build
-- script are included in the OPEN SOURCE edition.
ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/app.js',
    'web/dist/style.css',
    'web/dist/atlas.html',
    'web/dist/atlas.js',
    'web/dist/fonts/*.woff2',
    'web/dist/fonts/*.txt',
    'web/dist/images/*',
    'stream/oxvw_glyphs.ytyp',
}

-- The letter models in stream/ are streamed automatically; this archetype file tells the
-- game they exist. A FULL SERVER RESTART is required the first time (and after updating
-- stream/), and players must close and reopen FiveM once.
data_file 'DLC_ITYP_REQUEST' 'stream/oxvw_glyphs.ytyp'

-- ══════════════════════════════-- ═══════════════════════════════════════════════════════════════════════════
--  ESCROW EDITION
--
--  These files stay OPEN so you can configure and translate everything:
--  config.lua, the languages in locales/, your data (published scene and
--  uploaded images), the font licences and the documentation.
--
--  The Lua in client/, server/ and shared/, the interface build in web/dist and
--  the models and map files in stream/ are protected. The Open Source edition
--  contains the full source.
-- ═══════════════════════════════════════════════════════════════════════════
escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'data/*',
    'data/**/*',
    'licenses/*',
    'README.md',
    'CHANGELOG.md',
}

dependency '/assetpacks'

