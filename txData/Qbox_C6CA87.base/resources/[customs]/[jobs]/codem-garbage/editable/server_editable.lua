bot_Token = ""
bot_logo = "https://cdn.discordapp.com/attachments/1025789416456867961/1106324039808594011/512x512_Logo.png"
bot_name = "Codem Store"


discord_webhook = {
    ['jobfinish'] = "",
}

local playerKeys = {}
local usedNonces = {}

-- Server-Side Session Tracking Architecture
local activeGarbageSessions = {}

local function HasGarbageJob(playerId)
    if not Config.GarbagejobSettings or Config.GarbagejobSettings['job'] == 'all' then return true end
    local Player = GetPlayer(playerId)
    if not Player then return false end
    if Config.Framework == 'esx' or Config.Framework == 'oldesx' then
        return Player.job and Player.job.name == Config.GarbagejobSettings['job']
    else
        return Player.PlayerData and Player.PlayerData.job and Player.PlayerData.job.name == Config.GarbagejobSettings['job']
    end
end

-- Server-authoritative singleplayer session initialization
RegisterServerEvent('codem-garbagejob:server:startJobSingleplayer', function(routeName, truckNetId)
    local src = source
    if not HasGarbageJob(src) then
        print("[GARBAGE SECURITY] Unauthorized startJobSingleplayer from source " .. tostring(src))
        return
    end

    local routeStops = Config.GarbagejobSettings['garbageStop'] and Config.GarbagejobSettings['garbageStop'][routeName]
    if not routeStops then
        print("[GARBAGE SECURITY] Invalid routeName in startJobSingleplayer: " .. tostring(routeName))
        return
    end

    local totalBags = 0
    for _, stop in pairs(routeStops) do
        totalBags = totalBags + (tonumber(stop.garbageCount) or 1)
    end

    activeGarbageSessions[src] = {
        state = "EN_ROUTE",
        route = routeName,
        truckNetId = truckNetId,
        startTime = GetGameTimer(),
        currentStopIndex = 1,
        verifiedBags = 0,
        totalExpectedBags = totalBags,
        stopsCompleted = false,
        totalStops = #routeStops,
    }
end)

-- Server-authoritative stop progression & distance validation
RegisterServerEvent('codem-garbagejob:server:completeStop', function(stopIndex)
    local src = source
    local session = activeGarbageSessions[src]
    if not session or session.state ~= "EN_ROUTE" then
        return
    end

    stopIndex = tonumber(stopIndex) or 0
    if stopIndex ~= session.currentStopIndex then
        print(string.format("[GARBAGE SECURITY] Player %s stopIndex mismatch: expected %d, got %d", src, session.currentStopIndex, stopIndex))
        return
    end

    local routeStops = Config.GarbagejobSettings['garbageStop'][session.route]
    if not routeStops or not routeStops[stopIndex] then
        return
    end

    local stopData = routeStops[stopIndex]
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)
    local dist = #(coords - stopData.coords)
    if dist > 35.0 then
        print(string.format("[GARBAGE SECURITY] Player %s too far from stop coords (%.1fm > 35m)", src, dist))
        return
    end

        local bagCount = tonumber(stopData.garbageCount) or 1
    local minStopDuration = math.max(4, bagCount * 2)
    local lastTime = session.lastStopTimer or session.startTime
    local elapsed = (GetGameTimer() - lastTime) / 1000.0
    if elapsed < minStopDuration then
        print(string.format("[GARBAGE SECURITY] Player %s stop completed too fast: %.1fs < %ds", src, elapsed, minStopDuration))
        return
    end
    session.lastStopTimer = GetGameTimer()

    session.verifiedBags = session.verifiedBags + bagCount
    session.currentStopIndex = session.currentStopIndex + 1

    if session.currentStopIndex > session.totalStops then
        session.stopsCompleted = true
    end
end)


Citizen.CreateThread(function()
    Citizen.Wait(1000)
    while Core == nil do
        Citizen.Wait(0)
    end
    RegisterCallback('codem-garbage:getKey', function(source, cb)
        if not playerKeys[source] then
            playerKeys[source] = "CODEM" ..
                math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. os.time()
        end
        cb(playerKeys[source])
    end)
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    activeGarbageSessions[src] = nil
    leaveLobbyorDeleteLobby(src)
end)

