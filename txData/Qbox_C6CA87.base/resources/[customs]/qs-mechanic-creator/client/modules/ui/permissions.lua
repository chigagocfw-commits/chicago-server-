local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1
playerJob = nil
playerLicense = nil
L0_1 = {}
L1_1 = false
function L2_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if not A0_2 then
    L1_2 = "unknown"
    return L1_2
  end
  L1_2 = A0_2.id
  if L1_2 then
    L1_2 = tostring
    L2_2 = A0_2.id
    return L1_2(L2_2)
  end
  L1_2 = A0_2.job
  if not L1_2 then
    L1_2 = ""
  end
  L2_2 = A0_2.created_by
  if not L2_2 then
    L2_2 = A0_2.ownerLicense
    if not L2_2 then
      L2_2 = ""
    end
  end
  L3_2 = L1_2
  L4_2 = "_"
  L5_2 = L2_2
  L3_2 = L3_2 .. L4_2 .. L5_2
  return L3_2
end
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = playerLicense
  L3_2 = playerJob
  if L3_2 then
    L3_2 = playerJob
    L3_2 = L3_2.name
  end
  L4_2 = playerJob
  if L4_2 then
    L4_2 = playerJob
    L4_2 = L4_2.grade
  end
  playerJob = A0_2
  playerLicense = A1_2
  if L2_2 == A1_2 then
    if A0_2 then
      L5_2 = A0_2.name
      if L3_2 ~= L5_2 then
        goto lbl_26
      end
    end
    if not A0_2 then
      goto lbl_29
    end
    L5_2 = A0_2.grade
    if L4_2 == L5_2 then
      goto lbl_29
    end
  end
  ::lbl_26::
  L5_2 = {}
  L0_1 = L5_2
  ::lbl_29::
end
setPlayerData = L3_1
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = L2_1
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L2_2 = L0_1
  L2_2 = L2_2[L1_2]
  if nil ~= L2_2 then
    L2_2 = playerLicense
    if L2_2 then
      L2_2 = playerJob
      if L2_2 then
        L2_2 = L0_1
        L2_2 = L2_2[L1_2]
        return L2_2
      end
    end
  end
  L2_2 = false
  L3_2 = ""
  L4_2 = nil
  L5_2 = 0
  L6_2 = playerJob
  if L6_2 then
    L6_2 = type
    L7_2 = playerJob
    L6_2 = L6_2(L7_2)
    if "table" == L6_2 then
      L6_2 = playerJob
      L4_2 = L6_2.name
      L6_2 = tonumber
      L7_2 = playerJob
      L7_2 = L7_2.grade
      L6_2 = L6_2(L7_2)
      L5_2 = L6_2 or L5_2
      if not L6_2 then
        L5_2 = 0
      end
    else
      L6_2 = type
      L7_2 = playerJob
      L6_2 = L6_2(L7_2)
      if "string" == L6_2 then
        L4_2 = playerJob
        L5_2 = 0
      end
    end
  end
  L6_2 = playerLicense
  if not L6_2 or not L4_2 then
    L6_2 = A0_2.created_by
    if L6_2 then
      L6_2 = A0_2.created_by
    end
    L6_2 = "" ~= L6_2
    L7_2 = A0_2.job
    if L7_2 then
      L7_2 = A0_2.job
      L7_2 = "" ~= L7_2
    end
    if not L6_2 and not L7_2 then
      L3_2 = "Shop has no owner or job requirements (player data not loaded)"
      L2_2 = true
    else
      L3_2 = "Player data not loaded yet"
      L2_2 = false
    end
  else
    L6_2 = A0_2.created_by
    L7_2 = playerLicense
    if L6_2 and L7_2 and L6_2 == L7_2 then
      L3_2 = "Player is owner"
      L2_2 = true
    else
      L6_2 = A0_2.ownerLicense
      L7_2 = playerLicense
      if L6_2 and L7_2 and L6_2 == L7_2 then
        L3_2 = "Player is owner"
        L2_2 = true
      else
        L6_2 = A0_2.job
        if L6_2 and L4_2 then
          L6_2 = A0_2.job
          if L4_2 == L6_2 then
            L6_2 = tonumber
            L7_2 = A0_2.jobGrade
            L6_2 = L6_2(L7_2)
            if not L6_2 then
              L6_2 = 0
            end
            if L5_2 >= L6_2 then
              L3_2 = "Player has job access"
              L2_2 = true
            else
              L3_2 = "Insufficient job grade"
              L2_2 = false
            end
          else
            L3_2 = "No matching criteria"
            L2_2 = false
          end
        else
          L6_2 = A0_2.created_by
          if L6_2 then
            L6_2 = A0_2.created_by
          end
          L6_2 = "" ~= L6_2
          L7_2 = A0_2.job
          if L7_2 then
            L7_2 = A0_2.job
            L7_2 = "" ~= L7_2
          end
          if not L6_2 and not L7_2 then
            L3_2 = "Shop has no owner or job requirements"
            L2_2 = true
          else
            L3_2 = "No matching criteria"
            L2_2 = false
          end
        end
      end
    end
  end
  L6_2 = playerLicense
  if L6_2 and L4_2 then
    L6_2 = L0_1
    L6_2[L1_2] = L2_2
    L6_2 = L1_1
    if L6_2 then
      L6_2 = Config
      L6_2 = L6_2.Debug
      if L6_2 then
        L6_2 = print
        L7_2 = "[PERMISSIONS DEBUG] Cache set for"
        L8_2 = L1_2
        L9_2 = "="
        L10_2 = L2_2
        L11_2 = "-"
        L12_2 = L3_2
        L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
      end
    end
  end
  return L2_2
