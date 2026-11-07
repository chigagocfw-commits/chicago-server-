-- SOUH4IL-DEV — Server Main Bootstrap
-- Author: SOUH4IL / Antigravity
-- Framework: Qbox / ox_lib / oxmysql

local SharedConfig = require 'config.shared'
local PermissionsConfig = require 'config.permissions'
local Identifiers = require 'server.identifiers'
local Security = require 'server.security'
local Permissions = require 'server.permissions'
local Logger = require 'server.logger'
local Outbox = require 'server.outbox'

-- ============================================================
-- SERVER-SIDE STAFF PERMISSION ENFORCEMENT
-- Every panel callback is mapped to a module (the same keys as the Staff tab:
-- players, teleport, vehicles, punishments, items, characters, jobs, world,
-- devtools, arsenal, god, logs, events, staff). A staff member can only call a
-- callback if that module is enabled for them. Hiding tabs in the UI is NOT
-- enough, so this is enforced here. Owner always bypasses.
-- Callbacks not listed keep their original checks.
-- ============================================================
local CALLBACK_MODULES = {
    -- players / moderation
    getPlayerDetails = { 'view_players', 'players' },
    messagePlayer = { 'view_players', 'players' },
    trollPlayer = { 'manage_trolls', 'god_powers', 'god' },
    healPlayer = { 'player_heal', 'players' },
    controlPlayerVitals = { 'player_heal', 'players' },
    -- teleport
    teleportAction = { 'player_teleport', 'world_teleport', 'teleport' },
    teleportPlayerToPlayer = { 'player_teleport', 'teleport' },
    teleportToProperty = { 'player_teleport', 'world_teleport', 'teleport' },
    getSpectateCoords = { 'player_spectate', 'players' },
    -- punishments
    banPlayer = { 'punish_bans' },
    kickPlayer = { 'punish_kicks' },
    warnPlayer = { 'punish_kicks' },
    freezePlayer = { 'player_freeze', 'players' },
    forceLogout = { 'punish_kicks' },
    banOfflinePlayer = { 'punish_bans' },
    unbanPlayer = { 'punish_bans' },
    -- items / money / inventories
    giveItem = { 'spawn_items', 'items' },
    giveItemToPlayer = { 'spawn_items', 'items' },
    giveMoney = { 'manage_money' },
    managePlayerMoney = { 'manage_money' },
    getAllGameItems = { 'spawn_items', 'items' },
    removePlayerItem = { 'player_inventory', 'items' },
    clearPlayerInventory = { 'player_inventory', 'items' },
    openInventory = { 'player_inventory', 'items' },
    createStash = { 'devtools' },
    openHouseStash = { 'player_inventory', 'manage_assets', 'items' },
    openVehicleTrunk = { 'player_inventory', 'manage_assets', 'items' },
    openVehicleGlovebox = { 'player_inventory', 'manage_assets', 'items' },
    -- vehicles
    giveVehicleKeys = { 'spawn_vehicles', 'vehicles' },
    giveKeysToPlayer = { 'spawn_vehicles', 'vehicles' },
    setVehiclePlate = { 'manage_assets', 'vehicles' },
    getAllGameVehicles = { 'spawn_vehicles', 'vehicles' },
    saveMyCurrentVehicle = { 'manage_assets', 'vehicles' },
    seizePlayerVehicle = { 'manage_assets' },
    givePlayerOwnedVehicle = { 'manage_assets' },
    bringPlayerVehicle = { 'manage_assets', 'vehicles' },
    storePlayerVehicle = { 'manage_assets', 'vehicles' },
    repairPlayerVehicle = { 'spawn_vehicles', 'vehicles' },
    transferPlayerVehicle = { 'manage_assets' },
    controlPlayerVehicle = { 'spawn_vehicles', 'vehicles' },
    spawnVehicleDirect = { 'spawn_vehicles', 'vehicles' },
    -- characters / properties / skins
    getAllGameCharacters = { 'manage_skins', 'characters' },
    controlPlayerAppearance = { 'manage_skins', 'characters' },
    wipePlayer = { 'manage_wipes' },
    givePlayerProperty = { 'manage_assets' },
    seizePlayerProperty = { 'manage_assets' },
    givePropertyKey = { 'manage_assets' },
    resetPropertyKeyholders = { 'manage_assets' },
    transferPlayerProperty = { 'manage_assets' },
    -- jobs / gangs
    setPlayerJob = { 'manage_jobs', 'jobs' },
    setPlayerJobDirect = { 'manage_jobs', 'jobs' },
    setPlayerGang = { 'manage_jobs', 'jobs' },
    getAllGameJobs = { 'manage_jobs', 'jobs' },
    setMyJob = { 'manage_jobs', 'jobs' },
    -- arsenal
    giveArsenalLoadout = { 'arsenal' },
    -- world / server
    broadcastAnnouncement = { 'world_control', 'world' },
    setTime = { 'world_control', 'world' },
    setBlackout = { 'world_control', 'world' },
    setTrafficDensity = { 'world_control', 'world' },
    getNpcConfig = { 'world_control', 'world' },
    updateNpcConfig = { 'world_control', 'world' },
    cleanNpcCopsNow = { 'world_control', 'world' },
    massServerAction = { 'world_control', 'world' },
    reviveAll = { 'world_control', 'player_heal', 'world' },
    reviveInRadius = { 'world_control', 'player_heal', 'world' },
    -- devtools & cleaning
    cleanArea = { 'devtools' },
    -- events
    triggerServerEvent = { 'events' },
    stopServerEvent = { 'events' },
    -- staff management
    getStaffData = { 'staff_management', 'staff' },
    saveStaffMember = { 'staff_management', 'staff' },
    removeStaffMember = { 'staff_management', 'staff' },
    -- previously unprotected callbacks (security fix)
    getOnlinePlayers = { 'view_players', 'players' },
    toggleDuty = { 'manage_jobs', 'jobs' },
    removeStress = { 'player_heal', 'players' },
    getEventState = { 'events' },
    setTrafficDensity = { 'world_control', 'world' },
}

-- Only the real owner may edit critical system gates (prevents privilege escalation).
local OWNER_ONLY_CALLBACKS = {
    managePermission = true,
}

do
    local originalRegister = lib.callback.register
    lib.callback.register = function(name, cb, ...)
        local short = type(name) == 'string' and name:match('^souh4il_dev:server:(.+)$')
        local modules = short and CALLBACK_MODULES[short]
        local ownerOnly = short and OWNER_ONLY_CALLBACKS[short]
        if not modules and not ownerOnly then
            return originalRegister(name, cb, ...)
        end

        return originalRegister(name, function(source, ...)
            if not Permissions.IsOwner(source) then
                local ok = not ownerOnly
                if ok and modules then
                    ok = false
                    for i = 1, #modules do
                        if Permissions.HasModulePermission(source, modules[i]) then ok = true break end
                    end
                end
                if not ok then
                    Logger.Write("PERMISSION_DENIED", source, nil, { callback = short, required = modules or 'owner' }, "REJECTED")
                    return { success = false, error = "MODULE_PERMISSION_DENIED" }
                end
            end
            return cb(source, ...)
        end, ...)
    end
end

lib.print.info("==================================================================")
lib.print.info(("^2%s v%s — Control Panel Initializing...^0"):format(SharedConfig.PanelName, SharedConfig.Version))
lib.print.info(("^2Community: %s^0"):format(SharedConfig.Community))
lib.print.info("==================================================================")

-- Automatic Database Initialization (Idempotent: Safe if already created)
AddEventHandler('onResourceStart', function(resourceName)
    if resourceName ~= cache.resource then return end

    CreateThread(function()
        local success, err = pcall(function()
            MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `souh4il_dev_logs` (
                  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
                  `timestamp` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  `action` varchar(50) NOT NULL,
                  `executor_source` int(11) DEFAULT NULL,
                  `executor_name` varchar(100) NOT NULL,
                  `executor_license` varchar(50) NOT NULL,
                  `target_source` int(11) DEFAULT NULL,
                  `target_name` varchar(100) DEFAULT NULL,
                  `target_license` varchar(50) DEFAULT NULL,
                  `details` longtext DEFAULT NULL,
                  `status` enum('SUCCESS','REJECTED','INTRUSION_ALERT') NOT NULL DEFAULT 'SUCCESS',
                  `previous_hash` varchar(64) NOT NULL,
                  `hash` varchar(64) NOT NULL,
                  PRIMARY KEY (`id`),
                  KEY `idx_action` (`action`),
                  KEY `idx_executor` (`executor_license`),
                  KEY `idx_timestamp` (`timestamp`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]])

            MySQL.query.await([[CREATE TABLE IF NOT EXISTS `souh4il_dev_logs_archive` LIKE `souh4il_dev_logs`;]])

            MySQL.query.await([[
                CREATE TABLE IF NOT EXISTS `souh4il_dev_outbox` (
                  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT,
                  `log_id` bigint(20) unsigned NOT NULL,
                  `destination` varchar(100) NOT NULL,
                  `payload` longtext NOT NULL,
                  `signature` varchar(64) NOT NULL,
                  `attempts` tinyint(3) unsigned NOT NULL DEFAULT 0,
                  `status` enum('PENDING','SENT','FAILED') NOT NULL DEFAULT 'PENDING',
                  `last_error` text DEFAULT NULL,
                  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
                  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                  PRIMARY KEY (`id`),
                  KEY `idx_status` (`status`),
                  KEY `idx_log` (`log_id`)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
            ]])
        end)

        if success then
            lib.print.info(("^2%s — Database tables verified.^0"):format(SharedConfig.PanelName))
            -- Initialize Staff DB & Cache
            Permissions.InitDB()
        else
            lib.print.error(("^1%s — Database initialization error: %s^0"):format(SharedConfig.PanelName, tostring(err)))
        end
    end)
end)

---Callback 1: Ping / Health Check
lib.callback.register('souh4il_dev:server:ping', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'ping')
    if not allowed then
        return { success = false, error = reason }
    end

    return {
        success = true,
        panel = SharedConfig.PanelName,
        community = SharedConfig.Community,
        serverTime = os.time(),
        version = SharedConfig.Version
    }
end)

---Callback 2: Get Caller Security Status
lib.callback.register('souh4il_dev:server:getSecurityStatus', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'security_check')
    if not allowed then
        return { success = false, error = reason }
    end

    local role = Permissions.GetStaffRole(source)
    local isOwner = Permissions.IsOwner(source)
    local hasAccess = Permissions.CanOpenPanel(source)
    local perms = Permissions.GetPermissions(source)

    -- Log the status check
    Logger.Write("SECURITY_STATUS_QUERY", source, nil, { role = role, isOwner = isOwner }, "SUCCESS")

    return {
        success = true,
        role = role,
        isOwner = isOwner,
        hasAccess = hasAccess or isOwner,
        permissions = perms,
    }
end)

