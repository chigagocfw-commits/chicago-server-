--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]


local DisableControlAction = DisableControlAction
local IsNuiFocused         = IsNuiFocused
local DisablePlayerFiring  = DisablePlayerFiring

phoneData    = nil    
currentPhone = nil    
settings     = nil    
phoneOpen    = false  

SavedLocations = {}   
PhoneOnScreen  = false 

local phoneLoaded       = nil   
local isFetchingPhone   = nil   
local configReceivedByUI = nil  

local function WaitForConfig()
    if configReceivedByUI then
        return
    end

    debugprint("waiting for config to be received")

    while true do
        if configReceivedByUI then
            break
        end
        Wait(0)
    end

    debugprint("config received")
end

local function FetchPhone()
    debugprint("FetchPhone triggered")

    if isFetchingPhone then
        debugprint("already fetching phone")
        return
    end

    if not configReceivedByUI then
        debugprint("config has not been received by the UI yet")
        return
    end

    isFetchingPhone = true

    while true do
        if FrameworkLoaded then
            break
        end
        debugprint("waiting for framework to load")
        Wait(500)
    end

    debugprint("triggering phone:playerLoaded")

    local phoneNumber = nil

    if phoneLoaded and currentPhone then
        
        phoneNumber = SavedLocations  
        goto useExistingNumber
    end

    do
        local result = AwaitCallback("playerLoaded")
        phoneNumber  = result
        SavedLocations = phoneNumber   
        phoneLoaded  = true
    end
    goto afterNumberFetch

    ::useExistingNumber::
    phoneNumber = SavedLocations

    ::afterNumberFetch::
    debugprint("got number", phoneNumber)

    if not phoneNumber then
        debugprint("no number, checking if player has item")

        if HasPhoneItem() then
            debugprint("player has item; triggering phone:generatePhoneNumber")
            phoneNumber = AwaitCallback("generatePhoneNumber")
            debugprint("got number", phoneNumber)
        else
            debugprint("player does not have item")
        end
    end

    if not phoneNumber then
        isFetchingPhone = false

        if currentPhone then
            debugprint("no number. using SetPhone")
            SetPhone()
        end

        debugprint("no number, returning")
        return
    end

    local defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))

    local latestVersion  = AwaitCallback("getLatestVersion")
    local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)

    if not latestVersion then
        latestVersion = currentVersion
    end

    defaultSettings.locale        = Config.DefaultLocale
    defaultSettings.version       = currentVersion
    defaultSettings.latestVersion = latestVersion

    local isSetup = false
    debugprint("fetching phone data")
    local phoneDataFromServer = AwaitCallback("getPhone", phoneNumber)
    debugprint("got phone data", json.encode(phoneDataFromServer))

    if phoneDataFromServer then
        
        if phoneDataFromServer.settings then
            defaultSettings = phoneDataFromServer.settings
        end

        if phoneDataFromServer.name then
            defaultSettings.name = phoneDataFromServer.name
        else
            
            local charName = AwaitCallback("getCharacterName")
            defaultSettings.name = L("BACKEND.MISC.X_PHONE", {
                name     = charName.firstname,
                lastname = charName.lastname,
            })
        end

        defaultSettings.version       = currentVersion
        defaultSettings.latestVersion = latestVersion

        local savedLocs = AwaitCallback("maps:getSavedLocations")
        SavedLocations  = savedLocs

        isSetup = phoneDataFromServer.is_setup or isSetup
        if not phoneDataFromServer.is_setup then
            isSetup = false
        end

        currentPhone = phoneNumber

        local newPhoneData = {
            isSetup          = isSetup,
            phoneNumber      = phoneNumber,
            settings         = defaultSettings,
        }

        local batteryLevel
        if Config.Battery and Config.Battery.Enabled then
            batteryLevel = phoneDataFromServer.battery
        end
        if not batteryLevel then
            batteryLevel = 100
        end
        newPhoneData.battery = batteryLevel

        newPhoneData.serverIdentifier = GetCurrentServerEndpoint()

        phoneData = newPhoneData

        WaitForConfig()

        debugprint("triggering phone:setPhoneData")
        SendNUIAction("setPhoneData", phoneData)

        TriggerEvent("lb-phone:numberChanged", phoneNumber)

        Wait(250)
    end

    if FetchCryptoCoins then
        FetchCryptoCoins()
    end

    settings        = defaultSettings
    isFetchingPhone = false
