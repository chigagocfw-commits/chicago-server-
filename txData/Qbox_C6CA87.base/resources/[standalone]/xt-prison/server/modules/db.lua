local qb = (GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started')
local esx = (GetResourceState('es_extended') == 'started')
local ox = (GetResourceState('ox_core') == 'started')
local nd = lib.checkDependency('ND_Core', '2.0.0')

local db = {
    table = qb and 'players' or esx and 'users' or nd and 'nd_characters' or ox and 'characters',
    identifier = qb and 'citizenid' or esx and 'identifier' or nd and 'charid' or ox and 'charid',
}

local requiredSchema = {
    xt_prison = { 'identifier', 'jailtime' },
    xt_prison_items = { 'owner', 'data' }
}

-- Safe Read-Only Schema Verification (Zero DDL on startup)
local function verifyPrisonSchema()
    local missing = {}

    local rows = MySQL.query.await([[
        SELECT TABLE_NAME, COLUMN_NAME
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME IN ('xt_prison', 'xt_prison_items')
    ]])

    local existingSchema = {}
    for _, row in ipairs(rows or {}) do
        local tbl = row.TABLE_NAME
        local col = row.COLUMN_NAME
        if not existingSchema[tbl] then existingSchema[tbl] = {} end
        existingSchema[tbl][col] = true
    end

    for tbl, requiredCols in pairs(requiredSchema) do
        if not existingSchema[tbl] then
            table.insert(missing, ("Missing table: %s"):format(tbl))
        else
            for _, col in ipairs(requiredCols) do
                if not existingSchema[tbl][col] then
                    table.insert(missing, ("Missing column: %s.%s"):format(tbl, col))
                end
            end
        end
    end

    -- Check legacy jailtime column in player table
    local legacyCount = MySQL.scalar.await([[
        SELECT COUNT(COLUMN_NAME)
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = 'jailtime'
    ]], { db.table })

    if (tonumber(legacyCount) or 0) > 0 then
        lib.print.warn(('Legacy jailtime column detected in %s. Please run DBA migration to migrate and drop it.'):format(db.table))
    end

    return #missing == 0, missing
end

CreateThread(function()
    local ok, valid, missing = pcall(verifyPrisonSchema)
    if not ok then
        lib.print.error(('Failed to query prison schema verification: %s'):format(tostring(valid)))
    elseif not valid or #missing > 0 then
        lib.print.error('xt-prison schema verification failed! Missing schema elements:')
        for _, item in ipairs(missing) do
            lib.print.error(('  - %s'):format(item))
        end
        lib.print.error('Please import prison schema under DBA credentials.')
    else
        lib.print.info('Prison database schema verified successfully (xt_prison and xt_prison_items present).')
    end
end)

return {
    UPDATE_JAILTIME = 'INSERT INTO xt_prison (identifier, jailtime) VALUES (?, ?) ON DUPLICATE KEY UPDATE jailtime = VALUES(jailtime)',
    LOAD_JAILTIME = 'SELECT `jailtime` FROM xt_prison WHERE `identifier` = ?',

    GET_ITEMS = 'SELECT data FROM xt_prison_items WHERE owner = ?',
    CONFISCATE_ITEMS = 'INSERT INTO xt_prison_items (owner, data) VALUES (?, ?)',
    UPDATE_CONFISCATED_ITEMS = 'UPDATE xt_prison_items SET data = ? WHERE owner = ? LIMIT 1',
    CLEAR_CONFISCATED_ITEMS = 'DELETE FROM xt_prison_items WHERE owner = ?'
}
