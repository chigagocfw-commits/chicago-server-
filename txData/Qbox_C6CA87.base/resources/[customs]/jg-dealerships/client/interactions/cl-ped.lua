Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Ped = Interactions.Client.Ped or {}

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

  if direction == "up" or direction == "down" then
    SetEntityCoordsNoOffset(entity, nextCoords.x, nextCoords.y, nextCoords.z, false, false, false)
  else
    SetEntityCoordsNoOffset(entity, nextCoords.x, nextCoords.y, coords.z, false, false, false)
  end
end

function Interactions.Client.Ped.Spawn(coords, model, scenario, options)
  options = options or {}

  local collision = options.collision ~= false
  local alpha = options.alpha or 255
  local frozen = options.frozen ~= false
  local invincible = options.invincible ~= false
  local blocking = options.blocking ~= false

  local function spawnPed()
    lib.requestModel(model)

    local ped = CreatePed(4, joaat(model), coords.x, coords.y, coords.z, coords.w or 0.0, false, false)
    local timeoutAt = GetGameTimer() + 5000

    while not DoesEntityExist(ped) and GetGameTimer() < timeoutAt do
      Wait(0)
    end

    if not DoesEntityExist(ped) then
      print("[Interactions.Client.Ped.Spawn] Failed to create ped")
      return 0
    end

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    Wait(100)
    SetEntityAsMissionEntity(ped, true, true)

    if blocking then
      SetBlockingOfNonTemporaryEvents(ped, true)
      TaskSetBlockingOfNonTemporaryEvents(ped, true)
    end

    SetEntityInvincible(ped, invincible)
    FreezeEntityPosition(ped, frozen)
    SetPedCanRagdoll(ped, false)
    SetEntityCollision(ped, collision, collision)

    if alpha < 255 then
      SetEntityAlpha(ped, alpha, false)
    end

    if scenario and scenario ~= "" then
      Wait(50)

      if not scenario:find("^WORLD_") and not scenario:find("^PROP_") and not scenario:find("^CODE_") and not scenario:find("^MINI@") then
        print("[Interactions.Client.Ped.Spawn] Warning: Scenario '" .. scenario .. "' may not be valid. Most scenarios start with WORLD_HUMAN_, PROP_HUMAN_, etc.")
      end

      local ok, err = pcall(function()
        TaskStartScenarioInPlace(ped, scenario, 0, true)
      end)

      if not ok then
        print("[Interactions.Client.Ped.Spawn] Failed to apply scenario '" .. tostring(scenario) .. "': " .. tostring(err))
      end
    end

    return ped
  end

  local wrapper = Interactions.Client.EntityStreaming.CreateWrapper(coords, model, options)
  wrapper.scenario = scenario
  Interactions.Client.EntityStreaming.SetupStreaming(wrapper, spawnPed, "ped", function(entity)
    DeletePed(entity)
  end)
  return wrapper
end

function Interactions.Client.Ped.SpawnPreview(coords, model, scenario)
  return Interactions.Client.Ped.Spawn(coords, model, scenario, {
    collision = false,
    alpha = 200,
    frozen = true,
    invincible = true,
    blocking = true,
    enableStreaming = false
  })
end