RegisterServerEvent('codem-garbage:resetjob', function(garbageJobData)
    local src = source
    local clientIdentifier = GetIdentifier(src)
    local data = playerJobData[clientIdentifier]
    if not data then
        return
    end
    local roomname = false
    for k, v in pairs(coopData) do
        local players = v.players
        for _, player in pairs(players) do
            if player.src == src then
                roomname = v.roomData.hostIdentifier
            end
        end
    end
    if roomname == nil then
        return
    end
    local room = coopData[roomname]
    if not room then
        return
    end
    local players = room.players
    for _, player in pairs(players) do
        if tonumber(player.src) == tonumber(src) then
            if player.host then
                for __, playerId in pairs(players) do
                    if tonumber(playerId.src) then
                        TriggerClientEvent('codem-garbage:deleteRoom', tonumber(playerId.src), roomname)
                    end
                end
                coopData[roomname] = nil
                Citizen.Wait(150)
                TriggerClientEvent('codem-garbage:deleteroomeveryone', -1, roomname)
                TriggerClientEvent('codem-garbage:client:ResetJob', tonumber(src), garbageJobData)
            else
                table.remove(players, _)
                coopData[roomname].players = players
                for __, playerId in pairs(players) do
                    if tonumber(playerId.src) ~= tonumber(src) then
                        TriggerClientEvent('codem-garbage:updateClientRoomPlayersData', -1, roomname,
                            coopData[roomname].players)
                    end
                end
                TriggerClientEvent('codem-garbage:deleteMyTeam', src, roomname, src)
            end
        else
            TriggerClientEvent('codem-garbage:client:ResetJob', tonumber(player.src), garbageJobData)
        end
    end
    savePlayerData(src)
    playerKeys[src] = "CODEM" ..
        math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. os.time()
end)


function leaveLobbyorDeleteLobby(src)
    local clientIdentifier = GetIdentifier(src)
    local data = playerJobData[clientIdentifier]
    if not data then
        return
    end
    local roomname = false
    for k, v in pairs(coopData) do
        local players = v.players
        for _, player in pairs(players) do
            if player.src == src then
                roomname = v.roomData.hostIdentifier
            end
        end
    end
    if roomname == nil then
        return
    end
    local room = coopData[roomname]
    if not room then
        return
    end
    local players = room.players
    for _, player in pairs(players) do
        if tonumber(player.src) == tonumber(src) then
            if player.host then
                for __, playerId in pairs(players) do
                    if tonumber(playerId.src) then
                        TriggerClientEvent('codem-garbage:deleteRoom', tonumber(playerId.src),
                            roomname)
                    end
                end
                coopData[roomname] = nil
                Citizen.Wait(150)
                TriggerClientEvent('codem-garbage:deleteroomeveryone', -1, roomname)
            else
                table.remove(players, _)
                coopData[roomname].players = players
                for __, playerId in pairs(players) do
                    if tonumber(playerId.src) ~= tonumber(src) then
                        TriggerClientEvent('codem-garbage:updateClientRoomPlayersData', -1, roomname,
                            coopData[roomname].players)
                    end
                end
                TriggerClientEvent('codem-garbage:deleteMyTeam', src, roomname, src)
            end
        end
    end
    savePlayerData(src)
    playerKeys[src] = "CODEM" ..
        math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. os.time()
end

RegisterServerEvent('codem-garbage:finishMultiplayerJobs', function()
    local src = source
    local identifier = GetIdentifier(src)
    local data = playerJobData[GetIdentifier(src)]
    if not data then
        return
    end
    local room = coopData[identifier]
    if not room then
        print('room not found')
        return
    end
    local players = room.players

    for _, player in pairs(players) do
        if player.src then
            leaveLobbyorDeleteLobby(player.src)
            TriggerClientEvent('codem-garbage:client:finishMultiplayerJob', tonumber(player.src))
        end
    end
    Citizen.Wait(2500)
    if coopData[identifier] then
        coopData[identifier] = nil
        TriggerClientEvent('codem-garbage:deleteroomeveryone', -1, identifier)
    end
end)

RegisterServerEvent('codem-garbage:deliveryVehicleForDriver', function()
    local src = source
    local data = playerJobData[GetIdentifier(src)]
    if not data then
        return
    end
    local roomname = nil
    for k, v in pairs(coopData) do
        local players = v.players
        for _, player in pairs(players) do
            if player.src == src then
                roomname = v.roomData.hostIdentifier
            end
        end
    end
    local roomData = coopData[roomname]
    if roomData then
        local players = roomData.players
        for _, player in pairs(players) do
            if player.src then
                if player.host then
                    TriggerClientEvent('codem-garbage:finishIsDriver', tonumber(player.src))
                end
            end
        end
    end
end)

