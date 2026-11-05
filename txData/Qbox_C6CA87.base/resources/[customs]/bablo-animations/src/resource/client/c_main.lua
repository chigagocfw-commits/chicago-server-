



eventName = "bablo-animations:"
Locales  = {}

-- Verify the resource is running under the correct name
if "bablo-animations" ~= GetCurrentResourceName() then
  error("Resource name must be 'bablo-animations'")
  return
end

-- ─── CLIENT CALLBACK: client:requestAnimation ────────────────────────────────
-- Asks the local player to accept or deny an incoming shared-animation request.

RegisterClientCallback({
  eventName = eventName .. "client:requestAnimation",
  eventCallback = function(animData)
    local done   = false
    local result = { status = false, message = "Animation request failed" }

    Trace("Requesting animation:", json.encode(animData, { indent = true }))

    -- Framework permission checks
    if not Framework:canPlayAnimation(animData.animation.name) then
      return result
    end
    if not Framework:canAcceptAnimationRequest(animData.animation.name) then
      return result
    end

    -- Prompt thread: show accept/deny UI and wait for player input
    Citizen.CreateThread(function()
      local startTime = GetGameTimer()

      if not animData.animation.skip then
        ShowQuestion(Translate("REQUEST_SHARED_ANIMATION", { animData.animation.label }))
      end

      -- 10-second input window
      while GetGameTimer() < startTime + 10000 do
        SetPauseMenuActive(false)

        -- Control 38 = ENTER (accept)
        if IsControlJustReleased(0, 38) or IsDisabledControlJustReleased(0, 38) then
          result = { status = true, message = "Animation accepted" }
          break
        end

        -- Control 47 = BACKSPACE (deny)
        if IsControlJustReleased(0, 47) or IsDisabledControlJustReleased(0, 47) then
          result = { status = false, message = "Animation denied" }
          break
        end

        Citizen.Wait(0)
      end

      SetPauseMenuActive(true)

      if not animData.animation.skip then
        HideQuestion()
      end

      done = true
    end)

    -- Block the callback until the prompt thread resolves
    while not done do
      Citizen.Wait(0)
    end

    Trace("Returning data:", json.encode(result))
    return result
  end
})

-- ─── CLIENT CALLBACK: client:requestJoinGroup ────────────────────────────────
-- Asks the local player to accept or deny a group-join request.

RegisterClientCallback({
  eventName = eventName .. "client:requestJoinGroup",
  eventCallback = function(groupData)
    local done   = false
    local result = { status = false, message = "Group request failed" }

    Citizen.CreateThread(function()
      local startTime = GetGameTimer()

      ShowQuestion(Translate("JOIN_GROUP_TEXT") .. groupData.groupName)

      -- 10-second input window
      while GetGameTimer() < startTime + 10000 do
        SetPauseMenuActive(false)

        -- Control 38 = ENTER (accept)
        if IsControlJustReleased(0, 38) or IsDisabledControlJustReleased(0, 38) then
          result = { status = true, message = "Group request accepted" }

          -- Optionally fire a webhook log
          if Config.Logs then
            TriggerServerEvent(eventName .. "server:sendWebhook", "JOINED_GROUP", groupData.groupName)
          end

          -- Notify Main of the join in a separate thread to avoid blocking
          Citizen.CreateThread(function()
            Main:onGroupJoin(groupData.requester)
          end)

          break
        end

        -- Control 47 = BACKSPACE (deny)
        if IsControlJustReleased(0, 47) or IsDisabledControlJustReleased(0, 47) then
          result = { status = false, message = "Group request denied" }
          break
        end

        Citizen.Wait(0)
      end

      SetPauseMenuActive(true)
      HideQuestion()
      done = true
    end)

    while not done do
      Citizen.Wait(0)
    end

    Trace("Returning data:", json.encode(result))
    return result
  end
})

-- ─── NET EVENT: client:playSynced ────────────────────────────────────────────
-- Plays a synchronised animation: optionally attaches our ped to a target ped,
-- plays the animation, then detaches after the clip finishes.

RegisterNetEvent(eventName .. "client:playSynced")
AddEventHandler(eventName .. "client:playSynced", function(serverId, animData, flag)
  local targetPed = GetPlayerPed(GetPlayerFromServerId(serverId))

  Trace("Started Sync:", json.encode(animData))

  -- Optionally attach local ped to the target entity
  if animData.attach then
    local a = animData.attach
    AttachEntityToEntity(
      cache.ped, targetPed,
      a.bone,
      a.xPosition, a.yPosition, a.zPosition,
      a.xRotation, a.yRotation, a.zRotation,
      0, 0, 0, 0, 2, 1
    )
  end

  -- Play the animation on the local ped
  Main:startPlayAnimation({
    ped  = cache.ped,
    dict = animData.lib,
    lib  = animData.animation,
    flag = animData.flag or 0,
  })

  -- Detach after animation ends (750 ms early to avoid clipping)
  -- Must run in a thread so Wait() doesn't block the event handler
  local animDuration = GetAnimDuration(animData.lib, animData.animation)
  Citizen.CreateThread(function()
    Citizen.Wait(math.max(0, animDuration * 1000 - 750))
    DetachEntity(cache.ped, true, false)
    ClearPedTasks(cache.ped)
  end)
end)

