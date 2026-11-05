local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = {}
L6_1 = {}
L7_1 = nil
L8_1 = {}
L9_1 = {}
L10_1 = {}
L11_1 = 0
L12_1 = 5000
L13_1 = false
L14_1 = 0
L15_1 = 200
L16_1 = nil
L17_1 = false
L18_1 = 0
L19_1 = Config
L19_1 = L19_1.CarliftModels
L19_1 = L19_1.pole
L20_1 = Config
L20_1 = L20_1.CarliftModels
L20_1 = L20_1.arm
L21_1 = Config
L21_1 = L21_1.CarliftModels
L21_1 = L21_1.detectionRadius
L22_1 = Config
L22_1 = L22_1.CarliftModels
L22_1 = L22_1.interactionRadius
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = L1_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L1_1
    L2_2 = L2_2[A0_2]
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_13
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_13::
  L1_2 = GetEntityCoords
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  L1_2 = L1_2(L2_2)
  L2_2 = GetGamePool
  L3_2 = "CVehicle"
  L2_2 = L2_2(L3_2)
  L3_2 = nil
  L4_2 = L22_1
  L5_2 = ipairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = DoesEntityExist
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = GetEntityCoords
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      L11_2 = L11_2 - L1_2
      L11_2 = #L11_2
      if L4_2 > L11_2 then
        L4_2 = L11_2
        L3_2 = L10_2
      end
    end
  end
  return L3_2
end
L24_1 = RegisterNetEvent
L25_1 = "qs-mechanic-creator:client:updateCarliftPosition"
L24_1(L25_1)
L24_1 = AddEventHandler
L25_1 = "qs-mechanic-creator:client:updateCarliftPosition"
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  if not A0_2 or not A1_2 then
    return
  end
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_1
    L3_2 = L3_2[A0_2]
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L3_1
      L2_2 = L2_2[A0_2]
      if L2_2 then
        goto lbl_21
      end
    end
  end
  do return end
  ::lbl_21::
  L2_2 = GetEntityCoords
  L3_2 = L1_1
  L3_2 = L3_2[A0_2]
  L2_2 = L2_2(L3_2)
  L3_2 = L3_1
  L3_2 = L3_2[A0_2]
  L3_2.currentZ = A1_2
  L3_2 = SetEntityCoords
  L4_2 = L1_1
  L4_2 = L4_2[A0_2]
  L5_2 = L2_2.x
  L6_2 = L2_2.y
  L7_2 = A1_2
  L8_2 = false
  L9_2 = false
  L10_2 = false
  L11_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end
L24_1(L25_1, L26_1)
L24_1 = RegisterNetEvent
L25_1 = "qs-mechanic-creator:client:toggleCarliftVehicle"
L24_1(L25_1)
L24_1 = AddEventHandler
L25_1 = "qs-mechanic-creator:client:toggleCarliftVehicle"
function L26_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  if not A0_2 or not A1_2 then
    return
  end
  L3_2 = L1_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L4_2 = DoesEntityExist
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_16
    end
  end
  do return end
  ::lbl_16::
  L4_2 = NetworkDoesNetworkIdExist
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    return
  end
  L4_2 = NetworkGetEntityFromNetworkId
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 and 0 ~= L4_2 then
    L5_2 = DoesEntityExist
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_35
    end
  end
  do return end
  ::lbl_35::
  L5_2 = A1_2
  if A2_2 then
    L6_2 = GetModelDimensions
    L7_2 = GetEntityModel
    L8_2 = L4_2
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L7_2(L8_2)
    L6_2, L7_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
    L8_2 = math
    L8_2 = L8_2.abs
    L9_2 = L6_2.z
    L8_2 = L8_2(L9_2)
    L9_2 = Config
    L9_2 = L9_2.CarliftModels
    L9_2 = L9_2.vehicleZOffset
    L8_2 = L8_2 + L9_2
    L9_2 = AttachEntityToEntity
    L10_2 = L4_2
    L11_2 = L3_2
    L12_2 = -1
    L13_2 = 0.1
    L14_2 = -0.3
    L15_2 = L8_2
    L16_2 = 0.0
    L17_2 = 0.0
    L18_2 = 0.0
    L19_2 = false
    L20_2 = false
    L21_2 = true
    L22_2 = false
    L23_2 = 2
    L24_2 = true
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
    L9_2 = Wait
    L10_2 = 100
    L9_2(L10_2)
    L9_2 = FreezeEntityPosition
    L10_2 = L4_2
    L11_2 = true
    L9_2(L10_2, L11_2)
    L9_2 = L4_1
    L9_2[L5_2] = true
  else
    L6_2 = FreezeEntityPosition
    L7_2 = L4_2
    L8_2 = false
    L6_2(L7_2, L8_2)
    L6_2 = DetachEntity
    L7_2 = L4_2
    L8_2 = true
    L9_2 = true
    L6_2(L7_2, L8_2, L9_2)
    L6_2 = L4_1
    L6_2[L5_2] = nil
  end
end
L24_1(L25_1, L26_1)
function L24_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L3_2 = GetHashKey
  L4_2 = A2_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetGamePool
  L5_2 = "CObject"
  L4_2 = L4_2(L5_2)
  L5_2 = ipairs
  L6_2 = L4_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = DoesEntityExist
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = GetEntityModel
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 == L3_2 then
        L11_2 = GetEntityCoords
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        L12_2 = vector3
        L13_2 = L11_2.x
        L14_2 = L11_2.y
        L15_2 = L11_2.z
        L12_2 = L12_2(L13_2, L14_2, L15_2)
        L12_2 = L12_2 - A0_2
        L12_2 = #L12_2
        if A1_2 > L12_2 then
          return L10_2
        end
      end
    end
  end
  L5_2 = nil
  return L5_2
end
function L25_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if A0_2 then
    L1_2 = DoesEntityExist
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L1_2 = SetEntityAsMissionEntity
  L2_2 = A0_2
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = DetachEntity
  L2_2 = A0_2
  L3_2 = true
  L4_2 = true
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = DeleteEntity
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = DeleteObject
    L2_2 = A0_2
    L1_2(L2_2)
  end
