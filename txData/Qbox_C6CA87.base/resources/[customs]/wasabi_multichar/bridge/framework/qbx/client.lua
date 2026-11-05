-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global
if not GetResourceState('qbx_core'):find('start') then return end

local bridge = {}

bridge.framework = 'qbx'

---Trigger QBX framework events after the player spawns
function bridge.onPlayerLoaded()
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
end

Modules.register('bridge', bridge)
