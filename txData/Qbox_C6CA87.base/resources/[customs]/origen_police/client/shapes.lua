-- Shapes System - Client Side
-- Handles restricted zones/shapes updates from server

-- Reload shapes when server sends update
RegisterNetEvent("origen_police:client:ReloadShapes", function()
    -- Notify NUI to update shapes display
    SendNUIMessage({
        action = "UpdateShapes"
    })
end)
