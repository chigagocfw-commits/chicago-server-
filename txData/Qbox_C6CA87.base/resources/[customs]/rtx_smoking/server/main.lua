--       _                           _   _             _                   _             _                
--   ___| | ___  __ _ _ __   ___  __| | | |__  _   _  | |__  _ __ __ _  __| |_   _   ___| |_ ___ _ __     
--  / __| |/ _ \/ _` | '_ \ / _ \/ _` | | '_ \| | | | | '_ \| '__/ _` |/ _` | | | | / __| __/ _ \ '_ \    
-- | (__| |  __/ (_| | | | |  __/ (_| | | |_) | |_| | | |_) | | | (_| | (_| | |_| | \__ \ ||  __/ | | |   
--  \___|_|\___|\__,_|_| |_|\___|\__,_| |_.__/ \__, | |_.__/|_|  \__,_|\__,_|\__, | |___/\__\___|_| |_|   
--  / _(_)_  _____  __| | | |__  _   _  | |__  |___/ ___(_)_ __ ___   | |__  |___/_ __ _ __ ___ _ __ __ _ 
-- | |_| \ \/ / _ \/ _` | | '_ \| | | | | '_ \ / _` |_  / | '_ ` _ \  | '_ \ / _ \ '__| '__/ _ \ '__/ _` |
-- |  _| |>  <  __/ (_| | | |_) | |_| | | | | | (_| |/ /| | | | | | | | | | |  __/ |  | | |  __/ | | (_| |
-- |_| |_/_/\_\___|\__,_| |_.__/ \__, | |_| |_|\__,_/___|_|_| |_| |_| |_| |_|\___|_|  |_|  \___|_|  \__,_|
--                               |___/
--   

-- ============================================================
--  RTX SMOKING  –  server/main.lua
-- ============================================================

local hookahs       = {}   -- [hookahId] = hookahData
local hookahCounter = 0    -- auto-incrémente les IDs de narguilé
local playerSmoking = {}   -- [source] = { smoking, item, type }
local coalTimers    = {}   -- [hookahId] = { heatTimer, burnTimer }
local hoseConnections = {} -- [hookahId][serverId] = true
local lastPlace = {}       -- [source] = timestamp dernier placement
local removedStaticHookahs = {}
local persistedStaticHookahs = {}
local hookahPersistenceKey = 'rtx_smoking:hookahs:v1'
local hookahsInitialized = false

-- ── langue (utilise Config.Language, repli sur English) ───
local function L(key)
    local lang = Language and (Language[Config.Language] or Language['English'])
    return (lang and lang[key]) or key
end

local function NormalizeHookahId(hookahId)
    return tonumber(hookahId)
end

local function PersistHookahs()
    local saved = {
        version = 1,
        hookahs = {},
        removedStatic = removedStaticHookahs,
    }

    for hookahId, hookah in pairs(hookahs) do
        saved.hookahs[#saved.hookahs + 1] = {
            id = hookahId,
            ownerIdentifier = hookah.ownerIdentifier,
            isStatic = hookah.isStatic == true,
            staticIdx = hookah.staticIdx,
            type = hookah.type,
            coords = {
                x = hookah.coords.x,
                y = hookah.coords.y,
                z = hookah.coords.z,
            },
            rotation = {
                x = hookah.rotation and hookah.rotation.x or 0.0,
                y = hookah.rotation and hookah.rotation.y or 0.0,
                z = hookah.rotation and hookah.rotation.z or 0.0,
            },
            water = hookah.water,
            tobacco = hookah.tobacco,
            coal = hookah.coal,
        }
    end

    SetResourceKvp(hookahPersistenceKey, json.encode(saved))
end

local function LoadPersistedHookahs()
    local raw = GetResourceKvpString(hookahPersistenceKey)
    if not raw or raw == '' then return end

    local ok, saved = pcall(json.decode, raw)
    if not ok or type(saved) ~= 'table' then
        print('[RTX SMOKING] Hookah persistence data is invalid; starting with configured defaults.')
        return
    end

    local removedStatic = type(saved.removedStatic) == 'table' and saved.removedStatic or {}
    for staticIdx, removed in pairs(removedStatic) do
        if removed == true then
            removedStaticHookahs[tonumber(staticIdx) or staticIdx] = true
        end
    end

    local savedHookahs = type(saved.hookahs) == 'table' and saved.hookahs or {}
    for _, data in pairs(savedHookahs) do
        if type(data) == 'table' then
            local hookahId = tonumber(data.id)
            local typeId = tonumber(data.type) or data.type
            local coords = data.coords
            local rotation = type(data.rotation) == 'table' and data.rotation or {}
            if hookahId and Config.HookahTypes[typeId]
                and type(coords) == 'table'
                and tonumber(coords.x) and tonumber(coords.y) and tonumber(coords.z)
            then
                local staticIdx = tonumber(data.staticIdx) or data.staticIdx
                local hookah = {
                    id = hookahId,
                    ownerId = nil,
                    ownerIdentifier = data.ownerIdentifier,
                    isStatic = data.isStatic == true,
                    staticIdx = staticIdx,
                    type = typeId,
                    coords = vector3(tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)),
                    rotation = vector3(
                        tonumber(rotation.x) or 0.0,
                        tonumber(rotation.y) or 0.0,
                        tonumber(rotation.z) or 0.0
                    ),
                    water = type(data.water) == 'table' and data.water or { state = 'empty', level = 0 },
                    tobacco = type(data.tobacco) == 'table' and data.tobacco or { state = 'empty', amount = 0, flavor = nil },
                    coal = type(data.coal) == 'table' and data.coal or { state = 'missing', progress = 0, durability = 0 },
                    hoses = { connected = 0, max = Config.MaxHoses, players = {} },
                    managePermissions = nil,
                }
                if hookah.coal.state == 'heating' then
                    hookah.coal.state = 'ready'
                    hookah.coal.progress = 100
                    hookah.coal.durability = 100
                end

                if hookah.isStatic and staticIdx ~= nil then
                    persistedStaticHookahs[staticIdx] = hookah
                elseif not hookah.isStatic then
                    hookahs[hookahId] = hookah
                end
                hookahCounter = math.max(hookahCounter, hookahId)
            end
        end
    end
end

-- ── timers (remplace SetInterval/clearInterval qui n'existent pas en FiveM) ──
local function SetTimer(ms, cb)
    local timer = { active = true }
    CreateThread(function()
        while timer.active do
            Wait(ms)
            if not timer.active then break end
            cb(timer)
        end
    end)
    return timer
end

local function StopTimer(timer)
    if timer then timer.active = false end
end

-- distance joueur -> coords (vrai si impossible à vérifier : console / pas de OneSync)
local function IsNear(source, coords, maxDist)
    if not source or source == 0 or not coords then return true end
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return true end
    local p = GetEntityCoords(ped)
    local dx, dy, dz = p.x - coords.x, p.y - coords.y, p.z - coords.z
    return (dx * dx + dy * dy + dz * dz) <= maxDist * maxDist
end

-- ── utilitaires framework ─────────────────────────────────
local ESX, QBCore

if Config.Framework == 'esx' then
    if Config.ESXFramework.newversion then
        ESX = exports[Config.ESXFramework.resourcename]:getSharedObject()
    else
        TriggerEvent(Config.ESXFramework.getsharedobject, function(obj) ESX = obj end)
    end
elseif Config.Framework == 'qbcore' then
    QBCore = exports[Config.QBCoreFrameworkResourceName]:GetCoreObject()
end

function GetLicenseIdentifier(source)
    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('license:') then return id end
    end
    return tostring(source)
end

function GetPlayerJob(source)
    if Config.Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then return xPlayer.job and xPlayer.job.name end
    elseif Config.Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if player then return player.PlayerData.job and player.PlayerData.job.name end
    end
    return nil
end

function HasPermission(source, permList)
    if not permList then return false end
    for _, perm in ipairs(permList) do
        local pt = perm.permissiontype
        local pv = perm.permission
        if pt == 'ace' then
            if IsPlayerAceAllowed(source, pv) then return true end
        elseif pt == 'job' then
            if GetPlayerJob(source) == pv then return true end
        elseif pt == 'identifier' then
            if GetLicenseIdentifier(source) == pv then return true end
        end
    end
    return false
end

function IsHookahAdmin(source)
    if source == 0 then return true end -- console serveur
    local cfg = Config.HookahAdmin
    if not cfg or not cfg.enabled then return false end
    if cfg.everyone then return true end
    return HasPermission(source, cfg.permissions)
end

function CanManageHookah(source, hookahId)
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return false end
    local hookah = hookahs[hookahId]
    if not hookah then return false end
    if not IsNear(source, hookah.coords, (Config.HookahInteractDistance or 3.0) + 5.0) then return false end
    if IsHookahAdmin(source) then return true end
    if hookah.ownerId == source
        and (not hookah.ownerIdentifier or hookah.ownerIdentifier == GetLicenseIdentifier(source))
    then
        return true
    end
    if hookah.ownerIdentifier and hookah.ownerIdentifier == GetLicenseIdentifier(source) then return true end
    local permCfg = hookah.managePermissions
    if not permCfg then return false end
    if permCfg.everyone then return true end
    return HasPermission(source, permCfg.permissions)
end

local function CanRemoveHookah(source, hookahId)
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return false end
    local hookah = hookahs[hookahId]
    if not hookah then return false end

    if hookah.isStatic then
        return Config.HookahAdmin.allowStaticRemoval == true and IsHookahAdmin(source)
    end
    return IsHookahAdmin(source) or CanManageHookah(source, hookahId)
end

-- ── inventaire ────────────────────────────────────────────
function HasItem(source, itemName, count)
    count = count or 1
    if Config.Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local item = xPlayer.getInventoryItem(itemName)
        return item and item.count >= count
    elseif Config.Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if not player then return false end
        local item = player.Functions.GetItemByName(itemName)
        return item and item.amount >= count
    elseif Config.Framework == 'standalone' then
        return true
    end
    return false
end

function RemoveItem(source, itemName, count)
    count = count or 1
    if not HasItem(source, itemName, count) then return false end
    if Config.Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then xPlayer.removeInventoryItem(itemName, count) end
    elseif Config.Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if not player then return false end
        return player.Functions.RemoveItem(itemName, count) == true
    end
    return true
end

function GiveItem(source, itemName, count)
    count = count or 1
    if Config.Framework == 'esx' and ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        if xPlayer.canCarryItem and not xPlayer.canCarryItem(itemName, count) then return false end
        xPlayer.addInventoryItem(itemName, count)
        return true
    elseif Config.Framework == 'qbcore' and QBCore then
        local player = QBCore.Functions.GetPlayer(source)
        if not player then return false end
        return player.Functions.AddItem(itemName, count) and true or false
    end
    return true
end

-- ── notifications ─────────────────────────────────────────
function NotifyPlayer(source, notifType, title, message)
    if source == 0 then print(('[RTX SMOKING] %s'):format(tostring(message))) return end
    TriggerClientEvent('rtx_smoking:Notify', source, notifType, title, message)
end

-- ── synchronisation ───────────────────────────────────────
function BroadcastHookahState(hookahId, key, value)
    GlobalState['rtxsmoking-' .. tostring(hookahId) .. '-' .. key] = value
end

function SyncHookahHoses(hookahId)
    local hookah = hookahs[hookahId]
    if not hookah then return end
    hookah.hoses = hookah.hoses or {}
    local players, n = {}, 0
    for sid, connected in pairs(hoseConnections[hookahId] or {}) do
        if connected then
            players[sid] = { serverId = sid, laststate = 'idle' }
            n = n + 1
        end
    end
    hookah.hoses.connected = n
    hookah.hoses.players   = players
end

function SyncHookahToAll(hookahId)
    local hookah = hookahs[hookahId]
    if not hookah then return end
    TriggerClientEvent('rtx_smoking:Global:HookahCreate', -1, hookahId, hookah)
end

function RemoveHookahFromAll(hookahId)
    TriggerClientEvent('rtx_smoking:Global:HookahRemove', -1, hookahId)
end

-- ── initialisation des narguileés statiques ───────────────
CreateThread(function()
    Wait(1000)
    LoadPersistedHookahs()
    for idx, staticDef in pairs(Config.StaticHookahs or {}) do
        local isRemoved = removedStaticHookahs[idx] == true
            or removedStaticHookahs[tostring(idx)] == true
        if staticDef.enabled and not isRemoved then
            local hookah = persistedStaticHookahs[idx] or persistedStaticHookahs[tostring(idx)]
            local hookahId
            if hookah then
                hookahId = hookah.id
                hookah.type = staticDef.hookahType
                hookah.coords = staticDef.coords
                hookah.rotation = staticDef.rotation
                hookah.managePermissions = staticDef.managePermissions
                hookah.hoses = { connected = 0, max = staticDef.defaultState.hoses.max or Config.MaxHoses, players = {} }
            else
                hookahCounter = hookahCounter + 1
                hookahId = hookahCounter
                hookah = {
                    id          = hookahId,
                    ownerId     = nil,
                    isStatic    = true,
                    staticIdx   = idx,
                    type        = staticDef.hookahType,
                    coords      = staticDef.coords,
                    rotation    = staticDef.rotation,
                    water       = staticDef.defaultState.water,
                    tobacco     = staticDef.defaultState.tobacco,
                    coal        = staticDef.defaultState.coal,
                    hoses       = staticDef.defaultState.hoses,
                    managePermissions = staticDef.managePermissions,
                }
            end
            hookahs[hookahId] = hookah
            BroadcastHookahState(hookahId, 'water-state',      hookah.water.state)
            BroadcastHookahState(hookahId, 'water-level',      hookah.water.level)
            BroadcastHookahState(hookahId, 'tobacco-state',    hookah.tobacco.state)
            BroadcastHookahState(hookahId, 'tobacco-amount',   hookah.tobacco.amount)
            BroadcastHookahState(hookahId, 'tobacco-flavor',   hookah.tobacco.flavor or '')
            BroadcastHookahState(hookahId, 'coal-state',       hookah.coal.state)
            BroadcastHookahState(hookahId, 'coal-progress',    hookah.coal.progress)
            BroadcastHookahState(hookahId, 'coal-durability',  hookah.coal.durability)
            BroadcastHookahState(hookahId, 'connected',        0)
            BroadcastHookahState(hookahId, 'can-smoke',        hookah.coal.state == 'placed' and hookah.tobacco.state == 'prepared' and hookah.water.state ~= 'empty')
            BroadcastHookahState(hookahId, 'status',
                hookah.coal.state == 'placed' and hookah.tobacco.state == 'prepared' and hookah.water.state ~= 'empty' and 'ready' or 'preparing')
            TriggerClientEvent('rtx_smoking:Global:HookahCreate', -1, hookahId, hookah)
        end
    end
    for hookahId, hookah in pairs(hookahs) do
        if not hookah.isStatic then
            TriggerClientEvent('rtx_smoking:Global:HookahCreate', -1, hookahId, hookah)
        end
        if hookah.coal.state == 'placed' then
            StartCoalBurnTimer(hookahId)
        end
    end
    hookahsInitialized = true
    PersistHookahs()
end)

-- ── synchronisation à la connexion d'un joueur ───────────
local function SendHookahSync(playerSource)
    CreateThread(function()
        while not hookahsInitialized and GetPlayerName(playerSource) do
            Wait(100)
        end
        if GetPlayerName(playerSource) then
            TriggerClientEvent('rtx_smoking:Global:SynchHookahs', playerSource, hookahs)
        end
    end)
end

AddEventHandler('playerJoining', function()
    local source = source
    SendHookahSync(source)
end)

RegisterNetEvent('rtx_smoking:server:SynchHookah')
AddEventHandler('rtx_smoking:server:SynchHookah', function()
    SendHookahSync(source)
end)

-- ── placement d'un narguilé ───────────────────────────────
RegisterNetEvent('rtx_smoking:Global:PlaceHookah')
AddEventHandler('rtx_smoking:Global:PlaceHookah', function(coords, rotation, hookahTypeId)
    local source = source
    hookahTypeId = tonumber(hookahTypeId) or hookahTypeId
    local typeDef = Config.HookahTypes[hookahTypeId]
    if not typeDef then
        NotifyPlayer(source, 'error', 'Shisha', 'Invalid hookah type.')
        return
    end
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then
        NotifyPlayer(source, 'error', 'Shisha', 'Invalid placement coordinates.')
        return
    end
    local x, y, z = tonumber(coords.x), tonumber(coords.y), tonumber(coords.z)
    local function IsFinite(value)
        return value and value == value and value ~= math.huge and value ~= -math.huge
    end
    if not IsFinite(x) or not IsFinite(y) or not IsFinite(z) then
        NotifyPlayer(source, 'error', 'Shisha', 'Invalid placement coordinates.')
        return
    end
    coords = vector3(x, y, z)

    local rotationZ = type(rotation) == 'vector3' and rotation.z
        or type(rotation) == 'table' and tonumber(rotation.z)
        or 0.0
    if not IsFinite(rotationZ) then
        NotifyPlayer(source, 'error', 'Shisha', 'Invalid placement rotation.')
        return
    end
    rotation = vector3(0.0, 0.0, rotationZ % 360.0)

    local now = GetGameTimer()
    if lastPlace[source] and now - lastPlace[source] < 2000 then
        NotifyPlayer(source, 'error', 'Shisha', 'Please wait before placing another hookah.')
        return
    end
    if not IsNear(source, coords, 15.0) then
        NotifyPlayer(source, 'error', 'Shisha', 'That placement is too far away.')
        return
    end
    lastPlace[source] = now

    if not HasItem(source, typeDef.item) then
        NotifyPlayer(source, 'error', 'Shisha', 'Tu ne possèdes pas cet item.')
        return
    end
    if not RemoveItem(source, typeDef.item, 1) then
        NotifyPlayer(source, 'error', 'Shisha', 'The hookah item could not be removed from your inventory.')
        return
    end

    hookahCounter = hookahCounter + 1
    local hookahId = hookahCounter
    local hookah = {
        id       = hookahId,
        ownerId  = source,
        ownerIdentifier = GetLicenseIdentifier(source),
        isStatic = false,
        type     = hookahTypeId,
        coords   = coords,
        rotation = rotation,
        water    = { state = 'empty', level = 0 },
        tobacco  = { state = 'empty', amount = 0, flavor = nil },
        coal     = { state = 'missing', progress = 0, durability = 0 },
        hoses    = { connected = 0, max = Config.MaxHoses, players = {} },
        managePermissions = { everyone = false, permissions = {} },
    }
    hookahs[hookahId] = hookah

    BroadcastHookahState(hookahId, 'water-state',     'empty')
    BroadcastHookahState(hookahId, 'water-level',     0)
    BroadcastHookahState(hookahId, 'tobacco-state',   'empty')
    BroadcastHookahState(hookahId, 'tobacco-amount',  0)
    BroadcastHookahState(hookahId, 'tobacco-flavor',  '')
    BroadcastHookahState(hookahId, 'coal-state',      'missing')
    BroadcastHookahState(hookahId, 'coal-progress',   0)
    BroadcastHookahState(hookahId, 'coal-durability', 0)
    BroadcastHookahState(hookahId, 'connected',       0)
    BroadcastHookahState(hookahId, 'can-smoke',       false)
    BroadcastHookahState(hookahId, 'status',          'preparing')

    PersistHookahs()
    TriggerClientEvent('rtx_smoking:Global:HookahCreate', -1, hookahId, hookah)
end)

-- ── vérification + ouverture du menu ─────────────────────
RegisterNetEvent('rtx_smoking:Global:CheckHookah')
AddEventHandler('rtx_smoking:Global:CheckHookah', function(hookahId)
    local source  = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah  = hookahs[hookahId]
    if not hookah then return end

    local isAdmin   = IsHookahAdmin(source)
    local canRemove = CanRemoveHookah(source, hookahId)

    local perms = {
        canRemove = canRemove,
        isAdmin   = isAdmin,
        static    = hookah.isStatic == true,
    }
    TriggerClientEvent('rtx_smoking:Global:OpenHookah', source, hookahId, perms, perms)
end)

-- ── fermeture du menu ─────────────────────────────────────
RegisterNetEvent('rtx_smoking:Global:HookahClose')
AddEventHandler('rtx_smoking:Global:HookahClose', function(hookahId)
    -- côté client géré localement, rien à faire côté serveur
end)

-- ── eau ───────────────────────────────────────────────────
RegisterNetEvent('rtx_smoking:Global:HookahWater')
AddEventHandler('rtx_smoking:Global:HookahWater', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end
    if (hookah.water.level or 0) >= 100 then
        NotifyPlayer(source, 'info', 'Shisha', L('wateralreadyfilled'))
        return
    end
    if not HasItem(source, Config.ItemNames['water']) then
        NotifyPlayer(source, 'error', 'Shisha', L('waterneeded'))
        return
    end
    if not RemoveItem(source, Config.ItemNames['water'], 1) then
        NotifyPlayer(source, 'error', 'Shisha', L('itemremovalfailed'))
        return
    end

    hookah.water.state = 'good'
    hookah.water.level = 100

    BroadcastHookahState(hookahId, 'water-state', 'good')
    BroadcastHookahState(hookahId, 'water-level', 100)
    UpdateCanSmoke(hookahId)

    TriggerClientEvent('rtx_smoking:Global:UpdateWater', -1, hookahId, hookah.water)
    PersistHookahs()
    NotifyPlayer(source, 'success', 'Shisha', L('wateradded'))
end)

-- ── tabac : sélection du goût ─────────────────────────────
RegisterNetEvent('rtx_smoking:Global:FlavorSelect')
AddEventHandler('rtx_smoking:Global:FlavorSelect', function(hookahId, flavorKey)
    local source  = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah  = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end

    if hookah.tobacco.state ~= 'empty'
        and hookah.tobacco.state ~= 'filled'
        and hookah.tobacco.state ~= 'prepared'
    then
        NotifyPlayer(source, 'error', 'Shisha', L('tobaccoalreadybeingprepared'))
        return
    end

    local flavorDef = Config.HookahFlavors[flavorKey]
    if not flavorDef then
        NotifyPlayer(source, 'error', 'Shisha', L('noflavour'))
        return
    end
    if not HasItem(source, flavorDef.itemname) then
        NotifyPlayer(source, 'error', 'Shisha', L('noflavour'))
        return
    end
    if not RemoveItem(source, flavorDef.itemname, 1) then
        NotifyPlayer(source, 'error', 'Shisha', L('itemremovalfailed'))
        return
    end

    hookah.tobacco.state  = 'filled'
    hookah.tobacco.flavor = flavorDef.label
    hookah.tobacco.amount = 100

    BroadcastHookahState(hookahId, 'tobacco-state',  'filled')
    BroadcastHookahState(hookahId, 'tobacco-flavor', flavorDef.label)
    BroadcastHookahState(hookahId, 'tobacco-amount', 100)
    UpdateCanSmoke(hookahId)

    TriggerClientEvent('rtx_smoking:Global:UpdateTabacco', -1, hookahId, hookah.tobacco)
    PersistHookahs()
    NotifyPlayer(source, 'success', 'Shisha', L('flavourselected'))
end)

-- ── tabac : préparer la tête ──────────────────────────────
RegisterNetEvent('rtx_smoking:Global:FlavorPrepare')
AddEventHandler('rtx_smoking:Global:FlavorPrepare', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end
    if hookah.tobacco.state ~= 'filled' then
        NotifyPlayer(source, 'error', 'Shisha', L('needpreparetobacco'))
        return
    end

    hookah.tobacco.state = 'prepared'
    BroadcastHookahState(hookahId, 'tobacco-state', 'prepared')
    UpdateCanSmoke(hookahId)
    TriggerClientEvent('rtx_smoking:Global:UpdateTabacco', -1, hookahId, hookah.tobacco)
    PersistHookahs()
    NotifyPlayer(source, 'success', 'Shisha', L('tobaccoprepared'))
end)

-- ── charbon : chauffage ───────────────────────────────────
RegisterNetEvent('rtx_smoking:Global:CoalHeat')
AddEventHandler('rtx_smoking:Global:CoalHeat', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end
    if hookah.coal.state == 'heating' or hookah.coal.state == 'ready' or hookah.coal.state == 'placed' then
        NotifyPlayer(source, 'info', 'Shisha', L('coalalreadyactive'))
        return
    end

    if not HasItem(source, Config.CoalItem) then
        NotifyPlayer(source, 'error', 'Shisha', L('nocoal'))
        return
    end
    if not HasItem(source, Config.ItemNames['lighter']) then
        NotifyPlayer(source, 'error', 'Shisha', L('needlighter'))
        return
    end
    if not RemoveItem(source, Config.CoalItem, 1) then
        NotifyPlayer(source, 'error', 'Shisha', L('itemremovalfailed'))
        return
    end

    hookah.coal.state    = 'heating'
    hookah.coal.progress = 0

    BroadcastHookahState(hookahId, 'coal-state',    'heating')
    BroadcastHookahState(hookahId, 'coal-progress', 0)
    TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, hookah.coal)
    NotifyPlayer(source, 'success', 'Shisha', L('coalheating'))
    PersistHookahs()

    coalTimers[hookahId] = coalTimers[hookahId] or {}
    StopTimer(coalTimers[hookahId].heat)

    local elapsed  = 0
    local total    = Config.CoalHeatDuration
    local interval = Config.CoalHeatUpdateInterval

    coalTimers[hookahId].heat = SetTimer(interval, function(timer)
        elapsed = elapsed + interval
        hookah.coal.progress = math.min(100, math.floor(elapsed / total * 100))
        BroadcastHookahState(hookahId, 'coal-progress', hookah.coal.progress)
        TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, hookah.coal)
        PersistHookahs()

        if elapsed >= total then
            StopTimer(timer)
            if coalTimers[hookahId] then coalTimers[hookahId].heat = nil end
            hookah.coal.state      = 'ready'
            hookah.coal.progress   = 100
            hookah.coal.durability = 100
            BroadcastHookahState(hookahId, 'coal-state',      'ready')
            BroadcastHookahState(hookahId, 'coal-progress',   100)
            BroadcastHookahState(hookahId, 'coal-durability', 100)
            TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, hookah.coal)
            PersistHookahs()
        end
    end)
end)

-- ── charbon : placement sur la tête ──────────────────────
RegisterNetEvent('rtx_smoking:Global:CoalPlace')
AddEventHandler('rtx_smoking:Global:CoalPlace', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end
    if hookah.coal.state ~= 'ready' then
        NotifyPlayer(source, 'error', 'Shisha', L('coalnotready'))
        return
    end
    if hookah.tobacco.state ~= 'prepared' then
        NotifyPlayer(source, 'error', 'Shisha', L('needpreparetobacco'))
        return
    end

    hookah.coal.state      = 'placed'
    hookah.coal.durability = 100
    BroadcastHookahState(hookahId, 'coal-state',      'placed')
    BroadcastHookahState(hookahId, 'coal-durability', 100)
    UpdateCanSmoke(hookahId)
    TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, hookah.coal)

    PersistHookahs()
    StartCoalBurnTimer(hookahId)
end)

function StartCoalBurnTimer(hookahId)
    local hookah   = hookahs[hookahId]
    if not hookah then return end
    coalTimers[hookahId] = coalTimers[hookahId] or {}
    if coalTimers[hookahId].burn then StopTimer(coalTimers[hookahId].burn) end

    local total    = Config.CoalBurnDuration
    local interval = Config.CoalBurnUpdateInterval
    local elapsed  = total * (1 - (tonumber(hookah.coal.durability) or 100) / 100)

    coalTimers[hookahId].burn = SetTimer(interval, function(timer)
        local h = hookahs[hookahId]
        if not h or h.coal.state ~= 'placed' then
            StopTimer(timer)
            return
        end
        elapsed = elapsed + interval
        h.coal.durability = math.max(0, math.floor((1 - elapsed / total) * 100))
        BroadcastHookahState(hookahId, 'coal-durability', h.coal.durability)
        TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, h.coal)
        PersistHookahs()

        if elapsed >= total then
            StopTimer(timer)
            if coalTimers[hookahId] then coalTimers[hookahId].burn = nil end
            h.coal.state      = 'missing'
            h.coal.durability = 0
            BroadcastHookahState(hookahId, 'coal-state',      'missing')
            BroadcastHookahState(hookahId, 'coal-durability', 0)
            BroadcastHookahState(hookahId, 'can-smoke',       false)
            TriggerClientEvent('rtx_smoking:Global:UpdateCoal', -1, hookahId, h.coal)
            PersistHookahs()
        end
    end)
