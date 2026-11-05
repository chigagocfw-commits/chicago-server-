local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = false
L1_1 = nil
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = L0_1
  if L1_2 then
    return
  end
  L1_2 = true
  L0_1 = L1_2
  L1_1 = A0_2
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = {}
  L2_2 = nil
  if A0_2 then
    L3_2 = lib
    L3_2 = L3_2.callback
    L3_2 = L3_2.await
    L4_2 = "qs-mechanic-creator:server:getEngineStock"
    L5_2 = false
    L6_2 = A0_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L1_2 = L3_2 or L1_2
    if not L3_2 then
      L3_2 = {}
      L1_2 = L3_2
    end
    L3_2 = lib
    L3_2 = L3_2.callback
    L3_2 = L3_2.await
    L4_2 = "qs-mechanic-creator:server:getPalletEngine"
    L5_2 = false
    L6_2 = A0_2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2 = L3_2
  end
  L3_2 = {}
  L4_2 = EngineCatalog
  if L4_2 then
    L4_2 = type
    L5_2 = EngineCatalog
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      L4_2 = pairs
      L5_2 = EngineCatalog
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
        L10_2 = table
        L10_2 = L10_2.insert
        L11_2 = L3_2
        L12_2 = {}
        L13_2 = L9_2.id
        L12_2.id = L13_2
        L13_2 = L9_2.name
        L12_2.name = L13_2
        L13_2 = L9_2.power
        L12_2.power = L13_2
        L13_2 = L9_2.speed
        L12_2.speed = L13_2
        L13_2 = L9_2.acceleration
        L12_2.acceleration = L13_2
        L13_2 = L9_2.torque
        L12_2.torque = L13_2
        L13_2 = L9_2.price
        L12_2.price = L13_2
        L13_2 = L9_2.image
        L12_2.image = L13_2
        L13_2 = L9_2.peakHPRPM
        L12_2.peakHPRPM = L13_2
        L13_2 = L9_2.peakTorqueRPM
        L12_2.peakTorqueRPM = L13_2
        L13_2 = L9_2.engineType
        L12_2.engineType = L13_2
        L10_2(L11_2, L12_2)
      end
      L4_2 = table
      L4_2 = L4_2.sort
      L5_2 = L3_2
      function L6_2(A0_3, A1_3)
        local L2_3, L3_3
        L2_3 = A0_3.id
        if not L2_3 then
          L2_3 = 0
        end
        L3_3 = A1_3.id
        if not L3_3 then
          L3_3 = 0
        end
        L2_3 = L2_3 < L3_3
        return L2_3
      end
      L4_2(L5_2, L6_2)
    end
  end
  L4_2 = SendNUIMessage
  L5_2 = {}
  L5_2.type = "openEnginesUI"
  L5_2.mechanicId = A0_2
  L5_2.engines = L3_2
  L5_2.stock = L1_2
  L5_2.palletEngine = L2_2
  L6_2 = GetLocales
  L6_2 = L6_2()
  L5_2.locales = L6_2
  L4_2(L5_2)
end
function L3_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L0_1 = L0_2
  L0_2 = nil
  L1_1 = L0_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.type = "closeEnginesUI"
  L0_2(L1_2)
end
L4_1 = RegisterNUICallback
L5_1 = "closeEnginesLaptop"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L3_1
  L2_2()
  L2_2 = A1_2
  L3_2 = {}
  L3_2.status = "ok"
  L2_2(L3_2)
end
L4_1(L5_1, L6_1)
L4_1 = CreateThread
function L5_1()
  local L0_2, L1_2, L2_2, L3_2
  while true do
    L0_2 = Wait
    L1_2 = 0
    L0_2(L1_2)
    L0_2 = L0_1
    if L0_2 then
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 1
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 2
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 24
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 25
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 142
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 106
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = IsControlJustPressed
      L1_2 = 0
      L2_2 = 322
      L0_2 = L0_2(L1_2, L2_2)
      if L0_2 then
        L0_2 = L3_1
        L0_2()
      end
    else
      L0_2 = Wait
      L1_2 = 500
      L0_2(L1_2)
    end
  end
