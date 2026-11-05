

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN-HANDLING  •  shared/bridges/framework.lua
--  Auto-detects ESX / QBCore / Qbox and exposes ONE uniform API. The rest of
--  the resource never talks to a framework directly — only through `Framework`.
--
--  Ships a self-contained server<->client callback system (no ox_lib / no
--  framework callbacks required) and the permission gate.
--
--  ── PERMISSIONS ────────────────────────────────────────────────────────
--  The gate is a UNION (OR) of independent sources, like the rest of the
--  OXLYN series. ANY source saying yes grants access; a missing framework
--  degrades to "deny", never to an error.
--
--    0. hook        Config.Admin.check(src) / OxlynHandlingHooks.IsAdmin(src)
--                   → true/false short-circuits, nil falls through
--    1. console     server console (src == 0) when Config.Admin.allowConsole
--    2. everyone    Config.Admin.everyone == true (TESTING ONLY)
--    3. ace         Config.Admin.aces, PLUS the universal bridge aces
--                   group.<g> / qbcore.<g> / qbx.<g> / esx.<g> for every
--                   configured group. These ACE objects require an ACL grant;
--                   joining a principal alone does not grant an ACE object.
--    4. group       ESX getGroup() / QBCore HasPermission / Qbox HasPermission
--    5. job         Config.Admin.jobs = { jobname = minGrade }
--    6. identifier  Config.Admin.identifiers (license:/steam:/discord:/fivem:)
--
--  Every check is pcall-guarded. `Framework.EvaluateAdmin(src)` returns the
--  full per-source report that /handlingaccess prints.
-- ════════════════════════════════════════════════════════════════════════

Framework = Framework or {}
Framework.Name = nil          -- 'esx' | 'qbcore' | 'qbox' | nil
Framework.Core = nil
Framework.Ready = false
Framework.Generation = 0     -- invalidates cached player data on core changes

local IS_SERVER = IsDuplicityVersion()
local resourceKinds = { es_extended = 'esx', ['qb-core'] = 'qbcore', qbx_core = 'qbox' }
local stoppedResources = {}
local function res(name)
    return not stoppedResources[name] and GetResourceState(name) == 'started'
end

-- ════════════════════════════════════════════════════════════════════════
--  DETECTION
-- ════════════════════════════════════════════════════════════════════════
local function detect()
    local forced = (Config and Config.Framework) or 'auto'

    local function tryQbox()
        if not res('qbx_core') then return false end
        -- NOTE: `exports.qbx_core` is a PROXY — indexing a key Qbox does not
        -- export raises. Never probe it outside a pcall.
        local core
        pcall(function() core = exports.qbx_core end)
        if not core then return false end
        Framework.Name, Framework.Core = 'qbox', core
        return true
    end

    local function tryQb()
        if not res('qb-core') then return false end
        local core
        pcall(function() core = exports['qb-core']:GetCoreObject() end)
        if not core then return false end
        Framework.Name, Framework.Core = 'qbcore', core
        return true
    end

    local function tryEsx()
        if not res('es_extended') then return false end
        local core
        pcall(function() core = exports['es_extended']:getSharedObject() end)
        if not core then
            pcall(function() TriggerEvent('esx:getSharedObject', function(o) core = o end) end)
        end
        if not core then return false end
        Framework.Name, Framework.Core = 'esx', core
        return true
    end

    if forced == 'esx' then return tryEsx()
    elseif forced == 'qbcore' then return tryQb()
    elseif forced == 'qbox' then return tryQbox()
    elseif forced == 'standalone' then return false
    else
        return tryQbox() or tryQb() or tryEsx()
    end
end

local lastDetectionAt
local detectionWorker = false

--- A permission check can recover immediately once a late core is available.
--- Failed probes are throttled; no permission is granted merely for waiting.
function Framework.EnsureReady()
    if Framework.Ready then return true end
    if Config and Config.Framework == 'standalone' then return false end
    local now = GetGameTimer()
    if lastDetectionAt and now >= lastDetectionAt and now - lastDetectionAt < 250 then return false end
    lastDetectionAt = now
    if not detect() then return false end
    Framework.Ready = true
    Framework.Generation = Framework.Generation + 1
    if Config and Config.Debug then
        print(('[oxlyn-handling] Framework detected: %s'):format(Framework.Name))
    end
    return true
