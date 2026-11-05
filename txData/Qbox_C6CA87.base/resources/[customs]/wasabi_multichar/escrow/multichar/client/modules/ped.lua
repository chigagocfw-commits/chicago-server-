local Appearance = nil
local PedController = lib.class("PedController")

function PedController:constructor()
    self.peds = {}
    self.props = {}
    self.vehicles = {}
    self.cam = nil
    self.showcaseDummyPed = nil
    self.currentLocationSet = nil
    self.cinematicRunning = false
    self.mugshotHandles = {}
end

function PedController:pickRandomLocationSet(characterCount)
    local previewLocations = Config.PreviewLocations
    if not previewLocations then
        return nil
    end

    local exactSlotLocations = {}
    local defaultLocations = {}
    local allLocations = {}

    for locationKey, locationData in pairs(previewLocations) do
        if locationData then
            table.insert(allLocations, locationKey)

            if locationData.minSlots then
                if characterCount and characterCount == locationData.minSlots then
                    table.insert(exactSlotLocations, locationKey)
                end
            else
                table.insert(defaultLocations, locationKey)
            end
        end
    end

    local candidatePool = allLocations
    if #exactSlotLocations > 0 then
        candidatePool = exactSlotLocations
    elseif #defaultLocations > 0 then
        candidatePool = defaultLocations
    end

    if #candidatePool == 0 then
        return nil
    end

    table.sort(candidatePool)
    local chosenIndex = math.random(1, #candidatePool)
    local chosenKey = candidatePool[chosenIndex]

    self.currentLocationSet = Config.PreviewLocations[chosenKey]
    return self.currentLocationSet
end

function LoadInteriorAtCoords(coords)
    if not coords then
        return
    end

    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if interiorId and interiorId ~= 0 then
        LoadInterior(interiorId)
        local attempts = 0
        while not IsInteriorReady(interiorId) and attempts < 100 do
            Wait(100)
            attempts = attempts + 1
        end
    end
end

function RequestLocationIPLs(iplList)
    if not iplList then
        return
    end

    for _, iplName in ipairs(iplList) do
        if not IsIplActive(iplName) then
            RequestIpl(iplName)
        end
    end
end

function RemoveLocationIPLs(iplList)
    if not iplList then
        return
    end

    for _, iplName in ipairs(iplList) do
        if IsIplActive(iplName) then
            RemoveIpl(iplName)
        end
    end
end

function PedController:spawnLocationVehicles()
    local locationSet = self.currentLocationSet
    if not locationSet or not locationSet.vehicles then
        return
    end

    for _, vehicleData in ipairs(locationSet.vehicles) do
        local modelHash = type(vehicleData.model) == "string" and joaat(vehicleData.model) or vehicleData.model
        lib.requestModel(modelHash)

        local pos = vehicleData.pos
        local heading = pos.w or 0.0
        local vehicle = CreateVehicle(modelHash, pos.x, pos.y, pos.z, heading, false, false)

        if vehicle and DoesEntityExist(vehicle) then
            FreezeEntityPosition(vehicle, true)
            SetEntityInvincible(vehicle, true)
            SetVehicleDoorsLocked(vehicle, 2)
            table.insert(self.vehicles, vehicle)
        end

        SetModelAsNoLongerNeeded(modelHash)
    end
end

function PedController:clearLocationVehicles()
    for _, vehicle in ipairs(self.vehicles) do
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
    self.vehicles = {}
end

function ApplyPedAppearance(ped, appearanceData)
    if not appearanceData then
        return
    end

    local skinData = appearanceData
    if type(appearanceData) == "string" then
        skinData = json.decode(appearanceData)
    end

    if not skinData then
        return
    end

    local success = pcall(function()
        if GetResourceState("rcore_clothing") == "started" then
            exports["rcore_clothing"]:setPedSkin(ped, skinData)
            return
        end

        if GetResourceState("illenium-appearance") == "started" then
            exports["illenium-appearance"]:setPedAppearance(ped, skinData)
            return
        end

        if GetResourceState("fivem-appearance") == "started" then
            exports["fivem-appearance"]:setPedAppearance(ped, skinData)
            return
        end

        if GetResourceState("qb-clothing") == "started" then
            TriggerEvent("qb-clothing:client:loadPlayerClothing", skinData, ped)
            return
        end

        if Appearance and Appearance.applyPedSkinFallback then
            Appearance.applyPedSkinFallback(ped, skinData)
        end
    end)

    if not success then
        lib.print.debug("[wasabi_multichar] setPedAppearance failed for ped " .. tostring(ped))
    end
end

function PedController:startCamera()
    if self.cam then
        return
    end

    local locationSet = self.currentLocationSet
    local startCam = locationSet and locationSet.startCam
    local cinematicCam = locationSet and locationSet.cinematicCam
    local camCoords = startCam or (cinematicCam and cinematicCam.pos)

    if not camCoords then
        return
    end

    local x = camCoords.x or camCoords[1]
    local y = camCoords.y or camCoords[2]
    local z = camCoords.z or camCoords[3]

    self.cam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        x, y, z,
        0.0, 0.0, 289.6153,
        60.0,
        false, 0
    )

    if not startCam and cinematicCam and cinematicCam.pointAt then
        local target = cinematicCam.pointAt
        PointCamAtCoord(self.cam, target.x, target.y, target.z)
    end

    SetCamActive(self.cam, true)
    RenderScriptCams(true, false, 1, true, true)
    ShakeCam(self.cam, "HAND_SHAKE", 0.35)

    local firstSlot = locationSet and locationSet.slots and locationSet.slots[1]
    if firstSlot and firstSlot.anim and firstSlot.anim.type == "animation" and firstSlot.anim.dict then
        lib.requestAnimDict(firstSlot.anim.dict)
    end
