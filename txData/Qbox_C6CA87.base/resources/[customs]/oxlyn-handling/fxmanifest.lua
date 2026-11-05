

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                        ║
    ║      ██████  ██   ██ ██      ██    ██ ███    ██                        ║
    ║     ██    ██  ██ ██  ██       ██  ██  ████   ██                        ║
    ║     ██    ██   ███   ██        ████   ██ ██  ██   H A N D L I N G      ║
    ║     ██    ██  ██ ██  ██         ██    ██  ██ ██   S T U D I O          ║
    ║      ██████  ██   ██ ███████    ██    ██   ████                        ║
    ║                                                                        ║
    ║   OXLYN Software®  •  Live Handling Editor  •  ESX / QBCore / Qbox     ║
    ╚══════════════════════════════════════════════════════════════════════╝

    Real-time in-vehicle handling editor with an Apple-style liquid-glass UI.
    /handlingeditor inside any vehicle (default, addon, anything) opens the
    studio pre-loaded with that vehicle's CURRENT handling. Every slider is
    applied live. Saving persists the tune per MODEL server-side — every
    spawn of that model, for every player, forever, gets the tune applied
    automatically. Stock snapshots make resets perfect. Built-in + custom
    admin presets, Drive Mode with live telemetry, EN/PT/FR/ES/PL.
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Oxlyn Software'
description 'OXLYN Handling — real-time vehicle handling studio: 46 live-tunable CHandlingData fields in 7 categories, per-model persistence (server KVP + GlobalState auto-apply on every spawn for every player), stock snapshots for perfect resets, built-in + admin-created presets, vehicle classes, copy/paste tunes between vehicles, Drive Mode with live telemetry, liquid-glass Apple-style NUI. Server-authoritative permissions (ACE + txAdmin/add_principal bridge aces + framework groups + jobs + identifiers + override hook) with the /handlingaccess diagnostic. Multi-framework (ESX / QBCore / Qbox auto-detect), EN/PT/FR/ES/PL.'
version '1.3.1'

-- NOTE: framework resources (es_extended / qb-core / qbx_core) are intentionally
-- NOT declared as dependencies. The bridge auto-detects whatever is running so the
-- resource loads cleanly on any (or no) framework.

shared_scripts {
    'config.lua',
    -- Locales (English is the fallback, keep it first)
    'locales/en.lua',
    'locales/pt.lua',
    'locales/fr.lua',
    'locales/es.lua',
    'locales/pl.lua',
    'shared/locale.lua',
    'shared/fields.lua',            -- the 46-field CHandlingData schema (categories, ranges, conversions)
    'shared/bridges/framework.lua', -- ESX / QBCore / Qbox auto-detect, permission gate, self-contained callbacks
}

client_scripts {
    'client/handlingio.lua', -- the ONLY code touching handling natives: verified writes (read-back + auto-correct + blacklist)
    'client/main.lua',       -- command, editor session, live apply, NUI contract, telemetry, drive mode
    'client/sync.lua',       -- GlobalState watcher: auto-applies saved tunes to every matching vehicle
}

server_scripts {
    'server/main.lua',  -- THE AUTHORITY: permission gate on every action, KVP persistence,
                        -- GlobalState publishing, preset/class CRUD, /handlingaccess report
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
}

-- ══ Escrow ═══════════════════════════════════════════════════════════
-- Core logic (client/*.lua, server/*.lua) is protected. Everything a server
-- owner needs to customise stays fully editable:
--   • config.lua            — commands, permissions, presets, behaviour
--   • locales/*.lua         — all 5 languages, add your own freely
--   • shared/*.lua          — field schema (ranges/categories) + i18n helper
--   • shared/bridges/*.lua  — framework auto-detect AND the whole permission
--                             gate, so a custom core / custom staff system can
--                             be supported without touching protected code
--                             (Config.Admin.check is the supported hook)
--   • html/**               — the NUI (CEF cannot run encrypted files)
escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'shared/*.lua',
    'shared/bridges/*.lua',
    'html/**',
    'README.md',
}

dependency '/assetpacks'

