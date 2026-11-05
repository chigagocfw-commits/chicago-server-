Core = nil
playersData = {}
local resourceSecurityKey = nil

CreateThread(function()
  local coreObject, frameworkName = GetCore()
  Config.Framework = frameworkName
  Core = coreObject
  
  local randomPart1 = math.random(10000, 999999999)
  local randomPart2 = math.random(10000, 999999999)
  resourceSecurityKey = "CODEM-miner" .. randomPart1 .. "saas" .. randomPart2 .. "KEY"
  
  RegisterCallback("codem-minerjob:getKey", function(source, callback)
    callback(resourceSecurityKey)
  end)
  
  local dbResult = ExecuteSql("SELECT * FROM codem_minerjob")
  playersData = dbResult
  
  for _, playerRecord in pairs(playersData) do
    playerRecord.dailyMissions = json.decode(playerRecord.dailyMissions)
    playerRecord.latestWorks = json.decode(playerRecord.latestWorks)
    
    local playerSource = GetPlayerSourceByIdentifier(playerRecord.identifier)
    if playerSource then
      TriggerClientEvent("codem-minerjob:Load", playerSource, playerRecord)
    end
  end
  
  RegisterCallback("codem-minerjob:GetItems", function(source, callback)
    local inventory = GetPlayerInventory(source)
    callback(inventory)
  end)
  
  RegisterCallback("codem-minerjob:GetLeaderboard", function(source, callback)
    table.sort(playersData, function(playerA, playerB)
      return playerA.level > playerB.level
    end)
    
    local requestingIdentifier = GetIdentifier(source)
    local result = {
      data = {},
      playerOrder = false
    }
    
    local index = 1
    for _, playerInfo in pairs(playersData) do
      if index <= 8 then
        table.insert(result.data, playerInfo)
      end
      if playerInfo.identifier == requestingIdentifier then
        result.playerOrder = index
      end
      index = index + 1
    end
    
    callback(result)
  end)
  
  RegisterCallback("codem-minerjob:getMoney", function(source, callback)
    local cash = GetPlayerMoney(source, "cash")
    callback(cash)
  end)
  
  RegisterCallback("codem-minerjob:HasItem", function(source, callback, itemData)
    local hasItem = HasItem(source, itemData)
    callback(hasItem)
  end)
end)

function AddLatestWork(source, labelText, titleText, placeText)
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  
  if jobData then
    local newWork = {
      label = labelText,
      title = titleText,
      place = placeText,
      time = os.time()
    }
    table.insert(jobData.latestWorks, newWork)
    
    local encodedWorks = json.encode(jobData.latestWorks)
    ExecuteSql("UPDATE codem_minerjob SET `latestWorks` = '" .. encodedWorks .. "' WHERE `identifier` = '" .. identifier .. "'")
    
    SyncPlayerDataByKey(source, "latestWorks", jobData.latestWorks)
  end
end

RegisterServerEvent("codem-minerjob:AddLatestWork")
AddEventHandler("codem-minerjob:AddLatestWork", function(label, title, place)
  local source = source
  AddLatestWork(source, label, title, place)
end)

function GetPlayerJobData(identifier)
  for _, data in pairs(playersData) do
    if data.identifier == identifier then
      return data
    end
  end
  return nil
end

RegisterServerEvent("codem-minerjob:GiveItems")
AddEventHandler("codem-minerjob:GiveItems", function(itemName, clientKey)
  local source = source
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  
  if clientKey ~= resourceSecurityKey then
    print("Player " .. source .. " tried to execute pay trigger")
    return
  end
  
  AddInventoryItem(source, itemName, 1)
  
  if jobData then
    local xpAmount = Config.GiveXP.collectMine
    AddXP(source, xpAmount)
    jobData.gatheredOres = jobData.gatheredOres + 1
  end
  
  TriggerClientEvent("codem-minerjob:AddItemLog", source, itemName)
end)

AddEventHandler("playerDropped", function()
  local source = source
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  
  if jobData then
    ExecuteSql("UPDATE codem_minerjob SET `gatheredOres` = '" .. jobData.gatheredOres .. "' WHERE `identifier` = '" .. identifier .. "'")
    ExecuteSql("UPDATE codem_minerjob SET `level` = '" .. jobData.level .. "', `xp` = '" .. jobData.xp .. "' WHERE `identifier` = '" .. identifier .. "'")
  end
end)

RegisterServerEvent("codem-minerjob:OnMenuOpen")
AddEventHandler("codem-minerjob:OnMenuOpen", function()
  local source = source
  CreatePlayerData(source)
  
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  
  if jobData then
    SyncPlayerDataByKey(source, "gatheredOres", jobData.gatheredOres)
  end
end)

