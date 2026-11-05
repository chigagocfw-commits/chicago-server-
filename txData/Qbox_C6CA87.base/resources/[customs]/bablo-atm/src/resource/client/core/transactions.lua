Transactions = Transactions or {}

if not ATM or not UI then
    error("ATM and UI modules must be loaded before Transactions")
end

local serverEvents = {
    withdraw = "bablo-atm:server:WithdrawMoney",
    deposit = "bablo-atm:server:DepositMoney",
}

local labels = {
    withdraw = "WITHDRAW",
    deposit = "DEPOSIT",
}

function Transactions.handleTransaction(transactionType, data, cb)
    local amount = tonumber(data and data.amount)
    if not amount or amount <= 0 then
        cb({
            success = false,
            message = Translate("INVALID_AMOUNT"),
        })
        return
    end

    local eventName = serverEvents[transactionType]
    if not eventName then
        cb({
            success = false,
            message = "Invalid transaction type",
        })
        return
    end

    Debug(transactionType .. " request:", amount)

    local response = TriggerServerCallback({
        eventName = eventName,
        args = { amount = amount },
        timeout = 5000,
    })

    Debug("Transaction response:", json.encode(response or {}, { indent = true }))

    if response and response.success then
        local label = Translate(labels[transactionType])
        local message = Translate("TRANSACTION_SUCCESS", {
            label,
            tostring(response.newBalance),
        })

        SendNotification(message)
        UI.transactionComplete(true, transactionType, amount, response.newBalance)

        cb({
            success = true,
            data = response,
        })
        return
    end

    local message
    if response and response.message then
        message = Translate(response.message)
    else
        local label = Translate(labels[transactionType])
        message = Translate("TRANSACTION_FAILED", { label })
    end

    SendNotification(Translate("TRANSACTION_FAILED_PREFIX", { message }))
    UI.transactionComplete(false, nil, nil, nil, message)

    cb({
        success = false,
        message = message,
    })
end
