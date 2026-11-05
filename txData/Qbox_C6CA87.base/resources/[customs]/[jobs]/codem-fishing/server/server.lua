-- Global Variables
Core = nil
AllPlayerData = {}
PlayerBoat = {}
SelectedLocalesData = Locales[Config.Language]
ClassFish = {}

-- Default Daily Mission Template
local defaultDailyMissionTemplate = {}
local defaultDailyDeliveryTemplate = {}

-- Rate Limit Tracker
local caughtFishRateLimit = {}

-- Discord Bot Token
local discordBotToken = "Bot " .. (bot_Token or "")

-- Discord Avatar Cache
local discordCache = {
  Avatars = {}
}

-- Initialize Core Framework
CreateThread(function()
  local coreObject, frameworkName = GetCore()
  Config.Framework = frameworkName
  Core = coreObject
end)

-- Initialize Daily Mission Templates
Citizen.CreateThread(function()
  for missionKey, missionData in pairs(Config.DailyMission) do
    defaultDailyMissionTemplate[missionKey] = {
      complete = false,
      count = 0
    }
  end
end)

-- Initialize Daily Delivery Templates
Citizen.CreateThread(function()
  for deliveryKey, deliveryData in pairs(Config.DailyDelivery) do
    defaultDailyDeliveryTemplate[deliveryKey] = {
      complete = false
    }
  end
end)

-- Initialize Fish Classes
Citizen.CreateThread(function()
  for itemName, itemData in pairs(Config.Items) do
    if itemData.type == "fish" then
      table.insert(ClassFish, itemData)
    end
  end
end)

-- Load All Player Data from Database
Citizen.CreateThread(function()
  while Core == nil do
    Wait(0)
  end

  -- Delete old logs if configured
  if Config.DeleteLogsAfterDays > 0 then
    local cutoffTime = os.time() - (Config.DeleteLogsAfterDays * 24 * 60 * 60)

    local countQuery = [[
            SELECT COUNT(*) as count FROM codem_fishingjob_log WHERE last_update < @last_update
        ]]
    local countResult = ExecuteSql(countQuery, { ["@last_update"] = cutoffTime })

    if countResult and #countResult > 0 and countResult[1].count > 0 then
      local deleteQuery = [[
                DELETE FROM codem_fishingjob_log WHERE last_update < @last_update
            ]]
      local success, err = pcall(function()
        ExecuteSql(deleteQuery, { ["@last_update"] = cutoffTime })
      end)

      if success then
        print("^5 Fishing JOB SQL: Deleted", countResult[1].count, "log.^0")
      else
        print("Error deleting Last fishing job logs. Error: " .. tostring(err))
      end
    end
  end

  -- Load all player data
  local playerRecords = ExecuteSql("SELECT * FROM codem_fishingjob_player")

  if playerRecords then
    for i = 1, #playerRecords do
      local record = playerRecords[i]
      local identifier = record.identifier

      if not AllPlayerData[identifier] then
        AllPlayerData[identifier] = {}
      end

      AllPlayerData[identifier] = record
      AllPlayerData[identifier].dailymission = json.decode(record.dailymission)
      AllPlayerData[identifier].dailydelivery = json.decode(record.dailydelivery)
      AllPlayerData[identifier].latetest = {}
    end
  end

  -- Load log data
  local logRecords = ExecuteSql("SELECT * FROM codem_fishingjob_log")

  if logRecords then
    for i = 1, #logRecords do
      local logRecord = logRecords[i]
      local identifier = logRecord.identifier

      if AllPlayerData[identifier] then
        if not AllPlayerData[identifier].latetest then
          AllPlayerData[identifier].latetest = {}
        end

        local logData = json.decode(logRecord.log)
        table.insert(AllPlayerData[identifier].latetest, logData)
      end
    end
  end
end)

