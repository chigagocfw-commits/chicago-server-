local isServer = IsDuplicityVersion()
local unpack = table.unpack
local debugGetInfo = debug.getinfo
local msgpackPack = msgpack.pack
local msgpackUnpack = msgpack.unpack
local msgpackPackArgs = msgpack.pack_args

local PROMISE_PENDING = 0
local PROMISE_REJECTED = 2
local PROMISE_TIMED_OUT = 4

local function assertType(value, expectedType, optionalType, message)
  local actualType = type(value)
  local caller = debugGetInfo(2)
  local callerName = caller and caller.name or "callback"

  message = message or (
    optionalType == nil
      and (callerName .. " expected %s, but got %s")
      or (callerName .. " expected %s or %s, but got %s")
  )

  if expectedType == "function" and actualType == "table" then
    if rawget(value, "__cfx_functionReference") then
      return
    end
  elseif actualType == expectedType or actualType == optionalType then
    return
  end

  if optionalType == nil then
    error(message:format(expectedType, actualType))
  end

  error(message:format(expectedType, optionalType, actualType))
end

local function unpackArgs(packedArgs)
  local decoded = msgpackUnpack(packedArgs)

  if type(decoded) ~= "table" then
    return decoded
  end

  if decoded[1] ~= nil then
    return unpack(decoded)
  end

  return decoded
end

local function shouldTimeout(callbackPromise)
  return callbackPromise.state == PROMISE_PENDING
    or callbackPromise.state == PROMISE_TIMED_OUT
    or callbackPromise.state == PROMISE_REJECTED
end

if isServer then
  function RegisterServerCallback(options)
    assertType(options, "table")
    assertType(options.eventName, "string")
    assertType(options.eventCallback, "function")

    local eventCallback = options.eventCallback
    local callbackName = options.eventName

    return RegisterNetEvent("bablo_banking_callbacks__server_callback:" .. callbackName, function(packedArgs, requestId, localCallback)
      local playerSource = tonumber(source)

      if not playerSource then
        localCallback(msgpackPackArgs(eventCallback(requestId, unpackArgs(packedArgs))))
        return
      end

      TriggerClientEvent(
        ("bablo_banking_callbacks__client_callback_response:%s:%s"):format(callbackName, playerSource),
        playerSource,
        msgpackPackArgs(eventCallback(playerSource, unpackArgs(packedArgs)))
      )
    end)
  end

  exports("RegisterServerCallback", RegisterServerCallback)

  function UnregisterServerCallback(eventHandler)
    RemoveEventHandler(eventHandler)
  end

  exports("UnregisterServerCallback", UnregisterServerCallback)

  function TriggerClientCallback(options)
    assertType(options, "table")
    assertType(options.source, "string", "number")
    assertType(options.eventName, "string")
    assertType(options.args, "table", "nil")
    assertType(options.timeout, "number", "nil")
    assertType(options.timedout, "function", "nil")
    assertType(options.callback, "function", "nil")

    local playerSource = tonumber(options.source)
    if playerSource < 0 then
      error("source should be equal too or higher than 0")
    end

    local requestId = tostring(options.source) .. "x" .. tostring(GetGameTimer())
    local callbackPromise = promise.new()
    local callback = options.callback

    local eventHandler = RegisterNetEvent(
      ("bablo_banking_callbacks__callback_retval:%s:%s:%s"):format(options.source, options.eventName, requestId),
      function(packedResult)
        if callback and callbackPromise.state == PROMISE_PENDING then
          callback(unpackArgs(packedResult))
        end

        callbackPromise:resolve(unpackArgs(packedResult))
      end
    )

    TriggerClientEvent(
      ("bablo_banking_callbacks__client_callback:%s"):format(options.eventName),
      options.source,
      msgpackPack(options.args or {}),
      requestId
    )

    if options.timeout ~= nil and options.timedout then
      SetTimeout(options.timeout * 1000, function()
        if shouldTimeout(callbackPromise) then
          options.timedout(callbackPromise.state)

          if callbackPromise.state == PROMISE_PENDING then
            callbackPromise:reject()
          end

          RemoveEventHandler(eventHandler)
        end
      end)
    end

    if not callback then
      local result = Citizen.Await(callbackPromise)
      RemoveEventHandler(eventHandler)
      return result
    end
  end

  exports("TriggerClientCallback", TriggerClientCallback)

  function TriggerServerCallback(options)
    assertType(options, "table")
    assertType(options.source, "string", "number")
    assertType(options.eventName, "string")
    assertType(options.args, "table", "nil")
    assertType(options.timeout, "number", "nil")
    assertType(options.timedout, "function", "nil")
    assertType(options.callback, "function", "nil")

    local callbackPromise = promise.new()
    local callback = options.callback

    TriggerEvent(
      "bablo_banking_callbacks__server_callback:" .. options.eventName,
      msgpackPack(options.args or {}),
      options.source,
      function(packedResult)
        if callback and callbackPromise.state == PROMISE_PENDING then
          callback(unpackArgs(packedResult))
        end

        callbackPromise:resolve(unpackArgs(packedResult))
      end
    )

    if options.timeout ~= nil and options.timedout then
      SetTimeout(options.timeout * 1000, function()
        if shouldTimeout(callbackPromise) then
          options.timedout(callbackPromise.state)

          if callbackPromise.state == PROMISE_PENDING then
            callbackPromise:reject()
          end
        end
      end)
    end

    if not callback then
      return Citizen.Await(callbackPromise)
    end
  end

  exports("TriggerServerCallback", TriggerServerCallback)
