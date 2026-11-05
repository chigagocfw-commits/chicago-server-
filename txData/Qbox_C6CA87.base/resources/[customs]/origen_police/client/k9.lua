local k9Ped = 0
local spawnCoords = vector3(0.0, 0.0, 0.0)
local k9Vehicle = 0

RegisterNetEvent("origen_police:client:CallK9", function()
  if k9Ped == 0 then
    local vehicles = FW_GetVehicles()
    k9Vehicle = 0
    local playerCoords = GetEntityCoords(PlayerPedId())

    for i = 1, #vehicles do
      local vehicleModel = GetEntityModel(vehicles[i])
      if Config.K9.Vehicles[vehicleModel] then
        local distance = #(GetEntityCoords(vehicles[i]) - playerCoords)
        if distance < 40 then
          k9Vehicle = vehicles[i]
          NetworkRequestControlOfEntity(k9Vehicle)
          Citizen.Wait(50)
          if NetworkHasControlOfEntity(k9Vehicle) then
            break
          end
        end
      end
    end

    if k9Vehicle ~= 0 then
      RequestAnimDict("swat")
      RequestAnimDict("taxi_hail")
      RequestAnimDict("gestures@f@standing@casual")
      RequestAnimDict("creatures@rottweiler@amb@world_dog_sitting@idle_a")
      RequestAnimDict("creatures@rottweiler@amb@sleep_in_kennel@")
      RequestAnimDict("creatures@rottweiler@amb@world_dog_barking@idle_a")

      spawnCoords = GetOffsetFromEntityInWorldCoords(k9Vehicle, Config.K9.SpawnCarOffset.x, Config.K9.SpawnCarOffset.y, Config.K9.SpawnCarOffset.z)
      SetVehicleDoorOpen(k9Vehicle, Config.K9.SpawnOpenDoor, false, false)

      local modelHash = GetHashKey(Config.K9.Model)
      RequestModel(modelHash)
      while not HasModelLoaded(modelHash) do
        Citizen.Wait(1)
      end

      while not HasAnimDictLoaded("taxi_hail") do
        Citizen.Wait(7)
      end

      TaskPlayAnim(PlayerPedId(), "taxi_hail", "hail_taxi", 8.0, -8.0, -1, 48, 0, false, false, false)
      Citizen.Wait(1000)

      k9Ped = CreatePed(4, modelHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true)
      SetPedRelationshipGroupHash(k9Ped, GetHashKey("k9"))
      SetBlockingOfNonTemporaryEvents(k9Ped, true)
      SetPedFleeAttributes(k9Ped, 0, 0)

      local blip = AddBlipForEntity(k9Ped)
      SetBlipAsFriendly(blip, true)
      SetBlipSprite(blip, 442)
      SetEntityHeading(k9Ped, GetEntityHeading(k9Vehicle) - 180)

      TaskFollowToOffsetOfEntity(k9Ped, PlayerPedId(), 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
      Citizen.Wait(2000)
      SetVehicleDoorShut(k9Vehicle, 5, false)
      SetVehicleDoorShut(k9Vehicle, 6, false)
      DogThread()
    else
      ShowNotification(Config.Translations.InvalidK9Veh)
    end
  else
    ShowNotification(Config.Translations.AlreadyCallK9)
  end
end)

function DogThread()
  Citizen.CreateThread(function()
    local isShowingHelp = false
    while true do
      if not DoesEntityExist(k9Ped) then
        break
      end

      local waitTime = 500
      local playerPed = PlayerPedId()

      if IsPlayerFreeAiming(PlayerId()) then
        waitTime = 5
        local found, targetEntity = GetEntityPlayerIsFreeAimingAt(PlayerId())

        if found and targetEntity then
          if IsEntityAPed(targetEntity) and targetEntity ~= k9Ped then
            if Config.CustomNotify then
              ShowHelpNotification("E", Config.Translations.k9Attack)
              isShowingHelp = true
            elseif Config.Framework == "qbcore" then
              if not isShowingHelp then
                exports["qb-core"]:DrawText("[E] " .. Config.Translations.k9Attack, "left")
                isShowingHelp = true
              end
            elseif Config.Framework == "esx" then
              Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. Config.Translations.k9Attack, true)
            end

            if IsControlJustPressed(0, 38) then
              TaskPlayAnim(playerPed, "swat", "you_fwd", 1.0, 4.0, -1, 48, 0, false, false, false)
              TaskCombatPed(k9Ped, targetEntity, 0, 16)
            end
          end
        elseif isShowingHelp then
          HideHelpNotification()
          isShowingHelp = false
        end
      elseif isShowingHelp then
        HideHelpNotification()
        isShowingHelp = false
      end
      Citizen.Wait(waitTime)
    end
    k9Ped = 0
  end)
