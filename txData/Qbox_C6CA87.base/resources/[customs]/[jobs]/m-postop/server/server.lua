frameworkObject = nil
cooldowns = {}

Citizen.CreateThread(function()
    frameworkObject = GetFrameworkObject()
    CDM.PlayerPostOPData = {}
    CDM.LeaderBoard = {}
    CDM.UpdateSQLData("get")
    CDM.BadgeData = {}
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1800000)
        for identifier, data in pairs(CDM.PlayerPostOPData) do
            CDM.UpdateSQLData("update", identifier)
        end
    end
end)

RegisterServerEvent("m-postop-server:Job")
AddEventHandler("m-postop-server:Job", function(action)
    local source = source
    local player = CDM.GetPlayer(source)
    local useJob = CDM.Config.UseJob or false
    
    if useJob then
        local jobName = CDM.Config.JobName
        local playerJob = CDM.GetPlayerJob(source)
        if jobName ~= playerJob then
            return CDM.SendMessage(CDM.Messages.server.notjob, true, "server", source)
        end
    end
    
    if action == "start" then
        if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
            local citizenid = player.PlayerData.citizenid
            
            if CDM.PlayerPostOPData[citizenid] == nil then
                CDM.PlayerPostOPData[citizenid] = {}
                CDM.PlayerPostOPData[citizenid].xp = 0
                CDM.PlayerPostOPData[citizenid].level = CDM.GetLevelFromXP(0)
                CDM.PlayerPostOPData[citizenid].class = CDM.GetClassFromLevel(CDM.PlayerPostOPData[citizenid].level)
                CDM.PlayerPostOPData[citizenid].name = CDM.GetPlayerCharacterName(source)
                CDM.PlayerPostOPData[citizenid].statistics = {completedworks = 0, earned = 0}
                CDM.PlayerPostOPData[citizenid].DailyMissions = {
                    firstcargo = {bool = false},
                    DeliverCargo = {amount = 0, bool = false},
                    endofWork = {bool = false},
                    time = os.time()
                }
                CDM.PlayerPostOPData[citizenid].lastjobs = {}
                
                table.insert(CDM.LeaderBoard, {
                    level = 1,
                    identifier = citizenid,
                    name = CDM.PlayerPostOPData[citizenid].name
                })
            end
            
            CDM.BoardArrangement()
            CDM.UpdateLevel(citizenid)
            
            if CDM.PlayerPostOPData[citizenid].DailyMissions then
                TriggerClientEvent("m-postop-client:OpenNui", source, 
                    CDM.PlayerPostOPData[citizenid],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[citizenid].DailyMissions.time, citizenid),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            else
                CDM.PlayerPostOPData[citizenid].DailyMissions = {
                    firstcargo = {bool = false},
                    DeliverCargo = {amount = 0, bool = false},
                    endofWork = {bool = false},
                    time = os.time()
                }
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[citizenid],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[citizenid].DailyMissions.time, citizenid),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            end
        else
            local identifier = player.identifier
            
            if CDM.PlayerPostOPData[identifier] == nil then
                CDM.PlayerPostOPData[identifier] = {}
                CDM.PlayerPostOPData[identifier].xp = 0
                CDM.PlayerPostOPData[identifier].level = CDM.GetLevelFromXP(0)
                CDM.PlayerPostOPData[identifier].class = CDM.GetClassFromLevel(CDM.PlayerPostOPData[identifier].level)
                CDM.PlayerPostOPData[identifier].name = CDM.GetPlayerCharacterName(source)
                CDM.PlayerPostOPData[identifier].statistics = {completedworks = 0, earned = 0}
                CDM.PlayerPostOPData[identifier].DailyMissions = {
                    firstcargo = {bool = false},
                    DeliverCargo = {amount = 0, bool = false},
                    endofWork = {bool = false},
                    time = os.time()
                }
                CDM.PlayerPostOPData[identifier].lastjobs = {}
                
                table.insert(CDM.LeaderBoard, {
                    level = 1,
                    identifier = identifier,
                    name = CDM.PlayerPostOPData[identifier].name
                })
            end
            
            CDM.BoardArrangement()
            CDM.UpdateLevel(identifier)
            
            if CDM.PlayerPostOPData[identifier].DailyMissions then
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[identifier],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[identifier].DailyMissions.time, identifier),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            else
                CDM.PlayerPostOPData[identifier].statistics = {completedworks = 0, earned = 0}
                CDM.PlayerPostOPData[identifier].DailyMissions = {
                    firstcargo = {bool = false},
                    DeliverCargo = {amount = 0, bool = false},
                    endofWork = {bool = false},
                    time = os.time()
                }
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[identifier],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[identifier].DailyMissions.time, identifier),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            end
        end
    elseif action == "gardrop" then
        if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
            local citizenid = player.PlayerData.citizenid
            
            if CDM.BadgeData[citizenid] then
                return
            end
            
            if CDM.PlayerPostOPData[citizenid] then
                if not CDM.Inventory.RemoveMoney(source, CDM.Config.BadgePrice) then
                    return CDM.SendMessage(CDM.Messages.server.enoughmoney, true, "server", source)
                end
                
                CDM.BadgeData[citizenid] = true
                
                if CDM.PlayerPostOPData[citizenid] == nil then
                    CDM.PlayerPostOPData[citizenid] = {}
                    CDM.PlayerPostOPData[citizenid].job = {}
                end
                
                CDM.PlayerPostOPData[citizenid].job = {}
                CDM.PlayerPostOPData[citizenid].job.route = "unknown"
                CDM.PlayerPostOPData[citizenid].job.wardrobe = true
                CDM.SendMessage(CDM.Messages.server.setclothes, false, "server", source)
            end
        else
            if CDM.PlayerPostOPData[player.identifier] then
                if CDM.BadgeData[player.identifier] then
                    return
                end
                
                if not CDM.Inventory.RemoveMoney(source, CDM.Config.BadgePrice) then
                    return CDM.SendMessage(CDM.Messages.server.enoughmoney, true, "server", source)
                end
                
                CDM.BadgeData[player.identifier] = true
                
                if CDM.PlayerPostOPData[player.identifier] == nil then
                    CDM.PlayerPostOPData[player.identifier] = {}
                    CDM.PlayerPostOPData[player.identifier].job = {}
                end
                
                CDM.PlayerPostOPData[player.identifier].job = {}
                CDM.PlayerPostOPData[player.identifier].job.route = "unknown"
                CDM.PlayerPostOPData[player.identifier].job.wardrobe = true
                CDM.SendMessage(CDM.Messages.server.setclothes, false, "server", source)
            end
        end
    else
        CDM.SendMessage(CDM.Messages.server.selectjobfirst, false, "server", source)
    end
