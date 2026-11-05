local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1
L0_1 = {}
L1_1 = {}
L2_1 = {}
L3_1 = {}
L4_1 = {}
L5_1 = false
L6_1 = false
L7_1 = 0
function L8_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Config
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.debug
    if L1_2 then
      L1_2 = print
      L2_2 = "^5[apex_blips]^7 "
      L3_2 = A0_2
      L2_2 = L2_2 .. L3_2
      L1_2(L2_2)
    end
  end
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = TriggerEvent
  L2_2 = "chat:addMessage"
  L3_2 = {}
  L4_2 = {}
  L5_2 = 31
  L6_2 = 94
  L7_2 = 255
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L3_2.color = L4_2
  L3_2.multiline = true
  L4_2 = {}
  L5_2 = "APEX BLIPS"
  L6_2 = A0_2
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L3_2.args = L4_2
  L1_2(L2_2, L3_2)
end
Notify = L9_1
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = A0_2.icon
  if not L1_2 then
    L1_2 = {}
  end
  L2_2 = L1_2.mode
  if "image" ~= L2_2 then
    L2_2 = L1_2.sprite
    if not L2_2 then
      L2_2 = Config
      L2_2 = L2_2.defaults
      L2_2 = L2_2.sprite
    end
    L3_2 = false
    return L2_2, L3_2
  end
  L2_2 = nil
  L3_2 = type
  L4_2 = L1_2.data
  L3_2 = L3_2(L4_2)
  if "string" == L3_2 then
    L3_2 = {}
    L4_2 = "inline_"
    L5_2 = tostring
    L6_2 = GetHashKey
    L7_2 = L1_2.data
    L6_2, L7_2 = L6_2(L7_2)
    L5_2 = L5_2(L6_2, L7_2)
    L4_2 = L4_2 .. L5_2
    L3_2.id = L4_2
    L4_2 = L1_2.data
    L3_2.data = L4_2
    L2_2 = L3_2
  else
    L3_2 = type
    L4_2 = L1_2.image
    L3_2 = L3_2(L4_2)
    if "string" == L3_2 then
      L4_2 = L1_2.image
      L3_2 = L1_1
      L2_2 = L3_2[L4_2]
    end
  end
  if L2_2 then
    L3_2 = Slots
    L3_2 = L3_2.SpriteFor
    L4_2 = L2_2
    L5_2 = L1_2.shape
    L3_2 = L3_2(L4_2, L5_2)
    if L3_2 then
      goto lbl_55
    end
  end
  L3_2 = nil
  ::lbl_55::
  if nil ~= L3_2 then
    L4_2 = L3_2
    L5_2 = false
    return L4_2, L5_2
  end
  L4_2 = Config
  L4_2 = L4_2.engine
  L4_2 = L4_2.fallbackSprite
  if not L4_2 then
    L4_2 = 1
  end
  L5_2 = true
  return L4_2, L5_2
end
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = nil
  L2_2 = type
  L3_2 = A0_2.image
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L1_2 = A0_2.image
  else
    L2_2 = type
    L3_2 = A0_2.data
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = "inline_"
      L3_2 = tostring
      L4_2 = GetHashKey
      L5_2 = A0_2.data
      L4_2, L5_2 = L4_2(L5_2)
      L3_2 = L3_2(L4_2, L5_2)
      L2_2 = L2_2 .. L3_2
      L1_2 = L2_2
    else
      L2_2 = nil
      return L2_2
    end
  end
  L2_2 = A0_2.shape
  if "rounded" ~= L2_2 and "circle" ~= L2_2 then
    L2_2 = "none"
  end
  L3_2 = L1_2
  L4_2 = "|"
  L5_2 = L2_2
  L3_2 = L3_2 .. L4_2 .. L5_2
  return L3_2
