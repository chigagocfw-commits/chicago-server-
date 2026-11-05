-- Initialize on player spawn
Citizen.CreateThread(function()
    local playerData = FW_GetPlayerData(true)
    
    if playerData then
        LoadPlayer(playerData)
    end
end)

-- Radio Item Detection
local hasRadioItem = false

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(4000)
        
        local playerData = FW_GetPlayerData(false)
        
        if playerData.items then
            local foundRadio = false
            
            -- Check if player has radio item
            for _, item in pairs(playerData.items) do
                if item.name == "radio" then
                    foundRadio = true
                    break
                end
            end
            
            -- Player picked up radio
            if foundRadio and not hasRadioItem then
                hasRadioItem = true
                TriggerEvent("origen_police:client:TakeDropRadio", true)
            end
            
            -- Player dropped radio
            if not foundRadio and hasRadioItem then
                hasRadioItem = false
                TriggerEvent("origen_police:client:TakeDropRadio", false)
            end
        end
    end
end)