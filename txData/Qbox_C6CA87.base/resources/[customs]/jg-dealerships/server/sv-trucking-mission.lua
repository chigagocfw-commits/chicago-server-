TruckingMission = TruckingMission or {}
TruckingMission.Server = TruckingMission.Server or {}

local activeMissions = {}
local occupiedPickupLocations = {}
local pendingConfigs = {}
local hashSeed = tostring(os.time()) .. tostring(math.random(100000, 999999))
local entityResolveTimeout = 5000
local entityRegisterTimeout = 10000

local function getInTransitQuantity(orderId)
  local inTransitQuantity = 0

  for _, mission in pairs(activeMissions) do
    if mission and mission.active and mission.orders then
      for _, order in ipairs(mission.orders) do
        if order.orderId == orderId then
          inTransitQuantity = inTransitQuantity + order.quantityToDeliver
        end
      end
    end
  end

  return inTransitQuantity
end

local function normalizeModel(model)
  if not model then
    return nil
  end

  return type(model) == "string" and joaat(model) or model
end

local function resolveEntityFromNetId(netId, timeout)
  if not netId or netId == 0 then
    return nil
  end

  local entity = NetworkGetEntityFromNetworkId(netId)
  if entity and entity ~= 0 and DoesEntityExist(entity) then
    return entity
  end

  local success = pcall(function()
    lib.waitFor(function()
      entity = NetworkGetEntityFromNetworkId(netId)
      return entity and entity ~= 0 and DoesEntityExist(entity)
    end, nil, timeout or entityResolveTimeout)
  end)

  if success and entity and entity ~= 0 and DoesEntityExist(entity) then
    return entity
  end

  return nil
end

local function isExpectedTruck(entity)
  if not entity or entity == 0 or not DoesEntityExist(entity) then
    return false
  end

  local expectedModel = normalizeModel(TruckingConfig.TruckModel)
  return expectedModel and GetEntityModel(entity) == expectedModel
end

function TruckingMission.Server.GetOrderSizeCategory(orderId)
  return MySQL.scalar.await("SELECT size_category FROM dealership_orders WHERE id = ?", { orderId }) or "medium"
end

local function createConfigHash(orderIds, trailerType)
  table.sort(orderIds)

  local source = hashSeed .. trailerType
  for _, orderId in ipairs(orderIds) do
    source = source .. tostring(orderId)
  end

  return GetHashKey(source) .. ""
end

local function verifyConfigHash(orderIds, trailerType, configHash)
  return createConfigHash(orderIds, trailerType) == configHash
end

