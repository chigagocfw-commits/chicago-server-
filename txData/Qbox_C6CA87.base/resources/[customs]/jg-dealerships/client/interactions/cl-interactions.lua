Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}

local createdBlips = {}

local function createBlip(name, coords, sprite, colour, scale)
  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)

  SetBlipSprite(blip, sprite)
  SetBlipColour(blip, colour)
  SetBlipScale(blip, scale + 0.0)
  SetBlipAsShortRange(blip, true)

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentString(name)
  EndTextCommandSetBlipName(blip)

  createdBlips[#createdBlips + 1] = blip
  return blip
end

local function createMarkerPoint(coords, markerData)
  local markerPoint = lib.points.new({
    coords = coords,
    distance = Config.EntityStreamingDistance or 150.0
  })

  function markerPoint:nearby()
    Utils.Client.DrawMarkerOnFrame(
      markerData.id,
      coords,
      markerData.size,
      markerData.color,
      nil,
      nil,
      markerData.bobUpAndDown,
      markerData.faceCamera,
      markerData.rotate,
      markerData.drawOnEnts
    )
  end

  return markerPoint
end

local function buildMarkerData(interaction)
  return {
    id = interaction.markerId,
    size = interaction.markerSize,
    color = interaction.markerColor,
    bobUpAndDown = interaction.markerBobUpAndDown,
    faceCamera = interaction.markerFaceCamera,
    rotate = interaction.markerRotate,
    drawOnEnts = interaction.markerDrawOnEnts
  }
end

local function queueStreamingEntity(queue, interaction, text, key, callback, canInteract)
  queue[#queue + 1] = {
    coords = interaction.coords[1],
    model = interaction.model,
    pedScenario = interaction.pedScenario,
    vehColour = interaction.vehColour,
    text = text,
    key = key,
    callback = callback,
    canInteract = canInteract
  }
end

function Interactions.Client.Create(interactions, key, text, callback, blipName, canInteract)
  local group = {
    entities = {},
    points = {},
    zones = {},
    blips = {},
    markers = {},
    _cancelled = false
  }

  local pendingPeds = {}
  local pendingVehicles = {}
  local pendingObjects = {}
  local interactionsEnabled = not canInteract or canInteract

  for _, interaction in ipairs(interactions) do
    local firstCoord = interaction.coords[1]
    local isPed = interaction.type == "ped"

    if interaction.enableBlip and (interactionsEnabled or isPed) then
      local blipCoords

      if interaction.type == "polyzone" then
        blipCoords = Utils.Client.GetPolygonCenter(interaction.coords)
      elseif firstCoord then
        blipCoords = vec3(firstCoord.x, firstCoord.y, firstCoord.z)
      end

      if blipCoords then
        group.blips[#group.blips + 1] = createBlip(
          blipName or "Interaction",
          blipCoords,
          interaction.blipIconId,
          interaction.blipColourId,
          interaction.blipSize
        )
      end
    end

    if interaction.enableMarker and interaction.type == "point" and firstCoord and interactionsEnabled then
      local markerCoords = vec3(firstCoord.x, firstCoord.y, firstCoord.z)
      group.markers[#group.markers + 1] = createMarkerPoint(markerCoords, buildMarkerData(interaction))
    end

    if interaction.type == "ped" then
      queueStreamingEntity(pendingPeds, interaction, text, key, callback, canInteract)
    elseif interaction.type == "vehicle" then
      queueStreamingEntity(pendingVehicles, interaction, text, key, callback, canInteract)
    elseif interaction.type == "object" then
      queueStreamingEntity(pendingObjects, interaction, text, key, callback, canInteract)
    elseif interaction.type == "point" then
      if interactionsEnabled then
        group.points[#group.points + 1] = Interactions.Client.Point.Create(
          firstCoord,
          interaction.radius or 2.0,
          text,
          key,
          callback,
          canInteract
        )
      end
    elseif interaction.type == "polyzone" then
      local zoneCoords = {}

      for _, coord in ipairs(interaction.coords) do
        zoneCoords[#zoneCoords + 1] = vec3(coord.x, coord.y, coord.z)
      end

      if interactionsEnabled then
        group.zones[#group.zones + 1] = Interactions.Client.Zone.Create(
          zoneCoords,
          text,
          key,
          callback,
          canInteract,
          interaction.zoneHeight
        )
      end

      if interaction.enableMarker and interactionsEnabled then
        local polygonCenter = Utils.Client.GetPolygonCenter(zoneCoords)
        local markerCoords = vec3(polygonCenter.x, polygonCenter.y, polygonCenter.z)
        group.markers[#group.markers + 1] = createMarkerPoint(markerCoords, buildMarkerData(interaction))
      end
    end
  end

  if #pendingPeds > 0 or #pendingVehicles > 0 or #pendingObjects > 0 then
    CreateThread(function()
      for _, pedData in ipairs(pendingPeds) do
        if group._cancelled then
          return
        end

        local wrapper = Interactions.Client.Ped.Create(
          pedData.coords,
          pedData.model,
          pedData.pedScenario,
          pedData.text,
          pedData.key,
          pedData.callback,
          pedData.canInteract
        )

        group.entities[#group.entities + 1] = {
          type = "ped",
          wrapper = wrapper,
          entity = wrapper.entity or 0,
          interactionId = "entity_" .. (wrapper.entity or 0)
        }

        Wait(100)
      end

      for _, vehicleData in ipairs(pendingVehicles) do
        if group._cancelled then
          return
        end

        local wrapper = Interactions.Client.Vehicle.Create(
          vehicleData.coords,
          vehicleData.model,
          vehicleData.vehColour,
          vehicleData.text,
          vehicleData.key,
          vehicleData.callback,
          vehicleData.canInteract
        )

        group.entities[#group.entities + 1] = {
          type = "vehicle",
          wrapper = wrapper,
          entity = wrapper.entity or 0,
          interactionId = "entity_" .. (wrapper.entity or 0)
        }

        Wait(100)
      end

      for index, objectData in ipairs(pendingObjects) do
        if group._cancelled then
          return
        end

        local wrapper = Interactions.Client.Object.Create(
          objectData.coords,
          objectData.model,
          objectData.text,
          objectData.key,
          objectData.callback,
          objectData.canInteract
        )

        group.entities[#group.entities + 1] = {
          type = "object",
          wrapper = wrapper,
          entity = wrapper.entity or 0,
          interactionId = "entity_" .. (wrapper.entity or 0)
        }

        if index < #pendingObjects then
          Wait(100)
        end
      end

      group._streamingEntitiesReady = true
    end)
  else
    group._streamingEntitiesReady = true
  end

  return group
end

function Interactions.Client.Remove(group)
  if not group then
    return
  end

  group._cancelled = true

  if group.entities then
    for _, entityData in ipairs(group.entities) do
      local wrapper = entityData.wrapper

      if wrapper then
        wrapper._removed = true

        if wrapper.activeInteraction then
          Interactions.Client.Handler.RemoveEntityInteraction(wrapper.activeInteraction)
          wrapper.activeInteraction = nil
        end

        if wrapper.entity and DoesEntityExist(wrapper.entity) then
          if entityData.type == "ped" then
            ClearPedTasksImmediately(wrapper.entity)
          end

          SetEntityAsMissionEntity(wrapper.entity, false, true)
          DeleteEntity(wrapper.entity)
          wrapper.entity = nil
        end

        if wrapper.streamingPoint then
          wrapper.streamingPoint:remove()
          wrapper.streamingPoint = nil
        end
      end
    end
  end

  if group.points then
    for _, point in ipairs(group.points) do
      Interactions.Client.Point.Remove(point)
    end
  end

  if group.zones then
    for _, zone in ipairs(group.zones) do
      Interactions.Client.Zone.Remove(zone)
    end
  end

  if group.blips then
    for _, blip in ipairs(group.blips) do
      if DoesBlipExist(blip) then
        RemoveBlip(blip)
      end
    end
  end

  if group.markers then
    for _, marker in ipairs(group.markers) do
      marker:remove()
    end
  end
end
