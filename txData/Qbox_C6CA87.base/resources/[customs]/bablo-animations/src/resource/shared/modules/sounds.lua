



-- Wait for eventName to be set by s_main / c_main
while not eventName do Wait(0) end

if not Config.Music or not Config.Music.Enabled then return end

if not IsResourceStartedOrStarting("xsound") then
    Trace("Warning: XSound is not started. Music will not work.")
    return
end

XSound = false

-- ─── Module-level variables ───────────────────────────────────────────────────

-- Shared music cache: array of track entries.
-- Client:  { uniqueId, url, pos, playerSource, time }
-- Server:  same, plus `created` (os.time)
local musicCache = {}

-- =============================================================================
-- CLIENT SIDE
-- =============================================================================

if not IsDuplicityVersion() then

    XSound = exports.xsound

    -- Recently-destroyed guard: { [uniqueId] = gameTimestamp }
    -- Prevents re-playing tracks destroyed within the last 3 seconds.
    local recentlyDestroyed = {}
    local RECENT_DESTROY_WINDOW = 3000

    -- Stop-all cooldown
    local lastStopAllTime    = 0
    local STOP_ALL_COOLDOWN  = 1000

    -- SafeDestroy retry params
    local DESTROY_RETRIES    = 5
    local DESTROY_RETRY_WAIT = 100

    -- ── Helpers ───────────────────────────────────────────────────────────────

    local function isRecentlyDestroyed(uniqueId)
        local ts = recentlyDestroyed[uniqueId]
        if not ts then return false end
        if (GetGameTimer() - ts) > RECENT_DESTROY_WINDOW then
            recentlyDestroyed[uniqueId] = nil
            return false
        end
        return true
    end

    local function markRecentlyDestroyed(uniqueId)
        recentlyDestroyed[uniqueId] = GetGameTimer()
    end

    local function clearRecentlyDestroyed(uniqueId)
        recentlyDestroyed[uniqueId] = nil
    end

    -- Safely destroy an XSound track, retrying up to DESTROY_RETRIES times.
    local function safeDestroyXSound(uniqueId)
        if not uniqueId then return end
        if isRecentlyDestroyed(uniqueId) then return end
        markRecentlyDestroyed(uniqueId)

        if not XSound:soundExists(uniqueId) then
            clearRecentlyDestroyed(uniqueId)
            return
        end

        local destroyed = false
        for _ = 1, DESTROY_RETRIES do
            XSound:Destroy(uniqueId)
            Wait(DESTROY_RETRY_WAIT)
            if not XSound:soundExists(uniqueId) then
                destroyed = true
                break
            end
        end

        if not destroyed then
            local cacheCount = 0
            for _ in pairs(musicCache) do cacheCount = cacheCount + 1 end
            Trace("SafeDestroyXSound: failed to destroy after retries", uniqueId, "cacheCount=", cacheCount)
        end

        clearRecentlyDestroyed(uniqueId)
    end

    -- Wait until Main.settings.musicVolume is ready
    while not (Main and Main.settings and Main.settings.musicVolume ~= nil) do
        Wait(0)
    end

    -- ─── RequestPlayMusic(url) ────────────────────────────────────────────────
    -- Registers a new music track in the server cache and triggers nearby clients
    -- to play it via XSound. Returns a uniqueId string.

    function RequestPlayMusic(url)
        local ped = PlayerPedId()
        if not ped or ped == 0 then return nil end

        local track = {
            uniqueId     = "EMOTE_MUSIC_" .. GenerateUniqueId(),
            time         = 0,
            playerSource = GetPlayerServerId(PlayerId()),
            url          = url,
            pos          = GetEntityCoords(ped),
        }

        TriggerServerEvent(eventName .. "server:addToCache", track)
        return track.uniqueId
    end

    -- ─── UpdateVolume(vol) ────────────────────────────────────────────────────
    -- Sets the volume (0-100) on all active XSound tracks in the local cache.

    function UpdateVolume(vol)
        for _, track in pairs(musicCache) do
            if XSound:soundExists(track.uniqueId) then
                local currentVol = XSound:getVolume(track.uniqueId)
                if currentVol ~= 0.0 then
                    XSound:setVolumeMax(track.uniqueId, vol)
                end
            end
        end
    end

    -- ─── IsBeingPlayed(uniqueId) ──────────────────────────────────────────────
    -- Returns true if the given uniqueId is in the local music cache.

    function IsBeingPlayed(uniqueId)
        for _, track in pairs(musicCache) do
            if track.uniqueId == uniqueId then return true end
        end
        return false
    end

    -- ─── DestroyMusic(uniqueId) ───────────────────────────────────────────────
    -- Stops a specific track and removes it from all server caches.

    function DestroyMusic(uniqueId)
        -- Find the cache index
        local cacheIdx = nil
        for i, track in pairs(musicCache) do
            if track.uniqueId == uniqueId then
                cacheIdx = i
                break
            end
        end

        if not cacheIdx then
            Trace("Warning: DestroyMusic called for uniqueId not found in local cache:", uniqueId)
        end

        safeDestroyXSound(uniqueId)

        if type(cacheIdx) == "number" then
            table.remove(musicCache, cacheIdx)
            TriggerServerEvent(eventName .. "server:deleteFromCache", uniqueId)
        else
            TriggerServerEvent(eventName .. "server:deleteFromCache", uniqueId)
        end
    end

    -- ─── DestroyAllMyMusic() ─────────────────────────────────────────────────
    -- Stops all tracks belonging to the local player.

    function DestroyAllMyMusic()
        local mySource = GetPlayerServerId(PlayerId())
        local myTracks = {}

        for _, track in pairs(musicCache) do
            if track.playerSource == mySource then
                table.insert(myTracks, track.uniqueId)
            end
        end

        if #myTracks > 0 then
            for _, uid in ipairs(myTracks) do
                DestroyMusic(uid)
            end

            local now = GetGameTimer()
            if (now - lastStopAllTime) >= STOP_ALL_COOLDOWN then
                lastStopAllTime = now
                TriggerServerEvent(eventName .. "server:stopAllMyMusic")
            end
        end
    end

    -- ─── ForceStopAllHearingSounds() ─────────────────────────────────────────
    -- Immediately destroys all tracks in the local cache (regardless of owner)
    -- and clears the cache.

    function ForceStopAllHearingSounds()
        local destroyed = false

        for _, track in pairs(musicCache) do
            if track.uniqueId and XSound:soundExists(track.uniqueId) then
                XSound:Destroy(track.uniqueId)
                destroyed = true
            end
        end

        musicCache = {}

        if destroyed then
            local now = GetGameTimer()
            if (now - lastStopAllTime) >= STOP_ALL_COOLDOWN then
                lastStopAllTime = now
                TriggerServerEvent(eventName .. "server:stopAllMyMusic")
            end
        end
    end

    -- ─── Net Event: client:stopAllMyMusic ────────────────────────────────────
    RegisterNetEvent(eventName .. "client:stopAllMyMusic")
    AddEventHandler(eventName .. "client:stopAllMyMusic", function()
        DestroyAllMyMusic()
    end)

    -- ─── Event: onResourceStop ───────────────────────────────────────────────
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end
        for _, track in pairs(musicCache) do
            safeDestroyXSound(track.uniqueId)
        end
    end)

    -- ─── Net Event: client:deleteFromCache ───────────────────────────────────
    -- Server instructs this client to destroy and remove one specific track.

    RegisterNetEvent(eventName .. "client:deleteFromCache")
    AddEventHandler(eventName .. "client:deleteFromCache", function(uniqueId)
        safeDestroyXSound(uniqueId)

        local cacheIdx = nil
        for i, track in pairs(musicCache) do
            if track.uniqueId == uniqueId then
                cacheIdx = i
                break
            end
        end

        if type(cacheIdx) == "number" then
            table.remove(musicCache, cacheIdx)
        end
    end)

    -- ─── Net Event: client:updateCache ───────────────────────────────────────
    -- Server sends a full new cache + a list of stale entries to destroy.

    RegisterNetEvent(eventName .. "client:updateCache")
    AddEventHandler(eventName .. "client:updateCache", function(newCache, staleTracks)
        musicCache = newCache

        for _, track in pairs(staleTracks) do
            if track.uniqueId and XSound:soundExists(track.uniqueId) then
                XSound:Destroy(track.uniqueId)
            end
        end
    end)

    -- ─── Net Event: client:addToCache ────────────────────────────────────────
    -- Server tells this client to start playing a newly-added track.

    RegisterNetEvent(eventName .. "client:addToCache")
    AddEventHandler(eventName .. "client:addToCache", function(track)
        -- Validate required fields
        if not (track and track.uniqueId and track.url and track.pos) then return end

        if not XSound:soundExists(track.uniqueId) then
            -- Remove any duplicate entry
            for i, existing in pairs(musicCache) do
                if existing.uniqueId == track.uniqueId then
                    table.remove(musicCache, i)
                    break
                end
            end

            table.insert(musicCache, track)

            local volume = Main.settings.musicVolume / 100
            XSound:PlayUrlPos(track.uniqueId, track.url, volume, track.pos, true)
            XSound:setSoundDynamic(track.uniqueId, true)

            local maxDist = (Config.Music and Config.Music.MaxDistance) or 5.0
            XSound:Distance(track.uniqueId, maxDist)
        else
            -- Track already exists; just update its position
            XSound:Position(track.uniqueId, track.pos)
        end
    end)

    -- ─── Net Event: client:updateMusic ───────────────────────────────────────
    -- Server tells this client to restart a track with a new URL/position.

    RegisterNetEvent(eventName .. "client:updateMusic")
    AddEventHandler(eventName .. "client:updateMusic", function(track)
        if not (track and track.uniqueId and track.url and track.pos) then return end

        if XSound:soundExists(track.uniqueId) then
            XSound:Destroy(track.uniqueId)
        end

        local volume = Main.settings.musicVolume / 100
        XSound:PlayUrlPos(track.uniqueId, track.url, volume, track.pos, true)
        XSound:setSoundDynamic(track.uniqueId, true)

        local dist = Config.CustomDistanceForVehicles
            or Config.DistancePlaying
            or 25.0
        XSound:Distance(track.uniqueId, dist)
    end)

    -- ─── Thread: position sync ────────────────────────────────────────────────
    -- Every 250 ms, update each track's position to follow its owner.
    -- If two tracks from different players are within 5m of each other, mute
    -- the older one to avoid audio overlap.

    CreateThread(function()
        while true do
            Wait(250)

            -- Build an "active" map: uniqueId → entry (only for tracks currently playing)
            local activeTracks = {}

            for _, track in pairs(musicCache) do
                if track and track.playerSource and track.uniqueId then
                    if XSound:soundExists(track.uniqueId) then
                        local player = GetPlayerFromServerId(track.playerSource)
                        if player and player ~= 0 then
                            local ped = GetPlayerPed(player)
                            if DoesEntityExist(ped) then
                                local coords = GetEntityCoords(ped)
                                XSound:Position(track.uniqueId, coords)
                                activeTracks[track.uniqueId] = { entry = track, pos = coords }
                            end
                        end
                    end
                end
            end

            -- Volume ducking: if two tracks are within 5m of each other, mute
            -- the one whose player joined earlier (lower .created time = older).
            for uid1, data1 in pairs(activeTracks) do
                local shouldMute = false

                for uid2, data2 in pairs(activeTracks) do
                    if uid1 ~= uid2 then
                        local dist = #(data1.pos - data2.pos)
                        if dist <= 5.0 then
                            if data1.entry.created and data2.entry.created then
                                if data1.entry.created < data2.entry.created then
                                    shouldMute = true
                                    break
                                end
                            end
                        end
                    end
                end

                if XSound:soundExists(uid1) then
                    if shouldMute then
                        XSound:setVolumeMax(uid1, 0.0)
                    else
                        XSound:setVolumeMax(uid1, Main.settings.musicVolume / 100)
                    end
                end
            end
        end
    end)

