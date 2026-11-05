Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Vehicle = Interactions.Client.Vehicle or {}

local creatorActive = false

local CONTROL_ESCAPE = 200
local CONTROL_ENTER = 201
local CONTROL_SCROLL_UP = 181
local CONTROL_SCROLL_DOWN = 180
local CONTROL_MOVE_FORWARD = 32
local CONTROL_MOVE_BACK = 33
local CONTROL_MOVE_LEFT = 34
local CONTROL_MOVE_RIGHT = 35
local CONTROL_MOVE_UP = 250
local CONTROL_MOVE_DOWN = 251
local DISABLED_CONTROLS = { 30, 31, 44, 22, 23, 140 }

local function rotateEntity(entity, heading, delta)
  local nextHeading = (heading + delta) % 360.0
  SetEntityHeading(entity, nextHeading)
  return nextHeading
end

local function moveEntity(entity, direction, amount, zoneId)
  local coords = GetEntityCoords(entity)
  local forward = GetEntityForwardVector(entity)
  local right = vector3(-forward.y, forward.x, 0.0)
  local offset = vector3(0.0, 0.0, 0.0)

  if direction == "forward" then
    offset = forward * amount
  elseif direction == "back" then
    offset = forward * -amount
  elseif direction == "right" then
    offset = right * amount
  elseif direction == "left" then
    offset = right * -amount
  elseif direction == "up" then
    offset = vector3(0.0, 0.0, amount)
  elseif direction == "down" then
    offset = vector3(0.0, 0.0, -amount)
  end

  local nextCoords = coords + offset

  if zoneId and not DealershipZones.Client.IsPointInZone(zoneId, nextCoords.x, nextCoords.y) then
    return
  end

  SetEntityCoordsNoOffset(entity, nextCoords.x, nextCoords.y, nextCoords.z, false, false, false)
end

function Interactions.Client.Vehicle.Spawn(coords, model, options)
  options = options or {}

  local colour = options.colour or 0
  local collision = options.collision ~= false
  local alpha = options.alpha or 255
  local frozen = options.frozen ~= false
  local invincible = options.invincible ~= false
  local gravity = options.gravity == true
  local undriveable = options.undriveable ~= false
  local locked = options.locked ~= false

  local function spawnVehicle()
    lib.requestModel(model)

    local spawnZ = collision and coords.z or coords.z + 100.0
    local vehicle = CreateVehicle(joaat(model), coords.x, coords.y, spawnZ, coords.w or 0.0, false, false)
    local timeoutAt = GetGameTimer() + 5000

    while not DoesEntityExist(vehicle) and GetGameTimer() < timeoutAt do
      Wait(0)
    end

    if not DoesEntityExist(vehicle) then
      print("[Interactions.Client.Vehicle.Spawn] Failed to create vehicle")
      return 0
    end

    SetEntityAsMissionEntity(vehicle, true, true)

    if not collision then
      SetEntityCollision(vehicle, false, false)
      FreezeEntityPosition(vehicle, true)
    end

    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    lib.waitFor(function()
      return HasCollisionLoadedAroundEntity(vehicle) or nil
    end, "collision failed to load", 5000)

    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 1.0, false)
    SetEntityCoords(vehicle, coords.x, coords.y, groundZ and groundZ > 0.0 and groundZ or coords.z, false, false, false, false)
    SetVehicleOnGroundProperly(vehicle)
    Wait(0)

    Utils.Client.SetVehicleColourNew(vehicle, colour)

    if alpha < 255 then
      SetEntityAlpha(vehicle, alpha, false)
    end

    SetEntityCollision(vehicle, collision, collision)
    FreezeEntityPosition(vehicle, frozen)
    SetEntityInvincible(vehicle, invincible)
    SetVehicleDirtLevel(vehicle, 0.0)

    if not gravity then
      SetVehicleGravity(vehicle, false)
      DisableVehicleWorldCollision(vehicle)
    end

    if undriveable then
      SetVehicleUndriveable(vehicle, true)
    end

    if locked then
      SetVehicleDoorsLocked(vehicle, 2)
    end

    return vehicle
  end

  local wrapper = Interactions.Client.EntityStreaming.CreateWrapper(coords, model, options)
  Interactions.Client.EntityStreaming.SetupStreaming(wrapper, spawnVehicle, "vehicle")
  return wrapper
