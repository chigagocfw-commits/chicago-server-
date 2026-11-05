

-- Vinewood font streaming (cleaned from decompiled output)
-- Streams per-font letter IPL "banks" (<prefix>_s1 .. _s4) in and out as scenes change.

VinewoodFontStreaming = {}
local M = VinewoodFontStreaming

---------------------------------------------------------------------
-- Constants / state
---------------------------------------------------------------------
local MAX_ACTIVE      = 24     -- max banks requested at once
local TICK_INTERVAL   = 250    -- ms between pump runs
local RETRY_INTERVAL  = 1000   -- ms between Request/RemoveIpl retries
local NOTICE_AFTER    = 15000  -- ms before warning that a bank hasn't loaded
local CLEAR_GRACE     = 1500   -- ms a retired bank must be fully gone before forgetting it
local ARCHETYPES_PER_BANK = 142

local fontsByPrefix = {}   -- [modelPrefix] = { id, font, probe }
local banks         = {}   -- [iplName]     = bank state
local wantedOrder   = {}   -- ordered list of bank names wanted by the current scene
local stopped       = false
local nextTick      = 0

---------------------------------------------------------------------
-- Index fonts by the prefix of their "A" (codepoint 65) model
---------------------------------------------------------------------
for fontId, font in pairs(VinewoodGlyphs.fonts) do
    local glyphA = font.glyphs[65]
    if font.streamingPrefix and glyphA then
        local prefix = glyphA.model:match("^(.-)_%x%x%x%x$")
        if prefix then
            fontsByPrefix[prefix] = {
                id    = fontId,
                font  = font,
                probe = glyphA.model,
            }
        end
    end
end

---------------------------------------------------------------------
-- On (re)start: any bank left loaded by a previous run is adopted as
-- "retired" so it gets removed cleanly.
---------------------------------------------------------------------
do
    local now = GetGameTimer()
    for _, info in pairs(fontsByPrefix) do
        for i = 1, 4 do
            local name  = info.font.streamingPrefix .. "_s" .. i
            local probe = GetHashKey(info.probe .. ((i == 1) and "" or ("_s" .. i)))

            if IsIplActive(name) or IsModelValid(probe) then
                banks[name] = {
                    name      = name,
                    font      = info.id,
                    probe     = probe,
                    since     = now,
                    requested = true,
                    retired   = true,
                    retryAt   = now + RETRY_INTERVAL,
                }
                RemoveIpl(name)
            end
        end
    end
end

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
-- "<prefix>_xxxx[_s2|_s3|_s4][_e]" -> bank name, font info, bank index
local function parseModel(model)
    if type(model) ~= "string" then return nil end

    local index = tonumber(model:match("_s([234])$")) or 1
    local base  = model:gsub("_s[234]$", "")
    base        = base:gsub("_e$", "")

    local prefix = base:match("^(.-)_%x%x%x%x$")
    local info   = fontsByPrefix[prefix]
    if not info then return nil end

    return info.font.streamingPrefix .. "_s" .. index, info, index
end

-- Warn (once per request) when a bank takes too long or is waiting on the budget
local function notice(bank, now, waitingOnBudget)
    if now - bank.since < NOTICE_AFTER or bank.noticed then
        return
    end
    bank.noticed = true

    local key = waitingOnBudget and "solid_font_budget_wait" or "solid_font_timeout"
    local msg = L(key, { font = bank.font, ipl = bank.name })
    print("[oxlyn-vinewood] " .. msg)

    if VinewoodEditor and VinewoodEditor.Active then
        SendNUIMessage({ action = "toast", kind = "error", message = msg })
    end
end