end)

RegisterServerEvent("m-postop-server:UpdateJobData")
AddEventHandler("m-postop-server:UpdateJobData", function(jobType, routeIndex)
    local source = source
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].job ~= nil then
            if CDM.PlayerPostOPData[citizenid].job.wardrobe then
                CDM.PlayerPostOPData[citizenid].job.route = CDM.Routes[jobType][routeIndex]
                CDM.PlayerPostOPData[citizenid].job.jobtype = jobType
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[citizenid],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[citizenid].DailyMissions.time, citizenid),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            else
                CDM.SendMessage(CDM.Messages.server.needbadge, true, "server", source)
            end
        end
    else
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].job ~= nil then
            if CDM.PlayerPostOPData[identifier].job.wardrobe then
                CDM.PlayerPostOPData[identifier].job.route = CDM.Routes[jobType][routeIndex]
                CDM.PlayerPostOPData[identifier].job.jobtype = jobType
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[identifier],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[identifier].DailyMissions.time, identifier),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            else
                CDM.SendMessage(CDM.Messages.server.needbadge, true, "server", source)
            end
        end
    end
end)

RegisterServerEvent("m-postop-server:DeliverPackage")
AddEventHandler("m-postop-server:DeliverPackage", function(jobIndex)
    local player = CDM.GetPlayer(source)
    
    if cooldowns[source] then
        local timeDiff = os.time() - cooldowns[source]
        if timeDiff < 5 then
            CDM.SendMessage(CDM.Messages.server.youcantdo, true, "server", source)
            return
        end
    end
    
    cooldowns[source] = os.time()
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local deliverAmount = math.random(CDM.Config.DeliverAmount.min, CDM.Config.DeliverAmount.max)
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].job ~= nil then
            if CDM.PlayerPostOPData[citizenid].job.jobtype == "cargo" then
                if CDM.PlayerPostOPData[citizenid].job.deliver == nil then
                    CDM.PlayerPostOPData[citizenid].job.deliver = 0
                    CDM.PlayerPostOPData[citizenid].job.vehiclesPackages = CDM.Vehicles[CDM.PlayerPostOPData[citizenid].job.vehicle].capacity
                end
                
                if CDM.PlayerPostOPData[citizenid].job.vehiclesPackages == 0 then
                    return
                end
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.firstcargo.bool == false then
                    CDM.PlayerPostOPData[citizenid].DailyMissions.firstcargo.bool = true
                    CDM.AddXP(citizenid, CDM.Config.DailyMissions.firstcargo.xp)
                end
                
                if CDM.PlayerPostOPData[citizenid].job.vehiclesPackages - deliverAmount <= 0 then
                    CDM.PlayerPostOPData[citizenid].job.deliver = CDM.PlayerPostOPData[citizenid].job.deliver + CDM.PlayerPostOPData[citizenid].job.vehiclesPackages
                    CDM.PlayerPostOPData[citizenid].job.vehiclesPackages = 0
                    CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount + CDM.PlayerPostOPData[citizenid].job.vehiclesPackages
                    
                    if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                        if not CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool then
                            CDM.AddXP(citizenid, CDM.Config.DailyMissions.deliver.xp)
                        end
                    end
                    
                    if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                        CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool = true
                    end
                    
                    local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                    CDM.AddXP(citizenid, xpAmount)
                    CDM.UpdateRemainingPackage(citizenid)
                    
                    local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[citizenid].job.route, deliverAmount, false)
                    CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp + xpAmount
                    CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney + earnedMoney)
                    
                    if not CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork.bool then
                        CDM.AddXP(citizenid, CDM.Config.DailyMissions.endofwork.xp)
                    end
                    
                    CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork = {bool = true}
                    CDM.FinishJob(source, citizenid)
                    return
                end
                
                CDM.PlayerPostOPData[citizenid].job.vehiclesPackages = CDM.PlayerPostOPData[citizenid].job.vehiclesPackages - deliverAmount
                
                if CDM.PlayerPostOPData[citizenid].job.deliver + deliverAmount >= CDM.PlayerPostOPData[citizenid].job.route.totalDelivery then
                    CDM.PlayerPostOPData[citizenid].job.deliver = CDM.PlayerPostOPData[citizenid].job.route.totalDelivery
                    CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount + deliverAmount
                    
                    if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                        if not CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool then
                            CDM.AddXP(citizenid, CDM.Config.DailyMissions.deliver.xp)
                        end
                    end
                    
                    if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                        CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool = true
                    end
                    
                    local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                    CDM.AddXP(citizenid, xpAmount)
                    CDM.UpdateRemainingPackage(citizenid)
                    
                    local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[citizenid].job.route, deliverAmount, true)
                    
                    if not CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork.bool then
                        CDM.AddXP(citizenid, CDM.Config.DailyMissions.endofwork.xp)
                    end
                    
                    CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork = {bool = true}
                    CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp + xpAmount
                    CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney + earnedMoney)
                    CDM.FinishJob(source, citizenid)
                    CDM.PlayerPostOPData[citizenid].statistics.completedworks = CDM.PlayerPostOPData[citizenid].statistics.completedworks + 1
                    return
                end
                
                local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                CDM.AddXP(citizenid, xpAmount)
                CDM.PlayerPostOPData[citizenid].job.deliver = CDM.PlayerPostOPData[citizenid].job.deliver + deliverAmount
                CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount + deliverAmount
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                    if not CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool then
                        CDM.AddXP(citizenid, CDM.Config.DailyMissions.deliver.xp)
                    end
                end
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                    CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool = true
                end
                
                TriggerClientEvent("m-postop-client:ContinueJob", source)
                CDM.UpdateRemainingPackage(citizenid)
                
                local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[citizenid].job.route, deliverAmount, false)
                CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp + xpAmount
                CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney + earnedMoney)
            else
                local totalDelivery = CDM.PlayerPostOPData[citizenid].job.route.totalDelivery
                
                if CDM.Vehicles[CDM.PlayerPostOPData[citizenid].job.vehicle].capacity < CDM.PlayerPostOPData[citizenid].job.route.totalDelivery then
                    CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount = CDM.Vehicles[CDM.PlayerPostOPData[citizenid].job.vehicle].capacity
                    totalDelivery = CDM.Vehicles[CDM.PlayerPostOPData[citizenid].job.vehicle].capacity
                end
                
                local xpAmount = CDM.Config.XPAmountForPerPackage * totalDelivery
                CDM.AddXP(citizenid, xpAmount)
                CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount = totalDelivery
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.firstcargo.bool == false then
                    CDM.PlayerPostOPData[citizenid].DailyMissions.firstcargo.bool = true
                    CDM.AddXP(citizenid, CDM.Config.DailyMissions.firstcargo.xp)
                end
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                    if not CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool then
                        CDM.AddXP(citizenid, CDM.Config.DailyMissions.deliver.xp)
                    end
                end
                
                if CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.amount >= 50 then
                    CDM.PlayerPostOPData[citizenid].DailyMissions.DeliverCargo.bool = true
                end
                
                CDM.PlayerPostOPData[citizenid].job.deliver = totalDelivery
                local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[citizenid].job.route, totalDelivery, true, true)
                CDM.UpdateRemainingPackage(citizenid)
                CDM.FinishJob(source, citizenid)
                CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp + xpAmount
                CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney = math.floor(earnedMoney)
                
                if not CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork.bool then
                    CDM.AddXP(citizenid, CDM.Config.DailyMissions.endofwork.xp)
                end
                
                CDM.PlayerPostOPData[citizenid].DailyMissions.endofWork = {bool = true}
            end
            CDM.UpdateLevel(citizenid)
        end
    else
        local deliverAmount = math.random(CDM.Config.DeliverAmount.min, CDM.Config.DeliverAmount.max)
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].job ~= nil then
            if CDM.PlayerPostOPData[identifier].job.jobtype == "cargo" then
                if CDM.PlayerPostOPData[identifier].job.deliver == nil then
                    CDM.PlayerPostOPData[identifier].job.deliver = 0
                    CDM.PlayerPostOPData[identifier].job.vehiclesPackages = CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity
                end
                
                if CDM.PlayerPostOPData[identifier].job.vehiclesPackages == 0 then
                    return
                end
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.firstcargo.bool == false then
                    CDM.PlayerPostOPData[identifier].DailyMissions.firstcargo.bool = true
                    CDM.AddXP(identifier, CDM.Config.DailyMissions.firstcargo.xp)
                end
                
                if CDM.PlayerPostOPData[identifier].job.vehiclesPackages - deliverAmount <= 0 then
                    CDM.PlayerPostOPData[identifier].job.deliver = CDM.PlayerPostOPData[identifier].job.deliver + CDM.PlayerPostOPData[identifier].job.vehiclesPackages
                    CDM.PlayerPostOPData[identifier].job.vehiclesPackages = 0
                    CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount + CDM.PlayerPostOPData[identifier].job.vehiclesPackages
                    
                    if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                        if not CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool then
                            CDM.AddXP(identifier, CDM.Config.DailyMissions.deliver.xp)
                        end
                    end
                    
                    if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                        CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool = true
                    end
                    
                    local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                    CDM.AddXP(identifier, xpAmount)
                    CDM.UpdateRemainingPackage(identifier)
                    
                    local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[identifier].job.route, deliverAmount, false)
                    CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp + xpAmount
                    CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney + earnedMoney)
                    
                    if not CDM.PlayerPostOPData[identifier].DailyMissions.endofWork.bool then
                        CDM.AddXP(identifier, CDM.Config.DailyMissions.endofwork.xp)
                    end
                    
                    CDM.PlayerPostOPData[identifier].DailyMissions.endofWork = {bool = true}
                    CDM.FinishJob(source, identifier)
                    return
                end
                
                CDM.PlayerPostOPData[identifier].job.vehiclesPackages = CDM.PlayerPostOPData[identifier].job.vehiclesPackages - deliverAmount
                
                if CDM.PlayerPostOPData[identifier].job.deliver + deliverAmount >= CDM.PlayerPostOPData[identifier].job.route.totalDelivery then
                    CDM.PlayerPostOPData[identifier].job.deliver = CDM.PlayerPostOPData[identifier].job.route.totalDelivery
                    CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount + deliverAmount
                    
                    if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                        if not CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool then
                            CDM.AddXP(identifier, CDM.Config.DailyMissions.deliver.xp)
                        end
                    end
                    
                    if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                        CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool = true
                    end
                    
                    local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                    CDM.AddXP(identifier, xpAmount)
                    CDM.UpdateRemainingPackage(identifier)
                    
                    local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[identifier].job.route, deliverAmount, true)
                    
                    if not CDM.PlayerPostOPData[identifier].DailyMissions.endofWork.bool then
                        CDM.AddXP(identifier, CDM.Config.DailyMissions.endofwork.xp)
                    end
                    
                    CDM.PlayerPostOPData[identifier].DailyMissions.endofWork = {bool = true}
                    CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp + xpAmount
                    CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney + earnedMoney)
                    CDM.FinishJob(source, identifier)
                    CDM.PlayerPostOPData[identifier].statistics.completedworks = CDM.PlayerPostOPData[identifier].statistics.completedworks + 1
                    return
                end
                
                local xpAmount = CDM.Config.XPAmountForPerPackage * deliverAmount
                CDM.AddXP(identifier, xpAmount)
                CDM.PlayerPostOPData[identifier].job.deliver = CDM.PlayerPostOPData[identifier].job.deliver + deliverAmount
                CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount = CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount + deliverAmount
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                    if not CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool then
                        CDM.AddXP(identifier, CDM.Config.DailyMissions.deliver.xp)
                    end
                end
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                    CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool = true
                end
                
                TriggerClientEvent("m-postop-client:ContinueJob", source)
                CDM.UpdateRemainingPackage(identifier)
                
                local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[identifier].job.route, deliverAmount, false)
                CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp + xpAmount
                CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney = math.floor(CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney + earnedMoney)
            else
                local totalDelivery = CDM.PlayerPostOPData[identifier].job.route.totalDelivery
                
                if CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity < CDM.PlayerPostOPData[identifier].job.route.totalDelivery then
                    CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount = CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity
                    totalDelivery = CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity
                end
                
                local xpAmount = CDM.Config.XPAmountForPerPackage * totalDelivery
                CDM.AddXP(identifier, xpAmount)
                CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount = totalDelivery
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.firstcargo.bool == false then
                    CDM.PlayerPostOPData[identifier].DailyMissions.firstcargo.bool = true
                    CDM.AddXP(identifier, CDM.Config.DailyMissions.firstcargo.xp)
                end
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                    if not CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool then
                        CDM.AddXP(identifier, CDM.Config.DailyMissions.deliver.xp)
                    end
                end
                
                if CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.amount >= 50 then
                    CDM.PlayerPostOPData[identifier].DailyMissions.DeliverCargo.bool = true
                end
                
                CDM.PlayerPostOPData[identifier].job.deliver = totalDelivery
                local earnedMoney = CDM.CalculateEarnMoney(source, CDM.PlayerPostOPData[identifier].job.route, totalDelivery, true, true)
                CDM.UpdateRemainingPackage(identifier)
                CDM.FinishJob(source, identifier)
                CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp = CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp + xpAmount
                CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney = math.floor(earnedMoney)
                
                if not CDM.PlayerPostOPData[identifier].DailyMissions.endofWork.bool then
                    CDM.AddXP(identifier, CDM.Config.DailyMissions.endofwork.xp)
                end
                
                CDM.PlayerPostOPData[identifier].DailyMissions.endofWork = {bool = true}
            end
            CDM.UpdateLevel(identifier)
        end
    end
