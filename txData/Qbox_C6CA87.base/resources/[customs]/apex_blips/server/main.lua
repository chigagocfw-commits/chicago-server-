local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1, L34_1, L35_1, L36_1, L37_1, L38_1, L39_1, L40_1, L41_1, L42_1, L43_1, L44_1, L45_1, L46_1, L47_1, L48_1, L49_1, L50_1, L51_1, L52_1, L53_1, L54_1, L55_1
L0_1 = GetCurrentResourceName
L0_1 = L0_1()
L1_1 = "data/blips.json"
L2_1 = 1
L3_1 = 500
L4_1 = 300
L5_1 = 1024
L6_1 = 256
L7_1 = 120
function L8_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = print
  L2_2 = "^5[apex_blips]^7 "
  L3_2 = A0_2
  L2_2 = L2_2 .. L3_2
  L1_2(L2_2)
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = print
  L2_2 = "^3[apex_blips]^7 "
  L3_2 = A0_2
  L2_2 = L2_2 .. L3_2
  L1_2(L2_2)
end
function L10_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = print
  L2_2 = "^1[apex_blips]^7 "
  L3_2 = A0_2
  L2_2 = L2_2 .. L3_2
  L1_2(L2_2)
end
function L11_1(A0_2)
  local L1_2, L2_2
  L1_2 = Config
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.debug
    if L1_2 then
      L1_2 = L8_1
      L2_2 = A0_2
      L1_2(L2_2)
    end
  end
end
function L12_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return A0_2
  end
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L12_1
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L1_2[L6_2] = L8_2
  end
  return L1_2
end
function L13_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2
  L4_2 = tonumber
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  A0_2 = L4_2
  if nil == A0_2 then
    return A3_2
  end
  if A1_2 > A0_2 then
    return A1_2
  end
  if A2_2 < A0_2 then
    return A2_2
  end
  return A0_2
end
function L14_1(A0_2)
  local L1_2, L2_2
  L1_2 = math
  L1_2 = L1_2.floor
  L2_2 = A0_2 * 10
  L2_2 = L2_2 + 0.5
  L1_2 = L1_2(L2_2)
  L1_2 = L1_2 / 10
  return L1_2
end
function L15_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = tonumber
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  A0_2 = L3_2
  if nil == A0_2 then
    return A2_2
  end
  L3_2 = 1
  L4_2 = #A1_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = A1_2[L6_2]
    if L7_2 == A0_2 then
      return A0_2
    end
  end
  return A2_2
end
function L16_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
    L2_2 = ""
    return L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.gsub
  L4_2 = "[%c]"
  L5_2 = " "
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "^%s+"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "%s+$"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  A0_2 = L2_2
  L2_2 = #A0_2
  if A1_2 < L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.sub
    L4_2 = 1
    L5_2 = A1_2
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    A0_2 = L2_2
  end
  return A0_2
end
L17_1 = {}
L18_1 = "es_extended"
L19_1 = "qbx_core"
L20_1 = "qb-core"
L17_1[1] = L18_1
L17_1[2] = L19_1
L17_1[3] = L20_1
L18_1 = nil
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = L18_1
  if nil ~= L0_2 then
    L0_2 = L18_1
    if false == L0_2 then
      L0_2 = nil
      return L0_2
    end
    L0_2 = L18_1
    return L0_2
  end
  L0_2 = 1
  L1_2 = L17_1
  L1_2 = #L1_2
  L2_2 = 1
  for L3_2 = L0_2, L1_2, L2_2 do
    L4_2 = GetResourceState
    L5_2 = L17_1
    L5_2 = L5_2[L3_2]
    L4_2 = L4_2(L5_2)
    if "started" == L4_2 or "starting" == L4_2 then
      L5_2 = L17_1
      L5_2 = L5_2[L3_2]
      L18_1 = L5_2
      L5_2 = L18_1
      return L5_2
    end
  end
  L0_2 = false
  L18_1 = L0_2
  L0_2 = nil
  return L0_2
end
function L20_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = L19_1
  L1_2 = L1_2()
  if nil == L1_2 then
    L2_2 = nil
    return L2_2
  end
  if "es_extended" == L1_2 then
    L2_2 = pcall
    function L3_2()
      local L0_3, L1_3
      L0_3 = exports
      L0_3 = L0_3.es_extended
      L1_3 = L0_3
      L0_3 = L0_3.getSharedObject
      L0_3 = L0_3(L1_3)
      L0_3 = L0_3.GetPlayerFromId
      L1_3 = A0_2
      return L0_3(L1_3)
    end
    L2_2, L3_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = type
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L4_2 = type
        L5_2 = L3_2.job
        L4_2 = L4_2(L5_2)
        if "table" == L4_2 then
          L4_2 = type
          L5_2 = L3_2.job
          L5_2 = L5_2.name
          L4_2 = L4_2(L5_2)
          if "string" == L4_2 then
            L4_2 = L3_2.job
            L4_2 = L4_2.name
            L5_2 = L4_2
            L4_2 = L4_2.lower
            return L4_2(L5_2)
          end
        end
      end
    end
  elseif "qbx_core" == L1_2 then
    L2_2 = pcall
    function L3_2()
      local L0_3, L1_3, L2_3
      L0_3 = exports
      L0_3 = L0_3.qbx_core
      L1_3 = L0_3
      L0_3 = L0_3.GetPlayer
      L2_3 = A0_2
      return L0_3(L1_3, L2_3)
    end
    L2_2, L3_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = type
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L4_2 = type
        L5_2 = L3_2.PlayerData
        L4_2 = L4_2(L5_2)
        if "table" == L4_2 then
          L4_2 = type
          L5_2 = L3_2.PlayerData
          L5_2 = L5_2.job
          L4_2 = L4_2(L5_2)
          if "table" == L4_2 then
            L4_2 = type
            L5_2 = L3_2.PlayerData
            L5_2 = L5_2.job
            L5_2 = L5_2.name
            L4_2 = L4_2(L5_2)
            if "string" == L4_2 then
              L4_2 = L3_2.PlayerData
              L4_2 = L4_2.job
              L4_2 = L4_2.name
              L5_2 = L4_2
              L4_2 = L4_2.lower
              return L4_2(L5_2)
            end
          end
        end
      end
    end
  elseif "qb-core" == L1_2 then
    L2_2 = pcall
    function L3_2()
      local L0_3, L1_3
      L0_3 = exports
      L0_3 = L0_3["qb-core"]
      L1_3 = L0_3
      L0_3 = L0_3.GetCoreObject
      L0_3 = L0_3(L1_3)
      L0_3 = L0_3.Functions
      L0_3 = L0_3.GetPlayer
      L1_3 = A0_2
      return L0_3(L1_3)
    end
    L2_2, L3_2 = L2_2(L3_2)
    if L2_2 then
      L4_2 = type
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      if "table" == L4_2 then
        L4_2 = type
        L5_2 = L3_2.PlayerData
        L4_2 = L4_2(L5_2)
        if "table" == L4_2 then
          L4_2 = type
          L5_2 = L3_2.PlayerData
          L5_2 = L5_2.job
          L4_2 = L4_2(L5_2)
          if "table" == L4_2 then
            L4_2 = type
            L5_2 = L3_2.PlayerData
            L5_2 = L5_2.job
            L5_2 = L5_2.name
            L4_2 = L4_2(L5_2)
            if "string" == L4_2 then
              L4_2 = L3_2.PlayerData
              L4_2 = L4_2.job
              L4_2 = L4_2.name
              L5_2 = L4_2
              L4_2 = L4_2.lower
              return L4_2(L5_2)
            end
          end
        end
      end
    end
  end
  L2_2 = nil
  return L2_2
end
function L21_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "string" ~= L3_2 or "" == A2_2 then
    return
  end
  L4_2 = A2_2
  L3_2 = A2_2.lower
  L3_2 = L3_2(L4_2)
  L4_2 = A1_2[L3_2]
  if nil == L4_2 then
    A1_2[L3_2] = true
    L4_2 = #A0_2
    L4_2 = L4_2 + 1
    A0_2[L4_2] = L3_2
  end
