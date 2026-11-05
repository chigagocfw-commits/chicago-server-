local cardUseCooldowns = {}
local CARD_USE_COOLDOWN_MS = 5000

Main = {
  isLoaded = false,
  usableItems = {
    {
      name = "bcreditcard",
      use = function(source, item)
        local metadata = item and (item.info or item.metadata) or {}
        local cardNumber = metadata.cardNumber or metadata.card_number or metadata.number
        cardNumber = cardNumber and tostring(cardNumber) or nil

        if cardNumber and cardNumber ~= "" then
          local cooldownKey = tostring(source) .. ":" .. cardNumber
          local now = GetGameTimer()
          local lastUse = cardUseCooldowns[cooldownKey] or 0

          if now - lastUse < CARD_USE_COOLDOWN_MS then
            local seconds = math.ceil((CARD_USE_COOLDOWN_MS - (now - lastUse)) / 1000)
            TriggerClientEvent(
              eventName .. "client:sendNotify",
              source,
              Translate and Translate("CARD_COOLDOWN", seconds) or ("Please wait " .. seconds .. " seconds before using this card again")
            )
            return
          end

          cardUseCooldowns[cooldownKey] = now
        end

        if Config and Config.OnlyOwnerCanUseCard and cardNumber and cardNumber ~= "" then
          local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(source)
          local identifier = player and Framework:getCharacterIdentifier(player)

          if identifier then
            local rows = MySQL.query.await([[
SELECT a.owner FROM bablo_bank_cards c
JOIN bablo_bank_accounts a ON a.account_number = c.account_number
WHERE c.card_number = ? LIMIT 1]], { cardNumber })

            local owner = rows and rows[1] and tostring(rows[1].owner or "") or ""
            if owner ~= "" and owner ~= tostring(identifier) then
              TriggerClientEvent(
                eventName .. "client:sendNotify",
                source,
                Translate and Translate("CARD_NOT_YOURS") or "This card does not belong to you"
              )
              return
            end
          end
        end

        exports["bablo-atm"]:OnCardOpen(source, item)
      end
    }
  }
}

local function fetchCharacter(source)
  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(source)
  local identifier = player and Framework.getCharacterIdentifier and Framework:getCharacterIdentifier(player)
  return player, identifier
end

local function response(success, message, data)
  local result = {
    success = success,
    message = message
  }

  if data ~= nil then
    for key, value in pairs(data) do
      result[key] = value
    end
  end

  return result
end

local function asBool(value)
  if type(value) == "boolean" then
    return value
  end

  return tonumber(value or 0) == 1
end

local function accountRow(accountNumber)
  local rows = MySQL.query.await(
    "SELECT * FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
    { tostring(accountNumber or "") }
  )

  return rows and rows[1] or nil
end

local function cardRow(cardNumber)
  local rows = MySQL.query.await(
    "SELECT * FROM bablo_bank_cards WHERE card_number = ? LIMIT 1",
    { tostring(cardNumber or "") }
  )

  return rows and rows[1] or nil
end

local function getAccountRole(accountNumber, identifier)
  local account = accountRow(accountNumber)
  if account and tostring(account.owner or "") == tostring(identifier) then
    return "owner"
  end

  local rows = MySQL.query.await(
    "SELECT role FROM bablo_bank_account_user_roles WHERE account_number = ? AND identifier = ? LIMIT 1",
    { accountNumber, identifier }
  )

  return rows and rows[1] and rows[1].role or "member"
end

local function hasPermission(accountNumber, identifier, permission)
  local role = getAccountRole(accountNumber, identifier)
  if role == "owner" or role == "admin" then
    return true
  end

  local rows = MySQL.query.await(
    ("SELECT %s FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ? LIMIT 1"):format(permission),
    { accountNumber, identifier }
  )

  return rows and rows[1] and tonumber(rows[1][permission] or 0) == 1
end

local function transactionText(key, fallback, value)
  if Translate then
    local translated = Translate(key)
    if translated and translated.format then
      return translated:format(tostring(value))
    end

    if translated then
      return translated
    end
  end

  return fallback
