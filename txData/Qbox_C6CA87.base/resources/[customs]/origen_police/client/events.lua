-- Vehicle Purchase Event
RegisterNetEvent("origen_police:client:buyveh", function(markerId, subId)
  local marker = Tables.Markers[markerId][subId]
  local playerData = FW_GetPlayerData()
  local jobName = playerData.job.name
  local menu = {}
  
  table.insert(menu, {
    header = Config.Translations.RequestVeh,
    isMenuHeader = true
  })
  
  for vehicleType, vehicles in pairs(Config.Vehicles) do
    if vehicleType == "car" and vehicles[jobName] then
      for vehicleModel, vehicleData in pairs(vehicles[jobName]) do
        if playerData.job.grade.level >= vehicleData.grade then
          table.insert(menu, {
            header = vehicleData.label,
            txt = Config.Translations.RequestVeh,
            icon = "fa-solid fa-car",
            params = {
              isAction = true,
              event = function()
                local closestVeh = FW_GetClosestVehicle(marker.spawn.xyz)
                local distance = #(marker.spawn.xyz - GetEntityCoords(closestVeh))
                
                if distance > 4 then
                  FW_SpawnVehicle(vehicleModel, function(vehicle)
                    SetVehicleFuel(vehicle, 100.0)
                    SetEntityHeading(vehicle, marker.spawn.w)
                    TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))
                    
                    if GetResourceState("qs-vehiclekeys") == "started" then
                      exports["qs-vehiclekeys"]:GiveKeys(
                        GetVehiclePlate(vehicle),
                        GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                        true
                      )
                    end
                    
                    local model = GetEntityModel(vehicle)
                    local label = Config.CustomCarLabels[model] or GetLabelText(GetDisplayNameFromVehicleModel(model))
                    
                    TriggerServerEvent("origen_police:server:TrackVehicle", NetworkGetNetworkIdFromEntity(vehicle), label)
                    GiveKeys("car", vehicle)
                    AddVehicleExtras("car", vehicle, vehicleModel)
                  end, marker.spawn.xyz, true)
                else
                  ShowNotification(Config.Translations.ExistVehicleInSpawn)
                end
              end
            }
          })
        end
      end
    end
  end
  
  OpenMenu(menu)
end)

-- Delete Vehicle Event
RegisterNetEvent("origen_police:client:deletevehicle", function()
  local vehicle = GetVehicleInCamera()
  
  if vehicle ~= 0 then
    local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId()))
    
    if distance < 7 then
      if GetResourceState("qs-vehiclekeys") == "started" then
        exports["qs-vehiclekeys"]:RemoveKeys(
          GetVehiclePlate(vehicle),
          GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        )
      end
      
      TaskLeaveVehicle(PlayerPedId(), vehicle, 64)
      RemoveKeys(vehicle)
      Citizen.Wait(2000)
      FW_DeleteVehicle(vehicle)
    end
  else
    ShowNotification(Config.Translations.MustLook)
  end
end)

-- Helicopter Purchase Event
RegisterNetEvent("origen_police:client:helicop", function(markerId, subId)
  local marker = Tables.Markers[markerId][subId]
  local playerData = FW_GetPlayerData()
  local jobName = playerData.job.name
  local menu = {}
  
  table.insert(menu, {
    header = Config.Translations.Heliport,
    isMenuHeader = true
  })
  
  for vehicleType, vehicles in pairs(Config.Vehicles) do
    if vehicleType == "heli" and vehicles[jobName] then
      for vehicleModel, vehicleData in pairs(vehicles[jobName]) do
        if playerData.job.grade.level >= vehicleData.grade then
          table.insert(menu, {
            header = vehicleData.label,
            txt = Config.Translations.TakeOutHeli,
            icon = "fa-solid fa-helicopter",
            params = {
              isAction = true,
              event = function()
                local closestVeh = FW_GetClosestVehicle(marker.spawn.xyz)
                local distance = #(marker.spawn.xyz - GetEntityCoords(closestVeh))
                
                if distance > 4 then
                  FW_SpawnVehicle(vehicleModel, function(vehicle)
                    SetVehicleFuel(vehicle, 100.0)
                    SetEntityHeading(vehicle, marker.spawn.w)
                    TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))
                    
                    if GetResourceState("qs-vehiclekeys") == "started" then
                      exports["qs-vehiclekeys"]:GiveKeys(
                        GetVehiclePlate(vehicle),
                        GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                        true
                      )
                    end
                    
                    GiveKeys("helicopter", vehicle)
                    AddVehicleExtras("helicopter", vehicle, vehicleModel)
                  end, marker.spawn.xyz, true)
                else
                  ShowNotification(Config.Translations.ExistHelicopterInSpawn)
                end
              end
            }
          })
        end
      end
    end
  end
  
  OpenMenu(menu)
