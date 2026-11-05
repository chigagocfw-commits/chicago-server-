local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
L0_1 = {}
L1_1 = nil
L2_1 = false
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = A0_2.job
  if L1_2 then
    L1_2 = "job"
    if L1_2 then
      goto lbl_12
    end
  end
  L1_2 = "public"
  ::lbl_12::
  if "public" == L1_2 then
    L2_2 = true
    return L2_2
  end
  if "job" == L1_2 then
    L2_2 = getPlayerJob
    L2_2 = L2_2()
    if not L2_2 then
      L3_2 = false
      return L3_2
    end
    L3_2 = A0_2.job
    L4_2 = A0_2.jobGrade
    if not L4_2 then
      L4_2 = 0
    end
    L5_2 = L2_2.name
    if L5_2 == L3_2 then
      L5_2 = L2_2.grade
      if L4_2 <= L5_2 then
        L5_2 = true
        return L5_2
      end
    end
  end
  L2_2 = false
  return L2_2
end
function L4_1()
  local L0_2, L1_2
  L0_2 = getPlayerJob
  L0_2 = L0_2()
  if L0_2 then
    L1_2 = L0_2.grade
    if not L1_2 then
      L1_2 = 0
    end
    return L1_2
  end
  L1_2 = 0
  return L1_2
end
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = A1_2.outfits
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = L4_1
  L3_2 = L3_2()
  L4_2 = {}
  L5_2 = pairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = L10_2.minGrade
    if not L11_2 then
      L11_2 = 0
    end
    L12_2 = L3_2 >= L11_2
    L13_2 = table
    L13_2 = L13_2.insert
    L14_2 = L4_2
    L15_2 = {}
    L16_2 = L10_2.label
    if not L16_2 then
      L16_2 = L9_2
    end
    L15_2.title = L16_2
    if L12_2 then
      L16_2 = L10_2.description
      if L16_2 then
        goto lbl_54
      end
      L16_2 = _U
      L17_2 = "WARDROBE_APPLY_OUTFIT"
      L16_2 = L16_2(L17_2)
      if L16_2 then
        goto lbl_54
      end
      L16_2 = "Click to apply this outfit"
      if L16_2 then
        goto lbl_54
      end
    end
    L16_2 = _U
    L17_2 = "WARDROBE_GRADE_REQUIRED"
    L18_2 = L11_2
    L16_2 = L16_2(L17_2, L18_2)
    if not L16_2 then
      L16_2 = "Requires grade "
      L17_2 = L11_2
      L16_2 = L16_2 .. L17_2
    end
    ::lbl_54::
    L15_2.description = L16_2
    if L12_2 then
      L16_2 = "shirt"
      if L16_2 then
        goto lbl_61
      end
    end
    L16_2 = "lock"
    ::lbl_61::
    L15_2.icon = L16_2
    L16_2 = not L12_2
    L15_2.disabled = L16_2
    function L16_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = L12_2
      if L0_3 then
        L0_3 = ApplyOutfit
        L1_3 = L10_2
        L0_3(L1_3)
        L0_3 = true
        L2_1 = L0_3
        L0_3 = showClientNotification
        L1_3 = {}
        L2_3 = _U
        L3_3 = "WARDROBE"
        L2_3 = L2_3(L3_3)
        if not L2_3 then
          L2_3 = "Wardrobe"
        end
        L1_3.title = L2_3
        L2_3 = _U
        L3_3 = "WARDROBE_OUTFIT_APPLIED"
        L4_3 = L10_2.label
        if not L4_3 then
          L4_3 = L9_2
        end
        L2_3 = L2_3(L3_3, L4_3)
        if not L2_3 then
          L2_3 = "Applied "
          L3_3 = L10_2.label
          if not L3_3 then
            L3_3 = L9_2
          end
          L2_3 = L2_3 .. L3_3
        end
        L1_3.description = L2_3
        L1_3.type = "success"
        L0_3(L1_3)
      end
    end
    L15_2.onSelect = L16_2
    if L12_2 then
    end
    L16_2 = {}
    L17_2 = {}
    L18_2 = _U
    L19_2 = "WARDROBE_MIN_GRADE"
    L18_2 = L18_2(L19_2)
    if not L18_2 then
      L18_2 = "Minimum Grade"
    end
    L17_2.label = L18_2
    L17_2.value = L11_2
    L16_2[1] = L17_2
    L15_2.metadata = L16_2
    L13_2(L14_2, L15_2)
  end
  L5_2 = #L4_2
  if 0 == L5_2 then
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L4_2
    L7_2 = {}
    L8_2 = _U
    L9_2 = "WARDROBE_NO_OUTFITS"
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = "No Outfits Available"
    end
    L7_2.title = L8_2
    L8_2 = _U
    L9_2 = "WARDROBE_NO_OUTFITS_DESC"
    L8_2 = L8_2(L9_2)
    if not L8_2 then
      L8_2 = "No work wear outfits have been configured"
    end
    L7_2.description = L8_2
    L7_2.icon = "circle-info"
    L7_2.disabled = true
    L5_2(L6_2, L7_2)
  end
  return L4_2
