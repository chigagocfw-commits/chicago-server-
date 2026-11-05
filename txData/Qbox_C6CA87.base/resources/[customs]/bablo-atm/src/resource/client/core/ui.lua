UI = UI or {}

if not ATM or not DUI then
    error("ATM and DUI modules must be loaded before UI")
end

function UI.sendMessage(action, data)
    DUI.sendMessage({
        action = action,
        data = data,
    })
end

function UI.pushLocale()
    UI.sendMessage("ui:setLocale", {
        locale = GetCurrentLocale(),
        currency = (Config and Config.Currency) or "USD",
        currencySymbol = Config and Config.CurrencySymbol or nil,
        dict = Locales or {},
    })
end

function UI.setStage(stage)
    if ATM then
        ATM:setCurrentStage(stage)
    end

    UI.sendMessage("atm:setStage", stage)
end

function UI.cardInserted(inserted)
    UI.sendMessage("atm:cardInserted", inserted == true)
end

function UI.transactionComplete(success, transactionType, amount, newBalance, message)
    UI.sendMessage("atm:transactionComplete", {
        success = success,
        type = transactionType,
        amount = amount,
        newBalance = newBalance,
        message = message,
    })
end

function UI.sendCardData(cardData)
    UI.sendMessage("atm:cardData", {
        name = cardData.name,
        cardNumber = cardData.cardNumber,
        accountId = cardData.id or cardData.accountId,
        balance = tonumber(cardData.balance) or 0,
    })
end

function UI.sendPresetSelected(index)
    UI.sendMessage("preset:selected", index)
end

function UI.sendCustomInputFocus()
    UI.sendMessage("preset:focusCustom", true)
end

function UI.sendPresetConfirm()
    UI.sendMessage("preset:confirm", true)
end

function UI.sendPresetBack()
    UI.sendMessage("preset:back", true)
end
