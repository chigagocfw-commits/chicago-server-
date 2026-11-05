local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1
L0_1 = {}
L0_1.initialized = false
L0_1.configsLoaded = false
L0_1.shopsLoaded = false
L0_1.uiOpen = false
L0_1.mechanicCam = nil
L0_1.textUIShown = false
L0_1.tuneshopOpen = false
L0_1.creatorOpen = false
L0_1.isPlacingShop = false
L0_1.tabletDataReceived = false
function L1_1()
  local L0_2, L1_2
  L0_2 = L0_1.isPlacingShop
  return L0_2
end
IsPlacingShop = L1_1
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = Wait
  L2_2 = 1
  L1_2(L2_2)
  L1_2 = pcall
  function L2_2()
    local L0_3, L1_3
    L0_3 = SendNUIMessage
    L1_3 = A0_2
    L0_3(L1_3)
  end
  L1_2, L2_2 = L1_2(L2_2)
  if not L1_2 then
    L3_2 = Config
    L3_2 = L3_2.Debug
    if L3_2 then
      L3_2 = print
      L4_2 = "^1[NUI ERROR]^0: Failed to send NUI message:"
      L5_2 = L2_2
      L3_2(L4_2, L5_2)
    end
    L3_2 = false
    return L3_2
  end
  L3_2 = true
  return L3_2
end
SafeSendNUIMessage = L1_1
L1_1 = 0
L2_1 = 50
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = L1_1
  L2_2 = L1_2 - L2_2
  L3_2 = L2_1
  if L2_2 < L3_2 then
    L3_2 = Wait
    L4_2 = L2_1
    L4_2 = L4_2 - L2_2
    L3_2(L4_2)
  end
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L1_1 = L3_2
  L3_2 = SafeSendNUIMessage
  L4_2 = A0_2
  return L3_2(L4_2)
end
L4_1 = {}
L4_1.WheelDamage = nil
L4_1.OffroadSystem = nil
L4_1.HeatedBrakes = nil
L5_1 = 0
L6_1 = {}
L7_1 = {}
L8_1 = {}
L9_1 = {}
L10_1 = false
L11_1 = 0
L12_1 = {}
L13_1 = {}
L14_1 = {}
L15_1 = {}
L16_1 = {}
L16_1.loading = false
L16_1.lastUpdate = 0
L16_1.updateInterval = 10000
L16_1.maxZonesPerFrame = 2
L17_1 = {}
L17_1.lastCleanup = 0
L17_1.operationCount = 0
L18_1 = nil
function L19_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    L1_2 = ""
    return L1_2
  end
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^%[E%]%s*%-%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^%[E%]%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press%s*%[E%]%s*%-%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press%s*%[E%]%s*to%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press%s*%[E%]%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press E%s*%-%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press E to%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  L2_2 = A0_2
  L1_2 = A0_2.gsub
  L3_2 = "^Press E%s*"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  A0_2 = L1_2
  return A0_2
end
function L20_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = {}
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = ...
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L2_2 = A0_2
  L3_2 = ipairs
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = type
    L10_2 = L2_2
    L9_2 = L9_2(L10_2)
    if "table" == L9_2 then
      L9_2 = L2_2[L8_2]
      if nil ~= L9_2 then
        L2_2 = L2_2[L8_2]
    end
    else
      L9_2 = nil
      return L9_2
    end
  end
  return L2_2
end
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 then
    return A1_2
  end
  L2_2 = {}
  L3_2 = pairs
  L4_2 = A1_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = A0_2[L7_2]
    if nil ~= L9_2 then
      L9_2 = type
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if "table" == L9_2 then
        L9_2 = type
        L10_2 = A0_2[L7_2]
        L9_2 = L9_2(L10_2)
        if "table" == L9_2 then
          if "excludedZones" == L7_2 or "blacklistedVehicles" == L7_2 or "models" == L7_2 or "classes" == L7_2 or "vehicleOverrides" == L7_2 then
            L9_2 = A0_2[L7_2]
            L2_2[L7_2] = L9_2
          else
            L9_2 = L21_1
            L10_2 = A0_2[L7_2]
            L11_2 = L8_2
            L9_2 = L9_2(L10_2, L11_2)
            L2_2[L7_2] = L9_2
          end
      end
      else
        L9_2 = A0_2[L7_2]
        L2_2[L7_2] = L9_2
      end
    else
      L2_2[L7_2] = L8_2
    end
  end
  return L2_2
end
function L22_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = pcall
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = SetNuiFocus
    L1_3 = false
    L2_3 = false
    L0_3(L1_3, L2_3)
    L0_3 = SetNuiFocusKeepInput
    L1_3 = false
    L0_3(L1_3)
    L0_3 = L0_1.mechanicCam
    if L0_3 then
      L0_3 = RenderScriptCams
      L1_3 = false
      L2_3 = false
      L3_3 = 0
      L4_3 = true
      L5_3 = true
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
      L0_3 = DestroyCam
      L1_3 = L0_1.mechanicCam
      L2_3 = false
      L0_3(L1_3, L2_3)
      L0_1.mechanicCam = nil
    end
    L0_3 = PlayerPedId
    L0_3 = L0_3()
    L1_3 = GetVehiclePedIsIn
    L2_3 = L0_3
    L3_3 = false
    L1_3 = L1_3(L2_3, L3_3)
    if 0 ~= L1_3 then
      L2_3 = FreezeEntityPosition
      L3_3 = L1_3
      L4_3 = false
      L2_3(L3_3, L4_3)
    end
    L0_1.uiOpen = false
    L0_1.creatorOpen = false
    L0_1.tuneshopOpen = false
  end
  L0_2, L1_2 = L0_2(L1_2)
  if not L0_2 then
    L2_2 = lib
    L2_2 = L2_2.print
    L2_2 = L2_2.error
    L3_2 = "UI cleanup failed: "
    L4_2 = tostring
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
    L2_2(L3_2)
  end
end
L23_1 = RegisterNetEvent
L24_1 = "qs-mechanic-creator:client:syncTuneshopVehicle"
L23_1(L24_1)
L23_1 = AddEventHandler
L24_1 = "qs-mechanic-creator:client:syncTuneshopVehicle"
function L25_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  A0_2 = tonumber(A0_2)
  if not A0_2 and (type(A1_2) == "number" or tonumber(A1_2)) then
    A0_2 = tonumber(A1_2)
    A1_2, A2_2, A3_2, A4_2 = nil, nil, nil, nil
  end
  if not A0_2 then
    return
  end
  L5_2 = NetworkDoesNetworkIdExist
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    return
  end
  L5_2 = NetworkGetEntityFromNetworkId
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if L5_2 and 0 ~= L5_2 then
    L6_2 = DoesEntityExist
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      goto lbl_23
    end
  end
  do return end
  ::lbl_23::
  L6_2 = IsEntityAVehicle
  L7_2 = L5_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    return
  end
  L6_2 = PlayerPedId
  L6_2 = L6_2()
  L7_2 = GetVehiclePedIsIn
  L8_2 = L6_2
  L9_2 = false
  L7_2 = L7_2(L8_2, L9_2)
  if L7_2 == L5_2 then
    return
  end
  L6_2 = NetworkRequestControlOfEntity
  L7_2 = L5_2
  L6_2(L7_2)
  L6_2 = GetGameTimer
  L6_2 = L6_2()
  L6_2 = L6_2 + 1000
  while true do
    L7_2 = NetworkHasControlOfEntity
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      break
    end
    L7_2 = GetGameTimer
    L7_2 = L7_2()
    if not (L6_2 > L7_2) then
      break
    end
    L7_2 = Wait
    L8_2 = 0
    L7_2(L8_2)
    L7_2 = NetworkRequestControlOfEntity
    L8_2 = L5_2
    L7_2(L8_2)
  end
  L7_2 = FreezeEntityPosition
  L8_2 = L5_2
  L9_2 = false
  L7_2(L8_2, L9_2)
  L7_2 = SetEntityCollision
  L8_2 = L5_2
  L9_2 = true
  L10_2 = true
  L7_2(L8_2, L9_2, L10_2)
  A1_2 = tonumber(A1_2)
  A2_2 = tonumber(A2_2)
  A3_2 = tonumber(A3_2)
  A4_2 = tonumber(A4_2)
  if not A1_2 or not A2_2 or not A3_2 then
    L7_2 = GetEntityCoords
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    A1_2 = L7_2.x
    A2_2 = L7_2.y
    A3_2 = L7_2.z
  end
  if not A4_2 then
    L7_2 = GetEntityHeading
    L8_2 = L5_2
    A4_2 = L7_2(L8_2) or 0.0
  end
  L7_2 = SetEntityCoordsNoOffset
  L8_2 = L5_2
  L9_2 = A1_2
  L10_2 = A2_2
  L11_2 = A3_2
  L12_2 = false
  L13_2 = false
  L14_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L7_2 = SetEntityHeading
  L8_2 = L5_2
  L9_2 = A4_2 + 0.0
  L7_2(L8_2, L9_2)
  L7_2 = SetVehicleOnGroundProperly
  L8_2 = L5_2
  L7_2(L8_2)
  L7_2 = Wait
  L8_2 = 50
  L7_2(L8_2)
  L7_2 = SetEntityRotation
  L8_2 = L5_2
  L9_2 = 0.0
  L10_2 = 0.0
  L11_2 = A4_2 + 0.0
  L12_2 = 2
  L13_2 = true
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L7_2 = SetEntityHeading
  L8_2 = L5_2
  L9_2 = A4_2 + 0.0
  L7_2(L8_2, L9_2)
  L7_2 = FreezeEntityPosition
  L8_2 = L5_2
  L9_2 = true
  L7_2(L8_2, L9_2)
end
L23_1(L24_1, L25_1)
function L23_1()
  local L0_2, L1_2
  L0_2 = L18_1
  function L1_2(A0_3)
    local L1_3, L2_3
    if A0_3 then
      L1_3 = TriggerServerEvent
      L2_3 = "qs-mechanic-creator:server:requestPlayerData"
      L1_3(L2_3)
    end
  end
  L0_2(L1_2)
end
function L24_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = 0
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L12_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L7_2 = #L1_2
    L7_2 = L7_2 + 1
    L1_2[L7_2] = L6_2
  end
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L12_1
    L8_2 = L8_2[L7_2]
    if L8_2 then
      L9_2 = DoesBlipExist
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 then
        L9_2 = RemoveBlip
        L10_2 = L8_2
        L9_2(L10_2)
        L0_2 = L0_2 + 1
      end
    end
    L9_2 = L12_1
    L9_2[L7_2] = nil
  end
end
function L25_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if not A1_2 then
    L2_2 = L12_1
    L2_2 = L2_2[A0_2]
    if L2_2 then
      L2_2 = DoesBlipExist
      L3_2 = L12_1
      L3_2 = L3_2[A0_2]
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = RemoveBlip
        L3_2 = L12_1
        L3_2 = L3_2[A0_2]
        L2_2(L3_2)
        L2_2 = L12_1
        L2_2[A0_2] = nil
      end
    end
    return
  end
  L2_2 = L20_1
  L3_2 = A1_2
  L4_2 = "shopConfig"
  L5_2 = "blip"
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if not L2_2 then
    L2_2 = L20_1
    L3_2 = A1_2
    L4_2 = "blip"
    L2_2 = L2_2(L3_2, L4_2)
  end
  if not L2_2 or false == L2_2 then
    L3_2 = L12_1
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = DoesBlipExist
      L4_2 = L12_1
      L4_2 = L4_2[A0_2]
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L3_2 = RemoveBlip
        L4_2 = L12_1
        L4_2 = L4_2[A0_2]
        L3_2(L4_2)
        L3_2 = L12_1
        L3_2[A0_2] = nil
      end
    end
    return
  end
  L3_2 = L2_2.sprite
  if not L3_2 then
    L2_2.sprite = 72
  end
  L3_2 = L2_2.color
  if not L3_2 then
    L2_2.color = 81
  end
  L3_2 = L2_2.scale
  if not L3_2 then
    L2_2.scale = 0.8
  end
  L3_2 = L2_2.name
  if not L3_2 then
    L3_2 = _U
    L4_2 = "BLIP_MECHANIC_SHOP"
    L3_2 = L3_2(L4_2)
    L2_2.name = L3_2
  end
  L3_2 = L12_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = DoesBlipExist
    L4_2 = L12_1
    L4_2 = L4_2[A0_2]
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = RemoveBlip
      L4_2 = L12_1
      L4_2 = L4_2[A0_2]
      L3_2(L4_2)
    end
  end
  L3_2 = L2_2.coords
  if not L3_2 then
    L4_2 = L20_1
    L5_2 = A1_2
    L6_2 = "shopConfig"
    L7_2 = "coords"
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L3_2 = L4_2 or L3_2
    if not L4_2 then
      L4_2 = L20_1
      L5_2 = A1_2
      L6_2 = "coords"
      L4_2 = L4_2(L5_2, L6_2)
      L3_2 = L4_2
    end
  end
  if not L3_2 then
    return
  end
  L4_2 = AddBlipForCoord
  L5_2 = L3_2.x
  L6_2 = L3_2.y
  L7_2 = L3_2.z
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if L4_2 then
    L5_2 = SetBlipSprite
    L6_2 = L4_2
    L7_2 = L2_2.sprite
    if not L7_2 then
      L7_2 = 72
    end
    L5_2(L6_2, L7_2)
    L5_2 = SetBlipDisplay
    L6_2 = L4_2
    L7_2 = 4
    L5_2(L6_2, L7_2)
    L5_2 = SetBlipScale
    L6_2 = L4_2
    L7_2 = L2_2.scale
    if not L7_2 then
      L7_2 = 0.8
    end
    L5_2(L6_2, L7_2)
    L5_2 = SetBlipColour
    L6_2 = L4_2
    L7_2 = L2_2.color
    if not L7_2 then
      L7_2 = 81
    end
    L5_2(L6_2, L7_2)
    L5_2 = SetBlipAsShortRange
    L6_2 = L4_2
    L7_2 = true
    L5_2(L6_2, L7_2)
    L5_2 = BeginTextCommandSetBlipName
    L6_2 = "STRING"
    L5_2(L6_2)
    L5_2 = AddTextComponentString
    L6_2 = L2_2.name
    if not L6_2 then
      L6_2 = _U
      L7_2 = "BLIP_MECHANIC_SHOP"
      L6_2 = L6_2(L7_2)
    end
    L5_2(L6_2)
    L5_2 = EndTextCommandSetBlipName
    L6_2 = L4_2
    L5_2(L6_2)
    L5_2 = L12_1
    L5_2[A0_2] = L4_2
  end
