DirectSales = DirectSales or {}
DirectSales.Client = DirectSales.Client or {}

local currentDealershipId
local saleVehicleBlip
local testDriveVehicleBlip
local activeTestDriveSessionId
local trackedTestDriveSessionId
local trackingActive = false

local function removeSaleVehicleBlip()
  if saleVehicleBlip and DoesBlipExist(saleVehicleBlip) then
    RemoveBlip(saleVehicleBlip)
  end

  saleVehicleBlip = nil
end

local function removeTestDriveVehicleBlip()
  if testDriveVehicleBlip and DoesBlipExist(testDriveVehicleBlip) then
    RemoveBlip(testDriveVehicleBlip)
  end

  testDriveVehicleBlip = nil
end

local function createSaleVehicleBlip(coords, label, timeoutMs)
  removeSaleVehicleBlip()

  saleVehicleBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(saleVehicleBlip, 225)
  SetBlipColour(saleVehicleBlip, 2)
  SetBlipScale(saleVehicleBlip, 1.0)
  SetBlipAsShortRange(saleVehicleBlip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(label or "Sold Vehicle Location")
  EndTextCommandSetBlipName(saleVehicleBlip)
  SetBlipRoute(saleVehicleBlip, true)
  SetBlipRouteColour(saleVehicleBlip, 2)
  SetTimeout(timeoutMs or 60000, removeSaleVehicleBlip)
end

local function createTestDriveVehicleBlip(coords)
  removeTestDriveVehicleBlip()

  testDriveVehicleBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(testDriveVehicleBlip, 225)
  SetBlipColour(testDriveVehicleBlip, 2)
  SetBlipScale(testDriveVehicleBlip, 1.0)
  SetBlipAsShortRange(testDriveVehicleBlip, false)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString("Test Drive Vehicle")
  EndTextCommandSetBlipName(testDriveVehicleBlip)
  SetBlipRoute(testDriveVehicleBlip, true)
  SetBlipRouteColour(testDriveVehicleBlip, 2)
end

local function stopTrackingVehicle()
  trackingActive = false
  trackedTestDriveSessionId = nil
  removeTestDriveVehicleBlip()
end

local function trackTestDriveVehicle(sessionId)
  if not sessionId then
    return
  end

  if trackingActive and trackedTestDriveSessionId == sessionId then
    return
  end

  if trackingActive then
    stopTrackingVehicle()
  end

  trackingActive = true
  trackedTestDriveSessionId = sessionId

  CreateThread(function()
    while trackingActive and trackedTestDriveSessionId == sessionId do
      local coords = lib.callback.await("jg-dealerships:server:get-test-drive-vehicle-coords", false, sessionId)

      if not coords then
        stopTrackingVehicle()
        break
      end

      if testDriveVehicleBlip and DoesBlipExist(testDriveVehicleBlip) then
        SetBlipCoords(testDriveVehicleBlip, coords.x, coords.y, coords.z)
      else
        createTestDriveVehicleBlip(vector4(coords.x, coords.y, coords.z, 0.0))
      end

      Wait(1000)
    end
  end)
end

local function startDirectTestDrive(data)
  local success, spawnCoords, netId, sessionId, spawnOnClient, plate = lib.callback.await(
    "jg-dealerships:server:start-direct-test-drive",
    false,
    currentDealershipId,
    data.playerId,
    data.model,
    data.colour
  )

  if not success then
    return false
  end

  spawnCoords = Utils.Client.FindAvailableSpawnCoords(Utils.Client.ConvertSpawnCoordsToVec4(spawnCoords))

  if spawnOnClient then
    if not plate then
      Framework.Client.Notify(Locale.couldNotGetPlateFromServer, "error")
      return false
    end

    local vehicle = Spawn.Client.Create(0, data.model, plate, spawnCoords, false, {
      plate = plate,
      colour = data.colour
    }, "testDrive")

    if not vehicle then
      Framework.Client.Notify(Locale.couldNotSpawnTestDriveVehicle, "error")
      return false
    end

    netId = VehToNet(vehicle)

    if not lib.callback.await("jg-dealerships:server:direct-test-drive-set-vehicle", false, sessionId, netId) then
      DeleteEntity(vehicle)
      Framework.Client.Notify(Locale.couldNotRegisterTestDriveVehicle, "error")
      return false
    end
  end

  activeTestDriveSessionId = sessionId
  createTestDriveVehicleBlip(spawnCoords)
  return true, spawnCoords, netId, sessionId
end

local function giveDirectTestDriveKeys()
  if not activeTestDriveSessionId then
    return false
  end

  return lib.callback.await("jg-dealerships:server:direct-test-drive-give-keys", false, activeTestDriveSessionId) == true
end

local function showDirectSaleRequest(uuid, dealerPlayerId, requestData)
  if type(requestData) ~= "table" then
    return false
  end

  local isSelfSale = dealerPlayerId == GetPlayerServerId(PlayerId())

  if not isSelfSale and LocalPlayer.state.isBusy then
    TriggerServerEvent("jg-dealerships:server:notify-other-player", dealerPlayerId, "Customer is in the showroom! Wait for them to come back, and try again", "error")
    return false
  end

  if not isSelfSale then
    SetNuiFocus(true, true)
  end

  SendNUIMessage({
    type = "show-direct-sale-request",
    uuid = uuid,
    dealerPlayerId = dealerPlayerId,
    dealerName = requestData.dealerName,
    dealershipId = requestData.dealershipId,
    dealershipLabel = requestData.dealershipLabel,
    playerBalances = GetPlayerBalances(requestData.dealershipId),
    paymentMethods = requestData.paymentMethods or { "bank", "cash" },
    currencies = requestData.currencies,
    vehicleLabel = (requestData.vehicle.brand or "") .. " " .. (requestData.vehicle.model or ""),
    vehicleSpawnCode = requestData.vehicle.spawn_code,
    vehicleCategory = requestData.vehicle.category,
    vehiclePrice = requestData.vehicle.price,
    color = requestData.colour,
    financed = requestData.financed,
    downPayment = requestData.downPayment,
    noOfPayments = requestData.noOfPayments,
    couponCode = requestData.couponCode,
    appliedCoupon = requestData.appliedCoupon,
    isSelfSale = isSelfSale or nil,
    config = Config,
    locale = Locale
  })
end

function DirectSales.Client.ShowDirectSaleTablet(dealershipId)
  currentDealershipId = dealershipId

  local data = lib.callback.await("jg-dealerships:server:get-direct-sale-data", false, dealershipId)
  if not data then
    return false
  end

  PlayTabletAnim()
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "show-sales-tablet",
    dealershipId = dealershipId,
    vehicles = data.vehicles,
    nearbyPlayers = data.nearbyPlayers,
    commission = data.commission,
    categories = data.categories,
    enableFinance = data.enableFinance,
    colourSelectionType = data.colourSelectionType,
    colourOptions = data.colourOptions,
    myPlayerId = GetPlayerServerId(PlayerId()),
    employeeName = data.employeeName,
    employeeRole = data.employeeRole,
    dealershipLabel = data.dealershipLabel,
    config = Config,
    locale = Locale
  })

  return true
