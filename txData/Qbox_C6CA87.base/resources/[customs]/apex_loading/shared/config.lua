--[[ ═══════════════════════════════════════════════════════════════════════

     █████╗ ██████╗ ███████╗██╗  ██╗    ██╗      ██████╗  █████╗ ██████╗
    ██╔══██╗██╔══██╗██╔════╝╚██╗██╔╝    ██║     ██╔═══██╗██╔══██╗██╔══██╗
    ███████║██████╔╝█████╗   ╚███╔╝     ██║     ██║   ██║███████║██║  ██║
    ██╔══██║██╔═══╝ ██╔══╝   ██╔██╗     ██║     ██║   ██║██╔══██║██║  ██║
    ██║  ██║██║     ███████╗██╔╝ ██╗    ███████╗╚██████╔╝██║  ██║██████╔╝
    ╚═╝  ╚═╝╚═╝     ╚══════╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝ ╚═╝  ╚═╝╚═════╝

    APEX LOADING: the loading screen your server builds itself
    Admins design it in game: /loadingcreator

    ▸ 1. Core             framework · locale
    ▸ 2. Access           who can open the creator
    ▸ 3. Commands         creator command
    ▸ 4. Exit             how players enter the city
    ▸ 5. AI assistant     provider · key · limits
    ▸ 6. Handover         what data reaches the loading screen

═══════════════════════════════════════════════════════════════════════ ]]

Config = {}

-- ═══ 1. CORE ═══════════════════════════════════════════════════════════════

Config.Debug = false

-- Only used for job/group based access checks. The loading screen itself is
-- completely standalone and works with no framework at all.
--   'auto'  → detect es_extended / qbx_core / qb-core automatically (recommended)
--   'esx' · 'qb' · 'qbx' · 'standalone'  → force one
Config.Framework = 'auto'

-- 'en' or 'pt' (shared/locales.lua: add your own language there)
Config.Locale = 'en'

-- ═══ 2. ACCESS ═════════════════════════════════════════════════════════════
-- Who can open the creator and publish the loading screen. Five additive
-- methods, always checked server-side; the first enabled method that says
-- yes wins. This is a server-wide tool, so the default is admin-only.

Config.Access = {
    creator = {
        everyone = { enabled = false },
        ace = { enabled = true, permissions = { 'apex.loading.admin' }, acceptOwnerAces = true,
                ownerAces = { 'command', 'txadmin.everything', 'group.admin' } },
        groups = { enabled = false, list = { 'owner', 'god', 'superadmin', 'admin' } },
        jobs = { enabled = false, list = {} },          -- e.g. { police = 0 }
        identifiers = { enabled = false, list = {} },   -- e.g. { 'license:...' }
    },
}

-- ═══ 3. COMMANDS ═══════════════════════════════════════════════════════════

Config.Creator = {
    command = 'loadingcreator',
    aliasCommand = 'loadingscreen',   -- false to disable
}

-- ═══ 4. EXIT ═══════════════════════════════════════════════════════════════
-- The exit mode itself (Press ENTER vs automatic) is part of the DESIGN and
-- is set in the creator. These are the safety rails around it.

Config.Exit = {
    -- hard ceiling: if the page never reports (broken media URL, etc.) the
    -- loading screen is force-closed this many seconds after the session
    -- starts, so nobody ever gets stuck behind it
    maxSecondsAfterSpawn = 30,
}

-- ═══ 5. AI ASSISTANT ═══════════════════════════════════════════════════════
-- The creator's AI panel ("make it cyberpunk purple with news on the left").
-- Bring your own key; it lives on the SERVER and never reaches any client.
-- The key can also come from a convar, which always wins:
--     set apex_loading_ai_key "sk-..."

Config.AI = {
    enabled = true,
    provider = 'gemini',      -- 'gemini' · 'groq' (free tier) · 'openai' · 'anthropic' · 'custom'

    -- ⚠ A key written here lives in a plain file. It is fine on your own
    -- server, but the safer place is the convar, which always wins:
    --     set apex_loading_ai_key "..."
    apiKey = '',

    model = '',               -- empty = a sensible default per provider
    maxPerMinute = 6,         -- per-admin rate limit
    timeout = 25000,
    -- provider = 'custom' → an OpenAI-compatible /chat/completions endpoint:
    customUrl = '',
}

-- ═══ 6. HANDOVER ═══════════════════════════════════════════════════════════
-- Data injected into the loading screen for the connecting player.

Config.Handover = {
    playerName = true,        -- for the greeting widget
    playerCount = true,       -- for the server stats widget
    serverName = true,        -- from sv_hostname (cleaned of colour codes)
}