end

-- ── peut-on fumer ─────────────────────────────────────────
function UpdateCanSmoke(hookahId)
    local h = hookahs[hookahId]
    if not h then return end
    local canSmoke = (
        h.coal.state    == 'placed'   and
        h.tobacco.state == 'prepared' and
        h.water.state   ~= 'empty'
    )
    BroadcastHookahState(hookahId, 'can-smoke', canSmoke)
    if canSmoke then
        BroadcastHookahState(hookahId, 'status', 'ready')
    else
        BroadcastHookahState(hookahId, 'status', 'preparing')
    end
end

-- ── nettoyage ─────────────────────────────────────────────
function StopCoalTimers(hookahId)
    local t = coalTimers[hookahId]
    if t then
        StopTimer(t.heat)
        StopTimer(t.burn)
        coalTimers[hookahId] = nil
    end
end

function CleanHookahById(hookahId)
    local hookah = hookahs[hookahId]
    if not hookah then return false end

    StopCoalTimers(hookahId)

    hookah.water   = { state = 'empty',   level = 0 }
    hookah.tobacco = { state = 'empty',   amount = 0, flavor = nil }
    hookah.coal    = { state = 'missing', progress = 0, durability = 0 }

    BroadcastHookahState(hookahId, 'water-state',     'empty')
    BroadcastHookahState(hookahId, 'water-level',     0)
    BroadcastHookahState(hookahId, 'tobacco-state',   'empty')
    BroadcastHookahState(hookahId, 'tobacco-amount',  0)
    BroadcastHookahState(hookahId, 'tobacco-flavor',  '')
    BroadcastHookahState(hookahId, 'coal-state',      'missing')
    BroadcastHookahState(hookahId, 'coal-progress',   0)
    BroadcastHookahState(hookahId, 'coal-durability', 0)
    BroadcastHookahState(hookahId, 'can-smoke',       false)
    BroadcastHookahState(hookahId, 'status',          'preparing')

    TriggerClientEvent('rtx_smoking:Global:UpdateWater',   -1, hookahId, hookah.water)
    TriggerClientEvent('rtx_smoking:Global:UpdateTabacco', -1, hookahId, hookah.tobacco)
    TriggerClientEvent('rtx_smoking:Global:UpdateCoal',    -1, hookahId, hookah.coal)
    PersistHookahs()
    return true
