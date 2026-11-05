-- Federal/Prison System - Client Side
local isInPrison = false

-- Validate configuration
if not Config.Federal or not Config.Federal.Exits then
  print("You have a syntax error in config/federal.lua or you're missing the Exits table, we don't give support for this, just revert your changed or redownload the file from keymaster.")
end

-- Export function to check if player is in prison
function IsInPrision()
  return isInPrison
end

exports("IsInPrision", IsInPrision)

-- Handle player loaded event
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
  -- Skip if origen_titlemenu is active
  if GetResourceState("origen_titlemenu") == "started" then
    return
  end
  
  Wait(2000)
  
  local playerData = FW_GetPlayerData(true)
  
  if playerData.metadata and playerData.metadata.federal == 1 then
    Citizen.Wait(2000)
    SpawnInFederal(playerData)
  end
end)

-- Spawn player in federal prison
function SpawnInFederal(playerData)
  if Config.OwnPrisionSystem then
    SpawnInJail(playerData)
  else
    -- Teleport to prison spawn
    SetEntityCoords(
      PlayerPedId(),
      playerData.position.x,
      playerData.position.y,
      playerData.position.z
    )
    SetEntityHeading(PlayerPedId(), playerData.position.w)
    FreezeEntityPosition(PlayerPedId(), false)
    
    -- Get federal data and start timer
    FW_TriggerCallback("origen_police:callback:GetFederal", function(federalData)
      if federalData.time and federalData.time > 0 then
        SetFederal(federalData.time)
      else
        SetFederal(false)
      end
    end, playerData.citizenid)
  end
end

-- Set federal prison status
function SetFederal(jailTime, dangerLevel)
  if Config.OwnPrisionSystem then
    setPrision(jailTime, dangerLevel)
  else
    DoScreenFadeOut(300)
    
    if jailTime then
      -- Sending to prison
      local closestExit = nil
      
      if dangerLevel then
        -- Find closest exit to player
        local playerPos = GetEntityCoords(PlayerPedId())
        local closestDistance = nil
        
        for exitName, exitData in pairs(Config.Federal.Exits) do
          local distance = #(playerPos - exitData.xyz)
          if not closestDistance or closestDistance > distance then
            closestDistance = distance
            closestExit = exitName
          end
        end
      end
      
      -- Send to server to register federal time
      TriggerServerEvent("origen_police:server:setfederal", jailTime, dangerLevel, closestExit)
      
      Citizen.Wait(1000)
      
      -- Teleport to spawn point
      SetEntityCoords(
        PlayerPedId(),
        Config.Federal.Exits[Config.DefaultExit].xyz
      )
      
      StartAnimation("join")
      
      -- Start prison timer thread
      Citizen.CreateThread(function()
        local timeCounter = Config.TimePerMonth
        isInPrison = true
        
        SendNUIMessage({
          action = "Federal",
          mins = jailTime
        })
        
        while jailTime > 0 and isInPrison do
          Citizen.Wait(1000)
          
          -- Check if player is too far from prison center
          local playerPos = GetEntityCoords(PlayerPedId())
          local distance = #(playerPos - Config.Federal.Center)
          
          if distance > 150 then
            -- Teleport back to spawn
            SetEntityCoords(PlayerPedId(), Config.Federal.Spawn.xyz)
            SetEntityHeading(PlayerPedId(), Config.Federal.Spawn.w)
            ShowNotification(Config.Translations.RespectRol)
          end
          
          -- Decrement time counter
          timeCounter = timeCounter - 1
          
          if timeCounter == 0 then
            timeCounter = Config.TimePerMonth
            jailTime = jailTime - 1
            
            if jailTime > 0 then
              -- Update time on server
              TriggerServerEvent("origen_police:server:updatemins", jailTime)
              SendNUIMessage({
                action = "Federal",
                mins = jailTime
              })
            else
              -- Time served, release player
              FW_TriggerCallback("origen_police:callback:GetFederal", function(federalData)
                isInPrison = false
                DoScreenFadeOut(300)
                
                TriggerServerEvent("origen_police:server:setfederal", false)
                SendNUIMessage({ action = "Federal" })
                
                Citizen.Wait(500)
                
                -- Get exit location
                local exitCoords = Config.Federal.Exits[federalData.joinedfrom]
                if not exitCoords then
                  exitCoords = Config.Federal.Exits[Config.DefaultExit]
                end
                
                -- Use forced exit if enabled
                if Config.ForcedExit.enabled then
                  exitCoords = Config.ForcedExit.coords
                end
                
                -- Teleport to exit
                SetEntityCoords(PlayerPedId(), exitCoords.xyz)
                SetEntityHeading(PlayerPedId(), exitCoords.w)
                
                Citizen.Wait(1000)
                StartAnimation("leave")
              end)
            end
          end
        end
      end)
    else
      -- Releasing from prison immediately
      isInPrison = false
      Citizen.Wait(1000)
      
      FW_TriggerCallback("origen_police:callback:GetFederal", function(federalData)
        DoScreenFadeOut(300)
        
        TriggerServerEvent("origen_police:server:setfederal", false)
        SendNUIMessage({ action = "Federal" })
        
        Citizen.Wait(500)
        
        -- Get exit location
        local exitCoords = Config.Federal.Exits[federalData.joinedfrom]
        if not exitCoords then
          exitCoords = Config.Federal.Exits[Config.DefaultExit]
        end
        
        -- Use forced exit if enabled
        if Config.ForcedExit.enabled then
          exitCoords = Config.ForcedExit.coords
        end
        
        -- Teleport to exit
        SetEntityCoords(PlayerPedId(), exitCoords.xyz)
        SetEntityHeading(PlayerPedId(), exitCoords.w)
        
        Citizen.Wait(1000)
        StartAnimation("leave")
      end)
    end
  end
