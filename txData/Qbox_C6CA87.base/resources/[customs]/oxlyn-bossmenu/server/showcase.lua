

-- Showcase (demo) mode for oxlyn-bossmenu
-- Cleaned up from decompiler output: registers renamed, temp-variable chains collapsed.
-- Behaviour is intended to be identical to the original.

Showcase = Showcase or {}

local TIME_FMT = "%Y-%m-%dT%H:%M:%S"
local TIME_PATTERN = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)"

-- state == nil   -> not initialised yet
-- state == false -> showcase disabled / misconfigured
local state = nil

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

-- Translation helper: uses global L() if present, else the default text (_d), else the key.
local function tr(key, opts)
    local translate = _G.L or rawget(_G, "L")
    if type(translate) == "function" then
        return translate(key, opts)
    end
    if opts and opts._d then
        return opts._d
    end
    return key
end

local function parseTime(str)
    local y, mo, d, h, mi, s = str:match(TIME_PATTERN)
    if not y then return nil end
    return os.time({
        year  = tonumber(y),
        month = tonumber(mo),
        day   = tonumber(d),
        hour  = tonumber(h),
        min   = tonumber(mi),
        sec   = tonumber(s),
    })
end

---------------------------------------------------------------------
-- Initialisation
---------------------------------------------------------------------

