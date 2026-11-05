Locations = Locations or {}
Locations.Server = Locations.Server or {}

local locationsCache = {}

function Locations.Server.ClearCache()
  locationsCache = {}
end

local function normalizeCoordList(coords)
  if not coords then
    return nil
  end

  if coords.x then
    return { coords }
  end

  return coords
end

local function decodeLocation(location)
  if not location or type(location) ~= "table" then
    error("location must be a table")
  end

  location.showroom_coords = json.decode(location.showroom_coords)
  location.management_coords = json.decode(location.management_coords)
  location.dealership_zone = json.decode(location.dealership_zone)

  if location.dealership_zone and not location.dealership_zone.points then
    location.dealership_zone = {
      points = location.dealership_zone,
      height = 10.0,
    }
  end

  location.purchase_vehicle_coords = normalizeCoordList(json.decode(location.purchase_vehicle_coords))
  location.trucking_vehicle_coords = normalizeCoordList(json.decode(location.trucking_vehicle_coords))
  location.categories = json.decode(location.categories)
  location.sell_vehicle_coords = json.decode(location.sell_vehicle_coords)
  location.test_drive_coords = normalizeCoordList(json.decode(location.test_drive_coords))
  location.camera_data = json.decode(location.camera_data)
  location.blip_data = json.decode(location.blip_data)
  location.marker_data = json.decode(location.marker_data)
  location.colour_options = json.decode(location.colour_options)
  location.showroom_job_whitelist = json.decode(location.showroom_job_whitelist)
  location.showroom_gang_whitelist = json.decode(location.showroom_gang_whitelist)
  location.society_purchase_job_whitelist = json.decode(location.society_purchase_job_whitelist)
  location.society_purchase_gang_whitelist = json.decode(location.society_purchase_gang_whitelist)
  location.job_rank_permissions = json.decode(location.job_rank_permissions)
  location.job_rank_mapping = json.decode(location.job_rank_mapping)
  location.payment_methods = json.decode(location.payment_methods) or { "bank", "cash" }

  return location
end

