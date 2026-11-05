TruckingMission = TruckingMission or {}
TruckingMission.Client = TruckingMission.Client or {}

local missionActive = false
local missionData
local truck
local cargoTrailer
local attachedVehicles = {}
local pickupCoords
local cargoAttached = false
local spawnBlip
local pickupBlip
local dropoffBlip
local routeBlip
local missionStage
local lastInstructionKey
local pickupHasMediumVehicles = false
local cargoSpawned = false
local cargoVehiclesLoaded = false

local function deleteTruck()
  if truck and DoesEntityExist(truck) then
    local plate = GetVehicleNumberPlateText(truck)
    if plate then
      Framework.Client.VehicleRemoveKeys(plate, truck, "truckingMission")
    end

    DeleteEntity(truck)
  end

  truck = nil
end

local function deleteCargo()
  for _, vehicle in pairs(attachedVehicles) do
    if vehicle and DoesEntityExist(vehicle) then
      DetachEntity(vehicle, false, false)
      DeleteEntity(vehicle)
    end
  end

  attachedVehicles = {}

  if cargoTrailer and DoesEntityExist(cargoTrailer) then
    DeleteEntity(cargoTrailer)
  end

  cargoTrailer = nil
end

local function normalizeCoords(coords)
  if type(coords) == "table" and coords[1] then
    coords = coords[1]
  end

  if not coords or not coords.x or not coords.y then
    return nil
  end

  return coords
end

local function createBlip(coords, sprite, colour, scale, label)
  coords = normalizeCoords(coords)
  if not coords then
    DebugPrint("Tried to create trucking blip without valid coordinates", "warning")
    return nil
  end

  local blip = AddBlipForCoord(coords.x, coords.y, coords.z or 0.0)
  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, colour)
  SetBlipScale(blip, scale)
  SetBlipAsShortRange(blip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(label)
  EndTextCommandSetBlipName(blip)
  return blip
end

local function removeBlip(blip)
  if blip and DoesBlipExist(blip) then
    RemoveBlip(blip)
  end
end

local function removePickupBlip()
  removeBlip(pickupBlip)
  pickupBlip = nil
end

local function setRoute(coords)
  coords = normalizeCoords(coords)
  if not coords then
    DebugPrint("Tried to route trucking blip without valid coordinates", "warning")
    return
  end

  if routeBlip and DoesBlipExist(routeBlip) then
    SetBlipRoute(routeBlip, false)
    RemoveBlip(routeBlip)
  end

  routeBlip = AddBlipForCoord(coords.x, coords.y, coords.z or 0.0)
  SetBlipRoute(routeBlip, true)
  SetBlipRouteColour(routeBlip, 47)
  SetNewWaypoint(coords.x, coords.y)
end

local function clearRoute()
  if routeBlip and DoesBlipExist(routeBlip) then
    SetBlipRoute(routeBlip, false)
    RemoveBlip(routeBlip)
  end

  routeBlip = nil
  DeleteWaypoint()
end

local function isExpectedCargo(entity)
  if not entity or entity == 0 or not DoesEntityExist(entity) then
    return false
  end

  if cargoAttached and entity == cargoTrailer then
    return true
  end

  if not pickupCoords then
    return false
  end

  return #(GetEntityCoords(entity) - pickupCoords) < 10.0
end

local function getEntityNetId(entity, timeoutMs)
  if not entity or entity == 0 or not DoesEntityExist(entity) then
    return nil
  end

  local netId = NetworkGetNetworkIdFromEntity(entity)
  if netId and netId ~= 0 then
    return netId
  end

  local ok = pcall(function()
    lib.waitFor(function()
      if not DoesEntityExist(entity) then
        return nil
      end

      netId = NetworkGetNetworkIdFromEntity(entity)
      return netId and netId ~= 0 or nil
    end, nil, timeoutMs or 10000)
  end)

  return ok and netId or nil
end

local function getVehicleFromNetId(netId, timeoutMs)
  if not netId or netId == 0 then
    return nil
  end

  local vehicle = NetToVeh(netId)
  if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
    return vehicle
  end

  local ok = pcall(function()
    lib.waitFor(function()
      if NetworkDoesNetworkIdExist(netId) and NetworkDoesEntityExistWithNetworkId(netId) then
        vehicle = NetToVeh(netId)
        return vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) or nil
      end
    end, nil, timeoutMs or 10000)
  end)

  return ok and vehicle or nil