end
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = {}
  L2_2 = {}
  L3_2 = L19_1
  L3_2 = L3_2()
  if "es_extended" == L3_2 then
    L4_2 = pcall
    function L5_2()
      local L0_3, L1_3
      L0_3 = exports
      L0_3 = L0_3.es_extended
      L1_3 = L0_3
      L0_3 = L0_3.getSharedObject
      L0_3 = L0_3(L1_3)
      L0_3 = L0_3.GetPlayerFromId
      L1_3 = A0_2
      return L0_3(L1_3)
    end
    L4_2, L5_2 = L4_2(L5_2)
    if L4_2 then
      L6_2 = type
      L7_2 = L5_2
      L6_2 = L6_2(L7_2)
      if "table" == L6_2 then
        L6_2 = type
        L7_2 = L5_2.getGroup
        L6_2 = L6_2(L7_2)
        if "function" == L6_2 then
          L6_2 = pcall
          L7_2 = L5_2.getGroup
          L8_2 = L5_2
          L6_2, L7_2 = L6_2(L7_2, L8_2)
          if L6_2 then
            L8_2 = L21_1
            L9_2 = L1_2
            L10_2 = L2_2
            L11_2 = L7_2
            L8_2(L9_2, L10_2, L11_2)
          end
        end
      end
    end
  elseif "qbx_core" == L3_2 or "qb-core" == L3_2 then
    L4_2 = pcall
    function L5_2()
      local L0_3, L1_3, L2_3
      L0_3 = L3_2
      if "qbx_core" == L0_3 then
        L0_3 = exports
        L0_3 = L0_3.qbx_core
        L1_3 = L0_3
        L0_3 = L0_3.GetPermission
        L2_3 = A0_2
        return L0_3(L1_3, L2_3)
      end
      L0_3 = exports
      L0_3 = L0_3["qb-core"]
      L1_3 = L0_3
      L0_3 = L0_3.GetCoreObject
      L0_3 = L0_3(L1_3)
      L0_3 = L0_3.Functions
      L0_3 = L0_3.GetPermission
      L1_3 = A0_2
      return L0_3(L1_3)
    end
    L4_2, L5_2 = L4_2(L5_2)
    if L4_2 then
      L6_2 = type
      L7_2 = L5_2
      L6_2 = L6_2(L7_2)
      if "string" == L6_2 then
        L6_2 = L21_1
        L7_2 = L1_2
        L8_2 = L2_2
        L9_2 = L5_2
        L6_2(L7_2, L8_2, L9_2)
      else
        L6_2 = type
        L7_2 = L5_2
        L6_2 = L6_2(L7_2)
        if "table" == L6_2 then
          L6_2 = pairs
          L7_2 = L5_2
          L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
          for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
            L12_2 = type
            L13_2 = L10_2
            L12_2 = L12_2(L13_2)
            if "string" == L12_2 and true == L11_2 then
              L12_2 = L21_1
              L13_2 = L1_2
              L14_2 = L2_2
              L15_2 = L10_2
              L12_2(L13_2, L14_2, L15_2)
            end
            L12_2 = type
            L13_2 = L11_2
            L12_2 = L12_2(L13_2)
            if "string" == L12_2 then
              L12_2 = L21_1
              L13_2 = L1_2
              L14_2 = L2_2
              L15_2 = L11_2
              L12_2(L13_2, L14_2, L15_2)
            end
          end
        end
      end
    end
  end
  return L1_2
end
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = GetPlayerIdentifiers
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = nil
  L3_2 = 1
  L4_2 = #L1_2
  L5_2 = 1
  for L6_2 = L3_2, L4_2, L5_2 do
    L7_2 = L1_2[L6_2]
    L8_2 = type
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if "string" == L8_2 then
      L9_2 = L7_2
      L8_2 = L7_2.sub
      L10_2 = 1
      L11_2 = 8
      L8_2 = L8_2(L9_2, L10_2, L11_2)
      if "license:" == L8_2 then
        return L7_2
      end
      if nil == L2_2 then
        L9_2 = L7_2
        L8_2 = L7_2.sub
        L10_2 = 1
        L11_2 = 3
        L8_2 = L8_2(L9_2, L10_2, L11_2)
        if "ip:" ~= L8_2 then
          L2_2 = L7_2
        end
      end
    end
  end
  L3_2 = L2_2 or L3_2
  if not L2_2 then
    L3_2 = "src:"
    L4_2 = tostring
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
  end
  return L3_2
end
function L24_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if nil == A0_2 or 0 == A0_2 then
    L1_2 = true
    return L1_2
  end
  L1_2 = Config
  L1_2 = L1_2.perms
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = {}
    L1_2 = L2_2
  end
  L2_2 = type
  L3_2 = L1_2.groups
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = L1_2.groups
    L2_2 = #L2_2
    if L2_2 > 0 then
      L2_2 = L22_1
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
      L3_2 = {}
      L4_2 = 1
      L5_2 = #L2_2
      L6_2 = 1
      for L7_2 = L4_2, L5_2, L6_2 do
        L8_2 = L2_2[L7_2]
        L3_2[L8_2] = true
      end
      L4_2 = 1
      L5_2 = L1_2.groups
      L5_2 = #L5_2
      L6_2 = 1
      for L7_2 = L4_2, L5_2, L6_2 do
        L8_2 = L1_2.groups
        L8_2 = L8_2[L7_2]
        L9_2 = type
        L10_2 = L8_2
        L9_2 = L9_2(L10_2)
        if "string" == L9_2 and "" ~= L8_2 then
          L10_2 = L8_2
          L9_2 = L8_2.lower
          L9_2 = L9_2(L10_2)
          L10_2 = L3_2[L9_2]
          if L10_2 then
            L10_2 = true
            return L10_2
          end
          L10_2 = IsPlayerAceAllowed
          L11_2 = A0_2
          L12_2 = "group."
          L13_2 = L9_2
          L12_2 = L12_2 .. L13_2
          L10_2 = L10_2(L11_2, L12_2)
          if L10_2 then
            L10_2 = true
            return L10_2
          end
        end
      end
    end
  end
  L2_2 = type
  L3_2 = L1_2.jobs
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = L1_2.jobs
    L2_2 = #L2_2
    if L2_2 > 0 then
      L2_2 = L20_1
      L3_2 = A0_2
      L2_2 = L2_2(L3_2)
      if nil ~= L2_2 then
        L3_2 = 1
        L4_2 = L1_2.jobs
        L4_2 = #L4_2
        L5_2 = 1
        for L6_2 = L3_2, L4_2, L5_2 do
          L7_2 = L1_2.jobs
          L7_2 = L7_2[L6_2]
          L8_2 = type
          L9_2 = L7_2
          L8_2 = L8_2(L9_2)
          if "string" == L8_2 then
            L9_2 = L7_2
            L8_2 = L7_2.lower
            L8_2 = L8_2(L9_2)
            if L8_2 == L2_2 then
              L8_2 = true
              return L8_2
            end
          end
        end
      end
    end
  end
  L2_2 = L1_2.everyone
  L2_2 = true == L2_2
  return L2_2
end
L25_1 = {}
L26_1 = {}
L25_1.blips = L26_1
L26_1 = {}
L25_1.images = L26_1
L26_1 = {}
L26_1.nextBlip = 1
L26_1.nextImage = 1
L25_1.meta = L26_1
L26_1 = {}
function L27_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = {}
  L26_1 = L0_2
  L0_2 = 1
  L1_2 = L25_1.blips
  L1_2 = #L1_2
  L2_2 = 1
  for L3_2 = L0_2, L1_2, L2_2 do
    L4_2 = L25_1.blips
    L4_2 = L4_2[L3_2]
    L5_2 = L4_2.id
    L4_2 = L26_1
    L4_2[L5_2] = L3_2
  end
