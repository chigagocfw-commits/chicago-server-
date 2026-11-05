local function fireDepositHook(payload)
  if Framework and Framework.onDeposit then
    pcall(function()
      Framework:onDeposit(payload)
    end)
  end
end

local function fireWithdrawalHook(payload)
  if Framework and Framework.onWithdrawal then
    pcall(function()
      Framework:onWithdrawal(payload)
    end)
  end
end

local function societyAccount(jobName)
  jobName = tostring(jobName or "")
  if jobName == "" then
    return nil
  end

  local jobs = Config and Config.Societies and Config.Societies.Jobs
  if jobs then
    local config = jobs[jobName] or jobs[jobName:lower()] or jobs[jobName:upper()]
    if config and config.AccountNumber and config.AccountNumber ~= "" then
      return tostring(config.AccountNumber)
    end

    local normalized = jobName:upper()
    for _, jobConfig in pairs(jobs) do
      if jobConfig and jobConfig.AccountNumber and tostring(jobConfig.AccountNumber):upper() == normalized then
        return tostring(jobConfig.AccountNumber)
      end
    end
  end

  if Society and Society.getAccountNumber then
    local accountNumber = Society:getAccountNumber(jobName)
    if accountNumber and accountNumber ~= "" then
      return accountNumber
    end
  end

  return nil
end

local function defaultAccountForIdentifier(identifier)
  local rows = MySQL.query.await(
    " SELECT account_number FROM bablo_bank_accounts WHERE owner = ? AND is_default = 1 LIMIT 1 ",
    { identifier }
  )

  return rows and rows[1] and rows[1].account_number or nil
end

local function identifierForSource(playerSource)
  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(playerSource)
  if not player then
    return nil
  end

  return Framework and Framework.getCharacterIdentifier and Framework:getCharacterIdentifier(player) or nil
end

local function jobForSource(playerSource)
  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(playerSource)
  if not player then
    return nil
  end

  if Framework.getPlayerJobData then
    local job = Framework:getPlayerJobData(player)
    return job and job.name or nil
  end

  return nil
end

local function getCardAccount(cardNumber)
  cardNumber = tostring(cardNumber or ""):gsub("%s", "")
  if cardNumber == "" then
    return nil, "CARD_NOT_FOUND"
  end

  local rows = MySQL.query.await(
    "SELECT account_number, state, credit_limit FROM bablo_bank_cards WHERE card_number = ? LIMIT 1",
    { cardNumber }
  )

  if not rows or not rows[1] then
    return nil, "CARD_NOT_FOUND"
  end

  if tonumber(rows[1].state or 0) ~= 0 then
    return nil, "CARD_FROZEN"
  end

  return rows[1].account_number, nil, rows[1]
end

local function accountExists(accountNumber)
  local rows = MySQL.query.await(
    "SELECT account_number, owner, balance, is_default, is_frozen FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
    { tostring(accountNumber or "") }
  )

  return rows and rows[1] or nil
end

local function isDefaultAccount(account)
  return tonumber(account and account.is_default or 0) == 1
end

local function getFrameworkPlayer(playerSource)
  if not playerSource or not Framework or not Framework.fetchPlayer then
    return nil
  end

  return Framework:fetchPlayer(playerSource)
end

local function getAccountBalance(account, playerSource)
  if not account then
    return nil
  end

  if isDefaultAccount(account) then
    local player = getFrameworkPlayer(playerSource)
    if player and Framework.getPlayerMoney then
      return tonumber(Framework:getPlayerMoney(player, "bank") or 0) or 0
    end
  end

  return tonumber(account.balance or 0) or 0
end

local function createTransaction(accountNumber, transactionType, amount, text, cardNumber)
  MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, text, amount, created_at)
VALUES (?, ?, ?, ?, ?, NOW())]], {
    accountNumber,
    cardNumber or "",
    transactionType,
    text or transactionType,
    amount
  })
end

