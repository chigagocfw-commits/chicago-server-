



eventName     = "bablo-animations:"
Locales       = {}
animationList = {}

-- Verify the resource is running under the correct name
if "bablo-animations" ~= GetCurrentResourceName() then
  error("Resource name must be 'bablo-animations'")
  return
end

-- Initialise Main on resource start
Citizen.CreateThread(function()
  Main:Init()
end)

-- ─── SERVER CALLBACK: server:getConvars ──────────────────────────────────────
-- Returns a sanitised server name (alphanumeric only) for use by clients.

RegisterServerCallback({
  eventName = eventName .. "server:getConvars",
  eventCallback = function(source)
    local rawName    = GetConvar("sv_hostname", "unknown")
    local serverName = rawName:gsub("[^%w]", ""):gsub("%s+", "")
    return { status = true, serverName = serverName }
  end
})

-- ─── SERVER CALLBACK: server:requestAnimation ────────────────────────────────
-- Relays an animation request from the requester to the target client and
-- waits for their accept/deny response before returning a result.

RegisterServerCallback({
  eventName = eventName .. "server:requestAnimation",
  eventCallback = function(source, data)
    if not data.target then
      return { status = false, message = "Target not found" }
    end

    -- Use the accepter-specific animation data if provided, otherwise fall back
    local animData = (data.animation.accepter and data.animation.accepter) or data.animation

    local cbResult = TriggerClientCallback({
      source    = data.target,
      eventName = eventName .. "client:requestAnimation",
      args      = { { requester = source, animation = animData } },
    })

    Trace("Requesting callback:", json.encode(cbResult))

    if cbResult.status then
      Main:addPendingRequest(source, data.target, data.animation.name)
      return { status = true, message = "Animation requested" }
    else
      return { status = false, message = "Animation request failed" }
    end
  end
})

-- ─── SERVER CALLBACK: server:getGroupData ────────────────────────────────────
-- Returns the caller's current group, nearby players, and player info.

RegisterServerCallback({
  eventName = eventName .. "server:getGroupData",
  eventCallback = function(source, data)
    local playerPed = GetPlayerPed(source)
    if not playerPed then
      return { status = false, message = "PlayerPed not found" }
    end

    local currentGroup, inGroup = Main:getGroup(source)
    local closestPlayers        = Main:getClosestPlayers(source, currentGroup)

    return {
      status         = true,
      currentGroup   = currentGroup,
      closestPlayers = closestPlayers,
      player         = {
        id      = source,
        name    = Framework:getPlayerName(source),
        inGroup = inGroup,
      },
    }
  end
})

-- ─── SERVER CALLBACK: server:invitePlayer ────────────────────────────────────
-- Sends a group-join request to the target client on behalf of the caller.

RegisterServerCallback({
  eventName = eventName .. "server:invitePlayer",
  eventCallback = function(source, data)
    if not data.target then
      return { status = false, message = "Target not found" }
    end

    local cbResult = TriggerClientCallback({
      source    = data.target,
      eventName = eventName .. "client:requestJoinGroup",
      args      = { { requester = source, groupName = Framework:getPlayerName(source) } },
    })

    Trace("Requesting callback:", json.encode(cbResult))

    if cbResult.status then
      return { status = true, message = "Group request sent" }
    else
      return { status = false, message = "Group request failed" }
    end
  end
})

-- ─── SERVER EVENT: server:syncAnimation ──────────────────────────────────────
-- Validates and relays a synced animation between two players.
-- Blocked if either player ID is invalid, they are too far apart (> 3 m),
-- or there is no accepted pending request between them.