end
function L11_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2
  L2_2 = A0_2.zone
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = table
  L3_2 = L3_2.concat
  L4_2 = {}
  L5_2 = A1_2
  L6_2 = A0_2.icon
  if L6_2 then
    L6_2 = A0_2.icon
    L6_2 = L6_2.shape
    if L6_2 then
      goto lbl_19
    end
  end
  L6_2 = ""
  ::lbl_19::
  L7_2 = A0_2.name
  L8_2 = A0_2.pos
  L8_2 = L8_2.x
  L9_2 = A0_2.pos
  L9_2 = L9_2.y
  L10_2 = A0_2.pos
  L10_2 = L10_2.z
  L11_2 = A0_2.colour
  L12_2 = A0_2.scale
  L13_2 = A0_2.alpha
  L14_2 = A0_2.category
  L15_2 = A0_2.display
  L16_2 = A0_2.shortRange
  if L16_2 then
    L16_2 = 1
    if L16_2 then
      goto lbl_38
    end
  end
  L16_2 = 0
  ::lbl_38::
  L17_2 = A0_2.flash
  if L17_2 then
    L17_2 = 1
    if L17_2 then
      goto lbl_45
    end
  end
  L17_2 = 0
  ::lbl_45::
  L18_2 = A0_2.route
  if L18_2 then
    L18_2 = 1
    if L18_2 then
      goto lbl_52
    end
  end
  L18_2 = 0
  ::lbl_52::
  L19_2 = A0_2.routeColour
  L20_2 = L2_2.mode
  if not L20_2 then
    L20_2 = "none"
  end
  L21_2 = L2_2.radius
  if not L21_2 then
    L21_2 = 0
  end
  L22_2 = L2_2.w
  if not L22_2 then
    L22_2 = 0
  end
  L23_2 = L2_2.h
  if not L23_2 then
    L23_2 = 0
  end
  L24_2 = L2_2.rot
  if not L24_2 then
    L24_2 = 0
  end
  L25_2 = L2_2.colour
  if not L25_2 then
    L25_2 = 0
  end
  L26_2 = L2_2.alpha
  if not L26_2 then
    L26_2 = 0
  end
  L4_2[1] = L5_2
  L4_2[2] = L6_2
  L4_2[3] = L7_2
  L4_2[4] = L8_2
  L4_2[5] = L9_2
  L4_2[6] = L10_2
  L4_2[7] = L11_2
  L4_2[8] = L12_2
  L4_2[9] = L13_2
  L4_2[10] = L14_2
  L4_2[11] = L15_2
  L4_2[12] = L16_2
  L4_2[13] = L17_2
  L4_2[14] = L18_2
  L4_2[15] = L19_2
  L4_2[16] = L20_2
  L4_2[17] = L21_2
  L4_2[18] = L22_2
  L4_2[19] = L23_2
  L4_2[20] = L24_2
  L4_2[21] = L25_2
  L4_2[22] = L26_2
  L5_2 = "|"
  return L3_2(L4_2, L5_2)
end
function L12_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L3_1
  L1_2 = L1_2[A0_2]
  if nil == L1_2 then
    return
  end
  L2_2 = L1_2.blip
  if nil ~= L2_2 then
    L2_2 = DoesBlipExist
    L3_2 = L1_2.blip
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = RemoveBlip
      L3_2 = L1_2.blip
      L2_2(L3_2)
    end
  end
  L2_2 = L1_2.zone
  if nil ~= L2_2 then
    L2_2 = DoesBlipExist
    L3_2 = L1_2.zone
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = RemoveBlip
      L3_2 = L1_2.zone
      L2_2(L3_2)
    end
  end
  L2_2 = L3_1
  L2_2[A0_2] = nil
