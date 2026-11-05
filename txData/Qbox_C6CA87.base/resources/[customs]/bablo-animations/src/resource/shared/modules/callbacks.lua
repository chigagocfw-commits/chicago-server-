



local isServer        = IsDuplicityVersion()
local tableUnpack     = table.unpack
local getinfo         = debug.getinfo
local msgpackPack     = msgpack.pack
local msgpackUnpack   = msgpack.unpack
local msgpackPackArgs = msgpack.pack_args

-- cfx promise state constants
local PROMISE_PENDING  = 0
local PROMISE_RESOLVED = 2
local PROMISE_REJECTED = 4

-- ─── assertType ──────────────────────────────────────────────────────────────
-- Throws a descriptive error if `value` is not one of the expected types.
-- When type1 == "function", also accepts CFX native references (tables with
-- __cfx_functionReference).

local function assertType(value, type1, type2, customMsg)
    local valueType = type(value)
    local caller    = getinfo(2)

    local errorMsg = customMsg
    if not customMsg then
        if type2 == nil then
            errorMsg = caller.name .. " expected %s, but got %s"
        else
            errorMsg = caller.name .. " expected %s or %s, but got %s"
        end
    end

    local function throwError()
        if type2 == nil then
            error(errorMsg:format(type1, valueType))
        else
            error(errorMsg:format(type1, type2, valueType))
        end
    end

    if type1 ~= "function" then
        if valueType ~= type1 and valueType ~= type2 then
            throwError()
        end
    elseif valueType == "table" then
        -- Tables with a CFX function reference are valid as "function"
        if not rawget(value, "__cfx_functionReference") then
            throwError()
        end
    end
end

-- ─── timeoutGuard ────────────────────────────────────────────────────────────
-- Schedules a SetTimeout that calls timedoutFn and rejects the promise if
-- it hasn't been settled yet. Silently skips if the promise is in an
-- intermediate/transitioning state (not PENDING, RESOLVED, or REJECTED).

local function timeoutGuard(prom, timeoutSecs, timedoutFn, handlerRef)
    SetTimeout(timeoutSecs * 1000, function()
        local state = prom.state
        if state ~= PROMISE_PENDING and state ~= PROMISE_REJECTED and state ~= PROMISE_RESOLVED then
            return
        end
        timedoutFn(state)
        if state == PROMISE_PENDING then
            prom:reject(prom)
        end
        RemoveEventHandler(handlerRef)
    end)
end

-- =============================================================================
-- SERVER SIDE
-- =============================================================================

