Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.EntityStreaming = Interactions.Client.EntityStreaming or {}

function Interactions.Client.EntityStreaming.CreateWrapper(coords, model, options)
  return {
    entity = nil,
    coords = coords,
    model = model,
    options = options or {},
    streamingPoint = nil,
    interactionData = nil,
    activeInteraction = nil,
    _removed = false,
    _spawning = false,
  }
end

function Interactions.Client.EntityStreaming.SetupStreaming(wrapper, spawnEntity, entityType, deleteEntity)
  local coords = wrapper.coords
  local enableStreaming = wrapper.options.enableStreaming

  deleteEntity = deleteEntity or function(entity)
    if entityType == "ped" then
      DeletePed(entity)
    else
      DeleteEntity(entity)
    end
  end

  if not enableStreaming then
    wrapper.entity = spawnEntity()
    return
  end

  wrapper.streamingPoint = lib.points.new({
    coords = vec3(coords.x, coords.y, coords.z),
    distance = Config.EntityStreamingDistance or 150.0,
  })

  wrapper.streamingPoint.onEnter = function()
    if wrapper._removed or wrapper._spawning then return end

    DebugPrint(("[EntityStreaming] onEnter: %s entity=%s _spawning=%s"):format(
      tostring(wrapper.model),
      tostring(wrapper.entity),
      tostring(wrapper._spawning)
    ))

    if wrapper.entity and DoesEntityExist(wrapper.entity) then return end

    wrapper._spawning = true
    wrapper.entity = spawnEntity()
    wrapper._spawning = false

    DebugPrint(("[EntityStreaming] Spawned: %s entity=%s"):format(
      tostring(wrapper.model),
      tostring(wrapper.entity)
    ))

    local interactionData = wrapper.interactionData
    if not interactionData then return end

    wrapper.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(
      wrapper.entity,
      entityType,
      interactionData.label,
      interactionData.key,
      interactionData.onInteract,
      interactionData.distance,
      interactionData.canInteract
    )
  end

  wrapper.streamingPoint.onExit = function()
    if not wrapper.entity or not DoesEntityExist(wrapper.entity) then return end

    if wrapper.activeInteraction then
      Interactions.Client.Handler.RemoveEntityInteraction(wrapper.activeInteraction)
      wrapper.activeInteraction = nil
    end

    deleteEntity(wrapper.entity)
    wrapper.entity = nil
  end
end