end
function L13_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = A0_2.pos
  L3_2 = AddBlipForCoord
  L4_2 = L2_2.x
  L4_2 = L4_2 + 0.0
  L5_2 = L2_2.y
  L5_2 = L5_2 + 0.0
  L6_2 = L2_2.z
  L6_2 = L6_2 + 0.0
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  L4_2 = SetBlipSprite
  L5_2 = L3_2
  L6_2 = A1_2
  L4_2(L5_2, L6_2)
  L4_2 = SetBlipDisplay
  L5_2 = L3_2
  L6_2 = A0_2.display
  if not L6_2 then
    L6_2 = 2
  end
  L4_2(L5_2, L6_2)
  L4_2 = SetBlipScale
  L5_2 = L3_2
  L6_2 = A0_2.scale
  if not L6_2 then
    L6_2 = 1.0
  end
  L6_2 = L6_2 + 0.0
  L4_2(L5_2, L6_2)
  L4_2 = SetBlipAlpha
  L5_2 = L3_2
  L6_2 = A0_2.alpha
  if not L6_2 then
    L6_2 = 255
  end
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.icon
  if L4_2 then
    L4_2 = A0_2.icon
    L4_2 = L4_2.mode
    if "image" ~= L4_2 then
      L4_2 = A0_2.colour
      if not L4_2 then
        L4_2 = 0
      end
      if L4_2 > 0 then
        L4_2 = SetBlipColour
        L5_2 = L3_2
        L6_2 = A0_2.colour
        L4_2(L5_2, L6_2)
      end
    end
  end
  L4_2 = SetBlipAsShortRange
  L5_2 = L3_2
  L6_2 = A0_2.shortRange
  L6_2 = true == L6_2
  L4_2(L5_2, L6_2)
  L4_2 = A0_2.category
  if not L4_2 then
    L4_2 = 1
  end
  if 1 ~= L4_2 then
    L4_2 = SetBlipCategory
    L5_2 = L3_2
    L6_2 = A0_2.category
    L4_2(L5_2, L6_2)
  end
  L4_2 = A0_2.flash
  if L4_2 then
    L4_2 = SetBlipFlashes
    L5_2 = L3_2
    L6_2 = true
    L4_2(L5_2, L6_2)
  end
  L4_2 = A0_2.route
  if L4_2 then
    L4_2 = SetBlipRoute
    L5_2 = L3_2
    L6_2 = true
    L4_2(L5_2, L6_2)
    L4_2 = SetBlipRouteColour
    L5_2 = L3_2
    L6_2 = A0_2.routeColour
    if not L6_2 then
      L6_2 = 0
    end
    L4_2(L5_2, L6_2)
  end
  L4_2 = BeginTextCommandSetBlipName
  L5_2 = "STRING"
  L4_2(L5_2)
  L4_2 = AddTextComponentSubstringPlayerName
  L5_2 = A0_2.name
  if not L5_2 then
    L5_2 = "Blip"
  end
  L4_2(L5_2)
  L4_2 = EndTextCommandSetBlipName
  L5_2 = L3_2
  L4_2(L5_2)
  L4_2 = nil
  L5_2 = A0_2.zone
  if not L5_2 then
    L5_2 = {}
  end
  L6_2 = L5_2.mode
  if "radius" == L6_2 then
    L6_2 = AddBlipForRadius
    L7_2 = L2_2.x
    L7_2 = L7_2 + 0.0
    L8_2 = L2_2.y
    L8_2 = L8_2 + 0.0
    L9_2 = L2_2.z
    L9_2 = L9_2 + 0.0
    L10_2 = L5_2.radius
    if not L10_2 then
      L10_2 = 50.0
    end
    L10_2 = L10_2 + 0.0
    L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    L4_2 = L6_2
  else
    L6_2 = L5_2.mode
    if "area" == L6_2 then
      L6_2 = AddBlipForArea
      L7_2 = L2_2.x
      L7_2 = L7_2 + 0.0
      L8_2 = L2_2.y
      L8_2 = L8_2 + 0.0
      L9_2 = L2_2.z
      L9_2 = L9_2 + 0.0
      L10_2 = L5_2.w
      if not L10_2 then
        L10_2 = 100.0
      end
      L10_2 = L10_2 + 0.0
      L11_2 = L5_2.h
      if not L11_2 then
        L11_2 = 100.0
      end
      L11_2 = L11_2 + 0.0
      L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
      L4_2 = L6_2
      L6_2 = SetBlipRotation
      L7_2 = L4_2
      L8_2 = math
      L8_2 = L8_2.floor
      L9_2 = L5_2.rot
      if not L9_2 then
        L9_2 = 0
      end
      L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2)
      L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
    end
  end
  if nil ~= L4_2 then
    L6_2 = SetBlipColour
    L7_2 = L4_2
    L8_2 = L5_2.colour
    if not L8_2 then
      L8_2 = 1
    end
    L6_2(L7_2, L8_2)
    L6_2 = SetBlipAlpha
    L7_2 = L4_2
    L8_2 = L5_2.alpha
    if not L8_2 then
      L8_2 = 80
    end
    L6_2(L7_2, L8_2)
    L6_2 = SetBlipAsShortRange
    L7_2 = L4_2
    L8_2 = false
    L6_2(L7_2, L8_2)
    L6_2 = SetBlipHighDetail
    L7_2 = L4_2
    L8_2 = true
    L6_2(L7_2, L8_2)
  end
  L6_2 = L3_2
  L7_2 = L4_2
  return L6_2, L7_2