end

local function generateCardNumber()
  local digits = { "4" }

  for index = 2, 16 do
    digits[index] = tostring(math.random(0, 9))
  end

  return table.concat(digits)
end

local function giveCreditCardItem(source, metadata)
  local itemName = Config.CreditCardItemName or "bcreditcard"

  metadata = metadata or {}
  metadata.label = metadata.label or "Credit Card"
  metadata.description = metadata.description or ("Card ending in " .. tostring(metadata.last4 or "0000"))

  if Config.Inventory == "ox_inventory" and GetResourceState("ox_inventory") == "started" then
    local ok, result = pcall(function()
      return exports.ox_inventory:AddItem(source, itemName, 1, metadata)
    end)

    return ok and result ~= false
  end

  local player = Framework and Framework.fetchPlayer and Framework:fetchPlayer(source)
  if player and player.Functions and player.Functions.AddItem then
    local itemInfo = metadata
    local ok, result = pcall(function()
      return player.Functions.AddItem(itemName, 1, false, itemInfo)
    end)

    return ok and result ~= false
  end

  if Framework and Framework.addItem then
    local ok, result = pcall(function()
      return Framework:addItem(source, itemName, 1, metadata)
    end)

    return ok and result ~= false
  end

  return false
end

local function insertTransaction(accountNumber, transactionType, text, amount, cardNumber)
  return MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, text, amount, created_at)
VALUES (?, ?, ?, ?, ?, NOW())]], {
    accountNumber,
    cardNumber or "",
    transactionType,
    text,
    amount
  })
end

local function notifyOnline(identifier, message)
  if not Framework or not Framework.fetchPlayerByIdentifier or not Framework.getPlayerSource then
    return
  end

  local player = Framework:fetchPlayerByIdentifier(identifier)
  local targetSource = player and Framework:getPlayerSource(player)

  if targetSource then
    TriggerClientEvent(eventName .. "client:sendNotify", targetSource, message)
    TriggerClientEvent(eventName .. "client:refreshAccounts", targetSource)
  end
end

function Main:Init()
  Trace("Banking module initialized")

  if self.isLoaded then
    Trace("Banking module is already loaded")
    return
  end

  Inventory:Init()
  self.isLoaded = true

  Citizen.CreateThread(function()
    while true do
      local retentionMonths = math.max(math.floor(tonumber(Config and Config.TransactionRetentionMonths) or 1), 1)
      MySQL.query.await("DELETE FROM bablo_bank_transactions WHERE created_at < DATE_SUB(NOW(), INTERVAL " .. tostring(retentionMonths) .. " MONTH)")
      Wait(21600000)
    end
  end)
end

function Main:ToggleFreeze(source, accountNumber)
  local player, identifier = fetchCharacter(source)
  if not player or not identifier then
    return response(false, "Character not found")
  end

  local account = accountRow(accountNumber)
  if not account then
    return response(false, "ACCOUNT_NOT_FOUND")
  end

  local isOwner = tostring(account.owner or "") == tostring(identifier)
  if not isOwner and getAccountRole(accountNumber, identifier) ~= "owner" then
    return response(false, "No access to account")
  end

  local nextState = asBool(account.is_frozen) and 0 or 1
  MySQL.query.await("UPDATE bablo_bank_accounts SET is_frozen = ? WHERE account_number = ?", { nextState, accountNumber })

  sendWebhook(source, nextState == 1 and "ACCOUNT_FROZEN" or "ACCOUNT_UNFROZEN", "Account: " .. tostring(accountNumber))

  return response(true, nil, {
    isFrozen = nextState == 1
  })
end

