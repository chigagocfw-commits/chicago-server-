local isServer = IsDuplicityVersion()
local registeredCallbacks = {}
local pendingCallbacks = {}
local callbackId = 0

local CALLBACK_REQUEST = "bablo-atm:callback:request"
local CALLBACK_RESPONSE = "bablo-atm:callback:response"

local function assertType(value, expectedType, name)
    if type(value) ~= expectedType then
        error(("%s must be a %s"):format(name, expectedType), 3)
    end
end

local function nextCallbackId()
    callbackId = callbackId + 1
    return callbackId
end

local function registerCallback(options)
    assertType(options, "table", "options")
    assertType(options.eventName, "string", "options.eventName")
    assertType(options.eventCallback, "function", "options.eventCallback")

    registeredCallbacks[options.eventName] = options.eventCallback
    return options.eventName
end

local function unregisterCallback(eventName)
    registeredCallbacks[eventName] = nil
end

local function resolvePending(id, response)
    local pending = pendingCallbacks[id]
    if not pending then
        return
    end

    pendingCallbacks[id] = nil
    pending:resolve(response)
end

if isServer then
    function RegisterServerCallback(options)
        return registerCallback(options)
    end

    function UnregisterServerCallback(eventName)
        unregisterCallback(eventName)
    end

    RegisterNetEvent(CALLBACK_REQUEST, function(id, eventName, args)
        local src = source
        local callback = registeredCallbacks[eventName]

        if not callback then
            TriggerClientEvent(CALLBACK_RESPONSE, src, id, nil)
            return
        end

        local ok, result = pcall(callback, src, args or {})
        if not ok then
            Error(("[bablo-atm] Server callback '%s' failed: %s"):format(eventName, result))
            result = nil
        end

        TriggerClientEvent(CALLBACK_RESPONSE, src, id, result)
    end)

    RegisterNetEvent(CALLBACK_RESPONSE, function(id, response)
        resolvePending(id, response)
    end)

    function RegisterClientCallback(options)
        return registerCallback(options)
    end

    function TriggerClientCallback(options)
        assertType(options, "table", "options")
        assertType(options.source, "number", "options.source")
        assertType(options.eventName, "string", "options.eventName")

        local id = nextCallbackId()
        local request = promise.new()
        pendingCallbacks[id] = request

        TriggerClientEvent(CALLBACK_REQUEST, options.source, id, options.eventName, options.args or {})

        if options.timeout ~= false then
            SetTimeout(options.timeout or 5000, function()
                local pending = pendingCallbacks[id]
                if pending then
                    pendingCallbacks[id] = nil
                    pending:resolve(options.timedout)
                end
            end)
        end

        if options.callback then
            CreateThread(function()
                options.callback(Citizen.Await(request))
            end)
            return
        end

        return Citizen.Await(request)
    end
else
    function RegisterClientCallback(options)
        return registerCallback(options)
    end

    function UnregisterClientCallback(eventName)
        unregisterCallback(eventName)
    end

    RegisterNetEvent(CALLBACK_REQUEST, function(id, eventName, args)
        local callback = registeredCallbacks[eventName]

        if not callback then
            TriggerServerEvent(CALLBACK_RESPONSE, id, nil)
            return
        end

        local ok, result = pcall(callback, args or {})
        if not ok then
            Error(("[bablo-atm] Client callback '%s' failed: %s"):format(eventName, result))
            result = nil
        end

        TriggerServerEvent(CALLBACK_RESPONSE, id, result)
    end)

    RegisterNetEvent(CALLBACK_RESPONSE, function(id, response)
        resolvePending(id, response)
    end)

    function TriggerServerCallback(options)
        assertType(options, "table", "options")
        assertType(options.eventName, "string", "options.eventName")

        local id = nextCallbackId()
        local request = promise.new()
        pendingCallbacks[id] = request

        TriggerServerEvent(CALLBACK_REQUEST, id, options.eventName, options.args or {})

        if options.timeout ~= false then
            SetTimeout(options.timeout or 5000, function()
                local pending = pendingCallbacks[id]
                if pending then
                    pendingCallbacks[id] = nil
                    pending:resolve(options.timedout)
                end
            end)
        end

        if options.callback then
            CreateThread(function()
                options.callback(Citizen.Await(request))
            end)
            return
        end

        return Citizen.Await(request)
    end
end
