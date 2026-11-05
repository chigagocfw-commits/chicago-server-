-- Codem Garbage Job - Client Main

Core = nil
nuiLoaded = false
menuOpen = false
currentStopIndex = 1
garbageTruckVehicle = nil
callbackResult = nil
activeBlips = {}
coopData = {}

garbageJobData = {
  startMission = false,
  deliveryvehicle = false,
  incomePrice = 0,
  gatheredCount = 0,
  stopname = nil,
  multiplayerJobs = false,
  isDriver = false
}

-- Load animation dictionary and wait until loaded
function LoadAnimationDictionary(animDict)
  RequestAnimDict(animDict)
  while not HasAnimDictLoaded(animDict) do
    Wait(10)
  end
end

-- Animation loop for garbage carry
function StartGarbageCarryAnimationLoop()
  CreateThread(function()
    local playerPed = PlayerPedId()
    while true do
      if IsEntityPlayingAnim(playerPed, "missfbi4prepp1", "_bag_throw_garbage_man", 3) then
        break
      end
      if not IsEntityPlayingAnim(playerPed, "missfbi4prepp1", "_bag_walk_garbage_man", 3) then
        ClearPedTasksImmediately(playerPed)
        LoadAnimationDictionary("missfbi4prepp1")
        TaskPlayAnim(playerPed, "missfbi4prepp1", "_bag_walk_garbage_man", 6.0, -6.0, -1, 49, 0, 0, 0, 0)
      end
      Wait(1000)
    end
  end)
end

-- NUI message helper - waits for NUI to load before sending
function NuiMessage(action, payload)
  while not nuiLoaded do
    Wait(0)
  end
  SendNUIMessage({
    action = action,
    payload = payload
  })
end

-- NUI callback for loaded state
RegisterNUICallback("loaded", function(data, cb)
  nuiLoaded = true
  cb("ok")
end)

-- Thread to check NUI loading status
CreateThread(function()
  while Core == nil do
    Wait(0)
  end
  while not nuiLoaded do
    if NetworkIsSessionStarted() then
      SendNUIMessage({ action = "CHECK_NUI" })
    end
    Wait(2000)
  end
end)

-- NUI callback for closing menu
RegisterNUICallback("closeMenu", function(data, cb)
  SetNuiFocus(false, false)
  menuOpen = false
  RenderScriptCams(false, true, 500, true, true)
  DestroyCam(cam, true)
  ClearFocus()
  cb("ok")
end)

-- Initialize NUI configuration on load
Citizen.CreateThread(function()
  while Core == nil do
    Citizen.Wait(0)
  end
  while not nuiLoaded do
    Citizen.Wait(0)
  end

  Config.OpenTrigger()
  NuiMessage("requiredXp", Config.RequiredXP)
  NuiMessage("configCurrencyUnit", Config.CurrencyUnit)
  NuiMessage("configlocales", Config.Locales)
  NuiMessage("configDailyMission", Config.GarbagejobSettings.dailyMission)
  NuiMessage("configBadge", Config.GarbagejobSettings.badge)

  -- Calculate profit and stop count for each route
  for _, routeSettings in pairs(Config.GarbagejobSettings.garbageRouteSettings) do
    local garbageStops = Config.GarbagejobSettings.garbageStop[routeSettings.name]
    routeSettings.Profit = 0
    routeSettings.stopCount = 0

    if garbageStops then
      for _, stop in ipairs(garbageStops) do
        routeSettings.Profit = routeSettings.Profit + (stop.garbagePrice * stop.garbageCount)
        routeSettings.stopCount = routeSettings.stopCount + 1
      end
    end
  end

  NuiMessage("configRoutes", Config.GarbagejobSettings.garbageRouteSettings)
end)

-- Open the trash menu
function openTrashMenu()
  if not menuOpen then
    CreateCamera()
    SetNuiFocus(true, true)
    menuOpen = true
    local playerData = TriggerCallback("codem-garbage:getPlayerData")
    NuiMessage("OPEN_MENU", {
      playerData = playerData,
      coopData = coopData
    })
  end
