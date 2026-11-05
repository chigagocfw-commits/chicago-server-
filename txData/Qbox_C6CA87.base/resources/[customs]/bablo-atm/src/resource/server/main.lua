local sessions = {}

local function getBankingResource()
    return (Config and Config.BankingResource) or "bablo-banking"
end

local function getBankingExport()
    local resourceName = getBankingResource()

    if GetResourceState(resourceName) ~= "started" then
        return nil, "BANKING_OFFLINE"
    end

    return exports[resourceName], nil
end

local function callBankingExport(exportName, ...)
    local banking, err = getBankingExport()
    if not banking then
        return nil, err
    end

    if type(banking[exportName]) ~= "function" then
        return nil, ("MISSING_EXPORT_%s"):format(exportName)
    end

    local ok, result, extra = pcall(banking[exportName], ...)
    if not ok then
        local methodOk, methodResult, methodExtra = pcall(banking[exportName], banking, ...)
        if methodOk then
            return methodResult, methodExtra
        end

        Error(("[bablo-atm] Banking export '%s' failed: %s"):format(exportName, result))
        return nil, "BANKING_EXPORT_FAILED"
    end

    if result == nil then
        local methodOk, methodResult, methodExtra = pcall(banking[exportName], banking, ...)
        if methodOk and methodResult ~= nil then
            return methodResult, methodExtra
        end
    end

    return result, extra
end

local function getCardPin(cardNumber)
    local pin = callBankingExport("GetCardPinByNumber", cardNumber)

    if pin == nil and GetCardPinCode then
        pin = GetCardPinCode(cardNumber)
    end

    return pin
end

local function getBalanceForCard(source, cardNumber, accountId)
    cardNumber = cardNumber and tostring(cardNumber):gsub("%s", "") or nil
    accountId = accountId and tostring(accountId):gsub("%s", "") or nil

    local balance
    if cardNumber and cardNumber ~= "" then
        balance = callBankingExport("GetBalanceFromCard", cardNumber, source)
        Debug(("[bablo-atm] Balance by card %s for player %s: %s"):format(cardNumber, source, tostring(balance)))
    end

    if balance == nil and accountId and accountId ~= "" then
        balance = callBankingExport("GetBalance", accountId, source)
        Debug(("[bablo-atm] Balance by account %s for player %s: %s"):format(accountId, source, tostring(balance)))
    end

    if balance == nil and accountId and accountId ~= "" then
        local rows = MySQL.query.await([[
            SELECT balance
            FROM bablo_bank_accounts
            WHERE account_number = ?
            LIMIT 1
        ]], { accountId }) or {}

        balance = rows[1] and rows[1].balance or nil
        Debug(("[bablo-atm] Balance by DB fallback %s: %s"):format(accountId, tostring(balance)))
    end

    return tonumber(balance) or 0
end

local function removeMoneyForSession(source, session, amount)
    local result = callBankingExport("RemoveMoneyByCard", session.cardNumber, amount, "ATM_WITHDRAWAL", source)

    if result and result.success == true then
        return result
    end

    if result and result.message ~= "CARD_NOT_FOUND" then
        return result
    end

    Debug(("[bablo-atm] RemoveMoneyByCard failed for %s, falling back to account %s"):format(
        tostring(session.cardNumber),
        tostring(session.accountId)
    ))

    local resourceName = getBankingResource()
    local ok, accountResult = pcall(function()
        return exports[resourceName]:RemoveMoney(session.accountId, amount, "ATM_WITHDRAWAL", source, session.cardNumber)
    end)

    if not ok then
        Error(("[bablo-atm] Account fallback withdrawal failed: %s"):format(accountResult))
        return {
            success = false,
            message = "BANKING_EXPORT_FAILED",
        }
    end

    Debug("[bablo-atm] Account fallback withdrawal result:", json.encode(accountResult or {}, { indent = true }))

    return accountResult
end

