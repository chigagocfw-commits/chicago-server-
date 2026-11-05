local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1, L33_1, L34_1, L35_1
L0_1 = joaat
L1_1 = "prop_laptop_01a"
L0_1 = L0_1(L1_1)
L1_1 = joaat
L2_1 = "prop_pallet_03a"
L1_1 = L1_1(L2_1)
L2_1 = joaat
L3_1 = "prop_car_engine_01"
L2_1 = L2_1(L3_1)
L3_1 = joaat
L4_1 = "xs_prop_x18_engine_hoist_02a"
L3_1 = L3_1(L4_1)
L4_1 = {}
L5_1 = {}
L6_1 = {}
L7_1 = {}
L8_1 = {}
L9_1 = {}
L10_1 = false
L11_1 = {}
L12_1 = {}
function L13_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = tostring
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  A0_2 = L3_2
  L3_2 = L12_1
  L4_2 = {}
  L5_2 = vector3
  L6_2 = A1_2.x
  L7_2 = A1_2.y
  L8_2 = A1_2.z
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2.coords = L5_2
  L4_2.heading = A2_2
  L3_2[A0_2] = L4_2
end
L14_1 = nil
L15_1 = {}
L15_1.shopId = nil
L15_1.prop = nil
L15_1.attached = false
L15_1.vehicle = nil
L15_1.bonnetRemoved = false
L15_1.engineProp = nil
L15_1.engineAttached = false
L15_1.attachedToPallet = false
L15_1.palletProp = nil
L15_1.engineFromPallet = false
L15_1.engineSourceShopId = nil
L15_1.engineType = nil
L15_1.originalEngineData = nil
L15_1.isBusy = false
function L16_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = World3dToScreen2d
  L3_2 = A0_2.x
  L4_2 = A0_2.y
  L5_2 = A0_2.z
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2, L5_2)
  L5_2 = GetGameplayCamCoords
  L5_2 = L5_2()
  L6_2 = L5_2 - A0_2
  L6_2 = #L6_2
  L7_2 = 1
  L7_2 = L7_2 / L6_2
  L7_2 = L7_2 * 2
  L8_2 = GetGameplayCamFov
  L8_2 = L8_2()
  L9_2 = 1
  L8_2 = L9_2 / L8_2
  L8_2 = L8_2 * 100
  L7_2 = L7_2 * L8_2
  if L2_2 then
    L9_2 = SetTextScale
    L10_2 = 0.0 * L7_2
    L11_2 = 0.55 * L7_2
    L9_2(L10_2, L11_2)
    L9_2 = SetTextFont
    L10_2 = Config
    L10_2 = L10_2.TextFont3D
    if not L10_2 then
      L10_2 = 4
    end
    L9_2(L10_2)
    L9_2 = SetTextProportional
    L10_2 = 1
    L9_2(L10_2)
    L9_2 = SetTextColour
    L10_2 = 255
    L11_2 = 255
    L12_2 = 255
    L13_2 = 215
    L9_2(L10_2, L11_2, L12_2, L13_2)
    L9_2 = SetTextDropshadow
    L10_2 = 0
    L11_2 = 0
    L12_2 = 0
    L13_2 = 0
    L14_2 = 255
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    L9_2 = SetTextEdge
    L10_2 = 2
    L11_2 = 0
    L12_2 = 0
    L13_2 = 0
    L14_2 = 150
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    L9_2 = SetTextDropShadow
    L9_2()
    L9_2 = SetTextOutline
    L9_2()
    L9_2 = SetTextEntry
    L10_2 = "STRING"
    L9_2(L10_2)
    L9_2 = SetTextCentre
    L10_2 = 1
    L9_2(L10_2)
    L9_2 = AddTextComponentString
    L10_2 = A1_2
    L9_2(L10_2)
    L9_2 = DrawText
    L10_2 = L3_2
    L11_2 = L4_2
    L9_2(L10_2, L11_2)
  end
end
function L17_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = GetHashKey
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_12
    end
  end
  L1_2 = A0_2
  ::lbl_12::
  if L1_2 and 0 ~= L1_2 then
    L2_2 = IsModelInCdimage
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_23
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_23::
  L2_2 = HasModelLoaded
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = RequestModel
    L3_2 = L1_2
    L2_2(L3_2)
    L2_2 = 0
    while true do
      L3_2 = HasModelLoaded
      L4_2 = L1_2
      L3_2 = L3_2(L4_2)
      if not (not L3_2 and L2_2 < 100) then
        break
      end
      L3_2 = Wait
      L4_2 = 10
      L3_2(L4_2)
      L2_2 = L2_2 + 1
    end
  end
  L2_2 = HasModelLoaded
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L2_2 = L1_2 or L2_2
  if not L2_2 or not L1_2 then
    L2_2 = nil
  end
  return L2_2
end
function L18_1(A0_2)
  local L1_2, L2_2, L3_2
  if A0_2 then
    L1_2 = DoesEntityExist
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = DeleteEntity
      L2_2 = A0_2
      L1_2(L2_2)
      L1_2 = 0
      while true do
        L2_2 = DoesEntityExist
        L3_2 = A0_2
        L2_2 = L2_2(L3_2)
        if not (L2_2 and L1_2 < 50) then
          break
        end
        L2_2 = Wait
        L3_2 = 10
        L2_2(L3_2)
        L1_2 = L1_2 + 1
      end
    end
  end
end
function L19_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = L17_1
  L3_2 = L2_1
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L3_2 = nil
    L4_2 = nil
    return L3_2, L4_2
  end
  L3_2 = CreateObject
  L4_2 = L2_2
  L5_2 = A0_2.x
  L6_2 = A0_2.y
  L7_2 = A0_2.z
  L8_2 = true
  L9_2 = true
  L10_2 = true
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  if not L3_2 or 0 == L3_2 then
    L4_2 = nil
    L5_2 = nil
    return L4_2, L5_2
  end
  L4_2 = SetEntityHeading
  L5_2 = L3_2
  L6_2 = A1_2 or L6_2
  if not A1_2 then
    L6_2 = 0.0
  end
  L4_2(L5_2, L6_2)
  L4_2 = SetEntityCollision
  L5_2 = L3_2
  L6_2 = false
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = SetEntityAsMissionEntity
  L5_2 = L3_2
  L6_2 = true
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = 0
  while true do
    L5_2 = NetworkGetEntityIsNetworked
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if not (not L5_2 and L4_2 < 50) then
      break
    end
    L5_2 = Wait
    L6_2 = 10
    L5_2(L6_2)
    L4_2 = L4_2 + 1
  end
  L5_2 = NetworkGetEntityIsNetworked
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L5_2 = NetworkGetNetworkIdFromEntity
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    L6_2 = SetNetworkIdCanMigrate
    L7_2 = L5_2
    L8_2 = true
    L6_2(L7_2, L8_2)
    L6_2 = SetNetworkIdExistsOnAllMachines
    L7_2 = L5_2
    L8_2 = true
    L6_2(L7_2, L8_2)
    L6_2 = L3_2
    L7_2 = L5_2
    return L6_2, L7_2
  end
  L5_2 = NetworkRegisterEntityAsNetworked
  L6_2 = L3_2
  L5_2(L6_2)
  L5_2 = Wait
  L6_2 = 50
  L5_2(L6_2)
  L5_2 = NetworkGetNetworkIdFromEntity
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  if L5_2 and 0 ~= L5_2 then
    L6_2 = SetNetworkIdCanMigrate
    L7_2 = L5_2
    L8_2 = true
    L6_2(L7_2, L8_2)
    L6_2 = SetNetworkIdExistsOnAllMachines
    L7_2 = L5_2
    L8_2 = true
    L6_2(L7_2, L8_2)
  end
  L6_2 = L3_2
  L7_2 = L5_2
  return L6_2, L7_2
end
function L20_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = tostring
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = L4_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = RemoveInteract
    L3_2 = L1_2
    L2_2(L3_2)
    L2_2 = L4_1
    L2_2[A0_2] = nil
  end
  L2_2 = L6_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L4_2 = L2_2
    L3_2 = L2_2.remove
    L3_2(L4_2)
    L3_2 = L6_1
    L3_2[A0_2] = nil
  end
  L3_2 = L7_1
  L3_2 = L3_2[A0_2]
  if L3_2 then
    L4_2 = RemoveInteract
    L5_2 = L3_2
    L4_2(L5_2)
    L4_2 = L7_1
    L4_2[A0_2] = nil
  end
  L4_2 = L8_1
  L4_2[A0_2] = nil
  L4_2 = L12_1
  L4_2[A0_2] = nil
  L4_2 = L5_1
  L4_2 = L4_2[A0_2]
  if L4_2 then
    L5_2 = L4_2.laptop
    if L5_2 then
      L5_2 = L18_1
      L6_2 = L4_2.laptop
      L5_2(L6_2)
      L4_2.laptop = nil
    end
    L5_2 = L4_2.pallet
    if L5_2 then
      L5_2 = L18_1
      L6_2 = L4_2.pallet
      L5_2(L6_2)
      L4_2.pallet = nil
    end
    L5_2 = L4_2.engine
    if L5_2 then
      L5_2 = L18_1
      L6_2 = L4_2.engine
      L5_2(L6_2)
      L4_2.engine = nil
    end
    L5_2 = L4_2.hoist
    if L5_2 then
      L5_2 = L18_1
      L6_2 = L4_2.hoist
      L5_2(L6_2)
      L4_2.hoist = nil
    end
    L5_2 = L5_1
    L5_2[A0_2] = nil
  end
end
function L21_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = pairs
  L1_2 = L4_1
  L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
  for L4_2 in L0_2, L1_2, L2_2, L3_2 do
    L5_2 = L20_1
    L6_2 = L4_2
    L5_2(L6_2)
  end
  L0_2 = L15_1.engineProp
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L15_1.engineProp
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = L18_1
      L1_2 = L15_1.engineProp
      L0_2(L1_2)
      L15_1.engineProp = nil
    end
  end
  L0_2 = L15_1.prop
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L15_1.prop
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = L18_1
      L1_2 = L15_1.prop
      L0_2(L1_2)
      L15_1.prop = nil
    end
  end
  L15_1.shopId = nil
  L15_1.attached = false
  L15_1.vehicle = nil
  L15_1.bonnetRemoved = false
  L15_1.engineAttached = false
  L15_1.attachedToPallet = false
  L15_1.palletProp = nil
  L15_1.engineFromPallet = false
  L15_1.engineSourceShopId = nil
  L15_1.engineType = nil
  L15_1.originalEngineData = nil
end
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = A0_2.x
  if L1_2 then
    L1_2 = A0_2.y
    if L1_2 then
      L1_2 = A0_2.z
      if L1_2 then
        L1_2 = vector3
        L2_2 = A0_2.x
        L2_2 = L2_2 + 0.0
        L3_2 = A0_2.y
        L3_2 = L3_2 + 0.0
        L4_2 = A0_2.z
        L4_2 = L4_2 + 0.0
        return L1_2(L2_2, L3_2, L4_2)
      end
    end
  end
  L1_2 = nil
  return L1_2
end
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if not A0_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = A0_2.coords
  if not L1_2 then
    L1_2 = A0_2
  end
  if L1_2 then
    L2_2 = L1_2.x
    if L2_2 then
      L2_2 = L1_2.y
      if L2_2 then
        L2_2 = L1_2.z
        if L2_2 then
          goto lbl_22
        end
      end
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_22::
  L2_2 = A0_2.heading
  if not L2_2 then
    L2_2 = L1_2.w
    if not L2_2 then
      L2_2 = L1_2.heading
      if not L2_2 then
        L2_2 = 0.0
      end
    end
  end
  L3_2 = {}
  L4_2 = vector3
  L5_2 = tonumber
  L6_2 = L1_2.x
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = L1_2.x
  end
  L6_2 = tonumber
  L7_2 = L1_2.y
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = L1_2.y
  end
  L7_2 = tonumber
  L8_2 = L1_2.z
  L7_2 = L7_2(L8_2)
  if not L7_2 then
    L7_2 = L1_2.z
  end
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2.position = L4_2
  L4_2 = tonumber
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 0.0
  end
  L3_2.heading = L4_2
  return L3_2
end
function L24_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L6_2 = L17_1
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L7_2 = nil
    return L7_2
  end
  L7_2 = A5_2 or L7_2
  if not A5_2 then
    L7_2 = false
  end
  L8_2 = CreateObject
  L9_2 = L6_2
  L10_2 = A1_2.x
  L11_2 = A1_2.y
  L12_2 = A1_2.z
  L13_2 = L7_2
  L14_2 = L7_2
  L15_2 = false
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  if not L8_2 or 0 == L8_2 then
    L9_2 = nil
    return L9_2
  end
  L9_2 = A2_2 or L9_2
  if not A2_2 then
    L9_2 = 0.0
  end
  L10_2 = 360.0
  if L9_2 >= L10_2 then
    L9_2 = L9_2 - 360.0
  elseif L9_2 < 0.0 then
    L9_2 = L9_2 + 360.0
  end
  if A3_2 then
    L10_2 = PlaceObjectOnGroundProperly
    L11_2 = L8_2
    L10_2(L11_2)
    L10_2 = Wait
    L11_2 = 50
    L10_2(L11_2)
    L10_2 = SetEntityHeading
    L11_2 = L8_2
    L12_2 = L9_2
    L10_2(L11_2, L12_2)
    L10_2 = Wait
    L11_2 = 50
    L10_2(L11_2)
  end
  L10_2 = SetEntityHeading
  L11_2 = L8_2
  L12_2 = L9_2
  L10_2(L11_2, L12_2)
  L10_2 = FreezeEntityPosition
  L11_2 = L8_2
  L12_2 = true
  L10_2(L11_2, L12_2)
  if A4_2 then
    L10_2 = SetEntityCollision
    L11_2 = L8_2
    L12_2 = true
    L13_2 = true
    L10_2(L11_2, L12_2, L13_2)
  else
    L10_2 = SetEntityCollision
    L11_2 = L8_2
    L12_2 = false
    L13_2 = false
    L10_2(L11_2, L12_2, L13_2)
  end
  L10_2 = SetEntityInvincible
  L11_2 = L8_2
  L12_2 = true
  L10_2(L11_2, L12_2)
  L10_2 = SetEntityAsMissionEntity
  L11_2 = L8_2
  L12_2 = true
  L13_2 = true
  L10_2(L11_2, L12_2, L13_2)
  L10_2 = SetEntityProofs
  L11_2 = L8_2
  L12_2 = true
  L13_2 = true
  L14_2 = true
  L15_2 = true
  L16_2 = true
  L17_2 = true
  L18_2 = true
  L19_2 = true
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
  L10_2 = Wait
  L11_2 = 10
  L10_2(L11_2)
  L10_2 = SetModelAsNoLongerNeeded
  L11_2 = L6_2
  L10_2(L11_2)
  return L8_2
end
function L25_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = math
  L3_2 = L3_2.rad
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = 0.0
  end
  L3_2 = L3_2(L4_2)
  L4_2 = math
  L4_2 = L4_2.sin
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = math
  L5_2 = L5_2.cos
  L6_2 = L3_2
  L5_2 = L5_2(L6_2)
  L6_2 = A0_2.x
  L7_2 = A2_2.x
  L7_2 = L7_2 * L5_2
  L8_2 = A2_2.y
  L8_2 = L8_2 * L4_2
  L7_2 = L7_2 - L8_2
  L6_2 = L6_2 + L7_2
  L7_2 = A0_2.y
  L8_2 = A2_2.x
  L8_2 = L8_2 * L4_2
  L9_2 = A2_2.y
  L9_2 = L9_2 * L5_2
  L8_2 = L8_2 + L9_2
  L7_2 = L7_2 + L8_2
  L8_2 = A0_2.z
  L9_2 = A2_2.z
  L8_2 = L8_2 + L9_2
  L9_2 = vector3
  L10_2 = L6_2
  L11_2 = L7_2
  L12_2 = L8_2
  return L9_2(L10_2, L11_2, L12_2)
end
function L26_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = tostring
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = L5_1
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.pallet
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_2.pallet
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_19
    end
  end
  do return end
  ::lbl_19::
  L2_2 = L8_1
  L2_2 = L2_2[A0_2]
  if not L2_2 then
    return
  end
  L2_2 = L1_2.engine
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_2.engine
    L2_2 = L2_2(L3_2)
    if L2_2 then
      return
    end
  end
  L2_2 = GetEntityCoords
  L3_2 = L1_2.pallet
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityHeading
  L4_2 = L1_2.pallet
  L3_2 = L3_2(L4_2)
  L4_2 = L25_1
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = vector3
  L8_2 = 0.0
  L9_2 = -0.25
  L10_2 = 0.125
  L7_2, L8_2, L9_2, L10_2, L11_2 = L7_2(L8_2, L9_2, L10_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L5_2 = L24_1
  L6_2 = L2_1
  L7_2 = L4_2
  L8_2 = L3_2
  L9_2 = false
  L10_2 = true
  L11_2 = false
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L1_2.engine = L5_2
  L5_2 = Config
  L5_2 = L5_2.Debug
  if L5_2 then
    L5_2 = print
    L6_2 = "^2[DEBUG]^0: Respawned engine prop on pallet for shop: "
    L7_2 = A0_2
    L6_2 = L6_2 .. L7_2
    L5_2(L6_2)
  end
end
L14_1 = L26_1
function L26_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = tostring
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  A0_2 = L2_2
  L2_2 = L6_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = L6_1
    L2_2 = L2_2[A0_2]
    L3_2 = L2_2
    L2_2 = L2_2.remove
    L2_2(L3_2)
  end
  L2_2 = L8_1
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:getPalletEngine"
  L5_2 = false
  L6_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2[A0_2] = L3_2
  L2_2 = L6_1
  L3_2 = lib
  L3_2 = L3_2.zones
  L3_2 = L3_2.box
  L4_2 = {}
  L5_2 = vector3
  L6_2 = A1_2.x
  L7_2 = A1_2.y
  L8_2 = A1_2.z
  L8_2 = L8_2 + 0.5
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2.coords = L5_2
  L5_2 = vector3
  L6_2 = 6.0
  L7_2 = 6.0
  L8_2 = 2.0
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2.size = L5_2
  L4_2.rotation = 0
  L4_2.debug = false
  function L5_2()
    local L0_3, L1_3
    L0_3 = CreateThread
    function L1_3()
      local L0_4, L1_4, L2_4, L3_4, L4_4, L5_4, L6_4
      while true do
        L1_4 = A0_2
        L0_4 = L6_1
        L0_4 = L0_4[L1_4]
        if not L0_4 then
          break
        end
        L1_4 = A0_2
        L0_4 = L6_1
        L0_4 = L0_4[L1_4]
        L1_4 = L0_4
        L0_4 = L0_4.contains
        L2_4 = GetEntityCoords
        L3_4 = PlayerPedId
        L3_4, L4_4, L5_4, L6_4 = L3_4()
        L2_4, L3_4, L4_4, L5_4, L6_4 = L2_4(L3_4, L4_4, L5_4, L6_4)
        L0_4 = L0_4(L1_4, L2_4, L3_4, L4_4, L5_4, L6_4)
        if not L0_4 then
          break
        end
        L1_4 = A0_2
        L0_4 = L8_1
        L0_4 = L0_4[L1_4]
        if L0_4 then
          L1_4 = string
          L1_4 = L1_4.format
          L2_4 = [[
~b~Engine:~w~ %s
~y~Power:~w~ %s ~r~Torque:~w~ %s]]
          L3_4 = L0_4.name
          L4_4 = L0_4.power
          L5_4 = L0_4.torque
          L1_4 = L1_4(L2_4, L3_4, L4_4, L5_4)
          L2_4 = L16_1
          L3_4 = vector3
          L4_4 = A1_2.x
          L5_4 = A1_2.y
          L6_4 = A1_2.z
          L6_4 = L6_4 + 1.2
          L3_4 = L3_4(L4_4, L5_4, L6_4)
          L4_4 = L1_4
          L2_4(L3_4, L4_4)
        else
          L1_4 = L16_1
          L2_4 = vector3
          L3_4 = A1_2.x
          L4_4 = A1_2.y
          L5_4 = A1_2.z
          L5_4 = L5_4 + 1.2
          L2_4 = L2_4(L3_4, L4_4, L5_4)
          L3_4 = "~r~"
          L4_4 = _U
          L5_4 = "NO_ENGINE_ON_PALLET"
          L4_4 = L4_4(L5_4)
          L3_4 = L3_4 .. L4_4
          L1_4(L2_4, L3_4)
        end
        L1_4 = Wait
        L2_4 = 0
        L1_4(L2_4)
      end
    end
    L0_3(L1_3)
  end
  L4_2.onEnter = L5_2
  L3_2 = L3_2(L4_2)
  L2_2[A0_2] = L3_2
end
function L27_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L4_2 = tostring
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  A0_2 = L4_2
  L4_2 = L5_1
  L4_2 = L4_2[A0_2]
  if not L4_2 then
    L4_2 = L5_1
    L5_2 = {}
    L4_2[A0_2] = L5_2
  end
  L4_2 = L5_1
  L4_2 = L4_2[A0_2]
  if A1_2 then
    L5_2 = L4_2.laptop
    if not L5_2 then
      L5_2 = L24_1
      L6_2 = L0_1
      L7_2 = A1_2.position
      L8_2 = A1_2.heading
      L9_2 = true
      L10_2 = false
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      L4_2.laptop = L5_2
    end
  end
  if A2_2 then
    L5_2 = L4_2.pallet
    if not L5_2 then
      L5_2 = L24_1
      L6_2 = L1_1
      L7_2 = A2_2.position
      L8_2 = A2_2.heading
      L9_2 = true
      L10_2 = true
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2)
      L4_2.pallet = L5_2
      L5_2 = L4_2.pallet
      if L5_2 then
        L5_2 = SetEntityHeading
        L6_2 = L4_2.pallet
        L7_2 = A2_2.heading
        L5_2(L6_2, L7_2)
        L5_2 = GetEntityCoords
        L6_2 = L4_2.pallet
        L5_2 = L5_2(L6_2)
        L6_2 = A2_2.heading
        L7_2 = L26_1
        L8_2 = A0_2
        L9_2 = L5_2
        L7_2(L8_2, L9_2)
        L7_2 = lib
        L7_2 = L7_2.callback
        L7_2 = L7_2.await
        L8_2 = "qs-mechanic-creator:server:getPalletEngine"
        L9_2 = false
        L10_2 = A0_2
        L7_2 = L7_2(L8_2, L9_2, L10_2)
        if L7_2 then
          L8_2 = L4_2.engine
          if not L8_2 then
            L8_2 = L25_1
            L9_2 = L5_2
            L10_2 = L6_2
            L11_2 = vector3
            L12_2 = 0.0
            L13_2 = -0.25
            L14_2 = 0.125
            L11_2, L12_2, L13_2, L14_2, L15_2 = L11_2(L12_2, L13_2, L14_2)
            L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
            L9_2 = L24_1
            L10_2 = L2_1
            L11_2 = L8_2
            L12_2 = L6_2
            L13_2 = false
            L14_2 = true
            L15_2 = false
            L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
            L4_2.engine = L9_2
            L9_2 = L13_1
            L10_2 = A0_2
            L11_2 = L8_2
            L12_2 = L6_2
            L9_2(L10_2, L11_2, L12_2)
          end
        end
      end
    end
  end
  if A3_2 then
    L5_2 = L4_2.hoist
    if not L5_2 then
      L5_2 = L24_1
      L6_2 = L3_1
      L7_2 = A3_2.position
      L8_2 = A3_2.heading
      L9_2 = true
      L10_2 = true
      L11_2 = false
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
      L4_2.hoist = L5_2
    end
  end