if isServer then

    -- ─── RegisterServerCallback ──────────────────────────────────────────────
    -- opts = { eventName: string, eventCallback: function }
    -- Returns a handlerRef usable with UnregisterServerCallback.

    local function RegisterServerCallback(opts)
        assertType(opts,               "table")
        assertType(opts.eventName,     "string")
        assertType(opts.eventCallback, "function")

        local cb        = opts.eventCallback
        local evtName   = opts.eventName
        local fullEvent = "bablo_animation_callbacks__server_callback:" .. evtName

        local function handler(packedArgs, uniqueId, returnCallback)
            local playerId = tonumber(source)

            if not playerId then
                -- Local-resource call: uniqueId = caller's server ID string,
                -- returnCallback = function that delivers the result.
                local result = { cb(uniqueId, tableUnpack(msgpackUnpack(packedArgs))) }
                returnCallback(msgpackPackArgs(tableUnpack(result)))
            else
                -- Player client call: fire response event back to the client.
                local responseEvent = string.format(
                    "bablo_animation_callbacks__client_callback_response:%s:%s",
                    evtName, playerId
                )
                local result = { cb(playerId, tableUnpack(msgpackUnpack(packedArgs))) }
                TriggerClientEvent(responseEvent, playerId, msgpackPackArgs(tableUnpack(result)))
            end
        end

        return RegisterNetEvent(fullEvent, handler)
    end

    _G.RegisterServerCallback = RegisterServerCallback
    exports("RegisterServerCallback", RegisterServerCallback)

    -- ─── UnregisterServerCallback ────────────────────────────────────────────

    local function UnregisterServerCallback(handlerRef)
        RemoveEventHandler(handlerRef)
    end

    _G.UnregisterServerCallback = UnregisterServerCallback
    exports("UnregisterServerCallback", UnregisterServerCallback)

    -- ─── TriggerClientCallback ────────────────────────────────────────────────
    -- Fires an event on a specific client and awaits its response.
    --
    -- opts = {
    --   source:   number|string   (player server ID, must be >= 0)
    --   eventName: string
    --   args:     table|nil
    --   timeout:  number|nil      (seconds)
    --   timedout: function|nil
    --   callback: function|nil    (if provided → async, no Citizen.Await)
    -- }

    local function TriggerClientCallback(opts)
        assertType(opts,           "table")
        assertType(opts.source,    "string",   "number")
        assertType(opts.eventName, "string")
        assertType(opts.args,      "table",    "nil")
        assertType(opts.timeout,   "number",   "nil")
        assertType(opts.timedout,  "function", "nil")
        assertType(opts.callback,  "function", "nil")

        local playerId = tonumber(opts.source)
        if playerId >= 0 then
            local uniqueId = tostring(playerId) .. "x" .. tostring(GetGameTimer())
            local prom     = promise.new()
            local userCb   = opts.callback
            local evtName  = opts.eventName

            local responseEvent = string.format(
                "bablo_animation_callbacks__callback_retval:%s:%s:%s",
                opts.source, evtName, uniqueId
            )

            local function responseHandler(packedData)
                if userCb and prom.state == PROMISE_PENDING then
                    userCb(tableUnpack(msgpackUnpack(packedData)))
                end
                prom:resolve(tableUnpack(msgpackUnpack(packedData)))
            end

            local handlerRef = RegisterNetEvent(responseEvent, responseHandler)

            TriggerClientEvent(
                "bablo_animation_callbacks__client_callback:" .. evtName,
                playerId,
                msgpackPack(opts.args or {}),
                uniqueId
            )

            if opts.timeout ~= nil and opts.timedout then
                timeoutGuard(prom, opts.timeout, opts.timedout, handlerRef)
            end

            if not userCb then
                local result = Citizen.Await(prom)
                RemoveEventHandler(handlerRef)
                return result
            end
        else
            error("source should be equal too or higher than 0")
        end
    end

    _G.TriggerClientCallback = TriggerClientCallback
    exports("TriggerClientCallback", TriggerClientCallback)

end -- isServer

-- =============================================================================
-- CLIENT SIDE
-- =============================================================================

