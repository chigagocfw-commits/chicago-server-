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
    local hasAccess = Permissions.CanExecute(source, PermissionsConfig.ACES.ACCESS)

    -- Log the status check
    Logger.Write("SECURITY_STATUS_QUERY", source, nil, { role = role, isOwner = isOwner }, "SUCCESS")

    return {
        success = true,
        role = role,
        isOwner = isOwner,
        hasAccess = hasAccess or isOwner,
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
    end

    if not Permissions.CanExecute(src, PermissionsConfig.ACES.ADMIN) and not Permissions.IsOwner(src) then
        return
    end

    if weatherType and type(weatherType) == 'string' then
        GlobalState.weather = {
            weather = weatherType:upper(),
            time = 9999999999
        }
        Logger.Write("SET_WEATHER", src, nil, { weather = weatherType:upper() }, "SUCCESS")
    end
end)

---Callback 5: Get Online Players
lib.callback.register('souh4il_dev:server:getOnlinePlayers', function(source)
    local allowed, reason = Security.CheckRateLimit(source, 'get_players')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.ACCESS) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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
                end
            end

            table.insert(players, {
                id = srcNum,
                name = pName,
                charName = charName,
                citizenid = citizenid,
                ping = pPing,
                job = jobLabel,
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

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.ADMIN) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.MODERATOR) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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

---Callback 8: Teleport Action (Goto / Bring)
lib.callback.register('souh4il_dev:server:teleportAction', function(source, action, targetId)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.ADMIN) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    local srcPed = GetPlayerPed(source)
    local tgtPed = GetPlayerPed(target)

    if action == 'goto' then
        local coords = GetEntityCoords(tgtPed)
        SetEntityCoords(srcPed, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        Logger.Write("TELEPORT_GOTO", source, target, { coords = coords }, "SUCCESS")
        return { success = true, action = 'goto' }
    elseif action == 'bring' then
        local coords = GetEntityCoords(srcPed)
        SetEntityCoords(tgtPed, coords.x, coords.y, coords.z + 1.0, false, false, false, false)
        Logger.Write("TELEPORT_BRING", source, target, { coords = coords }, "SUCCESS")
        return { success = true, action = 'bring' }
    end

    return { success = false, error = "UNKNOWN_TELEPORT_ACTION" }
end)

---Callback 9: Freeze Player
lib.callback.register('souh4il_dev:server:freezePlayer', function(source, targetId, state)
    local allowed, reason = Security.CheckRateLimit(source, 'player_action')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.MODERATOR) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

    local target = tonumber(targetId)
    if not target or not DoesPlayerExist(tostring(target)) then
        return { success = false, error = "TARGET_NOT_ONLINE" }
    end

    FreezeEntityPosition(GetPlayerPed(target), state == true)
    Logger.Write("FREEZE_PLAYER", source, target, { state = state }, "SUCCESS")
    return { success = true, frozen = state }
end)

---Callback 10: Give Item (Integrated with ox_inventory)
lib.callback.register('souh4il_dev:server:giveItem', function(source, data)
    local allowed, reason = Security.CheckRateLimit(source, 'give_item')
    if not allowed then return { success = false, error = reason } end

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.DEVELOPER) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.DEVELOPER) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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

    if not Permissions.CanExecute(source, PermissionsConfig.ACES.ACCESS) and not Permissions.IsOwner(source) then
        return { success = false, error = "ACCESS_DENIED" }
    end

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

-- Clean shutdown handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    lib.print.info(("^3%s — Resource stopped cleanly.^0"):format(SharedConfig.PanelName))
end)

lib.print.info(("^2%s — Online and ready for Chicago Roleplay.^0"):format(SharedConfig.PanelName))
