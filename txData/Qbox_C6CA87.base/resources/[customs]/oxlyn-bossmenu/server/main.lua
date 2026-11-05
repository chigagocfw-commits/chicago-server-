

--------------------------------------------------------------------
-- oxlyn-bossmenu | main server script (cleaned)
--
-- Contents:
--   * helpers (translation, money formatting, SQL wrappers)
--   * company / boss resolution from Config.Companies
--   * rank cache + ESX/QB runtime job patching
--   * per-company settings, accounts, timesheet, transaction ledger
--   * server callbacks used by the NUI (hire, fire, deposit, ...)
--   * public exports (AddCompanyFunds, StartDuty, ...)
--   * admin command to strip a boss rank
--
-- Callback signature used throughout:  handler(source, cb, ...)
--------------------------------------------------------------------

local RESOURCE_TAG = "oxlyn-bossmenu"

--------------------------------------------------------------------
-- Translation / formatting helpers
--------------------------------------------------------------------

-- Uses the global L() from locale.lua if present; falls back to vars._d / key.
local function tr(key, vars)
    local translate = _G.L or rawget(_G, "L")
    if type(translate) == "function" then
        return translate(key, vars)
    end
    if vars and vars._d then
        return vars._d
    end
    return key
end

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function trimEnd(s)
    return (s:gsub("%s+$", ""))
end

-- Formats an amount using Config.Currency (symbol, position, space, thousands).
local function formatMoney(amount)
    local cfg = (Config and Config.Currency) or {}

    local symbol = "€"
    if cfg.symbol ~= nil and cfg.symbol ~= "" then
        symbol = tostring(cfg.symbol)
    end

    local position  = (cfg.position == "before") and "before" or "after"
    local space     = (cfg.space == true) and " " or ""
    local thousands = (cfg.thousands ~= nil) and tostring(cfg.thousands) or " "

    local number = tonumber(amount) or 0
    local text = tostring(math.floor(math.abs(number) + 0.5))

    if thousands ~= "" then
        while true do
            local replaced
            text, replaced = text:gsub("^(%d+)(%d%d%d)", "%1" .. thousands .. "%2")
            if replaced == 0 then break end
        end
    end

    local result
    if position == "before" then
        result = symbol .. space .. text
    else
        result = text .. space .. symbol
    end

    if number < 0 then
        result = "-" .. result
    end
    return result
end

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

--------------------------------------------------------------------
-- Callback registration
-- Callbacks are queued until Framework is ready (30s max), then
-- registered via Framework.RegisterCallback.
--------------------------------------------------------------------
local registeredCount   = 0
local expectedCount     = nil
local frameworkReady    = false
local frameworkTimedOut = false
local pendingCallbacks  = {}

local function registerNow(name, handler)
    Framework.RegisterCallback(name, function(src, cb, ...)
        local ok, err = pcall(handler, src, cb, ...)
        if not ok then
            print(("^1[%s] callback \"%s\" errored: %s^7"):format(RESOURCE_TAG, name, tostring(err)))
            pcall(cb, nil)
        end
    end)

    registeredCount = registeredCount + 1
    if expectedCount and registeredCount == expectedCount then
        print(("^2[%s] %d callbacks registered — server ready.^7"):format(RESOURCE_TAG, registeredCount))
    end
end

local function warnCallbackTimeout(name)
    print(("^1[%s] RegisterCallback timeout (30s) — %s was NOT registered. /bossmenu will not work.^7")
        :format(RESOURCE_TAG, name))
end

CreateThread(function()
    local waited = 0
    while not (Framework and Framework.ready) and waited < 30000 do
        Wait(100)
        waited = waited + 100
    end

    if not (Framework and Framework.ready) then
        frameworkTimedOut = true
        for i = 1, #pendingCallbacks do
            warnCallbackTimeout(pendingCallbacks[i][1])
        end
        pendingCallbacks = {}
        return
    end

    frameworkReady = true
    expectedCount = #pendingCallbacks
    for i = 1, #pendingCallbacks do
        registerNow(pendingCallbacks[i][1], pendingCallbacks[i][2])
    end
    pendingCallbacks = {}
end)

