-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if not GetResourceState('es_extended'):find('start') then return end

local bridge = {}

bridge.framework = 'esx'

---Trigger ESX framework events after the player spawns
function bridge.onPlayerLoaded()
    TriggerEvent('esx:onPlayerSpawn')
    TriggerServerEvent('esx:onPlayerSpawn')
end

Modules.register('bridge', bridge)
