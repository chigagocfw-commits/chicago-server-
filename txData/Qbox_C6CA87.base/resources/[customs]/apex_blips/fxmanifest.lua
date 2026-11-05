--[[
    Apex Scriptz — apex_blips "Blip Studio"

    A creator for CUSTOM MAP BLIPS. Three icon sources:

      · any of the 900+ native GTA sprites (searchable picker with real
        previews),
      · ANY IMAGE — upload a PNG/JPG/WEBP and it becomes a real blip on the
        minimap and the pause map, rendered through a runtime texture that
        recomposes the blip sheet (no restart per image, no YTD editing),
      · a generated badge — emoji, Font Awesome icon or short text, with or
        without a coloured disc.

    Every blip can carry a MAP ZONE (radius circle or rotated rectangle) that
    optionally fires enter/exit events other resources can listen to, can be
    visible to everyone, to specific jobs only, or to its creator only, and
    the whole thing is scriptable through exports (see README.md).

    Fullscreen studio with a live Los Santos map, JSON store in data/,
    standalone — ESX Legacy, QBCore, QBox and vanilla all work. No database.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author      'Apex Scriptz'
description 'Custom blip studio — image blips via runtime textures, native sprite catalogue, map zones with events, job visibility, JSON store, full export API'
version     '1.1.0'

-- locales/*.lua is a glob so a new language only needs to be dropped into the
-- folder. locale.lua only reads the tables at call time, so load order between
-- locale.lua and the language files does not matter.
shared_scripts {
    'config.lua',
    'locales/*.lua',
}

client_scripts {
    'client/slots.lua',
    'client/main.lua',
    'client/studio.lua',
}

server_scripts {
    'server/main.lua',
}

-- The studio window. Image blips do NOT go through this page — each image
-- cell is composed by a dedicated DUI surface (html/dui.html) whose pixels
-- are bound to a runtime texture.
ui_page 'html/index.html'

-- stream/minimap.gfx + stream/minimap.ytd pin the blip sheet layout the
-- image engine was built against AND add the newest GTA Online blips.
-- Streamed .gfx/.ytd only register after a FULL server restart — a bare
-- `restart apex_blips` is not enough the first time.
files {
    'html/index.html',
    'html/dui.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/js/blipdata.js',
    'html/js/fadata.js',
    'html/blips/**/*',
    'html/img/*.png',
    'html/fonts/*.woff2',
}

dependencies {
    '/server:5104',
}

--------------------------------------------------------------------------------
-- ESCROW build: the config, every locale file, the README and the JSON store
-- stay fully editable after Keymaster protection. Only the Lua game logic is
-- protected. Locales are listed ONE BY ONE on purpose — directory globs have
-- silently protected files before.
--------------------------------------------------------------------------------
escrow_ignore {
    'config.lua',
    'README.md',
    'locales/locale.lua',
    'locales/en.lua',
    'locales/pt.lua',
    'data/blips.json',
}

provide 'apex_blips'

dependency '/assetpacks'