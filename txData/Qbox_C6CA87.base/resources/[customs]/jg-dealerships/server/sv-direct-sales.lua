local pendingDirectSales = {}

local function createPendingDirectSale(dealershipId, dealerPlayerId, playerId, model, colour, price, finance, noOfPayments, downPayment, couponCode, appliedCoupon)
  local requestId = Utils.Server.GenerateUuid()
  local attempts = 0

  while pendingDirectSales[requestId] and attempts < 10 do
    attempts = attempts + 1
    requestId = Utils.Server.GenerateUuid()
  end

  pendingDirectSales[requestId] = {
    dealershipId = dealershipId,
    dealerPlayerId = dealerPlayerId,
    playerId = playerId,
    model = model,
    colour = colour,
    price = price,
    finance = finance,
    noOfPayments = noOfPayments,
    downPayment = downPayment,
    couponCode = couponCode,
    appliedCoupon = appliedCoupon,
  }

  return requestId
end

local function removePendingDirectSale(requestId)
  if pendingDirectSales[requestId] then
    pendingDirectSales[requestId] = nil
  end
end

DirectSales = DirectSales or {}
DirectSales.Server = DirectSales.Server or {}

function DirectSales.Server.GetPending(requestId)
  return pendingDirectSales[requestId] or false
end

lib.callback.register("jg-dealerships:server:get-direct-sale-data", function(playerSource, dealershipId)
  local employeeRole = Employees.Server.IsEmployee(playerSource, dealershipId, "SELL", false)

  if not employeeRole then
    employeeRole = Employees.Server.IsEmployee(playerSource, dealershipId, "SELL", true)
    if not employeeRole then
      Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
      return false
    end
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership or dealership.type == "selfService" then
    return false
  end

  local playerInfo = Framework.Server.GetPlayerInfo(playerSource)

  return {
    vehicles = Showroom.Server.GetVehicles(dealershipId),
    categories = dealership.categories,
    enableFinance = dealership.enable_finance,
    commission = (dealership.employee_commission or 10) / 100,
    nearbyPlayers = Utils.Server.GetNearbyPlayers(
      playerSource,
      GetEntityCoords(GetPlayerPed(playerSource)),
      10.0,
      true
    ),
    colourSelectionType = dealership.colour_selection_type or "RGB",
    colourOptions = dealership.colour_options or {},
    employeeName = playerInfo and playerInfo.name or "",
    employeeRole = employeeRole,
    dealershipLabel = dealership.name or dealershipId,
  }
end)

