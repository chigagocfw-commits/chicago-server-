local previewActive = false
local highlightsEnabled = true
local previewItems = {}
local previewBlips = {}
local removedLocationId
local removedInteractionType
local previewStarting = false
local renderThreadActive = false

local function removePreviewEntities()
  for _, item in ipairs(previewItems) do
    if (item.type == "ped" or item.type == "vehicle" or item.type == "object") and item.entity and DoesEntityExist(item.entity) then
      SetEntityAsMissionEntity(item.entity, false, true)

      if item.type == "ped" then
        ClearPedTasksImmediately(item.entity)
      end

      DeleteEntity(item.entity)
    end
  end
end

local function removePreviewBlips()
  for _, blip in ipairs(previewBlips) do
    if DoesBlipExist(blip) then
      RemoveBlip(blip)
    end
  end
end

local function stopPreview(locationId, interactionType, interactionData)
  if not previewActive then
    return
  end

  previewActive = false
  renderThreadActive = false
  highlightsEnabled = true

  removePreviewEntities()
  removePreviewBlips()

  previewItems = {}
  previewBlips = {}

  if removedLocationId and removedInteractionType and locationId and interactionType then
    if interactionData then
      Locations.Client.RecreateInteractionTypeFromData(locationId, interactionType, interactionData)
    else
      Locations.Client.RecreateInteractionType(locationId, interactionType)
    end

    removedLocationId = nil
    removedInteractionType = nil
  end
end

local function addEntityPreview(interactionType, wrapper)
  local entity = wrapper.entity or 0
  if entity ~= 0 then
    previewItems[#previewItems + 1] = {
      type = interactionType,
      entity = entity
    }
  end
end