-- ─── NET EVENT: client:cancelAnimation ───────────────────────────────────────
RegisterNetEvent(eventName .. "client:cancelAnimation")
AddEventHandler(eventName .. "client:cancelAnimation", function(ped)
  Main:cancelEmote(ped or cache.ped)
end)

-- ─── NET EVENT: client:openApp ───────────────────────────────────────────────
RegisterNetEvent(eventName .. "client:openApp")
AddEventHandler(eventName .. "client:openApp", function()
  Main:openApp()
end)

-- ─── NET EVENT: client:notify ────────────────────────────────────────────────
RegisterNetEvent(eventName .. "client:notify")
AddEventHandler(eventName .. "client:notify", function(notifData)
  Framework:Notify(notifData)
end)

-- ─── NET EVENT: client:leaveGroup ────────────────────────────────────────────
RegisterNetEvent(eventName .. "client:leaveGroup")
AddEventHandler(eventName .. "client:leaveGroup", function()
  Main.currentGroup = 0
end)

-- ─── NET EVENT: client:playAnimation ─────────────────────────────────────────
RegisterNetEvent(eventName .. "client:playAnimation")
AddEventHandler(eventName .. "client:playAnimation", function(ped, animData, flag)
  Main:playAnimation(ped or cache.ped, animData, flag)
end)

-- ─── NET EVENT: client:playConvertedSynced ───────────────────────────────────
-- Plays a converted / shared emote on the local ped relative to a target player.

RegisterNetEvent(eventName .. "client:playConvertedSynced")
AddEventHandler(eventName .. "client:playConvertedSynced", function(animName, targetServerId)
  -- Cancel any existing emote before starting the synced one
  Main:cancelEmote(cache.ped, true)
  Wait(100)

  Main.targetPlayerId = targetServerId

  -- Resolve target player; fall back to the closest player if the server ID is invalid
  local targetPlayer = GetPlayerFromServerId(targetServerId)
  if targetPlayer == 0 or not targetPlayer then
    targetPlayer = lib.GetClosestPlayer()
  end
  local targetPed = GetPlayerPed(targetPlayer)

  -- Block if target is inside a vehicle
  if IsPedInAnyVehicle(targetPed, true) then
    Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY_IN_VEHICLE"))
    return
  end

  local sharedAnim = Main.sharedAnimations[animName]
  if sharedAnim then
    local opts = sharedAnim.animationOptions
    if opts and opts.attachTo then
      local partnerKey   = Main.sharedAnimations[animName][4]
      local partnerHasAttach = false

      -- Check whether the partner animation also requests an attachment
      if partnerKey then
        local partnerData = Main.sharedAnimations[partnerKey]
        if partnerData and partnerData.animationOptions and partnerData.animationOptions.attachTo then
          partnerHasAttach = true
        end
      end

      -- Only attach if the partner does NOT also attach (avoids double-attach)
      if not partnerHasAttach then
        AttachEntityToEntity(
          cache.ped, targetPed,
          GetPedBoneIndex(targetPed, opts.bone or -1),
          opts.xPos or 0.0, opts.yPos or 0.0, opts.zPos or 0.0,
          opts.xRot or 0.0, opts.yRot or 0.0, opts.zRot or 0.0,
          false, false, false, true, 1, true
        )
      end
    end

    print(json.encode(Main.sharedAnimations[animName], { indent = true }))
    Main:playEmote(Main.sharedAnimations[animName], false, true)
    return
  end

  Trace("Sycned Emote not found")
end)

-- ─── NET EVENT: client:playConvertedSyncedSource ─────────────────────────────
-- Source-side of a converted synced emote: positions the local ped near the
-- target ped using either entity-attachment or world-offset placement.