end
function L28_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = CreateEngineSwapInteract
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = L10_1
    if not L2_2 then
      L2_2 = print
      L3_2 = "[EngineSwap] CreateEngineSwapInteract is not available for the selected interaction type."
      L2_2(L3_2)
      L2_2 = true
      L10_1 = L2_2
    end
    L2_2 = false
    return L2_2
  end
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "%s_engine_laptop"
  L4_2 = tostring
  L5_2 = A0_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = _U
  if L3_2 then
    L3_2 = _U
    L4_2 = "ENGINE_SWAP_ACCESS_LAPTOP"
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_32
    end
  end
  L3_2 = "Access Laptop"
  ::lbl_32::
  L4_2 = {}
  L5_2 = A1_2.position
  L5_2 = L5_2.x
  L4_2.x = L5_2
  L5_2 = A1_2.position
  L5_2 = L5_2.y
  L4_2.y = L5_2
  L5_2 = A1_2.position
  L5_2 = L5_2.z
  L4_2.z = L5_2
  L5_2 = A1_2.heading
  L4_2.w = L5_2
  L5_2 = CreateEngineSwapInteract
  L6_2 = L2_2
  L7_2 = L4_2
  L8_2 = L3_2
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:engineSwapLaptop"
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  if L5_2 then
    L6_2 = tostring
    L7_2 = A0_2
    L6_2 = L6_2(L7_2)
    L7_2 = L4_1
    L7_2[L6_2] = L2_2
    L6_2 = true
    return L6_2
  end
  L6_2 = false
  return L6_2
