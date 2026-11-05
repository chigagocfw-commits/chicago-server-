if not Detection or not UI then
    error("Core modules must be loaded before keypad.lua")
end

local keypadButtons = {}
local hoveredButtonIndex = nil
local previousHoveredButtonIndex = nil
local cursorVisible = false
local currentATM = nil
local isKeypadActive = false
local lastConfirmAt = 0
local confirmCooldown = 1000

local function button(value, x, y, z)
    return {
        value = value,
        offset = vector3(x, y, z),
    }
end

local keypadLayouts = {
    [GetHashKey("prop_fleeca_atm")] = {
        button("1", -0.145, -0.148, 1.04),
        button("2", -0.12, -0.148, 1.04),
        button("3", -0.095, -0.148, 1.04),
        button("4", -0.152, -0.145, 1.0),
        button("5", -0.128, -0.145, 1.0),
        button("6", -0.102, -0.145, 1.0),
        button("7", -0.157, -0.147, 0.96),
        button("8", -0.132, -0.147, 0.96),
        button("9", -0.102, -0.147, 0.96),
        button("clear", -0.157, -0.182, 0.96),
        button("0", -0.136, -0.155, 0.92),
        button("enter", -0.102, -0.182, 0.96),
        button("deposit", 0.1, 0.23, 1.04),
        button("withdraw", -0.38, 0.23, 1.04),
    },
    [GetHashKey("prop_atm_01")] = {
        button("1", -0.09, -0.22, 0.92),
        button("2", -0.06, -0.22, 0.92),
        button("3", -0.03, -0.22, 0.92),
        button("4", -0.09, -0.22, 0.89),
        button("5", -0.06, -0.22, 0.89),
        button("6", -0.03, -0.22, 0.89),
        button("7", -0.09, -0.22, 0.85),
        button("8", -0.055, -0.22, 0.85),
        button("9", -0.02, -0.22, 0.85),
        button("clear", -0.09, -0.24, 0.83),
        button("0", -0.055, -0.24, 0.83),
        button("enter", -0.017, -0.24, 0.83),
        button("deposit", 0.102, -0.11, 1.062),
        button("withdraw", -0.29, 0.22, 0.994),
    },
    [GetHashKey("prop_atm_02")] = {
        button("1", -0.155, -0.154, 1.04),
        button("2", -0.13, -0.154, 1.04),
        button("3", -0.105, -0.154, 1.04),
        button("4", -0.16, -0.154, 1.0),
        button("5", -0.132, -0.154, 1.0),
        button("6", -0.107, -0.154, 1.0),
        button("7", -0.165, -0.154, 0.96),
        button("8", -0.134, -0.154, 0.96),
        button("9", -0.109, -0.154, 0.96),
        button("clear", -0.08, -0.12, 0.96),
        button("0", -0.136, -0.165, 0.92),
        button("enter", -0.08, -0.157, 0.96),
        button("deposit", 0.12, 0.23, 1.04),
        button("withdraw", -0.38, 0.23, 1.04),
    },
    [GetHashKey("prop_atm_03")] = {
        button("1", -0.155, -0.154, 1.04),
        button("2", -0.13, -0.154, 1.04),
        button("3", -0.105, -0.154, 1.04),
        button("4", -0.16, -0.154, 1.0),
        button("5", -0.132, -0.154, 1.0),
        button("6", -0.107, -0.154, 1.0),
        button("7", -0.165, -0.154, 0.96),
        button("8", -0.134, -0.154, 0.96),
        button("9", -0.109, -0.154, 0.96),
        button("clear", -0.08, -0.12, 0.96),
        button("0", -0.14, -0.165, 0.92),
        button("enter", -0.08, -0.157, 0.96),
        button("deposit", 0.0, -0.154, 1.225),
        button("withdraw", -0.225, -0.154, 1.225),
    },
}

local function getLayoutForATM(atmEntity)
    if not DoesEntityExist(atmEntity) then
        return nil
    end

    return keypadLayouts[GetEntityModel(atmEntity)]
end

local function buildKeypadButtons(atmEntity)
    local layout = getLayoutForATM(atmEntity)
    if not layout then
        return {}
    end

    local buttons = {}
    for _, config in ipairs(layout) do
        buttons[#buttons + 1] = {
            value = config.value,
            worldPos = GetOffsetFromEntityInWorldCoords(
                atmEntity,
                config.offset.x,
                config.offset.y,
                config.offset.z
            ),
        }
    end

    return buttons
end

