

-- ============================================================
--  OXLYN Vinewood Studio | Locale loader
--  Load order (fxmanifest shared_scripts):
--    config.lua -> locales/loader.lua -> locales/<code>.lua -> shared/*
--  Runs on the client, the server and (through the NUI payload) the UI.
--  The file is idempotent: loading it twice never drops registered locales.
-- ============================================================

_OxlynLocales = _OxlynLocales or {}

-- Registers a locale table. Every table carries its code and a native name
-- (`_name`) so the UI can build a language list without extra metadata.
function RegisterLocale(code, tbl)
    if type(code) ~= 'string' or type(tbl) ~= 'table' then return end
    code = code:lower()
    tbl._code = code
    if type(tbl._name) ~= 'string' or #tbl._name == 0 then tbl._name = code:upper() end
    _OxlynLocales[code] = tbl
end

local function fallback()
    return _OxlynLocales.en
end

local resolved, resolvedCode = nil, nil
local warned = false
-- Language override for this side only (the client follows the player's UI choice; the server never sets it).
local override = nil

-- Overrides Config.Locale for GetLang()/L(). An unknown or empty code clears the override
-- so the configured default applies again. The resolved cache is reset either way.
function SetLocale(code)
    code = type(code) == 'string' and code:lower() or nil
    if code and not _OxlynLocales[code] then code = nil end
    override = code
    resolved, resolvedCode = nil, nil
end

-- The code GetLang() resolves: the override when one is set, else Config.Locale (default 'en').
function GetLocaleCode()
    if override then return override end
    return type(Config) == 'table' and type(Config.Locale) == 'string' and Config.Locale:lower() or 'en'
end

-- Resolves the active locale table from the override or Config.Locale, falling back to English.
-- The result is cached only once a real table exists so early calls never pin
-- an empty table for the rest of the session.
function GetLang()
    local selected = GetLocaleCode()
    if resolved and resolvedCode == selected then return resolved end
    local tbl = _OxlynLocales[selected]
    if not tbl then
        if not warned and next(_OxlynLocales) then
            warned = true
            print(('[oxlyn-vinewood] WARNING: unknown locale "%s", falling back to en'):format(tostring(selected)))
        end
        tbl = fallback()
    end
    if tbl then resolved, resolvedCode = tbl, selected; return tbl end
    return {}
end

local function substitute(str, vars)
    if type(vars) ~= 'table' then return str end
    for key, value in pairs(vars) do
        local replacement = tostring(value):gsub('%%', '%%%%')
        str = str:gsub('{' .. tostring(key) .. '}', replacement)
    end
    return str
end

-- Translates `key`, replacing `{name}` placeholders with `vars.name`.
-- Missing keys fall back to English, then to the key itself.
function L(key, vars)
    local str = GetLang()[key]
    if type(str) ~= 'string' then
        local en = fallback()
        str = en and en[key]
    end
    if type(str) ~= 'string' then return tostring(key) end
    return substitute(str, vars)
end

-- Read-only proxy: Lang.example gives the same text as L with the key "example", without placeholders.
Lang = setmetatable({}, {
    __index = function(_, key) return GetLang()[key] end,
    __newindex = function() end
})

-- Full table of one locale (for the NUI). Unknown codes resolve to English.
-- Returns the table and the code that was actually resolved.
function GetLocaleTable(code)
    code = type(code) == 'string' and code:lower() or 'en'
    local tbl = _OxlynLocales[code]
    if not tbl then tbl, code = fallback(), 'en' end
    if not tbl then return {}, 'en' end
    return tbl, code
end

-- { {code='en', name='English'}, ... } with English first, then by code.
function ListLocales()
    local list = {}
    for code, tbl in pairs(_OxlynLocales) do
        list[#list + 1] = { code = code, name = tbl._name or code:upper() }
    end
    table.sort(list, function(a, b)
        if a.code == 'en' then return b.code ~= 'en' end
        if b.code == 'en' then return false end
        return a.code < b.code
    end)
    return list
end

