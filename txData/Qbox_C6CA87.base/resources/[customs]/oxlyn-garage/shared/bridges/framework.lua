

Framework = Framework or {}
Framework.Name = nil   -- "esx" | "qbcore" | "qbox" | nil (standalone)
Framework.Core = nil
Framework.Ready = false

local resourceName = GetCurrentResourceName()
local isServer = IsDuplicityVersion()

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

local function isStarted(resource)
    return GetResourceState(resource) == "started"
end

local function debugPrint(message)
    if Config and Config.Debug then
        print(("[%s] %s"):format(resourceName, message))
    end
end

---------------------------------------------------------------------
-- Framework detection
---------------------------------------------------------------------

local function detectQbox()
    if not isStarted("qbx_core") then
        return false
    end
    Framework.Name = "qbox"
    Framework.Core = exports.qbx_core
    return true
end

local function detectQbcore()
    if not isStarted("qb-core") then
        return false
    end

    local core
    pcall(function()
        core = exports["qb-core"]:GetCoreObject()
    end)

    if not core then
        return false
    end

    Framework.Name = "qbcore"
    Framework.Core = core
    return true
end

local function detectEsx()
    if not isStarted("es_extended") then
        return false
    end

    local core
    pcall(function()
        core = exports.es_extended:getSharedObject()
    end)

    -- legacy fallback
    if not core then
        pcall(function()
            TriggerEvent("esx:getSharedObject", function(obj)
                core = obj
            end)
        end)
    end

    if not core then
        return false
    end

    Framework.Name = "esx"
    Framework.Core = core
    return true
end

local function detectFramework()
    local mode = (Config and Config.Framework) or "auto"

    if mode == "standalone" then
        Framework.Name = nil
        Framework.Core = nil
        return true
    end

    if mode == "esx" then return detectEsx() end
    if mode == "qbcore" then return detectQbcore() end
    if mode == "qbox" then return detectQbox() end

    -- auto: qbox -> qbcore -> esx
    return detectQbox() or detectQbcore() or detectEsx()
end

CreateThread(function()
    local attempts = 0

    while not Framework.Ready and attempts < 80 do
        if detectFramework() then
            Framework.Ready = true
            debugPrint(("Framework detected: %s"):format(Framework.Name or "standalone"))
            break
        end
        attempts = attempts + 1
        Wait(250)
    end

    if not Framework.Ready then
        Framework.Ready = true
        print(("[%s] ^3No framework detected — running standalone (garages work, ownership queries will find nothing).^7"):format(resourceName))
    end
end)

-- Blocks until the framework is ready (max 20s). Returns Framework.Ready.
function Framework.Wait()
    local waited = 0
    while not Framework.Ready and waited < 20000 do
        Wait(100)
        waited = waited + 100
    end
    return Framework.Ready
end

local function getQbFunctions()
    if type(Framework.Core) ~= "table" then
        return nil
    end

    local ok, functions = pcall(function()
        return Framework.Core.Functions
    end)

    if ok and type(functions) == "table" then
        return functions
    end
    return nil
end

---------------------------------------------------------------------
-- SERVER
---------------------------------------------------------------------

