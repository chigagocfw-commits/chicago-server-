lib.locale()

if lib.context == "client" then
    RegisterNUICallback("GET_LOCALES", function(data, cb)
        local allLocales = lib.getLocales()
        local uiLocales = {}

        for key, value in pairs(allLocales) do
            if key:find("ui_") then
                uiLocales[key] = value
            end
        end

        cb(uiLocales)
    end)
end