end
function L26_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = {}
  L0_2.enabled = true
  L1_2 = {}
  L2_2 = {}
  L1_2.models = L2_2
  L2_2 = {}
  L1_2.classes = L2_2
  L0_2.blacklist = L1_2
  L1_2 = {}
  L1_2.enabled = false
  L1_2.speed = 180
  L1_2.chance = 100
  L2_2 = {}
  L3_2 = 0
  L4_2 = 1
  L5_2 = 4
  L6_2 = 5
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L1_2.wheels = L2_2
  L1_2.cooldown = 5000
  L0_2.crashBreak = L1_2
  L1_2 = L21_1
  L2_2 = L4_1.WheelDamage
  L3_2 = L0_2
  return L1_2(L2_2, L3_2)
end
getWheelDamageConfig = L26_1
function L26_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2, L42_2, L43_2, L44_2, L45_2, L46_2, L47_2, L48_2, L49_2, L50_2, L51_2
  L0_2 = {}
  L0_2.enabled = true
  L1_2 = {}
  L0_2.excludedZones = L1_2
  L1_2 = {}
  L2_2 = "rcbandito"
  L3_2 = "monster"
  L4_2 = "rhino"
  L5_2 = "scarab"
  L6_2 = "khanjali"
  L7_2 = "oppressor"
  L8_2 = "oppressor2"
  L9_2 = "deluxo"
  L10_2 = "stromberg"
  L11_2 = "toreador"
  L12_2 = "vigilante"
  L13_2 = "akula"
  L14_2 = "hunter"
  L15_2 = "savage"
  L16_2 = "buzzard"
  L17_2 = "buzzard2"
  L18_2 = "valkyrie"
  L19_2 = "valkyrie2"
  L20_2 = "hydra"
  L21_2 = "lazer"
  L22_2 = "titan"
  L23_2 = "cargobob"
  L24_2 = "cargobob2"
  L25_2 = "cargobob3"
  L26_2 = "cargobob4"
  L27_2 = "skylift"
  L28_2 = "volatol"
  L29_2 = "bombushka"
  L30_2 = "mogul"
  L31_2 = "nokota"
  L32_2 = "pyro"
  L33_2 = "starling"
  L34_2 = "seabreeze"
  L35_2 = "tula"
  L36_2 = "dodo"
  L37_2 = "howard"
  L38_2 = "alphaz1"
  L39_2 = "nimbus"
  L40_2 = "miljet"
  L41_2 = "shamal"
  L42_2 = "luxor"
  L43_2 = "luxor2"
  L44_2 = "jet"
  L45_2 = "besra"
  L46_2 = "cuban800"
  L47_2 = "duster"
  L48_2 = "stunt"
  L49_2 = "mallard"
  L50_2 = "velum"
  L51_2 = "velum2"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L1_2[7] = L8_2
  L1_2[8] = L9_2
  L1_2[9] = L10_2
  L1_2[10] = L11_2
  L1_2[11] = L12_2
  L1_2[12] = L13_2
  L1_2[13] = L14_2
  L1_2[14] = L15_2
  L1_2[15] = L16_2
  L1_2[16] = L17_2
  L1_2[17] = L18_2
  L1_2[18] = L19_2
  L1_2[19] = L20_2
  L1_2[20] = L21_2
  L1_2[21] = L22_2
  L1_2[22] = L23_2
  L1_2[23] = L24_2
  L1_2[24] = L25_2
  L1_2[25] = L26_2
  L1_2[26] = L27_2
  L1_2[27] = L28_2
  L1_2[28] = L29_2
  L1_2[29] = L30_2
  L1_2[30] = L31_2
  L1_2[31] = L32_2
  L1_2[32] = L33_2
  L1_2[33] = L34_2
  L1_2[34] = L35_2
  L1_2[35] = L36_2
  L1_2[36] = L37_2
  L1_2[37] = L38_2
  L1_2[38] = L39_2
  L1_2[39] = L40_2
  L1_2[40] = L41_2
  L1_2[41] = L42_2
  L1_2[42] = L43_2
  L1_2[43] = L44_2
  L1_2[44] = L45_2
  L1_2[45] = L46_2
  L1_2[46] = L47_2
  L1_2[47] = L48_2
  L1_2[48] = L49_2
  L1_2[49] = L50_2
  L1_2[50] = L51_2
  L2_2 = "vestra"
  L3_2 = "cargoplane"
  L4_2 = "titan2"
  L5_2 = "avenger"
  L6_2 = "avenger2"
  L7_2 = "avenger3"
  L8_2 = "cerberus"
  L9_2 = "cerberus2"
  L10_2 = "cerberus3"
  L11_2 = "scarab"
  L12_2 = "scarab2"
  L13_2 = "scarab3"
  L14_2 = "khanjali"
  L15_2 = "khanjali2"
  L16_2 = "khanjali3"
  L17_2 = "thruster"
  L1_2[51] = L2_2
  L1_2[52] = L3_2
  L1_2[53] = L4_2
  L1_2[54] = L5_2
  L1_2[55] = L6_2
  L1_2[56] = L7_2
  L1_2[57] = L8_2
  L1_2[58] = L9_2
  L1_2[59] = L10_2
  L1_2[60] = L11_2
  L1_2[61] = L12_2
  L1_2[62] = L13_2
  L1_2[63] = L14_2
  L1_2[64] = L15_2
  L1_2[65] = L16_2
  L1_2[66] = L17_2
  L0_2.blacklistedVehicles = L1_2
  L1_2 = L21_1
  L2_2 = L4_1.OffroadSystem
  L3_2 = L0_2
  return L1_2(L2_2, L3_2)
end
getOffroadSystemConfig = L26_1
function L26_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = {}
  L0_2.enabled = true
  L0_2.temperatureRate = 1.0
  L0_2.coolingRate = 1.0
  L0_2.performanceLoss = 1.0
  L1_2 = {}
  L0_2.blacklistedVehicles = L1_2
  L1_2 = {}
  L2_2 = {}
  L2_2.enabled = true
  L2_2.strength = 1
  L1_2.glow = L2_2
  L0_2.visual = L1_2
  L1_2 = {}
  L2_2 = {}
  L1_2.classes = L2_2
  L2_2 = {}
  L3_2 = -1
  L2_2[L3_2] = 1.0
  L2_2[0] = 1.0
  L2_2[1] = 1.0
  L2_2[2] = 1.0
  L1_2.brakeUpgrade = L2_2
  L0_2.temperatureIncrease = L1_2
  L1_2 = {}
  L2_2 = {}
  L1_2.classes = L2_2
  L2_2 = {}
  L3_2 = -1
  L2_2[L3_2] = 1.0
  L2_2[0] = 1.0
  L2_2[1] = 1.0
  L2_2[2] = 1.0
  L1_2.brakeUpgrade = L2_2
  L0_2.temperatureDecrease = L1_2
  L1_2 = setmetatable
  L2_2 = {}
  L3_2 = {}
  L3_2.__jsontype = "object"
  L1_2 = L1_2(L2_2, L3_2)
  L0_2.vehicleOverrides = L1_2
  L1_2 = L21_1
  L2_2 = L4_1.HeatedBrakes
  L3_2 = L0_2
  L1_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L2_2 = L1_2.vehicleOverrides
    if L2_2 then
      L2_2 = setmetatable
      L3_2 = L1_2.vehicleOverrides
      L4_2 = {}
      L4_2.__jsontype = "object"
      L2_2(L3_2, L4_2)
    end
  end
  return L1_2
end
getHeatedBrakesConfig = L26_1
function L26_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = lib
  if not L1_2 then
    if A0_2 then
      L1_2 = A0_2
      L2_2 = false
      L1_2(L2_2)
    end
    return
  end
  L1_2 = lib
  L1_2 = L1_2.callback
  L2_2 = "qs-mechanic-creator:server:getConfigs"
  L3_2 = false
  function L4_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    if A0_3 then
      L1_3 = A0_3.wheeldamage
      L4_1.WheelDamage = L1_3
      L1_3 = A0_3.offroadsystem
      L4_1.OffroadSystem = L1_3
      L1_3 = A0_3.heatedbrakes
      L4_1.HeatedBrakes = L1_3
      L1_3 = A0_3.wheeldamage
      if L1_3 then
        L1_3 = TriggerEvent
        L2_3 = "qs-mechanic-creator:client:setWheelDamage"
        L3_3 = A0_3.wheeldamage
        L1_3(L2_3, L3_3)
      end
      L1_3 = A0_3.offroadsystem
      if L1_3 then
        L1_3 = {}
        L2_3 = A0_3.offroadsystem
        L2_3 = L2_3.enabled
        if not L2_3 then
          L2_3 = true
        end
        L1_3.active = L2_3
        L2_3 = A0_3.offroadsystem
        L2_3 = L2_3.excludedZones
        if not L2_3 then
          L2_3 = {}
        end
        L1_3.excludedZones = L2_3
        L2_3 = A0_3.offroadsystem
        L2_3 = L2_3.blacklistedVehicles
        if not L2_3 then
          L2_3 = {}
          L3_3 = "rcbandito"
          L4_3 = "monster"
          L5_3 = "rhino"
          L6_3 = "scarab"
          L7_3 = "khanjali"
          L2_3[1] = L3_3
          L2_3[2] = L4_3
          L2_3[3] = L5_3
          L2_3[4] = L6_3
          L2_3[5] = L7_3
        end
        L1_3.blacklistedVehicles = L2_3
        L2_3 = TriggerEvent
        L3_3 = "advanced-mechanic:client:setTerrainSystem"
        L4_3 = L1_3
        L2_3(L3_3, L4_3)
        L2_3 = TriggerEvent
        L3_3 = "qs-mechanic-creator:client:setOffroadSystem"
        L4_3 = A0_3.offroadsystem
        L2_3(L3_3, L4_3)
      end
      L1_3 = A0_3.heatedbrakes
      if L1_3 then
        L1_3 = TriggerEvent
        L2_3 = "qs-mechanic-creator:client:setHeatedBrakes"
        L3_3 = A0_3.heatedbrakes
        L1_3(L2_3, L3_3)
      end
      L0_1.configsLoaded = true
      L1_3 = A0_2
      if L1_3 then
        L1_3 = A0_2
        L2_3 = true
        L3_3 = A0_3
        L1_3(L2_3, L3_3)
      end
    else
      L1_3 = getWheelDamageConfig
      L1_3 = L1_3()
      L4_1.WheelDamage = L1_3
      L1_3 = getOffroadSystemConfig
      L1_3 = L1_3()
      L4_1.OffroadSystem = L1_3
      L1_3 = getHeatedBrakesConfig
      L1_3 = L1_3()
      L4_1.HeatedBrakes = L1_3
      L0_1.configsLoaded = true
      L1_3 = A0_2
      if L1_3 then
        L1_3 = A0_2
        L2_3 = true
        L3_3 = {}
        L1_3(L2_3, L3_3)
      end
    end
  end
  L1_2(L2_2, L3_2, L4_2)
end
function L27_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SafeSendNUIMessage
  L3_2 = {}
  L3_2.type = "openCreatorUI"
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = mechanicShops
  end
  L3_2.shops = L4_2
  if A1_2 then
    L4_2 = A1_2.wheeldamage
    if L4_2 then
      goto lbl_15
    end
  end
  L4_2 = L4_1.WheelDamage
  ::lbl_15::
  L3_2.wheeldamage = L4_2
  if A1_2 then
    L4_2 = A1_2.offroadsystem
    if L4_2 then
      goto lbl_22
    end
  end
  L4_2 = L4_1.OffroadSystem
  ::lbl_22::
  L3_2.offroadsystem = L4_2
  if A1_2 then
    L4_2 = A1_2.heatedbrakes
    if L4_2 then
      goto lbl_29
    end
  end
  L4_2 = L4_1.HeatedBrakes
  ::lbl_29::
  L3_2.heatedbrakes = L4_2
  L4_2 = GetLocales
  L4_2 = L4_2()
  L3_2.locales = L4_2
  L2_2(L3_2)
