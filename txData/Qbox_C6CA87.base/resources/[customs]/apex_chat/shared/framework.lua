--[[
    Apex Chat — Framework Bridge
    ────────────────────────────────────────────────────────────
    Detects qb-core | qbx_core | es_extended (per Shared._alias),
    then exposes a QBCore-shaped facade via the global `QBCore`
    so the rest of the codebase can keep using the familiar API
    regardless of what's actually running.

    Provided surface (server-side):
        QBCore.Functions.GetPlayer(source)
        QBCore.Functions.GetPlayers()            -> { source, ... }
        QBCore.Functions.HasPermission(src, grp) -> bool

    The returned player table mimics QBCore:
        xPlayer.PlayerData.source
        xPlayer.PlayerData.name
        xPlayer.PlayerData.charinfo.firstname / lastname
        xPlayer.PlayerData.money.bank / .cash
        xPlayer.PlayerData.job.name / .label
        xPlayer.Functions.RemoveMoney('bank'|'cash', amount)
        xPlayer.Functions.AddMoney('bank'|'cash', amount)
]]

if not IsDuplicityVersion() then return end

local BRIDGE = { framework = nil, core = nil }
local ALIAS  = (Shared and Shared._alias) or {
    ['qb-core']     = 'qb',
    ['qbx_core']    = 'qbx',
    ['es_extended'] = 'esx',
}

-- short name -> resource name (honours renamed cores in Shared._alias).
local RES = { qb = 'qb-core', qbx = 'qbx_core', esx = 'es_extended' }
for resource, short in pairs(ALIAS) do RES[short] = resource end

-- ─── Detection ─────────────────────────────────────────────
-- Fixed order, qbx first: qbx_core `provide`s qb-core, so on a Qbox server
-- both names report 'started' and pairs() order would pick one at random.
local ORDER = { 'qbx', 'qb', 'esx' }

local function detect()
    local pref = (Shared and Shared.framework) or 'auto'
    if pref ~= 'auto' then return pref end
    for _, short in ipairs(ORDER) do
        if GetResourceState(RES[short]) == 'started' then return short end
    end
    return 'none'
end

-- ─── Core loaders ──────────────────────────────────────────
-- Qbox has NO `GetCoreObject` export on qbx_core (only its optional qb-core
-- bridge has one), so the core is built from the native qbx_core exports.
local function qbxCore(res)
    return {
        Functions = {
            GetPlayer = function(src)
                local ok, player = pcall(function() return exports[res]:GetPlayer(src) end)
                return ok and player or nil
            end,
            GetPlayers = function()
                local out, list = {}, GetPlayers()
                for i = 1, #list do
                    local src = tonumber(list[i])
                    if src and Player(src).state.isLoggedIn then out[#out + 1] = src end
                end
                return out
            end,
            -- Qbox permissions are plain ACEs (add_ace group.admin admin allow).
            HasPermission = function(src, group)
                return IsPlayerAceAllowed(src, group)
            end,
        },
    }
end

local function loadCore(short)
    local res = RES[short]
    if not res or GetResourceState(res) ~= 'started' then return nil end
    if short == 'qbx' then
        return qbxCore(res)
    end
    if short == 'qb' then
        local ok, core = pcall(function() return exports[res]:GetCoreObject() end)
        if ok and core then return core end
    end
    if short == 'esx' then
        local ok, esx = pcall(function() return exports[res]:getSharedObject() end)
        if ok and esx then return esx end
    end
    return nil
end

-- ─── ESX → QBCore-shaped facade ────────────────────────────
local function wrapESX(xp)
    if not xp then return nil end

    local function safeAccount(name)
        if xp.getAccount then
            local a = xp.getAccount(name)
            return (a and a.money) or 0
        end
        return 0
    end

    local function safeGet(key)
        if xp.get then
            local ok, v = pcall(xp.get, key)
            if ok then return v end
        end
        return nil
    end

    local first = xp.firstName  or safeGet('firstName')  or xp.variables and xp.variables.firstName or ''
    local last  = xp.lastName   or safeGet('lastName')   or xp.variables and xp.variables.lastName  or ''
    if (first == '' or last == '') and xp.getName then
        local full = xp.getName() or ''
        if full ~= '' and first == '' and last == '' then
            local sp = full:find(' ')
            first = sp and full:sub(1, sp - 1) or full
            last  = sp and full:sub(sp + 1)    or ''
        end
    end

    local job = xp.job or (xp.getJob and xp.getJob()) or { name = 'unemployed', label = 'Unemployed' }

    return {
        PlayerData = {
            source   = xp.source,
            name     = (xp.getName and xp.getName()) or xp.name or '',
            charinfo = { firstname = first or '', lastname = last or '' },
            money    = { bank = safeAccount('bank'), cash = safeAccount('money') },
            job      = {
                name        = job.name or 'unemployed',
                label       = job.label or job.name or 'Unemployed',
                grade       = tonumber(job.grade) or 0,
                grade_name  = job.grade_name or '',
                grade_label = job.grade_label or job.grade_name or '',
            },
        },
        Functions = {
            -- Called QBCore-style with a dot: Functions.RemoveMoney('bank', amount).
            RemoveMoney = function(account, amount)
                if account == 'bank' and xp.removeAccountMoney then xp.removeAccountMoney('bank', amount) end
                if account == 'cash' and xp.removeMoney         then xp.removeMoney(amount) end
            end,
            AddMoney = function(account, amount)
                if account == 'bank' and xp.addAccountMoney then xp.addAccountMoney('bank', amount) end
                if account == 'cash' and xp.addMoney        then xp.addMoney(amount) end
            end,
        },
    }
end

-- ─── Synthesised QBCore global ─────────────────────────────
local Functions = {}

function Functions.GetPlayer(src)
    if not BRIDGE.core then return nil end
    if BRIDGE.framework == 'qb' or BRIDGE.framework == 'qbx' then
        return BRIDGE.core.Functions.GetPlayer(src)
    elseif BRIDGE.framework == 'esx' then
        return wrapESX(BRIDGE.core.GetPlayerFromId(src))
    end
    return nil
end

function Functions.GetPlayers()
    if BRIDGE.framework == 'qb' or BRIDGE.framework == 'qbx' then
        return (BRIDGE.core and BRIDGE.core.Functions.GetPlayers()) or {}
    end
    if BRIDGE.framework == 'esx' and BRIDGE.core and BRIDGE.core.GetPlayers then
        -- ESX.GetPlayers() returns only fully-loaded players (numeric ids).
        local ok, list = pcall(BRIDGE.core.GetPlayers)
        if ok and type(list) == 'table' then
            local out = {}
            for i = 1, #list do out[i] = tonumber(list[i]) or list[i] end
            return out
        end
    end
    -- Fallback: native GetPlayers (string IDs → numbers).
    local out, list = {}, GetPlayers()
    for i = 1, #list do out[i] = tonumber(list[i]) end
    return out
end

-- Robust ESX permission group reader across ESX versions.
local function esxGroup(xp)
    if not xp then return 'user' end
    if xp.getGroup then
        local ok, g = pcall(xp.getGroup, xp); if ok and g and g ~= '' then return g end
    end
    if xp.group and xp.group ~= '' then return xp.group end
    if xp.variables and xp.variables.group and xp.variables.group ~= '' then return xp.variables.group end
    return 'user'
end

function Functions.HasPermission(src, group)
    if not src or not group or group == '' then return false end

    -- 1) Framework-native permission check.
    if BRIDGE.framework == 'qb' or BRIDGE.framework == 'qbx' then
        if BRIDGE.core and BRIDGE.core.Functions.HasPermission then
            local ok, allowed = pcall(BRIDGE.core.Functions.HasPermission, src, group)
            if ok and allowed then return true end
        end
    elseif BRIDGE.framework == 'esx' then
        local xp = BRIDGE.core and BRIDGE.core.GetPlayerFromId(src)
        if xp then
            local g = esxGroup(xp)
            if g == group then return true end
            -- ESX considers superadmin as admin; treat 'god' as superadmin.
            if group == 'admin' and (g == 'admin' or g == 'superadmin') then return true end
            if group == 'god'   and g == 'superadmin' then return true end
        end
    end

    -- 2) ACE safety net for EVERY framework: a principal added in server.cfg
    --    (add_principal identifier.X group.admin) always satisfies the check.
    if IsPlayerAceAllowed(src, 'group.' .. group) then return true end

    return false
