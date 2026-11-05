local debugModule = {}
local configModule

function InitDebug()
    configModule = Modules.require("config")
    debugModule.enabled = configModule.Debug
    local resourceName = GetCurrentResourceName()
    if debugModule.enabled then
        SetConvarReplicated("ox:printlevel:" .. resourceName, "debug")
    else
        SetConvarReplicated("ox:printlevel:" .. resourceName, "info")
    end
end
debugModule.init = InitDebug

Modules.register("debug", debugModule, {
    dependencies = { "config" }
})
