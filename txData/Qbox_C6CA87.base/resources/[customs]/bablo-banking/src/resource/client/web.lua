local function nuiResponse(success, data, message)
  return {
    success = success,
    data = data,
    message = message
  }
end

local function translate(key, fallback)
  if Translate then
    local translated = Translate(key)
    if translated then
      return translated
    end
  end

  return fallback
end
local function friendlyTransferMessage(message)
  local normalized = tostring(message or "")
  local lower = normalized:lower()

  if lower == "insufficient balance" or lower == "insufficient funds" or lower == "not enough funds" then
    return "Not enough funds"
  end

  if normalized == "" then
    return translate("TRANSFER_FAILED", "Failed to process transfer")
  end

  return normalized
end

local function callServer(callbackName, args)
  local ok, result = pcall(function()
    return TriggerServerCallback({
      eventName = eventName .. callbackName,
      args = args or {}
    })
  end)

  if not ok then
    Trace("^1[Banking] Server callback error: " .. tostring(result) .. "^0")
    return nil
  end

  return result
end

local function normalizeCardNumber(cardNumber, payload)
  if type(cardNumber) == "number" then
    cardNumber = tostring(cardNumber)
  end

  if cardNumber and tostring(cardNumber):match("e%+") then
    Trace("^1WARNING: Received scientific notation cardNumber; last4=" .. tostring(payload and payload.last4) .. "^0")
  end

  return cardNumber
end

local function currentCharacterIdentifier()
  if Framework and Framework.getCharacterIdentifier then
    return Framework:getCharacterIdentifier() or "global"
  end

  return "global"
end

local function decodeContacts(rawContacts)
  local ok, contacts = pcall(function()
    return json.decode(rawContacts)
  end)

  return ok and type(contacts) == "table" and contacts or {}
end

local function recentContactsKey(identifier)
  return "bb_recent_contacts:" .. tostring(identifier or "global")
end

local function loadRecentContacts(identifier)
  local key = recentContactsKey(identifier)
  local contacts = {}
  local rawContacts = GetResourceKvpString(key)

  if rawContacts and rawContacts ~= "" then
    contacts = decodeContacts(rawContacts)
  end

  if #contacts == 0 then
    local legacyContacts = GetResourceKvpString("bb_recent_contacts")
    if legacyContacts and legacyContacts ~= "" then
      local decodedLegacy = decodeContacts(legacyContacts)
      if #decodedLegacy > 0 then
        contacts = decodedLegacy
        SetResourceKvp(key, json.encode(decodedLegacy))
      end
    end
  end

  return contacts
end

local function saveRecentContacts(identifier, contacts)
  contacts = contacts or {}
  SetResourceKvp(recentContactsKey(identifier), json.encode(contacts))
end

local function rememberTransferContact(destination, recipientDetails)
  if not destination then
    return
  end

  local identifier = currentCharacterIdentifier()
  local contacts = loadRecentContacts(identifier)
  local details = recipientDetails or {}
  local isOwned = details.isOwned or false
  local accountName = details.accountName or ""
  local ownerName = details.ownerName or ""
  local firstName = ""
  local lastName = ""

  if isOwned then
    firstName = accountName or ""
  elseif type(ownerName) == "string" and ownerName ~= "" then
    firstName, lastName = ownerName:match("^(%S+)%s+(.*)$")
    firstName = firstName or ownerName
    lastName = lastName or ""
  end

  local nextContacts = {
    {
      iban = tostring(destination),
      firstName = firstName,
      lastName = lastName,
      id = tostring(destination),
      accountName = accountName,
      isOwned = isOwned,
      ownerName = ownerName
    }
  }

  local seen = {
    [tostring(destination)] = true
  }

  for _, contact in ipairs(contacts) do
    if contact and contact.iban and not seen[tostring(contact.iban)] then
      table.insert(nextContacts, contact)
      seen[tostring(contact.iban)] = true
    end

    if #nextContacts >= 5 then
      break
    end
  end

  if identifier and identifier ~= "global" then
    saveRecentContacts(identifier, nextContacts)
  else
    SetResourceKvp("bb_recent_contacts", json.encode(nextContacts))
  end
end