end

-- Uniform job-grade reader. QBCore stores job.grade as a table
-- ({ level, name }); ESX (wrapped above) stores it as a number.
function Functions.GetJobGrade(xPlayer)
    if not xPlayer or not xPlayer.PlayerData or not xPlayer.PlayerData.job then return 0 end
    local g = xPlayer.PlayerData.job.grade
    if type(g) == 'table' then return tonumber(g.level) or 0 end
    return tonumber(g) or 0
end

-- Best-effort permission group (used by role/staff rules).
function Functions.GetPlayerGroup(src)
    if BRIDGE.framework == 'esx' then
        local xp = BRIDGE.core and BRIDGE.core.GetPlayerFromId(src)
        return (xp and xp.getGroup and xp.getGroup()) or 'user'
    elseif BRIDGE.framework == 'qb' or BRIDGE.framework == 'qbx' then
        local xp = BRIDGE.core and BRIDGE.core.Functions.GetPlayer(src)
        if xp and xp.PlayerData and xp.PlayerData.metadata then
            -- QB exposes ace-based perms; fall back to 'user'.
        end
    end
    return 'user'
end

-- ─── Init ──────────────────────────────────────────────────
-- Retries are silent: each state is printed once, never once per attempt.
local announced

local function say(key, msg)
    if announced == key then return end
    announced = key
    print(msg)
end

local function init()
    if BRIDGE.core then return end
    BRIDGE.framework = detect()
    if BRIDGE.framework == 'none' then return end
    BRIDGE.core = loadCore(BRIDGE.framework)
    if BRIDGE.core then
        say('ready', ('^2[apex_chat]^7 Framework bridge ready (%s).'):format(BRIDGE.framework))
    end
end

-- Always expose the global; methods no-op gracefully until init succeeds.
QBCore = {
    Functions = Functions,
}

-- Try eagerly on script load (in case the framework is already up).
init()

-- Retry until a framework boots or 30 s pass.
CreateThread(function()
    local elapsed = 0
    while not BRIDGE.core and elapsed < 30000 do
        Wait(500); elapsed = elapsed + 500
        init()
    end
    if BRIDGE.core then return end
    if BRIDGE.framework == 'none' then
        say('none', '^3[apex_chat]^7 No supported framework detected (qb-core / qbx_core / es_extended). Player-aware features are disabled.')
    else
        say('failed', ('^3[apex_chat]^7 Framework %s (%s) did not load after 30 s. Player-aware features stay disabled until it starts.')
            :format(BRIDGE.framework, tostring(RES[BRIDGE.framework])))
    end
end)

AddEventHandler('onServerResourceStart', function(res)
    if BRIDGE.core then return end
    for _, name in pairs(RES) do
        if name == res then init() break end
    end
end)
