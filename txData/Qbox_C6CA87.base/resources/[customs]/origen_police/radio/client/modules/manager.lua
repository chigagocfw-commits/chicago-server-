CurrentFrec = nil

-- Toggle Radio On/Off
function Toggle(status)
    if status ~= nil then
        Radio.Enabled = status
    else
        Radio.Enabled = not Radio.Enabled
    end
    
    if not Radio.Enabled then
        TriggerEvent("origen_police:client:CloseRadioTab")
    end
    
    SendNUIMessage({
        action = "status",
        status = Radio.Enabled
    })
end

-- Set Radio Frequency
function SetFreq(frequency)
    Radio.Frec = frequency or 0
    
    TriggerServerEvent("origen_police:server:SetFreq", Radio.Frec)
    
    SendNUIMessage({
        action = "set_freq",
        new_freq = Radio.Frec
    })
end

-- Set Voice Targets
function SetTargets(targets)
    Radio.Targets = targets or {}
end

-- Add Player to Voice Targets
function AddPlayerTarget(playerId)
    Radio.Targets[playerId] = true
end

-- Remove Player from Voice Targets
function RemovePlayerTarget(playerId)
    Radio.Targets[playerId] = nil
end

-- Set Multi-Frequency
function SetMultiFrec(group, frequency)
    if not group then
        group = Config.PoliceJobName
    end
    
    Radio.MultiGroup = group or "none"
    Radio.MultiFrec = frequency or "none"
    CurrentFrec = frequency
    
    local playerData = FW_GetPlayerData(true)
    local divisionIcons = {}
    
    if playerData and playerData.metadata and playerData.metadata.divisions then
        for divisionId, _ in pairs(playerData.metadata.divisions) do
            local icon = nil
            
            if Translations.DivisionsData[divisionId] and Translations.DivisionsData[divisionId].icon then
                icon = Translations.DivisionsData[divisionId].icon
            end
            
            table.insert(divisionIcons, icon)
        end
    end
    
    TriggerServerEvent("origen_police:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec, {
        divisions = divisionIcons
    })
end

-- Set Multi-Frequency Targets
function SetMultiFrecTargets(targets)
    Radio.MultiFrecTargets = targets or {}
end

-- Add Player to Multi-Frequency
function AddPlayerMultiFrec(playerId, frequency, enabled)
    -- Remove player from all frequencies first
    for freq, players in pairs(Radio.MultiFrecTargets) do
        if players[playerId] then
            players[playerId] = nil
            break
        end
    end
    
    -- Create frequency table if doesn't exist
    if not Radio.MultiFrecTargets[frequency] then
        Radio.MultiFrecTargets[frequency] = {}
    end
    
    -- Add player to new frequency
    Radio.MultiFrecTargets[frequency][playerId] = enabled or true
end

-- Remove Player from Multi-Frequency
function RemovePlayerMultiFrec(playerId, frequency)
    if frequency then
        if Radio.MultiFrecTargets[frequency] then
            Radio.MultiFrecTargets[frequency][playerId] = nil
        end
    else
        -- Remove from all frequencies
        for freq, players in pairs(Radio.MultiFrecTargets) do
            if players[playerId] then
                players[playerId] = nil
                break
            end
        end
    end
end

-- Move Player Between Multi-Frequencies
function MovePlayerMultiFrec(playerId, oldFreq, newFreq)
    playerId = tonumber(playerId)
    
    RemovePlayerMultiFrec(playerId)
    AddPlayerMultiFrec(playerId, newFreq)
    
    TriggerServerEvent("origen_police:server:moveplayer", playerId, oldFreq, newFreq)
end

-- Toggle Mute
function ToggleMute(status)
    if status ~= nil then
        Radio.Muted = status
    else
        Radio.Muted = not Radio.Muted
    end
end

-- Set Player Muted Status
function SetMuted(playerId, muted)
    for freq, players in pairs(Radio.MultiFrecTargets) do
        if players[playerId] then
            players[playerId].muted = muted
            break
        end
    end
end

-- Set Radio Animation
function SetAnim(animId)
    Radio.Anim = animId or 1
    
    RequestAnimDict(RadioConfig.Anims[Radio.Anim].Dict)
    SetPlayerConfig("radio_police.anim", Radio.Anim)
end

-- Change Radio Animation Command
local currentAnimIndex = 1

RegisterCommand(Config.Commands.ChangeRadioAnim.cmd, function()
    currentAnimIndex = currentAnimIndex + 1
    
    if currentAnimIndex > GetTableLength(RadioConfig.Anims) then
        currentAnimIndex = 1
    end
    
    SetAnim(currentAnimIndex)
end)