---Callback 3: Query Audit Logs (STRICTLY OWNER-ONLY)
lib.callback.register('souh4il_dev:server:queryAuditLogs', function(source, limit)
    local allowed, reason = Security.CheckRateLimit(source, 'audit_query')
    if not allowed then
        return { success = false, error = reason }
    end

    -- Dual-Key Gate enforcement
    if not Permissions.IsOwner(source) then
        local callerLic = Identifiers.GetLicense(source) or "UNKNOWN"
        lib.print.warn(('INTRUSION ALERT: Source %d [%s] attempted unauthorized audit log access!')
            :format(source, callerLic))

        Logger.Write("UNAUTHORIZED_AUDIT_LOG_READ_ATTEMPT", source, nil, { callerLicense = callerLic }, "INTRUSION_ALERT")
        Outbox.QueueDiscordAlert("UNAUTHORIZED_AUDIT_LOG_READ_ATTEMPT", GetPlayerName(tostring(source)) or "UNKNOWN", callerLic, { source = source })

        return { success = false, error = "FORBIDDEN_OWNER_REQUIRED" }
    end

    local queryLimit = math.min(100, math.max(1, math.tointeger(limit) or 25))
    local rows = MySQL.query.await([[
        SELECT id, timestamp, action, executor_name, executor_license, target_name, 
               target_license, details, status, previous_hash, hash
        FROM souh4il_dev_logs
        ORDER BY id DESC LIMIT ?
    ]], { queryLimit })

    Logger.Write("OWNER_AUDIT_LOG_QUERY", source, nil, { queryLimit = queryLimit, resultCount = #(rows or {}) }, "SUCCESS")

    return {
        success = true,
        logs = rows or {}
    }
end)

---Callback 4: Request Quick Action (Server-Side Authorized & Audited)
lib.callback.register('souh4il_dev:server:requestQuickAction', function(source, actionType)
    local allowed, reason = Security.CheckRateLimit(source, 'quick_action')
    if not allowed then
        return { success = false, error = reason }
    end

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.ACCESS) and not Permissions.IsOwner(source) then
        Logger.Write("UNAUTHORIZED_QUICK_ACTION_ATTEMPT", source, source, { action = actionType }, "REJECTED")
        return { success = false, error = "ACCESS_DENIED" }
    end

    if actionType == 'revive' then
        if GetResourceState('qbx_medical') == 'started' then
            exports.qbx_medical:Revive(source)
            Logger.Write("QUICK_ACTION_REVIVE", source, source, { type = "self_revive" }, "SUCCESS")
            return { success = true }
        end
        return { success = false, error = "qbx_medical not started" }
    elseif actionType == 'heal' then
        if GetResourceState('qbx_medical') == 'started' then
            exports.qbx_medical:Heal(source)
            Logger.Write("QUICK_ACTION_HEAL", source, source, { type = "self_heal" }, "SUCCESS")
            return { success = true }
        end
        return { success = false, error = "qbx_medical not started" }
    elseif actionType == 'repair' or actionType == 'clean' or actionType == 'tpm' or actionType == 'dv' then
        Logger.Write("QUICK_ACTION_" .. actionType:upper(), source, source, { type = actionType }, "SUCCESS")
        return { success = true }
    end

    return { success = false, error = "UNKNOWN_ACTION" }
end)

---NetEvent: Set Weather
RegisterNetEvent('souh4il_dev:server:setWeather', function(weatherType)
    local src = source
    local allowed, reason = Security.CheckRateLimit(src, 'weather_control')
    if not allowed then
        return
    end    if not Permissions.IsOwner(src) and not Permissions.HasModulePermission(src, 'world_control') then
        return
    end

    if weatherType and type(weatherType) == 'string' then
        local wUpper = weatherType:upper()
        GlobalState.weather = {
            weather = wUpper,
            time = 9999999999
        }
        pcall(function()
            if exports['Renewed-Weathersync'] and exports['Renewed-Weathersync'].setWeather then
                exports['Renewed-Weathersync']:setWeather(wUpper)
            end
        end)
        Logger.Write("SET_WEATHER", src, nil, { weather = wUpper }, "SUCCESS")
    end
end)

---Callback 5: Get Online Players
lib.callback.register('souh4il_dev:server:getOnlinePlayers', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_players')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper
    -- Financial data redaction: only show cash/bank to staff with manage_money
    local canSeeMoney = Permissions.IsOwner(source) or (Permissions.GetPermissions(source).manage_money == true)

    local players = {}
    local playerList = GetPlayers()

    for _, srcStr in ipairs(playerList) do
        local srcNum = tonumber(srcStr)
        if srcNum then
            local pName = GetPlayerName(srcStr) or ("Player #" .. srcStr)
            local pPing = GetPlayerPing(srcStr) or 0
            local qPlayer = exports.qbx_core:GetPlayer(srcNum)

            local citizenid = "N/A"
            local charName = pName
            local jobLabel = "Civilian"
            local jobName = "unemployed"
            local onDuty = false
            local gangName = "none"
            local cash = 0
            local bank = 0
            local isDead = false
            local ped = GetPlayerPed(srcStr)
            local inVehicle = (ped and ped ~= 0 and GetVehiclePedIsIn(ped, false) ~= 0) or false

            if qPlayer and qPlayer.PlayerData then
                citizenid = qPlayer.PlayerData.citizenid or "N/A"
                if qPlayer.PlayerData.charinfo then
                    local fn = qPlayer.PlayerData.charinfo.firstname or ""
                    local ln = qPlayer.PlayerData.charinfo.lastname or ""
                    if #fn > 0 or #ln > 0 then
                        charName = fn .. " " .. ln
                    end
                end
                if qPlayer.PlayerData.job then
                    jobLabel = qPlayer.PlayerData.job.label or qPlayer.PlayerData.job.name or "Civilian"
                    jobName = tostring(qPlayer.PlayerData.job.name or "unemployed"):lower()
                    onDuty = qPlayer.PlayerData.job.onduty == true
                end
                if qPlayer.PlayerData.gang then
                    gangName = tostring(qPlayer.PlayerData.gang.name or "none"):lower()
                end
                if qPlayer.PlayerData.money then
                    cash = tonumber(qPlayer.PlayerData.money.cash) or 0
                    bank = tonumber(qPlayer.PlayerData.money.bank) or 0
                end
                if qPlayer.PlayerData.metadata then
                    isDead = (qPlayer.PlayerData.metadata.isdead == true or qPlayer.PlayerData.metadata.inlaststand == true)
                end
            end

            table.insert(players, {
                id = srcNum,
                name = pName,
                charName = charName,
                citizenid = citizenid,
                ping = pPing,
                job = jobLabel,
                jobName = jobName,
                onDuty = onDuty,
                gangName = gangName,
                cash = canSeeMoney and cash or 0,
                bank = canSeeMoney and bank or 0,
                isDead = isDead,
                inVehicle = inVehicle,
                isFrozen = Player(srcNum).state.sdev_frozen == true,
                role = Permissions.GetStaffRole(srcNum)
            })
        end
    end

    return { success = true, players = players }
end)

---Callback 6: Ban Player (Strictly Authoritative via SQL bans table)
lib.callback.register('souh4il_dev:server:banPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'ban_player')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local targetId = tonumber(data.targetId)
    local banReason = data.reason or "Banned by administrator"
    local durationHours = tonumber(data.duration) or 0 -- 0 = permanent

    if not targetId or not DoesPlayerExist(tostring(targetId)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    if not Permissions.CanTargetPlayer(source, targetId) then
        return { success = false, error = "CANNOT_TARGET_EQUAL_OR_HIGHER_RANK" }
    end

    local targetLic = Identifiers.GetLicense(targetId) or "UNKNOWN"
    local targetDiscord = Identifiers.GetDiscord(targetId) or "NONE"
    local targetIp = GetPlayerEndpoint(tostring(targetId)) or "NONE"
    local targetName = GetPlayerName(tostring(targetId)) or "Unknown"
    local bannerName = GetPlayerName(tostring(source)) or "Staff"

    local expireTime = 2147483647
    if durationHours > 0 then
        expireTime = os.time() + (durationHours * 3600)
    end

    MySQL.insert.await('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        targetName,
        targetLic,
        targetDiscord,
        targetIp,
        banReason,
        expireTime,
        bannerName
    })

    Logger.Write("BAN_PLAYER", source, targetId, {
        targetName = targetName,
        targetLicense = targetLic,
        reason = banReason,
        durationHours = durationHours,
        expire = expireTime
    }, "SUCCESS")

    local banMsg = ("You have been banned by %s.\nReason: %s\nExpires: %s"):format(
        bannerName,
        banReason,
        durationHours == 0 and "PERMANENT" or os.date('%Y-%m-%d %H:%M:%S', expireTime)
    )
    DropPlayer(tostring(targetId), banMsg)

    return { success = true }
end)

---Callback 7: Kick Player
lib.callback.register('souh4il_dev:server:kickPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'kick_player')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local targetId = tonumber(data.targetId)
    local kickReason = data.reason or "Kicked by staff"

    if not targetId or not DoesPlayerExist(tostring(targetId)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    if not Permissions.CanTargetPlayer(source, targetId) then
        return { success = false, error = "CANNOT_TARGET_EQUAL_OR_HIGHER_RANK" }
    end

    local targetName = GetPlayerName(tostring(targetId)) or "Unknown"
    local kickerName = GetPlayerName(tostring(source)) or "Staff"

    Logger.Write("KICK_PLAYER", source, targetId, { targetName = targetName, reason = kickReason }, "SUCCESS")
    DropPlayer(tostring(targetId), ("Kicked by %s. Reason: %s"):format(kickerName, kickReason))

    return { success = true }
end)

---Callback 8: Teleport Action (Goto / Bring / Preset on Target)
lib.callback.register('souh4il_dev:server:teleportAction', function(source, action, targetId, extraCoords)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    local srcPed = GetPlayerPed(source)
    local tgtPed = GetPlayerPed(target)

    if action == 'goto' then
        local coords = GetEntityCoords(tgtPed)
        local srcVeh = GetVehiclePedIsIn(srcPed, false)
        local entityToMove = (srcVeh ~= 0 and GetPedInVehicleSeat(srcVeh, -1) == srcPed) and srcVeh or srcPed
        SetEntityCoords(entityToMove, coords.x + 1.0, coords.y, coords.z + 0.5, false, false, false, false)
        Logger.Write("TELEPORT_GOTO", source, target, { coords = coords }, "SUCCESS")
        return { success = true, action = 'goto', coords = coords }
    elseif action == 'bring' then
        local coords = GetEntityCoords(srcPed)
        local tgtVeh = GetVehiclePedIsIn(tgtPed, false)
        local entityToMove = (tgtVeh ~= 0 and GetPedInVehicleSeat(tgtVeh, -1) == tgtPed) and tgtVeh or tgtPed
        SetEntityCoords(entityToMove, coords.x + 1.5, coords.y, coords.z + 0.5, false, false, false, false)
        Logger.Write("TELEPORT_BRING", source, target, { coords = coords }, "SUCCESS")
        return { success = true, action = 'bring', coords = coords }
    elseif action == 'preset' and type(extraCoords) == 'table' and extraCoords.x then
        local tgtVeh = GetVehiclePedIsIn(tgtPed, false)
        local entityToMove = (tgtVeh ~= 0 and GetPedInVehicleSeat(tgtVeh, -1) == tgtPed) and tgtVeh or tgtPed
        SetEntityCoords(entityToMove, tonumber(extraCoords.x), tonumber(extraCoords.y), tonumber(extraCoords.z), false, false, false, false)
        if extraCoords.w then
            SetEntityHeading(entityToMove, tonumber(extraCoords.w))
        end
        Logger.Write("TELEPORT_PRESET_TARGET", source, target, { coords = extraCoords }, "SUCCESS")
        return { success = true, action = 'preset' }
    end

    return { success = false, error = "UNKNOWN_TELEPORT_ACTION" }
end)

---Callback 8B: Get Target Player Coords for Long-Range Spectate
lib.callback.register('souh4il_dev:server:getSpectateCoords', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    local tgtPed = GetPlayerPed(target)
    if not tgtPed or tgtPed == 0 or not DoesEntityExist(tgtPed) then
        return { success = false, error = "PED_NOT_FOUND" }
    end

    local coords = GetEntityCoords(tgtPed)
    Logger.Write("SPECTATE_PLAYER", source, target, { coords = coords }, "SUCCESS")
    return {
        success = true,
        targetId = target,
        name = GetPlayerName(tostring(target)) or ("Player #" .. target),
        coords = { x = coords.x, y = coords.y, z = coords.z }
    }
end)

---Callback 9: Freeze Player (Per-Target State Toggle)
lib.callback.register('souh4il_dev:server:freezePlayer', function(source, targetId, state)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    local currentFrozen = Player(target).state.sdev_frozen == true
    local newState = (state ~= nil) and (state == true) or (not currentFrozen)
    Player(target).state:set('sdev_frozen', newState, true)

    local ped = GetPlayerPed(target)
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        FreezeEntityPosition(ped, newState)
        local veh = GetVehiclePedIsIn(ped, false)
        if veh and veh ~= 0 and DoesEntityExist(veh) then
            FreezeEntityPosition(veh, newState)
        end
    end

    TriggerClientEvent('souh4il_dev:client:receiveFreeze', target, newState)
    Logger.Write("FREEZE_PLAYER", source, target, { state = newState }, "SUCCESS")
    return { success = true, frozen = newState, targetName = GetPlayerName(tostring(target)) }
end)

---Callback 10: Give Item (Integrated with ox_inventory)
lib.callback.register('souh4il_dev:server:giveItem', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'give_item')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local itemName = tostring(data.item or ""):lower():gsub("%s+", "")
    local count = math.max(1, math.min(1000, tonumber(data.count) or 1))
    local targetId = tonumber(data.targetId) or source

    if #itemName == 0 then
        return { success = false, error = "INVALID_ITEM_NAME" }
    end

    local success, err = exports.ox_inventory:AddItem(targetId, itemName, count)
    if success then
        Logger.Write("GIVE_ITEM", source, targetId, { item = itemName, count = count }, "SUCCESS")
        return { success = true }
    else
        return { success = false, error = tostring(err or "Failed to add item to inventory") }
    end
end)

---Callback 11: Give Money
lib.callback.register('souh4il_dev:server:giveMoney', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'give_money')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local moneyType = data.moneyType == 'bank' and 'bank' or 'cash'
    local amount = math.max(1, tonumber(data.amount) or 10000)
    local targetId = tonumber(data.targetId) or source

    local player = exports.qbx_core:GetPlayer(targetId)
    if player then
        player.Functions.AddMoney(moneyType, amount, "souh4il_dev_admin")
        Logger.Write("GIVE_MONEY", source, targetId, { type = moneyType, amount = amount }, "SUCCESS")
        return { success = true }
    end
    return { success = false, error = "PLAYER_NOT_FOUND" }
end)

---Callback 12: Give Vehicle Keys (qbx_vehiclekeys Integration)
lib.callback.register('souh4il_dev:server:giveVehicleKeys', function(source, netId)
    local allowed, reason = Security.CheckRateLimit(source, 'vehicle_action')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(source, entity)
        end)
        Logger.Write("SPAWN_VEHICLE", source, nil, { netId = netId }, "SUCCESS")
        return { success = true }
    end
    return { success = false, error = "VEHICLE_ENTITY_NOT_FOUND" }
end)

---Callback 13: Set Player Job & Grade (Qbox Integrated)
lib.callback.register('souh4il_dev:server:setPlayerJob', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'set_job')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local targetId = tonumber(data.targetId)
    local jobName = tostring(data.job or "unemployed"):lower():gsub("%s+", "")
    local gradeLevel = tonumber(data.grade) or 0

    local targetPlayer = exports.qbx_core:GetPlayer(targetId)
    if not targetPlayer then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    local success, err = targetPlayer.Functions.SetJob(jobName, gradeLevel)
    if success ~= false then
        Logger.Write("SET_PLAYER_JOB", source, targetId, { job = jobName, grade = gradeLevel }, "SUCCESS")
        return { success = true }
    else
        return { success = false, error = tostring(err or "Failed to set job") }
    end
end)

---Callback 14: Clear Player Inventory (ox_inventory Integrated)
lib.callback.register('souh4il_dev:server:clearPlayerInventory', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'clear_inventory')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    exports.ox_inventory:ClearInventory(target)
    Logger.Write("CLEAR_INVENTORY", source, target, {}, "SUCCESS")
    return { success = true }
end)

---Callback 15: Broadcast Server Announcement
lib.callback.register('souh4il_dev:server:broadcastAnnouncement', function(source, message)
    local allowed, reason = Security.CheckRateLimit(source, 'broadcast')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local cleanMsg = Security.SanitizeString(message, 300)
    if #cleanMsg == 0 then return { success = false, error = "EMPTY_MESSAGE" } end

    TriggerClientEvent('ox_lib:notify', -1, {
        title = "SERVER ANNOUNCEMENT",
        description = cleanMsg,
        type = 'inform',
        duration = 10000
    })

    Logger.Write("BROADCAST_ANNOUNCEMENT", source, nil, { message = cleanMsg }, "SUCCESS")
    return { success = true }
end)

---Callback 16: Set World Time
lib.callback.register('souh4il_dev:server:setTime', function(source, hour, minute)
    local allowed, reason = Security.CheckRateLimit(source, 'set_time')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local h = math.max(0, math.min(23, tonumber(hour) or 12))
    local m = math.max(0, math.min(59, tonumber(minute) or 0))

    GlobalState.time = { hour = h, minute = m }
    GlobalState.currentTime = { hour = h, minute = m }
    pcall(function()
        if exports['Renewed-Weathersync'] and exports['Renewed-Weathersync'].setTime then
            exports['Renewed-Weathersync']:setTime(h, m)
        end
    end)
    TriggerClientEvent('souh4il_dev:client:syncTime', -1, h, m)
    Logger.Write("SET_WORLD_TIME", source, nil, { hour = h, minute = m }, "SUCCESS")
    return { success = true }
end)