end
L14_1 = false
function L15_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L0_2 = L14_1
  if L0_2 then
    return
  end
  L0_2 = true
  L14_1 = L0_2
  L0_2 = {}
  L1_2 = L5_1
  if not L1_2 then
    L1_2 = 1
    L2_2 = L0_1
    L2_2 = #L2_2
    L3_2 = 1
    for L4_2 = L1_2, L2_2, L3_2 do
      L5_2 = L0_1
      L5_2 = L5_2[L4_2]
      L5_2 = L5_2.icon
      if L5_2 then
        L6_2 = L5_2.mode
        if "image" == L6_2 then
          L6_2 = L10_1
          L7_2 = L5_2
          L6_2 = L6_2(L7_2)
          if nil ~= L6_2 then
            L0_2[L6_2] = true
          end
        end
      end
    end
    L1_2 = pairs
    L2_2 = L2_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = L6_2.icon
      if L7_2 then
        L8_2 = L7_2.mode
        if "image" == L8_2 then
          L8_2 = L10_1
          L9_2 = L7_2
          L8_2 = L8_2(L9_2)
          if nil ~= L8_2 then
            L0_2[L8_2] = true
          end
        end
      end
    end
  end
  L1_2 = Slots
  L1_2 = L1_2.Prune
  L2_2 = L0_2
  L1_2(L2_2)
  L1_2 = {}
  L2_2 = L5_1
  if not L2_2 then
    L2_2 = 1
    L3_2 = L0_1
    L3_2 = #L3_2
    L4_2 = 1
    for L5_2 = L2_2, L3_2, L4_2 do
      L6_2 = L0_1
      L6_2 = L6_2[L5_2]
      L7_2 = L9_1
      L8_2 = L6_2
      L7_2 = L7_2(L8_2)
      L8_2 = L6_2.id
      L9_2 = {}
      L9_2.def = L6_2
      L9_2.sprite = L7_2
      L1_2[L8_2] = L9_2
    end
    L2_2 = pairs
    L3_2 = L2_1
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
      L8_2 = L9_1
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      L9_2 = {}
      L9_2.def = L7_2
      L9_2.sprite = L8_2
      L1_2[L6_2] = L9_2
    end
  end
  L2_2 = pairs
  L3_2 = L3_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2 in L2_2, L3_2, L4_2, L5_2 do
    L7_2 = L1_2[L6_2]
    if nil == L7_2 then
      L7_2 = L12_1
      L8_2 = L6_2
      L7_2(L8_2)
      L7_2 = L4_1
      L7_2[L6_2] = nil
    end
  end
  L2_2 = pairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L11_1
    L9_2 = L7_2.def
    L10_2 = L7_2.sprite
    L8_2 = L8_2(L9_2, L10_2)
    L9_2 = L3_1
    L9_2 = L9_2[L6_2]
    if nil ~= L9_2 then
      L10_2 = L9_2.sig
      if L10_2 == L8_2 then
        goto lbl_136
      end
    end
    L10_2 = L12_1
    L11_2 = L6_2
    L10_2(L11_2)
    L10_2 = L13_1
    L11_2 = L7_2.def
    L12_2 = L7_2.sprite
    L10_2, L11_2 = L10_2(L11_2, L12_2)
    L12_2 = L3_1
    L13_2 = {}
    L13_2.blip = L10_2
    L13_2.zone = L11_2
    L13_2.sig = L8_2
    L12_2[L6_2] = L13_2
    ::lbl_136::
  end
  L2_2 = false
  L14_1 = L2_2
