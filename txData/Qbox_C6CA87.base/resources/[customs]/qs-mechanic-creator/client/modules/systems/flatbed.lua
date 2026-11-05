local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1
L0_1 = {}
L1_1 = false
L2_1 = nil
L3_1 = nil
L4_1 = nil
L5_1 = {}
L5_1.isSelectingVehicle = false
L5_1.isSelectingForAttach = false
L5_1.textUIShown = false
L5_1.flatbed = nil
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = GetEntityModel
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = string
  L2_2 = L2_2.lower
  L3_2 = GetDisplayNameFromVehicleModel
  L4_2 = L1_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L3_2(L4_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L3_2 = Config
  L3_2 = L3_2.Debug
  if L3_2 then
    L3_2 = print
    L4_2 = "^2[FLATBED DEBUG]^7 Checking vehicle model:"
    L5_2 = L2_2
    L6_2 = "Hash:"
    L7_2 = L1_2
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = print
    L4_2 = "^2[FLATBED DEBUG]^7 Config.Flatbeds:"
    L5_2 = json
    L5_2 = L5_2.encode
    L6_2 = Config
    L6_2 = L6_2.Flatbeds
    L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L5_2(L6_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  end
  L3_2 = ipairs
  L4_2 = Config
  L4_2 = L4_2.Flatbeds
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = string
    L9_2 = L9_2.lower
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L10_2 = GetHashKey
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    L11_2 = GetHashKey
    L12_2 = L9_2
    L11_2 = L11_2(L12_2)
    if L9_2 == L2_2 or L8_2 == L2_2 or L10_2 == L1_2 or L11_2 == L1_2 then
      L12_2 = Config
      L12_2 = L12_2.Debug
      if L12_2 then
        L12_2 = print
        L13_2 = "^2[FLATBED DEBUG]^7 Vehicle IS a flatbed!"
        L12_2(L13_2)
      end
      L12_2 = true
      return L12_2
    end
  end
  L3_2 = Config
  L3_2 = L3_2.Debug
  if L3_2 then
    L3_2 = print
    L4_2 = "^2[FLATBED DEBUG]^7 Vehicle is NOT a flatbed"
    L3_2(L4_2)
  end
  L3_2 = false
  return L3_2
end
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = GetEntityCoords
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = GetClosestVehicle
  L3_2 = L1_2.x
  L4_2 = L1_2.y
  L5_2 = L1_2.z
  L6_2 = 10.0
  L7_2 = 0
  L8_2 = 71
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  if 0 ~= L2_2 then
    L3_2 = L6_1
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      return L2_2
    end
  end
  L3_2 = nil
  return L3_2
end
function L8_1()
  local L0_2, L1_2
  L0_2 = L7_1
  L0_2 = L0_2()
  L0_2 = nil ~= L0_2
  return L0_2
end
IsNearFlatbed = L8_1
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = GetEntityCoords
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = FindFirstVehicle
  L4_2, L5_2 = L4_2()
  L6_2 = nil
  repeat
    L7_2 = DoesEntityExist
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = GetEntityCoords
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      L8_2 = L2_2 - L7_2
      L8_2 = #L8_2
      if L8_2 < 15.0 and L5_2 ~= A0_2 then
        L9_2 = L6_1
        L10_2 = L5_2
        L9_2 = L9_2(L10_2)
        if not L9_2 then
          L9_2 = table
          L9_2 = L9_2.insert
          L10_2 = L3_2
          L11_2 = L5_2
          L9_2(L10_2, L11_2)
        end
      end
    end
    L7_2 = FindNextVehicle
    L8_2 = L4_2
    L7_2, L8_2 = L7_2(L8_2)
    L5_2 = L8_2
    L6_2 = L7_2
  until not L6_2
  L7_2 = EndFindVehicle
  L8_2 = L4_2
  L7_2(L8_2)
  return L3_2
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.flatbed
    if L8_2 == A0_2 then
      L8_2 = NetToVeh
      L9_2 = L6_2
      L8_2 = L8_2(L9_2)
      L9_2 = DoesEntityExist
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 then
        L9_2 = table
        L9_2 = L9_2.insert
        L10_2 = L1_2
        L11_2 = L8_2
        L9_2(L10_2, L11_2)
      end
    end
  end
  return L1_2
end
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = SetEntityDrawOutline
  L2_2 = A0_2
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = SetEntityDrawOutlineColor
  L2_2 = 0
  L3_2 = 150
  L4_2 = 255
  L5_2 = 200
  L1_2(L2_2, L3_2, L4_2, L5_2)
end
function L11_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = SetEntityDrawOutline
    L2_2 = A0_2
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
end
function L12_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = nil
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = 15.0
  end
  L4_2 = FindFirstVehicle
  L4_2, L5_2 = L4_2()
  L6_2 = nil
  repeat
    L7_2 = DoesEntityExist
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = GetEntityCoords
      L8_2 = L5_2
      L7_2 = L7_2(L8_2)
      L8_2 = A0_2 - L7_2
      L8_2 = #L8_2
      if L3_2 > L8_2 then
        L2_2 = L5_2
        L3_2 = L8_2
      end
    end
    L7_2 = FindNextVehicle
    L8_2 = L4_2
    L7_2, L8_2 = L7_2(L8_2)
    L5_2 = L8_2
    L6_2 = L7_2
  until not L6_2
  L7_2 = EndFindVehicle
  L8_2 = L4_2
  L7_2(L8_2)
  L7_2 = L2_2
  L8_2 = L3_2
  return L7_2, L8_2
end
function L13_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = {}
  L2_2 = math
  L2_2 = L2_2.pi
  L2_2 = L2_2 / 180
  L3_2 = A0_2.x
  L2_2 = L2_2 * L3_2
  L1_2.x = L2_2
  L2_2 = math
  L2_2 = L2_2.pi
  L2_2 = L2_2 / 180
  L3_2 = A0_2.y
  L2_2 = L2_2 * L3_2
  L1_2.y = L2_2
  L2_2 = math
  L2_2 = L2_2.pi
  L2_2 = L2_2 / 180
  L3_2 = A0_2.z
  L2_2 = L2_2 * L3_2
  L1_2.z = L2_2
  L2_2 = {}
  L3_2 = math
  L3_2 = L3_2.sin
  L4_2 = L1_2.z
  L3_2 = L3_2(L4_2)
  L3_2 = -L3_2
  L4_2 = math
  L4_2 = L4_2.abs
  L5_2 = math
  L5_2 = L5_2.cos
  L6_2 = L1_2.x
  L5_2, L6_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2)
  L3_2 = L3_2 * L4_2
  L2_2.x = L3_2
  L3_2 = math
  L3_2 = L3_2.cos
  L4_2 = L1_2.z
  L3_2 = L3_2(L4_2)
  L4_2 = math
  L4_2 = L4_2.abs
  L5_2 = math
  L5_2 = L5_2.cos
  L6_2 = L1_2.x
  L5_2, L6_2 = L5_2(L6_2)
  L4_2 = L4_2(L5_2, L6_2)
  L3_2 = L3_2 * L4_2
  L2_2.y = L3_2
  L3_2 = math
  L3_2 = L3_2.sin
  L4_2 = L1_2.x
  L3_2 = L3_2(L4_2)
  L2_2.z = L3_2
  return L2_2
end
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = GetGameplayCamRot
  L2_2 = L2_2()
  L3_2 = GetGameplayCamCoord
  L3_2 = L3_2()
  L4_2 = L13_1
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  L5_2 = {}
  L6_2 = L3_2.x
  L7_2 = L4_2.x
  L7_2 = L7_2 * A0_2
  L6_2 = L6_2 + L7_2
  L5_2.x = L6_2
  L6_2 = L3_2.y
  L7_2 = L4_2.y
  L7_2 = L7_2 * A0_2
  L6_2 = L6_2 + L7_2
  L5_2.y = L6_2
  L6_2 = L3_2.z
  L7_2 = L4_2.z
  L7_2 = L7_2 * A0_2
  L6_2 = L6_2 + L7_2
  L5_2.z = L6_2
  L6_2 = StartShapeTestRay
  L7_2 = L3_2.x
  L8_2 = L3_2.y
  L9_2 = L3_2.z
  L10_2 = L5_2.x
  L11_2 = L5_2.y
  L12_2 = L5_2.z
  L13_2 = 27
  L14_2 = A1_2 or L14_2
  if not A1_2 then
    L14_2 = PlayerPedId
    L14_2 = L14_2()
  end
  L15_2 = 0
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L7_2 = GetShapeTestResult
  L8_2 = L6_2
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2)
  L12_2 = L8_2
  L13_2 = L9_2
  L14_2 = L11_2
  return L12_2, L13_2, L14_2
