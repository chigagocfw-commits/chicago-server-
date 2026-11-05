-- Server State Variables
Core = nil
local playerJobDataCache = {}
local isDatabaseReady = false
local activeJobSessions = {}
local discordAvatarCache = {}
local paymentCooldowns = {}

-- Server State & Session Architecture
local activeTruckerSessions = {}

local function HasTruckerJob(playerId)
  if Config.JobName == "all" then return true end
  local player = GetPlayer(playerId)
  if not player then return false end
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    return player.job and player.job.name == Config.JobName
  else
    return player.PlayerData and player.PlayerData.job and player.PlayerData.job.name == Config.JobName
  end
end

-- Start Job Session Tracking with Authoritative Verification
RegisterServerEvent("codem-truckerjob:StartJob")
AddEventHandler("codem-truckerjob:StartJob", function(missionId, routeLabel, truckNetId)
  local playerId = source
  if not missionId or missionId == false then
    activeTruckerSessions[playerId] = nil
    activeJobSessions[playerId] = nil
    return
  end

  if not HasTruckerJob(playerId) then
    print("[TRUCKER SECURITY] Unauthorized StartJob attempt from source " .. tostring(playerId))
    return
  end

  local missionData = GetMissionById(tonumber(missionId))
  if not missionData then
    print("[TRUCKER SECURITY] Invalid missionId in StartJob: " .. tostring(missionId))
    return
  end

  local routeData = GetRouteByLabel(missionData.routes, routeLabel)
  if not routeData then
    routeData = missionData.routes[1]
    routeLabel = routeData.label
  end

  activeTruckerSessions[playerId] = {
    state = "EN_ROUTE",
    missionId = tonumber(missionId),
    routeLabel = routeLabel,
    routeData = routeData,
    missionData = missionData,
    truckNetId = truckNetId,
    startTime = GetGameTimer(),
    destination = routeData and (routeData.destination or routeData.board) or nil,
    depotCoords = vector3(Config.VehSpawn.x, Config.VehSpawn.y, Config.VehSpawn.z),
    illegalBoxes = 0,
    lastBoxTimer = 0,
    basePay = missionData.payment,
    extraPayment = routeData and (routeData.extraPayment or 0) or 0,
  }
  activeJobSessions[playerId] = missionId
end)

AddEventHandler("playerDropped", function()
  local playerId = source
  activeTruckerSessions[playerId] = nil
  activeJobSessions[playerId] = nil
end)

-- Core Initialization
CreateThread(function()
  Config.Framework = select(2, GetCore())
  Core = GetCore()

  while Core == nil do
    Wait(0)
  end

  -- Register callback for checking mission unlock status
  RegisterCallback("codem-truckerjob:CheckMissionUnlocked", function(playerId, cb, missionId)
    local playerData = GetPlayerJobData(playerId)
    if playerData then
      cb(playerData.unlockedMissions[tostring(missionId)])
    else
      cb(false)
    end
  end)

  -- Load all player data from database
  local allPlayerData = ExecuteSql("SELECT * FROM codem_truckerjob")

  for _, playerRecord in pairs(allPlayerData) do
    playerRecord.unlockedMissions = json.decode(playerRecord.unlockedMissions)
    playerRecord.dailymissions = json.decode(playerRecord.dailymissions)
    playerRecord.history = json.decode(playerRecord.history)
    playerRecord.points = json.decode(playerRecord.points)
    table.insert(playerJobDataCache, playerRecord)
  end

  -- Register callback for leaderboard
  RegisterCallback("codem-truckerjob:GetLeaderboard", function(playerId, cb)
    table.sort(playerJobDataCache, function(a, b)
      return a.level > b.level
    end)

    local identifier = GetIdentifier(playerId)
    local leaderboardData = { data = {} }

    for index, playerData in pairs(playerJobDataCache) do
      if index <= 8 then
        table.insert(leaderboardData.data, playerData)
      end
    end

    cb(leaderboardData)
  end)

  isDatabaseReady = true
end)

function waitDatabase()
  while not isDatabaseReady do
    Wait(0)
  end
end

