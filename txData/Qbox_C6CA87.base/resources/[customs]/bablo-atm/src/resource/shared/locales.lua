Locales = Locales or {}

local localesLoaded = false

local function getBankingResource()
    return (Config and Config.BankingResource) or "bablo-banking"
end

local function fetchBankingLocales()
    local resourceName = getBankingResource()
    local state = GetResourceState(resourceName)

    if state ~= "started" and state ~= "starting" then
        return nil
    end

    local ok, locales = pcall(function()
        local banking = exports[resourceName]
        return banking and banking.GetLocales and banking:GetLocales()
    end)

    if ok and type(locales) == "table" then
        return locales
    end

    return nil
end

local function ensureLocales()
    if localesLoaded then
        return
    end

    local bankingLocales = fetchBankingLocales()
    if type(bankingLocales) == "table" then
        Locales = bankingLocales
        localesLoaded = true
    end
end

CreateThread(ensureLocales)

function Translate(key, replacements)
    ensureLocales()

    local variants = {
        key,
        string.upper(key),
        string.lower(key),
        key:gsub("-", "_"),
        key:gsub("_", "-"),
    }

    local value
    for _, variant in ipairs(variants) do
        if Locales[variant] then
            value = Locales[variant]
            break
        end
    end

    if not value then
        return key
    end

    if replacements then
        for _, replacement in ipairs(replacements) do
            value = value:gsub("%%s", tostring(replacement), 1)
        end
    end

    return value
end

function SetActiveLocales(locales)
    if type(locales) == "table" then
        Locales = locales
        localesLoaded = true
    end
end

function GetActiveLocales()
    ensureLocales()
    return Locales
end

function GetCurrentLocale()
    return "en-US"
end
