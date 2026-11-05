--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]


function GetMultiJobs()
    if GetResourceState("ps-multijob") == "started" then
        if not QB then
            return
        end

        local jobsPromise = promise.new()

        QB.Functions.TriggerCallback('ps-multijob:getJobs', function(result)
            jobsPromise:resolve(result)
        end)

        local formattedJobs = {}
        local allJobs = Citizen.Await(jobsPromise)

        for _, jobs in pairs(allJobs) do
            for i = 1, #jobs do
                local job = jobs[i]

                formattedJobs[#formattedJobs+1] = {
                    icon = job.icon,
                    job = job.name,
                    label = job.label,
                    grade = job.grade
                }
            end
        end

        return {
            jobs = formattedJobs,
            activeJob = PlayerData.job.name,
            canLeave = true
        }
    end
end

function SetActiveJob(job)
    if GetResourceState("ps-multijob") == "started" then
        TriggerServerEvent("ps-multijob:changeJob", job.job, job.grade)

        return true
    end

    return false
end

function LeaveJob(job)
    if GetResourceState("ps-multijob") == "started" then
        TriggerServerEvent("ps-multijob:removeJob", job.job, job.grade)

        return true
    end

    return false
end

function SetMultiJobData(data)
    SendNUIAction("services:setJobs", data)
end

function RefreshMultiJobs()
    local data = GetMultiJobs()

    SetMultiJobData(data)
end