end
hasShopAccess = L3_1
function L3_1(A0_2)
  local L1_2, L2_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = Config
  L1_2 = L1_2.MechanicsOnlyTuneshop
  if L1_2 then
    L1_2 = isMechanicEmployee
    L2_2 = A0_2
    return L1_2(L2_2)
  end
  L1_2 = true
  return L1_2
end
canUseTuneshop = L3_1
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = nil
  L2_2 = 0
  L3_2 = playerJob
  if L3_2 then
    L3_2 = type
    L4_2 = playerJob
    L3_2 = L3_2(L4_2)
    if "table" == L3_2 then
      L3_2 = playerJob
      L1_2 = L3_2.name
      L3_2 = tonumber
      L4_2 = playerJob
      L4_2 = L4_2.grade
      L3_2 = L3_2(L4_2)
      L2_2 = L3_2 or L2_2
      if not L3_2 then
        L2_2 = 0
      end
    else
      L3_2 = type
      L4_2 = playerJob
      L3_2 = L3_2(L4_2)
      if "string" == L3_2 then
        L1_2 = playerJob
        L2_2 = 0
      end
    end
  end
  if not L1_2 then
    L3_2 = false
    return L3_2
  end
  L3_2 = A0_2.created_by
  L4_2 = playerLicense
  if L3_2 and L4_2 and L3_2 == L4_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = A0_2.ownerLicense
  L4_2 = playerLicense
  if L3_2 and L4_2 and L3_2 == L4_2 then
    L3_2 = true
    return L3_2
  end
  L3_2 = A0_2.job
  if L3_2 and L1_2 then
    L3_2 = A0_2.job
    if L1_2 == L3_2 then
      L3_2 = tonumber
      L4_2 = A0_2.jobGrade
      L3_2 = L3_2(L4_2)
      if not L3_2 then
        L3_2 = 0
      end
      if L2_2 >= L3_2 then
        L4_2 = true
        return L4_2
      end
    end
  end
  L3_2 = false
  return L3_2
