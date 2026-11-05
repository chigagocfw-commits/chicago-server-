

Utils = Utils or {}

---------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------

Utils.GARAGE_TYPES = { "car", "motorcycle", "boat", "air", "all" }
Utils.KINDS        = { "garage", "impound" }
Utils.ACCESS_MODES = { "public", "job", "gang", "private" }
Utils.STYLES       = { "showroom", "ledger", "grid", "minimal" }
Utils.WORLD_ICONS  = { "pin", "badge", "minimal", "none" }
Utils.PROMPTS      = { "card", "pill", "minimal" }
Utils.RADII        = { "sharp", "soft", "round" }

Utils.MAX_SPOTS  = 60
Utils.MAX_ID_LEN = 48

Utils.PRESETS = {
    midnight = { accent = "#4d7cff", surface = "#0e121a" },
    graphite = { accent = "#f2f3f5", surface = "#141518" },
    onyx     = { accent = "#d7d9de", surface = "#0b0b0d" },
    slate    = { accent = "#aebdd0", surface = "#171b21" },
    steel    = { accent = "#6fa8ff", surface = "#121620" },
    mint     = { accent = "#3ddc97", surface = "#111816" },
    amber    = { accent = "#f5b544", surface = "#171410" },
    crimson  = { accent = "#f0505f", surface = "#181113" },
    violet   = { accent = "#8f7bff", surface = "#141224" },
}

Utils.ZONE_MAX_POINTS = 64
Utils.ZONE_BELOW      = 3.0
Utils.ZONE_ABOVE      = 6.0

---------------------------------------------------------------------
-- Lookup sets (built from the lists above)
---------------------------------------------------------------------

local function toSet(list)
    local set = {}
    for _, value in ipairs(list) do
        set[value] = true
    end
    return set
end

local GARAGE_TYPE_SET = toSet(Utils.GARAGE_TYPES)
local KIND_SET        = toSet(Utils.KINDS)
local ACCESS_SET      = toSet(Utils.ACCESS_MODES)
local STYLE_SET       = toSet(Utils.STYLES)
local WORLD_ICON_SET  = toSet(Utils.WORLD_ICONS)
local PROMPT_SET      = toSet(Utils.PROMPTS)
local RADIUS_SET      = toSet(Utils.RADII)

local INTERACTION_MODES = { prompt = true, target = true, both = true }

-- nil -> fall back to default (treated as true unless default is explicitly false)
-- otherwise only an explicit `true` counts as true
local function toBool(value, default)
    if value == nil then
        return default ~= false
    end
    return value == true
end

---------------------------------------------------------------------
-- Basic helpers
---------------------------------------------------------------------

function Utils.IsHex(value)
    return type(value) == "string"
        and (value:match("^#%x%x%x%x%x%x$") ~= nil or value:match("^#%x%x%x$") ~= nil)
end

function Utils.Round(value, decimals)
    value = tonumber(value) or 0
    local mult = 10 ^ (decimals or 0)
    return math.floor(value * mult + 0.5) / mult
end

function Utils.Clamp(value, min, max)
    value = tonumber(value) or min
    if min > value then return min end
    if max < value then return max end
    return value
end

function Utils.Trim(str)
    if type(str) ~= "string" then
        return ""
    end
    return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

function Utils.PlateKey(plate)
    if type(plate) ~= "string" then
        return ""
    end
    return (plate:upper():gsub("%s+", ""))
end

function Utils.Slug(value)
    value = tostring(value or ""):lower()
    value = value:gsub("[^%w_]+", "_"):gsub("^_+", ""):gsub("_+$", "")
    if #value > Utils.MAX_ID_LEN then
        value = value:sub(1, Utils.MAX_ID_LEN)
    end
    return value
end

function Utils.Money(amount)
    amount = math.floor(tonumber(amount) or 0)

    local currency = (Config and Config.Currency) or {}
    local separator = currency.thousands or ","

    local digits = tostring(math.abs(amount))
    local formatted = digits:reverse():gsub("(%d%d%d)", "%1" .. separator):reverse()

    if formatted:sub(1, 1) == separator then
        formatted = formatted:sub(2)
    end
    if amount < 0 then
        formatted = "-" .. formatted
    end

    local symbol = currency.symbol or "$"
    if currency.position == "after" then
        return formatted .. " " .. symbol
    end
    return symbol .. formatted
