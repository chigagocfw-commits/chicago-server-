-- Police Tablet UI Management
local heatAlerts = nil
local isLoadingRadio = false
local isTakingPicture = false

-- Load Police Page
RegisterNUICallback("LoadPolicePage", function(data, cb)
  local result = {}
  local playerData = exports.origen_police:FW_GetPlayerData(true)
  
  if data.page == "home" then
    -- Home page - show service status and cop count
    result.service = playerData.job.onduty
    
    local loaded = false
    exports.origen_police:FW_TriggerCallback("origen_police:server:GetPoliceCount", function(count)
      result.cops = count
      loaded = true
    end)
    
    -- Wait for callback to complete
    while not loaded do
      Citizen.Wait(0)
    end
    
  elseif data.page == "radio" or data.page == "central" then
    -- Radio/Central page - check if player has radio
    if isLoadingRadio then
      return
    end
    
    result = false
    
    -- Check if player has radio item
    for _, item in pairs(playerData.items) do
      if item.name == "radio" then
        result = exports.origen_police:GetMultiFrec() or "none"
        exports.origen_police:Toggle(true)
        break
      end
    end
    
    -- If no radio but dispatch doesn't require it, allow access
    if not result then
      if not exports.origen_police:GetConfig("NeedRadioForDispatch") then
        local multiFrec = exports.origen_police:GetMultiFrec()
        if multiFrec then
          result = multiFrec
        end
      end
      
      if not result then
        result = false
      end
    end
    
    -- Load heat map alerts for central page
    if Config.HeatMapAlerts then
      if data.page == "central" and not heatAlerts then
        isLoadingRadio = true
        FW_TriggerCallback("origen_police:server:GetHeatAlerts", function(alerts)
          heatAlerts = alerts or {}
        end)
      end
    elseif not Config.HeatMapAlerts and data.page == "central" then
      heatAlerts = {}
    end
    
    -- Wait for heat alerts to load
    while not heatAlerts and data.page == "central" do
      Citizen.Wait(0)
    end
    
    if data.page == "central" then
      result = heatAlerts
      isLoadingRadio = false
    end
    
  elseif data.page == "penalcode" then
    -- Penal code page - allow all officers to manage
    -- Change to result.boss = playerData.job.isboss to restrict to boss only
    result.boss = true
    
  elseif data.page == "agents" then
    -- Agents page - check permissions
    if GetResourceState("origen_police") == "started" then
      local minimumGrade = GetMinimunGrade(playerData.job.name, "AgentManagement")
      result = playerData.job.grade.level >= minimumGrade
    else
      result = true
    end
  end
  
  cb(result)
end)

-- Get Inventory
RegisterNUICallback("GetInventory", function(filter, cb)
  local playerData = exports.origen_police:FW_GetPlayerData(false)
  
  if #filter == 0 then
    -- No filter - return all items
    cb(playerData.items)
  else
    -- Filter items by name
    local filteredItems = {}
    for _, item in pairs(playerData.items) do
      if InSmallArray(item.name, filter) then
        table.insert(filteredItems, item)
      end
    end
    cb(filteredItems)
  end
end)

-- Close Radio Tab
RegisterNetEvent("origen_police:client:CloseRadioTab", function()
  SendNUIMessage({ action = "CloseRadioTab" })
end)

-- Toggle Duty
RegisterNetEvent("origen_police:toggleDuty", function(delay)
  if delay then
    Wait(2000)
  end
  
  TriggerServerEvent("QBCore:ToggleDuty")
  TriggerServerEvent("origen_police:server_esx:SetDuty", not exports.origen_police:GetPoliceDuty())
end)

-- Camera Webhook Functions
function GetCameraWebhook(callback)
  FW_TriggerCallback("origen_police:server:GetCameraUrl", function(url)
    callback(url or nil)
  end)
end

exports("GetWebhook", GetCameraWebhook)

-- Take Picture with Camera
RegisterNUICallback("TakePicture", function(data, cb)
  if isTakingPicture then
    return
  end
  
  GetCameraWebhook(function(webhook)
    if not webhook then
      cb(false)
      isTakingPicture = false
      TogglePause(false)
      Wait(100)
      TogglePause(true)
      return ShowNotification("The camera logs are not configured correctly")
    end
    
    isTakingPicture = true
    
    Citizen.CreateThread(function()
      local originalFov = GetGameplayCamFov()
      local ped = PlayerPedId()
      local camPos = GetEntityCoords(ped) + vector3(0, 0, 0.6) + (GetEntityForwardVector(ped) * 0.7)
      
      -- Create camera
      local camera = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camPos,
        GetEntityRotation(ped, 2),
        originalFov
      )
      
      local currentFov = originalFov
      local minimapWasRendering = IsMinimapRendering()
      
      SetCamActive(camera, true)
      RenderScriptCams(true, true, 2000, true, false)
      DisplayRadar(false)
      
      Citizen.Wait(2000)
      
      local photoTaken = false
      
      while isTakingPicture do
        Citizen.Wait(0)
        
        -- Handle zoom
        currentFov = HandleZoom(camera, originalFov, currentFov)
        
        -- Handle rotation
        CheckInputRotation(camera, currentFov)
        
        -- Disable all controls
        DisableAllControlActions(0)
        
        -- Take photo on ENTER (176)
        if IsDisabledControlJustPressed(0, 176) and not photoTaken then
          photoTaken = true
          webhook = exports.origen_police:TakePhoto(webhook)
          
          exports.origen_police:FW_TriggerCallback("origen_police:police:UpdateCitizenStatus", function(success)
            cb(success and webhook or false)
            isTakingPicture = false
            TogglePause(true)
          end, {
            citizenid = data.citizenid,
            column = "image",
            value = webhook
          })
        end
        
        -- Cancel on BACKSPACE (177)
        if IsDisabledControlJustPressed(0, 177) and not photoTaken then
          cb(false)
          isTakingPicture = false
          TogglePause(true)
        end
      end
      
      -- Cleanup camera
      DisplayRadar(minimapWasRendering)
      ClearPedTasks(ped)
      SetCamActive(camera, false)
      DestroyCam(camera, true)
      RenderScriptCams(false, true, 2000, true, false)
    end)
  end)
