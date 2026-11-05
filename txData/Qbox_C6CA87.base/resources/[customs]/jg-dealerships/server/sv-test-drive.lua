local showroomTestDrives = {}

DirectTestDrive = DirectTestDrive or {}
DirectTestDrive.Server = DirectTestDrive.Server or {}

local directTestDrives = {}

function DirectTestDrive.Server.GetActiveTestDrives(dealershipId)
  local activeTestDrives = {}
  for _, session in pairs(directTestDrives) do
    if session.dealershipId == dealershipId then
      activeTestDrives[#activeTestDrives + 1] = session
    end
  end

  return activeTestDrives
end

function DirectTestDrive.Server.GetSession(sessionId)
  return directTestDrives[sessionId]
end

local function getTestDriveSpawnCoords(dealership)
  if dealership.test_drive_coords and #dealership.test_drive_coords > 0 then
    return dealership.test_drive_coords
  end

  if dealership.purchase_vehicle_coords and #dealership.purchase_vehicle_coords > 0 then
    return dealership.purchase_vehicle_coords
  end

  return nil
end

local function deleteDirectTestDriveVehicle(session)
  if not session then
    return
  end

  local vehicle = session.vehicleEntity or (session.vehicleNetId and NetworkGetEntityFromNetworkId(session.vehicleNetId))
  if not vehicle or not DoesEntityExist(vehicle) then
    return
  end

  for seat = -1, 5 do
    local ped = GetPedInVehicleSeat(vehicle, seat)
    if ped and ped ~= 0 then
      TaskLeaveVehicle(ped, vehicle, 0)
    end
  end

  SetTimeout(500, function()
    if DoesEntityExist(vehicle) then
      SetVehicleDoorsLocked(vehicle, 2)
      JGDeleteVehicle(vehicle)
    end
  end)
end

lib.callback.register("jg-dealerships:server:start-test-drive", function(playerSource, dealershipId, spawnCoords, vehicleNetId, model, vehicleLabel, plate, colour, originalCoords)
  local vehicleEntity = vehicleNetId and NetworkGetEntityFromNetworkId(vehicleNetId) or nil
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)

  if not playerIdentifier then
    return false
  end

  if not Framework.Server.PlayerHasLicense(playerSource, "driver") then
    Framework.Server.Notify(playerSource, "You need a valid driver's license to test drive a vehicle.", "error")
    return false
  end

  if Config.SpawnVehiclesWithServerSetter then
    local warpIntoVehicle = not Config.DoNotSpawnInsideVehicle
    local vehicleProps = {
      plate = plate,
      colour = colour,
    }

    vehicleNetId, vehicleEntity = Spawn.Server.Create(
      playerSource,
      0,
      model,
      plate,
      spawnCoords,
      warpIntoVehicle,
      vehicleProps,
      "testDrive"
    )
  end

  if not vehicleEntity or vehicleEntity == 0 or not vehicleNetId then
    Framework.Server.Notify(playerSource, Locale.couldNotSpawnVehicle, "error")
    return false
  end

  local originalBucket = 0
  local useTestDriveBucket = not Config.TestDriveNotInBucket

  if useTestDriveBucket then
    if Config.ReturnToPreviousRoutingBucket then
      originalBucket = GetPlayerRoutingBucket(playerSource)
    end

    local routingBucket = math.random(100, 999)
    SetPlayerRoutingBucket(playerSource, routingBucket)
    SetEntityRoutingBucket(vehicleEntity, routingBucket)
  end

  showroomTestDrives[playerIdentifier] = {
    dealershipId = dealershipId,
    originalBucket = originalBucket,
    originalCoords = originalCoords,
    vehicleNetId = vehicleNetId,
    vehicleModel = model,
    vehicleColour = colour,
  }

  SendWebhook(playerSource, Webhooks.TestDrive, "New Test Drive", "success", {
    { key = "Vehicle", value = vehicleLabel },
    { key = "Dealership", value = (Locations.Server.GetById(dealershipId) or {}).name or dealershipId },
    { key = "Plate", value = plate },
  })

  return true, vehicleNetId
end)

lib.callback.register("jg-dealerships:server:finish-test-drive", function(playerSource)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    DebugPrint("jg-dealerships:server:finish-test-drive: no identifier found for player " .. playerSource, "warning")
    return false
  end

  local session = showroomTestDrives[playerIdentifier]
  if not session then
    DebugPrint("jg-dealerships:server:finish-test-drive: no test drive session found for player " .. playerSource, "warning")
    return false
  end

  local vehicle = NetworkGetEntityFromNetworkId(session.vehicleNetId)
  SetEntityVelocity(vehicle, 0, 0, 0)

  for seat = -1, 5 do
    local ped = GetPedInVehicleSeat(vehicle, seat)
    if ped then
      TaskLeaveVehicle(ped, vehicle, 0)
    end
  end

  SetVehicleDoorsLocked(vehicle, 2)

  local playerPed = GetPlayerPed(playerSource)
  local originalCoords = session.originalCoords

  JGDeleteVehicle(vehicle)
  SetEntityCoords(playerPed, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false, false)
  Wait(500)

  if not Config.TestDriveNotInBucket then
    SetPlayerRoutingBucket(playerSource, session.originalBucket)
  end

  showroomTestDrives[playerIdentifier] = nil
  return session
end)

