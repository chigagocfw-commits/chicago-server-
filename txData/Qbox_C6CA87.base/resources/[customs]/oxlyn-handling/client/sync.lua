

-- oxlyn-handling : client-side sync of saved handling overrides

local REV_DECOR = "_oxlyn_handling_rev"

-- Mirror of GlobalState["oxlyn-handling"]
local state = {
  rev = 0,
  models = {},  -- [modelKey] = { fields = {...} }
  stocks = {},  -- [modelKey] = { fieldName = stockValue }
  groups = {},  -- [groupId]  = { label, fields, members = { [spawnName] = true } }
}

local groupByModel = {}  -- [modelKey] = group (only groups that have fields)
local localStock = {}    -- [modelKey] = stock values captured on this client
local modelNames = nil   -- [modelKey] = lowercase spawn name
local appliedTag = {}    -- [modelKey] = "tuned:<rev>" | "stock" (model-level state last applied)

CreateThread(function()
  DecorRegister(REV_DECOR, 3) -- int
end)

---------------------------------------------------------------------
-- Public accessors used by the editor
---------------------------------------------------------------------

function OxlynHandlingGetOverride(modelKey)
  local entry = state.models and state.models[modelKey]
  if not entry then return nil end

  return {
    name = entry.name,
    fields = entry.fields,
    stock = state.stocks and state.stocks[modelKey] or nil,
  }
end

function OxlynHandlingGetLocalStock(modelKey)
  return localStock[modelKey]
end

function OxlynHandlingGetGroupForModel(modelKey)
  local group = groupByModel[modelKey]
  return group and group.label or nil
end