RegisterNUICallback("GET_ACCOUNTS", function(_, cb)
  local result = callServer("server:onOpen", {})

  if result and result.status then
    cb(nuiResponse(true, result.accounts or {}, translate("ACCOUNTS_RETRIEVED_SUCCESS", "Accounts retrieved successfully")))
    return
  end

  cb(nuiResponse(false, {}, result and result.message or translate("ACCOUNTS_RETRIEVE_FAILED", "Failed to retrieve accounts")))
end)

RegisterNUICallback("GET_PLAYER_NAME", function(_, cb)
  local result = callServer("server:getFullName", {})

  if result and result.success then
    cb(nuiResponse(true, result.name or translate("PLAYER_NAME_UNKNOWN", "Unknown Player"), translate("OK", "OK")))
    return
  end

  cb(nuiResponse(false, translate("PLAYER_NAME_UNKNOWN", "Unknown Player"), result and result.message or translate("ERR", "ERR")))
end)

RegisterNetEvent(eventName .. "client:refreshAccounts", function()
  Trace("^3Received refreshAccounts event^0")

  local result = callServer("server:onOpen", {})
  Trace("^3Server response status: " .. tostring(result and result.status) .. ", accounts count: " .. tostring(result and result.accounts and #result.accounts or 0) .. "^0")

  if result and result.status and result.accounts then
    Trace("^3Sending SET_ACCOUNTS to NUI with " .. #result.accounts .. " accounts^0")
    SendNUIMessage({
      action = "SET_ACCOUNTS",
      data = result.accounts
    })
  else
    Trace("^1Failed to get accounts or invalid response^0")
  end
end)

RegisterNUICallback("GET_TRANSACTIONS", function(data, cb)
  if not data.accountId then
    cb(nuiResponse(false, {}, translate("ACCOUNT_ID_REQUIRED", "Account ID is required")))
    return
  end

  local result = callServer("server:getTransactions", { { data.accountId, data.daysFilter } })

  if result and result.success then
    cb(nuiResponse(true, result.data or {}, translate("TRANSACTIONS_RETRIEVED_SUCCESS", "Transactions retrieved successfully")))
    return
  end

  cb(nuiResponse(false, {}, result and result.message or translate("TRANSACTIONS_RETRIEVE_FAILED", "Failed to retrieve transactions")))
end)

local function handleMoneyAction(callbackName, data, cb, successKey, successFallback, failKey, failFallback)
  local accountId = data.accountId
  local amount = data.amount
  local cardNumber = data.cardNumber and tostring(data.cardNumber):gsub("%s", "") or nil

  if not accountId or not amount then
    cb(nuiResponse(false, nil, translate("ACCOUNT_ID_AND_AMOUNT_REQUIRED", "Account ID and amount are required")))
    return
  end

  if amount <= 0 then
    cb(nuiResponse(false, nil, translate("AMOUNT_GREATER_THAN_ZERO", "Amount must be greater than 0")))
    return
  end

  Trace((" Processing %s request - accountId: %s, amount: $%s, cardNumber: %s^0"):format(callbackName, tostring(accountId), tostring(amount), tostring(cardNumber)))

  local result = callServer(callbackName, { accountId, amount, cardNumber })

  if result and result.success then
    Trace((" %s successful^0"):format(callbackName))
    cb(nuiResponse(true, { newBalance = result.newBalance }, result.message or translate(successKey, successFallback)))
    return
  end

  local message = result and result.message or translate(failKey, failFallback)
  Trace((" %s failed: %s^0"):format(callbackName, message))
  cb(nuiResponse(false, nil, message))
end

RegisterNUICallback("DEPOSIT", function(data, cb)
  handleMoneyAction("server:deposit", data, cb, "DEPOSIT_COMPLETED_SUCCESS", "Deposit completed successfully", "DEPOSIT_FAILED", "Failed to process deposit")
end)

RegisterNUICallback("WITHDRAW", function(data, cb)
  handleMoneyAction("server:withdraw", data, cb, "WITHDRAWAL_COMPLETED_SUCCESS", "Withdrawal completed successfully", "WITHDRAWAL_FAILED", "Failed to process withdrawal")
end)

RegisterNUICallback("TRANSFER", function(data, cb)
  local fromAccountId = data.fromAccountId
  local toAccountId = data.toAccountId
  local toIban = data.toIban
  local amount = data.amount

  if not fromAccountId or not amount then
    cb(nuiResponse(false, nil, translate("FROM_ACCOUNT_ID_AND_AMOUNT_REQUIRED", "From account ID and amount are required")))
    return
  end

  if not toAccountId and not toIban then
    cb(nuiResponse(false, nil, translate("DESTINATION_REQUIRED", "Destination account ID or IBAN is required")))
    return
  end

  if amount <= 0 then
    cb(nuiResponse(false, nil, translate("AMOUNT_GREATER_THAN_ZERO", "Amount must be greater than 0")))
    return
  end

  local result = callServer("server:transfer", {
    fromAccountId,
    toAccountId,
    toIban,
    amount,
    data.description
  })

  if result and result.success then
    rememberTransferContact(toIban or toAccountId, result.recipientDetails)
    cb(nuiResponse(true, {
      newBalance = result.newBalance,
      recipient = result.recipient,
      transactionId = ""
    }, result.message or translate("TRANSFER_COMPLETED_SUCCESS", "Transfer completed successfully")))
    return
  end

  cb(nuiResponse(false, nil, friendlyTransferMessage(result and result.message)))
end)

local pinCache = {}
local pinCooldowns = {}
local PIN_CACHE_MS = 60000
local PIN_COOLDOWN_MS = 5000

RegisterNUICallback("GET_CARD_PIN", function(data, cb)
  local cardNumber = normalizeCardNumber(data and data.cardNumber, data)

  if not cardNumber then
    cb(nuiResponse(false, nil, translate("CARD_NUMBER_REQUIRED", "Card number is required")))
    return
  end

  local now = GetGameTimer and GetGameTimer() or os.time() * 1000
  local cached = pinCache[cardNumber]

  if cached and now - cached.time < PIN_CACHE_MS then
    cb(nuiResponse(true, { pin = cached.pin }, "OK (cache)"))
    return
  end

  local lastRequest = pinCooldowns[cardNumber] or 0
  if now - lastRequest < PIN_COOLDOWN_MS then
    if cached then
      cb(nuiResponse(true, { pin = cached.pin }, translate("OK_COOLDOWN_CACHE", "OK (cooldown-cache)")))
    else
      cb(nuiResponse(false, nil, translate("PLEASE_WAIT_BEFORE_REQUESTING_PIN_AGAIN", "Please wait before requesting PIN again")))
    end

    return
  end

  pinCooldowns[cardNumber] = now
  Trace("NUI GET_CARD_PIN for card " .. tostring(cardNumber))

  local result = callServer("server:getCardPin", { cardNumber })

  if result and result.success then
    pinCache[cardNumber] = {
      pin = tostring(result.pin),
      time = now
    }

    cb(nuiResponse(true, { pin = result.pin }, translate("OK", "OK")))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("FAILED", "Failed")))
end)

RegisterNUICallback("CHANGE_CARD_PIN", function(data, cb)
  local cardNumber = normalizeCardNumber(data and data.cardNumber, data)
  local newPin = data and data.newPin

  if not cardNumber or not newPin then
    cb(nuiResponse(false, nil, translate("CARD_NUMBER_AND_NEWPIN_REQUIRED", "Card number and newPin are required")))
    return
  end

  Trace("NUI CHANGE_CARD_PIN for card " .. tostring(cardNumber))
  local result = callServer("server:changeCardPin", { { cardNumber = cardNumber, newPin = newPin } })

  if result and result.success then
    pinCache = {}
    pinCooldowns = {}
    cb(nuiResponse(true, {}, translate("PIN_UPDATED", "PIN updated")))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("FAILED_TO_UPDATE_PIN", "Failed to update PIN")))
