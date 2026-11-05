-- Server State Variables
Core = nil
local playerJobDataCache = {}
local isDatabaseReady = false
local activeJobSessions = {}
local discordAvatarCache = {}
local paymentCooldowns = {}

-- Start Job Session Tracking
RegisterServerEvent("codem-truckerjob:StartJob")
AddEventHandler("codem-truckerjob:StartJob", function(missionId)
  local playerId = source
  activeJobSessions[playerId] = missionId
end)

AddEventHandler("playerDropped", function()
  local playerId = source
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

-- Mission Unlock Handler
RegisterServerEvent("codem-truckerjob:UnlockMission")
AddEventHandler("codem-truckerjob:UnlockMission", function(missionData)
  local playerId = source
  local playerData = GetPlayerJobData(playerId)

  if playerData then
    local missionIdStr = tostring(missionData.id)

    -- Check if already unlocked
    if playerData.unlockedMissions[missionIdStr] then
      TriggerClientEvent("codem-truckerjob:createNotification", playerId, Config.Language.already_unlocked)
      return
    end

    local companyIndexStr = tostring(missionData.companyIndex)
    local currentPoints = playerData.points[companyIndexStr]

    -- Check if player has enough points
    if missionData.reqPoint <= currentPoints then
      playerData.points[companyIndexStr] = currentPoints - missionData.reqPoint
      playerData.unlockedMissions[missionIdStr] = true

      SyncPlayerDataByKey(playerId, "points", playerData.points)
      SyncPlayerDataByKey(playerId, "unlockedMissions", playerData.unlockedMissions)

      ExecuteSql("UPDATE codem_truckerjob SET `unlockedMissions` = '" ..
      json.encode(playerData.unlockedMissions) ..
      "', `points`= '" .. json.encode(playerData.points) .. "' WHERE `identifier` = '" .. playerData.identifier .. "'")
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

  -- Anti-spam check
  if paymentCooldowns[playerId] then
    print("Player " .. playerId .. " tried to execute pay trigger too fast")
    return
  end

  -- Verify job session
  if activeJobSessions[playerId] ~= missionId then
    print("Player " .. playerId .. " tried to execute pay trigger with wrong job id")
    return
  end

  -- Set cooldown
  paymentCooldowns[playerId] = true
  SetTimeout(5000, function()
    paymentCooldowns[playerId] = false
  end)

  activeJobSessions[playerId] = nil

  local player = GetPlayer(playerId)
  local playerData = GetPlayerJobData(playerId)

  if playerData then
    local missionData = GetMissionById(missionId)

    if missionData then
      local companyIndex = missionData.companyIndex

      local historyEntry = {
        label = missionData.header,
        supply = missionData.requirementsLabel[1].label
      }

      -- Clamp vehicle health
      if vehicleHealth > 100 then vehicleHealth = 100 end
      if vehicleHealth < 0 then vehicleHealth = 0 end

      -- Calculate damage penalty
      local damagePercent = 100 - vehicleHealth
      local basePay = missionData.payment
      local damagePenalty = math.floor((basePay * damagePercent) / 100)
      local finalPay = basePay - damagePenalty

      -- Check for illegal cargo bonus
      if loadedIllegal then
        local hasIllegalItem = HasItem(playerId, {
          name = Config.IllegalNPC.item_name,
          amount = 10
        })

        if hasIllegalItem then
          finalPay = finalPay + Config.IllegalNPC.money
          RemoveItem(playerId, Config.IllegalNPC.item_name, 10)
        else
          TriggerClientEvent("codem-truckerjob:createNotification", playerId, Config.Language.not_enough_illegal_box)
        end
      else
        print("loadedIllegal is false, skipping illegal item check")
      end

      -- Check for route extra payment
      local routeData = GetRouteByLabel(missionData.routes, routeLabel)
      local extraPayment = false

      if routeData and routeData.extraPayment then
        extraPayment = routeData.extraPayment
      end

      if extraPayment then
        finalPay = finalPay + extraPayment
      end

      -- Pay the player
      addMoney(playerId, finalPay)

      -- Notify about damage penalty
      if damagePenalty > 0 then
        TriggerClientEvent("codem-truckerjob:createNotification", playerId,
          string.format(Config.Language.you_charged, damagePenalty))
      end

      -- Update player stats
      local companyIndexStr = tostring(companyIndex)
      playerData.points[companyIndexStr] = playerData.points[companyIndexStr] + 1
      playerData.totalEarnings = playerData.totalEarnings + finalPay
      playerData.completedJobs = playerData.completedJobs + 1

      SyncPlayerDataByKey(playerId, "points", playerData.points)
      SyncPlayerDataByKey(playerId, "totalEarnings", playerData.totalEarnings)
      SyncPlayerDataByKey(playerId, "completedJobs", playerData.completedJobs)

      -- Add XP
      AddXP(playerId, math.random(Config.GiveXP.min, Config.GiveXP.max))

      -- Save to database
      ExecuteSql("UPDATE codem_truckerjob SET `totalEarnings` = '" ..
      playerData.totalEarnings ..
      "', `points`= '" ..
      json.encode(playerData.points) ..
      "', `completedJobs`= '" .. playerData.completedJobs .. "' WHERE `identifier` = '" .. playerData.identifier .. "'")

      -- Add to history
      AddToHistory(playerId, historyEntry.label, historyEntry.supply, finalPay)
    end
  end
end)

-- Get Route By Label
function GetRouteByLabel(routes, label)
  for _, route in pairs(routes) do
    if route.label == label then
      return route
    end
  end
  return false
end

-- Get Mission By ID
function GetMissionById(missionId)
  for _, mission in pairs(Config.Missions) do
    if mission.id == missionId then
      return mission
    end
  end
  return false
end

-- Give Illegal Item Handler
RegisterServerEvent("codem-truckerjob:GiveIllegalItem")
AddEventHandler("codem-truckerjob:GiveIllegalItem", function()
  local playerId = source
  AddInventoryItem(playerId, Config.IllegalNPC.item_name, 1)
end)
