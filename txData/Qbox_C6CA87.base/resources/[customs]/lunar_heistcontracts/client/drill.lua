PreloadDicts("anim_heist@hs3f@ig9_vault_drill@drill@")

local function setScaleformParameter(scaleform, parameter, value)
    PushScaleformMovieFunction(scaleform, parameter)
    PushScaleformMovieFunctionParameterFloat(value)
    PopScaleformMovieFunctionVoid()
end

function StartDrilling(coords)
    local animDict = "anim_heist@hs3f@ig9_vault_drill@drill@"
    
    lib.requestModel(-944468481)
    lib.requestModel(-443429795)
    lib.requestNamedPtfxAsset("scr_gr_bunk")
    
    local bagObject = CreateSceneObject(-944468481, coords)
    local drillBitObject = CreateSceneObject(-443429795, coords)
    
    local sceneIntro = NetworkCreateSynchronisedScene(
        coords.x, coords.y, coords.z, 0.0, 0.0, coords.w,
        2, true, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, sceneIntro, animDict, "intro", -4.0, -4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneIntro, animDict, "bag_intro", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(drillBitObject, sceneIntro, animDict, "intro_drill_bit", 1.0, -1.0, 0)
    
    local sceneDrillStart = NetworkCreateSynchronisedScene(
        coords.x, coords.y, coords.z, 0.0, 0.0, coords.w,
        2, false, true, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, sceneDrillStart, animDict, "drill_straight_start", -4.0, 4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneDrillStart, animDict, "bag_drill_straight_start", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(drillBitObject, sceneDrillStart, animDict, "drill_straight_start_drill_bit", 1.0, -1.0, 0)
    
    local sceneExit = NetworkCreateSynchronisedScene(
        coords.x, coords.y, coords.z, 0.0, 0.0, coords.w,
        2, false, false, 1.0, 0.0, 1.0
    )
    NetworkAddPedToSynchronisedScene(cache.ped, sceneExit, animDict, "exit", -4.0, 4.0, 1037, 16, 1000.0, 0)
    NetworkAddEntityToSynchronisedScene(bagObject, sceneExit, animDict, "bag_exit", 1.0, -1.0, 0)
    NetworkAddEntityToSynchronisedScene(drillBitObject, sceneExit, animDict, "exit_drill_bit", 1.0, -1.0, 0)
    
    NetworkStartSynchronisedScene(sceneIntro)
    Wait((GetAnimDuration(animDict, "intro") * 1000) - 200)
    
    LR.notify(locale("drill_without_overheat"), "inform")
    LR.showUI(locale("drill_controls"), "gamepad")
    
    NetworkStartSynchronisedScene(sceneDrillStart)
    
    local soundId = GetSoundId()
    local scaleform = RequestScaleformMovie("DRILLING")
    
    while not HasScaleformMovieLoaded(scaleform) do Wait(0) end
    
    RequestScriptAudioBank("DLC_HEIST_FLEECA_SOUNDSET", false)
    RequestScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL", false)
    RequestScriptAudioBank("DLC_MPHEIST\\HEIST_FLEECA_DRILL_2", false)
    Wait(500)
    
    PlaySoundFromEntity(soundId, "Drill", drillBitObject, "DLC_HEIST_FLEECA_SOUNDSET", false, 0)
    
    setScaleformParameter(scaleform, "SET_SPEED", 1.0)
    setScaleformParameter(scaleform, "SET_DRILL_POSITION", 0.0)
    setScaleformParameter(scaleform, "SET_TEMPERATURE", 0.0)
    setScaleformParameter(scaleform, "SET_HOLE_DEPTH", 0.0)
    
    local drillPosition = 0.0
    local temperature = 1.0
    local lastDrillPosition = 0.0
    local lastTemperature = 0.1
    local particles = nil
    
    while true do
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
        
        if IsControlPressed(0, 188) then
            drillPosition = math.min(1.0, drillPosition + (0.1 * GetFrameTime()) / math.max(0.1, lastTemperature) * 10)
        elseif IsControlPressed(0, 187) then
            drillPosition = math.max(0.0, drillPosition - (0.1 * GetFrameTime()))
        end
        
        if lastDrillPosition < drillPosition then
            if temperature > 0.4 then
                temperature = math.min(1.0, temperature + (0.05 * GetFrameTime()) * temperature * 10)
                setScaleformParameter(scaleform, "SET_DRILL_POSITION", drillPosition)
            elseif drillPosition < 0.1 or lastDrillPosition > drillPosition then
                setScaleformParameter(scaleform, "SET_DRILL_POSITION", drillPosition)
            else
                drillPosition = lastDrillPosition
                temperature = math.min(1.0, temperature + (0.01 * GetFrameTime()))
            end
        else
            if lastDrillPosition >= drillPosition then
                temperature = math.max(0.0, temperature - (0.05 * GetFrameTime()) * math.max(0.005, (temperature * 10) / 2))
            end
            if drillPosition ~= lastDrillPosition then
                setScaleformParameter(scaleform, "SET_DRILL_POSITION", drillPosition)
            end
        end
        
        if lastTemperature ~= temperature then
            setScaleformParameter(scaleform, "SET_TEMPERATURE", temperature)
        end
        
        if lastDrillPosition < drillPosition and not particles then
            local particleNames = {
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark", "scr_gr_bunk_drill_spark",
                "scr_gr_bunk_drill_smoke"
            }
            particles = {}
            for i, name in ipairs(particleNames) do
                UseParticleFxAssetNextCall("scr_gr_bunk")
                particles[i] = StartParticleFxLoopedAtCoord(name, coords.x, coords.y, coords.z, 90.0, 0.0, coords.w, 2.25, false, false, false, false)
            end
        elseif lastDrillPosition >= drillPosition and particles then
            for _, particle in ipairs(particles) do
                StopParticleFxLooped(particle, false)
            end
            particles = nil
        end
        
        if temperature >= 1.0 then
            success = false
            LR.notify(locale("drill_overheated"), "error")
            break
        elseif drillPosition >= 0.775 then
            success = true
            LR.notify(locale("drilled_deposit_box"), "success")
            break
        end
        
        if Editable.isDead(cache.ped) then
            LR.hideUI()
            DeleteEntity(bagObject)
            DeleteEntity(drillBitObject)
            return false
        end
        
        lastDrillPosition = drillPosition or lastDrillPosition
        Wait(0)
    end
    
    if particles then
        for _, particle in ipairs(particles) do
            StopParticleFxLooped(particle, false)
        end
    end
    
    LR.hideUI()
    StopSound(soundId)
    NetworkStartSynchronisedScene(sceneExit)
    
    SetTimeout((GetAnimDuration(animDict, "exit") * 1000) - 200, function()
        DeleteEntity(bagObject)
        DeleteEntity(drillBitObject)
        SetModelAsNoLongerNeeded(-944468481)
        SetModelAsNoLongerNeeded(-443429795)
        RemoveNamedPtfxAsset("scr_gr_bunk")
    end)
    
    return success
end