end
function L29_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = type
  L3_2 = CreateEngineHoistInteract
  L2_2 = L2_2(L3_2)
  if "function" ~= L2_2 then
    L2_2 = L10_1
    if not L2_2 then
      L2_2 = print
      L3_2 = "[EngineSwap] CreateEngineHoistInteract is not available for the selected interaction type."
      L2_2(L3_2)
      L2_2 = true
      L10_1 = L2_2
    end
    L2_2 = false
    return L2_2
  end
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "%s_engine_hoist"
  L4_2 = tostring
  L5_2 = A0_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2 = L4_2(L5_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2 = _U
  if L3_2 then
    L3_2 = _U
    L4_2 = "ENGINE_HOIST_USE"
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_32
    end
  end
  L3_2 = "Use Engine Hoist"
  ::lbl_32::
  L4_2 = {}
  L5_2 = A1_2.position
  L5_2 = L5_2.x
  L4_2.x = L5_2
  L5_2 = A1_2.position
  L5_2 = L5_2.y
  L4_2.y = L5_2
  L5_2 = A1_2.position
  L5_2 = L5_2.z
  L4_2.z = L5_2
  L5_2 = A1_2.heading
  L4_2.w = L5_2
  L5_2 = CreateEngineHoistInteract
  L6_2 = L2_2
  L7_2 = L4_2
  L8_2 = L3_2
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:useEngineHoist"
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  if L5_2 then
    L6_2 = tostring
    L7_2 = A0_2
    L6_2 = L6_2(L7_2)
    L7_2 = L7_1
    L7_2[L6_2] = L2_2
    L6_2 = true
    return L6_2
  end
  L6_2 = false
  return L6_2
end
function L30_1(A0_2)
  local L1_2
  if not A0_2 then
    L1_2 = nil
    return L1_2
  end
  L1_2 = A0_2.shopConfig
  if L1_2 then
    L1_2 = A0_2.shopConfig
    L1_2 = L1_2.engineSwap
    if L1_2 then
      L1_2 = A0_2.shopConfig
      L1_2 = L1_2.engineSwap
      return L1_2
    end
  end
  L1_2 = A0_2.engineSwap
  return L1_2
end
function L31_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = tostring
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  A0_2 = L2_2
  L2_2 = L11_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    return
  end
  L2_2 = L11_1
  L2_2[A0_2] = true
  L2_2 = L30_1
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = L2_2.enabled
    if L3_2 then
      goto lbl_26
    end
  end
  L3_2 = L20_1
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = L11_1
  L3_2[A0_2] = nil
  do return end
  ::lbl_26::
  L3_2 = L23_1
  L4_2 = L2_2.laptop
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L4_2 = L20_1
    L5_2 = A0_2
    L4_2(L5_2)
    L4_2 = L11_1
    L4_2[A0_2] = nil
    return
  end
  L4_2 = L23_1
  L5_2 = L2_2.stock
  L4_2 = L4_2(L5_2)
  L5_2 = L23_1
  L6_2 = L2_2.hoist
  L5_2 = L5_2(L6_2)
  L6_2 = L4_1
  L6_2 = L6_2[A0_2]
  if L6_2 then
    L7_2 = RemoveInteract
    L8_2 = L6_2
    L7_2(L8_2)
    L7_2 = L4_1
    L7_2[A0_2] = nil
  end
  L7_2 = L7_1
  L7_2 = L7_2[A0_2]
  if L7_2 then
    L8_2 = RemoveInteract
    L9_2 = L7_2
    L8_2(L9_2)
    L8_2 = L7_1
    L8_2[A0_2] = nil
  end
  L8_2 = Wait
  L9_2 = 100
  L8_2(L9_2)
  L8_2 = L27_1
  L9_2 = A0_2
  L10_2 = L3_2
  L11_2 = L4_2
  L12_2 = L5_2
  L8_2(L9_2, L10_2, L11_2, L12_2)
  L8_2 = false
  L9_2 = type
  L10_2 = hasShopAccess
  L9_2 = L9_2(L10_2)
  if "function" == L9_2 then
    L9_2 = hasShopAccess
    L10_2 = A1_2
    L9_2 = L9_2(L10_2)
    L8_2 = L9_2
  end
  if L8_2 then
    L9_2 = L28_1
    L10_2 = A0_2
    L11_2 = L3_2
    L9_2(L10_2, L11_2)
    if L5_2 then
      L9_2 = L29_1
      L10_2 = A0_2
      L11_2 = L5_2
      L9_2(L10_2, L11_2)
    end
  end
  L9_2 = L11_1
  L9_2[A0_2] = nil
end
function L32_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = Config
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.Tuneshops
    if L0_2 then
      goto lbl_10
    end
  end
  L0_2 = {}
  ::lbl_10::
  L1_2 = {}
  L2_2 = pairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = tostring
    L9_2 = L6_2
    L8_2 = L8_2(L9_2)
    L1_2[L8_2] = true
    L8_2 = L31_1
    L9_2 = L6_2
    L10_2 = L7_2
    L8_2(L9_2, L10_2)
  end
  L2_2 = pairs
  L3_2 = L4_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L7_2 = L1_2[L6_2]
    if not L7_2 then
      L7_2 = L20_1
      L8_2 = L6_2
      L7_2(L8_2)
    end
  end
  L2_2 = pairs
  L3_2 = L5_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L7_2 = L1_2[L6_2]
    if not L7_2 then
      L7_2 = L20_1
      L8_2 = L6_2
      L7_2(L8_2)
    end
  end
end
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:updateShops"
function L35_1()
  local L0_2, L1_2
  L0_2 = L32_1
  L0_2()
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:deleteMechanicCleanup"
function L35_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = L20_1
    L2_2 = A0_2
    L1_2(L2_2)
  end
end
L33_1(L34_1, L35_1)
L33_1 = AddEventHandler
L34_1 = "onResourceStop"
function L35_1(A0_2)
  local L1_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = L21_1
    L1_2()
  end
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncHoistAttach"
function L35_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = tostring
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A1_2 = L2_2
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L3_2 = DoesEntityExist
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_16
    end
  end
  do return end
  ::lbl_16::
  L3_2 = L5_1
  if L3_2 then
    L3_2 = L5_1
    L3_2 = L3_2[A1_2]
    if L3_2 then
      L3_2 = L5_1
      L3_2 = L3_2[A1_2]
      L3_2 = L3_2.hoist
      if L3_2 then
        L3_2 = L5_1
        L3_2 = L3_2[A1_2]
        L3_2 = L3_2.hoist
        L4_2 = DoesEntityExist
        L5_2 = L3_2
        L4_2 = L4_2(L5_2)
        if L4_2 and L3_2 ~= L2_2 then
          L4_2 = NetworkGetEntityIsNetworked
          L5_2 = L3_2
          L4_2 = L4_2(L5_2)
          if not L4_2 then
            L5_2 = string
            L5_2 = L5_2.format
            L6_2 = "hoist_pickup_%d"
            L7_2 = L3_2
            L5_2 = L5_2(L6_2, L7_2)
            L6_2 = RemoveInteract
            L7_2 = L5_2
            L6_2(L7_2)
            L6_2 = DeleteEntity
            L7_2 = L3_2
            L6_2(L7_2)
          end
        end
      end
    end
  end
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "hoist_pickup_%d"
  L5_2 = L2_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = RemoveInteract
  L5_2 = L3_2
  L4_2(L5_2)
  L4_2 = SetEntityAlpha
  L5_2 = L2_2
  L6_2 = 255
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = SetEntityVisible
  L5_2 = L2_2
  L6_2 = true
  L7_2 = false
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = FreezeEntityPosition
  L5_2 = L2_2
  L6_2 = false
  L4_2(L5_2, L6_2)
  L4_2 = SetEntityCollision
  L5_2 = L2_2
  L6_2 = true
  L7_2 = true
  L4_2(L5_2, L6_2, L7_2)
  L4_2 = L5_1
  if not L4_2 then
    L4_2 = {}
  end
  L5_1 = L4_2
  L4_2 = L5_1
  L5_2 = L5_1
  L5_2 = L5_2[A1_2]
  if not L5_2 then
    L5_2 = {}
  end
  L4_2[A1_2] = L5_2
  L4_2 = L5_1
  L4_2 = L4_2[A1_2]
  L4_2.hoist = L2_2
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncHoistPlace"
function L35_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2)
  local L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L7_2 = tostring
  L8_2 = A5_2
  L7_2 = L7_2(L8_2)
  A5_2 = L7_2
  L7_2 = NetworkGetEntityFromNetworkId
  L8_2 = A0_2
  L7_2 = L7_2(L8_2)
  L8_2 = nil
  if A6_2 then
    L9_2 = NetworkGetEntityFromNetworkId
    L10_2 = A6_2
    L9_2 = L9_2(L10_2)
    L8_2 = L9_2
  end
  if L7_2 then
    L9_2 = DoesEntityExist
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      goto lbl_23
    end
  end
  do return end
  ::lbl_23::
  L9_2 = SetEntityCoords
  L10_2 = L7_2
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = false
  L15_2 = false
  L16_2 = false
  L17_2 = false
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L9_2 = SetEntityHeading
  L10_2 = L7_2
  L11_2 = A4_2
  L9_2(L10_2, L11_2)
  L9_2 = FreezeEntityPosition
  L10_2 = L7_2
  L11_2 = true
  L9_2(L10_2, L11_2)
  L9_2 = SetEntityCollision
  L10_2 = L7_2
  L11_2 = true
  L12_2 = true
  L9_2(L10_2, L11_2, L12_2)
  if L8_2 then
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = IsEntityAttachedToEntity
      L10_2 = L8_2
      L11_2 = L7_2
      L9_2 = L9_2(L10_2, L11_2)
      if not L9_2 then
        L9_2 = AttachEntityToEntity
        L10_2 = L8_2
        L11_2 = L7_2
        L12_2 = 0
        L13_2 = 0.0
        L14_2 = -1.2
        L15_2 = 1.1
        L16_2 = 0.0
        L17_2 = 0.0
        L18_2 = 0.0
        L19_2 = false
        L20_2 = false
        L21_2 = false
        L22_2 = false
        L23_2 = 2
        L24_2 = true
        L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
      end
    end
  end
  L9_2 = L5_1
  if not L9_2 then
    L9_2 = {}
  end
  L5_1 = L9_2
  L9_2 = L5_1
  L10_2 = L5_1
  L10_2 = L10_2[A5_2]
  if not L10_2 then
    L10_2 = {}
  end
  L9_2[A5_2] = L10_2
  L9_2 = L5_1
  L9_2 = L9_2[A5_2]
  L9_2.hoist = L7_2
  L9_2 = string
  L9_2 = L9_2.format
  L10_2 = "hoist_pickup_%d"
  L11_2 = L7_2
  L9_2 = L9_2(L10_2, L11_2)
  L10_2 = RemoveInteract
  L11_2 = L9_2
  L10_2(L11_2)
  L10_2 = {}
  L10_2.x = A1_2
  L10_2.y = A2_2
  L11_2 = A3_2 + 1.0
  L10_2.z = L11_2
  L10_2.w = A4_2
  L11_2 = CreateEngineHoistInteract
  L12_2 = L9_2
  L13_2 = L10_2
  L14_2 = _U
  L15_2 = "ENGINE_HOIST_USE"
  L14_2 = L14_2(L15_2)
  function L15_2()
    local L0_3, L1_3, L2_3
    L0_3 = RemoveInteract
    L1_3 = L9_2
    L0_3(L1_3)
    L0_3 = tonumber
    L1_3 = A5_2
    L0_3 = L0_3(L1_3)
    L15_1.shopId = L0_3
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:useEngineHoist"
    L2_3 = A5_2
    L0_3(L1_3, L2_3)
  end
  L11_2(L12_2, L13_2, L14_2, L15_2)
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncEngineLift"
function L35_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2
  L6_2 = NetworkGetEntityFromNetworkId
  L7_2 = A0_2
  L6_2 = L6_2(L7_2)
  if L6_2 then
    L7_2 = DoesEntityExist
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L7_2 = CreateThread
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3
    L0_3 = A4_2
    L1_3 = A3_2
    L0_3 = L0_3 - L1_3
    L1_3 = A5_2
    L0_3 = L0_3 / L1_3
    L1_3 = 1
    L2_3 = A5_2
    L3_3 = 1
    for L4_3 = L1_3, L2_3, L3_3 do
      L5_3 = DoesEntityExist
      L6_3 = L6_2
      L5_3 = L5_3(L6_3)
      if L5_3 then
        L5_3 = GetEntityCoords
        L6_3 = L6_2
        L5_3 = L5_3(L6_3)
        L6_3 = SetEntityCoords
        L7_3 = L6_2
        L8_3 = A1_2
        L9_3 = A2_2
        L10_3 = L5_3.z
        L10_3 = L10_3 + L0_3
        L11_3 = false
        L12_3 = false
        L13_3 = false
        L14_3 = false
        L6_3(L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      end
      L5_3 = Wait
      L6_3 = 50
      L5_3(L6_3)
    end
  end
  L7_2(L8_2)
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncEngineLower"
function L35_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2
  L8_2 = NetworkGetEntityFromNetworkId
  L9_2 = A0_2
  L8_2 = L8_2(L9_2)
  if L8_2 then
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L9_2 = CreateThread
  function L10_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3
    L0_3 = A4_2
    L1_3 = A1_2
    L0_3 = L0_3 - L1_3
    L1_3 = A7_2
    L0_3 = L0_3 / L1_3
    L1_3 = A5_2
    L2_3 = A2_2
    L1_3 = L1_3 - L2_3
    L2_3 = A7_2
    L1_3 = L1_3 / L2_3
    L2_3 = A6_2
    L3_3 = A3_2
    L2_3 = L2_3 - L3_3
    L3_3 = A7_2
    L2_3 = L2_3 / L3_3
    L3_3 = 1
    L4_3 = A7_2
    L5_3 = 1
    for L6_3 = L3_3, L4_3, L5_3 do
      L7_3 = DoesEntityExist
      L8_3 = L8_2
      L7_3 = L7_3(L8_3)
      if L7_3 then
        L7_3 = GetEntityCoords
        L8_3 = L8_2
        L7_3 = L7_3(L8_3)
        L8_3 = SetEntityCoords
        L9_3 = L8_2
        L10_3 = L7_3.x
        L10_3 = L10_3 + L0_3
        L11_3 = L7_3.y
        L11_3 = L11_3 + L1_3
        L12_3 = L7_3.z
        L12_3 = L12_3 + L2_3
        L13_3 = false
        L14_3 = false
        L15_3 = false
        L16_3 = false
        L8_3(L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
      end
      L7_3 = Wait
      L8_3 = 50
      L7_3(L8_3)
    end
  end
  L9_2(L10_2)
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncEngineDelete"
function L35_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = NetworkGetEntityFromNetworkId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = DeleteEntity
      L3_2 = L1_2
      L2_2(L3_2)
    end
  end
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:syncEngineAttach"
function L35_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = NetworkGetEntityFromNetworkId
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L2_2 then
    L4_2 = DoesEntityExist
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_15
    end
  end
  do return end
  ::lbl_15::
  if L3_2 then
    L4_2 = DoesEntityExist
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_23
    end
  end
  do return end
  ::lbl_23::
  L4_2 = AttachEntityToEntity
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = 0
  L8_2 = 0.0
  L9_2 = -1.2
  L10_2 = 1.1
  L11_2 = 0.0
  L12_2 = 0.0
  L13_2 = 0.0
  L14_2 = false
  L15_2 = false
  L16_2 = false
  L17_2 = false
  L18_2 = 2
  L19_2 = true
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2)
end
L33_1(L34_1, L35_1)
L33_1 = CreateThread
function L34_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 1500
  L0_2(L1_2)
  L0_2 = L32_1
  L0_2()
end
L33_1(L34_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:engineStockUpdated"
function L35_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if not A0_2 then
    return
  end
  L1_2 = tostring
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = L5_1
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.engine
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_2.engine
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L18_1
      L3_2 = L1_2.engine
      L2_2(L3_2)
      L1_2.engine = nil
    end
  end
  L2_2 = L8_1
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:getPalletEngine"
  L5_2 = false
  L6_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2[A0_2] = L3_2
  L2_2 = L14_1
  L3_2 = A0_2
  L2_2(L3_2)
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:palletEngineUpdated"
function L35_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  if not A0_2 then
    return
  end
  L1_2 = tostring
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  A0_2 = L1_2
  L1_2 = L5_1
  L1_2 = L1_2[A0_2]
  if not L1_2 then
    return
  end
  L2_2 = L1_2.engine
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L1_2.engine
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L18_1
      L3_2 = L1_2.engine
      L2_2(L3_2)
      L1_2.engine = nil
    end
  end
  L2_2 = L8_1
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:getPalletEngine"
  L5_2 = false
  L6_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2[A0_2] = L3_2
  L2_2 = L14_1
  L3_2 = A0_2
  L2_2(L3_2)
end
L33_1(L34_1, L35_1)
L33_1 = RegisterNetEvent
L34_1 = "qs-mechanic-creator:client:useEngineHoist"
function L35_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L15_1.attached
  if L1_2 then
    L1_2 = DetachHoist
    L1_2()
    return
  end
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = tostring
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = L5_1
  L2_2 = L3_2[L2_2]
  if L2_2 then
    L3_2 = L2_2.hoist
    if L3_2 then
      L3_2 = DoesEntityExist
      L4_2 = L2_2.hoist
      L3_2 = L3_2(L4_2)
      if L3_2 then
        goto lbl_25
      end
    end
  end
  do return end
  ::lbl_25::
  L3_2 = L2_2.hoist
  L4_2 = AttachHoistToPed
  L5_2 = L1_2
  L6_2 = L3_2
  L7_2 = A0_2
  L4_2(L5_2, L6_2, L7_2)
end
L33_1(L34_1, L35_1)
function L33_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L3_2 = L15_1.attached
  if L3_2 then
    return
  end
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "%s_engine_hoist"
  L5_2 = tostring
  L6_2 = A2_2
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L4_2 = RemoveInteract
  L5_2 = L3_2
  L4_2(L5_2)
  L4_2 = string
  L4_2 = L4_2.format
  L5_2 = "hoist_pickup_%d"
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = RemoveInteract
  L6_2 = L4_2
  L5_2(L6_2)
  L5_2 = "anim@heists@box_carry@"
  L6_2 = RequestAnimDict
  L7_2 = L5_2
  L6_2(L7_2)
  while true do
    L6_2 = HasAnimDictLoaded
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      break
    end
    L6_2 = Wait
    L7_2 = 10
    L6_2(L7_2)
  end
  L6_2 = TaskPlayAnim
  L7_2 = A0_2
  L8_2 = L5_2
  L9_2 = "idle"
  L10_2 = 8.0
  L11_2 = 8.0
  L12_2 = -1
  L13_2 = 50
  L14_2 = 0
  L15_2 = false
  L16_2 = false
  L17_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L6_2 = GetEntityCoords
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L7_2 = GetEntityHeading
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = nil
  L9_2 = L15_1.engineProp
  if L9_2 then
    L9_2 = DoesEntityExist
    L10_2 = L15_1.engineProp
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L8_2 = L15_1.engineProp
    end
  end
  L9_2 = L5_1
  if L9_2 then
    L9_2 = tostring
    L10_2 = A2_2
    L9_2 = L9_2(L10_2)
    L10_2 = L5_1
    L9_2 = L10_2[L9_2]
  end
  L10_2 = nil
  L11_2 = DoesEntityExist
  L12_2 = A1_2
  L11_2 = L11_2(L12_2)
  if L11_2 then
    L11_2 = NetworkGetEntityIsNetworked
    L12_2 = A1_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L10_2 = A1_2
      L12_2 = FreezeEntityPosition
      L13_2 = L10_2
      L14_2 = false
      L12_2(L13_2, L14_2)
    else
      L12_2 = DeleteEntity
      L13_2 = A1_2
      L12_2(L13_2)
      L12_2 = Wait
      L13_2 = 100
      L12_2(L13_2)
      L12_2 = L24_1
      L13_2 = L3_1
      L14_2 = L6_2
      L15_2 = L7_2
      L16_2 = true
      L17_2 = true
      L18_2 = true
      L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
      L10_2 = L12_2
    end
  else
    L11_2 = L24_1
    L12_2 = L3_1
    L13_2 = L6_2
    L14_2 = L7_2
    L15_2 = true
    L16_2 = true
    L17_2 = true
    L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L10_2 = L11_2
  end
  if L10_2 then
    L11_2 = DoesEntityExist
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      goto lbl_124
    end
  end
  L15_1.attached = false
  do return end
  ::lbl_124::
  if L9_2 then
    L9_2.hoist = nil
  end
  L11_2 = AttachEntityToEntity
  L12_2 = L10_2
  L13_2 = A0_2
  L14_2 = GetPedBoneIndex
  L15_2 = A0_2
  L16_2 = 28422
  L14_2 = L14_2(L15_2, L16_2)
  L15_2 = 0.0
  L16_2 = -0.8
  L17_2 = -1.3
  L18_2 = 15.0
  L19_2 = 0.0
  L20_2 = 0.0
  L21_2 = true
  L22_2 = true
  L23_2 = false
  L24_2 = true
  L25_2 = 1
  L26_2 = true
  L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  if L8_2 then
    L11_2 = DoesEntityExist
    L12_2 = L8_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = AttachEntityToEntity
      L12_2 = L8_2
      L13_2 = L10_2
      L14_2 = 0
      L15_2 = 0.0
      L16_2 = -1.2
      L17_2 = 1.1
      L18_2 = 0.0
      L19_2 = 0.0
      L20_2 = 0.0
      L21_2 = false
      L22_2 = false
      L23_2 = false
      L24_2 = false
      L25_2 = 2
      L26_2 = true
      L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
    end
  end
  L15_1.shopId = A2_2
  L15_1.prop = L10_2
  L15_1.attached = true
  L11_2 = NetworkGetNetworkIdFromEntity
  L12_2 = L10_2
  L11_2 = L11_2(L12_2)
  L12_2 = TriggerServerEvent
  L13_2 = "qs-mechanic-creator:server:syncHoistAttach"
  L14_2 = L11_2
  L15_2 = A2_2
  L12_2(L13_2, L14_2, L15_2)
  L12_2 = CreateThread
  function L13_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3
    while true do
      L0_3 = L15_1.attached
      if not L0_3 then
        break
      end
      L0_3 = PlayerPedId
      L0_3 = L0_3()
      L1_3 = GetEntityCoords
      L2_3 = L0_3
      L1_3 = L1_3(L2_3)
      L2_3 = GetEntityCoords
      L3_3 = L15_1.prop
      L2_3 = L2_3(L3_3)
      L3_3 = IsEntityPlayingAnim
      L4_3 = L0_3
      L5_3 = L5_2
      L6_3 = "idle"
      L7_3 = 3
      L3_3 = L3_3(L4_3, L5_3, L6_3, L7_3)
      if not L3_3 then
        L3_3 = TaskPlayAnim
        L4_3 = L0_3
        L5_3 = L5_2
        L6_3 = "idle"
        L7_3 = 8.0
        L8_3 = 8.0
        L9_3 = -1
        L10_3 = 50
        L11_3 = 0
        L12_3 = false
        L13_3 = false
        L14_3 = false
        L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      end
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 24
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 25
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 44
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 37
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = L16_1
      L4_3 = vector3
      L5_3 = L2_3.x
      L6_3 = L2_3.y
      L7_3 = L2_3.z
      L7_3 = L7_3 + 0.5
      L4_3 = L4_3(L5_3, L6_3, L7_3)
      L5_3 = _U
      L6_3 = "ENGINE_HOIST_RELEASE"
      L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3 = L5_3(L6_3)
      L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      L3_3 = GetNearestPalletWithEngine
      L4_3 = L1_3
      L3_3, L4_3, L5_3 = L3_3(L4_3)
      if L3_3 then
        L6_3 = L15_1.engineAttached
        if not L6_3 then
          L6_3 = L16_1
          L7_3 = vector3
          L8_3 = L2_3.x
          L9_3 = L2_3.y
          L10_3 = L2_3.z
          L10_3 = L10_3 + 0.2
          L7_3 = L7_3(L8_3, L9_3, L10_3)
          L8_3 = _U
          L9_3 = "ENGINE_HOIST_ATTACH_TO_PALLET"
          L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3 = L8_3(L9_3)
          L6_3(L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
          L6_3 = IsControlJustReleased
          L7_3 = 0
          L8_3 = 38
          L6_3 = L6_3(L7_3, L8_3)
          if L6_3 then
            L6_3 = PlaceHoistNearPallet
            L7_3 = L4_3
            L8_3 = L5_3
            L6_3(L7_3, L8_3)
          end
      end
      else
        L6_3 = GetNearestVehicle
        L7_3 = L1_3
        L6_3, L7_3 = L6_3(L7_3)
        if L6_3 then
          L8_3 = GetVehicleNumberPlateText
          L9_3 = L7_3
          L8_3 = L8_3(L9_3)
          L9_3 = L9_1
          L9_3 = L9_3[L8_3]
          if nil == L9_3 then
            L10_3 = lib
            L10_3 = L10_3.callback
            L10_3 = L10_3.await
            L11_3 = "qs-mechanic-creator:server:vehicleHasEngine"
            L12_3 = false
            L13_3 = L8_3
            L10_3 = L10_3(L11_3, L12_3, L13_3)
            L9_3 = L10_3
            L10_3 = L9_1
            L10_3[L8_3] = L9_3
          end
          L10_3 = L15_1.engineAttached
          if L10_3 then
            if not L9_3 then
              L10_3 = L16_1
              L11_3 = vector3
              L12_3 = L2_3.x
              L13_3 = L2_3.y
              L14_3 = L2_3.z
              L14_3 = L14_3 + 0.2
              L11_3 = L11_3(L12_3, L13_3, L14_3)
              L12_3 = _U
              L13_3 = "ENGINE_HOIST_PLACE_NEAR_VEHICLE"
              L12_3, L13_3, L14_3 = L12_3(L13_3)
              L10_3(L11_3, L12_3, L13_3, L14_3)
              L10_3 = IsControlJustReleased
              L11_3 = 0
              L12_3 = 38
              L10_3 = L10_3(L11_3, L12_3)
              if L10_3 then
                L10_3 = PlaceHoistNearVehicleForInstall
                L11_3 = L7_3
                L10_3(L11_3)
              end
            end
          elseif L9_3 then
            L10_3 = L16_1
            L11_3 = vector3
            L12_3 = L2_3.x
            L13_3 = L2_3.y
            L14_3 = L2_3.z
            L14_3 = L14_3 + 0.2
            L11_3 = L11_3(L12_3, L13_3, L14_3)
            L12_3 = _U
            L13_3 = "ENGINE_HOIST_PLACE_NEAR_VEHICLE"
            L12_3, L13_3, L14_3 = L12_3(L13_3)
            L10_3(L11_3, L12_3, L13_3, L14_3)
            L10_3 = IsControlJustReleased
            L11_3 = 0
            L12_3 = 38
            L10_3 = L10_3(L11_3, L12_3)
            if L10_3 then
              L10_3 = PlaceHoistNearVehicle
              L11_3 = L7_3
              L10_3(L11_3)
            end
          end
        end
      end
      L6_3 = IsControlJustReleased
      L7_3 = 0
      L8_3 = 194
      L6_3 = L6_3(L7_3, L8_3)
      if L6_3 then
        L6_3 = DetachHoist
        L6_3()
        break
      end
      L6_3 = Wait
      L7_3 = 0
      L6_3(L7_3)
    end
  end
  L12_2(L13_2)
end
AttachHoistToPed = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = nil
  L2_2 = 5.0
  L3_2 = ipairs
  L4_2 = GetGamePool
  L5_2 = "CVehicle"
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2(L5_2)
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = GetEntityCoords
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    L10_2 = A0_2 - L9_2
    L10_2 = #L10_2
    if L2_2 > L10_2 then
      L1_2 = L8_2
      L2_2 = L10_2
    end
  end
  L3_2 = nil ~= L1_2
  L4_2 = L1_2
  return L3_2, L4_2
end
GetNearestVehicle = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = pairs
  L2_2 = L5_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L6_2.pallet
    if L7_2 then
      L7_2 = DoesEntityExist
      L8_2 = L6_2.pallet
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = GetEntityCoords
        L8_2 = L6_2.pallet
        L7_2 = L7_2(L8_2)
        L8_2 = A0_2 - L7_2
        L8_2 = #L8_2
        if L8_2 < 3.0 then
          L8_2 = L8_1
          L8_2 = L8_2[L5_2]
          if L8_2 then
            L9_2 = true
            L10_2 = L6_2.pallet
            L11_2 = L5_2
            return L9_2, L10_2, L11_2
          end
        end
      end
    end
  end
  L1_2 = false
  L2_2 = nil
  L3_2 = nil
  return L1_2, L2_2, L3_2
end
GetNearestPalletWithEngine = L33_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2
  L2_2 = DoesEntityExist
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = L15_1.attached
    if L2_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = ClearPedTasks
  L4_2 = L2_2
  L3_2(L4_2)
  L3_2 = L15_1.prop
  if L3_2 then
    L3_2 = DoesEntityExist
    L4_2 = L15_1.prop
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = DetachEntity
      L4_2 = L15_1.prop
      L5_2 = true
      L6_2 = true
      L3_2(L4_2, L5_2, L6_2)
      L3_2 = GetEntityCoords
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      L4_2 = GetEntityHeading
      L5_2 = A0_2
      L4_2 = L4_2(L5_2)
      L5_2 = GetEntityForwardVector
      L6_2 = A0_2
      L5_2 = L5_2(L6_2)
      L6_2 = vector3
      L7_2 = L5_2.y
      L7_2 = -L7_2
      L8_2 = L5_2.x
      L9_2 = 0.0
      L6_2 = L6_2(L7_2, L8_2, L9_2)
      L7_2 = vector3
      L8_2 = L3_2.x
      L9_2 = L5_2.x
      L9_2 = L9_2 * 0.75
      L8_2 = L8_2 + L9_2
      L9_2 = L6_2.x
      L9_2 = L9_2 * 0.0
      L8_2 = L8_2 + L9_2
      L9_2 = L3_2.y
      L10_2 = L5_2.y
      L10_2 = L10_2 * 0.75
      L9_2 = L9_2 + L10_2
      L10_2 = L6_2.y
      L10_2 = L10_2 * 0.0
      L9_2 = L9_2 + L10_2
      L10_2 = L3_2.z
      L7_2 = L7_2(L8_2, L9_2, L10_2)
      L8_2 = SetEntityCoords
      L9_2 = L15_1.prop
      L10_2 = L7_2.x
      L11_2 = L7_2.y
      L12_2 = L7_2.z
      L13_2 = false
      L14_2 = false
      L15_2 = false
      L16_2 = false
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
      L8_2 = SetEntityHeading
      L9_2 = L15_1.prop
      L10_2 = L4_2
      L8_2(L9_2, L10_2)
      L8_2 = SetEntityCollision
      L9_2 = L15_1.prop
      L10_2 = false
      L11_2 = false
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = PlaceObjectOnGroundProperly
      L9_2 = L15_1.prop
      L8_2(L9_2)
      L8_2 = Wait
      L9_2 = 100
      L8_2(L9_2)
      L8_2 = SetEntityCollision
      L9_2 = L15_1.prop
      L10_2 = true
      L11_2 = true
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = SetEntityHeading
      L9_2 = L15_1.prop
      L10_2 = L4_2
      L8_2(L9_2, L10_2)
      L8_2 = SetEntityRotation
      L9_2 = L15_1.prop
      L10_2 = 0.0
      L11_2 = 0.0
      L12_2 = L4_2
      L13_2 = 2
      L14_2 = true
      L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
      L8_2 = Wait
      L9_2 = 100
      L8_2(L9_2)
      L8_2 = GetEntityCoords
      L9_2 = L15_1.prop
      L8_2 = L8_2(L9_2)
      L9_2 = GetEntityHeading
      L10_2 = L15_1.prop
      L9_2 = L9_2(L10_2)
      L10_2 = FreezeEntityPosition
      L11_2 = L15_1.prop
      L12_2 = true
      L10_2(L11_2, L12_2)
      L10_2 = L15_1.prop
      L11_2 = L15_1.shopId
      L15_1.shopId = L11_2
      L15_1.attached = false
      L15_1.attachedToPallet = true
      L15_1.palletProp = A0_2
      L15_1.prop = L10_2
      L12_2 = NetworkGetNetworkIdFromEntity
      L13_2 = L10_2
      L12_2 = L12_2(L13_2)
      L13_2 = nil
      L14_2 = L15_1.engineAttached
      if L14_2 then
        L14_2 = L15_1.engineProp
        if L14_2 then
          L14_2 = DoesEntityExist
          L15_2 = L15_1.engineProp
          L14_2 = L14_2(L15_2)
          if L14_2 then
            L14_2 = NetworkGetNetworkIdFromEntity
            L15_2 = L15_1.engineProp
            L14_2 = L14_2(L15_2)
            L13_2 = L14_2
            L14_2 = TriggerServerEvent
            L15_2 = "qs-mechanic-creator:server:syncEngineAttach"
            L16_2 = L13_2
            L17_2 = L12_2
            L14_2(L15_2, L16_2, L17_2)
          end
        end
      end
      L14_2 = TriggerServerEvent
      L15_2 = "qs-mechanic-creator:server:syncHoistPlace"
      L16_2 = L12_2
      L17_2 = L8_2.x
      L18_2 = L8_2.y
      L19_2 = L8_2.z
      L20_2 = L9_2
      L21_2 = L15_1.shopId
      L22_2 = L13_2
      L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
      L14_2 = CreatePickupEngineFromPalletInteraction
      L15_2 = A1_2
      L14_2(L15_2)
    end
  end
end
PlaceHoistNearPallet = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = L15_1.prop
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L15_1.prop
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = type
  L2_2 = CreateEngineHoistInteract
  L1_2 = L1_2(L2_2)
  if "function" ~= L1_2 then
    return
  end
  L1_2 = GetEntityCoords
  L2_2 = L15_1.prop
  L1_2 = L1_2(L2_2)
  L2_2 = GetEntityHeading
  L3_2 = L15_1.prop
  L2_2 = L2_2(L3_2)
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "hoist_pickup_engine_%d"
  L5_2 = L15_1.prop
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = {}
  L5_2 = L1_2.x
  L4_2.x = L5_2
  L5_2 = L1_2.y
  L4_2.y = L5_2
  L5_2 = L1_2.z
  L5_2 = L5_2 + 1.0
  L4_2.z = L5_2
  L4_2.w = L2_2
  L5_2 = CreateEngineHoistInteract
  L6_2 = L3_2
  L7_2 = L4_2
  L8_2 = _U
  L9_2 = "ENGINE_PICKUP"
  L8_2 = L8_2(L9_2)
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = PickupEngineFromPallet
    L1_3 = L3_2
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L5_2(L6_2, L7_2, L8_2, L9_2)
end
CreatePickupEngineFromPalletInteraction = L33_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2
  L2_2 = L15_1.prop
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L15_1.prop
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L2_2 = L15_1.engineAttached
  if L2_2 then
    return
  end
  L2_2 = RemoveInteract
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = lib
  L2_2 = L2_2.callback
  L2_2 = L2_2.await
  L3_2 = "qs-mechanic-creator:server:getPalletEngine"
  L4_2 = false
  L5_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  if not L2_2 then
    return
  end
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:pickupEngineFromPallet"
  L5_2 = false
  L6_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if not L3_2 then
    return
  end
  L4_2 = tostring
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = L5_1
  L4_2 = L5_2[L4_2]
  if L4_2 then
    L5_2 = L4_2.engine
    if L5_2 then
      L5_2 = DoesEntityExist
      L6_2 = L4_2.engine
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L5_2 = L18_1
        L6_2 = L4_2.engine
        L5_2(L6_2)
        L4_2.engine = nil
      end
    end
  end
  L5_2 = "I4_2_0L_TURBO"
  L6_2 = L2_2.name
  if L6_2 then
    L6_2 = EngineNameMapping
    L7_2 = L2_2.name
    L6_2 = L6_2[L7_2]
    if L6_2 then
      L6_2 = EngineNameMapping
      L7_2 = L2_2.name
      L5_2 = L6_2[L7_2]
    end
  end
  L15_1.engineType = L5_2
  L15_1.originalEngineData = L2_2
  L6_2 = L15_1.palletProp
  if not L6_2 then
    L6_2 = L5_1
    L6_2 = L6_2[A1_2]
    if L6_2 then
      L6_2 = L5_1
      L6_2 = L6_2[A1_2]
      L6_2 = L6_2.pallet
    end
  end
  if L6_2 then
    L7_2 = DoesEntityExist
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      goto lbl_88
    end
  end
  do return end
  ::lbl_88::
  L7_2 = GetEntityCoords
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  L8_2 = GetEntityHeading
  L9_2 = L6_2
  L8_2 = L8_2(L9_2)
  L9_2 = L25_1
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = vector3
  L13_2 = 0.0
  L14_2 = -0.25
  L15_2 = 0.125
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2 = L12_2(L13_2, L14_2, L15_2)
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L10_2 = L19_1
  L11_2 = L9_2
  L12_2 = L8_2
  L10_2, L11_2 = L10_2(L11_2, L12_2)
  if not L10_2 then
    return
  end
  L15_1.engineProp = L10_2
  L12_2 = PlayerPedId
  L12_2 = L12_2()
  L13_2 = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L14_2 = RequestAnimDict
  L15_2 = L13_2
  L14_2(L15_2)
  while true do
    L14_2 = HasAnimDictLoaded
    L15_2 = L13_2
    L14_2 = L14_2(L15_2)
    if L14_2 then
      break
    end
    L14_2 = Wait
    L15_2 = 10
    L14_2(L15_2)
  end
  L14_2 = TaskPlayAnim
  L15_2 = L12_2
  L16_2 = L13_2
  L17_2 = "machinic_loop_mechandplayer"
  L18_2 = 8.0
  L19_2 = -8.0
  L20_2 = 5000
  L21_2 = 1
  L22_2 = 0
  L23_2 = false
  L24_2 = false
  L25_2 = false
  L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  L14_2 = GetEntityCoords
  L15_2 = L15_1.prop
  L14_2 = L14_2(L15_2)
  L15_2 = Wait
  L16_2 = 1000
  L15_2(L16_2)
  L15_2 = L14_2.z
  L15_2 = L15_2 + 1.1
  L16_2 = GetEntityCoords
  L17_2 = L10_2
  L16_2 = L16_2(L17_2)
  L17_2 = 50
  L18_2 = L16_2.z
  L18_2 = L15_2 - L18_2
  L18_2 = L18_2 / L17_2
  L19_2 = TriggerServerEvent
  L20_2 = "qs-mechanic-creator:server:syncEngineLift"
  L21_2 = L11_2
  L22_2 = L16_2.x
  L23_2 = L16_2.y
  L24_2 = L16_2.z
  L25_2 = L15_2
  L26_2 = L17_2
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L19_2 = 1
  L20_2 = L17_2
  L21_2 = 1
  for L22_2 = L19_2, L20_2, L21_2 do
    L23_2 = DoesEntityExist
    L24_2 = L10_2
    L23_2 = L23_2(L24_2)
    if not L23_2 then
      break
    end
    L23_2 = GetEntityCoords
    L24_2 = L10_2
    L23_2 = L23_2(L24_2)
    L24_2 = SetEntityCoords
    L25_2 = L10_2
    L26_2 = L16_2.x
    L27_2 = L16_2.y
    L28_2 = L23_2.z
    L28_2 = L28_2 + L18_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = Wait
    L25_2 = 50
    L24_2(L25_2)
  end
  L19_2 = Wait
  L20_2 = 100
  L19_2(L20_2)
  L19_2 = AttachEntityToEntity
  L20_2 = L10_2
  L21_2 = L15_1.prop
  L22_2 = 0
  L23_2 = 0.0
  L24_2 = -1.2
  L25_2 = 1.1
  L26_2 = 0.0
  L27_2 = 0.0
  L28_2 = 0.0
  L29_2 = false
  L30_2 = false
  L31_2 = false
  L32_2 = false
  L33_2 = 2
  L34_2 = true
  L19_2(L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2)
  L15_1.engineAttached = true
  L15_1.attachedToPallet = false
  L15_1.engineFromPallet = true
  L15_1.engineSourceShopId = A1_2
  L19_2 = NetworkGetNetworkIdFromEntity
  L20_2 = L15_1.prop
  L19_2 = L19_2(L20_2)
  L20_2 = TriggerServerEvent
  L21_2 = "qs-mechanic-creator:server:syncEngineAttach"
  L22_2 = L11_2
  L23_2 = L19_2
  L20_2(L21_2, L22_2, L23_2)
  L20_2 = TriggerEvent
  L21_2 = "qs-mechanic-creator:client:palletEngineUpdated"
  L22_2 = A1_2
  L20_2(L21_2, L22_2)
  L20_2 = CreateDetachHoistInteraction
  L20_2()
end
PickupEngineFromPallet = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = L15_1.attached
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = ClearPedTasks
  L3_2 = L1_2
  L2_2(L3_2)
  L2_2 = L15_1.prop
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L15_1.prop
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = DetachEntity
      L3_2 = L15_1.prop
      L4_2 = true
      L5_2 = true
      L2_2(L3_2, L4_2, L5_2)
      L2_2 = nil
      L3_2 = L15_1.engineAttached
      if L3_2 then
        L3_2 = L15_1.engineProp
        if L3_2 then
          L3_2 = DoesEntityExist
          L4_2 = L15_1.engineProp
          L3_2 = L3_2(L4_2)
          if L3_2 then
            L2_2 = L15_1.engineProp
            L3_2 = DetachEntity
            L4_2 = L2_2
            L5_2 = false
            L6_2 = false
            L3_2(L4_2, L5_2, L6_2)
          end
        end
      end
      L3_2 = FreezeEntityPosition
      L4_2 = A0_2
      L5_2 = true
      L3_2(L4_2, L5_2)
      L3_2 = GetEntityCoords
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      L4_2 = GetEntityHeading
      L5_2 = A0_2
      L4_2 = L4_2(L5_2)
      L5_2 = GetEntityForwardVector
      L6_2 = A0_2
      L5_2 = L5_2(L6_2)
      L6_2 = vector3
      L7_2 = L5_2.y
      L7_2 = -L7_2
      L8_2 = L5_2.x
      L9_2 = 0.0
      L6_2 = L6_2(L7_2, L8_2, L9_2)
      L7_2 = GetEntityModel
      L8_2 = A0_2
      L7_2 = L7_2(L8_2)
      L8_2 = Config
      L8_2 = L8_2.BackEngines
      L8_2 = L8_2[L7_2]
      L8_2 = true == L8_2
      if L8_2 then
        L9_2 = -2.2
        if L9_2 then
          goto lbl_81
        end
      end
      L9_2 = 2.45
      ::lbl_81::
      if L8_2 then
        L10_2 = 0.1
        if L10_2 then
          goto lbl_87
        end
      end
      L10_2 = -0.1
      ::lbl_87::
      if L8_2 then
        L11_2 = -0.6
        if L11_2 then
          goto lbl_93
        end
      end
      L11_2 = -0.4
      ::lbl_93::
      if L8_2 then
        L12_2 = 180.0
        if L12_2 then
          goto lbl_99
        end
      end
      L12_2 = 0.0
      ::lbl_99::
      L13_2 = vector3
      L14_2 = L3_2.x
      L15_2 = L5_2.x
      L15_2 = L15_2 * L9_2
      L14_2 = L14_2 + L15_2
      L15_2 = L6_2.x
      L15_2 = L15_2 * L10_2
      L14_2 = L14_2 + L15_2
      L15_2 = L3_2.y
      L16_2 = L5_2.y
      L16_2 = L16_2 * L9_2
      L15_2 = L15_2 + L16_2
      L16_2 = L6_2.y
      L16_2 = L16_2 * L10_2
      L15_2 = L15_2 + L16_2
      L16_2 = L3_2.z
      L16_2 = L16_2 + L11_2
      L13_2 = L13_2(L14_2, L15_2, L16_2)
      L14_2 = SetEntityCoords
      L15_2 = L15_1.prop
      L16_2 = L13_2.x
      L17_2 = L13_2.y
      L18_2 = L13_2.z
      L19_2 = false
      L20_2 = false
      L21_2 = false
      L22_2 = false
      L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2)
      L14_2 = SetEntityCollision
      L15_2 = L15_1.prop
      L16_2 = false
      L17_2 = false
      L14_2(L15_2, L16_2, L17_2)
      L14_2 = SetEntityHeading
      L15_2 = L15_1.prop
      L16_2 = L4_2 + L12_2
      L14_2(L15_2, L16_2)
      L14_2 = Wait
      L15_2 = 100
      L14_2(L15_2)
      L14_2 = GetEntityCoords
      L15_2 = L15_1.prop
      L14_2 = L14_2(L15_2)
      L15_2 = GetEntityHeading
      L16_2 = L15_1.prop
      L15_2 = L15_2(L16_2)
      L16_2 = FreezeEntityPosition
      L17_2 = L15_1.prop
      L18_2 = true
      L16_2(L17_2, L18_2)
      L16_2 = SetEntityCollision
      L17_2 = L15_1.prop
      L18_2 = true
      L19_2 = true
      L16_2(L17_2, L18_2, L19_2)
      if L2_2 then
        L16_2 = DoesEntityExist
        L17_2 = L2_2
        L16_2 = L16_2(L17_2)
        if L16_2 then
          L16_2 = Wait
          L17_2 = 50
          L16_2(L17_2)
          L16_2 = AttachEntityToEntity
          L17_2 = L2_2
          L18_2 = L15_1.prop
          L19_2 = 0
          L20_2 = 0.0
          L21_2 = -1.2
          L22_2 = 1.1
          L23_2 = 0.0
          L24_2 = 0.0
          L25_2 = 0.0
          L26_2 = false
          L27_2 = false
          L28_2 = false
          L29_2 = false
          L30_2 = 2
          L31_2 = true
          L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2)
        end
      end
      L16_2 = L15_1.prop
      L17_2 = L15_1.shopId
      L15_1.shopId = L17_2
      L15_1.attached = false
      L15_1.vehicle = A0_2
      L15_1.bonnetRemoved = false
      L15_1.prop = L16_2
      L18_2 = NetworkGetNetworkIdFromEntity
      L19_2 = L16_2
      L18_2 = L18_2(L19_2)
      L19_2 = nil
      L20_2 = L15_1.engineAttached
      if L20_2 then
        L20_2 = L15_1.engineProp
        if L20_2 then
          L20_2 = DoesEntityExist
          L21_2 = L15_1.engineProp
          L20_2 = L20_2(L21_2)
          if L20_2 then
            L20_2 = NetworkGetNetworkIdFromEntity
            L21_2 = L15_1.engineProp
            L20_2 = L20_2(L21_2)
            L19_2 = L20_2
            L20_2 = TriggerServerEvent
            L21_2 = "qs-mechanic-creator:server:syncEngineAttach"
            L22_2 = L19_2
            L23_2 = L18_2
            L20_2(L21_2, L22_2, L23_2)
          end
        end
      end
      L20_2 = TriggerServerEvent
      L21_2 = "qs-mechanic-creator:server:syncHoistPlace"
      L22_2 = L18_2
      L23_2 = L14_2.x
      L24_2 = L14_2.y
      L25_2 = L14_2.z
      L26_2 = L15_2
      L27_2 = L15_1.shopId
      L28_2 = L19_2
      L20_2(L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
      L20_2 = GetVehicleNumberPlateText
      L21_2 = A0_2
      L20_2 = L20_2(L21_2)
      L21_2 = L9_1
      L21_2 = L21_2[L20_2]
      if nil == L21_2 then
        L22_2 = lib
        L22_2 = L22_2.callback
        L22_2 = L22_2.await
        L23_2 = "qs-mechanic-creator:server:vehicleHasEngine"
        L24_2 = false
        L25_2 = L20_2
        L22_2 = L22_2(L23_2, L24_2, L25_2)
        L21_2 = L22_2
        L22_2 = L9_1
        L22_2[L20_2] = L21_2
      end
      if not L21_2 then
        L22_2 = L15_1.engineAttached
        if not L22_2 then
          return
        end
      end
      if L8_2 then
        L15_1.bonnetRemoved = true
        L22_2 = L15_1.engineAttached
        if L22_2 then
          L22_2 = CreateInstallEngineInteraction
          L23_2 = A0_2
          L22_2(L23_2)
        else
          L22_2 = CreateHoistCrankInteraction
          L22_2()
        end
      else
        L22_2 = GetVehicleDoorAngleRatio
        L23_2 = A0_2
        L24_2 = 4
        L22_2 = L22_2(L23_2, L24_2)
        L23_2 = 0.5
        L24_2 = L22_2 > L23_2
        if not L24_2 then
          L22_2 = IsVehicleDoorDamaged
          L23_2 = A0_2
          L24_2 = 4
          L22_2 = L22_2(L23_2, L24_2)
          L24_2 = L22_2
        end
        if L24_2 then
          L15_1.bonnetRemoved = true
          L22_2 = L15_1.engineAttached
          if L22_2 then
            L22_2 = CreateInstallEngineInteraction
            L23_2 = A0_2
            L22_2(L23_2)
          else
            L22_2 = CreateHoistCrankInteraction
            L22_2()
          end
        else
          L22_2 = L15_1.engineAttached
          if L22_2 then
            L22_2 = CreateVehicleBonnetInteractionForInstall
            L23_2 = A0_2
            L22_2(L23_2)
          else
            L22_2 = CreateVehicleBonnetInteraction
            L23_2 = A0_2
            L22_2(L23_2)
          end
        end
      end
    end
  end
end
PlaceHoistNearVehicle = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = L15_1.prop
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L15_1.prop
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = type
  L2_2 = CreateEngineHoistInteract
  L1_2 = L1_2(L2_2)
  if "function" ~= L1_2 then
    return
  end
  L1_2 = GetEntityCoords
  L2_2 = L15_1.prop
  L1_2 = L1_2(L2_2)
  L2_2 = GetEntityHeading
  L3_2 = L15_1.prop
  L2_2 = L2_2(L3_2)
  L3_2 = string
  L3_2 = L3_2.format
  L4_2 = "hoist_install_%d"
  L5_2 = L15_1.prop
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = {}
  L5_2 = L1_2.x
  L4_2.x = L5_2
  L5_2 = L1_2.y
  L4_2.y = L5_2
  L5_2 = L1_2.z
  L5_2 = L5_2 + 1.0
  L4_2.z = L5_2
  L4_2.w = L2_2
  L5_2 = CreateEngineHoistInteract
  L6_2 = L3_2
  L7_2 = L4_2
  L8_2 = "Install Engine"
  function L9_2()
    local L0_3, L1_3, L2_3
    L0_3 = InstallEngineIntoVehicle
    L1_3 = L3_2
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L5_2(L6_2, L7_2, L8_2, L9_2)
end
CreateInstallEngineInteraction = L33_1
function L33_1(A0_2)
  local L1_2, L2_2
  L1_2 = PlaceHoistNearVehicle
  L2_2 = A0_2
  L1_2(L2_2)
end
PlaceHoistNearVehicleForInstall = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = type
  L2_2 = CreateEngineHoistInteract
  L1_2 = L1_2(L2_2)
  if "function" ~= L1_2 then
    return
  end
  L1_2 = GetEntityCoords
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = GetEntityHeading
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityForwardVector
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = vector3
  L5_2 = L1_2.x
  L6_2 = L3_2.x
  L6_2 = L6_2 * 1.5
  L5_2 = L5_2 + L6_2
  L6_2 = L1_2.y
  L7_2 = L3_2.y
  L7_2 = L7_2 * 1.5
  L6_2 = L6_2 + L7_2
  L7_2 = L1_2.z
  L7_2 = L7_2 + 0.5
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = string
  L5_2 = L5_2.format
  L6_2 = "vehicle_bonnet_install_%d"
  L7_2 = A0_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = {}
  L7_2 = L4_2.x
  L6_2.x = L7_2
  L7_2 = L4_2.y
  L6_2.y = L7_2
  L7_2 = L4_2.z
  L6_2.z = L7_2
  L6_2.w = L2_2
  L7_2 = CreateEngineHoistInteract
  L8_2 = L5_2
  L9_2 = L6_2
  L10_2 = "Open Bonnet"
  function L11_2()
    local L0_3, L1_3, L2_3
    L0_3 = RemoveBonnetForInstall
    L1_3 = L5_2
    L2_3 = A0_2
    L0_3(L1_3, L2_3)
  end
  L7_2(L8_2, L9_2, L10_2, L11_2)
end
CreateVehicleBonnetInteractionForInstall = L33_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A1_2 then
    L2_2 = DoesEntityExist
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L2_2 = RemoveInteract
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = SetVehicleDoorOpen
  L3_2 = A1_2
  L4_2 = 4
  L5_2 = false
  L6_2 = false
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = Wait
  L3_2 = 1000
  L2_2(L3_2)
  L2_2 = SetVehicleDoorBroken
  L3_2 = A1_2
  L4_2 = 4
  L5_2 = true
  L2_2(L3_2, L4_2, L5_2)
  L15_1.bonnetRemoved = true
  L2_2 = CreateInstallEngineInteraction
  L3_2 = A1_2
  L2_2(L3_2)
end
RemoveBonnetForInstall = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L1_2 = type
  L2_2 = CreateEngineHoistInteract
  L1_2 = L1_2(L2_2)
  if "function" ~= L1_2 then
    return
  end
  L1_2 = GetEntityCoords
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = GetEntityHeading
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetEntityForwardVector
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = vector3
  L5_2 = L1_2.x
  L6_2 = L3_2.x
  L6_2 = L6_2 * 1.5
  L5_2 = L5_2 + L6_2
  L6_2 = L1_2.y
  L7_2 = L3_2.y
  L7_2 = L7_2 * 1.5
  L6_2 = L6_2 + L7_2
  L7_2 = L1_2.z
  L7_2 = L7_2 + 0.5
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = string
  L5_2 = L5_2.format
  L6_2 = "vehicle_bonnet_%d"
  L7_2 = A0_2
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = {}
  L7_2 = L4_2.x
  L6_2.x = L7_2
  L7_2 = L4_2.y
  L6_2.y = L7_2
  L7_2 = L4_2.z
  L6_2.z = L7_2
  L6_2.w = L2_2
  L7_2 = CreateEngineHoistInteract
  L8_2 = L5_2
  L9_2 = L6_2
  L10_2 = "Remove Bonnet"
  function L11_2()
    local L0_3, L1_3, L2_3
    L0_3 = RemoveBonnet
    L1_3 = A0_2
    L2_3 = L5_2
    L0_3(L1_3, L2_3)
  end
  L7_2(L8_2, L9_2, L10_2, L11_2)
end
CreateVehicleBonnetInteraction = L33_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L2_2 = DoesEntityExist
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = L15_1.bonnetRemoved
    if not L2_2 then
      L2_2 = L15_1.isBusy
      if not L2_2 then
        goto lbl_13
      end
    end
  end
  do return end
  ::lbl_13::
  L15_1.isBusy = true
  L2_2 = RemoveInteract
  L3_2 = A1_2
  L2_2(L3_2)
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = "mini@repair"
  L4_2 = RequestAnimDict
  L5_2 = L3_2
  L4_2(L5_2)
  while true do
    L4_2 = HasAnimDictLoaded
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      break
    end
    L4_2 = Wait
    L5_2 = 10
    L4_2(L5_2)
  end
  L4_2 = TaskPlayAnim
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = "fixing_a_player"
  L8_2 = 8.0
  L9_2 = -8.0
  L10_2 = -1
  L11_2 = 1
  L12_2 = 0
  L13_2 = false
  L14_2 = false
  L15_2 = false
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L4_2 = false
  L5_2 = type
  L6_2 = PerformSkillCheck
  L5_2 = L5_2(L6_2)
  if "function" == L5_2 then
    L5_2 = PerformSkillCheck
    L6_2 = {}
    L7_2 = "easy"
    L8_2 = "easy"
    L9_2 = "medium"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "w"
    L9_2 = "a"
    L10_2 = "s"
    L11_2 = "d"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L5_2 = L5_2(L6_2, L7_2)
    L4_2 = L5_2
  else
    L5_2 = Wait
    L6_2 = 3000
    L5_2(L6_2)
    L4_2 = true
  end
  L5_2 = ClearPedTasks
  L6_2 = L2_2
  L5_2(L6_2)
  if not L4_2 then
    L15_1.isBusy = false
    L5_2 = Wait
    L6_2 = 500
    L5_2(L6_2)
    L5_2 = CreateVehicleBonnetInteraction
    L6_2 = A0_2
    L5_2(L6_2)
    return
  end
  L5_2 = SetVehicleDoorBroken
  L6_2 = A0_2
  L7_2 = 4
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L15_1.bonnetRemoved = true
  L15_1.isBusy = false
  L5_2 = CreateHoistCrankInteraction
  L5_2()
end
RemoveBonnet = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L15_1.prop
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L15_1.prop
    L0_2 = L0_2(L1_2)
    if L0_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L0_2 = type
  L1_2 = CreateEngineHoistInteract
  L0_2 = L0_2(L1_2)
  if "function" ~= L0_2 then
    return
  end
  L0_2 = GetEntityCoords
  L1_2 = L15_1.prop
  L0_2 = L0_2(L1_2)
  L1_2 = GetEntityHeading
  L2_2 = L15_1.prop
  L1_2 = L1_2(L2_2)
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "hoist_crank_%d"
  L4_2 = L15_1.prop
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = {}
  L4_2 = L0_2.x
  L3_2.x = L4_2
  L4_2 = L0_2.y
  L3_2.y = L4_2
  L4_2 = L0_2.z
  L4_2 = L4_2 + 1.0
  L3_2.z = L4_2
  L3_2.w = L1_2
  L4_2 = CreateEngineHoistInteract
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = "Extract Engine"
  function L8_2()
    local L0_3, L1_3
    L0_3 = ExtractEngineFromVehicle
    L1_3 = L2_2
    L0_3(L1_3)
  end
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
CreateHoistCrankInteraction = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2
  L1_2 = L15_1.vehicle
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L15_1.vehicle
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = L15_1.engineAttached
  if not L1_2 then
    L1_2 = L15_1.isBusy
    if not L1_2 then
      goto lbl_17
    end
  end
  do return end
  ::lbl_17::
  L1_2 = L15_1.vehicle
  L2_2 = 0
  while true do
    L3_2 = NetworkHasControlOfEntity
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    if not (not L3_2 and L2_2 < 100) then
      break
    end
    L3_2 = NetworkRequestControlOfEntity
    L4_2 = L1_2
    L3_2(L4_2)
    L3_2 = Wait
    L4_2 = 10
    L3_2(L4_2)
    L2_2 = L2_2 + 1
  end
  L3_2 = NetworkHasControlOfEntity
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    return
  end
  L3_2 = SetEntityAsMissionEntity
  L4_2 = L1_2
  L5_2 = true
  L6_2 = true
  L3_2(L4_2, L5_2, L6_2)
  L15_1.isBusy = true
  L3_2 = RemoveInteract
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = GetVehicleNumberPlateText
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  L4_2 = lib
  L4_2 = L4_2.callback
  L4_2 = L4_2.await
  L5_2 = "qs-mechanic-creator:server:getVehicleEngineConfig"
  L6_2 = false
  L7_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_2 = PlayerPedId
  L5_2 = L5_2()
  L6_2 = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L7_2 = RequestAnimDict
  L8_2 = L6_2
  L7_2(L8_2)
  while true do
    L7_2 = HasAnimDictLoaded
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      break
    end
    L7_2 = Wait
    L8_2 = 10
    L7_2(L8_2)
  end
  L7_2 = TaskPlayAnim
  L8_2 = L5_2
  L9_2 = L6_2
  L10_2 = "machinic_loop_mechandplayer"
  L11_2 = 8.0
  L12_2 = -8.0
  L13_2 = -1
  L14_2 = 1
  L15_2 = 0
  L16_2 = false
  L17_2 = false
  L18_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L7_2 = false
  L8_2 = type
  L9_2 = PerformSkillCheck
  L8_2 = L8_2(L9_2)
  if "function" == L8_2 then
    L8_2 = PerformSkillCheck
    L9_2 = {}
    L10_2 = "easy"
    L11_2 = "easy"
    L12_2 = "medium"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L10_2 = {}
    L11_2 = "w"
    L12_2 = "a"
    L13_2 = "s"
    L14_2 = "d"
    L10_2[1] = L11_2
    L10_2[2] = L12_2
    L10_2[3] = L13_2
    L10_2[4] = L14_2
    L8_2 = L8_2(L9_2, L10_2)
    L7_2 = L8_2
  else
    L8_2 = Wait
    L9_2 = 5000
    L8_2(L9_2)
    L7_2 = true
  end
  L8_2 = ClearPedTasks
  L9_2 = L5_2
  L8_2(L9_2)
  if not L7_2 then
    L15_1.isBusy = false
    L8_2 = Wait
    L9_2 = 500
    L8_2(L9_2)
    L8_2 = CreateHoistCrankInteraction
    L8_2()
    return
  end
  L8_2 = DoesEntityExist
  L9_2 = L1_2
  L8_2 = L8_2(L9_2)
  if not L8_2 then
    L15_1.isBusy = false
    return
  end
  L8_2 = lib
  L8_2 = L8_2.callback
  L8_2 = L8_2.await
  L9_2 = "qs-mechanic-creator:server:removeVehicleEngine"
  L10_2 = false
  L11_2 = L3_2
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  if not L8_2 then
    L15_1.isBusy = false
    return
  end
  L9_2 = L9_1
  L9_2[L3_2] = false
  L9_2 = TriggerServerEvent
  L10_2 = "qs-mechanic-creator:server:syncEngineStatus"
  L11_2 = L3_2
  L12_2 = false
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = TriggerEvent
  L10_2 = "qs-mechanic-creator:client:updateEngineStatus"
  L11_2 = L3_2
  L12_2 = false
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = lib
  L9_2 = L9_2.callback
  L9_2 = L9_2.await
  L10_2 = "qs-mechanic-creator:server:clearVehicleEngineConfig"
  L11_2 = false
  L12_2 = L3_2
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = NetworkGetNetworkIdFromEntity
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  if L9_2 and 0 ~= L9_2 then
    L10_2 = TriggerServerEvent
    L11_2 = "qs-mechanic-creator:server:setEngineConfig"
    L12_2 = {}
    L12_2.net = L9_2
    L12_2.sound = nil
    L12_2.mods = nil
    L12_2.engineType = nil
    L10_2(L11_2, L12_2)
  end
  L15_1.originalEngineData = L4_2
  L15_1.engineType = nil
  L10_2 = GetEntityCoords
  L11_2 = L15_1.prop
  L10_2 = L10_2(L11_2)
  L11_2 = GetEntityHeading
  L12_2 = L15_1.prop
  L11_2 = L11_2(L12_2)
  L12_2 = GetEntityForwardVector
  L13_2 = L15_1.prop
  L12_2 = L12_2(L13_2)
  L13_2 = vector3
  L14_2 = L12_2.y
  L14_2 = -L14_2
  L15_2 = L12_2.x
  L16_2 = 0.0
  L13_2 = L13_2(L14_2, L15_2, L16_2)
  L14_2 = vector3
  L15_2 = L10_2.x
  L16_2 = L12_2.x
  L16_2 = L16_2 * -1.2
  L15_2 = L15_2 + L16_2
  L16_2 = L13_2.x
  L16_2 = L16_2 * 0.2
  L15_2 = L15_2 + L16_2
  L16_2 = L10_2.y
  L17_2 = L12_2.y
  L17_2 = L17_2 * -1.2
  L16_2 = L16_2 + L17_2
  L17_2 = L13_2.y
  L17_2 = L17_2 * 0.2
  L16_2 = L16_2 + L17_2
  L17_2 = L10_2.z
  L14_2 = L14_2(L15_2, L16_2, L17_2)
  L15_2 = GetEntityHeading
  L16_2 = L1_2
  L15_2 = L15_2(L16_2)
  L16_2 = L19_1
  L17_2 = L14_2
  L18_2 = L15_2
  L16_2, L17_2 = L16_2(L17_2, L18_2)
  if not L16_2 then
    return
  end
  L15_1.engineProp = L16_2
  L18_2 = Wait
  L19_2 = 1000
  L18_2(L19_2)
  L18_2 = L10_2.z
  L18_2 = L18_2 + 1.1
  L19_2 = GetEntityCoords
  L20_2 = L16_2
  L19_2 = L19_2(L20_2)
  L20_2 = 50
  L21_2 = L19_2.z
  L21_2 = L18_2 - L21_2
  L21_2 = L21_2 / L20_2
  L22_2 = TriggerServerEvent
  L23_2 = "qs-mechanic-creator:server:syncEngineLift"
  L24_2 = L17_2
  L25_2 = L19_2.x
  L26_2 = L19_2.y
  L27_2 = L19_2.z
  L28_2 = L18_2
  L29_2 = L20_2
  L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2)
  L22_2 = 1
  L23_2 = L20_2
  L24_2 = 1
  for L25_2 = L22_2, L23_2, L24_2 do
    L26_2 = DoesEntityExist
    L27_2 = L16_2
    L26_2 = L26_2(L27_2)
    if not L26_2 then
      break
    end
    L26_2 = GetEntityCoords
    L27_2 = L16_2
    L26_2 = L26_2(L27_2)
    L27_2 = SetEntityCoords
    L28_2 = L16_2
    L29_2 = L19_2.x
    L30_2 = L19_2.y
    L31_2 = L26_2.z
    L31_2 = L31_2 + L21_2
    L27_2(L28_2, L29_2, L30_2, L31_2)
    L27_2 = Wait
    L28_2 = 50
    L27_2(L28_2)
  end
  L22_2 = Wait
  L23_2 = 100
  L22_2(L23_2)
  L22_2 = AttachEntityToEntity
  L23_2 = L16_2
  L24_2 = L15_1.prop
  L25_2 = 0
  L26_2 = 0.0
  L27_2 = -1.2
  L28_2 = 1.1
  L29_2 = 0.0
  L30_2 = 0.0
  L31_2 = 0.0
  L32_2 = false
  L33_2 = false
  L34_2 = false
  L35_2 = false
  L36_2 = 2
  L37_2 = true
  L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2)
  L15_1.engineAttached = true
  L15_1.engineFromPallet = false
  L15_1.engineSourceShopId = nil
  L15_1.isBusy = false
  L22_2 = NetworkGetNetworkIdFromEntity
  L23_2 = L15_1.prop
  L22_2 = L22_2(L23_2)
  L23_2 = TriggerServerEvent
  L24_2 = "qs-mechanic-creator:server:syncEngineAttach"
  L25_2 = L17_2
  L26_2 = L22_2
  L23_2(L24_2, L25_2, L26_2)
  L23_2 = CreateDetachHoistInteraction
  L23_2()