end
function L28_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2 or nil
  if not A0_2 then
    L2_2 = mechanicShops
  end
  mechanicShops = L2_2
  if A1_2 then
    L2_2 = A1_2.wheeldamage
    L4_1.WheelDamage = L2_2
    L2_2 = A1_2.offroadsystem
    L4_1.OffroadSystem = L2_2
    L2_2 = A1_2.heatedbrakes
    L4_1.HeatedBrakes = L2_2
  end
  L0_1.creatorOpen = true
  L0_1.uiOpen = true
  L2_2 = L27_1
  L3_2 = mechanicShops
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
  L2_2 = SetNuiFocus
  L3_2 = true
  L4_2 = true
  L2_2(L3_2, L4_2)
end
function L29_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = lib
  if not L0_2 then
    L0_2 = showClientNotification
    L1_2 = {}
    L2_2 = _U
    L3_2 = "ERROR"
    L2_2 = L2_2(L3_2)
    L1_2.title = L2_2
    L2_2 = _U
    L3_2 = "DEPENDENCY_NOT_AVAILABLE"
    L2_2 = L2_2(L3_2)
    L1_2.description = L2_2
    L1_2.type = "error"
    L0_2(L1_2)
    return
  end
  L0_2 = L0_1.uiOpen
  if L0_2 then
    return
  end
  L0_2 = L26_1
  function L1_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    if not A0_3 then
      L2_3 = showClientNotification
      L3_3 = {}
      L4_3 = _U
      L5_3 = "ERROR"
      L4_3 = L4_3(L5_3)
      L3_3.title = L4_3
      L4_3 = _U
      L5_3 = "FAILED_LOAD_CONFIGS"
      L4_3 = L4_3(L5_3)
      L3_3.description = L4_3
      L3_3.type = "error"
      L2_3(L3_3)
      return
    end
    L2_3 = lib
    L2_3 = L2_3.callback
    L3_3 = "qs-mechanic-creator:server:getMechanicShops"
    L4_3 = false
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4
      L1_4 = L28_1
      L2_4 = A0_4
      L3_4 = A1_3
      L1_4(L2_4, L3_4)
    end
    L2_3(L3_3, L4_3, L5_3)
  end
  L0_2(L1_2)
end
openMechanicCreator = L29_1
function L29_1()
  local L0_2, L1_2
  L0_2 = L22_1
  L0_2()
end
closeMechanicUI = L29_1
function L29_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  if not A1_2 or not A2_2 then
    L4_2 = nil
    return L4_2
  end
  L4_2 = A0_2
  L5_2 = string
  L5_2 = L5_2.find
  L6_2 = A0_2
  L7_2 = "_tuneshop_"
  L5_2 = L5_2(L6_2, L7_2)
  if L5_2 then
    L5_2 = string
    L5_2 = L5_2.sub
    L6_2 = A0_2
    L7_2 = 1
    L8_2 = string
    L8_2 = L8_2.find
    L9_2 = A0_2
    L10_2 = "_tuneshop_"
    L8_2 = L8_2(L9_2, L10_2)
    L8_2 = L8_2 - 1
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    L4_2 = L5_2
  end
  L5_2 = QsMechanicNormalizeCoordTable
  if L5_2 then
    L5_2 = QsMechanicNormalizeCoordTable(A2_2)
    if L5_2 then
      A2_2 = L5_2
      goto lbl_41
    end
  end
  if A2_2 then
    L5_2 = tonumber(A2_2.x or A2_2[1])
    L6_2 = tonumber(A2_2.y or A2_2[2])
    L7_2 = tonumber(A2_2.z or A2_2[3])
    if L5_2 and L6_2 and L7_2 then
      A2_2.x = L5_2
      A2_2.y = L6_2
      A2_2.z = L7_2
      goto lbl_41
    end
  end
  L5_2 = nil
  do return L5_2 end
  ::lbl_41::
  L5_2 = A2_2.w
  if L5_2 then
    L5_2 = tonumber
    L6_2 = A2_2.w
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_62
    end
  end
  L5_2 = 0.0
  ::lbl_62::
  A2_2.w = L5_2
  L5_2 = tonumber(A2_2.x)
  L6_2 = tonumber(A2_2.y)
  L7_2 = tonumber(A2_2.z)
  if not (L5_2 and L6_2 and L7_2) then
    L8_2 = nil
    return L8_2
  end
  A2_2.x = L5_2
  A2_2.y = L6_2
  A2_2.z = L7_2
  L5_2 = math
  L5_2 = L5_2.abs
  L6_2 = A2_2.x
  L5_2 = L5_2(L6_2)
  L6_2 = 10000
  if not (L5_2 > L6_2) then
    L5_2 = math
    L5_2 = L5_2.abs
    L6_2 = A2_2.y
    L5_2 = L5_2(L6_2)
    L6_2 = 10000
    if not (L5_2 > L6_2) then
      L5_2 = tonumber(A2_2.z)
      L6_2 = -500
      if L5_2 and not (L5_2 < L6_2) then
        L5_2 = tonumber(A2_2.z)
        L6_2 = 2000
        if L5_2 and not (L5_2 > L6_2) then
          goto lbl_121
        end
      end
    end
  end
  L5_2 = Config
  L5_2 = L5_2.Debug
  if L5_2 then
    L5_2 = print
    L6_2 = "^1[TUNESHOP ERROR]^0: Invalid coordinates for zone "
    L7_2 = tostring
    L8_2 = A0_2
    L7_2 = L7_2(L8_2)
    L8_2 = " - x:"
    L9_2 = tostring
    L10_2 = A2_2.x
    L9_2 = L9_2(L10_2)
    L10_2 = " y:"
    L11_2 = tostring
    L12_2 = A2_2.y
    L11_2 = L11_2(L12_2)
    L12_2 = " z:"
    L13_2 = tostring
    L14_2 = A2_2.z
    L13_2 = L13_2(L14_2)
    L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
    L5_2(L6_2)
  end
  L5_2 = nil
  do return L5_2 end
  ::lbl_121::
  L5_2 = lib
  if L5_2 then
    L5_2 = lib
    L5_2 = L5_2.zones
    if L5_2 then
      L5_2 = lib
      L5_2 = L5_2.zones
      L5_2 = L5_2.box
      if L5_2 then
        goto lbl_135
      end
    end
  end
  L5_2 = nil
  do return L5_2 end
  ::lbl_135::
  L5_2 = L19_1
  L6_2 = _U
  L7_2 = "PRESS_E_TUNESHOP"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L6_2(L7_2)
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L6_2 = "[E] - "
  L7_2 = L5_2
  L6_2 = L6_2 .. L7_2
  L7_2 = tonumber(A2_2.w or A2_2.heading) or 0.0
  A2_2.x = tonumber(A2_2.x)
  A2_2.y = tonumber(A2_2.y)
  A2_2.z = tonumber(A2_2.z)
  A2_2.w = L7_2
  if not A2_2.x or not A2_2.y or not A2_2.z then
    L8_2 = nil
    return L8_2
  end
  L8_2 = Config
  L8_2 = L8_2.TuneshopZoneSize
  if not L8_2 then
    L8_2 = {}
    L8_2.x = 8.0
    L8_2.y = 8.0
    L8_2.z = 4.0
  end
  L9_2 = tonumber
  L10_2 = L8_2.x
  L9_2 = L9_2(L10_2)
  if not L9_2 then
    L9_2 = 8.0
  end
  L10_2 = tonumber
  L11_2 = L8_2.y
  L10_2 = L10_2(L11_2)
  if not L10_2 then
    L10_2 = 8.0
  end
  L11_2 = tonumber
  L12_2 = L8_2.z
  L11_2 = L11_2(L12_2)
  if not L11_2 then
    L11_2 = 4.0
  end
  L12_2 = pcall
  function L13_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = lib
    L0_3 = L0_3.zones
    L0_3 = L0_3.box
    L1_3 = {}
    L2_3 = "tuneshop_"
    L3_3 = A0_2
    L2_3 = L2_3 .. L3_3
    L1_3.name = L2_3
    L2_3 = vector3
    L3_3 = A2_2.x
    L4_3 = A2_2.y
    L5_3 = A2_2.z
    L2_3 = L2_3(L3_3, L4_3, L5_3)
    L1_3.coords = L2_3
    L2_3 = vector3
    L3_3 = L9_2
    L4_3 = L10_2
    L5_3 = L11_2
    L2_3 = L2_3(L3_3, L4_3, L5_3)
    L1_3.size = L2_3
    L2_3 = L7_2
    L1_3.rotation = L2_3
    L2_3 = Config
    L2_3 = L2_3.Debug
    L1_3.debug = L2_3
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4
      L0_4 = L0_1.textUIShown
      if L0_4 then
        return
      end
      L0_4 = PlayerPedId
      L0_4 = L0_4()
      L1_4 = GetVehiclePedIsIn
      L2_4 = L0_4
      L3_4 = false
      L1_4 = L1_4(L2_4, L3_4)
      if 0 ~= L1_4 then
        L2_4 = lib
        L2_4 = L2_4.showTextUI
        L3_4 = L6_2
        L4_4 = {}
        L5_4 = Config
        L5_4 = L5_4.TextPosition
        L4_4.position = L5_4
        L4_4.icon = "fa-solid fa-wrench"
        L5_4 = {}
        L5_4.borderRadius = 5
        L5_4.backgroundColor = "rgba(0, 0, 0, 0.8)"
        L5_4.color = "white"
        L4_4.style = L5_4
        L2_4(L3_4, L4_4)
        L0_1.textUIShown = true
      end
    end
    L1_3.onEnter = L2_3
    function L2_3()
      local L0_4, L1_4
      L0_4 = L0_1.textUIShown
      if L0_4 then
        L0_4 = lib
        L0_4 = L0_4.hideTextUI
        L0_4()
        L0_1.textUIShown = false
      end
    end
    L1_3.onExit = L2_3
    function L2_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4, L13_4, L14_4, L15_4, L16_4, L17_4, L18_4, L19_4, L20_4, L21_4, L22_4, L23_4, L24_4, L25_4, L26_4
      L0_4 = PlayerPedId
      L0_4 = L0_4()
      L1_4 = GetVehiclePedIsIn
      L2_4 = L0_4
      L3_4 = false
      L1_4 = L1_4(L2_4, L3_4)
      if 0 ~= L1_4 then
        L2_4 = L0_1.tuneshopOpen
        if not L2_4 then
          L2_4 = DrawMarker
          L3_4 = 2
          L4_4 = A2_2.x
          L5_4 = A2_2.y
          L6_4 = A2_2.z
          L6_4 = L6_4 + 1.0
          L7_4 = 0.0
          L8_4 = 0.0
          L9_4 = 0.0
          L10_4 = 0.0
          L11_4 = 0.0
          L12_4 = 0.0
          L13_4 = 0.3
          L14_4 = 0.3
          L15_4 = 0.3
          L16_4 = 255
          L17_4 = 255
          L18_4 = 0
          L19_4 = 150
          L20_4 = false
          L21_4 = true
          L22_4 = 2
          L23_4 = false
          L24_4 = nil
          L25_4 = nil
          L26_4 = false
          L2_4(L3_4, L4_4, L5_4, L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4, L13_4, L14_4, L15_4, L16_4, L17_4, L18_4, L19_4, L20_4, L21_4, L22_4, L23_4, L24_4, L25_4, L26_4)
        end
      end
      if 0 ~= L1_4 then
        L3_4 = A0_2
        L2_4 = L15_1
        L2_4 = L2_4[L3_4]
        if L2_4 then
          L2_4 = L0_1.tuneshopOpen
          if not L2_4 then
            L2_4 = L0_1.textUIShown
            if not L2_4 then
              L2_4 = lib
              L2_4 = L2_4.showTextUI
              L3_4 = "[!] - "
              L4_4 = _U
              L5_4 = "TUNESHOP_IN_USE"
              L4_4 = L4_4(L5_4)
              L3_4 = L3_4 .. L4_4
              L4_4 = {}
              L5_4 = Config
              L5_4 = L5_4.TextPosition
              L4_4.position = L5_4
              L4_4.icon = "fa-solid fa-ban"
              L5_4 = {}
              L5_4.borderRadius = 5
              L5_4.backgroundColor = "rgba(255, 0, 0, 0.8)"
              L5_4.color = "white"
              L4_4.style = L5_4
              L2_4(L3_4, L4_4)
              L0_1.textUIShown = true
            end
        end
        else
          L2_4 = L0_1.textUIShown
          if not L2_4 then
            L2_4 = L0_1.tuneshopOpen
            if not L2_4 then
              L2_4 = lib
              L2_4 = L2_4.showTextUI
              L3_4 = L6_2
              L4_4 = {}
              L5_4 = Config
              L5_4 = L5_4.TextPosition
              L4_4.position = L5_4
              L4_4.icon = "fa-solid fa-wrench"
              L5_4 = {}
              L5_4.borderRadius = 5
              L5_4.backgroundColor = "rgba(0, 0, 0, 0.8)"
              L5_4.color = "white"
              L4_4.style = L5_4
              L2_4(L3_4, L4_4)
              L0_1.textUIShown = true
            end
          end
        end
        L2_4 = L0_1.textUIShown
        if not L2_4 then
          goto lbl_332
        end
        L2_4 = IsControlJustReleased
        L3_4 = 0
        L4_4 = 38
        L2_4 = L2_4(L3_4, L4_4)
        if not L2_4 then
          goto lbl_332
        end
        L2_4 = L0_1.tuneshopOpen
        if L2_4 then
          goto lbl_332
        end
        L3_4 = A0_2
        L2_4 = L15_1
        L2_4 = L2_4[L3_4]
        if L2_4 then
          goto lbl_332
        end
        L3_4 = A0_2
        L2_4 = L15_1
        L2_4[L3_4] = true
        L2_4 = TriggerServerEvent
        L3_4 = "qs-mechanic-creator:server:setTuneshopOccupied"
        L4_4 = A0_2
        L5_4 = true
        L2_4(L3_4, L4_4, L5_4)
        L2_4 = NetworkGetNetworkIdFromEntity
        L3_4 = L1_4
        L2_4 = L2_4(L3_4)
        L3_4 = NetworkRequestControlOfEntity
        L4_4 = L1_4
        L3_4(L4_4)
        L3_4 = GetGameTimer
        L3_4 = L3_4()
        L3_4 = L3_4 + 1000
        while true do
          L4_4 = NetworkHasControlOfEntity
          L5_4 = L1_4
          L4_4 = L4_4(L5_4)
          if L4_4 then
            break
          end
          L4_4 = GetGameTimer
          L4_4 = L4_4()
          if not (L3_4 > L4_4) then
            break
          end
          L4_4 = Wait
          L5_4 = 0
          L4_4(L5_4)
          L4_4 = NetworkRequestControlOfEntity
          L5_4 = L1_4
          L4_4(L5_4)
        end
        L4_4 = PlayerPedId
        L4_4 = L4_4()
        L5_4 = IsPedInVehicle
        L6_4 = L4_4
        L7_4 = L1_4
        L8_4 = false
        L5_4 = L5_4(L6_4, L7_4, L8_4)
        if not L5_4 then
          L5_4 = SetPedIntoVehicle
          L6_4 = L4_4
          L7_4 = L1_4
          L8_4 = -1
          L5_4(L6_4, L7_4, L8_4)
        end
        L5_4 = SetEntityCollision
        L6_4 = L1_4
        L7_4 = true
        L8_4 = true
        L5_4(L6_4, L7_4, L8_4)
        L5_4 = FreezeEntityPosition
        L6_4 = L1_4
        L7_4 = false
        L5_4(L6_4, L7_4)
        L5_4 = QsMechanicNormalizeCoordTable
        if L5_4 then
          L5_4 = QsMechanicNormalizeCoordTable(A2_2)
          if L5_4 then
            A2_2 = L5_4
          end
        end
        L5_4 = tonumber(A2_2.x)
        L6_4 = tonumber(A2_2.y)
        L7_4 = tonumber(A2_2.z)
        if not (L5_4 and L6_4 and L7_4) then
          L8_4 = GetEntityCoords
          L9_4 = L1_4
          L8_4 = L8_4(L9_4)
          L5_4 = L8_4.x
          L6_4 = L8_4.y
          L7_4 = L8_4.z
          A2_2.x = L5_4
          A2_2.y = L6_4
          A2_2.z = L7_4
        end
        L8_4 = tonumber(L7_2) or GetEntityHeading(L1_4) or 0.0
        L7_2 = L8_4
        L11_4 = L5_4
        L12_4 = L6_4
        L13_4 = L7_4
        L5_4 = SetEntityCoordsNoOffset
        L6_4 = L1_4
        L7_4 = L11_4
        L8_4 = L12_4
        L9_4 = L13_4
        L10_4 = false
        L11_4 = false
        L12_4 = false
        L5_4(L6_4, L7_4, L8_4, L9_4, L10_4, L11_4, L12_4)
        L6_4 = SetEntityHeading
        L7_4 = L1_4
        L8_4 = tonumber(L7_2) or GetEntityHeading(L1_4) or 0.0
        L6_4(L7_4, L8_4)
        L6_4 = Wait
        L7_4 = 50
        L6_4(L7_4)
        L6_4 = SetEntityRotation
        L7_4 = L1_4
        L8_4 = 0.0
        L9_4 = 0.0
        L10_4 = tonumber(L7_2) or 0.0
        L11_4 = 2
        L12_4 = true
        L6_4(L7_4, L8_4, L9_4, L10_4, L11_4, L12_4)
        L6_4 = SetEntityHeading
        L7_4 = L1_4
        L8_4 = tonumber(L7_2) or GetEntityHeading(L1_4) or 0.0
        L6_4(L7_4, L8_4)
        L6_4 = GetEntityCoords
        L7_4 = L1_4
        L6_4 = L6_4(L7_4)
        L7_4 = NetworkGetNetworkIdFromEntity
        L8_4 = L1_4
        L7_4 = L7_4(L8_4)
        L8_4 = TriggerServerEvent
        L9_4 = "qs-mechanic-creator:server:syncTuneshopVehicle"
        L10_4 = L7_4
        L11_4 = L6_4.x
        L12_4 = L6_4.y
        L13_4 = L6_4.z
        L14_4 = tonumber(L7_2) or GetEntityHeading(L1_4) or 0.0
        L8_4(L9_4, L10_4, L11_4, L12_4, L13_4, L14_4)
        L8_4 = Wait
        L9_4 = 100
        L8_4(L9_4)
        L8_4 = SetEntityCollision
        L9_4 = L1_4
        L10_4 = true
        L11_4 = true
        L8_4(L9_4, L10_4, L11_4)
        L8_4 = FreezeEntityPosition
        L9_4 = L1_4
        L10_4 = true
        L8_4(L9_4, L10_4)
        L8_4 = lib
        L8_4 = L8_4.hideTextUI
        L8_4()
        L0_1.textUIShown = false
        L0_1.tuneshopOpen = true
        L8_4 = createLocationSpecificShop
        L9_4 = A1_2
        L10_4 = A3_2
        L8_4 = L8_4(L9_4, L10_4)
        L9_4 = L4_2
        if not L9_4 then
          L9_4 = A1_2.id
        end
        L10_4 = _G
        L11_4 = tonumber(L7_2)
        if L11_4 then
          L10_4.tuneshopTargetHeading = L11_4 + 0.0
        else
          L10_4.tuneshopTargetHeading = nil
        end
        L10_4 = _G
        L10_4.tuneshopTargetVehicle = L1_4
        L10_4 = OpenTuneShop
        L11_4 = L4_2
        L12_4 = L8_4
        L13_4 = L9_4
        L14_4 = A0_2
        L10_4(L11_4, L12_4, L13_4, L14_4)
      elseif 0 == L1_4 then
        L2_4 = L0_1.textUIShown
        if L2_4 then
          L2_4 = lib
          L2_4 = L2_4.hideTextUI
          L2_4()
          L0_1.textUIShown = false
        end
      end
      ::lbl_332::
    end
    L1_3.inside = L2_3
    return L0_3(L1_3)
  end
  L12_2, L13_2 = L12_2(L13_2)
  if L12_2 and L13_2 then
    L14_2 = L13_1
    L14_2[A0_2] = L13_2
    return L13_2
  else
    L14_2 = nil
    return L14_2
  end
