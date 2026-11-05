local pedEntity = nil
local blipEntity = nil
local isApplying = false

-- Create map blip
local function createBlip()
    if not Config.Blip or not Config.Blip.enable then return end
    blipEntity = AddBlipForCoord(Config.Blip.coords.x, Config.Blip.coords.y, Config.Blip.coords.z)
    SetBlipSprite(blipEntity, Config.Blip.sprite)
    SetBlipDisplay(blipEntity, 4)
    SetBlipScale(blipEntity, Config.Blip.scale)
    SetBlipColour(blipEntity, Config.Blip.color)
    SetBlipAsShortRange(blipEntity, Config.Blip.shortRange)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Blip.label)
    EndTextCommandSetBlipName(blipEntity)
end

-- Open ox_lib context menu
local function openJobCenterMenu()
    local options = {}

    for i = 1, #Config.Jobs do
        local job = Config.Jobs[i]
        options[#options + 1] = {
            title = job.label,
            description = job.description,
            icon = job.icon,
            onSelect = function()
                if isApplying then return end
                isApplying = true
                
                lib.callback('chicago_jobcenter:server:applyJob', false, function(success, message)
                    isApplying = false
                    if success then
                        lib.notify({
                            title = 'Job Center',
                            description = message or 'You have been employed successfully!',
                            type = 'success',
                            position = 'top-right',
                        })
                    else
                        lib.notify({
                            title = 'Job Center',
                            description = message or 'Failed to change job.',
                            type = 'error',
                            position = 'top-right',
                        })
                    end
                end, job.name)
            end,
        }
    end

    lib.registerContext({
        id = 'chicago_jobcenter_menu',
        title = 'Job Center',
        options = options,
    })

    lib.showContext('chicago_jobcenter_menu')
end

-- Spawn stationary receptionist ped
local function spawnReceptionist()
    local modelHash = Config.PedModel
    lib.requestModel(modelHash)

    pedEntity = CreatePed(0, modelHash, Config.PedLocation.x, Config.PedLocation.y, Config.PedLocation.z - 1.0, Config.PedLocation.w, false, false)
    SetEntityAsMissionEntity(pedEntity, true, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)
    FreezeEntityPosition(pedEntity, true)
    SetEntityInvincible(pedEntity, true)
    TaskStartScenarioInPlace(pedEntity, 'WORLD_HUMAN_CLIPBOARD', 0, true)

    -- Register ox_target interaction
    exports.ox_target:addLocalEntity(pedEntity, {
        {
            name = 'chicago_jobcenter_receptionist',
            icon = 'fas fa-briefcase',
            label = 'Job Center',
            distance = 2.5,
            onSelect = function()
                openJobCenterMenu()
            end,
        }
    })
end

CreateThread(function()
    createBlip()
    spawnReceptionist()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if pedEntity and DoesEntityExist(pedEntity) then
        exports.ox_target:removeLocalEntity(pedEntity, 'chicago_jobcenter_receptionist')
        DeleteEntity(pedEntity)
    end
    if blipEntity and DoesBlipExist(blipEntity) then
        RemoveBlip(blipEntity)
    end
end)
