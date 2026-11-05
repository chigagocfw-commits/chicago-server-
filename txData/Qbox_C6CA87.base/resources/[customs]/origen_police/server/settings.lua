-- Police station settings management - Server side

-- Early return if settings are ignored
-- Commented out to allow settings tab to work even when using Config.Maps
-- if Config.IgnoreSettings then
--     return
-- end

local activeMaps = {}

-- Helper function to get station options
function GetStationOption(stationData)
    if not stationData then
        return {}
    end
    
    return stationData.Options or {}
end

-- Helper function to get station coordinates
function GetStationCoords(stationData)
    for _, markerData in pairs(stationData) do
        if markerData[1] and markerData[1].coords then
            local coords = markerData[1].coords
            if coords[1] ~= 0 and coords[2] ~= 0 and coords[3] ~= 0 then
                return {coords[1], coords[2], coords[3]}
            end
        end
    end
    
    return {0, 0, 0}
end

-- Helper function to get markers (excludes Options)
function GetMarkers(stationData)
    local markers = {}
    
    for key, value in pairs(stationData) do
        if key ~= "Options" then
            markers[key] = value
        end
    end
    
    return markers
end

-- Initialize active maps from config files
function InitMaps()
    local files = exports.origen_police:GetFileList("/config/police-stations")
    
    for i = 1, #files do
        if files[i]:find(".json") then
            local fileContent = exports.origen_police:ReadFile("/config/police-stations/" .. files[i])
            local stationData = json.decode(fileContent)
            local options = GetStationOption(stationData)
            
            if options.inUse then
                local stationName = files[i]:gsub(".json", "")
                activeMaps[#activeMaps + 1] = stationName
            end
        end
    end
end

-- Callback: Get list of all stations
FW_CreateCallback("origen_police:callback:GetStationsList", function(source, cb)
    local files = exports.origen_police:GetFileList("/config/police-stations")
    print("^3[GetStationsList] Found " .. #files .. " files in police-stations folder^7")
    local stationsList = {}
    
    for i = 1, #files do
        if files[i]:find(".json") then
            print("^3[GetStationsList] Processing file: " .. files[i] .. "^7")
            local fileContent = exports.origen_police:ReadFile("/config/police-stations/" .. files[i])
            local stationData = json.decode(fileContent)
            local options = GetStationOption(stationData)
            
            local stationInfo = {
                name = files[i]:gsub(".json", ""),
                label = options.label or files[i]:gsub(".json", ""),
                author = options.LastUserModified or "NONE",
                modified = options.LastDateModified or os.date("%d/%m/%Y - %H:%M"),
                coords = GetStationCoords(stationData),
                active = options.inUse or false
            }
            
            stationsList[i] = stationInfo
            print("^2[GetStationsList] Added station: " .. stationInfo.name .. " (active: " .. tostring(stationInfo.active) .. ")^7")
        end
    end
    
    print("^3[GetStationsList] Returning " .. #stationsList .. " stations^7")
    cb(stationsList)
end, AdminMDW)

-- Callback: Get specific station data
FW_CreateCallback("origen_police:callback:GetStation", function(source, cb, data)
    local filePath = "/config/police-stations/" .. data.station .. ".json"
    local fileContent = exports.origen_police:ReadFile(filePath)
    local stationData = json.decode(fileContent)
    local options = GetStationOption(stationData)
    
    -- Build allowed jobs list
    local allowedJobCat = options.AllowedJobCat or {}
    local jobsList = {}
    
    for _, category in pairs(allowedJobCat) do
        for _, jobData in pairs(Config.JobCategory[category]) do
            jobsList[category] = jobsList[category] or {}
            jobsList[category][#jobsList[category] + 1] = jobData.name
        end
    end
    
    cb({
        name = data.station,
        label = options.label or data.station,
        author = options.LastUserModified or "NONE",
        modified = options.LastDateModified or os.date("%d/%m/%Y - %H:%M"),
        active = options.inUse or false,
        markers = GetMarkers(stationData),
        jobs = jobsList
    })
end)

-- Helper to read station file
local function ReadStationFile(stationName)
    local filePath = "/config/police-stations/" .. stationName .. ".json"
    local fileContent = exports.origen_police:ReadFile(filePath)
    local stationData = json.decode(fileContent) or {}
    
    stationData.Options = stationData.Options or {}
    
    return stationData, filePath
end

-- Helper to save station file
local function SaveStationFile(filePath, stationData, source)
    stationData.Options.LastUserModified = GetPlayerName(source)
    stationData.Options.LastDateModified = os.date("%d/%m/%Y - %H:%M")
    
    exports.origen_police:WriteFile(filePath, json.encode(stationData, {indent = true}))
end

-- Callback: Add job category to station
FW_CreateCallback("origen_police:callback:AddJobCatStation", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    stationData.Options.AllowedJobCat = stationData.Options.AllowedJobCat or {}
    table.insert(stationData.Options.AllowedJobCat, data.cat)
    
    SaveStationFile(filePath, stationData, source)
    cb(true)
end, AdminMDW)

-- Callback: Remove job category from station
FW_CreateCallback("origen_police:callback:RemoveJobCatStation", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    stationData.Options.AllowedJobCat = stationData.Options.AllowedJobCat or {}
    
    for i, category in ipairs(stationData.Options.AllowedJobCat) do
        if category == data.cat then
            table.remove(stationData.Options.AllowedJobCat, i)
            break
        end
    end
    
    SaveStationFile(filePath, stationData, source)
    cb(true)
end, AdminMDW)

-- Callback: Set station active/inactive
FW_CreateCallback("origen_police:callback:SetActiveStation", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    stationData.Options.inUse = data.active
    
    SaveStationFile(filePath, stationData, source)
    
    -- Notify all clients
    TriggerClientEvent("origen_police:client:ActiveStation", -1, {
        station = data.station,
        active = data.active
    })
    
    cb(true)
end, AdminMDW)

-- Callback: Update marker position
FW_CreateCallback("origen_police:callback:UpdateMarkerPos", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    data.markerIndex = tonumber(data.markerIndex)
    local marker = stationData[data.markerName][data.markerIndex]
    local coordKey = data.isMultiple and "spawn" or "coords"
    
    marker[coordKey] = {data.x, data.y, data.z, data.w}
    
    SaveStationFile(filePath, stationData, source)
    
    TriggerClientEvent("origen_police:client:UpdateMarkerPos", -1, data)
    cb(true)
end, AdminMDW)

-- Callback: Remove marker
FW_CreateCallback("origen_police:callback:RemoveMarker", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    data.markerIndex = tonumber(data.markerIndex)
    data.coords = stationData[data.markerName][data.markerIndex].coords
    
    table.remove(stationData[data.markerName], data.markerIndex)
    
    SaveStationFile(filePath, stationData, source)
    
    TriggerClientEvent("origen_police:client:RemoveMarker", -1, data)
    cb(true)
end, AdminMDW)

-- Callback: Create new marker
FW_CreateCallback("origen_police:callback:CreateMarker", function(source, cb, data)
    local stationData, filePath = ReadStationFile(data.station)
    
    data.markerIndex = tonumber(data.markerIndex)
    
    stationData[data.markerName] = stationData[data.markerName] or {}
    stationData[data.markerName][#stationData[data.markerName] + 1] = data.creatingData
    
    SaveStationFile(filePath, stationData, source)
    
    TriggerClientEvent("origen_police:client:CreateMarker", -1, data)
    cb(true)
end, AdminMDW)

-- Callback: Delete station
FW_CreateCallback("origen_police:callback:DeleteStation", function(source, cb, data)
    local filePath = "/config/police-stations/" .. data.station .. ".json"
    exports.origen_police:DeleteFile(filePath)
    
    cb(true)
end, AdminMDW)

-- Initialize maps on script start
InitMaps()

-- Callback: Get active maps
FW_CreateCallback("origen_police:callback:GetActiveMaps", function(source, cb, data)
    cb(activeMaps)
end)