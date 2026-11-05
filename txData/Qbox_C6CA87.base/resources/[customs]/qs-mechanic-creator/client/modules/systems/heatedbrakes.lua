local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
L0_1 = {}
L0_1.__index = L0_1
L1_1 = {}
L2_1 = {}
L2_1.MAX_TEMPERATURE = 250.0
L2_1.MIN_TEMPERATURE = 0.0
L2_1.GLOW_THRESHOLD = 80.0
L2_1.UPDATE_INTERVAL = 150
L2_1.CACHE_DURATION = 5000
L2_1.NEARBY_VEHICLE_RANGE = 40.0
L2_1.EFFECT_CLEANUP_RANGE = 60.0
L2_1.FADE_START_TEMP = 100.0
L2_1.MIN_BRAKE_FORCE = 0.15
L2_1.DEFAULT_BRAKE_FORCE = 1.0
L2_1.MIN_TEMP_CHANGE = 0.8
L2_1.BASE_COOLING_RATE = 0.35
L2_1.AIRFLOW_MULTIPLIER = 0.25
L2_1.MAX_AIRFLOW_SPEED = 50.0
L2_1.MAX_AIRFLOW_COOLING = 2.0
L2_1.BRAKE_TEMP_STATE = "vehicle_brake_temps"
L2_1.PARTICLE_EFFECT = "veh_exhaust_afterburner"
L3_1 = {}
L4_1 = 255.0
L5_1 = 100.0
L6_1 = 0.0
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L2_1.PARTICLE_COLOR = L3_1
L2_1.PARTICLE_ALPHA = 1.0
L3_1 = {}
L4_1 = "wheel_lf"
L5_1 = "wheel_rf"
L6_1 = "wheel_lr"
L7_1 = "wheel_rr"
L3_1[1] = L4_1
L3_1[2] = L5_1
L3_1[3] = L6_1
L3_1[4] = L7_1
L2_1.WHEEL_BONES = L3_1
L3_1 = {}
L3_1.enabled = true
L3_1.temperatureRate = 1.0
L3_1.coolingRate = 1.0
L3_1.performanceLoss = 1.0
L4_1 = {}
L3_1.blacklistedVehicles = L4_1
L4_1 = {}
L5_1 = {}
L5_1.enabled = true
L5_1.strength = 1.0
L4_1.glow = L5_1
L3_1.visual = L4_1
L4_1 = {}
L5_1 = {}
L4_1.classes = L5_1
L5_1 = {}
L6_1 = -1
L5_1[L6_1] = 1.0
L5_1[0] = 1.0
L5_1[1] = 1.0
L5_1[2] = 1.0
L4_1.brakeUpgrade = L5_1
L3_1.temperatureIncrease = L4_1
L4_1 = {}
L5_1 = {}
L4_1.classes = L5_1
L5_1 = {}
L6_1 = -1
L5_1[L6_1] = 1.0
L5_1[0] = 1.0
L5_1[1] = 1.0
L5_1[2] = 1.0
L4_1.brakeUpgrade = L5_1
L3_1.temperatureDecrease = L4_1
L4_1 = {}
L3_1.vehicleOverrides = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = setmetatable
  L3_2 = {}
  L4_2 = A0_2
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = L3_1
  end
  L2_2.config = L3_2
  L3_2 = {}
  L2_2.cache = L3_2
  L2_2.isInitialized = false
  L3_2 = {}
  L2_2.trackedVehicles = L3_2
  L2_2.currentVehicle = 0
  L3_2 = L2_1.DEFAULT_BRAKE_FORCE
  L2_2.lastBrakeForce = L3_2
  return L2_2
end
L0_1.new = L4_1
function L4_1(A0_2)
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
L0_1.initialize = L4_1
function L4_1(A0_2)
  local L1_2
  L1_2 = A0_2.config
  L1_2 = L1_2.enabled
  L1_2 = false ~= L1_2
  return L1_2
end
L0_1.isActive = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.config
  L2_2 = L2_2.blacklistedVehicles
  if L2_2 then
    L2_2 = A0_2.config
    L2_2 = L2_2.blacklistedVehicles
    L2_2 = #L2_2
    if 0 ~= L2_2 then
      goto lbl_12
    end
  end
  L2_2 = false
  do return L2_2 end
  ::lbl_12::
  L2_2 = GetEntityModel
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L3_2 = GetDisplayNameFromVehicleModel
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = L3_2
  L3_2 = L3_2.lower
  L3_2 = L3_2(L4_2)
  L4_2 = ipairs
  L5_2 = A0_2.config
  L5_2 = L5_2.blacklistedVehicles
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L11_2 = L9_2
    L10_2 = L9_2.lower
    L10_2 = L10_2(L11_2)
    if L3_2 == L10_2 then
      L10_2 = true
      return L10_2
    end
  end
  L4_2 = false
  return L4_2
end
L0_1.isVehicleBlacklisted = L4_1
function L4_1(A0_2)
  local L1_2
  L1_2 = A0_2.config
  return L1_2
end
L0_1.getConfig = L4_1
function L4_1(A0_2, A1_2)
  local L2_2
  L2_2 = A1_2 or nil
  if not A1_2 then
    L2_2 = L3_1
  end
  A0_2.config = L2_2
end
L0_1.updateConfig = L4_1
function L4_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = A0_2.cache
  L5_2 = {}
  L5_2.value = A2_2
  L6_2 = GetGameTimer
  L6_2 = L6_2()
  L7_2 = A3_2 or L7_2
  if not A3_2 then
    L7_2 = L2_1.CACHE_DURATION
  end
  L6_2 = L6_2 + L7_2
  L5_2.expiry = L6_2
  L4_2[A1_2] = L5_2
end
L0_1.storeCache = L4_1
function L4_1(A0_2, A1_2, A2_2, A3_2)
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
L0_1.getCached = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "brake_upgrade_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = GetVehicleMod
    L1_3 = A1_2
    L2_3 = 12
    return L0_3(L1_3, L2_3)
  end
  L6_2 = 60000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.getBrakeUpgradeLevel = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "vehicle_class_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3
    L0_3 = GetVehicleClass
    L1_3 = A1_2
    return L0_3(L1_3)
  end
  L6_2 = 60000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.getVehicleClass = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = GetEntitySpeed
  L3_2 = A1_2
  return L2_2(L3_2)
