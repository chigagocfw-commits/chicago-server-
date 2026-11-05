local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1
L0_1 = {}
L0_1.active = false
L0_1.orderId = nil
L0_1.vehicleNetId = nil
L0_1.vehicle = nil
L0_1.vehicleProperties = nil
L1_1 = {}
L0_1.steps = L1_1
L0_1.currentStepIndex = 1
L0_1.interactionPoint = nil
L1_1 = {}
L0_1.completedSteps = L1_1
L1_1 = {}
L1_1.sprayingCan = nil
L1_1.sprayingParticle = nil
L1_1.wrench = nil
L1_1.welder = nil
L1_1.welderParticle = nil
L2_1 = nil
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = {}
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "spraypaint"
  L4_2.dict = "switch@franklin@lamar_tagging_wall"
  L4_2.anim = "lamar_tagging_wall_loop_lamar"
  L4_2.exitAnim = "lamar_tagging_exit_loop_lamar"
  L4_2.prop = "prop_cs_spray_can"
  L4_2.propBone = 28422
  L5_2 = {}
  L5_2.x = 0
  L5_2.y = -0.01
  L5_2.z = -0.012
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 0
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.particle = "scr_playerlamgraff"
  L4_2.particleEffect = "scr_lamgraff_paint_spray"
  L4_2.duration = 8000
  L3_2.paint = L4_2
  L2_2.respray = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 10000
  L3_2.engine = L4_2
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 8000
  L3_2.brakes = L4_2
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 9000
  L3_2.transmission = L4_2
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 8000
  L3_2.suspension = L4_2
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 12000
  L3_2.turbo = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 10000
  L3_2.armor = L4_2
  L2_2.performance = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 5000
  L3_2.extras = L4_2
  L2_2.extras = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 7000
  L3_2.spoiler = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 8000
  L3_2.front_bumper = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 8000
  L3_2.rear_bumper = L4_2
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 7000
  L3_2.exhaust = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 6000
  L3_2.hood = L4_2
  L4_2 = {}
  L4_2.type = "spraypaint"
  L4_2.dict = "switch@franklin@lamar_tagging_wall"
  L4_2.anim = "lamar_tagging_wall_loop_lamar"
  L4_2.exitAnim = "lamar_tagging_exit_loop_lamar"
  L4_2.prop = "prop_cs_spray_can"
  L4_2.propBone = 28422
  L5_2 = {}
  L5_2.x = 0
  L5_2.y = -0.01
  L5_2.z = -0.012
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 0
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.particle = "scr_playerlamgraff"
  L4_2.particleEffect = "scr_lamgraff_paint_spray"
  L4_2.duration = 10000
  L3_2.livery = L4_2
  L2_2.cosmetics = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "mechanic"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 8000
  L3_2.wheels = L4_2
  L2_2.wheels = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 6000
  L3_2.headlights = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 5000
  L3_2.xenon = L4_2
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 9000
  L3_2.neon = L4_2
  L2_2.lights = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "install"
  L4_2.dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@"
  L4_2.anim = "machinic_loop_mechandplayer"
  L4_2.duration = 6000
  L3_2.tint = L4_2
  L2_2.windows = L3_2
  L3_2 = {}
  L4_2 = {}
  L4_2.type = "repair"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 15000
  L3_2.fullRepair = L4_2
  L4_2 = {}
  L4_2.type = "repair"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 12000
  L3_2.engineRepair = L4_2
  L4_2 = {}
  L4_2.type = "repair"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 10000
  L3_2.bodyRepair = L4_2
  L4_2 = {}
  L4_2.type = "repair"
  L4_2.dict = "mini@repair"
  L4_2.anim = "fixing_a_ped"
  L4_2.prop = "prop_tool_wrench"
  L4_2.propBone = 57005
  L5_2 = {}
  L5_2.x = 0.08
  L5_2.y = 0.0
  L5_2.z = -0.02
  L4_2.propOffset = L5_2
  L5_2 = {}
  L5_2.x = 90
  L5_2.y = 0
  L5_2.z = 0
  L4_2.propRotation = L5_2
  L4_2.duration = 6000
  L3_2.tireRepair = L4_2
  L2_2.repairs = L3_2
  L3_2 = L2_2[A0_2]
  if L3_2 then
    L3_2 = L2_2[A0_2]
    L3_2 = L3_2[A1_2]
    if L3_2 then
      L3_2 = L2_2[A0_2]
      L3_2 = L3_2[A1_2]
      return L3_2
    end
  end
  L3_2 = {}
  L3_2.type = "mechanic"
  L3_2.dict = "mini@repair"
  L3_2.anim = "fixing_a_ped"
  L3_2.duration = 8000
  return L3_2
end
function L4_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = L2_1
  if not L0_2 then
    L0_2 = {}
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 1.0
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_ENGINE"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.engine = L2_2
    L2_2 = {}
    L2_2.bone = "wheel_lf"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = -0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_BRAKES"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.brakes = L2_2
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.5
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_TRANSMISSION"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.transmission = L2_2
    L2_2 = {}
    L2_2.bone = "wheel_lf"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = -0.5
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_SUSPENSION"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.suspension = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_ARMOR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.armor = L2_2
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.8
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_TURBO"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.turbo = L2_2
    L0_2.performance = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "boot"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = -0.5
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_SPOILER"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.spoiler = L2_2
    L2_2 = {}
    L2_2.bone = "bumper_f"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.5
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_FRONT_BUMPER"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.front_bumper = L2_2
    L2_2 = {}
    L2_2.bone = "bumper_r"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = -0.5
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_REAR_BUMPER"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.rear_bumper = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.8
    L5_2 = 0.0
    L6_2 = -0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_SIDE_SKIRT"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.side_skirt = L2_2
    L2_2 = {}
    L2_2.bone = "exhaust"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = -1.0
    L6_2 = -0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_EXHAUST"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.exhaust = L2_2
    L2_2 = {}
    L2_2.bone = "bonnet"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 1.0
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_HOOD"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.hood = L2_2
    L2_2 = {}
    L2_2.bone = "roof"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = 0.5
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_ROOF"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.roof = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.8
    L5_2 = 0.5
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_FENDERS"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.fenders = L2_2
    L2_2 = {}
    L2_2.bone = "bumper_f"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.8
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_GRILLE"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.grille = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.5
    L5_2 = 0.0
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_STEERING_WHEEL"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.steering = L2_2
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 1.0
    L6_2 = 0.5
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_ENGINE_BLOCK"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.engine_block = L2_2
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.8
    L6_2 = 0.4
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_AIR_FILTER"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.air_filter = L2_2
    L2_2 = {}
    L2_2.bone = "door_dside_f"
    L3_2 = vector3
    L4_2 = -0.5
    L5_2 = 0.0
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_APPLY_LIVERY"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.livery = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.5
    L5_2 = 0.0
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_INTERIOR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.interior = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.5
    L5_2 = -0.5
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_SEATS"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.seats = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.5
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_DASHBOARD"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.dashboard = L2_2
    L2_2 = {}
    L2_2.bone = "plate_front"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.5
    L6_2 = -0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_PLATE"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.plate = L2_2
    L0_2.cosmetics = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.5
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_EXTRAS"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.extras = L2_2
    L0_2.extras = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "door_dside_f"
    L3_2 = vector3
    L4_2 = -0.5
    L5_2 = 0.0
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_APPLY_PAINT"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.paint = L2_2
    L0_2.respray = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "wheel_lf"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = -0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_WHEELS"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.wheels = L2_2
    L0_2.wheels = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "headlight_l"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.3
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_HEADLIGHTS"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.headlights = L2_2
    L2_2 = {}
    L2_2.bone = "headlight_l"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.3
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_XENON"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.xenon = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = -0.5
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_NEON"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.neon = L2_2
    L2_2 = {}
    L2_2.bone = "roof"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_LIGHTBOX"
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = "Press [E] to install lightbox"
    end
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.lightbox = L2_2
    L0_2.lights = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "window_lf"
    L3_2 = vector3
    L4_2 = -0.3
    L5_2 = 0.0
    L6_2 = 0.2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_APPLY_WINDOW_TINT"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.tint = L2_2
    L0_2.windows = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_FULL_REPAIR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.fullRepair = L2_2
    L2_2 = {}
    L2_2.bone = "engine"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 1.0
    L6_2 = 0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_ENGINE_REPAIR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = true
    L1_2.engineRepair = L2_2
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = -0.8
    L5_2 = 0.0
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_BODY_REPAIR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.bodyRepair = L2_2
    L2_2 = {}
    L2_2.bone = "wheel_lf"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = -0.3
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_TIRE_REPAIR"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.tireRepair = L2_2
    L0_2.repairs = L1_2
    L1_2 = {}
    L2_2 = {}
    L2_2.bone = "chassis"
    L3_2 = vector3
    L4_2 = 0.0
    L5_2 = 0.0
    L6_2 = 0.0
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L2_2.offset = L3_2
    L3_2 = _U
    L4_2 = "PRESS_E_INSTALL_MODIFICATION"
    L3_2 = L3_2(L4_2)
    L2_2.text = L3_2
    L2_2.openHood = false
    L1_2.default = L2_2
    L0_2.other = L1_2
    L2_1 = L0_2
  end
  L0_2 = L2_1
  return L0_2
