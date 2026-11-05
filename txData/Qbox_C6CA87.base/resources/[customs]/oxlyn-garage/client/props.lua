

Props = Props or {}

local function round(value, decimals)
    return Utils.Round(value, decimals)
end

---------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------

-- Wheel indexes to check for burst tyres, keyed by wheel count
local WHEEL_INDEXES = {
    ["2"] = { 0, 4 },
    ["3"] = { 0, 1, 4, 5 },
    ["4"] = { 0, 1, 4, 5 },
    ["6"] = { 0, 1, 2, 3, 4, 5 },
}

-- { propsKey, modSlot } for all simple (non-toggle) vehicle mods.
-- Wheels (23/24), livery (48) and toggles (18/20/22) are handled separately.
local MOD_SLOTS = {
    { "modSpoilers",      0 },
    { "modFrontBumper",   1 },
    { "modRearBumper",    2 },
    { "modSideSkirt",     3 },
    { "modExhaust",       4 },
    { "modFrame",         5 },
    { "modGrille",        6 },
    { "modHood",          7 },
    { "modFender",        8 },
    { "modRightFender",   9 },
    { "modRoof",          10 },
    { "modEngine",        11 },
    { "modBrakes",        12 },
    { "modTransmission",  13 },
    { "modHorns",         14 },
    { "modSuspension",    15 },
    { "modArmor",         16 },
    { "modPlateHolder",   25 },
    { "modVanityPlate",   26 },
    { "modTrimA",         27 },
    { "modOrnaments",     28 },
    { "modDashboard",     29 },
    { "modDial",          30 },
    { "modDoorSpeaker",   31 },
    { "modSeats",         32 },
    { "modSteeringWheel", 33 },
    { "modShifterLeavers", 34 },
    { "modAPlate",        35 },
    { "modSpeakers",      36 },
    { "modTrunk",         37 },
    { "modHydrolic",      38 },
    { "modEngineBlock",   39 },
    { "modAirFilter",     40 },
    { "modStruts",        41 },
    { "modArchCover",     42 },
    { "modAerials",       43 },
    { "modTrimB",         44 },
    { "modTank",          45 },
    { "modWindows",       46 },
}

local DEFORMATION_MIN_DAMAGE = 0.03
local DEFORMATION_MAX_DAMAGE = 2.0
local DEFORMATION_MAX_POINTS = 17

---------------------------------------------------------------------
-- Deformation capture / restore
---------------------------------------------------------------------

-- Samples the vehicle body on a grid and records dented points.
local function captureDeformation(vehicle, model)
    if not GetVehicleDeformationAtPos then
        return nil
    end

    local min, max = GetModelDimensions(model)
    local points = {}

    local function sample(x, y, z)
        local deformation = GetVehicleDeformationAtPos(vehicle, x, y, z)
        local magnitude = deformation and #deformation or 0.0

        if magnitude > DEFORMATION_MIN_DAMAGE then
            points[#points + 1] = {
                x = round(x, 3),
                y = round(y, 3),
                z = round(z, 3),
                damage = round(math.min(magnitude, DEFORMATION_MAX_DAMAGE), 3),
            }
        end
    end

    -- two height levels (35% and 70% of vehicle height), 3x3 grid minus the center
    for level = 1, 2 do
        local z = min.z + (max.z - min.z) * (level == 1 and 0.35 or 0.7)

        for gx = 0, 2 do
            for gy = 0, 2 do
                if gx ~= 1 or gy ~= 1 then
                    sample(
                        min.x + (max.x - min.x) * gx * 0.5,
                        min.y + (max.y - min.y) * gy * 0.5,
                        z
                    )
                end
            end
        end
    end

    -- center of the roof
    sample((min.x + max.x) * 0.5, (min.y + max.y) * 0.5, max.z)

    return points
end

