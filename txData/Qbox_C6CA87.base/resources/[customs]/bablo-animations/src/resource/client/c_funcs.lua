



-- ─────────────────────────────────────────────────
-- Main object definition
-- ─────────────────────────────────────────────────
Main = {
    animations          = {},
    keybinds            = {},
    currentBinds        = {},
    sequences           = {},
    props               = {},
    commandNames        = {},
    sharedAnimations    = {},
    skipAnimations      = {},
    hasProps            = false,
    inAction            = false,
    freeLook            = false,
    isLoaded            = false,
    isBusy              = false,
    onCooldown          = false,
    serverName          = "",
    currentGroup        = 0,
    onlyUpperBody       = false,
    particles           = {},
    isClosing           = false,
    disableModules      = false,
    playerSelectionActive = false,
    selectedPlayerIndex = 1,
    nearbyPlayersList   = {},
    currentAnimation    = nil,
    animSpeed           = 1.0,
    debugPlayerSelection = false,
    sharedPedState      = nil,
    testSharedPeds      = nil,
    NUIReady            = false,
}

-- ─────────────────────────────────────────────────
-- Main:Init(isReload)
-- Initialises the resource. isReload skips the
-- initial 2.5 s wait and animation conversion.
-- ─────────────────────────────────────────────────
function Main:Init(isReload)
    if not isReload then
        Citizen.Wait(2500)
    end

    -- Wait for Config.Convert to be populated
    local warned = false
    while not isReload do
        if Config and Config.Convert then break end
        if not warned then
            Trace("Waiting for Config to be ready...")
            warned = true
        end
        Citizen.Wait(0)
    end

    -- Merge Config.Custom overrides into Config tables
    if not isReload then
        for tblName, overrideTable in pairs(Config.Custom) do
            if Config[tblName] then
                for key, value in pairs(overrideTable) do
                    Config[tblName][key] = value
                end
            end
        end
        Config.Custom = nil
        self:convertAnimations()
    end

    -- Wait for character identifier (required for character-specific keybinds)
    if Config.CharacterSpecific and Config.CharacterSpecific.keybinds then
        local attempts = 0
        while attempts < 400 do
            if Framework and Framework.getCharacterIdentifier then
                if Framework:getCharacterIdentifier() then break end
            end
            Citizen.Wait(25)
            attempts = attempts + 1
        end
    end

    -- Fetch server convars (server name, saved data)
    local result = TriggerServerCallback({
        eventName = eventName .. "server:getConvars",
        args      = {},
    })

    if result.status then
        local cacheData, isNewServer = self:getCache(result.serverName)
        if not isNewServer then
            -- Returning player: restore saved data
            self.currentBinds = cacheData.keybinds
            self:setupSequences(cacheData.sequences)
            self:formatKeybinds(Config.Keybinds, cacheData.keybinds)
            self:formatAnimations(Config.Animations, cacheData.favorites, cacheData.keybinds)
        else
            -- New server / first time: start with empty saved data
            Trace("New server detected, fetching animations data")
            self:formatKeybinds(Config.Keybinds, {})
            self:formatAnimations(Config.Animations, {}, {})
        end

        if not cacheData.settings then
            cacheData.settings = Config.DefaultSettings
        end
        self:setSettings(cacheData.settings)
    else
        Trace("Failed to fetch animations data")
        self:formatKeybinds(Config.Keybinds, {})
        self:formatAnimations(Config.Animations, {}, {})
        self:setSettings(Config.DefaultSettings)
    end

    -- Push locale and initial menu data to NUI
    local locale = Locales[Config.Locale]
    locale.EMOTE_COMMAND_HINT = Config.EmoteCommand

    self:sendReactMessage("SET_MENU", {
        categories   = self:getCategories(),
        disablePreview = Config.DisablePreviews,
        translate    = locale,
        sequences    = self.sequences,
        closeKeys    = Config.CloseMenuKeys,
    })

    self.isLoaded = true
    self:sendAnimationsInBatches()

    if Config.DisableIdleCamera then
        DisableIdleCamera(true)
    end

    -- Reload keybinds and favourites after a short delay (ensures character ID is ready)
    Citizen.CreateThread(function()
        Citizen.Wait(3000)
        self:reloadKeybinds()
        self:reloadFavorites()
        print("Keybinds and favorites reloaded after delay")
    end)

    self:sendReactMessage("SET_VISIBLE", true)

    if isReload then return end

    self:handleWeaponStyle()

    -- Load keybind controls from JSON
    local controlsJson = LoadResourceFile(GetCurrentResourceName(), "controls.json")
    self.rawControls   = json.decode(controlsJson)
    self:getActiveControls(self.rawControls)

    -- Wait until active controls are resolved
    while not self.activeControls do Wait(0) end
    Trace("Main loop started")

    -- Main per-frame keybind check thread
    Citizen.CreateThread(function()
        local shiftHeld = false
        while true do
            Citizen.Wait(0)

            -- Disable crouch key when the module is active
            if Config.Modules.Crouch and not self.disableModules then
                DisableControlAction(0, 36, true)
            end

            -- Keybind shortcut detection (Shift + key)
            if not Config.DisableKeybinds then
                local shiftNormal   = IsControlPressed(0, 21)
                local shiftDisabled = IsDisabledControlPressed(0, 21)
                if shiftNormal or shiftDisabled then
                    for keyName, keyCode in pairs(self.activeControls) do
                        local upperKey = string.upper(keyName)
                        local released = IsControlJustReleased(0, keyCode)
                            or IsDisabledControlJustReleased(0, keyCode)

                        local triggered = false
                        if shiftNormal and released then
                            triggered = true
                        elseif shiftDisabled and IsDisabledControlJustReleased(0, keyCode) then
                            triggered = true
                        end

                        if triggered then
                            -- Debug output
                            if self.debugPlayerSelection then
                                local boundAnim = self.currentBinds[upperKey] or "N/A"
                                Trace(string.format(
                                    "Modifier (21) + Key '%s' (ID: %d) -> Animation: %s",
                                    keyName, keyCode, boundAnim
                                ))
                            end
                            -- Play bound animation
                            local animName = self.currentBinds[upperKey]
                            if animName then
                                self:playAnimation(cache.ped, animName)
                            end
                        end
                    end
                end
            end
        end
    end)

    SetPauseMenuActive(true)
end
Main.Init = Main.Init

-- ─────────────────────────────────────────────────
-- Main:setupSequences(sequenceData)
-- Populates self.sequences and Config.Sequences
-- from the raw sequence definitions.
-- ─────────────────────────────────────────────────
function Main:setupSequences(sequenceData)
    Trace("Setting up sequences", json.encode(sequenceData))
    if not sequenceData then return end

    local formatted = {}
    for _, seq in ipairs(sequenceData) do
        local name = seq.command or seq.name
        local entry = {
            name     = name,
            command  = name,
            label    = seq.label,
            category = "sequence",
            type     = "sequence",
            animations = {},
        }
        table.insert(formatted, entry)
        -- Strip the category/type fields before pushing to self.sequences
        entry.animations = nil
        entry.category   = nil
        entry.type       = nil
        entry.items      = seq.items
        table.insert(self.sequences, entry)
    end

    Config.Sequences    = formatted
    self.sequences      = formatted   -- also keep on self
end
Main.setupSequences = Main.setupSequences

-- ─────────────────────────────────────────────────
-- local getHelpItemsForPhase(phase)
-- Returns the help-overlay items for a given
-- AnimPos phase ("help" / "helpEdit" / "speed").
-- ─────────────────────────────────────────────────
local function getHelpItemsForPhase(phase)
    local items = {}
    if Config and Config.AnimPos then
        for _, entry in ipairs(Config.AnimPos) do
            if entry.type == "help" and entry.phase == phase then
                table.insert(items, {
                    key     = entry.key,
                    icon    = entry.icon,
                    textKey = entry.textKey,
                })
            end
        end
    end

    -- Fall back to Config.AnimPosHelp if nothing matched
    if #items == 0 and Config and Config.AnimPosHelp then
        if phase == "help" then
            items = Config.AnimPosHelp.helpItems or {}
        elseif phase == "helpEdit" then
            items = Config.AnimPosHelp.editHelpItems or {}
        end
    end
    return items
end

-- ─────────────────────────────────────────────────
-- local getPlaceControls()
-- Returns the placement-phase control code table.
-- ─────────────────────────────────────────────────
local function getPlaceControls()
    local controls = {}
    if Config and Config.AnimPos then
        for _, entry in ipairs(Config.AnimPos) do
            if entry.type == "control" and entry.phase == "place" then
                if entry.name and entry.code then
                    controls[entry.name] = entry.code
                end
            end
        end
    end

    -- Fall back to legacy Config.EditAnimControls
    if not next(controls) and Config and Config.EditAnimControls then
        controls = Config.EditAnimControls
    end
    return controls
end

-- ─────────────────────────────────────────────────
-- Main:setSettings(settings)
-- Applies the settings table, filling in any
-- missing defaults, and pushes them to the NUI.
-- ─────────────────────────────────────────────────
function Main:setSettings(settings)
    -- Fill missing optional settings with defaults
    if settings.bigMenu    == nil then settings.bigMenu    = Config.DefaultSettings.bigMenu    end
    if settings.solidPrimary == nil then settings.solidPrimary = Config.DefaultSettings.solidPrimary end

    self:sendReactMessage("SET_CONFIG", {
        menuAlign      = settings.menuAlign,
        menuScale      = settings.menuScale,
        musicVolume    = settings.musicVolume,
        showGifs       = settings.showGifs,
        performanceMode = settings.performanceMode,
        bigMenu        = settings.bigMenu,
        solidPrimary   = settings.solidPrimary,
        disableKeybinds = Config.DisableKeybinds,
        animPosHelp    = {
            helpItems     = getHelpItemsForPhase("help"),
            editHelpItems = getHelpItemsForPhase("helpEdit"),
        },
        defaultData    = {
            menuAlign      = Config.DefaultSettings.menuAlign,
            menuScale      = Config.DefaultSettings.menuScale,
            musicVolume    = Config.DefaultSettings.musicVolume,
            showGifs       = Config.DefaultSettings.showGifs,
            performanceMode = Config.DefaultSettings.performanceMode,
            disableKeybinds = Config.DisableKeybinds,
            bigMenu        = Config.DefaultSettings.bigMenu,
            solidPrimary   = Config.DefaultSettings.solidPrimary,
        },
    })
    self.settings = settings
end
Main.setSettings = Main.setSettings

-- ─────────────────────────────────────────────────
-- Main:getActiveControls(rawControls)
-- Filters rawControls to only those that have a
-- binding in currentBinds, storing the result in
-- self.activeControls.
-- ─────────────────────────────────────────────────
function Main:getActiveControls(rawControls)
    local active = {}
    for keyName, keyCode in pairs(rawControls) do
        local upper = string.upper(keyName)
        if self.currentBinds[upper] then
            active[upper] = keyCode
        end
    end
    self.activeControls = active
end
Main.getActiveControls = Main.getActiveControls

-- ─────────────────────────────────────────────────
-- Main:getActiveControl(keyName)
-- Returns the raw control code for a given key
-- name string (case-insensitive).
-- ─────────────────────────────────────────────────
function Main:getActiveControl(keyName)
    if not self.rawControls then return nil end
    for k, code in pairs(self.rawControls) do
        if tostring(string.upper(k)) == tostring(keyName) then
            return code
        end
    end
    return nil
end
Main.getActiveControl = Main.getActiveControl

