--[[
 LB-Phone error logging handler (secured)
 Telemetry webhook neutralized for server security and privacy.
--]]

local recentErrorCount = 0

RegisterNetEvent("phone:logError", function(message, stack, componentStack)
    if recentErrorCount >= 5 then
        return
    end

    recentErrorCount = recentErrorCount + 1

    SetTimeout(60000, function()
        recentErrorCount = recentErrorCount - 1
    end)

    -- Local server log only; no external leak
    -- print(("[lb-phone] Client UI error: %s"):format(tostring(message)))
end)