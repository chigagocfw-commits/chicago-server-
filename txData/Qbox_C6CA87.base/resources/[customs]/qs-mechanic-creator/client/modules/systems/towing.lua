local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1
L0_1 = {}
L1_1 = {}
L1_1.ROPE_PROP = "prop_rope_family_3"
L1_1.BROKEN_SPEED = 35.0
L1_1.MAX_SELECTION_DISTANCE = 10.0
L1_1.MAX_TOW_DISTANCE = 20.0
L2_1 = false
L3_1 = true
L4_1 = true
L5_1 = {}
L5_1.isTowing = false
L5_1.isSelectingTowVehicle = false
L5_1.isSelectingTargetVehicle = false
L5_1.firstEntity = nil
L5_1.secondEntity = nil
L5_1.length = 5.0
L6_1 = {}
L5_1.ropeHandle = L6_1
L5_1.ropeProp = nil
L5_1.textUIShown = false
L5_1.controlsShown = false
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = GetGamePool
  L3_2 = "CVehicle"
  L2_2 = L2_2(L3_2)
  L3_2 = nil
  L4_2 = A1_2 or L4_2
  if not A1_2 then
    L4_2 = 10.0
  end
  L5_2 = ipairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    L11_2 = GetEntityCoords
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    L11_2 = A0_2 - L11_2
    L11_2 = #L11_2
    if L4_2 > L11_2 then
      L4_2 = L11_2
      L3_2 = L10_2
    end
  end
  L5_2 = L3_2
  L6_2 = L4_2
  return L5_2, L6_2
end
function L7_1(A0_2)
  local L1_2, L2_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = IsEntityAVehicle
  L2_2 = A0_2
  return L1_2(L2_2)
end
function L8_1(A0_2)
  local L1_2, L2_2
  L1_2 = DoesEntityExist
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = IsEntityAVehicle
  L2_2 = A0_2
  return L1_2(L2_2)
end
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = pairs
  L3_2 = L5_1.ropeHandle
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.netId1
    if L8_2 == A0_2 then
      L8_2 = L7_2.netId2
      if L8_2 == A1_2 then
        return L7_2
      end
    end
  end
  L2_2 = nil
  return L2_2
end
function L10_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L0_2 = L5_1.ropeProp
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L5_1.ropeProp
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = L5_1.ropeProp
      return L0_2
    end
  end
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = lib
  L1_2 = L1_2.requestModel
  L2_2 = L1_1.ROPE_PROP
  L1_2(L2_2)
  L1_2 = GetEntityCoords
  L2_2 = L0_2
  L1_2 = L1_2(L2_2)
  L2_2 = CreateObject
  L3_2 = L1_1.ROPE_PROP
  L4_2 = L1_2.x
  L5_2 = L1_2.y
  L6_2 = L1_2.z
  L7_2 = true
  L8_2 = true
  L9_2 = false
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2)
  L5_1.ropeProp = L2_2
  L2_2 = AttachEntityToEntity
  L3_2 = L5_1.ropeProp
  L4_2 = L0_2
  L5_2 = GetPedBoneIndex
  L6_2 = L0_2
  L7_2 = 57005
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = 0.15
  L7_2 = 0.0
  L8_2 = 0.0
  L9_2 = -90.0
  L10_2 = 0.0
  L11_2 = 0.0
  L12_2 = true
  L13_2 = true
  L14_2 = false
  L15_2 = true
  L16_2 = 1
  L17_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L2_2 = L5_1.ropeProp
  return L2_2
end
function L11_1()
  local L0_2, L1_2
  L0_2 = L5_1.ropeProp
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L5_1.ropeProp
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = DeleteEntity
      L1_2 = L5_1.ropeProp
      L0_2(L1_2)
      L5_1.ropeProp = nil
    end
  end
