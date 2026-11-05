RTXTV                  = {}
RTXTV.CurrentRequestId = 0
RTXTV.ServerCallbacks  = {}

function RTXTV.TriggerServerCallback(eventName, callback, ...)
    RTXTV.ServerCallbacks[RTXTV.CurrentRequestId] = callback
    TriggerServerEvent("RTXTV:triggerServerCallback", eventName, RTXTV.CurrentRequestId, ...)
    if RTXTV.CurrentRequestId < 65535 then
        RTXTV.CurrentRequestId = RTXTV.CurrentRequestId + 1
    else
        RTXTV.CurrentRequestId = 0
    end
end

RegisterNetEvent("RTXTV:serverCallback")
AddEventHandler("RTXTV:serverCallback", function(requestId, ...)
    RTXTV.ServerCallbacks[requestId](...)
    RTXTV.ServerCallbacks[requestId] = nil
end)

local isNearTV              = false  -- true when the player is within range of an active TV
local activeTVIndex         = nil    -- Config.TVs index for the currently controlled TV
local vehicleNetworkTVs     = {}     -- networkId → panel prop entries for vehicle TVs
local vehicleItemCheckCache = {}     -- netId → pending/result cache for server-side vehicle TV ownership check
local isNUIOpen             = false  -- TV control NUI is currently visible
local isEditorOpen          = false  -- TV offset editor NUI is currently visible
local speedSettingIndex     = 1      -- active index into SpeedSettings (used by tvcreator)
local isMuted               = false  -- streamer mode: suppress all TV audio
local tvTurnOffPending      = {}     -- tvId → true when a TurnOff is in progress for that TV
local videoStartTimeCache = 0  -- cached videostarttime used for preset TVs (set by server sync)
local closestTVDist       = -1

local SpeedSettings = {
    { speeddata = 0.001 },
    { speeddata = 0.002 },
    { speeddata = 0.005 },
    { speeddata = 0.01  },
}

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

local stripURLPrefix = function(url, prefixes)
    for _, entry in ipairs(prefixes) do
        if string.find(url, entry.pattern) then
            return string.sub(url, entry.offset)
        end
    end
    return nil
end

local extractYouTubeID = function(url, prefixes)
    local suffix = stripURLPrefix(url, prefixes)
    if suffix then return string.sub(suffix, 1, 11) end
    return nil
end

local hasValidURLScheme = function(url)
    local result = string.find(url, "^www.")
    if not result then
        result = string.find(url, "^http")
        if not result then
            result = string.find(url, "^https")
        end
    end
    return result
end

function CreateTargets()
    for tvIndex, tvObj in ipairs(Config.TelevisionObjects) do
        if tvObj.object == nil then goto continue end

        local targetType = Config.Targettype

        if targetType == "qtarget" or targetType == "qbtarget" then
            local systemName = Config.TargetSystemsNames[targetType]
            local models     = { GetHashKey(tvObj.object) }
            local option     = {
                name  = "rtxtv-" .. tvIndex,
                event = "rtx_tv:ControlTVTarget",
                icon  = Config.TargetIcons.tvicon,
                label = Language[Config.Language].controltv,
            }
            exports[systemName]:AddTargetModel(models, { options = { option }, distance = tvObj.maxcontroldistance })

        elseif targetType == "oxtarget" then
            local systemName = Config.TargetSystemsNames.oxtarget
            local modelHash  = GetHashKey(tvObj.object)
            local option     = {
                name  = "rtxtv-" .. tvIndex,
                event = "rtx_tv:ControlTVTarget",
                icon  = Config.TargetIcons.tvicon,
                label = Language[Config.Language].controltv,
            }
            exports[systemName]:addModel(modelHash, { option })
        end

        ::continue::
    end
end

function CheckTVLocation(playerPos)
    local isFound      = false
    local minDist      = -1
    local closestIndex = nil
    local closestCoords = nil

    for tvIndex, tvObj in ipairs(Config.TelevisionObjects) do
        local dist, coords

        if tvObj.rendertarget == false then
            if tvObj.nonobject == true then
                local delta = playerPos - tvObj.nonobjectcoords
                dist   = #delta
                coords = tvObj.nonobjectcoords
                if dist < tvObj.maxcontroldistance and (minDist == -1 or minDist > dist) then
                    minDist      = dist
                    isFound      = true
                    closestIndex = tvIndex
                    closestCoords = coords
                end
            else
                local entity = GetClosestObjectOfType(playerPos, tvObj.maxcontroldistance, GetHashKey(tvObj.object))
                if DoesEntityExist(entity) then
                    coords = GetEntityCoords(entity)
                    dist   = #(playerPos - coords)
                    if dist < tvObj.maxcontroldistance and (minDist == -1 or minDist > dist) then
                        minDist      = dist
                        isFound      = true
                        closestIndex = tvIndex
                        closestCoords = coords
                    end
                end
            end
        else
            local entity = GetClosestObjectOfType(playerPos, tvObj.maxcontroldistance, GetHashKey(tvObj.object))
            if DoesEntityExist(entity) then
                coords = GetEntityCoords(entity)
                dist   = #(playerPos - coords)
                if dist < tvObj.maxcontroldistance and (minDist == -1 or minDist > dist) then
                    minDist      = dist
                    isFound      = true
                    closestIndex = tvIndex
                    closestCoords = coords
                end
            end
        end
    end

    return isFound, closestIndex, closestCoords
end

function IsPlayerBehindWall(playerPed, tvEntity)
    if Config.EnableTvInSameRoomOnly == true then
        return HasEntityClearLosToEntity(playerPed, tvEntity, 17)
    end
    return true
end

function CheckVideoUrl(url)
    local platform   = ""
    local identifier = ""
    local isValid    = false

    if string.find(url, "youtube.com") then
        platform = "youtube"
        local videoId = extractYouTubeID(url, YOUTUBE_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "youtu.be") then
        platform = "youtube"
        local videoId = extractYouTubeID(url, YOUTU_BE_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "twitch.tv") then
        platform = "twitch"
        local channel = stripURLPrefix(url, TWITCH_PREFIXES)
        if channel then identifier = channel; isValid = true end

    elseif string.find(url, "streamable.com") then
        platform = "streamable"
        local code = stripURLPrefix(url, STREAMABLE_PREFIXES)
        if code then identifier = code; isValid = true end

    elseif string.find(url, "facebook.com") then
        platform = "facebook"
        local videoId = stripURLPrefix(url, FACEBOOK_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "dailymotion.com") then
        platform = "dailymotion"
        local videoId = stripURLPrefix(url, DAILYMOTION_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "vimeo.com") then
        platform = "vimeo"
        local videoId = stripURLPrefix(url, VIMEO_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "bilibili.com") then
        platform = "bilibili"
        local videoId = stripURLPrefix(url, BILIBILI_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "huya.com") then
        platform = "huya"
        local channelId = stripURLPrefix(url, HUYA_PREFIXES)
        if channelId then identifier = channelId; isValid = true end

    elseif string.find(url, "aparat.com") then
        platform = "aparat"
        local videoId = stripURLPrefix(url, APARAT_PREFIXES)
        if videoId then identifier = videoId; isValid = true end

    elseif string.find(url, "soundcloud.com") then
        platform = "soundcloud"
        local trackPath = stripURLPrefix(url, SOUNDCLOUD_PREFIXES)
        if trackPath then identifier = trackPath; isValid = true end

    elseif string.find(url, "kick.com") then
        platform = "kick"
        local channelId = stripURLPrefix(url, KICK_PREFIXES)
        if channelId then identifier = channelId; isValid = true end

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

    else
        platform = "website"; identifier = url; isValid = true
    end

    if isValid then
        return true, platform, identifier
    end
    return false
end

function IsTVPresetFree(presetIndex)
    local presetId = "preset-" .. presetIndex
    for _, tvEntry in pairs(Config.TVs) do
        if tvEntry.id == presetId then return false end
    end
    return true
end

function CreateTVPresets()
    for presetIndex, preset in ipairs(Config.TelevisionPresetsLocations) do
        local found, tvObjectDataId, tvCoords = CheckTVLocation(preset.coords)
        if not found then goto continue end

        local isValid, urlType, urlId = CheckVideoUrl(preset.url)
        if not isValid then goto continue end

        if IsTVPresetFree(presetIndex) then
            table.insert(Config.TVs, {
                id                = "preset-" .. presetIndex,
                coords            = tvCoords,
                taken             = true,
                takenplayerid     = 0,
                tvobjectdataid    = tvObjectDataId,
                tvmainmenu        = false,
                tvurltype         = urlType,
                tvurl             = urlId,
                tvtime            = 0,
                tvvolume          = 0,
                tvduration        = nil,
                duihandler        = nil,
                tvvehicle         = false,
                tvvehiclenetworkid = nil,
                waitingforyt      = false,
                tvroutingbucket   = 0,
                preset            = true,
            })
        end

        ::continue::
    end
end

if Config.TelevisionPresets == true then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(500)
            CreateTVPresets()
        end
    end)
end

function CheckIfTvIsNotPresset(coords)
    for _, tvEntry in ipairs(Config.TVs) do
        if tvEntry.preset == true then
            local delta = tvEntry.coords - coords
            if #delta < 0.1 then return true end
        end
    end
    return false
end

function CheckTvData(tvId)
    for index, tvEntry in ipairs(Config.TVs) do
        if tvEntry.id == tvId then return index end
    end
    return nil
end

local tvSystemInitialized = false

function InitializeTv()
    if tvSystemInitialized then return end
    tvSystemInitialized = true

    SendNUIMessage({
        message              = "updateinterfacedata",
        interfacecolordata   = Config.InterfaceColor,
        televisionresouredata = tostring(GetCurrentResourceName()),
    })

    TriggerServerEvent("rtx_tv:Synchronize")

    if Config.TelevisionPresets then
        CreateTVPresets()
    end

    if Config.Target == true then
        CreateTargets()
    end
end

