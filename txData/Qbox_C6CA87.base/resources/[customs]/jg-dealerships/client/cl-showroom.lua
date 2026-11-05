Showroom = Showroom or {}
Showroom.Client = Showroom.Client or {}

local AUTO_ROTATE_STEP = 0.4

local currentDealershipId
local pinnedInterior
local showroomData
local showroomCamera
local showroomVehicle
local currentHeading = 120.0
local baseHeading = 120.0
local currentColour = 1
local currentZoomLevel = 1
local spawningVehicle = false
local autoRotateEnabled = false
local manualRotation = 0

local function setVehicleColour(colour)
  if not showroomVehicle then
    return false
  end

  currentColour = colour
  Utils.Client.SetVehicleColourNew(showroomVehicle, colour)
  return true
end

local function switchVehicle(model)
  if not currentDealershipId or not showroomCamera or spawningVehicle then
    return false
  end

  spawningVehicle = true

  local cameraCoords = showroomData.camera_data.coords

  if showroomVehicle then
    DeleteEntity(showroomVehicle)
  end

  model = ConvertModelToHash(model)

  if not IsModelValid(model) then
    DebugPrint("Vehicle does not exist. Please contact an admin! Vehicle: " .. model .. " returned false with IsModelValid", "warning")
    Framework.Client.Notify(Locale.vehicleDoesNotExistContactAdmin, "error")
    spawningVehicle = false
    return false
  end

  lib.requestModel(model, 60000)
  showroomVehicle = CreateVehicle(model, cameraCoords.x + 0.0, cameraCoords.y + 0.0, cameraCoords.z + 0.0, currentHeading, false, false)
  SetModelAsNoLongerNeeded(model)

  SetEntityHeading(showroomVehicle, currentHeading)
  FreezeEntityPosition(showroomVehicle, true)
  SetEntityCollision(showroomVehicle, false, true)
  SetVehicleDirtLevel(showroomVehicle, 0.0)
  setVehicleColour(currentColour)

  local vehicleCoords = GetEntityCoords(showroomVehicle)
  PointCamAtCoord(showroomCamera, vehicleCoords.x + 0.0, vehicleCoords.y + 0.0, vehicleCoords.z + 0.0)
  RenderScriptCams(true, true, 1, true, true)

  spawningVehicle = false
  return true
end

local function changeCameraView()
  if not currentDealershipId or not showroomCamera then
    return false
  end

  local zoomLevels = showroomData.camera_data.zoomLevels
  local cameraCoords = showroomData.camera_data.coords

  currentZoomLevel = currentZoomLevel + 1
  if currentZoomLevel > 4 then
    currentZoomLevel = 1
  end

  local zoom = zoomLevels[currentZoomLevel]
  local headingRadians = math.rad(cameraCoords.w)
  local offsetX = zoom * math.sin(headingRadians)
  local offsetY = zoom * math.cos(headingRadians)

  SetCamCoord(
    showroomCamera,
    cameraCoords.x + offsetX,
    cameraCoords.y - offsetY,
    cameraCoords.z + 1 + (zoomLevels[currentZoomLevel] / 10)
  )

  return true
end

function Showroom.Client.Open(dealershipId, defaultVehicle, defaultColour)
  if currentDealershipId or TestDrive.Client.IsInTestDrive() then
    return false
  end

  currentDealershipId = dealershipId

  if showroomVehicle and DoesEntityExist(showroomVehicle) then
    DeleteEntity(showroomVehicle)
    showroomVehicle = nil
  end

  local playerPed = cache.ped
  local playerCoords = GetEntityCoords(playerPed)

  if IsPedInAnyVehicle(playerPed, true) then
    currentDealershipId = nil
    Framework.Client.Notify(Locale.errorExitVehicle, "error")
    return false
  end

  if not ShowroomPreCheck(dealershipId) then
    DebugPrint("jg-dealerships:client:showroom-pre-check failed", "debug")
    currentDealershipId = nil
    return false
  end

  DoScreenFadeOut(500)
  Wait(500)
  PlayTabletAnim()

  local response = lib.callback.await("jg-dealerships:server:enter-showroom", false, dealershipId, playerCoords)
  if not response then
    currentDealershipId = nil
    DoScreenFadeIn(0)
    return false
  end

  showroomData = response.locationData
  local vehicles = response.vehicles
  local financeAllowed = response.financeAllowed
  local societies = response.societies
  local cameraCoords = showroomData.camera_data.coords
  local zoomLevels = showroomData.camera_data.zoomLevels or { 5, 8, 12, 8 }

  pcall(function()
    local interiorId = GetInteriorAtCoords(cameraCoords.x, cameraCoords.y, cameraCoords.z)

    if interiorId > 0 then
      PinInteriorInMemory(interiorId)
      lib.waitFor(function()
        return IsInteriorReady(interiorId) or nil
      end, nil, 5000)
      pinnedInterior = interiorId
    end
  end)

  local headingRadians = math.rad(cameraCoords.w)
  local offsetX = zoomLevels[1] * math.sin(headingRadians)
  local offsetY = zoomLevels[1] * math.cos(headingRadians)

  currentHeading = cameraCoords.w + 215.0
  baseHeading = currentHeading

  showroomCamera = CreateCamWithParams(
    "DEFAULT_SCRIPTED_CAMERA",
    cameraCoords.x + offsetX + 0.0,
    cameraCoords.y - offsetY + 0.0,
    cameraCoords.z + 1.5,
    0.0,
    0.0,
    cameraCoords.w + 0.0,
    0.0,
    false,
    0
  )

  SetCamActive(showroomCamera, true)
  SetCamFov(showroomCamera, 60.0)
  PointCamAtCoord(showroomCamera, cameraCoords.x + 0.0, cameraCoords.y + 0.0, cameraCoords.z + 0.0)
  RenderScriptCams(true, true, 1, true, true)
  SetFocusPosAndVel(cameraCoords.x + 0.0, cameraCoords.y + 0.0, cameraCoords.z + 0.0, 0.0, 0.0, 0.0)

  local currencies = lib.callback.await("jg-dealerships:server:get-currencies", false)

  Framework.Client.ToggleHud(false)
  DoScreenFadeIn(500)
  SetNuiFocus(true, true)

  SendNUIMessage({
    type = "showShowroom",
    dealershipId = dealershipId,
    label = showroomData.name,
    shopType = showroomData.type,
    vehicles = vehicles,
    defaultVehicle = defaultVehicle or false,
    defaultColor = defaultColour,
    colourSelectionType = showroomData.colour_selection_type,
    colourOptions = showroomData.colour_options,
    categories = showroomData.categories,
    playerBalances = GetPlayerBalances(dealershipId),
    paymentMethods = showroomData.payment_methods or { "bank", "cash" },
    currencies = currencies,
    societies = societies,
    jgGaragesRunning = GetResourceState("jg-advancedgarages") == "started",
    enablePurchase = showroomData.enable_purchase,
    enableTestDrive = showroomData.enable_test_drive,
    financeEnabled = showroomData.enable_finance and financeAllowed,
    locale = Locale,
    config = Config
  })

  return true
