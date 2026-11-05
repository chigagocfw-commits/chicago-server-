

-- oxlyn-handling : server side

local DATA_KEY = "oxlyn-handling:data"
local PRESETS_KEY = "oxlyn-handling:presets"

local data = { models = {}, stocks = {}, groups = {}, gseq = 0, rev = 0 }
local presets = {}

---------------------------------------------------------------------
-- Persistence
---------------------------------------------------------------------

local function loadKvp(key, default)
  local raw = GetResourceKvpString(key)
  if not raw or raw == "" then
    return default
  end

  local ok, decoded = pcall(json.decode, raw)
  if ok and type(decoded) == "table" then
    return decoded
  end
  return default
end

local function saveData()
  SetResourceKvp(DATA_KEY, json.encode(data))
end

local function savePresets()
  SetResourceKvp(PRESETS_KEY, json.encode(presets))
end

-- Bump revision, persist, and replicate to every client via GlobalState
local function commit()
  data.rev = (data.rev or 0) + 1
  saveData()
  GlobalState["oxlyn-handling"] = {
    rev = data.rev,
    models = data.models,
    stocks = data.stocks,
    groups = data.groups,
  }
end

CreateThread(function()
  data = loadKvp(DATA_KEY, { models = {}, stocks = {}, groups = {}, gseq = 0, rev = 0 })
  data.models = data.models or {}
  data.stocks = data.stocks or {}
  data.groups = data.groups or {}
  data.gseq = data.gseq or 0

  presets = loadKvp(PRESETS_KEY, {})

  commit()

  local modelCount, groupCount = 0, 0
  for _ in pairs(data.models) do modelCount = modelCount + 1 end
  for _ in pairs(data.groups) do groupCount = groupCount + 1 end

  print(("[oxlyn-handling] Loaded %d model tune(s), %d vehicle class(es), %d preset(s)."):format(
    modelCount, groupCount, #presets))
end)

---------------------------------------------------------------------
-- Validation helpers
---------------------------------------------------------------------

local function isString(v)
  return type(v) == "string"
end

local function trimLabel(value)
  local s = tostring(value or "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s:sub(1, 32)
end

-- Clamp to the field's range, allowing 50% overshoot either side
local function clampValue(field, value)
  value = tonumber(value)
  if not value then return nil end

  local lo, hi = field.min, field.max
  if lo > hi then lo, hi = hi, lo end

  local margin = (hi - lo) * 0.5
  if value < lo - margin then value = lo - margin end
  if value > hi + margin then value = hi + margin end
  return value
end

-- Validate a { fieldName = value } table against HandlingFieldMap.
-- strict = true: any unknown field rejects the whole table (returns nil).
-- Returns (cleanTable, count).
local function sanitizeFields(fields, strict)
  if type(fields) ~= "table" then return nil end

  local out, count = {}, 0
  for name, value in pairs(fields) do
    local field = HandlingFieldMap[name]
    if field then
      if field.type == "vector" then
        if type(value) == "table" then
          local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
          if x and y and z then
            out[name] = { x = x, y = y, z = z }
            count = count + 1
          end
        end
      else
        local clamped = clampValue(field, value)
        if clamped then
          out[name] = clamped
          count = count + 1
        end
      end
    elseif strict then
      return nil
    end
  end

  return out, count
end

-- Same idea but without range clamping (used for presets and .meta edits)
local function sanitizeLoose(fields)
  local out = {}
  if type(fields) ~= "table" then return out end

  for name, value in pairs(fields) do
    local field = HandlingFieldMap[name]
    if field then
      if field.type == "vector" then
        if type(value) == "table" then
          local x, y, z = tonumber(value.x), tonumber(value.y), tonumber(value.z)
          if x and y and z then
            out[name] = { x = x, y = y, z = z }
          end
        end
      else
        local n = tonumber(value)
        if n then out[name] = n end
      end
    end
  end

  return out
end

---------------------------------------------------------------------
-- View builders sent back to the UI
---------------------------------------------------------------------

local function presetList()
  local out = {}
  for i, preset in ipairs(presets) do
    local count = 0
    for _ in pairs(preset.fields) do
      count = count + 1
    end
    out[i] = { id = preset.id, label = preset.label, fields = preset.fields, count = count }
  end
  return out
end

local function groupList()
  local out = {}
  for id, group in pairs(data.groups) do
    local members = {}
    for name in pairs(group.members or {}) do
      members[#members + 1] = name
    end
    table.sort(members)

    out[id] = {
      label = group.label,
      members = members,
      hasTune = next(group.fields or {}) ~= nil,
    }
  end
  return out
end

---------------------------------------------------------------------
-- Access control
---------------------------------------------------------------------

local lastDeniedLog = {}

local function logDenied(src)
  local now = os.time()
  if now < (lastDeniedLog[src] or 0) + 20 then return end
  lastDeniedLog[src] = now

  print(("[oxlyn-handling] ACCESS DENIED for %s (id %s). Run \"%s %s\" in this console for the full reason and the exact add_ace / add_principal lines."):format(
    Framework.GetName(src),
    tostring(src),
    tostring(Config.AccessCommand or "handlingaccess"),
    tostring(src)
  ))
end

local function hasAccess(src)
  if Framework.IsAdmin(src) then
    return true
  end
  logDenied(src)
  return false
end

AddEventHandler("playerDropped", function()
  lastDeniedLog[source] = nil
end)

---------------------------------------------------------------------
-- Callbacks: open / groups
---------------------------------------------------------------------

Framework.RegisterCallback("oxlyn-handling:requestOpen", function(src, cb)
  if not hasAccess(src) then
    return cb(false)
  end
  cb(true, presetList(), groupList())
end)

Framework.RegisterCallback("oxlyn-handling:createGroup", function(src, cb, label)
  if not hasAccess(src) then
    return cb(false)
  end

  label = trimLabel(label)
  if label == "" then
    return cb(false, groupList())
  end

  data.gseq = (data.gseq or 0) + 1
  local gid = "g" .. tostring(data.gseq)

  data.groups[gid] = {
    label = label,
    members = {},
    fields = {},
    by = Framework.GetName(src),
  }

  commit()
  cb(true, groupList(), gid)
end)

Framework.RegisterCallback("oxlyn-handling:renameGroup", function(src, cb, id, label)
  if not hasAccess(src) then
    return cb(false, groupList())
  end

  local group = data.groups[id]
  label = trimLabel(label)
  if not group or label == "" then
    return cb(false, groupList())
  end

  group.label = label
  commit()
  cb(true, groupList())
end)

Framework.RegisterCallback("oxlyn-handling:deleteGroup", function(src, cb, id)
  if not hasAccess(src) then
    return cb(false, groupList())
  end
  if not data.groups[id] then
    return cb(false, groupList())
  end

  data.groups[id] = nil
  commit()
  cb(true, groupList())
end)

-- Add/remove a model (spawn name) to/from a group. A model can only be in one group.
Framework.RegisterCallback("oxlyn-handling:toggleMember", function(src, cb, id, model)
  if not hasAccess(src) then
    return cb(false, groupList())
  end

  local group = data.groups[id]
  if not (group and isString(model)) then
    return cb(false, groupList())
  end

  group.members = group.members or {}
  model = model:lower()

  if group.members[model] then
    group.members[model] = nil
  else
    for otherId, other in pairs(data.groups) do
      if otherId ~= id and other.members then
        other.members[model] = nil
      end
    end
    group.members[model] = true
  end

  commit()
  cb(true, groupList())
end)

Framework.RegisterCallback("oxlyn-handling:saveGroupTune", function(src, cb, id, fields)
  if not hasAccess(src) then
    return cb(false, groupList())
  end

  local group = data.groups[id]
  if not group then
    return cb(false, groupList())
  end

  local clean = sanitizeFields(fields, false)
  if not clean then
    return cb(false, groupList())
  end

  group.fields = clean
  group.by = Framework.GetName(src)
  group.at = os.time()

  commit()
  cb(true, groupList())
end)

Framework.RegisterCallback("oxlyn-handling:clearGroupTune", function(src, cb, id)
  if not hasAccess(src) then
    return cb(false, groupList())
  end

  local group = data.groups[id]
  if not group then
    return cb(false, groupList())
  end

  group.fields = {}
  commit()
  cb(true, groupList())
end)

---------------------------------------------------------------------
-- Callbacks: per-model save / reset
---------------------------------------------------------------------

Framework.RegisterCallback("oxlyn-handling:save", function(src, cb, modelKey, label, fields, stock)
  if not hasAccess(src) then
    return cb(false)
  end

  if not (type(modelKey) == "string" and modelKey:match("^%-?%d+$")) then
    return cb(false)
  end

  local clean = sanitizeFields(fields, false)
  if not clean then
    return cb(false)
  end

  -- Nothing changed: drop any existing override
  if next(clean) == nil then
    data.models[modelKey] = nil
    commit()
    return cb(true)
  end

  -- Record the stock values the first time this model is tuned
  if not data.stocks[modelKey] then
    local cleanStock = sanitizeFields(stock, false)
    if not (cleanStock and next(cleanStock) ~= nil) then
      return cb(false)
    end
    data.stocks[modelKey] = cleanStock
  end

  data.models[modelKey] = {
    name = tostring(label or modelKey):sub(1, 64),
    fields = clean,
    by = Framework.GetName(src),
    at = os.time(),
  }

  commit()

  if Config.Debug then
    print(("[oxlyn-handling] %s saved a tune for %s (%s)"):format(
      GetPlayerName(src), tostring(label), tostring(modelKey)))
  end

  cb(true)
end)

Framework.RegisterCallback("oxlyn-handling:resetModel", function(src, cb, modelKey)
  if not hasAccess(src) then
    return cb(false)
  end
  if type(modelKey) ~= "string" then
    return cb(false)
  end
  if not data.models[modelKey] then
    return cb(true)
  end

  data.models[modelKey] = nil
  commit()
  cb(true)
end)

---------------------------------------------------------------------
-- Callbacks: presets
---------------------------------------------------------------------

Framework.RegisterCallback("oxlyn-handling:savePreset", function(src, cb, label, fields)
  if not hasAccess(src) then
    return cb(false)
  end

  label = trimLabel(label)
  if label == "" then
    return cb(false)
  end

  local clean = sanitizeLoose(fields)
  if next(clean) == nil then
    return cb(false)
  end

  local id = label:lower():gsub("[^%w]+", "-")

  -- Replace any preset with the same id
  for i, preset in ipairs(presets) do
    if preset.id == id then
      table.remove(presets, i)
      break
    end
  end

  presets[#presets + 1] = {
    id = id,
    label = label,
    fields = clean,
    by = Framework.GetName(src),
  }

  savePresets()
  cb(true, presetList())
end)

Framework.RegisterCallback("oxlyn-handling:deletePreset", function(src, cb, id)
  if not hasAccess(src) then
    return cb(false)
  end

  for i, preset in ipairs(presets) do
    if preset.id == id then
      table.remove(presets, i)
      savePresets()
      return cb(true, presetList())
    end
  end

  cb(false, presetList())
end)

---------------------------------------------------------------------
-- Auto-edit handling.meta
---------------------------------------------------------------------

-- Search all resources for a handling .meta containing <handlingName>name</handlingName>.
-- Returns (resourceName, filePath, fileContents) or nil.
local function findHandlingMeta(name)
  local needle = "<handlingname>" .. name .. "</handlingname>"

  for i = 0, GetNumResources() - 1 do
    local resource = GetResourceByFindIndex(i)
    if resource and resource ~= "" then
      local manifest = LoadResourceFile(resource, "fxmanifest.lua")
        or LoadResourceFile(resource, "__resource.lua")

      if manifest then
        local candidates, seen = {}, {}

        for path in manifest:gmatch("['\"]([^'\"%*]-handling[^'\"%*]-%.meta)['\"]") do
          if not seen[path] then
            seen[path] = true
            candidates[#candidates + 1] = path
          end
        end
        for _, path in ipairs({ "handling.meta", "data/handling.meta", "meta/handling.meta" }) do
          if not seen[path] then
            candidates[#candidates + 1] = path
          end
        end

        for _, path in ipairs(candidates) do
          local content = LoadResourceFile(resource, path)
          if content then
            local stripped = content:lower():gsub("%s+", "")
            if stripped:find(needle, 1, true) then
              return resource, path, content
            end
          end
        end
      end
    end
  end
end

-- Rewrite the values for `fields` inside the <Item> block of handlingName `name`.
-- Returns (newXml, replacedCount) or (nil, 0) if the block wasn't found.
local function patchMeta(xml, name, fields)
  local escaped = name:gsub("%W", "%%%0")
  local lower = xml:lower()

  local startPos = lower:find("<handlingname>%s*" .. escaped:lower() .. "%s*</handlingname>")
  if not startPos then
    return nil, 0
  end

  local endPos = lower:find("<subhandlingdata>", startPos, true)
    or lower:find("</item>", startPos, true)
    or (#xml + 1)

  local before = xml:sub(1, startPos - 1)
  local block = xml:sub(startPos, endPos - 1)
  local after = xml:sub(endPos)

  local replaced = 0
  for fieldName, value in pairs(fields) do
    local field = HandlingFieldMap[fieldName]
    if field then
      local replacement, pattern, n

      if field.type == "vector" then
        replacement = ('<%s x="%.6f" y="%.6f" z="%.6f" />'):format(fieldName, value.x, value.y, value.z)
        pattern = "<" .. fieldName .. "%s[^>]-/>"
      elseif field.type == "int" then
        replacement = ('<%s value="%d" />'):format(fieldName, math.floor((tonumber(value) or 0) + 0.5))
        pattern = "<" .. fieldName .. '%s+value="[^"]*"%s*/>'
      else
        replacement = ('<%s value="%.6f" />'):format(fieldName, tonumber(value) or 0.0)
        pattern = "<" .. fieldName .. '%s+value="[^"]*"%s*/>'
      end

      block, n = block:gsub(pattern, replacement, 1)
      replaced = replaced + (n or 0)
    end
  end

  return before .. block .. after, replaced
end

Framework.RegisterCallback("oxlyn-handling:autoEditMeta", function(src, cb, spawnName, fields)
  if not hasAccess(src) then
    return cb(false)
  end
  if not isString(spawnName) then
    return cb(false)
  end
  spawnName = spawnName:lower()

  local clean = sanitizeLoose(fields)
  if next(clean) == nil then
    return cb(false)
  end

  local resource, path, content = findHandlingMeta(spawnName)
  if not resource then
    return cb(false, "notfound")
  end

  local newXml, replaced = patchMeta(content, spawnName, clean)
  if not newXml or replaced == 0 then
    return cb(false, "notfound")
  end

  -- One-time backup of the original file
  local backupPath = path .. ".oxlyn.bak"
  if not LoadResourceFile(resource, backupPath) then
    SaveResourceFile(resource, backupPath, content, -1)
  end

  local saved = SaveResourceFile(resource, path, newXml, -1)

  if Config.Debug and saved then
    print(("[oxlyn-handling] %s auto-edited %s/%s (%d fields)"):format(
      GetPlayerName(src), resource, path, replaced))
  end

  cb(true == saved, resource .. "/" .. path)
end)

---------------------------------------------------------------------
-- Access diagnostic command
---------------------------------------------------------------------

if Config.AccessCommand then
  local function findIdentifier(identifiers, prefix)
    for _, id in ipairs(identifiers) do
      if id:sub(1, #prefix) == prefix then
        return id
      end
    end
    return nil
  end

  RegisterCommand(Config.AccessCommand, function(src, args)
    -- Console (0) is always allowed; players need admin or command ACE
    if src ~= 0 then
      if not Framework.IsAdmin(src) and not Framework.AceAllowed(src, "command") then
        return
      end
    end

    local target = tonumber(args and args[1] or nil) or src

    if target ~= 0 and GetPlayerName(target) == nil then
      local msg = ("[oxlyn-handling] No player online with server id %s."):format(tostring(target))
      print(msg)
      if src ~= 0 then
        TriggerClientEvent("chat:addMessage", src, { args = { "^1[oxlyn-handling]", msg } })
      end
      return
    end

    local lines = {}
    local function add(fmt, ...)
      local ok, text = pcall(string.format, fmt, ...)
      lines[#lines + 1] = (ok and text) or fmt
    end

    local allowed, via, report = Framework.EvaluateAdmin(target)
    local cfg = Config.Admin or {}

    add("──────── OXLYN HANDLING • ACCESS REPORT ────────")
    add("player     : %s (server id %s)", tostring(report.name), tostring(target))
    add("framework  : %s%s", tostring(report.framework),
      Framework.Ready and "" or "  (no framework detected — ace/identifier only)")

    local methods = "ace, group, job, identifier (default)"
    if type(cfg.methods) == "table" and #cfg.methods > 0 then
      methods = table.concat(cfg.methods, ", ")
    end
    add("methods    : %s", methods)

    local group = Framework.GetGroup(target)
    local job, grade, onDuty = Framework.GetJob(target)
    add("group      : %s", tostring(group or "none"))
    add("job        : %s (grade %d, %s)", tostring(job or "none"), grade or 0, onDuty and "on duty" or "off duty")

    add("")
    add("sources consulted (any ALLOW grants access):")
    for _, source in ipairs(report.sources or {}) do
      add("  %-11s %-6s %s", source.source, source.verdict, tostring(source.detail or ""))
    end

    add("")
    add("RESULT     : %s%s",
      allowed and "ALLOWED" or "DENIED",
      allowed and (" (via " .. tostring(via) .. ")") or "")

    if not allowed then
      local identifiers = Framework.GetIdentifiers(target)
      local license = findIdentifier(identifiers, "license:") or findIdentifier(identifiers, "license2:")
      local ace = (type(cfg.aces) == "table" and cfg.aces[1]) or "oxlyn.handling.admin"
      local aceGroup = (type(cfg.groups) == "table" and cfg.groups[1]) or "admin"

      add("")
      add("To grant access, paste these TWO lines into the SERVER CONSOLE")
      add("(and add them to server.cfg so they survive a restart):")
      add("  add_ace group.%s %s allow", aceGroup, ace)
      add("  add_principal identifier.%s group.%s", tostring(license or "license:PUT_LICENSE_HERE"), aceGroup)
      add("")
      add("An add_ace in server.cfg only applies on a full SERVER start —")
      add("restarting the resource is not enough. Write license: only ONCE.")

      if license then
        add("")
        add("Or, with no ace at all, in config.lua:")
        add("  Config.Admin.identifiers = { '%s' }", license)
      end

      if #identifiers > 0 then
        add("")
        add("All identifiers for this player:")
        for _, id in ipairs(identifiers) do
          add("  %s", id)
        end
      end
    end

    add(string.rep("─", 60))

    for _, line in ipairs(lines) do
      print(line)
    end
    if src ~= 0 then
      for _, line in ipairs(lines) do
        TriggerClientEvent("chat:addMessage", src, { args = { "^5[handling]", line } })
      end
    end
  end, false)

  CreateThread(function()
    Wait(1500)
    TriggerClientEvent("chat:addSuggestion", -1, "/" .. Config.AccessCommand,
      "OXLYN Handling — why a player can (or cannot) open the editor",
      { { name = "serverId", help = "server id to test (defaults to you)" } })
  end)
end