end
L28_1 = false
function L29_1()
  local L0_2, L1_2, L2_2
  L0_2 = L28_1
  if L0_2 then
    return
  end
  L0_2 = true
  L28_1 = L0_2
  L0_2 = SetTimeout
  L1_2 = L3_1
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = false
    L28_1 = L0_3
    L0_3 = {}
    L1_3 = L2_1
    L0_3.version = L1_3
    L1_3 = L25_1.blips
    L0_3.blips = L1_3
    L1_3 = L25_1.images
    L0_3.images = L1_3
    L1_3 = L25_1.meta
    L0_3.meta = L1_3
    L1_3 = pcall
    L2_3 = json
    L2_3 = L2_3.encode
    L3_3 = L0_3
    L1_3, L2_3 = L1_3(L2_3, L3_3)
    if not L1_3 then
      L3_3 = L10_1
      L4_3 = "could not encode the store: "
      L5_3 = tostring
      L6_3 = L2_3
      L5_3 = L5_3(L6_3)
      L4_3 = L4_3 .. L5_3
      L3_3(L4_3)
      return
    end
    L3_3 = SaveResourceFile
    L4_3 = L0_1
    L5_3 = L1_1
    L6_3 = L2_3
    L7_3 = -1
    L3_3 = L3_3(L4_3, L5_3, L6_3, L7_3)
    if not L3_3 then
      L3_3 = L10_1
      L4_3 = "could not write "
      L5_3 = L1_1
      L6_3 = " \226\128\148 is the folder read-only?"
      L4_3 = L4_3 .. L5_3 .. L6_3
      L3_3(L4_3)
    end
  end
  L0_2(L1_2, L2_2)