local function registerCallback(name, handler)
    if frameworkReady then
        return registerNow(name, handler)
    end
    if frameworkTimedOut then
        return warnCallbackTimeout(name)
    end
    pendingCallbacks[#pendingCallbacks + 1] = { name, handler }
end

--------------------------------------------------------------------
-- SQL wrappers (oxmysql)
--------------------------------------------------------------------
local function isDatabaseConfirmedReady()
    if type(Framework) ~= "table" then return false end
    if type(Framework.IsDatabaseReady) ~= "function" then return false end
    local ok, ready = pcall(Framework.IsDatabaseReady)
    return ok and ready == true
end

local function dbFetchAsync(query, params, cb)
    if not isDatabaseConfirmedReady() then
        if cb then cb({}) end
        return
    end
    exports.oxmysql:fetch(query, params or {}, function(rows)
        cb(rows or {})
    end)
end

local function dbRows(query, params)
    if not isDatabaseConfirmedReady() then return {} end
    return exports.oxmysql:executeSync(query, params or {}) or {}
end

local function dbScalar(query, params)
    if not isDatabaseConfirmedReady() then return nil end
    return exports.oxmysql:scalarSync(query, params or {})
end

-- Runs a write query, returns affected row count.
local function dbExecute(query, params)
    if not isDatabaseConfirmedReady() then return 0 end
    local result = exports.oxmysql:executeSync(query, params or {})

    if type(result) == "table" then
        return tonumber(result.affectedRows) or tonumber(result.changes) or 0
    end
    return tonumber(result) or 0
end

-- Runs an insert query, returns numeric insertId or nil on failure
local function dbInsert(query, params)
    if not isDatabaseConfirmedReady() then return nil end
    local ok, result = pcall(function()
        return exports.oxmysql:executeSync(query, params or {})
    end)
    if not ok or not result then return nil end

    if type(result) == "table" and result.insertId then
        local id = tonumber(result.insertId)
        if id and id > 0 then return id end
    end
    if type(result) == "number" and result > 0 then
        return result
    end
    return nil
end

local function isQbFramework()
    return Framework and Framework.type == "qbcore"
end

--------------------------------------------------------------------
-- Framework-specific player/job storage (online + offline)
--------------------------------------------------------------------

-- Every player of `job` stored in the DB (online or not).
local function fetchEmployeesFromDb(job, cb)
    if isQbFramework() then
        dbFetchAsync(
            "SELECT citizenid AS identifier, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))  AS lastname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(job, '$.name'))           AS job, "
            .. "CAST(JSON_EXTRACT(job, '$.grade.level') AS UNSIGNED) AS job_grade "
            .. "FROM players WHERE JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ?",
            { job },
            function(rows) cb(rows or {}) end
        )
    else
        dbFetchAsync(
            "SELECT identifier, firstname, lastname, job, job_grade FROM users WHERE job = ?",
            { job },
            function(rows) cb(rows or {}) end
        )
    end
end

-- One DB row (firstname, lastname, job, job_grade) for an identifier.
local function fetchPlayerRow(identifier)
    if isQbFramework() then
        local rows = dbRows(
            "SELECT JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))  AS lastname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(job, '$.name'))           AS job, "
            .. "CAST(JSON_EXTRACT(job, '$.grade.level') AS UNSIGNED) AS job_grade "
            .. "FROM players WHERE citizenid = ? LIMIT 1",
            { identifier }
        )
        return rows and rows[1] or nil
    else
        local rows = dbRows(
            "SELECT firstname, lastname, job, job_grade FROM users WHERE identifier = ? LIMIT 1",
            { identifier }
        )
        return rows and rows[1] or nil
    end
end

-- Builds the QBCore `job` JSON object for a job + grade (offline writes).
local function buildQbJobData(jobName, grade)
    grade = tonumber(grade) or 0

    local jobs = Framework and Framework.core
        and Framework.core.Shared and Framework.core.Shared.Jobs or nil
    local jobDef = jobs and jobs[jobName] or nil

    local gradeDef = nil
    if jobDef and jobDef.grades then
        gradeDef = jobDef.grades[tostring(grade)] or jobDef.grades[grade]
    end

    local onDuty = true
    if jobDef and jobDef.defaultDuty ~= nil then
        onDuty = jobDef.defaultDuty == true
    end

    return {
        name    = jobName,
        label   = (jobDef and jobDef.label) or jobName,
        payment = (gradeDef and tonumber(gradeDef.payment)) or 0,
        onduty  = onDuty,
        isboss  = gradeDef ~= nil and gradeDef.isboss == true,
        grade   = {
            name  = (gradeDef and gradeDef.name) or tostring(grade),
            level = grade,
        },
    }
end

-- Change the job of an offline player directly in the DB.
local function setJobOffline(identifier, jobName, grade)
    if isQbFramework() then
        return dbExecute(
            "UPDATE players SET job = ? WHERE citizenid = ?",
            { json.encode(buildQbJobData(jobName, grade)), identifier }
        )
    else
        return dbExecute(
            "UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?",
            { jobName, tonumber(grade) or 0, identifier }
        )
    end
end

local function countMembersAtGrade(jobName, grade)
    if isQbFramework() then
        return dbScalar(
            "SELECT COUNT(*) FROM players WHERE "
            .. "JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) = ? AND "
            .. "CAST(JSON_EXTRACT(job, '$.grade.level') AS UNSIGNED) = ?",
            { jobName, tonumber(grade) or 0 }
        )
    else
        return dbScalar(
            "SELECT COUNT(*) FROM users WHERE job = ? AND job_grade = ?",
            { jobName, tonumber(grade) or 0 }
        )
    end
end

local function getJobNameOffline(identifier)
    if isQbFramework() then
        return dbScalar(
            "SELECT JSON_UNQUOTE(JSON_EXTRACT(job, '$.name')) FROM players WHERE citizenid = ?",
            { identifier }
        )
    else
        return dbScalar("SELECT job FROM users WHERE identifier = ?", { identifier })
    end
end

local function addBankMoneyOffline(identifier, amount)
    if isQbFramework() then
        return dbExecute(
            "UPDATE players SET money = JSON_SET(money, '$.bank', "
            .. "CAST(JSON_VALUE(money, '$.bank') AS UNSIGNED) + ?) WHERE citizenid = ?",
            { tonumber(amount) or 0, identifier }
        )
    else
        return dbExecute(
            "UPDATE users SET accounts = JSON_SET(accounts, \"$.bank\", JSON_VALUE(accounts, \"$.bank\") + ?) WHERE identifier = ?",
            { tonumber(amount) or 0, identifier }
        )
    end
end

--------------------------------------------------------------------
-- ESX runtime job-grade cache patching (so edits apply without restart)
-- patch == nil            -> remove the grade
-- patch.create == true    -> add a grade
-- otherwise               -> update salary / label of an existing grade
--------------------------------------------------------------------
local function patchFrameworkJobCache(jobName, grade, patch)
    if not (Framework and Framework.core) then return end

    if Framework.type == "esx" then
        local jobs = Framework.core.GetJobs and Framework.core.GetJobs() or nil
        if not (jobs and jobs[jobName]) then return end

        jobs[jobName].grades = jobs[jobName].grades or {}
        local grades = jobs[jobName].grades
        local key = tostring(grade)

        if patch == nil then
            grades[key] = nil
        elseif patch.create then
            grades[key] = {
                grade  = grade,
                name   = patch.name,
                label  = patch.label,
                salary = patch.salary,
            }
        else
            local entry = grades[key]
            if entry then
                if patch.salary ~= nil then entry.salary = patch.salary end
                if patch.label  ~= nil then entry.label  = patch.label  end
            end
        end

    elseif Framework.type == "qbcore" then
        local fns = Framework.core.Functions
        if fns and fns.RefreshJobs then
            fns.RefreshJobs()
        end
    end
end

--------------------------------------------------------------------
-- Companies (Config.Companies) and boss detection
--------------------------------------------------------------------
local companiesByJob   = nil -- job -> company config
local bossGradesByJob  = nil -- job -> { [grade] = true }

local function buildCompanyIndex()
    companiesByJob  = {}
    bossGradesByJob = {}

    for _, company in ipairs(Config.Companies or {}) do
        if company.job and companiesByJob[company.job] == nil then
            companiesByJob[company.job] = company

            local bossSet = {}
            for _, grade in ipairs(company.bossGrades or {}) do
                local n = tonumber(grade)
                if n then bossSet[n] = true end
            end
            bossGradesByJob[company.job] = bossSet
        end
    end
end

local function getCompany(jobName)
    if not jobName then return nil end
    if not companiesByJob then
        buildCompanyIndex()
    end
    return companiesByJob[jobName]
end

-- Company the player is a BOSS of (job + boss grade), or nil.
local function getBossCompany(player)
    if not (player and player.getJob) then return nil end

    local job = player.getJob()
    if not job then return nil end

    local company = getCompany(job.name)
    if not company then return nil end

    local bossSet = bossGradesByJob[job.name]
    if bossSet and bossSet[tonumber(job.grade) or 0] then
        return company
    end
    return nil
end

local function isBoss(player)
    return getBossCompany(player) ~= nil
end

-- Config.AllowedGrades: legacy list of job / grade names allowed to open the menu.
local function isGradeAllowedByConfig(player)
    if not (Config.AllowedGrades and #Config.AllowedGrades ~= 0) then
        return false
    end

    local job = player.getJob()
    local jobName   = (job and job.name) or ""
    local gradeName = (job and job.grade_name) or ""

    for _, allowed in ipairs(Config.AllowedGrades) do
        if allowed == jobName or allowed == gradeName then
            return true
        end
    end
    return false
end

--------------------------------------------------------------------
-- Rank cache (60s)
--------------------------------------------------------------------
local RANK_CACHE_TTL = 60000
local rankCache      = {}
local rankCacheTime  = {}

local function invalidateRankCache(jobName)
    if jobName then
        rankCache[jobName]     = nil
        rankCacheTime[jobName] = nil
    else
        rankCache     = {}
        rankCacheTime = {}
    end
end

local function sortRanksAscending(ranks)
    table.sort(ranks, function(a, b) return a.grade < b.grade end)
end

-- Loads a job's ranks from the framework: { name, label, grade, salary }[]
local function loadRanks(jobName)
    if not (Framework and Framework.ready) then
        return {}
    end

    ------------------------------------------------ ESX
    if Framework.type == "esx" then
        local rows = dbRows(
            "SELECT job_name, grade, name, label, salary FROM job_grades WHERE job_name = ? ORDER BY grade",
            { jobName }
        )

        if rows and #rows > 0 then
            local ranks = {}
            for _, row in ipairs(rows) do
                ranks[#ranks + 1] = {
                    name   = row.name,
                    label  = row.label or row.name,
                    grade  = tonumber(row.grade) or 0,
                    salary = tonumber(row.salary) or 0,
                }
            end
            return ranks
        end

        -- Fallback: in-memory ESX jobs
        local jobs = Framework.core and Framework.core.GetJobs and Framework.core.GetJobs() or nil
        if jobs and jobs[jobName] and jobs[jobName].grades then
            local ranks = {}
            for key, g in pairs(jobs[jobName].grades) do
                ranks[#ranks + 1] = {
                    name   = g.name,
                    label  = g.label or g.name,
                    grade  = tonumber(g.grade) or tonumber(key) or 0,
                    salary = tonumber(g.salary) or 0,
                }
            end
            sortRanksAscending(ranks)
            return ranks
        end

        return {}
    end

    ------------------------------------------------ QBCore / Qbox
    if Framework.type == "qbcore" then
        local jobs = nil
        if Framework.core and Framework.core.Shared and Framework.core.Shared.Jobs then
            jobs = Framework.core.Shared.Jobs
        end

        -- Qbox direct-exports mode: ask qbx_core for the jobs table
        if not (jobs and jobs[jobName]) then
            if Framework.core and Framework.core._qbx_direct then
                local res = Framework.core._resName or "qbx_core"

                local function tryExport(name, ...)
                    local ok, result = pcall(function(...)
                        return exports[res][name](exports[res], ...)
                    end, ...)
                    if ok and type(result) == "table" then
                        return result
                    end
                    return nil
                end

                jobs = tryExport("GetJobs") or jobs
                if not jobs then
                    jobs = tryExport("GetSharedData", "Jobs") or jobs
                    if not jobs then
                        jobs = tryExport("GetSharedData", "jobs") or jobs
                    end
                end
            end
        end

        local jobDef = jobs and jobs[jobName] or nil
        if jobDef and jobDef.grades then
            local ranks = {}
            for key, g in pairs(jobDef.grades) do
                ranks[#ranks + 1] = {
                    name   = g.name,
                    label  = g.name,
                    grade  = tonumber(key) or tonumber(g.level) or 0,
                    salary = tonumber(g.payment) or 0,
                }
            end
            sortRanksAscending(ranks)
            return ranks
        end
    end

    return {}
end

local function getRanksCached(jobName)
    if not jobName then return {} end

    local cachedAt = rankCacheTime[jobName]
    if cachedAt and (GetGameTimer() - cachedAt) < RANK_CACHE_TTL then
        local cached = rankCache[jobName]
        if cached then return cached end
    end

    local ranks = loadRanks(jobName)
    if ranks and #ranks > 0 then
        rankCache[jobName]     = ranks
        rankCacheTime[jobName] = GetGameTimer()
    end
    return ranks
end

--------------------------------------------------------------------
-- Society (company) money helpers
--------------------------------------------------------------------
local function getSocietyBalance(jobName, cb)
    Framework.GetSocietyMoney(jobName, cb)
end

-- delta >= 0 adds, delta < 0 removes
local function changeSocietyMoney(jobName, delta, cb)
    if delta >= 0 then
        Framework.AddSocietyMoney(jobName, delta, cb)
    else
        Framework.RemoveSocietyMoney(jobName, -delta, cb)
    end
end

--------------------------------------------------------------------
-- Name helpers
--------------------------------------------------------------------

-- "First Last" (trailing spaces trimmed) for an online player object.
local function getFirstLast(player)
    local first, last = "?", ""
    if player.get then
        first = player.get("firstName") or first
        last  = player.get("lastName") or ""
    elseif player.getName then
        first = player.getName()
    end
    return first, last
end

-- Display name; falls back to getName() or "Employee".
local function getDisplayName(player)
    local first = (player.get and player.get("firstName")) or ""
    local last  = (player.get and player.get("lastName")) or ""
    local full  = trim(first .. " " .. last)

    if full ~= "" then return full end
    return player.getName and player.getName() or nil
end

local function displayNameOrEmployee(player)
    return getDisplayName(player) or "Employee"
end

local function dbRowName(row)
    return trim((row.firstname or "") .. " " .. (row.lastname or ""))
end

--------------------------------------------------------------------
-- Employee listing (online + offline)
--------------------------------------------------------------------
local function listEmployees(jobName, cb)
    local list = {}
    local seen = {}

    for _, player in ipairs(Framework.GetExtendedPlayers()) do
        local job = player.getJob()
        if job.name == jobName then
            local first, last = getFirstLast(player)
            local identifier = player.getIdentifier()
            seen[identifier] = true

            list[#list + 1] = {
                identifier = identifier,
                source     = player.source,
                name       = trimEnd(first .. " " .. last),
                grade      = tonumber(job.grade) or 0,
                gradeLabel = job.grade_label or job.grade_name or "",
                online     = true,
            }
        end
    end

    fetchEmployeesFromDb(jobName, function(rows)
        for _, row in ipairs(rows or {}) do
            if not seen[row.identifier] then
                list[#list + 1] = {
                    identifier = row.identifier,
                    source     = nil,
                    name       = trimEnd((row.firstname or "") .. " " .. (row.lastname or "")),
                    grade      = tonumber(row.job_grade) or 0,
                    gradeLabel = "",
                    online     = false,
                }
            end
        end

        table.sort(list, function(a, b)
            if a.grade ~= b.grade then
                return a.grade > b.grade
            end
            return (a.name or "") < (b.name or "")
        end)

        cb(list)
    end)
end

--------------------------------------------------------------------
-- Database schema + ledger retention cleanup
--------------------------------------------------------------------
--------------------------------------------------------------------
-- Database schema verification (Read-Only Least-Privilege Gate)
--------------------------------------------------------------------
local SCHEMA_SPEC = {
    oxlyn_company_settings = {
        engine = "InnoDB",
        columns = {
            job_name = { "varchar" },
            settings = { "longtext", "text", "mediumtext" },
            updated_at = { "timestamp", "datetime" }
        },
        primaryKey = "job_name",
        indexes = {}
    },
    oxlyn_company_accounts = {
        engine = "InnoDB",
        columns = {
            job_name = { "varchar" },
            accounts = { "longtext", "text", "mediumtext" },
            updated_at = { "timestamp", "datetime" }
        },
        primaryKey = "job_name",
        indexes = {}
    },
    oxlyn_company_timesheet = {
        engine = "InnoDB",
        columns = {
            id = { "int", "bigint" },
            job_name = { "varchar" },
            identifier = { "varchar" },
            name = { "varchar" },
            grade = { "int", "tinyint", "smallint" },
            in_time = { "datetime", "timestamp" },
            out_time = { "datetime", "timestamp" },
            secs = { "int", "bigint" }
        },
        primaryKey = "id",
        indexes = { "idx_job_in", "idx_ident_in" }
    },
    oxlyn_company_transactions = {
        engine = "InnoDB",
        columns = {
            id = { "int", "bigint" },
            job_name = { "varchar" },
            type = { "varchar" },
            amount = { "bigint", "int" },
            method = { "varchar" },
            identifier = { "varchar" },
            name = { "varchar" },
            grade = { "int", "tinyint", "smallint" },
            target_identifier = { "varchar" },
            target_name = { "varchar" },
            note = { "varchar", "text" },
            origin = { "varchar" },
            balance_after = { "bigint", "int" },
            created_at = { "datetime", "timestamp" }
        },
        primaryKey = "id",
        indexes = { "idx_job_time", "idx_job_ident" }
    },
    management_funds = {
        engine = "InnoDB",
        columns = {
            id = { "int", "bigint" },
            job_name = { "varchar" },
            amount = { "int", "bigint" },
            type = { "enum", "varchar" }
        },
        primaryKey = "id",
        indexes = {}
    }
}

local function validateDatabaseSchema()
    local tablesList = {
        'oxlyn_company_settings',
        'oxlyn_company_accounts',
        'oxlyn_company_timesheet',
        'oxlyn_company_transactions',
        'management_funds'
    }

    local ok1, tablesResult = pcall(function()
        return exports.oxmysql:executeSync([[
            SELECT TABLE_NAME, ENGINE 
            FROM information_schema.TABLES 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME IN (?, ?, ?, ?, ?)
        ]], tablesList)
    end)

    if not ok1 or type(tablesResult) ~= "table" then
        Framework.schemaValidationStatus = "DATABASE_INSPECTION_FAILURE"
        print("^1[oxlyn-bossmenu] [CRITICAL ERROR] Failed to query information_schema.TABLES for schema validation.^0")
        return false
    end

    local tablesMap = {}
    for i = 1, #tablesResult do
        tablesMap[tablesResult[i].TABLE_NAME] = tablesResult[i].ENGINE
    end

    for tableName, spec in pairs(SCHEMA_SPEC) do
        if not tablesMap[tableName] then
            Framework.schemaValidationStatus = "TABLE_MISSING: " .. tableName
            print(("^1[oxlyn-bossmenu] [CRITICAL SCHEMA ERROR] Required table missing from database: %s^0"):format(tableName))
            print("^1[oxlyn-bossmenu] Database operations fail closed. Please ensure database migrations are run by an administrator.^0")
            return false
        end
    end

    local ok2, columnsResult = pcall(function()
        return exports.oxmysql:executeSync([[
            SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE 
            FROM information_schema.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME IN (?, ?, ?, ?, ?)
        ]], tablesList)
    end)

    if not ok2 or type(columnsResult) ~= "table" then
        Framework.schemaValidationStatus = "DATABASE_INSPECTION_FAILURE"
        print("^1[oxlyn-bossmenu] [CRITICAL ERROR] Failed to query information_schema.COLUMNS for schema validation.^0")
        return false
    end

    local columnsMap = {}
    for i = 1, #columnsResult do
        local r = columnsResult[i]
        if not columnsMap[r.TABLE_NAME] then columnsMap[r.TABLE_NAME] = {} end
        columnsMap[r.TABLE_NAME][r.COLUMN_NAME] = r.DATA_TYPE
    end

    for tableName, spec in pairs(SCHEMA_SPEC) do
        local tCols = columnsMap[tableName] or {}
        for colName, validTypes in pairs(spec.columns) do
            local actualType = tCols[colName]
            if not actualType then
                Framework.schemaValidationStatus = "COLUMN_MISSING: " .. tableName .. "." .. colName
                print(("^1[oxlyn-bossmenu] [CRITICAL SCHEMA ERROR] Required column missing: %s.%s^0"):format(tableName, colName))
                return false
            end
            local typeMatch = false
            for j = 1, #validTypes do
                if actualType == validTypes[j] then
                    typeMatch = true
                    break
                end
            end
            if not typeMatch then
                Framework.schemaValidationStatus = "INCOMPATIBLE_COLUMN_TYPE: " .. tableName .. "." .. colName .. " (" .. actualType .. ")"
                print(("^1[oxlyn-bossmenu] [CRITICAL SCHEMA ERROR] Incompatible type for %s.%s: found %s^0"):format(tableName, colName, actualType))
                return false
            end
        end
    end

    local ok3, indexesResult = pcall(function()
        return exports.oxmysql:executeSync([[
            SELECT TABLE_NAME, INDEX_NAME, COLUMN_NAME 
            FROM information_schema.STATISTICS 
            WHERE TABLE_SCHEMA = DATABASE() 
              AND TABLE_NAME IN (?, ?, ?, ?, ?)
        ]], tablesList)
    end)

    if not ok3 or type(indexesResult) ~= "table" then
        Framework.schemaValidationStatus = "DATABASE_INSPECTION_FAILURE"
        print("^1[oxlyn-bossmenu] [CRITICAL ERROR] Failed to query information_schema.STATISTICS for schema validation.^0")
        return false
    end

    local indexMap = {}
    for i = 1, #indexesResult do
        local r = indexesResult[i]
        if not indexMap[r.TABLE_NAME] then indexMap[r.TABLE_NAME] = {} end
        indexMap[r.TABLE_NAME][r.INDEX_NAME] = true
    end

    for tableName, spec in pairs(SCHEMA_SPEC) do
        local tIdx = indexMap[tableName] or {}
        if spec.primaryKey and not tIdx["PRIMARY"] then
            Framework.schemaValidationStatus = "MISSING_PRIMARY_KEY: " .. tableName
            print(("^1[oxlyn-bossmenu] [CRITICAL SCHEMA ERROR] Primary key missing on %s^0"):format(tableName))
            return false
        end
        for j = 1, #spec.indexes do
            local idxName = spec.indexes[j]
            if not tIdx[idxName] then
                Framework.schemaValidationStatus = "MISSING_INDEX: " .. tableName .. "." .. idxName
                print(("^1[oxlyn-bossmenu] [CRITICAL SCHEMA ERROR] Required index missing on %s: %s^0"):format(tableName, idxName))
                return false
            end
        end
    end

    Framework.schemaValidationStatus = "VALID"
    Framework.isSchemaValid = true
    print("^2[oxlyn-bossmenu] Database schema verified successfully (all 5 tables validated, least-privilege mode active).^0")
    return true
end

CreateThread(function()
    Wait(500)
    validateDatabaseSchema()
end)

--------------------------------------------------------------------
-- Per-company settings (allowedGrades / tabAccess), cached in memory
--------------------------------------------------------------------
local settingsCache     = {}
local settingsCacheTime = {}
local accountsCache     = {}
local accountsCacheTime = {}

local function emptySettings()
    return { allowedGrades = {}, tabAccess = {} }
end

local function loadSettings(jobName)
    local raw = dbScalar("SELECT settings FROM oxlyn_company_settings WHERE job_name = ?", { jobName })
    if not raw or raw == "" then
        return emptySettings()
    end

    local ok, decoded = pcall(json.decode, raw)
    if ok and type(decoded) == "table" then
        decoded.allowedGrades = decoded.allowedGrades or {}
        decoded.tabAccess     = decoded.tabAccess or {}
        return decoded
    end

    return emptySettings()
end

local function getSettings(jobName)
    if not jobName then
        return emptySettings()
    end

    if settingsCacheTime[jobName] ~= nil and settingsCache[jobName] then
        return settingsCache[jobName]
    end

    local settings = loadSettings(jobName)
    settingsCache[jobName]     = settings
    settingsCacheTime[jobName] = GetGameTimer()
    return settings
end

local function saveSettings(jobName, settings)
    if not isDatabaseConfirmedReady() then
        return false
    end

    settings = settings or {}
    settings.allowedGrades = settings.allowedGrades or {}
    settings.tabAccess     = settings.tabAccess or {}

    local ok, result = pcall(function()
        return exports.oxmysql:executeSync(
            "INSERT INTO oxlyn_company_settings (job_name, settings) VALUES (?, ?) "
            .. "ON DUPLICATE KEY UPDATE settings = VALUES(settings)",
            { jobName, json.encode(settings) }
        )
    end)

    if not ok or result == nil then
        return false
    end

    settingsCache[jobName]     = settings
    settingsCacheTime[jobName] = GetGameTimer()
    return true
end

-- Non-boss employee whose grade was granted access in company settings
local function hasSettingsAccess(player)
    local job = player.getJob()
    if not job then return false end

    local company = getCompany(job.name)
    if not company then return false end

    local settings = getSettings(job.name)
    local gradeKey = tostring(tonumber(job.grade) or 0)

    return settings.allowedGrades ~= nil and settings.allowedGrades[gradeKey] == true
end

--------------------------------------------------------------------
-- Company bank accounts (stored as JSON per company)
--------------------------------------------------------------------
local function getAccounts(jobName)
    if not jobName then return {} end

    if accountsCacheTime[jobName] ~= nil and accountsCache[jobName] then
        return accountsCache[jobName]
    end

    local raw = dbScalar("SELECT accounts FROM oxlyn_company_accounts WHERE job_name = ?", { jobName })
    local accounts = {}

    if raw and raw ~= "" then
        local ok, decoded = pcall(json.decode, raw)
        if ok and type(decoded) == "table" then
            accounts = decoded
        end
    end

    accountsCache[jobName]     = accounts
    accountsCacheTime[jobName] = GetGameTimer()
    return accounts
end

local function saveAccounts(jobName, accounts)
    if not isDatabaseConfirmedReady() then
        return false
    end

    accounts = accounts or {}

    local ok, result = pcall(function()
        return exports.oxmysql:executeSync(
            "INSERT INTO oxlyn_company_accounts (job_name, accounts) VALUES (?, ?) "
            .. "ON DUPLICATE KEY UPDATE accounts = VALUES(accounts)",
            { jobName, json.encode(accounts) }
        )
    end)

    if not ok or result == nil then
        return false
    end

    accountsCache[jobName]     = accounts
    accountsCacheTime[jobName] = GetGameTimer()
    return true
end

-- The company a player may administer (boss, or granted via settings).
local function getAccessCompany(player)
    if not player then return nil end

    local job = player.getJob()
    local company = getBossCompany(player)
    if not company and job then
        company = getCompany(job.name)
    end
    if not company then return nil end

    if not isBoss(player) and not hasSettingsAccess(player) then
        return nil
    end
    return company
end

--------------------------------------------------------------------
-- Showcase (demo) mode passthrough
--------------------------------------------------------------------
local function inShowcase()
    return Showcase and Showcase.active()
end

--------------------------------------------------------------------
-- Callbacks: accounts
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:createAccount", function(src, cb, name, color, password, isMaster)
    if inShowcase() then return cb(nil) end

    local player = Framework.GetPlayerFromId(src)
    local company = getAccessCompany(player)
    if not company then return cb(nil) end

    name = trim(tostring(name or "")):sub(1, 20)
    if name == "" then return cb(nil) end

    password = tostring(password or ""):sub(1, 32)

    -- If a master account exists, no other accounts can be created
    local accounts = {}
    for _, account in ipairs(getAccounts(company.job)) do
        if account.isMaster then
            return cb(nil)
        end
        accounts[#accounts + 1] = account
    end

    local newAccount = {
        id        = ("a_%d_%d"):format(os.time(), math.random(1000, 9999)),
        name      = name,
        color     = tostring(color or ""),
        password  = password,
        isMaster  = isMaster == true,
        createdBy = player.getIdentifier(),
    }

    if newAccount.isMaster then
        if not isBoss(player) then return cb(nil) end
        accounts = { newAccount }
    else
        accounts[#accounts + 1] = newAccount
    end

    local saved = saveAccounts(company.job, accounts)
    if not saved then return cb(nil) end
    cb(accounts)
end)

registerCallback("oxlyn-bossmenu:deleteAccount", function(src, cb, accountId)
    if inShowcase() then return cb(nil) end

    local player = Framework.GetPlayerFromId(src)
    local company = getAccessCompany(player)
    if not company then return cb(nil) end

    local identifier = player.getIdentifier()
    local remaining, found = {}, false

    for _, account in ipairs(getAccounts(company.job)) do
        if account.id == accountId then
            -- Only the creator may delete an account
            if account.createdBy == identifier then
                found = true
            end
        else
            remaining[#remaining + 1] = account
        end
    end

    if not found then return cb(nil) end

    local saved = saveAccounts(company.job, remaining)
    if not saved then return cb(nil) end
    cb(remaining)
end)

--------------------------------------------------------------------
-- Callbacks: open / player info / settings
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:canOpen", function(src, cb)
    if inShowcase() then return Showcase.canOpen(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    if getBossCompany(player) then return cb(true) end
    if hasSettingsAccess(player) then return cb(true) end

    cb(isGradeAllowedByConfig(player))
end)

registerCallback("oxlyn-bossmenu:getPlayerInfo", function(src, cb)
    if inShowcase() then return Showcase.getPlayerInfo(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(nil) end

    local firstName = "Patrão"
    if player.get then
        local f = player.get("firstName")
        if f then firstName = f end
    elseif player.getName then
        firstName = player.getName()
    end

    local job = player.getJob()

    if CacheIdentity then
        CacheIdentity(src, player.getIdentifier())
    end

    local bossCompany = getBossCompany(player)
    local company = bossCompany
    if not company and job then
        company = getCompany(job.name)
    end
    local boss = bossCompany ~= nil

    if company then
        local ranks = getRanksCached(company.job)
        if #ranks > 0 then
            company.ranks = ranks
        end
    end

    local settings = (company and getSettings(company.job)) or emptySettings()

    local access = "full"
    if not boss and job then
        local gradeKey = tostring(tonumber(job.grade) or 0)
        access = (settings.tabAccess and settings.tabAccess[gradeKey]) or "limited"
    end

    cb({
        firstName  = firstName,
        identifier = player.getIdentifier(),
        playerName = (player.getName and player.getName()) or firstName,
        job        = job,
        company    = company,
        isBoss     = boss,
        myGrade    = (job and tonumber(job.grade)) or 0,
        myAccess   = access,
        settings   = (boss and settings) or nil,
        accounts   = (company and getAccounts(company.job)) or {},
    })
end)

registerCallback("oxlyn-bossmenu:getCompanySettings", function(src, cb)
    if inShowcase() then return Showcase.getCompanySettings(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(nil) end

    local company = getBossCompany(player)
    if not company then return cb(nil) end

    cb(getSettings(company.job))
end)

registerCallback("oxlyn-bossmenu:setCompanySettings", function(src, cb, settings)
    if inShowcase() then return Showcase.setCompanySettings(src, cb, settings) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    if type(settings) ~= "table" then return cb(false) end

    local ok = saveSettings(company.job, settings)
    cb(ok == true)
end)

--------------------------------------------------------------------
-- Callbacks: timesheet
--------------------------------------------------------------------
local TIMESHEET_SELECT =
    "SELECT id, identifier, name, grade, "
    .. "DATE_FORMAT(in_time, '%Y-%m-%dT%H:%i:%s') AS in_time, "
    .. "DATE_FORMAT(out_time, '%Y-%m-%dT%H:%i:%s') AS out_time, "
    .. "CASE WHEN out_time IS NULL THEN TIMESTAMPDIFF(SECOND, in_time, NOW()) ELSE secs END AS secs "

local EMPTY_TIMESHEET = function()
    return { shifts = {}, isBoss = false, myIdentifier = nil }
end

registerCallback("oxlyn-bossmenu:getTimesheet", function(src, cb)
    if inShowcase() then return Showcase.getTimesheet(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(EMPTY_TIMESHEET()) end

    local job = player.getJob()
    local company = job and getCompany(job.name) or nil
    if not company then return cb(EMPTY_TIMESHEET()) end

    local boss = isBoss(player)
    local identifier = player.getIdentifier()

    local query, params
    if boss then
        query  = TIMESHEET_SELECT .. "FROM oxlyn_company_timesheet WHERE job_name = ? ORDER BY in_time DESC LIMIT 200"
        params = { company.job }
    else
        query  = TIMESHEET_SELECT .. "FROM oxlyn_company_timesheet WHERE job_name = ? AND identifier = ? ORDER BY in_time DESC LIMIT 200"
        params = { company.job, identifier }
    end

    cb({
        shifts       = dbRows(query, params) or {},
        isBoss       = boss,
        myIdentifier = identifier,
    })
end)

registerCallback("oxlyn-bossmenu:clockIn", function(src, cb, targetIdentifier)
    if inShowcase() then return Showcase.clockIn(src, cb, targetIdentifier) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local job = player.getJob()
    local company = job and getCompany(job.name) or nil
    if not company then return cb({ ok = false, error = "no_company" }) end

    local identifier = player.getIdentifier()
    local boss = isBoss(player)

    -- Bosses may clock in someone else; everyone else clocks in themselves
    local target = identifier
    if targetIdentifier and targetIdentifier ~= "" and boss then
        target = targetIdentifier
    end

    local existing = dbScalar(
        "SELECT id FROM oxlyn_company_timesheet WHERE job_name = ? AND identifier = ? AND out_time IS NULL LIMIT 1",
        { company.job, target }
    )
    if existing then
        return cb({ ok = false, error = "already_open" })
    end

    local name, grade
    if target == identifier then
        name  = (player.getName and player.getName()) or "Employee"
        grade = tonumber(job.grade) or 0
    else
        local row = fetchPlayerRow(target)
        if row then
            name  = dbRowName(row)
            grade = tonumber(row.job_grade) or 0
        end
        if not name or name == "" then
            name = "Employee"
        end
    end

    local shiftId = dbInsert(
        "INSERT INTO oxlyn_company_timesheet (job_name, identifier, name, grade, in_time, out_time, secs) "
        .. "VALUES (?, ?, ?, ?, NOW(), NULL, 0)",
        { company.job, target, name, grade or 0 }
    )

    if not shiftId then
        return cb({ ok = false, error = "db_error" })
    end

    cb({ ok = true, shiftId = shiftId })
end)

registerCallback("oxlyn-bossmenu:clockOut", function(src, cb, shiftId)
    if inShowcase() then return Showcase.clockOut(src, cb, shiftId) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local job = player.getJob()
    local company = job and getCompany(job.name) or nil
    if not company then return cb({ ok = false, error = "no_company" }) end

    shiftId = tonumber(shiftId)
    if not shiftId then return cb({ ok = false, error = "no_id" }) end

    local rows = dbRows(
        "SELECT id, identifier, in_time, out_time FROM oxlyn_company_timesheet WHERE id = ? LIMIT 1",
        { shiftId }
    )
    local shift = rows and rows[1]
    if not shift then return cb({ ok = false, error = "not_found" }) end

    if shift.out_time then return cb({ ok = false, error = "already_closed" }) end

    -- Non-bosses may only close their own shifts
    if not isBoss(player) and shift.identifier ~= player.getIdentifier() then
        return cb({ ok = false, error = "not_owner" })
    end

    local affected = dbExecute(
        "UPDATE oxlyn_company_timesheet SET out_time = NOW(), secs = TIMESTAMPDIFF(SECOND, in_time, NOW()) WHERE id = ? AND out_time IS NULL",
        { shiftId }
    )

    if not affected or affected <= 0 then
        local check = dbScalar("SELECT out_time FROM oxlyn_company_timesheet WHERE id = ? LIMIT 1", { shiftId })
        if check ~= nil then
            return cb({ ok = true, closed = true })
        end
        return cb({ ok = false, error = "db_error" })
    end

    cb({ ok = true })
end)

registerCallback("oxlyn-bossmenu:clearTimesheet", function(src, cb)
    if inShowcase() then return Showcase.clearTimesheet(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    if not isDatabaseConfirmedReady() then
        return cb(false)
    end

    local ok, result = pcall(function()
        return exports.oxmysql:executeSync("DELETE FROM oxlyn_company_timesheet WHERE job_name = ?", { company.job })
    end)

    if not ok or result == nil then
        return cb(false)
    end

    cb(true)
end)

--------------------------------------------------------------------
-- Callbacks: company data / online players
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:getCompanyData", function(src, cb)
    if inShowcase() then return Showcase.getCompanyData(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(nil) end

    local job = player.getJob()
    local company = getBossCompany(player)
    if not company and job then
        company = getCompany(job.name)
    end
    if not company then return cb(nil) end

    if not isBoss(player) and not hasSettingsAccess(player) then
        return cb(nil)
    end

    listEmployees(company.job, function(employees)
        getSocietyBalance(company.job, function(balance)
            local ranks = getRanksCached(company.job)
            if not ranks or #ranks == 0 then
                ranks = company.ranks or {}
            end

            cb({
                balance   = balance,
                employees = employees,
                ranks     = ranks,
            })
        end)
    end)
end)

registerCallback("oxlyn-bossmenu:listOnlinePlayers", function(src, cb)
    if inShowcase() then return Showcase.listOnlinePlayers(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({}) end

    local company = getBossCompany(player)
    local ownJob = company and company.job or nil

    local list = {}
    for _, other in ipairs(Framework.GetExtendedPlayers()) do
        local otherJob = other.getJob()
        local first, last = getFirstLast(other)

        -- Hide people who already work at this company
        if not (ownJob and otherJob.name == ownJob) then
            list[#list + 1] = {
                source     = other.source,
                identifier = other.getIdentifier(),
                name       = trimEnd(first .. " " .. last),
                job        = otherJob.name,
                jobLabel   = otherJob.label or otherJob.name,
            }
        end
    end

    table.sort(list, function(a, b) return a.name < b.name end)
    cb(list)
end)

--------------------------------------------------------------------
-- MultiJob integration (optional external multijob resource)
--------------------------------------------------------------------
local function getMultiJobConfig()
    local cfg = Config and Config.MultiJob
    if type(cfg) ~= "table" then return nil end
    if cfg.enabled == false then return nil end

    local resource = trim(tostring(cfg.resource or ""))
    if resource == "" then return nil end

    if cfg.enabled ~= true and GetResourceState(resource) ~= "started" then
        return nil
    end

    return cfg, resource
end

local function multiJobDebug(fmt, ...)
    local cfg = Config and Config.MultiJob
    if not (cfg and cfg.debug == true) then return end

    print((("^5[%s] multijob: " .. fmt .. "^7"):format(RESOURCE_TAG, ...)))
end

local function callMultiJobExport(resource, exportName, a, b)
    if type(exportName) ~= "string" or exportName == "" then
        return false
    end

    local ok, err = pcall(function()
        return exports[resource][exportName](exports[resource], a, b)
    end)

    if not ok then
        multiJobDebug("export %s:%s failed — %s", resource, exportName, tostring(err))
        return false
    end

    multiJobDebug("%s:%s(%s, %s) ok", resource, exportName, tostring(a), tostring(b))
    return true
end

local function removeJobFromMultiJob(identifier, jobName, source)
    local cfg, resource = getMultiJobConfig()
    if not cfg then return end

    local exportNames = (type(cfg.exports) == "table") and cfg.exports or {}

    if source then
        if callMultiJobExport(resource, exportNames.fireOnline, source, jobName) then
            return
        end
    end

    if identifier then
        callMultiJobExport(resource, exportNames.fireOffline, identifier, jobName)
    end
end

--------------------------------------------------------------------
-- Employee events (other resources can listen to these)
--------------------------------------------------------------------
local function emitEmployeeFired(data)
    data = data or {}
    data.offline = data.source == nil
    TriggerEvent("oxlyn-bossmenu:employeeFired", data)
    removeJobFromMultiJob(data.identifier, data.job, data.source)
end

local function emitEmployeeHired(data)
    TriggerEvent("oxlyn-bossmenu:employeeHired", data or {})
end

local function emitEmployeeGradeChanged(data)
    TriggerEvent("oxlyn-bossmenu:employeeGradeChanged", data or {})
end

-- Online player with this identifier, else (pcall) framework lookup, else nil
local function findPlayerByIdentifier(identifier)
    for _, player in ipairs(Framework.GetExtendedPlayers()) do
        if player.getIdentifier() == identifier then
            return player
        end
    end

    if Framework.GetPlayerByIdentifier then
        local ok, player = pcall(Framework.GetPlayerByIdentifier, identifier)
        if ok then return player end
    end
    return nil
end

--------------------------------------------------------------------
-- Callbacks: hire / grade / fire / salary
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:hireEmployee", function(src, cb, targetSource, grade)
    if inShowcase() then return Showcase.hireEmployee(src, cb, targetSource, grade) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    local target = Framework.GetPlayerFromId(targetSource)
    if not target then return cb(false) end

    grade = tonumber(grade) or 0
    target.setJob(company.job, grade)

    if target.showNotification then
        target.showNotification(tr("lua_notify_hired", {
            company = company.name or company.job,
            _d      = "Foste contratado para {company}",
        }))
    end

    emitEmployeeHired({
        identifier  = target.getIdentifier(),
        source      = tonumber(targetSource),
        job         = company.job,
        grade       = grade,
        companyName = company.name or company.job,
        by          = "boss",
        bySource    = src,
    })

    cb(true)
end)

registerCallback("oxlyn-bossmenu:setEmployeeGrade", function(src, cb, identifier, grade)
    if inShowcase() then return Showcase.setEmployeeGrade(src, cb, identifier, grade) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    local target = findPlayerByIdentifier(identifier)

    -- Online target
    if target then
        if target.getJob().name ~= company.job then
            return cb(false)
        end

        grade = tonumber(grade) or 0
        target.setJob(company.job, grade)

        if target.showNotification then
            target.showNotification(tr("lua_notify_grade_changed", {
                _d = "A tua patente foi alterada",
            }))
        end

        emitEmployeeGradeChanged({
            identifier  = identifier,
            source      = tonumber(target.source),
            job         = company.job,
            grade       = grade,
            companyName = company.name or company.job,
            by          = "boss",
            bySource    = src,
        })

        return cb(true)
    end

    -- Offline target
    local row = fetchPlayerRow(identifier)
    if not (row and row.job == company.job) then
        return cb(false)
    end

    grade = tonumber(grade) or 0
    setJobOffline(identifier, company.job, grade)

    local success = fetchPlayerRow(identifier) ~= nil
    if success then
        emitEmployeeGradeChanged({
            identifier  = identifier,
            source      = nil,
            job         = company.job,
            grade       = grade,
            companyName = company.name or company.job,
            by          = "boss",
            bySource    = src,
        })
    end

    cb(success)
end)

registerCallback("oxlyn-bossmenu:fireEmployee", function(src, cb, identifier)
    if inShowcase() then return Showcase.fireEmployee(src, cb, identifier) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    local target = findPlayerByIdentifier(identifier)

    -- Online target
    if target then
        local targetJob = target.getJob()
        if targetJob.name ~= company.job then
            return cb(false)
        end

        local oldGrade = tonumber(targetJob.grade) or 0
        target.setJob("unemployed", 0)

        if target.showNotification then
            target.showNotification(tr("lua_notify_fired", {
                company = company.name or company.job,
                _d      = "Foste despedido de {company}",
            }))
        end

        emitEmployeeFired({
            identifier  = identifier,
            source      = tonumber(target.source),
            job         = company.job,
            grade       = oldGrade,
            companyName = company.name or company.job,
            by          = "boss",
            bySource    = src,
        })

        return cb(true)
    end

    -- Offline target
    local row = fetchPlayerRow(identifier)
    if not (row and row.job == company.job) then
        return cb(false)
    end

    local oldGrade = tonumber(row.job_grade) or 0
    setJobOffline(identifier, "unemployed", 0)

    local success = getJobNameOffline(identifier) == "unemployed"
    if success then
        emitEmployeeFired({
            identifier  = identifier,
            source      = nil,
            job         = company.job,
            grade       = oldGrade,
            companyName = company.name or company.job,
            by          = "boss",
            bySource    = src,
        })
    end

    cb(success)
end)

registerCallback("oxlyn-bossmenu:setGradeSalary", function(src, cb, grade, salary)
    if inShowcase() then return Showcase.setGradeSalary(src, cb, grade, salary) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(false) end

    local company = getBossCompany(player)
    if not company then return cb(false) end

    -- Runtime salary edits only supported on ESX (job_grades table)
    if Framework.type ~= "esx" then return cb(false) end

    grade  = tonumber(grade)
    salary = tonumber(salary)
    if grade == nil or salary == nil or salary < 0 then
        return cb(false)
    end

    local affected = dbExecute(
        "UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?",
        { salary, company.job, grade }
    )

    invalidateRankCache(company.job)
    patchFrameworkJobCache(company.job, grade, { salary = salary })

    cb(affected and affected > 0)
end)

--------------------------------------------------------------------
-- Callbacks: ranks (ESX only — edits the job_grades table)
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:addRank", function(src, cb, data)
    if inShowcase() then return Showcase.addRank(src, cb, data) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false, error = "no_access" }) end

    if Framework.type ~= "esx" then
        return cb({ ok = false, error = "no_runtime_edit" })
    end

    data = data or {}

    local grade  = tonumber(data.grade)
    local label  = tostring(data.label or ""):sub(1, 60)
    local salary = tonumber(data.salary) or 0

    if not grade or grade < 0 or label == "" or salary < 0 then
        return cb({ ok = false, error = "invalid" })
    end

    local existing = dbScalar(
        "SELECT grade FROM job_grades WHERE job_name = ? AND grade = ? LIMIT 1",
        { company.job, grade }
    )
    if existing ~= nil then
        return cb({ ok = false, error = "grade_exists" })
    end

    -- Slug from the label for the grade's internal `name`
    local slug = label:lower()
        :gsub("[^%w]", "_")
        :gsub("_+", "_")
        :gsub("^_+", "")
        :gsub("_+$", "")
    if slug == "" then
        slug = "grade" .. grade
    end

    -- Ensure the name is unique within the job
    local suffix = 0
    local gradeName = slug
    while dbScalar(
        "SELECT name FROM job_grades WHERE job_name = ? AND name = ? LIMIT 1",
        { company.job, gradeName }
    ) ~= nil do
        suffix = suffix + 1
        gradeName = slug .. "_" .. suffix
    end

    dbExecute(
        "INSERT INTO job_grades (job_name, grade, name, label, salary) VALUES (?, ?, ?, ?, ?)",
        { company.job, grade, gradeName, label, salary }
    )

    invalidateRankCache(company.job)
    patchFrameworkJobCache(company.job, grade, {
        create = true,
        name   = gradeName,
        label  = label,
        salary = salary,
    })

    cb({ ok = true })
end)

registerCallback("oxlyn-bossmenu:updateRankLabel", function(src, cb, grade, label)
    if inShowcase() then return Showcase.updateRankLabel(src, cb, grade, label) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false }) end

    if Framework.type ~= "esx" then
        return cb({ ok = false, error = "no_runtime_edit" })
    end

    grade = tonumber(grade)
    label = tostring(label or ""):sub(1, 60)
    if not grade or label == "" then
        return cb({ ok = false })
    end

    local affected = dbExecute(
        "UPDATE job_grades SET label = ? WHERE job_name = ? AND grade = ?",
        { label, company.job, grade }
    )

    invalidateRankCache(company.job)
    patchFrameworkJobCache(company.job, grade, { label = label })

    cb({ ok = affected > 0 })
end)

registerCallback("oxlyn-bossmenu:deleteRank", function(src, cb, grade)
    if inShowcase() then return Showcase.deleteRank(src, cb, grade) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false, error = "no_access" }) end

    if Framework.type ~= "esx" then
        return cb({ ok = false, error = "no_runtime_edit" })
    end

    grade = tonumber(grade)
    if not grade then return cb({ ok = false, error = "invalid" }) end

    -- Boss grades can't be deleted
    for _, bossGrade in ipairs(company.bossGrades or {}) do
        if tonumber(bossGrade) == grade then
            return cb({ ok = false, error = "is_boss_grade" })
        end
    end

    -- Grades with members can't be deleted
    local count = countMembersAtGrade(company.job, grade)
    if (tonumber(count) or 0) > 0 then
        return cb({ ok = false, error = "has_members", count = tonumber(count) })
    end

    dbExecute("DELETE FROM job_grades WHERE job_name = ? AND grade = ?", { company.job, grade })

    invalidateRankCache(company.job)
    patchFrameworkJobCache(company.job, grade, nil)

    cb({ ok = true })
end)

--------------------------------------------------------------------
-- Transaction ledger
--------------------------------------------------------------------
local function getLedgerConfig()
    local cfg = (Config and Config.Transactions) or {}
    local fetchLimit = math.floor(tonumber(cfg.fetchLimit) or 500)

    return {
        enabled    = cfg.enabled ~= false,
        logExports = cfg.logExports ~= false,
        fetchLimit = math.max(50, math.min(fetchLimit, 5000)),
    }
end

-- Trim, drop empties, truncate to maxLen characters (UTF-8 aware).
local function sanitizeText(value, maxLen)
    if value == nil then return nil end

    value = trim(tostring(value))
    if value == "" then return nil end

    local ok, offset = pcall(utf8.offset, value, maxLen + 1)
    if ok and offset then
        value = value:sub(1, offset - 1)
    end
    return value
end

-- { identifier, name, grade } for a player (the "actor" in the ledger)
local function getActorInfo(player)
    if not player then return {} end

    local job = player.getJob and player.getJob() or nil

    return {
        identifier = player.getIdentifier and player.getIdentifier() or nil,
        name       = getDisplayName(player),
        grade      = job and tonumber(job.grade) or nil,
    }
end

local spawn = (Citizen and Citizen.CreateThreadNow) or CreateThread

-- Inserts a ledger row (async). entry = { job, type, amount, method, actor,
-- targetIdentifier, targetName, note, origin }
local function recordTransaction(entry)
    if not getLedgerConfig().enabled then return end
    if type(entry) ~= "table" or not entry.job then return end

    local amount = math.floor((tonumber(entry.amount) or 0) + 0.5)
    if amount <= 0 then return end

    local actor = entry.actor or {}

    spawn(function()
        -- Grab the balance after the change (3s timeout)
        local p = promise.new()
        local settled = false
        local function settle(value)
            if settled then return end
            settled = true
            p:resolve(value)
        end

        SetTimeout(3000, function() settle(nil) end)

        local ok = pcall(getSocietyBalance, entry.job, function(balance)
            settle(tonumber(balance))
        end)
        if not ok then settle(nil) end

        local balance = Citizen.Await(p)

        local columns, values = {}, {}
        local function add(column, value)
            if value ~= nil then
                columns[#columns + 1] = column
                values[#values + 1] = value
            end
        end

        add("job_name",          entry.job)
        add("type",              entry.type)
        add("amount",            amount)
        add("method",            sanitizeText(entry.method, 16))
        add("identifier",        sanitizeText(actor.identifier, 80))
        add("name",              sanitizeText(actor.name, 120))
        add("grade",             tonumber(actor.grade))
        add("target_identifier", sanitizeText(entry.targetIdentifier, 80))
        add("target_name",       sanitizeText(entry.targetName, 120))
        add("note",              sanitizeText(entry.note, 255))
        add("origin",            sanitizeText(entry.origin, 64))
        if balance then
            add("balance_after", math.floor(balance + 0.5))
        end

        if not isDatabaseConfirmedReady() then return end

        local okInsert, err = pcall(function()
            exports.oxmysql:insert(
                ("INSERT INTO oxlyn_company_transactions (%s) VALUES (%s)"):format(
                    table.concat(columns, ", "),
                    ("?, "):rep(#columns):sub(1, -3)
                ),
                values
            )
        end)

        if not okInsert then
            print(("^1[%s] ledger insert failed (%s %s): %s^7"):format(
                RESOURCE_TAG, tostring(entry.type), tostring(entry.job), tostring(err)))
        end
    end)
end

local function fetchTransactions(jobName, limit)
    return dbRows(
        "SELECT id, type, amount, method, identifier, name, grade, target_identifier, target_name, "
        .. "note, origin, balance_after, DATE_FORMAT(created_at, '%Y-%m-%dT%H:%i:%s') AS ts "
        .. "FROM oxlyn_company_transactions WHERE job_name = ? ORDER BY id DESC LIMIT ?",
        { jobName, math.floor(tonumber(limit) or 500) }
    )
end

registerCallback("oxlyn-bossmenu:getTransactions", function(src, cb)
    if inShowcase() then return Showcase.getTransactions(src, cb) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb(nil) end

    local company = getBossCompany(player)
    if not company then return cb(nil) end

    local cfg = getLedgerConfig()

    cb({
        rows    = (cfg.enabled and fetchTransactions(company.job, cfg.fetchLimit)) or {},
        limit   = cfg.fetchLimit,
        enabled = cfg.enabled,
    })
end)

--------------------------------------------------------------------
-- Callbacks: money (deposit / withdraw / bonus)
--------------------------------------------------------------------
registerCallback("oxlyn-bossmenu:depositMoney", function(src, cb, amount, note)
    if inShowcase() then return Showcase.depositMoney(src, cb, amount, note) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false, error = "no_access" }) end

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end

    local cash = tonumber(player.getMoney and player.getMoney() or 0) or 0
    local bankAccount = player.getAccount and player.getAccount("bank") or nil
    local bank = tonumber(bankAccount and bankAccount.money or 0) or 0

    if amount > cash + bank then
        return cb({ ok = false, error = "insufficient_player" })
    end

    -- Take from cash first, then bank, then both
    local method
    if amount <= cash then
        player.removeMoney(amount)
        method = "cash"
    elseif amount <= bank then
        player.removeAccountMoney("bank", amount)
        method = "bank"
    else
        if cash > 0 then
            player.removeMoney(cash)
        end
        player.removeAccountMoney("bank", amount - cash)
        method = (cash > 0) and "mixed" or "bank"
    end

    changeSocietyMoney(company.job, amount, function(ok)
        -- NOTE: the original always sets `error` here (likely an
        -- `ok and nil or "society_failed"` slip); behavior preserved.
        cb({ ok = ok, error = "society_failed" })

        if ok then
            recordTransaction({
                job    = company.job,
                type   = "deposit",
                amount = amount,
                method = method,
                actor  = getActorInfo(player),
                note   = note,
                origin = "bossmenu",
            })
        end
    end)
end)

registerCallback("oxlyn-bossmenu:withdrawMoney", function(src, cb, amount, note)
    if inShowcase() then return Showcase.withdrawMoney(src, cb, amount, note) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false, error = "no_access" }) end

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end

    getSocietyBalance(company.job, function(balance)
        if balance < amount then
            return cb({ ok = false, error = "insufficient_society" })
        end

        changeSocietyMoney(company.job, -amount, function(ok)
            if ok then
                player.addMoney(amount)
            end

            -- NOTE: `error` always set in the original (see depositMoney)
            cb({ ok = ok, error = "society_failed" })

            if ok then
                recordTransaction({
                    job    = company.job,
                    type   = "withdraw",
                    amount = amount,
                    method = "cash",
                    actor  = getActorInfo(player),
                    note   = note,
                    origin = "bossmenu",
                })
            end
        end)
    end)
end)

