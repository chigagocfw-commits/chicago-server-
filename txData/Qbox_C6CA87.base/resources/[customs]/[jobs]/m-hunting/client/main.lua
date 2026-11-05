Blips = {}
ContractData = {}
Polyzone = false
CreatedPedData = {}
SelectedData = {}
RequiredKillForContract = {}
Huntid = nil
vehicle = nil
Framework = nil
createdpeds = false

Citizen.CreateThread(function()
    local frameworkObject = GetFrameworkObject()
    Framework = frameworkObject
end)

RegisterNuiCallback("close", function(callbackData, callbackReturn)
    SetNuiFocus(false, false)
end)

RegisterNetEvent("m-hunting:exitfromlobby")
AddEventHandler("m-hunting:exitfromlobby", function(eventData)
    local messageData = {}
    messageData.action = "clearlobby"
    SendNUIMessage(messageData)
end)

RegisterNetEvent("m-hunting-cl:OpenNui")
AddEventHandler("m-hunting-cl:OpenNui", function(playerDataParam, leaderboardParam, lobbyListParam, totalPlayersParam)
    local translationData = Config.Translate
    local joinCoopText = translationData.joincoopdesc:format(totalPlayersParam)
    
    SetNuiFocus(true, true)
    
    local nuiMessage = {}
    nuiMessage.action = "open"
    nuiMessage.PlayerData = playerDataParam
    nuiMessage.itemprices = Config.ItemPrices
    nuiMessage.translate = translationData
    nuiMessage.desc = joinCoopText
    nuiMessage.wiki = Config.Wiki
    nuiMessage.categories = Config.Categories
    nuiMessage.contracts = Config.Contracts
    nuiMessage.leaderboard = leaderboardParam
    nuiMessage.lobbylist = lobbyListParam
    nuiMessage.serverimage = Config.ServerImage
    nuiMessage.TotalPlayers = totalPlayersParam
    
    SendNUIMessage(nuiMessage)
end)

RegisterNetEvent("m-hunting-client:syncLobbyList")
AddEventHandler("m-hunting-client:syncLobbyList", function(updatedLobbyList)
    local syncMessage = {}
    syncMessage.action = "updateLobbyList"
    syncMessage.lobbylist = updatedLobbyList
    SendNUIMessage(syncMessage)
end)

RegisterNuiCallback("createlobby", function(lobbyCreationData, returnCallback)
    local huntData = lobbyCreationData.data
    TriggerServerEvent("m-hunting-server:CreateLobby", huntData)
end)

RegisterNuiCallback("clearlobby", function(clearLobbyData, returnCallback)
    local lobbyIdString = clearLobbyData.id
    local lobbyIdNumber = tonumber(lobbyIdString)
    TriggerServerEvent("m-hunting-server:clearlobby", lobbyIdNumber)
end)

RegisterNuiCallback("huntwithfellas", function(joinFellasData, returnCallback)
    local targetLobbyId = joinFellasData.id
    local numericLobbyId = tonumber(targetLobbyId)
    SetNuiFocus(false, false)
    TriggerServerEvent("m-hunting-server:HuntWithFellas", numericLobbyId)
end)

RegisterNuiCallback("leavelobby", function(leaveData, returnCallback)
    local leavingLobbyId = leaveData.id
    local numericId = tonumber(leavingLobbyId)
    TriggerServerEvent("m-hunting-server:leavelobby", numericId)
end)

RegisterNuiCallback("joinlobby", function(joinData, returnCallback)
    local joinTargetId = joinData.id
    local numericJoinId = tonumber(joinTargetId)
    TriggerServerEvent("m-hunting-server:joinlobby", numericJoinId)
end)

RegisterNuiCallback("sellitems", function(sellData, returnCallback)
    local itemsToSell = sellData.items
    SetNuiFocus(false, false)
    TriggerServerEvent("m-hunting-server:SellItems", itemsToSell)
end)

RegisterNuiCallback("huntalone", function(soloData, returnCallback)
    local huntConfiguration = soloData.data
    TriggerServerEvent("m-hunting-server:Hunt", huntConfiguration)
    SetNuiFocus(false, false)
end)

RegisterNetEvent("m-hunting:Client-FinishJob")
AddEventHandler("m-hunting:Client-FinishJob", function()
    clearCache()
end)

