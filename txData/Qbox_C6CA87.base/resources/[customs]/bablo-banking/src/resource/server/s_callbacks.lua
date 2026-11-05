while not eventName do
  Wait(0)
end

if GetCurrentResourceName() ~= "bablo-banking" then
  error("Resource name must be 'bablo-banking'")
  return
end

local billingResourceName = "bablo-billing"
local billingAvailable = GetResourceState(billingResourceName) == "started"

local function isBillingAvailable()
  billingAvailable = GetResourceState(billingResourceName) == "started"
  return billingAvailable
end

AddEventHandler("onResourceStart", function(resourceName)
  if resourceName == billingResourceName then
    billingAvailable = true
  end
end)

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName == billingResourceName then
    billingAvailable = false
  end
end)

local function registerCallback(name, callback)
  RegisterServerCallback({
    eventName = eventName .. name,
    eventCallback = callback
  })
end

local function fetchCharacter(playerSource)
  local player = Framework:fetchPlayer(playerSource)
  if not player then
    return nil, nil, {
      success = false,
      message = "NO_CHARACTER"
    }
  end

  local identifier = Framework:getCharacterIdentifier(player)
  if not identifier then
    return nil, nil, {
      success = false,
      message = "NO_IDENTIFIER"
    }
  end

  return player, identifier
end

local function boolToInt(value)
  return value and 1 or 0
end

local function getAccountRole(accountNumber, identifier)
  local roleRows = MySQL.query.await([[
SELECT r.role, a.owner FROM bablo_bank_account_user_roles r
RIGHT JOIN bablo_bank_accounts a ON a.account_number = r.account_number
WHERE r.account_number = ? AND r.identifier = ? LIMIT 1]], { accountNumber, identifier })

  if roleRows and roleRows[1] then
    if roleRows[1].role then
      return roleRows[1].role
    end

    if tostring(roleRows[1].owner or "") == tostring(identifier) then
      return "owner"
    end
  end

  local accountRows = MySQL.query.await(
    "SELECT owner FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
    { accountNumber }
  )

  if accountRows and accountRows[1] and tostring(accountRows[1].owner or "") == tostring(identifier) then
    return "owner"
  end

  return "member"
end

local function canManageMembers(accountNumber, identifier)
  local role = getAccountRole(accountNumber, identifier)
  if role == "owner" or role == "admin" then
    return true, role
  end

  local rows = MySQL.query.await(
    "SELECT can_manage_members FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ? LIMIT 1",
    { accountNumber, identifier }
  )

  local allowed = rows and rows[1] and tonumber(rows[1].can_manage_members or 0) == 1
  return allowed, role
end

local function upsertPermissions(accountNumber, identifier, permissions)
  permissions = permissions or {}

  MySQL.query.await(
    "DELETE FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ?",
    { accountNumber, identifier }
  )

  MySQL.query.await([[
INSERT INTO bablo_bank_account_permissions (account_number, identifier, can_view, can_deposit, can_withdraw, can_transfer, can_manage_members, can_manage_cards)
VALUES (?, ?, ?, ?, ?, ?, ?, ?)]], {
    accountNumber,
    identifier,
    boolToInt(permissions.canView),
    boolToInt(permissions.canDeposit),
    boolToInt(permissions.canWithdraw),
    boolToInt(permissions.canTransfer),
    boolToInt(permissions.canManageMembers),
    boolToInt(permissions.canManageCards)
  })
end

local function fetchOfflineName(identifier)
  if Framework.fetchOfflinePlayerName then
    return Framework:fetchOfflinePlayerName(identifier) or identifier
  end

  return identifier
end

local function refreshOnlinePlayer(identifier, message)
  if not Framework.fetchPlayerByIdentifier or not Framework.getPlayerSource then
    Trace("Framework methods not available for player refresh")
    return
  end

  local player = Framework:fetchPlayerByIdentifier(identifier)
  if not player then
    Trace("Could not find target character for identifier: " .. tostring(identifier) .. "^0")
    return
  end

  local playerSource = Framework:getPlayerSource(player)
  if not playerSource then
    Trace("Could not get source for target player")
    return
  end

  TriggerClientEvent(eventName .. "client:refreshAccounts", playerSource)
  TriggerClientEvent(eventName .. "client:sendNotify", playerSource, message)
end

registerCallback("server:checkBillingAvailable", function()
  return {
    available = isBillingAvailable()
  }
end)

