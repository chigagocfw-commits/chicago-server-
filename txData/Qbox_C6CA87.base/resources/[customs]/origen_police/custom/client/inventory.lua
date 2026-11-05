function OpenStash(id, label, slots, weight, owner, private)
    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory" or
        Config.Inventory == "codem-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "stash", id, {
            maxweight = weight,
            slots = slots,
            label = label
        })
        TriggerEvent("inventory:client:SetCurrentStash", id)
    else
        FW_TriggerCallback("origen_police:server:OpenPoliceStash", function(data)
            if not owner then
                local PlayerData = FW_GetPlayerData(false)
                owner = PlayerData.citizenid
            end
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('stash', {id=id, owner = owner})
            elseif Config.Inventory == "tgiann-inventory" then
                exports["tgiann-inventory"]:OpenInventory('stash', id, nil, nil)
            end
        end, id, label, slots, weight, private)
    end
end

function OpenArmoury()
    if  Config.Inventory == "qb-inventory" or
        Config.Inventory == "origen_inventory" or
        Config.Inventory == "qs-inventory" or
        Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "shop", "Equipment", Config.Armory)
    elseif Config.Inventory == "codem-inventory" then
        TriggerEvent('codem-inventory:OpenPlayerShop', Config.Armory.items)
    else
        FW_TriggerCallback("origen_police:server:OpenPoliceArmoury", function(data)
            if Config.Inventory == "ox_inventory" then
                exports.ox_inventory:openInventory('shop', { type = 'OrigenPoliceArmoury', id = 1})
            end
        end)
    end
end

function OpenOtherPlayerInv(pID)
    if Config.Inventory == 'ox_inventory' then
        exports.ox_inventory:openNearbyInventory()
    elseif  Config.Inventory == 'qb-inventory' or
            Config.Inventory == "origen_inventory" or
            Config.Inventory == 'qs-inventory'or
            Config.Inventory == "ls-inventory"
    then
        TriggerServerEvent("inventory:server:OpenInventory", "otherplayer", pID)
    elseif Config.Inventory == 'codem-inventory' then
        TriggerEvent('codem-inventory:client:openplayerinventory', pID)
        local isClose = true
        CreateThread(function()
            while isClose do
                local targetPed = GetPlayerPed(GetPlayerFromServerId(pID))
                if not targetPed then isClose = false return end
                local targetCoords = GetEntityCoords(targetPed)
                local playerCoords = GetEntityCoords(PlayerPedId())
                if #(targetCoords - playerCoords) >= 4.0 then
                    TriggerServerEvent('origen_police:server:SetInventoryRobStatus', pID, false)
                    isClose = false
                end
                Wait(3)
            end
        end)
    elseif Config.Inventory == 'core_inventory' then
        TriggerServerEvent('core_inventory:server:openInventory', pID, 'otherplayer', nil, nil, false)
    else
        TriggerServerEvent("origen_police:server:OpenOtherPlayerInv", pID)
    end
end

local animsToSearch = {
    { dict = 'mp_arresting', anim = 'idle', flag = 49 },
    { dict = 'mp_arresting', anim = 'idle', flag = 51 },
    { dict = 'dead', anim = 'dead_a', flag = 3 },
}

function CanSearchPlayer(player)
    local targetPed = GetPlayerPed(player)
    
    -- Check if dead
    if IsEntityDead(targetPed) or IsPedDeadOrDying(targetPed, true) then
        return true
    end
    
    -- Check if playing cuffed animation with any flag
    if IsEntityPlayingAnim(targetPed, 'mp_arresting', 'idle', 49) or
       IsEntityPlayingAnim(targetPed, 'mp_arresting', 'idle', 51) or
       IsEntityPlayingAnim(targetPed, 'mp_arresting', 'idle', 3) then
        return true
    end
    
    return false
end

function StartSearchDistance(targetId)
    -- Monitor distance while searching
    Citizen.CreateThread(function()
        local searching = true
        while searching do
            Citizen.Wait(500)
            
            local targetPlayer = GetPlayerFromServerId(targetId)
            if targetPlayer == -1 then
                searching = false
                break
            end
            
            local targetPed = GetPlayerPed(targetPlayer)
            local playerPed = PlayerPedId()
            local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
            
            -- Close inventory if too far
            if distance > 3.5 then
                searching = false
                -- Close inventory based on framework
                if Config.Inventory == 'ox_inventory' then
                    exports.ox_inventory:closeInventory()
                elseif Config.Inventory == 'qb-inventory' or 
                       Config.Inventory == 'origen_inventory' or
                       Config.Inventory == 'qs-inventory' or
                       Config.Inventory == 'ls-inventory' then
                    TriggerEvent('qb-inventory:client:closeinv')
                elseif Config.Inventory == 'codem-inventory' then
                    TriggerEvent('codem-inventory:close')
                end
                ShowNotification(Config.Translations.PersonFar or "Player is too far away")
            end
            
            -- Stop if inventory is closed
            if Config.Inventory == 'ox_inventory' then
                if not exports.ox_inventory:isOpen() then
                    searching = false
                end
            end
        end
    end)
