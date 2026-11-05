-- Exit if helicopter camera is disabled
if not Config.HeliCam then
    return
end

local heliCamActive = false
local nightVisionActive = false
local thermalVisionActive = false
local currentFOV = (Config.Camara.fov_max + Config.Camara.fov_min) * 0.5

-- Toggle helicopter camera or rappel
function DoCamOrRappel(vehicle)
    local playerPed = PlayerPedId()
    
    if not heliCamActive then
        local driver = GetPedInVehicleSeat(vehicle, -1)
        local passenger = GetPedInVehicleSeat(vehicle, 0)
        
        -- If player is driver or front passenger, activate camera
        if driver == playerPed or passenger == playerPed then
            Citizen.CreateThread(function()
                -- Load scaleform
                local scaleform = RequestScaleformMovie("HELI_CAM")
                while not HasScaleformMovieLoaded(scaleform) do
                    Citizen.Wait(0)
                end
                
                -- Create camera
                local camera = CreateCam("DEFAULT_SCRIPTED_FLY_CAMERA", true)
                AttachCamToEntity(camera, vehicle, 0.0, 0.0, -1.5, true)
                SetCamRot(camera, 0.0, 0.0, GetEntityHeading(vehicle))
                SetCamFov(camera, currentFOV)
                RenderScriptCams(true, false, 0, 1, 0)
                PopScaleformMovieFunctionVoid()
                
                heliCamActive = true
                
                -- Main camera loop
                while heliCamActive and not IsEntityDead(playerPed) and GetEntityHeightAboveGround(vehicle) > 1.5 do
                    Citizen.Wait(0)
                    
                    -- Toggle night vision (RIGHT MOUSE)
                    if IsControlJustPressed(0, 25) then
                        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                        
                        if nightVisionActive then
                            SetNightvision(false)
                            SetSeethrough(false)
                            nightVisionActive = false
                            thermalVisionActive = false
                        else
                            SetNightvision(true)
                            SetSeethrough(false)
                            nightVisionActive = true
                            thermalVisionActive = false
                        end
                    -- Toggle thermal vision (LEFT MOUSE)
                    elseif IsControlJustPressed(0, 24) then
                        PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
                        
                        if thermalVisionActive then
                            SetNightvision(false)
                            SetSeethrough(false)
                            nightVisionActive = false
                            thermalVisionActive = false
                        else
                            SetNightvision(true)
                            SetSeethrough(true)
                            nightVisionActive = false
                            thermalVisionActive = true
                        end
                    end
                    
                    -- Calculate zoom level for controls
                    local zoomRange = Config.Camara.fov_max - Config.Camara.fov_min
                    local zoomValue = (1.0 / zoomRange) * (currentFOV - Config.Camara.fov_min)
                    
                    -- Handle camera rotation
                    CheckInputRotation_h(camera, zoomValue)
                    
                    -- Get vehicle in camera view
                    local targetVehicle = GetVehicleInView(camera)
                    if DoesEntityExist(targetVehicle) then
                        RenderVehicleInfo(targetVehicle)
                    end
                    
                    -- Handle zoom
                    HandleZoom_h(camera)
                    
                    -- Update scaleform UI
                    PushScaleformMovieFunction(scaleform, "SET_ALT_FOV_HEADING")
                    PushScaleformMovieFunctionParameterFloat(GetEntityCoords(vehicle).z)
                    PushScaleformMovieFunctionParameterFloat(zoomValue)
                    PushScaleformMovieFunctionParameterFloat(GetCamRot(camera, 2).z)
                    PopScaleformMovieFunctionVoid()
                    
                    DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
                end
                
                -- Cleanup
                heliCamActive = false
                nightVisionActive = false
                RenderScriptCams(false, false, 0, 1, 0)
                SetScaleformMovieAsNoLongerNeeded(scaleform)
                DestroyCam(camera, false)
                SetNightvision(false)
                SetSeethrough(false)
            end)
        -- Otherwise, rappel from helicopter
        elseif GetEntityHeightAboveGround(vehicle) > 5 then
            PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
            TaskRappelFromHeli(PlayerPedId(), 1092616192)
            
            Citizen.CreateThread(function()
                while GetEntityHeightAboveGround(PlayerPedId()) > 2 do
                    Citizen.Wait(0)
                end
                ClearPedTasks(PlayerPedId())
            end)
        end
    else
        heliCamActive = false
    end
