ESX    = nil
QBCore = nil

-- ── BiliBili API ───────────────────────────────────────────────────────────────

function FetchBiliBiliData(bvid, callback)
    local apiUrl = "https://api.bilibili.com/x/web-interface/view?bvid=" .. bvid
    PerformHttpRequest(apiUrl, function(statusCode, responseText, headers)
        if statusCode == 200 and responseText then
            local data = json.decode(responseText)
            if data and data.data and data.data.aid and data.data.cid then
                callback(data.data.aid, data.data.cid)
            else
                callback(nil, nil)
            end
        else
            callback(nil, nil)
        end
    end, "GET", "", { ["Content-Type"] = "application/json" })
end

-- ── Utility functions ──────────────────────────────────────────────────────────

function GenerateTVId()
    local newId
    local isUnique = false
    while not isUnique do
        Wait(1)
        newId    = math.random(1111111, 9999999)
        isUnique = true
        for _, tvData in ipairs(Config.TVs) do
            if tvData.id == newId then
                isUnique = false
                break
            end
        end
    end
    return newId
end

-- Returns the Config.TVs index whose coords + routingBucket match, or nil
function CheckTvData(coords, routingBucket)
    for index, tvData in ipairs(Config.TVs) do
        if #(tvData.coords - coords) < 0.5 and tvData.tvroutingbucket == routingBucket then
            return index
        end
    end
    return nil
end

-- Returns the Config.TVs index for a vehicle TV by network id, or nil
function CheckTvVehicleData(vehicleNetId)
    for index, tvData in ipairs(Config.TVs) do
        if tvData.tvvehiclenetworkid == vehicleNetId then
            return index
        end
    end
    return nil
end

-- Returns the Config.TVs index whose .id field matches, or nil
function CheckTvDataID(tvId)
    for index, tvData in ipairs(Config.TVs) do
        if tvData.id == tvId then
            return index
        end
    end
    return nil
end

-- Returns (found, permLocationIndex) if coords match a permission-locked TV location
function CheckPermissionTvs(coords)
    local found         = false
    local locationIndex = nil
    for index, location in ipairs(Config.TelevisionPermissionsLocations) do
        if #(location.coords - coords) < 1.0 then
            found         = true
            locationIndex = index
        end
    end
    return found, locationIndex
end

function GetPlayerInstanceId(playersource)
    if Config.EnableRoutingBucketTv then
        return GetPlayerRoutingBucket(playersource)
    end
    return 0
end

function CheckIfVideoIsAllowed(videoName)
    if Config.EnableVideosFromFolder ~= true then return false, "" end
    for key, videoEntry in pairs(Config.VideoList) do
        if string.find(videoName, videoEntry.videoname) then
            return true, key
        end
    end
    return false, ""
end

-- ── Server-side URL parser (mirrors client CheckVideoUrl / playvideo NUI callback) ──

