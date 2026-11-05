-- Global Variables
Core = nil
NuiLoaded = false
CharacterLoaded = false
isFishing = false
deliveryBlip = false
fishPedCaught = nil

PlayerData = {
  PlayerInfo = {},
  CurrentRod = {},
  PlayerInventory = {},
  StartFishing = false,
  SelectedBait = {
    itemname = nil,
    amount = 0,
    label = nil,
    baitEffect = nil
  },
  VehiclePlate = nil,
  BaitsLeft = 0
}

SelectedLocalesData = Locales[Config.Language]

-- Prop references for fishing
rodProp = false
ropeProp = false
baitProp = false

-- Initialize Core Framework
CreateThread(function()
  local coreObject, frameworkName = GetCore()
  Config.Framework = frameworkName
  Core = coreObject
end)

-- NUI Message Helper
function NuiMessage(action, payload)
  while not NuiLoaded do
    Wait(0)
  end
  SendNUIMessage({
    action = action,
    payload = payload
  })
end

-- NUI Loaded Callback
RegisterNUICallback("LoadedNUI", function(data, cb)
  NuiLoaded = true
  cb("ok")

  NuiMessage("LOAD_LOCALES", Locales[Config.Language])
  NuiMessage("CONFIG_ITEMS", Config.Items)
  NuiMessage("LOAD_DAILYMISSON", Config.DailyMission)
  NuiMessage("LOAD_MINIGAMETIMER", Config.MiniGameTimer)
  NuiMessage("LOAD_RENTBOAT", Config.BoatRent)
  NuiMessage("LOAD_ALLLVL", Config.RequiredXP)
  NuiMessage("LOAD_KEYMAPPING", Config.RegisterKeyMapping)
  NuiMessage("DAILY_DELIVERY", Config.DailyDelivery)
end)

-- Wait for NUI and Core to be ready
CreateThread(function()
  while Core == nil do
    Wait(0)
  end

  while not NuiLoaded do
    if NetworkIsSessionStarted() then
      SendNUIMessage({ action = "CHECK_NUI" })
    end
    Wait(2000)
  end
end)

-- Load Player Info Event
RegisterNetEvent("codem-fishingjob:LoadInfo", function(playerInfo)
  PlayerData.PlayerInfo = playerInfo or {}
  NuiMessage("LOAD_PLAYERINFO", PlayerData.PlayerInfo)
end)

-- Load Player Inventory Event
RegisterNetEvent("codem-fishingjob:client:playerinventory", function(inventory)
  PlayerData.PlayerInventory = inventory or {}
  NuiMessage("LOAD_PLAYERINVENTORY", PlayerData.PlayerInventory)
end)

-- Fishing Market NUI Callback
RegisterNUICallback("FishingMarket", function(data, cb)
  TriggerServerEvent("codem-fishingjob:market", data)
  if cb then cb("ok") end
end)

-- Load Top 10 Leaderboard Event
RegisterNetEvent("codem-fishing:loadtop10", function(top10Data, myRank)
  NuiMessage("LOAD_TOP10", top10Data)
  NuiMessage("LOAD_MYRANK", myRank)
end)

-- Update Sold Stats Event
RegisterNetEvent("codem-fishingjob:updatesold", function(totalFishes, totalEarnings)
  PlayerData.PlayerInfo.totalfishes = totalFishes
  PlayerData.PlayerInfo.totalearnings = totalEarnings
  NuiMessage("UPDATE_SOLD", {
    totalfishes = totalFishes,
    totalearnings = totalEarnings
  })
end)

-- Update Level Event
RegisterNetEvent("codem-fishingjob:UpdateLevel", function(level, xp)
  PlayerData.PlayerInfo.level = level
  PlayerData.PlayerInfo.xp = xp
  NuiMessage("UPDATE_LEVEL", {
    level = level,
    xp = xp
  })
end)

-- Delivery Mission Cooldown
local deliveryMissionCooldown = 0