-- ─────────────────────────────────────────────────
-- Main:sendAnimationsInBatches()
-- Sends the animation list to the NUI in chunks
-- of 100, staggered by 250 ms per batch.
-- ─────────────────────────────────────────────────
function Main:sendAnimationsInBatches()
    local batchSize  = 100
    local totalAnims = #self.animations
    local batches    = math.ceil(totalAnims / batchSize)

    -- Filter out hidden animations
    local function filterVisible(list)
        local out = {}
        for _, anim in ipairs(list) do
            if not anim.hide then table.insert(out, anim) end
        end
        return out
    end

    local visible = filterVisible(self.animations)

    for batchIndex = 1, batches do
        local delay = (batchIndex - 1) * 250
        SetTimeout(delay, function()
            local startIdx = (batchIndex - 1) * batchSize + 1
            local endIdx   = math.min(batchIndex * batchSize, #visible)
            local slice    = { table.unpack(visible, startIdx, endIdx) }
            self:sendReactMessage("SET_MENU_BATCH", {
                animations  = slice,
                isLastBatch = (batchIndex == batches),
            }, true)
        end)
    end

    Trace("Added " .. batches .. " batches to the menu")
    Trace("Total animations: "   .. totalAnims)
    Trace("Batch size: "         .. batchSize)
    Trace("Animations to send: " .. #visible)
end
Main.sendAnimationsInBatches = Main.sendAnimationsInBatches

-- ─────────────────────────────────────────────────
-- Main:convertAnimations()
-- Walks Config.Convert and normalises animation
-- option keys (PascalCase → camelCase), then
-- populates Config.Dances, Config.Emotes,
-- Config.Shared, etc.
-- ─────────────────────────────────────────────────
function Main:convertAnimations()
    -- Normalise a raw animation entry's AnimationOptions table
    local function normaliseOptions(anim, key)
        if not anim.AnimationOptions then return anim end
        local opts = anim.AnimationOptions
        local o    = {}
        o.prop                = opts.Prop
        o.propBone            = opts.PropBone
        o.propPlacement       = opts.PropPlacement
        o.secondProp          = opts.SecondProp
        o.secondPropBone      = opts.SecondPropBone
        o.secondPropPlacement = opts.SecondPropPlacement
        o.emoteLoop           = opts.EmoteLoop
        o.emoteMoving         = opts.EmoteMoving
        o.emoteDuration       = opts.EmoteDuration
        o.emoteStuck          = opts.EmoteStuck
        o.onlyInVehicle       = opts.OnlyInVehicle
        o.attachTo            = opts.Attachto
        o.syncOffset          = opts.SyncOffset
        o.syncOffsetFront     = opts.SyncOffsetFront
        o.syncOffsetSide      = opts.SyncOffsetSide
        o.syncOffsetHeading   = opts.SyncOffsetHeading
        o.syncOffsetHeight    = opts.SyncOffsetHeight
        o.customMovementType  = opts.Flag or opts.customMovementType
        o.bone                = opts.bone
        o.xPos                = opts.xPos
        o.yPos                = opts.yPos
        o.zPos                = opts.zPos
        o.xRot                = opts.xRot
        o.yRot                = opts.yRot
        o.zRot                = opts.zRot
        o.ptfxAsset           = opts.PtfxAsset
        o.ptfxName            = opts.PtfxName
        o.ptfxScale           = opts.PtfxScale
        o.ptfxPlacement       = opts.PtfxPlacement
        o.ptfxOffset          = opts.PtfxOffset
        o.ptfxOffsetFront     = opts.PtfxOffsetFront
        o.ptfxOffsetSide      = opts.PtfxOffsetSide
        o.ptfxOffsetHeading   = opts.PtfxOffsetHeading
        o.ptfxOffsetHeight    = opts.PtfxOffsetHeight
        o.musicURL            = opts.MusicURL
        o.skip                = opts.SkipRequest or opts.skip or opts.Skip
        o.group               = opts.Group or opts.group
        o.hide                = opts.Hide or opts.hide
        o.editAnimSpeed       = opts.EditAnimSpeed or opts.editAnimSpeed
        anim.animationOptions = o
        anim.AnimationOptions = nil
        return anim
    end

    for category, rawTable in pairs(Config.Convert) do
        if category == "Dances" or category == "Emotes" then
            if Config[category] then
                for key, anim in pairs(rawTable) do
                    Config[category][key] = normaliseOptions(anim, key)
                    Main.commandNames[anim[3]] = key
                end
            end

        elseif category == "Shared" or category == "ERP" then
            if Config[category] then
                if not self.sharedAnimations then self.sharedAnimations = {} end
                for key, anim in pairs(rawTable) do
                    -- Determine if this animation should be skip-requested
                    local shouldSkip = false
                    if anim.AnimationOptions then
                        local opts = anim.AnimationOptions
                        if opts.SkipRequest or opts.skip or opts.Skip then
                            Main.skipAnimations[key] = true
                            shouldSkip = true
                        end
                    end

                    -- Determine if hidden
                    local isHidden = false
                    if anim.AnimationOptions then
                        if anim.AnimationOptions.Hide or anim.AnimationOptions.hide then
                            isHidden = true
                        end
                    end

                    self.sharedAnimations[key] = normaliseOptions(anim, key)

                    table.insert(Config[category], {
                        name     = key,
                        label    = anim[3],
                        category = category == "ERP" and "erp" or "shared",
                        type     = "shared",
                        animationOptions = isHidden and { hide = true } or nil,
                    })
                    Main.commandNames[anim[3]] = key
                end
            end
        else
            Trace("Array not found:", category)
        end
    end

    Config.Convert = nil
end
Main.convertAnimations = Main.convertAnimations

-- ─────────────────────────────────────────────────
-- Main:getCache(serverName)
-- Reads the "BABLO_ANIMATIONS" KVP, selects the
-- correct character-specific sub-data and returns
--   cacheData, isNewServer
-- ─────────────────────────────────────────────────
function Main:getCache(serverName)
    if serverName then self.serverName = serverName end

    local raw = GetResourceKvpString("BABLO_ANIMATIONS")

    if raw then
        local ok, data = pcall(json.decode, raw)
        if ok and data then
            local charId        = Framework:getCharacterIdentifier()
            local charSpecific  = Config.CharacterSpecific
            local charData      = data.characterData and data.characterData[charId]
            local hasCharData   = charData ~= nil

            local function pickCharOrGlobal(field, defaultVal)
                if charSpecific and charSpecific[field] then
                    if hasCharData and charData[field] then
                        return charData[field]
                    end
                    return data[field] or defaultVal
                end
                return data[field] or defaultVal
            end

            local result = {
                keybinds      = pickCharOrGlobal("keybinds",      {}),
                favorites     = pickCharOrGlobal("favorites",     {}),
                expression    = pickCharOrGlobal("expression",    false),
                walkingstyle  = pickCharOrGlobal("walkingstyle",  false),
                weaponstyle   = pickCharOrGlobal("weaponstyle",   false),
                characterData = data.characterData or {},
                sequences     = data.sequences     or {},
                settings      = data.settings      or Config.DefaultSettings,
            }
            return result
        else
            Trace("Warning: Failed to decode KVP data, returning empty cache without overwriting")
            return {
                keybinds      = {},
                favorites     = {},
                expression    = false,
                walkingstyle  = false,
                weaponstyle   = false,
                characterData = {},
                sequences     = {},
                settings      = Config.DefaultSettings,
            }, false
        end
    else
        -- First run – initialise fresh KVP
        local initData = {
            settings      = Config.DefaultSettings,
            characterData = {},
        }
        SetResourceKvp("BABLO_ANIMATIONS", json.encode(initData))
        return {}, true
    end
end
Main.getCache = Main.getCache

-- ─────────────────────────────────────────────────
-- Main:reloadKeybinds()
-- Re-reads keybinds from the KVP and pushes the
-- updated bind values to the NUI.
-- ─────────────────────────────────────────────────
function Main:reloadKeybinds()
    local charId = Framework:getCharacterIdentifier()
    if not charId or charId == "" then
        Trace("reloadKeybinds: No character ID yet, retrying...")
        SetTimeout(1000, function() self:reloadKeybinds() end)
        return
    end

    Trace("reloadKeybinds: Reloading for character:", charId)

    local raw = GetResourceKvpString("BABLO_ANIMATIONS")
    if not raw then
        Trace("reloadKeybinds: No KVP data found")
        return
    end

    local ok, data = pcall(json.decode, raw)
    if not ok or not data then
        Trace("reloadKeybinds: Failed to decode KVP data")
        return
    end

    -- Determine keybinds for this character
    local keybinds = {}
    if Config.CharacterSpecific and Config.CharacterSpecific.keybinds then
        local charData = data.characterData and data.characterData[charId]
        if charData and charData.keybinds then
            keybinds = charData.keybinds
        end
    else
        keybinds = data.keybinds or {}
    end

    if not next(keybinds) then
        Trace("reloadKeybinds: No keybinds found for this character")
        return
    end

    Trace("reloadKeybinds: Found keybinds, updating...")
    self.currentBinds = keybinds

    for keyName, animName in pairs(keybinds) do
        Trace("reloadKeybinds: Setting", keyName, "->", animName)
        local anim = self:getAnimation(animName)
        if anim then
            anim.bind = keyName
            self:sendReactMessage("UPDATE_ANIMATION", { name = animName, field = "bind", value = keyName })
        end
        local control = self:getActiveControl(keyName)
        if control then
            self.activeControls[keyName] = control
        end
    end

    local hasBinds = next(self.currentBinds) and "keybinds" or "nothing"
    Trace("reloadKeybinds: Complete, loaded", hasBinds)
end
Main.reloadKeybinds = Main.reloadKeybinds

-- ─────────────────────────────────────────────────
-- Main:reloadFavorites()
-- Re-reads favourites from KVP and pushes the
-- updated favourite flags to the NUI.
-- ─────────────────────────────────────────────────
function Main:reloadFavorites()
    local charId = Framework:getCharacterIdentifier()
    if not charId or charId == "" then
        Trace("reloadFavorites: No character ID yet, retrying...")
        SetTimeout(1000, function() self:reloadFavorites() end)
        return
    end

    local raw = GetResourceKvpString("BABLO_ANIMATIONS")
    if not raw then
        Trace("reloadFavorites: No KVP data found")
        return
    end

    local ok, data = pcall(json.decode, raw)
    if not ok or not data then
        Trace("reloadFavorites: Failed to decode KVP data")
        return
    end

    -- Determine favourites for this character
    local favorites = {}
    if Config.CharacterSpecific and Config.CharacterSpecific.favorites then
        local charData = data.characterData and data.characterData[charId]
        if charData and charData.favorites then
            favorites = charData.favorites
        else
            favorites = data.favorites or {}
        end
    else
        favorites = data.favorites or {}
    end

    self.favorites = favorites or {}

    if not next(self.favorites) then
        Trace("reloadFavorites: No favorites found for this character")
        return
    end

    Trace("reloadFavorites: Applying favorites to UI")
    for animName, _ in pairs(self.favorites) do
        local anim = self:getAnimation(animName)
        if anim then
            anim.favorite = true
            self:sendReactMessage("UPDATE_ANIMATION", { name = animName, field = "favorite", value = true })
        end
    end
end
Main.reloadFavorites = Main.reloadFavorites

-- ─────────────────────────────────────────────────
-- Main:addCustomAnimations(animList)
-- Inserts a list of custom animations into either
-- Config.Dances or Config.Emotes based on their
-- declared category.
-- ─────────────────────────────────────────────────
function Main:addCustomAnimations(animList)
    animation.custom = true
    for i, anim in ipairs(animList) do
        if anim.category == "dances" then
            Config.Dances[i] = anim
        elseif anim.category == "emotes" or not anim.category then
            Config.Emotes[i] = anim
        end
    end
end
Main.addCustomAnimations = Main.addCustomAnimations

-- ─────────────────────────────────────────────────
-- Main:handleWeaponStyle()
-- Watches the player's weaponstyle state bag and
-- applies SetWeaponAnimationOverride accordingly.
-- ─────────────────────────────────────────────────
function Main:handleWeaponStyle()
    if not Config.CustomGunStyles then return end

    local isOverriding = false
    local currentDict  = nil
    local currentAnim  = nil

    -- React to weapon equip / unequip on the local ped
    lib.onCache("weapon", function(weapon)
        local ped         = cache.ped
        local pedState    = Entity(ped).state
        local weaponStyle = pedState.weaponstyle

        if not weapon then
            -- Weapon removed – cancel the override animation
            if isOverriding then
                isOverriding = false
                SetWeaponAnimationOverride(ped, "default")
                if currentDict and currentAnim then
                    if IsEntityPlayingAnim(ped, currentDict, currentAnim, 3) then
                        ClearPedTasks(ped)
                        SetPedCanPlayGestureAnims(ped, true)
                        SetPedCanPlayAmbientAnims(ped, true)
                        SetPedUsingActionMode(ped, false, -1, 0)
                    end
                end
            end
            return
        end

        if weaponStyle and weaponStyle ~= "wsdefault" then
            local anim = self:getAnimation(weaponStyle)
            if anim then
                if self:allowedWeapon() then
                    SetWeaponAnimationOverride(ped, anim.style)
                    isOverriding   = true
                    currentDict    = anim.lib
                    currentAnim    = anim.animation
                end
            else
                if isOverriding then
                    isOverriding = false
                    SetWeaponAnimationOverride(ped, "default")
                end
            end
        end
    end)

    -- Thread: play custom idle/aim animation while armed
    CreateThread(function()
        while true do
            Wait(250)
            local ped         = cache.ped
            local weaponStyle = Entity(ped).state.weaponstyle
            if weaponStyle and weaponStyle ~= "wsdefault" then
                if currentDict and currentAnim then
                    local armed = IsPedArmed(ped, 4)
                    if not armed then goto continue end
                    if not self:allowedWeapon() then goto continue end
                    local aiming   = IsPlayerFreeAiming(PlayerId())
                    local shooting = IsControlPressed(0, 24)
                    local _, weaponHash = GetCurrentPedWeapon(ped, true)
                    local hasAmmo  = GetAmmoInClip(ped, weaponHash) > 0
                    local shouldPlay = aiming or (shooting and hasAmmo)

                    if shouldPlay then
                        -- Play the custom weapon style animation if not already playing
                        if not IsEntityPlayingAnim(ped, currentDict, currentAnim, 3) then
                            lib.requestAnimDict(currentDict)
                            TaskPlayAnim(ped, currentDict, currentAnim, 8.0, -8.0, -1, 48, 0, false, false, false)
                            SetPedCanPlayGestureAnims(ped, false)
                            SetPedCanPlayAmbientAnims(ped, false)
                            SetPedUsingActionMode(ped, true, -1, 0)
                        end
                        goto continue
                    end

                    -- Not aiming/shooting – stop the override
                    if IsEntityPlayingAnim(ped, currentDict, currentAnim, 3) then
                        ClearPedTasks(ped)
                        SetPedCanPlayGestureAnims(ped, true)
                        SetPedCanPlayAmbientAnims(ped, true)
                        SetPedUsingActionMode(ped, false, -1, 0)
                    end
                end
            else
                Wait(750)
            end
            ::continue::
        end
    end)

    -- Thread: apply weapon style override to other nearby players
    CreateThread(function()
        while true do
            local players = GetActivePlayers()
            if players then
                for _, playerId in ipairs(players) do
                    local playerPed   = GetPlayerPed(playerId)
                    local pedState    = Entity(playerPed).state
                    local weaponStyle = pedState.weaponstyle
                    if weaponStyle and weaponStyle ~= "wsdefault" then
                        if self:allowedWeapon(playerPed) then
                            local styleAnim = self:getAnimation(weaponStyle)
                            if styleAnim then
                                SetWeaponAnimationOverride(playerPed, styleAnim.style)
                            end
                        end
                    end
                end
            end
            Wait(2500)
        end
    end)
end
Main.handleWeaponStyle = Main.handleWeaponStyle

-- ─────────────────────────────────────────────────
-- Main:allowedWeapon(ped)
-- Returns true if the ped's currently selected
-- weapon is in Config.Weapons.
-- ─────────────────────────────────────────────────
function Main:allowedWeapon(ped)
    ped = ped or cache.ped
    local currentWeapon = GetSelectedPedWeapon(ped)
    for _, weaponName in ipairs(Config.Weapons) do
        if currentWeapon == GetHashKey(weaponName) then
            return true
        end
    end
    return false
end
Main.allowedWeapon = Main.allowedWeapon

-- ─────────────────────────────────────────────────
-- Main:updateCache(key, value)
-- Persists a value to the "BABLO_ANIMATIONS" KVP,
-- respecting character-specific data rules.
-- ─────────────────────────────────────────────────
function Main:updateCache(key, value)
    -- Read existing data
    local raw = GetResourceKvpString("BABLO_ANIMATIONS")
    local data = {}
    if raw then
        local ok, decoded = pcall(json.decode, raw)
        if ok and decoded then
            data = decoded
        else
            Trace("Warning: Failed to decode existing KVP data, starting fresh")
        end
    end

    if not data.characterData then data.characterData = {} end
    if not data.settings       then data.settings = Config.DefaultSettings end

    -- Helper: is this key character-specific?
    local function isCharSpecific(k)
        return Config.CharacterSpecific and Config.CharacterSpecific[k]
    end

    if isCharSpecific(key) then
        local charId = Framework:getCharacterIdentifier()
        if not charId or charId == "" then
            Trace("Warning: No valid character ID available, cannot save character-specific data for key:", key)
            return false
        end
        if not data.characterData[charId] then
            Trace("Character data not found for", charId, "- creating new entry")
            data.characterData[charId] = {
                walkingstyle = false,
                expression   = false,
                weaponstyle  = false,
                favorites    = {},
                keybinds     = {},
            }
        end
        data.characterData[charId][key] = value
        Trace("Saved", key, "for character", charId)
    else
        data[key] = value
        Trace("Saved global", key)
    end

    -- Persist
    local ok, encoded = pcall(json.encode, data)
    if ok and encoded then
        SetResourceKvp("BABLO_ANIMATIONS", encoded)
        Trace("Cache saved successfully")
        return true
    else
        Trace("Error: Failed to encode data for KVP save")
        return false
    end
end
Main.updateCache = Main.updateCache

-- ─────────────────────────────────────────────────
-- Main:getCategories()
-- Returns the list of category descriptors for
-- the NUI, omitting Gun Styles when disabled.
-- ─────────────────────────────────────────────────
function Main:getCategories()
    local result = {}
    for _, cat in pairs(Config.Categories) do
        if cat.name == "weaponstyles" then
            if Config.CustomGunStyles then
                table.insert(result, { name = cat.name, label = cat.label, icon = cat.icon })
            end
        else
            table.insert(result, { name = cat.name, label = cat.label, icon = cat.icon })
        end
    end
    return result
end
Main.getCategories = Main.getCategories

-- ─────────────────────────────────────────────────
-- Main:Set(key, value)
-- Sets a property on self (unless it is "keybinds")
-- and persists it through updateCache.
-- ─────────────────────────────────────────────────
function Main:Set(key, value)
    if key ~= "keybinds" then
        self[key] = value
    end
    Trace("Setting", key, "to", value)
    self:updateCache(key, value)
end
Main.Set = Main.Set

-- ─────────────────────────────────────────────────
-- Main:startPlayAnimation(animData)
-- Plays a single TaskPlayAnim on the given ped
-- if it is not already playing.
-- ─────────────────────────────────────────────────
function Main:startPlayAnimation(animData)
    if not IsEntityPlayingAnim(animData.ped, animData.dict, animData.lib, 3) then
        if not animData.flag then animData.flag = 49 end
        if not animData.time then animData.time = -1 end
        self:loadAnim(animData.dict)
        TaskPlayAnim(
            animData.ped, animData.dict, animData.lib,
            2.0, -1.0, animData.time, animData.flag,
            0, 0, 0, 0
        )
    end
end
Main.startPlayAnimation = Main.startPlayAnimation

-- ─────────────────────────────────────────────────
-- Main:openApp()
-- Opens the emote menu UI (fetches group data
-- first, then shows the NUI).
-- ─────────────────────────────────────────────────
function Main:openApp()
    Trace(Main.isLoaded and "Main is loaded" or "Main is not loaded")

    if not Main.isLoaded then
        Framework:Notify(Translate("RELOADING"))
        return
    end
    if not Framework:isPlayerDead() then
        Trace("Player is dead returning")
        return
    end
    if not Framework:canOpenMenu() then return end
    if self.inAction or self.pedHandle then return end

    self.inAction = true

    -- Input-blocking thread while the menu is open
    Citizen.CreateThread(function()
        local openedAt = GetGameTimer()
        while true do
            if not self.inAction then break end
            Wait(0)

            -- Auto-close when NUI focus is lost and freeLook is off
            if not self.isClosing then
                local elapsed = GetGameTimer() - openedAt
                if elapsed > 3000 and not IsNuiFocused() and not self.freeLook then
                    self.inAction = false
                    break
                end
            end

            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 25, true)
            DisableControlAction(1, 25, true)

            if not self.freeLook then
                DisableControlAction(1, 1, true)
                DisableControlAction(1, 2, true)
                DisableControlAction(1, 142, true)
                DisableControlAction(1, 106, true)
            end

            DisableControlAction(0, 81, true)
            DisableControlAction(0, 82, true)

            if not self.freeLook then
                DisableControlAction(1, 1, true)
                DisableControlAction(1, 2, true)
                DisableControlAction(1, 142, true)
                DisableControlAction(1, 106, true)
            end

            DisableControlAction(0, 81, true)
            DisableControlAction(0, 82, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(1, 200, true)
            DisableControlAction(1, 288, true)
            DisableControlAction(1, 38, true)
            HideHudComponentThisFrame(19)
            BlockWeaponWheelThisFrame()
            SetPauseMenuActive(false)
        end
    end)

    -- Fetch group / nearby player data from server
    local groupData = TriggerServerCallback({
        eventName = eventName .. "server:getGroupData",
        args      = {},
    })

    if groupData.status then
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        self:sendReactMessage("SET_VISIBLE", true)
        self:sendReactMessage("SET_MENU", {
            keybinds      = self:getFreeBinds(),
            player        = groupData.player,
            currentGroup  = groupData.currentGroup,
            closestPlayers = groupData.closestPlayers,
        })
        SetNuiFocus(true, true)
        SetNuiFocusKeepInput(true)
        self:sendReactMessage("SHOW_MENU", { element = "showApp", toggle = true })
    else
        self.inAction = false
        Trace(groupData.message)
    end
end
Main.openApp = Main.openApp

-- ─────────────────────────────────────────────────
-- Main:getFreeBinds()
-- Returns all keybind labels that have no current
-- animation bound to them.
-- ─────────────────────────────────────────────────
function Main:getFreeBinds()
    local free = {}
    for _, label in ipairs(self.keybinds) do
        if not self.currentBinds[label] then
            table.insert(free, label)
        end
    end
    return free
end
Main.getFreeBinds = Main.getFreeBinds

-- ─────────────────────────────────────────────────
-- Main:getAnimation(animName)
-- Searches self.animations for an entry with the
-- given name. Returns the animation table or nil.
-- ─────────────────────────────────────────────────
function Main:getAnimation(animName)
    for _, anim in ipairs(self.animations) do
        if anim.name == animName then
            for _, cat in pairs(Config.Categories) do
                if cat.name == anim.category then
                    local catList, isDictionary = cat.get()
                    if isDictionary then
                        return catList[animName]
                    else
                        for i, entry in ipairs(catList) do
                            if entry.name == animName then
                                if not entry.type then
                                    entry.type = cat.type or "animation"
                                end
                                return entry
                            end
                        end
                    end
                end
            end
        end
    end
end
Main.getAnimation = Main.getAnimation

-- ─────────────────────────────────────────────────
-- Main:toggleFavorite(data)
-- Toggles the favourite flag on an animation and
-- persists the change.
-- ─────────────────────────────────────────────────
function Main:toggleFavorite(data)
    local anim = self:getAnimation(data.name)
    if not anim then
        Trace("Animation not found:", data.name)
        return
    end

    anim.favorite = data.favorite

    if anim.favorite then
        self.favorites[data.name] = true
    else
        self.favorites[data.name] = nil
        -- Also remove the keybind if the animation is unfavourited
        if anim.bind then
            self:toggleBind({ name = data.name, bind = false })
        end
    end

    self:updateAnimation("favorite", anim)
    self:Set("favorites", self.favorites)
end
Main.toggleFavorite = Main.toggleFavorite

-- ─────────────────────────────────────────────────
-- Main:toggleBind(data)
-- Assigns or removes a keyboard shortcut for an
-- animation and persists the change.
-- ─────────────────────────────────────────────────
function Main:toggleBind(data)
    local anim = self:getAnimation(data.name)
    if not anim then
        Trace("Animation not found:", data.name)
        return
    end

    -- Guard: character ID must be ready for character-specific keybinds
    if Config.CharacterSpecific and Config.CharacterSpecific.keybinds then
        local charId = Framework:getCharacterIdentifier()
        if not charId or charId == "" then
            Trace("Warning: Cannot save keybind - character ID not ready")
            local msg = Translate("KEYBIND_SAVE_FAILED") or "Failed to save keybind - please try again"
            Framework:Notify(msg)
            return
        end
    end

    if data.bind then
        data.bind = string.upper(data.bind)

        -- Warn if overwriting an existing bind
        for existingKey, existingAnim in pairs(self.currentBinds) do
            if tostring(existingKey) == tostring(data.bind) then
                local msg = Translate("KEYBIND_OVERWRITTEN", { self.currentBinds[existingKey], data.name })
                Framework:Notify(msg)
                -- Remove old bind
                self.activeControls[tostring(data.bind)] = nil
                self.currentBinds[existingKey]           = nil
                break
            end
        end
    end

    anim.bind = data.bind
    anim.name = data.name

    if anim.bind then
        -- Register the new bind
        self.currentBinds[anim.bind]                         = data.name
        self.activeControls[tostring(data.bind)]             = self:getActiveControl(data.bind)
    else
        -- Remove the bind entirely
        for key, boundAnim in pairs(self.currentBinds) do
            if boundAnim == data.name then
                self.currentBinds[key]             = nil
                self.activeControls[tostring(key)] = nil
            end
        end
        anim.bind = false
    end

    self:updateAnimation("bind", anim)
    self:Set("keybinds", self.currentBinds)
end
Main.toggleBind = Main.toggleBind

-- ─────────────────────────────────────────────────
-- Main:getTableIndex(tbl, key)
-- Returns the numeric index of `key` inside `tbl`.
-- ─────────────────────────────────────────────────
function Main:getTableIndex(tbl, key)
    local i = 0
    for k, _ in pairs(tbl) do
        i = i + 1
        if k == key then return i end
    end
    return nil
end
Main.getTableIndex = Main.getTableIndex

-- ─────────────────────────────────────────────────
-- Main:updateAnimation(field, animData)
-- Finds the matching animation in self.animations
-- and updates the given field in-place.
-- ─────────────────────────────────────────────────
function Main:updateAnimation(field, animData)
    for _, anim in ipairs(self.animations) do
        if anim.name == animData.name then
            anim[field] = animData[field]
        end
    end
end
Main.updateAnimation = Main.updateAnimation

-- ─────────────────────────────────────────────────
-- Main:playAnimation(ped, animName, ignoreCooldown, forcePlay)
-- Core animation dispatcher. Validates the request
-- and delegates to the appropriate animationType
-- handler.
-- ─────────────────────────────────────────────────
function Main:playAnimation(ped, animName, ignoreCooldown, forcePlay)
    local anim = self:getAnimation(animName)

    -- Set per-player cooldown when playing on self
    if ped == cache.ped and not forcePlay then
        SetTimeout(Config.Timeout * 2000, function()
            self.onCooldown = false
        end)
    end

    -- Cooldown guard
    if self.onCooldown and not ignoreCooldown then
        if Main.isLoaded and not forcePlay then return end
    end

    if not ped then
        Trace("Ped not found")
        return
    end

    -- Skip while ped is falling or in ragdoll
    if IsPedFalling(ped) or IsPedRagdoll(ped) then return end

    -- Skip if player is dead
    if ped == cache.ped and not forcePlay then
        if not Framework:isPlayerDead() then
            if Main.isLoaded then return end
        end
    end

    -- Check vehicle blacklist
    if IsPedInAnyVehicle(ped, false) then
        for _, blacklisted in ipairs(Config.AnimationsBlacklistedInVehicles) do
            if blacklisted == animName then
                Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY_IN_VEHICLE"))
                return
            end
        end
    end

    if not anim then
        Trace("Animation not found:", animName)
        return
    end

    -- Set cooldown for local ped
    if ped == cache.ped and not ignoreCooldown and not forcePlay then
        self.onCooldown = true
    end

    if not anim.type then
        Trace("Animation missing type:", animName)
        anim.type = "animation"
        Trace("Setting type to animation")
    end

    -- Framework hook
    if not Framework:canPlayAnimation(animName) then return end

    -- Group sync: trigger grouped animation instead
    if anim.type == "animation" and self.currentGroup ~= 0 then
        local myServerId = GetPlayerServerId(PlayerId())
        if self.currentGroup == myServerId and not ignoreCooldown then
            TriggerServerEvent(eventName .. "server:playGroupedAnimation", animName)
            return
        end
    end

    -- Webhook log
    if anim.type == "animation" and Config.Logs then
        TriggerServerEvent(eventName .. "server:sendWebhook", "PLAYED_ANIMATION", animName)
    end

    -- Framework callback
    Citizen.CreateThread(function()
        Framework:onPlayAnimation(animName)
    end)

    -- Speed edit flag
    local hasSpeedEdit = anim.animationOptions and anim.animationOptions.editAnimSpeed
    self.currentAnimHasSpeedEdit = hasSpeedEdit or false

    -- Dispatch to the correct handler
    local handler = Config.animationTypes[anim.type]
    handler(ped, anim, ignoreCooldown)
end
Main.playAnimation = Main.playAnimation

-- ─────────────────────────────────────────────────
-- Main:editAnimation(animName)
-- Opens the placement / position-editor for an
-- animation. Spawns a local preview ped and runs
-- an interactive loop until E (confirm) or ESC.
-- ─────────────────────────────────────────────────
function Main:editAnimation(animName)
    if self.currentAnimHasSpeedEdit then
        self.currentAnimHasSpeedEdit = false
        self.animSpeed = 1.0
        self:sendReactMessage("SHOW_ANIM_SPEED", { toggle = false, speed = 1.0 })
    end

    if not Config.EnablePlaceAnimation then
        Framework:Notify(Translate("NOT_ALLOWED_TO_PLACE"))
        return
    end

    local anim = self:getAnimation(animName)
    if not anim then
        Trace("Animation not found:", animName)
        return
    end

    if not anim.type then
        Trace("Animation missing type:", animName)
        anim.type = "animation"
        Trace("Setting type to animation")
    end

    if not self:allowedToPlace(anim.type) then
        Framework:Notify(Translate("NOT_ALLOWED_TO_PLACE"))
        return
    end

    self.lastValidCoords = nil
    local hitResult, hitCoords = self:rayCastGamePlayCamera(Config.PlaceDistance)
    local pedCoords = GetEntityCoords(cache.ped)
    if not hitResult or not hitCoords then
        hitCoords = pedCoords
    end

    local zHeight = hitCoords.z
    local previewPed = self:createLocalPed(pedCoords)
    self.pedHandle = previewPed
    ShowHelp(true)

    -- Wait for the ped to be spawned (up to 100 frames)
    local timeout = 100
    while not DoesEntityExist(self.pedHandle) and timeout > 0 do
        Wait(10)
        timeout = timeout - 1
    end

    if not DoesEntityExist(self.pedHandle) then
        Trace("Failed to create preview ped")
        ShowHelp(false)
        return
    end

    SetEntityCollision(self.pedHandle, false, false)
    FreezeEntityPosition(self.pedHandle, true)
    SetPedCanRagdoll(self.pedHandle, false)
    SetEntityAlpha(self.pedHandle, 200, false)
    SetEntityCoords(self.pedHandle, hitCoords.x, hitCoords.y, zHeight, false, false, false, false)
    Wait(50)
    self:playAnimation(self.pedHandle, animName)
    Wait(50)
    FreezeEntityPosition(self.pedHandle, true)

    local controls = getPlaceControls()

    -- Placement loop thread
    Citizen.CreateThread(function()
        local heading    = 0.0
        local heightLocked = false

        while true do
            if not DoesEntityExist(self.pedHandle) then break end

            local _, rayCoords  = self:rayCastGamePlayCamera(Config.PlaceDistance)
            local currentHeading = GetEntityHeading(self.pedHandle)
            heading = currentHeading

            if DoesEntityExist(self.pedHandle) then
                FreezeEntityPosition(self.pedHandle, true)
                SetEntityCollision(self.pedHandle, false, false)
                SetPedCanRagdoll(self.pedHandle, false)
            end

            if rayCoords and not heightLocked then
                zHeight = rayCoords.z
            end

            -- Disable movement / combat controls
            for _, code in ipairs({ 36, 44, 52, 37, 45, 140, 141, 142, 199, 14, 15, 157, 158, 159, 160, 161, 162, 163, 164 }) do
                DisableControlAction(0, code, true)
            end
            BlockWeaponWheelThisFrame()
            HideHudComponentThisFrame(19)
            SetPauseMenuActive(false)

            -- Rotation controls
            local rotLeftFast  = controls.rotateLeftFast  or 14
            local rotRightFast = controls.rotateRightFast or 15
            local rotUpSlow    = controls.rotateUpSlow    or 172
            local rotDownSlow  = controls.rotateDownSlow  or 173
            local rotLeftSlow  = controls.rotateLeftSlow  or 174
            local rotRightSlow = controls.rotateRightSlow or 175
            local pitchUpCode  = controls.pitchUp         or 10
            local pitchDnCode  = controls.pitchDown       or 11
            local incHeight    = controls.increaseHeight  or 44
            local decHeight    = controls.decreaseHeight  or 48
            local setGround    = controls.setOnGround     or 47
            local confirmCode  = controls.confirm         or 38
            local cancelCode   = controls.cancel          or 200

            local function isPressed(code)
                return IsControlPressed(0, code) or IsDisabledControlPressed(0, code)
            end
            local function isJustReleased(code)
                return IsControlJustReleased(0, code) or IsDisabledControlJustReleased(0, code)
            end

            if isPressed(rotLeftFast)  then heading = heading + 10.0 end
            if isPressed(rotRightFast) then heading = heading - 10.0 end
            if isPressed(rotUpSlow)    then heading = heading + 1.0  end
            if isPressed(rotDownSlow)  then heading = heading - 1.0  end
            if isPressed(rotLeftSlow)  then heading = heading - 3.0  end
            if isPressed(rotRightSlow) then heading = heading + 3.0  end
            if isPressed(pitchUpCode)  then heading = heading + 1.0  end
            if isPressed(pitchDnCode)  then heading = heading - 1.0  end

            -- Height adjustment
            if isPressed(incHeight) then
                local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(self.pedHandle))
                if dist < Config.PlaceDistance then
                    zHeight       = zHeight + 0.01
                    heightLocked  = true
                end
            elseif isPressed(decHeight) then
                local dist = #(GetEntityCoords(cache.ped) - GetEntityCoords(self.pedHandle))
                if dist < Config.PlaceDistance then
                    zHeight       = zHeight - 0.01
                    heightLocked  = true
                end
            end

            -- Set on ground
            if isJustReleased(setGround) then
                if rayCoords then zHeight = rayCoords.z end
                heightLocked = false
            end

            -- Cancel
            if isJustReleased(cancelCode) then
                for _, prop in pairs(self.localprops or {}) do DeleteEntity(prop) end
                self.localprops = {}
                DeleteEntity(self.pedHandle)
                self.pedHandle = nil
                break
            end

            -- Confirm (place)
            if isJustReleased(confirmCode) then
                FreezeEntityPosition(self.pedHandle, true)
                SetEntityCollision(self.pedHandle, false, false)
                SetEntityAsMissionEntity(self.pedHandle, false, false)
                local pedPos    = GetEntityCoords(self.pedHandle)
                local onGround, groundCoords = self:isPositionOnGround(vector3(pedPos.x, pedPos.y, zHeight))

                if not onGround then
                    Framework:Notify(Translate("CANNOT_PLACE_IN_AIR"))
                else
                    local playerZ  = GetEntityCoords(cache.ped).z - 0.49 + Config.PlaceMaxHeight
                    if zHeight > playerZ then
                        Framework:Notify(Translate("TOO_HIGH"))
                    else
                        local distToPlace = #(GetEntityCoords(cache.ped) - pedPos)
                        if distToPlace > Config.PlaceDistance then
                            Framework:Notify(Translate("TOO_FAR_AWAY"))
                        else
                            self:placeAnimation(animName, vec3(pedPos.x, pedPos.y, zHeight), heading)
                        end
                    end
                end

                for _, prop in pairs(self.localprops or {}) do DeleteEntity(prop) end
                self.localprops = {}
                DeleteEntity(self.pedHandle)
                self.pedHandle = nil
                break
            end

            SetEntityHeading(self.pedHandle, heading)
            if rayCoords then
                SetEntityCoords(self.pedHandle, rayCoords.x, rayCoords.y, zHeight, false, false, false, false)
            end
            SetPauseMenuActive(false)
            Citizen.Wait(0)
        end

        SetPauseMenuActive(true)
        ShowHelp(false)
    end)
end
Main.editAnimation = Main.editAnimation

-- ─────────────────────────────────────────────────
-- Main:isPositionOnGround(coords)
-- Fires a downward shape-test ray to check whether
-- coords is above solid ground.
-- Returns: isOnGround, groundCoords, normal
-- ─────────────────────────────────────────────────
function Main:isPositionOnGround(coords)
    local above = vector3(coords.x, coords.y, coords.z + 1.0)
    local below = vector3(coords.x, coords.y, coords.z - 5.0)
    local ray   = StartShapeTestRay(
        above.x, above.y, above.z,
        below.x, below.y, below.z,
        1, nil, 0
    )
    local _, hit, hitCoords = GetShapeTestResult(ray)
    return hit, hitCoords
end
Main.isPositionOnGround = Main.isPositionOnGround

-- ─────────────────────────────────────────────────
-- Main:placeAnimation(animName, coords, heading)
-- Teleports the player to `coords` and plays the
-- animation at the placed position.
-- ─────────────────────────────────────────────────
function Main:placeAnimation(animName, coords, heading)
    self.lastAnimationWasPlaced = true
    self.isBusy = true

    local myCoords  = GetEntityCoords(cache.ped)
    local distance  = #(myCoords - coords)
    local walkTime  = math.max(3000, math.ceil(distance / 1.0) * 1000 + 2000)

    local reached = Main:gotoPlace(cache.ped, coords, 1.0, walkTime, heading, 1.0)
    if not reached then
        self.isBusy = false
        return
    end

    if Config.FreezeEntityOnPlace then
        FreezeEntityPosition(cache.ped, true)
    end

    Citizen.Wait(100)
    SetEntityCoords(cache.ped, coords.x, coords.y, coords.z)
    SetEntityHeading(cache.ped, heading)

    if Config.Logs then
        TriggerServerEvent(eventName .. "server:sendWebhook", "PLACED_ANIMATION", animName)
    end

    Citizen.CreateThread(function()
        self:playAnimation(cache.ped, animName)
    end)

    self.isBusy = false
end
Main.placeAnimation = Main.placeAnimation

-- ─────────────────────────────────────────────────
-- Main:gotoPlace(ped, targetCoords, speed, timeout, heading, distThreshold)
-- Tasks the ped to walk to targetCoords and waits
-- until it arrives or the timeout expires.
-- Returns true if the ped reached the destination.
-- ─────────────────────────────────────────────────
function Main:gotoPlace(ped, targetCoords, speed, timeout, heading, distThreshold)
    TaskGoStraightToCoord(ped, targetCoords.x, targetCoords.y, targetCoords.z, speed, -1, heading, distThreshold)

    local startTime   = GetGameTimer()
    local threshold   = 2.0

    while true do
        -- Task complete?
        if GetScriptTaskStatus(ped, 2106541073) == 7 then break end

        -- Player interrupted (WASD)
        if ped == PlayerPedId() then
            local interrupted =
                IsControlJustPressed(0, 32) or
                IsControlJustPressed(0, 33) or
                IsControlJustPressed(0, 34) or
                IsControlJustPressed(0, 35)
            if interrupted then
                ClearPedTasks(ped)
                return false
            end
        end

        -- Timeout
        if (GetGameTimer() - startTime) > timeout then
            ClearPedTasks(ped)
            local dist = #(GetEntityCoords(ped) - targetCoords)
            return threshold >= dist
        end

        Citizen.Wait(0)
    end

    local dist = #(GetEntityCoords(ped) - targetCoords)
    return threshold >= dist
end
Main.gotoPlace = Main.gotoPlace

-- ─────────────────────────────────────────────────
-- Main:rayCastGamePlayCamera(distance)
-- Casts a ray from the gameplay camera forward by
-- `distance` units. Returns hit, coords, normal.
-- ─────────────────────────────────────────────────
function Main:rayCastGamePlayCamera(distance)
    local camRot   = GetGameplayCamRot()
    local camCoord = GetGameplayCamCoord()
    local dir      = self:rotationToDirection(camRot)

    local toPoint = vector3(
        camCoord.x + dir.x * distance,
        camCoord.y + dir.y * distance,
        camCoord.z + dir.z * distance
    )

    -- Primary ray
    local ray = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        toPoint.x,  toPoint.y,  toPoint.z,
        273, cache.ped, 0
    )
    local _, hit, coords, normal, _ = GetShapeTestResult(ray)

    -- Fallback swept sphere if primary missed
    if not hit then
        local ray2 = StartShapeTestSweptSphere(
            camCoord.x, camCoord.y, camCoord.z,
            toPoint.x,  toPoint.y,  toPoint.z,
            0.3, 273, cache.ped, 4
        )
        _, hit, coords, normal, _ = GetShapeTestResult(ray2)
    end

    -- Cache last valid coords
    if not self.lastValidCoords then
        self.lastValidCoords = GetEntityCoords(cache.ped)
    end

    if hit and coords then
        -- Update last valid if not a wall/ceiling hit
        local dotProduct = dir.x * normal.x + dir.y * normal.y + dir.z * normal.z
        if distance >= #(camCoord - coords) and dotProduct < 0.95 then
            self.lastValidCoords = coords
        elseif distance >= #(camCoord - coords) then
            self.lastValidCoords = coords
        else
            coords = self.lastValidCoords
        end
    else
        coords = self.lastValidCoords
    end

    -- Reject zero-coords
    if coords and coords.x == 0 and coords.y == 0 and coords.z == 0 then
        coords = GetEntityCoords(cache.ped)
        hit    = false
    end

    return hit, coords, normal