end
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = lib
  if not L2_2 then
    return
  end
  L2_2 = HasClothingShop
  if L2_2 then
    L2_2 = HasClothingShop
    L2_2 = L2_2()
    if L2_2 then
      goto lbl_13
    end
  end
  L2_2 = false
  ::lbl_13::
  L3_2 = A1_2.outfits
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = next
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L4_2 = nil ~= L4_2
  L5_2 = {}
  L6_2 = {}
  L7_2 = _U
  L8_2 = "WARDROBE_CIVILIAN_WEAR"
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = "Civilian Wear"
  end
  L6_2.title = L7_2
  L7_2 = _U
  L8_2 = "WARDROBE_CIVILIAN_DESC"
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = "Change back to your civilian clothing"
  end
  L6_2.description = L7_2
  L6_2.icon = "user"
  function L7_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = L1_1
    if L0_3 then
      L0_3 = RestorePlayerClothing
      L0_3()
      L0_3 = false
      L2_1 = L0_3
      L0_3 = showClientNotification
      L1_3 = {}
      L2_3 = _U
      L3_3 = "WARDROBE"
      L2_3 = L2_3(L3_3)
      if not L2_3 then
        L2_3 = "Wardrobe"
      end
      L1_3.title = L2_3
      L2_3 = _U
      L3_3 = "WARDROBE_CIVILIAN_APPLIED"
      L2_3 = L2_3(L3_3)
      if not L2_3 then
        L2_3 = "Changed to civilian clothing"
      end
      L1_3.description = L2_3
      L1_3.type = "success"
      L0_3(L1_3)
    else
      L0_3 = showClientNotification
      L1_3 = {}
      L2_3 = _U
      L3_3 = "WARDROBE"
      L2_3 = L2_3(L3_3)
      if not L2_3 then
        L2_3 = "Wardrobe"
      end
      L1_3.title = L2_3
      L2_3 = _U
      L3_3 = "WARDROBE_NO_CIVILIAN"
      L2_3 = L2_3(L3_3)
      if not L2_3 then
        L2_3 = "No civilian clothing saved"
      end
      L1_3.description = L2_3
      L1_3.type = "error"
      L0_3(L1_3)
    end
  end
  L6_2.onSelect = L7_2
  L7_2 = {}
  L8_2 = _U
  L9_2 = "WARDROBE_WORK_WEAR"
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = "Work Wear"
  end
  L7_2.title = L8_2
  if L4_2 then
    L8_2 = _U
    L9_2 = "WARDROBE_WORK_DESC"
    L8_2 = L8_2(L9_2)
    if L8_2 then
      goto lbl_71
    end
    L8_2 = "Browse available work uniforms"
    if L8_2 then
      goto lbl_71
    end
  end
  L8_2 = _U
  L9_2 = "WARDROBE_NO_OUTFITS_DESC"
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = "No work wear outfits configured"
  end
  ::lbl_71::
  L7_2.description = L8_2
  L7_2.icon = "hard-hat"
  L8_2 = not L4_2
  L7_2.disabled = L8_2
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = L4_2
    if L0_3 then
      L0_3 = lib
      L0_3 = L0_3.registerContext
      L1_3 = {}
      L1_3.id = "wardrobe_workwear_menu"
      L2_3 = _U
      L3_3 = "WARDROBE_WORK_WEAR"
      L2_3 = L2_3(L3_3)
      if not L2_3 then
        L2_3 = "Work Wear"
      end
      L1_3.title = L2_3
      L1_3.menu = "wardrobe_main_menu"
      L2_3 = L5_1
      L3_3 = A0_2
      L4_3 = A1_2
      L2_3 = L2_3(L3_3, L4_3)
      L1_3.options = L2_3
      L0_3(L1_3)
      L0_3 = lib
      L0_3 = L0_3.showContext
      L1_3 = "wardrobe_workwear_menu"
      L0_3(L1_3)
    end
  end
  L7_2.onSelect = L8_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  if L2_2 then
    L6_2 = table
    L6_2 = L6_2.insert
    L7_2 = L5_2
    L8_2 = {}
    L9_2 = _U
    L10_2 = "WARDROBE_CLOTHING_SHOP"
    L9_2 = L9_2(L10_2)
    if not L9_2 then
      L9_2 = "Clothing Shop"
    end
    L8_2.title = L9_2
    L9_2 = _U
    L10_2 = "WARDROBE_CLOTHING_SHOP_DESC"
    L9_2 = L9_2(L10_2)
    if not L9_2 then
      L9_2 = "Open the clothing customization menu"
    end
    L8_2.description = L9_2
    L8_2.icon = "store"
    function L9_2()
      local L0_3, L1_3
      L0_3 = OpenClothingShop
      L0_3()
    end
    L8_2.onSelect = L9_2
    L6_2(L7_2, L8_2)
  end
  L6_2 = lib
  L6_2 = L6_2.registerContext
  L7_2 = {}
  L7_2.id = "wardrobe_main_menu"
  L8_2 = _U
  L9_2 = "WARDROBE"
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = "Wardrobe"
  end
  L7_2.title = L8_2
  L7_2.options = L5_2
  L6_2(L7_2)
  L6_2 = lib
  L6_2 = L6_2.showContext
  L7_2 = "wardrobe_main_menu"
  L6_2(L7_2)