end
ExtractEngineFromVehicle = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L15_1.prop
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L15_1.prop
    L0_2 = L0_2(L1_2)
    if L0_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L0_2 = type
  L1_2 = CreateEngineHoistInteract
  L0_2 = L0_2(L1_2)
  if "function" ~= L0_2 then
    return
  end
  L0_2 = GetEntityCoords
  L1_2 = L15_1.prop
  L0_2 = L0_2(L1_2)
  L1_2 = GetEntityHeading
  L2_2 = L15_1.prop
  L1_2 = L1_2(L2_2)
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "hoist_move_%d"
  L4_2 = L15_1.prop
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = {}
  L4_2 = L0_2.x
  L3_2.x = L4_2
  L4_2 = L0_2.y
  L3_2.y = L4_2
  L4_2 = L0_2.z
  L4_2 = L4_2 + 1.0
  L3_2.z = L4_2
  L3_2.w = L1_2
  L4_2 = CreateEngineHoistInteract
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = "Move Hoist"
  function L8_2()
    local L0_3, L1_3
    L0_3 = DetachHoistWithEngine
    L1_3 = L2_2
    L0_3(L1_3)
  end
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
CreateDetachHoistInteraction = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = L15_1.prop
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L15_1.prop
    L0_2 = L0_2(L1_2)
    if L0_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L0_2 = type
  L1_2 = CreateEngineHoistInteract
  L0_2 = L0_2(L1_2)
  if "function" ~= L0_2 then
    return
  end
  L0_2 = GetEntityCoords
  L1_2 = L15_1.prop
  L0_2 = L0_2(L1_2)
  L1_2 = GetEntityHeading
  L2_2 = L15_1.prop
  L1_2 = L1_2(L2_2)
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = "hoist_drop_%d"
  L4_2 = L15_1.prop
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = {}
  L4_2 = L0_2.x
  L3_2.x = L4_2
  L4_2 = L0_2.y
  L3_2.y = L4_2
  L4_2 = L0_2.z
  L4_2 = L4_2 + 1.0
  L3_2.z = L4_2
  L3_2.w = L1_2
  L4_2 = CreateEngineHoistInteract
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = "Drop Engine"
  function L8_2()
    local L0_3, L1_3
    L0_3 = DropEngineFromHook
    L1_3 = L2_2
    L0_3(L1_3)
  end
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
CreateDropEngineInteraction = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = L15_1.engineProp
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L15_1.engineProp
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = L15_1.isBusy
      if not L1_2 then
        goto lbl_13
      end
    end
  end
  do return end
  ::lbl_13::
  L15_1.isBusy = true
  L1_2 = RemoveInteract
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = PlayerPedId
  L1_2 = L1_2()
  L2_2 = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L3_2 = RequestAnimDict
  L4_2 = L2_2
  L3_2(L4_2)
  while true do
    L3_2 = HasAnimDictLoaded
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      break
    end
    L3_2 = Wait
    L4_2 = 10
    L3_2(L4_2)
  end
  L3_2 = TaskPlayAnim
  L4_2 = L1_2
  L5_2 = L2_2
  L6_2 = "machinic_loop_mechandplayer"
  L7_2 = 8.0
  L8_2 = -8.0
  L9_2 = -1
  L10_2 = 1
  L11_2 = 0
  L12_2 = false
  L13_2 = false
  L14_2 = false
  L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L3_2 = false
  L4_2 = type
  L5_2 = PerformSkillCheck
  L4_2 = L4_2(L5_2)
  if "function" == L4_2 then
    L4_2 = PerformSkillCheck
    L5_2 = {}
    L6_2 = "easy"
    L7_2 = "easy"
    L8_2 = "medium"
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    L6_2 = {}
    L7_2 = "w"
    L8_2 = "a"
    L9_2 = "s"
    L10_2 = "d"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L6_2[4] = L10_2
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
  else
    L4_2 = Wait
    L5_2 = 3000
    L4_2(L5_2)
    L3_2 = true
  end
  L4_2 = ClearPedTasks
  L5_2 = L1_2
  L4_2(L5_2)
  if not L3_2 then
    L15_1.isBusy = false
    L4_2 = Wait
    L5_2 = 500
    L4_2(L5_2)
    L4_2 = CreateDropEngineInteraction
    L4_2()
    return
  end
  L4_2 = L15_1.engineProp
  L5_2 = L15_1.engineFromPallet
  L6_2 = L15_1.engineSourceShopId
  L7_2 = L15_1.originalEngineData
  L8_2 = L15_1.shopId
  L9_2 = L15_1.prop
  L10_2 = DetachEntity
  L11_2 = L4_2
  L12_2 = true
  L13_2 = true
  L10_2(L11_2, L12_2, L13_2)
  L15_1.engineProp = nil
  L15_1.engineAttached = false
  L15_1.engineFromPallet = false
  L15_1.engineSourceShopId = nil
  L15_1.engineType = nil
  L15_1.originalEngineData = nil
  L15_1.isBusy = false
  if L5_2 and L6_2 and L7_2 then
    L10_2 = DoesEntityExist
    L11_2 = L4_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = NetworkGetNetworkIdFromEntity
      L11_2 = L4_2
      L10_2 = L10_2(L11_2)
      L11_2 = TriggerServerEvent
      L12_2 = "qs-mechanic-creator:server:syncEngineDelete"
      L13_2 = L10_2
      L11_2(L12_2, L13_2)
      L11_2 = DeleteEntity
      L12_2 = L4_2
      L11_2(L12_2)
    end
    L10_2 = lib
    L10_2 = L10_2.callback
    L10_2 = L10_2.await
    L11_2 = "qs-mechanic-creator:server:returnEngineToStock"
    L12_2 = false
    L13_2 = L6_2
    L14_2 = L7_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
    L10_2 = TriggerEvent
    L11_2 = "qs-mechanic-creator:client:palletEngineUpdated"
    L12_2 = L6_2
    L10_2(L11_2, L12_2)
  else
    L10_2 = SetEntityCollision
    L11_2 = L4_2
    L12_2 = true
    L13_2 = true
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = FreezeEntityPosition
    L11_2 = L4_2
    L12_2 = false
    L10_2(L11_2, L12_2)
    L10_2 = SetEntityDynamic
    L11_2 = L4_2
    L12_2 = true
    L10_2(L11_2, L12_2)
    L10_2 = NetworkGetNetworkIdFromEntity
    L11_2 = L4_2
    L10_2 = L10_2(L11_2)
    L11_2 = TriggerServerEvent
    L12_2 = "qs-mechanic-creator:server:syncEngineDelete"
    L13_2 = L10_2
    L11_2(L12_2, L13_2)
    L11_2 = CreateThread
    function L12_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
      L0_3 = Wait
      L1_3 = 5000
      L0_3(L1_3)
      L0_3 = DoesEntityExist
      L1_3 = L4_2
      L0_3 = L0_3(L1_3)
      if L0_3 then
        L0_3 = 255
        L1_3 = 0
        L2_3 = -5
        for L3_3 = L0_3, L1_3, L2_3 do
          L4_3 = DoesEntityExist
          L5_3 = L4_2
          L4_3 = L4_3(L5_3)
          if L4_3 then
            L4_3 = SetEntityAlpha
            L5_3 = L4_2
            L6_3 = L3_3
            L7_3 = false
            L4_3(L5_3, L6_3, L7_3)
            L4_3 = Wait
            L5_3 = 50
            L4_3(L5_3)
          end
        end
        L0_3 = DoesEntityExist
        L1_3 = L4_2
        L0_3 = L0_3(L1_3)
        if L0_3 then
          L0_3 = DeleteEntity
          L1_3 = L4_2
          L0_3(L1_3)
        end
      end
    end
    L11_2(L12_2)
  end
  if L9_2 then
    L10_2 = DoesEntityExist
    L11_2 = L9_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = L5_1
      if not L10_2 then
        L10_2 = {}
      end
      L5_1 = L10_2
      L10_2 = tostring
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      L11_2 = L5_1
      L12_2 = tostring
      L13_2 = L8_2
      L12_2 = L12_2(L13_2)
      L13_2 = L5_1
      L12_2 = L13_2[L12_2]
      if not L12_2 then
        L12_2 = {}
      end
      L11_2[L10_2] = L12_2
      L10_2 = tostring
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      L11_2 = L5_1
      L10_2 = L11_2[L10_2]
      L10_2.hoist = L9_2
      L10_2 = GetEntityCoords
      L11_2 = L9_2
      L10_2 = L10_2(L11_2)
      L11_2 = GetEntityHeading
      L12_2 = L9_2
      L11_2 = L11_2(L12_2)
      L12_2 = string
      L12_2 = L12_2.format
      L13_2 = "hoist_pickup_%d"
      L14_2 = L9_2
      L12_2 = L12_2(L13_2, L14_2)
      L13_2 = {}
      L14_2 = L10_2.x
      L13_2.x = L14_2
      L14_2 = L10_2.y
      L13_2.y = L14_2
      L14_2 = L10_2.z
      L14_2 = L14_2 + 1.0
      L13_2.z = L14_2
      L13_2.w = L11_2
      L14_2 = CreateEngineHoistInteract
      L15_2 = L12_2
      L16_2 = L13_2
      L17_2 = _U
      L18_2 = "ENGINE_HOIST_USE"
      L17_2 = L17_2(L18_2)
      function L18_2()
        local L0_3, L1_3, L2_3
        L0_3 = RemoveInteract
        L1_3 = L12_2
        L0_3(L1_3)
        L0_3 = L8_2
        L15_1.shopId = L0_3
        L0_3 = TriggerEvent
        L1_3 = "qs-mechanic-creator:client:useEngineHoist"
        L2_3 = L8_2
        L0_3(L1_3, L2_3)
      end
      L14_2(L15_2, L16_2, L17_2, L18_2)
    end
  end
