local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1
L0_1 = false
L1_1 = nil
L2_1 = nil
L3_1 = {}
L3_1.dataReceived = false
L4_1 = {}
L4_1.dict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
L4_1.anim = "base"
L5_1 = table
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = nil
  if "table" == L1_2 then
    L3_2 = {}
    L2_2 = L3_2
    L3_2 = pairs
    L4_2 = A0_2
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L2_2[L7_2] = L8_2
    end
  else
    L2_2 = A0_2
  end
  return L2_2
end
L5_1.clone = L6_1
L5_1 = {}
L6_1 = 0
L7_1 = 5000
function L8_1()
  local L0_2, L1_2
  L0_2 = {}
  L5_1 = L0_2
  L0_2 = 0
  L6_1 = L0_2
end
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L0_2 = Config
  L0_2 = L0_2.Tuneshops
  if not L0_2 then
    L0_2 = Config
    L0_2 = L0_2.Debug
    if L0_2 then
      L0_2 = print
      L1_2 = "[TABLET DEBUG] Config.Tuneshops is nil"
      L0_2(L1_2)
    end
    L0_2 = nil
    return L0_2
  end
  L0_2 = playerLicense
  if L0_2 then
    L0_2 = playerJob
    if L0_2 then
      goto lbl_44
    end
  end
  L0_2 = Config
  L0_2 = L0_2.Debug
  if L0_2 then
    L0_2 = print
    L1_2 = "[TABLET DEBUG] playerLicense or playerJob is nil"
    L0_2(L1_2)
    L0_2 = print
    L1_2 = "[TABLET DEBUG] playerLicense:"
    L2_2 = playerLicense
    L0_2(L1_2, L2_2)
    L0_2 = print
    L1_2 = "[TABLET DEBUG] playerJob:"
    L2_2 = playerJob
    if L2_2 then
      L2_2 = playerJob
      L2_2 = L2_2.name
      if L2_2 then
        goto lbl_41
      end
    end
    L2_2 = "nil"
    ::lbl_41::
    L0_2(L1_2, L2_2)
  end
  L0_2 = nil
  do return L0_2 end
  ::lbl_44::
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L1_2 = playerJob
  L1_2 = L1_2.name
  if not L1_2 then
    L1_2 = playerJob
  end
  L2_2 = playerLicense
  L3_2 = ":"
  L4_2 = L1_2 or L4_2
  if not L1_2 then
    L4_2 = "none"
  end
  L2_2 = L2_2 .. L3_2 .. L4_2
  L3_2 = L5_1
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = L6_1
    L3_2 = L0_2 - L3_2
    L4_2 = L7_1
    if L3_2 < L4_2 then
      L3_2 = L5_1
      L3_2 = L3_2[L2_2]
      return L3_2
    end
  end
  L3_2 = nil
  L4_2 = nil
  L5_2 = pairs
  L6_2 = Config
  L6_2 = L6_2.Tuneshops
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = table
    L11_2 = L11_2.clone
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    L11_2.id = L9_2
    L12_2 = L11_2.created_by
    L13_2 = playerLicense
    if L12_2 and L13_2 and L12_2 == L13_2 then
      L4_2 = L9_2
      L12_2 = Config
      L12_2 = L12_2.Debug
      if L12_2 then
        L12_2 = print
        L13_2 = "[TABLET DEBUG] Found owner shop:"
        L14_2 = L9_2
        L12_2(L13_2, L14_2)
      end
      break
    end
    L12_2 = L11_2.ownerLicense
    L13_2 = playerLicense
    if L12_2 and L13_2 and L12_2 == L13_2 then
      L4_2 = L9_2
      L12_2 = Config
      L12_2 = L12_2.Debug
      if L12_2 then
        L12_2 = print
        L13_2 = "[TABLET DEBUG] Found owner shop:"
        L14_2 = L9_2
        L12_2(L13_2, L14_2)
      end
      break
    end
    L12_2 = L11_2.job
    if L12_2 then
      L12_2 = L11_2.job
      if "" ~= L12_2 then
        L12_2 = L11_2.job
        L12_2 = L1_2 == L12_2
        if L12_2 then
          L13_2 = tonumber
          L14_2 = L11_2.jobGrade
          L13_2 = L13_2(L14_2)
          if not L13_2 then
            L13_2 = 0
          end
          L14_2 = tonumber
          L15_2 = playerJob
          L15_2 = L15_2.grade
          L14_2 = L14_2(L15_2)
          if not L14_2 then
            L14_2 = 0
          end
          if L13_2 <= L14_2 then
            L3_2 = L9_2
            L15_2 = Config
            L15_2 = L15_2.Debug
            if L15_2 then
              L15_2 = print
              L16_2 = "[TABLET DEBUG] Found job shop:"
              L17_2 = L9_2
              L18_2 = "job:"
              L19_2 = L11_2.job
              L15_2(L16_2, L17_2, L18_2, L19_2)
            end
          else
            L15_2 = Config
            L15_2 = L15_2.Debug
            if L15_2 then
              L15_2 = print
              L16_2 = "[TABLET DEBUG] Job matches but grade insufficient:"
              L17_2 = L14_2
              L18_2 = "<"
              L19_2 = L13_2
              L15_2(L16_2, L17_2, L18_2, L19_2)
            end
          end
        end
    end
    else
      L12_2 = L11_2.job
      if L12_2 then
        L12_2 = L11_2.job
      end
      if "" == L12_2 and not L4_2 and not L3_2 then
        L3_2 = L9_2
        L12_2 = Config
        L12_2 = L12_2.Debug
        if L12_2 then
          L12_2 = print
          L13_2 = "[TABLET DEBUG] Found public shop:"
          L14_2 = L9_2
          L12_2(L13_2, L14_2)
        end
      end
    end
  end
  L5_2 = L4_2 or L5_2
  if not L4_2 then
    L5_2 = L3_2
  end
  L6_2 = L5_1
  L6_2[L2_2] = L5_2
  L6_1 = L0_2
  L6_2 = Config
  L6_2 = L6_2.Debug
  if L6_2 then
    L6_2 = print
    L7_2 = "[TABLET DEBUG] findPlayerShop result:"
    L8_2 = L5_2
    L6_2(L7_2, L8_2)
  end
  return L5_2
end
function L10_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = DoesEntityExist
  L2_2 = L2_1
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = RequestAnimDict
    L2_2 = L4_1.dict
    L1_2(L2_2)
    while true do
      L1_2 = HasAnimDictLoaded
      L2_2 = L4_1.dict
      L1_2 = L1_2(L2_2)
      if L1_2 then
        break
      end
      L1_2 = Wait
      L2_2 = 0
      L1_2(L2_2)
    end
    L1_2 = GetEntityCoords
    L2_2 = L0_2
    L1_2 = L1_2(L2_2)
    L2_2 = CreateObject
    L3_2 = GetHashKey
    L4_2 = "prop_cs_tablet"
    L3_2 = L3_2(L4_2)
    L4_2 = L1_2.x
    L5_2 = L1_2.y
    L6_2 = L1_2.z
    L7_2 = true
    L8_2 = true
    L9_2 = false
    L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
    L2_1 = L2_2
    L2_2 = GetPedBoneIndex
    L3_2 = L0_2
    L4_2 = 60309
    L2_2 = L2_2(L3_2, L4_2)
    L3_2 = AttachEntityToEntity
    L4_2 = L2_1
    L5_2 = L0_2
    L6_2 = L2_2
    L7_2 = 0.02
    L8_2 = 0.0
    L9_2 = -0.02
    L10_2 = 0.0
    L11_2 = 0.0
    L12_2 = 0.0
    L13_2 = true
    L14_2 = true
    L15_2 = false
    L16_2 = true
    L17_2 = 1
    L18_2 = true
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L3_2 = TaskPlayAnim
    L4_2 = L0_2
    L5_2 = L4_1.dict
    L6_2 = L4_1.anim
    L7_2 = 3.0
    L8_2 = 3.0
    L9_2 = -1
    L10_2 = 49
    L11_2 = 0
    L12_2 = false
    L13_2 = false
    L14_2 = false
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
end
function L11_1()
  local L0_2, L1_2, L2_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = ClearPedTasks
  L2_2 = L0_2
  L1_2(L2_2)
  L1_2 = DoesEntityExist
  L2_2 = L2_1
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeleteEntity
    L2_2 = L2_1
    L1_2(L2_2)
    L1_2 = nil
    L2_1 = L1_2
  end
