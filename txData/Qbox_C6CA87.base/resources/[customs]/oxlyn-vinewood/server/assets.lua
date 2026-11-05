

VinewoodAssets = {}

local RESOURCE        = GetCurrentResourceName()
local INDEX_FILE      = "data/upload-index.json"
local BACKUP_FILE     = "data/upload-index.backup.json"
local UPLOAD_DIR      = "data/uploads/"
local DATA_URL_PREFIX = "data:image/png;base64,"
local B64_ALPHABET    = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local PNG_SIGNATURE   = "\137PNG\r\n\026\n"
local MIN_PNG_SIZE    = 57   -- smallest sane PNG (signature + IHDR + IDAT + IEND)
local MAX_PNG_CHUNKS  = 1024

local UPLOAD_COOLDOWN = 3    -- seconds between uploads per player
local FETCH_BURST     = 8    -- fetch token bucket size
local FETCH_REFILL    = 2    -- seconds per refilled token
local FETCH_URL_GAP   = 10   -- seconds before the same url can be re-fetched
local CACHE_LIMIT     = 8    -- max cached images in memory

-- base64 char -> 6-bit value
local B64_DECODE = {}
for i = 1, #B64_ALPHABET do
  B64_DECODE[B64_ALPHABET:byte(i)] = i - 1
end

-- State
local indexEntries   = {}    -- ordered list of entries
local indexRecords   = {}    -- id -> entry
local snapshotPrimary, snapshotBackup  -- raw file contents seen at load / last write
local lockReason                       -- set when uploads are blocked to protect existing data
local lastUpload     = {}    -- src -> os.time() of last upload
local fetchBuckets   = {}    -- src -> { tokens, updated, urls = { [id] = time } }
local imageCache     = {}    -- id -> { dataUrl, used }
local cacheCount     = 0
local initialized    = false

-- Set in Init
local isPermitted, hasActiveLease, getScene, limits

-- Server console log (operational, not debug)
local function Log(message)
  print(("^3[%s uploads]^7 %s"):format(RESOURCE, message))
end

local function IsString(value)
  return type(value) == "string"
end

-- "upload:<32 hex>.png" -> id, otherwise nil
local function ParseUploadUrl(url)
  if not IsString(url) or #url ~= 43 then return nil end
  return url:match("^upload:([0-9a-f]+)%.png$")
end

local function ValidRequestId(value)
  if IsString(value) and #value >= 1 and #value <= 64 and value:match("^[A-Za-z0-9_%-]+$") then
    return value
  end
  return nil
end

local function ValidName(name)
  if not IsString(name) or #name < 1 or #name > 320 then return nil end
  if name:find("[%z\001-\031\127]") then return nil end -- control characters
  local length = utf8.len(name)
  if length and length <= 80 then return name end
  return nil
end

-- FIXED: the decompiled version ignored min/max entirely (only checked type and NaN),
-- so every limit check in the file was a no-op. Range check restored.
local function InRange(value, min, max)
  return type(value) == "number" and value == value and value >= min and value <= max
end

-- Returns content, status ("present" | "absent" | "error")
local function ReadFile(path)
  local ok, content = pcall(LoadResourceFile, RESOURCE, path)
  if ok and IsString(content) then
    return content, "present"
  end

  -- LoadResourceFile returns nil for both missing and unreadable; use io to tell them apart
  local resourcePath = GetResourcePath(RESOURCE)
  if not IsString(resourcePath) then return nil, "error" end

  local opened, file, _, errCode = pcall(io.open, resourcePath .. "/" .. path, "rb")
  if not opened then return nil, "error" end
  if not file then
    return nil, (errCode == 2) and "absent" or "error"
  end

  local readOk, data = pcall(file.read, file, "*a")
  pcall(file.close, file)

  if readOk and IsString(data) then
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

-- Block all further uploads (protects existing data when storage looks wrong)
local function BlockUploads(reason)
  lockReason = reason
  Log("Uploads blocked to preserve existing data: " .. reason)
  return nil, reason