end

-- NUI callback for creating lobby
RegisterNUICallback("createLobby", function(data)
  TriggerServerEvent("codem-garbage:onlineJobsInsertData", data)
end)

-- Event: Set driver data
RegisterNetEvent("codem-garbage:setDriverData", function()
  garbageJobData.isDriver = true
end)

-- Event: Show notification
RegisterNetEvent("codem-garbage:notificaton", function(notificationData)
  NuiMessage("notification", notificationData)
end)

-- NUI callback for kicking player
RegisterNUICallback("kickPlayer", function(data)
  TriggerServerEvent("codem-garbage:kickPlayer", data)
end)

-- Command: Reset job
RegisterCommand(Config.ResetJobPlayer, function()
  if garbageJobData.multiplayerJobs then
    TriggerServerEvent("codem-garbage:resetjob", garbageJobData)
  else
    if garbageTruckVehicle then
      Config.RemoveVehiclekey(
        GetVehicleNumberPlateText(garbageTruckVehicle),
        GetHashKey(Config.GarbagejobSettings.trashvehicle),
        garbageTruckVehicle
      )
      DeleteEntity(garbageTruckVehicle)

      local garbageStops = Config.GarbagejobSettings.garbageStop[garbageJobData.stopname]
      for _, stop in ipairs(garbageStops) do
        if stop.blip then
          RemoveBlip(stop.blip)
        end
      end

      Config.Notification(
        Config.NotificationText.resetjob.text,
        Config.NotificationText.resetjob.type,
        false
      )
      resetJob()
    end
  end
end)

-- Event: Client reset job
RegisterNetEvent("codem-garbage:client:ResetJob", function(jobDataParam)
  if jobDataParam then
    if garbageTruckVehicle then
      Config.RemoveVehiclekey(
        GetVehicleNumberPlateText(garbageTruckVehicle),
        GetHashKey(Config.GarbagejobSettings.trashvehicle),
        garbageTruckVehicle
      )
      DeleteEntity(garbageTruckVehicle)
    end

    local garbageStops = Config.GarbagejobSettings.garbageStop[jobDataParam.stopname]
    if garbageStops then
      for _, stop in ipairs(garbageStops) do
        if stop.blip then
          RemoveBlip(stop.blip)
        end
      end
    end

    Config.Notification(
      Config.NotificationText.resetjob.text,
      Config.NotificationText.resetjob.type,
      false
    )
    NuiMessage("DELETE_TEAMDATA")
    resetJob()

    if #activeBlips > 0 then
      for _, blip in pairs(activeBlips) do
        RemoveBlip(blip)
      end
    end
  end
end)