end

FetchPhone = FetchPhone  

local function RefreshPhone(onlyConfig)
    debugprint("RefreshPhone triggered")

    if isFetchingPhone then
        debugprint("phone is being fetched, waiting before refreshing")
        while true do
            if not isFetchingPhone then
                break
            end
            Wait(0)
        end
    end

    if Config.DynamicWebRTC and Config.DynamicWebRTC.Enabled then
        local iceServers = AwaitCallback("getWebRTCCredentials")

        if Config.DynamicWebRTC.RemoveStun and iceServers then
            for i = #iceServers, 1, -1 do
                if not iceServers[i].credential then
                    table.remove(iceServers, i)
                end
            end
        end

        if iceServers then
            if not Config.RTCConfig then
                Config.RTCConfig = {}
            end
            Config.RTCConfig.iceServers = iceServers
        end
    end

    configReceivedByUI = false

    local configData = json.decode(GetConfigFile("config.json"))

    local valetConfig = {}
    valetConfig.enabled      = Config.Valet and Config.Valet.Enabled and true or false
    valetConfig.price        = Config.Valet and Config.Valet.Price or 0
    valetConfig.vehicleTypes = (Config.Valet and Config.Valet.VehicleTypes) or {"car"}
    configData.valet = valetConfig

    configData.locations = Config.Locations

    configData.AllowExternal             = Config.AllowExternal
    configData.ExternalBlacklistedDomains = Config.ExternalBlacklistedDomains
    configData.ExternalWhitelistedDomains = Config.ExternalWhitelistedDomains

    configData.EmailDomain        = Config.EmailDomain
    configData.RealTime           = Config.RealTime
    configData.CurrencyFormat     = Config.CurrencyFormat
    configData.DeleteMessages     = Config.DeleteMessages
    configData.Battery            = Config.Battery
    configData.rtc                = Config.RTCConfig
    configData.PromoteBirdy       = Config.PromoteBirdy
    configData.Verified           = Config.Verified
    configData.LiveTray           = Config.LiveTray
    configData.SetupScreen        = Config.SetupScreen
    configData.MaxTransferAmount  = Config.MaxTransferAmount
    configData.EnableMessagePay   = Config.EnableMessagePay
    configData.EnableGIFs         = Config.EnableGIFs
    configData.GIFsFilter         = Config.GIFsFilter or "low"
    configData.EnableVoiceMessages = Config.EnableVoiceMessages
    configData.DefaultLocale      = Config.DefaultLocale
    configData.DateLocale         = Config.DateLocale
    configData.Debug              = Config.Debug

    configData.TikTokTTS = Config.TrendyTTS or {{"English (US) - Female", "en_us_001"}}

    configData.recordNearbyVoices = Config.Voice and Config.Voice.RecordNearby

    configData.frameColor           = Config.FrameColor
    configData.allowFrameColorChange = Config.AllowFrameColorChange

    configData.unlockPhoneKey = Config.KeyBinds
        and Config.KeyBinds.UnlockPhone
        and Config.KeyBinds.UnlockPhone.Bind
        or nil

    configData.DeleteMail     = Config.DeleteMail
    configData.ChangePassword = Config.ChangePassword
    configData.DeleteAccount  = Config.DeleteAccount

    configData.CustomCamera = (Config.Camera and Config.Camera.Walkable) or false

    configData.UsernameFilter = (Config.UsernameFilter and Config.UsernameFilter.Regex) or "[a-zA-Z0-9]+"

    if Config.Crypto and Config.Crypto.Limits then
        configData.CryptoLimit = Config.Crypto.Limits
    else
        configData.CryptoLimit = {Buy = 1000000, Sell = 1000000}
    end

    configData.Browser    = Config.Browser
    configData.CustomMaps = Config.CustomMaps

    configData.sound = {
        system           = Config.Sound and Config.Sound.System,
        ringtones        = Config.Sound and Config.Sound.Ringtones,
        notifications    = Config.Sound and Config.Sound.Notifications,
        appNotifications = Config.Sound and Config.Sound.AppNotifications,
    }

    configData.AppDownloadTime = Config.AppDownloadTime
    configData.Pages           = Config.Pages
    configData.Marketplace     = Config.Marketplace

    local numberLength = (Config.PhoneNumber and Config.PhoneNumber.Length) or 7
    local prefixLength = 0
    if Config.PhoneNumber
        and Config.PhoneNumber.Prefixes
        and #Config.PhoneNumber.Prefixes > 0
    then
        local firstPrefix = Config.PhoneNumber.Prefixes[1]
        if firstPrefix then
            prefixLength = #firstPrefix
        end
    end
    configData.PhoneNumberLength = numberLength + prefixLength
    configData.Format            = Config.PhoneNumber and Config.PhoneNumber.Format

    configData.imageOptions = {
        mime    = (Config.Image and Config.Image.Mime) or "image/png",
        quality = (Config.Image and Config.Image.Quality) or 1.0,
    }

    configData.videoOptions = {
        bitrate       = (Config.Video and Config.Video.Bitrate) or 250,
        audioBitrate  = (Config.Video and Config.Video.AudioBitrate) or 128,
        variableBitrate = (Config.Video and Config.Video.VariableBitrate) or false,
        size          = (Config.Video and Config.Video.MaxSize) or 10,
        duration      = (Config.Video and Config.Video.MaxDuration) or 60,
        fps           = (Config.Video and Config.Video.FrameRate) or 24,
    }

    configData.Companies = table.deep_clone(Config.Companies)

    if configData.Companies and configData.Companies.Services then
        for i = 1, #configData.Companies.Services do
            local service = configData.Companies.Services[i]
            if service.onCustomIconClick then
                service.onCustomIconClick = true  
            end
        end
    end

    if Config.CustomApps then
        for appKey, appData in pairs(Config.CustomApps) do
            configData.apps[appKey] = FormatCustomAppDataForUI(appData)
        end
    end

    for appKey, appData in pairs(configData.apps) do
        appData.access = HasAccessToApp(appKey)
    end

    configData.defaultSettings = json.decode(GetConfigFile("defaultSettings.json"))

    local function RemoveFromDefaultSettingsApps(appName)
        local pages = configData.defaultSettings.apps
        for pageIndex = 1, #pages do
            local page = pages[pageIndex]
            for slotIndex = 1, #page do
                if page[slotIndex] == appName then
                    table.remove(page, slotIndex)
                    break
                end
            end
        end
    end

    if Config.Framework == "standalone" and not Config.CustomFramework then
        configData.apps.Wallet   = nil
        configData.apps.Home     = nil
        configData.apps.Garage   = nil
        configData.apps.Services = nil
        RemoveFromDefaultSettingsApps("Wallet")
        RemoveFromDefaultSettingsApps("Home")
        RemoveFromDefaultSettingsApps("Garage")
        RemoveFromDefaultSettingsApps("Services")
    end

    if not Config.HouseScript then
        configData.apps.Home = nil
        debugprint("No Config.HouseScript, removed home app")
        RemoveFromDefaultSettingsApps("Home")
    end

    if not (Config.Crypto and Config.Crypto.Enabled) then
        configData.apps.Crypto = nil
        debugprint("Config.Crypto not enabled, removed crypto app")
        RemoveFromDefaultSettingsApps("Crypto")
    end

    for appKey, isHidden in pairs(GetHiddenApps()) do
        if configData.apps[appKey] then
            configData.apps[appKey].hidden = isHidden
        end
    end

    SendNUIAction("setConfig", configData)

    WaitForConfig()

    if phoneData then
        debugprint("phoneData is defined")
        SendNUIAction("setPhoneData", phoneData)
        return
    end

    if onlyConfig then
        return
    end

    FetchPhone()
