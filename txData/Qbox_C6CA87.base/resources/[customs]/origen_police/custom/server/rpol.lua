RegisterServerEvent("origen_police:server:rpol", function(job, message)
    if Config.Framework ~= "qbcore" and Config.Framework ~= "esx" then return print("Can't find supported framework: ", Config.Framework) end
    local jobCategory = CanOpenTablet(source)[2]
    local Players = Config.Framework == "qbcore" and Framework.Functions.GetPlayersOnDuty(job) or GetPlayersInDuty(jobCategory)
    local CentralSuscribers = exports["origen_police"]:GetCentralSuscribeds()
    for _, v in pairs(Players) do
        if CentralSuscribers[v] then
            TriggerClientEvent('origen_police:client:rpol', v, message)
        end
        local data = {}
        if GetResourceState("origen_chat") == "started" then
            local header, body = message:match("^(.-)%s%s(.+)$")
            header = header:gsub("^%^%d+", "")
            local jobColor = "#344feb"
            for k, v in pairs(Config.JobCategory[jobCategory]) do
                if v.name == job then
                    jobColor = v.color
                    break
                end
            end
            data = {
                icon = 'material-symbols:local-police',
                title = header,
                barColor = jobColor,
                args = {body}
            }
        else -- Default chat
            data = {
                args = {message}
            }
        end
        TriggerClientEvent('chat:addMessage', v, data)
    end
end)