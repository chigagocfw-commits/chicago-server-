



if IsDuplicityVersion() then return end

local playerZeroHash = joaat("PLAYER_ZERO")

function GetGroundCoord(coords)
    assert(
        type(coords) == "vector3",
        string.format("Failed to get ground coord. Expected vector3, got %s", type(coords))
    )

    -- Ensure the PLAYER_ZERO model is loaded
    if not HasModelLoaded(playerZeroHash) then
        RequestModel(playerZeroHash)
        while not HasModelLoaded(playerZeroHash) do
            Citizen.Wait(50)
        end
    end

    -- Spawn a temporary ped at the requested coordinates
    local tempPed = CreatePed(0, playerZeroHash, coords.x, coords.y, coords.z, 0.0, false, true)
    while not DoesEntityExist(tempPed) do
        Citizen.Wait(50)
    end

    -- Make the ped invisible and indestructible so it doesn't interact
    FreezeEntityPosition(tempPed, true)
    SetEntityInvincible(tempPed, true)
    SetEntityVisible(tempPed, false, false)
    SetEntityCanBeDamaged(tempPed, false)
    SetEntityCoordsNoOffset(tempPed, coords.x, coords.y, coords.z, false, false, true)

    -- Calculate ground Z: entity Z minus height above ground
    local groundZ = GetEntityCoords(tempPed).z - GetEntityHeightAboveGround(tempPed)

    -- Clean up the temporary ped and its model
    if DoesEntityExist(tempPed) then
        DeleteEntity(tempPed)
        SetEntityAsNoLongerNeeded(tempPed)
    end
    if HasModelLoaded(playerZeroHash) then
        SetModelAsNoLongerNeeded(playerZeroHash)
    end

    return groundZ
end