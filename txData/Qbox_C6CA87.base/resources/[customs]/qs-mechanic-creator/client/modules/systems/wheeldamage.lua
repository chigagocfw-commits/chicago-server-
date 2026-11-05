local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1
L0_1 = {}
L0_1.__index = L0_1
L1_1 = {}
L1_1.UPDATE_INTERVAL = 750
L1_1.CACHE_DURATION = 10000
L2_1 = {}
L2_1[0] = 0
L2_1[1] = 1
L2_1[4] = 2
L2_1[5] = 3
L1_1.WHEEL_ID_MAPPING = L2_1
L1_1.DEFAULT_CRASH_SPEED = 180
L1_1.DEFAULT_CRASH_CHANCE = 100
L1_1.DEFAULT_CRASH_COOLDOWN = 5000
L2_1 = {}
L3_1 = 0
L4_1 = 1
L5_1 = 4
L6_1 = 5
L2_1[1] = L3_1
L2_1[2] = L4_1
L2_1[3] = L5_1
L2_1[4] = L6_1
L1_1.DEFAULT_CRASH_WHEELS = L2_1
L1_1.BURST_DISTANCE_THRESHOLD = 150.0
L1_1.BURST_DISTANCE_MORE = 150.0
L1_1.LEFT_STEER_BIAS = 1.0
L1_1.RIGHT_STEER_BIAS = -1.0
L1_1.NEUTRAL_STEER_BIAS = 0.0
L1_1.SPEED_CONVERSION_FACTOR = 3.6
L2_1 = {}
L2_1.enabled = true
L3_1 = {}
L4_1 = {}
L3_1.models = L4_1
L4_1 = {}
L3_1.classes = L4_1
L2_1.blacklist = L3_1
L3_1 = {}
L3_1.enabled = true
L4_1 = L1_1.DEFAULT_CRASH_SPEED
L3_1.speed = L4_1
L4_1 = L1_1.DEFAULT_CRASH_CHANCE
L3_1.chance = L4_1
L4_1 = L1_1.DEFAULT_CRASH_WHEELS
L3_1.wheels = L4_1
L4_1 = L1_1.DEFAULT_CRASH_COOLDOWN
L3_1.cooldown = L4_1
L2_1.crashBreak = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = setmetatable
  L3_2 = {}
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = L2_1
  end
  L2_2.config = L3_2
  L3_2 = {}
  L2_2.cache = L3_2
  L2_2.isInitialized = false
  L3_2 = {}
  L2_2.brokenTyres = L3_2
  L2_2.lastCrashTime = 0
  return L2_2
end
L0_1.new = L3_1
function L3_1(A0_2)
  local L1_2
  L1_2 = A0_2.isInitialized
  if L1_2 then
    L1_2 = true
    return L1_2
  end
  A0_2.isInitialized = true
  L1_2 = true
  return L1_2
end
L0_1.initialize = L3_1
function L3_1(A0_2)
  local L1_2
  L1_2 = A0_2.config
  L1_2 = L1_2.enabled
  L1_2 = false ~= L1_2
  return L1_2
end
L0_1.isActive = L3_1
function L3_1(A0_2)
  local L1_2
  L1_2 = A0_2.config
  return L1_2
end
L0_1.getConfig = L3_1
function L3_1(A0_2, A1_2)
  local L2_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = L2_1
  end
  A0_2.config = L2_2
end
L0_1.updateConfig = L3_1
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2.cache
  L5_2 = {}
  L5_2.value = A2_2
  L6_2 = GetGameTimer
  L6_2 = L6_2()
  L7_2 = A3_2 or L7_2
  if not A3_2 then
    L7_2 = L1_1.CACHE_DURATION
  end
  L6_2 = L6_2 + L7_2
  L5_2.expiry = L6_2
  L4_2[A1_2] = L5_2
