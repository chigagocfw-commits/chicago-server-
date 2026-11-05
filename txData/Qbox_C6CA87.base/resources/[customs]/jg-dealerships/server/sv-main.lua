Utils = Utils or {}
Utils.Server = Utils.Server or {}

math.randomseed(os.time())

function Utils.Server.GenerateUuid()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"

  return template:gsub("[xy]", function(character)
    local value = character == "x" and math.random(0, 15) or math.random(8, 11)
    return ("%x"):format(value)
  end)
end

function Utils.Server.GetNearbyPlayers(playerSource, coords, distance, includeSelf)
  local nearbyPlayers = lib.getNearbyPlayers(coords, distance)
  local players = {}

  for _, nearbyPlayer in ipairs(nearbyPlayers) do
    if includeSelf or nearbyPlayer.id ~= playerSource then
      local playerId = nearbyPlayer.id
      local playerInfo = Framework.Server.GetPlayerInfo(playerId)

      players[#players + 1] = {
        id = playerId,
        identifier = Framework.Server.GetPlayerIdentifier(playerId),
        name = playerInfo and playerInfo.name,
        isSelf = playerId == playerSource,
      }
    end
  end

  DebugPrint(("Found %s nearby players"):format(#players), "debug", players)
  return players
end

lib.callback.register("jg-dealerships:server:get-nearby-players", function(playerSource, dealershipId, includeSelf)
  local playerCoords = GetEntityCoords(GetPlayerPed(playerSource))
  local nearbyPlayers = Utils.Server.GetNearbyPlayers(playerSource, playerCoords, 10.0, includeSelf or false)

  if dealershipId and Framework.Server.IsAdmin(playerSource) then
    local playerIdentifier = Framework.Server.GetPlayerIdentifier(playerSource)
    local employee = MySQL.single.await(
      "SELECT identifier FROM dealership_employees WHERE identifier = ? AND dealership = ?",
      { playerIdentifier, dealershipId }
    )

    if not employee then
      local playerInfo = Framework.Server.GetPlayerInfo(playerSource)

      table.insert(nearbyPlayers, 1, {
        id = playerSource,
        identifier = playerIdentifier,
        name = playerInfo and playerInfo.name or "Unknown",
        isSelf = true,
      })
    end
  end

  return nearbyPlayers
end)

RegisterNetEvent("jg-dealerships:server:notify-other-player", function(targetPlayer, ...)
  TriggerClientEvent("jg-dealerships:client:notify", targetPlayer, ...)
end)

AddEventHandler("onResourceStart", function(resourceName)
  if GetCurrentResourceName() ~= resourceName then return end
  InitSQL()
end)
