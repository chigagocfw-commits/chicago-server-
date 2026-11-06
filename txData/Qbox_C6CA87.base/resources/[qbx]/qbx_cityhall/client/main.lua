local config = require 'config.client'
local sharedConfig = require 'config.shared'
local inRangeCityhall = false
local pedsSpawned = false
local table_clone = table.clone
local blips = {}

local function getClosestHall()
    local playerCoords = GetEntityCoords(cache.ped)
    local distance = #(playerCoords - sharedConfig.cityhalls[1].coords)
    local closest = 1
    for i = 1, #sharedConfig.cityhalls do
        local hall = sharedConfig.cityhalls[i]
        local dist = #(playerCoords - hall.coords)
        if dist < distance then
            distance = dist
            closest = i
        end
    end
    return closest
end

local function pairsInOrder(object, _)
    local a = {}
    for n in pairs(object) do
        a[#a + 1] = n
    end
    table.sort(a, _)
    local i = 0
    local iterator = function()
        i = i + 1
        if a[i] == nil then
            return nil
        else
            return a[i], object[a[i]]
        end
    end
    return iterator
end

local function openIdentificationMenu(closestCityhall)
    local licensesMeta = QBX.PlayerData.metadata.licences
    local availableLicenses = table_clone(sharedConfig.cityhalls[closestCityhall].licenses)
    for license in pairs(availableLicenses) do
        if license and not licensesMeta[license] then
            availableLicenses[license] = nil
        end
    end
    local identityOptions = {}
    for item, id in pairsInOrder(availableLicenses) do
        identityOptions[#identityOptions + 1] = {
            title = id.label,
            description = locale('info.price', id.cost),
            onSelect = function()
                lib.callback.await('qbx_cityhall:server:requestId', false, item, closestCityhall)
                if not config.useTarget and inRangeCityhall then
                    lib.showTextUI(locale('info.open_cityhall'))
                end
            end
        }
    end
    lib.registerContext({
        id = 'cityhall_identity_menu',
        title = locale('info.identity'),
        menu = 'cityhall_menu',
        onExit = function()
            if not config.useTarget and inRangeCityhall then
                lib.showTextUI(locale('info.open_cityhall'))
            end
        end,
        options = identityOptions
    })
    lib.showContext('cityhall_identity_menu')
end

local function openEmploymentMenu()
    local jobOptions = {}
    
    -- Resign button prominently at the top
    jobOptions[#jobOptions + 1] = {
        title = '🛑 Quitter mon travail / Resign (Chômage)',
        description = 'Démissionner de votre travail actuel et devenir sans emploi',
        icon = 'ban',
        onSelect = function()
            local applied = lib.callback.await('qbx_cityhall:server:applyJob', false, 'unemployed')
            if not config.useTarget and inRangeCityhall then
                lib.showTextUI(locale('info.open_cityhall'))
            end
            if applied then
                lib.notify({
                    title = 'Job Center',
                    description = 'Vous avez quitté votre travail (Unemployed).',
                    type = 'inform',
                    duration = 6000
                })
            end
        end
    }

    for job, label in pairsInOrder(sharedConfig.employment.jobs) do
        if job ~= 'unemployed' then
            jobOptions[#jobOptions + 1] = {
                title = label,
                icon = 'briefcase',
                onSelect = function()
                    local applied = lib.callback.await('qbx_cityhall:server:applyJob', false, job)
                    if not config.useTarget and inRangeCityhall then
                        lib.showTextUI(locale('info.open_cityhall'))
                    end
                    if applied then
                        if sharedConfig.employment.jobLocations and sharedConfig.employment.jobLocations[job] then
                            local loc = sharedConfig.employment.jobLocations[job]
                            SetNewWaypoint(loc.coords.x, loc.coords.y)
                            lib.notify({
                                title = loc.label or label,
                                description = 'Félicitations! Point GPS vers votre lieu de travail activé.',
                                type = 'success',
                                duration = 8000
                            })
                        else
                            lib.notify({
                                title = label,
                                description = 'Vous avez pris le travail: ' .. label,
                                type = 'success',
                                duration = 6000
                            })
                        end
                    end
                end
            }
        end
    end
    lib.registerContext({
        id = 'cityhall_employment_menu',
        title = locale('info.employment'),
        menu = 'cityhall_menu',
        onExit = function()
            if not config.useTarget and inRangeCityhall then
                lib.showTextUI(locale('info.open_cityhall'))
            end
        end,
        options = jobOptions
    })
    lib.showContext('cityhall_employment_menu')
end

local function openCityhallMenu()
    local closestCityhall = getClosestHall()
    local hallConfig = sharedConfig.cityhalls[closestCityhall]
    local hasLicenses = hallConfig and hallConfig.licenses and next(hallConfig.licenses)
    local hasEmployment = sharedConfig.employment.enabled and (not hallConfig or hallConfig.enableEmployment ~= false)

    -- If cityhall only has jobs and no cards/licenses (like NPC 2), open employment menu directly
    if hasEmployment and not hasLicenses then
        openEmploymentMenu()
        return
    end

    -- If cityhall only has identity/cards and no jobs (like NPC 1), open identity menu directly
    if hasLicenses and not hasEmployment then
        openIdentificationMenu(closestCityhall)
        return
    end

    local options = {}

    if hasLicenses then
        options[#options + 1] = {
            title = locale('info.identity'),
            description = locale('info.obtain_license_identity'),
            onSelect = function()
                openIdentificationMenu(closestCityhall)
            end
        }
    end

    if hasEmployment then
        options[#options + 1] = {
            title = locale('info.employment'),
            description = locale('info.select_job'),
            onSelect = openEmploymentMenu
        }
    end

    lib.registerContext({
        id = 'cityhall_menu',
        title = hallConfig and hallConfig.blip and hallConfig.blip.label or locale('info.cityhall'),
        onExit = function()
            if not config.useTarget and inRangeCityhall then
                lib.showTextUI(locale('info.open_cityhall'))
            end
        end,
        options = options
    })
    lib.showContext('cityhall_menu')
    if not config.useTarget then return end
    inRangeCityhall = false
end

local function createBlip(cityhall)
    local blip = AddBlipForCoord(cityhall.coords.x, cityhall.coords.y, cityhall.coords.z)
    SetBlipSprite(blip, cityhall.blip.sprite or 1)
    SetBlipDisplay(blip, cityhall.blip.display or 4)
    SetBlipScale(blip, cityhall.blip.scale or 1.0)
    SetBlipColour(blip, cityhall.blip.colour or 1)
    SetBlipAsShortRange(blip, cityhall.blip.shortRange or false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(cityhall.blip.label or locale('info.cityhall'))
    EndTextCommandSetBlipName(blip)
    return blip
end

local function deleteBlips()
    if not blips then return end
    for i = 1, #blips do
        local blip = blips[i]
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    blips = {}
end

local function initBlips()
    if #blips > 0 then return end

    for i = 1, #sharedConfig.cityhalls do
        local cityhall = sharedConfig.cityhalls[i]

        if cityhall.showBlip and cityhall.blip then
            blips[#blips + 1] = createBlip({blip = cityhall.blip, coords = cityhall.coords})
        end
    end
end

local pedPoints = {}

local function deletePeds()
    for i = 1, #pedPoints do
        if pedPoints[i] then
            pedPoints[i]:remove()
        end
    end
    pedPoints = {}

    if not config.peds or not next(config.peds) then
        pedsSpawned = false
        return
    end

    for i = 1, #config.peds do
        local current = config.peds[i]
        if current.pedHandle then
            if current.targetAdded then
                exports.ox_target:removeLocalEntity(current.pedHandle)
            end
            if DoesEntityExist(current.pedHandle) then
                DeletePed(current.pedHandle)
            end
            current.pedHandle = nil
        end
        if current.zoneHandle then
            current.zoneHandle:remove()
            current.zoneHandle = nil
        end
        current.targetAdded = false
        current.zoneAdded = false
    end
    pedsSpawned = false
end

local function spawnPeds()
    if not config.peds or not next(config.peds) then
        pedsSpawned = false
        return
    end

    deletePeds()

    for i = 1, #config.peds do
        local current = config.peds[i]
        local pt = lib.points.new({
            coords = current.coords.xyz,
            distance = 60,
        })

        function pt:onEnter()
            if current.pedHandle and DoesEntityExist(current.pedHandle) then return end

            local model = type(current.model) == 'string' and joaat(current.model) or current.model
            lib.requestModel(model, 5000)

            RequestCollisionAtCoord(current.coords.x, current.coords.y, current.coords.z)
            local ground, groundZ = GetGroundZFor_3dCoord(current.coords.x, current.coords.y, current.coords.z + 1.5, true)
            local z = (ground and groundZ > 0) and groundZ or current.coords.z

            local ped = CreatePed(0, model, current.coords.x, current.coords.y, z, current.coords.w, false, false)
            SetModelAsNoLongerNeeded(model)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            FreezeEntityPosition(ped, true)
            TaskStartScenarioInPlace(ped, current.scenario, 0, true)
            current.pedHandle = ped

            if config.useTarget then
                if not current.targetAdded then
                    local targetLabel = locale('info.target_open_cityhall')
                    local hallConfig = sharedConfig.cityhalls[i]
                    if hallConfig and hallConfig.enableEmployment and (not hallConfig.licenses or not next(hallConfig.licenses)) then
                        targetLabel = 'Job Center'
                    elseif hallConfig and hallConfig.licenses and not hallConfig.enableEmployment then
                        targetLabel = 'City Services & ID'
                    end

                    exports.ox_target:addLocalEntity(ped, {{
                        name = 'open_cityhall_' .. i,
                        icon = i == 2 and 'fa-solid fa-briefcase' or 'fa-solid fa-id-card',
                        label = targetLabel,
                        distance = 2.0,
                        debug = false,
                        onSelect = function()
                            inRangeCityhall = true
                            openCityhallMenu()
                        end
                    }})
                    current.targetAdded = true
                end
            else
                local options = current.zoneOptions
                if options and not current.zoneAdded then
                    current.zoneHandle = lib.zones.box({
                        name = 'cityhall_' .. i,
                        coords = current.coords.xyz,
                        size = vec3(2, 2, 3),
                        rotation = current.coords.w,
                        debug = false,
                        onEnter = function()
                            inRangeCityhall = true
                            lib.showTextUI(locale('info.open_cityhall'))
                        end,
                        onExit = function()
                            lib.hideTextUI()
                            inRangeCityhall = false
                        end,
                        inside = function()
                            if IsControlJustPressed(0, 38) then
                                openCityhallMenu()
                                lib.hideTextUI()
                            end
                        end,
                    })
                    current.zoneAdded = true
                end
            end
        end

        function pt:onExit()
            if current.pedHandle and DoesEntityExist(current.pedHandle) then
                if current.targetAdded then
                    exports.ox_target:removeLocalEntity(current.pedHandle)
                    current.targetAdded = false
                end
                DeletePed(current.pedHandle)
                current.pedHandle = nil
            end
            if current.zoneHandle then
                current.zoneHandle:remove()
                current.zoneHandle = nil
                current.zoneAdded = false
            end
        end

        pedPoints[#pedPoints + 1] = pt
    end

    pedsSpawned = true
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    initBlips()
    spawnPeds()
end)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= cache.resource then return end
    initBlips()
    spawnPeds()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    deleteBlips()
    deletePeds()
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= cache.resource then return end
    deleteBlips()
    deletePeds()
end)