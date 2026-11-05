local currentWeaponData = {}
local lastPlayerHealth = false
local lastVehicleHealth = false
local evidenceBuffer = {}

Citizen.CreateThread(function()
  if Public.Blips then
    for _, blipData in pairs(Public.Blips) do
      local blip = AddBlipForCoord(blipData.coords.xyz)
      SetBlipSprite(blip, blipData.sprite or 1)
      SetBlipColour(blip, blipData.color or 0)
      SetBlipScale(blip, blipData.size or 0.8)
      SetBlipAsShortRange(blip, true)
      BeginTextCommandSetBlipName("STRING")
      AddTextComponentSubstringPlayerName(blipData.name)
      EndTextCommandSetBlipName(blip)
    end
  end

  Citizen.CreateThread(function()
    if Public.TrafficZones then
      Citizen.Wait(5000)
      
      for i = 1, #Public.TrafficZones do
        if onduty then
          Public.TrafficZones[i].blip = AddBlipForRadius(Public.TrafficZones[i].coords, 50.0)
          SetBlipAlpha(Public.TrafficZones[i].coords, 100)
        end

        if Public.TrafficZones[i].type == "stop" then
          Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 0.0, false)
          if Public.TrafficZones[i].blip then
            SetBlipColour(Public.TrafficZones[i].blip, 6)
          end
        elseif Public.TrafficZones[i].type == "slow" then
          Public.TrafficZones[i].id = AddRoadNodeSpeedZone(Public.TrafficZones[i].coords, 50.0, 5.0, false)
          if Public.TrafficZones[i].blip then
            SetBlipColour(Public.TrafficZones[i].blip, 44)
          end
        end
      end
    end
  end)

  while true do
    local sleepTime = 2000
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if Public.Markers then
      for i = 1, #Public.Markers do
        local marker = Public.Markers[i]
        local distance = #(playerCoords - marker.coords.xyz)

        if distance < 30 then
          sleepTime = 0

          if Config.MarkersDraw then
            DrawMarker(
              marker.sprite,
              marker.coords.x, marker.coords.y, marker.coords.z,
              0.0, 0.0, 0.0,
              0.0, 0.0, 0.0,
              0.3, 0.3, 0.3,
              marker.rgba.r, marker.rgba.g, marker.rgba.b, marker.rgba.a,
              false, false, 0, true
            )
          end

          local interactionRadius = marker.radius or 1
          if distance < interactionRadius then
            if Config.CustomNotify then
              ShowHelpNotification("E", marker.text)
              marker.noty = true
            else
              if Config.Framework == "qbcore" then
                if not marker.noty then
                  exports["qb-core"]:DrawText("[E] " .. marker.text, "left")
                  marker.noty = true
                end
              elseif Config.Framework == "esx" then
                Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. marker.text, true)
              end
            end

            if IsControlJustPressed(0, 38) then
              TriggerEvent(marker.event, i, marker.station)
            end
          else
            if marker.noty then
              HideHelpNotification()
              marker.noty = nil
            end
          end
        else
          if marker.noty then
            HideHelpNotification()
            marker.noty = nil
          end
        end
      end
    end

    Citizen.Wait(sleepTime)
  end
end)

function IsInRestrictedZone()
  local playerCoords = GetEntityCoords(PlayerPedId())
  
  for i = 1, #Config.RestrictedAlertZones do
    if isInside(Config.RestrictedAlertZones[i], playerCoords.x, playerCoords.y) then
      return true
    end
  end
  
  return false
end

