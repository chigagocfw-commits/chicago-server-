--[[
    Apex Chat — Shared Config
    ────────────────────────────────────────────────────────────
    User-facing settings + Apex theme tokens. Per-player UI
    preferences and custom commands are persisted via FiveM KVP
    and are NOT stored here.
]]

Config = Config or {}

-- ═══════════════════════════════════════════════════════════
-- APEX THEME — single source of truth for chat colors.
-- ═══════════════════════════════════════════════════════════
Config.theme = {
    brand        = '#1F5EFF',
    brandDark    = '#0048F0',
    bg           = '#0A0A0B',
    bgCard       = '#1A1A1B',
    bgRaised     = '#232325',
    bgSidebar    = '#131314',
    border       = '#1F1F21',
    borderHi     = '#2A2A2D',
    text         = '#F4F4F5',
    textSub      = 'rgba(244,244,245,.55)',
    info         = '#4E9CE5',
    success      = '#34C77B',
    warning      = '#E5A93C',
    error        = '#E5564B',
}

-- Color presets exposed in the Design tab.
Config.colorPresets = {
    { id = 'violet',  hex = '#7C5CFB' },
    { id = 'red',     hex = '#E5564B' },
    { id = 'blue',    hex = '#1F5EFF' },
    { id = 'dark',    hex = '#1F1F21' },
    { id = 'green',   hex = '#34C77B' },
    { id = 'orange',  hex = '#E5A93C' },
    { id = 'pink',    hex = '#E84393' },
    { id = 'cyan',    hex = '#3FC1C9' },
    { id = 'lime',    hex = '#A8E063' },
}

-- ═══════════════════════════════════════════════════════════
-- COMMANDS for opening the in-game UI panels.
-- ═══════════════════════════════════════════════════════════
Config.UICommands = {
    settings = 'chatsettings',     -- /chatsettings
    commands = 'chatcommands',     -- /chatcommands
}

-- Default theme for new players and for "Reset Default" in settings.
-- Must match an id from Config.Themes below, for example: 'apex', 'midnight', 'ox'.
Config.DefaultTheme = 'apex'

-- Default values applied when no KVP record exists yet.
Config.DefaultPrefs = {
    theme         = Config.DefaultTheme or 'apex',
    chatDesign    = 'apex',        -- chat LAYOUT theme: apex|glass|neon|bubble|cards|minimal|terminal
    activeCategory = 'global',     -- last selected chat tab
    selectedColor = false,         -- preset id, only used when accentOverride = true
    accentOverride = false,        -- true when a player manually picks a Design color
    themeMode     = 'dark',        -- legacy 'dark' | 'light' mode; full themes take priority
    chatSize      = 'medium',      -- 'small' | 'medium' | 'big'
    freeHand      = false,
    position      = 'top-left',    -- 'top-left' | 'top-center' | 'top-right' | 'bottom-left' | 'bottom-center' | 'bottom-right'
    visibility    = 'when-message',-- 'always' | 'when-message' | 'when-active'
    visibilityHideMs = 8000,
    inactiveHideMs   = 10000,
    showAvatars   = true,
    rect          = { w = 480, h = 260 },  -- x/y set only when the player drags (free-hand)
    shortcuts     = {},
}

--------------------------------
-- [Discord Logs]

Config.EnableDiscordLogs = true

Config.IconURL = ""

Config.ServerName = "CHICAGO ROLEPLAY"

