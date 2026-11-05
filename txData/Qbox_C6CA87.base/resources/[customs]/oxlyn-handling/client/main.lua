

-- oxlyn-handling : client-side editor

local isOpen = false          -- editor UI is open
local isDriving = false       -- NUI focus released so the player can drive
local vehicle = 0             -- vehicle being edited
local modelKey = nil          -- tostring(model hash) of that vehicle
local stockValues = {}        -- [fieldName] = stock/default value
local currentValues = {}      -- [fieldName] = current edited value
local activeFields = {}       -- list of field defs readable+writable on this vehicle

EditorSession = { vehicle = 0 }

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function notify(msg, ntype)
  SendNUIMessage({ action = "notify", msg = msg, ntype = ntype or "info" })
end

-- Returns (label, displayName)
local function getVehicleLabel(veh)
  local model = GetEntityModel(veh)
  local displayName = GetDisplayNameFromVehicleModel(model)
  local label = GetLabelText(displayName)
  if label == "NULL" or label == "" then
    label = displayName
  end
  return label, displayName
end

local function readField(veh, field)
  return HandlingIO.read(veh, field)
end

local function writeField(veh, field, value)
  return HandlingIO.write(veh, field, value)
end

-- Fields that need the car to be "nudged" so the physics pick up the change
local suspensionFields = {
  fSuspensionRaise = true,
  fSuspensionUpperLimit = true,
  fSuspensionLowerLimit = true,
  fSuspensionForce = true,
  fSuspensionCompDamp = true,
  fSuspensionReboundDamp = true,
  fSuspensionBiasFront = true,
  fAntiRollBarForce = true,
  fAntiRollBarBiasFront = true,
  fRollCentreHeightFront = true,
  fRollCentreHeightRear = true,
  fMass = true,
  vecCentreOfMassOffset = true,
  vecInertiaMultiplier = true,
}

local lastNudge = 0

local function nudgeVehicle(veh)
  local now = GetGameTimer()
  if now - lastNudge < 250 then return end
  lastNudge = now

  if not DoesEntityExist(veh) then return end
  if GetEntitySpeed(veh) > 1.5 then return end
  if not IsVehicleOnAllWheels(veh) then return end

  local coords = GetEntityCoords(veh)
  SetEntityCoordsNoOffset(veh, coords.x, coords.y, coords.z + 0.06, false, false, false)
  SetVehicleOnGroundProperly(veh, 5.0)
  SetEntityVelocity(veh, 0.0, 0.0, 0.03)
end

local function touchesSuspension(values)
  for name in pairs(values or {}) do
    if suspensionFields[name] then
      return true
    end
  end
  return false
end

---------------------------------------------------------------------
-- Vehicle snapshot / restore (used when respawning after save)
---------------------------------------------------------------------

local function snapshotVehicle(veh)
  local snap = {
    model = GetEntityModel(veh),
    pos = GetEntityCoords(veh),
    heading = GetEntityHeading(veh),
    velocity = GetEntityVelocity(veh),
    plate = GetVehicleNumberPlateText(veh),
    plateIdx = GetVehicleNumberPlateTextIndex(veh),
    bodyHealth = GetVehicleBodyHealth(veh),
    engineHealth = GetVehicleEngineHealth(veh),
    tankHealth = GetVehiclePetrolTankHealth(veh),
    fuel = GetVehicleFuelLevel(veh),
    dirt = GetVehicleDirtLevel(veh),
    engineOn = GetIsVehicleEngineRunning(veh),
  }

  snap.col1, snap.col2 = GetVehicleColours(veh)
  snap.pearl, snap.wheelCol = GetVehicleExtraColours(veh)

  if GetIsVehiclePrimaryColourCustom(veh) then
    snap.customPrimary = { GetVehicleCustomPrimaryColour(veh) }
  end
  if GetIsVehicleSecondaryColourCustom(veh) then
    snap.customSecondary = { GetVehicleCustomSecondaryColour(veh) }
  end

  snap.wheelType = GetVehicleWheelType(veh)
  snap.windowTint = GetVehicleWindowTint(veh)
  snap.livery = GetVehicleLivery(veh)
  snap.tyreSmoke = { GetVehicleTyreSmokeColor(veh) }
  snap.neonColor = { GetVehicleNeonLightsColour(veh) }

  snap.mods, snap.toggles, snap.neon, snap.extras = {}, {}, {}, {}

  for i = 0, 49 do
    snap.mods[i] = GetVehicleMod(veh, i)
  end
  for _, i in ipairs({ 17, 18, 19, 20, 21, 22 }) do
    snap.toggles[i] = IsToggleModOn(veh, i)
  end
  for i = 0, 3 do
    snap.neon[i] = IsVehicleNeonLightEnabled(veh, i)
  end
  for i = 0, 20 do
    if DoesExtraExist(veh, i) then
      snap.extras[i] = IsVehicleExtraTurnedOn(veh, i)
    end
  end

  return snap