end
Main.rayCastGamePlayCamera = Main.rayCastGamePlayCamera

-- ─────────────────────────────────────────────────
-- Main:rotationToDirection(rotation)
-- Converts a rotation vector (degrees) to a
-- normalised direction vector.
-- ─────────────────────────────────────────────────
function Main:rotationToDirection(rotation)
    local rad = { x = rotation.x * math.pi / 180, y = rotation.y * math.pi / 180, z = rotation.z * math.pi / 180 }
    local absCosPitch = math.abs(math.cos(rad.x))
    return {
        x = -math.sin(rad.z) * absCosPitch,
        y =  math.cos(rad.z) * absCosPitch,
        z =  math.sin(rad.x),
    }
end
Main.rotationToDirection = Main.rotationToDirection

-- ─────────────────────────────────────────────────
-- Main:createLocalPed(spawnCoords)
-- Clones the local player ped as a preview ped at
-- the given coordinates (or 1 m in front of the
-- player if coords is nil).
-- ─────────────────────────────────────────────────
function Main:createLocalPed(spawnCoords)
    local cloned = ClonePed(PlayerPedId(), false, false, true)
    if not cloned or cloned == 0 then
        Trace("Failed to clone ped")
        return nil
    end

    local pos = spawnCoords
    if not pos then
        pos = GetEntityCoords(cache.ped) + vec3(1.0, 0.0, 0.0)
    end

    SetEntityCoords(cloned, pos.x, pos.y, pos.z, false, false, false, false)
    SetEntityCollision(cloned, false, false)
    SetEntityInvincible(cloned, true)
    SetBlockingOfNonTemporaryEvents(cloned, true)
    SetPedFleeAttributes(cloned, 0, false)
    SetPedCanRagdoll(cloned, false)
    SetEntityAlpha(cloned, 200, false)
    SetEntityAsMissionEntity(cloned, true, true)
    FreezeEntityPosition(cloned, true)

    self.localprops = {}
    return cloned
