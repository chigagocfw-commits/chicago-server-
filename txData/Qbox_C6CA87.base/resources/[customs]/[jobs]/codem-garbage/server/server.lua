-- Codem Garbage Job - Server

Core = nil
cooldowns = {}
playerJobData = {}
coopData = {}

-- Initialize Core framework
Citizen.CreateThread(function()
  Core = GetCore()
end)

-- Load all player data from database on startup
Citizen.CreateThread(function()
  local allPlayerData = ExecuteSql("SELECT * FROM `codem_garbage`")
  for i = 1, #allPlayerData do
    local row = allPlayerData[i]
    local playerData = {
      profiledata = json.decode(row.profiledata),
      historydata = json.decode(row.historydata),
      dailymission = json.decode(row.dailymission)
    }
    if not playerJobData[row.identifier] then
      playerJobData[row.identifier] = playerData
    end
    playerJobData[row.identifier] = playerData
  end
end)

-- Event: Load garbage data for player
RegisterServerEvent("codem-garbage:loadData", function()
  local serverSource = source
  loadGarbageData(serverSource)
end)

-- Load garbage data for a specific player
function loadGarbageData(serverSource)
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    firsData(serverSource, function()
      playerData = playerJobData[identifier]
    end)
  end

  playerJobData[identifier] = playerData

  local profileData = playerJobData[identifier].profiledata
  local avatar = GetDiscordAvatar(serverSource)
  if not avatar then
    avatar = Config.ExampleProfilePicture
  end
  profileData.avatar = avatar

  local playerName = GetName(serverSource)
  profileData.name = playerName
  profileData.identifier = identifier

  Citizen.Wait(100)
  TriggerClientEvent("codem-garbage:client:loadnuidata", serverSource, playerData, coopData)
  savePlayerData(serverSource)
end

-- Check if 24 hours have passed and reset daily missions if needed
function checkAndResetTimestamp(timestamp)
  local endTime = timestamp + 86400
  local currentTime = os.time()
  local timeRemaining = endTime - currentTime
  local hoursRemaining = timeRemaining / 3600
  local isExpired = endTime < currentTime
  return isExpired, hoursRemaining
end

-- Check and manage daily mission time
function checkTime(serverSource)
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local dailyMission = playerData.dailymission
  local isExpired, hoursRemaining = checkAndResetTimestamp(dailyMission.timestamp)

  if isExpired then
    Citizen.Wait(500)
    dailyMission.timestamp = os.time()
    dailyMission.earninoneroute.count = 0
    dailyMission.earninoneroute.complete = false
    dailyMission.completeoneroute.count = 0
    dailyMission.completeoneroute.complete = false
    dailyMission.transportpassenger.count = 0
    dailyMission.transportpassenger.complete = false
    dailyMission.remainingtime = 24
    savePlayerData(serverSource)
  else
    dailyMission.remainingtime = hoursRemaining
  end

  return dailyMission
end

-- Register callback for getting player data
Citizen.CreateThread(function()
  while Core == nil do
    Citizen.Wait(0)
  end

  RegisterCallback("codem-garbage:getPlayerData", function(serverSource, cb, data)
    local identifier = GetIdentifier(serverSource)
    local playerData = playerJobData[identifier]

    if not playerData then
      firsData(serverSource, function()
        local responseData = {
          name = GetName(serverSource),
          allData = playerJobData[identifier],
          coopData = coopData
        }

        local dailyMission = checkTime(serverSource)
        if dailyMission then
          responseData.allData.dailymission = dailyMission
        end

        calculateLeaderboard(serverSource)
        cb(responseData)
      end)
    elseif playerData then
      local dailyMission = checkTime(serverSource)
      if dailyMission then
        playerJobData[identifier].dailymission = dailyMission
      end

      local responseData = {
        name = GetName(serverSource),
        allData = playerJobData[identifier],
        coopData = coopData
      }

      calculateLeaderboard(serverSource)
      cb(responseData)
    end
  end)
end)

