local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1, L34_1, L35_1, L36_1, L37_1, L38_1
L0_1 = Shared
if L0_1 then
  L0_1 = Shared
  L0_1 = L0_1.Storage
  if L0_1 then
    L0_1 = Shared
    L0_1 = L0_1.Storage
    L0_1 = L0_1.serverCategoriesKey
    if L0_1 then
      goto lbl_15
    end
  end
end
L0_1 = "apex_chat:categories"
::lbl_15::
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = {}
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.id
    if L8_2 then
      L8_2 = L7_2.id
      L1_2[L8_2] = true
    end
  end
  L2_2 = false
  L3_2 = ipairs
  L4_2 = ApexCats
  L4_2 = L4_2.defaults
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2()
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.id
    if L9_2 then
      L9_2 = L8_2.id
      L9_2 = L1_2[L9_2]
      if not L9_2 then
        L9_2 = #A0_2
        L9_2 = L9_2 + 1
        A0_2[L9_2] = L8_2
        L9_2 = L8_2.id
        L1_2[L9_2] = true
        L2_2 = true
      end
    end
  end
  L3_2 = A0_2
  L4_2 = L2_2
  return L3_2, L4_2
end
function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = GetResourceKvpString
  L1_2 = L0_1
  L0_2 = L0_2(L1_2)
  if L0_2 and "" ~= L0_2 then
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
        L3_2 = #L2_2
        if L3_2 > 0 then
          L3_2 = {}
          L4_2 = ipairs
          L5_2 = L2_2
          L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
          for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
            L10_2 = ApexCats
            L10_2 = L10_2.sanitize
            L11_2 = L9_2
            L10_2 = L10_2(L11_2)
            if L10_2 then
              L11_2 = #L3_2
              L11_2 = L11_2 + 1
              L3_2[L11_2] = L10_2
            end
          end
          L4_2 = #L3_2
          if L4_2 > 0 then
            L4_2 = L5_1
            L5_2 = L3_2
            L4_2, L5_2 = L4_2(L5_2)
            if L5_2 then
              L6_2 = SetResourceKvp
              L7_2 = L0_1
              L8_2 = json
              L8_2 = L8_2.encode
              L9_2 = L4_2
              L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
              L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
            end
            return L4_2
          end
        end
      end
    end
  end
  L1_2 = L5_1
  L2_2 = {}
  L1_2 = L1_2(L2_2)
  L2_2 = SetResourceKvp
  L3_2 = L0_1
  L4_2 = json
  L4_2 = L4_2.encode
  L5_2 = L1_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  return L1_2
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SetResourceKvp
  L2_2 = L0_1
  L3_2 = json
  L3_2 = L3_2.encode
  L4_2 = A0_2
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
end
function L8_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    if L7_2 == A0_2 then
      L8_2 = true
      return L8_2
    end
  end
  L2_2 = false
  return L2_2
end
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if A1_2 then
    L2_2 = #A1_2
    if L2_2 > 0 and A1_2 then
      goto lbl_10
      L2_2 = A1_2 or L2_2
    end
  end
  L2_2 = Config
  L2_2 = L2_2.StaffGroups
  ::lbl_10::
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = QBCore
    L9_2 = L9_2.Functions
    L9_2 = L9_2.HasPermission
    L10_2 = A0_2
    L11_2 = L8_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      L9_2 = true
      return L9_2
    end
  end
  L3_2 = false
  return L3_2
end
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = #A1_2
  if 0 == L2_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = ipairs
  L3_2 = GetPlayerIdentifiers
  L4_2 = A0_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L3_2(L4_2)
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = string
    L8_2 = L8_2.lower
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L9_2 = ipairs
    L10_2 = A1_2
    L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
    for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
      L15_2 = string
      L15_2 = L15_2.lower
      L16_2 = L14_2
      L15_2 = L15_2(L16_2)
      if L8_2 == L15_2 then
        L15_2 = true
        return L15_2
      end
    end
  end
  L2_2 = false
  return L2_2
end
function L11_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = A2_2.rule
  L4_2 = L3_2.type
  if "open" == L4_2 then
    L4_2 = true
    return L4_2
  end
  L4_2 = L3_2.type
  if "staff" == L4_2 then
    L4_2 = isAdmin
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if not L4_2 then
      L4_2 = L3_2.groups
      if L4_2 then
        L4_2 = L3_2.groups
        L4_2 = #L4_2
        L4_2 = L9_1
        L5_2 = A0_2
        L6_2 = L3_2.groups
        L4_2 = L4_2 > 0 and L4_2
      end
    end
    return L4_2
  end
  L4_2 = L3_2.type
  if "job" == L4_2 then
    L4_2 = L3_2.jobs
    L4_2 = #L4_2
    if 0 == L4_2 then
      L4_2 = true
      return L4_2
    end
    L4_2 = L8_1
    L5_2 = A1_2.PlayerData
    L5_2 = L5_2.job
    L5_2 = L5_2.name
    L6_2 = L3_2.jobs
    return L4_2(L5_2, L6_2)
  end
  L4_2 = L3_2.type
  if "grade" == L4_2 then
    L4_2 = L3_2.jobs
    L4_2 = #L4_2
    L4_2 = L8_1
    L5_2 = A1_2.PlayerData
    L5_2 = L5_2.job
    L5_2 = L5_2.name
    L6_2 = L3_2.jobs
    L4_2 = 0 == L4_2 or L4_2
    L5_2 = L4_2 or L5_2
    if L4_2 then
      L5_2 = QBCore
      L5_2 = L5_2.Functions
      L5_2 = L5_2.GetJobGrade
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      L6_2 = L3_2.minGrade
      if not L6_2 then
        L6_2 = 0
      end
      L5_2 = L5_2 >= L6_2
    end
    return L5_2
  end
  L4_2 = L3_2.type
  if "role" == L4_2 then
    L4_2 = L3_2.ace
    if L4_2 then
      L4_2 = IsPlayerAceAllowed
      L5_2 = A0_2
      L6_2 = L3_2.ace
      L4_2 = L4_2(L5_2, L6_2)
      if L4_2 then
        L4_2 = true
        return L4_2
      end
    end
    L4_2 = L10_1
    L5_2 = A0_2
    L6_2 = L3_2.identifiers
    L4_2 = L4_2(L5_2, L6_2)
    if L4_2 then
      L4_2 = true
      return L4_2
    end
    L4_2 = L3_2.groups
    if L4_2 then
      L4_2 = L3_2.groups
      L4_2 = #L4_2
      if L4_2 > 0 then
        L4_2 = L9_1
        L5_2 = A0_2
        L6_2 = L3_2.groups
        L4_2 = L4_2(L5_2, L6_2)
        if L4_2 then
          L4_2 = true
          return L4_2
        end
      end
    end
    L4_2 = false
    return L4_2
  end
  L4_2 = false
  return L4_2