---Callback 17: Set City Blackout
lib.callback.register('souh4il_dev:server:setBlackout', function(source, state)
    local allowed, reason = Security.CheckRateLimit(source, 'weather_control')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local isBlackout = (state == true)
    GlobalState.blackout = isBlackout
    GlobalState.blackOut = isBlackout
    pcall(function()
        if exports['Renewed-Weathersync'] and exports['Renewed-Weathersync'].setBlackout then
            exports['Renewed-Weathersync']:setBlackout(isBlackout)
        end
    end)
    TriggerClientEvent('souh4il_dev:client:syncBlackout', -1, isBlackout)
    Logger.Write("SET_CITY_BLACKOUT", source, nil, { blackout = isBlackout }, "SUCCESS")
    return { success = true }
end)

---Callback 18: Set Vehicle Custom Plate
lib.callback.register('souh4il_dev:server:setVehiclePlate', function(source, netId, newPlate)
    local allowed, reason = Security.CheckRateLimit(source, 'set_plate')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plateClean = tostring(newPlate or ""):upper():sub(1, 8)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetVehicleNumberPlateText(entity, plateClean)
        pcall(function()
            exports.qbx_vehiclekeys:GiveKeys(source, entity)
        end)
        Logger.Write("SET_VEHICLE_PLATE", source, nil, { netId = netId, plate = plateClean }, "SUCCESS")
        return { success = true, plate = plateClean }
    end
    return { success = false, error = "VEHICLE_NOT_FOUND" }
end)

---Callback 19: Get All Registered Items (ox_inventory Dynamic Catalog)
local cachedGameItems = nil
lib.callback.register('souh4il_dev:server:getAllGameItems', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_catalog')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if not cachedGameItems then
        local rawItems = exports.ox_inventory:Items() or {}
        local list = {}
        for name, data in pairs(rawItems) do
            local cleanName = tostring(name):lower()
            local cat = 'tool'
            if cleanName:find('weapon_') then
                cat = 'weapon'
            elseif cleanName:find('ammo') then
                cat = 'ammo'
            elseif cleanName:find('burger') or cleanName:find('water') or cleanName:find('sandwich') or cleanName:find('drink') or cleanName:find('food') or cleanName:find('coffee') or cleanName:find('cola') or cleanName:find('sprunk') or cleanName:find('tea') or cleanName:find('taco') or cleanName:find('donut') or cleanName:find('hotdog') then
                cat = 'food'
            elseif cleanName:find('bandage') or cleanName:find('medikit') or cleanName:find('firstaid') or cleanName:find('armor') or cleanName:find('pill') or cleanName:find('painkiller') then
                cat = 'medical'
            end

            table.insert(list, {
                name = cleanName,
                label = data.label or cleanName,
                category = cat,
                description = data.description or ''
            })
        end
        table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
        cachedGameItems = list
    end

    return { success = true, items = cachedGameItems }
end)

---Callback 20: Get All Registered Vehicles (Qbox Dynamic Catalog)
local cachedGameVehicles = nil
lib.callback.register('souh4il_dev:server:getAllGameVehicles', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_catalog')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if not cachedGameVehicles then
        local rawVehs = exports.qbx_core:GetVehiclesByName() or {}
        local list = {}
        for model, v in pairs(rawVehs) do
            table.insert(list, {
                model = tostring(model):lower(),
                name = v.name or model,
                brand = v.brand or '',
                category = v.category or 'sports',
                type = v.type or 'automobile'
            })
        end

        -- Backup file parser to ensure all 970+ vehicles are loaded even if export returned partial
        if #list < 100 then
            local fileRaw = LoadResourceFile('qbx_core', 'shared/vehicles.lua')
            if fileRaw then
                local seen = {}
                for _, existing in ipairs(list) do seen[existing.model] = true end
                for model, body in fileRaw:gmatch("(%w+)%s*=%s*{(.-)%s*hash%s*=") do
                    local m = model:lower()
                    if not seen[m] and m ~= 'return' and m ~= 'vehicle' then
                        seen[m] = true
                        local name = body:match("name%s*=%s*['\"]([^'\"]+)['\"]") or m
                        local brand = body:match("brand%s*=%s*['\"]([^'\"]+)['\"]") or ''
                        local cat = body:match("category%s*=%s*['\"]([^'\"]+)['\"]") or 'sports'
                        table.insert(list, {
                            model = m,
                            name = name,
                            brand = brand,
                            category = cat,
                            type = 'automobile'
                        })
                    end
                end
            end
        end

        table.sort(list, function(a, b) return tostring(a.name) < tostring(b.name) end)
        cachedGameVehicles = list
    end

    return { success = true, vehicles = cachedGameVehicles }
end)

---Callback: Get All Registered Characters / Peds (illenium-appearance Dynamic Catalog)
local cachedGameCharacters = nil
lib.callback.register('souh4il_dev:server:getAllGameCharacters', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_catalog')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if not cachedGameCharacters then
        local list = {}
        local raw = LoadResourceFile('illenium-appearance', 'shared/peds.lua')
        if raw then
            local seen = { ['admin'] = true, ['group.admin'] = true, ['souh4il'] = true }
            for pedModel in raw:gmatch('"([%w_%-]+)"') do
                local m = pedModel:lower()
                if not seen[m] and not m:find('config') and not m:find('ped') and not m:find('group') and #m > 2 then
                    seen[m] = true
                    local cat = 'story'
                    if m:sub(1, 4) == 'a_c_' then
                        cat = 'animals'
                    elseif m:sub(1, 2) == 'g_' then
                        cat = 'gangs'
                    elseif m:sub(1, 2) == 's_' or m:find('cop') or m:find('sheriff') or m:find('paramedic') or m:find('fire') or m:find('fib') or m:find('securo') then
                        cat = 'emergency'
                    elseif m:sub(1, 3) == 'mp_' then
                        cat = 'multiplayer'
                    elseif m:sub(1, 4) == 'a_f_' or m:sub(1, 4) == 'u_f_' then
                        cat = 'female'
                    elseif m:sub(1, 4) == 'a_m_' or m:sub(1, 4) == 'u_m_' then
                        cat = 'male'
                    elseif m:sub(1, 3) == 'ig_' or m:sub(1, 3) == 'cs_' or m:sub(1, 4) == 'csb_' or m:find('player_') then
                        cat = 'story'
                    end

                    local cleanLabel = m:gsub('^a_c_', ''):gsub('^a_f_[moy]_', ''):gsub('^a_m_[moy]_', ''):gsub('^s_[fm]_[my]_', ''):gsub('^g_[fm]_[my]_', ''):gsub('^ig_', ''):gsub('^cs_', ''):gsub('^csb_', ''):gsub('^u_[fm]_[my]_', ''):gsub('_', ' ')
                    cleanLabel = cleanLabel:gsub("(%a)([%w_']*)", function(first, rest) return first:upper() .. rest:lower() end)

                    table.insert(list, {
                        model = m,
                        label = cleanLabel,
                        category = cat
                    })
                end
            end
        end
        table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
        cachedGameCharacters = list
    end

    return { success = true, characters = cachedGameCharacters }
end)

---Callback 21: Get All Registered Jobs (Qbox Dynamic Jobs Catalog)
local cachedGameJobs = nil
lib.callback.register('souh4il_dev:server:getAllGameJobs', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_catalog')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if not cachedGameJobs then
        local rawJobs = exports.qbx_core:GetJobs() or {}
        local rawGangs = exports.qbx_core:GetGangs() or {}
        local list = {}

        for jobName, jobData in pairs(rawJobs) do
            local gradesList = {}
            if jobData.grades then
                for gradeIdx, gradeData in pairs(jobData.grades) do
                    table.insert(gradesList, {
                        grade = tonumber(gradeIdx) or 0,
                        name = gradeData.name or ("Grade " .. gradeIdx),
                        payment = gradeData.payment or 0,
                        isBoss = gradeData.isboss == true
                    })
                end
                table.sort(gradesList, function(a, b) return a.grade < b.grade end)
            end

            local cat = 'public'
            local jn = tostring(jobName):lower()
            if jn:find('police') or jn:find('sheriff') or jn:find('ambulance') or jn:find('ems') or jn:find('doctor') or jn:find('lawyer') or jn:find('judge') then
                cat = 'emergency'
            elseif jn:find('mechanic') or jn:find('cardealer') or jn:find('realestate') or jn:find('taxi') or jn:find('bennys') or jn:find('shop') then
                cat = 'business'
            end

            table.insert(list, {
                name = jobName,
                label = jobData.label or jobName,
                category = cat,
                type = jobData.type or 'default',
                grades = gradesList
            })
        end

        for gangName, gangData in pairs(rawGangs) do
            local gradesList = {}
            if gangData.grades then
                for gradeIdx, gradeData in pairs(gangData.grades) do
                    table.insert(gradesList, {
                        grade = tonumber(gradeIdx) or 0,
                        name = gradeData.name or ("Grade " .. gradeIdx),
                        payment = 0,
                        isBoss = gradeData.isboss == true
                    })
                end
                table.sort(gradesList, function(a, b) return a.grade < b.grade end)
            end

            table.insert(list, {
                name = gangName,
                label = gangData.label or gangName,
                category = 'gang',
                type = 'gang',
                grades = gradesList
            })
        end

        table.sort(list, function(a, b) return tostring(a.label) < tostring(b.label) end)
        cachedGameJobs = list
    end

    return { success = true, jobs = cachedGameJobs }
end)

---Callback 22: Set Caller Job Direct
lib.callback.register('souh4il_dev:server:setMyJob', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'set_job')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local jobName = tostring(data.job or 'unemployed')
    local grade = tonumber(data.grade) or 0
    local player = exports.qbx_core:GetPlayer(source)

    if player then
        player.Functions.SetJob(jobName, grade)
        Logger.Write("SET_MY_JOB", source, source, { job = jobName, grade = grade }, "SUCCESS")
        return { success = true, job = jobName, grade = grade }
    end

    return { success = false, error = "PLAYER_NOT_FOUND" }
end)

