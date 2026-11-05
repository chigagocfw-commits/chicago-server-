function ScootT(key, ...)
    local currentLocale = ScootConfig and ScootConfig.locale
    local localeTable = (ScootLocales and ScootLocales[currentLocale]) or (ScootLocales and ScootLocales.en) or {}
    local text = localeTable[key] or (ScootLocales and ScootLocales.en and ScootLocales.en[key]) or key

    if select("#", ...) > 0 then
        local success, formatted = pcall(string.format, text, ...)
        if success and formatted then
            return formatted
        end
    end

    return text
end

function ScootTranslations()
    local translations = {}
    local baseTable = (ScootLocales and ScootLocales.en) or {}

    for key in pairs(baseTable) do
        translations[key] = ScootT(key)
    end

    return translations
end