function GetPlayerJobData(playerId)
  waitDatabase()
  local identifier = GetIdentifier(playerId)

  for _, playerData in pairs(playerJobDataCache) do
    if playerData.identifier == identifier then
      return playerData
    end
  end

  return false
end

RegisterServerEvent("codem-truckerjob:LoadPlayerData")
AddEventHandler("codem-truckerjob:LoadPlayerData", function()
  local playerId = source
  LoadPlayerData(playerId)
end)

function SyncPlayerDataByKey(playerId, key, value)
  TriggerClientEvent("codem-truckerjob:SyncPlayerDataByKey", playerId, key, value)
end

function GetIdentifier(playerId)
  local player = GetPlayer(playerId)
  local identifier = false

  if player then
    if Config.Framework == "esx" or Config.Framework == "oldesx" then
      identifier = player.getIdentifier()
    else
      identifier = player.PlayerData.citizenid
    end
  end

  return identifier
end

function GetPlayer(playerId)
  local player = false
  WaitCore()

  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    player = Core.GetPlayerFromId(playerId)
  else
    player = Core.Functions.GetPlayer(playerId)
  end

  return player
end

function GetPlayerRPName(playerId)
  if Config.Framework == "oldesx" or Config.Framework == "esx" then
    local player = Core.GetPlayerFromId(tonumber(playerId))
    if player then
      return player.getName()
    end
  elseif Config.Framework == "qb" or Config.Framework == "oldqb" then
    local player = Core.Functions.GetPlayer(tonumber(playerId))
    if player then
      local charinfo = player.PlayerData.charinfo
      return charinfo.firstname .. " " .. charinfo.lastname
    end
  end

  return GetPlayerName(playerId)
end

-- Discord API Integration
function DiscordRequest(method, endpoint, body)
  local response = nil
  local authHeader = "Bot " .. botToken

  PerformHttpRequest("https://discordapp.com/api/" .. endpoint, function(code, data, headers)
    response = {
      data = data,
      code = code,
      headers = headers
    }
  end, method, #body > 0 and json.encode(body) or "", {
    ["Content-Type"] = "application/json",
    ["Authorization"] = authHeader
  })

  while response == nil do
    Citizen.Wait(0)
  end

  return response
end

function GetDiscordAvatar(playerId)
  local discordId = nil
  local avatarUrl = nil

  for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
    if string.match(identifier, "discord:") then
      discordId = string.gsub(identifier, "discord:", "")
      break
    end
  end

  if discordId then
    -- Check cache first
    if discordAvatarCache[discordId] == nil then
      local endpoint = string.format("users/%s", discordId)
      local response = DiscordRequest("GET", endpoint, {})

      if response.code == 200 then
        local userData = json.decode(response.data)
        if userData and userData.avatar then
          local firstChar = userData.avatar:sub(1, 1)
          local secondChar = userData.avatar:sub(2, 2)

          if firstChar and secondChar == "_" then
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".gif"
          else
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".png"
          end
        end
      else
        return Config.DefaultImage
      end

      discordAvatarCache[discordId] = avatarUrl
    else
      avatarUrl = discordAvatarCache[discordId]
    end
  end

  if avatarUrl == nil or avatarUrl == false then
    avatarUrl = Config.DefaultImage
  end

  return avatarUrl
end

