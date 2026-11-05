Showroom = Showroom or {}
Showroom.Server = Showroom.Server or {}

local showroomSessions = {}
local vehicleCacheByDealership = {}

function Showroom.Server.ClearVehicleCache()
  vehicleCacheByDealership = {}
end

function Showroom.Server.GetVehicles(dealershipId, forceRefresh)
  if vehicleCacheByDealership[dealershipId] and not forceRefresh then
    return TableValues(vehicleCacheByDealership[dealershipId])
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  if not dealership.categories or #dealership.categories == 0 then
    vehicleCacheByDealership[dealershipId] = {}
  end

  local vehicles = MySQL.query.await([[
      SELECT vehicle.*, stock.stock as stock, stock.price as price FROM dealership_vehicles vehicle
      INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle
      INNER JOIN dealership_locations dealership ON stock.dealership = dealership.id
      WHERE vehicle.category IN (?) AND (dealership.id = ?)
      ORDER BY vehicle.spawn_code ASC
    ]], { dealership.categories, dealershipId })

  vehicleCacheByDealership[dealershipId] = {}

  for _, vehicle in ipairs(vehicles) do
    vehicleCacheByDealership[dealershipId][vehicle.spawn_code] = vehicle
  end

  return TableValues(vehicleCacheByDealership[dealershipId])
end

function Showroom.Server.GetVehicle(dealershipId, spawnCode, forceRefresh)
  if not dealershipId or not spawnCode then
    return false
  end

  if vehicleCacheByDealership[dealershipId]
    and vehicleCacheByDealership[dealershipId][spawnCode]
    and not forceRefresh
  then
    return vehicleCacheByDealership[dealershipId][spawnCode]
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  if not dealership.categories or #dealership.categories == 0 then
    return false
  end

  local vehicle = MySQL.single.await([[
      SELECT vehicle.*, stock.stock as stock, stock.price as price FROM dealership_vehicles vehicle
      INNER JOIN dealership_stock stock ON vehicle.spawn_code = stock.vehicle
      INNER JOIN dealership_locations dealership ON stock.dealership = dealership.id
      WHERE vehicle.spawn_code = ? AND dealership.id = ?
      ORDER BY vehicle.spawn_code ASC
    ]], { spawnCode, dealershipId })

  if vehicleCacheByDealership[dealershipId] then
    vehicleCacheByDealership[dealershipId][spawnCode] = vehicle or nil
  end

  return vehicle or false
end

function Showroom.Server.UpdateVehicleCache(spawnCode, dealershipId)
  if not dealershipId then
    for cachedDealershipId in pairs(vehicleCacheByDealership) do
      Showroom.Server.GetVehicle(cachedDealershipId, spawnCode, true)
    end
  else
    Showroom.Server.GetVehicle(dealershipId, spawnCode, true)
  end
end

local function enterShowroom(playerSource, dealershipId, originalCoords)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    DebugPrint("jg-dealerships:server:enter-showroom: no identifier found for player " .. playerSource, "warning")
    return false
  end

  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    return false
  end

  local playerJob = Framework.Server.GetPlayerJob(playerSource)
  local playerGang = Framework.Server.GetPlayerGang(playerSource)
  local hasShowroomJobWhitelist = dealership.showroom_job_whitelist and next(dealership.showroom_job_whitelist)
  local hasShowroomGangWhitelist = dealership.showroom_gang_whitelist and next(dealership.showroom_gang_whitelist)

  if hasShowroomJobWhitelist or hasShowroomGangWhitelist then
    local jobAllowed = hasShowroomJobWhitelist
      and CheckJobGangWhitelist(dealership.showroom_job_whitelist, playerJob.name, playerJob.grade)
      or false
    local gangAllowed = hasShowroomGangWhitelist
      and CheckJobGangWhitelist(dealership.showroom_gang_whitelist, playerGang.name, playerGang.grade)
      or false

    if not jobAllowed and not gangAllowed then
      DebugPrint("jg-dealerships:server:enter-showroom: player " .. playerSource .. " not allowed in showroom", "debug")
      return false
    end
  end

  local societies = {}
  local hasSocietyJobWhitelist = dealership.society_purchase_job_whitelist and next(dealership.society_purchase_job_whitelist)
  local hasSocietyGangWhitelist = dealership.society_purchase_gang_whitelist and next(dealership.society_purchase_gang_whitelist)

  if hasSocietyJobWhitelist and playerJob.name
    and CheckJobGangWhitelist(dealership.society_purchase_job_whitelist, playerJob.name, playerJob.grade)
  then
    societies[#societies + 1] = {
      name = playerJob.name,
      label = playerJob.label or playerJob.name,
      type = "job",
      balance = Framework.Server.GetSocietyBalance(playerJob.name, "job"),
    }
  end

  if hasSocietyGangWhitelist and playerGang.name
    and CheckJobGangWhitelist(dealership.society_purchase_gang_whitelist, playerGang.name, playerGang.grade)
  then
    societies[#societies + 1] = {
      name = playerGang.name,
      label = playerGang.label or playerGang.name,
      type = "gang",
      balance = Framework.Server.GetSocietyBalance(playerGang.name, "gang"),
    }
  end

  local originalBucket = 0
  if Config.ReturnToPreviousRoutingBucket then
    originalBucket = GetPlayerRoutingBucket(playerSource)
  end

  showroomSessions[playerIdentifier] = {
    dealership = dealershipId,
    originalBucket = originalBucket,
    originalCoords = originalCoords,
  }

  local playerPed = GetPlayerPed(playerSource)
  ClearPedTasksImmediately(playerPed)
  FreezeEntityPosition(playerPed, true)

  local financedVehicleCount = MySQL.scalar.await(([[
      SELECT COUNT(*) as total FROM %s
      WHERE financed = 1 AND %s = ?
    ]]):format(Framework.VehiclesTable, Framework.PlayerId), { playerIdentifier })

  return {
    vehicles = Showroom.Server.GetVehicles(dealershipId),
    financeAllowed = financedVehicleCount < (Config.MaxFinancedVehiclesPerPlayer or 999999),
    locationData = dealership,
    societies = societies,
  }