end

function Utils.Copy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for k, v in pairs(value) do
        copy[k] = Utils.Copy(v)
    end
    return copy
end

function Utils.Arr(value)
    if type(value) ~= "table" then
        return {}
    end
    if #value > 0 then
        local copy = {}
        for i, v in ipairs(value) do
            copy[i] = v
        end
        return copy
    end
    return value
end

function Utils.Count(value)
    local count = 0
    if type(value) == "table" then
        for _ in pairs(value) do
            count = count + 1
        end
    end
    return count
end

---------------------------------------------------------------------
-- Settings sanitisers
---------------------------------------------------------------------

function Utils.SanitiseParkSettings(input)
    if type(input) ~= "table" then
        input = {}
    end
    local defaults = (Config and Config.Park) or {}

    -- collision is only true when explicitly true (default included)
    local collision = input.collision
    if collision == nil then
        collision = defaults.collision
    end

    local maxFee = (Config and Config.Impound and Config.Impound.maxFee) or 25000

    return {
        enabled   = toBool(input.enabled, defaults.enabled),
        collision = collision == true,
        blip      = toBool(input.blip, defaults.blip),
        maxPerPlayer = Utils.Clamp(
            math.floor(tonumber(input.maxPerPlayer) or tonumber(defaults.maxPerPlayer) or 0),
            0, 50),
        radius = Utils.Clamp(
            tonumber(input.radius) or tonumber(defaults.radius) or 8.0,
            3.0, 30.0),
        -- rounded to the nearest quarter hour
        maxHours = Utils.Clamp(
            math.floor((tonumber(input.maxHours) or tonumber(defaults.maxHours) or 0) * 4 + 0.5) / 4,
            0, 168),
        towFee = Utils.Clamp(
            math.floor(tonumber(input.towFee) or tonumber(defaults.towFee) or 300),
            0, maxFee),
    }
end

function Utils.SanitiseInteraction(input)
    if type(input) ~= "table" then
        input = {}
    end

    local configMode = Config and Config.Interaction and Config.Interaction.mode or "prompt"
    local defaultMode = tostring(configMode):lower()
    if not INTERACTION_MODES[defaultMode] then
        defaultMode = "prompt"
    end

    local mode = tostring(input.mode or defaultMode):lower()
    if not INTERACTION_MODES[mode] then
        mode = defaultMode
    end

    return { mode = mode }
end

function Utils.SanitiseSettings(input)
    if type(input) ~= "table" then
        input = {}
    end

    local ui = (Config and Config.UI) or {}
    local configTheme = type(ui.theme) == "table" and ui.theme or {}
    local inputTheme  = type(input.theme) == "table" and input.theme or {}

    local preset = tostring(inputTheme.preset or configTheme.preset or "midnight"):lower()

    local accent = Utils.IsHex(inputTheme.accent) and inputTheme.accent:lower() or nil
    local surface = Utils.IsHex(inputTheme.surface) and inputTheme.surface:lower() or nil

    if preset ~= "custom" then
        local presetColors = Utils.PRESETS[preset]
        if presetColors then
            accent = accent or presetColors.accent
            surface = surface or presetColors.surface
        else
            preset = "custom"
        end
    end

    if not accent then
        if Utils.IsHex(configTheme.accent) then
            accent = configTheme.accent:lower()
        else
            accent = "#f2f3f5"
        end
    end

    if not surface then
        if Utils.IsHex(configTheme.surface) then
            surface = configTheme.surface:lower()
        else
            surface = "#141518"
        end
    end

    local radius = tostring(inputTheme.radius or configTheme.radius or "soft"):lower()
    if not RADIUS_SET[radius] then
        radius = "soft"
    end

    local style = tostring(input.style or ui.style or "showroom"):lower()
    if not STYLE_SET[style] then
        style = "showroom"
    end

    local worldIcon = tostring(input.worldIcon or ui.worldIcon or "pin"):lower()
    if not WORLD_ICON_SET[worldIcon] then
        worldIcon = "pin"
    end

    local prompt = tostring(input.prompt or ui.prompt or "card"):lower()
    if not PROMPT_SET[prompt] then
        prompt = "card"
    end

    local updatedBy = nil
    if input.updatedBy then
        updatedBy = tostring(input.updatedBy):sub(1, 64)
    end

    return {
        theme = {
            preset  = preset,
            accent  = accent,
            surface = surface,
            radius  = radius,
        },
        style       = style,
        worldIcon   = worldIcon,
        prompt      = prompt,
        showImages  = toBool(input.showImages, ui.showImages),
        transitions = toBool(input.transitions, ui.transitions),
        park        = Utils.SanitiseParkSettings(input.park),
        interaction = Utils.SanitiseInteraction(input.interaction),
        updatedAt   = tonumber(input.updatedAt) or nil,
        updatedBy   = updatedBy,
    }
