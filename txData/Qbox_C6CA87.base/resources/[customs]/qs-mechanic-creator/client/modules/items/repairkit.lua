local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
function L0_1()
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
function L1_1(A0_2, A1_2, A2_2)
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
function L2_1()
  local L0_2, L1_2
  L0_2 = ClearPedTasks
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L0_2(L1_2)
end
L3_1 = RegisterNetEvent
L4_1 = "qs-mechanic-creator:client:useRepairKit"
function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = IsPedInAnyVehicle
  L2_2 = L0_2
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L3_2 = _U
    L4_2 = "ERROR"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "CANNOT_USE_IN_VEHICLE"
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = "You cannot use this item while inside a vehicle"
    end
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L0_1
  L1_2 = L1_2()
  if not L1_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = _U
    L5_2 = "NO_VEHICLE"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "RADIAL_NO_VEHICLE_NEARBY"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
    return
  end
  L2_2 = showClientNotification
  L3_2 = {}
  L4_2 = _U
  L5_2 = "FULL_REPAIR"
  L4_2 = L4_2(L5_2)
  L3_2.title = L4_2
  L4_2 = _U
  L5_2 = "RADIAL_STARTING_FULL_REPAIR"
  L4_2 = L4_2(L5_2)
  L3_2.description = L4_2
  L3_2.type = "info"
  L2_2(L3_2)
  L2_2 = L1_1
  L3_2 = "mini@repair"
  L4_2 = "fixing_a_player"
  L5_2 = -1
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = PerformRadialSkillCheck
  L3_2 = "FullRepair"
  L2_2 = L2_2(L3_2)
  L3_2 = L2_1
  L3_2()
  if L2_2 then
    L3_2 = TriggerServerEvent
    L4_2 = "qs-mechanic-creator:server:confirmItemUse"
    L5_2 = "repairkit"
    L3_2(L4_2, L5_2)
    L3_2 = fixVehicleDeformation
    L4_2 = L1_2
    L3_2(L4_2)
    L3_2 = SetVehicleEngineHealth
    L4_2 = L1_2
    L5_2 = 1000.0
    L3_2(L4_2, L5_2)
    L3_2 = SetVehicleBodyHealth
    L4_2 = L1_2
    L5_2 = 1000.0
    L3_2(L4_2, L5_2)
    L3_2 = SetVehiclePetrolTankHealth
    L4_2 = L1_2
    L5_2 = 1000.0
    L3_2(L4_2, L5_2)
    L3_2 = SetVehicleUndriveable
    L4_2 = L1_2
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = SetVehicleEngineOn
    L4_2 = L1_2
    L5_2 = true
    L6_2 = true
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = 0
    L4_2 = 7
    L5_2 = 1
    for L6_2 = L3_2, L4_2, L5_2 do
      L7_2 = SetVehicleTyreFixed
      L8_2 = L1_2
      L9_2 = L6_2
      L7_2(L8_2, L9_2)
    end
    L3_2 = 0
    L4_2 = 7
    L5_2 = 1
    for L6_2 = L3_2, L4_2, L5_2 do
      L7_2 = FixVehicleWindow
      L8_2 = L1_2
      L9_2 = L6_2
      L7_2(L8_2, L9_2)
    end
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
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "REPAIR_FAILED"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "RADIAL_FAILED_REPAIR_PROCESS"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
  end
end
L3_1(L4_1, L5_1)
