-- Police evidence system - Client side

local cameraActive = false

-- Network event: Use camera
RegisterNetEvent("origen_police:client:usecamera", function(evidences, timestamp, webhookUrl)
    if IsPedInAnyVehicle(PlayerPedId(), false) then
        return
    end
    
    if cameraActive then
        return
    end
    
    cameraActive = true
    
    Citizen.CreateThread(function()
        local defaultFov = GetGameplayCamFov()
        local ped = PlayerPedId()
        local pedCoords = GetEntityCoords(ped) + vector3(0, 0, 0.6)
        local forwardVector = GetEntityForwardVector(ped) * 0.7
        pedCoords = pedCoords + forwardVector
        
        -- Create camera
        local camera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pedCoords, GetEntityRotation(ped, 2), defaultFov)
        local currentFov = defaultFov
        local minimapWasShown = IsMinimapRendering()
        
        SetCamActive(camera, true)
        RenderScriptCams(true, true, 2000, true, false)
        TaskStartScenarioInPlace(ped, "WORLD_HUMAN_PAPARAZZI", 0, 1)
        DisplayRadar(false)
        
        local cameraStartTime = GetGameTimer()
        Citizen.Wait(2000)
        
        -- Apply camera filter
        SetTimecycleModifier("helicamfirst")
        SetTimecycleModifierStrength(0.85)
        
        local streetName = GetStreetNameFromHashKey(GetStreetNameAtCoord(pedCoords.x, pedCoords.y, pedCoords.z))
        local helpShown = false
        
        while cameraActive do
            -- Show help text
            if Config.CustomNotify then
                if not helpShown then
                    if GetResourceState("origen_notify") == "started" then
                        ShowHelpNotification("E", Config.Translations.camera.takepick)
                        ShowHelpNotification("scroll", Config.Translations.camera.zoom)
                        ShowHelpNotification("backspace", Config.Translations.camera.cancel)
                        
                        if Config.Framework == "esx" then
                            CreateThread(function()
                                Wait(0)
                                helpShown = false
                            end)
                        end
                    else
                        ShowHelpNotification("E", Config.Translations.camera.fullText:format("[E]", "[SCROLL]", "[BACKSPACE]"))
                    end
                    helpShown = true
                end
            else
                if Config.Framework == "qbcore" and not helpShown then
                    exports["qb-core"]:DrawText(Config.Translations.camera.fullText:format("[E]", "[SCROLL]", "[BACKSPACE]"))
                    helpShown = true
                elseif Config.Framework == "esx" then
                    Framework.ShowHelpNotification(Config.Translations.camera.fullText:format("~INPUT_CONTEXT~", "~INPUT_WEAPON_WHEEL_PREV~", "~INPUT_FRONTEND_RRIGHT~"))
                end
            end
            
            Citizen.Wait(0)
            
            local playerPos = GetEntityCoords(ped)
            
            -- Draw evidence markers
            if evidences then
                for i = 1, #evidences do
                    local distance = #(playerPos - evidences[i].coords)
                    
                    if distance < Config.EvidenceDrawDistance then
                        local evidenceType = evidences[i].type
                        local evidenceConfig = Config.Evidences[evidenceType]
                        
                        -- Get color
                        local r = evidenceConfig.color.r or evidences[i].color[1]
                        local g = evidenceConfig.color.g or evidences[i].color[2]
                        local b = evidenceConfig.color.b or evidences[i].color[3]
                        
                        DrawMarker(
                            evidenceConfig.sprite,
                            evidences[i].coords,
                            0.0, 0.0, 0.0,
                            0.0, 0.0, 0.0,
                            0.2, 0.2, 0.2,
                            r, g, b, 255,
                            false, false, 0, true
                        )
                        
                        -- Draw count if multiple items
                        if evidences[i].count then
                            DrawText3D(
                                evidences[i].coords.x,
                                evidences[i].coords.y,
                                evidences[i].coords.z + 0.2,
                                "x" .. evidences[i].count
                            )
                        end
                    end
                end
            end
            
            -- Handle zoom
            currentFov = HandleZoom(camera, defaultFov, currentFov)
            
            -- Handle camera rotation
            CheckInputRotation(camera, currentFov)
            
            DisableAllControlActions(0)
            
            -- Draw timestamp and location
            if timestamp then
                Draw2DText(0.5, 0.95, streetName .. " · " .. timestamp, 0.7)
            end
            
            -- E - Take photo
            if IsDisabledControlJustPressed(0, 38) then
                if (GetGameTimer() - cameraStartTime) > 2000 then
                    TriggerServerEvent("origen_police:server:savephoto", TakePhoto(webhookUrl))
                    cameraStartTime = GetGameTimer()
                    cameraActive = false
                end
            end
            
            -- BACKSPACE - Cancel
            if IsDisabledControlJustPressed(0, 177) then
                cameraActive = false
            end
        end
        
        -- Cleanup
        HideHelpNotification()
        ClearTimecycleModifier()
        DisplayRadar(minimapWasShown)
        ClearPedTasks(ped)
        SetCamActive(camera, false)
        DestroyCam(camera, true)
        RenderScriptCams(false, true, 2000, true, false)
    end)
