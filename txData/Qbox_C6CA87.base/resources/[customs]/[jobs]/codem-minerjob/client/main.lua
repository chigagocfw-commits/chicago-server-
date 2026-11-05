local npcPedEntity = nil
local selectedMineArea = false
local miningToolObject = nil
local serverSecurityKey = false
local isCurrentlyMining = false
local isCurrentlyProcessing = false
local collectedOreItems = {}
local miningItemLogs = {}
local shipmentDeliveryActive = false
local processAreaBlip = nil
local spamProtectionTimer = false
local inputControlsDisabled = false
cam = false
local jobVehicle = nil

Core = nil
nuiReady = false

playerData = {
  identifier = false,
  level = 1,
  xp = 0,
  name = false,
  avatar = false,
  gatheredOres = 0,
  createdAt = false,
  totalEarnings = 0,
  latestWorks = {},
  dailyMissions = {
    data = {},
    resetAt = false
  }
}

CreateThread(function()
  local coreObject, frameworkName = GetCore()
  Config.Framework = frameworkName
  Core = coreObject
  
  local callbackKeyResult = TriggerCallback("codem-minerjob:getKey")
  if callbackKeyResult then
    serverSecurityKey = callbackKeyResult
  else
    serverSecurityKey = false
  end
end)

function GetJob()
  while Core == nil do
    Wait(0)
  end
  
  if Config.Framework == 'esx' then
    local playerData = Core.GetPlayerData()
    local jobName = playerData.job.name
    return jobName
  elseif Config.Framework == 'oldesx' then
    local playerData = Core.GetPlayerData()
    local jobName = playerData.job.name
    return jobName
  else
    local playerData = Core.Functions.GetPlayerData()
    local jobName = playerData.job.name
    return jobName
  end
end

function NuiMessage(actionName, payloadData)
  WaitNui()
  local messageData = {
    action = actionName,
    payload = payloadData
  }
  SendNUIMessage(messageData)
end

function SpawnPed()
  if DoesEntityExist(npcPedEntity) then
    DeleteEntity(npcPedEntity)
  end
  
  local pedModel = Config.MinerMenu.model
  RequestModel(pedModel)
  
  while true do
    local hasLoaded = HasModelLoaded(pedModel)
    if hasLoaded then
      break
    end
    Wait(0)
  end
  
  local spawnCoords = Config.MinerMenu.coords
  npcPedEntity = CreatePed(0, pedModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w or spawnCoords.h or 0.0, false, false)
  FreezeEntityPosition(npcPedEntity, true)
  SetEntityInvincible(npcPedEntity, true)
  SetBlockingOfNonTemporaryEvents(npcPedEntity, true)
end

CreateThread(function()
  while true do
    if nuiReady then
      break
    end
    Wait(2000)
    local sessionStarted = NetworkIsSessionStarted()
    if sessionStarted then
      SendNUIMessage({
        action = "checknui"
      })
    end
  end
end)

if Config.DisableAFKMode then
  local controlsToDisable = {
    [1] = 0,
    [2] = 1,
    [3] = 2,
    [4] = 16,
    [5] = 17,
    [6] = 22,
    [7] = 24,
    [8] = 25,
    [9] = 26,
    [10] = 36,
    [11] = 37,
    [12] = 44,
    [13] = 47,
    [14] = 55,
    [15] = 75,
    [16] = 76,
    [17] = 81,
    [18] = 82,
    [19] = 91,
    [20] = 92,
    [21] = 99,
    [22] = 106,
    [23] = 114,
    [24] = 115,
    [25] = 121,
    [26] = 122,
    [27] = 135,
    [28] = 140,
    [29] = 200,
    [30] = 245,
    [31] = 32,
    [32] = 33,
    [33] = 34,
    [34] = 35,
    [35] = 87,
    [36] = 88,
    [37] = 89,
    [38] = 90,
    [39] = 31,
    [40] = 30
  }
  
  CreateThread(function()
    while true do
      if inputControlsDisabled then
        local controlIndex = 1
        while controlIndex <= #controlsToDisable do
          local controlId = controlsToDisable[controlIndex]
          DisableControlAction(0, controlId, true)
          controlIndex = controlIndex + 1
        end
      end
      Wait(0)
    end
  end)