end

function Utils.SanitiseGarageTheme(input)
    if type(input) ~= "table" then
        input = {}
    end

    local theme = {}

    if Utils.IsHex(input.accent) then
        theme.accent = input.accent:lower()
    end

    if type(input.style) == "string" and STYLE_SET[input.style:lower()] then
        theme.style = input.style:lower()
    end

    return theme
end

---------------------------------------------------------------------
-- Collection parsing
---------------------------------------------------------------------

-- Accepts a map ({ police = 2 }), a list of names, a list of { name, grade },
-- or a delimited string ("police:2, ambulance"). Returns { [name] = minGrade }.
function Utils.JobMap(input)
    local jobs = {}

    if type(input) == "table" then
        for key, value in pairs(input) do
            if type(key) == "string" then
                jobs[key:lower()] = math.max(0, math.floor(tonumber(value) or 0))
            elseif type(value) == "string" then
                jobs[value:lower()] = 0
            elseif type(value) == "table" and value.name then
                jobs[tostring(value.name):lower()] = math.max(0, math.floor(tonumber(value.grade) or 0))
            end
        end
    elseif type(input) == "string" then
        for entry in input:gmatch("[^\r\n,;]+") do
            local name, grade = entry:match("^%s*([%w_%-]+)%s*[:=]?%s*(%d*)%s*$")
            if name and name ~= "" then
                jobs[name:lower()] = tonumber(grade) or 0
            end
        end
    end

    return jobs
end