end
function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = true
  L1_1 = L2_2
  L2_1 = A0_2
  L3_1 = A1_2
  L2_2 = GetEntityModel
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityCoords
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetEntityHeading
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = RequestModel
  L6_2 = L2_2
  L5_2(L6_2)
  while true do
    L5_2 = HasModelLoaded
    L6_2 = L2_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      break
    end
    L5_2 = Wait
    L6_2 = 10
    L5_2(L6_2)
  end
  L5_2 = CreateVehicle
  L6_2 = L2_2
  L7_2 = L3_2.x
  L8_2 = L3_2.y
  L9_2 = L3_2.z
  L10_2 = L4_2
  L11_2 = false
  L12_2 = false
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_1 = L5_2
  L5_2 = lib
  L5_2 = L5_2.getVehicleProperties
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = lib
  L6_2 = L6_2.setVehicleProperties
  L7_2 = L4_1
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = SetEntityAlpha
  L7_2 = L4_1
  L8_2 = 180
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityCollision
  L7_2 = L4_1
  L8_2 = false
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityCompletelyDisableCollision
  L7_2 = L4_1
  L8_2 = false
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityInvincible
  L7_2 = L4_1
  L8_2 = true
  L6_2(L7_2, L8_2)
  L6_2 = FreezeEntityPosition
  L7_2 = L4_1
  L8_2 = true
  L6_2(L7_2, L8_2)
  L6_2 = SetVehicleDoorsLocked
  L7_2 = L4_1
  L8_2 = 2
  L6_2(L7_2, L8_2)
  L6_2 = L4_2
  L7_2 = CreateThread
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3, L20_3, L21_3, L22_3
    while true do
      L0_3 = L1_1
      if not L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 0
      L0_3(L1_3)
      L0_3 = L14_1
      L1_3 = 1000.0
      L2_3 = L4_1
      L0_3, L1_3, L2_3 = L0_3(L1_3, L2_3)
      L3_3 = L1_3
      if L0_3 and 0 ~= L2_3 then
        L4_3 = IsEntityAVehicle
        L5_3 = L2_3
        L4_3 = L4_3(L5_3)
        if L4_3 then
          goto lbl_29
        end
      end
      L4_3 = vector3
      L5_3 = L1_3.x
      L6_3 = L1_3.y
      L7_3 = L1_3.z
      L7_3 = L7_3 + 0.5
      L4_3 = L4_3(L5_3, L6_3, L7_3)
      L3_3 = L4_3
      ::lbl_29::
      L4_3 = IsControlPressed
      L5_3 = 1
      L6_3 = 174
      L4_3 = L4_3(L5_3, L6_3)
      if L4_3 then
        L4_3 = L6_2
        L4_3 = L4_3 - 0.5
        L6_2 = L4_3
      end
      L4_3 = IsControlPressed
      L5_3 = 1
      L6_3 = 175
      L4_3 = L4_3(L5_3, L6_3)
      if L4_3 then
        L4_3 = L6_2
        L4_3 = L4_3 + 0.5
        L6_2 = L4_3
      end
      L4_3 = SetEntityCoordsNoOffset
      L5_3 = L4_1
      L6_3 = L3_3.x
      L7_3 = L3_3.y
      L8_3 = L3_3.z
      L9_3 = false
      L10_3 = false
      L11_3 = false
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
      L4_3 = SetEntityHeading
      L5_3 = L4_1
      L6_3 = L6_2
      L4_3(L5_3, L6_3)
      L4_3 = L3_3.z
      L4_3 = L4_3 + 2.0
      L5_3 = DefaultText3D
      L6_3 = L3_3.x
      L7_3 = L3_3.y
      L8_3 = L4_3
      L9_3 = _U
      L10_3 = "FLATBED_POSITION"
      L9_3 = L9_3(L10_3)
      L10_3 = "\n"
      L11_3 = _U
      L12_3 = "CREATOR_CONFIRM_POSITION"
      L11_3 = L11_3(L12_3)
      L9_3 = L9_3 .. L10_3 .. L11_3
      L5_3(L6_3, L7_3, L8_3, L9_3)
      L5_3 = IsControlJustPressed
      L6_3 = 1
      L7_3 = 38
      L5_3 = L5_3(L6_3, L7_3)
      if L5_3 then
        L5_3 = GetEntityCoords
        L6_3 = L4_1
        L5_3 = L5_3(L6_3)
        L6_3 = GetEntityHeading
        L7_3 = L4_1
        L6_3 = L6_3(L7_3)
        L7_3 = GetEntityCoords
        L8_3 = A0_2
        L7_3 = L7_3(L8_3)
        L8_3 = GetEntityHeading
        L9_3 = A0_2
        L8_3 = L8_3(L9_3)
        L9_3 = L5_3 - L7_3
        L10_3 = vector3
        L11_3 = L9_3.x
        L12_3 = L9_3.y
        L13_3 = L9_3.z
        L13_3 = L13_3 + 0.15
        L10_3 = L10_3(L11_3, L12_3, L13_3)
        L9_3 = L10_3
        L10_3 = math
        L10_3 = L10_3.rad
        L11_3 = L8_3
        L10_3 = L10_3(L11_3)
        L11_3 = L9_3.x
        L12_3 = math
        L12_3 = L12_3.cos
        L13_3 = -L10_3
        L12_3 = L12_3(L13_3)
        L11_3 = L11_3 * L12_3
        L12_3 = L9_3.y
        L13_3 = math
        L13_3 = L13_3.sin
        L14_3 = -L10_3
        L13_3 = L13_3(L14_3)
        L12_3 = L12_3 * L13_3
        L11_3 = L11_3 - L12_3
        L12_3 = L9_3.x
        L13_3 = math
        L13_3 = L13_3.sin
        L14_3 = -L10_3
        L13_3 = L13_3(L14_3)
        L12_3 = L12_3 * L13_3
        L13_3 = L9_3.y
        L14_3 = math
        L14_3 = L14_3.cos
        L15_3 = -L10_3
        L14_3 = L14_3(L15_3)
        L13_3 = L13_3 * L14_3
        L12_3 = L12_3 + L13_3
        L13_3 = vector3
        L14_3 = L11_3
        L15_3 = L12_3
        L16_3 = L9_3.z
        L13_3 = L13_3(L14_3, L15_3, L16_3)
        L14_3 = print
        L15_3 = "^2[FLATBED DEBUG - POSITIONING]^7"
        L14_3(L15_3)
        L14_3 = print
        L15_3 = "Preview Final Coords:"
        L16_3 = L5_3
        L14_3(L15_3, L16_3)
        L14_3 = print
        L15_3 = "Preview Final Heading:"
        L16_3 = L6_3
        L14_3(L15_3, L16_3)
        L14_3 = print
        L15_3 = "Flatbed Coords:"
        L16_3 = L7_3
        L14_3(L15_3, L16_3)
        L14_3 = print
        L15_3 = "Flatbed Heading:"
        L16_3 = L8_3
        L14_3(L15_3, L16_3)
        L14_3 = print
        L15_3 = "World Offset:"
        L16_3 = L9_3
        L14_3(L15_3, L16_3)
        L14_3 = print
        L15_3 = "Local Offset:"
        L16_3 = L13_3
        L14_3(L15_3, L16_3)
        L14_3 = DeleteVehicle
        L15_3 = L4_1
        L14_3(L15_3)
        L14_3 = nil
        L4_1 = L14_3
        L14_3 = VehToNet
        L15_3 = A1_2
        L14_3 = L14_3(L15_3)
        L15_3 = VehToNet
        L16_3 = A0_2
        L15_3 = L15_3(L16_3)
        L16_3 = TriggerServerEvent
        L17_3 = "qs-mechanic-creator:server:attachVehicleToFlatbed"
        L18_3 = L14_3
        L19_3 = L15_3
        L20_3 = {}
        L21_3 = L5_3.x
        L20_3.x = L21_3
        L21_3 = L5_3.y
        L20_3.y = L21_3
        L21_3 = L5_3.z
        L20_3.z = L21_3
        L20_3.heading = L6_3
        L20_3.flatbedHeading = L8_3
        L21_3 = {}
        L22_3 = L13_3.x
        L21_3.x = L22_3
        L22_3 = L13_3.y
        L21_3.y = L22_3
        L22_3 = L13_3.z
        L21_3.z = L22_3
        L20_3.offset = L21_3
        L16_3(L17_3, L18_3, L19_3, L20_3)
        L16_3 = false
        L1_1 = L16_3
        L16_3 = nil
        L2_1 = L16_3
        L16_3 = nil
        L3_1 = L16_3
        break
      end
      L5_3 = IsControlJustPressed
      L6_3 = 1
      L7_3 = 73
      L5_3 = L5_3(L6_3, L7_3)
      if not L5_3 then
        L5_3 = IsControlJustPressed
        L6_3 = 0
        L7_3 = 194
        L5_3 = L5_3(L6_3, L7_3)
        if not L5_3 then
          goto lbl_254
        end
      end
      L5_3 = DeleteVehicle
      L6_3 = L4_1
      L5_3(L6_3)
      L5_3 = nil
      L4_1 = L5_3
      L5_3 = lib
      L5_3 = L5_3.notify
      L6_3 = {}
      L7_3 = _U
      L8_3 = "FLATBED_CANCELLED"
      L7_3 = L7_3(L8_3)
      L6_3.title = L7_3
      L7_3 = _U
      L8_3 = "FLATBED_CANCELLED"
      L7_3 = L7_3(L8_3)
      L6_3.description = L7_3
      L6_3.type = "info"
      L5_3(L6_3)
      L5_3 = false
      L1_1 = L5_3
      L5_3 = nil
      L2_1 = L5_3
      L5_3 = nil
      L3_1 = L5_3
      do break end
      ::lbl_254::
    end
  end
  L7_2(L8_2)
