-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
local notify = {}

setmetatable(notify, {
    __call = function(_, source, params)
        TriggerClientEvent('wasabi_multichar:notify', source, params)
    end
})

Modules.register('notify', notify)
