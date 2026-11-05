-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if GetResourceState('qb-core'):find('start') or GetResourceState('qbx_core'):find('start') or GetResourceState('es_extended'):find('start') then return end

local bridge = {}

---Trigger framework events after the player spawns — implement for your framework
function bridge.onPlayerLoaded()
    -- Add your custom framework's player loaded events here
end

Modules.register('bridge', bridge)