function Main:TerminateAccount(source, accountNumber)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return response(false, "Identifier not found")
  end

  local account = accountRow(accountNumber)
  if not account then
    return response(false, "ACCOUNT_NOT_FOUND")
  end

  if asBool(account.is_default) then
    return response(false, "Cannot terminate default account")
  end

  if tostring(account.owner or "") ~= tostring(identifier) and getAccountRole(accountNumber, identifier) ~= "owner" then
    return response(false, "No access to account")
  end

  MySQL.query.await("DELETE FROM bablo_bank_account_permissions WHERE account_number = ?", { accountNumber })
  MySQL.query.await("DELETE FROM bablo_bank_account_user_roles WHERE account_number = ?", { accountNumber })
  MySQL.query.await("DELETE FROM bablo_bank_account_users WHERE account_number = ?", { accountNumber })
  MySQL.query.await("DELETE FROM bablo_bank_transactions WHERE account_number = ?", { accountNumber })
  MySQL.query.await("DELETE FROM bablo_bank_accounts WHERE account_number = ?", { accountNumber })

  sendWebhook(source, "ACCOUNT_TERMINATED", "Account: " .. tostring(accountNumber))

  return response(true, "Account terminated")
end

function Main:TransferAccountOwnership(source, accountNumber, targetSource, targetIdentifier)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return response(false, "Identifier not found")
  end

  local account = accountRow(accountNumber)
  if not account then
    return response(false, "ACCOUNT_NOT_FOUND")
  end

  if tostring(account.owner or "") ~= tostring(identifier) then
    return response(false, "Only owner can transfer account")
  end

  if not targetIdentifier and targetSource then
    local targetPlayer = Framework:fetchPlayer(targetSource)
    targetIdentifier = targetPlayer and Framework:getCharacterIdentifier(targetPlayer)
  end

  if not targetIdentifier then
    return response(false, "Target identifier not found")
  end

  MySQL.query.await("UPDATE bablo_bank_accounts SET owner = ? WHERE account_number = ?", { targetIdentifier, accountNumber })
  MySQL.query.await("DELETE FROM bablo_bank_account_users WHERE account_number = ?", { accountNumber })
  MySQL.query.await("INSERT INTO bablo_bank_account_users (account_number, identifier) VALUES (?, ?)", { accountNumber, targetIdentifier })
  MySQL.query.await("DELETE FROM bablo_bank_account_user_roles WHERE account_number = ?", { accountNumber })
  MySQL.query.await("INSERT INTO bablo_bank_account_user_roles (account_number, identifier, role) VALUES (?, ?, 'owner')", { accountNumber, targetIdentifier })

  notifyOnline(targetIdentifier, "Account ownership was transferred to you")
  sendWebhook(source, "ACCOUNT_OWNERSHIP_TRANSFERRED", "Account: " .. tostring(accountNumber) .. " | New owner: " .. tostring(targetIdentifier))

  return response(true, "Account ownership transferred", {
    newOwnerId = targetIdentifier
  })
end

function Main:CreateAccount(source, name, accountType)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return response(false, "Identifier not found")
  end

  accountType = accountType or "personal"

  local accountNumber
  repeat
    accountNumber = GenerateAccountNumber()
  until not accountRow(accountNumber)

  MySQL.insert.await([[
INSERT INTO bablo_bank_accounts (account_number, owner, name, balance, type, is_default, is_frozen)
VALUES (?, ?, ?, 0, ?, 0, 0)]], { accountNumber, identifier, name, accountType })

  MySQL.insert.await(
    "INSERT INTO bablo_bank_account_users (account_number, identifier) VALUES (?, ?)",
    { accountNumber, identifier }
  )

  MySQL.insert.await(
    "INSERT INTO bablo_bank_account_user_roles (account_number, identifier, role) VALUES (?, ?, 'owner')",
    { accountNumber, identifier }
  )

  sendWebhook(source, "ACCOUNT_CREATED", "Account: " .. accountNumber .. " | Name: " .. tostring(name))

  return response(true, "ACCOUNT_CREATED", {
    account = {
      id = accountNumber,
      iban = accountNumber,
      name = name,
      balance = 0,
      type = accountType,
      isDefault = false,
      isFrozen = false
    }
  })
end