Citizen.CreateThread(function()
  while true do
    local sleepTime = 500
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    if not Config.EvidenceSystem and not Config.ShootAlert then
      break
    end

    if not IsInRestrictedZone() then
      if IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(playerPed, 78) then
        sleepTime = 0

        if IsPedShooting(playerPed) then
          local onScreen, impactCoords, hitEntity = GetScreenCoords()

          if onScreen then
            currentWeaponData = GetItemFromWeapon(FW_GetPlayerData(false), GetSelectedPedWeapon(playerPed))

            if not currentWeaponData then
              Debuger("Can't find weapon data in the inventory, weapon: ", GetSelectedPedWeapon(playerPed))
            else
              if Config.EvidenceSystem and currentWeaponData and currentWeaponData.slot then
                table.insert(evidenceBuffer, {
                  type = "Shoot",
                  coords = playerCoords,
                  wp = currentWeaponData.slot
                })

                if DoesEntityExist(hitEntity) and not IsEntityPositionFrozen(hitEntity) then
                  if hitEntity and IsEntityAPed(hitEntity) and not IsPedAPlayer(hitEntity) then
                    table.insert(evidenceBuffer, {
                      type = "NpcBlood",
                      coords = impactCoords,
                      adn = IsPedHuman(hitEntity) and "Generate" or "Animal"
                    })
                  end
                else
                  table.insert(evidenceBuffer, {
                    type = "Impact",
                    coords = impactCoords,
                    wp = currentWeaponData.slot
                  })
                end
              end

              if Config.ShootAlert then
                SendShootAlert(currentWeaponData)
              end
            end
          end
        end
      else
        if evidenceBuffer and #evidenceBuffer > 0 then
          if Config.EvidenceSystem then
            local processedEvidence = {}

            for i = 1, #evidenceBuffer do
              local isDuplicate = false

              for j = 1, #processedEvidence do
                local distanceBetween = #(processedEvidence[j].coords - evidenceBuffer[i].coords)
                
                if distanceBetween < 1.1 then
                  if processedEvidence[j].type == evidenceBuffer[i].type then
                    if evidenceBuffer[i].npc and processedEvidence[j].npc then
                      if evidenceBuffer[i].npc == processedEvidence[j].npc then
                        processedEvidence[j].count = (processedEvidence[j].count or 1) + 1
                        isDuplicate = true
                      end
                    else
                      processedEvidence[j].count = (processedEvidence[j].count or 1) + 1
                      isDuplicate = true
                    end
                  end
                end
              end

              if not isDuplicate then
                table.insert(processedEvidence, evidenceBuffer[i])
              end
            end

            TriggerServerEvent("origen_police:server:AddNewEvidence", processedEvidence)
            evidenceBuffer = {}
          end
        end
      end

      if Config.EvidenceSystem then
        local currentVehicle = GetVehiclePedIsIn(playerPed, false)

        if currentVehicle ~= 0 then
          if GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
            if lastVehicleHealth then
              local healthDiff = lastVehicleHealth - GetVehicleBodyHealth(currentVehicle)
              
              if healthDiff > 5 then
                local vehicleModel = Config.CustomCarLabels[GetEntityModel(currentVehicle)] or 
                                   GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle)))
                
                local vehicleColors = {GetVehicleColor(currentVehicle)}

                TriggerServerEvent("origen_police:server:AddNewEvidence", {
                  type = "VehCrash",
                  model = vehicleModel,
                  color = vehicleColors,
                  coords = GetEntityCoords(currentVehicle)
                })
              end
            end

            lastVehicleHealth = GetVehicleBodyHealth(currentVehicle)
          end
        elseif currentVehicle == 0 then
          if lastPlayerHealth then
            local healthDiff = lastPlayerHealth - GetEntityHealth(playerPed)
            
            if healthDiff > 6 then
              TriggerServerEvent("origen_police:server:AddNewEvidence", {
                type = "BloodRest",
                adn = true,
                bloodType = GetSelfBloodType(),
                coords = GetEntityCoords(playerPed)
              })
            end
          end

          lastPlayerHealth = GetEntityHealth(playerPed)
          lastVehicleHealth = false
        end
      end
    end

    Citizen.Wait(sleepTime)
  end
end)

