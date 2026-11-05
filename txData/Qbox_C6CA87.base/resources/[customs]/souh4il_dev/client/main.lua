-- SOUH4IL-DEV — Client Bridge (Phase 1 Security Core)
-- Author: SOUH4IL / Antigravity
-- Framework: Qbox / ox_lib

local SharedConfig = require 'config.shared'

---Phase 1 diagnostic ping command
RegisterCommand('sdev_status', function()
    lib.callback('souh4il_dev:server:getSecurityStatus', false, function(response)
        if not response or not response.success then
            lib.notify({
                title = SharedConfig.PanelName,
                description = response and response.error or "Server connection failed",
                type = 'error'
            })
            return
        end

        lib.notify({
            title = SharedConfig.PanelName,
            description = ("Role: %s | Owner: %s"):format(response.role, response.isOwner and "YES" or "NO"),
            type = response.isOwner and 'success' or 'inform'
        })
    end)
end, false)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    -- Client-side cleanup for future phases
end)