end
L5_1 = nil
function L6_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = L5_1
  if not L0_2 then
    L0_2 = {}
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "spoiler"
    L2_2 = _U
    L3_2 = "SPOILER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[0] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "front_bumper"
    L2_2 = _U
    L3_2 = "FRONT_BUMPER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[1] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "rear_bumper"
    L2_2 = _U
    L3_2 = "REAR_BUMPER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[2] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "side_skirt"
    L2_2 = _U
    L3_2 = "SIDE_SKIRT"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[3] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "exhaust"
    L2_2 = _U
    L3_2 = "EXHAUST"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[4] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "frame"
    L2_2 = _U
    L3_2 = "ROLL_CAGE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[5] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "grille"
    L2_2 = _U
    L3_2 = "GRILLE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[6] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "hood"
    L2_2 = _U
    L3_2 = "HOOD"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[7] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "fenders"
    L2_2 = _U
    L3_2 = "FENDERS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[8] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "fenders"
    L2_2 = _U
    L3_2 = "RIGHT_FENDER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[9] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "roof"
    L2_2 = _U
    L3_2 = "ROOF"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[10] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "engine"
    L2_2 = _U
    L3_2 = "ENGINE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[11] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "brakes"
    L2_2 = _U
    L3_2 = "BRAKES"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[12] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "transmission"
    L2_2 = _U
    L3_2 = "TRANSMISSION"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[13] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "horn"
    L2_2 = _U
    L3_2 = "HORN"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[14] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "suspension"
    L2_2 = _U
    L3_2 = "SUSPENSION"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[15] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "armor"
    L2_2 = _U
    L3_2 = "ARMOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[16] = L1_2
    L1_2 = {}
    L1_2.category = "performance"
    L1_2.subType = "turbo"
    L2_2 = _U
    L3_2 = "TURBO"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[18] = L1_2
    L1_2 = {}
    L1_2.category = "lights"
    L1_2.subType = "xenon"
    L2_2 = _U
    L3_2 = "XENON_LIGHTS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[22] = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "wheels"
    L2_2 = _U
    L3_2 = "FRONT_WHEELS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[23] = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "wheels"
    L2_2 = _U
    L3_2 = "BACK_WHEELS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[24] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "plate"
    L2_2 = _U
    L3_2 = "PLATE_HOLDER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[25] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "plate"
    L2_2 = _U
    L3_2 = "VANITY_PLATE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[26] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "interior"
    L2_2 = _U
    L3_2 = "INTERIOR_TRIM"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[27] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "ornaments"
    L2_2 = _U
    L3_2 = "ORNAMENTS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[28] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "dashboard"
    L2_2 = _U
    L3_2 = "DASHBOARD"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[29] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "dial"
    L2_2 = _U
    L3_2 = "DIAL"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[30] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "speaker"
    L2_2 = _U
    L3_2 = "DOOR_SPEAKER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[31] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "seats"
    L2_2 = _U
    L3_2 = "SEATS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[32] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "steering"
    L2_2 = _U
    L3_2 = "STEERING_WHEEL"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[33] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "shifter"
    L2_2 = _U
    L3_2 = "SHIFTER_LEAVERS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[34] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "plaques"
    L2_2 = _U
    L3_2 = "PLAQUES"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[35] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "speakers"
    L2_2 = _U
    L3_2 = "SPEAKERS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[36] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "trunk"
    L2_2 = _U
    L3_2 = "TRUNK"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[37] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "hydraulics"
    L2_2 = _U
    L3_2 = "HYDRAULICS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[38] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "engine_block"
    L2_2 = _U
    L3_2 = "ENGINE_BLOCK"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[39] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "air_filter"
    L2_2 = _U
    L3_2 = "AIR_FILTER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[40] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "struts"
    L2_2 = _U
    L3_2 = "STRUTS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[41] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "arch_cover"
    L2_2 = _U
    L3_2 = "ARCH_COVER"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[42] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "aerials"
    L2_2 = _U
    L3_2 = "AERIALS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[43] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "wings"
    L2_2 = _U
    L3_2 = "WINGS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[44] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "fuel_tank"
    L2_2 = _U
    L3_2 = "FUEL_TANK"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[45] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "windows"
    L2_2 = _U
    L3_2 = "WINDOWS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[46] = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "livery"
    L2_2 = _U
    L3_2 = "LIVERY"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2[48] = L1_2
    L1_2 = {}
    L1_2.category = "lights"
    L1_2.subType = "lightbox"
    L2_2 = _U
    L3_2 = "LIGHTBOX"
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      L2_2 = "Lightbox"
    end
    L1_2.name = L2_2
    L0_2[49] = L1_2
    L1_2 = {}
    L1_2.category = "respray"
    L1_2.subType = "paint"
    L2_2 = _U
    L3_2 = "PRIMARY_PAINT"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.primaryColor = L1_2
    L1_2 = {}
    L1_2.category = "respray"
    L1_2.subType = "paint"
    L2_2 = _U
    L3_2 = "SECONDARY_PAINT"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.secondaryColor = L1_2
    L1_2 = {}
    L1_2.category = "respray"
    L1_2.subType = "paint"
    L2_2 = _U
    L3_2 = "PEARLESCENT"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.pearlescentColor = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "wheels"
    L2_2 = _U
    L3_2 = "WHEELS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.wheels = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "wheels"
    L2_2 = _U
    L3_2 = "WHEEL_TYPE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.wheelType = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "wheels"
    L2_2 = _U
    L3_2 = "WHEEL_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.wheelColor = L1_2
    L1_2 = {}
    L1_2.category = "windows"
    L1_2.subType = "tint"
    L2_2 = _U
    L3_2 = "WINDOW_TINT"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.windowTint = L1_2
    L1_2 = {}
    L1_2.category = "lights"
    L1_2.subType = "neon"
    L2_2 = _U
    L3_2 = "NEON_LIGHTS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.neonLights = L1_2
    L1_2 = {}
    L1_2.category = "lights"
    L1_2.subType = "neon"
    L2_2 = _U
    L3_2 = "NEON_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.neonColor = L1_2
    L1_2 = {}
    L1_2.category = "lights"
    L1_2.subType = "xenon"
    L2_2 = _U
    L3_2 = "XENON_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.xenonColor = L1_2
    L1_2 = {}
    L1_2.category = "wheels"
    L1_2.subType = "smoke"
    L2_2 = _U
    L3_2 = "TYRE_SMOKE_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.tyreSmokeColor = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "plate"
    L2_2 = _U
    L3_2 = "LICENSE_PLATE"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.plateIndex = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "interior"
    L2_2 = _U
    L3_2 = "INTERIOR_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.interiorColor = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "dashboard"
    L2_2 = _U
    L3_2 = "DASHBOARD_COLOR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.dashboardColor = L1_2
    L1_2 = {}
    L1_2.category = "repairs"
    L1_2.subType = "fullRepair"
    L2_2 = _U
    L3_2 = "FULL_REPAIR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.fullRepair = L1_2
    L1_2 = {}
    L1_2.category = "repairs"
    L1_2.subType = "engineRepair"
    L2_2 = _U
    L3_2 = "ENGINE_REPAIR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.engineRepair = L1_2
    L1_2 = {}
    L1_2.category = "repairs"
    L1_2.subType = "bodyRepair"
    L2_2 = _U
    L3_2 = "BODY_REPAIR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.bodyRepair = L1_2
    L1_2 = {}
    L1_2.category = "repairs"
    L1_2.subType = "tireRepair"
    L2_2 = _U
    L3_2 = "TIRE_REPAIR"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.tireRepair = L1_2
    L1_2 = {}
    L1_2.category = "cosmetics"
    L1_2.subType = "extras"
    L2_2 = _U
    L3_2 = "TUNESHOP_EXTRAS"
    L2_2 = L2_2(L3_2)
    L1_2.name = L2_2
    L0_2.extras = L1_2
    L5_1 = L0_2
  end
  L0_2 = L5_1
  return L0_2
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = tonumber
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L2_2 = L6_1
    L2_2 = L2_2()
    L3_2 = L2_2[L1_2]
    if L3_2 then
      L4_2 = L3_2.category
      L5_2 = L3_2.subType
      L6_2 = L3_2.name
      return L4_2, L5_2, L6_2
    end
  end
  L2_2 = L6_1
  L2_2 = L2_2()
  L3_2 = L2_2[A0_2]
  if L3_2 then
    L4_2 = L3_2.category
    L5_2 = L3_2.subType
    L6_2 = L3_2.name
    return L4_2, L5_2, L6_2
  end
  L4_2 = "other"
  L5_2 = "default"
  L6_2 = tostring
  L7_2 = A0_2
  L6_2, L7_2 = L6_2(L7_2)
  return L4_2, L5_2, L6_2, L7_2
end
function L8_1()
  local L0_2, L1_2, L2_2
  L0_2 = L1_1.sprayingParticle
  if L0_2 then
    L0_2 = StopParticleFxLooped
    L1_2 = L1_1.sprayingParticle
    L2_2 = false
    L0_2(L1_2, L2_2)
    L1_1.sprayingParticle = nil
  end
  L0_2 = L1_1.sprayingCan
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L1_1.sprayingCan
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = DeleteObject
      L1_2 = L1_1.sprayingCan
      L0_2(L1_2)
      L1_1.sprayingCan = nil
    end
  end
  L0_2 = L1_1.wrench
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L1_1.wrench
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = DeleteObject
      L1_2 = L1_1.wrench
      L0_2(L1_2)
      L1_1.wrench = nil
    end
  end
  L0_2 = L1_1.welderParticle
  if L0_2 then
    L0_2 = StopParticleFxLooped
    L1_2 = L1_1.welderParticle
    L2_2 = false
    L0_2(L1_2, L2_2)
    L1_1.welderParticle = nil
  end
  L0_2 = L1_1.welder
  if L0_2 then
    L0_2 = DoesEntityExist
    L1_2 = L1_1.welder
    L0_2 = L0_2(L1_2)
    if L0_2 then
      L0_2 = DeleteObject
      L1_2 = L1_1.welder
      L0_2(L1_2)
      L1_1.welder = nil
    end
  end
end
function L9_1(A0_2)
  local L1_2, L2_2
  L1_2 = RequestAnimDict
  L2_2 = A0_2
  L1_2(L2_2)
  while true do
    L1_2 = HasAnimDictLoaded
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      break
    end
    L1_2 = Wait
    L2_2 = 0
    L1_2(L2_2)
  end
end
function L10_1(A0_2)
  local L1_2, L2_2
  L1_2 = RequestModel
  L2_2 = A0_2
  L1_2(L2_2)
  while true do
    L1_2 = HasModelLoaded
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      break
    end
    L1_2 = Wait
    L2_2 = 0
    L1_2(L2_2)
  end
end
function L11_1(A0_2)
  local L1_2, L2_2
  L1_2 = RequestNamedPtfxAsset
  L2_2 = A0_2
  L1_2(L2_2)
  while true do
    L1_2 = HasNamedPtfxAssetLoaded
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if L1_2 then
      break
    end
    L1_2 = Wait
    L2_2 = 0
    L1_2(L2_2)
  end
end
function L12_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L3_2 = L4_1
  L3_2 = L3_2()
  L3_2 = L3_2[A1_2]
  if not L3_2 then
    L4_2 = L4_1
    L4_2 = L4_2()
    L3_2 = L4_2.other
    A2_2 = "default"
  end
  L4_2 = L3_2[A2_2]
  if not L4_2 then
    L4_2 = L4_1
    L4_2 = L4_2()
    L4_2 = L4_2.other
    L4_2 = L4_2.default
  end
  L5_2 = GetEntityBoneIndexByName
  L6_2 = A0_2
  L7_2 = L4_2.bone
  L5_2 = L5_2(L6_2, L7_2)
  L6_2 = nil
  if -1 ~= L5_2 then
    L7_2 = GetWorldPositionOfEntityBone
    L8_2 = A0_2
    L9_2 = L5_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L7_2
  else
    L7_2 = GetEntityCoords
    L8_2 = A0_2
    L7_2 = L7_2(L8_2)
    L6_2 = L7_2
  end
  L7_2 = GetEntityHeading
  L8_2 = A0_2
  L7_2 = L7_2(L8_2)
  L8_2 = math
  L8_2 = L8_2.rad
  L9_2 = L7_2
  L8_2 = L8_2(L9_2)
  L9_2 = vector3
  L10_2 = L4_2.offset
  L10_2 = L10_2.x
  L11_2 = math
  L11_2 = L11_2.cos
  L12_2 = L8_2
  L11_2 = L11_2(L12_2)
  L10_2 = L10_2 * L11_2
  L11_2 = L4_2.offset
  L11_2 = L11_2.y
  L12_2 = math
  L12_2 = L12_2.sin
  L13_2 = L8_2
  L12_2 = L12_2(L13_2)
  L11_2 = L11_2 * L12_2
  L10_2 = L10_2 - L11_2
  L11_2 = L4_2.offset
  L11_2 = L11_2.x
  L12_2 = math
  L12_2 = L12_2.sin
  L13_2 = L8_2
  L12_2 = L12_2(L13_2)
  L11_2 = L11_2 * L12_2
  L12_2 = L4_2.offset
  L12_2 = L12_2.y
  L13_2 = math
  L13_2 = L13_2.cos
  L14_2 = L8_2
  L13_2 = L13_2(L14_2)
  L12_2 = L12_2 * L13_2
  L11_2 = L11_2 + L12_2
  L12_2 = L4_2.offset
  L12_2 = L12_2.z
  L9_2 = L9_2(L10_2, L11_2, L12_2)
  L10_2 = L6_2 + L9_2
  L11_2 = L4_2.openHood
  if not L11_2 then
    L11_2 = false
  end
  L12_2 = false
  if L11_2 then
    L13_2 = Config
    L13_2 = L13_2.BackEngines
    if L13_2 then
      L13_2 = GetEntityModel
      L14_2 = A0_2
      L13_2 = L13_2(L14_2)
      L14_2 = Config
      L14_2 = L14_2.BackEngines
      L14_2 = L14_2[L13_2]
      L12_2 = true == L14_2
    end
  end
  L13_2 = {}
  L13_2.position = L10_2
  L14_2 = L4_2.text
  L13_2.text = L14_2
  L13_2.shouldOpenHood = L11_2
  L14_2 = L4_2.openTrunk
  if not L14_2 then
    L14_2 = false
  end
  L13_2.shouldOpenTrunk = L14_2
  L13_2.isBackEngine = L12_2
  return L13_2