end

function Interactions.Client.Vehicle.SpawnPreview(coords, model, colour)
  return Interactions.Client.Vehicle.Spawn(coords, model, {
    colour = colour,
    collision = false,
    alpha = 200,
    frozen = true,
    invincible = true,
    gravity = false,
    undriveable = true,
    locked = true,
    enableStreaming = false
  })
end

local function getHalfWidth(entity)
  local minDimensions, maxDimensions = GetModelDimensions(GetEntityModel(entity))
  return math.max(math.abs(maxDimensions.x - minDimensions.x), math.abs(maxDimensions.y - minDimensions.y)) / 2.0
end

local function isPointInsideEntityBounds(entity, worldPoint, padding)
  local minDimensions, maxDimensions = GetModelDimensions(GetEntityModel(entity))
  local localPoint = GetOffsetFromEntityGivenWorldCoords(entity, worldPoint.x, worldPoint.y, worldPoint.z)

  return localPoint.x >= minDimensions.x - padding
    and localPoint.x <= maxDimensions.x + padding
    and localPoint.y >= minDimensions.y - padding
    and localPoint.y <= maxDimensions.y + padding
    and localPoint.z >= minDimensions.z - padding
    and localPoint.z <= maxDimensions.z + padding
end

local function getProbePoints(entity, zOffset)
  local minDimensions, maxDimensions = GetModelDimensions(GetEntityModel(entity))

  return {
    GetOffsetFromEntityInWorldCoords(entity, minDimensions.x, minDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, maxDimensions.x, maxDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, minDimensions.x, maxDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, maxDimensions.x, minDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, 0.0, maxDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, 0.0, minDimensions.y, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, maxDimensions.x, 0.0, zOffset),
    GetOffsetFromEntityInWorldCoords(entity, minDimensions.x, 0.0, zOffset)
  }
end

local function hasCollision(entity)
  if not DoesEntityExist(entity) then
    return false
  end

  local entityCoords = GetEntityCoords(entity)
  local entityHalfWidth = getHalfWidth(entity)

  for _, nearbyVehicle in ipairs(GetGamePool("CVehicle")) do
    if nearbyVehicle ~= entity and DoesEntityExist(nearbyVehicle) then
      local otherCoords = GetEntityCoords(nearbyVehicle)
      local distance = #(entityCoords - otherCoords)

      if distance < 15.0 and distance < entityHalfWidth + getHalfWidth(nearbyVehicle) then
        for _, probePoint in ipairs(getProbePoints(entity, 0.0)) do
          if isPointInsideEntityBounds(nearbyVehicle, probePoint, 0.2) then
            return true
          end
        end
      end
    end
  end

  for _, object in ipairs(GetGamePool("CObject")) do
    if DoesEntityExist(object) then
      local objectCoords = GetEntityCoords(object)
      local distance = #(entityCoords - objectCoords)

      if distance < 10.0 and objectCoords.z > entityCoords.z - 1.0 then
        local minDimensions, maxDimensions = GetModelDimensions(GetEntityModel(object))
        local objectSize = vector3(
          math.abs(maxDimensions.x - minDimensions.x),
          math.abs(maxDimensions.y - minDimensions.y),
          math.abs(maxDimensions.z - minDimensions.z)
        )

        if objectSize.x > 0.5 and objectSize.y > 0.5 and objectSize.z > 0.5 then
          if distance < entityHalfWidth + (math.max(objectSize.x, objectSize.y) / 2.0) - 0.3 then
            return true
          end
        end
      end
    end
  end

  for _, ped in ipairs(GetGamePool("CPed")) do
    if ped ~= cache.ped and DoesEntityExist(ped) then
      if #(entityCoords - GetEntityCoords(ped)) < entityHalfWidth + 1.0 then
        return true
      end
    end
  end

  local rayOffsets = {
    vector3(0.3, 0.0, 0.0),
    vector3(-0.3, 0.0, 0.0),
    vector3(0.0, 0.3, 0.0),
    vector3(0.0, -0.3, 0.0)
  }

  for _, probePoint in ipairs(getProbePoints(entity, 0.5)) do
    for _, rayOffset in ipairs(rayOffsets) do
      local rayEnd = probePoint + rayOffset
      local rayHandle = StartShapeTestRay(probePoint.x, probePoint.y, probePoint.z, rayEnd.x, rayEnd.y, rayEnd.z, -1, entity, 0)
      local _, hit, _, _, hitEntity = GetShapeTestResult(rayHandle)

      if hit == 1 and hitEntity ~= entity then
        return true
      end
    end
  end

  return false
