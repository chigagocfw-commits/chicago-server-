function handleCursor()
    SetMouseCursorVisible(true)
    SetMouseCursorThisFrame()

    return GetControlNormal(0, 239), GetControlNormal(0, 240)
end

function isClickInsideArea(cursorX, cursorY, minX, minY, maxX, maxY)
    return minX <= cursorX and cursorX <= maxX and minY <= cursorY and cursorY <= maxY
end

function isInKeypadInputMode(stage)
    return stage == "deposit" or stage == "withdraw"
end

function isTransactionControlButton(action)
    return action == "submit" or action == "cancel" or action == "back"
end

local function playUiSound(soundName)
    PlaySoundFrontend(-1, soundName, "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

local function rejectButton(action, stage)
    Debug(("Blocking UI navigation button '%s' during keypad input mode"):format(tostring(action)))
    playUiSound("ERROR")
end

local function handleDepositButton(stage)
    if stage == "home" then
        Debug("Home deposit button pressed")
        playUiSound("SELECT")
        UI.setStage("deposit")
        return
    end

    if stage == "withdraw" or stage == "deposit" then
        Debug(("Deposit button (Confirm) pressed on %s page"):format(tostring(stage)))
        playUiSound("SELECT")
        UI.sendPresetConfirm()
        return
    end

    Debug("Deposit button ignored at stage: " .. tostring(stage))
    playUiSound("ERROR")
end

local function handleWithdrawButton(stage)
    if stage == "home" then
        Debug("Home withdraw button pressed")
        playUiSound("SELECT")
        UI.setStage("withdraw")
        return
    end

    if stage == "withdraw" or stage == "deposit" then
        Debug(("Withdraw button (Cancel) pressed on %s page"):format(tostring(stage)))
        playUiSound("BACK")
        UI.setStage("home")
        return
    end

    Debug("Withdraw button ignored at stage: " .. tostring(stage))
    playUiSound("ERROR")
end

function handleRegionClick(region, stage)
    local action = region and region.action
    Debug(("UI button clicked: %s at stage: %s"):format(tostring(action), tostring(stage)))

    if isInKeypadInputMode(stage)
        and action ~= "deposit"
        and action ~= "withdraw"
        and not isTransactionControlButton(action)
    then
        rejectButton(action, stage)
        return
    end

    if action == "deposit" then
        handleDepositButton(stage)
    elseif action == "withdraw" then
        handleWithdrawButton(stage)
    elseif action == "submit" then
        Debug("Submit button pressed")
        playUiSound("SELECT")
        UI.sendPresetConfirm()
    elseif action == "cancel" or action == "back" then
        Debug("Cancel/Back button pressed")
        playUiSound("BACK")
        UI.setStage("home")
    end
end

function handleButtonClicks(buttons, cursorX, cursorY, stage)
    for _, region in ipairs(buttons) do
        if isClickInsideArea(cursorX, cursorY, region.x, region.y, region.x2, region.y2) then
            handleRegionClick(region, stage)
            return true
        end
    end

    return false
end

G_ButtonThreadActive = false

function startButtonThread(buttons)
    if G_ButtonThreadActive then
        return
    end

    G_ButtonThreadActive = true

    CreateThread(function()
        while ATM:isUsing() do
            local waitMs = 100

            if #buttons > 0 then
                waitMs = 0

                local stage = ATM:getCurrentStage()
                local keypadInputMode = isInKeypadInputMode(stage)
                local keypadActive = KeypadHandler
                    and KeypadHandler.isKeypadActive
                    and KeypadHandler.isKeypadActive()

                if not keypadInputMode or not keypadActive then
                    local cursorX, cursorY = handleCursor()
                    local clicked = IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24)

                    if clicked then
                        handleButtonClicks(buttons, cursorX, cursorY, stage)
                    end
                end
            end

            Wait(waitMs)
        end

        G_ButtonThreadActive = false
    end)
end
