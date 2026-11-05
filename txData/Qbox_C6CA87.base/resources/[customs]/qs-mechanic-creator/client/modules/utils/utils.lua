local L0_1, L1_1
function L0_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = Locales
  if L1_2 then
    L1_2 = Locales
    L2_2 = Config
    L2_2 = L2_2.Language
    L1_2 = L1_2[L2_2]
    if L1_2 then
      L1_2 = Locales
      L2_2 = Config
      L2_2 = L2_2.Language
      L1_2 = L1_2[L2_2]
      L1_2 = L1_2[A0_2]
      if L1_2 then
        L1_2 = string
        L1_2 = L1_2.format
        L2_2 = Locales
        L3_2 = Config
        L3_2 = L3_2.Language
        L2_2 = L2_2[L3_2]
        L2_2 = L2_2[A0_2]
        L3_2, L4_2, L5_2, L6_2 = ...
        return L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
    end
  end
  else
    L1_2 = Config
    L1_2 = L1_2.Debug
    if L1_2 then
      L1_2 = print
      L2_2 = "Translation ["
      L3_2 = Config
      L3_2 = L3_2.Language
      L4_2 = "]["
      L5_2 = A0_2
      L6_2 = "] does not exist"
      L2_2 = L2_2 .. L3_2 .. L4_2 .. L5_2 .. L6_2
      L1_2(L2_2)
    end
    L1_2 = "Translation ["
    L2_2 = Config
    L2_2 = L2_2.Language
    L3_2 = "]["
    L4_2 = A0_2
    L5_2 = "] does not exist"
    L1_2 = L1_2 .. L2_2 .. L3_2 .. L4_2 .. L5_2
    return L1_2
  end
end
_U = L0_1
function L0_1()
  local L0_2, L1_2
  L0_2 = Locales
  L1_2 = Config
  L1_2 = L1_2.Language
  L0_2 = L0_2[L1_2]
  if not L0_2 then
    L0_2 = {}
  end
  return L0_2
end
GetLocales = L0_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "number" == L1_2 then
    L1_2 = math
    L1_2 = L1_2.floor
    L2_2 = A0_2 + 0.5
    L1_2 = L1_2(L2_2)
    A0_2 = L1_2
    L1_2 = tostring
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    L2_2 = nil
    while true do
      L3_2 = string
      L3_2 = L3_2.gsub
      L4_2 = L1_2
      L5_2 = "^(-?%d+)(%d%d%d)"
      L6_2 = "%1,%2"
      L3_2, L4_2 = L3_2(L4_2, L5_2, L6_2)
      L2_2 = L4_2
      L1_2 = L3_2
      if 0 == L2_2 then
        break
      end
    end
    L3_2 = _U
    L4_2 = "CURRENCY_FORMAT"
    L5_2 = L1_2
    return L3_2(L4_2, L5_2)
  end
  L1_2 = _U
  L2_2 = "CURRENCY_FORMAT"
  L3_2 = tostring
  L4_2 = A0_2
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  return L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end
FormatCurrency = L0_1
function L0_1()
  local L0_2, L1_2
  L0_2 = _U
  L1_2 = "CURRENCY_SYMBOL"
  return L0_2(L1_2)
end
GetCurrencySymbol = L0_1
function L0_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  if A0_2 and A1_2 then
    L2_2 = PlaySoundFrontend
    L3_2 = -1
    L4_2 = A0_2
    L5_2 = A1_2
    L6_2 = 1
    L2_2(L3_2, L4_2, L5_2, L6_2)
  else
    L2_2 = PlaySoundFrontend
    L3_2 = -1
    L4_2 = "SELECT"
    L5_2 = "HUD_FREEMODE_SOUNDSET"
    L6_2 = 1
    L2_2(L3_2, L4_2, L5_2, L6_2)
  end