local function addMoney(accountNumber, amount, text, source, cardNumber)
  accountNumber = tostring(accountNumber or "")
  amount = tonumber(amount)

  if accountNumber == "" or not amount or amount <= 0 then
    return {
      success = false,
      message = "INVALID_PARAMS"
    }
  end

  local account = accountExists(accountNumber)
  if not account then
    return {
      success = false,
      message = "ACCOUNT_NOT_FOUND"
    }
  end

  if tonumber(account.is_frozen or 0) == 1 then
    return {
      success = false,
      message = "ACCOUNT_FROZEN"
    }
  end

  if isDefaultAccount(account) then
    local player = getFrameworkPlayer(source)
    if not player or not Framework.addPlayerMoney then
      return {
        success = false,
        message = "PLAYER_NOT_FOUND"
      }
    end

    Framework:addPlayerMoney(player, "bank", amount)
  else
    MySQL.query.await(
      "UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?",
      { amount, accountNumber }
    )
  end

  createTransaction(accountNumber, "deposit", amount, text or "External deposit", cardNumber)
  fireDepositHook({
    accountNumber = accountNumber,
    amount = amount,
    source = source,
    cardNumber = cardNumber
  })

  return {
    success = true,
    accountNumber = accountNumber,
    amount = amount,
    newBalance = isDefaultAccount(account) and getAccountBalance(account, source) or ((tonumber(account.balance) or 0) + amount)
  }
end

local function removeMoney(accountNumber, amount, text, source, cardNumber, allowNegative)
  accountNumber = tostring(accountNumber or "")
  amount = tonumber(amount)

  if accountNumber == "" or not amount or amount <= 0 then
    return {
      success = false,
      message = "INVALID_PARAMS"
    }
  end

  local account = accountExists(accountNumber)
  if not account then
    return {
      success = false,
      message = "ACCOUNT_NOT_FOUND"
    }
  end

  if tonumber(account.is_frozen or 0) == 1 then
    return {
      success = false,
      message = "ACCOUNT_FROZEN"
    }
  end

  local balance = getAccountBalance(account, source) or 0
  if not allowNegative and balance < amount then
    return {
      success = false,
      message = "INSUFFICIENT_FUNDS"
    }
  end

  if isDefaultAccount(account) then
    local player = getFrameworkPlayer(source)
    if not player or not Framework.removePlayerMoney then
      return {
        success = false,
        message = "PLAYER_NOT_FOUND"
      }
    end

    if not Framework:removePlayerMoney(player, "bank", amount) then
      return {
        success = false,
        message = "INSUFFICIENT_FUNDS"
      }
    end
  else
    MySQL.query.await(
      "UPDATE bablo_bank_accounts SET balance = balance - ? WHERE account_number = ?",
      { amount, accountNumber }
    )
  end

  createTransaction(accountNumber, "withdraw", -amount, text or "External withdrawal", cardNumber)
  fireWithdrawalHook({
    accountNumber = accountNumber,
    amount = amount,
    source = source,
    cardNumber = cardNumber
  })

  return {
    success = true,
    accountNumber = accountNumber,
    amount = amount,
    newBalance = isDefaultAccount(account) and getAccountBalance(account, source) or (balance - amount)
  }
end

exports("AddMoney", addMoney)

exports("RemoveMoney", function(accountNumber, amount, text, source, cardNumber)
  return removeMoney(accountNumber, amount, text, source, cardNumber)
end)

exports("RemoveMoneyByCard", function(cardNumber, amount, text, source)
  local accountNumber, errorMessage = getCardAccount(cardNumber)
  if not accountNumber then
    return {
      success = false,
      message = errorMessage
    }
  end

  return removeMoney(accountNumber, amount, text, source, tostring(cardNumber))
end)

exports("AddMoneyByCard", function(cardNumber, amount, text, source)
  local accountNumber, errorMessage = getCardAccount(cardNumber)
  if not accountNumber then
    return {
      success = false,
      message = errorMessage
    }
  end

  return addMoney(accountNumber, amount, text, source, tostring(cardNumber))
end)

