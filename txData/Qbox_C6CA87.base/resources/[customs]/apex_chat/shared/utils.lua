local L0_1, L1_1
L0_1 = Utils
if not L0_1 then
  L0_1 = {}
end
Utils = L0_1
L0_1 = Utils
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L3_2 = A0_2
  L2_2 = A0_2.gsub
  L4_2 = "($%b{})"
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L2_3 = A0_3
    L1_3 = A0_3.sub
    L3_3 = 3
    L4_3 = -2
    L1_3 = L1_3(L2_3, L3_3, L4_3)
    L2_3 = A1_2
    L1_3 = L2_3[L1_3]
    if not L1_3 then
      L1_3 = A0_3
    end
    return L1_3
  end
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  return L2_2
end
L0_1.interp = L1_1
L0_1 = Utils
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = tonumber
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  if not A0_2 or A0_2 <= 0 then
    L1_2 = "00"
    return L1_2
  end
  L1_2 = string
  L1_2 = L1_2.format
  L2_2 = "%02.f"
  L3_2 = math
  L3_2 = L3_2.floor
  L4_2 = A0_2 / 3600
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L3_2(L4_2)
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "%02.f"
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = A0_2 / 60
  L6_2 = L1_2 * 60
  L5_2 = L5_2 - L6_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "%02.f"
  L5_2 = math
  L5_2 = L5_2.floor
  L6_2 = L1_2 * 3600
  L6_2 = A0_2 - L6_2
  L7_2 = L2_2 * 60
  L6_2 = L6_2 - L7_2
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L4_2 = L1_2
  L5_2 = ":"
  L6_2 = L2_2
  L7_2 = ":"
  L8_2 = L3_2
  L9_2 = Config
  L9_2 = L9_2.TimeOutMessages
  L9_2 = L9_2.hours
  L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2 .. L9_2
  if "00" == L1_2 then
    L5_2 = L2_2
    L6_2 = ":"
    L7_2 = L3_2
    L8_2 = Config
    L8_2 = L8_2.TimeOutMessages
    L8_2 = L8_2.minutes
    L5_2 = L5_2 .. L6_2 .. L7_2 .. L8_2
    L4_2 = L5_2
  end
  if "00" == L1_2 and "00" == L2_2 then
    L5_2 = math
    L5_2 = L5_2.floor
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.TimeOutMessages
    L6_2 = L6_2.seconds
    L5_2 = L5_2 .. L6_2
    L4_2 = L5_2
  end
  return L4_2
end
L0_1.SecondsToClock = L1_1
L0_1 = Utils
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  L1_2 = string
  L1_2 = L1_2.gsub
  L2_2 = L0_2
  L3_2 = "[xy]"
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    if "x" == A0_3 then
      L1_3 = math
      L1_3 = L1_3.random
      L2_3 = 0
      L3_3 = 15
      L1_3 = L1_3(L2_3, L3_3)
      if L1_3 then
        goto lbl_15
      end
    end
    L1_3 = math
    L1_3 = L1_3.random
    L2_3 = 8
    L3_3 = 11
    L1_3 = L1_3(L2_3, L3_3)
    ::lbl_15::
    L2_3 = string
    L2_3 = L2_3.format
    L3_3 = "%x"
    L4_3 = L1_3
    return L2_3(L3_3, L4_3)
  end
  return L1_2(L2_2, L3_2, L4_2)
end
L0_1.uuid = L1_1
L0_1 = Utils
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return A0_2
  end
  L1_2 = {}
  L2_2 = next
  L3_2 = A0_2
  L4_2 = nil
  L5_2 = nil
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = Utils
    L8_2 = L8_2.deepCopy
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L1_2[L6_2] = L8_2
  end
  return L1_2
end
L0_1.deepCopy = L1_1
L0_1 = Utils
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 then
    L2_2 = {}
    A0_2 = L2_2
  end
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return A0_2
  end
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = type
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if "table" == L8_2 then
      L8_2 = type
      L9_2 = A0_2[L6_2]
      L8_2 = L8_2(L9_2)
      if "table" == L8_2 then
        L8_2 = Utils
        L8_2 = L8_2.tableMerge
        L9_2 = A0_2[L6_2]
        L10_2 = L7_2
        L8_2 = L8_2(L9_2, L10_2)
        A0_2[L6_2] = L8_2
    end
    else
      A0_2[L6_2] = L7_2
    end
  end
  return A0_2
end
L0_1.tableMerge = L1_1
L0_1 = Utils
function L1_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L0_2 = Config
  L0_2 = L0_2.theme
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = #L1_2
    L8_2 = L8_2 + 1
    L9_2 = "--apex-%s:%s;"
    L10_2 = L9_2
    L9_2 = L9_2.format
    L11_2 = L6_2
    L12_2 = L7_2
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    L1_2[L8_2] = L9_2
  end
  L2_2 = table
  L2_2 = L2_2.concat
  L3_2 = L1_2
  return L2_2(L3_2)
end
L0_1.themeToCss = L1_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Utils
  L2_2 = L2_2.interp
  L3_2 = A0_2
  L4_2 = A1_2
  return L2_2(L3_2, L4_2)
end
interp = L0_1
function L0_1(A0_2)
  local L1_2, L2_2
  L1_2 = Utils
  L1_2 = L1_2.SecondsToClock
  L2_2 = A0_2
  return L1_2(L2_2)
end
SecondsToClock = L0_1
