-- Police Interaction Script
-- Variables
local minimapState = 1
local isDragging = false
local isDraggingPlayer = false
local translationsReceived = false
local handcuffObject = nil
local isDraggingBackwards = false
local isEscorting = false
local isHandcuffed = false

-- Send translations to NUI
Citizen.CreateThread(function()
    Wait(5000)
    SendNUIMessage({
        action = "translations",
        translations = Config.Translations
    })
end)

-- Minimap size toggle command
RegisterCommand(Config.Commands.Minimap.cmd, function()
    if not Config.ChangeMinimapSize then return end
    if IsNuiFocused() then return end
    
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if canOpen[1] and playerData.job.onduty then
        if minimapState == 3 then
            minimapState = 1
        else
            minimapState = minimapState + 1
        end
        
        if minimapState == 1 then
            SetBigmapActive(false, false)
        elseif minimapState == 2 then
            SetBigmapActive(true, false)
        elseif minimapState == 3 then
            SetBigmapActive(true, true)
        end
    end
end)

RegisterKeyMapping(Config.Commands.Minimap.cmd, Config.Commands.Minimap.description, "keyboard", Config.Commands.Minimap.key)

-- Quick Access Menu
RegisterCommand(Config.Commands.QuickAccess.cmd, function(source, args, rawCommand)
    if IsNuiFocused() then return end
    
    local playerData = FW_GetPlayerData(false)
    
    if CanOpenQuickAccessMenu() then
        SendNUIMessage({
            action = "OpenQuickAccess",
            translations = translationsReceived and Config.Translations or nil,
            permissions = exports.origen_police:GerPermissions(),
            jobData = {
                duty = playerData.job.onduty,
                name = playerData.job.name,
                level = playerData.job.grade.level
            },
            options = {
                confiscate = Config.Confiscate,
                holster = Config.Holster
            }
        })
        
        SetNuiFocus(true, Config.Actions.QuickAccessShowCursor)
        
        Citizen.CreateThread(function()
            SetNuiFocusKeepInput(Config.Actions.QuickAccessKeepInput)
            
            while IsNuiFocused() do
                Citizen.Wait(0)
                DisableAllControlActions(0)
                EnableControlAction(0, 249, true)
                EnableControlAction(1, 249, true)
                EnableControlAction(2, 249, true)
                
                for _, input in pairs(Config.Actions.QuickAccessAllowedInputs) do
                    EnableControlAction(0, input, true)
                end
            end
            
            SetNuiFocusKeepInput(false)
            
            while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
                Citizen.Wait(0)
                DisableControlAction(0, 200, true)
            end
            
            DisableControlAction(0, 200, true)
        end)
    end
end)

RegisterNUICallback("translationsRecived", function(data, cb)
    translationsReceived = true
    cb(true)
end)

RegisterKeyMapping(Config.Commands.QuickAccess.cmd, Config.Commands.QuickAccess.description, "keyboard", Config.Commands.QuickAccess.key)

-- NUI Callbacks
RegisterNUICallback("notification", function(data, cb)
    ShowNotification(data)
    cb(true)
end)

local lastActionTime = 0