end)

RegisterNetEvent("m-postop-server:UpdateRemainingPackage")
AddEventHandler("m-postop-server:UpdateRemainingPackage", function()
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        CDM.UpdateRemainingPackage(player.PlayerData.citizenid)
    else
        CDM.UpdateRemainingPackage(player.identifier)
    end
end)

RegisterServerEvent("m-postop-server:SetVehicleData")
AddEventHandler("m-postop-server:SetVehicleData", function(vehicleType)
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].job ~= nil then
            if CDM.PlayerPostOPData[citizenid].job.route then
                CDM.PlayerPostOPData[citizenid].job.vehicle = vehicleType
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[citizenid],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[citizenid].DailyMissions.time, citizenid),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            end
        end
    else
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].job ~= nil then
            if CDM.PlayerPostOPData[identifier].job.route then
                CDM.PlayerPostOPData[identifier].job.vehicle = vehicleType
                TriggerClientEvent("m-postop-client:OpenNui", source,
                    CDM.PlayerPostOPData[identifier],
                    CDM.CheckDailyMissions(CDM.PlayerPostOPData[identifier].DailyMissions.time, identifier),
                    CDM.LeaderBoard,
                    CDM.GetProfilePhoto(source))
            end
        end
    end
end)

RegisterServerEvent("m-postop-server:StartJob")
AddEventHandler("m-postop-server:StartJob", function()
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].job ~= nil then
            if CDM.PlayerPostOPData[citizenid].job.route == nil then
                return
            end
            
            if CDM.PlayerPostOPData[citizenid].job.vehicle == nil then
                return
            end
            
            if CDM.PlayerPostOPData[citizenid].lastjobs == nil then
                CDM.PlayerPostOPData[citizenid].lastjobs = {}
            end
            
            local jobIndex = #CDM.PlayerPostOPData[citizenid].lastjobs + 1
            CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex] = {}
            CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedxp = 0
            CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].earnedmoney = 0
            CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].time = CDM.CalculateDay()
            CDM.PlayerPostOPData[citizenid].lastjobs[jobIndex].route = {
                jobtype = CDM.PlayerPostOPData[citizenid].job.jobtype,
                route = CDM.PlayerPostOPData[citizenid].job.route
            }
            
            TriggerClientEvent("m-postop-client:StartJob", source, CDM.PlayerPostOPData[citizenid].job, jobIndex)
            
            local message = CDM.Messages.server.startjob .. "" .. CDM.PlayerPostOPData[citizenid].job.route.label
            CDM.SendMessage(message, false, "server", source)
            CDM.UpdateLevel(citizenid)
            CDM.UpdateSQLData("update", citizenid)
        end
    else
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].job ~= nil then
            if CDM.PlayerPostOPData[identifier].job.route == nil then
                return
            end
            
            if CDM.PlayerPostOPData[identifier].job.vehicle == nil then
                return
            end
            
            if CDM.PlayerPostOPData[identifier].lastjobs == nil then
                CDM.PlayerPostOPData[identifier].lastjobs = {}
            end
            
            local jobIndex = #CDM.PlayerPostOPData[identifier].lastjobs + 1
            CDM.PlayerPostOPData[identifier].lastjobs[jobIndex] = {}
            CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedxp = 0
            CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].earnedmoney = 0
            CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].time = CDM.CalculateDay()
            CDM.PlayerPostOPData[identifier].lastjobs[jobIndex].route = {
                jobtype = CDM.PlayerPostOPData[identifier].job.jobtype,
                route = CDM.PlayerPostOPData[identifier].job.route
            }
            
            TriggerClientEvent("m-postop-client:StartJob", source, CDM.PlayerPostOPData[identifier].job, jobIndex)
            
            local message = CDM.Messages.server.startjob .. "" .. CDM.PlayerPostOPData[identifier].job.route.label
            CDM.SendMessage(message, false, "server", source)
            CDM.UpdateLevel(identifier)
            CDM.UpdateSQLData("update", identifier)
        end
    end