function Main:Transfer(source, fromAccount, toAccount, toIban, amount, description)
  local player, identifier = fetchCharacter(source)
  amount = tonumber(amount)
  fromAccount = fromAccount and tostring(fromAccount) or nil
  toAccount = toAccount and tostring(toAccount) or nil
  toIban = toIban and tostring(toIban) or nil

  if not player or not identifier then
    return response(false, "Character not found")
  end

  if not fromAccount or not amount or amount <= 0 then
    return response(false, "Enter a valid transfer amount")
  end

  local sourceAccount = accountRow(fromAccount)
  if not sourceAccount then
    return response(false, "Source account not found")
  end

  local isSourceOwner = tostring(sourceAccount.owner or "") == tostring(identifier)
  if not isSourceOwner and not hasPermission(fromAccount, identifier, "can_transfer") then
    return response(false, "You do not have permission to transfer from this account")
  end

  local destinationAccountNumber = toAccount or toIban
  if not destinationAccountNumber then
    return response(false, "Enter a destination IBAN")
  end

  if tostring(destinationAccountNumber) == tostring(fromAccount) then
    return response(false, "You cannot transfer to the same account")
  end

  local destinationAccount = accountRow(destinationAccountNumber)
  if not destinationAccount then
    return response(false, "Destination account not found")
  end

  if asBool(sourceAccount.is_frozen) then
    return response(false, "Source account is frozen")
  end

  if asBool(destinationAccount.is_frozen) then
    return response(false, "Destination account is frozen")
  end

  local sourceIsDefault = asBool(sourceAccount.is_default)
  local destinationIsDefault = asBool(destinationAccount.is_default)
  local sourceBalance = sourceIsDefault and Framework:getPlayerMoney(player, "bank") or (tonumber(sourceAccount.balance) or 0)

  if amount > sourceBalance then
    return response(false, "Not enough funds")
  end

  if sourceIsDefault then
    if not Framework:removePlayerMoney(player, "bank", amount) then
      return response(false, "Not enough funds")
    end
  else
    MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance - ? WHERE account_number = ?", { amount, fromAccount })
  end

  local destinationOwner = destinationAccount.owner

  if destinationIsDefault and tostring(destinationOwner or "") ~= tostring(identifier) then
    if not destinationOwner or tostring(destinationOwner) == "" then
      if sourceIsDefault then
        Framework:addPlayerMoney(player, "bank", amount)
      else
        MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, fromAccount })
      end

      return response(false, "Recipient account owner not found")
    end
  end

  if destinationIsDefault then
    if tostring(destinationOwner or "") == tostring(identifier) then
      if not Framework:addPlayerMoney(player, "bank", amount) then
        if sourceIsDefault then
          Framework:addPlayerMoney(player, "bank", amount)
        else
          MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, fromAccount })
        end

        return response(false, "Failed to credit destination account")
      end
    elseif Framework.addOfflineMoney then
      if not Framework:addOfflineMoney(destinationOwner, "bank", amount) then
        if sourceIsDefault then
          Framework:addPlayerMoney(player, "bank", amount)
        else
          MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, fromAccount })
        end

        return response(false, "Failed to credit recipient account")
      end
    else
      if sourceIsDefault then
        Framework:addPlayerMoney(player, "bank", amount)
      else
        MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, fromAccount })
      end

      return response(false, "Offline bank transfer is not supported by this framework")
    end
  else
    MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, destinationAccountNumber })
  end

  local outText = description and ("Transfer: " .. tostring(description)) or transactionText("TRANSFER_TO", "Transfer to " .. tostring(destinationAccountNumber), destinationAccountNumber)
  local inText = description and ("Transfer: " .. tostring(description)) or transactionText("TRANSFER_FROM", "Transfer from " .. tostring(fromAccount), fromAccount)
  local transactionId = insertTransaction(fromAccount, "transfer", outText, -amount, "")
  insertTransaction(destinationAccountNumber, "transfer", inText, amount, "")

  if destinationOwner and tostring(destinationOwner) ~= tostring(identifier) then
    pcall(function()
      notifyOnline(destinationOwner, ("You received $%s to %s"):format(tostring(amount), tostring(destinationAccount.name or destinationAccountNumber)))
    end)
  end

  local newBalance = sourceIsDefault and Framework:getPlayerMoney(player, "bank") or ((tonumber(sourceAccount.balance) or 0) - amount)
  local ownerName = "Unknown Player"
  if destinationOwner and Framework.fetchOfflinePlayerName then
    local ok, fetchedName = pcall(function()
      return Framework:fetchOfflinePlayerName(destinationOwner)
    end)
    if ok and fetchedName then
      ownerName = fetchedName
    end
  end

  pcall(function()
    sendWebhook(source, "TRANSFER", "$" .. tostring(amount) .. " | From: " .. tostring(fromAccount) .. " -> To: " .. tostring(destinationAccountNumber))
  end)

  return response(true, "Transfer successful", {
    newBalance = newBalance,
    transactionId = tonumber(transactionId) or os.time(),
    recipient = tostring(destinationAccountNumber),
    recipientDetails = {
      iban = tostring(destinationAccountNumber),
      accountName = destinationAccount.name or "",
      ownerIdentifier = destinationOwner,
      ownerName = ownerName,
      isDefault = destinationIsDefault,
      isOwned = tostring(destinationOwner or "") == tostring(identifier)
    }
  })