RegisterNetEvent("codem-fishingjob:client:deliverymission", function(missionKey)
  if not Config.DailyDelivery then return end
  if not Config.DailyDelivery[missionKey] then return end

  local currentTime = GetGameTimer()
  if currentTime < deliveryMissionCooldown then
    local remainingSeconds = math.ceil((deliveryMissionCooldown - currentTime) / 1000)
    Config.Notify(SelectedLocalesData.info, string.format(SelectedLocalesData.waitcooldown, remainingSeconds))
    return
  end

  deliveryMissionCooldown = currentTime + 3000
  TriggerServerEvent("codem-fishingjob:server:deliverymission", missionKey)

  if deliveryBlip then
    RemoveBlip(deliveryBlip)
    deliveryBlip = false
  end
end)

-- Complete Delivery Event
RegisterNetEvent("codem-fishingjob:completedelivery", function(missionKey)
  local dailyDelivery = PlayerData.PlayerInfo.dailydelivery
  if not dailyDelivery then return end

  local mission = dailyDelivery.missions[missionKey]
  if not mission or mission.complete then return end

  mission.complete = true
  NuiMessage("UPDATE_DELIVERY", dailyDelivery)

  if deliveryBlip then
    RemoveBlip(deliveryBlip)
    deliveryBlip = false
  end
end)

-- Deliver Fish NUI Callback
RegisterNUICallback("deliverFish", function(missionKey, cb)
  if not missionKey then
    if cb then cb("ok") end
    return
  end
  if not Config.DailyDelivery then
    if cb then cb("ok") end
    return
  end
  if not Config.DailyDelivery[missionKey] then
    if cb then cb("ok") end
    return
  end

  local dailyDelivery = PlayerData.PlayerInfo.dailydelivery
  if dailyDelivery and dailyDelivery.missions[missionKey] and dailyDelivery.missions[missionKey].complete then
    Config.Notify(SelectedLocalesData.info, SelectedLocalesData.gotodelivery)
    if cb then cb("ok") end
    return
  end

  local npcCoords = Config.DailyDelivery[missionKey].npcCoords.coords
  deliveryBlip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)
  SetBlipRoute(deliveryBlip, true)
  Config.Notify(SelectedLocalesData.info, SelectedLocalesData.gotodelivery)
  if cb then cb("ok") end
end)

-- Update Latest Event
RegisterNetEvent("codem-fishingjob:updatelatetest", function(latestData)
  table.insert(PlayerData.PlayerInfo.latetest, latestData)
  NuiMessage("UPDATE_LATEST", latestData)
end)

-- Select Bait Cooldown
local selectBaitCooldown = 0

RegisterNUICallback("SelectBait", function(baitItem, cb)
  local currentTime = GetGameTimer()
  if currentTime < selectBaitCooldown then
    local remainingSeconds = math.ceil((selectBaitCooldown - currentTime) / 1000)
    Config.Notify(SelectedLocalesData.info, string.format(SelectedLocalesData.waitcooldown, remainingSeconds))
    if cb then cb("ok") end
    return
  end

  selectBaitCooldown = currentTime + 3000
  TriggerServerEvent("codem-fishingjob:selectbait", baitItem)
  if cb then cb("ok") end
end)

-- Select Bait Server Response Event
RegisterNetEvent("codem-fishingjob:selectbait", function(itemName, label, amount)
  PlayerData.SelectedBait.itemname = itemName
  PlayerData.SelectedBait.label = label
  PlayerData.SelectedBait.amount = amount
  PlayerData.SelectedBait.baitEffect = Config.Items[itemName].baitEffect

  SetNuiFocus(false, false)
  PlayerData.StartFishing = true

  NuiMessage("SELECTED_BAIT", PlayerData.SelectedBait)
  StartFishing()
end)

-- Fish Caught NUI Callback
RegisterNUICallback("FishCaught", function(data, cb)
  SetNuiFocus(false, false)
  TriggerServerEvent("codem-fishingjob:caughtfish", PlayerData.CurrentRod.name, PlayerData.SelectedBait.itemname)
  if cb then cb("ok") end
end)

-- Mini Game Stopped NUI Callback
RegisterNUICallback("MiniGameStopped", function(data, cb)
  SetNuiFocus(false, false)
  TriggerServerEvent("codem-fishingjob:stopfishing", PlayerData.SelectedBait.itemname)
  if cb then cb("ok") end
end)

