if Config and Config.debug then print('Server-side Loaded') end
math.randomseed(os.time())

Config.contractCurrency = Config.contractCurrency or "crypto"

-- Replace CRYPTO_NAME placeholder in locales
local locales = lib.getLocales()
for key, value in pairs(locales) do
    locales[key] = value:gsub("CRYPTO_NAME", Config.crypto.label)
end

local function getCurrentTime()
    return os.time()
end

local function getContractSettings(contractType, contractId)
    if contractType == "house" and contractId then
        if Missions.house.getSettings then
            return Missions.house.getSettings(contractId)
        end
    elseif contractType == "boosting" and contractId then
        if Missions.boosting.getSettings then
            return Missions.boosting.getSettings(contractId)
        end
    end
    return Config.contracts[contractType].settings
end

local function getHouseChance()
    local house = Config.contracts.house
    local settings = house.settings
    
    if settings and settings.disabled then
        return {
            disabled = true,
            chance = 0,
            expiry = 1440,
            timeToStart = 120,
            requiredExperience = 0,
            price = 0,
            minPolice = 2,
            maxMembers = 4,
            minMembers = 1,
            maxStartedLimit = 1
        }
    end
    
    local totalChance = 0
    local anyEnabled = false
    
    for _, tier in pairs(house.tiers) do
        if tier.settings and not tier.settings.disabled then
            anyEnabled = true
            totalChance = totalChance + tier.chance
        end
    end
    
    return {
        disabled = not anyEnabled,
        chance = (totalChance > 0 and totalChance) or 0,
        expiry = 1440,
        timeToStart = 120,
        requiredExperience = 0
    }
end

local function getBoostingChance()
    local boosting = Config.contracts.boosting
    local settings = boosting.settings
    
    if settings and settings.disabled then
        return {
            disabled = true,
            chance = 0,
            expiry = 1440,
            timeToStart = 120,
            requiredExperience = 0,
            price = 0,
            minPolice = 2,
            maxMembers = 4,
            minMembers = 1,
            maxStartedLimit = 1
        }
    end
    
    local totalChance = 0
    local anyEnabled = false
    
    for _, class in ipairs(boosting.classes) do
        if class.settings and not class.settings.disabled then
            anyEnabled = true
            totalChance = totalChance + class.chance
        end
    end
    
    return {
        disabled = not anyEnabled,
        chance = (totalChance > 0 and totalChance) or 0,
        expiry = 1440,
        timeToStart = 120,
        requiredExperience = 0
    }
end

-- Check for mka-lasers dependency
if GetResourceState("mka-lasers") ~= "started" then
    SetTimeout(20000, function()
        local function warnDependency()
            lib.print.error("mka-lasers dependency not started before lunar_heistcontracts, this will cause issues with Maze Bank and House contract, Please install mka-lasers from https://github.com/mkafrin/mka-lasers and ensure the script folder is named exactly \"mka-lasers\"")
        end
        warnDependency()
        SetInterval(warnDependency, 60000)
    end)
end

Missions = {}
local contracts = {}
local activeContracts = {}
local contractCheck = false

-- Load contracts from database
MySQL.ready(function()
    Wait(1000)
    local results = MySQL.query.await("SELECT * FROM lunar_contracts")
    
    for _, row in ipairs(results) do
        local data = json.decode(row.data)
        local extraData = json.decode(row.extra_data)
        
        if data then
            if data.purchased and not data.purchased.started then
                contracts[row.id] = data
                if Missions[data.name] and Missions[data.name].loadSaveData then
                    Missions[data.name].loadSaveData(extraData)
                end
            end
        else
            MySQL.update.await("DELETE FROM lunar_contracts WHERE id = ?", { row.id })
        end
    end
    
    contractCheck = true

    -- Sync all contracts to all connected clients after restart
    for contractId in pairs(contracts) do
        TriggerClientEvent("lunar_contracts:syncContract", -1, contractId, contracts[contractId])
    end
end)

local function syncContract(contractId)
    local contract = contracts[contractId]
    TriggerClientEvent("lunar_contracts:syncContract", -1, contractId, contract)
    
    if contract and contract.purchased then
        MySQL.insert.await(
            "INSERT INTO lunar_contracts (id, data, extra_data) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE data = VALUES(data)",
            { contractId, json.encode(contract), json.encode(Missions[contract.name].getSaveData(contractId)) }
        )
    elseif not contract then
        MySQL.update.await("DELETE FROM lunar_contracts WHERE id = ?", { contractId })
    end
