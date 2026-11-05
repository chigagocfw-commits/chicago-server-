

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Oxlyn Software'
description 'Oxlyn Multi Boss Menu V1 - ESX / QBCore / QBox'
version '1.4.0'

-- The resource is framework-agnostic:
--   - Auto-detects ESX Legacy or QBCore/QBox.
--   - Configurable via Config.Framework ('auto' | 'esx' | 'qbcore') in config.lua.
-- We do NOT declare `dependencies` for any specific framework, so the
-- resource can load on servers that only have ESX (or only QBCore).

shared_scripts {
    -- NOTE: @ox_lib/init.lua is NOT loaded by default because if ox_lib
    -- is not installed the WHOLE resource fails to load (and the framework
    -- adapter never starts). If you want to use ox_lib for notifications,
    -- uncomment the line below AND make sure ox_lib is ensured in your
    -- server.cfg BEFORE oxlyn-bossmenu.
    -- '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/framework.lua',     -- adapter (ESX/QBCore) — loaded first
    'client/main.lua'
}

server_scripts {
    -- Locale (i18n global helper L()) — loaded first so the others can use it.
    'server/locale.lua',
    -- Framework adapter (ESX/QBCore/QBox).
    'server/framework.lua',
    -- Showcase mode (intercepts callbacks when Config.Showcase.enabled).
    'server/showcase.lua',
    -- We don't import the @oxmysql/lib/MySQL.lua wrapper because it's
    -- sometimes not available at load time. We use exports.oxmysql
    -- directly in server/main.lua.
    'server/main.lua',
    -- Auto-syncs the framework's native PlayerData.job.onduty flag with
    -- the timesheet (QBCore/QBox only). Loaded AFTER main.lua so it can
    -- call the StartDuty/EndDuty exports defined there.
    'server/duty_sync.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/style.css',
    'html/js/app.js',
    'html/js/icons.js',
    'html/js/calculator.js',
    'html/js/browser.js',
    'html/js/store.js',
    'html/js/calendar.js',
    'html/js/clock.js',
    'html/js/settings.js',
    'html/js/company.js',
    'html/js/notes.js',
    'html/js/reminders.js',
    'html/img/*.jpg',
    'html/img/*.png',
    'html/img/*.webp',
    'locales/pt.json',
    'locales/en.json'
}

escrow_ignore {
    '**'
}


dependency '/assetpacks'

