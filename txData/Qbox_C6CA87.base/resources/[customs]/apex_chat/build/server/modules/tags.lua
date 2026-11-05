local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1
L0_1 = "apex_chat:tags"
L1_1 = "apex_chat:tag_assign"
L2_1 = "apex_chat:known"
L3_1 = {}
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GetResourceKvpString
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 and "" ~= L2_2 then
    L3_2 = pcall
    L4_2 = json
    L4_2 = L4_2.decode
    L5_2 = L2_2
    L3_2, L4_2 = L3_2(L4_2, L5_2)
    if L3_2 then
      L5_2 = type
      L6_2 = L4_2
      L5_2 = L5_2(L6_2)
      if "table" == L5_2 then
        return L4_2
      end
    end
  end
  return A1_2
end
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = SetResourceKvp
  L3_2 = A0_2
  L4_2 = json
  L4_2 = L4_2.encode
  L5_2 = A1_2
  L4_2, L5_2 = L4_2(L5_2)
  L2_2(L3_2, L4_2, L5_2)
end
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = ExtractIdentifiers
  if L1_2 then
    L1_2 = ExtractIdentifiers
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_11
    end
  end
  L1_2 = {}
  ::lbl_11::
  L2_2 = L1_2.license
  if not L2_2 then
    L2_2 = ""
  end
  if "" ~= L2_2 then
    L2_2 = L1_2.license
    L3_2 = L2_2
    L2_2 = L2_2.gsub
    L4_2 = "license:"
    L5_2 = ""
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    if L2_2 then
      goto lbl_25
    end
  end
  L2_2 = nil
  ::lbl_25::
  return L2_2
end
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = tostring
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
  A0_2 = L2_2
  L3_2 = A0_2
  L2_2 = A0_2.match
  L4_2 = "^#%x%x%x%x%x%x$"
  L2_2 = L2_2(L3_2, L4_2)
  L2_2 = A0_2 or L2_2
  if not L2_2 or not A0_2 then
    L2_2 = A1_2
  end
  return L2_2
end
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L4_1
  L1_2 = L0_1
  L2_2 = {}
  L0_2 = L0_2(L1_2, L2_2)
  L1_2 = {}
  L3_1 = L1_2
  L1_2 = ipairs
  L2_2 = L0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L6_2.id
    if L7_2 then
      L8_2 = L6_2.id
      L7_2 = L3_1
      L7_2[L8_2] = L6_2
    end
  end
  return L0_2
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L5_1
  L2_2 = L0_1
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  L1_2 = L8_1
  L1_2()
end
L10_1 = {}
L10_1.badge = true
L10_1.icon = true
L10_1.text = true
L10_1.full = true
function L11_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = tostring
  L2_2 = A0_2.label
  if not L2_2 then
    L2_2 = ""
  end
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.gsub
  L3_2 = "[\r\n]"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = L1_2
  L1_2 = L1_2.sub
  L3_2 = 1
  L4_2 = 24
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  if "" == L1_2 then
    L2_2 = nil
    L3_2 = "label required"
    return L2_2, L3_2
  end
  L2_2 = tostring
  L3_2 = A0_2.id
  if not L3_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
  if "" == L2_2 then
    L3_2 = "tag_%s"
    L4_2 = L3_2
    L3_2 = L3_2.format
    L5_2 = Utils
    if L5_2 then
      L5_2 = Utils
      L5_2 = L5_2.uuid
      if L5_2 then
        L5_2 = Utils
        L5_2 = L5_2.uuid
        L5_2 = L5_2()
        if L5_2 then
          goto lbl_56
        end
      end
    end
    L5_2 = tostring
    L6_2 = math
    L6_2 = L6_2.random
    L7_2 = 100000
    L8_2 = 999999
    L6_2, L7_2, L8_2 = L6_2(L7_2, L8_2)
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    ::lbl_56::
    L3_2 = L3_2(L4_2, L5_2)
    L2_2 = L3_2
  end
  L3_2 = {}
  L3_2.id = L2_2
  L3_2.label = L1_2
  L4_2 = L7_1
  L5_2 = A0_2.color
  L6_2 = "#3B82F6"
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.color = L4_2
  L4_2 = L7_1
  L5_2 = A0_2.textColor
  L6_2 = "#FFFFFF"
  L4_2 = L4_2(L5_2, L6_2)
  L3_2.textColor = L4_2
  L4_2 = tostring
  L5_2 = A0_2.icon
  if not L5_2 then
    L5_2 = ""
  end
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2
  L4_2 = L4_2.gsub
  L6_2 = "[\r\n]"
  L7_2 = ""
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = L4_2
  L4_2 = L4_2.sub
  L6_2 = 1
  L7_2 = 48
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2.icon = L4_2
  L5_2 = A0_2.style
  L4_2 = L10_1
  L4_2 = L4_2[L5_2]
  if L4_2 then
    L4_2 = A0_2.style
    if L4_2 then
      goto lbl_96
    end
  end
  L4_2 = "badge"
  ::lbl_96::
  L3_2.style = L4_2
  L4_2 = tonumber
  L5_2 = A0_2.priority
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 0
  end
  L3_2.priority = L4_2
  return L3_2