RegisterNUICallback("quickaction", function(data, cb)
    local eventName = data.event or data.serverevent
    
    -- Security check
    if eventName then
        if not eventName:find("^origen_police") then
            Debuger("Trying to execute event with unknown name")
            return cb(false)
        end
        
        local currentTime = GetGameTimer()
        if (currentTime - lastActionTime) <= 500 then
            Debuger("Trying too fast with action: " .. eventName .. ", remaining time: " .. (currentTime - lastActionTime))
            return ShowNotification("You are doing this too fast")
        end
        
        lastActionTime = GetGameTimer()
    end
    
    -- Handle different actions
    if data.action == "ReferenceIcon" then
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped then
                local passengers = {}
                for seat = -1, 0 do
                    local passenger = GetPedInVehicleSeat(vehicle, seat)
                    if passenger ~= 0 then
                        table.insert(passengers, GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)))
                    end
                end
                TriggerServerEvent("origen_police:server:updateref", {sprite = tonumber(data.id)}, passengers)
            else
                TriggerServerEvent("origen_police:server:updateref", {sprite = tonumber(data.id)})
            end
        else
            TriggerServerEvent("origen_police:server:updateref", {sprite = tonumber(data.id)})
        end
        
    elseif data.action == "ReferenceColor" then
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped then
                local passengers = {}
                for seat = -1, 0 do
                    local passenger = GetPedInVehicleSeat(vehicle, seat)
                    if passenger ~= 0 then
                        table.insert(passengers, GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)))
                    end
                end
                TriggerServerEvent("origen_police:server:updateref", {color = tonumber(data.id)}, passengers)
            else
                TriggerServerEvent("origen_police:server:updateref", {color = tonumber(data.id)})
            end
        else
            TriggerServerEvent("origen_police:server:updateref", {color = tonumber(data.id)})
        end
        
    elseif data.action == "ToggleReady" then
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        
        if vehicle ~= 0 then
            if GetPedInVehicleSeat(vehicle, -1) == ped or GetPedInVehicleSeat(vehicle, 0) == ped then
                local passengers = {}
                for seat = -1, 0 do
                    local passenger = GetPedInVehicleSeat(vehicle, seat)
                    if passenger ~= 0 then
                        table.insert(passengers, GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)))
                    end
                end
                TriggerServerEvent("origen_police:server:Ready", Config.PoliceJobName, data.state, passengers)
            else
                TriggerServerEvent("origen_police:server:Ready", Config.PoliceJobName, data.state)
            end
        else
            TriggerServerEvent("origen_police:server:Ready", Config.PoliceJobName, data.state)
        end
        
    elseif data.action == "RadioCalls" then
        Calls(data.id)
        
    elseif data.command then
        if type(data.command) == "table" then
            for framework, cmd in pairs(data.command) do
                if framework == Config.Framework then
                    ExecuteCommand(cmd)
                end
            end
        else
            ExecuteCommand(data.command)
        end
        
    elseif data.event then
        TriggerEvent(data.event)
        
    elseif data.serverevent then
        TriggerServerEvent(data.serverevent)
    end
    
    cb(true)
end)

-- Handcuff/Uncuff Command
RegisterCommand("esposar", function()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if canOpen[1] then
        local currentTime = GetGameTimer()
        if (currentTime - lastActionTime) <= 500 then
            return ShowNotification("You are doing this too fast")
        end
        
        lastActionTime = GetGameTimer()
        TriggerEvent("origen_police:client:cuffuncuff")
    end
end)

-- Handcuff State Management
RegisterNetEvent("origen_police:client:setcuffstate", function(targetId)
    isHandcuffed = not isHandcuffed
    
    Citizen.CreateThread(function()
        TriggerServerEvent("origen_police:server:playcuffanim", targetId, isHandcuffed)
        
        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetId))
        SetEntityCoords(PlayerPedId(), GetEntityCoords(targetPed) + GetEntityForwardVector(targetPed))
        SetEntityHeading(PlayerPedId(), GetEntityHeading(targetPed))
        
        Citizen.Wait(5000)
        
        local ped = PlayerPedId()
        LockInventory(isHandcuffed)
        
        while isHandcuffed do
            Citizen.Wait(0)
            GiveWeaponToPed(ped, GetHashKey("WEAPON_UNARMED"), 0, false, true)
            
            for _, input in pairs(Config.HandCuff.BlockedInputs) do
                DisableControlAction(0, input, true)
            end
            
            if not IsEntityPlayingAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3) then
                TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, 8.0, -1, 51, false, false, false)
            end
        end
    end)
end)

-- Arrest Animation (Officer)
RegisterNetEvent("origen_police:client:playarrestanim", function(isCuffing)
    RequestAnimDict(Config.HandCuff.Anims.Cuffing.dict)
    while not HasAnimDictLoaded(Config.HandCuff.Anims.Cuffing.dict) do
        Wait(1)
    end
    
    RequestAnimDict(Config.HandCuff.Anims.Uncuffing.dict)
    while not HasAnimDictLoaded(Config.HandCuff.Anims.Uncuffing.dict) do
        Wait(1)
    end
    
    if isCuffing then
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Cuffing.dict, Config.HandCuff.Anims.Cuffing.anim, 8.0, -8.0, 3750, 2, 0, 0, 0, 0)
    else
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Uncuffing.dict, Config.HandCuff.Anims.Uncuffing.anim, 8.0, -8.0, -1, 2, 0, 0, 0, 0)
    end
    
    Citizen.Wait(3500)
    ClearPedTasks(PlayerPedId())