end

local function setStage(stage)
  missionStage = stage
  lib.callback.await("jg-dealerships:server:trucking:update-stage", false, stage)
end

local function showInstruction(text, keys, warning)
  local key = text .. (warning or "")

  if keys then
    for _, item in ipairs(keys) do
      key = key .. item.key .. item.desc
    end
  end

  if key == lastInstructionKey then
    return
  end

  lastInstructionKey = key
  Interactions.Client.InstrPrmt.Show(text, keys, false, warning)
end

local function hideInstruction()
  lastInstructionKey = nil
  Interactions.Client.InstrPrmt.Hide()
end

local function resetMission()
  missionActive = false
  missionData = nil
  missionStage = nil
  pickupCoords = nil
  cargoAttached = false
  lastInstructionKey = nil
  pickupHasMediumVehicles = false
  cargoSpawned = false
  cargoVehiclesLoaded = false

  deleteTruck()
  deleteCargo()
  removeBlip(spawnBlip)
  removePickupBlip()
  removeBlip(dropoffBlip)
  clearRoute()

  spawnBlip = nil
  dropoffBlip = nil
  hideInstruction()
  lib.callback.await("jg-dealerships:server:trucking:cancel", false)
end

function TruckingMission.Client.CancelMission()
  if not missionActive then
    return false
  end

  resetMission()
  return true
end

local function startSpawnPrompt()
  if missionStage ~= "spawned" or not missionData or not missionData.truckSpawn then
    return
  end

  local promptState = "normal"

  local function showPrompt()
    showInstruction(Locale.truckingGetInTruck, {
      { key = "E", desc = Locale.keyDismiss }
    })
  end

  showPrompt()

  CreateThread(function()
    while missionActive and missionStage == "spawned" do
      if truck and DoesEntityExist(truck) then
        local coords = GetEntityCoords(truck)
        local marker = TruckingConfig.Markers.spawn

        Utils.Client.DrawMarkerOnFrame(
          marker.type,
          vector3(coords.x, coords.y, coords.z + 4.0),
          marker.size,
          marker.color,
          vector3(0, 0, 0),
          vector3(0, 0, 0),
          marker.bobUpAndDown,
          marker.faceCamera,
          marker.rotate,
          false
        )

        if promptState == "normal" then
          showPrompt()
        end
      end

      if IsControlJustPressed(0, 38) and promptState == "normal" then
        promptState = "dismissed"
        hideInstruction()
      end

      Wait(0)
    end
  end)
end

local function aggregateVehicleModels(vehicles)
  local grouped = {}

  for _, vehicle in ipairs(vehicles) do
    local found

    for _, groupedVehicle in ipairs(grouped) do
      if groupedVehicle.model == vehicle.model then
        groupedVehicle.quantity = groupedVehicle.quantity + 1
        found = true
        break
      end
    end

    if not found then
      grouped[#grouped + 1] = {
        model = vehicle.model,
        quantity = 1
      }
    end
  end

  return grouped
end

