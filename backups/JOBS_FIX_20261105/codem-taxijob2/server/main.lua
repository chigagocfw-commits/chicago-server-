-- Codem Taxi Job Server Script - Deobfuscated Version
-- Core Variables
Core = nil
Players = {}

-- Use a dedicated table so this resource never conflicts with older codem-taxijob
local TAXIJOB_TABLE = "codem_taxijob2"

-- Helpers: make DB-loaded JSON fields safe
local function SafeJsonDecode(value, fallback)
  if value == nil then
    return fallback
  end
  local ok, decoded = pcall(json.decode, value)
  if ok and decoded ~= nil then
    return decoded
  end
  return fallback
end

-- Create daily missions with initial progress (per-player copy)
local function BuildDailyMissions()
  local missions = {}
  local daily = (Config and Config.DailyMissions) or {}

  for missionId, missionData in pairs(daily) do
    local m = {}
    if type(missionData) == "table" then
      for k, v in pairs(missionData) do
        m[k] = v
      end
    end
    m.process = 0
    missions[missionId] = m
  end

  return missions
end

local function EnsurePlayerJobDefaults(playerData)
  if type(playerData.history) ~= "table" then
    playerData.history = {}
  end
  if type(playerData.vipCooldown) ~= "table" then
    playerData.vipCooldown = {}
  end
  if type(playerData.dailymissions) ~= "table" then
    playerData.dailymissions = {}
  end
  if type(playerData.dailymissions.resetAt) ~= "number" then
    playerData.dailymissions.resetAt = os.time() + 86400
  end
  if type(playerData.dailymissions.data) ~= "table" then
    playerData.dailymissions.data = BuildDailyMissions()
  end
end

local function TryParseLegacyJobdate(jobdate)
  if type(jobdate) ~= "string" then
    return nil
  end

  -- legacy format from older codem taxi script: "%d.%m.%y %X" (e.g. "11.02.26 14:44:12")
  local d, m, yy, hh, mi, ss = jobdate:match("^(%d%d)%.(%d%d)%.(%d%d)%s+(%d%d):(%d%d):(%d%d)$")
  if d and m and yy and hh and mi and ss then
    local year = 2000 + tonumber(yy)
    return os.time({
      year = year,
      month = tonumber(m),
      day = tonumber(d),
      hour = tonumber(hh),
      min = tonumber(mi),
      sec = tonumber(ss)
    })
  end

  return nil
end

local function SanitizeHistoryEntries(history)
  if type(history) ~= "table" then
    return {}, true
  end

  local changed = false

  for _, entry in pairs(history) do
    if type(entry) == "table" then
      -- map legacy keys
      if entry.earn == nil and entry.price ~= nil then
        entry.earn = tonumber(entry.price) or entry.price
        changed = true
      end
      if entry.label == nil then
        if entry.way ~= nil then
          entry.label = tostring(entry.way)
        else
          entry.label = "Taxi Job"
        end
        changed = true
      end
      if entry.customertype == nil then
        entry.customertype = "NPC"
        changed = true
      end

      -- normalize numbers
      local xpNum = tonumber(entry.xp)
      if xpNum == nil then
        entry.xp = 0
        changed = true
      elseif entry.xp ~= xpNum then
        entry.xp = xpNum
        changed = true
      end

      local earnNum = tonumber(entry.earn)
      if earnNum == nil then
        entry.earn = 0
        changed = true
      elseif entry.earn ~= earnNum then
        entry.earn = earnNum
        changed = true
      end

      -- normalize date
      local dateNum = tonumber(entry.date)
      if dateNum == nil then
        local parsed = TryParseLegacyJobdate(entry.jobdate)
        entry.date = parsed or os.time()
        changed = true
      else
        if entry.date ~= dateNum then
          entry.date = dateNum
          changed = true
        end
      end
    end
  end

  return history, changed
end

-- Generate security key
local keyPrefix = "CODEM-taxijob"
local randomPart1 = math.random(10000, 999999999)
local keyMiddle = "saas"
local randomPart2 = math.random(10000, 999999999)
local keySuffix = "KEY"
key = keyPrefix .. randomPart1 .. keyMiddle .. randomPart2 .. keySuffix

