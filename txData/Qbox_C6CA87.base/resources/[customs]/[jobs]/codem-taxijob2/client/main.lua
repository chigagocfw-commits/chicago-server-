-- Codem Taxi Job Client Script - Deobfuscated Version
-- Framework and Core Variables
local Framework = nil
Core = nil

-- Player Data Storage
playerData = {}
nuiReady = false
npcped = nil
key = false
taxiMeterOpen = false
missionActive = false
vipMissionActive = false
spawnedVeh = false
customerped = false
customerped_2 = false
customerped_3 = false
npcBlip = false
-- Selected mission globals (used for cycling areas)
selectedMissionIndex_global = 1
missionConfig_global = nil
selectedVehicleIndex = 1

-- Taximeter Configuration
taximeter = {
    header = "",
    fare = 0,
    playerMode = false,
    enabled = false,
    customerInVeh = false,
    npcDriveChoice = false,
    vehicleHealth = 0,
    time = 0,
    billPlayer = false,
    billPlayers = {}
}
-- Get Player Job Function
function GetJob()
  -- Wait for Core to be initialized
  while Core == nil do
    Wait(0)
  end
  
  -- Check framework type and get job accordingly
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    local playerData = Core.GetPlayerData()
    return playerData.job.name
  elseif Config.Framework == "qb" or Config.Framework == "oldqb" then
    if Core and Core.Functions and Core.Functions.GetPlayerData then
      local playerData = Core.Functions.GetPlayerData()
      return playerData.job.name
    else
      print("[ERROR] QBCore not properly initialized")
      return nil
    end
  else
    print("[ERROR] Unknown framework: " .. tostring(Config.Framework))
    return nil
  end
end
-- Wait for Core to Initialize Function
function WaitCore()
  while Core == nil do
    Wait(0)
  end
end
-- Trigger Server Callback Function
function TriggerCallback(callbackName, callbackData)
  local result = false
  local status = "UNKNOWN"
  local attempts = 0
  
  WaitCore()
  WaitNui()
  
  if Config.Framework == "esx" or Config.Framework == "oldesx" then
    Core.TriggerServerCallback(callbackName, function(response)
      status = "SUCCESS"
      result = response
    end, callbackData)
  elseif Config.Framework == "qb" or Config.Framework == "oldqb" then
    if Core and Core.Functions and Core.Functions.TriggerCallback then
      Core.Functions.TriggerCallback(callbackName, function(response)
        status = "SUCCESS"
        result = response
      end, callbackData)
    else
      print("[ERROR] QBCore not properly initialized or TriggerCallback function not available")
      status = "FAILED"
      result = false
    end
  else
    print("[ERROR] Unknown framework: " .. tostring(Config.Framework))
    status = "FAILED"
    result = false
  end
  
  -- Wait for response with timeout
  CreateThread(function()
    while status == "UNKNOWN" do
      Wait(1000)
      attempts = attempts + 1
      if attempts >= 4 then
        status = "FAILED"
        result = false
        break
      end
    end
  end)
  
  while status == "UNKNOWN" do
    Wait(0)
  end
  
  return result
end
-- Framework Initialization Thread
CreateThread(function()
  -- Initialize framework
  Core, Config.Framework = GetCore()
  
  -- Wait for Core to be properly initialized
  while not Core do
    Wait(1000)
    Core, Config.Framework = GetCore()
  end
  
  -- Additional check for QBCore Functions
  if Config.Framework == "qb" or Config.Framework == "oldqb" then
    while not (Core and Core.Functions) do
      Wait(1000)
      print("[DEBUG] Waiting for QBCore Functions to initialize...")
    end
  end
  
  print("[SUCCESS] Framework initialized: " .. tostring(Config.Framework))
  
  -- Get security key from server
  local serverKey = TriggerCallback("codem-taxijob:getKey")
  if serverKey then
    key = serverKey
    print("[SUCCESS] Security key obtained from server")
  else
    key = false
    print("[ERROR] Failed to get security key from server")
  end
end)
-- Notification Event Handler
RegisterNetEvent("codem-taxijob:Notify")
AddEventHandler("codem-taxijob:Notify", function(notificationData)
  NuiMessage("notify", notificationData)
end)
-- Player Data Sync Event Handler
RegisterNetEvent("codem-taxijob:SyncPlayerDataByKey")
AddEventHandler("codem-taxijob:SyncPlayerDataByKey", function(key, value)
  NuiMessage("SyncPlayerDataByKey", {
    key = key,
    value = value
  })
  playerData[key] = value
end)
-- Wait for NUI to be Ready Function
function WaitNui()
  while not nuiReady do
    Wait(0)
  end
end
-- NUI Ready Callback
RegisterNUICallback("ready", function()
  nuiReady = true
end)
-- NUI Initialization Thread
CreateThread(function()
  while not nuiReady do
    Wait(2000)
    if NetworkIsSessionStarted() then
      SendNUIMessage({
        action = "checknui"
      })
    end
  end
end)
-- NUI Message Function
function NuiMessage(action, payload)
  WaitNui()
  SendNUIMessage({
    action = action,
    payload = payload
  })
end
-- ESX Player Loaded Event
RegisterNetEvent("esx:playerLoaded")
AddEventHandler("esx:playerLoaded", function()
  TriggerServerEvent("codem-taxijob:LoadPlayerData")
end)