registerCallback("oxlyn-bossmenu:payBonus", function(src, cb, targetIdentifier, amount, note)
    if inShowcase() then return Showcase.payBonus(src, cb, targetIdentifier, amount, note) end

    local player = Framework.GetPlayerFromId(src)
    if not player then return cb({ ok = false, error = "no_player" }) end

    local company = getBossCompany(player)
    if not company then return cb({ ok = false, error = "no_access" }) end

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end

    -- Find the target among online players
    local target = nil
    for _, other in ipairs(Framework.GetExtendedPlayers()) do
        if other.getIdentifier() == targetIdentifier then
            target = other
            break
        end
    end

    -- Target must work for this company
    local isMember
    if target then
        isMember = target.getJob().name == company.job
    else
        isMember = getJobNameOffline(targetIdentifier) == company.job
    end

    if not isMember then
        return cb({ ok = false, error = "not_member" })
    end

    getSocietyBalance(company.job, function(balance)
        if balance < amount then
            return cb({ ok = false, error = "insufficient_society" })
        end

        changeSocietyMoney(company.job, -amount, function(ok)
            if not ok then
                return cb({ ok = false, error = "society_failed" })
            end

            local method = "bank"
            local targetName = nil

            if target then
                if target.addAccountMoney then
                    target.addAccountMoney("bank", amount)
                else
                    target.addMoney(amount)
                    method = "cash"
                end

                if target.showNotification then
                    target.showNotification(tr("lua_notify_bonus_received", {
                        amount = formatMoney(amount),
                        _d     = "Recebeste um bónus de {amount}",
                    }))
                end

                targetName = getDisplayName(target)
            else
                addBankMoneyOffline(targetIdentifier, amount)

                local row = fetchPlayerRow(targetIdentifier)
                if row then
                    targetName = (row.firstname or "") .. " " .. (row.lastname or "")
                end
            end

            cb({ ok = true })

            recordTransaction({
                job              = company.job,
                type             = "bonus",
                amount           = amount,
                method           = method,
                actor            = getActorInfo(player),
                targetIdentifier = targetIdentifier,
                targetName       = targetName,
                note             = note,
                origin           = "bossmenu",
            })
        end)
    end)
end)

