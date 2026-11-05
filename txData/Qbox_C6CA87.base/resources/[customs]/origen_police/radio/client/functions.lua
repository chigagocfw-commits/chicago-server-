local radioProp = nil

-- Add Prop to Player
function AddPropToPlayer(model, boneIndex, offsetX, offsetY, offsetZ, rotX, rotY, rotZ, textureVariation)
    local ped = PlayerPedId()
    local x, y, z = table.unpack(GetEntityCoords(ped))
    
    -- Validate model
    if not IsModelValid(model) then
        Debuger(tostring(model) .. " is not a valid model!")
        return false
    end
    
    -- Load model
    if not HasModelLoaded(model) then
        while not HasModelLoaded(model) do
            RequestModel(model)
            Wait(100)
        end
    end
    
    -- Create prop
    radioProp = CreateObject(joaat(model), x, y, z + 0.2, true, true, true)
    
    -- Set texture variation if provided
    if textureVariation ~= nil then
        SetObjectTextureVariation(radioProp, textureVariation)
    end
    
    -- Attach to player
    AttachEntityToEntity(
        radioProp,
        ped,
        GetPedBoneIndex(ped, boneIndex),
        offsetX, offsetY, offsetZ,
        rotX, rotY, rotZ,
        true, true, false, true, 1, true
    )
    
    PlayerHasProp = true
    SetModelAsNoLongerNeeded(model)
    
    return true
end

-- Start Talking on Radio
function StartTalkRadio(frequencies)
    -- Check if already talking or radio not enabled
    if Radio.Talking then
        return
    end
    
    if not Radio.Enabled then
        return
    end
    
    if Radio.MultiFrec == "none" and not frequencies then
        return
    end
    
    -- Check if handcuffed
    if exports.origen_police:IsHandcuffed() then
        return
    end
    
    -- Handle multi-frequency mode
    if frequencies then
        if Radio.MultiFrec == "none" then
            return
        end
        
        if Radio.Muted then
            return
        end
        
        Radio.Talking = {}
        
        for i = 1, #frequencies do
            frequencies[i] = ParseFrecID(frequencies[i])
            
            if Radio.MultiFrecTargets[frequencies[i]] then
                for targetId, _ in pairs(Radio.MultiFrecTargets[frequencies[i]]) do
                    Radio.Talking[targetId] = true
                end
            end
        end
    else
        -- Handle single frequency mode
        if Radio.Frec > 0 then
            if Radio.Enabled and not Radio.Muted then
                Radio.Talking = Radio.Targets
            end
        elseif Radio.MultiFrec ~= "none" then
            if not Radio.Muted then
                Radio.Talking = Radio.MultiFrecTargets[Radio.MultiFrec]
                
                for targetId, _ in pairs(Radio.Talking) do
                    Radio.Talking[targetId] = true
                end
            end
        end
    end
    
    -- Check if can talk
    if not CanTalk() then
        return
    end
    
    if Radio.Talking then
        Citizen.CreateThread(function()
            -- Set voice targets
            PlayerTargets(Radio.Talking, CurrentFrec)
            
            -- Trigger HUD event
            TriggerEvent("origen_hud:mostrarRadio")
            
            -- Notify server
            TriggerServerEvent("origen_police:server:talking", Radio.Talking, true)
            
            local ped = PlayerPedId()
            local animConfig = RadioConfig.Anims[Radio.Anim]
            
            -- Add prop if configured
            if animConfig.Prop then
                local prop = animConfig.Prop
                local bone = animConfig.PropBone
                local x, y, z, rotX, rotY, rotZ = table.unpack(animConfig.PropPlacement)
                
                if not AddPropToPlayer(prop, bone, x, y, z, rotX, rotY, rotZ) then
                    return
                end
            end
            
            -- Play animation
            TaskPlayAnim(
                ped,
                animConfig.Dict,
                animConfig.Anim,
                4.0, 8.0, -1, 49, 0,
                false, false, false
            )
            
            -- Play click sound
            if Radio.Clicks then
                SendNUIMessage({
                    startTalkSound = true
                })
            end
            
            -- Keep talking loop
            while Radio.Talking do
                Wait(0)
                
                if not CanTalk() then
                    StopTalkRadio()
                    break
                end
                
                -- Prevent certain controls
                SetControlNormal(0, 249, 1.0)
                SetControlNormal(1, 249, 1.0)
                SetControlNormal(2, 249, 1.0)
            end
        end)
    end