end)

-- Boat Purchase Event
RegisterNetEvent("origen_police:client:boat", function(markerId, subId)
  local marker = Tables.Markers[markerId][subId]
  local playerData = FW_GetPlayerData()
  local jobName = playerData.job.name
  local menu = {}
  
  table.insert(menu, {
    header = Config.Translations.Pier,
    isMenuHeader = true
  })
  
  for vehicleType, vehicles in pairs(Config.Vehicles) do
    if vehicleType == "boat" and vehicles[jobName] then
      for vehicleModel, vehicleData in pairs(vehicles[jobName]) do
        if playerData.job.grade.level >= vehicleData.grade then
          table.insert(menu, {
            header = vehicleData.label,
            txt = Config.Translations.TakeOutBoat,
            icon = "fa-solid fa-ship",
            params = {
              isAction = true,
              event = function()
                local closestVeh = FW_GetClosestVehicle(marker.spawn.xyz)
                local distance = #(marker.spawn.xyz - GetEntityCoords(closestVeh))
                
                if distance > 4 then
                  FW_SpawnVehicle(vehicleModel, function(vehicle)
                    SetVehicleFuel(vehicle, 100.0)
                    SetEntityHeading(vehicle, marker.spawn.w)
                    TriggerEvent("vehiclekeys:client:SetOwner", GetVehiclePlate(vehicle))
                    
                    if GetResourceState("qs-vehiclekeys") == "started" then
                      exports["qs-vehiclekeys"]:GiveKeys(
                        GetVehiclePlate(vehicle),
                        GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)),
                        true
                      )
                    end
                    
                    GiveKeys("boat", vehicle)
                    AddVehicleExtras("boat", vehicle, vehicleModel)
                  end, marker.spawn.xyz, true)
                else
                  ShowNotification(Config.Translations.ExistBoatInSpawn)
                end
              end
            }
          })
        end
      end
    end
  end
  
  OpenMenu(menu)
end)

-- Inventory Event
RegisterNetEvent("origen_police:client:inventory", function(markerId, subId)
  local marker = Tables.Markers[markerId][subId]
  local playerData = FW_GetPlayerData(false)
  
  if not playerData or not playerData.job or not playerData.job.name then
    return
  end
  
  local result = CanOpenTablet(playerData.job.name)
  local canOpen = result[1]
  local jobCategory = result[2]
  
  -- Only police can access armory
  if not canOpen or jobCategory ~= Config.PoliceJobCategory then
    FW_Notify("This equipment point is restricted to police officers")
    return
  end
  
  OpenMenu({
    {
      header = Config.Translations.PoliceEquipment,
      isMenuHeader = true
    },
    {
      header = Config.Translations.Equipment,
      txt = Config.Translations.EquipmentDesc,
      icon = "fa-solid fa-gun",
      params = {
        isAction = true,
        event = function()
          OpenArmoury()
        end
      }
    },
    {
      header = Config.Translations.LeaveEquipment,
      txt = Config.Translations.LeaveEquipmentDesc,
      icon = "fa-solid fa-shield",
      params = {
        isAction = true,
        event = function()
          LeavePoliceEquipment(marker)
        end
      }
    },
    {
      header = Config.Translations.PoliceInventory,
      txt = Config.Translations.PoliceInventoryDesc,
      icon = "fa-solid fa-box",
      params = {
        isAction = true,
        event = function()
          PoliceInventory(marker)
        end
      }
    },
    {
      header = Config.Translations.EvidenceProof,
      txt = Config.Translations.EvidenceProofDesc,
      icon = "fa-solid fa-receipt",
      params = {
        isAction = true,
        event = function()
          OpenEvidenceInventory(marker)
        end
      }
    }
  })
end)

