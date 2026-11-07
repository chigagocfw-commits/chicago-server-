function NormalizePlate(plate)
    if not plate then return "" end
    plate = tostring(plate)
    plate = plate:gsub("^%s+", ""):gsub("%s+$", "")
    plate = plate:upper()
    return plate
end

function NormalizePlateForComparison(plate)
    if not plate then return "" end
    plate = tostring(plate)
    plate = plate:gsub("%s+", "")
    plate = plate:upper()
    return plate
end

function checkDependencies(resourceTable)
    for _, entry in ipairs(resourceTable) do
        local resourceName, frameworkId = entry[1], entry[2]
        local state = GetResourceState(resourceName)
        if state and state:find('started') ~= nil then
            if Config.Debug then
                print('^2[DEBUG]^0: ' .. resourceName .. ' is started')
            end
            return frameworkId
        end
    end
    return false
end

local frameworks = {
    {'es_extended', 'esx'},
    {'qbx_core', 'qbox'},
    {'qb-core', 'qbcore'},
}

local vehicleShops = {
    {'qs-vehicleshop', 'qs-vehicleshop'},
    {'esx_vehicleshop', 'esx_vehicleshop'},
    {'qb-vehicleshop', 'qb-vehicleshop'},
    {'qbx_vehicleshop', 'qbx_vehicleshop'},
    {'okokVehicleShop', 'okokvehicleshop'},
}

local interacts = {
    {'qs-textui', 'qs-textui'},
    {'ox_target', 'ox_target'},
    {'qb-target', 'qb-target'},
}

local clothingSystem = {
    {'qs-appearance', 'qs-appearance'},
    {'illenium-appearance', 'illenium-appearance'},
    {'fivem-appearance', 'fivem-appearance'},
    {'codem-appearance', 'codem-appearance'},
    {'bl_appearance', 'bl_appearance'},
    {'ox_appearance', 'ox_appearance'},
    {'qb-clothing', 'qb-clothing'},
    {'Renewed-Clothing', 'renewed-clothing'},
    {'rcore_clothing', 'rcore_clothing'},
    {'jg-clothing', 'jg-clothing'},
    {'fd_customization', 'fd_customization'},
    {'esx_clotheshop', 'esx_clotheshop'},
    {'esx_skin', 'esx_skin'},
    {'skinchanger', 'skinchanger'},
}

local billingSystems = {
    {'codem-billingv2', 'codem-billing'},
    {'qs-billing', 'qs-billing'},
    {'esx_billing', 'esx_billing'},
    {'qb-billing', 'qb-billing'},
    {'okokBilling', 'okokBilling'},
    {'Renewed-Banking', 'Renewed-Banking'},
    {'17mov_billing', '17mov_billing'},
    {'wasabi_billing', 'wasabi_billing'},
}

local function getSocietySystems()
    if Config.Framework == 'qbox' then
        return {
            {'Renewed-Banking', 'Renewed-Banking'},
            {'qs-banking', 'qs-banking'},
            {'ps-banking', 'ps-banking'},
            {'okokBanking', 'okokbanking'},
            {'codem-banking', 'codem-banking'},
        }
    elseif Config.Framework == 'esx' then
        return {
            {'esx_society', 'esx_addonaccount'},
            {'esx_addonaccount', 'esx_addonaccount'},
            {'Renewed-Banking', 'Renewed-Banking'},
            {'qs-banking', 'qs-banking'},
            {'ps-banking', 'ps-banking'},
            {'okokBanking', 'okokbanking'},
            {'codem-banking', 'codem-banking'},
        }
    else
        return {
            {'qb-core', 'qb-core'},
            {'qb-management', 'qb-management'},
            {'qb-banking', 'qb-banking'},
            {'Renewed-Banking', 'Renewed-Banking'},
            {'qs-banking', 'qs-banking'},
            {'ps-banking', 'ps-banking'},
            {'okokBanking', 'okokbanking'},
            {'codem-banking', 'codem-banking'},
        }
    end
end

local inventorySystems = {
    {'ox_inventory', 'ox_inventory'},
    {'qb-inventory', 'qb-inventory'},
    {'qs-inventory', 'qs-inventory'},
    {'ps-inventory', 'ps-inventory'},
    {'codem-inventory', 'codem-inventory'},
    {'origin_inventory', 'origin-inventory'},
    {'ak47_inventory', 'ak47_inventory'},
    {'ak47_qb_inventory', 'ak47_qb_inventory'},
    {'jaksam_inventory', 'jaksam_inventory'},
}

