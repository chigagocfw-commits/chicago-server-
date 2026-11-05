local activeSounds = {}
local nextSoundId = 0
local isLoopRunning = false

local function calculateRelativeCoords(worldCoords)
    local camCoords = GetGameplayCamCoord()
    local camRot = GetGameplayCamRot(2)
    local pitch = math.rad(camRot.x)
    local yaw = math.rad(camRot.z)

    local cosPitch = math.cos(pitch)
    local sinPitch = math.sin(pitch)
    local cosYaw = math.cos(yaw)
    local sinYaw = math.sin(yaw)

    local forwardX = -sinYaw * cosPitch
    local forwardY = cosYaw * cosPitch
    local forwardZ = sinPitch

    local rightX = cosYaw
    local rightY = sinYaw

    local upX = rightY * sinPitch
    local upY = -rightX * sinPitch
    local upZ = rightX * forwardY - rightY * forwardX

    local diffX = worldCoords.x - camCoords.x
    local diffY = worldCoords.y - camCoords.y
    local diffZ = worldCoords.z - camCoords.z

    local relX = diffX * rightX + diffY * rightY
    local relY = diffX * upX + diffY * upY + diffZ * upZ
    local relZ = -(diffX * forwardX + diffY * forwardY + diffZ * forwardZ)
    local distance = #(worldCoords - camCoords)

    return relX, relY, relZ, distance
end

local function sendSoundUpdate(action, soundId, soundData)
    local relX, relY, relZ, distance = calculateRelativeCoords(soundData.coords)

    if distance > ScootConfig.soundDistance then
        SendNUIMessage({
            action = "update",
            id = soundId,
            volume = 0.0,
            x = relX,
            y = relY,
            z = relZ
        })
        return
    end

    SendNUIMessage({
        action = action,
        id = soundId,
        file = soundData.file,
        volume = soundData.base * ScootConfig.soundVolume,
        x = relX,
        y = relY,
        z = relZ,
        ref = ScootConfig.soundRefDistance,
        max = ScootConfig.soundDistance,
        rolloff = ScootConfig.soundRolloff
    })
end

local function startUpdateLoop()
    if isLoopRunning then
        return
    end

    isLoopRunning = true

    CreateThread(function()
        while next(activeSounds) do
            local currentTime = GetGameTimer()

            for soundId, soundData in pairs(activeSounds) do
                if currentTime >= soundData.expires then
                    activeSounds[soundId] = nil
                    SendNUIMessage({
                        action = "stop",
                        id = soundId
                    })
                else
                    sendSoundUpdate("update", soundId, soundData)
                end
            end

            Wait(50)
        end

        isLoopRunning = false
    end)
end

local AudioModule = {}

function AudioModule.play(soundFile, coords, baseVolume, durationSeconds)
    if not ScootConfig.playSounds then
        return
    end

    local _, _, _, distance = calculateRelativeCoords(coords)
    if distance > ScootConfig.soundDistance then
        return
    end

    nextSoundId = nextSoundId + 1
    local soundId = nextSoundId

    activeSounds[soundId] = {
        coords = coords,
        base = baseVolume,
        file = soundFile,
        expires = GetGameTimer() + math.floor(durationSeconds * 1000) + 200
    }

    sendSoundUpdate("play", soundId, activeSounds[soundId])
    startUpdateLoop()

    return soundId
end

function AudioModule.stopAll()
    for soundId in pairs(activeSounds) do
        activeSounds[soundId] = nil
        SendNUIMessage({
            action = "stop",
            id = soundId
        })
    end
end

CreateThread(function()
    if not ScootConfig.playSounds or not ScootConfig.sounds then
        return
    end

    local soundFiles = {}
    for i = 1, #ScootConfig.sounds do
        soundFiles[#soundFiles + 1] = ScootConfig.sounds[i].file
    end

    Wait(1000)

    SendNUIMessage({
        action = "preload",
        files = soundFiles
    })
end)

ScootAudio = AudioModule
