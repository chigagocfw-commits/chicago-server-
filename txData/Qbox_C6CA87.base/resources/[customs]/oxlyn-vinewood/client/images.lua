

-- Vinewood image cache + upload client (cleaned from decompiled output)

VinewoodImages = {}
local M = VinewoodImages

---------------------------------------------------------------------
-- Constants / state
---------------------------------------------------------------------
local CACHE_LIMIT     = 16      -- max images kept in memory (LRU)
local REQUEST_TTL     = 30000   -- ms before an unanswered image request may be repeated
local UPLOAD_TIMEOUT  = 120000  -- ms before an upload is declared dead
local PNG_PREFIX      = "^data:image/png;base64,"

local cache        = {}    -- [url] = { dataUrl, used }
local pending      = {}    -- [url] = time requested
local activeUpload = nil   -- { requestId, dataUrl, started }
local sentToUi     = {}    -- [url] = true once pushed to the NUI
local useCounter   = 0
local stopped      = false

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function isString(v)
    return type(v) == "string"
end

-- Largest allowed data URL: base64 of MaxBytes (4 chars per 3 bytes) + prefix slack
local function maxDataUrlLength()
    return math.ceil(Config.Uploads.MaxBytes / 3) * 4 + 22
end

local function isValidPngDataUrl(v)
    return isString(v) and #v <= maxDataUrlLength() and v:match(PNG_PREFIX) ~= nil
end

-- Clean a user-supplied file name: strip control chars, cap at 80 characters
local function sanitizeName(name)
    local fallback = L("image_imported_name")

    if not (isString(name) and utf8.len(name)) then
        return fallback
    end

    name = name:gsub("[%z\001-\031\127]", " ")

    local cut = utf8.offset(name, 81)
    local trimmed = (cut and name:sub(1, cut - 1)) or name

    if #trimmed > 0 then
        return trimmed
    end
    return fallback
end

local function editorActive()
    return VinewoodEditor and VinewoodEditor.Active
end

---------------------------------------------------------------------
-- Delivering images to the UI / renderer
---------------------------------------------------------------------
local function deliver(url, dataUrl)
    if editorActive() and not sentToUi[url] then
        SendNUIMessage({ action = "imageData", url = url, dataUrl = dataUrl })
        sentToUi[url] = true
    end

    if VinewoodRender and VinewoodRender.ImageLoaded then
        VinewoodRender.ImageLoaded(url, dataUrl)
    end
end

-- Insert into the cache, evicting the least-recently-used entry if over the limit
local function store(url, dataUrl)
    useCounter = useCounter + 1
    cache[url] = { dataUrl = dataUrl, used = useCounter }
    pending[url] = nil

    local count, oldestUse, oldestUrl = 0, math.huge, nil
    for u, entry in pairs(cache) do
        count = count + 1
        if entry.used < oldestUse then
            oldestUse, oldestUrl = entry.used, u
        end
    end

    if count > CACHE_LIMIT and oldestUrl then
        cache[oldestUrl] = nil
        sentToUi[oldestUrl] = nil
    end

    deliver(url, dataUrl)
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------
-- Cached data URL (marks it as recently used), or nil
function M.Get(url)
    local entry = cache[url]
    if entry then
        useCounter = useCounter + 1
        entry.used = useCounter
        return entry.dataUrl
    end
end

-- Ask the server for an image unless we have it / recently asked
function M.Want(url)
    if stopped or not isString(url) then return end
    if cache[url] then return end

    local now = GetGameTimer()
    if pending[url] and now - pending[url] < REQUEST_TTL then
        return
    end

    pending[url] = now
    TriggerServerEvent("oxlyn-vinewood:requestImage", { url = url })
end