end
L4_1(L5_1)
L4_1 = RegisterNetEvent
L5_1 = "qs-mechanic-creator:client:engineSwapLaptop"
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = lib
  L1_2 = L1_2.callback
  L1_2 = L1_2.await
  L2_2 = "qs-mechanic-creator:server:getMechanicShops"
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = L1_2 or L2_2
  if L1_2 then
    L2_2 = L1_2[A0_2]
  end
  if L2_2 then
    L3_2 = L2_2.shopConfig
    if L3_2 then
      L3_2 = L2_2.shopConfig
      L3_2 = L3_2.engineSwap
      if L3_2 then
        L3_2 = tonumber
        L4_2 = L2_2.shopConfig
        L4_2 = L4_2.engineSwap
        L4_2 = L4_2.laptopGrade
        L3_2 = L3_2(L4_2)
        if not L3_2 then
          L3_2 = 0
        end
        if L3_2 > 0 then
          L4_2 = getPlayerData
          L4_2 = L4_2()
          L5_2 = 0
          if L4_2 then
            L6_2 = L4_2.job
            if L6_2 then
              L6_2 = type
              L7_2 = L4_2.job
              L6_2 = L6_2(L7_2)
              if "table" == L6_2 then
                L6_2 = tonumber
                L7_2 = L4_2.job
                L7_2 = L7_2.grade
                L6_2 = L6_2(L7_2)
                L5_2 = L6_2 or L5_2
                if not L6_2 then
                  L5_2 = 0
                end
              end
            end
          end
          if L3_2 > L5_2 then
            L6_2 = showClientNotification
            L7_2 = {}
            L8_2 = _U
            L9_2 = "ACCESS_DENIED"
            L8_2 = L8_2(L9_2)
            if not L8_2 then
              L8_2 = "Access Denied"
            end
            L7_2.title = L8_2
            L8_2 = _U
            L9_2 = "INSUFFICIENT_GRADE_LAPTOP"
            L8_2 = L8_2(L9_2)
            if not L8_2 then
              L8_2 = "You need grade %d or higher to access this laptop"
            end
            L9_2 = L8_2
            L8_2 = L8_2.format
            L10_2 = L3_2
            L8_2 = L8_2(L9_2, L10_2)
            L7_2.description = L8_2
            L7_2.type = "error"
            L6_2(L7_2)
            return
          end
        end
      end
    end
  end
  L3_2 = L2_1
  L4_2 = A0_2
  L3_2(L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "purchaseEngine"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 then
    L2_2 = A0_2.mechanicId
    if L2_2 then
      L2_2 = A0_2.engineData
      if L2_2 then
        goto lbl_30
      end
    end
  end
  L2_2 = lib
  L2_2 = L2_2.notify
  L3_2 = {}
  L4_2 = _U
  L5_2 = "ENGINE_PURCHASE_TITLE"
  L4_2 = L4_2(L5_2)
  L3_2.title = L4_2
  L4_2 = _U
  L5_2 = "ENGINE_PURCHASE_INVALID"
  L4_2 = L4_2(L5_2)
  L3_2.description = L4_2
  L3_2.type = "error"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.message = "Invalid purchase data"
  L2_2(L3_2)
  do return end
  ::lbl_30::
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "qs-mechanic-creator:server:purchaseEngine"
  L4_2 = false
  L5_2 = A0_2.mechanicId
  L6_2 = A0_2.engineData
  L2_2, L3_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  if L2_2 then
    L4_2 = lib
    L4_2 = L4_2.notify
    L5_2 = {}
    L6_2 = _U
    L7_2 = "ENGINE_PURCHASE_TITLE"
    L6_2 = L6_2(L7_2)
    L5_2.title = L6_2
    L6_2 = _U
    L7_2 = "ENGINE_PURCHASE_SUCCESS"
    L6_2 = L6_2(L7_2)
    L5_2.description = L6_2
    L5_2.type = "success"
    L4_2(L5_2)
    L4_2 = lib
    L4_2 = L4_2.callback
    L4_2 = L4_2.await
    L5_2 = "qs-mechanic-creator:server:getEngineStock"
    L6_2 = false
    L7_2 = A0_2.mechanicId
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    if not L4_2 then
      L4_2 = {}
    end
    L5_2 = SendNUIMessage
    L6_2 = {}
    L6_2.type = "updateEngines"
    L6_2.stock = L4_2
    L5_2(L6_2)
  else
    L4_2 = lib
    L4_2 = L4_2.notify
    L5_2 = {}
    L6_2 = _U
    L7_2 = "ENGINE_PURCHASE_TITLE"
    L6_2 = L6_2(L7_2)
    L5_2.title = L6_2
    L6_2 = L3_2 or L6_2
    if not L3_2 then
      L6_2 = _U
      L7_2 = "ENGINE_PURCHASE_FAILED"
      L6_2 = L6_2(L7_2)
    end
    L5_2.description = L6_2
    L5_2.type = "error"
    L4_2(L5_2)
  end
  L4_2 = A1_2
  L5_2 = {}
  L5_2.success = L2_2
  L5_2.message = L3_2
  L4_2(L5_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "qs-mechanic-creator:client:engineStockUpdated"
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L0_1
  if L1_2 then
    L1_2 = L1_1
    if L1_2 == A0_2 then
      L1_2 = lib
      L1_2 = L1_2.callback
      L1_2 = L1_2.await
      L2_2 = "qs-mechanic-creator:server:getEngineStock"
      L3_2 = false
      L4_2 = A0_2
      L1_2 = L1_2(L2_2, L3_2, L4_2)
      if not L1_2 then
        L1_2 = {}
      end
      L2_2 = SendNUIMessage
      L3_2 = {}
      L3_2.type = "updateEngines"
      L3_2.stock = L1_2
      L2_2(L3_2)
    end
  end
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNUICallback
L5_1 = "placeEngineOnPallet"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A0_2 then
    L2_2 = A0_2.mechanicId
    if L2_2 then
      L2_2 = A0_2.stockEngineId
      if L2_2 then
        goto lbl_30
      end
    end
  end
  L2_2 = lib
  L2_2 = L2_2.notify
  L3_2 = {}
  L4_2 = _U
  L5_2 = "ENGINE_PLACEMENT_TITLE"
  L4_2 = L4_2(L5_2)
  L3_2.title = L4_2
  L4_2 = _U
  L5_2 = "ENGINE_PLACEMENT_INVALID"
  L4_2 = L4_2(L5_2)
  L3_2.description = L4_2
  L3_2.type = "error"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.message = "Invalid data"
  L2_2(L3_2)
  do return end
  ::lbl_30::
  L2_2 = A0_2.removeFromPallet
  if not L2_2 then
    L2_2 = false
  end
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:placeEngineOnPallet"
  L5_2 = false
  L6_2 = A0_2.mechanicId
  L7_2 = A0_2.stockEngineId
  L8_2 = L2_2
  L3_2, L4_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
  if L3_2 then
    L5_2 = lib
    L5_2 = L5_2.notify
    L6_2 = {}
    L7_2 = _U
    L8_2 = "ENGINE_PLACEMENT_TITLE"
    L7_2 = L7_2(L8_2)
    L6_2.title = L7_2
    L7_2 = L4_2 or L7_2
    if not L4_2 then
      if L2_2 then
        L7_2 = _U
        L8_2 = "ENGINE_PLACEMENT_REMOVED"
        L7_2 = L7_2(L8_2)
        if L7_2 then
          goto lbl_65
        end
      end
      L7_2 = _U
      L8_2 = "ENGINE_PLACEMENT_SUCCESS"
      L7_2 = L7_2(L8_2)
    end
    ::lbl_65::
    L6_2.description = L7_2
    L6_2.type = "success"
    L5_2(L6_2)
    L5_2 = lib
    L5_2 = L5_2.callback
    L5_2 = L5_2.await
    L6_2 = "qs-mechanic-creator:server:getEngineStock"
    L7_2 = false
    L8_2 = A0_2.mechanicId
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if not L5_2 then
      L5_2 = {}
    end
    L6_2 = lib
    L6_2 = L6_2.callback
    L6_2 = L6_2.await
    L7_2 = "qs-mechanic-creator:server:getPalletEngine"
    L8_2 = false
    L9_2 = A0_2.mechanicId
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    L7_2 = SendNUIMessage
    L8_2 = {}
    L8_2.type = "updateEngines"
    L8_2.stock = L5_2
    L8_2.palletEngine = L6_2
    L7_2(L8_2)
  else
    L5_2 = lib
    L5_2 = L5_2.notify
    L6_2 = {}
    L7_2 = _U
    L8_2 = "ENGINE_PLACEMENT_TITLE"
    L7_2 = L7_2(L8_2)
    L6_2.title = L7_2
    L7_2 = L4_2 or L7_2
    if not L4_2 then
      L7_2 = _U
      L8_2 = "ENGINE_PLACEMENT_FAILED"
      L7_2 = L7_2(L8_2)
    end
    L6_2.description = L7_2
    L6_2.type = "error"
    L5_2(L6_2)
  end
  L5_2 = A1_2
  L6_2 = {}
  L6_2.success = L3_2
  L6_2.message = L4_2
  L5_2(L6_2)
end
L4_1(L5_1, L6_1)
