

--------------------------------------------------------------------
-- oxlyn-bossmenu | client framework bridge (cleaned)
-- Detects ESX / QBCore / Qbox and exposes a unified API:
--   Framework.type, Framework.core, Framework.ready
--   Framework.TriggerCallback(name, cb, ...)
--   Framework.Notify(type, message)
--------------------------------------------------------------------

Framework = {
    type  = nil,
    core  = nil,
    ready = false,
}

local RESOURCE_TAG = "oxlyn-bossmenu"

local function debugPrint(msg)
    if Config and Config.Debug then
        print("^5[" .. RESOURCE_TAG .. " DEBUG client] " .. tostring(msg) .. "^7")
    end
end

--------------------------------------------------------------------
-- Fallback event-based server callbacks
-- (used when the framework has no usable TriggerCallback)
--------------------------------------------------------------------
local pendingCallbacks = {}
local callbackCounter  = 0
local callbackHandlerRegistered = false

local function ensureCallbackHandler()
    if callbackHandlerRegistered then return end
    callbackHandlerRegistered = true

    RegisterNetEvent(RESOURCE_TAG .. ":cb:resp", function(id, args)
        local cb = pendingCallbacks[id]
        if not cb then return end
        pendingCallbacks[id] = nil

        if args then
            cb(table.unpack(args, 1, args.n or #args))
        else
            cb(nil)
        end
    end)
end

local function fallbackTriggerCallback(name, cb, ...)
    ensureCallbackHandler()

    callbackCounter = callbackCounter + 1
    local id = callbackCounter
    pendingCallbacks[id] = cb or function() end

    -- NOTE: the decompiler only showed the first vararg being packed;
    -- {...} is the most likely original. Use table.pack(...) if you
    -- need to preserve nil holes.
    TriggerServerEvent(RESOURCE_TAG .. ":cb:call", name, id, { ... })
end

--------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------

-- Returns Config.FrameworkResource if set to a non-empty string,
-- otherwise the supplied default.
local function getResourceName(default)
    local override = Config and Config.FrameworkResource
    if type(override) == "string" and override ~= "" then
        return override
    end
    return default
end

-- True for functions and for callable-looking tables
-- (cfx function references or tables with a metatable).
local function isCallable(value)
    local t = type(value)
    if t == "function" then
        return true
    end
    if t == "table" then
        if rawget(value, "__cfx_functionReference") then
            return true
        end
        return getmetatable(value) ~= nil
    end
    return false
end

-- Native GTA feed notification, used as a last resort.
local function nativeNotify(message)
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentSubstringPlayerName(message or "")
    EndTextCommandThefeedPostTicker(false, true)
end

--------------------------------------------------------------------
-- ESX
--------------------------------------------------------------------
local function tryEsx()
    local resource = getResourceName("es_extended")
    local state = GetResourceState(resource)
    debugPrint(("tryEsx: GetResourceState(%s) = %s"):format(resource, tostring(state)))

    if state ~= "started" then
        return false
    end

    local ESX
    local ok = pcall(function()
        ESX = exports[resource]:getSharedObject()
    end)
    debugPrint(("tryEsx: export pcall ok=%s, ESX=%s"):format(tostring(ok), tostring(ESX)))

    if not ok or not ESX then
        -- Legacy fallback
        local okEvent = pcall(function()
            TriggerEvent("esx:getSharedObject", function(obj)
                ESX = obj
            end)
        end)
        debugPrint(("tryEsx: fallback event ok=%s, ESX=%s"):format(tostring(okEvent), tostring(ESX)))

        if not okEvent or not ESX then
            debugPrint("tryEsx: BOTH methods failed — ESX is nil")
            return false
        end
    end

    Framework.type = "esx"
    Framework.core = ESX

    Framework.TriggerCallback = function(name, cb, ...)
        ESX.TriggerServerCallback(name, cb, ...)
    end

    Framework.Notify = function(_, message)
        if ESX.ShowNotification then
            ESX.ShowNotification(message)
        else
            nativeNotify(message)
        end
    end

    Framework.ready = true
    return true
end

--------------------------------------------------------------------
-- QBCore / Qbox
--------------------------------------------------------------------
local function tryQbCore()
    local mode = tostring((Config and Config.Framework) or "auto"):lower()

    local override = nil
    if Config and type(Config.FrameworkResource) == "string" and Config.FrameworkResource ~= "" then
        override = Config.FrameworkResource
    end

    -- Build the list of started candidate resources
    local candidates = {}
    local function addCandidate(resource, kind)
        if GetResourceState(resource) == "started" then
            candidates[#candidates + 1] = { res = resource, kind = kind }
        end
    end

    if override then
        local isQbx = (mode == "qbox" or mode == "qbx")
            or override:lower():find("qbx", 1, true) ~= nil
        addCandidate(override, isQbx and "qbx" or "qb")
    elseif mode == "qbox" or mode == "qbx" then
        addCandidate("qbx_core", "qbx")
    elseif mode == "qbcore" or mode == "qb-core" then
        addCandidate("qb-core", "qb")
    else
        addCandidate("qbx_core", "qbx")
        addCandidate("qb-core", "qb")
    end

    if #candidates == 0 then
        debugPrint("tryQbCore: no candidate backend is started")
        return false
    end

    local core, coreResource

    for _, candidate in ipairs(candidates) do
        local res, kind = candidate.res, candidate.kind
        debugPrint("tryQbCore: trying " .. res)

        local obj
        local ok, err = pcall(function()
            obj = exports[res]:GetCoreObject()
        end)

        if not ok then
            debugPrint(("tryQbCore: %s GetCoreObject raised: %s"):format(res, tostring(err)))
        elseif obj == nil then
            debugPrint(("tryQbCore: %s GetCoreObject returned nil"):format(res))
        elseif obj.Functions and isCallable(obj.Functions.TriggerCallback) then
            -- Core object is fully usable
            core, coreResource = obj, res
            break
        else
            debugPrint(("tryQbCore: %s GetCoreObject shim missing TriggerCallback"):format(res))
        end

        -- Qbox: GetCoreObject shim unusable, probe direct exports instead
        if kind == "qbx" then
            local probeOk = false
            for _, exportName in ipairs({ "GetPlayerData", "GetCoreVersion" }) do
                local success, probeErr = pcall(function()
                    return exports[res][exportName](exports[res])
                end)
                if success then
                    debugPrint(("tryQbCore: %s %s probe OK"):format(res, exportName))
                    probeOk = true
                    break
                else
                    debugPrint(("tryQbCore: %s %s probe failed: %s"):format(res, exportName, tostring(probeErr)))
                end
            end

            if probeOk then
                debugPrint(("tryQbCore: %s direct exports OK — using event-based callbacks"):format(res))
                core = {
                    _qbx_direct = true,
                    _resName    = res,
                    Functions   = {},
                }
                coreResource = res
                break
            end
        end
    end

    if not core then
        return false
    end

    debugPrint("tryQbCore: chosen backend = " .. tostring(coreResource))

    Framework.type = "qbcore"
    Framework.core = core

    -- Callbacks: native if available, otherwise event-based fallback
    if core.Functions and isCallable(core.Functions.TriggerCallback) then
        Framework.TriggerCallback = function(name, cb, ...)
            core.Functions.TriggerCallback(name, cb, ...)
        end
    else
        Framework.TriggerCallback = function(name, cb, ...)
            fallbackTriggerCallback(name, cb, ...)
        end
    end

    -- Notifications: core Functions -> export -> native feed
    Framework.Notify = function(notifyType, message)
        if core.Functions and isCallable(core.Functions.Notify) then
            core.Functions.Notify(message, notifyType or "primary")
            return
        end

        local resName = core._resName or "qbx_core"
        local ok = pcall(function()
            exports[resName]:Notify(message, notifyType or "primary")
        end)
        if ok then return end

        nativeNotify(message)
    end

    Framework.ready = true
    return true
end

--------------------------------------------------------------------
-- Detection entry point (respects Config.Framework)
--------------------------------------------------------------------
local function detectFramework()
    local mode = tostring((Config and Config.Framework) or "auto"):lower()

    if mode == "esx" then
        return tryEsx()
    end

    if mode == "qbcore" or mode == "qb-core" or mode == "qbx" or mode == "qbox" then
        return tryQbCore()
    end

    -- auto
    if tryEsx() then return true end
    if tryQbCore() then return true end
    return false
end

--------------------------------------------------------------------
-- Boot: wait for Config, then retry detection for up to 30s
--------------------------------------------------------------------
CreateThread(function()
    while not Config do
        Wait(50)
    end

    debugPrint("Boot: Config loaded, Config.Framework = " .. tostring(Config.Framework))
    debugPrint("Boot: resource states at boot:")
    debugPrint("  es_extended = " .. tostring(GetResourceState("es_extended")))
    debugPrint("  qb-core     = " .. tostring(GetResourceState("qb-core")))
    debugPrint("  qbx_core    = " .. tostring(GetResourceState("qbx_core")))

    local waited = 0
    while not Framework.ready and waited < 30000 do
        if detectFramework() then
            print(("^2[%s] Framework detected: %s (client)^7"):format(RESOURCE_TAG, Framework.type))
            return
        end
        Wait(500)
        waited = waited + 500
    end

    if not Framework.ready then
        print(("^1[%s] No framework detected after 30s. States:^7"):format(RESOURCE_TAG))
        print("^1  es_extended = " .. tostring(GetResourceState("es_extended")) .. "^7")
        print("^1  qb-core     = " .. tostring(GetResourceState("qb-core")) .. "^7")
        print("^1  qbx_core    = " .. tostring(GetResourceState("qbx_core")) .. "^7")
        print(("^1  Solution: make sure es_extended (or qb-core / qbx_core) is ensured in server.cfg BEFORE %s.^7"):format(RESOURCE_TAG))
    end
end)

--------------------------------------------------------------------
-- Late detection: if a framework resource starts after us
--------------------------------------------------------------------
AddEventHandler("onClientResourceStart", function(resourceName)
    if Framework.ready then return end

    local override = Config and Config.FrameworkResource

    if resourceName == "es_extended"
        or resourceName == "qb-core"
        or resourceName == "qbx_core"
        or resourceName == override then

        Wait(200)
        if detectFramework() then
            print(("^2[%s] Framework detected (after %s started): %s^7"):format(
                RESOURCE_TAG, resourceName, Framework.type))
        end
    end
end)