end
function L30_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = LoadResourceFile
  L1_2 = L0_1
  L2_2 = L1_1
  L0_2 = L0_2(L1_2, L2_2)
  if nil == L0_2 or "" == L0_2 then
    L1_2 = L8_1
    L2_2 = "no "
    L3_2 = L1_1
    L4_2 = " yet \226\128\148 starting empty."
    L2_2 = L2_2 .. L3_2 .. L4_2
    L1_2(L2_2)
    return
  end
  L1_2 = pcall
  L2_2 = json
  L2_2 = L2_2.decode
  L3_2 = L0_2
  L1_2, L2_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "table" == L3_2 then
      goto lbl_34
    end
  end
  L3_2 = L10_1
  L4_2 = L1_1
  L5_2 = " is not valid JSON \226\128\148 starting empty (file left untouched until the first save)."
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
  do return end
  ::lbl_34::
  L3_2 = L2_2.blips
  if nil == L3_2 then
    L3_2 = L2_2[1]
    if nil ~= L3_2 then
      L3_2 = {}
      L3_2.blips = L2_2
      L2_2 = L3_2
    end
  end
  L3_2 = type
  L4_2 = L2_2.blips
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = 1
    L4_2 = L2_2.blips
    L4_2 = #L4_2
    L5_2 = 1
    for L6_2 = L3_2, L4_2, L5_2 do
      L7_2 = L2_2.blips
      L7_2 = L7_2[L6_2]
      L8_2 = type
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if "table" == L8_2 then
        L8_2 = type
        L9_2 = L7_2.id
        L8_2 = L8_2(L9_2)
        if "string" == L8_2 then
          L8_2 = L25_1.blips
          L9_2 = L25_1.blips
          L9_2 = #L9_2
          L9_2 = L9_2 + 1
          L8_2[L9_2] = L7_2
        end
      end
    end
  end
  L3_2 = type
  L4_2 = L2_2.images
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = pairs
    L4_2 = L2_2.images
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = type
      L10_2 = L7_2
      L9_2 = L9_2(L10_2)
      if "string" == L9_2 then
        L9_2 = type
        L10_2 = L8_2
        L9_2 = L9_2(L10_2)
        if "table" == L9_2 then
          L9_2 = type
          L10_2 = L8_2.data
          L9_2 = L9_2(L10_2)
          if "string" == L9_2 then
            L9_2 = L25_1.images
            L9_2[L7_2] = L8_2
          end
        end
      end
    end
  end
  L3_2 = type
  L4_2 = L2_2.meta
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = L25_1.meta
    L4_2 = tonumber
    L5_2 = L2_2.meta
    L5_2 = L5_2.nextBlip
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = 1
    end
    L3_2.nextBlip = L4_2
    L3_2 = L25_1.meta
    L4_2 = tonumber
    L5_2 = L2_2.meta
    L5_2 = L5_2.nextImage
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = 1
    end
    L3_2.nextImage = L4_2
  end
  L3_2 = L27_1
  L3_2()
  L3_2 = 0
  L4_2 = pairs
  L5_2 = L25_1.images
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2 in L4_2, L5_2, L6_2, L7_2 do
    L3_2 = L3_2 + 1
  end
  L4_2 = L8_1
  L5_2 = "loaded %d blips and %d images from %s"
  L6_2 = L5_2
  L5_2 = L5_2.format
  L7_2 = L25_1.blips
  L7_2 = #L7_2
  L8_2 = L3_2
  L9_2 = L1_1
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
end
L31_1 = {}
L32_1 = 1
L33_1 = 2
L34_1 = 10
L35_1 = 11
L31_1[1] = L32_1
L31_1[2] = L33_1
L31_1[3] = L34_1
L31_1[4] = L35_1
L32_1 = {}
L33_1 = 2
L34_1 = 3
L35_1 = 5
L32_1[1] = L33_1
L32_1[2] = L34_1
L32_1[3] = L35_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = nil
    L3_2 = "not a table"
    return L2_2, L3_2
  end
  if A1_2 then
    L2_2 = L12_1
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_18
    end
  end
  L2_2 = {}
  ::lbl_18::
  L3_2 = L16_1
  L4_2 = A0_2.name
  if nil ~= L4_2 then
    L4_2 = A0_2.name
    if L4_2 then
      goto lbl_26
    end
  end
  L4_2 = L2_2.name
  ::lbl_26::
  L5_2 = 48
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.name = L3_2
  L3_2 = L2_2.name
  if "" == L3_2 then
    L3_2 = nil
    L4_2 = "empty name"
    return L3_2, L4_2
  end
  L3_2 = type
  L4_2 = A0_2.icon
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.icon
    if L3_2 then
      goto lbl_48
    end
  end
  L3_2 = L2_2.icon
  if not L3_2 then
    L3_2 = {}
  end
  ::lbl_48::
  L4_2 = L3_2.mode
  if "sprite" ~= L4_2 and "image" ~= L4_2 then
    L4_2 = "sprite"
  end
  if "image" == L4_2 then
    L5_2 = L3_2.image
    L6_2 = type
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if "string" == L6_2 then
      L6_2 = L25_1.images
      L6_2 = L6_2[L5_2]
      if nil ~= L6_2 then
        goto lbl_69
      end
    end
    L6_2 = nil
    L7_2 = "unknown image"
    do return L6_2, L7_2 end
    ::lbl_69::
    L6_2 = L3_2.shape
    if "rounded" ~= L6_2 and "circle" ~= L6_2 then
      L6_2 = nil
    end
    L7_2 = {}
    L7_2.mode = "image"
    L7_2.image = L5_2
    L7_2.shape = L6_2
    L2_2.icon = L7_2
  else
    L5_2 = {}
    L5_2.mode = "sprite"
    L6_2 = math
    L6_2 = L6_2.floor
    L7_2 = L13_1
    L8_2 = L3_2.sprite
    L9_2 = 1
    L10_2 = 957
    L11_2 = Config
    L11_2 = L11_2.defaults
    L11_2 = L11_2.sprite
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
    L5_2.sprite = L6_2
    L2_2.icon = L5_2
  end
  L5_2 = type
  L6_2 = A0_2.pos
  L5_2 = L5_2(L6_2)
  if "table" == L5_2 then
    L5_2 = A0_2.pos
    if L5_2 then
      goto lbl_111
    end
  end
  L5_2 = L2_2.pos
  if not L5_2 then
    L5_2 = {}
  end
  ::lbl_111::
  L6_2 = {}
  L7_2 = L14_1
  L8_2 = L13_1
  L9_2 = L5_2.x
  L10_2 = -10000.0
  L11_2 = 10000.0
  L12_2 = 0.0
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L6_2.x = L7_2
  L7_2 = L14_1
  L8_2 = L13_1
  L9_2 = L5_2.y
  L10_2 = -10000.0
  L11_2 = 10000.0
  L12_2 = 0.0
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L6_2.y = L7_2
  L7_2 = L14_1
  L8_2 = L13_1
  L9_2 = L5_2.z
  L10_2 = -2000.0
  L11_2 = 2000.0
  L12_2 = 30.0
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L6_2.z = L7_2
  L2_2.pos = L6_2
  L6_2 = Config
  L6_2 = L6_2.limits
  if not L6_2 then
    L6_2 = {}
  end
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = L13_1
  L9_2 = A0_2.colour
  L10_2 = 0
  L11_2 = 85
  L12_2 = L2_2.colour
  if not L12_2 then
    L12_2 = Config
    L12_2 = L12_2.defaults
    L12_2 = L12_2.colour
  end
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L2_2.colour = L7_2
  L7_2 = L13_1
  L8_2 = A0_2.scale
  L9_2 = L6_2.scaleMin
  if not L9_2 then
    L9_2 = 0.1
  end
  L10_2 = L6_2.scaleMax
  if not L10_2 then
    L10_2 = 10.0
  end
  L11_2 = L2_2.scale
  if not L11_2 then
    L11_2 = Config
    L11_2 = L11_2.defaults
    L11_2 = L11_2.scale
  end
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L2_2.scale = L7_2
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = L13_1
  L9_2 = A0_2.alpha
  L10_2 = L6_2.alphaMin
  if not L10_2 then
    L10_2 = 20
  end
  L11_2 = L6_2.alphaMax
  if not L11_2 then
    L11_2 = 255
  end
  L12_2 = L2_2.alpha
  if not L12_2 then
    L12_2 = Config
    L12_2 = L12_2.defaults
    L12_2 = L12_2.alpha
  end
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L2_2.alpha = L7_2
  L7_2 = L15_1
  L8_2 = A0_2.category
  L9_2 = L31_1
  L10_2 = L2_2.category
  if not L10_2 then
    L10_2 = Config
    L10_2 = L10_2.defaults
    L10_2 = L10_2.category
  end
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L2_2.category = L7_2
  L7_2 = L15_1
  L8_2 = A0_2.display
  L9_2 = L32_1
  L10_2 = L2_2.display
  if not L10_2 then
    L10_2 = Config
    L10_2 = L10_2.defaults
    L10_2 = L10_2.display
  end
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L2_2.display = L7_2
  L7_2 = math
  L7_2 = L7_2.floor
  L8_2 = L13_1
  L9_2 = A0_2.routeColour
  L10_2 = 0
  L11_2 = 85
  L12_2 = L2_2.routeColour
  if not L12_2 then
    L12_2 = 0
  end
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L2_2.routeColour = L7_2
  L7_2 = A0_2.shortRange
  if nil ~= L7_2 then
    L7_2 = A0_2.shortRange
    L7_2 = true == L7_2
    L2_2.shortRange = L7_2
  else
    L7_2 = L2_2.shortRange
    if nil == L7_2 then
      L7_2 = Config
      L7_2 = L7_2.defaults
      L7_2 = L7_2.shortRange
      L2_2.shortRange = L7_2
    end
  end
  L7_2 = A0_2.flash
  if nil ~= L7_2 then
    L7_2 = A0_2.flash
    L7_2 = true == L7_2
    L2_2.flash = L7_2
  else
    L7_2 = L2_2.flash
    if nil == L7_2 then
      L2_2.flash = false
    end
  end
  L7_2 = A0_2.route
  if nil ~= L7_2 then
    L7_2 = A0_2.route
    L7_2 = true == L7_2
    L2_2.route = L7_2
  else
    L7_2 = L2_2.route
    if nil == L7_2 then
      L2_2.route = false
    end
  end
  L7_2 = A0_2.enabled
  if nil ~= L7_2 then
    L7_2 = A0_2.enabled
    L7_2 = true == L7_2
    L2_2.enabled = L7_2
  else
    L7_2 = L2_2.enabled
    if nil == L7_2 then
      L2_2.enabled = true
    end
  end
  L7_2 = type
  L8_2 = A0_2.zone
  L7_2 = L7_2(L8_2)
  if "table" == L7_2 then
    L7_2 = A0_2.zone
    if L7_2 then
      goto lbl_308
    end
  end
  L7_2 = L2_2.zone
  if not L7_2 then
    L7_2 = {}
  end
  ::lbl_308::
  L8_2 = L7_2.mode
  if "radius" ~= L8_2 and "area" ~= L8_2 then
    L8_2 = "none"
  end
  L9_2 = {}
  L9_2.mode = L8_2
  L10_2 = L14_1
  L11_2 = L13_1
  L12_2 = L7_2.radius
  L13_2 = 5.0
  L14_2 = Config
  L14_2 = L14_2.zones
  L14_2 = L14_2.maxRadius
  L15_2 = 50.0
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.radius = L10_2
  L10_2 = L14_1
  L11_2 = L13_1
  L12_2 = L7_2.w
  L13_2 = 5.0
  L14_2 = Config
  L14_2 = L14_2.zones
  L14_2 = L14_2.maxSide
  L15_2 = 100.0
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.w = L10_2
  L10_2 = L14_1
  L11_2 = L13_1
  L12_2 = L7_2.h
  L13_2 = 5.0
  L14_2 = Config
  L14_2 = L14_2.zones
  L14_2 = L14_2.maxSide
  L15_2 = 100.0
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.h = L10_2
  L10_2 = math
  L10_2 = L10_2.floor
  L11_2 = L13_1
  L12_2 = L7_2.rot
  L13_2 = 0
  L14_2 = 359
  L15_2 = 0
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.rot = L10_2
  L10_2 = math
  L10_2 = L10_2.floor
  L11_2 = L13_1
  L12_2 = L7_2.colour
  L13_2 = 0
  L14_2 = 85
  L15_2 = Config
  L15_2 = L15_2.defaults
  L15_2 = L15_2.zoneColour
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.colour = L10_2
  L10_2 = math
  L10_2 = L10_2.floor
  L11_2 = L13_1
  L12_2 = L7_2.alpha
  L13_2 = L6_2.zoneAlphaMin
  if not L13_2 then
    L13_2 = 10
  end
  L14_2 = L6_2.zoneAlphaMax
  if not L14_2 then
    L14_2 = 255
  end
  L15_2 = Config
  L15_2 = L15_2.defaults
  L15_2 = L15_2.zoneAlpha
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2(L12_2, L13_2, L14_2, L15_2)
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L9_2.alpha = L10_2
  L10_2 = L7_2.events
  L10_2 = true == L10_2
  L9_2.events = L10_2
  L2_2.zone = L9_2
  L9_2 = type
  L10_2 = A0_2.vis
  L9_2 = L9_2(L10_2)
  if "table" == L9_2 then
    L9_2 = A0_2.vis
    if L9_2 then
      goto lbl_410
    end
  end
  L9_2 = L2_2.vis
  if not L9_2 then
    L9_2 = {}
  end
  ::lbl_410::
  L10_2 = L9_2.mode
  if "jobs" ~= L10_2 and "private" ~= L10_2 then
    L10_2 = "everyone"
  end
  L11_2 = {}
  if "jobs" == L10_2 then
    L12_2 = type
    L13_2 = L9_2.jobs
    L12_2 = L12_2(L13_2)
    if "table" == L12_2 then
      L12_2 = L9_2.jobs
      if L12_2 then
        goto lbl_430
      end
    end
    L12_2 = {}
    ::lbl_430::
    L13_2 = 1
    L14_2 = math
    L14_2 = L14_2.min
    L15_2 = #L12_2
    L16_2 = 16
    L14_2 = L14_2(L15_2, L16_2)
    L15_2 = 1
    for L16_2 = L13_2, L14_2, L15_2 do
      L17_2 = L12_2[L16_2]
      L18_2 = type
      L19_2 = L17_2
      L18_2 = L18_2(L19_2)
      if "string" == L18_2 then
        L19_2 = L17_2
        L18_2 = L17_2.lower
        L18_2 = L18_2(L19_2)
        L19_2 = L18_2
        L18_2 = L18_2.gsub
        L20_2 = "[^%w_%-]"
        L21_2 = ""
        L18_2 = L18_2(L19_2, L20_2, L21_2)
        L17_2 = L18_2
        if "" ~= L17_2 then
          L18_2 = #L17_2
          if L18_2 <= 40 then
            L18_2 = #L11_2
            L18_2 = L18_2 + 1
            L11_2[L18_2] = L17_2
          end
        end
      end
    end
    L13_2 = #L11_2
    if 0 == L13_2 then
      L10_2 = "everyone"
    end
  end
  L12_2 = {}
  L12_2.mode = L10_2
  L12_2.jobs = L11_2
  L2_2.vis = L12_2
  L12_2 = os
  L12_2 = L12_2.time
  L12_2 = L12_2()
  L2_2.updatedAt = L12_2
  L12_2 = L2_2
  L13_2 = nil
  return L12_2, L13_2