end

RegisterNetEvent('rtx_smoking:Global:CleanHookah')
AddEventHandler('rtx_smoking:Global:CleanHookah', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    if not hookahs[hookahId] then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end
    if not CanManageHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end
    if CleanHookahById(hookahId) then
        NotifyPlayer(source, 'success', 'Shisha', L('hookahcleaned'):format(hookahId))
    end
end)

-- ── suppression d'un narguilé ─────────────────────────────
function RemoveHookahById(hookahId, remover)
    local hookah = hookahs[hookahId]
    if not hookah then return false end
    local cfg = Config.HookahAdmin or {}
    if hookah.isStatic and cfg.allowStaticRemoval ~= true then return false end
    if hookah.isStatic and remover and remover > 0 and not IsHookahAdmin(remover) then return false end

    -- Forcer la déconnexion de tous les tuyaux
    if hoseConnections[hookahId] then
        for sid, _ in pairs(hoseConnections[hookahId]) do
            TriggerClientEvent('rtx_smoking:client:ForceReleaseHose', sid, hookahId)
        end
        hoseConnections[hookahId] = nil
    end
    BroadcastHookahState(hookahId, 'connected', 0)

    StopCoalTimers(hookahId)

    -- Rendre l'item
    if not hookah.isStatic then
        local typeDef = Config.HookahTypes[hookah.type]
        if typeDef then
            local isAdminRemover = remover and remover > 0 and IsHookahAdmin(remover)
            if cfg.returnItemToAdmin and isAdminRemover then
                GiveItem(remover, typeDef.item, 1)
            elseif hookah.ownerId and hookah.ownerIdentifier
                and GetPlayerName(hookah.ownerId)
                and GetLicenseIdentifier(hookah.ownerId) == hookah.ownerIdentifier
            then
                GiveItem(hookah.ownerId, typeDef.item, 1)
            elseif remover and hookah.ownerIdentifier == GetLicenseIdentifier(remover) then
                GiveItem(remover, typeDef.item, 1)
            end
        end
    end

    if cfg.logToConsole then
        local name = (remover and remover > 0 and GetPlayerName(remover)) or 'console'
        local ident = (remover and remover > 0 and GetLicenseIdentifier(remover)) or 'console'
        print(string.format('[RTX SMOKING] Hookah %d removed by %s (%s)', hookahId, name, ident))
    end

    hookahs[hookahId] = nil
    if hookah.isStatic and hookah.staticIdx ~= nil then
        removedStaticHookahs[hookah.staticIdx] = true
    end
    PersistHookahs()
    TriggerClientEvent('rtx_smoking:Global:HookahRemove', -1, hookahId)
    return true
