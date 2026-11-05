-- Handle Radio Talking Event
RegisterNetEvent("origen_police:client:talking", function(targetPlayers, isTalking)
    -- Check if radio is enabled and not muted
    if isTalking then
        if not Radio.Enabled or Radio.MultiFrec == "none" then
            return
        end
    end
    
    if Radio.Muted then
        return
    end
    
    ToggleVoice(targetPlayers, isTalking, "radio")
end)

-- Player Loaded Event
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    LoadPlayer()
end)

-- Player Unload Event
RegisterNetEvent("origen_police:client:OnPlayerUnload", function()
    UnLoadPlayer()
end)

-- QBCore Death Event
RegisterNetEvent("qb-ambulancejob:onplayerdeath", function(data)
    Toggle(false)
end)

-- ESX Death Event
RegisterNetEvent("esx:onPlayerDeath", function(data)
    Toggle(false)
end)

-- ESX Revive Event
RegisterNetEvent("esx_ambulancejob:revive", function()
    Toggle(true)
end)

-- Radio Take/Drop Event
RegisterNetEvent("origen_police:client:TakeDropRadio", function(hasRadio)
    if not hasRadio then
        Toggle(false)
        SendNUIMessage({
            action = "DisconnectAllFreqs"
        })
    end
end)