RegisterServerEvent(eventName .. "server:syncAnimation")
AddEventHandler(eventName .. "server:syncAnimation", function(targetId, animData)
  -- Both source and target must be valid online players
  if not (Main:isValidPlayer(source) and Main:isValidPlayer(targetId)) then
    return
  end

  -- Rate-limit repeated sync requests from this source
  if not Main:checkSyncCooldown(source) then return end

  -- Proximity check: players must be within 3 m of each other
  local srcCoords    = GetEntityCoords(GetPlayerPed(source))
  local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
  if #(srcCoords - targetCoords) > 3.0 then return end

  -- Resolve animation name (may be nil for skip-request flows)
  local animName = animData and animData.name or nil

  -- Validate against pending requests; also allow if the animation can skip requests
  local hasRequest = Main:validateAndConsumeRequest(source, targetId, animName)
  local canSkip    = animName and Main:canSkipRequest(animName)

  if not hasRequest and not canSkip then
    Trace("[EXPLOIT BLOCKED] syncAnimation from " .. tostring(source) ..
          " to " .. tostring(targetId) .. " - no valid request")
    return
  end

  -- Fire synced animation to both players
  TriggerClientEvent(eventName .. "client:playSynced", source,   targetId, animData.accepter)
  TriggerClientEvent(eventName .. "client:playSynced", targetId, source,   animData.requester, true)
end)

-- ─── SERVER EVENT: server:syncConvertedAnimation ─────────────────────────────
-- Validates and relays a converted (emote-wheel) synced animation.

RegisterServerEvent(eventName .. "server:syncConvertedAnimation")
AddEventHandler(eventName .. "server:syncConvertedAnimation", function(targetId, animName, partnerAnimName)
  if not (Main:isValidPlayer(source) and Main:isValidPlayer(targetId)) then
    return
  end

  if not Main:checkSyncCooldown(source) then return end

  local srcCoords    = GetEntityCoords(GetPlayerPed(source))
  local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
  if #(srcCoords - targetCoords) > 3.0 then return end

  local hasRequest = Main:validateAndConsumeRequest(source, targetId, animName)
  local canSkip    = animName and Main:canSkipRequest(animName)

  if not hasRequest and not canSkip then
    Trace("[EXPLOIT BLOCKED] syncConvertedAnimation from " .. tostring(source) ..
          " to " .. tostring(targetId) .. " - no valid request")
    return
  end

  -- Target plays the animation; source plays the source-side version
  TriggerClientEvent(eventName .. "client:playConvertedSynced",       source,   animName,        targetId)
  TriggerClientEvent(eventName .. "client:playConvertedSyncedSource", targetId, source,          animName, partnerAnimName)
end)

-- ─── SERVER EVENT: server:syncCancelEmote ────────────────────────────────────
-- Tells a target client to cancel the synced emote when the caller stops theirs.
-- Blocked if either player is invalid or they are more than 5 m apart.

RegisterServerEvent(eventName .. "server:syncCancelEmote")
AddEventHandler(eventName .. "server:syncCancelEmote", function(targetId)
  if not (Main:isValidPlayer(source) and Main:isValidPlayer(targetId)) then
    return
  end

  local srcCoords    = GetEntityCoords(GetPlayerPed(source))
  local targetCoords = GetEntityCoords(GetPlayerPed(targetId))
  if #(srcCoords - targetCoords) > 5.0 then return end

  TriggerClientEvent(eventName .. "client:syncCancelEmote", targetId, source)
end)

-- ─── SERVER EVENT: server:setPlayerStateBag ──────────────────────────────────
-- Allows clients to write a whitelisted key into their own player state bag.

RegisterServerEvent(eventName .. "server:setPlayerStateBag")
AddEventHandler(eventName .. "server:setPlayerStateBag", function(key, value)
  -- Only these keys may be written by the client
  local allowedKeys = { isInAnimation = true, animRot = true }
  if not allowedKeys[key] then return end

  Player(source).state[key] = value
end)

-- ─── SERVER EVENT: server:setGroup ───────────────────────────────────────────
-- Adds the target player to the caller's animation group if both are within
-- Config.GroupMaxDistance of each other.

RegisterServerEvent(eventName .. "server:setGroup")
AddEventHandler(eventName .. "server:setGroup", function(targetId)
  local srcCoords    = GetEntityCoords(GetPlayerPed(source))
  local targetCoords = GetEntityCoords(GetPlayerPed(targetId))

  if #(srcCoords - targetCoords) > Config.GroupMaxDistance then return end

  local success = Main:setPlayerGroup(source, targetId)
  if success then
    -- Notify the target that they joined the group
    TriggerClientEvent(eventName .. "client:notify", targetId,
      Translate("GROUP_JOINED", { Framework:getPlayerName(source) })
    )
    -- Notify the caller that the target joined
    TriggerClientEvent(eventName .. "client:notify", source,
      Translate("PLAYER_JOINED", { Framework:getPlayerName(targetId) })
    )
  end
end)