end
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L2_2 = DoesEntityExist
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L2_2 = VehToNet
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L4_1
  L3_2 = L3_2[L2_2]
  if L3_2 then
    L3_2 = FreezeEntityPosition
    L4_2 = A0_2
    L5_2 = false
    L3_2(L4_2, L5_2)
    L3_2 = DetachEntity
    L4_2 = A0_2
    L5_2 = true
    L6_2 = true
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = L4_1
    L3_2[L2_2] = nil
    L3_2 = L9_1
    L3_2 = L3_2[A1_2]
    L4_2 = TriggerServerEvent
    L5_2 = "qs-mechanic-creator:server:toggleCarliftVehicle"
    L6_2 = L3_2
    L7_2 = L2_2
    L8_2 = false
    L4_2(L5_2, L6_2, L7_2, L8_2)
  else
    L3_2 = GetEntityCoords
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L4_2 = GetEntityHeading
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    L5_2 = SetFocusPosAndVel
    L6_2 = L3_2.x
    L7_2 = L3_2.y
    L8_2 = L3_2.z
    L9_2 = 0.0
    L10_2 = 0.0
    L11_2 = 0.0
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    L5_2 = Wait
    L6_2 = 100
    L5_2(L6_2)
    L5_2 = GetModelDimensions
    L6_2 = GetEntityModel
    L7_2 = A0_2
    L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L6_2(L7_2)
    L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
    L7_2 = math
    L7_2 = L7_2.abs
    L8_2 = L5_2.z
    L7_2 = L7_2(L8_2)
    L8_2 = Config
    L8_2 = L8_2.CarliftModels
    L8_2 = L8_2.vehicleZOffset
    L7_2 = L7_2 + L8_2
    L8_2 = GetEntityHeading
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    L9_2 = Config
    L9_2 = L9_2.Debug
    if L9_2 then
      L9_2 = print
      L10_2 = "[CARLIFT DEBUG] Lift coords:"
      L11_2 = L3_2
      L9_2(L10_2, L11_2)
      L9_2 = print
      L10_2 = "[CARLIFT DEBUG] Lift heading:"
      L11_2 = L4_2
      L9_2(L10_2, L11_2)
      L9_2 = print
      L10_2 = "[CARLIFT DEBUG] Vehicle heading before:"
      L11_2 = L8_2
      L9_2(L10_2, L11_2)
      L9_2 = print
      L10_2 = "[CARLIFT DEBUG] Z offset:"
      L11_2 = L7_2
      L9_2(L10_2, L11_2)
    end
    L9_2 = AttachEntityToEntity
    L10_2 = A0_2
    L11_2 = A1_2
    L12_2 = -1
    L13_2 = 0.1
    L14_2 = -0.3
    L15_2 = L7_2
    L16_2 = 0.0
    L17_2 = 0.0
    L18_2 = 0.0
    L19_2 = false
    L20_2 = false
    L21_2 = true
    L22_2 = false
    L23_2 = 2
    L24_2 = true
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
    L9_2 = Wait
    L10_2 = 100
    L9_2(L10_2)
    L9_2 = FreezeEntityPosition
    L10_2 = A0_2
    L11_2 = true
    L9_2(L10_2, L11_2)
    L9_2 = Config
    L9_2 = L9_2.Debug
    if L9_2 then
      L9_2 = GetEntityCoords
      L10_2 = A0_2
      L9_2 = L9_2(L10_2)
      L10_2 = GetEntityHeading
      L11_2 = A0_2
      L10_2 = L10_2(L11_2)
      L11_2 = print
      L12_2 = "[CARLIFT DEBUG] Vehicle coords after attach:"
      L13_2 = L9_2
      L11_2(L12_2, L13_2)
      L11_2 = print
      L12_2 = "[CARLIFT DEBUG] Vehicle heading after attach:"
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
    end
    L9_2 = L4_1
    L9_2[L2_2] = true
    L9_2 = Wait
    L10_2 = 100
    L9_2(L10_2)
    L9_2 = ClearFocus
    L9_2()
    L9_2 = L9_1
    L9_2 = L9_2[A1_2]
    L10_2 = TriggerServerEvent
    L11_2 = "qs-mechanic-creator:server:toggleCarliftVehicle"
    L12_2 = L9_2
    L13_2 = L2_2
    L14_2 = true
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
end
function L27_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2
  L2_2 = Config
  L2_2 = L2_2.Debug
  if L2_2 then
    L2_2 = print
    L3_2 = "^2[DEBUG]^0: placeCarliftProp called for shop: "
    L4_2 = tostring
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
    L2_2(L3_2)
  end
  if A1_2 then
    L2_2 = A1_2.enabled
    if L2_2 then
      goto lbl_29
    end
  end
  L2_2 = Config
  L2_2 = L2_2.Debug
  if L2_2 then
    L2_2 = print
    L3_2 = "^2[DEBUG]^0: Carlift data not provided or not enabled for shop: "
    L4_2 = tostring
    L5_2 = A0_2
    L4_2 = L4_2(L5_2)
    L3_2 = L3_2 .. L4_2
    L2_2(L3_2)
  end
  do return end
  ::lbl_29::
  L2_2 = L0_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L0_1
    L3_2 = L3_2[A0_2]
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.Debug
      if L2_2 then
        L2_2 = print
        L3_2 = "^2[DEBUG]^0: Deleting existing carlift base for shop: "
        L4_2 = tostring
        L5_2 = A0_2
        L4_2 = L4_2(L5_2)
        L3_2 = L3_2 .. L4_2
        L2_2(L3_2)
      end
      L2_2 = L0_1
      L2_2 = L2_2[A0_2]
      L3_2 = L25_1
      L4_2 = L2_2
      L3_2(L4_2)
      L3_2 = L8_1
      L3_2[L2_2] = nil
      L3_2 = L0_1
      L3_2[A0_2] = nil
      L3_2 = Wait
      L4_2 = 100
      L3_2(L4_2)
    end
  end
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_1
    L3_2 = L3_2[A0_2]
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.Debug
      if L2_2 then
        L2_2 = print
        L3_2 = "^2[DEBUG]^0: Deleting existing carlift arm for shop: "
        L4_2 = tostring
        L5_2 = A0_2
        L4_2 = L4_2(L5_2)
        L3_2 = L3_2 .. L4_2
        L2_2(L3_2)
      end
      L2_2 = L1_1
      L2_2 = L2_2[A0_2]
      L3_2 = L25_1
      L4_2 = L2_2
      L3_2(L4_2)
      L3_2 = L9_1
      L3_2[L2_2] = nil
      L3_2 = L1_1
      L3_2[A0_2] = nil
      L3_2 = Wait
      L4_2 = 100
      L3_2(L4_2)
    end
  end
  L2_2 = nil
  L3_2 = A1_2.locations
  if L3_2 then
    L3_2 = A1_2.locations
    L3_2 = #L3_2
    if L3_2 > 0 then
      L3_2 = A1_2.locations
      L2_2 = L3_2[1]
  end
  else
    L3_2 = A1_2.coords
    if L3_2 then
      L2_2 = A1_2.coords
    else
      return
    end
  end
  L3_2 = tonumber
  L4_2 = L2_2.x
  L3_2 = L3_2(L4_2)
  L4_2 = tonumber
  L5_2 = L2_2.y
  L4_2 = L4_2(L5_2)
  L5_2 = tonumber
  L6_2 = L2_2.z
  L5_2 = L5_2(L6_2)
  L6_2 = tonumber
  L7_2 = L2_2.w
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = 0.0
  end
  if not (L3_2 and L4_2) or not L5_2 then
    return
  end
  L7_2 = vector3
  L8_2 = L3_2
  L9_2 = L4_2
  L10_2 = L5_2
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = GetHashKey
  L9_2 = L19_1
  L8_2 = L8_2(L9_2)
  L9_2 = GetHashKey
  L10_2 = L20_1
  L9_2 = L9_2(L10_2)
  if 0 ~= L8_2 and -1 ~= L8_2 then
    L10_2 = IsModelValid
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      goto lbl_155
    end
  end
  do return end
  ::lbl_155::
  if 0 ~= L9_2 and -1 ~= L9_2 then
    L10_2 = IsModelValid
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      goto lbl_165
    end
  end
  do return end
  ::lbl_165::
  L10_2 = lib
  L10_2 = L10_2.requestModel
  L11_2 = L8_2
  L12_2 = 10000
  L10_2 = L10_2(L11_2, L12_2)
  if not L10_2 then
    return
  end
  L11_2 = lib
  L11_2 = L11_2.requestModel
  L12_2 = L9_2
  L13_2 = 10000
  L11_2 = L11_2(L12_2, L13_2)
  if not L11_2 then
    L12_2 = SetModelAsNoLongerNeeded
    L13_2 = L8_2
    L12_2(L13_2)
    return
  end
  L12_2 = Wait
  L13_2 = 250
  L12_2(L13_2)
  L12_2 = HasModelLoaded
  L13_2 = L8_2
  L12_2 = L12_2(L13_2)
  if not L12_2 then
    L12_2 = Config
    L12_2 = L12_2.Debug
    if L12_2 then
      L12_2 = print
      L13_2 = "^1[DEBUG ERROR]^0: Pole model failed to load for shop: "
      L14_2 = tostring
      L15_2 = A0_2
      L14_2 = L14_2(L15_2)
      L13_2 = L13_2 .. L14_2
      L12_2(L13_2)
    end
    L12_2 = SetModelAsNoLongerNeeded
    L13_2 = L8_2
    L12_2(L13_2)
    L12_2 = SetModelAsNoLongerNeeded
    L13_2 = L9_2
    L12_2(L13_2)
    return
  end
  L12_2 = HasModelLoaded
  L13_2 = L9_2
  L12_2 = L12_2(L13_2)
  if not L12_2 then
    L12_2 = Config
    L12_2 = L12_2.Debug
    if L12_2 then
      L12_2 = print
      L13_2 = "^1[DEBUG ERROR]^0: Arm model failed to load for shop: "
      L14_2 = tostring
      L15_2 = A0_2
      L14_2 = L14_2(L15_2)
      L13_2 = L13_2 .. L14_2
      L12_2(L13_2)
    end
    L12_2 = SetModelAsNoLongerNeeded
    L13_2 = L8_2
    L12_2(L13_2)
    L12_2 = SetModelAsNoLongerNeeded
    L13_2 = L9_2
    L12_2(L13_2)
    return
  end
  L12_2 = Config
  L12_2 = L12_2.Debug
  if L12_2 then
    L12_2 = print
    L13_2 = "^2[DEBUG]^0: Models loaded successfully for shop: "
    L14_2 = tostring
    L15_2 = A0_2
    L14_2 = L14_2(L15_2)
    L13_2 = L13_2 .. L14_2
    L12_2(L13_2)
  end
  L12_2 = L24_1
  L13_2 = L7_2
  L14_2 = L21_1
  L15_2 = L19_1
  L12_2 = L12_2(L13_2, L14_2, L15_2)
  if L12_2 then
    L13_2 = DoesEntityExist
    L14_2 = L12_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L13_2 = L8_1
      L13_2 = L13_2[L12_2]
      if not L13_2 or L13_2 == A0_2 then
        L14_2 = L25_1
        L15_2 = L12_2
        L14_2(L15_2)
        L14_2 = L8_1
        L14_2[L12_2] = nil
        L14_2 = Wait
        L15_2 = 100
        L14_2(L15_2)
      end
    end
  end
  L13_2 = L24_1
  L14_2 = L7_2
  L15_2 = L21_1
  L16_2 = L20_1
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  if L13_2 then
    L14_2 = DoesEntityExist
    L15_2 = L13_2
    L14_2 = L14_2(L15_2)
    if L14_2 then
      L14_2 = L9_1
      L14_2 = L14_2[L13_2]
      if not L14_2 or L14_2 == A0_2 then
        L15_2 = L25_1
        L16_2 = L13_2
        L15_2(L16_2)
        L15_2 = L9_1
        L15_2[L13_2] = nil
        L15_2 = Wait
        L16_2 = 100
        L15_2(L16_2)
      end
    end
  end
  L14_2 = math
  L14_2 = L14_2.rad
  L15_2 = L6_2
  L14_2 = L14_2(L15_2)
  L15_2 = nil
  L16_2 = 1
  L17_2 = 5
  L18_2 = 1
  for L19_2 = L16_2, L17_2, L18_2 do
    L20_2 = CreateObjectNoOffset
    L21_2 = L8_2
    L22_2 = L7_2.x
    L23_2 = L7_2.y
    L24_2 = L7_2.z
    L25_2 = false
    L26_2 = false
    L27_2 = false
    L20_2 = L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
    L15_2 = L20_2
    L20_2 = DoesEntityExist
    L21_2 = L15_2
    L20_2 = L20_2(L21_2)
    if L20_2 then
      break
    end
    L20_2 = Wait
    L21_2 = 100
    L20_2(L21_2)
  end
  if L15_2 then
    L16_2 = DoesEntityExist
    L17_2 = L15_2
    L16_2 = L16_2(L17_2)
    if L16_2 then
      goto lbl_349
    end
  end
  L16_2 = Config
  L16_2 = L16_2.Debug
  if L16_2 then
    L16_2 = print
    L17_2 = "^1[DEBUG ERROR]^0: Failed to create carlift pole entity for shop: "
    L18_2 = tostring
    L19_2 = A0_2
    L18_2 = L18_2(L19_2)
    L17_2 = L17_2 .. L18_2
    L16_2(L17_2)
  end
  L16_2 = SetModelAsNoLongerNeeded
  L17_2 = L8_2
  L16_2(L17_2)
  L16_2 = SetModelAsNoLongerNeeded
  L17_2 = L9_2
  L16_2(L17_2)
  do return end
  ::lbl_349::
  L16_2 = Config
  L16_2 = L16_2.Debug
  if L16_2 then
    L16_2 = print
    L17_2 = "^2[DEBUG]^0: Carlift pole created successfully, entity: "
    L18_2 = tostring
    L19_2 = L15_2
    L18_2 = L18_2(L19_2)
    L17_2 = L17_2 .. L18_2
    L16_2(L17_2)
  end
  L16_2 = SetEntityAsMissionEntity
  L17_2 = L15_2
  L18_2 = true
  L19_2 = true
  L16_2(L17_2, L18_2, L19_2)
  L16_2 = SetEntityCoordsNoOffset
  L17_2 = L15_2
  L18_2 = L7_2.x
  L19_2 = L7_2.y
  L20_2 = L7_2.z
  L21_2 = false
  L22_2 = false
  L23_2 = false
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2)
  L16_2 = Wait
  L17_2 = 50
  L16_2(L17_2)
  L16_2 = SetEntityHeading
  L17_2 = L15_2
  L18_2 = L6_2
  L16_2(L17_2, L18_2)
  L16_2 = Wait
  L17_2 = 50
  L16_2(L17_2)
  L16_2 = GetEntityCoords
  L17_2 = L15_2
  L16_2 = L16_2(L17_2)
  L17_2 = math
  L17_2 = L17_2.rad
  L18_2 = L6_2
  L17_2 = L17_2(L18_2)
  L18_2 = FreezeEntityPosition
  L19_2 = L15_2
  L20_2 = true
  L18_2(L19_2, L20_2)
  L18_2 = SetEntityCollision
  L19_2 = L15_2
  L20_2 = true
  L21_2 = true
  L18_2(L19_2, L20_2, L21_2)
  L18_2 = SetEntityVisible
  L19_2 = L15_2
  L20_2 = true
  L21_2 = false
  L18_2(L19_2, L20_2, L21_2)
  L18_2 = SetEntityAlpha
  L19_2 = L15_2
  L20_2 = 255
  L21_2 = false
  L18_2(L19_2, L20_2, L21_2)
  L18_2 = L0_1
  L18_2[A0_2] = L15_2
  L18_2 = L8_1
  L18_2[L15_2] = A0_2
  L18_2 = Config
  L18_2 = L18_2.CarliftModels
  L18_2 = L18_2.armOffset
  L19_2 = L18_2.x
  L20_2 = math
  L20_2 = L20_2.sin
  L21_2 = L17_2
  L20_2 = L20_2(L21_2)
  L19_2 = L19_2 * L20_2
  L20_2 = L18_2.y
  L21_2 = math
  L21_2 = L21_2.cos
  L22_2 = L17_2
  L21_2 = L21_2(L22_2)
  L20_2 = L20_2 * L21_2
  L21_2 = L16_2.x
  L21_2 = L21_2 + L19_2
  L22_2 = L16_2.y
  L22_2 = L22_2 + L20_2
  L23_2 = L16_2.z
  L24_2 = L18_2.z
  L23_2 = L23_2 + L24_2
  L24_2 = nil
  L25_2 = 1
  L26_2 = 5
  L27_2 = 1
  for L28_2 = L25_2, L26_2, L27_2 do
    L29_2 = CreateObjectNoOffset
    L30_2 = L9_2
    L31_2 = L21_2
    L32_2 = L22_2
    L33_2 = L23_2
    L34_2 = false
    L35_2 = false
    L36_2 = false
    L29_2 = L29_2(L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2)
    L24_2 = L29_2
    L29_2 = DoesEntityExist
    L30_2 = L24_2
    L29_2 = L29_2(L30_2)
    if L29_2 then
      break
    end
    L29_2 = Wait
    L30_2 = 100
    L29_2(L30_2)
  end
  if L24_2 then
    L25_2 = DoesEntityExist
    L26_2 = L24_2
    L25_2 = L25_2(L26_2)
    if L25_2 then
      goto lbl_507
    end
  end
  L25_2 = Config
  L25_2 = L25_2.Debug
  if L25_2 then
    L25_2 = print
    L26_2 = "^1[DEBUG ERROR]^0: Failed to create carlift arm entity for shop: "
    L27_2 = tostring
    L28_2 = A0_2
    L27_2 = L27_2(L28_2)
    L26_2 = L26_2 .. L27_2
    L25_2(L26_2)
  end
  if L15_2 then
    L25_2 = DoesEntityExist
    L26_2 = L15_2
    L25_2 = L25_2(L26_2)
    if L25_2 then
      L25_2 = L25_1
      L26_2 = L15_2
      L25_2(L26_2)
      L25_2 = Wait
      L26_2 = 100
      L25_2(L26_2)
    end
  end
  L25_2 = L0_1
  L25_2[A0_2] = nil
  L25_2 = L8_1
  L25_2[L15_2] = nil
  L25_2 = SetModelAsNoLongerNeeded
  L26_2 = L8_2
  L25_2(L26_2)
  L25_2 = SetModelAsNoLongerNeeded
  L26_2 = L9_2
  L25_2(L26_2)
  do return end
  ::lbl_507::
  L25_2 = Config
  L25_2 = L25_2.Debug
  if L25_2 then
    L25_2 = print
    L26_2 = "^2[DEBUG]^0: Carlift arm created successfully, entity: "
    L27_2 = tostring
    L28_2 = L24_2
    L27_2 = L27_2(L28_2)
    L26_2 = L26_2 .. L27_2
    L25_2(L26_2)
  end
  L25_2 = SetEntityAsMissionEntity
  L26_2 = L24_2
  L27_2 = true
  L28_2 = true
  L25_2(L26_2, L27_2, L28_2)
  L25_2 = SetEntityHeading
  L26_2 = L24_2
  L27_2 = L6_2
  L25_2(L26_2, L27_2)
  L25_2 = Wait
  L26_2 = 50
  L25_2(L26_2)
  L25_2 = FreezeEntityPosition
  L26_2 = L24_2
  L27_2 = true
  L25_2(L26_2, L27_2)
  L25_2 = SetEntityCollision
  L26_2 = L24_2
  L27_2 = true
  L28_2 = true
  L25_2(L26_2, L27_2, L28_2)
  L25_2 = SetEntityVisible
  L26_2 = L24_2
  L27_2 = true
  L28_2 = false
  L25_2(L26_2, L27_2, L28_2)
  L25_2 = SetEntityAlpha
  L26_2 = L24_2
  L27_2 = 255
  L28_2 = false
  L25_2(L26_2, L27_2, L28_2)
  L25_2 = L1_1
  L25_2[A0_2] = L24_2
  L25_2 = L9_1
  L25_2[L24_2] = A0_2
  L25_2 = Wait
  L26_2 = 100
  L25_2(L26_2)
  L25_2 = DoesEntityExist
  L26_2 = L15_2
  L25_2 = L25_2(L26_2)
  if not L25_2 then
    L25_2 = DoesEntityExist
    L26_2 = L24_2
    L25_2 = L25_2(L26_2)
    if L25_2 then
      L25_2 = L25_1
      L26_2 = L24_2
      L25_2(L26_2)
    end
    L25_2 = L0_1
    L25_2[A0_2] = nil
    L25_2 = L1_1
    L25_2[A0_2] = nil
    L25_2 = L8_1
    L25_2[L15_2] = nil
    L25_2 = L9_1
    L25_2[L24_2] = nil
    L25_2 = SetModelAsNoLongerNeeded
    L26_2 = L8_2
    L25_2(L26_2)
    L25_2 = SetModelAsNoLongerNeeded
    L26_2 = L9_2
    L25_2(L26_2)
    return
  end
  L25_2 = DoesEntityExist
  L26_2 = L24_2
  L25_2 = L25_2(L26_2)
  if not L25_2 then
    L25_2 = DoesEntityExist
    L26_2 = L15_2
    L25_2 = L25_2(L26_2)
    if L25_2 then
      L25_2 = L25_1
      L26_2 = L15_2
      L25_2(L26_2)
    end
    L25_2 = L0_1
    L25_2[A0_2] = nil
    L25_2 = L1_1
    L25_2[A0_2] = nil
    L25_2 = L8_1
    L25_2[L15_2] = nil
    L25_2 = L9_1
    L25_2[L24_2] = nil
    L25_2 = SetModelAsNoLongerNeeded
    L26_2 = L8_2
    L25_2(L26_2)
    L25_2 = SetModelAsNoLongerNeeded
    L26_2 = L9_2
    L25_2(L26_2)
    return
  end
  L25_2 = L3_1
  L26_2 = {}
  L26_2.baseZ = L23_2
  L26_2.currentZ = L23_2
  L26_2.minZ = L23_2
  L27_2 = Config
  L27_2 = L27_2.CarliftModels
  L27_2 = L27_2.liftHeight
  L27_2 = L23_2 + L27_2
  L26_2.maxZ = L27_2
  L25_2[A0_2] = L26_2
  L25_2 = L2_1
  L25_2 = L25_2[A0_2]
  if L25_2 then
    L25_2 = RemoveInteract
    L26_2 = A0_2
    L25_2(L26_2)
    L25_2 = L2_1
    L25_2[A0_2] = nil
  end
  L25_2 = L16_2.x
  L26_2 = math
  L26_2 = L26_2.sin
  L27_2 = L17_2
  L26_2 = L26_2(L27_2)
  L26_2 = 0.3 * L26_2
  L25_2 = L25_2 - L26_2
  L26_2 = L16_2.y
  L27_2 = math
  L27_2 = L27_2.cos
  L28_2 = L17_2
  L27_2 = L27_2(L28_2)
  L27_2 = 0.3 * L27_2
  L26_2 = L26_2 + L27_2
  L27_2 = vec3
  L28_2 = L25_2
  L29_2 = L26_2
  L30_2 = L16_2.z
  L30_2 = L30_2 + 0.5
  L27_2 = L27_2(L28_2, L29_2, L30_2)
  L28_2 = vec3
  L29_2 = 4.0
  L30_2 = 6.0
  L31_2 = 3.0
  L28_2 = L28_2(L29_2, L30_2, L31_2)
  L29_2 = CreateCarliftInteract
  L30_2 = A0_2
  L31_2 = L27_2
  L32_2 = L28_2
  L33_2 = L6_2
  L34_2 = _U
  L35_2 = "CARLIFT"
  L34_2 = L34_2(L35_2)
  function L35_2()
    local L0_3, L1_3, L2_3
    L0_3 = TriggerServerEvent
    L1_3 = "qs-mechanic-creator:server:checkCarliftAccess"
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L29_2(L30_2, L31_2, L32_2, L33_2, L34_2, L35_2)
  L29_2 = L2_1
  L29_2[A0_2] = true
  L29_2 = SetModelAsNoLongerNeeded
  L30_2 = L8_2
  L29_2(L30_2)
  L29_2 = SetModelAsNoLongerNeeded
  L30_2 = L9_2
  L29_2(L30_2)
  L29_2 = Config
  L29_2 = L29_2.Debug
  if L29_2 then
    L29_2 = print
    L30_2 = "^2[DEBUG]^0: Carlift created successfully for shop: "
    L31_2 = tostring
    L32_2 = A0_2
    L31_2 = L31_2(L32_2)
    L30_2 = L30_2 .. L31_2
    L29_2(L30_2)
  end