local YOUTUBE_PREFIXES = {
    { pattern = "^https://www.youtube.com", offset = 33 },
    { pattern = "^https://youtube.com",     offset = 29 },
    { pattern = "^http://youtube.com",      offset = 28 },
    { pattern = "^http://www.youtube.com",  offset = 33 },
    { pattern = "^www.youtube.com",         offset = 25 },
    { pattern = "^youtube.com",             offset = 21 },
}
local YOUTU_BE_PREFIXES = {
    { pattern = "^https://www.youtu.be", offset = 22 },
    { pattern = "^https://youtu.be",     offset = 18 },
    { pattern = "^http://youtu.be",      offset = 17 },
    { pattern = "^http://www.youtu.be",  offset = 21 },
    { pattern = "^www.youtu.be",         offset = 14 },
    { pattern = "^youtu.be",             offset = 10 },
}
local TWITCH_PREFIXES = {
    { pattern = "^https://www.twitch.tv", offset = 23 },
    { pattern = "^https://twitch.tv",     offset = 19 },
    { pattern = "^http://twitch.tv",      offset = 18 },
    { pattern = "^http://www.twitch.tv",  offset = 22 },
    { pattern = "^www.twitch.tv",         offset = 15 },
    { pattern = "^twitch.tv",             offset = 11 },
}
local STREAMABLE_PREFIXES = {
    { pattern = "^https://www.streamable.com", offset = 28 },
    { pattern = "^https://streamable.com",     offset = 24 },
    { pattern = "^http://streamable.com",      offset = 23 },
    { pattern = "^http://www.streamable.com",  offset = 27 },
    { pattern = "^www.streamable.com",         offset = 20 },
    { pattern = "^streamable.com",             offset = 16 },
}
local FACEBOOK_PREFIXES = {
    { pattern = "^https://www.facebook.com/watch/", offset = 35 },
    { pattern = "^https://facebook.com/watch/",     offset = 31 },
    { pattern = "^http://facebook.com/watch/",      offset = 30 },
    { pattern = "^http://www.facebook.com/watch/",  offset = 34 },
    { pattern = "^www.facebook.com/watch/",         offset = 27 },
    { pattern = "^facebook.com/watch/",             offset = 23 },
}
local DAILYMOTION_PREFIXES = {
    { pattern = "^https://www.dailymotion.com", offset = 35 },
    { pattern = "^https://dailymotion.com",     offset = 30 },
    { pattern = "^http://dailymotion.com",      offset = 29 },
    { pattern = "^http://www.dailymotion.com",  offset = 34 },
    { pattern = "^www.dailymotion.com",         offset = 27 },
    { pattern = "^dailymotion.com",             offset = 23 },
}
local VIMEO_PREFIXES = {
    { pattern = "^https://www.vimeo.com", offset = 23 },
    { pattern = "^https://vimeo.com",     offset = 19 },
    { pattern = "^http://vimeo.com",      offset = 18 },
    { pattern = "^http://www.vimeo.com",  offset = 22 },
    { pattern = "^www.vimeo.com",         offset = 15 },
    { pattern = "^vimeo.com",             offset = 11 },
}
local BILIBILI_PREFIXES = {
    { pattern = "^https://www.bilibili.com/video/", offset = 32 },
    { pattern = "^https://bilibili.com/video/",     offset = 28 },
    { pattern = "^http://bilibili.com/video/",      offset = 27 },
    { pattern = "^http://www.bilibili.com/video/",  offset = 31 },
    { pattern = "^www.bilibili.com/video/",         offset = 24 }, -- offset corrected from 34 (upstream bug)
    { pattern = "^bilibili.com/video/",             offset = 20 },
}
local HUYA_PREFIXES = {
    { pattern = "^https://www.huya.com/", offset = 22 },
    { pattern = "^https://huya.com/",     offset = 18 },
    { pattern = "^http://huya.com/",      offset = 17 },
    { pattern = "^http://www.huya.com/",  offset = 21 },
    { pattern = "^www.huya.com/",         offset = 14 },
    { pattern = "^huya.com/",             offset = 10 },
}
local APARAT_PREFIXES = {
    { pattern = "^https://www.aparat.com/v/", offset = 26 },
    { pattern = "^https://aparat.com/v/",     offset = 22 },
    { pattern = "^http://aparat.com/v/",      offset = 21 },
    { pattern = "^http://www.aparat.com/v/",  offset = 25 },
    { pattern = "^www.aparat.com/v/",         offset = 18 },
    { pattern = "^aparat.com/v/",             offset = 14 },
}
local SOUNDCLOUD_PREFIXES = {
    { pattern = "^https://www.soundcloud.com", offset = 28 },
    { pattern = "^https://soundcloud.com",     offset = 24 },
    { pattern = "^http://soundcloud.com",      offset = 23 },
    { pattern = "^http://www.soundcloud.com",  offset = 27 },
    { pattern = "^www.soundcloud.com",         offset = 20 },
    { pattern = "^soundcloud.com",             offset = 16 },
}
local KICK_PREFIXES = {
    { pattern = "^https://www.kick.com", offset = 22 },
    { pattern = "^https://kick.com",     offset = 18 },
    { pattern = "^http://kick.com",      offset = 17 },
    { pattern = "^http://www.kick.com",  offset = 20 },
    { pattern = "^www.kick.com",         offset = 14 },
    { pattern = "^kick.com",             offset = 10 },
}

local function stripURLPrefix(url, prefixes)
    for _, entry in ipairs(prefixes) do
        if string.find(url, entry.pattern) then
            return string.sub(url, entry.offset)
        end
    end
    return nil