-- Database initialization flag
databaseInitialized = false

-- Player fares storage
fares = {}
-- Event: Set fare for player
RegisterServerEvent("codem-taxijob:SetFare")
AddEventHandler("codem-taxijob:SetFare", function(fareAmount)
  local playerId = source
  fares[playerId] = fareAmount
end)
-- Server initialization thread
CreateThread(function()
  -- Initialize framework
  Core, Config.Framework = GetCore()
  
  -- Load player data from database
  local playersData = ExecuteSql("SELECT * FROM " .. TAXIJOB_TABLE)
  
  -- Process each player's data
  for _, playerData in pairs(playersData) do
    -- Decode JSON fields
    playerData.dailymissions = SafeJsonDecode(playerData.dailymissions, nil)
    local historyRaw = playerData.history
    playerData.history = SafeJsonDecode(historyRaw, {})
    playerData.vipCooldown = SafeJsonDecode(playerData.vipCooldown, {})

    -- Ensure missing/NULL DB fields don't crash runtime
    EnsurePlayerJobDefaults(playerData)

    -- Migrate legacy history schemas (from older codem-taxijob using same SQL table)
    local sanitizedHistory, historyChanged = SanitizeHistoryEntries(playerData.history)
    playerData.history = sanitizedHistory
    if historyChanged and playerData.identifier then
      ExecuteSql("UPDATE " .. TAXIJOB_TABLE .. " SET `history` = :history WHERE `identifier` = :identifier", {
        history = json.encode(playerData.history),
        identifier = playerData.identifier
      })
    end
  end
  
  -- Store processed player data
  Players = playersData
  -- Callback: Get security key
  RegisterCallback("codem-taxijob:getKey", function(source, cb)
    cb(key)
  end)
  
  -- Callback: Get leaderboard data
  RegisterCallback("codem-taxijob:GetLeaderboard", function(source, cb)
    -- Deduplicate players by identifier to avoid duplicate entries
    local unique = {}
    for _, p in ipairs(Players) do
      local id = p.identifier or p.steam or p.discord or tostring(p.id)
      if id then
        local existing = unique[id]
        if not existing then
          unique[id] = p
        else
          -- keep the entry with the higher level
          local lvlP = tonumber(p.level) or 0
          local lvlE = tonumber(existing.level) or 0
          if lvlP > lvlE then
            unique[id] = p
          end
        end
      else
        -- fallback: use a generated key for entries without identifier
        table.insert(unique, p)
      end
    end

    -- Convert unique map to array
    local uniqueList = {}
    for _, v in pairs(unique) do
      table.insert(uniqueList, v)
    end

    -- Sort unique list by level (highest first)
    table.sort(uniqueList, function(a, b)
      return (tonumber(a.level) or 0) > (tonumber(b.level) or 0)
    end)

    local leaderboardData = { data = {} }
    for index = 1, math.min(8, #uniqueList) do
      table.insert(leaderboardData.data, uniqueList[index])
    end

    cb(leaderboardData)
  end)
  
  -- Callback: Get player information
  RegisterCallback("codem-taxijob:GetPlayerInformations", function(source, cb, playerId)
    local playerInfo = {
      name = GetPlayerRPName(playerId),
      id = playerId
    }
    cb(playerInfo)
  end)
  databaseInitialized = true
end)

-- Wait for database initialization function
function WaitForDatabase()
  while not databaseInitialized do
    Wait(0)
  end
end
WaitDatabase = WaitForDatabase
-- Function to add entry to player's history
function AddToHistory(playerId, label, customerType, earnAmount, xpAmount)
  local playerData = GetPlayerJobData(playerId)
  if playerData then
    -- Create history entry
    local historyEntry = {
      label = label,
      xp = xpAmount,
      earn = earnAmount,
      customertype = customerType,
      date = os.time()
    }
    
    -- Add to player's history
    table.insert(playerData.history, historyEntry)
    
    -- Update database
    ExecuteSql("UPDATE " .. TAXIJOB_TABLE .. " SET `history` = :history WHERE `identifier` = :identifier", {
      history = json.encode(playerData.history),
      identifier = playerData.identifier
    })
    
    -- Sync with client
    SyncPlayerDataByKey(playerId, "history", playerData.history)
  end
end
-- Event: Send bill to player
RegisterServerEvent("codem-taxijob:SendBill")
AddEventHandler("codem-taxijob:SendBill", function(targetPlayerId, billAmount, passengerCount)
  local billOwnerId = source
  
  -- Create bill data
  local billData = {
    passengers = passengerCount,
    amount = billAmount,
    billOwner = billOwnerId,
    date = os.time()
  }
  
  -- Send bill to target player
  TriggerClientEvent("codem-taxijob:ShowBill", targetPlayerId, billData)
end)
-- Function to get player's money based on framework
function GetPlayerMoney(playerId)
  local playerMoney = 0
  local player = GetPlayer(playerId)
  
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    playerMoney = player.getMoney()
  else
    playerMoney = player.Functions.GetMoney("cash")
  end
  
  return playerMoney
end
-- Event: Pay bill
RegisterServerEvent("codem-taxijob:PayBill")
AddEventHandler("codem-taxijob:PayBill", function(billData)
  local payerId = source
  local payerPlayer = GetPlayer(payerId)
  local billOwnerPlayer = GetPlayer(billData.billOwner)
  
  -- Round bill amount
  billData.amount = math.ceil(billData.amount)
  
  local payerMoney = tonumber(GetPlayerMoney(payerId))
  local billAmount = tonumber(billData.amount)
  
  -- Check if player has enough money
  if payerMoney >= billAmount then
    -- Process payment based on framework
    if Config.Framework == "esx" or Config.Framework == "oldesx" then
      -- Remove money from payer
      payerPlayer.removeMoney(billData.amount)
      
      -- Add money to bill owner if exists
      if billOwnerPlayer then
        billOwnerPlayer.addMoney(billData.amount)
      end
    else
      -- QBCore framework
      payerPlayer.Functions.RemoveMoney("cash", billData.amount, "Taxi bill")
      
      if billOwnerPlayer then
        billOwnerPlayer.Functions.AddMoney("cash", billData.amount, "Taxi bill")
      end
    end
    
    -- Notify payer
    Config.ServerNotify(payerId, string.format(locales.you_paid_bill, billData.amount))
    
    -- Process bill owner rewards if exists
    if billOwnerPlayer then
      -- Give random XP to bill owner
      local xpReward = math.random(Config.PlayerMissionXP.min, Config.PlayerMissionXP.max)
      AddXP(billData.billOwner, xpReward)
      
      -- Notify bill owner
      Config.ServerNotify(billData.billOwner, string.format(locales.paid_bill, GetPlayerRPName(payerId), billData.amount))
      
      -- Add to history
      AddToHistory(billData.billOwner, locales.downtown_area, locales.player, billData.amount, xpReward)
      
      -- Trigger daily mission progress
      TriggerClientEvent("codem-taxijob:AddPlayerDailyMission", billData.billOwner)
    end
  else
    -- Notify insufficient funds
    Config.ServerNotify(payerId, locales.you_dont_have_money)
    Config.ServerNotify(billData.billOwner, locales.customer_dont_have_money)
  end
end)
-- Function to add money to player based on framework
function AddMoney(playerId, amount)
  local player = GetPlayer(playerId)
  amount = math.ceil(amount)
  
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    player.addMoney(amount)
  else
    player.Functions.AddMoney("cash", amount)
  end
end
-- Function to wait for Core initialization
function WaitCore()
  while Core == nil do
    Wait(0)
  end
end
-- Function to register callback based on framework
function RegisterCallback(callbackName, callbackFunction)
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    Core.RegisterServerCallback(callbackName, function(source, cb, ...)
      callbackFunction(source, cb, ...)
    end)
  else
    Core.Functions.CreateCallback(callbackName, function(source, cb, ...)
      callbackFunction(source, cb, ...)
    end)
  end
end
-- Function to execute SQL queries based on configured SQL resource
function ExecuteSql(query, parameters)
  local isWaiting = true
  local result = nil
  
  if Config.SQL == "oxmysql" then
    if parameters then
      exports.oxmysql:execute(query, parameters, function(data)
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
    if parameters then
      exports.ghmattimysql:execute(query, parameters, function(data)
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
    if parameters then
      MySQL.Async.fetchAll(query, parameters, function(data)
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
  
  -- Wait for query to complete
  while isWaiting do
    Citizen.Wait(0)
  end
  
  return result
end
-- Function to get player identifier based on framework
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
-- Function to get player object based on framework
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
-- Function to get player job data from the Players table
function GetPlayerJobData(playerId)
  WaitDatabase()
  local identifier = GetIdentifier(playerId)
  
  for _, playerData in pairs(Players) do
    if playerData.identifier == identifier then
      return playerData
    end
  end
  
  return false
end
-- Function to get player roleplay name based on framework
function GetPlayerRPName(playerId)
  if Config.Framework == "oldesx" or Config.Framework == "esx" then
    local player = Core.GetPlayerFromId(tonumber(playerId))
    if player then
      return player.getName()
    end
  elseif Config.Framework == "qb" or Config.Framework == "oldqb" then
    local player = Core.Functions.GetPlayer(tonumber(playerId))
    if player then
      local firstname = player.PlayerData.charinfo.firstname
      local lastname = player.PlayerData.charinfo.lastname
      return firstname .. " " .. lastname
    end
  end
  
  return GetPlayerName(playerId)
end
-- Discord integration variables
local discordHeaders = {}
local authHeader = "Bot " .. botToken

-- Function to make Discord API requests
function DiscordRequest(method, endpoint, data)
  local response = nil
  
  local url = "https://discordapp.com/api/" .. endpoint
  
  local function callback(responseCode, responseData, responseHeaders)
    response = {
      data = responseData,
      code = responseCode,
      headers = responseHeaders
    }
  end
  
  local body = ""
  if #data > 0 then
    body = json.encode(data) or ""
  end
  
  local headers = {
    ["Content-Type"] = "application/json",
    Authorization = authHeader
  }
  
  PerformHttpRequest(url, callback, method, body, headers)
  
  while response == nil do
    Citizen.Wait(0)
  end
  
  return response
end
-- Function to get Discord avatar URL for a player
function GetDiscordAvatar(playerId)
  local discordId = nil
  local avatarUrl = nil
  
  -- Find Discord identifier from player identifiers
  for _, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
    if string.match(identifier, "discord:") then
      discordId = string.gsub(identifier, "discord:", "")
      break
    end
  end
  
  if discordId then
    -- Check if avatar is cached
    if discordHeaders[discordId] == nil then
      local endpoint = string.format("users/%s", discordId)
      local response = DiscordRequest("GET", endpoint, {})
      
      if response.code == 200 then
        local userData = json.decode(response.data)
        if userData ~= nil and userData.avatar ~= nil then
          -- Check if avatar is animated (starts with 'a_')
          if userData.avatar:sub(1, 1) and userData.avatar:sub(2, 2) == "_" then
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".gif"
          else
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".png"
          end
        end
      else
        return Config.DefaultImage
      end
      
      -- Cache the avatar URL
      discordHeaders[discordId] = avatarUrl
    else
      avatarUrl = discordHeaders[discordId]
    end
  end
  
  if avatarUrl == nil or avatarUrl == false then
    avatarUrl = Config.DefaultImage
  end
  
  return avatarUrl
end
-- Event handler for loading player data
RegisterServerEvent("codem-taxijob:LoadPlayerData")
AddEventHandler("codem-taxijob:LoadPlayerData", function()
  local playerId = source
  LoadPlayerData(playerId)
end)
-- Function to sync player data by key to client
function SyncPlayerDataByKey(playerId, key, value)
  TriggerClientEvent("codem-taxijob:SyncPlayerDataByKey", playerId, key, value)
end
-- Event handler for taxi payment processing
RegisterServerEvent("codem-taxijob:Pay")
AddEventHandler("codem-taxijob:Pay", function(amount, xpReward, securityKey, missionType)
  local playerId = source
  
  -- Security check
  if securityKey ~= key then
    print("Player " .. playerId .. " tried to execute pay trigger")
    return
  end
  
  print(fares[playerId], amount)
  
  -- Validate fare amount
  if fares[playerId] ~= amount then
    print("Player " .. playerId .. " tried to execute pay trigger with wrong amount")
    return
  end
  
  -- Clear fare and add money to player
  fares[playerId] = nil
  local playerData = GetPlayerJobData(playerId)
  AddMoney(playerId, amount)
  
  if playerData then
    -- Update player statistics
    playerData.totalEarnings = playerData.totalEarnings + amount
    playerData.completedJobs = playerData.completedJobs + 1
    
    -- Add XP and update history
    AddXP(playerId, xpReward)
    AddToHistory(playerId, missionType, locales.npc, amount, xpReward)
    
    -- Update database
    local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `totalEarnings` = '" .. playerData.totalEarnings .. 
                       "', `completedJobs` = '" .. playerData.completedJobs .. 
                       "' WHERE `identifier` = '" .. playerData.identifier .. "'"
    ExecuteSql(updateQuery)
    
    -- Sync data to client
    SyncPlayerDataByKey(playerId, "totalEarnings", playerData.totalEarnings)
    SyncPlayerDataByKey(playerId, "completedJobs", playerData.completedJobs)
  end
end)
-- Function to create new player data or update avatar
function CreatePlayerData(playerId)
  local identifier = GetIdentifier(playerId)
  local playerData = GetPlayerJobData(playerId)
  local avatarUrl = GetDiscordAvatar(playerId)
  
  -- If player data exists, only update avatar if needed
  if playerData then
    if not playerData.avatar then
      playerData.avatar = avatarUrl
      SyncPlayerDataByKey(playerId, "avatar", avatarUrl)
      
      if playerData.avatar then
        local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `avatar` = '" .. playerData.avatar .. 
                           "' WHERE `identifier` = '" .. playerData.identifier .. "'"
        ExecuteSql(updateQuery)
      end
    end
    return
  end
  
  -- Skip if invalid identifier
  if identifier == 0 or identifier == "0" or identifier == nil then
    return
  end
  
  -- Create new player data
  local newPlayerData = {
    identifier = identifier,
    avatar = avatarUrl,
    name = GetPlayerRPName(playerId),
    xp = 0,
    level = 1,
    dailymissions = {
      data = CreateDailyMission(),
      resetAt = os.time() + 86400
    },
    totalEarnings = 0,
    completedJobs = 0,
    history = {},
    vipCooldown = {}
  }
  
  -- Add to Players table
  table.insert(Players, newPlayerData)
  
  -- Insert into database
  local insertQuery = "INSERT INTO " .. TAXIJOB_TABLE .. " (identifier, dailymissions, xp, level, totalEarnings, completedJobs, name, avatar, history, vipCooldown) VALUES (:identifier, :dailymissions, :xp, :level, :totalEarnings, :completedJobs, :name, :avatar, :history, :vipCooldown)"
  local parameters = {
    identifier = newPlayerData.identifier,
    dailymissions = json.encode(newPlayerData.dailymissions),
    xp = newPlayerData.xp,
    level = newPlayerData.level,
    totalEarnings = newPlayerData.totalEarnings,
    completedJobs = newPlayerData.completedJobs,
    name = newPlayerData.name,
    avatar = newPlayerData.avatar,
    history = json.encode(newPlayerData.history),
    vipCooldown = json.encode(newPlayerData.vipCooldown)
  }
  
  ExecuteSql(insertQuery, parameters)
  LoadPlayerData(playerId)
end
-- Function to create daily missions with initial progress
function CreateDailyMission()
  return BuildDailyMissions()
end
-- Function to load and sync all player data to client
function LoadPlayerData(playerId)
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    -- Sync all player data to client
    SyncPlayerDataByKey(playerId, "identifier", playerData.identifier)
    SyncPlayerDataByKey(playerId, "dailymissions", playerData.dailymissions)
    SyncPlayerDataByKey(playerId, "xp", playerData.xp)
    SyncPlayerDataByKey(playerId, "name", playerData.name)
    SyncPlayerDataByKey(playerId, "totalEarnings", playerData.totalEarnings)
    SyncPlayerDataByKey(playerId, "completedJobs", playerData.completedJobs)
    SyncPlayerDataByKey(playerId, "level", playerData.level)
    SyncPlayerDataByKey(playerId, "avatar", GetDiscordAvatar(playerId))
    SyncPlayerDataByKey(playerId, "history", playerData.history)
    SyncPlayerDataByKey(playerId, "vipCooldown", playerData.vipCooldown)
    
    -- Trigger UI ready event
    TriggerClientEvent("codem-taxijob:openReadyUi", playerId)
  else
    CreatePlayerData(playerId)
  end
end
-- Event handler for checking and resetting daily missions
RegisterServerEvent("codem-taxijob:CheckDailyMission")
AddEventHandler("codem-taxijob:CheckDailyMission", function()
  local playerId = source
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    EnsurePlayerJobDefaults(playerData)
    local timeDiff = os.difftime(playerData.dailymissions.resetAt, os.time())
    
    -- Reset daily missions if time has expired
    if timeDiff <= 0 then
      playerData.dailymissions.resetAt = os.time() + 86400
      playerData.dailymissions.data = CreateDailyMission()
      
      -- Update database
      local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `dailymissions` = '" .. 
                         json.encode(playerData.dailymissions) .. 
                         "' WHERE `identifier` = '" .. playerData.identifier .. "'"
      ExecuteSql(updateQuery)
      
      -- Sync to client
      SyncPlayerDataByKey(playerId, "dailymissions", playerData.dailymissions)
    end
  end
end)
-- Event handler for adding VIP mission cooldown
RegisterServerEvent("codem-taxijob:AddVipCooldown")
AddEventHandler("codem-taxijob:AddVipCooldown", function(missionId)
  local playerId = source
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    EnsurePlayerJobDefaults(playerData)
    -- Add 24-hour cooldown for this VIP mission
    playerData.vipCooldown[tostring(missionId)] = os.time() + 86400
    
    -- Update database
    local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `vipCooldown` = '" .. 
                       json.encode(playerData.vipCooldown) .. 
                       "' WHERE `identifier` = '" .. playerData.identifier .. "'"
    ExecuteSql(updateQuery)
    
    -- Sync to client
    SyncPlayerDataByKey(playerId, "vipCooldown", playerData.vipCooldown)
  end
end)
-- Event handler for adding daily mission progress
RegisterServerEvent("codem-taxijob:AddDailyMissionProcess")
AddEventHandler("codem-taxijob:AddDailyMissionProcess", function(missionId)
  local playerId = source
  local identifier = GetIdentifier(playerId)
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    EnsurePlayerJobDefaults(playerData)
    if type(playerData.dailymissions.data) ~= "table" then
      playerData.dailymissions.data = CreateDailyMission()
    end

    local missionData = playerData.dailymissions.data[missionId]
    if not missionData then
      return
    end
    local maxProgress = missionData.max
    local currentProgress = missionData.process
    
    -- Increment progress if not at max
    if maxProgress > currentProgress then
      playerData.dailymissions.data[missionId].process = currentProgress + 1
    end
    
    -- Check if mission is completed and award XP
    local newProgress = playerData.dailymissions.data[missionId].process
    local maxRequired = playerData.dailymissions.data[missionId].max
    
    if newProgress == maxRequired then
      playerData.dailymissions.data[missionId].process = maxRequired
      AddXP(playerId, playerData.dailymissions.data[missionId].xp)
    end
    
    -- Sync to client
    SyncPlayerDataByKey(playerId, "dailymissions", playerData.dailymissions)
    
    -- Update database
    local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `dailymissions` = '" .. 
                       json.encode(playerData.dailymissions) .. 
                       "' WHERE `identifier` = '" .. identifier .. "'"
    ExecuteSql(updateQuery)
  end
end)
-- Event handler for checking and clearing expired VIP cooldowns
RegisterServerEvent("codem-taxijob:CheckVipCooldown")
AddEventHandler("codem-taxijob:CheckVipCooldown", function()
  local playerId = source
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    EnsurePlayerJobDefaults(playerData)
    local cooldownUpdated = false
    
    -- Check each VIP mission cooldown
    for missionId, cooldownTime in pairs(playerData.vipCooldown or {}) do
      if playerData.vipCooldown[missionId] then
        local timeDiff = os.difftime(playerData.vipCooldown[missionId], os.time())
        
        -- Remove expired cooldowns
        if timeDiff <= 0 then
          playerData.vipCooldown[missionId] = false
          cooldownUpdated = true
        end
      end
    end
    
    -- Update database and sync if any cooldowns were cleared
    if cooldownUpdated then
      local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `vipCooldown` = '" .. 
                         json.encode(playerData.vipCooldown) .. 
                         "' WHERE `identifier` = '" .. playerData.identifier .. "'"
      ExecuteSql(updateQuery)
      
      SyncPlayerDataByKey(playerId, "vipCooldown", playerData.vipCooldown)
    end
  end
end)
-- Function to level up a player
function AddLevel(playerId)
  local identifier = GetIdentifier(playerId)
  local playerData = GetPlayerJobData(playerId)
  
  if playerData then
    -- Increase level
    playerData.level = playerData.level + 1
    
    -- Check if level exists in XP config
    if not Config.XP[playerData.level] then
      -- Cap at max level
      playerData.level = #Config.XP
      playerData.xp = Config.XP[playerData.level]
    else
      -- Reset XP for new level
      playerData.xp = 0
    end
    
    -- Sync to client
    SyncPlayerDataByKey(playerId, "xp", playerData.xp)
    SyncPlayerDataByKey(playerId, "level", playerData.level)
    
    -- Update database
    local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `level` = '" .. playerData.level .. 
                       "', `xp` = '" .. playerData.xp .. 
                       "' WHERE `identifier` = '" .. identifier .. "'"
    ExecuteSql(updateQuery)
  end
end
-- Function to add XP to a player and handle level ups
function AddXP(playerId, xpAmount)
  local identifier = GetIdentifier(playerId)
  local playerData = GetPlayerJobData(playerId)
  
  -- Validate XP amount
  if not xpAmount or xpAmount <= 0 then
    return
  end
  
  if playerData then
    local currentLevel = playerData.level
    local maxLevel = #Config.XP
    
    -- Don't add XP if already at max level
    if currentLevel == maxLevel then
      playerData.xp = 0
      return
    end
    
    -- Add XP
    local currentXP = tonumber(playerData.xp)
    local addedXP = tonumber(xpAmount)
    playerData.xp = currentXP + addedXP
    
    -- Check if level up is needed
    local xpRequired = Config.XP[currentLevel]
    if xpRequired then
      if playerData.xp >= xpRequired then
        local excessXP = xpRequired - playerData.xp
        AddLevel(playerId)
        
        -- Add excess XP to new level if any
        if excessXP < 0 then
          AddXP(playerId, -excessXP)
        end
      end
    else
      -- Sync XP if no level up occurred
      SyncPlayerDataByKey(playerId, "xp", playerData.xp)
    end
    
    -- Update database
    local updateQuery = "UPDATE " .. TAXIJOB_TABLE .. " SET `level` = '" .. playerData.level .. 
                       "', `xp` = '" .. playerData.xp .. 
                       "' WHERE `identifier` = '" .. identifier .. "'"
    ExecuteSql(updateQuery)
  end
end