end

function OpenMenu(menuType)
  if Config.JobCheck.enable then
    local currentJob = GetJob()
    if currentJob ~= Config.JobCheck.name then
      TriggerEvent("codem-minerjob:Notify", locales.not_miner)
      return
    end
  end
  
  local payloadData = {
    type = menuType
  }
  NuiMessage("open_menu", payloadData)
  SetNuiFocus(true, true)
  
  if Config.DisableAFKMode then
    SetNuiFocusKeepInput(true)
    inputControlsDisabled = true
  end
  
  if menuType == "main" then
    TriggerEvent("codem-minerjob:GetCash")
    TriggerServerEvent("codem-minerjob:CheckDailyMission")
    CreateCamera()
  end
  
  if menuType == "job" then
    NuiMessage("set_current_mine", selectedMineArea)
  end
  
  Config.OnMenuOpen()
end

function CloseMenu()
  NuiMessage("close")
end

function SpawnVehicle(vehicleModelName, spawnCoordinates)
  local modelHash = GetHashKey(vehicleModelName)
  RequestModel(modelHash)
  
  while true do
    local loaded = HasModelLoaded(modelHash)
    if loaded then
      break
    end
    Wait(0)
  end
  
  jobVehicle = CreateVehicle(modelHash, spawnCoordinates.x, spawnCoordinates.y, spawnCoordinates.z, spawnCoordinates.w or spawnCoordinates.h or 0.0, true, true)
  local plateText = GetVehicleNumberPlateText(jobVehicle)
  Config.GiveVehicleKey(plateText, modelHash)
  Config.SetVehicleFuel(jobVehicle, 100.0)
  local playerPed = PlayerPedId()
  TaskWarpPedIntoVehicle(playerPed, jobVehicle, -1)
  DeleteVehLoop(modelHash)
end

function DeleteVehLoop(vehicleModelHash)
  CreateThread(function()
    while true do
      local exists = DoesEntityExist(jobVehicle)
      if not exists then
        break
      end
      
      local playerPed = PlayerPedId()
      local playerCoords = GetEntityCoords(playerPed)
      local spawnCoords = Config.MinerMenu.vehSpawnCoords
      local spawnVector = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
      local distance = #(playerCoords - spawnVector)
      
      if distance < 7.0 then
        local inVehicle = IsPedInAnyVehicle(playerPed, false)
        if inVehicle then
          local markerCoords = Config.MinerMenu.vehSpawnCoords
          DrawMarker(
            2,
            markerCoords.x, markerCoords.y, markerCoords.z + 2.0,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            0.3, 0.2, 0.15,
            255, 255, 255, 255,
            false, false, false,
            true, false, false, false
          )
          DrawText3D(markerCoords.x, markerCoords.y, markerCoords.z + 2.0, locales.press_to_delete)
          
          if IsControlJustPressed(0, 38) then
            local vehPlate = GetVehicleNumberPlateText(jobVehicle)
            Config.RemoveVehiclekey(vehPlate, vehicleModelHash)
            DeleteEntity(jobVehicle)
          end
        end
      end
      Wait(0)
    end
  end)
end

function LoadAnimation(animDict)
  RequestAnimDict(animDict)
  while true do
    local loaded = HasAnimDictLoaded(animDict)
    if loaded then
      break
    end
    Wait(0)
  end
end

