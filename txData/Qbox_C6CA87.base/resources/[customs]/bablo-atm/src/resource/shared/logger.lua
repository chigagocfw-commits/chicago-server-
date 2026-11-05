local function formatMessage(...)
    local parts = {}

    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end

    return table.concat(parts, " ")
end

local function log(level, ...)
    print(("[bablo-atm][%s]: %s"):format(level, formatMessage(...)))
end

function Trace(...)
    log("TRACE", ...)
end

function Debug(...)
    if Config and Config.DEBUG then
        log("DEBUG", ...)
    end
end

function Info(...)
    log("INFO", ...)
end

function Warn(...)
    log("WARN", ...)
end

function Error(...)
    log("ERROR", ...)
end

function Fatal(...)
    log("FATAL", ...)
end
