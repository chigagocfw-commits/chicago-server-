-- Backward-compatible society API exports and events

if not IsDuplicityVersion() then return end

local societiesEnabled = (Config and Config.Societies and Config.Societies.Enabled) or false

local function normalizeJobName(name)
    if not name then return nil end
    if type(name) == 'table' and name.name then name = name.name end
    name = tostring(name)
    if name:sub(1, 9) == 'society_' then
        name = name:sub(10)
    end
    return name
end

local function getAccountNumberForJob(job)
    if Society and Society.getAccountNumber then
        return Society:getAccountNumber(job)
    end
    local cfg = Config and Config.Societies and Config.Societies.Jobs and Config.Societies.Jobs[job]
    return cfg and cfg.AccountNumber or nil
end

local function getLabelForJob(job)
    if Society and Society.getAccountLabel then
        return Society:getAccountLabel(job)
    end
    local cfg = Config and Config.Societies and Config.Societies.Jobs and Config.Societies.Jobs[job]
    return (cfg and cfg.Label) or job
end

local function GetSocietyAccountMoney(society)
    local job = normalizeJobName(society)
    if not job then return 0 end
    if societiesEnabled and Society and Society.getBalance then
        return Society:getBalance(job)
    end
    local acc = getAccountNumberForJob(job)
    if not acc then return 0 end
    local row = MySQL.query.await('SELECT balance FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1', { acc })
    return (row and row[1] and tonumber(row[1].balance)) or 0
end

local function AddSocietyMoney(society, amount)
    amount = tonumber(amount) or 0
    if amount <= 0 then return false end
    local job = normalizeJobName(society)
    if not job then return false end
    if societiesEnabled and Society and Society.addMoney then
        return Society:addMoney(job, amount) and true or false
    end
    local acc = getAccountNumberForJob(job)
    if not acc then return false end
    local ok = MySQL.query.await('UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?',
        { amount, acc })
    return ok ~= nil
end

local function RemoveSocietyMoney(society, amount)
    amount = tonumber(amount) or 0

    if amount <= 0 then return false end
    local job = normalizeJobName(society)

    if not job then return false end
    if societiesEnabled and Society and Society.removeMoney then
        return Society:removeMoney(job, amount) and true or false
    end
    local acc = getAccountNumberForJob(job)
    if not acc then return false end
    local ok = MySQL.query.await(
        'UPDATE bablo_bank_accounts SET balance = GREATEST(0, balance - ?) WHERE account_number = ?',
        { amount, acc })
    return ok ~= nil
end

local function GetSocietyAccount(society)
    local job = normalizeJobName(society)
    if not job then return nil end
    local acc = getAccountNumberForJob(job)
    local balance = GetSocietyAccountMoney(job)
    return {
        name = job,
        label = getLabelForJob(job),
        account = acc,
        balance = balance,
    }
end

-- expose also as globals for older scripts
_G.GetSocietyAccountMoney = GetSocietyAccountMoney
_G.AddSocietyMoney = AddSocietyMoney
_G.RemoveSocietyMoney = RemoveSocietyMoney
_G.GetSocietyAccount = GetSocietyAccount

local function exportHandler(resource, name, cb)
    AddEventHandler(('__cfx_export_%s_%s'):format(resource, name), function(setCB)
        setCB(cb)
    end)
end

CreateThread(function()
    if not societiesEnabled then
        return
    end

    -- qb-management compatibility
    exportHandler('qb-management', 'GetAccount', GetSocietyAccountMoney)
    exportHandler('qb-management', 'AddMoney', AddSocietyMoney)
    exportHandler('qb-management', 'RemoveMoney', RemoveSocietyMoney)

    -- qb-banking compatibility
    exportHandler('qb-banking', 'GetAccount', GetSocietyAccount)
    exportHandler('qb-banking', 'AddMoney', AddSocietyMoney)
    exportHandler('qb-banking', 'RemoveMoney', RemoveSocietyMoney)
    exportHandler('qb-banking', 'GetAccountBalance', GetSocietyAccountMoney)

    -- esx_society compatibility (event-based)
    AddEventHandler('esx_society:getSociety', function(name, cb)
        if type(cb) ~= 'function' then return end
        local job = normalizeJobName(name)
        local balance = GetSocietyAccountMoney(job)
        cb({ name = 'society_' .. tostring(job), money = balance })
    end)
    AddEventHandler('esx_society:depositMoney', function(name, amount)
        AddSocietyMoney(name, amount)
    end)
    AddEventHandler('esx_society:withdrawMoney', function(name, amount)
        RemoveSocietyMoney(name, amount)
    end)

    -- esx_addonaccount compatibility (event-based)
    AddEventHandler('esx_addonaccount:getSharedAccount', function(name, cb)
        if type(cb) ~= 'function' then return end
        local job = normalizeJobName(name)
        local balance = GetSocietyAccountMoney(job)
        cb({
            name = 'society_' .. tostring(job),
            money = balance,
            owner = nil, -- shared account
            addMoney = function(amount)
                AddSocietyMoney(job, amount)
            end,
            removeMoney = function(amount)
                RemoveSocietyMoney(job, amount)
            end,
            getMoney = function()
                return GetSocietyAccountMoney(job)
            end,
            setMoney = function(amount)
                local current = GetSocietyAccountMoney(job)
                local diff = tonumber(amount) - current
                if diff > 0 then
                    AddSocietyMoney(job, diff)
                elseif diff < 0 then
                    RemoveSocietyMoney(job, math.abs(diff))
                end
            end
        })
    end)
    AddEventHandler('esx_addonaccount:addMoney', function(name, amount)
        AddSocietyMoney(name, amount)
    end)
    AddEventHandler('esx_addonaccount:removeMoney', function(name, amount)
        RemoveSocietyMoney(name, amount)
    end)

    -- esx_addonaccount exports compatibility
    exportHandler('esx_addonaccount', 'GetSharedAccount', function(name)
        local job = normalizeJobName(name)
        local balance = GetSocietyAccountMoney(job)
        return {
            name = 'society_' .. tostring(job),
            money = balance,
            owner = nil,
            addMoney = function(self, amount)
                AddSocietyMoney(job, amount)
            end,
            removeMoney = function(self, amount)
                RemoveSocietyMoney(job, amount)
            end,
            getMoney = function(self)
                return GetSocietyAccountMoney(job)
            end,
            setMoney = function(self, amount)
                local current = GetSocietyAccountMoney(job)
                local diff = tonumber(amount) - current
                if diff > 0 then
                    AddSocietyMoney(job, diff)
                elseif diff < 0 then
                    RemoveSocietyMoney(job, math.abs(diff))
                end
            end
        }
    end)

    -- Renewed-Banking compatibility
    exportHandler('Renewed-Banking', 'getAccountMoney', GetSocietyAccountMoney)
    exportHandler('Renewed-Banking', 'addAccountMoney', AddSocietyMoney)
    exportHandler('Renewed-Banking', 'removeAccountMoney', RemoveSocietyMoney)
end)