end
L0_1.getVehicleSpeed = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "is_helicopter_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3
    L0_3 = IsPedInAnyHeli
    L1_3 = PlayerPedId
    L1_3 = L1_3()
    return L0_3(L1_3)
  end
  L6_2 = 1000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isHelicopter = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "is_plane_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3
    L0_3 = IsPedInAnyPlane
    L1_3 = PlayerPedId
    L1_3 = L1_3()
    return L0_3(L1_3)
  end
  L6_2 = 1000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isPlane = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "is_boat_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3
    L0_3 = IsPedInAnyBoat
    L1_3 = PlayerPedId
    L1_3 = L1_3()
    return L0_3(L1_3)
  end
  L6_2 = 1000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isBoat = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "is_submarine_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3
    L0_3 = IsPedInAnySub
    L1_3 = PlayerPedId
    L1_3 = L1_3()
    return L0_3(L1_3)
  end
  L6_2 = 1000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.isSubmarine = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "heat_multiplier_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.getVehicleClass
    L2_3 = A1_2
    L0_3 = L0_3(L1_3, L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.getBrakeUpgradeLevel
    L3_3 = A1_2
    L1_3 = L1_3(L2_3, L3_3)
    L2_3 = 1.0
    L3_3 = A0_2.config
    L3_3 = L3_3.temperatureIncrease
    if L3_3 then
      L3_3 = A0_2.config
      L3_3 = L3_3.temperatureIncrease
      L3_3 = L3_3.classes
      if L3_3 then
        L3_3 = A0_2.config
        L3_3 = L3_3.temperatureIncrease
        L3_3 = L3_3.classes
        L3_3 = L3_3[L0_3]
        L2_3 = L3_3 or L2_3
        if not L3_3 then
          L2_3 = 1.0
        end
      end
    end
    L3_3 = 1.0
    L4_3 = A0_2.config
    L4_3 = L4_3.temperatureIncrease
    if L4_3 then
      L4_3 = A0_2.config
      L4_3 = L4_3.temperatureIncrease
      L4_3 = L4_3.brakeUpgrade
      if L4_3 then
        L4_3 = A0_2.config
        L4_3 = L4_3.temperatureIncrease
        L4_3 = L4_3.brakeUpgrade
        if L1_3 then
          L5_3 = L4_3[L1_3]
          if L5_3 then
            L3_3 = L4_3[L1_3]
        end
        else
          L5_3 = -1
          L5_3 = L4_3[L5_3]
          if L5_3 then
            L5_3 = -1
            L3_3 = L4_3[L5_3]
          end
        end
      end
    end
    L4_3 = A0_2.config
    L4_3 = L4_3.temperatureRate
    if not L4_3 then
      L4_3 = 1.0
    end
    L5_3 = L2_3 * L3_3
    L5_3 = L5_3 * L4_3
    return L5_3
  end
  L6_2 = 60000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.getHeatMultiplier = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L3_2 = A0_2
  L2_2 = A0_2.getCached
  L4_2 = "cooldown_multiplier_"
  L5_2 = A1_2
  L4_2 = L4_2 .. L5_2
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
    L0_3 = A0_2
    L1_3 = L0_3
    L0_3 = L0_3.getVehicleClass
    L2_3 = A1_2
    L0_3 = L0_3(L1_3, L2_3)
    L1_3 = A0_2
    L2_3 = L1_3
    L1_3 = L1_3.getBrakeUpgradeLevel
    L3_3 = A1_2
    L1_3 = L1_3(L2_3, L3_3)
    L2_3 = 1.0
    L3_3 = A0_2.config
    L3_3 = L3_3.temperatureDecrease
    if L3_3 then
      L3_3 = A0_2.config
      L3_3 = L3_3.temperatureDecrease
      L3_3 = L3_3.classes
      if L3_3 then
        L3_3 = A0_2.config
        L3_3 = L3_3.temperatureDecrease
        L3_3 = L3_3.classes
        L3_3 = L3_3[L0_3]
        L2_3 = L3_3 or L2_3
        if not L3_3 then
          L2_3 = 1.0
        end
      end
    end
    L3_3 = 1.0
    L4_3 = A0_2.config
    L4_3 = L4_3.temperatureDecrease
    if L4_3 then
      L4_3 = A0_2.config
      L4_3 = L4_3.temperatureDecrease
      L4_3 = L4_3.brakeUpgrade
      if L4_3 then
        L4_3 = A0_2.config
        L4_3 = L4_3.temperatureDecrease
        L4_3 = L4_3.brakeUpgrade
        if L1_3 then
          L5_3 = L4_3[L1_3]
          if L5_3 then
            L3_3 = L4_3[L1_3]
        end
        else
          L5_3 = -1
          L5_3 = L4_3[L5_3]
          if L5_3 then
            L5_3 = -1
            L3_3 = L4_3[L5_3]
          end
        end
      end
    end
    L4_3 = A0_2.config
    L4_3 = L4_3.coolingRate
    if not L4_3 then
      L4_3 = 1.0
    end
    L5_3 = L2_3 * L3_3
    L5_3 = L5_3 * L4_3
    return L5_3
  end
  L6_2 = 60000
  return L2_2(L3_2, L4_2, L5_2, L6_2)
end
L0_1.getCooldownMultiplier = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GetEntitySpeedVector
  L3_2 = A1_2
  L4_2 = true
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = L2_2.y
  L4_2 = IsControlPressed
  L5_2 = 0
  L6_2 = 72
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = GetVehicleHandbrake
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L6_2 = L4_2 and L3_2 > 1.0 or L6_2
  return L6_2
end
L0_1.isActuallyBraking = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = 0.0
  L3_2 = 0.0
  L5_2 = A0_2
  L4_2 = A0_2.isActuallyBraking
  L6_2 = A1_2
  L4_2 = L4_2(L5_2, L6_2)
  if not L4_2 then
    L4_2 = {}
    L4_2.front = 0.0
    L4_2.rear = 0.0
    return L4_2
  end
  L4_2 = IsControlPressed
  L5_2 = 0
  L6_2 = 72
  L4_2 = L4_2(L5_2, L6_2)
  if L4_2 then
    L4_2 = GetEntitySpeedVector
    L5_2 = A1_2
    L6_2 = true
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = L4_2.y
    if L5_2 > 1.0 then
      L2_2 = 5.0
      L3_2 = 5.0
    end
  end
  L4_2 = GetVehicleHandbrake
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = math
    L4_2 = L4_2.max
    L5_2 = L3_2
    L6_2 = 5.0
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
  end
  L4_2 = IsVehicleInBurnout
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  if L4_2 then
    L4_2 = math
    L4_2 = L4_2.max
    L5_2 = L3_2
    L6_2 = 8.0
    L4_2 = L4_2(L5_2, L6_2)
    L3_2 = L4_2
  end
  L4_2 = {}
  L4_2.front = L2_2
  L4_2.rear = L3_2
  return L4_2
end
L0_1.getBrakingIntensity = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = Entity
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  L2_2 = L2_2.state
  L3_2 = L2_1.BRAKE_TEMP_STATE
  L2_2 = L2_2[L3_2]
  if L2_2 then
    L3_2 = L2_2.front
    if not L3_2 then
      L3_2 = 0.0
    end
    L4_2 = L2_2.rear
    if not L4_2 then
      L4_2 = 0.0
    end
    return L3_2, L4_2
  end
  L3_2 = 0.0
  L4_2 = 0.0
  return L3_2, L4_2
end
L0_1.getBrakeTemperatures = L4_1
function L4_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L4_2 = VehToNet
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = Entity
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L5_2 = L5_2.state
  L6_2 = L2_1.BRAKE_TEMP_STATE
  L5_2 = L5_2[L6_2]
  if not L5_2 then
    L5_2 = TriggerServerEvent
    L6_2 = "qs-mechanic-creator:server:createStatebag:heatedbrakes"
    L7_2 = L4_2
    L8_2 = L2_1.BRAKE_TEMP_STATE
    L9_2 = {}
    L9_2.front = A2_2
    L9_2.rear = A3_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
  else
    L5_2 = Entity
    L6_2 = A1_2
    L5_2 = L5_2(L6_2)
    L5_2 = L5_2.state
    L6_2 = L5_2
    L5_2 = L5_2.set
    L7_2 = L2_1.BRAKE_TEMP_STATE
    L8_2 = {}
    L8_2.front = A2_2
    L8_2.rear = A3_2
    L9_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2)
  end