end
DropEngineFromHook = L33_1
function L33_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2
  L1_2 = L15_1.prop
  if L1_2 then
    L1_2 = DoesEntityExist
    L2_2 = L15_1.prop
    L1_2 = L1_2(L2_2)
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = RemoveInteract
  L2_2 = A0_2
  L1_2(L2_2)
  L1_2 = L15_1.prop
  L2_2 = L15_1.shopId
  L3_2 = L15_1.engineProp
  L4_2 = L15_1.engineAttached
  L5_2 = FreezeEntityPosition
  L6_2 = L1_2
  L7_2 = false
  L5_2(L6_2, L7_2)
  L5_2 = L15_1.vehicle
  if L5_2 then
    L5_2 = DoesEntityExist
    L6_2 = L15_1.vehicle
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L5_2 = FreezeEntityPosition
      L6_2 = L15_1.vehicle
      L7_2 = false
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = PlayerPedId
  L5_2 = L5_2()
  L6_2 = "anim@heists@box_carry@"
  L7_2 = RequestAnimDict
  L8_2 = L6_2
  L7_2(L8_2)
  while true do
    L7_2 = HasAnimDictLoaded
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      break
    end
    L7_2 = Wait
    L8_2 = 10
    L7_2(L8_2)
  end
  L7_2 = TaskPlayAnim
  L8_2 = L5_2
  L9_2 = L6_2
  L10_2 = "idle"
  L11_2 = 8.0
  L12_2 = 8.0
  L13_2 = -1
  L14_2 = 50
  L15_2 = 0
  L16_2 = false
  L17_2 = false
  L18_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L7_2 = L5_1
  if L7_2 then
    L7_2 = tostring
    L8_2 = L2_2
    L7_2 = L7_2(L8_2)
    L8_2 = L5_1
    L7_2 = L8_2[L7_2]
  end
  if L7_2 then
    L7_2.hoist = nil
  end
  L8_2 = nil
  L9_2 = NetworkGetEntityIsNetworked
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  if L9_2 then
    L8_2 = L1_2
  else
    L10_2 = GetEntityCoords
    L11_2 = L1_2
    L10_2 = L10_2(L11_2)
    L11_2 = GetEntityHeading
    L12_2 = L1_2
    L11_2 = L11_2(L12_2)
    L12_2 = DeleteEntity
    L13_2 = L1_2
    L12_2(L13_2)
    L12_2 = Wait
    L13_2 = 100
    L12_2(L13_2)
    L12_2 = L24_1
    L13_2 = L3_1
    L14_2 = L10_2
    L15_2 = L11_2
    L16_2 = true
    L17_2 = true
    L18_2 = true
    L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
    L8_2 = L12_2
  end
  if L8_2 then
    L10_2 = DoesEntityExist
    L11_2 = L8_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      goto lbl_110
    end
  end
  L15_1.attached = false
  do return end
  ::lbl_110::
  L10_2 = AttachEntityToEntity
  L11_2 = L8_2
  L12_2 = L5_2
  L13_2 = GetPedBoneIndex
  L14_2 = L5_2
  L15_2 = 28422
  L13_2 = L13_2(L14_2, L15_2)
  L14_2 = 0.0
  L15_2 = -1.2
  L16_2 = -1.5
  L17_2 = 15.0
  L18_2 = 0.0
  L19_2 = 0.0
  L20_2 = true
  L21_2 = true
  L22_2 = false
  L23_2 = true
  L24_2 = 1
  L25_2 = true
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  if L4_2 and L3_2 then
    L10_2 = DoesEntityExist
    L11_2 = L3_2
    L10_2 = L10_2(L11_2)
    if L10_2 then
      L10_2 = AttachEntityToEntity
      L11_2 = L3_2
      L12_2 = L8_2
      L13_2 = 0
      L14_2 = 0.0
      L15_2 = -1.2
      L16_2 = 1.1
      L17_2 = 0.0
      L18_2 = 0.0
      L19_2 = 0.0
      L20_2 = false
      L21_2 = false
      L22_2 = false
      L23_2 = false
      L24_2 = 2
      L25_2 = true
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
      L10_2 = NetworkGetNetworkIdFromEntity
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      L11_2 = NetworkGetNetworkIdFromEntity
      L12_2 = L3_2
      L11_2 = L11_2(L12_2)
      L12_2 = TriggerServerEvent
      L13_2 = "qs-mechanic-creator:server:syncEngineAttach"
      L14_2 = L11_2
      L15_2 = L10_2
      L12_2(L13_2, L14_2, L15_2)
    end
  end
  L15_1.prop = L8_2
  L15_1.attached = true
  L10_2 = NetworkGetNetworkIdFromEntity
  L11_2 = L8_2
  L10_2 = L10_2(L11_2)
  L11_2 = TriggerServerEvent
  L12_2 = "qs-mechanic-creator:server:syncHoistAttach"
  L13_2 = L10_2
  L14_2 = L2_2
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = TriggerServerEvent
  L12_2 = "qs-mechanic-creator:server:hoistPickedUp"
  L13_2 = L2_2
  L11_2(L12_2, L13_2)
  L11_2 = CreateThread
  function L12_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3
    while true do
      L0_3 = L15_1.attached
      if not L0_3 then
        break
      end
      L0_3 = PlayerPedId
      L0_3 = L0_3()
      L1_3 = GetEntityCoords
      L2_3 = L0_3
      L1_3 = L1_3(L2_3)
      L2_3 = GetEntityCoords
      L3_3 = L15_1.prop
      L2_3 = L2_3(L3_3)
      L3_3 = IsEntityPlayingAnim
      L4_3 = L0_3
      L5_3 = L6_2
      L6_3 = "idle"
      L7_3 = 3
      L3_3 = L3_3(L4_3, L5_3, L6_3, L7_3)
      if not L3_3 then
        L3_3 = TaskPlayAnim
        L4_3 = L0_3
        L5_3 = L6_2
        L6_3 = "idle"
        L7_3 = 8.0
        L8_3 = 8.0
        L9_3 = -1
        L10_3 = 50
        L11_3 = 0
        L12_3 = false
        L13_3 = false
        L14_3 = false
        L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      end
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 24
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 25
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 44
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = DisableControlAction
      L4_3 = 0
      L5_3 = 37
      L6_3 = true
      L3_3(L4_3, L5_3, L6_3)
      L3_3 = L16_1
      L4_3 = vector3
      L5_3 = L2_3.x
      L6_3 = L2_3.y
      L7_3 = L2_3.z
      L7_3 = L7_3 + 1.0
      L4_3 = L4_3(L5_3, L6_3, L7_3)
      L5_3 = _U
      L6_3 = "ENGINE_HOIST_RELEASE"
      L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3 = L5_3(L6_3)
      L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
      L3_3 = GetNearestVehicle
      L4_3 = L1_3
      L3_3, L4_3 = L3_3(L4_3)
      if L3_3 then
        L5_3 = GetVehicleNumberPlateText
        L6_3 = L4_3
        L5_3 = L5_3(L6_3)
        L6_3 = L9_1
        L6_3 = L6_3[L5_3]
        if nil == L6_3 then
          L7_3 = lib
          L7_3 = L7_3.callback
          L7_3 = L7_3.await
          L8_3 = "qs-mechanic-creator:server:vehicleHasEngine"
          L9_3 = false
          L10_3 = L5_3
          L7_3 = L7_3(L8_3, L9_3, L10_3)
          L6_3 = L7_3
          L7_3 = L9_1
          L7_3[L5_3] = L6_3
        end
        if not L6_3 then
          L7_3 = L16_1
          L8_3 = vector3
          L9_3 = L2_3.x
          L10_3 = L2_3.y
          L11_3 = L2_3.z
          L11_3 = L11_3 + 0.7
          L8_3 = L8_3(L9_3, L10_3, L11_3)
          L9_3 = _U
          L10_3 = "ENGINE_HOIST_PLACE_NEAR_VEHICLE"
          L9_3, L10_3, L11_3, L12_3, L13_3, L14_3 = L9_3(L10_3)
          L7_3(L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3)
          L7_3 = IsControlJustReleased
          L8_3 = 0
          L9_3 = 38
          L7_3 = L7_3(L8_3, L9_3)
          if L7_3 then
            L7_3 = PlaceHoistNearVehicleForInstall
            L8_3 = L4_3
            L7_3(L8_3)
            break
          end
        end
      end
      L5_3 = IsControlJustReleased
      L6_3 = 0
      L7_3 = 194
      L5_3 = L5_3(L6_3, L7_3)
      if L5_3 then
        L5_3 = DetachHoistFinal
        L5_3()
        break
      end
      L5_3 = Wait
      L6_3 = 0
      L5_3(L6_3)
    end
  end
  L11_2(L12_2)
