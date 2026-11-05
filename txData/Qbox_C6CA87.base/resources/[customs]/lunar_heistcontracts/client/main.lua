local contracts = {}
Profile = nil

print("^2[DEBUG] client/main.lua loaded_^7")

if not Config.contractCurrency then
    Config.contractCurrency = "crypto"
end

GetContracts = function()
    return contracts
end

lib.callback("lunar_contracts:getGeneratedContracts", 1000, function(data)
    contracts = data
end)

local function getPurchasedContracts()
    local result = {}
    for index, contract in pairs(contracts) do
        if contract.purchased and not contract.purchased.finished then
            local owner = contract.purchased.membersData[1]
            table.insert(result, {
                index = index,
                type = contract.name,
                owner = { name = owner.username, image = owner.image },
                started = contract.purchased.started
            })
        end
    end
    table.sort(result, function(a, b) return a.index > b.index end)
    return result
end

RegisterNetEvent("lunar_contracts:syncContract", function(index, data)
    while not Framework.isPlayerLoaded() do Wait(200) end
    contracts[index] = data
    UI.sendMessage("updateContracts", TransformContracts(contracts))
    UI.sendMessage("updateAdminContracts", getPurchasedContracts())
end)

Framework.onPlayerLoaded(function()
    Profile = nil
end)

RegisterNetEvent("lunar_contracts:updateProfile", function(profileData)
    if Profile and Profile.identifier == profileData.identifier then
        Profile = profileData
        Wait(500)
        UI.sendMessage("updateProfile", Profile)
    end
end)

RegisterNetEvent("lunar_contracts:syncProfile", function(profileData)
    Profile = profileData
    if not Profile.image then
        Profile.image = Config.defaultProfile.image
    end
    Wait(200)
    UI.sendMessage("updateProfile", Profile)
end)

RegisterNetEvent("lunar_contracts:receivedInvite", function(username, contractIndex)
    if not IsNuiFocused() then
        LR.notify(locale("received_invite"), "inform")
    end
    UI.sendMessage("showInvite", { username = username, contractIndex = contractIndex })
end)

local tabletObject = nil
local TABLET_ANIM_DICT = "amb@world_human_seat_wall_tablet@female@base"
local TABLET_ANIM_NAME = "base"

local function createTablet()
    local model = 1943210810
    local coords = GetEntityCoords(cache.ped)
    
    lib.requestAnimDict(TABLET_ANIM_DICT)
    lib.requestModel(model)
    
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    tabletObject = object
    
    AttachEntityToEntity(tabletObject, cache.ped, GetPedBoneIndex(cache.ped, 57005), 0.17, 0.1, -0.13, 20.0, 180.0, 180.0, true, true, false, true, 1, true)
    TaskPlayAnim(cache.ped, TABLET_ANIM_DICT, TABLET_ANIM_NAME, 4.0, 4.0, -1, 50, 0, false, false, false)
    RemoveAnimDict(TABLET_ANIM_DICT)
end

RegisterNUICallback("hideFrame", function(_, cb)
    Wait(200)
    SetNuiFocus(false, false)

    if tabletObject and DoesEntityExist(tabletObject) then
        DeleteEntity(tabletObject)
    end

    StopAnimTask(cache.ped, TABLET_ANIM_DICT, TABLET_ANIM_NAME, 4.0)
    tabletObject = nil

    if cb then
        cb({ ok = true })
    end
end)

RegisterNetEvent("lunar_contracts:openTablet", function()
    if Config.itemCheck and Config.tabletItem and not Framework.hasItem(Config.tabletItem) then
        return
    end

    if not Profile or Config.overrideCrypto or Config.overrideExperience then
        Profile = lib.callback.await("lunar_contracts:getProfile", false)
        if not Profile then return end
        if not Profile.image then
            Profile.image = Config.defaultProfile.image
        end
        UI.sendMessage("updateProfile", Profile)
    end

    if tabletObject then return end

    if not Config.disableTabletAnim and cache and cache.ped then
        createTablet()
    end

    SetNuiFocus(true, true)
    local admin = lib.callback.await("lunar_contracts:isAdmin", false)
    UI.sendMessage("open", { isAdmin = admin })
end)

-- Debug: opens tablet without item check (/tablet)
RegisterNetEvent("lunar_contracts:debugOpenTablet", function()
    print("^2[DEBUG] debugOpenTablet handler EXECUTED^7")
    if tabletObject then
        print("^3[DEBUG] tabletObject already exists, returning^7")
        return
    end
    TriggerServerEvent("lunar_contracts:debugCallback")
    print("^2[DEBUG] Setting NUI focus...^7")
    SetNuiFocus(true, true)
    print("^2[DEBUG] Sending open to UI...^7")
    UI.sendMessage("open", { isAdmin = false })
    print("^2[DEBUG] Done^7")
end)

RegisterNetEvent("lunar_contracts:contractGenerated", function()
    if Framework.hasItem(Config.tabletItem) then
        LR.notify(locale("contract_generated"), "success")
    end
end)

RegisterNetEvent("lunar_contracts:kickFromContract", function(contractIndex)
    UI.sendMessage("kickFromContract", contractIndex)
end)

RegisterNUICallback("resolveInvite", function(data, cb)
    TriggerServerEvent("lunar_contracts:resolveInvite", data.contractIndex, data.accepted)
    Wait(500)
    
    local contractData = TransformContracts({ contracts[data.contractIndex] })[1]
    if contractData then
        contractData.index = data.contractIndex
    end
    
    cb((data.accepted and contractData) or {})
end)

RegisterNUICallback("getAdminContracts", function(_, cb)
    cb(getPurchasedContracts())
end)

RegisterNetEvent("lunar_contracts:showContractObjective", function(members, text, coords)
    for _, memberId in ipairs(members) do
        if Framework.getIdentifier() == memberId then
            LR.showObjective(text, coords)
            return
        end
    end
end)

RegisterNetEvent("lunar_contracts:hideContractObjective", function(members)
    for _, memberId in ipairs(members) do
        if Framework.getIdentifier() == memberId then
            LR.hideObjective()
            return
        end
    end
end)

local cancelPoints = {}

lib.callback("lunar_contracts:getCancelPoints", 1000, function(data)
    cancelPoints = data
end)

RegisterNetEvent("lunar_contracts:addCancelPoint", function(index, coords)
    cancelPoints[index] = coords
end)

RegisterNetEvent("lunar_contracts:removeCancelPoint", function(index)
    cancelPoints[index] = nil
end)

RegisterCommand(Config.policeHeistCancelling.command, function()
    if not Utils.isPolice() then return end
    
    local grade = Framework.getJobGrade()
    if grade < Config.policeHeistCancelling.minGrade then
        LR.notify(locale("not_min_grade"), "error")
        return
    end
    
    for contractIndex, coords in pairs(cancelPoints) do
        if Utils.distanceCheck(cache.ped, coords, 7.5) then
            SetTimeout(500, function()
                LR.showUI(locale("abort_cancel"))
                while LR.progressActive() do
                    if IsControlJustReleased(0, 73) then
                        LR.cancelProgress()
                        break
                    end
                    Wait(0)
                end
                LR.hideUI()
            end)
            
            local success = LR.progressBar(
                locale("cancelling_heist"),
                Config.policeHeistCancelling.duration * 1000,
                true,
                { scenario = "WORLD_HUMAN_CLIPBOARD" }
            )
            
            if success then
                TriggerServerEvent("lunar_contracts:heistCancelledByPolice", contractIndex)
            end
        end
    end
end)