exports("AddSocietyMoney", function(jobName, amount, text, source)
  local accountNumber = societyAccount(jobName)
  if not accountNumber then
    return {
      success = false,
      message = "INVALID_SOCIETY"
    }
  end

  return addMoney(accountNumber, amount, text, source)
end)

exports("GetSocietyBalance", function(jobName)
  if Society and Society.getBalance then
    return Society:getBalance(jobName)
  end

  local accountNumber = societyAccount(jobName)
  if not accountNumber then
    return 0
  end

  return exports["bablo-banking"]:GetBalance(accountNumber) or 0
end)

exports("RemoveSocietyMoney", function(jobName, amount, text, source)
  local accountNumber = societyAccount(jobName)
  if not accountNumber then
    return {
      success = false,
      message = "INVALID_SOCIETY"
    }
  end

  return removeMoney(accountNumber, amount, text, source)
end)

exports("AddSocietyMoneyForSource", function(playerSource, amount, text)
  local jobName = jobForSource(playerSource)
  if not jobName then
    return {
      success = false,
      message = "NO_JOB"
    }
  end

  return exports["bablo-banking"]:AddSocietyMoney(jobName, amount, text, playerSource)
end)

exports("RemoveSocietyMoneyForSource", function(playerSource, amount, text)
  local jobName = jobForSource(playerSource)
  if not jobName then
    return {
      success = false,
      message = "NO_JOB"
    }
  end

  return exports["bablo-banking"]:RemoveSocietyMoney(jobName, amount, text, playerSource)
end)

exports("RemoveDefaultByCard", function(cardNumber, amount, text, source)
  return exports["bablo-banking"]:RemoveMoneyByCard(cardNumber, amount, text, source)
end)

exports("AddDefaultByCard", function(cardNumber, amount, text, source)
  return exports["bablo-banking"]:AddMoneyByCard(cardNumber, amount, text, source)
end)

exports("GetAccountFromCard", function(cardNumber)
  local accountNumber = getCardAccount(cardNumber)
  return accountNumber
end)

exports("GetBalance", function(accountNumber, playerSource)
  local account = accountExists(accountNumber)
  return getAccountBalance(account, playerSource)
end)

exports("GetBalanceFromCard", function(cardNumber, playerSource)
  local accountNumber = getCardAccount(cardNumber)
  return accountNumber and exports["bablo-banking"]:GetBalance(accountNumber, playerSource) or nil
end)

exports("GetDefaultAccountNumber", function(playerSourceOrIdentifier)
  local identifier = tonumber(playerSourceOrIdentifier) and identifierForSource(playerSourceOrIdentifier) or tostring(playerSourceOrIdentifier or "")
  if identifier == "" then
    return nil
  end

  return defaultAccountForIdentifier(identifier)
end)

exports("CreateTransaction", function(accountNumber, transactionType, amount, text, cardNumber)
  if not accountNumber or not transactionType or not amount then
    return {
      success = false,
      message = "INVALID_PARAMS"
    }
  end

  createTransaction(tostring(accountNumber), transactionType, amount, text, cardNumber)

  return {
    success = true
  }
end)

exports("CreateDefaultTransaction", function(playerSourceOrIdentifier, transactionType, amount, text, cardNumber)
  local accountNumber = exports["bablo-banking"]:GetDefaultAccountNumber(playerSourceOrIdentifier)
  if not accountNumber then
    return {
      success = false,
      message = "DEFAULT_ACCOUNT_NOT_FOUND"
    }
  end

  return exports["bablo-banking"]:CreateTransaction(accountNumber, transactionType, amount, text, cardNumber)
end)

exports("GetCardPinByNumber", function(cardNumber)
  local rows = MySQL.query.await(
    "SELECT pin FROM bablo_bank_cards WHERE card_number = ? LIMIT 1",
    { tostring(cardNumber or "") }
  )

  return rows and rows[1] and rows[1].pin or nil
end)