-- Authoritative Mission Unlock Handler
RegisterServerEvent("codem-truckerjob:UnlockMission")
AddEventHandler("codem-truckerjob:UnlockMission", function(missionData)
  local playerId = source
  local playerData = GetPlayerJobData(playerId)

  if playerData and missionData and missionData.id then
    local missionId = tonumber(missionData.id)
    local missionIdStr = tostring(missionId)

    if playerData.unlockedMissions[missionIdStr] then
      TriggerClientEvent("codem-truckerjob:createNotification", playerId, Config.Language.already_unlocked)
      return
    end

    local authoritativeMission = GetMissionById(missionId)
    if not authoritativeMission then
      print("[TRUCKER SECURITY] UnlockMission invalid mission ID: " .. tostring(missionId))
      return
    end

    local companyIndexStr = tostring(authoritativeMission.companyIndex)
    local currentPoints = playerData.points[companyIndexStr] or 0
    local requiredPoints = authoritativeMission.reqPoint or 0

    if currentPoints >= requiredPoints then
      playerData.points[companyIndexStr] = currentPoints - requiredPoints
      playerData.unlockedMissions[missionIdStr] = true

      SyncPlayerDataByKey(playerId, "points", playerData.points)
      SyncPlayerDataByKey(playerId, "unlockedMissions", playerData.unlockedMissions)

      ExecuteSql("UPDATE codem_truckerjob SET unlockedMissions = '" ..
      json.encode(playerData.unlockedMissions) ..
      "', points= '" .. json.encode(playerData.points) .. "' WHERE identifier = '" .. playerData.identifier .. "'")
    else
      TriggerClientEvent("codem-truckerjob:createNotification", playerId, Config.Language.not_enough_points)
    end
  end
end)

-- Add To History
function AddToHistory(playerId, label, supply, earnings)
  local playerData = GetPlayerJobData(playerId)

  if playerData then
    table.insert(playerData.history, {
      label = label,
      supply = supply,
      earn = earnings,
      date = os.time()
    })

    ExecuteSql("UPDATE codem_truckerjob SET `history` = '" ..
    json.encode(playerData.history) .. "' WHERE `identifier` = '" .. playerData.identifier .. "'")
    SyncPlayerDataByKey(playerId, "history", playerData.history)
  end
end

-- Create New Player Data
function CreatePlayerData(playerId)
  local identifier = GetIdentifier(playerId)
  local playerData = GetPlayerJobData(playerId)
  local avatarUrl = GetDiscordAvatar(playerId)

  -- If player already exists in cache, just update avatar if missing
  if playerData then
    if not playerData.avatar then
      playerData.avatar = avatarUrl or Config.DefaultImage
      SyncPlayerDataByKey(playerId, "avatar", avatarUrl)
      ExecuteSql("UPDATE codem_truckerjob SET `avatar` = '" .. (playerData.avatar or Config.DefaultImage) .. "'")
    end
    return
  end

  -- Initialize unlocked missions (mission 1 unlocked by default)
  local unlockedMissions = {}
  for i = 1, 16 do
    unlockedMissions[tostring(i)] = (i == 1)
  end

  -- Initialize company points
  local companyPoints = {}
  for i = 0, 7 do
    companyPoints[tostring(i)] = 0
  end

  -- Create new player record
  local newPlayerData = {
    identifier = identifier,
    points = companyPoints,
    history = {},
    avatar = avatarUrl,
    name = GetPlayerRPName(playerId),
    unlockedMissions = unlockedMissions,
    dailymissions = {
      data = CreateDailyMission(),
      resetAt = os.time() + 86400
    },
    totalEarnings = 0,
    completedJobs = 0,
    xp = 0,
    level = 1
  }

  -- Check if player already exists in database
  local existingData = ExecuteSql("SELECT * FROM codem_truckerjob WHERE identifier = :identifier",
    { identifier = identifier })
  if existingData[1] then
    print("player with " .. identifier .. " identifier is already exist!")
    return
  end

  -- Add to cache and database
  table.insert(playerJobDataCache, newPlayerData)

  ExecuteSql(
  "INSERT INTO codem_truckerjob (identifier, points, unlockedMissions, dailymissions, xp, level, totalEarnings, completedJobs, name, avatar, history) VALUES (:identifier, :points, :unlockedMissions, :dailymissions, :xp, :level, :totalEarnings, :completedJobs, :name, :avatar, :history)",
    {
      identifier = newPlayerData.identifier,
      points = json.encode(newPlayerData.points),
      unlockedMissions = json.encode(newPlayerData.unlockedMissions),
      dailymissions = json.encode(newPlayerData.dailymissions),
      xp = newPlayerData.xp,
      level = newPlayerData.level,
      totalEarnings = newPlayerData.totalEarnings,
      completedJobs = newPlayerData.completedJobs,
      name = newPlayerData.name,
      avatar = newPlayerData.avatar or Config.DefaultImage,
      history = json.encode(newPlayerData.history)
    })

  LoadPlayerData(playerId)