end
function L12_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = IsPedInAnyVehicle
  L2_2 = L0_2
  L3_2 = false
  return L1_2(L2_2, L3_2)
end
function L13_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = L0_1
  if L0_2 then
    return
  end
  L0_2 = getPlayerData
  L0_2 = L0_2()
  if L0_2 then
    L1_2 = L0_2.job
    if L1_2 then
      goto lbl_26
    end
    L1_2 = L0_2.license
    if L1_2 then
      goto lbl_26
    end
  end
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:requestPlayerData"
  L1_2(L2_2)
  L1_2 = showClientNotification
  L2_2 = {}
  L2_2.title = "Tablet"
  L2_2.description = "Loading player data, please try again in a moment"
  L2_2.type = "info"
  L1_2(L2_2)
  do return end
  ::lbl_26::
  L1_2 = playerJob
  if L1_2 then
    L1_2 = playerLicense
    if L1_2 then
      goto lbl_43
    end
  end
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:requestPlayerData"
  L1_2(L2_2)
  L1_2 = showClientNotification
  L2_2 = {}
  L2_2.title = "Tablet"
  L2_2.description = "Player data not loaded yet, please try again"
  L2_2.type = "error"
  L1_2(L2_2)
  do return end
  ::lbl_43::
  L1_2 = Config
  L1_2 = L1_2.Tuneshops
  if L1_2 then
    L1_2 = next
    L2_2 = Config
    L2_2 = L2_2.Tuneshops
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_64
    end
  end
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:getMechanicShopsForceSync"
  L1_2(L2_2)
  L1_2 = showClientNotification
  L2_2 = {}
  L2_2.title = "Tablet"
  L2_2.description = "Shop data not loaded yet, please try again"
  L2_2.type = "error"
  L1_2(L2_2)
  do return end
  ::lbl_64::
  L1_2 = false
  L2_2 = L9_1
  L2_2 = L2_2()
  L1_2 = nil ~= L2_2
  if not L1_2 then
    L3_2 = showClientNotification
    L4_2 = {}
    L4_2.title = "Tablet"
    L5_2 = _U
    L6_2 = "NOTIFICATION_NEED_MECHANIC_JOB"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
    return
  end
  L3_2 = L9_1
  L3_2 = L3_2()
  if not L3_2 then
    L4_2 = showClientNotification
    L5_2 = {}
    L5_2.title = "Tablet"
    L5_2.description = "You don't have access to any mechanic shop"
    L5_2.type = "error"
    L4_2(L5_2)
    return
  end
  L1_1 = L3_2
  L4_2 = true
  L0_1 = L4_2
  L4_2 = L10_1
  L4_2()
  L4_2 = {}
  L4_2.hasDutySystem = false
  L4_2.onDuty = true
  L5_2 = hasDutySystem
  if L5_2 then
    L5_2 = type
    L6_2 = hasDutySystem
    L5_2 = L5_2(L6_2)
    if "function" == L5_2 then
      L5_2 = hasDutySystem
      L5_2 = L5_2()
      L4_2.hasDutySystem = L5_2
      L5_2 = L4_2.hasDutySystem
      if L5_2 then
        L5_2 = isPlayerOnDuty
        if L5_2 then
          L5_2 = type
          L6_2 = isPlayerOnDuty
          L5_2 = L5_2(L6_2)
          if "function" == L5_2 then
            L5_2 = isPlayerOnDuty
            L5_2 = L5_2()
            L4_2.onDuty = L5_2
          end
        end
      end
    end
  end
  L5_2 = SendNUIMessage
  L6_2 = {}
  L6_2.action = "openTablet"
  L7_2 = GetLocales
  L7_2 = L7_2()
  L6_2.locales = L7_2
  L6_2.dutyInfo = L4_2
  L5_2(L6_2)
  L5_2 = SetNuiFocus
  L6_2 = true
  L7_2 = true
  L5_2(L6_2, L7_2)
  L5_2 = L12_1
  L5_2 = L5_2()
  L6_2 = nil
  if L5_2 then
    L7_2 = GetVehiclePedIsIn
    L8_2 = PlayerPedId
    L8_2 = L8_2()
    L9_2 = false
    L7_2 = L7_2(L8_2, L9_2)
    L8_2 = GetEntityModel
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L9_2 = GetDisplayNameFromVehicleModel
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L10_2 = {}
    L10_2.name = L9_2
    L11_2 = _U
    L12_2 = "TABLET_READY_FOR_DIAGNOSTIC"
    L11_2 = L11_2(L12_2)
    L10_2.details = L11_2
    L6_2 = L10_2
  end
  L7_2 = Config
  L7_2 = L7_2.Tuneshops
  L8_2 = L1_1
  L7_2 = L7_2[L8_2]
  L8_2 = _U
  L9_2 = "MECHANIC_SHOP"
  L8_2 = L8_2(L9_2)
  if L7_2 then
    L9_2 = L7_2.shopConfig
    if L9_2 then
      L9_2 = L7_2.shopConfig
      L9_2 = L9_2.blip
      if L9_2 then
        L9_2 = L7_2.shopConfig
        L9_2 = L9_2.blip
        L9_2 = L9_2.name
        if L9_2 then
          L9_2 = L7_2.shopConfig
          L9_2 = L9_2.blip
          L8_2 = L9_2.name
      end
      else
        L9_2 = L7_2.shopConfig
        L9_2 = L9_2.name
        if L9_2 then
          L9_2 = L7_2.shopConfig
          L8_2 = L9_2.name
        end
      end
    end
  end
  L9_2 = SendNUIMessage
  L10_2 = {}
  L10_2.action = "updateVehicleConnection"
  L10_2.isConnected = L5_2
  L10_2.vehicleData = L6_2
  L10_2.shopName = L8_2
  L9_2(L10_2)
  L9_2 = nil
  if L5_2 then
    L10_2 = GetVehiclePedIsIn
    L11_2 = PlayerPedId
    L11_2 = L11_2()
    L12_2 = false
    L10_2 = L10_2(L11_2, L12_2)
    L11_2 = GetVehicleNumberPlateText
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    L9_2 = L11_2
  end
  L10_2 = TriggerServerEvent
  L11_2 = "qs-mechanic-creator:server:requestTabletData"
  L12_2 = L1_1
  L13_2 = nil
  L10_2(L11_2, L12_2, L13_2)
end
function L14_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L0_1 = L0_2
  L0_2 = nil
  L1_1 = L0_2
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "closeTablet"
  L0_2(L1_2)
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = L11_1
  L0_2()