---------------------------------------------------------------------
-- Pump: drives requests/removals; throttled unless forced
---------------------------------------------------------------------
local function pump(now, force)
    if stopped then return end
    if not force and now < nextTick then return end
    nextTick = now + TICK_INTERVAL

    local active = 0

    for name, bank in pairs(banks) do
        local modelValid = IsModelValid(bank.probe)

        if bank.retired then
            -- waiting for the IPL to unload
            active = active + 1

            if not IsIplActive(name) and not modelValid then
                bank.clearSince = bank.clearSince or now
                if now - bank.clearSince >= CLEAR_GRACE then
                    banks[name] = nil
                    active = active - 1
                end
            else
                bank.clearSince = nil
                if now >= bank.retryAt then
                    RemoveIpl(name)
                    bank.retryAt = now + RETRY_INTERVAL
                end
            end

        elseif bank.requested then
            -- waiting for the IPL to load
            active = active + 1

            if not (modelValid and IsIplActive(name)) then
                if now >= bank.retryAt then
                    RequestIpl(name)
                    bank.retryAt = now + RETRY_INTERVAL
                end
            end

            if not modelValid then
                notice(bank, now, false)
            end
        end
    end

    -- start queued banks in scene order while under the budget
    for _, name in ipairs(wantedOrder) do
        local bank = banks[name]
        if bank and not bank.requested and not bank.retired then
            if active < MAX_ACTIVE then
                RequestIpl(name)
                bank.requested = true
                bank.retryAt   = now + RETRY_INTERVAL
                bank.noticed   = false
                bank.since     = now
                active = active + 1
            else
                notice(bank, now, true)
            end
        end
    end
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------
-- Declare which models the current scene needs.
--   list : array of { model = ... }
--   map  : table of  { model = ... }
function M.Sync(list, map)
    if stopped then return end

    local seen  = {}
    local order = {}
    local now   = GetGameTimer()

    local function want(model)
        local name, info, index = parseModel(model)
        if not name or seen[name] then return end

        seen[name] = true
        order[#order + 1] = name

        local bank = banks[name]
        if not bank then
            local probeName = info.probe .. ((index == 1) and "" or ("_s" .. index))
            banks[name] = {
                name      = name,
                font      = info.id,
                probe     = GetHashKey(probeName),
                since     = now,
                requested = false,
                retired   = false,
                retryAt   = 0,
            }
        elseif bank.retired then
            -- bank was on its way out but is wanted again
            bank.requested  = true
            bank.retired    = false
            bank.clearSince = nil
            bank.noticed    = false
            bank.since      = now
            RequestIpl(name)
            bank.retryAt = now + RETRY_INTERVAL
        end
    end

    for _, entry in ipairs(list) do want(entry.model) end
    for _, entry in pairs(map)   do want(entry.model) end

    -- retire banks that are no longer needed
    for name, bank in pairs(banks) do
        if not seen[name] and not bank.retired then
            if bank.requested then
                RemoveIpl(name)
                bank.retired = true
                bank.retryAt = now + RETRY_INTERVAL
            else
                banks[name] = nil
            end
        end
    end

    wantedOrder = order
    pump(now, true)
end

-- Is the bank for `model` fully loaded? (non-streamed models count as ready)
function M.Ready(model, now)
    if stopped then return false end

    local name = parseModel(model)
    if not name then return true end

    pump(now, false)

    local bank = banks[name]
    return bank ~= nil
        and bank.requested
        and not bank.retired
        and IsIplActive(name)
        and IsModelValid(bank.probe)
end

function M.Diagnostics()
    local info = {
        limit             = MAX_ACTIVE,
        archetypesPerBank = ARCHETYPES_PER_BANK,
        requested         = 0,
        retiring          = 0,
        queued            = 0,
    }

    for _, bank in pairs(banks) do
        local state = (bank.retired and "retiring")
            or (bank.requested and "requested")
            or "queued"
        info[state] = info[state] + 1
    end

    return info
end

function M.Stop()
    if stopped then return end
    stopped = true

    for name, bank in pairs(banks) do
        if bank.requested then
            RemoveIpl(name)
        end
    end

    banks       = {}
    wantedOrder = {}
end

