local function broadcastLocationAdded(location)
  TriggerClientEvent("jg-dealerships:client:add-location", -1, location)
end

local function broadcastLocationUpdated(location)
  TriggerClientEvent("jg-dealerships:client:update-location", -1, location)
end

local function broadcastLocationDeleted(locationId)
  TriggerClientEvent("jg-dealerships:client:delete-location", -1, locationId)
end

local function rejectAdminAction(playerSource, debugMessage)
  Framework.Server.Notify(playerSource, Locale.insufficientPermissions, "error")
  DebugPrint(("Player %s %s"):format(playerSource, debugMessage), "warning")
  return { error = true }
end

lib.callback.register("jg-dealerships:server:fetch-all-locations-admin", function(playerSource)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to create a new dealership location without permission")
  end

  Locations.Server.ClearCache()
  return Locations.Server.GetAll(true)
end)

lib.callback.register("jg-dealerships:server:toggle-location-disabled", function(playerSource, locationData)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to toggle location disabled without permission")
  end

  Locations.Server.SetDisabled(locationData.id, locationData.disabled)

  if locationData.disabled then
    broadcastLocationDeleted(locationData.id)
  else
    local location = Locations.Server.GetById(locationData.id, false)
    if location then
      broadcastLocationAdded(location)
    end
  end

  return true
end)

lib.callback.register("jg-dealerships:server:create-location", function(playerSource, locationData)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to create a new dealership location without permission")
  end

  local stockSync = locationData.stockSync
  locationData.stockSync = nil

  local _, locationId = Locations.Server.Create(locationData)

  if stockSync and locationId then
    local syncResult = Locations.Server.SyncStockByCategories(
      locationId,
      stockSync.addedCategories or {},
      stockSync.removedCategories or {},
      stockSync.removeStock or false
    )

    if syncResult.added > 0 or syncResult.removed > 0 then
      Framework.Server.Notify(
        playerSource,
        ("Stock sync: %d added, %d removed"):format(syncResult.added, syncResult.removed),
        "success"
      )
    end
  end

  local location = Locations.Server.GetById(locationId, false)
  if location then
    broadcastLocationAdded(location)
  end

  return locationId
end)

lib.callback.register("jg-dealerships:server:update-location", function(playerSource, payload)
  local locationId = payload.id
  local locationData = payload.data
  local stockSync = payload.stockSync

  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to update a dealership location without permission")
  end

  Locations.Server.Update(locationId, locationData)

  if stockSync and locationId then
    local syncResult = Locations.Server.SyncStockByCategories(
      locationId,
      stockSync.addedCategories or {},
      stockSync.removedCategories or {},
      stockSync.removeStock or false
    )

    if syncResult.added > 0 or syncResult.removed > 0 then
      Framework.Server.Notify(
        playerSource,
        ("Stock sync: %d added, %d removed"):format(syncResult.added, syncResult.removed),
        "success"
      )
    end
  end

  local location = Locations.Server.GetById(locationId, false)
  if location then
    broadcastLocationUpdated(location)
  end

  return true
end)

lib.callback.register("jg-dealerships:server:delete-location", function(playerSource, locationId)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to delete a dealership location without permission")
  end

  Locations.Server.Delete(locationId)
  broadcastLocationDeleted(locationId)
  return true
end)

lib.callback.register("jg-dealerships:server:fetch-all-vehicles-admin", function(playerSource)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to get admin data without permission")
  end

  return {
    vehicles = Vehicles.Server.GetAll(),
    locations = Locations.Server.GetAllIdAndNameOnly(),
  }
end)

lib.callback.register("jg-dealerships:server:add-vehicle", function(playerSource, vehicleData)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to add a vehicle without permission")
  end

  if not Vehicles.Server.Create(vehicleData) then
    return { error = true }
  end

  SendWebhook(playerSource, Webhooks.Admin, "Admin: Add Vehicle", "success", {
    { key = "Vehicle", value = vehicleData.spawn_code },
    { key = "Name", value = vehicleData.brand .. " " .. vehicleData.model },
    { key = "Category", value = vehicleData.category },
    { key = "Price", value = vehicleData.price },
    { key = "Dealerships", value = #vehicleData.locations .. " dealership(s)" },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:update-vehicle", function(playerSource, vehicleData, updateLocationPrices)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to update a vehicle without permission")
  end

  if not Vehicles.Server.Update(vehicleData.spawn_code, vehicleData, updateLocationPrices) then
    return { error = true }
  end

  SendWebhook(playerSource, Webhooks.Admin, "Admin: Vehicle Updated", nil, {
    { key = "Vehicle", value = vehicleData.spawn_code },
    { key = "Name", value = vehicleData.brand .. " " .. vehicleData.model },
    { key = "Category", value = vehicleData.category },
    { key = "Price", value = vehicleData.price },
    { key = "Dealerships", value = #vehicleData.locations .. " dealership(s)" },
  })

  return true
end)

lib.callback.register("jg-dealerships:server:delete-vehicle", function(playerSource, spawnCode)
  if not Framework.Server.IsAdmin(playerSource) then
    return rejectAdminAction(playerSource, "tried to delete a vehicle without permission")
  end

  if not Vehicles.Server.Delete(spawnCode) then
    return { error = true }
  end

  SendWebhook(playerSource, Webhooks.Admin, "Admin: Vehicle Deleted", "danger", {
    { key = "Vehicle", value = spawnCode },
  })

  return true
end)
