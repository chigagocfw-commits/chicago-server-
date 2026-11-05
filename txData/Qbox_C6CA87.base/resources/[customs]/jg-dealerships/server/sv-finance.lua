Finance = Finance or {}
Finance.Server = Finance.Server or {}

function Finance.Server.GetAllFinancedVehicles()
  return MySQL.query.await(
    "SELECT * FROM " .. Framework.VehiclesTable .. " WHERE financed = ?",
    { 1 }
  ) or {}
end

function Finance.Server.GetPlayerFinancedVehicles(identifier)
  return MySQL.query.await(
    "SELECT * FROM " .. Framework.VehiclesTable .. " WHERE " .. Framework.PlayerId .. " = ? AND financed = ?",
    { identifier, 1 }
  ) or {}
end

function Finance.Server.GetFinancedVehicle(identifier, plate)
  return MySQL.single.await(
    "SELECT * FROM " .. Framework.VehiclesTable .. " WHERE " .. Framework.PlayerId .. " = ? AND plate = ? AND financed = ?",
    { identifier, plate, 1 }
  )
end

local function updateVehicleFinance(plate, financed, financeData)
  MySQL.update.await(
    "UPDATE " .. Framework.VehiclesTable .. " SET financed = ?, finance_data = ? WHERE plate = ?",
    { financed and 1 or 0, financeData and json.encode(financeData) or nil, plate }
  )
end

local function updateSaleFinance(plate, paid, owed)
  MySQL.update.await(
    "UPDATE dealership_sales SET paid = ?, owed = ? WHERE plate = ?",
    { paid, Round(owed), plate }
  )
end

function Finance.Server.MakePayment(playerSource, vehicle, financeData)
  local currency = financeData.currency or "bank"
  local paymentBaseAmount = financeData.recurring_payment
  local paymentAmount = Round(Currencies.Server.ConvertFromBase(paymentBaseAmount, currency))
  local playerBalance = Framework.Server.GetPlayerBalance(playerSource, currency)

  if paymentAmount > playerBalance then
    Framework.Server.Notify(playerSource, Locale.errorNotEnoughMoney, "error")
    DebugPrint(("Player %s tried to make payment but insufficient funds. Balance: %s, Required: %s (currency: %s)"):format(
      playerSource,
      playerBalance,
      paymentAmount,
      currency
    ), "debug")
    return false
  end

  Framework.Server.PlayerRemoveMoney(playerSource, paymentAmount, currency)
  DealershipBalance.Server.Add(financeData.dealership_id, paymentBaseAmount)

  financeData.paid = financeData.paid + paymentBaseAmount
  financeData.payment_failed = false
  financeData.payments_complete = financeData.payments_complete + 1
  financeData.seconds_to_next_payment = 3600 * financeData.payment_interval

  DebugPrint(("Player %s made payment of %s (%s %s) for vehicle %s. Completed: %s/%s"):format(
    playerSource,
    paymentBaseAmount,
    paymentAmount,
    currency,
    vehicle.plate,
    financeData.payments_complete,
    financeData.total_payments
  ), "debug")

  updateSaleFinance(vehicle.plate, financeData.paid, financeData.total - financeData.paid)
  Framework.Server.Notify(playerSource, Locale.vehicleFinancePaymentMade:gsub("%%{value}", vehicle.plate), "success")
  SendWebhook(playerSource, Webhooks.Finance, "Finance: Payment Success", "success", {
    { key = "Plate", value = vehicle.plate },
    { key = "Payment amount", value = paymentBaseAmount },
    { key = "Currency", value = currency },
  })

  if financeData.payments_complete >= financeData.total_payments then
    updateVehicleFinance(vehicle.plate, false, nil)
    DebugPrint(("Player %s paid off vehicle %s"):format(playerSource, vehicle.plate), "debug")
    Framework.Server.Notify(playerSource, Locale.vehicleFinancePaidOff:gsub("%%{value}", vehicle.plate), "success")
    SendWebhook(playerSource, Webhooks.Finance, "Finance: Vehicle paid off", "success", {
      { key = "Plate", value = vehicle.plate },
    })
    TriggerEvent("jg-dealerships:server:vehicle-finance-complete", playerSource, vehicle.plate)
    return true, nil, true
  end

  updateVehicleFinance(vehicle.plate, true, financeData)
  return true, financeData, false
end

