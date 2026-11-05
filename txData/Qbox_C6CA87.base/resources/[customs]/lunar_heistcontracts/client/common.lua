function CreateSceneObject(model, coords)
    local object = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)
    
    if coords.w then
        SetEntityHeading(object, coords.w)
    end
    
    DisableCamCollisionForEntity(object)
    DisableCamCollisionForObject(object)
    SetEntityCompletelyDisableCollision(object, true, false)
    
    if SetEntityRemoteSyncedScenesAllowed then
        SetEntityRemoteSyncedScenesAllowed(object, true)
        SetEntityRemoteSyncedScenesAllowed(cache.ped, true)
    end
    
    return object
end

function PreloadDicts(...)
    local dicts = { ... }
    
    Framework.onPlayerLoaded(function()
        for _, dict in ipairs(dicts) do
            CreateThread(function()
                while not HasAnimDictLoaded(dict) do
                    RequestAnimDict(dict)
                    Wait(500)
                end
            end)
        end
    end)
end