local function getCachedLocations(includeDisabled)
  if includeDisabled then
    return TableValues(locationsCache)
  end

  local activeLocations = {}
  for _, location in pairs(locationsCache) do
    if not location.disabled or location.disabled == 0 then
      activeLocations[#activeLocations + 1] = location
    end
  end

  return activeLocations
end

function Locations.Server.GetAll(includeDisabled)
  if type(locationsCache) == "table" and next(locationsCache) then
    return getCachedLocations(includeDisabled)
  end

  local rows = MySQL.query.await("SELECT * FROM dealership_locations")
  for _, row in ipairs(rows) do
    locationsCache[row.id] = decodeLocation(row)
  end

  return getCachedLocations(includeDisabled)
end

function Locations.Server.GetAllIdAndNameOnly()
  if type(locationsCache) ~= "table" or not next(locationsCache) then
    Locations.Server.GetAll()
  end

  local locations = {}
  for _, location in pairs(locationsCache) do
    locations[#locations + 1] = {
      id = location.id,
      name = location.name,
    }
  end

  return locations
end

function Locations.Server.GetAllPublic(playerSource)
  local locations = MySQL.query.await([[
    SELECT id, name, type, owner_id, job_name,
    dealership_zone, showroom_coords, management_coords,
    purchase_vehicle_coords, enable_sell_vehicle,
    sell_vehicle_coords, sell_vehicle_percent, enable_test_drive,
    test_drive_coords, colour_selection_type, colour_options,
    showroom_job_whitelist, showroom_gang_whitelist
    FROM dealership_locations
    WHERE disabled = 0
  ]])

  local playerJob = Framework.Server.GetPlayerJob(playerSource)
  local playerGang = Framework.Server.GetPlayerGang(playerSource)

  for index, location in ipairs(locations) do
    location.dealership_zone = json.decode(location.dealership_zone or "{}")
    if location.dealership_zone and not location.dealership_zone.points then
      location.dealership_zone = {
        points = location.dealership_zone,
        height = 10.0,
      }
    end

    location.showroom_coords = json.decode(location.showroom_coords or "{}")
    location.management_coords = json.decode(location.management_coords or "{}")
    location.purchase_vehicle_coords = normalizeCoordList(json.decode(location.purchase_vehicle_coords or "{}"))
    location.sell_vehicle_coords = json.decode(location.sell_vehicle_coords or "{}")
    location.test_drive_coords = normalizeCoordList(json.decode(location.test_drive_coords or "{}"))
    location.blip_data = json.decode(location.blip_data or "{}")
    location.colour_options = json.decode(location.colour_options or "{}")
    location.marker_data = json.decode(location.marker_data or "{}")
    location.showroom_job_whitelist = json.decode(location.showroom_job_whitelist or "{}")
    location.showroom_gang_whitelist = json.decode(location.showroom_gang_whitelist or "{}")

    local hasJobWhitelist = location.showroom_job_whitelist and next(location.showroom_job_whitelist)
    local hasGangWhitelist = location.showroom_gang_whitelist and next(location.showroom_gang_whitelist)

    if not hasJobWhitelist and not hasGangWhitelist then
      location.playerCanAccessShowroom = true
    else
      local jobAllowed = hasJobWhitelist
        and CheckJobGangWhitelist(location.showroom_job_whitelist, playerJob.name, playerJob.grade)
        or false
      local gangAllowed = hasGangWhitelist
        and CheckJobGangWhitelist(location.showroom_gang_whitelist, playerGang.name, playerGang.grade)
        or false
      location.playerCanAccessShowroom = jobAllowed or gangAllowed
    end

    if location.type == "owned" then
      location.playerIsEmployee = Employees.Server.IsEmployee(playerSource, location.id, nil, false) and true or false
    else
      location.playerIsEmployee = false
    end

    locations[index].showroom_job_whitelist = nil
    locations[index].showroom_gang_whitelist = nil
  end

  return locations
end

function Locations.Server.GetById(locationId, includeDisabled)
  local cachedLocation = locationsCache[locationId]
  if cachedLocation then
    if not includeDisabled and cachedLocation.disabled == 1 then
      return false
    end

    return cachedLocation
  end

  local location = MySQL.single.await("SELECT * FROM dealership_locations WHERE id = ?", { locationId })
  if not location then
    return false
  end

  locationsCache[location.id] = decodeLocation(location)

  if not includeDisabled and location.disabled == 1 then
    return false
  end

  return locationsCache[location.id]
end

local function encodeLocationField(value)
  return value and json.encode(value)
end

function Locations.Server.Create(locationData)
  local locationId = Utils.Server.GenerateUuid()
  local attemptsRemaining = 10

  while MySQL.scalar.await("SELECT id FROM dealership_locations WHERE id = ?", { locationId }) and attemptsRemaining > 0 do
    DebugPrint("uuid not available, trying again...")
    locationId = Utils.Server.GenerateUuid()
    attemptsRemaining = attemptsRemaining - 1
  end

  MySQL.insert.await([[
    INSERT INTO dealership_locations
    (id, name, type, job_name, job_rank_permissions, job_rank_mapping, dealership_zone, showroom_coords, management_coords, purchase_vehicle_coords,
    trucking_vehicle_coords, categories, enable_finance, enable_sell_vehicle, sell_vehicle_coords,
    sell_vehicle_percent, enable_test_drive, test_drive_coords, camera_data, colour_selection_type,
    colour_options, enable_purchase, showroom_job_whitelist, showroom_gang_whitelist,
    society_purchase_job_whitelist, society_purchase_gang_whitelist, payment_methods)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  ]], {
    locationId,
    locationData.name,
    locationData.type,
    locationData.job_name,
    encodeLocationField(locationData.job_rank_permissions),
    encodeLocationField(locationData.job_rank_mapping),
    encodeLocationField(locationData.dealership_zone),
    encodeLocationField(locationData.showroom_coords),
    encodeLocationField(locationData.management_coords),
    encodeLocationField(locationData.purchase_vehicle_coords),
    encodeLocationField(locationData.trucking_vehicle_coords),
    encodeLocationField(locationData.categories),
    locationData.enable_finance,
    locationData.enable_sell_vehicle,
    encodeLocationField(locationData.sell_vehicle_coords),
    locationData.sell_vehicle_percent,
    locationData.enable_test_drive,
    encodeLocationField(locationData.test_drive_coords),
    encodeLocationField(locationData.camera_data),
    locationData.colour_selection_type,
    encodeLocationField(locationData.colour_options),
    locationData.enable_purchase,
    encodeLocationField(locationData.showroom_job_whitelist),
    encodeLocationField(locationData.showroom_gang_whitelist),
    encodeLocationField(locationData.society_purchase_job_whitelist),
    encodeLocationField(locationData.society_purchase_gang_whitelist),
    json.encode(locationData.payment_methods or { "bank", "cash" }),
  })

  locationData.id = locationId
  locationsCache[locationId] = locationData
  EsxSociety.Server.RegisterSociety(locationData.job_name)

  return Locations.Server.GetAll(false), locationId
end

function Locations.Server.Update(locationId, locationData)
  local previousJobName = locationsCache[locationId] and locationsCache[locationId].job_name

  MySQL.update.await([[
    UPDATE dealership_locations SET name = ?, type = ?, job_name = ?, job_rank_permissions = ?, job_rank_mapping = ?,
    dealership_zone = ?, showroom_coords = ?, management_coords = ?, purchase_vehicle_coords = ?, trucking_vehicle_coords = ?,
    categories = ?, enable_finance = ?,
    enable_sell_vehicle = ?, sell_vehicle_coords = ?, sell_vehicle_percent = ?,
    enable_test_drive = ?, test_drive_coords = ?, camera_data = ?,
    colour_selection_type = ?, colour_options = ?, enable_purchase = ?,
    showroom_job_whitelist = ?, showroom_gang_whitelist = ?,
    society_purchase_job_whitelist = ?, society_purchase_gang_whitelist = ?, payment_methods = ?
    WHERE id = ?
  ]], {
    locationData.name,
    locationData.type,
    locationData.job_name,
    encodeLocationField(locationData.job_rank_permissions),
    encodeLocationField(locationData.job_rank_mapping),
    encodeLocationField(locationData.dealership_zone),
    encodeLocationField(locationData.showroom_coords),
    encodeLocationField(locationData.management_coords),
    encodeLocationField(locationData.purchase_vehicle_coords),
    encodeLocationField(locationData.trucking_vehicle_coords),
    encodeLocationField(locationData.categories),
    locationData.enable_finance,
    locationData.enable_sell_vehicle,
    encodeLocationField(locationData.sell_vehicle_coords),
    locationData.sell_vehicle_percent,
    locationData.enable_test_drive,
    encodeLocationField(locationData.test_drive_coords),
    encodeLocationField(locationData.camera_data),
    locationData.colour_selection_type,
    encodeLocationField(locationData.colour_options),
    locationData.enable_purchase,
    encodeLocationField(locationData.showroom_job_whitelist),
    encodeLocationField(locationData.showroom_gang_whitelist),
    encodeLocationField(locationData.society_purchase_job_whitelist),
    encodeLocationField(locationData.society_purchase_gang_whitelist),
    json.encode(locationData.payment_methods or { "bank", "cash" }),
    locationId,
  })

  locationData.id = locationId
  locationsCache[locationId] = locationData

  if locationData.job_name ~= previousJobName then
    EsxSociety.Server.RegisterSociety(locationData.job_name)
  end

  return Locations.Server.GetAll(false)
end

function Locations.Server.Delete(locationId)
  local coupons = MySQL.query.await("SELECT id FROM dealership_coupons WHERE dealership_id = ?", { locationId })
  for _, coupon in ipairs(coupons or {}) do
    MySQL.query.await("DELETE FROM dealership_coupon_usage WHERE coupon_id = ?", { coupon.id })
  end

  MySQL.query.await("DELETE FROM dealership_coupons WHERE dealership_id = ?", { locationId })
  MySQL.query.await("DELETE FROM dealership_employees WHERE dealership = ?", { locationId })
  MySQL.query.await("DELETE FROM dealership_stock WHERE dealership = ?", { locationId })
  MySQL.query.await("DELETE FROM dealership_locations WHERE id = ?", { locationId })

  locationsCache[locationId] = nil
  return Locations.Server.GetAll(false)
end

function Locations.Server.SetDisabled(locationId, disabled)
  MySQL.update.await("UPDATE dealership_locations SET disabled = ? WHERE id = ?", {
    disabled and 1 or 0,
    locationId,
  })

  local location = MySQL.single.await("SELECT * FROM dealership_locations WHERE id = ?", { locationId })
  if location then
    locationsCache[locationId] = decodeLocation(location)
  end

  return true
end

function Locations.Server.RefreshLocation(locationId)
  local location = MySQL.single.await("SELECT * FROM dealership_locations WHERE id = ?", { locationId })
  if location then
    locationsCache[locationId] = decodeLocation(location)
    return locationsCache[locationId]
  end

  return nil
end

function Locations.Server.SyncStockByCategories(locationId, addedCategories, removedCategories, removeStock)
  local result = {
    added = 0,
    removed = 0,
  }

  if addedCategories and #addedCategories > 0 then
    local addedVehicles = MySQL.query.await([[
      SELECT spawn_code, price FROM dealership_vehicles
      WHERE category IN (?)
    ]], { addedCategories })

    for _, vehicle in ipairs(addedVehicles or {}) do
      local insertId = MySQL.insert.await([[
          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)
          VALUES (?, ?, 0, ?)
        ]], { vehicle.spawn_code, locationId, vehicle.price })

      if insertId then
        result.added = result.added + 1
      end
    end
  end

  if removeStock and removedCategories and #removedCategories > 0 then
    local removedVehicles = MySQL.query.await([[
      SELECT spawn_code FROM dealership_vehicles
      WHERE category IN (?)
    ]], { removedCategories })

    for _, vehicle in ipairs(removedVehicles or {}) do
      local deleteResult = MySQL.query.await([[
          DELETE FROM dealership_stock
          WHERE vehicle = ? AND dealership = ?
        ]], { vehicle.spawn_code, locationId })

      if deleteResult and deleteResult.affectedRows and deleteResult.affectedRows > 0 then
        result.removed = result.removed + deleteResult.affectedRows
      end
    end
  end

  if result.added > 0 or result.removed > 0 then
    Showroom.Server.ClearVehicleCache()
  end

  return result
end

lib.callback.register("jg-dealerships:server:get-all-locations", Locations.Server.GetAllPublic)

exports("getDealerships", function()
  return Locations.Server.GetAll()
end)

exports("getDealership", function(locationId)
  if type(locationId) ~= "string" then
    return false
  end

  return Locations.Server.GetById(locationId)
end)
