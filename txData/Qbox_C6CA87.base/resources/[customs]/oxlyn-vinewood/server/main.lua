

local RESOURCE         = GetCurrentResourceName()
local SCENE_FILE       = "data/scene.json"
local BACKUP_FILE      = "data/scene.backup.json"
local SESSION_SECONDS  = 60    -- editor lease length, refreshed by heartbeat/save
local SAVE_COOLDOWN    = 2     -- seconds between saves per player
local MAX_REVISION     = 9007199254740990 -- 2^53 - 2, keeps revision exact as a double

-- State
local currentScene, currentRevision
local lockReason                  -- set when saving is blocked to protect existing data
local session                     -- { player = src, expires = os.time() } (one editor at a time)
local snapshotPrimary, snapshotBackup -- raw file contents seen at load / last write
local rateLimits = {}             -- src -> { [key] = last time }
local lastSave   = {}             -- src -> last save time

-- Server console log (operational, not debug)
local function Log(message)
  print(("^3[%s]^7 %s"):format(RESOURCE, message))
end

local function Encode(value)
  local ok, encoded = pcall(json.encode, value)
  if ok and type(encoded) == "string" then return encoded end
  return nil
end

-- Parses and validates a scene file. Returns { scene, revision }, or nil + reason
local function ParseSceneFile(raw)
  if type(raw) ~= "string" or #raw > Config.Limits.MaxPayloadBytes + 1024 then
    return nil, "file is too large or unreadable"
  end

  local ok, decoded = pcall(json.decode, raw)
  if not (ok and type(decoded) == "table") then
    return nil, "invalid JSON"
  end

  local revision = decoded.revision
  if not (type(revision) == "number" and revision >= 0 and revision % 1 == 0 and revision <= MAX_REVISION) then
    return nil, "invalid revision"
  end

  local scene, err = VinewoodSchema.Validate(decoded.scene)
  if not scene then return nil, err end

  return { scene = scene, revision = revision }
end

-- Returns content, status ("present" | "absent" | "error")
local function ReadFile(path)
  local ok, content = pcall(LoadResourceFile, RESOURCE, path)
  if ok and type(content) == "string" then
    return content, "present"
  end

  -- LoadResourceFile returns nil for both missing and unreadable; use io to tell them apart
  local resourcePath = GetResourcePath(RESOURCE)
  if type(resourcePath) ~= "string" then return nil, "error" end

  local opened, file, _, errCode = pcall(io.open, resourcePath .. "/" .. path, "rb")
  if not opened then return nil, "error" end
  if not file then
    return nil, (errCode == 2) and "absent" or "error"
  end

  local readOk, data = pcall(file.read, file, "*a")
  pcall(file.close, file)

  if readOk and type(data) == "string" then
    return data, "present"
  end
  return nil, "error"
end

