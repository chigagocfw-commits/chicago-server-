

----              _  _     _  _     _  _     _  _     _  _     _  _     _  _     _  _
----            _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_
----            _  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|
----           |_      _|_      _|_      _|_      _|_      _|_      _|_      _|_      _|
----             |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|
----
----
----                  ___       _               ____         __ _
----                 / _ \__  _| |_   _ _ __   / ___|  ___  / _| |___      ____ _ _ __ ___
----                | | | \ \/ / | | | | '_ \  \___ \ / _ \| |_| __\ \ /\ / / _` | '__/ _ \
----                | |_| |>  <| | |_| | | | |  ___) | (_) |  _| |_ \ V  V / (_| | | |  __/
----                 \___//_/\_\_|\__, |_| |_| |____/ \___/|_|  \__| \_/\_/ \__,_|_|  \___|
----                              |___/
----
----                                   OXLYN SOFTWARE | MULTI BOSS MENU ESX/QBCORE/QBOX
----
----               Thank you for purchasing our script; we greatly appreciate your preference.
----        If you have any questions or any modifications in mind, please contact us via Discord.
----
----                           Support and More: https://discord.gg/Jskkg4h54r
----
----              _  _     _  _     _  _     _  _     _  _     _  _     _  _     _  _
----            _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_ _| || |_
----            _  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|_  ..  _|
----           |_      _|_      _|_      _|_      _|_      _|_      _|_      _|_      _|
----             |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|   |_||_|
----

-- =============================================================================
--  ██████╗ ██████╗ ███╗   ██╗███████╗██╗ ██████╗
-- ██╔════╝██╔═══██╗████╗  ██║██╔════╝██║██╔════╝
-- ██║     ██║   ██║██╔██╗ ██║█████╗  ██║██║  ███╗
-- ██║     ██║   ██║██║╚██╗██║██╔══╝  ██║██║   ██║
-- ╚██████╗╚██████╔╝██║ ╚████║██║     ██║╚██████╔╝
--  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝ ╚═════╝
-- =============================================================================
--
--  CONFIGURATION FILE — shared/config.lua
--  Edit this file to configure Oxlyn Multi Boss Menu for your server.
--
--  ┌─────────────────────────────────────────────────────────────┐
--  │  OPEN-SOURCE FILES YOU CAN EDIT FREELY                      │
--  │  ─────────────────────────────────────────────────────────  │
--  │  config.lua      ← YOU ARE HERE (main config)               │
--  └─────────────────────────────────────────────────────────────┘
--
-- =============================================================================
Config = {}

-- ==========================================
-- FRAMEWORK
-- ==========================================
-- 'auto'   → autodetect (ESX → QBCore → QBox, in that order)
-- 'esx'    → force ESX Legacy (es_extended)
-- 'qbcore' → force QBCore (qb-core)
-- 'qbox'   → force QBox (qbx_core)
--
-- The resource uses an adapter (server/framework.lua + client/framework.lua)
-- that maps automatically to the correct API. To add support for another
-- framework, implement the API in framework.lua.
--
-- For SOCIETY MONEY:
--   - ESX:    uses esx_addonaccount (society_<job>) with fallback to addon_account_data
--   - QBCore: uses qb-banking → Renewed-Banking → qb-management (in the order they are started)
--
-- Using a DIFFERENT banking resource (tgg-banking, or any other)?
-- See Config.SocietyBanking below - you can point the Finance tab at any
-- banking resource from this file, no other edits needed.
Config.Framework = 'auto'

-- OPTIONAL — override the resource NAME used for the framework. Only set
-- this if you have renamed your framework resource (e.g. you forked
-- qb-core into 'myserver-core', or qbx_core into 'qbx-core').
-- Leave nil/'' to use the default name:
--   esx    → 'es_extended'
--   qbcore → 'qb-core'
--   qbox   → 'qbx_core'
-- Example: Config.FrameworkResource = 'myserver-core'
Config.FrameworkResource = nil

-- ⚠️  IMPORTANT — QBCore / QBox limitation
-- ------------------------------------------------------------------
-- On QBCore and QBox the job grades (ranks) live in a static Lua file
-- (`qb-core/shared/jobs.lua` or `qbx_core/shared/jobs.lua`), NOT in a
-- database table like ESX does (`job_grades`). As a result the
-- following 4 actions are DISABLED on QBCore/QBox:
--
--   • Add new rank          (addRank)
--   • Edit rank label/name  (updateRankLabel)
--   • Edit rank salary      (setGradeSalary)
--   • Delete rank           (deleteRank)
--
-- These callbacks return error='no_runtime_edit' and the UI shows an
-- error notification. To change ranks on QBCore/QBox, edit the shared
-- file and restart the core resource.
--
-- Everything ELSE works on every framework: hire / fire / change a
-- player's grade, timesheet, society money, deposit, withdraw, pay
-- bonus, company settings (per-rank PC access), etc.
-- ------------------------------------------------------------------

-- ==========================================
-- SOCIETY BANKING  (company / society account)
-- ==========================================
-- The Boss Menu's Finance tab (balance, deposit, withdraw, salaries,
-- bonuses) and the public exports (AddCompanyFunds / RemoveCompanyFunds /
-- GetCompanyFunds) all read and write ONE account: the company's society
-- account. This block decides WHICH banking resource owns that account.
--
-- 'auto' (default) keeps the built-in behaviour:
--   - ESX    → esx_addonaccount (`society_<job>`), written straight to
--              addon_account_data + esx_addonaccount:refreshAccounts
--   - QBCore → qb-banking → Renewed-Banking → qb-management → the legacy
--              `management_funds` table (first one started wins)
--
-- Set `provider` to anything else to FORCE a specific backend, including
-- your own banking resource, without touching any Lua outside this file.
--
--   provider = 'auto'              → autodetect (default)
--   provider = 'tgg-banking'       → built-in profile for tgg-banking
--   provider = 'qb-banking'        → force qb-banking
--   provider = 'Renewed-Banking'   → force Renewed-Banking
--   provider = 'qb-management'     → force qb-management
--   provider = 'esx_addonaccount'  → force the ESX addon_account_data path
--   provider = 'custom'            → use Config.SocietyBanking.custom below
--
-- ⚠️  If a forced provider can't be reached (resource stopped, export
-- missing) the adapter prints a warning and falls back to 'auto' rather
-- than leaving the Finance tab dead.
Config.SocietyBanking = {
    provider = 'auto',

    -- Account NAME sent to the banking resource. Most QBCore banking
    -- resources (qb-banking, Renewed-Banking, tgg-banking) use the bare
    -- job name ('police'); ESX uses 'society_police'.
    --   nil / ''   → the provider's own default (recommended)
    --   'society_' → force the ESX-style prefix
    --   '<job>'    → any string containing {job} is used as a template,
    --                e.g. 'job_{job}' → 'job_police'
    accountName = nil,

    -- ------------------------------------------------------------------
    -- CUSTOM BANKING RESOURCE  (provider = 'custom')
    -- ------------------------------------------------------------------
    -- Wire ANY banking resource by naming its server-side exports. The
    -- adapter calls them as:
    --
    --   exports[resource][get](account)                 → number
    --   exports[resource][add](account, amount, reason) → any
    --   exports[resource][remove](account, amount, reason)
    --
    -- `get` may return the balance directly OR take a callback — both
    -- shapes are handled. Leave a name empty to disable that operation.
    custom = {
        resource = '',            -- e.g. 'tgg-banking'
        get      = '',            -- e.g. 'GetAccountBalance'
        add      = '',            -- e.g. 'AddMoney'
        remove   = '',            -- e.g. 'RemoveMoney'
        -- Passed as the 3rd argument to add/remove, where the banking
        -- resource expects a transaction reason/label.
        reason   = 'oxlyn-bossmenu',
        -- Set true if your exports take (amount, account) instead of
        -- (account, amount).
        amountFirst = false,
    },
}