-- Event: Start multiplayer job
RegisterNetEvent("codem-garbage:startMultiplayerJob", function(garbageStops, truckNetId, stopName)
  if not truckNetId then
    Config.Notification(
      Config.NotificationText.vehicleNotFound.text,
      Config.NotificationText.vehicleNotFound.type,
      false
    )
    return
  end

  garbageTruckVehicle = NetToVeh(truckNetId)
  Config.SetVehicleFuel(garbageTruckVehicle, 100.0)
  Config.GiveVehicleKey(
    GetVehicleNumberPlateText(garbageTruckVehicle),
    GetHashKey(Config.GarbagejobSettings.trashvehicle),
    garbageTruckVehicle
  )

  local playerPed = PlayerPedId()
  local boneIndex = GetPedBoneIndex(playerPed, 57005)

  garbageJobData.startMission = true
  garbageJobData.multiplayerJobs = true
  garbageJobData.stopname = stopName

  -- Setup blips for all stops
  for stopIndex, stop in ipairs(garbageStops) do
    if stop.blip then
      RemoveBlip(stop.blip)
    end
    stop.blip = AddBlipForCoord(stop.coords.x, stop.coords.y, stop.coords.z)
    SetBlipAttributes(stop.blip, stopIndex)
    table.insert(activeBlips, stop.blip)
  end

  -- If driver, calculate total income
  if garbageJobData.isDriver then
    for _, stop in pairs(garbageStops) do
      if stop then
        garbageJobData.gatheredCount = garbageJobData.gatheredCount + stop.garbageCount
        garbageJobData.incomePrice = garbageJobData.incomePrice + (stop.garbagePrice * stop.garbageCount)
      end
    end
  end

  SetNewWaypoint(garbageStops[currentStopIndex].coords.x, garbageStops[currentStopIndex].coords.y)
  NuiMessage("closeMenu")

  -- Main garbage collection loop for non-drivers
  while currentStopIndex <= #garbageStops and garbageJobData.startMission and not garbageJobData.isDriver do
    local currentStop = garbageStops[currentStopIndex]
    local garbageRemaining = currentStop.garbageCount
    local waitTime = 1000
    local collectedCount = 0

    while garbageRemaining > collectedCount do
      local playerCoords = GetEntityCoords(playerPed)
      local distance = #(playerCoords - currentStop.coords)

      if distance < 20 then
        waitTime = 0
        DrawMarker(2, currentStop.coords.x, currentStop.coords.y, currentStop.coords.z,
          0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.2,
          255, 255, 255, 255, 0, 0, 0, 1, 0, 0, 0)
        DrawText3D(currentStop.coords.x, currentStop.coords.y, currentStop.coords.z + 0.5, Config.Locales.press_e)

        if IsControlJustReleased(1, 38) and distance < 3 then
          if CanPrees() then
            collectTrash(playerPed, boneIndex)
            collectedCount = (collectedCount or 0) + 1
            updateScreen(garbageStops, collectedCount)
            garbageJobData.incomePrice = garbageJobData.incomePrice + currentStop.garbagePrice
            garbageJobData.gatheredCount = garbageJobData.gatheredCount + 1
            Citizen.Wait(500)
          end
        end
      else
        waitTime = 1000
      end
      Citizen.Wait(waitTime)
    end

    currentStopIndex = currentStopIndex + 1
    local nextStop = garbageStops[currentStopIndex]

    if currentStopIndex <= #garbageStops then
      if currentStop.blip then
        TriggerServerEvent("codem-garbage:deleteBlip", currentStopIndex)
        currentStop.blip = nil
      end
      Config.Notification(
        Config.NotificationText.nextposition.text,
        Config.NotificationText.nextposition.type,
        false
      )
      SetNewWaypoint(nextStop.coords.x, nextStop.coords.y)
    end

    if currentStopIndex > #garbageStops then
      garbageJobData.deliveryvehicle = true
      Config.Notification(
        Config.NotificationText.deliveryvehicle.text,
        Config.NotificationText.deliveryvehicle.type,
        false
      )
      TriggerServerEvent("codem-garbage:deleteBlip", currentStopIndex)
      TriggerServerEvent("codem-garbage:deliveryVehicleForDriver")
      deliveryTheVehicle()
    end
  end
end)

-- Event: Delete blip at index
RegisterNetEvent("codem-garbage:deleteBlip", function(blipIndex)
  local targetIndex = blipIndex - 1
  if #activeBlips > 0 then
    for index, blip in pairs(activeBlips) do
      if index == targetIndex then
        if blip then
          RemoveBlip(blip)
        else
          if #activeBlips > 0 then
            for _, remainingBlip in pairs(activeBlips) do
              RemoveBlip(remainingBlip)
            end
          end
        end
      end
    end
  end
end)

