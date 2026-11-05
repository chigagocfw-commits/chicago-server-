local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = ApexCats
if not L0_1 then
  L0_1 = {}
end
ApexCats = L0_1
L0_1 = {}
L0_1.rp = true
L0_1.steam = true
L0_1.anon = true
L1_1 = {}
L1_1.all = true
L1_1.staff = true
L1_1.sender = true
L1_1.role = true
L1_1.job = true
L2_1 = {}
L2_1.open = true
L2_1.job = true
L2_1.grade = true
L2_1.staff = true
L2_1.role = true
function L3_1(A0_2)
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
    L8_2 = L3_1
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L1_2[L6_2] = L8_2
  end
  return L1_2
end
L4_1 = ApexCats
L4_1.clone = L3_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return L1_2
  end
  L2_2 = ipairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = tostring
    L9_2 = L7_2 or L9_2
    if not L7_2 then
      L9_2 = ""
    end
    L8_2 = L8_2(L9_2)
    L9_2 = L8_2
    L8_2 = L8_2.gsub
    L10_2 = "^%s+"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L9_2 = L8_2
    L8_2 = L8_2.gsub
    L10_2 = "%s+$"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2 = L8_2
    if "" ~= L7_2 then
      L8_2 = #L1_2
      L8_2 = L8_2 + 1
      L1_2[L8_2] = L7_2
    end
  end
  return L1_2