-- ==========================================
-- TRANSACTION LEDGER  (Finance tab → Transaction History)
-- ==========================================
-- Every money movement on the company account is stored server-side in
-- the `oxlyn_company_transactions` table (auto-created) and shown to
-- EVERY boss of that company — not just the person who made it:
--   - deposits     (who, amount, paid from cash / bank, note)
--   - withdrawals  (who, amount, note)
--   - bonuses      (who paid, who received, amount, note)
--   - income / expense made by other resources through the
--     AddCompanyFunds / RemoveCompanyFunds exports (resource name + note)
-- Each row also stores the employee's grade and the balance after it.
--
-- There is intentionally NO button to clear it — it is an audit trail for
-- DOJ inspections (suspicious withdrawals, laundering, tax evasion).
-- Read it from other scripts (MDT, tax office) with:
--   exports['oxlyn-bossmenu']:GetCompanyTransactions(job, cb, limit)
Config.Transactions = {
    enabled       = true,
    -- Also record AddCompanyFunds / RemoveCompanyFunds calls from other
    -- resources (billing, invoices, taxes).
    logExports    = true,
    -- How many of the most recent rows the Finance tab loads (50-5000).
    fetchLimit    = 500,
    -- Delete rows older than this many days on resource start.
    -- 0 = keep forever.
    retentionDays = 0,
}