--------------------------------------------------------------------
-- Public exports
--------------------------------------------------------------------
local function waitForFramework()
    local waited = 0
    while not (Framework and Framework.ready) and waited < 30000 do
        Wait(100)
        waited = waited + 100
    end
    return Framework and Framework.ready
end

-- Allows both (job, amount, cb, info) and (job, amount, info) call styles.
local function normalizeCallback(a, b)
    if a == false then
        return nil, b
    end
    if a ~= nil and not isCallable(a) then
        return nil, a
    end
    return a, b
end

-- Logs an export-driven money change to the ledger.
local function logExportTransaction(jobName, txType, amount, info, invokingResource)
    if not getLedgerConfig().logExports then return end

    local note = nil
    local actor = {}

    if type(info) == "table" then
        note = info.reason or info.note or info.label

        local source = tonumber(info.source)
        local player = source and Framework.GetPlayerFromId(source) or nil
        if player then
            actor = getActorInfo(player)
        end

        actor.identifier = actor.identifier or info.identifier
        actor.name       = actor.name or info.name
    elseif type(info) == "string" or type(info) == "number" then
        note = info
    end

    recordTransaction({
        job    = jobName,
        type   = txType,
        amount = amount,
        actor  = actor,
        note   = note,
        origin = invokingResource or "unknown",
    })