AddEventHandler("playerSpawned", function()
    Citizen.CreateThread(function()
        Citizen.Wait(2000)
        InitializeTv()
    end)
end)

AddEventHandler("onClientResourceStart", function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    Citizen.CreateThread(function()
        while true do
            if NetworkIsPlayerActive(PlayerId()) and DoesEntityExist(PlayerPedId()) then
                break
            end
            Citizen.Wait(500)
        end
        Citizen.Wait(1000)
        InitializeTv()
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if NetworkIsSessionStarted() then
            SendNUIMessage({
                message               = "updateinterfacedata",
                interfacecolordata    = Config.InterfaceColor,
                televisionresouredata = tostring(GetCurrentResourceName()),
            })
        end
    end
end)

function GenerateTextureName()
    local result = ""
    for _ = 1, 25 do
        result = result .. string.char(math.random(97, 122))
    end
    return result
end

function CheckVehicle(vehicleEntity)
    local modelHash    = GetEntityModel(vehicleEntity)
    local tvAvailable  = false

    if Config.VehicleTelevisionForEveryVehicle then
        tvAvailable = true
    else
        for _, vehicleEntry in ipairs(Config.TelevisonVehicles) do
            if GetHashKey(vehicleEntry.vehiclename) == modelHash then
                tvAvailable = true
                break
            end
        end
    end

    if Config.VehicleTelevisionoForOnlySpecifiedTypeOfVehicle then
        local vehicleClass = GetVehicleClass(vehicleEntity)
        local classSetting = Config.TelevisonVehiclesClasses[vehicleClass]
        if classSetting ~= nil then
            tvAvailable = (classSetting == true)
        end
    end

    if Config.VehicleTelevisionBlacklist then
        for _, blacklistEntry in ipairs(Config.TelevisonBlacklistedVehicles) do
            if GetHashKey(blacklistEntry.vehiclename) == modelHash then
                tvAvailable = false
                break
            end
        end
    end

    return tvAvailable
end

function CheckVehicleOffsets(vehicleModel)
    for index, offsetEntry in ipairs(Config.TelevisonVehiclesOffsets) do
        if GetHashKey(offsetEntry.vehiclename) == vehicleModel then
            return true, index
        end
    end
    return false, nil
end

function RenderTargetTelevision(targetName, modelHash)
    local renderId = 0
    if not IsNamedRendertargetRegistered(targetName) then
        RegisterNamedRendertarget(targetName, 0)
    end
    if not IsNamedRendertargetLinked(modelHash) then
        LinkNamedRendertarget(modelHash)
    end
    if IsNamedRendertargetRegistered(targetName) then
        renderId = GetNamedRendertargetRenderId(targetName)
    end
    return renderId
end

function CreateNamedRenderTargetForModel(targetName, modelHash)
    local renderId = 0
    if not IsNamedRendertargetRegistered(targetName) then
        RegisterNamedRendertarget(targetName, 0)
    end
    if not IsNamedRendertargetLinked(modelHash) then
        LinkNamedRendertarget(modelHash)
    end
    if IsNamedRendertargetRegistered(targetName) then
        renderId = GetNamedRendertargetRenderId(targetName)
    end
    return renderId
end

function loadScaleform(scaleformName)
    local handle = RequestScaleformMovie(scaleformName)
    while not HasScaleformMovieLoaded(handle) do
        handle = RequestScaleformMovie(scaleformName)
        Citizen.Wait(0)
    end
    return handle
end

function RenderScaleformTelevision(renderId, txdDict, txdName)
    SetTextRenderId(renderId)
    Set_2dLayer(4)
    SetScriptGfxDrawBehindPausemenu(1)
    DrawSprite("rtxtv_d", "rtxtv_txd", 0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    DrawSprite(txdDict, txdName,       0.5, 0.5, 1.0, 1.0, 0.0, 255, 255, 255, 255)
    SetTextRenderId(GetDefaultScriptRendertargetRenderId())
    SetScriptGfxDrawBehindPausemenu(0)
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

function PlateReformat(str)
    if str then
        return string.gsub(str, "^%s*(.-)%s*$", "%1")
    end
    return ""
end

function ScreenReformating(platform, identifier, startTime, aid, cid)
    local resourceName = GetCurrentResourceName()

    if platform == "youtube" then
        return "https://cfx-nui-" .. resourceName .. "/html/video.html"

    elseif platform == "twitch" then
        return "https://player.twitch.tv/?channel=" .. identifier .. "&parent=streamernews.example.com&autoplay=true"

    elseif platform == "streamable" then
        return "https://streamable.com/e/" .. identifier .. "?autoplay=1&t=" .. startTime

    elseif platform == "facebook" then
        return "https://www.facebook.com/plugins/video.php?&href=https%3A%2F%2Fwww.facebook.com%2F105100294421568%2Fvideos%2F" .. identifier .. "%2F&t=" .. startTime

    elseif platform == "dailymotion" then
        return "https://www.dailymotion.com/embed/video/" .. identifier .. "?autoplay=1&start=" .. startTime

    elseif platform == "vimeo" then
        return "https://player.vimeo.com/video/" .. identifier .. "?autoplay=1#t=" .. startTime .. "s"

    elseif platform == "bilibili" then
        return string.format("https://player.bilibili.com/player.html?aid=%s&bvid=%s&cid=%s&autoplay=1&t=%s", aid, identifier, cid, startTime)

    elseif platform == "huya" then
        return "https://liveshare.huya.com/iframe/" .. identifier .. "&page=1&high_quality=1&as_wide=1&autoplay=1"

    elseif platform == "aparat" then
        return "https://www.aparat.com/video/video/embed/videohash/" .. identifier .. "/vt/frame?startTime=" .. startTime .. "&autoplay=true"

    elseif platform == "soundcloud" then
        local timeFormatted = math.floor(startTime / 60) .. ":" .. (startTime % 60)
        return "https://soundcloud.com/" .. identifier .. "#t=" .. timeFormatted

    elseif platform == "kick" then
        return "https://player.kick.com/" .. identifier .. "?autoplay=true&muted=false"

    elseif platform == "folder" then
        local videoEntry = Config.VideoList[identifier]
        local videoUrl   = "https://cfx-nui-" .. resourceName .. "/html/videos/" .. videoEntry.filename
        return videoUrl .. "#t=" .. startTime

    elseif platform == "mp4" or platform == "mp3" then
        return identifier .. "#t=" .. startTime

    elseif platform == "png" or platform == "gif" or platform == "jpg" or platform == "website" then
        return identifier
    end

    return ""
end

function ChangeVideoVolume(tvIndex, volume)
    local tvData     = Config.TVs[tvIndex]
    local urlType    = tvData.tvurltype
    local duiHandler = tvData.duihandler

    if duiHandler == nil or not IsDuiAvailable(duiHandler) then return end

    if urlType == "youtube" then
        SendDuiMessage(duiHandler, json.encode({ message = "updatevolume", videovolume = volume }))

    elseif urlType == "streamable" then
        local sliderX = 75 + math.ceil(tonumber(volume) * 39 / 100 + 1)
        SendDuiMouseMove(duiHandler, 75, 700)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 700)
        Citizen.Wait(5)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 800)

    elseif urlType == "folder" or urlType == "mp4" then
        local sliderX = 1088 + math.ceil(tonumber(volume) * 46 / 100 + 1)
        SendDuiMouseMove(duiHandler, 1162, 689)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, 1162, 689)
        Citizen.Wait(500)
        SendDuiMouseMove(duiHandler, sliderX, 689)
        Citizen.Wait(5)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 800)

    elseif urlType == "mp3" then
        local sliderX = 668 + math.ceil(tonumber(volume) * 46 / 100 + 1)
        SendDuiMouseMove(duiHandler, 740, 422)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, 740, 422)
        Citizen.Wait(500)
        SendDuiMouseMove(duiHandler, sliderX, 422)
        Citizen.Wait(5)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 800)

    elseif urlType == "dailymotion" then
        local sliderX = 1155 + math.ceil(tonumber(volume) * 99 / 100 + 1)
        SendDuiMouseMove(duiHandler, 1150, 702)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, 1150, 702)
        Citizen.Wait(500)
        SendDuiMouseMove(duiHandler, sliderX, 702)
        Citizen.Wait(5)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 750)

    elseif urlType == "twitch" then
        local sliderX = 70 + math.ceil(tonumber(volume) * 99 / 100 + 6)
        SendDuiMouseMove(duiHandler, sliderX, 690)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 690)
        Citizen.Wait(250)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 750)

    elseif urlType == "vimeo" then
        local sliderX = 1120 + math.ceil(tonumber(volume) * 21 / 100 + 1)
        SendDuiMouseMove(duiHandler, sliderX, 698)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 698)
        Citizen.Wait(250)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(7)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, sliderX, 750)

    elseif urlType == "soundcloud" then
        local sliderY = 670 - math.ceil(tonumber(volume) * 99 / 100 + 1)
        SendDuiMouseMove(duiHandler, 870, 675)
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, 870, 675)
        Citizen.Wait(500)
        SendDuiMouseMove(duiHandler, 870, sliderY)
        Citizen.Wait(5)
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(5)
        SendDuiMouseUp(duiHandler, "left")
        Citizen.Wait(250)
        SendDuiMouseMove(duiHandler, 870, 750)
    end
end

function GetUrlTypeLabel(platform)
    local labels = {
        youtube     = "YouTube",
        streamable  = "Streamable",
        folder      = "CUSTOM",
        mp4         = "MP4",
        mp3         = "MP3",
        dailymotion = "DailyMotion",
        twitch      = "Twitch",
        vimeo       = "Vimeo",
        bilibili    = "Bilibili",
        huya        = "Huya",
        aparat      = "Aparat",
        soundcloud  = "SoundCloud",
        kick        = "Kick",
        facebook    = "Facebook",
        png         = "Image",
        gif         = "Image",
        jpg         = "Image",
        website     = "Website",
    }
    return labels[platform] or ""