---Callback 23: Equip Owner Arsenal Loadout (Self or Target Player)
lib.callback.register('souh4il_dev:server:giveArsenalLoadout', function(source, payload)
    local allowed, reason = Security.CheckRateLimit(source, 'arsenal')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local loadoutKey = type(payload) == 'table' and payload.loadout or payload
    local targetId = (type(payload) == 'table' and tonumber(payload.targetId)) or source
    if not DoesPlayerExist(tostring(targetId)) then targetId = source end

    local loadouts = {
        swat = {
            { item = 'weapon_carbinerifle', count = 1 },
            { item = 'weapon_combatpistol', count = 1 },
            { item = 'weapon_pumpshotgun', count = 1 },
            { item = 'ammo-rifle', count = 250 },
            { item = 'ammo-9', count = 150 },
            { item = 'ammo-shotgun', count = 50 },
            { item = 'armor', count = 2 },
            { item = 'medikit', count = 3 },
            { item = 'handcuffs', count = 2 },
        },
        juggernaut = {
            { item = 'weapon_specialcarbine', count = 1 },
            { item = 'weapon_heavysniper', count = 1 },
            { item = 'weapon_combatpdw', count = 1 },
            { item = 'ammo-rifle', count = 500 },
            { item = 'ammo-sniper', count = 100 },
            { item = 'armor', count = 5 },
            { item = 'bandage', count = 10 },
        },
        assassin = {
            { item = 'weapon_appistol', count = 1 },
            { item = 'weapon_knife', count = 1 },
            { item = 'weapon_katana', count = 1 },
            { item = 'ammo-9', count = 250 },
            { item = 'armor', count = 2 },
            { item = 'lockpick', count = 5 },
            { item = 'advancedlockpick', count = 2 },
        },
        god_arsenal = {
            { item = 'weapon_carbinerifle', count = 1 },
            { item = 'weapon_specialcarbine', count = 1 },
            { item = 'weapon_assaultrifle', count = 1 },
            { item = 'weapon_heavysniper', count = 1 },
            { item = 'weapon_combatpistol', count = 1 },
            { item = 'ammo-rifle', count = 999 },
            { item = 'ammo-9', count = 999 },
            { item = 'ammo-sniper', count = 250 },
            { item = 'armor', count = 10 },
            { item = 'medikit', count = 10 },
            { item = 'repairkit', count = 5 },
        }
    }

    local items = loadouts[loadoutKey] or loadouts.god_arsenal
    for _, it in ipairs(items) do
        exports.ox_inventory:AddItem(targetId, it.item, it.count)
    end

    Logger.Write("EQUIP_OWNER_ARSENAL", source, targetId, { loadout = loadoutKey, itemCount = #items }, "SUCCESS")
    return { success = true, loadout = loadoutKey, targetId = targetId }
end)

-- =========================================================================
-- WORLD NPC, TRAFFIC & SMART POLICE NPC CONTROLLER
-- =========================================================================
local WorldNpcConfig = {
    policeNpcEnabled = false,       -- Master state: whether NPC Police are active
    autoMode = true,                -- Auto-disable NPC police when real cops >= minCopsThreshold
    minCopsThreshold = 1,           -- Real cops on duty needed to disable NPC police
    wantedStarsEnabled = false,     -- GTA V Wanted stars
    emsNpcEnabled = false,          -- Ambulance & Fire Dept AI dispatch
    pedDensity = 1.0,               -- Pedestrians / Civilians multiplier (0.0 to 1.5)
    trafficDensity = 1.0,           -- Driving vehicles multiplier (0.0 to 1.5)
    parkedDensity = 1.0,            -- Parked vehicles multiplier (0.0 to 1.5)
    realCopsOnDuty = 0,             -- Live counter of real on-duty police players
}

-- Load persisted NPC config if saved previously
CreateThread(function()
    Wait(500)
    local savedRaw = GetResourceKvpString('souh4il_npc_config')
    if savedRaw and #savedRaw > 0 then
        local ok, decoded = pcall(json.decode, savedRaw)
        if ok and type(decoded) == 'table' then
            if decoded.policeNpcEnabled ~= nil then WorldNpcConfig.policeNpcEnabled = decoded.policeNpcEnabled end
            if decoded.autoMode ~= nil then WorldNpcConfig.autoMode = decoded.autoMode end
            if decoded.minCopsThreshold ~= nil then WorldNpcConfig.minCopsThreshold = tonumber(decoded.minCopsThreshold) or 1 end
            if decoded.wantedStarsEnabled ~= nil then WorldNpcConfig.wantedStarsEnabled = decoded.wantedStarsEnabled end
            if decoded.emsNpcEnabled ~= nil then WorldNpcConfig.emsNpcEnabled = decoded.emsNpcEnabled end
            if decoded.pedDensity ~= nil then WorldNpcConfig.pedDensity = tonumber(decoded.pedDensity) or 1.0 end
            if decoded.trafficDensity ~= nil then WorldNpcConfig.trafficDensity = tonumber(decoded.trafficDensity) or 1.0 end
            if decoded.parkedDensity ~= nil then WorldNpcConfig.parkedDensity = tonumber(decoded.parkedDensity) or 1.0 end
        end
    end
    GlobalState.souh4ilNpcConfig = WorldNpcConfig
    GlobalState.trafficDensity = WorldNpcConfig.trafficDensity
end)

local function CountRealCopsOnDuty()
    local count = 0
    local ok, players = pcall(function() return exports.qbx_core:GetQBPlayers() end)
    if ok and players then
        for _, p in pairs(players) do
            if p and p.PlayerData and p.PlayerData.job then
                local jName = tostring(p.PlayerData.job.name or ''):lower()
                local onDuty = p.PlayerData.job.onduty
                if onDuty and (jName == 'police' or jName == 'sheriff' or jName == 'lspd' or jName == 'bcso' or jName == 'sasp' or jName == 'trooper') then
                    count = count + 1
                end
            end
        end
    else
        for _, srcStr in ipairs(GetPlayers()) do
            local s = tonumber(srcStr)
            if s then
                local okP, player = pcall(function() return exports.qbx_core:GetPlayer(s) end)
                if okP and player and player.PlayerData and player.PlayerData.job then
                    local jName = tostring(player.PlayerData.job.name or ''):lower()
                    if player.PlayerData.job.onduty and (jName == 'police' or jName == 'sheriff' or jName == 'lspd' or jName == 'bcso' or jName == 'sasp') then
                        count = count + 1
                    end
                end
            end
        end
    end
    return count
end

local function SaveAndBroadcastNpcConfig(cleanCopsIfDisabled)
    pcall(function()
        SetResourceKvp('souh4il_npc_config', json.encode(WorldNpcConfig))
    end)
    GlobalState.souh4ilNpcConfig = WorldNpcConfig
    GlobalState.trafficDensity = WorldNpcConfig.trafficDensity
    TriggerClientEvent('souh4il_dev:client:syncNpcConfig', -1, WorldNpcConfig)
    if cleanCopsIfDisabled and not WorldNpcConfig.policeNpcEnabled then
        TriggerClientEvent('souh4il_dev:client:cleanNpcCops', -1)
    end
end

-- Background Monitor for Smart RP Police Threshold
CreateThread(function()
    while true do
        Wait(8000)
        local cops = CountRealCopsOnDuty()
        local changed = (WorldNpcConfig.realCopsOnDuty ~= cops)
        WorldNpcConfig.realCopsOnDuty = cops

        if WorldNpcConfig.autoMode then
            local shouldEnableNpcPolice = (cops < WorldNpcConfig.minCopsThreshold)
            if WorldNpcConfig.policeNpcEnabled ~= shouldEnableNpcPolice then
                WorldNpcConfig.policeNpcEnabled = shouldEnableNpcPolice
                SaveAndBroadcastNpcConfig(true)
                changed = false
            end
        end

        if changed then
            GlobalState.souh4ilNpcConfig = WorldNpcConfig
            TriggerClientEvent('souh4il_dev:client:syncNpcConfig', -1, WorldNpcConfig)
        end
    end
end)

---Callback: Get Full World NPC & Police Config
lib.callback.register('souh4il_dev:server:getNpcConfig', function(source)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper
    WorldNpcConfig.realCopsOnDuty = CountRealCopsOnDuty()
    return { success = true, config = WorldNpcConfig }
end)

---Callback: Update World NPC & Police Config
lib.callback.register('souh4il_dev:server:updateNpcConfig', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if type(data) ~= 'table' then return { success = false, error = "INVALID_DATA" } end

    WorldNpcConfig.realCopsOnDuty = CountRealCopsOnDuty()

    if data.minCopsThreshold ~= nil then
        WorldNpcConfig.minCopsThreshold = math.max(1, math.min(50, math.floor(tonumber(data.minCopsThreshold) or 1)))
    end

    if data.autoMode ~= nil then
        WorldNpcConfig.autoMode = (data.autoMode == true)
    end

    if data.policeNpcEnabled ~= nil then
        WorldNpcConfig.policeNpcEnabled = (data.policeNpcEnabled == true)
        -- If admin explicitly toggles manual ON/OFF, disable autoMode unless autoMode was explicitly sent in same payload
        if data.autoMode == nil then
            WorldNpcConfig.autoMode = false
        end
    end

    if WorldNpcConfig.autoMode then
        WorldNpcConfig.policeNpcEnabled = (WorldNpcConfig.realCopsOnDuty < WorldNpcConfig.minCopsThreshold)
    end

    if data.wantedStarsEnabled ~= nil then
        WorldNpcConfig.wantedStarsEnabled = (data.wantedStarsEnabled == true)
    end

    if data.emsNpcEnabled ~= nil then
        WorldNpcConfig.emsNpcEnabled = (data.emsNpcEnabled == true)
    end

    if data.pedDensity ~= nil then
        WorldNpcConfig.pedDensity = math.max(0.0, math.min(2.0, tonumber(data.pedDensity) or 1.0))
    end

    if data.trafficDensity ~= nil then
        WorldNpcConfig.trafficDensity = math.max(0.0, math.min(2.0, tonumber(data.trafficDensity) or 1.0))
    end

    if data.parkedDensity ~= nil then
        WorldNpcConfig.parkedDensity = math.max(0.0, math.min(2.0, tonumber(data.parkedDensity) or 1.0))
    end

    SaveAndBroadcastNpcConfig(true)
    Logger.Write("UPDATE_NPC_CONFIG", source, nil, WorldNpcConfig, "SUCCESS")

    return { success = true, config = WorldNpcConfig }
end)

---Callback: Clean / Purge All Active NPC Cops & Police Vehicles Now
lib.callback.register('souh4il_dev:server:cleanNpcCopsNow', function(source)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    TriggerClientEvent('souh4il_dev:client:cleanNpcCops', -1)
    Logger.Write("CLEAN_NPC_COPS", source, nil, {}, "SUCCESS")
    return { success = true }
end)

---Callback 24: World Traffic & NPC Density Control (Quick Preset Compatibility)
lib.callback.register('souh4il_dev:server:setTrafficDensity', function(source, densityVal)
    local allowed, reason = Security.CheckRateLimit(source, 'set_traffic')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local d = math.max(0.0, math.min(2.0, tonumber(densityVal) or 1.0))
    WorldNpcConfig.pedDensity = d
    WorldNpcConfig.trafficDensity = d
    WorldNpcConfig.parkedDensity = d
    SaveAndBroadcastNpcConfig(false)
    TriggerClientEvent('souh4il_dev:client:syncDensity', -1, d)
    Logger.Write("SET_WORLD_DENSITY", source, nil, { density = d }, "SUCCESS")
    return { success = true, density = d, config = WorldNpcConfig }
end)

---Command: Reload Bank, Housing & Police Services (Owner Only)
lib.addCommand('sdev_services', {
    help = 'Reload Bank, Housing & Police services (Owner Only)'
}, function(source)
    if source ~= 0 and not Permissions.IsOwner(source) then
        exports.qbx_core:Notify(source, "Unauthorized: Owner Only", "error")
        return
    end

    ExecuteCommand('restart bablo-banking')
    ExecuteCommand('restart qbx_properties')
    ExecuteCommand('restart qbx_police')
    ExecuteCommand('ensure cu_multijob')
    ExecuteCommand('restart cu_multijob')
    ExecuteCommand('restart souh4il_dev')

    if source ~= 0 then
        exports.qbx_core:Notify(source, "All Services & SOUH4IL-DEV reloaded successfully!", "success")
        Logger.Write("RELOAD_SERVICES", source, nil, { services = "all" }, "SUCCESS")
    else
        print("^2[SOUH4IL-DEV] All Services & SOUH4IL-DEV reloaded successfully!^0")
    end
end)

lib.addCommand('sdev_reload', {
    help = 'Reload SOUH4IL-DEV Panel (Owner Only)'
}, function(source)
    if source ~= 0 and not Permissions.IsOwner(source) then
        exports.qbx_core:Notify(source, "Unauthorized: Owner Only", "error")
        return
    end
    ExecuteCommand('restart souh4il_dev')
end)

---Callback: Heal & Revive Player
lib.callback.register('souh4il_dev:server:healPlayer', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(targetId) or source
    if not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    TriggerClientEvent('qbx_medical:client:playerRevived', tId)
    TriggerClientEvent('hospital:client:Revive', tId)
    TriggerClientEvent('souh4il_dev:client:receiveHeal', tId)

    Logger.Write("HEAL_PLAYER", source, tId, { target = tId }, "SUCCESS")
    return { success = true }
end)

---Callback: Revive All Players
lib.callback.register('souh4il_dev:server:reviveAll', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local players = GetPlayers()
    for _, srcStr in ipairs(players) do
        local pid = tonumber(srcStr)
        if pid then
            TriggerClientEvent('qbx_medical:client:playerRevived', pid)
            TriggerClientEvent('hospital:client:Revive', pid)
            TriggerClientEvent('souh4il_dev:client:receiveHeal', pid)
        end
    end

    Logger.Write("REVIVE_ALL", source, nil, { count = #players }, "SUCCESS")
    return { success = true, count = #players }
end)

---Callback: Revive Players in Radius
lib.callback.register('souh4il_dev:server:reviveInRadius', function(source, radius)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local rad = tonumber(radius) or 50.0
    local myPed = GetPlayerPed(tostring(source))
    local myCoords = GetEntityCoords(myPed)
    local revivedCount = 0

    for _, srcStr in ipairs(GetPlayers()) do
        local pid = tonumber(srcStr)
        if pid then
            local tPed = GetPlayerPed(srcStr)
            local tCoords = GetEntityCoords(tPed)
            if #(myCoords - tCoords) <= rad then
                TriggerClientEvent('qbx_medical:client:playerRevived', pid)
                TriggerClientEvent('hospital:client:Revive', pid)
                TriggerClientEvent('souh4il_dev:client:receiveHeal', pid)
                revivedCount = revivedCount + 1
            end
        end
    end

    Logger.Write("REVIVE_RADIUS", source, nil, { radius = rad, count = revivedCount }, "SUCCESS")
    return { success = true, count = revivedCount }
end)

---Callback: Set Gang
lib.callback.register('souh4il_dev:server:setPlayerGang', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'set_gang')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId) or source
    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    player.Functions.SetGang(data.gang or "none", tonumber(data.grade) or 0)
    Logger.Write("SET_GANG", source, tId, { gang = data.gang, grade = data.grade }, "SUCCESS")
    return { success = true }
end)

---Callback: Give / Remove Permission (ACE Principal)
lib.callback.register('souh4il_dev:server:managePermission', function(source, data)
    if not Permissions.IsOwner(source) then
        return { success = false, error = "OWNER_ONLY" }
    end

    local tId = tonumber(data.targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local lic = Identifiers.GetLicense(tId)
    if not lic then return { success = false, error = "NO_LICENSE" } end

    local role = data.role or 'admin'
    local isAdd = data.action == 'add'

    if isAdd then
        ExecuteCommand(('add_principal identifier.license:%s qbx.%s'):format(lic, role))
        ExecuteCommand(('add_principal identifier.license:%s souh4il_dev.%s'):format(lic, role))
    else
        ExecuteCommand(('remove_principal identifier.license:%s qbx.%s'):format(lic, role))
        ExecuteCommand(('remove_principal identifier.license:%s souh4il_dev.%s'):format(lic, role))
    end

    Logger.Write(isAdd and "GRANT_PERMISSION" or "REVOKE_PERMISSION", source, tId, { license = lic, role = role }, "SUCCESS")
    return { success = true }
end)

---Callback: Warn Player
lib.callback.register('souh4il_dev:server:warnPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    local msg = data.reason or "You have received an official staff warning."
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    TriggerClientEvent('souh4il_dev:client:receiveWarn', tId, msg)
    exports.qbx_core:Notify(tId, "⚠️ OFFICIAL WARNING: " .. msg, "error", 10000)
    Logger.Write("WARN_PLAYER", source, tId, { reason = msg }, "SUCCESS")
    return { success = true }
end)

---Callback: Force Logout Player
lib.callback.register('souh4il_dev:server:forceLogout', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    DropPlayer(tostring(tId), "Forced logout by Chicago RP Administration.")
    Logger.Write("FORCE_LOGOUT", source, tId, {}, "SUCCESS")
    return { success = true }
end)

---Callback: Message Player
lib.callback.register('souh4il_dev:server:messagePlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end

    local tId = tonumber(data.targetId)
    local msg = data.message or ""
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    exports.qbx_core:Notify(tId, "[STAFF MESSAGE]: " .. msg, "inform", 10000)
    TriggerClientEvent('chat:addMessage', tId, {
        color = {255, 50, 50},
        multiline = true,
        args = {"[ADMIN PM]", msg}
    })
    Logger.Write("MESSAGE_PLAYER", source, tId, { message = msg }, "SUCCESS")
    return { success = true }
end)

---Callback: Troll Action on Target Player
lib.callback.register('souh4il_dev:server:trollPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    local trollType = data.type
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    TriggerClientEvent('souh4il_dev:client:receiveTroll', tId, trollType)
    Logger.Write("TROLL_ACTION", source, tId, { type = trollType }, "SUCCESS")
    return { success = true }
end)

---Callback: Open Target Inventory / Storage
lib.callback.register('souh4il_dev:server:openInventory', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local invType = data.type
    local target = data.target

    if invType == 'player' then
        exports.ox_inventory:forceOpenInventory(source, 'player', tonumber(target))
    elseif invType == 'trunk' then
        exports.ox_inventory:forceOpenInventory(source, 'trunk', 'trunk' .. tostring(target))
    elseif invType == 'glovebox' then
        exports.ox_inventory:forceOpenInventory(source, 'glovebox', 'glove' .. tostring(target))
    elseif invType == 'stash' then
        exports.ox_inventory:forceOpenInventory(source, 'stash', tostring(target))
    end

    return { success = true }
end)

---Callback: Create Custom Job or Gang Stash
lib.callback.register('souh4il_dev:server:createStash', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local stashId = data.stashId or ("stash_" .. os.time())
    local label = data.label or "Custom Stash"
    local slots = tonumber(data.slots) or 50
    local maxWeight = tonumber(data.weight) or 1000000

    exports.ox_inventory:RegisterStash(stashId, label, slots, maxWeight)
    exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    Logger.Write("CREATE_STASH", source, nil, { stashId = stashId, label = label, slots = slots, weight = maxWeight }, "SUCCESS")
    return { success = true, stashId = stashId }
end)

---Callback: Get Player Detailed Dossier (Player Info)
lib.callback.register('souh4il_dev:server:getPlayerDetails', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'get_players')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper
    -- Financial data redaction: only show cash/bank to staff with manage_money
    local canSeeMoney = Permissions.IsOwner(source) or (Permissions.GetPermissions(source).manage_money == true)

    local tId = tonumber(targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local player = exports.qbx_core:GetPlayer(tId)
    local pData = player and player.PlayerData or {}

    local cash = (pData.money and pData.money.cash) or 0
    local bank = (pData.money and pData.money.bank) or 0
    local job = (pData.job and pData.job.label) or "Civilian"
    local jobGrade = (pData.job and pData.job.grade and pData.job.grade.name) or "0"
    local gang = (pData.gang and pData.gang.label) or "None"
    local gangGrade = (pData.gang and pData.gang.grade and pData.gang.grade.name) or "0"
    local phone = (pData.charinfo and pData.charinfo.phone) or "N/A"
    local citizenid = pData.citizenid or "N/A"
    local license = Identifiers.GetLicense(tId) or "UNKNOWN"
    local discord = Identifiers.GetDiscord(tId) or "NONE"
    local ping = GetPlayerPing(tostring(tId)) or 0
    local endpoint = GetPlayerEndpoint(tostring(tId)) or "127.0.0.1"

    local vehiclesList = {}
    local propertiesList = {}
    local availableProperties = {}
    local inventoryList = {}

    pcall(function()
        local rawInv = exports.ox_inventory:GetInventoryItems(tId)
        if type(rawInv) == 'table' then
            for _, it in pairs(rawInv) do
                if type(it) == 'table' and it.name and (tonumber(it.count) or 0) > 0 then
                    table.insert(inventoryList, {
                        slot = it.slot,
                        name = tostring(it.name):lower(),
                        label = it.label or it.name,
                        count = tonumber(it.count) or 1,
                        weight = tonumber(it.weight) or 0
                    })
                end
            end
            table.sort(inventoryList, function(a, b) return (tonumber(a.slot) or 0) < (tonumber(b.slot) or 0) end)
        end
    end)

    pcall(function()
        local allProps = MySQL.query.await([[
            SELECT id, property_name, price, interior, owner
            FROM properties
            ORDER BY id ASC
            LIMIT 150
        ]])
        if allProps then availableProperties = allProps end
    end)

    if citizenid and citizenid ~= "N/A" then
        pcall(function()
            local vehRows = MySQL.query.await([[
                SELECT id, vehicle, plate, garage, fuel, engine, body, state
                FROM player_vehicles
                WHERE citizenid = ?
                ORDER BY id DESC
            ]], { citizenid })
            if vehRows then vehiclesList = vehRows end
        end)

        pcall(function()
            local propRows = MySQL.query.await([[
                SELECT id, property_name, price, interior, rent_interval, owner, keyholders
                FROM properties
                WHERE owner = ? OR keyholders LIKE ?
                ORDER BY id DESC
            ]], { citizenid, '%' .. citizenid .. '%' })
            if propRows then
                local filteredProps = {}
                for _, pr in ipairs(propRows) do
                    if type(pr.keyholders) == 'string' then
                        local okDec, dec = pcall(json.decode, pr.keyholders)
                        pr.keyholders = (okDec and type(dec) == 'table') and dec or {}
                    elseif type(pr.keyholders) ~= 'table' then
                        pr.keyholders = {}
                    end
                    local isOwnerProp = (pr.owner == citizenid)
                    local isKeyholderProp = false
                    for _, kh in ipairs(pr.keyholders) do
                        if kh == citizenid then
                            isKeyholderProp = true
                            break
                        end
                    end
                    if isOwnerProp or isKeyholderProp then
                        pr.isKeyholderOnly = (not isOwnerProp and isKeyholderProp)
                        filteredProps[#filteredProps + 1] = pr
                    end
                end
                propertiesList = filteredProps
            end
        end)
    end

    return {
        success = true,
        details = {
            id = tId,
            name = GetPlayerName(tostring(tId)) or "Unknown",
            citizenid = citizenid,
            cash = canSeeMoney and cash or 0,
            bank = canSeeMoney and bank or 0,
            job = job,
            jobGrade = jobGrade,
            gang = gang,
            gangGrade = gangGrade,
            phone = phone,
            license = license,
            discord = discord,
            ping = ping,
            ip = endpoint,
            vehicles = vehiclesList,
            properties = propertiesList,
            availableProperties = availableProperties,
            inventory = inventoryList,
        }
    }
end)

---Callback: Remove Specific Item from Player Inventory
lib.callback.register('souh4il_dev:server:removePlayerItem', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'clear_inventory')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data and data.targetId)
    local item = tostring(data and data.item or ''):lower()
    local count = math.max(1, tonumber(data and data.count) or 1)
    local slot = tonumber(data and data.slot)

    if not tId or not DoesPlayerExist(tostring(tId)) or item == '' then
        return { success = false, error = "INVALID_PARAMS" }
    end

    local ok = exports.ox_inventory:RemoveItem(tId, item, count, nil, slot)
    Logger.Write("REMOVE_ITEM_TARGET", source, tId, { item = item, count = count, slot = slot }, ok and "SUCCESS" or "REJECTED")
    return { success = ok == true }
end)

---Callback: Give / Assign Official Property (House) to Player
lib.callback.register('souh4il_dev:server:givePlayerProperty', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data and data.targetId)
    local propId = tonumber(data and data.propertyId)
    if not tId or not propId then return { success = false, error = "INVALID_PARAMS" } end

    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local citizenid = player.PlayerData.citizenid
    local prop = MySQL.single.await('SELECT id, property_name, stash_options FROM properties WHERE id = ?', { propId })
    if not prop then return { success = false, error = "PROPERTY_NOT_FOUND" } end

    MySQL.update.await('UPDATE properties SET owner = ?, rent_interval = NULL, keyholders = JSON_ARRAY() WHERE id = ?', { citizenid, propId })

    pcall(function()
        local slots, maxWeight = 50, 1000000
        if prop.stash_options then
            local opts = type(prop.stash_options) == 'string' and json.decode(prop.stash_options) or prop.stash_options
            if type(opts) == 'table' then
                slots = tonumber(opts.slots) or 50
                maxWeight = tonumber(opts.maxWeight) or 1000000
            end
        end
        exports.ox_inventory:RegisterStash('qbx_properties_' .. prop.property_name, 'Property: ' .. prop.property_name, slots, maxWeight, citizenid)
    end)

    Logger.Write("GIVE_PROPERTY", source, tId, { propertyId = propId, propertyName = prop.property_name, citizenid = citizenid }, "SUCCESS")
    Outbox.QueueDiscordAlert("GIVE_PROPERTY", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { propertyId = propId, propertyName = prop.property_name, target = tId })

    return { success = true, propertyName = prop.property_name }
end)

---Callback: Mass Server Action (Heal & Feed All, Clean Abandoned Cars)
lib.callback.register('souh4il_dev:server:massServerAction', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local mType = tostring(data and data.massType or '')
    if mType == 'heal_feed_all' then
        local players = GetPlayers()
        for _, srcStr in ipairs(players) do
            local pid = tonumber(srcStr)
            if pid then
                TriggerClientEvent('qbx_medical:client:playerRevived', pid)
                TriggerClientEvent('hospital:client:Revive', pid)
                TriggerClientEvent('souh4il_dev:client:receiveHeal', pid)
                TriggerClientEvent('souh4il_dev:client:receiveVitalsControl', pid, { type = 'feed' })
            end
        end
        Logger.Write("MASS_HEAL_FEED_ALL", source, nil, { count = #players }, "SUCCESS")
        return { success = true, count = #players }
    elseif mType == 'clean_abandoned_cars' then
        local allVehs = GetAllVehicles()
        local deletedCount = 0
        for _, v in ipairs(allVehs) do
            if DoesEntityExist(v) then
                local occupied = false
                for seat = -1, 6 do
                    local pedInSeat = GetPedInVehicleSeat(v, seat)
                    if pedInSeat and pedInSeat ~= 0 then
                        occupied = true
                        break
                    end
                end
                if not occupied then
                    DeleteEntity(v)
                    deletedCount = deletedCount + 1
                end
            end
        end
        Logger.Write("MASS_CLEAN_ABANDONED_CARS", source, nil, { deleted = deletedCount }, "SUCCESS")
        return { success = true, count = deletedCount }
    end

    return { success = false, error = "UNKNOWN_MASS_ACTION" }
end)

---Callback: Save Admin's Current Vehicle to Personal Garage
lib.callback.register('souh4il_dev:server:saveMyCurrentVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local model = tostring(data and data.model or ''):lower()
    local plate = tostring(data and data.plate or ''):upper():gsub('^%s*(.-)%s*$', '%1')
    local mods = data and data.mods or {}
    local garage = tostring(data and data.garage or 'motel')

    if #model == 0 or #plate == 0 then
        return { success = false, error = "NOT_IN_VEHICLE" }
    end

    local citizenid = player.PlayerData.citizenid
    local license = player.PlayerData.license or Identifiers.GetLicense(source) or "UNKNOWN"
    local hash = joaat(model)

    MySQL.insert.await([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, 100, 1000, 1000, 0)
        ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid), license = VALUES(license), vehicle = VALUES(vehicle), hash = VALUES(hash), mods = VALUES(mods)
    ]], { license, citizenid, model, hash, json.encode(mods), plate, garage })

    local ped = GetPlayerPed(source)
    local currVeh = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
    if currVeh ~= 0 and DoesEntityExist(currVeh) then
        Entity(currVeh).state.owner = citizenid
        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, currVeh) end)
    end

    Logger.Write("SAVE_VEHICLE_TO_GARAGE", source, source, { model = model, plate = plate, garage = garage }, "SUCCESS")
    return { success = true, plate = plate, model = model, garage = garage }
end)

