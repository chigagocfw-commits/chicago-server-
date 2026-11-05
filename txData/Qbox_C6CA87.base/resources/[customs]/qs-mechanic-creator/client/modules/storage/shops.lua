local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = InventoryShopSupport
if not L3_1 then
  L3_1 = false
end
InventoryShopSupport = L3_1
L3_1 = OpenShop
if not L3_1 then
  function L3_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2
    if A1_2 then
      L2_2 = A1_2.items
      if L2_2 then
        L2_2 = openShopMenu
        L3_2 = A0_2
        L4_2 = A1_2.items
        L2_2(L3_2, L4_2)
      end
    end
  end
  OpenShop = L3_1
end
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A1_2 or not A2_2 then
    return
  end
  L4_2 = A2_2.items
  if L4_2 then
    L4_2 = type
    L5_2 = A2_2.items
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L4_2 = A2_2.items
      L4_2 = #L4_2
      if 0 ~= L4_2 then
        goto lbl_19
      end
    end
  end
  do return end
  ::lbl_19::
  L4_2 = A0_2
  L5_2 = "_shop_"
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
  L5_2 = CreateShopInteract
  L6_2 = L4_2
  L7_2 = A2_2
  L8_2 = _U
  L9_2 = "SHOP_PRESS_E"
  L8_2 = L8_2(L9_2)
  function L9_2()
    local L0_3, L1_3, L2_3, L3_3
    L0_3 = InventoryShopSupport
    if L0_3 then
      L0_3 = OpenShop
      L1_3 = A0_2
      L2_3 = {}
      L3_3 = A2_2.items
      L2_3.items = L3_3
      L0_3(L1_3, L2_3)
    else
      L0_3 = openShopMenu
      L1_3 = A0_2
      L2_3 = A2_2.items
      if not L2_3 then
        L2_3 = {}
      end
      L0_3(L1_3, L2_3)
    end
  end
  L5_2(L6_2, L7_2, L8_2, L9_2)
  L5_2 = L0_1
  L5_2[L4_2] = true
  L5_2 = true
  return L5_2