function ProcessAnimation(processData)
  local playerPed = PlayerPedId()
  FreezeEntityPosition(playerPed, true)
  LoadAnimation("amb@world_human_stand_fire@male@idle_a")
  
  CreateThread(function()
    if Config.DisableAFKMode then
      TriggerEvent("minerjob_minigame:start", 1, 20, function(minigameSuccess)
        if minigameSuccess == true then
          TaskPlayAnim(
            playerPed,
            "amb@world_human_stand_fire@male@idle_a",
            "idle_a",
            3.0, 3.0, -1, 2, 0,
            false, false, false
          )
          Wait(3000)
          TriggerServerEvent("codem-minerjob:ProcessItems", processData)
          TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "process_ore")
          spamProtectionTimer = false
          
          if isCurrentlyProcessing then
            ProcessAnimation(processData)
          end
        elseif minigameSuccess == false then
          if isCurrentlyProcessing then
            ProcessAnimation(processData)
          end
        end
      end)
    else
      while true do
        if not isCurrentlyProcessing then
          break
        end
        TaskPlayAnim(
          playerPed,
          "amb@world_human_stand_fire@male@idle_a",
          "idle_a",
          3.0, 3.0, -1, 2, 0,
          false, false, false
        )
        Wait(3000)
        TriggerServerEvent("codem-minerjob:ProcessItems", processData)
        TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "process_ore")
        spamProtectionTimer = false
      end
    end
  end)
end

function MineAnimation()
  local playerPed = PlayerPedId()
  local pickaxeModel = 260873931
  
  RequestModel(pickaxeModel)
  while true do
    local loaded = HasModelLoaded(pickaxeModel)
    if loaded then
      break
    end
    Wait(0)
  end
  
  local toolExists = DoesEntityExist(miningToolObject)
  if not toolExists then
    local playerCoords = GetEntityCoords(playerPed)
    miningToolObject = CreateObject(pickaxeModel, playerCoords.x, playerCoords.y, playerCoords.z, true, false, false)
    local boneIndex = GetPedBoneIndex(playerPed, 57005)
    AttachEntityToEntity(
      miningToolObject, playerPed, boneIndex,
      0.09, 0.03, -0.02,
      -78.0, 13.0, 28.0,
      true, true, false, true, 1, true
    )
  end
  
  LoadAnimation("melee@large_wpn@streamed_core")
  FreezeEntityPosition(playerPed, true)
  
  CreateThread(function()
    if Config.DisableAFKMode then
      TriggerEvent("minerjob_minigame:start", 1, 20, function(minigameSuccess)
        if minigameSuccess == true then
          TaskPlayAnim(
            playerPed,
            "melee@large_wpn@streamed_core",
            "ground_attack_on_spot",
            3.0, 3.0, -1, 2, 0,
            false, false, false
          )
          Wait(3000)
          
          local possibleItems = Config.Areas[selectedMineArea].possible_items
          local randomIndex = math.random(1, #possibleItems)
          local selectedOre = possibleItems[randomIndex]
          
          table.insert(collectedOreItems, selectedOre)
          TriggerServerEvent("codem-minerjob:GiveItems", selectedOre, serverSecurityKey)
          TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "gather_mine")
          
          if selectedMineArea == "abandoned_mine" and selectedOre == "diamond_ore" then
            TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "gather_diamonds")
          end
          
          spamProtectionTimer = false
          if isCurrentlyMining then
            MineAnimation()
          end
        elseif minigameSuccess == false then
          if isCurrentlyMining then
            MineAnimation()
          end
        end
      end)
    else
      while true do
        if not isCurrentlyMining then
          break
        end
        TaskPlayAnim(
          playerPed,
          "melee@large_wpn@streamed_core",
          "ground_attack_on_spot",
          3.0, 3.0, -1, 2, 0,
          false, false, false
        )
        Wait(3000)
        
        local possibleItems = Config.Areas[selectedMineArea].possible_items
        local randomIndex = math.random(1, #possibleItems)
        local selectedOre = possibleItems[randomIndex]
        
        table.insert(collectedOreItems, selectedOre)
        TriggerServerEvent("codem-minerjob:GiveItems", selectedOre, serverSecurityKey)
        TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "gather_mine")
        
        if selectedMineArea == "abandoned_mine" and selectedOre == "diamond_ore" then
          TriggerServerEvent("codem-minerjob:AddDailyMissionProcess", "gather_diamonds")
        end
        
        spamProtectionTimer = false
      end
    end
  end)