end

local function extractYouTubeID(url, prefixes)
    local suffix = stripURLPrefix(url, prefixes)
    if suffix then return string.sub(suffix, 1, 11) end
    return nil
end

local function hasValidURLScheme(url)
    return string.find(url, "^www.") or string.find(url, "^http") or string.find(url, "^https")
end

-- Returns (isValid, platform, identifier) — mirrors client-side URL parsing
function ParseVideoUrl(rawUrl)
    local url        = tostring(rawUrl)
    local platform   = ""
    local identifier = ""
    local isValid    = false

    local isFolderVideo, folderKey = CheckIfVideoIsAllowed(url)
    if isFolderVideo then
        return true, "folder", tostring(folderKey)
    end

    if string.find(url, "youtube.com") then
        if Config.EnabledLinkTypes.youtube == true then
            platform = "youtube"
            local videoId = extractYouTubeID(url, YOUTUBE_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "youtu.be") then
        if Config.EnabledLinkTypes.youtube == true then
            platform = "youtube"
            local videoId = extractYouTubeID(url, YOUTU_BE_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "twitch.tv") then
        if Config.EnabledLinkTypes.twitch == true then
            platform = "twitch"
            local channel = stripURLPrefix(url, TWITCH_PREFIXES)
            if channel then identifier = channel; isValid = true end
        end

    elseif string.find(url, "streamable.com") then
        if Config.EnabledLinkTypes.streamable == true then
            platform = "streamable"
            local code = stripURLPrefix(url, STREAMABLE_PREFIXES)
            if code then identifier = code; isValid = true end
        end

    elseif string.find(url, "facebook.com") then
        if Config.EnabledLinkTypes.facebook == true then
            platform = "facebook"
            local videoId = stripURLPrefix(url, FACEBOOK_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "dailymotion.com") then
        if Config.EnabledLinkTypes.dailymotion == true then
            platform = "dailymotion"
            local videoId = stripURLPrefix(url, DAILYMOTION_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "vimeo.com") then
        if Config.EnabledLinkTypes.vimeo == true then
            platform = "vimeo"
            local videoId = stripURLPrefix(url, VIMEO_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "bilibili.com") then
        if Config.EnabledLinkTypes.bilibili == true then
            platform = "bilibili"
            local videoId = stripURLPrefix(url, BILIBILI_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "huya.com") then
        if Config.EnabledLinkTypes.huya == true then
            platform = "huya"
            local channelId = stripURLPrefix(url, HUYA_PREFIXES)
            if channelId then identifier = channelId; isValid = true end
        end

    elseif string.find(url, "aparat.com") then
        if Config.EnabledLinkTypes.aparat == true then
            platform = "aparat"
            local videoId = stripURLPrefix(url, APARAT_PREFIXES)
            if videoId then identifier = videoId; isValid = true end
        end

    elseif string.find(url, "soundcloud.com") then
        if Config.EnabledLinkTypes.soundcloud == true then
            platform = "soundcloud"
            local trackPath = stripURLPrefix(url, SOUNDCLOUD_PREFIXES)
            if trackPath then identifier = trackPath; isValid = true end
        end

    elseif string.find(url, "kick.com") then
        if Config.EnabledLinkTypes.kick == true then
            platform = "kick"
            local channelId = stripURLPrefix(url, KICK_PREFIXES)
            if channelId then identifier = channelId; isValid = true end
        end

    elseif string.find(url, ".mp4") then
        if hasValidURLScheme(url) and Config.EnabledLinkTypes.mp4 == true then
            platform = "mp4"; identifier = url; isValid = true
        end

    elseif string.find(url, ".mp3") then
        if hasValidURLScheme(url) and Config.EnabledLinkTypes.mp3 == true then
            platform = "mp3"; identifier = url; isValid = true
        end

    elseif string.find(url, ".png") then
        if hasValidURLScheme(url) then
            platform = "png"; identifier = url; isValid = true
        end

    elseif string.find(url, ".gif") then
        if hasValidURLScheme(url) then
            platform = "gif"; identifier = url; isValid = true
        end

    elseif string.find(url, ".jpg") then
        if hasValidURLScheme(url) then
            platform = "jpg"; identifier = url; isValid = true
        end

    elseif Config.EnableWebsitesForTv then
        local isBlacklisted = false
        for _, blacklistedDomain in pairs(Config.BlacklistedWebsites) do
            if string.match(string.lower(url), string.lower(blacklistedDomain)) then
                isBlacklisted = true
                break
            end
        end
        if not isBlacklisted then
            platform = "website"; identifier = url; isValid = true
        end
    end

    if Config.EnableImagesForTv == false and (platform == "png" or platform == "gif" or platform == "jpg") then
        isValid = false
    end

    if isValid then
        return true, platform, identifier
    end
    return false, "", ""