Citizen.CreateThread(function()
  while true do
    if not Public.Radars or #Public.Radars == 0 then
      Citizen.Wait(5000)
    else
      break
    end
  end

  local lastRadarCoords = false

  while true do
    local sleepTime = 1500
    local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

    if #Public.Radars > 0 and currentVehicle ~= 0 then
      if GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
        local vehicleCoords = GetEntityCoords(currentVehicle)
        sleepTime = 150

        if not lastRadarCoords then
          for i = 1, #Public.Radars do
            local distanceToRadar = #(vehicleCoords - Public.Radars[i].coords)

            if distanceToRadar < 22 then
              lastRadarCoords = Public.Radars[i].coords

              if Public.Radars[i].type == 1 then
                local speedMultiplier = Config.SpeedType == "kmh" and 3.6 or 2.23694
                local vehicleSpeed = GetEntitySpeed(currentVehicle) * speedMultiplier

                if vehicleSpeed > Public.Radars[i].value then
                  if GetVehicleClass(currentVehicle) ~= 18 then
                    vehicleSpeed = FW_Round(vehicleSpeed)

                    local vehicleModel = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle)))
                    local vehicleColors = {GetVehicleColor(currentVehicle)}
                    local vehiclePlate = GetVehiclePlate(currentVehicle)
                    local speedDiff = vehicleSpeed - Public.Radars[i].value

                    TriggerServerEvent("SendAlert:police", {
                      coords = Public.Radars[i].coords,
                      title = Config.Translations.Speeding,
                      type = "RADARES",
                      metadata = {
                        model = vehicleModel,
                        color = vehicleColors,
                        plate = vehiclePlate,
                        speed = vehicleSpeed .. " kmh / ^" .. speedDiff .. " kmh"
                      },
                      job = Config.PoliceJobCategory,
                      ignoreCooldown = true
                    })

                    SendNUIMessage({ action = "RadarFlash" })
                  end
                end
              elseif Public.Radars[i].type == 2 then
                local vehiclePlate = GetVehiclePlate(currentVehicle)
                
                if vehiclePlate:find(Public.Radars[i].value) then
                  local vehicleModel = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle)))
                  local vehicleColors = {GetVehicleColor(currentVehicle)}

                  TriggerServerEvent("SendAlert:police", {
                    coords = Public.Radars[i].coords,
                    title = Config.Translations.PlateCod9,
                    type = "RADARES",
                    metadata = {
                      model = vehicleModel,
                      color = vehicleColors,
                      plate = vehiclePlate
                    },
                    job = Config.PoliceJobCategory,
                    ignoreCooldown = true
                  })

                  SendNUIMessage({ action = "RadarFlash" })
                end
              end
            end
          end
        else
          if #(vehicleCoords - lastRadarCoords) > 22 then
            lastRadarCoords = false
          end
        end
      end
    end

    Citizen.Wait(sleepTime)
  end
end)

Citizen.CreateThread(function()
  local wheelData = {
    { name = "wheel_lf", index = 0 },
    { name = "wheel_lr", index = 4 },
    { name = "wheel_rf", index = 1 },
    { name = "wheel_lm1", index = 2 },
    { name = "wheel_rm1", index = 3 },
    { name = "wheel_rr", index = 5 },
    { name = "wheel_lm2", index = 45 },
    { name = "wheel_rm2", index = 47 }
  }

  while true do
    local sleepTime = 1500

    if IsPedInAnyVehicle(PlayerPedId()) then
      local currentVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

      if GetPedInVehicleSeat(currentVehicle, -1) == PlayerPedId() then
        sleepTime = 500

        local spikeStrip = GetClosestObjectOfType(
          GetEntityCoords(currentVehicle),
          50.0,
          GetHashKey("p_ld_stinger_s"),
          false, false, false
        )

        if spikeStrip ~= 0 then
          sleepTime = 10
          local spikeCoords = GetEntityCoords(spikeStrip)
          local vehicleSpeed = GetEntitySpeed(currentVehicle)

          if vehicleSpeed > 15 then
            local distanceToSpike = #(spikeCoords - GetEntityCoords(currentVehicle))

            if distanceToSpike < 5 then
              for i = 1, GetVehicleNumberOfWheels(currentVehicle) do
                if not IsVehicleTyreBurst(currentVehicle, wheelData[i].index, false) then
                  SetVehicleTyreBurst(currentVehicle, wheelData[i].index, true, 0)
                end
              end
            end
          else
            for i = 1, GetVehicleNumberOfWheels(currentVehicle) do
              local wheelPos = GetWorldPositionOfEntityBone(
                currentVehicle,
                GetEntityBoneIndexByName(currentVehicle, wheelData[i].name)
              )
              local distanceToWheel = #(spikeCoords - wheelPos)

              if distanceToWheel < 1 then
                if not IsVehicleTyreBurst(currentVehicle, wheelData[i].index, false) then
                  SetVehicleTyreBurst(currentVehicle, wheelData[i].index, true, 0)
                end
              end
            end
          end
        end
      end
    end

    Citizen.Wait(sleepTime)
  end
end)