local function addPointPreview(interaction)
  local firstCoord = interaction.coords[1]
  local point = {
    type = "point",
    coords = vec3(firstCoord.x, firstCoord.y, firstCoord.z),
    radius = interaction.radius or 2.0,
    enableMarker = interaction.enableMarker,
    markerId = interaction.markerId,
    markerSize = interaction.markerSize,
    markerColor = interaction.markerColor,
    markerBobUpAndDown = interaction.markerBobUpAndDown,
    markerFaceCamera = interaction.markerFaceCamera,
    markerRotate = interaction.markerRotate,
    markerDrawOnEnts = interaction.markerDrawOnEnts
  }

  previewItems[#previewItems + 1] = point

  local blip = AddBlipForRadius(firstCoord.x, firstCoord.y, firstCoord.z, interaction.radius or 2.0)
  SetBlipColour(blip, 1)
  SetBlipAlpha(blip, 128)
  SetBlipSprite(blip, 9)
  previewBlips[#previewBlips + 1] = blip
end

local function addZonePreview(interaction)
  local points = {}

  for _, coord in ipairs(interaction.coords) do
    points[#points + 1] = vec3(coord.x, coord.y, coord.z)
  end

  previewItems[#previewItems + 1] = {
    type = "zone",
    points = points,
    zoneHeight = interaction.zoneHeight,
    enableMarker = interaction.enableMarker,
    markerId = interaction.markerId,
    markerSize = interaction.markerSize,
    markerColor = interaction.markerColor,
    markerBobUpAndDown = interaction.markerBobUpAndDown,
    markerFaceCamera = interaction.markerFaceCamera,
    markerRotate = interaction.markerRotate,
    markerDrawOnEnts = interaction.markerDrawOnEnts
  }
end

local function drawPreviewMarker(item, coords)
  Utils.Client.DrawMarkerOnFrame(
    item.markerId,
    coords,
    item.markerSize,
    item.markerColor,
    nil,
    nil,
    item.markerBobUpAndDown,
    item.markerFaceCamera,
    item.markerRotate,
    item.markerDrawOnEnts
  )
end

local function startRenderThread()
  if renderThreadActive then
    return
  end

  renderThreadActive = true

  CreateThread(function()
    while previewActive do
      Wait(0)

      local playerCoords = GetEntityCoords(cache.ped)

      for _, item in ipairs(previewItems) do
        local shouldHighlight = highlightsEnabled and not item.highlightHidden

        if item.type == "ped" then
          if shouldHighlight and item.entity and DoesEntityExist(item.entity) then
            local coords = GetEntityCoords(item.entity)
            Utils.Client.DrawMarkerOnFrame(20, vec3(coords.x, coords.y, coords.z + 1.2), 0.5, {
              r = 106,
              g = 226,
              b = 119,
              a = 0.7843137254901961
            }, vec3(180, 0, 0))
          end
        elseif item.type == "vehicle" then
          if shouldHighlight and item.entity and DoesEntityExist(item.entity) then
            Interactions.Client.SetEntityOutline(item.entity, 106, 226, 119, 255)
          end
        elseif item.type == "object" then
          if shouldHighlight and item.entity and DoesEntityExist(item.entity) then
            local coords = GetEntityCoords(item.entity)
            Utils.Client.DrawMarkerOnFrame(20, vec3(coords.x, coords.y, coords.z + 1.0), 0.5, {
              r = 106,
              g = 226,
              b = 119,
              a = 0.7843137254901961
            }, vec3(180, 0, 0))
            Interactions.Client.SetEntityOutline(item.entity, 106, 226, 119, 255)
          end
        elseif item.type == "point" then
          local distance = #(playerCoords - item.coords)
          if distance < 500.0 then
            local baseZ = item.coords.z - Globals.InteractionZOffset

            if shouldHighlight then
              Interactions.Client.Point.DrawVisualization(item.coords.x, item.coords.y, baseZ, item.radius, 255, 0, 0, 80, 3.0)
            end

            if item.enableMarker then
              drawPreviewMarker(item, vec3(item.coords.x, item.coords.y, item.coords.z))
            end
          end
        elseif item.type == "zone" then
          if shouldHighlight then
            local basePoints = {}

            for _, point in ipairs(item.points) do
              basePoints[#basePoints + 1] = vec3(point.x, point.y, point.z - Globals.InteractionZOffset)
            end

            Interactions.Client.Zone.DrawVisualization(basePoints, item.zoneHeight or 10.0, 255, 0, 0, 80)
          end

          if item.enableMarker then
            local center = Utils.Client.GetPolygonCenter(item.points)
            drawPreviewMarker(item, vec3(center.x, center.y, center.z))
          end
        end
      end
    end

    renderThreadActive = false
  end)
end

local function startPreview(interactions, _, _, showHighlights)
  if previewStarting then
    return
  end

  previewStarting = true
  highlightsEnabled = showHighlights ~= false

  if #previewItems > 0 then
    removePreviewEntities()
  end

  previewActive = true
  previewItems = {}
  previewBlips = {}

  for _, interaction in ipairs(interactions) do
    local firstCoord = interaction.coords[1]

    if interaction.type == "ped" and firstCoord then
      addEntityPreview("ped", Interactions.Client.Ped.SpawnPreview(firstCoord, interaction.model, interaction.pedScenario))
    elseif interaction.type == "vehicle" and firstCoord then
      addEntityPreview("vehicle", Interactions.Client.Vehicle.SpawnPreview(firstCoord, interaction.model, interaction.vehColour))
    elseif interaction.type == "object" and firstCoord then
      addEntityPreview("object", Interactions.Client.Object.SpawnPreview(firstCoord, interaction.model))
    elseif interaction.type == "point" and firstCoord then
      addPointPreview(interaction)
    elseif interaction.type == "polyzone" and interaction.coords then
      addZonePreview(interaction)
    end
  end

  startRenderThread()
  previewStarting = false
end

RegisterNUICallback("preview-location-interactions", function(data, callback)
  local locationId = data.locationId
  local interactionType = data.interactionType

  if locationId and interactionType then
    Locations.Client.RemoveInteractionType(locationId, interactionType)
    removedLocationId = locationId
    removedInteractionType = interactionType
  end

  startPreview(data.interactions, locationId, interactionType, data.showHighlights)
  callback("ok")
end)

RegisterNUICallback("toggle-interaction-highlights", function(data, callback)
  highlightsEnabled = data.enabled ~= false
  callback("ok")
end)

RegisterNUICallback("toggle-single-interaction-highlight", function(data, callback)
  local item = previewItems[data.index + 1]
  if item then
    item.highlightHidden = not data.enabled
  end

  callback("ok")
end)

local explorationModeActive = false
local CONTROL_ESCAPE = 200

RegisterNUICallback("set-nui-focus", function(data, callback)
  SetNuiFocus(data.hasFocus, data.hasCursor)
  explorationModeActive = not data.hasFocus

  if explorationModeActive then
    CreateThread(function()
      while explorationModeActive do
        DisableControlAction(0, CONTROL_ESCAPE, true)

        if IsDisabledControlJustReleased(0, CONTROL_ESCAPE) then
          SendNUIMessage({ action = "toggle-exploration-mode" })
          explorationModeActive = false
        end

        Wait(0)
      end
    end)
  end

  callback("ok")
end)

RegisterNUICallback("stop-preview-location-interactions", function(data, callback)
  if data.skipRecreate then
    stopPreview(nil, nil, nil)
  else
    stopPreview(data.locationId, data.interactionType, data.interactions)
  end

  callback("ok")
end)

RegisterNUICallback("restore-location-interactions", function(data, callback)
  if previewActive then
    previewActive = false
    renderThreadActive = false
    highlightsEnabled = true
    removePreviewEntities()
    removePreviewBlips()
    previewItems = {}
    previewBlips = {}
  end

  if removedLocationId and removedInteractionType and data.locationId == removedLocationId then
    Locations.Client.RecreateInteractionType(data.locationId, removedInteractionType)
    removedLocationId = nil
    removedInteractionType = nil
  end

  callback("ok")
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == GetCurrentResourceName() then
    stopPreview()
  end
end)