-- Calculate Leaderboard
function CalculateLeaderboardFishing(playerId)
  local leaderboard = {}
  local playerRank = nil
  local playerIdentifier = GetIdentifier(playerId)

  for identifier, playerData in pairs(AllPlayerData) do
    playerData.level = tonumber(playerData.level)

    if playerData.level then
      table.insert(leaderboard, {
        name = playerData.name,
        profilephoto = playerData.profilephoto,
        xp = playerData.xp,
        level = playerData.level,
        identifier = playerData.identifier
      })
    end
  end

  -- Sort by level (descending), then by XP (descending)
  table.sort(leaderboard, function(a, b)
    local levelA = tonumber(a.level)
    local levelB = tonumber(b.level)

    if levelA == levelB then
      return tonumber(a.xp) > tonumber(b.xp)
    else
      return levelA > levelB
    end
  end)

  -- Find player rank
  for rank, entry in ipairs(leaderboard) do
    if entry.identifier == playerIdentifier then
      playerRank = rank
      break
    end
  end

  -- Get top 10
  local top10 = {}
  for i = 1, math.min(10, #leaderboard), 1 do
    top10[i] = leaderboard[i]
  end

  TriggerClientEvent("codem-fishing:loadtop10", playerId, top10, playerRank)
end

-- Check and Reset Daily Timestamp
function CheckAndResetTimestamp(timestamp)
  local resetTime = timestamp + 86400
  local currentTime = os.time()
  local remainingHours = (resetTime - currentTime) / 3600
  local shouldReset = resetTime < currentTime

  return shouldReset, remainingHours
end

-- Check Daily Mission Time
function CheckTime(identifier, dailyMission)
  local shouldReset, remainingHours = CheckAndResetTimestamp(dailyMission.timestamp)

  if shouldReset then
    Citizen.Wait(500)
    dailyMission.timestamp = os.time()
    dailyMission.remainingtime = 24
    dailyMission.missions = defaultDailyMissionTemplate

    local updateQuery = [[
            UPDATE codem_fishingjob_player SET dailymission = ?
            WHERE identifier = ?
        ]]
    local params = { json.encode(dailyMission), identifier }

    local success, err = pcall(function()
      CodemSQLQuery(updateQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end
  else
    dailyMission.remainingtime = remainingHours
  end

  return dailyMission
end

-- Check Daily Delivery Time
function CheckTimeDelivery(identifier, dailyDelivery)
  local shouldReset, remainingHours = CheckAndResetTimestamp(dailyDelivery.timestamp)

  if shouldReset then
    Citizen.Wait(500)
    dailyDelivery.timestamp = os.time()
    dailyDelivery.remainingtime = 24
    dailyDelivery.missions = defaultDailyDeliveryTemplate

    local updateQuery = [[
            UPDATE codem_fishingjob_player SET dailydelivery = ?
            WHERE identifier = ?
        ]]
    local params = { json.encode(dailyDelivery), identifier }

    local success, err = pcall(function()
      CodemSQLQuery(updateQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end
  else
    dailyDelivery.remainingtime = remainingHours
  end

  return dailyDelivery
end

-- Register Callbacks
Citizen.CreateThread(function()
  while Core == nil do
    Wait(0)
  end

  -- Check Money Callback
  RegisterCallback("codem-fishingjob:checkmoney", function(source, cb, vehicleName)
    local playerId = source
    local player = GetPlayer(playerId)
    if not player then return end

    local identifier = GetIdentifier(playerId)
    if not identifier then return end

    -- Validate vehicle exists in config
    local vehicleExists = false
    for _, boatData in pairs(Config.BoatRent) do
      if boatData.name == vehicleName then
        vehicleExists = true
        break
      end
    end

    if not vehicleExists then
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.vehiclenotfound)
      cb(false)
      return
    end

    local playerData = AllPlayerData[identifier]
    if not playerData then return end

    -- Get vehicle price
    local vehiclePrice = 0
    for _, boatData in pairs(Config.BoatRent) do
      if boatData.name == vehicleName then
        vehiclePrice = boatData.price
        break
      end
    end

    -- Check player balance
    local playerBank = GetPlayerMoney(playerId, "bank")
    if tonumber(playerBank) < tonumber(vehiclePrice) then
      cb(false)
      return
    end

    -- Check if player already has a rented boat
    if PlayerBoat[identifier] then
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.alreadyrent)
      cb(false)
      return
    end

    -- Remove money and mark boat as rented
    RemoveMoney(playerId, "bank", vehiclePrice)
    PlayerBoat[identifier] = vehicleName
    cb(true)
  end)

  -- Get Player Money Callback
  RegisterCallback("codem-fishingjob:GetPlayerMoney", function(source, cb)
    local playerId = source
    local player = GetPlayer(playerId)
    if not player then return end

    local identifier = GetIdentifier(playerId)
    if not identifier then return end

    local playerData = AllPlayerData[identifier]
    if not playerData then return end

    local cash = GetPlayerMoney(playerId, "cash")
    local bank = GetPlayerMoney(playerId, "bank")

    cb({ cash = cash, bank = bank })
  end)
end)

-- Deposit Rent Price Event
RegisterServerEvent("codem-fishingjob:depositrentprice", function()
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end

  local identifier = GetIdentifier(playerId)
  if not identifier then return end

  if PlayerBoat[identifier] then
    local refundAmount = 0

    for _, boatData in pairs(Config.BoatRent) do
      if boatData.name == PlayerBoat[identifier] then
        refundAmount = boatData.price
        break
      end
    end

    -- Refund 50% of the price
    refundAmount = refundAmount / 2
    AddMoney(playerId, "bank", refundAmount)
    PlayerBoat[identifier] = nil
  else
    Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.vehiclenotrent)
  end
end)

-- Load Player Info Event
RegisterServerEvent("codem-fishingjob:LoadInfo", function()
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end

  local identifier = GetIdentifier(playerId)
  if not identifier then return end

  local playerData = AllPlayerData[identifier]

  if not playerData then
    -- Create new player data
    local discordAvatar = GetDiscordAvatar(playerId) or Config.DefaultProfilePicture

    local newPlayerData = {
      identifier = identifier,
      name = GetName(playerId),
      level = 1,
      xp = 0,
      profilephoto = discordAvatar,
      dailymission = {
        timestamp = os.time(),
        remainingtime = 24,
        missions = defaultDailyMissionTemplate
      },
      latetest = {},
      totalearnings = 0,
      totalfishes = 0,
      dailydelivery = {
        timestamp = os.time(),
        remainingtime = 24,
        missions = defaultDailyDeliveryTemplate
      }
    }

    AllPlayerData[identifier] = newPlayerData

    TriggerClientEvent("codem-fishingjob:LoadInfo", playerId, AllPlayerData[identifier])
    CalculateLeaderboardFishing(playerId)

    -- Insert into database
    local insertQuery = [[
            INSERT INTO codem_fishingjob_player (identifier, level, xp, dailymission, name, profilephoto, totalearnings, totalfishes, dailydelivery)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ]]
    local params = {
      identifier,
      newPlayerData.level,
      newPlayerData.xp,
      json.encode(newPlayerData.dailymission),
      newPlayerData.name,
      newPlayerData.profilephoto,
      newPlayerData.totalearnings,
      newPlayerData.totalfishes,
      json.encode(newPlayerData.dailydelivery)
    }

    local success, err = pcall(function()
      CodemSQLQuery(insertQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end
  else
    -- Update existing player data
    local updatedDailyMission = CheckTime(identifier, AllPlayerData[identifier].dailymission)
    local updatedDailyDelivery = CheckTimeDelivery(identifier, AllPlayerData[identifier].dailydelivery)

    local discordAvatar = GetDiscordAvatar(playerId) or Config.DefaultProfilePicture

    AllPlayerData[identifier].dailymission = updatedDailyMission
    AllPlayerData[identifier].dailydelivery = updatedDailyDelivery
    AllPlayerData[identifier].name = GetName(playerId)
    AllPlayerData[identifier].profilephoto = discordAvatar

    CalculateLeaderboardFishing(playerId)
    TriggerClientEvent("codem-fishingjob:LoadInfo", playerId, AllPlayerData[identifier])

    -- Update database
    local updateQuery = [[
            UPDATE codem_fishingjob_player SET name = ?, profilephoto = ?, dailymission = ?
            WHERE identifier = ?
        ]]
    local params = {
      AllPlayerData[identifier].name,
      discordAvatar,
      json.encode(AllPlayerData[identifier].dailymission),
      identifier
    }

    local success, err = pcall(function()
      CodemSQLQuery(updateQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end
  end
end)

-- Select Bait Event
RegisterServerEvent("codem-fishingjob:selectbait", function(baitItem)
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end
  if not baitItem then return end

  local baitConfig = Config.Items[baitItem]
  if not baitConfig then return end

  local identifier = GetIdentifier(playerId)
  local playerData = AllPlayerData[identifier]
  if not playerData then return end

  -- Check required level
  local requiredLevel = tonumber(baitConfig.requiredLevel)
  local playerLevel = tonumber(playerData.level)

  if requiredLevel > playerLevel then
    Config.ServerNotify(playerId, SelectedLocalesData.info,
      string.format(SelectedLocalesData.baitrequired, baitConfig.requiredLevel))
    return
  end

  -- Check if player has the bait item
  local inventory = GetPlayerInventory(playerId)
  local foundBait = false

  for _, item in pairs(inventory) do
    if item.name == baitItem then
      foundBait = true
      TriggerClientEvent("codem-fishingjob:selectbait", playerId, baitItem, item.label, item.amount)
      break
    end
  end

  if not foundBait then
    Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.inventoryitemnotfound)
    TriggerClientEvent("codem-fishingjob:stopfishing", playerId)
  end
end)

-- Stop Fishing Event
RegisterServerEvent("codem-fishingjob:stopfishing", function(baitItem)
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end

  local inventory = GetPlayerInventory(playerId)
  if not baitItem then return end

  local baitAmount = 0
  for _, item in pairs(inventory) do
    if item.name == baitItem then
      baitAmount = item.amount
      break
    end
  end

  if baitAmount > 0 then
    RemoveItem(playerId, baitItem, 1)

    if (baitAmount - 1) > 0 then
      TriggerClientEvent("codem-fishingjob:againfishingplayer", playerId, baitAmount - 1)
    else
      TriggerClientEvent("codem-fishingjob:stopfishing", playerId)
    end
  else
    TriggerClientEvent("codem-fishingjob:stopfishing", playerId)
    Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.inventoryitemnotfound)
  end
end)

-- Delivery Mission Event
RegisterServerEvent("codem-fishingjob:server:deliverymission", function(missionKey)
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end

  local identifier = GetIdentifier(playerId)
  if not identifier then return end

  local playerData = AllPlayerData[identifier]
  if not playerData then return end

  local deliveryConfig = Config.DailyDelivery[missionKey]
  if not deliveryConfig then return end

  -- Check if mission already completed
  local missionData = playerData.dailydelivery.missions[missionKey]
  if missionData and missionData.complete == true then
    Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.dailymissionalready)
    return
  end

  -- Get player inventory and count fish
  local inventory = GetPlayerInventory(playerId)
  local requiredClassName = deliveryConfig.fishtype .. "class"
  local requiredAmount = deliveryConfig.requiredAmount
  local totalFishCount = 0
  local fishToRemove = {}

  for _, item in pairs(inventory) do
    local itemConfig = Config.Items[item.name]
    if itemConfig and itemConfig.type == "fish" then
      if itemConfig.classname == requiredClassName then
        table.insert(fishToRemove, {
          name = item.name,
          amount = item.amount
        })
        totalFishCount = totalFishCount + (item.amount or 0)
      end
    end
  end

  -- Check if player has enough fish
  if requiredAmount > totalFishCount then
    local missingAmount = requiredAmount - totalFishCount
    Config.ServerNotify(playerId, SelectedLocalesData.info,
      string.format(SelectedLocalesData.requiredfishdelivery, missingAmount))
    return
  end

  -- Calculate which fish to remove
  local remainingToRemove = requiredAmount
  local itemsToRemove = {}

  for _, fishItem in ipairs(fishToRemove) do
    if remainingToRemove <= 0 then break end

    local removeAmount = math.min(fishItem.amount, remainingToRemove)
    table.insert(itemsToRemove, {
      name = fishItem.name,
      amount = removeAmount
    })
    remainingToRemove = remainingToRemove - removeAmount
  end

  -- Remove fish from inventory
  for _, item in ipairs(itemsToRemove) do
    RemoveItem(playerId, item.name, item.amount)
  end

  -- Mark mission as complete
  playerData.dailydelivery.missions[missionKey].complete = true

  -- Add reward money
  AddMoney(playerId, "bank", deliveryConfig.price)

  Config.ServerNotify(playerId, SelectedLocalesData.info,
    string.format(SelectedLocalesData.finishmission, Config.CurrencyUnit, deliveryConfig.price))
  TriggerClientEvent("codem-fishingjob:completedelivery", playerId, missionKey)

  -- Update database
  local updateQuery = [[
        UPDATE codem_fishingjob_player SET dailydelivery = ?
        WHERE identifier = ?
    ]]
  local params = { json.encode(playerData.dailydelivery), identifier }

  local success, err = pcall(function()
    CodemSQLQuery(updateQuery, params)
  end)

  if not success then
    print("Error: " .. tostring(err))
  end
end)

-- Market Event (Buy/Sell)
RegisterServerEvent("codem-fishingjob:market", function(marketData)
  local playerId = source
  local player = GetPlayer(playerId)
  if not player then return end

  local identifier = GetIdentifier(playerId)
  if not identifier then return end

  local inventory = GetPlayerInventory(playerId)

  -- SELL Logic
  if marketData.type == "sell" then
    local itemsToSell = marketData.items or {}
    local missingItems = {}
    local inventoryMap = {}

    -- Build inventory map
    for _, item in pairs(inventory) do
      inventoryMap[item.name] = item.amount or 0
    end

    -- Check for missing items
    for _, sellItem in pairs(itemsToSell) do
      local availableAmount = inventoryMap[sellItem.name] or 0
      local requestedAmount = tonumber(sellItem.amount)

      if availableAmount < requestedAmount then
        local missingAmount = requestedAmount - availableAmount
        table.insert(missingItems, {
          label = sellItem.label,
          missingAmount = missingAmount
        })
      end
    end

    if #missingItems > 0 then
      for _, missingItem in pairs(missingItems) do
        Config.ServerNotify(playerId, SelectedLocalesData.info,
          string.format(SelectedLocalesData.missingitems, missingItem.label, missingItem.missingAmount))
      end
    else
      local totalEarnings = 0
      local totalFishCount = 0

      -- Process sale
      for _, sellItem in pairs(itemsToSell) do
        local itemConfig = Config.Items[sellItem.name]
        if itemConfig then
          local itemPrice = tonumber(itemConfig.price) * tonumber(sellItem.amount)
          totalEarnings = totalEarnings + itemPrice

          RemoveItem(playerId, sellItem.name, sellItem.amount)
          totalFishCount = totalFishCount + sellItem.amount
        end
      end

      -- Add money to player
      AddMoney(playerId, marketData.value, totalEarnings)

      -- Update client with new money
      local cash = GetPlayerMoney(playerId, "cash")
      local bank = GetPlayerMoney(playerId, "bank")
      TriggerClientEvent("codem-fishingjob:updateplayermoney", playerId, { cash = cash, bank = bank })
      TriggerClientEvent("codem-fishingjob:refreshmarketbasket", playerId)

      -- Update player stats
      AllPlayerData[identifier].totalearnings = AllPlayerData[identifier].totalearnings + totalEarnings
      AllPlayerData[identifier].totalfishes = AllPlayerData[identifier].totalfishes + totalFishCount

      -- Discord log
      if Config.DiscordLog then
        SendDiscordLog(playerId, "sell", marketData.items, totalEarnings)
      end

      -- Save to latest activity
      SaveLatetest(identifier, {
        type = "marketsell",
        amounttype = "+",
        amount = totalEarnings,
        itemamount = totalFishCount,
        header = SelectedLocalesData.market,
        label = SelectedLocalesData.itemsold,
        icon = "market"
      }, playerId)

      UpdateFishSold(playerId, totalFishCount, totalEarnings)
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.itemsell)
      CheckDailyMission(playerId, identifier, "sellfish", totalFishCount)
    end
  end

  -- BUY Logic
  if marketData.type == "buy" then
    local totalCost = 0
    local totalItemCount = 0

    -- Calculate total cost
    for _, buyItem in pairs(marketData.items) do
      local itemConfig = Config.Items[buyItem.name]
      if itemConfig then
        local itemPrice = tonumber(itemConfig.price) * tonumber(buyItem.amount)
        totalCost = totalCost + itemPrice
      end
    end

    -- Check player balance
    local playerMoney = GetPlayerMoney(playerId, marketData.value)
    if tonumber(playerMoney) < tonumber(totalCost) then
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.notmoney)
      return
    end

    -- Add items to inventory
    for _, buyItem in pairs(marketData.items) do
      local itemConfig = Config.Items[buyItem.name]
      if itemConfig then
        AddItem(playerId, buyItem.name, buyItem.amount)
        totalItemCount = totalItemCount + buyItem.amount
      end
    end

    -- Remove money
    RemoveMoney(playerId, marketData.value, totalCost)

    -- Update client
    local cash = GetPlayerMoney(playerId, "cash")
    local bank = GetPlayerMoney(playerId, "bank")
    TriggerClientEvent("codem-fishingjob:updateplayermoney", playerId, { cash = cash, bank = bank })
    TriggerClientEvent("codem-fishingjob:refreshmarketbasket", playerId)

    -- Discord log
    if Config.DiscordLog then
      SendDiscordLog(playerId, "buy", marketData.items, totalCost)
    end

    -- Save to latest activity
    SaveLatetest(identifier, {
      type = "marketbuy",
      amounttype = "-",
      amount = totalCost,
      itemamount = totalItemCount,
      header = SelectedLocalesData.market,
      label = SelectedLocalesData.itembought,
      icon = "market"
    }, playerId)

    Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.itembuy)
  end
end)