-- Fish Caught Client Event
RegisterNetEvent("codem-fishingjob:caughtfish", function(fishData)
  NuiMessage("COUGHT_FISH_NOTIFICATION", fishData)

  PlayerData.SelectedBait.amount = PlayerData.SelectedBait.amount - 1
  PlayerData.BaitsLeft = PlayerData.BaitsLeft + 1

  NuiMessage("SELECTED_BAIT", PlayerData.SelectedBait)
  NuiMessage("UPDATE_BAIT_AMOUNT", PlayerData.BaitsLeft)

  CreateAndMovePedTowardsPlayer()
end)

-- Create Fish Ped and Move Towards Player
function CreateAndMovePedTowardsPlayer()
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  local forwardVector = GetEntityForwardVector(playerPed)

  local spawnCoords = vector3(
    playerCoords.x + forwardVector.x * 10,
    playerCoords.y + forwardVector.y * 10,
    playerCoords.z + forwardVector.z * 2
  )

  local fishModel = 802685111
  RequestModel(fishModel)
  while not HasModelLoaded(fishModel) do
    Wait(100)
  end

  fishPedCaught = CreatePed(4, fishModel, spawnCoords.x, spawnCoords.y, spawnCoords.z, 0.0, true, true)
  SetEntityCollision(fishPedCaught, false, false)

  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(1)

      local currentPlayerCoords = GetEntityCoords(playerPed)
      local fishCoords = GetEntityCoords(fishPedCaught)
      local distance = #(currentPlayerCoords - fishCoords)

      if distance > 0.2 then
        local direction = (currentPlayerCoords - fishCoords) * 4
        SetEntityVelocity(fishPedCaught, direction.x, direction.y, direction.z)
      else
        if not isFishing then
          if fishPedCaught then
            DeleteEntity(fishPedCaught)
          end
          break
        end

        RequestAnimDict("pickup_object")
        while not HasAnimDictLoaded("pickup_object") do
          Citizen.Wait(0)
        end

        TaskPlayAnim(playerPed, "pickup_object", "pickup_low", 1.0, -1.0, -1, 2, 1, true, true, true)
        Citizen.Wait(1500)

        DeleteEntity(fishPedCaught)

        if isFishing then
          StartFishing()
        end
        break
      end
    end
  end)
end

-- Again Fishing Player Event (with bait remaining)
RegisterNetEvent("codem-fishingjob:againfishingplayer", function(baitAmount)
  PlayerData.StartFishing = true
  PlayerData.SelectedBait.amount = baitAmount
  NuiMessage("SELECTED_BAIT", PlayerData.SelectedBait)

  if isFishing then
    local waitTime = math.random(Config.FishArrivalTime.min, Config.FishArrivalTime.max)
    Citizen.Wait(waitTime * 1000)

    if isFishing then
      SetNuiFocus(true, true)
      NuiMessage("START_MINIGAME")
    end
  end
end)

-- Again Fishing Event (without minigame)
RegisterNetEvent("codem-fishingjob:againfishing", function(baitAmount)
  PlayerData.StartFishing = true
  PlayerData.SelectedBait.amount = baitAmount
  NuiMessage("SELECTED_BAIT", PlayerData.SelectedBait)
end)

-- Open Bait Menu (Press Key)
function OpenPressBaitMenu()
  if not PlayerData.SelectedBait or not PlayerData.SelectedBait.itemname then
    return
  end

  cleanUP()
  FreezeEntityPosition(PlayerPedId(), false)
  ClearPedTasks(PlayerPedId())

  TriggerServerEvent("codem-fishingjob:getplayerinventory")
  NuiMessage("REOPEN_MENU")
  NuiMessage("PLAYER_IN_ZONE")

  isFishing = false
  SetNuiFocus(true, true)
end

-- Update Daily Mission Event
RegisterNetEvent("codem-fishing:uptadedailymission", function(dailyMission)
  PlayerData.PlayerInfo.dailymission = dailyMission
  NuiMessage("LOAD_PLAYERINFO", PlayerData.PlayerInfo)
end)