end

RegisterNetEvent('rtx_smoking:Global:RemoveHookah')
AddEventHandler('rtx_smoking:Global:RemoveHookah', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then return end
    local cfg     = Config.HookahAdmin or {}
    local isAdmin = IsHookahAdmin(source)

    if not CanRemoveHookah(source, hookahId) then
        NotifyPlayer(source, 'error', 'Shisha', L('nohookahpermission'))
        return
    end

    if hookah.isStatic and cfg.allowStaticRemoval ~= true then
        NotifyPlayer(source, 'error', 'Shisha', L('cannotremovestatichookah'))
        return
    end

    local connected = 0
    if hoseConnections[hookahId] then
        for _ in pairs(hoseConnections[hookahId]) do connected = connected + 1 end
    end
    if connected > 0 and not cfg.forceDisconnectHoses and not isAdmin then
        NotifyPlayer(source, 'error', 'Shisha', L('cannotremovehookahhose'))
        return
    end

    RemoveHookahById(hookahId, source)
end)

-- ── tuyau : connexion ─────────────────────────────────────
RegisterNetEvent('rtx_smoking:Global:ConnectHose')
AddEventHandler('rtx_smoking:Global:ConnectHose', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then
        NotifyPlayer(source, 'error', 'Shisha', L('hookahnotfound'):format(hookahId))
        return
    end

    if not IsNear(source, hookah.coords, (Config.HookahInteractDistance or 3.0) + 5.0) then
        NotifyPlayer(source, 'error', 'Shisha', L('hosehookahnotnearby'))
        return
    end
    for otherId, conns in pairs(hoseConnections) do
        if conns[source] then
            NotifyPlayer(source, 'error', 'Shisha', L('alreadyusinghookah'))
            return
        end
    end

    local connected = 0
    for _ in pairs(hoseConnections[hookahId] or {}) do connected = connected + 1 end
    if connected >= Config.MaxHoses then
        NotifyPlayer(source, 'error', 'Shisha', L('maxhosesreached'))
        return
    end

    -- Déjà connecté ?
    if hoseConnections[hookahId] and hoseConnections[hookahId][source] then
        NotifyPlayer(source, 'error', 'Shisha', L('alreadyusinghookah'))
        return
    end

    hoseConnections[hookahId] = hoseConnections[hookahId] or {}
    hoseConnections[hookahId][source] = true
    SyncHookahHoses(hookahId)

    connected = connected + 1
    BroadcastHookahState(hookahId, 'connected', connected)
    BroadcastHookahState(hookahId, 'hose-' .. source .. '-state',     'idle')
    BroadcastHookahState(hookahId, 'hose-' .. source .. '-connected', true)

    TriggerClientEvent('rtx_smoking:Global:HosePlayerAdded', -1, hookahId, source)
    TriggerClientEvent('rtx_smoking:Global:Connected',       -1, hookahId, connected)
    NotifyPlayer(source, 'success', 'Shisha', L('hoseconnected'))
end)

