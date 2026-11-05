-- Access control: five additive methods (everyone / ace / groups / jobs /
-- identifiers), always checked server-side. A player passes as soon as the
-- first enabled method says yes.

Access = {}

local ESX, QBCore = nil, nil
local Framework = 'standalone'   -- resolved at runtime; never read Config directly below

-- A resource only counts as present if it is actually STARTED. A server that
-- merely has the folder on disk (stopped, or a leftover) must not win detection.
local function started(name)
    return GetResourceState(name) == 'started'
end

local function detect()
    local want = (Config.Framework or 'auto'):lower()

    if want ~= 'auto' then
        Framework = want
    elseif started('es_extended') then
        Framework = 'esx'
    elseif started('qbx_core') then
        Framework = 'qbx'
    elseif started('qb-core') then
        Framework = 'qb'
    else
        Framework = 'standalone'
    end

    if Framework == 'esx' then
        local ok, core = pcall(function() return exports['es_extended']:getSharedObject() end)
        ESX = ok and core or nil
        -- Older ESX builds expose no getSharedObject export; fall back to the event.
        if not ESX then
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        end
    elseif Framework == 'qb' or Framework == 'qbx' then
        -- qbx_core still ships a qb-core compatible object, so this is safe for both.
        local ok, core = pcall(function() return exports['qb-core']:GetCoreObject() end)
        QBCore = ok and core or nil
    end

    if Config.Debug then
        print(('[apex_loading] framework: %s%s'):format(Framework,
            (Config.Framework or 'auto') == 'auto' and ' (auto-detected)' or ' (forced by config)'))
    end
end

-- Resources start in an arbitrary order, so give the core a moment to come up.
CreateThread(function()
    Wait(0)
    detect()
end)

function Access.Framework() return Framework end

local function hasAce(src, perm)
    return IsPlayerAceAllowed(src, perm)
end

-- QB stores the grade as a table ({ level = 3 }), but several forks and older
-- builds store a plain number. Accept both rather than silently reading 0.
local function qbGrade(job)
    local g = job and job.grade
    if type(g) == 'table' then return tonumber(g.level) or 0 end
    return tonumber(g) or 0
end

local function getJob(src)
    if Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.job then
            local grade = xPlayer.job.grade
            return xPlayer.job.name, tonumber(grade) or 0
        end
    elseif Framework == 'qbx' then
        local ok, player = pcall(function() return exports.qbx_core:GetPlayer(src) end)
        if ok and player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name, qbGrade(player.PlayerData.job)
        end
        -- qbx_core also answers the qb-core object, so fall through to it below.
    end

    if (Framework == 'qb' or Framework == 'qbx') and QBCore then
        local ok, player = pcall(function() return QBCore.Functions.GetPlayer(src) end)
        if ok and player and player.PlayerData and player.PlayerData.job then
            return player.PlayerData.job.name, qbGrade(player.PlayerData.job)
        end
    end

    return nil, 0
end

local function inGroup(src, name)
    if hasAce(src, name) or hasAce(src, 'group.' .. name)
        or hasAce(src, 'qbcore.' .. name) or hasAce(src, 'qbx.' .. name) then
        return true
    end
    if Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer and xPlayer.getGroup then
            local ok, group = pcall(xPlayer.getGroup)
            if ok and group == name then return true end
        end
    elseif Framework == 'qbx' then
        -- qbx_core takes a LIST of groups, not a single string.
        local ok, res = pcall(function() return exports.qbx_core:HasPermission(src, { name }) end)
        if ok and res then return true end
    end

    if (Framework == 'qb' or Framework == 'qbx') and QBCore then
        -- Newer QB wants a table, older QB wants a string. Try both.
        local ok, res = pcall(function() return QBCore.Functions.HasPermission(src, name) end)
        if ok and res then return true end
        ok, res = pcall(function() return QBCore.Functions.HasPermission(src, { name }) end)
        if ok and res then return true end
    end

    return false
end

function Access.Check(src, kind)
    local cfg = Config.Access and Config.Access[kind]
    if not cfg then return false end

    if cfg.everyone and cfg.everyone.enabled then return true end

    if cfg.ace and cfg.ace.enabled then
        for _, perm in ipairs(cfg.ace.permissions or {}) do
            if hasAce(src, perm) then return true end
        end
        if cfg.ace.acceptOwnerAces ~= false then
            for _, perm in ipairs(cfg.ace.ownerAces or { 'command', 'txadmin.everything', 'group.admin' }) do
                if hasAce(src, perm) then return true end
            end
        end
    end

    if cfg.groups and cfg.groups.enabled then
        for _, name in ipairs(cfg.groups.list or {}) do
            if inGroup(src, name) then return true end
        end
    end

    if cfg.jobs and cfg.jobs.enabled then
        local jobName, grade = getJob(src)
        if jobName and cfg.jobs.list and cfg.jobs.list[jobName] ~= nil then
            if grade >= (cfg.jobs.list[jobName] or 0) then return true end
        end
    end

    if cfg.identifiers and cfg.identifiers.enabled then
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local id = GetPlayerIdentifier(src, i)
            for _, want in ipairs(cfg.identifiers.list or {}) do
                if id == want then return true end
            end
        end
    end

    return false
end

-- Auto-sync file design to KVP store so changes in data/design.json are always published
CreateThread(function()
    Wait(1500)
    ExecuteCommand('loading_use_file')
end)
