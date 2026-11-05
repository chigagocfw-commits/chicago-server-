-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
local notify = {}
local _clientNonce = "c75e2cbced08e99c33646c483421cebc"

local notificationSystem = "ox_lib"

-- Use an ordered array for lookup priority AND provide a map for lookup
local notificationPriority = {
    "wasabi_notify",
    "wasabi_uikit",
    "lation_ui",
    "ox_lib"
}

local notificationSystems = {
    -- Get wasabi_notify here: https://wasabiscripts.com/product/6215100
    ["wasabi_notify"] = function(params)
        if params.style == "inform" or params.style == "primary" then
            params.type = "info"
        end
        return exports.wasabi_notify:notify(params.title, params.description, 3500, params.type, false, nil, nil)
    end,

    -- Get wasabi_uikit here: https://www.wasabiscripts.com/product/7037645
    ["wasabi_uikit"] = function(params)
        if params.style == "inform" or params.style == "primary" then
            params.type = "info"
        end
        return exports.wasabi_uikit:Notification(params.title, params.description, params.type, nil, nil)
    end,

    -- Get lation_ui here: https://lationscripts.com/product/modern-ui
    ['lation_ui'] = function(params)
        return exports.lation_ui:notify({
            title = params.title,
            message = params.description,
            id = nil,
            position = 'top-right',
            icon = nil,
            duration = 3500,
            type = params.style
        })
    end,

    -- Default notification system
    ["ox_lib"] = function(params)
        return lib.notify({
            title = params.title,
            description = params.description,
            type = params.type
        })
    end,
}

RegisterNetEvent('wasabi_multichar:notify', function(params)
    -- Fallback in case the chosen system isn't available
    if not notificationSystems[notificationSystem] then
        notificationSystem = 'ox_lib'
    end
    notificationSystems[notificationSystem](params)
end)

CreateThread(function()
    for _, resourceName in ipairs(notificationPriority) do
        if GetResourceState(resourceName):find('start') then
            lib.print.debug('[notify] Using notification system:', resourceName)
            notificationSystem = resourceName
            break
        end
    end
end)

setmetatable(notify, {
    __call = function(_, params)
        if not notificationSystems[notificationSystem] then
            notificationSystem = 'ox_lib'
        end
        return notificationSystems[notificationSystem](params)
    end
})

Modules.register('notify', notify)