---Callback: Wipe Player (Cash, Inventory, or Full)
lib.callback.register('souh4il_dev:server:wipePlayer', function(source, data)
    -- [SOUH4IL-DEV] Granular 'manage_wipes' enforced by CALLBACK_MODULES wrapper
    -- Extra audit: destructive action, log prominently below

    local tId = tonumber(data.targetId)
    local wipeType = data.type
    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    if wipeType == 'cash' then
        player.Functions.SetMoney('cash', 0)
        player.Functions.SetMoney('bank', 0)
    elseif wipeType == 'inventory' then
        exports.ox_inventory:ClearInventory(tId)
    elseif wipeType == 'full' then
        player.Functions.SetMoney('cash', 0)
        player.Functions.SetMoney('bank', 0)
        exports.ox_inventory:ClearInventory(tId)
        player.Functions.SetJob('unemployed', 0)
        player.Functions.SetGang('none', 0)
    end

    Logger.Write("WIPE_PLAYER", source, tId, { type = wipeType }, "SUCCESS")
    return { success = true }
end)

---Callback: Teleport Player to Another Player (Send A to B, or Bring B to A)
lib.callback.register('souh4il_dev:server:teleportPlayerToPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local fromId = tonumber(data.fromId)
    local toId = tonumber(data.toId)
    if not fromId or not DoesPlayerExist(tostring(fromId)) or not toId or not DoesPlayerExist(tostring(toId)) then
        return { success = false, error = "PLAYER_NOT_ONLINE" }
    end

    local pedFrom = GetPlayerPed(tostring(fromId))
    local pedTo = GetPlayerPed(tostring(toId))
    local coords = GetEntityCoords(pedTo)

    SetEntityCoords(pedFrom, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
    TriggerClientEvent('souh4il_dev:client:receiveNotify', fromId, { title = "Téléportation", description = "Vous avez été téléporté par le Staff.", type = "inform" })
    Logger.Write("TELEPORT_PLAYER_TO_PLAYER", source, fromId, { destinationPlayer = toId, coords = coords }, "SUCCESS")
    return { success = true, from = fromId, to = toId }
end)

---Callback: Manage Player Money (Give, Set, Remove)
lib.callback.register('souh4il_dev:server:managePlayerMoney', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'give_money')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local moneyType = data.moneyType == 'bank' and 'bank' or 'cash'
    local amount = tonumber(data.amount) or 0
    local action = data.moneyAction -- 'give', 'remove', 'set'

    if action == 'give' then
        player.Functions.AddMoney(moneyType, math.abs(amount), "souh4il_dev_admin")
    elseif action == 'remove' then
        player.Functions.RemoveMoney(moneyType, math.abs(amount), "souh4il_dev_admin")
    elseif action == 'set' then
        player.Functions.SetMoney(moneyType, math.max(0, amount), "souh4il_dev_admin")
    end

    local updatedCash = player.PlayerData.money.cash
    local updatedBank = player.PlayerData.money.bank
    Logger.Write("MANAGE_PLAYER_MONEY", source, tId, { action = action, type = moneyType, amount = amount, cash = updatedCash, bank = updatedBank }, "SUCCESS")
    return { success = true, cash = updatedCash, bank = updatedBank }
end)

---Callback: Give Custom Item Directly to Player
lib.callback.register('souh4il_dev:server:giveItemToPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'give_item')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    local item = tostring(data.item or ''):lower():gsub('%s+', '')
    local count = math.max(1, tonumber(data.count) or 1)

    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end
    if item == '' then return { success = false, error = "INVALID_ITEM" } end

    local success, response = exports.ox_inventory:AddItem(tId, item, count)
    if success then
        Logger.Write("GIVE_ITEM_TARGET", source, tId, { item = item, count = count }, "SUCCESS")
        return { success = true }
    else
        return { success = false, error = response or "CANNOT_ADD_ITEM" }
    end
end)

---Callback: Control Target Player Vitals (Armor, Hunger, Kill, Godmode)
lib.callback.register('souh4il_dev:server:controlPlayerVitals', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local vType = data.vitalsType -- 'armor', 'feed', 'kill', 'godmode'
    TriggerClientEvent('souh4il_dev:client:receiveVitalsControl', tId, { type = vType, value = data.value })
    Logger.Write("CONTROL_PLAYER_VITALS", source, tId, { type = vType, value = data.value }, "SUCCESS")
    return { success = true }
end)