end
function L12_1()
  local L0_2, L1_2, L2_2
  L0_2 = L4_1
  L1_2 = L1_1
  L2_2 = {}
  return L0_2(L1_2, L2_2)
end
function L13_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L5_1
  L2_2 = L1_1
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 then
    L1_2 = {}
    return L1_2
  end
  L1_2 = L12_1
  L1_2 = L1_2()
  L1_2 = L1_2[A0_2]
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    L2_2 = {}
    return L2_2
  end
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L3_1
    L9_2 = L9_2[L8_2]
    if L9_2 then
      L10_2 = #L2_2
      L10_2 = L10_2 + 1
      L2_2[L10_2] = L9_2
    end
  end
  L3_2 = table
  L3_2 = L3_2.sort
  L4_2 = L2_2
  function L5_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.priority
    if not L2_3 then
      L2_3 = 0
    end
    L3_3 = A1_3.priority
    if not L3_3 then
      L3_3 = 0
    end
    L2_3 = L2_3 > L3_3
    return L2_3
  end
  L3_2(L4_2, L5_2)
  return L2_2
end
function L15_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L14_1
  L2_2 = L6_1
  L3_2 = A0_2
  L2_2, L3_2 = L2_2(L3_2)
  return L1_2(L2_2, L3_2)
end
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L6_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L2_2 = L4_1
  L3_2 = L2_1
  L4_2 = {}
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L2_2[L1_2]
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = GetPlayerName
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = L3_2.steam
  end
  L3_2.steam = L4_2
  L4_2 = QBCore
  L4_2 = L4_2.Functions
  L4_2 = L4_2.GetPlayer
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L5_2 = getName
    if L5_2 then
      L5_2 = getName
      L6_2 = L4_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        goto lbl_40
      end
    end
    L5_2 = L3_2.rp
    ::lbl_40::
    L3_2.rp = L5_2
  end
  L5_2 = os
  L5_2 = L5_2.time
  L5_2 = L5_2()
  L3_2.seen = L5_2
  L2_2[L1_2] = L3_2
  L5_2 = L5_1
  L6_2 = L2_1
  L7_2 = L2_2
  L5_2(L6_2, L7_2)