end
function L7_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A1_2 or not A2_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = A0_2
  L5_2 = "_wardrobe_"
  L6_2 = A3_2
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = L0_1
  L5_2 = L5_2[L4_2]
  if L5_2 then
    L5_2 = RemoveInteract
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = L0_1
    L5_2[L4_2] = nil
  end
  L5_2 = CreateWardrobeInteract
  L6_2 = L4_2
  L7_2 = A2_2
  L8_2 = _U
  L9_2 = "WARDROBE_INTERACT"
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L8_2 = "Open Wardrobe"
  end
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = L1_1
    if not L0_3 then
      L0_3 = SavePlayerClothing
      L0_3 = L0_3()
      L1_1 = L0_3
    end
    L0_3 = L6_1
    L1_3 = A0_2
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
  end
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = L0_1
  L5_2[L4_2] = true
  L5_2 = true
  return L5_2
end
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = pairs
  L1_2 = L0_1
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
    L6_2 = RemoveInteract
    L7_2 = L4_2
    L6_2(L7_2)
    L6_2 = L0_1
    L6_2[L4_2] = nil
  end
end
cleanupWardrobeZones = L8_1
L8_1 = AddEventHandler
L9_1 = "qs-mechanic-creator:client:updateWardrobes"
function L10_1()
  local L0_2, L1_2
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3
    L0_3 = cleanupWardrobeZones
    L0_3()
    L0_3 = Wait
    L1_3 = 200
    L0_3(L1_3)
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Wardrobes
    if not L2_3 then
      L2_3 = {}
    end
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L6_3.enabled
      if L7_3 then
        L7_3 = L6_3.locations
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Tuneshops
          L7_3 = L7_3[L5_3]
          if L7_3 then
            L8_3 = L3_1
            L9_3 = L7_3
            L8_3 = L8_3(L9_3)
            if L8_3 then
              L9_3 = ipairs
              L10_3 = L6_3.locations
              L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3)
              for L13_3, L14_3 in L9_3, L10_3, L11_3, L12_3 do
                L15_3 = L7_1
                L16_3 = L5_3
                L17_3 = L6_3
                L18_3 = L14_3
                L19_3 = L13_3
                L15_3(L16_3, L17_3, L18_3, L19_3)
                L0_3 = L0_3 + 1
                L15_3 = L0_3 % 3
                if 0 == L15_3 then
                  L15_3 = Wait
                  L16_3 = 100
                  L15_3(L16_3)
                end
              end
            end
          end
        end
      end
    end
  end
  L0_2(L1_2)
end
L8_1(L9_1, L10_1)
L8_1 = AddEventHandler
L9_1 = "qs-mechanic-creator:client:jobChanged"
function L10_1()
  local L0_2, L1_2
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3
    L0_3 = Wait
    L1_3 = 500
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:updateWardrobes"
    L0_3(L1_3)
  end
  L0_2(L1_2)
end
L8_1(L9_1, L10_1)
L8_1 = AddEventHandler
L9_1 = "onResourceStart"
function L10_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = CreateThread
    function L2_2()
      local L0_3, L1_3
      L0_3 = Wait
      L1_3 = 3000
      L0_3(L1_3)
      L0_3 = TriggerEvent
      L1_3 = "qs-mechanic-creator:client:updateWardrobes"
      L0_3(L1_3)
    end
    L1_2(L2_2)
  end
end
L8_1(L9_1, L10_1)
L8_1 = AddEventHandler
L9_1 = "onResourceStop"
function L10_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = cleanupWardrobeZones
    L1_2()
  end
end
L8_1(L9_1, L10_1)
L8_1 = exports
L9_1 = "IsInWorkWear"
function L10_1()
  local L0_2, L1_2
  L0_2 = L2_1
  return L0_2
end
L8_1(L9_1, L10_1)
L8_1 = exports
L9_1 = "GetCivilianClothing"
function L10_1()
  local L0_2, L1_2
  L0_2 = L1_1
  return L0_2
end
L8_1(L9_1, L10_1)
L8_1 = exports
L9_1 = "SetCivilianClothing"
function L10_1(A0_2)
  local L1_2
  L1_1 = A0_2
end
L8_1(L9_1, L10_1)