end
Main.createLocalPed = Main.createLocalPed

-- ─────────────────────────────────────────────────
-- Main:allowedToPlace(animType)
-- Returns true if the animation type is in the
-- list of placeable types.
-- ─────────────────────────────────────────────────
function Main:allowedToPlace(animType)
    for _, t in ipairs(Config.placeableTypes) do
        if t == animType then return true end
    end
end
Main.allowedToPlace = Main.allowedToPlace

-- ─────────────────────────────────────────────────
-- Main:formatKeybinds(keybindDefs)
-- Builds self.keybinds (list of label strings)
-- from the keybind definition table.
-- ─────────────────────────────────────────────────
function Main:formatKeybinds(keybindDefs)
    if not keybindDefs or #keybindDefs == 0 then return end
    local labels = {}
    for _, kb in ipairs(keybindDefs) do
        if kb.label then
            Trace("Adding label:", kb.label)
            table.insert(labels, kb.label)
        else
            Trace("Keybind missing label:", json.encode(kb))
        end
    end
    self.keybinds = labels
end
Main.formatKeybinds = Main.formatKeybinds

-- ─────────────────────────────────────────────────
-- Main:formatAnimations(animList, favorites, keybinds)
-- Builds the flat self.animations array from all
-- enabled categories, applying favourite / bind
-- flags from saved data.
-- ─────────────────────────────────────────────────
function Main:formatAnimations(animList, favorites, keybinds)
    local flat = {}
    -- Skip the pseudo-categories that don't have real lists
    local skipCats = { all = true, favorites = true }

    for _, cat in pairs(Config.Categories) do
        if not skipCats[cat.name] and cat.get then
            local catList, isDictionary = cat.get()
            if isDictionary then
                -- Sorted dictionary (e.g. Dances, Emotes by key)
                for k, anim in self:sortTable(catList) do
                    local label = anim.label or anim[3]
                    local name  = anim.name  or k
                    table.insert(flat, {
                        name      = name,
                        category  = cat.name,
                        label     = label,
                        musicURL  = anim.animationOptions and anim.animationOptions.musicURL or false,
                        hide      = anim.animationOptions and anim.animationOptions.hide     or false,
                        type      = cat.type,
                        style     = anim.style or false,
                    })
                    Main.commandNames[label] = name
                end
            else
                -- Array (e.g. Sequences, WeaponStyles)
                for i, anim in ipairs(catList) do
                    local label = anim.label or anim[3]
                    local name  = anim.name  or anim[1] or i
                    table.insert(flat, {
                        name      = name,
                        category  = cat.name,
                        label     = label,
                        type      = cat.type,
                        musicURL  = anim.animationOptions and anim.animationOptions.musicURL or false,
                        hide      = anim.animationOptions and anim.animationOptions.hide     or false,
                        style     = anim.style or false,
                    })
                    Main.commandNames[label] = name
                end
            end
        end
    end

    self:setAnimations(flat, favorites, keybinds)