-- Stop Fishing Function
function StopFishing()
  if fishPedCaught then
    DeleteEntity(fishPedCaught)
  end

  cleanUP()
  FreezeEntityPosition(PlayerPedId(), false)
  ClearPedTasks(PlayerPedId())

  isFishing = false
  NuiMessage("STOP_MINIGAME")
  NuiMessage("REFRESH_BAIT_MENU")
  SetNuiFocus(false, false)

  PlayerData.SelectedBait = {
    itemname = nil,
    amount = 0,
    label = nil
  }
  PlayerData.BaitsLeft = 0
  NuiMessage("UPDATE_BAIT_AMOUNT", 0)
end

-- Stop Fishing Server Event
RegisterNetEvent("codem-fishingjob:stopfishing", function()
  PlayerData.CurrentRod = {}
  PlayerData.StartFishing = false
  PlayerData.SelectedBait = {
    itemname = nil,
    amount = 0,
    label = nil
  }

  cleanUP()
  FreezeEntityPosition(PlayerPedId(), false)
  NuiMessage("SHOW_POPUP", false)
  ClearPedTasks(PlayerPedId())
  NuiMessage("REFRESH_BAIT_MENU")
  NuiMessage("UPDATE_BAIT_AMOUNT", 0)

  isFishing = false
end)

-- Start Fishing Function
function StartFishing()
  cleanUP()

  local playerPed = PlayerPedId()
  ClearPedTasks(playerPed)

  local rodPropName = Config.FishingRodProps[PlayerData.CurrentRod.name]
  local rodHash = GetHashKey(rodPropName)
  RequestModel(rodHash)

  local animationReady = Animation(rodHash)
  if not animationReady then
    return
  end

  -- Play cast animation
  PlayAnimation(PlayerPedId(), "mini@tennis", "forehand_ts_md_far", { flag = 48 })

  while IsEntityPlayingAnim(PlayerPedId(), "mini@tennis", "forehand_ts_md_far", 3) do
    Citizen.Wait(0)
  end

  -- Play idle fishing animation
  PlayAnimation(PlayerPedId(), "amb@world_human_stand_fishing@idle_a", "idle_c", { flag = 11 })

  isFishing = true

  -- Keep animation running
  Citizen.CreateThread(function()
    while isFishing do
      Citizen.Wait(1000)
      if not IsEntityPlayingAnim(PlayerPedId(), "amb@world_human_stand_fishing@idle_a", "idle_c", 3) then
        if isFishing then
          ClearPedTasks(PlayerPedId())
          PlayAnimation(PlayerPedId(), "amb@world_human_stand_fishing@idle_a", "idle_c", { flag = 11 })
        end
        break
      end
    end
  end)

  NuiMessage("SHOW_POPUP", true)
  NuiMessage("UPDATE_ROD", PlayerData.CurrentRod.name)

  -- Wait for fish to arrive
  local waitTime = math.random(Config.FishArrivalTime.min, Config.FishArrivalTime.max)
  Citizen.Wait(waitTime * 1000)

  if isFishing then
    SetNuiFocus(true, true)
    NuiMessage("START_MINIGAME")
  end
end

-- Client Start Fishing Event (when using rod item)
RegisterNetEvent("codem-fishingjob:client:StartFishing", function(rodData)
  local playerPed = PlayerPedId()

  -- Check if player is falling or parachuting
  if IsPedFalling(playerPed) or IsPedInParachuteFreeFall(playerPed) then
    return
  end

  -- Check if player is swimming
  if IsPedSwimming(playerPed) then
    return
  end

  -- Check if player is in a vehicle (not boat)
  local vehicle = GetVehiclePedIsIn(playerPed, false)
  if vehicle ~= 0 then
    local seatCount = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for seat = -1, seatCount, 1 do
      if GetPedInVehicleSeat(vehicle, seat) == PlayerPedId() then
        return
      end
    end
  else
    -- Check for nearby boats
    local playerCoords = GetEntityCoords(playerPed)
    local nearestBoat = nil
    local nearestDistance = 10.0

    for foundVehicle in EnumerateVehicles() do
      if GetVehicleClass(foundVehicle) == 14 then -- Boat class
        local boatCoords = GetEntityCoords(foundVehicle)
        local distance = #(playerCoords - boatCoords)
        if distance < nearestDistance then
          nearestBoat = foundVehicle
          nearestDistance = distance
        end
      end
    end

    if not nearestBoat then
      local heightAboveGround = GetEntityHeightAboveGround(playerPed)
      if heightAboveGround > 2.0 then
        return
      end
    end
  end

  -- Check if already fishing
  if PlayerData.SelectedBait and PlayerData.SelectedBait.itemname then
    return
  end

  -- Check player level
  local playerLevel = PlayerData.PlayerInfo.level
  if not playerLevel then
    return
  end

  local requiredLevel = rodData.requiredLevel
  if tonumber(playerLevel) < tonumber(requiredLevel) then
    Config.Notify(SelectedLocalesData.info, string.format(SelectedLocalesData.rodrequiredlevel, requiredLevel))
    return
  end

  -- Check if in fishing zone
  local inFishingZone = GetPlayerFishingZone()
  if not inFishingZone then
    Config.Notify(SelectedLocalesData.info, SelectedLocalesData.notfisharea)
    return
  end

  PlayerData.CurrentRod = rodData
  TriggerServerEvent("codem-fishingjob:getplayerinventory")
  NuiMessage("PLAYER_IN_ZONE")
  SetNuiFocus(true, true)
end)

