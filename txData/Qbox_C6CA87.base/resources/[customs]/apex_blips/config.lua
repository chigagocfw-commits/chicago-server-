--[[
    Apex Scriptz — apex_blips "Blip Studio"
    ============================================================================
    CONFIG — this is the file you are meant to read and edit.

    What the resource does: an in-game studio (and an export API) for custom
    map blips. A blip's icon can be a native GTA sprite, ANY uploaded image,
    or a generated emoji/text badge. Image icons are rendered through runtime
    textures that temporarily replace never-used DLC sprites — nothing is
    streamed, nothing needs a restart, and the vanilla sprite comes back the
    moment the image slot is released.

    Every value the server receives is clamped and sanitised in server/main.lua
    before it is stored or relayed, so a typo here can never crash the
    resource — it just falls back to the safe value.
]]

Config = {}

--------------------------------------------------------------------------------
-- 1. BASICS
--------------------------------------------------------------------------------

-- Prints a lot of noise to F8 / the server console. Leave off in production.
Config.debug = false

-- Interface + in-game language. English is the primary language; 'pt' is the
-- translation. To add one: copy locales/en.lua to locales/xx.lua, translate it,
-- set it here. locales/*.lua is a glob in fxmanifest.lua, so nothing else needs
-- to change. Every user-facing string in Lua AND in the studio comes from there.
Config.locale = 'en'

--------------------------------------------------------------------------------
-- 2. COMMANDS
--------------------------------------------------------------------------------

Config.commands = {
    -- Opens the Blip Studio. Requires edit permission (see Config.perms).
    studio = 'blipstudio',

    -- Any player: toggles the custom blips on/off for THEMSELVES only.
    -- Useful for screenshots and for players who want a clean map.
    toggle = 'myblips',
}

-- Optional key mapping for the studio command. '' = no key mapping.
-- Players can always rebind it afterwards in Settings > Key Bindings > FiveM.
-- Examples: 'F7', 'F9', 'HOME', 'DELETE'
Config.keybind = ''

--------------------------------------------------------------------------------
-- 3. PERMISSIONS — who may create / edit / delete blips
--------------------------------------------------------------------------------
-- Checked on the SERVER on every single write, not just when the studio opens,
-- so there is nothing to bypass client-side. A player passes if ANY of the
-- checks below succeeds.
--
-- There is deliberately NO dedicated ace permission (no `apex.blips`).
-- Access is by GROUP, by JOB, or open to everyone. That keeps the resource on
-- the permission list your server already maintains instead of adding a second,
-- parallel one that is easy to forget about.
--
-- >>> THIS BUILD SHIPS WITH `everyone = true` (see the boxed note below). <<<
-- >>> Nothing is gated until you set it to false. <<<
--------------------------------------------------------------------------------

Config.perms = {
    -- 1) Framework groups. ESX: xPlayer.getGroup(). QB/QBX: the permission
    --    list. On a server with no framework at all, a matching
    --    `group.<name>` principal is honoured too, so
    --      add_principal identifier.license:xxxx group.admin
    --    still works standalone.
    --    Add 'superadmin', 'mod', … here if you want more groups in.
    groups = { 'admin' },

    -- 2) Framework jobs. ESX reads xPlayer.job.name, QB/QBX read
    --    Player.PlayerData.job.name. Grades are NOT checked here — put a
    --    grade-gated job in its own name if you need that granularity.
    --    Example: jobs = { 'police', 'realestate' }
    jobs = {},

    -- ╔════════════════════════════════════════════════════════════════════════╗
    -- ║  READ ME — THE ONLY LINE THAT DECIDES WHO CAN EDIT BLIPS               ║
    -- ║                                                                        ║
    -- ║      everyone = true   <-- SHIPPED THIS WAY ON PURPOSE                 ║
    -- ║                                                                        ║
    -- ║  While this is `true`, EVERY player on the server can open the studio  ║
    -- ║  and create, edit and DELETE every blip — the groups and jobs lists    ║
    -- ║  above are not even looked at.                                         ║
    -- ║                                                                        ║
    -- ║  To lock the studio down: change the line below to `everyone = false`, ║
    -- ║  then restart the resource. Access falls back to Config.perms.groups   ║
    -- ║  (admin by default) and Config.perms.jobs.                             ║
    -- ║                                                                        ║
    -- ║  The server prints a yellow reminder on every start while it is true,  ║
    -- ║  so this can never be forgotten by accident.                           ║
    -- ╚════════════════════════════════════════════════════════════════════════╝
    everyone = false,
}

--------------------------------------------------------------------------------
-- 4. IMAGES — the uploaded-icon library
--------------------------------------------------------------------------------

Config.images = {
    -- Side, in pixels, of the square texture an image icon is baked into.
    -- 128 is crisp on both the minimap and the zoomed pause map. 64 halves
    -- the work, 256 is overkill (blips never render that large). The studio
    -- downsizes every upload to this size BEFORE it is stored, so this also
    -- caps what travels over the network. Allowed: 64, 96, 128, 256.
    textureSize = 128,

    -- Hard cap, in KB, on one stored image (as a data: URL). Uploads are
    -- already downsized client-side, so a normal icon lands well under this.
    maxKB = 192,

    -- How many images the library may hold in total. This is the LIBRARY
    -- cap — how many can be on screen at once is Config.engine.slots below.
    maxCount = 96,
}

--------------------------------------------------------------------------------
-- 5. ENGINE — how an image becomes a real blip (read before editing)
--------------------------------------------------------------------------------
-- GTA draws every blip from ATLAS SHEETS inside the `minimap` texture
-- dictionary (individual radar_* textures do not exist). So the engine:
--
--   1. streams a known minimap.gfx + minimap.ytd pair (stream/ folder, from
--      the menkzy/fivem-blips project) — that pins the sheet layout this
--      resource was built against, on every game build, and as a bonus your
--      server gets the newest GTA Online blips.
--      >>> Streamed .gfx/.ytd only register after a FULL server restart. <<<
--   2. owns ONE DUI page that re-renders the whole blips_texturesheet_ng_2
--      sheet: vanilla art + your images painted into the cells of the
--      hijacked sprites below,
--   3. swaps that sheet in with AddReplaceTexture. Every OTHER blip keeps
--      its vanilla pixels — the compositor paints them from the extracted
--      sheet (html/img/sheet_ng2.png).
--
-- The swap is LOCAL to each game session and fully undone the moment the
-- last image blip disappears.
--
-- Many blips can share one image: 40 pizzerias with the same logo cost ONE
-- cell. The list below is therefore "how many DIFFERENT images can be
-- visible at the same time".
--
-- ⚠ If another resource on your server streams its own minimap.ytd or
--   minimap.gfx, remove it or remove ours — two streams of the same asset
--   fight each other and only one wins.
--------------------------------------------------------------------------------

Config.engine = {
    -- The texture dictionary that holds every radar sprite. Never changes on
    -- vanilla GTA V; only here so a future game update cannot strand you.
    dict = 'minimap',

    -- ── Payload delivery timings ────────────────────────────────────────────
    -- IsDuiAvailable turns true when the SURFACE exists, which can happen
    -- BEFORE the page's script is listening. A payload sent in that window is
    -- lost, so the engine re-sends (the page ignores identical payloads):
    resendMs    = 6000,   -- fast lane: keep re-sending for this long after a change
    resendEvery = 400,    -- ...at this interval
    heartbeatMs = 2500,   -- then forever at this interval (self-heals CEF suspends)

    -- After a texture swap, flip the bigmap for one frame so blips already on
    -- screen re-request the texture and show the new picture immediately.
    -- Costs a barely-visible minimap blink; set false if you'd rather wait
    -- for the radar to refresh on its own.
    radarPoke = true,

    -- The sheet the compositor re-renders. Matches the streamed minimap.ytd —
    -- do not touch unless you replaced the stream/ pair with your own AND
    -- regenerated the cells below.
    sheet = { texture = 'blips_texturesheet_ng_2', size = 1024, cell = 64 },

    -- How long (ms) after the compositor page loads before the sheet is
    -- swapped in — gives the page time to paint the vanilla art first, so
    -- the sheet's other blips never render blank.
    baseDelayMs = 1200,

    -- The hijacked sprites. Each entry is one image cell: a sprite id and
    -- that sprite's cell inside blips_texturesheet_ng_2 (coordinates were
    -- extracted from the exact minimap.gfx this resource streams — they are
    -- not guesses). Defaults: the 14 single-player smuggler waypoints, plus
    -- 27 Arena War icons — 41 cells no roleplay script uses in practice.
    --
    -- If ANOTHER resource on your server does use one of these sprites, just
    -- delete that line — the engine only ever touches sprites in this list.
    -- (Sprite 656 shares its cell with 655 in the atlas, so it is not here.)
    -- Sprite reference: https://docs.fivem.net/docs/game-references/blips/
    slots = {
        { sprite = 572, cell = { x = 576, y = 128 } },   -- radar_sm_wp1
        { sprite = 573, cell = { x = 640, y = 128 } },   -- radar_sm_wp2
        { sprite = 574, cell = { x = 704, y = 128 } },   -- radar_sm_wp3
        { sprite = 575, cell = { x = 768, y = 128 } },   -- radar_sm_wp4
        { sprite = 576, cell = { x = 832, y = 128 } },   -- radar_sm_wp5
        { sprite = 577, cell = { x = 896, y = 128 } },   -- radar_sm_wp6
        { sprite = 578, cell = { x = 960, y = 128 } },   -- radar_sm_wp7
        { sprite = 579, cell = { x = 0,   y = 192 } },   -- radar_sm_wp8
        { sprite = 580, cell = { x = 64,  y = 192 } },   -- radar_sm_wp9
        { sprite = 581, cell = { x = 128, y = 192 } },   -- radar_sm_wp10
        { sprite = 582, cell = { x = 192, y = 192 } },   -- radar_sm_wp11
        { sprite = 583, cell = { x = 256, y = 192 } },   -- radar_sm_wp12
        { sprite = 584, cell = { x = 320, y = 192 } },   -- radar_sm_wp13
        { sprite = 585, cell = { x = 384, y = 192 } },   -- radar_sm_wp14
        { sprite = 641, cell = { x = 896, y = 384 } },   -- radar_arena_series
        { sprite = 642, cell = { x = 832, y = 384 } },   -- radar_arena_premium
        { sprite = 643, cell = { x = 960, y = 384 } },   -- radar_arena_workshop
        { sprite = 645, cell = { x = 64,  y = 448 } },   -- radar_arena_turret
        { sprite = 646, cell = { x = 128, y = 448 } },   -- radar_arena_rc_car
        { sprite = 647, cell = { x = 192, y = 448 } },   -- radar_arena_rc_workshop
        { sprite = 648, cell = { x = 256, y = 448 } },   -- radar_arena_trap_fire
        { sprite = 649, cell = { x = 320, y = 448 } },   -- radar_arena_trap_flip
        { sprite = 650, cell = { x = 384, y = 448 } },   -- radar_arena_trap_sea
        { sprite = 651, cell = { x = 448, y = 448 } },   -- radar_arena_trap_turn
        { sprite = 652, cell = { x = 512, y = 448 } },   -- radar_arena_trap_pit
        { sprite = 653, cell = { x = 576, y = 448 } },   -- radar_arena_trap_mine
        { sprite = 654, cell = { x = 640, y = 448 } },   -- radar_arena_trap_bomb
        { sprite = 655, cell = { x = 768, y = 448 } },   -- radar_arena_trap_wall
        { sprite = 657, cell = { x = 832, y = 448 } },   -- radar_arena_trap_sbrd
        { sprite = 658, cell = { x = 256, y = 512 } },   -- radar_arena_bruiser
        { sprite = 659, cell = { x = 320, y = 512 } },   -- radar_arena_brutus
        { sprite = 660, cell = { x = 192, y = 512 } },   -- radar_arena_cerberus
        { sprite = 661, cell = { x = 960, y = 448 } },   -- radar_arena_deathbike
        { sprite = 662, cell = { x = 448, y = 512 } },   -- radar_arena_dominator
        { sprite = 663, cell = { x = 512, y = 512 } },   -- radar_arena_impaler
        { sprite = 664, cell = { x = 576, y = 512 } },   -- radar_arena_imperator
        { sprite = 665, cell = { x = 64,  y = 512 } },   -- radar_arena_issi
        { sprite = 666, cell = { x = 128, y = 512 } },   -- radar_arena_sasquatch
        { sprite = 667, cell = { x = 896, y = 448 } },   -- radar_arena_scarab
        { sprite = 668, cell = { x = 0,   y = 512 } },   -- radar_arena_slamvan
        { sprite = 669, cell = { x = 384, y = 512 } },   -- radar_arena_zr380
    },

    -- Sprite used when an image blip cannot get a slot (every slot is taken
    -- by a different image, or the image failed to decode). 1 = the plain
    -- white dot. The blip still works — name, zone, route, everything — it
    -- just wears this sprite until a slot frees up.
    fallbackSprite = 1,
}

--------------------------------------------------------------------------------
-- 6. ZONES
--------------------------------------------------------------------------------

Config.zones = {
    -- How often (ms) each client checks whether it is inside a zone whose
    -- events are enabled. 500 is plenty for map zones.
    checkMs = 500,

    -- Master switch for zone enter/exit events. When false, zones still DRAW
    -- on the map but never fire events, no matter what a blip says.
    events = true,

    -- Ceilings for the editor sliders (metres).
    maxRadius = 2000.0,
    maxSide   = 4000.0,
}

--------------------------------------------------------------------------------
-- 6b. LIMITS — how far the editor is allowed to go
--------------------------------------------------------------------------------
-- ⚠ THESE ARE THE REAL CEILINGS, not a suggestion. The server clamps every
-- saved blip to them, and the studio is told what they are so a slider can
-- never promise a number the server would quietly cut back. Raise one here and
-- both ends move together; there is nothing else to edit.
--
-- The value boxes in the editor are typeable, so a number beyond the slider's
-- visible travel is reached by typing it, and the slider stretches to match.
-- The ceiling below is what stops it there.
Config.limits = {
    -- Blip size. 1.0 is the game's own default; the editor used to stop at 2.0
    -- because that was the slider's end, which is not a reason. GTA keeps
    -- scaling well past it, so the ceiling is the owner's taste now.
    -- ⚠ Above ~4 a blip covers a noticeable part of the minimap. That is a
    -- choice, not a bug, which is exactly why it lives in the config.
    scaleMin = 0.1,
    scaleMax = 10.0,

    -- Opacity, 0-255 in the engine. 20 is the floor because anything under it
    -- is invisible and reads as a broken blip rather than a faint one.
    alphaMin = 20,
    alphaMax = 255,

    -- Zone opacity. The engine takes 0-255 here too; the old 200 was another
    -- slider end that had become a rule.
    zoneAlphaMin = 10,
    zoneAlphaMax = 255,
}

--------------------------------------------------------------------------------
-- 7. NEW-BLIP DEFAULTS — what the Create form starts from
--------------------------------------------------------------------------------

Config.defaults = {
    sprite     = 1,      -- plain white dot
    colour     = 0,      -- 0 = untinted white (see the palette in the studio)
    scale      = 0.9,
    alpha      = 255,
    shortRange = true,   -- only shows on the minimap when you are close
    category   = 1,
    display    = 2,      -- minimap + pause map
    zoneColour = 1,      -- red
    zoneAlpha  = 80,
}

--------------------------------------------------------------------------------
-- 8. SYNC — network behaviour (rarely needs touching)
--------------------------------------------------------------------------------

Config.sync = {
    -- Bandwidth for the latent events that carry blips + images to a client
    -- (bits per second). 2 Mbit moves a full 40-image library in ~2 s without
    -- starving the rest of the connection.
    bps = 2000000,

    -- Client boot: how long to keep asking the server for the first payload.
    -- (Starts at retryMinMs, doubles to retryMaxMs, gives up after retryMax.)
    retryMinMs = 500,
    retryMaxMs = 5000,
    retryMax   = 20,
}