end)

-- Being Arrested Animation (Suspect)
RegisterNetEvent("origen_police:client:playarrestedanim", function(isCuffing)
    RequestAnimDict(Config.HandCuff.Anims.BeingCuffed.dict)
    while not HasAnimDictLoaded(Config.HandCuff.Anims.BeingCuffed.dict) do
        Wait(1)
    end
    
    RequestAnimDict(Config.HandCuff.Anims.BeingUncuffed.dict)
    while not HasAnimDictLoaded(Config.HandCuff.Anims.BeingUncuffed.dict) do
        Wait(1)
    end
    
    local ped = PlayerPedId()
    
    if isCuffing then
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingCuffed.dict, Config.HandCuff.Anims.BeingCuffed.anim, 8.0, -8.0, 3750, 2, 0, 0, 0, 0)
        
        if not Config.HandCuff.SkillCheck.enabled then
            Wait(3500)
            local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
            handcuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handcuffObject, ped, GetPedBoneIndex(ped, 60309), -0.02, 0.06, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
            return
        end
        
        local skillCheckResult = nil
        Citizen.CreateThread(function()
            skillCheckResult = Config.HandCuff.SkillCheck.func()
        end)
        
        Citizen.Wait(Config.HandCuff.SkillCheck.WaitChance)
        
        if not skillCheckResult then
            local coords = GetEntityCoords(GetPlayerPed(PlayerId()), false)
            handcuffObject = CreateObject(GetHashKey("p_cs_cuffs_02_s"), coords.x, coords.y, coords.z, true, true, true)
            AttachEntityToEntity(handcuffObject, ped, GetPedBoneIndex(ped, 60309), -0.02, 0.06, 0.03, 290.0, 155.0, 80.0, true, false, false, false, 0, true)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8.0, -1, 49, 0.0, false, false, false)
        else
            isHandcuffed = false
            ClearPedTasks(PlayerPedId())
        end
    else
        if handcuffObject ~= nil then
            DetachEntity(handcuffObject, true, true)
            DeleteEntity(handcuffObject)
            handcuffObject = nil
        end
        
        TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.BeingUncuffed.dict, Config.HandCuff.Anims.BeingUncuffed.anim, 8.0, -8.0, -1, 2, 0, 0, 0, 0)
        Citizen.Wait(3500)
        ClearPedTasks(PlayerPedId())
    end
end)

-- Remove Handcuffs Function
function RemoveHandCuff()
    isHandcuffed = false
    
    if handcuffObject ~= nil then
        DetachEntity(handcuffObject, true, true)
        DeleteEntity(handcuffObject)
        handcuffObject = nil
    end
    
    ClearPedTasks(PlayerPedId())
end

exports("RemoveHandCuff", RemoveHandCuff)
exports("origenPoliceCuff", origen_police_cuffuncuff)

-- Handcuff/Uncuff Event
RegisterNetEvent("origen_police:client:cuffuncuff", function()
    origen_police_cuffuncuff()
end)

function origen_police_cuffuncuff()
    if IsPedInAnyVehicle(PlayerPedId(), false) then return end
    
    handCuff(function(canCuff)
        if canCuff then
            local closestPlayer, distance = FW_GetClosestPlayer()
            
            if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
                if not isDraggingPlayer then
                    TriggerServerEvent("origen_police:server:cuffuncuffplayer", GetPlayerServerId(closestPlayer))
                else
                    ShowNotification(Config.Translations.CantUncuff, "error")
                end
            else
                ShowNotification(Config.Translations.NoPersonNear, "error")
            end
        else
            ShowNotification(Config.Translations.CantDoThis, "error")
        end
    end)
end