end

-- Cron for clearing expired contracts
lib.cron.new(Config.generator.clearCron or "*/10 * * * *", function()
    for id, contract in pairs(contracts) do
        if contract.expires <= getCurrentTime() then
            DeleteContract(id)
        end
    end
end)

local function getContractTierClass(contractType, contractId)
    local contract = contracts[contractId]
    if not contract or not contract.metadata then return end
    
    if contractType == "house" then
        for _, meta in pairs(contract.metadata) do
            if meta.left == locale("house_tier") then
                return meta.right
            end
        end
    elseif contractType == "boosting" then
        for _, meta in pairs(contract.metadata) do
            if meta.left == locale("boosting_class") then
                return meta.right
            end
        end
    end
end

local contractCooldowns = {}

local function setCooldown(contractType, tierClass, minutes)
    if not minutes then return end
    contractCooldowns[contractType] = contractCooldowns[contractType] or {}
    contractCooldowns[contractType][tierClass or "default"] = getCurrentTime()
end

local function isInCooldown(contractType, tierClass, minutes)
    if not minutes or minutes == false then return false end
    
    local cooldownTable = contractCooldowns[contractType]
    if not cooldownTable then return false end
    
    local lastTime = cooldownTable[tierClass or "default"]
    if not lastTime then return false end
    
    local cooldownSeconds = minutes * 60
    return cooldownSeconds > (getCurrentTime() - lastTime)
end

local function isContractTypeOnCooldown(contractType)
    if contractType == "house" then
        local onCooldown = true
        for _, tier in pairs(Config.contracts.house.tiers) do
            if tier.settings and tier.settings.disabled then goto continue end
            
            local cooldown = tier.settings and tier.settings.cooldown or Config.contracts.house.duration
            if not isInCooldown(contractType, tier.label, cooldown) then
                onCooldown = false
                break
            end
            ::continue::
        end
        return onCooldown
    elseif contractType == "boosting" then
        local onCooldown = true
        for _, class in pairs(Config.contracts.boosting.classes) do
            if class.settings and class.settings.disabled then goto continue end
            
            local cooldown = class.settings and class.settings.cooldown
            if not isInCooldown(contractType, class.label, cooldown) then
                onCooldown = false
                break
            end
            ::continue::
        end
        return onCooldown
    else
        local settings = Config.contracts[contractType].settings
        return isInCooldown(contractType, nil, settings.cooldown)
    end
end