end
DetachHoistWithEngine = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L0_2 = L15_1.attached
  if not L0_2 then
    return
  end
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = L15_1.prop
  L2_2 = L15_1.shopId
  L3_2 = L15_1.engineProp
  L4_2 = L15_1.engineAttached
  L5_2 = ClearPedTasks
  L6_2 = L0_2
  L5_2(L6_2)
  if L1_2 then
    L5_2 = DoesEntityExist
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_23
    end
  end
  L15_1.attached = false
  do return end
  ::lbl_23::
  L5_2 = DetachEntity
  L6_2 = L1_2
  L7_2 = true
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = GetEntityCoords
  L6_2 = L0_2
  L5_2 = L5_2(L6_2)
  L6_2 = GetEntityHeading
  L7_2 = L0_2
  L6_2 = L6_2(L7_2)
  L7_2 = GetEntityForwardVector
  L8_2 = L0_2
  L7_2 = L7_2(L8_2)
  L8_2 = vector3
  L9_2 = L5_2.x
  L10_2 = L7_2.x
  L10_2 = L10_2 * 1.5
  L9_2 = L9_2 + L10_2
  L10_2 = L5_2.y
  L11_2 = L7_2.y
  L11_2 = L11_2 * 1.5
  L10_2 = L10_2 + L11_2
  L11_2 = L5_2.z
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = SetEntityCoords
  L10_2 = L1_2
  L11_2 = L8_2.x
  L12_2 = L8_2.y
  L13_2 = L8_2.z
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = SetEntityHeading
  L10_2 = L1_2
  L11_2 = L6_2 + 180.0
  L11_2 = L11_2 % 360.0
  L9_2(L10_2, L11_2)
  L9_2 = SetEntityCollision
  L10_2 = L1_2
  L11_2 = true
  L12_2 = true
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = PlaceObjectOnGroundProperly
  L10_2 = L1_2
  L9_2(L10_2)
  L9_2 = SetEntityHeading
  L10_2 = L1_2
  L11_2 = L6_2 + 180.0
  L11_2 = L11_2 % 360.0
  L9_2(L10_2, L11_2)
  L9_2 = SetEntityRotation
  L10_2 = L1_2
  L11_2 = 0.0
  L12_2 = 0.0
  L13_2 = L6_2 + 180.0
  L13_2 = L13_2 % 360.0
  L14_2 = 2
  L15_2 = true
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = Wait
  L10_2 = 100
  L9_2(L10_2)
  L9_2 = FreezeEntityPosition
  L10_2 = L1_2
  L11_2 = true
  L9_2(L10_2, L11_2)
  L9_2 = NetworkGetEntityFromNetworkId
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  L10_2 = GetEntityCoords
  L11_2 = L1_2
  L10_2 = L10_2(L11_2)
  L11_2 = GetEntityHeading
  L12_2 = L1_2
  L11_2 = L11_2(L12_2)
  L12_2 = nil
  if L4_2 and L3_2 then
    L13_2 = DoesEntityExist
    L14_2 = L3_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L13_2 = NetworkGetNetworkIdFromEntity
      L14_2 = L3_2
      L13_2 = L13_2(L14_2)
      L12_2 = L13_2
      L13_2 = TriggerServerEvent
      L14_2 = "qs-mechanic-creator:server:syncEngineAttach"
      L15_2 = L12_2
      L16_2 = L9_2
      L13_2(L14_2, L15_2, L16_2)
    end
  end
  L13_2 = TriggerServerEvent
  L14_2 = "qs-mechanic-creator:server:syncHoistPlace"
  L15_2 = L9_2
  L16_2 = L10_2.x
  L17_2 = L10_2.y
  L18_2 = L10_2.z
  L19_2 = L11_2
  L20_2 = L2_2
  L21_2 = L12_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L13_2 = L5_1
  if not L13_2 then
    L13_2 = {}
  end
  L5_1 = L13_2
  L13_2 = tostring
  L14_2 = L2_2
  L13_2 = L13_2(L14_2)
  L14_2 = L5_1
  L15_2 = tostring
  L16_2 = L2_2
  L15_2 = L15_2(L16_2)
  L16_2 = L5_1
  L15_2 = L16_2[L15_2]
  if not L15_2 then
    L15_2 = {}
  end
  L14_2[L13_2] = L15_2
  L13_2 = tostring
  L14_2 = L2_2
  L13_2 = L13_2(L14_2)
  L14_2 = L5_1
  L13_2 = L14_2[L13_2]
  L13_2.hoist = L1_2
  L15_1.attached = false
  L13_2 = Wait
  L14_2 = 100
  L13_2(L14_2)
  if L4_2 then
    L13_2 = CheckNearbyVehiclesAndPallet
    L13_2()
  else
    L13_2 = string
    L13_2 = L13_2.format
    L14_2 = "hoist_pickup_%d"
    L15_2 = L1_2
    L13_2 = L13_2(L14_2, L15_2)
    L14_2 = {}
    L15_2 = L10_2.x
    L14_2.x = L15_2
    L15_2 = L10_2.y
    L14_2.y = L15_2
    L15_2 = L10_2.z
    L15_2 = L15_2 + 1.0
    L14_2.z = L15_2
    L14_2.w = L11_2
    L15_2 = CreateEngineHoistInteract
    L16_2 = L13_2
    L17_2 = L14_2
    L18_2 = _U
    L19_2 = "ENGINE_HOIST_USE"
    L18_2 = L18_2(L19_2)
    function L19_2()
      local L0_3, L1_3, L2_3
      L0_3 = RemoveInteract
      L1_3 = L13_2
      L0_3(L1_3)
      L0_3 = L2_2
      L15_1.shopId = L0_3
      L0_3 = TriggerEvent
      L1_3 = "qs-mechanic-creator:client:useEngineHoist"
      L2_3 = L2_2
      L0_3(L1_3, L2_3)
    end
    L15_2(L16_2, L17_2, L18_2, L19_2)
  end
end
DetachHoistFinal = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = L15_1.shopId
  L1_2 = L15_1.prop
  L2_2 = L15_1.engineAttached
  if not L2_2 then
    if L1_2 then
      L2_2 = DoesEntityExist
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = GetEntityCoords
        L3_2 = L1_2
        L2_2 = L2_2(L3_2)
        L3_2 = GetEntityHeading
        L4_2 = L1_2
        L3_2 = L3_2(L4_2)
        L4_2 = string
        L4_2 = L4_2.format
        L5_2 = "hoist_pickup_%d"
        L6_2 = L1_2
        L4_2 = L4_2(L5_2, L6_2)
        L5_2 = {}
        L6_2 = L2_2.x
        L5_2.x = L6_2
        L6_2 = L2_2.y
        L5_2.y = L6_2
        L6_2 = L2_2.z
        L6_2 = L6_2 + 1.0
        L5_2.z = L6_2
        L5_2.w = L3_2
        L6_2 = CreateEngineHoistInteract
        L7_2 = L4_2
        L8_2 = L5_2
        L9_2 = _U
        L10_2 = "ENGINE_HOIST_USE"
        L9_2 = L9_2(L10_2)
        function L10_2()
          local L0_3, L1_3, L2_3
          L0_3 = RemoveInteract
          L1_3 = L4_2
          L0_3(L1_3)
          L0_3 = L0_2
          L15_1.shopId = L0_3
          L0_3 = TriggerEvent
          L1_3 = "qs-mechanic-creator:client:useEngineHoist"
          L2_3 = L0_2
          L0_3(L1_3, L2_3)
        end
        L6_2(L7_2, L8_2, L9_2, L10_2)
      end
    end
    return
  end
  L2_2 = CreateDropEngineInteraction
  L2_2()