end
Main.formatAnimations = Main.formatAnimations

-- ─────────────────────────────────────────────────
-- Main:setAnimations(animations, favorites, keybinds)
-- Applies favourite / bind flags to each animation
-- entry and stores the result on self.
-- ─────────────────────────────────────────────────
function Main:setAnimations(animations, favorites, keybinds)
    for _, anim in ipairs(animations) do
        -- Apply keybind
        for key, boundAnim in pairs(keybinds) do
            if boundAnim == anim.name then
                anim.bind = key
            end
        end
        -- Apply favourite
        anim.favorite = favorites[anim.name] == true

        -- Ensure bind and label have defaults
        if not anim.bind  then anim.bind  = false  end
        if not anim.label then anim.label = anim.name end
    end

    Trace("Formatted animations", #animations)
    self.animations = animations
    self.favorites  = favorites
end
Main.setAnimations = Main.setAnimations

-- ─────────────────────────────────────────────────
-- Main:resetClipset()
-- Resets the player's walking style to the default
-- (or re-applies the saved walking style if any).
-- ─────────────────────────────────────────────────
function Main:resetClipset()
    if self.walkingstyle then
        local walkAnim = self:getAnimation(self.walkingstyle)
        if walkAnim then
            local handler = Config.animationTypes[walkAnim.type]
            handler(cache.ped, walkAnim, true)
        else
            ResetPedMovementClipset(cache.ped, 0.5)
        end
    else
        ResetPedMovementClipset(cache.ped, 0.5)
    end
end
Main.resetClipset = Main.resetClipset

-- ─────────────────────────────────────────────────
-- Main:sortTable(tbl, compareFn)
-- Returns an iterator that yields key, value pairs
-- in sorted key order. Uses compareFn if provided.
-- ─────────────────────────────────────────────────
function Main:sortTable(tbl, compareFn)
    local keys   = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys, compareFn)

    local i = 0
    return function()
        i = i + 1
        if keys[i] == nil then return nil end
        return keys[i], tbl[keys[i]]
    end
end
Main.sortTable = Main.sortTable

-- ─────────────────────────────────────────────────
-- Main:sendReactMessage(action, data, silent)
-- Sends a NUI message. If silent is false/nil and
-- debug mode is on, also logs the payload.
-- ─────────────────────────────────────────────────
function Main:sendReactMessage(action, data, silent)
    SendNUIMessage({ action = action, data = data })
    if not silent then
        Trace(action, json.encode(data, { indent = 2 }))
    end
end
Main.sendReactMessage = Main.sendReactMessage

-- ─────────────────────────────────────────────────
-- Main:isPedAnimal(ped)
-- Returns true if the ped's model matches one of
-- the configured animal ped models.
-- ─────────────────────────────────────────────────
function Main:isPedAnimal(ped)
    local model = GetEntityModel(ped)
    for _, animalName in ipairs(Config.AnimalPeds) do
        if model == GetHashKey(animalName) then return true end
    end
    return false
end
Main.isPedAnimal = Main.isPedAnimal

-- ─────────────────────────────────────────────────
-- Main:playEmote(anim, ped, ignoreCooldown, inGroup)
-- The actual emote executor. Runs all validation,
-- handles scenarios, plays TaskPlayAnim, attaches
-- props, starts music, etc.
-- ─────────────────────────────────────────────────
function Main:playEmote(anim, ped, ignoreCooldown, inGroup)
    ped = ped or cache.ped

    -- Stop existing music first
    if self.musicId then
        self:cancelEmote()
        Wait(1300)
    end

    -- Cancel current emote if configured
    if Config.CancelOnNewEmote then
        if LocalPlayer.state.isInAnimation and not ignoreCooldown then
            self:cancelEmote()
            Wait(1000)
        end
    end

    MovementType = 0

    local inVehicle = IsPedInAnyVehicle(ped, true)
    InVehicle = inVehicle

    if not DoesEntityExist(ped) then return false end

    -- Disarm player if configured
    if Config.DisarmPlayer then
        if IsPedArmed(ped, 7) then
            SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        end
    end

    -- Unpack animation components
    local dict, animClip, name = table.unpack(anim)
    ename          = name
    ChosenAnimation = animClip
    ChosenDict      = dict
    AnimationDuration = -1

    -- Destroy existing props
    if self.hasProps then self:destroyProps() end

    -- Helper: is this ped using the male/female freemode model?
    local function isFreemodePed()
        local model = GetEntityModel(ped)
        if model == GetHashKey("mp_m_freemode_01") then return true  end
        if model == GetHashKey("mp_f_freemode_01") then return false end
        return false
    end

    -- Clear previous isInAnimation state bag
    if LocalPlayer.state.isInAnimation then
        self:setPlayerStateBag("isInAnimation", false)
    end

    -- ── Scenario types ──────────────────────────────
    if ChosenDict == "malescenario" then
        if inVehicle then return end
        if isFreemodePed() then
            ClearPedTasks(ped)
            TaskStartScenarioInPlace(ped, ChosenAnimation, 0, true)
            self:setPlayerStateBag("isInAnimation", Main.commandNames[ename])
        end
        return

    elseif ChosenDict == "scenarioobject" then
        if inVehicle then return end
        local behindPed = GetOffsetFromEntityInWorldCoords(ped, 0.0, -0.5, -0.5)
        BehindPlayer = behindPed
        ClearPedTasks(ped)
        TaskStartScenarioAtPosition(
            ped, ChosenAnimation,
            behindPed.x, behindPed.y, behindPed.z,
            GetEntityHeading(ped), 0, 1, false
        )
        Trace("Playing scenario = (" .. ChosenAnimation .. ")")
        self:setPlayerStateBag("isInAnimation", Main.commandNames[ename])
        return

    elseif ChosenDict == "scenario" then
        if inVehicle then return end
        ClearPedTasks(ped)
        TaskStartScenarioInPlace(ped, ChosenAnimation, 0, true)
        Trace("Playing scenario = (" .. ChosenAnimation .. ")")
        self:setPlayerStateBag("isInAnimation", Main.commandNames[ename])
        return
    end

    -- ── Regular animation ────────────────────────────
    self:loadAnim(ChosenDict)

    if anim.animationOptions then
        local opts = anim.animationOptions
        ChosenAnimOptions = opts

        -- Vehicle restriction
        if opts.onlyInVehicle and not inVehicle then
            Framework:Notify(Translate("ONLY_IN_VEHICLE"))
            return false
        end
        if opts.onlyOnFoot and inVehicle then
            Framework:Notify(Translate("ONLY_ON_FOOT"))
            return false
        end

        -- Movement type
        if opts.emoteLoop then
            MovementType = opts.emoteMoving and 51 or 1
        elseif opts.emoteMoving then
            MovementType = 51
        elseif opts.emoteMoving == false then
            MovementType = 0
        elseif opts.emoteStuck then
            MovementType = 50
        end

        -- Group restriction
        if opts.group then
            local groupFn = Config.Groups[opts.group]
            if groupFn then
                if not groupFn() then
                    Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY"))
                    return false
                end
            else
                Trace("Group not found:", opts.group)
            end
        end

        -- Job restriction
        if opts.jobs then
            local allowed = false
            for _, job in ipairs(opts.jobs) do
                if Framework:isCurrentJob(job) then allowed = true end
            end
            if not allowed then
                Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY"))
                return false
            end
        end
    else
        MovementType = 0
    end

    if inVehicle  then MovementType = 51 end

    if anim.animationOptions and anim.animationOptions.customMovementType then
        MovementType = anim.animationOptions.customMovementType
    end
    if self.onlyUpperBody then MovementType = 49 end

    -- Emote duration
    if anim.animationOptions then
        local opts = anim.animationOptions
        if opts.emoteDuration == nil then
            opts.emoteDuration = -1
            AttachWait = 0
        else
            AnimationDuration = opts.emoteDuration
            AttachWait        = opts.emoteDuration
        end

        -- Particle effects
        if opts.ptfxAsset then
            local placement = opts.ptfxPlacement
            Ptfx1, Ptfx2, Ptfx3, Ptfx4, Ptfx5, Ptfx6 = table.unpack(placement)
            PtfxScale  = opts.ptfxScale
            PtfxNotif  = false
            PtfxPrompt = true
            TriggerServerEvent(eventName .. "ptfx:sync",
                opts.ptfxAsset,
                opts.ptfxName,
                vector3(Ptfx1, Ptfx2, Ptfx3),
                vector3(Ptfx4, Ptfx5, Ptfx6),
                opts.ptfxBone,
                PtfxScale,
                opts.ptfxColor
            )
            SetTimeout(1000, function() RunAnimationThread() end)
        else
            PtfxPrompt = false
        end

        -- Animal only
        if opts.onlyAnimals then
            if not self:isPedAnimal(ped) then
                Framework:Notify(Translate("NOT_ANIMAL"))
                return false
            end
        end
    end

    -- Play the animation
    TaskPlayAnim(
        ped, ChosenDict, ChosenAnimation,
        2.0, 2.0, AnimationDuration, MovementType,
        0, false, false, false
    )
    RemoveAnimDict(ChosenDict)
    self:setPlayerStateBag("isInAnimation", Main.commandNames[ename])
    MostRecentDict      = ChosenDict
    MostRecentAnimation = ChosenAnimation

    -- Speed editor overlay
    if self.currentAnimHasSpeedEdit then
        self.animSpeed = 1.0
        local speedItems = getHelpItemsForPhase("speed")
        local speedUpLabel, speedDnLabel = Translate("SPEED_UP_ANIMATION"), Translate("SPEED_DOWN_ANIMATION")
        local speedUpKey,   speedDnKey   = "PgUp", "PgDn"
        for _, item in ipairs(speedItems) do
            local translated = Translate(item.textKey)
            if item.key == "PGUP" then
                speedUpLabel = translated or speedUpLabel
                speedUpKey   = item.key
            elseif item.key == "PGDN" then
                speedDnLabel = translated or speedDnLabel
                speedDnKey   = item.key
            end
        end
        self:sendReactMessage("SHOW_ANIM_SPEED", {
            toggle         = true,
            speed          = self.animSpeed,
            speedUpLabel   = speedUpLabel,
            speedDownLabel = speedDnLabel,
            speedUpKey     = speedUpKey,
            speedDownKey   = speedDnKey,
        })
    end

    -- Props
    if anim.animationOptions and anim.animationOptions.prop then
        local opts      = anim.animationOptions
        PropName        = opts.prop
        propBone        = opts.propBone
        PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6 = table.unpack(opts.propPlacement)

        if opts.secondProp then
            secondPropName    = opts.secondProp
            secondPropBone    = opts.secondPropBone
            secondPropPl1, secondPropPl2, secondPropPl3, secondPropPl4, secondPropPl5, secondPropPl6 =
                table.unpack(opts.secondPropPlacement)
            secondPropEmote = true
        else
            secondPropEmote = false
        end

        Wait(AttachWait)
        self:addProp(PropName, propBone, PropPl1, PropPl2, PropPl3, PropPl4, PropPl5, PropPl6, ped)
        if secondPropEmote then
            self:addProp(secondPropName, secondPropBone, secondPropPl1, secondPropPl2, secondPropPl3,
                secondPropPl4, secondPropPl5, secondPropPl6, ped)
        end

        -- Particle sync with prop
        if anim.animationOptions and not anim.animationOptions.ptfxNoProp then
            local propNet  = self.props[1] and ObjToNet(self.props[1])
            local prop2Net = self.props[2] and ObjToNet(self.props[2])
            Trace(prop2Net or "no second prop")
            local useSecond = anim.animationOptions.ptfxUseSecondProp
            TriggerServerEvent(eventName .. "ptfx:syncProp",
                useSecond and prop2Net or propNet
            )
        end
    end

    -- Music
    if not self.musicCache then self.musicCache = {} end
    local musicURL  = anim.animationOptions and anim.animationOptions.musicURL
    local isOwnPed  = ped == cache.ped

    if isOwnPed and musicURL and Config.Music and Config.Music.Enabled and XSound then
        -- Group check: only the group leader plays music
        local okToPlay = true
        if inGroup then
            if self.currentGroup == 0 then okToPlay = false end
            if self.currentGroup ~= GetPlayerServerId(PlayerId()) then okToPlay = false end
        end

        if okToPlay then
            local now     = GetGameTimer()
            local cooldown = 3000
            local lastPlay = self.musicCache[musicURL]
            if lastPlay and not (cooldown < now - lastPlay) then
                Trace("Music with URL " .. musicURL .. " is on cooldown.")
            else
                if self.musicId then
                    DestroyMusic(self.musicId)
                    self.musicId = nil
                end
                self.musicId          = RequestPlayMusic(musicURL)
                self.musicCache[musicURL] = now
                Trace("Playing music with ID: " .. self.musicId)

                if self.inSequence then
                    Citizen.CreateThread(function() self:whileMusicPlaying() end)
                else
                    self:whileMusicPlaying()
                end
            end
        end
    end

    return true
