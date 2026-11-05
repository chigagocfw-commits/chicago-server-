-- SOUH4IL-DEV — Security & Rate Limiting Service
-- Implements millisecond-resolution Token-Bucket with strict fail-closed anomaly handling

local SharedConfig = require 'config.shared'
local Security = {}

local rateBuckets = {}
local TIMER_MAX_INT = 2147483647
local MAX_PLAUSIBLE_ELAPSED_MS = 3600000 -- 1 hour maximum plausible gap

---Validates execution rate with fail-closed anomaly protection and source verification
---@param source number
---@param action string
---@return boolean allowed, string? reason
function Security.CheckRateLimit(source, action)
    -- Guard 1: Strict numeric source validation
    if type(source) ~= 'number' or source <= 0 or math.tointeger(source) == nil then
        return false, "INVALID_SOURCE_ID"
    end

    -- Guard 2: Verify player presence on server
    local srcStr = tostring(source)
    if not DoesPlayerExist(srcStr) then
        return false, "PLAYER_NOT_ONLINE"
    end

    -- Guard 3: Reject unconfigured actions
    local rule = SharedConfig.RateLimits[action]
    if not rule then
        return false, "UNCONFIGURED_ACTION_REJECTED"
    end

    local nowMs = GetGameTimer()
    rateBuckets[source] = rateBuckets[source] or {}
    local bucket = rateBuckets[source][action]

    if not bucket then
        rateBuckets[source][action] = {
            tokens = rule.capacity - 1.0,
            lastFillMs = nowMs
        }
        return true
    end

    -- Elapsed time calculation with rollover compensation
    local elapsedMs = 0
    if nowMs >= bucket.lastFillMs then
        elapsedMs = nowMs - bucket.lastFillMs
    else
        -- Counter wrapped across 32-bit signed boundary (+1 for rollover boundary millisecond)
        elapsedMs = (TIMER_MAX_INT - bucket.lastFillMs) + nowMs + 1
    end

    -- Fail-Closed Anomaly Detection
    -- If clock anomalies occur, grant zero tokens, reset to 0, and reject current request
    if elapsedMs < 0 or elapsedMs > MAX_PLAUSIBLE_ELAPSED_MS then
        bucket.lastFillMs = nowMs
        bucket.tokens = math.min(bucket.tokens, 0.0)
        return false, "RATE_LIMIT_CLOCK_ANOMALY"
    end

    -- Regenerate fractional tokens
    bucket.tokens = math.min(rule.capacity, bucket.tokens + (elapsedMs * (rule.fillRatePerSec / 1000.0)))
    bucket.lastFillMs = nowMs

    if bucket.tokens >= 1.0 then
        bucket.tokens = bucket.tokens - 1.0
        return true
    end

    return false, "RATE_LIMIT_EXCEEDED"
end

---Sanitizes an input string to prevent injection / oversized payloads
---@param str any
---@param maxLen? number
---@return string
function Security.SanitizeString(str, maxLen)
    if type(str) ~= 'string' then
        return ""
    end

    local clean = str:gsub("[%c]", "") -- remove control chars
    if maxLen and #clean > maxLen then
        clean = clean:sub(1, maxLen)
    end
    return clean
end

-- Disconnect cleanup
AddEventHandler('playerDropped', function()
    rateBuckets[source] = nil
end)

-- Resource-stop cleanup
AddEventHandler('onResourceStop', function(res)
    if res == cache.resource then
        table.wipe(rateBuckets)
    end
end)

return Security