end

function DrawText3D(x, y, z, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)

    if not onScreen then return end

    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry("STRING")
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(screenX, screenY)

    local bgWidth = string.len(text) / 240
    DrawRect(
        screenX, screenY + 0.0125,
        0.015 + bgWidth, 0.03,
        Config.EditorColor.r, Config.EditorColor.g, Config.EditorColor.b, 150
    )
end

function HasVehicleTV(vehicleEntity)
    if not DoesEntityExist(vehicleEntity) then return false end
    if NetworkGetEntityIsNetworked(vehicleEntity) then
        local netId = NetworkGetNetworkIdFromEntity(vehicleEntity)
        if vehicleNetworkTVs[netId] ~= nil then return true end
    end
    return false
end

function OnlyOwnedVehiclesAllowed()
    if not Config.VehicleTelevisionItem then return false end
    local framework = Config.Framework
    if framework == "qbcore" or framework == "esx" or framework == "custom" then
        return true
    end
    return false
end

RegisterNUICallback("playvideo", function(data, cb)
    if activeTVIndex == nil then cb("ok"); return end

    local tvData   = Config.TVs[activeTVIndex]
    local url      = tostring(data.videourldata)
    local platform = ""
    local identifier = ""
    local isValid  = false
    local alreadyNotified = false  -- ✅ declarado aquí arriba para que sea accesible en todo el callback

    local isFolderVideo, folderKey = CheckIfVideoIsAllowed(url)

    if isFolderVideo then
        platform   = "folder"
        identifier = tostring(folderKey)
        isValid    = true

    elseif string.find(url, "youtube.com") then
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

    else
        if Config.EnableWebsitesForTv then
            local isBlacklisted = false
            for _, blacklistedDomain in pairs(Config.BlacklistedWebsites) do
                if string.match(string.lower(url), string.lower(blacklistedDomain)) then
                    isBlacklisted = true
                end
            end
            if isBlacklisted then
                isValid = false
                alreadyNotified = true
                Notify(Language[Config.Language].notsupported)
            else
                platform = "website"; identifier = url; isValid = true
            end
        else
            isValid = false
        end
    end  -- ✅ solo un end para cerrar el if/elseif/else principal

    -- Bloque de imágenes deshabilitadas
    if Config.EnableImagesForTv == false and (platform == "png" or platform == "gif" or platform == "jpg") then
        isValid = false
        if not alreadyNotified then
            alreadyNotified = true
            Notify(Language[Config.Language].notsupported)
        end
    end

    -- Bloque final
    if isValid then
        TriggerServerEvent("rtx_tv:PlayVideo", tvData.id, platform, identifier, url)
    elseif not alreadyNotified then
        Notify(Language[Config.Language].notsupported)
    end

    cb("ok")
end)

RegisterNUICallback("volumechange", function(data, cb)
    if activeTVIndex ~= nil then
        local tvData = Config.TVs[activeTVIndex]
        local volume = tonumber(data.volumedata)
        if volume and volume >= 0 and volume <= 100 then
            TriggerServerEvent("rtx_tv:ChangeVolume", tvData.id, volume)
        end
    end
    cb("ok")
end)

RegisterNUICallback("quit", function(data, cb)
    if activeTVIndex ~= nil then
        local tvData = Config.TVs[activeTVIndex]
        SetNuiFocus(false, false)
        isNUIOpen = false
        SendNUIMessage({ message = "hide" })
        TriggerServerEvent("rtx_tv:CloseTV", tvData.id)
        DisableIdleCamera(false)
    end

    if isEditorOpen == true then
        SetNuiFocus(false, false)
        isEditorOpen = false
        SendNUIMessage({ message = "hide" })
    end

    cb("ok")
end)

RegisterNUICallback("turnoff", function(data, cb)
    if activeTVIndex ~= nil then
        local tvData = Config.TVs[activeTVIndex]
        SetNuiFocus(false, false)
        isNUIOpen = false
        SendNUIMessage({ message = "hide" })
        TriggerServerEvent("rtx_tv:TurnOffTV", tvData.id)
    end
    cb("ok")
end)

RegisterNUICallback("readyyt", function(data, cb)
    if activeTVIndex ~= nil then
        local tvData = Config.TVs[activeTVIndex]

        if tvData.waitingforyt == true then
            tvData.waitingforyt = false

            RTXTV.TriggerServerCallback("rtx_tv:GetCurrentVideoTime", function(currentTime)
                if tvData.duihandler ~= nil and IsDuiAvailable(tvData.duihandler) then
                    local payload = {
                        message      = "playvideo",
                        videoid      = tvData.tvurl,
                        videoseconds = currentTime,
                        videovolume  = isMuted and 0 or tvData.tvvolume,
                    }
                    SendDuiMessage(tvData.duihandler, json.encode(payload))
                end
            end, tvData.id)
        end
    end

    cb("ok")
end)

local TV_PANEL_MODEL = "xm_prop_x17_sec_panel_01"
local TV_PANEL_RENDER_TARGET = "prop_x17_p_01"

function LoadModelAsync(modelHash)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        RequestModel(modelHash)
        Citizen.Wait(5)
    end
end

function GetPlayerRoutingBucket()
    if not Config.EnableRoutingBucketTv then return 0 end
    local serverId = GetPlayerServerId(PlayerId())
    return GlobalState["rtxtv-" .. serverId .. "-routing"] or 0
end

function SpawnAndAttachTVPanel(vehicleEntity, offsetConfig)
    local vehicleCoords = GetEntityCoords(vehicleEntity)
    local panelHash     = GetHashKey(TV_PANEL_MODEL)
    LoadModelAsync(panelHash)

    local prop = CreateObjectNoOffset(panelHash, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, false, true, true)

    SetEntityCollision(prop, false)
    FreezeEntityPosition(prop, true)

    local boneIndex = GetEntityBoneIndexByName(vehicleEntity, offsetConfig.vehiclebone)
    if boneIndex then
        AttachEntityToEntity(
            prop, vehicleEntity, 0,
            offsetConfig.offsetx, offsetConfig.offsety, offsetConfig.offsetz,
            offsetConfig.rotation.x, offsetConfig.rotation.y, offsetConfig.rotation.z,
            false, false, false, false, 2, true
        )
    end

    return prop
end


function BuildVehicleTVEntries(vehicleEntity, vehicleModelHash)
    local entries = {}
    local hasOffsets, offsetIndex = CheckVehicleOffsets(vehicleModelHash)

    if hasOffsets then
        local offsetData = Config.TelevisonVehiclesOffsets[offsetIndex]
        for tvSlotIndex, tvSlotConfig in ipairs(offsetData.televisions) do
            local prop = SpawnAndAttachTVPanel(vehicleEntity, tvSlotConfig)
            table.insert(entries, {
                handler            = prop,
                vehicletvid        = tvSlotIndex,
                vehicletvoffsetid  = offsetIndex,
            })
        end
    else
        local defaultOffset = Config.TelevisonVehiclesOffsetsDefault
        local prop = SpawnAndAttachTVPanel(vehicleEntity, defaultOffset)
        table.insert(entries, {
            handler     = prop,
            vehicletvid = "default",
        })
    end

    return entries
end

function RebuildMissingVehicleHandlers(vehicleEntity, networkId)
    for _, tvSlot in ipairs(vehicleNetworkTVs[networkId]) do
        if not DoesEntityExist(tvSlot.handler) then
            local offsetConfig
            if tvSlot.vehicletvid == "default" then
                offsetConfig = Config.TelevisonVehiclesOffsetsDefault
            else
                -- ⚠️ Original accesses .vehicletvhandler.vehicletvid — likely a decompiler artifact;
                --    the actual intent seems to be fetching the offset by vehicletvoffsetid
                offsetConfig = Config.TelevisonVehiclesOffsets[tvSlot.vehicletvoffsetid]
            end

            local prop = SpawnAndAttachTVPanel(vehicleEntity, offsetConfig)
            tvSlot.handler = prop
        end
    end
end

function SetVehicleTVHandlersVisible(networkId, visible)
    if vehicleNetworkTVs[networkId] == nil then return end
    for _, tvSlot in ipairs(vehicleNetworkTVs[networkId]) do
        if DoesEntityExist(tvSlot.handler) then
            SetEntityVisible(tvSlot.handler, visible, 0)
        end
    end
end

function DestroyVehicleTVEntry(networkId)
    if vehicleNetworkTVs[networkId] == nil then return end
    for _, tvSlot in ipairs(vehicleNetworkTVs[networkId]) do
        if DoesEntityExist(tvSlot.handler) then
            DeleteEntity(tvSlot.handler)
        end
    end
    vehicleNetworkTVs[networkId] = nil
end

function ApplyPlatformDuiWorkaround(duiHandler, platform)
    if platform == "twitch" then
        for y = 440, 500, 5 do
            SendDuiMouseMove(duiHandler, 550, y)
            Wait(100)
            SendDuiMouseDown(duiHandler, "left")
            Wait(10)
            SendDuiMouseUp(duiHandler, "left")
            Wait(300)
        end

    elseif platform == "facebook" then
        for _, yPos in ipairs({ 50, 100, 150 }) do
            SendDuiMouseMove(duiHandler, 620, yPos)
            Citizen.Wait(100)
            SendDuiMouseDown(duiHandler, "left")
            Citizen.Wait(5)
            SendDuiMouseUp(duiHandler, "left")
            Citizen.Wait(100)
        end

    elseif platform == "soundcloud" then
        for _ = 1, 2 do
            SendDuiMouseMove(duiHandler, 1200, 400)
            Citizen.Wait(50)
        end
        SendDuiMouseDown(duiHandler, "left")
        Citizen.Wait(50)
        SendDuiMouseUp(duiHandler, "left")
    end
end

