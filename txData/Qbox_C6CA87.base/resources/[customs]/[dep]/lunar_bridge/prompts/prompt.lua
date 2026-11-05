-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
-- Prompt UI Module
-- Handles the DUI-based prompt interface

local Prompt = {}

-- DUI Configuration
local DUI_SIZE = 700
local dui = CreateDui(
    string.format("https://cfx-nui-%s/web/index.html", cache.resource),
    DUI_SIZE,
    DUI_SIZE
)

-- Create runtime texture
local duiHandle = GetDuiHandle(dui)
local txd = CreateRuntimeTxd("lunar_prompt")
CreateRuntimeTextureFromDuiHandle(txd, "main", duiHandle)

-- Reload DUI on player load
Framework.onPlayerLoaded(function()
    SetDuiUrl(dui, string.format("https://cfx-nui-%s/web/index.html", cache.resource))
end)

-- State
local currentOptions = {}
local currentIndex = 1
local visibleCount = 1
local canInteractCache = {}
local lastSelectTime = 0

local function isFunctionReference(value)
    return type(value) == "table" and rawget(value, "__cfx_functionReference") ~= nil
end

local function isCallable(value)
    if type(value) == "function" or isFunctionReference(value) then
        return true
    end

    local meta = getmetatable(value)
    return type(meta) == "table" and type(meta.__call) == "function"
end

local function canAttemptCall(value)
    local valueType = type(value)

    if isCallable(value) then
        return true
    end

    if valueType == "table" then
        return getmetatable(value) ~= nil
    end

    return valueType == "userdata"
end

local function resolveCanInteract(option, context)
    if type(option) ~= "table" then
        return false
    end

    if isCallable(option.canInteract) then
        local success, result = pcall(option.canInteract)

        if not success then
            print(("[lunar_bridge] Prompt canInteract failed: %s"):format(result))
            return false
        end

        return result == true
    end

    if type(option.canInteractEvent) == "string" then
        context = context or {}
        context.args = context.args or option.args
        context.allowed = true
        TriggerEvent(option.canInteractEvent, context)
        return context.allowed ~= false
    end

    return true
end

--[[
    Send a message to the DUI
    @param data - Data to send
--]]
local function sendMessage(data)
    SendDuiMessage(dui, json.encode(data))
end

--[[
    Set the available options
    @param options - Table of interaction options
--]]
function Prompt.setOptions(options)
    local formattedOptions = {}
    table.wipe(canInteractCache)
    
    for index, option in ipairs(options) do
        table.insert(formattedOptions, {
            label = option.label,
            icon = option.icon ~= "" and option.icon
        })
        canInteractCache[index] = true
    end
    
    sendMessage({
        action = "set_options",
        options = formattedOptions
    })
    
    currentOptions = options
    visibleCount = 1
end

local canUseOption

--[[
    Update option visibility based on canInteract
--]]
function Prompt.updateOptions()
    table.wipe(canInteractCache)
    
    local visibleOptions = 0
    
    for i, option in ipairs(currentOptions) do
        local canUse = canUseOption(option)
        table.insert(canInteractCache, canUse)
        
        if canUse then
            visibleOptions = visibleOptions + 1
        end
    end
    
    sendMessage({
        action = "update_options",
        canInteract = canInteractCache
    })
    
    -- Adjust index if needed
    if visibleOptions < visibleCount then
        Prompt.setIndex(visibleOptions)
    else
        Prompt.setIndex(currentIndex)
    end
    
    visibleCount = visibleOptions
end

--[[
    Set the currently selected option index
    @param index - Option index (1-based)
--]]
function Prompt.setIndex(index)
    if index <= 0 or index > visibleCount then
        return
    end
    
    currentIndex = index
    
    sendMessage({
        action = "set_index",
        index = currentIndex - 1  -- Convert to 0-based for JS
    })
end

--[[
    Show the prompt UI
--]]
function Prompt.show()
    sendMessage({ action = "show" })
end

--[[
    Hide the prompt UI
--]]
function Prompt.hide()
    sendMessage({ action = "hide" })
    currentOptions = {}
    currentIndex = 1
end

--[[
    Draw the prompt sprite
--]]
function Prompt.draw()
    local width = 0.28
    local height = 0.28 * GetAspectRatio(false)
    
    DrawSprite(
        "lunar_prompt",
        "main",
        0.0, 0.0,
        width, height,
        0.0,
        255, 255, 255, 255
    )
end

local function getOptionHandler(option)
    if type(option) ~= "table" then
        return nil
    end

    local handlers = {
        option.onSelect,
        option.action,
        option.cb,
        option.callback
    }

    for _, handler in ipairs(handlers) do
        if canAttemptCall(handler) then
            return handler
        end
    end

    return nil