end
L0_1.storeCache = L3_1
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L4_2 = A0_2.cache
  L4_2 = L4_2[A1_2]
  if L4_2 then
    L5_2 = L4_2.expiry
    L6_2 = GetGameTimer
    L6_2 = L6_2()
    if not (L5_2 < L6_2) then
      goto lbl_25
    end
  end
  L5_2 = {}
  L6_2 = A2_2
  L6_2, L7_2, L8_2, L9_2, L10_2 = L6_2()
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  L5_2[4] = L9_2
  L5_2[5] = L10_2
  L7_2 = A0_2
  L6_2 = A0_2.storeCache
  L8_2 = A1_2
  L9_2 = L5_2
  L10_2 = A3_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = table
  L6_2 = L6_2.unpack
  L7_2 = L5_2
  do return L6_2(L7_2) end
  ::lbl_25::
  L5_2 = table
  L5_2 = L5_2.unpack
  L6_2 = L4_2.value
  return L5_2(L6_2)
end
L0_1.getCached = L3_1
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = {}
  L3_2 = pairs
  L4_2 = A0_2.cache
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L8_2.expiry
    if L1_2 > L9_2 then
      L9_2 = #L2_2
      L9_2 = L9_2 + 1
      L2_2[L9_2] = L7_2
    end
  end
  L3_2 = ipairs
  L4_2 = L2_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = A0_2.cache
    L9_2[L8_2] = nil
  end
end
L0_1.cleanupCache = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "model_blacklist_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L0_3 = GetEntityModel
    L1_3 = A1_2
    L0_3 = L0_3(L1_3)
    L1_3 = A0_2.config
    L1_3 = L1_3.blacklist
    if L1_3 then
      L1_3 = A0_2.config
      L1_3 = L1_3.blacklist
      L1_3 = L1_3.models
      if L1_3 then
        goto lbl_15
      end
    end
    L1_3 = false
    do return L1_3 end
    ::lbl_15::
    L1_3 = ipairs
    L2_3 = A0_2.config
    L2_3 = L2_3.blacklist
    L2_3 = L2_3.models
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      L7_3 = type
      L8_3 = L6_3
      L7_3 = L7_3(L8_3)
      if "string" == L7_3 then
        L7_3 = GetHashKey
        L8_3 = L6_3
        L7_3 = L7_3(L8_3)
        if L7_3 == L0_3 then
          L7_3 = true
          return L7_3
        end
      end
    end
    L1_3 = false
    return L1_3
  end
  L6_2 = 30000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isModelBlacklisted = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "class_blacklist_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = GetVehicleClass
    L1_3 = A1_2
    L0_3 = L0_3(L1_3)
    L1_3 = A0_2.config
    L1_3 = L1_3.blacklist
    if L1_3 then
      L1_3 = A0_2.config
      L1_3 = L1_3.blacklist
      L1_3 = L1_3.classes
      if L1_3 then
        goto lbl_15
      end
    end
    L1_3 = false
    do return L1_3 end
    ::lbl_15::
    L1_3 = ipairs
    L2_3 = A0_2.config
    L2_3 = L2_3.blacklist
    L2_3 = L2_3.classes
    L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3)
    for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
      if L6_3 == L0_3 then
        L7_3 = true
        return L7_3
      end
    end
    L1_3 = false
    return L1_3
  end
  L6_2 = 30000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isClassBlacklisted = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L3_2 = A0_2
  L2_2 = A0_2.isModelBlacklisted
  L4_2 = A1_2
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L3_2 = A0_2
    L2_2 = A0_2.isClassBlacklisted
    L4_2 = A1_2
    L2_2 = L2_2(L3_2, L4_2)
  end
  return L2_2
