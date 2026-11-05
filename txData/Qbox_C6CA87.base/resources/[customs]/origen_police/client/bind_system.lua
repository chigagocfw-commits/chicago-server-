-- Custom Police Keybind System
local keybinds = {}

-- Load keybinds when player loads
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    local playerData = FW_GetPlayerData(true)
    
    while not playerData.citizenid do
        Citizen.Wait(1000)
        playerData = FW_GetPlayerData(true)
    end
    
    keybinds = playerData.metadata.custom_police_keybind or {}
    LoadBinds()
end)

-- Load keybinds on startup
Citizen.CreateThread(function()
    local playerData = FW_GetPlayerData(true)
    
    if playerData and playerData.citizenid then
        keybinds = playerData.metadata.custom_police_keybind or {}
        LoadBinds()
    end
end)

-- Load all keybinds
function LoadBinds()
    for key, event in pairs(keybinds) do
        AddKeyBind(key, event)
    end
end

-- Execute custom keybind command
RegisterCommand("custom_police_keybind", function(source, args)
    local key = args[1]
    
    if key and keybinds[key] then
        TriggerEvent(keybinds[key])
    end
end)

-- Add a keybind
function AddKeyBind(key, event)
    RegisterKeyMapping(
        "custom_police_keybind " .. key,
        "custom_police_keybind " .. key,
        "keyboard",
        key
    )
    
    if type(keybinds) ~= "table" then
        return
    end
    
    -- Remove existing bind for this event
    for existingKey, existingEvent in pairs(keybinds) do
        if existingEvent == event then
            keybinds[existingKey] = nil
            break
        end
    end
    
    keybinds[key] = event
    SetPlayerConfig("custom_police_keybind", keybinds)
end

-- Remove a keybind
function RemoveKeyBind(key)
    keybinds[key] = nil
    SetPlayerConfig("custom_police_keybind", keybinds)
end

-- Get all keybinds
function GetKeyBinds()
    return keybinds
end

-- Set default bind (only if not already bound)
function SetDefaultBind(key, event)
    if type(keybinds) ~= "table" then
        return
    end
    
    -- Check if event is already bound
    for _, existingEvent in pairs(keybinds) do
        if existingEvent == event then
            return
        end
    end
    
    AddKeyBind(key, event)
end

-- Export functions
exports("AddKeyBind", AddKeyBind)
exports("SetDefaultBind", SetDefaultBind)
exports("RemoveKeyBind", RemoveKeyBind)
exports("GetKeyBinds", GetKeyBinds)

-- Network events
RegisterNetEvent("AddKeyBind", AddKeyBind)
RegisterNetEvent("SetDefaultBind", SetDefaultBind)
RegisterNetEvent("RemoveKeyBind", RemoveKeyBind)
RegisterNetEvent("GetKeyBinds", function(callback)
    callback(GetKeyBinds())
end)

-- NUI Callbacks
RegisterNUICallback("AddKeyBind", function(data, cb)
    AddKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetDefaultBind", function(data, cb)
    SetDefaultBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemoveKeyBind", function(data, cb)
    RemoveKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("GetKeyBinds", function(data, cb)
    cb(GetKeyBinds())
end)