-- Re-applies saved dents (up to 3 passes per point until damage matches).
local function applyDeformation(vehicle, points)
    if type(points) ~= "table" or not GetVehicleDeformationAtPos or not SetVehicleDamage then
        return
    end

    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    local margin = 0.1

    for i = 1, math.min(#points, DEFORMATION_MAX_POINTS) do
        local point = points[i]

        if type(point) == "table" then
            local x = tonumber(point.x)
            local y = tonumber(point.y)
            local z = tonumber(point.z)
            local damage = tonumber(point.damage)

            local valid = x and y and z and damage
                and damage == damage -- NaN check
                and damage > DEFORMATION_MIN_DAMAGE
                and x >= min.x - margin and x <= max.x + margin
                and y >= min.y - margin and y <= max.y + margin
                and z >= min.z - margin and z <= max.z + margin

            if valid then
                damage = math.min(damage, DEFORMATION_MAX_DAMAGE)

                for _ = 1, 3 do
                    local current = #GetVehicleDeformationAtPos(vehicle, x, y, z)
                    if current >= damage - 0.02 then
                        break
                    end

                    SetVehicleDamage(
                        vehicle, x, y, z,
                        math.min(150.0, (damage - current) * 200.0),
                        0.35,
                        true
                    )
                end
            end
        end
    end
end

---------------------------------------------------------------------
-- Props.Get
---------------------------------------------------------------------

function Props.Get(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then
        return nil
    end

    local color1, color2 = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)

    if GetIsVehiclePrimaryColourCustom(vehicle) then
        color1 = { GetVehicleCustomPrimaryColour(vehicle) }
    end
    if GetIsVehicleSecondaryColourCustom(vehicle) then
        color2 = { GetVehicleCustomSecondaryColour(vehicle) }
    end

    local hasCustomXenon, xr, xg, xb = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = hasCustomXenon and { xr, xg, xb } or nil

    -- extras
    local extras = {}
    for i = 0, 20 do
        if DoesExtraExist(vehicle, i) then
            extras[tostring(i)] = IsVehicleExtraTurnedOn(vehicle, i)
        end
    end

    -- tyres
    local tyreBurst = {}
    local wheelIndexes = WHEEL_INDEXES[tostring(GetVehicleNumberOfWheels(vehicle))]
    if wheelIndexes then
        for _, index in ipairs(wheelIndexes) do
            tyreBurst[tostring(index)] = IsVehicleTyreBurst(vehicle, index, false)
        end
    end

    -- windows (rolled up first so IsVehicleWindowIntact is accurate)
    local windowsBroken = {}
    for i = 0, 7 do
        RollUpWindow(vehicle, i)
        windowsBroken[tostring(i)] = not IsVehicleWindowIntact(vehicle, i)
    end

    -- doors
    local doorsBroken = {}
    local doorCount = GetNumberOfVehicleDoors(vehicle)
    if doorCount and doorCount > 0 then
        for i = 0, doorCount do
            doorsBroken[tostring(i)] = IsVehicleDoorDamaged(vehicle, i)
        end
    end

    local model = GetEntityModel(vehicle)
    local livery = GetVehicleMod(vehicle, 48)

    local props = {
        model = model,
        deformation = captureDeformation(vehicle, model),
        plate = Utils.Trim(GetVehicleNumberPlateText(vehicle) or ""),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),

        bodyHealth = round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = round(GetVehiclePetrolTankHealth(vehicle), 1),
        fuelLevel = round(Fuel.Get(vehicle), 1),
        dirtLevel = round(GetVehicleDirtLevel(vehicle), 1),

        color1 = color1,
        color2 = color2,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        dashboardColor = GetVehicleDashboardColor(vehicle),
        interiorColor = GetVehicleInteriorColour(vehicle),

        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),

        xenonColor = GetVehicleXenonLightsColor(vehicle),
        customXenonColor = customXenonColor,

        neonEnabled = {
            IsVehicleNeonLightEnabled(vehicle, 0),
            IsVehicleNeonLightEnabled(vehicle, 1),
            IsVehicleNeonLightEnabled(vehicle, 2),
            IsVehicleNeonLightEnabled(vehicle, 3),
        },
        neonColor = { GetVehicleNeonLightsColour(vehicle) },
        tyreSmokeColor = { GetVehicleTyreSmokeColor(vehicle) },

        extras = extras,
        tyresCanBurst = GetVehicleTyresCanBurst(vehicle),
        tyreBurst = tyreBurst,
        windowsBroken = windowsBroken,
        doorsBroken = doorsBroken,

        modRoofLivery = GetVehicleRoofLivery(vehicle),

        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),

        modFrontWheels = GetVehicleMod(vehicle, 23),
        modCustomFrontWheels = GetVehicleModVariation(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modCustomBackWheels = GetVehicleModVariation(vehicle, 24),

        -- fall back to the native livery if the mod-slot livery isn't set
        modLivery = (livery == -1 and GetVehicleLivery(vehicle)) or livery,
        modLightbar = GetVehicleMod(vehicle, 49),
    }

    for _, entry in ipairs(MOD_SLOTS) do
        props[entry[1]] = GetVehicleMod(vehicle, entry[2])
    end

    return props