-- Writes then reads back to verify the file matches exactly
local function WriteFile(path, data)
  local ok, result = pcall(SaveResourceFile, RESOURCE, path, data, #data)
  if not ok or result == false then return false end

  local written, status = ReadFile(path)
  return status == "present" and written == data
end

-- Loads the scene (primary, then backup). Blocks saving if storage looks unsafe
local function LoadScene()
  local default, defaultErr = VinewoodSchema.Validate(Config.DefaultScene)
  assert(default, "Invalid Config.DefaultScene: " .. tostring(defaultErr))

  currentScene, currentRevision = default, 0

  local primaryRaw, primaryState = ReadFile(SCENE_FILE)
  local backupRaw, backupState   = ReadFile(BACKUP_FILE)
  snapshotPrimary, snapshotBackup = primaryRaw, backupRaw

  local primary, primaryErr = ParseSceneFile(primaryRaw)
  local backup, backupErr   = ParseSceneFile(backupRaw)

  if primary then
    currentScene, currentRevision = primary.scene, primary.revision
  elseif backup then
    currentScene, currentRevision = backup.scene, backup.revision
    Log("Loading the backup because the primary scene file is unavailable.")
  end

  -- unsafe if a file can't be read, the primary exists but is invalid,
  -- or a backup exists but is invalid
  local safe = primaryState ~= "error" and backupState ~= "error"
               and (primaryState ~= "present" or primary)
  if not safe or (backupState == "present" and not backup) then
    lockReason = L("server_storage_protected")
    Log(("Saving BLOCKED to preserve data. Primary: %s (%s); backup: %s (%s). Repair or move the damaged file, then restart the resource."):format(
      primaryState, primaryErr or "valid", backupState, backupErr or "valid"))
  else
    lockReason = nil
  end
end

local function Block(reason)
  lockReason = reason
  Log(reason)
  return false, reason
end

-- Writes backup (previous scene) then primary (new scene). Returns true, or false + reason
local function PersistScene(scene, revision)
  if lockReason then return false, lockReason end

  -- refuse to overwrite if the files changed behind our back
  local primaryRaw, primaryState = ReadFile(SCENE_FILE)
  local backupRaw, backupState   = ReadFile(BACKUP_FILE)
  if primaryState == "error" or backupState == "error"
     or primaryRaw ~= snapshotPrimary or backupRaw ~= snapshotBackup then
    return Block(L("server_data_changed"))
  end

  local backupJson = Encode({ revision = currentRevision, scene = currentScene })
  local newJson    = Encode({ revision = revision, scene = scene })
  if not backupJson or not newJson then
    return false, L("server_serialize_failed")
  end

  -- backup first, so a failed primary write never leaves us without a good copy
  if not WriteFile(BACKUP_FILE, backupJson) then
    return Block(L("server_backup_write_failed"))
  end
  if not WriteFile(SCENE_FILE, newJson) then
    return Block(L("server_scene_write_failed"))
  end

  snapshotPrimary, snapshotBackup = newJson, backupJson
  return true
end

local function IsPermitted(src)
  return VinewoodPermissions.Allowed(src)
end

local function ExpireSession(message)
  if not session then return end
  local player = session.player
  session = nil
  TriggerClientEvent("oxlyn-vinewood:sessionExpired", player, message or L("server_session_expired"))
end

-- True if this player currently holds the editor lease (expired leases are cleared first)
local function HasActiveLease(src)
  if session and os.time() >= session.expires then
    ExpireSession()
  end
  return session ~= nil and session.player == src
end

-- True if the player triggered this key less than minGap seconds ago
local function IsRateLimited(src, key, minGap)
  local now = os.time()
  local bucket = rateLimits[src] or {}
  rateLimits[src] = bucket

  if bucket[key] and now - bucket[key] < minGap then
    return true
  end
  bucket[key] = now
  return false
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------
LoadScene()

if VinewoodAssets then
  VinewoodAssets.Init({
    permitted   = IsPermitted,
    activeLease = HasActiveLease,
    getScene    = function() return currentScene end,
  })

  local ok, err = VinewoodAssets.ValidateScene(currentScene)
  if not ok then
    Log("Published image storage needs attention: " .. tostring(err))
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
RegisterNetEvent("oxlyn-vinewood:requestState", function()
  local src = source
  if IsRateLimited(src, "state", 2) then return end

  TriggerClientEvent("oxlyn-vinewood:state", src, { scene = currentScene, revision = currentRevision })
end)

RegisterNetEvent("oxlyn-vinewood:requestEditor", function()
  local src = source
  if IsRateLimited(src, "editor", 2) then return end

  if not IsPermitted(src) then
    TriggerClientEvent("oxlyn-vinewood:denied", src, L("server_no_permission_edit"))
    return
  end

  HasActiveLease(src) -- clears a stale session if it has expired

  if session and session.player ~= src then
    TriggerClientEvent("oxlyn-vinewood:denied", src, L("server_another_admin"))
    return
  end

  session = { player = src, expires = os.time() + SESSION_SECONDS }

  TriggerClientEvent("oxlyn-vinewood:editorGranted", src, {
    scene    = currentScene,
    revision = currentRevision,
    limits   = Config.Limits,
  })
end)

RegisterNetEvent("oxlyn-vinewood:heartbeat", function()
  local src = source
  if IsRateLimited(src, "heartbeat", 5) then return end
  if not HasActiveLease(src) then return end

  if not IsPermitted(src) then
    ExpireSession(L("server_permission_removed"))
    return
  end

  session.expires = os.time() + SESSION_SECONDS
end)

RegisterNetEvent("oxlyn-vinewood:closeEditor", function()
  if session and session.player == source then
    session = nil
  end
end)

RegisterNetEvent("oxlyn-vinewood:save", function(payload)
  local src = source

  local function fail(message)
    TriggerClientEvent("oxlyn-vinewood:saveResult", src, {
      ok = false, error = message, revision = currentRevision,
    })
  end

  if not IsPermitted(src) then
    if session and session.player == src then
      ExpireSession(L("server_permission_removed"))
    end
    return fail(L("server_no_permission_save"))
  end

  if not HasActiveLease(src) then
    return fail(L("server_session_expired_reopen"))
  end

  local now = os.time()
  if lastSave[src] and now - lastSave[src] < SAVE_COOLDOWN then
    return fail(L("server_save_rate", { seconds = SAVE_COOLDOWN }))
  end
  lastSave[src] = now

  -- optimistic concurrency: client must have edited the current revision
  if type(payload) ~= "table" or payload.baseRevision ~= currentRevision then
    return fail(L("server_scene_changed"))
  end

  if currentRevision >= MAX_REVISION then
    return fail(L("server_revision_limit"))
  end

  local encoded = Encode(payload)
  if not encoded or #encoded > Config.Limits.MaxPayloadBytes then
    return fail(L("server_scene_too_large", { max = Config.Limits.MaxPayloadBytes }))
  end

  local scene, schemaErr = VinewoodSchema.Validate(payload.scene)
  if not scene then return fail(schemaErr) end

  if VinewoodAssets then
    local assetsOk, assetsErr = VinewoodAssets.ValidateScene(scene)
    if not assetsOk then return fail(assetsErr) end
  end

  local newRevision = currentRevision + 1
  local saved, saveErr = PersistScene(scene, newRevision)
  if not saved then return fail(saveErr) end

  currentScene, currentRevision = scene, newRevision
  session.expires = now + SESSION_SECONDS

  TriggerClientEvent("oxlyn-vinewood:state", -1, { scene = currentScene, revision = currentRevision })
  TriggerClientEvent("oxlyn-vinewood:saveResult", src, { ok = true, scene = currentScene, revision = currentRevision })

  Log(("Scene published by player ID %d, revision %d, %d layer(s)."):format(src, currentRevision, #currentScene.layers))
end)

AddEventHandler("playerDropped", function()
  local src = source
  rateLimits[src] = nil
  lastSave[src] = nil

  if session and session.player == src then
    session = nil
  end
end)

-- Expire idle editor sessions even if nobody triggers an event
CreateThread(function()
  while true do
    Wait(15000)
    if session and os.time() >= session.expires then
      ExpireSession()
    end
  end
end)

exports("GetScene", function()
  return VinewoodSchema.Copy(currentScene), currentRevision
end)