RegisterNetEvent("m-hunting-client:StartHunt")
AddEventHandler("m-hunting-client:StartHunt", function(huntConfiguration, contractConfiguration, huntIdentifier, hasVehicleFlag, hasGearFlag)
    local closeMessage = {}
    closeMessage.action = "closenui"
    SendNUIMessage(closeMessage)
    
    SetNuiFocus(false, false)
    
    local targetX = huntConfiguration.locationcoord.x
    local targetY = huntConfiguration.locationcoord.y
    SetNewWaypoint(targetX, targetY)
    
    local zoneCenter = huntConfiguration.locationcoord
    local createdZone = CircleZone:Create(zoneCenter, 200.0, {
        name = "circle_zone",
        debugPoly = false
    })
    Polyzone = createdZone
    
    Huntid = huntIdentifier
    
    SelectedData.type = huntConfiguration.type
    SelectedData.id = huntConfiguration.index
    
    CreateBlip(huntConfiguration.locationcoord)
    
    local hasContractData = next(contractConfiguration)
    if hasContractData then
        ContractData = contractConfiguration
        local contractHashTable = ContractData.hash
        for animalKey, killCount in pairs(contractHashTable) do
            RequiredKillForContract[animalKey] = 0
        end
    end
    
    local function onPlayerEnterZone(isInsideZone)
        if isInsideZone then
            if not createdpeds then
                createdpeds = true
                local randomCoords = GetRandomCoordInCircle(huntConfiguration.locationcoord)
                Citizen.Wait(0)
                SpawnAnimals(randomCoords, huntConfiguration.hash, huntConfiguration.locationcoord)
            end
        end
    end
    
    Polyzone:onPlayerInOut(onPlayerEnterZone)
end)

Citizen.CreateThread(function()
    while true do
        local waitTime = 1000
        local playerPed = PlayerPedId()
        
        if Huntid then
            local weaponCheck = IsPedArmed(playerPed, 7)
            local hasHuntingWeapon = false
            
            if weaponCheck then
                local selectedWeapon = GetSelectedPedWeapon(playerPed)
                local huntingRifleHash = GetHashKey(Config.WeaponHash)
                if selectedWeapon == huntingRifleHash then
                    hasHuntingWeapon = true
                end
            end
            
            if Config.DisableAttackToPlayer == "all" then
                if hasHuntingWeapon then
                    waitTime = 30
                    NetworkSetFriendlyFireOption(false)
                    SetCanAttackFriendly(playerPed, false, false)
                    if Config.UseEntityAlphaSystem then
                        SetEntityAlpha(playerPed, 255, false)
                    end
                else
                    NetworkSetFriendlyFireOption(true)
                    SetCanAttackFriendly(playerPed, true, true)
                    if Config.UseEntityAlphaSystem then
                        SetEntityAlpha(playerPed, 255, false)
                    end
                end
            elseif Config.DisableAttackToPlayer == "job" then
                if hasHuntingWeapon then
                    NetworkSetFriendlyFireOption(false)
                    SetCanAttackFriendly(playerPed, false, false)
                    if Config.UseEntityAlphaSystem then
                        SetEntityAlpha(playerPed, 255, false)
                    end
                else
                    NetworkSetFriendlyFireOption(true)
                    SetCanAttackFriendly(playerPed, true, true)
                    if Config.UseEntityAlphaSystem then
                        SetEntityAlpha(playerPed, 255, false)
                    end
                end
            end
        end
        
        Citizen.Wait(waitTime)
    end
end)

RegisterNetEvent("m-hunting:setplayerstocar")
AddEventHandler("m-hunting:setplayerstocar", function(targetVehicleNetId)
    local targetVehicle = NetworkGetEntityFromNetworkId(targetVehicleNetId)
    local seatIndices = {-1, 0, 1, 2, 3, 4, 5, 6}
    
    for index, seatIndex in ipairs(seatIndices) do
        local isSeatFree = IsVehicleSeatFree(targetVehicle, seatIndex)
        if isSeatFree then
            local playerPed = PlayerPedId()
            TaskWarpPedIntoVehicle(playerPed, targetVehicle, seatIndex)
            break
        end
    end
end)

RegisterNetEvent("m-hunting:clientClaimItems")
AddEventHandler("m-hunting:clientClaimItems", function(targetAnimalPed)
    local hasCreatedPeds = next(CreatedPedData)
    if hasCreatedPeds then
        for dataIndex, animalData in pairs(CreatedPedData) do
            local storedPed = animalData.ped
            if storedPed == targetAnimalPed then
                animalData.takeitems = true
                CreatedPedData[dataIndex] = nil
                DeleteEntity(targetAnimalPed)
                break
            end
        end
    end
end)

function GetRandomCoordInCircle(centerCoordinate)
    local spawnCoordinates = {}
    local maxSpawnRadius = 200.0
    local spawnCount = Config.PedSpawnCount
    
    for i = 1, spawnCount do
        local randomX = centerCoordinate.x + math.random(-maxSpawnRadius, maxSpawnRadius)
        local randomY = centerCoordinate.y + math.random(-maxSpawnRadius, maxSpawnRadius)
        local groundZ = FindZForCoords(randomX, randomY)
        local spawnVector = vector3(randomX, randomY, groundZ)
        table.insert(spawnCoordinates, spawnVector)
    end
    
    return spawnCoordinates
end