end
L5_1 = ApexCats
L5_1.strArray = L4_1
function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = Utils
  if L0_2 then
    L0_2 = Utils
    L0_2 = L0_2.uuid
    if L0_2 then
      L0_2 = Utils
      L0_2 = L0_2.uuid
      return L0_2()
    end
  end
  L0_2 = "cat-%d-%d"
  L1_2 = L0_2
  L0_2 = L0_2.format
  L2_2 = os
  L2_2 = L2_2.time
  if L2_2 then
    L2_2 = os
    L2_2 = L2_2.time
    L2_2 = L2_2()
    if L2_2 then
      goto lbl_24
    end
  end
  L2_2 = 0
  ::lbl_24::
  L3_2 = math
  L3_2 = L3_2.random
  L4_2 = 100000
  L5_2 = 999999
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  return L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
end
L6_1 = ApexCats
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    L2_2 = "invalid"
    return L1_2, L2_2
  end
  L1_2 = tostring
  L2_2 = A0_2.command
  if not L2_2 then
    L2_2 = ""
  end
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.gsub
  L3_2 = "%s+"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = L1_2
  L1_2 = L1_2.lower
  L1_2 = L1_2(L2_2)
  if "" == L1_2 then
    L2_2 = nil
    L3_2 = "command"
    return L2_2, L3_2
  end
  L3_2 = L1_2
  L2_2 = L1_2.match
  L4_2 = "^[%a_][%w_]*$"
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L2_2 = nil
    L3_2 = "command-pattern"
    return L2_2, L3_2
  end
  L2_2 = #L1_2
  if L2_2 > 24 then
    L2_2 = nil
    L3_2 = "command-length"
    return L2_2, L3_2
  end
  L2_2 = tostring
  L3_2 = A0_2.label
  if not L3_2 then
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
  if "" == L2_2 then
    L4_2 = L1_2
    L3_2 = L1_2.gsub
    L5_2 = "^%l"
    L6_2 = string
    L6_2 = L6_2.upper
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2 = L3_2
  end
  L4_2 = L2_2
  L3_2 = L2_2.sub
  L5_2 = 1
  L6_2 = 32
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2 = L3_2
  L3_2 = type
  L4_2 = A0_2.rule
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.rule
    if L3_2 then
      goto lbl_77
    end
  end
  L3_2 = {}
  ::lbl_77::
  L5_2 = L3_2.type
  L4_2 = L2_1
  L4_2 = L4_2[L5_2]
  if L4_2 then
    L4_2 = L3_2.type
    if L4_2 then
      goto lbl_86
    end
  end
  L4_2 = "open"
  ::lbl_86::
  L6_2 = A0_2.identity
  L5_2 = L0_1
  L5_2 = L5_2[L6_2]
  if L5_2 then
    L5_2 = A0_2.identity
    if L5_2 then
      goto lbl_95
    end
  end
  L5_2 = "rp"
  ::lbl_95::
  L7_2 = A0_2.visibility
  L6_2 = L1_1
  L6_2 = L6_2[L7_2]
  if L6_2 then
    L6_2 = A0_2.visibility
    if L6_2 then
      goto lbl_104
    end
  end
  L6_2 = "all"
  ::lbl_104::
  L7_2 = tostring
  L8_2 = A0_2.color
  if not L8_2 then
    L8_2 = "#1F5EFF"
  end
  L7_2 = L7_2(L8_2)
  L9_2 = L7_2
  L8_2 = L7_2.match
  L10_2 = "^#%x%x%x%x?%x?%x?$"
  L8_2 = L8_2(L9_2, L10_2)
  if not L8_2 then
    L7_2 = "#1F5EFF"
  end
  L8_2 = tostring
  L9_2 = A0_2.webhook
  if not L9_2 then
    L9_2 = ""
  end
  L8_2 = L8_2(L9_2)
  L9_2 = L8_2
  L8_2 = L8_2.gsub
  L10_2 = "^%s+"
  L11_2 = ""
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = L8_2
  L8_2 = L8_2.gsub
  L10_2 = "%s+$"
  L11_2 = ""
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if "" ~= L8_2 then
    L10_2 = L8_2
    L9_2 = L8_2.match
    L11_2 = "^https://"
    L9_2 = L9_2(L10_2, L11_2)
    if not L9_2 then
      L8_2 = ""
    end
  end
  L9_2 = {}
  L10_2 = type
  L11_2 = A0_2.id
  L10_2 = L10_2(L11_2)
  if "string" == L10_2 then
    L10_2 = A0_2.id
    if "" ~= L10_2 then
      L10_2 = A0_2.id
      if L10_2 then
        goto lbl_153
      end
    end
  end
  L10_2 = L5_1
  L10_2 = L10_2()
  ::lbl_153::
  L9_2.id = L10_2
  L9_2.label = L2_2
  L9_2.command = L1_2
  L10_2 = tostring
  L11_2 = A0_2.icon
  if not L11_2 then
    L11_2 = "fas fa-comment"
  end
  L10_2 = L10_2(L11_2)
  L11_2 = L10_2
  L10_2 = L10_2.sub
  L12_2 = 1
  L13_2 = 48
  L10_2 = L10_2(L11_2, L12_2, L13_2)
  L9_2.icon = L10_2
  L9_2.color = L7_2
  L10_2 = type
  L11_2 = A0_2.bg
  L10_2 = L10_2(L11_2)
  if "string" == L10_2 then
    L10_2 = A0_2.bg
    if "" ~= L10_2 then
      L10_2 = A0_2.bg
      L11_2 = L10_2
      L10_2 = L10_2.sub
      L12_2 = 1
      L13_2 = 300
      L10_2 = L10_2(L11_2, L12_2, L13_2)
      if L10_2 then
        goto lbl_184
      end
    end
  end
  L10_2 = nil
  ::lbl_184::
  L9_2.bg = L10_2
  if "" ~= L8_2 then
    L11_2 = L8_2
    L10_2 = L8_2.sub
    L12_2 = 1
    L13_2 = 300
    L10_2 = L10_2(L11_2, L12_2, L13_2)
    if L10_2 then
      goto lbl_194
    end
  end
  L10_2 = nil
  ::lbl_194::
  L9_2.webhook = L10_2
  L9_2.identity = L5_2
  L10_2 = math
  L10_2 = L10_2.max
  L11_2 = 0
  L12_2 = tonumber
  L13_2 = A0_2.area
  L12_2 = L12_2(L13_2)
  if not L12_2 then
    L12_2 = 0
  end
  L10_2 = L10_2(L11_2, L12_2)
  L9_2.area = L10_2
  L9_2.visibility = L6_2
  L10_2 = {}
  L10_2.type = L4_2
  L11_2 = L4_1
  L12_2 = L3_2.jobs
  L11_2 = L11_2(L12_2)
  L10_2.jobs = L11_2
  L11_2 = math
  L11_2 = L11_2.max
  L12_2 = 0
  L13_2 = tonumber
  L14_2 = L3_2.minGrade
  L13_2 = L13_2(L14_2)
  if not L13_2 then
    L13_2 = 0
  end
  L11_2 = L11_2(L12_2, L13_2)
  L10_2.minGrade = L11_2
  L11_2 = L4_1
  L12_2 = L3_2.groups
  L11_2 = L11_2(L12_2)
  L10_2.groups = L11_2
  L11_2 = type
  L12_2 = L3_2.ace
  L11_2 = L11_2(L12_2)
  if "string" == L11_2 then
    L11_2 = L3_2.ace
    if "" ~= L11_2 then
      L11_2 = L3_2.ace
      if L11_2 then
        goto lbl_242
      end
    end
  end
  L11_2 = nil
  ::lbl_242::
  L10_2.ace = L11_2
  L11_2 = L4_1
  L12_2 = L3_2.identifiers
  L11_2 = L11_2(L12_2)
  L10_2.identifiers = L11_2
  L9_2.rule = L10_2
  L10_2 = A0_2.enabled
  L10_2 = false ~= L10_2
  L9_2.enabled = L10_2
  L10_2 = tonumber
  L11_2 = A0_2.order
  L10_2 = L10_2(L11_2)
  if not L10_2 then
    L10_2 = 999
  end
  L9_2.order = L10_2
  L10_2 = A0_2.builtin
  L10_2 = true == L10_2
  L9_2.builtin = L10_2
  L10_2 = L9_2
  L11_2 = nil
  return L10_2, L11_2