end

exports("AddCompanyFunds", function(jobName, amount, cb, info)
    cb, info = normalizeCallback(cb, info)
    local invoking = GetInvokingResource()

    amount = tonumber(amount) or 0
    if type(jobName) ~= "string" or jobName == "" or amount <= 0 then
        if cb then cb(false) end
        return
    end

    if not getCompany(jobName) then
        if cb then cb(false) end
        return
    end

    CreateThread(function()
        if not waitForFramework() then
            if cb then cb(false) end
            return
        end

        Framework.AddSocietyMoney(jobName, amount, function(ok)
            if cb then cb(ok ~= false) end
            if ok ~= false then
                logExportTransaction(jobName, "income", amount, info, invoking)
            end
        end)
    end)
end)

exports("RemoveCompanyFunds", function(jobName, amount, cb, info)
    cb, info = normalizeCallback(cb, info)
    local invoking = GetInvokingResource()

    amount = tonumber(amount) or 0
    if type(jobName) ~= "string" or jobName == "" or amount <= 0 then
        if cb then cb(false) end
        return
    end

    if not getCompany(jobName) then
        if cb then cb(false) end
        return
    end

    CreateThread(function()
        if not waitForFramework() then
            if cb then cb(false) end
            return
        end

        Framework.RemoveSocietyMoney(jobName, amount, function(ok)
            if cb then cb(ok ~= false) end
            if ok ~= false then
                logExportTransaction(jobName, "expense", amount, info, invoking)
            end
        end)
    end)
end)