-- Event: Kick player from lobby
RegisterServerEvent("codem-garbage:kickPlayer", function(kickData)
  local serverSource = source
  local targetIdentifier = kickData.identifier
  local targetPlayerData = playerJobData[targetIdentifier]

  if not targetPlayerData then
    return
  end

  local hostIdentifier = false

  -- Find the room that contains this player
  for roomId, roomData in pairs(coopData) do
    local players = roomData.players
    for _, player in pairs(players) do
      if tonumber(player.src) == tonumber(kickData.src) then
        hostIdentifier = roomData.roomData.hostIdentifier
      end
    end
  end

  if not hostIdentifier then
    return
  end

  local room = coopData[hostIdentifier]
  local players = room.players

  for playerIndex, player in pairs(players) do
    if tonumber(player.src) == tonumber(kickData.src) then
      if player.host then
        -- Host is leaving - delete the room
        for _, roomPlayer in pairs(players) do
          if tonumber(roomPlayer.src) then
            TriggerClientEvent("codem-garbage:deleteRoom", tonumber(roomPlayer.src), hostIdentifier)
          end
        end
        coopData[hostIdentifier] = nil
        Citizen.Wait(150)
        TriggerClientEvent("codem-garbage:deleteroomeveryone", -1, hostIdentifier)
      else
        -- Non-host is leaving - remove from room
        table.remove(players, playerIndex)
        coopData[hostIdentifier].players = players

        for _, roomPlayer in pairs(players) do
          if tonumber(roomPlayer.src) ~= tonumber(kickData.src) then
            TriggerClientEvent("codem-garbage:updateClientRoomPlayersData", -1, hostIdentifier,
              coopData[hostIdentifier].players)
          end
        end
        TriggerClientEvent("codem-garbage:deleteMyTeam", kickData.src, hostIdentifier, serverSource)
      end
    end
  end
end)

-- Event: Join lobby with password
RegisterServerEvent("codem-gabage:joinLobbyPassword", function(joinData)
  local serverSource = source

  -- Cooldown check
  if cooldowns[serverSource] then
    local timePassed = os.time() - cooldowns[serverSource]
    if timePassed < 5 then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.waitcooldown)
      return
    end
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local room = coopData[joinData.roomdata.hostIdentifier]
  if not room then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.undefinedroom)
    return
  end

  local players = room.players

  -- Check if already in room
  for _, player in pairs(players) do
    if tonumber(player.src) == tonumber(serverSource) then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.ingame)
      return
    end
  end

  -- Verify password
  if joinData.password == room.roomData.password then
    local newPlayer = {
      name = GetName(serverSource),
      avatar = GetDiscordAvatar(serverSource) or Config.ExampleProfilePicture,
      src = serverSource,
      identifier = identifier,
      host = false,
      level = playerData.profiledata.level
    }

    table.insert(players, newPlayer)
    coopData[joinData.roomdata.hostIdentifier].players = players
    TriggerClientEvent("codem-garbage:updateClientRoomPlayersData", -1, joinData.roomdata.hostIdentifier,
      coopData[joinData.roomdata.hostIdentifier].players)
  else
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.wrongpassword)
  end

  cooldowns[serverSource] = os.time()
end)

-- Event: Take badge
RegisterServerEvent("codem-garbage:takeBadge", function(badgeData)
  local serverSource = source

  -- Cooldown check
  if cooldowns[serverSource] then
    local timePassed = os.time() - cooldowns[serverSource]
    if timePassed < 5 then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.waitcooldown)
      return
    end
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local currentBadge = playerData.profiledata.badge
  if currentBadge == badgeData.name then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.alreadybadge)
  end

  local playerLevel = tonumber(playerData.profiledata.level)
  local requiredLevel = tonumber(badgeData.level)

  if playerLevel < requiredLevel then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.levelbadge)
    return
  end

  playerData.profiledata.badge = badgeData.name
  TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.badgeget)
  savePlayerData(serverSource)
end)

-- Event: Update lobbies
RegisterServerEvent("codem-garbage:updateLobbys", function(lobbyData)
  TriggerClientEvent("codem-garbage:updateLobbys", -1, lobbyData)
end)

-- Event: Update area for all players in room
RegisterServerEvent("codem-gabage:updateArea", function(areaData)
  local serverSource = source
  local identifier = GetIdentifier(serverSource)
  local room = coopData[identifier]
  local players = room.players

  for _, player in pairs(players) do
    if player.src and player.src ~= serverSource then
      TriggerClientEvent("codem-garbage:client:UpdateArea", tonumber(player.src), areaData)
    end
  end
end)