end

RegisterNUICallback("send-direct-sale-request", function(data, callback)
  local success, uuid = lib.callback.await("jg-dealerships:server:send-direct-sale-request", false, currentDealershipId, data)
  if not success then
    return callback({ error = true })
  end

  callback({ success = true, uuid = uuid })
end)

RegisterNUICallback("accept-direct-sale-request", function(data, callback)
  if not data.isSelfSale then
    SetNuiFocus(false, false)
  end

  local success = lib.callback.await("jg-dealerships:server:direct-sale-request-accepted", false, data.uuid, {
    paymentMethod = data.paymentMethod,
    coords = data.coords
  })

  if not success then
    return callback({ error = true })
  end

  callback(true)
end)

RegisterNUICallback("deny-direct-sale-request", function(data, callback)
  local uuid = type(data) == "table" and data.uuid or data
  local isSelfSale = type(data) == "table" and data.isSelfSale or false

  if not isSelfSale then
    SetNuiFocus(false, false)
  end

  if not lib.callback.await("jg-dealerships:server:direct-sale-request-denied", false, uuid) then
    return callback({ error = true })
  end

  callback(true)
end)

RegisterNUICallback("reopen-sales-tablet", function(data, callback)
  local tabletData = lib.callback.await("jg-dealerships:server:get-direct-sale-data", false, data.dealershipId)
  if not tabletData then
    return callback(false)
  end

  SendNUIMessage({
    type = "show-sales-tablet",
    dealershipId = data.dealershipId,
    vehicles = tabletData.vehicles,
    nearbyPlayers = tabletData.nearbyPlayers,
    commission = tabletData.commission,
    categories = tabletData.categories,
    enableFinance = tabletData.enableFinance,
    colourSelectionType = tabletData.colourSelectionType,
    colourOptions = tabletData.colourOptions,
    myPlayerId = GetPlayerServerId(PlayerId()),
    employeeName = tabletData.employeeName,
    employeeRole = tabletData.employeeRole,
    dealershipLabel = tabletData.dealershipLabel,
    selfSaleResult = data.selfSaleResult,
    config = Config,
    locale = Locale
  })

  callback(true)
end)

RegisterNUICallback("cancel-direct-sale-request", function(data, callback)
  if not lib.callback.await("jg-dealerships:server:cancel-direct-sale-request", false, data) then
    return callback({ error = true })
  end

  callback(true)
end)

