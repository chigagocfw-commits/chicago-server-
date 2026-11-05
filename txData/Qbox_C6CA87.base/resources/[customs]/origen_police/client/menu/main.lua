local isTabletOpen = false
local tabletProp = nil
local isAdminCached = nil

RegisterNetEvent("origen_police:client:OpenPoliceCad", function()
  local playerData = FW_GetPlayerData(false)
  if not playerData or not playerData.job or not playerData.job.name then
    FW_Notify(Config.Translations.CantUseItem or "You cannot use this")
    return
  end
  
  local result = CanOpenTablet(playerData.job.name)
  local canOpen = result[1]
  
  if not canOpen then
    FW_Notify(Config.Translations.CantUseItem or "You cannot use this")
    return
  end

  -- Only open tablet if player has permission
  if not isTabletOpen then
    TogglePause(true)
  end
end)

RegisterNUICallback("close", function(data, cb)
  if isTabletOpen then
    TogglePause(false)
    isTabletOpen = true
    Citizen.Wait(100)
    isTabletOpen = false
  end
  cb(true)
end)

function TogglePause(stateOverride, keepInputFocus)
  local playerData = FW_GetPlayerData(false)
  if not (playerData and playerData.job and playerData.job.name) then
    return
  end
  
  -- Check if player can open tablet
  local result = CanOpenTablet(playerData.job.name)
  local canOpen = result[1]
  if not canOpen then
    FW_Notify(Config.Translations.CantUseItem)
    return
  end

  if isAdminCached == nil then
    FW_TriggerCallback("origen_police:server:getAdminState", function(isAdmin)
      isAdminCached = isAdmin
    end)
    while isAdminCached == nil do
      Citizen.Wait(0)
    end
  end

  SetNuiFocusKeepInput(false)
  DisableAllControlActions(0)
  Citizen.Wait(1)

  if stateOverride ~= nil then
    isTabletOpen = stateOverride
  else
    isTabletOpen = not isTabletOpen
  end

  if isTabletOpen then
    Citizen.CreateThread(function()
      while isTabletOpen do
        DisableAllControlActions(0)
        EnableControlAction(0, 249, true) -- INPUT_FRONTEND_PAUSE
        EnableControlAction(1, 249, true)
        EnableControlAction(2, 249, true)
        Wait(0)
      end
      while IsControlPressed(0, 200) or IsDisabledControlPressed(0, 200) do
        Citizen.Wait(0)
        DisableControlAction(0, 200, true) -- INPUT_FRONTEND_PAUSE_ALTERNATE
      end
      DisableControlAction(0, 200, true)
    end)

    local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@idle_a"
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
      Wait(500)
    end

    local propName = "prop_cs_tablet"
    if not IsPedInAnyVehicle(PlayerPedId(), false) then
      TaskPlayAnim(PlayerPedId(), animDict, "idle_a", 2.0, 3.0, -1, 51, 0, false, false, false)
      tabletProp = CreateObject(GetHashKey(propName), 0.0, 0.0, 0.0, true, true, true)
      AttachEntityToEntity(tabletProp, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), -0.05, 0.0, 0.0, 0.0, 0.0, 0.0, true, true, false, true, 1, true)
    end

    local nuiData = {
      open = true,
      translations = Config.Translations,
      permissions = exports.origen_police:GerPermissions(),
      isAdmin = isAdminCached,
      jobData = {
        duty = playerData.job.onduty,
        name = playerData.job.name,
        level = playerData.job.grade.level
      },
      jobCategories = Config.JobCategory,
      options = {
        GuideBtn = Config.ShowGuideButton
      }
    }

    SendNUIMessage(nuiData)
    Debuger("Open cad data: ", json.encode(nuiData, { indent = true }))

    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(keepInputFocus)
  else
    if tabletProp ~= nil then
      ClearPedSecondaryTask(PlayerPedId())
      DetachEntity(tabletProp, false, false)
      DeleteEntity(tabletProp)
      tabletProp = nil
    end
    SetNuiFocus(false, false)
  end
end

RegisterNUICallback("ExecuteCommand", function(data, cb)
  ExecuteCommand(data.command)
  cb(true)
end)

RegisterNUICallback("SetWaypointinCoords", function(data, cb)
  SetNewWaypoint(data.x, data.y)
  cb(true)
end)

RegisterNUICallback("GetClosestPlayers", function(data, cb)
  local nearbyPlayerHandles = exports.origen_police:FW_GetPlayersFromCoords(GetEntityCoords(PlayerPedId()), 10.0)
  local nearbyServerIds = {}
  for i = 1, #nearbyPlayerHandles do
    nearbyServerIds[i] = GetPlayerServerId(nearbyPlayerHandles[i])
  end

  exports.origen_police:FW_TriggerCallback("origen_police:server:GetClosestPlayers", function(result)
    cb(result)
  end, nearbyServerIds, data)
end)

RegisterNUICallback("GetCoords", function(data, cb)
  local coords = GetEntityCoords(PlayerPedId())
  local heading = GetEntityHeading(PlayerPedId())
  cb({
    x = coords.x,
    y = coords.y,
    z = coords.z,
    w = heading
  })
end)

exports("SendNUIMessage", SendNUIMessage)
exports("TogglePause", TogglePause)
exports("InTablet", function()
  return isTabletOpen
end)

RegisterNUICallback("showGameMenu", function(data, cb)
  ActivateFrontendMenu(GetHashKey(data.menu), false, -1)
  cb(true)
end)

RegisterNetEvent("origen_police:ForceNotification", function(notifyData)
  SendNUIMessage({
    action = "ForceNotification",
    notify = notifyData
  })
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    if tabletProp then
      DeleteEntity(tabletProp)
    end
  end
end)

if Config.Commands.OpenPoliceCad.cmd then
  RegisterCommand(Config.Commands.OpenPoliceCad.cmd, function(source, args)
    TriggerEvent("origen_police:client:OpenPoliceCad")
  end, false)

  RegisterKeyMapping(Config.Commands.OpenPoliceCad.cmd, Config.Commands.OpenPoliceCad.description, "keyboard", Config.Commands.OpenPoliceCad.key)
end