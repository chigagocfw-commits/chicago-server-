if Config.Framework ~= "qbcore" then return end
if GetResourceState("qb-core") ~= "started" then
    while true do
        print("^0[^5Origen Police^0] qb-core is not started, please make sure to start origen_police after qb-core^0")
        Wait(2000)
    end
end
Framework = exports['qb-core']:GetCoreObject()

function FW_CreateCallback(name, callback, mdw)
    Framework.Functions.CreateCallback(name, function(source, cb1, ...)
        if mdw then
            local args = {...}
            mdw(source, cb1, function()
                callback(source, cb1, table.unpack(args))
            end)
        else
            callback(source, cb1, ...)
        end
    end)
end

function FW_GetPlayer(source)
    local Player = Framework.Functions.GetPlayer(source)
    if Player == nil then return nil end
    return Player
end

function FW_GetPlayerFromCitizenid(citizenid)
    return Framework.Functions.GetPlayerByCitizenId(citizenid) or Framework.Functions.GetOfflinePlayerByCitizenId(citizenid)
end

function FW_CreateUseableItem(name, cb)
    if Config.Inventory == "ox_inventory" then
        exports(name, function(event, item, inventory, slot, data)
            cb(inventory.id, inventory.items[slot])
        end)
        return
    end
    Framework.Functions.CreateUseableItem(name, cb)
end

function FW_CommandsAdd(name, help, arguments, argsrequired, callback, permission, ...)
    Framework.Commands.Add(name, help, arguments, argsrequired, callback, permission, ...)
end

Framework.Functions.HasPermission = function(source, permission)
    -- Check ACE permissions first (server.cfg permissions)
    if IsPlayerAceAllowed(source, permission) then
        return true
    end
    
    local Player = Framework.Functions.GetPlayer(source)
    if not Player then return false end
    
    -- Check if player has admin permission through QBX permissions system
    if permission == "admin" then
        -- Check QBX permission level (if using qbx_core)
        if GetResourceState('qbx_core') == 'started' then
            local hasQbxPerm = exports.qbx_core:HasPermission(source, 'admin')
            if hasQbxPerm then return true end
        end
        
        -- Check player's permission/group field
        local playerPermission = Player.PlayerData.permission or Player.PlayerData.group
        if playerPermission then
            for i = 1, #Config.PermissionsGroups do
                if playerPermission == Config.PermissionsGroups[i] then
                    return true
                end
            end
        end
    end
    
    return false
end

exports('FW_CreateCallback', FW_CreateCallback)
exports("FW_GetPlayer", FW_GetPlayer)
exports("FW_GetPlayerFromCitizenid", FW_GetPlayerFromCitizenid)
exports("FW_CreateUseableItem", FW_CreateUseableItem)
exports("FW_CommandsAdd", FW_CommandsAdd)

exports('GetCoreObject', function()
    return Framework
end)