-- QBCore Player Loaded Event
RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
  TriggerServerEvent("codem-taxijob:LoadPlayerData")
end)
-- Data Initialization Thread
CreateThread(function()
  Wait(3000)
  
  -- Load player data
  TriggerServerEvent("codem-taxijob:LoadPlayerData")
  
  -- Initialize NUI with config data
  NuiMessage("setMissions", Config.Missions)
  NuiMessage("setVipMissions", Config.VipMissions)
  NuiMessage("setVehicles", Config.Vehicles)
  NuiMessage("setTaxFee", Config.Tax)
  NuiMessage("setCabFee", Config.CabFee)
  NuiMessage("setXP", Config.XP)
  NuiMessage("setKey", Config.KeyBind)
  
  -- Initialize menu
  InitMenu()
end)
-- Function to spawn a ped with collision settings
function SpawnPed(modelHash, spawnCoords, freezePosition)
  -- Delete existing ped if it exists
  if DoesEntityExist(ped) then
    DeleteEntity(ped)
  end
  
  -- Request ped model
  RequestModel(modelHash)
  
  -- Wait for model to load
  while not HasModelLoaded(modelHash) do
    Wait(0)
  end
  
  -- Create ped
  local newPed = CreatePed(0, modelHash, spawnCoords, false, false)
  
  -- Freeze ped position if specified
  FreezeEntityPosition(newPed, freezePosition)
  
  -- Make ped invincible
  SetEntityInvincible(newPed, true)
  
  -- Block non-temporary events
  SetBlockingOfNonTemporaryEvents(newPed, true)
  
  -- Set no collision with other peds
  local allPeds = GetGamePool("CPed")
  for _, otherPed in pairs(allPeds) do
    if otherPed ~= newPed then
      SetEntityNoCollisionEntity(otherPed, newPed, false)
    end
  end
  
  -- Set no collision with vehicles
  local allVehicles = GetGamePool("CVehicle")
  for _, vehicle in pairs(allVehicles) do
    SetEntityNoCollisionEntity(vehicle, newPed, false)
  end
  
  return newPed
end
-- Resource Stop Event Handler
AddEventHandler("onResourceStop", function(resourceName)
  -- Only handle stop for this resource
  if GetCurrentResourceName() ~= resourceName then
    return
  end
  
  -- Clean up NPC ped
  DeleteEntity(npcped)
end)
-- NPC Initialization Thread
CreateThread(function()
  -- Spawn NPC at configured location
  npcped = SpawnPed(
    Config.NpcLocation.model,
    Config.NpcLocation.coords,
    true
  )
  
  -- Send locales to NUI
  NuiMessage("setLocales", locales)
  
  -- Create blip for NPC location
  CreateBlip(
    vector3(Config.NpcLocation.coords.x, Config.NpcLocation.coords.y, Config.NpcLocation.coords.z),
    Config.NpcLocation.blip.sprite,
    Config.NpcLocation.blip.color,
    Config.NpcLocation.blip.scale,
    Config.NpcLocation.blip.name,
    Config.NpcLocation.blip.show
  )
end)
-- Function to draw 3D text in world space
function DrawText3D(x, y, z, text)
  -- Set text properties
  SetTextScale(0.35, 0.35)
  SetTextFont(4)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextEntry("STRING")
  SetTextCentre(true)
  AddTextComponentString(text)
  
  -- Set draw origin and draw text
  SetDrawOrigin(x, y, z, 0)
  DrawText(0.0, 0.0)
  
  -- Draw background rectangle
  local textLength = string.len(text) / 370
  DrawRect(0.0, 0.0125, 0.017 + textLength, 0.03, 0, 0, 0, 75)
  
  -- Clear draw origin
  ClearDrawOrigin()
end
-- Function to create camera for menu view
function CreateCamera()
  -- Don't create camera if player is in vehicle
  if IsPedInAnyVehicle(PlayerPedId(), false) then
    return
  end
  
  -- Get camera position offset from player
  local cameraOffset = GetOffsetFromEntityInWorldCoords(PlayerPedId(), 1.38, -1.7, 0)
  
  -- Enable script cameras
  RenderScriptCams(true, true, 500, true, true)
  
  -- Destroy existing camera
  DestroyCam(cam, false)
  
  -- Create new camera if it doesn't exist
  if not DoesCamExist(cam) then
    cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    
    -- Activate camera
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 500, true, true)
    
    -- Set camera position
    SetCamCoord(cam, cameraOffset.x, cameraOffset.y, cameraOffset.z + 0.2)
    
    -- Set camera rotation
    SetCamRot(cam, 5.0, 0.0, GetEntityHeading(PlayerPedId()))
    
    -- Set camera properties
    SetCamNearClip(cam, 0.1)
    SetCamFarClip(cam, 1000.0)
    SetCamFov(cam, 68.0)
    SetCamDofFnumberOfLens(camera, 24.0)
    SetCamDofFocalLengthMultiplier(camera, 50.0)
  end
end
-- Menu Ready State
local menuReady = false

