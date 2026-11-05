local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = {}
L0_1.fInitialDriveForce = true
L0_1.fInitialDriveMaxFlatVel = true
L0_1.fDriveInertia = true
L0_1.fInitialDragCoeff = true
L0_1.fTractionCurveMax = true
L0_1.fTractionCurveMin = true
L0_1.fTractionCurveLateral = true
L0_1.fLowSpeedTractionLossMult = true
L0_1.fBrakeForce = true
L0_1.fDriveBiasFront = true
L0_1.fDownforceModifier = true
L0_1.fClutchChangeRateScaleUpShift = true
L0_1.fClutchChangeRateScaleDownShift = true
L0_1.fHandBrakeForce = true
L0_1.fSteeringLock = true
L0_1.fTractionBiasFront = true
L0_1.fTractionLossMult = true
L0_1.fSuspensionForce = true
L0_1.fSuspensionRaise = true
L0_1.fPetrolTankVolume = true
L0_1.fOilVolume = true
L0_1.fMass = true
L1_1 = {}
L1_1.nInitialDriveGears = true
L1_1.nMonetaryValue = true
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  if A0_2 then
    L2_2 = DoesEntityExist
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 and A1_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = pairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = type
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    if "number" == L8_2 then
      L8_2 = L0_1
      L8_2 = L8_2[L6_2]
      if L8_2 then
        L8_2 = SetVehicleHandlingFloat
        L9_2 = A0_2
        L10_2 = "CHandlingData"
        L11_2 = L6_2
        L12_2 = L7_2 + 0.0
        L8_2(L9_2, L10_2, L11_2, L12_2)
      else
        L8_2 = L1_1
        L8_2 = L8_2[L6_2]
        if L8_2 then
          L8_2 = SetVehicleHandlingInt
          L9_2 = A0_2
          L10_2 = "CHandlingData"
          L11_2 = L6_2
          L12_2 = math
          L12_2 = L12_2.floor
          L13_2 = L7_2
          L12_2, L13_2 = L12_2(L13_2)
          L8_2(L9_2, L10_2, L11_2, L12_2, L13_2)
        end
      end
    end
  end
  L2_2 = TriggerEvent
  L3_2 = "qs-mechanic-creator:client:engineHandlingApplied"
  L4_2 = A0_2
  L5_2 = A1_2
  L2_2(L3_2, L4_2, L5_2)
end
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  if A0_2 then
    L2_2 = DoesEntityExist
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 and A1_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L2_2 = type
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 or "" == A1_2 then
    return
  end
  L2_2 = ForceUseAudioGameObject
  L3_2 = A0_2
  L4_2 = A1_2
  L2_2(L3_2, L4_2)
end
L4_1 = lib
L4_1 = L4_1.onCache
L5_1 = "vehicle"
function L6_1(A0_2)
  local L1_2, L2_2
  if not A0_2 then
    return
  end
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = Wait
    L1_3 = 300
    L0_3(L1_3)
    L0_3 = A0_2
    if L0_3 then
      L0_3 = DoesEntityExist
      L1_3 = A0_2
      L0_3 = L0_3(L1_3)
      if L0_3 then
        goto lbl_13
      end
    end
    do return end
    ::lbl_13::
    L0_3 = cache
    L0_3 = L0_3.seat
    if -1 ~= L0_3 then
      L0_3 = Entity
      L1_3 = A0_2
      L0_3 = L0_3(L1_3)
      L0_3 = L0_3.state
      L1_3 = L0_3 or L1_3
      if L0_3 then
        L1_3 = L0_3.engineConfig
      end
      if L1_3 then
        L2_3 = type
        L3_3 = L1_3
        L2_3 = L2_3(L3_3)
        if "table" == L2_3 then
          L2_3 = L1_3.sound
          if L2_3 then
            L2_3 = L1_3.sound
            if "" ~= L2_3 then
              L2_3 = L3_1
              L3_3 = A0_2
              L4_3 = L1_3.sound
              L2_3(L3_3, L4_3)
            end
          end
          L2_3 = L1_3.mods
          if L2_3 then
            L2_3 = L2_1
            L3_3 = A0_2
            L4_3 = L1_3.mods
            L2_3(L3_3, L4_3)
          end
        end
      end
      return
    end
    L0_3 = GetVehicleNumberPlateText
    L1_3 = A0_2
    L0_3 = L0_3(L1_3)
    if not L0_3 or "" == L0_3 then
      return
    end
    L1_3 = string
    L1_3 = L1_3.gsub
    L2_3 = L0_3
    L3_3 = "^%s*(.-)%s*$"
    L4_3 = "%1"
    L1_3 = L1_3(L2_3, L3_3, L4_3)
    L0_3 = L1_3
    L1_3 = lib
    L1_3 = L1_3.callback
    L1_3 = L1_3.await
    L2_3 = "qs-mechanic-creator:server:getVehicleEngineConfig"
    L3_3 = false
    L4_3 = L0_3
    L1_3 = L1_3(L2_3, L3_3, L4_3)
    if not L1_3 then
      return
    end
    L2_3 = DoesEntityExist
    L3_3 = A0_2
    L2_3 = L2_3(L3_3)
    if not L2_3 then
      return
    end
    L2_3 = L1_3.sound
    if L2_3 then
      L2_3 = L1_3.sound
      if "" ~= L2_3 then
        L2_3 = L3_1
        L3_3 = A0_2
        L4_3 = L1_3.sound
        L2_3(L3_3, L4_3)
      end
    end
    L2_3 = L1_3.mods
    if L2_3 then
      L2_3 = L2_1
      L3_3 = A0_2
      L4_3 = L1_3.mods
      L2_3(L3_3, L4_3)
    end
    L2_3 = 0
    while L2_3 < 30 do
      L3_3 = DoesEntityExist
      L4_3 = A0_2
      L3_3 = L3_3(L4_3)
      if not L3_3 then
        return
      end
      L3_3 = NetworkGetEntityIsNetworked
      L4_3 = A0_2
      L3_3 = L3_3(L4_3)
      if L3_3 then
        L3_3 = NetworkGetNetworkIdFromEntity
        L4_3 = A0_2
        L3_3 = L3_3(L4_3)
        if L3_3 and 0 ~= L3_3 then
          L4_3 = TriggerServerEvent
          L5_3 = "qs-mechanic-creator:server:setEngineConfig"
          L6_3 = {}
          L6_3.net = L3_3
          L7_3 = L1_3.sound
          L6_3.sound = L7_3
          L7_3 = L1_3.mods
          L6_3.mods = L7_3
          L7_3 = L1_3.engineType
          L6_3.engineType = L7_3
          L4_3(L5_3, L6_3)
          return
        end
      end
      L3_3 = Wait
      L4_3 = 200
      L3_3(L4_3)
      L2_3 = L2_3 + 1
    end
  end
  L1_2(L2_2)