exports("GetCompanyTransactions", function(jobName, cb, limit)
    if not isCallable(cb) then return end

    if type(jobName) ~= "string" or jobName == "" then
        return cb({})
    end

    limit = math.max(1, math.min(math.floor(tonumber(limit) or 200), 5000))

    CreateThread(function()
        cb(fetchTransactions(jobName, limit) or {})
    end)
end)

exports("GetCompanyFunds", function(jobName, cb)
    if not (type(jobName) == "string" and jobName ~= "" and isCallable(cb)) then
        if cb then cb(0) end
        return
    end

    CreateThread(function()
        if not waitForFramework() then
            cb(0)
            return
        end

        Framework.GetSocietyMoney(jobName, function(balance)
            cb(tonumber(balance) or 0)
        end)
    end)
end)

--------------------------------------------------------------------
-- Duty exports (StartDuty / EndDuty / IsOnDuty / GetActiveShifts)
--------------------------------------------------------------------

-- Name + grade for a timesheet row (online player first, then DB)
local function resolveNameAndGrade(identifier)
    for _, player in ipairs(Framework.GetExtendedPlayers()) do
        if player.getIdentifier() == identifier then
            local job = player.getJob() or {}
            local first = (player.get and player.get("firstName")) or ""
            local last  = (player.get and player.get("lastName")) or ""

            local name
            if first ~= "" or last ~= "" then
                name = trim(first .. " " .. last)
            else
                name = (player.getName and player.getName()) or "Employee"
            end

            return name, tonumber(job.grade) or 0
        end
    end

    local row = fetchPlayerRow(identifier)
    if row then
        local name = dbRowName(row)
        if name == "" then name = "Employee" end
        return name, tonumber(row.job_grade) or 0
    end

    return "Employee", 0