end
L15_1 = AddEventHandler
L16_1 = "onResourceStop"
function L17_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = L11_1
    L1_2()
  end
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNetEvent
L16_1 = "qs-mechanic-creator:client:updateTabletData"
function L17_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = A0_2.shopId
  if L1_2 then
    L2_2 = L1_1
    if L2_2 then
      L2_2 = L1_1
      if L1_2 ~= L2_2 then
        return
      end
    end
  end
  L3_1.dataReceived = true
  L2_2 = A0_2.employees
  if L2_2 then
    L2_2 = A0_2.employees
    L2_2 = L2_2[1]
    if not L2_2 then
      L2_2 = {}
      L3_2 = pairs
      L4_2 = A0_2.employees
      L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
      for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
        L9_2 = type
        L10_2 = L8_2
        L9_2 = L9_2(L10_2)
        if "table" == L9_2 then
          L9_2 = table
          L9_2 = L9_2.insert
          L10_2 = L2_2
          L11_2 = L8_2
          L9_2(L10_2, L11_2)
        end
      end
      A0_2.employees = L2_2
    end
  end
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "updateTabletData"
  L3_2.data = A0_2
  L2_2(L3_2)
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNetEvent
L16_1 = "qs-mechanic-creator:client:openTablet"
function L17_1()
  local L0_2, L1_2
  L0_2 = L13_1
  L0_2()
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNetEvent
L16_1 = "qs-mechanic-creator:client:closeTablet"
function L17_1()
  local L0_2, L1_2
  L0_2 = L14_1
  L0_2()
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNetEvent
L16_1 = "qs-mechanic-creator:client:refreshTabletOrders"
function L17_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = L1_1
  if L1_2 then
    L1_2 = L1_1
    if L1_2 == A0_2 then
      L1_2 = nil
      L2_2 = L12_1
      L2_2 = L2_2()
      if L2_2 then
        L2_2 = GetVehiclePedIsIn
        L3_2 = PlayerPedId
        L3_2 = L3_2()
        L4_2 = false
        L2_2 = L2_2(L3_2, L4_2)
        L3_2 = GetVehicleNumberPlateText
        L4_2 = L2_2
        L3_2 = L3_2(L4_2)
        L1_2 = L3_2
      end
      L2_2 = TriggerServerEvent
      L3_2 = "qs-mechanic-creator:server:requestTabletData"
      L4_2 = L1_1
      L5_2 = L1_2
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNetEvent
L16_1 = "qs-mechanic-creator:client:requestHireConfirmation"
function L17_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = lib
  L5_2 = L5_2.alertDialog
  L6_2 = {}
  L6_2.header = "Job Offer"
  L7_2 = "You have received a job offer from "
  L8_2 = A2_2
  L9_2 = " as a "
  L10_2 = A1_2
  L11_2 = " (Grade "
  L12_2 = A3_2
  L13_2 = "). Do you want to accept this position?"
  L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
  L6_2.content = L7_2
  L6_2.centered = true
  L6_2.cancel = true
  L5_2 = L5_2(L6_2)
  if "confirm" == L5_2 then
    L6_2 = TriggerServerEvent
    L7_2 = "qs-mechanic-creator:server:hireConfirmationResponse"
    L8_2 = true
    L9_2 = A0_2
    L10_2 = A4_2
    L11_2 = A1_2
    L12_2 = A3_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  else
    L6_2 = TriggerServerEvent
    L7_2 = "qs-mechanic-creator:server:hireConfirmationResponse"
    L8_2 = false
    L9_2 = A0_2
    L10_2 = A4_2
    L11_2 = A1_2
    L12_2 = A3_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  end
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "closeTablet"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L14_1
  L2_2()
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "loadTabletData"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No shop ID available"
    L2_2(L3_2)
    return
  end
  L2_2 = nil
  L3_2 = L12_1
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = GetVehiclePedIsIn
    L4_2 = PlayerPedId
    L4_2 = L4_2()
    L5_2 = false
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = GetVehicleNumberPlateText
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    L2_2 = L4_2
  end
  L3_2 = TriggerServerEvent
  L4_2 = "qs-mechanic-creator:server:requestTabletData"
  L5_2 = L1_1
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = A1_2
  L4_2 = {}
  L4_2.success = true
  L3_2(L4_2)
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "hireEmployee"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No shop selected"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.targetId
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No target player specified"
    L2_2(L3_2)
    return
  end
  L2_2 = tonumber
  L3_2 = A0_2.grade
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = 0
  end
  L3_2 = 0
  if L2_2 >= 4 then
    L3_2 = 2
  elseif L2_2 >= 1 then
    L3_2 = 1
  end
  L4_2 = TriggerServerEvent
  L5_2 = "qs-mechanic-creator:server:hireEmployee"
  L6_2 = L1_1
  L7_2 = A0_2.targetId
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A1_2
  L5_2 = {}
  L5_2.success = true
  L4_2(L5_2)
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "checkVehicleNearby"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  if A0_2 then
    L2_2 = A0_2.vehiclePlate
    if L2_2 then
      goto lbl_12
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.found = false
  L2_2(L3_2)
  do return end
  ::lbl_12::
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = GetEntityCoords
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = 10.0
  L5_2 = GetGamePool
  L6_2 = "CVehicle"
  L5_2 = L5_2(L6_2)
  L6_2 = ipairs
  L7_2 = L5_2
  L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2)
  for L10_2, L11_2 in L6_2, L7_2, L8_2, L9_2 do
    L12_2 = DoesEntityExist
    L13_2 = L11_2
    L12_2 = L12_2(L13_2)
    if L12_2 then
      L12_2 = GetVehicleNumberPlateText
      L13_2 = L11_2
      L12_2 = L12_2(L13_2)
      if L12_2 then
        L13_2 = string
        L13_2 = L13_2.gsub
        L14_2 = L12_2
        L15_2 = "%s+"
        L16_2 = ""
        L13_2 = L13_2(L14_2, L15_2, L16_2)
        L14_2 = string
        L14_2 = L14_2.gsub
        L15_2 = A0_2.vehiclePlate
        L16_2 = "%s+"
        L17_2 = ""
        L14_2 = L14_2(L15_2, L16_2, L17_2)
        if L13_2 == L14_2 then
          L15_2 = GetEntityCoords
          L16_2 = L11_2
          L15_2 = L15_2(L16_2)
          L16_2 = L3_2 - L15_2
          L16_2 = #L16_2
          if L4_2 >= L16_2 then
            L17_2 = A1_2
            L18_2 = {}
            L18_2.found = true
            L19_2 = VehToNet
            L20_2 = L11_2
            L19_2 = L19_2(L20_2)
            L18_2.vehicle = L19_2
            L18_2.plate = L12_2
            L18_2.distance = L16_2
            L17_2(L18_2)
            return
          end
        end
      end
    end
  end
  L6_2 = A1_2
  L7_2 = {}
  L7_2.found = false
  L6_2(L7_2)
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "getOrderModifications"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.orderId
    if L2_2 then
      goto lbl_13
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.message = "No order ID provided"
  L2_2(L3_2)
  do return end
  ::lbl_13::
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "qs-mechanic-creator:server:getOrderModifications"
  L4_2 = false
  L5_2 = A0_2.orderId
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if L2_2 then
    L3_2 = A1_2
    L4_2 = L2_2
    L3_2(L4_2)
  else
    L3_2 = A1_2
    L4_2 = {}
    L4_2.success = false
    L4_2.message = "Failed to fetch order data"
    L3_2(L4_2)
  end
end
L15_1(L16_1, L17_1)
L15_1 = RegisterNUICallback
L16_1 = "startInstallation"
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = A0_2.orderId
    if L2_2 then
      L2_2 = A0_2.vehicleNetId
      if L2_2 then
        goto lbl_16
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.message = "Missing required data"
  L2_2(L3_2)
  do return end
  ::lbl_16::
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "qs-mechanic-creator:server:startInstallation"
  L4_2 = false
  L5_2 = A0_2.orderId
  L6_2 = A0_2.vehicleNetId
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2)
  if L2_2 then
    L3_2 = L2_2.success
    if L3_2 then
      L3_2 = SendNUIMessage
      L4_2 = {}
      L4_2.action = "showInstallProgress"
      L5_2 = L2_2.order
      L4_2.order = L5_2
      L3_2(L4_2)
      L3_2 = TriggerEvent
      L4_2 = "qs-mechanic-creator:client:startInstallation"
      L5_2 = L2_2.order
      L3_2(L4_2, L5_2)
      L3_2 = A1_2
      L4_2 = {}
      L4_2.success = true
      L3_2(L4_2)
  end
  else
    L3_2 = A1_2
    L4_2 = {}
    L4_2.success = false
    L5_2 = L2_2.message
    if not L5_2 then
      L5_2 = "Failed to start installation"
    end
    L4_2.message = L5_2
    L3_2(L4_2)
  end
