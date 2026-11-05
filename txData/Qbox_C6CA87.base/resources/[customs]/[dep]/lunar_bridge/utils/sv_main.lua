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
-- Server Utilities Module
-- Provides utility functions for server-side operations

local Utils = {}
local utilsRetrieved = false
local resourceName = GetCurrentResourceName()

--[[
    Get the Utils object (one-time retrieval)
    @return table - The Utils object
--]]
function GetUtils()
    if not utilsRetrieved then
        utilsRetrieved = true
        return Utils
    end
end

-- Generate unique ID for validation
Utils.id = tonumber(tostring(GetUtils):sub(11), 16)

--[[
    Check if two positions are within a maximum distance
    @param pos1 - First position (vector3, source, or entity)
    @param pos2 - Second position (vector3, source, or entity)
    @param maxDistance - Maximum allowed distance
    @return boolean - True if within distance
--]]
function Utils.distanceCheck(pos1, pos2, maxDistance)
    maxDistance = maxDistance or Config.MaxDistance
    
    -- Convert player source to coords
    if type(pos1) == "number" or type(pos1) == "string" then
        local ped = GetPlayerPed(pos1)
        if ped == 0 then
            return false
        end
        pos1 = GetEntityCoords(ped)
    end
    
    if type(pos2) == "number" or type(pos2) == "string" then
        local ped = GetPlayerPed(pos2)
        if ped == 0 then
            return false
        end
        pos2 = GetEntityCoords(ped)
    end
    
    local distance = #(pos1.xyz - pos2.xyz)
    return maxDistance >= distance
end

--[[
    Get the size of a table (including non-sequential keys)
    @param tbl - The table to count
    @return number - Number of entries
--]]
function Utils.getTableSize(tbl)
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

