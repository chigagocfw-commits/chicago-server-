local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1
L0_1 = 64
L1_1 = {}
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = type
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if "string" == L7_2 and "" ~= L6_2 then
      L8_2 = L6_2
      L7_2 = L6_2.sub
      L9_2 = 1
      L10_2 = 1
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      if "/" == L7_2 then
        L8_2 = L6_2
        L7_2 = L6_2.sub
        L9_2 = 2
        L7_2 = L7_2(L8_2, L9_2)
        if L7_2 then
          goto lbl_30
        end
      end
      L7_2 = L6_2
      ::lbl_30::
      L8_2 = ExecuteCommand
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
end
L3_1 = 1
L4_1 = L0_1
L5_1 = 1
for L6_1 = L3_1, L4_1, L5_1 do
  L7_1 = "apex_sc_%d"
  L8_1 = L7_1
  L7_1 = L7_1.format
  L9_1 = L6_1
  L7_1 = L7_1(L8_1, L9_1)
  L8_1 = RegisterCommand
  L9_1 = L7_1
  function L10_1()
    local L0_2, L1_2, L2_2
    L1_2 = L6_1
    L0_2 = L1_1
    L0_2 = L0_2[L1_2]
    if L0_2 then
      L1_2 = L2_1
      L2_2 = L0_2.commands
      L1_2(L2_2)
    end
  end
  L11_1 = false
  L8_1(L9_1, L10_1, L11_1)
  L8_1 = RegisterKeyMapping
  L9_1 = L7_1
  L10_1 = "Apex Chat shortcut #%d"
  L11_1 = L10_1
  L10_1 = L10_1.format
  L12_1 = L6_1
  L10_1 = L10_1(L11_1, L12_1)
  L11_1 = "keyboard"
  L12_1 = ""
  L8_1(L9_1, L10_1, L11_1, L12_1)
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L1_1 = L1_2
  if A0_2 then
    L1_2 = type
    L2_2 = A0_2.shortcuts
    L1_2 = L1_2(L2_2)
    if "table" == L1_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L1_2 = ipairs
  L2_2 = A0_2.shortcuts
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L0_1
    if L5_2 <= L7_2 then
      L7_2 = type
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if "table" == L7_2 then
        L7_2 = L1_1
        L8_2 = {}
        L9_2 = L6_2.commands
        if not L9_2 then
          L9_2 = {}
        end
        L8_2.commands = L9_2
        L7_2[L5_2] = L8_2
      end
    end
  end
end
L4_1 = AddEventHandler
L5_1 = "apex_chat:prefs:changed"
L6_1 = L3_1
L4_1(L5_1, L6_1)
L4_1 = CreateThread
function L5_1()
  local L0_2, L1_2, L2_2
  L0_2 = Wait
  L1_2 = 250
  L0_2(L1_2)
  L0_2 = ApexChat
  if L0_2 then
    L0_2 = ApexChat
    L0_2 = L0_2.GetPrefs
    if L0_2 then
      L0_2 = L3_1
      L1_2 = ApexChat
      L2_2 = L1_2
      L1_2 = L1_2.GetPrefs
      L1_2, L2_2 = L1_2(L2_2)
      L0_2(L1_2, L2_2)
    end
  end
end
L4_1(L5_1)
