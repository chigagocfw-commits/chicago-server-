local L0_1, L1_1, L2_1
L0_1 = RegisterNetEvent
L1_1 = "qs-mechanic-creator:client:useRope"
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
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
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:confirmItemUse"
  L3_2 = "rope"
  L1_2(L2_2, L3_2)
  L1_2 = StartTowing
  L1_2()
end
L0_1(L1_1, L2_1)