end
function L12_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = RopeLoadTextures
  L1_2()
  L1_2 = AddRope
  L2_2 = A0_2.x
  L3_2 = A0_2.y
  L4_2 = A0_2.z
  L5_2 = 0.0
  L6_2 = 0.0
  L7_2 = 0.0
  L8_2 = 10.0
  L9_2 = 1
  L10_2 = 10.0
  L11_2 = 0.25
  L12_2 = 0.0
  L13_2 = false
  L14_2 = true
  L15_2 = false
  L16_2 = 5.0
  L17_2 = false
  L18_2 = 0
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  return L1_2
end
function L13_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2
  L3_2 = GetModelDimensions
  L4_2 = GetEntityModel
  L5_2 = A1_2
  L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L4_2(L5_2)
  L3_2, L4_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L5_2 = GetModelDimensions
  L6_2 = GetEntityModel
  L7_2 = A2_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2 = L6_2(L7_2)
  L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L7_2 = GetOffsetFromEntityInWorldCoords
  L8_2 = A1_2
  L9_2 = 0.0
  L10_2 = L3_2.y
  L10_2 = L10_2 - 0.3
  L11_2 = 0.3
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = GetOffsetFromEntityInWorldCoords
  L9_2 = A2_2
  L10_2 = 0.0
  L11_2 = L6_2.y
  L11_2 = L11_2 + 0.3
  L12_2 = 0.3
  L8_2 = L8_2(L9_2, L10_2, L11_2, L12_2)
  L9_2 = L7_2 - L8_2
  L9_2 = #L9_2
  L10_2 = AttachEntitiesToRope
  L11_2 = A0_2
  L12_2 = A1_2
  L13_2 = A2_2
  L14_2 = L7_2.x
  L15_2 = L7_2.y
  L16_2 = L7_2.z
  L17_2 = L8_2.x
  L18_2 = L8_2.y
  L19_2 = L8_2.z
  L20_2 = L9_2
  L21_2 = false
  L22_2 = false
  L23_2 = nil
  L24_2 = nil
  L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2)
  L10_2 = StopRopeUnwindingFront
  L11_2 = A0_2
  L10_2(L11_2)
  L10_2 = StartRopeWinding
  L11_2 = A0_2
  L10_2(L11_2)
  L10_2 = RopeForceLength
  L11_2 = A0_2
  L12_2 = L9_2
  L10_2(L11_2, L12_2)
  return L9_2
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
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
function L15_1(A0_2)
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
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = L5_1.isTowing
  if L1_2 then
    L1_2 = lib
    L1_2 = L1_2.notify
    L2_2 = {}
    L3_2 = _U
    L4_2 = "TOWING_TITLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "TOWING_ALREADY_ACTIVE"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = Config
  L1_2 = L1_2.RadialItemRequirements
  L1_2 = L1_2.enabled
  if L1_2 then
    L1_2 = lib
    L1_2 = L1_2.callback
    L1_2 = L1_2.await
    L2_2 = "qs-mechanic-creator:server:hasItem"
    L3_2 = false
    L4_2 = Config
    L4_2 = L4_2.RadialItemRequirements
    L4_2 = L4_2.items
    L4_2 = L4_2.rope
    L1_2 = L1_2(L2_2, L3_2, L4_2)
    if not L1_2 then
      L2_2 = lib
      L2_2 = L2_2.notify
      L3_2 = {}
      L4_2 = _U
      L5_2 = "MISSING_ITEM"
      L4_2 = L4_2(L5_2)
      L3_2.title = L4_2
      L4_2 = _U
      L5_2 = "MISSING_ITEM_DESC"
      L6_2 = Config
      L6_2 = L6_2.RadialItemRequirements
      L6_2 = L6_2.items
      L6_2 = L6_2.rope
      L4_2 = L4_2(L5_2, L6_2)
      L3_2.description = L4_2
      L3_2.type = "error"
      L2_2(L3_2)
      return
    end
  end
  L1_2 = L10_1
  L1_2()
  L5_1.isSelectingTowVehicle = true
  L1_2 = lib
  L1_2 = L1_2.notify
  L2_2 = {}
  L3_2 = _U
  L4_2 = "TOWING_TITLE"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "TOWING_SELECT_TOW_VEHICLE"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L2_2.duration = 7000
  L1_2(L2_2)
  L2_2 = A0_2
  L1_2 = A0_2.StartVehicleSelectionThread
  L1_2(L2_2)
end
L0_1.StartTowing = L16_1
function L16_1(A0_2)
  local L1_2, L2_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = nil
    while true do
      L1_3 = L5_1.isSelectingTowVehicle
      if not L1_3 then
        L1_3 = L5_1.isSelectingTargetVehicle
        if not L1_3 then
          break
        end
      end
      L1_3 = PlayerPedId
      L1_3 = L1_3()
      L2_3 = GetEntityCoords
      L3_3 = L1_3
      L2_3 = L2_3(L3_3)
      L3_3 = L6_1
      L4_3 = L2_3
      L5_3 = L1_1.MAX_SELECTION_DISTANCE
      L3_3, L4_3 = L3_3(L4_3, L5_3)
      if L3_3 and L3_3 ~= L0_3 then
        if L0_3 then
          L5_3 = L15_1
          L6_3 = L0_3
          L5_3(L6_3)
        end
        L5_3 = L14_1
        L6_3 = L3_3
        L5_3(L6_3)
        L0_3 = L3_3
      elseif not L3_3 and L0_3 then
        L5_3 = L15_1
        L6_3 = L0_3
        L5_3(L6_3)
        L0_3 = nil
      end
      if L3_3 then
        L5_3 = L5_1.textUIShown
        if not L5_3 then
          L5_3 = lib
          L5_3 = L5_3.showTextUI
          L6_3 = _U
          L7_3 = "TOWING_PRESS_TO_SELECT"
          L6_3 = L6_3(L7_3)
          L7_3 = {}
          L8_3 = Config
          L8_3 = L8_3.TextPosition
          L7_3.position = L8_3
          L7_3.icon = "hand-pointer"
          L8_3 = {}
          L8_3.borderRadius = 5
          L8_3.backgroundColor = "rgba(0, 0, 0, 0.8)"
          L8_3.color = "white"
          L7_3.style = L8_3
          L5_3(L6_3, L7_3)
          L5_1.textUIShown = true
        end
        L5_3 = IsControlJustPressed
        L6_3 = 0
        L7_3 = 38
        L5_3 = L5_3(L6_3, L7_3)
        if L5_3 then
          L5_3 = L5_1.isSelectingTowVehicle
          if L5_3 then
            L5_3 = A0_2
            L6_3 = L5_3
            L5_3 = L5_3.SelectTowVehicle
            L7_3 = L3_3
            L5_3(L6_3, L7_3)
          else
            L5_3 = L5_1.isSelectingTargetVehicle
            if L5_3 then
              L5_3 = A0_2
              L6_3 = L5_3
              L5_3 = L5_3.SelectTargetVehicle
              L7_3 = L3_3
              L5_3(L6_3, L7_3)
            end
          end
          if L0_3 then
            L5_3 = L15_1
            L6_3 = L0_3
            L5_3(L6_3)
          end
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
        L5_3 = A0_2
        L6_3 = L5_3
        L5_3 = L5_3.CancelTowing
        L5_3(L6_3)
        if L0_3 then
          L5_3 = L15_1
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
        break
      end
      L5_3 = Wait
      L6_3 = 0
      L5_3(L6_3)
    end
    L1_3 = L5_1.textUIShown
    if L1_3 then
      L1_3 = lib
      L1_3 = L1_3.hideTextUI
      L1_3()
      L5_1.textUIShown = false
    end
  end
  L1_2(L2_2)