end

RefreshPhone = RefreshPhone

RegisterNetEvent("lb-phone:jobUpdated")
AddEventHandler("lb-phone:jobUpdated", function(jobInfo)
    
    if not Config.WhitelistApps and not Config.BlacklistApps then
        return
    end

    debugprint("Job updated, refreshing whitelisted & blacklisted apps")

    local accessMap = {}

    for appKey in pairs(Config.WhitelistApps) do
        accessMap[appKey] = HasAccessToApp(appKey, jobInfo.job, jobInfo.grade)
    end

    for appKey in pairs(Config.BlacklistApps) do
        accessMap[appKey] = HasAccessToApp(appKey, jobInfo.job, jobInfo.grade)
    end

    for appKey in pairs(Config.CustomApps) do
        accessMap[appKey] = HasAccessToApp(appKey, jobInfo.job, jobInfo.grade)
    end

    SendNUIAction("app:setHasAccess", accessMap)
end)

RegisterNUICallback("configReceived", function(data, cb)
    debugprint("UI has received the config (configReceived triggered)")
    configReceivedByUI = true
    cb("ok")
end)

RegisterNUICallback("getPhoneData", function(data, cb)
    debugprint("getPhoneData triggered")

    while true do
        if FrameworkLoaded then
            break
        end
        Wait(500)
    end

    Wait(1000)
    RefreshPhone()

    if not cb then
        debugprint("cb is not defined in getPhoneData", data)
        return
    end

    cb(true)
end)