if isServer then

    function Framework.GetPlayer(src)
        if not (Framework.Core and src) or src == 0 then
            return nil
        end

        local ok, player = pcall(function()
            if Framework.Name == "esx" then
                return Framework.Core.GetPlayerFromId(src)
            elseif Framework.Name == "qbox" then
                return Framework.Core:GetPlayer(src)
            elseif Framework.Name == "qbcore" then
                return Framework.Core.Functions.GetPlayer(src)
            end
        end)

        if ok and player then
            return player
        end
        return nil
    end

    -- Persistent character identifier (ESX identifier / QB citizenid),
    -- falling back to the license, then to "src:<id>".
    function Framework.GetIdentifier(src)
        local player = Framework.GetPlayer(src)

        if player then
            if Framework.Name == "esx" then
                local id = (player.getIdentifier and player.getIdentifier()) or player.identifier
                if id then
                    return id
                end
            else
                local id = player.PlayerData and player.PlayerData.citizenid
                if id then
                    return id
                end
            end
        end

        return GetPlayerIdentifierByType(src, "license") or ("src:%s"):format(src)
    end

    function Framework.GetLicense(src)
        local player = Framework.GetPlayer(src)

        if player and player.PlayerData and player.PlayerData.license then
            return player.PlayerData.license
        end

        return GetPlayerIdentifierByType(src, "license") or ""
    end

    -- Standalone counts as always loaded.
    function Framework.IsLoaded(src)
        if not Framework.Name then
            return true
        end
        return Framework.GetPlayer(src) ~= nil
    end

    function Framework.GetName(src)
        local player = Framework.GetPlayer(src)

        if player then
            local ok, name = pcall(function()
                if Framework.Name == "esx" then
                    return (player.getName and player.getName()) or player.name
                end

                local charinfo = player.PlayerData and player.PlayerData.charinfo
                if charinfo then
                    local full = ("%s %s"):format(charinfo.firstname or "", charinfo.lastname or "")
                    if (full:gsub("%s", "")) ~= "" then
                        return full
                    end
                end
            end)

            if ok and name and name ~= "" then
                return name
            end
        end

        return GetPlayerName(src) or ("Player %s"):format(src)
    end

    -- Returns { name, grade, onDuty } or nil
    function Framework.GetJob(src)
        local player = Framework.GetPlayer(src)
        if not player then
            return nil
        end

        local ok, result = pcall(function()
            if Framework.Name == "esx" then
                local job = (player.getJob and player.getJob()) or player.job
                if not job then
                    return nil
                end
                return {
                    name = tostring(job.name or ""):lower(),
                    grade = tonumber(job.grade) or 0,
                    onDuty = job.onDuty ~= false,
                }
            end

            local job = player.PlayerData and player.PlayerData.job
            if not job then
                return nil
            end

            local grade = (type(job.grade) == "table" and job.grade.level) or job.grade
            return {
                name = tostring(job.name or ""):lower(),
                grade = tonumber(grade) or 0,
                onDuty = job.onduty ~= false,
            }
        end)

        if ok and result then
            return result
        end
        return nil
    end

    -- Returns { name, grade } or nil (QB/Qbox only; ESX has no gangs)
    function Framework.GetGang(src)
        local player = Framework.GetPlayer(src)
        if not player or Framework.Name == "esx" then
            return nil
        end

        local ok, result = pcall(function()
            local gang = player.PlayerData and player.PlayerData.gang
            if not (gang and gang.name and gang.name ~= "none") then
                return nil
            end

            local grade = (type(gang.grade) == "table" and gang.grade.level) or gang.grade
            return {
                name = tostring(gang.name):lower(),
                grade = tonumber(grade) or 0,
            }
        end)

        if ok and result then
            return result
        end
        return nil
    end

    -- Permission group ("user" if unknown)
    function Framework.GetGroup(src)
        local player = Framework.GetPlayer(src)
        if not player then
            return "user"
        end

        local ok, group = pcall(function()
            if Framework.Name == "esx" then
                return (player.getGroup and player.getGroup()) or player.group
            end
            return player.PlayerData and player.PlayerData.permission
        end)

        if ok and group then
            return tostring(group)
        end
        return "user"
    end

    -- Online player source for a persistent identifier, or nil
    function Framework.GetPlayerByIdentifier(identifier)
        if not identifier or not Framework.Core then
            return nil
        end

        local ok, result = pcall(function()
            if Framework.Name == "esx" then
                local player = Framework.Core.GetPlayerFromIdentifier(identifier)
                return player and player.source
            elseif Framework.Name == "qbcore" then
                local player = Framework.Core.Functions.GetPlayerByCitizenId(identifier)
                return player and player.PlayerData and player.PlayerData.source
            elseif Framework.Name == "qbox" then
                local player = Framework.Core:GetPlayerByCitizenId(identifier)
                return player and player.PlayerData and player.PlayerData.source
            end
        end)

        if ok then
            return tonumber(result)
        end
        return nil
    end

    ---------------------------------------------------------------
    -- Money
    ---------------------------------------------------------------

    -- Maps "cash"/"bank" to the framework's account name
    function Framework.MoneyAccount(account)
        if account == "cash" then
            return Framework.Name == "esx" and "money" or "cash"
        end
        return "bank"
    end

    function Framework.GetMoney(src, account)
        local player = Framework.GetPlayer(src)
        if not player then
            return 0
        end

        local accountName = Framework.MoneyAccount(account == "cash" and "cash" or "bank")

        local ok, balance = pcall(function()
            if Framework.Name == "esx" then
                local acc = player.getAccount(accountName)
                return acc and acc.money or 0
            elseif Framework.Name == "qbox" then
                local okExport, value = pcall(function()
                    return Framework.Core:GetMoney(src, accountName)
                end)
                if okExport and value ~= nil then
                    return value
                end
                return player.PlayerData.money[accountName]
            end

            return player.PlayerData.money[accountName]
        end)

        return (ok and tonumber(balance)) or 0
    end

    function Framework.RemoveMoney(src, account, amount, reason)
        amount = math.floor(tonumber(amount) or 0)

        if amount < 0 then return false end
        if amount == 0 then return true end

        local player = Framework.GetPlayer(src)
        if not player then
            return false
        end

        if amount > Framework.GetMoney(src, account) then
            return false
        end

        local accountName = Framework.MoneyAccount(account == "cash" and "cash" or "bank")

        if Framework.Name == "esx" then
            return (pcall(function()
                player.removeAccountMoney(accountName, amount, reason or resourceName)
            end))
        end

        if Framework.Name == "qbox" then
            local ok, result = pcall(function()
                return Framework.Core:RemoveMoney(src, accountName, amount, reason or resourceName)
            end)
            if ok then
                return result ~= false
            end
        end

        -- qbcore (and qbox fallback)
        local ok, result = pcall(function()
            return player.Functions.RemoveMoney(accountName, amount, reason or resourceName)
        end)
        return ok and result ~= false
    end

    function Framework.AddMoney(src, account, amount, reason)
        amount = math.floor(tonumber(amount) or 0)

        if amount <= 0 then
            return amount == 0
        end

        local player = Framework.GetPlayer(src)
        if not player then
            return false
        end

        local accountName = Framework.MoneyAccount(account == "cash" and "cash" or "bank")

        if Framework.Name == "esx" then
            return (pcall(function()
                player.addAccountMoney(accountName, amount, reason or resourceName)
            end))
        end

        if Framework.Name == "qbox" then
            local ok, result = pcall(function()
                return Framework.Core:AddMoney(src, accountName, amount, reason or resourceName)
            end)
            if ok then
                return result ~= false
            end
        end

        -- qbcore (and qbox fallback)
        local ok, result = pcall(function()
            return player.Functions.AddMoney(accountName, amount, reason or resourceName)
        end)
        return ok and result ~= false
    end

    ---------------------------------------------------------------
    -- Permissions
    ---------------------------------------------------------------

    -- All of a player's identifiers, lowercased
    local function identifiersOf(src)
        local list = {}
        for i = 0, GetNumPlayerIdentifiers(src) - 1 do
            local identifier = GetPlayerIdentifier(src, i)
            if identifier then
                list[#list + 1] = identifier:lower()
            end
        end
        return list
    end
    Framework.IdentifiersOf = identifiersOf

    function Framework.HasAce(src, ace)
        if not ace or ace == "" then
            return false
        end
        return IsPlayerAceAllowed(src, ace)
    end

    -- Returns true, matchedGroup (or matched ace) / false
    function Framework.HasGroup(src, groups, checkAces)
        if type(groups) == "string" then
            groups = { groups }
        end
        if type(groups) ~= "table" then
            return false
        end

        local current = Framework.GetGroup(src)
        local acePrefixes = { "group.", "qbcore.", "qbx.", "esx." }

        for _, group in ipairs(groups) do
            if current == group then
                return true, group
            end

            if checkAces ~= false then
                for _, prefix in ipairs(acePrefixes) do
                    if IsPlayerAceAllowed(src, prefix .. group) then
                        return true, prefix .. group
                    end
                end
            end

            if Framework.Name == "qbcore" then
                local qb = getQbFunctions()
                if qb and qb.HasPermission then
                    local ok, has = pcall(qb.HasPermission, src, group)
                    if ok and has then
                        return true, group
                    end
                end
            elseif Framework.Name == "qbox" then
                local ok, has = pcall(function()
                    return Framework.Core:HasPermission(src, group)
                end)
                if ok and has then
                    return true, group
                end
            end
        end

        return false
    end

    -- jobs: map/list of jobName -> minGrade (normalized by Utils.JobMap)
    -- Returns true, jobName / false / false, "offduty"
    function Framework.HasJob(src, jobs, requireOnDuty)
        jobs = Utils.JobMap(jobs)
        if next(jobs) == nil then
            return false
        end

        local job = Framework.GetJob(src)
        if not job then
            return false
        end

        local minGrade = jobs[job.name]
        if minGrade == nil then
            return false
        end
        if minGrade > job.grade then
            return false
        end

        if requireOnDuty and not job.onDuty then
            return false, "offduty"
        end

        return true, job.name
    end

    function Framework.HasGang(src, gangs)
        local list = Utils.StringList(gangs)
        if #list == 0 then
            return false
        end

        local gang = Framework.GetGang(src)
        if not gang then
            return false
        end

        for _, name in ipairs(list) do
            if name:lower() == gang.name then
                return true, name
            end
        end

        return false
    end

    ---------------------------------------------------------------
    -- Admin evaluation
    ---------------------------------------------------------------

    local DEFAULT_ADMIN_CONFIG = {
        everyone = false,
        methods = { "ace", "group", "identifier" },
        aces = { "oxlyn.garage.admin" },
        groupAces = true,
        groups = { "admin", "superadmin", "god" },
        jobs = {},
        jobOnDuty = false,
        identifiers = {},
        allowConsole = true,
    }

    local function getAdminConfig()
        local cfg = Config and Config.Admin
        if type(cfg) ~= "table" then
            return DEFAULT_ADMIN_CONFIG
        end
        return cfg
    end

    -- Returns allowed (bool), via (string), trace (list of { source, verdict, note })
    function Framework.Evaluate(src, cfg)
        local trace = {}

        local function note(source, allowed, text)
            trace[#trace + 1] = {
                source = source,
                verdict = allowed and "ALLOW" or "deny",
                note = text or "",
            }
        end

        src = tonumber(src) or 0
        if type(cfg) ~= "table" then
            cfg = {}
        end

        -- server console
        if src == 0 then
            if cfg.allowConsole ~= false then
                note("console", true, "server console")
                return true, "console", trace
            end
            note("console", false, "allowConsole = false")
            return false, "console", trace
        end

        -- custom hook: true/false is final, nil/error falls through
        if type(cfg.check) == "function" then
            local ok, result = pcall(cfg.check, src)

            if ok and result == true then
                note("hook", true, "check() returned true")
                return true, "hook", trace
            end
            if ok and result == false then
                note("hook", false, "check() returned false")
                return false, "hook", trace
            end

            note("hook", false, ok and "check() returned nil — fell through"
                or ("check() errored: " .. tostring(result)))
        end

        if cfg.everyone == true then
            note("everyone", true, "everyone = true")
            return true, "everyone", trace
        end

        local methods = {}
        for _, method in ipairs(cfg.methods or {}) do
            methods[tostring(method):lower()] = true
        end

        -- ACE
        if methods.ace then
            local tested = {}
            for _, ace in ipairs(cfg.aces or {}) do
                tested[#tested + 1] = ace
                if IsPlayerAceAllowed(src, ace) then
                    note("ace", true, ace)
                    return true, "ace", trace
                end
            end
            note("ace", false, #tested > 0 and ("tested " .. table.concat(tested, ", ")) or "no aces configured")
        end

        -- group
        if methods.group then
            local ok, matched = Framework.HasGroup(src, cfg.groups or {}, cfg.groupAces ~= false)
            if ok then
                note("group", true, matched)
                return true, "group", trace
            end
            note("group", false, ('current group "%s"'):format(Framework.GetGroup(src)))
        end

        -- job
        if methods.job then
            local ok, detail = Framework.HasJob(src, cfg.jobs, cfg.jobOnDuty == true)
            if ok then
                note("job", true, detail)
                return true, "job", trace
            end

            local job = Framework.GetJob(src)
            note("job", false, detail == "offduty" and "off duty"
                or ('current job "%s" grade %s'):format(job and job.name or "-", job and job.grade or "-"))
        end

        -- identifier
        if methods.identifier then
            local playerIds = identifiersOf(src)
            for _, configured in ipairs(cfg.identifiers or {}) do
                local wanted = tostring(configured):lower()
                for _, id in ipairs(playerIds) do
                    if id == wanted then
                        note("identifier", true, configured)
                        return true, "identifier", trace
                    end
                end
            end
            note("identifier", false, #(cfg.identifiers or {}) > 0 and "none matched" or "no identifiers configured")
        end

        return false, "none", trace
    end

    function Framework.EvaluateAdmin(src)
        local allowed, via, trace = Framework.Evaluate(src, getAdminConfig())

        if getAdminConfig().debug then
            print(("[%s] admin check for %s → %s (%s)"):format(
                resourceName, tostring(src), allowed and "ALLOW" or "DENY", via
            ))
        end

        return allowed, via, trace
    end

    function Framework.IsAdmin(src)
        return (Framework.EvaluateAdmin(src))
    end

    ---------------------------------------------------------------
    -- Notifications
    ---------------------------------------------------------------

    function Framework.Notify(src, data, notifyType)
        -- console / invalid source: just print
        if not src or src == 0 then
            print(("[%s] %s"):format(
                resourceName,
                type(data) == "table" and tostring(data.message) or tostring(data)
            ))
            return
        end

        if type(data) == "string" then
            data = { message = data, type = notifyType or "info" }
        end

        data.type = notifyType or data.type or "info"

        TriggerClientEvent(resourceName .. ":client:notify", src, data)
    end

    ---------------------------------------------------------------
    -- Server callbacks
    ---------------------------------------------------------------

    local callbacks = {}

    function Framework.RegisterCallback(name, handler)
        callbacks[name] = handler
    end

    RegisterNetEvent(resourceName .. ":cb:request", function(name, requestId, args)
        local src = source
        local handler = callbacks[name]
        local responded = false

        -- can only be answered once
        local function reply(...)
            if responded then
                return
            end
            responded = true
            TriggerClientEvent(resourceName .. ":cb:response", src, requestId, { ... })
        end

        if not handler then
            return reply(nil)
        end

        local ok, err = pcall(handler, src, reply, table.unpack(args or {}))
        if not ok then
            print(("[%s] ^1callback \"%s\" errored: %s^7"):format(resourceName, tostring(name), tostring(err)))
            reply(nil)
        end
    end)

    ---------------------------------------------------------------
    -- Usable items / player loaded
    ---------------------------------------------------------------

    -- handler(src, slot, metadata)
    function Framework.RegisterUsableItem(item, handler)
        if not Framework.Core or not item then
            return false
        end

        return (pcall(function()
            if Framework.Name == "esx" then
                Framework.Core.RegisterUsableItem(item, function(src, _, data)
                    handler(
                        src,
                        type(data) == "table" and data.slot or nil,
                        type(data) == "table" and data.metadata or nil
                    )
                end)
            elseif Framework.Name == "qbcore" then
                Framework.Core.Functions.CreateUseableItem(item, function(src, itemData)
                    handler(
                        src,
                        type(itemData) == "table" and itemData.slot or nil,
                        type(itemData) == "table" and (itemData.info or itemData.metadata) or nil
                    )
                end)
            elseif Framework.Name == "qbox" then
                Framework.Core:CreateUseableItem(item, function(src, itemData)
                    handler(
                        src,
                        type(itemData) == "table" and itemData.slot or nil,
                        type(itemData) == "table" and (itemData.info or itemData.metadata) or nil
                    )
                end)
            end
        end))
    end

    -- handler(src): fires when a player's character has loaded (any framework)
    function Framework.OnPlayerLoaded(handler)
        AddEventHandler("esx:playerLoaded", function(playerId)
            handler(tonumber(playerId))
        end)

        local function onQbLoaded(player)
            local src = (type(player) == "table" and player.PlayerData and player.PlayerData.source) or source
            if tonumber(src) then
                handler(tonumber(src))
            end
        end

        RegisterNetEvent("QBCore:Server:PlayerLoaded", onQbLoaded)
        RegisterNetEvent("qbx_core:server:playerLoaded", onQbLoaded)
    end

---------------------------------------------------------------------
-- CLIENT
---------------------------------------------------------------------

else

    local function getPlayerData()
        if not Framework.Core then
            return nil
        end

        local ok, data = pcall(function()
            if Framework.Name == "esx" then
                return Framework.Core.GetPlayerData()
            elseif Framework.Name == "qbcore" then
                return Framework.Core.Functions.GetPlayerData()
            elseif Framework.Name == "qbox" then
                return Framework.Core:GetPlayerData()
            end
        end)

        if ok and data then
            return data
        end
        return nil
    end

    -- Returns { name, grade, onDuty } or nil
    function Framework.GetJob()
        local data = getPlayerData()
        local job = data and data.job
        if not job then
            return nil
        end

        local grade = (type(job.grade) == "table" and job.grade.level) or job.grade

        return {
            name = tostring(job.name or ""):lower(),
            grade = tonumber(grade) or 0,
            onDuty = job.onDuty ~= false,
        }
    end

    -- Returns { name } or nil
    function Framework.GetGang()
        local data = getPlayerData()
        local gang = data and data.gang

        if not (gang and gang.name and gang.name ~= "none") then
            return nil
        end

        return { name = tostring(gang.name):lower() }
    end

    -- handler() is called (after a short delay) whenever job/gang/duty/load events fire
    function Framework.OnGroupsChanged(handler)
        local function trigger()
            SetTimeout(50, handler)
        end

        local events = {
            "esx:setJob",
            "QBCore:Client:OnJobUpdate",
            "QBCore:Client:OnGangUpdate",
            "QBCore:Client:SetDuty",
            "QBCore:Client:OnPlayerLoaded",
            "esx:playerLoaded",
            "qbx_core:client:onJobUpdate",
            "qbx_core:client:onGangUpdate",
        }

        for _, event in ipairs(events) do
            RegisterNetEvent(event, trigger)
        end
    end

    -- Notification using the best available system:
    -- ox_lib -> okokNotify -> framework native -> chat message
    function Framework.BridgeNotify(message, notifyType, title)
        notifyType = notifyType or "info"
        message = tostring(message or "")

        if message == "" then
            return
        end

        if isStarted("ox_lib") then
            local ok = pcall(function()
                local mapped = "inform"
                if notifyType == "error" or notifyType == "success" or notifyType == "warning" then
                    mapped = notifyType
                end

                exports.ox_lib:notify({
                    title = title,
                    description = message,
                    type = mapped,
                })
            end)
            if ok then
                return
            end
        end

        if isStarted("okokNotify") then
            local ok = pcall(function()
                exports.okokNotify:Alert(title or "Garage", message, 5000, notifyType)
            end)
            if ok then
                return
            end
        end

        if Framework.Name == "esx" then
            if Framework.Core then
                local ok = pcall(function()
                    Framework.Core.ShowNotification(message)
                end)
                if ok then
                    return
                end
            end
        elseif Framework.Name == "qbcore" then
            if Framework.Core then
                local ok = pcall(function()
                    Framework.Core.Functions.Notify(message, notifyType)
                end)
                if ok then
                    return
                end
            end
        elseif Framework.Name == "qbox" then
            local ok = pcall(function()
                exports.qbx_core:Notify(message, notifyType)
            end)
            if ok then
                return
            end
        end

        TriggerEvent("chat:addMessage", { args = { "^3Garage", message } })
    end

    ---------------------------------------------------------------
    -- Client callbacks
    ---------------------------------------------------------------

    local pending = {}
    local nextRequestId = 0

    -- cb(...) is called with the server's reply, or cb(nil) after 15s timeout
    function Framework.TriggerCallback(name, cb, ...)
        nextRequestId = nextRequestId + 1
        local requestId = nextRequestId

        pending[requestId] = cb
        TriggerServerEvent(resourceName .. ":cb:request", name, requestId, { ... })

        SetTimeout(15000, function()
            if pending[requestId] then
                pending[requestId] = nil
                if cb then
                    cb(nil)
                end
            end
        end)
    end

    -- Blocking version: returns the server's reply values
    function Framework.Await(name, ...)
        local p = promise.new()

        Framework.TriggerCallback(name, function(...)
            p:resolve({ ... })
        end, ...)

        local result = Citizen.Await(p)
        return table.unpack(result)
    end

    RegisterNetEvent(resourceName .. ":cb:response", function(requestId, args)
        local cb = pending[requestId]
        if not cb then
            return
        end

        pending[requestId] = nil
        cb(table.unpack(args or {}))
    end)
end