-- Menu Ready UI Event Handler
RegisterNetEvent("codem-taxijob:openReadyUi")
AddEventHandler("codem-taxijob:openReadyUi", function()
  menuReady = true
end)
-- Menu Open Event Handler
RegisterNetEvent("codem-taxijob:OpenMenu")
AddEventHandler("codem-taxijob:OpenMenu", function()
  -- Check if menu is ready
  if not menuReady then
    return
  end
  
  -- Check job requirement if enabled
  if Config.JobCheck.enable then
    local playerJob = GetJob()
    if playerJob ~= Config.JobCheck.name then
      Config.Notify(locales.not_taxi)
      return
    end
  end
  
  -- Trigger server events for cooldown and daily mission checks
  TriggerServerEvent("codem-taxijob:CheckVipCooldown")
  TriggerServerEvent("codem-taxijob:CheckDailyMission")
  
  -- Open menu UI
  NuiMessage("openmenu")
  setMissionsActive()
  
  -- Set NUI focus and create camera
  SetNuiFocus(true, true)
  CreateCamera()
end)
-- Menu Close NUI Callback
RegisterNUICallback("close", function()
  -- Remove NUI focus
  SetNuiFocus(false, false)
  
  -- Destroy camera if it exists
  if DoesCamExist(cam) then
    RenderScriptCams(false, true, 500, true, true)
    DestroyCam(cam, true)
  end
end)
-- Function to set taximeter data in NUI
function setTaximeterData(key, value)
  NuiMessage("setTaxiMeterData", {
    key = key,
    value = value
  })
end
-- Function to round numbers to specified decimal places
function round(number, decimals)
  local multiplier = decimals or 0
  if not decimals then
    multiplier = 0
  end
  
  local factor = 5 ^ multiplier
  return math.floor(number * factor + 0.5) / factor
end
-- Function to handle taximeter fare calculation
function taximeterFare(vehicle)
  CreateThread(function()
    while missionActive and taximeter.enabled do
      -- Check if player is in vehicle
      if IsPedInAnyVehicle(PlayerPedId()) then
        -- Open taxi meter if not already open
        if not taxiMeterOpen then
          taxiMeterOpen = true
          NuiMessage("openTaxiMeter")
        end
        
        -- Calculate and update fare
        taximeter.fare = Config.TaximeterFare(vehicle, taximeter.fare)
        taximeter.fare = string.format("%.2f", taximeter.fare)
        
        -- Update NUI with new fare
        setTaximeterData("fare", taximeter.fare)
        
        -- Set vehicle state for fare
        Entity(vehicle).state:set("taximeterFare", taximeter.fare, true)
      else
        -- Close taxi meter if player exits vehicle
        if taxiMeterOpen then
          NuiMessage("closeTaxiMeter")
          taxiMeterOpen = false
        end
      end
      
      Wait(1000)
    end
  end)
end
-- Function to check if vehicle model is valid for taxi job
function IsValidVehicle(vehicleModel)
  -- Check each configured vehicle
  for _, vehicle in pairs(Config.Vehicles) do
    if GetHashKey(vehicle.spawnCode) == vehicleModel then
      return true
    end
  end
  
  return false
end
-- Taxi Meter Management Thread
CreateThread(function()
  while true do
    local playerPed = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    local waitTime = 1700
    
    if currentVehicle then
      -- Check if vehicle is valid for taxi job
      if IsValidVehicle(GetEntityModel(currentVehicle)) then
        -- Only open the taxi meter when there's an active mission, VIP mission, or player-mode
        if missionActive or vipMissionActive or (taximeter and taximeter.playerMode) then
          -- Open taxi meter if not already open
          if not taxiMeterOpen then
            NuiMessage("openTaxiMeter")
            taxiMeterOpen = true
          end

          -- Update fare from vehicle state when not on VIP mission
          if not vipMissionActive then
            setTaximeterData("fare", Entity(currentVehicle).state.taximeterFare)
            waitTime = 100
          end
        end
      end
    else
      -- Close taxi meter when not in vehicle and not active/ player-mode
      if taxiMeterOpen and not (missionActive or vipMissionActive or (taximeter and taximeter.playerMode)) then
        NuiMessage("closeTaxiMeter")
        taxiMeterOpen = false
      end
    end
    
    Wait(waitTime)
  end
end)
-- Function to create blips on the map
function CreateBlip(coords, sprite, color, scale, name, show, forEntity, entity)
  if show then
    local blip
    
    -- Create blip for entity or coordinates
    if forEntity then
      blip = AddBlipForEntity(entity)
    else
      blip = AddBlipForCoord(coords)
    end
    
    -- Set blip properties
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipAsShortRange(blip, false)
    
    -- Set blip name
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    
    return blip
  end
end
-- Function to get the first free seat in a vehicle
function GetFreeSeat(vehicle)
  local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
  
  -- Check each seat from 0 to max passengers
  for seatIndex = 0, maxPassengers, 1 do
    if IsVehicleSeatFree(vehicle, seatIndex) then
      return seatIndex
    end
  end
end
-- Function to start mission timer countdown
function StartTimer(vehicle)
  CreateThread(function()
    while DoesEntityExist(vehicle) and missionActive and taximeter.time >= 0 and DoesEntityExist(customerped) do
      -- Decrease timer by 1 second
      taximeter.time = taximeter.time - 1
      
      -- Ensure timer doesn't go below 0
      if taximeter.time < 0 then
        taximeter.time = 0
      end
      
      -- Update NUI with new time
      setTaximeterData("time", taximeter.time)
      
      Wait(1000)
    end
  end)