end

local function applySnapshot(veh, snap)
  SetVehicleModKit(veh, 0)
  SetVehicleWheelType(veh, snap.wheelType)

  for i, v in pairs(snap.mods) do
    if v and v >= 0 then
      SetVehicleMod(veh, i, v, false)
    end
  end
  for i, on in pairs(snap.toggles) do
    ToggleVehicleMod(veh, i, on)
  end
  for i, on in pairs(snap.extras) do
    SetVehicleExtra(veh, i, not on)
  end

  SetVehicleColours(veh, snap.col1, snap.col2)
  SetVehicleExtraColours(veh, snap.pearl, snap.wheelCol)

  if snap.customPrimary then
    SetVehicleCustomPrimaryColour(veh, table.unpack(snap.customPrimary))
  end
  if snap.customSecondary then
    SetVehicleCustomSecondaryColour(veh, table.unpack(snap.customSecondary))
  end

  SetVehicleWindowTint(veh, snap.windowTint)
  if snap.livery and snap.livery >= 0 then
    SetVehicleLivery(veh, snap.livery)
  end

  SetVehicleTyreSmokeColor(veh, table.unpack(snap.tyreSmoke))
  for i, on in pairs(snap.neon) do
    SetVehicleNeonLightEnabled(veh, i, on)
  end
  SetVehicleNeonLightsColour(veh, table.unpack(snap.neonColor))

  SetVehicleNumberPlateText(veh, snap.plate)
  SetVehicleNumberPlateTextIndex(veh, snap.plateIdx)
  SetVehicleBodyHealth(veh, snap.bodyHealth + 0.0)
  SetVehicleEngineHealth(veh, snap.engineHealth + 0.0)
  SetVehiclePetrolTankHealth(veh, snap.tankHealth + 0.0)
  SetVehicleFuelLevel(veh, snap.fuel + 0.0)
  SetVehicleDirtLevel(veh, snap.dirt + 0.0)
end

-- Delete and recreate the vehicle so new handling is picked up from scratch
local function respawnVehicle()
  local oldVeh = vehicle
  if not DoesEntityExist(oldVeh) then return end

  local ped = PlayerPedId()
  local mySeat = nil

  for seat = -1, GetVehicleMaxNumberOfPassengers(oldVeh) - 1 do
    local occupant = GetPedInVehicleSeat(oldVeh, seat)
    if occupant == ped then
      mySeat = seat
    elseif occupant ~= 0 and IsPedAPlayer(occupant) then
      return -- don't respawn if another player is aboard
    end
  end
  if mySeat == nil then return end

  local snap = snapshotVehicle(oldVeh)

  RequestModel(snap.model)
  local deadline = GetGameTimer() + 3000
  while not HasModelLoaded(snap.model) and GetGameTimer() < deadline do
    Wait(0)
  end
  if not HasModelLoaded(snap.model) then return end

  local newVeh = CreateVehicle(snap.model, snap.pos.x, snap.pos.y, snap.pos.z, snap.heading, true, false)
  if not DoesEntityExist(newVeh) then return end

  SetEntityAsMissionEntity(newVeh, true, true)
  applySnapshot(newVeh, snap)
  SetPedIntoVehicle(ped, newVeh, mySeat)

  if snap.engineOn then
    SetVehicleEngineOn(newVeh, true, true, false)
  end
  SetEntityVelocity(newVeh, snap.velocity.x, snap.velocity.y, snap.velocity.z)

  SetEntityAsMissionEntity(oldVeh, true, true)
  DeleteVehicle(oldVeh)

  vehicle = newVeh
  EditorSession.vehicle = newVeh
  SetModelAsNoLongerNeeded(snap.model)