function UpdateDuiVideoUrl(tvData, platform, identifier)
    tvData.waitingforyt = false
    local data1 = GlobalState["rtxtv-" .. tvData.id .. "-data1"]
    local data2 = GlobalState["rtxtv-" .. tvData.id .. "-data2"]
    local newUrl = ScreenReformating(platform, identifier, 0, data1, data2)
    SetDuiUrl(tvData.duihandler, newUrl)

    if platform == "youtube" then
        tvData.waitingforyt = true
    end

    ApplyPlatformDuiWorkaround(tvData.duihandler, platform)
end

function CreateTVDui(tvData, currentVideoTime)
    local resourceName = GetCurrentResourceName()

    if tvData.tvmainmenu then
        local dui = CreateDui("https://cfx-nui-" .. resourceName .. "/html/tv/index.html", 1280, 720)
        return dui, true
    end

    if tvData.tvurltype == "youtube" then
        local dui = CreateDui("https://cfx-nui-" .. resourceName .. "/html/video.html", 1280, 720)
        tvData.waitingforyt = true
        return dui, true
    end

    local data1 = GlobalState["rtxtv-" .. tvData.id .. "-data1"]
    local data2 = GlobalState["rtxtv-" .. tvData.id .. "-data2"]

    -- videoStartTimeCache used for preset TVs (time received from server sync)
    local resolvedTime = tvData.preset and videoStartTimeCache or currentVideoTime
    local url = ScreenReformating(tvData.tvurltype, tvData.tvurl, resolvedTime, data1, data2)
    local dui = CreateDui(url, 1280, 720)
    tvData.waitingforyt = false
    return dui, true
end

function BindDuiToRuntimeTexture(duiHandler)
    local txdName  = GenerateTextureName()
    local texName  = GenerateTextureName()
    local duiNativeHandle = GetDuiHandle(duiHandler)
    local txd = CreateRuntimeTxd(txdName)
    CreateRuntimeTextureFromDuiHandle(txd, texName, duiNativeHandle)
    return txdName, texName
end

function BindScaleformTexture(scaleformHandle, txdName, texName)
    BeginScaleformMovieMethod(scaleformHandle, "SET_TEXTURE")
    _ENV["ScaleformMovieMethodAddParamTextureNameString"](txdName)
    _ENV["ScaleformMovieMethodAddParamTextureNameString"](texName)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(1920)
    ScaleformMovieMethodAddParamInt(1080)
    EndScaleformMovieMethod()
    PopScaleformMovieFunctionVoid()
end

function RemoveAndResetTV(tvIndex)
    table.remove(Config.TVs, tvIndex)
    isNearTV      = false
    closestTVDist = -1
    activeTVIndex = nil
    SendNUIMessage({ message = "stopvideo" })
end

function TeardownTVDui(tvData, tvIndex)
    if tvData.duihandler ~= nil then
        DestroyDui(tvData.duihandler)
        tvData.duihandler = nil
    end

    local isTurnedOff = tvTurnOffPending[tvData.id]
    if isTurnedOff == true then
        RemoveAndResetTV(tvIndex)
    else
        SendNUIMessage({ message = "stopvideo" })
    end
end