function FindZForCoords(xCoord, yCoord)
    local groundFound = true
    local maxHeight = 1500.0
    local currentHeight = maxHeight
    
    while groundFound and currentHeight > 0 do
        local foundGround, groundZValue = GetGroundZAndNormalFor_3dCoord(xCoord + 0.0, yCoord + 0.0, currentHeight - 1.0)
        if foundGround then
            currentHeight = groundZValue + 0.0
        end
        groundFound = foundGround
        Wait(0)
    end
    
    local finalZ = currentHeight + 0.0
    return finalZ
end

Citizen.CreateThread(function()
    local hunterBlip = AddBlipForCoord(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z)
    
    local hunterSprite = Config.HuntingBlip.sprite
    local hunterColor = Config.HuntingBlip.color
    local hunterScale = Config.HuntingBlip.scale
    local hunterName = Config.HuntingBlip.name
    
    SetBlipSprite(hunterBlip, hunterSprite)
    SetBlipColour(hunterBlip, hunterColor)
    SetBlipScale(hunterBlip, hunterScale)
    SetBlipAsShortRange(hunterBlip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(hunterName)
    EndTextCommandSetBlipName(hunterBlip)
end)

function CreateBlip(targetCoordinates)
    local jobBlip = AddBlipForCoord(targetCoordinates)
    local jobSprite = Config.Blip.sprite
    local jobColor = Config.Blip.color
    local jobScale = Config.Blip.scale
    local jobName = Config.Blip.name
    
    SetBlipSprite(jobBlip, jobSprite)
    SetBlipColour(jobBlip, jobColor)
    SetBlipScale(jobBlip, jobScale)
    SetBlipAsShortRange(jobBlip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(jobName)
    EndTextCommandSetBlipName(jobBlip)
    
    table.insert(Blips, jobBlip)
    
    local radiusBlip = AddBlipForRadius(targetCoordinates, 180.0)
    SetBlipHighDetail(radiusBlip, true)
    SetBlipColour(radiusBlip, jobColor)
    SetBlipAlpha(radiusBlip, 128)
    
    table.insert(Blips, radiusBlip)
end

function clearCache()
    for index, animalData in pairs(CreatedPedData) do
        local pedHandle = animalData.ped
        DeleteEntity(pedHandle)
    end
    
    CreatedPedData = {}
    
    if vehicle ~= nil then
        local vehicleHandle = vehicle
        Config.RemoveVehicleKey(vehicleHandle)
        DeleteVehicle(vehicleHandle)
    end
    
    for index, blipHandle in pairs(Blips) do
        RemoveBlip(blipHandle)
    end
    
    Blips = {}
    ContractData = {}
    Polyzone = false
    SelectedData = {}
    RequiredKillForContract = {}
    Huntid = nil
    vehicle = nil
    createdpeds = false
    
    if Config.PedWeaponDeleted then
        local weaponToRemove = Config.WeaponHash
        local weaponAmount = 1
        local ammoItemName = Config.AmmoItem.name
        local ammoItemCount = Config.AmmoItem.count
        
        TriggerServerEvent("m-hunting:server:RemoveWeapon", weaponToRemove, weaponAmount)
        TriggerServerEvent("m-hunting:server:RemoveWeapon", ammoItemName, ammoItemCount)
    end
end

function SpawnAnimals(coordinatesList, animalHashes, centerPoint)
    for index, existingData in pairs(CreatedPedData) do
        local existingPed = existingData.ped
        DeleteEntity(existingPed)
    end
    
    CreatedPedData = {}
    
    for coordIndex, coordinate in pairs(coordinatesList) do
        local randomAnimal = GetRandomAnimal(animalHashes)
        local modelHash = GetHashKey(randomAnimal)
        
        RequestModel(modelHash)
        local modelLoaded = HasModelLoaded(modelHash)
        while not modelLoaded do
            Citizen.Wait(0)
            modelLoaded = HasModelLoaded(modelHash)
        end
        
        Citizen.Wait(30)
        
        local spawnX = coordinate.x
        local spawnY = coordinate.y
        local spawnZ = coordinate.z
        local createdPed = CreatePed(28, modelHash, spawnX, spawnY, spawnZ, true, false)
        
        Citizen.Wait(10)
        
        local pedData = {}
        pedData.ped = createdPed
        pedData.dead = false
        pedData.takeitems = false
        pedData.animal = randomAnimal
        table.insert(CreatedPedData, pedData)
        
        SetEntityAsMissionEntity(createdPed, true, true)
        TaskWanderStandard(createdPed)
        
        Citizen.Wait(10)
    end
end

function GetRandomAnimal(animalHashTable)
    local animalNames = {}
    
    for animalName, _ in pairs(animalHashTable) do
        table.insert(animalNames, animalName)
    end
    
    local nameCount = #animalNames
    local randomIndex = math.random(1, nameCount)
    local selectedAnimal = animalNames[randomIndex]
    
    return selectedAnimal
end