end
L0_1.setBrakeTemperatures = L4_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = GetVehiclePedIsIn
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.isVehicleBlacklisted
  L4_2 = L1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.getBrakeTemperatures
  L4_2 = L1_2
  L2_2, L3_2 = L2_2(L3_2, L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.getBrakingIntensity
  L6_2 = L1_2
  L4_2 = L4_2(L5_2, L6_2)
  L6_2 = A0_2
  L5_2 = A0_2.getHeatMultiplier
  L7_2 = L1_2
  L5_2 = L5_2(L6_2, L7_2)
  L7_2 = A0_2
  L6_2 = A0_2.getCooldownMultiplier
  L8_2 = L1_2
  L6_2 = L6_2(L7_2, L8_2)
  L8_2 = A0_2
  L7_2 = A0_2.getVehicleSpeed
  L9_2 = L1_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = math
  L8_2 = L8_2.min
  L9_2 = L2_1.MAX_AIRFLOW_SPEED
  L9_2 = L7_2 / L9_2
  L10_2 = L2_1.MAX_AIRFLOW_COOLING
  L8_2 = L8_2(L9_2, L10_2)
  L9_2 = L2_2
  L10_2 = L3_2
  L11_2 = L4_2.front
  if L11_2 > 0.0 then
    L11_2 = math
    L11_2 = L11_2.min
    L12_2 = L2_1.MAX_TEMPERATURE
    L13_2 = L4_2.front
    L13_2 = L13_2 * L5_2
    L13_2 = L2_2 + L13_2
    L11_2 = L11_2(L12_2, L13_2)
    L2_2 = L11_2
  else
    L11_2 = L2_1.BASE_COOLING_RATE
    L12_2 = L2_1.AIRFLOW_MULTIPLIER
    L12_2 = L8_2 * L12_2
    L11_2 = L11_2 + L12_2
    L11_2 = L11_2 * L6_2
    L12_2 = math
    L12_2 = L12_2.max
    L13_2 = L2_1.MIN_TEMPERATURE
    L14_2 = L2_2 - L11_2
    L12_2 = L12_2(L13_2, L14_2)
    L2_2 = L12_2
  end
  L11_2 = L4_2.rear
  if L11_2 > 0.0 then
    L11_2 = math
    L11_2 = L11_2.min
    L12_2 = L2_1.MAX_TEMPERATURE
    L13_2 = L4_2.rear
    L13_2 = L13_2 * L5_2
    L13_2 = L3_2 + L13_2
    L11_2 = L11_2(L12_2, L13_2)
    L3_2 = L11_2
  else
    L11_2 = L2_1.BASE_COOLING_RATE
    L12_2 = L2_1.AIRFLOW_MULTIPLIER
    L12_2 = L8_2 * L12_2
    L11_2 = L11_2 + L12_2
    L11_2 = L11_2 * L6_2
    L12_2 = math
    L12_2 = L12_2.max
    L13_2 = L2_1.MIN_TEMPERATURE
    L14_2 = L3_2 - L11_2
    L12_2 = L12_2(L13_2, L14_2)
    L3_2 = L12_2
  end
  L11_2 = math
  L11_2 = L11_2.abs
  L12_2 = L2_2 - L9_2
  L11_2 = L11_2(L12_2)
  L12_2 = math
  L12_2 = L12_2.abs
  L13_2 = L3_2 - L10_2
  L12_2 = L12_2(L13_2)
  L13_2 = L2_1.MIN_TEMP_CHANGE
  if not (L11_2 > L13_2) then
    L13_2 = L2_1.MIN_TEMP_CHANGE
    if not (L12_2 > L13_2) then
      goto lbl_121
    end
  end
  L14_2 = A0_2
  L13_2 = A0_2.setBrakeTemperatures
  L15_2 = L1_2
  L16_2 = L2_2
  L17_2 = L3_2
  L13_2(L14_2, L15_2, L16_2, L17_2)
  ::lbl_121::
end
L0_1.updateBrakeTemperatures = L4_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = GetVehiclePedIsIn
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.isVehicleBlacklisted
  L4_2 = L1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.getBrakeTemperatures
  L4_2 = L1_2
  L2_2, L3_2 = L2_2(L3_2, L4_2)
  L4_2 = math
  L4_2 = L4_2.max
  L5_2 = L2_2
  L6_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2)
  L5_2 = L2_1.FADE_START_TEMP
  if L4_2 > L5_2 then
    L5_2 = A0_2.config
    L5_2 = L5_2.performanceLoss
    if not L5_2 then
      L5_2 = 1.0
    end
    L6_2 = L2_1.FADE_START_TEMP
    L6_2 = L4_2 - L6_2
    L6_2 = L6_2 / 200.0
    L6_2 = L6_2 * L5_2
    L7_2 = math
    L7_2 = L7_2.max
    L8_2 = L2_1.MIN_BRAKE_FORCE
    L9_2 = L2_1.DEFAULT_BRAKE_FORCE
    L9_2 = L9_2 - L6_2
    L7_2 = L7_2(L8_2, L9_2)
    L8_2 = math
    L8_2 = L8_2.abs
    L9_2 = A0_2.lastBrakeForce
    L9_2 = L7_2 - L9_2
    L8_2 = L8_2(L9_2)
    L9_2 = 0.01
    if L8_2 > L9_2 then
      L8_2 = SetVehicleHandlingFloat
      L9_2 = L1_2
      L10_2 = "CHandlingData"
      L11_2 = "fBrakeForce"
      L12_2 = L7_2
      L8_2(L9_2, L10_2, L11_2, L12_2)
      A0_2.lastBrakeForce = L7_2
    end
  else
    L5_2 = A0_2.lastBrakeForce
    L6_2 = L2_1.DEFAULT_BRAKE_FORCE
    if L5_2 < L6_2 then
      L5_2 = SetVehicleHandlingFloat
      L6_2 = L1_2
      L7_2 = "CHandlingData"
      L8_2 = "fBrakeForce"
      L9_2 = L2_1.DEFAULT_BRAKE_FORCE
      L5_2(L6_2, L7_2, L8_2, L9_2)
      L5_2 = L2_1.DEFAULT_BRAKE_FORCE
      A0_2.lastBrakeForce = L5_2
    end
  end