end
placeCarliftProp = L27_1
function L27_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    return
  end
  L1_2 = Config
  L1_2 = L1_2.Debug
  if L1_2 then
    L1_2 = print
    L2_2 = "^2[DEBUG]^0: removeCarliftProp called for shop: "
    L3_2 = tostring
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L2_2 = L2_2 .. L3_2
    L1_2(L2_2)
  end
  L1_2 = L1_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L1_1
    L2_2 = L2_2[A0_2]
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = L1_1
      L1_2 = L1_2[A0_2]
      L2_2 = L25_1
      L3_2 = L1_2
      L2_2(L3_2)
      L2_2 = L9_1
      L2_2[L1_2] = nil
      L2_2 = L1_1
      L2_2[A0_2] = nil
      L2_2 = Wait
      L3_2 = 50
      L2_2(L3_2)
  end
  else
    L1_2 = L1_1
    L1_2[A0_2] = nil
  end
  L1_2 = L0_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L0_1
    L2_2 = L2_2[A0_2]
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = L0_1
      L1_2 = L1_2[A0_2]
      L2_2 = L25_1
      L3_2 = L1_2
      L2_2(L3_2)
      L2_2 = L8_1
      L2_2[L1_2] = nil
      L2_2 = L0_1
      L2_2[A0_2] = nil
      L2_2 = Wait
      L3_2 = 50
      L2_2(L3_2)
  end
  else
    L1_2 = L0_1
    L1_2[A0_2] = nil
  end
  L1_2 = L2_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = RemoveInteract
    L2_2 = A0_2
    L1_2(L2_2)
    L1_2 = L2_1
    L1_2[A0_2] = nil
  end
  L1_2 = L3_1
  L1_2[A0_2] = nil
  L1_2 = L5_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = L5_1
    L1_2[A0_2] = nil
  end
  L1_2 = L10_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = L10_1
    L1_2[A0_2] = nil
  end
