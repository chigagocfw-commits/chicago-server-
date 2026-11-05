-- SOUH4IL-DEV — Client Controller & NUI Bridge
-- Author: SOUH4IL / Antigravity
-- Framework: Qbox / ox_lib

local SharedConfig = require 'config.shared'
local isPanelOpen = false

---Toggles the SOUH4IL-DEV Control Panel
local function TogglePanel()
    if isPanelOpen then
        isPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "setVisible", visible = false })
        return
    end

    -- Query security status before opening
    lib.callback('souh4il_dev:server:getSecurityStatus', false, function(response)
        if not response or not response.success then
            lib.notify({
                title = SharedConfig.PanelName,
                description = response and response.error or "Server connection failed",
                type = 'error'
            })
            return
        end

        if not response.hasAccess and not response.isOwner then
            lib.notify({
                title = SharedConfig.PanelName,
                description = "Access Denied: You do not possess SOUH4IL-DEV staff permissions.",
                type = 'error'
            })
            return
        end

        isPanelOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "setVisible",
            visible = true,
            status = response,
            panelName = SharedConfig.PanelName,
            community = SharedConfig.Community
        })
    end)
end

-- Primary Command & Key Mapping (Default: F10)
RegisterCommand('sdev_menu', TogglePanel, false)
RegisterKeyMapping('sdev_menu', 'Open SOUH4IL-DEV Control Panel', 'keyboard', 'F10')

-- Diagnostic Status Command
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
            description = ("Role: %s | Owner: %s | Access: %s"):format(
                response.role,
                response.isOwner and "YES (Dual-Key)" or "NO",
                response.hasAccess and "GRANTED" or "DENIED"
            ),
            type = response.isOwner and 'success' or 'inform'
        })
    end)
end, false)

-- NUI Close Callback
RegisterNUICallback('close', function(_, cb)
    isPanelOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

-- NUI Quick Actions Callback
RegisterNUICallback('quickAction', function(data, cb)
    local action = data.action
    local ped = PlayerPedId()

    if action == 'revive' then
        TriggerServerEvent('souh4il_dev:server:executeQuickAction', 'revive')
    elseif action == 'heal' then
        TriggerServerEvent('souh4il_dev:server:executeQuickAction', 'heal')
    elseif action == 'repair' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            SetVehicleFixed(veh)
            SetVehicleDirtLevel(veh, 0.0)
            lib.notify({ title = SharedConfig.PanelName, description = "Vehicle fully repaired & cleaned.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "You must be inside a vehicle.", type = 'error' })
        end
    elseif action == 'clean' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            SetVehicleDirtLevel(veh, 0.0)
            lib.notify({ title = SharedConfig.PanelName, description = "Vehicle washed.", type = 'success' })
        else
            ClearPedBloodDamage(ped)
            ResetPedVisibleDamage(ped)
            lib.notify({ title = SharedConfig.PanelName, description = "Ped cleaned.", type = 'success' })
        end
    elseif action == 'tpm' then
        local waypoint = GetFirstBlipInfoId(8)
        if DoesBlipExist(waypoint) then
            local coords = GetBlipInfoIdCoord(waypoint)
            DoScreenFadeOut(250)
            Wait(300)
            SetEntityCoords(ped, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
            Wait(250)
            DoScreenFadeIn(250)
            lib.notify({ title = SharedConfig.PanelName, description = "Teleported to waypoint.", type = 'success' })
        else
            lib.notify({ title = SharedConfig.PanelName, description = "No map waypoint set.", type = 'error' })
        end
    elseif action == 'dv' then
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            DeleteEntity(veh)
            lib.notify({ title = SharedConfig.PanelName, description = "Vehicle deleted.", type = 'inform' })
        end
    end

    cb('ok')
end)

-- Fetch Audit Logs Callback
RegisterNUICallback('fetchLogs', function(_, cb)
    lib.callback('souh4il_dev:server:queryAuditLogs', false, function(response)
        if response and response.success then
            SendNUIMessage({ action = "updateLogs", logs = response.logs })
        else
            lib.notify({
                title = SharedConfig.PanelName,
                description = response and response.error or "Log query failed",
                type = 'error'
            })
        end
    end, 25)
    cb('ok')
end)

-- Weather Set Callback
RegisterNUICallback('setWeather', function(data, cb)
    TriggerServerEvent('souh4il_dev:server:setWeather', data.weather)
    cb('ok')
end)

-- Clean shutdown
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    if isPanelOpen then
        SetNuiFocus(false, false)
    end
end)
