--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]


function GetConfigFile(filename)
    return LoadResourceFile(GetCurrentResourceName(), "config/" .. filename)
end

local _nearbyPlayers = {}
local _lastPlayerPos = vector3(0.0, 0.0, 0.0)
local _lastCacheTime = 0

local function _RebuildNearbyPlayers()
    local myCoords   = GetEntityCoords(PlayerPedId())
    local allPlayers = GetActivePlayers()
    local result     = {}

    for i = 1, #allPlayers do
        local player = allPlayers[i]

        if player ~= PlayerId() then
            local ped    = GetPlayerPed(player)
            local coords = GetEntityCoords(ped)
            local dist   = #(myCoords - coords)

            if dist <= 50.0 then
                result[#result + 1] = {
                    player = player,
                    source = GetPlayerServerId(player),
                    ped    = ped,
                    coords = coords,
                }
            end
        end
    end

    _nearbyPlayers = result
end

function GetNearbyPlayers()
    local now     = GetGameTimer()
    local elapsed = now - _lastCacheTime
    local pos     = GetEntityCoords(PlayerPedId())
    local moved   = #(pos - _lastPlayerPos)

    if elapsed > 5000 or moved > 25.0 then
        _lastCacheTime = now
        _lastPlayerPos = pos
        _RebuildNearbyPlayers()
    end

    return _nearbyPlayers
end