-- NUI callback for starting solo job
RegisterNUICallback("startJob", function(data)
  if garbageJobData.startMission then
    Config.Notification(
      Config.NotificationText.missioninprogress.text,
      Config.NotificationText.missioninprogress.type,
      false
    )
    return
  end

  local vehicleSpawned = spawnGarbageVehicle()
  if vehicleSpawned then
    garbageJobData.multiplayerJobs = false
    garbageJobData.stopname = data.route
    TriggerServerEvent('codem-garbagejob:server:startJobSingleplayer', data.route, NetworkGetNetworkIdFromEntity(garbageTruckVehicle))

    local garbageStops = Config.GarbagejobSettings.garbageStop[data.route]
    local playerPed = PlayerPedId()
    local boneIndex = GetPedBoneIndex(playerPed, 57005)

    -- Setup blips for all stops
    for stopIndex, stop in ipairs(garbageStops) do
      if stop.blip then
        RemoveBlip(stop.blip)
      end
      stop.blip = AddBlipForCoord(stop.coords.x, stop.coords.y, stop.coords.z)
      SetBlipAttributes(stop.blip, stopIndex)
      table.insert(activeBlips, stop.blip)
    end

    SetNewWaypoint(garbageStops[currentStopIndex].coords.x, garbageStops[currentStopIndex].coords.y)

    if garbageStops then
      garbageJobData.startMission = true

      -- Main garbage collection loop
      while currentStopIndex <= #garbageStops and garbageJobData.startMission do
        local currentStop = garbageStops[currentStopIndex]
        local garbageRemaining = currentStop.garbageCount
        local waitTime = 1000
        local collectedCount = 0

        while garbageRemaining > collectedCount do
          local playerCoords = GetEntityCoords(playerPed)
          local distance = #(playerCoords - currentStop.coords)

          if distance < 7.5 then
            waitTime = 0
            DrawMarker(2, currentStop.coords.x, currentStop.coords.y, currentStop.coords.z,
              0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.2,
              255, 255, 255, 255, 0, 0, 0, 1, 0, 0, 0)
            DrawText3D(currentStop.coords.x, currentStop.coords.y, currentStop.coords.z + 0.5, Config.Locales.press_e)

            if IsControlJustReleased(1, 38) and distance < 3 then
              if CanPrees() then
                collectTrash(playerPed, boneIndex)
                collectedCount = (collectedCount or 0) + 1
                updateScreen(garbageStops, collectedCount)
                garbageJobData.incomePrice = garbageJobData.incomePrice + currentStop.garbagePrice
                garbageJobData.gatheredCount = garbageJobData.gatheredCount + 1
                Citizen.Wait(500)
              end
            end
          else
            waitTime = 1000
          end
          Citizen.Wait(waitTime)
        end

        TriggerServerEvent('codem-garbagejob:server:completeStop', currentStopIndex)
        currentStopIndex = currentStopIndex + 1
        local nextStop = garbageStops[currentStopIndex]

        if currentStopIndex <= #garbageStops then
          if currentStop.blip then
            RemoveBlip(currentStop.blip)
            currentStop.blip = nil
          end
          SetNewWaypoint(nextStop.coords.x, nextStop.coords.y)
          Config.Notification(
            Config.NotificationText.nextposition.text,
            Config.NotificationText.nextposition.type,
            false
          )
        end

        if currentStopIndex > #garbageStops then
          garbageJobData.deliveryvehicle = true
          Config.Notification(
            Config.NotificationText.deliveryvehicle.text,
            Config.NotificationText.deliveryvehicle.type,
            false
          )
          RemoveBlip(currentStop.blip)
          deliveryTheVehicle()
        end
      end
    else
      Config.Notification(
        Config.NotificationText.routenotfound.text,
        Config.NotificationText.routenotfound.type,
        false
      )
    end
  end
end)

-- Check if player can interact (not in vehicle)
function CanPrees()
  local playerPed = PlayerPedId()
  if IsPedInAnyVehicle(playerPed, false) then
    return false
  end
  return true
end

-- Event: Finish as driver (start delivery)
RegisterNetEvent("codem-garbage:finishIsDriver", function()
  garbageJobData.deliveryvehicle = true
  deliveryTheVehicle()
end)

