

-- Client only
if IsDuplicityVersion() then
    return
end

NotifyBridge = NotifyBridge or {}

local function isStarted(resource)
    return GetResourceState(resource) == "started"
end

---------------------------------------------------------------------
-- Notification type mapping
-- Internal types: "info", "success", "error", "warning"
---------------------------------------------------------------------

-- ox_lib uses "inform" instead of "info"
local function toOxType(notifyType)
    return notifyType == "info" and "inform" or notifyType
end

-- qb-core has no "info"/"warning" style; "primary" is the neutral one
local function toQbType(notifyType)
    if notifyType == "info" or notifyType == "warning" then
        return "primary"
    end
    return notifyType
end

local function toMythicType(notifyType)
    if notifyType == "info" or notifyType == "warning" then
        return "inform"
    end
    return notifyType
end

---------------------------------------------------------------------
-- Providers
-- send(message, type, title, duration)
---------------------------------------------------------------------

local providers = {
    {
        id = "okokNotify",
        resource = "okokNotify",
        send = function(message, notifyType, title, duration)
            exports.okokNotify:Alert(title, message, duration, notifyType)
        end,
    },
    {
        id = "brutal_notify",
        resource = "brutal_notify",
        send = function(message, notifyType, title, duration)
            exports.brutal_notify:SendAlert(title, message, duration, notifyType, false)
        end,
    },
    {
        id = "wasabi_notify",
        resource = "wasabi_notify",
        send = function(message, notifyType, title, duration)
            exports.wasabi_notify:notify(title, message, duration, notifyType)
        end,
    },
    {
        id = "lation_ui",
        resource = "lation_ui",
        send = function(message, notifyType, title, duration)
            exports.lation_ui:notify({
                title = title,
                message = message,
                type = notifyType,
                duration = duration,
            })
        end,
    },
    {
        id = "t-notify",
        resource = "t-notify",
        send = function(message, notifyType, _, duration)
            exports["t-notify"]:Alert({
                style = notifyType,
                message = message,
                duration = duration,
            })
        end,
    },
    {
        id = "mythic_notify",
        resource = "mythic_notify",
        send = function(message, notifyType, _, duration)
            exports.mythic_notify:SendAlert(toMythicType(notifyType), message, duration)
        end,
    },
    {
        id = "pNotify",
        resource = "pNotify",
        send = function(message, notifyType, _, duration)
            exports.pNotify:SendNotification({
                text = message,
                type = notifyType,
                timeout = duration,
                layout = "centerRight",
            })
        end,
    },
    {
        id = "oxlyn-notify",
        resource = "oxlyn-notify",
        send = function(message, notifyType, title, duration)
            exports["oxlyn-notify"]:ShowNotification(notifyType, title, message, duration)
        end,
    },
    {
        id = "corescripts-notify",
        resource = "corescripts-notify",
        send = function(message, notifyType, _, duration)
            exports["corescripts-notify"]:Notify(message, notifyType, duration)
        end,
    },
    {
        id = "esx_notify",
        resource = "esx_notify",
        send = function(message, notifyType, title, duration)
            exports.esx_notify:Notify(notifyType, duration, message, title)
        end,
    },
    {
        id = "ox_lib",
        resource = "ox_lib",
        send = function(message, notifyType, title, duration)
            exports.ox_lib:notify({
                title = title,
                description = message,
                type = toOxType(notifyType),
                duration = duration,
            })
        end,
    },
    {
        id = "qbox",
        resource = "qbx_core",
        send = function(message, notifyType, _, duration)
            exports.qbx_core:Notify(message, toOxType(notifyType), duration)
        end,
    },
    {
        id = "qbcore",
        resource = "qb-core",
        send = function(message, notifyType, _, duration)
            local core = (Framework.Name == "qbcore" and Framework.Core)
                or exports["qb-core"]:GetCoreObject()
            core.Functions.Notify(message, toQbType(notifyType), duration)
        end,
    },
    {
        id = "esx",
        resource = "es_extended",
        send = function(message, notifyType, _, duration)
            local core = (Framework.Name == "esx" and Framework.Core)
                or exports.es_extended:getSharedObject()
            core.ShowNotification(message, notifyType, duration)
        end,
    },
}