end

local function isNonEmptyString(value)
    return type(value) == "string" and value ~= ""
end

exports("StartDuty", function(identifier, jobName, cb)
    cb = cb or function() end

    if not (isNonEmptyString(identifier) and isNonEmptyString(jobName)) then
        return cb({ ok = false, error = "invalid" })
    end

    if not getCompany(jobName) then
        return cb({ ok = false, error = "no_company" })
    end

    CreateThread(function()
        if not waitForFramework() then
            return cb({ ok = false, error = "framework_not_ready" })
        end

        if not isDatabaseConfirmedReady() then
            return cb({ ok = false, error = "db_not_ready" })
        end

        local existing = dbScalar(
            "SELECT id FROM oxlyn_company_timesheet WHERE job_name = ? AND identifier = ? AND out_time IS NULL LIMIT 1",
            { jobName, identifier }
        )
        if existing then
            return cb({ ok = false, error = "already_open", shiftId = tonumber(existing) })
        end

        local name, grade = resolveNameAndGrade(identifier)

        local shiftId = dbInsert(
            "INSERT INTO oxlyn_company_timesheet (job_name, identifier, name, grade, in_time, out_time, secs) "
            .. "VALUES (?, ?, ?, ?, NOW(), NULL, 0)",
            { jobName, identifier, name, grade }
        )

        if not shiftId then
            return cb({ ok = false, error = "insert_failed" })
        end

        cb({ ok = true, shiftId = shiftId })
    end)
end)

exports("EndDuty", function(identifier, jobName, cb)
    cb = cb or function() end

    if not (isNonEmptyString(identifier) and isNonEmptyString(jobName)) then
        return cb({ ok = false, error = "invalid" })
    end

    if not getCompany(jobName) then
        return cb({ ok = false, error = "no_company" })
    end

    CreateThread(function()
        if not waitForFramework() then
            return cb({ ok = false, error = "framework_not_ready" })
        end

        local rows = dbRows(
            "SELECT id, TIMESTAMPDIFF(SECOND, in_time, NOW()) AS secs "
            .. "FROM oxlyn_company_timesheet WHERE job_name = ? AND identifier = ? AND out_time IS NULL "
            .. "ORDER BY in_time DESC LIMIT 1",
            { jobName, identifier }
        )

        local shift = rows and rows[1]
        if not shift then
            return cb({ ok = false, error = "not_open" })
        end

        dbExecute(
            "UPDATE oxlyn_company_timesheet SET out_time = NOW(), secs = ? WHERE id = ?",
            { tonumber(shift.secs) or 0, tonumber(shift.id) }
        )

        cb({ ok = true, secs = tonumber(shift.secs) or 0 })
    end)
end)

exports("IsOnDuty", function(identifier, jobName, cb)
    if not isCallable(cb) then return end

    if not (isNonEmptyString(identifier) and isNonEmptyString(jobName)) then
        return cb(false)
    end

    CreateThread(function()
        if not waitForFramework() then
            return cb(false)
        end

        local id = dbScalar(
            "SELECT id FROM oxlyn_company_timesheet WHERE job_name = ? AND identifier = ? AND out_time IS NULL LIMIT 1",
            { jobName, identifier }
        )
        cb(id ~= nil)
    end)
end)

exports("GetActiveShifts", function(jobName, cb)
    if not isCallable(cb) then return end

    if not isNonEmptyString(jobName) then
        return cb({})
    end

    CreateThread(function()
        if not waitForFramework() then
            return cb({})
        end

        local rows = dbRows(
            "SELECT id, identifier, name, grade, "
            .. "DATE_FORMAT(in_time, '%Y-%m-%dT%H:%i:%s') AS in_time, "
            .. "TIMESTAMPDIFF(SECOND, in_time, NOW()) AS secs "
            .. "FROM oxlyn_company_timesheet WHERE job_name = ? AND out_time IS NULL ORDER BY in_time DESC",
            { jobName }
        )
        cb(rows or {})
    end)
end)

--------------------------------------------------------------------
-- Identity cache + auto clock-out when a player disconnects
--------------------------------------------------------------------
_identityCache = _identityCache or {}

