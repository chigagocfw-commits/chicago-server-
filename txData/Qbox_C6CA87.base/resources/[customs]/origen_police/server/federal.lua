-- Federal/Jail System
local FederalList = {}

-- Load federal prisoners from database on server start
Citizen.CreateThread(function()
  local prisoners = MySQL.awaitQuery("SELECT * FROM origen_police_federal")
  
  for i = 1, #prisoners do
    local prisoner = prisoners[i]
    FederalList[prisoner.citizenid] = prisoner
  end
end)

-- Get Federal Data Callback
FW_CreateCallback("origen_police:callback:GetFederal", function(source, cb, citizenid)
  if not citizenid then
    local player = FW_GetPlayer(source)
    
    if player and player.PlayerData and player.PlayerData.citizenid then
      citizenid = player.PlayerData.citizenid
    else
      return cb({})
    end
  end
  
  cb(FederalList[citizenid] or {})
end)

-- Set Federal Status Event
RegisterServerEvent("origen_police:server:setfederal", function(jailTime, dangerLevel, joiningStation)
  local player = FW_GetPlayer(source)
  
  if not player or not player.PlayerData then
    return
  end
  
  if jailTime then
    -- Adding player to federal prison
    player.Functions.SetMetaData("federal", 1)
    local citizenid = player.PlayerData.citizenid
    
    if not FederalList[citizenid] then
      -- Get player image from database
      local table_name = Config.Framework == "esx" and "users" or "players"
      local column_name = Config.Framework == "esx" and "identifier" or "citizenid"
      
      local result = MySQL.awaitQuery(
        "SELECT image FROM " .. table_name .. " WHERE " .. column_name .. " = ?",
        {player.PlayerData.citizenid}
      )
      
      local image = result[1] and result[1].image or nil
      local fullName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
      
      -- Create federal record
      FederalList[citizenid] = {
        citizenid = player.PlayerData.citizenid,
        time = jailTime,
        initial = jailTime,
        name = fullName,
        date = os.time() * 1000,
        danger = dangerLevel or "NP",
        joinedfrom = joiningStation or "Mission Row",
        online = true,
        image = image
      }
      
      -- Insert into database
      MySQL.awaitInsert(
        "INSERT INTO origen_police_federal (citizenid, time, initial, name, danger, joinedfrom) VALUES (?, ?, ?, ?, ?, ?)",
        {
          player.PlayerData.citizenid,
          jailTime,
          jailTime,
          fullName,
          dangerLevel or "NP",
          joiningStation or "Mission Row"
        }
      )
    else
      -- Update existing record as online
      FederalList[citizenid].online = true
    end
  else
    -- Removing player from federal prison
    player.Functions.SetMetaData("federal", 0)
    local citizenid = player.PlayerData.citizenid
    
    FederalList[citizenid] = nil
    
    MySQL.awaitQuery(
      "DELETE FROM origen_police_federal WHERE citizenid = ?",
      {player.PlayerData.citizenid}
    )
    
    -- Create log for exit
    CreateLog({
      type = "Federal",
      embed = {
        title = Config.LogsTranslations.ExitFederal.title,
        description = Config.LogsTranslations.ExitFederal.message,
        color = 1791423
      },
      source = player.PlayerData.source
    })
  end
end)

-- Update Federal Time Event
RegisterServerEvent("origen_police:server:updatemins", function(newTime)
  local player = FW_GetPlayer(source)
  
  if not player or not player.PlayerData or not player.PlayerData.citizenid then
    return
  end
  
  local citizenid = player.PlayerData.citizenid
  
  if FederalList[citizenid] then
    FederalList[citizenid].time = newTime
    
    MySQL.awaitUpdate(
      "UPDATE origen_police_federal SET time = ? WHERE citizenid = ?",
      {newTime, player.PlayerData.citizenid}
    )
  end
end)

