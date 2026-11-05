--[[ ═══════════════════════════════════════════════════════════════════════
    APEX LOADING: media library (server)

    THE method that works. A loading screen is served from nui://, which sends
    no Referer and no Origin, so every external platform (YouTube, Spotify,
    Streamable…) refuses it. A file that lives INSIDE the resource has none of
    those checks to pass: same origin, no CORS, no referrer, no API.

    So the creator uploads the file here, it is written into web/media/, and
    the design just points at `media/<name>`. Nothing external is involved at
    playback time, which is exactly why it cannot break.

    Uploads arrive base64-encoded through the chunked uplink
    (server/sv_uplink.lua): a whole song does not fit in one network event,
    and anything over the server's netEventSize burst drops the player.
    Each part is decoded the moment it lands, so finishing a big file never
    stalls the server thread.
═══════════════════════════════════════════════════════════════════════ ]]

local RESOURCE = GetCurrentResourceName()

local MAX_BYTES = 24 * 1024 * 1024          -- per file
local ALLOWED = {
    mp3 = true, ogg = true, wav = true, m4a = true, aac = true,   -- audio
    mp4 = true, webm = true, ogv = true,                          -- video
    png = true, jpg = true, jpeg = true, webp = true, gif = true, -- images
}

-- ── base64 ──────────────────────────────────────────────────────────────────
-- Four characters at a time, straight arithmetic, no per-byte closures: the
-- classic gsub decoder takes seconds on a megabyte and would stall the
-- server thread. Every uplink part is a multiple of 4 characters, so each
-- one decodes on its own.
local ALPHA = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local VAL = {}
for i = 1, #ALPHA do VAL[ALPHA:byte(i)] = i - 1 end

local byte, char = string.byte, string.char

local function b64decode(data)
    data = data:gsub('[^%w%+/]', '')
    local out, n = {}, 0
    local len = #data
    local full = len - len % 4
    for i = 1, full, 4 do
        local a, b, c, d = byte(data, i, i + 3)
        local v = VAL[a] * 262144 + VAL[b] * 4096 + VAL[c] * 64 + VAL[d]
        n = n + 1
        out[n] = char(v // 65536, (v // 256) % 256, v % 256)
    end
    local rem = len - full
    if rem == 2 then
        local a, b = byte(data, full + 1, full + 2)
        n = n + 1
        out[n] = char((VAL[a] * 262144 + VAL[b] * 4096) // 65536)
    elseif rem == 3 then
        local a, b, c = byte(data, full + 1, full + 3)
        local v = VAL[a] * 262144 + VAL[b] * 4096 + VAL[c] * 64
        n = n + 1
        out[n] = char(v // 65536, (v // 256) % 256)
    end
    return table.concat(out)
end

-- ── filenames ───────────────────────────────────────────────────────────────
local function safeName(name)
    name = tostring(name or ''):gsub('[/\\]', ''):gsub('%s+', '_')
    name = name:gsub('[^%w%._%-]', '')
    local ext = name:match('%.([%w]+)$')
    if not ext then return nil end
    ext = ext:lower()
    if not ALLOWED[ext] then return nil end
    local stem = name:sub(1, #name - #ext - 1):sub(1, 48)
    if stem == '' then stem = 'file' end
    return stem .. '.' .. ext
end

-- forward declaration: the upload handler below closes over this, and it is
-- defined further down with the rest of the index code
local remember

-- ── chunked uploads ─────────────────────────────────────────────────────────
Uplink.Register('media', {
    -- base64 is 4 characters for every 3 bytes
    maxBytes = math.ceil(MAX_BYTES / 3) * 4 + 4,

    begin = function(_, meta)
        local safe = safeName(meta.name)
        if not safe then return false, 'unsupported file type' end
        meta.safe = safe
        return true
    end,

    part = function(job, data, index)
        -- only the last part may end mid-group, or the bytes come out shifted
        if #data % 4 ~= 0 and index ~= job.total then error('a part was not 4-aligned') end
        return b64decode(data)
    end,

    done = function(src, raw, job)
        local name = job.meta.safe
        if #raw < 8 or #raw > MAX_BYTES then
            Uplink.Result(src, job, 'rejected, wrong size')
            TriggerClientEvent('apex_loading:client:MediaDone', src, false, 'file too large')
            return
        end
        -- read it back: SaveResourceFile has answered true on writes that
        -- never reached the disk
        local wrote = SaveResourceFile(RESOURCE, 'web/media/' .. name, raw, #raw)
        local back = wrote and LoadResourceFile(RESOURCE, 'web/media/' .. name)
        if not back or #back ~= #raw then
            Uplink.Result(src, job, 'web/media/' .. name .. ' could not be written')
            TriggerClientEvent('apex_loading:client:MediaDone', src, false, 'could not write the file')
            return
        end

        remember(name, #raw)
        Uplink.Result(src, job, 'saved web/media/' .. name)
        print(('[apex_loading] %s uploaded web/media/%s (%.1f MB): restart the resource to serve it')
            :format(GetPlayerName(src) or src, name, #raw / 1048576))
        TriggerClientEvent('apex_loading:client:MediaDone', src, true, name, #raw)
    end,
})

-- ── listing ─────────────────────────────────────────────────────────────────
-- The design remembers which files it uses, and every uploaded name is kept
-- in data/media.json: the server has no directory listing of its own.
local INDEX = 'data/media.json'

local function readIndex()
    local raw = LoadResourceFile(RESOURCE, INDEX)
    if not raw or #raw < 2 then return {} end
    local ok, t = pcall(json.decode, raw)
    return (ok and type(t) == 'table') and t or {}
end

local function writeIndex(list)
    SaveResourceFile(RESOURCE, INDEX, json.encode(list), -1)
end

function remember(name, size)
    local list = readIndex()
    for _, e in ipairs(list) do
        if e.name == name then e.size = size return writeIndex(list) end
    end
    list[#list + 1] = { name = name, size = size }
    writeIndex(list)
end

RegisterNetEvent('apex_loading:server:MediaList', function()
    local src = source
    if not Access.Check(src, 'creator') then return end
    TriggerClientEvent('apex_loading:client:MediaList', src, readIndex())
end)

RegisterNetEvent('apex_loading:server:MediaDelete', function(name)
    local src = source
    if not Access.Check(src, 'creator') then return end
    local safe = safeName(name)
    if not safe then return end
    -- an empty file is the closest thing to a delete the API offers
    SaveResourceFile(RESOURCE, 'web/media/' .. safe, '', 0)
    local list, out = readIndex(), {}
    for _, e in ipairs(list) do
        if e.name ~= safe then out[#out + 1] = e end
    end
    writeIndex(out)
    TriggerClientEvent('apex_loading:client:MediaList', src, out)
end)

exports('RememberMedia', remember)
MediaRemember = remember