local function DisableControlsWhileOpen()
    local playerId = PlayerId()

    while phoneOpen do
        Wait(0)

        DisableControlAction(0, 199, true)  
        DisableControlAction(0, 200, true)  
        DisableControlAction(0, 24,  true)  
        DisableControlAction(0, 25,  true)  
        DisableControlAction(0, 69,  true)  
        DisableControlAction(0, 70,  true)  
        DisableControlAction(0, 91,  true)  
        DisableControlAction(0, 92,  true)  
        DisableControlAction(0, 106, true)  
        DisableControlAction(0, 114, true)  
        DisableControlAction(0, 140, true)  
        DisableControlAction(0, 141, true)  
        DisableControlAction(0, 142, true)  
        DisableControlAction(0, 257, true)  
        DisableControlAction(0, 263, true)  
        DisableControlAction(0, 264, true)  
        DisableControlAction(0, 330, true)  
        DisableControlAction(0, 331, true)  

        DisablePlayerFiring(playerId, true)

        if IsNuiFocused() then
            DisableControlAction(0, 1,   true)  
            DisableControlAction(0, 2,   true)  
            DisableControlAction(0, 245, true)  
            DisableControlAction(0, 14,  true)  
            DisableControlAction(0, 15,  true)  
            DisableControlAction(0, 16,  true)  
            DisableControlAction(0, 17,  true)  
            DisableControlAction(0, 37,  true)  
            DisableControlAction(0, 50,  true)  
            DisableControlAction(0, 99,  true)  
            DisableControlAction(0, 115, true)  
            DisableControlAction(0, 180, true)  
            DisableControlAction(0, 181, true)  
            DisableControlAction(0, 198, true)  
            DisableControlAction(0, 241, true)  
            DisableControlAction(0, 242, true)  
            DisableControlAction(0, 261, true)  
            DisableControlAction(0, 262, true)  
            DisableControlAction(0, 85,  true)  
        end
    end

    while true do
        local stillPressed = IsDisabledControlPressed(0, 200)
        if not stillPressed then
            break
        end
        DisableControlAction(0, 200, true)
        Wait(0)
    end

    if cameraOpen then
        if IsWalkingCamEnabled() then
            local wasSelfie = IsSelfieCam()
            DisableWalkableCam()

            while true do
                if phoneOpen then
                    break
                end
                Wait(500)
            end

            if cameraOpen then
                SetPhoneAction("camera")
                EnableWalkableCam(wasSelfie)
            end
        end
    end