local skillChecks = {
    {'ox_lib', 'ox_lib'},
}

local vehicleKeys = {
    {'qs-vehiclekeys', 'qs-vehiclekeys'},
    {'qb-vehiclekeys', 'qb-vehiclekeys'},
    {'qbx_vehiclekeys', 'qbx-vehiclekeys'},
    {'okokVehicleKeys', 'okokvehiclekeys'},
    {'wasabi_carlock', 'wasabi_carlock'},
    {'cd_garage', 'cd_garage'},
    {'vehicles_keys', 'vehicles_keys'},
    {'t1ger_keys', 't1ger_keys'},
    {'Renewed-Vehiclekeys', 'Renewed-Vehiclekeys'},
    {'lunar_keys', 'lunar_keys'},
    {'VehicleKeyChain', 'VehicleKeyChain'},
    {'mri_Qcarkeys', 'mri_Qcarkeys'},
    {'ak47_qb_vehiclekeys', 'ak47_qb_vehiclekeys'},
    {'haso-getkey', 'haso-getkey'},
}

Config = {}

-- Enable debug mode for development (shows additional console logs)
Config.Debug = false

-- Automatically detect and set the framework being used
Config.Framework = checkDependencies(frameworks) or 'standalone'

-- Automatically detect and set the vehicle shop system being used
Config.VehicleDatabase = checkDependencies(vehicleShops) or 'standalone'

-- Automatically detect and set the interaction system (target/textui)
Config.Interact = checkDependencies(interacts) or 'standalone'

-- Automatically detect and set the inventory system being used
Config.Inventory = checkDependencies(inventorySystems) or 'standalone'

-- Automatically detect and set the vehicle keys system being used
Config.VehicleKeys = checkDependencies(vehicleKeys) or 'standalone'

-- Automatically detect and set the clothing system being used
Config.ClothingSystem = checkDependencies(clothingSystem) or 'standalone'

--[[
    ⚠️  IMPORTANT FOR QBOX USERS:
    qbx_management does NOT handle money storage (only employee management).
    If you don't have a banking system installed, set Config.UseSociety = false
    OR install Renewed-Banking or qs-banking.
]]

-- Enable society system integration
Config.UseSociety = true

Config.SocietySystem = checkDependencies(getSocietySystems()) or 'standalone'

-- Society fee percentage for job-restricted mechanics (0.1 = 10%)
Config.SocietyFeePercentage = 0.1

-- Employee commission percentage for completing installations (0.15 = 15% of order total goes to employee)
Config.EmployeeInstallationCommission = 0.15

-- When true, only the exact SocietyFeePercentage goes to society and the rest is removed from the economy (money sink)
-- When false, all remaining money after employee commission goes to society (legacy behavior)
Config.BurnUnallocated = true

-- Automatically detect and set the skillcheck system being used
Config.SkillCheck = checkDependencies(skillChecks) or 'standalone'

Config.Billing = checkDependencies(billingSystems) or 'standalone'

-- When true (legacy/default), the customer is charged immediately when an order is placed
-- from the tuneshop UI. When false, no money is deducted at order placement — the mechanic
-- is expected to invoice the customer from the tablet "Send Invoice" action instead, which
-- dispatches through Config.Billing (SendBillToPlayer).
--
-- Useful for servers where the tuneshop is job-restricted to mechanics: without this toggle
-- the mechanic pays themselves, which is never the intended flow.
Config.ChargeOnOrder = true

-- When true, the tuneshop UI hides every price label/total. The mechanic decides what to
-- charge by sending an invoice from the tablet (Send Invoice) instead. Most useful when
-- combined with Config.ChargeOnOrder = false: the customer never sees the default prices,
-- and the mechanic bills whatever amount they negotiate. Server-side cost calculation is
-- unchanged — Send Invoice still defaults to the order total — adapters that let you
-- override the amount (codem-billingv2 etc.) will respect a custom value.
Config.HidePrices = false

-- Allows bills dispatched via SendBillToPlayer to be paid from the company fund on
-- adapters that support it (codem-billingv2, Renewed-Banking, qs-billing). EMS/Police-style
-- workflow where the employer picks up the tab. Adapters that don't support society
-- payment silently fall back to the player account.
Config.BillingAllowSociety = false

-- Enables an "Invoice customer" export for engine swaps. When true, mechanics can call
-- exports['qs-mechanic-creator']:SendEngineSwapInvoice(customerSource, engineName, mechanicShopId)
-- after completing an engine install to dispatch the engine price through Config.Billing.
-- Set false to keep engine installs free/handled outside this resource.
Config.InvoiceEngineSwaps = true

