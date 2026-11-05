-- Police evidence system - Server side

local evidencesNeedUpdate = false
local fingerprints = {}  -- Fingerprints by weapon serial
local weaponShots = {}   -- Weapon shot tracking by serial
local evidences = {}     -- All placed evidences
local lastEvidenceCache = {}  -- Cached evidence list
local lastQueryPosition = vector3(0, 0, 0)  -- Last query position for cache

-- Server event: Add new evidence
RegisterServerEvent("origen_police:server:AddNewEvidence", function(evidenceData)
    local player = FW_GetPlayer(source)
    
    if player then
        -- Handle single evidence or array
        if #evidenceData == 0 then
            AddNewEvidence(evidenceData, player)
        else
            for i = 1, #evidenceData do
                AddNewEvidence(evidenceData[i], player)
            end
        end
    end
end)

-- Add new evidence to the world
function AddNewEvidence(evidence, player)
    if not player or not player.PlayerData then
        return
    end
    
    evidence.time = os.time()
    
    -- Handle DNA/ADN evidence
    if evidence.adn then
        if evidence.adn == true then
            -- Use player's actual name
            evidence.adn = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
        elseif evidence.adn == "Generate" then
            -- Generate random name
            local gender = (math.random(1, 2) == 1) and "male" or "female"
            evidence.adn = GetRandomName(gender)
        end
    end
    
    -- Handle weapon evidence
    if evidence.wp then
        local weaponItem = GetItemFromSlot(player.PlayerData, evidence.wp)
        local metadata = GetItemMetadata(weaponItem)
        local serial = metadata.serie or metadata.serial or "UNKNOW"
        
        -- Track weapon shots
        if evidence.type == "Shoot" then
            weaponShots[serial] = {
                adn = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
                time = os.time()
            }
        end
        
        -- Determine ammo type
        local ammoType = "Sin Clasificar"
        local weaponName = weaponItem.name:lower()
        
        if Config.AmmoTypes[weaponName] then
            local ammoCategory = Config.AmmoTypes[weaponName]
            ammoType = Config.Ammos[ammoCategory] or "Sin Clasificar"
        end
        
        evidence.ammo = ammoType
        
        -- Set weapon serial if metadata exists
        if weaponItem and GetItemMetadata(weaponItem) then
            evidence.fkserie = serial
        end
        
        evidence.wp = nil
    end
    
    -- Handle fingerprint evidence
    if evidence.type == "FinguerPrint" then
        local serial = evidence.fkserie
        fingerprints[serial] = {
            adn = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname,
            time = os.time(),
            fkserie = evidence.fkserie,
            model = evidence.model,
            type = "FinguerPrint"
        }
    else
        -- Add to evidence list
        table.insert(evidences, evidence)
        evidencesNeedUpdate = true
    end
end

-- Server event: Remove evidence
RegisterServerEvent("origen_police:server:RemoveEvidence", function(evidenceIndex)
    if evidences[evidenceIndex] then
        TriggerClientEvent("origen_police:client:rmevidence", -1, evidenceIndex)
        evidences[evidenceIndex] = nil
    end
end)

-- Callback: Get nearby evidences
FW_CreateCallback("origen_police:callback:GetEvidences", function(source, cb, playerCoords)
    local distance = #(lastQueryPosition - playerCoords)
    
    -- Return cached data if player hasn't moved much
    if distance < 50 and not evidencesNeedUpdate then
        cb(lastEvidenceCache)
        return
    end
    
    -- Build list of nearby evidences
    local nearbyEvidences = {}
    
    for i = 1, #evidences do
        if evidences[i] and evidences[i].coords then
            local evidenceDistance = #(evidences[i].coords - playerCoords)
            
            if evidenceDistance < 300 then
                table.insert(nearbyEvidences, evidences[i])
            end
        end
    end
    
    lastEvidenceCache = nearbyEvidences
    lastQueryPosition = playerCoords
    evidencesNeedUpdate = false
    
    cb(nearbyEvidences)
end)

-- Useable item: Instant camera
FW_CreateUseableItem("instant_camera", function(source)
    local player = FW_GetPlayer(source)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.CantUseItem or "You cannot use this item")
        return
    end
    
    -- Check if player can use police equipment
    local result = CanOpenTablet(player.PlayerData.job.name)
    local canUse = result[1]
    local jobCategory = result[2]
    
    -- Camera is police-only equipment
    if not canUse or jobCategory ~= Config.PoliceJobCategory then
        TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.CantUseItem or "You cannot use police camera")
        return
    end
    
    -- Set on-duty status for ESX
    if Config.Framework == "esx" then
        player.PlayerData.job.onduty = IsPlayerOnDuty(source)
    end
    
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local webhookUrl = ServerConfig.Logs.Camera
    
    -- Validate webhook URL
    if not isValidURL(webhookUrl) then
        TriggerClientEvent("origen_police:ShowNotification", source, "The camera logs are not configured correctly")
        return Debuger("^2PLEASE READ!!^1You need to set your discord webhook in config/logs/logs.lua^0We don't give support for this error, just set the webhook and the error will be fixed^0")
    end
    
    local timestamp = os.date("%H:%M - %d/%m/%Y")
    
    -- Police on-duty can use camera
    if player.PlayerData.job.onduty then
        local distance = #(lastQueryPosition - playerCoords)
        
        -- Return cached evidences if nearby
        if distance < 50 and not evidencesNeedUpdate then
            TriggerClientEvent("origen_police:client:usecamera", source, lastEvidenceCache, timestamp, webhookUrl)
            return
        end
        
        -- Build nearby evidences list
        local nearbyEvidences = {}
        
        for i = 1, #evidences do
            if evidences[i] and evidences[i].coords then
                local evidenceDistance = #(evidences[i].coords - playerCoords)
                
                if evidenceDistance < 300 then
                    table.insert(nearbyEvidences, evidences[i])
                end
            end
        end
        
        lastEvidenceCache = nearbyEvidences
        lastQueryPosition = playerCoords
        evidencesNeedUpdate = false
        
        TriggerClientEvent("origen_police:client:usecamera", source, nearbyEvidences, timestamp, webhookUrl)
    else
        -- Non-police can use camera from origen_ilegal if available
        if GetResourceState("origen_ilegal") == "started" then
            return exports.origen_ilegal:OpenCamera(source)
        end
        
        TriggerClientEvent("origen_police:client:usecamera", source, false, false, webhookUrl)
    end