end

---------------------------------------------------------------------
-- Props.Set helpers
---------------------------------------------------------------------

-- Extras may be saved with number/string keys in various spellings
-- ("1", 1, "01", "1.0"). Normalize them to integer ids, preferring the
-- canonical spelling when duplicates exist, then apply them in a
-- deterministic order: disable everything first, then enable.
local function applyExtras(vehicle, extras)
    local byId = {}
    local ids = {}

    for key, on in pairs(extras) do
        local id = (type(key) == "number" or type(key) == "string") and tonumber(key) or nil

        if type(on) == "boolean"
            and id and id == id
            and id % 1 == 0
            and id >= 0 and id <= 2147483647 then

            id = math.floor(id)
            local spelling = tostring(key)

            -- 3 = canonical string ("5"), 2 = number key, 1 = other string
            local rank
            if type(key) == "string" and tostring(id) == key then
                rank = 3
            elseif type(key) == "number" then
                rank = 2
            else
                rank = 1
            end

            local existing = byId[id]
            if not existing then
                ids[#ids + 1] = id
            end

            if not existing
                or rank > existing.rank
                or (rank == existing.rank and spelling < existing.spelling) then
                byId[id] = { on = on, rank = rank, spelling = spelling }
            end
        end
    end

    table.sort(ids)

    for _, id in ipairs(ids) do
        if not DoesExtraExist(vehicle, id) then
            byId[id] = nil
        end
    end

    -- SetVehicleExtra's last arg is "disable"
    for _, id in ipairs(ids) do
        if byId[id] and byId[id].on == false then
            SetVehicleExtra(vehicle, id, true)
        end
    end
    for _, id in ipairs(ids) do
        if byId[id] and byId[id].on == true then
            SetVehicleExtra(vehicle, id, false)
        end
    end
end

---------------------------------------------------------------------
-- Props.Set
---------------------------------------------------------------------

function Props.Set(vehicle, props)
    if not vehicle or not DoesEntityExist(vehicle) or type(props) ~= "table" then
        return
    end

    SetVehicleModKit(vehicle, 0)

    if props.tyresCanBurst ~= nil then
        SetVehicleTyresCanBurst(vehicle, props.tyresCanBurst)
    end
    if props.plate then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end
    if props.plateIndex then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end
    if props.fuelLevel then
        Fuel.Set(vehicle, props.fuelLevel)
    end

    -- primary / secondary paint (palette indexes)
    local hasColor1 = props.color1 ~= nil
    local hasColor2 = props.color2 ~= nil
    if hasColor1 or hasColor2 then
        local primary, secondary = props.color1, props.color2

        if not (hasColor1 and hasColor2) then
            local currentPrimary, currentSecondary = GetVehicleColours(vehicle)
            primary = (hasColor1 and primary) or currentPrimary
            secondary = (hasColor2 and secondary) or currentSecondary
        end

        -- NOTE: if color1/color2 is an {r,g,b} table (custom paint) this passes
        -- the table to SetVehicleColours, same as the original. See notes.
        SetVehicleColours(vehicle, primary, secondary)
    end

    -- custom RGB paint
    if type(props.color1) == "table" then
        SetVehicleCustomPrimaryColour(vehicle, props.color1[1], props.color1[2], props.color1[3])
    end
    if type(props.color2) == "table" then
        SetVehicleCustomSecondaryColour(vehicle, props.color2[1], props.color2[2], props.color2[3])
    end

    -- pearlescent / wheel color
    if props.pearlescentColor ~= nil or props.wheelColor ~= nil then
        local pearl, wheel = props.pearlescentColor, props.wheelColor

        if pearl == nil or wheel == nil then
            local currentPearl, currentWheel = GetVehicleExtraColours(vehicle)
            pearl = pearl or currentPearl
            wheel = wheel or currentWheel
        end

        SetVehicleExtraColours(vehicle, pearl, wheel)
    end

    if props.interiorColor ~= nil then
        SetVehicleInteriorColor(vehicle, props.interiorColor)
    end
    if props.dashboardColor ~= nil then
        SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end
    if props.wheels ~= nil then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    if props.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end

    -- neon
    if type(props.neonEnabled) == "table" then
        for i = 0, 3 do
            SetVehicleNeonLightEnabled(vehicle, i, props.neonEnabled[i + 1] == true)
        end
    end
    if type(props.neonColor) == "table" then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end

    -- xenon
    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end
    if type(props.customXenonColor) == "table" then
        SetVehicleXenonLightsCustomColor(
            vehicle,
            props.customXenonColor[1], props.customXenonColor[2], props.customXenonColor[3]
        )
    end

    -- tyre smoke
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, props.modSmokeEnabled == true)
    end
    if type(props.tyreSmokeColor) == "table" then
        SetVehicleTyreSmokeColor(
            vehicle,
            props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3]
        )
    end

    -- simple mods
    for _, entry in ipairs(MOD_SLOTS) do
        local value = props[entry[1]]
        if value ~= nil then
            SetVehicleMod(vehicle, entry[2], value, false)
        end
    end

    if props.modRoofLivery ~= nil then
        SetVehicleRoofLivery(vehicle, props.modRoofLivery)
    end
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomFrontWheels == true)
    end
    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomBackWheels == true)
    end
    if props.modLivery ~= nil then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end
    if props.modLightbar ~= nil then
        SetVehicleMod(vehicle, 49, props.modLightbar, false)
    end

    -- extras
    if type(props.extras) == "table" then
        applyExtras(vehicle, props.extras)
    end

    -- damage
    applyDeformation(vehicle, props.deformation)

    if type(props.windowsBroken) == "table" then
        for key, broken in pairs(props.windowsBroken) do
            local index = tonumber(key)
            if index and broken then
                SmashVehicleWindow(vehicle, index)
            end
        end
    end

    if type(props.doorsBroken) == "table" then
        for key, broken in pairs(props.doorsBroken) do
            local index = tonumber(key)
            if index and broken then
                SetVehicleDoorBroken(vehicle, index, true)
            end
        end
    end

    if type(props.tyreBurst) == "table" then
        for key, burst in pairs(props.tyreBurst) do
            local index = tonumber(key)
            if index and burst then
                SetVehicleTyreBurst(vehicle, index, true, 1000.0)
            end
        end
    end

    -- health / dirt (applied last)
    if props.bodyHealth then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end
    if props.engineHealth then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end
    if props.tankHealth then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end
    if props.dirtLevel then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end
end

---------------------------------------------------------------------
-- Display helpers
---------------------------------------------------------------------

-- Lowercase model name used for image lookups.
-- If a name string is given it wins; otherwise derived from the model hash.
function Props.ImageName(model, name)
    if type(name) == "string" and name ~= "" then
        return name:lower()
    end

    if not model or model == 0 then
        return nil
    end

    local displayName = GetDisplayNameFromVehicleModel(model)
    if not displayName or displayName == "" or displayName == "CARNOTFOUND" then
        return nil
    end

    return displayName:lower()
end

-- Human-readable vehicle name (uses game label, falls back to capitalized spawn name).
function Props.Label(model)
    if not model then
        return "Vehicle"
    end

    local displayName = GetDisplayNameFromVehicleModel(model)
    if not displayName or displayName == "" or displayName == "CARNOTFOUND" then
        return "Vehicle"
    end

    local label = GetLabelText(displayName)
    if not label or label == "NULL" then
        return (displayName:lower():gsub("^%l", string.upper))
    end

    return label
end