end
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = GetResourceState
  L3_2 = "oxmysql"
  L2_2 = L2_2(L3_2)
  if "started" ~= L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    return L2_2(L3_2)
  end
  L2_2 = "%"
  L3_2 = A0_2
  L4_2 = "%"
  L2_2 = L2_2 .. L3_2 .. L4_2
  L3_2 = exports
  L3_2 = L3_2.oxmysql
  L4_2 = L3_2
  L3_2 = L3_2.query
  L5_2 = "SELECT identifier, firstname, lastname FROM users "
  L6_2 = "WHERE firstname LIKE ? OR lastname LIKE ? OR CONCAT(IFNULL(firstname,''),' ',IFNULL(lastname,'')) LIKE ? LIMIT 25"
  L5_2 = L5_2 .. L6_2
  L6_2 = {}
  L7_2 = L2_2
  L8_2 = L2_2
  L9_2 = L2_2
  L6_2[1] = L7_2
  L6_2[2] = L8_2
  L6_2[3] = L9_2
  function L7_2(A0_3)
    local L1_3, L2_3
    L1_3 = A1_2
    L2_3 = A0_3 or L2_3
    if not A0_3 then
      L2_3 = {}
    end
    L1_3(L2_3)
  end
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L2_2 = tostring
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
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
  if L2_2 < 2 then
    L2_2 = A1_2
    L3_2 = {}
    return L2_2(L3_2)
  end
  L3_2 = A0_2
  L2_2 = A0_2.lower
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = {}
  function L5_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3
    L3_3 = A0_3 or nil
    if not A0_3 then
      L3_3 = ""
    end
    L4_3 = L3_3
    L3_3 = L3_3.gsub
    L5_3 = "^char%d+:"
    L6_3 = ""
    L3_3 = L3_3(L4_3, L5_3, L6_3)
    L4_3 = L3_3
    L3_3 = L3_3.gsub
    L5_3 = "license:"
    L6_3 = ""
    L3_3 = L3_3(L4_3, L5_3, L6_3)
    A0_3 = L3_3
    if "" ~= A0_3 then
      L3_3 = L4_2
      L3_3 = L3_3[A0_3]
      if not L3_3 then
        goto lbl_20
      end
    end
    do return end
    ::lbl_20::
    L3_3 = L4_2
    L3_3[A0_3] = true
    L3_3 = L3_2
    L3_3 = #L3_3
    L4_3 = L3_3 + 1
    L3_3 = L3_2
    L5_3 = {}
    L5_3.identifier = A0_3
    L6_3 = A1_3 or L6_3
    if not A1_3 then
      L6_3 = "\226\128\148"
    end
    L5_3.name = L6_3
    L6_3 = A2_3 or L6_3
    if not A2_3 then
      L6_3 = ""
    end
    L5_3.steam = L6_3
    L6_3 = L14_1
    L7_3 = A0_3
    L6_3 = L6_3(L7_3)
    L5_3.tags = L6_3
    L3_3[L4_3] = L5_3
  end
  L6_2 = pairs
  L7_2 = L4_1
  L8_2 = L2_1
  L9_2 = {}
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L7_2(L8_2, L9_2)
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    L12_2 = L11_2.steam
    if not L12_2 then
      L12_2 = ""
    end
    L13_2 = L12_2
    L12_2 = L12_2.lower
    L12_2 = L12_2(L13_2)
    L13_2 = L11_2.rp
    if not L13_2 then
      L13_2 = ""
    end
    L14_2 = L13_2
    L13_2 = L13_2.lower
    L13_2 = L13_2(L14_2)
    L15_2 = L12_2
    L14_2 = L12_2.find
    L16_2 = L2_2
    L17_2 = 1
    L18_2 = true
    L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2)
    if not L14_2 then
      L15_2 = L13_2
      L14_2 = L13_2.find
      L16_2 = L2_2
      L17_2 = 1
      L18_2 = true
      L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2)
      if not L14_2 then
        goto lbl_72
      end
    end
    L14_2 = L5_2
    L15_2 = L10_2
    L16_2 = L11_2.rp
    if not L16_2 then
      L16_2 = L11_2.steam
    end
    L17_2 = L11_2.steam
    L14_2(L15_2, L16_2, L17_2)
    ::lbl_72::
  end
  L6_2 = L17_1
  L7_2 = A0_2
  function L8_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    L1_3 = ipairs
    L2_3 = A0_3
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L6_3.firstname
      if not L7_3 then
        L7_3 = ""
      end
      L8_3 = " "
      L9_3 = L6_3.lastname
      if not L9_3 then
        L9_3 = ""
      end
      L7_3 = L7_3 .. L8_3 .. L9_3
      L8_3 = L7_3
      L7_3 = L7_3.gsub
      L9_3 = "^%s+"
      L10_3 = ""
      L7_3 = L7_3(L8_3, L9_3, L10_3)
      L8_3 = L7_3
      L7_3 = L7_3.gsub
      L9_3 = "%s+$"
      L10_3 = ""
      L7_3 = L7_3(L8_3, L9_3, L10_3)
      L8_3 = L5_2
      L9_3 = L6_3.identifier
      L10_3 = L7_3 or L10_3
      if "" == L7_3 or not L7_3 then
        L10_3 = "Unknown"
      end
      L11_3 = nil
      L8_3(L9_3, L10_3, L11_3)
    end
    L1_3 = A1_2
    L2_3 = L3_2
    L1_3(L2_3)
  end
  L6_2(L7_2, L8_2)
