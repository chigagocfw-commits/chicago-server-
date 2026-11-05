local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1, L25_1, L26_1, L27_1, L28_1, L29_1, L30_1, L31_1, L32_1
L0_1 = Shared
if L0_1 then
  L0_1 = Shared
  L0_1 = L0_1.UI
  if L0_1 then
    L0_1 = Shared
    L0_1 = L0_1.UI
    L0_1 = L0_1.DuiHandler
    if L0_1 then
      goto lbl_16
    end
  end
end
L0_1 = {}
::lbl_16::
L1_1 = L0_1.maxDistance
if not L1_1 then
  L1_1 = 50.0
end
L2_1 = L0_1.fadeDistance
if not L2_1 then
  L2_1 = 30.0
end
L3_1 = L0_1.maxTexts
if not L3_1 then
  L3_1 = 2
end
L4_1 = L0_1.verticalOffset
if not L4_1 then
  L4_1 = 0.32
end
L5_1 = 31086
L6_1 = AddEventHandler
L7_1 = "apex_chat:prefs:changed"
function L8_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = tonumber
  L2_2 = A0_2.bubbleMaxDistance
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = tonumber
    L2_2 = A0_2.bubbleMaxDistance
    L1_2 = L1_2(L2_2)
    L1_1 = L1_2
    L1_2 = math
    L1_2 = L1_2.max
    L2_2 = 5.0
    L3_2 = L1_1
    L3_2 = L3_2 * 0.6
    L1_2 = L1_2(L2_2, L3_2)
    L2_1 = L1_2
  end
end
L6_1(L7_1, L8_1)
L6_1 = {}
function L7_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = "b%d_%d"
  L1_2 = L0_2
  L0_2 = L0_2.format
  L2_2 = GetGameTimer
  L2_2 = L2_2()
  L3_2 = math
  L3_2 = L3_2.random
  L4_2 = 1
  L5_2 = 1000000.0
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  return L0_2(L1_2, L2_2, L3_2, L4_2, L5_2)
end
function L8_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetPlayerFromServerId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if -1 == L1_2 then
    L2_2 = 0
    return L2_2
  end
  L2_2 = GetPlayerPed
  L3_2 = L1_2
  return L2_2(L3_2)
end
function L9_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L4_2 = 0
  L5_2 = nil
  L6_2 = nil
  L7_2 = pairs
  L8_2 = L6_1
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
    L13_2 = L12_2.source
    if L13_2 == A0_2 then
      L4_2 = L4_2 + 1
      if L6_2 then
        L13_2 = L12_2.expires
        if not (L6_2 > L13_2) then
          goto lbl_19
        end
      end
      L6_2 = L12_2.expires
      L5_2 = L11_2
    end
    ::lbl_19::
  end
  L7_2 = L3_1
  if L4_2 >= L7_2 and L5_2 then
    L7_2 = L6_1
    L7_2[L5_2] = nil
    L7_2 = SendNUIMessage
    L8_2 = {}
    L8_2.action = "apex_bubble_remove"
    L8_2.id = L5_2
    L7_2(L8_2)
  end
  L7_2 = L7_1
  L7_2 = L7_2()
  L8_2 = L6_1
  L9_2 = {}
  L9_2.source = A0_2
  L10_2 = A1_2 or L10_2
  if not A1_2 then
    L10_2 = ""
  end
  L9_2.message = L10_2
  L10_2 = A2_2 or L10_2
  if not A2_2 then
    L10_2 = "me"
  end
  L9_2.type = L10_2
  L10_2 = GetGameTimer
  L10_2 = L10_2()
  L11_2 = A3_2 or L11_2
  if not A3_2 then
    L11_2 = L0_1.duration
    if not L11_2 then
      L11_2 = 5000
    end
  end
  L10_2 = L10_2 + L11_2
  L9_2.expires = L10_2
  L8_2[L7_2] = L9_2
  L8_2 = SendNUIMessage
  L9_2 = {}
  L9_2.action = "apex_bubble_add"
  L9_2.id = L7_2
  L10_2 = L6_1
  L10_2 = L10_2[L7_2]
  L10_2 = L10_2.message
  L9_2.text = L10_2
  L10_2 = L6_1
  L10_2 = L10_2[L7_2]
  L10_2 = L10_2.type
  L9_2.type = L10_2
  L8_2(L9_2)