end

local function startDetection()
    if detectionWorker or Framework.Ready or (Config and Config.Framework == 'standalone') then return end
    detectionWorker = true
    CreateThread(function()
        local tries = 0
        while not Framework.Ready and not (Config and Config.Framework == 'standalone') do
            if Framework.EnsureReady() then break end
            tries = tries + 1
            if tries == 80 and Config and Config.Debug then
                print('[oxlyn-handling] Framework not available yet — retrying every 2 s; ACE / identifier permissions remain available.')
            end
            -- Keep the fast startup window, then back off instead of giving
            -- up permanently. The worker exits as soon as a core is found.
            Wait(tries < 80 and 250 or 2000)
        end
        detectionWorker = false
    end)
end

AddEventHandler(IS_SERVER and 'onResourceStart' or 'onClientResourceStart', function(name)
    if not resourceKinds[name] then return end
    stoppedResources[name] = nil
    if Framework.Ready then return end
    lastDetectionAt = nil
    Framework.EnsureReady()
    startDetection() -- exports can become available after the start event
end)

AddEventHandler(IS_SERVER and 'onResourceStop' or 'onClientResourceStop', function(name)
    if not resourceKinds[name] then return end
    stoppedResources[name] = true -- the stop event may precede the state change
    if Framework.Name ~= resourceKinds[name] then return end
    Framework.Name, Framework.Core, Framework.Ready = nil, nil, false
    Framework.Generation = Framework.Generation + 1
    lastDetectionAt = nil
    startDetection()
end)

startDetection()