else
  local playerServerId = GetPlayerServerId(PlayerId())

  function RegisterClientCallback(options)
    assertType(options, "table")
    assertType(options.eventName, "string")
    assertType(options.eventCallback, "function")

    local eventCallback = options.eventCallback
    local callbackName = options.eventName

    return RegisterNetEvent("bablo_banking_callbacks__client_callback:" .. callbackName, function(packedArgs, requestIdOrCallback)
      if type(requestIdOrCallback) == "function" then
        requestIdOrCallback(msgpackPackArgs(eventCallback(unpackArgs(packedArgs))))
        return
      end

      TriggerServerEvent(
        ("bablo_banking_callbacks__callback_retval:%s:%s:%s"):format(playerServerId, callbackName, requestIdOrCallback),
        msgpackPackArgs(eventCallback(unpackArgs(packedArgs)))
      )
    end)
  end

  exports("RegisterClientCallback", RegisterClientCallback)

  function UnregisterClientCallback(eventHandler)
    RemoveEventHandler(eventHandler)
  end

  exports("UnregisterClientCallback", UnregisterClientCallback)

  function TriggerServerCallback(options)
    assertType(options, "table")
    assertType(options.args, "table", "nil")
    assertType(options.eventName, "string")
    assertType(options.timeout, "number", "nil")
    assertType(options.timedout, "function", "nil")
    assertType(options.callback, "function", "nil")

    local callbackPromise = promise.new()
    local callback = options.callback

    local eventHandler = RegisterNetEvent(
      ("bablo_banking_callbacks__client_callback_response:%s:%s"):format(options.eventName, playerServerId),
      function(packedResult)
        if callback and callbackPromise.state == PROMISE_PENDING then
          callback(unpackArgs(packedResult))
        end

        callbackPromise:resolve(unpackArgs(packedResult))
      end
    )

    TriggerServerEvent(
      "bablo_banking_callbacks__server_callback:" .. options.eventName,
      msgpackPack(options.args)
    )

    if options.timeout ~= nil and options.timedout then
      SetTimeout(options.timeout * 1000, function()
        if shouldTimeout(callbackPromise) then
          options.timedout(callbackPromise.state)

          if callbackPromise.state == PROMISE_PENDING then
            callbackPromise:reject()
          end

          RemoveEventHandler(eventHandler)
        end
      end)
    end

    if not callback then
      local result = Citizen.Await(callbackPromise)
      RemoveEventHandler(eventHandler)
      return result
    end
  end

  exports("TriggerServerCallback", TriggerServerCallback)

  function TriggerClientCallback(options)
    assertType(options, "table")
    assertType(options.eventName, "string")
    assertType(options.args, "table", "nil")
    assertType(options.timeout, "number", "nil")
    assertType(options.timedout, "function", "nil")
    assertType(options.callback, "function", "nil")

    local callbackPromise = promise.new()
    local callback = options.callback

    TriggerEvent(
      "bablo_banking_callbacks__client_callback:" .. options.eventName,
      msgpackPack(options.args or {}),
      function(packedResult)
        if callback and callbackPromise.state == PROMISE_PENDING then
          callback(unpackArgs(packedResult))
        end

        callbackPromise:resolve(unpackArgs(packedResult))
      end
    )

    if options.timeout ~= nil and options.timedout then
      SetTimeout(options.timeout * 1000, function()
        if shouldTimeout(callbackPromise) then
          options.timedout(callbackPromise.state)

          if callbackPromise.state == PROMISE_PENDING then
            callbackPromise:reject()
          end
        end
      end)
    end

    if not callback then
      return Citizen.Await(callbackPromise)
    end
  end

  exports("TriggerClientCallback", TriggerClientCallback)
end