end
removeCarliftProp = L27_1
function L27_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L0_2 = L6_1
  if L0_2 then
    L0_2 = next
    L1_2 = L6_1
    L0_2 = L0_2(L1_2)
    if L0_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L1_2 = L11_1
  L1_2 = L0_2 - L1_2
  L2_2 = L12_1
  if L1_2 < L2_2 then
    return
  end
  L11_1 = L0_2
  L1_2 = pairs
  L2_2 = L10_1
  if not L2_2 then
    L2_2 = {}
  end
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    if L6_2 then
      L7_2 = L6_2.enabled
      if L7_2 then
        L7_2 = L0_1
        L7_2 = L7_2[L5_2]
        L8_2 = L1_1
        L8_2 = L8_2[L5_2]
        L9_2 = L7_2 or L9_2
        if L7_2 then
          L9_2 = DoesEntityExist
          L10_2 = L7_2
          L9_2 = L9_2(L10_2)
        end
        L10_2 = L8_2 or L10_2
        if L8_2 then
          L10_2 = DoesEntityExist
          L11_2 = L8_2
          L10_2 = L10_2(L11_2)
        end
        if not L9_2 or not L10_2 then
          if L7_2 then
            L11_2 = DoesEntityExist
            L12_2 = L7_2
            L11_2 = L11_2(L12_2)
            if L11_2 then
              L11_2 = L25_1
              L12_2 = L7_2
              L11_2(L12_2)
              L11_2 = L8_1
              L11_2[L7_2] = nil
            end
          end
          L11_2 = L0_1
          L11_2[L5_2] = nil
          if L8_2 then
            L11_2 = DoesEntityExist
            L12_2 = L8_2
            L11_2 = L11_2(L12_2)
            if L11_2 then
              L11_2 = L25_1
              L12_2 = L8_2
              L11_2(L12_2)
              L11_2 = L9_1
              L11_2[L8_2] = nil
            end
          end
          L11_2 = L1_1
          L11_2[L5_2] = nil
          L11_2 = Wait
          L12_2 = 100
          L11_2(L12_2)
          L11_2 = L10_1
          L11_2 = L11_2[L5_2]
          if L11_2 then
            L12_2 = placeCarliftProp
            L13_2 = L5_2
            L14_2 = L11_2
            L12_2(L13_2, L14_2)
          else
            L12_2 = placeCarliftProp
            L13_2 = L5_2
            L14_2 = L6_2
            L12_2(L13_2, L14_2)
          end
        end
      end
    end
  end
