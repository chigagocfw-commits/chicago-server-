
if Config.Framework ~= "qbox" then return end

function SendNotification(message)
    local success = pcall(function()
        exports.qbx_core:Notify(message)
    end)
    if not success then
        success = pcall(function()
            TriggerEvent('ox_lib:notify', {
                title = 'ATM',
                description = message,
                type = 'inform'
            })
        end)
    end
    if not success then
        pcall(function()
            TriggerEvent('QBCore:Notify', message)
        end)
    end
end