---Callback: Control Target Player Vehicle
lib.callback.register('souh4il_dev:server:controlPlayerVehicle', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local vAction = data.vehAction -- 'repair', 'max_tune', 'eject', 'damage', 'delete'
    TriggerClientEvent('souh4il_dev:client:receiveVehicleControl', tId, vAction)
    Logger.Write("CONTROL_PLAYER_VEHICLE", source, tId, { action = vAction }, "SUCCESS")
    return { success = true }
end)

---Callback: Control Target Player Appearance & Ped
lib.callback.register('souh4il_dev:server:controlPlayerAppearance', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local aType = data.appType -- 'set_ped', 'clothing_menu', 'barber_menu', 'reload_skin', 'clean_ped'
    if aType == 'set_ped' then
        TriggerClientEvent('souh4il_dev:client:receiveSetPed', tId, data.model)
    elseif aType == 'clothing_menu' then
        TriggerClientEvent('souh4il_dev:client:receiveOpenClothing', tId, 'clothing')
    elseif aType == 'barber_menu' then
        TriggerClientEvent('souh4il_dev:client:receiveOpenClothing', tId, 'barber')
    elseif aType == 'reload_skin' then
        TriggerClientEvent('souh4il_dev:client:receiveReloadSkin', tId)
    elseif aType == 'clean_ped' then
        TriggerClientEvent('souh4il_dev:client:receiveCleanPed', tId)
    end

    Logger.Write("CONTROL_PLAYER_APPEARANCE", source, tId, { type = aType, model = data.model }, "SUCCESS")
    return { success = true }
end)

---Callback: Set Target Player Job Direct
lib.callback.register('souh4il_dev:server:setPlayerJobDirect', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'set_job')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data.targetId)
    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local job = tostring(data.job or 'unemployed')
    local grade = tonumber(data.grade) or 0
    player.Functions.SetJob(job, grade)

    Logger.Write("SET_PLAYER_JOB", source, tId, { job = job, grade = grade }, "SUCCESS")
    return { success = true, job = job, grade = grade }
end)

---Callback: Ban Offline Player
lib.callback.register('souh4il_dev:server:banOfflinePlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'ban_player')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local identifier = data.identifier
    local reason = data.reason or "Banned by administrator (Offline)"
    local hours = tonumber(data.duration) or 0
    local expireTime = hours > 0 and (os.time() + hours * 3600) or 2147483647
    local banner = GetPlayerName(tostring(source)) or "Staff"

    MySQL.insert.await('INSERT INTO bans (name, license, discord, ip, reason, expire, bannedby) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        "Offline Player",
        identifier,
        "NONE",
        "NONE",
        reason,
        expireTime,
        banner
    })

    Logger.Write("BAN_OFFLINE", source, nil, { identifier = identifier, reason = reason, hours = hours }, "SUCCESS")
    return { success = true }
end)

---Callback: Unban Player
lib.callback.register('souh4il_dev:server:unbanPlayer', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'ban_player')
    if not allowed then return { success = false, error = reason } end
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local queryVal = data.identifier or data.id
    MySQL.query.await('DELETE FROM bans WHERE id = ? OR license = ?', { queryVal, queryVal })
    Logger.Write("UNBAN_PLAYER", source, nil, { identifier = queryVal }, "SUCCESS")
    return { success = true }
end)

---Callback: Give Vehicle Keys To Player (Qbox Compatible — Active or Garage)
lib.callback.register('souh4il_dev:server:giveKeysToPlayer', function(source, data)
    local tId = tonumber(data and data.targetId) or source
    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    local cleanPlate = string.gsub(plate, "%s+", ""):upper()
    local found = false
    local spawnedFromGarage = false

    -- 1. If no plate specified, check if player is currently in a vehicle
    if #cleanPlate == 0 then
        local ped = GetPlayerPed(tId)
        local currVeh = ped ~= 0 and GetVehiclePedIsIn(ped, false) or 0
        if currVeh ~= 0 and DoesEntityExist(currVeh) then
            SetVehicleDoorsLocked(currVeh, 1)
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(tId, currVeh) end)
            if source ~= tId then
                pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, currVeh) end)
            end
            found = true
        end
    else
        -- 2. Match against all vehicles in world
        local allVehs = GetAllVehicles()
        for _, veh in ipairs(allVehs) do
            if DoesEntityExist(veh) then
                local vPlate = GetVehicleNumberPlateText(veh)
                if vPlate and string.gsub(vPlate, "%s+", ""):upper() == cleanPlate then
                    SetVehicleDoorsLocked(veh, 1)
                    pcall(function() exports.qbx_vehiclekeys:GiveKeys(tId, veh) end)
                    if source ~= tId then
                        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, veh) end)
                    end
                    found = true
                    break
                end
            end
        end

        -- 3. If vehicle is stored in garage (not in world), spawn it near target/admin & give keys
        if not found then
            local row = MySQL.single.await([[
                SELECT id, citizenid, vehicle, plate, mods
                FROM player_vehicles
                WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
                LIMIT 1
            ]], { plate, cleanPlate })

            if row then
                local refPed = GetPlayerPed(DoesPlayerExist(tostring(tId)) and tId or source)
                local coords = GetEntityCoords(refPed)
                local heading = GetEntityHeading(refPed)
                local modelName = tostring(row.vehicle or 'adder')
                local spawnedVeh = nil

                pcall(function()
                    if exports.qbx_core and exports.qbx_core.SpawnVehicle then
                        local _, v = exports.qbx_core:SpawnVehicle(tId, modelName, vec4(coords.x + 2.5, coords.y, coords.z, heading), false)
                        spawnedVeh = v
                    end
                end)

                if not spawnedVeh or not DoesEntityExist(spawnedVeh) then
                    spawnedVeh = CreateVehicleServerSetter(joaat(modelName), "automobile", coords.x + 2.5, coords.y, coords.z, heading)
                end

                if spawnedVeh and DoesEntityExist(spawnedVeh) then
                    local actualPlate = row.plate or plate
                    SetVehicleNumberPlateText(spawnedVeh, actualPlate)
                    SetVehicleDoorsLocked(spawnedVeh, 1)
                    Entity(spawnedVeh).state:set('vehicleid', row.id, false)
                    Entity(spawnedVeh).state.owner = row.citizenid
                    pcall(function() exports.qbx_vehiclekeys:GiveKeys(tId, spawnedVeh) end)
                    if source ~= tId then
                        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, spawnedVeh) end)
                    end
                    MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE id = ?', { row.id })
                    found = true
                    spawnedFromGarage = true
                end
            end
        end
    end

    Logger.Write("GIVE_KEYS", source, tId, { plate = plate, foundEntity = found, spawnedFromGarage = spawnedFromGarage }, "SUCCESS")
    return { success = true, found = found, spawnedFromGarage = spawnedFromGarage }
end)

---Callback: Seize / Remove Player Vehicle
lib.callback.register('souh4il_dev:server:seizePlayerVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    local targetId = tonumber(data and data.targetId)
    local citizenid = data and data.citizenid

    if #plate == 0 then
        return { success = false, error = "INVALID_PLATE" }
    end

    local cleanPlate = string.gsub(plate, "%s+", ""):upper()

    -- 1. Remove from database
    MySQL.query.await('DELETE FROM player_vehicles WHERE plate = ? OR REPLACE(UPPER(plate), " ", "") = ?', { plate, cleanPlate })

    -- 2. Find and delete physical entity in world & revoke keys
    local allVehs = GetAllVehicles()
    for _, veh in ipairs(allVehs) do
        if DoesEntityExist(veh) then
            local vehPlate = GetVehicleNumberPlateText(veh)
            if vehPlate and string.gsub(vehPlate, "%s+", ""):upper() == cleanPlate then
                if targetId and DoesPlayerExist(tostring(targetId)) then
                    pcall(function() exports.qbx_vehiclekeys:RemoveKeys(targetId, veh, true) end)
                end
                Entity(veh).state:set('vehicleid', nil, false)
                DeleteEntity(veh)
            end
        end
    end

    Logger.Write("SEIZE_VEHICLE", source, targetId, { plate = plate, citizenid = citizenid }, "SUCCESS")
    Outbox.QueueDiscordAlert("VEHICLE_SEIZED", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { plate = plate, target = targetId })

    return { success = true, plate = plate }
end)