-- ==========================================
-- AUTO-SYNC FRAMEWORK DUTY  (QBCore / QBox only)
-- ==========================================
-- When TRUE, oxlyn-bossmenu listens to the framework's native duty events
-- (QBCore:Server:SetDuty + qbx_core:server:onSetDuty) and automatically
-- opens/closes a timesheet shift whenever PlayerData.job.onduty changes —
-- no need for other resources (lb-phone, duty points, police scripts, etc.)
-- to call StartDuty/EndDuty manually.
--
-- Only jobs declared in Config.Companies are tracked. Other jobs are
-- ignored so the timesheet stays clean.
--
-- The public StartDuty / EndDuty exports KEEP WORKING regardless of this
-- setting — use them when you need explicit control from a custom script.
--
-- Has no effect on ESX (no native duty system on ESX). On ESX, use the
-- StartDuty / EndDuty exports directly from your own duty resource.
Config.AutoSyncFrameworkDuty = true

-- ==========================================
-- MULTI-JOB INTEGRATION (qs-multijob & friends)
-- ==========================================
-- Multi-job resources keep their OWN list of jobs per player, separate
-- from the framework's current job. When a boss fires someone from the
-- boss menu we only change the framework job — the fired job would stay
-- in the player's multi-job list and they could simply re-select it.
--
-- With this block enabled, every fire performed by the boss menu (boss
-- menu "Fire" button AND the admin /removeboss command when it is set to
-- 'unemployed') also removes the job from the multi-job resource, online
-- or offline.
--
-- Works out of the box with Quasar Multi Job (qs-multijob). For any other
-- multi-job resource, just point `resource` at it and rename the exports.
Config.MultiJob = {
    -- true  = always try  |  false = never  |  'auto' = only if the
    -- resource below is actually started on the server.
    enabled  = 'auto',

    -- Resource name that owns the multi-job list.
    resource = 'wasabi_multijob',

    -- Export names called when an employee is fired.
    --   fireOnline (source, jobName)       → player is connected
    --   fireOffline (identifier, jobName)  → player is offline
    -- Set either one to nil/'' to skip that path.
    exports = {
        fireOnline  = 'FirePlayerFromJob',
        fireOffline = 'FirePlayerFromJobOffline',
    },

    -- Print a line in the server console every time the boss menu calls
    -- the multi-job resource. Handy while testing the integration.
    debug = false,
}

-- ==========================================
-- PUBLIC SERVER EVENTS (for your own scripts)
-- ==========================================
-- The boss menu fires these server events so any resource can react to
-- staff changes without touching the boss menu code:
--
--   AddEventHandler('oxlyn-bossmenu:employeeFired', function(data)
--       -- data = {
--       --   identifier   = 'char1:abc...' | 'ESX identifier',
--       --   source       = 12 or nil (nil when the player is offline),
--       --   job          = 'police',
--       --   grade        = 3,        -- grade the player had when fired
--       --   companyName  = 'Police Department',
--       --   offline      = false,
--       --   by           = 'admin' | 'boss',
--       --   bySource     = 4 or nil, -- who performed the action
--       -- }
--   end)
--
--   AddEventHandler('oxlyn-bossmenu:employeeHired', function(data) end)
--   AddEventHandler('oxlyn-bossmenu:employeeGradeChanged', function(data) end)
--
-- These are plain server events — no config needed to enable them.

-- Debug: prints detailed framework detection logs to client F8 console and
-- server console. Useful when /bossmenu won't open — enable TEMPORARILY.
Config.Debug = false

-- Script language ('pt' or 'en')
Config.Locale = 'en'

-- Command to open the boss menu (set to nil to disable)
Config.Command = 'bossmenu'

-- Default key to open (FiveM key map). Set to nil to disable.
-- Key list: https://docs.fivem.net/docs/game-references/controls/
Config.OpenKey = nil  -- example: 'F6'

-- Restrict opening to specific groups/jobs (empty = anyone can open).
-- By default, access is controlled by Config.Companies below. This list is
-- only a fallback when no company matches the player's job.
Config.AllowedGrades = {}  -- empty = only Config.Companies controls access