-- Jail Command Handler (shared function for all aliases)
local function JailCommandHandler(source, args)
  local player = FW_GetPlayer(source)
  
  if not player then
    return
  end
  
  -- Get target player ID based on framework
  local targetId = Config.Framework == "esx" and args.id or args[1]
  local targetPlayerId = tonumber(targetId)
  
  -- Security check: prevent jailing everyone
  if targetPlayerId == -1 then
    BanPlayer(source, "Trying to send everyone to jail")
    return
  end
  
  -- Distance check
  local officerPos = GetEntityCoords(GetPlayerPed(source))
  local targetPos = GetEntityCoords(GetPlayerPed(targetPlayerId))
  local distance = #(officerPos - targetPos)
  
  if distance > 50 then
    TriggerClientEvent(
      "origen_police:ShowNotification",
      source,
      "You can't send someone to jail if you're not near them."
    )
    return
  end
  
  -- Get jail time and danger level based on framework
  local jailTime = Config.Framework == "esx" and args.tiempo or args[2]
  local dangerLevel = Config.Framework == "esx" and args.dangerous or args[3]
  
  -- Check permissions
  local hasPermission = CanOpenTablet(player.PlayerData.job.name)[1]
  
  if not hasPermission then
    return
  end
  
  -- Check if on duty (framework specific)
  local isOnDuty = false
  
  if Config.Framework == "qbcore" then
    isOnDuty = player.PlayerData.job.onduty
  elseif Config.Framework == "esx" then
    isOnDuty = exports.origen_police:IsPlayerOnDuty(source)
  end
  
  if not isOnDuty then
    return
  end
  
  -- Get target player
  local targetPlayer = FW_GetPlayer(targetPlayerId)
  
  if not targetPlayer then
    TriggerClientEvent(
      "origen_police:ShowNotification",
      source,
      Config.Translations.PlayerNotConnected
    )
    return
  end
  
  -- Validate jail time
  if not tonumber(jailTime) then
    return
  end
  
  -- Send player to jail
  TriggerClientEvent(
    "origen_police:client:sendCitizenToFederal",
    source,
    targetPlayerId,
    tonumber(jailTime),
    dangerLevel
  )
  
  -- Trigger jail system if not using custom prison system
  if not Config.OwnPrisionSystem then
    TriggerClientEvent(
      "SetFederal",
      targetPlayerId,
      tonumber(jailTime),
      dangerLevel
    )
  end
  
  -- Create log entry
  local officerName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
  
  CreateLog({
    type = "Federal",
    embed = {
      title = Config.LogsTranslations.EnterFederal.title,
      description = string.format(
        Config.LogsTranslations.EnterFederal.message,
        jailTime,
        officerName
      ),
      color = 1791423
    },
    source = targetId
  })
end

-- Register jail commands with multiple aliases
RegisterCommand("celda", JailCommandHandler, false)  -- Spanish
RegisterCommand("jail", JailCommandHandler, false)   -- English
RegisterCommand("sendjail", JailCommandHandler, false) -- Alternative

-- Get Federal List Callback
FW_CreateCallback("origen_police:server:GetFederalList", function(source, cb)
  if Config.OwnPrisionSystem then
    cb(GetFederalList())
  else
    cb(FederalList)
  end
end)

-- Handle Player Disconnect
AddEventHandler("playerDropped", function(reason)
  local player = FW_GetPlayer(source)
  
  if player and player.PlayerData and player.PlayerData.citizenid then
    local citizenid = player.PlayerData.citizenid
    
    if FederalList[citizenid] then
      FederalList[citizenid].online = false
    end
  end
end)

-- Handle Player Unload Event
AddEventHandler("origen_police:client:OnPlayerUnload", function()
  local player = FW_GetPlayer(source)
  
  if not player or not player.PlayerData or not player.PlayerData.citizenid then
    return
  end
  
  local citizenid = player.PlayerData.citizenid
  
  if FederalList[citizenid] then
    FederalList[citizenid].online = false
  end
end)

-- Release Federal Prisoner Callback
FW_CreateCallback("origen_police:server:releasefederal", function(source, cb, prisonerData)
  local player = FW_GetPlayerFromCitizenid(prisonerData.citizenid)
  
  -- Use custom prison system if enabled
  if Config.OwnPrisionSystem then
    return cb(ReleaseFederal(prisonerData.citizenid, player.PlayerData.source))
  end
  
  -- Release player from default system
  if player then
    TriggerClientEvent("SetFederal", player.PlayerData.source)
  end
  
  -- Remove from federal list
  FederalList[prisonerData.citizenid] = nil
  
  -- Delete from database
  MySQL.awaitQuery(
    "DELETE FROM origen_police_federal WHERE citizenid = ?",
    {prisonerData.citizenid}
  )
  
  cb(true)
end)