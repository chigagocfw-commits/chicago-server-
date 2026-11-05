TestDrive = TestDrive or {}
TestDrive.Client = TestDrive.Client or {}

local inTestDrive = false
local currentDealership
local testDriveVehicle

function TestDrive.Client.IsInTestDrive()
  return inTestDrive
end

local function finishTestDrive()
  if not inTestDrive or not testDriveVehicle or not currentDealership then
    return false
  end

  inTestDrive = false
  DoScreenFadeOut(500)
  Wait(500)

  local plate = Framework.Client.GetPlate(testDriveVehicle)
  if plate then
    Framework.Client.VehicleRemoveKeys(plate, testDriveVehicle, "testDrive")
  end

  local testDriveData = lib.callback.await("jg-dealerships:server:finish-test-drive", false)
  Showroom.Client.Open(currentDealership.id, testDriveData.vehicleModel, testDriveData.vehicleColour)

  currentDealership = nil
  testDriveVehicle = nil
end

local function startRestrictionThread()
  CreateThread(function()
    while inTestDrive do
      if not cache.vehicle then
        finishTestDrive()
      end

      SetPlayerCanDoDriveBy(cache.ped, false)
      DisablePlayerFiring(cache.ped, true)
      DisableControlAction(0, 140, true)
      Wait(0)
    end
  end)
end

local function startTestDrive(dealershipId, vehicleModel, vehicleColour)
  currentDealership = Locations.Client.GetLocationById(dealershipId)
  if not currentDealership then return false end
  if not currentDealership.enable_test_drive or not currentDealership.test_drive_coords then return false end

  local spawnCoords = Utils.Client.ConvertSpawnCoordsToVec4(currentDealership.test_drive_coords)
  if not spawnCoords or #spawnCoords == 0 then return false end

  local returnCoords = GetEntityCoords(cache.ped)
  local vehicleLabel = Framework.Client.GetVehicleLabel(vehicleModel)
  local plate = lib.callback.await(
    "jg-dealerships:server:vehicle-generate-plate",
    false,
    Config.TestDrivePlate,
    false
  )

  local coords = Utils.Client.FindAvailableSpawnCoords(spawnCoords)
  Showroom.Client.Exit()

  local vehicle
  local netId

  if not Config.SpawnVehiclesWithServerSetter then
    local properties = {
      plate = plate,
      colour = vehicleColour,
    }

    vehicle = Spawn.Client.Create(0, vehicleModel, plate, coords, true, properties, "testDrive")
    if not vehicle then return false end

    netId = VehToNet(vehicle)
  end

  local success
  success, netId = lib.callback.await(
    "jg-dealerships:server:start-test-drive",
    false,
    dealershipId,
    coords,
    netId,
    vehicleModel,
    vehicleLabel,
    plate,
    vehicleColour,
    returnCoords
  )

  vehicle = netId and NetToVeh(netId) or false

  if not success then
    if vehicle then
      JGDeleteVehicle(vehicle)
    end

    return false
  end

  if Config.SpawnVehiclesWithServerSetter and not vehicle then
    print("^1[ERROR] There was a problem spawning in your vehicle")
    return false
  end

  testDriveVehicle = vehicle
  inTestDrive = true

  SetNuiFocus(false, false)
  SendNUIMessage({
    type = "testDriveHud",
    time = Config.TestDriveTimeSeconds or 60,
    locale = Locale,
    config = Config,
  })

  TriggerEvent(
    "jg-dealerships:client:start-test-drive:config",
    vehicle,
    Framework.Client.GetPlate(vehicle)
  )

  DoScreenFadeIn(500)

  CreateThread(function()
    Wait(2500)
    startRestrictionThread()
  end)

  return true
end

RegisterNUICallback("finish-test-drive", function(_, callback)
  finishTestDrive()
  callback(true)
end)

RegisterNUICallback("start-test-drive", function(data, callback)
  inTestDrive = true
  DoScreenFadeOut(500)
  Wait(500)

  if not startTestDrive(data.dealershipId, data.vehicle, data.color) then
    inTestDrive = false
    DoScreenFadeIn(0)
    return callback({ error = true })
  end

  callback(true)
end)

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() ~= resourceName or not inTestDrive then return end

  TriggerServerEvent("jg-dealerships:server:exit-bucket")

  if cache.vehicle then
    DeleteEntity(cache.vehicle)
  end
end)
