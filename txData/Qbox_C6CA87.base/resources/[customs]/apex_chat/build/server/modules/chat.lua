local L0_1, L1_1, L2_1, L3_1, L4_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Shared
  if L1_2 then
    L1_2 = Shared
    L1_2 = L1_2.headMessage
    if L1_2 then
      goto lbl_10
    end
  end
  L1_2 = {}
  ::lbl_10::
  L2_2 = L1_2.timePerCharacter
  if not L2_2 then
    L2_2 = 180
  end
  L3_2 = L1_2.minTime
  if not L3_2 then
    L3_2 = 3200
  end
  L4_2 = L1_2.maxTime
  if not L4_2 then
    L4_2 = 7000
  end
  L5_2 = math
  L5_2 = L5_2.floor
  L6_2 = #A0_2
  L6_2 = L6_2 * L2_2
  L5_2 = L5_2(L6_2)
  if L3_2 > L5_2 then
    L5_2 = L3_2
  end
  if L4_2 < L5_2 then
    L5_2 = L4_2
  end
  return L5_2
end
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = TriggerClientEvent
  L4_2 = "apex_chat:headBubble"
  L5_2 = -1
  L6_2 = {}
  L6_2.source = A0_2
  L6_2.message = A1_2
  L6_2.type = A2_2
  L7_2 = L0_1
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L6_2.ms = L7_2
  L3_2(L4_2, L5_2, L6_2)
end
L2_1 = Config
L2_1 = L2_1.EnableMe
if L2_1 then
  L2_1 = RegisterCommand
  L3_1 = Config
  L3_1 = L3_1.MeCommand
  function L4_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
    L3_2 = string
    L3_2 = L3_2.len
    L4_2 = Config
    L4_2 = L4_2.MeCommand
    L3_2 = L3_2(L4_2)
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = L3_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L6_2 = L4_2
    L5_2 = L4_2.gsub
    L7_2 = "%s+"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "" ~= L5_2 then
      L5_2 = L1_1
      L6_2 = A0_2
      L8_2 = L4_2
      L7_2 = L4_2.gsub
      L9_2 = "^%s+"
      L10_2 = ""
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      L8_2 = "me"
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  L2_1(L3_1, L4_1)
end
L2_1 = Config
L2_1 = L2_1.EnableDo
if L2_1 then
  L2_1 = RegisterCommand
  L3_1 = Config
  L3_1 = L3_1.DoCommand
  function L4_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
    L3_2 = string
    L3_2 = L3_2.len
    L4_2 = Config
    L4_2 = L4_2.DoCommand
    L3_2 = L3_2(L4_2)
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = L3_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L6_2 = L4_2
    L5_2 = L4_2.gsub
    L7_2 = "%s+"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "" ~= L5_2 then
      L5_2 = L1_1
      L6_2 = A0_2
      L8_2 = L4_2
      L7_2 = L4_2.gsub
      L9_2 = "^%s+"
      L10_2 = ""
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      L8_2 = "do"
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  L2_1(L3_1, L4_1)
end
L2_1 = Config
L2_1 = L2_1.EnableTry
if L2_1 then
  L2_1 = RegisterCommand
  L3_1 = Config
  L3_1 = L3_1.TryCommand
  function L4_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
    L3_2 = string
    L3_2 = L3_2.len
    L4_2 = Config
    L4_2 = L4_2.TryCommand
    L3_2 = L3_2(L4_2)
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = L3_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = math
    L5_2 = L5_2.random
    L6_2 = 0
    L7_2 = 1
    L5_2 = L5_2(L6_2, L7_2)
    if 0 == L5_2 then
      return
    end
    L6_2 = L4_2
    L5_2 = L4_2.gsub
    L7_2 = "%s+"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "" ~= L5_2 then
      L5_2 = L1_1
      L6_2 = A0_2
      L8_2 = L4_2
      L7_2 = L4_2.gsub
      L9_2 = "^%s+"
      L10_2 = ""
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      L8_2 = "try"
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  L2_1(L3_1, L4_1)
end