end
function L16_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = SetTextScale
  L5_2 = 0.35
  L6_2 = 0.35
  L4_2(L5_2, L6_2)
  L4_2 = SetTextFont
  L5_2 = Config
  L5_2 = L5_2.TextFont3D
  if not L5_2 then
    L5_2 = 4
  end
  L4_2(L5_2)
  L4_2 = SetTextProportional
  L5_2 = 1
  L4_2(L5_2)
  L4_2 = SetTextColour
  L5_2 = 255
  L6_2 = 255
  L7_2 = 255
  L8_2 = 215
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = SetTextEntry
  L5_2 = "STRING"
  L4_2(L5_2)
  L4_2 = SetTextCentre
  L5_2 = true
  L4_2(L5_2)
  L4_2 = AddTextComponentString
  L5_2 = A3_2
  L4_2(L5_2)
  L4_2 = SetDrawOrigin
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  L8_2 = 0
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = DrawText
  L5_2 = 0.0
  L6_2 = 0.0
  L4_2(L5_2, L6_2)
  L4_2 = string
  L4_2 = L4_2.len
  L5_2 = A3_2
  L4_2 = L4_2(L5_2)
  L4_2 = L4_2 / 370
  L5_2 = DrawRect
  L6_2 = 0.0
  L7_2 = 0.0125
  L8_2 = 0.017 + L4_2
  L9_2 = 0.03
  L10_2 = 0
  L11_2 = 0
  L12_2 = 0
  L13_2 = 75
  L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  L5_2 = ClearDrawOrigin
  L5_2()