end
function L28_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = L14_1
  L2_2 = L1_2 - L2_2
  L3_2 = L15_1
  if L2_2 < L3_2 then
    return
  end
  L2_2 = IsPlacingShop
  if L2_2 then
    L2_2 = IsPlacingShop
    L2_2 = L2_2()
    if L2_2 then
      return
    end
  end
  L2_2 = L13_1
  if L2_2 then
    return
  end
  L16_1 = A0_2
  L2_2 = true
  L13_1 = L2_2
  L2_2 = SetNuiFocus
  L3_2 = true
  L4_2 = true
  L2_2(L3_2, L4_2)
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.type = "openCarliftUI"
  L3_2.shopId = A0_2
  L4_2 = GetLocales
  L4_2 = L4_2()
  L3_2.locales = L4_2
  L2_2(L3_2)
end
openCarliftUI = L28_1
function L28_1()
  local L0_2, L1_2, L2_2
  L0_2 = L13_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L13_1 = L0_2
  L0_2 = nil
  L16_1 = L0_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SetNuiFocusKeepInput
  L1_2 = false
  L0_2(L1_2)
  L0_2 = Wait
  L1_2 = 100
  L0_2(L1_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.type = "closeCarliftUI"
  L0_2(L1_2)
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L14_1 = L0_2
end
closeCarliftUI = L28_1
function L28_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L2_2 = L1_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_1
    L3_2 = L3_2[A0_2]
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L3_1
      L2_2 = L2_2[A0_2]
      if L2_2 then
        goto lbl_16
      end
    end
  end
  do return end
  ::lbl_16::
  L2_2 = 0.1
  L3_2 = L3_1
  L3_2 = L3_2[A0_2]
  L4_2 = GetEntityCoords
  L5_2 = L1_1
  L5_2 = L5_2[A0_2]
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2.z
  L3_2.currentZ = L5_2
  if "up" == A1_2 then
    L5_2 = L3_2.currentZ
    L6_2 = L3_2.maxZ
    if L5_2 < L6_2 then
      L5_2 = math
      L5_2 = L5_2.min
      L6_2 = L3_2.currentZ
      L6_2 = L6_2 + L2_2
      L7_2 = L3_2.maxZ
      L5_2 = L5_2(L6_2, L7_2)
      L3_2.currentZ = L5_2
  end
  elseif "down" == A1_2 then
    L5_2 = L3_2.currentZ
    L6_2 = L3_2.minZ
    if L5_2 > L6_2 then
      L5_2 = math
      L5_2 = L5_2.max
      L6_2 = L3_2.currentZ
      L6_2 = L6_2 - L2_2
      L7_2 = L3_2.minZ
      L5_2 = L5_2(L6_2, L7_2)
      L3_2.currentZ = L5_2
    end
  end
  L5_2 = SetEntityCoords
  L6_2 = L1_1
  L6_2 = L6_2[A0_2]
  L7_2 = L4_2.x
  L8_2 = L4_2.y
  L9_2 = L3_2.currentZ
  L10_2 = false
  L11_2 = false
  L12_2 = false
  L13_2 = false
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L5_2 = TriggerServerEvent
  L6_2 = "qs-mechanic-creator:server:updateCarliftPosition"
  L7_2 = A0_2
  L8_2 = L3_2.currentZ
  L5_2(L6_2, L7_2, L8_2)
end
moveCarlift = L28_1
function L28_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = tonumber
  L2_2 = A0_2.x
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = 0.0
  end
  L2_2 = tonumber
  L3_2 = A0_2.y
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = 0.0
  end
  L3_2 = tonumber
  L4_2 = A0_2.z
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 0.0
  end
  L4_2 = tonumber
  L5_2 = A0_2.w
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 0.0
  end
  L5_2 = string
  L5_2 = L5_2.format
  L6_2 = "%.4f|%.4f|%.4f|%.4f"
  L7_2 = L1_2
  L8_2 = L2_2
  L9_2 = L3_2
  L10_2 = L4_2
  return L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
end
function L29_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A0_2 then
    L1_2 = L6_1
    if L1_2 then
      L1_2 = next
      L2_2 = L6_1
      L1_2 = L1_2(L2_2)
      if L1_2 then
        goto lbl_13
      end
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_13::
  L1_2 = string
  L1_2 = L1_2.find
  L2_2 = A0_2
  L3_2 = "_"
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = A0_2
  L3_2 = nil
  if L1_2 then
    L4_2 = string
    L4_2 = L4_2.sub
    L5_2 = A0_2
    L6_2 = 1
    L7_2 = L1_2 - 1
    L4_2 = L4_2(L5_2, L6_2, L7_2)
    L2_2 = L4_2
    L4_2 = tonumber
    L5_2 = string
    L5_2 = L5_2.sub
    L6_2 = A0_2
    L7_2 = L1_2 + 1
    L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    L3_2 = L4_2
  end
  L4_2 = L6_1
  L4_2 = L4_2[L2_2]
  if L4_2 then
    L5_2 = L4_2.shopConfig
    if L5_2 then
      L5_2 = L4_2.shopConfig
      L5_2 = L5_2.carlift
      if L5_2 then
        goto lbl_52
      end
    end
  end
  L5_2 = nil
  do return L5_2 end
  ::lbl_52::
  L5_2 = L4_2.shopConfig
  L5_2 = L5_2.carlift
  if L3_2 then
    L6_2 = L5_2.locations
    if L6_2 then
      L6_2 = L5_2.locations
      L6_2 = L6_2[L3_2]
      if L6_2 then
        L6_2 = L5_2.locations
        L6_2 = L6_2[L3_2]
        L7_2 = {}
        L7_2.enabled = true
        L8_2 = {}
        L9_2 = L6_2.x
        L8_2.x = L9_2
        L9_2 = L6_2.y
        L8_2.y = L9_2
        L9_2 = L6_2.z
        L8_2.z = L9_2
        L9_2 = L6_2.w
        L8_2.w = L9_2
        L7_2.coords = L8_2
        return L7_2
      end
    end
  end
  return L5_2
end
function L30_1(A0_2)
  local L1_2, L2_2
  if not A0_2 then
    L1_2 = {}
    A0_2 = L1_2
  end
  L1_2 = L17_1
  if L1_2 then
    L7_1 = A0_2
    return
  end
  L1_2 = true
  L17_1 = L1_2
  L6_1 = A0_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3, L21_3, L22_3, L23_3
    L0_3 = {}
    L1_3 = Config
    L2_3 = {}
    L1_3.Carlifts = L2_3
    L1_3 = {}
    L10_1 = L1_3
    L1_3 = 0
    L2_3 = 0
    L3_3 = pairs
    L4_3 = A0_2
    L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3)
    for L7_3, L8_3 in L3_3, L4_3, L5_3, L6_3 do
      L9_3 = L8_3.shopConfig
      if L9_3 then
        L9_3 = L8_3.shopConfig
        L9_3 = L9_3.carlift
        if L9_3 then
          L9_3 = L8_3.shopConfig
          L9_3 = L9_3.carlift
          L10_3 = L9_3.enabled
          if L10_3 then
            L10_3 = Config
            L10_3 = L10_3.Carlifts
            L10_3[L7_3] = L9_3
            L10_3 = L9_3.locations
            if L10_3 then
              L10_3 = L9_3.locations
              L10_3 = #L10_3
              if L10_3 > 0 then
                L10_3 = ipairs
                L11_3 = L9_3.locations
                L10_3, L11_3, L12_3, L13_3 = L10_3(L11_3)
                for L14_3, L15_3 in L10_3, L11_3, L12_3, L13_3 do
                  L16_3 = L7_3
                  L17_3 = "_"
                  L18_3 = L14_3
                  L16_3 = L16_3 .. L17_3 .. L18_3
                  L17_3 = L28_1
                  L18_3 = L15_3
                  L17_3 = L17_3(L18_3)
                  L0_3[L16_3] = L17_3
                  L18_3 = L5_1
                  L18_3 = L18_3[L16_3]
                  if L18_3 ~= L17_3 then
                    L18_3 = placeCarliftProp
                    L19_3 = L16_3
                    L20_3 = {}
                    L20_3.enabled = true
                    L20_3.coords = L15_3
                    L18_3(L19_3, L20_3)
                    L18_3 = L5_1
                    L18_3[L16_3] = L17_3
                    L2_3 = L2_3 + 1
                    L18_3 = Wait
                    L19_3 = 100
                    L18_3(L19_3)
                  end
                  L1_3 = L1_3 + 1
                  L18_3 = L10_1
                  L19_3 = {}
                  L19_3.enabled = true
                  L19_3.coords = L15_3
                  L18_3[L16_3] = L19_3
                end
            end
            else
              L10_3 = L9_3.coords
              if L10_3 then
                L10_3 = L7_3
                L11_3 = L28_1
                L12_3 = L9_3.coords
                L11_3 = L11_3(L12_3)
                L0_3[L10_3] = L11_3
                L12_3 = L5_1
                L12_3 = L12_3[L10_3]
                if L12_3 ~= L11_3 then
                  L12_3 = placeCarliftProp
                  L13_3 = L10_3
                  L14_3 = L9_3
                  L12_3(L13_3, L14_3)
                  L12_3 = L5_1
                  L12_3[L10_3] = L11_3
                  L2_3 = L2_3 + 1
                  L12_3 = Wait
                  L13_3 = 100
                  L12_3(L13_3)
                end
                L1_3 = L1_3 + 1
                L12_3 = L10_1
                L13_3 = {}
                L13_3.enabled = true
                L14_3 = L9_3.coords
                L13_3.coords = L14_3
                L12_3[L10_3] = L13_3
              end
            end
          else
            L10_3 = L7_3
            L11_3 = L7_3
            L12_3 = "_1"
            L11_3 = L11_3 .. L12_3
            L12_3 = L5_1
            L12_3 = L12_3[L10_3]
            if L12_3 then
              L12_3 = removeCarliftProp
              L13_3 = L10_3
              L12_3(L13_3)
              L12_3 = L5_1
              L12_3[L10_3] = nil
            end
            L12_3 = {}
            L13_3 = pairs
            L14_3 = L5_1
            L13_3, L14_3, L15_3, L16_3 = L13_3(L14_3)
            for L17_3, L18_3 in L13_3, L14_3, L15_3, L16_3 do
              L20_3 = L17_3
              L19_3 = L17_3.find
              L21_3 = "^"
              L22_3 = L7_3
              L23_3 = "_"
              L21_3 = L21_3 .. L22_3 .. L23_3
              L19_3 = L19_3(L20_3, L21_3)
              if L19_3 then
                L19_3 = table
                L19_3 = L19_3.insert
                L20_3 = L12_3
                L21_3 = L17_3
                L19_3(L20_3, L21_3)
              end
            end
            L13_3 = ipairs
            L14_3 = L12_3
            L13_3, L14_3, L15_3, L16_3 = L13_3(L14_3)
            for L17_3, L18_3 in L13_3, L14_3, L15_3, L16_3 do
              L19_3 = removeCarliftProp
              L20_3 = L18_3
              L19_3(L20_3)
              L19_3 = L5_1
              L19_3[L18_3] = nil
            end
          end
        end
      end
      L9_3 = Wait
      L10_3 = 50
      L9_3(L10_3)
    end
    L3_3 = {}
    L4_3 = pairs
    L5_3 = L5_1
    L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3)
    for L8_3, L9_3 in L4_3, L5_3, L6_3, L7_3 do
      L10_3 = L0_3[L8_3]
      if not L10_3 then
        L10_3 = table
        L10_3 = L10_3.insert
        L11_3 = L3_3
        L12_3 = L8_3
        L10_3(L11_3, L12_3)
      end
    end
    L4_3 = ipairs
    L5_3 = L3_3
    L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3)
    for L8_3, L9_3 in L4_3, L5_3, L6_3, L7_3 do
      L10_3 = removeCarliftProp
      L11_3 = L9_3
      L10_3(L11_3)
      L10_3 = L5_1
      L10_3[L9_3] = nil
      L10_3 = L8_3 % 2
      if 0 == L10_3 then
        L10_3 = Wait
        L11_3 = 50
        L10_3(L11_3)
      end
    end
    L4_3 = GetGameTimer
    L4_3 = L4_3()
    L18_1 = L4_3
    L4_3 = false
    L17_1 = L4_3
    L4_3 = L7_1
    if L4_3 then
      L4_3 = L7_1
      L5_3 = nil
      L7_1 = L5_3
      L5_3 = L30_1
      L6_3 = L4_3
      L5_3(L6_3)
    end
    L4_3 = L27_1
    L4_3()
  end
  L1_2(L2_2)
