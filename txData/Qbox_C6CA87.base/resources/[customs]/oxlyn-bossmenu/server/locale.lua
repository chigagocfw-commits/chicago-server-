

--------------------------------------------------------------------
-- oxlyn-bossmenu | locale loader (cleaned)
-- Loads locales/<Config.Locale>.json and exposes a global translator:
--   L(key, vars)          -- global shortcut
--   OxlynBM.t(key, vars)  -- same function
--
-- vars:
--   { name = "Bob" }      replaces "{name}" in the translated text
--   { _d = "Default" }    text to use if the key is missing from the locale
--------------------------------------------------------------------

local RESOURCE_TAG = "oxlyn-bossmenu"

local locales = {}

local localeName = (Config and Config.Locale) or "pt"
local rawJson = LoadResourceFile(GetCurrentResourceName(), "locales/" .. localeName .. ".json")

if rawJson and rawJson ~= "" then
    local ok, decoded = pcall(json.decode, rawJson)

    if ok then
        if type(decoded) == "table" then
            locales = decoded
        end
    else
        print(("^1[%s] locale.lua: failed to parse locales/%s.json^7"):format(RESOURCE_TAG, localeName))
    end
else
    print(("^3[%s] locale.lua: locales/%s.json not found — using _d fallback^7"):format(RESOURCE_TAG, localeName))
end

-- Translate `key`, falling back to vars._d, then to the key itself.
-- Replaces {placeholders} with values from `vars` (ignoring _d).
local function translate(key, vars)
    local text = locales[key]

    if text == nil then
        text = (vars and vars._d) or key
    end

    if vars then
        for name, value in pairs(vars) do
            if name ~= "_d" then
                text = text:gsub("{" .. name .. "}", tostring(value))
            end
        end
    end

    return text
end

_G.L = translate
L = translate

OxlynBM = OxlynBM or {}
OxlynBM.t = translate

local keyCount = 0
for _ in pairs(locales) do
    keyCount = keyCount + 1
end

print(("^2[%s] locale.lua loaded (%d keys in locale \"%s\").^7"):format(RESOURCE_TAG, keyCount, localeName))