local function isButtonUnderCursor(buttonData, cursorX, cursorY)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
        buttonData.worldPos.x,
        buttonData.worldPos.y,
        buttonData.worldPos.z
    )

    if not onScreen then
        return false
    end

    local halfWidth = (buttonData.value == "deposit" or buttonData.value == "withdraw") and 0.008 or 0.015
    local halfHeight = (buttonData.value == "deposit" or buttonData.value == "withdraw") and 0.016 or 0.02

    return cursorX >= screenX - halfWidth
        and cursorX <= screenX + halfWidth
        and cursorY >= screenY - halfHeight
        and cursorY <= screenY + halfHeight
end

local function getHoveredButton(buttons, cursorX, cursorY)
    for index, buttonData in ipairs(buttons) do
        if isButtonUnderCursor(buttonData, cursorX, cursorY) then
            return index, buttonData
        end
    end

    return nil, nil
end

local function sendButtonHover(value, hovered)
    if value == "deposit" or value == "withdraw" then
        UI.sendMessage("buttonHover", {
            button = value,
            hovered = hovered,
        })
    end
end

local function canConfirm()
    local now = GetGameTimer()

    if now - lastConfirmAt < confirmCooldown then
        Debug("Ignored preset:confirm due to cooldown")
        return false
    end

    lastConfirmAt = now
    return true
end

local function pressConfirm()
    if not canConfirm() then
        return
    end

    PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true)
    UI.sendMessage("preset:confirm", true)
end

