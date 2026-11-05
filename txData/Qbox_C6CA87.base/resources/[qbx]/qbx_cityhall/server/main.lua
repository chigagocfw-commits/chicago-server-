local sharedConfig = require 'config.shared'
local idIssuanceLocks = {}

local function finishIdRequest(source, result)
    idIssuanceLocks[source] = nil
    return result
end

local function playerHasLicenseItem(source, itemName, citizenId)
    local items = exports.ox_inventory:Search(source, 1, itemName)
    if items == false then return false end
    if type(items) ~= 'table' then
        error(('unexpected inventory search result for %s'):format(itemName))
    end
    for _, item in pairs(items) do
        if not citizenId or (item.metadata and item.metadata.citizenid == citizenId) then
            return true
        end
    end
    return false
end

AddEventHandler('playerDropped', function()
    local sourceId = tonumber(source)
    if sourceId then idIssuanceLocks[sourceId] = nil end
end)

local function getClosestHall(pedCoords)
    local distance = #(pedCoords - sharedConfig.cityhalls[1].coords)
    local closest = 1
    for i = 1, #sharedConfig.cityhalls do
        local hall = sharedConfig.cityhalls[i]
        local dist = #(pedCoords - hall.coords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

local function isNearCityhall(source, hall)
    if type(hall) ~= 'number' or hall % 1 ~= 0 then return false end

    local cityhall = sharedConfig.cityhalls[hall]
    if not cityhall then return false end

    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    local pedCoords = GetEntityCoords(ped)
    return #(pedCoords - cityhall.coords) < 20.0
end

local function employmentDistanceCheck(source, job)
    if type(job) ~= 'string' or not sharedConfig.employment.jobs[job] then return false end

    local ped = GetPlayerPed(source)
    if ped == 0 then return false end

    local pedCoords = GetEntityCoords(ped)
    local closestCityhall = getClosestHall(pedCoords)
    return #(pedCoords - sharedConfig.cityhalls[closestCityhall].coords) < 20.0
end

lib.callback.register('qbx_cityhall:server:requestId', function(source, item, hall)
    if type(source) ~= 'number' or idIssuanceLocks[source] then return false end
    idIssuanceLocks[source] = true

    local player = exports.qbx_core:GetPlayer(source)
    if not player or type(item) ~= 'string' or not isNearCityhall(source, hall) then
        return finishIdRequest(source, false)
    end

    local itemType = sharedConfig.cityhalls[hall].licenses[item]
    local licences = player.PlayerData.metadata.licences
    if not itemType or not licences or licences[item] ~= true then
        exports.qbx_core:Notify(source, locale('error.invalid_type'), 'error')
        return finishIdRequest(source, false)
    end

    if itemType.item ~= 'id_card' and itemType.item ~= 'driver_license' and itemType.item ~= 'weaponlicense' then
        exports.qbx_core:Notify(source, locale('error.invalid_type'), 'error')
        return finishIdRequest(source, false)
    end

    if type(itemType.cost) ~= 'number' or itemType.cost < 0 or itemType.cost % 1 ~= 0 then
        lib.print.error(('qbx_cityhall: invalid configured price for license item %s'):format(itemType.item))
        return finishIdRequest(source, false)
    end

    if GetResourceState('ox_inventory') ~= 'started' or GetResourceState('qbx_idcard') ~= 'started' then
        exports.qbx_core:Notify(source, 'License issuance is temporarily unavailable.', 'error')
        return finishIdRequest(source, false)
    end

    local inventoryCheckOk, alreadyHasLicense = pcall(playerHasLicenseItem, source, itemType.item)
    if not inventoryCheckOk then
        lib.print.error(('qbx_cityhall: could not check existing license items (%s)'):format(itemType.item))
        exports.qbx_core:Notify(source, 'License issuance is temporarily unavailable.', 'error')
        return finishIdRequest(source, false)
    end
    if alreadyHasLicense then
        exports.qbx_core:Notify(source, 'You already have this license item.', 'error')
        return finishIdRequest(source, false)
    end

    if not player.Functions.RemoveMoney('cash', itemType.cost, 'cityhall-license') then
        exports.qbx_core:Notify(source, locale('error.not_enough_money'), 'error')
        return finishIdRequest(source, false)
    end

    local callOk, issued, issueError = pcall(function()
        return exports.qbx_idcard:CreateMetaLicense(source, itemType.item)
    end)

    if not callOk or issued ~= true then
        local inventoryCheckOk, itemExists = pcall(playerHasLicenseItem, source, itemType.item, player.PlayerData.citizenid)
        if not inventoryCheckOk then
            lib.print.error(('qbx_cityhall: could not verify license item after uncertain issuance (%s); refund requires reconciliation'):format(itemType.item))
            exports.qbx_core:Notify(source, 'License issuance could not be verified. Staff will reconcile the item and payment.', 'error')
            return finishIdRequest(source, false)
        end

        if itemExists then
            lib.print.warn(('qbx_cityhall: inventory item exists after an uncertain issuance result (%s)'):format(itemType.item))
        else
            if not callOk then
                lib.print.error(('qbx_cityhall: license issuance call failed for item %s'):format(itemType.item))
            else
                lib.print.warn(('qbx_cityhall: license issuance rejected for item %s (%s)'):format(itemType.item, tostring(issueError or 'inventory_rejected')))
            end

            local refundOk, refunded = pcall(function()
                return player.Functions.AddMoney('cash', itemType.cost, 'cityhall-license-refund')
            end)
            if not refundOk or refunded ~= true then
                lib.print.error(('qbx_cityhall: automatic refund failed after license issuance failure (%s)'):format(itemType.item))
                exports.qbx_core:Notify(source, 'License issuance failed. Staff have been notified about your refund.', 'error')
            else
                exports.qbx_core:Notify(source, 'License issuance failed; your payment was refunded.', 'error')
            end
            return finishIdRequest(source, false)
        end
    end

    exports.qbx_core:Notify(source, locale('success.item_recieved') .. itemType.label, 'success')
    return finishIdRequest(source, true)
end)

lib.callback.register('qbx_cityhall:server:applyJob', function(source, job)
    if not sharedConfig.employment.enabled then
        lib.print.error((
            'Weird applyJob attempt while employment is disabled | source=%s | name=%s | requestedJob=%s'
        ):format(source, GetPlayerName(source), tostring(job)))
        return false
    end

    local player = exports.qbx_core:GetPlayer(source)
    if not player or not employmentDistanceCheck(source, job) then return false end

    if not sharedConfig.employment.jobs[job] then
        exports.qbx_core:Notify(source, locale('error.invalid_job'), 'error')
        return false
    end
    
    local success, errorResult = player.Functions.SetJob(job, 0)
    if not success then
        lib.print.error(('qbx_cityhall: failed to assign configured job %s to source %s (%s)'):format(
            job, source, errorResult and errorResult.message or 'SetJob rejected'
        ))
        exports.qbx_core:Notify(source, locale('error.invalid_job'), 'error')
        return false
    end

    exports.qbx_core:Notify(source, locale('success.new_job'), 'success')
    return true
end)
