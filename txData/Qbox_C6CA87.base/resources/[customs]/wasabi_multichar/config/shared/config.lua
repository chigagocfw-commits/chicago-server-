-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

Config = {}
Config.BuildRevision = "c75e2cbced08e99c33646c483421cebc"

-- Enables verbose debug logging via lib.print.debug across the resource.
-- When true, the debug module raises ox_lib's print level to "debug" for this
-- resource so informational logs surface in the console (server + client).
Config.Debug = false

-- Maximum character slots (base; VIP slots are added on top via database or command)
Config.MaxSlots = 3

-- Allow character deletion (checked on both client UI and server)
Config.AllowDeletion = true

-- Spawn options (used on both server trigger and client apply)
Config.SpawnOptions = {
    -- Default spawn coords used when no last position exists (new character or skipSpawnSelector with no saved pos)
    defaultCoords = {
        vector4(-269.4, -955.3, 31.2, 205.0),
    },

    -- If true: skip the spawn selector and spawn at the character's last saved position.
    -- Falls back to defaultCoords if no last position is stored (new character).
    skipSpawnSelector = false,

    -- If true: use a custom Spawn Selector integration (wasabi_spawn, um-spawn, qb-spawn, qb-apartments).
    -- If false: use the built-in spawn system (defaultCoords or Config.JobSpawns).
    -- To add your own custom spawn selector integration,
    -- modify bridge/spawn/server.lua (see comments there for guidance).
    useCustomSpawnSelector = true,

    -- If true: show the spawn selector on first character creation (requires useCustomSpawnSelector = true).
    spawnSelectOnFirstSpawn = false,

    -- If true: play a short synchronised scene at spawn before fading in.
    -- Skipped automatically when first-spawn customization opens (new characters).
    spawnAnimation = false,

    -- Fine-tunes the synchronised spawn scene origin relative to the final grounded spawn position.
    -- Keep at 0.0 unless a server needs minor per-map tuning; negative values can sink the ped.
    spawnAnimationZOffset = 0.0,
}

-- Job-based spawns for built-in spawn fallback (uses cached character.job). Empty = disabled.
-- Example: ['police'] = vector4(428.0, -984.0, 30.7, 90.0)
Config.JobSpawns = {}

---@ignore
Modules.register('config', Config, true)
