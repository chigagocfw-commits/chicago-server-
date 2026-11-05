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

    MySQL.query([[
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

    MySQL.query([[CREATE TABLE IF NOT EXISTS `souh4il_dev_logs_archive` LIKE `souh4il_dev_logs`;]])

    MySQL.query([[
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

    lib.print.info(("^2%s — Database tables verified.^0"):format(SharedConfig.PanelName))
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

---NetEvent: Execute Personal Quick Actions (Revive, Heal)
RegisterNetEvent('souh4il_dev:server:executeQuickAction', function(actionType)
    local src = source
    if not Permissions.CanExecute(src, PermissionsConfig.ACES.ACCESS) and not Permissions.IsOwner(src) then
        return
    end

    if actionType == 'revive' then
        if GetResourceState('qbx_medical') == 'started' then
            exports.qbx_medical:Revive(src)
            Logger.Write("QUICK_ACTION_REVIVE", src, src, { type = "self_revive" }, "SUCCESS")
        end
    elseif actionType == 'heal' then
        if GetResourceState('qbx_medical') == 'started' then
            exports.qbx_medical:Heal(src)
            Logger.Write("QUICK_ACTION_HEAL", src, src, { type = "self_heal" }, "SUCCESS")
        end
    end
end)

---NetEvent: Set Weather
RegisterNetEvent('souh4il_dev:server:setWeather', function(weatherType)
    local src = source
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

-- Clean shutdown handler
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= cache.resource then return end
    lib.print.info(("^3%s — Resource stopped cleanly.^0"):format(SharedConfig.PanelName))
end)

lib.print.info(("^2%s — Online and ready for Chicago Roleplay.^0"):format(SharedConfig.PanelName))
