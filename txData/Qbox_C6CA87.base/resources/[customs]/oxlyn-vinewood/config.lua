

--[[
    ============================================================================
     OXLYN · Advanced Vinewood Editor — configuration
    ============================================================================
     Every option below is safe to change. After editing, restart the resource
     (restart oxlyn-vinewood). Options marked [FULL RESTART] need the whole
     server restarted and FiveM closed/reopened on the client.

     Sections
       1. Framework & permissions      6. Freecam & camera
       2. Command & language           7. Rendering & streaming
       3. Keyboard shortcuts           8. Images & uploads
       4. Interface defaults           9. Original sign
       5. Scene limits & area         10. Default scene
    ============================================================================
]]
Config = {}

-- ============================================================================
--  1. FRAMEWORK & PERMISSIONS
-- ============================================================================

-- 'auto'       detect at start: qbx_core → Qbox, qb-core → QBCore, es_extended → ESX, else standalone
-- 'esx' | 'qbcore' | 'qbox' | 'standalone'   force one
Config.Framework = 'auto'

Config.Permissions = {
    -- ACE permission checked on EVERY framework (and the only check when standalone).
    -- Grant it in server.cfg:   add_ace group.admin oxlyn.vinewood allow
    Ace = 'oxlyn.vinewood',

    -- Framework groups that may open the editor. Use { name = true } entries.
    --   ESX     → xPlayer.getGroup()
    --   QBCore  → QBCore.Functions.HasPermission(source, group)
    --   Qbox    → ACE group 'group.<name>' (and qbx_core HasPermission when available)
    Groups = {
        esx    = { admin = true, superadmin = true },
        qbcore = { admin = true, god = true },
        qbox   = { admin = true, god = true },
    },

    -- Optional: your own check. Return true to allow. Runs first; any error is
    -- printed to the server console and the other checks still run.
    -- Custom = function(source)
    --     return exports['my_staff']:IsStaff(source)
    -- end,
    Custom = nil,
}

-- ============================================================================
--  2. COMMAND & LANGUAGE
-- ============================================================================

-- Chat command that opens the editor. '/vinewood showcase' runs the automatic
-- demonstration (same permission).
Config.Command = 'vinewood'

-- Default language of the editor and of every message from the resource.
-- Shipped: en, pt (Portugal), br (Brazil), es, fr, de, it, nl, pl, tr, ru, cs, sv, ro.
-- Each player can pick another language in the editor (Settings tab); that
-- choice is remembered on their computer. Server replies always use this value.
Config.Locale = 'en'

-- ============================================================================
--  3. KEYBOARD SHORTCUTS  (inside the editor only)
-- ============================================================================
-- Values are browser key codes (KeyboardEvent.code): 'KeyQ', 'Tab', 'KeyH', 'F2', 'Digit1' ...
-- While the editor is open the game never receives the keyboard, so these keys
-- cannot trigger other resources (inventory on Tab, phone, hotbar ...).
Config.Keys = {
    freecam      = 'KeyQ',  -- switch between cursor and freecam
    toggleEditor = 'Tab',   -- hide / show the editor dock (slides under the keybind bar)
    hideUi       = 'KeyH',  -- hide the whole interface (for screenshots)
    focus        = 'KeyF',  -- frame the selected layer or letter
    nudgeStep    = 0.1,     -- arrow-key nudge in metres (Shift ×10, Alt ÷10)
    nudgeFast    = 1.0,     -- preset offered in the nudge step menu
    nudgeSlow    = 0.01,    -- preset offered in the nudge step menu
    rotateStep   = 5,       -- degrees per Ctrl + ←/→
}

-- ============================================================================
--  4. INTERFACE DEFAULTS  (each player can change these in the Settings tab)
-- ============================================================================
Config.UI = {
    Scale     = 'auto',  -- 'auto' follows the screen height; or 1, 1.15, 1.3, 1.5, 1.75, 2
    Hints     = true,    -- keybind bar above the editor
    DockHeight = 440,    -- editor height in pixels (300 - 560)
    Grain     = true,    -- film grain and soft shadows (false = lighter "performance" look)
}