end
DefaultText3D = L16_1
function L16_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = true
  L1_1 = L2_2
  L2_1 = A1_2
  L3_1 = A0_2
  L2_2 = GetEntityModel
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityCoords
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetEntityHeading
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = RequestModel
  L6_2 = L2_2
  L5_2(L6_2)
  while true do
    L5_2 = HasModelLoaded
    L6_2 = L2_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      break
    end
    L5_2 = Wait
    L6_2 = 10
    L5_2(L6_2)
  end
  L5_2 = CreateVehicle
  L6_2 = L2_2
  L7_2 = L3_2.x
  L8_2 = L3_2.y
  L9_2 = L3_2.z
  L10_2 = L4_2
  L11_2 = false
  L12_2 = false
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L4_1 = L5_2
  L5_2 = lib
  L5_2 = L5_2.getVehicleProperties
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  L6_2 = lib
  L6_2 = L6_2.setVehicleProperties
  L7_2 = L4_1
  L8_2 = L5_2
  L6_2(L7_2, L8_2)
  L6_2 = SetEntityAlpha
  L7_2 = L4_1
  L8_2 = 180
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityCollision
  L7_2 = L4_1
  L8_2 = false
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityCompletelyDisableCollision
  L7_2 = L4_1
  L8_2 = false
  L9_2 = false
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = SetEntityInvincible
  L7_2 = L4_1
  L8_2 = true
  L6_2(L7_2, L8_2)
  L6_2 = FreezeEntityPosition
  L7_2 = L4_1
  L8_2 = true
  L6_2(L7_2, L8_2)
  L6_2 = SetVehicleDoorsLocked
  L7_2 = L4_1
  L8_2 = 2
  L6_2(L7_2, L8_2)
  L6_2 = L4_2
  L7_2 = CreateThread
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3
    while true do
      L0_3 = L1_1
      if not L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 0
      L0_3(L1_3)
      L0_3 = L14_1
      L1_3 = 1000.0
      L2_3 = L4_1
      L0_3, L1_3, L2_3 = L0_3(L1_3, L2_3)
      L3_3 = L1_3
      if L0_3 and 0 ~= L2_3 then
        L4_3 = IsEntityAVehicle
        L5_3 = L2_3
        L4_3 = L4_3(L5_3)
        if L4_3 then
          goto lbl_29
        end
      end
      L4_3 = vector3
      L5_3 = L1_3.x
      L6_3 = L1_3.y
      L7_3 = L1_3.z
      L7_3 = L7_3 + 0.5
      L4_3 = L4_3(L5_3, L6_3, L7_3)
      L3_3 = L4_3
      ::lbl_29::
      L4_3 = IsControlPressed
      L5_3 = 1
      L6_3 = 174
      L4_3 = L4_3(L5_3, L6_3)
      if L4_3 then
        L4_3 = L6_2
        L4_3 = L4_3 - 0.5
        L6_2 = L4_3
      end
      L4_3 = IsControlPressed
      L5_3 = 1
      L6_3 = 175
      L4_3 = L4_3(L5_3, L6_3)
      if L4_3 then
        L4_3 = L6_2
        L4_3 = L4_3 + 0.5
        L6_2 = L4_3
      end
      L4_3 = SetEntityCoordsNoOffset
      L5_3 = L4_1
      L6_3 = L3_3.x
      L7_3 = L3_3.y
      L8_3 = L3_3.z
      L9_3 = false
      L10_3 = false
      L11_3 = false
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
      L4_3 = SetEntityHeading
      L5_3 = L4_1
      L6_3 = L6_2
      L4_3(L5_3, L6_3)
      L4_3 = L3_3.z
      L4_3 = L4_3 + 2.0
      L5_3 = DefaultText3D
      L6_3 = L3_3.x
      L7_3 = L3_3.y
      L8_3 = L4_3
      L9_3 = _U
      L10_3 = "FLATBED_POSITION_GROUND"
      L9_3 = L9_3(L10_3)
      L10_3 = "\n"
      L11_3 = _U
      L12_3 = "CREATOR_CONFIRM_POSITION"
      L11_3 = L11_3(L12_3)
      L9_3 = L9_3 .. L10_3 .. L11_3
      L5_3(L6_3, L7_3, L8_3, L9_3)
      L5_3 = IsControlJustPressed
      L6_3 = 1
      L7_3 = 38
      L5_3 = L5_3(L6_3, L7_3)
      if L5_3 then
        L5_3 = GetEntityCoords
        L6_3 = L4_1
        L5_3 = L5_3(L6_3)
        L6_3 = GetEntityHeading
        L7_3 = L4_1
        L6_3 = L6_3(L7_3)
        L7_3 = DeleteVehicle
        L8_3 = L4_1
        L7_3(L8_3)
        L7_3 = nil
        L4_1 = L7_3
        L7_3 = VehToNet
        L8_3 = A0_2
        L7_3 = L7_3(L8_3)
        L8_3 = VehToNet
        L9_3 = A1_2
        L8_3 = L8_3(L9_3)
        L9_3 = TriggerServerEvent
        L10_3 = "qs-mechanic-creator:server:detachVehicleFromFlatbed"
        L11_3 = L7_3
        L12_3 = L8_3
        L13_3 = {}
        L14_3 = L5_3.x
        L13_3.x = L14_3
        L14_3 = L5_3.y
        L13_3.y = L14_3
        L14_3 = L5_3.z
        L13_3.z = L14_3
        L13_3.heading = L6_3
        L9_3(L10_3, L11_3, L12_3, L13_3)
        L9_3 = false
        L1_1 = L9_3
        L9_3 = nil
        L2_1 = L9_3
        L9_3 = nil
        L3_1 = L9_3
        break
      end
      L5_3 = IsControlJustPressed
      L6_3 = 1
      L7_3 = 73
      L5_3 = L5_3(L6_3, L7_3)
      if not L5_3 then
        L5_3 = IsControlJustPressed
        L6_3 = 0
        L7_3 = 194
        L5_3 = L5_3(L6_3, L7_3)
        if not L5_3 then
          goto lbl_160
        end
      end
      L5_3 = DeleteVehicle
      L6_3 = L4_1
      L5_3(L6_3)
      L5_3 = nil
      L4_1 = L5_3
      L5_3 = lib
      L5_3 = L5_3.notify
      L6_3 = {}
      L7_3 = _U
      L8_3 = "FLATBED_CANCELLED"
      L7_3 = L7_3(L8_3)
      L6_3.title = L7_3
      L7_3 = _U
      L8_3 = "FLATBED_CANCELLED"
      L7_3 = L7_3(L8_3)
      L6_3.description = L7_3
      L6_3.type = "info"
      L5_3(L6_3)
      L5_3 = false
      L1_1 = L5_3
      L5_3 = nil
      L2_1 = L5_3
      L5_3 = nil
      L3_1 = L5_3
      do break end
      ::lbl_160::
    end
  end
  L7_2(L8_2)