end
L10_1 = RegisterNetEvent
L11_1 = "apex_chat:headBubble"
function L12_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = L0_1.enabled
  if not L1_2 then
    return
  end
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.source
    if L1_2 then
      goto lbl_14
    end
  end
  do return end
  ::lbl_14::
  L1_2 = L9_1
  L2_2 = A0_2.source
  L3_2 = A0_2.message
  if not L3_2 then
    L3_2 = ""
  end
  L4_2 = A0_2.type
  if not L4_2 then
    L4_2 = "me"
  end
  L5_2 = A0_2.ms
  if not L5_2 then
    L5_2 = L0_1.duration
  end
  L1_2(L2_2, L3_2, L4_2, L5_2)
end
L10_1(L11_1, L12_1)
L10_1 = CreateThread
function L11_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2, L21_2, L22_2, L23_2, L24_2, L25_2, L26_2, L27_2, L28_2, L29_2, L30_2
  while true do
    L0_2 = L0_1.enabled
    if L0_2 then
      L0_2 = next
      L1_2 = L6_1
      L0_2 = L0_2(L1_2)
      if L0_2 then
        goto lbl_13
      end
    end
    L0_2 = Wait
    L1_2 = 150
    L0_2(L1_2)
    goto lbl_234
    ::lbl_13::
    L0_2 = GetGameTimer
    L0_2 = L0_2()
    L1_2 = PlayerPedId
    L1_2 = L1_2()
    if 0 ~= L1_2 then
      L2_2 = GetEntityCoords
      L3_2 = L1_2
      L2_2 = L2_2(L3_2)
      if L2_2 then
        goto lbl_29
      end
    end
    L2_2 = vector3
    L3_2 = 0
    L4_2 = 0
    L5_2 = 0
    L2_2 = L2_2(L3_2, L4_2, L5_2)
    ::lbl_29::
    L3_2 = {}
    L4_2 = pairs
    L5_2 = L6_1
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = L9_2.expires
      if L0_2 >= L10_2 then
        L10_2 = L6_1
        L10_2[L8_2] = nil
        L10_2 = SendNUIMessage
        L11_2 = {}
        L11_2.action = "apex_bubble_remove"
        L11_2.id = L8_2
        L10_2(L11_2)
      else
        L10_2 = L9_2.ped
        if L10_2 then
          L10_2 = DoesEntityExist
          L11_2 = L9_2.ped
          L10_2 = L10_2(L11_2)
          if L10_2 then
            L10_2 = L9_2.ped
            if L10_2 then
              goto lbl_61
            end
          end
        end
        L10_2 = L8_1
        L11_2 = L9_2.source
        L10_2 = L10_2(L11_2)
        ::lbl_61::
        if 0 ~= L10_2 and L10_2 then
          L11_2 = DoesEntityExist
          L12_2 = L10_2
          L11_2 = L11_2(L12_2)
          if L11_2 then
            goto lbl_77
          end
        end
        L11_2 = SendNUIMessage
        L12_2 = {}
        L12_2.action = "apex_bubble_hide"
        L12_2.id = L8_2
        L11_2(L12_2)
        goto lbl_93
        ::lbl_77::
        L11_2 = L3_2[L10_2]
        if not L11_2 then
          L11_2 = {}
        end
        L3_2[L10_2] = L11_2
        L11_2 = L3_2[L10_2]
        L12_2 = L3_2[L10_2]
        L12_2 = #L12_2
        L12_2 = L12_2 + 1
        L13_2 = {}
        L13_2.id = L8_2
        L13_2.b = L9_2
        L11_2[L12_2] = L13_2
      end
      ::lbl_93::
    end
    L4_2 = pairs
    L5_2 = L3_2
    L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
    for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
      L10_2 = table
      L10_2 = L10_2.sort
      L11_2 = L9_2
      function L12_2(A0_3, A1_3)
        local L2_3, L3_3
        L2_3 = A0_3.b
        L2_3 = L2_3.expires
        L3_3 = A1_3.b
        L3_3 = L3_3.expires
        L2_3 = L2_3 < L3_3
        return L2_3
      end
      L10_2(L11_2, L12_2)
      L10_2 = GetEntityCoords
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      L11_2 = GetPedBoneCoords
      L12_2 = L8_2
      L13_2 = L5_1
      L14_2 = 0.0
      L15_2 = 0.0
      L16_2 = 0.0
      L11_2 = L11_2(L12_2, L13_2, L14_2, L15_2, L16_2)
      L12_2 = L10_2 - L2_2
      L12_2 = #L12_2
      L13_2 = L1_1
      if L12_2 > L13_2 then
        L13_2 = ipairs
        L14_2 = L9_2
        L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
        for L17_2, L18_2 in L13_2, L14_2, L15_2, L16_2 do
          L19_2 = SendNUIMessage
          L20_2 = {}
          L20_2.action = "apex_bubble_hide"
          L21_2 = L18_2.id
          L20_2.id = L21_2
          L19_2(L20_2)
        end
      else
        L13_2 = ipairs
        L14_2 = L9_2
        L13_2, L14_2, L15_2, L16_2 = L13_2(L14_2)
        for L17_2, L18_2 in L13_2, L14_2, L15_2, L16_2 do
          L19_2 = L4_1
          L20_2 = L17_2 - 1
          L20_2 = L20_2 * 0.22
          L19_2 = L19_2 + L20_2
          L20_2 = World3dToScreen2d
          L21_2 = L11_2.x
          L22_2 = L11_2.y
          L23_2 = L11_2.z
          L23_2 = L23_2 + L19_2
          L20_2, L21_2, L22_2 = L20_2(L21_2, L22_2, L23_2)
          if L20_2 then
            L23_2 = HasEntityClearLosToEntity
            L24_2 = L1_2
            L25_2 = L8_2
            L26_2 = 17
            L23_2 = L23_2(L24_2, L25_2, L26_2)
            if L23_2 then
              L23_2 = L2_1
              if L12_2 <= L23_2 then
                L23_2 = 1.0
                if L23_2 then
                  goto lbl_185
                end
              end
              L23_2 = math
              L23_2 = L23_2.max
              L24_2 = 0.0
              L25_2 = L2_1
              L25_2 = L12_2 - L25_2
              L26_2 = L1_1
              L27_2 = L2_1
              L26_2 = L26_2 - L27_2
              L25_2 = L25_2 / L26_2
              L26_2 = 1.0
              L25_2 = L26_2 - L25_2
              L23_2 = L23_2(L24_2, L25_2)
              ::lbl_185::
              L24_2 = math
              L24_2 = L24_2.max
              L25_2 = 0.55
              L26_2 = math
              L26_2 = L26_2.min
              L27_2 = 1.0
              L28_2 = math
              L28_2 = L28_2.max
              L29_2 = L12_2
              L30_2 = 0.5
              L28_2 = L28_2(L29_2, L30_2)
              L29_2 = 6.0
              L28_2 = L29_2 / L28_2
              L26_2, L27_2, L28_2, L29_2, L30_2 = L26_2(L27_2, L28_2)
              L24_2 = L24_2(L25_2, L26_2, L27_2, L28_2, L29_2, L30_2)
              L25_2 = SendNUIMessage
              L26_2 = {}
              L26_2.action = "apex_bubble_show"
              L27_2 = L18_2.id
              L26_2.id = L27_2
              L26_2.x = L21_2
              L26_2.y = L22_2
              L26_2.scale = L24_2
              L26_2.opacity = L23_2
              L27_2 = L18_2.b
              L27_2 = L27_2.expires
              L27_2 = L27_2 - L0_2
              L26_2.ttlMs = L27_2
              L25_2(L26_2)
          end
          else
            L23_2 = SendNUIMessage
            L24_2 = {}
            L24_2.action = "apex_bubble_hide"
            L25_2 = L18_2.id
            L24_2.id = L25_2
            L23_2(L24_2)
          end
        end
      end
    end
    L4_2 = Wait
    L5_2 = 0
    L4_2(L5_2)
    ::lbl_234::
  end