end
isMechanicEmployee = L3_1
L3_1 = RegisterNetEvent
L4_1 = "qs-mechanic-creator:client:updatePlayerData"
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = playerJob
  if L1_2 then
    L1_2 = playerJob
    L1_2 = L1_2.name
  end
  L2_2 = playerJob
  if L2_2 then
    L2_2 = playerJob
    L2_2 = L2_2.grade
  end
  L3_2 = playerLicense
  L4_2 = A0_2.job
  if L4_2 then
    L4_2 = A0_2.job
    playerJob = L4_2
  end
  L4_2 = A0_2.license
  if L4_2 then
    L4_2 = A0_2.license
    playerLicense = L4_2
  end
  L4_2 = playerLicense
  if L3_2 == L4_2 then
    L4_2 = playerJob
    if L4_2 then
      L4_2 = playerJob
      L4_2 = L4_2.name
    end
    if L1_2 == L4_2 then
      L4_2 = playerJob
      if L4_2 then
        L4_2 = playerJob
        L4_2 = L4_2.grade
      end
      if L2_2 == L4_2 then
        goto lbl_42
      end
    end
  end
  L4_2 = {}
  L0_1 = L4_2
  ::lbl_42::
  L4_2 = TriggerEvent
  L5_2 = "qs-mechanic-creator:client:refreshZones"
  L4_2(L5_2)
end
L3_1(L4_1, L5_1)
L3_1 = RegisterNetEvent
L4_1 = "qs-mechanic-creator:client:refreshZones"
function L5_1()
  local L0_2, L1_2
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic-creator:client:updateShops"
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic-creator:client:updateStashes"
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic-creator:client:updateGarages"
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "qs-mechanic-creator:client:updateTuneshops"
  L0_2(L1_2)
end
L3_1(L4_1, L5_1)
L3_1 = RegisterNetEvent
L4_1 = "qs-mechanic-creator:client:dutyChanged"
function L5_1(A0_2)
  local L1_2, L2_2
  L1_2 = {}
  L0_1 = L1_2
  L1_2 = TriggerEvent
  L2_2 = "qs-mechanic-creator:client:refreshZones"
  L1_2(L2_2)
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "updateDutyStatus"
  L2_2.onDuty = A0_2
  L1_2(L2_2)
end
L3_1(L4_1, L5_1)
L3_1 = CreateThread
function L4_1()
  local L0_2, L1_2
  L0_2 = Wait
  L1_2 = 2000
  L0_2(L1_2)
  L0_2 = playerJob
  if L0_2 then
    L0_2 = playerLicense
    if L0_2 then
      goto lbl_13
    end
  end
  L0_2 = TriggerServerEvent
  L1_2 = "qs-mechanic-creator:server:requestPlayerData"
  L0_2(L1_2)
  ::lbl_13::
  L0_2 = Wait
  L1_2 = 3000
  L0_2(L1_2)
  L0_2 = playerJob
  if L0_2 then
    L0_2 = playerLicense
    if L0_2 then
      goto lbl_25
    end
  end
  L0_2 = TriggerServerEvent
  L1_2 = "qs-mechanic-creator:server:requestPlayerData"
  L0_2(L1_2)
  ::lbl_25::
  L0_2 = Wait
  L1_2 = 5000
  L0_2(L1_2)
  L0_2 = playerJob
  if L0_2 then
    L0_2 = playerLicense
    if L0_2 then
      goto lbl_37
    end
  end
  L0_2 = TriggerServerEvent
  L1_2 = "qs-mechanic-creator:server:requestPlayerData"
  L0_2(L1_2)
  ::lbl_37::
end
L3_1(L4_1)
function L3_1()
  local L0_2, L1_2
  L0_2 = playerJob
  return L0_2
end
getPlayerJob = L3_1
function L3_1()
  local L0_2, L1_2
  L0_2 = playerLicense
  return L0_2
end
getPlayerLicense = L3_1
function L3_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = playerJob
  L0_2.job = L1_2
  L1_2 = playerLicense
  L0_2.license = L1_2
  return L0_2
end
getPlayerData = L3_1