end
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L3_2 = {}
  L4_2 = {}
  L5_2 = A2_2.visibility
  L6_2 = tonumber
  L7_2 = A2_2.area
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = 0
  end
  if L6_2 > 0 then
    L7_2 = GetEntityCoords
    L8_2 = GetPlayerPed
    L9_2 = A0_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
    if L7_2 then
      goto lbl_22
    end
  end
  L7_2 = nil
  ::lbl_22::
  L8_2 = nil
  if "job" == L5_2 then
    L9_2 = {}
    L8_2 = L9_2
    L9_2 = A2_2.rule
    L9_2 = L9_2.jobs
    L9_2 = #L9_2
    if L9_2 > 0 then
      L9_2 = ipairs
      L10_2 = A2_2.rule
      L10_2 = L10_2.jobs
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
        L8_2[L14_2] = true
      end
    else
      L9_2 = A1_2.PlayerData
      L9_2 = L9_2.job
      L9_2 = L9_2.name
      L8_2[L9_2] = true
    end
  end
  function L9_2(A0_3)
    local L1_3, L2_3
    L1_3 = L4_2
    L1_3 = L1_3[A0_3]
    if not L1_3 then
      L1_3 = L4_2
      L1_3[A0_3] = true
      L1_3 = L3_2
      L1_3 = #L1_3
      L2_3 = L1_3 + 1
      L1_3 = L3_2
      L1_3[L2_3] = A0_3
    end
  end
  L10_2 = ipairs
  L11_2 = QBCore
  L11_2 = L11_2.Functions
  L11_2 = L11_2.GetPlayers
  L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2 = L11_2()
  L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
    L16_2 = QBCore
    L16_2 = L16_2.Functions
    L16_2 = L16_2.GetPlayer
    L17_2 = L15_2
    L16_2 = L16_2(L17_2)
    if L16_2 then
      L17_2 = chatsHidden
      L17_2 = L17_2[L15_2]
      if nil == L17_2 then
        L17_2 = false
        if "all" == L5_2 then
          L17_2 = true
        elseif "sender" == L5_2 then
          L17_2 = L15_2 == A0_2
        elseif "staff" == L5_2 then
          L18_2 = isAdmin
          L19_2 = L16_2
          L18_2 = L18_2(L19_2)
          L17_2 = L18_2 or L17_2
          if not L18_2 then
            L18_2 = A2_2.rule
            L18_2 = L18_2.groups
            L17_2 = L18_2 or L17_2
            if L18_2 then
              L18_2 = A2_2.rule
              L18_2 = L18_2.groups
              L18_2 = #L18_2
              L18_2 = L9_1
              L19_2 = L15_2
              L20_2 = A2_2.rule
              L20_2 = L20_2.groups
              L18_2 = L18_2(L19_2, L20_2)
              L17_2 = L18_2 > 0 and L17_2
            end
          end
        elseif "role" == L5_2 then
          L18_2 = L11_1
          L19_2 = L15_2
          L20_2 = L16_2
          L21_2 = A2_2
          L18_2 = L18_2(L19_2, L20_2, L21_2)
          L17_2 = L18_2
        elseif "job" == L5_2 then
          L18_2 = L16_2.PlayerData
          L18_2 = L18_2.job
          L18_2 = L18_2.name
          L18_2 = L8_2[L18_2]
          L17_2 = true == L18_2
        end
        if L17_2 and L7_2 then
          L18_2 = GetEntityCoords
          L19_2 = GetPlayerPed
          L20_2 = L15_2
          L19_2, L20_2, L21_2 = L19_2(L20_2)
          L18_2 = L18_2(L19_2, L20_2, L21_2)
          L18_2 = L7_2 - L18_2
          L18_2 = #L18_2
          if L6_2 < L18_2 then
            L17_2 = false
          end
        end
        if L17_2 then
          L18_2 = L9_2
          L19_2 = L15_2
          L18_2(L19_2)
        end
      end
    end
  end
  L10_2 = chatsHidden
  L10_2 = L10_2[A0_2]
  if nil == L10_2 then
    L10_2 = L9_2
    L11_2 = A0_2
    L10_2(L11_2)
  end
  return L3_2
end
function L13_1(A0_2, A1_2)
  local L2_2, L3_2
  if "steam" == A1_2 then
    L2_2 = getSteamName
    L3_2 = A0_2
    return L2_2(L3_2)
  end
  if "anon" == A1_2 then
    L2_2 = "Anonymous"
    return L2_2
  end
  L2_2 = getName
  L3_2 = A0_2
  return L2_2(L3_2)
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = tostring
  L2_2 = A0_2.id
  if not L2_2 then
    L2_2 = ""
  end
  L1_2 = L1_2(L2_2)
  if "" == L1_2 then
    L2_2 = nil
    return L2_2
  end
  L2_2 = tostring
  L3_2 = A0_2.sender
  if not L3_2 then
    L3_2 = "Message"
  end
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "[\r\n]+"
  L5_2 = " "
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = tostring
  L4_2 = A0_2.text
  if not L4_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.gsub
  L5_2 = "[\r\n]+"
  L6_2 = " "
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = #L2_2
  if L4_2 > 64 then
    L5_2 = L2_2
    L4_2 = L2_2.sub
    L6_2 = 1
    L7_2 = 64
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L2_2 = L4_2
  end
  L4_2 = #L3_2
  L5_2 = 180
  if L4_2 > L5_2 then
    L5_2 = L3_2
    L4_2 = L3_2.sub
    L6_2 = 1
    L7_2 = 180
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2 = L4_2
  end
  L4_2 = {}
  L4_2.id = L1_2
  L4_2.sender = L2_2
  L4_2.text = L3_2
  return L4_2
end
function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "%s+"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  if "" == A0_2 then
    L1_2 = nil
    return L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.match
  L3_2 = "^https://[%w%.%-]+giphy%.com/"
  L1_2 = L1_2(L2_2, L3_2)
  if not L1_2 then
    L2_2 = A0_2
    L1_2 = A0_2.match
    L3_2 = "^https://[%w%.%-]+tenor%.com/"
    L1_2 = L1_2(L2_2, L3_2)
    if not L1_2 then
      goto lbl_35
    end
  end
  L1_2 = #A0_2
  L2_2 = 600
  L1_2 = A0_2 or L1_2
  if not (L1_2 <= L2_2) or not A0_2 then
    L1_2 = nil
  end
  do return L1_2 end
  ::lbl_35::
  L1_2 = Config
  L1_2 = L1_2.ScreenPhoto
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.ScreenPhoto
    L1_2 = L1_2.chatMaxBase64Length
    if L1_2 then
      goto lbl_45
    end
  end
  L1_2 = 900000
  ::lbl_45::
  L2_2 = #A0_2
  if L1_2 < L2_2 then
    L2_2 = nil
    return L2_2
  end
  L3_2 = A0_2
  L2_2 = A0_2.match
  L4_2 = "^data:image/png;base64,"
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.match
    L4_2 = "^data:image/jpeg;base64,"
    L2_2 = L2_2(L3_2, L4_2)
    if not L2_2 then
      L3_2 = A0_2
      L2_2 = A0_2.match
      L4_2 = "^data:image/jpg;base64,"
      L2_2 = L2_2(L3_2, L4_2)
      if not L2_2 then
        L3_2 = A0_2
        L2_2 = A0_2.match
        L4_2 = "^data:image/webp;base64,"
        L2_2 = L2_2(L3_2, L4_2)
      end
    end
  end
  if not L2_2 then
    L3_2 = nil
    return L3_2
  end
  return A0_2