if not isServer then

    -- Stable server-side ID for this client instance
    local myServerId = GetPlayerServerId(PlayerId())

    -- ─── RegisterClientCallback ──────────────────────────────────────────────
    -- opts = { eventName: string, eventCallback: function }

    local function RegisterClientCallback(opts)
        assertType(opts,               "table")
        assertType(opts.eventName,     "string")
        assertType(opts.eventCallback, "function")

        local cb        = opts.eventCallback
        local evtName   = opts.eventName
        local fullEvent = "bablo_animation_callbacks__client_callback:" .. evtName

        local function handler(packedArgs, uniqueId)
            if type(uniqueId) == "function" then
                -- Local call path: uniqueId is the return-callback function.
                local returnCallback = uniqueId
                local result = { cb(tableUnpack(msgpackUnpack(packedArgs))) }
                returnCallback(msgpackPackArgs(tableUnpack(result)))
            else
                -- Server-triggered path: fire result back via TriggerServerEvent.
                local responseEvent = string.format(
                    "bablo_animation_callbacks__callback_retval:%s:%s:%s",
                    myServerId, evtName, uniqueId
                )
                local result = { cb(tableUnpack(msgpackUnpack(packedArgs))) }
                TriggerServerEvent(responseEvent, msgpackPackArgs(tableUnpack(result)))
            end
        end

        return RegisterNetEvent(fullEvent, handler)
    end

    _G.RegisterClientCallback = RegisterClientCallback
    exports("RegisterClientCallback", RegisterClientCallback)

    -- ─── UnregisterClientCallback ────────────────────────────────────────────

    local function UnregisterClientCallback(handlerRef)
        RemoveEventHandler(handlerRef)
    end

    _G.UnregisterClientCallback = UnregisterClientCallback
    exports("UnregisterClientCallback", UnregisterClientCallback)

    -- ─── TriggerServerCallback ────────────────────────────────────────────────
    -- Fires an event on the server and awaits its response.
    --
    -- opts = {
    --   eventName: string
    --   args:      table|nil
    --   timeout:   number|nil
    --   timedout:  function|nil
    --   callback:  function|nil
    -- }

    local function TriggerServerCallback(opts)
        assertType(opts,           "table")
        assertType(opts.eventName, "string")
        assertType(opts.args,      "table",    "nil")
        assertType(opts.timeout,   "number",   "nil")
        assertType(opts.timedout,  "function", "nil")
        assertType(opts.callback,  "function", "nil")

        local prom    = promise.new()
        local userCb  = opts.callback
        local evtName = opts.eventName

        local responseEvent = string.format(
            "bablo_animation_callbacks__client_callback_response:%s:%s",
            evtName, myServerId
        )

        local function responseHandler(packedData)
            if userCb and prom.state == PROMISE_PENDING then
                userCb(tableUnpack(msgpackUnpack(packedData)))
            end
            prom:resolve(tableUnpack(msgpackUnpack(packedData)))
        end

        local handlerRef = RegisterNetEvent(responseEvent, responseHandler)

        TriggerServerEvent(
            "bablo_animation_callbacks__server_callback:" .. evtName,
            msgpackPack(opts.args or {}),
            myServerId
        )

        if opts.timeout ~= nil and opts.timedout then
            timeoutGuard(prom, opts.timeout, opts.timedout, handlerRef)
        end

        if not userCb then
            local result = Citizen.Await(prom)
            RemoveEventHandler(handlerRef)
            return result
        end
    end

    _G.TriggerServerCallback = TriggerServerCallback
    exports("TriggerServerCallback", TriggerServerCallback)

    -- ─── TriggerClientCallback (client-local) ────────────────────────────────
    -- Same as TriggerServerCallback but fires the event locally (no network
    -- hop) when both caller and handler are on the same client.
    --
    -- opts = {
    --   eventName: string
    --   args:      table|nil
    --   timeout:   number|nil
    --   timedout:  function|nil
    --   callback:  function|nil
    -- }

    local function TriggerClientCallback(opts)
        assertType(opts,           "table")
        assertType(opts.args,      "table",    "nil")
        assertType(opts.eventName, "string")
        assertType(opts.timeout,   "number",   "nil")
        assertType(opts.timedout,  "function", "nil")
        assertType(opts.callback,  "function", "nil")

        local prom    = promise.new()
        local userCb  = opts.callback
        local evtName = opts.eventName

        local responseEvent = string.format(
            "bablo_animation_callbacks__client_callback_response:%s:%s",
            evtName, myServerId
        )

        local function responseHandler(packedData)
            if userCb and prom.state == PROMISE_PENDING then
                userCb(tableUnpack(msgpackUnpack(packedData)))
            end
            prom:resolve(tableUnpack(msgpackUnpack(packedData)))
        end

        local handlerRef = RegisterNetEvent(responseEvent, responseHandler)

        -- Fire locally — no network round-trip
        TriggerEvent(
            "bablo_animation_callbacks__client_callback:" .. evtName,
            msgpackPack(opts.args or {}),
            myServerId
        )

        if opts.timeout ~= nil and opts.timedout then
            timeoutGuard(prom, opts.timeout, opts.timedout, handlerRef)
        end

        if not userCb then
            local result = Citizen.Await(prom)
            RemoveEventHandler(handlerRef)
            return result
        end
    end

    _G.TriggerClientCallback = TriggerClientCallback
    exports("TriggerClientCallback", TriggerClientCallback)

end -- not isServer