function IsTVTurnOffPending(tvData)
    return tvTurnOffPending[tvData.id] == true
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(500)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local foundTV      = false
        closestTVDist      = -1

        -- ── Vehicle TV: spawn/rebuild panel props ────────────────
        if Config.VehicleTelevision then
            if IsPedSittingInAnyVehicle(playerPed) then
                local currentVehicle = GetVehiclePedIsIn(playerPed, false)

                if NetworkGetEntityIsNetworked(currentVehicle) then
                    local netId = NetworkGetNetworkIdFromEntity(currentVehicle)

                    if OnlyOwnedVehiclesAllowed() then
                        local vehicleModel = GetEntityModel(currentVehicle)

                        if vehicleNetworkTVs[netId] ~= nil then
                            -- Entry exists — rebuild any missing handlers
                            RebuildMissingVehicleHandlers(currentVehicle, netId)

                        elseif vehicleItemCheckCache[netId] ~= nil then
                            -- vehicleItemCheckCache[netId]:
                            --   nil   = never queried
                            --   false = query result: ineligible (skip)
                            --   true  = query pending or ineligible (wait)
                            if vehicleItemCheckCache[netId] ~= false then
                                -- still pending or ineligible, skip
                            else
                                local plate = PlateReformat(GetVehicleNumberPlateText(currentVehicle))
                                RTXTV.TriggerServerCallback("rtx_tv:CheckVehicleTV", function(isAllowed)
                                    if isAllowed then
                                        local entries = BuildVehicleTVEntries(currentVehicle, vehicleModel)
                                        vehicleNetworkTVs[netId]      = entries
                                        vehicleItemCheckCache[netId]  = nil
                                    else
                                        vehicleItemCheckCache[netId] = true
                                        Citizen.Wait(1000)
                                    end
                                end, plate)
                            end
                        else
                            -- Never seen this vehicle — query the server
                            local plate = PlateReformat(GetVehicleNumberPlateText(currentVehicle))
                            RTXTV.TriggerServerCallback("rtx_tv:CheckVehicleTV", function(isAllowed)
                                if isAllowed then
                                    local entries = BuildVehicleTVEntries(currentVehicle, vehicleModel)
                                    vehicleNetworkTVs[netId]      = entries
                                    vehicleItemCheckCache[netId]  = nil
                                else
                                    vehicleItemCheckCache[netId] = true
                                    Citizen.Wait(1000)
                                end
                            end, plate)
                        end
                    else
                        -- No ownership check needed
                        local vehicleModel = GetEntityModel(currentVehicle)
                        if CheckVehicle(currentVehicle) then
                            if vehicleNetworkTVs[netId] ~= nil then
                                RebuildMissingVehicleHandlers(currentVehicle, netId)
                            else
                                local entries = BuildVehicleTVEntries(currentVehicle, vehicleModel)
                                vehicleNetworkTVs[netId] = entries
                            end
                        end
                    end
                end
            end
        end

        -- ── Manage visibility of all tracked vehicle TVs ─────────
        for netId, _ in pairs(vehicleNetworkTVs) do
            if NetworkDoesNetworkIdExist(netId) then
                local vehicleEntity = NetworkGetEntityFromNetworkId(netId)

                if DoesEntityExist(vehicleEntity) then
                    local playerCurrentVehicle = GetVehiclePedIsIn(playerPed, false)
                    local pedInAnyVehicle      = IsPedSittingInAnyVehicle(playerPed)

                    if pedInAnyVehicle and NetworkGetEntityIsNetworked(playerCurrentVehicle) then
                        local playerVehicleNetId = NetworkGetNetworkIdFromEntity(playerCurrentVehicle)

                        if playerVehicleNetId == netId then
                            SetVehicleTVHandlersVisible(netId, true)
                        else
                            SetVehicleTVHandlersVisible(netId, false)
                        end
                    else
                        SetVehicleTVHandlersVisible(netId, false)
                    end
                else
                    DestroyVehicleTVEntry(netId)
                end
            else
                DestroyVehicleTVEntry(netId)
            end
        end

        -- ── Find closest active TV for the player ────────────────
        for tvIndex, tvData in ipairs(Config.TVs) do
            if tvData.tvvehicle == true then
                -- Vehicle TV proximity check
                if IsPedSittingInAnyVehicle(playerPed) then
                    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
                    if NetworkGetEntityIsNetworked(currentVehicle) then
                        local netId = NetworkGetNetworkIdFromEntity(currentVehicle)
                        if netId == tvData.tvvehiclenetworkid then
                            if vehicleNetworkTVs[netId] ~= nil then
                                closestTVDist = 1.0
                                isNearTV      = true
                                activeTVIndex = tvIndex
                                foundTV       = true
                            end
                        end
                    end
                end
            else
                -- Static TV proximity check
                local routingBucket = GetPlayerRoutingBucket()

                if tvData.tvroutingbucket == routingBucket then
                    local tvObjectConfig = Config.TelevisionObjects[tvData.tvobjectdataid]

                    local dist
                    if tvObjectConfig.rendertarget == false then
                        if tvObjectConfig.nonobject == true then
                            dist = #(playerCoords - tvObjectConfig.nonobjectcoords)
                            if dist < tvObjectConfig.maxdistance then
                                if closestTVDist == -1 or dist < closestTVDist then
                                    closestTVDist = dist
                                    isNearTV      = true
                                    activeTVIndex = tvIndex
                                    foundTV       = true
                                end
                            end
                        else
                            dist = #(playerCoords - tvData.coords)
                            if dist < tvObjectConfig.maxdistance then
                                local tvEntity = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                                if DoesEntityExist(tvEntity) then
                                    if closestTVDist == -1 or dist < closestTVDist then
                                        closestTVDist = dist
                                        isNearTV      = true
                                        activeTVIndex = tvIndex
                                        foundTV       = true
                                    end
                                end
                            end
                        end
                    else
                        dist = #(playerCoords - tvData.coords)
                        if dist < tvObjectConfig.maxdistance then
                            local tvEntity = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                            if DoesEntityExist(tvEntity) then
                                if closestTVDist == -1 or dist < closestTVDist then
                                    closestTVDist = dist
                                    isNearTV      = true
                                    activeTVIndex = tvIndex
                                    foundTV       = true
                                end
                            end
                        end
                    end
                end
            end
        end

        if not foundTV then
            isNearTV      = false
            closestTVDist = -1
            activeTVIndex = nil
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local idle         = true

        if isNearTV == true then
            idle = false

            local currentTVIndex = activeTVIndex
            local tvData         = Config.TVs[activeTVIndex]

            -- ── Vehicle TV rendering ──────────────────────────────
            if tvData.tvvehicle then
                if IsPedSittingInAnyVehicle(playerPed) then
                    local currentVehicle = GetVehiclePedIsIn(playerPed, false)

                    if NetworkGetEntityIsNetworked(currentVehicle) then
                        local netId = NetworkGetNetworkIdFromEntity(currentVehicle)

                        if netId == tvData.tvvehiclenetworkid and vehicleNetworkTVs[netId] ~= nil then
                            local vehicleCoords = GetEntityCoords(currentVehicle)
                            local panelEntity   = GetClosestObjectOfType(vehicleCoords, 20.0, GetHashKey(TV_PANEL_MODEL))

                            if DoesEntityExist(panelEntity) then
                                -- Create DUI if needed
                                if tvData.duihandler == nil then
                                    local duiHandler, ready = nil, false

                                    if tvData.tvmainmenu then
                                        local resourceName = GetCurrentResourceName()
                                        duiHandler = CreateDui("https://cfx-nui-" .. resourceName .. "/html/tv/index.html", 1280, 720)
                                        ready = true
                                    else
                                        RTXTV.TriggerServerCallback("rtx_tv:GetCurrentVideoTime", function(currentTime)
                                            duiHandler, ready = CreateTVDui(tvData, currentTime)
                                        end, tvData.id)
                                    end

                                    while not ready do Citizen.Wait(5) end

                                    if not tvData.tvmainmenu then
                                        ApplyPlatformDuiWorkaround(duiHandler, tvData.tvurltype)
                                    end

                                    tvData.duihandler = duiHandler

                                    if not isMuted then
                                        ChangeVideoVolume(activeTVIndex, tvData.tvvolume)
                                    else
                                        ChangeVideoVolume(activeTVIndex, 0)
                                    end

                                    local txdName, texName = BindDuiToRuntimeTexture(duiHandler)

                                    -- Render loop for vehicle TV
                                    local stillInVehicle = IsPedSittingInAnyVehicle(playerPed)
                                        and NetworkGetNetworkIdFromEntity(GetVehiclePedIsIn(playerPed, false)) == tvData.tvvehiclenetworkid

                                    while stillInVehicle do
                                        Citizen.Wait(0)

                                        local renderId = CreateNamedRenderTargetForModel(TV_PANEL_RENDER_TARGET, GetHashKey(TV_PANEL_MODEL))
                                        if renderId ~= -1 then
                                            RenderScaleformTelevision(renderId, txdName, texName)
                                        end

                                        -- Update loop condition
                                        local inVehicleNow = IsPedSittingInAnyVehicle(playerPed)
                                        if inVehicleNow then
                                            local currentNetId = NetworkGetNetworkIdFromEntity(GetVehiclePedIsIn(playerPed, false))
                                            stillInVehicle = (currentNetId == tvData.tvvehiclenetworkid)
                                        else
                                            stillInVehicle = false
                                        end

                                        if IsTVTurnOffPending(tvData) then
                                            stillInVehicle = false
                                        end

                                        playerPed = PlayerPedId()
                                    end

                                    -- Cleanup
                                    if isNUIOpen then
                                        TriggerServerEvent("rtx_tv:CloseTV", tvData.id)
                                    end

                                    TeardownTVDui(tvData, currentTVIndex)
                                end
                            end
                        end
                    end
                end

            -- ── Static TV rendering ───────────────────────────────
            else
                local routingBucket  = GetPlayerRoutingBucket()

                if tvData.tvroutingbucket == routingBucket then
                    local tvObjectConfig = Config.TelevisionObjects[tvData.tvobjectdataid]
                    local scaleformHandle = nil

                    -- Load scaleform for non-render-target TVs
                    if tvObjectConfig.rendertarget ~= true then
                        scaleformHandle = loadScaleform("rtxtv")
                    end

                    -- Determine if TV object is valid/present
                    local tvEntityFound = false
                    local tvEntity      = nil

                    if tvObjectConfig.rendertarget == false then
                        if tvObjectConfig.nonobject == true then
                            tvEntityFound = true
                        else
                            tvEntity      = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                            tvEntityFound = DoesEntityExist(tvEntity)
                        end
                    else
                        tvEntity      = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                        tvEntityFound = DoesEntityExist(tvEntity)
                    end

                    if tvEntityFound then
                        -- Create DUI
                        local duiHandler, ready = nil, false

                        if tvData.tvmainmenu then
                            local resourceName = GetCurrentResourceName()
                            duiHandler = CreateDui("https://cfx-nui-" .. resourceName .. "/html/tv/index.html", 1280, 720)
                            ready = true
                        elseif not tvData.preset then
                            RTXTV.TriggerServerCallback("rtx_tv:GetCurrentVideoTime", function(currentTime)
                                duiHandler, ready = CreateTVDui(tvData, currentTime)
                            end, tvData.id)
                        else
                            duiHandler, ready = CreateTVDui(tvData, nil)
                        end

                        while not ready do Citizen.Wait(5) end

                        if not tvData.tvmainmenu then
                            ApplyPlatformDuiWorkaround(duiHandler, tvData.tvurltype)
                        end

                        tvData.duihandler = duiHandler

                        -- Wait for DUI to become available
                        while not IsDuiAvailable(duiHandler) do Citizen.Wait(5) end

                        if not isMuted then
                            ChangeVideoVolume(currentTVIndex, tvData.tvvolume)
                        else
                            ChangeVideoVolume(currentTVIndex, 0)
                        end

                        -- ── Non-render-target rendering ───────────────────────
                        if tvObjectConfig.rendertarget == false then
                            local txdName, texName = BindDuiToRuntimeTexture(duiHandler)
                            local currentRoutingBucket = GetPlayerRoutingBucket()

                            if tvObjectConfig.nonobject == true then
                                -- Floating scaleform 3D (no attached entity)
                                nonobjectScaleform = loadScaleform("rtxtv")
                                BindScaleformTexture(nonobjectScaleform, txdName, texName)

                                local distToTV = #(playerCoords - tvData.coords)

                                while distToTV < tvObjectConfig.maxdistance and tvData.tvroutingbucket == currentRoutingBucket do
                                    Citizen.Wait(0)
                                    DrawScaleformMovie_3dSolid(
                                        nonobjectScaleform,
                                        tvObjectConfig.nonobjectcoords,
                                        tvObjectConfig.nonobjectrotation,
                                        2.0, 2.0, 2.0,
                                        tvObjectConfig.scale.x, tvObjectConfig.scale.y, tvObjectConfig.scale.z,
                                        2
                                    )

                                    playerCoords  = GetEntityCoords(PlayerPedId())
                                    distToTV      = #(playerCoords - tvData.coords)
                                    currentRoutingBucket = GetPlayerRoutingBucket()

                                    if IsTVTurnOffPending(tvData) then
                                        distToTV = 10000
                                    end

                                    playerPed = PlayerPedId()
                                end

                                -- Cleanup nonobject
                                DestroyDui(tvData.duihandler)
                                tvData.duihandler = nil
                                SetScaleformMovieAsNoLongerNeeded(nonobjectScaleform)
                                TeardownTVDui(tvData, currentTVIndex)

                            else
                                -- Object-attached scaleform (rotated to match object)
                                local entityCoords   = GetEntityCoords(tvEntity)
                                local entityRotation = GetEntityRotation(tvEntity)
                                local radZ           = math.rad(entityRotation.z)
                                local cosZ, sinZ     = math.cos(radZ), math.sin(radZ)

                                local posX = tvObjectConfig.position.x * cosZ - tvObjectConfig.position.y * sinZ + entityCoords.x
                                local posY = tvObjectConfig.position.y * cosZ + tvObjectConfig.position.x * sinZ + entityCoords.y
                                local posZ = tvObjectConfig.position.z + entityCoords.z

                                local worldPos    = vector3(posX, posY, posZ)
                                local worldRotZ   = -(entityRotation.z + tvObjectConfig.rotation)

                                nonobjectScaleform = loadScaleform("rtxtv")
                                BindScaleformTexture(nonobjectScaleform, txdName, texName)

                                local distToTV = #(playerCoords - tvData.coords)

                                while distToTV < tvObjectConfig.maxdistance
                                    and tvData.tvroutingbucket == currentRoutingBucket
                                    and IsPlayerBehindWall(playerPed, tvEntity)
                                do
                                    Citizen.Wait(0)
                                    DrawScaleformMovie_3dSolid(
                                        nonobjectScaleform,
                                        worldPos, worldRotZ,
                                        2.0, 2.0, 2.0,
                                        tvObjectConfig.scale.x * 1,
                                        tvObjectConfig.scale.y * 0.5625,
                                        tvObjectConfig.scale.z,
                                        2
                                    )

                                    playerCoords  = GetEntityCoords(PlayerPedId())
                                    distToTV      = #(playerCoords - tvData.coords)
                                    currentRoutingBucket = GetPlayerRoutingBucket()

                                    if IsTVTurnOffPending(tvData) then
                                        distToTV = 10000
                                    end

                                    playerPed = PlayerPedId()
                                end

                                -- Cleanup object-attached scaleform
                                DestroyDui(tvData.duihandler)
                                SetScaleformMovieAsNoLongerNeeded(nonobjectScaleform)
                                tvData.duihandler = nil
                                TeardownTVDui(tvData, currentTVIndex)
                            end

                        -- ── Render-target rendering ───────────────────────────
                        else
                            local txdName, texName = BindDuiToRuntimeTexture(tvData.duihandler)
                            local currentRoutingBucket = GetPlayerRoutingBucket()
                            local keepRendering = true

                            while keepRendering do
                                if activeTVIndex == currentTVIndex
                                    and tvData.tvroutingbucket == currentRoutingBucket
                                    and IsPlayerBehindWall(playerPed, tvEntity)
                                then
                                    Citizen.Wait(0)

                                    local renderId = CreateNamedRenderTargetForModel(tvObjectConfig.rendertargetname, GetHashKey(tvObjectConfig.object))
                                    if renderId ~= -1 then
                                        RenderScaleformTelevision(renderId, txdName, texName)
                                    end

                                    currentRoutingBucket = GetPlayerRoutingBucket()
                                    playerCoords         = GetEntityCoords(PlayerPedId())
                                    local distancetv     = #(playerCoords - tvData.coords)

                                    if IsTVTurnOffPending(tvData) then
                                        keepRendering = false
                                    end

                                    playerPed = PlayerPedId()
                                else
                                    keepRendering = false
                                end
                            end

                            -- Cleanup render-target
                            DestroyDui(tvData.duihandler)
                            tvData.duihandler = nil
                            TeardownTVDui(tvData, currentTVIndex)
                        end
                    end
                end
            end
        end

        if idle then
            Citizen.Wait(500)
        end
    end
