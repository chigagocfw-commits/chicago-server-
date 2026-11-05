local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
L0_1 = {}
L1_1 = {}
L2_1 = InventoryStashSupport
if not L2_1 then
  L2_1 = false
end
InventoryStashSupport = L2_1
L2_1 = OpenStash
if not L2_1 then
  function L2_1(A0_2)
    local L1_2, L2_2
    L1_2 = openStashMenu
    L2_2 = A0_2
    L1_2(L2_2)
  end
  OpenStash = L2_1
end
function L2_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A1_2 or not A2_2 then
    return
  end
  L4_2 = A0_2
  L5_2 = "_stash_"
  L6_2 = A3_2
  L4_2 = L4_2 .. L5_2 .. L6_2
  L5_2 = A0_2
  L6_2 = "_"
  L7_2 = A3_2
  L5_2 = L5_2 .. L6_2 .. L7_2
  L6_2 = L0_1
  L6_2 = L6_2[L4_2]
  if L6_2 then
    L6_2 = RemoveInteract
    L7_2 = L4_2
    L6_2(L7_2)
    L6_2 = L0_1
    L6_2[L4_2] = nil
  end
  L6_2 = CreateStashInteract
  L7_2 = L4_2
  L8_2 = A2_2
  L9_2 = _U
  L10_2 = "STASH_PRESS_E"
  L9_2 = L9_2(L10_2)
  function L10_2()
    local L0_3, L1_3
    L0_3 = InventoryStashSupport
    if L0_3 then
      L0_3 = OpenStash
      L1_3 = L5_2
      L0_3(L1_3)
    else
      L0_3 = openStashMenu
      L1_3 = L5_2
      L0_3(L1_3)
    end
  end
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = L0_1
  L6_2[L4_2] = true
  L6_2 = true
  return L6_2
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = lib
  L1_2 = L1_2.callback
  L2_2 = "qs-mechanic-creator:server:getPlayerInventory"
  L3_2 = false
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = lib
    L1_3 = L1_3.callback
    L2_3 = "qs-mechanic-creator:server:getStashInventory"
    L3_3 = false
    function L4_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4, L13_4, L14_4, L15_4
      L1_4 = {}
      L2_4 = {}
      L3_4 = _U
      L4_4 = "DEPOSIT_ITEMS"
      L3_4 = L3_4(L4_4)
      L2_4.title = L3_4
      L3_4 = _U
      L4_4 = "ADD_ITEMS_STASH"
      L3_4 = L3_4(L4_4)
      L2_4.description = L3_4
      L2_4.icon = "fa-solid fa-arrow-down"
      function L3_4()
        local L0_5, L1_5, L2_5
        L0_5 = openDepositMenu
        L1_5 = A0_2
        L2_5 = A0_3
        L0_5(L1_5, L2_5)
      end
      L2_4.onSelect = L3_4
      L1_4[1] = L2_4
      if A0_4 then
        L2_4 = #A0_4
        if L2_4 > 0 then
          L2_4 = table
          L2_4 = L2_4.insert
          L3_4 = L1_4
          L4_4 = {}
          L4_4.title = "\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128\226\148\128"
          L4_4.disabled = true
          L2_4(L3_4, L4_4)
          L2_4 = ipairs
          L3_4 = A0_4
          L2_4, L3_4, L4_4, L5_4 = L2_4(L3_4)
          for L6_4, L7_4 in L2_4, L3_4, L4_4, L5_4 do
            L8_4 = table
            L8_4 = L8_4.insert
            L9_4 = L1_4
            L10_4 = {}
            L11_4 = L7_4.label
            L10_4.title = L11_4
            L11_4 = _U
            L12_4 = "QUANTITY"
            L11_4 = L11_4(L12_4)
            L12_4 = ": "
            L13_4 = L7_4.count
            L11_4 = L11_4 .. L12_4 .. L13_4
            L10_4.description = L11_4
            L10_4.icon = "fa-solid fa-box"
            L11_4 = {}
            L12_4 = {}
            L13_4 = _U
            L14_4 = "ITEM"
            L13_4 = L13_4(L14_4)
            L12_4.label = L13_4
            L13_4 = L7_4.name
            L12_4.value = L13_4
            L13_4 = {}
            L14_4 = _U
            L15_4 = "AMOUNT"
            L14_4 = L14_4(L15_4)
            L13_4.label = L14_4
            L14_4 = L7_4.count
            L13_4.value = L14_4
            L11_4[1] = L12_4
            L11_4[2] = L13_4
            L10_4.metadata = L11_4
            function L11_4()
              local L0_5, L1_5, L2_5, L3_5, L4_5, L5_5
              L0_5 = lib
              L0_5 = L0_5.inputDialog
              L1_5 = _U
              L2_5 = "WITHDRAW"
              L3_5 = L7_4.label
              L1_5 = L1_5(L2_5, L3_5)
              L2_5 = {}
              L3_5 = {}
              L3_5.type = "number"
              L4_5 = _U
              L5_5 = "AMOUNT"
              L4_5 = L4_5(L5_5)
              L3_5.label = L4_5
              L4_5 = _U
              L5_5 = "HOW_MANY_WITHDRAW"
              L4_5 = L4_5(L5_5)
              L3_5.description = L4_5
              L3_5.required = true
              L3_5.min = 1
              L4_5 = L7_4.count
              L3_5.max = L4_5
              L3_5.default = 1
              L2_5[1] = L3_5
              L0_5 = L0_5(L1_5, L2_5)
              if L0_5 then
                L1_5 = L0_5[1]
                if L1_5 then
                  L1_5 = TriggerServerEvent
                  L2_5 = "qs-mechanic-creator:server:withdrawFromStash"
                  L3_5 = A0_2
                  L4_5 = L7_4.name
                  L5_5 = L0_5[1]
                  L1_5(L2_5, L3_5, L4_5, L5_5)
                  L1_5 = Wait
                  L2_5 = 500
                  L1_5(L2_5)
                  L1_5 = openStashMenu
                  L2_5 = A0_2
                  L1_5(L2_5)
                end
              end
            end
            L10_4.onSelect = L11_4
            L8_4(L9_4, L10_4)
          end
      end
      else
        L2_4 = table
        L2_4 = L2_4.insert
        L3_4 = L1_4
        L4_4 = {}
        L5_4 = _U
        L6_4 = "STASH_EMPTY"
        L5_4 = L5_4(L6_4)
        L4_4.title = L5_4
        L5_4 = _U
        L6_4 = "NO_ITEMS_STASH"
        L5_4 = L5_4(L6_4)
        L4_4.description = L5_4
        L4_4.disabled = true
        L2_4(L3_4, L4_4)
      end
      L2_4 = lib
      L2_4 = L2_4.registerContext
      L3_4 = {}
      L4_4 = "mechanic_stash_"
      L5_4 = A0_2
      L4_4 = L4_4 .. L5_4
      L3_4.id = L4_4
      L4_4 = _U
      L5_4 = "STASH"
      L4_4 = L4_4(L5_4)
      L3_4.title = L4_4
      L3_4.options = L1_4
      L2_4(L3_4)
      L2_4 = lib
      L2_4 = L2_4.showContext
      L3_4 = "mechanic_stash_"
      L4_4 = A0_2
      L3_4 = L3_4 .. L4_4
      L2_4(L3_4)
    end
    L5_3 = A0_2
    L1_3(L2_3, L3_3, L4_3, L5_3)
  end
  L1_2(L2_2, L3_2, L4_2)