end
function L19_1(A0_2)
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
  L2_2 = L2_2.TagManager
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.TagManager
    L2_2 = L2_2.authorGroups
    if L2_2 then
      goto lbl_32
    end
  end
  L2_2 = Config
  L2_2 = L2_2.CategoryManager
  if L2_2 then
    L2_2 = Config
    L2_2 = L2_2.CategoryManager
    L2_2 = L2_2.authorGroups
    if L2_2 then
      goto lbl_32
    end
  end
  L2_2 = {}
  L3_2 = "admin"
  L2_2[1] = L3_2
  ::lbl_32::
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
function L20_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = TriggerClientEvent
  L2_2 = "apex_chat:tags:sync"
  L3_2 = A0_2
  L4_2 = {}
  L5_2 = L8_1
  L5_2 = L5_2()
  L4_2.tags = L5_2
  L5_2 = L19_1
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L4_2.isManager = L5_2
  L1_2(L2_2, L3_2, L4_2)
end
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:tags:request"
function L23_1()
  local L0_2, L1_2
  L0_2 = L20_1
  L1_2 = source
  L0_2(L1_2)
end
L21_1(L22_1, L23_1)
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:tags:save"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = source
  L2_2 = L19_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = L11_1
  L3_2 = A0_2
  L2_2, L3_2 = L2_2(L3_2)
  if not L2_2 then
    L4_2 = TriggerClientEvent
    L5_2 = "okokChat:Notification"
    L6_2 = L1_2
    L7_2 = {}
    L7_2.title = "TAGS"
    L7_2.type = "error"
    L7_2.time = 4000
    L8_2 = "Invalid tag ("
    L9_2 = tostring
    L10_2 = L3_2
    L9_2 = L9_2(L10_2)
    L10_2 = ")"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L4_2(L5_2, L6_2, L7_2, L8_2)
    return
  end
  L4_2 = L8_1
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
      break
    end
  end
  if not L5_2 then
    L6_2 = #L4_2
    L6_2 = L6_2 + 1
    L4_2[L6_2] = L2_2
  end
  L6_2 = L9_1
  L7_2 = L4_2
  L6_2(L7_2)
  L6_2 = TriggerClientEvent
  L7_2 = "okokChat:Notification"
  L8_2 = L1_2
  L9_2 = {}
  L9_2.title = "TAGS"
  L9_2.type = "success"
  L9_2.time = 3000
  L10_2 = "Tag saved"
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = L20_1
  L7_2 = L1_2
  L6_2(L7_2)
end
L21_1(L22_1, L23_1)
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:tags:delete"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L1_2 = source
  L2_2 = L19_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = L8_1
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
      break
    end
  end
  L3_2 = L9_1
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = L12_1
  L3_2 = L3_2()
  L4_2 = pairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = #L9_2
    L11_2 = 1
    L12_2 = -1
    for L13_2 = L10_2, L11_2, L12_2 do
      L14_2 = L9_2[L13_2]
      if L14_2 == A0_2 then
        L14_2 = table
        L14_2 = L14_2.remove
        L15_2 = L9_2
        L16_2 = L13_2
        L14_2(L15_2, L16_2)
      end
    end
    L10_2 = #L9_2
    if 0 == L10_2 then
      L3_2[L8_2] = nil
    end
  end
  L4_2 = L13_1
  L5_2 = L3_2
  L4_2(L5_2)
  L4_2 = TriggerClientEvent
  L5_2 = "okokChat:Notification"
  L6_2 = L1_2
  L7_2 = {}
  L7_2.title = "TAGS"
  L7_2.type = "success"
  L7_2.time = 3000
  L8_2 = "Tag deleted"
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = L20_1
  L5_2 = L1_2
  L4_2(L5_2)
end
L21_1(L22_1, L23_1)
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:tags:search"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = source
  L2_2 = L19_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = L18_1
  L3_2 = A0_2
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    L1_3 = TriggerClientEvent
    L2_3 = "apex_chat:tags:results"
    L3_3 = L1_2
    L4_3 = A0_3
    L1_3(L2_3, L3_3, L4_3)
  end
  L2_2(L3_2, L4_2)
