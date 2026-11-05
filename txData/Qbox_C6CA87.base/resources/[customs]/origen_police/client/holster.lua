-- Weapon Holster System
-- Variables
local isHolsterAllowed = false
local attachedWeapons = {}
local isLoaded = true
local realWeapons = Config.RealWeapons
local handgunHolsterType = "backhandgun"
local rifleHolsterType = "assault"
local currentWeaponCategory = nil
local weaponOffsets = {}
local weaponsVisible = true
local isDrawing = true
local holsterChanged = false

-- Check if holster is enabled
if not Config.Holster then
    return
end

-- Check if player's job allows holster
function IsHolsterAllowed()
    local playerData = FW_GetPlayerData(false)
    
    if not playerData or not playerData.job or not playerData.job.name then
        return false
    end
    
    for _, jobName in pairs(Config.AllowedHolster) do
        if playerData.job.name == jobName then
            isHolsterAllowed = true
            return true
        end
    end
    
    isHolsterAllowed = false
    return false
end

-- Toggle Holster Visibility (Hide/Show Weapons)
RegisterNetEvent("origen_police:holster:unarm", function()
    local ped = PlayerPedId()
    
    if weaponsVisible then
        -- Hide weapons
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        SetPedCanSwitchWeapon(ped, true)
        weaponsVisible = false
        RemoveGears()
        ClearPedTasks(ped)
        ExecuteCommand(Config.Translations.DoHide)
    else
        -- Show weapons
        weaponsVisible = true
        SetGears()
        SetPedCanSwitchWeapon(ped, true)
        ExecuteCommand(Config.Translations.DoShow)
    end
end)

-- On Job Update Event
local playerLoaded = false

RegisterNetEvent("origen_police:client:OnJobUpdate", function(jobData)
    if IsHolsterAllowed() then
        handgunHolsterType = "handguns"
    end
    
    RemoveGears()
    Wait(2000)
end)

-- On Player Loaded Event
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
    local playerData = FW_GetPlayerData(true)
    Wait(2000)
    playerLoaded = true
    
    if not playerData.metadata then
        return
    end
    
    local handgunFlag = playerData.metadata.handgunflag
    local rifleFlag = playerData.metadata.rifleflag
    
    handgunHolsterType = handgunFlag or handgunHolsterType
    rifleHolsterType = rifleFlag or rifleHolsterType
end)

-- Inventory cache for weapon checks
local inventoryCache = {}

-- Check if ped has weapon in inventory
function HasPedGotWeapon(ped, weaponHash, ignoreAmmo)
    if not playerLoaded then
        return false
    end
    
    -- Update cache if needed
    local currentTime = GetGameTimer()
    if not inventoryCache.data or (currentTime - inventoryCache.time) > 10 then
        inventoryCache = {
            time = GetGameTimer(),
            data = GetPlayerItems(nil)
        }
    end
    
    -- Check inventory for weapon
    for _, item in pairs(inventoryCache.data) do
        if GetHashKey(item.name) == weaponHash then
            return true
        end
    end
    
    return false
end

-- Main Holster Loop
Citizen.CreateThread(function()
    if not Config.Holster then return end
    
    -- Wait for player to load
    while not isLoaded do
        Citizen.Wait(500)
    end
    
    Citizen.Wait(5000)
    
    local ped = PlayerPedId()
    SetPedCanSwitchWeapon(ped, true)
    
    realWeapons = Config.RealWeapons
    weaponOffsets = Config.WeaponCategoryOffsets
    
    while true do
        Citizen.Wait(1500)
        ped = PlayerPedId()
        
        if weaponsVisible and playerLoaded then
            -- Check all weapons in config
            for i = 1, #realWeapons do
                local weaponHash = GetHashKey(realWeapons[i].name)
                local hasWeapon = HasPedGotWeapon(ped, weaponHash, false)
                
                if hasWeapon then
                    local weaponName = realWeapons[i].name
                    local isAttached = attachedWeapons[weaponName]
                    
                    if not isAttached then
                        local currentWeapon = GetSelectedPedWeapon(ped)
                        
                        -- If weapon is not currently equipped, attach it
                        if weaponHash ~= currentWeapon then
                            local weaponModel = realWeapons[i].model
                            if weaponModel then
                                SetGear(weaponName)
                            end
                        end
                    else
                        local currentWeapon = GetSelectedPedWeapon(ped)
                        
                        -- If weapon is currently equipped, remove holstered version
                        if weaponHash == currentWeapon then
                            RemoveGear(weaponName)
                        end
                    end
                else
                    -- Player doesn't have weapon, remove if attached
                    if attachedWeapons[weaponName] then
                        RemoveGear(weaponName)
                    end
                end
            end
        else
            RemoveGears()
        end
    end
end)

