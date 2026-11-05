-- Police Radio System Integration

-- Add Player to Multi-Frequency
RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", function(playerId, frequency, data)
  SendNUIMessage({
    radioMenu = "AddPlayerMultiFrec",
    id = playerId,
    frec = frequency,
    data = data,
    i = playerId == GetPlayerServerId(PlayerId()) -- Is this the local player?
  })
end)

-- Player Disconnected from Radio
RegisterNetEvent("origen_police:client:Disconnected", function()
  SendNUIMessage({
    radioMenu = "Disconnected"
  })
end)

-- Player Talking Status Update
RegisterNetEvent("origen_police:client:talking", function(targetId, isTalking)
  SendNUIMessage({
    radioMenu = "Talking",
    target = targetId,
    value = isTalking
  })
end)

-- Remove Player from Multi-Frequency
RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", function(playerId, frequency)
  SendNUIMessage({
    radioMenu = "RemovePlayerMultiFrec",
    id = playerId,
    frec = frequency
  })
end)

-- Set Player Muted Status
RegisterNetEvent("origen_police:client:SetMuted", function(playerId, isMuted)
  SendNUIMessage({
    radioMenu = "SetMuted",
    id = playerId,
    value = isMuted
  })
end)

-- Set Player Ready Status
RegisterNetEvent("origen_police:client:SetReady", function(playerId, isReady)
  SendNUIMessage({
    radioMenu = "SetReady",
    id = playerId,
    value = isReady
  })
end)

-- Load Frequency List
RegisterNUICallback("LoadFrecList", function(data, cb)
  local result = {
    freq = exports.origen_police:GetPoliceRadioChannels(),
    buttons = exports.origen_police:GetPoliceRadioButtons()
  }
  
  cb(result)
end)

-- Load Radio Key Binds
RegisterNUICallback("LoadRadioBinds", function(data, cb)
  local result = {
    binds = exports.origen_police:GetPoliceRadioBinds()
  }
  
  cb(result)
end)