end
L21_1(L22_1, L23_1)
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:tags:assign"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = source
  L2_2 = L19_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      goto lbl_13
    end
  end
  do return end
  ::lbl_13::
  L2_2 = tostring
  L3_2 = A0_2.identifier
  if not L3_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "^char%d+:"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "license:"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = tostring
  L4_2 = A0_2.tagId
  if not L4_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  if "" ~= L2_2 then
    L4_2 = L3_1
    L4_2 = L4_2[L3_2]
    if L4_2 then
      goto lbl_40
    end
  end
  do return end
  ::lbl_40::
  L4_2 = L12_1
  L4_2 = L4_2()
  L5_2 = L4_2[L2_2]
  if not L5_2 then
    L5_2 = {}
  end
  L6_2 = false
  L7_2 = nil
  L8_2 = ipairs
  L9_2 = L5_2
  L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
  for L12_2, L13_2 in L8_2, L9_2, L10_2, L11_2 do
    if L13_2 == L3_2 then
      L14_2 = true
      L7_2 = L12_2
      L6_2 = L14_2
      break
    end
  end
  L8_2 = A0_2.add
  if L8_2 and not L6_2 then
    L8_2 = #L5_2
    L8_2 = L8_2 + 1
    L5_2[L8_2] = L3_2
  else
    L8_2 = A0_2.add
    if not L8_2 and L6_2 then
      L8_2 = table
      L8_2 = L8_2.remove
      L9_2 = L5_2
      L10_2 = L7_2
      L8_2(L9_2, L10_2)
    end
  end
  L8_2 = #L5_2
  if L8_2 > 0 then
    L4_2[L2_2] = L5_2
  else
    L4_2[L2_2] = nil
  end
  L8_2 = L13_1
  L9_2 = L4_2
  L8_2(L9_2)
  L8_2 = TriggerClientEvent
  L9_2 = "apex_chat:tags:player"
  L10_2 = L1_2
  L11_2 = {}
  L11_2.identifier = L2_2
  L12_2 = L14_1
  L13_2 = L2_2
  L12_2 = L12_2(L13_2)
  L11_2.tags = L12_2
  L8_2(L9_2, L10_2, L11_2)
end
L21_1(L22_1, L23_1)
L21_1 = RegisterNetEvent
L22_1 = "apex_chat:theme:broadcast"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = source
  L2_2 = L19_1
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = nil
  L3_2 = nil
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if "table" == L4_2 then
    L4_2 = A0_2.theme
    if L4_2 then
      L4_2 = tostring
      L5_2 = A0_2.theme
      L4_2 = L4_2(L5_2)
      if L4_2 then
        goto lbl_23
        L2_2 = L4_2 or L2_2
      end
    end
    L2_2 = nil
    ::lbl_23::
    L4_2 = A0_2.accent
    if L4_2 then
      L4_2 = tostring
      L5_2 = A0_2.accent
      L4_2 = L4_2(L5_2)
      L3_2 = L4_2 or L3_2
    end
    if not L4_2 then
      L3_2 = nil
    end
  else
    L4_2 = tostring
    L5_2 = A0_2 or L5_2
    if not A0_2 then
      L5_2 = ""
    end
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
    if "" == L2_2 then
      L2_2 = nil
    end
  end
  if not L2_2 and not L3_2 then
    return
  end
  L4_2 = {}
  L4_2.theme = L2_2
  L4_2.accent = L3_2
  L5_2 = L5_1
  L6_2 = "apex_chat:server_theme"
  L7_2 = L4_2
  L5_2(L6_2, L7_2)
  L5_2 = TriggerClientEvent
  L6_2 = "apex_chat:theme:apply"
  L7_2 = -1
  L8_2 = L4_2
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = TriggerClientEvent
  L6_2 = "okokChat:Notification"
  L7_2 = L1_2
  L8_2 = {}
  L8_2.title = "DESIGN"
  L8_2.type = "success"
  L8_2.time = 3000
  L9_2 = "Design applied for everyone"
  L5_2(L6_2, L7_2, L8_2, L9_2)
end
L21_1(L22_1, L23_1)
L21_1 = AddEventHandler
L22_1 = "playerJoining"
function L23_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = source
  L1_2 = L4_1
  L2_2 = "apex_chat:server_theme"
  L1_2 = L1_2(L2_2)
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = {}
    L2_2.theme = L1_2
    L1_2 = L2_2
  end
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = L1_2.theme
    if not L2_2 then
      L2_2 = L1_2.accent
      if not L2_2 then
        goto lbl_29
      end
    end
    L2_2 = SetTimeout
    L3_2 = 2500
    function L4_2()
      local L0_3, L1_3, L2_3, L3_3
      L0_3 = TriggerClientEvent
      L1_3 = "apex_chat:theme:apply"
      L2_3 = L0_2
      L3_3 = L1_2
      L0_3(L1_3, L2_3, L3_3)
    end
    L2_2(L3_2, L4_2)
  end
  ::lbl_29::
