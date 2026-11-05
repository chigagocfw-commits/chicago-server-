

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN-HANDLING  •  config.lua
--  Everything a server owner should ever need to touch.
-- ════════════════════════════════════════════════════════════════════════

Config = {}

-- ── General ──────────────────────────────────────────────────────────────
Config.Locale    = 'en'            -- 'en' | 'pt' | 'fr' | 'es' | 'pl'
Config.Framework = 'auto'          -- 'auto' | 'esx' | 'qbcore' | 'qbox' | 'standalone'
Config.Debug     = false

-- ── Command / keys ───────────────────────────────────────────────────────
Config.Command      = 'handlingeditor'  -- /handlingeditor while seated in a vehicle
Config.CommandAlias = 'handling'        -- second command, set false to disable
Config.ResetCommand = 'resetsettings'   -- restores the INTERFACE settings (theme,
                                        -- interface size, layout, auto-edit) to
                                        -- the script defaults. Escape hatch for
                                        -- when a chosen interface size is too big
                                        -- to reach the Settings panel again.
                                        -- Works in chat or the F8 console.
                                        -- Set to false to disable.
Config.RefocusKey   = 'F2'              -- while in Drive Mode, press this to get the mouse back
                                        -- (players can rebind in GTA Settings > Key Bindings > FiveM)

-- ════════════════════════════════════════════════════════════════════════
--  WHO CAN OPEN THE EDITOR
--
--  The gate is a UNION (OR) of independent sources — ANY one of them saying
--  yes grants access. It is ALWAYS re-validated server-side on every single
--  action; the client is never trusted.
--
--  ── Quickstart (the only two lines most servers need) ──────────────────
--    add_ace group.admin oxlyn.handling.admin allow
--    add_principal identifier.license:PUT_YOUR_LICENSE_HERE group.admin
--
--  ⚠ An `add_ace` written in server.cfg only takes effect on a full SERVER
--    start — restarting the resource is NOT enough. To apply it right now,
--    paste both lines straight into the server console.
--  ⚠ The `license:` prefix is written ONCE.
--    `identifier.license:license:c14af5…` matches nobody.
--
--  If you already run txAdmin or any framework that puts your admins in
--  `group.admin`, you do not even need the first line: the gate also tests
--  group.<g> / qbcore.<g> / qbx.<g> / esx.<g> for every group listed below.
--
--  Stuck? Run  /handlingaccess <serverId>  in the server console (or in chat
--  as an admin). It prints every source it consulted, the verdict of each
--  one, and the exact add_ace / add_principal lines for that player.
-- ════════════════════════════════════════════════════════════════════════
Config.Admin = {
    -- true = ANYONE can open the editor. Testing only — never in production.
    everyone = false,

    -- Which sources are consulted. Remove one to switch it off entirely.
    -- Omitting this key (older configs) means "all of them".
    methods = { 'ace', 'group', 'job', 'identifier' },

    -- 1) ACE permissions. `oxlyn.handling` is kept for older installs.
    --    NOTE: the bare `command` ace is deliberately NOT here any more — it
    --    handed the editor to anyone with generic txAdmin command rights.
    --    Add it back only if that is really what you want.
    aces = { 'oxlyn.handling.admin', 'oxlyn.handling' },

    -- Also test group.<g> / qbcore.<g> / qbx.<g> / esx.<g> for every group
    -- below. This is what makes txAdmin and a plain `add_principal` work on
    -- any framework. Set false to require the explicit aces above only.
    groupAces = true,

    -- 2) Framework groups: ESX getGroup(), QBCore / Qbox HasPermission().
    groups = { 'admin', 'superadmin', 'god' },

    -- 3) Jobs: { jobname = minimumGrade }. A plain list { 'mechanic' } also
    --    works and means grade 0. Empty = off.
    jobs = {
        -- mechanic = 4,
    },
    jobOnDuty = false,   -- true = the job only counts while ON duty (QB/Qbox)

    -- 4) Identifier allow-list. The emergency path: depends on no framework,
    --    no ace, nothing. license: / steam: / discord: / fivem: all work.
    identifiers = {
        -- 'license:c14af5e0f1e0d0c9b8a7…',
    },

    -- Server console (src 0) may always run the commands.
    allowConsole = true,

    -- Override hook. Return true/false to decide, nil to fall through to the
    -- sources above. The right place for a custom integration — never patch
    -- the core. (You can also define OxlynHandlingHooks.IsAdmin elsewhere.)
    check = nil,
    -- check = function(src)
    --     if exports['my_perms']:isStaff(src) then return true end
    --     return nil   -- nil = "no opinion", keep checking the rest
    -- end,

    -- Print every allow/deny decision to the server console.
    debug = false,
}

-- Permission diagnostic command. Set to false to remove it.
Config.AccessCommand = 'handlingaccess'   -- /handlingaccess <serverId>