-- Returns a de-duplicated, trimmed list of strings.
function Utils.StringList(input)
    local list = {}
    local seen = {}

    local function add(value)
        value = Utils.Trim(tostring(value or ""))
        if value ~= "" and not seen[value] then
            seen[value] = true
            list[#list + 1] = value
        end
    end

    if type(input) == "table" then
        for key, value in pairs(input) do
            if type(key) == "string" and value then
                add(key)
            else
                add(value)
            end
        end
    elseif type(input) == "string" then
        for entry in input:gmatch("[^\r\n,;]+") do
            add(entry)
        end
    end

    return list
end

---------------------------------------------------------------------
-- Coordinates & distance
---------------------------------------------------------------------

function Utils.Coords(input, withHeading)
    if type(input) ~= "table" then
        return nil
    end

    local x = tonumber(input.x or input[1])
    local y = tonumber(input.y or input[2])
    local z = tonumber(input.z or input[3])
    if not (x and y and z) then
        return nil
    end

    local coords = {
        x = Utils.Round(x, 3),
        y = Utils.Round(y, 3),
        z = Utils.Round(z, 3),
    }

    if withHeading ~= false then
        local heading = tonumber(input.w or input.heading or input[4]) or 0.0
        coords.w = Utils.Round(heading % 360, 1)
    end

    return coords
end

-- 3D distance
function Utils.Dist(a, b)
    if not a or not b then
        return math.huge
    end
    local dx = a.x - b.x
    local dy = a.y - b.y
    local dz = (a.z or 0) - (b.z or 0)
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

-- 2D distance (ignores Z)
function Utils.Dist2(a, b)
    if not a or not b then
        return math.huge
    end
    local dx = a.x - b.x
    local dy = a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

---------------------------------------------------------------------
-- Vehicle categories
---------------------------------------------------------------------

local VEHICLE_TYPE_TO_CATEGORY = {
    automobile           = "car",
    quadbike             = "car",
    amphibious_automobile = "car",
    amphibious_quadbike  = "car",
    trailer              = "car",
    train                = "car",
    bike                 = "motorcycle",
    bicycle              = "motorcycle",
    boat                 = "boat",
    submarine            = "boat",
    heli                 = "air",
    plane                = "air",
    blimp                = "air",
}

function Utils.CategoryFromType(vehicleType)
    return VEHICLE_TYPE_TO_CATEGORY[tostring(vehicleType or ""):lower()] or "car"
end

-- GTA vehicle class IDs
function Utils.CategoryFromClass(class)
    class = tonumber(class) or 0
    if class == 8 or class == 13 then return "motorcycle" end
    if class == 14 then return "boat" end
    if class == 15 or class == 16 then return "air" end
    return "car"
end

function Utils.GarageAccepts(garageType, vehicleCategory)
    if garageType == "all" then
        return true
    end
    if garageType == "car" then
        return vehicleCategory == "car" or vehicleCategory == "motorcycle"
    end
    return garageType == vehicleCategory
end

function Utils.GarageAcceptsVehicle(garage, vehicleCategory)
    if not garage then
        return false
    end
    return Utils.GarageAccepts(garage.type, vehicleCategory)
end

---------------------------------------------------------------------
-- Fleet / vehicle data
---------------------------------------------------------------------

-- Valid extras: an array of unique integers 0..20. Returns a sorted list, or nil if invalid.
function Utils.SanitiseFleetExtras(input)
    if type(input) ~= "table" then
        return nil
    end

    local extras = {}
    local seen = {}
    local entryCount = 0
    local length = #input

    for key, value in pairs(input) do
        local validKey = type(key) == "number" and key % 1 == 0 and key >= 1 and key <= length
        local validValue = type(value) == "number" and value == value and value % 1 == 0
            and value >= 0 and value <= 20

        if not (validKey and validValue) then
            return nil
        end

        entryCount = entryCount + 1
        if not seen[value] then
            seen[value] = true
            extras[#extras + 1] = value
        end
    end

    if entryCount ~= length then
        return nil
    end

    table.sort(extras)
    return extras
end

-- Normalises engine/body health (0-1000) and fuel to percentages.
function Utils.Condition(input)
    if type(input) ~= "table" then
        input = {}
    end

    local engineHealth = tonumber(input.engineHealth) or 1000
    local bodyHealth   = tonumber(input.bodyHealth) or 1000
    local fuelLevel    = tonumber(input.fuelLevel) or 100

    return {
        engine = Utils.Clamp(Utils.Round(engineHealth / 10, 0), 0, 100),
        body   = Utils.Clamp(Utils.Round(bodyHealth / 10, 0), 0, 100),
        fuel   = Utils.Clamp(Utils.Round(fuelLevel, 0), 0, 100),
    }
end

---------------------------------------------------------------------
-- Zone geometry
---------------------------------------------------------------------

-- Returns polygon area (shoelace formula) and perimeter.
function Utils.ZoneStats(points)
    local count = #points
    if count < 2 then
        return 0, 0
    end

    local area2 = 0
    local perimeter = 0

    for i = 1, count do
        local a = points[i]
        local b = points[i % count + 1]

        area2 = area2 + (a.x * b.y - b.x * a.y)

        -- with only two points the closing edge would double count
        if count > 2 or i < count then
            perimeter = perimeter + math.sqrt((b.x - a.x) ^ 2 + (b.y - a.y) ^ 2)
        end
    end

    return math.abs(area2) / 2, perimeter
end

local function cross(a, b, c)
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
end

-- NOTE: the decompiled source computed four cross products but only compared the
-- first two (c3/c4 were unused), so this only checks that p3 and p4 sit on
-- opposite sides... of nothing meaningful. A proper segment test also requires
-- (c3 > 0) ~= (c4 > 0). Behaviour is preserved here as-is.
local function segmentsIntersect(p1, p2, p3, p4)
    local c1 = cross(p1, p2, p3)
    local c2 = cross(p1, p2, p4)
    return (c1 > 0) ~= (c2 > 0)
end

function Utils.ZoneSelfIntersects(points)
    local count = #points
    if count < 4 then
        return false
    end

    for i = 1, count do
        local a = points[i]
        local b = points[i % count + 1]

        for j = i + 2, count do
            -- skip the pair of edges that are adjacent via wraparound
            if not (i == 1 and j == count) then
                if segmentsIntersect(a, b, points[j], points[j % count + 1]) then
                    return true
                end
            end
        end
    end

    return false
end

function Utils.SanitiseZone(raw, center)
    if type(raw) ~= "table" then
        return nil
    end

    local source = type(raw.points) == "table" and raw.points or raw
    local points = {}

    for _, p in ipairs(source) do
        if type(p) == "table" then
            local x = tonumber(p.x or p[1])
            local y = tonumber(p.y or p[2])
            local z = tonumber(p.z or p[3])

            -- reject nil / NaN / out-of-range values
            if x and y and z and x == x and y == y and z == z
                and math.abs(x) < 100000.0
                and math.abs(y) < 100000.0
                and math.abs(z) < 10000.0 then
                points[#points + 1] = {
                    x = Utils.Round(x, 2),
                    y = Utils.Round(y, 2),
                    z = Utils.Round(z, 2),
                }
            end
        end

        if #points >= Utils.ZONE_MAX_POINTS then
            break
        end
    end

    if #points < 3 then
        return nil
    end

    local area, perimeter = Utils.ZoneStats(points)
    if area < 4.0 then
        return nil
    end

    local minZ, maxZ = math.huge, -math.huge
    local reach = 0

    for _, p in ipairs(points) do
        if p.z < minZ then minZ = p.z end
        if p.z > maxZ then maxZ = p.z end

        -- furthest vertex from the interaction point
        if center then
            local d = math.sqrt((p.x - center.x) ^ 2 + (p.y - center.y) ^ 2)
            if d > reach then
                reach = d
            end
        end
    end

    return {
        points    = points,
        minZ      = minZ,
        maxZ      = maxZ,
        area      = Utils.Round(area, 1),
        perimeter = Utils.Round(perimeter, 1),
        reach     = Utils.Round(reach, 1),
    }
end

-- Ray-casting point-in-polygon test (2D).
function Utils.InPolygon(points, x, y)
    local inside = false
    local j = #points

    for i = 1, #points do
        local a = points[i]
        local b = points[j]

        if (y < a.y) ~= (y < b.y) then
            local intersectX = (b.x - a.x) * (y - a.y) / (b.y - a.y) + a.x
            if x < intersectX then
                inside = not inside
            end
        end

        j = i
    end

    return inside
end

-- Distance from a position to the zone: 0 if inside, math.huge if outside the Z band.
function Utils.ZoneDistance(zone, pos)
    if pos.z < zone.minZ - Utils.ZONE_BELOW or pos.z > zone.maxZ + Utils.ZONE_ABOVE then
        return math.huge
    end

    local points = zone.points
    if Utils.InPolygon(points, pos.x, pos.y) then
        return 0
    end

    local best = math.huge
    local count = #points

    for i = 1, count do
        local a = points[i]
        local b = points[i % count + 1]

        local dx = b.x - a.x
        local dy = b.y - a.y
        local lengthSq = dx * dx + dy * dy

        -- projection of pos onto segment a-b, clamped to the segment
        local t = 0
        if lengthSq > 0 then
            t = Utils.Clamp(((pos.x - a.x) * dx + (pos.y - a.y) * dy) / lengthSq, 0, 1)
        end

        local d = math.sqrt((pos.x - (a.x + t * dx)) ^ 2 + (pos.y - (a.y + t * dy)) ^ 2)
        if d < best then
            best = d
        end
    end

    return best
end

function Utils.InParkingArea(garage, pos, margin)
    margin = margin or 0

    if garage.zone then
        return margin >= Utils.ZoneDistance(garage.zone, pos)
    end

    local radius = (garage.storeRadius or 14.0) + margin

    if radius >= Utils.Dist(pos, garage.point) then
        return true
    end

    for _, spot in ipairs(garage.spots or {}) do
        if radius >= Utils.Dist(pos, spot) then
            return true
        end
    end

    return false
end

---------------------------------------------------------------------
-- Garage sanitiser
---------------------------------------------------------------------

-- Returns the sanitised garage table, or nil plus an error message.
function Utils.SanitiseGarage(raw)
    if type(raw) ~= "table" then
        return nil, "not a table"
    end

    local id = Utils.Slug(raw.id)
    if id == "" then
        return nil, "missing id"
    end

    local label = Utils.Trim(tostring(raw.label or ""))
    if label == "" then
        label = id
    end
    if #label > 64 then
        label = label:sub(1, 64)
    end

    local kind = tostring(raw.kind or "garage"):lower()
    if not KIND_SET[kind] then
        return nil, 'unknown kind "' .. kind .. '"'
    end

    local garageType = tostring(raw.type or "car"):lower()
    if not GARAGE_TYPE_SET[garageType] then
        return nil, 'unknown type "' .. garageType .. '"'
    end
    if kind == "impound" then
        garageType = "all"
    end

    local point = Utils.Coords(raw.point)
    if not point then
        return nil, "missing interaction point"
    end

    local garageConfig = (Config and Config.Garage) or {}

    local radius = Utils.Clamp(
        Utils.Round(raw.radius or garageConfig.defaultRadius or 2.5, 2),
        1.0, 15.0)

    local storeRadius = Utils.Clamp(
        Utils.Round(raw.storeRadius or garageConfig.defaultStoreRadius or 14.0, 2),
        3.0, 150.0)

    -- Parking spots
    local spots = {}
    if type(raw.spots) == "table" then
        for _, spot in ipairs(raw.spots) do
            local coords = Utils.Coords(spot)
            if coords then
                spots[#spots + 1] = coords
            end
            if #spots >= Utils.MAX_SPOTS then
                break
            end
        end
    end
    if #spots == 0 then
        spots[1] = { x = point.x, y = point.y, z = point.z, w = point.w }
    end

    -- Blip
    local rawBlip = type(raw.blip) == "table" and raw.blip or {}
    local blipConfig = (Config and Config.Blips) or {}
    local blipDefaults =
        (kind == "impound" and blipConfig.impound)
        or (garageType == "boat" and blipConfig.boat)
        or (garageType == "air" and blipConfig.air)
        or blipConfig.garage
        or {}

    local blip = {
        enabled = rawBlip.enabled ~= false,
        sprite = math.floor(Utils.Clamp(rawBlip.sprite or blipDefaults.sprite or 357, 1, 999)),
        color  = math.floor(Utils.Clamp(rawBlip.color or blipDefaults.color or 3, 0, 85)),
        scale  = Utils.Clamp(
            Utils.Round(rawBlip.scale or blipDefaults.scale or 0.75, 2),
            0.3, 2.0),
        label  = Utils.Trim(tostring(rawBlip.label or "")),
    }
    if #blip.label > 48 then
        blip.label = blip.label:sub(1, 48)
    end

    -- Ped
    local rawPed = type(raw.ped) == "table" and raw.ped or {}
    local pedConfig = (Config and Config.Peds) or {}
    local defaultPedModel = pedConfig.defaultModel or "s_m_y_valet_01"

    local ped = {
        enabled  = rawPed.enabled == true,
        model    = Utils.Trim(tostring(rawPed.model or defaultPedModel)),
        scenario = Utils.Trim(tostring(rawPed.scenario or pedConfig.defaultScenario or "WORLD_HUMAN_CLIPBOARD")),
    }
    if ped.model == "" then
        ped.model = defaultPedModel
    end

    -- Marker
    local rawMarker = type(raw.marker) == "table" and raw.marker or {}
    local marker = { enabled = rawMarker.enabled ~= false }

    -- Access
    local rawAccess = type(raw.access) == "table" and raw.access or {}
    local accessMode = tostring(rawAccess.mode or "public"):lower()
    if not ACCESS_SET[accessMode] then
        accessMode = "public"
    end

    local access = {
        mode        = accessMode,
        jobs        = Utils.JobMap(rawAccess.jobs),
        gangs       = Utils.StringList(rawAccess.gangs),
        identifiers = Utils.StringList(rawAccess.identifiers),
    }
    for i, gang in ipairs(access.gangs) do
        access.gangs[i] = gang:lower()
    end

    -- Impound settings
    local rawImpound = type(raw.impound) == "table" and raw.impound or {}
    local defaultFee = (Config and Config.Impound and Config.Impound.defaultFee) or 300

    local impound = {
        fee = math.floor(Utils.Clamp(rawImpound.fee or defaultFee, 0, 10000000)),
        presentation = rawImpound.presentation == "cinematic" and "cinematic" or "document",
    }

    -- Fleet (job vehicles; only for regular garages)
    local fleet = {}
    if kind == "garage" and type(raw.fleet) == "table" then
        for _, entry in ipairs(raw.fleet) do
            if type(entry) == "table" then
                local model = Utils.Trim(tostring(entry.model or ""))
                model = model:lower():gsub("[^%w_]", "")
                model = model:sub(1, 32)

                if model ~= "" then
                    local entryLabel = Utils.Trim(tostring(entry.label or ""))
                    entryLabel = entryLabel:gsub("[%c<>]", "")

                    local subcategory = ""
                    if type(entry.subcategory) == "string" then
                        subcategory = Utils.Trim((entry.subcategory:gsub("[%c<>]", "")))
                    end

                    -- limit to 48 UTF-8 characters, and drop it if it isn't valid UTF-8
                    local ok, length = pcall(utf8.len, subcategory)
                    if not ok or not length then
                        subcategory = ""
                    elseif length > 48 then
                        subcategory = subcategory:sub(1, utf8.offset(subcategory, 49) - 1)
                    end

                    fleet[#fleet + 1] = {
                        model       = model,
                        label       = entryLabel ~= "" and entryLabel:sub(1, 32) or nil,
                        subcategory = subcategory ~= "" and subcategory or nil,
                        minGrade    = math.floor(Utils.Clamp(tonumber(entry.minGrade) or 0, 0, 50)),
                        count       = math.floor(Utils.Clamp(tonumber(entry.count) or 0, 0, 99)),
                        livery      = math.floor(Utils.Clamp(tonumber(entry.livery) or -1, -1, 60)),
                        extras      = Utils.SanitiseFleetExtras(entry.extras),
                        tuned       = entry.tuned == true,
                    }

                    if #fleet >= 30 then
                        break
                    end
                end
            end
        end
    end

    local fleetPlate = Utils.Trim(tostring(raw.fleetPlate or "")):upper():gsub("[^%w]", "")
    fleetPlate = fleetPlate:sub(1, 4)
    if fleetPlate == "" then
        fleetPlate = nil
    end

    local fleetPerPlayer = tonumber(raw.fleetPerPlayer)
    if kind ~= "garage" or not fleetPerPlayer then
        fleetPerPlayer = nil
    else
        fleetPerPlayer = math.floor(Utils.Clamp(fleetPerPlayer, 0, 30))
    end

    local fleetRecall = nil
    if kind == "garage" and raw.fleetRecall ~= nil then
        fleetRecall = raw.fleetRecall ~= false
    end

    -- Personal (owned-vehicle) storage: always on for impounds; for garages it
    -- defaults to on unless access is job/gang restricted.
    local personal
    if kind ~= "garage" then
        personal = true
    elseif raw.personal == nil then
        personal = accessMode ~= "job" and accessMode ~= "gang"
    else
        personal = raw.personal == true
    end

    local createdBy = nil
    if raw.createdBy then
        createdBy = tostring(raw.createdBy):sub(1, 64)
    end

    return {
        id          = id,
        label       = label,
        kind        = kind,
        type        = garageType,
        point       = point,
        radius      = radius,
        storeRadius = storeRadius,
        zone        = Utils.SanitiseZone(raw.zone, point),
        spots       = spots,
        blip        = blip,
        ped         = ped,
        marker      = marker,
        access      = access,
        impound     = impound,
        fleet       = fleet,
        fleetPlate      = fleetPlate,
        fleetPerPlayer  = fleetPerPlayer,
        fleetRecall     = fleetRecall,
        personal        = personal,
        localVehiclesOnly = raw.localVehiclesOnly == true,
        vehicleCollision  = raw.vehicleCollision ~= false,
        theme       = Utils.SanitiseGarageTheme(raw.theme),
        createdBy   = createdBy,
        createdAt   = tonumber(raw.createdAt) or nil,
        updatedAt   = tonumber(raw.updatedAt) or nil,
    }
end