-- Remove specific weapon gear
function RemoveGear(weaponName)
    local newAttachments = {}
    
    for name, entity in pairs(attachedWeapons) do
        if name ~= weaponName then
            newAttachments[name] = entity
        else
            DeleteEntity(entity)
        end
    end
    
    attachedWeapons = newAttachments
end

-- Remove all weapon gears
function RemoveGears()
    for _, entity in pairs(attachedWeapons) do
        DeleteEntity(entity)
    end
    
    attachedWeapons = {}
end

-- Get holster coordinates for weapon category
function GetCoords(category)
    for i = 1, #weaponOffsets do
        if weaponOffsets[i].category == category then
            return weaponOffsets[i].bone,
                   weaponOffsets[i].x,
                   weaponOffsets[i].y,
                   weaponOffsets[i].z,
                   weaponOffsets[i].xRot,
                   weaponOffsets[i].yRot,
                   weaponOffsets[i].zRot
        end
    end
end

-- Attach weapon to holster
function SetGear(weaponName)
    local bone = nil
    local x, y, z = 0.0, 0.0, 0.0
    local xRot, yRot, zRot = 0.0, 0.0, 0.0
    local ped = PlayerPedId()
    local weaponModel = nil
    local holsterCategory = nil
    
    if not IsHolsterAllowed() then
        return
    end
    
    -- Find weapon in config
    for i = 1, #realWeapons do
        if realWeapons[i].name == weaponName then
            local category = realWeapons[i].category
            
            -- Determine holster location based on weapon type
            if category == "handguns" or category == "revolver" then
                if holsterCategory then
                    if not holsterChanged then
                        currentWeaponCategory = "handguns"
                        handgunHolsterType = "handguns"
                    end
                else
                    currentWeaponCategory = handgunHolsterType
                end
            elseif category == "machine" or category == "assault" or 
                   category == "shotgun" or category == "sniper" or 
                   category == "heavy" then
                currentWeaponCategory = rifleHolsterType
            else
                currentWeaponCategory = realWeapons[i].category
            end
            
            -- Get holster coordinates
            bone, x, y, z, xRot, yRot, zRot = GetCoords(currentWeaponCategory)
            weaponModel = realWeapons[i].model
            break
        end
    end
    
    -- Create and attach weapon prop
    local pedCoords = GetEntityCoords(ped)
    local weaponObject = CreateObject(weaponModel, pedCoords.x, pedCoords.y, pedCoords.z, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, bone)
    
    SetEntityCollision(weaponObject, false, false)
    AttachEntityToEntity(weaponObject, ped, boneIndex, x, y, z, xRot, yRot, zRot, false, false, false, false, 2, true)
    SetEntityCollision(weaponObject, false, false)
    
    attachedWeapons[weaponName] = weaponObject
end

-- Show all weapons on holster
function SetGears()
    local ped = PlayerPedId()
    
    for i = 1, #realWeapons do
        if HasPedGotWeapon(ped, GetHashKey(realWeapons[i].name), false) then
            SetGear(realWeapons[i].name)
        end
    end
end

-- Holster Command
RegisterCommand("holster", function(source, args)
    if not IsHolsterAllowed() then return end
    
    if not args[1] then
        return FW_Notify(Config.Translations.SomethingWrong)
    end
    
    -- Set holster type based on argument
    if args[1] == "handguns" or args[1] == "waisthandgun" then
        handgunHolsterType = args[1]
        FW_Notify(Config.Translations.HipHolster)
    elseif args[1] == "backhandgun" then
        handgunHolsterType = args[1]
        FW_Notify(Config.Translations.BackHolster)
    elseif args[1] == "leghandgun" or args[1] == "hiphandgun" or args[1] == "handguns2" then
        handgunHolsterType = args[1]
        FW_Notify(Config.Translations.LegHolster)
    elseif args[1] == "chesthandgun" then
        handgunHolsterType = args[1]
        FW_Notify(Config.Translations.UpperHolster)
    elseif args[1] == "boxers" then
        handgunHolsterType = args[1]
        FW_Notify(Config.Translations.UnderPantsHolster)
    elseif args[1] == "assault" then
        rifleHolsterType = args[1]
        FW_Notify(Config.Translations.LongHolsterBack)
    elseif args[1] == "tacticalrifle" then
        rifleHolsterType = args[1]
        FW_Notify(Config.Translations.LongHolsterFront)
    end
    
    -- Save preferences to server
    TriggerServerEvent("origen_police:SetMetaData", "rifleflag", rifleHolsterType)
    TriggerServerEvent("origen_police:SetMetaData", "handgunflag", handgunHolsterType)
    
    RemoveGears()
    holsterChanged = true
end)

-- Load animation dictionary
function loadAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(100)
    end
end

-- Load animation dictionary (fast)
function loadAnimDict2(dict)
    while not HasAnimDictLoaded(dict) do
        RequestAnimDict(dict)
        Citizen.Wait(0)
    end
end