end
function L17_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L5_1.isSelectingVehicle = true
  L5_1.isSelectingForAttach = A1_2
  L5_1.flatbed = A0_2
  if A1_2 then
    L2_2 = _U
    L3_2 = "FLATBED_SELECT_VEHICLE"
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_14
    end
  end
  L2_2 = _U
  L3_2 = "FLATBED_SELECT_DETACH"
  L2_2 = L2_2(L3_2)
  ::lbl_14::
  L3_2 = lib
  L3_2 = L3_2.notify
  L4_2 = {}
  L5_2 = _U
  L6_2 = "RADIAL_FLATBED"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L4_2.description = L2_2
  L4_2.type = "info"
  L4_2.duration = 7000
  L3_2(L4_2)
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
    L0_3 = nil
    while true do
      L1_3 = L5_1.isSelectingVehicle
      if not L1_3 then
        break
      end
      L1_3 = PlayerPedId
      L1_3 = L1_3()
      L2_3 = GetEntityCoords
      L3_3 = L1_3
      L2_3 = L2_3(L3_3)
      L3_3 = L12_1
      L4_3 = L2_3
      L5_3 = 15.0
      L3_3, L4_3 = L3_3(L4_3, L5_3)
      if L3_3 then
        L5_3 = A0_2
        if L3_3 ~= L5_3 then
          L5_3 = L6_1
          L6_3 = L3_3
          L5_3 = L5_3(L6_3)
          if not L5_3 then
            L5_3 = L5_1.isSelectingForAttach
            if L5_3 then
              L5_3 = false
              L6_3 = pairs
              L7_3 = L0_1
              L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3)
              for L10_3, L11_3 in L6_3, L7_3, L8_3, L9_3 do
                L12_3 = L11_3.flatbed
                L13_3 = A0_2
                if L12_3 == L13_3 then
                  L12_3 = NetToVeh
                  L13_3 = L10_3
                  L12_3 = L12_3(L13_3)
                  if L12_3 == L3_3 then
                    L5_3 = true
                    break
                  end
                end
              end
              if L5_3 then
                L3_3 = nil
              end
            else
              L5_3 = false
              L6_3 = pairs
              L7_3 = L0_1
              L6_3, L7_3, L8_3, L9_3 = L6_3(L7_3)
              for L10_3, L11_3 in L6_3, L7_3, L8_3, L9_3 do
                L12_3 = L11_3.flatbed
                L13_3 = A0_2
                if L12_3 == L13_3 then
                  L12_3 = NetToVeh
                  L13_3 = L10_3
                  L12_3 = L12_3(L13_3)
                  if L12_3 == L3_3 then
                    L5_3 = true
                    break
                  end
                end
              end
              if not L5_3 then
                L3_3 = nil
              end
            end
        end
      end
      else
        L3_3 = nil
      end
      if L3_3 and L3_3 ~= L0_3 then
        if L0_3 then
          L5_3 = L11_1
          L6_3 = L0_3
          L5_3(L6_3)
        end
        L5_3 = L10_1
        L6_3 = L3_3
        L5_3(L6_3)
        L0_3 = L3_3
      elseif not L3_3 and L0_3 then
        L5_3 = L11_1
        L6_3 = L0_3
        L5_3(L6_3)
        L0_3 = nil
      end
      if L3_3 then
        L5_3 = L5_1.textUIShown
        if not L5_3 then
          L5_3 = lib
          L5_3 = L5_3.showTextUI
          L6_3 = "[E] Select Vehicle | [Backspace] Cancel"
          L5_3(L6_3)
          L5_1.textUIShown = true
        end
        L5_3 = IsControlJustPressed
        L6_3 = 0
        L7_3 = 38
        L5_3 = L5_3(L6_3, L7_3)
        if L5_3 then
          if L0_3 then
            L5_3 = L11_1
            L6_3 = L0_3
            L5_3(L6_3)
          end
          L5_3 = L5_1.textUIShown
          if L5_3 then
            L5_3 = lib
            L5_3 = L5_3.hideTextUI
            L5_3()
            L5_1.textUIShown = false
          end
          L5_1.isSelectingVehicle = false
          L5_3 = L5_1.isSelectingForAttach
          if L5_3 then
            L5_3 = L15_1
            L6_3 = A0_2
            L7_3 = L3_3
            L5_3(L6_3, L7_3)
            break
          end
          L5_3 = L16_1
          L6_3 = L3_3
          L7_3 = A0_2
          L5_3(L6_3, L7_3)
          break
        end
      else
        L5_3 = L5_1.textUIShown
        if L5_3 then
          L5_3 = lib
          L5_3 = L5_3.hideTextUI
          L5_3()
          L5_1.textUIShown = false
        end
      end
      L5_3 = IsControlJustPressed
      L6_3 = 0
      L7_3 = 194
      L5_3 = L5_3(L6_3, L7_3)
      if L5_3 then
        if L0_3 then
          L5_3 = L11_1
          L6_3 = L0_3
          L5_3(L6_3)
        end
        L5_3 = L5_1.textUIShown
        if L5_3 then
          L5_3 = lib
          L5_3 = L5_3.hideTextUI
          L5_3()
          L5_1.textUIShown = false
        end
        L5_1.isSelectingVehicle = false
        L5_1.flatbed = nil
        L5_3 = lib
        L5_3 = L5_3.notify
        L6_3 = {}
        L7_3 = _U
        L8_3 = "FLATBED_CANCELLED"
        L7_3 = L7_3(L8_3)
        L6_3.title = L7_3
        L7_3 = _U
        L8_3 = "FLATBED_CANCELLED"
        L7_3 = L7_3(L8_3)
        L6_3.description = L7_3
        L6_3.type = "info"
        L5_3(L6_3)
        break
      end
      L5_3 = Wait
      L6_3 = 0
      L5_3(L6_3)
    end
  end
  L3_2(L4_2)