-- Remember source -> identifier (used when the player object is gone)
function CacheIdentity(src, identifier)
    if not (src and identifier) or identifier == "" then return end
    _identityCache[src] = identifier
end

-- Close every open shift for an identifier
local function closeOpenShifts(identifier)
    if not identifier or identifier == "" then return end

    local rows = dbRows(
        "SELECT id, TIMESTAMPDIFF(SECOND, in_time, NOW()) AS secs "
        .. "FROM oxlyn_company_timesheet WHERE identifier = ? AND out_time IS NULL",
        { identifier }
    )

    for _, shift in ipairs(rows or {}) do
        dbExecute(
            "UPDATE oxlyn_company_timesheet SET out_time = NOW(), secs = ? WHERE id = ?",
            { tonumber(shift.secs) or 0, tonumber(shift.id) }
        )
    end
end

AddEventHandler("playerDropped", function()
    local src = source

    CreateThread(function()
        if not waitForFramework() then return end

        local identifier = nil
        local player = Framework.GetPlayerFromId(src)
        if player and player.getIdentifier then
            identifier = player.getIdentifier()
        end

        if not identifier then
            identifier = _identityCache[src]
        end
        _identityCache[src] = nil

        if identifier then
            closeOpenShifts(identifier)
        end
    end)
end)

--------------------------------------------------------------------
-- Admin: remove a player's boss rank (Config.Admin.removeBossCommand)
--------------------------------------------------------------------

-- Highest non-boss grade of a company (used when demoting)
local function computeDemotionGrade(company)
    local bossSet = {}
    for _, grade in ipairs(company.bossGrades or {}) do
        bossSet[tonumber(grade)] = true
    end

    local best = 0
    local found = false

    for _, rank in ipairs(getRanksCached(company.job) or {}) do
        local grade = tonumber(rank.grade) or 0
        if not bossSet[grade] and (not found or best < grade) then
            best = grade
            found = true
        end
    end

    return found and best or 0
end

local function searchPlayersByName(name)
    local pattern = "%" .. name .. "%"

    if isQbFramework() then
        return dbRows(
            "SELECT citizenid AS identifier, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))  AS lastname, "
            .. "JSON_UNQUOTE(JSON_EXTRACT(job, '$.name'))           AS job, "
            .. "CAST(JSON_EXTRACT(job, '$.grade.level') AS UNSIGNED) AS job_grade "
            .. "FROM players WHERE CONCAT("
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')), ' ', "
            .. "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname'))) LIKE ? LIMIT 6",
            { pattern }
        ) or {}
    end

    return dbRows(
        "SELECT identifier, firstname, lastname, job, job_grade FROM users "
        .. "WHERE CONCAT(firstname, ' ', lastname) LIKE ? LIMIT 6",
        { pattern }
    ) or {}
end

-- Online-player entry for the admin command
local function onlineTargetEntry(player)
    local job = player.getJob() or {}
    return {
        identifier = player.getIdentifier(),
        name       = displayNameOrEmployee(player),
        jobName    = job.name,
        grade      = tonumber(job.grade) or 0,
        online     = true,
    }
end

-- Resolve "<server id | player name>" to a target.
-- Returns entry, or nil + errorCode [+ extra info].
local function resolveTarget(query)
    -- Server id
    if query:match("^%d+$") then
        local player = Framework.GetPlayerFromId(tonumber(query))
        if not player then
            return nil, "id_not_online"
        end
        return onlineTargetEntry(player)
    end

    -- Online name: exact match wins, otherwise collect partial matches
    local lowered = query:lower()
    local partial = {}

    for _, player in ipairs(Framework.GetExtendedPlayers()) do
        local name = displayNameOrEmployee(player)

        if name:lower() == lowered then
            return onlineTargetEntry(player)
        end
        if name:lower():find(lowered, 1, true) then
            partial[#partial + 1] = player
        end
    end

    if #partial == 1 then
        return onlineTargetEntry(partial[1])
    elseif #partial > 1 then
        local names = {}
        for _, player in ipairs(partial) do
            names[#names + 1] = displayNameOrEmployee(player)
        end
        return nil, "ambiguous", table.concat(names, ", ")
    end

    -- Offline (DB) search
    local rows = searchPlayersByName(query)

    if #rows == 1 then
        local row = rows[1]
        local name = dbRowName(row)
        return {
            identifier = row.identifier,
            name       = (name ~= "" and name) or "Employee",
            jobName    = row.job,
            grade      = tonumber(row.job_grade) or 0,
            online     = false,
        }
    elseif #rows > 1 then
        local names = {}
        for _, row in ipairs(rows) do
            names[#names + 1] = dbRowName(row)
        end
        return nil, "ambiguous", table.concat(names, ", ")
    end

    return nil, "not_found"
end

local function isBossGrade(company, grade)
    for _, bossGrade in ipairs(company.bossGrades or {}) do
        if tonumber(bossGrade) == tonumber(grade) then
            return true
        end
    end
    return false
end

-- Strips the boss rank (per Config.Admin.onRemove: "unemployed" or demote).
-- Returns success, mode, newGrade.
local function removeBossRank(target, company, adminSource)
    local mode = (Config.Admin and Config.Admin.onRemove == "unemployed") and "unemployed" or "demote"

    local newJob, newGrade
    if mode == "unemployed" then
        newJob, newGrade = "unemployed", 0
    else
        newJob, newGrade = company.job, computeDemotionGrade(company)
    end

    local companyName = company.name or company.job

    -- Online
    local player = findPlayerByIdentifier(target.identifier)
    if player then
        player.setJob(newJob, newGrade)

        if player.showNotification then
            player.showNotification(tr("lua_notify_admin_boss_removed", {
                _d = "An admin removed your boss rank.",
            }))
        end

        if mode == "unemployed" then
            emitEmployeeFired({
                identifier  = target.identifier,
                source      = tonumber(player.source),
                job         = company.job,
                grade       = tonumber(target.grade) or 0,
                companyName = companyName,
                by          = "admin",
                bySource    = adminSource,
            })
        end

        return true, mode, newGrade
    end

    -- Offline
    setJobOffline(target.identifier, newJob, newGrade)

    if mode == "unemployed" then
        local ok = getJobNameOffline(target.identifier) == "unemployed"
        if ok then
            emitEmployeeFired({
                identifier  = target.identifier,
                source      = nil,
                job         = company.job,
                grade       = tonumber(target.grade) or 0,
                companyName = companyName,
                by          = "admin",
                bySource    = adminSource,
            })
        end
        return ok, mode, newGrade
    end

    return fetchPlayerRow(target.identifier) ~= nil, mode, newGrade
end

-- Who may run the admin command (console / identifiers / ace / groups)
local function isAdmin(src)
    local cfg = Config.Admin or {}

    if src == 0 then
        return cfg.allowConsole ~= false
    end

    if cfg.identifiers and #cfg.identifiers > 0 then
        for _, playerIdentifier in ipairs(GetPlayerIdentifiers(src) or {}) do
            for _, allowed in ipairs(cfg.identifiers) do
                if playerIdentifier == allowed then
                    return true
                end
            end
        end
    end

    if type(cfg.ace) == "string" and cfg.ace ~= "" then
        if IsPlayerAceAllowed(src, cfg.ace) then
            return true
        end
    end

    if cfg.groups and #cfg.groups > 0 then
        for _, group in ipairs(cfg.groups) do
            if IsPlayerAceAllowed(src, "group." .. group) then
                return true
            end
        end

        local frameworkGroups = (Framework.GetAdminGroups and Framework.GetAdminGroups(src)) or {}
        for _, playerGroup in ipairs(frameworkGroups) do
            for _, allowed in ipairs(cfg.groups) do
                if tostring(playerGroup):lower() == tostring(allowed):lower() then
                    return true
                end
            end
        end
    end

    return false
end

-- Console print or in-game chat message
local function reply(src, message)
    if src == 0 then
        print("^3[" .. RESOURCE_TAG .. "] " .. message .. "^7")
    else
        TriggerClientEvent("chat:addMessage", src, {
            color     = { 255, 180, 0 },
            multiline = true,
            args      = { "Boss Menu", message },
        })
    end
end

if Config.Admin
    and type(Config.Admin.removeBossCommand) == "string"
    and Config.Admin.removeBossCommand ~= "" then

    RegisterCommand(Config.Admin.removeBossCommand, function(src, args)
        if not isAdmin(src) then
            return reply(src, "You are not allowed to use this command.")
        end

        local query = trim(table.concat(args or {}, " "))
        if query == "" then
            return reply(src, ("Usage: /%s <server id | player name>"):format(Config.Admin.removeBossCommand))
        end

        CreateThread(function()
            if not waitForFramework() then
                return reply(src, "Framework not ready, try again.")
            end

            local target, errorCode, extra = resolveTarget(query)
            if not target then
                local messages = {
                    id_not_online = "That server id is not online. Use the exact character name for offline players.",
                    ambiguous     = "Multiple players match \"" .. query .. "\": " .. tostring(extra) .. ". Be more specific.",
                    not_found     = "No player found for \"" .. query .. "\".",
                }
                return reply(src, messages[errorCode] or ("Could not resolve \"" .. query .. "\"."))
            end

            local company = target.jobName and getCompany(target.jobName) or nil
            if not company then
                return reply(src, ("%s is not in a boss-menu company (job: %s)."):format(
                    target.name, tostring(target.jobName)))
            end

            if not isBossGrade(company, target.grade) then
                return reply(src, ("%s is not a boss of %s (grade %d). Nothing to remove."):format(
                    target.name, company.name or company.job, target.grade))
            end

            local adminSource = (src ~= 0 and src) or nil
            local ok, mode, newGrade = removeBossRank(target, company, adminSource)
            if not ok then
                return reply(src, "Failed to update the player. Check the server console.")
            end

            local description
            if mode == "unemployed" then
                description = ("fired from %s"):format(company.name or company.job)
            else
                description = ("demoted to grade %d of %s"):format(newGrade, company.name or company.job)
            end

            reply(src, ("Boss rank removed: %s (%s) was %s. [%s]"):format(
                target.name,
                target.online and "online" or "offline",
                description,
                mode
            ))

            print(("^2[%s] Admin removed boss: %s (%s) -> %s^7"):format(
                RESOURCE_TAG, target.name, target.identifier, description))
        end)
    end, false)
end