lib.callback.register("jg-dealerships:server:start-direct-test-drive", function(playerSource, dealershipId, customerPlayerId, model, colour)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    return false
  end

  if not Employees.Server.IsEmployee(playerSource, dealershipId, "SELL") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return false
  end

  local activeTestDriveCount = 0
  for _, session in pairs(directTestDrives) do
    if session.dealershipId == dealershipId then
      activeTestDriveCount = activeTestDriveCount + 1
    end
  end

  if activeTestDriveCount >= (Config.DealershipMaxActiveTestDrives or 5) then
    Framework.Server.Notify(playerSource, Locale.maxTestDrivesReached, "error")
    return false
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  local testDriveCoords = getTestDriveSpawnCoords(dealership)
  if not testDriveCoords then
    Framework.Server.Notify(playerSource, Locale.noTestDriveSpawnCoords, "error")
    return false
  end

  local spawnCoords = testDriveCoords[1]
  local plate = Framework.Server.VehicleGeneratePlate(Config.TestDrivePlate or "TEST0000", false)
  if not plate then
    Framework.Server.Notify(playerSource, Locale.couldNotGeneratePlate, "error")
    return false
  end

  local vehicleLabel = Framework.Server.GetVehicleLabel and Framework.Server.GetVehicleLabel(model) or model
  local sellerInfo = Framework.Server.GetPlayerInfo(playerSource)
  local customerInfo = Framework.Server.GetPlayerInfo(customerPlayerId)
  local sessionId = Utils.Server.GenerateUuid()

  local session = {
    id = sessionId,
    dealershipId = dealershipId,
    sellerPlayerId = playerSource,
    sellerName = sellerInfo and sellerInfo.name or "Unknown",
    customerPlayerId = customerPlayerId,
    customerName = customerInfo and customerInfo.name or "Unknown",
    vehicleModel = model,
    vehicleLabel = vehicleLabel,
    plate = plate,
    coords = testDriveCoords,
    colour = colour,
    startTime = os.time(),
  }

  local vehicleNetId
  local vehicleEntity

  if Config.SpawnVehiclesWithServerSetter then
    local vehicleProps = {
      plate = plate,
      colour = colour,
    }

    vehicleNetId, vehicleEntity = Spawn.Server.Create(
      playerSource,
      0,
      model,
      plate,
      spawnCoords,
      false,
      vehicleProps,
      "testDrive"
    )

    if not vehicleEntity or vehicleEntity == 0 or not vehicleNetId then
      Framework.Server.Notify(playerSource, Locale.couldNotSpawnTestDriveVehicle, "error")
      return false
    end

    session.vehicleNetId = vehicleNetId
    session.vehicleEntity = vehicleEntity
  end

  directTestDrives[sessionId] = session

  SendWebhook(playerSource, Webhooks.TestDrive, "New Direct Sale Test Drive", "success", {
    { key = "Vehicle", value = vehicleLabel },
    { key = "Dealership", value = dealership.name or dealershipId },
    { key = "Plate", value = plate },
    { key = "Customer ID", value = tostring(customerPlayerId) },
  })

  return true, testDriveCoords, vehicleNetId, not Config.SpawnVehiclesWithServerSetter, sessionId, plate
end)

lib.callback.register("jg-dealerships:server:direct-test-drive-give-keys", function(playerSource, sessionId)
  local session = sessionId and directTestDrives[sessionId]
  if not session or not session.vehicleNetId or session.sellerPlayerId ~= playerSource then
    return false
  end

  TriggerClientEvent("jg-dealerships:client:direct-test-drive-receive-keys", session.customerPlayerId, session.vehicleNetId, session.plate)
  TriggerClientEvent("jg-dealerships:client:direct-test-drive-receive-keys", playerSource, session.vehicleNetId, session.plate)
  return true
end)

lib.callback.register("jg-dealerships:server:cancel-direct-test-drive", function(playerSource, sessionId)
  local session = sessionId and directTestDrives[sessionId]
  if not session then
    return false
  end

  if not Employees.Server.IsEmployee(playerSource, session.dealershipId, "SELL") then
    return false
  end

  local plate = session.plate
  deleteDirectTestDriveVehicle(session)
  TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, plate)
  directTestDrives[sessionId] = nil
  return true, plate