end
L16_1 = Slots
L16_1 = L16_1.OnReady
function L17_1()
  local L0_2, L1_2
  L0_2 = L15_1
  L0_2()
end
L16_1(L17_1)
L16_1 = RegisterNetEvent
L17_1 = "apex_blips:sync"
function L18_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = type
  L2_2 = A0_2.blips
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.blips
    if L1_2 then
      goto lbl_17
    end
  end
  L1_2 = {}
  ::lbl_17::
  L0_1 = L1_2
  L1_2 = type
  L2_2 = A0_2.images
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.images
    if L1_2 then
      goto lbl_28
    end
  end
  L1_2 = {}
  ::lbl_28::
  L1_1 = L1_2
  L1_2 = true
  L6_1 = L1_2
  L1_2 = L8_1
  L2_2 = "sync: %d blips for me"
  L3_2 = L2_2
  L2_2 = L2_2.format
  L4_2 = L0_1
  L4_2 = #L4_2
  L2_2, L3_2, L4_2 = L2_2(L3_2, L4_2)
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = L15_1
  L1_2()
end
L16_1(L17_1, L18_1)
L16_1 = RegisterNetEvent
L17_1 = "apex_blips:notify"
function L18_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = Notify
    L2_2 = A0_2
    L1_2(L2_2)
  end
end
L16_1(L17_1, L18_1)
L16_1 = CreateThread
function L17_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = Config
  L0_2 = L0_2.sync
  L0_2 = L0_2.retryMinMs
  L1_2 = 1
  L2_2 = Config
  L2_2 = L2_2.sync
  L2_2 = L2_2.retryMax
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L6_1
    if L5_2 then
      return
    end
    L5_2 = TriggerServerEvent
    L6_2 = "apex_blips:requestSync"
    L5_2(L6_2)
    L5_2 = Wait
    L6_2 = L0_2
    L5_2(L6_2)
    L5_2 = math
    L5_2 = L5_2.min
    L6_2 = L0_2 * 2
    L7_2 = Config
    L7_2 = L7_2.sync
    L7_2 = L7_2.retryMaxMs
    L5_2 = L5_2(L6_2, L7_2)
    L0_2 = L5_2
  end
end
L16_1(L17_1)
L16_1 = AddEventHandler
L17_1 = "playerSpawned"
function L18_1()
  local L0_2, L1_2
  L0_2 = TriggerServerEvent
  L1_2 = "apex_blips:requestSync"
  L0_2(L1_2)
end
L16_1(L17_1, L18_1)
L16_1 = false
function L17_1()
  local L0_2, L1_2, L2_2
  L0_2 = L16_1
  if L0_2 then
    return
  end
  L0_2 = true
  L16_1 = L0_2
  L0_2 = SetTimeout
  L1_2 = 800
  function L2_2()
    local L0_3, L1_3
    L0_3 = false
    L16_1 = L0_3
    L0_3 = TriggerServerEvent
    L1_3 = "apex_blips:requestSync"
    L0_3(L1_3)
  end
  L0_2(L1_2, L2_2)
