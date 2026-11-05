Spawn = Spawn or {}
Spawn.Server = Spawn.Server or {}

local spawnAttemptsByPlayer = {}
local maxSpawnDistance = 10.0
local maxSpawnAttempts = 3

local function createVehicleWithServerSetter(playerSource, model, vehicleType, plate, coords, warpIntoVehicle, vehicleProps)
  if spawnAttemptsByPlayer[playerSource] == maxSpawnAttempts then
    print("^3[WARNING] Vehicle props failed to set after trying several times. First check if the plate within the vehicle props JSON does not match the plate column. If they match, and you see this message regularly, try setting Config.SpawnVehiclesWithServerSetter = false")
    spawnAttemptsByPlayer[playerSource] = 0
    return false
  end

  spawnAttemptsByPlayer[playerSource] = (spawnAttemptsByPlayer[playerSource] or 0) + 1

  local vehicle = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z, coords.w)

  lib.waitFor(function()
    return DoesEntityExist(vehicle) or nil
  end, "Timed out while trying to spawn in vehicle (server)", 10000)

  lib.waitFor(function()
    local currentPlate = GetVehicleNumberPlateText(vehicle)
    return currentPlate ~= "" or currentPlate
  end, "Vehicle number plate text is nil", 5000)

  SetEntityRoutingBucket(vehicle, GetPlayerRoutingBucket(playerSource))

  if SetEntityOrphanMode then
    SetEntityOrphanMode(vehicle, 2)
  end

  for seat = -1, 6 do
    local ped = GetPedInVehicleSeat(vehicle, seat)
    if ped ~= 0 then
      DeleteEntity(ped)
    end
  end

  if warpIntoVehicle then
    local playerPed = GetPlayerPed(playerSource)

    pcall(function()
      lib.waitFor(function()
        if GetPedInVehicleSeat(vehicle, -1) == playerPed then
          return true
        end

        SetPedIntoVehicle(playerPed, vehicle, -1)
      end, nil, 1000)
    end)
  end

  lib.waitFor(function()
    local owner = NetworkGetEntityOwner(vehicle)
    return owner ~= -1 or owner
  end, "Timed out waiting for server-setter entity to have an owner (owner is -1)", 5000)

  Entity(vehicle).state:set("vehInit", true, true)

  if type(vehicleProps) == "table" then
    Entity(vehicle).state:set("dealershipVehCreatedApplyProps", vehicleProps, true)
  end

  local propsApplied = pcall(function()
    lib.waitFor(function()
      if Entity(vehicle).state.dealershipVehCreatedApplyProps then
        return
      end

      if not plate or plate == "" or Framework.Server.GetPlate(vehicle) == plate then
        return true
      end
    end, nil, 2000)
  end)

  if not propsApplied then
    DeleteEntity(vehicle)
    JGDeleteVehicle(vehicle)
    return createVehicleWithServerSetter(playerSource, model, vehicleType, plate, coords, warpIntoVehicle, vehicleProps)
  end

  spawnAttemptsByPlayer[playerSource] = 0
  return NetworkGetNetworkIdFromEntity(vehicle), vehicle
end

function Spawn.Server.Create(playerSource, vehicleName, vehicleModel, plate, coords, warpIntoVehicle, vehicleProps, keepEngineOn)
  local model, vehicleType, shouldWarpIntoVehicle = lib.callback.await(
    "jg-dealerships:client:req-vehicle-and-get-spawn-details",
    playerSource,
    vehicleModel
  )

  if not model then
    return false
  end

  local playerPed = GetPlayerPed(playerSource)
  local originalPlayerCoords = GetEntityCoords(playerPed)
  local movedPlayer = false

  if #(originalPlayerCoords - coords.xyz) > maxSpawnDistance then
    SetEntityCoords(playerPed, coords.x + 3.0, coords.y + 3.0, coords.z, false, false, false, false)
    movedPlayer = true
  end

  local networkId, vehicle = createVehicleWithServerSetter(
    playerSource,
    model,
    vehicleType,
    plate,
    coords,
    shouldWarpIntoVehicle and warpIntoVehicle or false,
    vehicleProps
  )

  if not vehicle or not networkId then
    return false
  end

  local created = lib.callback.await(
    "jg-dealerships:client:on-server-vehicle-created",
    playerSource,
    networkId,
    movedPlayer and originalPlayerCoords or false,
    shouldWarpIntoVehicle and warpIntoVehicle or false,
    model,
    vehicleName,
    plate,
    vehicleProps,
    keepEngineOn
  )

  if not created then
    if DoesEntityExist(vehicle) then
      DeleteEntity(vehicle)
      DebugPrint("Failed to create vehicle, deleted entity.", "warning", networkId)
    end

    return false
  end

  return networkId, vehicle
end