end
function Main:getPlayerAccounts(player, identifier)
  if not identifier then
    return {}
  end

  local accountRows = MySQL.query.await([[
SELECT DISTINCT a.account_number, a.owner, a.name, a.balance, a.type, a.is_default, a.is_frozen
FROM bablo_bank_accounts a
JOIN bablo_bank_account_users u ON u.account_number = a.account_number
WHERE u.identifier = ?]], { identifier }) or {}

  local accounts = {}

  for _, account in ipairs(accountRows) do
    local accountNumber = tostring(account.account_number)
    local isDefault = asBool(account.is_default)
    local balance = isDefault and Framework:getPlayerMoney(player, "bank") or (tonumber(account.balance) or 0)
    local role = getAccountRole(accountNumber, identifier)
    local canManageCards = role == "owner" or role == "admin" or hasPermission(accountNumber, identifier, "can_manage_cards")

    table.insert(accounts, {
      id = accountNumber,
      iban = accountNumber,
      owner = account.owner,
      name = account.name,
      balance = balance,
      type = account.type or "personal",
      isDefault = isDefault,
      isFrozen = asBool(account.is_frozen),
      role = role,
      permissions = {
        canView = true,
        canDeposit = role == "owner" or role == "admin" or hasPermission(accountNumber, identifier, "can_deposit"),
        canWithdraw = role == "owner" or role == "admin" or hasPermission(accountNumber, identifier, "can_withdraw"),
        canTransfer = role == "owner" or role == "admin" or hasPermission(accountNumber, identifier, "can_transfer"),
        canManageMembers = role == "owner" or role == "admin" or hasPermission(accountNumber, identifier, "can_manage_members"),
        canCreateCard = canManageCards,
        canManageCards = canManageCards
      }
    })
  end

  return accounts
end