local function init()
    if state ~= nil then return end

    if not (Config.Showcase and Config.Showcase.enabled) then
        state = false
        return
    end

    -- Find the configured company
    local company
    for _, c in ipairs(Config.Companies or {}) do
        if c.id == Config.Showcase.companyId then
            company = c
            break
        end
    end

    if not company then
        print(("^1[oxlyn-bossmenu] Showcase: companyId \"%s\" does not exist in Config.Companies. Showcase mode disabled.^7")
            :format(tostring(Config.Showcase.companyId)))
        state = false
        return
    end

    -- Ranks
    local ranks = {}
    for _, r in ipairs(company.ranks or {}) do
        ranks[#ranks + 1] = {
            name   = r.name,
            label  = r.label or r.name,
            grade  = tonumber(r.grade) or 0,
            salary = tonumber(r.salary) or 0,
        }
    end

    -- Fake employees
    local employees = {}
    for _, e in ipairs(Config.Showcase.employees or {}) do
        employees[#employees + 1] = {
            identifier = e.identifier,
            source     = nil,
            name       = e.name,
            grade      = tonumber(e.grade) or 0,
            gradeLabel = "",
            online     = (e.online == true),
        }
    end

    -- Fake candidates (online players that can be hired)
    local candidates = {}
    for _, c in ipairs(Config.Showcase.candidates or {}) do
        candidates[#candidates + 1] = {
            source     = c.source,
            identifier = c.identifier,
            name       = c.name,
            job        = c.job or "unemployed",
            jobLabel   = c.jobLabel or c.job or tr("lua_label_unemployed", { _d = "Desempregado" }),
        }
    end

    state = {
        company         = company,
        ranks           = ranks,
        employees       = employees,
        candidates      = candidates,
        balance         = tonumber(Config.Showcase.balance) or 0,
        bossGrade       = tonumber(Config.Showcase.bossGrade) or 4,
        bossIdentifier  = nil,
        shifts          = {},
        nextShiftId     = 1,
        shiftsGenerated = false,
        nextSrc         = 9000,
    }

    print(("^2[oxlyn-bossmenu] Showcase mode ENABLED \226\128\148 company \"%s\" (%d employees, %d candidates).^7")
        :format(company.name, #employees, #candidates))
end

function Showcase.active()
    init()
    return state and state ~= false
end

---------------------------------------------------------------------
-- Lookups
---------------------------------------------------------------------

local function findEmployeeIndex(identifier)
    if not state then return nil end
    for i, e in ipairs(state.employees) do
        if e.identifier == identifier then
            return i
        end
    end
    return nil
end

-- Matches either by source or by identifier
local function findCandidateIndex(idOrSource)
    if not state then return nil end
    local key = tostring(idOrSource)
    for i, c in ipairs(state.candidates) do
        if tostring(c.source) == key or c.identifier == key then
            return i
        end
    end
    return nil
end

local function getCompanyInfo()
    local copy = {}
    for k, v in pairs(state.company) do
        copy[k] = v
    end
    copy.ranks = state.ranks
    return copy
end

-- Highest grade first, then alphabetical by name
local function getSortedEmployees()
    local list = {}
    for _, e in ipairs(state.employees) do
        table.insert(list, e)
    end
    table.sort(list, function(a, b)
        if a.grade ~= b.grade then
            return a.grade > b.grade
        end
        return (a.name or "") < (b.name or "")
    end)
    return list
end

---------------------------------------------------------------------
-- Timesheet generation
---------------------------------------------------------------------

local function generateShifts()
    if state.shiftsGenerated then return end
    state.shiftsGenerated = true

    -- Online employees get an open shift that started 20min - 3h ago
    for _, e in ipairs(state.employees) do
        if e.online then
            local startTime = os.time() - math.random(1200, 10800)
            table.insert(state.shifts, {
                id         = state.nextShiftId,
                identifier = e.identifier,
                name       = e.name,
                grade      = e.grade,
                in_time    = os.date(TIME_FMT, startTime),
                out_time   = nil,
                secs       = os.time() - startTime,
            })
            state.nextShiftId = state.nextShiftId + 1
        end
    end

    -- Everyone gets 2-4 random closed shifts from the last 7 days
    for _, e in ipairs(state.employees) do
        local count = math.random(2, 4)
        for _ = 1, count do
            local daysAgo  = math.random(1, 7)
            local startTime = os.time() - daysAgo * 86400 + math.random(28800, 57600)
            local duration  = math.random(7200, 28800)
            local endTime   = startTime + duration

            if endTime < os.time() then
                table.insert(state.shifts, {
                    id         = state.nextShiftId,
                    identifier = e.identifier,
                    name       = e.name,
                    grade      = e.grade,
                    in_time    = os.date(TIME_FMT, startTime),
                    out_time   = os.date(TIME_FMT, endTime),
                    secs       = duration,
                })
                state.nextShiftId = state.nextShiftId + 1
            end
        end
    end

    -- Newest first
    table.sort(state.shifts, function(a, b)
        return a.in_time > b.in_time
    end)
end

-- Recompute elapsed seconds for shifts that are still open
local function refreshOpenShifts()
    local now = os.time()
    for _, shift in ipairs(state.shifts) do
        if not shift.out_time then
            local startTime = parseTime(shift.in_time)
            if startTime then
                shift.secs = math.max(0, now - startTime)
            end
        end
    end
end

---------------------------------------------------------------------
-- Transactions
---------------------------------------------------------------------

-- Who is acting (the boss)
local function getBossInfo()
    local boss = state.employees[findEmployeeIndex(state.bossIdentifier) or 0]
    return {
        identifier = state.bossIdentifier,
        name       = (boss and boss.name) or tr("lua_label_boss", { _d = "Patr\195\163o" }),
        grade      = state.bossGrade,
    }
end

local function addTransaction(tx, epoch)
    state.nextTxId = (state.nextTxId or 0) + 1
    tx.id     = state.nextTxId
    tx.ts     = os.date(TIME_FMT, epoch or os.time())
    tx.origin = tx.origin or "bossmenu"
    table.insert(state.transactions, 1, tx)
end

local function logTransaction(txType, amount, method, note, target)
    local actor = getBossInfo()
    addTransaction({
        type              = txType,
        amount            = amount,
        method            = method,
        identifier        = actor.identifier,
        name              = actor.name,
        grade             = actor.grade,
        target_identifier = target and target.identifier or nil,
        target_name       = target and target.name or nil,
        note              = (note and note ~= "" and tostring(note)) or nil,
        balance_after     = state.balance,
    })
end

-- Lazily seeds 18 fake transactions over the last 14 days
local function seedTransactions()
    if state.transactions then return end
    state.transactions = {}

    -- Everyone except the boss can be the actor
    local pool = {}
    for _, e in ipairs(state.employees) do
        if e.identifier ~= state.bossIdentifier then
            pool[#pool + 1] = e
        end
    end
    if #pool == 0 then return end

    local seeded = {}
    for _ = 1, 18 do
        local actor = pool[math.random(1, #pool)]
        local roll  = math.random()
        local tx = {
            epoch      = os.time() - math.random(1, 1209600),
            identifier = actor.identifier,
            name       = actor.name,
            grade      = actor.grade,
        }

        if roll < 0.45 then
            tx.type   = "deposit"
            tx.amount = math.random(4, 60) * 250
            tx.method = ({ "cash", "bank", "cash" })[math.random(1, 3)]
        elseif roll < 0.75 then
            tx.type   = "withdraw"
            tx.method = "cash"
            tx.amount = math.random(2, 30) * 250
        elseif roll < 0.9 then
            tx.type       = "income"
            tx.origin     = "okokBilling"
            tx.amount     = math.random(2, 12) * 500
            tx.identifier = nil
            tx.name       = nil
            tx.grade      = nil
            tx.note       = ("Invoice #%d"):format(math.random(1000, 9999))
        else
            local target = pool[math.random(1, #pool)]
            tx.type              = "bonus"
            tx.method            = "bank"
            tx.amount            = math.random(2, 10) * 250
            tx.target_identifier = target.identifier
            tx.target_name       = target.name
        end

        seeded[#seeded + 1] = tx
    end

    -- Oldest first
    table.sort(seeded, function(a, b) return a.epoch < b.epoch end)

    -- Walk backwards from the current balance to work out balance_after for each entry
    local running = state.balance
    for i = #seeded, 1, -1 do
        local tx = seeded[i]
        tx.balance_after = running
        if tx.type == "deposit" or tx.type == "income" then
            running = running - tx.amount
        else
            running = running + tx.amount
        end
    end

    for _, tx in ipairs(seeded) do
        local epoch = tx.epoch
        tx.epoch = nil
        addTransaction(tx, epoch)
    end
end

---------------------------------------------------------------------
-- Public API (callback style: cb(result))
---------------------------------------------------------------------

function Showcase.canOpen(_, cb)
    cb(true)
end

function Showcase.getPlayerInfo(src, cb)
    init()

    local firstName = tr("lua_label_boss", { _d = "Patr\195\163o" })
    local fullName  = firstName
    local identifier = ("showcase:boss:%s"):format(tostring(src or 0))

    local player = Framework and Framework.GetPlayerFromId and Framework.GetPlayerFromId(src) or nil

    if player then
        if player.get then
            if player.get("firstName") then
                firstName = player.get("firstName") or firstName
                local lastName = player.get("lastName") or ""
                fullName = (firstName .. " " .. lastName):gsub("^%s+", ""):gsub("%s+$", "")
            end
        elseif player.getName then
            firstName = player.getName() or firstName
            fullName  = firstName
        end

        if player.getIdentifier then
            identifier = player.getIdentifier() or identifier
        end
    end

    state.bossIdentifier = identifier

    -- Make sure the boss exists in the employee list
    local idx = findEmployeeIndex(identifier)
    if idx then
        local boss = state.employees[idx]
        boss.name   = fullName
        boss.online = true
        boss.grade  = state.bossGrade
    else
        table.insert(state.employees, 1, {
            identifier = identifier,
            source     = src,
            name       = fullName,
            grade      = state.bossGrade,
            gradeLabel = "",
            online     = true,
        })
    end

    local company = getCompanyInfo()
    cb({
        firstName  = firstName,
        identifier = identifier,
        playerName = fullName,
        job = {
            name        = company.job,
            grade       = state.bossGrade,
            label       = company.name,
            grade_label = tr("lua_label_chief", { _d = "Chefe" }),
            grade_name  = "boss",
        },
        company  = company,
        isBoss   = true,
        myGrade  = state.bossGrade,
        myAccess = "full",
        settings = {
            allowedGrades = {},
            tabAccess     = {},
        },
    })
end

function Showcase.getCompanyData(_, cb)
    init()
    cb({
        balance   = state.balance,
        employees = getSortedEmployees(),
        ranks     = state.ranks,
    })
end

function Showcase.listOnlinePlayers(_, cb)
    init()
    cb(state.candidates)
end

function Showcase.hireEmployee(_, cb, target, grade)
    init()

    local idx = findCandidateIndex(target)
    if not idx then
        return cb(false)
    end

    local candidate = table.remove(state.candidates, idx)
    table.insert(state.employees, {
        identifier = candidate.identifier,
        source     = candidate.source,
        name       = candidate.name,
        grade      = tonumber(grade) or 0,
        gradeLabel = "",
        online     = true,
    })
    cb(true)
end

function Showcase.setEmployeeGrade(_, cb, identifier, grade)
    init()

    local idx = findEmployeeIndex(identifier)
    if not idx then
        return cb(false)
    end

    state.employees[idx].grade = tonumber(grade) or 0
    cb(true)
end

function Showcase.fireEmployee(_, cb, identifier)
    init()

    local idx = findEmployeeIndex(identifier)
    if not idx then
        return cb(false)
    end
    if identifier == state.bossIdentifier then
        return cb(false) -- the boss can't fire themselves
    end

    table.remove(state.employees, idx)
    cb(true)
end

function Showcase.setGradeSalary(_, cb, grade, salary)
    init()

    grade  = tonumber(grade)
    salary = tonumber(salary)
    if not (grade and salary) or salary < 0 then
        return cb(false)
    end

    for _, rank in ipairs(state.ranks) do
        if tonumber(rank.grade) == grade then
            rank.salary = salary
            return cb(true)
        end
    end
    cb(false)
end

function Showcase.getTransactions(_, cb)
    init()
    seedTransactions()
    cb({
        rows    = state.transactions,
        limit   = 500,
        enabled = true,
    })
end

function Showcase.depositMoney(_, cb, amount, note)
    init()
    seedTransactions()

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end

    state.balance = state.balance + amount
    logTransaction("deposit", amount, "cash", note)
    cb({ ok = true })
end

function Showcase.withdrawMoney(_, cb, amount, note)
    init()
    seedTransactions()

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end
    if amount > state.balance then
        return cb({ ok = false, error = "insufficient_society" })
    end

    state.balance = state.balance - amount
    logTransaction("withdraw", amount, "cash", note)
    cb({ ok = true })
end

function Showcase.payBonus(_, cb, identifier, amount, note)
    init()
    seedTransactions()

    amount = tonumber(amount) or 0
    if amount <= 0 then
        return cb({ ok = false, error = "invalid_amount" })
    end

    local idx = findEmployeeIndex(identifier)
    if not idx then
        return cb({ ok = false, error = "not_member" })
    end
    if amount > state.balance then
        return cb({ ok = false, error = "insufficient_society" })
    end

    state.balance = state.balance - amount
    logTransaction("bonus", amount, "bank", note, state.employees[idx])
    cb({ ok = true })
end

function Showcase.addRank(_, cb, data)
    init()
    data = data or {}

    local grade  = tonumber(data.grade)
    local label  = tostring(data.label or ""):sub(1, 60)
    local salary = tonumber(data.salary) or 0

    if not grade or grade < 0 or label == "" or salary < 0 then
        return cb({ ok = false, error = "invalid" })
    end

    for _, rank in ipairs(state.ranks) do
        if tonumber(rank.grade) == grade then
            return cb({ ok = false, error = "grade_exists" })
        end
    end

    -- Build an internal name from the label: lowercase, non-alphanumerics -> "_", trimmed
    local name = label:lower()
        :gsub("[^%w]", "_")
        :gsub("_+", "_")
        :gsub("^_+", "")
        :gsub("_+$", "")
    if name == "" then
        name = "grade" .. grade
    end

    table.insert(state.ranks, {
        name   = name,
        label  = label,
        grade  = grade,
        salary = salary,
    })
    table.sort(state.ranks, function(a, b)
        return tonumber(a.grade) < tonumber(b.grade)
    end)

    cb({ ok = true })
end

function Showcase.updateRankLabel(_, cb, grade, label)
    init()

    grade = tonumber(grade)
    label = tostring(label or ""):sub(1, 60)
    if not grade or label == "" then
        return cb({ ok = false })
    end

    for _, rank in ipairs(state.ranks) do
        if tonumber(rank.grade) == grade then
            rank.label = label
            return cb({ ok = true })
        end
    end
    cb({ ok = false })
end

function Showcase.deleteRank(_, cb, grade)
    init()

    grade = tonumber(grade)
    if not grade then
        return cb({ ok = false, error = "invalid" })
    end

    -- Boss grades are protected
    for _, bossGrade in ipairs(state.company.bossGrades or {}) do
        if tonumber(bossGrade) == grade then
            return cb({ ok = false, error = "is_boss_grade" })
        end
    end

    -- Can't delete a rank that still has members
    local members = 0
    for _, e in ipairs(state.employees) do
        if tonumber(e.grade) == grade then
            members = members + 1
        end
    end
    if members > 0 then
        return cb({ ok = false, error = "has_members", count = members })
    end

    for i, rank in ipairs(state.ranks) do
        if tonumber(rank.grade) == grade then
            table.remove(state.ranks, i)
            return cb({ ok = true })
        end
    end
    cb({ ok = false })
end

function Showcase.getCompanySettings(_, cb)
    cb({
        allowedGrades = {},
        tabAccess     = {},
    })
end

function Showcase.setCompanySettings(_, cb, _)
    cb(true)
end

---------------------------------------------------------------------
-- Timesheet
---------------------------------------------------------------------

function Showcase.getTimesheet(_, cb)
    init()
    generateShifts()
    refreshOpenShifts()
    cb({
        shifts       = state.shifts,
        isBoss       = true,
        myIdentifier = state.bossIdentifier,
    })
end

function Showcase.clockIn(_, cb, identifier)
    init()
    generateShifts()

    local bossId = state.bossIdentifier
    local id = (identifier and identifier ~= "") and identifier or bossId
    if not id then
        return cb({ ok = false, error = "no_id" })
    end

    -- Already clocked in?
    for _, shift in ipairs(state.shifts) do
        if shift.identifier == id and not shift.out_time then
            return cb({ ok = false, error = "already_open" })
        end
    end

    local empIdx   = findEmployeeIndex(id)
    local employee = state.employees[empIdx or 0]
    local name  = (employee and employee.name) or tr("lua_label_employee", { _d = "Empregado" })
    local grade = (employee and employee.grade) or 0

    table.insert(state.shifts, 1, {
        id         = state.nextShiftId,
        identifier = id,
        name       = name,
        grade      = grade,
        in_time    = os.date(TIME_FMT, os.time()),
        out_time   = nil,
        secs       = 0,
    })
    state.nextShiftId = state.nextShiftId + 1

    if empIdx then
        state.employees[empIdx].online = true
    end
    cb({ ok = true })
end

function Showcase.clockOut(_, cb, shiftId)
    init()

    shiftId = tonumber(shiftId)
    if not shiftId then
        return cb({ ok = false, error = "no_id" })
    end

    for _, shift in ipairs(state.shifts) do
        if shift.id == shiftId then
            if shift.out_time then
                return cb({ ok = false, error = "already_closed" })
            end

            local startTime = parseTime(shift.in_time) or os.time()
            local now = os.time()

            shift.out_time = os.date(TIME_FMT, now)
            shift.secs     = math.max(0, now - startTime)
            return cb({ ok = true })
        end
    end

    cb({ ok = false, error = "not_found" })
end

function Showcase.clearTimesheet(_, cb)
    init()
    state.shifts          = {}
    state.nextShiftId     = 1
    state.shiftsGenerated = true
    cb(true)
end