end
Main.playEmote = Main.playEmote

-- ─────────────────────────────────────────────────
-- Main:saveSettings()
-- Persists the current settings through Set().
-- ─────────────────────────────────────────────────
function Main:saveSettings()
    self:Set("settings", self.settings)
end
Main.saveSettings = Main.saveSettings

-- ─────────────────────────────────────────────────
-- Main:whileMusicPlaying()
-- Polls the animation / state bag every 500 ms and
-- stops the music when the animation ends or the
-- configured max duration is reached.
-- ─────────────────────────────────────────────────
function Main:whileMusicPlaying()
    Citizen.Wait(500)
    local startTime = GetGameTimer()
    local maxMs     = nil

    if Config.Music and Config.Music.MaxDuration then
        maxMs = Config.Music.MaxDuration * 1000
    end

    while true do
        if not self.musicId then break end
        Wait(500)

        local isPlaying  = IsEntityPlayingAnim(cache.ped, MostRecentDict, MostRecentAnimation, 3)
        local inAnimState = LocalPlayer.state and LocalPlayer.state.isInAnimation
        local expired    = maxMs and (GetGameTimer() - startTime) > maxMs

        if not (isPlaying and inAnimState) or expired then
            if self.musicId then
                DestroyMusic(self.musicId)
                Trace("Music stopped (ended=" .. tostring(not isPlaying) ..
                    ", state=" .. tostring(inAnimState) ..
                    ", expired=" .. tostring(expired) .. ")")
                self.musicId = nil
            end
        end
    end
end
Main.whileMusicPlaying = Main.whileMusicPlaying

-- ─────────────────────────────────────────────────
-- Main:setPlayerStateBag(key, value)
-- Sets a value on LocalPlayer.state and syncs it
-- to the server. Also updates the NUI anim state
-- indicator when the key is "isInAnimation".
-- ─────────────────────────────────────────────────
function Main:setPlayerStateBag(key, value)
    LocalPlayer.state[key] = value
    TriggerServerEvent(eventName .. "server:setPlayerStateBag", key, value)

    if key == "isInAnimation" then
        self:sendReactMessage("SET_ANIM_STATE", { inAnimation = value and true or false })
    end
end
Main.setPlayerStateBag = Main.setPlayerStateBag

-- Thread: watches LocalPlayer.state.isInAnimation and keeps the NUI in sync
Citizen.CreateThread(function()
    local lastState = nil
    while true do
        Citizen.Wait(200)
        local current = LocalPlayer.state and LocalPlayer.state.isInAnimation or false
        if current ~= lastState then
            lastState = current
            Main:sendReactMessage("SET_ANIM_STATE", { inAnimation = current and true or false })
        end
    end
end)

-- ─────────────────────────────────────────────────
-- Main:addProp(propName, bone, px, py, pz, rx, ry, rz, ped)
-- Loads and attaches a prop to the ped's bone.
-- Handles server-side spawn, preview ped props,
-- and remote ped props.
-- ─────────────────────────────────────────────────
function Main:addProp(propName, bone, px, py, pz, rx, ry, rz, ped)
    ped = ped or cache.ped

    if not self.props     then self.props     = {} end
    if not self.localprops  then self.localprops  = {} end
    if not self.pedProps  then self.pedProps  = {} end

    local pedCoords = GetEntityCoords(ped)

    -- Server-side spawn (local player only)
    if Config.ServerSideSpawn and ped == cache.ped then
        TriggerServerEvent(eventName .. "server:addProp",
            propName, bone, px, py, pz, rx, ry, rz)
        self.hasProps = true
        return
    end

    -- Load the model if needed
    if not HasModelLoaded(propName) then
        self:loadProp(propName)
    end

    -- Create the object
    local isOwnPed = ped == cache.ped
    local obj = CreateObject(
        GetHashKey(propName),
        pedCoords.x, pedCoords.y, pedCoords.z + 0.2,
        isOwnPed, true, true
    )
    prop = obj

    -- Optionally disable collision
    if Config.DisablePropCollision then
        SetEntityCollision(obj, false, false)
        SetEntityNoCollisionEntity(obj, ped, false)
    end

    if isOwnPed then
        -- Attach to local player ped
        AttachEntityToEntity(
            obj, ped,
            GetPedBoneIndex(ped, bone),
            px, py, pz, rx, ry, rz,
            true, true, false, true, 1, true
        )
        table.insert(self.props, obj)
        self.hasProps = true

    elseif self.pedHandle and ped == self.pedHandle then
        -- Attach to local preview ped
        AttachEntityToEntity(
            obj, ped,
            GetPedBoneIndex(ped, bone),
            px, py, pz, rx, ry, rz,
            true, true, false, true, 1, true
        )
        table.insert(self.localprops, obj)
        SetEntityAlpha(obj, 150, false)
        SetEntityAsMissionEntity(obj, true, true)

    else
        -- Attach to a remote ped
        AttachEntityToEntity(
            obj, ped,
            GetPedBoneIndex(ped, bone),
            px, py, pz, rx, ry, rz,
            true, true, false, true, 1, true
        )
        if not self.pedProps[ped] then self.pedProps[ped] = {} end
        table.insert(self.pedProps[ped], obj)
        SetEntityAsMissionEntity(obj, true, true)
    end

    SetModelAsNoLongerNeeded(propName)
end
Main.addProp = Main.addProp

-- ─────────────────────────────────────────────────
-- Main:destroyProps(ped)
-- Destroys all props attached to `ped`.
-- If ped is nil/cache.ped, destroys self.props.
-- ─────────────────────────────────────────────────
function Main:destroyProps(ped)
    ped = ped or cache.ped

    if ped ~= cache.ped then
        -- Destroy remote ped props
        if self.pedProps and self.pedProps[ped] then
            for _, obj in ipairs(self.pedProps[ped]) do
                if DoesEntityExist(obj) then DeleteEntity(obj) end
            end
            self.pedProps[ped] = nil
        end
        return
    end

    -- Destroy local player props
    if Config.ServerSideSpawn then
        TriggerServerEvent(eventName .. "server:destroyProps")
    else
        for _, obj in pairs(self.props) do
            DeleteEntity(obj)
        end
    end
    self.props    = {}
    self.hasProps = false
end
Main.destroyProps = Main.destroyProps

-- ─────────────────────────────────────────────────
-- Main:loadAnim(dict)
-- Requests an animation dictionary and blocks until
-- it is loaded or a 5 s timeout expires.
-- ─────────────────────────────────────────────────
function Main:loadAnim(dict)
    local startTime = GetGameTimer()
    local timeout   = 5000
    while true do
        if HasAnimDictLoaded(dict) then return true end
        if (GetGameTimer() - startTime) > timeout then
            Trace("Failed to load animation dictionary:", dict)
            return false
        end
        RequestAnimDict(dict)
        Wait(10)
    end
end
Main.loadAnim = Main.loadAnim

-- ─────────────────────────────────────────────────
-- Main:loadProp(model)
-- Requests a model and blocks until it is loaded
-- or a 5 s timeout expires.
-- ─────────────────────────────────────────────────
function Main:loadProp(model)
    local startTime = GetGameTimer()
    local timeout   = 5000
    local hash      = GetHashKey(model)
    while true do
        if HasModelLoaded(hash) then return true end
        if (GetGameTimer() - startTime) > timeout then
            Trace("Failed to load model:", model)
            return false
        end
        RequestModel(hash)
        Wait(10)
    end
end
Main.loadProp = Main.loadProp

-- ─────────────────────────────────────────────────
-- Main:getPtfx(asset)
-- Requests a named particle effect asset and
-- activates it for the next call.
-- ─────────────────────────────────────────────────
function Main:getPtfx(asset)
    local startTime = GetGameTimer()
    local timeout   = 5000
    while true do
        if HasNamedPtfxAssetLoaded(asset) then break end
        if (GetGameTimer() - startTime) > timeout then
            Trace("Failed to load particle asset:", asset)
            return false
        end
        RequestNamedPtfxAsset(asset)
        Wait(10)
    end
    UseParticleFxAssetNextCall(asset)
    return true
end
Main.getPtfx = Main.getPtfx

-- ─────────────────────────────────────────────────
-- Main:cancelEmote(ped, skipGroupSync, inSequence, animName)
-- Cancels the current emote on `ped`: stops the
-- animation, destroys props, clears music, and
-- optionally syncs the cancel to a group.
-- ─────────────────────────────────────────────────
function Main:cancelEmote(ped, skipGroupSync, inSequence, animName)
    ped = ped or cache.ped

    local hasMusicId    = self.musicId ~= nil
    local isOwnPed      = ped == cache.ped

    -- Ped is reloading – skip
    if IsPedReloading(cache.ped) and cache.ped == ped then return end

    -- Framework hook: canCancelAnimation
    if Framework.canCancelAnimation then
        if Framework:canCancelAnimation() == false then return end
    end

    if self.isBusy then return end

    -- Cancel sequence tracking
    if not inSequence and self.inSequence then
        self.inSequence = false
    end

    -- Unfreeze if the animation was placed
    if self.lastAnimationWasPlaced and Config.FreezeEntityOnPlace then
        self.lastAnimationWasPlaced = false
        FreezeEntityPosition(ped, false)
    end

    -- Clean up animpos object
    if self.hasObject then
        AnimationPositioning:CleanupObject()
        self.hasObject = false
    end

    -- Scenario cleanup
    if LocalPlayer.state.isInAnimation == "scenarioobject" then
        ClearPedTasksImmediately(ped)
        self:setPlayerStateBag("isInAnimation", false)

        -- Delete nearby scenario objects
        if Config.ScenarioModels then
            local pedPos = GetEntityCoords(cache.ped)
            for i = 1, #Config.ScenarioModels do
                local mdl   = Config.ScenarioModels[i]
                local hash  = type(mdl) == "string" and GetHashKey(mdl) or mdl
                local obj   = GetClosestObjectOfType(pedPos.x, pedPos.y, pedPos.z, 1.5, hash, false, true, true)
                if obj ~= 0 then
                    SetEntityAsMissionEntity(obj, false, true)
                    DeleteEntity(obj)
                end
            end
        end
    end

    -- Stop particles
    if PtfxForceStopAll then
        PtfxForceStopAll()
    else
        PtfxNotif  = false
        PtfxPrompt = false
        if PtfxStop then PtfxStop() end
    end
    TriggerServerEvent(eventName .. "ptfx:clear")

    -- Stop music
    if self.musicId then
        DestroyMusic(self.musicId)
        self.musicId = nil
    end
    if ForceStopAllHearingSounds then
        ForceStopAllHearingSounds()
    elseif DestroyAllMyMusic then
        DestroyAllMyMusic()
    end

    local wasInAnimation = LocalPlayer.state.isInAnimation

    -- Detach entity if not in vehicle
    if not IsPedInAnyVehicle(ped, false) then
        DetachEntity(ped, true, false)
    end

    -- Cancel shared emote target sync
    if not skipGroupSync and self.targetPlayerId then
        TriggerServerEvent(eventName .. "server:syncCancelEmote", self.targetPlayerId)
        self.targetPlayerId = nil
    end

    -- Group cancel sync
    if not skipGroupSync and isOwnPed and self.currentGroup ~= 0 then
        if self.currentGroup == GetPlayerServerId(PlayerId()) then
            TriggerServerEvent(eventName .. "server:cancelGroupedAnimation")
        end
    end

    -- Stop looped particles
    for i, particleId in pairs(self.particles) do
        StopParticleFxLooped(particleId, false)
        table.remove(self.particles, i)
    end

    -- Stop animation task
    if IsPedInAnyVehicle(ped, false) then
        if MostRecentDict and MostRecentAnimation then
            if IsEntityPlayingAnim(ped, MostRecentDict, MostRecentAnimation, 3) then
                StopAnimTask(ped, MostRecentDict, MostRecentAnimation, -2.0)
            end
        end
    else
        ClearPedTasks(ped)
    end

    -- Destroy props
    self:destroyProps(ped)

    -- Clear isInAnimation state bag
    if LocalPlayer.state.isInAnimation then
        self:setPlayerStateBag("isInAnimation", false)
    end

    -- Hide speed editor
    if self.currentAnimHasSpeedEdit and isOwnPed then
        self.animSpeed               = 1.0
        self.currentAnimHasSpeedEdit = false
        self:sendReactMessage("SHOW_ANIM_SPEED", { toggle = false, speed = 1.0 })
    end

    -- Clear animRot
    if LocalPlayer.state.animRot then
        self:setPlayerStateBag("animRot", nil)
    end

    -- Reset clipset (own ped, not in vehicle)
    if isOwnPed and not IsPedInAnyVehicle(ped, false) then
        self:resetClipset()
    end

    -- Framework onCancelAnimation callback
    if wasInAnimation then
        Citizen.CreateThread(function()
            Framework:onCancelAnimation(wasInAnimation)
        end)
    end

    -- Brief cooldown after music
    if hasMusicId then
        self.onCooldown = true
        SetTimeout(1000, function() self.onCooldown = false end)
    end