end

-- Handle zoom controls
function HandleZoom_h(camera)
    DisableControlAction(0, 14)  -- Scroll wheel up
    DisableControlAction(0, 15)  -- Scroll wheel down
    DisableControlAction(0, 241) -- Scroll wheel up (secondary)
    DisableControlAction(0, 242) -- Scroll wheel down (secondary)
    
    -- Zoom in
    if IsDisabledControlJustPressed(0, 241) then
        currentFOV = math.max(currentFOV - Config.Camara.zoomspeed, Config.Camara.fov_min)
    end
    
    -- Zoom out
    if IsDisabledControlJustPressed(0, 242) then
        currentFOV = math.min(currentFOV + Config.Camara.zoomspeed, Config.Camara.fov_max)
    end
    
    local currentCamFOV = GetCamFov(camera)
    
    -- Smooth FOV transition
    if math.abs(currentFOV - currentCamFOV) < 0.1 then
        currentFOV = currentCamFOV
    end
    
    SetCamFov(camera, currentCamFOV + (currentFOV - currentCamFOV) * 0.05)
end

-- Handle camera rotation with mouse
function CheckInputRotation_h(camera, zoomValue)
    local mouseX = GetDisabledControlNormal(0, 220)
    local mouseY = GetDisabledControlNormal(0, 221)
    local rotation = GetCamRot(camera, 2)
    
    if mouseX ~= 0.0 or mouseY ~= 0.0 then
        local newZ = rotation.z + (mouseX * -1.0 * Config.Camara.speed_ud * (zoomValue + 0.1))
        local newX = math.max(math.min(20.0, rotation.x + (mouseY * -1.0 * Config.Camara.speed_lr * (zoomValue + 0.1))), -89.5)
        
        SetCamRot(camera, newX, 0.0, newZ, 2)
    end
end

-- Raycast from camera to find vehicle
function GetVehicleInView(camera)
    local cameraCoords = GetCamCoord(camera)
    local forwardVector = RotAnglesToVec(GetCamRot(camera, 2))
    
    local rayHandle = CastRayPointToPoint(
        cameraCoords,
        cameraCoords + forwardVector * 200.0,
        10,
        GetVehiclePedIsIn(GetPlayerPed(-1)),
        0
    )
    
    local _, hit, endCoords, surfaceNormal, entity = GetRaycastResult(rayHandle)
    
    if entity > 0 and IsEntityAVehicle(entity) then
        return entity
    end
    
    return nil
end

-- Convert rotation angles to direction vector
function RotAnglesToVec(rotation)
    local z = math.rad(rotation.z)
    local x = math.rad(rotation.x)
    local num = math.abs(math.cos(x))
    
    return vector3(
        -math.sin(z) * num,
        math.cos(z) * num,
        math.sin(x)
    )
end

-- Display vehicle information on screen
function RenderVehicleInfo(vehicle)
    local model = GetEntityModel(vehicle)
    local vehicleName = Config.CustomCarLabels[model] or GetLabelText(GetDisplayNameFromVehicleModel(model))
    local displayName = GetLabelText(GetDisplayNameFromVehicleModel(vehicleName))
    local plate = GetVehiclePlate(vehicle)
    
    SetTextFont(0)
    SetTextProportional(1)
    SetTextScale(0.0, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextEdge(1, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextEntry("STRING")
    AddTextComponentString(
        Config.Translations.Model .. ": " .. displayName .. "\n" ..
        Config.Translations.LicensePlate .. ": " .. plate
    )
    DrawText(0.505, 0.505)
end