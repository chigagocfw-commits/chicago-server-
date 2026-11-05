Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Object = Interactions.Client.Object or {}

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

local function moveEntity(entity, direction, amount)
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
  SetEntityCoordsNoOffset(entity, nextCoords.x, nextCoords.y, nextCoords.z, false, false, false)
end

local function getGroundAdjustedCoords(entity, probeZ)
  local coords = GetEntityCoords(entity)
  local foundGround, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, probeZ + 2.0, false)

  if foundGround then
    local minDimensions = GetModelDimensions(GetEntityModel(entity))
    return vector3(coords.x, coords.y, groundZ - minDimensions.z)
  end

  local rayHandle = StartShapeTestRay(coords.x, coords.y, probeZ + 2.0, coords.x, coords.y, coords.z - 10.0, -1, entity, 7)
  local _, hit, hitCoords = GetShapeTestResult(rayHandle)

  if hit then
    local minDimensions = GetModelDimensions(GetEntityModel(entity))
    return vector3(hitCoords.x, hitCoords.y, hitCoords.z - minDimensions.z)
  end

  return nil
end

function Interactions.Client.Object.Spawn(coords, model, options)
  options = options or {}

  local collision = options.collision ~= false
  local alpha = options.alpha or 255
  local frozen = options.frozen ~= false
  local invincible = options.invincible ~= false

  local function spawnObject()
    lib.requestModel(model)

    local object = CreateObject(joaat(model), coords.x, coords.y, coords.z, false, false, false)
    local timeoutAt = GetGameTimer() + 5000

    while not DoesEntityExist(object) and GetGameTimer() < timeoutAt do
      Wait(0)
    end

    if not DoesEntityExist(object) then
      print("[Interactions.Client.Object.Spawn] Failed to create object")
      return 0
    end

    if coords.w then
      SetEntityHeading(object, coords.w)
    end

    SetEntityAsMissionEntity(object, true, true)

    if alpha < 255 then
      SetEntityAlpha(object, alpha, false)
    end

    SetEntityCollision(object, collision, collision)
    FreezeEntityPosition(object, frozen)
    SetEntityInvincible(object, invincible)

    return object
  end

  local wrapper = Interactions.Client.EntityStreaming.CreateWrapper(coords, model, options)
  Interactions.Client.EntityStreaming.SetupStreaming(wrapper, spawnObject, "object")
  return wrapper
end

function Interactions.Client.Object.SpawnPreview(coords, model)
  return Interactions.Client.Object.Spawn(coords, model, {
    collision = false,
    alpha = 200,
    frozen = true,
    invincible = true,
    enableStreaming = false
  })
end

function Interactions.Client.Object.StartCreator(model)
  local resultPromise = promise.new()

  if creatorActive then
    print("[ObjectPlacer] already running – press Esc to cancel")
    resultPromise:resolve(false)
    return Citizen.Await(resultPromise)
  end

  creatorActive = true
  model = model or "xm_prop_x17_laptop_lester_01"

  local stage = 1
  local object
  local heading = 0.0

  Interactions.Client.InstrPrmt.Show("Position yourself where you want to spawn the object", {
    { key = "Enter", desc = "Spawn Preview" },
    { key = "Esc", desc = "Cancel" }
  })

  CreateThread(function()
    while creatorActive do
      DisableControlAction(0, CONTROL_ESCAPE, true)

      if IsDisabledControlJustReleased(0, CONTROL_ESCAPE) then
        if object and DoesEntityExist(object) then
          DeleteEntity(object)
        end

        Interactions.Client.InstrPrmt.Hide()
        creatorActive = false
        resultPromise:resolve(false)
      end

      if stage == 1 then
        if IsControlJustReleased(0, CONTROL_ENTER) then
          local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 2.0, 0.0)
          heading = GetEntityHeading(cache.ped)

          local wrapper = Interactions.Client.Object.SpawnPreview({
            x = spawnCoords.x,
            y = spawnCoords.y,
            z = spawnCoords.z,
            w = heading
          }, model)

          object = wrapper.entity or 0

          if object == 0 then
            print("[ObjectPlacer] Failed to spawn object")
            creatorActive = false
            resultPromise:resolve(false)
            return
          end

          local playerZ = GetEntityCoords(cache.ped).z
          local adjustedCoords = getGroundAdjustedCoords(object, playerZ)

          if adjustedCoords then
            SetEntityCoordsNoOffset(object, adjustedCoords.x, adjustedCoords.y, adjustedCoords.z, false, false, false)
          else
            PlaceObjectOnGroundProperly(object)
          end

          stage = 2
          DebugPrint("[ObjectPlacer] preview spawned – fine-tune with WASD / scroll for rotation, R/F for up/down. Enter to confirm.")
          Interactions.Client.InstrPrmt.Show("Fine-tune object position", {
            { key = "Scroll", desc = "Rotate" },
            { key = "R", desc = "Up" },
            { key = "F", desc = "Down" },
            { key = "Enter", desc = "Confirm" },
            { key = "Esc", desc = "Cancel" }
          }, "Move")
        end
      elseif stage == 2 and object and DoesEntityExist(object) then
        for _, control in ipairs(DISABLED_CONTROLS) do
          DisableControlAction(0, control, true)
        end

        if IsDisabledControlPressed(0, CONTROL_SCROLL_UP) then
          heading = rotateEntity(object, heading, -2.0)
        elseif IsControlPressed(0, CONTROL_SCROLL_DOWN) then
          heading = rotateEntity(object, heading, 2.0)
        end

        if IsControlPressed(0, CONTROL_MOVE_FORWARD) then
          moveEntity(object, "forward", 0.01)
        elseif IsControlPressed(0, CONTROL_MOVE_BACK) then
          moveEntity(object, "back", 0.01)
        end

        if IsControlPressed(0, CONTROL_MOVE_LEFT) then
          moveEntity(object, "left", 0.01)
        elseif IsControlPressed(0, CONTROL_MOVE_RIGHT) then
          moveEntity(object, "right", 0.01)
        end

        if IsDisabledControlPressed(0, CONTROL_MOVE_UP) then
          moveEntity(object, "up", 0.01)
        elseif IsDisabledControlPressed(0, CONTROL_MOVE_DOWN) then
          moveEntity(object, "down", 0.01)
        end

        Interactions.Client.SetEntityOutline(object, 106, 226, 119, 255)

        if IsControlJustReleased(0, CONTROL_ENTER) then
          local coords = GetEntityCoords(object)
          heading = GetEntityHeading(object)

          DebugPrint(("[ObjectPlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading))
          DeleteEntity(object)
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

      Wait(0)
    end
  end)

  return Citizen.Await(resultPromise)
end

RegisterNUICallback("interactions-object-placer", function(data, callback)
  SetNuiFocus(false, false)
  callback(Interactions.Client.Object.StartCreator(data))
  SetNuiFocus(true, true)
end)

function Interactions.Client.Object.Create(coords, model, label, key, onInteract, canInteract)
  local wrapper = Interactions.Client.Object.Spawn(coords, model, {
    collision = true,
    frozen = true,
    invincible = true,
    enableStreaming = true
  })

  wrapper.interactionData = {
    label = label,
    key = key,
    onInteract = onInteract,
    distance = 2.5,
    canInteract = canInteract
  }

  if wrapper.entity and wrapper.entity ~= 0 and DoesEntityExist(wrapper.entity) then
    wrapper.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(
      wrapper.entity,
      "object",
      label,
      key,
      onInteract,
      2.5,
      canInteract
    )
  end

  return wrapper
end