end)

-- Useable item: Photo
FW_CreateUseableItem("photo", function(source, itemData, slot)
    Debuger("Photo item data: " .. json.encode(itemData) .. json.encode(slot))
    
    local metadata = GetItemMetadata(slot or itemData)
    TriggerClientEvent("origen_police:client:showphoto", source, metadata.url)
end)

-- Useable item: Evidence report
FW_CreateUseableItem("report_evidence", function(source, itemData, slot)
    Debuger("Report item data: " .. json.encode(itemData) .. json.encode(slot))
    
    local metadata = GetItemMetadata(slot or itemData)
    TriggerClientEvent("origen_police:client:showphoto", source, metadata.url)
end)

-- Server event: Save photo
RegisterServerEvent("origen_police:server:savephoto", function(photoUrl)
    local src = source
    local player = FW_GetPlayer(src)
    
    if not player then
        return
    end
    
    local success = player.Functions.AddItem("photo", 1, false, {
        url = photoUrl,
        serie = player.PlayerData.citizenid .. os.time()
    })
    
    if not success then
        TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.NoPhotoSpace)
    else
        CreateLog({
            type = "Camera",
            embed = {
                title = Config.LogsTranslations.NewPhoto.title,
                description = Config.LogsTranslations.NewPhoto.message,
                color = 1791423,
                image = {url = photoUrl}
            },
            source = src
        })
    end
end)

-- Server event: Save evidence report
RegisterServerEvent("origen_police:server:savereportevidence", function(reportUrl)
    local player = FW_GetPlayer(source)
    
    if not player then
        return
    end
    
    local success = player.Functions.AddItem("report_evidence", 1, false, {
        url = reportUrl,
        serie = player.PlayerData.citizenid .. os.time()
    })
    
    if not success then
        TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.NoSpaceInInv)
    end
end)

-- Server event: Collect evidence
RegisterServerEvent("origen_police:server:GetEvidence", function(evidenceIndex, evidenceData)
    local src = source
    local player = FW_GetPlayer(src)
    
    if not player or not player.PlayerData or not player.PlayerData.job then
        TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.CantUseItem or "You cannot collect evidence")
        return
    end
    
    -- Check if player can collect evidence (must be police)
    local result = CanOpenTablet(player.PlayerData.job.name)
    local canUse = result[1]
    local jobCategory = result[2]
    
    -- Evidence collection is police-only
    if not canUse or jobCategory ~= Config.PoliceJobCategory then
        TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.CantUseItem or "You cannot collect evidence")
        return
    end
    
    evidenceData.coords = nil
    
    -- Handle standard evidence types
    if Config.Evidences[evidenceData.type] then
        local success = player.Functions.AddItem(
            Config.Evidences[evidenceData.type].item,
            1,
            false,
            evidenceData
        )
        
        if success then
            TriggerClientEvent("origen_police:client:rmevidence", -1, evidenceIndex)
            
            if evidences[evidenceIndex] then
                evidences[evidenceIndex] = nil
            end
        else
            TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.NoSpaceInInv)
        end
    -- Handle fingerprint evidence
    elseif evidenceData.type == "FinguerPrint" then
        local fingerprintData = fingerprints[evidenceData.fkserie]
        
        if fingerprintData then
            local success = player.Functions.AddItem("evidence_ne", 1, false, fingerprintData)
            
            if success then
                TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.ObtainedFingerpritns)
            else
                TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.NoSpaceInInv)
            end
        else
            TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.NoFingerFound)
        end
    else
        TriggerClientEvent("origen_police:ShowNotification", src, Config.Translations.EvidenceNotCategorized)
    end
end)

-- Server event: Remove all evidence items from player
RegisterServerEvent("origen_police:client:removeevidences", function()
    if Config.Debug then
        return Debuger("Ignoring evidence removal due to debug mode")
    end
    
    local player = FW_GetPlayer(source)
    
    if not player then
        return
    end
    
    local removedCount = 0
    
    for _, item in pairs(player.PlayerData.items) do
        if string.find(item.name, "^evidence_") then
            player.Functions.RemoveItem(item.name, item.count or item.amount, item.slot)
            removedCount = removedCount + 1
            
            if removedCount == 4 then
                break
            end
        end
    end
end)

-- Export: Get fingerprint by weapon serial
exports("GetFingerPrint", function(serial)
    return fingerprints[serial]
end)

-- Export: Get weapon shot data
exports("GetShootedWp", function(serial)
    if weaponShots[serial] then
        local timeSinceShot = os.time() - weaponShots[serial].time
        
        if timeSinceShot < Config.SecondsToCool then
            return timeSinceShot
        else
            weaponShots[serial] = false
            return false
        end
    end
    
    return false
end)