end

local isTogglingOpen = false  

local function ToggleOpen(open, keepFocus)
    local calledBy = GetInvokingResource()

    if isTogglingOpen then
        return
    end

    if type(open) ~= "boolean" then
        open = not phoneOpen
    end
    open = (open == true)

    debugprint("ToggleOpen(" .. tostring(open) .. ", " .. tostring(keepFocus) .. ")", "triggered by", calledBy)

    if phoneDisabled and open then
        debugprint("phone is disabled, returning")
        return
    end

    if phoneOpen == open then
        debugprint("phoneOpen & open are both the same value, returning")
        return
    end

    if not FrameworkLoaded and open then
        infoprint("warning", "Framework not loaded")
        return
    end

    if open then
        local ped  = PlayerPedId()
        local dead = IsPedDeadOrDying(ped, true)
        if dead then
            debugprint("player ped is dead/dying, returning")
            return
        end
    end

    if open then
        if CanOpenPhone then
            if not CanOpenPhone() then
                debugprint("CanOpenPhone returned false, returning")
                return
            end
        end
    end

    if open then
        if not ValidateChecks("openPhone") then
            debugprint("ValidateChecks returned false for openPhone, returning")
            return
        end
    end

    if open then
        if IsNuiFocused() then
            if Config.DisableOpenNUI then
                infoprint("info", "Not opening the phone as another script has NUI focus. You can disable this behavior by setting Config.DisableOpenNUI to false.")
                return
            end
        end
    end

    if open then
        if GetResourceState("lb-tablet") == "started" then
            if not Config.DisableTabletOpenPhone then
                local ok, tabletOpen = pcall(function()
                    return exports["lb-tablet"]:IsOpen()
                end)
                if ok and tabletOpen then
                    infoprint("info", "Not opening the phone as the tablet is open. You can disable this behavior by adding Config.DisableTabletOpenPhone = true to the config.")
                    return
                end
            end
        end
    end

    if isFetchingPhone then
        isTogglingOpen = true
        while true do
            if not isFetchingPhone then
                break
            end
            Wait(0)
        end
        isTogglingOpen = false
    end

    if open then
        if not currentPhone then
            debugprint("no phone, fetching")
            FetchPhone()
            if not currentPhone then
                debugprint("still no phone after fetching, returning")
                return
            end
        end
    end

    if open then
        local hasItem = HasPhoneItem(currentPhone)
        if not hasItem then
            debugprint("HasPhoneItem returned false. Phone number:", tostring(currentPhone))
            TriggerServerEvent("phone:togglePhone")
            SendNUIAction("closePhone")
            return
        end
    end

    if not open then
        if IsWalkingCamEnabled() then
            if IsSelfieCam() then
                ToggleSelfieCam(false)
            end
        end
    end

    if not open then
        if Config.EndLiveClose then
            local liveData = IsWatchingLive()
            EndLive()
            if liveData then
                SendNUIAction("instagram:liveEnded", liveData)
            end
        end
    end

    phoneOpen      = open
    isTogglingOpen = true

    if open then
        
        debugprint("should open phone. sending openPhone event to ui")
        SendNUIAction("openPhone")

        if not keepFocus then
            SetNuiFocus(true, true)
            SetNuiFocusKeepInput(Config.KeepInput)
        end

        if Config.KeepInput then
            CreateThread(DisableControlsWhileOpen)
        end

        if ControllerThread then
            CreateThread(ControllerThread)
        end

        debugprint("setting animation action")

        if IsWalkingCamEnabled() then
            SetPhoneAction("camera")
        elseif IsInCall() then
            SetPhoneAction("call")
        else
            SetPhoneAction("default")
        end
    else
        
        debugprint("sending closePhone event to ui")
        PlayCloseAnim()
        SetNuiFocus(false, false)
        SetNuiFocusKeepInput(false)
        SendNUIAction("closePhone")
    end

    TriggerServerEvent("phone:togglePhone", open)
    TriggerEvent("lb-phone:phoneToggled", open)

    isTogglingOpen = false
