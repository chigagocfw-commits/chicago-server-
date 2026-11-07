-- Radial menu bridge: registers mechanic:client:RepairVehicle and
-- mechanic:client:CleanVehicle events used by codem-supreme-radialmenu.
-- These provide quick-repair / quick-clean actions for mechanic job players
-- without having to open the full qs-mechanic-creator UI.

local function getClosestVehicle(maxDist)
    maxDist = maxDist or 5.0
    local ped = cache.ped
    local coords = GetEntityCoords(ped)
    local closest, closestDist

    local vehicles = GetGamePool('CVehicle')
    for i = 1, #vehicles do
        local veh = vehicles[i]
        local dist = #(coords - GetEntityCoords(veh))
        if dist < maxDist and (not closestDist or dist < closestDist) then
            closest, closestDist = veh, dist
        end
    end

    return closest
end

local function isMechanic()
    local job = exports.qbx_core:GetPlayerData().job
    return job and (job.name == 'mechanic' or job.name == 'tow')
end

RegisterNetEvent('mechanic:client:RepairVehicle', function()
    if not isMechanic() then return end

    local vehicle = getClosestVehicle(5.0)
    if not vehicle then
        exports.qbx_core:Notify('No vehicle nearby', 'error')
        return
    end

    local success = lib.progressBar({
        duration = 5000,
        label = 'Repairing vehicle...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    if not success then return end

    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)

    -- Fix all doors and windows
    for i = 0, 5 do
        SetVehicleDoorShut(vehicle, i, false)
    end
    for i = 0, 7 do
        FixVehicleWindow(vehicle, i)
    end

    exports.qbx_core:Notify('Vehicle repaired', 'success')
end)

RegisterNetEvent('mechanic:client:CleanVehicle', function()
    if not isMechanic() then return end

    local vehicle = getClosestVehicle(5.0)
    if not vehicle then
        exports.qbx_core:Notify('No vehicle nearby', 'error')
        return
    end

    local success = lib.progressBar({
        duration = 3000,
        label = 'Cleaning vehicle...',
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
    })

    if not success then return end

    SetVehicleDirtLevel(vehicle, 0.0)
    WashDecalsFromVehicle(vehicle, 1.0)
    exports.qbx_core:Notify('Vehicle cleaned', 'success')
end)

RegisterNetEvent('mechanic:client:OpenRadial', function()
    ExecuteCommand('mechanic_radial')
end)

RegisterCommand('mechanictablet', function()
    TriggerEvent('qs-mechanic-creator:client:openTablet')
end, false)