end
function L16_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = TriggerClientEvent
  L4_2 = "apex_chat:recv"
  L5_2 = A0_2
  L6_2 = {}
  L7_2 = Utils
  L7_2 = L7_2.uuid
  L7_2 = L7_2()
  L6_2.id = L7_2
  L6_2.cat = "system"
  L6_2.catLabel = "SYSTEM"
  L6_2.command = ""
  L6_2.icon = "fas fa-circle-info"
  L7_2 = A2_2 or L7_2
  if not A2_2 then
    L7_2 = "#E5A93C"
  end
  L6_2.color = L7_2
  L6_2.identity = "steam"
  L7_2 = Config
  L7_2 = L7_2.MessageTitle
  if not L7_2 then
    L7_2 = "SYSTEM"
  end
  L6_2.sender = L7_2
  L6_2.senderId = false
  L6_2.text = A1_2
  L7_2 = os
  L7_2 = L7_2.date
  L8_2 = Config
  L8_2 = L8_2.DateFormat
  L7_2 = L7_2(L8_2)
  L6_2.time = L7_2
  L6_2.showAvatar = false
  L3_2(L4_2, L5_2, L6_2)
end
L17_1 = {}
L18_1 = {}
function L19_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = L17_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    return
  end
  L3_2 = L17_1
  L4_2 = {}
  L4_2.sender = A1_2
  L4_2.cat = A2_2
  L3_2[A0_2] = L4_2
  L3_2 = L18_1
  L3_2 = #L3_2
  L4_2 = L3_2 + 1
  L3_2 = L18_1
  L3_2[L4_2] = A0_2
  L3_2 = L18_1
  L3_2 = #L3_2
  L4_2 = 500
  if L3_2 > L4_2 then
    L3_2 = table
    L3_2 = L3_2.remove
    L4_2 = L18_1
    L5_2 = 1
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = L17_1
    L4_2[L3_2] = nil
  end
end
function L20_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L3_2 = Config
  L3_2 = L3_2.Mentions
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Mentions
    L3_2 = L3_2.enabled
    if false == L3_2 then
      L3_2 = nil
      return L3_2
    end
  end
  L4_2 = A0_2
  L3_2 = A0_2.find
  L5_2 = "@"
  L6_2 = 1
  L7_2 = true
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  if not L3_2 then
    L3_2 = nil
    return L3_2
  end
  L4_2 = A0_2
  L3_2 = A0_2.lower
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L5_2 = false
  L6_2 = ipairs
  L7_2 = A1_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    if L11_2 ~= A2_2 then
      L12_2 = QBCore
      L12_2 = L12_2.Functions
      L12_2 = L12_2.GetPlayer
      L13_2 = L11_2
      L12_2 = L12_2(L13_2)
      if L12_2 then
        L13_2 = getName
        L14_2 = L12_2
        L13_2 = L13_2(L14_2)
        if L13_2 then
          goto lbl_45
        end
      end
      L13_2 = nil
      ::lbl_45::
      L14_2 = false
      if L13_2 and "" ~= L13_2 then
        L16_2 = L13_2
        L15_2 = L13_2.lower
        L15_2 = L15_2(L16_2)
        L17_2 = L3_2
        L16_2 = L3_2.find
        L18_2 = "@"
        L19_2 = L15_2
        L18_2 = L18_2 .. L19_2
        L19_2 = 1
        L20_2 = true
        L16_2 = L16_2(L17_2, L18_2, L19_2, L20_2)
        L14_2 = nil ~= L16_2
        if not L14_2 then
          L17_2 = L15_2
          L16_2 = L15_2.match
          L18_2 = "^(%S+)"
          L16_2 = L16_2(L17_2, L18_2)
          if L16_2 then
            L18_2 = L3_2
            L17_2 = L3_2.find
            L19_2 = "@"
            L20_2 = L16_2
            L19_2 = L19_2 .. L20_2
            L20_2 = 1
            L21_2 = true
            L17_2 = L17_2(L18_2, L19_2, L20_2, L21_2)
          end
          L14_2 = nil ~= L17_2 or L14_2
        end
      end
      if not L14_2 then
        L16_2 = L3_2
        L15_2 = L3_2.find
        L17_2 = "@"
        L18_2 = tostring
        L19_2 = L11_2
        L18_2 = L18_2(L19_2)
        L17_2 = L17_2 .. L18_2
        L18_2 = 1
        L19_2 = true
        L15_2 = L15_2(L16_2, L17_2, L18_2, L19_2)
        L14_2 = nil ~= L15_2
      end
      if L14_2 then
        L4_2[L11_2] = true
        L5_2 = true
      end
    end
  end
  L6_2 = L4_2 or L6_2
  if not L5_2 or not L4_2 then
    L6_2 = nil
  end
  return L6_2