end
function L34_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = nil
    L3_2 = "not a table"
    return L2_2, L3_2
  end
  if A1_2 then
    L2_2 = L12_1
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_18
    end
  end
  L2_2 = {}
  ::lbl_18::
  L3_2 = L16_1
  L4_2 = A0_2.name
  if nil ~= L4_2 then
    L4_2 = A0_2.name
    if L4_2 then
      goto lbl_26
    end
  end
  L4_2 = L2_2.name
  ::lbl_26::
  L5_2 = 40
  L3_2 = L3_2(L4_2, L5_2)
  L2_2.name = L3_2
  L3_2 = L2_2.name
  if "" == L3_2 then
    L2_2.name = "Image"
  end
  L3_2 = A0_2.data
  if nil == L3_2 then
    L3_2 = L2_2.data
    if nil ~= L3_2 then
      goto lbl_78
    end
  end
  L3_2 = A0_2.data
  L4_2 = type
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if "string" ~= L4_2 then
    L4_2 = nil
    L5_2 = "no data"
    return L4_2, L5_2
  end
  L5_2 = L3_2
  L4_2 = L3_2.find
  L6_2 = "^data:image/png;base64,"
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L5_2 = L3_2
    L4_2 = L3_2.find
    L6_2 = "^data:image/jpeg;base64,"
    L4_2 = L4_2(L5_2, L6_2)
    if not L4_2 then
      L5_2 = L3_2
      L4_2 = L3_2.find
      L6_2 = "^data:image/webp;base64,"
      L4_2 = L4_2(L5_2, L6_2)
      if not L4_2 then
        L4_2 = nil
        L5_2 = "not an inline image"
        return L4_2, L5_2
      end
    end
  end
  L4_2 = #L3_2
  L5_2 = Config
  L5_2 = L5_2.images
  L5_2 = L5_2.maxKB
  L5_2 = L5_2 * 1024
  if L4_2 > L5_2 then
    L4_2 = nil
    L5_2 = "too large"
    return L4_2, L5_2
  end
  L2_2.data = L3_2
  ::lbl_78::
  L3_2 = L15_1
  L4_2 = A0_2.size
  L5_2 = {}
  L6_2 = 64
  L7_2 = 96
  L8_2 = 128
  L9_2 = 256
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L6_2 = L2_2.size
  if not L6_2 then
    L6_2 = Config
    L6_2 = L6_2.images
    L6_2 = L6_2.textureSize
  end
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2.size = L3_2
  L3_2 = A0_2.badge
  if nil ~= L3_2 then
    L3_2 = A0_2.badge
    L3_2 = true == L3_2
    L2_2.badge = L3_2
  else
    L3_2 = L2_2.badge
    if nil == L3_2 then
      L2_2.badge = false
    end
  end
  L3_2 = L2_2
  L4_2 = nil
  return L3_2, L4_2
end
function L35_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = A0_2.enabled
  if true ~= L3_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = A0_2.vis
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = L3_2.mode
  if "private" == L4_2 then
    L4_2 = A0_2.owner
    L4_2 = L4_2 == A2_2
    return L4_2
  end
  L4_2 = L3_2.mode
  if "jobs" == L4_2 then
    if nil == A1_2 then
      L4_2 = false
      return L4_2
    end
    L4_2 = 1
    L5_2 = L3_2.jobs
    L5_2 = #L5_2
    L6_2 = 1
    for L7_2 = L4_2, L5_2, L6_2 do
      L8_2 = L3_2.jobs
      L8_2 = L8_2[L7_2]
      if L8_2 == A1_2 then
        L8_2 = true
        return L8_2
      end
    end
    L4_2 = false
    return L4_2
  end
  L4_2 = true
  return L4_2
end
function L36_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = L20_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = L23_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = {}
  L5_2 = 1
  L6_2 = L25_1.blips
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L25_1.blips
    L9_2 = L9_2[L8_2]
    L10_2 = L35_1
    L11_2 = L9_2
    L12_2 = L1_2
    L13_2 = L2_2
    L10_2 = L10_2(L11_2, L12_2, L13_2)
    if L10_2 then
      L10_2 = #L3_2
      L10_2 = L10_2 + 1
      L3_2[L10_2] = L9_2
      L10_2 = L9_2.icon
      L10_2 = L10_2.mode
      if "image" == L10_2 then
        L10_2 = L25_1.images
        L11_2 = L9_2.icon
        L11_2 = L11_2.image
        L10_2 = L10_2[L11_2]
        if nil ~= L10_2 then
          L10_2 = L9_2.icon
          L10_2 = L10_2.image
          L11_2 = L25_1.images
          L12_2 = L9_2.icon
          L12_2 = L12_2.image
          L11_2 = L11_2[L12_2]
          L4_2[L10_2] = L11_2
        end
      end
    end
  end
  L5_2 = {}
  L5_2.blips = L3_2
  L5_2.images = L4_2
  return L5_2
