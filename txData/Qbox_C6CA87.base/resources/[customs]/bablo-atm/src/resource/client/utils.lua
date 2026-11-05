utils = {}

function utils.encodeUrl(value)
    if type(value) ~= "string" then
        Debug("utils.encodeUrl: Expected string, got " .. type(value))
        return ""
    end

    value = value:gsub("\n", "\r\n")
    value = value:gsub("([^%w _%%%-%.~])", function(character)
        return ("%%%02X"):format(string.byte(character))
    end)
    value = value:gsub(" ", "+")

    return value
end

function loadAnimDict(dictionary, callback)
    if not dictionary then
        Debug("loadAnimDict: No dictionary provided")

        if callback then
            callback()
        end

        return
    end

    if HasAnimDictLoaded(dictionary) then
        if callback then
            callback()
        end

        return
    end

    RequestAnimDict(dictionary)

    local attempts = 0
    while not HasAnimDictLoaded(dictionary) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasAnimDictLoaded(dictionary) then
        Debug("loadAnimDict: Failed to load animation dictionary: " .. dictionary)
    end

    if callback then
        callback()
    end
end

function createObject(model, coords, isLocal, callback)
    if type(model) == "string" then
        model = GetHashKey(model)
    end

    RequestModel(model)

    local attempts = 0
    while not HasModelLoaded(model) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(model) then
        Debug("createObject: Failed to load model: " .. tostring(model))

        if callback then
            callback(nil)
        end

        return nil
    end

    local networked = not isLocal
    local object = CreateObject(model, coords.x, coords.y, coords.z, networked, networked, false)
    SetModelAsNoLongerNeeded(model)

    if callback then
        callback(object)
    end

    return object
end