end
CheckNearbyVehiclesAndPallet = L33_1
function L33_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2
  L2_2 = L15_1.engineProp
  if L2_2 then
    L2_2 = DoesEntityExist
    L3_2 = L15_1.engineProp
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  if A1_2 then
    L2_2 = DoesEntityExist
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = L15_1.isBusy
      if not L2_2 then
        goto lbl_21
      end
    end
  end
  do return end
  ::lbl_21::
  L15_1.isBusy = true
  L2_2 = RemoveInteract
  L3_2 = A0_2
  L2_2(L3_2)
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2 = RequestAnimDict
  L5_2 = L3_2
  L4_2(L5_2)
  while true do
    L4_2 = HasAnimDictLoaded
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      break
    end
    L4_2 = Wait
    L5_2 = 10
    L4_2(L5_2)
  end
  L4_2 = TaskPlayAnim
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = "machinic_loop_mechandplayer"
  L8_2 = 8.0
  L9_2 = -8.0
  L10_2 = -1
  L11_2 = 1
  L12_2 = 0
  L13_2 = false
  L14_2 = false
  L15_2 = false
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L4_2 = false
  L5_2 = type
  L6_2 = PerformSkillCheck
  L5_2 = L5_2(L6_2)
  if "function" == L5_2 then
    L5_2 = PerformSkillCheck
    L6_2 = {}
    L7_2 = "easy"
    L8_2 = "easy"
    L9_2 = "medium"
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L6_2[3] = L9_2
    L7_2 = {}
    L8_2 = "w"
    L9_2 = "a"
    L10_2 = "s"
    L11_2 = "d"
    L7_2[1] = L8_2
    L7_2[2] = L9_2
    L7_2[3] = L10_2
    L7_2[4] = L11_2
    L5_2 = L5_2(L6_2, L7_2)
    L4_2 = L5_2
  else
    L5_2 = Wait
    L6_2 = 5000
    L5_2(L6_2)
    L4_2 = true
  end
  L5_2 = ClearPedTasks
  L6_2 = L2_2
  L5_2(L6_2)
  if not L4_2 then
    L15_1.isBusy = false
    L5_2 = Wait
    L6_2 = 500
    L5_2(L6_2)
    L5_2 = GetEntityCoords
    L6_2 = L15_1.prop
    L5_2 = L5_2(L6_2)
    L6_2 = GetEntityHeading
    L7_2 = L15_1.prop
    L6_2 = L6_2(L7_2)
    L7_2 = string
    L7_2 = L7_2.format
    L8_2 = "hoist_install_%d"
    L9_2 = L15_1.prop
    L7_2 = L7_2(L8_2, L9_2)
    L8_2 = {}
    L9_2 = L5_2.x
    L8_2.x = L9_2
    L9_2 = L5_2.y
    L8_2.y = L9_2
    L9_2 = L5_2.z
    L9_2 = L9_2 + 1.0
    L8_2.z = L9_2
    L8_2.w = L6_2
    L9_2 = CreateEngineHoistInteract
    L10_2 = L7_2
    L11_2 = L8_2
    L12_2 = "Install Engine"
    function L13_2()
      local L0_3, L1_3, L2_3
      L0_3 = InstallEngineIntoVehicle
      L1_3 = L7_2
      L2_3 = A1_2
      L0_3(L1_3, L2_3)
    end
    L9_2(L10_2, L11_2, L12_2, L13_2)
    return
  end
  L5_2 = GetEntityCoords
  L6_2 = L15_1.prop
  L5_2 = L5_2(L6_2)
  L6_2 = GetEntityForwardVector
  L7_2 = L15_1.prop
  L6_2 = L6_2(L7_2)
  L7_2 = vector3
  L8_2 = L6_2.y
  L8_2 = -L8_2
  L9_2 = L6_2.x
  L10_2 = 0.0
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = vector3
  L9_2 = L5_2.x
  L10_2 = L6_2.x
  L10_2 = L10_2 * -1.2
  L9_2 = L9_2 + L10_2
  L10_2 = L7_2.x
  L10_2 = L10_2 * 0.2
  L9_2 = L9_2 + L10_2
  L10_2 = L5_2.y
  L11_2 = L6_2.y
  L11_2 = L11_2 * -1.2
  L10_2 = L10_2 + L11_2
  L11_2 = L7_2.y
  L11_2 = L11_2 * 0.2
  L10_2 = L10_2 + L11_2
  L11_2 = L5_2.z
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = L15_1.engineProp
  L10_2 = NetworkGetNetworkIdFromEntity
  L11_2 = L9_2
  L10_2 = L10_2(L11_2)
  L11_2 = GetEntityCoords
  L12_2 = L9_2
  L11_2 = L11_2(L12_2)
  L12_2 = 50
  L13_2 = L8_2.x
  L14_2 = L11_2.x
  L13_2 = L13_2 - L14_2
  L13_2 = L13_2 / L12_2
  L14_2 = L8_2.y
  L15_2 = L11_2.y
  L14_2 = L14_2 - L15_2
  L14_2 = L14_2 / L12_2
  L15_2 = L8_2.z
  L16_2 = L11_2.z
  L15_2 = L15_2 - L16_2
  L15_2 = L15_2 / L12_2
  L16_2 = DetachEntity
  L17_2 = L9_2
  L18_2 = false
  L19_2 = false
  L16_2(L17_2, L18_2, L19_2)
  L16_2 = SetEntityCollision
  L17_2 = L9_2
  L18_2 = false
  L19_2 = false
  L16_2(L17_2, L18_2, L19_2)
  L16_2 = TriggerServerEvent
  L17_2 = "qs-mechanic-creator:server:syncEngineLower"
  L18_2 = L10_2
  L19_2 = L11_2.x
  L20_2 = L11_2.y
  L21_2 = L11_2.z
  L22_2 = L8_2.x
  L23_2 = L8_2.y
  L24_2 = L8_2.z
  L25_2 = L12_2
  L16_2(L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2)
  L16_2 = 1
  L17_2 = L12_2
  L18_2 = 1
  for L19_2 = L16_2, L17_2, L18_2 do
    L20_2 = DoesEntityExist
    L21_2 = L9_2
    L20_2 = L20_2(L21_2)
    if not L20_2 then
      break
    end
    L20_2 = GetEntityCoords
    L21_2 = L9_2
    L20_2 = L20_2(L21_2)
    L21_2 = SetEntityCoords
    L22_2 = L9_2
    L23_2 = L20_2.x
    L23_2 = L23_2 + L13_2
    L24_2 = L20_2.y
    L24_2 = L24_2 + L14_2
    L25_2 = L20_2.z
    L25_2 = L25_2 + L15_2
    L21_2(L22_2, L23_2, L24_2, L25_2)
    L21_2 = Wait
    L22_2 = 50
    L21_2(L22_2)
  end
  L16_2 = Wait
  L17_2 = 500
  L16_2(L17_2)
  L16_2 = NetworkGetNetworkIdFromEntity
  L17_2 = L9_2
  L16_2 = L16_2(L17_2)
  L17_2 = TriggerServerEvent
  L18_2 = "qs-mechanic-creator:server:syncEngineDelete"
  L19_2 = L16_2
  L17_2(L18_2, L19_2)
  L17_2 = DoesEntityExist
  L18_2 = L9_2
  L17_2 = L17_2(L18_2)
  if L17_2 then
    L17_2 = DeleteEntity
    L18_2 = L9_2
    L17_2(L18_2)
  end
  L17_2 = FreezeEntityPosition
  L18_2 = A1_2
  L19_2 = false
  L17_2(L18_2, L19_2)
  L17_2 = GetVehicleNumberPlateText
  L18_2 = A1_2
  L17_2 = L17_2(L18_2)
  L18_2 = false
  L19_2 = L15_1.originalEngineData
  if L19_2 then
    L19_2 = L15_1.originalEngineData
    L19_2 = L19_2.sound
    if not L19_2 then
      L19_2 = L15_1.originalEngineData
      L19_2 = L19_2.mods
      if not L19_2 then
        goto lbl_317
      end
    end
    L19_2 = lib
    L19_2 = L19_2.callback
    L19_2 = L19_2.await
    L20_2 = "qs-mechanic-creator:server:installCustomVehicleEngine"
    L21_2 = false
    L22_2 = L17_2
    L23_2 = L15_1.originalEngineData
    L23_2 = L23_2.sound
    L24_2 = L15_1.originalEngineData
    L24_2 = L24_2.mods
    L19_2 = L19_2(L20_2, L21_2, L22_2, L23_2, L24_2)
    L18_2 = L19_2
    L19_2 = L9_1
    L19_2[L17_2] = true
    L19_2 = TriggerServerEvent
    L20_2 = "qs-mechanic-creator:server:syncEngineStatus"
    L21_2 = L17_2
    L22_2 = true
    L19_2(L20_2, L21_2, L22_2)
    L19_2 = TriggerEvent
    L20_2 = "qs-mechanic-creator:client:updateEngineStatus"
    L21_2 = L17_2
    L22_2 = true
    L19_2(L20_2, L21_2, L22_2)
    if L18_2 then
      L19_2 = NetworkGetNetworkIdFromEntity
      L20_2 = A1_2
      L19_2 = L19_2(L20_2)
      if L19_2 and 0 ~= L19_2 then
        L20_2 = TriggerServerEvent
        L21_2 = "qs-mechanic-creator:server:setEngineConfig"
        L22_2 = {}
        L22_2.net = L19_2
        L23_2 = L15_1.originalEngineData
        L23_2 = L23_2.sound
        L22_2.sound = L23_2
        L23_2 = L15_1.originalEngineData
        L23_2 = L23_2.mods
        L22_2.mods = L23_2
        L23_2 = L15_1.originalEngineData
        L23_2 = L23_2.engineType
        L22_2.engineType = L23_2
        L20_2(L21_2, L22_2)
      end
    end
  ::lbl_317::
  else
    L19_2 = L15_1.engineType
    if not L19_2 then
      L19_2 = nil
    end
    L20_2 = L19_2
    L21_2 = lib
    L21_2 = L21_2.callback
    L21_2 = L21_2.await
    L22_2 = "qs-mechanic-creator:server:installVehicleEngine"
    L23_2 = false
    L24_2 = L17_2
    L25_2 = L20_2
    L21_2 = L21_2(L22_2, L23_2, L24_2, L25_2)
    L18_2 = L21_2
    L21_2 = L9_1
    L21_2[L17_2] = true
    L21_2 = TriggerServerEvent
    L22_2 = "qs-mechanic-creator:server:syncEngineStatus"
    L23_2 = L17_2
    L24_2 = true
    L21_2(L22_2, L23_2, L24_2)
    L21_2 = TriggerEvent
    L22_2 = "qs-mechanic-creator:client:updateEngineStatus"
    L23_2 = L17_2
    L24_2 = true
    L21_2(L22_2, L23_2, L24_2)
    if L18_2 and L20_2 then
      L21_2 = EngineList
      L21_2 = L21_2[L20_2]
      if L21_2 then
        L21_2 = EngineList
        L21_2 = L21_2[L20_2]
        L22_2 = NetworkGetNetworkIdFromEntity
        L23_2 = A1_2
        L22_2 = L22_2(L23_2)
        if L22_2 and 0 ~= L22_2 then
          L23_2 = TriggerServerEvent
          L24_2 = "qs-mechanic-creator:server:setEngineConfig"
          L25_2 = {}
          L25_2.net = L22_2
          L26_2 = L21_2.sound
          L25_2.sound = L26_2
          L26_2 = L21_2.mods
          L25_2.mods = L26_2
          L26_2 = {}
          L26_2.id = L20_2
          L27_2 = L21_2.name
          L26_2.name = L27_2
          L25_2.engineType = L26_2
          L23_2(L24_2, L25_2)
        end
      end
    end
  end
  L19_2 = L15_1.prop
  L20_2 = L15_1.shopId
  L15_1.engineProp = nil
  L15_1.engineAttached = false
  L15_1.engineFromPallet = false
  L15_1.engineSourceShopId = nil
  L15_1.engineType = nil
  L15_1.originalEngineData = nil
  L15_1.isBusy = false
  if L20_2 then
    L21_2 = TriggerEvent
    L22_2 = "qs-mechanic-creator:client:restoreCarliftMovable"
    L23_2 = L20_2
    L21_2(L22_2, L23_2)
  end
  L21_2 = type
  L22_2 = showNotification
  L21_2 = L21_2(L22_2)
  if "function" == L21_2 then
    L21_2 = showNotification
    L22_2 = {}
    L23_2 = _U
    L24_2 = "ENGINE_INSTALL_SUCCESS"
    L23_2 = L23_2(L24_2)
    L22_2.description = L23_2
    L22_2.type = "success"
    L21_2(L22_2)
  else
    L21_2 = lib
    L21_2 = L21_2.notify
    L22_2 = {}
    L23_2 = _U
    L24_2 = "SUCCESS"
    L23_2 = L23_2(L24_2)
    L22_2.title = L23_2
    L23_2 = _U
    L24_2 = "ENGINE_INSTALL_SUCCESS"
    L23_2 = L23_2(L24_2)
    L22_2.description = L23_2
    L22_2.type = "success"
    L21_2(L22_2)
  end
  L21_2 = IsVehicleDoorDamaged
  L22_2 = A1_2
  L23_2 = 4
  L21_2 = L21_2(L22_2, L23_2)
  if L21_2 then
    L22_2 = GetEntityCoords
    L23_2 = A1_2
    L22_2 = L22_2(L23_2)
    L23_2 = GetEntityHeading
    L24_2 = A1_2
    L23_2 = L23_2(L24_2)
    L24_2 = GetEntityForwardVector
    L25_2 = A1_2
    L24_2 = L24_2(L25_2)
    L25_2 = vector3
    L26_2 = L22_2.x
    L27_2 = L24_2.x
    L27_2 = L27_2 * 1.5
    L26_2 = L26_2 + L27_2
    L27_2 = L22_2.y
    L28_2 = L24_2.y
    L28_2 = L28_2 * 1.5
    L27_2 = L27_2 + L28_2
    L28_2 = L22_2.z
    L28_2 = L28_2 + 0.5
    L25_2 = L25_2(L26_2, L27_2, L28_2)
    L26_2 = string
    L26_2 = L26_2.format
    L27_2 = "vehicle_bonnet_reattach_%d"
    L28_2 = A1_2
    L26_2 = L26_2(L27_2, L28_2)
    L27_2 = {}
    L28_2 = L25_2.x
    L27_2.x = L28_2
    L28_2 = L25_2.y
    L27_2.y = L28_2
    L28_2 = L25_2.z
    L27_2.z = L28_2
    L27_2.w = L23_2
    L28_2 = CreateEngineHoistInteract
    L29_2 = L26_2
    L30_2 = L27_2
    L31_2 = _U
    L32_2 = "ENGINE_REATTACH_BONNET"
    L31_2 = L31_2(L32_2)
    function L32_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = ReattachBonnet
      L1_3 = L26_2
      L2_3 = A1_2
      L3_3 = L19_2
      L4_3 = L20_2
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
    L28_2(L29_2, L30_2, L31_2, L32_2)
  elseif L19_2 then
    L22_2 = DoesEntityExist
    L23_2 = L19_2
    L22_2 = L22_2(L23_2)
    if L22_2 then
      L22_2 = L5_1
      if not L22_2 then
        L22_2 = {}
      end
      L5_1 = L22_2
      L22_2 = tostring
      L23_2 = L20_2
      L22_2 = L22_2(L23_2)
      L23_2 = L5_1
      L24_2 = tostring
      L25_2 = L20_2
      L24_2 = L24_2(L25_2)
      L25_2 = L5_1
      L24_2 = L25_2[L24_2]
      if not L24_2 then
        L24_2 = {}
      end
      L23_2[L22_2] = L24_2
      L22_2 = tostring
      L23_2 = L20_2
      L22_2 = L22_2(L23_2)
      L23_2 = L5_1
      L22_2 = L23_2[L22_2]
      L22_2.hoist = L19_2
      L22_2 = GetEntityCoords
      L23_2 = L19_2
      L22_2 = L22_2(L23_2)
      L23_2 = GetEntityHeading
      L24_2 = L19_2
      L23_2 = L23_2(L24_2)
      L24_2 = string
      L24_2 = L24_2.format
      L25_2 = "hoist_pickup_%d"
      L26_2 = L19_2
      L24_2 = L24_2(L25_2, L26_2)
      L25_2 = {}
      L26_2 = L22_2.x
      L25_2.x = L26_2
      L26_2 = L22_2.y
      L25_2.y = L26_2
      L26_2 = L22_2.z
      L26_2 = L26_2 + 1.0
      L25_2.z = L26_2
      L25_2.w = L23_2
      L26_2 = CreateEngineHoistInteract
      L27_2 = L24_2
      L28_2 = L25_2
      L29_2 = _U
      L30_2 = "ENGINE_HOIST_USE"
      L29_2 = L29_2(L30_2)
      function L30_2()
        local L0_3, L1_3, L2_3
        L0_3 = RemoveInteract
        L1_3 = L24_2
        L0_3(L1_3)
        L0_3 = L20_2
        L15_1.shopId = L0_3
        L0_3 = TriggerEvent
        L1_3 = "qs-mechanic-creator:client:useEngineHoist"
        L2_3 = L20_2
        L0_3(L1_3, L2_3)
      end
      L26_2(L27_2, L28_2, L29_2, L30_2)
    end
  end