function Interactions.Client.Ped.StartCreator(model, scenario)
  local resultPromise = promise.new()

  if creatorActive then
    print("[PedPlacer] already running – press Esc to cancel")
    resultPromise:resolve(false)
    return Citizen.Await(resultPromise)
  end

  creatorActive = true
  model = model or "a_m_m_business_01"

  local stage = 1
  local ped
  local heading = 0.0
  local spawnDistance = 3.0

  Interactions.Client.InstrPrmt.Show("Position yourself where you want to spawn the ped", {
    { key = "Enter", desc = "Spawn Preview" },
    { key = "Esc", desc = "Cancel" }
  })

  CreateThread(function()
    while creatorActive do
      DisableControlAction(0, CONTROL_ESCAPE, true)

      if IsDisabledControlJustReleased(0, CONTROL_ESCAPE) then
        if ped and DoesEntityExist(ped) then
          DeletePed(ped)
        end

        Interactions.Client.InstrPrmt.Hide()
        creatorActive = false
        resultPromise:resolve(false)
      end

      if stage == 1 then
        if IsControlJustReleased(0, CONTROL_ENTER) then
          local spawnCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, spawnDistance, 0.0)
          local playerZ = GetEntityCoords(cache.ped).z
          local foundGround, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, playerZ + 2.0, false)

          heading = GetEntityHeading(cache.ped)
          local z = foundGround and groundZ or playerZ

          local wrapper = Interactions.Client.Ped.SpawnPreview({
            x = spawnCoords.x,
            y = spawnCoords.y,
            z = z + 1.0,
            w = heading
          }, model, scenario)

          ped = wrapper.entity or 0

          if ped == 0 then
            print("[PedPlacer] Failed to spawn ped")
            creatorActive = false
            resultPromise:resolve(false)
            return
          end

          PlaceObjectOnGroundProperly(ped)
          stage = 2
          DebugPrint("[PedPlacer] preview spawned – fine-tune with WASD / Q,E or scroll. Enter to confirm.")
          Interactions.Client.InstrPrmt.Show("Fine-tune ped position", {
            { key = "Scroll", desc = "Rotate" },
            { key = "R", desc = "Up" },
            { key = "F", desc = "Down" },
            { key = "Enter", desc = "Confirm" },
            { key = "Esc", desc = "Cancel" }
          }, "Move")
        end
      elseif stage == 2 and ped and DoesEntityExist(ped) then
        for _, control in ipairs(DISABLED_CONTROLS) do
          DisableControlAction(0, control, true)
        end

        if IsDisabledControlPressed(0, CONTROL_SCROLL_UP) then
          heading = rotateEntity(ped, heading, -5.0)
        elseif IsControlPressed(0, CONTROL_SCROLL_DOWN) then
          heading = rotateEntity(ped, heading, 5.0)
        end

        if IsControlPressed(0, CONTROL_MOVE_FORWARD) then
          moveEntity(ped, "forward", 0.025)
        elseif IsControlPressed(0, CONTROL_MOVE_BACK) then
          moveEntity(ped, "back", 0.025)
        end

        if IsControlPressed(0, CONTROL_MOVE_LEFT) then
          moveEntity(ped, "left", 0.025)
        elseif IsControlPressed(0, CONTROL_MOVE_RIGHT) then
          moveEntity(ped, "right", 0.025)
        end

        if IsDisabledControlPressed(0, CONTROL_MOVE_UP) then
          moveEntity(ped, "up", 0.01)
        elseif IsDisabledControlPressed(0, CONTROL_MOVE_DOWN) then
          moveEntity(ped, "down", 0.01)
        end

        local coords = GetEntityCoords(ped)
        Utils.Client.DrawMarkerOnFrame(20, vec3(coords.x, coords.y, coords.z + 1.2), 0.5, {
          r = 106,
          g = 226,
          b = 119,
          a = 0.7843137254901961
        }, vec3(180, 0, 0))

        if IsControlJustReleased(0, CONTROL_ENTER) then
          coords = GetEntityCoords(ped)
          local scenarioSuffix = scenario and (" | scenario: " .. scenario) or ""

          DebugPrint(("[PedPlacer Saved] vector4(%.2f, %.2f, %.2f, %.2f)%s"):format(coords.x, coords.y, coords.z, heading, scenarioSuffix))
          DeletePed(ped)
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

RegisterNUICallback("interactions-ped-placer", function(data, callback)
  SetNuiFocus(false, false)
  callback(Interactions.Client.Ped.StartCreator(data.pedModel, data.pedScenario))
  SetNuiFocus(true, true)
end)

function Interactions.Client.Ped.Create(coords, model, scenario, label, key, onInteract, canInteract)
  local wrapper = Interactions.Client.Ped.Spawn(coords, model, scenario, {
    collision = true,
    frozen = true,
    invincible = true,
    blocking = true,
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
      "ped",
      label,
      key,
      onInteract,
      2.5,
      canInteract
    )
  end

  return wrapper
end