-- Drag Player Function
function origen_police_drag()
    local closestPlayer, distance = FW_GetClosestPlayer()
    
    if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
        local targetPed = GetPlayerPed(closestPlayer)
        local isNotAttached = not IsEntityAttachedToEntity(targetPed, PlayerPedId())
        local isCuffed = isNotAttached and IsEntityPlayingAnim(targetPed, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 3) or isDraggingPlayer
        
        if isCuffed then
            TriggerServerEvent("origen_police:server:dragplayer", GetPlayerServerId(closestPlayer), isNotAttached)
            isDraggingPlayer = isNotAttached and GetPlayerServerId(closestPlayer) or false
            
            Citizen.CreateThread(function()
                RequestAnimDict("amb@world_human_drinking@coffee@male@base")
                while not HasAnimDictLoaded("amb@world_human_drinking@coffee@male@base") do
                    Citizen.Wait(10)
                end
                
                while isDraggingPlayer and DoesEntityExist(targetPed) and IsPedOnFoot(targetPed) and not IsPedDeadOrDying(targetPed, true) do
                    Citizen.Wait(100)
                    
                    if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 3) then
                        TaskPlayAnim(PlayerPedId(), "amb@world_human_drinking@coffee@male@base", "base", 8.0, 8.0, -1, 49, false, false, false)
                    end
                end
                
                isDraggingPlayer = false
                ClearPedTasks(PlayerPedId())
            end)
        else
            ShowNotification(Config.Translations.HasToBeCuffed, "error")
        end
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end