end)

if Config.TelevisionObjectPlacer then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)

            local playerPed    = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)

            for _, locationEntry in ipairs(Config.TelevisionObjectsLocations) do
                local dist = #(playerCoords - locationEntry.coords)

                if dist < 200.0 then
                    if DoesEntityExist(locationEntry.handler) then
                        FreezeEntityPosition(locationEntry.handler, true)
                    else
                        local modelHash = GetHashKey(locationEntry.objectname)
                        LoadModelAsync(modelHash)

                        local obj = CreateObjectNoOffset(
                            modelHash,
                            locationEntry.coords.x, locationEntry.coords.y, locationEntry.coords.z,
                            false, true, true
                        )
                        locationEntry.handler = obj

                        SetEntityRotation(obj, locationEntry.rotation.x, locationEntry.rotation.y, locationEntry.rotation.z)
                        FreezeEntityPosition(obj, true)
                    end
                end
            end
        end
    end)
end

RegisterNetEvent("rtx_tv:CreateNewTV")
AddEventHandler("rtx_tv:CreateNewTV", function(tvId, coords, objectDataId, isVehicleTV, vehicleNetId, volume, isMainMenu, urlType, urlIdentifier, routingBucket)
    if CheckTvData(tvId) ~= nil then return end

    table.insert(Config.TVs, {
        id                  = tvId,
        coords              = coords,
        taken               = true,
        takenplayerid       = nil,          -- server-side only; not available client-side
        tvobjectdataid      = objectDataId,
        tvmainmenu          = isMainMenu,
        tvurltype           = urlType,
        tvurl               = urlIdentifier,
        tvtime              = videoStartTimeCache,
        tvvolume            = volume,
        tvduration          = nil,
        duihandler          = nil,
        tvvehicle           = isVehicleTV,
        tvvehiclenetworkid  = vehicleNetId,
        waitingforyt        = false,
        tvroutingbucket     = routingBucket,
        preset              = false,
    })
end)

RegisterNetEvent("rtx_tv:PlayVideoClient")
AddEventHandler("rtx_tv:PlayVideoClient", function(tvId, platform, identifier)
    local tvIndex = CheckTvData(tvId)
    if tvIndex == nil then return end

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local tvData       = Config.TVs[tvIndex]

    tvData.tvmainmenu = false
    tvData.tvurltype  = platform
    tvData.tvurl      = identifier

    if tvData.tvvehicle then
        if not IsPedSittingInAnyVehicle(playerPed) then return end

        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        if not NetworkGetEntityIsNetworked(currentVehicle) then return end

        local netId = NetworkGetNetworkIdFromEntity(currentVehicle)
        if netId ~= tvData.tvvehiclenetworkid then return end
        if vehicleNetworkTVs[netId] == nil then return end

        local vehicleCoords = GetEntityCoords(currentVehicle)
        local panelEntity   = GetClosestObjectOfType(vehicleCoords, 20.0, GetHashKey(TV_PANEL_MODEL))
        if not DoesEntityExist(panelEntity) then return end
        if tvData.duihandler == nil then return end

        UpdateDuiVideoUrl(tvData, platform, identifier)
    else
        local tvObjectConfig = Config.TelevisionObjects[tvData.tvobjectdataid]
        local isInRange      = false

        if tvObjectConfig.rendertarget == false and tvObjectConfig.nonobject == true then
            isInRange = #(playerCoords - tvObjectConfig.nonobjectcoords) < tvObjectConfig.maxdistance
        else
            local dist = #(playerCoords - tvData.coords)
            if dist < tvObjectConfig.maxdistance then
                local tvEntity = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                isInRange = DoesEntityExist(tvEntity)
            end
        end

        if not isInRange then return end
        if tvData.duihandler == nil then return end

        UpdateDuiVideoUrl(tvData, platform, identifier)
    end
end)

RegisterNetEvent("rtx_tv:ChangeVolumeClient")
AddEventHandler("rtx_tv:ChangeVolumeClient", function(tvId, newVolume)
    local tvIndex = CheckTvData(tvId)
    if tvIndex == nil then return end

    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local tvData       = Config.TVs[tvIndex]

    tvData.tvvolume = newVolume

    local function ApplyVolume()
        if tvData.duihandler == nil then return end
        if not isMuted then
            ChangeVideoVolume(tvIndex, newVolume)
        else
            ChangeVideoVolume(tvIndex, 0)
        end
    end

    if tvData.tvvehicle then
        if not IsPedSittingInAnyVehicle(playerPed) then return end

        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        if not NetworkGetEntityIsNetworked(currentVehicle) then return end

        local netId = NetworkGetNetworkIdFromEntity(currentVehicle)
        if netId ~= tvData.tvvehiclenetworkid then return end
        if vehicleNetworkTVs[netId] == nil then return end

        local vehicleCoords = GetEntityCoords(currentVehicle)
        local panelEntity   = GetClosestObjectOfType(vehicleCoords, 20.0, GetHashKey(TV_PANEL_MODEL))
        if not DoesEntityExist(panelEntity) then return end

        ApplyVolume()
    else
        local tvObjectConfig = Config.TelevisionObjects[tvData.tvobjectdataid]
        local isInRange      = false

        if tvObjectConfig.rendertarget == false and tvObjectConfig.nonobject == true then
            isInRange = #(playerCoords - tvObjectConfig.nonobjectcoords) < tvObjectConfig.maxdistance
        else
            local dist = #(playerCoords - tvData.coords)
            if dist < tvObjectConfig.maxdistance then
                local tvEntity = GetClosestObjectOfType(tvData.coords, tvObjectConfig.maxdistance, GetHashKey(tvObjectConfig.object))
                isInRange = DoesEntityExist(tvEntity)
            end
        end

        if not isInRange then return end
        ApplyVolume()
    end
end)

RegisterNetEvent("rtx_tv:TurnOffTVClient")
AddEventHandler("rtx_tv:TurnOffTVClient", function(tvId)
    local tvIndex = CheckTvData(tvId)
    if tvIndex == nil then return end

    tvTurnOffPending[tvId] = true

    if activeTVIndex ~= nil and activeTVIndex ~= tvIndex then
        table.remove(Config.TVs, tvIndex)
    end
end)

RegisterNetEvent("rtx_tv:OpenTVMenu")
AddEventHandler("rtx_tv:OpenTVMenu", function(currentUrl, urlType, volume)
    DisableIdleCamera(true)

    local urlLabel = GetUrlTypeLabel(urlType)
    isNUIOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({
        message      = "tvshow",
        tvurldata    = currentUrl,
        tvurltypedata = urlLabel,
        tvvolumedata = volume,
    })
end)

RegisterNetEvent("rtx_tv:TVInstalledVehicleClient")
AddEventHandler("rtx_tv:TVInstalledVehicleClient", function(netId)
    vehicleItemCheckCache[netId] = false
end)

if Config.TvForItem then
    RegisterNetEvent("rtx_tv:TVRemote")
    AddEventHandler("rtx_tv:TVRemote", function()
        if isNUIOpen then return end
        ActivateNearestTV()
    end)
end

if Config.Target then
    RegisterNetEvent("rtx_tv:ControlTVTarget")
    AddEventHandler("rtx_tv:ControlTVTarget", function()
        if isNUIOpen then return end
        ActivateNearestTV()
    end)
end

if Config.Framework == "qbcore" or Config.Framework == "esx" or Config.Framework == "custom" then
    RegisterNetEvent("rtx_tv:InstallVehicleTVClient")
    AddEventHandler("rtx_tv:InstallVehicleTVClient", function()
        local playerPed = PlayerPedId()

        if not IsPedSittingInAnyVehicle(playerPed) then
            Notify(Language[Config.Language].noinvehicle)
            return
        end

        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        local plate          = PlateReformat(GetVehicleNumberPlateText(currentVehicle))
        local netId          = NetworkGetNetworkIdFromEntity(currentVehicle)

        if CheckVehicle(currentVehicle) then
            TriggerServerEvent("rtx_tv:InstallVehicleTV", plate, netId)
        else
            Notify(Language[Config.Language].vehiclenotowned)
        end
    end)
end

RegisterNetEvent("rtx_tv:Notify")
AddEventHandler("rtx_tv:Notify", function(message)
    Notify(message)
end)

function ActivateNearestTV()
    local playerPed    = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local foundTV          = false
    local closestDist      = -1
    local closestObjectIndex = nil
    local closestCoords    = nil
    local isVehicleTV      = false
    local vehicleNetId     = nil

    -- Check if inside an eligible vehicle
    if IsPedSittingInAnyVehicle(playerPed) then
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)
        if CheckVehicle(currentVehicle) and NetworkGetEntityIsNetworked(currentVehicle) then
            local netId = NetworkGetNetworkIdFromEntity(currentVehicle)
            if vehicleNetworkTVs[netId] ~= nil then
                isVehicleTV = true
                vehicleNetId = netId
            end
        end
    end

    -- Find closest static TV object
    for objIndex, tvObjConfig in ipairs(Config.TelevisionObjects) do
        local dist, coords

        if tvObjConfig.rendertarget == false and tvObjConfig.nonobject == true then
            dist   = #(playerCoords - tvObjConfig.nonobjectcoords)
            coords = tvObjConfig.nonobjectcoords
        else
            local tvEntity = GetClosestObjectOfType(playerCoords, tvObjConfig.maxcontroldistance, GetHashKey(tvObjConfig.object))
            if DoesEntityExist(tvEntity) then
                coords = GetEntityCoords(tvEntity)
                dist   = #(playerCoords - coords)
            end
        end

        if dist and dist < tvObjConfig.maxcontroldistance and (closestDist == -1 or dist < closestDist) then
            closestDist        = dist
            foundTV            = true
            closestObjectIndex = objIndex
            closestCoords      = coords
        end
    end

    if isVehicleTV then
        TriggerServerEvent("rtx_tv:AddNewTVVehicle", vehicleNetId)

    elseif foundTV then
        local isPreset = false
        if Config.TelevisionPresets then
            isPreset = CheckIfTvIsNotPresset(closestCoords)
        end

        if not isPreset then
            TriggerServerEvent("rtx_tv:AddNewTV", closestObjectIndex, closestCoords)
        else
            Notify(Language[Config.Language].notvnearby)
        end
    else
        Notify(Language[Config.Language].notvnearby)
    end