-- ─── SERVER EVENT: server:leaveGroup ─────────────────────────────────────────
-- Removes a player from a group, dissolving the group if only one member remains.

RegisterServerEvent(eventName .. "server:leaveGroup")
AddEventHandler(eventName .. "server:leaveGroup", function(groupId, leavingPlayerId)
  if not groupId then return end

  local group = Main.Groups[groupId]
  if group then
    for i, member in pairs(group) do
      -- Match by numeric ID or string representation
      if member.id == leavingPlayerId or tostring(member.id) == tostring(leavingPlayerId) then
        table.remove(Main.Groups[groupId], i)

        -- If only one member remains, dissolve the group entirely
        if #Main.Groups[groupId] == 1 then
          Main.Groups[groupId] = nil
          TriggerClientEvent(eventName .. "client:leaveGroup", groupId)
        end

        -- Notify remaining group members
        TriggerClientEvent(eventName .. "client:notify", groupId,
          Translate("PLAYER_LEFT_GROUP", { Framework:getPlayerName(leavingPlayerId) })
        )

        -- Notify the leaving player
        TriggerClientEvent(eventName .. "client:leaveGroup", leavingPlayerId)
        sendWebhook(leavingPlayerId, "LEFT_GROUP", groupId)
        return
      end
    end
  end

  -- Player was not found in the group — still notify them they left
  TriggerClientEvent(eventName .. "client:notify", leavingPlayerId, Translate("GROUP_LEFT"))
end)

-- ─── SERVER EVENT: server:playGroupedAnimation ───────────────────────────────
-- Broadcasts an animation to every member of the caller's group.

RegisterServerEvent(eventName .. "server:playGroupedAnimation")
AddEventHandler(eventName .. "server:playGroupedAnimation", function(animData)
  local group = Main.Groups[source]
  if not group then return end

  for _, member in pairs(group) do
    TriggerClientEvent(eventName .. "client:playAnimation", member.id, nil, animData, true)
  end
end)

-- ─── SERVER EVENT: server:cancelGroupedAnimation ─────────────────────────────
-- Tells every other member of the caller's group to stop their animation.

RegisterServerEvent(eventName .. "server:cancelGroupedAnimation")
AddEventHandler(eventName .. "server:cancelGroupedAnimation", function()
  local group = Main.Groups[source]
  if not group then return end

  for _, member in pairs(group) do
    if member.id ~= source then
      TriggerClientEvent(eventName .. "client:forceStopGroupAnimation", member.id)
    end
  end
end)

-- ─── NET EVENT: ptfx:sync ────────────────────────────────────────────────────
-- Writes particle-effect parameters into the caller's player state bag so that
-- nearby clients can render the effect. Validates all arguments before writing.

RegisterNetEvent(eventName .. "ptfx:sync")
AddEventHandler(eventName .. "ptfx:sync", function(asset, name, offset, rotation, bone, scale, color)
  -- Type validation
  if type(asset)    ~= "string"  then return end
  if type(name)     ~= "string"  then return end
  if type(offset)   ~= "vector3" then return end
  if type(rotation) ~= "vector3" then return end

  -- String length guard
  if #asset > 100 or #name > 100 then return end

  -- Optional numeric parameters
  if bone  ~= nil and type(bone)  ~= "number" then return end
  if scale ~= nil and type(scale) ~= "number" then return end

  local playerState = Player(source).state
  playerState:set(eventName .. "ptfxAsset",   asset,    true)
  playerState:set(eventName .. "ptfxName",    name,     true)
  playerState:set(eventName .. "ptfxOffset",  offset,   true)
  playerState:set(eventName .. "ptfxRot",     rotation, true)
  playerState:set(eventName .. "ptfxBone",    bone,     true)
  playerState:set(eventName .. "ptfxScale",   scale,    true)
  playerState:set(eventName .. "ptfxColor",   color,    true)
  playerState:set(eventName .. "ptfxPropNet", false,    true)
end)

-- ─── NET EVENT: ptfx:syncProp ─────────────────────────────────────────────────
-- Resolves a networked prop entity and writes its net ID into the state bag
-- so clients know which prop is emitting the particle effect.