RegisterNUICallback("start-direct-test-drive", function(data, callback)
  local success, coords, netId, sessionId = startDirectTestDrive(data)
  if not success then
    return callback({ success = false })
  end

  callback({
    success = true,
    coords = coords,
    netId = netId,
    sessionId = sessionId
  })
end)

RegisterNUICallback("direct-test-drive-give-keys", function(_, callback)
  callback({ success = giveDirectTestDriveKeys() })
end)

RegisterNUICallback("cancel-direct-test-drive", function(data, callback)
  if not data.sessionId then
    return callback({ success = false })
  end

  if not lib.callback.await("jg-dealerships:server:cancel-direct-test-drive", false, data.sessionId) then
    return callback({ success = false })
  end

  removeTestDriveVehicleBlip()

  if activeTestDriveSessionId == data.sessionId then
    activeTestDriveSessionId = nil
  end

  callback({ success = true })
end)

RegisterNUICallback("get-active-test-drives", function(_, callback)
  if not currentDealershipId then
    return callback({ testDrives = {} })
  end

  callback({
    testDrives = lib.callback.await("jg-dealerships:server:get-active-test-drives", false, currentDealershipId) or {}
  })
end)

RegisterNUICallback("end-test-drive-remote", function(data, callback)
  if not data.sessionId then
    return callback({ success = false })
  end

  if not lib.callback.await("jg-dealerships:server:end-test-drive-remote", false, data.sessionId) then
    return callback({ success = false })
  end

  if activeTestDriveSessionId == data.sessionId then
    activeTestDriveSessionId = nil
  end

  stopTrackingVehicle()
  callback({ success = true })
end)

RegisterNUICallback("track-test-drive-vehicle", function(data, callback)
  if not data.sessionId then
    return callback({ success = false })
  end

  trackTestDriveVehicle(data.sessionId)
  Framework.Client.Notify(Locale.trackingVehicleLocation, "success")
  callback({ success = true, sessionId = data.sessionId })
end)

RegisterNUICallback("stop-tracking-vehicle", function(_, callback)
  stopTrackingVehicle()
  callback({ success = true })
end)

RegisterNUICallback("get-tracking-state", function(_, callback)
  callback({
    isTracking = trackingActive,
    sessionId = trackedTestDriveSessionId
  })
end)

RegisterNetEvent("jg-dealerships:client:show-direct-sale-request", showDirectSaleRequest)

RegisterNetEvent("jg-dealerships:client:direct-sale-response", function(uuid, status, vehicleCoords)
  if status == "accepted" and vehicleCoords then
    createSaleVehicleBlip(vehicleCoords)
  end

  SendNUIMessage({
    type = "direct-sale-response",
    uuid = uuid,
    status = status,
    vehicleCoords = vehicleCoords
  })
end)

RegisterNetEvent("jg-dealerships:client:direct-sale-cancelled", function()
  SetNuiFocus(false, false)
  SendNUIMessage({ type = "direct-sale-cancelled" })
  Framework.Client.Notify(Locale.directSaleCancelled, "error")
end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-receive-keys", function(netId, plate)
  local vehicle = NetToVeh(netId)
  if not vehicle or not DoesEntityExist(vehicle) then
    return
  end

  Framework.Client.VehicleGiveKeys(plate, vehicle, "testDrive")
  Framework.Client.Notify(Locale.testDriveKeysReceived, "success")
end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-ended", function(plate)
  local vehicle = GetVehiclePedIsIn(cache.ped, false)

  if vehicle and vehicle ~= 0 then
    local currentPlate = GetVehicleNumberPlateText(vehicle)
    if currentPlate and currentPlate:gsub("%s+", "") == plate:gsub("%s+", "") then
      Framework.Client.VehicleRemoveKeys(plate, vehicle, "testDrive")
    end
  end

  Framework.Client.Notify(Locale.testDriveEndedCustomer, "success")
end)

RegisterNetEvent("jg-dealerships:client:direct-test-drive-ended-remote", function(plate, silent)
  local vehicle = GetVehiclePedIsIn(cache.ped, false)

  if vehicle and vehicle ~= 0 then
    local currentPlate = GetVehicleNumberPlateText(vehicle)
    if currentPlate and currentPlate:gsub("%s+", "") == plate:gsub("%s+", "") then
      Framework.Client.VehicleRemoveKeys(plate, vehicle, "testDrive")
    end
  end

  if not silent then
    Framework.Client.Notify(Locale.testDriveEndedByEmployee, "warning")
  end
end)

lib.callback.register("jg-dealerships:client:open-direct-sale-tablet", function()
  local currentZone = DealershipZones.Client.GetCurrentZone()
  if not currentZone then
    Framework.Client.Notify(Locale.notInDealershipZone, "error")
    return false
  end

  return DirectSales.Client.ShowDirectSaleTablet(currentZone)
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    stopTrackingVehicle()
    removeSaleVehicleBlip()
    activeTestDriveSessionId = nil
  end
end)
