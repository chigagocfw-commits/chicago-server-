local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A1_2 or not A2_2 then
    return
  end
  L4_2 = A0_2
  L5_2 = "_garage_open_"
  L6_2 = A3_2
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = L0_1
  L5_2 = L5_2[L4_2]
  if L5_2 then
    L5_2 = RemoveInteract
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = L0_1
    L5_2[L4_2] = nil
  end
  L5_2 = CreateGarageOpenInteract
  L6_2 = L4_2
  L7_2 = A2_2
  L8_2 = _U
  L9_2 = "GARAGE_OPEN_GARAGE_KEY"
  L8_2 = L8_2(L9_2)
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = openGarageMenu
    L1_3 = A0_2
    L2_3 = A2_2.vehicles
    if not L2_3 then
      L2_3 = {}
    end
    L0_3(L1_3, L2_3)
  end
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = L0_1
  L5_2[L4_2] = true
  L5_2 = true
  return L5_2
end
function L4_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  if not A1_2 or not A2_2 then
    return
  end
  L4_2 = A0_2
  L5_2 = "_garage_remove_"
  L6_2 = A3_2
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = L0_1
  L5_2 = L5_2[L4_2]
  if L5_2 then
    L5_2 = RemoveInteract
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = L0_1
    L5_2[L4_2] = nil
  end
  L5_2 = {}
  L6_2 = A1_2.locations
  if L6_2 then
    L6_2 = ipairs
    L7_2 = A1_2.locations
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
    for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
      L12_2 = L11_2.vehicles
      if L12_2 then
        L12_2 = type
        L13_2 = L11_2.vehicles
        L12_2 = L12_2(L13_2)
        if "table" == L12_2 then
          L12_2 = ipairs
          L13_2 = L11_2.vehicles
          L12_2, L13_2, L14_2, L15_2 = L12_2(L13_2)
          for L16_2, L17_2 in L12_2, L13_2, L14_2, L15_2 do
            L18_2 = L17_2.model
            if L18_2 then
              L18_2 = string
              L18_2 = L18_2.lower
              L19_2 = L17_2.model
              L18_2 = L18_2(L19_2)
              L5_2[L18_2] = true
            end
          end
        end
      end
    end
  end
  L6_2 = CreateGarageRemoveInteract
  L7_2 = L4_2
  L8_2 = A2_2
  L9_2 = _U
  L10_2 = "GARAGE_STORE_VEHICLE_KEY"
  L9_2 = L9_2(L10_2)
  function L10_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = PlayerPedId
    L0_3 = L0_3()
    L1_3 = GetVehiclePedIsIn
    L2_3 = L0_3
    L3_3 = false
    L1_3 = L1_3(L2_3, L3_3)
    if 0 ~= L1_3 then
      L2_3 = storeVehicle
      L3_3 = L1_3
      L4_3 = A0_2
      L5_3 = L5_2
      L2_3(L3_3, L4_3, L5_3)
    end
  end
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = L0_1
  L6_2[L4_2] = true
  L6_2 = true
  return L6_2