end
createTuneshopZone = L29_1
function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = {}
  L3_2 = pairs
  L4_2 = A0_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L2_2[L7_2] = L8_2
  end
  L3_2 = A0_2.tuneshopLocations
  if not L3_2 then
    L3_2 = L20_1
    L4_2 = A0_2
    L5_2 = "shopConfig"
    L6_2 = "tuneshopLocations"
    L3_2 = L3_2(L4_2, L5_2, L6_2)
  end
  L4_2 = A1_2 + 1
  if L3_2 then
    L5_2 = L3_2[L4_2]
    if L5_2 then
      L5_2 = L3_2[L4_2]
      L5_2 = L5_2.categorys
      if L5_2 then
        L5_2 = L2_2.shopConfig
        if not L5_2 then
          L5_2 = {}
          L2_2.shopConfig = L5_2
        end
        L5_2 = L2_2.shopConfig
        L6_2 = L3_2[L4_2]
        L6_2 = L6_2.categorys
        L5_2.categorys = L6_2
      end
    end
  end
  return L2_2
end
createLocationSpecificShop = L29_1
function L29_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = 0
  L1_2 = 0
  L2_2 = {}
  L3_2 = pairs
  L4_2 = L13_1
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2 in L3_2, L4_2, L5_2, L6_2 do
    L8_2 = #L2_2
    L8_2 = L8_2 + 1
    L2_2[L8_2] = L7_2
  end
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L13_1
    L9_2 = L9_2[L8_2]
    L10_2 = pcall
    function L11_2()
      local L0_3, L1_3
      L0_3 = L9_2
      if L0_3 then
        L0_3 = L9_2.remove
        if L0_3 then
          L0_3 = L9_2
          L1_3 = L0_3
          L0_3 = L0_3.remove
          L0_3(L1_3)
      end
      else
        L0_3 = lib
        L0_3 = L0_3.zones
        if L0_3 then
          L0_3 = lib
          L0_3 = L0_3.zones
          L0_3 = L0_3.remove
          if L0_3 then
            L0_3 = lib
            L0_3 = L0_3.zones
            L0_3 = L0_3.remove
            L1_3 = L8_2
            L0_3(L1_3)
          end
        end
      end
    end
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L0_2 = L0_2 + 1
    else
      L1_2 = L1_2 + 1
    end
    L11_2 = L13_1
    L11_2[L8_2] = nil
  end
  L3_2 = L0_1.textUIShown
  if L3_2 then
    L3_2 = pcall
    function L4_2()
      local L0_3, L1_3
      L0_3 = lib
      L0_3 = L0_3.hideTextUI
      L0_3()
      L0_1.textUIShown = false
    end
    L3_2(L4_2)
  end
