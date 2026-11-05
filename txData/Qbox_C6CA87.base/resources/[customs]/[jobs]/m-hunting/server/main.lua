Framework = nil
HSN = {}
HuntData = {}
PlayerData = {}
Lobbylist = {}
TotalPlayers = 0
LeaderBoardTable = {}

Citizen.CreateThread(function()
    local huntDataEmpty = {}
    local playerDataEmpty = {}
    HuntData = huntDataEmpty
    PlayerData = playerDataEmpty
    
    local frameworkObject = GetFrameworkObject()
    Framework = frameworkObject
    
    local lobbyListEmpty = {}
    Lobbylist = lobbyListEmpty
    
    local totalCount = 0
    TotalPlayers = totalCount
    
    local leaderboardEmpty = {}
    LeaderBoardTable = leaderboardEmpty
    
    local sqlQuery = "SELECT * FROM m_hunting"
    local sqlResult = ExecuteSql(sqlQuery)
    
    for rowIndex, rowData in pairs(sqlResult) do
        local recentHuntsJson = rowData.recenthunts
        local parsedRecentHunts = json.decode(recentHuntsJson)
        rowData.recenthunts = parsedRecentHunts
        
        local playerIdentifier = rowData.identifier
        PlayerData[playerIdentifier] = rowData
        
        local currentXP = rowData.xp
        local levelData = HSN.GetLevelFromXP(currentXP)
        local currentLevel = levelData[1]
        local nextLevelXP = levelData[2]
        
        PlayerData[playerIdentifier].level = currentLevel
        PlayerData[playerIdentifier].xpfornextlevel = nextLevelXP
        
        local leaderboardEntry = {}
        leaderboardEntry.name = rowData.name
        leaderboardEntry.image = rowData.image
        leaderboardEntry.level = currentLevel
        
        local nextIndex = #LeaderBoardTable + 1
        LeaderBoardTable[nextIndex] = leaderboardEntry
    end
end)

function HSN.GetHunterData(source)
    local playerSource = source
    local itemList = Editable.GetUserItemList(playerSource)
    local userObject = Editable.GetUser(playerSource)
    local playerName = Editable.GetName(playerSource)
    
    local playerIdentifier = nil
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        playerIdentifier = userObject.PlayerData.citizenid
    else
        playerIdentifier = userObject.identifier
    end
    
    local leaderboardData = HSN.GetLeaderboard()
    
    if PlayerData[playerIdentifier] == nil then
        local lobbyListData = Lobbylist
        local totalHunters = TotalPlayers
        
        PlayerData[playerIdentifier] = {}
        local newPlayerData = PlayerData[playerIdentifier]
        
        local newLeaderboardEntry = {}
        newLeaderboardEntry.name = playerName
        local steamPhoto = GetSteamPP(playerSource)
        if not steamPhoto then
            steamPhoto = Config.DefaultPicture
        end
        newLeaderboardEntry.image = steamPhoto
        
        local initialLevelData = HSN.GetLevelFromXP(0)
        newLeaderboardEntry.level = initialLevelData[1]
        
        local nextLeaderboardIndex = #LeaderBoardTable + 1
        LeaderBoardTable[nextLeaderboardIndex] = newLeaderboardEntry
        
        newPlayerData.itemlist = {}
        local existingHunts = newPlayerData.recenthunts
        if not existingHunts then
            existingHunts = {}
        end
        newPlayerData.recenthunts = existingHunts
        newPlayerData.name = playerName
        newPlayerData.identifier = playerIdentifier
        
        local levelInfo = HSN.GetLevelFromXP(0)
        newPlayerData.level = levelInfo[1]
        newPlayerData.huntedanimals = 0
        newPlayerData.xp = 0
        newPlayerData.xpfornextlevel = levelInfo[2]
        newPlayerData.hunts = 0
        
        local profilePhoto = GetSteamPP(playerSource)
        newPlayerData.photo = profilePhoto
        
        TriggerClientEvent("m-hunting-cl:OpenNui", playerSource, newPlayerData, leaderboardData, lobbyListData, totalHunters)
    else
        local existingData = PlayerData[playerIdentifier]
        local sendData = {}
        sendData.itemlist = itemList
        
        local recentHunts = existingData.recenthunts
        if not recentHunts then
            recentHunts = {}
        end
        sendData.recenthunts = recentHunts
        sendData.name = playerName
        sendData.identifier = playerIdentifier
        
        local currentXP = existingData.xp
        if not currentXP then
            currentXP = 0
        end
        local currentLevelData = HSN.GetLevelFromXP(currentXP)
        sendData.level = currentLevelData[1]
        
        local animalsKilled = existingData.huntedanimals
        if not animalsKilled then
            animalsKilled = 0
        end
        sendData.huntedanimals = animalsKilled
        sendData.xp = currentXP
        sendData.xpfornextlevel = currentLevelData[2]
        
        local totalHunts = existingData.hunts
        if not totalHunts then
            totalHunts = 0
        end
        sendData.hunts = totalHunts
        
        local photoUrl = GetSteamPP(playerSource)
        sendData.photo = photoUrl
        
        TriggerClientEvent("m-hunting-cl:OpenNui", playerSource, sendData, leaderboardData, Lobbylist, TotalPlayers)
    end