local function handleTransactionButton(value, stage)
    if stage == "withdraw" or stage == "deposit" then
        if value == "deposit" then
            Debug(("Deposit button (Confirm) pressed on %s page"):format(tostring(stage)))
            pressConfirm()
        elseif value == "withdraw" then
            Debug(("Withdraw button (Cancel) pressed on %s page"):format(tostring(stage)))
            PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            UI.setStage("home")
        end

        return
    end

    if not stage or stage == "home" then
        PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true)
        UI.setStage(value)
        return
    end

    PlaySoundFrontend(-1, "ERROR", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
end

local function handleKeypadButton(value)
    if not value then
        return
    end

    Debug("Keypad button clicked: " .. tostring(value))

    local stage = ATM:getCurrentStage()

    if value == "deposit" or value == "withdraw" then
        handleTransactionButton(value, stage)
        return
    end

    PlaySoundFrontend(-1, "PIN_BUTTON", "ATM_SOUNDS", true)

    if value == "enter" then
        UI.sendMessage("keyboardInput", "enter")
    elseif value == "clear" then
        UI.sendMessage("keyboardInput", "backspace")
    else
        Debug("Keyboard input: " .. tostring(value))
        UI.sendMessage("keyboardInput", value)
    end
end

local function drawDebugButtonOverlay(buttonData)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(
        buttonData.worldPos.x,
        buttonData.worldPos.y,
        buttonData.worldPos.z
    )

    if not onScreen then
        return
    end

    DrawRect(screenX, screenY, 0.02, 0.02, 255, 0, 0, 150)
    SetTextFont(4)
    SetTextScale(0.3, 0.3)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(buttonData.value)
    DrawText(screenX - 0.01, screenY - 0.01)
end

local function drawDebugOverlay(cursorX, cursorY)
    if not Config.DEBUG then
        return
    end

    SetTextFont(4)
    SetTextProportional(true)
    SetTextScale(0.4, 0.4)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    AddTextComponentString(("Screen: %.4f, %.4f"):format(cursorX, cursorY))
    DrawText(0.5, 0.06)

    SetTextFont(4)
    SetTextScale(0.25, 0.25)
    SetTextColour(255, 255, 0, 255)
    SetTextEntry("STRING")
    AddTextComponentString(("Total buttons: %d"):format(#keypadButtons))
    DrawText(0.02, 0.1)

    for _, buttonData in ipairs(keypadButtons) do
        drawDebugButtonOverlay(buttonData)
    end
end

local function showKeypadHelp()
    BeginTextCommandDisplayHelp("STRING")
    AddTextComponentSubstringPlayerName(Translate("PIN_KEYPAD_HINT"))
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function logEnabledKeypad(atmEntity)
    Debug("Keypad enabled with " .. #keypadButtons .. " buttons")

    if not Config.DEBUG then
        return
    end

    Debug("ATM Model: " .. tostring(GetEntityModel(atmEntity)))
    Debug("Button count: " .. #keypadButtons)

    for index, buttonData in ipairs(keypadButtons) do
        Debug(("Button %d: %s at world pos %.3f, %.3f, %.3f"):format(
            index,
            buttonData.value,
            buttonData.worldPos.x,
            buttonData.worldPos.y,
            buttonData.worldPos.z
        ))
    end
end

local function enableKeypad(atmEntity)
    if isKeypadActive then
        return
    end

    isKeypadActive = true
    cursorVisible = true
    currentATM = atmEntity
    keypadButtons = buildKeypadButtons(atmEntity)

    SetMouseCursorVisible(true)
    logEnabledKeypad(atmEntity)
end

local function disableKeypad()
    if not isKeypadActive then
        return
    end

    if previousHoveredButtonIndex and keypadButtons[previousHoveredButtonIndex] then
        sendButtonHover(keypadButtons[previousHoveredButtonIndex].value, false)
    end

    isKeypadActive = false
    cursorVisible = false
    currentATM = nil
    keypadButtons = {}
    hoveredButtonIndex = nil
    previousHoveredButtonIndex = nil

    SetMouseCursorVisible(false)
    Debug("Keypad disabled")
end

local function isActive()
    return isKeypadActive
end

CreateThread(function()
    while true do
        local waitMs = 500

        if isKeypadActive and #keypadButtons > 0 then
            waitMs = 0

            if cursorVisible then
                SetMouseCursorThisFrame()
            end

            local cursorX = GetControlNormal(0, 239)
            local cursorY = GetControlNormal(0, 240)
            local currentHoveredIndex, currentHoveredButton = getHoveredButton(keypadButtons, cursorX, cursorY)
            hoveredButtonIndex = currentHoveredIndex

            if hoveredButtonIndex ~= previousHoveredButtonIndex then
                if previousHoveredButtonIndex and keypadButtons[previousHoveredButtonIndex] then
                    sendButtonHover(keypadButtons[previousHoveredButtonIndex].value, false)
                end

                if hoveredButtonIndex and currentHoveredButton then
                    sendButtonHover(currentHoveredButton.value, true)
                end

                previousHoveredButtonIndex = hoveredButtonIndex
            end

            SetMouseCursorSprite(hoveredButtonIndex and 5 or 1)
            drawDebugOverlay(cursorX, cursorY)

            if hoveredButtonIndex and currentHoveredButton then
                local clicked = IsControlJustPressed(0, 24) or IsDisabledControlJustPressed(0, 24)
                if clicked then
                    handleKeypadButton(currentHoveredButton.value)
                end
            end

            showKeypadHelp()

            if IsControlJustPressed(0, 194) or IsControlJustPressed(0, 202) then
                disableKeypad()
                TriggerEvent("bablo-atm:client:EndATM")
            end
        end

        Wait(waitMs)
    end
end)

RegisterCommand("atm_test_offset", function(_, args)
    local x = tonumber(args[1]) or 0.0
    local y = tonumber(args[2]) or 0.0
    local z = tonumber(args[3]) or 1.0
    local isNearATM, atmEntity = Detection.isPlayerCloseToATM()

    if not isNearATM or not atmEntity then
        Debug("Not near an ATM")
        return
    end

    local worldPos = GetOffsetFromEntityInWorldCoords(atmEntity, x, y, z)
    local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(worldPos.x, worldPos.y, worldPos.z)

    Debug(("Test Offset: X=%.3f, Y=%.3f, Z=%.3f"):format(x, y, z))
    Debug(("Screen Pos: X=%.3f, Y=%.3f, OnScreen=%s"):format(screenX, screenY, tostring(onScreen)))

    CreateThread(function()
        local deadline = GetGameTimer() + 5000

        while GetGameTimer() < deadline do
            Wait(0)

            local drawWorldPos = GetOffsetFromEntityInWorldCoords(atmEntity, x, y, z)
            local visible, drawX, drawY = GetScreenCoordFromWorldCoord(drawWorldPos.x, drawWorldPos.y, drawWorldPos.z)

            if visible then
                DrawRect(drawX, drawY, 0.02, 0.028, 255, 0, 0, 255)
                SetTextFont(4)
                SetTextScale(0.3, 0.3)
                SetTextColour(255, 255, 255, 255)
                SetTextEntry("STRING")
                AddTextComponentString(("%.3f, %.3f, %.3f"):format(x, y, z))
                DrawText(drawX, drawY - 0.02)
            end
        end
    end)
end, false)

KeypadHandler = {
    enableKeypad = enableKeypad,
    disableKeypad = disableKeypad,
    isKeypadActive = isActive,
}