function Main:getAccountTransactions(identifier, accountNumber, daysFilter)
  if not identifier or not accountNumber then
    return {}
  end

  local access = MySQL.query.await([[
SELECT COUNT(*) as count
FROM bablo_bank_account_users
WHERE identifier = ? AND account_number = ?]], { identifier, accountNumber })

  if not access or not access[1] or access[1].count == 0 then
    return {}
  end

  daysFilter = daysFilter or 7
  local sql
  local params = { accountNumber }

  if daysFilter == -1 then
    sql = [[
SELECT type, text, amount, created_at, card_number
FROM bablo_bank_transactions
WHERE account_number = ?
ORDER BY created_at DESC
LIMIT 500]]
  else
    local days = tonumber(daysFilter) or 7
    local startExpression = days <= 1 and "CURDATE()" or ("DATE_SUB(CURDATE(), INTERVAL " .. tostring(days - 1) .. " DAY)")
    sql = [[
SELECT type, text, amount, created_at, card_number
FROM bablo_bank_transactions
WHERE account_number = ?
AND created_at >= ]] .. startExpression .. [[
ORDER BY created_at DESC
LIMIT 200]]
  end

  local rows = MySQL.query.await(sql, params) or {}
  local transactions = {}

  for index, row in ipairs(rows) do
    local transactionType = row.type or "transfer"
    if transactionType ~= "withdraw" and transactionType ~= "deposit" then
      transactionType = "transfer"
    end

    local date = os.date("%Y-%m-%d")
    if type(row.created_at) == "number" then
      local timestamp = row.created_at > 10000000000 and math.floor(row.created_at / 1000) or row.created_at
      local ok, formatted = pcall(function()
        return os.date("%Y-%m-%d", timestamp)
      end)
      date = ok and formatted or date
    elseif type(row.created_at) == "string" then
      date = row.created_at:match("(%d%d%d%d%-%d%d%-%d%d)") or os.date("%Y-%m-%d", TimestampToUnix(row.created_at))
    end

    table.insert(transactions, {
      id = index,
      type = transactionType,
      name = row.text or "Unknown Transaction",
      date = date,
      amount = tonumber(row.amount) or 0,
      accountIban = accountNumber,
      cardNumber = row.card_number and tostring(row.card_number):gsub("%s", "") or nil
    })
  end

  return transactions
end

function Main:CreateCard(source, cardData)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return response(false, "Identifier not found")
  end

  if not cardData or not cardData.accountId then
    return response(false, "Account ID required")
  end

  local accountNumber = tostring(cardData.accountId)
  local account = accountRow(accountNumber)
  if not account then
    return response(false, "Account not found")
  end

  if not hasPermission(accountNumber, identifier, "can_manage_cards") then
    return response(false, "No permission to manage cards")
  end

  local cardNumber
  repeat
    cardNumber = generateCardNumber()
  until not cardRow(cardNumber)

  local expiry = os.date("%m/%y", os.time() + (365 * 24 * 60 * 60 * 3))
  local cvv = tostring(math.random(100, 999))
  local pin = tonumber(cardData.pin) or math.random(1000, 9999)

  MySQL.insert.await([[
INSERT INTO bablo_bank_cards (card_number, account_number, pin, state, credit_limit, credit_used, provider, type, expiry, cvv, name)
VALUES (?, ?, ?, 0, ?, 0, ?, ?, ?, ?, ?)]], {
    cardNumber,
    accountNumber,
    pin,
    tonumber(cardData.creditLimit) or 0,
    tostring(cardData.provider or "visa"),
    tostring(cardData.type or "credit"),
    expiry,
    cvv,
    tostring(cardData.name or "Card")
  })

  local cardName = tostring(cardData.name or "Card")
  local itemGiven = giveCreditCardItem(source, {
    cardNumber = cardNumber,
    card_number = cardNumber,
    accountNumber = accountNumber,
    account_number = accountNumber,
    accountId = accountNumber,
    name = cardName,
    type = tostring(cardData.type or "credit"),
    provider = tostring(cardData.provider or "visa"),
    expiry = expiry,
    expiryDate = expiry,
    cvv = cvv,
    last4 = cardNumber:sub(-4),
    label = cardName,
    description = ("Card ending in %s"):format(cardNumber:sub(-4))
  })

  if not itemGiven then
    MySQL.query.await("DELETE FROM bablo_bank_cards WHERE card_number = ?", { cardNumber })
    return response(false, "Failed to give card item. Check inventory space/item config.")
  end

  sendWebhook(source, "CARD_CREATED", "Account: " .. accountNumber .. " | Card: " .. cardNumber)

  return response(true, "CARD_CREATED", {
    card = {
      id = cardNumber,
      name = cardName,
      cardNumber = cardNumber,
      expiryDate = expiry,
      cvv = cvv,
      type = cardData.type or "credit",
      provider = cardData.provider or "visa",
      balance = 0,
      creditLimit = tonumber(cardData.creditLimit) or 0,
      isActive = true,
      isFrozen = false,
      linkedAccountId = accountNumber
    }
  })
end