end

function PedController:setCameraToSlot(slot)
    self:stopCinematicLoop()

    local locationSet = self.currentLocationSet
    local slotData = locationSet and locationSet.slots and locationSet.slots[slot]

    if not slotData or not slotData.cam then
        return
    end

    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(200)
        while not IsScreenFadedIn() do
            Wait(5)
        end
    end

    local camCoords = slotData.cam
    local targetPos = slotData.pos

    if locationSet.useFladeAnim then
        local previousCam = self.cam
        local camTarget = {
            x = camCoords.x,
            y = camCoords.y,
            z = camCoords.z,
            w = camCoords.w or 0.0
        }
        local lookTarget = {
            x = targetPos.x,
            y = targetPos.y,
            z = targetPos.z
        }

        CreateThread(function()
            DoScreenFadeOut(400)
            while not IsScreenFadedOut() do
                Wait(10)
            end

            if previousCam and DoesEntityExist(previousCam) then
                DestroyCam(previousCam, false)
            end

            local newCam = CreateCamWithParams(
                "DEFAULT_SCRIPTED_CAMERA",
                camTarget.x, camTarget.y, camTarget.z,
                0.0, 0.0, camTarget.w,
                GetGameplayCamFov(),
                true, 2
            )

            PointCamAtCoord(newCam, lookTarget.x, lookTarget.y, lookTarget.z)
            ClearTimecycleModifier()
            ShakeCam(newCam, "HAND_SHAKE", 0.25)
            SetCamActive(newCam, true)
            RenderScriptCams(true, false, 0, true, false)

            self.cam = newCam
            Wait(150)
            DoScreenFadeIn(500)
        end)
        return
    end

    local newCam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camCoords.x, camCoords.y, camCoords.z,
        0.0, 0.0, camCoords.w or 0.0,
        GetGameplayCamFov(),
        true, 2
    )

    PointCamAtCoord(newCam, targetPos.x, targetPos.y, targetPos.z)
    ClearTimecycleModifier()
    ShakeCam(newCam, "HAND_SHAKE", 0.25)

    if self.cam then
        SetCamActive(newCam, true)
        SetCamActiveWithInterp(newCam, self.cam, 800, 1, 1)
        DestroyCam(self.cam, false)
    else
        SetCamActive(newCam, true)
        RenderScriptCams(true, false, 0, true, false)
    end

    self.cam = newCam
end

function ApplyCameraDofEffects(cam)
    SetTimecycleModifier("hud_def_blur")
    SetTimecycleModifierStrength(0.5)
    SetCamUseShallowDofMode(cam, true)
    SetCamNearDof(cam, 0.4)
    SetCamFarDof(cam, 1.8)
    SetCamDofStrength(cam, 0.7)
    ShakeCam(cam, "HAND_SHAKE", 0.2)
end