end
openStashMenu = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A1_2 then
    L2_2 = #A1_2
    if 0 ~= L2_2 then
      goto lbl_20
    end
  end
  L2_2 = showClientNotification
  L3_2 = {}
  L4_2 = _U
  L5_2 = "STASH"
  L4_2 = L4_2(L5_2)
  L3_2.title = L4_2
  L4_2 = _U
  L5_2 = "NO_ITEMS_DEPOSIT"
  L4_2 = L4_2(L5_2)
  L3_2.description = L4_2
  L3_2.type = "error"
  L2_2(L3_2)
  do return end
  ::lbl_20::
  L2_2 = {}
  L3_2 = ipairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = table
    L9_2 = L9_2.insert
    L10_2 = L2_2
    L11_2 = {}
    L12_2 = L8_2.label
    L11_2.title = L12_2
    L12_2 = _U
    L13_2 = "QUANTITY"
    L12_2 = L12_2(L13_2)
    L13_2 = ": "
    L14_2 = L8_2.count
    L12_2 = L12_2 .. L13_2 .. L14_2
    L11_2.description = L12_2
    L11_2.icon = "fa-solid fa-box"
    L12_2 = {}
    L13_2 = {}
    L14_2 = _U
    L15_2 = "ITEM"
    L14_2 = L14_2(L15_2)
    L13_2.label = L14_2
    L14_2 = L8_2.name
    L13_2.value = L14_2
    L14_2 = {}
    L15_2 = _U
    L16_2 = "AMOUNT"
    L15_2 = L15_2(L16_2)
    L14_2.label = L15_2
    L15_2 = L8_2.count
    L14_2.value = L15_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L11_2.metadata = L12_2
    function L12_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = lib
      L0_3 = L0_3.inputDialog
      L1_3 = _U
      L2_3 = "DEPOSIT"
      L3_3 = L8_2.label
      L1_3 = L1_3(L2_3, L3_3)
      L2_3 = {}
      L3_3 = {}
      L3_3.type = "number"
      L4_3 = _U
      L5_3 = "AMOUNT"
      L4_3 = L4_3(L5_3)
      L3_3.label = L4_3
      L4_3 = _U
      L5_3 = "HOW_MANY_DEPOSIT"
      L4_3 = L4_3(L5_3)
      L3_3.description = L4_3
      L3_3.required = true
      L3_3.min = 1
      L4_3 = L8_2.count
      L3_3.max = L4_3
      L3_3.default = 1
      L2_3[1] = L3_3
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L1_3 = L0_3[1]
        if L1_3 then
          L1_3 = TriggerServerEvent
          L2_3 = "qs-mechanic-creator:server:depositToStash"
          L3_3 = A0_2
          L4_3 = L8_2.name
          L5_3 = L0_3[1]
          L1_3(L2_3, L3_3, L4_3, L5_3)
          L1_3 = Wait
          L2_3 = 500
          L1_3(L2_3)
          L1_3 = openStashMenu
          L2_3 = A0_2
          L1_3(L2_3)
        end
      end
    end
    L11_2.onSelect = L12_2
    L9_2(L10_2, L11_2)
  end
  L3_2 = lib
  L3_2 = L3_2.registerContext
  L4_2 = {}
  L5_2 = "mechanic_deposit_"
  L6_2 = A0_2
  L5_2 = L5_2 .. L6_2
  L4_2.id = L5_2
  L5_2 = _U
  L6_2 = "DEPOSIT_ITEMS"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = "mechanic_stash_"
  L6_2 = A0_2
  L5_2 = L5_2 .. L6_2
  L4_2.menu = L5_2
  L4_2.options = L2_2
  L3_2(L4_2)
  L3_2 = lib
  L3_2 = L3_2.showContext
  L4_2 = "mechanic_deposit_"
  L5_2 = A0_2
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
end
openDepositMenu = L3_1
function L3_1()
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
cleanupStashZones = L3_1
L3_1 = AddEventHandler
L4_1 = "qs-mechanic-creator:client:updateStashes"
function L5_1()
  local L0_2, L1_2
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3
    L0_3 = cleanupStashZones
    L0_3()
    L0_3 = Wait
    L1_3 = 200
    L0_3(L1_3)
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Stashes
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
              L8_3 = ipairs
              L9_3 = L6_3.locations
              L8_3, L9_3, L10_3, L11_3 = L8_3(L9_3)
              for L12_3, L13_3 in L8_3, L9_3, L10_3, L11_3 do
                L14_3 = L2_1
                L15_3 = L5_3
                L16_3 = L6_3
                L17_3 = L13_3
                L18_3 = L12_3
                L14_3(L15_3, L16_3, L17_3, L18_3)
                L0_3 = L0_3 + 1
                L14_3 = L0_3 % 3
                if 0 == L14_3 then
                  L14_3 = Wait
                  L15_3 = 100
                  L14_3(L15_3)
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
L3_1(L4_1, L5_1)
L3_1 = AddEventHandler
L4_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L5_1(A0_2)
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
L3_1(L4_1, L5_1)
L3_1 = AddEventHandler
L4_1 = "onResourceStop"
function L5_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = cleanupStashZones
    L1_2()
  end
end
L3_1(L4_1, L5_1)