end)

RegisterNUICallback("GET_RECENT_CONTACTS", function(_, cb)
  cb(nuiResponse(true, loadRecentContacts(currentCharacterIdentifier()), translate("RECENT_CONTACTS_FETCHED", "Recent contacts fetched")))
end)

RegisterNetEvent(eventName .. "client:saveRecentContacts", function(identifier, contacts)
  contacts = contacts or {}
  saveRecentContacts(identifier or "global", contacts)

  SendNUIMessage({
    action = "SET_RECENT_CONTACTS",
    data = contacts
  })
end)

RegisterNUICallback("CREATE_ACCOUNT", function(data, cb)
  if not data.name or data.name == "" then
    cb(nuiResponse(false, nil, "Account name is required"))
    return
  end

  local result = callServer("server:createAccount", { data.name, data.type })

  if result and result.success then
    cb(nuiResponse(true, result.account, result.message or "Account created successfully"))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or "Failed to create account"))
end)

RegisterNUICallback("CREATE_CARD", function(data, cb)
  if not data.accountId then
    cb(nuiResponse(false, nil, "Account ID is required"))
    return
  end

  local result = callServer("server:createCard", { {
    accountId = data.accountId,
    name = data.name,
    type = data.type,
    provider = data.provider,
    creditLimit = data.creditLimit,
    pin = data.pin
  } })

  if result and result.success then
    cb(nuiResponse(true, { card = result.card }, result.message or "Card created successfully"))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or "Failed to create card"))
