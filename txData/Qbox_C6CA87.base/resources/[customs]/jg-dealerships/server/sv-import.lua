Import = Import or {}
Import.Server = Import.Server or {}

local function tableExists(tableName)
  return (MySQL.scalar.await([[
    SELECT COUNT(*) FROM information_schema.tables
    WHERE table_schema = DATABASE() AND table_name = ?
  ]], { tableName }) or 0) > 0
end

local function buildInteractionPoint(coords, radius, blip, marker, hideBlip, hideMarkers)
  local markerSize = marker and marker.size and marker.size.x or 0.3
  local markerColor = {
    r = marker and marker.color and marker.color.r or 255,
    g = marker and marker.color and marker.color.g or 255,
    b = marker and marker.color and marker.color.b or 255,
    a = marker and marker.color and marker.color.a or 120,
  }

  return {
    type = "point",
    coords = {
      {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        w = coords.w or 0.0,
      },
    },
    radius = radius or 5.0,
    enableBlip = not hideBlip and blip ~= nil,
    blipIconId = blip and blip.id or 326,
    blipColourId = blip and blip.color or 2,
    blipSize = blip and blip.scale or 0.6,
    enableMarker = not hideMarkers,
    markerId = marker and marker.id or 21,
    markerSize = markerSize,
    markerColor = markerColor,
    markerBobUpAndDown = marker and (marker.bobUpAndDown == 1 or marker.bobUpAndDown),
    markerFaceCamera = marker and (marker.faceCamera == 1 or marker.faceCamera),
    markerRotate = marker and (marker.rotate == 1 or marker.rotate),
    markerDrawOnEnts = marker and (marker.drawOnEnts == 1 or marker.drawOnEnts),
  }
end

local function createSquareZone(coords, radius)
  local z = coords.z
  return {
    { x = coords.x - radius, y = coords.y - radius, z = z },
    { x = coords.x + radius, y = coords.y - radius, z = z },
    { x = coords.x + radius, y = coords.y + radius, z = z },
    { x = coords.x - radius, y = coords.y + radius, z = z },
  }
end

local function normalizeCoords(coords)
  return {
    x = coords.x,
    y = coords.y,
    z = coords.z,
    w = coords.w,
  }
end