end

-- Handles BiliBili-specific GlobalState update after the async API fetch
function ResolveBilibiliAndStore(tvData, bvid)
    FetchBiliBiliData(bvid, function(aid, cid)
        GlobalState["rtxtv-" .. tvData.id .. "-data1"] = aid
        GlobalState["rtxtv-" .. tvData.id .. "-data2"] = cid
    end)
end

-- ── RTXTV callback system ──────────────────────────────────────────────────────

RTXTV                  = {}
RTXTV.ServerCallbacks  = {}

RegisterServerEvent("RTXTV:triggerServerCallback")
AddEventHandler("RTXTV:triggerServerCallback", function(eventName, requestId, ...)
    local playersource = source
    local args         = {...}
    RTXTV.TriggerServerCallback(eventName, requestId, playersource, function(...)
        TriggerClientEvent("RTXTV:serverCallback", playersource, requestId, ...)
    end, table.unpack(args))
end)

function RTXTV.RegisterServerCallback(name, handler)
    RTXTV.ServerCallbacks[name] = handler
end

function RTXTV.TriggerServerCallback(name, requestId, playersource, responseCallback, ...)
    if RTXTV.ServerCallbacks[name] ~= nil then
        RTXTV.ServerCallbacks[name](playersource, responseCallback, ...)
    end
end

-- ── Helper: create a new TV entry and broadcast to all clients ─────────────────

local function CreateAndBroadcastTV(newTvId, coords, objectDataId, isVehicleTV, vehicleNetId, volume, isMainMenu, urlType, urlIdentifier, routingBucket, takenPlayerId)
    table.insert(Config.TVs, {
        id                  = newTvId,
        coords              = coords,
        taken               = true,
        takenplayerid       = takenPlayerId,
        tvobjectdataid      = objectDataId,
        tvmainmenu          = isMainMenu,
        tvurltype           = urlType,
        tvurl               = urlIdentifier,
        tvurlnoncutted      = "",
        videostarttime      = os.time(),
        tvvolume            = volume,
        tvvehicle           = isVehicleTV,
        tvvehiclenetworkid  = vehicleNetId,
        tvroutingbucket     = routingBucket,
    })
    GlobalState["rtxtv-" .. newTvId .. "-data1"] = nil
    GlobalState["rtxtv-" .. newTvId .. "-data2"] = nil

    TriggerClientEvent("rtx_tv:CreateNewTV", -1,
        newTvId, coords, objectDataId,
        isVehicleTV, vehicleNetId, volume,
        isMainMenu, urlType, urlIdentifier,
        routingBucket
    )
end

-- ── Framework init ─────────────────────────────────────────────────────────────

