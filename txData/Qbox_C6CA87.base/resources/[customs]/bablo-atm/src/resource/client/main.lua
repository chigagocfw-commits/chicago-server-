if not ATM or not Detection or not DUI or not UI or not Transactions then
    error("Core modules must be loaded before main.lua")
end

if GetCurrentResourceName() ~= "bablo-atm" then
    error("Resource name must be 'bablo-atm'")
    return
end

local function suppressPause()
    if Controls and Controls.suppressPauseFor then
        Controls.suppressPauseFor(2500)
    end
end

local function enableKeypad(atmEntity)
    if Config.EnableKeypad and KeypadHandler and KeypadHandler.enableKeypad then
        KeypadHandler.enableKeypad(atmEntity)
    end
end

local function disableKeypad()
    if KeypadHandler and KeypadHandler.disableKeypad then
        KeypadHandler.disableKeypad()
    end
end

local function showPinEntry(atmEntity)
    UI.setStage("awaitPin")
    SendNotification(Translate("ENTER_PIN_PROMPT"))
    enableKeypad(atmEntity)
end

RegisterNetEvent("bablo-atm:client:UseCreditCard", function(cardData)
    local isClose, atmEntity = Detection.isPlayerCloseToATM()
    Debug("Player used credit card event triggered.")

    if not isClose or not atmEntity then
        SendNotification(Translate("NOT_NEAR_ATM"))
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        SendNotification(Translate("CANNOT_USE_ATM_IN_VEHICLE"))
        return
    end

    ATM:setCurrentCardData(cardData)
    ATM:setCurrentATM(atmEntity)

    local dui = DUI.setCurrentATMDUI()
    if dui then
        ATM:setCurrentDUI(dui)

        if UI and UI.pushLocale then
            UI.pushLocale()
        end
    else
        Debug("Warning: Could not set DUI, UI may not work properly")
    end

    ATM:setUsageState(true)

    if Config.EnableATMAnimations and AnimationHandler and AnimationHandler.insertCardSequence then
        Debug("Starting animation sequence...")

        CreateThread(function()
            AnimationHandler.insertCardSequence(atmEntity, function()
                Debug("Animation sequence complete, showing PIN entry")
                showPinEntry(atmEntity)
            end)
        end)
    else
        showPinEntry(atmEntity)
    end
end)

RegisterNUICallback("atm:pinValidated", function(data, cb)
    Debug("PIN validation requested:", tostring(data and data.pin))

    local cardData = ATM:getCurrentCardData()
    if not cardData then
        Debug("No player data found")
        cb({
            success = false,
            message = Translate("NO_PLAYER_DATA"),
        })
        return
    end

    local response = TriggerServerCallback({
        eventName = "bablo-atm:server:ValidatePin",
        args = {
            pin = data and data.pin,
            cardNumber = cardData.cardNumber,
        },
        timeout = 5000,
    })

    if response and response.success then
        Debug("PIN validated successfully on server")

        if response.cardData then
            cardData.name = response.cardData.name or cardData.name
            cardData.cardNumber = response.cardData.cardNumber or cardData.cardNumber
            cardData.accountId = response.cardData.accountId or cardData.accountId
            cardData.balance = response.cardData.balance or cardData.balance
            ATM:setCurrentCardData(cardData)
        end

        UI.sendCardData(cardData)
        UI.setStage("home")
        cb({ success = true })
        return
    end

    local message = (response and response.message) or Translate("INVALID_PIN")
    Debug("PIN validation failed:", message)
    cb({
        success = false,
        message = message,
    })
end)

RegisterNetEvent("bablo-atm:client:EndATM", function()
    suppressPause()
    ATM:setUsageState(false)
    TriggerServerEvent("bablo-atm:server:ClearAuthentication")

    disableKeypad()

    if AnimationHandler and AnimationHandler.endATMSequence then
        AnimationHandler.endATMSequence()
    end

    UI.cardInserted(false)
    UI.setStage("awaitCard")
    ATM:reset()
end)

RegisterNUICallback("atm:close", function(_, cb)
    suppressPause()
    TriggerEvent("bablo-atm:client:EndATM")
    cb("ok")
end)

RegisterNUICallback("atm:cancelDeposit", function(_, cb)
    suppressPause()
    UI.setStage("home")
    cb("ok")
end)

RegisterNUICallback("atm:getBalance", function(_, cb)
    Debug("Getting balance from server")

    local response = TriggerServerCallback({
        eventName = "bablo-atm:server:GetBalance",
        args = {},
        timeout = 5000,
    })

    Debug("Balance response:", json.encode(response or {}, { indent = true }))

    if response and response.success then
        cb(response.data.balance)
        return
    end

    cb({
        message = (response and response.message) or "Failed to get balance",
    })
end)

RegisterNUICallback("atm:getLocale", function(_, cb)
    cb({
        success = true,
        data = {
            locale = GetCurrentLocale(),
            currency = (Config and Config.Currency) or "USD",
            currencySymbol = Config and Config.CurrencySymbol or nil,
            dict = Locales or {},
        }
    })
end)

RegisterNUICallback("atm:withdraw", function(data, cb)
    Transactions.handleTransaction("withdraw", data, cb)
end)

RegisterNUICallback("atm:deposit", function(data, cb)
    Debug("Deposit request:", json.encode(data or {}, { indent = true }))
    Transactions.handleTransaction("deposit", data, cb)
end)

RegisterNUICallback("atm:registerButtons", function(data, cb)
    if data and data.buttons then
        startButtonThread(data.buttons)
    end

    cb("ok")
end)

RegisterNUICallback("atm:stageChanged", function(data, cb)
    if data and data.stage then
        Debug("Stage changed from UI:", tostring(data.stage))
        ATM:setCurrentStage(data.stage)

        if UI and UI.pushLocale then
            UI.pushLocale()
        end
    end

    cb("ok")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    FreezeEntityPosition(PlayerPedId(), false)
    disableKeypad()

    if AnimationHandler and AnimationHandler.endATMSequence then
        AnimationHandler.endATMSequence()
    end

    if CameraHandler and CameraHandler.destroyAtmCamera then
        CameraHandler.destroyAtmCamera()
    end

    DUI.clearAllReplaceTextures()
    ATM:reset()
end)