function Main:GetCards(source, accountNumber)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return response(false, "Identifier not found", { data = {} })
  end

  local rows
  if accountNumber then
    if not hasPermission(accountNumber, identifier, "can_manage_cards") then
      return response(false, "No access to account", { data = {} })
    end

    rows = MySQL.query.await("SELECT * FROM bablo_bank_cards WHERE account_number = ?", { accountNumber }) or {}
  else
    rows = MySQL.query.await([[
SELECT c.* FROM bablo_bank_cards c
JOIN bablo_bank_account_users u ON u.account_number = c.account_number
WHERE u.identifier = ?]], { identifier }) or {}
  end

  local cards = {}
  for _, card in ipairs(rows) do
    table.insert(cards, {
      id = tostring(card.card_number),
      name = card.name or "Card",
      cardNumber = tostring(card.card_number),
      expiryDate = tostring(card.expiry or ""),
      cvv = tostring(card.cvv or ""),
      type = tostring(card.type or "credit"),
      provider = tostring(card.provider or "visa"),
      balance = 0,
      creditLimit = tonumber(card.credit_limit or 0) or 0,
      isActive = tonumber(card.state or 0) == 0,
      isFrozen = tonumber(card.state or 0) ~= 0,
      linkedAccountId = tostring(card.account_number)
    })
  end

  return response(true, nil, {
    data = cards
  })
end

function Main:ToggleCardFreeze(source, cardNumber)
  local _, identifier = fetchCharacter(source)
  local card = cardRow(cardNumber)
  if not identifier or not card then
    return response(false, "Card not found")
  end

  if not hasPermission(card.account_number, identifier, "can_manage_cards") then
    return response(false, "No permission to manage cards")
  end

  local nextState = tonumber(card.state or 0) == 0 and 1 or 0
  MySQL.query.await("UPDATE bablo_bank_cards SET state = ? WHERE card_number = ?", { nextState, cardNumber })

  return response(true, nil, {
    isFrozen = nextState ~= 0
  })
end

function Main:TerminateCard(source, cardNumber)
  local _, identifier = fetchCharacter(source)
  local card = cardRow(cardNumber)
  if not identifier or not card then
    return response(false, "Card not found")
  end

  if not hasPermission(card.account_number, identifier, "can_manage_cards") then
    return response(false, "No permission to manage cards")
  end

  MySQL.query.await("DELETE FROM bablo_bank_cards WHERE card_number = ?", { cardNumber })
  return response(true, "Card terminated")
end

function Main:ChangeCardPin(source, data)
  local cardNumber = data and data.cardNumber
  local newPin = data and data.newPin

  if not cardNumber or not newPin then
    return response(false, "CARD_NUMBER_AND_NEWPIN_REQUIRED")
  end

  local _, identifier = fetchCharacter(source)
  local card = cardRow(cardNumber)
  if not identifier or not card then
    return response(false, "Card not found")
  end

  if not hasPermission(card.account_number, identifier, "can_manage_cards") then
    return response(false, "No permission to manage cards")
  end

  MySQL.query.await("UPDATE bablo_bank_cards SET pin = ? WHERE card_number = ?", { newPin, cardNumber })
  return response(true, "PIN_UPDATED")
end

function Main:GetCardPin(source, cardNumber)
  local _, identifier = fetchCharacter(source)
  local card = cardRow(cardNumber)
  if not identifier or not card then
    return response(false, "Card not found")
  end

  if not hasPermission(card.account_number, identifier, "can_manage_cards") then
    return response(false, "No permission to manage cards")
  end

  return response(true, nil, {
    pin = card.pin
  })
end

function Main:createDebugTransactions(accountNumber)
  MySQL.query.await([[
DELETE FROM bablo_bank_transactions
WHERE account_number = ?
AND text IN ('Debug Deposit','Debug Withdrawal','Debug Transfer')]], { accountNumber })

  for index = 1, 14 do
    MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, text, amount, created_at)