if Config.Framework == "qbcore" then
    QBCore = exports[Config.QBCoreFrameworkResourceName]:GetCoreObject()

    if Config.TvForItem then
        QBCore.Functions.CreateUseableItem("tvremote", function(playersource)
            TriggerClientEvent("rtx_tv:TVRemote", playersource)
        end)
    end

    if Config.VehicleTelevisionItem then
        QBCore.Functions.CreateUseableItem("vehicletv", function(playersource)
            TriggerClientEvent("rtx_tv:InstallVehicleTVClient", playersource)
        end)
    end

    RTXTV.RegisterServerCallback("rtx_tv:CheckVehicleTV", function(playersource, cb, tvPlate)
        MySQL.Async.fetchScalar(
            "SELECT 1 FROM player_vehicles WHERE plate = @plate AND vehicletv = @vehicletv",
            { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true },
            function(result) cb(result ~= nil) end
        )
    end)

    RegisterServerEvent("rtx_tv:InstallVehicleTV")
    AddEventHandler("rtx_tv:InstallVehicleTV", function(tvPlate, vehicleNetId)
        local playersource = source
        if tvPlate == nil then return end

        local player = QBCore.Functions.GetPlayer(playersource)
        if not player then return end

        local item = player.Functions.GetItemByName("vehicletv")
        if item and item.amount > 0 then
            MySQL.Async.fetchScalar(
                "SELECT 1 FROM player_vehicles WHERE plate = @plate",
                { ["@plate"] = tostring(tvPlate) },
                function(result)
                    if result then
                        MySQL.Sync.execute(
                            "UPDATE player_vehicles SET vehicletv = @vehicletv WHERE plate = @plate",
                            { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true }
                        )
                        TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].tvinstalled)
                        TriggerClientEvent("rtx_tv:TVInstalledVehicleClient", playersource, vehicleNetId)
                        player.Functions.RemoveItem("vehicletv", 1)
                    else
                        TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].vehiclenotowned)
                    end
                end
            )
        else
            TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].notenoughitem)
        end
    end)

    RegisterServerEvent("rtx_tv:InstallVehicleTVCustom")
    AddEventHandler("rtx_tv:InstallVehicleTVCustom", function(tvPlate, vehicleNetId)
        local playersource = source
        if tvPlate == nil then return end

        local player = QBCore.Functions.GetPlayer(playersource)
        if not player then return end

        MySQL.Async.fetchScalar(
            "SELECT 1 FROM player_vehicles WHERE plate = @plate",
            { ["@plate"] = tostring(tvPlate) },
            function(result)
                if result then
                    MySQL.Sync.execute(
                        "UPDATE player_vehicles SET vehicletv = @vehicletv WHERE plate = @plate",
                        { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true }
                    )
                    TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].tvinstalled)
                    TriggerClientEvent("rtx_tv:TVInstalledVehicleClient", playersource, vehicleNetId)
                else
                    TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].vehiclenotowned)
                end
            end
        )
    end)
end

if Config.Framework == "esx" then
    if Config.ESXFramework.newversion == true then
        ESX = exports[Config.ESXFramework.resourcename]:getSharedObject()
    else
        TriggerEvent(Config.ESXFramework.getsharedobject, function(sharedObject)
            ESX = sharedObject
        end)
    end

    if Config.TvForItem then
        ESX.RegisterUsableItem("tvremote", function(playersource)
            TriggerClientEvent("rtx_tv:TVRemote", playersource)
        end)
    end

    if Config.VehicleTelevisionItem then
        ESX.RegisterUsableItem("vehicletv", function(playersource)
            TriggerClientEvent("rtx_tv:InstallVehicleTVClient", playersource)
        end)
    end

    RTXTV.RegisterServerCallback("rtx_tv:CheckVehicleTV", function(playersource, cb, tvPlate)
        MySQL.Async.fetchScalar(
            "SELECT 1 FROM owned_vehicles WHERE plate = @plate AND vehicletv = @vehicletv",
            { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true },
            function(result) cb(result ~= nil) end
        )
    end)

    RegisterServerEvent("rtx_tv:InstallVehicleTV")
    AddEventHandler("rtx_tv:InstallVehicleTV", function(tvPlate, vehicleNetId)
        local playersource = source
        if tvPlate == nil then return end

        local player = ESX.GetPlayerFromId(playersource)
        if not player then return end

        local item = player.getInventoryItem("vehicletv")
        if item and item.count and item.count > 0 then
            MySQL.Async.fetchScalar(
                "SELECT 1 FROM owned_vehicles WHERE plate = @plate",
                { ["@plate"] = tostring(tvPlate) },
                function(result)
                    if result then
                        MySQL.Sync.execute(
                            "UPDATE owned_vehicles SET vehicletv = @vehicletv WHERE plate = @plate",
                            { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true }
                        )
                        player.removeInventoryItem("vehicletv", 1)
                        TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].tvinstalled)
                        TriggerClientEvent("rtx_tv:TVInstalledVehicleClient", playersource, vehicleNetId)
                    else
                        TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].vehiclenotowned)
                    end
                end
            )
        else
            TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].notenoughitem)
        end
    end)

    RegisterServerEvent("rtx_tv:InstallVehicleTVCustom")
    AddEventHandler("rtx_tv:InstallVehicleTVCustom", function(tvPlate, vehicleNetId)
        local playersource = source
        if tvPlate == nil then return end

        local player = ESX.GetPlayerFromId(playersource)
        if not player then return end

        MySQL.Async.fetchScalar(
            "SELECT 1 FROM owned_vehicles WHERE plate = @plate",
            { ["@plate"] = tostring(tvPlate) },
            function(result)
                if result then
                    MySQL.Sync.execute(
                        "UPDATE owned_vehicles SET vehicletv = @vehicletv WHERE plate = @plate",
                        { ["@plate"] = tostring(tvPlate), ["@vehicletv"] = true }
                    )
                    TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].tvinstalled)
                    TriggerClientEvent("rtx_tv:TVInstalledVehicleClient", playersource, vehicleNetId)
                else
                    TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].vehiclenotowned)
                end
            end
        )
    end)
