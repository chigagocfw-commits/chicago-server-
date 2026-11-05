-- Client-side Ankle Tracker System
local hasAnkleTracker = false

-- Request tracker status on player load
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    TriggerServerEvent("origen_police:server:GetAnkleCuff")
end)

-- Handle ankle shock from UI
RegisterNUICallback("AnckleShock", function(data, cb)
    TriggerServerEvent("origen_police:server:ankleshock", data.id)
    cb(true)
end)

-- Add tracker object and clothing
function AddTrackerObj(skipLoop)
    if not hasAnkleTracker then
        return
    end
    
    -- Apply tracker clothing if enabled
    if Config.TrackerCloths and Config.TrackerCloths.enabled then
        local ped = PlayerPedId()
        local model = GetEntityModel(ped)
        local isMale = model == GetHashKey("mp_m_freemode_01")
        
        local clothingId = isMale and Config.TrackerCloths.male or Config.TrackerCloths.female
        
        SetPedComponentVariation(ped, 7, clothingId, 0, 0) -- Component 7 is accessories
    end
    
    if skipLoop then
        return
    end
    
    -- Keep tracker object active
    while hasAnkleTracker do
        AddTrackerObj(true)
        Wait(3000)
    end
end

-- Remove tracker object and clothing
function RemoveTrackerObj()
    hasAnkleTracker = false
    
    -- Remove tracker clothing if enabled
    if Config.TrackerCloths and Config.TrackerCloths.enabled then
        local ped = PlayerPedId()
        SetPedComponentVariation(ped, 7, 0, 0, 0) -- Reset accessory slot
    end
end

-- Place/remove ankle cuff on nearby player
RegisterNetEvent("origen_police:client:anklecuff", function()
    local closestPlayer, distance = FW_GetClosestPlayer()
    local playerPed = PlayerPedId()
    
    if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
        -- Trigger server event
        TriggerServerEvent("origen_police:server:anklecuff", GetPlayerServerId(closestPlayer))
        
        -- Play placement animation
        RequestAnimSet("move_ped_crouched")
        while not HasAnimSetLoaded("move_ped_crouched") do
            Wait(10)
        end
        
        SetPedMovementClipset(playerPed, "move_ped_crouched", 1.0)
        SetPedStrafeClipset(playerPed, "move_ped_crouched_strafing")
        Wait(400)
        
        RequestAnimDict("mp_arresting")
        while not HasAnimDictLoaded("mp_arresting") do
            Wait(1)
        end
        
        TaskPlayAnim(PlayerPedId(), "mp_arresting", "a_uncuff", 8.0, -8.0, -1, 16, 0, 0, 0, 0)
        Wait(5000)
        
        -- Reset movement
        ClearPedTasks(playerPed)
        SetPedStealthMovement(playerPed, false, "DEFAULT_ACTION")
        ResetPedMovementClipset(playerPed, 1.0)
        ResetPedWeaponMovementClipset(playerPed)
        ResetPedStrafeClipset(playerPed)
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end)

-- Set ankle cuff status
RegisterNetEvent("origen_police:client:SetAnkleCuff", function(active)
    if not active then
        RemoveTrackerObj()
        return
    end
    
    hasAnkleTracker = true
    AddTrackerObj()
end)

-- Apply shock effect to player
RegisterNetEvent("origen_police:client:ankleshock", function()
    local animDict = "stungun@standing"
    
    -- Load stun animation
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        RequestAnimDict(animDict)
        Citizen.Wait(0)
    end
    
    local playerPed = PlayerPedId()
    
    -- Play shock animation
    TaskPlayAnim(playerPed, animDict, "damage", 8.0, 1.0, 1500, 1, 0, false, false, false)
    
    -- Apply damage over time
    for i = 0, 15 do
        SetEntityHealth(playerPed, GetEntityHealth(playerPed) - 1)
        Citizen.Wait(100)
    end
    
    -- Ragdoll player
    SetPedToRagdoll(playerPed, 4000, 4000, 0, 0, 0, 0)
end)