end
L0_1.isVehicleBlacklisted = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A0_2.brokenTyres
  L2_2 = L2_2[A1_2]
  if not L2_2 then
    return
  end
  L2_2 = A0_2.brokenTyres
  L2_2 = L2_2[A1_2]
  L3_2 = L2_2[0]
  if L3_2 then
    L3_2 = L2_2[1]
    if not L3_2 then
      L3_2 = SetVehicleSteerBias
      L4_2 = A1_2
      L5_2 = L1_1.LEFT_STEER_BIAS
      L3_2(L4_2, L5_2)
  end
  else
    L3_2 = L2_2[1]
    if L3_2 then
      L3_2 = L2_2[0]
      if not L3_2 then
        L3_2 = SetVehicleSteerBias
        L4_2 = A1_2
        L5_2 = L1_1.RIGHT_STEER_BIAS
        L3_2(L4_2, L5_2)
    end
    else
      L3_2 = SetVehicleSteerBias
      L4_2 = A1_2
      L5_2 = L1_1.NEUTRAL_STEER_BIAS
      L3_2(L4_2, L5_2)
    end
  end
end
L0_1.updateSteeringBias = L3_1
function L3_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = L1_1.WHEEL_ID_MAPPING
  L3_2 = L3_2[A2_2]
  if L3_2 then
    L4_2 = BreakOffVehicleWheel
    L5_2 = A1_2
    L6_2 = L3_2
    L7_2 = true
    L8_2 = false
    L9_2 = true
    L10_2 = false
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
    L4_2 = A0_2.brokenTyres
    L4_2 = L4_2[A1_2]
    if not L4_2 then
      L4_2 = A0_2.brokenTyres
      L5_2 = {}
      L4_2[A1_2] = L5_2
    end
    L4_2 = A0_2.brokenTyres
    L4_2 = L4_2[A1_2]
    L4_2[A2_2] = true
    L5_2 = A0_2
    L4_2 = A0_2.updateSteeringBias
    L6_2 = A1_2
    L4_2(L5_2, L6_2)
  end
end
L0_1.breakVehicleWheel = L3_1
function L3_1(A0_2)
  local L1_2
  L1_2 = A0_2.config
  L1_2 = L1_2.crashBreak
  if not L1_2 then
    L1_2 = {}
    L1_2.enabled = false
  end
  return L1_2
end
L0_1.getCrashBreakConfig = L3_1
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L2_2 = A0_2
  L1_2 = A0_2.getCrashBreakConfig
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2.cooldown
  if not L2_2 then
    L2_2 = L1_1.DEFAULT_CRASH_COOLDOWN
  end
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L4_2 = A0_2.lastCrashTime
  L3_2 = L3_2 - L4_2
  L3_2 = L2_2 > L3_2
  return L3_2
end
L0_1.isCrashBreakOnCooldown = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L3_2 = A0_2
  L2_2 = A0_2.getCrashBreakConfig
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2.enabled
  if L3_2 then
    L4_2 = A0_2
    L3_2 = A0_2.isVehicleBlacklisted
    L5_2 = A1_2
    L3_2 = L3_2(L4_2, L5_2)
    if not L3_2 then
      L4_2 = A0_2
      L3_2 = A0_2.isCrashBreakOnCooldown
      L3_2 = L3_2(L4_2)
      if not L3_2 then
        goto lbl_17
      end
    end
  end
  L3_2 = false
  do return L3_2 end
  ::lbl_17::
  L3_2 = math
  L3_2 = L3_2.ceil
  L4_2 = GetEntitySpeed
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = L1_1.SPEED_CONVERSION_FACTOR
  L4_2 = L4_2 * L5_2
  L3_2 = L3_2(L4_2)
  L4_2 = L2_2.speed
  if not L4_2 then
    L4_2 = L1_1.DEFAULT_CRASH_SPEED
  end
  L5_2 = HasEntityCollidedWithAnything
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  if L5_2 and L3_2 >= L4_2 then
    L5_2 = L2_2.chance
    if not L5_2 then
      L5_2 = L1_1.DEFAULT_CRASH_CHANCE
    end
    L6_2 = math
    L6_2 = L6_2.random
    L7_2 = 0
    L8_2 = 100
    L6_2 = L6_2(L7_2, L8_2)
    if L5_2 >= L6_2 then
      L6_2 = L2_2.wheels
      if not L6_2 then
        L6_2 = L1_1.DEFAULT_CRASH_WHEELS
      end
      L7_2 = math
      L7_2 = L7_2.random
      L8_2 = 1
      L9_2 = #L6_2
      L7_2 = L7_2(L8_2, L9_2)
      L7_2 = L6_2[L7_2]
      L9_2 = A0_2
      L8_2 = A0_2.breakVehicleWheel
      L10_2 = A1_2
      L11_2 = L7_2
      L8_2(L9_2, L10_2, L11_2)
      L8_2 = GetGameTimer
      L8_2 = L8_2()
      A0_2.lastCrashTime = L8_2
      L8_2 = true
      return L8_2
    end
  end
  L5_2 = false
  return L5_2