-- Optional pre-action hook for custom skill / ability / permission systems.
-- Runs server-side *before* any mechanic action is applied and can cancel the action.
--
-- If this function is left as nil (default install), every action proceeds as normal —
-- so leaving the block as-is is fully backward compatible. Define it only if you have
-- a skill system or other gating logic you want to enforce.
--
-- Parameters:
--   source  : the player ID attempting the action
--   action  : string identifying the action. One of:
--               'repair'        full repair (radial)
--               'bodyRepair'    body damage repair (radial)
--               'engineRepair'  engine repair (radial)
--               'wash'          vehicle wash (radial)
--               'fuel'          refuel (radial)
--               'flip'          flip a flipped vehicle back over (radial)
--               'tune'          any tuneshop modification — paint, wheels, neon,
--                               engine, brakes, suspension, armor, turbo, etc.
--               'engineSwap'    engine swap install
--               'nitro'         nitro install
--             Note: armor is part of the tuneshop, so an armor install fires
--             action 'tune' (not a separate string) — inspect data.modifications
--             to gate it specifically (armor is GTA mod slot 16).
--   data    : context table. Keys vary by action:
--               data.plate          : string vehicle plate (when a vehicle is involved)
--               data.vehicleNetId   : number vehicle network ID (nil if unavailable)
--               data.shopId         : number mechanic shop ID (set for 'tune')
--               data.modifications  : table of every modification being applied —
--                                     only set for 'tune'. Inspect it to gate a
--                                     single category (e.g. armor / mod slot 16).
--               data.cost           : number cost in $ (nil if free / not applicable)
--
-- Return values (use the simplest form that fits your needs):
--   return true                              -- allow the action
--   return false                             -- deny + default "no skill" notification
--   return false, "Custom message"           -- deny + notify with your own message
--   return false, { message = "...", type = "error" }
--                                            -- deny + notify with explicit message & type
--   return false, false                      -- deny silently (your own script handles UI)
--
-- Example:
--   Config.CanPerformMechanicAction = function(source, action, data)
--       if action == 'engineSwap' and not playerHasSkill(source, 'engine_swap', 3) then
--           return false, 'You need engine mechanic grade 3.'
--       end
--       return true
--   end
Config.CanPerformMechanicAction = nil

Locales = Locales or {}