local evidenceList = {}
local evidenceThreadActive = true
local lastEvidenceUpdate = 0
local isFlashlightActive = false

function EvidenceThread()
  while true do
    local playerData = FW_GetPlayerData(false)

    while playerData ~= nil do
      local currentWeapon = GetSelectedPedWeapon(PlayerPedId())
      local sleepTime = 500

      if not isFlashlightActive and currentWeapon ~= 0 then
        if currentWeapon == GetHashKey("weapon_flashlight") then
          isFlashlightActive = true
          local playerPed = PlayerPedId()
          
          -- Update player data if needed
          local timeSinceUpdate = GetGameTimer() - lastEvidenceUpdate
          if timeSinceUpdate > 10000 then
            playerData = FW_GetPlayerData(false)
            lastEvidenceUpdate = GetGameTimer()
          end
          
          -- Check if player can use police equipment
          local result = CanOpenTablet(playerData.job.name)
          local canOpenTablet = result[1]
          local jobCategory = result[2]
          
          -- Only allow police to see evidences (not EMS)
          if canOpenTablet and jobCategory == Config.PoliceJobCategory then
            local isOnDuty = false
            if Config.Framework == "qbcore" then
              isOnDuty = playerData.job.onduty
            else
              isOnDuty = exports.origen_police:IsOnDuty()
            end

            FW_TriggerCallback("origen_police:callback:GetEvidences", function(evidences)
            evidenceList = evidences

            Citizen.CreateThread(function()
              local helpNotifyShown = nil

              while currentWeapon == GetHashKey("weapon_flashlight") do
                local loopSleepTime = 1000
                currentWeapon = GetSelectedPedWeapon(PlayerPedId())

                if IsPlayerFreeAiming(PlayerId()) or GetPedConfigFlag(playerPed, 78) then
                  loopSleepTime = 0
                  local playerCoords = GetEntityCoords(playerPed)

                  for i = 1, #evidenceList do
                    if evidenceList[i] then
                      local distanceToEvidence = #(playerCoords - evidenceList[i].coords)

                      if distanceToEvidence < Config.EvidenceDrawDistance then
                        local evidenceConfig = Config.Evidences[evidenceList[i].type]
                        local colorR = evidenceConfig.color.r or evidenceList[i].color[1]
                        local colorG = evidenceConfig.color.g or evidenceList[i].color[2]
                        local colorB = evidenceConfig.color.b or evidenceList[i].color[3]

                        DrawMarker(
                          evidenceConfig.sprite,
                          evidenceList[i].coords,
                          0.0, 0.0, 0.0,
                          0.0, 0.0, 0.0,
                          0.2, 0.2, 0.2,
                          colorR, colorG, colorB, 255,
                          false, false, 0, true
                        )

                        if evidenceList[i].count then
                          DrawText3D(
                            evidenceList[i].coords.x,
                            evidenceList[i].coords.y,
                            evidenceList[i].coords.z + 0.2,
                            "x" .. evidenceList[i].count
                          )
                        end

                        if distanceToEvidence < 1.5 then
                          local notifyText = isOnDuty and Config.Translations.CollectEvidence or Config.Translations.ClearEvidence

                          if Config.CustomNotify then
                            ShowHelpNotification("E", notifyText)
                            helpNotifyShown = true
                          else
                            if Config.Framework == "qbcore" then
                              if not helpNotifyShown then
                                exports["qb-core"]:DrawText("[E] " .. notifyText, "left")
                                helpNotifyShown = true
                              end
                            else
                              Framework.ShowHelpNotification("~INPUT_PICKUP~ " .. notifyText, true)
                            end
                          end

                          if IsControlJustPressed(0, 38) then
                            if isOnDuty then
                              TriggerServerEvent("origen_police:server:GetEvidence", i, evidenceList[i])
                              CollectEvidenceAnim(i)
                            else
                              TriggerServerEvent("origen_police:server:RemoveEvidence", i)
                              CollectEvidenceAnim(i)
                            end
                          end
                        end
                      end
                    end
                  end
                else
                  if helpNotifyShown then
                    HideHelpNotification()
                    helpNotifyShown = nil
                  end
                end

                Citizen.Wait(loopSleepTime)
              end

              if helpNotifyShown then
                HideHelpNotification()
                helpNotifyShown = nil
              end

              evidenceList = {}
            end)
          end, GetEntityCoords(playerPed))
          else
            -- Non-police job with flashlight - show notification once
            if canOpenTablet and jobCategory == Config.EmsJobCategory then
              FW_Notify("Evidence collection is restricted to police officers")
            else
              FW_Notify(Config.Translations.CantUseItem or "You cannot use police equipment")
            end
          end
        end
      elseif currentWeapon ~= GetHashKey("weapon_flashlight") then
        isFlashlightActive = false
        sleepTime = 3000
      end

      if not evidenceThreadActive then
        break
      end

      Wait(sleepTime)
    end

    if not evidenceThreadActive then
      break
    end
  end