-- Vehicle Data Event
RegisterNetEvent("origen_police:client:vehicledata", function()
  local vehicle = GetVehicleInCamera()
  
  if vehicle ~= 0 then
    local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId()))
    
    if distance < Config.VehicleDataDist then
      FW_TriggerCallback("origen_police:callback:vehicledata", function(owner)
        OpenMenu({
          {
            header = Config.Translations.VehicleInformation,
            isMenuHeader = true
          },
          {
            header = Config.Translations.Model,
            txt = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))),
            icon = "fa-solid fa-car",
            params = {
              isAction = true,
              event = function()
                SendNUIMessage({
                  action = "copy",
                  value = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))
                })
              end
            }
          },
          {
            header = Config.Translations.LicensePlate,
            txt = GetVehiclePlate(vehicle),
            icon = "fa-solid fa-id-card",
            params = {
              isAction = true,
              event = function()
                SendNUIMessage({
                  action = "copy",
                  value = GetVehiclePlate(vehicle)
                })
              end
            }
          },
          {
            header = Config.Translations.Owner,
            txt = owner,
            icon = "fa-solid fa-user",
            params = {
              isAction = true,
              event = function()
                SendNUIMessage({
                  action = "copy",
                  value = owner
                })
              end
            }
          }
        })
      end, GetVehiclePlate(vehicle))
    end
  else
    ShowNotification(Config.Translations.MustLook)
  end
end)

-- Confiscate Vehicle Event
RegisterNetEvent("origen_police:client:dvpolice", function()
  ConfiscateVeh()
end)

-- Open Vehicle Event
RegisterNetEvent("origen_police:client:openveh", function()
  local vehicle = GetVehicleInCamera()
  
  if vehicle ~= 0 then
    local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId()))
    
    if distance < 2 then
      local attempts = 0
      
      while not NetworkHasControlOfEntity(vehicle) and attempts < 100 do
        if not DoesEntityExist(vehicle) then
          break
        end
        Citizen.Wait(100)
        NetworkRequestControlOfEntity(vehicle)
        attempts = attempts + 1
      end
      
      if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
        RequestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
        while not HasAnimDictLoaded("anim@amb@clubhouse@tutorial@bkr_tut_ig3@") do
          Citizen.Wait(7)
        end
        
        TaskPlayAnim(PlayerPedId(), "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 8.0, -8.0, -1, 1, 0, false, false, false)
        Citizen.Wait(3000)
        ClearPedTasks(PlayerPedId())
        
        SetVehicleDoorsLocked(vehicle, 0)
        SetVehicleDoorsLockedForAllPlayers(vehicle, false)
        GiveVehicleKeys(vehicle)
      else
        ShowNotification(Config.Translations.CouldntOpenLock)
      end
    end
  else
    ShowNotification(Config.Translations.MustLook)
  end
end)

-- Vehicle Evidence Event
RegisterNetEvent("origen_police:client:vehevidences", function()
  local vehicle = GetVehicleInCamera()
  
  if vehicle ~= 0 then
    local distance = #(GetEntityCoords(vehicle) - GetEntityCoords(PlayerPedId()))
    
    if distance < 2 then
      TriggerServerEvent("origen_police:server:GetEvidence", false, {
        type = "FinguerPrint",
        fkserie = GetVehiclePlate(vehicle)
      })
    end
  else
    ShowNotification(Config.Translations.MustLook)
  end
end)

-- Make Report Event
RegisterNetEvent("origen_police:client:makereport", function()
  local playerData = FW_GetPlayerData(false)
  
  if not playerData or not playerData.job or not playerData.job.name then
    return
  end
  
  local result = CanOpenTablet(playerData.job.name)
  local canOpen = result[1]
  local jobCategory = result[2]
  
  -- Only police can use lab
  if not canOpen or jobCategory ~= Config.PoliceJobCategory then
    FW_Notify("The lab is restricted to police officers")
    return
  end
  
  local evidences = {}
  
  for _, item in pairs(FW_GetPlayerData(true).items) do
    if #evidences >= 4 then
      break
    end
    
    if string.find(item.name, "^evidence_") then
      table.insert(evidences, GetItemMetadata(item))
    end
  end
  
  if #evidences > 0 then
    TriggerServerEvent("origen_police:client:removeevidences")
    
    FW_TriggerCallback("OsTime", function(date)
      SendNUIMessage({
        action = "AnalizeEvidences",
        list = evidences,
        date = date
      })
    end)
    
    SetNuiFocus(true, true)
  else
    ShowNotification(Config.Translations.NoEvidence)
  end
end)