end
L0_1.applyBrakeFade = L4_1
function L4_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L4_2 = A0_2
  L3_2 = A0_2.getVehicleClass
  L5_2 = A1_2
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = GetEntityModel
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  L5_2 = GetDisplayNameFromVehicleModel
  L6_2 = L4_2
  L5_2 = L5_2(L6_2)
  L6_2 = L5_2
  L5_2 = L5_2.lower
  L5_2 = L5_2(L6_2)
  L6_2 = "wheel_lf" == A2_2 or "wheel_rf" == A2_2
  L7_2 = 0.45
  L8_2 = 0.0
  L9_2 = 0.0
  L10_2 = 0.0
  L11_2 = {}
  L12_2 = {}
  L12_2.scale = 0.42
  L12_2.offset = 0.0
  L11_2[0] = L12_2
  L12_2 = {}
  L12_2.scale = 0.45
  L12_2.offset = 0.0
  L11_2[1] = L12_2
  L12_2 = {}
  L12_2.scale = 0.48
  L12_2.offset = 0.02
  L11_2[2] = L12_2
  L12_2 = {}
  L12_2.scale = 0.44
  L12_2.offset = 0.0
  L11_2[3] = L12_2
  L12_2 = {}
  L12_2.scale = 0.46
  L12_2.offset = 0.0
  L11_2[4] = L12_2
  L12_2 = {}
  L12_2.scale = 0.44
  L12_2.offset = 0.0
  L11_2[5] = L12_2
  L12_2 = {}
  L12_2.scale = 0.44
  L12_2.offset = 0.0
  L11_2[6] = L12_2
  L12_2 = {}
  L12_2.scale = 0.46
  L12_2.offset = 0.0
  L11_2[7] = L12_2
  L12_2 = {}
  L12_2.scale = 0.28
  L12_2.offset = 0.0
  L11_2[8] = L12_2
  L12_2 = {}
  L12_2.scale = 0.52
  L12_2.offset = 0.02
  L11_2[9] = L12_2
  L12_2 = {}
  L12_2.scale = 0.58
  L12_2.offset = 0.03
  L11_2[10] = L12_2
  L12_2 = {}
  L12_2.scale = 0.52
  L12_2.offset = 0.02
  L11_2[11] = L12_2
  L12_2 = {}
  L12_2.scale = 0.54
  L12_2.offset = 0.02
  L11_2[12] = L12_2
  L12_2 = {}
  L12_2.scale = 0.22
  L12_2.offset = 0.0
  L11_2[13] = L12_2
  L12_2 = {}
  L12_2.scale = 0.0
  L12_2.offset = 0.0
  L11_2[14] = L12_2
  L12_2 = {}
  L12_2.scale = 0.0
  L12_2.offset = 0.0
  L11_2[15] = L12_2
  L12_2 = {}
  L12_2.scale = 0.0
  L12_2.offset = 0.0
  L11_2[16] = L12_2
  L12_2 = {}
  L12_2.scale = 0.52
  L12_2.offset = 0.02
  L11_2[17] = L12_2
  L12_2 = {}
  L12_2.scale = 0.52
  L12_2.offset = 0.02
  L11_2[18] = L12_2
  L12_2 = {}
  L12_2.scale = 0.62
  L12_2.offset = 0.03
  L11_2[19] = L12_2
  L12_2 = {}
  L12_2.scale = 0.62
  L12_2.offset = 0.03
  L11_2[20] = L12_2
  L12_2 = {}
  L12_2.scale = 0.0
  L12_2.offset = 0.0
  L11_2[21] = L12_2
  L12_2 = L11_2[L3_2]
  if L12_2 then
    L12_2 = L11_2[L3_2]
    L7_2 = L12_2.scale
    L12_2 = L11_2[L3_2]
    L8_2 = L12_2.offset
  end
  if not L6_2 and (6 == L3_2 or 7 == L3_2 or 4 == L3_2) then
    L7_2 = L7_2 * 0.92
  end
  L12_2 = A0_2.config
  L12_2 = L12_2.vehicleOverrides
  if not L12_2 then
    L12_2 = {}
  end
  L13_2 = L12_2[L5_2]
  if L13_2 then
    L13_2 = L12_2[L5_2]
    L13_2 = L13_2[A2_2]
    if L13_2 then
      L13_2 = L12_2[L5_2]
      L13_2 = L13_2[A2_2]
      L14_2 = L13_2.scale
      L7_2 = L14_2 or L7_2
      if not L14_2 then
      end
      L14_2 = L13_2.offsetX
      L8_2 = L14_2 or L8_2
      if not L14_2 then
      end
      L14_2 = L13_2.offsetY
      L9_2 = L14_2 or L9_2
      if not L14_2 then
      end
      L14_2 = L13_2.offsetZ
      L10_2 = L14_2 or L10_2
      if not L14_2 then
      end
    end
  end
  L13_2 = L7_2
  L14_2 = L8_2
  L15_2 = L9_2
  L16_2 = L10_2
  return L13_2, L14_2, L15_2, L16_2
end
L0_1.getWheelBoneTransform = L4_1
function L4_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2
  L4_2 = lib
  L4_2 = L4_2.requestNamedPtfxAsset
  L5_2 = "core"
  L4_2(L5_2)
  L4_2 = GetEntityBoneIndexByName
  L5_2 = A1_2
  L6_2 = A2_2
  L4_2 = L4_2(L5_2, L6_2)
  if -1 == L4_2 then
    return
  end
  L5_2 = A0_2.trackedVehicles
  L5_2 = L5_2[A1_2]
  if L5_2 then
    L5_2 = A0_2.trackedVehicles
    L5_2 = L5_2[A1_2]
    L5_2 = L5_2.effects
    if L5_2 then
      L5_2 = A0_2.trackedVehicles
      L5_2 = L5_2[A1_2]
      L5_2 = L5_2.effects
      L5_2 = L5_2[A2_2]
    end
  end
  L6_2 = L2_1.GLOW_THRESHOLD
  if A3_2 > L6_2 then
    if L5_2 then
      L6_2 = DoesParticleFxLoopedExist
      L7_2 = L5_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        goto lbl_133
      end
    end
    L7_2 = A0_2
    L6_2 = A0_2.getWheelBoneTransform
    L8_2 = A1_2
    L9_2 = A2_2
    L6_2, L7_2, L8_2, L9_2 = L6_2(L7_2, L8_2, L9_2)
    L10_2 = 0.0
    L11_2 = 0.0
    L12_2 = 90.0
    L13_2 = 1.0
    L14_2 = A0_2.config
    L14_2 = L14_2.visual
    if L14_2 then
      L14_2 = A0_2.config
      L14_2 = L14_2.visual
      L14_2 = L14_2.glow
      if L14_2 then
        L14_2 = A0_2.config
        L14_2 = L14_2.visual
        L14_2 = L14_2.glow
        L14_2 = L14_2.strength
        L13_2 = L14_2 or L13_2
        if not L14_2 then
          L13_2 = 1.0
        end
      end
    end
    L14_2 = UseParticleFxAssetNextCall
    L15_2 = "core"
    L14_2(L15_2)
    L14_2 = StartParticleFxLoopedOnEntityBone
    L15_2 = L2_1.PARTICLE_EFFECT
    L16_2 = A1_2
    L17_2 = L7_2
    L18_2 = L8_2
    L19_2 = L9_2
    L20_2 = L10_2
    L21_2 = L11_2
    L22_2 = L12_2
    L23_2 = L4_2
    L24_2 = L6_2 * L13_2
    L25_2 = false
    L26_2 = false
    L27_2 = false
    L14_2 = L14_2(L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2)
    L15_2 = SetParticleFxLoopedColour
    L16_2 = L14_2
    L17_2 = L2_1.PARTICLE_COLOR
    L17_2 = L17_2[1]
    L18_2 = L2_1.PARTICLE_COLOR
    L18_2 = L18_2[2]
    L19_2 = L2_1.PARTICLE_COLOR
    L19_2 = L19_2[3]
    L20_2 = true
    L15_2(L16_2, L17_2, L18_2, L19_2, L20_2)
    L15_2 = L2_1.PARTICLE_ALPHA
    L16_2 = L2_1.GLOW_THRESHOLD
    L16_2 = L16_2 + 50
    if A3_2 < L16_2 then
      L16_2 = L2_1.GLOW_THRESHOLD
      L16_2 = A3_2 - L16_2
      L16_2 = L16_2 / 50
      L17_2 = L2_1.PARTICLE_ALPHA
      L15_2 = L16_2 * L17_2
    end
    L16_2 = SetParticleFxLoopedAlpha
    L17_2 = L14_2
    L18_2 = L15_2
    L16_2(L17_2, L18_2)
    L16_2 = A0_2.trackedVehicles
    L16_2 = L16_2[A1_2]
    if not L16_2 then
      L16_2 = A0_2.trackedVehicles
      L17_2 = {}
      L18_2 = {}
      L17_2.effects = L18_2
      L16_2[A1_2] = L17_2
    else
      L16_2 = A0_2.trackedVehicles
      L16_2 = L16_2[A1_2]
      L16_2 = L16_2.effects
      if not L16_2 then
        L16_2 = A0_2.trackedVehicles
        L16_2 = L16_2[A1_2]
        L17_2 = {}
        L16_2.effects = L17_2
      end
    end
    L16_2 = A0_2.trackedVehicles
    L16_2 = L16_2[A1_2]
    L16_2 = L16_2.effects
    L16_2[A2_2] = L14_2
    goto lbl_180
    ::lbl_133::
    L6_2 = L2_1.PARTICLE_ALPHA
    L7_2 = L2_1.GLOW_THRESHOLD
    L7_2 = L7_2 + 50
    if A3_2 < L7_2 then
      L7_2 = L2_1.GLOW_THRESHOLD
      L7_2 = A3_2 - L7_2
      L7_2 = L7_2 / 50
      L8_2 = L2_1.PARTICLE_ALPHA
      L6_2 = L7_2 * L8_2
    end
    L7_2 = SetParticleFxLoopedAlpha
    L8_2 = L5_2
    L9_2 = L6_2
    L7_2(L8_2, L9_2)
  elseif L5_2 then
    L6_2 = DoesParticleFxLoopedExist
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = StopParticleFxLooped
      L7_2 = L5_2
      L8_2 = 1
      L6_2(L7_2, L8_2)
      L6_2 = RemoveParticleFx
      L7_2 = L5_2
      L8_2 = false
      L6_2(L7_2, L8_2)
      L6_2 = A0_2.trackedVehicles
      L6_2 = L6_2[A1_2]
      if L6_2 then
        L6_2 = A0_2.trackedVehicles
        L6_2 = L6_2[A1_2]
        L6_2 = L6_2.effects
        if L6_2 then
          L6_2 = A0_2.trackedVehicles
          L6_2 = L6_2[A1_2]
          L6_2 = L6_2.effects
          L6_2[A2_2] = nil
        end
      end
    end
  end
  ::lbl_180::