-- NUI Callback for Setting Animation
RegisterNUICallback("SetRadioAnim", function(data, cb)
    if not RadioConfig.Anims[data.anim] then
        print("INVALID RADIO ANIM, CHECK THE AMOUNT OF ANIMS IN RADIO CONFIG")
        return
    end
    
    SetAnim(data.anim)
    cb(true)
end)

-- Toggle Radio Clicks
function ToggleClicks(enabled)
    Radio.Clicks = enabled
    SetPlayerConfig("radio_police.clicks", Radio.Clicks)
end

-- Add Radio Keybind
function RadioAddKeyBind(inputType, key, action)
    RegisterKeyMapping("+r_police_keybind " .. key, "", inputType, key)
    
    -- Remove existing bind with same action
    for bindKey, bindAction in pairs(Radio.Binds) do
        if action == bindAction then
            Radio.Binds[bindKey] = nil
            break
        end
    end
    
    Radio.Binds[key] = action
    SetPlayerConfig("radio_police.binds", Radio.Binds)
end

-- Remove Radio Keybind
function RadioRemoveKeyBind(key)
    Radio.Binds[key] = nil
    SetPlayerConfig("radio_police.binds", Radio.Binds)
end

-- ========================================
-- Network Events Registration
-- ========================================

RegisterNetEvent("origen_police:client:Toggle", Toggle)
RegisterNetEvent("origen_police:client:SetFreq", SetFreq)
RegisterNetEvent("origen_police:client:SetTargets", SetTargets)
RegisterNetEvent("origen_police:client:AddPlayerTarget", AddPlayerTarget)
RegisterNetEvent("origen_police:client:RemovePlayerTarget", RemovePlayerTarget)
RegisterNetEvent("origen_police:client:SetMultiFrec", SetMultiFrec)
RegisterNetEvent("origen_police:client:SetMultiFrecTargets", SetMultiFrecTargets)
RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", AddPlayerMultiFrec)
RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", RemovePlayerMultiFrec)
RegisterNetEvent("origen_police:client:MovePlayerMultiFrec", MovePlayerMultiFrec)
RegisterNetEvent("origen_police:client:SetMuted", SetMuted)
RegisterNetEvent("origen_police:client:SetAnim", SetAnim)
RegisterNetEvent("origen_police:client:ToggleClicks", ToggleClicks)
RegisterNetEvent("origen_police:client:RadioAddKeyBind", RadioAddKeyBind)
RegisterNetEvent("origen_police:client:RadioRemoveKeyBind", RadioRemoveKeyBind)

-- ========================================
-- Exports Registration
-- ========================================

exports("Toggle", Toggle)
exports("SetFreq", SetFreq)
exports("SetTargets", SetTargets)
exports("AddPlayerTarget", AddPlayerTarget)
exports("RemovePlayerTarget", RemovePlayerTarget)
exports("SetMultiFrec", SetMultiFrec)
exports("SetMultiFrecTargets", SetMultiFrecTargets)
exports("AddPlayerMultiFrec", AddPlayerMultiFrec)
exports("RemovePlayerMultiFrec", RemovePlayerMultiFrec)
exports("MovePlayerMultiFrec", MovePlayerMultiFrec)
exports("SetMuted", SetMuted)
exports("SetAnim", SetAnim)
exports("ToggleClicks", ToggleClicks)
exports("RadioAddKeyBind", RadioAddKeyBind)
exports("RadioRemoveKeyBind", RadioRemoveKeyBind)

exports("GetCurrentFrequencyName", function()
    return CurrentFrec or "none"
end)

exports("GetMultiFrec", function()
    return Radio.MultiFrec
end)

-- ========================================
-- NUI Callbacks
-- ========================================

RegisterNUICallback("Toggle", function(data, cb)
    Toggle(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetFreq", function(data, cb)
    SetFreq(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetTargets", function(data, cb)
    SetTargets(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("AddPlayerTarget", function(data, cb)
    AddPlayerTarget(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemovePlayerTarget", function(data, cb)
    RemovePlayerTarget(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetMultiFrec", function(data, cb)
    SetMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetMultiFrecTargets", function(data, cb)
    SetMultiFrecTargets(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("AddPlayerMultiFrec", function(data, cb)
    AddPlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RemovePlayerMultiFrec", function(data, cb)
    RemovePlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("MovePlayerMultiFrec", function(data, cb)
    MovePlayerMultiFrec(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetMuted", function(data, cb)
    SetMuted(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("SetAnim", function(data, cb)
    SetAnim(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("ToggleClicks", function(data, cb)
    ToggleClicks(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RadioAddKeyBind", function(data, cb)
    RadioAddKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("RadioRemoveKeyBind", function(data, cb)
    RadioRemoveKeyBind(table.unpack(data))
    cb(true)
end)

RegisterNUICallback("GetBinds", function(data, cb)
    cb(Radio.Binds)
end)