end
-- Daily Mission Event Handler
RegisterNetEvent("codem-taxijob:AddPlayerDailyMission")
AddEventHandler("codem-taxijob:AddPlayerDailyMission", function()
  TriggerServerEvent("codem-taxijob:AddDailyMissionProcess", "deliver_player")
end)
-- Customer delivered flag
local customerDelivered = false

-- Function to create customer for mission
function CreateCustomer(missionConfig, vehicle)
  -- Don't spawn NPCs when player mode is enabled
  if taximeter and taximeter.playerMode then
    return
  end

  Config.Notify(locales.searching_customer)
    if missionActive then
        if DoesEntityExist(customerped) then
            DeleteEntity(customerped)
        end
        if DoesEntityExist(customerped_2) then
            DeleteEntity(customerped_2)
        end
        if DoesEntityExist(customerped_3) then
            DeleteEntity(customerped_3)
        end
        if DoesBlipExist(npcBlip) then
            RemoveBlip(npcBlip)
        end
    end

    taximeter.fare = 0
    setTaximeterData("fare", 0)
    taximeter.customerInVeh = false
    setTaximeterData("customerInVeh", taximeter.customerInVeh)
    local changeLocation = false
    Wait(math.random(10000, 15000))

    if not missionActive then
        return
    end

    taximeter.enabled = false
    setTaximeterData("enabled", taximeter.enabled)
    local payment = math.random(missionConfig.minPayment, missionConfig.maxPayment)
    TriggerServerEvent('codem-taxijob:SetFare', payment)
    taximeter.fare = payment
    setTaximeterData("fare", payment)
    local selectedFinishCoords = missionConfig.finishLocations[math.random(1, #missionConfig.finishLocations)]
    local selectedCoords = missionConfig.npcSpawnLocations[math.random(1, #missionConfig.npcSpawnLocations)]
    local model = Config.NpcModels[math.random(1, #Config.NpcModels)]
    customerped = SpawnPed(model, selectedCoords, false)
    local finished = false

    Wait(500)
    Config.Notify(locales.customer_found)
    SetNewWaypoint(selectedCoords.x, selectedCoords.y)
    npcBlip = CreateBlip(selectedCoords, 388, 5, 0.7, locales.taxi_customer, true)
    SetVehicleBodyHealth(vehicle, 1000.0)

    CreateThread(function()
        while not taximeter.playerMode and not finished do
            Wait(100)
        end
        if not finished then
            DeleteEntity(customerped)
            DeleteWaypoint()
            RemoveBlip(npcBlip)
        end
    end)

    CreateThread(function()
        while not changeLocation do
            Wait(100)
        end
        DeleteEntity(customerped)
        DeleteWaypoint()
        RemoveBlip(npcBlip)
    end)

    CreateThread(function()
        local notification = false
        local callcustomer = false
        local finaldest = false
        while missionActive and DoesEntityExist(customerped) and not finaldest do
            local cd = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local customerCoords = GetEntityCoords(customerped)
            local dist = #(playerCoords - vector3(customerCoords.x, customerCoords.y, customerCoords.z))
            if dist < 4.0 and not IsPedInAnyVehicle(customerped) and not finished and not callcustomer then
                cd = 0
                DrawText3D(customerCoords.x, customerCoords.y, customerCoords.z, locales.call_customer)
                if IsControlJustPressed(0, Config.KeyBind.call_customer) then
                    callcustomer = true
                    SetVehicleDoorsLocked(vehicle, 1)
                    TaskEnterVehicle(customerped, vehicle, -1, GetFreeSeat(vehicle), 1.0, 1, 0)
                    while not IsPedInAnyVehicle(customerped) do
                        Wait(0)
                    end
                    local choice = math.random(1, 3)
                    if choice == 1 then
                        taximeter.npcDriveChoice = "careful"
                    elseif choice == 2 then
                        taximeter.npcDriveChoice = "fast"
                        taximeter.time = math.random(50, 100)
                        setTaximeterData("time", taximeter.time)
                        StartTimer(vehicle)
                        setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    elseif choice == 3 then
                        taximeter.npcDriveChoice = false
                    end
                    taximeter.customerInVeh = true
                    setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    setTaximeterData("customerInVeh", taximeter.customerInVeh)
                    TriggerServerEvent('codem-taxijob:ConfirmPickup')
                    SetNewWaypoint(selectedFinishCoords.x, selectedFinishCoords.y)
                    RemoveBlip(npcBlip)
                    Config.Notify(locales.take_customer)
                end
            end
            local finishDist = #(playerCoords - selectedFinishCoords)
            if finishDist < 30.0 and taximeter.customerInVeh then
                cd = 0
                local vehSpeed = GetEntitySpeed(vehicle)
                if not notification then
                    Config.Notify(locales.stop_vehicle)
                    notification = true
                end
                if vehSpeed <= 0.5 then
                    finished = true
                    TaskLeaveVehicle(customerped, vehicle, 0)
                    TaskWanderStandard(customerped, 10.0, 10)
                    local cutpercent = 100 - (math.floor(GetVehicleBodyHealth(vehicle)) / 10)
                    local cut = (taximeter.fare * cutpercent) / 100
                    if taximeter.npcDriveChoice == "careful" then
                        taximeter.fare = taximeter.fare - cut
                    end
                    if taximeter.npcDriveChoice == "fast" then
                        if taximeter.time <= 0 then
                            taximeter.fare = taximeter.fare / 2
                        end
                    end
                    setTaximeterData("fare", taximeter.fare)
                    TriggerServerEvent('codem-taxijob:Pay', taximeter.fare, math.random(missionConfig.minXP, missionConfig.maxXP),
                        key, missionConfig.header)
                    TriggerServerEvent('codem-taxijob:AddDailyMissionProcess', "deliver_npc")
                    taximeter.npcDriveChoice = false
                    setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    Wait(math.random(12000, 18000))
                    finaldest = true
                    if missionActive then
                        CreateCustomer(missionConfig, vehicle)
                    end
                end
            end
            if taximeter.npcDriveChoice == 'careful' then
                setTaximeterData("vehicleHealth", math.floor(GetVehicleBodyHealth(vehicle)) / 10)
            end
            Wait(cd)
        end
    end)
end
CreateCustomer = CreateCustomer

-- Debug command removed for security (triggerpay eliminated)
-- NUI Callback for getting leaderboard data
RegisterNUICallback("getLeaderboard", function(data, cb)
  local leaderboardData = TriggerCallback("codem-taxijob:GetLeaderboard")
  cb(leaderboardData)
end)
-- Event handler for showing bills to players
RegisterNetEvent("codem-taxijob:ShowBill")
AddEventHandler("codem-taxijob:ShowBill", function(billData)
  NuiMessage("ShowBill", billData)
  SetNuiFocus(true, true)
end)
-- NUI Callback for paying bills
RegisterNUICallback("payBill", function(billData, cb)
  TriggerServerEvent("codem-taxijob:PayBill", billData)
  print("payBill")
  SetNuiFocus(false, false)
end)
-- NUI Callback for starting VIP missions
RegisterNUICallback("startVip", function(data, cb)
  -- Check if any mission is already active
  if missionActive or vipMissionActive then
    Config.Notify(locales.mission_active)
    return
  end
  
  local selectedVehicleIndex = tonumber(data.selectedVehicle) + 1
  local selectedMission = data.selectedMission
  local vehicleConfig = Config.Vehicles[selectedVehicleIndex]
  
  -- Check VIP mission cooldown
  local missionId = tostring(selectedMission.id)
  if playerData.vipCooldown[missionId] then
    Config.Notify(locales.you_have_cd)
    return
  end
  vipMissionActive = true
  setMissionsActive()
  NuiMessage("openTaxiMeter")
  TriggerServerEvent("codem-taxijob:SetFare", selectedMission.payment)
  
  -- Initialize taximeter for VIP mission
  taximeter = {
    header = "",
    fare = selectedMission.payment,
    playerMode = false,
    enabled = false,
    customerInVeh = false,
    npcDriveChoice = false,
    vehicleHealth = 0,
    time = 0,
    billPlayer = false,
    billPlayers = {}
  }
  -- Set all taximeter data
  setTaximeterData("header", taximeter.header)
  setTaximeterData("playerMode", taximeter.playerMode)
  setTaximeterData("enabled", taximeter.enabled)
  setTaximeterData("customerInVeh", taximeter.customerInVeh)
  setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
  setTaximeterData("vehicleHealth", taximeter.vehicleHealth)
  setTaximeterData("time", taximeter.time)
  setTaximeterData("billPlayer", taximeter.billPlayer)
  setTaximeterData("billPlayers", taximeter.billPlayers)
  -- Spawn vehicle and customers
  spawnedVeh = SpawnVehicle(vehicleConfig.spawnCode, Config.VehicleSpawnLocation)
  customerped = SpawnPed(selectedMission.ped, vector3(selectedMission.spawnLocation.x, selectedMission.spawnLocation.y, selectedMission.spawnLocation.z), false)
  
  -- Spawn additional customers if configured
  if selectedMission.ped_2 then
    customerped_2 = SpawnPed(selectedMission.ped_2, vector3(selectedMission.spawnLocation.x, selectedMission.spawnLocation.y, selectedMission.spawnLocation.z), false)
  end
  
  if selectedMission.ped_3 then
    customerped_3 = SpawnPed(selectedMission.ped_3, vector3(selectedMission.spawnLocation.x, selectedMission.spawnLocation.y, selectedMission.spawnLocation.z), false)
  end
  -- Close NUI and set waypoint
  NuiMessage("close")
  SetNewWaypoint(selectedMission.spawnLocation.x, selectedMission.spawnLocation.y)
  
  -- Create blip for customer location
  npcBlip = CreateBlip(vector3(selectedMission.spawnLocation.x, selectedMission.spawnLocation.y, selectedMission.spawnLocation.z), 388, 5, 0.7, locales.taxi_customer, true)
  -- VIP Mission Thread
  local customerDelivered = false
  CreateThread(function()
    local missionCompleted = false
    local customerCalled = false
    local stopNotified = false
    local waitTime = 1000
    
    while vipMissionActive do
      if not DoesEntityExist(customerped) or missionCompleted then
        break
      end
      
      
      local playerCoords = GetEntityCoords(PlayerPedId())
      local customerCoords = GetEntityCoords(customerped)
      local distanceToCustomer = #(playerCoords - vector3(customerCoords.x, customerCoords.y, customerCoords.z))
      
      local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      if DoesEntityExist(currentVehicle) then
        if currentVehicle ~= spawnedVeh then
          StopMission()
        end
      end
      -- Customer pickup logic
      if distanceToCustomer < 4.0 then
        if not IsPedInAnyVehicle(customerped) then
          if not customerDelivered and not customerCalled then
            waitTime = 0
            DrawText3D(customerCoords.x, customerCoords.y, customerCoords.z, locales.call_customer)
            
            if IsControlJustPressed(0, Config.KeyBind.call_customer) then
              customerCalled = true
              TaskEnterVehicle(customerped, spawnedVeh, -1, GetFreeSeat(spawnedVeh), 1.0, 1, 0)
              
              -- Handle second customer if exists
              if selectedMission.ped_2 then
                while not IsPedInAnyVehicle(customerped) do
                  Wait(0)
                end
                
                if IsPedHuman(customerped_2) then
                  TaskEnterVehicle(customerped_2, spawnedVeh, -1, GetFreeSeat(spawnedVeh), 1.0, 1, 0)
                else
                  TaskEnterVehicle(customerped_2, spawnedVeh, -1, GetFreeSeat(spawnedVeh), 1.0, 16, 0)
                end
              end
              
              -- Handle third customer if exists
              if selectedMission.ped_3 then
                while not IsPedInAnyVehicle(customerped_2) do
                  Wait(0)
                end
                TaskEnterVehicle(customerped_3, spawnedVeh, -1, GetFreeSeat(spawnedVeh), 1.0, 1, 0)
              end
              
              -- Set destination waypoint and remove pickup blip
              TriggerServerEvent('codem-taxijob:ConfirmPickup')
              SetNewWaypoint(selectedMission.finishLocation.x, selectedMission.finishLocation.y)
              RemoveBlip(npcBlip)
              Config.Notify(locales.take_customer)
            end
          end
        end
      end
      
      -- Check if near destination
      local distanceToDestination = #(playerCoords - vector3(selectedMission.finishLocation.x, selectedMission.finishLocation.y, selectedMission.finishLocation.z))
      if distanceToDestination < 30.0 then
        if not customerDelivered then
          waitTime = 0
          local vehicleSpeed = GetEntitySpeed(spawnedVeh)
          
          if not stopNotified then
            Config.Notify(locales.stop_vehicle)
            stopNotified = true
          end
          
          if vehicleSpeed <= 1 then
            customerDelivered = true
            -- Make customers exit vehicle
            TaskLeaveVehicle(customerped, spawnedVeh, 0)
            
            if selectedMission.ped_2 then
              TaskLeaveVehicle(customerped_2, spawnedVeh, 0)
            end
            
            if selectedMission.ped_3 then
              TaskLeaveVehicle(customerped_3, spawnedVeh, 0)
            end
            
            -- Make customers wander away
            TaskWanderStandard(customerped, 10.0, 10)
            
            if selectedMission.ped_2 then
              TaskWanderStandard(customerped_2, 10.0, 10)
            end
            
            if selectedMission.ped_3 then
              TaskWanderStandard(customerped_3, 10.0, 10)
            end
            
            missionCompleted = true
            
            -- Complete mission and pay player
            TriggerServerEvent("codem-taxijob:AddDailyMissionProcess", "deliver_vip")
            TriggerServerEvent("codem-taxijob:AddVipCooldown", selectedMission.id)
            TriggerServerEvent("codem-taxijob:Pay", taximeter.fare, math.random(selectedMission.minxp, selectedMission.maxxp), key, selectedMission.name)
            
            NuiMessage("closeTaxiMeter")
            Wait(3000)
            -- Clean up entities
            if DoesEntityExist(customerped) then
              DeleteEntity(customerped)
            end
            
            if DoesEntityExist(customerped_2) then
              DeleteEntity(customerped_2)
            end
            
            if DoesEntityExist(customerped_3) then
              DeleteEntity(customerped_3)
            end
            
            if DoesBlipExist(npcBlip) then
              RemoveBlip(npcBlip)
            end
          end
        end
      end
      Wait(waitTime)
    end
  end)
  
  Wait(1700)
  setTaximeterData("fare", taximeter.fare)
end)
-- Function to update mission status in NUI
function setMissionsActive()
  NuiMessage("setMissionsActive", {
    missionActive = missionActive,
    vipMissionActive = vipMissionActive
  })
end
-- Function to stop and cleanup missions
local function StopMission()
  -- Set mission flags to false
  missionActive = false
  vipMissionActive = false
  TriggerServerEvent("codem-taxijob:CancelMission")
  
  -- IMPORTANT: Close taximeter NUI
  SendNUIMessage({
      action = "closeTaxiMeter"
  })
  
  -- Reset taximeter data
  if taximeter then
      taximeter.fare = 0
      taximeter.customerInVeh = false
      taximeter.enabled = false
      taximeter.playerMode = false
      setTaximeterData("fare", 0)
      setTaximeterData("customerInVeh", false)
      setTaximeterData("enabled", false)
      setTaximeterData("playerMode", false)
  end
  
  -- Clean up entities
  if DoesEntityExist(customerped) then
      DeleteEntity(customerped)
  end
  if DoesEntityExist(customerped_2) then
      DeleteEntity(customerped_2)
  end
  if DoesEntityExist(customerped_3) then
      DeleteEntity(customerped_3)
  end
  if DoesBlipExist(npcBlip) then
      RemoveBlip(npcBlip)
  end
  
  -- Delete vehicle if exists (spawnedVeh used throughout)
  if DoesEntityExist(spawnedVeh) then
      Config.RemoveVehiclekey(GetVehicleNumberPlateText(spawnedVeh), GetEntityModel(spawnedVeh), spawnedVeh)
      DeleteVehicle(spawnedVeh)
      spawnedVeh = nil
  end

  DeleteWaypoint()

  -- Clean up any customer peds and blips
  if DoesEntityExist(customerped) then
      DeleteEntity(customerped)
  end
  if DoesEntityExist(customerped_2) then
      DeleteEntity(customerped_2)
  end
  if DoesEntityExist(customerped_3) then
      DeleteEntity(customerped_3)
  end
  if DoesBlipExist(npcBlip) then
      RemoveBlip(npcBlip)
  end

  vipMissionActive = false
  NuiMessage("closeTaxiMeter")
  taxiMeterOpen = false
  
  setMissionsActive()
end
-- NUI Callback to stop missions
RegisterNUICallback("stop", function()
  StopMission()
end)

-- NUI Callback for notifications
RegisterNUICallback("notify", function(message, cb)
  Config.Notify(message)
end)

CreateThread(function()
  local wasInVehicle = false
  
  while true do
      Wait(1000)  -- Check every second
      local playerPed = PlayerPedId()
      local isInVehicle = IsPedInAnyVehicle(playerPed, false)
      
      -- Player just exited vehicle
      if not isInVehicle and wasInVehicle then
          -- Close taximeter if not on active mission
          if not missionActive and not vipMissionActive then
              SendNUIMessage({
                  action = "closeTaxiMeter"
              })
          end
      end
      
      wasInVehicle = isInVehicle
  end
end)
-- NUI Callback for starting regular missions
RegisterNUICallback("start", function(data, cb)
  -- Check if any mission is already active
  if missionActive or vipMissionActive then
    Config.Notify(locales.mission_active)
    return
  end
  
  missionActive = true
  setMissionsActive()
  
  selectedVehicleIndex = tonumber(data.selectedVehicle) + 1
  selectedMissionIndex_global = tonumber(data.selectedMission) + 1
  missionConfig_global = Config.Missions[selectedMissionIndex_global]
  local missionConfig = missionConfig_global
  local vehicleConfig = Config.Vehicles[selectedVehicleIndex]
  
  -- Initialize taximeter
  taximeter = {
    header = "",
    fare = 0,
    playerMode = false,
    enabled = false,
    customerInVeh = false,
    npcDriveChoice = false,
    vehicleHealth = 0,
    time = 0,
    billPlayer = false,
    billPlayers = {}
  }
  
  NuiMessage("openTaxiMeter")
  NuiMessage("close")
  
  spawnedVeh = SpawnVehicle(vehicleConfig.spawnCode, Config.VehicleSpawnLocation)
  setTaximeterData("header", missionConfig.header)
  CreateCustomer(missionConfig, spawnedVeh)
  -- Mission control thread
  CreateThread(function()
    while missionActive do
      -- Check if player is still in the spawned vehicle
      local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
      if DoesEntityExist(currentVehicle) then
        if currentVehicle ~= spawnedVeh then
          StopMission()
        end
      end
      
      -- Toggle between NPC and player mode
      if IsControlJustPressed(0, Config.KeyBind.npc_cabbing) then
        if taximeter.customerInVeh then
          Config.Notify(locales.cant_change_mode)
        else
          taximeter.playerMode = not taximeter.playerMode
          setTaximeterData("playerMode", taximeter.playerMode)
          taximeter.billPlayer = false
          setTaximeterData("billPlayer", taximeter.billPlayer)
          
          if not taximeter.playerMode then
            CreateCustomer(missionConfig, spawnedVeh)
          end
        end
      end
      -- Player mode controls
      if taximeter.playerMode then
        -- Toggle taximeter on/off
        if IsControlJustPressed(0, Config.KeyBind.open_taximeter) then
          -- Validate job if job check is enabled
          local canOpen = true
          
          if Config.JobCheck.enable then
              local hasCorrectJob = false
              
              if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
                  local playerData = Core.GetPlayerData()
                  hasCorrectJob = playerData.job and playerData.job.name == Config.JobCheck.name
              elseif Config.Framework == 'qb' or Config.Framework == 'oldqb' then
                  local playerData = Core.Functions.GetPlayerData()
                  hasCorrectJob = playerData.job and playerData.job.name == Config.JobCheck.name
              end
              
              if not hasCorrectJob then
                  Config.Notify(locales.not_taxi)
                  canOpen = false
              end
          end
          
          -- Only open if player has job (or job check disabled) and is on active mission
          if canOpen and (missionActive or vipMissionActive) then
              SendNUIMessage({
                  action = "openTaxiMeter"
              })
          elseif canOpen and not missionActive and not vipMissionActive then
              Config.Notify("You need to start a mission first!")  -- Add this to locales if needed
          end
        end
        -- Bill individual players with hotkeys
        -- Bill player 1 (key 157)
        if IsDisabledControlJustPressed(0, 157) then
          taximeter.billPlayers = GetPlayersInVehicle(spawnedVeh)
          if taximeter.billPlayers[1] then
            TriggerServerEvent("codem-taxijob:SendBill", taximeter.billPlayers[1].id, taximeter.fare, #taximeter.billPlayers)
          end
        end
        
        -- Bill player 2 (key 158)
        if IsDisabledControlJustPressed(0, 158) then
          taximeter.billPlayers = GetPlayersInVehicle(spawnedVeh)
          if taximeter.billPlayers[2] then
            TriggerServerEvent("codem-taxijob:SendBill", taximeter.billPlayers[2].id, taximeter.fare, #taximeter.billPlayers)
          end
        end
        
        -- Bill player 3 (key 160)
        if IsDisabledControlJustPressed(0, 160) then
          taximeter.billPlayers = GetPlayersInVehicle(spawnedVeh)
          if taximeter.billPlayers[3] then
            TriggerServerEvent("codem-taxijob:SendBill", taximeter.billPlayers[3].id, taximeter.fare, #taximeter.billPlayers)
          end
        end
        
        -- Bill player 4 (key 164)
        if IsDisabledControlJustPressed(0, 164) then
          taximeter.billPlayers = GetPlayersInVehicle(spawnedVeh)
          if taximeter.billPlayers[4] then
            TriggerServerEvent("codem-taxijob:SendBill", taximeter.billPlayers[4].id, taximeter.fare, #taximeter.billPlayers)
          end
        end
      end
      -- Toggle bill player mode or cycle through missions
      if IsControlJustPressed(0, Config.KeyBind.billPlayer) then
        if taximeter.customerInVeh then
          Config.Notify(locales.cant_change_location)
        else
          if taximeter.playerMode then
            taximeter.billPlayer = not taximeter.billPlayer
            setTaximeterData("billPlayer", taximeter.billPlayer)
            taximeter.billPlayers = GetPlayersInVehicle(spawnedVeh)
            setTaximeterData("billPlayers", taximeter.billPlayers)
          else
            -- Cycle missions via shared function
            CycleMission()
          end
        end
      end
      
      Wait(0)
    end
  end)
end)
-- Function to get all players in a vehicle with their information
function GetPlayersInVehicle(vehicle)
  local playerIds = {}
  local playersData = {}
  local maxPassengers = GetVehicleMaxNumberOfPassengers(vehicle)
  
  -- Get all player IDs in vehicle
  for seatIndex = 0, maxPassengers, 1 do
    local ped = GetPedInVehicleSeat(vehicle, seatIndex)
    if DoesEntityExist(ped) then
      local playerId = GetPlayerServerId(NetworkGetPlayerIndexFromPed(ped))
      table.insert(playerIds, playerId)
    end
  end
  
  -- Get player information for each player
  for _, playerId in pairs(playerIds) do
    local playerInfo = TriggerCallback("codem-taxijob:GetPlayerInformations", playerId)
    table.insert(playersData, playerInfo)
  end
  
  return playersData
end
-- Function to spawn a vehicle at specified location
function SpawnVehicle(modelHash, spawnLocation)
  -- Request vehicle model
  RequestModel(modelHash)
  
  -- Wait for model to load
  while not HasModelLoaded(modelHash) do
    Wait(0)
  end
  
  -- Create vehicle
  local vehicle = CreateVehicle(modelHash, spawnLocation.x, spawnLocation.y, spawnLocation.z, true, true)
  
  -- Set vehicle heading
  SetEntityHeading(vehicle, spawnLocation.w)
  
  -- Give vehicle key to player
  Config.GiveVehicleKey(GetVehicleNumberPlateText(vehicle), modelHash, vehicle)
  
  -- Set vehicle fuel to full
  Config.SetVehicleFuel(vehicle, 100.0)
  
  -- Warp player into driver seat
  TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
  
  return vehicle
end

-- Cycle to the next available mission/area and spawn customer
function CycleMission()
  if not missionActive then
    return
  end

  local nextMissionIndex = selectedMissionIndex_global + 1
  if nextMissionIndex > #Config.Missions then
    nextMissionIndex = 1
  end

  local nextMission = Config.Missions[nextMissionIndex]
  local requiredLevel = (nextMission and nextMission.level) or 1
  local playerLevel = playerData.level or 0

  if requiredLevel <= playerLevel then
    selectedMissionIndex_global = nextMissionIndex
    missionConfig_global = Config.Missions[selectedMissionIndex_global]
    setTaximeterData("header", missionConfig_global.header)
    CreateCustomer(missionConfig_global, spawnedVeh)
  else
    Config.Notify(locales.not_enough_level)
  end
end

-- NUI callback: change area (triggered from NUI key press)
RegisterNUICallback("changeArea", function(data, cb)
  CycleMission()
  if cb then cb(true) end
end)

AddEventHandler('onResourceStop', function(resourceName)
  if GetCurrentResourceName() == resourceName then
      -- Close taximeter
      SendNUIMessage({
          action = "closeTaxiMeter"
      })
      
      -- Close main menu
      SendNUIMessage({
          action = "close"
      })
      
      -- Clean up entities
      if DoesEntityExist(customerped) then
          DeleteEntity(customerped)
      end
      if DoesEntityExist(customerped_2) then
          DeleteEntity(customerped_2)
      end
      if DoesEntityExist(customerped_3) then
          DeleteEntity(customerped_3)
      end
      if DoesBlipExist(npcBlip) then
          RemoveBlip(npcBlip)
      end
        if DoesEntityExist(spawnedVeh) then
          DeleteVehicle(spawnedVeh)
          spawnedVeh = nil
        end
  end
end)