end
L5_1 = {}
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if A1_2 then
    L2_2 = #A1_2
    if 0 ~= L2_2 then
      goto lbl_35
    end
  end
  L2_2 = GetGameTimer
  L2_2 = L2_2()
  L3_2 = L5_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = L5_1
    L3_2 = L3_2[A0_2]
    L3_2 = L2_2 - L3_2
    L4_2 = 10000
    if not (L3_2 > L4_2) then
      goto lbl_34
    end
  end
  L3_2 = showClientNotification
  L4_2 = {}
  L5_2 = _U
  L6_2 = "GARAGE"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = _U
  L6_2 = "GARAGE_NO_VEHICLES_AVAILABLE"
  L5_2 = L5_2(L6_2)
  L4_2.description = L5_2
  L4_2.type = "info"
  L3_2(L4_2)
  L3_2 = L5_1
  L3_2[A0_2] = L2_2
  ::lbl_34::
  do return end
  ::lbl_35::
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L2_2
    L11_2 = {}
    L12_2 = L8_2.label
    L11_2.title = L12_2
    L12_2 = _U
    L13_2 = "GARAGE_MODEL"
    L14_2 = L8_2.model
    L12_2 = L12_2(L13_2, L14_2)
    L11_2.description = L12_2
    L11_2.icon = "fa-solid fa-car"
    function L12_2()
      local L0_3, L1_3, L2_3
      L0_3 = confirmTakeVehicle
      L1_3 = A0_2
      L2_3 = L8_2
      L0_3(L1_3, L2_3)
    end
    L11_2.onSelect = L12_2
    L9_2(L10_2, L11_2)
  end
  L3_2 = lib
  L3_2 = L3_2.registerContext
  L4_2 = {}
  L5_2 = "garage_menu_"
  L6_2 = A0_2
  L5_2 = L5_2 .. L6_2
  L4_2.id = L5_2
  L5_2 = _U
  L6_2 = "GARAGE_VEHICLES"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L4_2.options = L2_2
  L3_2(L4_2)
  L3_2 = lib
  L3_2 = L3_2.showContext
  L4_2 = "garage_menu_"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
end
openGarageMenu = L6_1
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = lib
  L2_2 = L2_2.alertDialog
  L3_2 = {}
  L4_2 = _U
  L5_2 = "GARAGE_TAKE_VEHICLE"
  L4_2 = L4_2(L5_2)
  L3_2.header = L4_2
  L4_2 = _U
  L5_2 = "GARAGE_CONFIRM_TAKE"
  L6_2 = A1_2.label
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.content = L4_2
  L3_2.centered = true
  L3_2.cancel = true
  L2_2 = L2_2(L3_2)
  if "confirm" == L2_2 then
    L3_2 = spawnVehicle
    L4_2 = A0_2
    L5_2 = A1_2
    L3_2(L4_2, L5_2)
  end