-- Set Drag State (Being Dragged)
function origen_police_setdragstate(state, draggedBy)
    isDragging = state
    
    if state then
        local isWalking = false
        local ped = PlayerPedId()
        local draggerId = GetPlayerFromServerId(draggedBy)
        local draggerPed = GetPlayerPed(draggerId)
        
        AttachEntityToEntity(ped, draggerPed, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        
        Citizen.CreateThread(function()
            while isDragging and DoesEntityExist(draggerPed) and IsPedOnFoot(draggerPed) and not IsPedDeadOrDying(draggerPed, true) do
                Citizen.Wait(100)
                
                ped = PlayerPedId()
                draggerPed = GetPlayerPed(draggerId)
                
                if not IsEntityAttachedToEntity(ped, draggerPed) then
                    AttachEntityToEntity(ped, draggerPed, 11816, 0.28, 0.43, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                end
                
                if GetEntitySpeed(draggerPed) > 0.1 then
                    isWalking = true
                    local targetSpeed = GetEntitySpeed(draggerPed) > 2.0 and 2.0 or 1.0
                    TaskGoStraightToCoord(ped, GetEntityCoords(ped) + (GetEntityForwardVector(ped) * 5.0), targetSpeed, -1, GetEntityHeading(ped), 0.0)
                else
                    if isWalking then
                        isWalking = false
                        ClearPedTasks(ped)
                    end
                end
            end
            
            isDragging = false
            DetachEntity(PlayerPedId(), true, false)
            ClearPedTasks(ped)
        end)
    else
        DetachEntity(PlayerPedId(), true, false)
    end
end

RegisterNetEvent("origen_police:client:setdragstate", function(state, draggedBy)
    origen_police_setdragstate(state, draggedBy)
end)

RegisterNetEvent("origen_police:client:drag", function()
    origen_police_drag()
end)

-- Vehicle In/Out Function
function origen_police_vehicleinof()
    local closestPlayer, distance = FW_GetClosestPlayer()
    local closestVehicle = FW_GetClosestVehicle()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if not (canOpen[1] and playerData.job.onduty) then return end
    
    if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
        local vehicleCoords = GetEntityCoords(closestVehicle)
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        if #(vehicleCoords - playerCoords) < 5 then
            if isDraggingPlayer then
                isDraggingPlayer = false
                ClearPedTasks(PlayerPedId())
                TriggerServerEvent("origen_police:server:dragplayer", GetPlayerServerId(closestPlayer), false)
            end
            
            if not IsPedInAnyVehicle(GetPlayerPed(closestPlayer), false) then
                local maxSeats = GetVehicleModelNumberOfSeats(GetEntityModel(closestVehicle)) - 2
                
                for seat = 0, maxSeats do
                    if IsVehicleSeatFree(closestVehicle, maxSeats - seat) then
                        UseCommand("me", Config.Translations.VehicleinofME)
                        TriggerServerEvent("origen_police:server:vehicleinof", GetPlayerServerId(closestPlayer), NetworkGetNetworkIdFromEntity(closestVehicle), maxSeats - seat)
                        return
                    end
                end
                
                ShowNotification(Config.Translations.noSeat)
            else
                UseCommand("me", Config.Translations.VehicleofinME)
                TriggerServerEvent("origen_police:server:vehicleinof", GetPlayerServerId(closestPlayer))
            end
        end
    else
        ShowNotification(Config.Translations.NoPersonNear)
    end
end

function origen_police_statevehicleinof(vehicleNetId, seatIndex)
    if vehicleNetId then
        TaskWarpPedIntoVehicle(PlayerPedId(), NetworkGetEntityFromNetworkId(vehicleNetId), seatIndex)
    else
        TaskLeaveVehicle(PlayerPedId(), GetVehiclePedIsIn(PlayerPedId(), false), 16)
        
        if isHandcuffed then
            Wait(100)
            TaskPlayAnim(PlayerPedId(), Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, 8.0, -1, 51, false, false, false)
        end
    end
end

RegisterCommand("vehicleinof", function()
    origen_police_vehicleinof()
end)

RegisterNetEvent("origen_police:client:vehicleinof", function()
    origen_police_vehicleinof()
end)

RegisterNetEvent("origen_police:client:statevehicleinof", function(vehicleNetId, seatIndex)
    origen_police_statevehicleinof(vehicleNetId, seatIndex)
end)

-- Search Player Function
function SearchClosest()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if not (canOpen[1] and playerData.job.onduty) then return end
    
    local closestPlayer, distance = FW_GetClosestPlayer()
    
    if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
        if CanSearchPlayer(closestPlayer) then
            local targetServerId = GetPlayerServerId(closestPlayer)
            SearchClosestPlayer(targetServerId)
        else
            ShowNotification(Config.Translations.NotCuffed, "error")
        end
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end

RegisterCommand("cachearPolice", SearchClosest)

-- Search Distance Check
function StartSearchDistance(targetId)
    Citizen.Wait(300)
    
    while true do
        Citizen.Wait(50)
        
        local targetPlayer = GetPlayerFromServerId(targetId)
        local targetPed = GetPlayerPed(targetPlayer)
        local targetCoords = GetEntityCoords(targetPed)
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        if false == false then break end
        
        if #(targetCoords - playerCoords) > 4 then
            TriggerEvent(Config.Inventory .. ":closeInv")
            TriggerEvent(Config.Inventory .. ":client:closeInventory")
            ShowNotification(Config.Translations.PersonFar, "error")
            break
        end
    end
end

-- Export IsHandcuffed
exports("IsHandcuffed", function()
    return isHandcuffed
end)

AddReplaceExport("qb-policejob", "IsHandcuffed", function()
    return isHandcuffed
end)

-- Animation Helper
local function LoadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(5)
    end
end

-- Walk Backwards Commands
local function StartWalkBackwards()
    if isDraggingBackwards then
        LoadAnimDict("move_strafe@first_person@generic")
        TaskPlayAnim(PlayerPedId(), "move_strafe@first_person@generic", "walk_bwd_180_loop", 3.0, 1.0, -1, 1, 0, 0, 0, 0)
    end
end

local function StopWalkBackwards()
    if isDraggingBackwards then
        LoadAnimDict("move_strafe@first_person@generic")
        TaskPlayAnim(PlayerPedId(), "move_strafe@first_person@generic", "exit", 3.0, 1.0, -1, 1, 0, 0, 0, 0)
    end
end

-- Get Dragged Event
RegisterNetEvent("origen_police:client:getDragged", function(draggerId, dragType)
    local draggerPed = GetPlayerPed(GetPlayerFromServerId(draggerId))
    local ped = PlayerPedId()
    
    if dragType == "escort" then
        if not isEscorting then
            ClearPedTasks(ped)
            isEscorting = true
            LoadAnimDict(Config.HandCuff.Anims.Cuffing.dict)
            LoadAnimDict("move_m@generic_variations@walk")
            TaskPlayAnim(ped, Config.HandCuff.Anims.Idle.dict, Config.HandCuff.Anims.Idle.anim, 8.0, -8, -1, 49, 0.0, false, false, false)
            AttachEntityToEntity(ped, draggerPed, 1816, 0.25, 0.49, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
        else
            isEscorting = false
            DetachEntity(ped)
            ClearPedTasks(ped)
        end
        
    elseif dragType == "stopdrag" then
        isEscorting = false
        DetachEntity(ped)
        ClearPedTasks(ped)
        
    else
        if not isEscorting then
            isEscorting = true
            ClearPedTasks(ped)
            LoadAnimDict("combat@drag_ped@")
            TaskPlayAnim(ped, "combat@drag_ped@", "injured_drag_ped", 8.0, -8, -1, 5, 0, false, false, false)
            AttachEntityToEntity(ped, draggerPed, 1816, 4103, 0.48, 0.0, 0.0, 0.0, 0.0, 0.0)
        else
            isEscorting = false
            DetachEntity(ped)
            ClearPedTasks(ped)
        end
    end
end)

-- Do Animation Event
RegisterNetEvent("origen_police:client:doAnimation", function(animType)
    local ped = PlayerPedId()
    
    if animType == "escort" then
        if isHandcuffed then
            ClearPedTasks(ped)
            isHandcuffed = false
        else
            isHandcuffed = true
            LoadAnimDict("amb@world_human_drinking@coffee@male@base")
            
            if IsEntityPlayingAnim(ped, "amb@world_human_drinking@coffee@male@base", "base", 3) ~= 1 then
                TaskPlayAnim(ped, "amb@world_human_drinking@coffee@male@base", "base", 8.0, -8, -1, 51, 0, false, false, false)
            end
        end
        
    elseif animType == "stopdrag" then
        ClearPedTasks(ped)
        
    else
        if isDraggingBackwards then
            ClearPedTasks(ped)
            isDraggingBackwards = false
        else
            isDraggingBackwards = true
            LoadAnimDict("combat@drag_ped@")
            
            if IsEntityPlayingAnim(ped, "combat@drag_ped@", "injured_drag_plyr", 3) ~= 1 then
                TaskPlayAnim(ped, "combat@drag_ped@", "injured_drag_plyr", 8.0, -8, -1, 51, 0, false, false, false)
            end
        end
    end
end)

-- Drag Command
RegisterCommand("drag", function()
    local playerData = FW_GetPlayerData(false)
    local canOpen = CanOpenTablet(playerData.job.name)
    
    if not (canOpen[1] and playerData.job.onduty) then return end
    
    local closestPlayer, distance = FW_GetClosestPlayer()
    
    if closestPlayer ~= -1 and distance <= 3.0 then
        TriggerServerEvent("origen_police:server:attachPlayer", GetPlayerServerId(closestPlayer), "drag")
    else
        ShowNotification(Config.Translations.NoPersonNear, "error")
    end
end, false)

-- Walk Backwards Commands
RegisterCommand("+walkBackwards", StartWalkBackwards, false)
RegisterCommand("-walkBackwards", StopWalkBackwards, false)

-- Stop Walk/Drag Command
RegisterCommand("StopWalkDrag", function()
    if isDraggingBackwards then
        ClearPedTasks(PlayerPedId())
        isDraggingBackwards = false
        
        local closestPlayer, distance = FW_GetClosestPlayer()
        
        if closestPlayer ~= -1 and distance <= 3.0 then
            TriggerServerEvent("origen_police:server:attachPlayer", GetPlayerServerId(closestPlayer), "stopdrag")
        end
    end
end, false)

-- Key Mappings
if Config.Commands.HandCuff then
    RegisterKeyMapping("esposar", Config.Commands.HandCuff.description, "keyboard", Config.Commands.HandCuff.key)
end

if Config.Commands.QRR then
    RegisterKeyMapping("qrr", Config.Commands.QRR.description, "keyboard", Config.Commands.QRR.key)
end

if Config.Commands.Ten20 then
    RegisterKeyMapping("10-20", Config.Commands.Ten20.description, "keyboard", Config.Commands.Ten20.key)
end

if Config.Commands.Tackle then
    RegisterKeyMapping("placaje", Config.Commands.Tackle.description, "keyboard", Config.Commands.Tackle.key)
end

if Config.Commands.VehicleInto then
    RegisterKeyMapping("vehicleinof", Config.Commands.VehicleInto.description, "keyboard", Config.Commands.VehicleInto.key)
end

RegisterKeyMapping("+walkBackwards", "Walk Backwards", "keyboard", "S")
RegisterKeyMapping("StopWalkDrag", "Cancel drag", "keyboard", "X")

-- Exports
exports("origenPoliceCuff", origen_police_cuffuncuff)
exports("origenPoliceDrag", origen_police_drag)
exports("origenPoliceVehicleInof", origen_police_vehicleinof)