-- Event: Join lobby without password
RegisterServerEvent("codem-gabage:joinLobby", function(joinData)
  local serverSource = source

  -- Cooldown check
  if cooldowns[serverSource] then
    local timePassed = os.time() - cooldowns[serverSource]
    if timePassed < 5 then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.waitcooldown)
      return
    end
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local room = coopData[joinData.roomData.hostIdentifier]
  if not room then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.undefinedroom)
    return
  end

  local players = room.players

  -- Check if room is full
  if #players >= 4 then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.lobbyfull)
    return
  end

  -- Check if mission already started
  if room.roomData.startMission then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.cantjointhis)
    return
  end

  -- Check if already in room
  for _, player in pairs(players) do
    if tonumber(player.src) == tonumber(serverSource) then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.ingame)
      return
    end
  end

  local newPlayer = {
    name = GetName(serverSource),
    avatar = GetDiscordAvatar(serverSource) or Config.ExampleProfilePicture,
    src = serverSource,
    identifier = identifier,
    host = false,
    level = playerData.profiledata.level
  }

  table.insert(players, newPlayer)
  coopData[joinData.roomData.hostIdentifier].players = players
  TriggerClientEvent("codem-garbage:updateClientRoomPlayersData", -1, joinData.roomData.hostIdentifier,
    coopData[joinData.roomData.hostIdentifier].players)

  cooldowns[serverSource] = os.time()
end)

-- Event: Start multiplayer job
RegisterServerEvent("codem-garbage:startJobMultiplayer", function(jobData)
  local serverSource = source

  -- Cooldown check
  if cooldowns[serverSource] then
    local timePassed = os.time() - cooldowns[serverSource]
    if timePassed < 5 then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.waitcooldown)
      return
    end
  end

  local routeName = jobData.routename
  local garbageStops = Config.GarbagejobSettings.garbageStop[routeName]

  local identifier = GetIdentifier(serverSource)
  local room = coopData[identifier]

  if not room then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.undefinedroom)
    return
  end

  local players = room.players

  if #players > 4 then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.lobbyfull)
    return
  end

  if #players <= 1 then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.minplayer)
    return
  end

  if garbageStops then
    room.roomData.startMission = true

    -- Create garbage truck vehicle
    local spawnCoords = Config.GarbagejobSettings.garbageTruckSpawnCoords[1]
    local garbageTruck = CreateVehicle(
      GetHashKey(Config.GarbagejobSettings.trashvehicle),
      spawnCoords.x,
      spawnCoords.y,
      spawnCoords.z,
      spawnCoords.w,
      true,
      true
    )

    -- Wait for vehicle to spawn
    while not DoesEntityExist(garbageTruck) do
      Wait(0)
    end

    TriggerClientEvent("codem-garbage:setDriverData", serverSource)
    cooldowns[serverSource] = os.time()
    Citizen.Wait(1000)

    -- Notify all players in the room
    for _, player in pairs(players) do
      if player.src then
        TriggerClientEvent(
          "codem-garbage:startMultiplayerJob",
          tonumber(player.src),
          garbageStops,
          NetworkGetNetworkIdFromEntity(garbageTruck),
          routeName
        )
      end
    end
  else
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.notroute)
  end
end)

-- Event: Leave lobby
RegisterServerEvent("codem-garbage:leaveLobby", function(leaveData)
  local serverSource = source

  -- Cooldown check
  if cooldowns[serverSource] then
    local timePassed = os.time() - cooldowns[serverSource]
    if timePassed < 5 then
      TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.waitcooldown)
      return
    end
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.notplayerdata)
    return
  end

  local room = coopData[leaveData.hostIdentifier]
  if not room then
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.undefinedroom)
    return
  end

  local players = room.players

  for playerIndex, player in pairs(players) do
    if tonumber(player.src) == tonumber(serverSource) then
      if leaveData.hostIdentifier ~= identifier then
        -- Non-host leaving
        table.remove(players, playerIndex)
        coopData[leaveData.hostIdentifier].players = players

        for _, roomPlayer in pairs(players) do
          if tonumber(roomPlayer.src) ~= tonumber(serverSource) then
            TriggerClientEvent("codem-garbage:updateClientRoomPlayersData", -1, leaveData.hostIdentifier,
              coopData[leaveData.hostIdentifier].players)
          end
        end
        TriggerClientEvent("codem-garbage:deleteMyTeam", serverSource, leaveData.hostIdentifier, serverSource)
        break
      end

      -- Host leaving - delete the room
      for _, roomPlayer in pairs(players) do
        if tonumber(roomPlayer.src) then
          TriggerClientEvent("codem-garbage:deleteRoom", tonumber(roomPlayer.src), leaveData.hostIdentifier)
        end
      end
      coopData[leaveData.hostIdentifier] = nil
      Citizen.Wait(150)
      TriggerClientEvent("codem-garbage:deleteroomeveryone", -1, leaveData.hostIdentifier)
      break
    end
  end

  cooldowns[serverSource] = os.time()
