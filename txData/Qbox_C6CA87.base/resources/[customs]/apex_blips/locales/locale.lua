--[[
    Apex Blips — locale loader (shared)

    Every string a player, an admin or the studio interface ever shows lives in
    locales/<lang>.lua. Nothing is hardcoded anywhere else — the whole NUI is
    labelled from this table, so translating the resource means translating ONE
    file and nothing else.

    Add a language:
      1. copy locales/en.lua to locales/xx.lua and translate the VALUES only
      2. drop it in the folder (fxmanifest loads locales/*.lua as a glob)
      3. set Config.locale = 'xx' in config.lua

    Load order does not matter. This file only reads `Locales` and `Config` at
    CALL time, never at load time, so it works whether the language files or
    config.lua are loaded before or after it.
]]

Locales = Locales or {}

-- Resolve the language once per call. Config may not exist yet (another
-- shared_script could call L() while config.lua is still loading), so guard it.
local function activeLang()
    if Config and type(Config.locale) == 'string' and Config.locale ~= '' then
        return Config.locale
    end
    return 'en'
end

--[[
    L('some_key')            -> 'Some text'
    L('saved', 'Ammu')       -> 'Blip "Ammu" saved.'

    Lookup order: active language -> English -> the key itself. Returning the
    key is deliberate: a missing string shows up as `saved` in game, which is
    instantly reportable, instead of a nil that crashes the caller or an empty
    string that silently blanks a button.
]]
function L(key, ...)
    if type(key) ~= 'string' then return '' end

    local tbl = Locales[activeLang()] or {}
    local en  = Locales['en'] or {}
    local str = tbl[key]
    if type(str) ~= 'string' then str = en[key] end
    if type(str) ~= 'string' then str = key end

    if select('#', ...) > 0 then
        -- A translator who drops or reorders a %s must never take the resource
        -- down with them, so the format is attempted and quietly abandoned.
        local ok, out = pcall(string.format, str, ...)
        if ok and type(out) == 'string' then return out end
    end
    return str
end

--[[
    The whole active table, English-backed, shipped to the NUI in the `open`
    message so app.js can label itself with T(key, fallback).

    English is merged UNDER the active language on purpose: a half-finished
    translation then shows English for the missing keys instead of blank
    buttons, which is the difference between "not translated yet" and "broken".
]]
function LocaleTable()
    local base = Locales['en'] or {}
    local cur  = Locales[activeLang()] or base

    local out = {}
    for k, v in pairs(base) do out[k] = v end   -- English as the safety net
    for k, v in pairs(cur) do
        -- Skip empty strings too: an untranslated placeholder like `key = ''`
        -- would otherwise punch a hole through the English fallback.
        if type(v) == 'string' and v ~= '' then out[k] = v end
    end
    return out
end