end
L15_1(L16_1, L17_1)
L15_1 = false
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L1_2 = GetVehicleHandlingFloat
  L2_2 = A0_2
  L3_2 = "CHandlingData"
  L4_2 = "fMass"
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = GetVehicleHandlingFloat
  L3_2 = A0_2
  L4_2 = "CHandlingData"
  L5_2 = "fInitialDriveForce"
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = GetVehicleHandlingFloat
  L4_2 = A0_2
  L5_2 = "CHandlingData"
  L6_2 = "fDriveBiasFront"
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = GetVehicleHandlingFloat
  L5_2 = A0_2
  L6_2 = "CHandlingData"
  L7_2 = "fDriveInertia"
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = GetVehicleHandlingFloat
  L6_2 = A0_2
  L7_2 = "CHandlingData"
  L8_2 = "fClutchChangeRateScaleUpShift"
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L6_2 = GetVehicleHandlingInt
  L7_2 = A0_2
  L8_2 = "CHandlingData"
  L9_2 = "nInitialDriveGears"
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L7_2 = GetVehicleHandlingFloat
  L8_2 = A0_2
  L9_2 = "CHandlingData"
  L10_2 = "fBrakeBiasFront"
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = GetVehicleHandlingFloat
  L9_2 = A0_2
  L10_2 = "CHandlingData"
  L11_2 = "fHandBrakeForce"
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = GetVehicleHandlingFloat
  L10_2 = A0_2
  L11_2 = "CHandlingData"
  L12_2 = "fSteeringLock"
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  L10_2 = GetVehicleHandlingFloat
  L11_2 = A0_2
  L12_2 = "CHandlingData"
  L13_2 = "fTractionCurveMax"
  L10_2 = L10_2(L11_2, L12_2, L13_2)
  L11_2 = GetVehicleHandlingFloat
  L12_2 = A0_2
  L13_2 = "CHandlingData"
  L14_2 = "fTractionCurveMin"
  L11_2 = L11_2(L12_2, L13_2, L14_2)
  L12_2 = GetVehicleHandlingFloat
  L13_2 = A0_2
  L14_2 = "CHandlingData"
  L15_2 = "fSuspensionForce"
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  L13_2 = GetVehicleHandlingFloat
  L14_2 = A0_2
  L15_2 = "CHandlingData"
  L16_2 = "fSuspensionCompDamp"
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L14_2 = GetVehicleHandlingFloat
  L15_2 = A0_2
  L16_2 = "CHandlingData"
  L17_2 = "fSuspensionReboundDamp"
  L14_2 = L14_2(L15_2, L16_2, L17_2)
  L15_2 = GetVehicleHandlingFloat
  L16_2 = A0_2
  L17_2 = "CHandlingData"
  L18_2 = "fCollisionDamageMult"
  L15_2 = L15_2(L16_2, L17_2, L18_2)
  L16_2 = GetVehicleMod
  L17_2 = A0_2
  L18_2 = 11
  L16_2 = L16_2(L17_2, L18_2)
  L17_2 = IsToggleModOn
  L18_2 = A0_2
  L19_2 = 18
  L17_2 = L17_2(L18_2, L19_2)
  L18_2 = GetVehicleMod
  L19_2 = A0_2
  L20_2 = 13
  L18_2 = L18_2(L19_2, L20_2)
  L19_2 = GetVehicleMod
  L20_2 = A0_2
  L21_2 = 15
  L19_2 = L19_2(L20_2, L21_2)
  L20_2 = GetVehicleMod
  L21_2 = A0_2
  L22_2 = 16
  L20_2 = L20_2(L21_2, L22_2)
  L21_2 = GetVehicleMod
  L22_2 = A0_2
  L23_2 = 12
  L21_2 = L21_2(L22_2, L23_2)
  L22_2 = L16_2 * 0.15
  L22_2 = 1.0 + L22_2
  if L17_2 then
    L23_2 = 1.3
    if L23_2 then
      goto lbl_110
    end
  end
  L23_2 = 1.0
  ::lbl_110::
  L24_2 = L18_2 * 0.05
  L24_2 = 1.0 + L24_2
  L25_2 = L2_2 * L22_2
  L25_2 = L25_2 * L23_2
  L25_2 = L25_2 * L24_2
  L26_2 = {}
  L26_2.mass = L1_2
  L26_2.driveForce = L25_2
  L26_2.baseDriveForce = L2_2
  L26_2.driveBiasFront = L3_2
  L26_2.driveInertia = L4_2
  L26_2.clutchChangeRate = L5_2
  L26_2.gears = L6_2
  L26_2.brakeBiasFront = L7_2
  L26_2.handBrakeForce = L8_2
  L26_2.steeringLock = L9_2
  L26_2.tractionMax = L10_2
  L26_2.tractionMin = L11_2
  L26_2.suspensionForce = L12_2
  L26_2.suspensionCompDamp = L13_2
  L26_2.suspensionReboundDamp = L14_2
  L26_2.collisionDamageMult = L15_2
  L26_2.engineMod = L16_2
  L26_2.turboMod = L17_2
  L26_2.transmissionMod = L18_2
  L26_2.suspensionMod = L19_2
  L26_2.armorMod = L20_2
  L26_2.brakeMod = L21_2
  L26_2.engineMultiplier = L22_2
  L26_2.turboMultiplier = L23_2
  L26_2.transMultiplier = L24_2
  return L26_2
end
function L17_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = 0.4
  L4_2 = 3.5
  L5_2 = 7.04
  L6_2 = A0_2.driveForce
  L7_2 = A0_2.mass
  L6_2 = L6_2 * L7_2
  L6_2 = L6_2 * L3_2
  L6_2 = L6_2 * L5_2
  L6_2 = L6_2 / L4_2
  L7_2 = nil
  L8_2 = A0_2.turboMod
  if L8_2 then
    L7_2 = 0.55
  elseif 7 == A2_2 or 6 == A2_2 then
    L7_2 = 0.6
  elseif 18 == A2_2 then
    L7_2 = 0.0
  else
    L7_2 = 0.5
  end
  L8_2 = nil
  if 18 == A2_2 then
    L9_2 = 0.15 * A1_2
    L10_2 = 1.0
    L8_2 = L10_2 - L9_2
  elseif A1_2 < L7_2 then
    L9_2 = A1_2 / L7_2
    L10_2 = A0_2.turboMod
    if L10_2 then
      L10_2 = math
      L10_2 = L10_2.pow
      L11_2 = L9_2
      L12_2 = 1.2
      L10_2 = L10_2(L11_2, L12_2)
      L10_2 = 0.5 * L10_2
      L8_2 = 0.5 + L10_2
    else
      L10_2 = math
      L10_2 = L10_2.pow
      L11_2 = L9_2
      L12_2 = 1.5
      L10_2 = L10_2(L11_2, L12_2)
      L10_2 = 0.5 * L10_2
      L8_2 = 0.5 + L10_2
    end
  else
    L9_2 = A1_2 - L7_2
    L10_2 = 1.0
    L10_2 = L10_2 - L7_2
    L9_2 = L9_2 / L10_2
    L10_2 = A0_2.turboMod
    if L10_2 then
      L10_2 = math
      L10_2 = L10_2.pow
      L11_2 = L9_2
      L12_2 = 0.8
      L10_2 = L10_2(L11_2, L12_2)
      L10_2 = 0.2 * L10_2
      L11_2 = 1.0
      L8_2 = L11_2 - L10_2
    else
      L10_2 = math
      L10_2 = L10_2.pow
      L11_2 = L9_2
      L12_2 = 0.9
      L10_2 = L10_2(L11_2, L12_2)
      L10_2 = 0.3 * L10_2
      L11_2 = 1.0
      L8_2 = L11_2 - L10_2
    end
  end
  L9_2 = L6_2 * L8_2
  L10_2 = L7_2
  return L9_2, L10_2
