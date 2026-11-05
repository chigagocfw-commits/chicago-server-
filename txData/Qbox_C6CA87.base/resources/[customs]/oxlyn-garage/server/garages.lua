

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved; tangled goto/if chains were rebuilt by intent.

Garages = Garages or {}
Garages.List = {}      -- [id] = garage
Garages.Ready = false

local resourceName = GetCurrentResourceName()

local function log(msg)
    print(("[%s] %s"):format(resourceName, msg))
end

---------------------------------------------------------------------
-- Sorted list cache (by lowercase label, then id)
---------------------------------------------------------------------

local sortedCache = nil

local function getSorted()
    if not sortedCache then
        local list, labels = {}, {}

        for _, garage in pairs(Garages.List) do
            list[#list + 1] = garage
            labels[garage] = garage.label:lower()
        end

        table.sort(list, function(a, b)
            if labels[a] == labels[b] then
                return a.id < b.id
            end
            return labels[a] < labels[b]
        end)

        sortedCache = list
    end
    return sortedCache
end

---------------------------------------------------------------------
-- Load / CRUD
---------------------------------------------------------------------

function Garages.Load()
    local garages = DB.LoadGarages()

    -- First run: seed from Config.DefaultGarages
    if #garages == 0 and type(Config.DefaultGarages) == "table" then
        log(("no garages in the database — seeding %d default garage(s)"):format(#Config.DefaultGarages))

        for _, default in ipairs(Config.DefaultGarages) do
            local garage, err = Utils.SanitiseGarage(default)
            if garage then
                garage.createdAt = os.time()
                garage.updatedAt = os.time()
                garage.createdBy = "config"
                DB.SaveGarage(garage)
                garages[#garages + 1] = garage
            else
                log(("^3default garage skipped: %s^7"):format(tostring(err)))
            end
        end
    end

    Garages.List = {}
    sortedCache = nil

    for _, raw in ipairs(garages) do
        local garage, err = Utils.SanitiseGarage(raw)
        if garage then
            Garages.List[garage.id] = garage
        else
            log(("^3garage \"%s\" ignored: %s^7"):format(tostring(raw.id), tostring(err)))
        end
    end

    Garages.Ready = true
    log(("%d garage(s) loaded"):format(Utils.Count(Garages.List)))
end

function Garages.Get(id)
    if not id then return nil end
    return Garages.List[id]
end

--- Shallow copy of the sorted garage array.
function Garages.All()
    local copy = {}
    for i, garage in ipairs(getSorted()) do
        copy[i] = garage
    end
    return copy
end

--- Create or update a garage.
--- @param data       raw garage data (will be sanitised)
--- @param createdBy  who is saving (defaults to existing creator, else "editor")
--- @param oldId      previous id, if the garage is being renamed
--- @return table|nil garage, string|nil error
function Garages.Save(data, createdBy, oldId)
    local garage, err = Utils.SanitiseGarage(data)
    if not garage then
        return nil, err
    end

    local existing = Garages.List[garage.id]

    -- Handle id change (rename)
    if oldId and oldId ~= garage.id then
        if existing then
            return nil, "id_taken"
        end
        if Garages.List[oldId] then
            DB.DeleteGarage(oldId)
            Garages.List[oldId] = nil
            sortedCache = nil
        end
    end

    garage.createdAt = (existing and existing.createdAt)
        or tonumber(data.createdAt)
        or os.time()
    garage.createdBy = createdBy or (existing and existing.createdBy) or "editor"
    garage.updatedAt = os.time()

    DB.SaveGarage(garage)
    Garages.List[garage.id] = garage
    sortedCache = nil

    Garages.BroadcastAll()
    TriggerEvent(resourceName .. ":server:garageSaved", garage)

    return garage
end

function Garages.Delete(id)
    if not Garages.List[id] then
        return false
    end

    DB.DeleteGarage(id)
    Garages.List[id] = nil
    sortedCache = nil

    Garages.BroadcastAll()
    TriggerEvent(resourceName .. ":server:garageDeleted", id)

    return true
end

---------------------------------------------------------------------
-- Access control
---------------------------------------------------------------------

--- Can player `src` use `garage`?
--- `cache` (optional table) memoises job/gang/identifier lookups across many
--- garages for the same player.
function Garages.CanAccess(src, garage, cache)
    if not garage then return false end

    local access = garage.access or {}
    local mode = access.mode

    if mode == "public" or mode == nil then
        return true
    end

    if mode == "job" then
        if cache then
            if cache.job == nil then
                cache.job = Framework.GetJob(src) or false
            end
            local job = cache.job
            if not job then return false end

            local allowed = access.jobs and access.jobs[job.name]
            return allowed ~= nil
        end

        return Framework.HasJob(src, access.jobs, false) and true or false
    end

    if mode == "gang" then
        if cache then
            if cache.gang == nil then
                cache.gang = Framework.GetGang(src) or false
            end
            local gang = cache.gang
            if gang then
                for _, name in ipairs(access.gangs or {}) do
                    if name == gang.name then
                        return true
                    end
                end
            end
            return false
        end

        return Framework.HasGang(src, access.gangs) and true or false
    end

    if mode == "private" then
        local allowedIds = access.identifiers or {}
        if #allowedIds == 0 then
            return false
        end

        -- Set of this player's identifiers (lowercased)
        local playerIds = cache and cache.identifiers
        if not playerIds then
            playerIds = {}
            playerIds[(Framework.GetIdentifier(src) or ""):lower()] = true
            for _, id in ipairs(Framework.IdentifiersOf(src)) do
                playerIds[id:lower()] = true
            end
            if cache then
                cache.identifiers = playerIds
            end
        end

        for _, id in ipairs(allowedIds) do
            if playerIds[tostring(id):lower()] then
                return true
            end
        end
        return false
    end

    return false
end

---------------------------------------------------------------------
-- Queries
---------------------------------------------------------------------

--- Nearest garage to `coords`, optionally filtered by `kind` and `maxDist`.
--- @return table|nil garage, number distance
function Garages.Nearest(coords, kind, maxDist)
    local nearest
    local best = maxDist or math.huge

    for _, garage in pairs(Garages.List) do
        if not kind or garage.kind == kind then
            local dist = Utils.Dist(coords, garage.point)
            if best > dist then
                best = dist
                nearest = garage
            end
        end
    end

    return nearest, best
end

--- First garage (by sort order) matching `kind` and `vehicleType`
--- ("all" garages match any type). Falls back to the first garage overall.
function Garages.Any(kind, vehicleType)
    local sorted = getSorted()

    for _, garage in ipairs(sorted) do
        local kindOk = not kind or garage.kind == kind
        local typeOk = not vehicleType or garage.type == vehicleType or garage.type == "all"
        if kindOk and typeOk then
            return garage
        end
    end

    return sorted[1]
end

--- Display label for a garage id ("—" if unknown/empty).
function Garages.Label(id)
    local garage = id and Garages.List[id]
    if garage and garage.label then
        return garage.label
    end
    if id then
        return tostring(id)
    end
    return "—"
end

---------------------------------------------------------------------
-- Client sync
---------------------------------------------------------------------

--- Build the garage list for one player, each entry copied with an
--- `accessible` flag.
local function buildPlayerList(src)
    local result = {}
    local cache = {}

    for _, garage in ipairs(getSorted()) do
        local entry = {}
        for k, v in pairs(garage) do
            entry[k] = v
        end
        entry.accessible = Garages.CanAccess(src, garage, cache)
        result[#result + 1] = entry
    end

    return result
end

function Garages.SyncPlayer(src)
    if not (Garages.Ready and src) or src == 0 then
        return
    end

    TriggerClientEvent(resourceName .. ":client:sync", src, buildPlayerList(src))
end

function Garages.BroadcastAll()
    if not Garages.Ready then return end

    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            Garages.SyncPlayer(src)
        end
    end
end

RegisterNetEvent(resourceName .. ":sv:requestSync", function()
    Garages.SyncPlayer(source)
end)