-- NUI Callbacks
RegisterNUICallback("focus", function(data, cb)
  SetNuiFocus(false, false)
  ClearPedTasks(PlayerPedId())
  cb(true)
end)

RegisterNUICallback("savereportevidence", function(data, cb)
  TriggerServerEvent("origen_police:server:savereportevidence", data.url)
  cb(true)
end)

-- Show Badge Event
RegisterNetEvent("origen_police:client:showbadge", function(badgeData)
  local canOpen = CanOpenTablet(FW_GetPlayerData().job.name)[1]
  
  if Config.ShowBadgePreview then
    TriggerEvent("origen_police:client:viewbadge", badgeData)
  end
  
  if not canOpen and not Config.NotPoliceCanShowBadge then
    return
  end
  
  local closestPlayer, distance = FW_GetClosestPlayer()
  
  if closestPlayer ~= -1 and distance <= 3.0 and distance > 0 then
    RequestAnimDict("paper_1_rcm_alt1-8")
    while not HasAnimDictLoaded("paper_1_rcm_alt1-8") do
      Citizen.Wait(0)
    end
    
    local badgeModel = "prop_lspd_badge"
    if badgeData.type == "BCSD" then
      badgeModel = "prop_bcso_badge"
    elseif badgeData.type == "FIB" then
      badgeModel = "prop_fib_badge"
    end
    
    RequestModel(badgeModel)
    while not HasModelLoaded(GetHashKey(badgeModel)) do
      Citizen.Wait(0)
    end
    
    local badgeObject = CreateObject(GetHashKey(badgeModel), GetEntityCoords(PlayerPedId()), true, true, true)
    TaskPlayAnim(PlayerPedId(), "paper_1_rcm_alt1-8", "player_one_dual-8", 8.0, 8.0, -1, 50, 0, false, false, false)
    AttachEntityToEntity(badgeObject, PlayerPedId(), GetPedBoneIndex(PlayerPedId(), 28422), 0.09, 0.0, -0.05, -90.0, -180.0, 70.9, true, true, false, true, 1, true)
    
    TriggerServerEvent("origen_police:server:showbadge", GetPlayerServerId(closestPlayer), badgeData)
    
    Citizen.Wait(5000)
    ClearPedTasks(PlayerPedId())
    DeleteObject(badgeObject)
  else
    ShowNotification(Config.Translations.NoPersonNear, "error")
  end
end)

-- View Badge Event
RegisterNetEvent("origen_police:client:viewbadge", function(badgeData)
  badgeData.action = "ViewBadge"
  SendNUIMessage(badgeData)
  
  Citizen.CreateThread(function()
    while true do
      Citizen.Wait(0)
      if IsControlJustPressed(0, 177) then
        SendNUIMessage({ action = "ViewBadge" })
        break
      end
    end
  end)
end)

-- Radio Load Callback
RegisterNUICallback("LoadRadio", function(data, cb)
  local playerData = FW_GetPlayerData(false)
  
  if not Config.NeedRadioForDispatch then
    exports.origen_police:Toggle(true)
    return cb({
      freclist = Config.Multifrec,
      myfrec = exports.origen_police:GetMultiFrec() or "none"
    })
  end
  
  for _, item in pairs(playerData.items) do
    if item.name == "radio" then
      exports.origen_police:Toggle(true)
      return cb({
        freclist = Config.Multifrec,
        myfrec = exports.origen_police:GetMultiFrec() or "none"
      })
    end
  end
  
  cb(false)
end)

-- Radio Events
RegisterNetEvent("origen_police:client:AddPlayerMultiFrec", function(playerId, frequency, data)
  SendNUIMessage({
    radio = "AddPlayerMultiFrec",
    id = playerId,
    frec = frequency,
    data = data,
    i = playerId == GetPlayerServerId(PlayerId())
  })
end)