RegisterNetEvent(eventName .. "client:playConvertedSyncedSource")
AddEventHandler(eventName .. "client:playConvertedSyncedSource", function(animName, targetServerId, partnerAnimName)
  local myPed = cache.ped

  -- Resolve target player ped; fall back to the closest player
  local targetPlayer = GetPlayerFromServerId(targetServerId)
  if targetPlayer == 0 or not targetPlayer then
    targetPlayer = lib.GetClosestPlayer()
  end
  local targetPed = GetPlayerPed(targetPlayer)

  -- Block if either ped is in a vehicle
  if IsPedInAnyVehicle(myPed, true) or IsPedInAnyVehicle(targetPed, true) then
    Framework:Notify(Translate("NOT_ALLOWED_TO_PLAY_IN_VEHICLE"))
    return
  end

  -- animName    = requester's anim (e.g. "baseball")
  -- partnerAnimName = our own anim  (e.g. "baseballthrow")
  -- targetPed   = requester's ped

  -- Resolve OUR own animation options (from partnerAnimName)
  local myOpts
  if partnerAnimName and Main.sharedAnimations[partnerAnimName] then
    myOpts = Main.sharedAnimations[partnerAnimName].animationOptions
  end

  -- Resolve REQUESTER's animation options as fallback for offsets
  local requesterOpts
  if Main.sharedAnimations[animName] then
    requesterOpts = Main.sharedAnimations[animName].animationOptions
  end

  local isAttached = false
  if myOpts and myOpts.attachTo then
    isAttached = true
    AttachEntityToEntity(
      myPed, targetPed,
      GetPedBoneIndex(targetPed, myOpts.bone or -1),
      myOpts.xPos or 0.0, myOpts.yPos or 0.0, myOpts.zPos or 0.0,
      myOpts.xRot or 0.0, myOpts.yRot or 0.0, myOpts.zRot or 0.0,
      false, false, false, true, 1, true
    )
  end

  -- If not attached, place ped at a world-space offset from the requester
  if not isAttached then
    -- Use our own opts first, fall back to requester's opts
    local opts = myOpts or requesterOpts
    local offsetSide    = (opts and opts.syncOffsetSide)    or 0
    local offsetFront   = (opts and opts.syncOffsetFront)   or 0.5
    local offsetHeight  = (opts and opts.syncOffsetHeight)  or 0
    local offsetHeading = (opts and opts.syncOffsetHeading) or 180

    local worldCoords = GetOffsetFromEntityInWorldCoords(
      targetPed,
      offsetSide   + 0.0,
      offsetFront  + 0.0,
      offsetHeight + 0.0
    )
    local targetHeading = GetEntityHeading(targetPed)

    SetEntityHeading(myPed, targetHeading + offsetHeading)
    SetEntityCoordsNoOffset(myPed, worldCoords.x, worldCoords.y, worldCoords.z)
  end

  Wait(100)
  Main.targetPlayerId = targetServerId

  -- Play the emote if the shared animation still exists
  -- Target plays partnerAnimName (their side), not animName (requester's side)
  local animToPlay = (partnerAnimName and Main.sharedAnimations[partnerAnimName]) and partnerAnimName or animName
  if Main.sharedAnimations[animToPlay] ~= nil then
    Main:playEmote(Main.sharedAnimations[animToPlay], false, true)
    return
  end
end)

-- ─── NET EVENT: client:syncCancelEmote ───────────────────────────────────────
-- Cancels the current synced emote when the target player stops theirs.

RegisterNetEvent(eventName .. "client:syncCancelEmote")
AddEventHandler(eventName .. "client:syncCancelEmote", function(serverId)
  if Main.targetPlayerId and Main.targetPlayerId == serverId then
    Main.targetPlayerId = nil

    if ForceStopAllHearingSounds then
      ForceStopAllHearingSounds()
    end

    Main:cancelEmote(cache.ped, true)

    -- Only detach if the ped is not in a vehicle
    if not IsPedInAnyVehicle(cache.ped, false) then
      DetachEntity(cache.ped, true, false)
    end
  end
end)

-- ─── NET EVENT: client:forceStopGroupAnimation ───────────────────────────────
-- Force-stops the current group animation and cleans up ped state.

RegisterNetEvent(eventName .. "client:forceStopGroupAnimation")
AddEventHandler(eventName .. "client:forceStopGroupAnimation", function()
  if ForceStopAllHearingSounds then
    ForceStopAllHearingSounds()
  end

  Main:cancelEmote(cache.ped, true)

  -- Detach and clear tasks only when not in a vehicle
  if not IsPedInAnyVehicle(cache.ped, false) then
    DetachEntity(cache.ped, true, false)
    ClearPedTasks(cache.ped)
  end
end)

-- ─── STATE BAG: animProps ─────────────────────────────────────────────────────
-- Attaches networked props (via net ID) to the local player's ped whenever the
-- "animProps" state bag changes.

local playerBagName = ("player:%s"):format(GetPlayerServerId(PlayerId()))
AddStateBagChangeHandler("animProps", playerBagName, function(bagName, key, propList, reserved, replicated)
  -- Only process if the value is a table
  if not propList or type(propList) ~= "table" then
    return
  end

  local myPed = cache.ped

  for _, propData in ipairs(propList) do
    if type(propData) == "table" and propData.netId and propData.bone then
      -- Poll until the networked entity exists (up to 200 × 10 ms = 2 s)
      local attempts   = 0
      local propEntity = nil

      while attempts < 200 do
        propEntity = NetworkGetEntityFromNetworkId(propData.netId)
        if DoesEntityExist(propEntity) then break end
        Wait(10)
        attempts = attempts + 1
      end

      if propEntity and DoesEntityExist(propEntity) then
        -- Optionally disable collision between prop and ped
        if Config.DisablePropCollision then
          SetEntityCollision(propEntity, false, false)
          SetEntityNoCollisionEntity(propEntity, myPed, false)
        end

        AttachEntityToEntity(
          propEntity, myPed,
          GetPedBoneIndex(myPed, propData.bone),
          propData.off1, propData.off2, propData.off3,
          propData.rot1, propData.rot2, propData.rot3,
          true, true, false, true, 1, true
        )
      end
    end
  end
end)

-- ─── EVENT: onResourceStop ───────────────────────────────────────────────────
-- Cleans up UI focus, active creators, and ped attachments on resource stop.

AddEventHandler("onResourceStop", function(resourceName)
  if resourceName ~= GetCurrentResourceName() then return end

  -- Stop emote creators if they are active
  if EmoteCreator and EmoteCreator.isActive then
    EmoteCreator:Stop()
  end
  if SoloEmoteCreator and SoloEmoteCreator.isActive then
    SoloEmoteCreator:Stop()
  end

  -- Delete the preview ped handle if one was spawned
  if Main.pedHandle then
    DeleteEntity(Main.pedHandle)
  end

  DetachEntity(cache.ped)
  SetNuiFocus(false, false)
  SetNuiFocusKeepInput(false)
  Main.inAction = false
end)

-- ─── NET EVENT: client:forceLoad ─────────────────────────────────────────────
-- Forces re-initialisation and restores cached style animations after login.

RegisterNetEvent(eventName .. "client:forceLoad")
AddEventHandler(eventName .. "client:forceLoad", function()
  Citizen.Wait(100)

  -- Skip if the framework has no character identifier
  if not (Framework and Framework.getCharacterIdentifier and Framework:getCharacterIdentifier()) then
    return
  end

  -- Wait until the NUI is fully ready
  while not Main.NUIReady do
    Citizen.Wait(100)
  end

  Main:Init()
  Trace("forceLoad: Main:Init")

  Citizen.Wait(2000)

  -- Restore cached walking style, expression, and weapon style
  local cachedData, alreadyLoaded = Main:getCache()
  if not alreadyLoaded then
    Main:playAnimation(cache.ped, cachedData.walkingstyle or nil, false, true)
    Main:playAnimation(cache.ped, cachedData.expression   or nil, false, true)
    Main:playAnimation(cache.ped, cachedData.weaponstyle  or nil, false, true)
  end
end)

-- ─── COMMAND: Config.EmoteCommand ────────────────────────────────────────────
-- In-game chat command to play or cancel an emote by name.

RegisterCommand(Config.EmoteCommand, function(source, args)
  -- Block if the player is dead
  if not Framework:isPlayerDead() then return end

  if args[1] then
    -- Normalise to lowercase
    args[1] = args[1]:lower()

    -- "c" or "cancel" → stop the current emote
    if args[1] == "c" or args[1] == "cancel" then
      Main:cancelEmote(cache.ped)
      return
    end

    -- Otherwise, play the named animation
    Main:playAnimation(cache.ped, args[1])
  end
end)

-- Register chat autocomplete suggestion for the emote command
Citizen.CreateThread(function()
  TriggerEvent("chat:addSuggestion",
    "/" .. Config.EmoteCommand,
    Translate("EMOTE_COMMAND_HELP"),
    {
      { name = Translate("EMOTE_COMMAND_TITLE"), help = Translate("EMOTE_COMMAND_DESC") }
    }
  )

  -- Also register the AnimAdjust command suggestion if configured
  if Config.AnimAdjustCommand then
    TriggerEvent("chat:addSuggestion",
      "/" .. Config.AnimAdjustCommand,
      Translate("ADJUST_COMMAND_HELP"),
      {}
    )
  end
end)

-- ─── COMMAND: clearall_animation_favorites ───────────────────────────────────
-- Clears all favourites for the current player.

RegisterCommand("clearall_animation_favorites", function(source, args)
  for animName, isFav in pairs(Main.favorites) do
    if isFav then
      Main:toggleFavorite(animName)
    end
  end
end)

-- ─── COMMAND: debug_keybinds ─────────────────────────────────────────────────
-- Prints the current animation keybind state to the console for debugging.

RegisterCommand("debug_keybinds", function(source, args)
  print("^3=== DEBUG: Current Animation Keybinds ===^0")

  -- In-memory binds
  print("^5[In-Memory] Main.currentBinds:^0")
  if Main.currentBinds and next(Main.currentBinds) then
    for key, anim in pairs(Main.currentBinds) do
      print(("  ^2SHIFT + %s^0 -> ^6%s^0"):format(key, anim))
    end
  else
    print("  ^1(empty or nil)^0")
  end

  -- Available keybind slots
  print("^5[Available Slots] Main.keybinds:^0")
  if Main.keybinds and #Main.keybinds > 0 then
    print(("  %s"):format(table.concat(Main.keybinds, ", ")))
  else
    print("  ^1(empty or nil)^0")
  end

  -- Saved KVP data
  print("^5[Cached/Saved] From KVP:^0")
  local kvpRaw = GetResourceKvpString("BABLO_ANIMATIONS")
  if kvpRaw then
    local kvpData = json.decode(kvpRaw)
    if kvpData then
      local charId = Framework:getCharacterIdentifier()
      print(("  Character ID: ^3%s^0"):format(tostring(charId)))

      local charData = kvpData.characterData and kvpData.characterData[charId]
      if charData then
        -- Character-specific keybinds
        local charBinds = charData.keybinds
        if charBinds and next(charBinds) then
          print("  ^2Character-specific keybinds:^0")
          for key, anim in pairs(charBinds) do
            print(("    ^2SHIFT + %s^0 -> ^6%s^0"):format(key, anim))
          end
        else
          print("  ^1Character keybinds table exists but is empty^0")
        end
      else
        print("  ^1No character-specific keybinds found^0")
      end

      -- Global (non-character) keybinds
      if kvpData.keybinds then
        print("  ^2Global keybinds (non-character-specific):^0")
        if next(kvpData.keybinds) then
          for key, anim in pairs(kvpData.keybinds) do
            print(("    ^2SHIFT + %s^0 -> ^6%s^0"):format(key, anim))
          end
        else
          print("    ^1(empty)^0")
        end
      end
    else
      print("  ^1Failed to decode KVP data^0")
    end
  else
    print("  ^1No KVP data found^0")
  end

  print("^3=== END DEBUG ===^0")
end, false)

-- ─── NUI CALLBACK: IS_READY ──────────────────────────────────────────────────
-- Called by the NUI when it has finished loading.

RegisterNUICallback("IS_READY", function(data, cb)
  Trace("NUI is ready")
  Main.NUIReady = true
  return cb({ _ = 200 })
end)

-- ─── NUI CALLBACK: CLOSE_MENU ────────────────────────────────────────────────
-- Closes the animation menu and cleans up NUI focus.

RegisterNUICallback("CLOSE_MENU", function(data, cb)
  -- Stop any active creator tools
  if EmoteCreator and EmoteCreator.isActive then
    EmoteCreator:Stop()
  end
  if SoloEmoteCreator and SoloEmoteCreator.isActive then
    SoloEmoteCreator:Stop()
  end

  Main:sendReactMessage("SHOW_MENU", { element = "showApp", toggle = false })
  SetNuiFocus(false, false)

  Main.freeLook  = false
  Main.isClosing = true

  -- Delay inAction reset to avoid flickering
  SetTimeout(250, function()
    Main.inAction  = false
    Main.isClosing = false
    SetNuiFocusKeepInput(false)
  end)

  return cb(true)
end)

-- ─── NUI CALLBACK: INVITE_PLAYER ─────────────────────────────────────────────
-- Invites another player to join the current animation group.

RegisterNUICallback("INVITE_PLAYER", function(data, cb)
  local accepted = false

  -- Ask the server to relay the invitation
  local inviteResult = TriggerServerCallback({
    eventName = eventName .. "server:invitePlayer",
    args      = { data },
  })

  if inviteResult.status then
    -- Tell the server to update group membership
    TriggerServerEvent(eventName .. "server:setGroup", data.target)
    accepted = data.target
  else
    Framework:Notify(Translate("GROUP_REQUEST_DENIED"))
  end

  if accepted then
    -- Fetch updated group data and send it to the NUI
    local groupResult = TriggerServerCallback({
      eventName = eventName .. "server:getGroupData",
      args      = {},
    })

    if groupResult.status then
      Main:sendReactMessage("ON_INVITE", {
        player       = groupResult.player,
        currentGroup = groupResult.currentGroup,
        accepted     = accepted,
        target       = data.target,
      })
      Main.currentGroup = GetPlayerServerId(PlayerId())
    end
  else
    Main:sendReactMessage("ON_INVITE", { accepted = accepted, target = data.target })
  end

  return cb(true)
end)

-- ─── NUI CALLBACK: LEAVE_GROUP ───────────────────────────────────────────────
RegisterNUICallback("LEAVE_GROUP", function(data, cb)
  Trace("Leaving group:", json.encode(data))
  TriggerServerEvent(eventName .. "server:leaveGroup", data.currentGroup, data.target)
  return cb(true)
end)

-- ─── NUI CALLBACK: PLAY_ANIMATION ────────────────────────────────────────────
RegisterNUICallback("PLAY_ANIMATION", function(data, cb)
  Trace("Playing animation:", json.encode(data))
  Main:playAnimation(cache.ped, data)
  return cb(true)
end)

-- ─── NUI CALLBACK: PLACE_ANIMATION ───────────────────────────────────────────
RegisterNUICallback("PLACE_ANIMATION", function(data, cb)
  Trace("Playing animation:", json.encode(data))
  Main:editAnimation(data)
  return cb(true)
end)

-- ─── NUI CALLBACK: TOGGLE_FAVORITE ───────────────────────────────────────────
RegisterNUICallback("TOGGLE_FAVORITE", function(data, cb)
  Trace("Toggling favorite:", json.encode(data))
  Main:toggleFavorite(data)
  return cb(true)
end)

-- ─── NUI CALLBACK: SET_NUI_FOCUS ─────────────────────────────────────────────
RegisterNUICallback("SET_NUI_FOCUS", function(data, cb)
  Trace("Setting focus:", json.encode(data))
  SetNuiFocusKeepInput(data.focus)
  return cb(true)
end)

-- ─── NUI CALLBACK: SET_VOLUME ────────────────────────────────────────────────
RegisterNUICallback("SET_VOLUME", function(data, cb)
  Trace("Setting volume:", json.encode(data))
  Main.settings.musicVolume = data
  UpdateVolume(data)
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: RUN_ANIMPOS ───────────────────────────────────────────────
-- Closes the UI and opens the animation position adjustment command (if enabled).

RegisterNUICallback("RUN_ANIMPOS", function(data, cb)
  Trace("Running animpos via UI")

  -- Stop any active creator tools
  if EmoteCreator and EmoteCreator.isActive then
    EmoteCreator:Stop()
  end
  if SoloEmoteCreator and SoloEmoteCreator.isActive then
    SoloEmoteCreator:Stop()
  end

  Main:sendReactMessage("SHOW_MENU", { element = "showApp", toggle = false })
  SetNuiFocus(false, false)

  Main.freeLook  = false
  Main.isClosing = true

  SetTimeout(250, function()
    Main.inAction  = false
    Main.isClosing = false
    SetNuiFocusKeepInput(false)
  end)

  if Config.AnimAdjustCommand then
    ExecuteCommand(Config.AnimAdjustCommand)
    return cb(true)
  end

  return cb(false)
end)

-- ─── NUI CALLBACK: SET_MENU_POSITION ─────────────────────────────────────────
RegisterNUICallback("SET_MENU_POSITION", function(data, cb)
  Trace("Setting menu position:", data)
  Main.settings.menuAlign = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: SHOW_GIF_PREVIEW ──────────────────────────────────────────
RegisterNUICallback("SHOW_GIF_PREVIEW", function(data, cb)
  Trace("Setting gif preview:", json.encode(data))
  Main.settings.showGifs = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: PERFORMANCE_MODE ──────────────────────────────────────────
RegisterNUICallback("PERFORMANCE_MODE", function(data, cb)
  Trace("Setting performance mode:", json.encode(data))
  Main.settings.performanceMode = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: CHANGE_SCALE ──────────────────────────────────────────────
RegisterNUICallback("CHANGE_SCALE", function(data, cb)
  Trace("Changing scale:", json.encode(data))
  Main.settings.menuScale = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: TOGGLE_BIND ───────────────────────────────────────────────
RegisterNUICallback("TOGGLE_BIND", function(data, cb)
  Trace("Toggling favorite:", json.encode(data))
  Main:toggleBind(data)
  return cb(true)
end)

-- ─── NUI CALLBACK: SET_UPPERBODY ─────────────────────────────────────────────
RegisterNUICallback("SET_UPPERBODY", function(data, cb)
  Trace("Setting upper body:", json.encode(data))
  Main.onlyUpperBody = data.state
  return cb(true)
end)

-- ─── NUI CALLBACK: RESET_SETTINGS ────────────────────────────────────────────
RegisterNUICallback("RESET_SETTINGS", function(data, cb)
  Main.settings = Config.DefaultSettings
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: SET_BIG_MENU ──────────────────────────────────────────────
RegisterNUICallback("SET_BIG_MENU", function(data, cb)
  Trace("Setting big menu:", json.encode(data))
  if data == nil then data = false end
  Main.settings.bigMenu = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: SET_SOLID_PRIMARY ─────────────────────────────────────────
RegisterNUICallback("SET_SOLID_PRIMARY", function(data, cb)
  Trace("Setting solid primary:", json.encode(data))
  if data == nil then data = false end
  Main.settings.solidPrimary = data
  Main:saveSettings()
  return cb(true)
end)

-- ─── NUI CALLBACK: SAVE_SEQUENCE ─────────────────────────────────────────────
-- Creates a new sequence or updates an existing one in all relevant tables.

RegisterNUICallback("SAVE_SEQUENCE", function(data, cb)
  if data.isNew then
    -- Reject if a sequence with this command already exists
    for _, seq in ipairs(Main.sequences) do
      if seq.command == data.command then
        return cb(false)
      end
    end

    -- Build the new sequence entry (shared structure)
    local newEntry = {
      name     = data.command,
      category = "sequence",
      label    = data.label,
      type     = "sequence",
      musicURL = false,
      items    = data.items,
      style    = false,
    }

    table.insert(Main.animations,    newEntry)
    table.insert(Config.Sequences,   newEntry)

    -- Notify the NUI of the new animation
    Main:sendReactMessage("SET_MENU_BATCH", {
      animations  = { newEntry },
      isLastBatch = true,
    })
  else
    -- Ensure oldCommand has a fallback
    if not data.oldCommand then
      data.oldCommand = ""
    end

    -- Update matching entry in Main.sequences
    for _, seq in ipairs(Main.sequences) do
      if seq.command == data.command or seq.command == data.oldCommand then
        seq.label = data.label
        seq.items = data.items
        break
      end
    end

    -- Update matching entry in Config.Sequences
    for _, seq in ipairs(Config.Sequences) do
      if seq.command == data.command or seq.command == data.oldCommand then
        seq.label = data.label
        break
      end
    end

    -- Update matching entry in Main.animations
    for _, anim in ipairs(Main.animations) do
      if anim.command == data.command or anim.command == data.oldCommand then
        anim.label = data.label
        break
      end
    end

    Main:sendReactMessage("UPDATE_SEQUENCE", {
      command = data.oldCommand,
      label   = data.label,
      items   = data.items,
    })
  end

  Main:Set("sequences", Main.sequences)
  return cb(true)
end)

-- ─── NUI CALLBACK: DELETE_SEQUENCE ───────────────────────────────────────────
-- Removes a sequence from all relevant tables.

RegisterNUICallback("DELETE_SEQUENCE", function(data, cb)
  -- Remove from Main.sequences
  for i, seq in ipairs(Main.sequences) do
    if seq.command == data or seq.name == data then
      table.remove(Main.sequences, i)
      break
    end
  end

  Main:Set("sequences", Main.sequences)

  -- Remove from Config.Sequences
  for i, seq in ipairs(Config.Sequences) do
    if seq.command == data or seq.name == data then
      table.remove(Config.Sequences, i)
      break
    end
  end

  -- Remove from Main.animations
  for i, anim in ipairs(Main.animations) do
    if anim.command == data or anim.name == data then
      table.remove(Main.animations, i)
      break
    end
  end

  Main:sendReactMessage("DELETE_SEQUENCE", { command = data })
  return cb(true)
end)

-- ─── NUI CALLBACK: WHEEL_PLAY_ANIM ───────────────────────────────────────────
-- Plays an animation from the emote wheel and closes the wheel UI.

RegisterNUICallback("WHEEL_PLAY_ANIM", function(data, cb)
  Main.emoteWheelOpen = false
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)

  Main:sendReactMessage("SHOW_EMOTE_WHEEL", { toggle = false })

  if data and data.name then
    Main:playAnimation(cache.ped, data.name)
  end

  return cb(true)
end)

-- ─── NUI CALLBACK: WHEEL_CLOSE ───────────────────────────────────────────────
-- Closes the emote wheel without playing anything.

RegisterNUICallback("WHEEL_CLOSE", function(data, cb)
  Main.emoteWheelOpen = false
  SetNuiFocusKeepInput(false)
  SetNuiFocus(false, false)
  Main:sendReactMessage("SHOW_EMOTE_WHEEL", { toggle = false })
  return cb(true)
end)

-- ─── THREAD: Debug mode setup ────────────────────────────────────────────────
-- Registers the "openanim" debug command if Config.Debug is enabled.

Citizen.CreateThread(function()
  if Config.Debug then
    RegisterCommand("openanim", function()
      Main:openApp()
    end)
    Trace("Debug mode enabled")
  end
end)

-- ─── THREAD: Key bindings and open command setup ──────────────────────────────
-- Registers all configurable keybinds: open menu, cancel emote, free-look
-- toggle, emote wheel, and animation speed controls.

Citizen.CreateThread(function()
  -- Keybind: open menu
  if Config.OpenMenu then
    Main:registerKey(
      "___openmenu",
      Translate("KEYMAPPING_OPEN_TEXT"),
      Config.OpenMenu,
      function() Main:OpenMenu() end
    )
  end

  -- Command-based open if configured
  if Config.OpenCommand then
    RegisterCommand(Config.OpenCommand, function()
      Main:openApp()
    end, false)

    TriggerEvent("chat:addSuggestion",
      "/" .. Config.OpenCommand,
      "Open the emote menu",
      {}
    )
  end

  -- Keybind: cancel emote
  Main:registerKey(
    "___cancelemote",
    Translate("KEYMAPPING_CANCEL_EMOTE_TEXT"),
    Config.CancelEmote,
    function() Main:cancelEmote() end
  )

  -- Keybind: free-look toggle (when menu is open)
  if Config.EnableFreeLookToggle then
    Main:registerKey("___toggle_focus", "Toggle menu focus", "LMENU", function()
      if Main.inAction then
        local nowFocused = not IsNuiFocused()
        SetNuiFocus(nowFocused, nowFocused)
        SetNuiFocusKeepInput(nowFocused)
        Main.freeLook = not nowFocused

        if nowFocused then
          Framework:Notify(Translate("MENU_FOCUS_ENABLED"))
        else
          Framework:Notify(Translate("MENU_FOCUS_DISABLED"))
        end
      end
    end)
  end

  -- Keybind: emote wheel
  if Config.EmoteWheel then
    local wheelKey = Config.EmoteWheelKey or "Z"

    Main:registerKey("emotewheel", "Open Emote Wheel", wheelKey, function()
      -- Toggle: if already open, close it
      if Main.emoteWheelOpen then
        Main.emoteWheelOpen = false
        Main:sendReactMessage("SHOW_EMOTE_WHEEL", { toggle = false })
        SetNuiFocusKeepInput(false)
        SetNuiFocus(false, false)
        return
      end

      -- Block if the menu is already in use or the pause menu is open
      if Main.inAction or IsPauseMenuActive() then return end

      -- Build a sorted list of favourited animations
      local favList = {}
      if Main.animations and Main.favorites then
        for _, anim in ipairs(Main.animations) do
          if Main.favorites[anim.name] then
            local idx = #favList + 1
            favList[idx] = {
              name  = anim.name,
              label = anim.label or anim.name,
              src   = anim.src or nil,
            }
          end
        end
      end

      -- Notify the player if there are no favourites
      if #favList == 0 then
        Framework:Notify(Translate("NO_FAVORITES"))
        return
      end

      -- Sort alphabetically by label
      table.sort(favList, function(a, b)
        return (a.label or "") < (b.label or "")
      end)

      Main:sendReactMessage("SHOW_EMOTE_WHEEL", { animations = favList, toggle = true })
      SetNuiFocus(true, true)
      SetNuiFocusKeepInput(true)
      Main.emoteWheelOpen = true

      -- Disable game controls while the wheel is visible
      Citizen.CreateThread(function()
        while Main.emoteWheelOpen do
          Wait(0)
          DisableControlAction(1, 1,   true)
          DisableControlAction(1, 2,   true)
          DisableControlAction(1, 106, true)
          DisableControlAction(0, 25,  true)
          DisableControlAction(1, 25,  true)
          DisableControlAction(1, 142, true)
          DisableControlAction(0, 81,  true)
          DisableControlAction(0, 82,  true)
        end
      end)
    end)
  end

  -- Animation speed controls (PAGEUP / PAGEDOWN while in animation)
  local maxSpeed  = Config.AnimMaxSpeed  or 2.0
  local speedStep = Config.AnimSpeedStep or 0.1
  local speedUp   = false
  local speedDown = false

  RegisterCommand("+___animspeed_up",   function() speedUp   = true  end)
  RegisterCommand("-___animspeed_up",   function() speedUp   = false end)
  RegisterKeyMapping("+___animspeed_up",   "Speed Up Animation",  "keyboard", "PAGEUP")

  RegisterCommand("+___animspeed_down", function() speedDown = true  end)
  RegisterCommand("-___animspeed_down", function() speedDown = false end)
  RegisterKeyMapping("+___animspeed_down", "Slow Down Animation", "keyboard", "PAGEDOWN")

  -- Thread: apply speed changes while the player is in a compatible animation
  Citizen.CreateThread(function()
    while true do
      -- Only proceed if a speed key is held
      if speedUp or speedDown then
        local playerState = LocalPlayer.state
        if playerState.isInAnimation and Main.currentAnimHasSpeedEdit and not Main.isBusy and not Main.pedHandle then
          if MostRecentDict and MostRecentAnimation then
            -- Increase speed
            if speedUp then
              Main.animSpeed = math.min(Main.animSpeed + speedStep, maxSpeed)
            -- Decrease speed
            elseif speedDown then
              Main.animSpeed = math.max(Main.animSpeed - speedStep, 0.1)
            end

            -- Round to 2 decimal places
            Main.animSpeed = math.floor(Main.animSpeed * 100 + 0.5) / 100

            SetEntityAnimSpeed(cache.ped, MostRecentDict, MostRecentAnimation, Main.animSpeed)
            Main:sendReactMessage("SHOW_ANIM_SPEED", { toggle = true, speed = Main.animSpeed })
            Wait(120)
          end
        end
      end

      -- If no key is held and no conditions matched, use a longer wait
      if not (speedUp or speedDown) then
        Wait(200)
      else
        Wait(0)
      end
    end
  end)
end)

-- ─── EXPORT: getAnimations ───────────────────────────────────────────────────
exports("getAnimations", function()
  return Main.animations
end)

-- ─── EXPORT: getAnimation ────────────────────────────────────────────────────
exports("getAnimation", function(animName)
  return Main:getAnimation(animName)
end)

-- ─── EXPORT: getSharedAnimationData ──────────────────────────────────────────
-- Returns the shared animation data for a given animation name (string),
-- or nil if not found.

exports("getSharedAnimationData", function(animName)
  if not animName or type(animName) ~= "string" then
    return nil
  end

  if Main.sharedAnimations then
    local entry = Main.sharedAnimations[animName:lower()]
    if entry then
      return entry
    end
  end

  return nil
end)

-- ─── EXPORT: cancelAnimation ─────────────────────────────────────────────────
exports("cancelAnimation", function(ped)
  Main:cancelEmote(ped or cache.ped)
end)

-- ─── NUMPAD KEYBINDS ─────────────────────────────────────────────────────────
-- Maps numpad keys to animation shortcuts when numpad keybinds are not disabled.

if not (Config.DisableNumpadKeybinds or Config.DisableKeybinds) then
  local numpadMap = {
    END        = "numpad1",
    ARROWDOWN  = "numpad2",
    PAGEDOWN   = "numpad3",
    ARROWLEFT  = "numpad4",
    CLEAR      = "numpad5",
    ARROWRIGHT = "numpad6",
    HOME       = "numpad7",
    ARROWUP    = "numpad8",
    PAGEUP     = "numpad9",
    INSERT     = "numpad0",
  }

  for keyName, defaultKey in pairs(numpadMap) do
    -- Capture loop variables for the closure
    local capturedKeyName = keyName
    local capturedDefaultKey = defaultKey

    Main:registerKey(
      "___anim_" .. capturedKeyName,
      "Numpad Animation Key",
      capturedDefaultKey,
      function()
        -- Only fire when SHIFT is held
        if IsControlPressed(0, 21) or IsControlJustPressed(0, 21) then
          Trace("Pressed FIX", capturedDefaultKey, capturedKeyName,
            Main.currentBinds[capturedKeyName],
            json.encode(Main.currentBinds, { indent = 2 })
          )

          local boundAnim = Main.currentBinds[capturedKeyName]
          if boundAnim then
            Main:playAnimation(cache.ped, boundAnim)
          end
        end
      end
    )
  end
end

-- ─── AnimPos help item categorisation ────────────────────────────────────────
-- Splits Config.AnimPos entries into help (view) and helpEdit (edit) buckets.

local animPosHelpItems     = {}
local animPosEditHelpItems = {}

for _, entry in ipairs(Config.AnimPos) do
  if entry.type == "help" then
    local item = { textKey = entry.textKey }
    if entry.key  then item.key  = entry.key  end
    if entry.icon then item.icon = entry.icon end

    if entry.phase == "help" then
      table.insert(animPosHelpItems, item)
    elseif entry.phase == "helpEdit" then
      table.insert(animPosEditHelpItems, item)
    end
  end
end

Config.AnimPosHelp = {
  helpItems     = animPosHelpItems,
  editHelpItems = animPosEditHelpItems,
}