end

CreateThread(function()
  SpawnPed()
  AreaLoop()
end)

CreateThread(function()
  while true do
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local sleepDuration = 1000
    local processCoords = Config.Process.coords
    local distanceToProcess = #(playerCoords - processCoords)
    
    if distanceToProcess < 10.0 then
      sleepDuration = 0
      DrawMarker(
        2,
        processCoords.x, processCoords.y, processCoords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        0.3, 0.2, 0.15,
        255, 255, 255, 255,
        false, false, false, true,
        false, false, false
      )
      
      if distanceToProcess < 3.0 then
        DrawText3D(processCoords.x, processCoords.y, processCoords.z, locales.press_to_open)
        if IsControlJustPressed(0, 38) then
          OpenMenu("process")
        end
      end
    end
    
    Wait(sleepDuration)
  end
end)

function AreaLoop()
  while true do
    if not selectedMineArea then
      break
    end
    
    local areaData = Config.Areas[selectedMineArea]
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, coord in pairs(areaData.coords) do
      local distance = #(playerCoords - coord)
      
      if distance < 6.0 then
        DrawMarker(
          2,
          coord.x, coord.y, coord.z,
          0.0, 0.0, 0.0,
          0.0, 0.0, 0.0,
          0.3, 0.2, 0.15,
          255, 255, 255, 255,
          false, false, false,
          true, false, false, false
        )
      end
      
      if distance < 2.0 then
        DrawText3D(coord.x, coord.y, coord.z, locales.press_to_open)
        if IsControlJustPressed(0, 38) then
          OpenMenu("job")
        end
      end
    end
    
    Wait(0)
  end
end

function ShipOrder(shipmentData)
  shipmentDeliveryActive = true
  SetNewWaypoint(shipmentData.coords.x, shipmentData.coords.y)
  TriggerEvent("codem-minerjob:Notify", locales.go_to_location)
  CloseMenu()
  
  CreateThread(function()
    while true do
      if not shipmentDeliveryActive then
        break
      end
      
      local sleepDuration = 1000
      local playerPed = PlayerPedId()
      local waypointPos = vector3(shipmentData.coords.x, shipmentData.coords.y, shipmentData.coords.z)
      local playerPos = GetEntityCoords(playerPed)
      local distance = #(playerPos - waypointPos)
      
      if distance < 4.0 then
        sleepDuration = 0
        DrawMarker(
          2,
          shipmentData.coords.x, shipmentData.coords.y, shipmentData.coords.z,
          0.0, 0.0, 0.0,
          0.0, 0.0, 0.0,
          0.3, 0.2, 0.15,
          255, 255, 255, 255,
          false, false, false,
          true, false, false, false
        )
        DrawText3D(shipmentData.coords.x, shipmentData.coords.y, shipmentData.coords.z, locales.press_to_ship)
        
        if IsControlJustPressed(0, 38) then
          TriggerServerEvent("codem-minerjob:ShipOrder", shipmentData)
          shipmentDeliveryActive = false
        end
      end
      
      Wait(sleepDuration)
    end
  end)
end

function UpdateItemLogs()
  NuiMessage("update_item_logs", miningItemLogs)
end

function DeleteOreProcessBlip()
  if DoesBlipExist(processAreaBlip) then
    RemoveBlip(processAreaBlip)
  end
end

function CreateOreProcessBlip()
  local blipConfig = Config.Process.blip
  processAreaBlip = AddBlipForCoord(Config.Process.coords.x, Config.Process.coords.y, Config.Process.coords.z)
  SetBlipSprite(processAreaBlip, blipConfig.sprite)
  SetBlipColour(processAreaBlip, blipConfig.color)
  SetBlipScale(processAreaBlip, blipConfig.scale)
  SetBlipAsShortRange(processAreaBlip, true)
  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(blipConfig.name)
  EndTextCommandSetBlipName(processAreaBlip)