end
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = 8000
  L3_2 = A1_2 * L2_2
  L4_2 = A0_2 * L3_2
  L4_2 = L4_2 / 5252
  return L4_2
end
function L19_1(A0_2)
  local L1_2, L2_2
  L1_2 = {}
  L1_2[0] = "Compacts"
  L1_2[1] = "Sedans"
  L1_2[2] = "SUVs"
  L1_2[3] = "Coupes"
  L1_2[4] = "Muscle"
  L1_2[5] = "Sports Classics"
  L1_2[6] = "Sports"
  L1_2[7] = "Super"
  L1_2[8] = "Motorcycles"
  L1_2[9] = "Off-road"
  L1_2[10] = "Industrial"
  L1_2[11] = "Utility"
  L1_2[12] = "Vans"
  L1_2[13] = "Cycles"
  L1_2[14] = "Boats"
  L1_2[15] = "Helicopters"
  L1_2[16] = "Planes"
  L1_2[17] = "Service"
  L1_2[18] = "Emergency"
  L1_2[19] = "Military"
  L1_2[20] = "Commercial"
  L1_2[21] = "Trains"
  L1_2[22] = "Open Wheel"
  L2_2 = L1_2[A0_2]
  if not L2_2 then
    L2_2 = "Unknown"
  end
  return L2_2
end
function L20_1(A0_2)
  local L1_2
  if 1.0 == A0_2 then
    L1_2 = "FWD (Front-Wheel Drive)"
    return L1_2
  elseif 0.0 == A0_2 then
    L1_2 = "RWD (Rear-Wheel Drive)"
    return L1_2
  else
    L1_2 = "AWD (All-Wheel Drive)"
    return L1_2
  end