end
function L18_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L7_1
  L0_2 = L0_2()
  if not L0_2 then
    L1_2 = lib
    L1_2 = L1_2.notify
    L2_2 = {}
    L3_2 = _U
    L4_2 = "FLATBED_NOT_NEAR"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "FLATBED_NOT_NEAR"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = L9_1
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = L8_1
  L3_2 = L0_2
  L2_2 = L2_2(L3_2)
  L3_2 = {}
  L4_2 = #L2_2
  if not (L4_2 > 0) then
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = L3_2
  L6_2 = {}
  L7_2 = _U
  L8_2 = "FLATBED_ATTACH"
  L7_2 = L7_2(L8_2)
  L6_2.title = L7_2
  L7_2 = _U
  L8_2 = "FLATBED_SELECT_VEHICLE"
  L7_2 = L7_2(L8_2)
  L6_2.description = L7_2
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = L17_1
    L1_3 = L0_2
    L2_3 = true
    L0_3(L1_3, L2_3)
  end
  L6_2.onSelect = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = #L1_2
  if not (L4_2 > 0) then
  end
  L4_2 = table
  L4_2 = L4_2.insert
  L5_2 = L3_2
  L6_2 = {}
  L7_2 = _U
  L8_2 = "FLATBED_DETACH"
  L7_2 = L7_2(L8_2)
  L6_2.title = L7_2
  L7_2 = _U
  L8_2 = "FLATBED_SELECT_DETACH"
  L7_2 = L7_2(L8_2)
  L6_2.description = L7_2
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = L17_1
    L1_3 = L0_2
    L2_3 = false
    L0_3(L1_3, L2_3)
  end
  L6_2.onSelect = L7_2
  L4_2(L5_2, L6_2)
  L4_2 = lib
  L4_2 = L4_2.registerContext
  L5_2 = {}
  L5_2.id = "flatbed_menu"
  L6_2 = _U
  L7_2 = "RADIAL_FLATBED"
  L6_2 = L6_2(L7_2)
  L5_2.title = L6_2
  L5_2.options = L3_2
  L4_2(L5_2)
  L4_2 = lib
  L4_2 = L4_2.showContext
  L5_2 = "flatbed_menu"
  L4_2(L5_2)