end
L10_1(L11_1)
L10_1 = {}
L11_1 = "looks around"
L12_1 = "checks phone"
L13_1 = "lights a cigarette"
L14_1 = "adjusts jacket"
L15_1 = "nods slowly"
L16_1 = "scratches head"
L17_1 = "cracks knuckles"
L18_1 = "sips coffee"
L19_1 = "checks watch"
L20_1 = "ties a shoelace"
L21_1 = "waves"
L22_1 = "points ahead"
L23_1 = "sighs"
L24_1 = "glances back"
L25_1 = "stretches"
L26_1 = "coughs"
L27_1 = "looks nervous"
L28_1 = "grins"
L29_1 = "rubs hands"
L30_1 = "shrugs"
L31_1 = "leans on the wall"
L32_1 = "looks at his phone"
L10_1[1] = L11_1
L10_1[2] = L12_1
L10_1[3] = L13_1
L10_1[4] = L14_1
L10_1[5] = L15_1
L10_1[6] = L16_1
L10_1[7] = L17_1
L10_1[8] = L18_1
L10_1[9] = L19_1
L10_1[10] = L20_1
L10_1[11] = L21_1
L10_1[12] = L22_1
L10_1[13] = L23_1
L10_1[14] = L24_1
L10_1[15] = L25_1
L10_1[16] = L26_1
L10_1[17] = L27_1
L10_1[18] = L28_1
L10_1[19] = L29_1
L10_1[20] = L30_1
L10_1[21] = L31_1
L10_1[22] = L32_1
function L11_1()
  local L0_2, L1_2, L2_2
  L0_2 = math
  L0_2 = L0_2.random
  L1_2 = 1
  L2_2 = L10_1
  L2_2 = #L2_2
  L0_2 = L0_2(L1_2, L2_2)
  L1_2 = L10_1
  L0_2 = L1_2[L0_2]
  return L0_2