end
function L21_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2
  L5_2 = L12_1
  L6_2 = A0_2
  L7_2 = A1_2
  L8_2 = A2_2
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = os
  L6_2 = L6_2.date
  L7_2 = Config
  L7_2 = L7_2.DateFormat
  L6_2 = L6_2(L7_2)
  L7_2 = L13_1
  L8_2 = A1_2
  L9_2 = A2_2.identity
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = A2_2.identity
  L8_2 = "anon" == L8_2
  L9_2 = Config
  L9_2 = L9_2.Avatars
  if L9_2 then
    L9_2 = Config
    L9_2 = L9_2.Avatars
    L9_2 = L9_2.enabled
    if L9_2 then
      L9_2 = not L8_2
    end
  end
  if A4_2 then
    L10_2 = L14_1
    L11_2 = A4_2.replyTo
    L10_2 = L10_2(L11_2)
    if L10_2 then
      goto lbl_38
    end
  end
  L10_2 = nil
  ::lbl_38::
  if A4_2 then
    L11_2 = L15_1
    L12_2 = A4_2.image
    L11_2 = L11_2(L12_2)
    if L11_2 then
      goto lbl_46
    end
  end
  L11_2 = nil
  ::lbl_46::
  L12_2 = Utils
  L12_2 = L12_2.uuid
  L12_2 = L12_2()
  L13_2 = L19_1
  L14_2 = L12_2
  L15_2 = A0_2
  L16_2 = A2_2.id
  L13_2(L14_2, L15_2, L16_2)
  L13_2 = L20_1
  L14_2 = A3_2
  L15_2 = L5_2
  L16_2 = A0_2
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  function L14_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = L7_2
    L2_3 = Config
    L2_3 = L2_3.ShowIDOnMessageForEveryone
    if L2_3 or A0_3 then
      L2_3 = L8_2
      if L2_3 then
        L2_3 = not A0_3
        if L2_3 then
          goto lbl_29
        end
      end
      if A0_3 then
        L2_3 = L8_2
        if L2_3 then
          L2_3 = getName
          L3_3 = A1_2
          L2_3 = L2_3(L3_3)
          L1_3 = L2_3
        end
      end
      L2_3 = L1_3
      L3_3 = " ["
      L4_3 = A0_2
      L5_3 = "]"
      L2_3 = L2_3 .. L3_3 .. L4_3 .. L5_3
      L1_3 = L2_3
    end
    ::lbl_29::
    L2_3 = {}
    L3_3 = L12_2
    L2_3.id = L3_3
    L3_3 = A2_2.id
    L2_3.cat = L3_3
    L3_3 = A2_2.label
    L2_3.catLabel = L3_3
    L3_3 = A2_2.command
    L2_3.command = L3_3
    L3_3 = A2_2.icon
    L2_3.icon = L3_3
    L3_3 = A2_2.color
    L2_3.color = L3_3
    L3_3 = A2_2.bg
    L2_3.bg = L3_3
    L3_3 = A2_2.identity
    L2_3.identity = L3_3
    L2_3.sender = L1_3
    L3_3 = L9_2
    if L3_3 then
      L3_3 = L8_2
      if not L3_3 or A0_3 then
        L3_3 = A0_2
        if L3_3 then
          goto lbl_60
        end
      end
    end
    L3_3 = false
    ::lbl_60::
    L2_3.senderId = L3_3
    L3_3 = A3_2
    L2_3.text = L3_3
    L3_3 = L6_2
    L2_3.time = L3_3
    L3_3 = L9_2
    if L3_3 then
      L3_3 = L8_2
      L3_3 = not L3_3 or L3_3
    end
    L2_3.showAvatar = L3_3
    L3_3 = L10_2
    L2_3.replyTo = L3_3
    L3_3 = L11_2
    L2_3.image = L3_3
    L3_3 = L8_2
    if not L3_3 or A0_3 then
      L3_3 = ApexTags
      if L3_3 then
        L3_3 = ApexTags
        L3_3 = L3_3.forSource
        L4_3 = A0_2
        L3_3 = L3_3(L4_3)
        if L3_3 then
          goto lbl_95
        end
      end
    end
    L3_3 = nil
    ::lbl_95::
    L2_3.tags = L3_3
    return L2_3
  end
  L15_2 = L14_2
  L16_2 = false
  L15_2 = L15_2(L16_2)
  L16_2 = nil
  L17_2 = Config
  L17_2 = L17_2.ShowIDOnMessage
  if L17_2 then
    L17_2 = Config
    L17_2 = L17_2.ShowIDOnMessageForEveryone
    L17_2 = not L17_2
  end
  function L18_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L2_3 = L13_2
    if L2_3 then
      L2_3 = L13_2
      L2_3 = L2_3[A0_3]
      if L2_3 then
        L2_3 = {}
        L3_3 = pairs
        L4_3 = A1_3
        L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3)
        for L7_3, L8_3 in L3_3, L4_3, L5_3, L6_3 do
          L2_3[L7_3] = L8_3
        end
        L2_3.mention = true
        L3_3 = TriggerClientEvent
        L4_3 = "apex_chat:recv"
        L5_3 = A0_3
        L6_3 = L2_3
        L3_3(L4_3, L5_3, L6_3)
    end
    else
      L2_3 = TriggerClientEvent
      L3_3 = "apex_chat:recv"
      L4_3 = A0_3
      L5_3 = A1_3
      L2_3(L3_3, L4_3, L5_3)
    end
  end
  L19_2 = ipairs
  L20_2 = L5_2
  L19_2, L20_2, L21_2, L22_2 = L19_2(L20_2)
  for L23_2, L24_2 in L19_2, L20_2, L21_2, L22_2 do
    if (L17_2 or L8_2) and L24_2 ~= A0_2 then
      L25_2 = QBCore
      L25_2 = L25_2.Functions
      L25_2 = L25_2.GetPlayer
      L26_2 = L24_2
      L25_2 = L25_2(L26_2)
      if L25_2 then
        L26_2 = isAdmin
        L27_2 = L25_2
        L26_2 = L26_2(L27_2)
        if L26_2 then
          if not L16_2 then
            L26_2 = L14_2
            L27_2 = true
            L26_2 = L26_2(L27_2)
            L16_2 = L26_2
          end
          L26_2 = L18_2
          L27_2 = L24_2
          L28_2 = L16_2
          L26_2(L27_2, L28_2)
      end
      else
        L26_2 = L18_2
        L27_2 = L24_2
        L28_2 = L15_2
        L26_2(L27_2, L28_2)
      end
    else
      L25_2 = L18_2
      L26_2 = L24_2
      L27_2 = L15_2
      L25_2(L26_2, L27_2)
    end
  end
  L19_2 = type
  L20_2 = A2_2.webhook
  L19_2 = L19_2(L20_2)
  if "string" == L19_2 then
    L19_2 = A2_2.webhook
    if "" ~= L19_2 then
      L19_2 = A2_2.webhook
      if L19_2 then
        goto lbl_129
      end
    end
  end
  L19_2 = Webhook
  ::lbl_129::
  if L19_2 and "" ~= L19_2 then
    L20_2 = ExtractIdentifiers
    L21_2 = A0_2
    L20_2 = L20_2(L21_2)
    L21_2 = discordWebhook
    L22_2 = {}
    L22_2.webhook = L19_2
    L22_2.playerid = A0_2
    L23_2 = L20_2.license
    if not L23_2 then
      L23_2 = ""
    end
    L24_2 = L23_2
    L23_2 = L23_2.gsub
    L25_2 = "license:"
    L26_2 = ""
    L23_2 = L23_2(L24_2, L25_2, L26_2)
    L22_2.identifier = L23_2
    L23_2 = "<@"
    L24_2 = L20_2.discord
    if not L24_2 then
      L24_2 = ""
    end
    L25_2 = L24_2
    L24_2 = L24_2.gsub
    L26_2 = "discord:"
    L27_2 = ""
    L24_2 = L24_2(L25_2, L26_2, L27_2)
    L25_2 = ">"
    L23_2 = L23_2 .. L24_2 .. L25_2
    L22_2.discord = L23_2
    L23_2 = "Category [%s]"
    L24_2 = L23_2
    L23_2 = L23_2.format
    L25_2 = A2_2.label
    L23_2 = L23_2(L24_2, L25_2)
    L22_2.type = L23_2
    L22_2.message = A3_2
    L21_2(L22_2)
  end
end
L22_1 = {}
function L23_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = Config
  L3_2 = L3_2.SlowMode
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = L3_2.enabled
  if false == L4_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = L3_2.exemptStaff
  if false ~= L4_2 then
    L4_2 = isAdmin
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = false
      return L4_2
    end
  end
  L4_2 = GetGameTimer
  L4_2 = L4_2()
  L5_2 = L22_1
  L5_2 = L5_2[A0_2]
  if L5_2 then
    L6_2 = tonumber
    L7_2 = L3_2.cooldownMs
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = 2000
    end
    L7_2 = L5_2.lastAt
    L7_2 = L4_2 - L7_2
    if L6_2 > L7_2 then
      L8_2 = L16_1
      L9_2 = A0_2
      L10_2 = L
      L11_2 = "slow_wait"
      L10_2 = L10_2(L11_2)
      L11_2 = L10_2
      L10_2 = L10_2.format
      L12_2 = L6_2 - L7_2
      L12_2 = L12_2 / 1000
      L10_2 = L10_2(L11_2, L12_2)
      L11_2 = "#E5A93C"
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = true
      return L8_2
    end
    L8_2 = tonumber
    L9_2 = L3_2.duplicateMs
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = 6000
    end
    L9_2 = L5_2.lastText
    L11_2 = A2_2
    L10_2 = A2_2.lower
    L10_2 = L10_2(L11_2)
    if L9_2 == L10_2 then
      L9_2 = L5_2.lastTextAt
      L9_2 = L4_2 - L9_2
      if L8_2 > L9_2 then
        L9_2 = L16_1
        L10_2 = A0_2
        L11_2 = L
        L12_2 = "slow_duplicate"
        L11_2 = L11_2(L12_2)
        L12_2 = "#E5A93C"
        L9_2(L10_2, L11_2, L12_2)
        L9_2 = true
        return L9_2
      end
    end
  end
  L6_2 = L22_1
  L7_2 = {}
  L7_2.lastAt = L4_2
  L9_2 = A2_2
  L8_2 = A2_2.lower
  L8_2 = L8_2(L9_2)
  L7_2.lastText = L8_2
  L7_2.lastTextAt = L4_2
  L6_2[A0_2] = L7_2
  L6_2 = false
  return L6_2
