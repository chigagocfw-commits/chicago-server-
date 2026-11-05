

--------------------------------------------------------------------
-- oxlyn-bossmenu | server framework bridge (cleaned)
--
-- Detects ESX / QBCore / Qbox and exposes a unified server API:
--   Framework.type / .core / .ready
--   Framework.GetPlayer / GetPlayerFromId / GetPlayerByIdentifier
--   Framework.GetIdentifier / GetName / GetJob / SetJob
--   Framework.GetMoney / AddMoney / RemoveMoney
--   Framework.GetSocietyMoney / AddSocietyMoney / RemoveSocietyMoney
--   Framework.GetAdminGroups / GetOnlineSources / GetExtendedPlayers
--   Framework.NotifyPlayer (ESX) / RegisterCallback
--
-- Also contains:
--   * an event-based server-callback fallback
--   * society (company) banking backends + Config.SocietyBanking override
--   * the /bossmenu_banking console diagnostic command
--------------------------------------------------------------------

local RESOURCE_TAG = "oxlyn-bossmenu"
local REASON       = "oxlyn-bossmenu" -- transaction reason sent to banking resources

Framework = {
    type  = nil,
    core  = nil,
    ready = false,
    isSchemaValid = false,
    schemaValidationStatus = "INITIALIZING",
    IsDatabaseReady = function()
        return Framework.isSchemaValid == true
    end,
}

--------------------------------------------------------------------
-- Generic helpers
--------------------------------------------------------------------

-- Config.FrameworkResource if set to a non-empty string, else default.
local function getResourceName(default)
    local override = Config and Config.FrameworkResource
    if type(override) == "string" and override ~= "" then
        return override
    end
    return default
end

-- True for functions and callable-looking tables (cfx references / metatables).
local function isCallable(value)
    local t = type(value)
    if t == "function" then
        return true
    end
    if t == "table" then
        if rawget(value, "__cfx_functionReference") then
            return true
        end
        return getmetatable(value) ~= nil
    end
    return false
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

--------------------------------------------------------------------
-- Detection trace (printed only if detection ultimately fails)
--------------------------------------------------------------------
local traceLog = {}

