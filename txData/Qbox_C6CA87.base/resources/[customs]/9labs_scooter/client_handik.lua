local SCOOTER_MODEL = `labscoot`
local IK_LEFT_HAND = 3
local IK_RIGHT_HAND = 4
local IK_BLEND_TIME = 150

local handIkEnabled = true
local handIkFlags = 4

local function isPlayerDrivingScooter(playerPed, vehicle)
    if vehicle == 0 or GetEntityModel(vehicle) ~= SCOOTER_MODEL then
        return false
    end
    return GetPedInVehicleSeat(vehicle, -1) == playerPed
end

CreateThread(function()
    local currentVehicle = 0
    local boneLeft = -1
    local boneRight = -1

    while true do
        local sleep = 250
        local playerPed = PlayerPedId()
        local vehicle = 0

        if handIkEnabled then
            vehicle = GetVehiclePedIsIn(playerPed, false)
        end

        if vehicle ~= currentVehicle then
            currentVehicle = 0
            boneLeft = -1
            boneRight = -1

            if isPlayerDrivingScooter(playerPed, vehicle) then
                currentVehicle = vehicle
                local gripBone = GetEntityBoneIndexByName(vehicle, "gripref_l")
                if gripBone ~= -1 then
                    boneLeft = 41479
                    boneRight = 41421
                else
                    boneLeft = 46652
                    boneRight = 46530
                end
            end
        end

        if currentVehicle ~= 0 then
            if GetIsTaskActive(playerPed, 2) or IsPedRagdoll(playerPed) then
                currentVehicle = 0
            else
                SetIkTarget(playerPed, IK_LEFT_HAND, currentVehicle, boneLeft, 0.0, 0.0, 0.0, handIkFlags, IK_BLEND_TIME, 150)
                SetIkTarget(playerPed, IK_RIGHT_HAND, currentVehicle, boneRight, 0.0, 0.0, 0.0, handIkFlags, IK_BLEND_TIME, 150)
                sleep = 0
            end
        end

        Wait(sleep)
    end
end)

exports("labscootHandIkState", function()
    return handIkEnabled, handIkFlags
end)

exports("setLabscootHandIk", function(enabled, flags)
    handIkEnabled = enabled ~= false
    if type(flags) == "number" then
        handIkFlags = flags
    end
    return handIkEnabled, handIkFlags
end)