local function setAccountFrozen(accountNumber, frozen, source)
  accountNumber = tostring(accountNumber or "")
  if accountNumber == "" then
    return {
      success = false,
      message = "INVALID_PARAMS"
    }
  end

  local account = accountExists(accountNumber)
  if not account then
    return {
      success = false,
      message = "ACCOUNT_NOT_FOUND"
    }
  end

  local state = frozen and 1 or 0
  local currentlyFrozen = tonumber(account.is_frozen or 0) == 1
  if currentlyFrozen == frozen then
    return {
      success = true,
      isFrozen = currentlyFrozen
    }
  end

  if not MySQL.query.await("UPDATE bablo_bank_accounts SET is_frozen = ? WHERE account_number = ?", { state, accountNumber }) then
    return {
      success = false,
      message = "DB_ERROR"
    }
  end

  if source and type(sendWebhook) == "function" then
    sendWebhook(source, frozen and "ACCOUNT_FROZEN" or "ACCOUNT_UNFROZEN", "Account: " .. tostring(accountNumber))
  end

  return {
    success = true,
    isFrozen = frozen
  }
end

exports("FreezeAccount", function(accountNumber, source)
  return setAccountFrozen(accountNumber, true, source)
end)

exports("UnfreezeAccount", function(accountNumber, source)
  return setAccountFrozen(accountNumber, false, source)
end)

exports("IsAccountFrozen", function(accountNumber)
  local account = accountExists(accountNumber)
  return account and tonumber(account.is_frozen or 0) == 1 or nil
end)

exports("RegisterSociety", function(jobName, options)
  jobName = tostring(jobName or ""):gsub("^society_", "")
  if jobName == "" then
    return {
      success = false,
      message = "INVALID_JOB"
    }
  end

  options = options or {}
  local accountNumber = tostring(options.accountNumber or options.AccountNumber or "")
  if accountNumber == "" then
    return {
      success = false,
      message = "INVALID_ACCOUNT_NUMBER"
    }
  end

  local label = tostring(options.label or options.Label or (Translate and Translate("SOCIETY_ACCOUNT")) or "Society Account")
  local access = options.access or options.Access or {}

  local account = accountExists(accountNumber)
  if not account then
    MySQL.insert.await([[
INSERT INTO bablo_bank_accounts (account_number, owner, name, balance, type, is_default, is_frozen)
VALUES (?, NULL, ?, 0, 'shared', 0, 0)]], { accountNumber, label })
  end

  Config.Societies = Config.Societies or {}
  Config.Societies.Enabled = true
  Config.Societies.Jobs = Config.Societies.Jobs or {}
  Config.Societies.Jobs[jobName] = {
    AccountNumber = accountNumber,
    Label = label,
    Access = access
  }

  return {
    success = true,
    job = jobName,
    accountNumber = accountNumber,
    label = label
  }
end)

exports("IsCardFrozen", function(cardNumber)
  local rows = MySQL.query.await(
    "SELECT state as is_frozen FROM bablo_bank_cards WHERE card_number = ? LIMIT 1",
    { cardNumber }
  )

  return rows and rows[1] and tonumber(rows[1].is_frozen or 0) ~= 0 or nil
end)

local function transactionsToCsv(transactions)
  if not transactions or #transactions == 0 then
    return ""
  end

  local lines = { "Date,Type,Amount,Description,Account,CardNumber" }

  for _, transaction in ipairs(transactions) do
    local description = tostring(transaction.name or ""):gsub("\"", "\"\"")
    table.insert(lines, string.format(
      "\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"",
      tostring(transaction.date or ""),
      tostring(transaction.type or ""),
      tostring(transaction.amount or ""),
      description,
      tostring(transaction.accountIban or ""),
      tostring(transaction.cardNumber or "")
    ))
  end

  return table.concat(lines, "\n")
end