local function buildJobRankMapping(jobName)
  local isValidJob, ranks = Framework.Server.IsValidJob(jobName)
  if not isValidJob or not ranks or #ranks == 0 then
    return nil
  end

  local sortedRanks = {}
  for _, rank in ipairs(ranks) do
    sortedRanks[#sortedRanks + 1] = rank
  end

  table.sort(sortedRanks, function(a, b)
    return a.rank > b.rank
  end)

  local mapping = {}
  local configuredRoles = TableKeys(Config.EmployeePermissions or {}) or { "manager", "supervisor", "sales" }

  for index, role in ipairs(configuredRoles) do
    mapping[role] = sortedRanks[index] and sortedRanks[index].rank or sortedRanks[#sortedRanks].rank
  end

  return mapping
end

local function normalizeColourOptions(useRgb, options)
  local normalized = {}
  local errors = {}

  if not options or type(options) ~= "table" then
    return normalized, errors
  end

  for index, option in ipairs(options) do
    local optionId = tostring(index) .. "-" .. (option.label or "Unknown")
    local color

    if useRgb then
      if option.hex then
        local ok, r, g, b = pcall(lib.math.hextorgb, option.hex)
        if ok and r and g and b then
          color = { r = r, g = g, b = b }
        else
          errors[#errors + 1] = ("Failed to convert hex '%s' for colour option '%s'"):format(option.hex or "nil", option.label or "Unknown")
        end
      else
        errors[#errors + 1] = ("Missing hex value for colour option '%s'"):format(option.label or "Unknown")
      end
    elseif option.index then
      color = option.index
    else
      errors[#errors + 1] = ("Missing index value for colour option '%s'"):format(option.label or "Unknown")
    end

    if color then
      normalized[#normalized + 1] = {
        id = optionId,
        color = color,
      }
    end
  end

  return normalized, errors
end

local function normalizeCameraData(camera)
  if not camera then
    return {
      preset = "Car",
      coords = { x = 0, y = 0, z = 0, w = 0 },
      zoomLevels = { "5", "8", "12", "8" },
    }
  end

  local zoomLevels = {}
  if camera.positions then
    for _, position in ipairs(camera.positions) do
      zoomLevels[#zoomLevels + 1] = tostring(position)
    end
  else
    zoomLevels = { "5", "8", "12", "8" }
  end

  return {
    preset = camera.name or "Car",
    coords = {
      x = camera.coords and camera.coords.x or 0,
      y = camera.coords and camera.coords.y or 0,
      z = camera.coords and camera.coords.z or 0,
      w = camera.coords and camera.coords.w or 0,
    },
    zoomLevels = zoomLevels,
  }
end

local function convertV1Location(locationId, locationConfig, legacyData)
  local errors = {}
  local converted = {
    id = locationId,
    name = (locationConfig and locationConfig.label and locationConfig.label ~= "" and locationConfig.label)
      or (legacyData and legacyData.label and legacyData.label ~= "" and legacyData.label)
      or locationId,
    type = locationConfig.type == "owned" and "owned" or "selfService",
  }

  if locationConfig.type ~= "owned" and locationConfig.type ~= "self-service" then
    errors[#errors + 1] = ("Unknown type '%s', defaulting to 'selfService'"):format(tostring(locationConfig.type))
  end

  if converted.type == "owned" and locationConfig.job then
    local validJob = Framework.Server.IsValidJob(locationConfig.job)
    if validJob then
      converted.job_name = locationConfig.job
      converted.job_rank_mapping = buildJobRankMapping(locationConfig.job)
      if not converted.job_rank_mapping then
        errors[#errors + 1] = ("Job '%s' is valid but could not build rank mapping"):format(locationConfig.job)
      end
    else
      errors[#errors + 1] = ("Invalid job '%s', skipping job configuration"):format(locationConfig.job)
    end
  end

  converted.job_rank_permissions = nil
  converted.balance = legacyData and legacyData.balance or 0
  converted.owner_id = legacyData and legacyData.owner_id or nil
  converted.owner_name = legacyData and legacyData.owner_name or nil
  converted.employee_commission = legacyData and legacyData.employee_commission or 10

  if locationConfig.zone and type(locationConfig.zone) == "table" and #locationConfig.zone >= 3 then
    converted.dealership_zone = {}
    for _, point in ipairs(locationConfig.zone) do
      converted.dealership_zone[#converted.dealership_zone + 1] = {
        x = point.x,
        y = point.y,
        z = point.z,
      }
    end
  elseif locationConfig.openShowroom and locationConfig.openShowroom.coords then
    converted.dealership_zone = createSquareZone(locationConfig.openShowroom.coords, locationConfig.directSaleDistance or 50.0)
  else
    errors[#errors + 1] = "Missing zone or openShowroom.coords, cannot generate dealership_zone"
  end

  if locationConfig.openShowroom and locationConfig.openShowroom.coords then
    converted.showroom_coords = {
      buildInteractionPoint(
        locationConfig.openShowroom.coords,
        locationConfig.openShowroom.size or 5,
        locationConfig.blip,
        locationConfig.markers,
        locationConfig.hideBlip,
        locationConfig.hideMarkers
      ),
    }
  else
    errors[#errors + 1] = "Missing openShowroom configuration (required)"
  end

  if locationConfig.openManagement and locationConfig.openManagement.coords then
    converted.management_coords = {
      buildInteractionPoint(
        locationConfig.openManagement.coords,
        locationConfig.openManagement.size or 5,
        locationConfig.blip,
        locationConfig.markers,
        locationConfig.hideBlip,
        locationConfig.hideMarkers
      ),
    }
  end

  if locationConfig.purchaseSpawn then
    converted.purchase_vehicle_coords = normalizeCoords(locationConfig.purchaseSpawn)
    converted.trucking_vehicle_coords = normalizeCoords(locationConfig.purchaseSpawn)
  else
    errors[#errors + 1] = "Missing purchaseSpawn configuration (required)"
  end

  converted.enable_finance = locationConfig.enableFinance == true
  converted.enable_sell_vehicle = locationConfig.enableSellVehicle == true

  if locationConfig.sellVehicle and locationConfig.sellVehicle.coords then
    converted.sell_vehicle_coords = {
      buildInteractionPoint(
        locationConfig.sellVehicle.coords,
        locationConfig.sellVehicle.size or 5,
        locationConfig.blip,
        locationConfig.markers,
        locationConfig.hideBlip,
        locationConfig.hideMarkers
      ),
    }
  end

  converted.sell_vehicle_percent = locationConfig.sellVehiclePercent and math.floor(locationConfig.sellVehiclePercent * 100) or 60
  converted.enable_test_drive = locationConfig.enableTestDrive == true

  if locationConfig.testDriveSpawn then
    converted.test_drive_coords = normalizeCoords(locationConfig.testDriveSpawn)
  end

  if locationConfig.categories and type(locationConfig.categories) == "table" and #locationConfig.categories > 0 then
    converted.categories = locationConfig.categories
  else
    errors[#errors + 1] = "Missing or empty categories configuration (required)"
  end

  converted.camera_data = normalizeCameraData(locationConfig.camera)
  converted.colour_selection_type = "RGB"

  if Config.VehicleColourOptions and #Config.VehicleColourOptions > 0 then
    local useRgb = Config.UseRGBColors == true
    converted.colour_selection_type = useRgb and "RGBOPT" or "IDOPT"
    local colourErrors
    converted.colour_options, colourErrors = normalizeColourOptions(useRgb, Config.VehicleColourOptions)
    for _, errorMessage in ipairs(colourErrors) do
      errors[#errors + 1] = errorMessage
    end
  end

  converted.enable_purchase = locationConfig.disableShowroomPurchase ~= true

  if type(locationConfig.showroomJobWhitelist) == "table" then
    converted.showroom_job_whitelist = locationConfig.showroomJobWhitelist
  end
  if type(locationConfig.showroomGangWhitelist) == "table" then
    converted.showroom_gang_whitelist = locationConfig.showroomGangWhitelist
  end
  if type(locationConfig.societyPurchaseJobWhitelist) == "table" then
    converted.society_purchase_job_whitelist = locationConfig.societyPurchaseJobWhitelist
  end
  if type(locationConfig.societyPurchaseGangWhitelist) == "table" then
    converted.society_purchase_gang_whitelist = locationConfig.societyPurchaseGangWhitelist
  end

  return {
    data = converted,
    errors = errors,
  }
end

local function locationExists(locationId)
  return (MySQL.scalar.await("SELECT COUNT(*) FROM dealership_locations WHERE id = ?", { locationId }) or 0) > 0
end

local function insertConvertedLocation(location)
  local success, errorMessage = pcall(function()
    MySQL.insert.await([[
      INSERT INTO dealership_locations (
        id, name, type, job_name, job_rank_permissions, job_rank_mapping,
        balance, owner_id, owner_name, employee_commission,
        dealership_zone, showroom_coords, management_coords,
        purchase_vehicle_coords, trucking_vehicle_coords,
        enable_finance, enable_sell_vehicle, sell_vehicle_coords, sell_vehicle_percent,
        enable_test_drive, test_drive_coords, categories, camera_data,
        colour_selection_type, colour_options, enable_purchase,
        showroom_job_whitelist, showroom_gang_whitelist,
        society_purchase_job_whitelist, society_purchase_gang_whitelist
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ]], {
      location.id,
      location.name,
      location.type,
      location.job_name,
      location.job_rank_permissions and json.encode(location.job_rank_permissions) or nil,
      location.job_rank_mapping and json.encode(location.job_rank_mapping) or nil,
      location.balance or 0,
      location.owner_id,
      location.owner_name,
      location.employee_commission or 10,
      location.dealership_zone and json.encode(location.dealership_zone) or nil,
      json.encode(location.showroom_coords),
      location.management_coords and json.encode(location.management_coords) or nil,
      json.encode(location.purchase_vehicle_coords),
      location.trucking_vehicle_coords and json.encode(location.trucking_vehicle_coords) or nil,
      location.enable_finance and 1 or 0,
      location.enable_sell_vehicle and 1 or 0,
      location.sell_vehicle_coords and json.encode(location.sell_vehicle_coords) or nil,
      location.sell_vehicle_percent,
      location.enable_test_drive and 1 or 0,
      location.test_drive_coords and json.encode(location.test_drive_coords) or nil,
      json.encode(location.categories),
      json.encode(location.camera_data),
      location.colour_selection_type,
      location.colour_options and json.encode(location.colour_options) or nil,
      location.enable_purchase and 1 or 0,
      location.showroom_job_whitelist and json.encode(location.showroom_job_whitelist) or nil,
      location.showroom_gang_whitelist and json.encode(location.showroom_gang_whitelist) or nil,
      location.society_purchase_job_whitelist and json.encode(location.society_purchase_job_whitelist) or nil,
      location.society_purchase_gang_whitelist and json.encode(location.society_purchase_gang_whitelist) or nil,
    })
  end)

  return success, success and nil or tostring(errorMessage)
end

function Import.Server.ImportV1Locations(locations)
  locations = locations or Config.DealershipLocations

  local result = {
    success = true,
    imported = {},
    skipped = {},
    errors = {},
  }

  if not tableExists("dealership_locations") then
    result.success = false
    result.errors._global = { "Database table 'dealership_locations' does not exist. Please run the v2 migration SQL first." }
    return result
  end

  if not locations or type(locations) ~= "table" then
    result.success = false
    result.errors._global = { "No locations provided and Config.DealershipLocations is not a valid table." }
    return result
  end

  local legacyData = {}
  if tableExists("dealership_data") then
    for _, row in ipairs(MySQL.query.await("SELECT * FROM dealership_data") or {}) do
      legacyData[row.name] = row
    end
  end

  local convertedLocations = {}
  local hasBlockingErrors = false

  for locationId, locationConfig in pairs(locations) do
    if locationExists(locationId) then
      result.skipped[#result.skipped + 1] = locationId
    else
      local converted = convertV1Location(locationId, locationConfig, legacyData[locationId])
      convertedLocations[locationId] = converted

      local blockingErrors = {}
      for _, errorMessage in ipairs(converted.errors) do
        if errorMessage:find("%(required%)") then
          blockingErrors[#blockingErrors + 1] = errorMessage
          hasBlockingErrors = true
        end
      end

      if #converted.errors > 0 then
        result.errors[locationId] = converted.errors
      end
    end
  end

  if hasBlockingErrors then
    result.success = false
    result.errors._global = result.errors._global or {}
    result.errors._global[#result.errors._global + 1] = "Blocking errors found. Fix the issues above before importing."
    return result
  end

  for locationId, converted in pairs(convertedLocations) do
    local success, errorMessage = insertConvertedLocation(converted.data)
    if success then
      result.imported[#result.imported + 1] = locationId
    else
      result.success = false
      result.errors[locationId] = result.errors[locationId] or {}
      result.errors[locationId][#result.errors[locationId] + 1] = "Database insert failed: " .. (errorMessage or "Unknown error")
    end
  end

  if #result.imported > 0 then
    TriggerClientEvent("jg-dealerships:client:create-dealership-locations", -1, nil, true)
  end

  return result
end

lib.callback.register("jg-dealerships:server:import-v1-locations", function(playerSource, data)
  if not Framework.Server.IsAdmin(playerSource) then
    Framework.Server.Notify(playerSource, Locale.insufficientPermissions, "error")
    DebugPrint("Player " .. playerSource .. " tried to import locations without permission", "warning")
    return {
      success = false,
      imported = {},
      skipped = {},
      errors = { _global = { "Insufficient permissions" } },
    }
  end

  local sourceLocations = data.source == "default" and DEFAULT_LOCATIONS or Config.DealershipLocations
  local result = Import.Server.ImportV1Locations(sourceLocations)

  if result.success and #result.imported > 0 and data.syncStock then
    local addedStock = 0
    for _, locationId in ipairs(result.imported) do
      local location = Locations.Server.GetById(locationId, true)
      if location and location.categories and #location.categories > 0 then
        addedStock = addedStock + Locations.Server.SyncStockByCategories(locationId, location.categories, {}, false).added
      end
    end

    if addedStock > 0 then
      Framework.Server.Notify(playerSource, ("Stock sync: %d vehicles added"):format(addedStock), "success")
    end
  end

  if result.success and #result.imported > 0 then
    SendWebhook(playerSource, Webhooks.Admin, "Admin: Imported Locations", "success", {
      { key = "Source", value = data.source == "default" and "Default Locations" or "Config.lua" },
      { key = "Imported", value = table.concat(result.imported, ", ") },
      { key = "Skipped", value = #result.skipped > 0 and table.concat(result.skipped, ", ") or "None" },
      { key = "Stock Sync", value = data.syncStock and "Yes" or "No" },
    })
  end

  return result
end)

local function clearVehicleData()
  MySQL.query.await("DELETE FROM dealership_dispveh")
  MySQL.query.await("DELETE FROM dealership_orders")
  MySQL.query.await("DELETE FROM dealership_sales")
  MySQL.query.await("DELETE FROM dealership_stock")
  MySQL.query.await("DELETE FROM dealership_vehicles")
end

local function getExistingVehicles()
  local existing = {}
  for _, row in ipairs(MySQL.query.await("SELECT spawn_code FROM dealership_vehicles") or {}) do
    existing[row.spawn_code] = true
  end
  return existing
end

local function getCategoriesByLocation()
  local categoriesByLocation = {}
  for _, location in ipairs(Locations.Server.GetAll(true)) do
    categoriesByLocation[location.id] = location.categories or {}
  end
  return categoriesByLocation
end

local function categoryAllowed(categories, category)
  if not categories or #categories == 0 then
    return true
  end

  for _, allowedCategory in ipairs(categories) do
    if allowedCategory == category then
      return true
    end
  end

  return false
end

local function getQbSharedVehicles()
  if Config.Framework ~= "QBCore" then
    return nil, false
  end

  local vehicles = QBCore and QBCore.Shared and QBCore.Shared.Vehicles
  if not vehicles then
    return nil, false
  end

  for _, vehicle in pairs(vehicles) do
    if vehicle.shop then
      return vehicles, true
    end
  end

  return vehicles, false
end

local function getQboxSharedVehicles()
  if Config.Framework ~= "Qbox" then
    return nil, false
  end

  local ok, vehicles = pcall(function()
    return exports.qbx_core:GetVehiclesByHash()
  end)

  if not ok or not vehicles then
    return nil, false
  end

  for _, vehicle in pairs(vehicles) do
    if vehicle.shop then
      return vehicles, true
    end
  end

  return vehicles, false
end

local function getEsxVehicles()
  if Config.Framework ~= "ESX" then
    return nil, false
  end

  local vehicles = MySQL.query.await("SELECT * FROM vehicles ORDER BY name DESC")
  if not vehicles then
    return nil, false
  end

  return vehicles, false
end

function Import.Server.PreviewVehiclesData(source)
  local vehicles
  local hasShopData

  if source == "qbshared" then
    vehicles, hasShopData = getQbSharedVehicles()
    if not vehicles then
      return {
        available = false,
        count = 0,
        hasShopData = false,
        error = "QBCore.Shared.Vehicles not available (wrong framework or not loaded)",
      }
    end
  elseif source == "qbx_shared" then
    vehicles, hasShopData = getQboxSharedVehicles()
    if not vehicles then
      return {
        available = false,
        count = 0,
        hasShopData = false,
        error = "exports.qbx_core:GetVehiclesByHash() not available (wrong framework or not loaded)",
      }
    end
  elseif source == "esxdb" then
    vehicles, hasShopData = getEsxVehicles()
    if not vehicles then
      return {
        available = false,
        count = 0,
        hasShopData = false,
        error = "ESX vehicles table not found or empty",
      }
    end
  else
    return {
      available = false,
      count = 0,
      hasShopData = false,
      error = "Unknown import source",
    }
  end

  local count = 0
  for _ in pairs(vehicles) do
    count = count + 1
  end

  return {
    available = true,
    count = count,
    hasShopData = hasShopData,
  }
end

local function insertVehicle(spawnCode, hashKey, brand, model, category, price, shopData, categoriesByLocation, mappingMode)
  MySQL.query.await([[
    INSERT IGNORE INTO dealership_vehicles (spawn_code, hashkey, brand, model, category, price)
    VALUES(?, ?, ?, ?, ?, ?)
  ]], { spawnCode, hashKey, brand, model, category, price })

  if mappingMode == "byShop" and shopData then
    local shopLookup = {}

    if type(shopData) == "string" then
      shopLookup[shopData] = true
    elseif type(shopData) == "table" then
      for _, shop in ipairs(shopData) do
        shopLookup[shop] = true
      end
    end

    for shop in pairs(shopLookup) do
      if categoriesByLocation[shop] then
        MySQL.query.await([[
          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)
          VALUES(?, ?, ?, ?)
        ]], { spawnCode, shop, 0, price })
      end
    end
  else
    for locationId, categories in pairs(categoriesByLocation) do
      if categoryAllowed(categories, category) then
        MySQL.query.await([[
          INSERT IGNORE INTO dealership_stock (vehicle, dealership, stock, price)
          VALUES(?, ?, ?, ?)
        ]], { spawnCode, locationId, 0, price })
      end
    end
  end
end

local function importQbShared(mode, mappingMode)
  local vehicles = getQbSharedVehicles()
  if not vehicles then
    return { success = false, count = 0, imported = 0, error = "QBCore.Shared.Vehicles not found" }
  end

  if mode == "Overwrite" then
    clearVehicleData()
  end

  local existingVehicles = mode == "Append" and getExistingVehicles() or {}
  local categoriesByLocation = getCategoriesByLocation()
  local imported = 0

  for spawnCode, vehicle in pairs(vehicles) do
    local normalizedSpawnCode = Trim(spawnCode)
    if not (mode == "Append" and existingVehicles[normalizedSpawnCode]) then
      insertVehicle(normalizedSpawnCode, joaat(spawnCode), vehicle.brand, vehicle.name, vehicle.category, vehicle.price, vehicle.shop, categoriesByLocation, mappingMode)
      imported = imported + 1
    end
  end

  Showroom.Server.ClearVehicleCache()
  return {
    success = true,
    count = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0,
    imported = imported,
  }
end

local function importQboxShared(mode, mappingMode)
  local vehicles = getQboxSharedVehicles()
  if not vehicles then
    return { success = false, count = 0, imported = 0, error = "exports.qbx_core:GetVehiclesByHash() returned nil" }
  end

  if mode == "Overwrite" then
    clearVehicleData()
  end

  local existingVehicles = mode == "Append" and getExistingVehicles() or {}
  local categoriesByLocation = getCategoriesByLocation()
  local imported = 0

  for hashKey, vehicle in pairs(vehicles) do
    local spawnCode = Trim(vehicle.model)
    if not (mode == "Append" and existingVehicles[spawnCode]) then
      insertVehicle(spawnCode, hashKey, vehicle.brand, vehicle.name, vehicle.category, vehicle.price, vehicle.shop, categoriesByLocation, mappingMode)
      imported = imported + 1
    end
  end

  Showroom.Server.ClearVehicleCache()
  return {
    success = true,
    count = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0,
    imported = imported,
  }
end

local function importEsxVehicles(mode)
  local vehicles = getEsxVehicles()
  if not vehicles then
    return { success = false, count = 0, imported = 0, error = "Could not query ESX vehicles table" }
  end

  if mode == "Overwrite" then
    clearVehicleData()
  end

  local existingVehicles = mode == "Append" and getExistingVehicles() or {}
  local categoriesByLocation = getCategoriesByLocation()
  local imported = 0

  for _, vehicle in pairs(vehicles) do
    local spawnCode = Trim(vehicle.model)
    if not (mode == "Append" and existingVehicles[spawnCode]) then
      insertVehicle(spawnCode, joaat(vehicle.model), nil, vehicle.name, vehicle.category, vehicle.price, nil, categoriesByLocation, "byCategory")
      imported = imported + 1
    end
  end

  Showroom.Server.ClearVehicleCache()
  return {
    success = true,
    count = MySQL.scalar.await("SELECT COUNT(*) FROM dealership_vehicles") or 0,
    imported = imported,
  }
end

function Import.Server.ImportVehiclesData(source, mode, mappingMode)
  mode = mode or "Append"
  mappingMode = mappingMode or "byCategory"

  if source == "qbshared" then
    return importQbShared(mode, mappingMode)
  elseif source == "qbx_shared" then
    return importQboxShared(mode, mappingMode)
  elseif source == "esxdb" then
    return importEsxVehicles(mode)
  end

  return {
    success = false,
    count = 0,
    imported = 0,
    error = "UNSUPPORTED_SOURCE",
  }
end

lib.callback.register("jg-dealerships:server:preview-vehicles-data", function(playerSource, source)
  if not Framework.Server.IsAdmin(playerSource) then
    return {
      available = false,
      count = 0,
      hasShopData = false,
      error = "INSUFFICIENT_PERMISSIONS",
    }
  end

  return Import.Server.PreviewVehiclesData(source)
end)

lib.callback.register("jg-dealerships:server:import-vehicles-data", function(playerSource, source, mode, mappingMode)
  if not Framework.Server.IsAdmin(playerSource) then
    Framework.Server.Notify(playerSource, Locale.insufficientPermissions, "error")
    DebugPrint("Player " .. playerSource .. " tried to import vehicles without permission", "warning")
    return {
      success = false,
      count = 0,
      error = "INSUFFICIENT_PERMISSIONS",
    }
  end

  local result = Import.Server.ImportVehiclesData(source, mode, mappingMode)
  if result.success then
    Framework.Server.Notify(
      playerSource,
      ("Import successful! %d vehicles imported (%d total)"):format(result.imported or 0, result.count or 0),
      "success"
    )

    SendWebhook(playerSource, Webhooks.Admin, "Admin: Imported Vehicles", "success", {
      { key = "Source", value = source },
      { key = "Mode", value = mode },
      { key = "Mapping", value = mappingMode },
      { key = "Imported", value = result.imported or 0 },
      { key = "Total", value = result.count or 0 },
    })
  else
    Framework.Server.Notify(playerSource, result.error or "Vehicle import failed", "error")
  end

  return result
end)

