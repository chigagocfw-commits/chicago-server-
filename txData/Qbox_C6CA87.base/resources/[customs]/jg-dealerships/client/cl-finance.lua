Finance = Finance or {}
Finance.Client = Finance.Client or {}

function Finance.Client.GetFinancedVehicles()
  local vehicles = lib.callback.await("jg-dealerships:server:get-financed-vehicles", false)

  for index, vehicle in pairs(vehicles) do
    if vehicle.financed and vehicle.finance_data then
      local model = Framework.Client.GetModelColumn(vehicle)
      vehicles[index].vehicleLabel = model and Framework.Client.GetVehicleLabel(model) or model
      vehicles[index].finance_data = json.decode(vehicle.finance_data)
    end
  end

  return {
    type = "manageFinance",
    vehicles = vehicles,
    config = Config,
    locale = Locale,
  }
end

function Finance.Client.OpenFinanceMenu()
  SetNuiFocus(true, true)
  SendNUIMessage(Finance.Client.GetFinancedVehicles())
end

lib.callback.register("jg-dealerships:client:open-finance-menu", function()
  Finance.Client.OpenFinanceMenu()
  return true
end)

RegisterNUICallback("finance-make-payment", function(data, callback)
  callback(lib.callback.await(
    "jg-dealerships:server:finance-make-payment",
    false,
    data.plate,
    data.type
  ))
end)