-- ==========================================
-- ADMIN — remove boss / manage jobs
-- ==========================================
-- Lets your ADMIN TEAM remove the boss rank (or fire) a player straight
-- from a command — works whether the target is ONLINE or OFFLINE, by
-- server id OR by name. This is the "take the boss off someone" tool that
-- does NOT need database access, so you can keep your DB closed to admins.
Config.Admin = {
    -- Command an admin runs, e.g. /removeboss 12  or  /removeboss John Doe
    -- Set to nil to disable the command entirely.
    removeBossCommand = 'removeboss',

    -- When a boss is removed, which grade do they drop to?
    --   'demote'     → set to the highest NON-boss grade of that company
    --                  (keeps them employed, just no longer a boss)
    --   'unemployed' → fire them from the company (job set to 'unemployed')
    onRemove = 'demote',

    -- WHO is allowed to run the command. A player passes if they match ANY
    -- of the enabled checks below.

    -- 1) ACE permission. Grant with, in server.cfg:
    --      add_ace group.admin oxlyn_bossmenu.admin allow
    --    (txAdmin admins already have "group.admin" by default.)
    ace = 'oxlyn_bossmenu.admin',

    -- 2) Framework admin groups (ESX group / QBCore permission). Anyone in
    --    one of these is allowed. Leave empty to ignore.
    groups = { 'admin', 'superadmin', 'god' },

    -- 3) Explicit identifier allow-list (license:, steam:, discord:, fivem:).
    --    Use full identifiers exactly as they appear in the server.
    identifiers = {
        -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
    },

    -- Also let anyone with the native command permission run it (txAdmin
    -- "command" ACE). Safe to leave true.
    allowConsole = true,
}

-- ==========================================
-- CURRENCY / MONEY SYMBOL
-- ==========================================
-- Controls how EVERY money value is displayed across the whole boss menu
-- (society balance, salaries, bonuses, deposits/withdrawals, KPIs, the
-- server-side "bonus received" notification, input labels, etc.).
--
--   symbol    → the currency sign shown next to amounts.
--               Examples: '$'  '€'  '£'  '¥'  'R$'  'zł'  'kr'  '₽'  '₺'
--   position  → 'before' → $1,000        |   'after' → 1,000$
--   space     → true  puts a space between the symbol and the number
--               ($ 1,000 / 1,000 $)  ·  false = glued ($1,000 / 1,000$)
--   thousands → the thousands separator used to group digits:
--               ','  → 1,000,000   (English)
--               '.'  → 1.000.000   (EU / PT / DE)
--               ' '  → 1 000 000   (FR / space)
--               ''   → 1000000     (no grouping)
--
-- Just change `symbol` to switch the currency — nothing else is required.
Config.Currency = {
    symbol    = '$',        -- € $ £ ¥ R$ zł kr ₽ ₺ ...
    position  = 'before',   -- 'before' or 'after'
    space     = false,      -- add a space between symbol and number
    thousands = ',',        -- ',' | '.' | ' ' | ''
}