end
L0_1.manageDiscGlow = L4_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = GetVehiclePedIsIn
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = false
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.isVehicleBlacklisted
  L4_2 = L1_2
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    return
  end
  L3_2 = A0_2
  L2_2 = A0_2.getBrakeTemperatures
  L4_2 = L1_2
  L2_2, L3_2 = L2_2(L3_2, L4_2)
  L5_2 = A0_2
  L4_2 = A0_2.manageDiscGlow
  L6_2 = L1_2
  L7_2 = L2_1.WHEEL_BONES
  L7_2 = L7_2[1]
  L8_2 = L2_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.manageDiscGlow
  L6_2 = L1_2
  L7_2 = L2_1.WHEEL_BONES
  L7_2 = L7_2[2]
  L8_2 = L2_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.manageDiscGlow
  L6_2 = L1_2
  L7_2 = L2_1.WHEEL_BONES
  L7_2 = L7_2[3]
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = A0_2
  L4_2 = A0_2.manageDiscGlow
  L6_2 = L1_2
  L7_2 = L2_1.WHEEL_BONES
  L7_2 = L7_2[4]
  L8_2 = L3_2
  L4_2(L5_2, L6_2, L7_2, L8_2)
end
L0_1.updateVisualEffects = L4_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L1_2 = GetEntityCoords
  L2_2 = PlayerPedId
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2 = L2_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  L2_2 = GetGamePool
  L3_2 = "CVehicle"
  L2_2 = L2_2(L3_2)
  L3_2 = 10
  L4_2 = 0
  L5_2 = ipairs
  L6_2 = L2_2
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    if L3_2 <= L4_2 then
      break
    end
    L11_2 = DoesEntityExist
    L12_2 = L10_2
    L11_2 = L11_2(L12_2)
    if L11_2 then
      L11_2 = A0_2.currentVehicle
      if L10_2 ~= L11_2 then
        L11_2 = GetEntityCoords
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        L11_2 = L11_2 - L1_2
        L11_2 = #L11_2
        L12_2 = L2_1.NEARBY_VEHICLE_RANGE
        if L11_2 < L12_2 then
          L13_2 = A0_2
          L12_2 = A0_2.isVehicleBlacklisted
          L14_2 = L10_2
          L12_2 = L12_2(L13_2, L14_2)
          if not L12_2 then
            L4_2 = L4_2 + 1
            L13_2 = A0_2
            L12_2 = A0_2.getBrakeTemperatures
            L14_2 = L10_2
            L12_2, L13_2 = L12_2(L13_2, L14_2)
            L14_2 = L2_1.GLOW_THRESHOLD
            if not (L12_2 > L14_2) then
              L14_2 = L2_1.GLOW_THRESHOLD
              if not (L13_2 > L14_2) then
                goto lbl_93
              end
            end
            L14_2 = A0_2.trackedVehicles
            L14_2 = L14_2[L10_2]
            if not L14_2 then
              L14_2 = A0_2.trackedVehicles
              L15_2 = {}
              L16_2 = GetGameTimer
              L16_2 = L16_2()
              L15_2.lastUpdate = L16_2
              L16_2 = {}
              L15_2.effects = L16_2
              L14_2[L10_2] = L15_2
            else
              L14_2 = A0_2.trackedVehicles
              L14_2 = L14_2[L10_2]
              L15_2 = GetGameTimer
              L15_2 = L15_2()
              L14_2.lastUpdate = L15_2
            end
            L15_2 = A0_2
            L14_2 = A0_2.manageDiscGlow
            L16_2 = L10_2
            L17_2 = L2_1.WHEEL_BONES
            L17_2 = L17_2[1]
            L18_2 = L12_2
            L14_2(L15_2, L16_2, L17_2, L18_2)
            L15_2 = A0_2
            L14_2 = A0_2.manageDiscGlow
            L16_2 = L10_2
            L17_2 = L2_1.WHEEL_BONES
            L17_2 = L17_2[2]
            L18_2 = L12_2
            L14_2(L15_2, L16_2, L17_2, L18_2)
            L15_2 = A0_2
            L14_2 = A0_2.manageDiscGlow
            L16_2 = L10_2
            L17_2 = L2_1.WHEEL_BONES
            L17_2 = L17_2[3]
            L18_2 = L13_2
            L14_2(L15_2, L16_2, L17_2, L18_2)
            L15_2 = A0_2
            L14_2 = A0_2.manageDiscGlow
            L16_2 = L10_2
            L17_2 = L2_1.WHEEL_BONES
            L17_2 = L17_2[4]
            L18_2 = L13_2
            L14_2(L15_2, L16_2, L17_2, L18_2)
          end
        end
      end
    end
    ::lbl_93::
  end
end
L0_1.updateNearbyVehicleEffects = L4_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L1_2 = pairs
  L2_2 = A0_2.trackedVehicles
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = DoesEntityExist
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L8_2 = A0_2
      L7_2 = A0_2.getBrakeTemperatures
      L9_2 = L5_2
      L7_2, L8_2 = L7_2(L8_2, L9_2)
      if L7_2 and L8_2 then
        L10_2 = A0_2
        L9_2 = A0_2.getVehicleSpeed
        L11_2 = L5_2
        L9_2 = L9_2(L10_2, L11_2)
        L11_2 = A0_2
        L10_2 = A0_2.getCooldownMultiplier
        L12_2 = L5_2
        L10_2 = L10_2(L11_2, L12_2)
        L11_2 = math
        L11_2 = L11_2.min
        L12_2 = L2_1.MAX_AIRFLOW_SPEED
        L12_2 = L9_2 / L12_2
        L13_2 = L2_1.MAX_AIRFLOW_COOLING
        L11_2 = L11_2(L12_2, L13_2)
        L12_2 = L2_1.BASE_COOLING_RATE
        L13_2 = L2_1.AIRFLOW_MULTIPLIER
        L13_2 = L11_2 * L13_2
        L12_2 = L12_2 + L13_2
        L12_2 = L12_2 * L10_2
        L13_2 = math
        L13_2 = L13_2.max
        L14_2 = L2_1.MIN_TEMPERATURE
        L15_2 = L7_2 - L12_2
        L13_2 = L13_2(L14_2, L15_2)
        L7_2 = L13_2
        L13_2 = math
        L13_2 = L13_2.max
        L14_2 = L2_1.MIN_TEMPERATURE
        L15_2 = L8_2 - L12_2
        L13_2 = L13_2(L14_2, L15_2)
        L8_2 = L13_2
        L14_2 = A0_2
        L13_2 = A0_2.setBrakeTemperatures
        L15_2 = L5_2
        L16_2 = L7_2
        L17_2 = L8_2
        L13_2(L14_2, L15_2, L16_2, L17_2)
      end
    end
  end