end
L0_1.StartVehicleSelectionThread = L16_1
function L16_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L7_1
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = lib
    L2_2 = L2_2.notify
    L3_2 = {}
    L4_2 = _U
    L5_2 = "TOWING_TITLE"
    L4_2 = L4_2(L5_2)
    L3_2.title = L4_2
    L4_2 = _U
    L5_2 = "TOWING_NOT_ALLOWED"
    L4_2 = L4_2(L5_2)
    L3_2.description = L4_2
    L3_2.type = "error"
    L2_2(L3_2)
    return
  end
  L2_2 = GetLabelText
  L3_2 = GetDisplayNameFromVehicleModel
  L4_2 = GetEntityModel
  L5_2 = A1_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = NetworkGetEntityIsNetworked
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = NetworkGetNetworkIdFromEntity
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L5_1.firstEntity = L3_2
  else
    L3_2 = NetworkRegisterEntityAsNetworked
    L4_2 = A1_2
    L3_2(L4_2)
    L3_2 = Wait
    L4_2 = 100
    L3_2(L4_2)
    L3_2 = NetworkGetNetworkIdFromEntity
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    L5_1.firstEntity = L3_2
  end
  L5_1.isSelectingTowVehicle = false
  L5_1.isSelectingTargetVehicle = true
  L3_2 = lib
  L3_2 = L3_2.notify
  L4_2 = {}
  L5_2 = _U
  L6_2 = "TOWING_TITLE"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = _U
  L6_2 = "TOWING_TOW_VEHICLE_SET"
  L7_2 = L2_2
  L5_2 = L5_2(L6_2, L7_2)
  L4_2.description = L5_2
  L4_2.type = "success"
  L4_2.duration = 5000
  L3_2(L4_2)
  L3_2 = lib
  L3_2 = L3_2.notify
  L4_2 = {}
  L5_2 = _U
  L6_2 = "TOWING_TITLE"
  L5_2 = L5_2(L6_2)
  L4_2.title = L5_2
  L5_2 = _U
  L6_2 = "TOWING_SELECT_TARGET_VEHICLE"
  L5_2 = L5_2(L6_2)
  L4_2.description = L5_2
  L4_2.type = "info"
  L4_2.duration = 7000
  L3_2(L4_2)