end

local function showVehicleControls(warning)
  Interactions.Client.InstrPrmt.Show("Fine-tune vehicle position", {
    { key = "Scroll", desc = "Rotate" },
    { key = "R", desc = "Up" },
    { key = "F", desc = "Down" },
    { key = "Enter", desc = "Confirm" },
    { key = "Esc", desc = "Cancel" }
  }, "Move", warning)
end

function Interactions.Client.Vehicle.StartCreator(model, colour, zoneOptions)
  local resultPromise = promise.new()

  if creatorActive then
    print("[VehiclePlacer] already running – press Esc to cancel")
    resultPromise:resolve(false)
    return Citizen.Await(resultPromise)
  end

  creatorActive = true
  model = model or "adder"
  colour = colour or { r = 0, g = 0, b = 0 }

  local modelHash = joaat(model)
  if not IsModelInCdimage(modelHash) or not IsModelAVehicle(modelHash) then
    print("[VehiclePlacer] Invalid vehicle model: " .. model)
    creatorActive = false
    resultPromise:resolve(false)
    return Citizen.Await(resultPromise)
  end

  RequestModel(modelHash)
  while not HasModelLoaded(modelHash) do
    Wait(10)
  end

  local _, maxDimensions = GetModelDimensions(modelHash)
  SetModelAsNoLongerNeeded(modelHash)

  local spawnDistance = maxDimensions.y + 2.5
  local stage = 1
  local vehicle
  local heading = 0.0
  local ignoreCollision = false
  local warningVisible = false

  Interactions.Client.InstrPrmt.Show("Position yourself where you want to spawn the vehicle", {
    { key = "Enter", desc = "Spawn Preview" },
    { key = "Esc", desc = "Cancel" }
  })

  CreateThread(function()
    while creatorActive do
      DisableControlAction(0, CONTROL_ESCAPE, true)

      if IsDisabledControlJustReleased(0, CONTROL_ESCAPE) then
        if vehicle and DoesEntityExist(vehicle) then
          DeleteEntity(vehicle)
        end

        Interactions.Client.InstrPrmt.Hide()
        creatorActive = false
        resultPromise:resolve(false)
      end

      if stage == 1 then
        if IsControlJustReleased(0, CONTROL_ENTER) then
          local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, spawnDistance, 0.0)
          heading = GetEntityHeading(cache.ped)

          if zoneOptions and not DealershipZones.Client.IsPointInZone(zoneOptions.locationId, spawnCoords.x, spawnCoords.y) then
            Framework.Client.Notify(zoneOptions.errorMessage or Locale.displayVehicleOutsideZone, "error", 5000)
          else
            local wrapper = Interactions.Client.Vehicle.SpawnPreview({
              x = spawnCoords.x,
              y = spawnCoords.y,
              z = spawnCoords.z - 0.5,
              w = heading
            }, model, colour)

            vehicle = wrapper.entity or 0

            if vehicle == 0 then
              print("[VehiclePlacer] Failed to spawn vehicle")
              creatorActive = false
              resultPromise:resolve(false)
              return
            end

            Wait(100)

            if DoesEntityExist(vehicle) then
              SetEntityCoordsNoOffset(vehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z - 0.5, false, false, false)
              SetEntityHeading(vehicle, heading)
            end

            stage = 2
            DebugPrint("[VehiclePlacer] preview spawned – fine-tune with WASD / Q,E or scroll. Enter to confirm.")
            showVehicleControls()
          end
        end
      elseif stage == 2 and vehicle and DoesEntityExist(vehicle) then
        for _, control in ipairs(DISABLED_CONTROLS) do
          DisableControlAction(0, control, true)
        end

        local zoneId = zoneOptions and zoneOptions.locationId or nil

        if IsDisabledControlPressed(0, CONTROL_SCROLL_UP) then
          heading = rotateEntity(vehicle, heading, -5.0)
        elseif IsControlPressed(0, CONTROL_SCROLL_DOWN) then
          heading = rotateEntity(vehicle, heading, 5.0)
        end

        if IsControlPressed(0, CONTROL_MOVE_FORWARD) then
          moveEntity(vehicle, "forward", 0.025, zoneId)
        elseif IsControlPressed(0, CONTROL_MOVE_BACK) then
          moveEntity(vehicle, "back", 0.025, zoneId)
        end

        if IsControlPressed(0, CONTROL_MOVE_LEFT) then
          moveEntity(vehicle, "left", 0.025, zoneId)
        elseif IsControlPressed(0, CONTROL_MOVE_RIGHT) then
          moveEntity(vehicle, "right", 0.025, zoneId)
        end

        if IsDisabledControlPressed(0, CONTROL_MOVE_UP) then
          moveEntity(vehicle, "up", 0.01)
        elseif IsDisabledControlPressed(0, CONTROL_MOVE_DOWN) then
          moveEntity(vehicle, "down", 0.01)
        end

        local collisionDetected = hasCollision(vehicle)
        local outsideZone = zoneOptions and not DealershipZones.Client.IsPointInZone(zoneOptions.locationId, GetEntityCoords(vehicle).x, GetEntityCoords(vehicle).y)

        if collisionDetected then
          Interactions.Client.SetEntityOutline(vehicle, 226, 106, 106, 255)

          if not warningVisible then
            showVehicleControls("Warning: Collision detected! Press ENTER to ignore and place anyway.")
            warningVisible = true
          end
        else
          Interactions.Client.SetEntityOutline(vehicle, 106, 226, 119, 255)

          if warningVisible then
            showVehicleControls()
            warningVisible = false
          end
        end

        if IsControlJustReleased(0, CONTROL_ENTER) then
          if outsideZone then
            Framework.Client.Notify(zoneOptions.errorMessage or Locale.displayVehicleOutsideZone, "error", 5000)
          elseif collisionDetected and not ignoreCollision then
            ignoreCollision = true
            showVehicleControls("Warning: Collision detected! Press ENTER to ignore and place anyway.")
            warningVisible = true
          else
            local coords = GetEntityCoords(vehicle)
            DebugPrint(("[VehiclePlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading))
            DeleteEntity(vehicle)
            Interactions.Client.InstrPrmt.Hide()
            creatorActive = false
            resultPromise:resolve({
              x = coords.x,
              y = coords.y,
              z = coords.z,
              w = heading
            })
          end
        end
      end

      Wait(0)
    end
  end)

  return Citizen.Await(resultPromise)
end

RegisterNUICallback("interactions-vehicle-placer", function(data, callback)
  local model = data.vehModel or "adder"
  local colour = data.vehColour or { r = 0, g = 0, b = 0 }

  SetNuiFocus(false, false)
  callback(Interactions.Client.Vehicle.StartCreator(model, colour))
  SetNuiFocus(true, true)
end)

function Interactions.Client.Vehicle.Create(coords, model, colour, label, key, onInteract, canInteract)
  model = model or "adder"
  colour = colour or { r = 0, g = 0, b = 0 }

  local wrapper = Interactions.Client.Vehicle.Spawn(coords, model, {
    colour = colour,
    collision = true,
    frozen = false,
    invincible = true,
    gravity = true,
    undriveable = true,
    locked = true,
    enableStreaming = true
  })

  wrapper.interactionData = {
    label = label,
    key = key,
    onInteract = onInteract,
    distance = 3.0,
    canInteract = canInteract
  }

  if wrapper.entity and wrapper.entity ~= 0 and DoesEntityExist(wrapper.entity) then
    wrapper.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(
      wrapper.entity,
      "vehicle",
      label,
      key,
      onInteract,
      3.0,
      canInteract
    )
  end

  return wrapper
end