-- Update Fish Sold Stats
function UpdateFishSold(playerId, fishCount, earnings)
  local identifier = GetIdentifier(playerId)
  local playerData = AllPlayerData[identifier]

  if not playerData then return end

  local totalFishes = playerData.totalfishes + fishCount
  local totalEarnings = playerData.totalearnings + earnings

  local updateQuery = [[
        UPDATE codem_fishingjob_player SET totalfishes = ? , totalearnings = ?
        WHERE identifier = ?
    ]]
  local params = { totalFishes, totalEarnings, identifier }

  local success, err = pcall(function()
    CodemSQLQuery(updateQuery, params)
  end)

  if not success then
    print("Error: " .. tostring(err))
  end

  TriggerClientEvent("codem-fishingjob:updatesold", playerId, totalFishes, totalEarnings)
end

-- Save Latest Activity
function SaveLatetest(identifier, logData, playerId)
  local playerData = AllPlayerData[identifier]
  if not playerData then return end

  local insertQuery = [[
        INSERT INTO codem_fishingjob_log (identifier, log, last_update)
        VALUES (?, ?, ?)
    ]]
  local params = { identifier, json.encode(logData), os.time() }

  local success, err = pcall(function()
    CodemSQLQuery(insertQuery, params)
  end)

  if not success then
    print("Error: " .. tostring(err))
  else
    table.insert(playerData.latetest, logData)
    TriggerClientEvent("codem-fishingjob:updatelatetest", playerId, logData)
  end