function CreatePlayerData(source)
  local identifier = GetIdentifier(source)
  local avatarUrl = GetDiscordAvatar(source)
  local checkQuery = "SELECT * FROM codem_minerjob WHERE identifier = @identifier"
  local existingData = ExecuteSql(checkQuery, { ["@identifier"] = identifier })
  
  if existingData[1] then
    local jobData = GetPlayerJobData(identifier)
    if jobData then
      if not jobData.avatar then
        jobData.avatar = avatarUrl
        SyncPlayerDataByKey(source, "avatar", avatarUrl)
      end
    end
    return false
  end
  
  local rpName = GetPlayerRPName(source)
  local currentTimestamp = os.time()
  
  local dailyMissionsData = {
    data = CreateDailyMission(),
    resetAt = currentTimestamp + 86400
  }
  
  local newPlayerData = {
    identifier = identifier,
    xp = 0,
    level = 1,
    name = rpName,
    avatar = avatarUrl,
    gatheredOres = 0,
    createdAt = currentTimestamp,
    totalEarnings = 0,
    dailyMissions = dailyMissionsData,
    latestWorks = {},
    completedShipments = 0
  }
  
  local insertQuery = [[
    INSERT INTO codem_minerjob (
      identifier, xp, level, name, gatheredOres, createdAt, 
      totalEarnings, avatar, dailyMissions, latestWorks, completedShipments
    ) VALUES (
      :identifier, :xp, :level, :name, :gatheredOres, :createdAt, 
      :totalEarnings, :avatar, :dailyMissions, :latestWorks, :completedShipments
    )
  ]]
  
  ExecuteSql(insertQuery, {
    identifier = identifier,
    level = 1,
    xp = 0,
    name = rpName,
    gatheredOres = 0,
    createdAt = currentTimestamp,
    totalEarnings = 0,
    avatar = avatarUrl,
    dailyMissions = json.encode(dailyMissionsData),
    latestWorks = json.encode({}),
    completedShipments = 0
  })
  
  table.insert(playersData, newPlayerData)
  
  SyncPlayerDataByKey(source, "identifier", identifier)
  SyncPlayerDataByKey(source, "name", rpName)
  SyncPlayerDataByKey(source, "avatar", avatarUrl)
  SyncPlayerDataByKey(source, "createdAt", currentTimestamp)
  SyncPlayerDataByKey(source, "dailyMissions", dailyMissionsData)
end

function GetPlayerSourceByIdentifier(identifier)
  while Core == nil do
    Wait(0)
  end
  
  if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
    local player = Core.GetPlayerFromIdentifier(identifier)
    if player then
      return player.source
    end
  else
    local player = Core.Functions.GetPlayerByCitizenId(identifier)
    if player then
      return player.PlayerData.source
    end
  end
  return nil
end

function SyncPlayerDataByKey(source, key, value)
  TriggerClientEvent("codem-minerjob:SyncPlayerDataByKey", source, key, value)
end

RegisterServerEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function(source)
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  if jobData then
    TriggerClientEvent("codem-minerjob:Load", source, jobData)
  end
end)

RegisterServerEvent("QBCore:Server:OnPlayerLoaded")
AddEventHandler("QBCore:Server:OnPlayerLoaded", function()
  local source = source
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  if jobData then
    TriggerClientEvent("codem-minerjob:Load", source, jobData)
  end
end)