local function addMoneyForSession(source, session, amount)
    local result = callBankingExport("AddMoneyByCard", session.cardNumber, amount, "ATM_DEPOSIT", source)

    if result and result.success == true then
        return result
    end

    if result and result.message ~= "CARD_NOT_FOUND" then
        return result
    end

    Debug(("[bablo-atm] AddMoneyByCard failed for %s, falling back to account %s"):format(
        tostring(session.cardNumber),
        tostring(session.accountId)
    ))

    local resourceName = getBankingResource()
    local ok, accountResult = pcall(function()
        return exports[resourceName]:AddMoney(session.accountId, amount, "ATM_DEPOSIT", source, session.cardNumber)
    end)

    if not ok then
        Error(("[bablo-atm] Account fallback deposit failed: %s"):format(accountResult))
        return {
            success = false,
            message = "BANKING_EXPORT_FAILED",
        }
    end

    Debug("[bablo-atm] Account fallback deposit result:", json.encode(accountResult or {}, { indent = true }))

    return accountResult
end

local function normalizeCardData(item)
    if type(item) ~= "table" then
        return nil
    end

    local metadata = item.info or item.metadata or item
    if type(metadata) ~= "table" then
        return nil
    end

    local cardNumber = metadata.cardNumber or metadata.card_number
    if not cardNumber or tostring(cardNumber) == "" then
        return nil
    end

    local account = metadata.account or metadata.accountId or metadata.accountNumber or metadata.linkedAccountId or metadata.account_number
    if not account or tostring(account) == "" then
        account = callBankingExport("GetAccountFromCard", tostring(cardNumber))
    end

    if not account or tostring(account) == "" then
        return nil
    end

    return {
        info = {
            cardNumber = tostring(cardNumber),
            account = tostring(account),
            name = tostring(metadata.name or "Cardholder"),
            balance = tonumber(metadata.balance) or 0,
        }
    }
end