end

RegisterServerEvent("m-hunting:server:RemoveWeapon")
AddEventHandler("m-hunting:server:RemoveWeapon", function(itemName, itemAmount)
    local playerSource = source
    Editable.RemoveItem(playerSource, itemName, itemAmount)
end)

RegisterServerEvent("m-hunting-server:CreateLobby")
AddEventHandler("m-hunting-server:CreateLobby", function(creationData)
    local creatorSource = source
    local newLobbyId = #Lobbylist + 1
    
    local creatorUser = Editable.GetUser(creatorSource)
    local creatorIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        creatorIdentifier = creatorUser.PlayerData.citizenid
    else
        creatorIdentifier = creatorUser.identifier
    end
    
    local lobbyName = Editable.GetName(creatorSource) .. " " .. Config.Translate["lobbys"]
    local lobbyType = creationData.type
    local lobbySize = creationData.size
    local getVehicleFlag = creationData.getvehicle
    local contractsTaken = creationData.contracts
    local passwordRequired = creationData.requiredpassword
    local lobbyPassword = creationData.password
    local huntTypeData = creationData.hunttype
    local huntTypeCategory = huntTypeData.type
    local huntTypeSelected = huntTypeData.selectedtype
    
    local newLobby = {}
    newLobby.name = lobbyName
    newLobby.lobbytype = lobbyType
    newLobby.size = lobbySize
    newLobby.getveh = getVehicleFlag
    newLobby.contractstaken = contractsTaken
    newLobby.requiredpassword = passwordRequired
    newLobby.password = lobbyPassword
    newLobby.createdcar = false
    newLobby.seatindex = -1
    newLobby.id = newLobbyId
    newLobby.vehicle = nil
    
    local playerList = {}
    local firstPlayer = {}
    firstPlayer.name = Editable.GetName(creatorSource)
    firstPlayer.identifier = creatorIdentifier
    firstPlayer.owner = true
    firstPlayer.image = GetSteamPP(creatorSource)
    
    local creatorLevel = PlayerData[creatorIdentifier].level
    if not creatorLevel then
        creatorLevel = 0
    end
    firstPlayer.level = creatorLevel
    
    playerList[1] = firstPlayer
    newLobby.playerlist = playerList
    
    local huntTypeInfo = {}
    huntTypeInfo.type = huntTypeCategory
    huntTypeInfo.selectedtype = huntTypeSelected
    newLobby.hunttype = huntTypeInfo
    
    table.insert(Lobbylist, newLobby)
    TriggerClientEvent("m-hunting-client:syncLobbyList", -1, Lobbylist)
end)