local function spawnCargoAtPickup(pickupStop)
  local spawnSucceeded, serverNetId, spawnOnClient = lib.callback.await("jg-dealerships:server:trucking:spawn-cargo", false)
  if not spawnSucceeded then
    return false
  end

  local trailerModel
  local useMixedVehicleLoader = false

  if missionData.trailerType == "container" then
    trailerModel = TruckingConfig.TrailerLargeVehicle
    cargoVehiclesLoaded = true
  else
    if TruckingConfig.TrailerSmallVehicle == "DYNAMIC_TR2" then
      trailerModel = "tr2"
      useMixedVehicleLoader = true
    else
      trailerModel = TruckingConfig.TrailerSmallVehicle
      cargoVehiclesLoaded = true
    end
  end

  if spawnOnClient then
    cargoTrailer = Spawn.Client.Create(0, trailerModel, false, pickupStop.location.coords, false, TruckingConfig.CargoProperties or {}, "truckingMission")
    if not cargoTrailer then
      return false
    end

    SetEntityAsMissionEntity(cargoTrailer, true, true)
    Wait(200)
    SetVehicleOnGroundProperly(cargoTrailer)
    Wait(200)
    SetVehicleOnGroundProperly(cargoTrailer)
    Wait(100)
    SetEntityHeading(cargoTrailer, pickupStop.location.coords.w)

    local netId = getEntityNetId(cargoTrailer)
    if not netId or not lib.callback.await("jg-dealerships:server:trucking:set-cargo", false, netId) then
      return false
    end
  else
    cargoTrailer = getVehicleFromNetId(serverNetId, 15000)
    if not cargoTrailer then
      return false
    end
  end

  if useMixedVehicleLoader and missionData.trailerType == "car" and cargoTrailer and DoesEntityExist(cargoTrailer) then
    for _, vehicle in ipairs(pickupStop.vehicles) do
      if TrailerAttachment.Client.GetVehicleSizeCategory(vehicle.model) == "medium" then
        pickupHasMediumVehicles = true
        break
      end
    end

    local groupedVehicles = aggregateVehicleModels(pickupStop.vehicles)
    local attachedOk, spawnedVehicles = TrailerAttachment.Client.AttachMixedVehicles(cargoTrailer, groupedVehicles)

    if attachedOk and spawnedVehicles then
      attachedVehicles = spawnedVehicles
      cargoVehiclesLoaded = true
      local count = #pickupStop.vehicles
      local suffix = count > 1 and "s" or ""
      Framework.Client.Notify(Locale.truckingVehiclesLoaded:gsub("%%{count}", count):gsub("%%{s}", suffix), "success")
    end
  end

  return true
end

local function startDropoffLoop()
  if missionStage ~= "driving_to_dropoff" and missionStage ~= "at_dropoff" then
    return
  end

  if not missionData or not missionData.dropoffCoords then
    return
  end

  local dropoffCoords = missionData.dropoffCoords
  local marker = TruckingConfig.Markers.dropoff
  local promptState = "normal"

  showInstruction(Locale.truckingDriveToDelivery, {
    { key = "E", desc = Locale.keyDismiss }
  })

  CreateThread(function()
    while missionActive and (missionStage == "driving_to_dropoff" or missionStage == "at_dropoff") do
      local playerCoords = GetEntityCoords(cache.ped)
      local distance = #(playerCoords - vector3(dropoffCoords.x, dropoffCoords.y, dropoffCoords.z))

      if distance < 50.0 then
        Utils.Client.DrawMarkerOnFrame(
          marker.type,
          vector3(dropoffCoords.x, dropoffCoords.y, dropoffCoords.z - 1.0),
          marker.size,
          marker.color,
          vector3(0, 0, 0),
          vector3(0, 0, 0),
          marker.bobUpAndDown,
          marker.faceCamera,
          marker.rotate,
          false
        )
      end

      local warning
      if truck and DoesEntityExist(truck) then
        if IsVehicleAttachedToTrailer(truck) then
          local _, trailer = GetVehicleTrailerVehicle(truck)
          if isExpectedCargo(trailer) then
            cargoTrailer = trailer
            cargoAttached = true
          else
            warning = Locale.truckingWrongTrailer
          end
        else
          warning = Locale.truckingTrailerNotAttached
        end
      end

      local canDeliver = distance < 5.0 and not warning

      if canDeliver then
        promptState = "normal"
        showInstruction(Locale.truckingCompleteDelivery, {
          { key = "E", desc = Locale.keyDeliverCargo }
        })
      elseif promptState == "normal" then
        showInstruction(Locale.truckingDriveToDelivery, {
          { key = "E", desc = Locale.keyDismiss }
        }, warning)
      end

      if IsControlJustPressed(0, 38) then
        if canDeliver then
          hideInstruction()
          setStage("at_dropoff")

          local trailerNetId = 0
          if truck and IsVehicleAttachedToTrailer(truck) then
            local _, trailer = GetVehicleTrailerVehicle(truck)
            if trailer then
              trailerNetId = NetworkGetNetworkIdFromEntity(trailer)
            end
          end

          if truck and DoesEntityExist(truck) then
            local plate = GetVehicleNumberPlateText(truck)
            if plate then
              Framework.Client.VehicleRemoveKeys(plate, truck, "truckingMission")
            end
          end

          if lib.callback.await("jg-dealerships:server:trucking:complete", false, trailerNetId) then
            Framework.Client.Notify(Locale.truckingDeliveryComplete, "success")
            resetMission()
            return
          end

          Framework.Client.Notify(Locale.truckingDeliveryFailed, "error")
          setStage("driving_to_dropoff")
        elseif promptState == "normal" then
          promptState = "dismissed"
          hideInstruction()
        end
      end

      Wait(0)
    end
  end)