end
function L12_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  if A0_2 and 0 ~= A0_2 then
    L2_2 = DoesEntityExist
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if L2_2 then
      goto lbl_11
    end
  end
  do return end
  ::lbl_11::
  L2_2 = pairs
  L3_2 = L6_1
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.ped
    if L8_2 == A0_2 then
      L8_2 = L6_1
      L8_2[L6_2] = nil
      L8_2 = SendNUIMessage
      L9_2 = {}
      L9_2.action = "apex_bubble_remove"
      L9_2.id = L6_2
      L8_2(L9_2)
    end
  end
  L2_2 = L7_1
  L2_2 = L2_2()
  L3_2 = L6_1
  L4_2 = {}
  L4_2.ped = A0_2
  L5_2 = A1_2 or L5_2
  if not A1_2 then
    L5_2 = ""
  end
  L4_2.message = L5_2
  L4_2.type = "me"
  L5_2 = GetGameTimer
  L5_2 = L5_2()
  L6_2 = L0_1.duration
  if not L6_2 then
    L6_2 = 5000
  end
  L5_2 = L5_2 + L6_2
  L4_2.expires = L5_2
  L3_2[L2_2] = L4_2
  L3_2 = SendNUIMessage
  L4_2 = {}
  L4_2.action = "apex_bubble_add"
  L4_2.id = L2_2
  L5_2 = L6_1
  L5_2 = L5_2[L2_2]
  L5_2 = L5_2.message
  L4_2.text = L5_2
  L4_2.type = "me"
  L3_2(L4_2)