end

ToggleOpen = ToggleOpen

RegisterNUICallback("toggleInput", function(hasFocus, cb)
    cb("ok")

    if not Config.KeepInput then
        return
    end

    local function isPttActive()
        if Config.DisableFocusTalking then
            if IsDisabledControlPressed(0, 249) then
                return true
            end
        end
        return IsDisabledControlJustReleased(0, 249)
    end

    if isPttActive() then
        if hasFocus then
            
            debugprint("PTT is pressed, ignoring toggle focus")
            return
        end

        debugprint("PTT is pressed, waiting before toggling focus")
        while true do
            local stillActive = isPttActive()
            if not stillActive then
                break
            end
            Wait(100)
        end
    end

    if hasFocus then
        Wait(200)
    end

    SetNuiFocusKeepInput(not hasFocus)
end)

local focusTogglePending = false  

AddEventHandler("lb-phone:keyPressed", function(action)
    
    if IsPauseMenuActive() then
        return
    end

    if action == "Open" then
        debugprint("Pressed open keybind")
        ToggleOpen(not phoneOpen)

    elseif action == "Focus" then
        
        if not phoneOpen or focusTogglePending then
            return
        end

        local function isPttPressed()
            if Config.DisableFocusTalking then
                if IsDisabledControlPressed(0, 249) then
                    return true
                end
            end
            return IsDisabledControlJustReleased(0, 249)
        end

        if isPttPressed() then
            debugprint("PTT is pressed, waiting before toggling focus")
            focusTogglePending = true
            while true do
                if not IsDisabledControlPressed(0, 249)
                   and not IsDisabledControlJustReleased(0, 249)
                then
                    break
                end
                Wait(0)
            end
            focusTogglePending = false
        end

        local nuiFocused = IsNuiFocused()
        SetNuiFocus(not nuiFocused, not nuiFocused)

        if not nuiFocused then
            
            SetNuiFocusKeepInput(Config.KeepInput)
        else
            
            SetNuiFocusKeepInput(false)
        end

    elseif action == "StopSounds" then
        SendNUIAction("stopSounds")
    end

    if action == "AnswerCall" or action == "DeclineCall" then
        
        if CanOpenPhone then
            if not CanOpenPhone() then
                debugprint("CanOpenPhone returned false, not answering/declining call")
                return
            end
        else
            if not ValidateChecks("openPhone") then
                debugprint("ValidateChecks returned false for openPhone, not answering/declining call")
                return
            end
        end

        if action == "AnswerCall" then
            SendNUIAction("usedCommand", "answer")
        elseif action == "DeclineCall" then
            SendNUIAction("usedCommand", "decline")
        end
    end

    if action == "TakePhoto" then
        SendNUIAction("camera:usedCommand", "toggleTaking")
    elseif action == "ToggleFlash" then
        SendNUIAction("camera:usedCommand", "toggleFlash")
    elseif action == "LeftMode" then
        SendNUIAction("camera:usedCommand", "leftMode")
    elseif action == "RightMode" then
        SendNUIAction("camera:usedCommand", "rightMode")
    elseif action == "FlipCamera" then
        SendNUIAction("camera:usedCommand", "toggleFlip")
    end
end)

for keyName, keyConfig in pairs(Config.KeyBinds) do
    if keyConfig.Command then
        
        keyConfig.Command = keyConfig.Command:lower()

        if keyConfig.Bind then
            
            keyConfig.bindData = AddKeyBind({
                name            = keyConfig.Command,
                description     = keyConfig.Description or "no description",
                defaultKey      = keyConfig.Bind,
                defaultMapper   = keyConfig.Mapper,
                secondaryKey    = keyConfig.SecondaryBind,
                secondaryMapper = keyConfig.SecondaryMapper,

                onPress = function()
                    TriggerEvent("lb-phone:keyPressed", keyName)
                end,

                onRelease = function(duration)
                    
                    TriggerEvent("lb-tablet:keyReleased", keyName, duration)
                end,
            })
        else
            
            RegisterCommand(keyConfig.Command, function()
                TriggerEvent("lb-phone:keyPressed", keyName)
                Wait(0)
                TriggerEvent("lb-phone:keyReleased", keyName, 0)
            end, false)
        end
    end