--[[
    Get a random element from a table
    @param tbl - The table to pick from
    @return any - Random element
--]]
function Utils.randomFromTable(tbl)
    local index = math.random(1, #tbl)
    return tbl[index]
end

--[[
    Log a message to Discord webhook
    @param source - Player source
    @param webhook - Discord webhook URL
    @param message - Log message
--]]
function Utils.logToDiscord(source, webhook, message)
    local invokingResource = GetInvokingResource() or "lunar_bridge"
    
    local player = Framework.getPlayerFromId(source)
    if not player then
        return
    end
    
    -- Use custom logging if configured
    if Config.Logging == "custom" then
        CustomLogging(player, invokingResource, message)
    end
    
    -- Build Discord embed
    local embeds = {
        {
            color = "16768885",
            title = GetPlayerName(source) .. " (" .. player:getIdentifier() .. ")",
            description = message,
            footer = {
                text = os.date("%H:%M - %d. %m. %Y", os.time()),
                icon_url = "https://cdn.discordapp.com/attachments/793081015433560075/1048643072952647700/lunar.png"
            }
        }
    }
    
    PerformHttpRequest(webhook, function(statusCode, response, headers) end, "POST", json.encode({
        username = invokingResource,
        embeds = embeds
    }), {
        ["Content-Type"] = "application/json"
    })
end

--[[
    Create a cancellable timeout
    @param duration - Timeout duration in ms
    @param callback - Function to call after timeout
    @return table - Timeout controller with cancel method
--]]
function Utils.setTimeout(duration, callback)
    local active = true
    
    local controller = {
        cancel = function()
            active = false
        end
    }
    
    SetTimeout(duration, function()
        if active then
            callback()
        end
    end)
    
    return controller
end

--[[
    Get count of players with specific job(s)
    @param jobs - Job name, table of job names, or nil for all
    @return number - Count of players with the job(s)
--]]
function Utils.getJobCount(jobs)
    local jobLookup = nil
    
    if type(jobs) == "table" then
        jobLookup = {}
        for _, job in ipairs(jobs) do
            jobLookup[job] = true
        end
    elseif type(jobs) == "string" then
        jobLookup = { [jobs] = true }
    end
    
    local players = Framework.getPlayers()
    local count = 0
    
    for _, player in pairs(players) do
        -- Get job name (handle different data structures)
        local jobName = player.job and player.job.name or player.PlayerData.job.name
        
        -- Get on-duty status
        local onDuty = player.job and true or player.PlayerData.job.onduty
        
        if jobName ~= nil and onDuty then
            if jobLookup[jobName] == true then
                count = count + 1
            end
        end
    end
    
    return count
end

--[[
    Get count of police officers on duty
    @return number - Count of police officers
--]]
function Utils.getPoliceCount()
    return Utils.getJobCount(Config.Dispatch.Jobs)
end

--[[
    Check if a player has any of the specified jobs
    @param source - Player source
    @param jobs - Job name or table of job names
    @return boolean - True if player has one of the jobs
--]]
function Utils.hasJobs(source, jobs)
    local player = Framework.getPlayerFromId(source)
    
    if not player then
        return false
    end
    
    if type(jobs) == "string" then
        jobs = { jobs }
    end
    
    for _, job in ipairs(jobs) do
        if player:getJob() == job then
            return true
        end
    end
    
    return false
end

--[[
    Check if a player is police
    @param source - Player source
    @return boolean - True if player is police
--]]
function Utils.isPolice(source)
    return Utils.hasJobs(source, Config.Dispatch.Jobs)
end

local reddevBannerShown = false

local function isResourceStarted(name)
    return GetResourceState(name) == "started"
end

local function formatStatus(name)
    return isResourceStarted(name) and (name .. " started") or (name .. " missing")
end

local function detectFramework()
    if Framework and Framework.name then
        if Framework.name == "qb-core" then
            return "QBCore (qb-core)"
        end

        if Framework.name == "qbx_core" then
            return "Qbox/QBX (qbx_core)"
        end

        if Framework.name == "es_extended" then
            return "ESX (es_extended)"
        end

        return Framework.name
    end

    if isResourceStarted("qbx_core") then
        return "QBox detected"
    end

    if isResourceStarted("qb-core") then
        return "qb-core started, bridge pending"
    end

    if isResourceStarted("es_extended") then
        return "es_extended started, bridge pending"
    end

    return "not detected"
end

local function detectInventory()
    if isResourceStarted("ox_inventory") then
        return "ox_inventory"
    end

    if isResourceStarted("codem-inventory") then
        return "codem-inventory"
    end

    if isResourceStarted("qs-inventory") then
        return "qs-inventory"
    end

    if isResourceStarted("qb-inventory") then
        return "qb-inventory"
    end

    if Framework and (Framework.name == "qb-core" or Framework.name == "qbx_core") then
        return "QBCore shared items"
    end

    return "framework default"
end

local function detectTarget()
    if Config.Target then
        return isResourceStarted("ox_target") and "ox_target" or "ox_target missing"
    end

    if isResourceStarted("qb-target") then
        return "text UI (qb-target available)"
    end

    if isResourceStarted("ox_target") then
        return "text UI (ox_target available)"
    end

    return "text UI prompts"
end

local function detectDispatch()
    if not Config.Dispatch or not Config.Dispatch.Enable then
        return "disabled"
    end

    local dispatchType = Config.Dispatch.Type or "normal"
    if dispatchType == "normal" then
        return "normal"
    end

    return formatStatus(dispatchType)
end

local function getMissingDependencies()
    local missing = {}

    if not Framework or not Framework.name then
        missing[#missing + 1] = "framework"
    end

    if not isResourceStarted("ox_lib") then
        missing[#missing + 1] = "ox_lib"
    end

    if not isResourceStarted("oxmysql") then
        missing[#missing + 1] = "oxmysql"
    end

    if Config.Target and not isResourceStarted("ox_target") then
        missing[#missing + 1] = "ox_target"
    end

    if Config.Dispatch and Config.Dispatch.Enable then
        local dispatchType = Config.Dispatch.Type
        if dispatchType and dispatchType ~= "normal" and not isResourceStarted(dispatchType) then
            missing[#missing + 1] = dispatchType
        end
    end

    if #missing == 0 then
        return "none"
    end

    return table.concat(missing, ", ")
end

local function printBannerLine(label, value)
    value = tostring(value or "unknown")

    if #value > 40 then
        value = value:sub(1, 37) .. "..."
    end

    print(("^1|^0 ^7%-12s^0 ^5%-40s^0 ^1|^0"):format(label .. ":", value))
end

local function printReddevBanner()
    if reddevBannerShown then
        return
    end

    reddevBannerShown = true

    print("^1+----------------------------------------------------------+^0")
    print("^1|^0 ^7Lunar resources patched and cleaned by ^1Reddev^7.        ^1|^0")
    printBannerLine("Framework", detectFramework())
    printBannerLine("Inventory", detectInventory())
    printBannerLine("Target", detectTarget())
    printBannerLine("Dispatch", detectDispatch())
    printBannerLine("Database", formatStatus("oxmysql"))
    printBannerLine("Needs", getMissingDependencies())
    print("^1|^0 ^7Support: ^5https://discord.gg/MJH5zX7NSg^7              ^1|^0")
    print("^1+----------------------------------------------------------+^0")
end

-- Preserve the public helper but suppress noisy upstream version checks.
function Utils.checkVersion(resource)
    printReddevBanner()
end

CreateThread(function()
    Wait(2500)
    printReddevBanner()
end)

-- Item labels cache
local itemLabels = nil
local itemLabelsLoaded = false

-- Load item labels
CreateThread(function()
    while true do
        if itemLabels and Utils.getTableSize(itemLabels) ~= 0 then
            break
        end
        
        local items = Framework.getItems()
        local labels = {}
        
        for key, item in pairs(items) do
            local name = item.name or key
            local label = item.label or "NULL"
            labels[name] = label
        end
        
        itemLabels = labels
        Wait(100)
    end
    
    itemLabelsLoaded = true
end)

-- Callback: Get item labels
lib.callback.register("lunar_bridge:getItemLabels", function()
    while not itemLabelsLoaded do
        Wait(100)
    end
    
    return itemLabels
end)

--[[
    Get label for an item
    @param itemName - Item name
    @return string - Item label
--]]
function Utils.getItemLabel(itemName)
    if not itemLabels then
        local items = Framework and Framework.getItems and Framework.getItems()
        if items then
            local labels = {}
            for key, item in pairs(items) do
                local name = item.name or key
                local label = item.label or "NULL"
                labels[name] = label
            end
            itemLabels = labels
        else
            itemLabels = {}
        end
    end
    local label = itemLabels[itemName]
    
    if not label then
        label = itemLabels[itemName:upper()]
        if not label then
            label = "ITEM_NOT_FOUND"
        end
    end
    
    return label
end

--[[
    Get image URL for an item
    @param itemName - Item name
    @return string - Image URL
--]]
function Utils.getImageUrl(itemName)
    return string.format("https://lunar-scripts.com/%s", itemName)
end

--[[
    Calculate offset coordinates from a position
    @param coords - Base coordinates (vector4)
    @param offsetX - X offset
    @param offsetY - Y offset
    @param offsetZ - Z offset
    @param headingOffset - Optional heading offset
    @return vector4 - Offset coordinates
--]]
function Utils.offsetCoords(coords, offsetX, offsetY, offsetZ, headingOffset)
    offsetX = offsetX or 0.0
    offsetY = offsetY or 0.0
    offsetZ = offsetZ or 0.0

    local baseHeading = coords.w or coords.heading or 0.0
    local heading = math.rad(baseHeading)
    
    local cosHeading = math.cos(heading)
    local sinHeading = math.sin(heading)
    
    local newX = (offsetX * cosHeading) - (offsetY * sinHeading)
    local newY = (offsetX * sinHeading) + (offsetY * cosHeading)
    local newZ = offsetZ
    
    local finalX = coords.x + newX
    local finalY = coords.y + newY
    local finalZ = (coords.z or 0.0) + newZ
    local finalHeading = baseHeading + (headingOffset or 0.0)
    
    return vector4(finalX, finalY, finalZ, finalHeading)
end

--[[
    Create a vehicle on the server
    @param model - Vehicle model hash
    @param coords - Spawn coordinates (vector4)
    @param vehicleType - Vehicle type string
    @return number - Vehicle entity handle
--]]
function Utils.createVehicle(model, coords, vehicleType)
    local vehicle = CreateVehicleServerSetter(model, vehicleType, coords.x, coords.y, coords.z - 0.7, coords.w)
    
    -- Remove any NPC peds in the vehicle
    for seatIndex = -1, 6 do
        local ped = GetPedInVehicleSeat(vehicle, seatIndex)
        local popType = GetEntityPopulationType(ped)
        
        if popType > 0 and popType < 6 then
            DeleteEntity(ped)
        end
    end
    
    return vehicle
end