end
function L24_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = L3_1
  L4_2 = L4_2[A1_2]
  if L4_2 then
    L5_2 = L4_2.enabled
    if L5_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L5_2 = QBCore
  L5_2 = L5_2.Functions
  L5_2 = L5_2.GetPlayer
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    return
  end
  L6_2 = chatsHidden
  L6_2 = L6_2[A0_2]
  if L6_2 then
    return
  end
  L6_2 = IsMuted
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L6_2 = L16_1
    L7_2 = A0_2
    L8_2 = L
    L9_2 = "muted_for"
    L8_2 = L8_2(L9_2)
    L9_2 = L8_2
    L8_2 = L8_2.format
    L10_2 = SecondsToClock
    L11_2 = MuteRemaining
    L12_2 = A0_2
    L11_2, L12_2, L13_2 = L11_2(L12_2)
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2, L12_2, L13_2)
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    return
  end
  L6_2 = tostring
  L7_2 = A2_2 or L7_2
  if not A2_2 then
    L7_2 = ""
  end
  L6_2 = L6_2(L7_2)
  L7_2 = L6_2
  L6_2 = L6_2.gsub
  L8_2 = "^%s+"
  L9_2 = ""
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L7_2 = L6_2
  L6_2 = L6_2.gsub
  L8_2 = "%s+$"
  L9_2 = ""
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  A2_2 = L6_2
  if A3_2 then
    L6_2 = L15_1
    L7_2 = A3_2.image
    L6_2 = L6_2(L7_2)
    if L6_2 then
      goto lbl_63
    end
  end
  L6_2 = nil
  ::lbl_63::
  if "" == A2_2 and not L6_2 then
    return
  end
  L7_2 = Shared
  L7_2 = L7_2.UI
  if L7_2 then
    L7_2 = Shared
    L7_2 = L7_2.UI
    L7_2 = L7_2.General
    if L7_2 then
      L7_2 = Shared
      L7_2 = L7_2.UI
      L7_2 = L7_2.General
      L7_2 = L7_2.MaxMessageLength
      if L7_2 then
        goto lbl_84
      end
    end
  end
  L7_2 = 300
  ::lbl_84::
  L8_2 = #A2_2
  if L7_2 < L8_2 then
    L9_2 = A2_2
    L8_2 = A2_2.sub
    L10_2 = 1
    L11_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    A2_2 = L8_2
  end
  L8_2 = L11_1
  L9_2 = A0_2
  L10_2 = L5_2
  L11_2 = L4_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if not L8_2 then
    L8_2 = L16_1
    L9_2 = A0_2
    L10_2 = L
    L11_2 = "cant_send_here"
    L10_2 = L10_2(L11_2)
    L11_2 = L10_2
    L10_2 = L10_2.format
    L12_2 = L4_2.label
    L10_2 = L10_2(L11_2, L12_2)
    L11_2 = "#E5564B"
    L8_2(L9_2, L10_2, L11_2)
    return
  end
  L8_2 = L23_1
  L9_2 = A0_2
  L10_2 = L5_2
  L11_2 = A2_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if L8_2 then
    return
  end
  L8_2 = L21_1
  L9_2 = A0_2
  L10_2 = L5_2
  L11_2 = L4_2
  L12_2 = A2_2
  L13_2 = A3_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
end
function L25_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2.id
  L1_2 = L3_1
  L1_2[L2_2] = A0_2
  L2_2 = A0_2.id
  L1_2 = L2_1
  L1_2[L2_2] = A0_2
  L2_2 = A0_2.command
  L1_2 = L1_1
  L1_2 = L1_2[L2_2]
  if not L1_2 then
    L2_2 = A0_2.command
    L1_2 = L1_1
    L1_2[L2_2] = true
    L1_2 = RegisterCommand
    L2_2 = A0_2.command
    function L3_2(A0_3, A1_3, A2_3)
      local L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      if A0_3 <= 0 then
        return
      end
      L4_3 = A0_2.id
      L3_3 = L3_1
      L3_3 = L3_3[L4_3]
      if not L3_3 then
        return
      end
      L5_3 = A2_3
      L4_3 = A2_3.sub
      L6_3 = L3_3.command
      L6_3 = #L6_3
      L6_3 = L6_3 + 1
      L4_3 = L4_3(L5_3, L6_3)
      L5_3 = L24_1
      L6_3 = A0_3
      L7_3 = A0_2.id
      L8_3 = L4_3
      L5_3(L6_3, L7_3, L8_3)
    end
    L4_2 = false
    L1_2(L2_2, L3_2, L4_2)
  end
end
function L26_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = QBCore
  L1_2 = L1_2.Functions
  L1_2 = L1_2.GetPlayer
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = Config
  L2_2 = L2_2.CategoryManager
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.CategoryManager
    L2_2 = L2_2.authorGroups
    if L2_2 then
      goto lbl_23
    end
  end
  L2_2 = {}
  L3_2 = "admin"
  L2_2[1] = L3_2
  ::lbl_23::
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    if "everyone" == L8_2 then
      L9_2 = true
      return L9_2
    end
    L9_2 = QBCore
    L9_2 = L9_2.Functions
    L9_2 = L9_2.HasPermission
    L10_2 = A0_2
    L11_2 = L8_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      L9_2 = true
      return L9_2
    end
  end
  L3_2 = false
  return L3_2
end
function L27_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = L2_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = #L0_2
    L7_2 = L7_2 + 1
    L0_2[L7_2] = L6_2
  end
  L1_2 = table
  L1_2 = L1_2.sort
  L2_2 = L0_2
  function L3_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.order
    if not L2_3 then
      L2_3 = 999
    end
    L3_3 = A1_3.order
    if not L3_3 then
      L3_3 = 999
    end
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  L1_2(L2_2, L3_2)
  return L0_2
