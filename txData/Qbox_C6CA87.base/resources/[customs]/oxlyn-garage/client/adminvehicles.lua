

AdminGarage = AdminGarage or {}
AdminGarage.open = false

local session = nil      -- current admin garage session id
local opening = false    -- open request in flight
local busy = false       -- action request in flight
local token = 0          -- bumped on open/close to invalidate stale callbacks
local resourceName = GetCurrentResourceName()

local function fail(key)
    return { ok = false, error = key, message = _U(key) }
end

local function prepare(data)
    for _, garage in ipairs(data.garages or {}) do
        for _, vehicle in ipairs(garage.vehicles or {}) do
            Garage.Enrich(vehicle)
        end
        garage.vehicles = Utils.Arr(garage.vehicles)
    end
    data.garages = Utils.Arr(data.garages)
    return data
end

local function releaseSession(id)
    Framework.TriggerCallback("adminGarage:close", function() end, id)
end

function AdminGarage.Close()
    token = token + 1
    local oldSession = session
    session, opening, busy = nil, false, false
    AdminGarage.open = false

    Client.ReleaseFocus("adminGarage")
    Client.NUI("adminGarage:close")

    if oldSession then
        releaseSession(oldSession)
    end
end

function AdminGarage.Open(target)
    target = tonumber(target)
    if not target or target < 1 or target % 1 ~= 0 then
        return Client.Notify(_U("admin_garage_invalid_target"), "error")
    end

    if opening or AdminGarage.open or Client.Busy() then return end

    token = token + 1
    local myToken = token
    opening = true

    Framework.TriggerCallback("adminGarage:open", function(res)
        -- stale response (closed/reopened meanwhile) or player became busy
        if myToken ~= token or Client.Busy() then
            if res and res.ok and res.session then
                releaseSession(res.session)
            end
            if myToken == token then opening = false end
            return
        end

        opening = false

        if not (res and res.ok) then
            return Client.Notify((res and res.message) or _U("ui_ag_request_failed"), "error")
        end

        AdminGarage.open = true
        session = res.session
        Client.SetFocus("adminGarage")
        Client.NUI("adminGarage:open", prepare(res))
    end, target)
end

-- Generic guarded server request. Extra args are forwarded after the session.
local function request(name, data, cb, ...)
    if not (AdminGarage.open and type(data) == "table" and data.session == session) then
        return cb(fail("ui_ag_request_failed"))
    end

    if busy then
        return cb(fail("ui_ag_loading"))
    end

    busy = true
    local myToken, mySession = token, session

    Framework.TriggerCallback(name, function(res)
        if myToken ~= token or mySession ~= session then
            return cb(fail("ui_ag_request_failed"))
        end

        busy = false
        res = res or fail("ui_ag_request_failed")

        if res.fatal then
            cb(res)
            AdminGarage.Close()
            return Client.Notify(res.message or _U("no_permission"), "error")
        end

        cb((res.ok and prepare(res)) or res)
    end, mySession, ...)
end

RegisterNUICallback("adminGarage:close", function(_, cb)
    AdminGarage.Close()
    cb(1)
end)

RegisterNUICallback("adminGarage:refresh", function(data, cb)
    request("adminGarage:refresh", data, cb)
end)

RegisterNUICallback("adminGarage:remove", function(data, cb)
    if type(data) ~= "table" then
        return cb(fail("ui_ag_request_failed"))
    end
    request("adminGarage:remove", data, cb, data.garageId, data.plate)
end)

RegisterNUICallback("adminGarage:add", function(data, cb)
    if not (type(data) == "table" and AdminGarage.open and data.session == session) then
        return cb(fail("ui_ag_request_failed"))
    end

    -- model (name or numeric hash)
    local model = type(data.model) == "string" and Utils.Trim(data.model):lower() or ""
    if model == "" or #model > 48 then
        return cb(fail("ui_ag_invalid_model"))
    end

    local numeric = tonumber(model)
    if not numeric and not model:match("^[%w_]+$") then
        return cb(fail("ui_ag_invalid_model"))
    end

    local hash = numeric or GetHashKey(model)
    if not (hash and hash ~= 0 and hash % 1 == 0
        and IsModelInCdimage(hash) and IsModelAVehicle(hash)) then
        return cb(fail("model_invalid"))
    end

    local modelName = (not numeric) and model or nil

    -- plate
    local plate = type(data.plate) == "string" and Utils.Trim(data.plate):upper() or ""
    if #plate > 8 or plate:find("[^A-Z0-9 ]") then
        return cb(fail("ui_ag_invalid_plate"))
    end

    local info = Garage.Enrich({ model = hash, modelName = modelName })

    request("adminGarage:add", data, cb, data.garageId, {
        model     = hash,
        modelName = modelName,
        class     = info.class,
        category  = Utils.CategoryFromClass(info.class),
        label     = info.displayName or info.label,
        plate     = plate ~= "" and plate or nil,
    })
end)

AddEventHandler("onResourceStop", function(name)
    if name ~= resourceName then return end

    token = token + 1
    session, opening, busy = nil, false, false
    AdminGarage.open = false
    Client.ReleaseFocus("adminGarage")
end)

