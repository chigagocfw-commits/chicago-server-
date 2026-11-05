Spawn = Spawn or {}
Spawn.Client = Spawn.Client or {}

local function getVehicleType(model)
  local vehicleClass = GetVehicleClassFromName(model)

  if IsThisModelACar(model) then return "automobile" end
  if IsThisModelABicycle(model) or IsThisModelABike(model) then return "bike" end
  if IsThisModelABoat(model) then return "boat" end
  if IsThisModelAHeli(model) then return "heli" end
  if IsThisModelAPlane(model) then return "plane" end
  if IsThisModelAQuadbike(model) then return "automobile" end
  if IsThisModelATrain(model) then return "train" end
  if vehicleClass == 5 then return "automobile" end
  if vehicleClass == 14 then return "submarine" end
  if vehicleClass == 16 then return "heli" end

  return "trailer"
end

local function applyVehicleProps(vehicle, props)
  if type(props) == "table" then
    if props.colour then
      Utils.Client.SetVehicleColourNew(vehicle, props.colour)
    end

    if props.plate then
      SetVehicleNumberPlateText(vehicle, props.plate)
    end
  end

  Framework.Client.VehicleSetFuel(vehicle, 100.0)
  return not NetworkGetEntityIsNetworked(vehicle)
end

local function requestVehicleAndGetSpawnDetails(model, plate)
  local hash = ConvertModelToHash(model)
  local vehicleType = getVehicleType(hash)

  if not IsModelInCdimage(hash) then
    Framework.Client.Notify(Locale.vehicleModelDoesNotExist, "error")
    print(("^1Vehicle model %s does not exist"):format(model))
    return false
  end

  local hasSeats = GetVehicleModelNumberOfSeats(hash) > 0

  if plate and plate ~= "" and not IsValidGTAPlate(plate) then
    Framework.Client.Notify(Locale.vehiclePlateInvalid, "error")
    print(("^1This vehicle is trying to spawn with the plate '%s' which is invalid for a GTA vehicle plate"):format(plate:upper()))
    print("^1Vehicle plates must be 8 characters long maximum, and can contain ONLY numbers, letters and spaces")
    return false
  end

  lib.requestModel(hash, 60000)

  if IsPedRagdoll(cache.ped) then
    Framework.Client.Notify(Locale.currentlyInRagdollState, "error")
    SetModelAsNoLongerNeeded(hash)
    return false
  end

  return hash, vehicleType, hasSeats
end

local function finaliseVehicle(vehicle, vehicleId, modelHash, warpPlayer, plate, props, reason)
  if not vehicle or vehicle == 0 then
    Framework.Client.Notify(Locale.couldNotSpawnVehicle, "error")
    print("^1Vehicle does not exist (vehicle = 0)")
    return false
  end

  if IsPedRagdoll(cache.ped) then
    Framework.Client.Notify(Locale.currentlyInRagdollState, "error")
    SetModelAsNoLongerNeeded(modelHash)
    return false
  end

  if warpPlayer then
    ClearPedTasks(cache.ped)

    local ok = pcall(function()
      lib.waitFor(function()
        if GetPedInVehicleSeat(vehicle, -1) == cache.ped then
          return true
        end

        TaskWarpPedIntoVehicle(cache.ped, vehicle, -1)
      end, nil, 5000)
    end)

    if not ok then
      print("^1[ERROR] Could not warp you into the vehicle^0")
      return false
    end
  end

  if plate and plate ~= "" then
    SetVehicleNumberPlateText(vehicle, plate)
  end

  if type(props) == "table" then
    applyVehicleProps(vehicle, props)
  end

  if GetResourceState("brazzers-fakeplates") == "started" then
    local fakePlate = lib.callback.await("jg-dealerships:server:brazzers-get-fakeplate-from-plate", false, plate)
    if fakePlate then
      plate = fakePlate
      SetVehicleNumberPlateText(vehicle, fakePlate)
    end
  end

  if not plate or plate == "" then
    plate = Framework.Client.GetPlate(vehicle)
  end

  if not plate or plate == "" then
    print("^1[ERROR] The game thinks the vehicle has no plate - absolutely no idea how you've managed this")
    return false
  end

  Entity(vehicle).state:set("vehicleid", vehicleId, true)
  Framework.Client.VehicleGiveKeys(plate, vehicle, reason)
  return true