VALUES (?, '', 'deposit', 'Debug Deposit', ?, NOW() - INTERVAL ? DAY)]], { accountNumber, math.random(100, 1000), index })

    MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, text, amount, created_at)
VALUES (?, '', 'withdraw', 'Debug Withdrawal', ?, NOW() - INTERVAL ? DAY)]], { accountNumber, -math.random(20, 500), index })

    MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, text, amount, created_at)
VALUES (?, '', 'transfer', 'Debug Transfer', ?, NOW() - INTERVAL ? DAY)]], { accountNumber, math.random(-700, 700), index })
  end
end

function Main:getDefaultAccountNumberForSource(source)
  local _, identifier = fetchCharacter(source)
  if not identifier then
    return nil
  end

  local rows = MySQL.query.await(
    "SELECT account_number FROM bablo_bank_accounts WHERE owner = ? AND is_default = 1 LIMIT 1",
    { identifier }
  )

  return rows and rows[1] and rows[1].account_number or nil
end

function Main:createDebugTransactionsTwoWeeks(accountNumber)
  self:createDebugTransactions(accountNumber)
end

function Main:Deposit(source, accountNumber, amount, cardNumber)
  local player, identifier = fetchCharacter(source)
  amount = tonumber(amount)

  if not player or not identifier then
    return response(false, "Character not found")
  end

  if not accountNumber or not amount or amount <= 0 then
    return response(false, "Invalid data provided")
  end

  local account = accountRow(accountNumber)
  if not account then
    return response(false, "Account not found")
  end

  if asBool(account.is_frozen) then
    return response(false, "Account is frozen")
  end

  if not hasPermission(accountNumber, identifier, "can_deposit") then
    return response(false, "No permission to deposit")
  end

  local isDefault = asBool(account.is_default)
  if isDefault then
    if not Framework:removePlayerMoney(player, "cash", amount) then
      return response(false, "Not enough cash")
    end

    Framework:addPlayerMoney(player, "bank", amount)
  else
    if not Framework:removePlayerMoney(player, "cash", amount) then
      return response(false, "Not enough cash")
    end

    MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance + ? WHERE account_number = ?", { amount, accountNumber })
  end

  insertTransaction(accountNumber, "deposit", "Cash Deposit", amount, cardNumber)
  local newBalance = isDefault and Framework:getPlayerMoney(player, "bank") or ((tonumber(account.balance) or 0) + amount)
  sendWebhook(source, "DEPOSIT", "$" .. tostring(amount) .. " | Account: " .. tostring(accountNumber))

  return response(true, "Deposit successful", {
    newBalance = newBalance
  })
end

function Main:Withdraw(source, accountNumber, amount, cardNumber)
  local player, identifier = fetchCharacter(source)
  amount = tonumber(amount)

  if not player or not identifier then
    return response(false, "Character not found")
  end

  if not accountNumber or not amount or amount <= 0 then
    return response(false, "Invalid data provided")
  end

  local account = accountRow(accountNumber)
  if not account then
    return response(false, "Account not found")
  end

  if asBool(account.is_frozen) then
    return response(false, "Account is frozen")
  end

  if not hasPermission(accountNumber, identifier, "can_withdraw") then
    return response(false, "No permission to withdraw")
  end

  local isDefault = asBool(account.is_default)
  local balance = isDefault and Framework:getPlayerMoney(player, "bank") or (tonumber(account.balance) or 0)

  if amount > balance then
    return response(false, "Insufficient balance")
  end

  if isDefault then
    Framework:removePlayerMoney(player, "bank", amount)
  else
    MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance - ? WHERE account_number = ?", { amount, accountNumber })
  end

  Framework:addPlayerMoney(player, "cash", amount)
  insertTransaction(accountNumber, "withdraw", "Cash Withdrawal", -amount, cardNumber)
  local newBalance = isDefault and Framework:getPlayerMoney(player, "bank") or (balance - amount)
  sendWebhook(source, "WITHDRAW", "$" .. tostring(amount) .. " | Account: " .. tostring(accountNumber))

  return response(true, "Withdrawal successful", {
    newBalance = newBalance
  })
end