-- ════════════════════════════════════════════════════════════════════════
--  SERVER API
-- ════════════════════════════════════════════════════════════════════════
if IS_SERVER then

    function Framework.GetPlayer(src)
        if not Framework.EnsureReady() or not Framework.Core then return nil end
        local ok, p = pcall(function()
            if Framework.Name == 'esx'    then return Framework.Core.GetPlayerFromId(src) end
            if Framework.Name == 'qbox'   then return Framework.Core:GetPlayer(src) end
            if Framework.Name == 'qbcore' then return Framework.Core.Functions.GetPlayer(src) end
            return nil
        end)
        return ok and p or nil
    end

    function Framework.GetIdentifier(src)
        local p = Framework.GetPlayer(src)
        if not p then return nil end
        if Framework.Name == 'esx' then return p.getIdentifier and p.getIdentifier() or p.identifier end
        return p.PlayerData and p.PlayerData.citizenid
    end

    function Framework.GetName(src)
        if src == 0 then return 'console' end
        local p = Framework.GetPlayer(src)
        if not p then return GetPlayerName(src) or ('src:' .. tostring(src)) end
        if Framework.Name == 'esx' then
            return (p.getName and p.getName()) or p.name or GetPlayerName(src)
        end
        local ci = p.PlayerData and p.PlayerData.charinfo
        if ci then return ('%s %s'):format(ci.firstname or '', ci.lastname or '') end
        return GetPlayerName(src) or ('src:' .. tostring(src))
    end

    --- Every identifier FiveM knows for this player (license:, steam:, discord:…).
    function Framework.GetIdentifiers(src)
        local out = {}
        if src == 0 then return out end
        local sid = tostring(src)
        local ok, n = pcall(GetNumPlayerIdentifiers, sid)
        if not ok or type(n) ~= 'number' then return out end
        for i = 0, n - 1 do
            local okid, id = pcall(GetPlayerIdentifier, sid, i)
            if okid and type(id) == 'string' and id ~= '' then out[#out + 1] = id end
        end
        return out
    end

    --- Framework group / permission level, as a plain string (may be nil).
    function Framework.GetGroup(src)
        local p = Framework.GetPlayer(src)
        if not p then return nil end
        local ok, g = pcall(function()
            if Framework.Name == 'esx' then
                return (p.getGroup and p.getGroup()) or p.group
            end
            local pd = p.PlayerData
            if not pd then return nil end
            return pd.group or (pd.metadata and pd.metadata.group)
        end)
        return (ok and type(g) == 'string') and g or nil
    end

    --- @return string|nil job, number grade, boolean onDuty
    function Framework.GetJob(src)
        local p = Framework.GetPlayer(src)
        if not p then return nil, 0, false end
        local ok, name, grade, duty = pcall(function()
            if Framework.Name == 'esx' then
                local j = (p.getJob and p.getJob()) or p.job
                if not j then return nil, 0, false end
                return j.name, tonumber(j.grade) or 0, true   -- ESX has no duty flag
            end
            local j = p.PlayerData and p.PlayerData.job
            if not j then return nil, 0, false end
            local lvl = j.grade and (tonumber(j.grade.level) or tonumber(j.grade)) or 0
            return j.name, lvl or 0, j.onduty ~= false
        end)
        if not ok then return nil, 0, false end
        return name, grade or 0, duty == true
    end

    -- ── Permission gate ─────────────────────────────────────────────────
    local function cfgAdmin()
        local a = (Config and Config.Admin) or {}
        return type(a) == 'table' and a or {}
    end

    --  An absent/empty `methods` list means "all sources on", so an older
    --  config.lua (everyone/aces/groups only) keeps working untouched.
    local function methodOn(a, m)
        local list = a.methods
        if type(list) ~= 'table' or #list == 0 then return true end
        for _, v in ipairs(list) do if v == m then return true end end
        return false
    end

    --- ACE test that never throws and always passes the src as a STRING
    --- (IsPlayerAceAllowed takes a char*: a number works by coercion on most
    --- builds but not all, and this is the documented form).
    function Framework.AceAllowed(src, object)
        if type(object) ~= 'string' or object == '' then return false end
        local ok, allowed = pcall(IsPlayerAceAllowed, tostring(src), object)
        return ok and allowed == true
    end

    --  The universal bridge namespaces. txAdmin, `add_principal … group.admin`
    --  and every framework that mirrors its groups into principals land here.
    local ACE_NAMESPACES = { 'group.', 'qbcore.', 'qbx.', 'esx.' }

    local function normIdent(s)
        return (tostring(s or ''):lower():gsub('%s+', ''))
    end

    --- Full evaluation with a per-source report (drives /handlingaccess).
    --- @return boolean allowed, string reason, table report
    function Framework.EvaluateAdmin(src)
        Framework.EnsureReady()
        local a = cfgAdmin()
        local report = {
            src = src,
            framework = Framework.Ready and Framework.Name or ((Config and Config.Framework == 'standalone') and 'standalone' or 'waiting'),
            name = Framework.GetName(src),
            sources = {},
        }
        local function note(source, verdict, detail)
            report.sources[#report.sources + 1] = { source = source, verdict = verdict, detail = detail }
        end

        -- 0 ── override hook (editable file: never patch the core for a
        --      custom integration, implement this instead)
        local hook = a.check
        if type(hook) ~= 'function' and type(OxlynHandlingHooks) == 'table' then
            hook = OxlynHandlingHooks.IsAdmin
        end
        if type(hook) == 'function' then
            local ok, verdict = pcall(hook, src)
            if ok and type(verdict) == 'boolean' then
                note('hook', verdict and 'ALLOW' or 'DENY', 'Config.Admin.check returned ' .. tostring(verdict))
                report.allowed, report.reason = verdict, 'hook'
                return verdict, 'hook', report
            end
            note('hook', 'skip', ok and 'returned nil — falling through' or 'errored — ignored')
        else
            note('hook', 'skip', 'not set')
        end

        -- 1 ── server console
        if src == 0 then
            local allow = a.allowConsole ~= false
            note('console', allow and 'ALLOW' or 'DENY', 'server console')
            report.allowed, report.reason = allow, 'console'
            return allow, 'console', report
        end

        -- 2 ── everyone
        if a.everyone == true then
            note('everyone', 'ALLOW', 'Config.Admin.everyone = true (TESTING ONLY)')
            report.allowed, report.reason = true, 'everyone'
            return true, 'everyone', report
        end
        note('everyone', 'no', 'Config.Admin.everyone = false')

        local groups = type(a.groups) == 'table' and a.groups or {}

        -- 3 ── ace (explicit list + the group.<g>/qbcore.<g>/qbx.<g> bridges)
        if methodOn(a, 'ace') then
            local tested = {}
            local function tryAce(object)
                if tested[object] then return false end
                tested[object] = true
                return Framework.AceAllowed(src, object)
            end
            for _, ace in ipairs(type(a.aces) == 'table' and a.aces or {}) do
                if type(ace) == 'string' and tryAce(ace) then
                    note('ace', 'ALLOW', ace)
                    report.allowed, report.reason = true, 'ace'
                    return true, 'ace', report
                end
            end
            if a.groupAces ~= false then
                for _, g in ipairs(groups) do
                    if type(g) == 'string' then
                        for _, ns in ipairs(ACE_NAMESPACES) do
                            if tryAce(ns .. g) then
                                note('ace', 'ALLOW', ns .. g)
                                report.allowed, report.reason = true, 'ace'
                                return true, 'ace', report
                            end
                        end
                    end
                end
            end
            local list = {}
            for object in pairs(tested) do list[#list + 1] = object end
            table.sort(list)
            note('ace', 'no', 'none of: ' .. table.concat(list, ', '))
        else
            note('ace', 'off', 'not in Config.Admin.methods')
        end

        -- 4 ── framework group
        if methodOn(a, 'group') then
            if #groups == 0 then
                note('group', 'no', 'Config.Admin.groups is empty')
            elseif not Framework.Ready then
                note('group', 'no', (Config and Config.Framework == 'standalone') and 'standalone configured' or 'framework not available yet (retrying)')
            else
                local mine = Framework.GetGroup(src)
                for _, g in ipairs(groups) do
                    if type(g) == 'string' then
                        if mine and mine:lower() == g:lower() then
                            note('group', 'ALLOW', ('%s group = %s'):format(report.framework, g))
                            report.allowed, report.reason = true, 'group'
                            return true, 'group', report
                        end
                        local ok, has = false, false
                        if Framework.Name == 'qbcore' then
                            ok, has = pcall(function() return Framework.Core.Functions.HasPermission(src, g) end)
                        elseif Framework.Name == 'qbox' then
                            ok, has = pcall(function() return exports.qbx_core:HasPermission(src, g) end)
                        end
                        if ok and has == true then
                            note('group', 'ALLOW', ('%s HasPermission("%s")'):format(report.framework, g))
                            report.allowed, report.reason = true, 'group'
                            return true, 'group', report
                        end
                    end
                end
                note('group', 'no', ('%s group = %s, none of { %s }')
                    :format(report.framework, tostring(mine or 'nil'), table.concat(groups, ', ')))
            end
        else
            note('group', 'off', 'not in Config.Admin.methods')
        end

        -- 5 ── job
        if methodOn(a, 'job') then
            local jobs = type(a.jobs) == 'table' and a.jobs or {}
            if next(jobs) == nil then
                note('job', 'no', 'Config.Admin.jobs is empty')
            elseif not Framework.Ready then
                note('job', 'no', (Config and Config.Framework == 'standalone') and 'standalone configured' or 'framework not available yet (retrying)')
            else
                local jname, jgrade, jduty = Framework.GetJob(src)
                local matched = false
                for k, v in pairs(jobs) do
                    -- accepts BOTH { police = 0 } and { 'police', 'ambulance' }
                    local want, minGrade
                    if type(k) == 'number' then want, minGrade = v, 0 else want, minGrade = k, tonumber(v) or 0 end
                    if type(want) == 'string' and jname and jname:lower() == want:lower() then
                        matched = true
                        if jgrade >= minGrade and (a.jobOnDuty ~= true or jduty) then
                            note('job', 'ALLOW', ('job %s grade %d >= %d'):format(jname, jgrade, minGrade))
                            report.allowed, report.reason = true, 'job'
                            return true, 'job', report
                        end
                    end
                end
                note('job', 'no', matched
                    and ('job %s grade %d below the minimum%s'):format(tostring(jname), jgrade,
                        (a.jobOnDuty == true and not jduty) and ' (or off duty)' or '')
                    or ('current job = %s'):format(tostring(jname or 'none')))
            end
        else
            note('job', 'off', 'not in Config.Admin.methods')
        end

        -- 6 ── identifier allow-list (the emergency path: depends on nothing)
        if methodOn(a, 'identifier') then
            local wanted = type(a.identifiers) == 'table' and a.identifiers or {}
            if #wanted == 0 then
                note('identifier', 'no', 'Config.Admin.identifiers is empty')
            else
                local mine = Framework.GetIdentifiers(src)
                local set = {}
                for _, id in ipairs(mine) do set[normIdent(id)] = true end
                for _, want in ipairs(wanted) do
                    local w = normIdent(want)
                    if w ~= '' then
                        if set[w] then
                            note('identifier', 'ALLOW', want)
                            report.allowed, report.reason = true, 'identifier'
                            return true, 'identifier', report
                        end
                        -- tolerate a doubled prefix ("license:license:abc…") and
                        -- a bare hash written with no prefix at all
                        for _, id in ipairs(mine) do
                            local n = normIdent(id)
                            if #w >= 8 and (n:find(w, 1, true) or w:find(n, 1, true)) then
                                note('identifier', 'ALLOW', ('%s matches %s'):format(want, id))
                                report.allowed, report.reason = true, 'identifier'
                                return true, 'identifier', report
                            end
                        end
                    end
                end
                note('identifier', 'no', ('%d configured, none matched'):format(#wanted))
            end
        else
            note('identifier', 'off', 'not in Config.Admin.methods')
        end

        report.allowed, report.reason = false, 'none'
        return false, 'none', report
    end

    --- The boolean gate every server callback uses.
    function Framework.IsAdmin(src)
        local ok, allowed, reason = pcall(Framework.EvaluateAdmin, src)
        if not ok then
            print(('[oxlyn-handling] permission check errored for src %s: %s'):format(tostring(src), tostring(allowed)))
            return false
        end
        if (Config and Config.Admin and Config.Admin.debug) or (Config and Config.Debug) then
            print(('[oxlyn-handling] access %s for %s (src %s) via %s')
                :format(allowed and 'ALLOWED' or 'DENIED', Framework.GetName(src), tostring(src), tostring(reason)))
        end
        return allowed == true
    end

    -- ── Self-contained callback registry ────────────────────────────────
    local callbacks = {}
    function Framework.RegisterCallback(name, fn) callbacks[name] = fn end

    --  Token bucket per source: the client owns the trigger for this event, so
    --  cap how often it can make the server work. 30 burst / +10 per second —
    --  far above the fastest real use (an admin clicking models into a vehicle
    --  class), far below what a spammer would need.
    local BURST, PER_MS = 30, 0.01
    local bucket = {}
    local function allowRequest(src)
        local now = GetGameTimer()
        local b = bucket[src]
        if not b then
            b = { tokens = BURST, at = now }
            bucket[src] = b
        end
        b.tokens = math.min(BURST, b.tokens + (now - b.at) * PER_MS)
        b.at = now
        if b.tokens < 1 then return false end
        b.tokens = b.tokens - 1
        return true
    end
    AddEventHandler('playerDropped', function() bucket[source] = nil end)

    RegisterNetEvent('oxlyn-handling:cb:request', function(name, reqId, args)
        local src = source
        if type(name) ~= 'string' or type(reqId) ~= 'number' then return end
        if type(args) ~= 'table' then args = {} end
        local function done(...)
            TriggerClientEvent('oxlyn-handling:cb:response', src, reqId, { ... })
        end
        if not allowRequest(src) then return done(nil) end
        local fn = callbacks[name]
        if not fn then return done(nil) end
        fn(src, done, table.unpack(args, 1, math.min(#args, 8)))
    end)

-- ════════════════════════════════════════════════════════════════════════
--  CLIENT API
-- ════════════════════════════════════════════════════════════════════════
else

    -- ── Self-contained callback client side ─────────────────────────────
    local pending, seq = {}, 0

    function Framework.TriggerCallback(name, cb, ...)
        seq = seq + 1
        local id = seq
        pending[id] = cb
        TriggerServerEvent('oxlyn-handling:cb:request', name, id, { ... })
        SetTimeout(8000, function()
            if pending[id] then
                pending[id] = nil
                if cb then cb(nil) end
            end
        end)
    end

    RegisterNetEvent('oxlyn-handling:cb:response', function(reqId, results)
        local cb = pending[reqId]
        if not cb then return end
        pending[reqId] = nil
        cb(table.unpack(results or {}))
    end)
end

