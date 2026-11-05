--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]

if Config.PropSpawn ~= "state" then
    return
end

local phoneObjects = {}

local function DeletePlayerPhoneEntity(source)
    if phoneObjects[source] then
        local entity = phoneObjects[source]

        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end

        phoneObjects[source] = nil

        debugprint("Deleted phone entity for source " .. source)
    end
end

local function IsPhoneOpen(source)
    local state = Player(source).state

    if not state.phoneOpen and not state.onCallWith and not state.instapicIsLive then
        return false
    end

    return true
end

local function SpawnAndAttachPhoneToPlayer(source, ped)
    if phoneObjects[source] then
        debugprint("Phone entity already exists for source " .. source)
        return
    end

    local showPhoneTimer = GetGameTimer() + 500
    local state = Player(source).state
    local phoneVariation = state.lbPhoneVariation
    local itemData = phoneVariation and Config.Item.Names[phoneVariation]
    local phoneModel = itemData and itemData.model or Config.PhoneModel or `prop_amb_phone`
    local coords = GetEntityCoords(ped)

    LoadModel(phoneModel)

    while showPhoneTimer > GetGameTimer() do
        Wait(0)
    end

    if not IsPhoneOpen(source) then
        debugprint("Player closed phone before it was spawned")
        SetModelAsNoLongerNeeded(phoneModel)
        return
    end

    local phone = CreateObject(phoneModel, coords.x, coords.y, coords.z, false, true, true)

    SetEntityCollision(phone, false, false)
    SetModelAsNoLongerNeeded(phoneModel)
    AttachPhone({
        phone = phone,
        ped = ped,
        variation = phoneVariation,
        landscape = state.phoneLandscape
    })

    if itemData and itemData.textureVariation then
        SetObjectTextureVariation(phone, itemData.textureVariation)
    end

    phoneObjects[source] = phone

    debugprint("Created phone entity for source " .. source)
end

local function HandleStateBagChange(bagName, key, value, reserved, replicated)
    local source, ped = GetPlayerDataFromStateBag(bagName)

    if not source or source == GetPlayerServerId(PlayerId()) then
        return
    end

    if not ped then
        debugprint("Ped not found")
        return
    end

    if value then
        SpawnAndAttachPhoneToPlayer(source, ped)
    else
        Wait(0) 

        if not IsPhoneOpen(source) then
            DeletePlayerPhoneEntity(source)
        end
    end
end

AddStateBagChangeHandler("phoneOpen", nil, HandleStateBagChange)

AddStateBagChangeHandler("onCallWith", nil, HandleStateBagChange)

AddStateBagChangeHandler("instapicIsLive", nil, HandleStateBagChange)

AddStateBagChangeHandler("phoneLandscape", nil, function(bagName, key, value, reserved, replicated)
    local source, ped = GetPlayerDataFromStateBag(bagName)

    if not source or source == GetPlayerServerId(PlayerId()) then
        return
    end

    if not ped then
        debugprint("Ped not found")
        return
    end

    local phone = phoneObjects[source]

    if not phone or not DoesEntityExist(phone) then
        debugprint("Phone entity not found for source " .. source .. ", not changing landscape attachment")
        return
    end

    AttachPhone({
        phone = phone,
        ped = ped,
        landscape = value,
        variation = Player(source).state.lbPhoneVariation
    })
end)

RegisterNetEvent("onPlayerDropped", function(src)
    DeletePlayerPhoneEntity(src)
end)