-- ==========================================
-- Config.Companies — registered companies on the server
-- ==========================================
-- Each company defines:
--   id           - unique identifier (string)
--   name         - full display name
--   shortName    - short tag (3-5 letters, used for badges/icons)
--   job          - job name in the framework (matches DB job_grades.job_name)
--   bossGrades   - list of grades (numbers) considered Boss
--                  → only these have full access (hire, fire, money, ranks)
--                  → other grades only open the PC if authorized in the
--                    Settings tab (Computer Access) and see a limited view
--   color        - primary color (CSS gradient or hex) used for UI / badge
--   ranks        - company hierarchy (synced with DB job_grades).
--                  Each rank: { name, grade, salary }. If job_grades is
--                  populated, it overrides this list.
--   defaultBalance / defaultIncome - decorative initial values
--
-- To add a new company:
--   1. Add the job in the DB (ESX job_grades / jobs, or QBCore.Shared.Jobs)
--   2. Add a block here with id, job and bossGrades
--   3. Restart the resource
--   4. (optional) the boss can add/edit ranks inside the app
Config.Companies = {
    -- ===================== POLICE =====================
    {
        id          = 'police',
        name        = 'Los Santos Police Department',
        shortName   = 'LSPD',
        job         = 'police',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#0ea5e9,#1e40af)',
        ranks = {
            { name = 'Cadet',      grade = 0, salary =  600 },
            { name = 'Officer',    grade = 1, salary = 1000 },
            { name = 'Sergeant',   grade = 2, salary = 1500 },
            { name = 'Lieutenant', grade = 3, salary = 2200 },
            { name = 'Chief',      grade = 4, salary = 3500 },
        },
        defaultBalance = 75000,
        defaultIncome  = 18000,
    },

    -- ===================== BCSO =====================
    {
        id          = 'bcso',
        name        = 'Blaine County Sheriff Office',
        shortName   = 'BCSO',
        job         = 'bcso',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#eab308,#854d0e)',
        ranks = {
            { name = 'Cadet',      grade = 0, salary =  600 },
            { name = 'Deputy',     grade = 1, salary = 1000 },
            { name = 'Sergeant',   grade = 2, salary = 1500 },
            { name = 'Lieutenant', grade = 3, salary = 2200 },
            { name = 'Sheriff',    grade = 4, salary = 3500 },
        },
        defaultBalance = 75000,
        defaultIncome  = 18000,
    },

    -- ===================== SASP =====================
    {
        id          = 'sasp',
        name        = 'San Andreas State Police',
        shortName   = 'SASP',
        job         = 'sasp',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#1e293b,#0f172a)',
        ranks = {
            { name = 'Cadet',      grade = 0, salary =  600 },
            { name = 'Trooper',    grade = 1, salary = 1000 },
            { name = 'Sergeant',   grade = 2, salary = 1500 },
            { name = 'Lieutenant', grade = 3, salary = 2200 },
            { name = 'Colonel',    grade = 4, salary = 3500 },
        },
        defaultBalance = 75000,
        defaultIncome  = 18000,
    },

    -- ===================== EMS / AMBULANCE =====================
    {
        id          = 'ambulance',
        name        = 'Los Santos EMS',
        shortName   = 'EMS',
        job         = 'ambulance',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#ef4444,#7f1d1d)',
        ranks = {
            { name = 'Intern',     grade = 0, salary =  800 },
            { name = 'Paramedic',  grade = 1, salary = 1200 },
            { name = 'Doctor',     grade = 2, salary = 1800 },
            { name = 'Surgeon',    grade = 3, salary = 2500 },
            { name = 'Director',   grade = 4, salary = 4000 },
        },
        defaultBalance = 50000,
        defaultIncome  = 14000,
    },

    -- ===================== MECHANIC =====================
    {
        id          = 'mechanic',
        name        = 'Oxlyn Auto Care',
        shortName   = 'AUTO',
        job         = 'mechanic',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#f59e0b,#b45309)',
        ranks = {
            { name = 'Apprentice', grade = 0, salary =  600 },
            { name = 'Mechanic',   grade = 1, salary = 1000 },
            { name = 'Senior',     grade = 2, salary = 1500 },
            { name = 'Advanced',   grade = 3, salary = 2500 },
            { name = 'Manager',    grade = 4, salary = 3500 },
        },
        defaultBalance = 30000,
        defaultIncome  = 12000,
    },

    -- ===================== TAXI =====================
    {
        id          = 'taxi',
        name        = 'Downtown Cab Co.',
        shortName   = 'DCC',
        job         = 'taxi',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#facc15,#a16207)',
        ranks = {
            { name = 'Trainee',      grade = 0, salary =  500 },
            { name = 'Driver',       grade = 1, salary =  900 },
            { name = 'Event Driver', grade = 2, salary = 1400 },
            { name = 'Sales',        grade = 3, salary = 2000 },
            { name = 'Manager',      grade = 4, salary = 2800 },
        },
        defaultBalance = 25000,
        defaultIncome  = 9000,
    },

    -- ===================== CAR DEALER =====================
    {
        id          = 'cardealer',
        name        = 'Premium Deluxe Motorsport',
        shortName   = 'PDM',
        job         = 'cardealer',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#3b82f6,#1d4ed8)',
        ranks = {
            { name = 'Recruit',        grade = 0, salary =  600 },
            { name = 'Showroom Sales', grade = 1, salary = 1000 },
            { name = 'Business Sales', grade = 2, salary = 1500 },
            { name = 'Finance',        grade = 3, salary = 2200 },
            { name = 'Manager',        grade = 4, salary = 3500 },
        },
        defaultBalance = 50000,
        defaultIncome  = 15000,
    },

    -- ===================== REAL ESTATE =====================
    {
        id          = 'realestate',
        name        = 'LS Real Estate',
        shortName   = 'RE',
        job         = 'realestate',
        bossGrades  = { 4 },
        color       = 'linear-gradient(135deg,#a855f7,#6d28d9)',
        ranks = {
            { name = 'Recruit',        grade = 0, salary =  600 },
            { name = 'House Sales',    grade = 1, salary = 1100 },
            { name = 'Business Sales', grade = 2, salary = 1700 },
            { name = 'Broker',         grade = 3, salary = 2400 },
            { name = 'Manager',        grade = 4, salary = 4000 },
        },
        defaultBalance = 40000,
        defaultIncome  = 12000,
    },
}
Config.Computer = {
    enabled        = true,    -- Enable computer mode
    -- If true, disables the /bossmenu command (only opens via PC).
    -- Set to false to keep BOTH methods available.
    disableCommand = false,

    -- Interaction system:
    --   'native'    → proximity loop + native Liquid Glass UI (no deps)
    --   'ox_target' → integrates with ox_target (BoxZone, crosshair focus)
    --   'qb-target' → integrates with qb-target (BoxZone)
    -- 'native' is the default and does NOT need any extra resource. The
    -- others only work if the corresponding resource is started.
    targetSystem = 'native',

    -- Hint text shown below the PC name (only in 'native' mode).
    -- Can be free text OR a locale key (e.g. 'app_interact_hint').
    promptHint = 'app_interact_hint',

    locations = {
        -- ===== LSPD — Mission Row PD =====
        {
            -- Free text OR a locale key (recommended for multi-language)
            label   = 'app_computer_label_lspd',
            coords  = vector3(447.9749, -973.3751, 30.6896),
            heading = 153.7074,

            -- Distances (meters)
            interactDist = 1.6,   -- distance at which the "[E] ..." prompt shows
            renderDist   = 10.0,  -- distance at which the floating icon shows

            -- Z offset of the 3D icon (meters above coords)
            iconHeight   = 1.05,

            -- Native interact key (38 = E)
            key = 38,

            -- Spawn a prop. The Mission Row PD MLO already has a desk
            -- computer, so the default is false. Enable it if you want
            -- to place your own visual PC.
            spawnProp = false,
            propModel = 'prop_pc_01b',
        },

        -- To add ANOTHER company, copy the block above and change coords.
        -- {
        --     label   = 'Boss Computer — Auto Care',
        --     coords  = vector3(...),
        --     heading = 0.0,
        --     interactDist = 1.6, renderDist = 10.0, iconHeight = 1.05, key = 38,
        --     spawnProp = false, propModel = 'prop_pc_01b',
        -- },
    },
}