end)

RegisterNUICallback("GET_CARDS", function(data, cb)
  local result = callServer("server:getCards", { data and data.accountId or nil })

  if result and result.success then
    cb(nuiResponse(true, result.data or {}, translate("CARDS_FETCHED", "Cards fetched")))
    return
  end

  cb(nuiResponse(false, {}, result and result.message or translate("CARDS_FETCH_FAILED", "Failed to fetch cards")))
end)

local function cardAction(data, cb, serverCallback, successData, successKey, successFallback, failKey, failFallback)
  local cardNumber = normalizeCardNumber(data and data.cardNumber, data)

  if not cardNumber then
    cb(nuiResponse(false, nil, translate("CARD_NUMBER_REQUIRED", "Card number is required")))
    return
  end

  Trace("Calling " .. serverCallback .. " for card " .. tostring(cardNumber))
  local result = callServer(serverCallback, { cardNumber })
  Trace("Server response for " .. serverCallback .. " = " .. tostring(result and result.success))

  if result and result.success then
    cb(nuiResponse(true, successData(result), result.message or translate(successKey, successFallback)))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate(failKey, failFallback)))
end

RegisterNUICallback("TOGGLE_CARD_FREEZE", function(data, cb)
  Trace("NUI TOGGLE_CARD_FREEZE called")
  cardAction(data, cb, "server:toggleCardFreeze", function(result)
    return { isFrozen = result.isFrozen }
  end, "CARD_UPDATED", "Card updated", "CARD_UPDATE_FAILED", "Failed to update card")
end)

RegisterNUICallback("TERMINATE_CARD", function(data, cb)
  Trace("NUI TERMINATE_CARD called")
  cardAction(data, cb, "server:terminateCard", function()
    return { removed = true }
  end, "CARD_TERMINATED", "Card terminated", "CARD_TERMINATE_FAILED", "Failed to terminate card")
end)

RegisterNUICallback("GET_ACCOUNT_MEMBERS", function(data, cb)
  if not data.accountId then
    cb(nuiResponse(false, {}, translate("ACCOUNT_ID_REQUIRED", "Account ID is required")))
    return
  end

  local result = callServer("server:getAccountMembers", { data.accountId })

  if result and result.success then
    cb(nuiResponse(true, result.data or {}, translate("MEMBERS_FETCHED", "Members fetched")))
    return
  end

  cb(nuiResponse(false, {}, result and result.message or translate("MEMBERS_FETCH_FAILED", "Failed to fetch members")))
end)

local function memberAction(serverCallback, data, cb, successKey, successFallback, failKey, failFallback, responseData)
  local result = callServer(serverCallback, { data })

  if result and result.success then
    cb(nuiResponse(true, responseData and responseData(result) or result.data or {}, translate(successKey, successFallback)))
    return
  end

  cb(nuiResponse(false, {}, result and result.message or translate(failKey, failFallback)))
end

RegisterNUICallback("ADD_MEMBER", function(data, cb)
  memberAction("server:addMember", data, cb, "MEMBER_ADDED", "Member added", "MEMBER_ADD_FAILED", "Failed to add member")
end)

RegisterNUICallback("UPDATE_MEMBER", function(data, cb)
  memberAction("server:updateMember", data, cb, "MEMBER_UPDATED", "Member updated", "MEMBER_UPDATE_FAILED", "Failed to update member", function()
    return {}
  end)
end)

RegisterNUICallback("REMOVE_MEMBER", function(data, cb)
  memberAction("server:removeMember", data, cb, "MEMBER_REMOVED", "Member removed", "MEMBER_REMOVE_FAILED", "Failed to remove member", function()
    return {}
  end)
end)

