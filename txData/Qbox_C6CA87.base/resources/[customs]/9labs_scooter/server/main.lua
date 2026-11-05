local playerIkStates = {}

RegisterNetEvent("9labs_scooter:server:syncHandIk", function(enabled, flags)
    local src = source
    playerIkStates[src] = {
        enabled = enabled ~= false,
        flags = flags or 4
    }
    Player(src).state:set("labscoot_handik", playerIkStates[src], true)
end)

AddEventHandler("playerDropped", function()
    local src = source
    playerIkStates[src] = nil
end)

exports("GetPlayerHandIk", function(source)
    return playerIkStates[source] or { enabled = true, flags = 4 }
end)

exports("SetPlayerHandIk", function(source, enabled, flags)
    playerIkStates[source] = {
        enabled = enabled ~= false,
        flags = flags or 4
    }
    Player(source).state:set("labscoot_handik", playerIkStates[source], true)
    TriggerClientEvent("9labs_scooter:client:setHandIk", source, enabled, flags)
end)