end
L0_1.SelectTowVehicle = L16_1
function L16_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = L5_1.firstEntity
  L2_2 = L2_2(L3_2)
  if A1_2 == L2_2 then
    L3_2 = lib
    L3_2 = L3_2.notify
    L4_2 = {}
    L5_2 = _U
    L6_2 = "TOWING_TITLE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "TOWING_SAME_VEHICLE"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
    return
  end
  L3_2 = L8_1
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = lib
    L3_2 = L3_2.notify
    L4_2 = {}
    L5_2 = _U
    L6_2 = "TOWING_TITLE"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "TOWING_NOT_ALLOWED"
    L5_2 = L5_2(L6_2)
    L4_2.description = L5_2
    L4_2.type = "error"
    L3_2(L4_2)
    return
  end
  L3_2 = GetEntityCoords
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = GetEntityCoords
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  L3_2 = L3_2 - L4_2
  L3_2 = #L3_2
  L4_2 = L1_1.MAX_TOW_DISTANCE
  if L3_2 > L4_2 then
    L4_2 = lib
    L4_2 = L4_2.notify
    L5_2 = {}
    L6_2 = _U
    L7_2 = "TOWING_TITLE"
    L6_2 = L6_2(L7_2)
    L5_2.title = L6_2
    L6_2 = _U
    L7_2 = "TOWING_TOO_FAR"
    L6_2 = L6_2(L7_2)
    L5_2.description = L6_2
    L5_2.type = "error"
    L4_2(L5_2)
    return
  end
  L4_2 = GetLabelText
  L5_2 = GetDisplayNameFromVehicleModel
  L6_2 = GetEntityModel
  L7_2 = A1_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L6_2(L7_2)
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L5_2 = NetworkGetEntityIsNetworked
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if L5_2 then
    L5_2 = NetworkGetNetworkIdFromEntity
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    L5_1.secondEntity = L5_2
  else
    L5_2 = NetworkRegisterEntityAsNetworked
    L6_2 = A1_2
    L5_2(L6_2)
    L5_2 = Wait
    L6_2 = 100
    L5_2(L6_2)
    L5_2 = NetworkGetNetworkIdFromEntity
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    L5_1.secondEntity = L5_2
  end
  L5_1.isSelectingTargetVehicle = false
  L5_1.isTowing = true
  L5_2 = Config
  L5_2 = L5_2.RadialItemRequirements
  L5_2 = L5_2.enabled
  if L5_2 then
    L5_2 = Config
    L5_2 = L5_2.RadialItemRequirements
    L5_2 = L5_2.consumeItems
    if L5_2 then
      L5_2 = TriggerServerEvent
      L6_2 = "qs-mechanic-creator:server:removeItem"
      L7_2 = Config
      L7_2 = L7_2.RadialItemRequirements
      L7_2 = L7_2.items
      L7_2 = L7_2.rope
      L8_2 = 1
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  L5_2 = L11_1
  L5_2()
  L5_2 = GetModelDimensions
  L6_2 = GetEntityModel
  L7_2 = L2_2
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L6_2(L7_2)
  L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L7_2 = GetModelDimensions
  L8_2 = GetEntityModel
  L9_2 = A1_2
  L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L8_2(L9_2)
  L7_2, L8_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L9_2 = GetOffsetFromEntityInWorldCoords
  L10_2 = L2_2
  L11_2 = 0.0
  L12_2 = L5_2.y
  L12_2 = L12_2 - 0.3
  L13_2 = 0.3
  L9_2 = L9_2(L10_2, L11_2, L12_2, L13_2)
  L10_2 = GetOffsetFromEntityInWorldCoords
  L11_2 = A1_2
  L12_2 = 0.0
  L13_2 = L8_2.y
  L13_2 = L13_2 + 0.3
  L14_2 = 0.3
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2)
  L11_2 = L9_2 - L10_2
  L11_2 = #L11_2
  L5_1.length = L11_2
  L11_2 = GetDisplayNameFromVehicleModel
  L12_2 = GetEntityModel
  L13_2 = L2_2
  L12_2, L13_2, L14_2, L15_2, L16_2, L17_2 = L12_2(L13_2)
  L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
  L12_2 = GetDisplayNameFromVehicleModel
  L13_2 = GetEntityModel
  L14_2 = A1_2
  L13_2, L14_2, L15_2, L16_2, L17_2 = L13_2(L14_2)
  L12_2 = L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  L13_2 = TriggerServerEvent
  L14_2 = "qs-mechanic-creator:server:logTowingStarted"
  L15_2 = L11_2
  L16_2 = L12_2
  L13_2(L14_2, L15_2, L16_2)
  L13_2 = lib
  L13_2 = L13_2.notify
  L14_2 = {}
  L15_2 = _U
  L16_2 = "TOWING_TITLE"
  L15_2 = L15_2(L16_2)
  L14_2.title = L15_2
  L15_2 = _U
  L16_2 = "TOWING_COMPLETE"
  L17_2 = L4_2
  L15_2 = L15_2(L16_2, L17_2)
  L14_2.description = L15_2
  L14_2.type = "success"
  L14_2.duration = 5000
  L13_2(L14_2)
  L13_2 = TriggerServerEvent
  L14_2 = "qs-mechanic:server:CreateRope"
  L15_2 = L5_1.firstEntity
  L16_2 = L5_1.secondEntity
  L13_2(L14_2, L15_2, L16_2)
  L13_2 = TriggerServerEvent
  L14_2 = "qs-mechanic:server:UpdateRopeLength"
  L15_2 = L5_1.firstEntity
  L16_2 = L5_1.secondEntity
  L17_2 = L5_1.length
  L13_2(L14_2, L15_2, L16_2, L17_2)
end
L0_1.SelectTargetVehicle = L16_1
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L5_1.isSelectingTowVehicle = false
  L5_1.isSelectingTargetVehicle = false
  L5_1.firstEntity = nil
  L5_1.secondEntity = nil
  L5_1.controlsShown = false
  L1_2 = L11_1
  L1_2()
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:logTowingCancelled"
  L1_2(L2_2)
  L1_2 = lib
  L1_2 = L1_2.notify
  L2_2 = {}
  L3_2 = _U
  L4_2 = "TOWING_TITLE"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "TOWING_CANCELLED"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "info"
  L1_2(L2_2)
end
L0_1.CancelTowing = L16_1
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L5_1.isTowing
  if not L1_2 then
    L1_2 = lib
    L1_2 = L1_2.notify
    L2_2 = {}
    L3_2 = _U
    L4_2 = "TOWING_TITLE"
    L3_2 = L3_2(L4_2)
    L2_2.title = L3_2
    L3_2 = _U
    L4_2 = "TOWING_NOT_ACTIVE"
    L3_2 = L3_2(L4_2)
    L2_2.description = L3_2
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic:server:RemoveRope"
  L3_2 = L5_1.firstEntity
  L4_2 = L5_1.secondEntity
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = TriggerServerEvent
  L2_2 = "qs-mechanic-creator:server:logRopeDetached"
  L1_2(L2_2)
  L5_1.isTowing = false
  L5_1.firstEntity = nil
  L5_1.secondEntity = nil
  L5_1.controlsShown = false
  L1_2 = lib
  L1_2 = L1_2.notify
  L2_2 = {}
  L3_2 = _U
  L4_2 = "TOWING_TITLE"
  L3_2 = L3_2(L4_2)
  L2_2.title = L3_2
  L3_2 = _U
  L4_2 = "TOWING_REMOVED"
  L3_2 = L3_2(L4_2)
  L2_2.description = L3_2
  L2_2.type = "success"
  L1_2(L2_2)
