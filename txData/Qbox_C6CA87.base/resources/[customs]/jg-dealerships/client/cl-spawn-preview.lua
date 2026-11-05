local previewActive = false
local previewEntities = {}
local outlineThreadActive = false

local function clearPreview()
  if not previewActive then return end

  previewActive = false
  outlineThreadActive = false

  for _, preview in ipairs(previewEntities) do
    if preview.entity and DoesEntityExist(preview.entity) then
      SetEntityAsMissionEntity(preview.entity, false, true)
      DeleteEntity(preview.entity)
    end
  end

  previewEntities = {}
end

local function startPreview(spawnPoints, vehicleModel)
  if not spawnPoints or #spawnPoints == 0 then return end

  clearPreview()
  previewActive = true

  for _, spawnPoint in ipairs(spawnPoints) do
    local coords = {
      x = spawnPoint.x,
      y = spawnPoint.y,
      z = spawnPoint.z,
      w = spawnPoint.w,
    }

    local preview = Interactions.Client.Vehicle.SpawnPreview(coords, vehicleModel)
    local entity = preview.entity or 0

    if entity ~= 0 then
      previewEntities[#previewEntities + 1] = { entity = entity }
    end
  end

  if outlineThreadActive then return end

  outlineThreadActive = true
  CreateThread(function()
    while previewActive do
      Wait(0)

      local hasHighlightedEntity = false
      for _, preview in ipairs(previewEntities) do
        if preview.highlighted then
          hasHighlightedEntity = true
          break
        end
      end

      for _, preview in ipairs(previewEntities) do
        if DoesEntityExist(preview.entity) then
          if hasHighlightedEntity then
            if preview.highlighted then
              Interactions.Client.SetEntityOutline(preview.entity, 106, 226, 119, 255)
            else
              SetEntityDrawOutline(preview.entity, false)
            end
          else
            Interactions.Client.SetEntityOutline(preview.entity, 106, 226, 119, 255)
          end
        end
      end
    end

    outlineThreadActive = false
  end)
end

RegisterNUICallback("preview-spawn-points", function(data, callback)
  startPreview(data.spawnPoints, data.vehModel or "adder")
  callback("ok")
end)

RegisterNUICallback("stop-preview-spawn-points", function(_, callback)
  clearPreview()
  callback("ok")
end)

RegisterNUICallback("highlight-spawn-point", function(data, callback)
  local highlightedIndex = data.index

  for index, preview in ipairs(previewEntities) do
    preview.highlighted = highlightedIndex ~= nil and index == highlightedIndex
  end

  callback("ok")
end)