-- Request every image used by a scene; optionally push cached ones to the UI
function M.WantScene(scene, pushToUi)
    local layers = scene.layers or {}

    if pushToUi then
        local used = {}
        for _, layer in ipairs(layers) do
            if layer.type == "image" then
                used[layer.url] = true
            end
        end
        for url in pairs(sentToUi) do
            if not used[url] then
                sentToUi[url] = nil
            end
        end
    end

    for _, layer in ipairs(layers) do
        if layer.type == "image" then
            M.Want(layer.url)
            if pushToUi and cache[layer.url] then
                deliver(layer.url, cache[layer.url].dataUrl)
            end
        end
    end
end

-- Forget what has been pushed to the UI (e.g. editor closed)
function M.ReleaseUi()
    sentToUi = {}
end

-- Drop the active upload (all, or only if the request id matches)
function M.Cancel(requestId)
    if activeUpload and (not requestId or activeUpload.requestId == requestId) then
        activeUpload = nil
    end
end

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------
RegisterNUICallback("cancelUpload", function(data, cb)
    if type(data) == "table" and isString(data.requestId) then
        M.Cancel(data.requestId)
    end
    cb({ ok = true })
end)

RegisterNUICallback("uploadImage", function(data, cb)
    if stopped or not editorActive() then
        cb({ ok = false, error = L("image_open_editor_first") })
        return
    end

    if activeUpload then
        cb({ ok = false, error = L("image_upload_busy") })
        return
    end

    local valid = type(data) == "table"
        and isString(data.requestId)
        and #data.requestId <= 64
        and data.requestId:match("^[%w_%-]+$")
        and isValidPngDataUrl(data.dataUrl)

    if not valid then
        cb({ ok = false, error = L("image_upload_invalid") })
        return
    end

    activeUpload = {
        requestId = data.requestId,
        dataUrl   = data.dataUrl,
        started   = GetGameTimer(),
    }

    TriggerLatentServerEvent("oxlyn-vinewood:uploadImage", Config.Uploads.BytesPerSecond, {
        requestId = data.requestId,
        name      = sanitizeName(data.name),
        dataUrl   = data.dataUrl,
    })

    cb({ ok = true, pending = true, requestId = data.requestId })
end)

---------------------------------------------------------------------
-- Server events
---------------------------------------------------------------------
RegisterNetEvent("oxlyn-vinewood:uploadResult", function(result)
    if stopped or type(result) ~= "table" or not activeUpload
        or result.requestId ~= activeUpload.requestId then
        return
    end

    if result.ok and isString(result.url) then
        store(result.url, activeUpload.dataUrl)
    elseif result.ok then
        -- server said ok but gave no usable url
        result = {
            requestId = result.requestId,
            ok        = false,
            error     = L("image_invalid_reference"),
        }
    end

    activeUpload = nil

    SendNUIMessage({
        action    = "uploadResult",
        requestId = result.requestId,
        ok        = result.ok == true,
        url       = result.url,
        error     = result.error,
    })
end)

RegisterNetEvent("oxlyn-vinewood:imageData", function(payload)
    if stopped or type(payload) ~= "table"
        or not isString(payload.url) or not pending[payload.url] then
        return
    end

    if isValidPngDataUrl(payload.dataUrl) then
        store(payload.url, payload.dataUrl)
    elseif editorActive() then
        SendNUIMessage({
            action = "imageData",
            url    = payload.url,
            error  = payload.error or L("image_load_failed"),
        })
    end
end)

---------------------------------------------------------------------
-- Upload watchdog + cleanup
---------------------------------------------------------------------
CreateThread(function()
    while not stopped do
        if activeUpload and GetGameTimer() - activeUpload.started > UPLOAD_TIMEOUT then
            SendNUIMessage({
                action    = "uploadResult",
                requestId = activeUpload.requestId,
                ok        = false,
                error     = L("image_upload_timeout"),
            })
            activeUpload = nil
        end
        Wait(1000)
    end
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        stopped      = true
        cache        = {}
        pending      = {}
        activeUpload = nil
        sentToUi     = {}
    end
end)

