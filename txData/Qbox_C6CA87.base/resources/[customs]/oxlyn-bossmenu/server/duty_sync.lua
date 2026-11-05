

--------------------------------------------------------------------
-- oxlyn-bossmenu | framework duty auto-sync (cleaned)
-- Mirrors QBCore / Qbox on-duty state into the bossmenu timesheet by
-- calling this resource's own StartDuty / EndDuty exports.
--------------------------------------------------------------------

local RESOURCE_TAG = "oxlyn-bossmenu"

-- Ignore repeated identical duty updates within this window (ms)
local DUTY_DEBOUNCE_MS = 750

-- "<identifier>:<jobName>" -> { duty = bool, ts = gameTimer }
local lastDutyState = {}

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

-- Returns { identifier, jobName } for a player source, or nil.
local function getPlayerContext(src)
    if not (Framework and Framework.GetPlayerFromId) then
        return nil
    end

    local player = Framework.GetPlayerFromId(src)
    if not player then
        return nil
    end

    local identifier = player.getIdentifier and player.getIdentifier() or nil
    local job        = player.getJob and player.getJob() or nil

    if not (identifier and job and job.name) then
        return nil
    end

    return {
        identifier = identifier,
        jobName    = job.name,
    }
end

-- Is this job one of the companies configured for the boss menu?
local function isCompanyJob(jobName)
    if not (Config and Config.Companies) then
        return false
    end

    for _, company in ipairs(Config.Companies) do
        if company.job == jobName then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------
-- Core sync
--------------------------------------------------------------------
local function syncDuty(src, onDuty)
    if Config and Config.AutoSyncFrameworkDuty == false then
        return
    end

    -- Only QBCore-family frameworks use this duty system
    if not (Framework and Framework.type == "qbcore") then
        return
    end

    local ctx = getPlayerContext(src)
    if not ctx then return end

    if CacheIdentity then
        CacheIdentity(src, ctx.identifier)
    end

    if not isCompanyJob(ctx.jobName) then return end

    -- Debounce duplicate events
    local key  = ctx.identifier .. ":" .. ctx.jobName
    local now  = GetGameTimer()
    local last = lastDutyState[key]

    if last and last.duty == onDuty and (now - last.ts) < DUTY_DEBOUNCE_MS then
        return
    end

    lastDutyState[key] = { duty = onDuty, ts = now }

    local self = exports[GetCurrentResourceName()]
    if onDuty then
        self:StartDuty(ctx.identifier, ctx.jobName)
    else
        self:EndDuty(ctx.identifier, ctx.jobName)
    end
end

-- On join: if the player is already on duty, start tracking them.
local function syncOnLoad(src)
    Wait(2000) -- let the framework finish building the player

    if not (Framework and Framework.type == "qbcore") then return end

    local player = Framework.GetPlayerFromId(src)
    if not (player and player._raw and player._raw.PlayerData) then return end

    local job = player._raw.PlayerData.job
    if job and job.onduty == true then
        syncDuty(src, true)
    end
end

--------------------------------------------------------------------
-- Framework events
--------------------------------------------------------------------
AddEventHandler("QBCore:Server:SetDuty", function(src, onDuty)
    syncDuty(src, onDuty == true)
end)

AddEventHandler("qbx_core:server:onSetDuty", function(src, onDuty)
    syncDuty(src, onDuty == true)
end)

AddEventHandler("QBCore:Server:OnJobUpdate", function(src, job)
    if job and type(job.onduty) == "boolean" then
        syncDuty(src, job.onduty)
    end
end)

AddEventHandler("QBCore:Server:PlayerLoaded", function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if src then
        CreateThread(function() syncOnLoad(src) end)
    end
end)

AddEventHandler("qbx_core:server:playerLoaded", function(data)
    local src = nil
    if type(data) == "table" then
        src = data.source or (data.PlayerData and data.PlayerData.source)
    end

    if src then
        CreateThread(function() syncOnLoad(src) end)
    end
end)

--------------------------------------------------------------------
-- Boot message: report whether auto-sync is active
--------------------------------------------------------------------
CreateThread(function()
    local waited = 0
    while not (Framework and Framework.ready) and waited < 30000 do
        Wait(250)
        waited = waited + 250
    end

    if not (Framework and Framework.ready) then return end
    if Framework.type ~= "qbcore" then return end

    if Config and Config.AutoSyncFrameworkDuty == false then
        print(("^3[%s] Auto-sync framework duty DISABLED (Config.AutoSyncFrameworkDuty = false)^7"):format(RESOURCE_TAG))
        return
    end

    print(("^2[%s] Auto-sync framework duty ENABLED — listening to QBCore:Server:SetDuty + qbx_core:server:onSetDuty^7"):format(RESOURCE_TAG))
end)

