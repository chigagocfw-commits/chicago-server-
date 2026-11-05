

--[[
    ╔══════════════════════════════════════════════════════════════════════╗
    ║   OXLYN Software®  •  Advanced Garage System  •  config/config.lua   ║
    ╚══════════════════════════════════════════════════════════════════════╝

    Every option in this file is documented. Anything you do not touch keeps
    a sensible default. Garages themselves are NOT configured here — they are
    created in-game with the editor (/garageeditor) and stored in the database.
    Config.DefaultGarages below is only the starter set, seeded the very first
    time the resource boots on an empty table.

    WHAT IS SET WHERE
      • This file ........ server-wide rules and the DEFAULTS of everything.
      • /garageeditor .... every garage (location, spots, zone, fleet, access,
                           attendant, blip), the interface theme and the park
                           mode rules. Saved in the database; overrides the
                           matching defaults here without touching this file.
      • locales/*.lua .... every text players see (en, pt — add your own).

    Restart the resource after editing this file (ensure oxlyn-garage).

    INDEX
      1. General            (language, framework, currency)
      2. Admin permissions  (who may open the editor)
      3. Commands
      4. Interaction        (E prompt vs ox_target / qb-target, world icons)
      5. Garage rules       (fees, global garages, fleet, restart behaviour, preview)
      6. Impound            (/impound, jobs, fees, lots)
      6b. Park mode         (/park)
      7. Sale contracts     (the vehicle_contract item)
      8. Vehicle keys / notifications / fuel  (bridges to other resources)
      9. Blips & peds
     10. Interface          (theme defaults)
     11. Default garages    (seed data, used once)
]]

Config = {}

-- ═══════════════════════════════════════════════════════════════════════
--  1. GENERAL
-- ═══════════════════════════════════════════════════════════════════════
-- Language of every text (locales/<code>.lua): 'en' English · 'pt' Português ·
-- 'es' Español · 'fr' Français · 'de' Deutsch · 'pl' Polski · 'lt' Lietuvių.
-- The contract paper writes amounts in words in the same language. Copy
-- locales/en.lua to add another one; missing keys fall back to English.
Config.Locale    = 'en'
Config.Debug     = false     -- verbose console output (detection, saves, spawns)
-- 'auto' detects Qbox → QBCore → ESX in that order. Force one if you run
-- several cores side by side. 'standalone' = no framework (nobody owns vehicles).
Config.Framework = 'auto'    -- 'auto' | 'esx' | 'qbcore' | 'qbox' | 'standalone'

-- Phone garage / valet API. See EXPORTS.MD for CodeM mPhone 2.5, LB-Phone
-- and generic adapters. Fees charged by a native phone remain its responsibility;
-- trusted adapters pass { charge = false } to avoid charging twice.
Config.Phone = {
    enabled = true,
    valet = {
        enabled = true,
        fee = 0,             -- OXLYN generic RequestValet fee
        account = 'bank',     -- 'bank' | 'cash'
        maxDistance = 250.0,  -- bounded distance for NPC valet road spawns
    },
}

-- Currency formatting used by notifications AND the interface.
Config.Currency = {
    symbol   = '$',
    position = 'before',     -- 'before' → $1,200   'after' → 1,200 €
    thousands = ',',
}

-- ═══════════════════════════════════════════════════════════════════════
--  2. ADMIN PERMISSIONS
--  A player is an admin when ANY enabled source says yes (OR union):
--    ace        → holds one of Config.Admin.aces
--    group      → framework group in `groups` (plus the group.<name> /
--                 qbcore.<name> / qbx.<name> / esx.<name> ace bridges when
--                 `groupAces` is on — this is what makes txAdmin work)
--    job        → job in `jobs` with at least that grade
--    identifier → license/discord/steam in `identifiers`
--  The server console (src 0) is always allowed when `allowConsole` is on.
--
--  server.cfg recipe:
--      add_ace group.admin oxlyn.garage.admin allow
--      add_principal identifier.license:XXXXXXXX group.admin
--  (an add_ace in server.cfg only applies on a FULL server restart — paste
--   the two lines in the live console to apply right now)
--
--  Diagnose "I'm admin but it says no": /garageaccess <id>
-- ═══════════════════════════════════════════════════════════════════════
Config.Admin = {
    everyone     = false,                      -- true = the editor is open to EVERYONE (test servers only!)
    methods      = { 'ace', 'group', 'identifier' },   -- any of 'ace' | 'group' | 'job' | 'identifier'
    aces         = { 'oxlyn.garage.admin' },
    groupAces    = true,
    groups       = { 'admin', 'superadmin', 'god' },
    jobs         = {},                         -- e.g. { mapper = 0, police = 4 }  (job = minimum grade)
    jobOnDuty    = false,                      -- job source only counts while on duty (QB/Qbox)
    identifiers  = {},                         -- e.g. { 'license:abc123…', 'discord:1234…' }
    allowConsole = true,
    -- Custom hook: return true / false to decide, nil to fall through.
    -- check = function(src) return exports.myperms:isStaff(src) end,
    check        = nil,
    debug        = false,                      -- print every evaluation to the console
}

-- ═══════════════════════════════════════════════════════════════════════
--  3. COMMANDS
-- ═══════════════════════════════════════════════════════════════════════
Config.Commands = {
    editor  = 'garageeditor',   -- opens the admin studio (gated by Config.Admin)
    access  = 'garageaccess',   -- /garageaccess <id> — prints the permission report
    impound = 'impound',        -- /impound [fee] [reason] — see Config.Impound.jobs
    garage  = 'garage',         -- nearby garage; /garage <player ID> opens admin vehicle management (Config.Admin); false disables both
    park    = 'park',           -- park mode: leave the vehicle next to you where it is (see Config.Park)
    admincar = 'admincar',      -- admins (Config.Admin): the vehicle you sit in becomes yours and joins your garage (false to disable)
    contract = 'contract',      -- admins, SHOWCASE: an NPC buyer sits next to you for the sale contract and signs/pays on the paper only — nothing real changes (for videos; false to disable)
    suggestions = false,        -- register the commands in the chat's auto-complete
}

-- ═══════════════════════════════════════════════════════════════════════
--  4. INTERACTION
-- ═══════════════════════════════════════════════════════════════════════
Config.Interaction = {
    -- How players open a garage on foot. This is the DEFAULT: admins can
    -- switch it in-game (/garageeditor → Theme → Opening a garage) and that
    -- choice, saved for the whole server, wins over this line.
    -- 'prompt' → OXLYN keycap prompt + floating world icon (no dependency)
    -- 'target' → ox_target / qb-target option on the garage point (where the
    --            attendant stands). Parking a vehicle still uses the prompt
    --            from the driver seat. With no target resource running the
    --            E prompt keeps working, so nobody is locked out.
    -- 'both'   → prompt AND target
    mode         = 'prompt',
    key          = 38,          -- game control id (38 = E)
    keyLabel     = 'E',         -- what the keycap shows
    drawDistance = 60.0,        -- metres — world icons / prompt logic wake up inside this
    -- Floating icons drawn by the interface over each garage point (no 3D
    -- game markers). The look is picked in the editor (Theme → World icon).
    worldIcons = {
        enabled  = true,
        distance      = 12.0,   -- gone beyond this distance (metres)
        fadeFrom      = 6.0,    -- fully visible up to here, then fades out towards `distance`
        labels        = true,   -- garage name under the icon
        labelDistance = 5.0,    -- the name only shows this close
    },
    -- ox_target / qb-target options when mode is 'target' or 'both'
    target = {
        icon        = 'fa-solid fa-warehouse',   -- garages
        impoundIcon = 'fa-solid fa-gavel',       -- impound lots
        distance    = 2.5,
    },
}

-- ═══════════════════════════════════════════════════════════════════════
--  5. GARAGE RULES
-- ═══════════════════════════════════════════════════════════════════════
Config.Garage = {
    -- false → a vehicle can only be taken out of the garage it was parked in
    --         (other garages list it as "Parked at …" with a "Bring here" action)
    -- true  → every garage of the right type shows every stored vehicle
    -- Editor → Identity → Only vehicles in this garage overrides this per garage:
    -- local vehicles cannot be fetched remotely by other garages or phone valet.
    -- Driving the vehicle and storing it elsewhere is still allowed.
    global            = false,
    transferFee       = 500,    -- "Bring here" valet fee (0 = free). Only when global = false.
    retrieveFee       = 250,    -- "Rescue": fee to bring back a vehicle that is OUT in the world (lost/destroyed), from anywhere. 0 = free.
    retrieveDeletesWorld = true,-- delete the matching world vehicle when rescued
    rescueWhenOccupied = false, -- false → no rescue while somebody sits in the vehicle (it is not pulled from under a player)
    -- Lost personal vehicles (marked "out" in SQL):
    -- 'garage'  → keep the Rescue action and retrieveFee above (default).
    -- 'impound' → missing vehicles go to an impound lot with this fixed fine/reason.
    -- 'disabled'→ no garage recovery or automatic impound; Locate still works.
    lostVehicles = {
        mode          = 'garage',
        autoImpound   = true,  -- in impound mode, detect missing vehicles automatically
        graceSeconds  = 120,   -- wait after first observed absence (also after a restart)
        checkInterval = 60,    -- seconds between server checks; never runs per frame
        impound = {
            lot    = nil,     -- nil = choose an existing impound; or its exact editor ID
            fee    = 500,     -- fixed fine, paid ONCE when released; capped by Impound.maxFee
            reason = 'Abandoned / lost vehicle',
        },
    },
    -- Impound recovery requires absence from the SERVER world: streaming out
    -- on a player's client is not a loss. /park, pending spawns and sale
    -- contracts are excluded. Stored tuning/damage is preserved.
    -- autoImpound=false offers manual Send to impound after the same grace.
    -- "Locate" (menu): the map blip put on a vehicle that is out in the world
    locateBlipSeconds = 120,

    -- What happens to vehicles marked "out" when the resource boots (after a
    -- server restart the world is empty, so they cannot be found anyway).
    -- true → they are put back in the garage they last used (no fee).
    -- Applies only when lostVehicles.mode='garage'. Other modes keep their policy.
    restoreOnRestart  = true,

    -- Where the player stands after parking. Vehicle types set to true send
    -- the driver back to the garage point, in front of the attendant (boats
    -- are parked on the water, aircraft on the apron). Anything else steps
    -- out beside the vehicle. Keys: car, motorcycle, boat, air.
    returnToAttendant = { boat = true, air = true },

    -- Fleet (editor → Fleet): a garage's own vehicles for everyone who may use
    -- it (job / gang garages). How many fleet vehicles one player may have out
    -- from the same garage at a time (0 = no limit) — the default; each garage
    -- can set its own in the editor (Fleet → Per player). Taking one more when
    -- the limit is reached brings the player's other one back if it is empty.
    fleetPerPlayer    = 1,
    -- A fleet vehicle left empty comes back by itself when its driver takes
    -- another one over the limit, or when its driver left the server. The
    -- default for garages that do not set it (editor → Fleet → Bring back
    -- empty vehicles); false = it stays out until parked back or destroyed.
    fleetRecall       = true,

    putInVehicle      = true,   -- warp the player into the driver seat on take-out
    -- Takeout starts the engine after the vehicle keys are ready. Saved
    -- engine damage and fuel still apply; no repair/refuel is performed.
    lockOnStore       = false,  -- (cosmetic) lock doors before deleting
    spotClearRadius   = 2.6,    -- metres — a spot is "occupied" if any vehicle is closer than this
    maxVehiclesPerPlayer = 0,   -- purchase/transfer cap used by contracts (0 = unlimited)
    typeCheck         = true,   -- refuse boats in car garages etc.
    allowStoreOthers  = false,  -- true = a driver may park a vehicle owned by somebody else (it stays theirs)
    storeUnknownVehicles = false, -- true = any vehicle you drive can be stored (it must still be in your DB)
    -- Distance from the garage point (or from any parking spot) a vehicle
    -- must be within to be stored — the default garages set their own.
    defaultStoreRadius = 14.0,   -- a garage with a drawn zone (editor → Location → Draw zone) uses the zone instead
    defaultRadius      = 2.5,   -- on-foot interaction radius

    -- Cinematic preview: picking a vehicle in the menu puts a local copy on
    -- the first free spot with you inside and a camera orbiting it; Spawn
    -- takes it out right there, or pick another. Other players never see the copy.
    preview = {
        enabled    = true,
        fov        = 40.0,      -- camera field of view
        distance   = 1.0,       -- camera distance multiplier (framed from each vehicle's size; 1.2 = 20 % farther)
        orbitSpeed = 6.0,       -- degrees per second while you are not dragging
    },
}

-- ═══════════════════════════════════════════════════════════════════════
--  6. IMPOUND
-- ═══════════════════════════════════════════════════════════════════════
Config.Impound = {
    -- Jobs allowed to use /impound  (job = minimum grade). Admins can always.
    jobs         = { police = 0, sheriff = 0, mechanic = 0 },
    jobOnDuty    = false,
    adminCanImpound = false,    -- true → admins can impound even without one of the jobs
    defaultFee   = 300,
    maxFee       = 25000,
    defaultReason = 'Impounded by the authorities',
    -- Which impound lot receives the vehicle when the command does not say:
    -- 'nearest' picks the closest impound-kind garage to the officer.
    defaultLot   = 'nearest',
    anyLot       = true,        -- true → every impound lot shows all of your impounded vehicles
    radius       = 6.0,         -- /impound with arguments: nearest vehicle within this distance
    toolRadius   = 30.0,        -- /impound without arguments: the tool lists vehicles within this distance
    -- Quick reasons offered by the tool (free text is always possible)
    reasons      = { 'Abandoned vehicle', 'Illegally parked', 'Reckless driving', 'Evidence · seized', 'Unpaid fines' },
    deleteUnknownPlates = true, -- /impound on a vehicle nobody owns just deletes it
}

-- ═══════════════════════════════════════════════════════════════════════
--  6b. PARK MODE  (/park)
--  Leave your vehicle where it stands, for good: it survives restarts, is
--  locked for everybody else and comes back the moment you try to get in.
--  These are the defaults — the garage editor (Park mode page) overrides
--  them for the whole server without touching this file. The optional
--  keybind below is config-only (not overwritten by the editor).
-- ═══════════════════════════════════════════════════════════════════════
Config.Park = {
    enabled      = true,
    keybind = {
        enabled = false,       -- true enables a shortcut alongside the /park command
        mapper  = 'keyboard',
        key     = 'F7',        -- FiveM input name, not a numeric GTA control ID
    },
    -- Players may rebind under Settings → Key Bindings → FiveM.
    -- This is the default for new bindings; it does not overwrite their saved key.
    -- Config.Commands.park=false disables the chat command independently.
    collision    = false,       -- false → players and cars pass through a parked vehicle
    blip         = true,        -- the owner sees a map blip where they left it
    maxPerPlayer = 3,           -- parked vehicles per player (0 = unlimited)
    radius       = 8.0,         -- /park: the vehicle must be within this distance
    -- How long a vehicle may stay in park mode (real hours since /park, also
    -- across restarts). Past it, it is towed to the nearest impound lot with
    -- `towFee` as its release fee; the owner is told when parking, warned
    -- 15 minutes before and notified when it is towed. 0 = no limit.
    maxHours     = 4.0,
    towFee       = 300,
    -- after /park: a hologram over the car (interface, not game text) with
    -- the time limit and the tow fee, for this many seconds. 0 = a plain
    -- notification instead.
    hologramSeconds = 8,
}

-- ═══════════════════════════════════════════════════════════════════════
--  7. SALE CONTRACTS  (item: vehicle_contract)
--  The deal happens INSIDE the vehicle: the owner sits in their car with the
--  buyer as a passenger and uses the contract item → the agreement paper
--  opens with the vehicle already filled in → the owner writes the price and
--  signs to hand it over → the buyer sees the same paper, ticks cash or card
--  and signs to pay (or declines) → ownership, keys and money move on the
--  spot, server-side. Works with ANY inventory (no item metadata needed).
--  Add the item to your inventory first: see install/ and the README.
Config.Contract = {
    enabled        = true,
    item           = 'vehicle_contract',
    minPrice       = 1,
    maxPrice       = 50000000,
    tax            = 0,         -- % taken from the price (money sink). 5 = buyer pays price, seller gets 95 %
    offerMinutes   = 5,         -- the buyer has this long to sign and pay before the offer voids
    requireSameVehicle = true,  -- both must still be sitting in the vehicle when the buyer pays
    accounts       = { 'cash', 'bank' },   -- what the buyer may pay with ('bank' shows as "card")
    consumeItem    = true,      -- the contract sheet is used up when the sale completes
    sellerReceives = 'bank',    -- 'same' (same account the buyer paid with) | 'bank' | 'cash'
}

-- ═══════════════════════════════════════════════════════════════════════
--  8. VEHICLE KEYS / FUEL
-- ═══════════════════════════════════════════════════════════════════════
Config.VehicleKeys = {
    enabled  = true,
    -- 'auto', 'none', or one of these providers:
    --   'qbx'    qbx_vehiclekeys     'qb'     qb-vehiclekeys      'mrnewb' MrNewbVehicleKeys
    --   'wasabi' wasabi_carlock      'renewed' Renewed-Vehiclekeys 'qs'     qs-vehiclekeys
    --   'ti'     ti_vehicleKeys      'jaksam' vehicles_keys       'ak47'   ak47_vehiclekeys
    --   'tgiann' tgiann-hotwire      'brutal' brutal_keys         'mono'   mono_carkeys
    --   'mk'     mk_vehiclekeys      't1ger'  t1ger_keys          'frks'   F_RealCarKeysSystem
    --   'xd'     xd_locksystem       'esxlock' esx_vehiclelock    'cd_garage'   'okok'
    -- If more than one keys resource runs, choose your actual provider:
    -- for qs-vehiclekeys use 'qs'. Auto detects running resources, not which
    -- inventory/ignition system your server intends to use, and warns on ambiguity.
    -- Systems without a public API (e.g. private codem/rcore builds) hook in
    -- through the extra*Events lists below — see EXPORTS.MD.
    system   = 'qbx',
    removeOnStore = true,
    -- One grant after server approval. Sale/impound/recall always revoke the
    -- previous holder even when ordinary garage storage retains keys.
    extraClientEvents = {},     -- extra client events fired as (plate, model, vehicle)
    extraServerEvents = {},     -- extra server events fired as (src, plate, model, vehicle)
    extraClientRemoveEvents = {}, -- custom removal hooks, same client arguments
    extraServerRemoveEvents = {}, -- custom removal hooks, same server arguments (e.g. ti versions with custom removal)
}

-- NOTIFICATIONS — where the garage's messages go ("Vehicle stored",
-- "Not enough money"…).
--   'builtin' — the garage's own toasts (top right, follow the theme)
--   'auto'    — the first notification resource found running, in this order:
--               okokNotify, brutal_notify, wasabi_notify, lation_ui, t-notify,
--               mythic_notify, pNotify, oxlyn-notify, corescripts-notify,
--               esx_notify, ox_lib, qbx_core, qb-core, es_extended
--   or one of those by name: 'okokNotify' | 'brutal_notify' | 'wasabi_notify'
--               | 'lation_ui' | 't-notify' | 'mythic_notify' | 'pNotify'
--               | 'oxlyn-notify' | 'corescripts-notify' | 'esx_notify'
--               | 'ox_lib' | 'qbox' | 'qbcore' | 'esx'
--   'event'   — TriggerEvent(Config.Notify.event, message, type, title, durationMs)
--   'custom'  — Config.Notify.custom(message, type, title, durationMs)
-- type is 'success' | 'error' | 'warning' | 'info'. If the chosen resource is
-- not running or its export fails, the built-in toast is shown instead.
Config.Notify = {
    system   = 'builtin',
    title    = nil,         -- title for systems that show one (nil = "Garage" / "Garagem")
    duration = 5000,        -- ms
    event    = nil,         -- for system = 'event', e.g. 'my-notify:client:show'
    -- custom = function(message, type, title, duration)
    --     exports['my-notify']:Show(message, type, duration)
    -- end,
}

Config.Fuel = {
    -- 'auto' | 'native' | 'ox_fuel' | 'LegacyFuel' | 'cdn-fuel' | 'ps-fuel' | 'lc_fuel' | 'okokGasStation' | 'x-fuel' | 'ti_fuel' | 'nd_fuel' | 'rcore_fuel'
    system = 'auto',
}

-- ═══════════════════════════════════════════════════════════════════════
--  9. BLIPS & PEDS
-- ═══════════════════════════════════════════════════════════════════════
Config.Blips = {
    enabled = true,
    showOnlyAccessible = true,  -- hide job/gang/private garages from players without access
    garage  = { sprite = 357, color = 3, scale = 0.75 },   -- defaults for new garages
    impound = { sprite = 68,  color = 1, scale = 0.75 },
    boat    = { sprite = 410, color = 3, scale = 0.75 },
    air     = { sprite = 359, color = 3, scale = 0.75 },
}

Config.Peds = {
    enabled       = true,
    spawnDistance = 60.0,       -- local peds appear inside this distance and despawn beyond it
    defaultModel  = 's_m_y_valet_01',
    defaultScenario = 'WORLD_HUMAN_CLIPBOARD',
}

-- ═══════════════════════════════════════════════════════════════════════
-- 10. INTERFACE
-- ═══════════════════════════════════════════════════════════════════════
--  DEFAULTS for the in-game theme editor (/garageeditor → Theme). Whatever
--  admins save there is stored in the database and overrides these — this
--  block only matters until the first save (and after "Reset to defaults").
Config.UI = {
    brandName = 'OXLYN Garage', -- interface footer/window name; config-only, not overridden by the theme editor
    hideHudWhileOpen = true,
    theme = {
        preset  = 'midnight',   -- midnight | graphite | onyx | slate | steel | mint | amber | crimson | violet | custom
        accent  = '#4d7cff',    -- two hex colours drive the whole interface
        surface = '#0e121a',
        radius  = 'soft',       -- 'sharp' | 'soft' | 'round'
    },
    style      = 'showroom',    -- garage menu layout: 'showroom' | 'ledger' | 'grid' | 'minimal'
    worldIcon  = 'pin',         -- floating garage icon: 'pin' | 'badge' | 'minimal' | 'none'
    prompt     = 'card',        -- keycap prompt: 'card' | 'pill' | 'minimal'
    showImages = true,          -- real renders for vanilla vehicles (silhouette for add-ons)
    transitions = true,         -- the animated take-out / parking sequences
}

-- ═══════════════════════════════════════════════════════════════════════
-- 11. DEFAULT GARAGES (seed)
--  Only used once, when the oxlyn_garages table is empty. After that the
--  in-game editor owns the data. Coordinates are sensible starting points —
--  adjust them in the editor to fit your map.
--  Fields: see README → "Garage schema".
-- ═══════════════════════════════════════════════════════════════════════
Config.DefaultGarages = {
    {
        id = 'legion_square', label = 'Legion Square Parking', kind = 'garage', type = 'car',
        point = { x = 215.4642, y = -806.1658, z = 30.7996, w = 353.9135 },
        radius = 2.5, storeRadius = 22.0,
        spots = {
            { x = 222.0, y = -782.5, z = 30.6, w = 338.0 },
            { x = 225.6, y = -784.0, z = 30.6, w = 338.0 },
            { x = 229.3, y = -785.5, z = 30.6, w = 338.0 },
            { x = 218.4, y = -781.0, z = 30.6, w = 338.0 },
            { x = 214.8, y = -779.6, z = 30.6, w = 338.0 },
            { x = 211.2, y = -778.2, z = 30.6, w = 338.0 },
        },
        blip = { enabled = true, sprite = 357, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_valet_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'vinewood', label = 'Vinewood Boulevard Garage', kind = 'garage', type = 'car',
        point = { x = -343.9, y = -874.2, z = 31.1, w = 90.0 },
        radius = 2.5, storeRadius = 18.0,
        spots = {
            { x = -353.4, y = -876.9, z = 31.0, w = 90.0 },
            { x = -353.4, y = -880.6, z = 31.0, w = 90.0 },
            { x = -353.4, y = -884.3, z = 31.0, w = 90.0 },
            { x = -353.4, y = -888.0, z = 31.0, w = 90.0 },
        },
        blip = { enabled = true, sprite = 357, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_valet_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'sandy_shores', label = 'Sandy Shores Garage', kind = 'garage', type = 'car',
        point = { x = 1737.9, y = 3709.0, z = 34.1, w = 20.0 },
        radius = 2.5, storeRadius = 18.0,
        spots = {
            { x = 1722.7, y = 3713.6, z = 33.2, w = 19.9 },
            { x = 1726.4, y = 3715.0, z = 33.2, w = 19.9 },
            { x = 1730.1, y = 3716.4, z = 33.2, w = 19.9 },
        },
        blip = { enabled = true, sprite = 357, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_valet_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'paleto_bay', label = 'Paleto Bay Garage', kind = 'garage', type = 'car',
        point = { x = -211.4, y = 6206.5, z = 31.4, w = 225.0 },
        radius = 2.5, storeRadius = 18.0,
        spots = {
            { x = -204.6, y = 6221.6, z = 30.5, w = 227.2 },
            { x = -201.9, y = 6218.9, z = 30.5, w = 227.2 },
            { x = -199.2, y = 6216.2, z = 30.5, w = 227.2 },
        },
        blip = { enabled = true, sprite = 357, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_valet_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'marina_boats', label = 'Marina Boat Dock', kind = 'garage', type = 'boat',
        point = { x = -772.9, y = -1431.5, z = 1.6, w = 140.0 },
        radius = 2.5, storeRadius = 40.0,
        spots = {
            { x = -778.2990, y = -1429.9110, z = 1.6772, w = 139.9541 },
            { x = -758.0, y = -1463.3, z = 0.0, w = 140.0 },
        },
        blip = { enabled = true, sprite = 410, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_dockwork_01', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'lsia_hangar', label = 'LSIA Hangar', kind = 'garage', type = 'air',
        point = { x = -1006.4, y = -3020.5, z = 13.9, w = 60.0 },
        radius = 2.5, storeRadius = 45.0,
        spots = {
            { x = -1010.6, y = -2989.5, z = 13.9, w = 60.0 },
            { x = -980.8, y = -3007.0, z = 13.9, w = 60.0 },
        },
        blip = { enabled = true, sprite = 359, color = 3, scale = 0.75 },
        ped = { enabled = true, model = 's_m_y_airworker', scenario = 'WORLD_HUMAN_CLIPBOARD' },
        access = { mode = 'public' },
    },
    {
        id = 'mission_row_pd', label = 'Mission Row PD Garage', kind = 'garage', type = 'car',
        point = { x = 452.6, y = -1000.1, z = 25.8, w = 90.0 },
        radius = 2.5, storeRadius = 20.0,
        spots = {
            { x = 442.3, y = -1003.2, z = 25.7, w = 180.0 },
            { x = 438.5, y = -1003.2, z = 25.7, w = 180.0 },
            { x = 434.7, y = -1003.2, z = 25.7, w = 180.0 },
        },
        blip = { enabled = false, sprite = 357, color = 38, scale = 0.7 },
        ped = { enabled = true, model = 's_m_y_cop_01', scenario = 'WORLD_HUMAN_COP_IDLES' },
        access = { mode = 'job', jobs = { police = 0, sheriff = 0 } },
        -- A job garage keeps its own FLEET instead of players' personal cars
        -- (personal = false is the default for job / gang garages). Edit it
        -- in /garageeditor → Fleet. count = how many can be out at once
        -- (0 = no limit), minGrade = lowest job grade that may take it.
        personal = false,
        fleetPlate = 'LSPD',
        fleet = {
            { model = 'police',  label = 'Police Cruiser',     minGrade = 0, count = 0 },
            { model = 'police2', label = 'Police Buffalo',     minGrade = 0, count = 0 },
            { model = 'police3', label = 'Police Interceptor', minGrade = 2, count = 2, tuned = true },
            { model = 'policeb', label = 'Police Bike',        minGrade = 1, count = 2 },
        },
    },
    {
        id = 'impound_davis', label = 'Davis Impound Lot', kind = 'impound', type = 'all',
        point = { x = 400.7, y = -1630.5, z = 29.3, w = 230.0 },
        radius = 2.5, storeRadius = 25.0,
        spots = {
            { x = 401.9, y = -1647.4, z = 29.2, w = 323.3 },
            { x = 405.4, y = -1650.2, z = 29.2, w = 323.3 },
            { x = 408.9, y = -1653.0, z = 29.2, w = 323.3 },
        },
        blip = { enabled = true, sprite = 68, color = 1, scale = 0.75 },
        ped = { enabled = true, model = 's_m_m_security_01', scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        access = { mode = 'public' },
        impound = { fee = 300 },
    },
    {
        id = 'impound_paleto', label = 'Paleto Impound Lot', kind = 'impound', type = 'all',
        point = { x = -211.4, y = 6199.0, z = 31.4, w = 225.0 },
        radius = 2.5, storeRadius = 25.0,
        spots = {
            { x = -196.5, y = 6213.5, z = 30.5, w = 227.2 },
            { x = -193.8, y = 6210.8, z = 30.5, w = 227.2 },
        },
        blip = { enabled = true, sprite = 68, color = 1, scale = 0.75 },
        ped = { enabled = true, model = 's_m_m_security_01', scenario = 'WORLD_HUMAN_STAND_MOBILE' },
        access = { mode = 'public' },
        impound = { fee = 300 },
    },
}

