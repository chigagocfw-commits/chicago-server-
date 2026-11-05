Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Handler = Interactions.Client.Handler or {}

local interactionMethod = Config.InteractionMethod or "textui"
local interactionCounter = 0

local function nextInteractionId(prefix)
  interactionCounter = interactionCounter + 1
  return ("%s_%d_%d"):format(prefix, GetGameTimer(), interactionCounter)
end

function Interactions.Client.SetEntityOutline(entity, red, green, blue, alpha)
  if not DoesEntityExist(entity) then return end

  SetEntityDrawOutlineColor(red, green, blue, alpha)
  SetEntityDrawOutlineShader(1)
  SetEntityDrawOutline(entity, true)
end

local function registerTextUiPoint(point, id, text, key, callback, canInteract)
  point.canInteract = canInteract
  point._removed = false

  point.onEnter = function(self)
    if self._removed then return end
    if self.canInteract and not self.canInteract() then return end
    Interactions.Client.TextUIManager.Show(id, text, key, callback)
  end

  point.onExit = function()
    Interactions.Client.TextUIManager.Hide(id)
  end

  point.nearby = function(self)
    if self._removed then return end

    if self.entity and DoesEntityExist(self.entity) then
      self.coords = GetEntityCoords(self.entity)
    end

    if self.canInteract then
      if self.canInteract() then
        if not Interactions.Client.TextUIManager.IsShowingId(id) then
          Interactions.Client.TextUIManager.Show(id, text, key, callback)
        end
      else
        Interactions.Client.TextUIManager.Hide(id)
      end
    end

    Interactions.Client.TextUIManager.HandleKeyPress()
  end
end

function Interactions.Client.Handler.AddEntityInteraction(entityOrWrapper, _, text, key, callback, distance, canInteract)
  if canInteract and not canInteract() then return {} end

  distance = distance or 2.5
  local entity = type(entityOrWrapper) == "table" and entityOrWrapper.entity or entityOrWrapper
  local interactionId = "entity_" .. entity

  if interactionMethod == "target" then
    Framework.Client.RegisterTarget("entity", nil, entity, text, callback)
    return { method = "target", type = "entity", entity = entity, id = interactionId }
  end

  if interactionMethod == "3dtextui" then
    Framework.Client.TextUI3dAdd("entity", nil, entity, text, callback)
    return { method = "3dtextui", type = "entity", entity = entity, id = interactionId }
  end

  if interactionMethod == "radial" then
    local point = lib.points.new({
      coords = GetEntityCoords(entity),
      distance = distance,
      entity = entity,
      interactionId = interactionId,
    })

    point.onEnter = function(self)
      Framework.Client.RadialMenuAdd(self.interactionId, text, callback)
    end

    point.onExit = function(self)
      Framework.Client.RadialMenuRemove(self.interactionId)
    end

    point.nearby = function(self)
      if DoesEntityExist(self.entity) then
        self.coords = GetEntityCoords(self.entity)
      end
    end

    return { method = "radial", type = "entity", entity = entity, point = point, id = interactionId }
  end

  if interactionMethod == "textui" then
    local point = lib.points.new({
      coords = GetEntityCoords(entity),
      distance = distance,
      entity = entity,
      interactionId = interactionId,
    })

    registerTextUiPoint(point, interactionId, text, key, callback, canInteract)
    return {
      method = "textui",
      type = "entity",
      entity = entity,
      point = point,
      id = interactionId,
      canInteract = canInteract,
    }
  end

  return {}
end

function Interactions.Client.Handler.AddPointInteraction(coords, distance, text, key, callback, polygon, canInteract)
  if canInteract and not canInteract() then return {} end

  local pointCoords = polygon and Utils.Client.GetPolygonCenter(polygon) or coords

  if interactionMethod == "target" then
    local id = Framework.Client.RegisterTarget("coords", pointCoords, nil, text, callback)
    if not id then
      print("[Interactions.Client.Handler] Failed to add target for coords:", pointCoords)
      return {}
    end
    return { method = "target", type = "coords", coords = pointCoords, id = id }
  end

  if interactionMethod == "3dtextui" then
    local id = Framework.Client.TextUI3dAdd("coords", pointCoords, nil, text, callback)
    if not id then
      print("[Interactions.Client.Handler] Failed to add 3dtextui for coords:", pointCoords)
      return {}
    end
    return { method = "3dtextui", type = "coords", coords = pointCoords, id = id, removed = false }
  end

  if interactionMethod == "radial" then
    local id = nextInteractionId("radial")
    local point = lib.points.new({
      coords = pointCoords,
      distance = distance,
      interactionId = id,
    })

    point.onEnter = function(self)
      Framework.Client.RadialMenuAdd(self.interactionId, text, callback)
    end

    point.onExit = function(self)
      Framework.Client.RadialMenuRemove(self.interactionId)
    end

    return { method = "radial", type = "coords", coords = pointCoords, point = point, id = id }
  end

  if interactionMethod == "textui" then
    local id = nextInteractionId("textui")
    local point = lib.points.new({
      coords = pointCoords,
      distance = distance,
      interactionId = id,
    })

    registerTextUiPoint(point, id, text, key, callback, canInteract)
    return {
      method = "textui",
      type = "coords",
      coords = pointCoords,
      point = point,
      id = id,
      canInteract = canInteract,
    }
  end

  return {}
end

function Interactions.Client.Handler.RemoveEntityInteraction(interaction)
  if not interaction then return end

  if interaction.method == "target" and interaction.type == "entity" then
    if DoesEntityExist(interaction.entity) then
      Framework.Client.RemoveTarget("entity", nil, interaction.entity)
    end
    return
  end

  if interaction.method == "3dtextui" and interaction.type == "entity" then
    if DoesEntityExist(interaction.entity) then
      Framework.Client.TextUI3dRemove("entity", nil, interaction.entity)
    end
    return
  end

  if interaction.method == "radial" then
    if interaction.id then
      Framework.Client.RadialMenuRemove(interaction.id)
    end
    if interaction.point then
      interaction.point:remove()
    end
    return
  end

  if interaction.method == "textui" and interaction.point then
    interaction.point._removed = true
    if interaction.id then
      Interactions.Client.TextUIManager.Hide(interaction.id)
    end
    interaction.point:remove()
  end
end

function Interactions.Client.Handler.RemovePointInteraction(interaction)
  if not interaction then return end

  if interaction.method == "target" and interaction.type == "coords" then
    if interaction.id then
      Framework.Client.RemoveTarget("coords", interaction.id, nil)
    end
    return
  end

  if interaction.method == "3dtextui" and interaction.type == "coords" then
    if interaction.id and not interaction.removed then
      local idType = type(interaction.id)
      if idType ~= "number" and idType ~= "string" then
        print("[Interactions.Client.Handler] Invalid 3dtextui ID type:", idType, interaction.id)
        return
      end

      Framework.Client.TextUI3dRemove("coords", interaction.id, nil)
      interaction.removed = true
    end
    return
  end

  if interaction.method == "radial" then
    if interaction.id then
      Framework.Client.RadialMenuRemove(interaction.id)
    end
    if interaction.point then
      interaction.point:remove()
    end
    return
  end

  if interaction.method == "textui" and interaction.point then
    interaction.point._removed = true
    if interaction.id then
      Interactions.Client.TextUIManager.Hide(interaction.id)
    end
    interaction.point:remove()
  end
end