end)

-- Event: Insert online job data (create lobby)
RegisterServerEvent("codem-garbage:onlineJobsInsertData", function(roomCreateData)
  local serverSource = source
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local existingRoom = coopData[identifier]

  if not existingRoom then
    -- Create new room
    coopData[identifier] = {
      roomData = {
        roomName = roomCreateData[1].name,
        password = roomCreateData[1].password,
        areaName = roomCreateData[1].areaName,
        hostIdentifier = identifier,
        startMission = false
      },
      players = {
        {
          name = GetName(serverSource),
          avatar = roomCreateData[1].avatar,
          src = serverSource,
          identifier = identifier,
          host = true,
          level = roomCreateData[1].level
        }
      }
    }

    TriggerClientEvent("codem-garbage:insertOnlineData", -1, roomCreateData, serverSource, identifier,
      GetName(serverSource))
  else
    TriggerClientEvent("codem-garbage:notificaton", serverSource, Config.Locales.lobbyopened)
  end
end)

-- Calculate leaderboard and send top 50
function calculateLeaderboard(serverSource)
  local levelGroups = {}

  -- Group players by level
  for _, playerData in pairs(playerJobData) do
    local profile = playerData.profiledata
    if profile.level then
      if not levelGroups[profile.level] then
        levelGroups[profile.level] = {}
      end
      table.insert(levelGroups[profile.level], {
        name = profile.name,
        avatar = profile.avatar,
        xp = profile.xp,
        level = profile.level,
        badge = profile.badge
      })
    end
  end

  -- Get all levels and sort descending
  local levels = {}
  for level in pairs(levelGroups) do
    table.insert(levels, level)
  end
  table.sort(levels, function(a, b) return a > b end)

  -- Flatten into sorted leaderboard
  local leaderboard = {}
  for _, level in ipairs(levels) do
    table.sort(levelGroups[level], function(a, b) return a.xp > b.xp end)
    for _, player in ipairs(levelGroups[level]) do
      table.insert(leaderboard, player)
    end
  end

  -- Get top 50
  local top50 = {}
  for i = 1, math.min(50, #leaderboard) do
    top50[i] = leaderboard[i]
  end

  TriggerClientEvent("codem-garbage:top50", serverSource, top50)
end

-- Initialize new player data
function firsData(serverSource, callback)
  local identifier = GetIdentifier(serverSource)

  if not identifier then return end

  if playerJobData[identifier] then
    return
  end

  local newPlayerData = {
    identifier = identifier,
    historydata = {},
    profiledata = {
      xp = 0,
      level = 1,
      avatar = GetDiscordAvatar(serverSource) or Config.ExampleProfilePicture,
      name = GetName(serverSource),
      completejobs = 0,
      totalearnings = 0,
      gathered = 0,
      sincedate = os.date("%d.%m.%Y"),
      identifier = identifier,
      badge = false
    },
    dailymission = {
      timestamp = os.time(),
      remainingtime = 24,
      transportpassenger = { complete = false, count = 0 },
      completeoneroute = { complete = false, count = 0 },
      earninoneroute = { complete = false, count = 0 }
    }
  }

  Citizen.Wait(100)
  playerJobData[identifier] = newPlayerData

  ExecuteSql(
    "INSERT INTO codem_garbage (identifier, profiledata, historydata, dailymission) VALUES (:identifier, :profiledata, :historydata, :dailymission) ",
    {
      identifier = identifier,
      profiledata = json.encode(newPlayerData.profiledata),
      historydata = json.encode(newPlayerData.historydata),
      dailymission = json.encode(newPlayerData.dailymission)
    }
  )

  playerJobData[identifier].dailymission.timestamp = os.time()
  callback()
end

-- Save player data to database
function savePlayerData(serverSource)
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  ExecuteSql(
    "UPDATE codem_garbage SET profiledata = :profiledata, historydata = :historydata, dailymission = :dailymission WHERE identifier = :identifier",
    {
      identifier = identifier,
      profiledata = json.encode(playerData.profiledata),
      historydata = json.encode(playerData.historydata),
      dailymission = json.encode(playerData.dailymission)
    }
  )
end

-- Add XP to player
function AddXPGarbabgeJob(serverSource, xpAmount)
  if not xpAmount or xpAmount <= 0 then
    return
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local profile = playerData.profiledata
  profile.xp = tonumber(profile.xp) + tonumber(xpAmount)

  local currentLevel = profile.level
  local maxLevel = #Config.RequiredXP

  if currentLevel > maxLevel then
    Config.Notification(
      Config.NotificationText.maxlevel.text,
      Config.NotificationText.maxlevel.type,
      true,
      serverSource
    )
    return
  end

  local requiredXP = tonumber(Config.RequiredXP[profile.level])

  if tonumber(profile.xp) >= requiredXP then
    profile.level = tonumber(profile.level) + 1
    profile.xp = 0
  end

  Config.Notification(
    string.format(Config.NotificationText.newxp.text, xpAmount),
    Config.NotificationText.newxp.type,
    true,
    serverSource
  )
end

-- Set XP for player (used internally)
function SetXPBusJob(serverSource, xpAmount)
  if not xpAmount or xpAmount <= 0 then
    return
  end

  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local profile = playerData.profiledata
  profile.xp = tonumber(xpAmount)

  local requiredXP = tonumber(Config.RequiredXP[profile.level])

  if tonumber(profile.xp) >= requiredXP then
    profile.level = tonumber(profile.level) + 1
    profile.xp = 0
  end
end

-- Add levels to player
function AddLevelGarbageJob(serverSource, newLevel)
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local profile = playerData.profiledata
  local currentLevel = profile.level
  local maxLevel = #Config.RequiredXP

  if currentLevel > maxLevel then
    Config.Notification(
      Config.NotificationText.maxlevel.text,
      Config.NotificationText.maxlevel.type,
      true,
      serverSource
    )
    return
  end

  profile.level = newLevel

  if not Config.RequiredXP[profile.level] then
    profile.level = #Config.RequiredXP
    profile.xp = Config.RequiredXP[profile.level]
  else
    profile.xp = 0
  end
end

-- Remove levels from player
function RemoveLevelGarbageJob(serverSource, levelsToRemove)
  local identifier = GetIdentifier(serverSource)
  local playerData = playerJobData[identifier]

  if not playerData then
    return
  end

  local profile = playerData.profiledata

  if levelsToRemove <= 0 then
    levelsToRemove = 1
  end

  profile.level = tonumber(profile.level) - levelsToRemove

  if profile.level <= 0 then
    profile.level = 1
  end

  profile.xp = 0
end

-- Discord integration
local discordCache = {
  Avatars = {}
}
local botToken = "Bot " .. (bot_Token or "")

-- Make Discord API request
function DiscordRequest(method, endpoint, body)
  local result = nil

  PerformHttpRequest(
    "https://discordapp.com/api/" .. endpoint,
    function(code, data, headers)
      result = {
        data = data,
        code = code,
        headers = headers
      }
    end,
    method,
    (#body > 0) and json.encode(body) or "",
    {
      ["Content-Type"] = "application/json",
      Authorization = botToken
    }
  )

  while result == nil do
    Citizen.Wait(0)
  end

  return result
end

-- Get Discord avatar for player
function GetDiscordAvatar(serverSource)
  local discordId = nil
  local avatarUrl = nil

  -- Find Discord identifier
  for _, identifier in ipairs(GetPlayerIdentifiers(serverSource)) do
    if string.match(identifier, "discord:") then
      discordId = string.gsub(identifier, "discord:", "")
      break
    end
  end

  if discordId then
    if discordCache.Avatars[discordId] == nil then
      local endpoint = string.format("users/%s", discordId)
      local response = DiscordRequest("GET", endpoint, {})

      if response.code == 200 then
        local userData = json.decode(response.data)
        if userData ~= nil and userData.avatar ~= nil then
          local avatar = userData.avatar
          local firstTwoChars = avatar:sub(1, 2)

          if firstTwoChars and firstTwoChars:sub(2, 2) == "_" then
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. avatar .. ".gif"
          else
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. avatar .. ".png"
          end
        end
      end
      discordCache.Avatars[discordId] = avatarUrl
    else
      avatarUrl = discordCache.Avatars[discordId]
    end
  end

  return avatarUrl
end