function PedController:startCinematicCam()
    if self.cam then
        return
    end

    local locationSet = self.currentLocationSet
    local cinematic = locationSet and locationSet.cinematicCam

    local camPos = (cinematic and cinematic.pos) or vector3(2719.5703, 1567.6654, 66.7429)
    local targetPos = (cinematic and cinematic.pointAt) or vector3(2729.2446, 1574.6409, 65.4772)

    local cam = CreateCamWithParams(
        "DEFAULT_SCRIPTED_CAMERA",
        camPos.x, camPos.y, camPos.z,
        0.0, 0.0, 0.0,
        GetGameplayCamFov(),
        true, 2
    )

    self.cam = cam
    ApplyCameraDofEffects(self.cam)
    PointCamAtCoord(self.cam, targetPos.x, targetPos.y, targetPos.z)
    SetCamActive(self.cam, true)
    RenderScriptCams(true, true, 0, true, false)

    local waypoints = locationSet and locationSet.waypoints
    if not waypoints or #waypoints == 0 then
        return
    end

    self.cinematicRunning = true
    local totalWaypoints = #waypoints

    CreateThread(function()
        Wait(7000)

        if not (self.cinematicRunning and self.cam) then
            return
        end

        DoScreenFadeOut(600)
        while not IsScreenFadedOut() do
            Wait(10)
        end

        if not self.cam then
            return
        end

        local initialWp = waypoints[1]
        SetCamCoord(self.cam, initialWp.pos.x, initialWp.pos.y, initialWp.pos.z)
        PointCamAtCoord(self.cam, initialWp.pointAt.x, initialWp.pointAt.y, initialWp.pointAt.z)
        ApplyCameraDofEffects(self.cam)
        Wait(200)
        DoScreenFadeIn(800)

        local currentIndex = 1

        while self.cinematicRunning and self.cam do
            local currentWp = waypoints[currentIndex]
            if not currentWp then
                break
            end

            local nextIndex = (currentIndex % totalWaypoints) + 1
            local nextWp = waypoints[nextIndex]
            if not nextWp then
                break
            end

            local duration = currentWp.duration or 8000
            local nextCam = CreateCamWithParams(
                "DEFAULT_SCRIPTED_CAMERA",
                nextWp.pos.x, nextWp.pos.y, nextWp.pos.z,
                0.0, 0.0, 0.0,
                GetGameplayCamFov(),
                true, 2
            )

            PointCamAtCoord(nextCam, nextWp.pointAt.x, nextWp.pointAt.y, nextWp.pointAt.z)
            ApplyCameraDofEffects(nextCam)
            SetCamActive(nextCam, true)
            SetCamActiveWithInterp(nextCam, self.cam, duration, 1, 1)

            local elapsed = 0
            while duration > elapsed do
                if not self.cinematicRunning or not self.cam then
                    break
                end
                Wait(50)
                elapsed = elapsed + 50
            end

            if not (self.cinematicRunning and self.cam) then
                DestroyCam(nextCam, false)
                break
            end

            DestroyCam(self.cam, false)
            self.cam = nextCam

            local followingIndex = (nextIndex % totalWaypoints) + 1
            local followingWp = waypoints[followingIndex]
            if not followingWp then
                break
            end

            DoScreenFadeOut(600)
            while not IsScreenFadedOut() do
                Wait(10)
            end

            if not self.cam or not self.cinematicRunning then
                break
            end

            SetCamCoord(self.cam, followingWp.pos.x, followingWp.pos.y, followingWp.pos.z)
            PointCamAtCoord(self.cam, followingWp.pointAt.x, followingWp.pointAt.y, followingWp.pointAt.z)
            ApplyCameraDofEffects(self.cam)
            Wait(200)
            DoScreenFadeIn(800)

            currentIndex = followingIndex
        end
    end)
end

function PedController:stopCinematicLoop()
    self.cinematicRunning = false
end

function PedController:captureMugshot(slot, ped)
    CreateThread(function()
        Wait(500)

        if not DoesEntityExist(ped) then
            return
        end

        local handle = RegisterPedheadshot(ped)
        local remainingWait = 2000

        while remainingWait > 0 do
            if handle and IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
                break
            end
            Wait(10)
            remainingWait = remainingWait - 10
        end

        local txdString = "none"
        if handle and IsPedheadshotReady(handle) and IsPedheadshotValid(handle) then
            txdString = GetPedheadshotTxdString(handle)
            self.mugshotHandles[slot] = handle
        end

        SendNUIMessage({
            type = "MUGSHOT_CONVERT",
            slot = slot,
            txd = txdString,
            handleId = handle
        })
    end)
end

