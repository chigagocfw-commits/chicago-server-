-- Server-Side Whitelist Lookup Table
local allowedJobs = {}
for i = 1, #Config.Jobs do
    allowedJobs[Config.Jobs[i].name] = Config.Jobs[i].label
end

-- Server-Side Rate Limiting & Concurrency State
local lastRequestTimers = {}
local pendingRequests = {}
local COOLDOWN_MS = 2500 -- 2.5 seconds cooldown between job changes

-- Clean up player state on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    lastRequestTimers[src] = nil
    pendingRequests[src] = nil
end)

-- Server Callback: Strictly validate and assign job
lib.callback.register('chicago_jobcenter:server:applyJob', function(source, requestedJob)
    local src = source

    -- 1. Concurrency Lock: Prevent simultaneous in-flight requests
    if pendingRequests[src] then
        print(string.format('[JOBCENTER SECURITY] Concurrent request blocked | source=%s', tostring(src)))
        return false, 'A job request is already being processed'
    end

    -- 2. Server-side Rate Limit: Cooldown enforcement
    local currentTime = GetGameTimer()
    local lastTime = lastRequestTimers[src] or 0
    if (currentTime - lastTime) < COOLDOWN_MS then
        local remainingSec = math.ceil((COOLDOWN_MS - (currentTime - lastTime)) / 1000)
        print(string.format('[JOBCENTER SECURITY] Rate limit triggered | source=%s | cooldown=%ds remaining', tostring(src), remainingSec))
        return false, string.format('Please wait %d seconds before requesting another job', remainingSec)
    end

    pendingRequests[src] = true

    local function finalize(success, message)
        lastRequestTimers[src] = GetGameTimer()
        pendingRequests[src] = nil
        return success, message
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then
        return finalize(false, 'Player data not found')
    end

    -- 3. Whitelist validation
    if type(requestedJob) ~= 'string' or not allowedJobs[requestedJob] then
        print(string.format('[JOBCENTER SECURITY] Unauthorized job request rejected | source=%s (citizenid=%s) | requestedJob=%s', 
            tostring(src), tostring(player.PlayerData.citizenid), tostring(requestedJob)))
        return finalize(false, 'Invalid or unauthorized job selection')
    end

    -- 4. Rigorous Ped & Coordinates Validation
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 or not DoesEntityExist(ped) then
        print(string.format('[JOBCENTER SECURITY] Invalid player ped entity | source=%s', tostring(src)))
        return finalize(false, 'Player entity not found')
    end

    local playerCoords = GetEntityCoords(ped)
    if not playerCoords or playerCoords == vector3(0, 0, 0) then
        print(string.format('[JOBCENTER SECURITY] Could not determine player coords | source=%s', tostring(src)))
        return finalize(false, 'Could not determine player position')
    end

    local targetCoords = vector3(Config.PedLocation.x, Config.PedLocation.y, Config.PedLocation.z)
    local distance = #(playerCoords - targetCoords)

    if distance > Config.MaxDistance then
        print(string.format('[JOBCENTER SECURITY] Distance check failed | source=%s | distance=%.2fm > %.2fm', 
            tostring(src), distance, Config.MaxDistance))
        return finalize(false, 'You are too far from the employment desk')
    end

    -- 5. Check if player already has this job
    if player.PlayerData.job.name == requestedJob then
        return finalize(false, 'You already have this job')
    end

    -- 6. Apply job through supported Qbox server-side API (Forced Grade = 0)
    local success, err = player.Functions.SetJob(requestedJob, 0)
    if not success then
        print(string.format('[JOBCENTER ERROR] SetJob failed | source=%s | job=%s | error=%s', 
            tostring(src), tostring(requestedJob), tostring(err and err.message or 'SetJob rejected')))
        return finalize(false, 'Failed to assign job. Please contact administration.')
    end

    local jobLabel = allowedJobs[requestedJob]
    return finalize(true, string.format('Congratulations! Your new job is: %s', jobLabel))
end)