end)

RegisterServerEvent("m-postop-server:fillvehicle")
AddEventHandler("m-postop-server:fillvehicle", function()
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].job ~= nil then
            CDM.PlayerPostOPData[citizenid].job.vehiclesPackages = CDM.Vehicles[CDM.PlayerPostOPData[citizenid].job.vehicle].capacity
            CDM.UpdateRemainingPackage(citizenid)
        end
    else
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].job ~= nil then
            CDM.PlayerPostOPData[identifier].job.vehiclesPackages = CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity
            CDM.UpdateRemainingPackage(identifier)
        end
    end
end)

CDM.ExecuteSql = function(query)
    local waiting = true
    local result = nil
    
    if CDM.Config.Database == "oxmysql" then
        exports.oxmysql:execute(query, function(data)
            result = data
            waiting = false
        end)
    elseif CDM.Config.Database == "ghmattimysql" then
        exports.ghmattimysql:execute(query, {}, function(data)
            result = data
            waiting = false
        end)
    elseif CDM.Config.Database == "mysql-async" then
        MySQL.Async.fetchAll(query, {}, function(data)
            result = data
            waiting = false
        end)
    end
    
    while waiting do
        Citizen.Wait(0)
    end
    
    return result
end

CDM.FinishJobWithCommand = function(identifier, playerId)
    if CDM.PlayerPostOPData[identifier] then
        if CDM.PlayerPostOPData[identifier].job then
            CDM.PlayerPostOPData[identifier].job = nil
            TriggerClientEvent("m-postop-client:FinishJob", playerId)
        end
    end