local function trace(msg)
    traceLog[#traceLog + 1] = msg
end

local function flushTrace()
    if #traceLog == 0 then return end

    print("^3[" .. RESOURCE_TAG .. "] Detection trace:^7")
    for _, line in ipairs(traceLog) do
        print("^3  " .. line .. "^7")
    end
    traceLog = {}
end

--------------------------------------------------------------------
-- Fallback event-based server callbacks
-- (used when the framework has no CreateCallback)
--------------------------------------------------------------------
local callbackHandlers = {}
local callbackEventRegistered = false

local function ensureCallbackEvent()
    if callbackEventRegistered then return end
    callbackEventRegistered = true

    RegisterNetEvent(RESOURCE_TAG .. ":cb:call", function(name, id, args)
        local src = source
        local handler = callbackHandlers[name]

        if not handler then
            TriggerClientEvent(RESOURCE_TAG .. ":cb:resp", src, id, nil)
            return
        end

        local replied = false
        local function reply(...)
            if replied then return end
            replied = true
            TriggerClientEvent(RESOURCE_TAG .. ":cb:resp", src, id, table.pack(...))
        end

        local ok, err = pcall(handler, src, reply, table.unpack(args or {}))
        if not ok then
            print(("^1[%s] Callback \"%s\" errored: %s^7"):format(RESOURCE_TAG, name, tostring(err)))
            reply(nil)
        end
    end)
end

local function registerFallbackCallback(name, handler)
    ensureCallbackEvent()
    callbackHandlers[name] = handler
end

--------------------------------------------------------------------
-- ESX
--------------------------------------------------------------------
local function tryEsx()
    local resource = getResourceName("es_extended")
    if GetResourceState(resource) ~= "started" then
        return false
    end

    local ESX
    local ok = pcall(function()
        ESX = exports[resource]:getSharedObject()
    end)

    if not ok or not ESX then
        local okEvent = pcall(function()
            TriggerEvent("esx:getSharedObject", function(obj) ESX = obj end)
        end)
        if not okEvent or not ESX then
            return false
        end
    end

    Framework.type = "esx"
    Framework.core = ESX

    ---------------- players ----------------
    Framework.GetPlayer = function(src)
        return ESX.GetPlayerFromId(src) or nil
    end

    Framework.GetPlayerFromId = function(src)
        return Framework.GetPlayer(src)
    end

    Framework.GetPlayerByIdentifier = function(identifier)
        if not ESX.GetPlayerFromIdentifier then return nil end
        local okCall, player = pcall(ESX.GetPlayerFromIdentifier, identifier)
        if not okCall then return nil end
        return player or nil
    end

    Framework.GetAdminGroups = function(src)
        local xPlayer = ESX.GetPlayerFromId(src)
        local group = xPlayer and xPlayer.getGroup and xPlayer.getGroup() or nil
        return group and { group } or {}
    end

    Framework.GetIdentifier = function(player)
        return player and player.getIdentifier and player.getIdentifier() or nil
    end

    Framework.GetName = function(player)
        if not player then return "Employee" end

        if player.get and player.get("firstName") then
            local last  = player.get("lastName") or ""
            local first = player.get("firstName") or ""
            return trim(first .. " " .. last)
        end

        return player.getName and player.getName() or "Employee"
    end

    Framework.GetJob = function(player)
        if not player then return nil end

        local job = player.getJob and player.getJob() or nil
        if not job then return nil end

        return {
            name        = job.name,
            grade       = tonumber(job.grade) or 0,
            label       = job.label,
            grade_label = job.grade_label or job.grade_name,
            grade_name  = job.grade_name,
        }
    end

    Framework.SetJob = function(player, jobName, grade)
        if not (player and player.setJob) then return false end
        player.setJob(jobName, grade)
        return true
    end

    ---------------- money ----------------
    Framework.GetMoney = function(player, account)
        if not player then return 0 end

        if account == "bank" and player.getAccount then
            local acc = player.getAccount("bank")
            return acc and acc.money or 0
        end

        return player.getMoney and player.getMoney() or 0
    end

    Framework.RemoveMoney = function(player, amount, account)
        if not player then return false end

        if account == "bank" and player.removeAccountMoney then
            player.removeAccountMoney("bank", amount)
            return true
        end
        if player.removeMoney then
            player.removeMoney(amount)
            return true
        end
        return false
    end

    Framework.AddMoney = function(player, amount, account)
        if not player then return false end

        if account == "bank" and player.addAccountMoney then
            player.addAccountMoney("bank", amount)
            return true
        end
        if player.addMoney then
            player.addMoney(amount)
            return true
        end
        return false
    end

    Framework.NotifyPlayer = function(player, message)
        if not player or not message then return end

        if player.showNotification then
            player.showNotification(message)
        elseif player.source then
            TriggerClientEvent("esx:showNotification", player.source, message)
        end
    end

    ---------------- online players ----------------
    Framework.GetOnlineSources = function()
        local sources = {}
        if ESX.GetExtendedPlayers then
            for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
                sources[#sources + 1] = xPlayer.source
            end
        elseif ESX.GetPlayers then
            for _, src in ipairs(ESX.GetPlayers()) do
                sources[#sources + 1] = src
            end
        end
        return sources
    end

    Framework.GetExtendedPlayers = function()
        local players = {}
        if ESX.GetExtendedPlayers then
            for _, xPlayer in pairs(ESX.GetExtendedPlayers()) do
                players[#players + 1] = xPlayer
            end
        end
        return players
    end

    ---------------- society money (esx_addonaccount tables) ----------------
    local function addonAccountStarted()
        return GetResourceState("esx_addonaccount") == "started"
    end

    -- Make sure the society account rows exist, then call done().
    local function ensureSocietyAccount(accountName, label, done)
        exports.oxmysql:scalar(
            "SELECT 1 FROM addon_account_data WHERE account_name = ? LIMIT 1",
            { accountName },
            function(exists)
                if exists then
                    return done()
                end

                if addonAccountStarted() then
                    pcall(function()
                        exports.esx_addonaccount:AddSharedAccount({
                            name  = accountName,
                            label = label or accountName,
                        }, 0)
                    end)
                end

                exports.oxmysql:execute(
                    "INSERT INTO addon_account (name, label, shared) "
                    .. "SELECT ?, ?, 1 FROM DUAL WHERE NOT EXISTS "
                    .. "(SELECT 1 FROM addon_account WHERE name = ?)",
                    { accountName, label or accountName, accountName },
                    function()
                        exports.oxmysql:execute(
                            "INSERT INTO addon_account_data (account_name, money) "
                            .. "SELECT ?, 0 FROM DUAL WHERE NOT EXISTS "
                            .. "(SELECT 1 FROM addon_account_data WHERE account_name = ?)",
                            { accountName, accountName },
                            function() done() end
                        )
                    end
                )
            end
        )
    end

    local function refreshAddonAccounts()
        if addonAccountStarted() then
            pcall(function()
                TriggerEvent("esx_addonaccount:refreshAccounts")
            end)
        end
    end

    Framework.GetSocietyMoney = function(job, cb)
        local account = "society_" .. job
        exports.oxmysql:scalar(
            "SELECT money FROM addon_account_data WHERE account_name = ? LIMIT 1",
            { account },
            function(money) cb(tonumber(money) or 0) end
        )
    end

    Framework.AddSocietyMoney = function(job, amount, cb)
        local account = "society_" .. job
        ensureSocietyAccount(account, job, function()
            exports.oxmysql:execute(
                "UPDATE addon_account_data SET money = money + ? WHERE account_name = ?",
                { amount, account },
                function()
                    refreshAddonAccounts()
                    if cb then cb(true) end
                end
            )
        end)
    end

    Framework.RemoveSocietyMoney = function(job, amount, cb)
        local account = "society_" .. job
        ensureSocietyAccount(account, job, function()
            exports.oxmysql:execute(
                "UPDATE addon_account_data SET money = money - ? WHERE account_name = ?",
                { amount, account },
                function()
                    refreshAddonAccounts()
                    if cb then cb(true) end
                end
            )
        end)
    end

    Framework.RegisterCallback = function(name, handler)
        ESX.RegisterServerCallback(name, handler)
    end

    Framework.ready = true
    return true
end

--------------------------------------------------------------------
-- Qbox direct-export shim
-- Used when qbx_core's GetCoreObject is unusable: builds a minimal
-- QBCore-like core object on top of qbx_core exports.
--------------------------------------------------------------------
local function buildQbxDirectCore(res)
    local nativeGetPlayers = _G.GetPlayers

    local core = {
        _qbx_direct = true,
        _resName    = res,
    }

    core.Functions = {
        GetPlayer = function(src)
            return exports[res]:GetPlayer(src)
        end,

        GetPlayerByCitizenId = function(citizenId)
            return exports[res]:GetPlayerByCitizenId(citizenId)
        end,

        GetPlayers = function()
            local list = {}
            for _, src in ipairs(nativeGetPlayers()) do
                list[#list + 1] = tonumber(src)
            end
            return list
        end,

        SetJob = function(src, job, grade)
            return exports[res]:SetPlayerPrimaryJob(src, job, grade)
        end,

        RefreshJobs = function() end,
    }

    -- Shared jobs: try a few export shapes, return first table found
    local function tryExport(name, ...)
        local ok, result = pcall(function(...)
            return exports[res][name](exports[res], ...)
        end, ...)
        if ok and type(result) == "table" then
            return result
        end
        return nil
    end

    core.Shared = {
        Jobs = tryExport("GetJobs")
            or tryExport("GetSharedData", "Jobs")
            or tryExport("GetSharedData", "jobs")
            or {},
    }

    return core
end

-- Does this qbx resource answer any of a few harmless exports?
local function probeQbxExports(res)
    for _, exportName in ipairs({ "GetCoreVersion", "GetSharedData", "GetIdentifier" }) do
        local ok, err = pcall(function()
            return exports[res][exportName](exports[res])
        end)

        if ok then
            trace(("%s: %s probe OK"):format(res, exportName))
            return true
        else
            trace(("%s: %s probe failed: %s"):format(res, exportName, tostring(err)))
        end
    end
    return false
end

--------------------------------------------------------------------
-- Society banking: provider catalogue
-- Used by Config.SocietyBanking.provider and /bossmenu_banking
--------------------------------------------------------------------
local bankingProviders = {
    ["tgg-banking"] = {
        resource = "tgg-banking",
        prefix   = "",
        getNames = {
            "GetAccountBalance", "getAccountBalance",
            "GetAccountMoney",   "getAccountMoney",
            "GetAccount",        "getAccount",
            "GetJobAccount",     "getJobAccount",
            "GetSocietyAccount", "getSocietyAccount",
            "GetAccountByName",  "getAccountByName",
        },
        addNames = {
            "AddMoney",        "addMoney",
            "AddAccountMoney", "addAccountMoney",
            "AddJobMoney",     "addJobMoney",
            "AddSocietyMoney", "addSocietyMoney",
        },
        remNames = {
            "RemoveMoney",        "removeMoney",
            "RemoveAccountMoney", "removeAccountMoney",
            "RemoveJobMoney",     "removeJobMoney",
            "RemoveSocietyMoney", "removeSocietyMoney",
        },
    },

    ["qb-banking"] = {
        resource = "qb-banking",
        prefix   = "",
        getNames = { "GetAccountBalance" },
        addNames = { "AddMoney" },
        remNames = { "RemoveMoney" },
    },

    ["renewed-banking"] = {
        resource = "Renewed-Banking",
        prefix   = "",
        getNames = { "getAccountMoney" },
        addNames = { "addAccountMoney" },
        remNames = { "removeAccountMoney" },
    },

    ["qb-management"] = {
        resource = "qb-management",
        prefix   = "",
        getNames = { "GetAccount" },
        addNames = { "AddMoney" },
        remNames = { "RemoveMoney" },
    },
}

-- Account name for a job. Config.SocietyBanking.accountName may contain
-- "{job}"; otherwise it's used as a prefix. Falls back to provider prefix.
local function societyAccountName(job, providerPrefix)
    local cfg = Config and Config.SocietyBanking or nil
    local pattern = cfg and cfg.accountName

    if type(pattern) == "string" and pattern ~= "" then
        if pattern:find("{job}", 1, true) then
            return (pattern:gsub("{job}", job))
        end
        return pattern .. job
    end

    return (providerPrefix or "") .. job
end

-- Safe export call. Returns false, or true + result.
local function callExport(resource, exportName, ...)
    if not exportName or exportName == "" then
        return false
    end
    if GetResourceState(resource) ~= "started" then
        return false
    end

    local args = table.pack(...)
    local ok, result = pcall(function()
        return exports[resource][exportName](exports[resource], table.unpack(args, 1, args.n))
    end)

    if not ok then
        return false
    end
    return true, result
end

-- Pull a numeric balance out of whatever an export returned.
local function extractBalance(value)
    local n = tonumber(value)
    if n then return n end

    if type(value) == "table" then
        for _, key in ipairs({ "balance", "money", "amount", "account_balance" }) do
            local field = tonumber(rawget(value, key))
            if field then return field end
        end
    end
    return nil
end

-- First export name in `names` that answers a call.
local function findWorkingExport(resource, names, ...)
    for _, name in ipairs(names or {}) do
        if callExport(resource, name, ...) then
            return name
        end
    end
    return nil
end

--------------------------------------------------------------------
-- Society banking: Config.SocietyBanking override backend
--------------------------------------------------------------------
local societyOverride        = nil
local societyOverrideResolved = false

local function describeNames(names)
    if type(names) == "table" then
        return "on first use (" .. #names .. " candidates)"
    end
    return tostring(names)
end

-- Returns a { name, get, add, rem } backend, or nil to use the framework default.
local function resolveSocietyOverride()
    if societyOverrideResolved then
        return societyOverride
    end

    local cfg = Config and Config.SocietyBanking or nil
    local provider = cfg and cfg.provider

    local function useDefault()
        societyOverrideResolved = true
        return nil
    end

    if type(provider) ~= "string" or provider == "" then
        return useDefault()
    end

    provider = provider:lower()
    if provider == "auto" or provider == "esx" or provider == "esx_addonaccount" then
        return useDefault()
    end

    local resource, getName, addNames, remNames
    local prefix, reason, amountFirst

    if provider == "custom" then
        local custom = (cfg and cfg.custom) or {}
        resource    = custom.resource
        prefix      = ""
        reason      = custom.reason or REASON
        amountFirst = custom.amountFirst == true

        if type(resource) ~= "string" or resource == "" then
            print(("^1[%s] Config.SocietyBanking.provider is \"custom\" but custom.resource is empty - falling back to auto.^7"):format(RESOURCE_TAG))
            return useDefault()
        end

        getName  = custom.get
        addNames = custom.add
        remNames = custom.remove
    else
        local entry = bankingProviders[provider]
        if not entry then
            print(("^1[%s] Unknown Config.SocietyBanking.provider \"%s\" - falling back to auto.^7"):format(RESOURCE_TAG, provider))
            return useDefault()
        end

        resource    = entry.resource
        prefix      = entry.prefix
        reason      = REASON
        amountFirst = false

        if GetResourceState(resource) ~= "started" then
            print(("^3[%s] Config.SocietyBanking.provider = \"%s\" but resource \"%s\" is not started yet - retrying on next use.^7")
                :format(RESOURCE_TAG, provider, resource))
            return nil -- not marked resolved: retry later
        end

        local probeAccount = societyAccountName("__oxlyn_probe__", prefix)
        getName  = findWorkingExport(resource, entry.getNames, probeAccount)
        addNames = entry.addNames
        remNames = entry.remNames
    end

    if GetResourceState(resource) ~= "started" then
        print(("^3[%s] Society banking resource \"%s\" is not started yet - retrying on next use.^7")
            :format(RESOURCE_TAG, resource))
        return nil
    end

    if not getName or getName == "" then
        print(("^1[%s] \"%s\" is started but no usable balance export was found - falling back to auto. Use Config.SocietyBanking.provider = \"custom\" and name the exports manually.^7")
            :format(RESOURCE_TAG, resource))
        return useDefault()
    end

    -- Argument order for add/remove calls
    local function orderArgs(account, amount)
        if amountFirst then
            return amount, account
        end
        return account, amount
    end

    -- Cache of op ("add"/"remove") -> export name that worked
    local resolvedExports = {}

    local function callMoneyExport(op, candidates, a, b)
        local cached = resolvedExports[op]
        if cached then
            return callExport(resource, cached, a, b, reason)
        end

        local list = (type(candidates) == "table") and candidates or { candidates }
        for _, candidate in ipairs(list) do
            if callExport(resource, candidate, a, b, reason) then
                resolvedExports[op] = candidate
                print(("^2[%s] society %s export on \"%s\": %s^7"):format(RESOURCE_TAG, op, resource, candidate))
                return true
            end
        end

        print(("^1[%s] no working %s export on \"%s\" - the money did NOT move. Set Config.SocietyBanking.provider = \"custom\" and name the export.^7")
            :format(RESOURCE_TAG, op, resource))
        return false
    end

    local backend = { name = resource }

    backend.get = function(job, cb)
        local ok, result = callExport(resource, getName, societyAccountName(job, prefix))
        if not ok then
            return cb(0)
        end
        cb(extractBalance(result) or 0)
    end

    backend.add = function(job, amount, cb)
        local a, b = orderArgs(societyAccountName(job, prefix), amount)
        local ok = callMoneyExport("add", addNames, a, b)
        if cb then cb(ok and true or false) end
    end

    backend.rem = function(job, amount, cb)
        local a, b = orderArgs(societyAccountName(job, prefix), amount)
        local ok = callMoneyExport("remove", remNames, a, b)
        if cb then cb(ok and true or false) end
    end

    societyOverride = backend
    societyOverrideResolved = true

    print(("^2[%s] society money backend (config override): %s [get=%s add=%s rem=%s]^7"):format(
        RESOURCE_TAG,
        resource,
        tostring(getName),
        describeNames(addNames),
        describeNames(remNames)
    ))

    return societyOverride
end

-- Route the framework's society functions through the override (if any).
local function wrapSocietyFunctions()
    if type(Framework.GetSocietyMoney) ~= "function" then return end
    if Framework._societyWrapped then return end
    Framework._societyWrapped = true

    local origGet = Framework.GetSocietyMoney
    local origAdd = Framework.AddSocietyMoney
    local origRem = Framework.RemoveSocietyMoney

    Framework.GetSocietyMoney = function(job, cb)
        local override = resolveSocietyOverride()
        if override then
            return override.get(job, cb)
        end
        return origGet(job, cb)
    end

    Framework.AddSocietyMoney = function(job, amount, cb)
        local override = resolveSocietyOverride()
        if override then
            return override.add(job, amount, cb)
        end
        return origAdd(job, amount, cb)
    end

    Framework.RemoveSocietyMoney = function(job, amount, cb)
        local override = resolveSocietyOverride()
        if override then
            return override.rem(job, amount, cb)
        end
        return origRem(job, amount, cb)
    end
end

--------------------------------------------------------------------
-- Society banking: auto-detected backend for QBCore / Qbox
-- Order: qb-banking -> Renewed-Banking -> qb-management -> management_funds table
--------------------------------------------------------------------
local autoSocietyBackend = nil

-- True if the export call succeeded (no error)
local function exportCallSucceeds(resource, exportName, ...)
    if GetResourceState(resource) ~= "started" then
        return false
    end

    local args = table.pack(...)
    local ok = pcall(function()
        return exports[resource][exportName](exports[resource], table.unpack(args, 1, args.n))
    end)
    return ok
end

local function detectSocietyBackend()
    if autoSocietyBackend then
        return autoSocietyBackend
    end

    local PROBE = "__oxlyn_probe__"

    if exportCallSucceeds("qb-banking", "GetAccountBalance", PROBE) then
        autoSocietyBackend = {
            name = "qb-banking",
            get = function(job, cb)
                cb(tonumber(exports["qb-banking"]:GetAccountBalance(job)) or 0)
            end,
            add = function(job, amount, cb)
                exports["qb-banking"]:AddMoney(job, amount, REASON)
                if cb then cb(true) end
            end,
            rem = function(job, amount, cb)
                exports["qb-banking"]:RemoveMoney(job, amount, REASON)
                if cb then cb(true) end
            end,
        }

    elseif exportCallSucceeds("Renewed-Banking", "getAccountMoney", PROBE) then
        autoSocietyBackend = {
            name = "Renewed-Banking",
            get = function(job, cb)
                cb(tonumber(exports["Renewed-Banking"]:getAccountMoney(job)) or 0)
            end,
            add = function(job, amount, cb)
                exports["Renewed-Banking"]:addAccountMoney(job, amount)
                if cb then cb(true) end
            end,
            rem = function(job, amount, cb)
                exports["Renewed-Banking"]:removeAccountMoney(job, amount)
                if cb then cb(true) end
            end,
        }

    elseif exportCallSucceeds("qb-management", "GetAccount", PROBE) then
        autoSocietyBackend = {
            name = "qb-management",
            get = function(job, cb)
                cb(tonumber(exports["qb-management"]:GetAccount(job)) or 0)
            end,
            add = function(job, amount, cb)
                exports["qb-management"]:AddMoney(job, amount)
                if cb then cb(true) end
            end,
            rem = function(job, amount, cb)
                exports["qb-management"]:RemoveMoney(job, amount)
                if cb then cb(true) end
            end,
        }

    else
        -- Last resort: talk to the management_funds table directly
        -- Table management_funds is pre-created in the production database schema.
        -- Redundant CREATE TABLE DDL has been removed for least-privilege compatibility.
        local function isDatabaseConfirmedReady()
            if type(Framework) ~= "table" then return false end
            if type(Framework.IsDatabaseReady) ~= "function" then return false end
            local ok, ready = pcall(Framework.IsDatabaseReady)
            return ok and ready == true
        end

        autoSocietyBackend = {
            name = "management_funds (direct DB)",

            get = function(job, cb)
                if not isDatabaseConfirmedReady() then
                    if cb then cb(0) end
                    return
                end
                exports.oxmysql:scalar(
                    "SELECT amount FROM management_funds WHERE job_name = ? AND type = 'boss' LIMIT 1",
                    { job },
                    function(amount) cb(tonumber(amount) or 0) end
                )
            end,

            add = function(job, amount, cb)
                if not isDatabaseConfirmedReady() then
                    if cb then cb(false) end
                    return
                end
                exports.oxmysql:execute(
                    "UPDATE management_funds SET amount = amount + ? WHERE job_name = ? AND type = 'boss'",
                    { amount, job },
                    function(result)
                        local affected
                        if type(result) == "table" then
                            affected = result.affectedRows or result.changes
                        end
                        if not affected then
                            affected = tonumber(result) or 0
                        end

                        if affected > 0 then
                            if cb then cb(true) end
                            return
                        end

                        -- No row yet for this job: create it
                        exports.oxmysql:execute(
                            "INSERT INTO management_funds (job_name, amount, type) VALUES (?, ?, 'boss')",
                            { job, amount },
                            function(insResult)
                                local insAffected = 0
                                if type(insResult) == "table" then
                                    insAffected = insResult.affectedRows or insResult.changes
                                end
                                if not insAffected then
                                    insAffected = tonumber(insResult) or 0
                                end
                                if cb then cb(insAffected > 0 or (type(insResult) == "table" and insResult.insertId ~= nil)) end
                            end
                        )
                    end
                )
            end,

            rem = function(job, amount, cb)
                if not isDatabaseConfirmedReady() then
                    if cb then cb(false) end
                    return
                end
                exports.oxmysql:execute(
                    "UPDATE management_funds SET amount = GREATEST(amount - ?, 0) WHERE job_name = ? AND type = 'boss'",
                    { amount, job },
                    function(result)
                        local affected = 0
                        if type(result) == "table" then
                            affected = result.affectedRows or result.changes or 0
                        elseif result ~= nil then
                            affected = tonumber(result) or 0
                        end
                        if cb then cb(result ~= nil and affected >= 0) end
                    end
                )
            end,
        }
    end

    print(("^2[%s] society money backend: %s^7"):format(RESOURCE_TAG, autoSocietyBackend.name))
    return autoSocietyBackend
end

-- Run backend[op] safely; `failValue` is passed to cb if it errors.
local function runSocietyOp(opName, fn, cb, failValue)
    local backend = detectSocietyBackend()

    local done = false
    local function once(...)
        if done then return end
        done = true
        if cb then cb(...) end
    end

    local ok, err = pcall(fn, backend, once)
    if not ok then
        print(("^1[%s] society backend \"%s\" failed on %s: %s^7"):format(
            RESOURCE_TAG, backend.name, opName, tostring(err)))
        once(failValue)
    end
end

--------------------------------------------------------------------
-- QBCore / Qbox
--------------------------------------------------------------------
local function tryQbCore()
    local mode = tostring((Config and Config.Framework) or "auto"):lower()

    local override = nil
    if Config and type(Config.FrameworkResource) == "string" and Config.FrameworkResource ~= "" then
        override = Config.FrameworkResource
    end

    -- Build the list of started candidate resources
    local candidates = {}
    local function addCandidate(resource, kind)
        if GetResourceState(resource) == "started" then
            candidates[#candidates + 1] = { res = resource, kind = kind }
        end
    end

    if override then
        local isQbx = (mode == "qbox" or mode == "qbx")
            or override:lower():find("qbx", 1, true) ~= nil
        addCandidate(override, isQbx and "qbx" or "qb")
    elseif mode == "qbox" or mode == "qbx" then
        addCandidate("qbx_core", "qbx")
    elseif mode == "qbcore" or mode == "qb-core" then
        addCandidate("qb-core", "qb")
    else
        addCandidate("qbx_core", "qbx")
        addCandidate("qb-core", "qb")
    end

    if #candidates == 0 then
        return false
    end

    traceLog = {}

    local core, coreResource

    for _, candidate in ipairs(candidates) do
        local res, kind = candidate.res, candidate.kind

        local obj
        local ok, err = pcall(function()
            obj = exports[res]:GetCoreObject()
        end)

        if not ok then
            trace(("%s: GetCoreObject raised: %s"):format(res, tostring(err)))
        elseif obj == nil then
            trace(("%s: GetCoreObject returned nil (export missing)"):format(res))
        elseif obj.Functions and isCallable(obj.Functions.GetPlayer) then
            core, coreResource = obj, res
            trace(("%s: GetCoreObject OK"):format(res))
            break
        else
            trace(("%s: GetCoreObject shim incomplete (Functions.GetPlayer not callable)"):format(res))
        end

        -- Qbox: GetCoreObject unusable -> synthesize from direct exports
        if kind == "qbx" and probeQbxExports(res) then
            trace(("%s: direct exports OK — synthesizing QBCore-like wrapper"):format(res))
            core = buildQbxDirectCore(res)
            coreResource = res
            break
        end
    end

    if not core then
        return false
    end

    trace(("using backend: %s%s"):format(
        coreResource or "?",
        core._qbx_direct and " (direct exports)" or " (GetCoreObject)"
    ))

    Framework.type = "qbcore"
    Framework.core = core

    ----------------------------------------------------------------
    -- Wrap a QBCore player into the ESX-style object the rest of the
    -- resource expects (getJob / getIdentifier / getMoney / ...).
    ----------------------------------------------------------------
    local function wrapPlayer(qbPlayer)
        if not qbPlayer then return nil end

        local function playerData()
            return qbPlayer.PlayerData
        end

        local wrapped = {
            _raw   = qbPlayer,
            source = qbPlayer.PlayerData and qbPlayer.PlayerData.source,
        }

        function wrapped.getJob()
            local data = playerData()
            local job = (data and data.job) or {}
            local gradeName = job.grade and job.grade.name or nil

            return {
                name        = job.name,
                grade       = job.grade and tonumber(job.grade.level) or 0,
                label       = job.label,
                grade_label = gradeName,
                grade_name  = gradeName,
            }
        end

        function wrapped.getIdentifier()
            local data = playerData()
            return data and data.citizenid or nil
        end

        function wrapped.getName()
            local data = playerData()
            local info = (data and data.charinfo) or {}
            return trim((info.firstname or "") .. " " .. (info.lastname or ""))
        end

        function wrapped.getMoney()
            local data = playerData()
            return data and data.money and data.money.cash or 0
        end

        function wrapped.removeMoney(amount)
            return qbPlayer.Functions
                and qbPlayer.Functions.RemoveMoney("cash", amount, REASON)
        end

        function wrapped.addMoney(amount)
            return qbPlayer.Functions
                and qbPlayer.Functions.AddMoney("cash", amount, REASON)
        end

        function wrapped.setJob(jobName, grade)
            if qbPlayer.Functions and qbPlayer.Functions.SetJob then
                return qbPlayer.Functions.SetJob(jobName, grade)
            end

            if core._qbx_direct then
                local data = playerData()
                local src = data and data.source
                if src then
                    return exports[core._resName or "qbx_core"]:SetPlayerPrimaryJob(src, jobName, grade)
                end
            end
            return false
        end

        -- ESX-style player.get("firstName") / get("lastName")
        function wrapped.get(key)
            local data = playerData()
            local info = (data and data.charinfo) or {}
            if key == "firstName" then return info.firstname end
            if key == "lastName"  then return info.lastname end
            return nil
        end

        function wrapped.getAccount(name)
            local data = playerData()
            local money = (data and data.money) or {}
            return { name = name, money = money[name] or 0 }
        end

        function wrapped.removeAccountMoney(account, amount)
            return qbPlayer.Functions
                and qbPlayer.Functions.RemoveMoney(account, amount, REASON)
        end

        function wrapped.addAccountMoney(account, amount)
            return qbPlayer.Functions
                and qbPlayer.Functions.AddMoney(account, amount, REASON)
        end

        function wrapped.showNotification(message)
            local src = qbPlayer.PlayerData and qbPlayer.PlayerData.source
            if not src or not message then return end

            if core.Functions and isCallable(core.Functions.Notify) then
                core.Functions.Notify(src, message, "primary")
                return
            end

            if core._qbx_direct then
                local okNotify = pcall(function()
                    exports[core._resName or "qbx_core"]:Notify(src, message, "primary")
                end)
                if okNotify then return end
            end

            TriggerClientEvent("QBCore:Notify", src, message, "primary")
        end

        return wrapped
    end

    ---------------- players ----------------
    Framework.GetPlayer = function(src)
        return wrapPlayer(core.Functions.GetPlayer(src))
    end

    Framework.GetPlayerFromId = function(src)
        return Framework.GetPlayer(src)
    end

    Framework.GetPlayerByIdentifier = function(identifier)
        local getByCitizenId = core.Functions and core.Functions.GetPlayerByCitizenId
        if not getByCitizenId then return nil end

        local okCall, player = pcall(getByCitizenId, identifier)
        if not okCall then return nil end
        return wrapPlayer(player)
    end

    Framework.GetAdminGroups = function(src)
        local groups = {}
        local getPermission = core.Functions and core.Functions.GetPermission

        if getPermission then
            local okCall, result = pcall(getPermission, src)
            if okCall then
                if type(result) == "string" then
                    groups[#groups + 1] = result
                elseif type(result) == "table" then
                    for name, enabled in pairs(result) do
                        if enabled then
                            groups[#groups + 1] = name
                        end
                    end
                end
            end
        end

        return groups
    end

    Framework.GetIdentifier = function(player)
        return player and player.getIdentifier and player.getIdentifier() or nil
    end

    Framework.GetName = function(player)
        return player and player.getName and player.getName() or "Employee"
    end

    Framework.GetJob = function(player)
        return player and player.getJob and player.getJob() or nil
    end

    ---------------- money ----------------
    Framework.GetMoney = function(player, account)
        if not player then return 0 end

        if account and account ~= "cash" and player.getAccount then
            local acc = player.getAccount(account)
            return acc and acc.money or 0
        end

        return player.getMoney and player.getMoney() or 0
    end

    Framework.RemoveMoney = function(player, amount, account)
        if not player then return false end

        if account and account ~= "cash" and player.removeAccountMoney then
            return player.removeAccountMoney(account, amount) ~= false
        end

        local result = player.removeMoney and player.removeMoney(amount)
        return result ~= false
    end

    Framework.AddMoney = function(player, amount, account)
        if not player then return false end

        if account and account ~= "cash" and player.addAccountMoney then
            return player.addAccountMoney(account, amount) ~= false
        end

        local result = player.addMoney and player.addMoney(amount)
        return result ~= false
    end

    Framework.SetJob = function(player, jobName, grade)
        if not player then return false end
        if player.setJob then
            return player.setJob(jobName, grade)
        end
        return false
    end

    ---------------- online players ----------------
    Framework.GetOnlineSources = function()
        if core.Functions.GetPlayers then
            return core.Functions.GetPlayers()
        end
        return {}
    end

    Framework.GetExtendedPlayers = function()
        local players = {}
        if core.Functions.GetPlayers then
            for _, src in ipairs(core.Functions.GetPlayers()) do
                local wrapped = wrapPlayer(core.Functions.GetPlayer(src))
                if wrapped then
                    players[#players + 1] = wrapped
                end
            end
        end
        return players
    end

    ---------------- society money ----------------
    Framework.GetSocietyMoney = function(job, cb)
        runSocietyOp("get", function(backend, once)
            backend.get(job, once)
        end, cb, 0)
    end

    Framework.AddSocietyMoney = function(job, amount, cb)
        runSocietyOp("add", function(backend, once)
            backend.add(job, amount, once)
        end, cb, false)
    end

    Framework.RemoveSocietyMoney = function(job, amount, cb)
        runSocietyOp("rem", function(backend, once)
            backend.rem(job, amount, once)
        end, cb, false)
    end

    ---------------- callbacks ----------------
    if core.Functions and isCallable(core.Functions.CreateCallback) then
        Framework.RegisterCallback = function(name, handler)
            core.Functions.CreateCallback(name, handler)
        end
    else
        Framework.RegisterCallback = function(name, handler)
            registerFallbackCallback(name, handler)
        end
    end

    Framework.ready = true
    return true
end

--------------------------------------------------------------------
-- /bossmenu_banking  (console only)
--   bossmenu_banking                -> print current society banking setup
--   bossmenu_banking <res> [job]    -> probe a banking resource's exports
--------------------------------------------------------------------
RegisterCommand("bossmenu_banking", function(src, args)
    if src ~= 0 then return end

    local resource = args[1]
    local job      = args[2]

    if not resource then
        local cfg = Config and Config.SocietyBanking or nil
        local active = resolveSocietyOverride()

        print("^5[" .. RESOURCE_TAG .. "] society banking^7")
        print(("  framework          : %s"):format(tostring(Framework.type)))
        print(("  config provider    : %s"):format(tostring((cfg and cfg.provider) or "auto")))
        print(("  config accountName : %s"):format(tostring((cfg and cfg.accountName) or "(provider default)")))
        print(("  active backend     : %s"):format(
            (active and active.name) or "framework default (see the \"society money backend:\" line above)"))
        print("  Tip: bossmenu_banking <resource> [job]  probes a banking resource for usable exports.")
        return
    end

    if GetResourceState(resource) ~= "started" then
        print(("^1[%s] resource \"%s\" is not started (state: %s).^7"):format(
            RESOURCE_TAG, resource, GetResourceState(resource)))
        return
    end

    -- Collect every candidate balance-export name (deduplicated)
    local seen, names = {}, {}
    local function addName(name)
        if type(name) == "string" and name ~= "" and not seen[name] then
            seen[name] = true
            names[#names + 1] = name
        end
    end

    for _, entry in pairs(bankingProviders) do
        for _, name in ipairs(entry.getNames) do
            addName(name)
        end
    end

    local custom = (Config and Config.SocietyBanking and Config.SocietyBanking.custom) or {}
    addName(custom.get)

    local account = job and societyAccountName(job, "") or "__oxlyn_probe__"

    print(("^5[%s] probing \"%s\" with account \"%s\" (read-only calls)^7"):format(RESOURCE_TAG, resource, account))

    local hits = 0
    for _, name in ipairs(names) do
        local ok, result = callExport(resource, name, account)
        if ok then
            hits = hits + 1
            local balance = extractBalance(result)
            print(("  ^2OK^7  %-24s -> %s%s"):format(
                name,
                type(result),
                balance and (" (balance " .. tostring(balance) .. ")") or ""
            ))
        end
    end

    if hits == 0 then
        print("  ^1no balance export answered.^7 The names differ on this build - open the resource's server files and look for exports('...') lines.")
    else
        print("  Put a working name above into Config.SocietyBanking.custom.get.")
    end

    print("  ^3Money-moving exports are NOT probed^7 (a probe call would write a real transaction).")
    print("  Name them yourself in Config.SocietyBanking.custom.add / .remove - usually the")
    print("  matching pair of the getter, e.g. GetAccountBalance -> AddMoney / RemoveMoney.")
end, true)

--------------------------------------------------------------------
-- Detection entry point (respects Config.Framework)
--------------------------------------------------------------------
local function detectFramework()
    local mode = tostring((Config and Config.Framework) or "auto"):lower()

    local found
    if mode == "esx" then
        found = tryEsx()
    elseif mode == "qbcore" or mode == "qb-core" or mode == "qbx" or mode == "qbox" then
        found = tryQbCore()
    else
        found = tryEsx() or tryQbCore()
    end

    if found then
        wrapSocietyFunctions()
    end

    return found and true or false
end

--------------------------------------------------------------------
-- Boot: wait for Config, then retry detection for up to 30s
--------------------------------------------------------------------
CreateThread(function()
    while not Config do
        Wait(50)
    end

    local waited = 0
    while not Framework.ready and waited < 30000 do
        if detectFramework() then
            print(("^2[%s] Framework detected: %s (server)^7"):format(RESOURCE_TAG, Framework.type))
            traceLog = {}
            return
        end
        Wait(500)
        waited = waited + 500
    end

    if not Framework.ready then
        print(("^1[%s] No framework detected after 30s on server. States:^7"):format(RESOURCE_TAG))
        print("^1  es_extended = " .. tostring(GetResourceState("es_extended")) .. "^7")
        print("^1  qb-core     = " .. tostring(GetResourceState("qb-core")) .. "^7")
        print("^1  qbx_core    = " .. tostring(GetResourceState("qbx_core")) .. "^7")
        print(("^1  Solution: make sure es_extended (or qb-core / qbx_core) is ensured in server.cfg BEFORE %s.^7"):format(RESOURCE_TAG))
        flushTrace()
    end
end)

--------------------------------------------------------------------
-- Late detection: if a framework resource starts after us
--------------------------------------------------------------------
AddEventHandler("onResourceStart", function(resourceName)
    if Framework.ready then return end

    local override = Config and Config.FrameworkResource

    if resourceName == "es_extended"
        or resourceName == "qb-core"
        or resourceName == "qbx_core"
        or resourceName == override then

        Wait(200)
        if detectFramework() then
            print(("^2[%s] Framework detected server-side (after %s started): %s^7"):format(
                RESOURCE_TAG, resourceName, Framework.type))
        end
    end
end)

