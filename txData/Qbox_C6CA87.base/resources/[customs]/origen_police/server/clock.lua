-- Duty Clock System - Track officer work hours
local clockInTimes = {}

-- Clock in when officer goes on duty
RegisterServerEvent("origen_police:server:ClockIn", function()
    local player = FW_GetPlayer(source)
    
    if player and player.PlayerData then
        local citizenId = player.PlayerData.citizenid
        
        if not clockInTimes[citizenId] then
            -- Set clock in time (minus 60 seconds for initialization)
            clockInTimes[citizenId] = os.time() - 60
        end
    end
end)

-- Clock out when officer goes off duty
RegisterServerEvent("origen_police:server:ClockOut", function()
    local player = FW_GetPlayer(source)
    
    if player and player.PlayerData then
        local citizenId = player.PlayerData.citizenid
        
        if clockInTimes[citizenId] then
            local badgeNumber = player.PlayerData.metadata.police_badge or "0000"
            local fullName = player.PlayerData.charinfo.firstname .. " " .. 
                           player.PlayerData.charinfo.lastname .. " (" .. 
                           badgeNumber .. ")"
            
            ClockOut(
                citizenId,
                fullName,
                player.PlayerData.job.name,
                player.PlayerData.source
            )
        end
    end
end)

-- Process clock out and save to database
function ClockOut(citizenId, fullName, jobName, source)
    if not citizenId or not fullName or not clockInTimes[citizenId] then
        return
    end
    
    local clockInTime = clockInTimes[citizenId]
    local clockOutTime = os.time()
    local minutesWorked = math.ceil((clockOutTime - clockInTime) / 60)
    
    -- Create log
    CreateLog({
        type = "DutyClock",
        embed = {
            title = Config.LogsTranslations.ClockOut.title,
            description = Config.LogsTranslations.ClockOut.message:format(
                os.date("%d/%m/%Y - %H:%M", clockInTime),
                os.date("%d/%m/%Y - %H:%M"),
                minutesWorked
            ),
            color = 1791423
        },
        source = source
    })
    
    -- Save to database
    MySQL.awaitInsert(
        "INSERT INTO origen_police_clocks (citizenid, name, clockin, clockout, minutes, job) VALUES (@citizenid, @name, @clockin, @clockout, @minutes, @job)",
        {
            ["@citizenid"] = citizenId,
            ["@name"] = fullName,
            ["@clockin"] = os.date("%d/%m/%Y - %H:%M", clockInTime),
            ["@clockout"] = os.date("%d/%m/%Y - %H:%M"),
            ["@minutes"] = minutesWorked,
            ["@job"] = jobName
        }
    )
    
    clockInTimes[citizenId] = nil
end

-- Auto clock out when player disconnects
AddEventHandler("playerDropped", function()
    local player = FW_GetPlayer(source)
    
    if player and player.PlayerData and player.PlayerData.citizenid then
        if clockInTimes[player.PlayerData.citizenid] then
            local badgeNumber = player.PlayerData.metadata.police_badge or "0000"
            local fullName = player.PlayerData.charinfo.firstname .. " " .. 
                           player.PlayerData.charinfo.lastname .. " (" .. 
                           badgeNumber .. ")"
            
            ClockOut(
                player.PlayerData.citizenid,
                fullName,
                player.PlayerData.job.name,
                source
            )
        end
    end
end)

-- Get clock history with caching
local clockCache = {}

FW_CreateCallback("origen_police:server:GetClocks", function(source, callback)
    local player = FW_GetPlayer(source)
    local jobName = Config.PoliceJobName
    
    if player and player.PlayerData and player.PlayerData.job then
        jobName = player.PlayerData.job.name
    end
    
    -- Get recent clock records
    local clockData = MySQL.awaitQuery(
        "SELECT * FROM origen_police_clocks WHERE job = ? ORDER BY id DESC LIMIT 200",
        {jobName}
    )
    
    -- Check cache (valid for 30 seconds)
    if clockCache[jobName] and clockCache[jobName].time + 30 > os.time() then
        callback({
            data = clockData,
            top = clockCache[jobName].data
        })
        return
    end
    
    -- Get top 10 officers by total minutes
    local topOfficers = MySQL.awaitQuery(
        "SELECT name, SUM(minutes) AS total_minutes FROM origen_police_clocks WHERE job = ? GROUP BY citizenid ORDER BY total_minutes DESC LIMIT 10",
        {jobName}
    )
    
    -- Update cache
    clockCache[jobName] = {
        time = os.time(),
        data = topOfficers
    }
    
    callback({
        data = clockData,
        top = topOfficers
    })
end)