end

function SearchClosestPlayer(playerId)
    local ped = PlayerPedId()
    ProgressBar("search_player_inv", "Searching", 3000, false, true, {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "anim@gangops@facility@servers@bodysearch@",
        anim = "player_search",
        flags = 49,
    }, {}, {}, function()
        StopAnimTask(ped, "anim@gangops@facility@servers@bodysearch@", "player_search", 1.0)
        OpenOtherPlayerInv(playerId)
        StartSearchDistance(playerId)
    end)
end

function StartSearchDistance(targetId)
    -- Monitor distance while searching
    Citizen.CreateThread(function()
        local searching = true
        while searching do
            Citizen.Wait(500)
            
            local targetPlayer = GetPlayerFromServerId(targetId)
            if targetPlayer == -1 then
                searching = false
                break
            end
            
            local targetPed = GetPlayerPed(targetPlayer)
            local playerPed = PlayerPedId()
            local distance = #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed))
            
            -- Close inventory if too far
            if distance > 3.5 then
                searching = false
                -- Close inventory based on framework
                if Config.Inventory == 'ox_inventory' then
                    exports.ox_inventory:closeInventory()
                elseif Config.Inventory == 'qb-inventory' or 
                       Config.Inventory == 'origen_inventory' or
                       Config.Inventory == 'qs-inventory' or
                       Config.Inventory == 'ls-inventory' then
                    TriggerEvent('qb-inventory:client:closeinv')
                elseif Config.Inventory == 'codem-inventory' then
                    TriggerEvent('codem-inventory:close')
                end
                ShowNotification(Config.Translations.PersonFar or "Player is too far away")
            end
            
            -- Stop if inventory is closed
            if Config.Inventory == 'ox_inventory' then
                if not exports.ox_inventory:isOpen() then
                    searching = false
                end
            end
        end
    end)
end

-- Register search command
RegisterCommand("cachearPolice", function()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    -- Check if player has permission to search
    if canOpen[1] and playerData.job.onduty then
        local closestPlayer, distance = FW_GetClosestPlayer()
        
        if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
            local targetPed = GetPlayerPed(closestPlayer)
            local targetServerId = GetPlayerServerId(closestPlayer)
            
            -- Check if target can be searched
            if CanSearchPlayer(closestPlayer) then
                SearchClosestPlayer(targetServerId)
            else
                ShowNotification(Config.Translations.HasToBeCuffed or "Player must be cuffed or dead", "error")
            end
        else
            ShowNotification(Config.Translations.NoPersonNear or "No player nearby", "error")
        end
    else
        ShowNotification(Config.Translations.CantDoThis or "You cannot do this", "error")
    end
end, false)

function GiveVehicleKeys(vehicle)
    -- Your code here
end

function GetPlayerItems(PlayerData)
    if Config.Inventory == "qs-inventory" then
        return exports['qs-inventory']:getUserInventory() or {}
    elseif Config.Inventory == "ls-inventory" then
        return exports["ls-inventory"]:GetPlayerItems() or {}
    elseif Config.Inventory == "origen_inventory" then
        return exports.origen_inventory:GetInventory() or {}
    elseif Config.Inventory == "ox_inventory" then
        return exports.ox_inventory:GetPlayerItems() or {}
    elseif Config.Inventory == "codem-inventory" then
        return exports["codem-inventory"]:GetClientPlayerInventory() or {}
    elseif Config.Inventory == 'core_inventory' then
        local inventory = -1
        FW_TriggerCallback("core_inventory:server:getInventory", function(data)
            inventory = data
        end)
        while inventory == -1 do
            Citizen.Wait(0)
        end
        return inventory or {}
    end

    if not PlayerData then
        PlayerData = FW_GetPlayerData()
    end
    return PlayerData.items or {}
end

function GetItemFromWeapon(PlayerData, weapon)
    if Config.Inventory == "core_inventory" then
        local data = exports["core_inventory"]:GetCurrentWeaponData()
        data.label = Config.WeaponsLabels[data.name] or "Unknown"
        return data
    end
    local hashes = {}
    local saveHashes = Config.Debug
    for _, v in pairs(GetPlayerItems(PlayerData)) do
        if saveHashes then
            hashes[v.name] = GetHashKey(v.name)
        end
        if GetHashKey(v.name) == weapon then
            return v
        end
    end
    print("Couldn't find weapon in inventory with hash: " .. weapon .. (saveHashes and " hashes: " .. json.encode(hashes) or ""))
    return nil
end

exports("GetPlayerItems", GetPlayerItems)

function LockInventory(value) -- To avoid the player to open the inventory
    if Config.Inventory == "ox_inventory" then
        return -- Looks like when searching other player inventory ox check if the inv is bussy, cause the player is cuffed agents can't search the inventory of cuffed players
    end
    if GetResourceState("qs-inventory") == "started" then
        exports['qs-inventory']:setInventoryDisabled(value)
    end
    LocalPlayer.state.invBusy = value
end