end

-- Load Player Data
function LoadPlayerData(playerId)
  local playerData = GetPlayerJobData(playerId)

  if playerData then
    SyncPlayerDataByKey(playerId, "identifier", playerData.identifier)
    SyncPlayerDataByKey(playerId, "points", playerData.points)
    SyncPlayerDataByKey(playerId, "history", playerData.history)
    SyncPlayerDataByKey(playerId, "unlockedMissions", playerData.unlockedMissions)
    SyncPlayerDataByKey(playerId, "dailymissions", playerData.dailymissions)
    SyncPlayerDataByKey(playerId, "xp", playerData.xp)
    SyncPlayerDataByKey(playerId, "name", playerData.name)
    SyncPlayerDataByKey(playerId, "totalEarnings", playerData.totalEarnings)
    SyncPlayerDataByKey(playerId, "completedJobs", playerData.completedJobs)
    SyncPlayerDataByKey(playerId, "level", playerData.level)
    SyncPlayerDataByKey(playerId, "avatar", GetDiscordAvatar(playerId))
  else
    CreatePlayerData(playerId)
  end
end

-- Register Callback Helper
function RegisterCallback(callbackName, callback)
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    Core.RegisterServerCallback(callbackName, function(playerId, cb, data)
      callback(playerId, cb, data)
    end)
  else
    Core.Functions.CreateCallback(callbackName, function(playerId, cb, data)
      callback(playerId, cb, data)
    end)
  end
end

-- SQL Execution Helper
function ExecuteSql(query, params)
  local isWaiting = true
  local result = nil

  if Config.SQL == "oxmysql" then
    if params then
      exports.oxmysql:execute(query, params, function(data)
        result = data
        isWaiting = false
      end)
    else
      exports.oxmysql:execute(query, function(data)
        result = data
        isWaiting = false
      end)
    end
  elseif Config.SQL == "ghmattimysql" then
    if params then
      exports.ghmattimysql:execute(query, params, function(data)
        result = data
        isWaiting = false
      end)
    else
      exports.ghmattimysql:execute(query, {}, function(data)
        result = data
        isWaiting = false
      end)
    end
  elseif Config.SQL == "mysql-async" then
    if params then
      MySQL.Async.fetchAll(query, params, function(data)
        result = data
        isWaiting = false
      end)
    else
      MySQL.Async.fetchAll(query, {}, function(data)
        result = data
        isWaiting = false
      end)
    end
  end

  while isWaiting do
    Citizen.Wait(0)
  end

  return result
end

-- Inventory Check Helper
function HasItem(playerId, itemData)
  local player = GetPlayer(playerId)

  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    if Config.Inventory == "codem-inventory" then
      return exports["codem-inventory"]:CheckItemValid(playerId, itemData.name, tonumber(itemData.amount))
    elseif Config.Inventory == "ox_inventory" then
      local count = exports.ox_inventory:Search(playerId, "count", itemData.name)
      return tonumber(count) >= tonumber(itemData.amount)
    elseif Config.Inventory == "qs_inventory" then
      local count = exports["qs-inventory"]:GetItemTotalAmount(playerId, itemData.name)
      return count ~= nil and count ~= 0
    else
      local item = player.getInventoryItem(itemData.name)
      if not item then return false end
      local count = item.count or item.amount
      return tonumber(count) >= tonumber(itemData.amount)
    end
  else
    if Config.Inventory == "codem-inventory" then
      return exports["codem-inventory"]:CheckItemValid(playerId, itemData.name, tonumber(itemData.amount))
    elseif Config.Inventory == "ox_inventory" then
      local count = exports.ox_inventory:Search(playerId, "count", itemData.name)
      return tonumber(count) >= tonumber(itemData.amount)
    elseif Config.Inventory == "qs_inventory" then
      local count = exports["qs-inventory"]:GetItemTotalAmount(playerId, itemData.name)
      return count ~= nil and count ~= 0
    else
      return Core.Functions.HasItem(playerId, itemData.name, tonumber(itemData.amount))
    end
  end

  return false
end

