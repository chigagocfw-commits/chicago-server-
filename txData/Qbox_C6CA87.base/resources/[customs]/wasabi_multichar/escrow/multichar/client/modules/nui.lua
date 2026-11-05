local NuiController = lib.class("NuiController")
local TIMEOUT_MS = 10000
local DEFAULT_UI_COLOR = "#29b181"

function FindFirstAvailableCharacterSlot(characters, excludeSlot)
    if not characters then
        return nil
    end

    local firstSlot = nil

    for _, entry in ipairs(characters) do
        if entry.character and entry.character.id then
            if not firstSlot then
                firstSlot = entry.slot
            end
            if excludeSlot and entry.slot ~= excludeSlot then
                return entry.slot
            end
        end
    end

    return firstSlot
end

function GetThemeUIColor()
    if type(Config.UIColor) == "string" and Config.UIColor ~= "" then
        return Config.UIColor
    end
    return DEFAULT_UI_COLOR
end

function NuiController:scheduleMulticharCameraFocus(characters)
    local targetSlot = FindFirstAvailableCharacterSlot(characters, nil)
    local pedController = self.pedController

    if not targetSlot or not pedController then
        return targetSlot
    end

    local delay = 0
    if Config.AutoFocusFirstCharacter == false then
        delay = Config.FirstOpenIntroDelay or 4000
    end

    CreateThread(function()
        while not IsScreenFadedIn() do
            Wait(10)
        end

        if delay > 0 then
            Wait(delay)
        end

        if self.isOpen and pedController then
            pedController:setCameraToSlot(targetSlot)
        end
    end)

    return targetSlot
end

function NuiController:sendUiTheme()
    SendNUIMessage({
        action = "SET_UI_THEME",
        data = {
            uiColor = GetThemeUIColor()
        }
    })
end

function NuiController:constructor(pedController)
    self.isOpen = false
    self.hasCompletedFirstOpen = false
    self.pedController = pedController
    self.welcomeCam = nil
    self.nuiReady = false
    self.welcomeActive = false
    self.welcomeTransitioning = false

    self:registerCallbacks()
end

function NuiController:sendWelcome()
    if not (self.nuiReady and self.welcomeActive) then
        return
    end

    local playerName = GetPlayerName(PlayerId()) or ""

    SendNUIMessage({
        action = "WELCOME",
        data = {
            playername = playerName
        }
    })
end

function NuiController:waitForNuiReady()
    local expiryTime = GetGameTimer() + TIMEOUT_MS

    while not self.nuiReady and expiryTime > GetGameTimer() do
        Wait(50)
    end
end

function NuiController:getWelcomeCamPos()
    if Config.WelcomeCam then
        local cam = Config.WelcomeCam
        local x = cam.x or cam[1]
        local y = cam.y or cam[2]
        local z = cam.z or cam[3]

        if x and y and z then
            return x, y, z
        end
    end

    if Config.PreviewLocations then
        for _, location in pairs(Config.PreviewLocations) do
            local startCam = location.startCam or (location.cinematicCam and location.cinematicCam.pos)
            if startCam then
                local x = startCam.x or startCam[1]
                local y = startCam.y or startCam[2]
                local z = startCam.z or startCam[3]

                if x and y and z then
                    return x, y, z
                end
            end
        end
    end

    return -1720.766, -1180.8932, 27.7457
end

function NuiController:startWelcomeScreen()
    self.welcomeActive = true
    self.welcomeTransitioning = false

    local playerPed = PlayerPedId()
    SetEntityVisible(playerPed, false, false)
    FreezeEntityPosition(playerPed, true)

    local camX, camY, camZ = self:getWelcomeCamPos()
    SetEntityCoords(playerPed, camX, camY, camZ, false, false, false, false)

    self.welcomeCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camX, camY, camZ,
        0.0, 0.0, 289.6153,
        60.0,
        false, 0
    )

    SetCamActive(self.welcomeCam, true)
    RenderScriptCams(true, false, 1, true, true)
    ShakeCam(self.welcomeCam, "HAND_SHAKE", 0.35)

    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.4)

    SetNuiFocus(true, true)
    self:sendUiTheme()
    self:sendWelcome()

    Wait(200)
    DoScreenFadeIn(1000)
end