end
L0_1.updateVehicleTemperatures = L4_1
function L4_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A1_2 or 0 == A1_2 then
    return
  end
  L2_2 = L1_1
  L2_2 = L2_2[A1_2]
  if L2_2 then
    return
  end
  L2_2 = L1_1
  L2_2[A1_2] = true
  L2_2 = A0_2.trackedVehicles
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = A0_2.trackedVehicles
    L2_2 = L2_2[A1_2]
    L2_2 = L2_2.effects
    if L2_2 then
      L2_2 = pairs
      L3_2 = A0_2.trackedVehicles
      L3_2 = L3_2[A1_2]
      L3_2 = L3_2.effects
      L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
      for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
        L8_2 = DoesParticleFxLoopedExist
        L9_2 = L7_2
        L8_2 = L8_2(L9_2)
        if L8_2 then
          L8_2 = StopParticleFxLooped
          L9_2 = L7_2
          L10_2 = 1
          L8_2(L9_2, L10_2)
          L8_2 = RemoveParticleFx
          L9_2 = L7_2
          L10_2 = true
          L8_2(L9_2, L10_2)
        end
      end
      L2_2 = A0_2.trackedVehicles
      L2_2 = L2_2[A1_2]
      L3_2 = {}
      L2_2.effects = L3_2
    end
  end
  L2_2 = DoesEntityExist
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  if L2_2 then
    L2_2 = pcall
    function L3_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3
      L0_3 = VehToNet
      L1_3 = A1_2
      L0_3 = L0_3(L1_3)
      L1_3 = Entity
      L2_3 = A1_2
      L1_3 = L1_3(L2_3)
      L1_3 = L1_3.state
      L2_3 = L2_1.BRAKE_TEMP_STATE
      L1_3 = L1_3[L2_3]
      if not L1_3 then
        L1_3 = TriggerServerEvent
        L2_3 = "qs-mechanic-creator:server:createStatebag:heatedbrakes"
        L3_3 = L0_3
        L4_3 = L2_1.BRAKE_TEMP_STATE
        L5_3 = {}
        L5_3.front = 0.0
        L5_3.rear = 0.0
        L1_3(L2_3, L3_3, L4_3, L5_3)
      else
        L1_3 = Entity
        L2_3 = A1_2
        L1_3 = L1_3(L2_3)
        L1_3 = L1_3.state
        L2_3 = L1_3
        L1_3 = L1_3.set
        L3_3 = L2_1.BRAKE_TEMP_STATE
        L4_3 = {}
        L4_3.front = 0.0
        L4_3.rear = 0.0
        L5_3 = true
        L1_3(L2_3, L3_3, L4_3, L5_3)
      end
    end
    L2_2(L3_2)
  end
  L2_2 = A0_2.trackedVehicles
  L2_2 = L2_2[A1_2]
  if L2_2 then
    L2_2 = A0_2.trackedVehicles
    L2_2[A1_2] = nil
  end
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3
    L0_3 = Wait
    L1_3 = 100
    L0_3(L1_3)
    L1_3 = A1_2
    L0_3 = L1_1
    L0_3[L1_3] = nil
  end
  L2_2(L3_2)
end
L0_1.cleanupVehicleEffects = L4_1
L4_1 = false
L5_1 = false
function L6_1(A0_2)
  local L1_2, L2_2
  L1_2 = L4_1
  if L1_2 then
    return
  end
  L1_2 = true
  L4_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3
    while true do
      L0_3 = A0_2.isInitialized
      if L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 100
      L0_3(L1_3)
    end
    while true do
      L0_3 = L4_1
      if L0_3 then
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3.isActive
        L0_3 = L0_3(L1_3)
        if L0_3 then
          goto lbl_20
        end
      end
      L0_3 = Wait
      L1_3 = 1000
      L0_3(L1_3)
      goto lbl_144
      ::lbl_20::
      L0_3 = L2_1.UPDATE_INTERVAL
      L1_3 = PlayerPedId
      L1_3 = L1_3()
      L2_3 = IsPedInAnyVehicle
      L3_3 = L1_3
      L4_3 = false
      L2_3 = L2_3(L3_3, L4_3)
      L3_3 = GetVehiclePedIsIn
      L4_3 = L1_3
      L5_3 = false
      L3_3 = L3_3(L4_3, L5_3)
      L4_3 = GetPedInVehicleSeat
      L5_3 = L3_3
      L6_3 = -1
      L4_3 = L4_3(L5_3, L6_3)
      L4_3 = L4_3 == L1_3
      if L2_3 and L4_3 then
        L5_3 = A0_2
        L6_3 = L5_3
        L5_3 = L5_3.isHelicopter
        L7_3 = L3_3
        L5_3 = L5_3(L6_3, L7_3)
        if not L5_3 then
          L5_3 = A0_2
          L6_3 = L5_3
          L5_3 = L5_3.isPlane
          L7_3 = L3_3
          L5_3 = L5_3(L6_3, L7_3)
          if not L5_3 then
            L5_3 = A0_2
            L6_3 = L5_3
            L5_3 = L5_3.isBoat
            L7_3 = L3_3
            L5_3 = L5_3(L6_3, L7_3)
            if not L5_3 then
              L5_3 = A0_2
              L6_3 = L5_3
              L5_3 = L5_3.isSubmarine
              L7_3 = L3_3
              L5_3 = L5_3(L6_3, L7_3)
              if not L5_3 then
                L5_3 = A0_2.currentVehicle
                if L3_3 ~= L5_3 then
                  L5_3 = DoesEntityExist
                  L6_3 = A0_2.currentVehicle
                  L5_3 = L5_3(L6_3)
                  if L5_3 then
                    L5_3 = A0_2
                    L6_3 = L5_3
                    L5_3 = L5_3.cleanupVehicleEffects
                    L7_3 = A0_2.currentVehicle
                    L5_3(L6_3, L7_3)
                  end
                  A0_2.currentVehicle = L3_3
                  L5_3 = L2_1.DEFAULT_BRAKE_FORCE
                  A0_2.lastBrakeForce = L5_3
                  L5_3 = A0_2
                  L6_3 = L5_3
                  L5_3 = L5_3.setBrakeTemperatures
                  L7_3 = L3_3
                  L8_3 = 0.0
                  L9_3 = 0.0
                  L5_3(L6_3, L7_3, L8_3, L9_3)
                  L5_3 = A0_2
                  L6_3 = L5_3
                  L5_3 = L5_3.cleanupVehicleEffects
                  L7_3 = L3_3
                  L5_3(L6_3, L7_3)
                  L5_3 = ipairs
                  L6_3 = L2_1.WHEEL_BONES
                  L5_3, L6_3, L7_3, L8_3 = L5_3(L6_3)
                  for L9_3, L10_3 in L5_3, L6_3, L7_3, L8_3 do
                    L11_3 = GetEntityBoneIndexByName
                    L12_3 = L3_3
                    L13_3 = L10_3
                    L11_3 = L11_3(L12_3, L13_3)
                    if -1 ~= L11_3 then
                      L12_3 = RemoveParticleFxFromEntity
                      L13_3 = L3_3
                      L12_3(L13_3)
                    end
                  end
                end
                L5_3 = A0_2
                L6_3 = L5_3
                L5_3 = L5_3.updateBrakeTemperatures
                L5_3(L6_3)
                L5_3 = A0_2
                L6_3 = L5_3
                L5_3 = L5_3.applyBrakeFade
                L5_3(L6_3)
                L5_3 = A0_2
                L6_3 = L5_3
                L5_3 = L5_3.updateVisualEffects
                L5_3(L6_3)
                L0_3 = L2_1.UPDATE_INTERVAL
            end
          end
        end
      end
      else
        L5_3 = A0_2.currentVehicle
        if 0 ~= L5_3 then
          L5_3 = A0_2.currentVehicle
          L6_3 = DoesEntityExist
          L7_3 = L5_3
          L6_3 = L6_3(L7_3)
          if L6_3 then
            L6_3 = A0_2.lastBrakeForce
            L7_3 = L2_1.DEFAULT_BRAKE_FORCE
            if L6_3 < L7_3 then
              L6_3 = SetVehicleHandlingFloat
              L7_3 = L5_3
              L8_3 = "CHandlingData"
              L9_3 = "fBrakeForce"
              L10_3 = L2_1.DEFAULT_BRAKE_FORCE
              L6_3(L7_3, L8_3, L9_3, L10_3)
            end
          end
          A0_2.currentVehicle = 0
          L6_3 = L2_1.DEFAULT_BRAKE_FORCE
          A0_2.lastBrakeForce = L6_3
        end
      end
      L5_3 = Wait
      L6_3 = L0_3
      L5_3(L6_3)
      ::lbl_144::
    end
  end
  L1_2(L2_2)