end
StartFlatbedManagement = L18_1
L18_1 = RegisterNetEvent
L19_1 = "qs-mechanic-creator:client:attachVehicleToFlatbed"
function L20_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L3_2 = NetToVeh
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = NetToVeh
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = DoesEntityExist
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L5_2 = DoesEntityExist
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_18
    end
  end
  do return end
  ::lbl_18::
  L5_2 = GetEntityHeading
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = A2_2.heading
  L7_2 = A2_2.flatbedHeading
  L6_2 = L6_2 - L7_2
  L7_2 = print
  L8_2 = "^3[FLATBED DEBUG - ATTACHING]^7"
  L7_2(L8_2)
  L7_2 = print
  L8_2 = "Position Data:"
  L9_2 = json
  L9_2 = L9_2.encode
  L10_2 = A2_2
  L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L9_2(L10_2)
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L7_2 = print
  L8_2 = "Current Flatbed Heading:"
  L9_2 = L5_2
  L7_2(L8_2, L9_2)
  L7_2 = print
  L8_2 = "Original Flatbed Heading:"
  L9_2 = A2_2.flatbedHeading
  L7_2(L8_2, L9_2)
  L7_2 = print
  L8_2 = "Vehicle Heading:"
  L9_2 = A2_2.heading
  L7_2(L8_2, L9_2)
  L7_2 = print
  L8_2 = "Relative Heading:"
  L9_2 = L6_2
  L7_2(L8_2, L9_2)
  L7_2 = print
  L8_2 = "Offset to use:"
  L9_2 = A2_2.offset
  L9_2 = L9_2.x
  L10_2 = A2_2.offset
  L10_2 = L10_2.y
  L11_2 = A2_2.offset
  L11_2 = L11_2.z
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = GetEntityCoords
  L8_2 = L3_2
  L7_2 = L7_2(L8_2)
  L8_2 = GetEntityHeading
  L9_2 = L3_2
  L8_2 = L8_2(L9_2)
  L9_2 = print
  L10_2 = "Vehicle Coords Before Attach:"
  L11_2 = L7_2
  L9_2(L10_2, L11_2)
  L9_2 = print
  L10_2 = "Vehicle Heading Before Attach:"
  L11_2 = L8_2
  L9_2(L10_2, L11_2)
  L9_2 = FreezeEntityPosition
  L10_2 = L3_2
  L11_2 = true
  L9_2(L10_2, L11_2)
  L9_2 = AttachEntityToEntity
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = 0
  L13_2 = A2_2.offset
  L13_2 = L13_2.x
  L14_2 = A2_2.offset
  L14_2 = L14_2.y
  L15_2 = A2_2.offset
  L15_2 = L15_2.z
  L16_2 = 0.0
  L17_2 = 0.0
  L18_2 = L6_2
  L19_2 = false
  L20_2 = false
  L21_2 = false
  L22_2 = false
  L23_2 = 2
  L24_2 = true
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L9_2 = Wait
  L10_2 = 50
  L9_2(L10_2)
  L9_2 = GetEntityCoords
  L10_2 = L3_2
  L9_2 = L9_2(L10_2)
  L10_2 = GetEntityHeading
  L11_2 = L3_2
  L10_2 = L10_2(L11_2)
  L11_2 = print
  L12_2 = "Vehicle Coords After Attach:"
  L13_2 = L9_2
  L11_2(L12_2, L13_2)
  L11_2 = print
  L12_2 = "Vehicle Heading After Attach:"
  L13_2 = L10_2
  L11_2(L12_2, L13_2)
  L11_2 = print
  L12_2 = "Expected Coords:"
  L13_2 = A2_2.x
  L14_2 = A2_2.y
  L15_2 = A2_2.z
  L11_2(L12_2, L13_2, L14_2, L15_2)
  L11_2 = print
  L12_2 = "Expected Heading:"
  L13_2 = A2_2.heading
  L11_2(L12_2, L13_2)
  L11_2 = L0_1
  L12_2 = {}
  L12_2.flatbed = L4_2
  L12_2.position = A2_2
  L11_2[A0_2] = L12_2
  L11_2 = lib
  L11_2 = L11_2.notify
  L12_2 = {}
  L13_2 = _U
  L14_2 = "FLATBED_ATTACHED"
  L13_2 = L13_2(L14_2)
  L12_2.title = L13_2
  L13_2 = _U
  L14_2 = "FLATBED_ATTACHED"
  L13_2 = L13_2(L14_2)
  L12_2.description = L13_2
  L12_2.type = "success"
  L11_2(L12_2)