end

RegisterNUICallback("getBuyItems", function(data, callback)
  callback(Config.BuyItems)
end)

RegisterNUICallback("getSellItems", function(data, callback)
  callback(Config.SellItems)
end)

RegisterNUICallback("ready", function(data, callback)
  nuiReady = true
end)

RegisterNUICallback("close", function(data, callback)
  SetNuiFocus(false, false)
  
  if Config.DisableAFKMode then
    SetNuiFocusKeepInput(false)
    inputControlsDisabled = false
  end
  
  local camExists = DoesCamExist(cam)
  if camExists then
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(cam, true)
  end
  
  Config.OnMenuClose()
end)

RegisterNUICallback("buyItems", function(data, callback)
  TriggerServerEvent("codem-minerjob:BuyItems", data.cart, data.money)
end)

RegisterNUICallback("sellItems", function(data, callback)
  TriggerServerEvent("codem-minerjob:SellItems", data)
end)

RegisterNUICallback("startMine", function(data, callback)
  local playerPed = PlayerPedId()
  local inVehicle = IsPedInAnyVehicle(playerPed, false)
  
  if inVehicle then
    TriggerEvent("codem-minerjob:Notify", "You can't start mine in vehicle")
    return
  end
  
  if isCurrentlyMining then
    return
  end
  
  if Config.SpamProtection then
    if spamProtectionTimer then
      TriggerEvent("codem-minerjob:Notify", locales.spam_protection)
      return
    end
  end
  
  local requiredTool = Config.Areas[selectedMineArea].tool
  local hasTool = TriggerCallback("codem-minerjob:HasItem", { name = requiredTool, amount = 1 })
  
  if hasTool then
    isCurrentlyMining = true
    miningItemLogs = {}
    UpdateItemLogs()
    spamProtectionTimer = true
    MineAnimation()
  else
    TriggerEvent("codem-minerjob:Notify", locales.dont_have_pickaxe)
  end
end)

function FindItem(tableData, itemName)
  for _, item in pairs(tableData) do
    if item.name == itemName then
      return item
    end
  end
  return false
end

function CalculateOres(oreList)
  local totals = {}
  for _, ore in pairs(oreList) do
    local foundItem = FindItem(totals, ore)
    if foundItem then
      foundItem.amount = foundItem.amount + 1
    else
      table.insert(totals, { name = ore, amount = 1 })
    end
  end
  return totals
end

function GetOresLabel(oreTotals)
  local labelString = ""
  for _, ore in pairs(oreTotals) do
    local itemLabel = itemLabels[ore.name]
    if itemLabel then
      labelString = labelString .. " " .. ore.amount .. " " .. itemLabel
    end
  end
  return labelString
end

RegisterNUICallback("stopMine", function(data, callback)
  isCurrentlyMining = false
  
  local toolExists = DoesEntityExist(miningToolObject)
  if toolExists then
    DeleteEntity(miningToolObject)
  end
  
  local playerPed = PlayerPedId()
  FreezeEntityPosition(playerPed, false)
  stopMinigame()
  ClearPedTasksImmediately(playerPed)
  
  miningItemLogs = {}
  UpdateItemLogs()
  TriggerEvent("codem-minerjob:Notify", locales.you_can_now_process)
  
  local oreTotals = CalculateOres(collectedOreItems)
  local labelText = GetOresLabel(oreTotals)
  local labelLength = #labelText
  
  if labelLength > 0 then
    local placeLabel = Config.Areas[selectedMineArea].label
    TriggerServerEvent("codem-minerjob:AddLatestWork", labelText, "MINING", placeLabel)
  end
  
  SetNewWaypoint(Config.Process.coords.x, Config.Process.coords.y)
  collectedOreItems = {}
end)

RegisterNUICallback("startProcess", function(data, callback)
  miningItemLogs = {}
  UpdateItemLogs()
  
  if Config.SpamProtection then
    if spamProtectionTimer then
      TriggerEvent("codem-minerjob:Notify", locales.spam_protection)
      return
    end
  end
  
  isCurrentlyProcessing = true
  spamProtectionTimer = true
  ProcessAnimation(data)
end)