end

RegisterNUICallback("finishedSetup", function(setupData, cb)
    if phoneData then
        phoneData.isSetup = true
    end

    SendNUIAction("setName", setupData.name)
    TriggerServerEvent("phone:setName", setupData.name)
    TriggerServerEvent("phone:togglePhone", phoneOpen)
    TriggerServerEvent("phone:finishedSetup", setupData)

    if Config.AutoBackup then
        TriggerCallback("backup:createBackup")
    end

    cb("ok")
end)

RegisterNUICallback("isAdmin", function(data, cb)
    TriggerCallback("isAdmin", cb)
end)

RegisterNUICallback("setPhoneName", function(name, cb)
    local isSetup = phoneData and phoneData.isSetup

    if isSetup then
        if settings then
            settings.name = name
        end
        TriggerServerEvent("phone:setName", name)
    end

    cb("ok")
end)

RegisterNUICallback("setSettings", function(newSettings, cb)
    debugprint("setSettings triggered")
    cb("ok")

    if not phoneData then
        print("setSettings triggered, but phoneData is nil")
        return
    end

    settings           = newSettings
    phoneData.settings = settings

    AwaitCallback("setSettings", settings)

    SetCallVolume(settings and settings.sound and settings.sound.callVolume)

    TriggerEvent("lb-phone:settingsUpdated", newSettings)

    SendNUIAction("customApp:sendMessage", {
        identifier = "any",
        message    = {
            type    = "settingsUpdated",
            settings = settings,
            action  = "settingsUpdated",
            data    = newSettings,
        },
    })
end)

RegisterNUICallback("setCursorLocation", function(pos, cb)
    local screenX, screenY = GetActiveScreenResolution()
    SetCursorLocation(pos.x / screenX, pos.y / screenY)
    cb("ok")
end)

RegisterNUICallback("exitFocus", function(data, cb)
    debugprint("exitFocus triggered")
    SetNuiFocus(false, false)
    ToggleOpen(false)
    cb("ok")
end)

RegisterNUICallback("getLocales", function(data, cb)
    local locales = Config.Locales or {en = "English"}
    cb(locales)
end)

RegisterNUICallback("setOnScreen", function(onScreen, cb)
    onScreen = (onScreen == true)

    if onScreen ~= PhoneOnScreen then
        TriggerEvent("lb-phone:setOnScreen", onScreen)
        PhoneOnScreen = onScreen
    end

    cb("ok")
end)

RegisterNUICallback("restartPhone", function(data, cb)
    cb("ok")
    ToggleOpen(false)
    Wait(1000)
    ToggleOpen(true)
end)

exports("IsPhoneOnScreen", function()
    return PhoneOnScreen
end)

CreateThread(function()
    local lastTime = {}

    debugprint("Waiting for currentPhone to be set before updating time & service")

    while true do
        if currentPhone then
            break
        end
        Wait(500)
    end

    local serviceBars, _ = GetServiceBars()
    SendNUIAction("updateService", serviceBars)

    debugprint("currentPhone is set, updating time & service")

    while true do
        
        if Config.RealTime then
            break  
        end

        local currentTime
        if Config.CustomTime then
            currentTime = Config.CustomTime()
        end

        if not currentTime then
            currentTime = {
                hour   = GetClockHours(),
                minute = GetClockMinutes(),
            }
        end

        if currentTime.hour ~= lastTime.hour or currentTime.minute ~= lastTime.minute then
            lastTime.hour   = currentTime.hour
            lastTime.minute = currentTime.minute
            SendNUIAction("updateTime", currentTime)
        end

        Wait(1000)
    end
end)

local function GetConfigFile(filename)
    return LoadResourceFile(GetCurrentResourceName(), "config/" .. filename)
end