function IsPlayerInContract(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not contract or not contract.purchased then
        return false
    end
    
    local playerId = player:getIdentifier()
    return contract.purchased.owner == playerId or lib.table.contains(contract.purchased.members, playerId)
end

function FinishContract(contractId)
    local contract = contracts[contractId]
    local settings = getContractSettings(contract.name, contractId)
    local rewards = settings.rewards
    
    if contract.purchased.finished then
        return
    end
    
    contract.purchased.finished = true
    syncContract(contractId)
    
    if not rewards then
        rewards = Missions[contract.name].getReward(contractId)
    end
    
    local cryptoReward = (type(rewards.crypto) == "number") and rewards.crypto or math.random(rewards.crypto.min, rewards.crypto.max)
    local xpReward = (type(rewards.experience) == "number") and rewards.experience or math.random(rewards.experience.min, rewards.experience.max)
    
    local members = contract.purchased.members
    
    if Config.crypto.reward == "owner" then
        Profiles.addCrypto(contract.purchased.owner, cryptoReward)
    elseif Config.crypto.reward == "members_split" then
        local splitAmount = math.floor(cryptoReward / #members)
        cryptoReward = splitAmount
        for _, member in ipairs(members) do
            Profiles.addCrypto(member, cryptoReward)
        end
    end
    
    local loggedOnce = false
    for _, member in ipairs(members) do
        Profiles.addExperience(member, xpReward)
        Profiles.completedContract(member)
        Profiles.sync(member)
        activeContracts[member] = nil
        
        if not loggedOnce then
            local player = Framework.getPlayerFromIdentifier(member)
            if player then
                LogNormal(player.source, string.format([[
Finished contract.
Contract name: %s]], contract.name))
                loggedOnce = true
            end
        end
    end
    
    Profiles.updateLeaderboard()
    TriggerEvent("lunar_contracts:heistCompleted", contractId, contract.name, contract.purchased.owner, members)
    
    local tierClass = getContractTierClass(contract.name, contractId)
    setCooldown(contract.name, tierClass, settings.cooldown)
end

function DeleteContract(contractId)
    local contract = contracts[contractId]
    if not contract then return end

    if contract.purchased and not contract.purchased.finished then
        for _, member in ipairs(contract.purchased.members) do
            activeContracts[member] = nil
        end
        local tierClass = getContractTierClass(contract.name, contractId)
        setCooldown(contract.name, tierClass, getContractSettings(contract.name, contractId).cooldown)
    end

    contracts[contractId] = nil

    if Missions[contract.name] and Missions[contract.name].deleted then
        Missions[contract.name].deleted(contractId)
    end

    syncContract(contractId)
end

function ShowContractObjective(contractId, text, data)
    local contract = contracts[contractId]
    if not contract or not contract.purchased then return end
    
    local members = contract.purchased.members
    TriggerClientEvent("lunar_contracts:showContractObjective", -1, members, text, data)
end

function HideContractObjective(contractId)
    local contract = contracts[contractId]
    if not contract or not contract.purchased then return end
    
    local members = contract.purchased.members
    TriggerClientEvent("lunar_contracts:hideContractObjective", -1, members)
end

local function splitString(str, sep)
    local result = {}
    for part in string.gmatch(str, "([^" .. sep .. "]+)") do
        table.insert(result, part)
    end
    return table.unpack(result)
end

-- Contract generation
local generationInProgress = false

local function generateContract(specificContract)
    while not contractCheck do Wait(200) end
    
    if not specificContract then
        local currentCount = Utils.getTableSize(contracts)
        if currentCount >= Config.generator.max then
            return
        end
        
        local availableContracts = {}
        local totalChance = 0
        
        for contractName in pairs(Config.contracts) do
            local contractSettings = nil
            if contractName == "house" then
                contractSettings = getHouseChance()
            elseif contractName == "boosting" then
                contractSettings = getBoostingChance()
            else
                contractSettings = Config.contracts[contractName].settings
            end
            
            if Missions[contractName] and Missions[contractName].canBeGenerated() and not contractSettings.disabled then
                if not isContractTypeOnCooldown(contractName) then
                    table.insert(availableContracts, contractName)
                    totalChance = totalChance + contractSettings.chance
                end
            end
        end
        
        if #availableContracts == 0 then
            return nil, locale("all_contracts_cooldown")
        end
        
        local randomValue = math.random(math.floor(totalChance))
        local cumulativeChance = 0
        
        for _, contractName in ipairs(availableContracts) do
            local contractSettings = nil
            if contractName == "house" then
                contractSettings = getHouseChance()
            elseif contractName == "boosting" then
                contractSettings = getBoostingChance()
            else
                contractSettings = Config.contracts[contractName].settings
            end
            
            cumulativeChance = cumulativeChance + contractSettings.chance
            if randomValue <= cumulativeChance then
                specificContract = contractName
                break
            end
        end
    end
    
    local contractName = specificContract
    local tier = nil
    
    if contractName:find("_") then
        contractName, tier = splitString(contractName, "_")
    end
    
    if Missions[contractName] and not Missions[contractName].canBeGenerated(tier) then
        return nil, locale("cant_generate")
    end
    
    local settings = nil
    if contractName == "house" then
        settings = getHouseChance()
    elseif contractName == "boosting" then
        settings = getBoostingChance()
    else
        settings = Config.contracts[contractName].settings
    end
    
    local contract = {
        name = contractName,
        expires = getCurrentTime() + (settings.expiry * 60),
        remaining = -1
    }
    
    local contractId = 1
    while contracts[contractId] do
        contractId = contractId + 1
    end
    contracts[contractId] = contract
    
    local success, err = pcall(function()
        local image, metadata = Missions[contractName].generated(contractId, tier)
        contract.metadata = metadata
        contract.image = image
        
        if contractName == "house" or contractName == "boosting" then
            contract.requiredExperience = Missions[contractName].getRequiredExperience(contractId)
            contract.price = Missions[contractName].getPrice(contractId)
            local contractSettings = Missions[contractName].getSettings(contractId)
            contract.expires = getCurrentTime() + (contractSettings.expiry * 60)
        else
            contract.requiredExperience = settings.requiredExperience or Missions[contractName].getRequiredExperience(contractId)
            contract.price = settings.price or Missions[contractName].getPrice(contractId)
        end
    end)
    
    if not success then
        contracts[contractId] = nil
        print(string.format("Error while generating contract: %s", contractName))
        print(err)
        print("This error is caused by bad configuration, please check the heist's config for issues.")
        return nil, locale("cant_generate")
    end
    
    local tierClass = getContractTierClass(contractName, contractId)
    local cooldown = nil
    
    if contractName == "house" and tierClass then
        for _, tier in pairs(Config.contracts.house.tiers) do
            if tier.label == tierClass then
                cooldown = tier.settings and tier.settings.cooldown or Config.contracts.house.duration
                break
            end
        end
    elseif contractName == "boosting" and tierClass then
        for _, class in pairs(Config.contracts.boosting.classes) do
            if class.label == tierClass then
                cooldown = class.settings and class.settings.cooldown
                break
            end
        end
    else
        cooldown = settings.cooldown
    end
    
    if isInCooldown(contractName, tierClass, cooldown) then
        contracts[contractId] = nil
        return nil, string.format("Contract %s%s is in cooldown", contractName, tierClass and (" tier " .. tierClass) or "")
    end
    
    syncContract(contractId)
    return contractId
end

-- Start contract generation
SetTimeout(5000, function()
    generateContract()
end)

SetInterval(generateContract, Config.generator.minutesBetweenGeneration * 60000)

-- Callbacks
lib.callback.register("lunar_contracts:getGeneratedContracts", function()
    while not contractCheck do Wait(100) end
    return contracts
end)

lib.callback.register("lunar_contracts:purchaseContract", function(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not contract or contract.purchased or contract.expires <= getCurrentTime() then
        return false, locale("contract_not_available")
    end
    
    local playerIdentifier = player:getIdentifier()
    local activeCount = 0
    
    for _, c in pairs(contracts) do
        if c.purchased and c.purchased.owner == playerIdentifier and not c.purchased.finished then
            activeCount = activeCount + 1
        end
    end
    
    if activeCount >= Config.generator.playerLimit then
        return false, locale("cant_buy_more")
    end
    
    if not isDev then
        local settings = getContractSettings(contract.name, contractId)
        
        if Config.minPoliceBeforePurchase then
            local policeCount = Utils.getPoliceCount()
            if policeCount < settings.minPolice then
                return false, locale("not_enough_police")
            end
        end
    end
    
    local settings = getContractSettings(contract.name, contractId)
    local requiredXp = nil
    
    if contract.name == "house" or contract.name == "boosting" then
        requiredXp = Missions[contract.name].getRequiredExperience(contractId)
    else
        requiredXp = settings.requiredExperience or Missions[contract.name].getRequiredExperience(contractId)
    end
    
    if requiredXp > 0 then
        local profile = Profiles.get(playerIdentifier)
        if requiredXp > profile.xp then
            return false, locale("not_enough_experience")
        end
    end
    
    local hasEnoughMoney = false
    local currency = Config.contractCurrency
    
    if contract.price == 0 then
        hasEnoughMoney = true
    elseif currency == "crypto" then
        local profile = Profiles.get(playerIdentifier)
        hasEnoughMoney = profile.crypto >= contract.price
    else
        hasEnoughMoney = player:getAccountMoney(currency) >= contract.price
    end
    
    if not hasEnoughMoney then
        return false, locale("not_enough_%s", currency)
    end
    
    if contract.purchased or contract.expires <= getCurrentTime() then
        return false, locale("contract_not_available")
    end
    
    if contract.price > 0 then
        if currency == "crypto" then
            Profiles.removeCrypto(playerIdentifier, contract.price)
            Profiles.sync(playerIdentifier)
        else
            player:removeAccountMoney(currency, contract.price)
        end
    end
    
    local profile = Profiles.get(playerIdentifier)
    local contractSettings = getContractSettings(contract.name, contractId)
    contract.expires = getCurrentTime() + (contractSettings.timeToStart * 60)
    
    contract.purchased = {
        started = false,
        owner = playerIdentifier,
        members = { playerIdentifier },
        membersData = { {
            username = profile.username,
            image = profile.image or Config.defaultProfile.image,
            accepted = true
        } }
    }
    
    syncContract(contractId)
    LogNormal(playerId, string.format([[
Purchased contract.
Contract name: %s]], contract.name))
    
    return true
end)

lib.callback.register("lunar_contracts:invitePlayer", function(playerId, contractId, targetId)
    local contract = contracts[contractId]
    local inviter = Framework.getPlayerFromId(playerId)
    local target = Framework.getPlayerFromId(targetId)
    
    if not inviter or not contract or not contract.purchased or contract.purchased.owner ~= inviter:getIdentifier() or playerId == targetId or not target then
        return
    end
    
    local settings = getContractSettings(contract.name, contractId)
    
    if settings.maxMembers and #contract.purchased.members >= settings.maxMembers then
        return false, locale("max_members")
    end
    
    local inviterIdentifier = inviter:getIdentifier()
    local inviterProfile = Profiles.get(inviterIdentifier)
    local targetIdentifier = target:getIdentifier()
    local targetProfile = Profiles.get(targetIdentifier)
    
    if not targetProfile then
        Profiles.create(targetIdentifier)
        targetProfile = Profiles.get(targetIdentifier)
    end
    
    table.insert(contract.purchased.members, targetIdentifier)
    table.insert(contract.purchased.membersData, {
        username = targetProfile.username,
        image = targetProfile.image or Config.defaultProfile.image,
        accepted = false
    })
    
    TriggerClientEvent("lunar_contracts:receivedInvite", targetId, inviterProfile.username, contractId)
    syncContract(contractId)
    
    LogNormal(playerId, string.format([[
Invited player to a contract.
Contract name: %s
Target player: %s]], contract.name, GetPlayerName(targetId)))
    
    return true
end)

RegisterNetEvent("lunar_contracts:resolveInvite")
AddEventHandler("lunar_contracts:resolveInvite", function(contractId, accepted)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = contracts[contractId]
    
    if not player or not contract or not contract.purchased then
        return
    end
    
    local playerIdentifier = player:getIdentifier()
    
    for i, memberId in ipairs(contract.purchased.members) do
        if playerIdentifier == memberId then
            if accepted then
                contract.purchased.membersData[i].accepted = true
            else
                table.remove(contract.purchased.membersData, i)
                table.remove(contract.purchased.members, i)
            end
            
            syncContract(contractId)
            
            local inviter = Framework.getPlayerFromIdentifier(contract.purchased.owner)
            LogNormal(sourcePlayer, string.format([[
Accepted invite.
Contract name: %s
Invited by: %s]], contract.name, inviter and GetPlayerName(inviter.source) or contract.purchased.owner))
            break
        end
    end
end)

RegisterNetEvent("lunar_contracts:kickMember")
AddEventHandler("lunar_contracts:kickMember", function(contractId, memberId)
    local sourcePlayer = source
    local contract = contracts[contractId]
    local player = Framework.getPlayerFromId(sourcePlayer)
    
    if not player or not contract or not contract.purchased or contract.purchased.owner ~= player:getIdentifier() then
        return
    end
    
    for i, id in ipairs(contract.purchased.members) do
        if id == memberId then
            table.remove(contract.purchased.members, i)
            table.remove(contract.purchased.membersData, i)
            syncContract(contractId)
            
            local target = Framework.getPlayerFromIdentifier(memberId)
            if target then
                TriggerClientEvent("lunar_contracts:kickFromContract", target.source, contractId)
            end
            
            LogNormal(sourcePlayer, string.format([[
Kicked player from a contract.
Contract name: %s
Target player: %s]], contract.name, target and GetPlayerName(target.source) or memberId))
        end
    end
end)

RegisterNetEvent("lunar_contracts:heistCancelledByPolice")
AddEventHandler("lunar_contracts:heistCancelledByPolice", function(contractId)
    local sourcePlayer = source
    local player = Framework.getPlayerFromId(sourcePlayer)
    local contract = contracts[contractId]
    
    local cancelPoint = Missions[contract.name].getCancelPoint(contractId)
    if not cancelPoint then
        LR.notify(sourcePlayer, locale("heist_cannot_be_cancelled"), "error")
        return
    end
    
    if player and contract and Utils.isPolice(sourcePlayer) then
        local grade = player.getJobGrade()
        if grade >= Config.policeHeistCancelling.minGrade and Utils.distanceCheck(sourcePlayer, cancelPoint, 7.5) then
            if contract.purchased and not contract.purchased.finished then
                local tierClass = getContractTierClass(contract.name, contractId)
                setCooldown(contract.name, tierClass, getContractSettings(contract.name, contractId).cooldown)
                
                for _, member in ipairs(contract.purchased.members) do
                    activeContracts[member] = nil
                end
            end
            
            contracts[contractId] = nil
            Missions[contract.name].deleted(contractId)
        end
    end
end)

local isDev = GetConvarInt("lunar_heistcontracts:dev", 0) == 1
Config.limitedHeists = Config.limitedHeists or {}

lib.callback.register("lunar_contracts:startContract", function(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not contract or not contract.purchased or contract.purchased.owner ~= player:getIdentifier() or contract.purchased.started or contract.expires <= getCurrentTime() then
        return false, locale("contract_not_available")
    end
    
    if activeContracts[contract.purchased.owner] then
        return false, locale("owner_already_participating")
    end
    
    for _, member in ipairs(contract.purchased.members) do
        if activeContracts[member] then
            return false, locale("member_already_participating")
        end
    end
    
    if not isDev then
        local settings = getContractSettings(contract.name, contractId)
        local minMembers = settings.minMembers or 0
        
        if #contract.purchased.members < minMembers then
            return false, locale("missing_members")
        end
        
        local minPolice = settings.minPolice or 0
        if Utils.getPoliceCount() < minPolice then
            return false, locale("not_enough_police")
        end
    end
    
    if lib.table.contains(Config.limitedHeists, contract.name) then
        for id, otherContract in pairs(contracts) do
            if contract ~= otherContract and otherContract.purchased and otherContract.purchased.started then
                if lib.table.contains(Config.limitedHeists, otherContract.name) then
                    return false, locale("cant_start")
                end
            end
        end
    end
    
    local settings = getContractSettings(contract.name, contractId)
    local maxStarted = settings.maxStartedLimit
    
    if maxStarted and maxStarted > 0 then
        local startedCount = 0
        for _, c in pairs(contracts) do
            if c.name == contract.name and c.purchased and c.purchased.started and not c.purchased.finished then
                if contract.name == "house" then
                    local contractTier = nil
                    local otherTier = nil
                    
                    if contract.metadata then
                        for _, meta in pairs(contract.metadata) do
                            if meta.left == locale("house_tier") then
                                contractTier = meta.right
                                break
                            end
                        end
                    end
                    
                    if c.metadata then
                        for _, meta in pairs(c.metadata) do
                            if meta.left == locale("house_tier") then
                                otherTier = meta.right
                                break
                            end
                        end
                    end
                    
                    if contractTier and otherTier and contractTier == otherTier then
                        startedCount = startedCount + 1
                    end
                else
                    startedCount = startedCount + 1
                end
            end
        end
        
        if startedCount >= maxStarted then
            return false, locale("cant_start")
        end
    end
    
    contract.purchased.started = true
    Missions[contract.name].start(contractId, {
        owner = contract.purchased.owner,
        members = contract.purchased.members
    })
    
    syncContract(contractId)
    
    for _, member in ipairs(contract.purchased.members) do
        Profiles.updateLastActive(member)
        activeContracts[member] = contractId
    end
    
    LogNormal(playerId, string.format([[
Started a contract.
Contract name: %s]], contract.name))
    
    local cancelPoint = Missions[contract.name].getCancelPoint(contractId)
    if cancelPoint and Config.policeHeistCancelling.enabled then
        TriggerClientEvent("lunar_contracts:addCancelPoint", -1, contractId, cancelPoint)
    end
    
    return true
end)

lib.callback.register("lunar_contracts:getCancelPoints", function()
    local points = {}
    for id, contract in pairs(contracts) do
        if contract.purchased and contract.purchased.started and not contract.purchased.finished then
            local point = Missions[contract.name].getCancelPoint(id)
            if point then
                points[id] = point
            end
        end
    end
    return points
end)

lib.callback.register("lunar_contracts:cancelContract", function(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not contract or not contract.purchased or contract.purchased.owner ~= player:getIdentifier() or not contract.purchased.started or contract.purchased.finished then
        return
    end
    
    for _, member in ipairs(contract.purchased.members) do
        activeContracts[member] = nil
    end
    
    local tierClass = getContractTierClass(contract.name, contractId)
    setCooldown(contract.name, tierClass, getContractSettings(contract.name, contractId).cooldown)
    
    Missions[contract.name].cancelled(contractId)
    
    SetTimeout((Config.cancelDelay or 5) * 60000, function()
        Missions[contract.name].deleted(contractId)
    end)
    
    contract.purchased.finished = true
    syncContract(contractId)
end)

-- Admin cache for debug override
local debugAdminCache = {}

local function hasAdminAce(playerId)
    if IsPlayerAceAllowed(playerId, "contracts_admin")
        or IsPlayerAceAllowed(playerId, "lunar_contracts.admin")
        or IsPlayerAceAllowed(playerId, "lunar_heistcontracts.admin") then
        return true
    end

    for groupName in pairs(Config.adminGroups or {}) do
        if IsPlayerAceAllowed(playerId, groupName)
            or IsPlayerAceAllowed(playerId, ("group.%s"):format(groupName)) then
            return true
        end
    end

    return false
end

local function isAdmin(playerId)
    if debugAdminCache[playerId] ~= nil then
        return debugAdminCache[playerId]
    end

    if hasAdminAce(playerId) then
        return true
    end

    local player = Framework.getPlayerFromId(playerId)
    if not player then
        return false
    end

    if type(player.hasOneOfGroups) == "function" then
        return player:hasOneOfGroups(Config.adminGroups)
    end

    return false
end

-- Debug command to override admin status
RegisterCommand("debugsetadmin", function(source, args)
    if source == 0 then
        if Config and Config.debug then print("^1[DEBUG] Tento prikaz lze pouzit pouze jako hrac.") end
        return
    end

    local targetId = source
    if args[1] then
        targetId = tonumber(args[1])
        if not targetId then
            TriggerClientEvent("ox_lib:notify", source, { type = "error", description = "Neplatne ID hrace" })
            return
        end
    end

    local current = debugAdminCache[targetId]
    if current == nil then
        current = isAdmin(targetId)
    end

    debugAdminCache[targetId] = not current
    local status = debugAdminCache[targetId] and "true" or "false"

    if Config and Config.debug then print(("^3[DEBUG] debugsetadmin | Player %s | Admin nastaven na: %s"):format(targetId, status)) end
    TriggerClientEvent("ox_lib:notify", targetId, { type = "success", description = ("Admin prepnut na: %s"):format(status) })
end, false)

lib.callback.register("lunar_contracts:giveContract", function(playerId, targetId, contractName)
    local player = Framework.getPlayerFromId(playerId)
    local target = Framework.getPlayerFromId(targetId)
    
    if not player or not isAdmin(playerId) or not target then
        return false, locale("invalid_id")
    end
    
    local contractId, generateError = generateContract(contractName)
    if not contractId then
        return false, generateError or locale("cant_generate")
    end
    
    local targetIdentifier = target:getIdentifier()
    local targetProfile = Profiles.get(targetIdentifier)
    local settings = getContractSettings(contracts[contractId].name, contractId)
    
    contracts[contractId].expires = getCurrentTime() + (settings.timeToStart * 60)
    contracts[contractId].purchased = {
        started = false,
        owner = targetIdentifier,
        members = { targetIdentifier },
        membersData = { {
            username = targetProfile.username,
            image = targetProfile.image or Config.defaultProfile.image,
            accepted = true
        } }
    }
    
    syncContract(contractId)
    
    LogNormal(playerId, string.format([[
Executed give contract.
Contract name: %s
Target player: %s]], contractName, GetPlayerName(targetId)))
    
    return true
end)

lib.callback.register("lunar_contracts:manageCurrency", function(playerId, targetId, amount, currencyType, action)
    local player = Framework.getPlayerFromId(playerId)
    local target = Framework.getPlayerFromId(targetId)
    
    if not player or not isAdmin(playerId) or not target then
        return false, locale("invalid_id")
    end
    
    if not amount or amount <= 0 then
        return false, "Invalid amount"
    end
    
    local targetIdentifier = target:getIdentifier()
    local targetProfile = Profiles.get(targetIdentifier)
    
    if not targetProfile then
        Profiles.create(targetIdentifier)
        targetProfile = Profiles.get(targetIdentifier)
    end
    
    if currencyType == "gcoin" then
        if action == "add" then
            Profiles.addCrypto(targetIdentifier, amount)
        elseif action == "remove" then
            Profiles.removeCrypto(targetIdentifier, amount)
        end
    elseif currencyType == "xp" then
        if action == "add" then
            Profiles.addExperience(targetIdentifier, amount)
        elseif action == "remove" then
            Profiles.removeExperience(targetIdentifier, amount)
        end
    else
        return false, "Invalid currency type"
    end
    
    Profiles.sync(targetIdentifier)
    Profiles.updateLeaderboard()
    
    LogNormal(playerId, string.format([[
Executed manage currency.
Currency: %s
Action: %s
Amount: %s
Target player: %s]], currencyType, action, amount, GetPlayerName(targetId)))
    
    return true
end)

lib.callback.register("lunar_contracts:deleteContract", function(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not isAdmin(playerId) or not contract or not contract.purchased then
        return
    end
    
    for _, member in ipairs(contract.purchased.members) do
        if activeContracts[member] == contractId then
            activeContracts[member] = nil
        end
    end
    
    if not contract.purchased.finished then
        local tierClass = getContractTierClass(contract.name, contractId)
        setCooldown(contract.name, tierClass, getContractSettings(contract.name, contractId).cooldown)
    end
    
    contracts[contractId] = nil

    Missions[contract.name].deleted(contractId)
    syncContract(contractId)

    local owner = Framework.getPlayerFromIdentifier(contract.purchased.owner)
    if owner then
        LR.notify(owner.source, locale("notify_contract_deleted"), "inform")
    end
    
    LogNormal(playerId, string.format([[
Deleted a player's contract.
Contract name: %s
Target player: %s]], contract.name, owner and GetPlayerName(owner.source) or contract.purchased.owner))
end)

lib.callback.register("lunar_contracts:refundContract", function(playerId, contractId)
    local player = Framework.getPlayerFromId(playerId)
    local contract = contracts[contractId]
    
    if not player or not isAdmin(playerId) or not contract or not contract.purchased then
        return
    end
    
    local price = contract.price
    local currency = Config.contractCurrency
    
    if currency == "crypto" then
        Profiles.addCrypto(contract.purchased.owner, price)
        Profiles.sync(contract.purchased.owner)
    else
        local owner = Framework.getPlayerFromIdentifier(contract.purchased.owner)
        if owner then
            owner:addAccountMoney(Config.contractCurrency, price)
        end
    end
    
    for _, member in ipairs(contract.purchased.members) do
        if activeContracts[member] == contractId then
            activeContracts[member] = nil
        end
    end
    
    if not contract.purchased.finished then
        local tierClass = getContractTierClass(contract.name, contractId)
        setCooldown(contract.name, tierClass, getContractSettings(contract.name, contractId).cooldown)
    end
    
    contracts[contractId] = nil

    Missions[contract.name].deleted(contractId)
    syncContract(contractId)

    local owner = Framework.getPlayerFromIdentifier(contract.purchased.owner)
    if owner then
        LR.notify(owner.source, locale("notify_contract_refunded"), "inform")
    end
    
    LogNormal(playerId, string.format([[
Refunded a player's contract.
Contract name: %s
Target player: %s]], contract.name, owner and GetPlayerName(owner.source) or contract.purchased.owner))
end)

local playerIdentifiers = {}

local function setPlayerIdentifier(playerId)
    local player = Framework.getPlayerFromId(playerId)
    if not player then return end
    playerIdentifiers[playerId] = player:getIdentifier()
end

AddEventHandler("esx:playerLoaded", function(_, data)
    setPlayerIdentifier(data.source)
end)

AddEventHandler("QBCore:Server:PlayerLoaded", function(data)
    setPlayerIdentifier(data.PlayerData.source)
end)

AddEventHandler("playerDropped", function()
    local sourcePlayer = source
    local playerId = playerIdentifiers[sourcePlayer]
    local contractId = activeContracts[playerId]
    
    if contractId then
        local contract = contracts[contractId]
        if contract and contract.purchased and contract.purchased.started then
            for i, memberId in ipairs(contract.purchased.members) do
                if memberId == playerId then
                    table.remove(contract.purchased.members, i)
                    activeContracts[playerId] = nil
                    syncContract(contractId)
                    return
                end
            end
        end
    end
end)

Framework.registerUsableItem(Config.tabletItem, function(playerId)
    local player = Framework.getPlayerFromId(playerId)

    if Utils.isPolice(playerId) then
        LR.notify(playerId, locale("you_are_police"), "error")
        return
    end

    if player and player:hasItem(Config.tabletItem) then
        if Config.customTabletCheck and not Editable.customTabletCheck(playerId) then
            return
        end
        TriggerClientEvent("lunar_contracts:openTablet", playerId)
    end
end)

-- Debug command to test tablet after restart (/tablet)
RegisterCommand("tablet", function(source)
    local playerId = source
    local player = Framework.getPlayerFromId(playerId)
    if Config and Config.debug then print(("^2[DEBUG] /tablet used by player %s, player found: %s^7"):format(playerId, player and "yes" or "no")) end
    if player then
        TriggerClientEvent("lunar_contracts:debugOpenTablet", playerId)
        if Config and Config.debug then print("^2[DEBUG] Triggered lunar_contracts:debugOpenTablet^7") end
    end
end, false)

RegisterNetEvent("lunar_contracts:debugCallback")
AddEventHandler("lunar_contracts:debugCallback", function()
    if Config and Config.debug then print(("^2[DEBUG] Client %s executed debugOpenTablet handler!^7"):format(source)) end
end)

lib.callback.register("lunar_contracts:isAdmin", isAdmin)