end

-- Handle prison entrance/exit animations
function StartAnimation(animationType)
  RemoveHandCuff()
  SetDimension(GetPlayerServerId(PlayerId()))
  Citizen.Wait(100)
  
  if animationType == "join" then
    -- Joining prison animation
    TriggerEvent("origen_police:client:OnFederalJoin")
    
    SetEntityVisible(PlayerPedId(), false)
    
    -- Load guard model
    RequestModel(GetHashKey("s_m_m_prisguard_01"))
    while not HasModelLoaded(GetHashKey("s_m_m_prisguard_01")) do
      Wait(0)
    end
    
    -- Function to complete spawn after animation
    local function CompleteSpawn()
      SetDimension(0)
      SetEntityCoords(PlayerPedId(), Config.Federal.Spawn.xyz)
      SetEntityHeading(PlayerPedId(), Config.Federal.Spawn.w)
      
      Citizen.Wait(500)
      
      SetEntityVisible(PlayerPedId(), true)
      SetGameplayCamRelativeHeading(0)
      DoScreenFadeIn(300)
      
      -- Make player walk forward if enabled
      if Config.PedWalkOnAnim then
        local forwardPos = GetEntityCoords(PlayerPedId()) + (GetEntityForwardVector(PlayerPedId()) * 3)
        TaskGoToCoordAnyMeans(PlayerPedId(), forwardPos, 1.0, 0, 0, 786603, 1.0)
      end
    end
    
    -- Check if cinematic is enabled
    if not Config.Federal.JoinCinematic then
      return CompleteSpawn()
    end
    
    -- Spawn bus with cinematic
    FW_SpawnVehicle(GetHashKey(Config.BusModel), function(bus)
      SetEntityHeading(bus, Config.Federal.BusCoords.w)
      
      -- Create guard driver
      local guard = CreatePedInsideVehicle(
        bus,
        6,
        GetHashKey("s_m_m_prisguard_01"),
        -1,
        false,
        false
      )
      
      -- Configure vehicle
      SetVehicleEngineOn(bus, true, true)
      SetBlockingOfNonTemporaryEvents(guard, true)
      SetDriverAbility(guard, 1.0)
      SetDriverAggressiveness(guard, 0.0)
      
      -- Drive to destination
      TaskVehicleDriveToCoord(
        guard,
        bus,
        Config.Federal.Finish.x,
        Config.Federal.Finish.y,
        Config.Federal.Finish.z,
        Config.Federal.Finish.w,
        0,
        1341619767,
        4457279,
        1,
        true
      )
      
      -- Play siren sound
      local soundId = GetSoundId()
      PlaySoundFromEntity(soundId, "VEHICLES_HORNS_SIREN_1", bus, 0, 0, 0)
      
      DoScreenFadeIn(300)
      
      -- Apply criminal clothes if enabled
      if Config.AutoSetCriminalClothe then
        local playerData = FW_GetPlayerData(true)
        local ped = PlayerPedId()
        local model = GetEntityModel(ped)
        
        local gender = false
        if model == GetHashKey("mp_m_freemode_01") then
          gender = "male"
        elseif model == GetHashKey("mp_f_freemode_01") then
          gender = "female"
        end
        
        SetCriminalClothes(gender, playerData)
      end
      
      -- Create cinematic camera
      local camera = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        Config.Federal.CamCoords.xyz,
        vector3(-30, 0, Config.Federal.CamCoords.w),
        GetGameplayCamFov()
      )
      
      SetCamActive(camera, true)
      RenderScriptCams(true, false, 0, true, false)
      
      -- Wait for cinematic to finish
      Citizen.Wait(10000)
      
      DoScreenFadeOut(300)
      Citizen.Wait(300)
      
      -- Clean up camera
      SetCamActive(camera, false)
      DestroyCam(camera, true)
      RenderScriptCams(false, false, 0, true, false)
      
      -- Clean up entities
      DeleteEntity(guard)
      StopSound(soundId)
      ReleaseSoundId(soundId)
      FW_DeleteVehicle(bus)
      
      CompleteSpawn()
    end, Config.Federal.BusCoords.xyz, false)
    
  elseif animationType == "leave" then
    -- Leaving prison animation
    TriggerEvent("origen_police:client:OnFederalLeave")
    
    -- Remove criminal clothes if enabled
    if Config.AutoSetCriminalClothe then
      local playerData = FW_GetPlayerData(true)
      SetCriminalClothes("none", playerData)
    end
    
    -- Return belongings
    TriggerServerEvent("origen_police:server:getanypertenences")
    
    -- Create exit camera
    local camPos = GetEntityCoords(PlayerPedId()) + 
                   (GetEntityForwardVector(PlayerPedId()) * 5) + 
                   vector3(0, 0, 2.1)
    
    local camera = CreateCamWithParams(
      "DEFAULT_SCRIPTED_CAMERA",
      camPos,
      vector3(-20, 0, GetEntityHeading(PlayerPedId()) - 180),
      GetGameplayCamFov()
    )
    
    SetCamActive(camera, true)
    RenderScriptCams(true, false, 0, true, false)
    DoScreenFadeIn(300)
    
    -- Make player walk forward if enabled
    if Config.PedWalkOnAnim then
      local forwardPos = GetEntityCoords(PlayerPedId()) + (GetEntityForwardVector(PlayerPedId()) * 7)
      TaskGoToCoordAnyMeans(PlayerPedId(), forwardPos, 1.0, 0, 0, 786603, 1.0)
    end
    
    Citizen.Wait(2000)
    
    -- Reset dimension and camera
    SetDimension(0)
    SetCamActive(camera, false)
    DestroyCam(camera, true)
    RenderScriptCams(false, true, 2000, true, false)
  end
end

-- Export functions
exports("SpawnInFederal", SpawnInFederal)
exports("SetFederal", SetFederal)

-- Register network events
RegisterNetEvent("SpawnInFederal", SpawnInFederal)
RegisterNetEvent("SetFederal", SetFederal)

-- NUI Callbacks
RegisterNUICallback("SpawnInFederal", function(data, cb)
  SpawnInFederal(table.unpack(data))
  cb(true)
end)

RegisterNUICallback("SetFederal", function(data, cb)
  SetFederal(table.unpack(data))
  cb(true)
end)