end
L21_1(L22_1, L23_1)
function L21_1()
  local L0_2, L1_2, L2_2
  L0_2 = Config
  L0_2 = L0_2.Gif
  if not L0_2 then
    L0_2 = {}
  end
  L1_2 = {}
  L2_2 = L0_2.provider
  if not L2_2 then
    L2_2 = "tenor"
  end
  L1_2.provider = L2_2
  L2_2 = L0_2.tenorKey
  if not L2_2 then
    L2_2 = "LIVDSRZULELA"
  end
  L1_2.tenorKey = L2_2
  L2_2 = L0_2.giphyKey
  if not L2_2 then
    L2_2 = ""
  end
  L1_2.giphyKey = L2_2
  L2_2 = L0_2.limit
  if not L2_2 then
    L2_2 = 24
  end
  L1_2.limit = L2_2
  return L1_2
end
function L22_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = ipairs
  L3_2 = A0_2.data
  if not L3_2 then
    L3_2 = {}
  end
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.images
    if not L8_2 then
      L8_2 = {}
    end
    L9_2 = L8_2.fixed_width_small
    if not L9_2 then
      L9_2 = L8_2.fixed_height_small
      if not L9_2 then
        L9_2 = L8_2.fixed_width
        if not L9_2 then
          L9_2 = {}
        end
      end
    end
    L9_2 = L9_2.url
    L10_2 = L8_2.fixed_height
    if not L10_2 then
      L10_2 = L8_2.downsized_medium
      if not L10_2 then
        L10_2 = L8_2.original
        if not L10_2 then
          L10_2 = {}
        end
      end
    end
    L10_2 = L10_2.url
    if L9_2 and L10_2 then
      L11_2 = #A1_2
      L11_2 = L11_2 + 1
      L12_2 = {}
      L12_2.thumb = L9_2
      L12_2.full = L10_2
      A1_2[L11_2] = L12_2
    end
  end
end
function L23_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = ipairs
  L3_2 = A0_2.results
  if not L3_2 then
    L3_2 = {}
  end
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.media
    if not L8_2 then
      L8_2 = {}
    end
    L8_2 = L8_2[1]
    if not L8_2 then
      L8_2 = {}
    end
    L9_2 = L8_2.tinygif
    if not L9_2 then
      L9_2 = L8_2.nanogif
      if not L9_2 then
        L9_2 = L8_2.gif
        if not L9_2 then
          L9_2 = {}
        end
      end
    end
    L9_2 = L9_2.url
    L10_2 = L8_2.gif
    if not L10_2 then
      L10_2 = L8_2.mediumgif
      if not L10_2 then
        L10_2 = L8_2.tinygif
        if not L10_2 then
          L10_2 = {}
        end
      end
    end
    L10_2 = L10_2.url
    if L9_2 and L10_2 then
      L11_2 = #A1_2
      L11_2 = L11_2 + 1
      L12_2 = {}
      L12_2.thumb = L9_2
      L12_2.full = L10_2
      A1_2[L11_2] = L12_2
    end
  end