-- Decimal value (use https://www.mathsisfun.com/hexadecimal-decimal-colors.html)
Config.WebhookColor = "2055679" -- Apex brand #1F5EFF in decimal

Config.WebhookURL = ""

--------------------------------
-- [Staff Groups]

Config.StaffGroups = { -- Groups that can access the different staff chats (/staff, /staffo, /sa)
    'god',
    'admin',
}

--------------------------------
-- [General]

Config.AllowPlayersToClearTheirChat = true

Config.ClearChatCommand = 'clear'

Config.EnableHideChat = true

Config.HideChatCommand = 'hide'

Config.ShowIDOnMessage = true

Config.ShowIDOnMessageForEveryone = false

Config.ClearChatMessageTitle = 'SYSTEM'

Config.ClearChatMessage = 'The chat has been cleared!'

-- [Date Format]

Config.DateFormat = '%H:%M'

--------------------------------
-- [Time Out]

Config.TimeOutPlayers = true

Config.TimeOutCommand = "mute"

Config.RemoveTimeOutCommand = "unmute"

Config.ShowTimeOutMessageForEveryone = true

Config.TimeOutIcon = 'fas fa-gavel'

Config.MessageTitle = 'SERVER'

Config.TimeOutMessages = {
    ['muted_for']       = '<b>{3}</b> has been muted for <b>{1}</b> minutes',
    ['you_muted_for']   = 'You muted <b>{3}</b> for <b>{1}</b> minutes',
    ['been_muted_for']  = 'You have been muted for <b>{0}</b> minutes',

    ['you_unmuted']     = 'You unmuted <b>{2}</b>',
    ['been_unmuted']    = 'You have been unmuted',

    ['muted_message']   = 'You are muted for <b>{0}</b>',
    ['seconds']         = ' seconds',
    ['minutes']         = ' minutes',
    ['hours']           = ' hours',
}

--------------------------------
-- [Me/Do/Try]

Config.Distance = 150
Config.Duration = 5000
Config.TextFont = 0
Config.TextScale = 0.5

Config.EnableMe = true
Config.MeCommand = 'me'
Config.MeTextColor = { r = 100, g = 100, b = 230, a = 255 }

Config.EnableDo = true
Config.DoCommand = 'do'
Config.DoTextColor = { r = 100, g = 230, b = 100, a = 255 }

Config.EnableTry = true
Config.TryCommand = 'try'
Config.TryTextColor = { r = 230, g = 100, b = 100, a = 255 }

--------------------------------
-- [Job]

Config.JobChat = true
Config.JobCommand = 'jobc'
Config.JobIcon = 'fas fa-briefcase'

--------------------------------
-- [Private Message]

Config.EnablePM = true
Config.PMCommand = 'pm'
Config.PMIcon = 'fas fa-comment'
Config.PMMessageTitle = "PM"

--------------------------------
-- [OOC]

Config.EnableOOC = true
Config.OOCCommand = 'ooc'
Config.OOCDistance = 20.0
Config.OOCIcon = 'fas fa-door-open'
Config.OOCMessageTitle = 'OOC'
Config.OOCMessageWithoutCommand = true

--------------------------------
-- [Staff]

Config.EnableStaffCommand = true
Config.StaffCommand = 'staff'
Config.StaffMessageTitle = 'STAFF'
Config.StaffIcon = 'fas fa-shield-alt'

Config.AllowStaffsToClearEveryonesChat = true
Config.ClearEveryonesChatCommand = 'clearall'

Config.StaffSteamName = true
Config.ShowStaffMessageWhenHidden = true

Config.EnableStaffOnlyCommand = true
Config.StaffOnlyCommand = 'staffo'
Config.StaffOnlyMessageTitle = 'STAFF ONLY'
Config.StaffOnlyIcon = 'fas fa-eye-slash'
Config.StaffOnlySteamName = true

Config.EnableServerAnnouncement = true
Config.ServerAnnouncementCommand = 'sa'
Config.AnnouncementIcon = 'fas fa-exclamation-circle'
Config.AnnouncementMessageTitle = 'SERVER'

--------------------------------
-- [Advertisements]

Config.EnableAdvertisementCommand = true
Config.AdvertisementCommand = 'ad'
Config.AdvertisementPrice = 1000
Config.AdvertisementCooldown = 5
Config.AdvertisementIcon = 'fas fa-ad'

--------------------------------
-- [Anonymous/Dark]

Config.EnableAnonymousCommand = true
Config.AnonymousCommand = 'anon'
Config.AnonymousPrice = 1000
Config.AnonymousCooldown = 5
Config.WhatJobsCantSeeAnonymousChat = { 'police', 'ambulance' }
Config.AnonymousIcon = 'fas fa-mask'

--------------------------------
-- [Twitch / YouTube / Twitter]

Config.EnableTwitchCommand = true
Config.TwitchCommand = 'twitch'
Config.TwitchList = { 'discord:000000000000000000' } -- identifiers allowed to use the command
Config.TwitchIcon = 'fab fa-twitch'

Config.EnableYoutubeCommand = true
Config.YoutubeCommand = 'youtube'
Config.YoutubeList = { 'discord:000000000000000000' } -- identifiers allowed to use the command
Config.YoutubeIcon = 'fab fa-youtube'

Config.EnableTwitterCommand = true
Config.TwitterCommand = 'x'
Config.TwitterIcon = 'fab fa-x-twitter'

--------------------------------
-- [Police / Ambulance]

Config.EnablePoliceCommand = true
Config.PoliceCommand = 'police'
Config.PoliceJobName = 'police'
Config.PoliceIcon = 'fas fa-bullhorn'

Config.EnableAmbulanceCommand = true
Config.AmbulanceCommand = 'ambulance'
Config.AmbulanceJobName = 'ambulance'
Config.AmbulanceIcon = 'fas fa-ambulance'

--------------------------------
-- [Auto Message]

Config.EnableAutoMessage = true
Config.AutoMessageTime = 10
Config.AutoMessages = {
    "Don't break the rules!",
    "Have fun!",
}

--------------------------------
-- [Custom Commands runtime]
-- Maximum number of custom commands allowed per server (KVP-stored).
Config.CustomCommands = {
    maxTotal      = 100,
    -- Group whose members can author custom commands via /chatcommands.
    -- Use 'everyone' to allow all players, or list QBCore groups.
    authorGroups  = { 'god', 'admin' },
    -- Default duration when 'auto-remove' is selected (ms).
    defaultAutoMs = 30000,
}

--------------------------------
-- [Notifications]

Config.NotificationsText = {
    ['disable_chat']    = { title = 'SYSTEM',        message = 'You disabled the chat',                                 time = 5000, type = 'info'    },
    ['enable_chat']     = { title = 'SYSTEM',        message = 'You enabled the chat',                                  time = 5000, type = 'info'    },
    ['ad_success']      = { title = 'ADVERTISEMENT', message = 'Advertisement successfully made for ${price}€',         time = 5000, type = 'success' },
    ['ad_no_money']     = { title = 'ADVERTISEMENT', message = "You don't have enough money to make an advertisement",  time = 5000, type = 'error'   },
    ['ad_too_quick']    = { title = 'ADVERTISEMENT', message = "You can't advertise so quickly",                        time = 5000, type = 'info'    },
    ['mute_not_adm']    = { title = 'SYSTEM',        message = 'You are not an admin',                                  time = 5000, type = 'error'   },
    ['mute_id_inv']     = { title = 'SYSTEM',        message = 'The id is invalid',                                     time = 5000, type = 'error'   },
    ['mute_time_inv']   = { title = 'SYSTEM',        message = 'The mute time is invalid',                              time = 5000, type = 'error'   },
    ['alr_muted']       = { title = 'SYSTEM',        message = 'This person is already muted',                          time = 5000, type = 'error'   },
    ['alr_unmuted']     = { title = 'SYSTEM',        message = 'This person is already unmuted',                        time = 5000, type = 'error'   },
    ['an_success']      = { title = 'ANONYMOUS',     message = 'Advertisement successfully made for price€',            time = 5000, type = 'success' },
    ['an_no_money']     = { title = 'ANONYMOUS',     message = "You don't have enough money to make an advertisement",  time = 5000, type = 'error'   },
    ['an_too_quick']    = { title = 'ANONYMOUS',     message = "You can't advertise so quickly",                        time = 5000, type = 'error'   },
    ['an_not_allowed']  = { title = 'ANONYMOUS',     message = "You are not allowed to send messages in the anonymous chat", time = 5000, type = 'error' },
    ['is_muted']        = { title = 'ANONYMOUS',     message = "This player is muted",                                  time = 5000, type = 'error'   },
    ['cc_saved']        = { title = 'COMMANDS',      message = 'Custom command saved',                                  time = 4000, type = 'success' },
    ['cc_deleted']      = { title = 'COMMANDS',      message = 'Custom command deleted',                                time = 4000, type = 'success' },
    ['cc_denied']       = { title = 'COMMANDS',      message = 'You are not allowed to manage custom commands',         time = 4000, type = 'error'   },
    ['cc_invalid']      = { title = 'COMMANDS',      message = 'Invalid command data',                                  time = 4000, type = 'error'   },
}

Config.WebhookText = {
    ['clear_all']       = 'Cleared all chats',
    ['staff_msg']       = 'Staff message',
    ['staff_chat_msg']  = 'Staff chat message',
    ['sv_an']           = 'Server announcement',
    ['ad']              = 'Advertisement',
    ['twitch']          = 'Twitch',
    ['youtube']         = 'Youtube',
    ['twitter']         = 'X',
    ['police']          = 'Police',
    ['ambulance']       = 'Ambulance',
    ['job_chat']        = 'Job chat [${job}]',
    ['pm_chat']         = 'Private Message to ${name} [${id}]',
    ['ooc']             = 'OOC',
    ['muted']           = 'Muted [${id}]',
    ['muted_for']       = 'For ${muteTime} minutes',
    ['unmuted']         = 'Unmuted [${id}]',
    ['p_unmuted']       = 'Player has been unmuted',
    ['anon']            = 'Anonymous',
    ['custom_cmd']      = 'Custom command [${name}]',
}

-- ═══════════════════════════════════════════════════════════
-- SHARED — runtime/UI behaviour. Exposed as a separate global
-- so the legacy Config above stays untouched.
-- ═══════════════════════════════════════════════════════════
Shared = Shared or {}

Shared.locale                  = "en"
Shared.debug                   = false  -- true enables dev helpers (e.g. the /me bubble test keybind)
Shared.acceptLegacyMessages    = true
Shared.executeCommandWhenDefault = "ooc"   -- nil for none; default routes naked messages
Shared.skipRecipientProccForAuthor = true  -- author skips recipient checks when in the pool

Shared.framework = "auto"  -- 'auto' | 'qb' | 'qbx' | 'esx'

Shared.headMessage = {
    timePerCharacter = 180,  -- ms per character (bubble lifetime)
    minTime          = 3200,
    maxTime          = 7000,
}

Shared._alias = {
    ["qb-core"]     = "qb",
    ["qbx_core"]    = "qbx",
    ["es_extended"] = "esx",
}

Shared.UI = {}

Shared.UI.General = {
    Debug            = false,
    MaxMessageLength = 300,
}

Shared.UI.Features = {
    EmojiPicker           = true,
    GifSelector           = true,
    DiceButton            = true,
    TryButton             = true,
    CommandSuggestions    = true,
    MessageLengthCounter  = true,
    MessageHistory        = true,
    MaxHistoryMessages    = 10,
}

-- 3D speech-bubble renderer (head messages). Uses the same
-- World3dToScreen2d + NUI projection technique as apex_banking
-- so every bubble is sharp HTML, not native DrawText.
Shared.UI.DuiHandler = {
    enabled            = true,
    duration           = 8000,                 -- default fallback lifetime (ms)
    maxDistance        = 50.0,                 -- world distance cutoff
    fontSize           = 0.4,                  -- legacy scalar, mirrored to NUI rem
    fontId             = 4,
    color              = { r = 255, g = 255, b = 255, a = 255 },
    shadowColor        = { r = 0,   g = 0,   b = 0,   a = 150 },
    verticalOffset     = 0.32,                 -- metres above the ped HEAD bone
    fadeDistance       = 30.0,                 -- start fading past this distance
    maxTexts           = 2,                    -- max stacked bubbles per ped
    backgroundColor    = { r = 0, g = 0, b = 0, a = 80 },
    backgroundPadding  = { x = 0.02, y = 0.01 },
    enableBackground   = false,
    enableShadow       = false,
}

-- KVP storage keys (FiveM key-value pairs, scope = resource).
Shared.Storage = {
    clientPrefsKey       = 'apex_chat:prefs_v5',  -- bumped to discard old saved prefs
    serverCustomCmdsKey  = 'apex_chat:custom_commands',
    serverCategoriesKey  = 'apex_chat:categories',
}

-- Locales bag — populated by shared/locales.lua + future translations.
Locales = Locales or {}

-- ═══════════════════════════════════════════════════════════
-- MODERN CHAT — window, categories, themes & avatars.
-- These power the fully-custom NUI chat (ox_lib/ox_inventory
-- aesthetic). Everything here is open-source (escrow_ignore).
-- ═══════════════════════════════════════════════════════════

-- Replace the stock FiveM `chat` resource so the custom UI owns
-- rendering + input. When true the server stops the conflicting
-- chat resources below and the client disables the GTA-native text
-- chat (SetTextChatEnabled(false)), exactly like okokChat.
Config.ReplaceDefaultChat = false

-- Chat resources stopped on boot so they don't render a 2nd chat.
-- Add any other chat resource you previously used.
Config.StopChatResources = { 'chat', 'okokchat-main', 'okokChat' }

-- Key used to open / focus the chat input (FiveM keymapping).
Config.OpenKey         = 'T'
Config.OpenCommand     = 'apexchat'

-- Category players land on when typing plain text (no slash).
Config.DefaultCategory = 'global'

-- Who may create/edit/delete categories & themes from the in-game
-- managers. 'everyone' allows all players; otherwise list groups.
Config.CategoryManager = {
    authorGroups = { 'god', 'admin' },
    maxTotal     = 100,
}

-- ─── Avatars ────────────────────────────────────────────────
-- Chat avatars use the same native character headshot method as apex_bossmenu.
-- Screen photos remain separate under Config.ScreenPhoto.
Config.Avatars = {
    enabled  = true,
    mode     = 'mugshot',   -- 'mugshot' = character photo, 'initials' = fallback only
    fallback = 'initials',
    refreshMs = 600000,
    transparent = true,
    maxCached = 16,
    timeoutMs = 1500,
}

-- Player screen photo capture. This uses screenshot-basic to capture
-- the player's current screen and stores the data URI/base64 locally.
Config.ScreenPhoto = {
    command = 'chatfoto',
    encoding = 'jpg',
    quality = 0.86,
    saveClientKvp = true,
    kvpKey = 'apex_chat:last_screen_photo_base64',
    maxBase64Length = 6000000,
    chatEncoding = 'jpg',
    chatQuality = 0.55,
    chatMaxBase64Length = 900000,
    chatCaptureDelayMs = 180,
    chatMessageText = 'Photo',

    -- Framing mode: after "Take photo" the chat closes and the player
    -- aims the camera freely; ENTER/LMB captures, BACKSPACE/ESC cancels.
    -- HUD + radar are hidden while framing. false = capture immediately.
    framing          = true,
    framingTimeoutMs = 60000,
    framingHelpText  = 'Capture: ~INPUT_CELLPHONE_SELECT~   Cancel: ~INPUT_CELLPHONE_CANCEL~',
}

-- GIF picker (composer GIF tool). Provider 'tenor' works out of the
-- box (public v1 key). For 'giphy' create a free key at
-- developers.giphy.com and paste it into giphyKey.
Config.Gif = {
    provider = 'tenor',          -- 'tenor' | 'giphy'
    tenorKey = 'LIVDSRZULELA',   -- Tenor v1 public key
    giphyKey = '',               -- only used when provider = 'giphy'
    limit    = 24,
}

-- @mentions: matching recipients get the message highlighted + a
-- distinct two-tone chime. Matches "@Nome Completo", "@PrimeiroNome"
-- or "@id" (case-insensitive).
Config.Mentions = {
    enabled = true,
}

-- "X está a escrever…" above the composer, per category, respecting
-- the category's visibility/area rules. Anonymous channels never show it.
Config.Typing = {
    enabled    = true,
    throttleMs = 900,
}

-- Slow mode / anti-spam (server-side): cooldown between messages and a
-- duplicate-message filter. Staff (isAdmin) is exempt by default.
Config.SlowMode = {
    enabled     = true,
    cooldownMs  = 2000,   -- min interval between messages per player
    duplicateMs = 6000,   -- window where the exact same text is rejected
    exemptStaff = true,
}

-- ═══════════════════════════════════════════════════════════
-- THEMES — selectable live from the Theme Manager. Each theme is
-- a set of CSS custom properties applied to the chat window.
-- Add/remove freely; `id` must be unique. First = default.
-- ═══════════════════════════════════════════════════════════
Config.Themes = {
    {
        id = 'aurora', name = 'Aurora',
        vars = {
            bg         = '#08110F',
            panel      = '#0F1A17',
            panelRaised= '#17251F',
            border     = 'rgba(255,255,255,.07)',
            borderHi   = 'rgba(255,255,255,.13)',
            text       = '#E9FBF4',
            textSub    = 'rgba(233,251,244,.55)',
            accent     = '#22D3AA',
            accentSoft = 'rgba(34,211,170,.14)',
            accentText = '#04130E',
            surface0   = '#08110F',
            surface1   = '#0C1613',
            surface2   = '#0F1A17',
            surface3   = '#17251F',
            surface4   = '#20322A',
            surface5   = '#2A4036',
            line1      = 'rgba(255,255,255,.06)',
            line2      = 'rgba(255,255,255,.10)',
            line3      = 'rgba(255,255,255,.17)',
            line4      = 'rgba(255,255,255,.26)',
            brand300   = '#7EEBD3',
            brand400   = '#48E0BF',
            brand500   = '#22D3AA',
            brand600   = '#0FA783',
        },
    },
    {
        id = 'apex', name = 'Apex Carbon',
        vars = {
            bg         = '#0A0A0B',
            panel      = '#1A1A1B',
            panelRaised= '#232325',
            border     = '#1F1F21',
            borderHi   = '#2A2A2D',
            text       = '#F4F4F5',
            textSub    = '#A8A8AD',
            accent     = '#1F5EFF',
            accentSoft = 'rgba(31,94,255,.14)',
            accentText = '#FFFFFF',
            surface0   = '#0A0A0B',
            surface1   = '#131314',
            surface2   = '#1A1A1B',
            surface3   = '#232325',
            surface4   = '#2D2D30',
            surface5   = '#38383C',
            line1      = '#1F1F21',
            line2      = '#2A2A2D',
            line3      = '#3A3A3E',
            line4      = '#4D4D52',
            brand300   = '#859BFF',
            brand400   = '#5C7AFF',
            brand500   = '#1F5EFF',
            brand600   = '#0048F0',
        },
    },
    {
        id = 'noir_gold', name = 'Noir Gold',
        vars = {
            bg='#070706', panel='#151411', panelRaised='#211F19',
            border='rgba(245,191,94,.08)', borderHi='rgba(245,191,94,.2)',
            text='#F6F1E6', textSub='rgba(246,241,230,.58)',
            accent='#D7A84B', accentSoft='rgba(215,168,75,.16)', accentText='#100D07',
            surface0='#070706', surface1='#100F0D', surface2='#151411', surface3='#211F19',
            surface4='#2C2921', surface5='#393426',
            line1='rgba(245,191,94,.06)', line2='rgba(245,191,94,.12)', line3='rgba(245,191,94,.22)', line4='rgba(245,191,94,.34)',
            brand300='#F5D58B', brand400='#E9BE62', brand500='#D7A84B', brand600='#A77723',
        },
    },
    {
        id = 'alpine', name = 'Alpine',
        vars = {
            bg='#07100D', panel='#111D19', panelRaised='#1B2B25',
            border='rgba(91,221,166,.08)', borderHi='rgba(91,221,166,.2)',
            text='#EAF8F1', textSub='rgba(234,248,241,.58)',
            accent='#45D18C', accentSoft='rgba(69,209,140,.16)', accentText='#03110A',
            surface0='#07100D', surface1='#0C1713', surface2='#111D19', surface3='#1B2B25',
            surface4='#253A32', surface5='#314A40',
            line1='rgba(91,221,166,.06)', line2='rgba(91,221,166,.12)', line3='rgba(91,221,166,.22)', line4='rgba(91,221,166,.34)',
            brand300='#A9F2CA', brand400='#71E4AA', brand500='#45D18C', brand600='#15995B',
        },
    },
    {
        id = 'metro', name = 'Metro Red',
        vars = {
            bg='#10090B', panel='#1D1114', panelRaised='#2B1A1E',
            border='rgba(238,86,103,.08)', borderHi='rgba(238,86,103,.2)',
            text='#F8EDEF', textSub='rgba(248,237,239,.58)',
            accent='#E64F64', accentSoft='rgba(230,79,100,.16)', accentText='#FFFFFF',
            surface0='#10090B', surface1='#170D10', surface2='#1D1114', surface3='#2B1A1E',
            surface4='#3A2328', surface5='#4B2D34',
            line1='rgba(238,86,103,.06)', line2='rgba(238,86,103,.12)', line3='rgba(238,86,103,.22)', line4='rgba(238,86,103,.34)',
            brand300='#FF9BA8', brand400='#F06D7E', brand500='#E64F64', brand600='#B72D40',
        },
    },
    {
        id = 'ocean', name = 'Deep Ocean',
        vars = {
            bg='#071018', panel='#101C27', panelRaised='#192A38',
            border='rgba(77,185,232,.08)', borderHi='rgba(77,185,232,.2)',
            text='#E8F4FA', textSub='rgba(232,244,250,.58)',
            accent='#4DB9E8', accentSoft='rgba(77,185,232,.16)', accentText='#03111A',
            surface0='#071018', surface1='#0C1620', surface2='#101C27', surface3='#192A38',
            surface4='#24394A', surface5='#30495D',
            line1='rgba(77,185,232,.06)', line2='rgba(77,185,232,.12)', line3='rgba(77,185,232,.22)', line4='rgba(77,185,232,.34)',
            brand300='#A7E0F6', brand400='#73C9EE', brand500='#4DB9E8', brand600='#1E83AD',
        },
    },
    {
        id = 'graphite_lime', name = 'Graphite Lime',
        vars = {
            bg='#090B09', panel='#151815', panelRaised='#20251F',
            border='rgba(178,235,97,.08)', borderHi='rgba(178,235,97,.2)',
            text='#F0F6E9', textSub='rgba(240,246,233,.58)',
            accent='#A8E063', accentSoft='rgba(168,224,99,.16)', accentText='#0B1204',
            surface0='#090B09', surface1='#101310', surface2='#151815', surface3='#20251F',
            surface4='#2B3229', surface5='#384235',
            line1='rgba(178,235,97,.06)', line2='rgba(178,235,97,.12)', line3='rgba(178,235,97,.22)', line4='rgba(178,235,97,.34)',
            brand300='#D3F7A7', brand400='#BDEB7E', brand500='#A8E063', brand600='#78A934',
        },
    },
    {
        id = 'platinum', name = 'Platinum Light',
        vars = {
            bg='#EEF1F6', panel='#F7F8FB', panelRaised='#FFFFFF',
            border='rgba(20,30,48,.08)', borderHi='rgba(20,30,48,.16)',
            text='#151A22', textSub='rgba(21,26,34,.58)',
            accent='#4968E8', accentSoft='rgba(73,104,232,.14)', accentText='#FFFFFF',
            surface0='#EEF1F6', surface1='#F3F5F9', surface2='#F7F8FB', surface3='#FFFFFF',
            surface4='#E7EAF0', surface5='#D9DEE8',
            line1='rgba(20,30,48,.06)', line2='rgba(20,30,48,.1)', line3='rgba(20,30,48,.18)', line4='rgba(20,30,48,.28)',
            brand300='#8EA0FF', brand400='#667EF3', brand500='#4968E8', brand600='#2E49B7',
        },
    },
    {
        id = 'copper', name = 'Copper Slate',
        vars = {
            bg='#0D0B0A', panel='#191412', panelRaised='#261D18',
            border='rgba(211,122,69,.08)', borderHi='rgba(211,122,69,.2)',
            text='#F5EEE8', textSub='rgba(245,238,232,.58)',
            accent='#D37A45', accentSoft='rgba(211,122,69,.16)', accentText='#140906',
            surface0='#0D0B0A', surface1='#130F0D', surface2='#191412', surface3='#261D18',
            surface4='#34261F', surface5='#443126',
            line1='rgba(211,122,69,.06)', line2='rgba(211,122,69,.12)', line3='rgba(211,122,69,.22)', line4='rgba(211,122,69,.34)',
            brand300='#F0B98C', brand400='#E18F5A', brand500='#D37A45', brand600='#9B4D24',
        },
    },
    {
        id = 'roseglass', name = 'Rose Glass',
        vars = {
            bg='#F5EFF2', panel='#FFF8FA', panelRaised='#FFFFFF',
            border='rgba(115,47,76,.08)', borderHi='rgba(115,47,76,.16)',
            text='#22161B', textSub='rgba(34,22,27,.58)',
            accent='#C45D83', accentSoft='rgba(196,93,131,.14)', accentText='#FFFFFF',
            surface0='#F5EFF2', surface1='#FAF4F6', surface2='#FFF8FA', surface3='#FFFFFF',
            surface4='#EBDDE3', surface5='#DEC9D1',
            line1='rgba(115,47,76,.06)', line2='rgba(115,47,76,.1)', line3='rgba(115,47,76,.18)', line4='rgba(115,47,76,.28)',
            brand300='#EAA5BE', brand400='#D7779B', brand500='#C45D83', brand600='#913658',
        },
    },
}

-- ═══════════════════════════════════════════════════════════
-- CATEGORIES — the chat channels. Seeded here on first boot, then
-- stored/edited live via the Category Manager (KVP override).
--
-- Schema:
--   id          unique string
--   label       tab name
--   command     slash command (e.g. 'police' → /police). Unique.
--   icon        Font Awesome class
--   color       hex accent for this channel
--   identity    'rp' | 'steam' | 'anon'  (how the sender is named)
--   area        metres; 0 = whole server (proximity channel if > 0)
--   visibility  'all' | 'staff' | 'sender' | 'role' | 'job'
--   rule = {
--     type      'open' | 'job' | 'grade' | 'staff' | 'role'
--     jobs      { 'police', ... }   (job/grade; empty = sender's own job)
--     minGrade  number              (grade)
--     groups    { 'admin', ... }    (staff; defaults to Config.StaffGroups)
--     ace       'chat.vip'          (role; ACE permission)
--     identifiers { 'discord:..' }  (role; identifier allowlist)
--   }
--   enabled, order
-- ═══════════════════════════════════════════════════════════
Config.Categories = {
    {
        id='global', label='Global', command='global', icon='fas fa-globe',
        color='#1F5EFF', identity='rp', area=0, visibility='all',
        rule={ type='open' }, enabled=true, order=1,
    },
    {
        id='local', label='Local', command='local', icon='fas fa-location-dot',
        color='#3FC1C9', identity='rp', area=20.0, visibility='all',
        rule={ type='open' }, enabled=true, order=2,
    },
    {
        id='jobc', label='Job', command='jobc', icon='fas fa-briefcase',
        color='#4E9CE5', identity='rp', area=0, visibility='job',
        rule={ type='job', jobs={} },  -- empty jobs = sender's current job
        enabled=true, order=3,
    },
    {
        id='police', label='Police', command='police', icon='fas fa-bullhorn',
        color='#1F5EFF', identity='rp', area=0, visibility='job',
        rule={ type='job', jobs={ 'police' } }, enabled=true, order=4,
    },
    {
        id='ems', label='EMS', command='ems', icon='fas fa-truck-medical',
        color='#E5A93C', identity='rp', area=0, visibility='job',
        rule={ type='job', jobs={ 'ambulance' } }, enabled=true, order=5,
    },
    {
        id='gang', label='Gang', command='gang', icon='fas fa-skull',
        color='#9C5CFB', identity='rp', area=0, visibility='role',
        rule={ type='grade', jobs={ 'ballas' }, minGrade=0 }, enabled=true, order=6,
    },
    {
        id='vip', label='Premium', command='vip', icon='fas fa-crown',
        color='#E5C84B', identity='rp', area=0, visibility='role',
        rule={ type='role', ace='chat.vip', identifiers={} }, enabled=true, order=7,
    },
    {
        id='staffchat', label='Staff', command='sc', icon='fas fa-shield-halved',
        color='#34C77B', identity='steam', area=0, visibility='staff',
        rule={ type='staff', groups={} }, enabled=true, order=8,  -- empty groups = Config.StaffGroups
    },
}