RegisterNetEvent("origen_police:client:Disconnected", function()
  SendNUIMessage({ radio = "Disconnected" })
end)

RegisterNetEvent("origen_police:client:talking", function(target, value)
  SendNUIMessage({
    radio = "Talking",
    target = target,
    value = value
  })
end)

RegisterNetEvent("origen_police:client:RemovePlayerMultiFrec", function(playerId, frequency)
  SendNUIMessage({
    radio = "RemovePlayerMultiFrec",
    id = playerId,
    frec = frequency
  })
end)

RegisterNetEvent("origen_police:client:SetMuted", function(playerId, value)
  SendNUIMessage({
    radio = "SetMuted",
    id = playerId,
    value = value
  })
end)

RegisterNetEvent("origen_police:client:SetReady", function(playerId, value)
  SendNUIMessage({
    radio = "SetReady",
    id = playerId,
    value = value
  })
end)

-- Trigger Callback
RegisterNUICallback("TriggerCallback", function(data, cb)
  if not data.name:find("^origen_police") then
    return cb(false)
  end
  
  FW_TriggerCallback(data.name, function(result)
    if data.name == "origen_police:police:GetCitizen" then
      for i = 1, #result.vehicles do
        result.vehicles[i].garage = result.vehicles[i].garage or "No"
        result.vehicles[i].label = GetLabelText(GetDisplayNameFromVehicleModel(tonumber(result.vehicles[i].hash)))
        
        if result.vehicles[i].label == "NULL" then
          result.vehicles[i].label = Config.CustomCarLabels[tonumber(result.vehicles[i].hash)] or "UNKNOWN"
        end
        
        if result.vehicles[i].garage:find("police_confiscate_veh") then
          result.vehicles[i].status = Config.Translations.Confiscated
        elseif result.vehicles[i].garage:find("police_") then
          result.vehicles[i].status = Config.Translations.PoliceFacilities
        else
          result.vehicles[i].status = ""
        end
        
        result.vehicles[i].garage = nil
        result.vehicles[i].hash = nil
      end
    elseif data.name == "origen_police:police:SearchVehicle" then
      for i = 1, #result do
        result[i].label = GetLabelText(GetDisplayNameFromVehicleModel(tonumber(result[i].hash)))
        
        if result[i].label == "NULL" then
          result[i].label = Config.CustomCarLabels[result[i].hash] or "UNKNOWN"
        end
        
        if result[i].garage:find("police_confiscate_veh") then
          result[i].status = Config.Translations.Confiscated
        elseif result[i].garage:find("police_") then
          result[i].status = Config.Translations.PoliceFacilities
        else
          result[i].status = result[i].garage
        end
        
        result[i].garage = nil
        result[i].hash = nil
      end
    elseif data.name == "origen_police:police:GetVehicle" then
      result.label = GetLabelText(GetDisplayNameFromVehicleModel(tonumber(result.hash)))
      
      if result.garage:find("police_confiscate_veh") then
        result.status = Config.Translations.Confiscated
      elseif result.garage:find("police_") then
        result.status = Config.Translations.PoliceFacilities
      else
        result.status = ""
      end
      
      result.garage = nil
      result.hash = nil
    elseif data.name == "origen_police:callback:GetStationsList" then
      for _, station in pairs(result) do
        station.coords = station.coords or {0, 0, 0}
        station.street = GetStreetName(station.coords)
      end
    end
    
    cb(result)
  end, data)
end)

-- Sync Quick Event
RegisterNetEvent("origen_police:client:SyncQuick", function(data)
  data.action = "SyncQuick"
  SendNUIMessage(data)
end)

-- Set Wanted Level Event
RegisterNetEvent("origen_police:client:SetWantedLevel", function(level)
  SetWantedLevel(level)
end)

-- Clothing Event
RegisterNetEvent("origen_police:client:clothing", function(markerId, subId, clothingData)
  OpenClothing(clothingData)
end)