RegisterNetEvent(eventName .. "ptfx:syncProp")
AddEventHandler(eventName .. "ptfx:syncProp", function(netId)
  if netId ~= nil and type(netId) ~= "number" then return end

  local playerState = Player(source).state

  if netId then
    -- Poll until the entity exists (up to 100 × 10 ms = 1 s)
    local attempts  = 0
    local propEntity

    while attempts <= 100 do
      propEntity = NetworkGetEntityFromNetworkId(netId)
      if DoesEntityExist(propEntity) then break end
      Wait(10)
      attempts = attempts + 1
    end

    if attempts < 100 then
      -- Entity found — write net ID into state bag
      playerState:set(eventName .. "ptfxPropNet", netId, true)
      return
    end
  end

  -- No valid net ID or entity not found — clear the state bag entry
  playerState:set(eventName .. "ptfxPropNet", false, true)
end)

-- ─── NET EVENT: ptfx:clear ───────────────────────────────────────────────────
-- Clears all particle-effect state bag entries for the calling player.

RegisterNetEvent(eventName .. "ptfx:clear")
AddEventHandler(eventName .. "ptfx:clear", function()
  local playerState = Player(source).state
  playerState:set(eventName .. "ptfxAsset",   nil,  true)
  playerState:set(eventName .. "ptfxName",    nil,  true)
  playerState:set(eventName .. "ptfxOffset",  nil,  true)
  playerState:set(eventName .. "ptfxRot",     nil,  true)
  playerState:set(eventName .. "ptfxBone",    nil,  true)
  playerState:set(eventName .. "ptfxScale",   nil,  true)
  playerState:set(eventName .. "ptfxColor",   nil,  true)
  playerState:set(eventName .. "ptfxPropNet", nil,  true)
end)

-- ─── NET EVENT: server:syncAnimpos ───────────────────────────────────────────
-- Broadcasts an animation position update (coords + heading) to all clients.

RegisterNetEvent(eventName .. "server:syncAnimpos")
AddEventHandler(eventName .. "server:syncAnimpos", function(coords, heading, pitch, roll)
  if type(coords)  ~= "vector3" then return end
  if type(heading) ~= "number"  then return end
  if type(pitch)   ~= "number"  then return end
  if type(roll)    ~= "number"  then return end

  TriggerClientEvent(eventName .. "client:syncAnimpos", -1, source, coords, heading, pitch, roll)
end)

-- ─── NET EVENT: server:addProp ────────────────────────────────────────────────
-- Server-side prop spawn: creates a networked object near the player's ped,
-- attaches its net ID + bone/offset/rotation data to the player's state bag,
-- and enforces per-player rate limiting and a max-prop cap.
--
-- Parameters: modelName, bone, off1, off2, off3, rot1, rot2, rot3

local propSpawnLastTime = {}   -- [source] = lastSpawnTimestamp
local PROP_SPAWN_COOLDOWN_MS = 500
local PROP_MAX_PER_PLAYER    = 4

