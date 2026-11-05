RegisterServerEvent('codem-taxijob:Pay')
AddEventHandler('codem-taxijob:Pay', function(amount, xp, clientkey, header)
    local src = source
    if clientkey ~= key then
        print('Player '..src.. ' tried to execute pay trigger')
        return
    end
    if fares[src] ~= amount then
        print('Player '..src.. ' tried to execute pay trigger with wrong amount')
        return
    end
    fares[src] = nil
    local jobData = GetPlayerJobData(src)
    AddMoney(src, amount)
    if jobData then
        jobData.totalEarnings = jobData.totalEarnings + amount
        jobData.completedJobs = jobData.completedJobs + 1
        AddXP(src, xp)
        AddToHistory(src, header, locales.npc, amount, xp)
        ExecuteSql("UPDATE codem_taxijob2 SET `totalEarnings` = '" ..
        jobData.totalEarnings .. "', `completedJobs` = '" ..
        jobData.completedJobs .. "' WHERE `identifier` = '" .. jobData.identifier .. "'")
        SyncPlayerDataByKey(src, "totalEarnings", jobData.totalEarnings)
        SyncPlayerDataByKey(src, "completedJobs", jobData.completedJobs)
    end
end)