end
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:syncCarlifts"
function L33_1(A0_2)
  local L1_2, L2_2
  L1_2 = L30_1
  L2_2 = A0_2
  L1_2(L2_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:updateCarlift"
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if not A0_2 then
    return
  end
  L2_2 = L6_1
  if not L2_2 then
    L2_2 = {}
  end
  L6_1 = L2_2
  L2_2 = L6_1
  L3_2 = L6_1
  L3_2 = L3_2[A0_2]
  if not L3_2 then
    L3_2 = {}
    L4_2 = {}
    L3_2.shopConfig = L4_2
  end
  L2_2[A0_2] = L3_2
  L2_2 = L6_1
  L2_2 = L2_2[A0_2]
  L3_2 = L6_1
  L3_2 = L3_2[A0_2]
  L3_2 = L3_2.shopConfig
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.shopConfig = L3_2
  L2_2 = L6_1
  L2_2 = L2_2[A0_2]
  L2_2 = L2_2.shopConfig
  L2_2.carlift = A1_2
  L2_2 = L30_1
  L3_2 = L6_1
  L2_2(L3_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:removeCarlift"
function L33_1(A0_2)
  local L1_2, L2_2
  L1_2 = removeCarliftProp
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = L6_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L1_2 = L6_1
    L1_2 = L1_2[A0_2]
    L1_2 = L1_2.shopConfig
    if L1_2 then
      L1_2 = L6_1
      L1_2 = L1_2[A0_2]
      L1_2 = L1_2.shopConfig
      L1_2.carlift = nil
    end
  end
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:openCarlift"
function L33_1(A0_2)
  local L1_2, L2_2
  L1_2 = openCarliftUI
  L2_2 = A0_2
  L1_2(L2_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  if not A0_2 then
    return
  end
  L1_2 = removeCarliftProp
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = tostring
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = L8_2
    L8_2 = L8_2.find
    L10_2 = tostring
    L11_2 = A0_2
    L10_2 = L10_2(L11_2)
    L11_2 = "_"
    L10_2 = L10_2 .. L11_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 or L6_2 == A0_2 then
      L8_2 = table
      L8_2 = L8_2.insert
      L9_2 = L1_2
      L10_2 = L6_2
      L8_2(L9_2, L10_2)
    end
  end
  L2_2 = pairs
  L3_2 = L1_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = tostring
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L9_2 = L8_2
    L8_2 = L8_2.find
    L10_2 = tostring
    L11_2 = A0_2
    L10_2 = L10_2(L11_2)
    L11_2 = "_"
    L10_2 = L10_2 .. L11_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 or L6_2 == A0_2 then
      L8_2 = false
      L9_2 = ipairs
      L10_2 = L1_2
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2)
      for L13_2, L14_2 in L9_2, L10_2, L11_2, L12_2 do
        if L14_2 == L6_2 then
          L8_2 = true
          break
        end
      end
      if not L8_2 then
        L9_2 = table
        L9_2 = L9_2.insert
        L10_2 = L1_2
        L11_2 = L6_2
        L9_2(L10_2, L11_2)
      end
    end
  end
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = removeCarliftProp
    L9_2 = L7_2
    L8_2(L9_2)
  end
  L2_2 = L6_1
  if L2_2 then
    L2_2 = L6_1
    L2_2 = L2_2[A0_2]
    if L2_2 then
      L2_2 = L6_1
      L2_2[A0_2] = nil
    end
  end
end
L31_1(L32_1, L33_1)
L31_1 = AddEventHandler
L32_1 = "qs-mechanic-creator:client:updateShops"
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L6_1
  if L0_2 then
    L0_2 = next
    L1_2 = L6_1
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = L6_1
      L1_2 = 0
      L2_2 = pairs
      L3_2 = L0_2
      L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
      for L6_2 in L2_2, L3_2, L4_2, L5_2 do
        L1_2 = L1_2 + 1
      end
      L2_2 = L30_1
      L3_2 = L0_2
      L2_2(L3_2)
    end
  end
end
L31_1(L32_1, L33_1)
L31_1 = CreateThread
function L32_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  while true do
    L0_2 = next
    L1_2 = L0_1
    L0_2 = L0_2(L1_2)
    if not L0_2 then
      L0_2 = next
      L1_2 = L1_1
      L0_2 = L0_2(L1_2)
      if not L0_2 then
        L0_2 = Wait
        L1_2 = 60000
        L0_2(L1_2)
    end
    else
      L0_2 = L17_1
      if L0_2 then
        L0_2 = Wait
        L1_2 = 10000
        L0_2(L1_2)
      else
        L0_2 = L6_1
        if L0_2 then
          L0_2 = next
          L1_2 = L6_1
          L0_2 = L0_2(L1_2)
          if L0_2 then
            goto lbl_34
          end
        end
        L0_2 = Wait
        L1_2 = 60000
        L0_2(L1_2)
        goto lbl_110
        ::lbl_34::
        L0_2 = next
        L1_2 = L5_1
        L0_2 = L0_2(L1_2)
        if not L0_2 then
          L0_2 = Wait
          L1_2 = 60000
          L0_2(L1_2)
        else
          L0_2 = Wait
          L1_2 = 10000
          L0_2(L1_2)
          L0_2 = 0
          L1_2 = pairs
          L2_2 = L5_1
          L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
          for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
            L7_2 = L0_1
            L7_2 = L7_2[L5_2]
            if L7_2 then
              L7_2 = DoesEntityExist
              L8_2 = L0_1
              L8_2 = L8_2[L5_2]
              L7_2 = L7_2(L8_2)
            end
            L8_2 = L1_1
            L8_2 = L8_2[L5_2]
            if L8_2 then
              L8_2 = DoesEntityExist
              L9_2 = L1_1
              L9_2 = L9_2[L5_2]
              L8_2 = L8_2(L9_2)
            end
            if not L7_2 or not L8_2 then
              L0_2 = L0_2 + 1
              L9_2 = removeCarliftProp
              L10_2 = L5_2
              L9_2(L10_2)
              L9_2 = L29_1
              L10_2 = L5_2
              L9_2 = L9_2(L10_2)
              if L9_2 then
                L10_2 = L9_2.enabled
                if L10_2 then
                  L10_2 = placeCarliftProp
                  L11_2 = L5_2
                  L12_2 = L9_2
                  L10_2(L11_2, L12_2)
                  L10_2 = L9_2.coords
                  if not L10_2 then
                    L11_2 = L9_2.locations
                    if L11_2 then
                      L11_2 = L9_2.locations
                      L11_2 = L11_2[1]
                      if L11_2 then
                        L11_2 = L9_2.locations
                        L10_2 = L11_2[1]
                      end
                    end
                  end
                  if L10_2 then
                    L11_2 = L5_1
                    L12_2 = L28_1
                    L13_2 = L10_2
                    L12_2 = L12_2(L13_2)
                    L11_2[L5_2] = L12_2
                  end
                end
              end
            end
          end
        end
      end
    end
    ::lbl_110::
  end
end
L31_1(L32_1)
L31_1 = RegisterNUICallback
L32_1 = "closeCarliftUI"
function L33_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = closeCarliftUI
  L2_2()
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNUICallback
L32_1 = "moveCarlift"
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L16_1
  if L2_2 then
    L2_2 = A0_2.direction
    if L2_2 then
      L2_2 = moveCarlift
      L3_2 = L16_1
      L4_2 = A0_2.direction
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNUICallback
L32_1 = "toggleFreezeCar"
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L16_1
  if not L2_2 then
    L2_2 = A1_2
    L3_2 = "ok"
    L2_2(L3_2)
    return
  end
  L2_2 = L23_1
  L3_2 = L16_1
  L2_2 = L2_2(L3_2)
  L4_2 = L16_1
  L3_2 = L1_1
  L3_2 = L3_2[L4_2]
  if L2_2 and L3_2 then
    L4_2 = L26_1
    L5_2 = L2_2
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
  end
  L4_2 = A1_2
  L5_2 = "ok"
  L4_2(L5_2)
end
L31_1(L32_1, L33_1)
L31_1 = RegisterNetEvent
L32_1 = "qs-mechanic-creator:client:restoreCarliftMovable"
L31_1(L32_1)
L31_1 = AddEventHandler
L32_1 = "qs-mechanic-creator:client:restoreCarliftMovable"
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  if not A0_2 then
    return
  end
  L1_2 = A0_2
  L2_2 = L1_1
  L2_2 = L2_2[L1_2]
  if L2_2 then
    L3_2 = DoesEntityExist
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = L23_1
      L4_2 = L1_2
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L4_2 = DoesEntityExist
        L5_2 = L3_2
        L4_2 = L4_2(L5_2)
        if L4_2 then
          L4_2 = VehToNet
          L5_2 = L3_2
          L4_2 = L4_2(L5_2)
          L5_2 = L4_1
          L5_2 = L5_2[L4_2]
          if L5_2 then
            L5_2 = FreezeEntityPosition
            L6_2 = L3_2
            L7_2 = false
            L5_2(L6_2, L7_2)
            L5_2 = DetachEntity
            L6_2 = L3_2
            L7_2 = true
            L8_2 = true
            L5_2(L6_2, L7_2, L8_2)
            L5_2 = L4_1
            L5_2[L4_2] = nil
            L5_2 = TriggerServerEvent
            L6_2 = "qs-mechanic-creator:server:toggleCarliftVehicle"
            L7_2 = L1_2
            L8_2 = L4_2
            L9_2 = false
            L5_2(L6_2, L7_2, L8_2, L9_2)
          end
        end
      end
    end
  end
  L3_2 = L2_1
  L3_2 = L3_2[L1_2]
  if not L3_2 then
    L3_2 = L10_1
    L3_2 = L3_2[L1_2]
    if L3_2 then
      L3_2 = L10_1
      L3_2 = L3_2[L1_2]
      L4_2 = L3_2.coords
      if L4_2 then
        L5_2 = tonumber
        L6_2 = L4_2.w
        L5_2 = L5_2(L6_2)
        if not L5_2 then
          L5_2 = 0.0
        end
        L6_2 = math
        L6_2 = L6_2.rad
        L7_2 = L5_2
        L6_2 = L6_2(L7_2)
        L7_2 = L0_1
        L7_2 = L7_2[L1_2]
        if L7_2 then
          L7_2 = GetEntityCoords
          L8_2 = L0_1
          L8_2 = L8_2[L1_2]
          L7_2 = L7_2(L8_2)
        end
        if L7_2 then
          L8_2 = L7_2.x
          L9_2 = math
          L9_2 = L9_2.sin
          L10_2 = L6_2
          L9_2 = L9_2(L10_2)
          L9_2 = 0.3 * L9_2
          L8_2 = L8_2 - L9_2
          L9_2 = L7_2.y
          L10_2 = math
          L10_2 = L10_2.cos
          L11_2 = L6_2
          L10_2 = L10_2(L11_2)
          L10_2 = 0.3 * L10_2
          L9_2 = L9_2 + L10_2
          L10_2 = vec3
          L11_2 = L8_2
          L12_2 = L9_2
          L13_2 = L7_2.z
          L13_2 = L13_2 + 0.5
          L10_2 = L10_2(L11_2, L12_2, L13_2)
          L11_2 = vec3
          L12_2 = 4.0
          L13_2 = 6.0
          L14_2 = 3.0
          L11_2 = L11_2(L12_2, L13_2, L14_2)
          L12_2 = CreateCarliftInteract
          L13_2 = L1_2
          L14_2 = L10_2
          L15_2 = L11_2
          L16_2 = L5_2
          L17_2 = _U
          L18_2 = "CARLIFT"
          L17_2 = L17_2(L18_2)
          function L18_2()
            local L0_3, L1_3, L2_3
            L0_3 = TriggerServerEvent
            L1_3 = "qs-mechanic-creator:server:checkCarliftAccess"
            L2_3 = L1_2
            L0_3(L1_3, L2_3)
          end
          L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
          L12_2 = L2_1
          L12_2[L1_2] = true
        end
      end
    end
  end
  L3_2 = Config
  L3_2 = L3_2.Debug
  if L3_2 then
    L3_2 = print
    L4_2 = "^2[DEBUG]^0: Carlift restored to movable state for shop: "
    L5_2 = tostring
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    L4_2 = L4_2 .. L5_2
    L3_2(L4_2)
  end
end
L31_1(L32_1, L33_1)
L31_1 = AddEventHandler
L32_1 = "onResourceStop"
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = pairs
    L2_2 = L0_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = DoesEntityExist
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = L25_1
        L8_2 = L6_2
        L7_2(L8_2)
      end
      L7_2 = L0_1
      L7_2[L5_2] = nil
    end
    L1_2 = pairs
    L2_2 = L1_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = DoesEntityExist
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = L25_1
        L8_2 = L6_2
        L7_2(L8_2)
      end
      L7_2 = L1_1
      L7_2[L5_2] = nil
    end
    L1_2 = pairs
    L2_2 = L2_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = RemoveInteract
      L8_2 = L5_2
      L7_2(L8_2)
      L7_2 = L2_1
      L7_2[L5_2] = nil
    end
    L1_2 = {}
    L3_1 = L1_2
    L1_2 = {}
    L5_1 = L1_2
    L1_2 = {}
    L6_1 = L1_2
    L1_2 = nil
    L7_1 = L1_2
  end
end
L31_1(L32_1, L33_1)
L31_1 = AddEventHandler
L32_1 = "onClientResourceStop"
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = GetHashKey
  L2_2 = L19_1
  L1_2 = L1_2(L2_2)
  L2_2 = GetHashKey
  L3_2 = L20_1
  L2_2 = L2_2(L3_2)
  L3_2 = pairs
  L4_2 = L0_1
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = L25_1
      L10_2 = L8_2
      L9_2(L10_2)
    end
    L9_2 = L0_1
    L9_2[L7_2] = nil
  end
  L3_2 = pairs
  L4_2 = L1_1
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = L25_1
      L10_2 = L8_2
      L9_2(L10_2)
    end
    L9_2 = L1_1
    L9_2[L7_2] = nil
  end
  L3_2 = GetGamePool
  L4_2 = "CObject"
  L3_2 = L3_2(L4_2)
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = DoesEntityExist
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = GetEntityModel
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      if L10_2 == L1_2 or L10_2 == L2_2 then
        L11_2 = L25_1
        L12_2 = L9_2
        L11_2(L12_2)
      end
    end
  end
  L4_2 = pairs
  L5_2 = L2_1
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = RemoveInteract
    L11_2 = L8_2
    L10_2(L11_2)
    L10_2 = L2_1
    L10_2[L8_2] = nil
  end
  L4_2 = {}
  L3_1 = L4_2
  L4_2 = {}
  L5_1 = L4_2
  L4_2 = {}
  L6_1 = L4_2
  L4_2 = nil
  L7_1 = L4_2
  L4_2 = {}
  L8_1 = L4_2
  L4_2 = {}
  L9_1 = L4_2
end
L31_1(L32_1, L33_1)