function Finance.Server.PayInFull(playerSource, vehicle, financeData)
  local currency = financeData.currency or "bank"
  local outstandingBaseAmount = financeData.total - financeData.paid
  local outstandingAmount = Round(Currencies.Server.ConvertFromBase(outstandingBaseAmount, currency))
  local playerBalance = Framework.Server.GetPlayerBalance(playerSource, currency)

  if outstandingAmount > playerBalance then
    Framework.Server.Notify(playerSource, Locale.errorNotEnoughMoney, "error")
    DebugPrint(("Player %s tried to pay off vehicle %s but insufficient funds. Balance: %s, Required: %s (currency: %s)"):format(
      playerSource,
      vehicle.plate,
      playerBalance,
      outstandingAmount,
      currency
    ), "debug")
    return false
  end

  Framework.Server.PlayerRemoveMoney(playerSource, outstandingAmount, currency)
  DealershipBalance.Server.Add(financeData.dealership_id, outstandingBaseAmount)
  updateVehicleFinance(vehicle.plate, false, nil)
  updateSaleFinance(vehicle.plate, financeData.total, 0)

  DebugPrint(("Player %s paid off vehicle %s in full. Amount: %s"):format(playerSource, vehicle.plate, outstandingAmount), "debug")
  Framework.Server.Notify(playerSource, Locale.vehicleFinancePaidOff:gsub("%%{value}", vehicle.plate), "success")
  SendWebhook(playerSource, Webhooks.Finance, "Finance: Vehicle paid off", "success", {
    { key = "Plate", value = vehicle.plate },
  })
  TriggerEvent("jg-dealerships:server:vehicle-finance-complete", playerSource, vehicle.plate)

  return true
end

function Finance.Server.RepossessVehicle(playerSource, vehicle, financeData)
  DebugPrint(("Repossessing vehicle %s due to payment failure"):format(vehicle.plate), "debug")

  MySQL.query.await("DELETE FROM " .. Framework.VehiclesTable .. " WHERE plate = ?", { vehicle.plate })
  MySQL.update.await(
    "UPDATE dealership_stock SET stock = stock + 1 WHERE vehicle = ? AND dealership = ?",
    { financeData.vehicle, financeData.dealership_id }
  )
  Showroom.Server.UpdateVehicleCache(financeData.vehicle, financeData.dealership_id)

  if GetResourceState("jg-advancedgarages") == "started" then
    TriggerEvent("jg-advancedgarages:server:DeleteOutsideVehicle", vehicle.plate)
  end

  if playerSource then
    Framework.Server.Notify(playerSource, Locale.vehicleFinanceRepossessed:gsub("%%{value}", vehicle.plate), "error")
  end

  SendWebhook(playerSource or 0, Webhooks.Finance, "Finance: Vehicle Repossessed!", "danger", {
    { key = "Plate", value = vehicle.plate },
    { key = "Balance owed", value = financeData.total - financeData.paid },
  })
  TriggerEvent("jg-dealerships:server:vehicle-finance-defaulted", playerSource or 0, vehicle.plate, financeData.total - financeData.paid)
end