end
function L13_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = L0_1.active
  if L1_2 then
    return
  end
  L1_2 = A0_2.vehicleNetId
  if not L1_2 then
    L1_2 = showClientNotification
    L2_2 = {}
    L2_2.title = "Installation Error"
    L2_2.description = "No vehicle network ID provided"
    L2_2.type = "error"
    L1_2(L2_2)
    return
  end
  L1_2 = NetToVeh
  L2_2 = A0_2.vehicleNetId
  L1_2 = L1_2(L2_2)
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L3_2.title = "Installation Error"
    L3_2.description = "Vehicle not found"
    L3_2.type = "error"
    L2_2(L3_2)
    return
  end
  L2_2 = A0_2.vehicleProperties
  if L2_2 then
    L2_2 = A0_2.modificationsList
    if L2_2 then
      goto lbl_46
    end
  end
  L2_2 = showClientNotification
  L3_2 = {}
  L3_2.title = "Installation Error"
  L3_2.description = "Invalid order data"
  L3_2.type = "error"
  L2_2(L3_2)
  do return end
  ::lbl_46::
  L0_1.active = true
  L2_2 = A0_2.id
  L0_1.orderId = L2_2
  L2_2 = A0_2.vehicleNetId
  L0_1.vehicleNetId = L2_2
  L0_1.vehicle = L1_2
  L2_2 = A0_2.vehicleProperties
  L0_1.vehicleProperties = L2_2
  L0_1.currentStepIndex = 1
  L2_2 = {}
  L0_1.steps = L2_2
  L2_2 = {}
  L0_1.completedSteps = L2_2
  L2_2 = {}
  L3_2 = pairs
  L4_2 = A0_2.modificationsList
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
    L9_2 = L7_1
    L10_2 = L7_2
    L9_2, L10_2, L11_2 = L9_2(L10_2)
    L12_2 = table
    L12_2 = L12_2.insert
    L13_2 = L2_2
    L14_2 = {}
    L14_2.modType = L7_2
    L14_2.modData = L8_2
    L14_2.category = L9_2
    L14_2.subType = L10_2
    L14_2.name = L11_2
    L14_2.completed = false
    L12_2(L13_2, L14_2)
  end
  L3_2 = table
  L3_2 = L3_2.sort
  L4_2 = L2_2
  function L5_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3, L6_3
    L2_3 = tonumber
    L3_3 = A0_3.modType
    L2_3 = L2_3(L3_3)
    L3_3 = tonumber
    L4_3 = A1_3.modType
    L3_3 = L3_3(L4_3)
    if L2_3 and L3_3 then
      L4_3 = L2_3 < L3_3
      return L4_3
    elseif L2_3 then
      L4_3 = true
      return L4_3
    elseif L3_3 then
      L4_3 = false
      return L4_3
    else
      L4_3 = tostring
      L5_3 = A0_3.modType
      L4_3 = L4_3(L5_3)
      L5_3 = tostring
      L6_3 = A1_3.modType
      L5_3 = L5_3(L6_3)
      L4_3 = L4_3 < L5_3
      return L4_3
    end
  end
  L3_2(L4_2, L5_2)
  L0_1.steps = L2_2
  L3_2 = SafeSendNUIMessage
  L4_2 = {}
  L4_2.action = "showInstallProgress"
  L5_2 = {}
  L6_2 = A0_2.id
  L5_2.id = L6_2
  L6_2 = A0_2.vehiclePlate
  L5_2.vehiclePlate = L6_2
  L6_2 = A0_2.vehicleModel
  L5_2.vehicleModel = L6_2
  L6_2 = L0_1.steps
  L6_2 = #L6_2
  L5_2.totalSteps = L6_2
  L6_2 = A0_2.modificationsList
  L5_2.modificationsList = L6_2
  L4_2.order = L5_2
  L3_2(L4_2)
  L3_2 = ProcessCurrentStep
  L3_2()