end

function CollectEvidenceAnim(evidenceIndex)
  RequestAnimDict("pickup_object")
  while not HasAnimDictLoaded("pickup_object") do
    Citizen.Wait(7)
  end

  if evidenceList[evidenceIndex] and evidenceList[evidenceIndex].type then
    if Config.Evidences[evidenceList[evidenceIndex].type].anim then
      TaskPlayAnim(PlayerPedId(), "pickup_object", "pickup_low", 8.0, -8.0, -1, 1, 0, false, false, false)
    end
  else
    print("Something went wrong with the evidence type, DATA: ", json.encode(evidenceList[evidenceIndex]), "ID: ", evidenceIndex)
  end

  local animStartTime = GetGameTimer()
  local evidenceCoords = evidenceList[evidenceIndex].coords

  while GetGameTimer() - animStartTime < 1000 do
    SetIkTarget(PlayerPedId(), 4, nil, nil, evidenceCoords.x, evidenceCoords.y, evidenceCoords.z, 0.0, 50, 200)
    Wait(0)
  end

  ClearPedTasks(PlayerPedId())
end

RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
  if not Config.EvidenceSystem then
    return
  end

  EvidenceThread()
end)

RegisterNetEvent("origen_police:client:rmevidence", function(evidenceId)
  if evidenceList[evidenceId] then
    evidenceList[evidenceId] = nil
  end
end)

function DrawText3D(x, y, z, text, font)
  local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
  local textLength = string.len(text) / 370
  font = font or 4

  SetTextScale(0.38, 0.38)
  SetTextFont(font)
  SetTextProportional(1)
  SetTextColour(255, 255, 255, 215)
  SetTextEntry("STRING")
  SetTextCentre(true)
  AddTextComponentString(text)
  SetTextDropshadow(textLength, 255, 0, 0, 255)
  DrawText(screenX, screenY)
end

local lastShootAlertTime = false