-- ── tuyau : déconnexion ───────────────────────────────────
function DisconnectPlayerHoses(src)
    for hookahId, connections in pairs(hoseConnections) do
        if connections[src] then
            connections[src] = nil
            SyncHookahHoses(hookahId)
            local connected = 0
            for _ in pairs(connections) do connected = connected + 1 end
            BroadcastHookahState(hookahId, 'connected',                    connected)
            BroadcastHookahState(hookahId, 'hose-' .. src .. '-connected', false)
            BroadcastHookahState(hookahId, 'hose-' .. src .. '-state',     'idle')
            TriggerClientEvent('rtx_smoking:Global:HosePlayerRemoved', -1, hookahId, src)
            TriggerClientEvent('rtx_smoking:Global:Connected',         -1, hookahId, connected)
        end
    end
end

RegisterNetEvent('rtx_smoking:Global:DisconnectHose')
AddEventHandler('rtx_smoking:Global:DisconnectHose', function()
    DisconnectPlayerHoses(source)
end)

-- ── inhale narguilé : début ───────────────────────────────
RegisterNetEvent('rtx_smoking:Global:HookahInhaleStart')
AddEventHandler('rtx_smoking:Global:HookahInhaleStart', function(hookahId)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then return end
    if not (hoseConnections[hookahId] and hoseConnections[hookahId][source]) then return end
    BroadcastHookahState(hookahId, 'hose-' .. source .. '-state', 'inhale')
end)

