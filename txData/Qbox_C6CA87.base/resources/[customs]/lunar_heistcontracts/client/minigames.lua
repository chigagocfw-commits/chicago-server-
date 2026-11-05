local minigamePromise

local function sendCallback(cb, payload)
    if cb then
        cb(payload or {})
    end
end

local function resolveMinigame(success)
    if minigamePromise then
        minigamePromise:resolve(success == true)
        minigamePromise = nil
    end
end

local function closeMinigame()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeInternalMinigame' })
end

---@param count integer
---@return string[]
local function generateRandomKeys(count)
    local keys = {}
    local alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWX'

    for i = 1, count do
        local index = math.random(1, #alphabet)
        keys[i] = alphabet:sub(index, index)
    end

    return keys
end

---@param name string
---@param data table
---@return boolean
local function openMinigame(name, data)
    resolveMinigame(false)

    minigamePromise = promise.new()

    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openMinigame',
        data = {
            name = name,
            data = data
        }
    })

    local success = Citizen.Await(minigamePromise)
    closeMinigame()

    return success == true
end

RegisterNUICallback('minigameFinished', function(data, cb)
    local success = data

    if type(data) == 'table' then
        success = data.success or data.result or data[1]
    end

    resolveMinigame(success == true)
    closeMinigame()
    sendCallback(cb, { ok = true, success = success == true })
end)

---@param count integer Number of keys to press
---@param seconds number Duration in seconds
exports('keys', function(count, seconds)
    return openMinigame('keys', {
        keys = generateRandomKeys(count),
        seconds = seconds
    })
end)

---@param sideLength integer Grid side length
---@param max integer Max number value
---@param seconds number Duration in seconds
exports('sort', function(sideLength, max, seconds)
    return openMinigame('sort', {
        sideLength = sideLength,
        max = max,
        seconds = seconds
    })
end)

---@param levels integer Number of lockpick rings
---@param seconds number Duration in seconds
exports('lockpick', function(levels, seconds)
    return openMinigame('lockpick', {
        levels = levels,
        seconds = seconds
    })
end)

---@param count integer Number of words to remember
---@param seconds number Duration in seconds
exports('words', function(count, seconds)
    local wordPools = Config.minigames and Config.minigames.words or Config.words

    return openMinigame('words', {
        words = wordPools[math.random(1, #wordPools)],
        count = count,
        seconds = seconds
    })
end)

---@param sequenceLength integer
---@param count integer Sequence count
---@param questionCount integer
---@param seconds number Duration in seconds
exports('terminal', function(sequenceLength, count, questionCount, seconds)
    return openMinigame('terminal', {
        sequenceLength = sequenceLength,
        count = count,
        questionCount = questionCount,
        seconds = seconds
    })
end)

---@param length integer PIN length
---@param seconds number Duration in seconds
exports('pinCracker', function(length, seconds)
    return openMinigame('pinCracker', {
        length = length,
        seconds = seconds
    })
end)

RegisterNUICallback('clearFocus', function(_, cb)
    resolveMinigame(false)
    closeMinigame()
    sendCallback(cb, { ok = true })
end)