end

local function startPickupLoop()
  if missionStage ~= "driving_to_pickup" and missionStage ~= "at_pickup" then
    return
  end

  if not missionData or not missionData.pickupStop then
    return
  end

  local pickupStop = missionData.pickupStop
  local promptState = "normal"

  showInstruction(Locale.truckingDriveToPickup, {
    { key = "E", desc = Locale.keyDismiss }
  })

  CreateThread(function()
    while missionActive and (missionStage == "driving_to_pickup" or missionStage == "at_pickup") do
      local playerCoords = GetEntityCoords(cache.ped)
      local stopCoords = pickupStop.location.coords
      local distance = #(playerCoords - vector3(stopCoords.x, stopCoords.y, stopCoords.z))

      if not cargoSpawned and distance < 100.0 then
        cargoSpawned = true
        pickupCoords = vector3(stopCoords.x, stopCoords.y, stopCoords.z)

        if not spawnCargoAtPickup(pickupStop) then
          Framework.Client.Notify(Locale.truckingMissionFailedSpawnCargo, "error")
          resetMission()
          return
        end
      end

      if cargoTrailer and DoesEntityExist(cargoTrailer) and distance < 50.0 then
        local trailerCoords = GetEntityCoords(cargoTrailer)
        local marker = TruckingConfig.Markers.pickup

        Utils.Client.DrawMarkerOnFrame(
          marker.type,
          vector3(trailerCoords.x, trailerCoords.y, trailerCoords.z + 4.0),
          marker.size,
          marker.color,
          vector3(0, 0, 0),
          vector3(0, 0, 0),
          marker.bobUpAndDown,
          marker.faceCamera,
          marker.rotate,
          false
        )
      end

      local truckAtTrailer = truck and cache.vehicle == truck and cargoTrailer and DoesEntityExist(cargoTrailer) and #(playerCoords - GetEntityCoords(cargoTrailer)) < 15.0
      local truckHasTrailer = truck and IsVehicleAttachedToTrailer(truck)
      local warning
      local readyForDropoff = false

      if truckHasTrailer then
        local _, trailer = GetVehicleTrailerVehicle(truck)
        if isExpectedCargo(trailer) then
          cargoTrailer = trailer
          cargoAttached = true
          readyForDropoff = cargoVehiclesLoaded
        else
          warning = Locale.truckingWrongTrailer
        end
      end

      if readyForDropoff then
        hideInstruction()
        setStage("driving_to_dropoff")
        removePickupBlip()

        if missionData.dropoffCoords then
          local blipConfig = TruckingConfig.Blips.dropoff
          dropoffBlip = createBlip(missionData.dropoffCoords, blipConfig.sprite, blipConfig.color, blipConfig.scale, blipConfig.label)
          setRoute(missionData.dropoffCoords)
        end

        startDropoffLoop()
        return
      elseif truckHasTrailer and not cargoVehiclesLoaded then
        promptState = "normal"
        showInstruction(Locale.truckingWaitingForVehicles, {}, warning)
      elseif truckHasTrailer then
        promptState = "normal"
        showInstruction(Locale.truckingTrailerAttached, {}, warning)
      elseif truckAtTrailer then
        promptState = "normal"
        showInstruction(Locale.truckingDriveUnderTrailer, {})
      elseif cache.vehicle == truck then
        if promptState == "normal" then
          showInstruction(Locale.truckingDriveToPickup, {
            { key = "E", desc = Locale.keyDismiss }
          })
        end
      else
        promptState = "normal"
        showInstruction(Locale.truckingGetInTruckContinue, {
          { key = "E", desc = Locale.keyDismiss }
        })
      end

      if IsControlJustPressed(0, 38) and promptState == "normal" then
        promptState = "dismissed"
        hideInstruction()
      end

      Wait(0)
    end
  end)
