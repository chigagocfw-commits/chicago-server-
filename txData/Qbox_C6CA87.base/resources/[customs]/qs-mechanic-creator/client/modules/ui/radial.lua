local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1
L0_1 = false
L1_1 = nil
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = {}
  if A1_2 then
    L3_2 = DoesEntityExist
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = GetVehicleNumberPlateText
      L4_2 = A1_2
      L3_2 = L3_2(L4_2)
      L2_2.plate = L3_2
      L3_2 = NetworkGetEntityIsNetworked
      L4_2 = A1_2
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L3_2 = NetworkGetNetworkIdFromEntity
        L4_2 = A1_2
        L3_2 = L3_2(L4_2)
        if L3_2 then
          goto lbl_25
        end
      end
      L3_2 = nil
      ::lbl_25::
      L2_2.vehicleNetId = L3_2
    end
  end
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:canPerformAction"
  L5_2 = false
  L6_2 = A0_2
  L7_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L4_2 = true == L3_2
  return L4_2
end
function L3_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L8_2 = PlayerPedId
  L8_2 = L8_2()
  L9_2 = GetPedBoneIndex
  L10_2 = L8_2
  L11_2 = A1_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = RequestModel
  L11_2 = A0_2
  L10_2(L11_2)
  while true do
    L10_2 = HasModelLoaded
    L11_2 = A0_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      break
    end
    L10_2 = Wait
    L11_2 = 10
    L10_2(L11_2)
  end
  L10_2 = CreateObject
  L11_2 = GetHashKey
  L12_2 = A0_2
  L11_2 = L11_2(L12_2)
  L12_2 = 0.0
  L13_2 = 0.0
  L14_2 = 0.0
  L15_2 = true
  L16_2 = true
  L17_2 = true
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L11_2 = AttachEntityToEntity
  L12_2 = L10_2
  L13_2 = L8_2
  L14_2 = L9_2
  L15_2 = A2_2
  L16_2 = A3_2
  L17_2 = A4_2
  L18_2 = A5_2
  L19_2 = A6_2
  L20_2 = A7_2
  L21_2 = true
  L22_2 = true
  L23_2 = false
  L24_2 = true
  L25_2 = 1
  L26_2 = true
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L1_1 = L10_2
  return L10_2
end
function L4_1()
  local L0_2, L1_2
  L0_2 = L1_1
  if L0_2 then
    L0_2 = DeleteObject
    L1_2 = L1_1
    L0_2(L1_2)
    L0_2 = nil
    L1_1 = L0_2
  end
end
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = RequestAnimDict
  L4_2 = A0_2
  L3_2(L4_2)
  while true do
    L3_2 = HasAnimDictLoaded
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      break
    end
    L3_2 = Wait
    L4_2 = 10
    L3_2(L4_2)
  end
  L3_2 = TaskPlayAnim
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = 8.0
  L8_2 = -8.0
  L9_2 = A2_2
  L10_2 = 1
  L11_2 = 0
  L12_2 = false
  L13_2 = false
  L14_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
end
function L6_1()
  local L0_2, L1_2
  L0_2 = ClearPedTasks
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L0_2(L1_2)
  L0_2 = L4_1
  L0_2()
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L1_2 = DoesEntityExist
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L1_2 = GetVehicleNumberPlateText
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = Wait
  L3_2 = 100
  L2_2(L3_2)
  L2_2 = lib
  L2_2 = L2_2.getVehicleProperties
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = TriggerServerEvent
  L4_2 = "qs-mechanic-creator:server:saveRadialRepair"
  L5_2 = L1_2
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
end
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = GetVehiclePedIsIn
  L2_2 = L0_2
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if 0 ~= L1_2 then
    return L1_2
  end
  L2_2 = GetEntityCoords
  L3_2 = L0_2
  L2_2 = L2_2(L3_2)
  L3_2 = nil
  L4_2 = 10.0
  L5_2 = GetGamePool
  L6_2 = "CVehicle"
  L5_2 = L5_2(L6_2)
  L6_2 = ipairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    L12_2 = DoesEntityExist
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    if L12_2 then
      L12_2 = GetEntityCoords
      L13_2 = L11_2
      L12_2 = L12_2(L13_2)
      L13_2 = L2_2 - L12_2
      L13_2 = #L13_2
      if L4_2 > L13_2 then
        L4_2 = L13_2
        L3_2 = L11_2
      end
    end
  end
  return L3_2