end

lib.callback.register("jg-dealerships:server:enter-showroom", enterShowroom)

lib.callback.register("jg-dealerships:server:check-showroom-whitelist", function(playerSource, dealershipId)
  local dealership = Locations.Server.GetById(dealershipId)
  if not dealership then
    DebugPrint("[ShowroomWhitelist] Location not found: " .. tostring(dealershipId) .. " - returning true", "debug")
    return true
  end

  local playerJob = Framework.Server.GetPlayerJob(playerSource)
  local playerGang = Framework.Server.GetPlayerGang(playerSource)
  local hasJobWhitelist = dealership.showroom_job_whitelist and next(dealership.showroom_job_whitelist)
  local hasGangWhitelist = dealership.showroom_gang_whitelist and next(dealership.showroom_gang_whitelist)

  DebugPrint("[ShowroomWhitelist] Checking access for player " .. playerSource .. " at " .. dealershipId, "debug")
  DebugPrint("[ShowroomWhitelist] Player job: " .. tostring(playerJob.name) .. " grade: " .. tostring(playerJob.grade), "debug")
  DebugPrint("[ShowroomWhitelist] Player gang: " .. tostring(playerGang.name) .. " grade: " .. tostring(playerGang.grade), "debug")
  DebugPrint("[ShowroomWhitelist] Job whitelist: " .. json.encode(dealership.showroom_job_whitelist or {}), "debug")
  DebugPrint("[ShowroomWhitelist] Gang whitelist: " .. json.encode(dealership.showroom_gang_whitelist or {}), "debug")
  DebugPrint("[ShowroomWhitelist] Has job whitelist: " .. tostring(hasJobWhitelist) .. ", Has gang whitelist: " .. tostring(hasGangWhitelist), "debug")

  if not hasJobWhitelist and not hasGangWhitelist then
    DebugPrint("[ShowroomWhitelist] No whitelists set - allowing access", "debug")
    return true
  end

  local jobAllowed = hasJobWhitelist
    and CheckJobGangWhitelist(dealership.showroom_job_whitelist, playerJob.name, playerJob.grade)
    or false
  local gangAllowed = hasGangWhitelist
    and CheckJobGangWhitelist(dealership.showroom_gang_whitelist, playerGang.name, playerGang.grade)
    or false

  DebugPrint("[ShowroomWhitelist] Job allowed: " .. tostring(jobAllowed) .. ", Gang allowed: " .. tostring(gangAllowed), "debug")
  DebugPrint("[ShowroomWhitelist] Final result: " .. tostring(jobAllowed or gangAllowed), "debug")

  return jobAllowed or gangAllowed
end)

lib.callback.register("jg-dealerships:server:exit-showroom", function(playerSource)
  local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
  if not playerIdentifier then
    DebugPrint("jg-dealerships:server:exit-showroom: no identifier found for player " .. playerSource, "warning")
    return false
  end

  local playerPed = GetPlayerPed(playerSource)
  FreezeEntityPosition(playerPed, false)
  ClearPedTasksImmediately(playerPed)
  showroomSessions[playerIdentifier] = nil
  return true
end)

exports("getShowroomVehicles", function(dealershipId)
  if type(dealershipId) ~= "string" then
    return false
  end

  return Showroom.Server.GetVehicles(dealershipId)
end)
