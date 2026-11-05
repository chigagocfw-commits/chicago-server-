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

local function getQboxPlayerData()
    if QBX and type(QBX.PlayerData) == 'table' and next(QBX.PlayerData) then
        return QBX.PlayerData
    end

    local success, playerData = pcall(function()
        return exports.qbx_core:GetPlayerData()
    end)

    return success and type(playerData) == 'table' and playerData or {}
end

local function getQboxInventory()
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetPlayerItems()
    end

    return getQboxPlayerData().items or {}
end

local sharedObject

if isQbox then
    Framework = { name = 'qbx_core' }
    sharedObject = {
        Functions = {}
    }

    function sharedObject.Functions.GetPlayerData()
        return getQboxPlayerData()
    end

    function sharedObject.Functions.HasItem(name)
        if GetResourceState('ox_inventory') == 'started' then
            return exports.ox_inventory:GetItemCount(name) > 0
        end

        for _, item in pairs(getQboxInventory()) do
            if item.name == name and (item.count or item.amount or 0) > 0 then
                return true
            end
        end

        return false
    end

    function sharedObject.Functions.SpawnVehicle(model, cb, coords, networked)
        local modelHash = type(model) == 'number' and model or joaat(model)
        lib.requestModel(modelHash)

        local vehicle = CreateVehicle(
            modelHash,
            coords.x,
            coords.y,
            coords.z,
            coords.w or coords.heading or 0.0,
            networked == true,
            false
        )

        if cb then
            cb(vehicle)
        end
    end

    sharedObject.Functions.DeleteVehicle = function(vehicle)
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end

    sharedObject.Functions.GetPlayersFromCoords = function(coords, distance)
        local players = lib.getNearbyPlayers(coords, distance or 50.0, false)
        local ids = {}

        for _, player in ipairs(players or {}) do
            ids[#ids + 1] = player.id
        end

        return ids
    end
else
    Framework = { name = 'qb-core' }
    sharedObject = exports['qb-core']:GetCoreObject()
end

Framework.object = sharedObject

local codemInventory = GetResourceState('codem-inventory') == 'started'

function Framework.isPlayerLoaded()
    return next(sharedObject.Functions.GetPlayerData()) ~= nil
end

Framework.onPlayerLoaded = function(cb)
    if Framework.isPlayerLoaded() then
        cb()
    end

    AddEventHandler('QBCore:Client:OnPlayerLoaded', cb)
end

Framework.onPlayerLogout = function(cb)
    AddEventHandler('QBCore:Client:OnPlayerUnload', cb)
    AddEventHandler('qbx_core:client:playerLoggedOut', cb)
end

function Framework.getJob()
    if not Framework.isPlayerLoaded() then
        return false
    end

    return sharedObject.Functions.GetPlayerData().job.name
end

function Framework.getJobGrade()
    return sharedObject.Functions.GetPlayerData().job.grade.level
end

Framework.hasItem = function(name)
    if GetResourceState('ox_inventory') == 'started' then
        return exports.ox_inventory:GetItemCount(name) > 0
    end

    if codemInventory then
        local inventory = exports['codem-inventory']:GetClientPlayerInventory()

        -- return early when not loaded yet
        if not inventory or type(inventory) ~= "table" then
            return false
        end

        for _, v in pairs(inventory) do
            if v.name == name then
                return true
            end
        end
    
        return false
    end

    return sharedObject.Functions.HasItem(name)
end

Framework.getInventory = function()
    if codemInventory then
        return exports['codem-inventory']:GetClientPlayerInventory()
    end

    return sharedObject.Functions.GetPlayerData().items
end

function Framework.spawnVehicle(model, coords, heading, cb)
    sharedObject.Functions.SpawnVehicle(model, cb, vector4(coords.x, coords.y, coords.z, heading), true)
end

function Framework.spawnLocalVehicle(model, coords, heading, cb)
    sharedObject.Functions.SpawnVehicle(model, cb, vector4(coords.x, coords.y, coords.z, heading), false)
end

Framework.getIdentifier = function()
    local playerData = sharedObject.Functions.GetPlayerData()
    return playerData.citizenid
end

Framework.getCharacterName = function()
    local playerData = sharedObject.Functions.GetPlayerData()
    return playerData.charinfo.firstname .. ' ' .. playerData.charinfo.lastname
end

Framework.deleteVehicle = sharedObject.Functions.DeleteVehicle

Framework.getPlayersInArea = sharedObject.Functions.GetPlayersFromCoords
