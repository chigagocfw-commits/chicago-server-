-- GPS Reference System for Police Units
local references = {}
local blips = {}

-- Set location via NUI
RegisterNUICallback("SetLocation", function(data, cb)
    local value = data.value
    TriggerServerEvent("origen_police:server:setLocation", value)
    cb(true)
end)

-- Listen for reference updates from server
AddStateBagChangeHandler("References", "global", function(bagName, key, value)
    local jobCategory = GetPlayerJobCategory()
    
    if not jobCategory then
        return
    end
    
    local jobReferences = value[jobCategory]
    
    if not jobReferences then
        return
    end
    
    references = jobReferences or {}
end)

-- Remove reference blip
RegisterNetEvent("origen_police:client:removeref", function(serverId, removeAll)
    if removeAll then
        -- Remove all blips
        for id, blip in pairs(blips) do
            RemoveBlip(blip)
            references[id] = nil
        end
        return
    end
    
    -- Remove specific blip
    if blips[serverId] then
        RemoveBlip(blips[serverId])
        blips[serverId] = nil
        references[serverId] = nil
    end
end)

-- Start reference system
function StartReferences()
    Citizen.CreateThread(function()
        DisplayPlayerNameTagsOnBlips(true)
        
        while onduty do
            Citizen.Wait(0)
            
            for serverId, refData in pairs(references) do
                if not refData.hideGPS then
                    -- Check if blip exists
                    if not blips[serverId] or not DoesBlipExist(blips[serverId]) or refData.sync then
                        -- Remove old blip if syncing
                        if refData.sync then
                            RemoveBlip(blips[serverId])
                            refData.sync = nil
                        end
                        
                        -- Create new blip
                        local playerIndex = GetPlayerFromServerId(serverId)
                        
                        if playerIndex ~= -1 then
                            -- Blip for entity (player online)
                            blips[serverId] = AddBlipForEntity(
                                GetPlayerPed(GetPlayerFromServerId(serverId))
                            )
                        else
                            -- Blip for coordinates (player offline)
                            blips[serverId] = AddBlipForCoord(refData.coords)
                        end
                    end
                    
                    -- Set blip properties
                    SetBlipSprite(blips[serverId], 
                        refData.sprite or Config.References.DefaultSprite)
                    SetBlipDisplay(blips[serverId], 2)
                    SetBlipColour(blips[serverId], 
                        refData.color or Config.References.DefaultColor)
                    SetBlipCategory(blips[serverId], 7)
                    
                    -- Set blip label
                    BeginTextCommandSetBlipName("STRING")
                    AddTextComponentSubstringPlayerName(refData.unit .. " - " .. refData.lastname)
                    EndTextCommandSetBlipName(blips[serverId])
                    
                else
                    -- Update existing blip properties
                    if not refData.hideGPS then
                        SetBlipSprite(blips[serverId], 
                            refData.sprite or Config.References.DefaultSprite)
                        SetBlipColour(blips[serverId], 
                            refData.color or Config.References.DefaultColor)
                        
                        BeginTextCommandSetBlipName("STRING")
                        AddTextComponentSubstringPlayerName(refData.unit .. " - " .. refData.lastname)
                        EndTextCommandSetBlipName(blips[serverId])
                        
                        local playerIndex = GetPlayerFromServerId(serverId)
                        
                        if playerIndex == -1 then
                            -- Update coords for offline player
                            SetBlipCoords(blips[serverId], refData.coords)
                        else
                            -- Check if we need to sync blip type
                            local blipType = GetBlipInfoIdType(blips[serverId])
                            if blipType == 4 then
                                refData.sync = true
                            end
                        end
                    else
                        -- Hide GPS - remove blip
                        if refData.hideGPS and blips[serverId] then
                            RemoveBlip(blips[serverId])
                            blips[serverId] = nil
                        end
                    end
                end
            end
        end
        
        -- Clean up all blips when going off duty
        for _, blip in pairs(blips) do
            RemoveBlip(blip)
        end
        
        DisplayPlayerNameTagsOnBlips(false)
    end)
end