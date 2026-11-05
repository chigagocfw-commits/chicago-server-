

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║      ██████  ██   ██ ██      ██    ██ ███    ██                      ║
    ║     ██    ██  ██ ██  ██       ██  ██  ████   ██                      ║
    ║     ██    ██   ███   ██        ████   ██ ██  ██   G A R A G E        ║
    ║     ██    ██  ██ ██  ██         ██    ██  ██ ██   S Y S T E M        ║
    ║      ██████  ██   ██ ███████    ██    ██   ████                      ║
    ║                                                                      ║
    ║   OXLYN Software®  •  Advanced Garage System  •  ESX / QB / Qbox     ║
    ╚══════════════════════════════════════════════════════════════════════╝

      • IN-GAME EDITOR   — /garageeditor: garages and impound lots anywhere,
                           spots and zones from a free camera, access by
                           job / gang / player, attendant peds, blips, theme.
      • REALISTIC PARKING— vehicles come back exactly as they were left:
                           damage, fuel, dirt, mods, colours.
      • PLAYER MENU      — real renders, condition gauges, cinematic preview,
                           Locate / Rescue / Bring here.
      • FLEETS           — job and gang garages with their own vehicles by grade.
      • IMPOUND · PARK   — impound lots and /impound, /park that survives restarts.
      • SALE CONTRACTS   — sell a vehicle to a passenger on an agreement paper.
      • ANY STACK        — ESX / QBCore / Qbox, 11 inventories, 19 key systems,
                           10 fuel scripts, ox_target / qb-target, 14 notify
                           resources — all detected automatically.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name        'oxlyn-garage'
author      'OXLYN Software'
description 'OXLYN Advanced Garage System (Escrow edition) — in-game garage editor, realistic parking, modern player menu, job/gang fleets, impound lots, park mode and vehicle sale contracts. ESX / QBCore / Qbox.'
version     '1.2.1'

-- Framework resources are deliberately NOT declared as dependencies: the
-- bridge auto-detects whatever is running.
dependencies {
    '/onesync',
    'oxmysql',
}

shared_scripts {
    'config/config.lua',
    'locales/en.lua',
    'locales/pt.lua',
    'locales/es.lua',
    'locales/fr.lua',
    'locales/de.lua',
    'locales/pl.lua',
    'locales/lt.lua',
    'shared/locale.lua',
    'shared/utils.lua',
    'shared/bridges/framework.lua',
    'shared/bridges/keys.lua',
}

client_scripts {
    'shared/bridges/fuel.lua',
    'shared/bridges/notify.lua',
    'client/props.lua',
    'client/main.lua',
    'client/garages.lua',
    'client/adminvehicles.lua',
    'client/preview.lua',
    'client/park.lua',
    'client/editor.lua',
    'client/zone.lua',
    'client/contract.lua',
    'client/phone.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/bridges/inventory.lua',
    'server/db.lua',
    'server/settings.lua',
    'server/garages.lua',
    'server/vehicles.lua',
    'server/park.lua',
    'server/contract.lua',
    'server/admin.lua',
    'server/adminvehicles.lua',
    'server/main.lua',
    'server/phone.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
    'web/dist/assets/*.woff2',
    'images/*.png',
    -- 738 vanilla vehicle renders (400x225 WebP, ~15 MB); add-on vehicles fall
    -- back to a coloured silhouette drawn by the interface
    'images/vehicles/*.webp',
    'images/vehicles/index.json',
}

-- ═══ ESCROW EDITION ═════════════════════════════════════════════════════
-- Readable and editable: config/, locales/, install/, sql/, images/, the
-- built interface (web/dist) and the docs. The Lua in client/, server/ and
-- shared/ is protected by the Cfx asset escrow. Everything that is not Lua
-- MUST be listed here too, or the escrow would encrypt it and it would not load.
escrow_ignore {
    'config/*.lua',
    'locales/*.lua',
    'install/*.lua',
    'install/*.md',
    'sql/*.sql',
    'images/*.png',
    'images/vehicles/*.webp',
    'images/vehicles/index.json',
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
    'web/dist/assets/*.woff2',
    'README.md',
    'CHANGELOG.md',
    'EXPORTS.MD',
}

dependency '/assetpacks'