end
L0_1.StopTowing = L16_1
L16_1 = RegisterNetEvent
L17_1 = "qs-mechanic:client:CreateRope"
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = NetworkDoesNetworkIdExist
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = NetworkDoesNetworkIdExist
    L3_2 = A1_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_12
    end
  end
  do return end
  ::lbl_12::
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L3_2 = NetworkGetEntityFromNetworkId
  L4_2 = A1_2
  L3_2 = L3_2(L4_2)
  L4_2 = DoesEntityExist
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = DoesEntityExist
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_29
    end
  end
  do return end
  ::lbl_29::
  L4_2 = L7_1
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = L8_1
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_40
    end
  end
  do return end
  ::lbl_40::
  L4_2 = GetEntityCoords
  L5_2 = L2_2
  L4_2 = L4_2(L5_2)
  L5_2 = L12_1
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = L13_1
  L7_2 = L5_2
  L8_2 = L2_2
  L9_2 = L3_2
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L7_2 = table
  L7_2 = L7_2.insert
  L8_2 = L5_1.ropeHandle
  L9_2 = {}
  L9_2.id = L5_2
  L9_2.netId1 = A0_2
  L9_2.netId2 = A1_2
  L9_2.length = L6_2
  L10_2 = L5_1.ropeHandle
  L10_2 = #L10_2
  L10_2 = L10_2 + 1
  L9_2.index = L10_2
  L7_2(L8_2, L9_2)
end
L16_1(L17_1, L18_1)
L16_1 = RegisterNetEvent
L17_1 = "qs-mechanic:client:RemoveRope"
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = L9_1
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    return
  end
  L3_2 = NetworkDoesNetworkIdExist
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = NetworkDoesNetworkIdExist
    L4_2 = A1_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = NetworkGetEntityFromNetworkId
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      L4_2 = NetworkGetEntityFromNetworkId
      L5_2 = A1_2
      L4_2 = L4_2(L5_2)
      L5_2 = DoesRopeExist
      L6_2 = L2_2.id
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L5_2 = StopRopeUnwindingFront
        L6_2 = L2_2.id
        L5_2(L6_2)
        L5_2 = StopRopeWinding
        L6_2 = L2_2.id
        L5_2(L6_2)
        L5_2 = DoesEntityExist
        L6_2 = L3_2
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L5_2 = DetachRopeFromEntity
          L6_2 = L2_2.id
          L7_2 = L3_2
          L5_2(L6_2, L7_2)
        end
        L5_2 = DoesEntityExist
        L6_2 = L4_2
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L5_2 = DetachRopeFromEntity
          L6_2 = L2_2.id
          L7_2 = L4_2
          L5_2(L6_2, L7_2)
        end
        L5_2 = DeleteRope
        L6_2 = L2_2.id
        L5_2(L6_2)
        L5_2 = RopeUnloadTextures
        L5_2()
      end
    end
  end
  L3_2 = table
  L3_2 = L3_2.remove
  L4_2 = L5_1.ropeHandle
  L5_2 = L2_2.index
  L3_2(L4_2, L5_2)
  L3_2 = ipairs
  L4_2 = L5_1.ropeHandle
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L8_2.index = L7_2
  end
  L3_2 = L5_1.firstEntity
  if L3_2 == A0_2 then
    L3_2 = L5_1.secondEntity
    if L3_2 == A1_2 then
      L5_1.firstEntity = nil
      L5_1.secondEntity = nil
      L5_1.isTowing = false
    end
  end
end
L16_1(L17_1, L18_1)
L16_1 = RegisterNetEvent
L17_1 = "qs-mechanic:client:LoadRopes"
function L18_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = pairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L9_1
    L8_2 = L6_2.netId1
    L9_2 = L6_2.netId2
    L7_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L7_2 = TriggerEvent
      L8_2 = "qs-mechanic:client:CreateRope"
      L9_2 = L6_2.netId1
      L10_2 = L6_2.netId2
      L7_2(L8_2, L9_2, L10_2)
    end
  end
end
L16_1(L17_1, L18_1)
L16_1 = RegisterNetEvent
L17_1 = "qs-mechanic:client:UpdateRopeLength"
function L18_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = L9_1
  L4_2 = A0_2
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  if L3_2 then
    L3_2.length = A2_2
    L4_2 = DoesRopeExist
    L5_2 = L3_2.id
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = RopeForceLength
      L5_2 = L3_2.id
      L6_2 = A2_2
      L4_2(L5_2, L6_2)
    end
  end