end
L24_1 = RegisterNetEvent
L25_1 = "apex_chat:gif"
function L26_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = source
  L2_2 = L21_1
  L2_2 = L2_2()
  L3_2 = tostring
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.gsub
  L5_2 = "[^%w%s%-_]"
  L6_2 = ""
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = L3_2
  L3_2 = L3_2.gsub
  L5_2 = "%s+"
  L6_2 = "+"
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  A0_2 = L3_2
  L3_2 = nil
  L4_2 = nil
  L5_2 = L2_2.provider
  if "giphy" == L5_2 then
    L5_2 = L2_2.giphyKey
    if "" ~= L5_2 then
      L4_2 = L22_1
      if "" ~= A0_2 then
        L5_2 = "https://api.giphy.com/v1/gifs/search?api_key=%s&q=%s&limit=%d&rating=pg-13&lang=pt"
        L6_2 = L5_2
        L5_2 = L5_2.format
        L7_2 = L2_2.giphyKey
        L8_2 = A0_2
        L9_2 = L2_2.limit
        L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
        L3_2 = L5_2
      else
        L5_2 = "https://api.giphy.com/v1/gifs/trending?api_key=%s&limit=%d&rating=pg-13"
        L6_2 = L5_2
        L5_2 = L5_2.format
        L7_2 = L2_2.giphyKey
        L8_2 = L2_2.limit
        L5_2 = L5_2(L6_2, L7_2, L8_2)
        L3_2 = L5_2
      end
  end
  else
    L4_2 = L23_1
    if "" ~= A0_2 then
      L5_2 = "https://g.tenor.com/v1/search?key=%s&q=%s&limit=%d&contentfilter=medium&media_filter=minimal&locale=pt_PT"
      L6_2 = L5_2
      L5_2 = L5_2.format
      L7_2 = L2_2.tenorKey
      L8_2 = A0_2
      L9_2 = L2_2.limit
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
      L3_2 = L5_2
    else
      L5_2 = "https://g.tenor.com/v1/trending?key=%s&limit=%d&contentfilter=medium&media_filter=minimal&locale=pt_PT"
      L6_2 = L5_2
      L5_2 = L5_2.format
      L7_2 = L2_2.tenorKey
      L8_2 = L2_2.limit
      L5_2 = L5_2(L6_2, L7_2, L8_2)
      L3_2 = L5_2
    end
  end
  L5_2 = PerformHttpRequest
  L6_2 = L3_2
  function L7_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L2_3 = {}
    if 200 == A0_3 and A1_3 then
      L3_3 = pcall
      L4_3 = json
      L4_3 = L4_3.decode
      L5_3 = A1_3
      L3_3, L4_3 = L3_3(L4_3, L5_3)
      if L3_3 then
        L5_3 = type
        L6_3 = L4_3
        L5_3 = L5_3(L6_3)
        if "table" == L5_3 then
          L5_3 = L4_2
          L6_3 = L4_3
          L7_3 = L2_3
          L5_3(L6_3, L7_3)
        end
      end
    else
      L3_3 = print
      L4_3 = "^3[apex_chat]^7 GIF search failed (HTTP %s) \226\128\148 provider %s"
      L5_3 = L4_3
      L4_3 = L4_3.format
      L6_3 = tostring
      L7_3 = A0_3
      L6_3 = L6_3(L7_3)
      L7_3 = L2_2.provider
      L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3, L6_3, L7_3)
      L3_3(L4_3, L5_3, L6_3, L7_3)
    end
    L3_3 = TriggerClientEvent
    L4_3 = "apex_chat:gif:results"
    L5_3 = L1_2
    L6_3 = L2_3
    L3_3(L4_3, L5_3, L6_3)
  end
  L8_2 = "GET"
  L9_2 = ""
  L10_2 = {}
  L10_2.Accept = "application/json"
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end
L24_1(L25_1, L26_1)
L24_1 = AddEventHandler
L25_1 = "playerJoining"
function L26_1()
  local L0_2, L1_2
  L0_2 = L16_1
  L1_2 = source
  L0_2(L1_2)
end
L24_1(L25_1, L26_1)
L24_1 = RegisterNetEvent
L25_1 = "apex_chat:tags:seen"
function L26_1()
  local L0_2, L1_2
  L0_2 = L16_1
  L1_2 = source
  L0_2(L1_2)
end
L24_1(L25_1, L26_1)
L24_1 = CreateThread
function L25_1()
  local L0_2, L1_2, L2_2
  L0_2 = L8_1
  L0_2()
  L0_2 = SetTimeout
  L1_2 = 1500
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = ipairs
    L1_3 = GetPlayers
    L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3 = L1_3()
    L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
    for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
      L6_3 = L16_1
      L7_3 = tonumber
      L8_3 = L5_3
      L7_3, L8_3 = L7_3(L8_3)
      L6_3(L7_3, L8_3)
    end
  end
  L0_2(L1_2, L2_2)
end
L24_1(L25_1)
L24_1 = {}
L24_1.forSource = L15_1
L24_1.forIdentifier = L14_1
ApexTags = L24_1
L24_1 = exports
L25_1 = "GetPlayerTags"
L26_1 = L15_1
L24_1(L25_1, L26_1)