lib.callback.register("jg-dealerships:server:get-financed-vehicles", function(playerSource)
  local identifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not identifier then
    return {}
  end

  DebugPrint(("Getting financed vehicles for player %s"):format(identifier), "debug")
  local vehicles = Finance.Server.GetPlayerFinancedVehicles(identifier)
  DebugPrint(("Got %s financed vehicles for player %s"):format(#vehicles, identifier), "debug")
  return vehicles
end)

lib.callback.register("jg-dealerships:server:finance-make-payment", function(playerSource, plate, paymentType)
  local identifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not identifier then
    return { error = true }
  end

  local vehicle = Finance.Server.GetFinancedVehicle(identifier, plate)
  if not vehicle or not vehicle.finance_data then
    DebugPrint(("Player %s (%s) tried to make payment on vehicle %s that doesn't exist or isn't financed"):format(
      identifier,
      playerSource,
      plate
    ), "debug")
    return { error = true }
  end

  local financeData = json.decode(vehicle.finance_data)

  if paymentType == "payment" then
    local success, updatedFinanceData, paidOff = Finance.Server.MakePayment(playerSource, vehicle, financeData)
    if not success then
      return { error = true }
    end

    return {
      success = true,
      paidOff = paidOff,
      plate = vehicle.plate,
      financed = not paidOff,
      finance_data = updatedFinanceData,
    }
  end

  if paymentType == "pay-in-full" then
    if not Finance.Server.PayInFull(playerSource, vehicle, financeData) then
      return { error = true }
    end

    return {
      success = true,
      paidOff = true,
      plate = vehicle.plate,
      financed = false,
      finance_data = nil,
    }
  end

  return { error = true }
end)

local function getOnlinePlayersByIdentifier()
  local onlinePlayers = {}
  for _, player in pairs(Framework.Server.GetPlayers()) do
    local playerSource = player.player_id
    local identifier = Framework.Server.GetPlayerIdentifier(playerSource)
    if identifier then
      onlinePlayers[identifier] = playerSource
    end
  end

  return onlinePlayers
end

local function processVehicleFinance(playerSource, identifier, vehicle, elapsedSeconds)
  if not vehicle.financed or not vehicle.finance_data then
    return
  end

  local financeData = json.decode(vehicle.finance_data)
  local playerIsOnline = playerSource ~= nil
  local currency = financeData.currency or "bank"
  local supportsOffline = Currencies.Server.SupportsOffline(currency)

  if financeData.payment_failed then
    financeData.seconds_to_repo = financeData.seconds_to_repo - elapsedSeconds
    DebugPrint(("Finance payment failed for vehicle %s. Seconds until repo: %s (owner %s)"):format(
      vehicle.plate,
      financeData.seconds_to_repo,
      playerIsOnline and "online" or "offline"
    ), "debug")

    if playerIsOnline and playerSource then
      Framework.Server.Notify(playerSource, Locale.vehicleFinanceRepossessedSoon:gsub("%%{value}", vehicle.plate), "error")
    end

    if financeData.seconds_to_repo <= 0 then
      Finance.Server.RepossessVehicle(playerSource, vehicle, financeData)
      return
    end

    updateVehicleFinance(vehicle.plate, true, financeData)
    return
  end

  financeData.seconds_to_next_payment = financeData.seconds_to_next_payment - elapsedSeconds
  if financeData.seconds_to_next_payment > 0 then
    updateVehicleFinance(vehicle.plate, true, financeData)
    return
  end

  local paymentBaseAmount = financeData.recurring_payment
  local paymentAmount = Round(Currencies.Server.ConvertFromBase(paymentBaseAmount, currency))
  local playerBalance

  if playerIsOnline and playerSource then
    playerBalance = Framework.Server.GetPlayerBalance(playerSource, currency)
  elseif supportsOffline then
    playerBalance = Currencies.Server.GetBalanceOffline(identifier, currency)
  else
    DebugPrint(("Skipping offline payment for vehicle %s - currency %s doesn't support offline operations"):format(vehicle.plate, currency), "debug")
    updateVehicleFinance(vehicle.plate, true, financeData)
    return
  end

  if paymentAmount > playerBalance then
    DebugPrint(("Finance payment failed for vehicle %s. Player %s insufficient funds. Balance: %s, Required: %s (currency: %s)"):format(
      vehicle.plate,
      identifier,
      playerBalance,
      paymentAmount,
      currency
    ), "debug")

    financeData.payment_failed = true
    financeData.seconds_to_repo = 3600 * Config.FinancePaymentFailedHoursUntilRepo

    if playerIsOnline and playerSource then
      Framework.Server.Notify(playerSource, Locale.vehicleFinancePaymentFailed:gsub("%%{value}", vehicle.plate), "error")
    end

    SendWebhook(playerSource or 0, Webhooks.Finance, "Finance: Payment Failed", "danger", {
      { key = "Plate", value = vehicle.plate },
      { key = "Payment amount", value = paymentBaseAmount },
      { key = "Currency", value = currency },
      { key = "Owner Status", value = playerIsOnline and "Online" or "Offline" },
    })

    updateVehicleFinance(vehicle.plate, true, financeData)
    return
  end

  if playerIsOnline and playerSource then
    Framework.Server.PlayerRemoveMoney(playerSource, paymentAmount, currency)
  else
    Currencies.Server.RemoveBalanceOffline(identifier, paymentAmount, currency)
  end

  DealershipBalance.Server.Add(financeData.dealership_id, paymentBaseAmount)
  financeData.paid = financeData.paid + paymentBaseAmount
  financeData.payments_complete = financeData.payments_complete + 1
  financeData.seconds_to_next_payment = 3600 * financeData.payment_interval

  DebugPrint(("Auto-payment: Player %s paid %s (%s %s) for vehicle %s. Completed: %s/%s (%s)"):format(
    identifier,
    paymentBaseAmount,
    paymentAmount,
    currency,
    vehicle.plate,
    financeData.payments_complete,
    financeData.total_payments,
    playerIsOnline and "online" or "offline"
  ), "debug")

  updateSaleFinance(vehicle.plate, financeData.paid, financeData.total - financeData.paid)

  if playerIsOnline and playerSource then
    Framework.Server.Notify(playerSource, Locale.vehicleFinancePaymentMade:gsub("%%{value}", vehicle.plate), "success")
  end

  SendWebhook(playerSource or 0, Webhooks.Finance, "Finance: Payment Success", "success", {
    { key = "Plate", value = vehicle.plate },
    { key = "Payment amount", value = financeData.recurring_payment },
    { key = "Owner Status", value = playerIsOnline and "Online" or "Offline" },
  })

  if financeData.payments_complete >= financeData.total_payments then
    DebugPrint(("Player %s paid off vehicle %s via auto-payment (%s)"):format(
      identifier,
      vehicle.plate,
      playerIsOnline and "online" or "offline"
    ), "debug")

    if playerIsOnline and playerSource then
      Framework.Server.Notify(playerSource, Locale.vehicleFinancePaidOff:gsub("%%{value}", vehicle.plate), "success")
    end

    SendWebhook(playerSource or 0, Webhooks.Finance, "Finance: Vehicle paid off", "success", {
      { key = "Plate", value = vehicle.plate },
      { key = "Owner Status", value = playerIsOnline and "Online" or "Offline" },
    })
    TriggerEvent("jg-dealerships:server:vehicle-finance-complete", playerSource or 0, vehicle.plate)
    updateVehicleFinance(vehicle.plate, false, nil)
    return
  end

  updateVehicleFinance(vehicle.plate, true, financeData)
end

function Finance.Server.ProcessPlayerFinances(playerSource, identifier, elapsedSeconds)
  local vehicles = Finance.Server.GetPlayerFinancedVehicles(identifier)
  if #vehicles == 0 then
    return
  end

  DebugPrint(("Processing %s financed vehicles for player %s"):format(#vehicles, identifier), "debug")

  for _, vehicle in ipairs(vehicles) do
    local success, errorMessage = pcall(processVehicleFinance, playerSource, identifier, vehicle, elapsedSeconds)
    if not success then
      DebugPrint(("Error processing finance for vehicle %s (player %s): %s"):format(vehicle.plate, identifier, errorMessage), "error")
    end

    Wait(100)
  end
end

local financeCronMinutes = 10
local firstFinanceRun = true

lib.cron.new(("*/%s * * * *"):format(financeCronMinutes), function()
  local elapsedSeconds = firstFinanceRun and 0 or financeCronMinutes * 60
  firstFinanceRun = false

  DebugPrint(("Finance cron job running. Elapsed seconds: %s"):format(elapsedSeconds), "debug")

  local onlinePlayers = getOnlinePlayersByIdentifier()
  local processedIdentifiers = {}

  for identifier, playerSource in pairs(onlinePlayers) do
    local success, errorMessage = pcall(Finance.Server.ProcessPlayerFinances, playerSource, identifier, elapsedSeconds)
    if not success then
      DebugPrint(("Error processing finances for player %s: %s"):format(identifier, errorMessage), "error")
    end

    processedIdentifiers[identifier] = true
  end

  if Config.FinanceProcessOfflinePlayers then
    for _, vehicle in ipairs(Finance.Server.GetAllFinancedVehicles()) do
      local identifier = vehicle[Framework.PlayerId]
      if not processedIdentifiers[identifier] then
        local success, errorMessage = pcall(processVehicleFinance, nil, identifier, vehicle, elapsedSeconds)
        if not success then
          DebugPrint(("Error processing offline finance for vehicle %s (owner %s): %s"):format(vehicle.plate, identifier, errorMessage), "error")
        end

        Wait(100)
      end
    end
  end
end)

exports("getPlayerFinancedVehicles", function(identifier)
  if type(identifier) ~= "string" then
    return {}
  end

  return Finance.Server.GetPlayerFinancedVehicles(identifier)
end)

exports("getFinanceByPlate", function(plate)
  if type(plate) ~= "string" then
    return nil
  end

  return MySQL.single.await(
    "SELECT * FROM " .. Framework.VehiclesTable .. " WHERE plate = ? AND financed = ?",
    { plate, 1 }
  )
end)

exports("makeFinancePayment", function(playerSource, plate)
  if type(playerSource) ~= "number" or type(plate) ~= "string" then
    return false, "src must be a number and plate must be a string"
  end

  local identifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not identifier then
    return false, "player not found"
  end

  local vehicle = Finance.Server.GetFinancedVehicle(identifier, plate)
  if not vehicle then
    return false, "no financed vehicle found with this plate for this player"
  end

  local financeData = type(vehicle.finance_data) == "string" and json.decode(vehicle.finance_data) or vehicle.finance_data
  if not financeData then
    return false, "failed to decode finance data"
  end

  if not Finance.Server.MakePayment(playerSource, vehicle, financeData) then
    return false, "payment failed (insufficient funds or payment error)"
  end

  return true
end)

exports("getPlayerFinanceCount", function(identifier)
  if type(identifier) ~= "string" then
    return 0
  end

  return MySQL.scalar.await(
    "SELECT COUNT(*) FROM " .. Framework.VehiclesTable .. " WHERE " .. Framework.PlayerId .. " = ? AND financed = ?",
    { identifier, 1 }
  ) or 0
end)
