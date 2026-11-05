-- =====================================================
--  Fixed by https://discord.gg/6NCbAv2VNK Reddev Development  
--  Cleaned By Reddev Using Codex 5.5 
--  Files Provided From anon_fort
-- =====================================================

-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
---@diagnostic disable: duplicate-set-field
---@diagnostic disable: duplicate-doc-field

local isQBCore = GetResourceState('qb-core') == 'started'
local isQbox = not isQBCore and GetResourceState('qbx_core') == 'started'

if not isQBCore and not isQbox then return end

local config

CreateThread(function()
    while GetResourceState('lunar_bridge') ~= 'started' do Wait(100) end

    config = exports.lunar_bridge:getConfig()
end)

local function getConfig()
    if config then
        return config
    end

    if GetResourceState('lunar_bridge') == 'started' then
        config = exports.lunar_bridge:getConfig()
    end

    return config or {}
end

local sharedObject

if isQbox then
    Framework = { name = 'qbx_core' }
    sharedObject = {
        Functions = {},
        Shared = {
            Items = {}
        }
    }

    function sharedObject.Functions.GetPlayer(id)
        return exports.qbx_core:GetPlayer(id)
    end

    function sharedObject.Functions.GetPlayerByCitizenId(identifier)
        return exports.qbx_core:GetPlayerByCitizenId(identifier)
    end

    function sharedObject.Functions.CreateUseableItem(name, cb)
        return exports.qbx_core:CreateUseableItem(name, cb)
    end

    function sharedObject.Functions.GetQBPlayers()
        return exports.qbx_core:GetQBPlayers()
    end

    function sharedObject.Functions.HasPermission(source, permission)
        if IsPlayerAceAllowed(source, permission) then
            return true
        end

        local success, result = pcall(function()
            return exports.qbx_core:HasPrimaryGroup(source, permission)
        end)

        return success and result == true
    end
else
    Framework = { name = 'qb-core' }
    sharedObject = exports['qb-core']:GetCoreObject()
end

Framework.object = sharedObject
QBCore = sharedObject
---@class Player
---@field source number
---@field QBPlayer any
local player = {}

local codemInventory = GetResourceState('codem-inventory') == 'started'

function Framework.getPlayerFromId(id)
    local player = setmetatable({}, { __index = player })
    player.QBPlayer = sharedObject.Functions.GetPlayer(id)

    if not player.QBPlayer then return end

    player.source = id

    return player
end

function Framework.getPlayerFromIdentifier(identifier)
    local player = setmetatable({}, { __index = player })
    player.QBPlayer = sharedObject.Functions.GetPlayerByCitizenId(identifier)

    if not player.QBPlayer then return end

    player.source = player.QBPlayer.PlayerData.source

    return player
end

Framework.registerUsableItem = sharedObject.Functions.CreateUseableItem

Framework.getPlayers = sharedObject.Functions.GetQBPlayers

local ox_inventory = GetResourceState('ox_inventory') == 'started'
local qs_inventory = GetResourceState('qs-inventory') == 'started'

local function getItemFromList(items, item)
    return items and item and items[item] or nil
end

function Framework.getItemLabel(item)
    if ox_inventory then
        local itemData = getItemFromList(exports.ox_inventory:Items(), item)
        return itemData and itemData.label
    elseif qs_inventory then
        local itemData = getItemFromList(exports['qs-inventory']:GetItemList(), item)
        return itemData and itemData.label
    elseif codemInventory then
        local itemData = getItemFromList(exports['codem-inventory']:GetItemList(), item)
        return itemData and itemData.label
    end

    local itemData = getItemFromList(sharedObject.Shared.Items, item)
    return itemData and itemData.label
end

function Framework.getItems()
    if ox_inventory then
        return exports.ox_inventory:Items()
    elseif qs_inventory then
        return exports['qs-inventory']:GetItemList()
    elseif codemInventory then
        return exports['codem-inventory']:GetItemList()
    end

    return sharedObject.Shared.Items
end

function player:hasGroup(name)
    return sharedObject.Functions.HasPermission(self.source, name)
end

function player:hasOneOfGroups(groups)
    for k,v in pairs(groups) do
        if sharedObject.Functions.HasPermission(self.source, k) then
            return true
        end
    end

    return false
end

function player:addItem(name, count, metadata)
    count = count or 1

    if ox_inventory then
        if not exports.ox_inventory:CanCarryItem(self.source, name, count) then
            return false
        end
        
        exports.ox_inventory:AddItem(self.source, name, count, metadata)
        return true
    elseif codemInventory then
        return exports['codem-inventory']:AddItem(self.source, name, count, nil, metadata)
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.AddItem then
        return self.QBPlayer.Functions.AddItem(name, count, nil, metadata) --[[@as boolean]]
    end

    return false