end)

-- Network event: Show photo
RegisterNetEvent("origen_police:client:showphoto", function(photoUrl)
    if not photoUrl then
        print("No photo url received")
        return
    end
    
    SendNUIMessage({
        action = "showphoto",
        url = photoUrl
    })
    
    SetNuiFocus(true, true)
end)

-- Handle camera rotation
function CheckInputRotation(camera, fov)
    local mouseX = GetDisabledControlNormal(0, 220)
    local mouseY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(camera, 2)
    
    if mouseX ~= 0.0 or mouseY ~= 0.0 then
        local newZ = rotation.z + (mouseX * -1.0 * 0.1 * (fov + 0.1))
        local newX = math.max(math.min(65.0, rotation.x + (mouseY * -1.0 * 0.1 * (fov + 0.1))), -65.0)
        
        SetCamRot(camera, newX, 0.0, newZ, 2)
    end
end

-- Handle camera zoom
function HandleZoom(camera, defaultFov, currentFov)
    -- Scroll up - Zoom in
    if IsDisabledControlJustPressed(0, 241) then
        currentFov = math.max(currentFov - 3.0, 5.0)
    end
    
    -- Scroll down - Zoom out
    if IsDisabledControlJustPressed(0, 242) then
        currentFov = math.min(currentFov + 3.0, defaultFov)
    end
    
    local camFov = GetCamFov(camera)
    
    if math.abs(currentFov - camFov) < 0.1 then
        currentFov = camFov
    end
    
    SetCamFov(camera, camFov + (currentFov - camFov) * 0.05)
    
    return currentFov
end

-- Draw 2D text
function Draw2DText(x, y, text, scale)
    SetTextFont(4)
    SetTextProportional(7)
    SetTextScale(scale, scale)
    SetTextColour(255, 255, 255, 255)
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextCentre(true)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
    
    local textLength = string.len(text) / 270
    DrawRect(x, y + 0.025, 0.095 + textLength, 0.05, 0, 0, 0, 155)
end

-- Debug: Visualize restricted zones
if Config.DebugRestrictZones then
    Citizen.CreateThread(function()
        while true do
            local playerPos = GetEntityCoords(PlayerPedId())
            
            for zoneIndex = 1, #Config.RestrictedAlertZones do
                local zone = Config.RestrictedAlertZones[zoneIndex]
                local isInside = isInside(zone, playerPos.x, playerPos.y)
                
                for pointIndex = 1, #zone do
                    local point = zone[pointIndex]
                    local previousPoint = zone[pointIndex - 1]
                    
                    -- Draw point marker
                    Draw3DText(point[1], point[2], playerPos.z, 0.7, pointIndex)
                    
                    -- Draw vertical line
                    DrawLine(point[1], point[2], -10.0, point[1], point[2], 100.0, 255.0, 0.0, 0.0, 255)
                    
                    -- Color based on inside/outside
                    local color = isInside and {0, 255, 0, 100} or {255, 0, 0, 100}
                    
                    -- Draw wall between points
                    if previousPoint then
                        DrawLine(point[1], point[2], 100.0, previousPoint[1], previousPoint[2], 100.0, 255.0, 0.0, 0.0, 255)
                        DrawWall(
                            vector3(point[1], point[2], 0.0),
                            vector3(previousPoint[1], previousPoint[2], 0.0),
                            -10.0,
                            100.0,
                            table.unpack(color)
                        )
                    else
                        -- Connect last point to first
                        local firstPoint = zone[#zone]
                        DrawLine(point[1], point[2], 100.0, firstPoint[1], firstPoint[2], 100.0, 255.0, 0.0, 0.0, 255)
                        DrawWall(
                            vector3(point[1], point[2], 0.0),
                            vector3(firstPoint[1], firstPoint[2], 0.0),
                            -10.0,
                            100.0,
                            table.unpack(color)
                        )
                    end
                end
            end
            
            Wait(0)
        end
    end)
end