end
confirmTakeVehicle = L6_1
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = nil
  L3_2 = Config
  L3_2 = L3_2.Garages
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Garages
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Garages
      L3_2 = L3_2[A0_2]
      L4_2 = L3_2.enabled
      if L4_2 then
        L4_2 = L3_2.locations
        if L4_2 then
          L4_2 = ipairs
          L5_2 = L3_2.locations
          L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
          for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
            L10_2 = L9_2.type
            if "spawn" == L10_2 then
              L2_2 = L9_2
              break
            end
          end
        end
      end
    end
  end
  if not L2_2 then
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "GARAGE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "GARAGE_NO_SPAWN_LOCATION"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
    return
  end
  L3_2 = vector3
  L4_2 = L2_2.x
  L5_2 = L2_2.y
  L6_2 = L2_2.z
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = tonumber
  L5_2 = L2_2.w
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = tonumber
    L5_2 = L2_2.heading
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = 0.0
    end
  end
  L5_2 = Config
  L5_2 = L5_2.Debug
  if L5_2 then
    L5_2 = print
    L6_2 = "[GARAGE DEBUG] Spawn Location:"
    L7_2 = json
    L7_2 = L7_2.encode
    L8_2 = L2_2
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L7_2(L8_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L5_2 = print
    L6_2 = "[GARAGE DEBUG] Spawn Heading:"
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
  end
  L5_2 = IsAnyVehicleNearPoint
  L6_2 = L3_2.x
  L7_2 = L3_2.y
  L8_2 = L3_2.z
  L9_2 = 3.0
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  if L5_2 then
    L5_2 = showClientNotification
    L6_2 = {}
    L7_2 = _U
    L8_2 = "GARAGE"
    L7_2 = L7_2(L8_2)
    L6_2.title = L7_2
    L7_2 = _U
    L8_2 = "GARAGE_SPAWN_AREA_BLOCKED"
    L7_2 = L7_2(L8_2)
    L6_2.description = L7_2
    L6_2.type = "error"
    L5_2(L6_2)
    return
  end
  L5_2 = GetHashKey
  L6_2 = A1_2.model
  L5_2 = L5_2(L6_2)
  L6_2 = RequestModel
  L7_2 = L5_2
  L6_2(L7_2)
  L6_2 = 0
  while true do
    L7_2 = HasModelLoaded
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      break
    end
    L7_2 = 10000
    if not (L6_2 < L7_2) then
      break
    end
    L7_2 = Wait
    L8_2 = 100
    L7_2(L8_2)
    L6_2 = L6_2 + 100
  end
  L7_2 = HasModelLoaded
  L8_2 = L5_2
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = showClientNotification
    L8_2 = {}
    L9_2 = _U
    L10_2 = "GARAGE"
    L9_2 = L9_2(L10_2)
    L8_2.title = L9_2
    L9_2 = _U
    L10_2 = "GARAGE_FAILED_LOAD_MODEL"
    L9_2 = L9_2(L10_2)
    L8_2.description = L9_2
    L8_2.type = "error"
    L7_2(L8_2)
    return
  end
  L7_2 = SetFocusPosAndVel
  L8_2 = L3_2.x
  L9_2 = L3_2.y
  L10_2 = L3_2.z
  L11_2 = 0.0
  L12_2 = 0.0
  L13_2 = 0.0
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = Wait
  L8_2 = 200
  L7_2(L8_2)
  L7_2 = L2_2.z
  L8_2 = CreateVehicle
  L9_2 = L5_2
  L10_2 = L3_2.x
  L11_2 = L3_2.y
  L12_2 = L7_2 + 1.0
  L13_2 = L4_2
  L14_2 = true
  L15_2 = false
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if L8_2 then
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = 0
      while true do
        L10_2 = NetworkGetEntityIsNetworked
        L11_2 = L8_2
        L10_2 = L10_2(L11_2)
        if not (not L10_2 and L9_2 < 50) then
          break
        end
        L10_2 = Wait
        L11_2 = 10
        L10_2(L11_2)
        L9_2 = L9_2 + 1
      end
      L10_2 = NetworkGetEntityIsNetworked
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      if L10_2 then
        L10_2 = SetNetworkIdExistsOnAllMachines
        L11_2 = NetworkGetNetworkIdFromEntity
        L12_2 = L8_2
        L11_2 = L11_2(L12_2)
        L12_2 = true
        L10_2(L11_2, L12_2)
      end
      L10_2 = SetEntityAsMissionEntity
      L11_2 = L8_2
      L12_2 = true
      L13_2 = true
      L10_2(L11_2, L12_2, L13_2)
      L10_2 = Wait
      L11_2 = 100
      L10_2(L11_2)
      L10_2 = FreezeEntityPosition
      L11_2 = L8_2
      L12_2 = true
      L10_2(L11_2, L12_2)
      L10_2 = SetEntityCoords
      L11_2 = L8_2
      L12_2 = L3_2.x
      L13_2 = L3_2.y
      L14_2 = L7_2
      L15_2 = false
      L16_2 = false
      L17_2 = false
      L18_2 = false
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
      L10_2 = SetEntityCollision
      L11_2 = L8_2
      L12_2 = true
      L13_2 = true
      L10_2(L11_2, L12_2, L13_2)
      L10_2 = Wait
      L11_2 = 100
      L10_2(L11_2)
      L10_2 = FreezeEntityPosition
      L11_2 = L8_2
      L12_2 = false
      L10_2(L11_2, L12_2)
      L10_2 = SetVehicleOnGroundProperly
      L11_2 = L8_2
      L10_2(L11_2)
      L10_2 = Wait
      L11_2 = 150
      L10_2(L11_2)
      L10_2 = FreezeEntityPosition
      L11_2 = L8_2
      L12_2 = true
      L10_2(L11_2, L12_2)
      L10_2 = SetEntityHeading
      L11_2 = L8_2
      L12_2 = L4_2
      L10_2(L11_2, L12_2)
      L10_2 = Config
      L10_2 = L10_2.Debug
      if L10_2 then
        L10_2 = Wait
        L11_2 = 50
        L10_2(L11_2)
        L10_2 = print
        L11_2 = "[GARAGE DEBUG] Vehicle heading set to:"
        L12_2 = L4_2
        L10_2(L11_2, L12_2)
        L10_2 = print
        L11_2 = "[GARAGE DEBUG] Vehicle actual heading:"
        L12_2 = GetEntityHeading
        L13_2 = L8_2
        L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L12_2(L13_2)
        L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
      end
      L10_2 = Wait
      L11_2 = 100
      L10_2(L11_2)
      L10_2 = FreezeEntityPosition
      L11_2 = L8_2
      L12_2 = false
      L10_2(L11_2, L12_2)
      L10_2 = SetVehicleEngineOn
      L11_2 = L8_2
      L12_2 = true
      L13_2 = true
      L14_2 = false
      L10_2(L11_2, L12_2, L13_2, L14_2)
      L10_2 = SetVehicleDoorsLocked
      L11_2 = L8_2
      L12_2 = 1
      L10_2(L11_2, L12_2)
      L10_2 = PlayerPedId
      L10_2 = L10_2()
      L11_2 = TaskWarpPedIntoVehicle
      L12_2 = L10_2
      L13_2 = L8_2
      L14_2 = -1
      L11_2(L12_2, L13_2, L14_2)
      L11_2 = Wait
      L12_2 = 100
      L11_2(L12_2)
      L11_2 = ClearFocus
      L11_2()
      L11_2 = Config
      L11_2 = L11_2.Tuneshops
      if L11_2 then
        L11_2 = Config
        L11_2 = L11_2.Tuneshops
        L11_2 = L11_2[A0_2]
      end
      if L11_2 then
        L12_2 = L11_2.blip
        if L12_2 then
          L12_2 = L11_2.blip
          L12_2 = L12_2.name
          if L12_2 then
            goto lbl_306
          end
        end
      end
      L12_2 = "Unknown"
      ::lbl_306::
      L13_2 = TriggerServerEvent
      L14_2 = "qs-mechanic-creator:server:logVehicleSpawned"
      L15_2 = A1_2.model
      L16_2 = L12_2
      L13_2(L14_2, L15_2, L16_2)
      L13_2 = giveVehicleKeys
      if L13_2 then
        L13_2 = type
        L14_2 = giveVehicleKeys
        L13_2 = L13_2(L14_2)
        if "function" == L13_2 then
          L13_2 = giveVehicleKeys
          L14_2 = L8_2
          L15_2 = A1_2.plate
          L13_2(L14_2, L15_2)
        end
      end
      L13_2 = showClientNotification
      L14_2 = {}
      L15_2 = _U
      L16_2 = "GARAGE"
      L15_2 = L15_2(L16_2)
      L14_2.title = L15_2
      L15_2 = _U
      L16_2 = "GARAGE_VEHICLE_SPAWNED"
      L17_2 = A1_2.label
      L15_2 = L15_2(L16_2, L17_2)
      L14_2.description = L15_2
      L14_2.type = "success"
      L13_2(L14_2)
  end
  else
    L9_2 = ClearFocus
    L9_2()
    L9_2 = showClientNotification
    L10_2 = {}
    L11_2 = _U
    L12_2 = "GARAGE"
    L11_2 = L11_2(L12_2)
    L10_2.title = L11_2
    L11_2 = _U
    L12_2 = "GARAGE_FAILED_SPAWN_VEHICLE"
    L11_2 = L11_2(L12_2)
    L10_2.description = L11_2
    L10_2.type = "error"
    L9_2(L10_2)
  end
  L9_2 = SetModelAsNoLongerNeeded
  L10_2 = L5_2
  L9_2(L10_2)
end
spawnVehicle = L6_1
function L6_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if A0_2 then
    L3_2 = DoesEntityExist
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L4_2 = A1_2
  L5_2 = "_"
  L6_2 = tostring
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = L2_1
  L5_2 = L5_2[L4_2]
  if L5_2 then
    L5_2 = L2_1
    L5_2 = L5_2[L4_2]
    L5_2 = L3_2 - L5_2
    L6_2 = 500
    if L5_2 < L6_2 then
      L5_2 = Config
      L5_2 = L5_2.Debug
      if L5_2 then
        L5_2 = print
        L6_2 = "[GARAGE DEBUG] storeVehicle blocked by debounce for:"
        L7_2 = L4_2
        L5_2(L6_2, L7_2)
      end
      return
    end
  end
  L5_2 = L2_1
  L5_2[L4_2] = L3_2
  L5_2 = SetTimeout
  L6_2 = 2000
  function L7_2()
    local L0_3, L1_3, L2_3
    L1_3 = L4_2
    L0_3 = L2_1
    L0_3 = L0_3[L1_3]
    if L0_3 then
      L0_3 = GetGameTimer
      L0_3 = L0_3()
      L2_3 = L4_2
      L1_3 = L2_1
      L1_3 = L1_3[L2_3]
      L0_3 = L0_3 - L1_3
      L1_3 = 1500
      if L0_3 > L1_3 then
        L1_3 = L4_2
        L0_3 = L2_1
        L0_3[L1_3] = nil
      end
    end
  end
  L5_2(L6_2, L7_2)
  L5_2 = Config
  L5_2 = L5_2.Debug
  if L5_2 then
    L5_2 = print
    L6_2 = "[GARAGE DEBUG] storeVehicle called for shopId:"
    L7_2 = A1_2
    L5_2(L6_2, L7_2)
    L5_2 = print
    L6_2 = "[GARAGE DEBUG] Vehicle:"
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = print
    L6_2 = "[GARAGE DEBUG] Allowed vehicles:"
    L7_2 = json
    L7_2 = L7_2.encode
    L8_2 = A2_2 or L8_2
    if not A2_2 then
      L8_2 = {}
    end
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L7_2(L8_2)
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
  L5_2 = GetEntityModel
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = GetDisplayNameFromVehicleModel
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  L7_2 = string
  L7_2 = L7_2.lower
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  if A2_2 then
    L8_2 = next
    L9_2 = A2_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L8_2 = A2_2[L7_2]
      if not L8_2 then
        L8_2 = Config
        L8_2 = L8_2.Debug
        if L8_2 then
          L8_2 = print
          L9_2 = "[GARAGE DEBUG] Vehicle not allowed notification about to be shown"
          L8_2(L9_2)
        end
        L8_2 = showClientNotification
        L9_2 = {}
        L10_2 = _U
        L11_2 = "GARAGE"
        L10_2 = L10_2(L11_2)
        L9_2.title = L10_2
        L10_2 = _U
        L11_2 = "GARAGE_VEHICLE_NOT_ALLOWED"
        L10_2 = L10_2(L11_2)
        if not L10_2 then
          L10_2 = "This vehicle can only be stored at the garage it was spawned from"
        end
        L9_2.description = L10_2
        L9_2.type = "error"
        L8_2(L9_2)
        return
      end
  end
  else
    L8_2 = Config
    L8_2 = L8_2.Debug
    if L8_2 then
      L8_2 = print
      L9_2 = "[GARAGE DEBUG] No vehicles configured notification about to be shown"
      L8_2(L9_2)
    end
    L8_2 = showClientNotification
    L9_2 = {}
    L10_2 = _U
    L11_2 = "GARAGE"
    L10_2 = L10_2(L11_2)
    L9_2.title = L10_2
    L10_2 = _U
    L11_2 = "GARAGE_NO_VEHICLES_CONFIGURED"
    L10_2 = L10_2(L11_2)
    if not L10_2 then
      L10_2 = "This garage has no vehicles configured"
    end
    L9_2.description = L10_2
    L9_2.type = "error"
    L8_2(L9_2)
    return
  end
  L8_2 = TriggerServerEvent
  L9_2 = "qs-mechanic-creator:server:logVehicleStored"
  L10_2 = L6_2
  L11_2 = "Garage"
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = showClientNotification
  L9_2 = {}
  L10_2 = _U
  L11_2 = "GARAGE"
  L10_2 = L10_2(L11_2)
  L9_2.title = L10_2
  L10_2 = _U
  L11_2 = "GARAGE_VEHICLE_STORED"
  L12_2 = L6_2
  L10_2 = L10_2(L11_2, L12_2)
  L9_2.description = L10_2
  L9_2.type = "success"
  L8_2(L9_2)
  L8_2 = SetEntityAsMissionEntity
  L9_2 = A0_2
  L10_2 = true
  L11_2 = true
  L8_2(L9_2, L10_2, L11_2)
  L8_2 = DeleteVehicle
  L9_2 = A0_2
  L8_2(L9_2)
end
storeVehicle = L6_1
function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = L0_1
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = RemoveInteract
    L7_2 = L4_2
    L6_2(L7_2)
    L6_2 = L0_1
    L6_2[L4_2] = nil
  end
end
cleanupGarageZones = L6_1
L6_1 = AddEventHandler
L7_1 = "qs-mechanic-creator:client:updateGarages"
function L8_1()
  local L0_2, L1_2
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3
    L0_3 = cleanupGarageZones
    L0_3()
    L0_3 = Wait
    L1_3 = 200
    L0_3(L1_3)
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Garages
    if not L2_3 then
      L2_3 = {}
    end
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L6_3.enabled
      if L7_3 then
        L7_3 = L6_3.locations
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Tuneshops
          L7_3 = L7_3[L5_3]
          if L7_3 then
            L8_3 = hasShopAccess
            L9_3 = L7_3
            L8_3 = L8_3(L9_3)
            if L8_3 then
              L9_3 = ipairs
              L10_3 = L6_3.locations
              L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3)
              for L13_3, L14_3 in L9_3, L10_3, L11_3, L12_3 do
                L15_3 = L14_3.type
                if "open" == L15_3 then
                  L15_3 = L3_1
                  L16_3 = L5_3
                  L17_3 = L6_3
                  L18_3 = L14_3
                  L19_3 = L13_3
                  L15_3(L16_3, L17_3, L18_3, L19_3)
                else
                  L15_3 = L14_3.type
                  if "remove" == L15_3 then
                    L15_3 = L4_1
                    L16_3 = L5_3
                    L17_3 = L6_3
                    L18_3 = L14_3
                    L19_3 = L13_3
                    L15_3(L16_3, L17_3, L18_3, L19_3)
                  end
                end
                L0_3 = L0_3 + 1
                L15_3 = L0_3 % 3
                if 0 == L15_3 then
                  L15_3 = Wait
                  L16_3 = 100
                  L15_3(L16_3)
                end
              end
            end
          end
        end
      end
      L7_3 = Wait
      L8_3 = 50
      L7_3(L8_3)
    end
  end
  L0_2(L1_2)
end
L6_1(L7_1, L8_1)
L6_1 = AddEventHandler
L7_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A0_2 then
    return
  end
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = string
    L7_2 = L7_2.find
    L8_2 = L5_2
    L9_2 = A0_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L7_2 = RemoveInteract
      L8_2 = L5_2
      L7_2(L8_2)
      L7_2 = L0_1
      L7_2[L5_2] = nil
    end
  end
end
L6_1(L7_1, L8_1)
L6_1 = AddEventHandler
L7_1 = "onResourceStop"
function L8_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = cleanupGarageZones
    L1_2()
  end
end
L6_1(L7_1, L8_1)