end

-- Caught Fish Event
RegisterServerEvent("codem-fishingjob:caughtfish", function(rodName, baitItem)
  local playerId = source

  -- Rate limiting
  if caughtFishRateLimit[playerId] then
    return
  else
    caughtFishRateLimit[playerId] = true
    SetTimeout(2000, function()
      caughtFishRateLimit[playerId] = nil
    end)
  end

  local identifier = GetIdentifier(playerId)
  local rodConfig = Config.Items[rodName]

  if not rodConfig then
    Config.ServerNotify(playerId, "Info", "Olta bulunamadı.")
    return
  end

  local inventory = GetPlayerInventory(playerId)

  -- Determine fish class based on catch rate
  local randomRoll = math.random(1, 100)
  local cumulativeChance = 0
  local fishClass = nil

  for _, catchRate in ipairs(rodConfig.catchRate) do
    cumulativeChance = cumulativeChance + catchRate.change
    if randomRoll <= cumulativeChance then
      fishClass = catchRate.class
      break
    end
  end

  if fishClass then
    -- Check bait amount
    local baitAmount = 0
    for _, item in pairs(inventory) do
      if item.name == baitItem then
        baitAmount = item.amount
        break
      end
    end

    if baitAmount > 0 then
      RemoveItem(playerId, baitItem, 1)
    else
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.inventoryitemnotfound)
      TriggerClientEvent("codem-fishingjob:stopfishing", playerId)
      return
    end

    -- Check bait effect for bonus fish
    local baitConfig = Config.Items[baitItem]
    local fishCount = 1

    for _, effect in pairs(baitConfig.baitEffect) do
      if effect.type == "fishcount" then
        local effectRoll = math.random(1, 100)
        if effectRoll <= effect.value then
          fishCount = effect.fishamount
          break
        end
      end
    end

    -- Find and give the fish
    for _, fishData in pairs(ClassFish) do
      if fishData.classname == (fishClass .. "class") then
        AddItem(playerId, fishData.name, fishCount)
        TriggerClientEvent("codem-fishingjob:caughtfish", playerId, fishData)
        AddXP(playerId, identifier)
        CheckDailyMission(playerId, identifier, "catchfish", fishCount, fishData.classname)
        break
      end
    end

    -- Check if more bait available
    if (baitAmount - 1) > 0 then
      TriggerClientEvent("codem-fishingjob:againfishing", playerId, baitAmount - 1)
    else
      Config.ServerNotify(playerId, SelectedLocalesData.info, SelectedLocalesData.inventoryitemnotfound)
      TriggerClientEvent("codem-fishingjob:stopfishing", playerId)
    end
  end