end
L0_1.startMainThread = L6_1
function L6_1(A0_2)
  local L1_2, L2_2
  L1_2 = L5_1
  if L1_2 then
    return
  end
  L1_2 = true
  L5_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3
    while true do
      L0_3 = A0_2.isInitialized
      if L0_3 then
        break
      end
      L0_3 = Wait
      L1_3 = 100
      L0_3(L1_3)
    end
    while true do
      L0_3 = L5_1
      if L0_3 then
        L0_3 = A0_2
        L1_3 = L0_3
        L0_3 = L0_3.isActive
        L0_3 = L0_3(L1_3)
        if L0_3 then
          goto lbl_20
        end
      end
      L0_3 = Wait
      L1_3 = 1000
      L0_3(L1_3)
      goto lbl_122
      ::lbl_20::
      L0_3 = Wait
      L1_3 = 500
      L0_3(L1_3)
      L0_3 = A0_2
      L1_3 = L0_3
      L0_3 = L0_3.updateVehicleTemperatures
      L0_3(L1_3)
      L0_3 = A0_2.config
      L0_3 = L0_3.visual
      if L0_3 then
        L0_3 = A0_2.config
        L0_3 = L0_3.visual
        L0_3 = L0_3.glow
        if L0_3 then
          L0_3 = A0_2.config
          L0_3 = L0_3.visual
          L0_3 = L0_3.glow
          L0_3 = L0_3.enabled
          if L0_3 then
            L0_3 = A0_2
            L1_3 = L0_3
            L0_3 = L0_3.updateNearbyVehicleEffects
            L0_3(L1_3)
          end
        end
      end
      L0_3 = pairs
      L1_3 = A0_2.trackedVehicles
      L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3)
      for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
        L6_3 = A0_2
        L7_3 = L6_3
        L6_3 = L6_3.getBrakeTemperatures
        L8_3 = L4_3
        L6_3, L7_3 = L6_3(L7_3, L8_3)
        L8_3 = false
        L9_3 = L5_3.effects
        if L9_3 then
          L9_3 = pairs
          L10_3 = L5_3.effects
          L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3)
          for L13_3, L14_3 in L9_3, L10_3, L11_3, L12_3 do
            L15_3 = DoesParticleFxLoopedExist
            L16_3 = L14_3
            L15_3 = L15_3(L16_3)
            if L15_3 then
              L8_3 = true
              break
            end
          end
        end
        L9_3 = false
        L10_3 = DoesEntityExist
        L11_3 = L4_3
        L10_3 = L10_3(L11_3)
        if not L10_3 then
          L9_3 = true
        else
          L10_3 = A0_2.currentVehicle
          if L4_3 ~= L10_3 then
            L10_3 = GetEntityCoords
            L11_3 = PlayerPedId
            L11_3, L12_3, L13_3, L14_3, L15_3, L16_3 = L11_3()
            L10_3 = L10_3(L11_3, L12_3, L13_3, L14_3, L15_3, L16_3)
            L11_3 = GetEntityCoords
            L12_3 = L4_3
            L11_3 = L11_3(L12_3)
            L12_3 = L11_3 - L10_3
            L12_3 = #L12_3
            if L8_3 then
              L13_3 = L2_1.EFFECT_CLEANUP_RANGE
            else
              L13_3 = L2_1.NEARBY_VEHICLE_RANGE
            end
            if L12_3 > L13_3 then
              L9_3 = true
            end
          end
        end
        L10_3 = L2_1.GLOW_THRESHOLD
        if L6_3 <= L10_3 then
          L10_3 = L2_1.GLOW_THRESHOLD
          if L7_3 <= L10_3 and L8_3 then
            L9_3 = true
          end
        end
        if L9_3 then
          L10_3 = A0_2
          L11_3 = L10_3
          L10_3 = L10_3.cleanupVehicleEffects
          L12_3 = L4_3
          L10_3(L11_3, L12_3)
          L10_3 = A0_2.trackedVehicles
          L10_3[L4_3] = nil
        end
      end
      ::lbl_122::
    end
  end
  L1_2(L2_2)
end
L0_1.startCleanupThread = L6_1
L7_1 = L0_1
L6_1 = L0_1.new
L6_1 = L6_1(L7_1)
L7_1 = RegisterNetEvent
L8_1 = "qs-mechanic-creator:client:setHeatedBrakes"
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = L6_1
  L2_2 = L1_2
  L1_2 = L1_2.isActive
  L1_2 = L1_2(L2_2)
  L2_2 = L6_1
  L3_2 = L2_2
  L2_2 = L2_2.updateConfig
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = L6_1
  L3_2 = L2_2
  L2_2 = L2_2.initialize
  L2_2(L3_2)
  L2_2 = L6_1
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
    L6_2 = "qs-mechanic:client:startHeatedBrakes"
    L5_2(L6_2)
  elseif not L2_2 and L1_2 then
    L5_2 = TriggerEvent
    L6_2 = "qs-mechanic:client:stopHeatedBrakes"
    L5_2(L6_2)
  end
end
L7_1(L8_1, L9_1)
L7_1 = CreateThread
function L8_1()
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
    L2_2 = L6_1.isInitialized
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
      L3_3 = "heatedbrakes"
      return L0_3(L1_3, L2_3, L3_3)
    end
    L2_2, L3_2 = L2_2(L3_2)
    if L2_2 and L3_2 then
      L4_2 = L6_1
      L5_2 = L4_2
      L4_2 = L4_2.updateConfig
      L6_2 = L3_2
      L4_2(L5_2, L6_2)
      L4_2 = L6_1
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
  L2_2 = L6_1.isInitialized
  if not L2_2 then
    L2_2 = L6_1
    L3_2 = L2_2
    L2_2 = L2_2.updateConfig
    L4_2 = L3_1
    L2_2(L3_2, L4_2)
    L2_2 = L6_1
    L3_2 = L2_2
    L2_2 = L2_2.initialize
    L2_2(L3_2)
  end
