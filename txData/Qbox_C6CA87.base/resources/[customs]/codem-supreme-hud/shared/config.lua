Config = {}

-- ═══════════════════════════════════════════════════════════════
-- Framework & System Settings
-- ═══════════════════════════════════════════════════════════════

-- Which framework to use?
-- Optional: 'qb', 'esx', 'qbox', 'vrp'
Config.Framework = 'qbox'

-- Which inventory system is being used?
-- Optional: 'ox', 'qb', 'esx', 'qs', 'codem', 'tgiann', 'none'
Config.Inventory = 'ox'

-- Which voice system is used?？
-- Optional: 'pma-voice', 'saltychat', 'mumble-voip', 'toko-voip'
-- Set to false to disable voice integration.
Config.VoiceSystem = 'mm-voice'

-- Which notification system is used?
-- Options: 'framework' (use the framework's built-in notifications), 'ox', 'custom'
-- 'framework' = QBCore.Functions.Notify / ESX.ShowNotification / QBX Notify / vRP Chat messages
-- 'ox' = ox_lib notification (ox_lib must be installed)
-- 'custom' = define a custom notification function below
Config.Notification = {
    System = 'ox',

    -- Custom notification function (only used when System = 'custom')
    -- @param message string - notification text
    -- @param type string - 'success', 'error', 'primary', 'warning'
    Custom = function(message, type)
        -- Example: exports['mythic_notify']:DoHudText(type, message)
    end,
}

-- vRP survival system (hunger & thirst) - only used when Config.Framework = 'vrp'
-- If vRP already has a survival module, the HUD will use it automatically
-- Otherwise, the HUD will use its built-in survival system
Config.VRPSurvival = {
    Enabled = true,             -- Enable built-in vRP hunger/thirst (if vRP has no survival module)
    FoodPerMinute = 1,          -- Hunger decrease per minute (0-100)
    WaterPerMinute = 2,         -- Thirst decrease per minute (0-100)
    OverflowDamage = 5,         -- Damage per tick when hunger/thirst reaches 0
    DefaultFood = 75,           -- Starting hunger value (0-100)
    DefaultWater = 100,         -- Starting thirst value (0-100)
}

-- Automatic HUD setup: show the HUD style selection screen when a new player joins
-- Set to false to trigger manually: TriggerClientEvent('codem-hud:client:TriggerSetup', source)
-- Disable this if it conflicts with your character creation screen
Config.AutoHudSetup = true

-- ═══════════════════════════════════════════════════════════════
-- Language settings (localization)
-- ═══════════════════════════════════════════════════════════════
-- Language files are located in shared/locales/
-- Options: 'en' (English), 'tr' (Turkish), 'es' (Spanish), 'fr' (French)
Config.Locale = {
    -- Language to use
    Language = 'en',
}

-- ═══════════════════════════════════════════════════════════════
-- Custom player ID function
-- ═══════════════════════════════════════════════════════════════
-- Override this function to use a custom player ID system
-- This ID is shown in the HUD settings panel and player information
-- Returns: string or number (custom player ID)
-- Default: use the server ID (GetPlayerServerId)
---@param serverId number player server ID
---@return string|number custom player ID to display
Config.GetCustomPlayerId = nil

-- example
--Config.GetCustomPlayerId = function(serverId)
--    local playerData = GetPlayerData()
--    local citizenid = playerData and playerData.citizenid
--    return citizenid or serverId
--end

-- ═══════════════════════════════════════════════════════════════
-- Vehicle model categories
-- ═══════════════════════════════════════════════════════════════
-- Define which vehicle models belong to special categories

Config.VehicleModels = {
    -- Police vehicles (for siren detection)
    Police = {
        'police', 'police2', 'police3', 'police4', 'policeb',
        'sheriff', 'sheriff2', 'pranger', 'fbi', 'fbi2',
    },

    -- Medical/emergency vehicles (for siren detection)
    EMS = {
        'ambulance', 'firetruk', 'lguard',
    },

    -- Electric vehicles (no exhaust flames when using nitrous)
    Electric = {
        'tezeract', 'cyclone', 'neon', 'raiden', 'voltic', 'voltic2',
        'imorgon', 'iwagen', 'virtue', 'omnisegt',
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Timing intervals (advanced settings - change only if you understand them)
-- ═══════════════════════════════════════════════════════════════
-- All time values are in milliseconds unless otherwise specified

Config.Timings = {
    -- Stress system cooldowns (milliseconds)
    Stress = {
        ShootCooldown = 800,      -- Interval between shooting stress events
        DamageCooldown = 2500,    -- Interval between damage stress events
        CrashCooldown = 6000,     -- Interval between crash stress events
        SpeedCooldown = 5000,     -- Interval between speeding stress events
        NotifyCooldown = 3000,    -- Stress notification interval
    },

    -- Adaptive interval settings (performance optimization)
    -- Format: { minimum, maximum, step, threshold }
    -- min = fastest update interval, max = slowest update interval, step = step increment, threshold = number of changes before adapting
    Intervals = {
        Weapon = { min = 200, max = 800, step = 100, threshold = 5 },
        Damage = { min = 300, max = 1500, step = 200, threshold = 3 },
        Vehicle = { min = 500, max = 2000, step = 200, threshold = 3 },
        Main = { min = 2000, max = 6000, step = 400, threshold = 3 },
        Hud = { min = 500, max = 2000, step = 200, threshold = 3 },
        Sync = { min = 30000, max = 120000, step = 15000, threshold = 2 },
        Location = { min = 3000, max = 15000, step = 2000, threshold = 2 },
        Heading = { min = 60, max = 200, step = 20, threshold = 8 },
        Waypoint = { min = 150, max = 500, step = 50, threshold = 5 },
    },

    -- Server timing settings
    Server = {
        SocietyCacheTime = 10000,  -- Society funds cache time (milliseconds)
        InitWaitTime = 2000,       -- Initialization wait time
    },
}

-- ═══════════════════════════════════════════════════════════════
-- UI effects
-- ═══════════════════════════════════════════════════════════════

Config.UI = {
    -- Enable HUD blur effect (glassmorphism)
    -- Set to false to disable blur completely for better performance
    -- When disabled, blur settings will not appear in the settings menu
    BlurEnabled = true,
}

-- ═══════════════════════════════════════════════════════════════
-- Settings menu
-- ═══════════════════════════════════════════════════════════════

Config.Settings = {
    -- Server name (shown in the settings menu)
    ServerName = 'CHICAGO RP',

    -- Server Discord (shown in the player information panel)
    ServerDiscord = 'CHICAGO ROLEPLAY',

    -- Server logo URL (shown in the player information panel)
    -- Set to nil to use the default placeholder image
    ServerLogo = 'https://imgur.com/a/I9WUhm4',

    -- Money format: thousands separator
    -- '.'  = period        (12.500)
    -- ','  = comma      (12,500)
    -- ' '  = space      (12 500)
    -- '\'' = apostrophe (12'500)
    -- '_'  = underscore (12_500)
    -- ''   = none       (12500)
    MoneySeparator = '.',

    -- Currency symbol
    -- '$' = US dollars, '€' = euros, '£' = British pounds, 'R$' = Brazilian reais, '₺' = Turkish lira
    MoneyPrefix = '$',

    -- Currency symbol position
    -- 'before' = $12.500 (prefix)
    -- 'after'  = 12.500$ (suffix)
    MoneyPosition = 'after',

    -- Money row text colors (hexadecimal)
    MoneyColors = {
        cash    = '#5ecb6e',
        bank    = '#74b1e0',
        marked  = '#cb5e5e',
        society = '#e074db',
        coin    = '#e0ce74',
    },

    -- Command to open settings (false to disable)
    Command = 'hudsettings',
    -- Key to open settings (false to disable)
    -- Reference: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    Keybind = 'F7',
    KeybindDescription = 'Open HUD settings',
    -- Event to open settings
    -- Usage: TriggerEvent('codem-hud:client:OpenSettings')
    Event = 'codem-hud:client:OpenSettings',

}

-- ═══════════════════════════════════════════════════════════════

Config.ToggleHud = {
    -- Command to toggle HUD visibility (false to disable)
    Command = 'togglehud',

    -- Key to toggle HUD visibility (false to disable)
    -- Reference: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    Keybind = false,
    KeybindDescription = 'Toggle HUD visibility',

    -- Events to toggle HUD visibility
    -- Usage: TriggerEvent('codem-hud:client:ToggleHud')
    -- Usage: TriggerEvent('codem-hud:client:ShowHud')
    -- Usage: TriggerEvent('codem-hud:client:HideHud')
    --
    -- Exports:
    -- exports['codem-supreme-hud']:ToggleHud()
    -- exports['codem-supreme-hud']:ShowHud()
    -- exports['codem-supreme-hud']:HideHud()
    -- exports['codem-supreme-hud']:IsHudHidden()
}

-- ═══════════════════════════════════════════════════════════════
-- Minimap
-- ═══════════════════════════════════════════════════════════════

Config.Minimap = {
    -- Show the minimap when the player is on foot?
    -- true  = Always show while on foot
    -- false = Hide while on foot (or require an item listed below)
    ShowOnFoot = true,

    -- Require an item to show the minimap while on foot?
    -- Only applies when ShowOnFoot = false
    -- true  = Show the minimap if the player has any item listed below
    -- false = Never show the minimap while on foot
    RequireItem = true,

    -- Items required to enable the minimap
    -- The player must have at least one of these
    RequiredItems = { 'phone' },

    -- ─────────────────────────────────────────────────────────────
    -- Big map toggle
    -- ─────────────────────────────────────────────────────────────
    -- Key to expand the minimap and hide HUD elements
    BigMap = {
        -- Enable the big map toggle feature
        Enabled = true,

        -- Key to toggle the big map
        -- Reference: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
        Key = 'Z',
        KeyDescription = 'Toggle Big Map',
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Stress system
-- ═══════════════════════════════════════════════════════════════
-- Realistic stress mechanics that affect player status
-- Supports QBCore, QBox, and ESX (requires metadata.stress)

Config.Stress = {
    -- Enable the stress system
    Enabled = false,

    -- Show notifications when stress changes
    Notifications = false,

    -- Maximum stress value (0-100)
    MaxStress = 100,

    -- Whitelisted jobs (shooting does not increase stress for these jobs)
    -- Suitable for police, military, security, and other jobs that often use weapons
    WhitelistedJobs = {
        'police',
        'sheriff',
        'bcso',
        'sasp',
        'fib',
        'doj',
        'military',
        'security',
        'ambulance',    -- Medical personnel may need to defend themselves
        'hunter',       -- Hunter job
        -- Add custom jobs here
    },

    -- Stress increase amounts (false to disable a feature)
    Increase = {
        -- Combat
        Shooting = 1.5,           -- Per shot fired | false disable
        GettingShot = 5,          -- Hit by a bullet | false disable
        Melee = 1,                -- Per melee attack | false disable
        GettingHit = 3,           -- Hit by a melee attack | false disable

        -- Driving
        Speeding = 0.1,           -- Exceeding the speed threshold | false disable
        SpeedThreshold = 120,     -- Speeding threshold (km/h) - only used when Speeding is enabled
        VehicleCrash = 8,         -- Vehicle collision | false disable

        -- Other
        Falling = 5,              -- Fall from a height | false disable
        Ragdoll = 2,              -- Ragdoll state | false disable
        LowHealth = 0.2,          -- Health < 25% | false disable
        Drowning = 1,             -- Drowning/underwater oxygen loss | false disable
    },

    -- Stress reduction amounts (false to disable a feature)
    Decrease = {
        -- Passive recovery (various relaxing activities)
        Sitting = 2,           -- Steady driving (20-100 km/h) | false disable
        Swimming = 2,           -- Swimming (exercise) | false disable
        Walking = 1,           -- Walking | false disable
        Running = 2,           -- Jogging/running (aerobic exercise) | false disable
        Passenger = 2,         -- Vehicle passenger | false disable

        -- Items (set item names; false to disable)
        -- Value = amount of stress reduced after using the item
        Items = {
            -- Smoking/vaping
            ['joint'] = 20,        -- Joint (strong effect)
            ['weed_joint'] = 20,   -- Weed joint
            ['cigarette'] = 10,    -- Cigarette
            ['cigar'] = 12,        -- Cigar
            ['vape'] = 8,          -- Vape
            ['phone'] = 100,          -- Using a phone
            ['WEAPON_PISTOL'] = 100,         -- Beer

            -- Alcohol
            ['beer'] = 12,         -- Beer
            ['whiskey'] = 15,      -- Whiskey
            ['vodka'] = 15,        -- Vodka
            ['wine'] = 10,         -- Red wine
            ['champagne'] = 12,    -- Champagne
            ['tequila'] = 15,      -- Tequila

            -- Drinks
            ['coffee'] = 8,        -- Coffee
            ['tea'] = 10,          -- Tea (calming)
            ['water'] = 5,         -- Water
            ['cola'] = 5,          -- Cola/soda
            ['energydrink'] = 6,   -- Energy drink

            -- Food
            ['sandwich'] = 8,      -- Sandwich
            ['burger'] = 8,        -- Burger
            ['pizza'] = 8,         -- Pizza
            ['donut'] = 6,         -- Donut
            ['chocolate'] = 10,    -- Chocolate (mood boost)
            ['candy'] = 5,         -- Candy

            -- Medical
            ['painkiller'] = 15,   -- Painkiller
            ['bandage'] = 5,       -- Bandage (minor relief)
        },
    },

    -- Stress effects (triggered at specific levels)
    Effects = {
        -- Screen shake at high stress
        ScreenShake = {
            Enabled = true,
            Threshold = 90,        -- Stress level at which shaking starts
            Intensity = 0.1,       -- Shake intensity (0.0-1.0)
        },
        -- Blur/drunk effect at very high stress
        ScreenBlur = {
            Enabled = true,
            Threshold = 95,        -- Stress level at which blur starts
        },
        -- Random blackout at maximum stress
        Blackout = {
            Enabled = false,       -- Disabled by default (strong effect)
            Threshold = 100,       -- Stress level that triggers blackout
            Duration = 3000,       -- Blackout duration (milliseconds)
        },
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Hunger sound effect
-- ═══════════════════════════════════════════════════════════════
-- Play a stomach growl when hunger is low
-- Nearby players can hear it too

Config.HungerSound = {
    Enabled = true,
    NearbyEnabled = true,      -- true: Nearby players can hear it | false: Only you can hear it
    Threshold = 25,            -- Hunger level at which stomach growling starts (0-100)
    Interval = 30000,          -- Growl interval (milliseconds) - default: 30seconds
    NearbyRadius = 10.0,       -- Radius within which nearby players can hear it (meters)
    SoundFile = 'stomach_growl.mp3', -- Place the sound in html/sounds/ and change the filename
}

-- ═══════════════════════════════════════════════════════════════
-- Vehicle panel
-- ═══════════════════════════════════════════════════════════════

Config.VehiclePanel = {
    -- Which vehicle locking script should be used?
    -- Set to false to use the default GTA lock/unlock system
    --
    -- Options:
    --   'qb-vehiclekeys'      - QBCore default keys
    --   'wasabi_carlock'      - Wasabi Scripts
    --   'Renewed-Vehiclekeys' - Renewed Scripts
    --   'mk_vehiclekeys'      - ManKind Scripts
    --   'vehicles_keys'       - Jaksam Vehicles Keys
    --   'qs-vehiclekeys'      - Quasar Store Vehicle Keys
    --
    -- Or add a custom integration in shared/bridges.lua
    LockScript = false,

}

-- ═══════════════════════════════════════════════════════════════
-- Manual transmission
-- ═══════════════════════════════════════════════════════════════
-- Players can switch between automatic/manual transmission in HUD settings
-- In manual mode, players shift gears using keys

Config.ManualTransmission = {
    -- Enable manual transmission
    Enabled = true,

    -- Upshift key
    -- Reference: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    ShiftUpKey = 'E',
    ShiftUpDescription = 'Upshift (manual transmission)',

    -- Downshift key
    ShiftDownKey = 'Q',
    ShiftDownDescription = 'Downshift (manual transmission)',
}

-- ═══════════════════════════════════════════════════════════════
-- Fuel system
-- ═══════════════════════════════════════════════════════════════

Config.FuelSystem = {
    -- Which fuel script should be used?
    --
    -- Options:
    --   'native'      - Native GTA fuel (GetVehicleFuelLevel)
    --   'LegacyFuel'  - LegacyFuel (Uses native fuel + decor)
    --   'qb-fuel'     - QBCore fuel
    --   'ps-fuel'     - Project Sloth fuel (entity state)
    --   'ox_fuel'     - Overextended fuel (entity state)
    --   'cdn-fuel'    - CDN fuel (entity state)
    --   'lc_fuel'     - Linden fuel (entity state)
    --   'okokGasStation' - OKOK Gas Station
    --
    -- Set to 'auto' for automatic detection (recommended)
    Script = 'auto',
}

-- ═══════════════════════════════════════════════════════════════
-- Society funds (job account)
-- ═══════════════════════════════════════════════════════════════

Config.SocietyMoney = {
    -- Show society funds in the HUD?
    Enabled = true,

    -- Only the boss can view society funds?
    -- true  = Visible only to the boss (default)
    -- false = Visible to all employees
    BossOnly = true,

    -- Which society/job funds script should be used?
    -- 'auto'   = Automatic detection (recommended - compatible with most scripts)
    -- 'custom' = Custom script (edit modules/society/custom.lua)
    --
    -- Automatic detection supports:
    --   qb-banking, renewed-banking, g-boss-menu,
    --   esx_society, esx_addonaccount, okokBanking,
    --   codem-bossmenuv2, mBossmenu
    Script = 'auto',
}

-- ═══════════════════════════════════════════════════════════════
-- Job display (player information panel)
-- ═══════════════════════════════════════════════════════════════

Config.JobDisplay = {
    -- Show abbreviations such as "LSPD | Officer" instead of the full job name
    UseAbbreviations = true,

    -- Job name → abbreviation mapping
    Abbreviations = {
        -- Law enforcement
        ['police'] = 'LSPD',
        ['lspd'] = 'LSPD',
        ['bcso'] = 'BCSO',
        ['sheriff'] = 'BCSO',
        ['sasp'] = 'SASP',
        ['highway'] = 'SAHP',
        ['fib'] = 'FIB',
        ['doj'] = 'DOJ',

        -- Emergency services
        ['ambulance'] = 'EMS',
        ['ems'] = 'EMS',
        ['doctor'] = 'EMS',
        ['fire'] = 'LSFD',
        ['firefighter'] = 'LSFD',

        -- Government & services
        ['mechanic'] = 'LSC',
        ['bennys'] = 'BNY',
        ['bus'] = 'BUS',
        ['trucker'] = 'TRK',
        ['tow'] = 'TOW',
        ['garbage'] = 'SAN',
        ['realestate'] = 'RES',
        ['cardealer'] = 'PDM',

        -- Unemployed
        ['unemployed'] = 'Citizen',
        ['civilian'] = 'Citizen',
    },

    -- Note: Jobs not listed above will display their full name
    -- (e.g. "Real Estate Agent | Senior Agent" instead of an abbreviation)
}

-- ═══════════════════════════════════════════════════════════════
-- Coin system (custom tokens/currency)
-- ═══════════════════════════════════════════════════════════════
-- Custom currency system; can be updated through exports or events
-- Used to display VIP tokens, points, credits, etc. (display only; cannot be used as currency)
--
-- Usage examples:
--
-- Set coin value (no animation):
--   exports['codem-supreme-hud']:SetCoin(100)
--   TriggerEvent('codem-hud:client:SetCoin', 100)
--
-- Add coins (with + animation):
--   exports['codem-supreme-hud']:AddCoin(50)
--   TriggerEvent('codem-hud:client:AddCoin', 50)
--
-- Remove coins (with - animation):
--   exports['codem-supreme-hud']:RemoveCoin(25)
--   TriggerEvent('codem-hud:client:RemoveCoin', 25)
--
-- Get the current coin value:
--   local coins = exports['codem-supreme-hudd']:GetCoin()
--
-- Full control (amount, change amount, whether to subtract):
--   exports['codem-supreme-hud']:UpdateCoin(150, 50, false)  -- Set to 150, display +50
--   TriggerEvent('codem-hud:client:UpdateCoin', 150, 50, false)

Config.Coin = {
    -- Enable coin display (shown only when coins > 0)
    Enabled = true,

    -- HUD display label (default: "Coin")
    Label = 'Coin',
}

-- ═══════════════════════════════════════════════════════════════
-- Marked money (black money) - (QBCore or QBox only; ESX uses account funds by default)
-- ═══════════════════════════════════════════════════════════════

Config.MarkedBills = {
    Enabled = false,
    ItemName = 'markedbills',  -- Item name in shared/items.lua

    -- How to calculate total marked money:
    -- true  = Sum item metadata values (QB: item.info.worth, ox: item.metadata.worth)
    --         Each markedbills item stores its value in metadata
    -- false = Use item count (total marked-money quantity)
    ItemInfo = true,

    -- Metadata key used to store value
    -- QB/QBox: 'worth' (item.info.worth)
    -- ox_inventory: 'worth' (item.metadata.worth)
    MetaKey = 'worth',
}

-- ═══════════════════════════════════════════════════════════════
-- HUD focus key (toggle mouse while in a vehicle)
-- ═══════════════════════════════════════════════════════════════
-- Mode: 'controls' = GTA control ID (DisableControlAction), 'keymapping' = FiveM registered key (rebindable in settings)
Config.HudFocusKeyMode = 'keymapping' -- 'controls' or 'keymapping'

-- Option 1: Controls mode - uses GTA control IDs
-- 19 = Alt, 21 = Shift, 36 = Ctrl, 37 = Tab, 171 = Caps Lock
-- 166 = F5, 167 = F6, 168 = F7, 169 = F8
-- Full list: https://docs.fivem.net/docs/game-references/controls/
Config.HudFocusKey = 19

-- Option 2: Keymapping mode - players can rebind in FiveM Settings > Key Bindings
-- Use keyboard key names: LMENU (Alt), LSHIFT, LCONTROL, TAB, CAPITAL (Caps Lock), F5–F8
-- Full list: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
Config.HudFocusKeyMap = 'F10'
Config.HudFocusKeyMapLabel = 'F10'

-- ═══════════════════════════════════════════════════════════════
-- Keybind panel (quick-action hints)
-- ═══════════════════════════════════════════════════════════════
-- Show keybind hints below the player information panel
-- Show an icon and key label for each keybind (e.g. F1, F2)

Config.Keybinds = {
    -- Enable the keybind panel
    Enabled = false,

    -- Keybind items (order determines display order)
    -- id: Unique ID (used to show/hide)
    -- key: Key displayed below the icon
    -- icon: icon filename in web/src/assets/images/keybinds/
    -- visible: Default visibility (can be changed through events/exports)
    Items = {
        { id = 'phone', key = 'F1', icon = 'phone.svg', visible = true, order = 1 },
        { id = 'inventory', key = 'F2', icon = 'inventory.svg', visible = true, order = 2 },
        { id = 'radialmenu', key = 'F3', icon = 'radialmenu.svg', visible = true, order = 3 },
        { id = 'settings', key = 'F6', icon = 'settings.svg', visible = true, order = 4 },
    },

}
-- ═══════════════════════════════════════════════════════════════
-- Voice assistant
-- ═══════════════════════════════════════════════════════════════
Config.VoiceAssistant = {
    Enabled = true,
    Lang = 'en', -- 'tr' or 'en'

    -- Command format: { 'trigger phrase' or {'trigger1','trigger2'}, 'status message', function() execute action end }
    Commands = {
        en = {
            -- Engine
            { {'start engine', 'start the engine', 'engine on', 'turn on engine'}, 'Starting engine...', function()
                TriggerEvent('qb-vehiclekeys:client:ToggleEngine')
            end },
            { {'stop engine', 'engine off', 'turn off engine'}, 'Stopping engine...', function()
                TriggerEvent('qb-vehiclekeys:client:ToggleEngine')
            end },

            -- Lock / unlock
            { {'lock doors', 'lock the doors', 'lock car', 'lock vehicle'}, 'Locking doors...', function()
                if cache.vehicle then
                    local status = GetVehicleDoorLockStatus(cache.vehicle)
                    if status ~= 2 then PlayLockEffect(cache.vehicle) SetVehicleDoorsLocked(cache.vehicle, 2) end
                end
            end },
            { {'unlock doors', 'unlock the doors', 'unlock car', 'unlock vehicle'}, 'Unlocking doors...', function()
                if cache.vehicle then
                    local status = GetVehicleDoorLockStatus(cache.vehicle)
                    if status == 2 or status == 3 then PlayLockEffect(cache.vehicle) SetVehicleDoorsLocked(cache.vehicle, 1) end
                end
            end },

            -- Turn signals
            { {'left signal', 'left indicator', 'signal left', 'left blinker'}, 'Left signal...', function()
                ExecuteCommand('+signalLeft') Wait(50) ExecuteCommand('-signalLeft')
            end },
            { {'right signal', 'right indicator', 'signal right', 'right blinker'}, 'Right signal...', function()
                ExecuteCommand('+signalRight') Wait(50) ExecuteCommand('-signalRight')
            end },
            { {'hazards', 'hazard lights', 'hazards on', 'hazards off', 'emergency lights'}, 'Toggling hazards...', function()
                ExecuteCommand('+signalHazard') Wait(50) ExecuteCommand('-signalHazard')
            end },

            -- Seatbelt
            { {'seatbelt', 'put on seatbelt', 'buckle up', 'belt on', 'belt off'}, 'Toggling seatbelt...', function()
                ExecuteCommand('+toggleSeatbelt') Wait(50) ExecuteCommand('-toggleSeatbelt')
            end },

            -- Headlights
            { {'headlights', 'lights on', 'lights off', 'turn on lights', 'turn off lights'}, 'Toggling headlights...', function()
                if cache.vehicle then
                    local _, lightsOn = GetVehicleLightsState(cache.vehicle)
                    if lightsOn == 1 or lightsOn == true then SetVehicleLights(cache.vehicle, 1) else SetVehicleLights(cache.vehicle, 2) end
                end
            end },

            -- Windows
            { {'windows down', 'open windows', 'roll down windows'}, 'Opening windows...', function()
                if cache.vehicle then for i = 0, 3 do RollDownWindow(cache.vehicle, i) end end
            end },
            { {'windows up', 'close windows', 'roll up windows'}, 'Closing windows...', function()
                if cache.vehicle then for i = 0, 3 do RollUpWindow(cache.vehicle, i) end end
            end },

            -- Speed limiter
            { {'activate limiter', 'set limiter', 'speed limiter', 'limiter on'}, 'Activating limiter...', function()
                if not limiterState.enabled then ToggleLimiter() end
            end },
            { {'deactivate limiter', 'limiter off', 'remove limiter', 'disable limiter'}, 'Deactivating limiter...', function()
                if limiterState.enabled then ToggleLimiter() end
            end },

            -- Cruise control
            { {'activate cruise', 'cruise control', 'cruise on', 'set cruise'}, 'Activating cruise control...', function()
                if not cruiseState.enabled then
                    if cache.vehicle then
                        SetCruiseSpeed(math.floor(GetEntitySpeed(cache.vehicle) * 3.6))
                    end
                    ToggleCruise()
                end
            end },
            { {'deactivate cruise', 'cruise off', 'disable cruise', 'stop cruise'}, 'Deactivating cruise control...', function()
                if cruiseState.enabled then ToggleCruise() end
            end },

            -- Quick navigation markers
            { {'mark gas', 'mark gas station', 'nearest gas', 'find gas'}, 'Marking nearest gas station...', function()
                SetFastNavWaypoint('gas')
            end },
            { {'mark market', 'mark store', 'nearest market', 'find market'}, 'Marking nearest market...', function()
                SetFastNavWaypoint('market')
            end },
            { {'mark mechanic', 'nearest mechanic', 'find mechanic'}, 'Marking nearest mechanic...', function()
                SetFastNavWaypoint('mechanic')
            end },
            { {'mark atm', 'nearest atm', 'find atm'}, 'Marking nearest ATM...', function()
                SetFastNavWaypoint('atm')
            end },
            { {'mark barber', 'nearest barber', 'find barber'}, 'Marking nearest barber...', function()
                SetFastNavWaypoint('barber')
            end },
            { {'mark clothing', 'nearest clothing', 'find clothing', 'mark clothes'}, 'Marking nearest clothing store...', function()
                SetFastNavWaypoint('clothing')
            end },
        },
        tr = {
            -- Engine
            { {'motoru çalıştır', 'motoru aç', 'motor çalıştır', 'motoru calistir'}, 'Motor çalıştırılıyor...', function()
                TriggerEvent('qb-vehiclekeys:client:ToggleEngine')
            end },
            { {'motoru kapat', 'motor kapat', 'motoru söndür', 'motoru kapa'}, 'Motor kapatılıyor...', function()
                TriggerEvent('qb-vehiclekeys:client:ToggleEngine')
            end },

            -- Locking
            { {'kapıları kilitle', 'kilitle', 'arabayı kilitle', 'kapilari kilitle'}, 'Kapılar kilitleniyor...', function()
                if cache.vehicle then
                    local status = GetVehicleDoorLockStatus(cache.vehicle)
                    if status ~= 2 then PlayLockEffect(cache.vehicle) SetVehicleDoorsLocked(cache.vehicle, 2) end
                end
            end },
            { {'kilidi aç', 'kapıları aç', 'kilidi ac', 'kapilari ac'}, 'Kilit açılıyor...', function()
                if cache.vehicle then
                    local status = GetVehicleDoorLockStatus(cache.vehicle)
                    if status == 2 or status == 3 then PlayLockEffect(cache.vehicle) SetVehicleDoorsLocked(cache.vehicle, 1) end
                end
            end },

            -- Turn signals
            { {'sol sinyal', 'sola sinyal', 'sol sinyal aç'}, 'Sol sinyal...', function()
                ExecuteCommand('+signalLeft') Wait(50) ExecuteCommand('-signalLeft')
            end },
            { {'sağ sinyal', 'saga sinyal', 'sağ sinyal aç'}, 'Sağ sinyal...', function()
                ExecuteCommand('+signalRight') Wait(50) ExecuteCommand('-signalRight')
            end },
            { {'dörtlüleri aç', 'dörtlü aç', 'dortluleri ac', 'dörtlüleri kapat', 'dörtlü kapat'}, 'Dörtlüler...', function()
                ExecuteCommand('+signalHazard') Wait(50) ExecuteCommand('-signalHazard')
            end },

            -- Seatbelt
            { {'kemer tak', 'emniyet kemeri', 'kemeri tak', 'kemer çıkar', 'kemeri cikar'}, 'Emniyet kemeri...', function()
                ExecuteCommand('+toggleSeatbelt') Wait(50) ExecuteCommand('-toggleSeatbelt')
            end },

            -- Headlights
            { {'farları aç', 'ışıkları aç', 'farlari ac', 'farları kapat', 'ışıkları kapat'}, 'Farlar...', function()
                if cache.vehicle then
                    local _, lightsOn = GetVehicleLightsState(cache.vehicle)
                    if lightsOn == 1 or lightsOn == true then SetVehicleLights(cache.vehicle, 1) else SetVehicleLights(cache.vehicle, 2) end
                end
            end },

            -- Windows
            { {'camları aç', 'camları indir', 'camlari ac'}, 'Camlar açılıyor...', function()
                if cache.vehicle then for i = 0, 3 do RollDownWindow(cache.vehicle, i) end end
            end },
            { {'camları kapat', 'camları kaldır', 'camlari kapat'}, 'Camlar kapatılıyor...', function()
                if cache.vehicle then for i = 0, 3 do RollUpWindow(cache.vehicle, i) end end
            end },
            { {'ön sol cam', 'sol ön cam'}, 'Ön sol cam açılıyor...', function()
                if cache.vehicle then RollDownWindow(cache.vehicle, 0) end
            end },
            { {'ön sağ cam', 'sağ ön cam'}, 'Ön sağ cam açılıyor...', function()
                if cache.vehicle then RollDownWindow(cache.vehicle, 1) end
            end },
            { {'arka sol cam', 'sol arka cam'}, 'Arka sol cam açılıyor...', function()
                if cache.vehicle then RollDownWindow(cache.vehicle, 2) end
            end },
            { {'arka sağ cam', 'sağ arka cam'}, 'Arka sağ cam açılıyor...', function()
                if cache.vehicle then RollDownWindow(cache.vehicle, 3) end
            end },

            -- Speed limiter
            { {'sınırlayıcı aç', 'limiter aç', 'hız sınırla', 'sinirla'}, 'Hız sınırlayıcı açılıyor...', function()
                if not limiterState.enabled then ToggleLimiter() end
            end },
            { {'sınırlayıcı kapat', 'limiter kapat', 'sınırı kaldır'}, 'Hız sınırlayıcı kapatılıyor...', function()
                if limiterState.enabled then ToggleLimiter() end
            end },

            -- Cruise control
            { {'hız sabitle', 'cruise aç', 'sabitle', 'hizi sabitle'}, 'Hız sabitleniyor...', function()
                if not cruiseState.enabled then
                    if cache.vehicle then
                        SetCruiseSpeed(math.floor(GetEntitySpeed(cache.vehicle) * 3.6))
                    end
                    ToggleCruise()
                end
            end },
            { {'sabitlemeyi kapat', 'cruise kapat', 'sabitleme kapat'}, 'Hız sabitleme kapatılıyor...', function()
                if cruiseState.enabled then ToggleCruise() end
            end },

            -- Quick navigation markers
            { {'benzinlik işaretle', 'en yakın benzinlik', 'benzinlige git'}, 'En yakın benzinlik işaretleniyor...', function()
                SetFastNavWaypoint('gas')
            end },
            { {'market işaretle', 'en yakın market', 'markete git'}, 'En yakın market işaretleniyor...', function()
                SetFastNavWaypoint('market')
            end },
            { {'tamirci işaretle', 'en yakın tamirci', 'tamirciye git'}, 'En yakın tamirci işaretleniyor...', function()
                SetFastNavWaypoint('mechanic')
            end },
            { {'atm işaretle', 'en yakın atm'}, 'En yakın ATM işaretleniyor...', function()
                SetFastNavWaypoint('atm')
            end },
            { {'berber işaretle', 'en yakın berber'}, 'En yakın berber işaretleniyor...', function()
                SetFastNavWaypoint('barber')
            end },
            { {'giyim işaretle', 'en yakın giyim', 'kıyafetçi'}, 'En yakın giyim mağazası işaretleniyor...', function()
                SetFastNavWaypoint('clothing')
            end },
        }
    },
}


-- ═══════════════════════════════════════════════════════════════
-- Vehicle modifications (performance modes)
-- ═══════════════════════════════════════════════════════════════
-- Change the speedometer style based on the selected modification:
--   Comfort → default speedometer
--   Sport → Yolante speedometer
--   Sport Plus → Ferrante speedometer

Config.VehicleMods = {
    -- Enable vehicle modification system
    Enabled = true,

    -- Key to open the vehicle modification panel (inside a vehicle)
    -- Set to false to disable the keybind
    Keybind = 'F9',
    KeybindDescription = 'Open Vehicle Modification Panel',

    -- Command to open the vehicle modification panel
    -- Set to false to disable the command
    Command = 'vehiclemods',

    -- Require items to install Sport/Sport Plus/Drift modifications?
    RequireItems = true,

    -- Items required for each modification
    -- The player must have all listed items to install
    RequiredItems = {
        ['sport'] = {
            { name = 'performance_chip', amount = 1, remove = true },
        },
        ['drift'] = {
            { name = 'drift_chip', amount = 1, remove = true },
        },
        ['sport-plus'] = {
            { name = 'racing_chip', amount = 1, remove = true },
        },

    },

    -- Installation time (seconds)
    InstallTime = {
        ['sport'] = 5,
        ['drift'] = 5,
        ['sport-plus'] = 8,
    },

    -- Apply vehicle physics changes for Drift/Sport/Sport Plus modes?
    ApplyPhysics = true,

    -- Physics modifiers (multipliers applied to vehicle handling)
    Physics = {
        ['drift'] = {
            -- ══════════════════════════════════════════════════════════════
            -- Arcade drift mode
            -- All values are multipliers applied to the vehicle’s original handling
            -- < 1.0 = decreased, 1.0 = unchanged, > 1.0 = increased
            -- ══════════════════════════════════════════════════════════════

            -- Power & throttle response
            fInitialDriveForce = 1.15,          -- Slightly increased torque +15% (helps initiate a drift)
            fDriveInertia = 1.35,               -- More responsive throttle +35% (precise power control)

            -- Traction (core drift feel)
            fTractionCurveMax = 0.62,           -- Cornering traction -38% (easier sliding through turns)
            fTractionCurveMin = 0.58,           -- Acceleration traction -42% (easier to kick out the rear)
            fTractionCurveLateral = 2.20,       -- Slide angle +120% (smooth sustained drifting)
            fTractionLossMult = 1.90,           -- Easier to slide +90%
            fLowSpeedTractionLossMult = 0.65,   -- Low-speed sliding reduced -35% (still drivable)

            -- Weight distribution
            fTractionBiasFront = 0.92,          -- Rear-wheel-drive bias (multiplied by original value, usually ~0.48–0.52)

            -- Suspension (softer = more weight transfer = better drift feel)
            fSuspensionForce = 0.65,            -- Softer suspension -35%
            fAntiRollBarForce = 0.45,           -- Very low anti-roll bar -55% (more body roll)
            fSuspensionReboundDamp = 0.70,      -- Softer rebound -30%
            fSuspensionCompDamp = 0.75,         -- Softer compression -25%

            -- Steering
            fSteeringLock = 1.55,               -- Greater steering angle +55% (countersteering range)

            -- Handbrake (drift initiation tool)
            fHandBrakeForce = 2.00,             -- Double handbrake force (instant drift initiation)

            -- Drag (slightly increased to prevent runaway speed)
            fInitialDragCoeff = 1.12,           -- Slightly increased drag +12%
        },
        ['sport'] = {
            fInitialDriveMaxFlatVel = 1.15,  -- Top speed +15%
            fDriveInertia = 1.10,             -- Acceleration response +10%
            fTractionCurveMax = 1.05,         -- Traction +5%
            fTractionCurveMin = 1.05,
            fSuspensionForce = 1.10,          -- Suspension stiffness +10%
        },
        ['sport-plus'] = {
            fInitialDriveMaxFlatVel = 1.25,  -- Top speed +25%
            fDriveInertia = 1.20,             -- Acceleration response +20%
            fTractionCurveMax = 1.10,         -- Traction +10%
            fTractionCurveMin = 1.10,
            fSuspensionForce = 1.20,          -- Suspension stiffness +20%
            fBrakeBiasFront = 0.95,           -- Improved braking
        },
    },

    -- Save modifications for each vehicle? (requires a database table)
    -- true  = Modifications are saved permanently (requires the codem_hud_vehicle_mods table)
    -- false = Modifications last only for the current session (reset when the server restarts)
    PersistMods = true,
}

-- ═══════════════════════════════════════════════════════════════
-- Vehicle features (seatbelt, nitrous, turn signals, siren)
-- ═══════════════════════════════════════════════════════════════

Config.VehicleFeatures = {
    -- ─────────────────────────────────────────────────────────────
    -- Seatbelt system
    -- ─────────────────────────────────────────────────────────────
    Seatbelt = {
        Enabled = true,
        Key = 'B',

        -- Warning beep when driving without a seatbelt
        Beep = {
            Enabled = true,
            Speed = 30,             -- km/h - Beeping starts above this speed
            Interval = 2000,        -- ms - Beep interval
        },

        -- Ejection through the windshield during a crash (native GTA physics)
        Ejection = {
            Enabled = true,
            -- 'low'       = ~45 km/h (Easy, triggers very easily)
            -- 'medium'    = ~72 km/h (Balanced, recommended)
            -- 'realistic' = ~60 km/h (Realistic crash speed)
            -- 'high'      = ~126 km/h (GTA default, very difficult to trigger)
            Difficulty = 'medium',
        },
    },

    -- ─────────────────────────────────────────────────────────────
    -- Nitrous system (percentage)
    -- ─────────────────────────────────────────────────────────────
    -- Use a nitrous item to install/refill
    Nitro = {
        Enabled = true,
        Key = 'LSHIFT',             -- Hold to activate

        -- Item (use from inventory to install/refill)
        Item = 'nitrous',

        -- Tank settings
        UseRate = 5,               -- Percentage consumed per second (100/5 = 20 seconds for a full tank)
        Cooldown = 1.5,             -- Cooldown before use after the tank is empty

        -- Boost power
        BoostPower = 1.0,           -- Engine power multiplier

        -- Visual effects
        Effects = {
            ExhaustFlame = true,    -- Exhaust flames
            Backfire = true,        -- Backfire sparks when nitrous is activated
            Purge = true,           -- Hood purge smoke
            PurgeWhileMoving = false, -- Show purge smoke while moving (false = only when stationary)
            Sound = true,           -- Sound when nitrous is activated (native GTA sound)
            SoundType = 'boost',    -- 'boost' (native vehicle boost), 'flare' (flame whoosh), 'turbo' (boost + screen effect)
        },
        FlameScale = 1.0,           -- Flame size (0.5 = small, 1.0 = normal, 2.0 = large)
    },

    -- ─────────────────────────────────────────────────────────────
    -- Turn signals & hazard lights
    -- ─────────────────────────────────────────────────────────────
    Signals = {
        Enabled = true,
        LeftKey = 'LEFT',
        RightKey = 'RIGHT',
        HazardKey = 'DOWN',
    },

    -- ─────────────────────────────────────────────────────────────
    -- Siren detection (police/EMS)
    -- ─────────────────────────────────────────────────────────────
    Siren = {
        Enabled = true,
    },

    -- ─────────────────────────────────────────────────────────────
    -- Drift scoring (drift speedometer overlay)
    -- ─────────────────────────────────────────────────────────────
    -- Arcade settings - easy drifting, fast scoring, forgiving
    DriftCounter = {
        Enabled = true,                 -- Enable drift scoring overlay
        MinAngle = 8,                   -- Minimum angle to start drifting (degrees) - easy arcade mode
        MinSpeed = 15,                  -- Minimum speed threshold (km/h) - drifting at low speeds is possible
        ComboTimeout = 4000,            -- Longer timeout before reset (milliseconds) - forgiving
        UIGracePeriod = 1000,           -- Keep the UI visible longer after drifting (smoother experience)
        ResetOnCollision = true,        -- Reset drift score when the vehicle collides
        ScoreMultiplier = 2.0,          -- Higher multiplier = score faster
        ComboGainTime = 1500,           -- Faster combo gain (continuous drifting in milliseconds)
        MaxCombo = 15,                  -- Higher maximum combo for more excitement
    },

    -- ─────────────────────────────────────────────────────────────
    -- Helicopter hover mode
    -- ─────────────────────────────────────────────────────────────
    HoverMode = {
        Enabled = true,                 -- Enable hover mode
        Key = 'J',                       -- Default key (can be rebound in FiveM)
        ActivationTime = 3000,           -- Time to activate hover mode (ms; 0 = immediate)
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Vehicle music system
-- ═══════════════════════════════════════════════════════════════
-- Synchronized music playback inside vehicles
-- The driver controls the music; all passengers hear the same music
-- Nearby players can also hear within range

Config.VehicleMusic = {
    -- Enable vehicle music system
    Enabled = true,

    -- Maximum distance (meters) to hear music from other vehicles
    Distance = 35.0,

    -- Time update interval (milliseconds) - time sync frequency
    TimeUpdateInterval = 200,

    -- Time drift threshold (seconds) - resync if exceeded
    TimeDriftThreshold = 2.0,

    -- Proximity check interval (milliseconds)
    NearbyCheckInterval = 2000,

    -- Effect of windows on volume (closed windows muffle sound)
    WindowEffect = {
        Enabled = true,
        ClosedWindowMultiplier = 0.35,  -- Volume multiplier when all windows are closed (0.0 - 1.0)
    },

    -- Spatial audio effects for nearby vehicle music
    -- Add realistic audio processing: muffling through car doors, echo/reverb
    SpatialAudio = {
        Enabled = true,

        -- Muffling effect: low-pass filter simulating sound through car doors/walls
        MuffledEffect = true,
        MuffledClosedWindow = 0.75,     -- Muffling with windows closed (0.0 = none, 1.0 = fully muffled)
        MuffledOpenWindow = 0.30,       -- Muffling with windows open (still sounds like it is outside)
        MuffledDistanceScale = 0.50,    -- Muffling increases with distance (0.0 = none, 1.0 = severe)
        MuffledMax = 0.95,              -- Maximum muffling regardless of distance (0.0–1.0)

        -- Reverb effect: echo/reverb at a distance
        ReverbEffect = true,
        ReverbStartDistance = 3.0,      -- Distance at which reverb starts (meters)
        ReverbMax = 0.25,               -- Maximum reverb amount (0.0 = none, 1.0 = maximum echo)

        -- Doppler effect: pitch changes as vehicles approach or move away
        DopplerEffect = true,
        DopplerSpeedOfSound = 80.0,     -- Virtual speed of sound (lower = more noticeable effect)
        DopplerMin = 0.75,              -- Minimum pitch multiplier (approaching quickly)
        DopplerMax = 1.50,              -- Maximum pitch multiplier (moving away quickly)
        DopplerMinDistance = 0.5,       -- Minimum distance for Doppler effect (meters)
    },

    -- How long music continues (seconds) after the driver exits without turning off the engine
    -- If the driver returns within this time, music continues; otherwise, the engine and music stop
    -- Set to 0 to stop music immediately when exiting (old behavior)
    ExitGracePeriod = 60,

    -- Custom audio resolver API URL (optional)
    -- If set, this is tried before the built-in method
    -- Supports self-hosted Cobalt, yt-dlp API, or any compatible endpoint
    -- Format: POST JSON body {"url": "https://youtube.com/watch?v=VIDEO_ID"}
    -- Expected response: {"status": "tunnel"|"redirect"|"stream", "url": "https://direct-audio-url"}
    -- Example: 'http://localhost:9000/' (self-hosted Cobalt)
    AudioResolverUrl = nil,

    -- RapidAPI key for the youtube-mp36 service (optional)
    -- Get a free key: https://rapidapi.com/ytjar/api/youtube-mp36
    -- Free quota: ~500 requests/month. Enables realistic muffled audio effect (low-pass filter)
    RapidApiKey = '',
}

-- ═══════════════════════════════════════════════════════════════
-- Server-side HUD control
-- The server can forcibly disable individual HUD elements
-- If false, players cannot see this element or its settings
-- ═══════════════════════════════════════════════════════════════

Config.InfoBarsEnabled = {
    onlineCount = true,    -- Online player count
    serverDetails = true,  -- Server name + Discord + map icon block
    dataWidget = true,     -- Date/time/day-of-week widget
    playerDetails = true,  -- Player badge (ID + job/gang)
    cashMoney = true,      -- Cash row
    bankMoney = true,      -- Bank row
    markedMoney = true,    -- Marked/black money row
    societyMoney = true,   -- Society/job funds row
    coin = true,           -- Coin row
}

-- ═══════════════════════════════════════════════════════════════
-- Default HUD settings
-- Used when the player has not configured settings
-- ═══════════════════════════════════════════════════════════════

Config.DefaultSettings = {
    general = {
        minimapShape = 'square',  -- 'square' = square or 'circle' = circle
        voiceAssistant = true,  -- Enable voice assistant widget
        streamerMode = false,  -- Hide sensitive information for streamers
        playerMusicAudibility = true,  -- Show music audibility range indicator
        cinematicMode = false,  -- Start with cinematic black bars
        focusOnRolePlay = false,  -- Blur HUD when focused on roleplay
        focusOnRolePlayDelay = 5000,  -- Hide delay in milliseconds (5000, 10000, 15000, 20000, 30000, 60000)
        refreshRate = 60,  -- HUD refresh rate: 30, 45, 60
        postalCode = true,  -- Show postal code widget
        marker3D = true,  -- Show 3D marker on screen
    },
    statusBars = {
        type = 'supreme-percentage',  -- 'supreme', 'supreme-percentage', 'mserie'
        theme = 'dynamic',  -- 'dark', 'light', 'dynamic'
        backgroundBlur = false,  -- Blur status bar background
        background = true,  -- Show status bar background
        attachToMinimap = false,  -- Attach to minimap position
    },
    infoBars = {
        theme = 'dynamic',  -- 'dark', 'light', 'dynamic'
        backgroundBlur = false,  -- Blur HUD element background
        background = true,  -- Show HUD element background
        compassType = 'detailed',  -- 'widget' or 'detailed'
        compassBehaviour = 'mouse',  -- 'mouse' or 'player'
        time = 'local',  -- 'local', 'server', 'game'
        display = {
            hideAll = false,  -- Hide all HUD elements
            onlineCount = true,  -- Online player count
            serverDetails = true,  -- Server name and details
            dataWidget = true,  -- Data usage/ping widget
            playerDetails = true,  -- Player name and ID
            cashMoney = true,  -- Cash
            bankMoney = true,  -- Bank balance
            markedMoney = true,  -- Marked/black money
            societyMoney = true,  -- Society/job account balance
            coin = true,  -- Custom tokens/currency
        },
    },
    hotkeys = {
        theme = 'dynamic',  -- 'dark', 'light', 'dynamic'
        backgroundBlur = false,  -- Blur keybind hint background
        background = true,  -- Show keybind background
        display = true,  -- Display on-screen keybind hints
    },
    speedometer = {
        type = 'default',  -- 'default', 'drift', 'yolante', 'ferrante'
        theme = 'dynamic',  -- 'dark', 'light', 'dynamic'
        backgroundBlur = true,  -- Blur gear and seatbelt indicator backgrounds
        refreshRate = 60,  -- Speedometer refresh rate: 30, 45, 60
        speedUnit = 'kmh',  -- 'kmh' or 'mph'
    },
}

-- ═══════════════════════════════════════════════════════════════
-- FLIR thermal imaging settings
-- ═══════════════════════════════════════════════════════════════

Config.FLIR = {
    -- Helicopter models that can use the FLIR camera system
    Enable = true, -- Set to false to disable the FLIR system completely
    AllowedModels = {
        'polmav', 'buzzard', 'buzzard2', 'hunter', 'akula',
        'annihilator', 'annihilator2', 'savage', 'valkyrie',
        'valkyrie2', 'maverick',
    },

    Sensitivity = 4.0,    -- Mouse sensitivity (higher = faster rotation)
    LerpSpeed   = 0.5,    -- Camera smoothing speed (0.1 = slow, 1.0 = instant)
    ZoomSpeed   = 0.12,   -- Mouse wheel zoom speed
    LockSpeed   = 0.08,   -- Target tracking speed in lock mode
    Sounds      = true,   -- Play sound when switching modes

    -- Zoom range (FOV in degrees; lower = more zoomed in)
    FOV = { Min = 5.0, Max = 90.0, Default = 60.0 },

    -- Vertical view limit (negative = down, positive = up)
    Pitch = { Min = -89.0, Max = 20.0 },

    -- Camera offset relative to the vehicle
    -- x: left/right, y: front/back, z: up/down, pitch: initial angle
    Camera = {
        High = { x = 0.0, y = 0.0, z = -2.0, pitch = -30.0 },  -- When airborne
        Low  = { x = 0.0, y = 2.0, z = 0.5, pitch = -5.0 },    -- When on the ground
        SwitchHeight = 5.0,  -- Height threshold for toggling high/low mode (meters)
    },

    -- Vision mode settings (normal mode is always enabled)
    VisionModes = {
        Thermal  = true,  -- Enable thermal/infrared vision (THRML)
        Negative = true,  -- Enable negative/inverted vision (NGTV)
    },

    -- Spotlight settings
    Spotlight = {
        Distance     = 120.0,  -- Default spotlight distance
        Brightness   = 15.0,   -- Spotlight brightness
        Hardness     = 3.0,    -- Spotlight edge hardness
        Radius       = 12.0,   -- Default spotlight cone radius
        DistanceStep = 10.0,   -- Distance change per keypress
        RadiusStep   = 1.0,    -- Radius change per keypress
        DistanceMin  = 30.0,   -- Minimum spotlight distance
        DistanceMax  = 300.0,  -- Maximum spotlight distance
        RadiusMin    = 3.0,    -- Minimum spotlight radius
        RadiusMax    = 30.0,   -- Maximum spotlight radius
    },

    -- Target information display settings
    TargetInfo = {
        ShowPlayerName    = true,   -- Show player RP character name
        ShowPlayerMugshot = true,   -- Show player portrait
        ShowPlayerId      = true,   -- Show player server ID
        ShowVehicleModel  = true,   -- Show vehicle model name
        ShowVehiclePlate  = true,   -- Show vehicle license plate
        ShowVehicleSpeed  = true,   -- Show vehicle speed
        ShowVehicleHealth = true,   -- Show vehicle engine health
        ShowVehicleHeading = true,  -- Show vehicle heading
        ShowDistance       = true,  -- Show distance to target
        ScanDelay          = 1.5,   -- Number of seconds to show information after scanning (progress bar)
        HideMaskedPlayer   = true,  -- Hide player information (name, portrait, ID) while masked
        SignalJammer = {
            Enabled = true,                      -- Enable signal jammer feature
            Items   = { 'signal_jammer' },       -- Hide information (name, portrait, ID) while the player carries this item
        },
    },

    -- 3D street-name label drawn on the road while using FLIR
    StreetNames = {
        Enable         = true,   -- Show floating street-name labels
        MaxNodes       = 40,     -- Number of road nodes to scan (more = wider coverage, higher cost)
        MaxDistance     = 350.0,  -- Maximum drawing distance in meters
        UpdateInterval = 1000,   -- Road node rescan interval in milliseconds
        FontScale      = 0.45,   -- Base text size
    },

    -- Key bindings (control = FiveM control ID, key = registered key)
    Keys = {
        Access        = { key = 'e',   label = 'E' },       -- Quickly open FLIR (in supported helicopters)
        Exit          = { control = 200, label = 'ESC' },      -- Exit FLIR camera
        VisionNext    = { control = 182, label = 'L' },         -- Next vision mode (THRML/NRM/NGTV)
        VisionPrev    = { key = 'j',     label = 'J' },         -- Previous vision mode
        Camera        = { control = 37,  label = 'TAB' },       -- Switch camera mode (HDEO/FOCUS/LOCK)
        Zoom          = {                label = 'SCROLL' },     -- Zoom (label only)
        ZoomReset     = { control = 45,  label = 'R' },          -- Reset zoom to default
        Lock          = { control = 245, label = 'T' },          -- Lock/unlock target
        ResetView     = { control = 47,  label = 'G' },          -- Reset camera rotation
        Spotlight     = { control = 38,  label = 'E' },          -- Toggle spotlight
        SpotDistUp    = { key = 'UP',    label = 'UP' },         -- Increase spotlight distance
        SpotDistDown  = { key = 'DOWN',  label = 'DOWN' },       -- Decrease spotlight distance
        SpotRadiusUp  = { key = 'RIGHT', label = 'RIGHT' },      -- Increase spotlight radius
        SpotRadiusDown = { key = 'LEFT', label = 'LEFT' },       -- Decrease spotlight radius
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Camera assistance
-- ═══════════════════════════════════════════════════════════════
-- Third-person camera offset feature (General Settings panel > Camera Assistance)
-- The server can globally enable/disable and control features
-- Sliders available to players
Config.CameraAccessibility = {
    -- Master switch. false = feature completely disabled (hide UI + disable Lua)
    Enabled = true,

    -- Individual slider toggles. The server can disable specific axes
    Sliders = {
        Vertical   = true,
        Horizontal = true,
        FOV        = true,
    },
}

-- ═══════════════════════════════════════════════════════════════
-- Advanced settings
-- ═══════════════════════════════════════════════════════════════

-- Enable console debug output
Config.Debug = false

-- Automatically create the SQL table on startup
Config.AutoSql = true