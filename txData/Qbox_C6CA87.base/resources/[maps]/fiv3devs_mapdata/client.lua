local L0_1, L1_1
L0_1 = Citizen
L0_1 = L0_1.CreateThread
function L1_1()
  local L0_2, L1_2, L2_2
  L0_2 = LoadWaterFromPath
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  L2_2 = "water.xml"
  L0_2 = L0_2(L1_2, L2_2)
end
L0_1(L1_1)