-- Handle vehicle delivery at finish point
function deliveryTheVehicle()
  Citizen.CreateThread(function()
    local deliveryCoords = Config.GarbagejobSettings.jobDeliverTheVehicleCoords
    SetNewWaypoint(deliveryCoords.x, deliveryCoords.y)

    while garbageJobData.deliveryvehicle do
      local waitTime = 2000
      local playerPed = PlayerPedId()
      local playerCoords = GetEntityCoords(playerPed)
      local distance = #(playerCoords - deliveryCoords)

      if distance < 15.0 then
        waitTime = 0
        if Config.DrawMarkerSettings.deleteVehicleDrawMarker then
          DrawMarker(22, deliveryCoords.x, deliveryCoords.y, deliveryCoords.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 2.5, 1.5,
            255, 150, 0, 255, 0, 1, 0, 0, 0, 0)
        end
      end

      if distance < 7.5 then
        if IsControlJustPressed(0, 38) then
          if garbageJobData.multiplayerJobs then
            if garbageJobData.isDriver then
              TriggerServerEvent("codem-garbage:finishMultiplayerJobs")
            end
          else
            if garbageTruckVehicle then
              Config.RemoveVehiclekey(
                GetVehicleNumberPlateText(garbageTruckVehicle),
                GetHashKey(Config.GarbagejobSettings.trashvehicle),
                garbageTruckVehicle
              )
              DeleteEntity(garbageTruckVehicle)
            end

            local keyResult = TriggerCallback("codem-garbage:getKey")
            callbackResult = keyResult or false

            TriggerServerEvent("codem-garbagejob:finishJob",
              callbackResult,
              garbageJobData.incomePrice,
              garbageJobData.gatheredCount,
              garbageJobData.stopname
            )

            local garbageStops = Config.GarbagejobSettings.garbageStop[garbageJobData.stopname]
            for _, stop in ipairs(garbageStops) do
              if stop.blip then
                RemoveBlip(stop.blip)
              end
            end
            resetJob()
          end
        end
      end
      Citizen.Wait(waitTime)
    end
  end)
end

-- Reset all job data
function resetJob()
  garbageJobData.startMission = false
  garbageJobData.incomePrice = 0
  garbageJobData.gatheredCount = 0
  garbageJobData.stopname = nil
  garbageJobData.multiplayerJobs = false
  garbageJobData.deliveryvehicle = false
  garbageTruckVehicle = nil
  garbageJobData.isDriver = false
  currentStopIndex = 1
end

-- Event: Finish multiplayer job for all players
RegisterNetEvent("codem-garbage:client:finishMultiplayerJob", function()
  if garbageTruckVehicle then
    Config.RemoveVehiclekey(
      GetVehicleNumberPlateText(garbageTruckVehicle),
      GetHashKey(Config.GarbagejobSettings.trashvehicle),
      garbageTruckVehicle
    )
    DeleteEntity(garbageTruckVehicle)
  end

  local garbageStops = Config.GarbagejobSettings.garbageStop[garbageJobData.stopname]
  for _, stop in ipairs(garbageStops) do
    if garbageStops and stop.blip then
      RemoveBlip(stop.blip)
    end
  end

  local keyResult = TriggerCallback("codem-garbage:getKey")
  callbackResult = keyResult or false

  TriggerServerEvent("codem-garbagejob:finishJob",
    callbackResult,
    garbageJobData.incomePrice,
    garbageJobData.gatheredCount,
    garbageJobData.stopname,
    garbageJobData.multiplayerJobs
  )
  NuiMessage("DELETE_TEAMDATA")
  resetJob()
end)

-- Update screen with remaining garbage count
function updateScreen(garbageStops, collectedCount)
  local currentStop = garbageStops[currentStopIndex]
  local totalGarbage = currentStop.garbageCount
  local currentCollected = collectedCount or 0
  local remaining = totalGarbage - currentCollected

  if remaining > 0 then
    Config.Notification(
      string.format(Config.NotificationText.garbagecount.text, totalGarbage, remaining),
      Config.NotificationText.garbagecount.type,
      false
    )
  end