-- Accent colour of the interface and the dark surface behind the panels (#RRGGBB).
Config.Theme = { accent = '#f2f3f5', surface = '#141518' }

-- ============================================================================
--  5. SCENE LIMITS & EDITABLE AREA
-- ============================================================================

-- Centre of the editable area and of the "Center at sign anchor" tool.
Config.Anchor = { x = 710.0, y = 1198.0, z = 350.0 }

Config.Limits = {
    MaxLayers          = 8,       -- text + image layers in one scene
    MaxSolidLayers     = 4,       -- of those, 3D-letter layers (each owns a colour texture)
    MaxSolidCharacters = 48,      -- characters per 3D-letter layer
    MaxSolidGlyphs     = 96,      -- physical letters in the whole scene
    MaxTextLength      = 96,      -- characters per flat-text layer
    MaxUrlLength       = 512,
    MaxPayloadBytes    = 24000,   -- largest scene the server accepts on Publish
    AreaRadius         = 450.0,   -- layers must stay within this distance of Config.Anchor (metres)
    MinSize            = 0.2,     -- smallest layer width/height (metres)
    MaxSize            = 240.0,   -- largest layer width/height (metres)
}

-- ============================================================================
--  6. FREECAM & CAMERA
-- ============================================================================
Config.Freecam = {
    Position       = { x = 670.0, y = 1010.0, z = 385.0 },  -- where the editor camera starts ("Home" view)
    Rotation       = { x = -14.0, y = 0.0, z = -16.0 },
    Fov            = 55.0,     -- default field of view
    Speed          = 18.0,     -- metres per second
    FastMultiplier = 4.0,      -- while Shift is held
    SlowMultiplier = 0.2,      -- while Alt is held
    MaxDistance    = 800.0,    -- the camera cannot leave this radius around Config.Anchor
}

Config.Camera = {
    Interpolation    = 650,    -- ms for smooth transitions between views and bookmarks (0 = instant)
    Sensitivity      = 1.0,    -- freecam mouse look
    OrbitSensitivity = 1.0,    -- right-button orbit in cursor mode
    Smooth           = true,   -- initial state of the "Smooth transitions" switch
    InvertY          = false,  -- initial state of the "Invert vertical look" switch
    -- Clock used by the Camera tab time-of-day preview (hour, minute). Only the
    -- editing admin sees it. Sunset must be at or after Config.Solid.NightStart
    -- so illuminated letters switch on in the preview.
    TimePreview = { day = { 13, 0 }, sunset = { 19, 40 }, night = { 0, 30 } },
}

-- ============================================================================
--  7. RENDERING & STREAMING
-- ============================================================================

-- Flat text and images: drawn up to this distance, fading out over FadeDistance.
Config.DrawDistance = 2000.0
Config.FadeDistance = 150.0
Config.StreamInterval = 750      -- ms between visibility checks
Config.DuiReleaseDelay = 15000   -- ms out of range before the texture page is emptied

-- Physical 3D letters.
Config.Solid = {
    StreamInterval      = 750,     -- ms between checks for letters to create/remove
    ReleaseDelay        = 12000,   -- ms out of range before letter models are released
    LoadTimeout         = 10000,   -- ms to wait for a model before skipping it
    SpawnBudget         = 6,       -- letters created per check (spreads the work over frames)
    NightStart          = 19,      -- 'At night' lighting: letters glow from this hour...
    NightEnd            = 7,       -- ...until this hour
    TextureDictionary   = 'oxvw_materials',  -- do not change
    -- GTA may rebuild scaled matrices after a model streams in. Letters are
    -- re-checked at this interval and only corrected when they actually moved.
    MatrixCheckInterval = 1000,
}

-- ============================================================================
--  8. IMAGES & UPLOADS
-- ============================================================================

-- Allow image layers that point to an https:// URL. Local files in
-- web/dist/images and images uploaded from the editor always work.
Config.AllowRemoteImages = true

-- Restrict remote images to these hosts. Empty = any public HTTPS host.
-- Example: { ['cdn.example.com'] = true, ['i.imgur.com'] = true }
Config.ImageHosts = {}

-- Images imported from the editor (PNG / JPG / WebP, normalised to PNG).
Config.Uploads = {
    MaxBytes       = 786432,   -- stored PNG size limit (768 KiB)
    MaxDimension   = 2048,     -- longest side in pixels after normalising
    MaxStored      = 128,      -- files kept in data/uploads
    BytesPerSecond = 131072,   -- upload bandwidth per transfer (keeps the connection smooth)
}

-- ============================================================================
--  9. ORIGINAL SIGN
-- ============================================================================
-- "Hide original sign" in the editor hides these nearby models. The distant
-- LOD/SLOD letters are removed by the map files in stream/ while the resource
-- runs (see README → Original sign). Never add ch2_lod3_* here: those models
-- also contain terrain.
Config.OriginalSign = {
    Center = { x = 723.091, y = 1193.019, z = 336.914 }, Radius = 200.0,
    Models = {
        'ch2_03_sign', 'ch2_03_signdcal', 'ch2_03_sign_lod', 'ch2_03_sign_slod',
        'ch2_03_emis_sign_hd', 'ch2_03_emis_sign_lod', 'ch2_03_emis_sign_slod',
        'ch2_03_signedge01', 'ch2_03_signedge02', 'ch2_03_signedge03', 'ch2_03_signedge04',
        'ch2_03_signedge05', 'ch2_03_signedge06', 'ch2_03_signedge07', 'ch2_03_signedge08',
        'ch2_03_signstructure', 'ch2_03_signstructure_lod', 'ch2_03_signstructure_b',
        'ch2_03_signstructure_b2', 'ch2_03_signstructure_b3', 'ch2_03_signstructure_b4',
        'ch2_03_signstructure_b5', 'ch2_03_signstructure_b6', 'ch2_03_signstructure_b7', 'ch2_03_signstructure_b8',
        'ch2_03_signframinga', 'ch2_03_signframingb', 'ch2_03_signframingc', 'ch2_03_signframingd',
        'ch2_03_signframinge', 'ch2_03_signframingf', 'ch2_03_signframingg',
        'ch2_03_signjoins01', 'ch2_03_signjoins02', 'ch2_03_signjoins03', 'ch2_03_signjoins04',
        'ch2_03_signjoins05', 'ch2_03_signjoins06', 'ch2_03_signjoins07', 'ch2_03_signjoins08',
        -- The climbable ladders are separate meshes; left visible they overlap shorter replacement letters.
        'ch2_03_ladder_mesh_00', 'ch2_03_ladder_mesh_01', 'ch2_03_ladder_mesh_02',
        'ch2_03_ladder_mesh_03', 'ch2_03_ladder_mesh_04', 'ch2_03_ladder_mesh_05',
        'ch2_03_ladder_mesh_06', 'ch2_03_ladder_mesh_07', 'ch2_03_ladder_mesh_08',
        'ch2_03_ladder_mesh_09', 'ch2_03_ladder_mesh_10', 'ch2_03_ladder_mesh_11',
        'ch2_03_ladder_mesh_12', 'ch2_03_ladder_mesh_13', 'ch2_03_ladder_mesh_14',
        'prop_vinewood_sign_01', -- rightmost upright with four rusty crossbars
    },
}

-- ============================================================================
--  10. DEFAULT SCENE
-- ============================================================================
-- Used until an admin publishes for the first time (the published scene is
-- saved in data/scene.json). Empty by default: open the editor, press
-- "Replace VINEWOOD" or add layers, then Publish.
Config.DefaultScene = { schemaVersion = 1, hideOriginal = false, layers = {} }