end
StartInstallation = L13_1
function L13_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = L0_1.active
  if not L0_2 then
    return
  end
  L0_2 = L0_1.currentStepIndex
  L1_2 = L0_1.steps
  L1_2 = #L1_2
  if L0_2 > L1_2 then
    L0_2 = CompleteInstallation
    L0_2()
    return
  end
  L0_2 = L0_1.steps
  L1_2 = L0_1.currentStepIndex
  L0_2 = L0_2[L1_2]
  L1_2 = L0_1.vehicle
  L2_2 = DoesEntityExist
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = showClientNotification
    L3_2 = {}
    L3_2.title = "Installation Error"
    L3_2.description = "Vehicle no longer exists"
    L3_2.type = "error"
    L2_2(L3_2)
    L2_2 = CompleteInstallation
    L2_2()
    return
  end
  L2_2 = L12_1
  L3_2 = L1_2
  L4_2 = L0_2.category
  L5_2 = L0_2.subType
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L0_1.interactionPoint = L2_2
  L2_2 = L0_1.currentStepIndex
  L3_2 = "installation_"
  L4_2 = L2_2
  L3_2 = L3_2 .. L4_2
  L4_2 = CreateThread
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3
    while true do
      L0_3 = L0_1.active
      if L0_3 then
        L0_3 = L0_1.currentStepIndex
        L1_3 = L2_2
        if L0_3 == L1_3 then
          L0_3 = L0_1.interactionPoint
          if L0_3 then
            L0_3 = PlayerPedId
            L0_3 = L0_3()
            L1_3 = GetEntityCoords
            L2_3 = L0_3
            L1_3 = L1_3(L2_3)
            L2_3 = L0_1.interactionPoint
            L2_3 = L2_3.position
            L3_3 = L1_3 - L2_3
            L3_3 = #L3_3
            L4_3 = 2.5
            if L3_3 < L4_3 then
              L4_3 = Config
              L4_3 = L4_3.Interact
              if "qs-textui" == L4_3 then
                L4_3 = L0_2.name
                if not L4_3 then
                  L4_3 = "Install Part"
                end
                L5_3 = DrawText3D
                L6_3 = L2_3.x
                L7_3 = L2_3.y
                L8_3 = L2_3.z
                L9_3 = L4_3
                L10_3 = L3_2
                L11_3 = "E"
                L5_3(L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
              else
                L4_3 = DefaultText3D
                L5_3 = L2_3.x
                L6_3 = L2_3.y
                L7_3 = L2_3.z
                L8_3 = L0_1.interactionPoint
                L8_3 = L8_3.text
                L4_3(L5_3, L6_3, L7_3, L8_3)
              end
              L4_3 = IsControlJustPressed
              L5_3 = 0
              L6_3 = 38
              L4_3 = L4_3(L5_3, L6_3)
              if L4_3 then
                L4_3 = Config
                L4_3 = L4_3.Interact
                if "qs-textui" == L4_3 then
                  L4_3 = pcall
                  function L5_3()
                    local L0_4, L1_4, L2_4
                    L0_4 = exports
                    L0_4 = L0_4["qs-textui"]
                    L1_4 = L0_4
                    L0_4 = L0_4.DeleteDrawText3D
                    L2_4 = L3_2
                    L0_4(L1_4, L2_4)
                  end
                  L4_3(L5_3)
                end
                L4_3 = pcall
                L5_3 = PerformInstallation
                L6_3 = L0_2
                L4_3, L5_3 = L4_3(L5_3, L6_3)
                if not L4_3 then
                  L6_3 = Config
                  L6_3 = L6_3.Debug
                  if L6_3 then
                    L6_3 = print
                    L7_3 = "^1[DEBUG ProcessCurrentStep]^0 PerformInstallation error: "
                    L8_3 = tostring
                    L9_3 = L5_3
                    L8_3 = L8_3(L9_3)
                    L7_3 = L7_3 .. L8_3
                    L6_3(L7_3)
                  end
                  L6_3 = L8_1
                  L6_3()
                  L0_1.interactionPoint = nil
                  L6_3 = L0_1.currentStepIndex
                  L6_3 = L6_3 + 1
                  L0_1.currentStepIndex = L6_3
                  L6_3 = Wait
                  L7_3 = 500
                  L6_3(L7_3)
                  L6_3 = ProcessCurrentStep
                  L6_3()
                end
                break
              end
            end
          end
        end
      end
      L4_3 = Wait
      L5_3 = 0
      L4_3(L5_3)
    end
  end
  L4_2(L5_2)
end
ProcessCurrentStep = L13_1
function L13_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = L0_1.vehicle
  L2_2 = PlayerPedId
  L2_2 = L2_2()
  L3_2 = L3_1
  L4_2 = A0_2.category
  L5_2 = A0_2.subType
  L3_2 = L3_2(L4_2, L5_2)
  L4_2 = L0_1.interactionPoint
  L4_2 = L4_2.shouldOpenHood
  if L4_2 then
    L4_2 = L0_1.interactionPoint
    L4_2 = L4_2.isBackEngine
    if L4_2 then
      L4_2 = 5
      if L4_2 then
        goto lbl_20
      end
    end
    L4_2 = 4
    ::lbl_20::
    L5_2 = SetVehicleDoorOpen
    L6_2 = L1_2
    L7_2 = L4_2
    L8_2 = false
    L9_2 = false
    L5_2(L6_2, L7_2, L8_2, L9_2)
    L5_2 = Wait
    L6_2 = 300
    L5_2(L6_2)
  end
  L4_2 = L9_1
  L5_2 = L3_2.dict
  L4_2(L5_2)
  L4_2 = L3_2.type
  if "spraypaint" == L4_2 then
    L4_2 = L10_1
    L5_2 = L3_2.prop
    L4_2(L5_2)
    L4_2 = L11_1
    L5_2 = L3_2.particle
    L4_2(L5_2)
    L4_2 = GetEntityCoords
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    L5_2 = CreateObject
    L6_2 = L3_2.prop
    L7_2 = L4_2.x
    L8_2 = L4_2.y
    L9_2 = L4_2.z
    L10_2 = true
    L11_2 = true
    L12_2 = false
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
    L1_1.sprayingCan = L5_2
    L5_2 = AttachEntityToEntity
    L6_2 = L1_1.sprayingCan
    L7_2 = L2_2
    L8_2 = GetPedBoneIndex
    L9_2 = L2_2
    L10_2 = L3_2.propBone
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = L3_2.propOffset
    L9_2 = L9_2.x
    L10_2 = L3_2.propOffset
    L10_2 = L10_2.y
    L11_2 = L3_2.propOffset
    L11_2 = L11_2.z
    L12_2 = L3_2.propRotation
    L12_2 = L12_2.x
    L13_2 = L3_2.propRotation
    L13_2 = L13_2.y
    L14_2 = L3_2.propRotation
    L14_2 = L14_2.z
    L15_2 = true
    L16_2 = true
    L17_2 = false
    L18_2 = false
    L19_2 = 2
    L20_2 = true
    L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    L5_2 = CreateThread
    function L6_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
      L0_3 = TaskPlayAnim
      L1_3 = L2_2
      L2_3 = L3_2.dict
      L3_3 = L3_2.anim
      L4_3 = 8.0
      L5_3 = -8.0
      L6_3 = -1
      L7_3 = 8192
      L8_3 = 0.0
      L9_3 = false
      L10_3 = false
      L11_3 = false
      L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
      L0_3 = Wait
      L1_3 = 500
      L0_3(L1_3)
      L0_3 = L3_2.exitAnim
      if L0_3 then
        L0_3 = TaskPlayAnim
        L1_3 = L2_2
        L2_3 = L3_2.dict
        L3_3 = L3_2.exitAnim
        L4_3 = 8.0
        L5_3 = -2.0
        L6_3 = -1
        L7_3 = 8193
        L8_3 = 0.0
        L9_3 = false
        L10_3 = false
        L11_3 = false
        L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3)
      end
      L0_3 = L1_1.sprayingParticle
      if not L0_3 then
        L0_3 = UseParticleFxAssetNextCall
        L1_3 = L3_2.particle
        L0_3(L1_3)
        L0_3 = StartParticleFxLoopedOnEntity
        L1_3 = L3_2.particleEffect
        L2_3 = L1_1.sprayingCan
        L3_3 = 0
        L4_3 = 0
        L5_3 = 0
        L6_3 = 0
        L7_3 = 0
        L8_3 = 0
        L9_3 = 1.0
        L10_3 = false
        L11_3 = false
        L12_3 = false
        L0_3 = L0_3(L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
        L1_1.sprayingParticle = L0_3
        L0_3 = SetParticleFxLoopedColour
        L1_3 = L1_1.sprayingParticle
        L2_3 = 1.0
        L3_3 = 0.5
        L4_3 = 0.5
        L5_3 = 0
        L0_3(L1_3, L2_3, L3_3, L4_3, L5_3)
        L0_3 = SetParticleFxLoopedAlpha
        L1_3 = L1_1.sprayingParticle
        L2_3 = 0.25
        L0_3(L1_3, L2_3)
      end
    end
    L5_2(L6_2)
  else
    L4_2 = L3_2.type
    if "mechanic" == L4_2 or "repair" == L4_2 then
    L4_2 = TaskPlayAnim
    L5_2 = L2_2
    L6_2 = L3_2.dict
    L7_2 = L3_2.anim
    L8_2 = 8.0
    L9_2 = -8.0
    L10_2 = -1
    L11_2 = 1
    L12_2 = 0
    L13_2 = false
    L14_2 = false
    L15_2 = false
    L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    L4_2 = L3_2.prop
    if L4_2 then
      L4_2 = L10_1
      L5_2 = L3_2.prop
      L4_2(L5_2)
      L4_2 = GetEntityCoords
      L5_2 = L2_2
      L4_2 = L4_2(L5_2)
      L5_2 = CreateObject
      L6_2 = L3_2.prop
      L7_2 = L4_2.x
      L8_2 = L4_2.y
      L9_2 = L4_2.z
      L10_2 = true
      L11_2 = true
      L12_2 = false
      L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
      L1_1.wrench = L5_2
      L5_2 = AttachEntityToEntity
      L6_2 = L1_1.wrench
      L7_2 = L2_2
      L8_2 = GetPedBoneIndex
      L9_2 = L2_2
      L10_2 = L3_2.propBone
      L8_2 = L8_2(L9_2, L10_2)
      L9_2 = L3_2.propOffset
      L9_2 = L9_2.x
      L10_2 = L3_2.propOffset
      L10_2 = L10_2.y
      L11_2 = L3_2.propOffset
      L11_2 = L11_2.z
      L12_2 = L3_2.propRotation
      L12_2 = L12_2.x
      L13_2 = L3_2.propRotation
      L13_2 = L13_2.y
      L14_2 = L3_2.propRotation
      L14_2 = L14_2.z
      L15_2 = true
      L16_2 = true
      L17_2 = false
      L18_2 = false
      L19_2 = 2
      L20_2 = true
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    end
    elseif "install" == L3_2.type then
      L4_2 = TaskPlayAnim
      L5_2 = L2_2
      L6_2 = L3_2.dict
      L7_2 = L3_2.anim
      L8_2 = 8.0
      L9_2 = -8.0
      L10_2 = -1
      L11_2 = 1
      L12_2 = 0
      L13_2 = false
      L14_2 = false
      L15_2 = false
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    else
      L4_2 = TaskPlayAnim
      L5_2 = L2_2
      L6_2 = L3_2.dict
      L7_2 = L3_2.anim
      L8_2 = 8.0
      L9_2 = -8.0
      L10_2 = -1
      L11_2 = 1
      L12_2 = 0
      L13_2 = false
      L14_2 = false
      L15_2 = false
      L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
  L4_2 = PerformInstallationSkillCheck
  L4_2 = L4_2()
  L5_2 = ClearPedTasks
  L6_2 = L2_2
  L5_2(L6_2)
  L5_2 = L8_1
  L5_2()
  L5_2 = L0_1.interactionPoint
  L5_2 = L5_2.shouldOpenHood
  if L5_2 then
    L5_2 = L0_1.interactionPoint
    L5_2 = L5_2.isBackEngine
    if L5_2 then
      L5_2 = 5
      if L5_2 then
        goto lbl_198
      end
    end
    L5_2 = 4
    ::lbl_198::
    L6_2 = SetVehicleDoorShut
    L7_2 = L1_2
    L8_2 = L5_2
    L9_2 = false
    L6_2(L7_2, L8_2, L9_2)
  end
  if L4_2 then
    L5_2 = table
    L5_2 = L5_2.insert
    L6_2 = L0_1.completedSteps
    L7_2 = A0_2
    L5_2(L6_2, L7_2)
    L5_2 = SafeSendNUIMessage
    L6_2 = {}
    L6_2.action = "updateInstallStep"
    L6_2.stepIndex = 0
    L6_2.status = "completed"
    L5_2(L6_2)
    L5_2 = showClientNotification
    L6_2 = {}
    L6_2.title = "Installation"
    L7_2 = _U
    L8_2 = "NOTIFICATION_MOD_INSTALLED"
    L9_2 = A0_2.name
    L7_2 = L7_2(L8_2, L9_2)
    L6_2.description = L7_2
    L6_2.type = "success"
    L5_2(L6_2)
    L0_1.interactionPoint = nil
    L5_2 = L0_1.currentStepIndex
    L5_2 = L5_2 + 1
    L0_1.currentStepIndex = L5_2
    L5_2 = Wait
    L6_2 = 500
    L5_2(L6_2)
    L5_2 = ProcessCurrentStep
    L5_2()
  else
    L5_2 = showClientNotification
    L6_2 = {}
    L6_2.title = "Installation Failed"
    L6_2.description = "Try again"
    L6_2.type = "error"
    L5_2(L6_2)
    L5_2 = Wait
    L6_2 = 2000
    L5_2(L6_2)
    L5_2 = ProcessCurrentStep
    L5_2()
  end
end
PerformInstallation = L13_1
function L13_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L0_2 = L0_1.active
  if not L0_2 then
    return
  end
  L0_2 = L0_1.orderId
  L1_2 = L0_1.vehicle
  L2_2 = L0_1.vehicleProperties
  L3_2 = L8_1
  L3_2()
  L3_2 = DoesEntityExist
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  if L3_2 then
    L3_2 = showClientNotification
    L4_2 = {}
    L5_2 = _U
    L6_2 = "INSTALLATION"
    L5_2 = L5_2(L6_2)
    L4_2.title = L5_2
    L5_2 = _U
    L6_2 = "INSTALLING"
    L7_2 = _U
    L8_2 = "MODIFICATIONS"
    L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L7_2(L8_2)
    L5_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
    L4_2.description = L5_2
    L4_2.type = "info"
    L3_2(L4_2)
    L3_2 = Wait
    L4_2 = 500
    L3_2(L4_2)
    L3_2 = SetVehicleModKit
    L4_2 = L1_2
    L5_2 = 0
    L3_2(L4_2, L5_2)
    L3_2 = ipairs
    L4_2 = L0_1.steps
    L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
    for L7_2, L8_2 in L3_2, L4_2, L5_2, L6_2 do
      L9_2 = DoesEntityExist
      L10_2 = L1_2
      L9_2 = L9_2(L10_2)
      if not L9_2 then
        break
      end
      L9_2 = L8_2.modType
      L10_2 = L8_2.modData
      if L10_2 then
        L10_2 = L8_2.modData
        L10_2 = L10_2.value
      end
      if nil ~= L10_2 then
        L11_2 = pcall
        function L12_2()
          local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
          L0_3 = type
          L1_3 = L9_2
          L0_3 = L0_3(L1_3)
          if "number" == L0_3 then
            L0_3 = L9_2
          else
            L0_3 = tonumber
            L1_3 = L9_2
            L0_3 = L0_3(L1_3)
          end
          if L0_3 then
          if 18 == L0_3 or 22 == L0_3 then
            L1_3 = ToggleVehicleMod
            L2_3 = L1_2
            L3_3 = L0_3
            L4_3 = L10_2
            L4_3 = true == L4_3
            L1_3(L2_3, L3_3, L4_3)
          elseif 48 == L0_3 then
            L1_3 = L10_2
            L2_3 = type
            L3_3 = L1_3
            L2_3 = L2_3(L3_3)
            if "string" == L2_3 then
              L2_3 = tonumber
              L3_3 = L1_3
              L2_3 = L2_3(L3_3)
              L1_3 = L2_3 or L1_3
              if not L2_3 then
                L1_3 = -1
              end
            end
            if nil == L1_3 or "" == L1_3 or "stock" == L1_3 or "STOCK" == L1_3 or false == L1_3 then
              L1_3 = -1
            end
            L2_3 = GetVehicleLiveryCount
            L3_3 = L1_2
            L2_3 = L2_3(L3_3)
            if L2_3 > 0 then
              L2_3 = SetVehicleLivery
              L3_3 = L1_2
              L4_3 = L1_3
              L2_3(L3_3, L4_3)
            end
            L2_3 = SetVehicleMod
            L3_3 = L1_2
            L4_3 = 48
            L5_3 = L1_3
            L6_3 = false
            L2_3(L3_3, L4_3, L5_3, L6_3)
            L2_3 = Config
            L2_3 = L2_3.Debug
            if L2_3 then
              L2_3 = print
              L3_3 = "^3[DEBUG CompleteInstallation]^0 Livery install: liveryIdx="
              L4_3 = tostring
              L5_3 = L1_3
              L4_3 = L4_3(L5_3)
              L5_3 = " | native="
              L6_3 = tostring
              L7_3 = GetVehicleLivery
              L8_3 = L1_2
              L7_3, L8_3, L9_3, L10_3, L11_3, L12_3 = L7_3(L8_3)
              L6_3 = L6_3(L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
              L7_3 = " | modkit="
              L8_3 = tostring
              L9_3 = GetVehicleMod
              L10_3 = L1_2
              L11_3 = 48
              L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3, L11_3)
              L8_3 = L8_3(L9_3, L10_3, L11_3, L12_3)
              L3_3 = L3_3 .. L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3
              L2_3(L3_3)
            end
          else
            L1_3 = SetVehicleMod
            L2_3 = L1_2
            L3_3 = L0_3
            L4_3 = L10_2
            L5_3 = false
            L1_3(L2_3, L3_3, L4_3, L5_3)
            if 23 == L0_3 then
              L1_3 = GetVehicleClass
              L2_3 = L1_2
              L1_3 = L1_3(L2_3)
              if 8 == L1_3 then
                L1_3 = SetVehicleMod
                L2_3 = L1_2
                L3_3 = 24
                L4_3 = L10_2
                L5_3 = false
                L1_3(L2_3, L3_3, L4_3, L5_3)
              end
            end
          end
          else
                L0_3 = L9_2
                if "windowTint" == L0_3 then
                  L0_3 = SetVehicleWindowTint
                  L1_3 = L1_2
                  L2_3 = L10_2
                  L0_3(L1_3, L2_3)
                else
                  L0_3 = L9_2
                  if "plateIndex" == L0_3 then
                    L0_3 = SetVehicleNumberPlateTextIndex
                    L1_3 = L1_2
                    L2_3 = L10_2
                    L0_3(L1_3, L2_3)
                  else
                    L0_3 = L9_2
                    if "wheelType" == L0_3 then
                      L0_3 = SetVehicleWheelType
                      L1_3 = L1_2
                      L2_3 = L10_2
                      L0_3(L1_3, L2_3)
                    else
                      L0_3 = L9_2
                      if "xenonColor" == L0_3 then
                        L0_3 = type
                        L1_3 = L10_2
                        L0_3 = L0_3(L1_3)
                        if "table" == L0_3 then
                          L0_3 = L10_2.r
                          if L0_3 then
                            L0_3 = L10_2.g
                            if L0_3 then
                              L0_3 = L10_2.b
                              if L0_3 then
                                L0_3 = ToggleVehicleMod
                                L1_3 = L1_2
                                L2_3 = 22
                                L3_3 = true
                                L0_3(L1_3, L2_3, L3_3)
                                L0_3 = SetVehicleXenonLightsCustomColor
                                L1_3 = L1_2
                                L2_3 = L10_2.r
                                L3_3 = L10_2.g
                                L4_3 = L10_2.b
                                L0_3(L1_3, L2_3, L3_3, L4_3)
                              end
                            end
                          end
                        end
                      else
                        L0_3 = L9_2
                        if "pearlescentColor" == L0_3 then
                          L0_3 = type
                          L1_3 = L10_2
                          L0_3 = L0_3(L1_3)
                          if "table" == L0_3 then
                            L0_3 = L10_2.index
                            if L0_3 then
                              goto lbl_178
                            end
                          end
                          L0_3 = L10_2
                          ::lbl_178::
                          L1_3 = type
                          L2_3 = L0_3
                          L1_3 = L1_3(L2_3)
                          if "number" == L1_3 then
                            L1_3 = GetVehicleExtraColours
                            L2_3 = L1_2
                            L1_3, L2_3 = L1_3(L2_3)
                            L3_3 = SetVehicleExtraColours
                            L4_3 = L1_2
                            L5_3 = L0_3
                            L6_3 = L2_3 or L6_3
                            if not L2_3 then
                              L6_3 = 0
                            end
                            L3_3(L4_3, L5_3, L6_3)
                          end
                        else
                          L0_3 = L9_2
                          if "primaryColor" == L0_3 then
                            L0_3 = type
                            L1_3 = L10_2
                            L0_3 = L0_3(L1_3)
                            if "table" == L0_3 then
                              L0_3 = GetVehicleColours
                              L1_3 = L1_2
                              L0_3, L1_3 = L0_3(L1_3)
                              L2_3 = Config
                              L2_3 = L2_3.Debug
                              if L2_3 then
                                L2_3 = print
                                L3_3 = "^3[DEBUG CompleteInstallation]^0 Applying PRIMARY color:"
                                L2_3(L3_3)
                                L2_3 = print
                                L3_3 = "  Material: "
                                L4_3 = tostring
                                L5_3 = L10_2.material
                                L4_3 = L4_3(L5_3)
                                L3_3 = L3_3 .. L4_3
                                L2_3(L3_3)
                                L2_3 = print
                                L3_3 = "  Index: "
                                L4_3 = tostring
                                L5_3 = L10_2.index
                                L4_3 = L4_3(L5_3)
                                L3_3 = L3_3 .. L4_3
                                L2_3(L3_3)
                                L2_3 = print
                                L3_3 = "  RGB: r="
                                L4_3 = tostring
                                L5_3 = L10_2.r
                                L4_3 = L4_3(L5_3)
                                L5_3 = " g="
                                L6_3 = tostring
                                L7_3 = L10_2.g
                                L6_3 = L6_3(L7_3)
                                L7_3 = " b="
                                L8_3 = tostring
                                L9_3 = L10_2.b
                                L8_3 = L8_3(L9_3)
                                L3_3 = L3_3 .. L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3
                                L2_3(L3_3)
                              end
                              L2_3 = L10_2.material
                              if "chameleon" == L2_3 then
                                L2_3 = L10_2.index
                                if L2_3 then
                                  L2_3 = ClearVehicleCustomPrimaryColour
                                  L3_3 = L1_2
                                  L2_3(L3_3)
                                  L2_3 = Wait
                                  L3_3 = 50
                                  L2_3(L3_3)
                                  L2_3 = SetVehicleColours
                                  L3_3 = L1_2
                                  L4_3 = L10_2.index
                                  L5_3 = L1_3
                                  L2_3(L3_3, L4_3, L5_3)
                                  L2_3 = Config
                                  L2_3 = L2_3.Debug
                                  if L2_3 then
                                    L2_3 = print
                                    L3_3 = "  -> Applied CHAMELEON index "
                                    L4_3 = L10_2.index
                                    L3_3 = L3_3 .. L4_3
                                    L2_3(L3_3)
                                  end
                              end
                              else
                                L2_3 = L10_2.material
                                if "chrome" == L2_3 then
                                  L2_3 = ClearVehicleCustomPrimaryColour
                                  L3_3 = L1_2
                                  L2_3(L3_3)
                                  L2_3 = Wait
                                  L3_3 = 50
                                  L2_3(L3_3)
                                  L2_3 = SetVehicleColours
                                  L3_3 = L1_2
                                  L4_3 = 120
                                  L5_3 = L1_3
                                  L2_3(L3_3, L4_3, L5_3)
                                  L2_3 = Config
                                  L2_3 = L2_3.Debug
                                  if L2_3 then
                                    L2_3 = print
                                    L3_3 = "  -> Applied CHROME (120)"
                                    L2_3(L3_3)
                                  end
                                else
                                  L2_3 = L10_2.r
                                  if L2_3 then
                                    L2_3 = L10_2.g
                                    if L2_3 then
                                      L2_3 = L10_2.b
                                      if L2_3 then
                                        L2_3 = 0
                                        L3_3 = L10_2.material
                                        if "metallic" == L3_3 then
                                          L2_3 = 1
                                        else
                                          L3_3 = L10_2.material
                                          if "pearl" == L3_3 then
                                            L2_3 = 2
                                          else
                                            L3_3 = L10_2.material
                                            if "matte" == L3_3 then
                                              L2_3 = 3
                                            else
                                              L3_3 = L10_2.material
                                              if "metal" == L3_3 then
                                                L2_3 = 4
                                              end
                                            end
                                          end
                                        end
                                        L3_3 = Config
                                        L3_3 = L3_3.Debug
                                        if L3_3 then
                                          L3_3 = print
                                          L4_3 = "  -> Applying paintType="
                                          L5_3 = L2_3
                                          L6_3 = " for material "
                                          L7_3 = tostring
                                          L8_3 = L10_2.material
                                          L7_3 = L7_3(L8_3)
                                          L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3
                                          L3_3(L4_3)
                                        end
                                        L3_3 = SetVehicleModColor_1
                                        L4_3 = L1_2
                                        L5_3 = L2_3
                                        L6_3 = 0
                                        L7_3 = 0
                                        L3_3(L4_3, L5_3, L6_3, L7_3)
                                        L3_3 = SetVehicleCustomPrimaryColour
                                        L4_3 = L1_2
                                        L5_3 = L10_2.r
                                        L6_3 = L10_2.g
                                        L7_3 = L10_2.b
                                        L3_3(L4_3, L5_3, L6_3, L7_3)
                                        L3_3 = Config
                                        L3_3 = L3_3.Debug
                                        if L3_3 then
                                          L3_3 = GetVehicleModColor_1
                                          L4_3 = L1_2
                                          L3_3, L4_3, L5_3 = L3_3(L4_3)
                                          L6_3 = print
                                          L7_3 = "  -> After SetVehicleModColor_1 + CustomPrimary, ModColor_1: "
                                          L8_3 = L3_3
                                          L9_3 = ", "
                                          L10_3 = L4_3
                                          L11_3 = ", "
                                          L12_3 = L5_3
                                          L7_3 = L7_3 .. L8_3 .. L9_3 .. L10_3 .. L11_3 .. L12_3
                                          L6_3(L7_3)
                                        end
                                      end
                                    end
                                  end
                                end
                              end
                            end
                          else
                            L0_3 = L9_2
                            if "secondaryColor" == L0_3 then
                              L0_3 = type
                              L1_3 = L10_2
                              L0_3 = L0_3(L1_3)
                              if "table" == L0_3 then
                                L0_3 = GetVehicleColours
                                L1_3 = L1_2
                                L0_3, L1_3 = L0_3(L1_3)
                                L2_3 = Config
                                L2_3 = L2_3.Debug
                                if L2_3 then
                                  L2_3 = print
                                  L3_3 = "^3[DEBUG CompleteInstallation]^0 Applying SECONDARY color:"
                                  L2_3(L3_3)
                                  L2_3 = print
                                  L3_3 = "  Material: "
                                  L4_3 = tostring
                                  L5_3 = L10_2.material
                                  L4_3 = L4_3(L5_3)
                                  L3_3 = L3_3 .. L4_3
                                  L2_3(L3_3)
                                  L2_3 = print
                                  L3_3 = "  Index: "
                                  L4_3 = tostring
                                  L5_3 = L10_2.index
                                  L4_3 = L4_3(L5_3)
                                  L3_3 = L3_3 .. L4_3
                                  L2_3(L3_3)
                                  L2_3 = print
                                  L3_3 = "  RGB: r="
                                  L4_3 = tostring
                                  L5_3 = L10_2.r
                                  L4_3 = L4_3(L5_3)
                                  L5_3 = " g="
                                  L6_3 = tostring
                                  L7_3 = L10_2.g
                                  L6_3 = L6_3(L7_3)
                                  L7_3 = " b="
                                  L8_3 = tostring
                                  L9_3 = L10_2.b
                                  L8_3 = L8_3(L9_3)
                                  L3_3 = L3_3 .. L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3
                                  L2_3(L3_3)
                                end
                                L2_3 = L10_2.material
                                if "chameleon" == L2_3 then
                                  L2_3 = L10_2.index
                                  if L2_3 then
                                    L2_3 = ClearVehicleCustomSecondaryColour
                                    L3_3 = L1_2
                                    L2_3(L3_3)
                                    L2_3 = Wait
                                    L3_3 = 50
                                    L2_3(L3_3)
                                    L2_3 = SetVehicleColours
                                    L3_3 = L1_2
                                    L4_3 = L0_3
                                    L5_3 = L10_2.index
                                    L2_3(L3_3, L4_3, L5_3)
                                    L2_3 = Config
                                    L2_3 = L2_3.Debug
                                    if L2_3 then
                                      L2_3 = print
                                      L3_3 = "  -> Applied CHAMELEON index "
                                      L4_3 = L10_2.index
                                      L3_3 = L3_3 .. L4_3
                                      L2_3(L3_3)
                                    end
                                end
                                else
                                  L2_3 = L10_2.material
                                  if "chrome" == L2_3 then
                                    L2_3 = ClearVehicleCustomSecondaryColour
                                    L3_3 = L1_2
                                    L2_3(L3_3)
                                    L2_3 = Wait
                                    L3_3 = 50
                                    L2_3(L3_3)
                                    L2_3 = SetVehicleColours
                                    L3_3 = L1_2
                                    L4_3 = L0_3
                                    L5_3 = 120
                                    L2_3(L3_3, L4_3, L5_3)
                                    L2_3 = Config
                                    L2_3 = L2_3.Debug
                                    if L2_3 then
                                      L2_3 = print
                                      L3_3 = "  -> Applied CHROME (120)"
                                      L2_3(L3_3)
                                    end
                                  else
                                    L2_3 = L10_2.r
                                    if L2_3 then
                                      L2_3 = L10_2.g
                                      if L2_3 then
                                        L2_3 = L10_2.b
                                        if L2_3 then
                                          L2_3 = 0
                                          L3_3 = L10_2.material
                                          if "metallic" == L3_3 then
                                            L2_3 = 1
                                          else
                                            L3_3 = L10_2.material
                                            if "pearl" == L3_3 then
                                              L2_3 = 2
                                            else
                                              L3_3 = L10_2.material
                                              if "matte" == L3_3 then
                                                L2_3 = 3
                                              else
                                                L3_3 = L10_2.material
                                                if "metal" == L3_3 then
                                                  L2_3 = 4
                                                end
                                              end
                                            end
                                          end
                                          L3_3 = Config
                                          L3_3 = L3_3.Debug
                                          if L3_3 then
                                            L3_3 = print
                                            L4_3 = "  -> Applying paintType="
                                            L5_3 = L2_3
                                            L6_3 = " for material "
                                            L7_3 = tostring
                                            L8_3 = L10_2.material
                                            L7_3 = L7_3(L8_3)
                                            L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3
                                            L3_3(L4_3)
                                          end
                                          L3_3 = SetVehicleModColor_2
                                          L4_3 = L1_2
                                          L5_3 = L2_3
                                          L6_3 = 0
                                          L3_3(L4_3, L5_3, L6_3)
                                          L3_3 = SetVehicleCustomSecondaryColour
                                          L4_3 = L1_2
                                          L5_3 = L10_2.r
                                          L6_3 = L10_2.g
                                          L7_3 = L10_2.b
                                          L3_3(L4_3, L5_3, L6_3, L7_3)
                                          L3_3 = Config
                                          L3_3 = L3_3.Debug
                                          if L3_3 then
                                            L3_3 = GetVehicleModColor_2
                                            L4_3 = L1_2
                                            L3_3, L4_3 = L3_3(L4_3)
                                            L5_3 = print
                                            L6_3 = "  -> After SetVehicleModColor_2 + CustomSecondary, ModColor_2: "
                                            L7_3 = L3_3
                                            L8_3 = ", "
                                            L9_3 = L4_3
                                            L6_3 = L6_3 .. L7_3 .. L8_3 .. L9_3
                                            L5_3(L6_3)
                                          end
                                        end
                                      end
                                    end
                                  end
                                end
                              end
                            else
                              L0_3 = L9_2
                              if "wheelColor" == L0_3 then
                                L0_3 = type
                                L1_3 = L10_2
                                L0_3 = L0_3(L1_3)
                                if "table" == L0_3 then
                                  L0_3 = L10_2.index
                                  if L0_3 then
                                    goto lbl_537
                                  end
                                end
                                L0_3 = L10_2
                                ::lbl_537::
                                L1_3 = type
                                L2_3 = L0_3
                                L1_3 = L1_3(L2_3)
                                if "number" == L1_3 then
                                  L1_3 = GetVehicleExtraColours
                                  L2_3 = L1_2
                                  L1_3, L2_3 = L1_3(L2_3)
                                  L3_3 = SetVehicleExtraColours
                                  L4_3 = L1_2
                                  L5_3 = L1_3 or L5_3
                                  if not L1_3 then
                                    L5_3 = 0
                                  end
                                  L6_3 = L0_3
                                  L3_3(L4_3, L5_3, L6_3)
                                end
                              else
                                L0_3 = L9_2
                                if "interiorColor" == L0_3 then
                                  L0_3 = type
                                  L1_3 = L10_2
                                  L0_3 = L0_3(L1_3)
                                  if "table" == L0_3 then
                                    L0_3 = L10_2.index
                                    if L0_3 then
                                      goto lbl_565
                                    end
                                  end
                                  L0_3 = L10_2
                                  ::lbl_565::
                                  L1_3 = type
                                  L2_3 = L0_3
                                  L1_3 = L1_3(L2_3)
                                  if "number" == L1_3 then
                                    L1_3 = pcall
                                    L2_3 = SetVehicleInteriorColor
                                    L3_3 = L1_2
                                    L4_3 = L0_3
                                    L1_3(L2_3, L3_3, L4_3)
                                  end
                                else
                                  L0_3 = L9_2
                                  if "dashboardColor" == L0_3 then
                                    L0_3 = type
                                    L1_3 = L10_2
                                    L0_3 = L0_3(L1_3)
                                    if "table" == L0_3 then
                                      L0_3 = L10_2.index
                                      if L0_3 then
                                        goto lbl_588
                                      end
                                    end
                                    L0_3 = L10_2
                                    ::lbl_588::
                                    L1_3 = type
                                    L2_3 = L0_3
                                    L1_3 = L1_3(L2_3)
                                    if "number" == L1_3 then
                                      L1_3 = pcall
                                      L2_3 = SetVehicleDashboardColor
                                      L3_3 = L1_2
                                      L4_3 = L0_3
                                      L1_3(L2_3, L3_3, L4_3)
                                    end
                                  else
                                    L0_3 = L9_2
                                    if "neonLights" == L0_3 then
                                      L0_3 = type
                                      L1_3 = L10_2
                                      L0_3 = L0_3(L1_3)
                                      if "table" == L0_3 then
                                        L0_3 = SetVehicleNeonLightEnabled
                                        L1_3 = L1_2
                                        L2_3 = 0
                                        L3_3 = L10_2.left
                                        if not L3_3 then
                                          L3_3 = false
                                        end
                                        L0_3(L1_3, L2_3, L3_3)
                                        L0_3 = SetVehicleNeonLightEnabled
                                        L1_3 = L1_2
                                        L2_3 = 1
                                        L3_3 = L10_2.right
                                        if not L3_3 then
                                          L3_3 = false
                                        end
                                        L0_3(L1_3, L2_3, L3_3)
                                        L0_3 = SetVehicleNeonLightEnabled
                                        L1_3 = L1_2
                                        L2_3 = 2
                                        L3_3 = L10_2.front
                                        if not L3_3 then
                                          L3_3 = false
                                        end
                                        L0_3(L1_3, L2_3, L3_3)
                                        L0_3 = SetVehicleNeonLightEnabled
                                        L1_3 = L1_2
                                        L2_3 = 3
                                        L3_3 = L10_2.back
                                        if not L3_3 then
                                          L3_3 = false
                                        end
                                        L0_3(L1_3, L2_3, L3_3)
                                      end
                                    else
                                      L0_3 = L9_2
                                      if "neonColor" == L0_3 then
                                        L0_3 = type
                                        L1_3 = L10_2
                                        L0_3 = L0_3(L1_3)
                                        if "table" == L0_3 then
                                          L0_3 = L10_2.r
                                          if L0_3 then
                                            L0_3 = L10_2.g
                                            if L0_3 then
                                              L0_3 = L10_2.b
                                              if L0_3 then
                                                L0_3 = SetVehicleNeonLightsColour
                                                L1_3 = L1_2
                                                L2_3 = L10_2.r
                                                L3_3 = L10_2.g
                                                L4_3 = L10_2.b
                                                L0_3(L1_3, L2_3, L3_3, L4_3)
                                              end
                                            end
                                          end
                                        end
                                      else
                                        L0_3 = L9_2
                                        if "tyreSmokeColor" == L0_3 then
                                          L0_3 = ToggleVehicleMod
                                          L1_3 = L1_2
                                          L2_3 = 20
                                          L3_3 = true
                                          L0_3(L1_3, L2_3, L3_3)
                                          L0_3 = type
                                          L1_3 = L10_2
                                          L0_3 = L0_3(L1_3)
                                          if "table" == L0_3 then
                                            L0_3 = L10_2.r
                                            if L0_3 then
                                              L0_3 = L10_2.g
                                              if L0_3 then
                                                L0_3 = L10_2.b
                                                if L0_3 then
                                                  L0_3 = SetVehicleTyreSmokeColor
                                                  L1_3 = L1_2
                                                  L2_3 = L10_2.r
                                                  L3_3 = L10_2.g
                                                  L4_3 = L10_2.b
                                                  L0_3(L1_3, L2_3, L3_3, L4_3)
                                                end
                                              end
                                            end
                                          end
                                        else
                                          L0_3 = L9_2
                                          if "livery" == L0_3 then
                                            L0_3 = GetVehicleLiveryCount
                                            L1_3 = L1_2
                                            L0_3 = L0_3(L1_3)
                                            if L0_3 > 0 then
                                              L0_3 = SetVehicleLivery
                                              L1_3 = L1_2
                                              L2_3 = L10_2
                                              L0_3(L1_3, L2_3)
                                            else
                                              L0_3 = SetVehicleMod
                                              L1_3 = L1_2
                                              L2_3 = 48
                                              L3_3 = L10_2
                                              L4_3 = false
                                              L0_3(L1_3, L2_3, L3_3, L4_3)
                                            end
                                          else
                                            L0_3 = L9_2
                                            if "extras" == L0_3 then
                                              L0_3 = type
                                              L1_3 = L10_2
                                              L0_3 = L0_3(L1_3)
                                              if "table" == L0_3 then
                                                L0_3 = pairs
                                                L1_3 = L10_2
                                                L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3)
                                                for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
                                                  L6_3 = tonumber
                                                  L7_3 = L4_3
                                                  L6_3 = L6_3(L7_3)
                                                  if L6_3 then
                                                    L7_3 = SetVehicleExtra
                                                    L8_3 = L1_2
                                                    L9_3 = L6_3
                                                    L10_3 = not L5_3
                                                    L7_3(L8_3, L9_3, L10_3)
                                                  end
                                                end
                                              end
                                            else
                                              L0_3 = L9_2
                                              if "fullRepair" == L0_3 then
                                                L0_3 = fixVehicleDeformation
                                                L1_3 = L1_2
                                                L0_3(L1_3)
                                                L0_3 = SetVehicleEngineHealth
                                                L1_3 = L1_2
                                                L2_3 = 1000.0
                                                L0_3(L1_3, L2_3)
                                                L0_3 = SetVehicleBodyHealth
                                                L1_3 = L1_2
                                                L2_3 = 1000.0
                                                L0_3(L1_3, L2_3)
                                                L0_3 = SetVehicleUndriveable
                                                L1_3 = L1_2
                                                L2_3 = false
                                                L0_3(L1_3, L2_3)
                                                L0_3 = SetVehicleEngineOn
                                                L1_3 = L1_2
                                                L2_3 = true
                                                L3_3 = true
                                                L4_3 = false
                                                L0_3(L1_3, L2_3, L3_3, L4_3)
                                                L0_3 = 0
                                                L1_3 = 7
                                                L2_3 = 1
                                                for L3_3 = L0_3, L1_3, L2_3 do
                                                  L4_3 = SetVehicleTyreFixed
                                                  L5_3 = L1_2
                                                  L6_3 = L3_3
                                                  L4_3(L5_3, L6_3)
                                                end
                                              else
                                                L0_3 = L9_2
                                                if "engineRepair" == L0_3 then
                                                  L0_3 = SetVehicleEngineHealth
                                                  L1_3 = L1_2
                                                  L2_3 = 1000.0
                                                  L0_3(L1_3, L2_3)
                                                  L0_3 = SetVehicleUndriveable
                                                  L1_3 = L1_2
                                                  L2_3 = false
                                                  L0_3(L1_3, L2_3)
                                                  L0_3 = SetVehicleEngineOn
                                                  L1_3 = L1_2
                                                  L2_3 = true
                                                  L3_3 = true
                                                  L4_3 = false
                                                  L0_3(L1_3, L2_3, L3_3, L4_3)
                                                else
                                                  L0_3 = L9_2
                                                  if "bodyRepair" == L0_3 then
                                                    L0_3 = SetVehicleBodyHealth
                                                    L1_3 = L1_2
                                                    L2_3 = 1000.0
                                                    L0_3(L1_3, L2_3)
                                                  else
                                                    L0_3 = L9_2
                                                    if "tireRepair" == L0_3 then
                                                      L0_3 = 0
                                                      L1_3 = 7
                                                      L2_3 = 1
                                                      for L3_3 = L0_3, L1_3, L2_3 do
                                                        L4_3 = SetVehicleTyreFixed
                                                        L5_3 = L1_2
                                                        L6_3 = L3_3
                                                        L4_3(L5_3, L6_3)
                                                      end
                                                    end
                                                  end
                                                end
                                              end
                                            end
                                          end
                                        end
                                      end
                                    end
                                  end
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
        L11_2, L12_2 = L11_2(L12_2)
        if not L11_2 then
          L13_2 = Config
          L13_2 = L13_2.Debug
          if L13_2 then
            L13_2 = print
            L14_2 = "^1[DEBUG CompleteInstallation]^0 Error applying mod "
            L15_2 = tostring
            L16_2 = L9_2
            L15_2 = L15_2(L16_2)
            L16_2 = ": "
            L17_2 = tostring
            L18_2 = L12_2
            L17_2 = L17_2(L18_2)
            L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2
            L13_2(L14_2)
          end
        end
      end
    end
    L3_2 = Wait
    L4_2 = 200
    L3_2(L4_2)
    L3_2 = Config
    L3_2 = L3_2.Debug
    if L3_2 then
      L3_2 = print
      L4_2 = "^3[DEBUG CompleteInstallation]^0 Vehicle state BEFORE lib.getVehicleProperties:"
      L3_2(L4_2)
      L3_2 = GetVehicleModColor_1
      L4_2 = L1_2
      L3_2, L4_2, L5_2 = L3_2(L4_2)
      L6_2 = GetVehicleModColor_2
      L7_2 = L1_2
      L6_2, L7_2 = L6_2(L7_2)
      L8_2 = GetVehicleColours
      L9_2 = L1_2
      L8_2, L9_2 = L8_2(L9_2)
      L10_2 = GetVehicleCustomPrimaryColour
      L11_2 = L1_2
      L10_2, L11_2, L12_2 = L10_2(L11_2)
      L13_2 = print
      L14_2 = "  ModColor_1 (paintType): "
      L15_2 = tostring
      L16_2 = L3_2
      L15_2 = L15_2(L16_2)
      L16_2 = ", "
      L17_2 = tostring
      L18_2 = L4_2
      L17_2 = L17_2(L18_2)
      L18_2 = ", "
      L19_2 = tostring
      L20_2 = L5_2
      L19_2 = L19_2(L20_2)
      L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
      L13_2(L14_2)
      L13_2 = print
      L14_2 = "  ModColor_2 (paintType): "
      L15_2 = tostring
      L16_2 = L6_2
      L15_2 = L15_2(L16_2)
      L16_2 = ", "
      L17_2 = tostring
      L18_2 = L7_2
      L17_2 = L17_2(L18_2)
      L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2
      L13_2(L14_2)
      L13_2 = print
      L14_2 = "  VehicleColours: primary="
      L15_2 = tostring
      L16_2 = L8_2
      L15_2 = L15_2(L16_2)
      L16_2 = ", secondary="
      L17_2 = tostring
      L18_2 = L9_2
      L17_2 = L17_2(L18_2)
      L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2
      L13_2(L14_2)
      L13_2 = print
      L14_2 = "  CustomPrimaryColour: r="
      L15_2 = tostring
      L16_2 = L10_2
      L15_2 = L15_2(L16_2)
      L16_2 = ", g="
      L17_2 = tostring
      L18_2 = L11_2
      L17_2 = L17_2(L18_2)
      L18_2 = ", b="
      L19_2 = tostring
      L20_2 = L12_2
      L19_2 = L19_2(L20_2)
      L14_2 = L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2
      L13_2(L14_2)
    end
    L3_2 = lib
    L3_2 = L3_2.getVehicleProperties
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    L4_2 = Config
    L4_2 = L4_2.Debug
    if L4_2 then
      L4_2 = print
      L5_2 = "^3[DEBUG CompleteInstallation]^0 lib.getVehicleProperties returned:"
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  color1: "
      L6_2 = tostring
      L7_2 = L3_2.color1
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  color2: "
      L6_2 = tostring
      L7_2 = L3_2.color2
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  pearlescentColor: "
      L6_2 = tostring
      L7_2 = L3_2.pearlescentColor
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  modLivery: "
      L6_2 = tostring
      L7_2 = L3_2.modLivery
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  livery: "
      L6_2 = tostring
      L7_2 = L3_2.livery
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  live GetVehicleMod(48): "
      L6_2 = tostring
      L7_2 = GetVehicleMod
      L8_2 = L1_2
      L9_2 = 48
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L7_2(L8_2, L9_2)
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = print
      L5_2 = "  live GetVehicleLivery: "
      L6_2 = tostring
      L7_2 = GetVehicleLivery
      L8_2 = L1_2
      L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2 = L7_2(L8_2)
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
      L4_2 = L3_2.color1
      if L4_2 then
        L4_2 = type
        L5_2 = L3_2.color1
        L4_2 = L4_2(L5_2)
        if "table" == L4_2 then
          L4_2 = print
          L5_2 = "  color1 is TABLE: r="
          L6_2 = tostring
          L7_2 = L3_2.color1
          L7_2 = L7_2[1]
          L6_2 = L6_2(L7_2)
          L7_2 = ", g="
          L8_2 = tostring
          L9_2 = L3_2.color1
          L9_2 = L9_2[2]
          L8_2 = L8_2(L9_2)
          L9_2 = ", b="
          L10_2 = tostring
          L11_2 = L3_2.color1
          L11_2 = L11_2[3]
          L10_2 = L10_2(L11_2)
          L5_2 = L5_2 .. L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2
          L4_2(L5_2)
        end
      end
    end
    L4_2 = ipairs
    L5_2 = L0_1.steps
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = L9_2.modType
      L11_2 = L9_2.modData
      if L11_2 then
        L11_2 = L9_2.modData
        L11_2 = L11_2.value
      end
      if (48 == L10_2 or "48" == L10_2 or "livery" == L10_2) and (-1 == L11_2 or "-1" == L11_2) then
        L3_2.modLivery = -1
        L3_2.livery = -1
        L12_2 = Config
        L12_2 = L12_2.Debug
        if L12_2 then
          L12_2 = print
          L13_2 = "^3[DEBUG CompleteInstallation]^0 Forced stock livery in finalProperties (modLivery=-1, livery=-1)"
          L12_2(L13_2)
        end
      end
    end
    L4_2 = ipairs
    L5_2 = L0_1.steps
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = L9_2.modType
      L11_2 = L9_2.modData
      if L11_2 then
        L11_2 = L9_2.modData
        L11_2 = L11_2.value
      end
      if "primaryColor" == L10_2 then
        L12_2 = type
        L13_2 = L11_2
        L12_2 = L12_2(L13_2)
        if "table" == L12_2 then
          L12_2 = L11_2.material
          L3_2.primaryColorMaterial = L12_2
          L12_2 = L11_2.material
          if "chameleon" == L12_2 then
            L12_2 = L11_2.index
            if L12_2 then
              L12_2 = L11_2.index
              L3_2.primaryColorIndex = L12_2
          end
          else
            L12_2 = L11_2.r
            if L12_2 then
              L12_2 = L11_2.g
              if L12_2 then
                L12_2 = L11_2.b
                if L12_2 then
                  L12_2 = {}
                  L13_2 = L11_2.r
                  L12_2.r = L13_2
                  L13_2 = L11_2.g
                  L12_2.g = L13_2
                  L13_2 = L11_2.b
                  L12_2.b = L13_2
                  L3_2.primaryColorRGB = L12_2
                  L3_2.color1 = nil
                end
              end
            end
          end
          L12_2 = Config
          L12_2 = L12_2.Debug
          if L12_2 then
            L12_2 = print
            L13_2 = "^3[DEBUG CompleteInstallation]^0 Injected primaryColorMaterial: "
            L14_2 = tostring
            L15_2 = L11_2.material
            L14_2 = L14_2(L15_2)
            L13_2 = L13_2 .. L14_2
            L12_2(L13_2)
            L12_2 = L3_2.primaryColorRGB
            if L12_2 then
              L12_2 = print
              L13_2 = "  primaryColorRGB: r="
              L14_2 = L3_2.primaryColorRGB
              L14_2 = L14_2.r
              L15_2 = ", g="
              L16_2 = L3_2.primaryColorRGB
              L16_2 = L16_2.g
              L17_2 = ", b="
              L18_2 = L3_2.primaryColorRGB
              L18_2 = L18_2.b
              L13_2 = L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2
              L12_2(L13_2)
            end
          end
      end
      elseif "secondaryColor" == L10_2 then
        L12_2 = type
        L13_2 = L11_2
        L12_2 = L12_2(L13_2)
        if "table" == L12_2 then
          L12_2 = L11_2.material
          L3_2.secondaryColorMaterial = L12_2
          L12_2 = L11_2.material
          if "chameleon" == L12_2 then
            L12_2 = L11_2.index
            if L12_2 then
              L12_2 = L11_2.index
              L3_2.secondaryColorIndex = L12_2
          end
          else
            L12_2 = L11_2.r
            if L12_2 then
              L12_2 = L11_2.g
              if L12_2 then
                L12_2 = L11_2.b
                if L12_2 then
                  L12_2 = {}
                  L13_2 = L11_2.r
                  L12_2.r = L13_2
                  L13_2 = L11_2.g
                  L12_2.g = L13_2
                  L13_2 = L11_2.b
                  L12_2.b = L13_2
                  L3_2.secondaryColorRGB = L12_2
                  L3_2.color2 = nil
                end
              end
            end
          end
          L12_2 = Config
          L12_2 = L12_2.Debug
          if L12_2 then
            L12_2 = print
            L13_2 = "^3[DEBUG CompleteInstallation]^0 Injected secondaryColorMaterial: "
            L14_2 = tostring
            L15_2 = L11_2.material
            L14_2 = L14_2(L15_2)
            L13_2 = L13_2 .. L14_2
            L12_2(L13_2)
          end
        end
      end
    end
    L4_2 = GetVehicleNumberPlateText
    L5_2 = L1_2
    L4_2 = L4_2(L5_2)
    L5_2 = VehToNet
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.Debug
    if L6_2 then
      L6_2 = print
      L7_2 = "^3[DEBUG CompleteInstallation]^0 Sending to server:"
      L6_2(L7_2)
      L6_2 = print
      L7_2 = "  orderId: "
      L8_2 = tostring
      L9_2 = L0_2
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 .. L8_2
      L6_2(L7_2)
      L6_2 = print
      L7_2 = "  vehiclePlate: "
      L8_2 = tostring
      L9_2 = L4_2
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 .. L8_2
      L6_2(L7_2)
      L6_2 = print
      L7_2 = "  vehicleNetId: "
      L8_2 = tostring
      L9_2 = L5_2
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 .. L8_2
      L6_2(L7_2)
      L6_2 = print
      L7_2 = "  finalProperties.primaryColorMaterial: "
      L8_2 = tostring
      L9_2 = L3_2.primaryColorMaterial
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 .. L8_2
      L6_2(L7_2)
      L6_2 = print
      L7_2 = "  finalProperties.secondaryColorMaterial: "
      L8_2 = tostring
      L9_2 = L3_2.secondaryColorMaterial
      L8_2 = L8_2(L9_2)
      L7_2 = L7_2 .. L8_2
      L6_2(L7_2)
    end
    L6_2 = TriggerServerEvent
    L7_2 = "qs-mechanic-creator:server:completeInstallation"
    L8_2 = L0_2
    L9_2 = L3_2
    L10_2 = L4_2
    L11_2 = L5_2
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
  end
  L0_1.active = false
  L0_1.orderId = nil
  L0_1.vehicleNetId = nil
  L0_1.vehicle = nil
  L0_1.vehicleProperties = nil
  L3_2 = {}
  L0_1.steps = L3_2
  L3_2 = {}
  L0_1.completedSteps = L3_2
  L0_1.currentStepIndex = 1
  L0_1.interactionPoint = nil
  L3_2 = SafeSendNUIMessage
  L4_2 = {}
  L4_2.action = "hideInstallProgress"
  L3_2(L4_2)
  L3_2 = showClientNotification
  L4_2 = {}
  L4_2.title = "Installation Complete"
  L5_2 = _U
  L6_2 = "NOTIFICATION_ALL_MODS_INSTALLED"
  L5_2 = L5_2(L6_2)
  L4_2.description = L5_2
  L4_2.type = "success"
  L4_2.duration = 5000
  L3_2(L4_2)