end

-- Collect trash animation and object handling
function collectTrash(playerPed, boneIndex)
  LoadAnimationDictionary("missfbi4prepp1")
  TaskPlayAnim(playerPed, "missfbi4prepp1", "_bag_walk_garbage_man", 6.0, -6.0, -1, 49, 0, 0, 0, 0)

  local trashBagObject = CreateObject(1138881502, 0, 0, 0, true, true, true)
  local handBone = GetPedBoneIndex(playerPed, 57005)

  AttachEntityToEntity(trashBagObject, playerPed, handBone, 0.12, 0.0, -0.05, 220.0, 120.0, 0.0, true, true, false, true,
    1, true)
  StopAnimTask(playerPed, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 1.0)
  StartGarbageCarryAnimationLoop()
  collectedtrash(trashBagObject)
end

-- Handle collected trash and go to truck
function collectedtrash(trashBagObject)
  local waitTime = 1000
  local playerPed = PlayerPedId()

  while true do
    local truckBonePos = GetWorldPositionOfEntityBone(
      garbageTruckVehicle,
      GetEntityBoneIndexByName(garbageTruckVehicle, "platelight")
    )

    local playerCoords = GetEntityCoords(playerPed)
    local distance = GetDistanceBetweenCoords(playerCoords, truckBonePos)

    if distance < 20 then
      local markerPos = truckBonePos + vector3(0.0, 0.0, 0.5)
      DrawMarker(2, markerPos, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.4, 0.2,
        255, 255, 255, 255, 0, 0, 0, 1, 0, 0, 0)

      if distance < 2 then
        if IsControlJustReleased(1, 38) then
          disposeOfTrash(playerPed, trashBagObject)
          return
        end
      end
      waitTime = 0
    end
    Citizen.Wait(waitTime)
  end
end

-- Dispose of trash in truck
function disposeOfTrash(playerPed, trashBagObject)
  LoadAnimationDictionary("missfbi4prepp1")
  TaskPlayAnim(playerPed, "missfbi4prepp1", "_bag_throw_garbage_man", 8.0, 8.0, 1100, 48, 0.0, 0, 0, 0)
  FreezeEntityPosition(playerPed, true)
  SetEntityHeading(playerPed, GetEntityHeading(garbageTruckVehicle))

  SetTimeout(1250, function()
    DetachEntity(trashBagObject, 1, false)
    DeleteObject(trashBagObject)
    TaskPlayAnim(playerPed, "missfbi4prepp1", "exit", 8.0, 8.0, 1100, 48, 0.0, 0, 0, 0)
    FreezeEntityPosition(playerPed, false)
  end)
end

-- NUI callback for joining lobby
RegisterNUICallback("joinLobby", function(data, cb)
  TriggerServerEvent("codem-gabage:joinLobby", data)
  cb("ok")
end)

-- NUI callback for updating lobbies
RegisterNUICallback("updateLobbys", function(data, cb)
  TriggerServerEvent("codem-garbage:updateLobbys", data)
  cb("ok")
end)

-- NUI callback for updating area
RegisterNUICallback("updateArea", function(data, cb)
  TriggerServerEvent("codem-gabage:updateArea", data)
  cb("ok")
end)

-- NUI callback for joining lobby with password
RegisterNUICallback("joinLobbyPassword", function(data, cb)
  TriggerServerEvent("codem-gabage:joinLobbyPassword", data)
  cb("ok")
end)

-- NUI callback for leaving lobby
RegisterNUICallback("leaveLobby", function(data, cb)
  TriggerServerEvent("codem-garbage:leaveLobby", data)
  cb("ok")
end)