end

RegisterNetEvent("m-postop-server:FinishJobWithCommand")
AddEventHandler("m-postop-server:FinishJobWithCommand", function()
    local player = CDM.GetPlayer(source)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        CDM.FinishJobWithCommand(player.PlayerData.citizenid, source)
    else
        CDM.FinishJobWithCommand(player.identifier, source)
    end
end)

CDM.FinishJob = function(playerId, identifier)
    if CDM.PlayerPostOPData[identifier] then
        if CDM.PlayerPostOPData[identifier].job then
            CDM.PlayerPostOPData[identifier].job = nil
            TriggerClientEvent("m-postop-client:FinishJob", playerId)
            CDM.UpdateSQLData("update", identifier)
            
            if CDM.BadgeData[identifier] ~= nil then
                CDM.BadgeData[identifier] = nil
                CDM.Inventory.AddMoney(playerId, CDM.Config.BadgePrice)
            end
        end
    end
end

CDM.ResetDailyMissions = function(identifier)
    if CDM.PlayerPostOPData[identifier] then
        CDM.PlayerPostOPData[identifier].DailyMissions = {
            firstcargo = {bool = false},
            DeliverCargo = {amount = 0, bool = false},
            endofWork = {bool = false},
            time = os.time()
        }
    end
end

CDM.UpdateRemainingPackage = function(identifier)
    if CDM.PlayerPostOPData[identifier].job.deliver == nil then
        CDM.PlayerPostOPData[identifier].job.deliver = 0
        CDM.PlayerPostOPData[identifier].job.vehiclesPackages = CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity
    end
    
    TriggerClientEvent("m-postop-client:UpdatePackages", source,
        CDM.PlayerPostOPData[identifier].job.deliver,
        CDM.PlayerPostOPData[identifier].job.route.totalDelivery,
        CDM.Vehicles[CDM.PlayerPostOPData[identifier].job.vehicle].capacity,
        CDM.PlayerPostOPData[identifier].job.vehiclesPackages)