RegisterServerEvent("m-hunting-server:HuntWithFellas")
AddEventHandler("m-hunting-server:HuntWithFellas", function(targetLobbyId)
    local vehicleEntity = nil
    
    for lobbyIndex, lobbyData in pairs(Lobbylist) do
        local currentLobbyId = lobbyData.id
        if currentLobbyId == targetLobbyId then
            local playerList = lobbyData.playerlist
            
            for playerIndex, playerInfo in pairs(playerList) do
                local playerIdentifier = playerInfo.identifier
                
                if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
                    local qbPlayer = Framework.Functions.GetPlayerByCitizenId(playerIdentifier)
                    
                    if qbPlayer ~= nil then
                        TotalPlayers = TotalPlayers + 1
                        local currentPlayerSource = qbPlayer.PlayerData.source
                        
                        local huntType = lobbyData.hunttype
                        local huntCategory = huntType.type
                        local huntSelected = huntType.selectedtype
                        local selectedHuntData = HSN.GetSelectedTypeOfHunt(huntCategory, huntSelected)
                        
                        local contractData = {}
                        local contractIndex = lobbyData.contractstaken
                        if contractIndex and contractIndex ~= -1 then
                            local contractCategory = Config.Contracts[huntCategory]
                            local specificContract = contractCategory[contractIndex + 1]
                            contractData = specificContract
                        end
                        
                        if selectedHuntData == nil then
                            print("nil")
                            return
                        end
                        
                        local huntId = HSN.AddHunts(playerIdentifier, selectedHuntData.name)
                        
                        if huntId == nil then
                            return
                        end
                        
                        PlayerData[playerIdentifier].injob = true
                        
                        local weaponHash = Config.WeaponHash
                        Editable.AddItem(currentPlayerSource, weaponHash, 1)
                        
                        if lobbyData.createdcar == false then
                            lobbyData.createdcar = true
                            local carHash = GetHashKey(Config.VehicleHash)
                            local spawnCoords = Config.CarSpawnCoord
                            local newVehicle = CreateVehicle(carHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
                            lobbyData.vehicle = newVehicle
                        end
                        
                        local assignedVehicle = lobbyData.vehicle
                        local vehicleExists = DoesEntityExist(assignedVehicle)
                        while not vehicleExists do
                            Wait(0)
                            vehicleExists = DoesEntityExist(assignedVehicle)
                        end
                        
                        Citizen.Wait(10)
                        
                        local playerPed = GetPlayerPed(currentPlayerSource)
                        TaskWarpPedIntoVehicle(playerPed, assignedVehicle, lobbyData.seatindex)
                        
                        local vehicleNetId = NetworkGetNetworkIdFromEntity(assignedVehicle)
                        TriggerClientEvent("m-hunting:client:SetOwner", currentPlayerSource, vehicleNetId)
                        
                        lobbyData.seatindex = lobbyData.seatindex + 1
                        
                        local getVehicleFlag = lobbyData.getveh
                        local isOwner = playerInfo.owner
                        
                        if getVehicleFlag and isOwner then
                            TriggerClientEvent("m-hunting-client:StartHunt", currentPlayerSource, selectedHuntData, contractData, huntId, true, false)
                        else
                            TriggerClientEvent("m-hunting-client:StartHunt", currentPlayerSource, selectedHuntData, contractData, huntId, false, false)
                        end
                        
                        Config.SendMessage(Config.Translate["huntingstarted"], false, "server", currentPlayerSource)
                    end
                else
                    TotalPlayers = TotalPlayers + 1
                    local esxPlayer = Framework.GetPlayerFromIdentifier(playerIdentifier)
                    
                    if esxPlayer ~= nil then
                        local playerSource = esxPlayer.source
                        local huntType = lobbyData.hunttype
                        local huntCategory = huntType.type
                        local huntSelected = huntType.selectedtype
                        local selectedHuntData = HSN.GetSelectedTypeOfHunt(huntCategory, huntSelected)
                        
                        local contractData = {}
                        local contractIndex = lobbyData.contractstaken
                        if contractIndex and contractIndex ~= -1 then
                            local contractCategory = Config.Contracts[huntCategory]
                            local specificContract = contractCategory[contractIndex + 1]
                            contractData = specificContract
                        end
                        
                        if selectedHuntData == nil then
                            print("nil")
                            return
                        end
                        
                        local huntId = HSN.AddHunts(playerIdentifier, selectedHuntData.name)
                        
                        if huntId == nil then
                            return
                        end
                        
                        PlayerData[playerIdentifier].injob = true
                        
                        local weaponHash = Config.WeaponHash
                        Editable.AddItem(playerSource, weaponHash, 1)
                        
                        if lobbyData.createdcar == false then
                            lobbyData.createdcar = true
                            local carHash = GetHashKey(Config.VehicleHash)
                            local spawnCoords = Config.CarSpawnCoord
                            local newVehicle = CreateVehicle(carHash, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
                            lobbyData.vehicle = newVehicle
                        end
                        
                        local assignedVehicle = lobbyData.vehicle
                        local vehicleExists = DoesEntityExist(assignedVehicle)
                        while not vehicleExists do
                            Wait(0)
                            vehicleExists = DoesEntityExist(assignedVehicle)
                        end
                        
                        Citizen.Wait(10)
                        
                        local playerPed = GetPlayerPed(playerSource)
                        TaskWarpPedIntoVehicle(playerPed, assignedVehicle, lobbyData.seatindex)
                        
                        local vehicleNetId = NetworkGetNetworkIdFromEntity(assignedVehicle)
                        TriggerClientEvent("m-hunting:client:SetOwner", playerSource, vehicleNetId)
                        
                        lobbyData.seatindex = lobbyData.seatindex + 1
                        
                        local getVehicleFlag = lobbyData.getveh
                        local isOwner = playerInfo.owner
                        
                        if getVehicleFlag and isOwner then
                            TriggerClientEvent("m-hunting-client:StartHunt", playerSource, selectedHuntData, contractData, huntId, true, false)
                        else
                            TriggerClientEvent("m-hunting-client:StartHunt", playerSource, selectedHuntData, contractData, huntId, false, false)
                        end
                        
                        Config.SendMessage(Config.Translate["huntingstarted"], false, "server", playerSource)
                    end
                end
            end
        end
    end
end)

RegisterServerEvent("m-hunting-server:clearlobby")
AddEventHandler("m-hunting-server:clearlobby", function(lobbyIdToClear)
    local numericId = tonumber(lobbyIdToClear)
    
    if numericId then
        for lobbyIndex, lobbyInfo in pairs(Lobbylist) do
            local currentId = tonumber(lobbyInfo.id)
            
            if currentId == numericId then
                local players = lobbyInfo.playerlist
                
                for playerIdx, playerData in pairs(players) do
                    local playerIdentifier = playerData.identifier
                    local targetPlayer = nil
                    
                    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
                        targetPlayer = Framework.Functions.GetPlayerByCitizenId(playerIdentifier)
                        if targetPlayer then
                            local targetSource = targetPlayer.PlayerData.source
                            TriggerClientEvent("m-hunting:exitfromlobby", targetSource)
                        end
                    else
                        targetPlayer = Framework.GetPlayerFromIdentifier(playerIdentifier)
                        if targetPlayer then
                            local targetSource = targetPlayer.source
                            TriggerClientEvent("m-hunting:exitfromlobby", targetSource)
                        end
                    end
                end
                
                table.remove(Lobbylist, lobbyIndex)
                TriggerClientEvent("m-hunting-client:syncLobbyList", -1, Lobbylist)
                break
            end
        end
    end
end)

RegisterServerEvent("m-hunting-server:leavelobby")
AddEventHandler("m-hunting-server:leavelobby", function(lobbyIdToLeave)
    local sourcePlayer = source
    local userData = Editable.GetUser(sourcePlayer)
    local playerIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        playerIdentifier = userData.PlayerData.citizenid
    else
        playerIdentifier = userData.identifier
    end
    
    for lobbyIndex, lobbyInfo in pairs(Lobbylist) do
        local players = lobbyInfo.playerlist
        if players then
            for playerIndex, playerInfo in pairs(players) do
                if playerInfo.identifier == playerIdentifier then
                    table.remove(players, playerIndex)
                    TriggerClientEvent("m-hunting-client:syncLobbyList", -1, Lobbylist)
                    break
                end
            end
        end
    end
end)

RegisterServerEvent("m-hunting-server:joinlobby")
AddEventHandler("m-hunting-server:joinlobby", function(lobbyIdToJoin)
    local joinerSource = source
    local userData = Editable.GetUser(joinerSource)
    local joinerIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        joinerIdentifier = userData.PlayerData.citizenid
    else
        joinerIdentifier = userData.identifier
    end
    
    local alreadyInLobby = HSN.CheckPlayerInAnyLobby(joinerIdentifier)
    if alreadyInLobby then
        return
    end
    
    for lobbyIndex, lobbyData in pairs(Lobbylist) do
        local currentId = lobbyData.id
        if currentId then
            local numericLobbyId = tonumber(lobbyData.id)
            
            if numericLobbyId == lobbyIdToJoin then
                local currentPlayers = lobbyData.playerlist
                local playerCount = #currentPlayers + 1
                
                if playerCount > lobbyData.size then
                    print("full")
                    return
                end
                
                if currentPlayers ~= nil then
                    local newPlayerEntry = {}
                    newPlayerEntry.name = Editable.GetName(joinerSource)
                    newPlayerEntry.identifier = joinerIdentifier
                    newPlayerEntry.owner = false
                    newPlayerEntry.image = GetSteamPP(joinerSource)
                    newPlayerEntry.level = PlayerData[joinerIdentifier].level
                    
                    table.insert(currentPlayers, newPlayerEntry)
                end
                
                TriggerClientEvent("m-hunting-client:syncLobbyList", -1, Lobbylist)
                break
            end
        end
    end
end)

function HSN.CheckPlayerInAnyLobby(identifierToCheck)
    for lobbyIndex, lobbyData in pairs(Lobbylist) do
        local players = lobbyData.playerlist
        if players then
            for playerIndex, playerInfo in pairs(players) do
                if playerInfo.identifier == identifierToCheck then
                    return true
                end
            end
        end
    end
    return false
end

function HSN.GetSelectedTypeOfHunt(categoryName, huntIndex)
    local categoryData = Config.Categories[categoryName]
    
    for keyName, huntData in pairs(categoryData) do
        if keyName ~= "requiredLevel" then
            local dataIndex = tonumber(huntData.index)
            local targetIndex = tonumber(huntIndex)
            
            if dataIndex == targetIndex then
                return Config.Categories[categoryName][keyName]
            end
        end
    end
    
    return nil
end

RegisterServerEvent("m-hunting-server:Hunt")
AddEventHandler("m-hunting-server:Hunt", function(huntConfiguration)
    local playerSource = source
    local huntCategory = huntConfiguration.type
    local huntId = huntConfiguration.id
    local selectedHuntData = HSN.GetSelectedTypeOfHunt(huntCategory, huntId)
    local userData = Editable.GetUser(playerSource)
    local playerIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        playerIdentifier = userData.PlayerData.citizenid
    else
        playerIdentifier = userData.identifier
    end
    
    if PlayerData[playerIdentifier] == nil then
        print("something went wrong")
        return
    end
    
    local contractData = {}
    local contractSelection = huntConfiguration.contract
    if contractSelection and contractSelection ~= -1 then
        local contractCategory = Config.Contracts[huntCategory]
        contractData = contractCategory[contractSelection + 1]
    end
    
    if selectedHuntData == nil then
        print("nil")
        return
    end
    
    local newHuntId = HSN.AddHunts(playerIdentifier, selectedHuntData.name)
    
    if newHuntId == nil then
        return
    end
    
    PlayerData[playerIdentifier].injob = true
    
    local spawnCar = huntConfiguration.car
    if spawnCar then
        TriggerClientEvent("m-hunting:client:SpawnVehicle", playerSource)
    end
    
    local getGear = huntConfiguration.gear
    if getGear then
        local weaponHash = Config.WeaponHash
        Editable.AddItem(playerSource, weaponHash, 1)
    end
    
    TotalPlayers = TotalPlayers + 1
    Config.SendMessage(Config.Translate["huntingstarted"], false, "server", playerSource)
    
    TriggerClientEvent("m-hunting-client:StartHunt", playerSource, selectedHuntData, contractData, newHuntId, spawnCar, getGear)
end)

AddEventHandler("playerDropped", function(dropReason)
    local droppedSource = source
    local playerIdentifier = Editable.GetUserIdentifier(droppedSource)
    
    if not playerIdentifier then return end
    
    local playerExists = PlayerData[playerIdentifier]
    if playerExists then
        local inJob = playerExists.injob
        if inJob then
            if Config.PedWeaponDeleted then
                local weaponHash = Config.WeaponHash
                local ammoItem = Config.AmmoItem.name
                local ammoCount = Config.AmmoItem.count
                
                Editable.RemoveItem(droppedSource, weaponHash, 1)
                Editable.RemoveItem(droppedSource, ammoItem, ammoCount)
            end
            
            playerExists.injob = false
            TotalPlayers = TotalPlayers - 1
        end
    end
end)

RegisterServerEvent("m-hunting:serverclaimItems")
AddEventHandler("m-hunting:serverclaimItems", function(selectedData, animalName, animalPed, huntIdentifier)
    local claimSource = source
    local userData = Editable.GetUser(claimSource)
    local huntTypeIndex = selectedData.id
    local huntCategory = selectedData.type
    
    local categoryTable = Config.Categories[huntCategory]
    local huntInfo = categoryTable[huntTypeIndex]
    local animalLootTable = huntInfo.hash[animalName]
    local randomRoll = math.random(1, 100)
    
    local playerIdentifier = nil
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        playerIdentifier = userData.PlayerData.citizenid
    else
        playerIdentifier = userData.identifier
    end
    
    if PlayerData[playerIdentifier] == nil then
        local defaultData = {}
        defaultData.level = 0
        defaultData.huntedanimals = 0
        defaultData.xp = 0
        local levelInfo = HSN.GetLevelFromXP(0)
        defaultData.xpfornextlevel = levelInfo[2]
        defaultData.hunts = 0
        defaultData.recenthunts = {}
        PlayerData[playerIdentifier] = defaultData
    end
    
    local currentKillCount = PlayerData[playerIdentifier].huntedanimals
    PlayerData[playerIdentifier].huntedanimals = currentKillCount + 1
    
    local minXP = Config.RandomXPForKillAnimal.min
    local maxXP = Config.RandomXPForKillAnimal.max
    local xpToAdd = math.random(minXP, maxXP)
    
    HSN.AddXP(playerIdentifier, xpToAdd)
    HSN.SetEarnedXP(huntIdentifier, playerIdentifier, xpToAdd)
    
    for itemName, dropData in pairs(animalLootTable) do
        local dropChance = dropData.chance
        if randomRoll <= dropChance then
            local minAmount = dropData.amount.min
            local maxAmount = dropData.amount.max
            local dropQuantity = math.random(minAmount, maxAmount)
            Editable.AddItem(claimSource, itemName, dropQuantity)
        end
    end
    
    TriggerClientEvent("m-hunting:clientClaimItems", claimSource, animalPed)
    Wait(1000)
end)

RegisterServerEvent("m-hunting:server:AddXpforContract")
AddEventHandler("m-hunting:server:AddXpforContract", function(contractXP, contractMoney, huntId)
    local sourcePlayer = source
    local userData = Editable.GetUser(sourcePlayer)
    local playerIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        playerIdentifier = userData.PlayerData.citizenid
    else
        playerIdentifier = userData.identifier
    end
    
    local xpAmount = tonumber(contractXP)
    HSN.AddXP(playerIdentifier, xpAmount)
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        local moneyType = Config.MoneyType
        local moneyAmount = tonumber(contractMoney)
        userData.Functions.AddMoney(moneyType, moneyAmount)
    else
        local moneyType = Config.MoneyType
        local moneyAmount = tonumber(contractMoney)
        userData.addAccountMoney(moneyType, moneyAmount)
    end
    
    HSN.SetEarnedXP(huntId, playerIdentifier, contractXP)
    Config.SendMessage(Config.Translate["finishedcontract"], false, "server", sourcePlayer)
    
    local playerData = PlayerData[playerIdentifier]
    SavePlayerDataToSQL(
        playerIdentifier,
        playerData.level,
        playerData.xp,
        playerData.huntedanimals,
        playerData.hunts,
        playerData.recenthunts,
        playerData.name,
        playerData.photo
    )
end)

RegisterServerEvent("m-hunting-server:SellItems")
AddEventHandler("m-hunting-server:SellItems", function(itemsToSell)
    local sellerSource = source
    local userData = Editable.GetUser(sellerSource)
    local totalEarnings = 0
    local playerItems = Editable.GetUserItemList(sellerSource)
    
    local hasItems = next(playerItems)
    if hasItems == nil then
        Config.SendMessage(Config.Translate["emptyInv"], true, "server", sellerSource)
        return
    end
    
    for itemName, itemDetails in pairs(itemsToSell) do
        local hasEnough = false
        
        for inventoryIndex, inventoryItem in pairs(playerItems) do
            local inventoryName = inventoryItem.itemname
            local inventoryCount = tonumber(inventoryItem.count)
            local requestedCount = tonumber(itemDetails.count)
            
            if inventoryName == itemName and inventoryCount >= requestedCount then
                hasEnough = true
                break
            end
        end
        
        if not hasEnough then
            local errorMsg = Config.Translate["notenoughitem"] .. itemDetails.label
            Config.SendMessage(errorMsg, true, "server", sellerSource)
            return
        end
    end
    
    for itemName, itemDetails in pairs(itemsToSell) do
        for inventoryIndex, inventoryItem in pairs(playerItems) do
            local inventoryName = inventoryItem.itemname
            local inventoryCount = tonumber(inventoryItem.count)
            local requestedCount = tonumber(itemDetails.count)
            
            if inventoryName == itemName and inventoryCount >= requestedCount then
                table.remove(playerItems, inventoryIndex)
                break
            end
        end
        
        Editable.RemoveItem(sellerSource, itemName, itemDetails.count)
        local itemPrice = Config.ItemPrices[itemName].price
        local saleValue = itemPrice * itemDetails.count
        totalEarnings = totalEarnings + saleValue
    end
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        local moneyType = Config.MoneyType
        userData.Functions.AddMoney(moneyType, totalEarnings)
    else
        local moneyType = Config.MoneyType
        userData.addAccountMoney(moneyType, totalEarnings)
    end
end)

function HSN.AddXP(identifier, xpAmount)
    local playerData = PlayerData[identifier]
    
    if playerData.xp == nil then
        playerData.xp = 0
    end
    
    local currentXP = playerData.xp
    local newXP = currentXP + xpAmount
    playerData.xp = newXP
    
    local levelInfo = HSN.GetLevelFromXP(newXP)
    playerData.level = levelInfo[1]
    playerData.xpfornextlevel = levelInfo[2]
end

function HSN.GetLevelFromXP(xpValue)
    local numericXP = tonumber(xpValue)
    local playerLevel = nil
    local previousLevel = nil
    
    for levelIndex, xpRequired in ipairs(Config.RequiredXP) do
        if numericXP < xpRequired then
            playerLevel = levelIndex
            local nextLevelXP = Config.RequiredXP[levelIndex + 1]
            return {playerLevel, nextLevelXP}
        end
        previousLevel = levelIndex
    end
    
    if playerLevel == nil then
        local maxLevel = #Config.RequiredXP
        local maxLevelXP = Config.RequiredXP[maxLevel]
        return {maxLevel, maxLevelXP}
    end
end

function HSN.SetEarnedXP(huntId, identifier, xpAmount)
    local playerData = PlayerData[identifier]
    if not playerData then return end
    
    local recentHunts = playerData.recenthunts
    if not recentHunts then return end
    
    local numericHuntId = tonumber(huntId)
    local huntEntry = recentHunts[numericHuntId]
    
    if huntEntry then
        local currentEarned = huntEntry.xp
        huntEntry.xp = currentEarned + xpAmount
    end
end

function HSN.AddHunts(identifier, huntName)
    if identifier == nil then return nil end
    
    local playerData = PlayerData[identifier]
    if not playerData then return nil end
    
    local currentHunts = playerData.hunts
    local newHuntCount = currentHunts + 1
    playerData.hunts = newHuntCount
    
    local recentHunts = playerData.recenthunts
    local newIndex = #recentHunts + 1
    
    local huntEntry = {}
    huntEntry.name = huntName
    huntEntry.count = 1
    huntEntry.xp = 0
    huntEntry.date = os.date("%c", os.time())
    
    recentHunts[newIndex] = huntEntry
    return newIndex
end

function HSN.GetLeaderboard()
    if LeaderBoardTable == nil then
        return {}
    end
    
    local sortFunction = function(a, b)
        local levelA = tonumber(a.level)
        local levelB = tonumber(b.level)
        return levelA > levelB
    end
    
    table.sort(LeaderBoardTable, sortFunction)
    return LeaderBoardTable
end

RegisterServerEvent("m-hunting:OpenHunting")
AddEventHandler("m-hunting:OpenHunting", function()
    local requestingSource = source
    local currentUser = Editable.GetUser(requestingSource)
    local userIdentifier = nil
    
    if Config.Framework == "new-qb" or Config.Framework == "old-qb" then
        userIdentifier = currentUser.PlayerData.citizenid
    else
        userIdentifier = currentUser.identifier
    end
    
    local existingData = PlayerData[userIdentifier]
    
    if existingData then
        local inJobStatus = existingData.injob
        
        if inJobStatus then
            existingData.injob = false
            TotalPlayers = TotalPlayers - 1
            
            Config.SendMessage(Config.Translate["finish"], false, "server", requestingSource)
            TriggerClientEvent("m-hunting:Client-FinishJob", requestingSource)
            
            SavePlayerDataToSQL(
                userIdentifier,
                existingData.level,
                existingData.xp,
                existingData.huntedanimals,
                existingData.hunts,
                existingData.recenthunts,
                existingData.name,
                existingData.photo
            )
        else
            HSN.GetHunterData(requestingSource)
        end
    else
        HSN.GetHunterData(requestingSource)
    end
end)

function GetSteamPP(playerSource)
    local steamIdentifier = nil
    local allIdentifiers = GetPlayerIdentifiers(playerSource)
    
    for index, identifier in pairs(allIdentifiers) do
        local steamPrefix = string.sub(identifier, 1, string.len("steam:"))
        if steamPrefix == "steam:" then
            steamIdentifier = identifier
            break
        end
    end
    
    if steamIdentifier == nil then
        return Config.DefaultPicture
    end
    
    local hexId = string.sub(steamIdentifier, string.len("steam:") + 1)
    local steamId64 = tonumber(hexId, 16)
    
    local steamURL = "http://steamcommunity.com/profiles/" .. steamId64 .. "/?xml=1"
    local resultPromise = promise.new()
    
    local httpCallback = function(errorCode, responseBody, responseHeaders)
        if not responseBody then
            resultPromise:resolve(Config.DefaultPicture)
            return
        end
        
        local responseLines = stringsplit(responseBody, "\n")
        
        for lineIndex, lineContent in ipairs(responseLines) do
            local hasAvatarTag = lineContent:find("<avatarFull>")
            
            if hasAvatarTag then
                local avatarURL = lineContent:gsub("<avatarFull><!%[CDATA%[", ""):gsub("]]></avatarFull>", "")
                resultPromise:resolve(avatarURL)
                
                for k, v in pairs(resultPromise) do
                    return resultPromise.value
                end
                
                break
            end
        end
    end
    
    PerformHttpRequest(steamURL, httpCallback, "GET")
    local finalResult = Citizen.Await(resultPromise)
    return finalResult
end

function GetIDFromSource(idType, idString)
    local splitResult = stringsplit(idString, ":")
    local prefix = splitResult[1]
    local lowerPrefix = string.lower(prefix)
    local lowerType = string.lower(idType)
    
    if lowerPrefix == lowerType then
        local suffix = splitResult[2]
        return string.lower(suffix)
    end
    
    return nil
end

function stringsplit(inputString, separator)
    if separator == nil then
        separator = "%s"
    end
    
    local results = {}
    local stringIndex = 1
    
    for substring in string.gmatch(inputString, "([^" .. separator .. "]+)") do
        results[stringIndex] = substring
        stringIndex = stringIndex + 1
    end
    
    return results
end

function CreateRandomLobbyId()
    local prefix = "cdm"
    local randomNum1 = math.random(1, 9999)
    local randomNum2 = math.random(1, 99999)
    local fullId = prefix .. randomNum1 .. randomNum2
    return fullId
end

function ExecuteSql(queryString)
    local isExecuting = true
    local queryResult = nil
    
    if Config.MySQL == "oxmysql" then
        local oxExport = exports.oxmysql
        local executeFunction = oxExport.execute
        local callbackFunction = function(resultData)
            queryResult = resultData
            isExecuting = false
        end
        executeFunction(oxExport, queryString, callbackFunction)
    elseif Config.MySQL == "ghmattimysql" then
        local ghmattiExport = exports.ghmattimysql
        local executeFunction = ghmattiExport.execute
        local emptyParams = {}
        local callbackFunction = function(resultData)
            queryResult = resultData
            isExecuting = false
        end
        executeFunction(ghmattiExport, queryString, emptyParams, callbackFunction)
    elseif Config.MySQL == "mysql-async" then
        local asyncLib = MySQL.Async
        local fetchFunction = asyncLib.fetchAll
        local emptyParams = {}
        local callbackFunction = function(resultData)
            queryResult = resultData
            isExecuting = false
        end
        fetchFunction(asyncLib, queryString, emptyParams, callbackFunction)
    end
    
    while isExecuting do
        Citizen.Wait(0)
    end
    
    return queryResult
end