end
cleanupTuneshopZones = L29_1
function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetGameTimer
  L2_2 = L2_2()
  if not A1_2 then
    A1_2 = 0
  end
  L3_2 = L16_1.loading
  if not L3_2 then
    if A0_2 then
      goto lbl_18
    end
    L3_2 = L16_1.lastUpdate
    L3_2 = tonumber(L3_2) or 0
    L3_2 = L2_2 - L3_2
    L4_2 = L16_1.updateInterval
    L4_2 = tonumber(L4_2) or 10000
    if not (L3_2 < L4_2) then
      goto lbl_18
    end
  end
  do return end
  ::lbl_18::
  L3_2 = Config
  L3_2 = L3_2.Tuneshops
  if L3_2 then
    L3_2 = next
    L4_2 = Config
    L4_2 = L4_2.Tuneshops
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_38
    end
  end
  if A1_2 < 5 then
    L3_2 = SetTimeout
    L4_2 = A1_2 * 500
    L4_2 = 1000 + L4_2
    function L5_2()
      local L0_3, L1_3, L2_3
      L0_3 = loadTuneshopZones
      L1_3 = A0_2
      L2_3 = A1_2
      L2_3 = L2_3 + 1
      L0_3(L1_3, L2_3)
    end
    L3_2(L4_2, L5_2)
  end
  do return end
  ::lbl_38::
  L16_1.loading = true
  L16_1.lastUpdate = L2_2
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3, L21_3
    L0_3 = Config
    L0_3 = L0_3.Tuneshops
    if not L0_3 then
      L16_1.loading = false
      return
    end
    L0_3 = next
    L1_3 = Config
    L1_3 = L1_3.Tuneshops
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      L16_1.loading = false
      return
    end
    L0_3 = A0_2
    if L0_3 then
      L0_3 = {}
      L1_3 = pairs
      L2_3 = L13_1
      L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
      for L5_3 in L1_3, L2_3, L3_3, L4_3 do
        L6_3 = #L0_3
        L6_3 = L6_3 + 1
        L0_3[L6_3] = L5_3
      end
      L1_3 = ipairs
      L2_3 = L0_3
      L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
      for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
        L7_3 = L13_1
        L7_3 = L7_3[L6_3]
        L8_3 = pcall
        function L9_3()
          local L0_4, L1_4
          L0_4 = L7_3
          if L0_4 then
            L0_4 = L7_3.remove
            if L0_4 then
              L0_4 = L7_3
              L1_4 = L0_4
              L0_4 = L0_4.remove
              L0_4(L1_4)
          end
          else
            L0_4 = lib
            L0_4 = L0_4.zones
            if L0_4 then
              L0_4 = lib
              L0_4 = L0_4.zones
              L0_4 = L0_4.remove
              if L0_4 then
                L0_4 = lib
                L0_4 = L0_4.zones
                L0_4 = L0_4.remove
                L1_4 = L6_3
                L0_4(L1_4)
              end
            end
          end
        end
        L8_3(L9_3)
        L8_3 = L13_1
        L8_3[L6_3] = nil
      end
      L1_3 = Wait
      L2_3 = 100
      L1_3(L2_3)
    end
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Tuneshops
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3 in L1_3, L2_3, L3_3, L4_3 do
      L0_3 = L0_3 + 1
    end
    L1_3 = 0
    L2_3 = 0
    L3_3 = pairs
    L4_3 = Config
    L4_3 = L4_3.Tuneshops
    L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3)
    for L7_3, L8_3 in L3_3, L4_3, L5_3, L6_3 do
      if L8_3 then
        L9_3 = canUseTuneshop
        L10_3 = L8_3
        L9_3 = L9_3(L10_3)
        if L9_3 then
          L9_3 = L8_3.tuneshopLocations
          if not L9_3 then
            L9_3 = L20_1
            L10_3 = L8_3
            L11_3 = "shopConfig"
            L12_3 = "tuneshopLocations"
            L9_3 = L9_3(L10_3, L11_3, L12_3)
          end
          if L9_3 then
            L10_3 = #L9_3
            if L10_3 > 0 then
              L10_3 = Config
              L10_3 = L10_3.Debug
              if L10_3 then
                L10_3 = print
                L11_3 = "[TUNESHOP DEBUG] Loading shop:"
                L12_3 = L7_3
                L13_3 = "with"
                L14_3 = #L9_3
                L15_3 = "locations"
                L10_3(L11_3, L12_3, L13_3, L14_3, L15_3)
              end
              L10_3 = ipairs
              L11_3 = L9_3
              L10_3, L11_3, L12_3, L13_3 = L10_3(L11_3)
              for L14_3, L15_3 in L10_3, L11_3, L12_3, L13_3 do
                L16_3 = L7_3
                L17_3 = "_tuneshop_"
                L18_3 = L14_3
                L16_3 = L16_3 .. L17_3 .. L18_3
                L17_3 = L13_1
                L17_3 = L17_3[L16_3]
                if not L17_3 then
                  L17_3 = createTuneshopZone
                  L18_3 = L16_3
                  L19_3 = L8_3
                  L20_3 = L15_3
                  L21_3 = L14_3 - 1
                  L17_3 = L17_3(L18_3, L19_3, L20_3, L21_3)
                  if L17_3 then
                    L2_3 = L2_3 + 1
                  end
                end
                L1_3 = L1_3 + 1
                L17_3 = L16_1.maxZonesPerFrame
                L17_3 = L1_3 % L17_3
                if 0 == L17_3 then
                  L17_3 = Wait
                  L18_3 = 100
                  L17_3(L18_3)
                end
              end
          end
          else
            L10_3 = L20_1
            L11_3 = L8_3
            L12_3 = "shopConfig"
            L13_3 = "coords"
            L10_3 = L10_3(L11_3, L12_3, L13_3)
            if not L10_3 then
              L10_3 = L20_1
              L11_3 = L8_3
              L12_3 = "coords"
              L10_3 = L10_3(L11_3, L12_3)
            end
            if L10_3 then
              L11_3 = L13_1
              L11_3 = L11_3[L7_3]
              if not L11_3 then
                L11_3 = createTuneshopZone
                L12_3 = L7_3
                L13_3 = L8_3
                L14_3 = L10_3
                L15_3 = 0
                L11_3 = L11_3(L12_3, L13_3, L14_3, L15_3)
                if L11_3 then
                  L2_3 = L2_3 + 1
                end
              end
              L1_3 = L1_3 + 1
              L11_3 = L16_1.maxZonesPerFrame
              L11_3 = tonumber(L11_3) or 2
              if L11_3 > 0 then
                L11_3 = L1_3 % L11_3
              else
                L11_3 = 0
              end
              if 0 == L11_3 then
                L11_3 = Wait
                L12_3 = 100
                L11_3(L12_3)
              end
            end
          end
        end
      end
      L9_3 = Wait
      L10_3 = 50
      L9_3(L10_3)
    end
    L16_1.loading = false
    L3_3 = L17_1.operationCount
    L3_3 = L3_3 + 1
    L17_1.operationCount = L3_3
  end
  L3_2(L4_2)
end
loadTuneshopZones = L29_1
function L29_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = GetVehiclePedIsIn
  L6_2 = L4_2
  L7_2 = false
  L5_2 = L5_2(L6_2, L7_2)
  if 0 == L5_2 then
    L6_2 = showClientNotification
    L7_2 = {}
    L8_2 = _U
    L9_2 = "TUNESHOP"
    L8_2 = L8_2(L9_2)
    L7_2.title = L8_2
    L8_2 = _U
    L9_2 = "MUST_BE_IN_VEHICLE"
    L8_2 = L8_2(L9_2)
    L7_2.description = L8_2
    L7_2.type = "error"
    L6_2(L7_2)
    if A3_2 then
      L6_2 = L15_1
      L6_2[A3_2] = false
      L6_2 = TriggerServerEvent
      L7_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
      L8_2 = A3_2
      L9_2 = false
      L6_2(L7_2, L8_2, L9_2)
    end
    return
  end
  if not A1_2 then
    if A3_2 then
      L6_2 = L15_1
      L6_2[A3_2] = false
      L6_2 = TriggerServerEvent
      L7_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
      L8_2 = A3_2
      L9_2 = false
      L6_2(L7_2, L8_2, L9_2)
    end
    return
  end
  L6_2 = InitializeTuneshop
  if not L6_2 then
    L6_2 = print
    L7_2 = "^1[qs-mechanic-creator]^0 InitializeTuneshop mancante — verifica errori tunes.lua in console avvio resource"
    L6_2(L7_2)
    L0_1.tuneshopOpen = false
    if A3_2 then
      L6_2 = L15_1
      L6_2[A3_2] = false
      L6_2 = TriggerServerEvent
      L7_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
      L8_2 = A3_2
      L9_2 = false
      L6_2(L7_2, L8_2, L9_2)
    end
    return
  end
  L7_2 = A1_2
  L8_2 = A2_2
  L9_2 = A3_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if not L6_2 then
    L0_1.tuneshopOpen = false
    if A3_2 then
      L6_2 = L15_1
      L6_2[A3_2] = false
      L6_2 = TriggerServerEvent
      L7_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
      L8_2 = A3_2
      L9_2 = false
      L6_2(L7_2, L8_2, L9_2)
    end
    return
  end
end
OpenTuneShop = L29_1
function L29_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1.initialized
  if L1_2 then
    if A0_2 then
      L1_2 = A0_2
      L2_2 = true
      L1_2(L2_2)
    end
    return
  end
  L1_2 = lib
  if not L1_2 then
    L1_2 = 0
    while true do
      L2_2 = lib
      if not (not L2_2 and L1_2 < 50) then
        break
      end
      L2_2 = Wait
      L3_2 = 200
      L2_2(L3_2)
      L1_2 = L1_2 + 1
    end
    L2_2 = lib
    if not L2_2 then
      L0_1.configsLoaded = true
      L0_1.initialized = true
      L2_2 = CreateThread
      function L3_2()
        local L0_3, L1_3
        L0_3 = Wait
        L1_3 = 5000
        L0_3(L1_3)
        L0_3 = TriggerServerEvent
        L1_3 = "qs-mechanic-creator:server:getMechanicShopsForceSync"
        L0_3(L1_3)
      end
      L2_2(L3_2)
      if A0_2 then
        L2_2 = A0_2
        L3_2 = true
        L2_2(L3_2)
      end
      return
    end
  end
  L1_2 = L26_1
  function L2_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    if A1_3 then
      L2_3 = A1_3.wheeldamage
      L4_1.WheelDamage = L2_3
      L2_3 = A1_3.offroadsystem
      L4_1.OffroadSystem = L2_3
      L2_3 = A1_3.heatedbrakes
      L4_1.HeatedBrakes = L2_3
    end
    L2_3 = lib
    L2_3 = L2_3.callback
    L3_3 = "qs-mechanic-creator:server:initializePlayer"
    L4_3 = false
    function L5_3(A0_4)
      local L1_4, L2_4
      if A0_4 then
        L0_1.initialized = true
        L1_4 = TriggerEvent
        L2_4 = "qs-mechanic-creator:client:playerLoaded"
        L1_4(L2_4)
        L1_4 = CreateThread
        function L2_4()
          local L0_5, L1_5
          L0_5 = Wait
          L1_5 = 500
          L0_5(L1_5)
          L0_5 = L0_1.shopsLoaded
          if not L0_5 then
            L0_5 = TriggerServerEvent
            L1_5 = "qs-mechanic-creator:server:getMechanicShopsForceSync"
            L0_5(L1_5)
          end
        end
        L1_4(L2_4)
      else
        L0_1.configsLoaded = true
        L0_1.initialized = true
        L1_4 = CreateThread
        function L2_4()
          local L0_5, L1_5
          L0_5 = Wait
          L1_5 = 5000
          L0_5(L1_5)
          L0_5 = TriggerServerEvent
          L1_5 = "qs-mechanic-creator:server:getMechanicShopsForceSync"
          L0_5(L1_5)
        end
        L1_4(L2_4)
      end
      L1_4 = A0_2
      if L1_4 then
        L1_4 = A0_2
        L2_4 = true
        L1_4(L2_4)
      end
    end
    L2_3(L3_3, L4_3, L5_3)
  end
  L1_2(L2_2)