lib.callback.register("jg-dealerships:server:send-direct-sale-request", function(playerSource, dealershipId, saleData)
  if not dealershipId then
    return false
  end

  if not Employees.Server.IsEmployee(playerSource, dealershipId, "SELL") then
    Framework.Server.Notify(playerSource, Locale.employeePermissionsError, "error")
    return false
  end

  local dealerInfo = Framework.Server.GetPlayerInfo(playerSource)
  local dealerName = dealerInfo and dealerInfo.name
  local buyerPlayerId = saleData.playerId
  local buyerIdentifier = Framework.Server.GetPlayerIdentifier(buyerPlayerId)
  local model = saleData.model
  local colour = saleData.colour
  local finance = saleData.finance
  local financePayments = saleData.financePayments
  local financeDownPayment = saleData.financeDownPayment
  local couponCode = saleData.couponCode
  local appliedCoupon = saleData.appliedCoupon

  if couponCode and couponCode ~= "" and Coupons and Coupons.Server and Coupons.Server.ValidateAndApplyCoupon then
    local showroomVehicle = Showroom.Server.GetVehicle(dealershipId, model)

    if showroomVehicle then
      local couponResult = Coupons.Server.ValidateAndApplyCoupon(
        playerSource,
        dealershipId,
        couponCode,
        model,
        showroomVehicle.category,
        finance,
        showroomVehicle.price,
        buyerPlayerId
      )

      if couponResult.valid then
        appliedCoupon = couponResult
      else
        Framework.Server.Notify(
          playerSource,
          Locale.invalidCoupon:gsub("%%{value}", couponResult.message or "Unknown error"),
          "error"
        )
        return false
      end
    end
  end

  if finance then
    local financeRows = MySQL.query.await(
      "SELECT COUNT(*) as total FROM " .. Framework.VehiclesTable .. " WHERE financed = 1 AND " .. Framework.PlayerId .. " = ?",
      { buyerIdentifier }
    )
    local financedVehicleCount = financeRows[1].total

    if financedVehicleCount >= (Config.MaxFinancedVehiclesPerPlayer or 999999) then
      Framework.Server.Notify(playerSource, Locale.playerTooManyFinancedVehicles, "error")
      return false
    end
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  local vehicle = Showroom.Server.GetVehicle(dealershipId, model)
  if not vehicle then
    return false
  end

  local requestId = createPendingDirectSale(
    dealershipId,
    playerSource,
    buyerPlayerId,
    model,
    colour,
    vehicle.price,
    finance,
    financePayments,
    financeDownPayment,
    couponCode,
    appliedCoupon
  )

  TriggerClientEvent("jg-dealerships:client:show-direct-sale-request", buyerPlayerId, requestId, playerSource, {
    dealerName = dealerName,
    dealershipId = dealershipId,
    dealershipLabel = dealership.name or dealership.id,
    vehicle = vehicle,
    colour = colour,
    financed = finance,
    downPayment = financeDownPayment,
    noOfPayments = financePayments,
    couponCode = couponCode,
    appliedCoupon = appliedCoupon,
  })

  return true, requestId
end)

lib.callback.register("jg-dealerships:server:cancel-direct-sale-request", function(playerSource, requestId)
  local pendingSale = pendingDirectSales[requestId]
  if not pendingSale or playerSource ~= pendingSale.dealerPlayerId then
    return false
  end

  TriggerClientEvent("jg-dealerships:client:direct-sale-cancelled", pendingSale.playerId)
  removePendingDirectSale(requestId)
  return true
end)

lib.callback.register("jg-dealerships:server:direct-sale-request-accepted", function(playerSource, requestId, purchaseData)
  local pendingSale = pendingDirectSales[requestId]
  if not pendingSale or playerSource ~= pendingSale.playerId then
    return false
  end

  local salePrice = pendingSale.finance and pendingSale.price * (1 + Config.FinanceInterest) or pendingSale.price
  local dealershipId = pendingSale.dealershipId
  local dealerPlayerId = pendingSale.dealerPlayerId
  local dealership = Locations.Server.GetById(dealershipId)

  if not dealership then
    return false
  end

  if dealerPlayerId ~= playerSource then
    local commission = Round(salePrice * ((dealership.employee_commission or 10) / 100))
    DealershipBalance.Server.Remove(dealershipId, commission)
    Framework.Server.PlayerAddMoney(dealerPlayerId, commission, "bank")
  end

  local vehicleSpawnCoords = purchaseData and purchaseData.coords or (dealership.purchase_vehicle_coords and dealership.purchase_vehicle_coords[1])

  TriggerClientEvent(
    "jg-dealerships:client:direct-sale-response",
    dealerPlayerId,
    requestId,
    "accepted",
    vehicleSpawnCoords
  )

  removePendingDirectSale(requestId)
  return true, vehicleSpawnCoords
end)

lib.callback.register("jg-dealerships:server:direct-sale-request-denied", function(playerSource, requestId)
  local pendingSale = pendingDirectSales[requestId]
  if not pendingSale or playerSource ~= pendingSale.playerId then
    return false
  end

  TriggerClientEvent("jg-dealerships:client:direct-sale-response", pendingSale.dealerPlayerId, requestId, "declined")
  removePendingDirectSale(requestId)
  return true
end)