end
L18_1(L19_1, L20_1)
L18_1 = RegisterNetEvent
L19_1 = "qs-mechanic-creator:client:detachVehicleFromFlatbed"
function L20_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = NetToVeh
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = DoesEntityExist
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    return
  end
  L3_2 = DetachEntity
  L4_2 = L2_2
  L5_2 = true
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = FreezeEntityPosition
  L4_2 = L2_2
  L5_2 = false
  L3_2(L4_2, L5_2)
  L3_2 = SetEntityCoordsNoOffset
  L4_2 = L2_2
  L5_2 = A1_2.x
  L6_2 = A1_2.y
  L7_2 = A1_2.z
  L8_2 = false
  L9_2 = false
  L10_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L3_2 = SetEntityHeading
  L4_2 = L2_2
  L5_2 = A1_2.heading
  L3_2(L4_2, L5_2)
  L3_2 = L0_1
  L3_2[A0_2] = nil
  L3_2 = lib
  L3_2 = L3_2.notify
  L4_2 = {}
  L5_2 = _U
  L6_2 = "FLATBED_DETACHED"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = _U
  L6_2 = "FLATBED_DETACHED"
  L5_2 = L5_2(L6_2)
  L4_2.description = L5_2
  L4_2.type = "success"
  L3_2(L4_2)
end
L18_1(L19_1, L20_1)