end
Main.cancelEmote = Main.cancelEmote

-- ─────────────────────────────────────────────────
-- Main:registerKey(command, label, key, callback)
-- Registers a keymapping + command for a keybind.
-- ─────────────────────────────────────────────────
function Main:registerKey(command, label, key, callback)
    RegisterKeyMapping(command, label or "Ny key", "keyboard", key)
    RegisterCommand(command, callback)
end
Main.registerKey = Main.registerKey

-- ─────────────────────────────────────────────────
-- Main:onGroupJoin(groupId)
-- Starts a proximity loop when the player joins a
-- group. Leaves the group automatically if they
-- wander too far from the group leader.
-- ─────────────────────────────────────────────────
function Main:onGroupJoin(groupId)
    Main.currentGroup = groupId

    while Main.currentGroup ~= 0 do
        local groupPed  = GetPlayerPed(GetPlayerFromServerId(Main.currentGroup))
        local groupPos  = GetEntityCoords(groupPed)
        local myPos     = GetEntityCoords(cache.ped)
        local dist      = #(groupPos - myPos)

        if dist > Config.GroupMaxDistance then
            Framework:Notify(Translate("GROUP_TOO_FAR"))
            TriggerServerEvent(
                eventName .. "server:leaveGroup",
                Main.currentGroup,
                GetPlayerServerId(PlayerId())
            )
            Main.currentGroup = 0
            break
        end
        Citizen.Wait(250)
    end
end
Main.onGroupJoin = Main.onGroupJoin

-- ─────────────────────────────────────────────────
-- Main:openSpecificCategory(categoryName)
-- Tells the NUI to navigate to a specific category.
-- ─────────────────────────────────────────────────
function Main:openSpecificCategory(categoryName)
    for _, cat in ipairs(Config.Categories) do
        if cat.name == categoryName then
            Main:sendReactMessage("OPEN_CATEGORY", cat.name)
        end
    end
end
Main.openSpecificCategory = Main.openSpecificCategory

-- ─────────────────────────────────────────────────
-- Main:getSequence(name)
-- Returns the sequence object with the given name.
-- ─────────────────────────────────────────────────
function Main:getSequence(name)
    for _, seq in ipairs(self.sequences) do
        if seq.name == name then return seq end
    end
    return false
end
Main.getSequence = Main.getSequence

-- ─────────────────────────────────────────────────
-- Main:playSequence(name, ped)
-- Plays all items of a sequence in order with a
-- configurable pause between each step.
-- ─────────────────────────────────────────────────
function Main:playSequence(name, ped)
    ped = ped or cache.ped

    local seq = self:getSequence(name)
    if not seq then
        Trace("Sequence not found:", name)
        return false
    end

    if self.inSequence then return false end

    self:cancelEmote(ped, false, true)
    Wait(300)
    self.inSequence = true

    for _, item in pairs(seq.items) do
        self:playAnimation(ped, item.name, false, true)
        if item.seconds then
            Wait(item.seconds * 1000)
        end
        if not self.inSequence then
            Trace("Sequence canceled:", name)
            break
        end
        self:cancelEmote(ped, false, true)
        Wait(100)
    end

    self:cancelEmote(nil, false, false)
    self.inSequence = false
end
Main.playSequence = Main.playSequence

-- ─────────────────────────────────────────────────
-- Player selection state fields
-- ─────────────────────────────────────────────────
Main.playerSelectionActive = false
Main.selectedPlayerIndex   = 1
Main.nearbyPlayersList     = {}
Main.currentAnimation      = nil
Main.debugPlayerSelection  = false

-- ─────────────────────────────────────────────────
-- Main:showPlayerSelection(players, animName)
-- Shows a UI overlay to pick a nearby player for a
-- shared animation. Arrow keys cycle through the
-- list; E confirms, G cancels.
-- ─────────────────────────────────────────────────
function Main:showPlayerSelection(players, animName)
    -- Guard: clean up any stale selection
    if self.playerSelectionActive then
        Trace("Warning: Player selection already active, forcing cleanup")
        self.playerSelectionActive = false
        self.nearbyPlayersList     = {}
        self.currentAnimation      = nil
        Wait(100)
    end

    self.playerSelectionActive = true
    self.nearbyPlayersList     = players
    self.selectedPlayerIndex   = 1
    self.currentAnimation      = animName

    -- Sort by distance
    table.sort(self.nearbyPlayersList, function(a, b)
        return a.distance < b.distance
    end)

    if self.debugPlayerSelection then
        Trace("Player Selection: Found " .. #self.nearbyPlayersList .. " nearby players")
        for i, p in ipairs(self.nearbyPlayersList) do
            Trace(string.format("  [%d] ServerID: %d, Distance: %.2f", i, p.serverId, p.distance))
        end
    end

    Main:sendReactMessage("SHOW_MENU", { element = "showPlayerSelect", toggle = true })

    CreateThread(function()
        local startTime    = GetGameTimer()
        local timeoutMs    = 30000
        local originCoords = GetEntityCoords(cache.ped)

        while true do
            if not self.playerSelectionActive then break end
            Wait(0)

            -- Timeout
            if (GetGameTimer() - startTime) > timeoutMs then
                Trace("Player selection timeout - auto cancelling")
                self.playerSelectionActive = false
                Framework:Notify(Translate("SELECTION_TIMEOUT") or "Selection timed out")
                break
            end

            local myCoords = GetEntityCoords(cache.ped)

            -- Auto-cancel if no player is close enough
            local anyClose = false
            for _, p in ipairs(self.nearbyPlayersList) do
                if DoesEntityExist(p.ped) then
                    local dist = #(myCoords - GetEntityCoords(p.ped))
                    if dist <= 2.5 then anyClose = true; break end
                end
            end

            if not anyClose and #self.nearbyPlayersList > 0 then
                Trace("No nearby players anymore - auto cancelling")
                self.playerSelectionActive = false
                Framework:Notify(Translate("NO_PLAYER_NEARBY"))
                break
            end

            -- Draw markers above each candidate
            for i, p in ipairs(self.nearbyPlayersList) do
                if DoesEntityExist(p.ped) then
                    local headCoords = GetPedBoneCoords(p.ped, 31086, 0.0, 0.0, 0.0)
                    local markerPos  = vector3(headCoords.x, headCoords.y, headCoords.z + 0.5)
                    local isSelected = (i == self.selectedPlayerIndex)
                    local r = isSelected and 0   or 255
                    local g = isSelected and 255 or 0
                    local b = 0

                    if isSelected then
                        DrawMarker(
                            0,
                            markerPos.x, markerPos.y, markerPos.z + 0.2,
                            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.3, 0.3, 0.3,
                            r, g, b, 255,
                            false, true, 2,
                            false, nil, nil, false
                        )
                    end
                end
            end

            local function isJustPressed(code)
                return IsControlJustPressed(0, code) or IsDisabledControlJustPressed(0, code)
            end

            -- Cycle selection up (Up / Left arrow)
            if isJustPressed(172) or isJustPressed(174) then
                self.selectedPlayerIndex = self.selectedPlayerIndex - 1
                if self.selectedPlayerIndex < 1 then
                    self.selectedPlayerIndex = #self.nearbyPlayersList
                end
                Wait(200)

            -- Cycle selection down (Down / Right arrow)
            elseif isJustPressed(173) or isJustPressed(175) then
                self.selectedPlayerIndex = self.selectedPlayerIndex + 1
                if self.selectedPlayerIndex > #self.nearbyPlayersList then
                    self.selectedPlayerIndex = 1
                end
                Wait(200)

            -- Confirm (E)
            elseif isJustPressed(38) then
                local selected = self.nearbyPlayersList[self.selectedPlayerIndex]
                if not selected then break end
                if not DoesEntityExist(selected.ped) then break end
                self.playerSelectionActive = false
                Main:executeSharedAnimation(selected.serverId, selected.ped, animName)
                break

            -- Cancel (G)
            elseif isJustPressed(47) then
                self.playerSelectionActive = false
                Framework:Notify(Translate("SELECTION_CANCELLED") or "Selection cancelled")
                break
            end

            -- Block combat inputs during selection
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 142, true)
        end

        Main:sendReactMessage("SHOW_MENU", { element = "showPlayerSelect", toggle = false })
        self.playerSelectionActive = false
        self.nearbyPlayersList     = {}
        self.currentAnimation      = nil
        self.selectedPlayerIndex   = 1
    end)
end
Main.showPlayerSelection = Main.showPlayerSelection

-- Export: reset player selection state from outside
exports("resetPlayerSelection", function()
    Main.playerSelectionActive = false
    Main.nearbyPlayersList     = {}
    Main.currentAnimation      = nil
    Main.selectedPlayerIndex   = 1
    Trace("Player selection reset")
end)

-- ─────────────────────────────────────────────────
-- Main:executeSharedAnimation(targetServerId, targetPed, animName)
-- Sends a shared animation request to the target
-- player (or fires the sync event directly if the
-- animation has skip-request set).
-- ─────────────────────────────────────────────────
function Main:executeSharedAnimation(targetServerId, targetPed, animName)
    local localPlayer = GetPlayerFromServerId(targetServerId)
    if not (localPlayer and localPlayer ~= -1 and DoesEntityExist(targetPed)) then
        Framework:Notify(Translate("NO_PLAYER_NEARBY"))
        return
    end

    -- Helper: should this animation skip the request step?
    local function shouldSkipRequest(data)
        local name = data.name
        if Main.skipAnimations and Main.skipAnimations[name] then return true end

        if data.accepter and (data.accepter.skip or data.accepter.Skip) then
            return true
        end
        local sharedAnim = Main.sharedAnimations and Main.sharedAnimations[name]
        if sharedAnim then
            local opts = sharedAnim.animationOptions or sharedAnim.AnimationOptions
            if opts and (opts.skip or opts.Skip) then return true end
        end
        return false
    end

    local animData = type(animName) == "string" and { name = animName } or animName

    -- If animData is a stripped menu entry (no requester/accepter), enrich it
    -- from Config.Shared so the full data is available for request & sync flows
    if not animData.requester and not animData.accepter then
        for _, entry in ipairs(Config.Shared or {}) do
            if entry.name == animData.name then
                animData = entry
                break
            end
        end
    end

    local skip     = shouldSkipRequest(animData)

    -- Job restriction check
    if animData.jobs then
        local allowed = false
        for _, job in ipairs(animData.jobs) do
            if Framework:isCurrentJob(job) then allowed = true end
        end
        if not allowed then
            Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY"))
            return false
        end
    end

    local function syncConvertedOrRaw(anim)
        local sharedAnim = Main.sharedAnimations and Main.sharedAnimations[anim.name]
        if sharedAnim then
            local accepterCmd = sharedAnim[4] or anim.name
            TriggerServerEvent(eventName .. "server:syncConvertedAnimation",
                targetServerId, anim.name, accepterCmd)
        else
            TriggerServerEvent(eventName .. "server:syncAnimation", targetServerId, anim)
        end
    end

    if skip then
        -- Skip the request/accept flow
        syncConvertedOrRaw(animData)
    else
        -- Send request to target player
        local result = TriggerServerCallback({
            eventName = eventName .. "server:requestAnimation",
            args      = {{ target = targetServerId, animation = animData }},
        })

        if result.status then
            syncConvertedOrRaw(animData)
        else
            Framework:Notify(Translate("ANIMATION_REQUEST_DENIED"))
        end
    end
end
Main.executeSharedAnimation = Main.executeSharedAnimation