end
function L28_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = QBCore
  L1_2 = L1_2.Functions
  L1_2 = L1_2.GetPlayer
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = L26_1
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = ipairs
  L6_2 = L27_1
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2()
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = #L3_2
    L11_2 = L11_2 + 1
    L12_2 = ApexCats
    L12_2 = L12_2.toClient
    L13_2 = L10_2
    L14_2 = L4_2
    L12_2 = L12_2(L13_2, L14_2)
    L3_2[L11_2] = L12_2
    L11_2 = L10_2.enabled
    if L11_2 then
      L11_2 = L11_1
      L12_2 = A0_2
      L13_2 = L1_2
      L14_2 = L10_2
      L11_2 = L11_2(L12_2, L13_2, L14_2)
      if L11_2 then
        L11_2 = #L2_2
        L11_2 = L11_2 + 1
        L12_2 = ApexCats
        L12_2 = L12_2.toClient
        L13_2 = L10_2
        L14_2 = false
        L12_2 = L12_2(L13_2, L14_2)
        L2_2[L11_2] = L12_2
      end
    end
  end
  L5_2 = TriggerClientEvent
  L6_2 = "apex_chat:cats:sync"
  L7_2 = A0_2
  L8_2 = {}
  L8_2.tabs = L2_2
  L9_2 = L3_2 or L9_2
  if not L4_2 or not L3_2 then
    L9_2 = nil
  end
  L8_2.all = L9_2
  L8_2.isManager = L4_2
  L9_2 = Config
  L9_2 = L9_2.DefaultCategory
  L8_2.default = L9_2
  L5_2(L6_2, L7_2, L8_2)
end
function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = ipairs
  L1_2 = QBCore
  L1_2 = L1_2.Functions
  L1_2 = L1_2.GetPlayers
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2()
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = L28_1
    L7_2 = L5_2
    L6_2(L7_2)
  end
end
L30_1 = RegisterNetEvent
L31_1 = "apex_chat:ingest"
L30_1(L31_1)
L30_1 = AddEventHandler
L31_1 = "apex_chat:ingest"
function L32_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = source
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = L24_1
  L3_2 = L1_2
  L4_2 = tostring
  L5_2 = A0_2.cat
  if not L5_2 then
    L5_2 = ""
  end
  L4_2 = L4_2(L5_2)
  L5_2 = A0_2.text
  if not L5_2 then
    L5_2 = ""
  end
  L6_2 = {}
  L7_2 = A0_2.replyTo
  L6_2.replyTo = L7_2
  L7_2 = A0_2.image
  L6_2.image = L7_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L30_1(L31_1, L32_1)
function L30_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = GetRegisteredCommands
  if not L2_2 then
    return
  end
  if not A1_2 then
    L2_2 = GetRegisteredCommands
    L2_2 = L2_2()
    A1_2 = L2_2
  end
  L2_2 = {}
  L3_2 = {}
  L4_2 = ipairs
  L5_2 = A1_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L9_2 or L10_2
    if L9_2 then
      L10_2 = L9_2.name
    end
    if L10_2 and "" ~= L10_2 then
      L11_2 = L3_2[L10_2]
      if not L11_2 then
        L11_2 = true
        L12_2 = L9_2.restricted
        if L12_2 then
          L12_2 = IsPlayerAceAllowed
          L13_2 = A0_2
          L14_2 = "command.%s"
          L15_2 = L14_2
          L14_2 = L14_2.format
          L16_2 = L10_2
          L14_2, L15_2, L16_2 = L14_2(L15_2, L16_2)
          L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2)
          L11_2 = L12_2
        end
        if L11_2 then
          L3_2[L10_2] = true
          L12_2 = #L2_2
          L12_2 = L12_2 + 1
          L13_2 = {}
          L14_2 = "/"
          L15_2 = L10_2
          L14_2 = L14_2 .. L15_2
          L13_2.name = L14_2
          L13_2.help = ""
          L2_2[L12_2] = L13_2
        end
      end
    end
  end
  L4_2 = TriggerClientEvent
  L5_2 = "chat:addSuggestions"
  L6_2 = A0_2
  L7_2 = L2_2
  L4_2(L5_2, L6_2, L7_2)
end
L31_1 = RegisterNetEvent
L32_1 = "apex_chat:commands:request"
L31_1(L32_1)
L31_1 = AddEventHandler
L32_1 = "apex_chat:commands:request"
function L33_1()
  local L0_2, L1_2
  L0_2 = L30_1
  L1_2 = source
  L0_2(L1_2)
end
L31_1(L32_1, L33_1)
L31_1 = 0
L32_1 = false
function L33_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = A0_2 or L2_2
  if not A0_2 then
    L2_2 = 750
  end
  L1_2 = L1_2 + L2_2
  L31_1 = L1_2
  L1_2 = L32_1
  if L1_2 then
    return
  end
  L1_2 = true
  L32_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3
    while true do
      L0_3 = GetGameTimer
      L0_3 = L0_3()
      L1_3 = L31_1
      if not (L0_3 < L1_3) then
        break
      end
      L0_3 = Wait
      L1_3 = 250
      L0_3(L1_3)
    end
    L0_3 = false
    L32_1 = L0_3
    L0_3 = GetPlayers
    L0_3 = L0_3()
    L1_3 = #L0_3
    if 0 == L1_3 then
      return
    end
    L1_3 = GetRegisteredCommands
    L1_3 = L1_3()
    L2_3 = ipairs
    L3_3 = L0_3
    L2_3, L3_3, L4_3, L5_3 = L2_3(L3_3)
    for L6_3, L7_3 in L2_3, L3_3, L4_3, L5_3 do
      L8_3 = L30_1
      L9_3 = tonumber
      L10_3 = L7_3
      L9_3 = L9_3(L10_3)
      L10_3 = L1_3
      L8_3(L9_3, L10_3)
    end
  end
  L1_2(L2_2)
end
L34_1 = AddEventHandler
L35_1 = "onResourceStart"
function L36_1()
  local L0_2, L1_2
  L0_2 = L33_1
  L1_2 = 750
  L0_2(L1_2)
end
L34_1(L35_1, L36_1)
function L34_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = {}
  L2_2 = L4_1
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = pairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = 0
    L10_2 = pairs
    L11_2 = L8_2
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    for L14_2 in L10_2, L11_2, L12_2, L13_2 do
      L9_2 = L9_2 + 1
    end
    if L9_2 > 0 then
      L10_2 = #L1_2
      L10_2 = L10_2 + 1
      L11_2 = {}
      L11_2.type = L7_2
      L11_2.count = L9_2
      L1_2[L10_2] = L11_2
    end
  end
  L3_2 = table
  L3_2 = L3_2.sort
  L4_2 = L1_2
  function L5_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.type
    L3_3 = A1_3.type
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  L3_2(L4_2, L5_2)
  return L1_2
end
L35_1 = RegisterNetEvent
L36_1 = "apex_chat:react"
L35_1(L36_1)
L35_1 = AddEventHandler
L36_1 = "apex_chat:react"
function L37_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = source
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = tostring
  L3_2 = A0_2.id
  if not L3_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
  L3_2 = tostring
  L4_2 = A0_2.type
  if not L4_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.gsub
  L5_2 = "[\r\n\t]"
  L6_2 = ""
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if "" ~= L2_2 and "" ~= L3_2 then
    L4_2 = #L3_2
    if not (L4_2 > 16) then
      goto lbl_32
    end
  end
  do return end
  ::lbl_32::
  L4_2 = L4_1
  L5_2 = L4_1
  L5_2 = L5_2[L2_2]
  if not L5_2 then
    L5_2 = {}
  end
  L4_2[L2_2] = L5_2
  L4_2 = L4_1
  L4_2 = L4_2[L2_2]
  L5_2 = L4_1
  L5_2 = L5_2[L2_2]
  L5_2 = L5_2[L3_2]
  if not L5_2 then
    L5_2 = {}
  end
  L4_2[L3_2] = L5_2
  L4_2 = L4_1
  L4_2 = L4_2[L2_2]
  L4_2 = L4_2[L3_2]
  L4_2 = L4_2[L1_2]
  if L4_2 then
    L4_2 = L4_1
    L4_2 = L4_2[L2_2]
    L4_2 = L4_2[L3_2]
    L4_2[L1_2] = nil
  else
    L4_2 = L4_1
    L4_2 = L4_2[L2_2]
    L4_2 = L4_2[L3_2]
    L4_2[L1_2] = true
  end
  L4_2 = TriggerClientEvent
  L5_2 = "apex_chat:reactionUpdate"
  L6_2 = -1
  L7_2 = {}
  L7_2.id = L2_2
  L8_2 = L34_1
  L9_2 = L2_2
  L8_2 = L8_2(L9_2)
  L7_2.reactions = L8_2
  L4_2(L5_2, L6_2, L7_2)
