PresetNavigation = PresetNavigation or {}

if not ATM or not UI then
    error("ATM and UI modules must be loaded before PresetNavigation")
end

PresetNavigation.State = PresetNavigation.State or {
    selectedIndex = nil,
    isCustomFocused = false,
}

local presets = { 100, 200, 500, 1000, 2000, 5000 }
local controls = {
    left = 174,
    right = 175,
    up = 172,
    down = 173,
    tab = 37,
}

function PresetNavigation.reset()
    PresetNavigation.State.selectedIndex = nil
    PresetNavigation.State.isCustomFocused = false
end

local function isTransactionStage(stage)
    return stage == "withdraw" or stage == "deposit"
end

local function sendSelection(label)
    UI.sendPresetSelected(PresetNavigation.State.selectedIndex - 1)
    Debug(("%s: Selected preset %s"):format(label, PresetNavigation.State.selectedIndex))
end

local function setCustomFocus()
    PresetNavigation.State.isCustomFocused = true
    PresetNavigation.State.selectedIndex = nil
    UI.sendCustomInputFocus()
    Debug("TAB pressed: Focus custom input")
end

local function moveSelection(delta, defaultIndex, label)
    PresetNavigation.State.isCustomFocused = false

    if PresetNavigation.State.selectedIndex == nil then
        PresetNavigation.State.selectedIndex = defaultIndex
    else
        local count = #presets
        PresetNavigation.State.selectedIndex = ((PresetNavigation.State.selectedIndex - 1 + delta) % count) + 1
    end

    sendSelection(label)
end

function PresetNavigation.handleNavigation()
    if not ATM:isUsing() then
        return
    end

    local stage = ATM:getCurrentStage()
    if not isTransactionStage(stage) then
        PresetNavigation.reset()
        return
    end

    if IsDisabledControlJustPressed(0, controls.tab) then
        setCustomFocus()
        return
    end

    if IsDisabledControlJustPressed(0, controls.left) then
        moveSelection(-1, #presets, "Arrow Left")
        return
    end

    if IsDisabledControlJustPressed(0, controls.right) then
        moveSelection(1, 1, "Arrow Right")
        return
    end

    if IsDisabledControlJustPressed(0, controls.up) then
        moveSelection(-3, #presets, "Arrow Up")
        return
    end

    if IsDisabledControlJustPressed(0, controls.down) then
        moveSelection(3, 1, "Arrow Down")
    end
end

CreateThread(function()
    while true do
        if ATM:isUsing() then
            PresetNavigation.handleNavigation()
            Wait(0)
        else
            PresetNavigation.reset()
            Wait(500)
        end
    end
end)
