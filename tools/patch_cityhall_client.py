path = 'txData/Qbox_C6CA87.base/resources/[qbx]/qbx_cityhall/client/main.lua'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update openCityhallMenu
old_menu = """local function openCityhallMenu()
    local closestCityhall = getClosestHall()
    local options = {}

    options[#options + 1] = {
        title = locale('info.identity'),
        description = locale('info.obtain_license_identity'),
        onSelect = function()
            openIdentificationMenu(closestCityhall)
        end
    }

    local hallConfig = sharedConfig.cityhalls[closestCityhall]
    if sharedConfig.employment.enabled and (not hallConfig or hallConfig.enableEmployment ~= false) then
        options[#options + 1] = {
            title = locale('info.employment'),
            description = locale('info.select_job'),
            onSelect = openEmploymentMenu
        }
    end

    lib.registerContext({
        id = 'cityhall_menu',
        title = locale('info.cityhall'),
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
end"""

new_menu = """local function openCityhallMenu()
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
end"""

# 2. Update spawnPeds and deletePeds
old_spawn = """local function spawnPeds()
    if not config.peds or not next(config.peds) then
        pedsSpawned = false
        return
    end

    for i = 1, #config.peds do
        local current = config.peds[i]
        if current.pedHandle and DoesEntityExist(current.pedHandle) then
            pedsSpawned = true
        else
            current.model = type(current.model) == 'string' and joaat(current.model) or current.model
            lib.requestModel(current.model, 5000)
            RequestCollisionAtCoord(current.coords.x, current.coords.y, current.coords.z)
            local ground, groundZ = GetGroundZFor_3dCoord(current.coords.x, current.coords.y, current.coords.z, true)
            local z = (ground and groundZ > 0) and groundZ or current.coords.z
            local ped = CreatePed(0, current.model, current.coords.x, current.coords.y, z, current.coords.w, false, false)
            SetModelAsNoLongerNeeded(current.model)
            PlaceObjectOnGroundProperly(ped)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            TaskStartScenarioInPlace(ped, current.scenario, 0, true)
            current.pedHandle = ped
            current.targetAdded = false
            current.zoneAdded = false
            pedsSpawned = true

            if config.useTarget then
                if not current.targetAdded then
                    exports.ox_target:addLocalEntity(ped, {{
                        name = 'open_cityhall_' .. i,
                        icon = 'fa-solid fa-city',
                        label = locale('info.target_open_cityhall'),
                        distance = 1.5,
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
    end
end

local function deletePeds()
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
end"""

new_spawn = """local pedPoints = {}

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
            local ground, groundZ = GetGroundZFor_3dCoord(current.coords.x, current.coords.y, current.coords.z, true)
            local z = (ground and groundZ > 0) and groundZ or (current.coords.z - 1.0)

            local ped = CreatePed(0, model, current.coords.x, current.coords.y, z, current.coords.w, false, false)
            SetModelAsNoLongerNeeded(model)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)

            -- Snap to ground reliably using entity height above ground
            local height = GetEntityHeightAboveGround(ped)
            if height > 0.05 and height < 15.0 then
                local pCoords = GetEntityCoords(ped)
                SetEntityCoordsNoOffset(ped, pCoords.x, pCoords.y, pCoords.z - height, false, false, true)
            end

            FreezeEntityPosition(ped, true)
            TaskStartScenarioInPlace(ped, current.scenario, 0, true)
            current.pedHandle = ped

            if config.useTarget then
                if not current.targetAdded then
                    local targetLabel = locale('info.target_open_cityhall')
                    local hallConfig = sharedConfig.cityhalls[i]
                    if hallConfig and hallConfig.enableEmployment and (not hallConfig.licenses or not next(hallConfig.licenses)) then
                        targetLabel = 'مركز التوظيف | Job Center'
                    elseif hallConfig and hallConfig.licenses and not hallConfig.enableEmployment then
                        targetLabel = 'بطاقة التعريف ورخصة السياقة | Civil Status'
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
end"""

# Replace normalizing newlines
content_norm = content.replace('\r\n', '\n')
old_menu_norm = old_menu.replace('\r\n', '\n')
new_menu_norm = new_menu.replace('\r\n', '\n')
old_spawn_norm = old_spawn.replace('\r\n', '\n')
new_spawn_norm = new_spawn.replace('\r\n', '\n')

assert old_menu_norm in content_norm, "old_menu not found"
content_norm = content_norm.replace(old_menu_norm, new_menu_norm)

assert old_spawn_norm in content_norm, "old_spawn not found"
content_norm = content_norm.replace(old_spawn_norm, new_spawn_norm)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content_norm)

print("Successfully updated client/main.lua!")