---Callback: Give Owned Vehicle (Saved in player_vehicles with Keys)
lib.callback.register('souh4il_dev:server:givePlayerOwnedVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local tId = tonumber(data and data.targetId)
    if not tId or not DoesPlayerExist(tostring(tId)) then
        return { success = false, error = "PLAYER_NOT_FOUND" }
    end

    local player = exports.qbx_core:GetPlayer(tId)
    if not player then return { success = false, error = "PLAYER_NOT_FOUND" } end

    local model = tostring(data and data.model or ''):lower():gsub('^%s*(.-)%s*$', '%1')
    if #model == 0 then return { success = false, error = "INVALID_MODEL" } end

    local plate = tostring(data and data.plate or ''):upper():gsub('^%s*(.-)%s*$', '%1')
    if #plate == 0 then
        local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        local numbers = "0123456789"
        local p = ""
        for i = 1, 3 do
            local r = math.random(1, #letters)
            p = p .. letters:sub(r, r)
        end
        p = p .. " "
        for i = 1, 4 do
            local r = math.random(1, #numbers)
            p = p .. numbers:sub(r, r)
        end
        plate = p
    else
        if #plate > 8 then plate = plate:sub(1, 8) end
    end

    local garage = tostring(data and data.garage or 'motel')
    local citizenid = player.PlayerData.citizenid
    local license = player.PlayerData.license or Identifiers.GetLicense(tId) or "UNKNOWN"
    local hash = joaat(model)
    local defaultMods = json.encode({ plate = plate, model = hash })

    -- Insert into player_vehicles
    local insertId = MySQL.insert.await([[
        INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, fuel, engine, body, state)
        VALUES (?, ?, ?, ?, ?, ?, ?, 100, 1000, 1000, 0)
        ON DUPLICATE KEY UPDATE citizenid = VALUES(citizenid), vehicle = VALUES(vehicle), hash = VALUES(hash)
    ]], { license, citizenid, model, hash, defaultMods, plate, garage })

    if not insertId or insertId == 0 then
        local row = MySQL.single.await('SELECT id FROM player_vehicles WHERE plate = ? LIMIT 1', { plate })
        insertId = row and row.id or nil
    end

    -- Spawn vehicle near player & warp
    local ped = GetPlayerPed(tId)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local spawnedVeh = nil

    pcall(function()
        if exports.qbx_core and exports.qbx_core.SpawnVehicle then
            local _, v = exports.qbx_core:SpawnVehicle(tId, model, vec4(coords.x, coords.y, coords.z, heading), true)
            spawnedVeh = v
        end
    end)

    if not spawnedVeh or not DoesEntityExist(spawnedVeh) then
        spawnedVeh = CreateVehicleServerSetter(hash, "automobile", coords.x, coords.y, coords.z, heading)
    end

    if spawnedVeh and DoesEntityExist(spawnedVeh) then
        SetVehicleNumberPlateText(spawnedVeh, plate)
        if insertId then
            Entity(spawnedVeh).state:set('vehicleid', insertId, false)
        end
        Entity(spawnedVeh).state.owner = citizenid
        TaskWarpPedIntoVehicle(ped, spawnedVeh, -1)
        pcall(function() exports.qbx_vehiclekeys:GiveKeys(tId, spawnedVeh) end)
    end

    Logger.Write("GIVE_OWNED_VEHICLE", source, tId, { model = model, plate = plate, citizenid = citizenid, garage = garage }, "SUCCESS")
    Outbox.QueueDiscordAlert("GIVE_OWNED_VEHICLE", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { model = model, plate = plate, target = tId })

    return { success = true, plate = plate, model = model, garage = garage }
end)

---Callback: Seize / Revoke Player Property (House)
lib.callback.register('souh4il_dev:server:seizePlayerProperty', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propertyId = tonumber(data and data.propertyId)
    local targetId = tonumber(data and data.targetId)
    local citizenid = data and data.citizenid

    if not propertyId then return { success = false, error = "INVALID_PROPERTY_ID" } end

    local prop = MySQL.single.await('SELECT property_name, owner FROM properties WHERE id = ?', { propertyId })
    if not prop then return { success = false, error = "PROPERTY_NOT_FOUND" } end

    -- Reset property in DB (JSON_ARRAY for qbx_properties compatibility)
    MySQL.update.await('UPDATE properties SET owner = NULL, keyholders = JSON_ARRAY() WHERE id = ?', { propertyId })

    Logger.Write("SEIZE_PROPERTY", source, targetId, { propertyId = propertyId, propertyName = prop.property_name, citizenid = citizenid }, "SUCCESS")
    Outbox.QueueDiscordAlert("PROPERTY_SEIZED", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { propertyId = propertyId, propertyName = prop.property_name, target = targetId })

    return { success = true, propertyId = propertyId, propertyName = prop.property_name }
end)

---Callback: Open House ox_inventory Stash
lib.callback.register('souh4il_dev:server:openHouseStash', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propId = tonumber(data and data.propertyId)
    local propName = tostring(data and data.propertyName or ''):gsub('^%s*(.-)%s*$', '%1')
    if not propId and #propName == 0 then return { success = false, error = "INVALID_PROPERTY" } end

    local prop = nil
    if propId then
        prop = MySQL.single.await('SELECT id, property_name, owner, stash_options FROM properties WHERE id = ? LIMIT 1', { propId })
    end
    if not prop and #propName > 0 then
        prop = MySQL.single.await('SELECT id, property_name, owner, stash_options FROM properties WHERE property_name = ? LIMIT 1', { propName })
    end

    local actualName = (prop and prop.property_name) or propName
    local ownerCid = (prop and prop.owner) or nil
    local slots, maxWeight = 50, 1000000

    if prop and prop.stash_options then
        local okDec, opts = pcall(function()
            return type(prop.stash_options) == 'string' and json.decode(prop.stash_options) or prop.stash_options
        end)
        if okDec and type(opts) == 'table' then
            slots = tonumber(opts.slots) or 50
            maxWeight = tonumber(opts.maxWeight) or 1000000
        end
    end

    local stashId = 'qbx_properties_' .. actualName
    Player(source).state.sdev_bypass_stash = true

    -- Register stash dynamically so it works even if no one has entered the house since server start
    pcall(function()
        exports.ox_inventory:RegisterStash(stashId, 'Property: ' .. actualName, slots, maxWeight, ownerCid or true)
    end)

    if ownerCid and #tostring(ownerCid) > 0 then
        exports.ox_inventory:forceOpenInventory(source, 'stash', { id = stashId, owner = ownerCid })
    else
        exports.ox_inventory:forceOpenInventory(source, 'stash', stashId)
    end

    Logger.Write("OPEN_HOUSE_STASH", source, nil, { propertyName = actualName, stashId = stashId, owner = ownerCid }, "SUCCESS")
    return { success = true, stashId = stashId }
end)

---Callback: Teleport to Property Entrance
lib.callback.register('souh4il_dev:server:teleportToProperty', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propId = tonumber(data and data.propertyId)
    if not propId then return { success = false, error = "INVALID_ID" } end

    local prop = MySQL.single.await('SELECT coords, property_name FROM properties WHERE id = ?', { propId })
    if not prop or not prop.coords then return { success = false, error = "PROPERTY_NOT_FOUND" } end

    local coords = json.decode(prop.coords)
    if coords and coords.x then
        local ped = GetPlayerPed(source)
        SetEntityCoords(ped, coords.x, coords.y, coords.z + 0.2, false, false, false, false)
        Logger.Write("TP_PROPERTY", source, nil, { propertyId = propId, propertyName = prop.property_name }, "SUCCESS")
        return { success = true, propertyName = prop.property_name }
    end

    return { success = false, error = "INVALID_COORDS" }
end)

---Callback: Give Property Keyholder Access (Double de Clé)
lib.callback.register('souh4il_dev:server:givePropertyKey', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propId = tonumber(data and data.propertyId)
    local toPlayerId = tonumber(data and data.toPlayerId)
    if not propId or not toPlayerId then return { success = false, error = "INVALID_PARAMS" } end

    local target = exports.qbx_core:GetPlayer(toPlayerId)
    if not target then return { success = false, error = "TARGET_NOT_FOUND" } end

    local targetCid = target.PlayerData.citizenid
    local prop = MySQL.single.await('SELECT id, property_name, owner, keyholders FROM properties WHERE id = ?', { propId })
    if not prop then return { success = false, error = "PROPERTY_NOT_FOUND" } end

    if prop.owner == targetCid then
        return { success = false, error = "ALREADY_OWNER" }
    end

    local keyholders = {}
    if prop.keyholders then
        local okDec, dec = pcall(function()
            return type(prop.keyholders) == 'string' and json.decode(prop.keyholders) or prop.keyholders
        end)
        if okDec and type(dec) == 'table' then
            for _, cid in ipairs(dec) do
                if type(cid) == 'string' then
                    keyholders[#keyholders + 1] = cid
                end
            end
        end
    end

    for _, cid in ipairs(keyholders) do
        if cid == targetCid then
            return { success = true, targetName = GetPlayerName(tostring(toPlayerId)), alreadyHad = true }
        end
    end

    keyholders[#keyholders + 1] = targetCid
    MySQL.update.await('UPDATE properties SET keyholders = ? WHERE id = ?', { json.encode(keyholders), propId })

    Logger.Write("GIVE_PROPERTY_KEY", source, toPlayerId, { propertyId = propId, propertyName = prop.property_name, keyholder = targetCid }, "SUCCESS")
    return { success = true, targetName = GetPlayerName(tostring(toPlayerId)), keyholders = keyholders }
end)

---Callback: Reset House Keyholders
lib.callback.register('souh4il_dev:server:resetPropertyKeyholders', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propId = tonumber(data and data.propertyId)
    if not propId then return { success = false, error = "INVALID_ID" } end

    MySQL.update.await('UPDATE properties SET keyholders = JSON_ARRAY() WHERE id = ?', { propId })
    Logger.Write("RESET_PROPERTY_KEYS", source, nil, { propertyId = propId }, "SUCCESS")
    return { success = true }
end)

---Callback: Transfer Property Ownership
lib.callback.register('souh4il_dev:server:transferPlayerProperty', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local propId = tonumber(data and data.propertyId)
    local toPlayerId = tonumber(data and data.toPlayerId)
    if not propId or not toPlayerId then return { success = false, error = "INVALID_PARAMS" } end

    local target = exports.qbx_core:GetPlayer(toPlayerId)
    if not target then return { success = false, error = "TARGET_NOT_FOUND" } end

    local newCid = target.PlayerData.citizenid
    local prop = MySQL.single.await('SELECT property_name, owner, stash_options FROM properties WHERE id = ?', { propId })
    if not prop then return { success = false, error = "PROPERTY_NOT_FOUND" } end

    local oldCid = prop.owner
    local stashId = 'qbx_properties_' .. prop.property_name

    MySQL.update.await('UPDATE properties SET owner = ?, rent_interval = NULL, keyholders = JSON_ARRAY() WHERE id = ?', { newCid, propId })

    -- Migrate stash ownership in ox_inventory table so items stay in the house for the new owner
    if oldCid and oldCid ~= newCid then
        pcall(function()
            MySQL.update.await('DELETE FROM ox_inventory WHERE name = ? AND owner = ?', { stashId, newCid })
            MySQL.update.await('UPDATE ox_inventory SET owner = ? WHERE name = ? AND owner = ?', { newCid, stashId, oldCid })
        end)
    end

    pcall(function()
        local slots, maxWeight = 50, 1000000
        if prop.stash_options then
            local opts = type(prop.stash_options) == 'string' and json.decode(prop.stash_options) or prop.stash_options
            if type(opts) == 'table' then
                slots = tonumber(opts.slots) or 50
                maxWeight = tonumber(opts.maxWeight) or 1000000
            end
        end
        exports.ox_inventory:RegisterStash(stashId, 'Property: ' .. prop.property_name, slots, maxWeight, newCid)
    end)

    Logger.Write("TRANSFER_PROPERTY", source, toPlayerId, { propertyId = propId, propertyName = prop.property_name, oldOwner = oldCid, newOwner = newCid }, "SUCCESS")
    Outbox.QueueDiscordAlert("TRANSFER_PROPERTY", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { propertyId = propId, propertyName = prop.property_name, toTarget = toPlayerId })

    return { success = true, newOwnerName = GetPlayerName(tostring(toPlayerId)) }
end)

---Callback: Open Vehicle Trunk Remotely (Works Active or in Garage)
lib.callback.register('souh4il_dev:server:openVehicleTrunk', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    if #plate == 0 then return { success = false, error = "INVALID_PLATE" } end

    local cleanPlate = string.gsub(plate, "%s+", ""):upper()
    local row = MySQL.single.await([[
        SELECT id, plate, citizenid
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, cleanPlate })

    local actualPlate = (row and row.plate) or plate

    -- If entity exists in world, ensure vehicleid statebag is set and use exact entity plate
    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                if row and row.id and not Entity(v).state.vehicleid then
                    Entity(v).state:set('vehicleid', row.id, false)
                end
                actualPlate = p:gsub('^%s*(.-)%s*$', '%1')
                break
            end
        end
    end

    exports.ox_inventory:forceOpenInventory(source, 'trunk', 'trunk' .. actualPlate)
    Logger.Write("OPEN_VEH_TRUNK", source, nil, { plate = actualPlate }, "SUCCESS")
    return { success = true, plate = actualPlate }
end)

---Callback: Open Vehicle Glovebox Remotely (Works Active or in Garage)
lib.callback.register('souh4il_dev:server:openVehicleGlovebox', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    if #plate == 0 then return { success = false, error = "INVALID_PLATE" } end

    local cleanPlate = string.gsub(plate, "%s+", ""):upper()
    local row = MySQL.single.await([[
        SELECT id, plate, citizenid
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, cleanPlate })

    local actualPlate = (row and row.plate) or plate

    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                if row and row.id and not Entity(v).state.vehicleid then
                    Entity(v).state:set('vehicleid', row.id, false)
                end
                actualPlate = p:gsub('^%s*(.-)%s*$', '%1')
                break
            end
        end
    end

    exports.ox_inventory:forceOpenInventory(source, 'glovebox', 'glove' .. actualPlate)
    Logger.Write("OPEN_VEH_GLOVEBOX", source, nil, { plate = actualPlate }, "SUCCESS")
    return { success = true, plate = actualPlate }
end)

---Callback: Bring Player Vehicle (Active or from Garage)
lib.callback.register('souh4il_dev:server:bringPlayerVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    local model = tostring(data and data.model or 'adder')
    local targetId = tonumber(data and data.targetId)
    local cleanPlate = string.gsub(plate, "%s+", ""):upper()
    local adminPed = GetPlayerPed(source)
    local coords = GetEntityCoords(adminPed)
    local heading = GetEntityHeading(adminPed)

    local row = MySQL.single.await([[
        SELECT id, citizenid, vehicle, plate, mods
        FROM player_vehicles
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
        LIMIT 1
    ]], { plate, cleanPlate })

    local actualPlate = (row and row.plate) or plate
    local actualModel = (row and row.vehicle and #tostring(row.vehicle) > 0) and tostring(row.vehicle) or model
    local decodedMods = nil
    if row and row.mods then
        pcall(function()
            decodedMods = type(row.mods) == 'string' and json.decode(row.mods) or row.mods
        end)
    end

    -- 1. Check if vehicle exists in world
    local foundVeh = nil
    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                foundVeh = v
                break
            end
        end
    end

    if foundVeh and DoesEntityExist(foundVeh) then
        SetEntityCoords(foundVeh, coords.x + 2.0, coords.y, coords.z + 0.5, false, false, false, false)
        SetEntityHeading(foundVeh, heading)
        SetVehicleDoorsLocked(foundVeh, 1)
        if row and row.id then
            Entity(foundVeh).state:set('vehicleid', row.id, false)
            Entity(foundVeh).state.owner = row.citizenid
        end
        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, foundVeh) end)
        if targetId and targetId ~= source and DoesPlayerExist(tostring(targetId)) then
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(targetId, foundVeh) end)
        end
        Logger.Write("BRING_VEHICLE", source, targetId, { plate = actualPlate, spawned = false }, "SUCCESS")
        return { success = true, action = "teleported", netId = NetworkGetNetworkIdFromEntity(foundVeh), mods = decodedMods }
    end

    -- 2. If stored in garage, spawn it directly to admin
    local spawnedVeh = nil
    pcall(function()
        if exports.qbx_core and exports.qbx_core.SpawnVehicle then
            local _, v = exports.qbx_core:SpawnVehicle(source, actualModel, vec4(coords.x + 2.0, coords.y, coords.z, heading), true)
            spawnedVeh = v
        end
    end)

    if not spawnedVeh or not DoesEntityExist(spawnedVeh) then
        local hash = joaat(actualModel)
        spawnedVeh = CreateVehicleServerSetter(hash, "automobile", coords.x + 2.0, coords.y, coords.z, heading)
    end

    if spawnedVeh and DoesEntityExist(spawnedVeh) then
        SetVehicleNumberPlateText(spawnedVeh, actualPlate)
        SetVehicleDoorsLocked(spawnedVeh, 1)
        if row and row.id then
            Entity(spawnedVeh).state:set('vehicleid', row.id, false)
            Entity(spawnedVeh).state.owner = row.citizenid
            MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE id = ?', { row.id })
        else
            MySQL.update.await('UPDATE player_vehicles SET state = 0 WHERE plate = ?', { actualPlate })
        end
        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, spawnedVeh) end)
        if targetId and targetId ~= source and DoesPlayerExist(tostring(targetId)) then
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(targetId, spawnedVeh) end)
        end
        Logger.Write("BRING_VEHICLE", source, targetId, { plate = actualPlate, spawned = true }, "SUCCESS")
        return { success = true, action = "spawned", netId = NetworkGetNetworkIdFromEntity(spawnedVeh), mods = decodedMods }
    end

    return { success = false, error = "FAILED_TO_BRING" }
end)

---Callback: Store Player Vehicle Back Into Garage (state = 1)
lib.callback.register('souh4il_dev:server:storePlayerVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    if #plate == 0 then return { success = false, error = "INVALID_PLATE" } end

    local cleanPlate = string.gsub(plate, "%s+", ""):upper()
    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                DeleteEntity(v)
            end
        end
    end

    MySQL.update.await([[
        UPDATE player_vehicles
        SET state = 1, garage = COALESCE(NULLIF(garage, ''), 'pillboxgarage')
        WHERE plate = ? OR REPLACE(UPPER(plate), ' ', '') = ?
    ]], { plate, cleanPlate })

    Logger.Write("STORE_VEHICLE", source, nil, { plate = plate }, "SUCCESS")
    return { success = true, plate = plate }
end)

---Callback: Repair & Wash Player Vehicle
lib.callback.register('souh4il_dev:server:repairPlayerVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    local cleanPlate = string.gsub(plate, "%s+", ""):upper()

    MySQL.update.await('UPDATE player_vehicles SET engine = 1000, body = 1000, fuel = 100 WHERE plate = ? OR REPLACE(UPPER(plate), " ", "") = ?', { plate, cleanPlate })

    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                SetVehicleFixed(v)
                SetVehicleDeformationFixed(v)
                SetVehicleDirtLevel(v, 0.0)
                SetVehicleEngineHealth(v, 1000.0)
                SetVehicleBodyHealth(v, 1000.0)
                break
            end
        end
    end

    Logger.Write("REPAIR_VEHICLE", source, nil, { plate = plate }, "SUCCESS")
    return { success = true }
end)

---Callback: Transfer Player Vehicle
lib.callback.register('souh4il_dev:server:transferPlayerVehicle', function(source, data)
    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local plate = tostring(data and data.plate or ''):gsub('^%s*(.-)%s*$', '%1')
    local toPlayerId = tonumber(data and data.toPlayerId)
    if not toPlayerId or #plate == 0 then return { success = false, error = "INVALID_PARAMS" } end

    local target = exports.qbx_core:GetPlayer(toPlayerId)
    if not target then return { success = false, error = "TARGET_NOT_FOUND" } end

    local newCid = target.PlayerData.citizenid
    local newLic = target.PlayerData.license or Identifiers.GetLicense(toPlayerId) or "UNKNOWN"
    local cleanPlate = string.gsub(plate, "%s+", ""):upper()

    MySQL.update.await('UPDATE player_vehicles SET citizenid = ?, license = ? WHERE plate = ? OR REPLACE(UPPER(plate), " ", "") = ?', { newCid, newLic, plate, cleanPlate })

    local allVehs = GetAllVehicles()
    for _, v in ipairs(allVehs) do
        if DoesEntityExist(v) then
            local p = GetVehicleNumberPlateText(v)
            if p and string.gsub(p, "%s+", ""):upper() == cleanPlate then
                Entity(v).state.owner = newCid
                SetVehicleDoorsLocked(v, 1)
                pcall(function() exports.qbx_vehiclekeys:GiveKeys(toPlayerId, v) end)
                break
            end
        end
    end

    Logger.Write("TRANSFER_VEHICLE", source, toPlayerId, { plate = plate, newOwner = newCid }, "SUCCESS")
    Outbox.QueueDiscordAlert("TRANSFER_VEHICLE", GetPlayerName(tostring(source)) or "Staff", Identifiers.GetLicense(source) or "UNKNOWN", { plate = plate, toTarget = toPlayerId })

    return { success = true, newOwnerName = GetPlayerName(tostring(toPlayerId)) }
end)