RegisterServerEvent("codem-minerjob:ShipOrder")
AddEventHandler("codem-minerjob:ShipOrder", function(shipmentData)
  local source = source
  local player = GetPlayer(source)
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  
  local hasRequiredItems = true
  
  local primaryItem = {
    name = shipmentData.itemname,
    amount = shipmentData.itemamount
  }
  local hasPrimary = HasItem(source, primaryItem)
  if not hasPrimary then
    hasRequiredItems = false
  end
  
  if shipmentData.item2name then
    local secondaryItem = {
      name = shipmentData.item2name,
      amount = shipmentData.item2amount
    }
    local hasSecondary = HasItem(source, secondaryItem)
    if not hasSecondary then
      hasRequiredItems = false
    end
  end
  
  if hasRequiredItems then
    RemoveItem(source, shipmentData.itemname, shipmentData.itemamount)
    
    if shipmentData.item2name then
      RemoveItem(source, shipmentData.item2name, shipmentData.item2amount)
    end
    
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
      player.addMoney(shipmentData.offer)
    else
      player.Functions.AddMoney("cash", shipmentData.offer)
    end
    
    local itemLabel = itemLabels[shipmentData.itemname]
    local workLabel = shipmentData.itemamount .. " " .. itemLabel .. " $" .. shipmentData.offer
    AddLatestWork(source, workLabel, "SHIPMENT", "Dock Shipment")
    
    if jobData then
      jobData.totalEarnings = jobData.totalEarnings + shipmentData.offer
      SyncPlayerDataByKey(source, "totalEarnings", jobData.totalEarnings)
      ExecuteSql("UPDATE codem_minerjob SET `totalEarnings` = '" .. jobData.totalEarnings .. "' WHERE `identifier` = '" .. identifier .. "'")
      
      jobData.completedShipments = jobData.completedShipments + 1
      ExecuteSql("UPDATE codem_minerjob SET `completedShipments` = '" .. jobData.completedShipments .. "' WHERE `identifier` = '" .. identifier .. "'")
      SyncPlayerDataByKey(source, "completedShipments", jobData.completedShipments)
    end
    
    local message = string.format(locales.items_delivered, shipmentData.offer)
    TriggerClientEvent("codem-minerjob:Notify", source, message)
  else
    TriggerClientEvent("codem-minerjob:Notify", source, locales.not_enough_items)
  end
end)

function CalculateTotalCart(cartData)
  local total = 0
  for _, item in pairs(cartData) do
    local itemTotal = item.amount * item.price
    total = total + itemTotal
  end
  return total
end

RegisterServerEvent("codem-minerjob:BuyItems")
AddEventHandler("codem-minerjob:BuyItems", function(cartData, paymentMethod)
  local source = source
  local player = GetPlayer(source)
  local currentMoney = GetPlayerMoney(source, paymentMethod)
  local totalCost = CalculateTotalCart(cartData)
  
  if currentMoney >= totalCost then
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
      if paymentMethod == "cash" then
        player.removeMoney(totalCost)
      else
        player.removeAccountMoney("bank", totalCost)
      end
    else
      player.Functions.RemoveMoney(paymentMethod, totalCost)
    end
    
    local itemsString = ""
    for _, item in pairs(cartData) do
      local label = itemLabels[item.name]
      if label then
        itemsString = itemsString .. " " .. item.amount .. " " .. label
      end
    end
    
    local workLabel = itemsString .. " $" .. totalCost
    AddLatestWork(source, workLabel, "BUY", "Market Buy")
    
    Wait(300)
    TriggerClientEvent("codem-minerjob:GetCash", source)
    
    for _, item in pairs(cartData) do
      AddInventoryItem(source, item.name, item.amount)
    end
    
    TriggerClientEvent("codem-minerjob:Notify", source, locales.items_bought)
  else
    TriggerClientEvent("codem-minerjob:Notify", source, locales.not_enough_money)
  end
end)

RegisterServerEvent("codem-minerjob:SellItems")
AddEventHandler("codem-minerjob:SellItems", function(cartData)
  local source = source
  local player = GetPlayer(source)
  local identifier = GetIdentifier(source)
  local jobData = GetPlayerJobData(identifier)
  local totalPrice = CalculateTotalCart(cartData)
  
  local hasAllItems = true
  for _, item in pairs(cartData) do
    local hasItem = HasItem(source, item)
    if not hasItem then
      hasAllItems = false
    end
  end
  
  if hasAllItems then
    for _, item in pairs(cartData) do
      RemoveItem(source, item.name, item.amount)
    end
    
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
      player.addMoney(totalPrice)
    else
      player.Functions.AddMoney("cash", totalPrice)
    end
    
    local itemsString = ""
    for _, item in pairs(cartData) do
      local label = itemLabels[item.name]
      if label then
        itemsString = itemsString .. " " .. item.amount .. " " .. label
      end
    end
    
    local workLabel = itemsString .. " $" .. totalPrice
    AddLatestWork(source, workLabel, "SELL", "Market Sell")
    
    if jobData then
      jobData.totalEarnings = jobData.totalEarnings + totalPrice
      SyncPlayerDataByKey(source, "totalEarnings", jobData.totalEarnings)
      ExecuteSql("UPDATE codem_minerjob SET `totalEarnings` = '" .. jobData.totalEarnings .. "' WHERE `identifier` = '" .. identifier .. "'")
    end
    
    TriggerClientEvent("codem-minerjob:Notify", source, locales.items_sold)
    Wait(300)
    TriggerClientEvent("codem-minerjob:GetCash", source)
  else
    TriggerClientEvent("codem-minerjob:Notify", source, locales.not_enough_items)
  end
end)