end

local function DecodeBase64(b64)
  return (b64:gsub("....", function(chunk)
    local a, b, c, d = chunk:byte(1, 4)
    local n = (B64_DECODE[a] << 18) | (B64_DECODE[b] << 12)
            | ((B64_DECODE[c] or 0) << 6) | (B64_DECODE[d] or 0)

    if chunk:sub(3, 3) == "=" then
      return string.char((n >> 16) & 255)
    end
    if chunk:sub(4, 4) == "=" then
      return string.char((n >> 16) & 255, (n >> 8) & 255)
    end
    return string.char((n >> 16) & 255, (n >> 8) & 255, n & 255)
  end))
end

-- Strict "data:image/png;base64,..." decoder. Returns bytes, or nil + error message
local function DecodeDataUrl(dataUrl)
  if not IsString(dataUrl) or dataUrl:sub(1, #DATA_URL_PREFIX) ~= DATA_URL_PREFIX then
    return nil, L("upload_not_png_data")
  end

  local b64 = dataUrl:sub(#DATA_URL_PREFIX + 1)
  local maxLength = math.ceil(limits.MaxBytes / 3) * 4

  if #b64 < 4 or #b64 % 4 ~= 0 or #b64 > maxLength or b64:find("[^A-Za-z0-9+/=]") then
    return nil, L("upload_encoding_invalid")
  end

  -- padding: at most 2 "=", only at the very end
  local padding = #(b64:match("=+$") or "")
  if padding > 2 or b64:sub(1, #b64 - padding):find("=", 1, true) then
    return nil, L("upload_padding")
  end

  if (#b64 / 4) * 3 - padding > limits.MaxBytes then
    return nil, L("upload_too_large", { max = math.floor(limits.MaxBytes / 1024) })
  end

  -- canonical encoding: unused trailing bits must be zero
  local thirdLast  = B64_DECODE[b64:byte(-3)]
  local secondLast = B64_DECODE[b64:byte(-2)]
  if padding == 2 and (not thirdLast or thirdLast % 16 ~= 0) then
    return nil, L("upload_not_canonical")
  end
  if padding == 1 and (not secondLast or secondLast % 4 ~= 0) then
    return nil, L("upload_not_canonical")
  end

  return DecodeBase64(b64)
end

local function EncodeDataUrl(bytes)
  local fullLength = #bytes - (#bytes % 3)

  local encoded = bytes:sub(1, fullLength):gsub("...", function(chunk)
    local a, b, c = chunk:byte(1, 3)
    local n = (a << 16) | (b << 8) | c
    local i1, i2, i3, i4 = (n >> 18) & 63, (n >> 12) & 63, (n >> 6) & 63, n & 63
    return B64_ALPHABET:sub(i1 + 1, i1 + 1) .. B64_ALPHABET:sub(i2 + 1, i2 + 1)
        .. B64_ALPHABET:sub(i3 + 1, i3 + 1) .. B64_ALPHABET:sub(i4 + 1, i4 + 1)
  end)

  local remainder = #bytes - fullLength
  if remainder == 1 then
    local a = bytes:byte(fullLength + 1)
    local i1, i2 = a >> 2, (a & 3) << 4
    encoded = encoded .. B64_ALPHABET:sub(i1 + 1, i1 + 1) .. B64_ALPHABET:sub(i2 + 1, i2 + 1) .. "=="
  elseif remainder == 2 then
    local a, b = bytes:byte(fullLength + 1, fullLength + 2)
    local i1 = a >> 2
    local i2 = ((a & 3) << 4) | (b >> 4)
    local i3 = (b & 15) << 2
    encoded = encoded .. B64_ALPHABET:sub(i1 + 1, i1 + 1) .. B64_ALPHABET:sub(i2 + 1, i2 + 1)
                      .. B64_ALPHABET:sub(i3 + 1, i3 + 1) .. "="
  end

  return DATA_URL_PREFIX .. encoded
end

local function ReadU32(bytes, pos)
  return (string.unpack(">I4", bytes, pos))
end

local function IsValidPngFormat(bitDepth, colorType)
  if colorType == 0 then
    return bitDepth == 1 or bitDepth == 2 or bitDepth == 4 or bitDepth == 8 or bitDepth == 16
  elseif colorType == 3 then
    return bitDepth == 1 or bitDepth == 2 or bitDepth == 4 or bitDepth == 8
  elseif colorType == 2 or colorType == 4 or colorType == 6 then
    return bitDepth == 8 or bitDepth == 16
  end
  return false
end

-- Walks every PNG chunk. Returns { width, height }, or nil + error message
local function ValidatePng(bytes)
  if not IsString(bytes) or #bytes < MIN_PNG_SIZE or #bytes > limits.MaxBytes
     or bytes:sub(1, 8) ~= PNG_SIGNATURE then
    return nil, L("upload_png_invalid")
  end

  local pos, chunkCount = 9, 0
  local width, height, colorType
  local seenIHDR, seenPLTE, seenIDAT, idatEnded = false, false, false, false

  while pos <= #bytes do
    chunkCount = chunkCount + 1
    if chunkCount > MAX_PNG_CHUNKS or pos + 11 > #bytes then
      return nil, L("upload_png_incomplete")
    end

    local length    = ReadU32(bytes, pos)
    local chunkType = bytes:sub(pos + 4, pos + 7)

    if length > #bytes - pos - 11 or not chunkType:match("^[A-Za-z][A-Za-z][A-Z][A-Za-z]$") then
      return nil, L("upload_png_chunk")
    end

    local dataStart = pos + 8
    local nextPos   = pos + 12 + length

    if not seenIHDR and chunkType ~= "IHDR" then
      return nil, L("upload_png_header_first")
    end

    if chunkType == "IHDR" then
      if seenIHDR or length ~= 13 then
        return nil, L("upload_png_header")
      end

      width  = ReadU32(bytes, dataStart)
      height = ReadU32(bytes, dataStart + 4)
      if not InRange(width, 1, limits.MaxDimension) or not InRange(height, 1, limits.MaxDimension) then
        return nil, L("upload_png_dimensions", { max = limits.MaxDimension })
      end

      local bitDepth, compression, filter, interlace
      bitDepth, colorType, compression, filter, interlace = bytes:byte(dataStart + 8, dataStart + 12)

      if not IsValidPngFormat(bitDepth, colorType) or compression ~= 0 or filter ~= 0
         or (interlace ~= 0 and interlace ~= 1) then
        return nil, L("upload_png_format")
      end
      seenIHDR = true

    elseif chunkType == "PLTE" then
      -- palette must come before IDAT, once, 1-256 entries, and never for grayscale types
      if seenPLTE or seenIDAT or length < 3 or length > 768 or length % 3 ~= 0
         or colorType == 0 or colorType == 4 then
        return nil, L("upload_png_palette")
      end
      seenPLTE = true

    elseif chunkType == "IDAT" then
      -- IDAT chunks must be contiguous; indexed images need a palette first
      if idatEnded or (colorType == 3 and not seenPLTE) then
        return nil, L("upload_png_data")
      end
      if length > 0 then seenIDAT = true end

    elseif chunkType == "IEND" then
      if length == 0 and seenIDAT and nextPos == #bytes + 1 then
        return { width = width, height = height }
      end
      return nil, L("upload_png_end")

    else
      -- unknown critical chunks (uppercase first letter) are rejected
      if chunkType:sub(1, 1):match("[A-Z]") then
        return nil, L("upload_png_critical")
      end
      if seenIDAT then idatEnded = true end
    end

    pos = nextPos
  end

  return nil, L("upload_png_end_missing")
end

-- Validates raw index JSON. Returns { entries, records }, or nil + reason
local function ParseIndex(raw)
  if not IsString(raw) or #raw > limits.MaxStored * 512 + 1024 then
    return nil, "unreadable or oversized index"
  end

  local ok, decoded = pcall(json.decode, raw)
  if not (ok and type(decoded) == "table" and decoded.version == 1 and type(decoded.entries) == "table") then
    return nil, "invalid index JSON or version"
  end

  -- keys must be 1..MaxStored
  local count = 0
  for key in pairs(decoded.entries) do
    if not InRange(key, 1, limits.MaxStored) then
      return nil, "invalid index entries"
    end
    count = count + 1
  end

  local entries, records = {}, {}
  for i = 1, count do
    local entry = decoded.entries[i]
    if not (type(entry) == "table"
        and IsString(entry.id)
        and not records[entry.id]
        and ValidName(entry.name)
        and InRange(entry.size, MIN_PNG_SIZE, limits.MaxBytes)
        and InRange(entry.width, 1, limits.MaxDimension)
        and InRange(entry.height, 1, limits.MaxDimension)) then
      return nil, "invalid index entries"
    end

    local clean = { id = entry.id, name = entry.name, size = entry.size, width = entry.width, height = entry.height }
    records[entry.id] = clean
    entries[i] = clean
  end

  return { entries = entries, records = records }
end

-- Loads primary index, falling back to the backup. Blocks uploads if storage looks unsafe
local function LoadIndex()
  local primaryRaw, primaryState = ReadFile(INDEX_FILE)
  local backupRaw, backupState   = ReadFile(BACKUP_FILE)
  snapshotPrimary, snapshotBackup = primaryRaw, backupRaw

  local primary, primaryErr = ParseIndex(primaryRaw)
  local backup, backupErr   = ParseIndex(backupRaw)

  if primary then
    indexEntries, indexRecords = primary.entries, primary.records
  elseif backup then
    indexEntries, indexRecords = backup.entries, backup.records
    Log("Using the verified backup upload index for existing images.")
  end

  local safe = primaryState ~= "error" and backupState ~= "error"
               and (primaryState ~= "present" or primary)
  if not safe or (backupState == "present" and not backup) then
    BlockUploads(L("upload_storage_index"))
    Log(("Primary: %s (%s); backup: %s (%s)."):format(
      primaryState, primaryErr or "valid", backupState, backupErr or "valid"))
  end
end

-- Confirms the index files weren't changed behind our back since we last read/wrote them
local function CheckStorageUnchanged()
  local primaryRaw, primaryState = ReadFile(INDEX_FILE)
  local backupRaw, backupState   = ReadFile(BACKUP_FILE)

  if primaryState ~= "error" and backupState ~= "error"
     and primaryRaw == snapshotPrimary and backupRaw == snapshotBackup then
    return true
  end
  return BlockUploads(L("upload_storage_changed"))
end

-- Small LRU cache of encoded images
local function CacheSet(id, dataUrl)
  if not imageCache[id] and cacheCount >= CACHE_LIMIT then
    local oldestId, oldestUsed
    for cachedId, cached in pairs(imageCache) do
      if not oldestUsed or oldestUsed > cached.used then
        oldestId, oldestUsed = cachedId, cached.used
      end
    end
    if oldestId then
      imageCache[oldestId] = nil
      cacheCount = cacheCount - 1
    end
  end

  if not imageCache[id] then cacheCount = cacheCount + 1 end
  imageCache[id] = { dataUrl = dataUrl, used = os.time() }
end

-- Reads a registered image from disk and verifies it still matches its index record
local function LoadStoredImage(id)
  local record = indexRecords[id]
  if not record then return nil, L("upload_not_registered") end

  local bytes, status = ReadFile(UPLOAD_DIR .. id .. ".png")
  if status ~= "present" or #bytes ~= record.size then
    return nil, L("upload_missing")
  end

  local info = ValidatePng(bytes)
  if not (info and info.width == record.width and info.height == record.height) then
    return nil, L("upload_damaged")
  end

  return bytes
end

-- Random 32-char hex id that isn't registered and has no file on disk
local function NewUploadId()
  for _ = 1, 32 do
    local parts = {}
    for i = 1, 16 do
      parts[i] = ("%02x"):format(math.random(0, 255))
    end
    local id = table.concat(parts)

    if not indexRecords[id] then
      local _, status = ReadFile(UPLOAD_DIR .. id .. ".png")
      if status == "absent" then return id end
      if status == "error" then return BlockUploads(L("upload_storage_folder")) end
    end
  end
  return nil, L("upload_id_failed")
end

-- Is this image url used by the scene currently published?
local function SceneUsesImage(url)
  local scene = getScene()
  local layers = (type(scene) == "table" and scene.layers) or {}
  for _, layer in ipairs(layers) do
    if layer.type == "image" and layer.url == url then
      return true
    end
  end
  return false
end

-- Checks every "upload:" image in a scene exists, is registered and is intact
function VinewoodAssets.ValidateScene(scene)
  for _, layer in ipairs(scene.layers or {}) do
    if layer.type == "image" and IsString(layer.url) and layer.url:sub(1, 7) == "upload:" then
      if lockReason then return nil, lockReason end

      local id = ParseUploadUrl(layer.url)
      if not (id and indexRecords[id]) then
        return nil, L("upload_unknown_reimport")
      end

      local bytes, err = LoadStoredImage(id)
      if not bytes then return nil, err end
    end
  end
  return true
end

function VinewoodAssets.Init(opts)
  assert(not initialized, "VinewoodAssets.Init called more than once")
  initialized = true

  isPermitted, hasActiveLease, getScene = opts.permitted, opts.activeLease, opts.getScene
  -- checks all three (original only checked `permitted`, but the others are called unguarded)
  assert(type(isPermitted) == "function" and type(hasActiveLease) == "function" and type(getScene) == "function",
    "Missing upload authority callbacks")

  limits = (Config and Config.Uploads) or {
    MaxBytes       = 786432,
    MaxDimension   = 2048,
    MaxStored      = 128,
    BytesPerSecond = 131072,
  }
  assert(InRange(limits.MaxBytes, MIN_PNG_SIZE, 786432)
     and InRange(limits.MaxDimension, 1, 2048)
     and InRange(limits.MaxStored, 1, 128)
     and InRange(limits.BytesPerSecond, 1024, 1048576),
    "Invalid Config.Uploads limits")

  LoadIndex()

  ---------------------------------------------------------------------------
  -- Client -> server: upload a new image
  ---------------------------------------------------------------------------
  RegisterNetEvent("oxlyn-vinewood:uploadImage", function(payload)
    local src = source
    local requestId = type(payload) == "table" and ValidRequestId(payload.requestId)
    if not requestId then return end

    local function reply(ok, valueOrError)
      if ok then
        TriggerClientEvent("oxlyn-vinewood:uploadResult", src, { requestId = requestId, ok = true, url = valueOrError })
      else
        TriggerClientEvent("oxlyn-vinewood:uploadResult", src, { requestId = requestId, ok = false, error = valueOrError })
      end
    end

    if not (isPermitted(src) and hasActiveLease(src)) then
      return reply(false, L("upload_unauthorized"))
    end

    local now = os.time()
    if lastUpload[src] and now - lastUpload[src] < UPLOAD_COOLDOWN then
      return reply(false, L("upload_rate", { seconds = UPLOAD_COOLDOWN }))
    end
    lastUpload[src] = now

    if lockReason then return reply(false, lockReason) end

    if #indexEntries >= limits.MaxStored then
      return reply(false, L("upload_library_full", { max = limits.MaxStored }))
    end

    local name = ValidName(payload.name)
    if not name then return reply(false, L("upload_name_invalid")) end

    -- cheap size check before doing any decoding work
    local maxDataUrl = #DATA_URL_PREFIX + math.ceil(limits.MaxBytes / 3) * 4
    if not IsString(payload.dataUrl) or #payload.dataUrl > maxDataUrl then
      return reply(false, L("upload_too_large", { max = math.floor(limits.MaxBytes / 1024) }))
    end

    local bytes, decodeErr = DecodeDataUrl(payload.dataUrl)
    if not bytes then return reply(false, decodeErr) end

    local info, pngErr = ValidatePng(bytes)
    if not info then return reply(false, pngErr) end

    if not CheckStorageUnchanged() then return reply(false, lockReason) end

    local id, idErr = NewUploadId()
    if not id then return reply(false, idErr) end

    local path = UPLOAD_DIR .. id .. ".png"
    if not WriteFile(path, bytes) then
      BlockUploads(L("upload_storage_write"))
      return reply(false, lockReason)
    end

    local entry = { id = id, name = name, size = #bytes, width = info.width, height = info.height }

    local newEntries = {}
    for i, existing in ipairs(indexEntries) do newEntries[i] = existing end
    newEntries[#newEntries + 1] = entry

    local okPrimary, primaryJson = pcall(json.encode, { version = 1, entries = newEntries })
    local okBackup, backupJson   = pcall(json.encode, { version = 1, entries = indexEntries }) -- backup = previous index

    -- backup is written first so a failed primary write never leaves us without a good copy
    local saved = okPrimary and IsString(primaryJson) and okBackup and IsString(backupJson)
                  and WriteFile(BACKUP_FILE, backupJson) and WriteFile(INDEX_FILE, primaryJson)
    if not saved then
      BlockUploads(L("upload_storage_index_write", { path = path }))
      return reply(false, lockReason)
    end

    -- commit to memory only after both files are safely on disk
    snapshotPrimary, snapshotBackup = primaryJson, backupJson
    indexRecords[id] = entry
    indexEntries = newEntries
    CacheSet(id, payload.dataUrl)

    reply(true, "upload:" .. id .. ".png")
  end)

  ---------------------------------------------------------------------------
  -- Client -> server: request an image's data
  ---------------------------------------------------------------------------
  RegisterNetEvent("oxlyn-vinewood:requestImage", function(payload)
    local src = source
    local url = type(payload) == "table" and payload.url
    local id = ParseUploadUrl(url)
    if not id then return end

    local function respond(dataUrl, err)
      TriggerLatentClientEvent("oxlyn-vinewood:imageData", src, limits.BytesPerSecond, {
        url = url, dataUrl = dataUrl, error = err,
      })
    end

    -- token bucket per player + per-url cooldown
    local now = os.time()
    local bucket = fetchBuckets[src]
    if not bucket then
      bucket = { tokens = FETCH_BURST, updated = now, urls = {} }
      fetchBuckets[src] = bucket
    end

    bucket.tokens = math.min(FETCH_BURST, bucket.tokens + math.max(0, now - bucket.updated) / FETCH_REFILL)
    bucket.updated = now

    if bucket.tokens < 1 or (bucket.urls[id] and now - bucket.urls[id] < FETCH_URL_GAP) then
      return respond(nil, L("upload_fetch_rate"))
    end
    bucket.tokens = bucket.tokens - 1

    -- anyone can fetch images used by the published scene; editors can fetch any registered image
    if not SceneUsesImage(url) then
      if not (isPermitted(src) and hasActiveLease(src)) then
        return respond(nil, L("upload_not_published"))
      end
    end

    if not indexRecords[id] then
      return respond(nil, lockReason or L("upload_unknown"))
    end

    bucket.urls[id] = now

    local cached = imageCache[id]
    if cached then
      cached.used = now
      return respond(cached.dataUrl)
    end

    local bytes, err = LoadStoredImage(id)
    if not bytes then return respond(nil, err) end

    local dataUrl = EncodeDataUrl(bytes)
    CacheSet(id, dataUrl)
    respond(dataUrl)
  end)

  AddEventHandler("playerDropped", function()
    lastUpload[source] = nil
    fetchBuckets[source] = nil
  end)
end