end
L18_1 = RegisterNetEvent
L19_1 = "esx:playerLoaded"
L20_1 = L17_1
L18_1(L19_1, L20_1)
L18_1 = RegisterNetEvent
L19_1 = "esx:setJob"
L20_1 = L17_1
L18_1(L19_1, L20_1)
L18_1 = RegisterNetEvent
L19_1 = "QBCore:Client:OnPlayerLoaded"
L20_1 = L17_1
L18_1(L19_1, L20_1)
L18_1 = RegisterNetEvent
L19_1 = "QBCore:Client:OnJobUpdate"
L20_1 = L17_1
L18_1(L19_1, L20_1)
function L18_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L3_2 = A0_2.zone
  L4_2 = A0_2.pos
  L4_2 = L4_2.x
  L4_2 = A1_2 - L4_2
  L5_2 = A0_2.pos
  L5_2 = L5_2.y
  L5_2 = A2_2 - L5_2
  L6_2 = L3_2.mode
  if "radius" == L6_2 then
    L6_2 = L4_2 * L4_2
    L7_2 = L5_2 * L5_2
    L6_2 = L6_2 + L7_2
    L7_2 = L3_2.radius
    L8_2 = L3_2.radius
    L7_2 = L7_2 * L8_2
    L6_2 = L6_2 <= L7_2
    return L6_2
  end
  L6_2 = math
  L6_2 = L6_2.rad
  L7_2 = L3_2.rot
  if not L7_2 then
    L7_2 = 0
  end
  L6_2 = L6_2(L7_2)
  L7_2 = math
  L7_2 = L7_2.cos
  L8_2 = L6_2
  L7_2 = L7_2(L8_2)
  L8_2 = math
  L8_2 = L8_2.sin
  L9_2 = L6_2
  L8_2 = L8_2(L9_2)
  L9_2 = L4_2 * L7_2
  L10_2 = L5_2 * L8_2
  L9_2 = L9_2 + L10_2
  L10_2 = -L4_2
  L10_2 = L10_2 * L8_2
  L11_2 = L5_2 * L7_2
  L10_2 = L10_2 + L11_2
  L11_2 = math
  L11_2 = L11_2.abs
  L12_2 = L9_2
  L11_2 = L11_2(L12_2)
  L12_2 = L3_2.w
  L12_2 = L12_2 * 0.5
  L11_2 = L11_2 <= L12_2
  return L11_2
end
L19_1 = CreateThread
function L20_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  while true do
    L0_2 = Wait
    L1_2 = Config
    L1_2 = L1_2.zones
    L1_2 = L1_2.checkMs
    if not L1_2 then
      L1_2 = 500
    end
    L0_2(L1_2)
    L0_2 = L6_1
    if L0_2 then
      L0_2 = L5_1
      if not L0_2 then
        L0_2 = Config
        L0_2 = L0_2.zones
        L0_2 = L0_2.events
        if true == L0_2 then
          L0_2 = GetEntityCoords
          L1_2 = PlayerPedId
          L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L1_2()
          L0_2 = L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
          function L1_2(A0_3, A1_3)
            local L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
            L2_3 = A1_3.zone
            if nil ~= L2_3 then
              L3_3 = L2_3.mode
              if "none" ~= L3_3 then
                L3_3 = L2_3.events
                if true == L3_3 then
                  L3_3 = L18_1
                  L4_3 = A1_3
                  L5_3 = L0_2.x
                  L6_3 = L0_2.y
                  L3_3 = L3_3(L4_3, L5_3, L6_3)
                  L4_3 = L4_1
                  L4_3 = L4_3[A0_3]
                  L4_3 = true == L4_3
                  if L3_3 ~= L4_3 then
                    L5_3 = L4_1
                    L5_3[A0_3] = L3_3
                    L5_3 = TriggerEvent
                    if L3_3 then
                      L6_3 = "apex_blips:client:zoneEnter"
                      if L6_3 then
                        goto lbl_32
                      end
                    end
                    L6_3 = "apex_blips:client:zoneExit"
                    ::lbl_32::
                    L7_3 = A0_3
                    L8_3 = A1_3.name
                    L5_3(L6_3, L7_3, L8_3)
                    L5_3 = L2_1
                    L5_3 = L5_3[A0_3]
                    if nil == L5_3 then
                      L5_3 = TriggerServerEvent
                      L6_3 = "apex_blips:zoneCross"
                      L7_3 = A0_3
                      L8_3 = L3_3
                      L5_3(L6_3, L7_3, L8_3)
                    end
                  end
                end
              end
            end
          end
          L2_2 = 1
          L3_2 = L0_1
          L3_2 = #L3_2
          L4_2 = 1
          for L5_2 = L2_2, L3_2, L4_2 do
            L6_2 = L1_2
            L7_2 = L0_1
            L7_2 = L7_2[L5_2]
            L7_2 = L7_2.id
            L8_2 = L0_1
            L8_2 = L8_2[L5_2]
            L6_2(L7_2, L8_2)
          end
          L2_2 = pairs
          L3_2 = L2_1
          L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
          for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
            L8_2 = L1_2
            L9_2 = L6_2
            L10_2 = L7_2
            L8_2(L9_2, L10_2)
          end
        end
      end
    end
  end