-- Vehicle Enumerator
function EnumerateVehicles()
  return coroutine.wrap(function()
    local findHandle, vehicle = FindFirstVehicle()

    if not findHandle or not vehicle or vehicle == 0 then
      EndFindVehicle(findHandle)
      return
    end

    repeat
      coroutine.yield(vehicle)
      local success, nextVehicle = FindNextVehicle(findHandle)
      vehicle = nextVehicle
    until not success

    EndFindVehicle(findHandle)
  end)
end

-- Update Player Money Event
RegisterNetEvent("codem-fishingjob:updateplayermoney", function(moneyData)
  NuiMessage("UPDATE_MONEY", moneyData)
end)

-- Refresh Market Basket Event
RegisterNetEvent("codem-fishingjob:refreshmarketbasket", function()
  TriggerServerEvent("codem-fishingjob:getplayerinventory")
  NuiMessage("REFRESH_MARKET_BASKET")
end)

-- Rent Vehicle NUI Callback
RegisterNUICallback("RentVehicle", function(vehicleName, cb)
  local availableSpawns = {}

  for _, spawnCoord in ipairs(Config.SpawnBoatCoords) do
    local coords = vector4(spawnCoord.x, spawnCoord.y, spawnCoord.z, spawnCoord.w)
    local nearbyVehicles = CodemGetVehiclesInArea(coords, 5.0)

    if next(nearbyVehicles) == nil then
      table.insert(availableSpawns, coords)
    end
  end

  if next(availableSpawns) == nil then
    Config.Notify(SelectedLocalesData.info, SelectedLocalesData.spawnpoint)
    if cb then cb("ok") end
    return
  end

  local hasEnoughMoney = TriggerCallback("codem-fishingjob:checkmoney", vehicleName)
  if not hasEnoughMoney then
    Config.Notify(SelectedLocalesData.error, SelectedLocalesData.notmoney)
    if cb then cb("ok") end
    return
  end

  NuiMessage("CLOSE_RENT_UI")
  SetNuiFocus(false, false)
  SpawnVehicle(vehicleName, availableSpawns[1])
  Config.Notify(SelectedLocalesData.info, SelectedLocalesData.boatprice)
  if cb then cb("ok") end
end)

-- Notify Event
RegisterNetEvent("codem-fishingjob:Notify", function(header, text)
  NuiMessage("NOTIFY", {
    header = header,
    text = text
  })
end)

-- Play Animation Helper
function PlayAnimation(ped, animDict, animName, options)
  if animDict then
    Citizen.CreateThread(function()
      RequestAnimDict(animDict)
      while not HasAnimDictLoaded(animDict) do
        Citizen.Wait(100)
      end

      if options == nil then
        TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, -1, 0, 0, false, false, false)
      else
        local speed = options.speed or 1.0
        local speedMultiplier = options.speedMultiplier or -1.0
        local duration = options.duration or 1.0
        local flag = options.flag or 0
        local playbackRate = options.playbackRate or 0

        TaskPlayAnim(ped, animDict, animName, speed, speedMultiplier, -1, flag, playbackRate, false, false, false)
      end

      RemoveAnimDict(animDict)
    end)
  else
    TaskStartScenarioInPlace(ped, animName, 0, true)
  end