local function resolveDefaultCard(source, options)
    local account = callBankingExport("GetDefaultAccountNumber", source)
    if not account or tostring(account) == "" then
        return nil, "DEFAULT_ACCOUNT_NOT_FOUND"
    end

    account = tostring(account)

    local cards = MySQL.query.await([[
        SELECT card_number, name
        FROM bablo_bank_cards
        WHERE account_number = ? AND state = 0
        ORDER BY created_at DESC
    ]], { account }) or {}

    if #cards == 0 then
        return nil, "NO_ACTIVE_CARD_ON_DEFAULT_ACCOUNT"
    end

    local index = 1
    if type(options) == "table" and options.select == "random" and #cards > 1 then
        index = math.random(1, #cards)
    end

    local card = cards[index]
    local cardNumber = tostring(card.card_number)
    local balance = getBalanceForCard(source, cardNumber, account)

    return {
        info = {
            cardNumber = cardNumber,
            account = account,
            name = tostring(card.name or "Cardholder"),
            balance = tonumber(balance) or 0,
        }
    }
end

local function openATMForCard(source, item, options)
    if not source then
        return false, "INVALID_PLAYER"
    end

    local cardData = normalizeCardData(item)
    if not cardData then
        cardData = resolveDefaultCard(source, options)
    end

    if not cardData then
        Debug(("[bablo-atm] Failed to resolve card for player %s"):format(source))
        return false, "CARD_NOT_FOUND"
    end

    local info = cardData.info or {}
    info.balance = getBalanceForCard(source, info.cardNumber, info.account)

    local pin = getCardPin(info.cardNumber)

    sessions[source] = {
        cardNumber = info.cardNumber,
        accountId = info.account,
        name = info.name,
        pin = pin,
        authenticated = false,
    }

    Debug(("[bablo-atm] Opening ATM for player %s with card %s"):format(source, tostring(info.cardNumber)))

    TriggerClientEvent("bablo-atm:client:UseCreditCard", source, {
        id = info.account,
        name = info.name,
        balance = tonumber(info.balance) or 0,
        cardNumber = info.cardNumber,
    })

    return true
end

function OnCardOpen(source, item)
    return openATMForCard(source, item, { select = "first" })
end

function UseCreditCard(source, item, options)
    return openATMForCard(source, item, options or { select = "first" })
end

local function isAuthenticated(source)
    return sessions[source] and sessions[source].authenticated == true
end

local function getSession(source)
    if not isAuthenticated(source) then
        return nil
    end

    return sessions[source]
end

local function validateAmount(amount)
    amount = tonumber(amount)

    if not amount or amount <= 0 then
        return nil, "INVALID_AMOUNT"
    end

    return math.floor(amount), nil
end

RegisterServerCallback({
    eventName = "bablo-atm:server:ValidatePin",
    eventCallback = function(source, data)
        local session = sessions[source]
        if not session then
            return {
                success = false,
                message = "No active session",
            }
        end

        if tostring(session.pin) ~= tostring(data.pin) then
            Debug(("[bablo-atm] Invalid PIN for player %s"):format(source))
            return {
                success = false,
                message = Translate("INVALID_PIN"),
            }
        end

        session.authenticated = true

        return {
            success = true,
            cardData = {
                name = session.name,
                cardNumber = session.cardNumber,
                accountId = session.accountId,
                balance = getBalanceForCard(source, session.cardNumber, session.accountId),
            }
        }
    end
})

RegisterServerCallback({
    eventName = "bablo-atm:server:GetBalance",
    eventCallback = function(source)
        local session = getSession(source)
        if not session then
            return {
                success = false,
                message = "Not authenticated",
            }
        end

        local balance = getBalanceForCard(source, session.cardNumber, session.accountId)

        return {
            success = true,
            data = {
                balance = balance,
            }
        }
    end
})

RegisterServerCallback({
    eventName = "bablo-atm:server:WithdrawMoney",
    eventCallback = function(source, data)
        local session = getSession(source)
        if not session then
            return {
                success = false,
                message = "Not authenticated",
            }
        end

        local amount, amountError = validateAmount(data and data.amount)
        if not amount then
            return {
                success = false,
                message = amountError,
            }
        end

        local frozen = callBankingExport("IsCardFrozen", session.cardNumber)
        if frozen then
            return {
                success = false,
                message = "Card is frozen, please contact support",
            }
        end

        local balance = getBalanceForCard(source, session.cardNumber, session.accountId)
        local creditLimit, creditUsed = callBankingExport("GetCreditLimitFromCard", session.cardNumber)
        creditLimit = tonumber(creditLimit) or 0
        creditUsed = tonumber(creditUsed) or 0

        if creditLimit > 0 and creditUsed + amount > creditLimit then
            return {
                success = false,
                message = "Insufficient credit limit",
            }
        end

        if amount > balance then
            return {
                success = false,
                message = "Insufficient funds",
            }
        end

        local result = removeMoneyForSession(source, session, amount)

        if not result or result.success ~= true then
            return {
                success = false,
                message = (result and result.message) or "Withdrawal failed",
            }
        end

        if not AddCash(source, amount) then
            Warn("[bablo-atm] Failed to add cash after bank withdrawal for player", source)
            return {
                success = false,
                message = "Failed to dispense cash",
            }
        end

        local newBalance = getBalanceForCard(source, session.cardNumber, session.accountId)

        return {
            success = true,
            newBalance = newBalance,
        }
    end
})

RegisterServerCallback({
    eventName = "bablo-atm:server:DepositMoney",
    eventCallback = function(source, data)
        local session = getSession(source)
        if not session then
            return {
                success = false,
                message = "Not authenticated",
            }
        end

        local amount, amountError = validateAmount(data and data.amount)
        if not amount then
            return {
                success = false,
                message = amountError,
            }
        end

        local cash = tonumber(GetCash(source)) or 0
        if amount > cash then
            return {
                success = false,
                message = "INSUFFICIENT_CASH",
            }
        end

        RemoveCash(source, amount)

        local result = addMoneyForSession(source, session, amount)
        if not result or result.success ~= true then
            AddCash(source, amount)
            return {
                success = false,
                message = (result and result.message) or "Deposit failed",
            }
        end

        local newBalance = getBalanceForCard(source, session.cardNumber, session.accountId)

        return {
            success = true,
            newBalance = newBalance,
        }
    end
})

AddEventHandler("playerDropped", function()
    sessions[source] = nil
end)

RegisterNetEvent("bablo-atm:server:ClearAuthentication", function()
    sessions[source] = nil
end)

RegisterNetEvent("bablo-atm:server:UseCreditCardFromTarget", function(options)
    local ok, err = UseCreditCard(source, nil, options)
    if not ok then
        Debug(("[bablo-atm] Target-triggered open failed for player %s: %s"):format(source, tostring(err)))
    end
end)

exports("OnCardOpen", OnCardOpen)
exports("UseCreditCard", UseCreditCard)