function OxlynHandlingGetOverriddenKeys()
  local keys = {}
  for key in pairs(state.models or {}) do
    keys[#keys + 1] = key
  end
  return keys
end

---------------------------------------------------------------------
-- Per-vehicle application
---------------------------------------------------------------------

local function applyToVehicle(veh, values)
  HandlingIO.writeSet(veh, values)
end

-- Small upward kick so suspension/physics settle after a change
local function bumpVehicle(veh)
  if GetEntitySpeed(veh) > 0.75 then return end
  if not NetworkHasControlOfEntity(veh) then return end

  local vel = GetEntityVelocity(veh)
  SetEntityVelocity(veh, vel.x + 0.0, vel.y + 0.0, vel.z + 0.05)
end

-- Remember the vehicle's original handling before we ever modify this model
local function captureLocalStock(veh, modelKey)
  if localStock[modelKey] then return end
  if DecorGetInt(veh, REV_DECOR) ~= 0 then return end -- already modified

  local values = {}
  for _, field in ipairs(HandlingFields) do
    local value = HandlingIO.read(veh, field)
    if value ~= nil then
      values[field.name] = value
    end
  end
  localStock[modelKey] = values
end

---------------------------------------------------------------------
-- Per-model application (affects newly spawned vehicles of that model)
---------------------------------------------------------------------

local function ensureModelNames()
  if modelNames then return end

  local models = GetAllVehicleModels()
  if type(models) ~= "table" or #models == 0 then return end

  local map = {}
  for i = 1, #models do
    local name = string.lower(models[i])
    map[tostring(GetHashKey(name))] = name
  end
  modelNames = map
end

local function applyToModel(modelName, values)
  for fieldName, value in pairs(values or {}) do
    local field = HandlingFieldMap[fieldName]
    if field then
      pcall(function()
        if field.type == "vector" then
          if type(value) == "table" and value.x then
            SetHandlingVector(modelName, "CHandlingData", fieldName,
              vector3(value.x + 0.0, value.y + 0.0, value.z + 0.0))
          end
        elseif field.type == "int" then
          SetHandlingInt(modelName, "CHandlingData", fieldName,
            math.floor((tonumber(value) or 0) + 0.5))
        else
          SetHandlingFloat(modelName, "CHandlingData", fieldName,
            (tonumber(value) or 0.0) + 0.0)
        end
      end)
    end
  end
end

-- Bring model-level handling in line with the shared state
local function syncModels()
  ensureModelNames()
  if not modelNames then return end

  -- Models that should currently be tuned: [modelKey] = { stock, fields }
  local effective = {}

  for key, entry in pairs(state.models) do
    local stock = state.stocks[key] or localStock[key]
    if stock then
      effective[key] = { stock = stock, fields = entry.fields }
    end
  end

  for _, group in pairs(state.groups) do
    if group.fields and next(group.fields) ~= nil then
      for memberName in pairs(group.members or {}) do
        local key = tostring(GetHashKey(memberName))
        if not effective[key] then
          local stock = state.stocks[key] or localStock[key]
          if stock then
            effective[key] = { stock = stock, fields = group.fields }
          end
        end
      end
    end
  end

  -- Apply stock then tune for anything not already at this revision
  local tag = "tuned:" .. tostring(state.rev)
  for key, entry in pairs(effective) do
    if appliedTag[key] ~= tag then
      local name = modelNames[key]
      if name then
        applyToModel(name, entry.stock)
        applyToModel(name, entry.fields)
        appliedTag[key] = tag
      end
    end
  end

  -- Revert models that are no longer tuned
  for key, tagValue in pairs(appliedTag) do
    if not effective[key] and tagValue ~= "stock" then
      local name = modelNames[key]
      local stock = state.stocks[key] or localStock[key]
      if name and stock then
        applyToModel(name, stock)
        appliedTag[key] = "stock"
      end
    end
  end

  -- Reset models that only have a stock entry and haven't been touched
  for key, stock in pairs(state.stocks) do
    if not effective[key] and appliedTag[key] == nil then
      local name = modelNames[key]
      if name then
        applyToModel(name, stock)
        appliedTag[key] = "stock"
      end
    end
  end
end

---------------------------------------------------------------------
-- Hooks called by the editor after save / reset
---------------------------------------------------------------------

-- Re-apply stock + changed values at model level for this model
function OxlynHandlingApplyShared(modelKey, stockValues, changed)
  ensureModelNames()
  if not modelNames then return false end

  local name = modelNames[modelKey]
  if not name then return false end

  applyToModel(name, stockValues or {})
  applyToModel(name, changed or {})
  appliedTag[modelKey] = nil
  return true
end

-- Optimistically update local state before the server broadcast arrives
function OxlynHandlingPredict(modelKey, changed, stock)
  if stock and not state.stocks[modelKey] then
    state.stocks[modelKey] = stock
  end

  -- NOTE: mirrors the decompiled flow. A nil `changed` clears the override;
  -- an empty (non-nil) table leaves the existing override untouched.
  if changed then
    if next(changed) ~= nil then
      state.models[modelKey] = { fields = changed }
    end
  else
    state.models[modelKey] = nil
  end

  state.rev = (state.rev or 0) + 1
  appliedTag[modelKey] = nil
end

---------------------------------------------------------------------
-- Global state replication
---------------------------------------------------------------------

local function applyGlobalState(data)
  if type(data) ~= "table" then return end

  state.rev = tonumber(data.rev) or 0
  state.models = data.models or {}
  state.stocks = data.stocks or {}
  state.groups = data.groups or {}

  groupByModel = {}
  for _, group in pairs(state.groups) do
    if group.fields and next(group.fields) ~= nil then
      for memberName in pairs(group.members or {}) do
        groupByModel[tostring(GetHashKey(memberName))] = group
      end
    end
  end
end

AddStateBagChangeHandler("oxlyn-handling", "global", function(bagName, key, value)
  applyGlobalState(value)
end)

-- Initial load: wait until the server has published the state
CreateThread(function()
  while GlobalState["oxlyn-handling"] == nil do
    Wait(500)
  end
  applyGlobalState(GlobalState["oxlyn-handling"])
end)

---------------------------------------------------------------------
-- Scan loop: keep every nearby vehicle in line with the current revision
---------------------------------------------------------------------

local function stampAndSettle(veh, rev)
  DecorSetInt(veh, REV_DECOR, rev)
  bumpVehicle(veh)
end

CreateThread(function()
  while true do
    -- NOTE: as in the original, nothing is processed unless at least one
    -- per-model override exists (group-only tunes alone won't trigger this).
    local hasModelOverrides = next(state.models) ~= nil

    if hasModelOverrides then
      syncModels()

      local editorVehicle = (EditorSession and EditorSession.vehicle) or 0

      for _, veh in ipairs(GetGamePool("CVehicle")) do
        if veh ~= editorVehicle and DoesEntityExist(veh) then
          local key = tostring(GetEntityModel(veh))
          local override = state.models[key]
          local group = groupByModel[key]
          local appliedRev = DecorGetInt(veh, REV_DECOR)

          if override then
            if appliedRev ~= state.rev then
              captureLocalStock(veh, key)
              local stock = state.stocks[key] or localStock[key]
              if stock then applyToVehicle(veh, stock) end
              applyToVehicle(veh, override.fields)
              stampAndSettle(veh, state.rev)
            end

          elseif group then
            if appliedRev ~= state.rev then
              captureLocalStock(veh, key)
              local stock = localStock[key] or state.stocks[key]
              if stock then applyToVehicle(veh, stock) end
              applyToVehicle(veh, group.fields)
              stampAndSettle(veh, state.rev)
            end

          elseif appliedRev > 0 then
            -- No longer tuned: restore stock and clear the stamp
            local stock = state.stocks[key] or localStock[key]
            if stock then applyToVehicle(veh, stock) end
            stampAndSettle(veh, 0)
          end
        end
      end
    end

    Wait(Config.ScanInterval or 1500)
  end
end)