end

-- Stop Talking on Radio
function StopTalkRadio()
    if not Radio.Talking then
        return
    end
    
    -- Notify server
    TriggerServerEvent("origen_police:server:talking", Radio.Talking, false)
    
    Radio.Talking = false
    
    -- Clear voice targets
    MumbleClearVoiceTargetPlayers(1)
    PlayerTargets()
    
    -- Remove prop
    if DoesEntityExist(radioProp) then
        DeleteEntity(radioProp)
    end
    
    -- Stop animation
    local ped = PlayerPedId()
    local animConfig = RadioConfig.Anims[Radio.Anim]
    StopAnimTask(ped, animConfig.Dict, animConfig.Anim, 3.0)
    
    -- Hide radio UI
    TriggerEvent("origen_hud:ocultarRadio")
end

-- Get Nested Table Value
local function GetNestedValue(tbl, key)
    if not tbl then
        return nil
    end
    
    -- Check if key contains dot notation
    if not key:match("%.") then
        return tbl[key]
    end
    
    -- Parse nested key
    local mainKey, subKey = key:match("([^%.]+)%.(.+)")
    
    if type(tbl[mainKey]) == "table" then
        return tbl[mainKey][subKey] or tbl[key]
    end
    
    return tbl[key]
end

-- Load Player Settings
function LoadPlayer(playerData)
    if not playerData then
        playerData = FW_GetPlayerData(true)
    end
    
    -- Wait for player data to be ready
    while not playerData.citizenid do
        Citizen.Wait(500)
        playerData = FW_GetPlayerData(true)
    end
    
    -- Load radio animation preference
    if playerData.metadata["radio_police.anim"] then
        Radio.Anim = GetNestedValue(playerData.metadata, "radio_police.anim")
    end
    
    -- Load radio clicks preference
    if playerData.metadata["radio_police.clicks"] then
        Radio.Clicks = GetNestedValue(playerData.metadata, "radio_police.clicks")
    end
    
    -- Load radio binds
    if playerData.metadata["radio_police.binds"] then
        Radio.Binds = GetNestedValue(playerData.metadata, "radio_police.binds")
    end
    
    -- Request animation dictionary
    if RadioConfig.Anims[Radio.Anim] then
        RequestAnimDict(RadioConfig.Anims[Radio.Anim].Dict)
    end
end

-- Unload Player (Reset Radio State)
function UnLoadPlayer()
    Radio = {
        Enabled = false,
        Frec = 0,
        Anim = 1,
        Targets = {},
        Talking = false,
        MultiGroup = "none",
        MultiFrec = "none",
        MultiFrecTargets = {},
        Clicks = true,
        Binds = {},
        Muted = false
    }
    
    -- Notify server
    TriggerServerEvent("origen_police:server:SetFreq", Radio.Frec)
    TriggerServerEvent("origen_police:server:SetMultiFrec", Radio.MultiGroup, Radio.MultiFrec)
end

-- Set Player Config
function SetPlayerConfig(key, value)
    TriggerServerEvent("origen_police:SetMetaData", key, value)
end

-- Do Action
function DoAction(action)
    if action == "mute" then
        ToggleMute()
        TriggerServerEvent("origen_police:server:Mute", Radio.MultiGroup, Radio.Muted)
    end
end

-- NUI Callbacks
RegisterNUICallback("StartTalkRadio", function(data, cb)
    StartTalkRadio(data)
    cb(true)
end)

RegisterNUICallback("StopTalkRadio", function(data, cb)
    StopTalkRadio()
    cb(true)
end)