lib.callback.register("jg-dealerships:server:get-display-vehicles", function(_, dealershipId)
  local displayVehicles = MySQL.query.await(
    "SELECT dispveh.*, vehicle.model, vehicle.brand FROM dealership_dispveh dispveh INNER JOIN dealership_vehicles vehicle ON dispveh.vehicle = vehicle.spawn_code WHERE dealership = ?",
    { dealershipId }
  )

  for _, displayVehicle in ipairs(displayVehicles) do
    displayVehicle.color = json.decode(displayVehicle.color)
  end

  return displayVehicles
end)

lib.callback.register("jg-dealerships:server:create-display-vehicle", function(_, dealershipId, vehicleSpawnCode, color, coords)
  if type(color) == "table" then
    color = json.encode(color) or color
  end

  MySQL.query.await(
    "INSERT INTO dealership_dispveh (dealership,vehicle,color,coords) VALUES(?,?,?,?)",
    { dealershipId, vehicleSpawnCode, color, json.encode(coords) }
  )

  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)
  return true
end)

lib.callback.register("jg-dealerships:server:edit-display-vehicle", function(_, dealershipId, displayVehicleId, vehicleSpawnCode, color)
  if type(color) == "table" then
    color = json.encode(color) or color
  end

  MySQL.query.await(
    "UPDATE dealership_dispveh SET vehicle = ?, color = ? WHERE id = ?",
    { vehicleSpawnCode, color, displayVehicleId }
  )

  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)
  return true
end)

lib.callback.register("jg-dealerships:server:delete-display-vehicle", function(_, dealershipId, displayVehicleId)
  MySQL.query.await("DELETE FROM dealership_dispveh WHERE id = ?", { displayVehicleId })
  TriggerClientEvent("jg-dealerships:client:spawn-display-vehicles", -1, dealershipId)
  return true
end)
