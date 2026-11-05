Trace = function(...)
    if not Config.DEBUG then
        return
    end

    local logLine = ""
    local logString = { ... }

    if IsDuplicityVersion() then
        logLine = os.date('%Y-%m-%d %H:%M:%S', os.time())
    end

    logLine = logLine .. " [" .. (GetCurrentResourceName() or "LOG") .. "] "

    for i = 1, #logString do
        logLine = logLine .. tostring(logString[i]) .. " "
    end

    print(logLine)
end

IsResourceStartedOrStarting = function(resource)
    local state = GetResourceState(resource)
    return state == "started" or state == "starting"
end

GenerateAccountNumber = function()
    local pattern = Config.AccountNumberPrefix or 'BXXXXXXXXX'
    local result = ""

    for i = 1, #pattern do
        local c = pattern:sub(i, i)
        if c == 'X' then
            result = result .. math.random(0, 9)
        else
            result = result .. c
        end
    end

    return result
end

Translate = function(key, args)
    if not Config.Locale then
        return key
    end

    local translation = Locales[Config.Locale][key]

    if not translation then
        return key
    else
        if args ~= nil then
            if type(args) ~= "table" then
                args = { args }
            end

            for i = 1, #args do
                translation = translation:gsub("%%s", tostring(args[i]), 1)
            end
        end
    end

    return translation
end

TimestampToUnix = function(mysql_time)
    if not mysql_time then
        return os.time()
    end

    if type(mysql_time) == "number" then
        return mysql_time
    end
    if type(mysql_time) == "string" then
        local pattern = "(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)"
        local year, month, day, hour, min, sec = mysql_time:match(pattern)

        if year then
            return os.time({
                year = tonumber(year),
                month = tonumber(month),
                day = tonumber(day),
                hour = tonumber(hour),
                min = tonumber(min),
                sec = tonumber(sec)
            })
        end
    end

    return os.time()
end

Ensure = function(value, expectedType, defaultValue)
    if value == nil then
        if defaultValue ~= nil then
            return defaultValue
        else
            error("Expected value of type " .. expectedType .. ", but got nil")
        end
    end

    local actualType = type(value)
    if actualType ~= expectedType then
        error("Expected value of type " .. expectedType .. ", but got " .. actualType)
    end

    return value
end