end
L4_1 = {}
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A1_2 then
    L2_2 = #A1_2
    if 0 ~= L2_2 then
      goto lbl_14
    end
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L3_2 = "qs-mechanic-creator:server:getShopItems"
  L4_2 = false
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    if A0_3 then
      L1_3 = #A0_3
      if L1_3 > 0 then
        L1_3 = openShopMenuWithItems
        L2_3 = A0_2
        L3_3 = A0_3
        L1_3(L2_3, L3_3)
    end
    else
      L1_3 = GetGameTimer
      L1_3 = L1_3()
      L3_3 = A0_2
      L2_3 = L4_1
      L2_3 = L2_3[L3_3]
      if L2_3 then
        L3_3 = A0_2
        L2_3 = L4_1
        L2_3 = L2_3[L3_3]
        L2_3 = L1_3 - L2_3
        L3_3 = 10000
        if not (L2_3 > L3_3) then
          goto lbl_42
        end
      end
      L2_3 = showClientNotification
      L3_3 = {}
      L4_3 = _U
      L5_3 = "SHOP"
      L4_3 = L4_3(L5_3)
      L3_3.title = L4_3
      L4_3 = _U
      L5_3 = "SHOP_NO_ITEMS"
      L4_3 = L4_3(L5_3)
      L3_3.description = L4_3
      L3_3.type = "error"
      L2_3(L3_3)
      L3_3 = A0_2
      L2_3 = L4_1
      L2_3[L3_3] = L1_3
    end
    ::lbl_42::
  end
  L6_2 = A0_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
  do return end
  ::lbl_14::
  L2_2 = openShopMenuWithItems
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end
openShopMenu = L5_1
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A1_2 then
    L2_2 = #A1_2
    if 0 ~= L2_2 then
      goto lbl_7
    end
  end
  do return end
  ::lbl_7::
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.price
    if not L9_2 then
      L9_2 = 0
    end
    L10_2 = table
    L10_2 = L10_2.insert
    L11_2 = L2_2
    L12_2 = {}
    L13_2 = L8_2.label
    L12_2.title = L13_2
    if L9_2 > 0 then
      L13_2 = string
      L13_2 = L13_2.format
      L14_2 = "$%d - %s"
      L15_2 = L9_2
      L16_2 = L8_2.item
      L13_2 = L13_2(L14_2, L15_2, L16_2)
      if L13_2 then
        goto lbl_40
      end
    end
    L13_2 = _U
    L14_2 = "ITEM"
    L13_2 = L13_2(L14_2)
    L14_2 = ": "
    L15_2 = L8_2.item
    L13_2 = L13_2 .. L14_2 .. L15_2
    ::lbl_40::
    L12_2.description = L13_2
    L12_2.icon = "fa-solid fa-box"
    if L9_2 > 0 then
      L13_2 = {}
      L14_2 = {}
      L15_2 = _U
      L16_2 = "PRICE"
      L15_2 = L15_2(L16_2)
      L14_2.label = L15_2
      L15_2 = "$"
      L16_2 = L9_2
      L15_2 = L15_2 .. L16_2
      L14_2.value = L15_2
      L13_2[1] = L14_2
      if L13_2 then
        goto lbl_60
      end
    end
    L13_2 = nil
    ::lbl_60::
    L12_2.metadata = L13_2
    function L13_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
      L0_3 = lib
      L0_3 = L0_3.inputDialog
      L1_3 = _U
      L2_3 = "PURCHASE"
      L3_3 = L8_2.label
      L1_3 = L1_3(L2_3, L3_3)
      L2_3 = {}
      L3_3 = {}
      L3_3.type = "number"
      L4_3 = _U
      L5_3 = "QUANTITY"
      L4_3 = L4_3(L5_3)
      L3_3.label = L4_3
      L4_3 = _U
      L5_3 = "HOW_MANY_BUY"
      L4_3 = L4_3(L5_3)
      L3_3.description = L4_3
      L3_3.required = true
      L3_3.min = 1
      L3_3.default = 1
      L2_3[1] = L3_3
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L1_3 = L0_3[1]
        if L1_3 then
          L1_3 = TriggerServerEvent
          L2_3 = "qs-mechanic-creator:server:buyShopItem"
          L3_3 = A0_2
          L4_3 = L8_2.item
          L5_3 = L0_3[1]
          L6_3 = L8_2.price
          if not L6_3 then
            L6_3 = 0
          end
          L1_3(L2_3, L3_3, L4_3, L5_3, L6_3)
        end
      end
    end
    L12_2.onSelect = L13_2
    L10_2(L11_2, L12_2)
  end
  L3_2 = lib
  L3_2 = L3_2.registerContext
  L4_2 = {}
  L5_2 = "mechanic_shop_"
  L6_2 = A0_2
  L5_2 = L5_2 .. L6_2
  L4_2.id = L5_2
  L5_2 = _U
  L6_2 = "MECHANIC_SHOP"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L4_2.options = L2_2
  L3_2(L4_2)
  L3_2 = lib
  L3_2 = L3_2.showContext
  L4_2 = "mechanic_shop_"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
end
openShopMenuWithItems = L5_1
function L5_1()
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
cleanupShopZones = L5_1
L5_1 = AddEventHandler
L6_1 = "qs-mechanic-creator:client:updateShops"
function L7_1()
  local L0_2, L1_2
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3
    L0_3 = cleanupShopZones
    L0_3()
    L0_3 = Wait
    L1_3 = 200
    L0_3(L1_3)
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Shops
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
            L8_3 = hasShopAccess
            L9_3 = L7_3
            L8_3 = L8_3(L9_3)
            if L8_3 then
              L9_3 = ipairs
              L10_3 = L6_3.locations
              L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3)
              for L13_3, L14_3 in L9_3, L10_3, L11_3, L12_3 do
                L15_3 = L14_3.items
                if L15_3 then
                  L15_3 = type
                  L16_3 = L14_3.items
                  L15_3 = L15_3(L16_3)
                  if "table" == L15_3 then
                    L15_3 = L3_1
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
      L7_3 = Wait
      L8_3 = 50
      L7_3(L8_3)
    end
  end
  L0_2(L1_2)
end
L5_1(L6_1, L7_1)
L5_1 = AddEventHandler
L6_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if not A0_2 then
    return
  end
  L1_2 = pairs
  L2_2 = L0_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = string
    L7_2 = L7_2.find
    L8_2 = L5_2
    L9_2 = A0_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      L7_2 = RemoveInteract
      L8_2 = L5_2
      L7_2(L8_2)
      L7_2 = L0_1
      L7_2[L5_2] = nil
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = AddEventHandler
L6_1 = "onResourceStop"
function L7_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = cleanupShopZones
    L1_2()
  end
end
L5_1(L6_1, L7_1)
