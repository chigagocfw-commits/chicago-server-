

local currentLocale = (Config and Config.Locale) or "en"

-- Start with English as the base so missing keys always have a fallback
local strings = {}
local english = (Locales and Locales.en) or {}
for key, value in pairs(english) do
    strings[key] = value
end

-- Overlay the selected locale on top of English
if currentLocale ~= "en" then
    local selected = Locales and Locales[currentLocale]
    if not selected then
        print(("[oxlyn-garage] Unknown locale \"%s\" — falling back to English."):format(tostring(currentLocale)))
    else
        for key, value in pairs(selected) do
            strings[key] = value
        end
    end
end

--- Translate a key, optionally formatting it with arguments.
--- Returns the key itself if no translation exists.
function _U(key, ...)
    local str = strings[key]
    if str == nil then
        return key
    end

    if select("#", ...) > 0 then
        local ok, formatted = pcall(string.format, str, ...)
        if ok then
            return formatted
        end
    end

    return str
end

function GetLocaleTable()
    return strings
end

function GetCurrentLocale()
    return currentLocale
end

