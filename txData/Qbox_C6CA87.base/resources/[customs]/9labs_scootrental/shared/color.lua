function ScootColor(input)
    if type(input) ~= "string" then
        return nil
    end

    local hex = input:gsub("%s", ""):gsub("^#", ""):gsub("^0[xX]", "")

    if #hex == 3 then
        hex = hex:gsub("%x", "%0%0")
    end

    if #hex == 8 then
        hex = hex:sub(3)
    end

    if #hex == 6 and not hex:find("%X") then
        return "#" .. hex:lower()
    end

    return nil
end

function ScootTheme()
    local theme = {}
    if ScootConfig and ScootConfig.ui then
        for key, value in pairs(ScootConfig.ui) do
            theme[key] = value
        end
    end

    local colorKeys = { "accent", "accentSecondary", "panel", "text", "muted" }
    for _, key in ipairs(colorKeys) do
        local rawValue = theme[key]
        local sanitized = ScootColor(rawValue)

        if not sanitized and rawValue ~= nil then
            print(string.format("[scootbunker] ui.%s is not a usable colour: %s", key, tostring(rawValue)))
        end

        theme[key] = sanitized
    end

    return theme
end