end

-- ── Sync all active TVs to a newly connected player ───────────────────────────

RegisterNetEvent("rtx_tv:Synchronize")
AddEventHandler("rtx_tv:Synchronize", function()
    local playersource = source
    for _, tvData in ipairs(Config.TVs) do
        TriggerClientEvent("rtx_tv:CreateNewTV", playersource,
            tvData.id, tvData.coords, tvData.tvobjectdataid,
            tvData.tvvehicle, tvData.tvvehiclenetworkid,
            tvData.tvvolume, tvData.tvmainmenu,
            tvData.tvurltype, tvData.tvurl,
            tvData.tvroutingbucket
        )
    end
end)

-- ── Add / open a static TV ─────────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:AddNewTV")
AddEventHandler("rtx_tv:AddNewTV", function(objectDataId, coords)
    local playersource  = source
    local routingBucket = GetPlayerInstanceId(playersource)

    if not GetPlayerPermissionsControl(playersource) then return end

    local existingIndex = CheckTvData(coords, routingBucket)

    local function OpenMenuForPlayer(tvData)
        tvData.taken         = true
        tvData.takenplayerid = playersource
        TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, tvData.tvurlnoncutted, tvData.tvurltype, tvData.tvvolume)
    end

    local function CreateNewTVEntry()
        local newTvId = GenerateTVId()
        CreateAndBroadcastTV(newTvId, coords, objectDataId, false, nil, 50, true, "", "", routingBucket, playersource)
        TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, "", "", 50)
    end

    if existingIndex ~= nil then
        local tvData = Config.TVs[existingIndex]
        if tvData.taken then return end

        if not Config.TelevisionPermissions then
            OpenMenuForPlayer(tvData)
        else
            local isPermLocation, permIndex = CheckPermissionTvs(coords)
            if not isPermLocation then
                OpenMenuForPlayer(tvData)
            elseif GetPlayerPermissionsControlTV(playersource, permIndex) then
                OpenMenuForPlayer(tvData)
            else
                TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].nopermission)
            end
        end
    else
        if not Config.TelevisionPermissions then
            CreateNewTVEntry()
        else
            local isPermLocation, permIndex = CheckPermissionTvs(coords)
            if not isPermLocation then
                CreateNewTVEntry()
            elseif GetPlayerPermissionsControlTV(playersource, permIndex) then
                CreateNewTVEntry()
            else
                TriggerClientEvent("rtx_tv:Notify", playersource, Language[Config.Language].nopermission)
            end
        end
    end
end)

-- ── Add / open a vehicle TV ────────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:AddNewTVVehicle")
AddEventHandler("rtx_tv:AddNewTVVehicle", function(vehicleNetId)
    local playersource = source

    if not GetPlayerPermissionsControl(playersource) then return end

    local vehicleEntity = NetworkGetEntityFromNetworkId(vehicleNetId)
    if not DoesEntityExist(vehicleEntity) then return end

    local existingIndex = CheckTvVehicleData(vehicleNetId)
    if existingIndex ~= nil then
        local tvData = Config.TVs[existingIndex]
        if not tvData.taken then
            tvData.taken         = true
            tvData.takenplayerid = playersource
            TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, tvData.tvurlnoncutted, tvData.tvurltype, tvData.tvvolume)
        end
    else
        local newTvId = GenerateTVId()
        -- ⚠️ tvobjectdataid is nil for vehicle TVs — the client render loop uses tvvehiclenetworkid instead
        CreateAndBroadcastTV(newTvId, nil, nil, true, vehicleNetId, 50, true, "", "", 0, playersource)
        TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, "", "", 50)
    end