end

if Config.TvForCommand then
    RegisterCommand(Config.TvCommand, function()
        if isNUIOpen then return end
        ActivateNearestTV()
    end)
end

if Config.VehicleTelevisionOffSetsCreator then
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)

            if isCreatorActive ~= true then
                Citizen.Wait(500)
                goto continue
            end

            if not DoesEntityExist(creatorVehicle) or not DoesEntityExist(creatorProp) then
                goto continue
            end

            local speed = SpeedSettings[speedSettingIndex].speeddata

            if isRotateMode then
                if IsControlPressed(1, 27) or IsDisabledControlPressed(1, 27) then
                    creatorOffsets.rotationx = creatorOffsets.rotationx + speed * 50.0
                end
                if IsControlPressed(1, 173) or IsDisabledControlPressed(1, 173) then
                    creatorOffsets.rotationx = creatorOffsets.rotationx - speed * 50.0
                end
                if IsControlPressed(1, 174) or IsDisabledControlPressed(1, 174) then
                    creatorOffsets.rotationz = creatorOffsets.rotationz + speed * 50.0
                end
                if IsControlPressed(1, 175) or IsDisabledControlPressed(1, 175) then
                    creatorOffsets.rotationz = creatorOffsets.rotationz - speed * 50.0
                end
                if IsControlPressed(1, 20) or IsDisabledControlPressed(1, 20) then
                    creatorOffsets.rotationy = creatorOffsets.rotationy + speed * 50.0
                end
                if IsControlPressed(1, 246) or IsDisabledControlPressed(1, 246) then
                    creatorOffsets.rotationy = creatorOffsets.rotationy - speed * 50.0
                end
            else
                if IsControlPressed(1, 27) or IsDisabledControlPressed(1, 27) then
                    creatorOffsets.offsety = creatorOffsets.offsety + speed
                end
                if IsControlPressed(1, 173) or IsDisabledControlPressed(1, 173) then
                    creatorOffsets.offsety = creatorOffsets.offsety - speed
                end
                if IsControlPressed(1, 174) or IsDisabledControlPressed(1, 174) then
                    creatorOffsets.offsetx = creatorOffsets.offsetx - speed
                end
                if IsControlPressed(1, 175) or IsDisabledControlPressed(1, 175) then
                    creatorOffsets.offsetx = creatorOffsets.offsetx + speed
                end
                if IsControlPressed(1, 20) or IsDisabledControlPressed(1, 20) then
                    creatorOffsets.offsetz = creatorOffsets.offsetz + speed
                end
                if IsControlPressed(1, 246) or IsDisabledControlPressed(1, 246) then
                    creatorOffsets.offsetz = creatorOffsets.offsetz - speed
                end
            end

            local defaultOffset = Config.TelevisonVehiclesOffsetsDefault
            local boneIndex     = GetEntityBoneIndexByName(creatorVehicle, defaultOffset.vehiclebone)
            if boneIndex then
                AttachEntityToEntity(
                    creatorProp, creatorVehicle, 0,
                    creatorOffsets.offsetx, creatorOffsets.offsety, creatorOffsets.offsetz,
                    creatorOffsets.rotationx, creatorOffsets.rotationy, creatorOffsets.rotationz,
                    false, false, false, false, 2, true
                )
            end

            local propCoords = GetEntityCoords(creatorProp)
            DrawText3D(propCoords.x, propCoords.y, propCoords.z, "Object")

            ::continue::
        end
    end)

    RegisterCommand("tvcreator", function(source, args)
        if isCreatorActive then return end

        local playerPed = PlayerPedId()
        if not IsPedSittingInAnyVehicle(playerPed) then return end

        local currentVehicle  = GetVehiclePedIsIn(playerPed, false)
        creatorVehicle        = currentVehicle

        local defaultOffset = Config.TelevisonVehiclesOffsetsDefault
        local vehicleCoords = GetEntityCoords(creatorVehicle)
        local panelHash     = GetHashKey(TV_PANEL_MODEL)
        LoadModelAsync(panelHash)

        local prop = CreateObjectNoOffset(panelHash, vehicleCoords.x, vehicleCoords.y, vehicleCoords.z, false, true, true)
        creatorProp = prop

        local boneIndex = GetEntityBoneIndexByName(creatorVehicle, defaultOffset.vehiclebone)

        creatorOffsets = {
            offsetx   = defaultOffset.offsetx,
            offsety   = defaultOffset.offsety,
            offsetz   = defaultOffset.offsetz,
            rotationx = defaultOffset.rotation.x,
            rotationy = defaultOffset.rotation.y,
            rotationz = defaultOffset.rotation.z,
        }

        if boneIndex then
            AttachEntityToEntity(
                creatorProp, creatorVehicle, 0,
                creatorOffsets.offsetx, creatorOffsets.offsety, creatorOffsets.offsetz,
                creatorOffsets.rotationx, creatorOffsets.rotationy, creatorOffsets.rotationz,
                false, false, false, false, 2, true
            )
        end

        speedSettingIndex = 1
        isRotateMode      = false
        isCreatorActive   = true

        SendNUIMessage({ message = "vehicletvcreatorshow" })
        SendNUIMessage({ message = "changespeed",  speeddata = speedSettingIndex })
        SendNUIMessage({ message = "changemode",   modedata  = "MOVE" })
    end)

    RegisterCommand("finishcreator", function(source, args)
        if not isCreatorActive then return end

        SetNuiFocus(true, true)
        SendNUIMessage({
            message          = "vehicletvcreatorfinishshow",
            offsetxdata      = creatorOffsets.offsetx,
            offsetydata      = creatorOffsets.offsety,
            offsetzdata      = creatorOffsets.offsetz,
            offsetrotationdata = "" .. vector3(creatorOffsets.rotationx, creatorOffsets.rotationy, creatorOffsets.rotationz) .. "",
        })

        DeleteEntity(creatorProp)
        creatorVehicle = nil
        creatorProp    = nil
    end)

    RegisterCommand("changespeedcreator", function(source, args)
        if not isCreatorActive then return end

        if speedSettingIndex == #SpeedSettings then
            speedSettingIndex = 1
        else
            speedSettingIndex = speedSettingIndex + 1
        end

        SendNUIMessage({ message = "changespeed", speeddata = speedSettingIndex })
    end)

    RegisterCommand("rotatechange", function(source, args)
        if not isCreatorActive then return end

        if not isRotateMode then
            isRotateMode = true
            SendNUIMessage({ message = "changemode", modedata = "ROTATE" })
        else
            isRotateMode = false
            SendNUIMessage({ message = "changemode", modedata = "MOVE" })
        end
    end)

    RegisterKeyMapping("changespeedcreator", "Speed Change",   "keyboard", "g")
    RegisterKeyMapping("rotatechange",        "Mode change",    "keyboard", "h")
    RegisterKeyMapping("finishcreator",       "Finish creator", "keyboard", "return")
end

RegisterCommand(Config.StreamerModeCommand, function(source, args, rawCommand)
    if isMuted then
        isMuted = false
        if activeTVIndex ~= nil then
            local tvData = Config.TVs[activeTVIndex]
            ChangeVideoVolume(activeTVIndex, tvData.tvvolume)
        end
        Notify(Language[Config.Language].streamerdeactivated)
    else
        isMuted = true
        if activeTVIndex ~= nil then
            ChangeVideoVolume(activeTVIndex, 0)
        end
        Notify(Language[Config.Language].streamerdactivated)
    end
end)

if Config.EnableGetNearbyTvCoords == true then
    RegisterCommand(Config.EnableGetNearbyTvCoordsCommand, function(source, args)
        if args == nil or args[1] == nil then
            print("Define the object name")
            return
        end

        local playerPed    = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local objectName   = tostring(args[1])
        local modelHash    = GetHashKey(objectName)
        local tvEntity     = GetClosestObjectOfType(playerCoords, 200.0, modelHash)

        if DoesEntityExist(tvEntity) then
            local coords = GetEntityCoords(tvEntity)
            print("Position of TV: " .. tostring(coords))
        else
            print("No tv nearby")
        end
    end)
end