-- =============================================================================
-- SERVER SIDE
-- =============================================================================

else

    -- Server-side music cache: array of track entries
    local serverMusicCache   = {}
    local lastBroadcastTime  = 0
    local BROADCAST_COOLDOWN = 1000
    local BROADCAST_RADIUS   = 150.0

    -- ── Server tick: increment .time on all entries every second ─────────────
    local function serverTick()
        SetTimeout(1000, serverTick)
        for _, track in pairs(serverMusicCache) do
            if track then
                track.time = (track.time or 0) + 1
            end
        end
    end
    SetTimeout(1000, serverTick)

    -- ── getPlayersNearPos(pos, radius) ────────────────────────────────────────
    -- Returns an array of player IDs whose ped is within `radius` of `pos`.

    local function getPlayersNearPos(pos, radius)
        local result = {}
        if not pos or type(pos) ~= "vector3" then return result end

        for _, playerId in ipairs(GetPlayers()) do
            local ped = GetPlayerPed(playerId)
            if ped and ped ~= 0 and DoesEntityExist(ped) then
                local dist = #(pos - GetEntityCoords(ped))
                if radius >= dist then
                    table.insert(result, playerId)
                end
                Wait(0)
            end
        end

        return result
    end

    -- ── broadcastToNearby(event, pos, radius, ...) ────────────────────────────
    -- Fires `event` on every player within `radius` of `pos`, passing `...`.
    -- Also tracks which uniqueIds each player is hearing via their state bag.

    local function broadcastToNearby(event, pos, radius, ...)
        local args     = { ... }
        local nearPlayers = getPlayersNearPos(pos, radius)

        for _, playerId in ipairs(nearPlayers) do
            TriggerClientEvent(event, playerId, ...)

            -- Update hearingSounds state bag
            local playerState  = Player(playerId).state
            local hearingSounds = playerState.hearingSounds or {}
            local uniqueId     = nil

            if event == eventName .. "client:addToCache"
            or event == eventName .. "client:updateMusic" then
                if type(args[1]) == "table" and args[1].uniqueId then
                    uniqueId = args[1].uniqueId
                    hearingSounds[uniqueId] = true
                end
            elseif event == eventName .. "client:deleteFromCache" then
                uniqueId = args[1]
                if uniqueId then
                    hearingSounds[uniqueId] = nil
                end
            end

            if uniqueId then
                Player(playerId).state.hearingSounds = hearingSounds
            end

            Wait(0)
        end
    end

    -- ─── Server Event: server:addToCache ─────────────────────────────────────
    -- Client requests to add a new music track. Server finds the player's
    -- position, stores the entry, and broadcasts to nearby players.

    RegisterServerEvent(eventName .. "server:addToCache")
    AddEventHandler(eventName .. "server:addToCache", function(track)
        if not (track and track.uniqueId and track.playerSource) then return end

        local playerId  = source
        local playerPed = GetPlayerPed(playerId)
        if not DoesEntityExist(playerPed) then return end

        local coords = GetEntityCoords(playerPed)
        track.pos     = coords
        track.created = os.time()

        -- Check if this player already has an entry (update) or is new (insert)
        local existingIdx = nil
        for i, entry in pairs(serverMusicCache) do
            if entry and entry.playerSource == playerId then
                existingIdx = i
                break
            end
        end

        if not existingIdx then
            -- New entry: broadcast addToCache to nearby players
            table.insert(serverMusicCache, track)
            broadcastToNearby(
                eventName .. "client:addToCache",
                track.pos, BROADCAST_RADIUS, track
            )
        else
            -- Existing entry: update in place and broadcast updateMusic
            serverMusicCache[existingIdx].pos  = coords
            serverMusicCache[existingIdx].url  = track.url
            serverMusicCache[existingIdx].time = 0

            local updatedTrack = serverMusicCache[existingIdx]
            broadcastToNearby(
                eventName .. "client:updateMusic",
                updatedTrack.pos, BROADCAST_RADIUS, updatedTrack
            )
        end
    end)

    -- ─── Server Event: server:deleteFromCache ────────────────────────────────
    -- Client requests to remove a track. Server broadcasts deleteFromCache to
    -- all nearby players and removes the entry from the server cache.

    RegisterServerEvent(eventName .. "server:deleteFromCache")
    AddEventHandler(eventName .. "server:deleteFromCache", function(uniqueId)
        if not uniqueId then return end

        local entry    = nil
        local entryIdx = nil

        for i, track in pairs(serverMusicCache) do
            if track and track.uniqueId == uniqueId then
                entry    = track
                entryIdx = i
                break
            end
        end

        if entry and entryIdx then
            -- Notify all players currently hearing this track
            for _, playerId in ipairs(GetPlayers()) do
                local hearingSounds = Player(playerId).state.hearingSounds or {}
                if hearingSounds[uniqueId] then
                    TriggerClientEvent(eventName .. "client:deleteFromCache", playerId, uniqueId)
                    hearingSounds[uniqueId] = nil
                    Player(playerId).state.hearingSounds = hearingSounds
                end
            end

            -- Broadcast to all players within range of the track's last position
            broadcastToNearby(
                eventName .. "client:deleteFromCache",
                entry.pos, BROADCAST_RADIUS, uniqueId
            )

            table.remove(serverMusicCache, entryIdx)
        end
    end)

    -- ─── Server Event: server:stopAllMyMusic ─────────────────────────────────
    -- Stops all tracks belonging to the requesting player and notifies
    -- all nearby clients.

    RegisterServerEvent(eventName .. "server:stopAllMyMusic")
    AddEventHandler(eventName .. "server:stopAllMyMusic", function()
        local playerId  = source
        local toRemove  = {}

        -- Collect and remove entries belonging to this player (reverse order)
        for i = #serverMusicCache, 1, -1 do
            local track = serverMusicCache[i]
            if track and track.playerSource == playerId then
                table.insert(toRemove, track)
                table.remove(serverMusicCache, i)
            end
        end

        -- For each removed entry, notify all hearers and nearby players
        for _, track in ipairs(toRemove) do
            if track.uniqueId then
                for _, pid in ipairs(GetPlayers()) do
                    local hearingSounds = Player(pid).state.hearingSounds or {}
                    if hearingSounds[track.uniqueId] then
                        TriggerClientEvent(eventName .. "client:deleteFromCache", pid, track.uniqueId)
                        hearingSounds[track.uniqueId] = nil
                        Player(pid).state.hearingSounds = hearingSounds
                    end
                end

                if track.pos then
                    broadcastToNearby(
                        eventName .. "client:deleteFromCache",
                        track.pos, BROADCAST_RADIUS, track.uniqueId
                    )
                end
            end

            Wait(0)
        end
    end)

    -- ─── Server Event: server:playerLoaded ───────────────────────────────────
    -- When a player spawns, send them all music currently playing within range.

    RegisterServerEvent(eventName .. "server:playerLoaded")
    AddEventHandler(eventName .. "server:playerLoaded", function()
        local playerId  = source
        local playerPed = GetPlayerPed(playerId)

        if not (playerPed and playerPed ~= 0 and DoesEntityExist(playerPed)) then
            -- Ped not ready yet: clear their hearing state
            Player(playerId).state.hearingSounds = {}
            return
        end

        local playerCoords  = GetEntityCoords(playerPed)
        local tracksToSend  = {}
        local hearingMap    = {}

        for _, track in pairs(serverMusicCache) do
            if track and type(track.pos) == "vector3" then
                local dist = #(playerCoords - track.pos)
                if dist <= BROADCAST_RADIUS then
                    hearingMap[track.uniqueId] = true
                    table.insert(tracksToSend, track)
                end
            end
            Wait(0)
        end

        Player(playerId).state.hearingSounds = hearingMap

        for _, track in ipairs(tracksToSend) do
            TriggerClientEvent(eventName .. "client:addToCache", playerId, track)
            Wait(0)
        end
    end)

    -- ─── Event: playerDropped ─────────────────────────────────────────────────
    -- When a player disconnects, remove their tracks and notify nearby clients.

    AddEventHandler("playerDropped", function()
        local playerId = source
        local dropped  = {}

        for i = #serverMusicCache, 1, -1 do
            local track = serverMusicCache[i]
            if track and track.playerSource == playerId then
                table.insert(dropped, track)
                table.remove(serverMusicCache, i)
            end
        end

        for _, track in ipairs(dropped) do
            if track.pos and track.uniqueId then
                broadcastToNearby(
                    eventName .. "client:deleteFromCache",
                    track.pos, BROADCAST_RADIUS, track.uniqueId
                )
            end
            Wait(0)
        end
    end)

    -- ─── Periodic cleanup: remove stale entries from disconnected players ─────
    -- Runs every 60 s; removes any entry whose owning player no longer has a
    -- live ped, then broadcasts deleteFromCache to nearby players.

    local function cleanupStaleEntries()
        SetTimeout(60000, cleanupStaleEntries)

        local stale = {}

        for _, track in pairs(serverMusicCache) do
            if track and track.playerSource then
                local ped = GetPlayerPed(track.playerSource)
                local isAlive = ped and ped ~= 0 and DoesEntityExist(ped)
                if not isAlive then
                    table.insert(stale, { entry = track })
                end
            end
        end

        if #stale > 0 then
            -- Sort by cache index descending so table.remove stays valid
            table.sort(stale, function(a, b) return a.entry > b.entry end)

            for _, item in ipairs(stale) do
                local track = item.entry
                if track and track.uniqueId and track.pos then
                    broadcastToNearby(
                        eventName .. "client:deleteFromCache",
                        track.pos, BROADCAST_RADIUS, track.uniqueId
                    )
                    -- Remove from serverMusicCache
                    for i = #serverMusicCache, 1, -1 do
                        if serverMusicCache[i] == track then
                            table.remove(serverMusicCache, i)
                            break
                        end
                    end
                elseif item.entry then
                    -- No pos — just remove by index if we can find it
                    for i = #serverMusicCache, 1, -1 do
                        if serverMusicCache[i] == track then
                            table.remove(serverMusicCache, i)
                            break
                        end
                    end
                end

                Wait(0)
            end
        end
    end
    SetTimeout(60000, cleanupStaleEntries)

end -- isServer