RegisterNUICallback("stopProcess", function(data, callback)
  isCurrentlyProcessing = false
  miningItemLogs = {}
  UpdateItemLogs()
  stopMinigame()
  
  local playerPed = PlayerPedId()
  FreezeEntityPosition(playerPed, false)
  ClearPedTasksImmediately(playerPed)
  
  DeleteOreProcessBlip()
end)

RegisterNUICallback("getAreas", function(data, callback)
  callback(Config.Areas)
end)

RegisterNUICallback("getXP", function(data, callback)
  callback(Config.XP)
end)

RegisterNUICallback("getShipments", function(data, callback)
  local shipmentsData = Config.Shipments
  local encodedData = json.encode(shipmentsData)
  callback(encodedData)
end)

RegisterNUICallback("getLeaderboard", function(data, callback)
  local leaderboardData = TriggerCallback("codem-minerjob:GetLeaderboard")
  callback(leaderboardData)
end)

RegisterNUICallback("getItems", function(data, callback)
  local playerItems = TriggerCallback("codem-minerjob:GetItems")
  callback(playerItems)
end)

RegisterNUICallback("startJob", function(data, callback)
  selectedMineArea = data.selectedArea
  SpawnVehicle(data.selectedVehicle, Config.MinerMenu.vehSpawnCoords)
  
  local areaCoords = Config.Areas[selectedMineArea].coords[1]
  SetNewWaypoint(areaCoords.x, areaCoords.y)
  
  CloseMenu()
  TriggerEvent("codem-minerjob:Notify", locales.go_to_location)
  CreateOreProcessBlip()
  AreaLoop()
end)

RegisterNUICallback("shipOrder", function(data, callback)
  local decodedData = json.decode(data)
  ShipOrder(decodedData)
end)

AddEventHandler("onResourceStart", function(resourceName)
  local currentResource = GetCurrentResourceName()
  if currentResource ~= resourceName then
    return
  end
  
  DeleteEntity(npcPedEntity)
  
  local toolExists = DoesEntityExist(miningToolObject)
  if toolExists then
    DeleteEntity(miningToolObject)
  end
  
  local playerPed = PlayerPedId()
  FreezeEntityPosition(playerPed, false)
  ClearPedTasksImmediately(playerPed)
end)

RegisterNetEvent("codem-minerjob:OpenMinerMenu")
AddEventHandler("codem-minerjob:OpenMinerMenu", function()
  OpenMenu("main")
  TriggerServerEvent("codem-minerjob:OnMenuOpen")
end)

RegisterNetEvent("codem-minerjob:SyncPlayerDataByKey")
AddEventHandler("codem-minerjob:SyncPlayerDataByKey", function(key, value)
  playerData[key] = value
  NuiMessage("setPlayerData", playerData)
end)

RegisterNetEvent("codem-minerjob:Load")
AddEventHandler("codem-minerjob:Load", function(serverData)
  playerData = serverData
  NuiMessage("setPlayerData", playerData)
end)

RegisterNetEvent("codem-minerjob:Notify")
AddEventHandler("codem-minerjob:Notify", function(message)
  NuiMessage("Notify", message)
end)

RegisterNetEvent("codem-minerjob:AddItemLog")
AddEventHandler("codem-minerjob:AddItemLog", function(itemName)
  local logCount = #miningItemLogs
  if logCount >= 3 then
    table.remove(miningItemLogs, 1)
  end
  
  local label = itemLabels[itemName]
  table.insert(miningItemLogs, {
    item = itemName,
    label = label
  })
  
  UpdateItemLogs()
end)

RegisterNetEvent("codem-minerjob:GetCash")
AddEventHandler("codem-minerjob:GetCash", function()
  local cashAmount = TriggerCallback("codem-minerjob:getMoney")
  NuiMessage("setMoney", cashAmount)
end)