-- SOUH4IL-DEV — Append-Only Audit Logger
-- Implements SHA-256 hash chaining and fail-closed persistence

local Identifiers = require 'server.identifiers'
local Logger = {}

local GENESIS_ROOT_HASH = "0000000000000000000000000000000000000000000000000000000000000000"
local lastKnownHash = nil

---Fetches the most recent hash from the active table or archive
---@return string lastHash
local function GetLatestHash()
    if lastKnownHash then
        return lastKnownHash
    end

    local row = MySQL.single.await('SELECT hash FROM souh4il_dev_logs ORDER BY id DESC LIMIT 1')
    if row and row.hash then
        lastKnownHash = row.hash
        return lastKnownHash
    end

    -- Check archive if active table is empty
    local arcRow = MySQL.single.await('SELECT hash FROM souh4il_dev_logs_archive ORDER BY id DESC LIMIT 1')
    if arcRow and arcRow.hash then
        lastKnownHash = arcRow.hash
        return lastKnownHash
    end

    lastKnownHash = GENESIS_ROOT_HASH
    return lastKnownHash
end

---Asynchronously writes a security decision log into souh4il_dev_logs
---@param action string
---@param executorSource number
---@param targetSource? number
---@param details? table
---@param status? 'SUCCESS' | 'REJECTED' | 'INTRUSION_ALERT'
---@return boolean success, string? errOrId
function Logger.Write(action, executorSource, targetSource, details, status)
    local prevHash = GetLatestHash()
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local statusVal = status or 'SUCCESS'
    local detailsJson = json.encode(details or {})

    local execName = "SYSTEM"
    local execLic = "SYSTEM"
    if executorSource and executorSource > 0 and DoesPlayerExist(tostring(executorSource)) then
        execName = GetPlayerName(tostring(executorSource)) or "UNKNOWN"
        execLic = Identifiers.GetLicense(executorSource) or "UNKNOWN"
    end

    local targetName = nil
    local targetLic = nil
    if targetSource and targetSource > 0 and DoesPlayerExist(tostring(targetSource)) then
        targetName = GetPlayerName(tostring(targetSource))
        targetLic = Identifiers.GetLicense(targetSource)
    end

    -- Canonical deterministic payload string for SHA-256 hashing
    -- Format: prevHash|timestamp|action|execLic|targetLic|detailsJson
    local canonicalStr = string.format("%s|%s|%s|%s|%s|%s",
        prevHash, timestamp, action, execLic, targetLic or "NONE", detailsJson
    )

    -- Insert record computing SHA2(canonicalStr, 256) inside MariaDB
    local insertQuery = [[
        INSERT INTO souh4il_dev_logs 
        (timestamp, action, executor_source, executor_name, executor_license, 
         target_source, target_name, target_license, details, status, previous_hash, hash)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, SHA2(?, 256))
    ]]

    local res = MySQL.insert.await(insertQuery, {
        timestamp, action, executorSource, execName, execLic,
        targetSource, targetName, targetLic, detailsJson, statusVal, prevHash, canonicalStr
    })

    if not res or res <= 0 then
        -- Fail-closed emergency console fallback
        lib.print.error(('SOUH4IL-DEV LOGGING FAILED: Action=%s, Executor=%s [%s]'):format(action, execName, execLic))
        return false, "SECURITY_AUDIT_UNAVAILABLE"
    end

    -- Update in-memory hash pointer
    local insertedRow = MySQL.single.await('SELECT hash FROM souh4il_dev_logs WHERE id = ?', { res })
    if insertedRow and insertedRow.hash then
        lastKnownHash = insertedRow.hash
    end

    return true, tostring(res)
end

---Reconciles and migrates records older than retention window into archive
---@param retentionDays? number
---@return boolean success
function Logger.ReconcileAndArchive(retentionDays)
    local days = retentionDays or 90
    local cutoff = os.date('%Y-%m-%d %H:%M:%S', os.time() - (days * 86400))

    -- 1. Pre-Transaction Qualification: Count candidate rows
    local expectedCount = MySQL.scalar.await(
        'SELECT COUNT(*) FROM souh4il_dev_logs WHERE timestamp < ?', { cutoff }
    )
    if not expectedCount or expectedCount == 0 then
        return true -- No rows qualify
    end

    -- 2. Execute migration with row count assertion
    local insertRes = MySQL.query.await([[
        INSERT INTO souh4il_dev_logs_archive (id, timestamp, action, executor_source, executor_name, 
            executor_license, target_source, target_name, target_license, details, status, previous_hash, hash)
        SELECT id, timestamp, action, executor_source, executor_name, 
            executor_license, target_source, target_name, target_license, details, status, previous_hash, hash
        FROM souh4il_dev_logs
        WHERE timestamp < ?
    ]], { cutoff })

    local insertedCount = insertRes and insertRes.affectedRows or 0
    if insertedCount ~= expectedCount then
        lib.print.error(('ARCHIVE_RECONCILIATION_ABORT: Expected %d rows to copy, but copied %d. Rolling back.')
            :format(expectedCount, insertedCount))
        -- Cleanup orphaned copies from archive if partial copy occurred
        MySQL.query.await('DELETE FROM souh4il_dev_logs_archive WHERE timestamp < ?', { cutoff })
        return false
    end

    -- 3. Only delete from active table after copy count is 100% confirmed
    local deleteRes = MySQL.query.await(
        'DELETE FROM souh4il_dev_logs WHERE timestamp < ?', { cutoff }
    )
    local deletedCount = deleteRes and deleteRes.affectedRows or 0

    if deletedCount ~= expectedCount then
        lib.print.error(('ARCHIVE_CRITICAL_DESYNC: Copied %d rows, but deleted %d rows.')
            :format(insertedCount, deletedCount))
        return false
    end

    lib.print.info(('ARCHIVE_SUCCESS: Reconciled and migrated %d rows cleanly.'):format(expectedCount))
    return true
end

return Logger