function PedController:spawnPed(slot, characterId)
    local locationSet = self.currentLocationSet
    local slotConfig = locationSet and locationSet.slots and locationSet.slots[slot]

    if not slotConfig or not slotConfig.pos then
        return
    end

    local previewSkin, previewModel = lib.callback.await("wasabi_multichar:getPedPreview", false, characterId)

    local modelHash = 1885233650
    if tonumber(previewModel) then
        modelHash = tonumber(previewModel)
    elseif type(previewModel) == "string" then
        modelHash = joaat(previewModel)
    end

    lib.requestModel(modelHash)

    local anim = slotConfig.anim
    if anim and anim.type == "animation" and anim.dict then
        lib.requestAnimDict(anim.dict)
    end

    local pos = slotConfig.pos
    local ped = CreatePed(4, modelHash, pos.x, pos.y, pos.z - 1.0, pos.w or 0.0, false, true)

    if previewSkin then
        ApplyPedAppearance(ped, previewSkin)
    end

    FreezeEntityPosition(ped, true)

    if anim then
        if anim.type == "animation" and anim.dict and anim.clip then
            local isAttached = slotConfig.attachToSlot ~= nil
            TaskPlayAnim(ped, anim.dict, anim.clip, 2.0, 2.0, -1, 1, 0, isAttached, isAttached, isAttached)

            if slotConfig.attachToSlot then
                local attachTarget = self.peds[slotConfig.attachToSlot]
                if attachTarget and DoesEntityExist(attachTarget) then
                    AttachEntityToEntityPhysically(
                        ped, attachTarget,
                        GetPedBoneIndex(ped, 58866),
                        GetPedBoneIndex(attachTarget, 57005),
                        0, 0, 0, 0, 50, 0, 0, 0, 0, 0,
                        true, false, false, false, 0
                    )
                end
            end
        elseif anim.type == "scenario" and anim.name then
            TaskStartScenarioInPlace(ped, anim.name, -1, true)
        end
    end

    if anim then
        local propList = {}
        if anim.prop then
            table.insert(propList, anim.prop)
        end
        if anim.secondProp then
            table.insert(propList, anim.secondProp)
        end

        for _, propConfig in ipairs(propList) do
            local propModel = type(propConfig.model) == "string" and joaat(propConfig.model) or propConfig.model
            lib.requestModel(propModel)

            local boneIndex = GetPedBoneIndex(ped, propConfig.bone or 28422)
            local placement = propConfig.placement or {}

            local propObj = CreateObject(propModel, pos.x, pos.y, pos.z, true, true, false)
            AttachEntityToEntity(
                propObj, ped, boneIndex,
                placement[1] or 0.0, placement[2] or 0.0, placement[3] or 0.0,
                placement[4] or 0.0, placement[5] or 0.0, placement[6] or 0.0,
                true, true, false, true, 1, true
            )

            SetModelAsNoLongerNeeded(propModel)
            table.insert(self.props, propObj)
        end
    end

    SetPedComponentVariation(ped, 0, 0, 0, 2)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    self.peds[slot] = ped
    SetModelAsNoLongerNeeded(modelHash)

    self:captureMugshot(slot, ped)
    return ped
end

function PedController:spawnShowcaseDummyPed()
    self:clearShowcaseDummyPed()

    local locationSet = self.currentLocationSet
    local hiddenCoords = locationSet and (locationSet.hiddenCoords or (locationSet.slots and locationSet.slots[1] and locationSet.slots[1].pos))

    if not hiddenCoords then
        return
    end

    local defaultModel = 1885233650
    RequestModel(defaultModel)
    while not HasModelLoaded(defaultModel) do
        Wait(1)
    end

    local dummyPed = CreatePed(4, defaultModel, hiddenCoords.x, hiddenCoords.y, hiddenCoords.z - 1.0, hiddenCoords.w or 0.0, false, true)
    SetModelAsNoLongerNeeded(defaultModel)

    SetEntityVisible(dummyPed, false, false)
    FreezeEntityPosition(dummyPed, true)
    SetEntityInvincible(dummyPed, true)
    SetBlockingOfNonTemporaryEvents(dummyPed, true)

    self.showcaseDummyPed = dummyPed

    RequestCollisionAtCoord(hiddenCoords.x, hiddenCoords.y, hiddenCoords.z)
    local attempts = 0
    while not HasCollisionLoadedAroundEntity(dummyPed) and attempts < 200 do
        Wait(10)
        attempts = attempts + 1
    end