end

function Showroom.Client.Exit()
  if not currentDealershipId then
    return
  end

  local exited = lib.callback.await("jg-dealerships:server:exit-showroom", false, currentDealershipId)
  if not exited then
    DebugPrint("jg-dealerships:server:exit-showroom failed", "warning")
    return
  end

  StopTabletAnim()
  Framework.Client.ToggleHud(true)

  if showroomVehicle then
    DeleteEntity(showroomVehicle)
    showroomVehicle = nil
  end

  if showroomCamera and IsCamActive(showroomCamera) then
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(showroomCamera, true)
  end

  ClearFocus()

  if pinnedInterior then
    UnpinInterior(pinnedInterior)
  end

  showroomCamera = nil
  currentHeading = 120.0
  currentColour = 1
  pinnedInterior = nil
  currentDealershipId = nil
end

RegisterNUICallback("exit-showroom", function(_, callback)
  if TestDrive.Client.IsInTestDrive() then
    return callback(false)
  end

  DoScreenFadeOut(500)
  Wait(500)
  Showroom.Client.Exit()
  DoScreenFadeIn(500)
  callback(true)
end)

RegisterNUICallback("change-color", function(data, callback)
  setVehicleColour(data)
  callback(true)
end)

RegisterNUICallback("switch-vehicle", function(data, callback)
  if not switchVehicle(data.spawnCode) then
    return callback({ error = true })
  end

  callback(true)
end)

RegisterNUICallback("veh-left", function(_, callback)
  if not showroomVehicle then
    return callback({ error = true })
  end

  autoRotateEnabled = false
  manualRotation = manualRotation - 10

  if manualRotation < 0 then
    manualRotation = 360 + manualRotation
  end

  currentHeading = baseHeading + manualRotation
  SetEntityHeading(showroomVehicle, currentHeading)
  callback({ rotation = manualRotation })
end)

RegisterNUICallback("veh-right", function(_, callback)
  if not showroomVehicle then
    return callback({ error = true })
  end

  autoRotateEnabled = false
  manualRotation = manualRotation + 10

  if manualRotation > 360 then
    manualRotation = manualRotation - 360
  end

  currentHeading = baseHeading + manualRotation
  SetEntityHeading(showroomVehicle, currentHeading)
  callback({ rotation = manualRotation })
end)

RegisterNUICallback("veh-rotate", function(data, callback)
  if not showroomVehicle then
    return callback({ error = true })
  end

  autoRotateEnabled = false
  manualRotation = tonumber(data.rotation) or 0
  currentHeading = baseHeading + manualRotation
  SetEntityHeading(showroomVehicle, currentHeading)
  callback({ rotation = manualRotation })
end)

RegisterNUICallback("veh-auto-rotate", function(data, callback)
  if not showroomVehicle then
    return callback({ error = true })
  end

  autoRotateEnabled = data.enabled == true

  if autoRotateEnabled then
    CreateThread(function()
      while autoRotateEnabled and showroomVehicle do
        manualRotation = manualRotation + AUTO_ROTATE_STEP

        if manualRotation > 360 then
          manualRotation = manualRotation - 360
        end

        currentHeading = baseHeading + manualRotation
        SetEntityHeading(showroomVehicle, currentHeading)
        Wait(10)
      end
    end)
  end

  callback({
    enabled = autoRotateEnabled,
    rotation = manualRotation
  })
end)

RegisterNUICallback("change-cam-view", function(_, callback)
  if not changeCameraView() then
    return callback({ error = true })
  end

  callback(true)
end)

RegisterNUICallback("get-model-stats", function(data, callback)
  if Config.HideVehicleStats then
    return callback({})
  end

  callback(Framework.Client.GetVehicleStats(data.vehicle))
end)

RegisterNetEvent("jg-dealerships:client:open-showroom", function(dealershipId, defaultVehicle, defaultColour)
  Showroom.Client.Open(dealershipId, defaultVehicle, defaultColour)
end)

exports("openShowroom", Showroom.Client.Open)
exports("exitShowroom", Showroom.Client.Exit)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() and currentDealershipId then
    if showroomVehicle then
      DeleteEntity(showroomVehicle)
    end

    Framework.Client.ToggleHud(true)
  end
end)
