local function getCore()
    return exports.qbx_core:GetCoreObject()
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

RegisterNetEvent('QBCore:Server:GetCoreObject', function(cb)
    if type(cb) == 'function' then
        cb(getCore())
    end
end)