RegisterServerEvent('codem-garbage:deleteBlip', function(blip)
    local src = source
    local data = playerJobData[GetIdentifier(src)]
    if not data then
        return
    end
    local roomname = nil
    for k, v in pairs(coopData) do
        local players = v.players
        for _, player in pairs(players) do
            if player.src == src then
                roomname = v.roomData.hostIdentifier
            end
        end
    end
    local roomData = coopData[roomname]
    if roomData then
        local players = roomData.players
        for _, player in pairs(players) do
            if player.src then
                TriggerClientEvent('codem-garbage:deleteBlip', tonumber(player.src), blip)
            end
        end
    end
end)




RegisterServerEvent('codem-garbagejob:finishJob', function(clientkey, money, gatheredcount, stopname, multivalue)
    local src = source

    -- Validate Nonce / Security Token
    if playerKeys[src] ~= clientkey or usedNonces[clientkey] then
        print(string.format("[GARBAGE SECURITY] Invalid key/nonce trigger from source %s", tostring(src)))
        return
    end

    if not HasGarbageJob(src) then
        print(string.format("[GARBAGE SECURITY] Unauthorized job attempt from source %s", tostring(src)))
        return
    end

    -- Verify vehicle entity and delivery location
    local ped = GetPlayerPed(src)
    local veh = GetVehiclePedIsIn(ped, false)
    local vehModel = GetEntityModel(veh)
    local trashHash = joaat(Config.GarbagejobSettings['trashvehicle'] or 'trash2')
    local trash1Hash = joaat('trash')
    local trash2Hash = joaat('trash2')
    if vehModel ~= trashHash and vehModel ~= trash1Hash and vehModel ~= trash2Hash then
        print(string.format("[GARBAGE SECURITY] Player %s not in garbage vehicle", tostring(src)))
        return
    end

    local coords = GetEntityCoords(ped)
    local deliverCoords = Config.GarbagejobSettings['jobDeliverTheVehicleCoords']
    local distToDepot = #(coords - deliverCoords)
    if distToDepot > 35.0 then
        print(string.format("[GARBAGE SECURITY] Player %s too far from delivery depot (%.1fm > 35m)", tostring(src), distToDepot))
        return
    end

    local routeStops = Config.GarbagejobSettings['garbageStop'][stopname]
    if not routeStops then
        print(string.format("[GARBAGE SECURITY] Invalid stopname %s from source %s", tostring(stopname), tostring(src)))
        return
    end

    local serverTotalBags = 0
    for _, stop in pairs(routeStops) do
        serverTotalBags = serverTotalBags + (tonumber(stop.garbageCount) or 1)
    end

    -- Singleplayer Verification
    local session = activeGarbageSessions[src]
    if not multivalue then
        if not session then
            print(string.format("[GARBAGE SECURITY] Singleplayer finishJob without active session for source %s", tostring(src)))
            return
        end

        if session.state == "PAYING" or session.state == "PAID" then
            print(string.format("[GARBAGE SECURITY] Player %s already in paying/paid state", tostring(src)))
            return
        end

        if session.route ~= stopname then
            print(string.format("[GARBAGE SECURITY] Route mismatch for source %s: session=%s, sent=%s", tostring(src), tostring(session.route), tostring(stopname)))
            return
        end

        if not session.stopsCompleted or session.verifiedBags < serverTotalBags then
            print(string.format("[GARBAGE SECURITY] Stops incomplete for source %s: verifiedBags=%d < total=%d", tostring(src), session.verifiedBags, serverTotalBags))
            return
        end

        local minDuration = math.max(60, session.totalStops * 15)
        local elapsed = (GetGameTimer() - session.startTime) / 1000.0
        if elapsed < minDuration then
            print(string.format("[GARBAGE SECURITY] Transit too fast for source %s: elapsed %.1fs < min %ds", tostring(src), elapsed, minDuration))
            return
        end

        session.state = "PAYING"
    end

    -- Consume Nonce after all validation checks succeed
    usedNonces[clientkey] = true

    -- AUTHORITATIVE SERVER PAYOUT CALCULATION:
    -- Complete disregard of client-supplied 'money'!
    local bagRate = 75
    local authoritativePayout = serverTotalBags * bagRate
    if multivalue then
        authoritativePayout = math.floor(authoritativePayout * 1.5)
    end

    local routeConfig = nil
    for _, r in pairs(Config.GarbagejobSettings['garbageRouteSettings']) do
        if r.name == stopname then
            routeConfig = r
            break
        end
    end
    local xpAwarded = routeConfig and routeConfig.xp or 500
    if multivalue then
        xpAwarded = xpAwarded * 2
    end

    local data = playerJobData[GetIdentifier(src)]
    if not data then return end

    local paymentSuccess = AddMoney(src, 'cash', authoritativePayout)

    if paymentSuccess then
        if session then
            session.state = "PAID"
            activeGarbageSessions[src] = nil
        end

        AddXPGarbabgeJob(src, tonumber(xpAwarded))
        data.profiledata.completejobs = data.profiledata.completejobs + 1
        data.profiledata.totalearnings = data.profiledata.totalearnings + authoritativePayout
        data.profiledata.gathered = data.profiledata.gathered + serverTotalBags

        local historyData = {
            ['routename'] = routeConfig and routeConfig.label or stopname,
            ['gathered'] = serverTotalBags,
            ['money'] = authoritativePayout,
            ['time'] = os.date("%m-%d-%Y %H:%M")
        }
        table.insert(data.historydata, historyData)

        local function updateDailyMission(missionType, increment)
            for _, missionConfig in pairs(Config.GarbagejobSettings['dailyMission']) do
                if missionConfig.name == missionType and not data.dailymission[missionType].complete then
                    data.dailymission[missionType].count = data.dailymission[missionType].count + increment
                    if data.dailymission[missionType].count >= missionConfig.count then
                        data.dailymission[missionType].complete = true
                        AddXPGarbabgeJob(src, tonumber(missionConfig.xp))
                        Config.Notification(
                            string.format(Config.NotificationText['completedailymission'].text, missionConfig.xp),
                            Config.NotificationText['completedailymission'].type, true, src)
                    end
                end
            end
        end

        for missionType, _ in pairs(data.dailymission) do
            if missionType == 'transportpassenger' then
                updateDailyMission(missionType, serverTotalBags)
            elseif missionType == 'completeoneroute' then
                updateDailyMission(missionType, 1)
            elseif missionType == 'earninoneroute' then
                updateDailyMission(missionType, authoritativePayout)
            end
        end

        savePlayerData(src)
    else
        print(string.format("[GARBAGE SECURITY] AddMoney failed for source %s, reverting state", tostring(src)))
        if session then
            session.state = "EN_ROUTE"
        end
    end

    playerKeys[src] = "CODEM" ..
        math.random(10000, 999999999) .. "saas" .. math.random(10000, 999999999) .. os.time()
end)