end

RegisterKeyMapping(Config.Commands.K9Menu.cmd, Config.Commands.K9Menu.description, "keyboard", Config.Commands.K9Menu.key)

RegisterCommand(Config.Commands.K9Menu.cmd, function()
  if IsNuiFocused() then
    return
  end

  if k9Ped ~= 0 then
    local menuOptions = {
      {
        header = Config.Translations.K9Title,
        isMenuHeader = true
      },
      {
        header = Config.Translations.K9Follow,
        txt = Config.Translations.K9FollowDesc,
        icon = "fa-solid fa-paw",
        params = {
          event = "origen_police:client:HandleK9",
          args = "followme"
        }
      },
      {
        header = Config.Translations.K9DontMove,
        txt = Config.Translations.K9DontMoveDesc,
        icon = "fa-solid fa-hand",
        params = {
          event = "origen_police:client:HandleK9",
          args = "stop"
        }
      },
      {
        header = Config.Translations.K9Sit,
        txt = Config.Translations.K9SitDesc,
        icon = "fa-solid fa-chair",
        params = {
          event = "origen_police:client:HandleK9",
          args = "sit"
        }
      },
      {
        header = Config.Translations.K9LieDown,
        txt = Config.Translations.K9LieDownDesc,
        icon = "fa-solid fa-water",
        params = {
          event = "origen_police:client:HandleK9",
          args = "lay"
        }
      },
      {
        header = Config.Translations.K9SearhArea,
        txt = Config.Translations.K9SearhAreaDesc,
        icon = "fa-solid fa-magnifying-glass",
        params = {
          event = "origen_police:client:HandleK9",
          args = "search"
        }
      },
      {
        header = Config.Translations.K9ReturnCar,
        txt = Config.Translations.K9ReturnCarDesc,
        icon = "fa-solid fa-truck",
        params = {
          event = "origen_police:client:HandleK9",
          args = "gohome"
        }
      }
    }
    OpenMenu(menuOptions)
  end
end)