function NuiController:finishWelcomeAndShowMultichar()
    if self.welcomeTransitioning then
        return
    end

    self.welcomeTransitioning = true
    self.welcomeActive = false

    SendNUIMessage({ action = "HIDE_WELCOME" })
    DoScreenFadeOut(900)

    while not IsScreenFadedOut() do
        Wait(10)
    end

    Wait(150)

    if self.welcomeCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(self.welcomeCam, false)
        self.welcomeCam = nil
    end

    Wait(100)
    self.hasCompletedFirstOpen = true

    local characters = lib.callback.await("wasabi_multichar:getCharacters", false)

    if self.pedController and Config.PreviewLocations then
        self.pedController:loadScene(characters)
        if characters then
            self.pedController:setPedsFromCharacters(characters)
        end
    end

    Wait(500)

    local focusSlot = self:scheduleMulticharCameraFocus(characters)
    self:sendUiTheme()

    SendNUIMessage({
        action = "SHOW_MULTICHAR",
        data = {
            characters = characters,
            focusSlot = focusSlot
        }
    })

    DoScreenFadeIn(1200)
end

function NuiController:open()
    if self.isOpen then
        return
    end

    self.isOpen = true

    if not self.hasCompletedFirstOpen then
        DoScreenFadeOut(0)
        Wait(3000)

        TriggerServerEvent("wasabi_multichar:setNewWorld", cache.serverId)
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()

        DoScreenFadeOut(0)
        Wait(100)

        self:waitForNuiReady()
        self:startWelcomeScreen()
        return
    end

    SetNuiFocus(true, true)

    local characters = lib.callback.await("wasabi_multichar:getCharacters", false)

    if self.pedController and Config.PreviewLocations then
        self.pedController:loadScene(characters)
        if characters then
            self.pedController:setPedsFromCharacters(characters)
        end
    end

    local focusSlot = self:scheduleMulticharCameraFocus(characters)
    self:sendUiTheme()

    SendNUIMessage({
        action = "SHOW_MULTICHAR",
        data = {
            characters = characters,
            focusSlot = focusSlot
        }
    })
end

function NuiController:close()
    if not self.isOpen then
        return
    end

    self.isOpen = false
    self.welcomeActive = false
    self.welcomeTransitioning = false

    SetNuiFocus(false, false)
    SendNUIMessage({ action = "HIDE_MULTICHAR" })

    if self.welcomeCam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(self.welcomeCam, false)
        self.welcomeCam = nil
    end

    if self.pedController then
        self.pedController:destroy()
    end
end

function NuiController:hideNui()
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "HIDE_MULTICHAR" })
end

function NuiController:resetFirstOpen()
    self.hasCompletedFirstOpen = false
    self.welcomeActive = false
    self.welcomeTransitioning = false
end

function NuiController:isUIOpen()
    return self.isOpen
end

function NuiController:refreshCharacters(characters, focusSlot)
    if not characters then
        characters = lib.callback.await("wasabi_multichar:getCharacters", false)
    end

    if self.pedController and Config.PreviewLocations and characters then
        self.pedController:setPedsFromCharacters(characters)
    end

    local targetSlot = nil
    if focusSlot then
        targetSlot = FindFirstAvailableCharacterSlot(characters, focusSlot)
    end

    if targetSlot and self.pedController then
        self.pedController:setCameraToSlot(targetSlot)
    end

    SendNUIMessage({
        action = "REFRESH_CHARACTERS",
        data = {
            characters = characters,
            focusSlot = targetSlot
        }
    })
end