end
L0_1.processCrashBreak = L3_1
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = IsVehicleTyreBurst
  L5_2 = A1_2
  L6_2 = A2_2
  L7_2 = true
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  if L4_2 then
    L4_2 = L1_1.BURST_DISTANCE_THRESHOLD
    if A3_2 > L4_2 then
      L5_2 = A0_2
      L4_2 = A0_2.breakVehicleWheel
      L6_2 = A1_2
      L7_2 = A2_2
      L4_2(L5_2, L6_2, L7_2)
      L4_2 = true
      return L4_2
    end
  end
  L4_2 = false
  return L4_2
end
L0_1.processTireBurst = L3_1
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A0_2.brokenTyres
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = A0_2.brokenTyres
    L3_2 = {}
    L2_2[A1_2] = L3_2
    L3_2 = A0_2
    L2_2 = A0_2.updateSteeringBias
    L4_2 = A1_2
    L2_2(L3_2, L4_2)
  end
end
L0_1.resetBrokenTires = L3_1
L3_1 = false
function L4_1(A0_2)
  local L1_2, L2_2
  L1_2 = L3_1
  if L1_2 then
    return
  end
  L1_2 = true
  L3_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    while true do
      L0_3 = A0_2.isInitialized
      if L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 100
      L0_3(L1_3)
    end
    L0_3 = 0
    while true do
      L1_3 = L3_1
      if L1_3 then
        L1_3 = A0_2
        L2_3 = L1_3
        L1_3 = L1_3.isActive
        L1_3 = L1_3(L2_3)
        if L1_3 then
          goto lbl_21
        end
      end
      L1_3 = Wait
      L2_3 = 1000
      L1_3(L2_3)
      goto lbl_74
      ::lbl_21::
      L1_3 = L1_1.UPDATE_INTERVAL
      L2_3 = PlayerPedId
      L2_3 = L2_3()
      L0_3 = L0_3 + 1
      if L0_3 >= 10 then
        L3_3 = A0_2
        L4_3 = L3_3
        L3_3 = L3_3.cleanupCache
        L3_3(L4_3)
        L0_3 = 0
      end
      L3_3 = IsPedInAnyVehicle
      L4_3 = L2_3
      L5_3 = false
      L3_3 = L3_3(L4_3, L5_3)
      if L3_3 then
        L3_3 = GetVehiclePedIsIn
        L4_3 = L2_3
        L5_3 = false
        L3_3 = L3_3(L4_3, L5_3)
        L4_3 = GetPedInVehicleSeat
        L5_3 = L3_3
        L6_3 = -1
        L4_3 = L4_3(L5_3, L6_3)
        if L4_3 == L2_3 then
          L4_3 = A0_2
          L5_3 = L4_3
          L4_3 = L4_3.getCrashBreakConfig
          L4_3 = L4_3(L5_3)
          L5_3 = A0_2
          L6_3 = L5_3
          L5_3 = L5_3.isVehicleBlacklisted
          L7_3 = L3_3
          L5_3 = L5_3(L6_3, L7_3)
          if not L5_3 then
            L5_3 = L4_3.enabled
            if L5_3 then
              L1_3 = 100
              L5_3 = A0_2
              L6_3 = L5_3
              L5_3 = L5_3.processCrashBreak
              L7_3 = L3_3
              L5_3 = L5_3(L6_3, L7_3)
              if L5_3 then
                L5_3 = L4_3.cooldown
                L1_3 = L5_3 or L1_3
                if not L5_3 then
                  L1_3 = L1_1.DEFAULT_CRASH_COOLDOWN
                end
              end
            end
          end
        end
      end
      L3_3 = Wait
      L4_3 = L1_3
      L3_3(L4_3)
      ::lbl_74::
    end
  end
  L1_2(L2_2)