end

-- Add Vector Factor Helper
function addVectorFactor(factor, baseVector, directionVector)
  return {
    x = baseVector.x + directionVector.x * factor,
    y = baseVector.y + directionVector.y * factor,
    z = baseVector.z + directionVector.z * factor
  }
end

-- Check if Facing Water
function IsFacingWater()
  local playerPed = PlayerPedId()
  local forwardVector = GetEntityForwardVector(playerPed)
  local playerCoords = GetEntityCoords(playerPed)

  local startPos = vector3(playerCoords.x + forwardVector.x, playerCoords.y + forwardVector.y,
    playerCoords.z + forwardVector.z)
  local endPos = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 50.0, -25.0)

  local hitWater, waterCoords = TestProbeAgainstAllWater(startPos.x, startPos.y, startPos.z, endPos.x, endPos.y, endPos
    .z, 1)

  if not hitWater then
    return false
  end

  return waterCoords
end

-- Cleanup Fishing Props
function cleanUP()
  if rodProp then
    DeleteEntity(rodProp)
  end
  if ropeProp then
    DeleteRope(ropeProp)
  end
  if baitProp then
    DeleteEntity(baitProp)
  end
  RopeUnloadTextures()
end

-- Animation Setup for Fishing
function Animation(rodModel)
  local waterCoords = IsFacingWater()

  if not waterCoords then
    Config.Notify(SelectedLocalesData.info, SelectedLocalesData.rodtosea)
    NuiMessage("REFRESH_BAIT_MENU")
    PlayerData.CurrentRod = {}
    PlayerData.StartFishing = false
    PlayerData.SelectedBait = {
      itemname = nil,
      amount = 0,
      label = nil
    }
    return false
  end

  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed, true)

  ModifyWater(waterCoords.x, waterCoords.y, 50.0, 200.0)

  -- Create invisible fish ped for rope attachment
  local fishModel = rodModel
  RequestModel(fishModel)
  while not HasModelLoaded(fishModel) do
    Wait(0)
  end

  local fishPed = CreatePed(0, fishModel, waterCoords.x, waterCoords.y, waterCoords.z, -GetEntityHeading(PlayerPedId()),
    true, true)
  SetEntityVisible(fishPed, false, false)
  SetEntityInvincible(fishPed, true)
  SetEntityCollision(fishPed, false, false)

  -- Calculate rope length
  local ropeLength = GetDistanceBetweenCoords(playerCoords.x, playerCoords.y, playerCoords.z, waterCoords.x,
    waterCoords.y, waterCoords.z, true)

  -- Create rope
  RopeLoadTextures()
  ropeProp = AddRope(playerCoords.x, playerCoords.y, playerCoords.z, 0.0, 0.0, 0.0, ropeLength * 4, 5, 15.0, 15.0, 0.7,
    false, false, false, 1.0, false)

  -- Create fishing rod prop
  local rodPropHash = GetHashKey("prop_fishing_rod_01")
  RequestModel(rodPropHash)
  while not HasModelLoaded(rodPropHash) do
    Wait(0)
  end
  local pedCoords = GetEntityCoords(playerPed)
  rodProp = CreateObject(rodPropHash, pedCoords.x, pedCoords.y, pedCoords.z, true, false, false)
  baitProp = fishPed

  local rodEndPos = GetOffsetFromEntityInWorldCoords(rodProp, 0, 0, 2.5)

  -- Attach rope to rod and water
  AttachEntitiesToRope(ropeProp, rodProp, playerPed, rodEndPos.x, rodEndPos.y, rodEndPos.z, waterCoords.x, waterCoords.y,
    waterCoords.z, ropeLength, false, false, 0, 0)

  -- Attach rod to player hand
  AttachEntityToEntity(rodProp, playerPed, GetPedBoneIndex(playerPed, 18905), 0.1, 0.05, 0, 80.0, 120.0, 160.0, true,
    true, false, true, 1, true)

  FreezeEntityPosition(PlayerPedId(), true)

  return true
end

-- Resource Stop Handler
AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    cleanUP()
    ClearPedTasks(PlayerPedId())

    if fishPedCaught then
      DeleteEntity(fishPedCaught)
    end
  end
end)
