local L0_1, L1_1, L2_1, L3_1
L0_1 = {}
L1_1 = CreateThread
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  while true do
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
    L0_2 = PlayerPedId
    L0_2 = L0_2()
    L1_2 = GetVehiclePedIsIn
    L2_2 = L0_2
    L3_2 = false
    L1_2 = L1_2(L2_2, L3_2)
    if 0 ~= L1_2 then
      L2_2 = GetPedInVehicleSeat
      L3_2 = L1_2
      L4_2 = -1
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 == L0_2 then
        L2_2 = GetVehicleNumberPlateText
        L3_2 = L1_2
        L2_2 = L2_2(L3_2)
        L3_2 = L0_1
        L3_2 = L3_2[L2_2]
        if nil == L3_2 then
          L3_2 = L0_1
          L4_2 = lib
          L4_2 = L4_2.callback
          L4_2 = L4_2.await
          L5_2 = "qs-mechanic-creator:server:vehicleHasEngine"
          L6_2 = false
          L7_2 = L2_2
          L4_2 = L4_2(L5_2, L6_2, L7_2)
          L3_2[L2_2] = L4_2
        end
        L3_2 = L0_1
        L3_2 = L3_2[L2_2]
        if not L3_2 then
          L3_2 = SetVehicleEngineOn
          L4_2 = L1_2
          L5_2 = false
          L6_2 = true
          L7_2 = true
          L3_2(L4_2, L5_2, L6_2, L7_2)
          L3_2 = DisableControlAction
          L4_2 = 0
          L5_2 = 71
          L6_2 = true
          L3_2(L4_2, L5_2, L6_2)
          L3_2 = DisableControlAction
          L4_2 = 0
          L5_2 = 72
          L6_2 = true
          L3_2(L4_2, L5_2, L6_2)
        end
      end
    end
  end
end
L1_1(L2_1)
L1_1 = RegisterNetEvent
L2_1 = "qs-mechanic-creator:client:updateEngineStatus"
L1_1(L2_1)
L1_1 = AddEventHandler
L2_1 = "qs-mechanic-creator:client:updateEngineStatus"
function L3_1(A0_2, A1_2)
  local L2_2
  if A0_2 then
    L2_2 = L0_1
    L2_2[A0_2] = A1_2
  end
end
L1_1(L2_1, L3_1)