end

---------------------------------------------------------------------
-- Value / field helpers
---------------------------------------------------------------------

-- Kept as a hook; currently returns the value unchanged
local function passthrough(field, value)
  return value
end

local function sanitizeValue(field, value)
  if field.type == "vector" then
    return {
      x = tonumber(value.x) or 0.0,
      y = tonumber(value.y) or 0.0,
      z = tonumber(value.z) or 0.0,
    }
  end
  return (tonumber(value) or 0.0) + 0.0
end

-- Field list sent to the NUI
local function buildFieldList()
  local out = {}
  for i, field in ipairs(activeFields) do
    local stock = stockValues[field.name]
    local current = currentValues[field.name]
    out[i] = {
      name = field.name,
      type = field.type,
      cat = field.cat,
      min = field.min,
      max = field.max,
      step = field.step,
      dec = field.dec,
      adv = field.adv or false,
      unit = field.unit,
      value = passthrough(field, current),
      def = passthrough(field, stock),
    }
  end
  return out
end

-- Cached, sorted list of every vehicle model
local vehicleListCache = nil

local function getVehicleList()
  if vehicleListCache then return vehicleListCache end

  local models = GetAllVehicleModels()
  if type(models) ~= "table" or #models == 0 then
    return {}
  end

  local list = {}
  for i = 1, #models do
    local name = string.lower(models[i])
    local hash = GetHashKey(name)
    local displayName = GetDisplayNameFromVehicleModel(hash)
    local label = GetLabelText(displayName)
    if label == "NULL" or label == "" then
      label = displayName
    end
    list[#list + 1] = { n = name, l = label, h = tostring(hash) }
  end

  table.sort(list, function(a, b)
    return string.lower(a.l) < string.lower(b.l)
  end)

  vehicleListCache = list
  return list
end

local function buildPresets(customPresets)
  local builtin = {}
  for i, preset in ipairs(Config.Presets or {}) do
    local count = 0
    for _ in pairs(preset.fields) do
      count = count + 1
    end
    builtin[i] = {
      id = preset.id,
      icon = preset.icon or "gauge",
      label = Lang(preset.label),
      desc = Lang(preset.desc),
      fields = preset.fields,
      count = count,
    }
  end
  return { builtin = builtin, custom = customPresets or {} }
end

-- Fields whose current value differs from stock. Returns (changedTable, count).
-- NOTE: for vectors only the X component is compared (as in the original).
local function getChangedFields()
  local changed, count = {}, 0
  for _, field in ipairs(activeFields) do
    local current = currentValues[field.name]
    local stock = stockValues[field.name]
    local differs
    if field.type == "vector" then
      differs = math.abs(current.x - stock.x) > 1.0e-6
    else
      differs = math.abs(current - stock) > 1.0e-6
    end
    if differs then
      changed[field.name] = current
      count = count + 1
    end
  end
  return changed, count
end

---------------------------------------------------------------------
-- NUI focus / open / close
---------------------------------------------------------------------

local function focusNui()
  SetNuiFocus(true, true)
  CreateThread(function()
    -- Re-assert focus for a few frames in case the game steals it
    for _ = 1, 6 do
      Wait(0)
      if not (isOpen and not isDriving) then return end
      if not IsNuiFocused() then
        SetNuiFocus(true, true)
      end
    end
  end)
end

local function closeEditor(silent)
  if not isOpen then return end

  isOpen = false
  isDriving = false
  EditorSession.vehicle = 0
  vehicle = 0
  modelKey = nil
  stockValues, currentValues, activeFields = {}, {}, {}

  SetNuiFocus(false, false)
  SendNUIMessage({ action = "close" })

  if not silent then
    PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
  end
end

local function getCurrentVehicle()
  local ped = PlayerPedId()
  if not IsPedInAnyVehicle(ped, false) then return 0 end

  local veh = GetVehiclePedIsIn(ped, false)
  if veh == 0 or not DoesEntityExist(veh) then return 0 end
  return veh
end

local function openEditor()
  if isOpen then return end

  local veh = getCurrentVehicle()
  if veh == 0 then
    return notify(_U("not_in_vehicle"), "err")
  end

  Framework.TriggerCallback("oxlyn-handling:requestOpen", function(allowed, customPresets, groups)
    if allowed == false then
      return notify(_U("no_permission"), "err")
    end
    if allowed ~= true then
      return notify(_U("server_unavailable"), "err")
    end
    if not DoesEntityExist(veh) then return end

    vehicle = veh
    EditorSession.vehicle = veh

    local model = GetEntityModel(veh)
    modelKey = tostring(model)

    local override = OxlynHandlingGetOverride and OxlynHandlingGetOverride(modelKey) or nil
    local localStock = OxlynHandlingGetLocalStock and OxlynHandlingGetLocalStock(modelKey) or nil

    activeFields = {}
    for _, field in ipairs(HandlingFields) do
      local value = readField(veh, field)
      if value ~= nil and writeField(veh, field, value) then
        activeFields[#activeFields + 1] = field
        currentValues[field.name] = value

        -- NOTE: mirrors the decompiled control flow exactly. If an override
        -- exists but has no stock entry for this field, stockValues stays nil.
        if override then
          if override.stock and override.stock[field.name] ~= nil then
            stockValues[field.name] = override.stock[field.name]
          end
        elseif localStock then
          if localStock[field.name] ~= nil then
            stockValues[field.name] = localStock[field.name]
          end
        else
          stockValues[field.name] = value
        end
      end
    end

    local label, displayName = getVehicleLabel(veh)

    isOpen = true
    focusNui()

    SendNUIMessage({
      action = "open",
      locale = GetLocaleTable(),
      speedUnit = Config.SpeedUnit or "kmh",
      refocusKey = Config.RefocusKey or "F2",
      vehicle = {
        label = label,
        model = displayName,
        modelKey = modelKey,
        class = GetVehicleClass(veh),
        hasOverride = override ~= nil,
        group = OxlynHandlingGetGroupForModel and OxlynHandlingGetGroupForModel(modelKey) or nil,
      },
      categories = HandlingCategories,
      fields = buildFieldList(),
      presets = buildPresets(customPresets),
      groups = groups or {},
      vehicles = getVehicleList(),
      tuned = OxlynHandlingGetOverriddenKeys and OxlynHandlingGetOverriddenKeys() or {},
    })

    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
  end)
end

---------------------------------------------------------------------
-- Commands
---------------------------------------------------------------------

RegisterCommand(Config.Command, openEditor, false)

if Config.CommandAlias then
  RegisterCommand(Config.CommandAlias, openEditor, false)
end

if Config.ResetCommand then
  RegisterCommand(Config.ResetCommand, function()
    SendNUIMessage({ action = "resetUi" })
    notify(_U("toast_ui_reset"), "ok")
  end, false)
end

CreateThread(function()
  Wait(1000)
  TriggerEvent("chat:addSuggestion", "/" .. Config.Command, _U("cmd_desc"))
  if Config.ResetCommand then
    TriggerEvent("chat:addSuggestion", "/" .. Config.ResetCommand, _U("cmd_reset_desc"))
  end
end)

-- Return from "drive" mode back to the editor
RegisterCommand("oxlynhandling_return", function()
  if isOpen and isDriving then
    isDriving = false
    SetNuiFocus(true, true)
    SendNUIMessage({ action = "refocus" })
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
  end
end, false)

RegisterKeyMapping("oxlynhandling_return", "OXLYN Handling — return to editor", "keyboard", Config.RefocusKey or "F2")

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------

local function editorReady()
  return isOpen and DoesEntityExist(vehicle)
end

RegisterNUICallback("setField", function(data, cb)
  cb("ok")
  if not editorReady() then return end

  local field = HandlingFieldMap[data.name]
  if not field then return end

  local value = sanitizeValue(field, data.value)
  currentValues[field.name] = value
  writeField(vehicle, field, value)

  if suspensionFields[field.name] then
    nudgeVehicle(vehicle)
  end
end)

RegisterNUICallback("setFields", function(data, cb)
  cb("ok")
  if not editorReady() then return end

  for name, raw in pairs(data.values or {}) do
    local field = HandlingFieldMap[name]
    if field then
      local value = sanitizeValue(field, raw)
      currentValues[name] = value
      writeField(vehicle, field, value)
    end
  end

  if touchesSuspension(data.values) then
    nudgeVehicle(vehicle)
  end
end)

RegisterNUICallback("save", function(data, cb)
  if not editorReady() then
    return cb({ ok = false })
  end

  local changed, count = getChangedFields()
  local label = getVehicleLabel(vehicle)

  Framework.TriggerCallback("oxlyn-handling:save", function(success)
    if success then
      notify(_U("saved_notif", label), "ok")

      if OxlynHandlingPredict then
        OxlynHandlingPredict(modelKey, changed, stockValues)
      end

      if Config.RespawnOnSave ~= false then
        if OxlynHandlingApplyShared then
          OxlynHandlingApplyShared(modelKey, stockValues, changed)
        end
        respawnVehicle()
      end
    end

    cb({ ok = success == true, count = count })
  end, modelKey, label, changed, stockValues)
end)

RegisterNUICallback("resetField", function(data, cb)
  cb("ok")
  if not editorReady() then return end

  local field = HandlingFieldMap[data.name]
  if not field then return end

  local stock = stockValues[field.name]
  currentValues[field.name] = stock
  writeField(vehicle, field, stock)

  if suspensionFields[field.name] then
    nudgeVehicle(vehicle)
  end
end)

RegisterNUICallback("resetAll", function(data, cb)
  cb("ok")
  if not editorReady() then return end

  for _, field in ipairs(activeFields) do
    local stock = stockValues[field.name]
    currentValues[field.name] = stock
    writeField(vehicle, field, stock)
  end
  nudgeVehicle(vehicle)
end)

RegisterNUICallback("resetModel", function(data, cb)
  if not isOpen then
    return cb({ ok = false })
  end

  local label = getVehicleLabel(vehicle)

  Framework.TriggerCallback("oxlyn-handling:resetModel", function(success)
    if success then
      if DoesEntityExist(vehicle) then
        for _, field in ipairs(activeFields) do
          local stock = stockValues[field.name]
          currentValues[field.name] = stock
          writeField(vehicle, field, stock)
        end

        if OxlynHandlingPredict then
          OxlynHandlingPredict(modelKey, nil, stockValues)
        end

        if Config.RespawnOnSave ~= false then
          if OxlynHandlingApplyShared then
            OxlynHandlingApplyShared(modelKey, stockValues, nil)
          end
          respawnVehicle()
        else
          nudgeVehicle(vehicle)
        end
      end
      notify(_U("reset_notif", label), "ok")
    end

    cb({ ok = success == true })
  end, modelKey)
end)

RegisterNUICallback("savePreset", function(data, cb)
  if not isOpen then
    return cb({ ok = false })
  end

  local values = {}
  for _, field in ipairs(activeFields) do
    values[field.name] = passthrough(field, currentValues[field.name])
  end

  Framework.TriggerCallback("oxlyn-handling:savePreset", function(success, presets)
    cb({ ok = success == true, presets = presets })
  end, data.label, values)
end)

RegisterNUICallback("deletePreset", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:deletePreset", function(success, presets)
    cb({ ok = success == true, presets = presets })
  end, data.id)
end)

RegisterNUICallback("createGroup", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:createGroup", function(success, groups, gid)
    cb({ ok = success == true, groups = groups, gid = gid })
  end, data.label)
end)