end
L16_1(L17_1, L18_1)
L16_1 = CreateThread
function L17_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  while true do
    L0_2 = NetworkIsPlayerActive
    L1_2 = PlayerId
    L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L1_2()
    L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = Wait
  L1_2 = 5000
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "qs-mechanic:server:LoadRopes"
  L0_2(L1_2)
  while true do
    L0_2 = L3_1
    if not L0_2 then
      break
    end
    L0_2 = L5_1.isTowing
    if L0_2 then
      L0_2 = NetworkDoesNetworkIdExist
      L1_2 = L5_1.firstEntity
      L0_2 = L0_2(L1_2)
      if L0_2 then
        L0_2 = NetworkDoesNetworkIdExist
        L1_2 = L5_1.secondEntity
        L0_2 = L0_2(L1_2)
        if L0_2 then
          goto lbl_47
        end
      end
      L5_1.isTowing = false
      L0_2 = false
      L2_1 = L0_2
      L0_2 = L5_1.controlsShown
      if L0_2 then
        L0_2 = lib
        L0_2 = L0_2.hideTextUI
        L0_2()
        L5_1.controlsShown = false
      end
      L0_2 = Wait
      L1_2 = 1000
      L0_2(L1_2)
      goto lbl_354
      ::lbl_47::
      L0_2 = NetworkGetEntityFromNetworkId
      L1_2 = L5_1.firstEntity
      L0_2 = L0_2(L1_2)
      L1_2 = NetworkGetEntityFromNetworkId
      L2_2 = L5_1.secondEntity
      L1_2 = L1_2(L2_2)
      L2_2 = L9_1
      L3_2 = L5_1.firstEntity
      L4_2 = L5_1.secondEntity
      L2_2 = L2_2(L3_2, L4_2)
      L3_2 = DoesEntityExist
      L4_2 = L0_2
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L3_2 = DoesEntityExist
        L4_2 = L1_2
        L3_2 = L3_2(L4_2)
        if L3_2 then
          L3_2 = GetEntityCoords
          L4_2 = L0_2
          L3_2 = L3_2(L4_2)
          L4_2 = GetEntityCoords
          L5_2 = L1_2
          L4_2 = L4_2(L5_2)
          L3_2 = L3_2 - L4_2
          L3_2 = #L3_2
          if L3_2 > 20.0 then
            L4_2 = lib
            L4_2 = L4_2.notify
            L5_2 = {}
            L6_2 = _U
            L7_2 = "TOWING_TITLE"
            L6_2 = L6_2(L7_2)
            L5_2.title = L6_2
            L6_2 = _U
            L7_2 = "TOWING_ROPE_BROKEN"
            L6_2 = L6_2(L7_2)
            L5_2.description = L6_2
            L5_2.type = "error"
            L4_2(L5_2)
            L4_2 = TriggerServerEvent
            L5_2 = "qs-mechanic:server:RemoveRope"
            L6_2 = L5_1.firstEntity
            L7_2 = L5_1.secondEntity
            L4_2(L5_2, L6_2, L7_2)
            L4_2 = TriggerServerEvent
            L5_2 = "qs-mechanic-creator:server:logRopeBroken"
            L6_2 = "Distance exceeded"
            L4_2(L5_2, L6_2)
            L5_1.isTowing = false
            L4_2 = false
            L2_1 = L4_2
            L4_2 = controlsShown
            if L4_2 then
              L4_2 = lib
              L4_2 = L4_2.hideTextUI
              L4_2()
              controlsShown = false
            end
          else
            L4_2 = GetEntitySpeed
            L5_2 = L0_2
            L4_2 = L4_2(L5_2)
            L5_2 = L1_1.BROKEN_SPEED
            if L4_2 > L5_2 then
              L4_2 = lib
              L4_2 = L4_2.notify
              L5_2 = {}
              L6_2 = _U
              L7_2 = "TOWING_TITLE"
              L6_2 = L6_2(L7_2)
              L5_2.title = L6_2
              L6_2 = _U
              L7_2 = "TOWING_TOO_FAST"
              L6_2 = L6_2(L7_2)
              L5_2.description = L6_2
              L5_2.type = "error"
              L4_2(L5_2)
              L4_2 = TriggerServerEvent
              L5_2 = "qs-mechanic:server:RemoveRope"
              L6_2 = L5_1.firstEntity
              L7_2 = L5_1.secondEntity
              L4_2(L5_2, L6_2, L7_2)
              L4_2 = TriggerServerEvent
              L5_2 = "qs-mechanic-creator:server:logRopeBroken"
              L6_2 = "Speed exceeded"
              L4_2(L5_2, L6_2)
              L5_1.isTowing = false
              L4_2 = false
              L2_1 = L4_2
              L4_2 = controlsShown
              if L4_2 then
                L4_2 = lib
                L4_2 = L4_2.hideTextUI
                L4_2()
                controlsShown = false
              end
            else
              L4_2 = SetVehicleHandbrake
              L5_2 = L1_2
              L6_2 = false
              L4_2(L5_2, L6_2)
              if L2_2 then
                L4_2 = DoesRopeExist
                L5_2 = L2_2.id
                L4_2 = L4_2(L5_2)
                if L4_2 then
                  L4_2 = StopRopeUnwindingFront
                  L5_2 = L2_2.id
                  L4_2(L5_2)
                  L4_2 = StopRopeWinding
                  L5_2 = L2_2.id
                  L4_2(L5_2)
                  L4_2 = RopeConvertToSimple
                  L5_2 = L2_2.id
                  L4_2(L5_2)
                  L4_2 = RopeForceLength
                  L5_2 = L2_2.id
                  L6_2 = L5_1.length
                  L4_2(L5_2, L6_2)
                end
              end
              L4_2 = PlayerPedId
              L4_2 = L4_2()
              L5_2 = GetVehiclePedIsIn
              L6_2 = L4_2
              L7_2 = false
              L5_2 = L5_2(L6_2, L7_2)
              L6_2 = L5_1.controlsShown
              if not L6_2 and (L5_2 == L0_2 or 0 == L5_2) then
                L6_2 = lib
                L6_2 = L6_2.showTextUI
                L7_2 = _U
                L8_2 = "TOWING_CONTROLS"
                L7_2 = L7_2(L8_2)
                L8_2 = {}
                L9_2 = Config
                L9_2 = L9_2.TextPosition
                L8_2.position = L9_2
                L8_2.icon = "link"
                L9_2 = {}
                L9_2.borderRadius = 5
                L9_2.backgroundColor = "rgba(0, 0, 0, 0.8)"
                L9_2.color = "white"
                L8_2.style = L9_2
                L6_2(L7_2, L8_2)
                L5_1.controlsShown = true
              else
                L6_2 = L5_1.controlsShown
                if L6_2 and L5_2 ~= L0_2 and 0 ~= L5_2 then
                  L6_2 = lib
                  L6_2 = L6_2.hideTextUI
                  L6_2()
                  L5_1.controlsShown = false
                end
              end
              L6_2 = IsControlJustPressed
              L7_2 = 0
              L8_2 = 194
              L6_2 = L6_2(L7_2, L8_2)
              if L6_2 then
                L6_2 = TriggerServerEvent
                L7_2 = "qs-mechanic:server:RemoveRope"
                L8_2 = L5_1.firstEntity
                L9_2 = L5_1.secondEntity
                L6_2(L7_2, L8_2, L9_2)
                L6_2 = TriggerServerEvent
                L7_2 = "qs-mechanic-creator:server:logRopeDetached"
                L6_2(L7_2)
                L5_1.isTowing = false
                L6_2 = L5_1.controlsShown
                if L6_2 then
                  L6_2 = lib
                  L6_2 = L6_2.hideTextUI
                  L6_2()
                  L5_1.controlsShown = false
                end
                L6_2 = lib
                L6_2 = L6_2.notify
                L7_2 = {}
                L8_2 = _U
                L9_2 = "TOWING_TITLE"
                L8_2 = L8_2(L9_2)
                L7_2.title = L8_2
                L8_2 = _U
                L9_2 = "TOWING_REMOVED"
                L8_2 = L8_2(L9_2)
                L7_2.description = L8_2
                L7_2.type = "success"
                L7_2.duration = 5000
                L6_2(L7_2)
              end
            end
          end
      end
      else
        L3_2 = TriggerServerEvent
        L4_2 = "qs-mechanic:server:RemoveRope"
        L5_2 = L5_1.firstEntity
        L6_2 = L5_1.secondEntity
        L3_2(L4_2, L5_2, L6_2)
        L5_1.isTowing = false
        L3_2 = L5_1.controlsShown
        if L3_2 then
          L3_2 = lib
          L3_2 = L3_2.hideTextUI
          L3_2()
          L5_1.controlsShown = false
        end
      end
    else
      L0_2 = L5_1.controlsShown
      if L0_2 then
        L0_2 = lib
        L0_2 = L0_2.hideTextUI
        L0_2()
        L5_1.controlsShown = false
      end
    end
    L0_2 = L5_1.firstEntity
    if L0_2 then
      L0_2 = L5_1.secondEntity
      if not L0_2 then
        L0_2 = L5_1.isSelectingTargetVehicle
        if not L0_2 then
          L5_1.firstEntity = nil
        end
      end
    end
    L0_2 = L5_1.ropeHandle
    if L0_2 then
      L0_2 = pairs
      L1_2 = L5_1.ropeHandle
      L0_2, L1_2, L2_2, L3_2 = L0_2(L1_2)
      for L4_2, L5_2 in L0_2, L1_2, L2_2, L3_2 do
        L6_2 = NetworkDoesNetworkIdExist
        L7_2 = L5_2.netId1
        L6_2 = L6_2(L7_2)
        if L6_2 then
          L6_2 = NetworkDoesNetworkIdExist
          L7_2 = L5_2.netId2
          L6_2 = L6_2(L7_2)
          if L6_2 then
            L6_2 = NetworkGetEntityFromNetworkId
            L7_2 = L5_2.netId1
            L6_2 = L6_2(L7_2)
            L7_2 = NetworkGetEntityFromNetworkId
            L8_2 = L5_2.netId2
            L7_2 = L7_2(L8_2)
            L8_2 = DoesEntityExist
            L9_2 = L6_2
            L8_2 = L8_2(L9_2)
            if L8_2 then
              L8_2 = DoesEntityExist
              L9_2 = L7_2
              L8_2 = L8_2(L9_2)
              if L8_2 then
                L8_2 = L5_1.firstEntity
                L9_2 = L5_2.netId1
                if L8_2 == L9_2 then
                  L8_2 = L5_1.secondEntity
                  L9_2 = L5_2.netId2
                  if L8_2 == L9_2 then
                    goto lbl_351
                  end
                end
                L8_2 = L5_2.length
                if L8_2 then
                  L8_2 = DoesRopeExist
                  L9_2 = L5_2.id
                  L8_2 = L8_2(L9_2)
                  if L8_2 then
                    L8_2 = StopRopeUnwindingFront
                    L9_2 = L5_2.id
                    L8_2(L9_2)
                    L8_2 = StopRopeWinding
                    L9_2 = L5_2.id
                    L8_2(L9_2)
                    L8_2 = RopeConvertToSimple
                    L9_2 = L5_2.id
                    L8_2(L9_2)
                    L8_2 = RopeForceLength
                    L9_2 = L5_2.id
                    L10_2 = L5_2.length
                    L8_2(L9_2, L10_2)
                  end
                end
              end
            end
          end
        end
        ::lbl_351::
      end
    end
    ::lbl_354::
    L0_2 = Wait
    L1_2 = L5_1.isTowing
    if L1_2 then
      L1_2 = 100
      if L1_2 then
        goto lbl_362
      end
    end
    L1_2 = 10000
    ::lbl_362::
    L0_2(L1_2)
  end