---Callback: Toggle Job Duty
lib.callback.register('souh4il_dev:server:toggleDuty', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'toggle_duty')
    if not allowed then return { success = false, error = reason } end

    local player = exports.qbx_core:GetPlayer(source)
    if not player then return { success = false } end
    local currentDuty = player.PlayerData.job.onduty
    player.Functions.SetJobDuty(not currentDuty)
    exports.qbx_core:Notify(source, ("Duty state: %s"):format(not currentDuty and "ON DUTY" or "OFF DUTY"), "inform")
    return { success = true, duty = not currentDuty }
end)

---Callback: Remove Stress
lib.callback.register('souh4il_dev:server:removeStress', function(source, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'remove_stress')
    if not allowed then return { success = false, error = reason } end

    local tId = tonumber(targetId) or source
    local player = exports.qbx_core:GetPlayer(tId)
    if player then
        player.Functions.SetMetaData('stress', 0)
        TriggerClientEvent('hud:client:UpdateStress', tId, 0)
    end
    return { success = true }
end)

---Callback: Get Staff Data and Online Players for Permissions Management
lib.callback.register('souh4il_dev:server:getStaffData', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_staff')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.IsOwner(source) and not Permissions.HasModulePermission(source, 'staff_management') and not Permissions.HasModulePermission(source, 'staff') then
        return { success = false, error = "ACCESS_DENIED" }
    end

    -- Online Players lookup (ga3 member f server)
    local onlinePlayers = {}
    local onlineLicenses = {}
    local canonicalLic = PermissionsConfig.CanonicalOwnerLicense

    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        if src then
            local lic = Identifiers.GetLicense(src)
            local pName = GetPlayerName(src)
            local qbxPlayer = exports.qbx_core:GetPlayer(src)
            local cid = qbxPlayer and qbxPlayer.PlayerData.citizenid or 'N/A'
            if lic then
                onlineLicenses[lic] = src
            end

            local isOwner = (lic == canonicalLic)
            local isStaff = isOwner or (lic and Permissions.StaffCache[lic] ~= nil)
            local role = isOwner and "OWNER" or (isStaff and Permissions.StaffCache[lic].role or "MEMBER")
            local perms = isOwner and Permissions.DEFAULT_ROLE_PERMS.owner or (isStaff and Permissions.StaffCache[lic].permissions or {})

            onlinePlayers[#onlinePlayers + 1] = {
                source = src,
                name = pName,
                citizenid = cid,
                license = lic or 'N/A',
                job = qbxPlayer and qbxPlayer.PlayerData.job and qbxPlayer.PlayerData.job.label or 'Unemployed',
                gang = qbxPlayer and qbxPlayer.PlayerData.gang and qbxPlayer.PlayerData.gang.label or 'None',
                hasAccess = isStaff,
                role = role,
                permissions = perms,
                isOwner = isOwner,
            }
        end
    end

    -- Registered Staff from DB / Cache
    local staffList = {}

    -- First, canonical owner
    staffList[#staffList + 1] = {
        license = canonicalLic,
        name = "SOUH4IL (Owner)",
        role = "OWNER",
        permissions = Permissions.DEFAULT_ROLE_PERMS.owner,
        isOwner = true,
        online = onlineLicenses[canonicalLic] ~= nil,
        source = onlineLicenses[canonicalLic],
        granted_by = "System",
    }

    -- Only full owners & staff_management holders see other staff's full permissions.
    -- Regular admins only see role + online status.
    local canViewAllPerms = Permissions.IsOwner(source) or Permissions.HasModulePermission(source, 'staff_management')

    for lic, data in pairs(Permissions.StaffCache) do
        if lic ~= canonicalLic then
            local isSelf = (lic == Identifiers.GetLicense(source))
            staffList[#staffList + 1] = {
                license = lic,
                name = data.name,
                role = data.role,
                permissions = (canViewAllPerms or isSelf) and (data.permissions or {}) or nil,
                isOwner = false,
                online = onlineLicenses[lic] ~= nil,
                source = onlineLicenses[lic],
                granted_by = data.granted_by or "Owner",
            }
        end
    end

    return {
        success = true,
        staff = staffList,
        onlinePlayers = onlinePlayers,
        defaultPerms = Permissions.DEFAULT_ROLE_PERMS,
    }
end)

---Callback: Save / Update Staff Member
lib.callback.register('souh4il_dev:server:saveStaffMember', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'staff_action')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.IsOwner(source) and not Permissions.HasModulePermission(source, 'staff_management') and not Permissions.HasModulePermission(source, 'staff') then
        return { success = false, error = "ACCESS_DENIED" }
    end

    if not data or not data.license or data.license == "" then
        return { success = false, error = "INVALID_LICENSE" }
    end

    -- Defense-in-depth: Non-owners cannot grant Owner role, modify Owner, or give staff_management
    if not Permissions.IsOwner(source) then
        if data.license == PermissionsConfig.CanonicalOwnerLicense then
            return { success = false, error = "CANNOT_MODIFY_OWNER" }
        end
        if string.lower(data.role or '') == 'owner' then
            return { success = false, error = "CANNOT_GRANT_OWNER_ROLE" }
        end
        if data.permissions and (data.permissions.staff == true or data.permissions.staff_management == true) then
            return { success = false, error = "CANNOT_DELEGATE_STAFF_MANAGEMENT" }
        end
    end

    local granterName = GetPlayerName(source) or "Owner"
    local ok, err = Permissions.SaveStaff(data.license, data.name or "Staff", data.role or "moderator", data.permissions or {}, granterName)
    if not ok then
        return { success = false, error = err }
    end

    Logger.Write("SAVE_STAFF_PERMISSIONS", source, nil, { targetLicense = data.license, name = data.name, role = data.role, perms = data.permissions }, "SUCCESS")

    -- Notify target player if online
    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        if src and Identifiers.GetLicense(src) == data.license then
            exports.qbx_core:Notify(src, ("Votre rang SOUH4IL-DEV a été mis à jour: %s"):format(string.upper(data.role or "Staff")), "success", 7000)
            TriggerClientEvent('souh4il_dev:client:refreshPermissions', src)
            break
        end
    end

    return { success = true }
end)

---Callback: Remove Staff Member
lib.callback.register('souh4il_dev:server:removeStaffMember', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'staff_action')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    if not data or not data.license then
        return { success = false, error = "INVALID_LICENSE" }
    end

    if data.license == PermissionsConfig.CanonicalOwnerLicense then
        return { success = false, error = "CANNOT_REMOVE_OWNER" }
    end

    local ok, err = Permissions.RemoveStaff(data.license)
    if not ok then
        return { success = false, error = err }
    end

    Logger.Write("REMOVE_STAFF_PERMISSIONS", source, nil, { targetLicense = data.license }, "SUCCESS")

    -- If target player is online, close their panel and notify them
    for _, srcStr in ipairs(GetPlayers()) do
        local src = tonumber(srcStr)
        if src and Identifiers.GetLicense(src) == data.license then
            exports.qbx_core:Notify(src, "Vos accès SOUH4IL-DEV ont été révoqués par l'administration.", "error", 7000)
            TriggerClientEvent('souh4il_dev:client:forceClosePanel', src)
            break
        end
    end

    return { success = true }
end)

-- Event Manager State
local ActiveEvent = nil

---Callback: Start Event
lib.callback.register('souh4il_dev:server:startEvent', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'event_action')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.IsOwner(source) and not Permissions.HasModulePermission(source, 'events') then
        return { success = false, error = "ACCESS_DENIED" }
    end

    local ped = GetPlayerPed(source)
    local pCoords = GetEntityCoords(ped)
    local targetCoords = data.coords or { x = pCoords.x, y = pCoords.y, z = pCoords.z }

    ActiveEvent = {
        id = os.time(),
        type = data.eventType or 'custom',
        title = data.title or 'Community Event',
        message = data.message or 'Un grand événement a commencé dans Chicago Roleplay !',
        coords = targetCoords,
        radius = tonumber(data.radius) or 100.0,
        blipColor = tonumber(data.blipColor) or 1,
        blipSprite = tonumber(data.blipSprite) or 38,
        weather = data.weather,
        time = data.time,
        startedBy = GetPlayerName(source),
        startedAt = os.date('%X'),
    }

    -- Weather & Time override if specified
    if ActiveEvent.weather and ActiveEvent.weather ~= '' then
        local w = tostring(ActiveEvent.weather):upper()
        GlobalState.weather = { weather = w, time = 9999999999 }
        pcall(function()
            if exports['Renewed-Weathersync'] and exports['Renewed-Weathersync'].setWeather then
                exports['Renewed-Weathersync']:setWeather(w)
            end
        end)
    end
    if ActiveEvent.time and ActiveEvent.time.hour then
        local h = tonumber(ActiveEvent.time.hour) or 12
        local m = tonumber(ActiveEvent.time.minute) or 0
        GlobalState.time = { hour = h, minute = m }
        GlobalState.currentTime = { hour = h, minute = m }
        pcall(function()
            if exports['Renewed-Weathersync'] and exports['Renewed-Weathersync'].setTime then
                exports['Renewed-Weathersync']:setTime(h, m)
            end
        end)
        TriggerClientEvent('souh4il_dev:client:syncTime', -1, h, m)
    end

    -- Broadcast to all players
    exports.qbx_core:Notify(-1, ("📢 ÉVÉNEMENT : %s — %s"):format(ActiveEvent.title, ActiveEvent.message), "inform", 12000)
    TriggerClientEvent('souh4il_dev:client:syncEvent', -1, ActiveEvent)

    Logger.Write("START_EVENT", source, nil, ActiveEvent, "SUCCESS")
    return { success = true, event = ActiveEvent }
end)

---Callback: Stop Event
lib.callback.register('souh4il_dev:server:stopEvent', function(source)
    if not Permissions.IsOwner(source) and not Permissions.HasModulePermission(source, 'events') then
        return { success = false, error = "ACCESS_DENIED" }
    end

    if not ActiveEvent then
        return { success = false, error = "NO_ACTIVE_EVENT" }
    end

    local oldTitle = ActiveEvent.title
    ActiveEvent = nil

    TriggerClientEvent('souh4il_dev:client:syncEvent', -1, nil)
    exports.qbx_core:Notify(-1, ("📢 L'événement '%s' est maintenant terminé !"):format(oldTitle), "inform", 8000)

    Logger.Write("STOP_EVENT", source, nil, { title = oldTitle }, "SUCCESS")
    return { success = true }
end)

---Callback: Get Event State
lib.callback.register('souh4il_dev:server:getEventState', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_event_state')
    if not allowed then return { success = false, error = reason } end

    return { success = true, activeEvent = ActiveEvent }
end)

---Callback: Server-Side Spawn Vehicle Direct (Fallback for custom addons & reliable OneSync sync)
lib.callback.register('souh4il_dev:server:spawnVehicleDirect', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'vehicle_action')
    if not allowed then return { success = false, error = reason } end

    -- [SOUH4IL-DEV] Granular permission enforced by CALLBACK_MODULES wrapper

    local model = tostring(data and data.model or ''):lower()
    if #model == 0 then return { success = false, error = "INVALID_MODEL" } end

    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return { success = false, error = "PLAYER_PED_NOT_FOUND" } end

    local currentVeh = GetVehiclePedIsIn(ped, false)
    if currentVeh and currentVeh ~= 0 then
        DeleteEntity(currentVeh)
    end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    local spawnedVeh = nil
    pcall(function()
        if exports.qbx_core and exports.qbx_core.SpawnVehicle then
            local _, v = exports.qbx_core:SpawnVehicle(source, model, vec4(coords.x, coords.y, coords.z, heading), true)
            spawnedVeh = v
        end
    end)

    if not spawnedVeh or not DoesEntityExist(spawnedVeh) then
        -- Native fallback with server setter
        local hash = joaat(model)
        local veh = CreateVehicleServerSetter(hash, "automobile", coords.x, coords.y, coords.z, heading)
        if DoesEntityExist(veh) then
            spawnedVeh = veh
            TaskWarpPedIntoVehicle(ped, veh, -1)
        end
    end

    if spawnedVeh and DoesEntityExist(spawnedVeh) then
        local netId = NetworkGetNetworkIdFromEntity(spawnedVeh)
        pcall(function() exports.qbx_vehiclekeys:GiveKeys(source, spawnedVeh) end)
        Logger.Write("SPAWN_VEHICLE", source, nil, { model = model, netId = netId }, "SUCCESS")
        return { success = true, netId = netId }
    end

    return { success = false, error = "FAILED_TO_CREATE_VEHICLE" }
end)

-- =========================================================================
-- SERVER-SIDE GOD POWERS ENFORCEMENT
-- Periodically checks if online staff have god_powers permission.
-- If not, forces all powers off to prevent unauthorized client-side toggling.
-- =========================================================================
CreateThread(function()
    while true do
        Wait(30000) -- Check every 30 seconds
        for _, srcStr in ipairs(GetPlayers()) do
            local src = tonumber(srcStr)
            if src and not Permissions.IsOwner(src) then
                local lic = Identifiers.GetLicense(src)
                -- Only inspect registered staff members to enforce permissions without spamming ordinary players
                if lic and Permissions.StaffCache[lic] then
                    local hasGodPowers = Permissions.StaffCache[lic].permissions and Permissions.StaffCache[lic].permissions.god_powers == true
                    if not hasGodPowers then
                        TriggerClientEvent('souh4il_dev:client:forceDisablePowers', src)
                    end
                end
            end
        end
    end
end)

-- Clean shutdown handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    lib.print.info(("^3%s — Resource stopped cleanly.^0"):format(SharedConfig.PanelName))
end)

lib.print.info(("^2%s — Online and ready for Chicago Roleplay.^0"):format(SharedConfig.PanelName))