end

local function watchForTruckEntry()
  CreateThread(function()
    while missionActive and missionStage == "spawned" do
      if cache.vehicle and cache.vehicle == truck and missionData then
        hideInstruction()
        setStage("driving_to_pickup")
        removeBlip(spawnBlip)
        spawnBlip = nil

        if missionData.pickupStop then
          local pickupConfig = TruckingConfig.Blips.pickup
          pickupBlip = createBlip(missionData.pickupStop.location.coords, pickupConfig.sprite, pickupConfig.color, pickupConfig.scale, "Pickup Location")
          setRoute(missionData.pickupStop.location.coords)
        end

        startPickupLoop()
        return
      end

      Wait(500)
    end
  end)
end

lib.callback.register("jg-dealerships:client:trucking:start-mission", function(serverTruckNetId)
  if missionActive then
    return false, "You already have an active mission"
  end

  local valid, errorMessage, data = lib.callback.await("jg-dealerships:server:trucking:validate-mission", false)
  if not valid then
    return false, errorMessage or "Mission validation failed"
  end

  missionActive = true
  missionData = data
  missionStage = "spawned"

  local spawnCoords = Utils.Client.FindAvailableSpawnCoords(Utils.Client.ConvertSpawnCoordsToVec4(data.truckSpawn))

  if data.spawnOnClient then
    truck = Spawn.Client.Create(0, TruckingConfig.TruckModel, false, spawnCoords, false, TruckingConfig.TruckProperties or {}, "truckingMission")

    if not truck then
      missionActive = false
      missionData = nil
      missionStage = nil
      return false, "Could not spawn truck"
    end

    local netId = getEntityNetId(truck)
    if not netId or not lib.callback.await("jg-dealerships:server:trucking:set-truck", false, netId) then
      deleteTruck()
      missionActive = false
      missionData = nil
      missionStage = nil
      return false, "Could not register truck"
    end
  else
    if not serverTruckNetId or serverTruckNetId == 0 then
      missionActive = false
      missionData = nil
      missionStage = nil
      return false, "Could not spawn truck"
    end

    truck = getVehicleFromNetId(serverTruckNetId)
    if not truck then
      missionActive = false
      missionData = nil
      missionStage = nil
      return false, "Could not find spawned truck"
    end
  end

  local blipConfig = TruckingConfig.Blips.spawn
  spawnBlip = createBlip(missionData.truckSpawn, blipConfig.sprite, blipConfig.color, blipConfig.scale, blipConfig.label)

  startSpawnPrompt()
  watchForTruckEntry()

  local pickupName = missionData.pickupStop and missionData.pickupStop.location and missionData.pickupStop.location.name or "pickup location"
  Framework.Client.Notify(Locale.truckingMissionStarted:gsub("%%{location}", pickupName), "success")

  return true
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() and missionActive then
    resetMission()
  end
end)

lib.callback.register("jg-dealerships:client:cancel-trucking-mission", function()
  if TruckingMission.Client.CancelMission() then
    Framework.Client.Notify(Locale.truckingMissionCancelled, "success")
    return true
  end

  Framework.Client.Notify(Locale.truckingNoActiveMission, "error")
  return false
end)