end

CDM.GetPlayerCharacterName = function(playerId)
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        player = frameworkObject.Functions.GetPlayer(playerId)
        return player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    else
        return CDM.GetPlayerCharacterNameESX(playerId)
    end
end

CDM.SetEarnedMoney = function(playerId, amount)
    local player = CDM.GetPlayer(playerId)
    
    if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
        local citizenid = player.PlayerData.citizenid
        
        if CDM.PlayerPostOPData[citizenid].statistics ~= nil then
            CDM.PlayerPostOPData[citizenid].statistics.earned = math.floor(CDM.PlayerPostOPData[citizenid].statistics.earned + amount)
        end
    else
        local identifier = player.identifier
        
        if CDM.PlayerPostOPData[identifier].statistics ~= nil then
            CDM.PlayerPostOPData[identifier].statistics.earned = math.floor(CDM.PlayerPostOPData[identifier].statistics.earned + amount)
        end
    end
end

CDM.UpdateSQLData = function(action, identifier)
    if action == "update" then
        local userData = {}
        
        if CDM.PlayerPostOPData[identifier] ~= nil then
            for key, value in pairs(CDM.PlayerPostOPData[identifier]) do
                if key ~= "job" then
                    userData[key] = value
                end
            end
        end
        
        local dbResult = CDM.ExecuteSql("SELECT * FROM m_postop WHERE identifier = '" .. identifier .. "'")
        
        if dbResult[1] == nil then
            CDM.ExecuteSql("INSERT INTO m_postop (identifier, userdata) VALUES ('" .. identifier .. "', '" .. json.encode(userData) .. "')")
        else
            CDM.ExecuteSql("UPDATE m_postop SET userdata ='" .. json.encode(userData) .. "' WHERE identifier = '" .. identifier .. "'")
        end
    elseif action == "get" then
        local dbResult = CDM.ExecuteSql("SELECT * FROM m_postop")
        
        if dbResult[1] then
            for index, row in pairs(dbResult) do
                row.userdata = json.decode(row.userdata)
                
                if next(row.userdata) then
                    CDM.PlayerPostOPData[row.identifier] = row.userdata
                    
                    if row.userdata.xp == nil then
                        row.userdata.xp = 0
                    end
                    
                    CDM.PlayerPostOPData[row.identifier].level = CDM.GetLevelFromXP(row.userdata.xp)
                    CDM.PlayerPostOPData[row.identifier].class = CDM.GetClassFromLevel(CDM.PlayerPostOPData[row.identifier].level)
                    
                    table.insert(CDM.LeaderBoard, {
                        level = CDM.PlayerPostOPData[row.identifier].level,
                        identifier = row.identifier,
                        name = row.userdata.name
                    })
                end
            end
            CDM.BoardArrangement()
        end
    end