end
L35_1(L36_1, L37_1)
L35_1 = {}
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:typing"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:typing"
function L38_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = source
  L2_2 = Config
  L2_2 = L2_2.Typing
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = L2_2.enabled
  if false == L3_2 then
    return
  end
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L4_2 = L35_1
  L4_2 = L4_2[L1_2]
  if L4_2 then
    L4_2 = L35_1
    L4_2 = L4_2[L1_2]
    L4_2 = L3_2 - L4_2
    L5_2 = tonumber
    L6_2 = L2_2.throttleMs
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L5_2 = 900
    end
    if L4_2 < L5_2 then
      return
    end
  end
  L4_2 = L35_1
  L4_2[L1_2] = L3_2
  L4_2 = tostring
  L5_2 = A0_2 or L5_2
  if not A0_2 then
    L5_2 = ""
  end
  L4_2 = L4_2(L5_2)
  L5_2 = L3_1
  L4_2 = L5_2[L4_2]
  if L4_2 then
    L5_2 = L4_2.enabled
    if L5_2 then
      L5_2 = L4_2.identity
      if "anon" ~= L5_2 then
        goto lbl_49
      end
    end
  end
  do return end
  ::lbl_49::
  L5_2 = QBCore
  L5_2 = L5_2.Functions
  L5_2 = L5_2.GetPlayer
  L6_2 = L1_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    return
  end
  L6_2 = L11_1
  L7_2 = L1_2
  L8_2 = L5_2
  L9_2 = L4_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if not L6_2 then
    return
  end
  L6_2 = L13_1
  L7_2 = L5_2
  L8_2 = L4_2.identity
  L6_2 = L6_2(L7_2, L8_2)
  L7_2 = ipairs
  L8_2 = L12_1
  L9_2 = L1_2
  L10_2 = L5_2
  L11_2 = L4_2
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L8_2(L9_2, L10_2, L11_2)
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
    if L12_2 ~= L1_2 then
      L13_2 = TriggerClientEvent
      L14_2 = "apex_chat:typing:show"
      L15_2 = L12_2
      L16_2 = {}
      L17_2 = L4_2.id
      L16_2.cat = L17_2
      L16_2.id = L1_2
      L16_2.name = L6_2
      L13_2(L14_2, L15_2, L16_2)
    end
  end
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:roster:request"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:roster:request"
function L38_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L0_2 = source
  L1_2 = Config
  L1_2 = L1_2.Mentions
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.Mentions
    L1_2 = L1_2.enabled
    if false == L1_2 then
      L1_2 = TriggerClientEvent
      L2_2 = "apex_chat:roster:sync"
      L3_2 = L0_2
      L4_2 = {}
      L1_2(L2_2, L3_2, L4_2)
      return
    end
  end
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = QBCore
  L3_2 = L3_2.Functions
  L3_2 = L3_2.GetPlayers
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L3_2()
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = QBCore
    L8_2 = L8_2.Functions
    L8_2 = L8_2.GetPlayer
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if L8_2 then
      L9_2 = getName
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 and "" ~= L9_2 then
        L10_2 = #L1_2
        L10_2 = L10_2 + 1
        L11_2 = {}
        L12_2 = tonumber
        L13_2 = L7_2
        L12_2 = L12_2(L13_2)
        if not L12_2 then
          L12_2 = L7_2
        end
        L11_2.id = L12_2
        L11_2.name = L9_2
        L13_2 = L9_2
        L12_2 = L9_2.match
        L14_2 = "^(%S+)"
        L12_2 = L12_2(L13_2, L14_2)
        if not L12_2 then
          L12_2 = L9_2
        end
        L11_2.first = L12_2
        L1_2[L10_2] = L11_2
      end
    end
  end
  L2_2 = TriggerClientEvent
  L3_2 = "apex_chat:roster:sync"
  L4_2 = L0_2
  L5_2 = L1_2
  L2_2(L3_2, L4_2, L5_2)
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:msg:remove"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:msg:remove"
function L38_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = source
  L2_2 = QBCore
  L2_2 = L2_2.Functions
  L2_2 = L2_2.GetPlayer
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = isAdmin
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_20
    end
    L3_2 = L26_1
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_20
    end
  end
  do return end
  ::lbl_20::
  L3_2 = tostring
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  A0_2 = L3_2
  if "" ~= A0_2 then
    L3_2 = L17_1
    L3_2 = L3_2[A0_2]
    if L3_2 then
      goto lbl_33
    end
  end
  do return end
  ::lbl_33::
  L3_2 = L17_1
  L3_2[A0_2] = nil
  L3_2 = TriggerClientEvent
  L4_2 = "apex_chat:msg:removed"
  L5_2 = -1
  L6_2 = A0_2
  L3_2(L4_2, L5_2, L6_2)
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:msg:edit"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:msg:edit"
function L38_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = source
  L3_2 = QBCore
  L3_2 = L3_2.Functions
  L3_2 = L3_2.GetPlayer
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L4_2 = isAdmin
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_20
    end
    L4_2 = L26_1
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_20
    end
  end
  do return end
  ::lbl_20::
  L4_2 = tostring
  L5_2 = A0_2 or L5_2
  if not A0_2 then
    L5_2 = ""
  end
  L4_2 = L4_2(L5_2)
  A0_2 = L4_2
  if "" ~= A0_2 then
    L4_2 = L17_1
    L4_2 = L4_2[A0_2]
    if L4_2 then
      goto lbl_33
    end
  end
  do return end
  ::lbl_33::
  L4_2 = tostring
  L5_2 = A1_2 or L5_2
  if not A1_2 then
    L5_2 = ""
  end
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.gsub
  L6_2 = "^%s+"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = L4_2
  L4_2 = L4_2.gsub
  L6_2 = "%s+$"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  A1_2 = L4_2
  if "" == A1_2 then
    return
  end
  L4_2 = Shared
  L4_2 = L4_2.UI
  if L4_2 then
    L4_2 = Shared
    L4_2 = L4_2.UI
    L4_2 = L4_2.General
    if L4_2 then
      L4_2 = Shared
      L4_2 = L4_2.UI
      L4_2 = L4_2.General
      L4_2 = L4_2.MaxMessageLength
      if L4_2 then
        goto lbl_66
      end
    end
  end
  L4_2 = 300
  ::lbl_66::
  L5_2 = #A1_2
  if L4_2 < L5_2 then
    L6_2 = A1_2
    L5_2 = A1_2.sub
    L7_2 = 1
    L8_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    A1_2 = L5_2
  end
  L5_2 = TriggerClientEvent
  L6_2 = "apex_chat:msg:edited"
  L7_2 = -1
  L8_2 = {}
  L8_2.id = A0_2
  L8_2.text = A1_2
  L5_2(L6_2, L7_2, L8_2)
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:cats:request"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:cats:request"
function L38_1()
  local L0_2, L1_2
  L0_2 = L28_1
  L1_2 = source
  L0_2(L1_2)
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:cats:save"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:cats:save"
function L38_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = source
  L2_2 = L26_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = TriggerClientEvent
    L3_2 = "okokChat:Notification"
    L4_2 = L1_2
    L5_2 = {}
    L5_2.title = "CATEGORIES"
    L5_2.type = "error"
    L5_2.time = 4000
    L6_2 = L
    L7_2 = "cat_no_manage"
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L6_2(L7_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    return
  end
  L2_2 = ApexCats
  L2_2 = L2_2.sanitize
  L3_2 = A0_2
  L2_2, L3_2 = L2_2(L3_2)
  if not L2_2 then
    L4_2 = TriggerClientEvent
    L5_2 = "okokChat:Notification"
    L6_2 = L1_2
    L7_2 = {}
    L7_2.title = "CATEGORIES"
    L7_2.type = "error"
    L7_2.time = 4000
    L8_2 = L
    L9_2 = "cat_invalid"
    L8_2 = L8_2(L9_2)
    L9_2 = L8_2
    L8_2 = L8_2.format
    L10_2 = tostring
    L11_2 = L3_2
    L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L10_2(L11_2)
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    return
  end
  L4_2 = L6_1
  L4_2 = L4_2()
  L5_2 = false
  L6_2 = ipairs
  L7_2 = L4_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    L12_2 = L11_2.id
    L13_2 = L2_2.id
    if L12_2 == L13_2 then
      L4_2[L10_2] = L2_2
      L5_2 = true
    else
      L12_2 = L11_2.command
      L13_2 = L2_2.command
      if L12_2 == L13_2 then
        L12_2 = TriggerClientEvent
        L13_2 = "okokChat:Notification"
        L14_2 = L1_2
        L15_2 = {}
        L15_2.title = "CATEGORIES"
        L15_2.type = "error"
        L15_2.time = 4000
        L16_2 = L
        L17_2 = "cat_cmd_taken"
        L16_2 = L16_2(L17_2)
        L17_2 = L16_2
        L16_2 = L16_2.format
        L18_2 = L2_2.command
        L16_2, L17_2, L18_2 = L16_2(L17_2, L18_2)
        L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
        return
      end
    end
  end
  if not L5_2 then
    L6_2 = #L4_2
    L7_2 = Config
    L7_2 = L7_2.CategoryManager
    if L7_2 then
      L7_2 = Config
      L7_2 = L7_2.CategoryManager
      L7_2 = L7_2.maxTotal
      if L7_2 then
        goto lbl_94
      end
    end
    L7_2 = 100
    ::lbl_94::
    if L6_2 >= L7_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = L1_2
      L9_2 = {}
      L9_2.title = "CATEGORIES"
      L9_2.type = "error"
      L9_2.time = 4000
      L10_2 = L
      L11_2 = "cat_too_many"
      L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L10_2(L11_2)
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
      return
    end
    L6_2 = #L4_2
    L6_2 = L6_2 + 1
    L4_2[L6_2] = L2_2
  end
  L6_2 = L7_1
  L7_2 = L4_2
  L6_2(L7_2)
  L6_2 = L25_1
  L7_2 = L2_2
  L6_2(L7_2)
  L6_2 = TriggerClientEvent
  L7_2 = "okokChat:Notification"
  L8_2 = L1_2
  L9_2 = {}
  L9_2.title = "CATEGORIES"
  L9_2.type = "success"
  L9_2.time = 4000
  L10_2 = L
  L11_2 = "cat_saved"
  L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L10_2(L11_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L6_2 = L29_1
  L6_2()
end
L36_1(L37_1, L38_1)
L36_1 = RegisterNetEvent
L37_1 = "apex_chat:cats:delete"
L36_1(L37_1)
L36_1 = AddEventHandler
L37_1 = "apex_chat:cats:delete"
function L38_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = source
  L2_2 = L26_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = L6_1
  L2_2 = L2_2()
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.id
    if L9_2 == A0_2 then
      L9_2 = table
      L9_2 = L9_2.remove
      L10_2 = L2_2
      L11_2 = L7_2
      L9_2(L10_2, L11_2)
      L9_2 = L2_1
      L9_2[A0_2] = nil
      L9_2 = L3_1
      L9_2[A0_2] = nil
      break
    end
  end
  L3_2 = L7_1
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = TriggerClientEvent
  L4_2 = "okokChat:Notification"
  L5_2 = L1_2
  L6_2 = {}
  L6_2.title = "CATEGORIES"
  L6_2.type = "success"
  L6_2.time = 4000
  L7_2 = L
  L8_2 = "cat_deleted"
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L3_2 = L29_1
  L3_2()
end
L36_1(L37_1, L38_1)
L36_1 = AddEventHandler
L37_1 = "playerDropped"
function L38_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L0_2 = source
  L1_2 = L22_1
  L1_2[L0_2] = nil
  L1_2 = L35_1
  L1_2[L0_2] = nil
  L1_2 = pairs
  L2_2 = L4_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = false
    L8_2 = pairs
    L9_2 = L6_2
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
    for L12_2, L13_2 in L8_2, L9_2, L10_2, L11_2 do
      L14_2 = L13_2[L0_2]
      if L14_2 then
        L13_2[L0_2] = nil
        L7_2 = true
      end
    end
    if L7_2 then
      L8_2 = TriggerClientEvent
      L9_2 = "apex_chat:reactionUpdate"
      L10_2 = -1
      L11_2 = {}
      L11_2.id = L5_2
      L12_2 = L34_1
      L13_2 = L5_2
      L12_2 = L12_2(L13_2)
      L11_2.reactions = L12_2
      L8_2(L9_2, L10_2, L11_2)
    end
  end
end
L36_1(L37_1, L38_1)
L36_1 = CreateThread
function L37_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = ipairs
  L1_2 = L6_1
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2 = L1_2()
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = L5_2.enabled
    if L6_2 then
      L6_2 = L25_1
      L7_2 = L5_2
      L6_2(L7_2)
    else
      L7_2 = L5_2.id
      L6_2 = L3_1
      L6_2[L7_2] = L5_2
      L7_2 = L5_2.id
      L6_2 = L2_1
      L6_2[L7_2] = L5_2
    end
  end
end
L36_1(L37_1)
L36_1 = exports
L37_1 = "GetCategories"
function L38_1()
  local L0_2, L1_2
  L0_2 = L27_1
  return L0_2()
end
L36_1(L37_1, L38_1)
L36_1 = exports
L37_1 = "SendCategoryMessage"
function L38_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  if A0_2 and A1_2 and A2_2 then
    L3_2 = L24_1
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = A2_2
    L3_2(L4_2, L5_2, L6_2)
  end
end
L36_1(L37_1, L38_1)
