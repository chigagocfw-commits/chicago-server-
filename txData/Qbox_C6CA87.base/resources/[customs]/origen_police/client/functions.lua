-- Get street name from coordinates
function GetStreetName(coords)
    -- Convert array to vector3 if needed
    if coords.x == nil then
        coords = vector3(coords[1], coords[2], coords[3])
    end
    
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    if crossingName == "" then
        return streetName
    else
        return streetName .. " & " .. crossingName
    end
end

-- Convert heading to cardinal direction (N, NE, E, SE, S, SW, W, NW)
function GetCardinalFromHeading(heading)
    if heading < 22.5 then
        return "N"
    elseif heading < 67.5 then
        return "NO"  -- Northwest (Spanish: Noroeste)
    elseif heading < 112.5 then
        return "O"   -- West (Spanish: Oeste)
    elseif heading < 157.5 then
        return "SO"  -- Southwest (Spanish: Suroeste)
    elseif heading < 202.5 then
        return "S"
    elseif heading < 247.5 then
        return "SE"
    elseif heading < 292.5 then
        return "E"
    elseif heading < 337.5 then
        return "NE"
    else
        return "N"
    end
end

-- Get vehicle in front using radar/raycast
function GetRadarVehicle()
    local playerPed = PlayerPedId()
    local entity = playerPed
    
    -- If player is in a vehicle, use the vehicle for the raycast
    if IsPedInAnyVehicle(playerPed, false) then
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        if vehicle then
            entity = vehicle
        end
    end
    
    -- Perform shape test (raycast) from vehicle forward
    local startPos = GetOffsetFromEntityInWorldCoords(entity, 0.0, 1.0, 1.0)
    local endPos = GetOffsetFromEntityInWorldCoords(entity, 0.0, 105.0, 0.0)
    
    local rayHandle = StartShapeTestCapsule(startPos, endPos, 3.0, 10, entity, 7)
    local _, hit, endCoords, surfaceNormal, hitEntity = GetShapeTestResult(rayHandle)
    
    local plate = GetVehiclePlate(hitEntity)
    local modelName = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(hitEntity)))
    
    return plate, modelName
end

-- Check if player is being seen by cameras or NPCs
function IsBeingSeen()
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Check for nearby CCTV cameras
    local camera = GetClosestObjectOfType(
        playerCoords.x, playerCoords.y, playerCoords.z,
        50.0,
        GetHashKey("prop_cctv_cam_06a"),
        false, false, false
    )
    
    -- Check for nearby NPCs that can see the player
    local peds = Fw_GetPeds()
    local seenByNPC = false
    
    for i = 1, #peds do
        if not IsPedAPlayer(peds[i]) then
            local pedCoords = GetEntityCoords(peds[i])
            local distance = #(pedCoords - playerCoords)
            
            if distance < 200 then
                local pedType = GetPedType(peds[i])
                
                -- Check if not an animal and is conscious
                if pedType ~= 28 and not GetPedConfigFlag(peds[i], 79) then
                    seenByNPC = true
                    break
                end
            end
        end
    end
    
    return (camera > 0) or seenByNPC
end

-- Set wanted level for player
function SetWantedLevel(wantedLevel)
    wantedLevel = tonumber(wantedLevel)
    if not wantedLevel then return end
    
    Citizen.CreateThread(function()
        SetPoliceRadarBlips(false)
        SetMaxWantedLevel(5)
        SetPlayerWantedLevel(PlayerId(), wantedLevel, false)
        SetPlayerWantedLevelNow(PlayerId(), true)
        
        while GetPlayerWantedLevel(PlayerId()) > 0 do
            Citizen.Wait(1000)
            
            -- Update UI with current wanted level
            SendNUIMessage({
                action = "WantedLevel",
                value = GetPlayerWantedLevel(PlayerId())
            })
            
            -- Share wanted level with vehicle passengers
            if IsPedInAnyVehicle(PlayerPedId(), false) then
                local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                local maxSeats = GetVehicleMaxNumberOfPassengers(vehicle)
                
                for seat = -1, maxSeats do
                    local passenger = GetPedInVehicleSeat(vehicle, seat)
                    
                    if passenger ~= 0 and passenger ~= PlayerPedId() then
                        local myWantedLevel = GetPlayerWantedLevel(PlayerId())
                        local passengerWantedLevel = GetPlayerWantedLevel(NetworkGetPlayerIndexFromPed(passenger))
                        
                        -- If my wanted level is higher, share it with passenger
                        if myWantedLevel > passengerWantedLevel then
                            TriggerServerEvent(
                                "origen_police:server:SetWantedLevel",
                                GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)),
                                myWantedLevel
                            )
                        end
                    end
                end
            end
        end
        
        SetMaxWantedLevel(0)
        SendNUIMessage({
            action = "WantedLevel",
            value = 0
        })
    end)