--[[
    Choose your preferred language!

    In this section, you can select the main language for your asset. We have a wide
    selection of default languages available, located in the locales/* folder.

    If your language is not listed, don't worry! You can easily create a new one
    by adding a new file in the locales folder and customizing it to your needs.

    🌐 Available languages:
        'de'     -- German
        'en'     -- English
        'es'     -- Spanish
        'fr'     -- French
        'hi'     -- Hindi
        'it'     -- Italian
        'ja'     -- Japanese
        'nl'     -- Dutch
        'pt'     -- Portuguese
        'zh-CN'  -- Chinese (Simplified)
        'zh-TW'  -- Chinese (Traditional)

    After selecting your preferred language, be sure to save your changes and test
    the asset to ensure everything works as expected!
]]

-- Select your preferred language (see available languages in comment block above)
Config.Language = 'en'

Config.TextFont3D = 4  -- Font used for 3D text displays (default is 4)

-- Vehicles with rear-mounted engines (affects carlift animations and engine positioning)
-- These vehicles require special handling when lifting or accessing the engine
Config.BackEngines = {
    [GetHashKey('ninef')] = true,
    [GetHashKey('adder')] = true,
    [GetHashKey('vagner')] = true,
    [GetHashKey('t20')] = true,
    [GetHashKey('infernus')] = true,
    [GetHashKey('zentorno')] = true,
    [GetHashKey('reaper')] = true,
    [GetHashKey('comet2')] = true,
    [GetHashKey('jester')] = true,
    [GetHashKey('jester2')] = true,
    [GetHashKey('cheetah')] = true,
    [GetHashKey('cheetah2')] = true,
    [GetHashKey('prototipo')] = true,
    [GetHashKey('turismor')] = true,
    [GetHashKey('pfister811')] = true,
    [GetHashKey('ardent')] = true,
    [GetHashKey('nero')] = true,
    [GetHashKey('nero2')] = true,
    [GetHashKey('tempesta')] = true,
    [GetHashKey('vacca')] = true,
    [GetHashKey('bullet')] = true,
    [GetHashKey('osiris')] = true,
    [GetHashKey('entityxf')] = true,
    [GetHashKey('turismo2')] = true,
    [GetHashKey('fmj')] = true,
    [GetHashKey('re7b')] = true,
    [GetHashKey('tyrus')] = true,
    [GetHashKey('italigtb')] = true,
    [GetHashKey('penetrator')] = true,
    [GetHashKey('monroe')] = true,
    [GetHashKey('ninef2')] = true,
    [GetHashKey('stingergt')] = true,
    [GetHashKey('surfer')] = true,
    [GetHashKey('surfer2')] = true,
    [GetHashKey('comet3')] = true
}

-- Position of notification text on screen
-- Options: "top-center", "top-right", "top-left", "bottom-center", "bottom-right", "bottom-left"
Config.TextPosition = "top-center"

-- Keybind for opening the radial menu (mechanic quick actions)
Config.RadialKey = "F5"

Config.UseRadial = true

Config.RadialActions = {
    wash_vehicle = true,
    engine_repair = true,
    body_repair = true,
    full_repair = true,
    flip_vehicle = true,
    fuel_vehicle = true,
    tow_vehicle = true,
    manage_flatbed = true,
    billing = true
}

Config.CreatorCommand = "mechanic_creator"

-- Per-vehicle modification blacklist
-- Use vehicle model names (lowercase) to disable specific mods for certain vehicles
-- Mod type IDs: 11=Engine, 12=Brakes, 13=Transmission, 15=Suspension, 16=Armor, 18=Turbo
-- Cosmetic IDs: 0=Spoiler, 1=Front Bumper, 2=Rear Bumper, 3=Side Skirt, 4=Exhaust, 5=Roll Cage, 6=Grille, 7=Hood, 8=Fender, 9=Right Fender, 10=Roof, 14=Horn
-- Example: disable armor and turbo on the sultan, disable spoiler on the adder
Config.VehicleModBlacklist = {
    -- ['sultan'] = {
    --     tuning = { [16] = false, [18] = false },
    --     cosmetic = { [0] = false }
    -- },
    -- ['adder'] = {
    --     tuning = { [16] = false }
    -- },
}

Config.EnabledModifications = {
    tuning = {
        [11] = true, -- Engine
        [12] = true, -- Brakes
        [13] = true, -- Transmission
        [15] = true, -- Suspension
        [16] = true, -- Armor
        [18] = true  -- Turbo
    },
    cosmetic = {
        [0] = true,  -- Spoiler
        [1] = true,  -- Front Bumper
        [2] = true,  -- Rear Bumper
        [3] = true,  -- Side Skirt
        [4] = true,  -- Exhaust
        [5] = true,  -- Frame / Roll Cage
        [6] = true,  -- Grille
        [7] = true,  -- Hood
        [8] = true,  -- Fender
        [9] = true,  -- Right Fender / Horn
        [10] = true, -- Roof / Hydraulics
        [14] = true, -- Horn
        [17] = true, -- Grille
        [19] = true, -- Dashboard
        [20] = true, -- Dial / Speakers
        [21] = true, -- Door Speakers / Seats
        [22] = true, -- Xenon Headlights / Steering Wheel
        [23] = true, -- Front Wheels / Engine Block
        [24] = true, -- Back Wheels / Rail Covers
        [25] = true, -- Plate Holder / Struts
        [26] = true, -- Vanity Plates / Headlight Covers
        [27] = true, -- Trim Design / Hood Catches
        [28] = true, -- Ornaments / Roof Scoops
        [29] = true, -- Dashboard / Mirrors
        [30] = true, -- Dial / Stickers
        [31] = true, -- Door Speaker / Plate Index
        [32] = true, -- Seats / Window Tint
        [33] = true, -- Steering Wheel
        [34] = true, -- Shifter Levers
        [35] = true, -- Plaques
        [36] = true, -- Speakers
        [37] = true, -- Trunk
        [38] = true, -- Hydraulics
        [39] = true, -- Engine Block
        [40] = true, -- Air Filter
        [41] = true, -- Struts
        [42] = true, -- Arch Cover
        [43] = true, -- Aerials
        [44] = true, -- Trim
        [45] = true, -- Tank
        [46] = true, -- Windows
        [47] = true, -- Livery 2
        [48] = true, -- Livery
        [49] = true, -- Lightbox / Lightbar (only present on a few vehicle classes)
        ['windowTint'] = true,        -- Window Tint
        ['plateIndex'] = true,        -- License Plate Style
        ['wheelType'] = true,         -- Wheel Type/Category
        ['xenonColor'] = true,        -- Xenon Light Color
        ['neonLights'] = true,        -- Neon Underglow Lights
        ['neonColor'] = true,         -- Neon Light Color
        ['tyreSmokeColor'] = true,    -- Tire Smoke Color
        ['tyreSmokeEnabled'] = true,  -- Tire Smoke Enabled
        ['pearlescentColor'] = true,  -- Pearlescent Paint
        ['wheelColor'] = true,        -- Wheel Color
        ['interiorColor'] = true,     -- Interior Color
        ['dashboardColor'] = true,    -- Dashboard Color
        ['primaryColor'] = true,      -- Primary Paint Color
        ['secondaryColor'] = true,    -- Secondary Paint Color
        ['chameleonPaint'] = true,    -- Chameleon Paint Material (set to false to disable chameleon option from all paint dropdowns)
        ['customTires'] = true,       -- Custom Tires
        ['extras'] = true             -- Vehicle Extras
    },
    repair = {
        ['fullRepair'] = true,    -- Complete vehicle repair
        ['engineRepair'] = true,  -- Engine only repair
        ['bodyRepair'] = true,    -- Body/cosmetic repair
        ['tireRepair'] = true     -- Tire repair
    }
}

--[[
    MODIFICATION PRICING SYSTEM
    ===========================
    Prices are calculated as a percentage of the vehicle's base value.
    Example: If a vehicle costs $100,000 and engine upgrade level 1 is 0.05 (5%),
    the upgrade will cost $5,000.
    
    Categories:
    - tuning: Performance upgrades (engine, brakes, transmission, etc.)
    - cosmetic: Visual modifications (body kits, paint, wheels, etc.)
    - repair: Repair services
]]
Config.ModificationPricing = {
    
    -- PERFORMANCE UPGRADES (tuning)
    -- Each array represents upgrade levels, values are % of vehicle price
    tuning = {
        [11] = {0.05, 0.10, 0.15, 0.25},  -- Engine: Level -1 (5%), 0 (10%), 1 (15%), 2 (25%)
        [12] = {0.03, 0.06, 0.09, 0.12},  -- Brakes: Level -1 (3%), 0 (6%), 1 (9%), 2 (12%)
        [13] = {0.04, 0.08, 0.12},        -- Transmission: Level -1 (4%), 0 (8%), 1 (12%)
        [15] = {0.035, 0.07, 0.105, 0.14, 0.175},  -- Suspension: 5 levels
        [16] = {0.025, 0.05, 0.075, 0.10, 0.125, 0.15},  -- Armor: 6 levels
        [18] = 0.20  -- Turbo: Single upgrade (20%)
    },
    
    -- COSMETIC MODIFICATIONS (cosmetic)
    -- Single value = fixed percentage, regardless of variant
    -- Based on GTA V vehicle mod slots
    cosmetic = {
        -- BODY PARTS (Standard GTA V Mod Slots)
        [0] = 0.015,   -- Spoiler (1.5%)
        [1] = 0.02,    -- Front Bumper (2%)
        [2] = 0.02,    -- Rear Bumper (2%)
        [3] = 0.01,    -- Side Skirt (1%)
        [4] = 0.015,   -- Exhaust (1.5%)
        [5] = 0.01,    -- Frame / Roll Cage (1%)
        [6] = 0.015,   -- Grille (1.5%)
        [7] = 0.015,   -- Hood (1.5%)
        [8] = 0.01,    -- Fender (1%)
        [9] = 0.01,    -- Right Fender / Horn (1%)
        [10] = 0.01,   -- Roof / Hydraulics (1%)
        [14] = 0.01,   -- Horn (1%)
        [17] = 0.015,  -- Grille (1.5%)
        [19] = 0.015,  -- Dashboard (1.5%)
        [20] = 0.01,   -- Dial / Speakers (1%)
        [21] = 0.02,   -- Door Speakers / Seats (2%)
        [22] = 0.03,   -- Xenon Headlights / Steering Wheel (3%)
        [23] = 0.015,  -- Front Wheels / Engine Block (1.5%)
        [24] = 0.015,  -- Back Wheels / Rail Covers (1.5%)
        [25] = 0.01,   -- Plate Holder / Struts (1%)
        [26] = 0.01,   -- Vanity Plates / Headlight Covers (1%)
        [27] = 0.01,   -- Trim Design / Hood Catches (1%)
        [28] = 0.01,   -- Ornaments / Roof Scoops (1%)
        [29] = 0.01,   -- Dashboard / Mirrors (1%)
        [30] = 0.01,   -- Dial / Stickers (1%)
        [31] = 0.01,   -- Door Speaker / Plate Index (1%)
        [32] = 0.01,   -- Seats / Window Tint (1%)
        [33] = 0.015,  -- Steering Wheel (1.5%)
        [34] = 0.01,   -- Shifter Levers (1%)
        [35] = 0.01,   -- Plaques (1%)
        [36] = 0.01,   -- Speakers (1%)
        [37] = 0.01,   -- Trunk (1%)
        [38] = 0.01,   -- Hydraulics (1%)
        [39] = 0.01,   -- Engine Block (1%)
        [40] = 0.01,   -- Air Filter (1%)
        [41] = 0.01,   -- Struts (1%)
        [42] = 0.01,   -- Arch Cover (1%)
        [43] = 0.01,   -- Aerials (1%)
        [44] = 0.01,   -- Trim (1%)
        [45] = 0.01,   -- Tank (1%)
        [46] = 0.01,   -- Windows (1%)
        [47] = 0.02,   -- Livery 2 (2%)
        [48] = 0.02,   -- Livery (2%)
        [49] = 0.02,   -- Lightbox / Lightbar (2%)
        ['windowTint'] = 0.02,        -- Window Tint (2%)
        ['plateIndex'] = 0.005,       -- License Plate Style (0.5%)
        ['wheelType'] = 0.015,        -- Wheel Type/Category (1.5%)
        ['xenonColor'] = 0.01,        -- Xenon Light Color (1%)
        ['neonLights'] = 0.05,        -- Neon Underglow Lights (5%)
        ['neonColor'] = 0.01,         -- Neon Light Color (1%)
        ['tyreSmokeColor'] = 0.015,   -- Tire Smoke Color (1.5%)
        ['tyreSmokeEnabled'] = 0.01,  -- Tire Smoke Enabled (1%)
        ['pearlescentColor'] = 0.01,  -- Pearlescent Paint (1%)
        ['wheelColor'] = 0.01,        -- Wheel Color (1%)
        ['interiorColor'] = 0.015,    -- Interior Color (1.5%)
        ['dashboardColor'] = 0.015,   -- Dashboard Color (1.5%)
        ['primaryColor'] = 0.02,      -- Primary Paint Color (2%)
        ['secondaryColor'] = 0.02,    -- Secondary Paint Color (2%)
        ['customTires'] = 0.02,       -- Custom Tires (2%)
        ['extras'] = 0.01             -- Vehicle Extras (1%)
    },
    
    -- REPAIR SERVICES (repair)
    -- Used by radial menu repair functions
    repair = {
        ['fullRepair'] = 0.10,     -- Complete vehicle repair (10%)
        ['engineRepair'] = 0.05,   -- Engine only repair (5%)
        ['bodyRepair'] = 0.03,     -- Body/cosmetic repair (3%)
        ['tireRepair'] = 0.01      -- Tire repair (1%)
    }
}

-- Default price used when a vehicle's price cannot be determined
-- This ensures modifications always have a calculable cost
Config.DefaultVehiclePrice = 50000

Config.FixCommand = 'fix'

Config.RadialItemRequirements = {
    enabled = true,
    consumeItems = true,
    items = {
        repairkit = 'repairkit',
        sponge = 'sponge',
        rope = 'rope',
        fuel = 'petrolcan' -- Fuel item for refueling (use any item name from your inventory, NOT weapon_petrolcan)
    }
}

-- Carlift Model Configuration
-- Allows server owners to swap carlift prop models and tweak positioning parameters
Config.CarliftModels = {
    pole = "qs-carlift",
    arm = "qs-carlift-platform",
    armOffset = { x = -0.3, y = 0.3, z = -0.08 },   -- Platform offset from pole
    liftHeight = 2.5,                                 -- Maximum lift height above base
    vehicleZOffset = 0.40,                            -- Vehicle vertical offset when attached
    detectionRadius = 2.0,                            -- Radius for detecting existing carlift props
    interactionRadius = 5.0,                          -- Radius for vehicle-to-carlift interaction
}

-- Tuneshop Zone Configuration
-- Allows you to customize the size of tuneshop interaction zones
Config.TuneshopZoneSize = {
    x = 8.0,  -- Width of the zone
    y = 8.0,  -- Length of the zone
    z = 4.0   -- Height of the zone
}

-- Mechanics Only Tuneshop
-- When enabled, only players with mechanic jobs can use the tuneshop locations
-- Set to true to restrict tuneshops to mechanics only
Config.MechanicsOnlyTuneshop = false

-- Flatbed Configuration
-- Add vehicle model names that should be recognized as flatbed trucks
-- You can use either the spawn name or the display name
Config.Flatbeds = {
    'flatbed',      -- Default GTA flatbed
    -- Add more flatbed models below as needed:
    -- 'flatbed2',
    -- 'flatbed3',
    -- 'slamtruck',
    -- 'towtruck',
    -- 'towtruck2'
}

-- Engine name to type mapping for automatic detection
EngineNameMapping = {
    ["I4 2.0L Turbo"] = "I4_2_0L_TURBO",
    ["I6 3.0L Turbo"] = "I6_3_0L_TURBO",
    ["V8 5.0L Naturally Aspirated"] = "V8_5_0L_NA",
    ["V8 5.0L NA"] = "V8_5_0L_NA",
    ["V8 4.0L Twin Turbo"] = "V8_4_0L_TWIN_TURBO",
    ["V10 5.2L Naturally Aspirated"] = "V10_5_2L_NA",
    ["V10 5.2L NA"] = "V10_5_2L_NA",
    ["V12 6.0L Naturally Aspirated"] = "V12_6_0L_NA",
    ["V12 6.0L NA"] = "V12_6_0L_NA",
    ["W16 8.0L Quad Turbo"] = "W16_8_0L_QUAD_TURBO",
    ["Dual Motor Performance EV"] = "DUAL_MOTOR_EV"
}

-- Engine configurations with sound and handling modifications
EngineList = {
    I4_2_0L_TURBO = {
        label = "I4 2.0L Turbo",
        sound = "sultan",
        mods = {
            fInitialDriveForce = 0.28,
            fInitialDriveMaxFlatVel = 180.0,
            fDriveInertia = 1.0,
            fInitialDragCoeff = 4.5,
            fTractionCurveMax = 2.6,
            fTractionCurveMin = 2.4,
            fTractionCurveLateral = 22.5,
            fLowSpeedTractionLossMult = 1.0,
            fBrakeForce = 0.9
        }
    },
    I6_3_0L_TURBO = {
        label = "I6 3.0L Turbo",
        sound = "elegy2",
        mods = {
            fInitialDriveForce = 0.32,
            fInitialDriveMaxFlatVel = 195.0,
            fDriveInertia = 1.0,
            fInitialDragCoeff = 4.2,
            fTractionCurveMax = 2.7,
            fTractionCurveMin = 2.5,
            fTractionCurveLateral = 23.0,
            fLowSpeedTractionLossMult = 0.9,
            fBrakeForce = 1.0
        }
    },
    V8_5_0L_NA = {
        label = "V8 5.0L Naturally Aspirated",
        sound = "dominator",
        mods = {
            fInitialDriveForce = 0.38,
            fInitialDriveMaxFlatVel = 185.0,
            fDriveInertia = 1.1,
            fInitialDragCoeff = 5.0,
            fTractionCurveMax = 2.5,
            fTractionCurveMin = 2.2,
            fTractionCurveLateral = 21.5,
            fLowSpeedTractionLossMult = 1.3,
            fBrakeForce = 0.95
        }
    },
    V8_4_0L_TWIN_TURBO = {
        label = "V8 4.0L Twin Turbo",
        sound = "pariah",
        mods = {
            fInitialDriveForce = 0.42,
            fInitialDriveMaxFlatVel = 215.0,
            fDriveInertia = 0.95,
            fInitialDragCoeff = 3.8,
            fTractionCurveMax = 2.6,
            fTractionCurveMin = 2.3,
            fTractionCurveLateral = 22.0,
            fLowSpeedTractionLossMult = 1.2,
            fBrakeForce = 1.1
        }
    },
    V10_5_2L_NA = {
        label = "V10 5.2L Naturally Aspirated",
        sound = "nero2",
        mods = {
            fInitialDriveForce = 0.40,
            fInitialDriveMaxFlatVel = 205.0,
            fDriveInertia = 1.0,
            fInitialDragCoeff = 4.0,
            fTractionCurveMax = 2.8,
            fTractionCurveMin = 2.6,
            fTractionCurveLateral = 23.5,
            fLowSpeedTractionLossMult = 0.85,
            fBrakeForce = 1.15
        }
    },
    V12_6_0L_NA = {
        label = "V12 6.0L Naturally Aspirated",
        sound = "zentorno",
        mods = {
            fInitialDriveForce = 0.45,
            fInitialDriveMaxFlatVel = 210.0,
            fDriveInertia = 0.9,
            fInitialDragCoeff = 3.5,
            fTractionCurveMax = 2.9,
            fTractionCurveMin = 2.7,
            fTractionCurveLateral = 24.0,
            fLowSpeedTractionLossMult = 0.9,
            fBrakeForce = 1.2
        }
    },
    W16_8_0L_QUAD_TURBO = {
        label = "W16 8.0L Quad Turbo",
        sound = "adder",
        mods = {
            fInitialDriveForce = 0.50,
            fInitialDriveMaxFlatVel = 230.0,
            fDriveInertia = 1.2,
            fInitialDragCoeff = 3.0,
            fTractionCurveMax = 3.0,
            fTractionCurveMin = 2.8,
            fTractionCurveLateral = 24.5,
            fLowSpeedTractionLossMult = 0.8,
            fBrakeForce = 1.3
        }
    },
    DUAL_MOTOR_EV = {
        label = "Dual Motor Performance EV",
        sound = "cyclone",
        mods = {
            fInitialDriveForce = 0.55,
            fInitialDriveMaxFlatVel = 200.0,
            fDriveInertia = 0.8,
            fInitialDragCoeff = 4.0,
            fTractionCurveMax = 3.1,
            fTractionCurveMin = 2.9,
            fTractionCurveLateral = 25.0,
            fLowSpeedTractionLossMult = 0.5,
            fBrakeForce = 1.25
        }
    }
}

-- Complete engine catalog with all metadata for stock management
EngineCatalog = {
    ["I4 2.0L Turbo"] = {
        id = 1,
        name = "I4 2.0L Turbo",
        power = "252 HP",
        speed = "90 mph",
        acceleration = "0-60: 7.5s",
        torque = "231 lb-ft",
        price = 15000,
        image = "assets/engines/I420LTurbo.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "I4_2_0L_TURBO"
    },
    ["I6 3.0L Turbo"] = {
        id = 2,
        name = "I6 3.0L Turbo",
        power = "388 HP",
        speed = "94 mph",
        acceleration = "0-60: 6.2s",
        torque = "356 lb-ft",
        price = 28000,
        image = "assets/engines/I630LTurbo.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "I6_3_0L_TURBO"
    },
    ["V8 5.0L Naturally Aspirated"] = {
        id = 3,
        name = "V8 5.0L Naturally Aspirated",
        power = "321 HP",
        speed = "90 mph",
        acceleration = "0-60: 6.8s",
        torque = "301 lb-ft",
        price = 32000,
        image = "assets/engines/V85lNaturallyAspirated.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4000,
        engineType = "V8_5_0L_NA"
    },
    ["V8 4.0L Twin Turbo"] = {
        id = 4,
        name = "V8 4.0L Twin Turbo",
        power = "333 HP",
        speed = "96 mph",
        acceleration = "0-60: 6.7s",
        torque = "306 lb-ft",
        price = 58000,
        image = "assets/engines/V84lTwinTurbo.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "V8_4_0L_TWIN_TURBO"
    },
    ["V10 5.2L Naturally Aspirated"] = {
        id = 5,
        name = "V10 5.2L Naturally Aspirated",
        power = "424 HP",
        speed = "99 mph",
        acceleration = "0-60: 5.8s",
        torque = "389 lb-ft",
        price = 65000,
        image = "assets/engines/V1052LNaturallyAspirated.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "V10_5_2L_NA"
    },
    ["V12 6.0L Naturally Aspirated"] = {
        id = 6,
        name = "V12 6.0L Naturally Aspirated",
        power = "367 HP",
        speed = "98 mph",
        acceleration = "0-60: 6.4s",
        torque = "337 lb-ft",
        price = 85000,
        image = "assets/engines/V1260LNaturallyAspirated.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "V12_6_0L_NA"
    },
    ["W16 8.0L Quad Turbo"] = {
        id = 7,
        name = "W16 8.0L Quad Turbo",
        power = "399 HP",
        speed = "99 mph",
        acceleration = "0-60: 6.0s",
        torque = "366 lb-ft",
        price = 250000,
        image = "assets/engines/W1680L.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "W16_8_0L_QUAD_TURBO"
    },
    ["Dual Motor Performance EV"] = {
        id = 8,
        name = "Dual Motor Performance EV",
        power = "339 HP",
        speed = "98 mph",
        acceleration = "0-60: 6.6s",
        torque = "312 lb-ft",
        price = 75000,
        image = "assets/engines/DualMotorPerformanceEV.png",
        peakHPRPM = 8000,
        peakTorqueRPM = 4666,
        engineType = "DUAL_MOTOR_EV"
    }
}

-- Helper function to get complete engine data by name
function GetCompleteEngineData(engineName)
    return EngineCatalog[engineName]
end