end
L6_1.sanitize = L7_1
L6_1 = ApexCats
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = ipairs
  L2_2 = Config
  L2_2 = L2_2.Categories
  if not L2_2 then
    L2_2 = {}
  end
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = ApexCats
    L7_2 = L7_2.sanitize
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2.builtin = true
      L8_2 = #L0_2
      L8_2 = L8_2 + 1
      L0_2[L8_2] = L7_2
    end
  end
  return L0_2
end
L6_1.defaults = L7_1
L6_1 = ApexCats
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = {}
  L3_2 = A0_2.id
  L2_2.id = L3_2
  L3_2 = A0_2.label
  L2_2.label = L3_2
  L3_2 = A0_2.command
  L2_2.command = L3_2
  L3_2 = A0_2.icon
  L2_2.icon = L3_2
  L3_2 = A0_2.color
  L2_2.color = L3_2
  L3_2 = A0_2.bg
  L2_2.bg = L3_2
  L3_2 = A0_2.identity
  L2_2.identity = L3_2
  L3_2 = A0_2.area
  L2_2.area = L3_2
  L3_2 = A0_2.visibility
  L2_2.visibility = L3_2
  L3_2 = L3_1
  L4_2 = A0_2.rule
  L3_2 = L3_2(L4_2)
  L2_2.rule = L3_2
  L3_2 = A0_2.enabled
  L2_2.enabled = L3_2
  L3_2 = A0_2.order
  L2_2.order = L3_2
  L3_2 = A0_2.builtin
  L2_2.builtin = L3_2
  if A1_2 then
    L3_2 = A0_2.webhook
    L2_2.webhook = L3_2
  end
  return L2_2
end
L6_1.toClient = L7_1
