-- Tackle System
local isTackling = false
local isRagdoll = false

-- Tackle command
RegisterCommand("placaje", function(source, args, rawCommand)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return
    end
    
    local playerData = FW_GetPlayerData(false)
    
    if not playerData or not playerData.job or not playerData.job.name then
        return false
    end
    
    -- Check grade permissions
    local minimumGrade = GetMinimunGrade(playerData.job.name, "CanTackle")
    local hasPermission = playerData.job.grade.level >= minimumGrade
    
    if not hasPermission then
        return FW_Notify(Config.Translations.CantDoThis)
    end
    
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if canOpen[1] and playerData.job.onduty then
        local closestPlayer, distance = FW_GetClosestPlayer()
        local targetPed = GetPlayerPed(closestPlayer)
        
        if closestPlayer ~= -1 and distance <= 1.5 and distance > 0 then
            if not IsPedInAnyVehicle(targetPed, false) and
               not IsPedInAnyVehicle(PlayerPedId(), false) and
               not IsEntityDead(targetPed) and
               not IsEntityDead(PlayerPedId()) and
               not isTackling then
                
                TriggerServerEvent("origen_police:placaje_sv", GetPlayerServerId(closestPlayer))
                isTackling = true
                
                -- Play tackle animation
                RequestAnimDict("missmic2ig_11")
                while not HasAnimDictLoaded("missmic2ig_11") do
                    Citizen.Wait(10)
                end
                
                TaskPlayAnim(PlayerPedId(), "missmic2ig_11", "mic_2_ig_11_intro_goon", 
                    8.0, -8.0, 3000, 0, 0, false, false, false)
                
                Citizen.Wait(3000)
                isTackling = false
                
                return
            end
        else
            -- Failed tackle - ragdoll player
            if Config.Actions.RagdollInTackleFail then
                ShowNotification(Config.Translations.PersonFar)
                
                RequestAnimDict("missmic2ig_11")
                while not HasAnimDictLoaded("missmic2ig_11") do
                    Citizen.Wait(10)
                end
                
                TaskPlayAnim(PlayerPedId(), "missmic2ig_11", "mic_2_ig_11_intro_goon",
                    8.0, -8.0, 3000, 0, 0, false, false, false)
                
                Citizen.Wait(2200)
                isRagdoll = true
                
                Citizen.CreateThread(function()
                    while true do
                        Citizen.Wait(5)
                        
                        if isRagdoll then
                            SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
                        else
                            break
                        end
                    end
                end)
                
                Citizen.Wait(3000)
                isRagdoll = false
            end
        end
        
        Debuger("Tackle failed data, targetped: " .. targetPed .. 
            ", player: " .. closestPlayer .. ", distance(max 1.5 min 0.01): " .. distance)
    end
end)

-- Receive tackle from server
RegisterNetEvent("origen_police:placaje_cl")
AddEventHandler("origen_police:placaje_cl", function(attackerId)
    if not isTackling then
        isTackling = true
        
        local attackerPed = GetPlayerPed(GetPlayerFromServerId(attackerId))
        
        RequestAnimDict("missmic2ig_11")
        while not HasAnimDictLoaded("missmic2ig_11") do
            Citizen.Wait(10)
        end
        
        -- Attach to attacker
        AttachEntityToEntity(GetPlayerPed(-1), attackerPed, 11816, 
            0.25, 0.5, 0.0, 0.5, 0.5, 180.0, false, false, false, false, 2, false)
        
        -- Play tackled animation
        TaskPlayAnim(GetPlayerPed(-1), "missmic2ig_11", "mic_2_ig_11_intro_p_one",
            8.0, -8.0, 3000, 0, 0, false, false, false)
        
        Citizen.Wait(2200)
        DetachEntity(GetPlayerPed(-1), true, false)
        
        isRagdoll = true
        
        Citizen.CreateThread(function()
            while true do
                Citizen.Wait(5)
                
                if isRagdoll then
                    SetPedToRagdoll(GetPlayerPed(-1), 1000, 1000, 0, 0, 0, 0)
                else
                    break
                end
            end
        end)
        
        Citizen.Wait(3000)
        isRagdoll = false
        isTackling = false
    end
end)