end
L4_1(L5_1, L6_1)
L4_1 = AddStateBagChangeHandler
L5_1 = "engineConfig"
L6_1 = nil
function L7_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  if A2_2 then
    L3_2 = type
    L4_2 = A2_2
    L3_2 = L3_2(L4_2)
    if "table" == L3_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  if A0_2 then
    L3_2 = type
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if "string" == L3_2 then
      goto lbl_17
    end
  end
  do return end
  ::lbl_17::
  L4_2 = A0_2
  L3_2 = A0_2.gsub
  L5_2 = "entity:"
  L6_2 = ""
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = tonumber
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    return
  end
  L5_2 = NetworkDoesNetworkIdExist
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    return
  end
  L5_2 = NetworkGetEntityFromNetworkId
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  if L5_2 and 0 ~= L5_2 then
    L6_2 = IsEntityAVehicle
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      goto lbl_46
    end
  end
  do return end
  ::lbl_46::
  L6_2 = CreateThread
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = Wait
    L1_3 = 100
    L0_3(L1_3)
    L0_3 = DoesEntityExist
    L1_3 = L5_2
    L0_3 = L0_3(L1_3)
    if L0_3 then
      L0_3 = L3_1
      L1_3 = L5_2
      L2_3 = A2_2.sound
      L0_3(L1_3, L2_3)
      L0_3 = L2_1
      L1_3 = L5_2
      L2_3 = A2_2.mods
      L0_3(L1_3, L2_3)
    end
  end
  L6_2(L7_2)
end
L4_1(L5_1, L6_1, L7_1)
L4_1 = RegisterNetEvent
L5_1 = "qs-mechanic-creator:server:setEngineConfig"
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.net
    if L1_2 then
      goto lbl_10
    end
  end
  do return end
  ::lbl_10::
  L1_2 = NetworkDoesNetworkIdExist
  L2_2 = A0_2.net
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    return
  end
  L1_2 = NetworkGetEntityFromNetworkId
  L2_2 = A0_2.net
  L1_2 = L1_2(L2_2)
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L2_2 = Entity
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2.state
  L3_2 = L2_2
  L2_2 = L2_2.set
  L4_2 = "engineConfig"
  L5_2 = A0_2
  L6_2 = true
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L4_1(L5_1, L6_1)
L4_1 = AddEventHandler
L5_1 = "qs-mechanic-creator:client:reapplyEngineHandling"
function L6_1(A0_2)
  local L1_2, L2_2
  if A0_2 then
    L1_2 = DoesEntityExist
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      L1_2 = IsEntityAVehicle
      L2_2 = A0_2
      L1_2 = L1_2(L2_2)
      if L1_2 then
        goto lbl_14
      end
    end
  end
  do return end
  ::lbl_14::
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = Wait
    L1_3 = 150
    L0_3(L1_3)
    L0_3 = DoesEntityExist
    L1_3 = A0_2
    L0_3 = L0_3(L1_3)
    if not L0_3 then
      return
    end
    L0_3 = Entity
    L1_3 = A0_2
    L0_3 = L0_3(L1_3)
    L0_3 = L0_3.state
    L1_3 = L0_3 or L1_3
    if L0_3 then
      L1_3 = L0_3.engineConfig
    end
    if L1_3 then
      L2_3 = type
      L3_3 = L1_3
      L2_3 = L2_3(L3_3)
      if "table" == L2_3 then
        L2_3 = L1_3.mods
        if L2_3 then
          L2_3 = L2_1
          L3_3 = A0_2
          L4_3 = L1_3.mods
          L2_3(L3_3, L4_3)
        end
      end
    end
  end
  L1_2(L2_2)
end
L4_1(L5_1, L6_1)