end)

-- ── Play video on a TV ─────────────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:PlayVideo")
AddEventHandler("rtx_tv:PlayVideo", function(tvId, _, _, rawUrl)
    local playersource = source

    if not GetPlayerPermissionsControl(playersource) then return end

    local tvIndex = CheckTvDataID(tvId)
    if tvIndex == nil then return end

    local tvData = Config.TVs[tvIndex]

    -- Re-validate the URL server-side; never trust platform/identifier from the client.
    local isValid, validatedPlatform, validatedIdentifier = ParseVideoUrl(rawUrl)
    if not isValid then return end

    if Config.TelevisionWebhook == true then
        TelevisionWebhook(playersource, rawUrl)
    end

    local function CanPlayerControl()
        if not tvData.taken then return false end
        return tvData.takenplayerid == playersource
    end

    local function CommitPlay()
        tvData.tvmainmenu     = false
        tvData.tvurltype      = validatedPlatform
        tvData.tvurl          = validatedIdentifier
        tvData.tvurlnoncutted = rawUrl
        tvData.videostarttime = os.time()
        TriggerClientEvent("rtx_tv:PlayVideoClient", -1, tvId, validatedPlatform, validatedIdentifier)
        TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, tvData.tvurlnoncutted, tvData.tvurltype, tvData.tvvolume)
    end

    if tvData.tvvehicle then
        local vehicleEntity = NetworkGetEntityFromNetworkId(tvData.tvvehiclenetworkid)
        if not DoesEntityExist(vehicleEntity) then return end
        if CanPlayerControl() then CommitPlay() end
    else
        if CanPlayerControl() then CommitPlay() end
    end
end)

-- ── Server video callbacks ─────────────────────────────────────────────────────

RTXTV.RegisterServerCallback("rtx_tv:GetCurrentVideoTime", function(playersource, cb, tvId)
    local tvIndex = CheckTvDataID(tvId)
    if tvIndex ~= nil then
        local elapsed = os.time() - Config.TVs[tvIndex].videostarttime
        cb(elapsed)
    else
        cb(0)
    end
end)

-- ── Volume ─────────────────────────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:ChangeVolume")
AddEventHandler("rtx_tv:ChangeVolume", function(tvId, newVolume)
    local playersource = source
    if newVolume < 0 or newVolume > 100 then return end

    local tvIndex = CheckTvDataID(tvId)
    if tvIndex == nil then return end

    local tvData = Config.TVs[tvIndex]

    local function CanPlayerControl()
        if not tvData.taken then return false end
        return tvData.takenplayerid == playersource
    end

    local function CommitVolumeChange()
        tvData.tvvolume = newVolume
        TriggerClientEvent("rtx_tv:ChangeVolumeClient", -1, tvId, newVolume)
        TriggerClientEvent("rtx_tv:OpenTVMenu", playersource, tvData.tvurlnoncutted, tvData.tvurltype, tvData.tvvolume)
    end

    if tvData.tvvehicle then
        local vehicleEntity = NetworkGetEntityFromNetworkId(tvData.tvvehiclenetworkid)
        if DoesEntityExist(vehicleEntity) and CanPlayerControl() then
            CommitVolumeChange()
        end
    else
        if CanPlayerControl() then
            CommitVolumeChange()
        end
    end
end)

-- ── Close (release lock) ───────────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:CloseTV")
AddEventHandler("rtx_tv:CloseTV", function(tvId)
    local playersource = source
    local tvIndex = CheckTvDataID(tvId)
    if tvIndex == nil then return end

    local tvData = Config.TVs[tvIndex]
    if tvData.taken and tvData.takenplayerid == playersource then
        tvData.taken         = false
        tvData.takenplayerid = nil
    end
end)