-- ── inhale narguilé : fin ────────────────────────────────
RegisterNetEvent('rtx_smoking:Global:HookahInhaleStop')
AddEventHandler('rtx_smoking:Global:HookahInhaleStop', function(hookahId, holdDurationMs)
    local source = source
    hookahId = NormalizeHookahId(hookahId)
    if not hookahId then return end
    local hookah = hookahs[hookahId]
    if not hookah then return end
    if not (hoseConnections[hookahId] and hoseConnections[hookahId][source]) then return end
    holdDurationMs = math.max(0, math.min(tonumber(holdDurationMs) or 0, 15000))

    BroadcastHookahState(hookahId, 'hose-' .. source .. '-state', 'idle')

    -- Consommation tabac/eau
    local tobaccoConsume = Config.HookahTobaccoConsume or 4
    local waterConsume   = Config.HookahWaterConsume   or 3

    hookah.tobacco.amount = math.max(0, (hookah.tobacco.amount or 100) - tobaccoConsume)
    hookah.water.level    = math.max(0, (hookah.water.level    or 100) - waterConsume)

    if hookah.tobacco.amount <= 0 then
        hookah.tobacco.state = 'empty'
        BroadcastHookahState(hookahId, 'tobacco-state', 'empty')
    end

    if hookah.water.level <= (Config.HookahLowWaterLevel or 20) then
        hookah.water.state = 'low'
    end
    if hookah.water.level <= 0 then
        hookah.water.state = 'empty'
        hookah.water.level = 0
    end

    BroadcastHookahState(hookahId, 'tobacco-amount', hookah.tobacco.amount)
    BroadcastHookahState(hookahId, 'water-level',    hookah.water.level)
    BroadcastHookahState(hookahId, 'water-state',    hookah.water.state)

    UpdateCanSmoke(hookahId)

    TriggerClientEvent('rtx_smoking:Global:UpdateTabacco', -1, hookahId, hookah.tobacco)
    TriggerClientEvent('rtx_smoking:Global:UpdateWater',   -1, hookahId, hookah.water)
    PersistHookahs()

    -- Fumée visible pour les autres joueurs
    TriggerClientEvent('rtx_smoking:Global:HookahExhaleSmoke', -1, hookahId, source, holdDurationMs)
end)

-- ── état de fumée général (cigarette, joint, etc.) ────────
RegisterNetEvent('rtx_smoking:server:SetSmokingState')
AddEventHandler('rtx_smoking:server:SetSmokingState', function(data)
    local source = source
    if type(data) ~= 'table' then return end
    if data.smoking then
        playerSmoking[source] = { smoking = true, item = data.item, type = data.type }
    else
        playerSmoking[source] = nil
    end
end)

function IsPlayerSmokingServer(source)
    return playerSmoking[source] ~= nil and playerSmoking[source].smoking == true
end

-- ── vérification allumage cigarette/joint ────────────────
RegisterNetEvent('rtx_smoking:server:lightCheck')
AddEventHandler('rtx_smoking:server:lightCheck', function(itemKey, itemType)
    local source = source
    if not HasItem(source, Config.ItemNames['lighter']) then
        NotifyPlayer(source, 'error', '', L('needlighter'))
        return
    end
    TriggerClientEvent('rtx_smoking:LightCigarette', source)
end)

-- ── bouffée (consommation item) ───────────────────────────
RegisterNetEvent('rtx_smoking:server:OnPuff')
AddEventHandler('rtx_smoking:server:OnPuff', function(puffData)
    local source = source
    -- Ici vous pouvez ajouter vos effets serveur (hunger, thirst, stress, etc.)
    -- puffData.item, puffData.type, puffData.amount, puffData.holdDuration, puffData.stats
end)

-- ── particule synchronisée ────────────────────────────────
RegisterNetEvent('rtx_smoking:server:SyncPedParticle')
AddEventHandler('rtx_smoking:server:SyncPedParticle', function(particleData)
    local source = source
    if type(particleData) ~= 'table' then return end
    particleData.sourceServerId = source
    TriggerClientEvent('rtx_smoking:client:SyncPedParticle', -1, particleData)
end)

-- ── sons synchronisés ─────────────────────────────────────
local syncedSoundLoops = {}

local function GetNearbySoundRecipients(source)
    local sourcePed = GetPlayerPed(source)
    if not sourcePed or sourcePed == 0 then return {} end

    local sourceCoords = GetEntityCoords(sourcePed)
    local maxDistance = tonumber(Config.SoundEffectsDistance) or 5.0
    if maxDistance <= 0 then return {} end

    local recipients = {}
    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and target ~= source then
            local targetPed = GetPlayerPed(target)
            if targetPed and targetPed ~= 0 then
                local targetCoords = GetEntityCoords(targetPed)
                if #(sourceCoords - targetCoords) <= maxDistance then
                    recipients[target] = true
                end
            end
        end
    end
    return recipients
