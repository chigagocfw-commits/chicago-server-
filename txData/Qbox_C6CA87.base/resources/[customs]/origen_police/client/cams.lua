local activeCamera = nil

-- Show bodycam from target player
RegisterNetEvent("origen_police:client:ShowBodycam", function(coords, targetPlayerId)
    if not activeCamera then
        HideHUD()
        SendNUIMessage({ action = "SetBodyCamEnabled" })
        
        DoScreenFadeOut(300)
        
        -- Create camera at target location
        activeCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords, 0, 0, 0, GetGameplayCamFov())
        SetCamActive(activeCamera, true)
        RenderScriptCams(true, true, 1, true, true)
        SetFocusPosAndVel(coords, 0.0, 0.0, 0.0)
        
        Citizen.Wait(1000)
        
        -- Get target player ped and attach camera
        local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
        AttachCamToPedBone(activeCamera, targetPed, 31086, 0, 0, -0.1, true)
        
        Citizen.CreateThread(function()
            SetTimecycleModifier("helicamfirst")
            SetTimecycleModifierStrength(0.75)
            DoScreenFadeIn(300)
            
            while activeCamera do
                Citizen.Wait(0)
                
                -- Update camera rotation to match ped
                SetCamRot(activeCamera, GetEntityRotation(targetPed))
                SetFocusPosAndVel(GetEntityCoords(targetPed), 0.0, 0.0, 0.0)
                
                -- Exit camera with BACKSPACE
                if IsControlJustPressed(0, 177) then
                    DoScreenFadeOut(300)
                    Citizen.Wait(500)
                    
                    SetCamActive(activeCamera, false)
                    DestroyCam(activeCamera, true)
                    RenderScriptCams(false, false, 0, true, false)
                    activeCamera = nil
                    
                    Citizen.Wait(250)
                    DoScreenFadeIn(300)
                    TriggerEvent("origen_police:client:HideCamHud")
                end
            end
            
            ClearTimecycleModifier()
            ClearFocus()
            ShowHUD()
        end)
    end
end)

-- Show car camera from tracked vehicle
RegisterNetEvent("origen_police:client:ShowCarcam", function(coords, vehicleNetId)
    if not activeCamera then
        DoScreenFadeOut(300)
        HideHUD()
        
        -- Create camera at vehicle location
        activeCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", coords, 0, 0, 0, GetGameplayCamFov())
        SetCamActive(activeCamera, true)
        RenderScriptCams(true, true, 1, true, true)
        SetFocusPosAndVel(coords, 0.0, 0.0, 0.0)
        
        Citizen.Wait(1000)
        
        local vehicle = NetworkGetEntityFromNetworkId(vehicleNetId)
        local cameraOffset = nil
        
        -- Check for custom camera offsets for this vehicle model
        if type(Config.CustomCarOffsets) ~= "table" then
            Config.CustomCarOffsets = {}
        end
        
        for modelName, offset in pairs(Config.CustomCarOffsets) do
            if GetHashKey(modelName) == GetEntityModel(vehicle) then
                cameraOffset = offset
            end
        end
        
        -- Use default offset if no custom offset found
        if cameraOffset == nil then
            cameraOffset = Config.DefaultCarCamOffset
        end
        
        AttachCamToEntity(activeCamera, vehicle, cameraOffset.x, cameraOffset.y, cameraOffset.z, true)
        
        Citizen.CreateThread(function()
            SetTimecycleModifier("helicamfirst")
            SetTimecycleModifierStrength(0.75)
            DoScreenFadeIn(300)
            
            while activeCamera do
                Citizen.Wait(0)
                
                -- Update camera rotation to match vehicle
                SetCamRot(activeCamera, GetEntityRotation(vehicle))
                SetFocusPosAndVel(GetEntityCoords(vehicle), 0.0, 0.0, 0.0)
                
                -- Exit camera with BACKSPACE
                if IsControlJustPressed(0, 177) then
                    DoScreenFadeOut(300)
                    Citizen.Wait(500)
                    
                    SetCamActive(activeCamera, false)
                    DestroyCam(activeCamera, true)
                    RenderScriptCams(false, false, 0, true, false)
                    activeCamera = nil
                    
                    Citizen.Wait(250)
                    DoScreenFadeIn(300)
                    TriggerEvent("origen_police:client:HideCamHud")
                end
            end
            
            ClearTimecycleModifier()
            ClearFocus()
            ShowHUD()
        end)
    end
end)