end

CDM.BoardArrangement = function()
    local leaderboard = CDM.LeaderBoard
    
    table.sort(leaderboard, function(a, b)
        return tonumber(a.level) > tonumber(b.level)
    end)
    
    for position, entry in pairs(leaderboard) do
        if CDM.PlayerPostOPData[entry.identifier] then
            CDM.PlayerPostOPData[entry.identifier].leaderboard = position
        end
    end
end

CDM.UpdateLevel = function(identifier)
    if CDM.PlayerPostOPData[identifier].xp == nil then
        CDM.PlayerPostOPData[identifier].xp = 0
    end
    
    CDM.PlayerPostOPData[identifier].level = CDM.GetLevelFromXP(CDM.PlayerPostOPData[identifier].xp)
    CDM.PlayerPostOPData[identifier].class = CDM.GetClassFromLevel(CDM.PlayerPostOPData[identifier].level)
end

CDM.AddXP = function(identifier, xpAmount)
    if CDM.PlayerPostOPData[identifier].xp == nil then
        CDM.PlayerPostOPData[identifier].xp = 0
    end
    
    CDM.PlayerPostOPData[identifier].xp = CDM.PlayerPostOPData[identifier].xp + xpAmount
end

CDM.CalculateDay = function()
    return os.date("%d.%m.%y %H:%M")
end

function SecondsToClock(seconds)
    if seconds ~= nil then
        local numSeconds = tonumber(seconds)
        
        if numSeconds <= 0 then
            return
        else
            hours = string.format("%0.f", math.floor(numSeconds / 3600))
            mins = string.format("%0.f", math.floor(numSeconds / 60 - (hours * 60)))
            return
        end
    end
end