end
L0_1.startMainThread = L4_1
function L4_1(A0_2)
  local L1_2, L2_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    while true do
      L0_3 = A0_2.isInitialized
      if L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 100
      L0_3(L1_3)
    end
    L0_3 = false
    L1_3 = nil
    L2_3 = 0
    L3_3 = lib
    L3_3 = L3_3.onCache
    L4_3 = "vehicle"
    function L5_3(A0_4)
      local L1_4, L2_4, L3_4
      L0_3 = A0_4
      L1_4 = L0_3
      if not L1_4 then
        L1_4 = 0
        L2_3 = L1_4
        L1_4 = nil
        L1_3 = L1_4
        L1_4 = A0_2.brokenTyres
        L1_4 = L1_4[A0_4]
        if L1_4 then
          L1_4 = A0_2
          L2_4 = L1_4
          L1_4 = L1_4.resetBrokenTires
          L3_4 = A0_4
          L1_4(L2_4, L3_4)
        end
        return
      end
      L1_4 = GetVehicleNumberOfWheels
      L2_4 = A0_4
      L1_4 = L1_4(L2_4)
      L1_4 = L1_4 + 1
      L2_4 = CreateThread
      function L3_4()
        local L0_5, L1_5, L2_5, L3_5, L4_5, L5_5, L6_5, L7_5, L8_5, L9_5, L10_5
        while true do
          L0_5 = L0_3
          if not L0_5 then
            break
          end
          L0_5 = A0_2
          L1_5 = L0_5
          L0_5 = L0_5.isActive
          L0_5 = L0_5(L1_5)
          if not L0_5 then
            L0_5 = Wait
            L1_5 = 5000
            L0_5(L1_5)
          else
            L0_5 = A0_2
            L1_5 = L0_5
            L0_5 = L0_5.isVehicleBlacklisted
            L2_5 = L0_3
            L0_5 = L0_5(L1_5, L2_5)
            if L0_5 then
              L0_5 = Wait
              L1_5 = L1_1.UPDATE_INTERVAL
              L0_5(L1_5)
            else
              L0_5 = L1_1.UPDATE_INTERVAL
              L1_5 = PlayerPedId
              L1_5 = L1_5()
              L2_5 = 0
              L3_5 = L1_4
              L4_5 = 1
              for L5_5 = L2_5, L3_5, L4_5 do
                L6_5 = IsVehicleTyreBurst
                L7_5 = L0_3
                L8_5 = L5_5
                L9_5 = true
                L6_5 = L6_5(L7_5, L8_5, L9_5)
                if L6_5 then
                  L0_5 = 0
                  L6_5 = L1_3
                  if not L6_5 then
                    L6_5 = GetEntityCoords
                    L7_5 = L1_5
                    L6_5 = L6_5(L7_5)
                    L1_3 = L6_5
                  end
                  L6_5 = GetEntityCoords
                  L7_5 = L1_5
                  L6_5 = L6_5(L7_5)
                  L7_5 = L1_3
                  L7_5 = L7_5 - L6_5
                  L7_5 = #L7_5
                  L2_3 = L7_5
                  L7_5 = L2_3
                  L8_5 = L1_1.BURST_DISTANCE_MORE
                  if L7_5 > L8_5 then
                    L7_5 = A0_2
                    L8_5 = L7_5
                    L7_5 = L7_5.breakVehicleWheel
                    L9_5 = L0_3
                    L10_5 = L5_5
                    L7_5(L8_5, L9_5, L10_5)
                  end
                end
              end
              L2_5 = Wait
              L3_5 = L0_5
              L2_5(L3_5)
            end
          end
        end
      end
      L2_4(L3_4)
    end
    L3_3(L4_3, L5_3)
  end
  L1_2(L2_2)