end
playSound = L0_1
function L0_1(A0_2, A1_2, A2_2, A3_2)
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
DefaultText3D = L0_1
L0_1 = {}
function L1_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2)
  local L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L6_2 = A4_2
  L7_2 = L0_1
  L7_2 = L7_2[L6_2]
  if not L7_2 then
    L7_2 = CreateThread
    function L8_2()
      local L0_3, L1_3, L2_3, L3_3
      L1_3 = L6_2
      L0_3 = L0_1
      L0_3[L1_3] = 5
      while true do
        L1_3 = L6_2
        L0_3 = L0_1
        L0_3 = L0_3[L1_3]
        if not (L0_3 > 0) then
          break
        end
        L1_3 = L6_2
        L0_3 = L0_1
        L3_3 = L6_2
        L2_3 = L0_1
        L2_3 = L2_3[L3_3]
        L2_3 = L2_3 - 1
        L0_3[L1_3] = L2_3
        L0_3 = Wait
        L1_3 = 0
        L0_3(L1_3)
      end
      L1_3 = L6_2
      L0_3 = L0_1
      L0_3[L1_3] = nil
      L0_3 = exports
      L0_3 = L0_3["qs-textui"]
      L1_3 = L0_3
      L0_3 = L0_3.DeleteDrawText3D
      L2_3 = A4_2
      L0_3(L1_3, L2_3)
    end
    L7_2(L8_2)
    L7_2 = TriggerEvent
    L8_2 = "textui:DrawText3D"
    L9_2 = A0_2
    L10_2 = A1_2
    L11_2 = A2_2
    L12_2 = A3_2
    L13_2 = A4_2
    L14_2 = A5_2
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  end
  L7_2 = L0_1
  L7_2[L6_2] = 5