end

local function onServerVehicleCreated(netId, teleportCoords, warpPlayer, modelHash, vehicleId, plate, props, reason)
  SetModelAsNoLongerNeeded(modelHash)

  if not netId then
    Framework.Client.Notify(Locale.couldNotSpawnVehicle, "error")
    print("^1Server returned false for netId")
    return false
  end

  lib.waitFor(function()
    return NetworkDoesNetworkIdExist(netId)
      and NetworkDoesEntityExistWithNetworkId(netId)
      or nil
  end, "Timed out while waiting for a server-setter netId to exist on client", 10000)

  local vehicle = NetToVeh(netId)

  lib.waitFor(function()
    return DoesEntityExist(vehicle) or nil
  end, "Timed out while waiting for a server-setter vehicle to exist on client", 10000)

  if teleportCoords then
    SetEntityCoords(cache.ped, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, false)
  end

  if not finaliseVehicle(vehicle, vehicleId, modelHash, warpPlayer, plate, props, reason) then
    DeleteEntity(vehicle)
    return false
  end

  return true
end

local function createClientVehicle(modelHash, coords, plate, networked)
  lib.requestModel(modelHash, 60000)

  local vehicle = CreateVehicle(
    modelHash,
    coords.x, coords.y, coords.z,
    coords.w,
    networked or false,
    networked or false
  )

  lib.waitFor(function()
    return DoesEntityExist(vehicle) or nil
  end, "Timed out while trying to spawn in vehicle (client)", 10000)

  SetModelAsNoLongerNeeded(modelHash)

  if plate and plate ~= "" then
    SetVehicleNumberPlateText(vehicle, plate)
  end

  return vehicle
end

function Spawn.Client.Create(vehicleId, model, plate, coords, warpPlayer, props, reason)
  if Config.SpawnVehiclesWithServerSetter then
    print("^1This function is disabled as client spawning is enabled")
    return false
  end

  local modelHash, _, hasSeats = requestVehicleAndGetSpawnDetails(model, plate)
  if not modelHash then return false end

  local vehicle = createClientVehicle(modelHash, coords, plate, true)
  if not vehicle then return false end

  if not finaliseVehicle(vehicle, vehicleId, modelHash, hasSeats and warpPlayer, plate, props, reason) then
    DeleteEntity(vehicle)
    return false
  end

  return vehicle
end

AddStateBagChangeHandler("vehInit", "", function(bagName, _, value)
  if not value then return end

  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle == 0 then return end

  lib.waitFor(function()
    return not IsEntityWaitingForWorldCollision(vehicle)
  end)

  if NetworkGetEntityOwner(vehicle) ~= cache.playerId then return end

  local state = Entity(vehicle).state
  SetVehicleOnGroundProperly(vehicle)

  SetTimeout(0, function()
    state:set("vehInit", nil, true)
  end)
end)

AddStateBagChangeHandler("dealershipVehCreatedApplyProps", "", function(bagName, _, value)
  if not value then return end

  local vehicle = GetEntityFromStateBagName(bagName)
  if vehicle == 0 then return end

  SetTimeout(0, function()
    local state = Entity(vehicle).state

    for _ = 1, 10 do
      if NetworkGetEntityOwner(vehicle) == cache.playerId and applyVehicleProps(vehicle, value) then
        state:set("dealershipVehCreatedApplyProps", nil, true)
        break
      end

      Wait(100)
    end
  end)
end)

lib.callback.register("jg-dealerships:client:req-vehicle-and-get-spawn-details", requestVehicleAndGetSpawnDetails)
lib.callback.register("jg-dealerships:client:on-server-vehicle-created", onServerVehicleCreated)
