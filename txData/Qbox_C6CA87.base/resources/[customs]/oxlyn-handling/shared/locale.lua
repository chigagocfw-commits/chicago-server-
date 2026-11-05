

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN-HANDLING  •  shared/locale.lua
--  Tiny i18n helper shared by client & server.
--    _U(key, ...)        → translated string (string.format args), EN fallback
--    Lang(textOrKey,...) → translate if it's a known key / 'locale:' ref, else as-is
--    GetLocaleTable()    → merged { EN <- current } table (handed to the NUI)
--    GetCurrentLocale()  → active locale code
-- ════════════════════════════════════════════════════════════════════════

local current = (Config and Config.Locale) or 'en'

-- Merge English (fallback) with the active language so a missing key never errors.
local merged = {}
do
    local en = (Locales and Locales['en']) or {}
    for k, v in pairs(en) do merged[k] = v end

    if current ~= 'en' then
        local active = (Locales and Locales[current]) or {}
        for k, v in pairs(active) do merged[k] = v end
    end
end

--- Translate a known locale key. Returns the key itself if not found.
function _U(key, ...)
    local str = merged[key]
    if str == nil then return key end
    if select('#', ...) > 0 then
        local ok, res = pcall(string.format, str, ...)
        if ok then return res end
    end
    return str
end

--- Resolve a config label that may be EITHER a locale key OR literal text.
--- Supports the 'locale:key' prefix used in config so labels can be i18n keys.
function Lang(textOrKey, ...)
    if textOrKey == nil then return nil end
    if type(textOrKey) == 'string' then
        local key = textOrKey:match('^locale:(.+)$')
        if key then return _U(key, ...) end
    end
    return _U(textOrKey, ...)
end

function GetLocaleTable()
    return merged
end

function GetCurrentLocale()
    return current
end