-- Finish Job Handler
RegisterServerEvent("codem-truckerjob:FinishJob")
AddEventHandler("codem-truckerjob:FinishJob", function(missionId, vehicleHealth, loadedIllegal, routeLabel)
  local playerId = source

  if paymentCooldowns[playerId] then
    print("[TRUCKER SECURITY] Player " .. playerId .. " payment cooldown active")
    return
  end

  local session = activeTruckerSessions[playerId]
  if not session then
    print("[TRUCKER SECURITY] Player " .. playerId .. " tried to finish job without active session")
    return
  end

  if session.state == "PAYING" or session.state == "PAID" then
    print("[TRUCKER SECURITY] Player " .. playerId .. " payment already in progress/paid")
    return
  end

  if session.state ~= "EN_ROUTE" then
    print("[TRUCKER SECURITY] Player " .. playerId .. " invalid session state: " .. tostring(session.state))
    return
  end

  if not HasTruckerJob(playerId) then
    print("[TRUCKER SECURITY] Player " .. playerId .. " unauthorized job during FinishJob")
    activeTruckerSessions[playerId] = nil
    activeJobSessions[playerId] = nil
    return
  end

  local ped = GetPlayerPed(playerId)
  local currentVeh = GetVehiclePedIsIn(ped, false)
  local sessionVeh = NetworkGetEntityFromNetworkId(session.truckNetId)
  if not DoesEntityExist(sessionVeh) or currentVeh ~= sessionVeh or GetPedInVehicleSeat(sessionVeh, -1) ~= ped then
    print("[TRUCKER SECURITY] Player " .. playerId .. " vehicle entity mismatch or not in driver seat")
    return
  end

  local playerCoords = GetEntityCoords(ped)
  local distToDepot = #(playerCoords - session.depotCoords)
  if distToDepot > 25.0 then
    print(string.format("[TRUCKER SECURITY] Player %s too far from return depot (%.1fm > 25m)", playerId, distToDepot))
    return
  end

  local destCoords = session.destination or session.depotCoords
  local distOneWay = #(destCoords - session.depotCoords)
  local totalDist = distOneWay * 2.0
  local minTransitTime = math.max(60, math.ceil(totalDist / 22.0))
  local elapsedSeconds = (GetGameTimer() - session.startTime) / 1000.0

  if elapsedSeconds < minTransitTime then
    print(string.format("[TRUCKER SECURITY] Player %s transit too fast: elapsed %.1fs < min %ds (dist: %.1fm)", playerId, elapsedSeconds, minTransitTime, totalDist))
    return
  end

  local playerData = GetPlayerJobData(playerId)
  if not playerData then
    print("[TRUCKER SECURITY] Player data not found for source " .. tostring(playerId))
    return
  end

  session.state = "PAYING"
  paymentCooldowns[playerId] = true
  SetTimeout(5000, function() paymentCooldowns[playerId] = false end)

  local basePay = session.basePay
  local extraPayment = session.extraPayment or 0

  vehicleHealth = tonumber(vehicleHealth) or 100
  if vehicleHealth > 100 then vehicleHealth = 100 end
  if vehicleHealth < 0 then vehicleHealth = 0 end

  if GetEntityHealth(sessionVeh) <= 0 then
    vehicleHealth = 50
  end

  local damagePercent = 100 - vehicleHealth
  local damagePenalty = math.floor((basePay * damagePercent) / 100)
  local finalPay = (basePay - damagePenalty) + extraPayment

  local tookIllegalItems = false
  if session.illegalBoxes >= 10 then
    local currentItems = exports.ox_inventory:GetItemCount(playerId, Config.IllegalNPC.item_name)
    if currentItems >= 10 then
      local removed = exports.ox_inventory:RemoveItem(playerId, Config.IllegalNPC.item_name, 10)
      if removed then
        tookIllegalItems = true
        finalPay = finalPay + Config.IllegalNPC.money
      end
    else
      TriggerClientEvent("codem-truckerjob:createNotification", playerId, Config.Language.not_enough_illegal_box)
    end
  end

  local paymentSuccess = addMoney(playerId, finalPay)

  if paymentSuccess then
    session.state = "PAID"
    activeTruckerSessions[playerId] = nil
    activeJobSessions[playerId] = nil

    if damagePenalty > 0 then
      TriggerClientEvent("codem-truckerjob:createNotification", playerId, string.format(Config.Language.you_charged, damagePenalty))
    end

    local companyIndexStr = tostring(session.missionData.companyIndex)
    playerData.points[companyIndexStr] = (playerData.points[companyIndexStr] or 0) + 1
    playerData.totalEarnings = (playerData.totalEarnings or 0) + finalPay
    playerData.completedJobs = (playerData.completedJobs or 0) + 1

    SyncPlayerDataByKey(playerId, "points", playerData.points)
    SyncPlayerDataByKey(playerId, "totalEarnings", playerData.totalEarnings)
    SyncPlayerDataByKey(playerId, "completedJobs", playerData.completedJobs)

    AddXP(playerId, math.random(Config.GiveXP.min, Config.GiveXP.max))

    ExecuteSql("UPDATE codem_truckerjob SET 	otalEarnings = '" ..
    playerData.totalEarnings ..
    "', points= '" ..
    json.encode(playerData.points) ..
    "', completedJobs= '" .. playerData.completedJobs .. "' WHERE identifier = '" .. playerData.identifier .. "'")

    local historyEntry = {
      label = session.missionData.header,
      supply = session.missionData.requirementsLabel and session.missionData.requirementsLabel[1] and session.missionData.requirementsLabel[1].label or "Cargo"
    }
    AddToHistory(playerId, historyEntry.label, historyEntry.supply, finalPay)
  else
    print("[TRUCKER SECURITY] addMoney failed for player " .. playerId .. ", reverting state")
    if tookIllegalItems then
      exports.ox_inventory:AddItem(playerId, Config.IllegalNPC.item_name, 10)
    end
    session.state = "EN_ROUTE"
  end
end)