RegisterNUICallback("TRANSFER_ACCOUNT_OWNERSHIP", function(data, cb)
  local accountId = data.accountId
  local recipientId = data.recipientId
  local recipientSource = data.recipientSource

  if not accountId or (not recipientId and not recipientSource) then
    cb(nuiResponse(false, nil, "Account ID and recipient are required"))
    return
  end

  local numericRecipient = tonumber(recipientSource or recipientId)
  local result

  if numericRecipient then
    result = callServer("server:transferAccountOwnershipBySource", { accountId, numericRecipient })
  else
    result = callServer("server:transferAccountOwnership", { accountId, recipientId })
  end

  if result and result.success then
    cb(nuiResponse(true, { newOwnerId = result.newOwnerId }, result.message or translate("ACCOUNT_OWNERSHIP_TRANSFERRED_SUCCESS", "Account ownership transferred successfully")))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("ACCOUNT_OWNERSHIP_TRANSFER_FAILED", "Failed to transfer account ownership")))
end)

RegisterNUICallback("TOGGLE_ACCOUNT_FREEZE", function(data, cb)
  if not data.accountId then
    cb(nuiResponse(false, nil, translate("ACCOUNT_ID_REQUIRED", "Account ID is required")))
    return
  end

  local result = callServer("server:toggleFreeze", { data.accountId })

  if result and result.success then
    local message = result.isFrozen
      and translate("ACCOUNT_FROZEN_SUCCESS", "Account frozen successfully")
      or translate("ACCOUNT_UNFROZEN_SUCCESS", "Account unfrozen successfully")

    cb(nuiResponse(true, { isFrozen = result.isFrozen }, message))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("ACCOUNT_FREEZE_TOGGLE_FAILED", "Failed to toggle account freeze status")))
end)

RegisterNUICallback("TERMINATE_ACCOUNT", function(data, cb)
  if not data.accountId then
    cb(nuiResponse(false, nil, translate("ACCOUNT_ID_REQUIRED", "Account ID is required")))
    return
  end

  local result = callServer("server:terminateAccount", { data.accountId })

  if result and result.success then
    cb(nuiResponse(true, { terminated = true }, translate("ACCOUNT_TERMINATED_SUCCESS", "Account terminated successfully")))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("ACCOUNT_TERMINATE_FAILED", "Failed to terminate account")))
end)

RegisterNUICallback("CLOSE_MENU", function(_, cb)
  if Main and Main.closeApp then
    Main:closeApp()
  else
    SetNuiFocus(false, false)
    SendNUIMessage({
      action = "SET_APP_STATE",
      data = false
    })
  end

  cb({})
end)

RegisterNUICallback("CHECK_BILLING_AVAILABLE", function(_, cb)
  local result = callServer("server:checkBillingAvailable", {})

  if result then
    cb(nuiResponse(true, { available = result.available }, translate("OK", "OK")))
    return
  end

  cb(nuiResponse(false, { available = false }, translate("FAILED_CHECK_BILLING_AVAILABILITY", "Failed to check billing availability")))
end)

RegisterNUICallback("GET_RECEIVED_INVOICES", function(data, cb)
  local result = callServer("server:getReceivedInvoices", { data })

  if result and result.success then
    cb(nuiResponse(true, result.data, translate("INVOICES_RETRIEVED", "Invoices retrieved")))
    return
  end

  cb(nuiResponse(false, {
    invoices = {},
    pagination = {}
  }, result and result.message or translate("INVOICES_RETRIEVE_FAILED", "Failed to retrieve invoices")))
end)

RegisterNUICallback("PAY_INVOICE_WITH_ACCOUNT", function(data, cb)
  if not data or not data.invoiceUuid or not data.accountId then
    cb(nuiResponse(false, nil, translate("INVOICE_UUID_AND_ACCOUNT_ID_REQUIRED", "Invoice UUID and account ID are required")))
    return
  end

  local result = callServer("server:payInvoiceWithAccount", { data })

  if result and result.success then
    cb(nuiResponse(true, { newBalance = result.newBalance }, result.message or translate("INVOICE_PAID_SUCCESS", "Invoice paid successfully")))
    return
  end

  cb(nuiResponse(false, nil, result and result.message or translate("FAILED_TO_PAY_INVOICE", "Failed to pay invoice")))
end)