end
function L21_1(A0_2)
  local L1_2, L2_2
  L1_2 = L15_1
  if L1_2 then
    return
  end
  L1_2 = true
  L15_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3, L21_3, L22_3, L23_3, L24_3, L25_3, L26_3, L27_3, L28_3, L29_3, L30_3, L31_3, L32_3, L33_3
    L0_3 = PlayerPedId
    L0_3 = L0_3()
    L1_3 = FreezeEntityPosition
    L2_3 = A0_2
    L3_3 = true
    L1_3(L2_3, L3_3)
    L1_3 = SetVehicleEngineOn
    L2_3 = A0_2
    L3_3 = true
    L4_3 = true
    L5_3 = false
    L1_3(L2_3, L3_3, L4_3, L5_3)
    L1_3 = SetVehicleForwardSpeed
    L2_3 = A0_2
    L3_3 = 0.0
    L1_3(L2_3, L3_3)
    L1_3 = SetEntityCollision
    L2_3 = A0_2
    L3_3 = false
    L4_3 = false
    L1_3(L2_3, L3_3, L4_3)
    L1_3 = GetEntityModel
    L2_3 = A0_2
    L1_3 = L1_3(L2_3)
    L2_3 = GetDisplayNameFromVehicleModel
    L3_3 = L1_3
    L2_3 = L2_3(L3_3)
    L3_3 = GetVehicleClass
    L4_3 = A0_2
    L3_3 = L3_3(L4_3)
    L4_3 = L19_1
    L5_3 = L3_3
    L4_3 = L4_3(L5_3)
    L5_3 = L1_3
    L6_3 = GetVehicleNumberPlateText
    L7_3 = A0_2
    L6_3 = L6_3(L7_3)
    L7_3 = L16_1
    L8_3 = A0_2
    L7_3 = L7_3(L8_3)
    L8_3 = 8000
    L9_3 = 25
    L10_3 = 80
    L11_3 = 0
    L12_3 = 0
    L13_3 = 0
    L14_3 = 0
    L15_3 = {}
    L16_3 = GetGameTimer
    L16_3 = L16_3()
    L17_3 = 0
    L18_3 = L9_3 - 1
    L19_3 = 1
    for L20_3 = L17_3, L18_3, L19_3 do
      L21_3 = L9_3 - 1
      L21_3 = L20_3 / L21_3
      L22_3 = math
      L22_3 = L22_3.floor
      L23_3 = L21_3 * L8_3
      L22_3 = L22_3(L23_3)
      L23_3 = SetVehicleCurrentRpm
      L24_3 = A0_2
      L25_3 = L21_3
      L23_3(L24_3, L25_3)
      L23_3 = SetVehicleForwardSpeed
      L24_3 = A0_2
      L25_3 = 0.0
      L23_3(L24_3, L25_3)
      L23_3 = L17_1
      L24_3 = L7_3
      L25_3 = L21_3
      L26_3 = L3_3
      L23_3, L24_3 = L23_3(L24_3, L25_3, L26_3)
      L25_3 = L18_1
      L26_3 = L23_3
      L27_3 = L21_3
      L25_3 = L25_3(L26_3, L27_3)
      if L11_3 < L25_3 then
        L11_3 = L25_3
        L12_3 = L22_3
      end
      if L13_3 < L23_3 then
        L13_3 = L23_3
        L14_3 = L22_3
      end
      L26_3 = table
      L26_3 = L26_3.insert
      L27_3 = L15_3
      L28_3 = {}
      L28_3.rpm = L22_3
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L25_3
      L29_3 = L29_3(L30_3)
      L28_3.hp = L29_3
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L23_3
      L29_3 = L29_3(L30_3)
      L28_3.torque = L29_3
      L26_3(L27_3, L28_3)
      L26_3 = SendNUIMessage
      L27_3 = {}
      L27_3.action = "updateDynoData"
      L28_3 = {}
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L25_3
      L29_3 = L29_3(L30_3)
      L28_3.currentHP = L29_3
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L23_3
      L29_3 = L29_3(L30_3)
      L28_3.currentTorque = L29_3
      L28_3.currentRPM = L22_3
      L29_3 = L9_3 - 1
      L29_3 = L20_3 / L29_3
      L29_3 = L29_3 * 100
      L28_3.progress = L29_3
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L11_3
      L29_3 = L29_3(L30_3)
      L28_3.peakHP = L29_3
      L29_3 = math
      L29_3 = L29_3.floor
      L30_3 = L13_3
      L29_3 = L29_3(L30_3)
      L28_3.peakTorque = L29_3
      L27_3.data = L28_3
      L26_3(L27_3)
      L26_3 = Wait
      L27_3 = L10_3
      L26_3(L27_3)
    end
    L17_3 = GetGameTimer
    L17_3 = L17_3()
    L17_3 = L17_3 - L16_3
    L17_3 = L17_3 / 1000
    L18_3 = Wait
    L19_3 = 500
    L18_3(L19_3)
    L18_3 = GetVehicleEstimatedMaxSpeed
    L19_3 = A0_2
    L18_3 = L18_3(L19_3)
    L19_3 = math
    L19_3 = L19_3.floor
    L20_3 = L18_3 * 2.23694
    L19_3 = L19_3(L20_3)
    L20_3 = math
    L20_3 = L20_3.floor
    L21_3 = L18_3 * 3.6
    L20_3 = L20_3(L21_3)
    L21_3 = L7_3.mass
    L22_3 = L21_3 * 2.20462
    L23_3 = L22_3 / 1000
    L23_3 = L11_3 / L23_3
    L24_3 = math
    L24_3 = L24_3.max
    L25_3 = 2.0
    L26_3 = math
    L26_3 = L26_3.min
    L27_3 = 15.0
    L28_3 = L23_3 * 0.8
    L29_3 = 18.0
    L28_3 = L29_3 - L28_3
    L26_3, L27_3, L28_3, L29_3, L30_3, L31_3, L32_3, L33_3 = L26_3(L27_3, L28_3)
    L24_3 = L24_3(L25_3, L26_3, L27_3, L28_3, L29_3, L30_3, L31_3, L32_3, L33_3)
    L25_3 = L24_3 * 1.1
    L26_3 = L20_1
    L27_3 = L7_3.driveBiasFront
    L26_3 = L26_3(L27_3)
    L27_3 = GetVehicleNumberOfWheels
    L28_3 = A0_2
    L27_3 = L27_3(L28_3)
    L28_3 = {}
    L29_3 = string
    L29_3 = L29_3.format
    L30_3 = "%.2fs"
    L31_3 = L17_3
    L29_3 = L29_3(L30_3, L31_3)
    L28_3.testDuration = L29_3
    L28_3.vehicleName = L2_3
    L28_3.vehicleHash = L5_3
    L28_3.vehiclePlate = L6_3
    L28_3.vehicleClass = L3_3
    L28_3.vehicleClassName = L4_3
    L29_3 = math
    L29_3 = L29_3.floor
    L30_3 = L11_3
    L29_3 = L29_3(L30_3)
    L28_3.peakHP = L29_3
    L29_3 = math
    L29_3 = L29_3.floor
    L30_3 = L13_3
    L29_3 = L29_3(L30_3)
    L28_3.peakTorque = L29_3
    L28_3.peakHPRPM = L12_3
    L28_3.peakTorqueRPM = L14_3
    L28_3.topSpeedMPH = L19_3
    L28_3.topSpeedKMH = L20_3
    L29_3 = string
    L29_3 = L29_3.format
    L30_3 = "%.2fs"
    L31_3 = L24_3
    L29_3 = L29_3(L30_3, L31_3)
    L28_3.acceleration060MPH = L29_3
    L29_3 = string
    L29_3 = L29_3.format
    L30_3 = "%.2fs"
    L31_3 = L25_3
    L29_3 = L29_3(L30_3, L31_3)
    L28_3.acceleration0100KMH = L29_3
    L29_3 = string
    L29_3 = L29_3.format
    L30_3 = "%.2f HP/1000lbs"
    L31_3 = L23_3
    L29_3 = L29_3(L30_3, L31_3)
    L28_3.powerToWeightRatio = L29_3
    L29_3 = {}
    L29_3.idleRPM = 0
    L29_3.redlineRPM = L8_3
    L30_3 = L7_3.turboMod
    L29_3.hasTurbo = L30_3
    L30_3 = L7_3.engineMod
    L29_3.engineUpgrade = L30_3
    L30_3 = L7_3.transmissionMod
    L29_3.transmissionUpgrade = L30_3
    L28_3.engineSpecs = L29_3
    L29_3 = {}
    L29_3.type = L26_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2f"
    L32_3 = L7_3.driveBiasFront
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.driveBiasFront = L30_3
    L30_3 = math
    L30_3 = L30_3.floor
    L31_3 = L21_3
    L30_3 = L30_3(L31_3)
    L29_3.weightKG = L30_3
    L30_3 = math
    L30_3 = L30_3.floor
    L31_3 = L22_3
    L30_3 = L30_3(L31_3)
    L29_3.weightLBS = L30_3
    L29_3.wheelCount = L27_3
    L30_3 = L7_3.gears
    L29_3.gearCount = L30_3
    L28_3.drivetrain = L29_3
    L29_3 = {}
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.driveForce
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.driveForce = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.baseDriveForce
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.baseDriveForce = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.driveInertia
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.driveInertia = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.clutchChangeRate
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.clutchChangeRate = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.tractionMax
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.tractionMax = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.tractionMin
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.tractionMin = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2f"
    L32_3 = L7_3.steeringLock
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.steeringLock = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2f"
    L32_3 = L7_3.brakeBiasFront
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.brakeBiasFront = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.handBrakeForce
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.handBrakeForce = L30_3
    L28_3.handling = L29_3
    L29_3 = {}
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.suspensionForce
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.force = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.suspensionCompDamp
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.compDamp = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.4f"
    L32_3 = L7_3.suspensionReboundDamp
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.reboundDamp = L30_3
    L30_3 = L7_3.suspensionMod
    L29_3.suspensionUpgrade = L30_3
    L28_3.suspension = L29_3
    L29_3 = {}
    L30_3 = L7_3.engineMod
    if L30_3 >= 0 then
      L30_3 = L7_3.engineMod
      L30_3 = L30_3 + 1
      if L30_3 then
        goto lbl_368
      end
    end
    L30_3 = 0
    ::lbl_368::
    L29_3.engine = L30_3
    L30_3 = L7_3.transmissionMod
    if L30_3 >= 0 then
      L30_3 = L7_3.transmissionMod
      L30_3 = L30_3 + 1
      if L30_3 then
        goto lbl_378
      end
    end
    L30_3 = 0
    ::lbl_378::
    L29_3.transmission = L30_3
    L30_3 = L7_3.brakeMod
    if L30_3 >= 0 then
      L30_3 = L7_3.brakeMod
      L30_3 = L30_3 + 1
      if L30_3 then
        goto lbl_388
      end
    end
    L30_3 = 0
    ::lbl_388::
    L29_3.brakes = L30_3
    L30_3 = L7_3.suspensionMod
    if L30_3 >= 0 then
      L30_3 = L7_3.suspensionMod
      L30_3 = L30_3 + 1
      if L30_3 then
        goto lbl_398
      end
    end
    L30_3 = 0
    ::lbl_398::
    L29_3.suspension = L30_3
    L30_3 = L7_3.armorMod
    if L30_3 >= 0 then
      L30_3 = L7_3.armorMod
      L30_3 = L30_3 + 1
      if L30_3 then
        goto lbl_408
      end
    end
    L30_3 = 0
    ::lbl_408::
    L29_3.armor = L30_3
    L30_3 = L7_3.turboMod
    L29_3.turbo = L30_3
    L28_3.upgrades = L29_3
    L29_3 = {}
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2fx"
    L32_3 = L7_3.engineMultiplier
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.engine = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2fx"
    L32_3 = L7_3.turboMultiplier
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.turbo = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2fx"
    L32_3 = L7_3.transMultiplier
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.transmission = L30_3
    L30_3 = string
    L30_3 = L30_3.format
    L31_3 = "%.2fx"
    L32_3 = L7_3.engineMultiplier
    L33_3 = L7_3.turboMultiplier
    L32_3 = L32_3 * L33_3
    L33_3 = L7_3.transMultiplier
    L32_3 = L32_3 * L33_3
    L30_3 = L30_3(L31_3, L32_3)
    L29_3.total = L30_3
    L28_3.multipliers = L29_3
    L28_3.curveData = L15_3
    L29_3 = SendNUIMessage
    L30_3 = {}
    L30_3.action = "dynoTestComplete"
    L30_3.results = L28_3
    L29_3(L30_3)
    L29_3 = Wait
    L30_3 = 1000
    L29_3(L30_3)
    L29_3 = SetVehicleCurrentRpm
    L30_3 = A0_2
    L31_3 = 0.0
    L29_3(L30_3, L31_3)
    L29_3 = SetVehicleForwardSpeed
    L30_3 = A0_2
    L31_3 = 0.0
    L29_3(L30_3, L31_3)
    L29_3 = SetEntityCollision
    L30_3 = A0_2
    L31_3 = true
    L32_3 = true
    L29_3(L30_3, L31_3, L32_3)
    L29_3 = FreezeEntityPosition
    L30_3 = A0_2
    L31_3 = false
    L29_3(L30_3, L31_3)
    L29_3 = false
    L15_1 = L29_3
  end
  L1_2(L2_2)
