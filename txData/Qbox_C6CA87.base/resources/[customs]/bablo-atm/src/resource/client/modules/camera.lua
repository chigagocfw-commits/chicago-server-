local activeCamera = nil
local pedHidden = false
local originalPedAlpha = nil

local function hideLocalPed()
    if not Config.CameraSettings.HidePlayerPed or pedHidden then
        return
    end

    local ped = PlayerPedId()
    originalPedAlpha = GetEntityAlpha(ped)
    SetEntityAlpha(ped, 0, false)
    SetEntityVisible(ped, false, false)
    pedHidden = true
end

local function restoreLocalPed()
    if not pedHidden then
        return
    end

    local ped = PlayerPedId()
    SetEntityAlpha(ped, originalPedAlpha or 255, false)
    SetEntityVisible(ped, true, false)
    pedHidden = false
    originalPedAlpha = nil
end

local function getCameraSetting(settingName, model, fallback)
    local settings = Config.CameraSettings[settingName]

    if settings then
        return settings[model] or settings.Default or fallback
    end

    return fallback
end

local function destroyExistingCamera()
    if activeCamera and DoesCamExist(activeCamera) then
        DestroyCam(activeCamera, false)
        activeCamera = nil
    end
end

local function createAtmCamera(atmEntity)
    if not DoesEntityExist(atmEntity) then
        return false
    end

    local model = GetEntityModel(atmEntity)
    local camOffset = getCameraSetting("CamOffsets", model, vector3(-0.09994507, -0.4500122, 1.379971))
    local camRot = getCameraSetting("CamRots", model, vector3(-0.1, 3.739997, -0.7399989))
    local fov = Config.CameraSettings.FOV or 70.0
    local transitionTime = Config.CameraSettings.TransitionTime or 1000

    destroyExistingCamera()
    hideLocalPed()

    activeCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamFov(activeCamera, fov)

    local cameraCoords = GetOffsetFromEntityInWorldCoords(atmEntity, camOffset.x, camOffset.y, camOffset.z)
    SetCamCoord(activeCamera, cameraCoords.x, cameraCoords.y, cameraCoords.z)
    PointCamAtEntity(activeCamera, atmEntity, camRot.x, camRot.y, camRot.z, true)
    SetCamActive(activeCamera, true)
    RenderScriptCams(true, true, transitionTime, true, true)

    return true
end

local function destroyAtmCamera()
    if activeCamera and DoesCamExist(activeCamera) then
        local transitionTime = Config.CameraSettings.TransitionTime or 500
        RenderScriptCams(false, true, transitionTime, true, true)
        DestroyCam(activeCamera, false)
        activeCamera = nil
    end

    restoreLocalPed()
end

local function isCameraActive()
    return activeCamera ~= nil and DoesCamExist(activeCamera)
end

CameraHandler = {
    createAtmCamera = createAtmCamera,
    destroyAtmCamera = destroyAtmCamera,
    isCameraActive = isCameraActive,
    hideLocalPed = hideLocalPed,
    restoreLocalPed = restoreLocalPed,
}