RegisterNetEvent(eventName .. "server:addProp")
AddEventHandler(eventName .. "server:addProp", function(modelName, bone, off1, off2, off3, rot1, rot2, rot3)
  if not Config.ServerSideSpawn then return end

  -- Validate calling player has a live ped
  local playerPed = GetPlayerPed(source)
  if not DoesEntityExist(playerPed) then return end

  -- Validate modelName: must be a non-empty string under 100 chars
  if type(modelName) ~= "string" or #modelName == 0 or #modelName > 100 then return end

  -- Validate all numeric parameters
  if type(bone) ~= "number" then return end
  if type(off1) ~= "number" or type(off2) ~= "number" or type(off3) ~= "number" then return end
  if type(rot1) ~= "number" or type(rot2) ~= "number" or type(rot3) ~= "number" then return end

  -- Per-player rate limiting
  local now = GetGameTimer()
  if propSpawnLastTime[source] and (now - propSpawnLastTime[source]) < PROP_SPAWN_COOLDOWN_MS then
    return
  end
  propSpawnLastTime[source] = now

  -- Cap the number of active props per player
  local playerState = Player(source).state
  local propList    = playerState.animProps or {}
  if #propList >= PROP_MAX_PER_PLAYER then return end

  -- Spawn the object slightly below the ped (z - 5) to avoid physics conflicts
  local modelHash = GetHashKey(modelName)
  local coords    = GetEntityCoords(playerPed)
  local propEntity = CreateObject(modelHash, coords.x, coords.y, coords.z - 5.0, true, true, true)

  -- Wait up to 100 × 10 ms for the entity to exist
  local attempts = 0
  while not DoesEntityExist(propEntity) and attempts < 100 do
    Wait(10)
    attempts = attempts + 1
  end

  if not DoesEntityExist(propEntity) then
    Trace("[bablo-animations] CreateObject failed",
          tostring(modelName), tostring(modelHash), coords.x, coords.y, coords.z)
    return
  end

  -- Add the prop to the player's state bag
  local netId = NetworkGetNetworkIdFromEntity(propEntity)
  table.insert(propList, {
    netId = netId,
    bone  = bone,
    off1  = off1, off2 = off2, off3 = off3,
    rot1  = rot1, rot2 = rot2, rot3 = rot3,
  })

  playerState:set("animProps", propList, true)
  Trace("[bablo-animations] addProp", source, tostring(netId), #propList)
end)

-- ─── NET EVENT: server:destroyProps ──────────────────────────────────────────
-- Deletes all networked props in the calling player's state bag.

RegisterNetEvent(eventName .. "server:destroyProps")
AddEventHandler(eventName .. "server:destroyProps", function()
  local playerState = Player(source).state
  local propList    = playerState.animProps or {}

  -- Iterate in reverse so table.remove indices stay valid
  for i = #propList, 1, -1 do
    local entry = propList[i]
    local netId = (type(entry) == "table" and entry.netId) or entry
    local entity = NetworkGetEntityFromNetworkId(netId)

    if DoesEntityExist(entity) then
      DeleteEntity(entity)
    end

    table.remove(propList, i)
  end

  playerState:set("animProps", propList, true)
  Trace("[bablo-animations] destroyProps", source)
end)

-- ─── EXPORT: cancelAnimation ─────────────────────────────────────────────────
exports("cancelAnimation", function(playerId)
  TriggerClientEvent(eventName .. "client:cancelAnimation", playerId)
end)

-- ─── EXPORT: playAnimation ───────────────────────────────────────────────────
exports("playAnimation", function(playerId, animData)
  TriggerClientEvent(eventName .. "client:playAnimation", playerId, nil, animData)
end)

-- ─── EXPORT: getAnimations ───────────────────────────────────────────────────
exports("getAnimations", function()
  return animationList
end)

-- ─── EXPORT: getAnimation ────────────────────────────────────────────────────
exports("getAnimation", function(animName)
  return Main:getAnimation(animName)
end)

-- ─── COMMAND: Config.EmoteCreatorCommand ─────────────────────────────────────
-- Opens the emote creator UI for admins.

if Config.EmoteCreatorCommand then
  RegisterCommand(Config.EmoteCreatorCommand, function(source, args, rawCmd)
    -- Block server console calls
    if source == 0 then return end

    -- Check admin permission through the framework (if available)
    local isAdmin = Framework and Framework.isAdmin and Framework:isAdmin(source)

    if not isAdmin then
      TriggerClientEvent(eventName .. "client:notify", source,
        "You do not have permission to use this command.")
      return
    end

    TriggerClientEvent(eventName .. "client:openEmoteCreator", source)
  end, false)
end

-- ─── EVENT: onResourceStop ───────────────────────────────────────────────────
-- Sets a global state flag so clients know the resource was restarted.

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end
  GlobalState.babloAnimationsRestarted = true
end)

-- ─── EVENT: onResourceStart ──────────────────────────────────────────────────
-- If the resource was previously stopped and restarted, force all connected
-- clients to reload their animation state.

AddEventHandler("onResourceStart", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end

  Citizen.Wait(2000)
  Trace("onResourceStart babloAnimationsRestarted: ", GlobalState.babloAnimationsRestarted)

  if GlobalState.babloAnimationsRestarted then
    TriggerClientEvent(eventName .. "client:forceLoad", -1)
    GlobalState.babloAnimationsRestarted = false
  end
end)