-- ── Turn off (remove TV entry) ─────────────────────────────────────────────────

RegisterNetEvent("rtx_tv:TurnOffTV")
AddEventHandler("rtx_tv:TurnOffTV", function(tvId)
    local playersource = source
    local tvIndex = CheckTvDataID(tvId)
    if tvIndex == nil then return end

    local tvData = Config.TVs[tvIndex]
    if tvData.taken and tvData.takenplayerid == playersource then
        tvData.taken         = false
        tvData.takenplayerid = nil
        TriggerClientEvent("rtx_tv:TurnOffTVClient", -1, tvId)
        table.remove(Config.TVs, tvIndex)
    end
end)

-- ── Player disconnect cleanup ──────────────────────────────────────────────────

AddEventHandler("playerDropped", function()
    local playersource = source
    for _, tvData in ipairs(Config.TVs) do
        if tvData.taken and tvData.takenplayerid == playersource then
            tvData.taken         = false
            tvData.takenplayerid = nil
        end
    end
end)

-- ── Routing bucket sync thread ─────────────────────────────────────────────────

if Config.EnableRoutingBucketTv then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(5000)
            for _, playerId in ipairs(GetPlayers()) do
                GlobalState["rtxtv-" .. playerId .. "-routing"] = GetPlayerRoutingBucket(playerId)
            end
        end
    end)
end

-- ── Export API (control TVs from other scripts) ────────────────────────────────

-- StartTelevision(coords, objectDataId, volume, routingBucket, taken) → bool
function StartTelevision(coords, objectDataId, volume, routingBucket, taken)
    local existingIndex = CheckTvData(coords, routingBucket)
    if existingIndex ~= nil then
        Config.TVs[existingIndex].taken = taken
        return true
    end

    local newTvId = GenerateTVId()
    CreateAndBroadcastTV(newTvId, coords, objectDataId, false, nil, volume, true, "", "", routingBucket, nil)
    Config.TVs[#Config.TVs].taken = taken
    return true
end

-- PlayVideoOnTelevision(coords, routingBucket, rawUrl) → bool
function PlayVideoOnTelevision(coords, routingBucket, rawUrl)
    local tvIndex = CheckTvData(coords, routingBucket)
    if tvIndex == nil then return false end

    local tvData     = Config.TVs[tvIndex]
    local url        = tostring(rawUrl)
    local isValid, platform, identifier = ParseVideoUrl(url)

    if not isValid then return false end

    if platform == "bilibili" then
        ResolveBilibiliAndStore(tvData, identifier)
    end

    tvData.tvmainmenu     = false
    tvData.tvurltype      = platform
    tvData.tvurl          = identifier
    tvData.tvurlnoncutted = url
    tvData.videostarttime = os.time()
    TriggerClientEvent("rtx_tv:PlayVideoClient", -1, tvData.id, platform, identifier)
    return true
end

-- ChangeVolumeTelevision(coords, newVolume, routingBucket)
function ChangeVolumeTelevision(coords, newVolume, routingBucket)
    if newVolume < 0 or newVolume > 100 then return false end
    local tvIndex = CheckTvData(coords, routingBucket)
    if tvIndex == nil then return false end

    local tvData = Config.TVs[tvIndex]
    tvData.tvvolume = newVolume
    TriggerClientEvent("rtx_tv:ChangeVolumeClient", -1, tvData.id, newVolume)
end

-- StopTelevision(coords, routingBucket)
function StopTelevision(coords, routingBucket)
    local tvIndex = CheckTvData(coords, routingBucket)
    if tvIndex == nil then return false end

    local tvData         = Config.TVs[tvIndex]
    tvData.taken         = false
    tvData.takenplayerid = nil
    TriggerClientEvent("rtx_tv:TurnOffTVClient", -1, tvData.id)
    table.remove(Config.TVs, tvIndex)
end

-- ── Startup message ────────────────────────────────────────────────────────────

function authorized()
    print("[RTX TV] - Thank you for choosing us - Discord: https://discord.gg/P6KdaDpgAk Store: https://rtx.tebex.io")
end

Citizen.CreateThread(function()
    authorized()
end)