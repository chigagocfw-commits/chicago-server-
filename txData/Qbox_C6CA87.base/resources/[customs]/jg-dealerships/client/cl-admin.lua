Admin = Admin or {}
Admin.Client = Admin.Client or {}

function Admin.Client.Open()
  local currencies = lib.callback.await("jg-dealerships:server:get-currencies", false)

  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "showNewAdmin",
    locale = Locale,
    config = Config,
    currencies = currencies,
  })
end

RegisterNetEvent("jg-dealerships:client:open-admin", function()
  Admin.Client.Open()
end)

local passthroughCallbacks = {
  ["fetch-all-locations-admin"] = "jg-dealerships:server:fetch-all-locations-admin",
  ["create-location"] = "jg-dealerships:server:create-location",
  ["update-location"] = "jg-dealerships:server:update-location",
  ["delete-location"] = "jg-dealerships:server:delete-location",
  ["toggle-location-disabled"] = "jg-dealerships:server:toggle-location-disabled",
  ["validate-job"] = "jg-dealerships:server:validate-job",
  ["validate-gang"] = "jg-dealerships:server:validate-gang",
  ["fetch-all-vehicles-admin"] = "jg-dealerships:server:fetch-all-vehicles-admin",
  ["add-vehicle"] = "jg-dealerships:server:add-vehicle",
  ["delete-vehicle"] = "jg-dealerships:server:delete-vehicle",
  ["import-v1-locations"] = "jg-dealerships:server:import-v1-locations",
}

for nuiCallback, serverCallback in pairs(passthroughCallbacks) do
  RegisterNUICallback(nuiCallback, function(data, callback)
    callback(lib.callback.await(serverCallback, false, data))
  end)
end

RegisterNUICallback("manage-location", function(data, callback)
  DealershipManagement.Client.Open(data, nil, true)
  callback(true)
end)

RegisterNUICallback("set-waypoint", function(data, callback)
  SetNewWaypoint(data.x, data.y)
  callback(true)
end)

RegisterNUICallback("update-vehicle", function(data, callback)
  callback(lib.callback.await(
    "jg-dealerships:server:update-vehicle",
    false,
    data,
    data.updateDealerPrices
  ))
end)

RegisterNUICallback("verify-spawn-code", function(spawnCode, callback)
  if not spawnCode then
    return callback(false)
  end

  callback(IsModelValid(joaat(spawnCode)))
end)

RegisterNUICallback("preview-vehicles-data", function(data, callback)
  callback(lib.callback.await("jg-dealerships:server:preview-vehicles-data", false, data.source))
end)

RegisterNUICallback("import-vehicles-data", function(data, callback)
  callback(lib.callback.await(
    "jg-dealerships:server:import-vehicles-data",
    false,
    data.source,
    data.behaviour,
    data.stockMethod
  ))
end)