end
InstallEngineIntoVehicle = L33_1
function L33_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if A1_2 then
    L4_2 = DoesEntityExist
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = L15_1.isBusy
      if not L4_2 then
        goto lbl_12
      end
    end
  end
  do return end
  ::lbl_12::
  L15_1.isBusy = true
  L4_2 = RemoveInteract
  L5_2 = A0_2
  L4_2(L5_2)
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = "mini@repair"
  L6_2 = RequestAnimDict
  L7_2 = L5_2
  L6_2(L7_2)
  while true do
    L6_2 = HasAnimDictLoaded
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      break
    end
    L6_2 = Wait
    L7_2 = 10
    L6_2(L7_2)
  end
  L6_2 = TaskPlayAnim
  L7_2 = L4_2
  L8_2 = L5_2
  L9_2 = "fixing_a_player"
  L10_2 = 8.0
  L11_2 = -8.0
  L12_2 = -1
  L13_2 = 1
  L14_2 = 0
  L15_2 = false
  L16_2 = false
  L17_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L6_2 = false
  L7_2 = type
  L8_2 = PerformSkillCheck
  L7_2 = L7_2(L8_2)
  if "function" == L7_2 then
    L7_2 = PerformSkillCheck
    L8_2 = {}
    L9_2 = "easy"
    L10_2 = "easy"
    L11_2 = "medium"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L9_2 = {}
    L10_2 = "w"
    L11_2 = "a"
    L12_2 = "s"
    L13_2 = "d"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L7_2
  else
    L7_2 = Wait
    L8_2 = 3000
    L7_2(L8_2)
    L6_2 = true
  end
  L7_2 = ClearPedTasks
  L8_2 = L4_2
  L7_2(L8_2)
  if not L6_2 then
    L15_1.isBusy = false
    L7_2 = Wait
    L8_2 = 500
    L7_2(L8_2)
    L7_2 = GetEntityCoords
    L8_2 = A1_2
    L7_2 = L7_2(L8_2)
    L8_2 = GetEntityHeading
    L9_2 = A1_2
    L8_2 = L8_2(L9_2)
    L9_2 = GetEntityForwardVector
    L10_2 = A1_2
    L9_2 = L9_2(L10_2)
    L10_2 = vector3
    L11_2 = L7_2.x
    L12_2 = L9_2.x
    L12_2 = L12_2 * 1.5
    L11_2 = L11_2 + L12_2
    L12_2 = L7_2.y
    L13_2 = L9_2.y
    L13_2 = L13_2 * 1.5
    L12_2 = L12_2 + L13_2
    L13_2 = L7_2.z
    L13_2 = L13_2 + 0.5
    L10_2 = L10_2(L11_2, L12_2, L13_2)
    L11_2 = string
    L11_2 = L11_2.format
    L12_2 = "vehicle_bonnet_reattach_%d"
    L13_2 = A1_2
    L11_2 = L11_2(L12_2, L13_2)
    L12_2 = {}
    L13_2 = L10_2.x
    L12_2.x = L13_2
    L13_2 = L10_2.y
    L12_2.y = L13_2
    L13_2 = L10_2.z
    L12_2.z = L13_2
    L12_2.w = L8_2
    L13_2 = CreateEngineHoistInteract
    L14_2 = L11_2
    L15_2 = L12_2
    L16_2 = _U
    L17_2 = "ENGINE_REATTACH_BONNET"
    L16_2 = L16_2(L17_2)
    function L17_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3
      L0_3 = ReattachBonnet
      L1_3 = L11_2
      L2_3 = A1_2
      L3_3 = A2_2
      L4_3 = A3_2
      L0_3(L1_3, L2_3, L3_3, L4_3)
    end
    L13_2(L14_2, L15_2, L16_2, L17_2)
    return
  end
  L15_1.isBusy = false
  if A3_2 then
    L7_2 = TriggerEvent
    L8_2 = "qs-mechanic-creator:client:restoreCarliftMovable"
    L9_2 = A3_2
    L7_2(L8_2, L9_2)
  end
  L7_2 = fixVehicleDeformation
  L8_2 = A1_2
  L7_2(L8_2)
  L7_2 = SetVehicleDoorShut
  L8_2 = A1_2
  L9_2 = 4
  L10_2 = false
  L7_2(L8_2, L9_2, L10_2)
  if A2_2 then
    L7_2 = DoesEntityExist
    L8_2 = A2_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L7_2 = L5_1
      if not L7_2 then
        L7_2 = {}
      end
      L5_1 = L7_2
      L7_2 = tostring
      L8_2 = A3_2
      L7_2 = L7_2(L8_2)
      L8_2 = L5_1
      L9_2 = tostring
      L10_2 = A3_2
      L9_2 = L9_2(L10_2)
      L10_2 = L5_1
      L9_2 = L10_2[L9_2]
      if not L9_2 then
        L9_2 = {}
      end
      L8_2[L7_2] = L9_2
      L7_2 = tostring
      L8_2 = A3_2
      L7_2 = L7_2(L8_2)
      L8_2 = L5_1
      L7_2 = L8_2[L7_2]
      L7_2.hoist = A2_2
      L7_2 = GetEntityCoords
      L8_2 = A2_2
      L7_2 = L7_2(L8_2)
      L8_2 = GetEntityHeading
      L9_2 = A2_2
      L8_2 = L8_2(L9_2)
      L9_2 = string
      L9_2 = L9_2.format
      L10_2 = "hoist_pickup_%d"
      L11_2 = A2_2
      L9_2 = L9_2(L10_2, L11_2)
      L10_2 = {}
      L11_2 = L7_2.x
      L10_2.x = L11_2
      L11_2 = L7_2.y
      L10_2.y = L11_2
      L11_2 = L7_2.z
      L11_2 = L11_2 + 1.0
      L10_2.z = L11_2
      L10_2.w = L8_2
      L11_2 = CreateEngineHoistInteract
      L12_2 = L9_2
      L13_2 = L10_2
      L14_2 = _U
      L15_2 = "ENGINE_HOIST_USE"
      L14_2 = L14_2(L15_2)
      function L15_2()
        local L0_3, L1_3, L2_3
        L0_3 = RemoveInteract
        L1_3 = L9_2
        L0_3(L1_3)
        L0_3 = A3_2
        L15_1.shopId = L0_3
        L0_3 = TriggerEvent
        L1_3 = "qs-mechanic-creator:client:useEngineHoist"
        L2_3 = A3_2
        L0_3(L1_3, L2_3)
      end
      L11_2(L12_2, L13_2, L14_2, L15_2)
    end
  end
end
ReattachBonnet = L33_1
function L33_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L3_2 = L15_1.engineProp
  if L3_2 then
    L3_2 = DoesEntityExist
    L4_2 = L15_1.engineProp
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  if A1_2 then
    L3_2 = DoesEntityExist
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_18
    end
  end
  do return end
  ::lbl_18::
  if not A2_2 then
    return
  end
  L3_2 = RemoveInteract
  L4_2 = A0_2
  L3_2(L4_2)
  L3_2 = lib
  L3_2 = L3_2.callback
  L3_2 = L3_2.await
  L4_2 = "qs-mechanic-creator:server:getPalletEngine"
  L5_2 = false
  L6_2 = A2_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if L3_2 then
    return
  end
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L6_2 = RequestAnimDict
  L7_2 = L5_2
  L6_2(L7_2)
  while true do
    L6_2 = HasAnimDictLoaded
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      break
    end
    L6_2 = Wait
    L7_2 = 10
    L6_2(L7_2)
  end
  L6_2 = TaskPlayAnim
  L7_2 = L4_2
  L8_2 = L5_2
  L9_2 = "machinic_loop_mechandplayer"
  L10_2 = 8.0
  L11_2 = -8.0
  L12_2 = -1
  L13_2 = 1
  L14_2 = 0
  L15_2 = false
  L16_2 = false
  L17_2 = false
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L6_2 = false
  L7_2 = type
  L8_2 = PerformSkillCheck
  L7_2 = L7_2(L8_2)
  if "function" == L7_2 then
    L7_2 = PerformSkillCheck
    L8_2 = {}
    L9_2 = "easy"
    L10_2 = "easy"
    L11_2 = "medium"
    L8_2[1] = L9_2
    L8_2[2] = L10_2
    L8_2[3] = L11_2
    L9_2 = {}
    L10_2 = "w"
    L11_2 = "a"
    L12_2 = "s"
    L13_2 = "d"
    L9_2[1] = L10_2
    L9_2[2] = L11_2
    L9_2[3] = L12_2
    L9_2[4] = L13_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L7_2
  else
    L7_2 = Wait
    L8_2 = 5000
    L7_2(L8_2)
    L6_2 = true
  end
  L7_2 = ClearPedTasks
  L8_2 = L4_2
  L7_2(L8_2)
  if not L6_2 then
    L7_2 = Wait
    L8_2 = 500
    L7_2(L8_2)
    L7_2 = GetEntityCoords
    L8_2 = L15_1.prop
    L7_2 = L7_2(L8_2)
    L8_2 = GetEntityHeading
    L9_2 = L15_1.prop
    L8_2 = L8_2(L9_2)
    L9_2 = string
    L9_2 = L9_2.format
    L10_2 = "hoist_pallet_return_%d"
    L11_2 = L15_1.prop
    L9_2 = L9_2(L10_2, L11_2)
    L10_2 = {}
    L11_2 = L7_2.x
    L10_2.x = L11_2
    L11_2 = L7_2.y
    L10_2.y = L11_2
    L11_2 = L7_2.z
    L11_2 = L11_2 + 1.0
    L10_2.z = L11_2
    L10_2.w = L8_2
    L11_2 = CreateEngineHoistInteract
    L12_2 = L9_2
    L13_2 = L10_2
    L14_2 = "Return Engine to Pallet"
    function L15_2()
      local L0_3, L1_3, L2_3, L3_3
      L0_3 = ReturnEngineToPallet
      L1_3 = L9_2
      L2_3 = A1_2
      L3_3 = A2_2
      L0_3(L1_3, L2_3, L3_3)
    end
    L11_2(L12_2, L13_2, L14_2, L15_2)
    return
  end
  L7_2 = TaskPlayAnim
  L8_2 = L4_2
  L9_2 = L5_2
  L10_2 = "machinic_loop_mechandplayer"
  L11_2 = 8.0
  L12_2 = -8.0
  L13_2 = 5000
  L14_2 = 1
  L15_2 = 0
  L16_2 = false
  L17_2 = false
  L18_2 = false
  L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L7_2 = GetEntityCoords
  L8_2 = A1_2
  L7_2 = L7_2(L8_2)
  L8_2 = GetEntityHeading
  L9_2 = A1_2
  L8_2 = L8_2(L9_2)
  L9_2 = L25_1
  L10_2 = L7_2
  L11_2 = L8_2
  L12_2 = vector3
  L13_2 = 0.0
  L14_2 = -0.25
  L15_2 = 0.125
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2 = L12_2(L13_2, L14_2, L15_2)
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L10_2 = L15_1.engineProp
  L11_2 = NetworkGetNetworkIdFromEntity
  L12_2 = L10_2
  L11_2 = L11_2(L12_2)
  L12_2 = GetEntityCoords
  L13_2 = L10_2
  L12_2 = L12_2(L13_2)
  L13_2 = 50
  L14_2 = L9_2.x
  L15_2 = L12_2.x
  L14_2 = L14_2 - L15_2
  L14_2 = L14_2 / L13_2
  L15_2 = L9_2.y
  L16_2 = L12_2.y
  L15_2 = L15_2 - L16_2
  L15_2 = L15_2 / L13_2
  L16_2 = L9_2.z
  L17_2 = L12_2.z
  L16_2 = L16_2 - L17_2
  L16_2 = L16_2 / L13_2
  L17_2 = DetachEntity
  L18_2 = L10_2
  L19_2 = false
  L20_2 = false
  L17_2(L18_2, L19_2, L20_2)
  L17_2 = SetEntityCollision
  L18_2 = L10_2
  L19_2 = false
  L20_2 = false
  L17_2(L18_2, L19_2, L20_2)
  L17_2 = TriggerServerEvent
  L18_2 = "qs-mechanic-creator:server:syncEngineLower"
  L19_2 = L11_2
  L20_2 = L12_2.x
  L21_2 = L12_2.y
  L22_2 = L12_2.z
  L23_2 = L9_2.x
  L24_2 = L9_2.y
  L25_2 = L9_2.z
  L26_2 = L13_2
  L17_2(L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2)
  L17_2 = 1
  L18_2 = L13_2
  L19_2 = 1
  for L20_2 = L17_2, L18_2, L19_2 do
    L21_2 = DoesEntityExist
    L22_2 = L10_2
    L21_2 = L21_2(L22_2)
    if not L21_2 then
      break
    end
    L21_2 = GetEntityCoords
    L22_2 = L10_2
    L21_2 = L21_2(L22_2)
    L22_2 = SetEntityCoords
    L23_2 = L10_2
    L24_2 = L21_2.x
    L24_2 = L24_2 + L14_2
    L25_2 = L21_2.y
    L25_2 = L25_2 + L15_2
    L26_2 = L21_2.z
    L26_2 = L26_2 + L16_2
    L22_2(L23_2, L24_2, L25_2, L26_2)
    L22_2 = Wait
    L23_2 = 50
    L22_2(L23_2)
  end
  L17_2 = Wait
  L18_2 = 500
  L17_2(L18_2)
  L17_2 = NetworkGetNetworkIdFromEntity
  L18_2 = L10_2
  L17_2 = L17_2(L18_2)
  L18_2 = TriggerServerEvent
  L19_2 = "qs-mechanic-creator:server:syncEngineDelete"
  L20_2 = L17_2
  L18_2(L19_2, L20_2)
  L18_2 = DoesEntityExist
  L19_2 = L10_2
  L18_2 = L18_2(L19_2)
  if L18_2 then
    L18_2 = DeleteEntity
    L19_2 = L10_2
    L18_2(L19_2)
  end
  L15_1.engineProp = nil
  L15_1.engineAttached = false
  L15_1.engineFromPallet = false
  L15_1.engineSourceShopId = nil
  L15_1.engineType = nil
  L18_2 = lib
  L18_2 = L18_2.callback
  L18_2 = L18_2.await
  L19_2 = "qs-mechanic-creator:server:returnEngineToPallet"
  L20_2 = false
  L21_2 = A2_2
  L18_2(L19_2, L20_2, L21_2)
  L18_2 = TriggerEvent
  L19_2 = "qs-mechanic-creator:client:palletEngineUpdated"
  L20_2 = A2_2
  L18_2(L19_2, L20_2)
  L18_2 = L5_1
  if not L18_2 then
    L18_2 = {}
  end
  L5_1 = L18_2
  L18_2 = tostring
  L19_2 = L15_1.shopId
  L18_2 = L18_2(L19_2)
  L19_2 = L5_1
  L20_2 = tostring
  L21_2 = L15_1.shopId
  L20_2 = L20_2(L21_2)
  L21_2 = L5_1
  L20_2 = L21_2[L20_2]
  if not L20_2 then
    L20_2 = {}
  end
  L19_2[L18_2] = L20_2
  L18_2 = tostring
  L19_2 = L15_1.shopId
  L18_2 = L18_2(L19_2)
  L19_2 = L5_1
  L18_2 = L19_2[L18_2]
  L19_2 = L15_1.prop
  L18_2.hoist = L19_2
  L18_2 = GetEntityCoords
  L19_2 = L15_1.prop
  L18_2 = L18_2(L19_2)
  L19_2 = GetEntityHeading
  L20_2 = L15_1.prop
  L19_2 = L19_2(L20_2)
  L20_2 = string
  L20_2 = L20_2.format
  L21_2 = "hoist_pickup_%d"
  L22_2 = L15_1.prop
  L20_2 = L20_2(L21_2, L22_2)
  L21_2 = {}
  L22_2 = L18_2.x
  L21_2.x = L22_2
  L22_2 = L18_2.y
  L21_2.y = L22_2
  L22_2 = L18_2.z
  L22_2 = L22_2 + 1.0
  L21_2.z = L22_2
  L21_2.w = L19_2
  L22_2 = CreateEngineHoistInteract
  L23_2 = L20_2
  L24_2 = L21_2
  L25_2 = _U
  L26_2 = "ENGINE_HOIST_USE"
  L25_2 = L25_2(L26_2)
  function L26_2()
    local L0_3, L1_3, L2_3
    L0_3 = RemoveInteract
    L1_3 = L20_2
    L0_3(L1_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:useEngineHoist"
    L2_3 = L15_1.shopId
    L0_3(L1_3, L2_3)
  end
  L22_2(L23_2, L24_2, L25_2, L26_2)
end
ReturnEngineToPallet = L33_1
function L33_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2
  L0_2 = L15_1.attached
  if not L0_2 then
    return
  end
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = L15_1.prop
  L2_2 = L15_1.shopId
  L3_2 = L15_1.engineProp
  L4_2 = L15_1.engineAttached
  L5_2 = ClearPedTasks
  L6_2 = L0_2
  L5_2(L6_2)
  if L1_2 then
    L5_2 = DoesEntityExist
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_25
    end
  end
  L15_1.attached = false
  L15_1.prop = nil
  L15_1.shopId = nil
  do return end
  ::lbl_25::
  L5_2 = DetachEntity
  L6_2 = L1_2
  L7_2 = true
  L8_2 = true
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = GetEntityCoords
  L6_2 = L0_2
  L5_2 = L5_2(L6_2)
  L6_2 = GetEntityHeading
  L7_2 = L0_2
  L6_2 = L6_2(L7_2)
  L7_2 = GetEntityForwardVector
  L8_2 = L0_2
  L7_2 = L7_2(L8_2)
  L8_2 = vector3
  L9_2 = L5_2.x
  L10_2 = L7_2.x
  L10_2 = L10_2 * 1.5
  L9_2 = L9_2 + L10_2
  L10_2 = L5_2.y
  L11_2 = L7_2.y
  L11_2 = L11_2 * 1.5
  L10_2 = L10_2 + L11_2
  L11_2 = L5_2.z
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = SetEntityCoords
  L10_2 = L1_2
  L11_2 = L8_2.x
  L12_2 = L8_2.y
  L13_2 = L8_2.z
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = SetEntityHeading
  L10_2 = L1_2
  L11_2 = L6_2 + 180.0
  L11_2 = L11_2 % 360.0
  L9_2(L10_2, L11_2)
  L9_2 = SetEntityCollision
  L10_2 = L1_2
  L11_2 = true
  L12_2 = true
  L9_2(L10_2, L11_2, L12_2)
  L9_2 = PlaceObjectOnGroundProperly
  L10_2 = L1_2
  L9_2(L10_2)
  L9_2 = SetEntityHeading
  L10_2 = L1_2
  L11_2 = L6_2 + 180.0
  L11_2 = L11_2 % 360.0
  L9_2(L10_2, L11_2)
  L9_2 = SetEntityRotation
  L10_2 = L1_2
  L11_2 = 0.0
  L12_2 = 0.0
  L13_2 = L6_2 + 180.0
  L13_2 = L13_2 % 360.0
  L14_2 = 2
  L15_2 = true
  L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L9_2 = Wait
  L10_2 = 100
  L9_2(L10_2)
  L9_2 = FreezeEntityPosition
  L10_2 = L1_2
  L11_2 = true
  L9_2(L10_2, L11_2)
  L9_2 = NetworkGetNetworkIdFromEntity
  L10_2 = L1_2
  L9_2 = L9_2(L10_2)
  L10_2 = GetEntityCoords
  L11_2 = L1_2
  L10_2 = L10_2(L11_2)
  L11_2 = GetEntityHeading
  L12_2 = L1_2
  L11_2 = L11_2(L12_2)
  L12_2 = nil
  if L4_2 and L3_2 then
    L13_2 = DoesEntityExist
    L14_2 = L3_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L13_2 = NetworkGetNetworkIdFromEntity
      L14_2 = L3_2
      L13_2 = L13_2(L14_2)
      L12_2 = L13_2
      L13_2 = TriggerServerEvent
      L14_2 = "qs-mechanic-creator:server:syncEngineAttach"
      L15_2 = L12_2
      L16_2 = L9_2
      L13_2(L14_2, L15_2, L16_2)
    end
  end
  L13_2 = TriggerServerEvent
  L14_2 = "qs-mechanic-creator:server:syncHoistPlace"
  L15_2 = L9_2
  L16_2 = L10_2.x
  L17_2 = L10_2.y
  L18_2 = L10_2.z
  L19_2 = L11_2
  L20_2 = L2_2
  L21_2 = L12_2
  L13_2(L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2)
  L13_2 = L5_1
  if not L13_2 then
    L13_2 = {}
  end
  L5_1 = L13_2
  L13_2 = tostring
  L14_2 = L2_2
  L13_2 = L13_2(L14_2)
  L14_2 = L5_1
  L15_2 = tostring
  L16_2 = L2_2
  L15_2 = L15_2(L16_2)
  L16_2 = L5_1
  L15_2 = L16_2[L15_2]
  if not L15_2 then
    L15_2 = {}
  end
  L14_2[L13_2] = L15_2
  L13_2 = tostring
  L14_2 = L2_2
  L13_2 = L13_2(L14_2)
  L14_2 = L5_1
  L13_2 = L14_2[L13_2]
  L13_2.hoist = L1_2
  L15_1.shopId = nil
  L15_1.prop = nil
  L15_1.attached = false
  if L1_2 then
    L13_2 = DoesEntityExist
    L14_2 = L1_2
    L13_2 = L13_2(L14_2)
    if L13_2 then
      L13_2 = GetEntityCoords
      L14_2 = L1_2
      L13_2 = L13_2(L14_2)
      L14_2 = GetEntityHeading
      L15_2 = L1_2
      L14_2 = L14_2(L15_2)
      L15_2 = string
      L15_2 = L15_2.format
      L16_2 = "hoist_pickup_%d"
      L17_2 = L1_2
      L15_2 = L15_2(L16_2, L17_2)
      L16_2 = {}
      L17_2 = L13_2.x
      L16_2.x = L17_2
      L17_2 = L13_2.y
      L16_2.y = L17_2
      L17_2 = L13_2.z
      L17_2 = L17_2 + 1.0
      L16_2.z = L17_2
      L16_2.w = L14_2
      L17_2 = CreateEngineHoistInteract
      L18_2 = L15_2
      L19_2 = L16_2
      L20_2 = _U
      L21_2 = "ENGINE_HOIST_USE"
      L20_2 = L20_2(L21_2)
      function L21_2()
        local L0_3, L1_3, L2_3
        L0_3 = RemoveInteract
        L1_3 = L15_2
        L0_3(L1_3)
        L0_3 = L2_2
        L15_1.shopId = L0_3
        L0_3 = TriggerEvent
        L1_3 = "qs-mechanic-creator:client:useEngineHoist"
        L2_3 = L2_2
        L0_3(L1_3, L2_3)
      end
      L17_2(L18_2, L19_2, L20_2, L21_2)
    end
  end
end
DetachHoist = L33_1