-- Criminal Clothes Event
RegisterNetEvent("origen_police:client:CriminalClothes", function()
  local playerData = FW_GetPlayerData(true)
  local ped = PlayerPedId()
  local model = GetEntityModel(ped)
  
  local gender = false
  if model == GetHashKey("mp_m_freemode_01") then
    gender = "male"
  elseif model == GetHashKey("mp_f_freemode_01") then
    gender = "female"
  end
  
  SetCriminalClothes(gender, playerData)
end)

-- Pertenences Event
RegisterNetEvent("origen_police:client:pertenences", function(markerId)
  local marker = Public.Markers[markerId]
  TriggerServerEvent("origen_police:server:pertenences", marker.station or 0)
end)

-- Modify Vehicle Event
RegisterNetEvent("origen_police:client:modifyveh", function()
  local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
  
  if vehicle == 0 then
    return ShowNotification(Config.Translations.VehicleCannotBeFound)
  end
  
  if not IsVehicleValid("car", vehicle) then
    return ShowNotification(Config.Translations.InvalidVeh)
  end
  
  OpenMenu({
    {
      header = Config.Translations.VehicleMods,
      isMenuHeader = true
    },
    {
      header = "EXTRAS",
      icon = "fa-solid fa-gear",
      params = {
        isAction = true,
        event = function()
          local extrasMenu = {
            {
              header = Config.Translations.VehicleMods,
              isMenuHeader = true
            }
          }
          
          for extraId, enabled in pairs(GetVehicleExtras(vehicle)) do
            table.insert(extrasMenu, {
              header = "EXTRA " .. tostring(extraId),
              txt = enabled and Config.Translations.Enabled or Config.Translations.Disabled,
              icon = "fa-solid fa-gear",
              params = {
                isAction = true,
                event = function()
                  SetVehicleExtra(vehicle, extraId, enabled)
                end
              }
            })
          end
          
          table.insert(extrasMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
              isAction = true,
              event = function()
                TriggerEvent("origen_police:client:modifyveh")
              end
            }
          })
          
          OpenMenu(extrasMenu)
        end
      }
    },
    {
      header = "LIVERIES",
      icon = "fa-solid fa-paint-brush",
      params = {
        isAction = true,
        event = function()
          local liveriesMenu = {
            {
              header = Config.Translations.VehicleMods,
              isMenuHeader = true
            }
          }
          
          local currentLivery = GetVehicleLivery(vehicle)
          local currentMod = GetVehicleMod(vehicle, 48)
          
          if currentMod >= 0 or currentLivery >= -1 then
            for i = 0, GetNumVehicleMods(vehicle, 48) - 1 do
              table.insert(liveriesMenu, {
                header = "LIVERY " .. tostring(i),
                icon = "fa-solid fa-paint-brush",
                params = {
                  isAction = true,
                  event = function()
                    SetVehicleLivery(vehicle, i)
                    SetVehicleMod(vehicle, 48, i)
                  end
                }
              })
            end
          else
            for i = 0, GetVehicleLiveryCount(vehicle) - 1 do
              table.insert(liveriesMenu, {
                header = "LIVERY " .. tostring(i),
                icon = "fa-solid fa-paint-brush",
                params = {
                  isAction = true,
                  event = function()
                    SetVehicleLivery(vehicle, i)
                    SetVehicleMod(vehicle, 48, i)
                  end
                }
              })
            end
          end
          
          table.insert(liveriesMenu, {
            header = Config.Translations.Back,
            icon = "fa-solid fa-arrow-left",
            params = {
              isAction = true,
              event = function()
                TriggerEvent("origen_police:client:modifyveh")
              end
            }
          })
          
          OpenMenu(liveriesMenu)
        end
      }
    }
  })
end)

-- Set Volume Callback
RegisterNUICallback("SetVolume", function(volume)
  if type(volume) ~= "number" then
    return
  end
  
  volume = math.max(0, math.min(100, volume))
  SetRadioVolume(volume)
end)

-- Generate Mugshot Badge Event
RegisterNetEvent("origen_police:client:GenerateMugshotBadge", function(citizenId, badgeType, transparent)
  local mugshot = GetMugShotBase64(PlayerPedId(), false, transparent)
  TriggerServerEvent("origen_police:server:SaveMugshot", mugshot, citizenId, badgeType)
end)