function GetSteamPP(playerId)
    local steamId = nil
    
    for index, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        if string.sub(identifier, 1, string.len("steam:")) == "steam:" then
            steamId = identifier
        end
    end
    
    local defaultAvatar = "https://www.gitbook.com/cdn-cgi/image/width=40,dpr=2,height=40,fit=contain,format=auto/https%3A%2F%2F3253843082-files.gitbook.io%2F~%2Ffiles%2Fv0%2Fb%2Fgitbook-x-prod.appspot.com%2Fo%2Fspaces%252FMRUfpMzIuVWlJ1CkzDbb%252Ficon%252FD3wjQp0cCyS6MkqdCs1C%252Fimage_2022-09-06_182033969.png%3Falt%3Dmedia%26token%3D662e0ec6-bb96-40d2-87e0-3e74d4061566"
    
    if steamId == nil then
        return defaultAvatar
    end
    
    local promise = promise.new()
    
    PerformHttpRequest("http://steamcommunity.com/profiles/" .. tonumber(GetIDFromSource("steam", steamId), 16) .. "/?xml=1", function(statusCode, responseData, headers)
        local lines = stringsplit(responseData, "\n")
        
        if lines ~= nil then
            if next(lines) ~= nil then
                for index, line in ipairs(lines) do
                    if line:find("<avatarFull>") then
                        promise:resolve(line:gsub("<avatarFull><!%[CDATA%[", ""):gsub("]]></avatarFull>", ""))
                        
                        for key, value in pairs(promise) do
                            return promise.value
                        end
                        break
                    end
                end
            end
        end
    end)
    
    return Citizen.Await(promise)
end

function GetIDFromSource(idType, identifier)
    local parts = stringsplit(identifier, ":")
    
    if parts[1]:lower() == string.lower(idType) then
        return parts[2]:lower()
    end
    
    return nil
end

function stringsplit(inputstr, separator)
    if separator == nil then
        separator = "%s"
    end
    
    local result = {}
    i = 1
    
    if inputstr ~= nil then
        for str in string.gmatch(inputstr, "([^" .. separator .. "]+)") do
            result[i] = str
            i = i + 1
        end
        return result
    end
end

local Discord = {Avatars = {}}

function GetDiscordAvatar(playerId)
    local discordId = nil
    local avatarUrl = nil
    
    if playerId then
        for index, identifier in ipairs(GetPlayerIdentifiers(playerId)) do
            if string.match(identifier, "discord:") then
                discordId = string.gsub(identifier, "discord:", "")
                break
            end
        end
        
        if discordId then
            if Discord.Avatars[discordId] == nil then
                local endpoint = ("users/%s"):format(discordId)
                local response = DiscordRequest("GET", endpoint, {})
                
                if response.code == 200 then
                    local userData = json.decode(response.data)
                    
                    if userData ~= nil then
                        if userData.avatar ~= nil then
                            if userData.avatar:sub(1, 1) then
                                if userData.avatar:sub(2, 2) == "_" then
                                    avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".gif"
                                end
                            else
                                avatarUrl = "https://media.discordapp.net/avatars/" .. discordId .. "/" .. userData.avatar .. ".png"
                            end
                        end
                    end
                end
                
                Discord.Avatars[discordId] = avatarUrl
            else
                avatarUrl = Discord.Avatars[discordId]
            end
        end
        
        return avatarUrl
    end
end

local botAuthToken = "Bot " .. bot_Token

function DiscordRequest(method, endpoint, data)
    local response = nil
    
    PerformHttpRequest("https://discordapp.com/api/" .. endpoint, function(statusCode, responseData, headers)
        response = {
            data = responseData,
            code = statusCode,
            headers = headers
        }
    end, method, #data > 0 and json.encode(data) or "", {
        ["Content-Type"] = "application/json",
        Authorization = botAuthToken
    })
    
    while response == nil do
        Citizen.Wait(0)
    end
    
    return response
end

CDM.GetProfilePhoto = function(playerId)
    if CDM.Config.UserImageType == "steam" then
        return GetSteamPP(playerId)
    else
        return GetDiscordAvatar(playerId)
    end
end

AddEventHandler("playerDropped", function(reason)
    if source then
        local player = CDM.GetPlayer(source)
        
        if player then
            if CDM.Config.Framework == "new-qb" or CDM.Config.Framework == "old-qb" then
                local citizenid = player.PlayerData.citizenid
                
                if CDM.PlayerPostOPData[citizenid] ~= nil then
                    if CDM.PlayerPostOPData[citizenid].job ~= nil then
                        CDM.PlayerPostOPData[citizenid].job = nil
                    end
                    
                    if CDM.BadgeData[citizenid] ~= nil then
                        CDM.BadgeData[citizenid] = nil
                    end
                    
                    CDM.UpdateSQLData("update", citizenid)
                end
            else
                local identifier = player.identifier
                
                if CDM.PlayerPostOPData[identifier] ~= nil then
                    if CDM.PlayerPostOPData[identifier].job ~= nil then
                        CDM.PlayerPostOPData[identifier].job = nil
                    end
                    
                    if CDM.BadgeData[identifier] ~= nil then
                        CDM.BadgeData[identifier] = nil
                    end
                    
                    CDM.UpdateSQLData("update", identifier)
                end
            end
        end
    end
end)