RegisterNUICallback("renameGroup", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:renameGroup", function(success, groups)
    cb({ ok = success == true, groups = groups })
  end, data.id, data.label)
end)

RegisterNUICallback("deleteGroup", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:deleteGroup", function(success, groups)
    cb({ ok = success == true, groups = groups })
  end, data.id)
end)

RegisterNUICallback("toggleMember", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:toggleMember", function(success, groups)
    cb({ ok = success == true, groups = groups })
  end, data.id, data.model)
end)

RegisterNUICallback("saveGroupTune", function(data, cb)
  if not isOpen then
    return cb({ ok = false })
  end

  Framework.TriggerCallback("oxlyn-handling:saveGroupTune", function(success, groups)
    cb({ ok = success == true, groups = groups })
  end, data.id, (getChangedFields()))
end)

RegisterNUICallback("clearGroupTune", function(data, cb)
  Framework.TriggerCallback("oxlyn-handling:clearGroupTune", function(success, groups)
    cb({ ok = success == true, groups = groups })
  end, data.id)
end)

RegisterNUICallback("autoEditMeta", function(data, cb)
  if not isOpen then
    return cb({ ok = false })
  end

  -- Find the model's spawn name from the cached vehicle list
  local spawnName = nil
  for _, entry in ipairs(getVehicleList()) do
    if entry.h == modelKey then
      spawnName = entry.n
      break
    end
  end

  if not spawnName then
    return cb({ ok = false, why = "notfound" })
  end

  local values = {}
  for _, field in ipairs(activeFields) do
    values[field.name] = passthrough(field, currentValues[field.name])
  end

  Framework.TriggerCallback("oxlyn-handling:autoEditMeta", function(success, where)
    cb({ ok = success == true, where = where })
  end, spawnName, values)
end)