end
L7_1(L8_1)
L7_1 = RegisterNetEvent
L8_1 = "qs-mechanic:client:startHeatedBrakes"
function L9_1()
  local L0_2, L1_2
  L0_2 = L6_1
  if L0_2 then
    L0_2 = L6_1
    L1_2 = L0_2
    L0_2 = L0_2.isActive
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = true
      L4_1 = L0_2
      L0_2 = true
      L5_1 = L0_2
    end
  end
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "qs-mechanic:client:stopHeatedBrakes"
function L9_1()
  local L0_2, L1_2
  L0_2 = false
  L4_1 = L0_2
  L0_2 = false
  L5_1 = L0_2
end
L7_1(L8_1, L9_1)
L8_1 = L6_1
L7_1 = L6_1.startMainThread
L7_1(L8_1)
L8_1 = L6_1
L7_1 = L6_1.startCleanupThread
L7_1(L8_1)
L7_1 = AddStateBagChangeHandler
L8_1 = L2_1.BRAKE_TEMP_STATE
L9_1 = nil
function L10_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  if A2_2 then
    L5_2 = type
    L6_2 = A2_2
    L5_2 = L5_2(L6_2)
    if "table" == L5_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L5_2 = L6_1
  if L5_2 then
    L5_2 = L6_1
    L6_2 = L5_2
    L5_2 = L5_2.isActive
    L5_2 = L5_2(L6_2)
    if L5_2 then
      goto lbl_18
    end
  end
  do return end
  ::lbl_18::
  L5_2 = A2_2.front
  if not L5_2 then
    L5_2 = 0.0
  end
  L6_2 = A2_2.rear
  if not L6_2 then
    L6_2 = 0.0
  end
  L7_2 = nil
  if A0_2 then
    L8_2 = type
    L9_2 = A0_2
    L8_2 = L8_2(L9_2)
    if "string" == L8_2 then
      L8_2 = {}
      L10_2 = A0_2
      L9_2 = A0_2.gmatch
      L11_2 = "[^:]+"
      L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2, L11_2)
      for L13_2 in L9_2, L10_2, L11_2, L12_2 do
        L14_2 = table
        L14_2 = L14_2.insert
        L15_2 = L8_2
        L16_2 = L13_2
        L14_2(L15_2, L16_2)
      end
      L9_2 = #L8_2
      if L9_2 >= 2 then
        L9_2 = L8_2[1]
        if "entity" == L9_2 then
          L9_2 = tonumber
          L10_2 = L8_2[2]
          L9_2 = L9_2(L10_2)
          L7_2 = L9_2
        end
      end
    end
  end
  L8_2 = nil
  if L7_2 then
    L9_2 = NetworkDoesNetworkIdExist
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    if not L9_2 then
      return
    end
    L9_2 = NetworkGetEntityFromNetworkId
    L10_2 = L7_2
    L9_2 = L9_2(L10_2)
    L8_2 = L9_2
    if 0 ~= L8_2 then
      L9_2 = DoesEntityExist
      L10_2 = L8_2
      L9_2 = L9_2(L10_2)
      if L9_2 then
        goto lbl_79
      end
    end
    do return end
    ::lbl_79::
    L9_2 = L1_1
    L9_2 = L9_2[L8_2]
    if L9_2 then
      return
    end
  else
    L9_2 = GetGamePool
    L10_2 = "CVehicle"
    L9_2 = L9_2(L10_2)
    L10_2 = ipairs
    L11_2 = L9_2
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
    for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
      L16_2 = DoesEntityExist
      L17_2 = L15_2
      L16_2 = L16_2(L17_2)
      if L16_2 then
        L16_2 = Entity
        L17_2 = L15_2
        L16_2 = L16_2(L17_2)
        L16_2 = L16_2.state
        L17_2 = L2_1.BRAKE_TEMP_STATE
        L16_2 = L16_2[L17_2]
        if L16_2 then
          L17_2 = L16_2.front
          if L17_2 == L5_2 then
            L17_2 = L16_2.rear
            if L17_2 == L6_2 then
              L8_2 = L15_2
              break
            end
          end
        end
      end
    end
  end
  if L8_2 then
    L9_2 = DoesEntityExist
    L10_2 = L8_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      goto lbl_124
    end
  end
  do return end
  ::lbl_124::
  L9_2 = L1_1
  L9_2 = L9_2[L8_2]
  if L9_2 then
    return
  end
  L9_2 = L2_1.GLOW_THRESHOLD
  if not (L5_2 > L9_2) then
    L9_2 = L2_1.GLOW_THRESHOLD
    if not (L6_2 > L9_2) then
      goto lbl_184
    end
  end
  L9_2 = L6_1.trackedVehicles
  L9_2 = L9_2[L8_2]
  if not L9_2 then
    L9_2 = L6_1.trackedVehicles
    L10_2 = {}
    L11_2 = GetGameTimer
    L11_2 = L11_2()
    L10_2.lastUpdate = L11_2
    L11_2 = {}
    L10_2.effects = L11_2
    L9_2[L8_2] = L10_2
  else
    L9_2 = L6_1.trackedVehicles
    L9_2 = L9_2[L8_2]
    L10_2 = GetGameTimer
    L10_2 = L10_2()
    L9_2.lastUpdate = L10_2
  end
  L9_2 = L6_1
  L10_2 = L9_2
  L9_2 = L9_2.manageDiscGlow
  L11_2 = L8_2
  L12_2 = L2_1.WHEEL_BONES
  L12_2 = L12_2[1]
  L13_2 = L5_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = L6_1
  L10_2 = L9_2
  L9_2 = L9_2.manageDiscGlow
  L11_2 = L8_2
  L12_2 = L2_1.WHEEL_BONES
  L12_2 = L12_2[2]
  L13_2 = L5_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = L6_1
  L10_2 = L9_2
  L9_2 = L9_2.manageDiscGlow
  L11_2 = L8_2
  L12_2 = L2_1.WHEEL_BONES
  L12_2 = L12_2[3]
  L13_2 = L6_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  L9_2 = L6_1
  L10_2 = L9_2
  L9_2 = L9_2.manageDiscGlow
  L11_2 = L8_2
  L12_2 = L2_1.WHEEL_BONES
  L12_2 = L12_2[4]
  L13_2 = L6_2
  L9_2(L10_2, L11_2, L12_2, L13_2)
  goto lbl_218
  ::lbl_184::
  L9_2 = L6_1.trackedVehicles
  L9_2 = L9_2[L8_2]
  if L9_2 then
    L9_2 = L6_1.trackedVehicles
    L9_2 = L9_2[L8_2]
    L9_2 = L9_2.effects
    if L9_2 then
      L9_2 = false
      L10_2 = pairs
      L11_2 = L6_1.trackedVehicles
      L11_2 = L11_2[L8_2]
      L11_2 = L11_2.effects
      L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2)
      for L14_2, L15_2 in L10_2, L11_2, L12_2, L13_2 do
        L16_2 = DoesParticleFxLoopedExist
        L17_2 = L15_2
        L16_2 = L16_2(L17_2)
        if L16_2 then
          L9_2 = true
          break
        end
      end
      if not L9_2 then
        L10_2 = L6_1
        L11_2 = L10_2
        L10_2 = L10_2.cleanupVehicleEffects
        L12_2 = L8_2
        L10_2(L11_2, L12_2)
        L10_2 = L6_1.trackedVehicles
        L10_2[L8_2] = nil
      end
    end
  end
  ::lbl_218::
end
L7_1(L8_1, L9_1, L10_1)