end
CompleteInstallation = L13_1
L13_1 = RegisterNetEvent
L14_1 = "qs-mechanic-creator:client:startInstallation"
function L15_1(A0_2)
  local L1_2, L2_2
  L1_2 = StartInstallation
  L2_2 = A0_2
  L1_2(L2_2)
end
L13_1(L14_1, L15_1)
L13_1 = RegisterNetEvent
L14_1 = "qs-mechanic-creator:client:syncVehicleMod"
function L15_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  if A0_2 then
    L3_2 = NetworkDoesNetworkIdExist
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      goto lbl_9
    end
  end
  do return end
  ::lbl_9::
  L3_2 = NetToVeh
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = DoesEntityExist
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = Config
    L4_2 = L4_2.Debug
    if L4_2 then
      L4_2 = print
      L5_2 = "^1[DEBUG syncVehicleMod]^0 Vehicle does not exist for netId: "
      L6_2 = tostring
      L7_2 = A0_2
      L6_2 = L6_2(L7_2)
      L5_2 = L5_2 .. L6_2
      L4_2(L5_2)
    end
    return
  end
  L4_2 = Config
  L4_2 = L4_2.Debug
  if L4_2 then
    L4_2 = print
    L5_2 = "^5[DEBUG syncVehicleMod]^0 RECEIVED EVENT:"
    L4_2(L5_2)
    L4_2 = print
    L5_2 = "  vehicleNetId: "
    L6_2 = tostring
    L7_2 = A0_2
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    L4_2 = print
    L5_2 = "  vehicleProperties.primaryColorMaterial: "
    L6_2 = tostring
    L7_2 = A1_2 or L7_2
    if A1_2 then
      L7_2 = A1_2.primaryColorMaterial
    end
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    L4_2 = print
    L5_2 = "  vehicleProperties.primaryColorRGB: "
    L6_2 = tostring
    L7_2 = A1_2 or L7_2
    if A1_2 then
      L7_2 = A1_2.primaryColorRGB
      if L7_2 then
        L7_2 = json
        L7_2 = L7_2.encode
        L8_2 = A1_2.primaryColorRGB
        L7_2 = L7_2(L8_2)
      end
    end
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    L4_2 = print
    L5_2 = "  modifications type: "
    L6_2 = type
    L7_2 = A2_2
    L6_2 = L6_2(L7_2)
    L5_2 = L5_2 .. L6_2
    L4_2(L5_2)
    if A2_2 then
      L4_2 = pairs
      L5_2 = A2_2
      L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
      for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
        L10_2 = print
        L11_2 = "    mod["
        L12_2 = tostring
        L13_2 = L8_2
        L12_2 = L12_2(L13_2)
        L13_2 = "]: "
        L14_2 = tostring
        L15_2 = type
        L16_2 = L9_2
        L15_2 = L15_2(L16_2)
        if "table" == L15_2 then
          L15_2 = json
          L15_2 = L15_2.encode
          L16_2 = L9_2
          L15_2 = L15_2(L16_2)
          if L15_2 then
            goto lbl_99
          end
        end
        L15_2 = L9_2
        ::lbl_99::
        L14_2 = L14_2(L15_2)
        L11_2 = L11_2 .. L12_2 .. L13_2 .. L14_2
        L10_2(L11_2)
      end
    end
  end
  L4_2 = pcall
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3, L18_3, L19_3
    L0_3 = Config
    L0_3 = L0_3.Debug
    if L0_3 then
      L0_3 = print
      L1_3 = "^5[DEBUG syncVehicleMod]^0 BEFORE lib.setVehicleProperties:"
      L0_3(L1_3)
      L0_3 = GetVehicleModColor_1
      L1_3 = L3_2
      L0_3, L1_3, L2_3 = L0_3(L1_3)
      L3_3 = print
      L4_3 = "  ModColor_1: "
      L5_3 = tostring
      L6_3 = L0_3
      L5_3 = L5_3(L6_3)
      L6_3 = ", "
      L7_3 = tostring
      L8_3 = L1_3
      L7_3 = L7_3(L8_3)
      L8_3 = ", "
      L9_3 = tostring
      L10_3 = L2_3
      L9_3 = L9_3(L10_3)
      L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
      L3_3(L4_3)
    end
    L0_3 = lib
    L0_3 = L0_3.setVehicleProperties
    L1_3 = L3_2
    L2_3 = A1_2
    L0_3(L1_3, L2_3)
    L0_3 = TriggerEvent
    L1_3 = "qs-mechanic-creator:client:reapplyEngineHandling"
    L2_3 = L3_2
    L0_3(L1_3, L2_3)
    L0_3 = Config
    L0_3 = L0_3.Debug
    if L0_3 then
      L0_3 = print
      L1_3 = "^5[DEBUG syncVehicleMod]^0 AFTER lib.setVehicleProperties:"
      L0_3(L1_3)
      L0_3 = GetVehicleModColor_1
      L1_3 = L3_2
      L0_3, L1_3, L2_3 = L0_3(L1_3)
      L3_3 = print
      L4_3 = "  ModColor_1: "
      L5_3 = tostring
      L6_3 = L0_3
      L5_3 = L5_3(L6_3)
      L6_3 = ", "
      L7_3 = tostring
      L8_3 = L1_3
      L7_3 = L7_3(L8_3)
      L8_3 = ", "
      L9_3 = tostring
      L10_3 = L2_3
      L9_3 = L9_3(L10_3)
      L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
      L3_3(L4_3)
    end
    L0_3 = A2_2
    if L0_3 then
      L0_3 = type
      L1_3 = A2_2
      L0_3 = L0_3(L1_3)
      if "table" == L0_3 then
        L0_3 = pairs
        L1_3 = A2_2
        L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3)
        for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
          L6_3 = L5_3
          L7_3 = type
          L8_3 = L5_3
          L7_3 = L7_3(L8_3)
          if "table" == L7_3 then
            L7_3 = L5_3.value
            if nil ~= L7_3 then
              L6_3 = L5_3.value
            end
          end
          if "primaryColor" == L4_3 then
            L7_3 = type
            L8_3 = L6_3
            L7_3 = L7_3(L8_3)
            if "table" == L7_3 then
              L7_3 = Config
              L7_3 = L7_3.Debug
              if L7_3 then
                L7_3 = print
                L8_3 = "^5[DEBUG syncVehicleMod]^0 Re-applying PRIMARY color:"
                L7_3(L8_3)
                L7_3 = print
                L8_3 = "  modValue.material: "
                L9_3 = tostring
                L10_3 = L6_3.material
                L9_3 = L9_3(L10_3)
                L8_3 = L8_3 .. L9_3
                L7_3(L8_3)
                L7_3 = print
                L8_3 = "  modValue.r/g/b: "
                L9_3 = tostring
                L10_3 = L6_3.r
                L9_3 = L9_3(L10_3)
                L10_3 = "/"
                L11_3 = tostring
                L12_3 = L6_3.g
                L11_3 = L11_3(L12_3)
                L12_3 = "/"
                L13_3 = tostring
                L14_3 = L6_3.b
                L13_3 = L13_3(L14_3)
                L8_3 = L8_3 .. L9_3 .. L10_3 .. L11_3 .. L12_3 .. L13_3
                L7_3(L8_3)
              end
              L7_3 = GetVehicleColours
              L8_3 = L3_2
              L7_3, L8_3 = L7_3(L8_3)
              L9_3 = L6_3.material
              if "chameleon" == L9_3 then
                L9_3 = L6_3.index
                if L9_3 then
                  L9_3 = ClearVehicleCustomPrimaryColour
                  L10_3 = L3_2
                  L9_3(L10_3)
                  L9_3 = Wait
                  L10_3 = 50
                  L9_3(L10_3)
                  L9_3 = SetVehicleColours
                  L10_3 = L3_2
                  L11_3 = L6_3.index
                  L12_3 = L8_3
                  L9_3(L10_3, L11_3, L12_3)
                  L9_3 = Config
                  L9_3 = L9_3.Debug
                  if L9_3 then
                    L9_3 = print
                    L10_3 = "  -> Applied CHAMELEON"
                    L9_3(L10_3)
                  end
              end
              else
                L9_3 = L6_3.material
                if "chrome" == L9_3 then
                  L9_3 = ClearVehicleCustomPrimaryColour
                  L10_3 = L3_2
                  L9_3(L10_3)
                  L9_3 = Wait
                  L10_3 = 50
                  L9_3(L10_3)
                  L9_3 = SetVehicleColours
                  L10_3 = L3_2
                  L11_3 = 120
                  L12_3 = L8_3
                  L9_3(L10_3, L11_3, L12_3)
                  L9_3 = Config
                  L9_3 = L9_3.Debug
                  if L9_3 then
                    L9_3 = print
                    L10_3 = "  -> Applied CHROME"
                    L9_3(L10_3)
                  end
                else
                  L9_3 = L6_3.r
                  if L9_3 then
                    L9_3 = L6_3.g
                    if L9_3 then
                      L9_3 = L6_3.b
                      if L9_3 then
                        L9_3 = 0
                        L10_3 = L6_3.material
                        if "metallic" == L10_3 then
                          L9_3 = 1
                        else
                          L10_3 = L6_3.material
                          if "pearl" == L10_3 then
                            L9_3 = 2
                          else
                            L10_3 = L6_3.material
                            if "matte" == L10_3 then
                              L9_3 = 3
                            else
                              L10_3 = L6_3.material
                              if "metal" == L10_3 then
                                L9_3 = 4
                              end
                            end
                          end
                        end
                        L10_3 = Config
                        L10_3 = L10_3.Debug
                        if L10_3 then
                          L10_3 = print
                          L11_3 = "  -> Applying paintType="
                          L12_3 = L9_3
                          L13_3 = " for "
                          L14_3 = tostring
                          L15_3 = L6_3.material
                          L14_3 = L14_3(L15_3)
                          L11_3 = L11_3 .. L12_3 .. L13_3 .. L14_3
                          L10_3(L11_3)
                        end
                        L10_3 = SetVehicleModColor_1
                        L11_3 = L3_2
                        L12_3 = L9_3
                        L13_3 = 0
                        L14_3 = 0
                        L10_3(L11_3, L12_3, L13_3, L14_3)
                        L10_3 = SetVehicleCustomPrimaryColour
                        L11_3 = L3_2
                        L12_3 = L6_3.r
                        L13_3 = L6_3.g
                        L14_3 = L6_3.b
                        L10_3(L11_3, L12_3, L13_3, L14_3)
                        L10_3 = Config
                        L10_3 = L10_3.Debug
                        if L10_3 then
                          L10_3 = GetVehicleModColor_1
                          L11_3 = L3_2
                          L10_3, L11_3, L12_3 = L10_3(L11_3)
                          L13_3 = print
                          L14_3 = "  -> After re-apply, ModColor_1: "
                          L15_3 = L10_3
                          L16_3 = ", "
                          L17_3 = L11_3
                          L18_3 = ", "
                          L19_3 = L12_3
                          L14_3 = L14_3 .. L15_3 .. L16_3 .. L17_3 .. L18_3 .. L19_3
                          L13_3(L14_3)
                        end
                      end
                    end
                  end
                end
              end
          end
          else
            if "secondaryColor" == L4_3 then
              L7_3 = type
              L8_3 = L6_3
              L7_3 = L7_3(L8_3)
              if "table" == L7_3 then
                L7_3 = Config
                L7_3 = L7_3.Debug
                if L7_3 then
                  L7_3 = print
                  L8_3 = "^5[DEBUG syncVehicleMod]^0 Re-applying SECONDARY color:"
                  L7_3(L8_3)
                  L7_3 = print
                  L8_3 = "  modValue.material: "
                  L9_3 = tostring
                  L10_3 = L6_3.material
                  L9_3 = L9_3(L10_3)
                  L8_3 = L8_3 .. L9_3
                  L7_3(L8_3)
                end
                L7_3 = GetVehicleColours
                L8_3 = L3_2
                L7_3, L8_3 = L7_3(L8_3)
                L9_3 = L6_3.material
                if "chameleon" == L9_3 then
                  L9_3 = L6_3.index
                  if L9_3 then
                    L9_3 = ClearVehicleCustomSecondaryColour
                    L10_3 = L3_2
                    L9_3(L10_3)
                    L9_3 = Wait
                    L10_3 = 50
                    L9_3(L10_3)
                    L9_3 = SetVehicleColours
                    L10_3 = L3_2
                    L11_3 = L7_3
                    L12_3 = L6_3.index
                    L9_3(L10_3, L11_3, L12_3)
                    L9_3 = Config
                    L9_3 = L9_3.Debug
                    if L9_3 then
                      L9_3 = print
                      L10_3 = "  -> Applied CHAMELEON"
                      L9_3(L10_3)
                    end
                end
                else
                  L9_3 = L6_3.material
                  if "chrome" == L9_3 then
                    L9_3 = ClearVehicleCustomSecondaryColour
                    L10_3 = L3_2
                    L9_3(L10_3)
                    L9_3 = Wait
                    L10_3 = 50
                    L9_3(L10_3)
                    L9_3 = SetVehicleColours
                    L10_3 = L3_2
                    L11_3 = L7_3
                    L12_3 = 120
                    L9_3(L10_3, L11_3, L12_3)
                  else
                    L9_3 = L6_3.r
                    if L9_3 then
                      L9_3 = L6_3.g
                      if L9_3 then
                        L9_3 = L6_3.b
                        if L9_3 then
                          L9_3 = 0
                          L10_3 = L6_3.material
                          if "metallic" == L10_3 then
                            L9_3 = 1
                          else
                            L10_3 = L6_3.material
                            if "pearl" == L10_3 then
                              L9_3 = 2
                            else
                              L10_3 = L6_3.material
                              if "matte" == L10_3 then
                                L9_3 = 3
                              else
                                L10_3 = L6_3.material
                                if "metal" == L10_3 then
                                  L9_3 = 4
                                end
                              end
                            end
                          end
                          L10_3 = SetVehicleModColor_2
                          L11_3 = L3_2
                          L12_3 = L9_3
                          L13_3 = 0
                          L10_3(L11_3, L12_3, L13_3)
                          L10_3 = SetVehicleCustomSecondaryColour
                          L11_3 = L3_2
                          L12_3 = L6_3.r
                          L13_3 = L6_3.g
                          L14_3 = L6_3.b
                          L10_3(L11_3, L12_3, L13_3, L14_3)
                        end
                      end
                    end
                  end
                end
            end
            elseif "fullRepair" == L4_3 then
              L7_3 = fixVehicleDeformation
              L8_3 = L3_2
              L7_3(L8_3)
              L7_3 = SetVehicleEngineHealth
              L8_3 = L3_2
              L9_3 = 1000.0
              L7_3(L8_3, L9_3)
              L7_3 = SetVehicleBodyHealth
              L8_3 = L3_2
              L9_3 = 1000.0
              L7_3(L8_3, L9_3)
              L7_3 = SetVehicleUndriveable
              L8_3 = L3_2
              L9_3 = false
              L7_3(L8_3, L9_3)
              L7_3 = SetVehicleEngineOn
              L8_3 = L3_2
              L9_3 = true
              L10_3 = true
              L11_3 = false
              L7_3(L8_3, L9_3, L10_3, L11_3)
              L7_3 = 0
              L8_3 = 7
              L9_3 = 1
              for L10_3 = L7_3, L8_3, L9_3 do
                L11_3 = SetVehicleTyreFixed
                L12_3 = L3_2
                L13_3 = L10_3
                L11_3(L12_3, L13_3)
              end
            elseif "engineRepair" == L4_3 then
              L7_3 = SetVehicleEngineHealth
              L8_3 = L3_2
              L9_3 = 1000.0
              L7_3(L8_3, L9_3)
              L7_3 = SetVehicleUndriveable
              L8_3 = L3_2
              L9_3 = false
              L7_3(L8_3, L9_3)
              L7_3 = SetVehicleEngineOn
              L8_3 = L3_2
              L9_3 = true
              L10_3 = true
              L11_3 = false
              L7_3(L8_3, L9_3, L10_3, L11_3)
            elseif "bodyRepair" == L4_3 then
              L7_3 = SetVehicleBodyHealth
              L8_3 = L3_2
              L9_3 = 1000.0
              L7_3(L8_3, L9_3)
            elseif "tireRepair" == L4_3 then
              L7_3 = 0
              L8_3 = 7
              L9_3 = 1
              for L10_3 = L7_3, L8_3, L9_3 do
                L11_3 = SetVehicleTyreFixed
                L12_3 = L3_2
                L13_3 = L10_3
                L11_3(L12_3, L13_3)
              end
            elseif 48 == L4_3 or "48" == L4_3 or "livery" == L4_3 then
              L7_3 = L6_3
              L8_3 = type
              L9_3 = L7_3
              L8_3 = L8_3(L9_3)
              if "string" == L8_3 then
                L8_3 = tonumber
                L9_3 = L7_3
                L8_3 = L8_3(L9_3)
                L7_3 = L8_3 or L7_3
                if not L8_3 then
                  L7_3 = -1
                end
              end
              if nil == L7_3 then
                L7_3 = -1
              end
              L8_3 = Config
              L8_3 = L8_3.Debug
              if L8_3 then
                L8_3 = print
                L9_3 = "^5[DEBUG syncVehicleMod]^0 Force-applying livery="
                L10_3 = tostring
                L11_3 = L7_3
                L10_3 = L10_3(L11_3)
                L9_3 = L9_3 .. L10_3
                L8_3(L9_3)
              end
              L8_3 = GetVehicleLiveryCount
              L9_3 = L3_2
              L8_3 = L8_3(L9_3)
              if L8_3 > 0 then
                L8_3 = SetVehicleLivery
                L9_3 = L3_2
                L10_3 = L7_3
                L8_3(L9_3, L10_3)
              end
              L8_3 = SetVehicleMod
              L9_3 = L3_2
              L10_3 = 48
              L11_3 = L7_3
              L12_3 = false
              L8_3(L9_3, L10_3, L11_3, L12_3)
            end
          end
        end
      end
    end
  end
  L4_2(L5_2)
end
L13_1(L14_1, L15_1)
L13_1 = AddEventHandler
L14_1 = "onResourceStop"
function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if L1_2 ~= A0_2 then
    return
  end
  L1_2 = L8_1
  L1_2()
  L1_2 = L0_1.active
  if L1_2 then
    L1_2 = L0_1.vehicle
    if L1_2 then
      L1_2 = DoesEntityExist
      L2_2 = L0_1.vehicle
      L1_2 = L1_2(L2_2)
      if L1_2 then
        L1_2 = FreezeEntityPosition
        L2_2 = L0_1.vehicle
        L3_2 = false
        L1_2(L2_2, L3_2)
        L1_2 = 0
        L2_2 = 5
        L3_2 = 1
        for L4_2 = L1_2, L2_2, L3_2 do
          L5_2 = SetVehicleDoorShut
          L6_2 = L0_1.vehicle
          L7_2 = L4_2
          L8_2 = false
          L5_2(L6_2, L7_2, L8_2)
        end
      end
    end
  end
end
L13_1(L14_1, L15_1)