registerCallback("server:getReceivedInvoices", function(playerSource, options)
  if not isBillingAvailable() then
    return {
      success = false,
      message = "Billing system not available"
    }
  end

  local _, identifier, errorResponse = fetchCharacter(playerSource)
  if errorResponse then
    return errorResponse
  end

  local page = options and options.page or 1
  local limit = options and options.limit or 50
  local offset = (page - 1) * limit

  local invoices = MySQL.query.await([[
SELECT * FROM bablo_invoices
WHERE recipient_identifier = ?
AND recipient_account_type = 'personal'
AND status = 'pending'
ORDER BY created_at DESC
LIMIT ? OFFSET ?]], { identifier, limit, offset }) or {}

  local countRows = MySQL.query.await([[
SELECT COUNT(*) as total FROM bablo_invoices
WHERE recipient_identifier = ?
AND recipient_account_type = 'personal'
AND status = 'pending']], { identifier })

  local total = countRows and countRows[1] and countRows[1].total or 0
  Trace("Found " .. tostring(#invoices) .. " pending invoices for " .. identifier)

  return {
    success = true,
    data = {
      invoices = invoices,
      pagination = {
        page = page,
        limit = limit,
        total = total,
        hasMore = total > page * limit
      }
    }
  }
end)

registerCallback("server:payInvoiceWithAccount", function(playerSource, data)
  if not isBillingAvailable() then
    return {
      success = false,
      message = "Billing system not available"
    }
  end

  local invoiceUuid = data and data.invoiceUuid
  local accountNumber = data and data.accountId

  if not invoiceUuid or not accountNumber then
    return {
      success = false,
      message = "Invoice UUID and account ID are required"
    }
  end

  local player, identifier, errorResponse = fetchCharacter(playerSource)
  if errorResponse then
    return errorResponse
  end

  local invoiceRows = MySQL.query.await("SELECT * FROM bablo_invoices WHERE uuid = ? LIMIT 1", { invoiceUuid })
  if not invoiceRows or #invoiceRows == 0 then
    return {
      success = false,
      message = "Invoice not found"
    }
  end

  local invoice = invoiceRows[1]
  if invoice.status ~= "pending" then
    return {
      success = false,
      message = "Invoice has already been paid"
    }
  end

  if invoice.recipient_identifier ~= identifier then
    return {
      success = false,
      message = "You are not authorized to pay this invoice"
    }
  end

  local accountRows = MySQL.query.await([[
SELECT ba.*,
       COALESCE(p.can_withdraw, 0) as can_withdraw,
       ba.owner = ? as is_owner
FROM bablo_bank_accounts ba
LEFT JOIN bablo_bank_account_permissions p
  ON p.account_number = ba.account_number AND p.identifier = ?
LEFT JOIN bablo_bank_account_users u
  ON u.account_number = ba.account_number AND u.identifier = ?
WHERE ba.account_number = ?
AND (ba.owner = ? OR u.identifier IS NOT NULL)
LIMIT 1]], { identifier, identifier, identifier, accountNumber, identifier })

  if not accountRows or #accountRows == 0 then
    return {
      success = false,
      message = "Account not found or no access"
    }
  end

  local account = accountRows[1]
  if account.is_frozen == 1 then
    return {
      success = false,
      message = "Cannot pay from a frozen account"
    }
  end

  if account.is_owner ~= 1 and tonumber(account.can_withdraw or 0) ~= 1 then
    return {
      success = false,
      message = "You do not have permission to withdraw from this account"
    }
  end

  local amount = tonumber(invoice.amount)
  if not amount or amount <= 0 then
    return {
      success = false,
      message = "Invalid invoice amount"
    }
  end

  local isDefault = tonumber(account.is_default or 0) == 1
  local balance = isDefault and Framework:getPlayerMoney(player, "bank") or (tonumber(account.balance) or 0)

  if amount > balance then
    return {
      success = false,
      message = "Insufficient funds in selected account"
    }
  end

  if isDefault then
    if not Framework:removePlayerMoney(player, "bank", amount) then
      return {
        success = false,
        message = "Failed to process payment"
      }
    end
  elseif not MySQL.query.await("UPDATE bablo_bank_accounts SET balance = balance - ? WHERE account_number = ?", { amount, accountNumber }) then
    return {
      success = false,
      message = "Failed to process payment"
    }
  end

  MySQL.insert.await([[
INSERT INTO bablo_bank_transactions (account_number, card_number, type, amount, text, created_at)
VALUES (?, '', 'withdraw', ?, ?, NOW())]], {
    accountNumber,
    -amount,
    "Invoice Payment: " .. (invoice.title or "Unknown")
  })

  local exportOk, billingResult = pcall(function()
    return exports[billingResourceName]:payInvoice(invoiceUuid, playerSource, {
      skipPayerDeduction = true
    })
  end)

  if not exportOk or not billingResult or not billingResult.success then
    Trace("Warning: bablo-billing payInvoice returned error: " .. tostring(billingResult and billingResult.message or "unknown"))
  end

  Trace("Invoice " .. invoiceUuid .. " paid by " .. identifier .. " from account " .. accountNumber)

  return {
    success = true,
    message = "Invoice paid successfully",
    newBalance = balance - amount
  }
end)

Citizen.CreateThread(function()
  registerCallback("server:getFullName", function(playerSource)
    local player = Framework.fetchPlayer and Framework:fetchPlayer(playerSource)
    if not player then
      return {
        success = false,
        message = "NO_CHARACTER"
      }
    end

    local name
    if Framework.getPlayerFullName then
      local ok, result = pcall(function()
        return Framework:getPlayerFullName(player)
      end)

      if ok and type(result) == "string" and #result > 0 then
        name = result
      end
    end

    return {
      success = true,
      name = name or "Unknown Player"
    }
  end)

  registerCallback("server:onOpen", function(playerSource)
    local player, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      return {
        status = false,
        message = errorResponse.message
      }
    end

    if Society and Society.Init then
      Society:Init()
      Society:syncForSource(playerSource)
    end

    return {
      status = true,
      accounts = Main:getPlayerAccounts(player, identifier)
    }
  end)

  registerCallback("server:getTranslations", function()
    local locale = Config and Config.Locale or "en"

    return {
      success = true,
      locale = locale,
      data = Locales and Locales[locale] or {}
    }
  end)

  registerCallback("server:getTransactions", function(playerSource, payload)
    local accountId
    local daysFilter

    if type(payload) == "string" or type(payload) == "number" then
      accountId = payload
    elseif type(payload) == "table" then
      if payload[1] ~= nil then
        accountId = payload[1]
        daysFilter = payload[2]
      else
        accountId = payload.accountId
        daysFilter = payload.daysFilter
      end
    end

    Trace("GET_TRANSACTIONS callback triggered for source: " .. tostring(playerSource))
    Trace("Data received - accountId: " .. tostring(accountId) .. ", daysFilter: " .. tostring(daysFilter))

    local _, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      errorResponse.data = {}
      return errorResponse
    end

    local transactions = Main:getAccountTransactions(identifier, accountId, daysFilter)

    return {
      success = true,
      message = "TRANSACTIONS_FETCHED",
      data = transactions
    }
  end)

  registerCallback("server:getAccountMembers", function(playerSource, accountNumber)
    if not accountNumber then
      return {
        success = false,
        message = "NO_ACCOUNT_ID",
        data = {}
      }
    end

    local _, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      errorResponse.data = {}
      return errorResponse
    end

    local rows = MySQL.query.await([[
SELECT
    au.identifier,
    au.added_at,
    COALESCE(r.role, 'member') AS role,
    1 AS can_view,
    CASE WHEN COALESCE(r.role, 'member') = 'owner' THEN 1 ELSE COALESCE(p.can_deposit, 0) END AS can_deposit,
    CASE WHEN COALESCE(r.role, 'member') = 'owner' THEN 1 ELSE COALESCE(p.can_withdraw, 0) END AS can_withdraw,
    CASE WHEN COALESCE(r.role, 'member') = 'owner' THEN 1 ELSE COALESCE(p.can_transfer, 0) END AS can_transfer,
    CASE WHEN COALESCE(r.role, 'member') = 'owner' THEN 1 ELSE COALESCE(p.can_manage_members, 0) END AS can_manage_members,
    CASE WHEN COALESCE(r.role, 'member') = 'owner' THEN 1 ELSE COALESCE(p.can_manage_cards, 0) END AS can_manage_cards
FROM bablo_bank_account_users au
LEFT JOIN bablo_bank_account_user_roles r
  ON r.account_number = au.account_number AND r.identifier = au.identifier
LEFT JOIN (
    SELECT account_number, identifier,
           MAX(can_deposit) AS can_deposit,
           MAX(can_withdraw) AS can_withdraw,
           MAX(can_transfer) AS can_transfer,
           MAX(can_manage_members) AS can_manage_members,
           MAX(can_manage_cards) AS can_manage_cards
    FROM bablo_bank_account_permissions
    GROUP BY account_number, identifier
) p
  ON p.account_number = au.account_number AND p.identifier = au.identifier
WHERE au.account_number = ?]], { accountNumber }) or {}

    local members = {}
    local accountRows = MySQL.query.await(
      "SELECT owner FROM bablo_bank_accounts WHERE account_number = ? LIMIT 1",
      { accountNumber }
    )
    local owner = accountRows and accountRows[1] and accountRows[1].owner

    for _, row in ipairs(rows) do
      local role = row.role
      if role ~= "owner" and owner and tostring(owner) == tostring(row.identifier) then
        role = "owner"
      end

      table.insert(members, {
        identifier = row.identifier,
        name = fetchOfflineName(row.identifier),
        role = role,
        added_at = row.added_at,
        can_view = row.can_view,
        can_deposit = row.can_deposit,
        can_withdraw = row.can_withdraw,
        can_transfer = row.can_transfer,
        can_manage_members = row.can_manage_members,
        can_manage_cards = row.can_manage_cards,
        is_self = tostring(row.identifier) == tostring(identifier)
      })
    end

    if owner then
      local ownerPermission = MySQL.query.await(
        "SELECT identifier FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ? LIMIT 1",
        { accountNumber, owner }
      )

      if not ownerPermission or not ownerPermission[1] then
        MySQL.query.await([[
REPLACE INTO bablo_bank_account_permissions (account_number, identifier, can_view, can_deposit, can_withdraw, can_transfer, can_manage_members, can_manage_cards)
VALUES (?, ?, 1, 1, 1, 1, 1, 1)]], { accountNumber, owner })
      end
    end

    return {
      success = true,
      data = members
    }
  end)

  registerCallback("server:addMember", function(playerSource, data)
    local accountNumber = data and data.accountId
    local memberData = data and data.memberData

    if not accountNumber or not memberData or not memberData.id then
      return {
        success = false,
        message = "INVALID_DATA"
      }
    end

    local _, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      return errorResponse
    end

    local allowed = canManageMembers(accountNumber, identifier)
    if not allowed then
      return {
        success = false,
        message = "NO_ACCESS"
      }
    end

    local targetIdentifier
    local targetSource = tonumber(memberData.id)

    if targetSource then
      local targetPlayer = Framework:fetchPlayer(targetSource)
      if not targetPlayer then
        return {
          success = false,
          message = "TARGET_NOT_ONLINE"
        }
      end

      targetIdentifier = Framework:getCharacterIdentifier(targetPlayer)
      if not targetIdentifier then
        return {
          success = false,
          message = "TARGET_IDENTIFIER_MISSING"
        }
      end
    else
      targetIdentifier = tostring(memberData.id)
    end

    MySQL.query.await(
      "INSERT IGNORE INTO bablo_bank_account_users (account_number, identifier) VALUES (?, ?)",
      { accountNumber, targetIdentifier }
    )

    if memberData.role then
      MySQL.query.await(
        "REPLACE INTO bablo_bank_account_user_roles (account_number, identifier, role) VALUES (?, ?, ?)",
        { accountNumber, targetIdentifier, memberData.role }
      )
    end

    if memberData.permissions then
      upsertPermissions(accountNumber, targetIdentifier, memberData.permissions)
    end

    local displayName = fetchOfflineName(targetIdentifier)
    local addedRows = MySQL.query.await(
      "SELECT added_at FROM bablo_bank_account_users WHERE account_number = ? AND identifier = ? LIMIT 1",
      { accountNumber, targetIdentifier }
    )
    local addedAt = addedRows and addedRows[1] and addedRows[1].added_at or os.date("%Y-%m-%d")

    refreshOnlinePlayer(targetIdentifier, "You have been added to a shared account")
    sendWebhook(playerSource, "MEMBER_ADDED", "Account: " .. tostring(accountNumber) .. " | Member: " .. tostring(displayName) .. " | Role: " .. tostring(memberData.role or "member"))

    local permissions = memberData.permissions or {}

    return {
      success = true,
      data = {
        id = targetIdentifier,
        identifier = targetIdentifier,
        name = displayName,
        role = memberData.role or "member",
        added_at = addedAt,
        can_view = boolToInt(permissions.canView),
        can_deposit = boolToInt(permissions.canDeposit),
        can_withdraw = boolToInt(permissions.canWithdraw),
        can_transfer = boolToInt(permissions.canTransfer),
        can_manage_members = boolToInt(permissions.canManageMembers),
        can_manage_cards = boolToInt(permissions.canManageCards)
      }
    }
  end)

  registerCallback("server:updateMember", function(playerSource, data)
    local accountNumber = data and data.accountId
    local memberIdentifier = data and data.memberId
    local updates = data and data.updates or {}

    if not accountNumber or not memberIdentifier then
      return {
        success = false,
        message = "INVALID_DATA"
      }
    end

    local _, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      return errorResponse
    end

    local allowed, actorRole = canManageMembers(accountNumber, identifier)
    if not allowed then
      return {
        success = false,
        message = "NO_ACCESS"
      }
    end

    if actorRole ~= "owner" then
      local targetRole = getAccountRole(accountNumber, memberIdentifier)
      if targetRole == "owner" or updates.role == "owner" then
        return {
          success = false,
          message = "OWNER_ONLY"
        }
      end
    end

    if updates.role then
      MySQL.query.await(
        "REPLACE INTO bablo_bank_account_user_roles (account_number, identifier, role) VALUES (?, ?, ?)",
        { accountNumber, memberIdentifier, updates.role }
      )
    end

    if updates.permissions then
      upsertPermissions(accountNumber, memberIdentifier, updates.permissions)
    end

    return {
      success = true
    }
  end)

  registerCallback("server:removeMember", function(playerSource, data)
    local accountNumber = data and data.accountId
    local memberIdentifier = data and data.memberId

    if not accountNumber or not memberIdentifier then
      return {
        success = false,
        message = "INVALID_DATA"
      }
    end

    local _, identifier, errorResponse = fetchCharacter(playerSource)
    if errorResponse then
      return errorResponse
    end

    local allowed, actorRole = canManageMembers(accountNumber, identifier)
    if not allowed then
      return {
        success = false,
        message = "NO_ACCESS"
      }
    end

    local targetRole = getAccountRole(accountNumber, memberIdentifier)
    if actorRole == "owner" and targetRole == "owner" then
      return {
        success = false,
        message = "CANNOT_REMOVE_OWNER"
      }
    end

    if actorRole == "admin" and targetRole ~= "member" then
      return {
        success = false,
        message = "NO_ACCESS"
      }
    end

    MySQL.query.await("DELETE FROM bablo_bank_account_permissions WHERE account_number = ? AND identifier = ?", { accountNumber, memberIdentifier })
    MySQL.query.await("DELETE FROM bablo_bank_account_user_roles WHERE account_number = ? AND identifier = ?", { accountNumber, memberIdentifier })
    MySQL.query.await("DELETE FROM bablo_bank_account_users WHERE account_number = ? AND identifier = ?", { accountNumber, memberIdentifier })

    refreshOnlinePlayer(memberIdentifier, "Your access to an account was removed")
    sendWebhook(playerSource, "MEMBER_REMOVED", "Account: " .. tostring(accountNumber) .. " | Member ID: " .. tostring(memberIdentifier))

    return {
      success = true
    }
  end)

  registerCallback("server:deposit", function(playerSource, accountNumber, amount, cardNumber)
    Trace("DEPOSIT callback triggered for source: " .. tostring(playerSource))
    Trace("Parameters: accountId = " .. tostring(accountNumber) .. ", amount = " .. tostring(amount) .. ", cardNumber = " .. tostring(cardNumber) .. "^0")

    if not accountNumber or not amount then
      return {
        success = false,
        message = "Invalid data provided"
      }
    end

    return Main:Deposit(playerSource, accountNumber, amount, cardNumber)
  end)

  registerCallback("server:withdraw", function(playerSource, accountNumber, amount, cardNumber)
    Trace("WITHDRAW callback triggered for source: " .. tostring(playerSource))
    Trace("Parameters: accountId = " .. tostring(accountNumber) .. ", amount = " .. tostring(amount) .. ", cardNumber = " .. tostring(cardNumber) .. "^0")

    if not accountNumber or not amount then
      return {
        success = false,
        message = "Invalid data provided"
      }
    end

    return Main:Withdraw(playerSource, accountNumber, amount, cardNumber)
  end)

  registerCallback("server:transfer", function(playerSource, fromAccount, toAccount, toIban, amount, description)
    if not fromAccount or not amount then
      return {
        success = false,
        message = "Invalid transfer details"
      }
    end

    local ok, result = pcall(function()
      return Main:Transfer(playerSource, fromAccount, toAccount, toIban, amount, description)
    end)

    if not ok then
      return {
        success = false,
        message = "Failed to process transfer"
      }
    end

    return result
  end)

  registerCallback("server:createAccount", function(playerSource, accountName, accountType)
    if not accountName or accountName == "" then
      return {
        success = false,
        message = "Account name is required"
      }
    end

    return Main:CreateAccount(playerSource, accountName, accountType or "personal")
  end)

  registerCallback("server:createCard", function(playerSource, cardData)
    if not cardData or not cardData.accountId then
      return {
        success = false,
        message = "Account ID required"
      }
    end

    return Main:CreateCard(playerSource, cardData)
  end)

  registerCallback("server:getCards", function(playerSource, payload)
    local accountNumber = payload

    if type(payload) == "table" then
      accountNumber = payload.accountId
    end

    return Main:GetCards(playerSource, accountNumber)
  end)

  registerCallback("server:toggleCardFreeze", function(playerSource, cardNumber)
    Trace(("server:toggleCardFreeze from %s, card=%s"):format(tostring(playerSource), tostring(cardNumber)))

    if not cardNumber then
      return {
        success = false,
        message = "CARD_NUMBER_REQUIRED"
      }
    end

    return Main:ToggleCardFreeze(playerSource, cardNumber)
  end)

  registerCallback("server:terminateCard", function(playerSource, cardNumber)
    Trace(("server:terminateCard from %s, card=%s"):format(tostring(playerSource), tostring(cardNumber)))

    if not cardNumber then
      return {
        success = false,
        message = "CARD_NUMBER_REQUIRED"
      }
    end

    return Main:TerminateCard(playerSource, cardNumber)
  end)

  registerCallback("server:changeCardPin", function(playerSource, data)
    Trace(("server:changeCardPin from %s"):format(tostring(playerSource)))
    return Main:ChangeCardPin(playerSource, data)
  end)

  registerCallback("server:getCardPin", function(playerSource, cardNumber)
    Trace(("server:getCardPin from %s, card=%s"):format(tostring(playerSource), tostring(cardNumber)))

    if not cardNumber then
      return {
        success = false,
        message = "CARD_NUMBER_REQUIRED"
      }
    end

    return Main:GetCardPin(playerSource, cardNumber)
  end)

  registerCallback("server:toggleFreeze", function(playerSource, accountNumber)
    if not accountNumber then
      return {
        success = false,
        message = "Account ID required"
      }
    end

    return Main:ToggleFreeze(playerSource, accountNumber)
  end)

  registerCallback("server:terminateAccount", function(playerSource, accountNumber)
    if not accountNumber then
      return {
        success = false,
        message = "Account ID required"
      }
    end

    return Main:TerminateAccount(playerSource, accountNumber)
  end)

  registerCallback("server:transferAccountOwnershipBySource", function(playerSource, accountNumber, targetSource)
    if not accountNumber or not targetSource then
      return {
        success = false,
        message = "Account ID and target source required"
      }
    end

    return Main:TransferAccountOwnership(playerSource, accountNumber, targetSource)
  end)

  registerCallback("server:transferAccountOwnership", function(playerSource, accountNumber, targetIdentifier)
    if not accountNumber or not targetIdentifier then
      return {
        success = false,
        message = "Account ID and target identifier required"
      }
    end

    return Main:TransferAccountOwnership(playerSource, accountNumber, nil, targetIdentifier)
  end)
end)

RegisterCommand("bb_debug_weekly", function(playerSource)
  local accountNumber = Main:getDefaultAccountNumberForSource(playerSource)
  if not accountNumber then
    Trace("No default account for source " .. tostring(playerSource))
    return
  end

  Main:createDebugTransactionsTwoWeeks(accountNumber)
  Trace("Created debug transactions for default account " .. accountNumber)
end, false)