function SendShootAlert(weaponData)
  if Config.WeaponSilencierBlockShootAlert then
    if IsPedCurrentWeaponSilenced(PlayerPedId()) then
      Debuger("Weapon has a silencier, not sending shoot alert")
      return
    end
  end

  if IsWeaponBlacklisted(weaponData.name) then
    Debuger("Weapon is blacklisted, not sending shoot alert")
    return
  end

  if Config.ShootAlertRequireSeen then
    if not IsBeingSeen() then
      Debuger("Player is not being seen by any player or ambient peds, not sending shoot alert, you can disable this in Config.ShootAlertRequireSeen")
      return
    end
  end

  if Config.ShootAlertDisablePolice then
    if CanOpenTablet(FW_GetPlayerData(false).job.name)[1] then
      Debuger("Player has a job listed in config/jobs.lua, not sending shoot alert, you can disable this in Config.ShootAlertDisablePolice")
      return
    end
  end

  if lastShootAlertTime then
    if GetGameTimer() - lastShootAlertTime < Config.ShootAlertCooldown then
      Debuger("Shoot alert cooldown(" .. (Config.ShootAlertCooldown - (GetGameTimer() - lastShootAlertTime)) / 1000 .. " sec), not sending shoot alert")
      return
    end
  end

  lastShootAlertTime = GetGameTimer()

  local ammoType = GetPedAmmoTypeFromWeapon(PlayerPedId(), GetHashKey(weaponData.name))

  if ammoType then
    if IsAmmoBlacklisted(ammoType) then
      Debuger("Ammo type is blacklisted(" .. ammoType .. "), not sending shoot alert")
      return
    end
  end

  math.randomseed(GetGameTimer())
  local weaponChance = math.random(0, 100) <= Config.ShootAlertWeaponChance
  local ammoChance = math.random(0, 100) <= Config.ShootAlertAmmoChance

  Debuger("Shoot alert data: ", json.encode({
    weaponChance = weaponChance,
    ammoChance = ammoChance,
    lastshootalert = lastShootAlertTime,
    weaponData = weaponData,
    ammotype = ammoType,
    weaponName = weaponData.name or "Unknown",
    weaponLabel = weaponData.label or "Unknown"
  }, { indent = true }))

  TriggerServerEvent("SendAlert:police", {
    coords = GetEntityCoords(PlayerPedId()),
    title = Config.Translations["215"],
    metadata = {
      weapon = weaponChance and weaponData.label or nil,
      ammotype = ammoChance and GetCaliberTranslation(ammoType) or nil
    },
    job = Config.PoliceJobCategory,
    ignoreCooldown = true
  })
end

RegisterNetEvent("origen_police:client:robVehicle", function()
  local playerPed = PlayerPedId()

  if IsPedInAnyVehicle(playerPed, false) then
    local playerCoords = GetEntityCoords(playerPed, true)
    local streetHash, crossingHash = Citizen.InvokeNative(0x2EB41072B4C1E4C0, playerCoords.x, playerCoords.y, playerCoords.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())

    local streetNames = {}
    if streetHash ~= 0 then
      table.insert(streetNames, GetStreetNameFromHashKey(streetHash))
    end
    if crossingHash ~= 0 then
      table.insert(streetNames, GetStreetNameFromHashKey(crossingHash))
    end

    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    local vehicleModel = GetDisplayNameFromVehicleModel(GetEntityModel(currentVehicle))

    TriggerServerEvent("SendAlert:police", {
      coords = GetEntityCoords(PlayerPedId()),
      title = Config.Translations.VehicleRob,
      type = "RADARES",
      message = Config.Translations.VehicleRobDesc,
      metadata = {
        model = vehicleModel,
        color = {GetVehicleColor(GetVehiclePedIsIn(PlayerPedId()))},
        plate = GetVehiclePlate(GetVehiclePedIsIn(PlayerPedId()))
      },
      job = Config.PoliceJobCategory,
      ignoreCooldown = true
    })
  end
end)

if Config.Commands.ForceVehicle and Config.Commands.ForceVehicle.cmd ~= "" then
  RegisterCommand(Config.Commands.ForceVehicle.cmd, function()
    TriggerEvent("origen_police:client:robVehicle")
  end)
end

exports("RobVehicle", function()
  TriggerEvent("origen_police:client:robVehicle")
end)