RegisterNetEvent("origen_police:client:HandleK9", function(action)
  local playerPed = PlayerPedId()

  if action == "followme" then
    TaskPlayAnim(playerPed, "swat", "come", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(1000)
    TaskFollowToOffsetOfEntity(k9Ped, playerPed, 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
  elseif action == "stop" then
    TaskPlayAnim(playerPed, "swat", "freeze", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(1000)
    ClearPedTasks(k9Ped)
  elseif action == "sit" then
    TaskPlayAnim(playerPed, "gestures@f@standing@casual", "gesture_hand_down", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(1000)
    ClearPedTasks(k9Ped)
    TaskPlayAnim(k9Ped, "creatures@rottweiler@amb@world_dog_sitting@idle_a", "idle_b", 2.0, -2.0, -1, 2, 0.0, false, false, false)
  elseif action == "lay" then
    TaskPlayAnim(playerPed, "gestures@f@standing@casual", "gesture_hand_down", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(500)
    TaskPlayAnim(playerPed, "gestures@f@standing@casual", "gesture_hand_down", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(500)
    ClearPedTasks(k9Ped)
    TaskPlayAnim(k9Ped, "creatures@rottweiler@amb@sleep_in_kennel@", "sleep_in_kennel", 2.0, -2.0, -1, 2, 0.0, false, false, false)
  elseif action == "search" then
    TaskPlayAnim(playerPed, "swat", "rally_point", 8.0, -8.0, -1, 48, 0, false, false, false)
    Citizen.Wait(1000)
    SetBlockingOfNonTemporaryEvents(k9Ped, true)
    local playerCoords = GetEntityCoords(playerPed)
    TaskWanderInArea(k9Ped, playerCoords.x, playerCoords.y, playerCoords.z, Config.K9.SearchRadious, 1, 1.0)
    Debuger("K9 Search started at: ", playerCoords, "Radius: ", Config.K9.SearchRadious, "Time: ", GetGameTimer())
    Citizen.Wait(Config.Debug and 1000 or 30000)
    SetBlockingOfNonTemporaryEvents(k9Ped, false)
    local targets = {}
    local nearbyPlayers = FW_GetPlayersFromCoords(GetEntityCoords(playerPed), Config.K9.SearchRadious)
    for _, player in pairs(nearbyPlayers) do
      local serverId = GetPlayerServerId(player)
      local targetPed = GetPlayerPed(player)
      targets[serverId] = targetPed
    end
    local playerCoordsForVeh = GetEntityCoords(playerPed)
    local nearbyVehicles = FW_GetVehicles()
    for _, vehicle in pairs(nearbyVehicles) do
      local distance = #(GetEntityCoords(vehicle) - playerCoordsForVeh)
      if distance < Config.K9.SearchRadious then
        local plate = GetVehiclePlate(vehicle)
        targets[plate] = vehicle
      end
    end
    Debuger("K9 Search targets: ", json.encode(targets, { indent = true }), "Time: ", GetGameTimer())
    FW_TriggerCallback("origen_police:server:K9Search", function(result)
      Debuger("K9 Search result: ", result)
      if result and targets[result] then
        ShowNotification(Config.Translations.K9Found)
        TaskFollowToOffsetOfEntity(k9Ped, targets[result], 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
        while #(GetEntityCoords(k9Ped) - GetEntityCoords(targets[result])) > 5 do
          Citizen.Wait(200)
        end
        TaskPlayAnim(k9Ped, "creatures@rottweiler@amb@world_dog_barking@idle_a", "idle_a", 8.0, -8.0, -1, 2, 0.0, false, false, false)
      else
        TaskFollowToOffsetOfEntity(k9Ped, playerPed, 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
        ShowNotification(Config.Translations.K9NotFound)
      end
    end, targets)
  elseif action == "gohome" then
    if not IsEntityDead(k9Ped) then
      local vehicles = FW_GetVehicles()
      local targetVehicle = 0
      local playerCoords = GetEntityCoords(playerPed)
      for i = 1, #vehicles do
        local vehicleModel = GetEntityModel(vehicles[i])
        if Config.K9.Vehicles[vehicleModel] then
          local distance = #(GetEntityCoords(vehicles[i]) - playerCoords)
          if distance < 40 then
            targetVehicle = vehicles[i]
            NetworkRequestControlOfEntity(targetVehicle)
            Citizen.Wait(50)
            if NetworkHasControlOfEntity(targetVehicle) then
              break
            end
          end
        end
      end
      TaskPlayAnim(playerPed, "swat", "rally_point", 8.0, -8.0, -1, 48, 0, false, false, false)
      Citizen.Wait(1000)
      if targetVehicle ~= 0 then
        TaskFollowToOffsetOfEntity(k9Ped, targetVehicle, 0.5, -1.0, 0.0, 5.0, -1, 1.0, true)
        Citizen.CreateThread(function()
          while #(GetEntityCoords(k9Ped) - GetEntityCoords(targetVehicle)) > 5 do
            Citizen.Wait(200)
          end
          DeleteEntity(k9Ped)
        end)
      else
        DeleteEntity(k9Ped)
      end
    else
      DeleteEntity(k9Ped)
    end
  end
end)