end
L19_1(L20_1)
L19_1 = RegisterCommand
L20_1 = Config
L20_1 = L20_1.commands
L20_1 = L20_1.toggle
function L21_1()
  local L0_2, L1_2, L2_2
  L0_2 = L5_1
  L0_2 = not L0_2
  L5_1 = L0_2
  L0_2 = L15_1
  L0_2()
  L0_2 = Notify
  L1_2 = L
  L2_2 = L5_1
  if L2_2 then
    L2_2 = "n_toggle_off"
    if L2_2 then
      goto lbl_15
    end
  end
  L2_2 = "n_toggle_on"
  ::lbl_15::
  L1_2, L2_2 = L1_2(L2_2)
  L0_2(L1_2, L2_2)
end
L22_1 = false
L19_1(L20_1, L21_1, L22_1)
L19_1 = exports
L20_1 = "AddLocalBlip"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = type
    L2_2 = A0_2.pos
    L1_2 = L1_2(L2_2)
    if "table" == L1_2 then
      goto lbl_13
    end
  end
  L1_2 = nil
  do return L1_2 end
  ::lbl_13::
  L1_2 = L7_1
  L1_2 = L1_2 + 1
  L7_1 = L1_2
  L1_2 = "local_%04d"
  L2_2 = L1_2
  L1_2 = L1_2.format
  L3_2 = L7_1
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = {}
  L2_2.id = L1_2
  L3_2 = type
  L4_2 = A0_2.name
  L3_2 = L3_2(L4_2)
  if "string" == L3_2 then
    L3_2 = A0_2.name
    if L3_2 then
      goto lbl_33
    end
  end
  L3_2 = "Blip"
  ::lbl_33::
  L2_2.name = L3_2
  L3_2 = type
  L4_2 = A0_2.icon
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.icon
    if L3_2 then
      goto lbl_49
    end
  end
  L3_2 = {}
  L3_2.mode = "sprite"
  L4_2 = Config
  L4_2 = L4_2.defaults
  L4_2 = L4_2.sprite
  L3_2.sprite = L4_2
  ::lbl_49::
  L2_2.icon = L3_2
  L3_2 = {}
  L4_2 = tonumber
  L5_2 = A0_2.pos
  L5_2 = L5_2.x
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 0.0
  end
  L3_2.x = L4_2
  L4_2 = tonumber
  L5_2 = A0_2.pos
  L5_2 = L5_2.y
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 0.0
  end
  L3_2.y = L4_2
  L4_2 = tonumber
  L5_2 = A0_2.pos
  L5_2 = L5_2.z
  L4_2 = L4_2(L5_2)
  if not L4_2 then
    L4_2 = 30.0
  end
  L3_2.z = L4_2
  L2_2.pos = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.colour
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 0
  end
  L2_2.colour = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.scale
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = Config
    L3_2 = L3_2.defaults
    L3_2 = L3_2.scale
  end
  L2_2.scale = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.alpha
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 255
  end
  L2_2.alpha = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.category
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 1
  end
  L2_2.category = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.display
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 2
  end
  L2_2.display = L3_2
  L3_2 = A0_2.shortRange
  L3_2 = false ~= L3_2
  L2_2.shortRange = L3_2
  L3_2 = A0_2.flash
  L3_2 = true == L3_2
  L2_2.flash = L3_2
  L3_2 = A0_2.route
  L3_2 = true == L3_2
  L2_2.route = L3_2
  L3_2 = tonumber
  L4_2 = A0_2.routeColour
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = 0
  end
  L2_2.routeColour = L3_2
  L3_2 = type
  L4_2 = A0_2.zone
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L3_2 = A0_2.zone
    if L3_2 then
      goto lbl_150
    end
  end
  L3_2 = {}
  L3_2.mode = "none"
  ::lbl_150::
  L2_2.zone = L3_2
  L3_2 = {}
  L3_2.mode = "everyone"
  L4_2 = {}
  L3_2.jobs = L4_2
  L2_2.vis = L3_2
  L3_2 = L2_1
  L3_2[L1_2] = L2_2
  L3_2 = L15_1
  L3_2()
  return L1_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "RemoveLocalBlip"