local function queryTransactions(accountNumber, days, maxRows)
  local dateFilter = ""

  if days and days ~= -1 then
    local dayCount = tonumber(days) or 7
    local startExpression = dayCount <= 1 and "CURDATE()" or ("DATE_SUB(CURDATE(), INTERVAL " .. tostring(dayCount - 1) .. " DAY)")
    dateFilter = " AND created_at >= " .. startExpression
  end

  local limitClause = maxRows and maxRows > 0 and (" LIMIT " .. tostring(maxRows)) or ""

  return MySQL.query.await([[
SELECT type, text, amount, created_at, card_number
FROM bablo_bank_transactions
WHERE account_number = ?]] .. dateFilter .. [[
ORDER BY created_at DESC]] .. limitClause, { accountNumber })
end

local function formatTransactions(rows, accountNumber)
  local transactions = {}

  for index, row in ipairs(rows or {}) do
    local transactionType = row.type or "transfer"
    if transactionType ~= "withdraw" and transactionType ~= "deposit" then
      transactionType = "transfer"
    end

    local date = os.date("%Y-%m-%d")
    if row.created_at then
      if type(row.created_at) == "number" then
        local timestamp = row.created_at > 10000000000 and math.floor(row.created_at / 1000) or row.created_at
        local ok, formattedDate = pcall(function()
          return os.date("%Y-%m-%d", timestamp)
        end)
        date = ok and formattedDate or date
      elseif type(row.created_at) == "string" then
        date = row.created_at:match("(%d%d%d%d%-%d%d%-%d%d)") or os.date("%Y-%m-%d", TimestampToUnix(row.created_at))
      end
    end

    local cardNumber = row.card_number and tostring(row.card_number):gsub("%s", "") or nil

    table.insert(transactions, {
      id = index,
      type = transactionType,
      name = row.text or "Unknown Transaction",
      date = date,
      amount = tonumber(row.amount) or 0,
      accountIban = accountNumber,
      cardNumber = cardNumber
    })
  end

  return transactions
end

exports("ExportAccountTransactionsByIdentifier", function(identifier, accountNumber, options)
  options = options or {}

  local access = MySQL.query.await([[
SELECT COUNT(*) as count
FROM bablo_bank_account_users
WHERE identifier = ? AND account_number = ?]], { identifier, accountNumber })

  if not access or not access[1] or access[1].count == 0 then
    return {
      success = false,
      message = "NO_ACCESS"
    }
  end

  local rows = queryTransactions(accountNumber, options.days or -1, options.all == true and nil or options.maxRows)
  local transactions = formatTransactions(rows, accountNumber)

  return {
    success = true,
    data = options.format == "csv" and transactionsToCsv(transactions) or transactions
  }
end)

exports("ExportAccountTransactions", function(playerSource, accountNumber, options)
  local identifier = identifierForSource(playerSource)
  if not identifier then
    return {
      success = false,
      message = "NO_IDENTIFIER"
    }
  end

  return exports["bablo-banking"]:ExportAccountTransactionsByIdentifier(identifier, accountNumber, options)
end)

exports("ExportSocietyTransactions", function(playerSource, jobName, options)
  local accountNumber = societyAccount(jobName)
  if not accountNumber then
    return {
      success = false,
      message = "INVALID_SOCIETY"
    }
  end

  return exports["bablo-banking"]:ExportAccountTransactions(playerSource, accountNumber, options)
end)

exports("GetCreditLimitFromCard", function(cardNumber)
  local rows = MySQL.query.await(
    "SELECT credit_limit FROM bablo_bank_cards WHERE card_number = ? LIMIT 1",
    { cardNumber }
  )

  if not rows or not rows[1] then
    return nil
  end

  local creditLimit = tonumber(rows[1].credit_limit or 0) or 0
  local spentRows = MySQL.query.await([[
SELECT COALESCE(SUM(ABS(amount)),0) as spent
FROM bablo_bank_transactions
WHERE card_number = ? AND type = 'withdraw' AND created_at >= NOW() - INTERVAL 1 DAY]], { tostring(cardNumber) })

  local spent = spentRows and spentRows[1] and tonumber(spentRows[1].spent or 0) or 0
  return creditLimit, spent
end)