end
function L37_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if nil ~= A0_2 then
    L1_2 = GetPlayerName
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if nil ~= L1_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L1_2 = TriggerLatentClientEvent
  L2_2 = "apex_blips:sync"
  L3_2 = A0_2
  L4_2 = Config
  L4_2 = L4_2.sync
  L4_2 = L4_2.bps
  L5_2 = L36_1
  L6_2 = A0_2
  L5_2, L6_2 = L5_2(L6_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end
L38_1 = {}
function L39_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = {}
  L2_2 = L25_1.blips
  L1_2.blips = L2_2
  L2_2 = L25_1.images
  L1_2.images = L2_2
  L2_2 = L24_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L1_2.canEdit = L2_2
  return L1_2
end
function L40_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if nil ~= A0_2 then
    L1_2 = GetPlayerName
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if nil ~= L1_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L1_2 = TriggerLatentClientEvent
  L2_2 = "apex_blips:studio"
  L3_2 = A0_2
  L4_2 = Config
  L4_2 = L4_2.sync
  L4_2 = L4_2.bps
  L5_2 = L39_1
  L6_2 = A0_2
  L5_2, L6_2 = L5_2(L6_2)
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end
function L41_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = pairs
  L3_2 = L38_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L7_2 = GetPlayerName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if nil ~= L7_2 then
      L7_2 = TriggerLatentClientEvent
      L8_2 = "apex_blips:image"
      L9_2 = L6_2
      L10_2 = Config
      L10_2 = L10_2.sync
      L10_2 = L10_2.bps
      L11_2 = {}
      L11_2.id = A0_2
      if not A1_2 then
        L12_2 = L25_1.images
        L12_2 = L12_2[A0_2]
        if L12_2 then
          goto lbl_26
        end
      end
      L12_2 = nil
      ::lbl_26::
      L11_2.image = L12_2
      L12_2 = true == A1_2
      L11_2.removed = L12_2
      L7_2(L8_2, L9_2, L10_2, L11_2)
    end
  end
end
function L42_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = 1
  L2_2 = L25_1.blips
  L2_2 = #L2_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L25_1.blips
    L5_2 = L5_2[L4_2]
    L5_2 = L5_2.icon
    if L5_2 then
      L6_2 = L5_2.mode
      if "image" == L6_2 then
        L6_2 = L5_2.image
        if L6_2 == A0_2 then
          L6_2 = true
          return L6_2
        end
      end
    end
  end
  L1_2 = false
  return L1_2
end
L43_1 = false
function L44_1()
  local L0_2, L1_2, L2_2
  L0_2 = L43_1
  if L0_2 then
    return
  end
  L0_2 = true
  L43_1 = L0_2
  L0_2 = SetTimeout
  L1_2 = L4_1
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = false
    L43_1 = L0_3
    L0_3 = GetPlayers
    L0_3 = L0_3()
    L1_3 = 1
    L2_3 = #L0_3
    L3_3 = 1
    for L4_3 = L1_3, L2_3, L3_3 do
      L5_3 = tonumber
      L6_3 = L0_3[L4_3]
      L5_3 = L5_3(L6_3)
      if L5_3 then
        L6_3 = L37_1
        L7_3 = L5_3
        L6_3(L7_3)
        L6_3 = L38_1
        L6_3 = L6_3[L5_3]
        if L6_3 then
          L6_3 = L40_1
          L7_3 = L5_3
          L6_3(L7_3)
        end
      end
    end
  end
  L0_2(L1_2, L2_2)
end
function L45_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if nil == A0_2 or 0 == A0_2 then
    L2_2 = L8_1
    L3_2 = A1_2
    L2_2(L3_2)
    return
  end
  L2_2 = TriggerClientEvent
  L3_2 = "apex_blips:notify"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
end
function L46_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = nil
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = type
    L4_2 = A0_2.id
    L3_2 = L3_2(L4_2)
    if "string" == L3_2 then
      L4_2 = A0_2.id
      L3_2 = L26_1
      L3_2 = L3_2[L4_2]
      if L3_2 then
        L3_2 = L25_1.blips
        L5_2 = A0_2.id
        L4_2 = L26_1
        L4_2 = L4_2[L5_2]
        L2_2 = L3_2[L4_2]
      end
    end
  end
  if nil == L2_2 then
    L3_2 = L25_1.blips
    L3_2 = #L3_2
    L4_2 = L5_1
    if L3_2 >= L4_2 then
      L3_2 = nil
      L4_2 = "limit"
      return L3_2, L4_2
    end
  end
  L3_2 = L33_1
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  if nil == L3_2 then
    L5_2 = nil
    L6_2 = L4_2
    return L5_2, L6_2
  end
  if nil == L2_2 then
    L5_2 = "b_%06d"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = L25_1.meta
    L7_2 = L7_2.nextBlip
    L5_2 = L5_2(L6_2, L7_2)
    L3_2.id = L5_2
    L5_2 = L25_1.meta
    L6_2 = L25_1.meta
    L6_2 = L6_2.nextBlip
    L6_2 = L6_2 + 1
    L5_2.nextBlip = L6_2
    if A1_2 and 0 ~= A1_2 then
      L5_2 = L23_1
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        goto lbl_65
      end
    end
    L5_2 = "server"
    ::lbl_65::
    L3_2.owner = L5_2
    if A1_2 and 0 ~= A1_2 then
      L5_2 = GetPlayerName
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        goto lbl_79
      end
      L5_2 = "?"
      if L5_2 then
        goto lbl_79
      end
    end
    L5_2 = "server"
    ::lbl_79::
    L3_2.createdBy = L5_2
    L5_2 = os
    L5_2 = L5_2.time
    L5_2 = L5_2()
    L3_2.createdAt = L5_2
    L5_2 = L25_1.blips
    L6_2 = L25_1.blips
    L6_2 = #L6_2
    L6_2 = L6_2 + 1
    L5_2[L6_2] = L3_2
  else
    L5_2 = L25_1.blips
    L7_2 = L2_2.id
    L6_2 = L26_1
    L6_2 = L6_2[L7_2]
    L5_2[L6_2] = L3_2
  end
  L5_2 = L27_1
  L5_2()
  L5_2 = L29_1
  L5_2()
  L5_2 = L44_1
  L5_2()
  L5_2 = L11_1
  L6_2 = "blip %s upserted by %s"
  L7_2 = L6_2
  L6_2 = L6_2.format
  L8_2 = L3_2.id
  L9_2 = tostring
  L10_2 = A1_2
  L9_2, L10_2 = L9_2(L10_2)
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
  L5_2 = L3_2.id
  L6_2 = nil
  return L5_2, L6_2
end
function L47_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L26_1
  L1_2 = L1_2[A0_2]
  if nil == L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = table
  L2_2 = L2_2.remove
  L3_2 = L25_1.blips
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = L27_1
  L2_2()
  L2_2 = L29_1
  L2_2()
  L2_2 = L44_1
  L2_2()
  L2_2 = true
  return L2_2
end
function L48_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A1_2 then
    L2_2 = L25_1.images
    L2_2 = L2_2[A1_2]
    if L2_2 then
      goto lbl_8
    end
  end
  L2_2 = nil
  ::lbl_8::
  if nil == L2_2 then
    L3_2 = 0
    L4_2 = pairs
    L5_2 = L25_1.images
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2 in L4_2, L5_2, L6_2, L7_2 do
      L3_2 = L3_2 + 1
    end
    L4_2 = Config
    L4_2 = L4_2.images
    L4_2 = L4_2.maxCount
    if L3_2 >= L4_2 then
      L4_2 = nil
      L5_2 = "limit"
      return L4_2, L5_2
    end
  end
  L3_2 = L34_1
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  if nil == L3_2 then
    L5_2 = nil
    L6_2 = L4_2
    return L5_2, L6_2
  end
  if nil == L2_2 then
    L5_2 = "img_%06d"
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = L25_1.meta
    L7_2 = L7_2.nextImage
    L5_2 = L5_2(L6_2, L7_2)
    L3_2.id = L5_2
    L5_2 = L25_1.meta
    L6_2 = L25_1.meta
    L6_2 = L6_2.nextImage
    L6_2 = L6_2 + 1
    L5_2.nextImage = L6_2
  else
    L3_2.id = A1_2
  end
  L5_2 = L25_1.images
  L6_2 = L3_2.id
  L5_2[L6_2] = L3_2
  L5_2 = L29_1
  L5_2()
  L5_2 = L3_2.id
  L6_2 = nil
  L7_2 = nil ~= L2_2
  return L5_2, L6_2, L7_2
end
function L49_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = 0
  L2_2 = 1
  L3_2 = L25_1.blips
  L3_2 = #L3_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = L25_1.blips
    L6_2 = L6_2[L5_2]
    L6_2 = L6_2.icon
    if L6_2 then
      L7_2 = L6_2.mode
      if "image" == L7_2 then
        L7_2 = L6_2.image
        if L7_2 == A0_2 then
          L1_2 = L1_2 + 1
        end
      end
    end
  end
  return L1_2
end
L50_1 = {}
function L51_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetGameTimer
  L2_2 = L2_2()
  L3_2 = L50_1
  L3_2 = L3_2[A0_2]
  if nil ~= L3_2 then
    L4_2 = L2_2 - L3_2
    L5_2 = A1_2 or L5_2
    if not A1_2 then
      L5_2 = L7_1
    end
    if L4_2 < L5_2 then
      L4_2 = true
      return L4_2
    end
  end
  L4_2 = L50_1
  L4_2[A0_2] = L2_2
  L4_2 = false
  return L4_2
end
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:requestSync"
function L54_1()
  local L0_2, L1_2, L2_2
  L0_2 = source
  L1_2 = L37_1
  L2_2 = L0_2
  L1_2(L2_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:requestStudio"
function L54_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = source
  L1_2 = L51_1
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    return
  end
  L1_2 = L24_1
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = L45_1
    L2_2 = L0_2
    L3_2 = L
    L4_2 = "n_no_perm"
    L3_2, L4_2 = L3_2(L4_2)
    L1_2(L2_2, L3_2, L4_2)
    return
  end
  L1_2 = L38_1
  L1_2[L0_2] = true
  L1_2 = L40_1
  L2_2 = L0_2
  L1_2(L2_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:studioClosed"
function L54_1()
  local L0_2, L1_2
  L1_2 = source
  L0_2 = L38_1
  L0_2[L1_2] = nil
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:save"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = source
  L2_2 = L51_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L45_1
    L3_2 = L1_2
    L4_2 = L
    L5_2 = "n_no_perm"
    L4_2, L5_2, L6_2, L7_2, L8_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    return
  end
  L2_2 = L46_1
  L3_2 = A0_2
  L4_2 = L1_2
  L2_2, L3_2 = L2_2(L3_2, L4_2)
  if nil == L2_2 then
    if "limit" == L3_2 then
      L4_2 = L45_1
      L5_2 = L1_2
      L6_2 = L
      L7_2 = "n_store_limit"
      L8_2 = L5_1
      L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
      L4_2(L5_2, L6_2, L7_2, L8_2)
    else
      L4_2 = L45_1
      L5_2 = L1_2
      L6_2 = L
      L7_2 = "n_bad_payload"
      L6_2, L7_2, L8_2 = L6_2(L7_2)
      L4_2(L5_2, L6_2, L7_2, L8_2)
    end
    L4_2 = TriggerClientEvent
    L5_2 = "apex_blips:saved"
    L6_2 = L1_2
    L7_2 = {}
    L7_2.ok = false
    L7_2.reason = L3_2
    L4_2(L5_2, L6_2, L7_2)
    return
  end
  L4_2 = TriggerClientEvent
  L5_2 = "apex_blips:saved"
  L6_2 = L1_2
  L7_2 = {}
  L7_2.ok = true
  L7_2.id = L2_2
  L4_2(L5_2, L6_2, L7_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:delete"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = source
  L2_2 = L51_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L45_1
    L3_2 = L1_2
    L4_2 = L
    L5_2 = "n_no_perm"
    L4_2, L5_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = L47_1
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L45_1
      L3_2 = L1_2
      L4_2 = L
      L5_2 = "n_deleted"
      L4_2, L5_2 = L4_2(L5_2)
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:saveImage"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = source
  L2_2 = L51_1
  L3_2 = L1_2
  L4_2 = 400
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L2_2 = TriggerClientEvent
    L3_2 = "apex_blips:imageSaved"
    L4_2 = L1_2
    L5_2 = {}
    L5_2.ok = false
    L5_2.reason = "busy"
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L45_1
    L3_2 = L1_2
    L4_2 = L
    L5_2 = "n_no_perm"
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L2_2 = TriggerClientEvent
    L3_2 = "apex_blips:imageSaved"
    L4_2 = L1_2
    L5_2 = {}
    L5_2.ok = false
    L5_2.reason = "perm"
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = TriggerClientEvent
    L3_2 = "apex_blips:imageSaved"
    L4_2 = L1_2
    L5_2 = {}
    L5_2.ok = false
    L5_2.reason = "payload"
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = type
  L3_2 = A0_2.id
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = L25_1.images
    L3_2 = A0_2.id
    L2_2 = L2_2[L3_2]
    if nil ~= L2_2 then
      L2_2 = A0_2.id
      if L2_2 then
        goto lbl_65
      end
    end
  end
  L2_2 = nil
  ::lbl_65::
  L3_2 = L48_1
  L4_2 = A0_2
  L5_2 = L2_2
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  if nil == L3_2 then
    if "limit" == L4_2 then
      L6_2 = L45_1
      L7_2 = L1_2
      L8_2 = L
      L9_2 = "n_image_limit"
      L10_2 = Config
      L10_2 = L10_2.images
      L10_2 = L10_2.maxCount
      L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
      L6_2(L7_2, L8_2, L9_2, L10_2)
    else
      L6_2 = L45_1
      L7_2 = L1_2
      L8_2 = L
      L9_2 = "n_bad_payload"
      L8_2, L9_2, L10_2 = L8_2(L9_2)
      L6_2(L7_2, L8_2, L9_2, L10_2)
    end
    L6_2 = TriggerClientEvent
    L7_2 = "apex_blips:imageSaved"
    L8_2 = L1_2
    L9_2 = {}
    L9_2.ok = false
    L9_2.reason = L4_2
    L6_2(L7_2, L8_2, L9_2)
    return
  end
  L6_2 = L41_1
  L7_2 = L3_2
  L8_2 = false
  L6_2(L7_2, L8_2)
  if L5_2 then
    L6_2 = L42_1
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = L44_1
      L6_2()
    end
  end
  L6_2 = L45_1
  L7_2 = L1_2
  L8_2 = L
  L9_2 = "n_image_saved"
  L10_2 = L25_1.images
  L10_2 = L10_2[L3_2]
  L10_2 = L10_2.name
  L8_2, L9_2, L10_2 = L8_2(L9_2, L10_2)
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = TriggerClientEvent
  L7_2 = "apex_blips:imageSaved"
  L8_2 = L1_2
  L9_2 = {}
  L9_2.ok = true
  L9_2.id = L3_2
  L10_2 = true == L5_2
  L9_2.replaced = L10_2
  L6_2(L7_2, L8_2, L9_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:deleteImage"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = source
  L2_2 = L51_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L45_1
    L3_2 = L1_2
    L4_2 = L
    L5_2 = "n_no_perm"
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
    return
  end
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = L25_1.images
    L2_2 = L2_2[A0_2]
    if nil ~= L2_2 then
      goto lbl_30
    end
  end
  do return end
  ::lbl_30::
  L2_2 = L49_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 > 0 then
    L3_2 = L45_1
    L4_2 = L1_2
    L5_2 = L
    L6_2 = "n_image_in_use"
    L7_2 = L2_2
    L5_2, L6_2, L7_2 = L5_2(L6_2, L7_2)
    L3_2(L4_2, L5_2, L6_2, L7_2)
    return
  end
  L3_2 = L25_1.images
  L3_2[A0_2] = nil
  L3_2 = L29_1
  L3_2()
  L3_2 = L41_1
  L4_2 = A0_2
  L5_2 = true
  L3_2(L4_2, L5_2)
  L3_2 = L45_1
  L4_2 = L1_2
  L5_2 = L
  L6_2 = "n_image_deleted"
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:importAll"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = source
  L2_2 = L51_1
  L3_2 = L1_2
  L4_2 = 1000
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L45_1
    L3_2 = L1_2
    L4_2 = L
    L5_2 = "n_no_perm"
    L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    return
  end
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.blips
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      goto lbl_39
    end
  end
  L2_2 = L45_1
  L3_2 = L1_2
  L4_2 = L
  L5_2 = "n_import_fail"
  L6_2 = "bad payload"
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L4_2(L5_2, L6_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  do return end
  ::lbl_39::
  L2_2 = {}
  L3_2 = type
  L4_2 = A0_2.images
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = 0
    L4_2 = pairs
    L5_2 = A0_2.images
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L3_2 = L3_2 + 1
      if L3_2 > 64 then
        break
      end
      L10_2 = L48_1
      L11_2 = L9_2
      L12_2 = nil
      L10_2 = L10_2(L11_2, L12_2)
      if nil ~= L10_2 then
        L2_2[L8_2] = L10_2
      end
    end
  end
  L3_2 = 0
  L4_2 = 0
  L5_2 = 1
  L6_2 = A0_2.blips
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L4_2 = L4_2 + 1
    L9_2 = L6_1
    if L4_2 > L9_2 then
      break
    end
    L9_2 = A0_2.blips
    L9_2 = L9_2[L8_2]
    L10_2 = type
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if "table" == L10_2 then
      L10_2 = L12_1
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      L9_2 = L10_2
      L9_2.id = nil
      L10_2 = type
      L11_2 = L9_2.icon
      L10_2 = L10_2(L11_2)
      if "table" == L10_2 then
        L10_2 = L9_2.icon
        L10_2 = L10_2.mode
        if "image" == L10_2 then
          L10_2 = L9_2.icon
          L11_2 = L9_2.icon
          L11_2 = L11_2.image
          L11_2 = L2_2[L11_2]
          if not L11_2 then
            L11_2 = L9_2.icon
            L11_2 = L11_2.image
          end
          L10_2.image = L11_2
        end
      end
      L10_2 = L46_1
      L11_2 = L9_2
      L12_2 = L1_2
      L10_2 = L10_2(L11_2, L12_2)
      if nil ~= L10_2 then
        L3_2 = L3_2 + 1
      end
    end
  end
  L5_2 = pairs
  L6_2 = L38_1
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2 in L5_2, L6_2, L7_2, L8_2 do
    L10_2 = L40_1
    L11_2 = L9_2
    L10_2(L11_2)
  end
  L5_2 = L44_1
  L5_2()
  L5_2 = L45_1
  L6_2 = L1_2
  L7_2 = L
  L8_2 = "n_import_done"
  L9_2 = L3_2
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L7_2(L8_2, L9_2)
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
end
L52_1(L53_1, L54_1)
L52_1 = RegisterNetEvent
L53_1 = "apex_blips:zoneCross"
function L54_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = source
  L3_2 = Config
  L3_2 = L3_2.zones
  L3_2 = L3_2.events
  if true ~= L3_2 then
    return
  end
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "string" == L3_2 then
    L3_2 = L26_1
    L3_2 = L3_2[A0_2]
    if nil ~= L3_2 then
      goto lbl_18
    end
  end
  do return end
  ::lbl_18::
  L3_2 = L25_1.blips
  L4_2 = L26_1
  L4_2 = L4_2[A0_2]
  L3_2 = L3_2[L4_2]
  L4_2 = L3_2.zone
  if nil ~= L4_2 then
    L4_2 = L3_2.zone
    L4_2 = L4_2.mode
    if "none" ~= L4_2 then
      L4_2 = L3_2.zone
      L4_2 = L4_2.events
      if true == L4_2 then
        goto lbl_34
      end
    end
  end
  do return end
  ::lbl_34::
  L4_2 = TriggerEvent
  L5_2 = "apex_blips:zone"
  L6_2 = L2_2
  L7_2 = A0_2
  L8_2 = true == A1_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
L52_1(L53_1, L54_1)
L52_1 = AddEventHandler
L53_1 = "playerDropped"
function L54_1()
  local L0_2, L1_2
  L0_2 = source
  L1_2 = L38_1
  L1_2[L0_2] = nil
  L1_2 = L50_1
  L1_2[L0_2] = nil
end
L52_1(L53_1, L54_1)
L52_1 = AddEventHandler
L53_1 = "esx:setJob"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "number" == L1_2 then
    L1_2 = SetTimeout
    L2_2 = 250
    function L3_2()
      local L0_3, L1_3
      L0_3 = L37_1
      L1_3 = A0_2
      L0_3(L1_3)
    end
    L1_2(L2_2, L3_2)
  end
end
L52_1(L53_1, L54_1)
L52_1 = AddEventHandler
L53_1 = "QBCore:Server:OnJobUpdate"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "number" == L1_2 then
    L1_2 = SetTimeout
    L2_2 = 250
    function L3_2()
      local L0_3, L1_3
      L0_3 = L37_1
      L1_3 = A0_2
      L0_3(L1_3)
    end
    L1_2(L2_2, L3_2)
  end
end
L52_1(L53_1, L54_1)
L52_1 = AddEventHandler
L53_1 = "esx:playerLoaded"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "number" == L1_2 then
    L1_2 = SetTimeout
    L2_2 = 500
    function L3_2()
      local L0_3, L1_3
      L0_3 = L37_1
      L1_3 = A0_2
      L0_3(L1_3)
    end
    L1_2(L2_2, L3_2)
  end
end
L52_1(L53_1, L54_1)
L52_1 = AddEventHandler
L53_1 = "QBCore:Server:PlayerLoaded"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = nil
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.PlayerData
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = tonumber
      L3_2 = A0_2.PlayerData
      L3_2 = L3_2.source
      L2_2 = L2_2(L3_2)
      L1_2 = L2_2
  end
  else
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "number" == L2_2 then
      L1_2 = A0_2
    end
  end
  if nil ~= L1_2 then
    L2_2 = SetTimeout
    L3_2 = 500
    function L4_2()
      local L0_3, L1_3
      L0_3 = L37_1
      L1_3 = L1_2
      L0_3(L1_3)
    end
    L2_2(L3_2, L4_2)
  end
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "AddBlip"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L46_1
  L2_2 = A0_2
  L3_2 = 0
  return L1_2(L2_2, L3_2)
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "UpdateBlip"
function L54_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = L26_1
    L2_2 = L2_2[A0_2]
    if nil ~= L2_2 then
      goto lbl_12
    end
  end
  L2_2 = false
  do return L2_2 end
  ::lbl_12::
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = L12_1
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A1_2 = L2_2
  A1_2.id = A0_2
  L2_2 = L46_1
  L3_2 = A1_2
  L4_2 = 0
  L2_2 = L2_2(L3_2, L4_2)
  L2_2 = nil ~= L2_2
  return L2_2
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "RemoveBlip"
function L54_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = L47_1
  L2_2 = A0_2
  return L1_2(L2_2)
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "GetBlip"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = L26_1
    L1_2 = L1_2[A0_2]
    if nil ~= L1_2 then
      goto lbl_12
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_12::
  L1_2 = L12_1
  L2_2 = L25_1.blips
  L3_2 = L26_1
  L3_2 = L3_2[A0_2]
  L2_2 = L2_2[L3_2]
  return L1_2(L2_2)
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "GetBlips"
function L54_1()
  local L0_2, L1_2
  L0_2 = L12_1
  L1_2 = L25_1.blips
  return L0_2(L1_2)
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "SetBlipEnabled"
function L54_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = L26_1
    L2_2 = L2_2[A0_2]
    if nil ~= L2_2 then
      goto lbl_12
    end
  end
  L2_2 = false
  do return L2_2 end
  ::lbl_12::
  L2_2 = L46_1
  L3_2 = {}
  L3_2.id = A0_2
  L4_2 = true == A1_2
  L3_2.enabled = L4_2
  L4_2 = 0
  L2_2 = L2_2(L3_2, L4_2)
  L2_2 = nil ~= L2_2
  return L2_2
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "RegisterImage"
function L54_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = type
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  if "string" == L3_2 then
    L3_2 = L25_1.images
    L3_2 = L3_2[A2_2]
    if nil ~= L3_2 and A2_2 then
      goto lbl_13
      L3_2 = A2_2 or L3_2
    end
  end
  L3_2 = nil
  ::lbl_13::
  L4_2 = L48_1
  L5_2 = {}
  L5_2.name = A0_2
  L5_2.data = A1_2
  L6_2 = L3_2
  L4_2, L5_2, L6_2 = L4_2(L5_2, L6_2)
  if nil ~= L4_2 then
    L7_2 = L41_1
    L8_2 = L4_2
    L9_2 = false
    L7_2(L8_2, L9_2)
    if L6_2 then
      L7_2 = L42_1
      L8_2 = L4_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = L44_1
        L7_2()
      end
    end
  end
  L7_2 = L4_2
  L8_2 = L5_2
  return L7_2, L8_2
end
L52_1(L53_1, L54_1)
L52_1 = exports
L53_1 = "RemoveImage"
function L54_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = L25_1.images
    L1_2 = L1_2[A0_2]
    if nil ~= L1_2 then
      goto lbl_13
    end
  end
  L1_2 = false
  L2_2 = "unknown"
  do return L1_2, L2_2 end
  ::lbl_13::
  L1_2 = L49_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 > 0 then
    L1_2 = false
    L2_2 = "in_use"
    return L1_2, L2_2
  end
  L1_2 = L25_1.images
  L1_2[A0_2] = nil
  L1_2 = L29_1
  L1_2()
  L1_2 = L41_1
  L2_2 = A0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = true
  L2_2 = nil
  return L1_2, L2_2
end
L52_1(L53_1, L54_1)
L52_1 = RegisterCommand
L53_1 = "blipwipe"
function L54_1(A0_2)
  local L1_2, L2_2
  if 0 ~= A0_2 then
    return
  end
  L1_2 = {}
  L25_1.blips = L1_2
  L1_2 = {}
  L25_1.images = L1_2
  L1_2 = L27_1
  L1_2()
  L1_2 = L29_1
  L1_2()
  L1_2 = L44_1
  L1_2()
  L1_2 = L8_1
  L2_2 = "store wiped by console."
  L1_2(L2_2)
end
L55_1 = true
L52_1(L53_1, L54_1, L55_1)
L52_1 = AddEventHandler
L53_1 = "onResourceStart"
function L54_1(A0_2)
  local L1_2, L2_2
  L1_2 = L0_1
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = L30_1
  L1_2()
  L1_2 = Config
  L1_2 = L1_2.perms
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.perms
    L1_2 = L1_2.everyone
    if true == L1_2 then
      L1_2 = L9_1
      L2_2 = "Config.perms.everyone = true \226\128\148 EVERY player can edit blips. Set it to false before going live."
      L1_2(L2_2)
    end
  end
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    L0_3 = 1
    L1_3 = 3
    L2_3 = 1
    for L3_3 = L0_3, L1_3, L2_3 do
      L4_3 = Wait
      L5_3 = L3_3 * 2000
      L4_3(L5_3)
      L4_3 = GetPlayers
      L4_3 = L4_3()
      L5_3 = 1
      L6_3 = #L4_3
      L7_3 = 1
      for L8_3 = L5_3, L6_3, L7_3 do
        L9_3 = tonumber
        L10_3 = L4_3[L8_3]
        L9_3 = L9_3(L10_3)
        if L9_3 then
          L10_3 = L37_1
          L11_3 = L9_3
          L10_3(L11_3)
        end
      end
    end
  end
  L1_2(L2_2)
end
L52_1(L53_1, L54_1)