end
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = Config
  L2_2 = L2_2.RadialItemRequirements
  L2_2 = L2_2.enabled
  if not L2_2 then
    L2_2 = true
    return L2_2
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "qs-mechanic-creator:server:hasItem"
  L4_2 = false
  L5_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if not L2_2 then
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "MISSING_ITEM"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "MISSING_ITEM_DESC"
    L7_2 = A0_2
    L5_2 = L5_2(L6_2, L7_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
    L3_2 = false
    return L3_2
  end
  if A1_2 then
    L3_2 = Config
    L3_2 = L3_2.RadialItemRequirements
    L3_2 = L3_2.consumeItems
    if L3_2 then
      L3_2 = TriggerServerEvent
      L4_2 = "qs-mechanic-creator:server:removeItem"
      L5_2 = A0_2
      L6_2 = 1
      L3_2(L4_2, L5_2, L6_2)
    end
  end
  L3_2 = true
  return L3_2
end
function L10_1(A0_2)
  local L1_2
  L1_2 = Config
  L1_2 = L1_2.RadialActions
  if not L1_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = Config
  L1_2 = L1_2.RadialActions
  L1_2 = L1_2[A0_2]
  L1_2 = false ~= L1_2
  return L1_2
end
function L11_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  L1_2 = L8_1
  L1_2 = L1_2()
  if L1_2 then
    L2_2 = L10_1
    L3_2 = "wash_vehicle"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "wash_vehicle"
      L4_2.titleKey = "RADIAL_WASH_VEHICLE"
      L4_2.icon = "fas fa-shower"
      L2_2(L3_2, L4_2)
    end
    L2_2 = L10_1
    L3_2 = "engine_repair"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "engine_repair"
      L4_2.titleKey = "ENGINE_REPAIR"
      L4_2.icon = "fas fa-cog"
      L2_2(L3_2, L4_2)
    end
    L2_2 = L10_1
    L3_2 = "body_repair"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "body_repair"
      L4_2.titleKey = "BODY_REPAIR"
      L4_2.icon = "fas fa-car-crash"
      L2_2(L3_2, L4_2)
    end
    L2_2 = L10_1
    L3_2 = "full_repair"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "full_repair"
      L4_2.titleKey = "FULL_REPAIR"
      L4_2.icon = "fas fa-wrench"
      L2_2(L3_2, L4_2)
    end
    L2_2 = L10_1
    L3_2 = "flip_vehicle"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "flip_vehicle"
      L4_2.titleKey = "RADIAL_FLIP_VEHICLE"
      L4_2.icon = "fas fa-undo"
      L2_2(L3_2, L4_2)
    end
    L2_2 = L10_1
    L3_2 = "fuel_vehicle"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = table
      L2_2 = L2_2.insert
      L3_2 = L0_2
      L4_2 = {}
      L4_2.action = "fuel_vehicle"
      L4_2.titleKey = "RADIAL_FUEL_VEHICLE"
      L4_2.icon = "fas fa-gas-pump"
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = L10_1
  L3_2 = "tow_vehicle"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = L0_2
    L4_2 = {}
    L4_2.action = "tow_vehicle"
    L4_2.titleKey = "RADIAL_TOW_VEHICLE"
    L4_2.icon = "fas fa-link"
    L2_2(L3_2, L4_2)
  end
  L2_2 = L10_1
  L3_2 = "manage_flatbed"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = IsNearFlatbed
    if L2_2 then
      L2_2 = IsNearFlatbed
      L2_2 = L2_2()
      if L2_2 then
        L2_2 = table
        L2_2 = L2_2.insert
        L3_2 = L0_2
        L4_2 = {}
        L4_2.action = "manage_flatbed"
        L4_2.titleKey = "RADIAL_FLATBED"
        L4_2.icon = "fas fa-truck-loading"
        L2_2(L3_2, L4_2)
      end
    end
  end
  L2_2 = L10_1
  L3_2 = "billing"
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = table
    L2_2 = L2_2.insert
    L3_2 = L0_2
    L4_2 = {}
    L4_2.action = "billing"
    L4_2.titleKey = "RADIAL_BILLING"
    L4_2.icon = "fas fa-file-invoice-dollar"
    L2_2(L3_2, L4_2)
  end
  return L0_2
end
L12_1 = 0
L13_1 = 300
function L14_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = Config
  L0_2 = L0_2.UseRadial
  if not L0_2 then
    return
  end
  L0_2 = L0_1
  if L0_2 then
    return
  end
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L1_2 = L12_1
  L1_2 = L0_2 - L1_2
  L2_2 = L13_1
  if L1_2 < L2_2 then
    return
  end
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = IsPedInAnyVehicle
  L3_2 = L1_2
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = GetVehiclePedIsIn
    L3_2 = L1_2
    L4_2 = false
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = GetVehicleClass
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if 14 ~= L3_2 and 15 ~= L3_2 and 16 ~= L3_2 then
      return
    end
  end
  L2_2 = getPlayerData
  L2_2 = L2_2()
  if L2_2 then
    L3_2 = L2_2.job
    if L3_2 then
      L3_2 = L2_2.license
      if L3_2 then
        goto lbl_52
      end
    end
  end
  do return end
  ::lbl_52::
  L3_2 = lib
  L3_2 = L3_2.callback
  L4_2 = "qs-mechanic-creator:server:checkRadialAccess"
  L5_2 = false
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    if not A0_3 then
      return
    end
    L1_3 = L11_1
    L1_3 = L1_3()
    L2_3 = #L1_3
    if 0 == L2_3 then
      L2_3 = showClientNotification
      L3_3 = {}
      L4_3 = _U
      L5_3 = "NO_VEHICLE"
      L4_3 = L4_3(L5_3)
      L3_3.title = L4_3
      L4_3 = _U
      L5_3 = "RADIAL_NO_VEHICLE_NEARBY"
      L4_3 = L4_3(L5_3)
      L3_3.description = L4_3
      L3_3.type = "error"
      L2_3(L3_3)
      return
    end
    L2_3 = true
    L0_1 = L2_3
    L2_3 = Wait
    L3_3 = 50
    L2_3(L3_3)
    L2_3 = SendNUIMessage
    L3_3 = {}
    L3_3.action = "openRadial"
    L4_3 = GetLocales
    L4_3 = L4_3()
    L3_3.locales = L4_3
    L3_3.availableActions = L1_3
    L2_3(L3_3)
    L2_3 = Wait
    L3_3 = 50
    L2_3(L3_3)
    L2_3 = SetNuiFocus
    L3_3 = true
    L4_3 = true
    L2_3(L3_3, L4_3)
  end
  L3_2(L4_2, L5_2, L6_2)
end
L15_1 = RegisterCommand
L16_1 = "mechanic_radial"
function L17_1()
  local L0_2, L1_2
  L0_2 = L14_1
  L0_2()
end
L18_1 = false
L15_1(L16_1, L17_1, L18_1)
function L15_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L0_1 = L0_2
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L12_1 = L0_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = Wait
  L1_2 = 50
  L0_2(L1_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "closeRadial"
  L0_2(L1_2)
end
function L16_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L9_1
  L2_2 = Config
  L2_2 = L2_2.RadialItemRequirements
  L2_2 = L2_2.items
  L2_2 = L2_2.repairkit
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = L2_1
  L2_2 = "repair"
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = showClientNotification
  L2_2 = {}
  L3_2 = _U
  L4_2 = "FULL_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "RADIAL_STARTING_FULL_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
  L1_2 = L5_1
  L2_2 = "mini@repair"
  L3_2 = "fixing_a_player"
  L4_2 = -1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = PerformRadialSkillCheck
  L2_2 = "FullRepair"
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L2_2()
  if L1_2 then
    L2_2 = Config
    L2_2 = L2_2.RadialItemRequirements
    L2_2 = L2_2.enabled
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.RadialItemRequirements
      L2_2 = L2_2.consumeItems
      if L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "qs-mechanic-creator:server:removeItem"
        L4_2 = Config
        L4_2 = L4_2.RadialItemRequirements
        L4_2 = L4_2.items
        L4_2 = L4_2.repairkit
        L5_2 = 1
        L2_2(L3_2, L4_2, L5_2)
      end
    end
    L2_2 = fixVehicleDeformation
    L3_2 = L0_2
    L2_2(L3_2)
    L2_2 = SetVehicleEngineHealth
    L3_2 = L0_2
    L4_2 = 1000.0
    L2_2(L3_2, L4_2)
    L2_2 = SetVehicleBodyHealth
    L3_2 = L0_2
    L4_2 = 1000.0
    L2_2(L3_2, L4_2)
    L2_2 = SetVehiclePetrolTankHealth
    L3_2 = L0_2
    L4_2 = 1000.0
    L2_2(L3_2, L4_2)
    L2_2 = SetVehicleUndriveable
    L3_2 = L0_2
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = SetVehicleEngineOn
    L3_2 = L0_2
    L4_2 = true
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = 0
    L3_2 = 7
    L4_2 = 1
    for L5_2 = L2_2, L3_2, L4_2 do
      L6_2 = SetVehicleTyreFixed
      L7_2 = L0_2
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
    L2_2 = 0
    L3_2 = 7
    L4_2 = 1
    for L5_2 = L2_2, L3_2, L4_2 do
      L6_2 = FixVehicleWindow
      L7_2 = L0_2
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
    L2_2 = GetDisplayNameFromVehicleModel
    L3_2 = GetEntityModel
    L4_2 = L0_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L3_2 = TriggerServerEvent
    L4_2 = "qs-mechanic-creator:server:logFullRepair"
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L3_2 = L7_1
    L4_2 = L0_2
    L3_2(L4_2)
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "REPAIR_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_VEHICLE_FULLY_REPAIRED"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "success"
    L3_2(L4_2)
  else
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "REPAIR_FAILED"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_FAILED_REPAIR_PROCESS"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
  end
end
function L17_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L9_1
  L2_2 = Config
  L2_2 = L2_2.RadialItemRequirements
  L2_2 = L2_2.items
  L2_2 = L2_2.repairkit
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = L2_1
  L2_2 = "bodyRepair"
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = showClientNotification
  L2_2 = {}
  L3_2 = _U
  L4_2 = "BODY_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "RADIAL_STARTING_BODY_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
  L1_2 = L5_1
  L2_2 = "mini@repair"
  L3_2 = "fixing_a_player"
  L4_2 = -1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = PerformRadialSkillCheck
  L2_2 = "BodyRepair"
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L2_2()
  if L1_2 then
    L2_2 = Config
    L2_2 = L2_2.RadialItemRequirements
    L2_2 = L2_2.enabled
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.RadialItemRequirements
      L2_2 = L2_2.consumeItems
      if L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "qs-mechanic-creator:server:removeItem"
        L4_2 = Config
        L4_2 = L4_2.RadialItemRequirements
        L4_2 = L4_2.items
        L4_2 = L4_2.repairkit
        L5_2 = 1
        L2_2(L3_2, L4_2, L5_2)
      end
    end
    L2_2 = fixVehicleDeformation
    L3_2 = L0_2
    L2_2(L3_2)
    L2_2 = SetVehicleBodyHealth
    L3_2 = L0_2
    L4_2 = 1000.0
    L2_2(L3_2, L4_2)
    L2_2 = 0
    L3_2 = 7
    L4_2 = 1
    for L5_2 = L2_2, L3_2, L4_2 do
      L6_2 = FixVehicleWindow
      L7_2 = L0_2
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
    L2_2 = GetDisplayNameFromVehicleModel
    L3_2 = GetEntityModel
    L4_2 = L0_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L3_2 = TriggerServerEvent
    L4_2 = "qs-mechanic-creator:server:logBodyRepair"
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L3_2 = L7_1
    L4_2 = L0_2
    L3_2(L4_2)
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "RADIAL_BODY_REPAIR_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_BODY_REPAIR_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "success"
    L3_2(L4_2)
  else
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "REPAIR_FAILED"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_FAILED_BODY_REPAIR"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
  end
end
function L18_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L9_1
  L2_2 = Config
  L2_2 = L2_2.RadialItemRequirements
  L2_2 = L2_2.items
  L2_2 = L2_2.repairkit
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = L2_1
  L2_2 = "engineRepair"
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = showClientNotification
  L2_2 = {}
  L3_2 = _U
  L4_2 = "ENGINE_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "RADIAL_STARTING_ENGINE_REPAIR"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
  L1_2 = L5_1
  L2_2 = "mini@repair"
  L3_2 = "fixing_a_player"
  L4_2 = -1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = PerformRadialSkillCheck
  L2_2 = "EngineRepair"
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L2_2()
  if L1_2 then
    L2_2 = Config
    L2_2 = L2_2.RadialItemRequirements
    L2_2 = L2_2.enabled
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.RadialItemRequirements
      L2_2 = L2_2.consumeItems
      if L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "qs-mechanic-creator:server:removeItem"
        L4_2 = Config
        L4_2 = L4_2.RadialItemRequirements
        L4_2 = L4_2.items
        L4_2 = L4_2.repairkit
        L5_2 = 1
        L2_2(L3_2, L4_2, L5_2)
      end
    end
    L2_2 = SetVehicleEngineHealth
    L3_2 = L0_2
    L4_2 = 1000.0
    L2_2(L3_2, L4_2)
    L2_2 = SetVehicleUndriveable
    L3_2 = L0_2
    L4_2 = false
    L2_2(L3_2, L4_2)
    L2_2 = SetVehicleEngineOn
    L3_2 = L0_2
    L4_2 = true
    L5_2 = true
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = GetDisplayNameFromVehicleModel
    L3_2 = GetEntityModel
    L4_2 = L0_2
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
    L3_2 = TriggerServerEvent
    L4_2 = "qs-mechanic-creator:server:logEngineRepair"
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L3_2 = L7_1
    L4_2 = L0_2
    L3_2(L4_2)
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "RADIAL_ENGINE_REPAIR_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_ENGINE_REPAIR_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "success"
    L3_2(L4_2)
  else
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "REPAIR_FAILED"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_FAILED_ENGINE_REPAIR"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
  end
end
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L9_1
  L2_2 = Config
  L2_2 = L2_2.RadialItemRequirements
  L2_2 = L2_2.items
  L2_2 = L2_2.sponge
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = L2_1
  L2_2 = "wash"
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = showClientNotification
  L2_2 = {}
  L3_2 = _U
  L4_2 = "RADIAL_STARTING_VEHICLE_WASH"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "RADIAL_STARTING_VEHICLE_WASH"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
  L1_2 = L3_1
  L2_2 = "prop_rag_01"
  L3_2 = 28422
  L4_2 = 0.0
  L5_2 = 0.0
  L6_2 = -0.01
  L7_2 = 0.0
  L8_2 = 0.0
  L9_2 = 0.0
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L1_2 = L5_1
  L2_2 = "timetable@floyd@clean_kitchen@base"
  L3_2 = "base"
  L4_2 = -1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = PerformRadialSkillCheck
  L2_2 = "WashVehicle"
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L2_2()
  if L1_2 then
    L2_2 = Config
    L2_2 = L2_2.RadialItemRequirements
    L2_2 = L2_2.enabled
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.RadialItemRequirements
      L2_2 = L2_2.consumeItems
      if L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "qs-mechanic-creator:server:removeItem"
        L4_2 = Config
        L4_2 = L4_2.RadialItemRequirements
        L4_2 = L4_2.items
        L4_2 = L4_2.sponge
        L5_2 = 1
        L2_2(L3_2, L4_2, L5_2)
      end
    end
    L2_2 = SetVehicleDirtLevel
    L3_2 = L0_2
    L4_2 = 0.0
    L2_2(L3_2, L4_2)
    L2_2 = GetDisplayNameFromVehicleModel
    L3_2 = GetEntityModel
    L4_2 = L0_2
    L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L3_2 = TriggerServerEvent
    L4_2 = "qs-mechanic-creator:server:logVehicleWashed"
    L5_2 = L2_2
    L3_2(L4_2, L5_2)
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "RADIAL_WASH_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_WASH_COMPLETE"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "success"
    L3_2(L4_2)
  else
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "RADIAL_FAILED_VEHICLE_WASH"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_FAILED_VEHICLE_WASH"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
  end
end
function L20_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L2_1
  L2_2 = "flip"
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    return
  end
  L1_2 = showClientNotification
  L2_2 = {}
  L3_2 = _U
  L4_2 = "RADIAL_FLIPPING_VEHICLE"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "RADIAL_FLIPPING_VEHICLE"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
  L1_2 = L5_1
  L2_2 = "missfinale_c2ig_11"
  L3_2 = "pushcar_offcliff_f"
  L4_2 = -1
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = PerformRadialSkillCheck
  L2_2 = "FlipVehicle"
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L2_2()
  if L1_2 then
    L2_2 = GetEntityCoords
    L3_2 = L0_2
    L2_2 = L2_2(L3_2)
    L3_2 = GetEntityHeading
    L4_2 = L0_2
    L3_2 = L3_2(L4_2)
    L4_2 = SetEntityCoords
    L5_2 = L0_2
    L6_2 = L2_2.x
    L7_2 = L2_2.y
    L8_2 = L2_2.z
    L8_2 = L8_2 + 1.0
    L9_2 = false
    L10_2 = false
    L11_2 = false
    L12_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L4_2 = SetEntityRotation
    L5_2 = L0_2
    L6_2 = 0.0
    L7_2 = 0.0
    L8_2 = L3_2
    L9_2 = 2
    L10_2 = true
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = GetDisplayNameFromVehicleModel
    L5_2 = GetEntityModel
    L6_2 = L0_2
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L5_2(L6_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L5_2 = TriggerServerEvent
    L6_2 = "qs-mechanic-creator:server:logVehicleFlipped"
    L7_2 = L4_2
    L5_2(L6_2, L7_2)
    L5_2 = showClientNotification
    L6_2 = {}
    L7_2 = _U
    L8_2 = "RADIAL_VEHICLE_FLIPPED"
    L7_2 = L7_2(L8_2)
    L6_2.title = L7_2
    L7_2 = _U
    L8_2 = "RADIAL_VEHICLE_FLIPPED"
    L7_2 = L7_2(L8_2)
    L6_2.description = L7_2
    L6_2.type = "success"
    L5_2(L6_2)
  else
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "RADIAL_FLIP_FAILED"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_FLIP_FAILED"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
  end
end
function L21_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = L8_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "NO_VEHICLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = Config
  L1_2 = L1_2.RadialItemRequirements
  L1_2 = L1_2.items
  L1_2 = L1_2.fuel
  if not L1_2 then
    L1_2 = "weapon_petrolcan"
  end
  L2_2 = L9_1
  L3_2 = L1_2
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    return
  end
  L2_2 = L2_1
  L3_2 = "fuel"
  L4_2 = L0_2
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    return
  end
  L2_2 = showClientNotification
  L3_2 = {}
  L4_2 = _U
  L5_2 = "RADIAL_REFUELING"
  L4_2 = L4_2(L5_2)
  L3_2.title = L4_2
  L4_2 = _U
  L5_2 = "RADIAL_REFUELING"
  L4_2 = L4_2(L5_2)
  L3_2.description = L4_2
  L3_2.type = "info"
  L2_2(L3_2)
  L2_2 = L3_1
  L3_2 = "prop_jerrycan_01a"
  L4_2 = 57005
  L5_2 = 0.15
  L6_2 = 0.11
  L7_2 = -0.01
  L8_2 = -140.0
  L9_2 = -8.0
  L10_2 = 12.0
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L2_2 = L5_1
  L3_2 = "weapon@w_sp_jerrycan"
  L4_2 = "fire"
  L5_2 = -1
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = PerformRadialSkillCheck
  L3_2 = "FuelVehicle"
  L2_2 = L2_2(L3_2)
  L3_2 = L6_1
  L3_2()
  if L2_2 then
    L3_2 = Config
    L3_2 = L3_2.RadialItemRequirements
    L3_2 = L3_2.enabled
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.RadialItemRequirements
      L3_2 = L3_2.consumeItems
      if L3_2 then
        L3_2 = TriggerServerEvent
        L4_2 = "qs-mechanic-creator:server:removeItem"
        L5_2 = L1_2
        L6_2 = 1
        L3_2(L4_2, L5_2, L6_2)
      end
    end
    L3_2 = refuelVehicle
    L4_2 = L0_2
    L3_2(L4_2)
    L3_2 = GetDisplayNameFromVehicleModel
    L4_2 = GetEntityModel
    L5_2 = L0_2
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2(L5_2)
    L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = TriggerServerEvent
    L5_2 = "qs-mechanic-creator:server:logVehicleRefueled"
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
    L4_2 = showClientNotification
    L5_2 = {}
    L6_2 = _U
    L7_2 = "RADIAL_FUEL_COMPLETE"
    L6_2 = L6_2(L7_2)
    L5_2.title = L6_2
    L6_2 = _U
    L7_2 = "RADIAL_FUEL_COMPLETE"
    L6_2 = L6_2(L7_2)
    L5_2.description = L6_2
    L5_2.type = "success"
    L4_2(L5_2)
  else
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "RADIAL_REFUEL_FAILED"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_REFUEL_FAILED"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
  end
end
L22_1 = nil
function L23_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = L22_1
  if L0_2 then
    return
  end
  L0_2 = lib
  L0_2 = L0_2.addKeybind
  L1_2 = {}
  L1_2.name = "mechanic_radial"
  L2_2 = _U
  L3_2 = "RADIAL_MENU"
  L2_2 = L2_2(L3_2)
  L1_2.description = L2_2
  L2_2 = Config
  L2_2 = L2_2.RadialKey
  L1_2.defaultKey = L2_2
  function L2_2(A0_3)
    local L1_3
    L1_3 = L14_1
    L1_3()
  end
  L1_2.onPressed = L2_2
  L0_2 = L0_2(L1_2)
  L22_1 = L0_2
end
L24_1 = RegisterNUICallback
L25_1 = "radial_action"
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = false
  L0_1 = L2_2
  L2_2 = A0_2.action
  if "full_repair" == L2_2 then
    L2_2 = L16_1
    L2_2()
  else
    L2_2 = A0_2.action
    if "body_repair" == L2_2 then
      L2_2 = L17_1
      L2_2()
    else
      L2_2 = A0_2.action
      if "engine_repair" == L2_2 then
        L2_2 = L18_1
        L2_2()
      else
        L2_2 = A0_2.action
        if "wash_vehicle" == L2_2 then
          L2_2 = L19_1
          L2_2()
        else
          L2_2 = A0_2.action
          if "flip_vehicle" == L2_2 then
            L2_2 = L20_1
            L2_2()
          else
            L2_2 = A0_2.action
            if "fuel_vehicle" == L2_2 then
              L2_2 = L21_1
              L2_2()
            else
              L2_2 = A0_2.action
              if "tow_vehicle" == L2_2 then
                L2_2 = StartTowing
                L2_2()
              else
                L2_2 = A0_2.action
                if "manage_flatbed" == L2_2 then
                  L2_2 = StartFlatbedManagement
                  if L2_2 then
                    L2_2 = StartFlatbedManagement
                    L2_2()
                  end
                else
                  L2_2 = A0_2.action
                  if "billing" == L2_2 then
                    L2_2 = OpenBillingMenu
                    if L2_2 then
                      L2_2 = lib
                      L2_2 = L2_2.callback
                      L3_2 = "qs-mechanic-creator:server:getPlayerShopData"
                      L4_2 = false
                      function L5_2(A0_3, A1_3)
                        local L2_3, L3_3, L4_3, L5_3
                        if A0_3 and A1_3 then
                          L2_3 = OpenBillingMenu
                          L3_3 = A0_3
                          L4_3 = A1_3
                          L2_3(L3_3, L4_3)
                        else
                          L2_3 = showClientNotification
                          L3_3 = {}
                          L4_3 = _U
                          L5_3 = "BILLING"
                          L4_3 = L4_3(L5_3)
                          if not L4_3 then
                            L4_3 = "Billing"
                          end
                          L3_3.title = L4_3
                          L4_3 = _U
                          L5_3 = "NO_SHOP_ACCESS"
                          L4_3 = L4_3(L5_3)
                          if not L4_3 then
                            L4_3 = "You do not have access to any shop"
                          end
                          L3_3.description = L4_3
                          L3_3.type = "error"
                          L2_3(L3_3)
                        end
                      end
                      L2_2(L3_2, L4_2, L5_2)
                    else
                      L2_2 = showClientNotification
                      L3_2 = {}
                      L4_2 = _U
                      L5_2 = "BILLING"
                      L4_2 = L4_2(L5_2)
                      if not L4_2 then
                        L4_2 = "Billing"
                      end
                      L3_2.title = L4_2
                      L4_2 = _U
                      L5_2 = "BILLING_NOT_CONFIGURED"
                      L4_2 = L4_2(L5_2)
                      if not L4_2 then
                        L4_2 = "Billing system not configured"
                      end
                      L3_2.description = L4_2
                      L3_2.type = "error"
                      L2_2(L3_2)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
L24_1(L25_1, L26_1)
L24_1 = RegisterNUICallback
L25_1 = "close_radial"
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = false
  L0_1 = L2_2
end
L24_1(L25_1, L26_1)
L24_1 = CreateThread
function L25_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 2000
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "qs-mechanic-creator:server:requestPlayerData"
  L0_2(L1_2)
  L0_2 = Config
  L0_2 = L0_2.UseRadial
  if L0_2 then
    L0_2 = L23_1
    L0_2()
  end
end
L24_1(L25_1)
L24_1 = exports
L25_1 = "PerformFullRepair"
L26_1 = L16_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "PerformBodyRepair"
L26_1 = L17_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "PerformEngineRepair"
L26_1 = L18_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "WashVehicle"
L26_1 = L19_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "FlipVehicle"
L26_1 = L20_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "FuelVehicle"
L26_1 = L21_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "OpenRadialMenu"
L26_1 = L14_1
L24_1(L25_1, L26_1)
L24_1 = exports
L25_1 = "CloseRadialMenu"
L26_1 = L15_1
L24_1(L25_1, L26_1)
