UI = {}

local function getDefaultContractSettings()
    return {
        disabled = false,
        expiry = 1440,
        timeToStart = 120,
        maxMembers = 4,
        minPolice = 2,
        minMembers = 1
    }
end

function UI.sendMessage(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function getLocales()
    local locales = lib.getLocales()
    
    for key, value in pairs(locales) do
        locales[key] = value:gsub("CRYPTO_NAME", Config.crypto.label)
    end
    
    locales.ui_profile_picture_formats = locales.ui_profile_picture_formats:format(table.concat(Config.allowedImageExtensions, ", "))
    return locales
end

Framework.onPlayerLoaded(function()
    Wait(500)
    UI.sendMessage("initLocales", getLocales())
end)

RegisterNUICallback("getLocales", function(_, cb)
    cb(getLocales())
end)

local function isMemberAccepted(members, membersData, identifier)
    for i, memberId in ipairs(members) do
        if memberId == identifier and membersData[i].accepted then
            return true
        end
    end
    return false
end

function TransformContracts(contractsData)
    local result = {}
    
    if not Profile then
        Profile = lib.callback.await("lunar_contracts:getProfile", false)
        if not Profile then return {} end
        if not Profile.image then
            Profile.image = Config.defaultProfile.image
        end
        UI.sendMessage("updateProfile", Profile)
    end
    
    for index, contract in pairs(contractsData) do
        local settings
        
        if contract.name == "house" and contract.metadata then
            local tierLabel
            for _, meta in pairs(contract.metadata) do
                if meta.left == locale("house_tier") then
                    tierLabel = meta.right
                    break
                end
            end
            if tierLabel then
                for _, tier in ipairs(Config.contracts.house.tiers) do
                    if tier.label == tierLabel then
                        settings = tier.settings
                        break
                    end
                end
            end
            if not settings then
                settings = getDefaultContractSettings()
            end
            
        elseif contract.name == "boosting" and contract.metadata then
            local classLabel
            for _, meta in pairs(contract.metadata) do
                if meta.left == locale("boosting_class") then
                    classLabel = meta.right
                    break
                end
            end
            if classLabel then
                for _, class in ipairs(Config.contracts.boosting.classes) do
                    if class.label == classLabel then
                        settings = class.settings
                        break
                    end
                end
            end
            if not settings then
                settings = getDefaultContractSettings()
            end
            
        else
            settings = Config.contracts[contract.name] and Config.contracts[contract.name].settings or getDefaultContractSettings()
        end
        
        local members = nil
        if contract.purchased and isMemberAccepted(contract.purchased.members, contract.purchased.membersData, Framework.getIdentifier()) then
            members = {}
            for i, memberId in ipairs(contract.purchased.members) do
                local memberData = table.clone(contract.purchased.membersData[i])
                memberData.identifier = memberId
                table.insert(members, memberData)
            end
        end
        
        if not contract.purchased or not contract.purchased.finished then
            if Config.hideUnavailableContracts then
                local isOwner = contract.purchased and contract.purchased.owner == Framework.getIdentifier()
                local isMember = contract.purchased and table.contains(contract.purchased.members, Framework.getIdentifier())
                local hasRequiredXp = (contract.requiredExperience or 0) <= (Profile.xp or 0)
                
                if not isOwner and not isMember and not hasRequiredXp then
                    goto continue
                end
            end
            
            local obfuscateRequiredItems = Config.obfuscateRequiredItems or false
            if settings.obfuscateRequiredItems ~= nil then
                obfuscateRequiredItems = settings.obfuscateRequiredItems
            end
            
            local metadata = contract.metadata
            if metadata and obfuscateRequiredItems then
                local newMetadata = {}
                for i, meta in ipairs(metadata) do
                    newMetadata[i] = {
                        left = meta.left,
                        right = meta.right,
                        obfuscated = meta.left == locale("required_tools")
                    }
                end
                metadata = newMetadata
            end
            
            table.insert(result, {
                index = index,
                name = locale(contract.name),
                image = contract.image,
                price = not contract.purchased and contract.price,
                owned = contract.purchased and contract.purchased.owner == Framework.getIdentifier(),
                started = contract.purchased and contract.purchased.started,
                minMembers = settings.minMembers,
                time = contract.expires,
                xp = contract.requiredExperience or settings.requiredExperience or 0,
                members = members,
                metadata = metadata
            })
        end
        
        ::continue::
    end
    
    table.sort(result, function(a, b) return a.index > b.index end)
    return result
end

RegisterNUICallback("getContracts", function(_, cb)
    if not Framework.isPlayerLoaded() then
        cb({})
        while not Framework.isPlayerLoaded() do Wait(200) end
        UI.sendMessage("updateContracts", TransformContracts(GetContracts()))
        return
    end
    
    cb(TransformContracts(GetContracts()))
end)

RegisterNUICallback("purchaseContract", function(contractIndex, cb)
    local success, msg = lib.callback.await("lunar_contracts:purchaseContract", false, contractIndex)
    cb({ success = success, msg = msg })
end)

RegisterNUICallback("sendInvite", function(data, cb)
    local success, msg = lib.callback.await("lunar_contracts:invitePlayer", false, data.contractIndex, data.playerId)
    cb({ success = success, msg = msg })
end)

RegisterNUICallback("kickMember", function(data, cb)
    TriggerServerEvent("lunar_contracts:kickMember", data.contractIndex, data.identifier)
    Wait(100)
    cb({})
end)

RegisterNUICallback("startContract", function(contractIndex, cb)
    local contract = GetContracts()[contractIndex]
    
    if Config.contracts.house.nightOnly and contract.name == "house" then
        local hour = GetClockHours()
        if hour < 22 and hour > 4 then
            cb({ success = false, msg = locale("must_be_night") })
            return
        end
    end
    
    local success, msg = lib.callback.await("lunar_contracts:startContract", false, contractIndex)
    cb({ success = success, msg = msg })
end)

RegisterNUICallback("cancelContract", function(contractIndex, cb)
    lib.callback.await("lunar_contracts:cancelContract", false, contractIndex)
    cb({})
end)

RegisterNUICallback("getSkipToContracts", function(_, cb)
    cb(Config.disableMainMenu or false)
end)

RegisterNUICallback("getContractCurrency", function(_, cb)
    cb(Config.contractCurrency)
end)

RegisterNUICallback("getHideCrypto", function(_, cb)
    cb(Config.hideCrypto or false)
end)

RegisterNUICallback("setUsername", function(username, cb)
    Wait(500)
    local success = lib.callback.await("lunar_contracts:updateUsername", false, username)
    cb(success)
end)

RegisterNUICallback("setProfilePicture", function(url, cb)
    Wait(500)
    local success = lib.callback.await("lunar_contracts:updateProfilePicture", false, url)
    cb(success)
end)

RegisterNUICallback("getGiveOptions", function(_, cb)
    local options = {}
    
    for contractType, contractData in pairs(Config.contracts) do
        if contractType ~= "boosting" and contractType ~= "house" then
            if not contractData.settings.disabled then
                table.insert(options, { value = contractType, label = locale(contractType) })
            end
        end
    end
    
    table.sort(options, function(a, b) return a.label < b.label end)
    
    local boosting = Config.contracts.boosting
    if not boosting.settings.disabled then
        for i, class in ipairs(boosting.classes) do
            if not class.settings or not class.settings.disabled then
                local insertPos = #options == 0 and 1 or 2
                table.insert(options, insertPos, {
                    value = string.format("boosting_%s", class.label),
                    label = locale("boosting_option", class.label)
                })
            end
        end
    end
    
    local house = Config.contracts.house
    if not house.settings.disabled then
        for _, tier in pairs(house.tiers) do
            if not tier.settings or not tier.settings.disabled then
                local value = string.format("house_%s", tier.label)
                local alreadyExists = false
                for _, opt in ipairs(options) do
                    if opt.value == value then
                        alreadyExists = true
                        break
                    end
                end
                if not alreadyExists then
                    local insertPos = #options == 0 and 1 or 2
                    table.insert(options, insertPos, {
                        value = value,
                        label = locale("house_option", tier.label)
                    })
                end
            end
        end
    end
    
    cb(options)
end)

local isAdmin = nil

RegisterNUICallback("isAdmin", function(_, cb)
    if isAdmin == nil then
        isAdmin = lib.callback.await("lunar_contracts:isAdmin", false)
        SetTimeout(10000, function() isAdmin = nil end)
    end
    cb(isAdmin)
end)

RegisterNUICallback("giveContract", function(data, cb)
    Wait(500)
    local success, msg = lib.callback.await("lunar_contracts:giveContract", false, data.playerId, data.contract)
    cb({ success = success, msg = msg })
end)

RegisterNUICallback("manageCurrency", function(data, cb)
    Wait(500)
    local success, msg = lib.callback.await("lunar_contracts:manageCurrency", false, data.playerId, data.amount, data.currencyType, data.actionType)
    cb({ success = success, msg = msg })
end)

RegisterNUICallback("deleteContract", function(contractIndex, cb)
    Wait(500)
    lib.callback.await("lunar_contracts:deleteContract", false, contractIndex)
    cb({})
end)

RegisterNUICallback("refundContract", function(contractIndex, cb)
    lib.callback.await("lunar_contracts:refundContract", false, contractIndex)
    Wait(500)
    cb({})
end)