function discordloghistoryData(source, data)
    local src = source
    local identifier = GetIdentifier(src)
    local dataInfo = {
        identifier = identifier,
        avatar = GetDiscordAvatar(src) or Config.ExampleProfilePicture,
        name = GetName(src),
        id = src,
        routename = data.routename,
        abbreviation = data.abbreviation,
        gathered = data.gathered,
        passenger = data.passenger,
        money = data.money,
    }
    return dataInfo
end

function sendDiscordLogHistory(data)
    local message = {
        username = bot_name,
        embeds = {
            {
                title = botname,
                color = 0xFFA500,
                author = {
                    name = 'Codem GARBAGE - JOB FINISH',
                },
                thumbnail = {
                    url = data.avatar
                },
                fields = {
                    { name = "Player Name", value = data.name or false, inline = true },
                    { name = "Player ID",   value = data.id or false,   inline = true },
                    {
                        name = "──────────Job Information──────────",
                        value = "",
                        inline = false
                    },
                    { name = "Route Name", value = data.routename or false,                inline = true },
                    { name = "Gathered",   value = tonumber(data.gathered) or 'undefined', inline = true },
                    { name = "Job Price",  value = tonumber(data.money) or 'undefined',    inline = true },

                },
                footer = {
                    text = "Codem Store - https://discord.gg/zj3QsUfxWs",
                    icon_url =
                    "https://cdn.discordapp.com/attachments/1025789416456867961/1106324039808594011/512x512_Logo.png"
                },

                timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
            }
        },
        avatar_url = bot_logo
    }

    PerformHttpRequest(discord_webhook['jobfinish'], function(err, text, headers) end,
        "POST",
        json.encode(message),
        { ["Content-Type"] = "application/json" })
end