end
function L13_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L3_2 = {}
  L4_2 = PlayerPedId
  L4_2 = L4_2()
  L5_2 = ipairs
  L6_2 = GetGamePool
  L7_2 = "CPed"
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L6_2(L7_2)
  L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
  for L9_2, L10_2 in L5_2, L6_2, L7_2, L8_2 do
    if L10_2 ~= L4_2 then
      L11_2 = DoesEntityExist
      L12_2 = L10_2
      L11_2 = L11_2(L12_2)
      if L11_2 then
        L11_2 = IsPedAPlayer
        L12_2 = L10_2
        L11_2 = L11_2(L12_2)
        if not L11_2 then
          L11_2 = IsEntityDead
          L12_2 = L10_2
          L11_2 = L11_2(L12_2)
          if not L11_2 then
            L11_2 = GetEntityCoords
            L12_2 = L10_2
            L11_2 = L11_2(L12_2)
            L11_2 = A0_2 - L11_2
            L11_2 = #L11_2
            if A2_2 >= L11_2 then
              L12_2 = #L3_2
              L12_2 = L12_2 + 1
              L13_2 = {}
              L13_2.ped = L10_2
              L13_2.dist = L11_2
              L3_2[L12_2] = L13_2
            end
          end
        end
      end
    end
  end
  L5_2 = table
  L5_2 = L5_2.sort
  L6_2 = L3_2
  function L7_2(A0_3, A1_3)
    local L2_3, L3_3
    L2_3 = A0_3.dist
    L3_3 = A1_3.dist
    L2_3 = L2_3 < L3_3
    return L2_3
  end
  L5_2(L6_2, L7_2)
  L5_2 = {}
  L6_2 = 1
  L7_2 = math
  L7_2 = L7_2.min
  L8_2 = A1_2
  L9_2 = #L3_2
  L7_2 = L7_2(L8_2, L9_2)
  L8_2 = 1
  for L9_2 = L6_2, L7_2, L8_2 do
    L10_2 = L3_2[L9_2]
    L10_2 = L10_2.ped
    L5_2[L9_2] = L10_2
  end
  return L5_2
end
L14_1 = Shared
if L14_1 then
  L14_1 = Shared
  L14_1 = L14_1.debug
  if L14_1 then
    L14_1 = RegisterCommand
    L15_1 = "apexchat_metest"
    function L16_1()
      local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
      L0_2 = L0_1.enabled
      if not L0_2 then
        return
      end
      L0_2 = PlayerPedId
      L0_2 = L0_2()
      if 0 == L0_2 then
        return
      end
      L1_2 = GetEntityCoords
      L2_2 = L0_2
      L1_2 = L1_2(L2_2)
      L2_2 = L12_1
      L3_2 = L0_2
      L4_2 = L11_1
      L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L4_2()
      L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
      L2_2 = ipairs
      L3_2 = L13_1
      L4_2 = L1_2
      L5_2 = 5
      L6_2 = 25.0
      L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2 = L3_2(L4_2, L5_2, L6_2)
      L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
      for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
        L8_2 = L12_1
        L9_2 = L7_2
        L10_2 = L11_1
        L10_2 = L10_2()
        L8_2(L9_2, L10_2)
      end
    end
    L17_1 = false
    L14_1(L15_1, L16_1, L17_1)
    L14_1 = RegisterKeyMapping
    L15_1 = "apexchat_metest"
    L16_1 = "Chat: /me bubbles over nearby NPCs + self"
    L17_1 = "keyboard"
    L18_1 = "B"
    L14_1(L15_1, L16_1, L17_1, L18_1)
  end
end
L14_1 = AddEventHandler
L15_1 = "onResourceStop"
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = pairs
    L2_2 = L6_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2 in L1_2, L2_2, L3_2, L4_2 do
      L6_2 = SendNUIMessage
      L7_2 = {}
      L7_2.action = "apex_bubble_remove"
      L7_2.id = L5_2
      L6_2(L7_2)
    end
    L1_2 = {}
    L6_1 = L1_2
  end
end
L14_1(L15_1, L16_1)