-- Get cameras in area (CCTV objects)
RegisterNUICallback("GetCamsInArea", function(data, cb)
    cb(GetCamsInArea())
end)

cameraProps = Config.cameraProps

-- Find all camera objects near player
function GetCamsInArea()
    local cameras = {}
    local playerCoords = GetEntityCoords(PlayerPedId())
    local objects = FW_GetObjects()
    
    if type(cameraProps) ~= "table" then
        cameraProps = {}
    end
    
    -- Search for camera props in the world
    for _, propName in pairs(cameraProps) do
        local propHash = GetHashKey(propName)
        
        for i = 1, #objects do
            if GetEntityModel(objects[i]) == propHash then
                local objectCoords = GetEntityCoords(objects[i])
                local distance = #(playerCoords - objectCoords)
                
                if distance < 50 then
                    table.insert(cameras, {
                        obj = objects[i],
                        dist = distance
                    })
                end
            end
        end
    end
    
    -- Sort cameras by distance
    table.sort(cameras, function(a, b)
        return a.dist < b.dist
    end)
    
    return cameras
end

-- Show camera view callback
RegisterNUICallback("ShowCam", function(data, cb)
    cb(true)
    ShowCam(tonumber(data.obj))
end)

-- Show CCTV camera view
function ShowCam(cameraObject)
    if not activeCamera then
        DoScreenFadeOut(300)
        HideHUD()
        
        -- Create camera at CCTV object
        activeCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(cameraObject), 0, 0, 0, GetGameplayCamFov())
        SetCamActive(activeCamera, true)
        RenderScriptCams(true, true, 1, true, true)
        
        Citizen.Wait(1000)
        
        AttachCamToEntity(activeCamera, cameraObject, 0.0, 0.0, 0.0, true)
        
        Citizen.CreateThread(function()
            SetTimecycleModifier("helicamfirst")
            SetTimecycleModifierStrength(0.75)
            DoScreenFadeIn(300)
            
            -- Set camera angle
            SetCamRot(activeCamera, GetEntityRotation(cameraObject) - vector3(35, 0, 180))
            
            local cameraWorking = true
            FreezeEntityPosition(PlayerPedId(), true)
            local wasRadarHidden = IsRadarHidden()
            
            while activeCamera do
                DisplayRadar(false)
                Citizen.Wait(0)
                
                -- Check if camera object is destroyed
                if cameraWorking then
                    if not DoesEntityExist(cameraObject) or GetEntityHealth(cameraObject) < 900 then
                        cameraWorking = false
                        SendNUIMessage({
                            action = "nosignal",
                            toggle = true
                        })
                    end
                end
                
                -- Exit camera with BACKSPACE
                if IsControlJustPressed(0, 177) then
                    DoScreenFadeOut(300)
                    Citizen.Wait(500)
                    
                    SetCamActive(activeCamera, false)
                    DestroyCam(activeCamera, true)
                    RenderScriptCams(false, false, 0, true, false)
                    activeCamera = nil
                    
                    Citizen.Wait(250)
                    DoScreenFadeIn(300)
                    TriggerEvent("origen_police:client:HideCamHud")
                end
            end
            
            DisplayRadar(not wasRadarHidden)
            FreezeEntityPosition(PlayerPedId(), false)
            ClearTimecycleModifier()
            SendNUIMessage({
                action = "nosignal",
                toggle = false
            })
            ShowHUD()
        end)
    end
end

-- Toggle body camera recording
RegisterNUICallback("SetBodyCamEnabled", function(data, cb)
    local enabled = data.value
    TriggerServerEvent("origen_police:server:DisableBodyCam", enabled)
    cb(true)
end)