if Config.CustomTvCreator == true then

    -- State for the custom TV creator
    local customTVPosition  = vector3(0.0, 0.0, 0.0)
    local customTVRotation  = vector3(0.0, 0.0, 0.0)
    local customTVScaleX    = 0.1
    local customTVScaleY    = 0.05
    local customTVDui       = nil
    local customTVScaleform = nil
    local customTVTxdName   = nil
    local customTVTexName   = nil
    local customTVActive    = false
    local customTVPropEntity = nil

    local creatorMoveSpeed   = 0.01
    local creatorRotSpeed    = 0.5
    local creatorScaleStep   = 0.0005
    local creatorEditMode    = "coords"   -- "coords" or "rotation"
    local creatorScaleAxis   = "x"        -- "x" or "y"

    -- Key label map for on-screen help
    local KEY_LABELS = {
        [172] = "↑", [173] = "↓", [174] = "←", [175] = "→",
        [21]  = "Shift", [38] = "E",   [44]  = "Q",  [74]  = "H",
        [96]  = "Num+",  [97] = "Num-",[191] = "Enter", [177] = "Backspace",
        [182] = "L",
    }

    function DrawManualKeyLabel(controlId, labelText, screenX, screenY)
        local keyName = KEY_LABELS[controlId] or "???"
        SetTextFont(0)
        SetTextProportional(1)
        SetTextScale(0.35, 0.35)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        AddTextComponentString("[" .. keyName .. "] " .. labelText)
        DrawText(screenX, screenY)
    end

    function DrawVerticalKeymap(keyList, screenX, startY, stepY)
        for i, entry in ipairs(keyList) do
            DrawManualKeyLabel(entry.control, entry.label, screenX, startY + (i - 1) * stepY)
        end
    end

    function initializeScreencreator()
        customTVScaleform = RequestScaleformMovie("rtxtv")
        while not HasScaleformMovieLoaded(customTVScaleform) do Citizen.Wait(0) end

        local resourceName = GetCurrentResourceName()
        customTVDui = CreateDui("https://cfx-nui-" .. resourceName .. "/html/tv/index.html", 1280, 720)
        while not IsDuiAvailable(customTVDui) do Citizen.Wait(0) end

        customTVTxdName = GenerateTextureName()
        customTVTexName = GenerateTextureName()

        local duiHandle = GetDuiHandle(customTVDui)
        local txd       = CreateRuntimeTxd(customTVTxdName)
        CreateRuntimeTextureFromDuiHandle(txd, customTVTexName, duiHandle)

        BindScaleformTexture(customTVScaleform, customTVTxdName, customTVTexName)
    end

    function drawScreencreator()
        DrawScaleformMovie_3dSolid(
            customTVScaleform,
            customTVPosition, customTVRotation,
            2.0, 2.0, 2.0,
            customTVScaleX, customTVScaleY, 1.0,
            2
        )
    end

    RegisterCommand("createcustomtv", function(source, args)
        if customTVActive then return end

        customTVActive   = true
        local playerPed  = PlayerPedId()
        customTVPosition = GetEntityCoords(playerPed)
        customTVRotation = vector3(0.0, 0.0, 0.0)
        customTVScaleX   = 0.1
        customTVScaleY   = 0.05

        local useObjectMode = false
        local objectModelName = ""

        if args[1] ~= nil and args[1] ~= "" then
            useObjectMode     = true
            objectModelName   = tostring(args[1])
        end

        -- Cleanup old prop
        if DoesEntityExist(customTVPropEntity) then
            DeleteEntity(customTVPropEntity)
        end

        if useObjectMode then
            local modelHash = GetHashKey(objectModelName)
            LoadModelAsync(modelHash)

            customTVPropEntity = CreateObjectNoOffset(modelHash, customTVPosition, false, true, true)
            FreezeEntityPosition(customTVPropEntity, true)
            SetEntityRotation(customTVPropEntity, customTVRotation)
        end

        -- Creator loop
        while customTVActive do
            Citizen.Wait(0)

            -- Disable conflicting controls
            for _, control in ipairs({ 24, 25, 45, 140, 141, 142, 263, 44, 22, 37, 157, 158, 159, 160, 75, 36, 199 }) do
                DisableControlAction(0, control, true)
            end

            if useObjectMode then
                -- Object placement mode
                local objectKeymap = {
                    { control = 172, label = "Move Forward"  },
                    { control = 173, label = "Move Backward" },
                    { control = 174, label = "Move Left"     },
                    { control = 175, label = "Move Right"    },
                    { control = 44,  label = "Move Up (Z+)"  },
                    { control = 38,  label = "Move Down (Z-)"},
                    { control = 21,  label = "Switch Mode"   },
                    { control = 191, label = "Confirm"       },
                }
                DrawVerticalKeymap(objectKeymap, 0.015, 0.4, 0.025)

                if IsControlJustPressed(0, 21) then
                    creatorEditMode = (creatorEditMode == "coords") and "rotation" or "coords"
                end

                if creatorEditMode == "coords" then
                    if IsControlPressed(0, 172) then customTVPosition = customTVPosition + vector3(0.0, creatorMoveSpeed, 0.0) end
                    if IsControlPressed(0, 173) then customTVPosition = customTVPosition - vector3(0.0, creatorMoveSpeed, 0.0) end
                    if IsControlPressed(0, 174) then customTVPosition = customTVPosition - vector3(creatorMoveSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 175) then customTVPosition = customTVPosition + vector3(creatorMoveSpeed, 0.0, 0.0) end
                    if IsDisabledControlPressed(0, 44) then customTVPosition = customTVPosition + vector3(0.0, 0.0, creatorMoveSpeed) end
                    if IsControlPressed(0, 38) then customTVPosition = customTVPosition - vector3(0.0, 0.0, creatorMoveSpeed) end
                end

                if creatorEditMode == "rotation" then
                    if IsControlPressed(0, 172) then customTVRotation = customTVRotation + vector3(creatorRotSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 173) then customTVRotation = customTVRotation - vector3(creatorRotSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 174) then customTVRotation = customTVRotation - vector3(0.0, creatorRotSpeed, 0.0) end
                    if IsControlPressed(0, 175) then customTVRotation = customTVRotation + vector3(0.0, creatorRotSpeed, 0.0) end
                    if IsDisabledControlPressed(0, 44) then customTVRotation = customTVRotation + vector3(0.0, 0.0, creatorRotSpeed) end
                    if IsControlPressed(0, 38) then customTVRotation = customTVRotation - vector3(0.0, 0.0, creatorRotSpeed) end
                end

                if IsControlJustPressed(0, 191) then
                    customTVActive = false
                    if DoesEntityExist(customTVPropEntity) then DeleteEntity(customTVPropEntity) end
                    print(string.format(
                        "coords = %s | rotation = %s | objectname = %s",
                        vector3(customTVPosition.x, customTVPosition.y, customTVPosition.z),
                        vector3(customTVRotation.x, customTVRotation.y, customTVRotation.z),
                        objectModelName
                    ))
                end

                SetEntityCoordsNoOffset(customTVPropEntity, customTVPosition.x, customTVPosition.y, customTVPosition.z, false, false, false)
                SetEntityRotation(customTVPropEntity, customTVRotation.x, customTVRotation.y, customTVRotation.z)

            else
                -- Screen-only (nonobject) placement mode
                if customTVScaleform == nil then
                    initializeScreencreator()
                end

                local screenKeymap = {
                    { control = 172, label = "Move Forward"    },
                    { control = 173, label = "Move Backward"   },
                    { control = 174, label = "Move Left"       },
                    { control = 175, label = "Move Right"      },
                    { control = 44,  label = "Move Up (Z+)"    },
                    { control = 38,  label = "Move Down (Z-)"  },
                    { control = 21,  label = "Switch Mode"     },
                    { control = 74,  label = "Switch Scale Axis"},
                    { control = 96,  label = "Increase Scale"  },
                    { control = 97,  label = "Decrease Scale"  },
                    { control = 191, label = "Confirm"         },
                }
                DrawVerticalKeymap(screenKeymap, 0.015, 0.4, 0.025)
                drawScreencreator()

                if IsControlJustPressed(0, 21) then
                    creatorEditMode = (creatorEditMode == "coords") and "rotation" or "coords"
                end
                if IsControlJustPressed(0, 74) then
                    creatorScaleAxis = (creatorScaleAxis == "x") and "y" or "x"
                end

                if creatorEditMode == "coords" then
                    if IsControlPressed(0, 172) then customTVPosition = customTVPosition + vector3(0.0, creatorMoveSpeed, 0.0) end
                    if IsControlPressed(0, 173) then customTVPosition = customTVPosition - vector3(0.0, creatorMoveSpeed, 0.0) end
                    if IsControlPressed(0, 174) then customTVPosition = customTVPosition - vector3(creatorMoveSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 175) then customTVPosition = customTVPosition + vector3(creatorMoveSpeed, 0.0, 0.0) end
                    if IsDisabledControlPressed(0, 44) then customTVPosition = customTVPosition + vector3(0.0, 0.0, creatorMoveSpeed) end
                    if IsControlPressed(0, 38) then customTVPosition = customTVPosition - vector3(0.0, 0.0, creatorMoveSpeed) end
                end

                if creatorEditMode == "rotation" then
                    if IsControlPressed(0, 172) then customTVRotation = customTVRotation + vector3(creatorRotSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 173) then customTVRotation = customTVRotation - vector3(creatorRotSpeed, 0.0, 0.0) end
                    if IsControlPressed(0, 174) then customTVRotation = customTVRotation - vector3(0.0, creatorRotSpeed, 0.0) end
                    if IsControlPressed(0, 175) then customTVRotation = customTVRotation + vector3(0.0, creatorRotSpeed, 0.0) end
                    if IsDisabledControlPressed(0, 44) then customTVRotation = customTVRotation + vector3(0.0, 0.0, creatorRotSpeed) end
                    if IsControlPressed(0, 38) then customTVRotation = customTVRotation - vector3(0.0, 0.0, creatorRotSpeed) end
                end

                -- Scale adjustment
                if IsControlPressed(0, 96) then
                    if creatorScaleAxis == "x" then
                        customTVScaleX = customTVScaleX + creatorScaleStep
                    else
                        customTVScaleY = customTVScaleY + creatorScaleStep
                    end
                elseif IsControlPressed(0, 97) then
                    if creatorScaleAxis == "x" then
                        customTVScaleX = math.max(0.01, customTVScaleX - creatorScaleStep)
                    else
                        customTVScaleY = math.max(0.01, customTVScaleY - creatorScaleStep)
                    end
                end

                if IsControlJustPressed(0, 191) then
                    customTVActive = false
                    print(string.format(
                        "nonobjectcoords = %s | nonobjectrotation = %s | scale = %s",
                        vector3(customTVPosition.x, customTVPosition.y, customTVPosition.z),
                        vector3(customTVRotation.x, customTVRotation.y, customTVRotation.z),
                        vector3(customTVScaleX, customTVScaleY, 1.0)
                    ))
                end
            end
        end
    end)
end