DisplayVehicles = DisplayVehicles or {}
DisplayVehicles.Client = DisplayVehicles.Client or {}

local displayVehiclesByLocation = {}
local isSpawning = {}
local respawnRequested = {}
local isCreatingDisplayVehicle = false

local function deleteLocationVehicles(locationId)
  local displayVehicles = displayVehiclesByLocation[locationId]

  if displayVehicles and #displayVehicles > 0 then
    for _, displayVehicle in ipairs(displayVehicles) do
      displayVehicle._removed = true

      if displayVehicle.activeInteraction then
        Interactions.Client.Handler.RemoveEntityInteraction(displayVehicle.activeInteraction)
        displayVehicle.activeInteraction = nil
      end

      if displayVehicle.entity and DoesEntityExist(displayVehicle.entity) then
        DeleteEntity(displayVehicle.entity)
      end

      displayVehicle.entity = nil

      if displayVehicle.streamingPoint then
        displayVehicle.streamingPoint:remove()
        displayVehicle.streamingPoint = nil
      end
    end
  end

  displayVehiclesByLocation[locationId] = {}
end

function DisplayVehicles.Client.DeleteAll()
  for locationId in pairs(displayVehiclesByLocation) do
    deleteLocationVehicles(locationId)
  end
end

function DisplayVehicles.Client.DeleteLocation(locationId)
  deleteLocationVehicles(locationId)
end

function DisplayVehicles.Client.SpawnAll(locationId)
  if isSpawning[locationId] then
    respawnRequested[locationId] = true
    return
  end

  isSpawning[locationId] = true
  respawnRequested[locationId] = false

  CreateThread(function()
    deleteLocationVehicles(locationId)

    local displayVehicles = lib.callback.await("jg-dealerships:server:get-display-vehicles", false, locationId)
    if not displayVehicles then
      isSpawning[locationId] = false

      if respawnRequested[locationId] then
        DisplayVehicles.Client.SpawnAll(locationId)
      end

      return
    end

    local spawnedVehicles = {}

    for _, displayVehicle in ipairs(displayVehicles) do
      local coords = json.decode(displayVehicle.coords)
      local color = displayVehicle.color
      local prompt = Config.ViewInShowroomPrompt

      if (Config.DrawText == "auto" and GetResourceState("jg-textui") == "started") or Config.DrawText == "jg-textui" then
        prompt = ("<h4 style='margin-bottom:5px'>%s %s</h4><p>%s</p>"):format(
          displayVehicle.brand or "",
          displayVehicle.model or "",
          Config.ViewInShowroomPrompt
        )
      end

      local vehicle = Interactions.Client.Vehicle.Create(
        vector4(coords.x, coords.y, coords.z, coords.w),
        displayVehicle.vehicle,
        color,
        prompt,
        Config.ViewInShowroomKeyBind,
        function()
          if not isCreatingDisplayVehicle then
            Showroom.Client.Open(locationId, displayVehicle.vehicle, color)
          end
        end,
        function()
          return Locations.Client.HasShowroomAccess(locationId)
        end
      )

      if vehicle.entity and DoesEntityExist(vehicle.entity) then
        Entity(vehicle.entity).state:set("isDisplayVehicle", true, false)
        SetVehicleNumberPlateText(vehicle.entity, Config.DisplayVehiclesPlate)
      end

      spawnedVehicles[#spawnedVehicles + 1] = vehicle
    end

    displayVehiclesByLocation[locationId] = spawnedVehicles
    isSpawning[locationId] = false

    if respawnRequested[locationId] then
      DisplayVehicles.Client.SpawnAll(locationId)
    end
  end)
end

RegisterNetEvent("jg-dealerships:client:spawn-display-vehicles", function(locationId)
  DisplayVehicles.Client.SpawnAll(locationId)
end)

RegisterNUICallback("create-display-vehicle", function(data, callback)
  if isCreatingDisplayVehicle then
    return callback(false)
  end

  Framework.Client.HideTextUI()
  isCreatingDisplayVehicle = true

  SetNuiFocus(false, false)

  local coords = Interactions.Client.Vehicle.StartCreator(data.spawnCode, data.color, {
    locationId = data.dealershipId,
    errorMessage = Locale.displayVehicleOutsideZone,
  })

  SetNuiFocus(true, true)
  isCreatingDisplayVehicle = false

  if coords then
    lib.callback.await(
      "jg-dealerships:server:create-display-vehicle",
      false,
      data.dealershipId,
      data.spawnCode,
      data.color,
      coords
    )

    DealershipManagement.Client.Open(data.dealershipId, "displayVehicles", data.fromAdmin)
    callback(true)
  else
    DealershipManagement.Client.Open(data.dealershipId, "displayVehicles", data.fromAdmin)
    callback(false)
  end
end)

RegisterNUICallback("edit-display-vehicle", function(data, callback)
  lib.callback.await(
    "jg-dealerships:server:edit-display-vehicle",
    false,
    data.dealershipId,
    data.id,
    data.spawnCode,
    data.color
  )

  callback(true)
end)

RegisterNUICallback("delete-display-vehicle", function(data, callback)
  lib.callback.await("jg-dealerships:server:delete-display-vehicle", false, data.dealershipId, data.id)
  callback(true)
end)

RegisterNUICallback("reset-display-vehicles", function(data, callback)
  DisplayVehicles.Client.SpawnAll(data.dealershipId)
  callback(true)
end)

lib.onCache("vehicle", function(vehicle)
  if vehicle and Entity(vehicle).state.isDisplayVehicle then
    Framework.Client.Notify(Locale.vehicleSecurityBreachDetected, "warning")
    FreezeEntityPosition(vehicle, true)
    SetVehicleAlarm(vehicle, true)
    StartVehicleAlarm(vehicle)
  end
end)

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() == resourceName then
    DisplayVehicles.Client.DeleteAll()
  end
end)