-- Authoritative Get Route By Label
function GetRouteByLabel(routes, label)
  if not routes then return false end
  for _, route in pairs(routes) do
    if route.label == label then
      return route
    end
  end
  return false
end

-- Authoritative Get Mission By ID
function GetMissionById(missionId)
  missionId = tonumber(missionId)
  for _, mission in pairs(Config.Missions) do
    if mission.id == missionId then
      return mission
    end
  end
  return false
end

-- Authoritative Give Illegal Item Handler
RegisterServerEvent("codem-truckerjob:GiveIllegalItem")
AddEventHandler("codem-truckerjob:GiveIllegalItem", function()
  local playerId = source
  local session = activeTruckerSessions[playerId]
  if not session or session.state ~= "EN_ROUTE" then
    print("[TRUCKER SECURITY] GiveIllegalItem rejected: no active session for " .. tostring(playerId))
    return
  end

  if not HasTruckerJob(playerId) then
    print("[TRUCKER SECURITY] GiveIllegalItem rejected: unauthorized job for " .. tostring(playerId))
    return
  end

  if session.illegalBoxes >= 10 then
    print("[TRUCKER SECURITY] GiveIllegalItem rejected: 10 boxes cap reached for " .. tostring(playerId))
    return
  end

  local now = GetGameTimer()
  if (now - (session.lastBoxTimer or 0)) < 2500 then
    print("[TRUCKER SECURITY] GiveIllegalItem rejected: rate-limit violation for " .. tostring(playerId))
    return
  end

  local ped = GetPlayerPed(playerId)
  local coords = GetEntityCoords(ped)
  local boardLoc = vector3(Config.IllegalNPC.boardLocation.x, Config.IllegalNPC.boardLocation.y, Config.IllegalNPC.boardLocation.z)
  local distToBoard = #(coords - boardLoc)
  if distToBoard > 25.0 then
    print(string.format("[TRUCKER SECURITY] GiveIllegalItem rejected: player %s too far from boardLocation (%.1fm)", playerId, distToBoard))
    return
  end

  session.illegalBoxes = session.illegalBoxes + 1
  session.lastBoxTimer = now
  AddInventoryItem(playerId, Config.IllegalNPC.item_name, 1)
end)