end

function PedController:clearShowcaseDummyPed()
    if self.showcaseDummyPed and DoesEntityExist(self.showcaseDummyPed) then
        DeleteEntity(self.showcaseDummyPed)
    end
    self.showcaseDummyPed = nil
end

function PedController:stopCinematicCam()
    self:stopCinematicLoop()

    local locationSet = self.currentLocationSet

    if self.cam then
        ShakeCam(self.cam, "HAND_SHAKE", 0)
        ShakeCinematicCam(self.cam, 0.1)

        local stopParams = locationSet and locationSet.stopCamParams
        if stopParams then
            local duration = stopParams.duration or stopParams.durationDrop or stopParams.durationHeadbutt or 5000
            SetCamParams(
                self.cam,
                stopParams.x, stopParams.y, stopParams.z,
                stopParams.rotX or 2, stopParams.rotY or 0, stopParams.rotZ or 0,
                GetGameplayCamFov(),
                duration, 0, 0, 2
            )
        end

        RenderScriptCams(true, true, 1000, false, true)
    end

    DoScreenFadeOut(750)
    Wait(950)

    if self.cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(self.cam, false)
        self.cam = nil
    end

    Wait(500)
    ClearTimecycleModifier()

    self:clearPeds()
    self:clearLocationVehicles()
    self:clearShowcaseDummyPed()

    if locationSet and locationSet.ipls then
        RemoveLocationIPLs(locationSet.ipls)
    end
end

function PedController:loadScene(characters)
    local characterCount = 0
    if characters and type(characters) == "table" then
        for _, item in ipairs(characters) do
            if item and item.character and item.character.id then
                characterCount = characterCount + 1
            end
        end
    end

    self:pickRandomLocationSet(characterCount)

    local locationSet = self.currentLocationSet
    if not locationSet then
        return
    end

    if locationSet.ipls then
        RequestLocationIPLs(locationSet.ipls)
        Wait(500)
    end

    if locationSet.hiddenCoords then
        local playerPed = PlayerPedId()
        SetEntityVisible(playerPed, false, false)
        SetEntityCoords(playerPed, locationSet.hiddenCoords.x, locationSet.hiddenCoords.y, locationSet.hiddenCoords.z, false, false, false, false)
        SetEntityHeading(playerPed, locationSet.hiddenCoords.w or 0.0)
        FreezeEntityPosition(playerPed, true)

        RequestCollisionAtCoord(locationSet.hiddenCoords.x, locationSet.hiddenCoords.y, locationSet.hiddenCoords.z)
        local attempts = 0
        while not HasCollisionLoadedAroundEntity(playerPed) and attempts < 200 do
            Wait(10)
            attempts = attempts + 1
        end
    end

    if locationSet.pedInterior then
        LoadInteriorAtCoords(locationSet.pedInterior)
    end

    self:spawnShowcaseDummyPed()
    self:spawnLocationVehicles()
    self:startCinematicCam()
end

function PedController:setPedsFromCharacters(characters)
    self:clearPeds()

    local locationSet = self.currentLocationSet
    if not (locationSet and locationSet.slots and characters) then
        return
    end

    for _, item in ipairs(characters) do
        local slot = item.slot
        local character = item.character
        if character and character.id and locationSet.slots[slot] then
            self:spawnPed(slot, character.id)
        end
    end
end

function PedController:clearPeds()
    for _, prop in pairs(self.props) do
        if DoesEntityExist(prop) then
            DetachEntity(prop, true, true)
            DeleteEntity(prop)
        end
    end
    self.props = {}

    for _, handle in pairs(self.mugshotHandles) do
        if handle then
            UnregisterPedheadshot(handle)
        end
    end
    self.mugshotHandles = {}

    for _, ped in pairs(self.peds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    self.peds = {}
end

function PedController:destroy()
    self:stopCinematicLoop()
    self:clearPeds()
    self:clearLocationVehicles()
    self:clearShowcaseDummyPed()

    if self.currentLocationSet and self.currentLocationSet.ipls then
        RemoveLocationIPLs(self.currentLocationSet.ipls)
    end

    self.currentLocationSet = nil

    if self.cam then
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(self.cam, false)
        self.cam = nil
    end

    ClearTimecycleModifier()
end

function PedController.init()
    Appearance = Modules.require("Appearance")
end

Modules.register("PedController", PedController, {
    dependencies = { "Appearance" }
})