end

exports("SetWantedLevel", SetWantedLevel)
exports("IsBeingSeen", IsBeingSeen)

-- Get vehicle currently in camera view
function GetVehicleInCamera()
    local hit, coords, entity = RayCastGamePlayCamera(1000.0)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local entityCoords = GetEntityCoords(entity)
    local distance = #(playerCoords - entityCoords)
    
    -- If entity is too far, get closest vehicle instead
    if distance > 100 then
        entity = FW_GetClosestVehicle()
    end
    
    playerCoords = GetEntityCoords(PlayerPedId())
    entityCoords = GetEntityCoords(entity)
    distance = #(playerCoords - entityCoords)
    
    -- If still too far, return false
    if distance > 30 then
        entity = false
    end
    
    -- If player is in a vehicle, return that vehicle
    if IsPedInAnyVehicle(PlayerPedId()) then
        entity = GetVehiclePedIsIn(PlayerPedId(), false)
    end
    
    return entity or 0
end

-- Get coordinates where camera is pointing
function GetScreenCoords(maxDistance)
    maxDistance = maxDistance or 1000.0
    local hit, coords, entity = RayCastGamePlayCamera(maxDistance)
    return hit, coords, entity
end

-- Convert rotation to direction vector
function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    
    local direction = {
        x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    
    return direction
end

-- Raycast from gameplay camera
function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoords = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    
    local destination = {
        x = cameraCoords.x + direction.x * distance,
        y = cameraCoords.y + direction.y * distance,
        z = cameraCoords.z + direction.z * distance
    }
    
    local rayHandle = StartShapeTestRay(
        cameraCoords.x, cameraCoords.y, cameraCoords.z,
        destination.x, destination.y, destination.z,
        -1,
        PlayerPedId(),
        0
    )
    
    local _, hit, endCoords, surfaceNormal, entity = GetShapeTestResult(rayHandle)
    
    return hit, endCoords, entity
end

-- Take a photo using screenshot-basic
function TakePhoto(uploadUrl)
    local imageUrl = nil
    
    SendNUIMessage({
        action = "playsound",
        soundid = "take-photo.mp3"
    })
    
    local fields = Config.Fields[Config.UploadMethod]
    
    exports["screenshot-basic"]:requestScreenshotUpload(uploadUrl, fields, function(data)
        Debuger("Data from screenshot-basic: ", data, type(data))
        imageUrl = GetCustomUrlFromResponse(json.decode(data))
    end)
    
    while imageUrl == nil do
        Wait(0)
    end
    
    return imageUrl
end

exports("TakePhoto", TakePhoto)

-- Set player dimension (routing bucket)
function SetDimension(dimension)
    local waiting = true
    
    FW_TriggerCallback("origen_police:SetDimension", function()
        waiting = false
    end, dimension)
    
    while waiting do
        Citizen.Wait(1)
    end
end

-- Get player gender
function GetGender()
    local model = GetEntityModel(PlayerPedId())
    local maleModel = GetHashKey("mp_m_freemode_01")
    
    if model == maleModel then
        return "Male"
    else
        return "Female"
    end
end

-- Get vehicle extras state
function GetVehicleExtras(vehicle)
    local extras = {}
    
    for extraId = 0, Config.ExtrasMaxCount do
        if DoesExtraExist(vehicle, extraId) then
            extras[extraId] = IsVehicleExtraTurnedOn(vehicle, extraId) == 1
        end
    end
    
    return extras
end