end

function player:removeItem(name, count)
    count = count or 1

    if ox_inventory then
        return exports.ox_inventory:RemoveItem(self.source, name, count)
    elseif codemInventory then
        return exports['codem-inventory']:RemoveItem(self.source, name, count)
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.RemoveItem then
        return self.QBPlayer.Functions.RemoveItem(name, count)
    end

    return false
end

function player:canCarryItem(name, count)
    count = count or 1

    if ox_inventory then
        return exports.ox_inventory:CanCarryItem(self.source, name, count)
    end

    if codemInventory then
        return exports['codem-inventory']:CanCarryItem(self.source, name, count)
    end

    -- No equivalent for QBCore
    return true
end

function player:getItemCount(name)
    if ox_inventory then
        return exports.ox_inventory:GetItemCount(self.source, name)
    elseif codemInventory then
        return exports['codem-inventory']:GetItemsTotalAmount(self.source, name)
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.GetItemByName then
        local item = self.QBPlayer.Functions.GetItemByName(name)
        return item and item.amount or 0
    end

    for _, item in pairs(self.QBPlayer.PlayerData.items or {}) do
        if item.name == name then
            return item.count or item.amount or 0
        end
    end

    return 0
end

function player:hasItem(name)
    return self:getItemCount(name) > 0
end

function player:getAccountMoney(account)
    if account == 'money' then
        account = 'cash'
    end

    local config = getConfig()

    if config.BlackMoney and account == config.BlackMoney.ItemName then
        if not config.BlackMoney.UsesMetadata then
            return self:getItemCount(account)
        else
            error(('Disable Config.BlackMoney.UsesMetadata in lunar_bridge if you want to use %s as a fully functional account.'):format(account))
        end
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.GetMoney then
        return self.QBPlayer.Functions.GetMoney(account)
    end

    return self.QBPlayer.PlayerData.money and self.QBPlayer.PlayerData.money[account] or 0
end

function player:addAccountMoney(account, amount)
    if account == 'money' then
        account = 'cash'
    end

    local config = getConfig()

    if config.BlackMoney and account == config.BlackMoney.ItemName then
        if config.BlackMoney.UsesMetadata then
            local oldWorth = 0

            for _, item in pairs(self.QBPlayer.PlayerData.items) do
                if item.name == account then
                    local worth = item.info and item.info.worth

                    if worth and worth > 0 then
                        oldWorth = oldWorth + worth
                        self:removeItem(account, 1)
                    end
                end
            end

            self:addItem(account, 1, { worth = amount + oldWorth })
        else
            self:addItem(account, amount)
        end
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.AddMoney then
        self.QBPlayer.Functions.AddMoney(account, amount)
    end   
end

function player:removeAccountMoney(account, amount)
    if account == 'money' then
        account = 'cash'
    end

    local config = getConfig()

    if config.BlackMoney and account == config.BlackMoney.ItemName then
        if not config.BlackMoney.UsesMetadata then
            return self:removeItem(account, amount)
        else
            error(('Disable Config.BlackMoney.UsesMetadata in lunar_bridge if you want to use %s as a fully functional account.'):format(account))
        end
    elseif self.QBPlayer.Functions and self.QBPlayer.Functions.RemoveMoney then
        self.QBPlayer.Functions.RemoveMoney(account, amount)
    end
end

function player:getJob()
    return self.QBPlayer.PlayerData.job and self.QBPlayer.PlayerData.job.name
end

function player:getJobGrade()
    return self.QBPlayer.PlayerData.job and self.QBPlayer.PlayerData.job.grade and self.QBPlayer.PlayerData.job.grade.level or 0
end

function player:setJob(name, grade)
    if not self.QBPlayer.Functions or not self.QBPlayer.Functions.SetJob then
        return false
    end

    return self.QBPlayer.Functions.SetJob(name, grade)
end

function player:setDuty(value)
    if not self.QBPlayer.Functions or not self.QBPlayer.Functions.SetJobDuty then
        return false
    end

    return self.QBPlayer.Functions.SetJobDuty(value)
end

function player:getIdentifier()   
    return self.QBPlayer.PlayerData.citizenid
end

function player:getFirstName()
    return self.QBPlayer.PlayerData.charinfo.firstname
end

function player:getLastName()
    return self.QBPlayer.PlayerData.charinfo.lastname
end