-- ── Live sync ────────────────────────────────────────────────────────────
Config.ScanInterval  = 1500  -- ms between vehicle scans that auto-apply saved tunes
Config.Telemetry     = true  -- live speed / RPM / gear strip while the editor is open
Config.SpeedUnit     = 'kmh' -- 'kmh' | 'mph'
Config.RespawnOnSave = true  -- seamlessly recreate the edited vehicle after Save so
                             -- creation-cached fields (drive force, gears…) apply
                             -- instantly (same spot/look/seat; skipped if another
                             -- player is on board)

-- ════════════════════════════════════════════════════════════════════════
--  BUILT-IN PRESETS
--  Applied on top of the model's STOCK values (deterministic — applying a
--  preset twice gives the same result). Admins can also snapshot their own
--  presets in-game; those are stored server-side and shown to every admin.
--
--    mode: mul = stock × v   •   set = v (display units!)   •   add = stock + v
--  Display units = what the UI shows (fSteeringLock in degrees, etc.)
-- ════════════════════════════════════════════════════════════════════════
Config.Presets = {
    {
        id = 'racing', icon = 'flag',
        label = 'locale:preset_racing', desc = 'locale:preset_racing_desc',
        fields = {
            fInitialDriveForce      = { mode = 'mul', v = 1.25 },
            fInitialDriveMaxFlatVel = { mode = 'mul', v = 1.10 },
            fBrakeForce             = { mode = 'mul', v = 1.35 },
            fTractionCurveMax       = { mode = 'mul', v = 1.15 },
            fTractionCurveMin       = { mode = 'mul', v = 1.12 },
            fSuspensionForce        = { mode = 'mul', v = 1.20 },
            fSuspensionCompDamp     = { mode = 'mul', v = 1.15 },
            fSuspensionReboundDamp  = { mode = 'mul', v = 1.15 },
            fAntiRollBarForce       = { mode = 'mul', v = 1.25 },
            fSuspensionRaise        = { mode = 'add', v = -0.03 },
            fInitialDragCoeff       = { mode = 'mul', v = 0.90 },
        },
    },
    {
        id = 'drift', icon = 'drift',
        label = 'locale:preset_drift', desc = 'locale:preset_drift_desc',
        fields = {
            fTractionCurveMax        = { mode = 'set', v = 2.05 },
            fTractionCurveMin        = { mode = 'set', v = 1.65 },
            fLowSpeedTractionLossMult= { mode = 'set', v = 0.20 },
            fSteeringLock            = { mode = 'set', v = 47.0 },  -- degrees
            fTractionBiasFront       = { mode = 'set', v = 0.52 },
            fDriveBiasFront          = { mode = 'set', v = 0.0 },   -- full RWD
            fInitialDriveForce       = { mode = 'mul', v = 1.15 },
            fCamberStiffnesss        = { mode = 'set', v = 0.15 },
            fSuspensionForce         = { mode = 'mul', v = 1.10 },
        },
    },
    {
        id = 'offroad', icon = 'mountain',
        label = 'locale:preset_offroad', desc = 'locale:preset_offroad_desc',
        fields = {
            fSuspensionRaise         = { mode = 'add', v = 0.06 },
            fSuspensionUpperLimit    = { mode = 'add', v = 0.03 },
            fSuspensionCompDamp      = { mode = 'mul', v = 0.80 },
            fSuspensionReboundDamp   = { mode = 'mul', v = 0.80 },
            fLowSpeedTractionLossMult= { mode = 'set', v = 0.40 },
            fTractionLossMult        = { mode = 'set', v = 0.80 },
            fAntiRollBarForce        = { mode = 'mul', v = 0.70 },
            fBrakeBiasFront          = { mode = 'set', v = 0.45 },
        },
    },
    {
        id = 'drag', icon = 'bolt',
        label = 'locale:preset_drag', desc = 'locale:preset_drag_desc',
        fields = {
            fInitialDriveForce      = { mode = 'mul', v = 1.50 },
            nInitialDriveGears      = { mode = 'set', v = 6 },
            fDriveBiasFront         = { mode = 'set', v = 0.0 },
            fInitialDriveMaxFlatVel = { mode = 'mul', v = 1.25 },
            fBrakeForce             = { mode = 'mul', v = 1.10 },
            fTractionCurveMax       = { mode = 'mul', v = 1.20 },
            fInitialDragCoeff       = { mode = 'mul', v = 0.75 },
            fSteeringLock           = { mode = 'set', v = 32.0 },
        },
    },
    {
        id = 'grip', icon = 'grip',
        label = 'locale:preset_grip', desc = 'locale:preset_grip_desc',
        fields = {
            fTractionCurveMax        = { mode = 'set', v = 3.10 },
            fTractionCurveMin        = { mode = 'set', v = 2.50 },
            fTractionSpringDeltaMax  = { mode = 'set', v = 0.12 },
            fLowSpeedTractionLossMult= { mode = 'set', v = 0.60 },
            fCamberStiffnesss        = { mode = 'set', v = 0.40 },
        },
    },
    {
        id = 'heavy', icon = 'shield',
        label = 'locale:preset_heavy', desc = 'locale:preset_heavy_desc',
        fields = {
            fMass                  = { mode = 'mul', v = 1.80 },
            fCollisionDamageMult   = { mode = 'mul', v = 0.35 },
            fDeformationDamageMult = { mode = 'mul', v = 0.40 },
            fEngineDamageMult      = { mode = 'mul', v = 0.60 },
            fBrakeForce            = { mode = 'mul', v = 1.15 },
            fSuspensionForce       = { mode = 'mul', v = 1.30 },
        },
    },
    {
        id = 'realistic', icon = 'gauge',
        label = 'locale:preset_realistic', desc = 'locale:preset_realistic_desc',
        fields = {
            fInitialDriveForce     = { mode = 'mul', v = 0.92 },
            fBrakeForce            = { mode = 'mul', v = 0.85 },
            fTractionCurveMax      = { mode = 'mul', v = 0.95 },
            fTractionCurveMin      = { mode = 'mul', v = 0.95 },
            fSuspensionCompDamp    = { mode = 'mul', v = 0.90 },
            fCollisionDamageMult   = { mode = 'mul', v = 1.50 },
            fDeformationDamageMult = { mode = 'mul', v = 1.40 },
            fEngineDamageMult      = { mode = 'mul', v = 1.30 },
        },
    },
    {
        id = 'tuner', icon = 'wrench',
        label = 'locale:preset_tuner', desc = 'locale:preset_tuner_desc',
        fields = {
            fInitialDriveForce     = { mode = 'mul', v = 1.15 },
            fBrakeForce            = { mode = 'mul', v = 1.15 },
            fTractionCurveMax      = { mode = 'mul', v = 1.08 },
            fSuspensionCompDamp    = { mode = 'mul', v = 1.10 },
            fSuspensionReboundDamp = { mode = 'mul', v = 1.10 },
            fSuspensionRaise       = { mode = 'add', v = -0.02 },
            fInitialDragCoeff      = { mode = 'mul', v = 0.95 },
        },
    },
    {
        id = 'rally', icon = 'mountain',
        label = 'locale:preset_rally', desc = 'locale:preset_rally_desc',
        fields = {
            fDriveBiasFront          = { mode = 'set', v = 0.5 },   -- AWD
            fInitialDriveForce       = { mode = 'mul', v = 1.10 },
            fSuspensionRaise         = { mode = 'add', v = 0.04 },
            fSuspensionCompDamp      = { mode = 'mul', v = 0.75 },
            fSuspensionReboundDamp   = { mode = 'mul', v = 0.80 },
            fTractionLossMult        = { mode = 'set', v = 0.60 },
            fLowSpeedTractionLossMult= { mode = 'set', v = 0.50 },
            fBrakeBiasFront          = { mode = 'set', v = 0.48 },
            fHandBrakeForce          = { mode = 'mul', v = 1.30 },
        },
    },
    {
        id = 'timeattack', icon = 'stopwatch',
        label = 'locale:preset_timeattack', desc = 'locale:preset_timeattack_desc',
        fields = {
            fDownforceModifier = { mode = 'add', v = 60.0 },
            fTractionCurveMax  = { mode = 'mul', v = 1.25 },
            fTractionCurveMin  = { mode = 'mul', v = 1.20 },
            fBrakeForce        = { mode = 'mul', v = 1.40 },
            fSuspensionForce   = { mode = 'mul', v = 1.35 },
            fAntiRollBarForce  = { mode = 'mul', v = 1.40 },
            fSuspensionRaise   = { mode = 'add', v = -0.04 },
            fSteeringLock      = { mode = 'set', v = 40.0 },
        },
    },
    {
        id = 'lowrider', icon = 'cardown',
        label = 'locale:preset_lowrider', desc = 'locale:preset_lowrider_desc',
        fields = {
            fSuspensionRaise       = { mode = 'add', v = -0.08 },
            fSuspensionForce       = { mode = 'mul', v = 0.80 },
            fSuspensionCompDamp    = { mode = 'mul', v = 0.55 },
            fSuspensionReboundDamp = { mode = 'mul', v = 0.50 },
            fMass                  = { mode = 'mul', v = 1.05 },
        },
    },
    {
        id = 'muscle', icon = 'engine',
        label = 'locale:preset_muscle', desc = 'locale:preset_muscle_desc',
        fields = {
            fInitialDriveForce       = { mode = 'mul', v = 1.30 },
            fDriveBiasFront          = { mode = 'set', v = 0.0 },   -- full RWD
            fLowSpeedTractionLossMult= { mode = 'set', v = 2.20 },
            fTractionCurveMax        = { mode = 'mul', v = 0.95 },
            fTractionBiasFront       = { mode = 'set', v = 0.48 },
            fBrakeForce              = { mode = 'mul', v = 1.05 },
        },
    },
}