end

RegisterNetEvent('rtx_smoking:server:RequestSound')
AddEventHandler('rtx_smoking:server:RequestSound', function(soundData)
    local source   = source
    if type(soundData) ~= 'table' or type(soundData.soundKey) ~= 'string' then return end
    local soundKey = soundData.soundKey
    if not soundKey or not Config.Sounds or not Config.Sounds[soundKey] then return end

    local src      = Config.Sounds[soundKey]
    local loopId   = soundData.loopId
    local isLoop   = soundData.isLoop == true
    local shouldStop = soundData.shouldStop == true
    if isLoop and (type(loopId) ~= 'string' or #loopId == 0 or #loopId > 64) then return end

    local volume   = Config.SoundEffectsVolume or 0.45
    local distance = Config.SoundEffectsDistance or 5.0

    if isLoop and shouldStop then
        local playerLoops = syncedSoundLoops[source]
        local recipients = playerLoops and playerLoops[loopId]
        if not recipients then return end

        for recipient in pairs(recipients) do
            TriggerClientEvent('rtx_smoking:client:PlaySyncedSound', recipient, {
                loopId = loopId,
                shouldStop = true,
            })
        end
        playerLoops[loopId] = nil
        if not next(playerLoops) then syncedSoundLoops[source] = nil end
        return
    end

    local payload = {
        soundKey   = soundKey,
        src        = src,
        loopId     = loopId,
        isLoop     = isLoop,
        shouldStop = shouldStop,
        sourceId   = source,
        baseVolume = volume,
        maxDistance = distance,
        volume     = volume,
    }

    local recipients = GetNearbySoundRecipients(source)
    if isLoop then
        syncedSoundLoops[source] = syncedSoundLoops[source] or {}
        syncedSoundLoops[source][loopId] = recipients
    end
    for recipient in pairs(recipients) do
        TriggerClientEvent('rtx_smoking:client:PlaySyncedSound', recipient, payload)
    end
end)

-- ── don d'item entre joueurs ──────────────────────────────
RegisterNetEvent('rtx_smoking:server:GiveSmokingItem')
AddEventHandler('rtx_smoking:server:GiveSmokingItem', function(targetServerId, giftData)
    local source = source
    local giver  = source
    targetServerId = tonumber(targetServerId)

    if not targetServerId or targetServerId == giver
        or type(giftData) ~= 'table'
        or type(giftData.variantKey) ~= 'string'
        or type(giftData.state) ~= 'table'
    then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    local variantDef = Config.SmokingVariants and Config.SmokingVariants[giftData.variantKey]
    if not variantDef then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    local activeSmoking = playerSmoking[giver]
    if not activeSmoking
        or activeSmoking.item ~= giftData.variantKey
        or activeSmoking.type ~= variantDef.type
    then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    if not HasItem(giver, variantDef.item) then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    if not GetPlayerName(targetServerId) then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    if playerSmoking[targetServerId] then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    local tPed = GetPlayerPed(targetServerId)
    if not tPed or tPed == 0
        or not IsNear(giver, GetEntityCoords(tPed), Config.GiveDistance or 3.0)
    then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    if not RemoveItem(giver, variantDef.item, 1) then
        TriggerClientEvent('rtx_smoking:client:GiveFailed', giver, nil)
        return
    end

    TriggerClientEvent('rtx_smoking:client:GiveSucceeded', giver)
    TriggerClientEvent('rtx_smoking:client:ReceiveSmokingItem', targetServerId, giver, giftData)
end)

-- ── crafting joint ────────────────────────────────────────
RegisterNetEvent('rtx_smoking:server:CraftJoint')
AddEventHandler('rtx_smoking:server:CraftJoint', function(fillKey)
    local source    = source
    local jointSets = Config.SelectionSets and Config.SelectionSets['joint']
    if not jointSets or not jointSets[fillKey] then return end
    local entry = jointSets[fillKey]

    if not HasItem(source, Config.ItemNames['rolling_paper']) then
        NotifyPlayer(source, 'error', '', L('needrollingpaper'))
        return
    end
    if not HasItem(source, entry.itemname) then
        NotifyPlayer(source, 'error', '', L('missingweed'))
        return
    end

    if not RemoveItem(source, Config.ItemNames['rolling_paper'], 1) then return end
    if not RemoveItem(source, entry.itemname, 1) then
        GiveItem(source, Config.ItemNames['rolling_paper'], 1)
        return
    end
    if not GiveItem(source, entry.itemnamecrafted, 1) then
        GiveItem(source, Config.ItemNames['rolling_paper'], 1)
        GiveItem(source, entry.itemname, 1)
        return
    end

    TriggerClientEvent('rtx_smoking:CraftJoint', source, fillKey)
end)

RegisterNetEvent('rtx_smoking:server:CraftedJoint')
AddEventHandler('rtx_smoking:server:CraftedJoint', function(fillKey)
    -- appelé après l'animation côté client, rien à faire ici sauf log éventuel
end)

-- ── remplissage bong ──────────────────────────────────────
RegisterNetEvent('rtx_smoking:server:FillBong')
AddEventHandler('rtx_smoking:server:FillBong', function(fillKey)
    local source   = source
    local bongSets = Config.SelectionSets and Config.SelectionSets['bong']
    if not bongSets or not bongSets[fillKey] then return end
    local entry = bongSets[fillKey]

    if not HasItem(source, entry.itemname) then
        NotifyPlayer(source, 'error', '', L('missingweed'))
        return
    end
    if not RemoveItem(source, entry.itemname, 1) then return end
    TriggerClientEvent('rtx_smoking:FillChange', source, fillKey)
end)

-- ── eau bong ─────────────────────────────────────────────
RegisterNetEvent('rtx_smoking:server:RemoveWater')
AddEventHandler('rtx_smoking:server:RemoveWater', function()
    local source = source
    if not HasItem(source, Config.ItemNames['water']) then
        NotifyPlayer(source, 'error', '', L('waterneeded'))
        return
    end
    if not RemoveItem(source, Config.ItemNames['water'], 1) then return end
    TriggerClientEvent('rtx_smoking:WaterChange', source)
end)

-- ── remplissage vape liquide ──────────────────────────────
RegisterNetEvent('rtx_smoking:server:removeLiquid')
AddEventHandler('rtx_smoking:server:removeLiquid', function(flavorKey)
    local source   = source
    local vapeSets = Config.SelectionSets and Config.SelectionSets['vape']
    if not vapeSets or not vapeSets[flavorKey] then return end
    local entry = vapeSets[flavorKey]

    if not HasItem(source, entry.itemname) then
        NotifyPlayer(source, 'error', '', L('needeliquidbox'))
        return
    end
    if not RemoveItem(source, entry.itemname, 1) then return end
    TriggerClientEvent('rtx_smoking:LiquidChange', source, flavorKey)
end)

-- ── batterie vape ─────────────────────────────────────────
RegisterNetEvent('rtx_smoking:server:removeVapeBattery')
AddEventHandler('rtx_smoking:server:removeVapeBattery', function()
    local source = source
    if not HasItem(source, Config.ItemNames['vape_battery']) then
        NotifyPlayer(source, 'error', '', L('needvapebattery'))
        return
    end
    if not RemoveItem(source, Config.ItemNames['vape_battery'], 1) then return end
    TriggerClientEvent('rtx_smoking:BatteryChange', source)
end)

-- ── sauvegarde métadonnées vape ───────────────────────────
RegisterNetEvent('rtx_smoking:server:SaveSmokingMetadata')
AddEventHandler('rtx_smoking:server:SaveSmokingMetadata', function(itemKey, state)
    -- Vape state persistence is inventory-specific; do not accept client metadata as authoritative.
end)

-- ── ouverture d'un pack ───────────────────────────────────
local function OpenPackForPlayer(playerSource, packItem)
    local reward  = Config.PackOpenRewards and Config.PackOpenRewards[packItem]
    if not reward then return end
    if not HasItem(playerSource, packItem) then return end
    if not RemoveItem(playerSource, packItem, 1) then return end
    if not GiveItem(playerSource, reward.item, reward.count) then
        if not GiveItem(playerSource, packItem, 1) then
            print(('[RTX SMOKING] Failed to grant pack "%s" back to player %s after reward delivery failed.')
                :format(packItem, tostring(playerSource)))
        end
        NotifyPlayer(playerSource, 'error', '', 'There is not enough inventory space to open this pack.')
    end
end

RegisterNetEvent('rtx_smoking:server:OpenPack')
AddEventHandler('rtx_smoking:server:OpenPack', function(packItem)
    OpenPackForPlayer(source, packItem)
end)

local function RegisterUsableItem(itemName, callback)
    if Config.Framework == 'qbcore' and QBCore then
        QBCore.Functions.CreateUseableItem(itemName, callback)
        return true
    elseif Config.Framework == 'esx' and ESX then
        ESX.RegisterUsableItem(itemName, function(playerSource)
            callback(playerSource)
        end)
        return true
    end

    print(('[RTX SMOKING] Cannot register usable item "%s": unsupported or unavailable framework "%s"')
        :format(itemName, tostring(Config.Framework)))
    return false
end

local function GetItemState(item)
    if type(item) ~= 'table' then return nil end
    local state = item.metadata
    if type(state) == 'table' and next(state) then return state end
    state = item.info
    if type(state) == 'table' and next(state) then
        return state
    end
    return nil
end

local registeredUsableItems = {}
local function RegisterSmokingItem(itemName, callback)
    if type(itemName) ~= 'string' or itemName == '' or registeredUsableItems[itemName] then return end
    if RegisterUsableItem(itemName, callback) then
        registeredUsableItems[itemName] = true
    end
end

for variantKey, variant in pairs(Config.SmokingVariants or {}) do
    local itemName = variant.item
    local itemType = variant.type
    local savedVariantKey = variantKey
    RegisterSmokingItem(itemName, function(playerSource, item)
        TriggerClientEvent(
            'rtx_smoking:client:useItem',
            playerSource,
            itemType,
            savedVariantKey,
            GetItemState(item)
        )
    end)
end

for hookahTypeId, hookahType in pairs(Config.HookahTypes or {}) do
    local itemName = hookahType.item
    local savedHookahTypeId = hookahTypeId
    local color = hookahType.color
    RegisterSmokingItem(itemName, function(playerSource)
        TriggerClientEvent('rtx_smoking:Global:Place', playerSource, savedHookahTypeId, color)
    end)
end

for packItem in pairs(Config.PackOpenRewards or {}) do
    local itemName = packItem
    RegisterSmokingItem(itemName, function(playerSource)
        OpenPackForPlayer(playerSource, itemName)
    end)
end

RegisterSmokingItem(Config.ItemNames and Config.ItemNames.rolling_paper, function(playerSource)
    TriggerClientEvent('rtx_smoking:client:useItem', playerSource, 'rolling_paper', 'rolling_paper')
end)

-- ── export serveur IsPlayerSmoking ────────────────────────
exports('IsPlayerSmoking', function(source)
    return IsPlayerSmokingServer(source)
end)

-- ── nettoyage à la déconnexion ────────────────────────────
AddEventHandler('playerDropped', function()
    local source = source
    playerSmoking[source] = nil
    lastPlace[source] = nil
    syncedSoundLoops[source] = nil
    DisconnectPlayerHoses(source)
end)

-- ── commandes admin ───────────────────────────────────────
local adminCmds = Config.HookahAdmin and Config.HookahAdmin.commands

if adminCmds then
    -- /removehookah [id]
    if adminCmds.removeNearby then
        RegisterCommand(adminCmds.removeNearby, function(source, args)
            if not IsHookahAdmin(source) then
                NotifyPlayer(source, 'error', 'Admin', L('nohookahpermission'))
                return
            end
            local hookahId = tonumber(args[1])
            if hookahId and hookahs[hookahId] then
                RemoveHookahById(hookahId, source)
                NotifyPlayer(source, 'info', 'Admin', string.format(L('hookahremoved'), hookahId))
            else
                NotifyPlayer(source, 'error', 'Admin', string.format(L('hookahnotfound'), tostring(hookahId)))
            end
        end, false)
    end

    -- /removeallhookahs
    if adminCmds.removeAll then
        RegisterCommand(adminCmds.removeAll, function(source, args)
            if not IsHookahAdmin(source) then
                NotifyPlayer(source, 'error', 'Admin', L('nohookahpermission'))
                return
            end
            local count = 0
            local ids = {}
            for hookahId, _ in pairs(hookahs) do ids[#ids + 1] = hookahId end
            for _, hookahId in ipairs(ids) do
                RemoveHookahById(hookahId, source)
                count = count + 1
            end
            NotifyPlayer(source, 'info', 'Admin', string.format(L('allhookahsremoved'), count))
        end, false)
    end

    -- /cleanhookah [id]
    if adminCmds.cleanNearby then
        RegisterCommand(adminCmds.cleanNearby, function(source, args)
            if not IsHookahAdmin(source) then
                NotifyPlayer(source, 'error', 'Admin', L('nohookahpermission'))
                return
            end
            local hookahId = tonumber(args[1])
            if hookahId and hookahs[hookahId] then
                CleanHookahById(hookahId)
                NotifyPlayer(source, 'info', 'Admin', string.format(L('hookahcleaned'), hookahId))
            else
                NotifyPlayer(source, 'error', 'Admin', string.format(L('hookahnotfound'), tostring(hookahId)))
            end
        end, false)
    end

    -- /hookahlist
    if adminCmds.list then
        RegisterCommand(adminCmds.list, function(source, args)
            if not IsHookahAdmin(source) then
                NotifyPlayer(source, 'error', 'Admin', L('nohookahpermission'))
                return
            end
            local count = 0
            for hookahId, hookah in pairs(hookahs) do
                count = count + 1
                print(string.format('[RTX SMOKING] Hookah %d | Owner: %s | Coords: %.1f, %.1f, %.1f',
                    hookahId,
                    hookah.ownerId and tostring(hookah.ownerId) or 'static',
                    hookah.coords.x, hookah.coords.y, hookah.coords.z
                ))
            end
            NotifyPlayer(source, 'info', 'Admin', string.format(L('hookahlisttotal'), count))
        end, false)
    end
end