end
L0_1.startTireBurstThread = L4_1
L5_1 = L0_1
L4_1 = L0_1.new
L4_1 = L4_1(L5_1)
L5_1 = RegisterNetEvent
L6_1 = "qs-mechanic-creator:client:setWheelDamage"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = L4_1
  L2_2 = L1_2
  L1_2 = L1_2.isActive
  L1_2 = L1_2(L2_2)
  L2_2 = L4_1
  L3_2 = L2_2
  L2_2 = L2_2.updateConfig
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = L4_1
  L3_2 = L2_2
  L2_2 = L2_2.initialize
  L2_2(L3_2)
  L2_2 = L4_1
  L3_2 = L2_2
  L2_2 = L2_2.isActive
  L2_2 = L2_2(L3_2)
  L3_2 = PlayerPedId
  L3_2 = L3_2()
  L4_2 = IsPedInAnyVehicle
  L5_2 = L3_2
  L6_2 = false
  L4_2 = L4_2(L5_2, L6_2)
  if L2_2 and not L1_2 and L4_2 then
    L5_2 = TriggerEvent
    L6_2 = "qs-mechanic:client:startWheelDamage"
    L5_2(L6_2)
  elseif not L2_2 and L1_2 then
    L5_2 = TriggerEvent
    L6_2 = "qs-mechanic:client:stopWheelDamage"
    L5_2(L6_2)
  end
end
L5_1(L6_1, L7_1)
L5_1 = CreateThread
function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  while true do
    L0_2 = lib
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 100
    L0_2(L1_2)
  end
  L0_2 = 0
  L1_2 = 10
  while true do
    L2_2 = L4_1.isInitialized
    if not (not L2_2 and L0_2 < L1_2) then
      break
    end
    L0_2 = L0_2 + 1
    L2_2 = pcall
    function L3_2()
      local L0_3, L1_3, L2_3, L3_3
      L0_3 = lib
      L0_3 = L0_3.callback
      L0_3 = L0_3.await
      L1_3 = "qs-mechanic-creator:server:getConfig"
      L2_3 = false
      L3_3 = "wheeldamage"
      return L0_3(L1_3, L2_3, L3_3)
    end
    L2_2, L3_2 = L2_2(L3_2)
    if L2_2 and L3_2 then
      L4_2 = L4_1
      L5_2 = L4_2
      L4_2 = L4_2.updateConfig
      L6_2 = L3_2
      L4_2(L5_2, L6_2)
      L4_2 = L4_1
      L5_2 = L4_2
      L4_2 = L4_2.initialize
      L4_2(L5_2)
      break
    else
      L4_2 = Wait
      L5_2 = 1000
      L4_2(L5_2)
    end
  end
  L2_2 = L4_1.isInitialized
  if not L2_2 then
    L2_2 = L4_1
    L3_2 = L2_2
    L2_2 = L2_2.updateConfig
    L4_2 = L2_1
    L2_2(L3_2, L4_2)
    L2_2 = L4_1
    L3_2 = L2_2
    L2_2 = L2_2.initialize
    L2_2(L3_2)
  end
end
L5_1(L6_1)
L5_1 = RegisterNetEvent
L6_1 = "qs-mechanic:client:startWheelDamage"
function L7_1()
  local L0_2, L1_2
  L0_2 = L4_1
  if L0_2 then
    L0_2 = L4_1
    L1_2 = L0_2
    L0_2 = L0_2.isActive
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = true
      L3_1 = L0_2
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNetEvent
L6_1 = "qs-mechanic:client:stopWheelDamage"
function L7_1()
  local L0_2, L1_2
  L0_2 = false
  L3_1 = L0_2
end
L5_1(L6_1, L7_1)
L6_1 = L4_1
L5_1 = L4_1.startMainThread
L5_1(L6_1)
L6_1 = L4_1
L5_1 = L4_1.startTireBurstThread
L5_1(L6_1)