end
DrawText3D = L1_1
function L1_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2
  L3_2 = false
  L4_2 = nil
  L5_2 = nil
  L6_2 = nil
  L7_2 = nil
  L8_2 = PlayerPedId
  L8_2 = L8_2()
  L9_2 = GetEntityHeading
  L10_2 = L8_2
  L9_2 = L9_2(L10_2)
  L10_2 = L9_2
  L11_2 = "carlift" == A1_2
  L12_2 = 0.0
  L13_2 = {}
  L14_2 = 0.0
  L15_2 = {}
  L15_2.xs_prop_x18_engine_hoist_02a = 180.0
  L16_2 = L15_2[A1_2]
  if not L16_2 then
    L16_2 = nil
  end
  if L16_2 then
    L10_2 = L9_2 + L16_2
  end
  function L17_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = L13_2
    if L0_3 then
      L0_3 = ipairs
      L1_3 = L13_2
      L0_3, L1_3, L2_3, L3_3 = L0_3(L1_3)
      for L4_3, L5_3 in L0_3, L1_3, L2_3, L3_3 do
        L6_3 = L5_3.entity
        if L6_3 then
          L6_3 = DoesEntityExist
          L7_3 = L5_3.entity
          L6_3 = L6_3(L7_3)
          if L6_3 then
            L6_3 = DeleteObject
            L7_3 = L5_3.entity
            L6_3(L7_3)
          end
        end
      end
    end
    L0_3 = {}
    L13_2 = L0_3
  end
  while true do
    L18_2 = Wait
    L19_2 = 0
    L18_2(L19_2)
    if L11_2 then
      L18_2 = DisableControlAction
      L19_2 = 0
      L20_2 = 172
      L21_2 = true
      L18_2(L19_2, L20_2, L21_2)
      L18_2 = DisableControlAction
      L19_2 = 0
      L20_2 = 173
      L21_2 = true
      L18_2(L19_2, L20_2, L21_2)
    end
    L18_2 = rayCastGamePlayCamera
    L19_2 = 1000.0
    L18_2, L19_2, L20_2 = L18_2(L19_2)
    L21_2 = L19_2
    if "prop" == A0_2 then
      L22_2 = vector3
      L23_2 = L19_2.x
      L24_2 = L19_2.y
      L25_2 = L19_2.z
      L25_2 = L25_2 + 0.15
      L22_2 = L22_2(L23_2, L24_2, L25_2)
      L21_2 = L22_2
    end
    if not L3_2 then
      L22_2 = SetFocusPosAndVel
      L23_2 = L21_2.x
      L24_2 = L21_2.y
      L25_2 = L21_2.z
      L26_2 = 0.0
      L27_2 = 0.0
      L28_2 = 0.0
      L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2)
      L22_2 = Wait
      L23_2 = 100
      L22_2(L23_2)
      if L11_2 then
        L22_2 = GetHashKey
        L23_2 = "qs-carlift"
        L22_2 = L22_2(L23_2)
        L23_2 = GetHashKey
        L24_2 = "qs-carlift-platform"
        L23_2 = L23_2(L24_2)
        L24_2 = lib
        L24_2 = L24_2.requestModel
        L25_2 = L22_2
        L26_2 = 10000
        L24_2(L25_2, L26_2)
        L24_2 = lib
        L24_2 = L24_2.requestModel
        L25_2 = L23_2
        L26_2 = 10000
        L24_2(L25_2, L26_2)
        L24_2 = HasModelLoaded
        L25_2 = L22_2
        L24_2 = L24_2(L25_2)
        if not L24_2 then
          L24_2 = ClearFocus
          L24_2()
          L24_2 = false
          return L24_2
        end
        L24_2 = HasModelLoaded
        L25_2 = L23_2
        L24_2 = L24_2(L25_2)
        if not L24_2 then
          L24_2 = ClearFocus
          L24_2()
          L24_2 = false
          return L24_2
        end
        L24_2 = CreateObject
        L25_2 = L22_2
        L26_2 = L21_2.x
        L27_2 = L21_2.y
        L28_2 = L21_2.z
        L29_2 = false
        L30_2 = false
        L31_2 = false
        L24_2 = L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2)
        L5_2 = L24_2
        L24_2 = PlaceObjectOnGroundProperly
        L25_2 = L5_2
        L24_2(L25_2)
        L24_2 = Wait
        L25_2 = 50
        L24_2(L25_2)
        L24_2 = GetEntityCoords
        L25_2 = L5_2
        L24_2 = L24_2(L25_2)
        L25_2 = L24_2.z
        L26_2 = L21_2.z
        L12_2 = L25_2 - L26_2
        L25_2 = SetEntityHeading
        L26_2 = L5_2
        L27_2 = L10_2
        L25_2(L26_2, L27_2)
        L25_2 = SetEntityCollision
        L26_2 = L5_2
        L27_2 = false
        L28_2 = false
        L25_2(L26_2, L27_2, L28_2)
        L25_2 = SetEntityAlpha
        L26_2 = L5_2
        L27_2 = 170
        L28_2 = false
        L25_2(L26_2, L27_2, L28_2)
        L25_2 = SetEntityVisible
        L26_2 = L5_2
        L27_2 = true
        L28_2 = false
        L25_2(L26_2, L27_2, L28_2)
        L25_2 = SetEntityAsMissionEntity
        L26_2 = L5_2
        L27_2 = true
        L28_2 = true
        L25_2(L26_2, L27_2, L28_2)
        L25_2 = GetEntityCoords
        L26_2 = L5_2
        L25_2 = L25_2(L26_2)
        L26_2 = math
        L26_2 = L26_2.rad
        L27_2 = L10_2
        L26_2 = L26_2(L27_2)
        L27_2 = math
        L27_2 = L27_2.sin
        L28_2 = L26_2
        L27_2 = L27_2(L28_2)
        L27_2 = -0.3 * L27_2
        L28_2 = math
        L28_2 = L28_2.cos
        L29_2 = L26_2
        L28_2 = L28_2(L29_2)
        L28_2 = 0.3 * L28_2
        L29_2 = CreateObject
        L30_2 = L23_2
        L31_2 = L25_2.x
        L31_2 = L31_2 + L27_2
        L32_2 = L25_2.y
        L32_2 = L32_2 + L28_2
        L33_2 = L25_2.z
        L33_2 = L33_2 - 0.08
        L34_2 = false
        L35_2 = false
        L36_2 = false
        L29_2 = L29_2(L30_2, L31_2, L32_2, L33_2, L34_2, L35_2, L36_2)
        L6_2 = L29_2
        L29_2 = SetEntityHeading
        L30_2 = L6_2
        L31_2 = L10_2
        L29_2(L30_2, L31_2)
        L29_2 = SetEntityCollision
        L30_2 = L6_2
        L31_2 = false
        L32_2 = false
        L29_2(L30_2, L31_2, L32_2)
        L29_2 = SetEntityAlpha
        L30_2 = L6_2
        L31_2 = 170
        L32_2 = false
        L29_2(L30_2, L31_2, L32_2)
        L29_2 = SetEntityVisible
        L30_2 = L6_2
        L31_2 = true
        L32_2 = false
        L29_2(L30_2, L31_2, L32_2)
        L29_2 = SetEntityAsMissionEntity
        L30_2 = L6_2
        L31_2 = true
        L32_2 = true
        L29_2(L30_2, L31_2, L32_2)
      else
        L22_2 = GetHashKey
        L23_2 = A1_2
        L22_2 = L22_2(L23_2)
        if 0 == L22_2 or -1 == L22_2 then
          L23_2 = ClearFocus
          L23_2()
          L23_2 = false
          return L23_2
        end
        L23_2 = IsModelValid
        L24_2 = L22_2
        L23_2 = L23_2(L24_2)
        if not L23_2 then
          L23_2 = ClearFocus
          L23_2()
          L23_2 = false
          return L23_2
        end
        L23_2 = lib
        L23_2 = L23_2.requestModel
        L24_2 = L22_2
        L25_2 = 10000
        L23_2(L24_2, L25_2)
        if "vehicle" == A0_2 then
          L23_2 = CreateVehicle
          L24_2 = L22_2
          L25_2 = L21_2.x
          L26_2 = L21_2.y
          L27_2 = L21_2.z
          L28_2 = L10_2
          L29_2 = false
          L30_2 = false
          L23_2 = L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
          L4_2 = L23_2
          L23_2 = SetEntityCollision
          L24_2 = L4_2
          L25_2 = false
          L26_2 = false
          L23_2(L24_2, L25_2, L26_2)
        elseif "prop" == A0_2 then
          L23_2 = CreateObject
          L24_2 = L22_2
          L25_2 = L21_2.x
          L26_2 = L21_2.y
          L27_2 = L21_2.z
          L28_2 = false
          L29_2 = false
          L30_2 = false
          L23_2 = L23_2(L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
          L4_2 = L23_2
          L23_2 = SetEntityCollision
          L24_2 = L4_2
          L25_2 = false
          L26_2 = false
          L23_2(L24_2, L25_2, L26_2)
        end
        if A2_2 then
          L23_2 = type
          L24_2 = A2_2
          L23_2 = L23_2(L24_2)
          if "table" == L23_2 then
            L23_2 = ipairs
            L24_2 = A2_2
            L23_2, L24_2, L25_2, L26_2 = L23_2(L24_2)
            for L27_2, L28_2 in L23_2, L24_2, L25_2, L26_2 do
              L29_2 = L28_2.model
              if L29_2 then
                L29_2 = GetHashKey
                L30_2 = L28_2.model
                L29_2 = L29_2(L30_2)
                if 0 ~= L29_2 and -1 ~= L29_2 then
                  L30_2 = IsModelValid
                  L31_2 = L29_2
                  L30_2 = L30_2(L31_2)
                  if L30_2 then
                    L30_2 = lib
                    L30_2 = L30_2.requestModel
                    L31_2 = L29_2
                    L32_2 = 10000
                    L30_2(L31_2, L32_2)
                    L30_2 = CreateObject
                    L31_2 = L29_2
                    L32_2 = L21_2.x
                    L33_2 = L21_2.y
                    L34_2 = L21_2.z
                    L35_2 = false
                    L36_2 = false
                    L37_2 = false
                    L30_2 = L30_2(L31_2, L32_2, L33_2, L34_2, L35_2, L36_2, L37_2)
                    L31_2 = SetEntityCollision
                    L32_2 = L30_2
                    L33_2 = false
                    L34_2 = false
                    L31_2(L32_2, L33_2, L34_2)
                    L31_2 = SetEntityAlpha
                    L32_2 = L30_2
                    L33_2 = 170
                    L34_2 = false
                    L31_2(L32_2, L33_2, L34_2)
                    L31_2 = SetEntityVisible
                    L32_2 = L30_2
                    L33_2 = true
                    L34_2 = false
                    L31_2(L32_2, L33_2, L34_2)
                    L31_2 = SetEntityAsMissionEntity
                    L32_2 = L30_2
                    L33_2 = true
                    L34_2 = true
                    L31_2(L32_2, L33_2, L34_2)
                    L31_2 = L28_2.offset
                    if not L31_2 then
                      L31_2 = {}
                    end
                    L32_2 = table
                    L32_2 = L32_2.insert
                    L33_2 = L13_2
                    L34_2 = {}
                    L34_2.entity = L30_2
                    L35_2 = vector3
                    L36_2 = L31_2.x
                    if not L36_2 then
                      L36_2 = 0.0
                    end
                    L37_2 = L31_2.y
                    if not L37_2 then
                      L37_2 = 0.0
                    end
                    L38_2 = L31_2.z
                    if not L38_2 then
                      L38_2 = 0.0
                    end
                    L35_2 = L35_2(L36_2, L37_2, L38_2)
                    L34_2.offset = L35_2
                    L32_2(L33_2, L34_2)
                  end
                end
              end
            end
          end
        end
      end
      L3_2 = true
    end
    L22_2 = IsControlPressed
    L23_2 = 1
    L24_2 = 174
    L22_2 = L22_2(L23_2, L24_2)
    if L22_2 then
      L10_2 = L10_2 - 0.5
    end
    L22_2 = IsControlPressed
    L23_2 = 1
    L24_2 = 175
    L22_2 = L22_2(L23_2, L24_2)
    if L22_2 then
      L10_2 = L10_2 + 0.5
    end
    if L11_2 then
      L22_2 = IsDisabledControlPressed
      L23_2 = 0
      L24_2 = 172
      L22_2 = L22_2(L23_2, L24_2)
      if L22_2 then
        L14_2 = L14_2 + 0.01
      end
      L22_2 = IsDisabledControlPressed
      L23_2 = 0
      L24_2 = 173
      L22_2 = L22_2(L23_2, L24_2)
      if L22_2 then
        L14_2 = L14_2 - 0.01
      end
    end
    L22_2 = 360.0
    if L10_2 >= L22_2 then
      L10_2 = L10_2 - 360.0
    elseif L10_2 < 0.0 then
      L10_2 = L10_2 + 360.0
    end
    if L11_2 then
      if L5_2 then
        L22_2 = DoesEntityExist
        L23_2 = L5_2
        L22_2 = L22_2(L23_2)
        if L22_2 then
          L22_2 = SetEntityCoords
          L23_2 = L5_2
          L24_2 = L21_2.x
          L25_2 = L21_2.y
          L26_2 = L21_2.z
          L26_2 = L26_2 + L12_2
          L26_2 = L26_2 + L14_2
          L27_2 = false
          L28_2 = false
          L29_2 = false
          L30_2 = false
          L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
          L22_2 = SetEntityHeading
          L23_2 = L5_2
          L24_2 = L10_2
          L22_2(L23_2, L24_2)
        end
      end
      if L6_2 then
        L22_2 = DoesEntityExist
        L23_2 = L6_2
        L22_2 = L22_2(L23_2)
        if L22_2 and L5_2 then
          L22_2 = GetEntityCoords
          L23_2 = L5_2
          L22_2 = L22_2(L23_2)
          L23_2 = math
          L23_2 = L23_2.rad
          L24_2 = L10_2
          L23_2 = L23_2(L24_2)
          L24_2 = SetEntityCoords
          L25_2 = L6_2
          L26_2 = L22_2.x
          L27_2 = math
          L27_2 = L27_2.sin
          L28_2 = L23_2
          L27_2 = L27_2(L28_2)
          L27_2 = -0.3 * L27_2
          L26_2 = L26_2 + L27_2
          L27_2 = L22_2.y
          L28_2 = math
          L28_2 = L28_2.cos
          L29_2 = L23_2
          L28_2 = L28_2(L29_2)
          L28_2 = 0.3 * L28_2
          L27_2 = L27_2 + L28_2
          L28_2 = L22_2.z
          L28_2 = L28_2 - 0.08
          L29_2 = false
          L30_2 = false
          L31_2 = false
          L32_2 = false
          L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2, L31_2, L32_2)
          L24_2 = SetEntityHeading
          L25_2 = L6_2
          L26_2 = L10_2
          L24_2(L25_2, L26_2)
        end
      end
    else
      L22_2 = SetEntityCoords
      L23_2 = L4_2
      L24_2 = L21_2.x
      L25_2 = L21_2.y
      L26_2 = L21_2.z
      L27_2 = false
      L28_2 = false
      L29_2 = false
      L30_2 = false
      L22_2(L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
      L22_2 = PlaceObjectOnGroundProperly
      L23_2 = L4_2
      L22_2(L23_2)
      L22_2 = SetEntityHeading
      L23_2 = L4_2
      L24_2 = L10_2
      L22_2(L23_2, L24_2)
      L22_2 = SetEntityAlpha
      L23_2 = L4_2
      L24_2 = 180
      L25_2 = 0
      L22_2(L23_2, L24_2, L25_2)
      if L13_2 then
        L22_2 = #L13_2
        if L22_2 > 0 then
          L22_2 = GetEntityCoords
          L23_2 = L4_2
          L22_2 = L22_2(L23_2)
          L23_2 = math
          L23_2 = L23_2.rad
          L24_2 = L10_2
          L23_2 = L23_2(L24_2)
          L24_2 = math
          L24_2 = L24_2.sin
          L25_2 = L23_2
          L24_2 = L24_2(L25_2)
          L25_2 = math
          L25_2 = L25_2.cos
          L26_2 = L23_2
          L25_2 = L25_2(L26_2)
          L26_2 = ipairs
          L27_2 = L13_2
          L26_2, L27_2, L28_2, L29_2 = L26_2(L27_2)
          for L30_2, L31_2 in L26_2, L27_2, L28_2, L29_2 do
            L32_2 = L31_2.entity
            if L32_2 then
              L32_2 = DoesEntityExist
              L33_2 = L31_2.entity
              L32_2 = L32_2(L33_2)
              if L32_2 then
                L32_2 = L31_2.offset
                if not L32_2 then
                  L32_2 = vector3
                  L33_2 = 0.0
                  L34_2 = 0.0
                  L35_2 = 0.0
                  L32_2 = L32_2(L33_2, L34_2, L35_2)
                end
                L33_2 = SetEntityCoords
                L34_2 = L31_2.entity
                L35_2 = L22_2.x
                L36_2 = L32_2.x
                L36_2 = L36_2 * L25_2
                L37_2 = L32_2.y
                L37_2 = L37_2 * L24_2
                L36_2 = L36_2 - L37_2
                L35_2 = L35_2 + L36_2
                L36_2 = L22_2.y
                L37_2 = L32_2.x
                L37_2 = L37_2 * L24_2
                L38_2 = L32_2.y
                L38_2 = L38_2 * L25_2
                L37_2 = L37_2 + L38_2
                L36_2 = L36_2 + L37_2
                L37_2 = L22_2.z
                L38_2 = L32_2.z
                L37_2 = L37_2 + L38_2
                L38_2 = false
                L39_2 = false
                L40_2 = false
                L41_2 = false
                L33_2(L34_2, L35_2, L36_2, L37_2, L38_2, L39_2, L40_2, L41_2)
                L33_2 = SetEntityHeading
                L34_2 = L31_2.entity
                L35_2 = L10_2
                L33_2(L34_2, L35_2)
                L33_2 = SetEntityAlpha
                L34_2 = L31_2.entity
                L35_2 = 180
                L36_2 = false
                L33_2(L34_2, L35_2, L36_2)
              end
            end
          end
        end
      end
    end
    L22_2 = L21_2.z
    L22_2 = L22_2 + 2.0
    if "prop" == A0_2 and "prop_mp_base_marker" == A1_2 then
      L23_2 = L21_2.z
      L22_2 = L23_2 + 1.5
    end
    L23_2 = _U
    L24_2 = "CREATOR_CONFIRM_POSITION"
    L23_2 = L23_2(L24_2)
    if L11_2 then
      L24_2 = _U
      L25_2 = "CREATOR_CARLIFT_OBJECTS"
      L24_2 = L24_2(L25_2)
      L25_2 = "\n"
      L26_2 = L23_2
      L27_2 = "\n"
      L28_2 = _U
      L29_2 = "CREATOR_HEIGHT_HINT"
      L28_2 = L28_2(L29_2)
      L24_2 = L24_2 .. L25_2 .. L26_2 .. L27_2 .. L28_2
      L23_2 = L24_2
    end
    L24_2 = DefaultText3D
    L25_2 = L21_2.x
    L26_2 = L21_2.y
    L27_2 = L22_2
    L28_2 = L23_2
    L24_2(L25_2, L26_2, L27_2, L28_2)
    L24_2 = IsControlJustPressed
    L25_2 = 1
    L26_2 = 38
    L24_2 = L24_2(L25_2, L26_2)
    if L24_2 then
      if L11_2 then
        if L5_2 then
          L24_2 = DoesEntityExist
          L25_2 = L5_2
          L24_2 = L24_2(L25_2)
          if L24_2 then
            L24_2 = GetEntityCoords
            L25_2 = L5_2
            L24_2 = L24_2(L25_2)
            L25_2 = vector3
            L26_2 = L24_2.x
            L27_2 = L24_2.y
            L28_2 = L24_2.z
            L28_2 = L28_2 - 0.325
            L25_2 = L25_2(L26_2, L27_2, L28_2)
            L7_2 = L25_2
            L25_2 = DeleteObject
            L26_2 = L5_2
            L25_2(L26_2)
          end
        end
        if L6_2 then
          L24_2 = DoesEntityExist
          L25_2 = L6_2
          L24_2 = L24_2(L25_2)
          if L24_2 then
            L24_2 = DeleteObject
            L25_2 = L6_2
            L24_2(L25_2)
          end
        end
      else
        if L4_2 then
          L24_2 = DoesEntityExist
          L25_2 = L4_2
          L24_2 = L24_2(L25_2)
          if L24_2 then
            L24_2 = GetEntityCoords
            L25_2 = L4_2
            L24_2 = L24_2(L25_2)
            L7_2 = L24_2
        end
        else
          L7_2 = L21_2
        end
        if "vehicle" == A0_2 then
          L24_2 = DeleteVehicle
          L25_2 = L4_2
          L24_2(L25_2)
        elseif "prop" == A0_2 then
          L24_2 = DeleteObject
          L25_2 = L4_2
          L24_2(L25_2)
        end
      end
      L24_2 = L17_2
      L24_2()
      L24_2 = ClearFocus
      L24_2()
      L24_2 = vector4
      L25_2 = L7_2.x
      L26_2 = L7_2.y
      L27_2 = L7_2.z
      L28_2 = L10_2
      return L24_2(L25_2, L26_2, L27_2, L28_2)
    end
    L24_2 = IsControlJustPressed
    L25_2 = 1
    L26_2 = 194
    L24_2 = L24_2(L25_2, L26_2)
    if L24_2 then
      if L11_2 then
        if L5_2 then
          L24_2 = DoesEntityExist
          L25_2 = L5_2
          L24_2 = L24_2(L25_2)
          if L24_2 then
            L24_2 = DeleteObject
            L25_2 = L5_2
            L24_2(L25_2)
          end
        end
        if L6_2 then
          L24_2 = DoesEntityExist
          L25_2 = L6_2
          L24_2 = L24_2(L25_2)
          if L24_2 then
            L24_2 = DeleteObject
            L25_2 = L6_2
            L24_2(L25_2)
          end
        end
      elseif "vehicle" == A0_2 then
        L24_2 = DeleteVehicle
        L25_2 = L4_2
        L24_2(L25_2)
      elseif "prop" == A0_2 then
        L24_2 = DeleteObject
        L25_2 = L4_2
        L24_2(L25_2)
      end
      L24_2 = L17_2
      L24_2()
      L24_2 = ClearFocus
      L24_2()
      L24_2 = nil
      return L24_2
    end
  end
end
getPosition = L1_1
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
  L1_2 = GetGameplayCamRot
  L1_2 = L1_2()
  L2_2 = GetGameplayCamCoord
  L2_2 = L2_2()
  L3_2 = rotationToDirection
  L4_2 = L1_2
  L3_2 = L3_2(L4_2)
  L4_2 = {}
  L5_2 = L2_2.x
  L6_2 = L3_2.x
  L6_2 = L6_2 * A0_2
  L5_2 = L5_2 + L6_2
  L4_2.x = L5_2
  L5_2 = L2_2.y
  L6_2 = L3_2.y
  L6_2 = L6_2 * A0_2
  L5_2 = L5_2 + L6_2
  L4_2.y = L5_2
  L5_2 = L2_2.z
  L6_2 = L3_2.z
  L6_2 = L6_2 * A0_2
  L5_2 = L5_2 + L6_2
  L4_2.z = L5_2
  L5_2 = GetShapeTestResult
  L6_2 = StartShapeTestRay
  L7_2 = L2_2.x
  L8_2 = L2_2.y
  L9_2 = L2_2.z
  L10_2 = L4_2.x
  L11_2 = L4_2.y
  L12_2 = L4_2.z
  L13_2 = -1
  L14_2 = PlayerPedId
  L14_2 = L14_2()
  L15_2 = 0
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2)
  L10_2 = L6_2
  L11_2 = L7_2
  L12_2 = L9_2
  return L10_2, L11_2, L12_2
end
rayCastGamePlayCamera = L1_1
function L1_1(A0_2)
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
rotationToDirection = L1_1
