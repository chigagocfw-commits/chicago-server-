local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = {}
L1_1 = nil
function L2_1(A0_2)
  local L1_2
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = L0_1
    L1_2[A0_2] = false
  end
end
function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = L0_1
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = L0_1
    L6_2[L4_2] = false
  end
  L0_2 = {}
  L0_1 = L0_2
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2
  if not A0_2 or 0 == A0_2 then
    return
  end
  L1_1 = A0_2
  L1_2 = TriggerEvent
  L2_2 = "qs-mechanic:client:startHeatedBrakes"
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = TriggerEvent
  L2_2 = "qs-mechanic:client:startWheelDamage"
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = TriggerEvent
  L2_2 = "qs-mechanic:client:startOffroad"
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
end
function L5_1()
  local L0_2, L1_2
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic:client:stopHeatedBrakes"
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic:client:stopWheelDamage"
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic:client:stopOffroad"
  L0_2(L1_2)
  L0_2 = L3_1
  L0_2()
  L0_2 = nil
  L1_1 = L0_2
end
L6_1 = lib
if L6_1 then
  L6_1 = lib
  L6_1 = L6_1.onCache
  L7_1 = "vehicle"
  function L8_1(A0_2)
    local L1_2, L2_2
    if A0_2 then
      L1_2 = L4_1
      L2_2 = A0_2
      L1_2(L2_2)
    else
      L1_2 = L5_1
      L1_2()
    end
  end
  L6_1(L7_1, L8_1)
  L6_1 = CreateThread
  function L7_1()
    local L0_2, L1_2, L2_2, L3_2
    while true do
      L0_2 = lib
      if L0_2 then
        break
      end
      L0_2 = Wait
      L1_2 = 100
      L0_2(L1_2)
    end
    L0_2 = Wait
    L1_2 = 3000
    L0_2(L1_2)
    L0_2 = PlayerPedId
    L0_2 = L0_2()
    L1_2 = IsPedInAnyVehicle
    L2_2 = L0_2
    L3_2 = false
    L1_2 = L1_2(L2_2, L3_2)
    if L1_2 then
      L1_2 = GetVehiclePedIsIn
      L2_2 = L0_2
      L3_2 = false
      L1_2 = L1_2(L2_2, L3_2)
      if 0 ~= L1_2 then
        L2_2 = L4_1
        L3_2 = L1_2
        L2_2(L3_2)
      end
    end
  end
  L6_1(L7_1)
else
  L6_1 = CreateThread
  function L7_1()
    local L0_2, L1_2, L2_2, L3_2, L4_2
    L0_2 = nil
    while true do
      L1_2 = Wait
      L2_2 = 500
      L1_2(L2_2)
      L1_2 = PlayerPedId
      L1_2 = L1_2()
      L2_2 = GetVehiclePedIsIn
      L3_2 = L1_2
      L4_2 = false
      L2_2 = L2_2(L3_2, L4_2)
      if L2_2 ~= L0_2 then
        if 0 ~= L2_2 then
          L3_2 = L4_1
          L4_2 = L2_2
          L3_2(L4_2)
        else
          L3_2 = L5_1
          L3_2()
        end
        L0_2 = L2_2
      end
    end
  end
  L6_1(L7_1)
end