end
L22_1 = RegisterNUICallback
L23_1 = "runDynoTest"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L12_1
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L3_2.title = "Dyno"
    L3_2.description = "You must be in a vehicle to run a dyno test"
    L3_2.type = "error"
    L2_2(L3_2)
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L2_2(L3_2)
    return
  end
  L2_2 = L15_1
  if L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L3_2.title = "Dyno"
    L3_2.description = "A test is already in progress"
    L3_2.type = "error"
    L2_2(L3_2)
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L2_2(L3_2)
    return
  end
  L2_2 = GetVehiclePedIsIn
  L3_2 = PlayerPedId
  L3_2 = L3_2()
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L21_1
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = A1_2
  L4_2 = {}
  L4_2.success = true
  L3_2(L4_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "installNitrous"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L12_1
  L2_2 = L2_2()
  if not L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L3_2.title = "Nitrous"
    L3_2.description = "You must be in a vehicle to install nitrous"
    L3_2.type = "error"
    L2_2(L3_2)
    L2_2 = A1_2
    L3_2 = "ok"
    L2_2(L3_2)
    return
  end
  L2_2 = GetVehiclePedIsIn
  L3_2 = PlayerPedId
  L3_2 = L3_2()
  L4_2 = false
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = TriggerServerEvent
  L4_2 = "qs-mechanic-creator:server:installNitrous"
  L5_2 = L1_1
  L6_2 = VehToNet
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  L7_2 = A0_2.kit
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = A1_2
  L4_2 = "ok"
  L3_2(L4_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "fireEmployee"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No shop selected"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.employeeId
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No employee ID specified"
    L2_2(L3_2)
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:fireEmployee"
  L4_2 = L1_1
  L5_2 = A0_2.employeeId
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = true
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "editEmployee"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No shop selected"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.employeeId
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No employee ID specified"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.grade
  if not L2_2 then
    L2_2 = A0_2.grade
    if 0 ~= L2_2 then
      L2_2 = A1_2
      L3_2 = {}
      L3_2.success = false
      L3_2.message = "No grade specified"
      L2_2(L3_2)
      return
    end
  end
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:editEmployee"
  L4_2 = L1_1
  L5_2 = A0_2.employeeId
  L6_2 = A0_2.grade
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = true
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "saveSettings"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:saveTabletSettings"
  L4_2 = L1_1
  L5_2 = A0_2
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "toggleDuty"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = toggleDuty
  if L2_2 then
    L2_2 = type
    L3_2 = toggleDuty
    L2_2 = L2_2(L3_2)
    if "function" == L2_2 then
      L2_2 = toggleDuty
      L2_2 = L2_2()
      if L2_2 then
        L3_2 = Wait
        L4_2 = 500
        L3_2(L4_2)
        L3_2 = false
        L4_2 = isPlayerOnDuty
        if L4_2 then
          L4_2 = type
          L5_2 = isPlayerOnDuty
          L4_2 = L4_2(L5_2)
          if "function" == L4_2 then
            L4_2 = isPlayerOnDuty
            L4_2 = L4_2()
            L3_2 = L4_2
          end
        end
        L4_2 = SendNUIMessage
        L5_2 = {}
        L5_2.action = "updateDutyStatus"
        L5_2.onDuty = L3_2
        L4_2(L5_2)
        L4_2 = A1_2
        L5_2 = {}
        L5_2.success = true
        L5_2.onDuty = L3_2
        L4_2(L5_2)
      else
        L3_2 = A1_2
        L4_2 = {}
        L4_2.success = false
        L3_2(L4_2)
      end
  end
  else
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L2_2(L3_2)
  end
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "tabletFocus"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SetNuiFocus
  L3_2 = A0_2.focus
  L4_2 = A0_2.focus
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "checkVehicle"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = L12_1
  L2_2 = L2_2()
  L3_2 = nil
  L4_2 = nil
  if L2_2 then
    L5_2 = GetVehiclePedIsIn
    L6_2 = PlayerPedId
    L6_2 = L6_2()
    L7_2 = false
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = GetEntityModel
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = GetDisplayNameFromVehicleModel
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = GetVehicleNumberPlateText
    L9_2 = L5_2
    L8_2 = L8_2(L9_2)
    L4_2 = L8_2
    L8_2 = {}
    L8_2.name = L7_2
    L9_2 = _U
    L10_2 = "TABLET_READY_FOR_DIAGNOSTIC"
    L9_2 = L9_2(L10_2)
    L8_2.details = L9_2
    L8_2.plate = L4_2
    L3_2 = L8_2
  end
  L5_2 = SendNUIMessage
  L6_2 = {}
  L6_2.action = "updateVehicleConnection"
  L6_2.isConnected = L2_2
  L6_2.vehicleData = L3_2
  L5_2(L6_2)
  L5_2 = L1_1
  if L5_2 then
    L5_2 = TriggerServerEvent
    L6_2 = "qs-mechanic-creator:server:requestTabletData"
    L7_2 = L1_1
    L8_2 = L4_2
    L5_2(L6_2, L7_2, L8_2)
  end
  L5_2 = A1_2
  L6_2 = "ok"
  L5_2(L6_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "refundOrder"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No shop selected"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.orderId
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.message = "No order ID specified"
    L2_2(L3_2)
    return
  end
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:refundOrder"
  L4_2 = A0_2.orderId
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = true
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "sendOrderInvoice"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = L1_1
  if L2_2 and A0_2 then
    L2_2 = type
    L3_2 = A0_2.orderId
    L2_2 = L2_2(L3_2)
    if "number" == L2_2 then
      goto lbl_18
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.message = "Invalid request"
  L2_2(L3_2)
  do return end
  ::lbl_18::
  L2_2 = A0_2.targetPlayerSrc
  if L2_2 then
    L2_2 = tonumber
    L3_2 = A0_2.targetPlayerSrc
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_27
    end
  end
  L2_2 = nil
  ::lbl_27::
  L3_2 = lib
  L3_2 = L3_2.callback
  L4_2 = "qs-mechanic-creator:server:sendOrderInvoice"
  L5_2 = false
  function L6_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3
    L2_3 = A1_2
    L3_3 = {}
    L4_3 = true == A0_3
    L3_3.success = L4_3
    L3_3.message = A1_3
    L2_3(L3_3)
  end
  L7_2 = A0_2.orderId
  L8_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "getNearbyPlayers"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 then
    L2_2 = tonumber
    L3_2 = A0_2.radius
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_9
    end
  end
  L2_2 = 10.0
  ::lbl_9::
  L3_2 = lib
  L3_2 = L3_2.callback
  L4_2 = "qs-mechanic-creator:server:getNearbyPlayers"
  L5_2 = false
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3
    L1_3 = A1_2
    L2_3 = {}
    L3_3 = A0_3 or L3_3
    if not A0_3 then
      L3_3 = {}
    end
    L2_3.players = L3_3
    L1_3(L2_3)
  end
  L7_2 = L2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "saveShopName"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.name
    if L2_2 then
      L2_2 = L1_1
      if L2_2 then
        goto lbl_13
      end
    end
  end
  L2_2 = A1_2
  L3_2 = "error"
  L2_2(L3_2)
  do return end
  ::lbl_13::
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:updateShopName"
  L4_2 = L1_1
  L5_2 = A0_2.name
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "editEmployee"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = A0_2.identifier
    if L2_2 then
      L2_2 = A0_2.grade
      if L2_2 then
        L2_2 = L1_1
        if L2_2 then
          goto lbl_16
        end
      end
    end
  end
  L2_2 = A1_2
  L3_2 = "error"
  L2_2(L3_2)
  do return end
  ::lbl_16::
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:editEmployee"
  L4_2 = L1_1
  L5_2 = A0_2.identifier
  L6_2 = A0_2.grade
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = RegisterNUICallback
L23_1 = "fireEmployee"
function L24_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.identifier
    if L2_2 then
      L2_2 = L1_1
      if L2_2 then
        goto lbl_13
      end
    end
  end
  L2_2 = A1_2
  L3_2 = "error"
  L2_2(L3_2)
  do return end
  ::lbl_13::
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:fireEmployee"
  L4_2 = L1_1
  L5_2 = A0_2.identifier
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L22_1(L23_1, L24_1)
L22_1 = nil
L23_1 = 0
L24_1 = RegisterNUICallback
L25_1 = "loadTabletData"
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = L12_1
  L2_2 = L2_2()
  L3_2 = nil
  L4_2 = GetGameTimer
  L4_2 = L4_2()
  if A0_2 then
    L5_2 = A0_2.vehiclePlate
    if L5_2 then
      L5_2 = A0_2.vehiclePlate
      if "" ~= L5_2 then
        L3_2 = A0_2.vehiclePlate
    end
  end
  elseif L2_2 then
    L5_2 = GetVehiclePedIsIn
    L6_2 = PlayerPedId
    L6_2 = L6_2()
    L7_2 = false
    L5_2 = L5_2(L6_2, L7_2)
    L6_2 = GetVehicleNumberPlateText
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L3_2 = L6_2
  end
  L5_2 = L1_1
  if L5_2 then
    L5_2 = L22_1
    L6_2 = L1_1
    if L5_2 == L6_2 then
      L5_2 = L23_1
      L5_2 = L4_2 - L5_2
      L6_2 = 2000
      if not (L5_2 > L6_2) then
        goto lbl_49
      end
    end
    L5_2 = L1_1
    L22_1 = L5_2
    L23_1 = L4_2
    L5_2 = TriggerServerEvent
    L6_2 = "qs-mechanic-creator:server:requestTabletData"
    L7_2 = L1_1
    L8_2 = L3_2
    L5_2(L6_2, L7_2, L8_2)
  else
  end
  ::lbl_49::
  L5_2 = A1_2
  L6_2 = "ok"
  L5_2(L6_2)
end
L24_1(L25_1, L26_1)
L24_1 = {}
L24_1.initialized = false
L24_1.inProgress = false
L24_1.attempts = 0
function L25_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L24_1.inProgress
  if L1_2 then
    L1_2 = false
    return L1_2
  end
  L24_1.inProgress = true
  if not A0_2 then
    A0_2 = 1
  end
  L1_2 = 10
  L2_2 = 2000
  if 1 == A0_2 then
  end
  L3_2 = getPlayerData
  L3_2 = L3_2()
  if L3_2 then
    L4_2 = playerLicense
    if L4_2 then
      L4_2 = playerJob
      if L4_2 then
        L4_2 = L9_1
        L4_2 = L4_2()
        if L4_2 then
          L1_1 = L4_2
          L5_2 = Citizen
          L5_2 = L5_2.SetTimeout
          L6_2 = 1000
          function L7_2()
            local L0_3, L1_3, L2_3
            L0_3 = L1_1
            if L0_3 then
              L0_3 = TriggerServerEvent
              L1_3 = "qs-mechanic-creator:server:requestTabletData"
              L2_3 = L1_1
              L0_3(L1_3, L2_3)
            else
            end
          end
          L5_2(L6_2, L7_2)
        else
        end
        L24_1.initialized = true
        L24_1.inProgress = false
        L5_2 = true
        return L5_2
    end
  end
  else
    if A0_2 < L1_2 then
      L4_2 = Citizen
      L4_2 = L4_2.SetTimeout
      L5_2 = L2_2
      function L6_2()
        local L0_3, L1_3
        L24_1.inProgress = false
        L0_3 = L25_1
        L1_3 = A0_2
        L1_3 = L1_3 + 1
        L0_3(L1_3)
      end
      L4_2(L5_2, L6_2)
    else
      L24_1.inProgress = false
    end
    L4_2 = false
    return L4_2
  end
end
L26_1 = AddEventHandler
L27_1 = "onResourceStart"
function L28_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L24_1.initialized = false
    L24_1.inProgress = false
    L24_1.attempts = 0
    L1_2 = Citizen
    L1_2 = L1_2.SetTimeout
    L2_2 = 5000
    function L3_2()
      local L0_3, L1_3
      L0_3 = L24_1.initialized
      if not L0_3 then
        L0_3 = L24_1.inProgress
        if not L0_3 then
          L0_3 = L25_1
          L0_3()
        end
      end
    end
    L1_2(L2_2, L3_2)
  end
end
L26_1(L27_1, L28_1)
L26_1 = RegisterNetEvent
L27_1 = "qs-mechanic-creator:client:jobChanged"
L26_1(L27_1)
L26_1 = AddEventHandler
L27_1 = "qs-mechanic-creator:client:jobChanged"
function L28_1()
  local L0_2, L1_2, L2_2
  L24_1.initialized = false
  L24_1.inProgress = false
  L24_1.attempts = 0
  L0_2 = {}
  L5_1 = L0_2
  L0_2 = 0
  L6_1 = L0_2
  L0_2 = L25_1
  L0_2()
  L0_2 = L0_1
  if L0_2 then
    L0_2 = Citizen
    L0_2 = L0_2.SetTimeout
    L1_2 = 500
    function L2_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = getPlayerData
      L0_3 = L0_3()
      if L0_3 then
        L1_3 = L0_3.job
        if L1_3 then
          goto lbl_18
        end
      end
      L1_3 = L14_1
      L1_3()
      L1_3 = showClientNotification
      L2_3 = {}
      L2_3.title = "Tablet"
      L2_3.description = "Your job has changed. Tablet closed."
      L2_3.type = "info"
      L1_3(L2_3)
      do return end
      ::lbl_18::
      L1_3 = L9_1
      L1_3 = L1_3()
      if not L1_3 then
        L2_3 = L14_1
        L2_3()
        L2_3 = showClientNotification
        L3_3 = {}
        L3_3.title = "Tablet"
        L3_3.description = "You no longer have access to this shop."
        L3_3.type = "error"
        L2_3(L3_3)
        return
      end
      L1_1 = L1_3
      L2_3 = showClientNotification
      L3_3 = {}
      L3_3.title = "Tablet"
      L3_3.description = "Your permissions have been updated."
      L3_3.type = "info"
      L2_3(L3_3)
      L2_3 = TriggerServerEvent
      L3_3 = "qs-mechanic-creator:server:requestTabletData"
      L4_3 = L1_1
      L5_3 = nil
      L2_3(L3_3, L4_3, L5_3)
    end
    L0_2(L1_2, L2_2)
  end
end
L26_1(L27_1, L28_1)
L26_1 = RegisterNUICallback
L27_1 = "societyTransaction"
function L28_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:societyTransaction"
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L26_1(L27_1, L28_1)
L26_1 = RegisterNetEvent
L27_1 = "qs-mechanic-creator:client:societyTransactionResult"
L26_1(L27_1)
L26_1 = AddEventHandler
L27_1 = "qs-mechanic-creator:client:societyTransactionResult"
function L28_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "societyTransactionResult"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L26_1(L27_1, L28_1)
L26_1 = AddEventHandler
L27_1 = "onResourceStop"
function L28_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = L0_1
    if L1_2 then
      L1_2 = L14_1
      L1_2()
    end
  end
end
L26_1(L27_1, L28_1)