GetConfigFile = GetConfigFile

RegisterNUICallback("getConfigFile", function(fileName, cb)
    local rawContent = GetConfigFile(fileName .. ".json")
    local decoded    = json.decode(rawContent)
    cb(decoded)
end)

local nearbyPlayers  = {}
local lastPlayerPos  = vector3(0.0, 0.0, 0.0)
local lastCacheTime  = 0

local function RebuildNearbyPlayers()
    local myCoords  = GetEntityCoords(PlayerPedId())
    local allPlayers = GetActivePlayers()
    local result    = {}

    for i = 1, #allPlayers do
        local player = allPlayers[i]

        if player ~= PlayerId() then
            local ped    = GetPlayerPed(player)
            local coords = GetEntityCoords(ped)
            local dist   = #(myCoords - coords)

            if dist <= 50.0 then
                result[#result + 1] = {
                    player = player,
                    source = GetPlayerServerId(player),
                    ped    = ped,
                    coords = coords,
                }
            end
        end
    end

    nearbyPlayers = result
end

local function GetNearbyPlayers()
    local now      = GetGameTimer()
    local elapsed  = now - lastCacheTime
    local myCoords = GetEntityCoords(PlayerPedId())
    local moved    = #(myCoords - lastPlayerPos)

    if elapsed > 5000 or moved > 25.0 then
        lastCacheTime  = now
        lastPlayerPos  = myCoords
        RebuildNearbyPlayers()
    end

    return nearbyPlayers
end

GetNearbyPlayers = GetNearbyPlayers

local function LogOut()
    debugprint("LogOut triggered")

    while true do
        if not isFetchingPhone then
            break
        end
        debugprint("LogOut triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    ResetSecurity()
    OnDeath()

    phoneData    = nil
    currentPhone = nil
    settings     = nil

    TriggerEvent("lb-phone:numberChanged", nil)
    TriggerCallback("setLastPhone")
end

LogOut = LogOut

local function SetPhone(phoneNumber, forceRefetch)
    debugprint("SetPhone triggered", phoneNumber, forceRefetch)

    while true do
        if not isFetchingPhone then
            break
        end
        debugprint("SetPhone triggered, waiting for fetchingPhone to finish...")
        Wait(500)
    end

    OnDeath()
    AwaitCallback("setLastPhone", phoneNumber)
    ResetSecurity(true)
    ToggleCharging(false)

    phoneData    = nil
    currentPhone = nil
    settings     = nil

    TriggerEvent("lb-phone:numberChanged", nil)

    if phoneNumber or forceRefetch then
        FetchPhone()
    end

    if phoneNumber == nil and not forceRefetch then
        local firstNumber = GetFirstNumber()
        if firstNumber then
            SetPhone(firstNumber)
        end
    end
end

SetPhone = SetPhone

local function OnDeath()
    debugprint("OnDeath triggered")

    local liveData = IsWatchingLive()
    EndLive()
    if liveData then
        SendNUIAction("instagram:liveEnded", liveData)
    end

    if flashlightEnabled then
        flashlightEnabled = false
        TriggerServerEvent("phone:toggleFlashlight", false)
    end

    EndCall()
    ToggleOpen(false)
end

_G.OnDeath = OnDeath

RegisterNetEvent("phone:toggleOpen", ToggleOpen)

exports("ToggleOpen", ToggleOpen)

exports("IsOpen", function()
    return phoneOpen
end)

exports("IsDisabled", function()
    return phoneDisabled
end)

exports("ToggleDisabled", function(disabled)
    phoneDisabled = (disabled == true)
    debugprint("ToggleDisabled triggered", phoneDisabled)

    if phoneDisabled and phoneOpen then
        ToggleOpen(false)
    end
end)

exports("GetSettings", function()
    return settings
end)

exports("GetAirplaneMode", function()
    return settings and settings.airplaneMode
end)

exports("GetStreamerMode", function()
    return settings and settings.streamerMode
end)

exports("GetEquippedPhoneNumber", function()
    return currentPhone
end)