end
L16_1(L17_1)
L16_1 = CreateThread
function L17_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  while true do
    L0_2 = L4_1
    if not L0_2 then
      break
    end
    L0_2 = L2_1
    if L0_2 then
      L0_2 = L5_1.ropeHandle
      if L0_2 then
        L0_2 = next
        L1_2 = L5_1.ropeHandle
        L0_2 = L0_2(L1_2)
        if L0_2 then
          goto lbl_19
        end
      end
    end
    L0_2 = Wait
    L1_2 = 10000
    L0_2(L1_2)
    goto lbl_110
    ::lbl_19::
    L0_2 = Wait
    L1_2 = 500
    L0_2(L1_2)
    L0_2 = {}
    L1_2 = pairs
    L2_2 = L5_1.ropeHandle
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = NetworkDoesNetworkIdExist
      L8_2 = L6_2.netId1
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = NetworkDoesNetworkIdExist
        L8_2 = L6_2.netId2
        L7_2 = L7_2(L8_2)
        if L7_2 then
          L7_2 = NetworkGetEntityFromNetworkId
          L8_2 = L6_2.netId1
          L7_2 = L7_2(L8_2)
          L8_2 = NetworkGetEntityFromNetworkId
          L9_2 = L6_2.netId2
          L8_2 = L8_2(L9_2)
          L9_2 = DoesEntityExist
          L10_2 = L7_2
          L9_2 = L9_2(L10_2)
          if L9_2 then
            L9_2 = DoesEntityExist
            L10_2 = L8_2
            L9_2 = L9_2(L10_2)
            if L9_2 then
              L9_2 = L5_1.firstEntity
              L10_2 = L6_2.netId1
              if L9_2 == L10_2 then
                L9_2 = L5_1.secondEntity
                L10_2 = L6_2.netId2
                if L9_2 == L10_2 then
                  goto lbl_83
                end
              end
              L9_2 = L6_2.length
              if L9_2 then
                L9_2 = DoesRopeExist
                L10_2 = L6_2.id
                L9_2 = L9_2(L10_2)
                if L9_2 then
                  L9_2 = StopRopeUnwindingFront
                  L10_2 = L6_2.id
                  L9_2(L10_2)
                  L9_2 = StopRopeWinding
                  L10_2 = L6_2.id
                  L9_2(L10_2)
                  L9_2 = RopeConvertToSimple
                  L10_2 = L6_2.id
                  L9_2(L10_2)
                  L9_2 = RopeForceLength
                  L10_2 = L6_2.id
                  L11_2 = L6_2.length
                  L9_2(L10_2, L11_2)
                end
              end
              ::lbl_83::
              L9_2 = table
              L9_2 = L9_2.insert
              L10_2 = L0_2
              L11_2 = L6_2
              L9_2(L10_2, L11_2)
          end
          else
            L9_2 = DoesRopeExist
            L10_2 = L6_2.id
            L9_2 = L9_2(L10_2)
            if L9_2 then
              L9_2 = DeleteRope
              L10_2 = L6_2.id
              L9_2(L10_2)
            end
          end
      end
      else
        L7_2 = DoesRopeExist
        L8_2 = L6_2.id
        L7_2 = L7_2(L8_2)
        if L7_2 then
          L7_2 = DeleteRope
          L8_2 = L6_2.id
          L7_2(L8_2)
        end
      end
    end
    L5_1.ropeHandle = L0_2
    ::lbl_110::
  end
end
L16_1(L17_1)
function L16_1()
  local L0_2, L1_2
  L0_2 = L0_1
  L1_2 = L0_2
  L0_2 = L0_2.StartTowing
  L0_2(L1_2)
end
StartTowing = L16_1
function L16_1()
  local L0_2, L1_2
  L0_2 = L0_1
  L1_2 = L0_2
  L0_2 = L0_2.StopTowing
  L0_2(L1_2)
end
StopTowing = L16_1