end
L18_1 = L29_1
L29_1 = RegisterNUICallback
L30_1 = "closeTuneshopUI"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = pcall
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3
    L0_3 = SetNuiFocus
    L1_3 = false
    L2_3 = false
    L0_3(L1_3, L2_3)
    L0_3 = SetNuiFocusKeepInput
    L1_3 = false
    L0_3(L1_3)
    L0_1.tuneshopOpen = false
    L0_3 = CloseTuneshop
    L0_3()
    L0_3 = PlayerPedId
    L0_3 = L0_3()
    L1_3 = GetVehiclePedIsIn
    L2_3 = L0_3
    L3_3 = false
    L1_3 = L1_3(L2_3, L3_3)
    if 0 ~= L1_3 then
      L2_3 = GetEntityCoords
      L3_3 = L0_3
      L2_3 = L2_3(L3_3)
      L3_3 = false
      L4_3 = 0
      L5_3 = pairs
      L6_3 = Config
      L6_3 = L6_3.Tuneshops
      if not L6_3 then
        L6_3 = {}
      end
      L5_3, L6_3, L7_3, L8_3 = L5_3(L6_3)
      for L9_3, L10_3 in L5_3, L6_3, L7_3, L8_3 do
        L11_3 = L20_1
        L12_3 = L10_3
        L13_3 = "shopConfig"
        L14_3 = "coords"
        L11_3 = L11_3(L12_3, L13_3, L14_3)
        if not L11_3 then
          L11_3 = L20_1
          L12_3 = L10_3
          L13_3 = "coords"
          L11_3 = L11_3(L12_3, L13_3)
        end
        if L11_3 then
          L12_3 = vector3
          L13_3 = L11_3.x
          L14_3 = L11_3.y
          L15_3 = L11_3.z
          L12_3 = L12_3(L13_3, L14_3, L15_3)
          L12_3 = L2_3 - L12_3
          L12_3 = #L12_3
          if L12_3 < 8.0 then
            L13_3 = L19_1
            L14_3 = _U
            L15_3 = "PRESS_E_TUNESHOP"
            L14_3, L15_3, L16_3, L17_3, L18_3 = L14_3(L15_3)
            L13_3 = L13_3(L14_3, L15_3, L16_3, L17_3, L18_3)
            L14_3 = "[E] - "
            L15_3 = L13_3
            L14_3 = L14_3 .. L15_3
            L15_3 = lib
            L15_3 = L15_3.showTextUI
            L16_3 = L14_3
            L17_3 = {}
            L18_3 = Config
            L18_3 = L18_3.TextPosition
            L17_3.position = L18_3
            L17_3.icon = "fa-solid fa-wrench"
            L18_3 = {}
            L18_3.borderRadius = 5
            L18_3.backgroundColor = "rgba(0, 0, 0, 0.8)"
            L18_3.color = "white"
            L17_3.style = L18_3
            L15_3(L16_3, L17_3)
            L0_1.textUIShown = true
            L3_3 = true
            break
          end
        end
        L4_3 = L4_3 + 1
        if L4_3 >= 10 then
          break
        end
      end
    end
  end
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = A1_2
    L4_2 = "ok"
    L3_2(L4_2)
  else
    L3_2 = A1_2
    L4_2 = "error"
    L3_2(L4_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "closeMechanicUI"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = pcall
  function L3_2()
    local L0_3, L1_3
    L0_3 = closeMechanicUI
    L0_3()
  end
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2
  if L2_2 then
    L4_2 = "ok"
    if L4_2 then
      goto lbl_11
    end
  end
  L4_2 = "error"
  ::lbl_11::
  L3_2(L4_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "closeCreatorUI"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = pcall
  function L3_2()
    local L0_3, L1_3, L2_3
    L0_3 = SetNuiFocus
    L1_3 = false
    L2_3 = false
    L0_3(L1_3, L2_3)
    L0_3 = SetNuiFocusKeepInput
    L1_3 = false
    L0_3(L1_3)
    L0_1.creatorOpen = false
    L0_3 = L22_1
    L0_3()
  end
  L2_2 = L2_2(L3_2)
  L3_2 = A1_2
  if L2_2 then
    L4_2 = "ok"
    if L4_2 then
      goto lbl_11
    end
  end
  L4_2 = "error"
  ::lbl_11::
  L3_2(L4_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "createMechanic"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if not A0_2 then
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.error = "No data provided"
    L2_2(L3_2)
    return
  end
  L2_2 = lib
  L2_2 = L2_2.callback
  L3_2 = "qs-mechanic-creator:server:createMechanic"
  L4_2 = false
  function L5_2(A0_3, A1_3, A2_3, A3_3)
    local L4_3, L5_3, L6_3, L7_3
    if A0_3 then
      L4_3 = showClientNotification
      L5_3 = {}
      L6_3 = _U
      L7_3 = "MECHANIC_CREATED"
      L6_3 = L6_3(L7_3)
      L5_3.title = L6_3
      L6_3 = _U
      L7_3 = "MECHANIC_CREATED_SUCCESS"
      L6_3 = L6_3(L7_3)
      L5_3.description = L6_3
      L5_3.type = "success"
      L4_3(L5_3)
      if A2_3 then
        L4_3 = Config
        L4_3.Tuneshops = A2_3
      end
      if A3_3 then
        L4_3 = TriggerEvent
        L5_3 = "qs-mechanic-creator:client:syncCarlifts"
        L6_3 = A3_3
        L4_3(L5_3, L6_3)
      end
      L4_3 = TriggerEvent
      L5_3 = "qs-mechanic-creator:client:updateWardrobes"
      L4_3(L5_3)
      L4_3 = L0_1.creatorOpen
      if L4_3 then
        L4_3 = SafeSendNUIMessage
        L5_3 = {}
        L5_3.type = "updateShops"
        L6_3 = A3_3 or L6_3
        L6_3 = A2_3 or L6_3
        if not A3_3 and not A2_3 then
          L6_3 = Config
          L6_3 = L6_3.Tuneshops
          if not L6_3 then
            L6_3 = {}
          end
        end
        L5_3.shops = L6_3
        L4_3(L5_3)
      end
      L4_3 = A1_2
      L5_3 = {}
      L5_3.success = true
      L5_3.shopId = A1_3
      L6_3 = A3_3 or L6_3
      if not A3_3 then
        L6_3 = A2_3
      end
      L5_3.shops = L6_3
      L4_3(L5_3)
    else
      L4_3 = showClientNotification
      L5_3 = {}
      L6_3 = _U
      L7_3 = "CREATION_FAILED"
      L6_3 = L6_3(L7_3)
      L5_3.title = L6_3
      L6_3 = _U
      L7_3 = "FAILED_CREATE_MECHANIC"
      L6_3 = L6_3(L7_3)
      L5_3.description = L6_3
      L5_3.type = "error"
      L4_3(L5_3)
      L4_3 = A1_2
      L5_3 = {}
      L5_3.success = false
      L5_3.error = "Creation failed"
      L4_3(L5_3)
    end
  end
  L6_2 = A0_2
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "deleteMechanic"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = A0_2.shopId
    if L2_2 then
      goto lbl_13
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.error = "Invalid shop ID"
  L2_2(L3_2)
  do return end
  ::lbl_13::
  L2_2 = lib
  L2_2 = L2_2.callback
  L3_2 = "qs-mechanic-creator:server:deleteMechanic"
  L4_2 = false
  function L5_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    if A0_3 then
      L1_3 = showClientNotification
      L2_3 = {}
      L3_3 = _U
      L4_3 = "MECHANIC_DELETED"
      L3_3 = L3_3(L4_3)
      L2_3.title = L3_3
      L3_3 = _U
      L4_3 = "MECHANIC_DELETED_SUCCESS"
      L3_3 = L3_3(L4_3)
      L2_3.description = L3_3
      L2_3.type = "success"
      L1_3(L2_3)
      L1_3 = lib
      L1_3 = L1_3.callback
      L2_3 = "qs-mechanic-creator:server:getMechanicShops"
      L3_3 = false
      function L4_3(A0_4)
        local L1_4, L2_4, L3_4
        L1_4 = L0_1.creatorOpen
        if L1_4 then
          L1_4 = SafeSendNUIMessage
          L2_4 = {}
          L2_4.type = "updateShops"
          L3_4 = A0_4 or L3_4
          if not A0_4 then
            L3_4 = {}
          end
          L2_4.shops = L3_4
          L1_4(L2_4)
        end
      end
      L1_3(L2_3, L3_3, L4_3)
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = true
      L1_3(L2_3)
    else
      L1_3 = showClientNotification
      L2_3 = {}
      L3_3 = _U
      L4_3 = "DELETION_FAILED"
      L3_3 = L3_3(L4_3)
      L2_3.title = L3_3
      L3_3 = _U
      L4_3 = "FAILED_DELETE_MECHANIC"
      L3_3 = L3_3(L4_3)
      L2_3.description = L3_3
      L2_3.type = "error"
      L1_3(L2_3)
      L1_3 = A1_2
      L2_3 = {}
      L2_3.success = false
      L2_3.error = "Deletion failed"
      L1_3(L2_3)
    end
  end
  L6_2 = A0_2.shopId
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "updateMechanic"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 then
    L2_2 = A0_2.shopId
    if L2_2 then
      L2_2 = A0_2.shopData
      if L2_2 then
        goto lbl_16
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.error = "Invalid data"
  L2_2(L3_2)
  do return end
  ::lbl_16::
  L2_2 = lib
  L2_2 = L2_2.callback
  L3_2 = "qs-mechanic-creator:server:updateMechanic"
  L4_2 = false
  function L5_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3
    if A0_3 then
      L3_3 = showClientNotification
      L4_3 = {}
      L5_3 = _U
      L6_3 = "MECHANIC_UPDATED"
      L5_3 = L5_3(L6_3)
      L4_3.title = L5_3
      L5_3 = _U
      L6_3 = "MECHANIC_UPDATED_SUCCESS"
      L5_3 = L5_3(L6_3)
      L4_3.description = L5_3
      L4_3.type = "success"
      L3_3(L4_3)
      if A1_3 then
        L3_3 = Config
        L3_3.Tuneshops = A1_3
      end
      if A2_3 then
        L3_3 = TriggerEvent
        L4_3 = "qs-mechanic-creator:client:syncCarlifts"
        L5_3 = A2_3
        L3_3(L4_3, L5_3)
      end
      L3_3 = TriggerEvent
      L4_3 = "qs-mechanic-creator:client:updateWardrobes"
      L3_3(L4_3)
      L3_3 = L0_1.creatorOpen
      if L3_3 then
        L3_3 = SafeSendNUIMessage
        L4_3 = {}
        L4_3.type = "updateShops"
        L5_3 = A2_3 or L5_3
        L5_3 = A1_3 or L5_3
        if not A2_3 and not A1_3 then
          L5_3 = Config
          L5_3 = L5_3.Tuneshops
          if not L5_3 then
            L5_3 = {}
          end
        end
        L4_3.shops = L5_3
        L5_3 = A2_3 or L5_3
        if not A2_3 then
          L5_3 = {}
        end
        L4_3.data = L5_3
        L3_3(L4_3)
      end
      L3_3 = A1_2
      L4_3 = {}
      L4_3.success = true
      L5_3 = A2_3 or L5_3
      if not A2_3 then
        L5_3 = A1_3
      end
      L4_3.shops = L5_3
      L4_3.rawShops = A2_3
      L3_3(L4_3)
    else
      L3_3 = showClientNotification
      L4_3 = {}
      L5_3 = _U
      L6_3 = "UPDATE_FAILED"
      L5_3 = L5_3(L6_3)
      L4_3.title = L5_3
      L5_3 = _U
      L6_3 = "FAILED_UPDATE_MECHANIC"
      L5_3 = L5_3(L6_3)
      L4_3.description = L5_3
      L4_3.type = "error"
      L3_3(L4_3)
      L3_3 = A1_2
      L4_3 = {}
      L4_3.success = false
      L4_3.error = "Update failed"
      L3_3(L4_3)
    end
  end
  L6_2 = A0_2.shopId
  L7_2 = A0_2.shopData
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "startPlacement"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = A0_2.objectType
    if L2_2 then
      goto lbl_10
    end
  end
  L2_2 = A1_2
  L3_2 = "error"
  L2_2(L3_2)
  do return end
  ::lbl_10::
  L0_1.creatorOpen = false
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = SetNuiFocusKeepInput
  L3_2 = false
  L2_2(L3_2)
  L0_1.isPlacingShop = true
  L2_2 = A0_2.placementType
  if not L2_2 then
    L2_2 = "tuneshop"
  end
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = Wait
    L1_3 = 100
    L0_3(L1_3)
    L0_3 = getPosition
    L1_3 = A0_2.objectType
    L2_3 = A0_2.model
    L3_3 = A0_2.extraProps
    L0_3 = L0_3(L1_3, L2_3, L3_3)
    L0_1.isPlacingShop = false
    L0_1.creatorOpen = true
    L1_3 = Wait
    L2_3 = 100
    L1_3(L2_3)
    if L0_3 then
      L1_3 = SafeSendNUIMessage
      L2_3 = {}
      L2_3.type = "placementComplete"
      L3_3 = L2_2
      L2_3.placementType = L3_3
      L3_3 = {}
      L4_3 = L0_3.x
      L3_3.x = L4_3
      L4_3 = L0_3.y
      L3_3.y = L4_3
      L4_3 = L0_3.z
      L3_3.z = L4_3
      L4_3 = L0_3.w
      L3_3.w = L4_3
      L2_3.coords = L3_3
      L1_3(L2_3)
    else
      L1_3 = SafeSendNUIMessage
      L2_3 = {}
      L2_3.type = "placementCancelled"
      L3_3 = L2_2
      L2_3.placementType = L3_3
      L1_3(L2_3)
    end
    L1_3 = Wait
    L2_3 = 50
    L1_3(L2_3)
    L1_3 = SetNuiFocus
    L2_3 = true
    L3_3 = true
    L1_3(L2_3, L3_3)
    L1_3 = SetNuiFocusKeepInput
    L2_3 = false
    L1_3(L2_3)
  end
  L3_2(L4_2)
  L3_2 = A1_2
  L4_2 = "ok"
  L3_2(L4_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "playSound"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = A0_2.sound
    if L2_2 then
      goto lbl_7
    end
  end
  L2_2 = "SELECT"
  ::lbl_7::
  if A0_2 then
    L3_2 = A0_2.set
    if L3_2 then
      goto lbl_13
    end
  end
  L3_2 = "HUD_FREEMODE_SOUNDSET"
  ::lbl_13::
  L4_2 = playSound
  L5_2 = L2_2
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = A1_2
  L5_2 = "ok"
  L4_2(L5_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "teleportToBlip"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if A0_2 then
    L2_2 = A0_2.x
    if L2_2 then
      L2_2 = A0_2.y
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
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = GetVehiclePedIsIn
  L4_2 = L2_2
  L5_2 = false
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = A0_2.x
  L5_2 = A0_2.y
  L6_2 = GetEntityCoords
  L7_2 = L2_2
  L6_2 = L6_2(L7_2)
  L6_2 = L6_2.z
  if 0 ~= L3_2 then
    L7_2 = SetEntityCoords
    L8_2 = L3_2
    L9_2 = L4_2
    L10_2 = L5_2
    L11_2 = L6_2
    L12_2 = false
    L13_2 = false
    L14_2 = false
    L15_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L7_2 = SetPedIntoVehicle
    L8_2 = L2_2
    L9_2 = L3_2
    L10_2 = -1
    L7_2(L8_2, L9_2, L10_2)
  else
    L7_2 = SetEntityCoords
    L8_2 = L2_2
    L9_2 = L4_2
    L10_2 = L5_2
    L11_2 = L6_2
    L12_2 = false
    L13_2 = false
    L14_2 = false
    L15_2 = true
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  end
  L7_2 = playSound
  L7_2()
  L7_2 = A1_2
  L8_2 = "ok"
  L7_2(L8_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "getConfig"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = A0_2.section
    if L2_2 then
      goto lbl_11
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L2_2(L3_2)
  do return end
  ::lbl_11::
  L2_2 = nil
  L3_2 = A0_2.section
  if "wheeldamage" == L3_2 then
    L3_2 = getWheelDamageConfig
    L3_2 = L3_2()
    L2_2 = L3_2
  else
    L3_2 = A0_2.section
    if "offroadsystem" == L3_2 then
      L3_2 = getOffroadSystemConfig
      L3_2 = L3_2()
      L2_2 = L3_2
    else
      L3_2 = A0_2.section
      if "heatedbrakes" == L3_2 then
        L3_2 = getHeatedBrakesConfig
        L3_2 = L3_2()
        L2_2 = L3_2
      end
    end
  end
  L3_2 = A1_2
  L4_2 = L2_2 or L4_2
  if not L2_2 then
    L4_2 = {}
  end
  L3_2(L4_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "saveConfig"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.section
    if L2_2 then
      L2_2 = A0_2.data
      if L2_2 then
        goto lbl_15
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L2_2(L3_2)
  do return end
  ::lbl_15::
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:saveConfig"
  L4_2 = A0_2.section
  L5_2 = A0_2.data
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = true
  L2_2(L3_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "resetConfig"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = A0_2.section
    if L2_2 then
      goto lbl_12
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L2_2(L3_2)
  do return end
  ::lbl_12::
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:resetConfig"
  L4_2 = A0_2.section
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = true
  L2_2(L3_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "setNuiFocus"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SetNuiFocus
  L3_2 = A0_2.focus
  L4_2 = A0_2.cursor
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "triggerSync"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = TriggerServerEvent
  L3_2 = "qs-mechanic-creator:server:getMechanicShopsForceSync"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "showNotification"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 then
    L2_2 = A0_2.message
    if L2_2 then
      goto lbl_10
    end
  end
  L2_2 = A1_2
  L3_2 = "error"
  L2_2(L3_2)
  do return end
  ::lbl_10::
  L2_2 = lib
  if L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L4_2 = A0_2.title
    if not L4_2 then
      L4_2 = _U
      L5_2 = "NOTIFICATION"
      L4_2 = L4_2(L5_2)
    end
    L3_2.title = L4_2
    L4_2 = A0_2.message
    L3_2.description = L4_2
    L4_2 = A0_2.type
    if not L4_2 then
      L4_2 = "info"
    end
    L3_2.type = L4_2
    L2_2(L3_2)
  else
    L2_2 = lib
    L2_2 = L2_2.print
    L2_2 = L2_2.debug
    L3_2 = string
    L3_2 = L3_2.format
    L4_2 = "[%s] %s"
    L5_2 = A0_2.title
    if not L5_2 then
      L5_2 = _U
      L6_2 = "NOTIFICATION"
      L5_2 = L5_2(L6_2)
    end
    L6_2 = A0_2.message
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNUICallback
L30_1 = "showTextInput"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if A0_2 then
    L2_2 = A0_2.title
    if L2_2 then
      goto lbl_13
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.success = false
  L3_2.text = ""
  L2_2(L3_2)
  do return end
  ::lbl_13::
  L2_2 = lib
  if L2_2 then
    L2_2 = lib
    L2_2 = L2_2.inputDialog
    L3_2 = A0_2.title
    L4_2 = {}
    L5_2 = {}
    L5_2.type = "input"
    L6_2 = A0_2.label
    if not L6_2 then
      L6_2 = _U
      L7_2 = "ENTER_TEXT"
      L6_2 = L6_2(L7_2)
    end
    L5_2.label = L6_2
    L6_2 = A0_2.description
    if not L6_2 then
      L6_2 = ""
    end
    L5_2.description = L6_2
    L6_2 = A0_2.required
    if not L6_2 then
      L6_2 = false
    end
    L5_2.required = L6_2
    L6_2 = A0_2.maxLength
    if not L6_2 then
      L6_2 = 100
    end
    L5_2.max = L6_2
    L4_2[1] = L5_2
    L2_2 = L2_2(L3_2, L4_2)
    if L2_2 then
      L3_2 = A1_2
      L4_2 = {}
      L4_2.success = true
      L5_2 = L2_2[1]
      if not L5_2 then
        L5_2 = ""
      end
      L4_2.text = L5_2
      L3_2(L4_2)
    else
      L3_2 = A1_2
      L4_2 = {}
      L4_2.success = false
      L4_2.text = ""
      L3_2(L4_2)
    end
  else
    L2_2 = A1_2
    L3_2 = {}
    L3_2.success = false
    L3_2.text = ""
    L2_2(L3_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 then
    return
  end
  L1_2 = 0
  L2_2 = {}
  L3_2 = pairs
  L4_2 = L13_1
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2 in L3_2, L4_2, L5_2, L6_2 do
    L8_2 = string
    L8_2 = L8_2.find
    L9_2 = L7_2
    L10_2 = A0_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L8_2 = #L2_2
      L8_2 = L8_2 + 1
      L2_2[L8_2] = L7_2
    end
  end
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L13_1
    L9_2 = L9_2[L8_2]
    L10_2 = pcall
    function L11_2()
      local L0_3, L1_3
      L0_3 = L9_2
      if L0_3 then
        L0_3 = L9_2.remove
        if L0_3 then
          L0_3 = L9_2
          L1_3 = L0_3
          L0_3 = L0_3.remove
          L0_3(L1_3)
        end
      end
      L0_3 = L1_2
      L0_3 = L0_3 + 1
      L1_2 = L0_3
    end
    L10_2(L11_2)
    L10_2 = L13_1
    L10_2[L8_2] = nil
  end
  L3_2 = L12_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L3_2 = DoesBlipExist
    L4_2 = L12_1
    L4_2 = L4_2[A0_2]
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = RemoveBlip
      L4_2 = L12_1
      L4_2 = L4_2[A0_2]
      L3_2(L4_2)
    end
    L3_2 = L12_1
    L3_2[A0_2] = nil
  end
  L3_2 = Config
  L3_2 = L3_2.Tuneshops
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Tuneshops
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Tuneshops
      L3_2[A0_2] = nil
    end
  end
  L3_2 = Config
  L3_2 = L3_2.Shops
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Shops
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Shops
      L3_2[A0_2] = nil
    end
  end
  L3_2 = Config
  L3_2 = L3_2.Stashes
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.Stashes
    L3_2 = L3_2[A0_2]
    if L3_2 then
      L3_2 = Config
      L3_2 = L3_2.Stashes
      L3_2[A0_2] = nil
    end
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:syncShops"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = Config
  L2_2 = A0_2 or L2_2
  if not A0_2 then
    L2_2 = {}
  end
  L1_2.Tuneshops = L2_2
  L1_2 = pcall
  function L2_2()
    local L0_3, L1_3
    L0_3 = shopAccessCache
    if L0_3 then
      L0_3 = {}
      shopAccessCache = L0_3
    end
  end
  L1_2(L2_2)
  L1_2 = 0
  L2_2 = pairs
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = {}
  end
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L1_2 = L1_2 + 1
  end
  L2_2 = Config
  L3_2 = {}
  L2_2.Shops = L3_2
  L2_2 = Config
  L3_2 = {}
  L2_2.Stashes = L3_2
  L2_2 = Config
  L3_2 = {}
  L2_2.Garages = L3_2
  L2_2 = Config
  L3_2 = {}
  L2_2.Wardrobes = L3_2
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3, L21_3, L22_3, L23_3
    L0_3 = 0
    L1_3 = pairs
    L2_3 = A0_2
    if not L2_3 then
      L2_3 = {}
    end
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L6_3.shops
      if L7_3 then
        L7_3 = L6_3.shops
        L7_3 = L7_3.enabled
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Shops
          L8_3 = {}
          L9_3 = L6_3.shops
          L9_3 = L9_3.enabled
          L8_3.enabled = L9_3
          L9_3 = {}
          L8_3.locations = L9_3
          L7_3[L5_3] = L8_3
          L7_3 = L6_3.shops
          L7_3 = L7_3.locations
          if L7_3 then
            L7_3 = ipairs
            L8_3 = L6_3.shops
            L8_3 = L8_3.locations
            L7_3, L8_3, L9_3, L10_3 = L7_3(L8_3)
            for L11_3, L12_3 in L7_3, L8_3, L9_3, L10_3 do
              L13_3 = {}
              L14_3 = L12_3.x
              L13_3.x = L14_3
              L14_3 = L12_3.y
              L13_3.y = L14_3
              L14_3 = L12_3.z
              L13_3.z = L14_3
              L14_3 = L12_3.w
              L13_3.w = L14_3
              L14_3 = {}
              L13_3.items = L14_3
              L14_3 = L12_3.items
              if L14_3 then
                L14_3 = type
                L15_3 = L12_3.items
                L14_3 = L14_3(L15_3)
                if "table" == L14_3 then
                  L14_3 = ipairs
                  L15_3 = L12_3.items
                  L14_3, L15_3, L16_3, L17_3 = L14_3(L15_3)
                  for L18_3, L19_3 in L14_3, L15_3, L16_3, L17_3 do
                    L20_3 = table
                    L20_3 = L20_3.insert
                    L21_3 = L13_3.items
                    L22_3 = {}
                    L23_3 = L19_3.item
                    L22_3.item = L23_3
                    L23_3 = L19_3.label
                    L22_3.label = L23_3
                    L23_3 = L19_3.price
                    L22_3.price = L23_3
                    L20_3(L21_3, L22_3)
                  end
                end
              end
              L14_3 = table
              L14_3 = L14_3.insert
              L15_3 = Config
              L15_3 = L15_3.Shops
              L15_3 = L15_3[L5_3]
              L15_3 = L15_3.locations
              L16_3 = L13_3
              L14_3(L15_3, L16_3)
            end
          end
        end
      end
      L7_3 = L6_3.stashes
      if L7_3 then
        L7_3 = L6_3.stashes
        L7_3 = L7_3.enabled
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Stashes
          L8_3 = L6_3.stashes
          L7_3[L5_3] = L8_3
        end
      end
      L7_3 = L6_3.garages
      if L7_3 then
        L7_3 = L6_3.garages
        L7_3 = L7_3.enabled
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Garages
          L8_3 = L6_3.garages
          L7_3[L5_3] = L8_3
        end
      end
      L7_3 = L6_3.wardrobe
      if L7_3 then
        L7_3 = L6_3.wardrobe
        L7_3 = L7_3.enabled
        if L7_3 then
          L7_3 = Config
          L7_3 = L7_3.Wardrobes
          L8_3 = L6_3.wardrobe
          L7_3[L5_3] = L8_3
        end
      end
      L0_3 = L0_3 + 1
      L7_3 = L0_3 % 10
      if 0 == L7_3 then
        L7_3 = Wait
        L8_3 = 30
        L7_3(L8_3)
      end
    end
  end
  L2_2(L3_2)
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    L0_3 = L24_1
    L0_3()
    L0_3 = Wait
    L1_3 = 50
    L0_3(L1_3)
    L0_3 = 0
    L1_3 = pairs
    L2_3 = Config
    L2_3 = L2_3.Tuneshops
    if not L2_3 then
      L2_3 = {}
    end
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = L25_1
      L8_3 = L5_3
      L9_3 = L6_3
      L7_3(L8_3, L9_3)
      L0_3 = L0_3 + 1
      L7_3 = L0_3 % 10
      if 0 == L7_3 then
        L7_3 = Wait
        L8_3 = 30
        L7_3(L8_3)
      end
    end
    L1_3 = Wait
    L2_3 = 300
    L1_3(L2_3)
    L1_3 = loadTuneshopZones
    L2_3 = true
    L1_3(L2_3)
  end
  L2_2(L3_2)
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3
    L0_3 = Wait
    L1_3 = 250
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:updateShops"
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:updateStashes"
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:updateGarages"
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:updateWardrobes"
    L0_3(L1_3)
  end
  L2_2(L3_2)
  L0_1.shopsLoaded = true
end
L29_1(L30_1, L31_1)
L29_1 = AddEventHandler
L30_1 = "qs-mechanic-creator:client:updateTuneshops"
function L31_1()
  local L0_2, L1_2, L2_2
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L1_2 = L16_1.lastUpdate
  L1_2 = tonumber(L1_2) or 0
  L1_2 = L0_2 - L1_2
  L2_2 = 10000
  if L1_2 < L2_2 then
    return
  end
  L16_1.lastUpdate = L0_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3
    L0_3 = Wait
    L1_3 = 2000
    L0_3(L1_3)
    L0_3 = loadTuneshopZones
    L1_3 = true
    L0_3(L1_3)
  end
  L1_2(L2_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:updateCreatorUI"
function L31_1(A0_2)
  local L1_2, L2_2
  L1_2 = L0_1.creatorOpen
  if L1_2 and A0_2 then
    L1_2 = SafeSendNUIMessage
    L2_2 = {}
    L2_2.type = "updateShops"
    L2_2.data = A0_2
    L1_2(L2_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:setWheelDamage"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2
  L4_1.WheelDamage = A0_2
  L1_2 = L0_1.creatorOpen
  if L1_2 then
    L1_2 = SafeSendNUIMessage
    L2_2 = {}
    L2_2.type = "updateConfig"
    L2_2.section = "wheeldamage"
    L3_2 = getWheelDamageConfig
    L3_2 = L3_2()
    L2_2.data = L3_2
    L1_2(L2_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:setOffroadSystem"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L4_1.OffroadSystem = A0_2
  L1_2 = {}
  L2_2 = A0_2.enabled
  if not L2_2 then
    L2_2 = true
  end
  L1_2.active = L2_2
  L2_2 = A0_2.excludedZones
  if not L2_2 then
    L2_2 = {}
  end
  L1_2.excludedZones = L2_2
  L2_2 = A0_2.blacklistedVehicles
  if not L2_2 then
    L2_2 = {}
    L3_2 = "rcbandito"
    L4_2 = "monster"
    L5_2 = "rhino"
    L6_2 = "scarab"
    L7_2 = "khanjali"
    L2_2[1] = L3_2
    L2_2[2] = L4_2
    L2_2[3] = L5_2
    L2_2[4] = L6_2
    L2_2[5] = L7_2
  end
  L1_2.blacklistedVehicles = L2_2
  L2_2 = TriggerEvent
  L3_2 = "advanced-mechanic:client:setTerrainSystem"
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = L0_1.creatorOpen
  if L2_2 then
    L2_2 = SafeSendNUIMessage
    L3_2 = {}
    L3_2.type = "updateConfig"
    L3_2.section = "offroadsystem"
    L4_2 = getOffroadSystemConfig
    L4_2 = L4_2()
    L3_2.data = L4_2
    L2_2(L3_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:setHeatedBrakes"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2
  if A0_2 then
    L1_2 = A0_2.vehicleOverrides
    if L1_2 then
      function L1_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
        L1_3 = type
        L2_3 = A0_3
        L1_3 = L1_3(L2_3)
        if "table" ~= L1_3 then
          return A0_3
        end
        L1_3 = setmetatable
        L2_3 = A0_3
        L3_3 = {}
        L3_3.__jsontype = "object"
        L1_3(L2_3, L3_3)
        L1_3 = pairs
        L2_3 = A0_3
        L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
        for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
          L7_3 = type
          L8_3 = L6_3
          L7_3 = L7_3(L8_3)
          if "table" == L7_3 then
            L7_3 = L1_2
            L8_3 = L6_3
            L7_3(L8_3)
          end
        end
        return A0_3
      end
      L2_2 = L1_2
      L3_2 = A0_2.vehicleOverrides
      L2_2(L3_2)
    end
  end
  L4_1.HeatedBrakes = A0_2
  L1_2 = L0_1.creatorOpen
  if L1_2 then
    L1_2 = SafeSendNUIMessage
    L2_2 = {}
    L2_2.type = "updateConfig"
    L2_2.section = "heatedbrakes"
    L3_2 = getHeatedBrakesConfig
    L3_2 = L3_2()
    L2_2.data = L3_2
    L1_2(L2_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:tuneshopClosed"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_1.tuneshopOpen = false
  L0_1.textUIShown = false
  if A0_2 then
    L1_2 = L15_1
    L1_2[A0_2] = false
    L1_2 = TriggerServerEvent
    L2_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
    L3_2 = A0_2
    L4_2 = false
    L1_2(L2_2, L3_2, L4_2)
  else
    L1_2 = pairs
    L2_2 = L15_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = L15_1
      L7_2[L5_2] = false
      L7_2 = TriggerServerEvent
      L8_2 = "qs-mechanic-creator:server:setTuneshopOccupied"
      L7_2(L8_2, L5_2, false)
    end
  end
  L1_2 = pcall
  function L2_2()
    local L0_3, L1_3
    L0_3 = lib
    if L0_3 then
      L0_3 = lib
      L0_3 = L0_3.hideTextUI
      if L0_3 then
        L0_3 = lib
        L0_3 = L0_3.hideTextUI
        L0_3()
      end
    end
  end
  L1_2(L2_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:showNotification"
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = showNotification
  L3_2 = A0_2
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = "info"
  end
  L5_2 = 5000
  L2_2(L3_2, L4_2, L5_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:openCreatorUI"
function L31_1(A0_2)
  local L1_2, L2_2, L3_2
  L0_1.creatorOpen = true
  L0_1.uiOpen = true
  if A0_2 then
    L1_2 = A0_2.shops
    if L1_2 then
      L1_2 = A0_2.shops
      mechanicShops = L1_2
    end
  end
  if A0_2 then
    L1_2 = A0_2.wheeldamage
    if L1_2 then
      L1_2 = A0_2.wheeldamage
      L4_1.WheelDamage = L1_2
    end
  end
  if A0_2 then
    L1_2 = A0_2.offroadsystem
    if L1_2 then
      L1_2 = A0_2.offroadsystem
      L4_1.OffroadSystem = L1_2
    end
  end
  if A0_2 then
    L1_2 = A0_2.heatedbrakes
    if L1_2 then
      L1_2 = A0_2.heatedbrakes
      L4_1.HeatedBrakes = L1_2
    end
  end
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = L27_1
  L2_2 = mechanicShops
  L1_2(L2_2)
end
L29_1(L30_1, L31_1)
L29_1 = RegisterCommand
L30_1 = "mechanic_creator"
function L31_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = lib
  if not L0_2 then
    return
  end
  L0_2 = lib
  L0_2 = L0_2.callback
  L1_2 = "qs-mechanic-creator:server:hasAdminPermission"
  L2_2 = false
  function L3_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3
    if A0_3 then
      L1_3 = lib
      L1_3 = L1_3.callback
      L2_3 = "qs-mechanic-creator:server:getMechanicShops"
      L3_3 = false
      function L4_3(A0_4)
        local L1_4, L2_4, L3_4, L4_4
        L1_4 = A0_4 or nil
        if not A0_4 then
          L1_4 = {}
        end
        mechanicShops = L1_4
        L1_4 = lib
        L1_4 = L1_4.callback
        L2_4 = "qs-mechanic-creator:server:getConfigs"
        L3_4 = false
        function L4_4(A0_5)
          local L1_5, L2_5, L3_5
          L1_5 = L28_1
          L2_5 = mechanicShops
          L3_5 = A0_5
          L1_5(L2_5, L3_5)
        end
        L1_4(L2_4, L3_4, L4_4)
      end
      L1_3(L2_3, L3_3, L4_3)
    else
      L1_3 = showClientNotification
      L2_3 = {}
      L3_3 = _U
      L4_3 = "ACCESS_DENIED"
      L3_3 = L3_3(L4_3)
      L2_3.title = L3_3
      L3_3 = _U
      L4_3 = "NO_ADMIN_PERMISSION"
      L3_3 = L3_3(L4_3)
      L2_3.description = L3_3
      L2_3.type = "error"
      L1_3(L2_3)
    end
  end
  L0_2(L1_2, L2_2, L3_2)
end
L32_1 = false
L29_1(L30_1, L31_1, L32_1)
L29_1 = AddEventHandler
L30_1 = "onResourceStart"
function L31_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = CreateThread
    function L2_2()
      local L0_3, L1_3, L2_3, L3_3
      while true do
        L0_3 = NetworkIsPlayerActive
        L1_3 = PlayerId
        L1_3, L2_3, L3_3 = L1_3()
        L0_3 = L0_3(L1_3, L2_3, L3_3)
        if L0_3 then
          break
        end
        L0_3 = Wait
        L1_3 = 100
        L0_3(L1_3)
      end
      L0_3 = Wait
      L1_3 = 2000
      L0_3(L1_3)
      L0_3 = {}
      L6_1 = L0_3
      L0_3 = {}
      L7_1 = L0_3
      L0_3 = {}
      L8_1 = L0_3
      L0_3 = {}
      L9_1 = L0_3
      L0_3 = false
      L10_1 = L0_3
      L0_3 = 0
      L11_1 = L0_3
      L0_3 = Wait
      L1_3 = 300
      L0_3(L1_3)
      L0_3 = PlayerPedId
      L0_3 = L0_3()
      L1_3 = IsPedInAnyVehicle
      L2_3 = L0_3
      L3_3 = false
      L1_3 = L1_3(L2_3, L3_3)
      if L1_3 then
        L1_3 = GetVehiclePedIsIn
        L2_3 = L0_3
        L3_3 = false
        L1_3 = L1_3(L2_3, L3_3)
        L2_3 = DoesEntityExist
        L3_3 = L1_3
        L2_3 = L2_3(L3_3)
        if L2_3 then
          L5_1 = L1_3
        end
      end
      L1_3 = Wait
      L2_3 = 500
      L1_3(L2_3)
      L1_3 = L23_1
      L1_3()
    end
    L1_2(L2_2)
  end
end
L29_1(L30_1, L31_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:forceInitialize"
function L31_1()
  local L0_2, L1_2
  L0_2 = L23_1
  L0_2()
end
L29_1(L30_1, L31_1)
L29_1 = AddEventHandler
L30_1 = "onResourceStop"
function L31_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = {}
    L1_2.initialized = false
    L1_2.configsLoaded = false
    L1_2.shopsLoaded = false
    L1_2.uiOpen = false
    L1_2.mechanicCam = nil
    L1_2.textUIShown = false
    L1_2.tuneshopOpen = false
    L1_2.creatorOpen = false
    L1_2.isPlacingShop = false
    L0_1 = L1_2
    L1_2 = L22_1
    L1_2()
    L1_2 = cleanupTuneshopZones
    L1_2()
    L1_2 = L24_1
    L1_2()
    L1_2 = {}
    L1_2.lastCleanup = 0
    L1_2.operationCount = 0
    L17_1 = L1_2
    L1_2 = {}
    L1_2.loading = false
    L1_2.lastUpdate = 0
    L1_2.updateInterval = 5000
    L1_2.maxZonesPerFrame = 3
    L16_1 = L1_2
    L1_2 = {}
    L1_2.WheelDamage = nil
    L1_2.OffroadSystem = nil
    L1_2.HeatedBrakes = nil
    L4_1 = L1_2
  end
end
L29_1(L30_1, L31_1)
L29_1 = CreateThread
function L30_1()
  local L0_2, L1_2, L2_2
  while true do
    L0_2 = Wait
    L1_2 = 600000
    L0_2(L1_2)
    L0_2 = next
    L1_2 = L13_1
    L0_2 = L0_2(L1_2)
    if not L0_2 then
      L0_2 = next
      L1_2 = L12_1
      L0_2 = L0_2(L1_2)
      if not L0_2 then
    end
    else
      L0_2 = GetGameTimer
      L0_2 = L0_2()
      L1_2 = L17_1.lastCleanup
      L1_2 = L0_2 - L1_2
      L2_2 = 600000
      if L1_2 > L2_2 then
        L17_1.lastCleanup = L0_2
        L1_2 = CreateThread
        function L2_2()
          local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3
          L0_3 = 0
          L1_3 = 0
          L2_3 = 0
          L3_3 = {}
          L4_3 = pairs
          L5_3 = L13_1
          L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3)
          for L8_3, L9_3 in L4_3, L5_3, L6_3, L7_3 do
            if L9_3 then
              L10_3 = L9_3.coords
              if L10_3 then
                goto lbl_22
              end
            end
            L10_3 = #L3_3
            L10_3 = L10_3 + 1
            L3_3[L10_3] = L8_3
            L1_3 = L1_3 + 1
            goto lbl_24
            ::lbl_22::
            L0_3 = L0_3 + 1
            ::lbl_24::
            L2_3 = L2_3 + 1
            L10_3 = L2_3 % 10
            if 0 == L10_3 then
              L10_3 = Wait
              L11_3 = 50
              L10_3(L11_3)
            end
            if L2_3 >= 50 then
              break
            end
          end
          L4_3 = ipairs
          L5_3 = L3_3
          L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3)
          for L8_3, L9_3 in L4_3, L5_3, L6_3, L7_3 do
            L10_3 = L13_1
            L10_3[L9_3] = nil
          end
          L4_3 = Wait
          L5_3 = 100
          L4_3(L5_3)
          L4_3 = 0
          L5_3 = 0
          L6_3 = 0
          L7_3 = {}
          L8_3 = pairs
          L9_3 = L12_1
          L8_3, L9_3, L10_3, L11_3 = L8_3(L9_3)
          for L12_3, L13_3 in L8_3, L9_3, L10_3, L11_3 do
            if L13_3 then
              L14_3 = DoesBlipExist
              L15_3 = L13_3
              L14_3 = L14_3(L15_3)
              if L14_3 then
                goto lbl_73
              end
            end
            L14_3 = #L7_3
            L14_3 = L14_3 + 1
            L7_3[L14_3] = L12_3
            L5_3 = L5_3 + 1
            goto lbl_75
            ::lbl_73::
            L4_3 = L4_3 + 1
            ::lbl_75::
            L6_3 = L6_3 + 1
            L14_3 = L6_3 % 10
            if 0 == L14_3 then
              L14_3 = Wait
              L15_3 = 50
              L14_3(L15_3)
            end
            if L6_3 >= 50 then
              break
            end
          end
          L8_3 = ipairs
          L9_3 = L7_3
          L8_3, L9_3, L10_3, L11_3 = L8_3(L9_3)
          for L12_3, L13_3 in L8_3, L9_3, L10_3, L11_3 do
            L14_3 = L12_1
            L14_3[L13_3] = nil
          end
        end
        L1_2(L2_2)
      end
    end
  end
end
L29_1(L30_1)
L29_1 = RegisterNetEvent
L30_1 = "qs-mechanic-creator:client:syncTuneshopOccupied"
L29_1(L30_1)
L29_1 = AddEventHandler
L30_1 = "qs-mechanic-creator:client:syncTuneshopOccupied"
function L31_1(A0_2, A1_2)
  local L2_2
  if not A0_2 then
    return
  end
  L2_2 = L15_1
  L2_2[A0_2] = A1_2
end
L29_1(L30_1, L31_1)