-- ==========================================
-- SHOWCASE MODE (for video recording / demos only)
-- ==========================================
-- When enabled=true, the resource bypasses the database/framework and uses
-- the employees, candidates, ranks and balance defined here. Everything is
-- interactive (hire, fire, promote, salaries, deposits, withdrawals,
-- bonuses, ranks) — changes persist ONLY for the current session (reset
-- when the resource is restarted).
--
-- Your character is automatically added to the team as Chief.
-- To return to real mode (ESX/QBCore with DB), just set enabled=false.
Config.Showcase = {
    enabled   = false,           -- Enable showcase mode (DISABLE in production)
    companyId = 'police',       -- A company id from Config.Companies (above)
    bossGrade = 4,              -- Your character's rank (must exist in ranks)

    balance   = 152480,         -- Initial company balance ($)

    -- Pre-defined employees (visible in the "Team" tab)
    --   identifier  → unique decorative ID (don't change, must be stable)
    --   name        → display name
    --   grade       → rank (must match a grade in ranks)
    --   online      → whether the employee shows as on duty (green)
    employees = {
        { identifier = 'showcase:emp_01', name = 'James Wilson',      grade = 3, online = true  },
        { identifier = 'showcase:emp_02', name = 'Sarah Mitchell',    grade = 3, online = false },
        { identifier = 'showcase:emp_03', name = 'Michael Brown',     grade = 2, online = true  },
        { identifier = 'showcase:emp_04', name = 'Emily Davis',       grade = 2, online = true  },
        { identifier = 'showcase:emp_05', name = 'David Thompson',    grade = 1, online = false },
        { identifier = 'showcase:emp_06', name = 'Jessica Anderson',  grade = 1, online = true  },
        { identifier = 'showcase:emp_07', name = 'Robert Garcia',     grade = 1, online = false },
        { identifier = 'showcase:emp_08', name = 'Olivia Martinez',   grade = 1, online = true  },
        { identifier = 'showcase:emp_09', name = 'Daniel Walker',     grade = 0, online = true  },
        { identifier = 'showcase:emp_10', name = 'Sophia Lewis',      grade = 0, online = false },
    },

    -- Hire candidates (shown when clicking "Hire")
    --   source      → fictitious ID (must be unique)
    --   identifier  → unique decorative ID
    --   job/jobLabel → candidate's current job (decorative, translated by locale if possible)
    candidates = {
        { source = 901, identifier = 'showcase:cand_01', name = 'Liam Carter',      job = 'unemployed', jobLabel = 'Unemployed' },
        { source = 902, identifier = 'showcase:cand_02', name = 'Ava Roberts',      job = 'unemployed', jobLabel = 'Unemployed' },
        { source = 903, identifier = 'showcase:cand_03', name = 'Noah Hughes',      job = 'unemployed', jobLabel = 'Unemployed' },
        { source = 904, identifier = 'showcase:cand_04', name = 'Mia Phillips',     job = 'mechanic',   jobLabel = 'Mechanic' },
        { source = 905, identifier = 'showcase:cand_05', name = 'Ethan Foster',     job = 'taxi',       jobLabel = 'Taxi Driver' },
        { source = 906, identifier = 'showcase:cand_06', name = 'Isabella Clark',   job = 'unemployed', jobLabel = 'Unemployed' },
        { source = 907, identifier = 'showcase:cand_07', name = 'Lucas Reed',       job = 'unemployed', jobLabel = 'Unemployed' },
    },
}

-- ==========================================
-- System (simulated macOS)
-- ==========================================

Config.System = {
    -- Operating system name shown in the top bar
    name    = 'OxlynOS',
    -- Version shown in the "About" modal
    version = '15.2 Sequoia',
}

-- ==========================================
-- Account / Login
-- ==========================================
-- Nothing to configure here anymore. Each COMPANY has its own computer
-- login system, managed entirely in-game on the lock screen:
--   - No default account: the first person opening the company computer
--     creates their own user via the "Add" tile.
--   - Accounts are shared per company (stored server-side in the
--     oxlyn_company_accounts table) — everyone with access to that
--     company's computer sees the same accounts.
--   - The BOSS can tick "Master Account" when creating: that account
--     becomes the ONLY one on that computer and blocks new creations.
--   - Only the person who CREATED an account can delete it (hover → ×).

-- ==========================================
-- Wallpaper / Cursor
-- ==========================================

-- Default wallpaper. Can be:
--   • path to an image in html/img/  (e.g. 'img/wallpaper.jpg')
--   • CSS string:  'linear-gradient(...)'  /  'radial-gradient(...)'  /  '#hex'
-- If the image file doesn't exist, a gradient fallback is shown.
Config.Wallpaper = 'img/wallpaper.jpg'
Config.CursorStyle = 'macos'             -- 'macos' or 'default'

-- ==========================================
-- Available applications
-- ==========================================
-- Each app has:
--   id            - unique identifier (string)
--   name          - display name
--   enabled       - whether it appears at all in the system
--   installed     - whether it ships pre-installed (false = must be installed via App Store)
--   showInDock    - whether it appears in the Dock
--   showOnDesktop - whether it appears as a desktop icon
-- Install philosophy:
-- By default ONLY 3 essential apps ship pre-installed (App Store, Settings,
-- Calculator). Everything else is optional and must be installed by the user
-- through the App Store. This makes the experience feel "real" — the PC
-- ships clean and each user installs whatever they want.
Config.Apps = {
    -- ===== Essential apps (pre-installed) =====
    {
        id      = 'appstore',
        name    = 'app_name_appstore',
        enabled = true,
        installed = true,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'settings',
        name    = 'app_name_settings',
        enabled = true,
        installed = true,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'calculator',
        name    = 'app_name_calculator',
        enabled = true,
        installed = true,
        showInDock    = true,
        showOnDesktop = false,
    },

    -- ===== Optional apps (must be installed via the App Store) =====
    {
        id      = 'browser',
        name    = 'app_name_browser',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'calendar',
        name    = 'app_name_calendar',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'clock',
        name    = 'app_name_clock',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'companyManagement',
        name    = 'app_name_companyManagement',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'notes',
        name    = 'app_name_notes',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
    {
        id      = 'reminders',
        name    = 'app_name_reminders',
        enabled = true,
        installed = false,
        showInDock    = true,
        showOnDesktop = false,
    },
}

-- ==========================================
-- App Store catalog (descriptions / metadata)
-- ==========================================
Config.Store = {
    apps = {
        {
            id          = 'companyManagement',
            name        = 'app_name_companyManagement',
            developer   = 'Oxlyn Software',
            category    = 'app_category_companyManagement',
            description = 'Manage your company: employees, finances, inventory and settings — all in a single panel.',
            rating      = 4.8,
            ratings     = 1247,
            size        = '32 MB',
            featured    = true,    -- shown in the hero carousel
            tag         = 'editor', -- 'editor' | 'new' | 'trending'
        },
        {
            id          = 'browser',
            name        = 'app_name_browser',
            developer   = 'Oxlyn Software',
            category    = 'app_category_browser',
            description = 'Fast and simple browser for your intranet, with city favorites pre-configured.',
            rating      = 4.6,
            ratings     = 892,
            size        = '124 MB',
            featured    = true,
            tag         = 'trending',
        },
        {
            id          = 'calculator',
            name        = 'app_name_calculator',
            developer   = 'Oxlyn Software',
            category    = 'app_category_calculator',
            description = 'Basic calculations and percentages.',
            rating      = 4.5,
            ratings     = 412,
            size        = '8 MB',
        },
        {
            id          = 'calendar',
            name        = 'app_name_calendar',
            developer   = 'Oxlyn Software',
            category    = 'app_category_calendar',
            description = 'View the current month, navigate dates and mark important appointments.',
            rating      = 4.4,
            ratings     = 356,
            size        = '22 MB',
        },
        {
            id          = 'clock',
            name        = 'app_name_clock',
            developer   = 'Oxlyn Software',
            category    = 'app_category_clock',
            description = 'World clock, stopwatch and timer in one place.',
            rating      = 4.3,
            ratings     = 245,
            size        = '15 MB',
        },
        {
            id          = 'settings',
            name        = 'app_name_settings',
            developer   = 'Oxlyn Software',
            category    = 'app_category_settings',
            description = 'Customize your system, wallpaper and more.',
            rating      = 4.7,
            ratings     = 1024,
        },
        {
            id          = 'notes',
            name        = 'app_name_notes',
            developer   = 'Oxlyn Software',
            category    = 'app_category_notes',
            description = 'Take quick notes, pin your favorites and search through history.',
            rating      = 4.7,
            ratings     = 678,
            size        = '18 MB',
            featured    = true,
            tag         = 'new',
        },
        {
            id          = 'reminders',
            name        = 'app_name_reminders',
            developer   = 'Oxlyn Software',
            category    = 'app_category_reminders',
            description = 'To-do lists with dates, priorities and multiple customizable lists.',
            rating      = 4.8,
            ratings     = 543,
            size        = '14 MB',
            tag         = 'new',
        },
        {
            id          = 'appstore',
            name        = 'app_name_appstore',
            developer   = 'Oxlyn Software',
            category    = 'app_category_appstore',
            description = 'Discover and install new apps.',
            hidden      = true,
        },
    },
}

-- ==========================================
-- Wallpapers available in Settings > Wallpaper
-- ==========================================
-- You can use image paths (e.g. 'img/wallpaper.jpg') or CSS strings
-- (linear-gradient / radial-gradient / hex colors).
Config.Wallpapers = {
    { name = 'Default',   value = 'img/wallpaper.jpg' },
    { name = 'Aurora',    value = 'linear-gradient(135deg, #2a1f5c 0%, #4a1f7c 50%, #1a1240 100%)' },
    { name = 'Twilight',  value = 'linear-gradient(160deg, #ff6b6b 0%, #ff9f6b 40%, #6f4cdc 100%)' },
    { name = 'Ocean',     value = 'linear-gradient(180deg, #0a3d62 0%, #006266 50%, #04293a 100%)' },
    { name = 'Forest',    value = 'linear-gradient(180deg, #134e4a 0%, #1a3a2a 100%)' },
    { name = 'Charcoal',  value = 'linear-gradient(180deg, #2a2a2e 0%, #0a0a0c 100%)' },
    { name = 'Solar',     value = 'linear-gradient(135deg, #f6d365 0%, #fda085 100%)' },
    { name = 'Nebula',    value = 'radial-gradient(ellipse at 30% 30%, #ff7e6b 0%, transparent 45%), radial-gradient(ellipse at 70% 70%, #6f4cdc 0%, transparent 50%), #1a1240' },
}

-- ==========================================
-- Browser (decorative)
-- ==========================================
-- Strings here can be free text OR locale keys (browser_search_engine,
-- browser_search_placeholder, etc.) — the keys are translated via locale.
Config.Browser = {
    -- Search engine name (decorative — does not actually search the web)
    searchEngine = 'browser_search_engine',
    -- Placeholder of the search bar
    placeholder  = 'browser_search_placeholder',
    -- Message shown when the player "searches" something
    fakeMessage  = 'browser_fake_message',
    -- Home page texts
    homepageTitle    = 'browser_homepage_title',
    homepageSubtitle = 'browser_homepage_subtitle',
    -- Suggestions shown on the home page
    suggestions = {
        'Los Santos News',
        'LSC Stock Quote',
        'Bleeter',
        'LifeInvader',
        'Weazel News',
    },
}

-- ==========================================
-- Calculator
-- ==========================================
Config.Calculator = {
    -- Decimal separator shown in the display ('.' or ',')
    decimalSeparator = '.',
    -- Maximum decimal places shown
    maxDecimals      = 8,
}

-- ==========================================
-- Sounds (paths relative to html/) — optional
-- ==========================================
Config.Sounds = {
    enabled = false,  -- enable to use sounds
    boot    = '',
    click   = '',
    error   = '',
}

-- ==========================================
-- Notifications
-- ==========================================
Config.NotifyType     = 'ox_lib'   -- 'esx', 'ox_lib', or 'oxlyn-notify' (if available)
Config.NotifyDuration = 4000