function L21_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = L2_1
    L1_2 = L1_2[A0_2]
    if nil ~= L1_2 then
      goto lbl_12
    end
  end
  L1_2 = false
  do return L1_2 end
  ::lbl_12::
  L1_2 = L2_1
  L1_2[A0_2] = nil
  L1_2 = L4_1
  L1_2[A0_2] = nil
  L1_2 = L15_1
  L1_2()
  L1_2 = true
  return L1_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "GetBlipHandle"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L3_1
  L1_2 = L1_2[A0_2]
  if nil ~= L1_2 then
    L2_2 = L1_2.blip
    if nil ~= L2_2 then
      L2_2 = DoesBlipExist
      L3_2 = L1_2.blip
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = L1_2.blip
        return L2_2
      end
    end
  end
  L2_2 = nil
  return L2_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "GetZoneHandle"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L3_1
  L1_2 = L1_2[A0_2]
  if nil ~= L1_2 then
    L2_2 = L1_2.zone
    if nil ~= L2_2 then
      L2_2 = DoesBlipExist
      L3_2 = L1_2.zone
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = L1_2.zone
        return L2_2
      end
    end
  end
  L2_2 = nil
  return L2_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "IsInZone"
function L21_1(A0_2)
  local L1_2
  L1_2 = L4_1
  L1_2 = L1_2[A0_2]
  L1_2 = true == L1_2
  return L1_2
end
L19_1(L20_1, L21_1)
L19_1 = exports
L20_1 = "Refresh"
function L21_1()
  local L0_2, L1_2
  L0_2 = L15_1
  L0_2()
end
L19_1(L20_1, L21_1)
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = L3_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L6_2.blip
    if nil ~= L7_2 then
      L7_2 = L6_2.blip
      L0_2[L7_2] = true
    end
    L7_2 = L6_2.zone
    if nil ~= L7_2 then
      L7_2 = L6_2.zone
      L0_2[L7_2] = true
    end
  end
  return L0_2
end
GetRenderedBlipHandles = L19_1
L19_1 = AddEventHandler
L20_1 = "onResourceStop"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = pairs
  L2_2 = L3_1
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2 in L1_2, L2_2, L3_2, L4_2 do
    L6_2 = L12_1
    L7_2 = L5_2
    L6_2(L7_2)
  end
end
L19_1(L20_1, L21_1)