end

canUseOption = function(option)
    if not resolveCanInteract(option) then
        return false
    end

    if getOptionHandler(option) then
        return true
    end

    return type(option and option.event) == "string" or type(option and option.serverEvent) == "string"
end

local function getOptionKeys(option)
    local keys = {}

    if type(option) ~= "table" then
        return "not-a-table"
    end

    for key in pairs(option) do
        keys[#keys + 1] = tostring(key)
    end

    table.sort(keys)
    return table.concat(keys, ",")
end

local function runCallback(handler, args)
    if not canAttemptCall(handler) then
        return false, "selected option has invalid handler"
    end

    local success, result = pcall(handler, args)
    if not success then
        return false, result
    end

    return true, result
end

local function runOption(option)
    local handler = getOptionHandler(option)
    local optionLabel = option and option.label or "unknown"

    if handler ~= nil then
        local success, result = runCallback(handler, option.args)

        if success then
            return true, result
        end

        return false,
            ("selected option handler failed: %s (label=%s) keys=%s"):format(
                result,
                optionLabel,
                getOptionKeys(option)
            )
    end

    if type(option and option.event) == "string" then
        TriggerEvent(option.event, option.args)
        return true
    end

    if type(option and option.serverEvent) == "string" then
        TriggerServerEvent(option.serverEvent, option.args)
        return true
    end

    return false, ("selected option has no handler: %s keys=%s"):format(optionLabel, getOptionKeys(option))
end

function Prompt.selectCurrentOption()
    if not currentOptions or #currentOptions == 0 then
        return
    end

    local gameTimer = GetGameTimer()
    if gameTimer - lastSelectTime < 250 then
        return
    end

    lastSelectTime = gameTimer

    local visibleIndex = 0
    local firstSelectableOption

    for i, option in ipairs(currentOptions) do
        if canUseOption(option) then
            visibleIndex = visibleIndex + 1
            firstSelectableOption = firstSelectableOption or option

            if visibleIndex == currentIndex then
                local success, err = runOption(option)
                if not success then
                    print(("[lunar_bridge] Prompt interaction failed: %s"):format(err))
                    lib.notify({
                        description = ("Interaction failed: %s"):format(err),
                        type = "error",
                        position = "top-right"
                    })
                end

                return
            end
        end
    end

    if firstSelectableOption then
        local success, err = runOption(firstSelectableOption)
        if not success then
            print(("[lunar_bridge] Prompt fallback interaction failed: %s"):format(err))
            lib.notify({
                description = ("Interaction failed: %s"):format(err),
                type = "error",
                position = "top-right"
            })
        end

        return
    end

end

RegisterCommand("+lunar_interact", function()
    Prompt.selectCurrentOption()
end, false)

RegisterCommand("-lunar_interact", function() end, false)
RegisterKeyMapping("+lunar_interact", "Lunar interaction", "keyboard", "E")

RegisterCommand("lunar_interact", function()
    Prompt.selectCurrentOption()
end, false)

-- Keybind: Main interaction
lib.addKeybind({
    name = "interact_prompt",
    description = "Main interaction keybind",
    defaultMapper = "keyboard",
    defaultKey = "E",
    onReleased = function()
        Prompt.selectCurrentOption()
    end
})

CreateThread(function()
    while true do
        if currentOptions and #currentOptions > 0 then
            if IsControlJustPressed(0, 38)
                or IsDisabledControlJustPressed(0, 38)
                or IsControlJustReleased(0, 38)
                or IsDisabledControlJustReleased(0, 38)
            then
                Prompt.selectCurrentOption()
            end

            Wait(0)
        else
            Wait(250)
        end
    end
end)

-- Command: Scroll up
RegisterCommand("interact_scroll_up", function()
    if not currentOptions then
        return
    end
    
    Prompt.setIndex(currentIndex - 1)
end)

-- Command: Scroll down
RegisterCommand("interact_scroll_down", function()
    if not currentOptions then
        return
    end
    
    Prompt.setIndex(currentIndex + 1)
end)

-- Key mappings for scroll
RegisterKeyMapping("interact_scroll_up", "Interaction scroll up", "MOUSE_WHEEL", "IOM_WHEEL_UP")
RegisterKeyMapping("interact_scroll_down", "Interaction scroll down", "MOUSE_WHEEL", "IOM_WHEEL_DOWN")

--[[
    Get the Prompt object
    @return table - Prompt controller
--]]
function GetPrompt()
    return Prompt
end