-- Release NUI focus so the player can test-drive
RegisterNUICallback("drive", function(data, cb)
  cb("ok")
  if not isOpen then return end
  isDriving = true
  SetNuiFocus(false, false)
end)

RegisterNUICallback("close", function(data, cb)
  cb("ok")
  closeEditor()
end)

---------------------------------------------------------------------
-- Telemetry / watchdog loop
---------------------------------------------------------------------

CreateThread(function()
  while true do
    if isOpen then
      if not DoesEntityExist(vehicle) then
        notify(_U("vehicle_gone"))
        closeEditor(true)
      elseif Config.Telemetry then
        local multiplier = (Config.SpeedUnit == "mph") and 2.236936 or 3.6
        SendNUIMessage({
          action = "telemetry",
          speed = math.floor(GetEntitySpeed(vehicle) * multiplier + 0.5),
          rpm = GetVehicleCurrentRpm(vehicle),
          gear = GetVehicleCurrentGear(vehicle),
        })
      end
      Wait(150)
    else
      Wait(500)
    end
  end
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    SetNuiFocus(false, false)
  end
end)

---------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------

RegisterCommand("handlingdiag", function()
  local veh = getCurrentVehicle()
  if veh == 0 then
    return print("[oxlyn-handling] diag: not in a vehicle")
  end

  local model = GetEntityModel(veh)
  local key = tostring(model)
  local state = GlobalState["oxlyn-handling"] or {}
  local entry = state.models and state.models[key]

  print(("[oxlyn-handling] diag: model=%s key=%s rev=%s decor=%s tune=%s"):format(
    GetDisplayNameFromVehicleModel(model),
    key,
    tostring(state.rev),
    tostring(DecorGetInt(veh, "_oxlyn_handling_rev")),
    entry and "YES" or "no"
  ))

  if not entry then return end

  local function fmt(v)
    if type(v) == "table" then
      return ("%.3f, %.3f, %.3f"):format(v.x, v.y, v.z)
    end
    return tostring(v)
  end

  for name, stored in pairs(entry.fields or {}) do
    local field = HandlingFieldMap[name]
    local live = field and HandlingIO.read(veh, field) or nil
    print(("  %s  stored=%s  vehicle=%s  writable=%s"):format(
      name, fmt(stored), fmt(live), tostring(HandlingIO.isWritable(name))
    ))
  end
end, false)

