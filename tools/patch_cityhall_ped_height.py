path = 'txData/Qbox_C6CA87.base/resources/[qbx]/qbx_cityhall/client/main.lua'

with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update notification texts
old_notif = """                    if job == 'unemployed' then
                        lib.notify({
                            title = 'مركز التوظيف',
                            description = 'تم تقديم الاستقالة بنجاح، أنت الآن عاطل عن العمل',
                            type = 'inform',
                            duration = 6000
                        })
                    elseif sharedConfig.employment.jobLocations and sharedConfig.employment.jobLocations[job] then
                        local loc = sharedConfig.employment.jobLocations[job]
                        SetNewWaypoint(loc.coords.x, loc.coords.y)
                        lib.notify({
                            title = loc.label or label,
                            description = 'تم قبولك في العمل! تم تحديد موقع العمل على الخريطة (GPS)',
                            type = 'success',
                            duration = 8000
                        })
                    end"""

new_notif = """                    if job == 'unemployed' then
                        lib.notify({
                            title = 'Job Center',
                            description = 'You resigned and are now unemployed.',
                            type = 'inform',
                            duration = 6000
                        })
                    elseif sharedConfig.employment.jobLocations and sharedConfig.employment.jobLocations[job] then
                        local loc = sharedConfig.employment.jobLocations[job]
                        SetNewWaypoint(loc.coords.x, loc.coords.y)
                        lib.notify({
                            title = loc.label or label,
                            description = 'You were hired! Workplace waypoint set on GPS.',
                            type = 'success',
                            duration = 8000
                        })
                    end"""

# 2. Update ped spawn logic and target labels
old_ped_spawn = """            RequestCollisionAtCoord(current.coords.x, current.coords.y, current.coords.z)
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
                    end"""

new_ped_spawn = """            RequestCollisionAtCoord(current.coords.x, current.coords.y, current.coords.z)
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
                    end"""

text_norm = text.replace('\r\n', '\n')
old_notif_norm = old_notif.replace('\r\n', '\n')
new_notif_norm = new_notif.replace('\r\n', '\n')
old_ped_spawn_norm = old_ped_spawn.replace('\r\n', '\n')
new_ped_spawn_norm = new_ped_spawn.replace('\r\n', '\n')

assert old_notif_norm in text_norm, "old_notif not found"
text_norm = text_norm.replace(old_notif_norm, new_notif_norm)

assert old_ped_spawn_norm in text_norm, "old_ped_spawn not found"
text_norm = text_norm.replace(old_ped_spawn_norm, new_ped_spawn_norm)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text_norm)

print("Successfully updated client/main.lua (Fixed ped height & English only)")