end)

lib.callback.register("jg-dealerships:server:direct-test-drive-set-vehicle", function(playerSource, sessionId, vehicleNetId)
  local session = sessionId and directTestDrives[sessionId]
  if not session or session.sellerPlayerId ~= playerSource or not vehicleNetId or vehicleNetId == 0 then
    return false
  end

  local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
  if not vehicleEntity or vehicleEntity == 0 then
    return false
  end

  session.vehicleNetId = vehicleNetId
  session.vehicleEntity = vehicleEntity
  return true
end)

lib.callback.register("jg-dealerships:server:get-active-test-drives", function(playerSource, dealershipId)
  if not Employees.Server.IsEmployee(playerSource, dealershipId, "SELL") then
    return {}
  end

  local activeTestDrives = {}
  for _, session in pairs(directTestDrives) do
    if session.dealershipId == dealershipId then
      activeTestDrives[#activeTestDrives + 1] = {
        id = session.id,
        sellerPlayerId = session.sellerPlayerId,
        sellerName = session.sellerName,
        customerName = session.customerName,
        vehicleLabel = session.vehicleLabel,
        vehicleModel = session.vehicleModel,
        plate = session.plate,
        startTime = session.startTime,
        vehicleNetId = session.vehicleNetId,
      }
    end
  end

  return activeTestDrives
end)

lib.callback.register("jg-dealerships:server:end-test-drive-remote", function(playerSource, sessionId)
  local session = sessionId and directTestDrives[sessionId]
  if not session then
    return false
  end

  if not Employees.Server.IsEmployee(playerSource, session.dealershipId, "SELL") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return false
  end

  local plate = session.plate
  deleteDirectTestDriveVehicle(session)
  TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended-remote", session.sellerPlayerId, plate, playerSource == session.sellerPlayerId)
  TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended-remote", session.customerPlayerId, plate, false)
  directTestDrives[sessionId] = nil
  return true
end)

lib.callback.register("jg-dealerships:server:track-test-drive-vehicle", function(playerSource, sessionId)
  local session = sessionId and directTestDrives[sessionId]
  if not session then
    return false
  end

  if not Employees.Server.IsEmployee(playerSource, session.dealershipId, "SELL") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return false
  end

  if not session.vehicleNetId then
    return false
  end

  local vehicleEntity = NetworkGetEntityFromNetworkId(session.vehicleNetId)
  if not vehicleEntity or not DoesEntityExist(vehicleEntity) then
    return false
  end

  return true, GetEntityCoords(vehicleEntity)
end)

lib.callback.register("jg-dealerships:server:get-test-drive-vehicle-coords", function(_, sessionId)
  local session = sessionId and directTestDrives[sessionId]
  if not session or not session.vehicleNetId then
    return nil
  end

  local vehicleEntity = NetworkGetEntityFromNetworkId(session.vehicleNetId)
  if not vehicleEntity or not DoesEntityExist(vehicleEntity) then
    return nil
  end

  return GetEntityCoords(vehicleEntity)
end)

lib.callback.register("jg-dealerships:server:get-direct-test-drive-status", function(playerSource)
  for _, session in pairs(directTestDrives) do
    if session.sellerPlayerId == playerSource then
      return true, {
        id = session.id,
        dealershipId = session.dealershipId,
        customerPlayerId = session.customerPlayerId,
        vehicleNetId = session.vehicleNetId,
        vehicleModel = session.vehicleModel,
        plate = session.plate,
        coords = session.coords,
      }
    end
  end

  return false
end)

RegisterNetEvent("jg-dealerships:server:exit-bucket", function()
  local playerSource = source
  SetPlayerRoutingBucket(playerSource, 0)
  print(("Restart: emegency player %s breakout to bucket 0"):format(playerSource))
end)

AddEventHandler("playerDropped", function()
  local playerSource = source

  for sessionId, session in pairs(directTestDrives) do
    if session.sellerPlayerId == playerSource then
      deleteDirectTestDriveVehicle(session)

      if GetPlayerPing(tostring(session.customerPlayerId)) > 0 then
        TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, session.plate)
      end

      directTestDrives[sessionId] = nil
    end
  end
end)

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() ~= resourceName then
    return
  end

  for _, session in pairs(directTestDrives) do
    deleteDirectTestDriveVehicle(session)

    if GetPlayerPing(tostring(session.sellerPlayerId)) > 0 then
      TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.sellerPlayerId, session.plate)
    end

    if GetPlayerPing(tostring(session.customerPlayerId)) > 0 then
      TriggerClientEvent("jg-dealerships:client:direct-test-drive-ended", session.customerPlayerId, session.plate)
    end
  end

  directTestDrives = {}
end)