-- ─────────────────────────────────────────────────
-- Main:playSharedOnPeds(ped1, ped2, emoteName)
-- Directly plays a shared emote on two arbitrary
-- peds (bypasses the request flow). Returns true
-- on success.
-- ─────────────────────────────────────────────────
function Main:playSharedOnPeds(ped1, ped2, emoteName)
    if not self.localprops then self.localprops = {} end

    if not (ped1 and ped2) or not DoesEntityExist(ped1) or not DoesEntityExist(ped2) then
        Trace("playSharedOnPeds: invalid peds")
        return false
    end

    if not emoteName or type(emoteName) ~= "string" then
        Trace("playSharedOnPeds: invalid emote")
        return false
    end

    emoteName = string.lower(emoteName)
    self:cancelSharedPedEmote()

    -- Set up shared ped state
    self.sharedPedState = {
        ped1        = ped1,
        ped2        = ped2,
        emote       = emoteName,
        attachments = {},
    }

    -- Helper: attach one ped to another at the configured bone offset
    local function attachPed(attachedPed, anchorPed, attachOpts)
        AttachEntityToEntity(
            attachedPed, anchorPed,
            GetPedBoneIndex(anchorPed, attachOpts.bone or -1),
            attachOpts.xPosition or attachOpts.xPos or 0.0,
            attachOpts.yPosition or attachOpts.yPos or 0.0,
            attachOpts.zPosition or attachOpts.zPos or 0.0,
            attachOpts.xRotation or attachOpts.xRot or 0.0,
            attachOpts.yRotation or attachOpts.yRot or 0.0,
            attachOpts.zRotation or attachOpts.zRot or 0.0,
            false, false, false, true, 1, true
        )
        table.insert(self.sharedPedState.attachments, attachedPed)
    end

    -- Helper: play an animation on a ped
    local function playOnPed(targetPed, dict, clip, flag, duration)
        self:loadAnim(dict)
        TaskPlayAnim(
            targetPed, dict, clip,
            2.0, -2.0,
            duration or -1,
            flag or 0,
            0, false, false, false
        )
    end

    -- Helper: position the second ped relative to the first using syncOffset
    local function positionRelativeTo(moverPed, anchorPed, animOpts)
        if not animOpts then return end
        local opts = animOpts.animationOptions
        if not opts then return end
        if not (opts.syncOffsetFront or opts.syncOffsetSide or opts.syncOffsetHeight) then return end

        local side    = opts.syncOffsetSide    or 0.0
        local front   = opts.syncOffsetFront   or 1.0
        local height  = opts.syncOffsetHeight  or 0.0
        local heading = opts.syncOffsetHeading or 180.0

        local offset  = GetOffsetFromEntityInWorldCoords(anchorPed, side, front, height)
        SetEntityHeading(moverPed, GetEntityHeading(anchorPed) - heading)
        SetEntityCoordsNoOffset(moverPed, offset.x, offset.y, offset.z)

        -- Attach if configured
        if opts.attachTo then
            AttachEntityToEntity(
                moverPed, anchorPed,
                GetPedBoneIndex(anchorPed, opts.bone or -1),
                opts.xPos or 0.0, opts.yPos or 0.0, opts.zPos or 0.0,
                opts.xRot or 0.0, opts.yRot or 0.0, opts.zRot or 0.0,
                false, false, false, true, 1, true
            )
            table.insert(self.sharedPedState.attachments, moverPed)
        end
    end

    -- Helper: determine movement flag from animation options
    local function getMovementType(animEntry)
        if not animEntry then return 0 end
        local opts = animEntry.animationOptions
        if not opts then return 0 end
        if opts.emoteStuck   then return 50 end
        if opts.emoteLoop    then return opts.emoteMoving and 51 or 1 end
        if opts.emoteMoving  then return 51 end
        return 0
    end

    -- Helper: add props to a ped from its animation options
    local function addPropsForPed(targetPed, animEntry)
        if not animEntry then return end
        local opts = animEntry.animationOptions
        if not opts or not opts.prop then return end
        local bone      = opts.propBone or 60309
        local placement = opts.propPlacement
        if not placement or #placement < 6 then return end
        local p1, p2, p3, p4, p5, p6 = table.unpack(placement)
        self:addProp(opts.prop, bone, p1, p2, p3, p4, p5, p6, targetPed)

        if opts.secondProp and opts.secondPropPlacement and #opts.secondPropPlacement >= 6 then
            local sp1, sp2, sp3, sp4, sp5, sp6 = table.unpack(opts.secondPropPlacement)
            local sBone = opts.secondPropBone or bone
            self:addProp(opts.secondProp, sBone, sp1, sp2, sp3, sp4, sp5, sp6, targetPed)
        end
    end

    -- Look up the shared animation definition
    local sharedAnim = self.sharedAnimations and self.sharedAnimations[emoteName]

    if sharedAnim then
        -- Resolve alternate (linked) animation
        local altAnim = nil
        if sharedAnim[4] then
            altAnim = self.sharedAnimations and self.sharedAnimations[sharedAnim[4]]
        end

        ClearPedTasksImmediately(ped1)
        ClearPedTasksImmediately(ped2)

        -- Play on each ped
        positionRelativeTo(ped2, ped1, sharedAnim)
        positionRelativeTo(ped1, ped2, altAnim)

        playOnPed(ped1, sharedAnim[1], sharedAnim[2], getMovementType(sharedAnim),
            sharedAnim.animationOptions and sharedAnim.animationOptions.emoteDuration or -1)

        playOnPed(ped2, altAnim and altAnim[1] or sharedAnim[1],
            altAnim and altAnim[2] or sharedAnim[2],
            getMovementType(altAnim or sharedAnim),
            (altAnim or sharedAnim).animationOptions and
            (altAnim or sharedAnim).animationOptions.emoteDuration or -1)

        -- Attach / props
        if sharedAnim.animationOptions and sharedAnim.animationOptions.attach then
            attachPed(ped1, ped2, sharedAnim.animationOptions.attach)
        end
        if altAnim and altAnim.animationOptions and altAnim.animationOptions.attach then
            attachPed(ped2, ped1, altAnim.animationOptions.attach)
        end

        addPropsForPed(ped1, sharedAnim)
        addPropsForPed(ped2, altAnim)
        if altAnim then addPropsForPed(ped2, altAnim) end

        return true
    end

    -- Emote not found
    self.sharedPedState = nil
    Trace("playSharedOnPeds: emote not found", emoteName)
    return false
end
Main.playSharedOnPeds = Main.playSharedOnPeds

-- ─────────────────────────────────────────────────
-- Main:cancelSharedPedEmote(ped1, ped2, deletePeds)
-- Cancels a shared ped emote, detaches entities,
-- destroys props, and optionally deletes non-player
-- peds.
-- ─────────────────────────────────────────────────
function Main:cancelSharedPedEmote(ped1, ped2, deletePeds)
    local state = self.sharedPedState

    -- Determine which peds to clean up
    local peds = {}
    if ped1 or (state and state.ped1) then peds[1] = ped1 or (state and state.ped1) end
    if ped2 or (state and state.ped2) then peds[2] = ped2 or (state and state.ped2) end

    for _, p in ipairs(peds) do
        if p and DoesEntityExist(p) then
            DetachEntity(p, true, false)
            ClearPedTasks(p)
        end

        -- Destroy pedProps
        if p and self.pedProps and self.pedProps[p] then
            for _, prop in ipairs(self.pedProps[p]) do
                if DoesEntityExist(prop) then DeleteEntity(prop) end
            end
            self.pedProps[p] = nil
        end

        -- Delete non-player peds if requested
        if p and deletePeds and DoesEntityExist(p) then
            if not IsPedAPlayer(p) then DeleteEntity(p) end
        end
    end

    -- Detach attachment entities
    if state and state.attachments then
        for _, attached in ipairs(state.attachments) do
            if DoesEntityExist(attached) then
                DetachEntity(attached, true, false)
            end
        end
    end

    -- Destroy local preview props
    if self.localprops and #self.localprops > 0 then
        for _, prop in ipairs(self.localprops) do
            if DoesEntityExist(prop) then DeleteEntity(prop) end
        end
        self.localprops = {}
    end

    self.sharedPedState = nil
end
Main.cancelSharedPedEmote = Main.cancelSharedPedEmote

-- ═══════════════════════════════════════════════════
-- Config.animationTypes
-- Handlers called by playAnimation() for each type.
-- ═══════════════════════════════════════════════════
Config.animationTypes = {}

-- Expression
function Config.animationTypes.expression(ped, anim, _ignoreCooldown)
    SetFacialIdleAnimOverride(ped, anim.animation, 0)
    if Config.Logs then
        TriggerServerEvent(eventName .. "server:sendWebhook", "SET_EXPRESSION", anim.name)
    end
    Main:Set("expression", anim.name)
end

-- Weapon style
function Config.animationTypes.weaponstyles(ped, anim, _ignoreCooldown)
    if not Config.CustomGunStyles then return end

    -- Job restriction
    if anim.jobs then
        local allowed = false
        for _, job in ipairs(anim.jobs) do
            if Framework:isCurrentJob(job) then allowed = true end
        end
        if not allowed then
            Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY"))
            return false
        end
    end

    SetWeaponAnimationOverride(ped, anim.style)
    ClearPedTasks(ped)

    if Config.Logs then
        TriggerServerEvent(eventName .. "server:sendWebhook", "SET_WEAPON_STYLE", anim.name)
    end

    Main:Set("weaponstyle", anim.name)
    Entity(ped).state:set("weaponstyle", anim.name, true)

    -- Revert if current weapon is not in the allowed list
    if IsPedArmed(ped, 4) then
        if not Main:allowedWeapon() then
            SetWeaponAnimationOverride(ped, "default")
        end
    else
        SetWeaponAnimationOverride(ped, "default")
    end
end

-- Scenario
function Config.animationTypes.scenario(ped, anim, _ignoreCooldown)
    TaskStartScenarioInPlace(ped, anim.animation, 0, false)
    if Config.Logs then
        TriggerServerEvent(eventName .. "server:sendWebhook", "PLAYED_ANIMATION", anim.name)
    end
end

-- Walking style
function Config.animationTypes.walkingstyle(ped, anim, _ignoreCooldown)
    Citizen.CreateThread(function()
        if not anim.animation then
            ResetPedMovementClipset(ped, 0.5)
            Main:Set("walkingstyle", "")
            return
        end

        RequestAnimSet(anim.animation)
        while not HasAnimSetLoaded(anim.animation) do
            Citizen.Wait(0)
        end
        SetPedMovementClipset(ped, anim.animation, 0.5)

        if Config.Logs then
            TriggerServerEvent(eventName .. "server:sendWebhook", "SET_WALKINGSTYLE", anim.name)
        end
        Main:Set("walkingstyle", anim.name)
    end)
end

-- Standard animation
function Config.animationTypes.animation(ped, anim, ignoreCooldown)
    Main:playEmote(anim, ped, ignoreCooldown, false)
end

-- Sequence
function Config.animationTypes.sequence(ped, anim, _ignoreCooldown)
    Main:playSequence(anim.name, ped)
end

-- Shared animation
function Config.animationTypes.shared(ped, anim, _ignoreCooldown)
    local myCoords = GetEntityCoords(ped)
    local nearby   = {}

    for _, playerId in ipairs(GetActivePlayers()) do
        local playerPed = GetPlayerPed(playerId)
        if playerPed ~= ped and DoesEntityExist(playerPed) and IsPedAPlayer(playerPed) then
            local dist = #(myCoords - GetEntityCoords(playerPed))
            if dist <= 2.5 then
                table.insert(nearby, {
                    playerId = playerId,
                    serverId = GetPlayerServerId(playerId),
                    ped      = playerPed,
                    coords   = GetEntityCoords(playerPed),
                    distance = dist,
                })
            end
        end
    end

    if #nearby == 0 then
        Framework:Notify(Translate("NO_PLAYER_NEARBY"))
        return
    end

    if #nearby == 1 then
        return Main:executeSharedAnimation(nearby[1].serverId, nearby[1].ped, anim)
    end

    Main:showPlayerSelection(nearby, anim)
end

Main.animationTypes = Config.animationTypes

-- ═══════════════════════════════════════════════════
-- Exports
-- ═══════════════════════════════════════════════════

exports("resetClipset", function()
    Main:resetClipset()
end)

exports("setWalkingstyle", function()
    if not Main.walkingstyle then
        Main:resetClipset()
        Trace("Walkingstyle not found")
        return
    end
    Main:playAnimation(cache.ped, Main.walkingstyle)
end)

exports("setExpression", function()
    if not Main.expression then
        Trace("Expression not found")
        return
    end
    Main:playAnimation(cache.ped, Main.expression)
end)

exports("openApp", function()
    Main:openApp()
end)

exports("canAccess", function()
    return Main.inAction
end)

exports("setAccess", function(value)
    Main.inAction = not value
end)

exports("playAnimation", function(ped, animName)
    Main:playAnimation(ped, animName)
end)

exports("playSharedEmote", function(ped1, ped2, emoteName)
    return Main:playSharedOnPeds(ped1, ped2, emoteName)
end)

exports("cancelSharedEmote", function(ped1, ped2, deletePeds)
    Main:cancelSharedPedEmote(ped1, ped2, deletePeds)
end)

exports("isMenuOpen", function()
    return Main.inAction
end)

exports("canCancel", function()
    return Main.isBusy
end)

exports("disableCancelAnimation", function(value)
    Main.isBusy = value
end)

exports("playEmoteData", function(animData, ped)
    if not animData then
        Trace("playEmoteData: No animation data provided")
        return false
    end
    if not animData[1] or not animData[2] then
        Trace("playEmoteData: Animation data must have dict [1] and anim [2]")
        return false
    end
    ped = ped or cache.ped
    -- Ensure [3] (name) has a value
    if not animData[3] then animData[3] = animData[2] end
    return Main:playEmote(animData, ped)
end)

exports("cancelEmote", function(ped)
    ped = ped or cache.ped
    Main:cancelEmote(ped)
end)

exports("isInAnimation", function()
    return LocalPlayer.state and LocalPlayer.state.isInAnimation and true or false
end)

exports("getCurrentAnimation", function()
    local state = LocalPlayer.state and LocalPlayer.state.isInAnimation
    return state or nil
end)

exports("disableModules", function(value)
    Main.disableModules = value
end)

exports("setPlayerSelectionDebug", function(value)
    Main.debugPlayerSelection = value == true
    Trace("Player Selection Debug:", Main.debugPlayerSelection and "ENABLED" or "DISABLED")
end)

exports("isEditingPosition", function()
    return DoesEntityExist(Main.pedHandle)
end)

exports("isLoaded", function()
    return Main.isLoaded
end)

exports("getPlayerSelectionState", function()
    return {
        active       = Main.playerSelectionActive,
        selectedIndex = Main.selectedPlayerIndex,
        nearbyCount  = #Main.nearbyPlayersList,
        debug        = Main.debugPlayerSelection,
    }
end)

-- ─────────────────────────────────────────────────
-- Debug / utility commands
-- ─────────────────────────────────────────────────

RegisterCommand("reload_animationsmenu", function()
    Trace("cmd: reload_animationsmenu  ran reloading... ")
    Main.inAction = false
    Main:Init(true)
end)

RegisterCommand("anim_debug_selection", function()
    Main.debugPlayerSelection = not Main.debugPlayerSelection
    Framework:Notify("Player Selection Debug: " .. (Main.debugPlayerSelection and "ENABLED" or "DISABLED"))
    Trace("Player Selection Debug:", Main.debugPlayerSelection and "ENABLED" or "DISABLED")
end, false)

RegisterCommand("anim_reset_selection", function()
    exports["bablo-animations"]:resetPlayerSelection()
    Framework:Notify("Player selection reset")
end, false)

-- Alias: c_main.lua calls Main:OpenMenu() but the method is defined as Main:openApp()
Main.OpenMenu = Main.openApp