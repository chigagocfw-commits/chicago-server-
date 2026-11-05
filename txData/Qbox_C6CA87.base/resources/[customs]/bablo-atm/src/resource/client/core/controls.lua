Controls = Controls or {}

Controls.DISABLED_WHEN_USING = {
    24, 257, 263, 264, 69, 92, 114, 331, 21, 22,
    36, 23, 75, 47, 157, 158, 160, 164, 165, 172,
    173, 174, 175, 37, 191, 199, 200, 322, 194, 202,
}

local function disablePauseControls()
    DisableControlAction(0, 199, true)
    DisableControlAction(0, 200, true)
    DisableControlAction(0, 322, true)
end

local function closePauseMenuIfOpen()
    if IsPauseMenuActive() then
        SetPauseMenuActive(false)
    end
end

function Controls.disableControls()
    for _, control in ipairs(Config.DisableControls or {}) do
        DisableControlAction(0, control, true)
    end

    for _, control in ipairs(Controls.DISABLED_WHEN_USING) do
        DisableControlAction(0, control, true)
    end
end

function Controls.handleEscape()
    local pressedEscape = IsDisabledControlJustPressed(0, 200)
        or IsDisabledControlJustPressed(0, 322)
        or IsDisabledControlJustPressed(0, 202)

    if not pressedEscape then
        return
    end

    if Controls.suppressPauseFor then
        Controls.suppressPauseFor(2000)
    end

    closePauseMenuIfOpen()

    local currentStage = ATM:getCurrentStage()
    if currentStage == "withdraw" or currentStage == "deposit" then
        Debug("ESC pressed on withdraw/deposit, navigating back to home")
        UI.setStage("home")
        return
    end

    Debug("Emergency ATM exit triggered")
    TriggerEvent("bablo-atm:client:EndATM")
end

function Controls.suppressPauseFor(duration)
    local deadline = GetGameTimer() + (duration or 2000)

    CreateThread(function()
        while GetGameTimer() < deadline do
            disablePauseControls()
            DisableFrontendThisFrame()
            closePauseMenuIfOpen()
            Wait(0)
        end
    end)
end

CreateThread(function()
    while true do
        if ATM:isUsing() then
            Controls.disableControls()
            Controls.handleEscape()
            DisableFrontendThisFrame()
            closePauseMenuIfOpen()
            Wait(0)
        else
            Wait(500)
        end
    end
end)