function NuiController:registerCallbacks()
    RegisterNUICallback("NUI_READY", function(data, cb)
        self.nuiReady = true
        self:sendWelcome()
        cb({ ok = true })
    end)

    RegisterNUICallback("GET_CONFIG", function(data, cb)
        cb(Config)
    end)

    RegisterNUICallback("WELCOME_ENTER", function(data, cb)
        if self.isOpen and not self.hasCompletedFirstOpen then
            self:finishWelcomeAndShowMultichar()
        end
        cb({ success = true })
    end)

    RegisterNUICallback("GET_MULTICHAR_CONFIG", function(data, cb)
        local slotConfig = lib.callback.await("wasabi_multichar:getSlotConfig", false)
        local permissions = lib.callback.await("wasabi_multichar:getPermissions", false)

        local purchaseUrl = ""
        if Config.PurchaseUrl and Config.PurchaseUrl ~= "" then
            purchaseUrl = Config.PurchaseUrl
        elseif Config.WebstoreLink then
            purchaseUrl = Config.WebstoreLink
        end

        local responseData = {
            maxSlots = (slotConfig and slotConfig.maxSlots) or Config.MaxSlots,
            normalSlots = (slotConfig and slotConfig.normalSlots) or Config.MaxSlots,
            vipSlots = (slotConfig and slotConfig.vipSlots) or 0,
            purchaseUrl = purchaseUrl,
            canRedeemSlot = (slotConfig and slotConfig.canRedeemSlot) or false,
            statFields = Config.StatFields,
            nationalities = Config.Nationalities,
            canDelete = (permissions and permissions.canDelete) or false,
            canLogout = permissions == nil or permissions.canLogout,
            uiColor = GetThemeUIColor()
        }

        cb(responseData)
    end)

    RegisterNUICallback("GET_CHARACTERS", function(data, cb)
        local characters = lib.callback.await("wasabi_multichar:getCharacters", false)
        cb(characters)
    end)

    RegisterNUICallback("PLAY_CHARACTER", function(data, cb)
        local slot = data.slot
        if not slot then
            cb({ success = false, error = "No slot provided" })
            return
        end

        self:hideNui()

        if self.pedController then
            self.pedController:stopCinematicCam()
        else
            DoScreenFadeOut(1500)
            while not IsScreenFadedOut() do
                Wait(10)
            end
        end

        self:close()
        TriggerServerEvent("wasabi_multichar:selectCharacter", slot)
        cb({ success = true })
    end)

    RegisterNUICallback("CREATE_CHARACTER", function(data, cb)
        if not (data.firstName and data.lastName and data.birthdate) then
            cb({ success = false, error = "Missing required fields" })
            return
        end

        local success, slotOrError = lib.callback.await("wasabi_multichar:createCharacter", false, data)
        if not success then
            cb({ success = false, error = slotOrError })
            return
        end

        cb({ success = true, slot = slotOrError })

        self:hideNui()

        if self.pedController then
            self.pedController:stopCinematicCam()
        else
            DoScreenFadeOut(1500)
            while not IsScreenFadedOut() do
                Wait(10)
            end
        end

        self:close()
        TriggerServerEvent("wasabi_multichar:selectCharacter", slotOrError)
    end)

    RegisterNUICallback("DELETE_CHARACTER", function(data, cb)
        if not Config.AllowDeletion then
            cb({ success = false, error = "Character deletion is disabled" })
            return
        end

        local slot = data.slot
        local characterId = data.characterId

        if not slot or not characterId then
            cb({ success = false, error = "Invalid character data" })
            return
        end

        local success, errorMessage = lib.callback.await("wasabi_multichar:deleteCharacter", false, slot, characterId)
        cb({
            success = success,
            error = (not success and errorMessage) or nil
        })
    end)

    RegisterNUICallback("QUIT", function(data, cb)
        cb({ success = true })
        self:close()

        CreateThread(function()
            Wait(200)
            TriggerServerEvent("wasabi_multichar:quit")
        end)
    end)

    RegisterNUICallback("OPEN_URL", function(data, cb)
        if data.url and data.url ~= "" then
            local cleanUrl = data.url:gsub("^https?://", "")
            lib.notify({
                title = "Purchase",
                description = "https://" .. cleanUrl,
                type = "inform"
            })
        end
        cb({ success = true })
    end)

    RegisterNUICallback("FOCUS_SLOT", function(data, cb)
        local slot = data and data.slot
        if slot and self.pedController then
            self.pedController:setCameraToSlot(slot)
        end
        cb({ success = true })
    end)

    RegisterNUICallback("REDEEM_SLOT", function(data, cb)
        local tebexId = data and data.tebexId
        if not tebexId or tebexId == "" then
            cb({ success = false, error = "No Tebex ID" })
            return
        end

        local success = lib.callback.await("wasabi_multichar:confirmTebexPurchase", false, tebexId)
        if success then
            self:refreshCharacters()
        end

        cb({ success = success })
    end)

    RegisterNUICallback("MUGSHOT_CAPTURED", function(data, cb)
        if data and data.handleId then
            UnregisterPedheadshot(data.handleId)
        end
        cb({ ok = true })
    end)
end

Modules.register("NuiController", NuiController)
