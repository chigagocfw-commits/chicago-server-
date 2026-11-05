local function getSellVehicleValue(playerSource, dealershipId, plate, model)
  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership or not dealership.enable_sell_vehicle then
    return false
  end

  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  local ownedVehicle = MySQL.single.await(
    ([[
      SELECT * FROM %s WHERE plate = ? AND %s = ?
    ]]):format(Framework.VehiclesTable, Framework.PlayerId),
    { plate, playerIdentifier }
  )

  if not ownedVehicle then
    DebugPrint(("The vehicle %s is not owned by player: %s (%s)"):format(plate, playerIdentifier, playerSource), "warning")
    Framework.Server.Notify(playerSource, Locale.notYourVehicleError, "error")
    return false
  end

  local ownedVehicleModel = Framework.Server.GetModelColumn(ownedVehicle)
  if type(ownedVehicleModel) == "string" then
    ownedVehicleModel = ownedVehicleModel:lower()
  end

  model = model:lower()
  if ownedVehicleModel ~= model and ownedVehicleModel ~= joaat(model) then
    DebugPrint(("[sell-vehicle]: model does not match db: %s doesn't match %s or %s"):format(ownedVehicleModel, model, joaat(model)), "warning")
    Framework.Server.Notify(playerSource, Locale.modelDoesNotMatchDb, "error")
    return false
  end

  if ownedVehicle.financed then
    Framework.Server.Notify(playerSource, Locale.vehicleFinancedError, "error")
    return false
  end

  local stockVehicle = MySQL.single.await([[
    SELECT *, stock.price as stock_price FROM dealership_stock stock
    INNER JOIN dealership_vehicles vehicle ON vehicle.spawn_code = stock.vehicle
    WHERE stock.dealership = ? AND vehicle.spawn_code = ?
  ]], { dealershipId, model })

  if not stockVehicle then
    Framework.Server.Notify(playerSource, Locale.dealershipDoesntSellVehicle, "error")
    return false
  end

  return Round(stockVehicle.stock_price * ((dealership.sell_vehicle_percent or 60) / 100))
end

lib.callback.register("jg-dealerships:server:sell-vehicle-get-value", function(playerSource, dealershipId, plate, model)
  local vehicleValue = getSellVehicleValue(playerSource, dealershipId, plate, model)
  if not vehicleValue then
    return false
  end

  if not SellVehiclePreCheck(dealershipId, plate, model, vehicleValue) then
    return false
  end

  return vehicleValue
end)

lib.callback.register("jg-dealerships:server:sell-vehicle", function(playerSource, dealershipId, plate, model)
  local vehicleValue = getSellVehicleValue(playerSource, dealershipId, plate, model)
  if not vehicleValue then
    return false
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  if dealership.type == "owned" then
    local hasFunds = DealershipBalance.Server.HasFunds(dealershipId, vehicleValue)
    if not hasFunds then
      Framework.Server.Notify(playerSource, Locale.dealershipDoesntSellVehicle, "error")
      return false
    end

    DealershipBalance.Server.Remove(dealershipId, vehicleValue)
    MySQL.update.await("UPDATE dealership_stock SET stock = stock + 1 WHERE dealership = ? AND vehicle = ?", {
      dealershipId,
      model,
    })
    Showroom.Server.UpdateVehicleCache(model, dealershipId)
  end

  MySQL.query.await(("DELETE FROM %s WHERE plate = ?"):format(Framework.VehiclesTable), { plate })
  Framework.Server.PlayerAddMoney(playerSource, vehicleValue, "bank")
  return true
end)