-- Event: Delete room
RegisterNetEvent("codem-garbage:deleteRoom", function(hostIdentifier)
  if coopData[hostIdentifier] then
    coopData[hostIdentifier] = nil
  end
  NuiMessage("DELETE_TEAMDATA")
end)

-- Event: Update lobbies
RegisterNetEvent("codem-garbage:updateLobbys", function(lobbyData)
  coopData = lobbyData
  NuiMessage("UPDATA_LOBBYS", coopData)
end)

-- Event: Update area
RegisterNetEvent("codem-garbage:client:UpdateArea", function(areaData)
  NuiMessage("UPDATE_AREA", areaData)
end)

-- Event: Delete room for everyone
RegisterNetEvent("codem-garbage:deleteroomeveryone", function(hostIdentifier)
  if coopData[hostIdentifier] then
    coopData[hostIdentifier] = nil
  end
  NuiMessage("INSERT_LOBBY", coopData)
end)

-- NUI callback for starting multiplayer job
RegisterNUICallback("startJobMultiplayer", function(data)
  if garbageJobData.startMission then
    Config.Notification(
      Config.NotificationText.missioninprogress.text,
      Config.NotificationText.missioninprogress.type,
      false
    )
    return
  end
  TriggerServerEvent("codem-garbage:startJobMultiplayer", data)
end)

-- Event: Delete my team
RegisterNetEvent("codem-garbage:deleteMyTeam", function()
  NuiMessage("DELETE_TEAMDATA")
  resetJob()
end)

-- Event: Load NUI data
RegisterNetEvent("codem-garbage:client:loadnuidata", function(playerNuiData, lobbyData)
  coopData = lobbyData
  NuiMessage("NUI_LOAD_DATA", playerNuiData)
end)

-- NUI callback for taking badge
RegisterNUICallback("takeBadge", function(data)
  TriggerServerEvent("codem-garbage:takeBadge", data)
end)

-- Event: Insert online lobby data
RegisterNetEvent("codem-garbage:insertOnlineData", function(roomData, serverSource, hostIdentifier, playerName)
  if roomData then
    if not coopData[hostIdentifier] then
      coopData[hostIdentifier] = {
        roomData = {
          roomName = roomData[1].name,
          password = roomData[1].password,
          areaName = roomData[1].areaName,
          hostIdentifier = hostIdentifier
        },
        players = {
          name = playerName,
          avatar = roomData[1].avatar,
          src = serverSource,
          identifier = hostIdentifier,
          host = true,
          level = roomData[1].level
        }
      }
    end
    NuiMessage("INSERT_LOBBY", coopData)
  end
end)

-- Event: Update room players data
RegisterNetEvent("codem-garbage:updateClientRoomPlayersData", function(hostIdentifier, playersData)
  if coopData[hostIdentifier] then
    coopData[hostIdentifier].players = playersData
  end
  NuiMessage("UPDATE_LOBBY", coopData)
end)

-- Event: Top 50 leaderboard
RegisterNetEvent("codem-garbage:top50", function(topData)
  if topData then
    NuiMessage("top50", topData)
  end
end)

-- Callback helper function for framework compatibility
function TriggerCallback(callbackName, callbackArgs)
  local result = false
  local status = "UNKOWN"
  local retryCount = 0

  while Core == nil do
    Wait(0)
  end

  if Config.Framework == "esx" then
    Core.TriggerServerCallback(callbackName, function(callbackResult)
      status = "SUCCESS"
      result = callbackResult
    end, callbackArgs)
  else
    Core.Functions.TriggerCallback(callbackName, function(callbackResult)
      status = "SUCCESS"
      result = callbackResult
    end, callbackArgs)
  end

  CreateThread(function()
    while status == "UNKOWN" do
      Wait(1000)
      retryCount = retryCount + 1
      if retryCount == 4 then
        status = "FAILED"
        result = false
        break
      end
    end
  end)

  while status == "UNKOWN" do
    Wait(0)
  end

  return result
end