end)

-- Camera Input Rotation Handler
function CheckInputRotation(camera, fov)
  local horizontal = GetDisabledControlNormal(0, 220)
  local vertical = GetDisabledControlNormal(0, 221)
  local rotation = GetCamRot(camera, 2)
  
  if horizontal ~= 0.0 or vertical ~= 0.0 then
    local newZ = rotation.z + (horizontal * -1.0 * 0.1 * (fov + 0.1))
    local newX = math.max(math.min(65.0, rotation.x + (vertical * -1.0 * 0.1 * (fov + 0.1))), -65.0)
    
    SetCamRot(camera, newX, 0.0, newZ, 2)
  end
end

-- Camera Zoom Handler
function HandleZoom(camera, originalFov, currentFov)
  -- Zoom in (241)
  if IsDisabledControlJustPressed(0, 241) then
    currentFov = math.max(currentFov - 3.0, 5.0)
  end
  
  -- Zoom out (242)
  if IsDisabledControlJustPressed(0, 242) then
    currentFov = math.min(currentFov + 3.0, originalFov)
  end
  
  local camFov = GetCamFov(camera)
  
  if math.abs(currentFov - camFov) < 0.1 then
    currentFov = camFov
  end
  
  SetCamFov(camera, camFov + ((currentFov - camFov) * 0.05))
  
  return currentFov
end

-- Utility: Check if value is in array
function InSmallArray(value, array)
  for i = 0, #array do
    if array[i] == value then
      return true
    end
  end
  return false
end

-- Show Bodycam
RegisterNUICallback("ShowBodycam", function(data, cb)
  TriggerServerEvent("origen_police:server:ShowBodycam", tonumber(data.id))
  cb(true)
end)

-- Show Carcam
RegisterNUICallback("ShowCarcam", function(data, cb)
  TriggerServerEvent("origen_police:server:ShowCarcam", tonumber(data.netid))
  cb(true)
end)

-- Get Police Grades
RegisterNUICallback("GetPoliceGrades", function(data, cb)
  if not Framework.Shared.Jobs then
    Debuger("The Framework.Shared.Jobs appear to be nil, please check your framework configuration.")
    return cb({})
  end
  
  if not Framework.Shared.Jobs[data.job] then
    Debuger("The job '" .. data.job .. "' does not exist in Framework.Shared.Jobs.")
    return cb({})
  end
  
  if not Framework.Shared.Jobs[data.job].grades then
    Debuger("The job '" .. data.job .. "' does not have grades defined in Framework.Shared.Jobs.")
    return cb({})
  end
  
  cb(Framework.Shared.Jobs[data.job].grades)
end)

-- Hide Camera HUD
RegisterNetEvent("origen_police:client:HideCamHud", function()
  SendNUIMessage({ action = "HideCamHud" })
  TogglePause(true)
end)

-- Rpol Message (Police Radio Message)
RegisterNetEvent("origen_police:client:rpol", function(message)
  SendNUIMessage({
    action = "RpolMessage",
    message = message
  })
end)

RegisterNUICallback("SendRpolMessage", function(data, cb)
  UseCommand("rpol", data.message)
  cb(true)
end)

-- Alert System
RegisterNetEvent("origen_police_menu:client:ReceiveAlert", function(alert)
  -- Calculate distance to alert
  local playerPos = GetEntityCoords(PlayerPedId())
  local distance = #(playerPos - alert.coords)
  alert.distance = distance
  
  -- Format distance display
  if alert.distance < 1000 then
    alert.distance = FW_Round(alert.distance, 2) .. " m"
  else
    alert.distance = FW_Round(alert.distance / 1000, 2) .. " Km"
  end
  
  -- Get street name
  alert.street = GetStreetNameFromHashKey(GetStreetNameAtCoord(alert.coords.x, alert.coords.y, alert.coords.z))
  alert.time = 0
  
  -- Play alert sound
  PlaySoundFrontend(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", false)
  
  SendNUIMessage({
    action = "ReceiveAlert",
    alert = alert
  })
end)

RegisterNetEvent("origen_police_menu:client:EditAlert", function(data)
  SendNUIMessage({
    action = "EditAlert",
    data = data
  })
end)

-- Central Map Markers
RegisterNetEvent("origen_police:client:AddCentralMark", function(id, data)
  SendNUIMessage({
    action = "AddCentralMark",
    id = id,
    data = data
  })
end)

RegisterNetEvent("origen_police:client:UpdateCentralMark", function(id, data)
  SendNUIMessage({
    action = "UpdateCentralMark",
    id = id,
    data = data
  })
end)

RegisterNetEvent("origen_police:client:RemoveCentralMark", function(id)
  SendNUIMessage({
    action = "RemoveCentralMark",
    id = id
  })
end)

RegisterNetEvent("origen_police:client:UpdateCentralPositions", function(vehicleTrackeds, cops)
  SendNUIMessage({
    action = "UpdateCentralPositions",
    VehicleTrackeds = vehicleTrackeds,
    Cops = cops
  })
end)