local function getAvailablePickupStop()
  local availableIndexes = {}

  for index = 1, #TruckingConfig.PickupLocations do
    if not occupiedPickupLocations[index] then
      availableIndexes[#availableIndexes + 1] = index
    end
  end

  if #availableIndexes == 0 then
    return nil, nil
  end

  local index = availableIndexes[math.random(#availableIndexes)]
  return {
    index = index,
    location = TruckingConfig.PickupLocations[index],
    vehicles = {},
  }, index
end

local function addPickupContents(pickupStop, orders)
  for _, order in ipairs(orders) do
    for _ = 1, order.quantityToDeliver do
      pickupStop.vehicles[#pickupStop.vehicles + 1] = {
        orderId = order.orderId,
        model = order.model,
        size = order.size,
        quantity = 1,
      }
    end
  end

  return pickupStop
end

local function estimateRoute(dropoffCoords, pickupStop)
  local dropoff = vector3(dropoffCoords.x, dropoffCoords.y, dropoffCoords.z)
  local pickup = vector3(
    pickupStop.location.coords.x,
    pickupStop.location.coords.y,
    pickupStop.location.coords.z
  )
  local totalDistance = #(dropoff - pickup) * 2 * 1.4
  local estimatedTime = math.ceil((totalDistance / 13.9) * 1.3)
  return math.floor(totalDistance), estimatedTime
end

local function canStartMission(playerId, dealershipId)
  if not playerId then
    return false, "Invalid player ID"
  end

  if activeMissions[playerId] then
    return false, "You already have an active mission"
  end

  if not Employees.Server.IsEmployee(playerId, dealershipId, "DELIVER") then
    return false, "You must have delivery permissions to start deliveries"
  end

  return true
end

local function validateOrders(orderIds, dealershipId, requestedQuantities)
  if #orderIds == 0 then
    return false, "No orders selected", nil
  end

  local orders = {}

  for _, orderId in ipairs(orderIds) do
    local order = MySQL.single.await(
      "SELECT * FROM dealership_orders WHERE id = ? AND dealership = ? AND fulfilled = 0",
      { orderId, dealershipId }
    )
    if not order then
      return false, "Order " .. orderId .. " not found or already fulfilled", nil
    end

    local remainingQuantity = order.quantity - (order.delivered or 0)
    local requestedQuantity = requestedQuantities[orderId] or requestedQuantities[tostring(orderId)] or remainingQuantity
    local alreadyInTransit = getInTransitQuantity(orderId)
    local availableQuantity = remainingQuantity - alreadyInTransit

    if availableQuantity <= 0 then
      return false, "All remaining vehicles for order " .. orderId .. " are already being delivered", nil
    end

    if requestedQuantity > availableQuantity then
      return false,
        string.format(
          "Order %d: only %d vehicle(s) available to deliver (%d remaining, %d already in transit)",
          orderId,
          availableQuantity,
          remainingQuantity,
          alreadyInTransit
        ),
        nil
    end

    if requestedQuantity <= 0 then
      return false, "Invalid quantity for order " .. orderId, nil
    end

    orders[#orders + 1] = {
      orderId = orderId,
      model = order.vehicle,
      quantityToDeliver = requestedQuantity,
      totalQuantity = order.quantity,
      delivered = order.delivered or 0,
      size = order.size_category or "medium",
    }
  end

  return true, nil, orders
end

function TruckingMission.Server.GenerateDeliveryConfiguration(playerId, dealershipId, trailerType, orderIds, requestedQuantities)
  local allowed, errorMessage = canStartMission(playerId, dealershipId)
  if not allowed then
    return false, errorMessage, nil
  end

  local ordersValid, orderError, orders = validateOrders(orderIds, dealershipId, requestedQuantities)
  if not ordersValid or not orders then
    return false, orderError, nil
  end

  for _, order in ipairs(orders) do
    if trailerType == "car" and order.size == "large" then
      return false, "Large vehicles require a container trailer", nil
    end

    if trailerType == "container" and order.size ~= "large" then
      return false, "Container trailer is only for large vehicles", nil
    end
  end

  if trailerType == "container" then
    local totalVehicles = 0
    for _, order in ipairs(orders) do
      totalVehicles = totalVehicles + order.quantityToDeliver
    end

    if totalVehicles > 1 then
      return false, "Container trailer can only carry 1 large vehicle", nil
    end
  elseif trailerType == "car" then
    local usedSlots = 0
    for _, order in ipairs(orders) do
      local slotCost = order.size == "medium" and 1.5 or 1
      usedSlots = usedSlots + (order.quantityToDeliver * slotCost)
    end

    if usedSlots > 6 then
      print("car trailer capacity exceeded")
      return false,
        string.format(
          "Car trailer capacity exceeded! Selected %.1f slots but maximum is %d slots. Small vehicles use 1 slot, medium vehicles use 1.5 slots.",
          usedSlots,
          6
        ),
        nil
    end
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership or not dealership.trucking_vehicle_coords then
    return false, "[Configuration error] No trucking vehicle coordinates set", nil
  end

  local totalVehicles = 0
  for _, order in ipairs(orders) do
    totalVehicles = totalVehicles + order.quantityToDeliver
  end

  local pickupStop, occupiedIndex = getAvailablePickupStop()
  if not pickupStop or not occupiedIndex then
    return false, "No pickup locations available at this time", nil
  end

  pickupStop = addPickupContents(pickupStop, orders)
  local totalDistance, estimatedTime = estimateRoute(dealership.trucking_vehicle_coords[1], pickupStop)
  local configHash = createConfigHash(orderIds, trailerType)
  local config = {
    trailerType = trailerType,
    pickupStop = pickupStop,
    occupiedIndex = occupiedIndex,
    totalVehicles = totalVehicles,
    maxCapacity = trailerType == "container" and 1 or 6,
    totalDistance = totalDistance,
    estimatedTime = estimatedTime,
    configHash = configHash,
    orders = orders,
  }

  pendingConfigs[playerId] = config

  for pendingPlayerId, pendingConfig in pairs(pendingConfigs) do
    if pendingConfig.timestamp and os.time() - pendingConfig.timestamp > 300 then
      pendingConfigs[pendingPlayerId] = nil
    end
  end

  config.timestamp = os.time()
  return true, nil, config
end

function TruckingMission.Server.PrepareDelivery(playerId, orderId, dealershipId)
  local order = MySQL.single.await(
    "SELECT * FROM dealership_orders WHERE id = ? AND dealership = ? AND fulfilled = 0",
    { orderId, dealershipId }
  )
  if not order then
    return false, Locale.orderNotFoundOrFulfilled, nil
  end

  local quantityToDeliver = order.quantity - (order.delivered or 0)
  local trailerType = order.size_category == "large" and "container" or "car"
  local success, errorMessage, config = TruckingMission.Server.GenerateDeliveryConfiguration(
    playerId,
    dealershipId,
    trailerType,
    { orderId },
    { [orderId] = quantityToDeliver }
  )

  if not success or not config then
    return false, errorMessage, nil
  end

  return true, nil, config.pickupStop.location
end

local function setTruck(playerId, truckNetId)
  local mission = activeMissions[playerId]
  if not mission or not truckNetId or truckNetId == 0 then
    return false
  end

  local truck = resolveEntityFromNetId(truckNetId, entityRegisterTimeout)
  if not truck then
    DebugPrint("Failed to register truck network ID for playerId: " .. playerId .. ", netId: " .. tostring(truckNetId), "warning")
    return false
  end

  if not isExpectedTruck(truck) then
    DebugPrint("Rejected unexpected truck model for playerId: " .. playerId .. ", netId: " .. tostring(truckNetId), "warning")
    return false
  end

  mission.truck = truck
  mission.truckNetId = truckNetId
  return true
end

local function setCargo(playerId, cargoNetId)
  local mission = activeMissions[playerId]
  if not mission or not cargoNetId or cargoNetId == 0 then
    return false
  end

  local cargo = resolveEntityFromNetId(cargoNetId, entityRegisterTimeout)
  if not cargo then
    DebugPrint("Failed to register cargo network ID for playerId: " .. playerId .. ", netId: " .. tostring(cargoNetId), "warning")
    return false
  end

  mission.cargo = cargo
  mission.cargoNetId = cargoNetId
  return true
end

local function updateStage(playerId, stage)
  local mission = activeMissions[playerId]
  if not mission then
    return false
  end

  DebugPrint("Updating stage for playerId: " .. playerId .. ", from: " .. tostring(mission.stage) .. ", to: " .. tostring(stage), "debug")
  mission.stage = stage
  return true
end

local function cleanupMissionEntities(mission)
  local truck = mission.truck
  if not truck or not DoesEntityExist(truck) then
    truck = mission.truckNetId and NetworkGetEntityFromNetworkId(mission.truckNetId) or nil
  end

  if truck and DoesEntityExist(truck) then
    DeleteEntity(truck)
  end

  local cargo = mission.cargo
  if not cargo or not DoesEntityExist(cargo) then
    cargo = mission.cargoNetId and NetworkGetEntityFromNetworkId(mission.cargoNetId) or nil
  end

  if cargo and DoesEntityExist(cargo) then
    DeleteEntity(cargo)
  end
end

local function releasePickupStop(mission)
  if mission.pickupStop and mission.pickupStop.index then
    occupiedPickupLocations[mission.pickupStop.index] = nil
  end
end

local function resolveMissionEntity(entity, netId)
  if entity and DoesEntityExist(entity) then
    if not netId or netId == 0 then
      return entity
    end

    local resolvedNetId = NetworkGetNetworkIdFromEntity(entity)
    if resolvedNetId and resolvedNetId == netId then
      return entity
    end
  end

  return resolveEntityFromNetId(netId)
end

local function completeMission(playerId, cargoNetId)
  local mission = activeMissions[playerId]
  DebugPrint("Trying to find mission for playerId: " .. playerId, "debug", "Mission data:", tostring(mission or "nil"))

  if not mission then
    DebugPrint("Mission not found for playerId: " .. playerId, "warning")
    return false
  end

  local playerPed = GetPlayerPed(playerId)
  DebugPrint("Checking player ped for playerId: " .. playerId, "debug", "Player ped:", tostring(playerPed or "nil"))

  if not playerPed or playerPed == 0 then
    DebugPrint("Player ped not found for playerId: " .. playerId, "warning")
    cleanupMissionEntities(mission)
    releasePickupStop(mission)
    activeMissions[playerId] = nil
    return false
  end

  if mission.stage ~= "at_dropoff" then
    DebugPrint("Invalid mission stage for playerId: " .. playerId .. ", expected: at_dropoff, received: " .. tostring(mission.stage), "warning")
    return false
  end

  local playerCoords = GetEntityCoords(playerPed)
  if not playerCoords or not mission.dropoffCoords then
    DebugPrint("Invalid player or dropoff coordinates for playerId: " .. playerId, "warning")
    return false
  end

  local distanceToDropoff = #(vector3(playerCoords.x, playerCoords.y, playerCoords.z) - vector3(
    mission.dropoffCoords.x,
    mission.dropoffCoords.y,
    mission.dropoffCoords.z
  ))
  if distanceToDropoff > 25.0 then
    DebugPrint("Player too far from dropoff for playerId: " .. playerId .. ", distance is: " .. distanceToDropoff .. " > 25.0", "warning")
    return false
  end

  local playerVehicle = GetVehiclePedIsIn(playerPed, false)
  local truck = resolveMissionEntity(mission.truck, mission.truckNetId)
  if not truck then
    if isExpectedTruck(playerVehicle) then
      truck = playerVehicle
      mission.truck = truck
      local truckNetId = NetworkGetNetworkIdFromEntity(truck)
      if truckNetId and truckNetId ~= 0 then
        mission.truckNetId = truckNetId
      end
      DebugPrint("Recovered truck from player vehicle for playerId: " .. playerId .. ", netId: " .. tostring(mission.truckNetId), "debug")
    else
      DebugPrint("Failed to resolve truck for playerId: " .. playerId .. ", netId: " .. tostring(mission.truckNetId), "warning")
      return false
    end
  end

  mission.truck = truck
  if playerVehicle ~= truck then
    DebugPrint("Player not in expected truck for playerId: " .. playerId .. ", expected: " .. tostring(truck) .. ", received: " .. tostring(playerVehicle), "warning")
    return false
  end

  local cargo = resolveMissionEntity(mission.cargo, mission.cargoNetId)
  if not cargo then
    DebugPrint("Failed to resolve cargo for playerId: " .. playerId, "warning")
    return false
  end

  mission.cargo = cargo
  local actualCargoNetId = NetworkGetNetworkIdFromEntity(cargo)
  if not actualCargoNetId or actualCargoNetId ~= cargoNetId then
    DebugPrint(
      "Cargo network ID mismatch for playerId: " .. playerId .. ", expected: " .. tostring(actualCargoNetId) .. ", received: " .. tostring(cargoNetId),
      "warning"
    )
    return false
  end

  if #(GetEntityCoords(truck) - GetEntityCoords(cargo)) > 20.0 then
    DebugPrint("Cargo too far from truck for playerId: " .. playerId .. ", distance is: " .. #(GetEntityCoords(truck) - GetEntityCoords(cargo)) .. " > 20.0", "warning")
    return false
  end

  releasePickupStop(mission)
  cleanupMissionEntities(mission)

  local deliveredBy = Framework.Server.GetPlayerIdentifier(playerId)
  local pickupLocationName = mission.pickupStop and mission.pickupStop.location.name or "Unknown"

  for _, order in ipairs(mission.orders) do
    local delivered = (MySQL.scalar.await("SELECT delivered FROM dealership_orders WHERE id = ?", { order.orderId }) or 0)
      + order.quantityToDeliver
    local quantityRow = MySQL.single.await("SELECT quantity FROM dealership_orders WHERE id = ?", { order.orderId })
    local fulfilled = quantityRow and delivered >= quantityRow.quantity

    MySQL.update.await(
      "UPDATE dealership_orders SET delivered = ?, fulfilled = ?, delivered_by = ?, delivered_at = NOW(), delivery_pickup_location = ? WHERE id = ?",
      { delivered, fulfilled and 1 or 0, deliveredBy, pickupLocationName, order.orderId }
    )

    local stock = MySQL.scalar.await(
      "SELECT stock FROM dealership_stock WHERE vehicle = ? AND dealership = ?",
      { order.model, mission.dealershipId }
    )
    if stock then
      MySQL.update.await(
        "UPDATE dealership_stock SET stock = stock + ? WHERE vehicle = ? AND dealership = ?",
        { order.quantityToDeliver, order.model, mission.dealershipId }
      )
    else
      MySQL.insert.await(
        "INSERT INTO dealership_stock (vehicle, dealership, stock, price) SELECT ?, ?, ?, price FROM dealership_vehicles WHERE spawn_code = ?",
        { order.model, mission.dealershipId, order.quantityToDeliver, order.model }
      )
    end

    Showroom.Server.UpdateVehicleCache(order.model, mission.dealershipId)
  end

  activeMissions[playerId] = nil
  return true
end

local function cancelMission(playerId)
  local mission = activeMissions[playerId]
  if not mission then
    return false
  end

  cleanupMissionEntities(mission)
  releasePickupStop(mission)
  activeMissions[playerId] = nil
  return true
end

local function validateMission(playerId)
  local mission = activeMissions[playerId]
  if not mission then
    return false, "No active mission found", nil
  end

  local dealership = Locations.Server.GetById(mission.dealershipId)
  if not dealership or not dealership.trucking_vehicle_coords then
    return false, "[Configuration error] No trucking vehicle coordinates set", nil
  end

  return true, nil, {
    pickupStop = mission.pickupStop,
    dropoffCoords = mission.dropoffCoords,
    truckSpawn = dealership.trucking_vehicle_coords[1],
    spawnOnClient = not Config.SpawnVehiclesWithServerSetter,
    trailerType = mission.trailerType,
    orders = mission.orders,
  }
end

local function spawnCargo(playerId)
  local mission = activeMissions[playerId]
  if not mission then
    return false, nil, nil
  end

  if mission.stage ~= "driving_to_pickup" and mission.stage ~= "spawned" then
    return false, nil, nil
  end

  if mission.cargo or not mission.pickupStop then
    return false, nil, nil
  end

  local cargoCoords = mission.pickupStop.location.coords
  local cargoModel
  if mission.trailerType == "container" then
    cargoModel = TruckingConfig.TrailerLargeVehicle
  else
    cargoModel = TruckingConfig.TrailerSmallVehicle == "DYNAMIC_TR2" and "tr2" or TruckingConfig.TrailerSmallVehicle
  end

  local cargoNetId
  if Config.SpawnVehiclesWithServerSetter then
    local cargoProperties = TruckingConfig.CargoProperties or {}
    cargoNetId, mission.cargo = Spawn.Server.Create(
      playerId,
      0,
      cargoModel,
      false,
      cargoCoords,
      false,
      cargoProperties,
      "truckingMission"
    )

    if not cargoNetId or not mission.cargo then
      return false, nil, nil
    end

    mission.cargoNetId = cargoNetId
    Wait(100)
    SetVehicleOnGroundProperly(mission.cargo)
  end

  return true, cargoNetId, not Config.SpawnVehiclesWithServerSetter
end

local function unfreezeCargo(playerId)
  local mission = activeMissions[playerId]
  if not mission or not mission.cargo then
    return false
  end

  if DoesEntityExist(mission.cargo) then
    FreezeEntityPosition(mission.cargo, false)
    return true
  end

  return false
end

local function getMission(playerId)
  return activeMissions[playerId]
end

function TruckingMission.Server.HasActiveDelivery()
  for _, mission in pairs(activeMissions) do
    if mission and mission.active then
      return true
    end
  end

  return false
end

function TruckingMission.Server.IsOrderBeingDelivered(orderId)
  local quantity = getInTransitQuantity(orderId)
  return quantity > 0, quantity
end

function TruckingMission.Server.GetActiveDeliveryInfo(orderId)
  local deliveries = {}

  for _, mission in pairs(activeMissions) do
    if mission and mission.active and mission.orders then
      for _, order in ipairs(mission.orders) do
        if order.orderId == orderId then
          deliveries[#deliveries + 1] = {
            startedAt = mission.startedAt,
            startedByName = mission.startedByName,
            pickupLocation = mission.pickupStop and mission.pickupStop.location.name or "Unknown",
            quantityBeingDelivered = order.quantityToDeliver,
          }
        end
      end
    end
  end

  if #deliveries == 0 then
    return nil
  end

  table.sort(deliveries, function(left, right)
    return (left.startedAt or 0) < (right.startedAt or 0)
  end)

  local deliveryNames = {}
  for _, delivery in ipairs(deliveries) do
    if delivery.startedByName then
      deliveryNames[#deliveryNames + 1] = delivery.startedByName .. " (" .. delivery.quantityBeingDelivered .. ")"
    end
  end

  return {
    startedAt = deliveries[1].startedAt,
    startedByName = table.concat(deliveryNames, ", "),
    pickupLocation = deliveries[1].pickupLocation,
    activeDeliveries = deliveries,
  }
end

function TruckingMission.Server.StartMultiDelivery(playerId, dealershipId, configHash)
  local config = pendingConfigs[playerId]
  if not config then
    Framework.Server.Notify(playerId, Locale.deliveryNotPrepared, "error")
    return false
  end

  if config.configHash ~= configHash then
    Framework.Server.Notify(playerId, Locale.deliveryConfigMismatch, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  if config.timestamp and os.time() - config.timestamp > 300 then
    Framework.Server.Notify(playerId, Locale.deliveryPreparationExpired, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  local orderIds = {}
  local quantities = {}
  for _, order in ipairs(config.orders) do
    orderIds[#orderIds + 1] = order.orderId
    quantities[order.orderId] = order.quantityToDeliver
  end

  local ordersValid, orderError = validateOrders(orderIds, dealershipId, quantities)
  if not ordersValid then
    Framework.Server.Notify(playerId, orderError or Locale.orderNotFoundOrFulfilled, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  local canStart, missionError = canStartMission(playerId, dealershipId)
  if not canStart then
    Framework.Server.Notify(playerId, missionError or Locale.failedToPrepareDelivery, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership or not dealership.trucking_vehicle_coords then
    Framework.Server.Notify(playerId, Locale.noTruckingVehicleCoordinates, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  if occupiedPickupLocations[config.occupiedIndex] then
    Framework.Server.Notify(playerId, Locale.pickupLocationUnavailable, "error")
    pendingConfigs[playerId] = nil
    return false
  end

  occupiedPickupLocations[config.occupiedIndex] = true

  local playerInfo = Framework.Server.GetPlayerInfo(playerId)
  local mission = {
    active = true,
    playerId = playerId,
    dealershipId = dealershipId,
    trailerType = config.trailerType,
    truck = nil,
    truckNetId = nil,
    cargo = nil,
    cargoNetId = nil,
    attachedVehicles = {},
    pickupStop = config.pickupStop,
    dropoffCoords = dealership.trucking_vehicle_coords[1],
    stage = "spawned",
    startedAt = os.time(),
    startedByName = playerInfo and playerInfo.name or "Unknown",
    configHash = configHash,
    orders = config.orders,
  }

  pendingConfigs[playerId] = nil
  activeMissions[playerId] = mission

  local truckNetId
  local truckEntity
  if Config.SpawnVehiclesWithServerSetter then
    local truckProperties = TruckingConfig.TruckProperties or {}
    truckNetId, truckEntity = Spawn.Server.Create(
      playerId,
      0,
      TruckingConfig.TruckModel,
      false,
      dealership.trucking_vehicle_coords[1],
      false,
      truckProperties,
      "truckingMission"
    )

    if not truckNetId or not truckEntity then
      releasePickupStop(mission)
      activeMissions[playerId] = nil
      Framework.Server.Notify(playerId, Locale.failedToSpawnTruck, "error")
      return false
    end

    mission.truck = truckEntity
    mission.truckNetId = truckNetId
  end

  local started, errorMessage = lib.callback.await("jg-dealerships:client:trucking:start-mission", playerId, truckNetId)
  if not started then
    if truckEntity and DoesEntityExist(truckEntity) then
      DeleteEntity(truckEntity)
    end

    releasePickupStop(mission)
    activeMissions[playerId] = nil
    Framework.Server.Notify(playerId, errorMessage or Locale.clientFailedToStartMission, "error")
    return false
  end

  return true
end

lib.callback.register("jg-dealerships:server:trucking:validate-mission", validateMission)
lib.callback.register("jg-dealerships:server:trucking:set-truck", setTruck)
lib.callback.register("jg-dealerships:server:trucking:spawn-cargo", spawnCargo)
lib.callback.register("jg-dealerships:server:trucking:set-cargo", setCargo)
lib.callback.register("jg-dealerships:server:trucking:update-stage", updateStage)
lib.callback.register("jg-dealerships:server:trucking:unfreeze-cargo", unfreezeCargo)
lib.callback.register("jg-dealerships:server:trucking:complete", completeMission)
lib.callback.register("jg-dealerships:server:trucking:cancel", cancelMission)
lib.callback.register("jg-dealerships:server:trucking:get-mission", getMission)

AddEventHandler("playerDropped", function()
  local playerId = source

  if activeMissions[playerId] then
    cancelMission(playerId)
  end

  if pendingConfigs[playerId] then
    pendingConfigs[playerId] = nil
  end
end)