-- Check if weapon is in config
function CheckWeapon(ped, weaponHash)
    if IsEntityDead(ped) then
        blocked = false
        return false
    end
    
    for i = 1, #realWeapons do
        local configWeaponHash = GetHashKey(realWeapons[i].name)
        local currentWeapon = GetSelectedPedWeapon(ped)
        
        if configWeaponHash == currentWeapon then
            return true
        end
    end
    
    return false
end

-- Weapon Draw/Holster Animation Loop
Citizen.CreateThread(function()
    if not Config.Holster then return end
    
    -- Preload animations
    loadAnimDict("rcmjosh4")
    loadAnimDict("reaction@intimidation@cop@unarmed")
    loadAnimDict("reaction@intimidation@1h")
    loadAnimDict2("combat@combat_reactions@pistol_1h_gang")
    loadAnimDict2("combat@combat_reactions@pistol_1h_hillbilly")
    loadAnimDict2("reaction@male_stand@big_variations@d")
    
    local weaponGroup = nil
    local lastWeaponHash = nil
    
    Citizen.Wait(0)
    
    while true do
        local ped = PlayerPedId()
        Citizen.Wait(50)
        
        local pedHeading = GetEntityHeading(ped)
        
        if isHolsterAllowed then
            if not IsPedInAnyVehicle(ped, true) and 
               (GetPedParachuteState(ped) == -1 or GetPedParachuteState(ped) == 0) and
               not IsPedInParachuteFreeFall(ped) then
                
                weaponGroup = GetWeapontypeGroup(GetSelectedPedWeapon(ped))
                local currentWeapon = GetSelectedPedWeapon(PlayerPedId())
                
                if CheckWeapon(ped) then
                    -- DRAWING WEAPON
                    if weaponGroup == 416676503 or weaponGroup == 690389602 then -- Handguns
                        if isDrawing then
                            -- Draw handgun based on holster type
                            if handgunHolsterType == "backhandgun" then
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                                
                            elseif handgunHolsterType == "boxers" then
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                                
                            elseif handgunHolsterType == "chesthandgun" then
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                                
                            elseif handgunHolsterType == "leghandgun" then
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                                
                            else
                                -- Default hip holster
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 0, 1, 1, 1)
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnim(ped, "rcmjosh4", "josh_leadout_cop2", 8.0, 2.0, -1, 48, 10, 0, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                            end
                        else
                            blocked = false
                        end
                        
                    else -- Long guns
                        if isDrawing then
                            if rifleHolsterType == "tacticalrifle" then
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_hillbilly", "0", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                            else
                                blocked = true
                                SetPedCurrentWeaponVisible(ped, 1, 1, 1, 1)
                                TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "intro", 
                                    GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                    8.0, 3.0, -1, 50, Config.AnimationSpeed.backhandgun.animSpeed, 0, 0)
                                Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                                ClearPedTasks(ped)
                                isDrawing = false
                                lastWeaponHash = GetSelectedPedWeapon(ped)
                            end
                        else
                            blocked = false
                        end
                    end
                    
                else
                    -- HOLSTERING WEAPON
                    lastWeaponHash = currentWeapon
                    
                    if (GetWeapontypeGroup(lastWeaponHash) == 416676503 or 
                        GetWeapontypeGroup(lastWeaponHash) == 690389602) and not isDrawing then
                        
                        -- Holster handgun
                        if handgunHolsterType == "backhandgun" then
                            TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                            
                        elseif handgunHolsterType == "boxers" then
                            TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                            
                        elseif handgunHolsterType == "leghandgun" then
                            TaskPlayAnimAdvanced(ped, "reaction@male_stand@big_variations@d", "react_big_variations_m", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                            
                        elseif handgunHolsterType == "chesthandgun" then
                            TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                            
                        else
                            TaskPlayAnimAdvanced(ped, "reaction@intimidation@cop@unarmed", "outro", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                        end
                        
                    elseif not isDrawing then
                        -- Holster rifle
                        if rifleHolsterType == "tacticalrifle" then
                            TaskPlayAnimAdvanced(ped, "combat@combat_reactions@pistol_1h_gang", "0", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                        else
                            TaskPlayAnimAdvanced(ped, "reaction@intimidation@1h", "outro", 
                                GetEntityCoords(ped, true), 0, 0, pedHeading, 
                                8.0, 3.0, -1, 50, 0.125, 0, 0)
                            Citizen.Wait(Config.AnimationSpeed.backhandgun.clearAnimWait)
                            ClearPedTasks(ped)
                            isDrawing = true
                        end
                    end
                end
                
            else
                -- In vehicle or parachuting - force unarmed
                local tryingToEnterVehicle = GetVehiclePedIsTryingToEnter(ped)
                
                if tryingToEnterVehicle == 0 then
                    isDrawing = false
                else
                    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                end
            end
        else
            isDrawing = true
        end
        
        if isDrawing then
            Citizen.Wait(500)
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveGears()
    end
end)