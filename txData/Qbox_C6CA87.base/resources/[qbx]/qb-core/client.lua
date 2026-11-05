local core

local function getCore()
    if not core then
        while GetResourceState('qbx_core') ~= 'started' do
            Wait(50)
        end
        while not exports.qbx_core or not exports.qbx_core.GetCoreObject do
            Wait(50)
        end
        core = exports.qbx_core:GetCoreObject()
    end
    return core
end

exports('GetCoreObject', function()
    return getCore()
end)

exports('GetUtils', function()
    local core = getCore()
    return core and core.Shared
end)

RegisterNetEvent('QBCore:GetObject', function(cb)
    if type(cb) == 'function' then
        cb(getCore())
    end
end)

RegisterNetEvent('QBCore:Client:GetCoreObject', function(cb)
    if type(cb) == 'function' then
        cb(getCore())
    end
end)
