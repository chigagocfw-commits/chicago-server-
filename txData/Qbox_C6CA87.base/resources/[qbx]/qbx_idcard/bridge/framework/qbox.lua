if GetResourceState('qbx_core') ~= 'started' then return end

local sharedConfig = require 'config.shared'

--- Convert sex number to string M or F
---@param sex number
---@return string
local function GetStringSex(sex)
    return sex == 1 and 'F' or 'M'
end

--- Get badge for license
---@param src number Source number
---@param itemName string
---@return string | table
local function GetBadge(src, itemName)
    if not sharedConfig.licenses[itemName].badge then return 'none' end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return 'none' end
    return {
        img = sharedConfig.licenses[itemName].badge,
        grade = player.PlayerData.job.grade.name
    }
end

--- Create metadata for license
---@param src number Source number
---@param itemTable string | table Item name or table of item names
local function CreateMetaLicense(src, itemTable)
    if type(src) ~= 'number' or not GetPlayerName(src) then
        return false, 'invalid_player'
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return false, 'player_not_loaded' end

    if type(itemTable) == "string" then
        itemTable = {itemTable}
    end

    if type(itemTable) ~= 'table' or not next(itemTable) then
        return false, 'invalid_item'
    end

    local itemNames, seenItems = {}, {}
    for _, itemName in pairs(itemTable) do
        if type(itemName) ~= 'string' or not sharedConfig.licenses[itemName] or seenItems[itemName] then
            return false, 'invalid_item'
        end
        seenItems[itemName] = true
        itemNames[#itemNames + 1] = itemName
    end

    if GetResourceState('ox_inventory') ~= 'started' or not exports.ox_inventory:GetInventory(src) then
        return false, 'inventory_unavailable'
    end

    for i = 1, #itemNames do
        local searchOk, items = pcall(function()
            return exports.ox_inventory:Search(src, 1, itemNames[i])
        end)
        if not searchOk then
            lib.print.error(('qbx_idcard: failed to check existing license items (%s)'):format(itemNames[i]))
            return false, 'inventory_error'
        end
        if items and #items > 0 then return false, 'license_already_issued' end
    end

    local addedItems = {}
    for _, itemName in ipairs(itemNames) do
        local metadata = {
            cardtype = itemName,
            citizenid = player.PlayerData.citizenid,
            firstname = player.PlayerData.charinfo.firstname,
            lastname = player.PlayerData.charinfo.lastname,
            birthdate = player.PlayerData.charinfo.birthdate,
            sex = GetStringSex(player.PlayerData.charinfo.gender),
            nationality = player.PlayerData.charinfo.nationality,
            badge = GetBadge(src, itemName)
        }

        local callOk, added, response = pcall(function()
            return exports.ox_inventory:AddItem(src, itemName, 1, metadata)
        end)

        if not callOk or added ~= true then
            for i = #addedItems, 1, -1 do
                local previous = addedItems[i]
                local removed, removeOk = pcall(function()
                    return exports.ox_inventory:RemoveItem(src, previous.name, 1, previous.metadata)
                end)
                if not removed or removeOk ~= true then
                    lib.print.error(('qbx_idcard: failed to roll back partial license issuance (%s)'):format(previous.name))
                end
            end
            return false, callOk and response or 'inventory_error'
        end

        addedItems[#addedItems + 1] = { name = itemName, metadata = metadata }
    end

    return true
end

exports('CreateMetaLicense', CreateMetaLicense)

--- Get metadata for license
---@param src number Source number
---@param itemTable string | table Item name or table of item names
local function GetMetaLicense(src, itemTable)
    local player = exports.qbx_core:GetPlayer(src)

    if type(itemTable) == "string" then
        itemTable = {itemTable}
    end

    if type(itemTable) == "table" then
        for _, v in pairs(itemTable) do --luacheck: ignore
            local metadata = {
                cardtype = v,
                citizenid = player.PlayerData.citizenid,
                firstname = player.PlayerData.charinfo.firstname,
                lastname = player.PlayerData.charinfo.lastname,
                birthdate = player.PlayerData.charinfo.birthdate,
                sex =  GetStringSex(player.PlayerData.charinfo.gender),
                nationality = player.PlayerData.charinfo.nationality,
                badge = GetBadge(src,v)
            }
            return metadata
        end
    else
        print("Invalid parameter type")
    end
end

exports('GetMetaLicense', GetMetaLicense)

--- Create metadata for license
---@param k string item name
function CreateRegisterItem(k)
    exports.qbx_core:CreateUseableItem(k, function(source, item)
        TriggerEvent('um-idcard:server:sendData', source, k, item.info or item.metadata)
    end)
end