end)

-- Check Daily Mission Progress
function CheckDailyMission(playerId, identifier, missionType, count, fishClassName)
  local playerData = AllPlayerData[identifier]
  if not playerData then return end

  local dailyMission = playerData.dailymission
  local missionConfig = Config.DailyMission[missionType]

  if not missionConfig then return end

  local mission = dailyMission.missions[missionType]
  if mission and mission.complete then return end

  -- Check if fish class specific mission
  if Config.DailyMission[fishClassName] then
    local classMission = dailyMission.missions[fishClassName]
    if classMission and classMission.complete then return end

    classMission.count = classMission.count + count

    if classMission.count >= missionConfig.Count then
      classMission.complete = true
      AddXpCount(playerId, identifier, missionConfig.RewardXP)
      Config.ServerNotify(playerId, SelectedLocalesData.info,
        string.format(SelectedLocalesData.completedailymission, missionConfig.label, missionConfig.RewardXP))
    end

    TriggerClientEvent("codem-fishing:uptadedailymission", playerId, dailyMission)

    local updateQuery = [[
            UPDATE codem_fishingjob_player SET dailymission = ?
            WHERE identifier = ?
        ]]
    local params = { json.encode(dailyMission), identifier }

    local success, err = pcall(function()
      CodemSQLQuery(updateQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end

    playerData.dailymission = dailyMission
  else
    -- Generic mission type
    mission.count = mission.count + count

    if mission.count >= missionConfig.Count then
      mission.complete = true
      AddXpCount(playerId, identifier, missionConfig.RewardXP)
      Config.ServerNotify(playerId, SelectedLocalesData.info,
        string.format(SelectedLocalesData.completedailymission, missionConfig.label, missionConfig.RewardXP))
    end

    TriggerClientEvent("codem-fishing:uptadedailymission", playerId, dailyMission)

    local updateQuery = [[
             UPDATE codem_fishingjob_player SET dailymission = ?
             WHERE identifier = ?
         ]]
    local params = { json.encode(dailyMission), identifier }

    local success, err = pcall(function()
      CodemSQLQuery(updateQuery, params)
    end)

    if not success then
      print("Error: " .. tostring(err))
    end

    playerData.dailymission = dailyMission
  end
end

-- Discord API Request
function DiscordRequest(method, endpoint, data)
  local result = nil

  local callback = function(statusCode, responseBody, responseHeaders)
    result = {
      data = responseBody,
      code = statusCode,
      headers = responseHeaders
    }
  end

  local body = ""
  if #data > 0 then
    body = json.encode(data) or ""
  end

  PerformHttpRequest("https://discordapp.com/api/" .. endpoint, callback, method, body, {
    ["Content-Type"] = "application/json",
    ["Authorization"] = discordBotToken
  })

  while result == nil do
    Citizen.Wait(0)
  end

  return result
end

-- Get Discord Avatar
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
    if discordCache.Avatars[discordId] == nil then
      local endpoint = string.format("users/%s", discordId)
      local response = DiscordRequest("GET", endpoint, {})

      if response.code == 200 then
        local userData = json.decode(response.data)

        if userData ~= nil and userData.avatar ~= nil then
          local avatarPrefix = string.sub(userData.avatar, 1, 1)
          local avatarSecond = string.sub(userData.avatar, 2, 2)

          if avatarSecond == "_" then
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".gif"
          else
            avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".png"
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

-- Send Discord Log
function SendDiscordLog(playerId, actionType, items, totalAmount)
  if not Config.DiscordWebhook or Config.DiscordWebhook == "" then
    return
  end

  local playerName = GetName(playerId)
  local identifier = GetIdentifier(playerId)
  local identifiers = ExtractIdentifiers(playerId)

  local itemList = ""
  for _, item in pairs(items) do
    itemList = itemList .. string.format("- %s x%d\n", item.label or item.name, item.amount)
  end

  local actionTitle = actionType == "sell" and "Fish Sold" or "Items Purchased"
  local color = actionType == "sell" and 3066993 or 15158332

  local embed = {
    {
      ["title"] = actionTitle,
      ["description"] = string.format(
        "**Player:** %s\n**Identifier:** %s\n**Discord:** %s\n\n**Items:**\n%s\n**Total:** %s%d",
        playerName,
        identifier,
        identifiers.discord or "N/A",
        itemList,
        Config.CurrencyUnit,
        totalAmount
      ),
      ["color"] = color,
      ["footer"] = {
        ["text"] = "Fishing Job Log"
      },
      ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
  }

  PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, "POST", json.encode({
    username = "Fishing Job",
    embeds = embed
  }), { ["Content-Type"] = "application/json" })
end