-- Auto-detect order is the order above.

-- Lookup by lowercase id, plus short aliases
local providersById = {}
for _, provider in ipairs(providers) do
    providersById[provider.id:lower()] = provider
end

providersById.okok    = providersById.okoknotify
providersById.qbx     = providersById.qbox
providersById.qb      = providersById.qbcore
providersById.oxlib   = providersById.ox_lib
providersById.ox      = providersById.ox_lib
providersById.lation  = providersById.lation_ui
providersById.wasabi  = providersById.wasabi_notify
providersById.brutal  = providersById.brutal_notify
providersById.mythic  = providersById.mythic_notify

---------------------------------------------------------------------
-- System resolution
---------------------------------------------------------------------

local function configuredSystem()
    local notifyConfig = Config.Notify
    return tostring((notifyConfig and notifyConfig.system) or "builtin"):lower()
end

-- Returns:
--   nil            -> use the built-in toasts
--   "custom"/"event" (string) -> use Config.Notify.custom / Config.Notify.event
--   provider table -> use that provider
local function resolveProvider()
    local system = configuredSystem()

    if system == "builtin" or system == "none" or system == "" then
        return nil
    end

    if system == "custom" or system == "event" then
        return system
    end

    if system == "auto" then
        for _, provider in ipairs(providers) do
            if isStarted(provider.resource) then
                return provider
            end
        end
        return nil
    end

    local provider = providersById[system]
    if provider and isStarted(provider.resource) then
        return provider
    end

    return nil
end

local warned = {}

local function warnOnce(key, message)
    if warned[key] then
        return
    end
    warned[key] = true
    print(("^3[%s] notify: %s^7"):format(GetCurrentResourceName(), message))
end

---------------------------------------------------------------------
-- Public API
---------------------------------------------------------------------

-- Sends a notification through the configured system.
-- Returns true if handled externally, false if the caller should show the
-- built-in toast instead.
function NotifyBridge.Send(message, notifyType, title)
    local handler = resolveProvider()

    if not handler then
        local system = configuredSystem()
        if system ~= "builtin" and system ~= "none" and system ~= "auto" and system ~= "" then
            warnOnce(system, ('"%s" is not running (or unknown) — using the built-in toasts'):format(system))
        end
        return false
    end

    local notifyConfig = Config.Notify or {}
    local duration = math.floor(tonumber(notifyConfig.duration) or 5000)

    if not title then
        title = notifyConfig.title or _U("title")
    end

    if not notifyType or (notifyType ~= "success" and notifyType ~= "error" and notifyType ~= "warning") then
        notifyType = "info"
    end

    local ok, err

    if handler == "custom" then
        if type(notifyConfig.custom) ~= "function" then
            warnOnce("custom", 'system = "custom" but Config.Notify.custom is not a function')
            return false
        end
        ok, err = pcall(notifyConfig.custom, message, notifyType, title, duration)

    elseif handler == "event" then
        if type(notifyConfig.event) ~= "string" or notifyConfig.event == "" then
            warnOnce("event", 'system = "event" but Config.Notify.event is empty')
            return false
        end
        ok, err = pcall(TriggerEvent, notifyConfig.event, message, notifyType, title, duration)

    else
        ok, err = pcall(handler.send, message, notifyType, title, duration)
    end

    if not ok then
        local name = type(handler) == "table" and handler.id or handler
        warnOnce(name .. ":err", ("%s failed (%s) — using the built-in toasts"):format(name, tostring(err)))
        return false
    end

    return true
end

-- Lists the supported provider ids.
function NotifyBridge.Systems()
    local ids = {}
    for _, provider in ipairs(providers) do
        ids[#ids + 1] = provider.id
    end
    return ids
end

