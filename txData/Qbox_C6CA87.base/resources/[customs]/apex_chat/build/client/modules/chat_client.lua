local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1
L0_1 = false
L1_1 = false
L2_1 = false
L3_1 = nil
L4_1 = nil
L5_1 = {}
L6_1 = {}
function L7_1()
  local L0_2, L1_2
  L0_2 = L3_1
  if not L0_2 then
    L0_2 = GetPlayerServerId
    L1_2 = PlayerId
    L1_2 = L1_2()
    L0_2 = L0_2(L1_2)
    L3_1 = L0_2
  end
  L0_2 = L3_1
  return L0_2
end
function L8_1()
  local L0_2, L1_2
  L0_2 = Config
  L0_2 = L0_2.Avatars
  if not L0_2 then
    L0_2 = {}
  end
  return L0_2
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = L5_1
  L1_2 = L1_2[A0_2]
  if L1_2 then
    L2_2 = L1_2.handle
    if L2_2 then
      L2_2 = pcall
      L3_2 = UnregisterPedheadshot
      L4_2 = L1_2.handle
      L2_2(L3_2, L4_2)
    end
  end
  L2_2 = L5_1
  L2_2[A0_2] = nil
  L2_2 = L6_1
  L2_2 = #L2_2
  L3_2 = 1
  L4_2 = -1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = L6_1
    L6_2 = L6_2[L5_2]
    if L6_2 == A0_2 then
      L6_2 = table
      L6_2 = L6_2.remove
      L7_2 = L6_1
      L8_2 = L5_2
      L6_2(L7_2, L8_2)
    end
  end
end
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = L6_1
  L1_2 = #L1_2
  L2_2 = 1
  L3_2 = -1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L6_1
    L5_2 = L5_2[L4_2]
    if L5_2 == A0_2 then
      L5_2 = table
      L5_2 = L5_2.remove
      L6_2 = L6_1
      L7_2 = L4_2
      L5_2(L6_2, L7_2)
    end
  end
  L1_2 = L6_1
  L1_2 = #L1_2
  L2_2 = L1_2 + 1
  L1_2 = L6_1
  L1_2[L2_2] = A0_2
  L1_2 = L8_1
  L1_2 = L1_2()
  L1_2 = L1_2.maxCached
  if not L1_2 then
    L1_2 = 16
  end
  while true do
    L2_2 = L6_1
    L2_2 = #L2_2
    if not (L1_2 < L2_2) then
      break
    end
    L2_2 = L9_1
    L3_2 = L6_1
    L3_2 = L3_2[1]
    L2_2(L3_2)
  end
end
function L11_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L7_1
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = PlayerPedId
    return L1_2()
  end
  L1_2 = GetPlayerFromServerId
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if -1 == L1_2 then
    L2_2 = 0
    return L2_2
  end
  L2_2 = GetPlayerPed
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = 0
  end
  return L2_2
end
function L12_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L1_2 = L8_1
  L1_2 = L1_2()
  L2_2 = L1_2.enabled
  if L2_2 then
    L2_2 = L1_2.mode
    if "mugshot" == L2_2 then
      goto lbl_11
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_11::
  L2_2 = L5_1
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L3_2 = L2_2.handle
    if L3_2 then
      L3_2 = IsPedheadshotValid
      L4_2 = L2_2.handle
      L3_2 = L3_2(L4_2)
      if L3_2 then
        L3_2 = L10_1
        L4_2 = A0_2
        L3_2(L4_2)
        L3_2 = L2_2.url
        return L3_2
      end
    end
  end
  L3_2 = L11_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if L3_2 and 0 ~= L3_2 then
    L4_2 = DoesEntityExist
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_42
    end
  end
  L4_2 = nil
  do return L4_2 end
  ::lbl_42::
  if L2_2 then
    L4_2 = L9_1
    L5_2 = A0_2
    L4_2(L5_2)
  end
  L4_2 = nil
  L5_2 = L1_2.transparent
  if L5_2 then
    L5_2 = RegisterPedheadshotTransparent
    if L5_2 then
      L5_2 = RegisterPedheadshotTransparent
      L6_2 = L3_2
      L5_2 = L5_2(L6_2)
      L4_2 = L5_2
  end
  else
    L5_2 = RegisterPedheadshot
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    L4_2 = L5_2
  end
  if not L4_2 or 0 == L4_2 then
    L5_2 = nil
    return L5_2
  end
  L5_2 = GetGameTimer
  L5_2 = L5_2()
  L6_2 = L1_2.timeoutMs
  if not L6_2 then
    L6_2 = 1500
  end
  L5_2 = L5_2 + L6_2
  while true do
    L6_2 = IsPedheadshotReady
    L7_2 = L4_2
    L6_2 = L6_2(L7_2)
    if L6_2 then
      L6_2 = IsPedheadshotValid
      L7_2 = L4_2
      L6_2 = L6_2(L7_2)
      if L6_2 then
        break
      end
    end
    L6_2 = GetGameTimer
    L6_2 = L6_2()
    if L5_2 < L6_2 then
      L6_2 = pcall
      L7_2 = UnregisterPedheadshot
      L8_2 = L4_2
      L6_2(L7_2, L8_2)
      L6_2 = nil
      return L6_2
    end
    L6_2 = Wait
    L7_2 = 0
    L6_2(L7_2)
  end
  L6_2 = GetPedheadshotTxdString
  L7_2 = L4_2
  L6_2 = L6_2(L7_2)
  if not L6_2 or "" == L6_2 then
    L7_2 = pcall
    L8_2 = UnregisterPedheadshot
    L9_2 = L4_2
    L7_2(L8_2, L9_2)
    L7_2 = nil
    return L7_2
  end
  L7_2 = "https://nui-img/%s/%s"
  L8_2 = L7_2
  L7_2 = L7_2.format
  L9_2 = L6_2
  L10_2 = L6_2
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = L5_1
  L9_2 = {}
  L9_2.handle = L4_2
  L9_2.txd = L6_2
  L9_2.url = L7_2
  L8_2[A0_2] = L9_2
  L8_2 = L10_1
  L9_2 = A0_2
  L8_2(L9_2)
  return L7_2
end
function L13_1()
  local L0_2, L1_2
  L0_2 = Config
  L0_2 = L0_2.ScreenPhoto
  if not L0_2 then
    L0_2 = {}
  end
  return L0_2
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L4_1 = A0_2
  L1_2 = L13_1
  L1_2 = L1_2()
  L2_2 = L1_2.saveClientKvp
  if false ~= L2_2 then
    L2_2 = pcall
    L3_2 = SetResourceKvp
    L4_2 = L1_2.kvpKey
    if not L4_2 then
      L4_2 = "apex_chat:last_screen_photo_base64"
    end
    L5_2 = A0_2
    L2_2(L3_2, L4_2, L5_2)
  end
end
function L15_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if not A0_2 then
    function L2_2()
      local L0_3, L1_3
    end
    A0_2 = L2_2
  end
  L2_2 = GetResourceState
  L3_2 = "screenshot-basic"
  L2_2 = L2_2(L3_2)
  if "started" ~= L2_2 then
    L2_2 = A0_2
    L3_2 = false
    L4_2 = nil
    L5_2 = "screenshot-basic is not started"
    L2_2(L3_2, L4_2, L5_2)
    return
  end
  L2_2 = L13_1
  L2_2 = L2_2()
  L3_2 = "chat" == A1_2
  L4_2 = exports
  L4_2 = L4_2["screenshot-basic"]
  L5_2 = L4_2
  L4_2 = L4_2.requestScreenshot
  L6_2 = {}
  if L3_2 then
    L7_2 = L2_2.chatEncoding
    if L7_2 then
      goto lbl_36
    end
  end
  L7_2 = L2_2.encoding
  if not L7_2 then
    L7_2 = "jpg"
  end
  ::lbl_36::
  L6_2.encoding = L7_2
  if L3_2 then
    L7_2 = L2_2.chatQuality
    if L7_2 then
      goto lbl_46
    end
  end
  L7_2 = L2_2.quality
  if not L7_2 then
    L7_2 = 0.86
  end
  ::lbl_46::
  L6_2.quality = L7_2
  function L7_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    L1_3 = type
    L2_3 = A0_3
    L1_3 = L1_3(L2_3)
    if "string" ~= L1_3 or "" == A0_3 then
      L1_3 = A0_2
      L2_3 = false
      L3_3 = nil
      L4_3 = "empty screenshot result"
      L1_3(L2_3, L3_3, L4_3)
      return
    end
    L1_3 = L3_2
    if L1_3 then
      L1_3 = L2_2.chatMaxBase64Length
      if L1_3 then
        goto lbl_24
      end
    end
    L1_3 = L2_2.maxBase64Length
    if not L1_3 then
      L1_3 = 6000000
    end
    ::lbl_24::
    L2_3 = #A0_3
    if L1_3 < L2_3 then
      L2_3 = A0_2
      L3_3 = false
      L4_3 = nil
      L5_3 = "screenshot is too large (%d > %d)"
      L6_3 = L5_3
      L5_3 = L5_3.format
      L7_3 = #A0_3
      L8_3 = L1_3
      L5_3, L6_3, L7_3, L8_3 = L5_3(L6_3, L7_3, L8_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3, L8_3)
      return
    end
    L2_3 = L14_1
    L3_3 = A0_3
    L2_3(L3_3)
    L2_3 = A0_2
    L3_3 = true
    L4_3 = A0_3
    L2_3(L3_3, L4_3)
  end
  L4_2(L5_2, L6_2, L7_2)
end
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L1_1
  if L1_2 then
    L1_2 = A0_2
    L2_2 = false
    L3_2 = nil
    L4_2 = "framing already active"
    L1_2(L2_2, L3_2, L4_2)
    return
  end
  L1_2 = L13_1
  L1_2 = L1_2()
  L2_2 = true
  L1_1 = L2_2
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = GetGameTimer
    L0_3 = L0_3()
    L1_3 = L1_2.framingTimeoutMs
    if not L1_3 then
      L1_3 = 60000
    end
    L0_3 = L0_3 + L1_3
    L1_3 = false
    L2_3 = false
    L3_3 = SendNUIMessage
    L4_3 = {}
    L4_3.action = "apex_photo_frame"
    L4_3.show = true
    L3_3(L4_3)
    function L3_3(A0_4, A1_4, A2_4)
      local L3_4, L4_4, L5_4, L6_4
      L3_4 = L2_3
      if L3_4 then
        return
      end
      L3_4 = true
      L2_3 = L3_4
      L3_4 = SendNUIMessage
      L4_4 = {}
      L4_4.action = "apex_photo_frame"
      L4_4.show = false
      L3_4(L4_4)
      L3_4 = A0_2
      L4_4 = A0_4
      L5_4 = A1_4
      L6_4 = A2_4
      L3_4(L4_4, L5_4, L6_4)
    end
    while not L2_3 do
      L4_3 = Wait
      L5_3 = 0
      L4_3(L5_3)
      L4_3 = HideHudAndRadarThisFrame
      L4_3()
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 24
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 25
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 37
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 140
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 141
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 142
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 257
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 263
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 176
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 177
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 199
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      L4_3 = DisableControlAction
      L5_3 = 0
      L6_3 = 200
      L7_3 = true
      L4_3(L5_3, L6_3, L7_3)
      if not L1_3 then
        L4_3 = GetGameTimer
        L4_3 = L4_3()
        if not (L0_3 < L4_3) then
          L4_3 = IsDisabledControlJustPressed
          L5_3 = 0
          L6_3 = 177
          L4_3 = L4_3(L5_3, L6_3)
          if not L4_3 then
            L4_3 = IsDisabledControlJustPressed
            L5_3 = 0
            L6_3 = 199
            L4_3 = L4_3(L5_3, L6_3)
            if not L4_3 then
              L4_3 = IsDisabledControlJustPressed
              L5_3 = 0
              L6_3 = 200
              L4_3 = L4_3(L5_3, L6_3)
              if not L4_3 then
                goto lbl_115
              end
            end
          end
        end
        L4_3 = L3_3
        L5_3 = false
        L6_3 = nil
        L7_3 = "cancelled"
        L4_3(L5_3, L6_3, L7_3)
        goto lbl_137
        ::lbl_115::
        L4_3 = IsDisabledControlJustPressed
        L5_3 = 0
        L6_3 = 176
        L4_3 = L4_3(L5_3, L6_3)
        if not L4_3 then
          L4_3 = IsDisabledControlJustPressed
          L5_3 = 0
          L6_3 = 24
          L4_3 = L4_3(L5_3, L6_3)
          if not L4_3 then
            goto lbl_137
          end
        end
        L1_3 = true
        L4_3 = SendNUIMessage
        L5_3 = {}
        L5_3.action = "apex_photo_frame"
        L5_3.show = false
        L4_3(L5_3)
        L4_3 = CreateThread
        function L5_3()
          local L0_4, L1_4, L2_4, L3_4
          L0_4 = Wait
          L1_4 = math
          L1_4 = L1_4.max
          L2_4 = L1_2.chatCaptureDelayMs
          if not L2_4 then
            L2_4 = 180
          end
          L3_4 = 120
          L1_4, L2_4, L3_4 = L1_4(L2_4, L3_4)
          L0_4(L1_4, L2_4, L3_4)
          L0_4 = L15_1
          L1_4 = L3_3
          L2_4 = "chat"
          L0_4(L1_4, L2_4)
        end
        L4_3(L5_3)
      end
      ::lbl_137::
    end
    L4_3 = false
    L1_1 = L4_3
  end
  L2_2(L3_2)
end
function L17_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  if L1_2 then
    return
  end
  L1_2 = true
  L0_1 = L1_2
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_chat_open"
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = ""
  end
  L2_2.prefill = L3_2
  L1_2(L2_2)
end
function L18_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L0_1 = L0_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "apex_chat_close"
  L0_2(L1_2)
end
L19_1 = CreateThread
function L20_1()
  local L0_2, L1_2, L2_2, L3_2
  while true do
    L0_2 = L0_1
    if L0_2 then
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 177
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 199
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 200
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = DisableControlAction
      L1_2 = 0
      L2_2 = 322
      L3_2 = true
      L0_2(L1_2, L2_2, L3_2)
      L0_2 = IsDisabledControlJustPressed
      L1_2 = 0
      L2_2 = 177
      L0_2 = L0_2(L1_2, L2_2)
      if not L0_2 then
        L0_2 = IsDisabledControlJustPressed
        L1_2 = 0
        L2_2 = 199
        L0_2 = L0_2(L1_2, L2_2)
        if not L0_2 then
          L0_2 = IsDisabledControlJustPressed
          L1_2 = 0
          L2_2 = 200
          L0_2 = L0_2(L1_2, L2_2)
          if not L0_2 then
            L0_2 = IsDisabledControlJustPressed
            L1_2 = 0
            L2_2 = 322
            L0_2 = L0_2(L1_2, L2_2)
            if not L0_2 then
              goto lbl_50
            end
          end
        end
      end
      L0_2 = L18_1
      L0_2()
      ::lbl_50::
      L0_2 = Wait
      L1_2 = 0
      L0_2(L1_2)
    else
      L0_2 = Wait
      L1_2 = 250
      L0_2(L1_2)
    end
  end
end
L19_1(L20_1)
L19_1 = RegisterCommand
L20_1 = Config
L20_1 = L20_1.OpenCommand
function L21_1()
  local L0_2, L1_2
  L0_2 = L17_1
  L0_2()
end
L22_1 = false
L19_1(L20_1, L21_1, L22_1)
L19_1 = RegisterKeyMapping
L20_1 = Config
L20_1 = L20_1.OpenCommand
L21_1 = "Open chat"
L22_1 = "keyboard"
L23_1 = Config
L23_1 = L23_1.OpenKey
if not L23_1 then
  L23_1 = "T"
end
L19_1(L20_1, L21_1, L22_1, L23_1)
L19_1 = RegisterCommand
L20_1 = "apexchat_slash"
function L21_1()
  local L0_2, L1_2
  L0_2 = L17_1
  L1_2 = "/"
  L0_2(L1_2)
end
L22_1 = false
L19_1(L20_1, L21_1, L22_1)
L19_1 = RegisterKeyMapping
L20_1 = "apexchat_slash"
L21_1 = "Open chat (command)"
L22_1 = "keyboard"
L23_1 = ""
L19_1(L20_1, L21_1, L22_1, L23_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_chat_send"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tostring
  if A0_2 then
    L3_2 = A0_2.text
    if L3_2 then
      goto lbl_8
    end
  end
  L3_2 = ""
  ::lbl_8::
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "^%s+"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "%s+$"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = tostring
  if A0_2 then
    L4_2 = A0_2.cat
    if L4_2 then
      goto lbl_25
    end
  end
  L4_2 = Config
  L4_2 = L4_2.DefaultCategory
  ::lbl_25::
  L3_2 = L3_2(L4_2)
  L4_2 = tostring
  if A0_2 then
    L5_2 = A0_2.image
    if L5_2 then
      goto lbl_33
    end
  end
  L5_2 = ""
  ::lbl_33::
  L4_2 = L4_2(L5_2)
  L5_2 = L18_1
  L5_2()
  if "" ~= L2_2 or "" ~= L4_2 then
    L6_2 = L2_2
    L5_2 = L2_2.sub
    L7_2 = 1
    L8_2 = 1
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "/" == L5_2 then
      L6_2 = L2_2
      L5_2 = L2_2.sub
      L7_2 = 2
      L5_2 = L5_2(L6_2, L7_2)
      L6_2 = L5_2
      L5_2 = L5_2.match
      L7_2 = "^(%S+)"
      L5_2 = L5_2(L6_2, L7_2)
      if not L5_2 then
        L5_2 = ""
      end
      L6_2 = L5_2
      L5_2 = L5_2.lower
      L5_2 = L5_2(L6_2)
      L6_2 = Config
      L6_2 = L6_2.AllowPlayersToClearTheirChat
      if L6_2 then
        L6_2 = tostring
        L7_2 = Config
        L7_2 = L7_2.ClearChatCommand
        L6_2 = L6_2(L7_2)
        L7_2 = L6_2
        L6_2 = L6_2.lower
        L6_2 = L6_2(L7_2)
        if L5_2 == L6_2 then
          L6_2 = SendNUIMessage
          L7_2 = {}
          L7_2.action = "apex_clear"
          L6_2(L7_2)
        end
      end
      L6_2 = ExecuteCommand
      L8_2 = L2_2
      L7_2 = L2_2.sub
      L9_2 = 2
      L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
      L6_2(L7_2, L8_2, L9_2)
    else
      L5_2 = TriggerServerEvent
      L6_2 = "apex_chat:ingest"
      L7_2 = {}
      L7_2.cat = L3_2
      L7_2.text = L2_2
      if A0_2 then
        L8_2 = A0_2.replyTo
        if L8_2 then
          goto lbl_92
        end
      end
      L8_2 = nil
      ::lbl_92::
      L7_2.replyTo = L8_2
      L8_2 = L4_2 or L8_2
      if "" == L4_2 or not L4_2 then
        L8_2 = nil
      end
      L7_2.image = L8_2
      L5_2(L6_2, L7_2)
    end
  end
  L5_2 = A1_2
  L6_2 = {}
  L6_2.ok = true
  L5_2(L6_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_chat_send_photo"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = tostring
  if A0_2 then
    L3_2 = A0_2.text
    if L3_2 then
      goto lbl_8
    end
  end
  L3_2 = ""
  ::lbl_8::
  L2_2 = L2_2(L3_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "^%s+"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = L2_2
  L2_2 = L2_2.gsub
  L4_2 = "%s+$"
  L5_2 = ""
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = tostring
  if A0_2 then
    L4_2 = A0_2.cat
    if L4_2 then
      goto lbl_25
    end
  end
  L4_2 = Config
  L4_2 = L4_2.DefaultCategory
  ::lbl_25::
  L3_2 = L3_2(L4_2)
  if A0_2 then
    L4_2 = A0_2.replyTo
    if L4_2 then
      goto lbl_32
    end
  end
  L4_2 = nil
  ::lbl_32::
  L5_2 = L13_1
  L5_2 = L5_2()
  L7_2 = L2_2
  L6_2 = L2_2.sub
  L8_2 = 1
  L9_2 = 1
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  if "/" == L6_2 then
    L2_2 = ""
  end
  L6_2 = L18_1
  L6_2()
  function L6_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3
    if A0_3 then
      L3_3 = TriggerServerEvent
      L4_3 = "apex_chat:ingest"
      L5_3 = {}
      L6_3 = L3_2
      L5_3.cat = L6_3
      L6_3 = L2_2
      L5_3.text = L6_3
      L6_3 = L4_2
      L5_3.replyTo = L6_3
      L5_3.image = A1_3
      L3_3(L4_3, L5_3)
    end
    L3_3 = A1_2
    L4_3 = {}
    L4_3.ok = A0_3
    L4_3.error = A2_3
    L3_3(L4_3)
  end
  L7_2 = L5_2.framing
  if false ~= L7_2 then
    L7_2 = L16_1
    L8_2 = L6_2
    L7_2(L8_2)
  else
    L7_2 = CreateThread
    function L8_2()
      local L0_3, L1_3, L2_3
      L0_3 = Wait
      L1_3 = L5_2.chatCaptureDelayMs
      if not L1_3 then
        L1_3 = 180
      end
      L0_3(L1_3)
      L0_3 = L15_1
      L1_3 = L6_2
      L2_3 = "chat"
      L0_3(L1_3, L2_3)
    end
    L7_2(L8_2)
  end
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_chat_react"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = TriggerServerEvent
    L3_2 = "apex_chat:react"
    L4_2 = {}
    L5_2 = A0_2.id
    L4_2.id = L5_2
    L5_2 = A0_2.type
    L4_2.type = L5_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_chat_blur"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L18_1
  L2_2()
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_chat_active_cat"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.cat
    if L2_2 then
      L2_2 = ApexChat
      if L2_2 then
        L2_2 = ApexChat
        L3_2 = L2_2
        L2_2 = L2_2.GetPrefs
        L2_2 = L2_2(L3_2)
        L3_2 = A0_2.cat
        L2_2.activeCategory = L3_2
        L3_2 = ApexChat
        L4_2 = L3_2
        L3_2 = L3_2.SetPrefs
        L5_2 = L2_2
        L3_2(L4_2, L5_2)
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "apex_gif_search"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:gif"
  L4_2 = type
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  if "table" == L4_2 then
    L4_2 = A0_2.term
    if L4_2 then
      goto lbl_12
    end
  end
  L4_2 = ""
  ::lbl_12::
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "apex_chat:gif:results"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_gif_results"
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = {}
  end
  L2_2.results = L3_2
  L1_2(L2_2)
end
L19_1(L20_1, L21_1)
L19_1 = 0
L20_1 = RegisterNUICallback
L21_1 = "apex_chat_typing"
function L22_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = GetGameTimer
  L2_2 = L2_2()
  L3_2 = L19_1
  L3_2 = L2_2 - L3_2
  L4_2 = 900
  if L3_2 > L4_2 then
    L19_1 = L2_2
    L3_2 = TriggerServerEvent
    L4_2 = "apex_chat:typing"
    L5_2 = type
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
    if "table" == L5_2 then
      L5_2 = A0_2.cat
      if L5_2 then
        goto lbl_21
      end
    end
    L5_2 = ""
    ::lbl_21::
    L3_2(L4_2, L5_2)
  end
  L3_2 = A1_2
  L4_2 = {}
  L4_2.ok = true
  L3_2(L4_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:typing:show"
function L22_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_typing"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNUICallback
L21_1 = "apex_chat_roster"
function L22_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:roster:request"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:roster:sync"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_roster"
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = {}
  end
  L2_2.players = L3_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNUICallback
L21_1 = "apex_chat_admin"
function L22_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = A0_2.act
    if "remove" == L2_2 then
      L2_2 = A0_2.id
      if L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "apex_chat:msg:remove"
        L4_2 = tostring
        L5_2 = A0_2.id
        L4_2, L5_2, L6_2 = L4_2(L5_2)
        L2_2(L3_2, L4_2, L5_2, L6_2)
    end
    else
      L2_2 = A0_2.act
      if "edit" == L2_2 then
        L2_2 = A0_2.id
        if L2_2 then
          L2_2 = TriggerServerEvent
          L3_2 = "apex_chat:msg:edit"
          L4_2 = tostring
          L5_2 = A0_2.id
          L4_2 = L4_2(L5_2)
          L5_2 = tostring
          L6_2 = A0_2.text
          if not L6_2 then
            L6_2 = ""
          end
          L5_2, L6_2 = L5_2(L6_2)
          L2_2(L3_2, L4_2, L5_2, L6_2)
        end
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:msg:removed"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_msg_remove"
  L3_2 = tostring
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L2_2.id = L3_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:msg:edited"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_msg_edit"
  L3_2 = tostring
  L4_2 = A0_2.id
  if not L4_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L2_2.id = L3_2
  L3_2 = tostring
  L4_2 = A0_2.text
  if not L4_2 then
    L4_2 = ""
  end
  L3_2 = L3_2(L4_2)
  L2_2.text = L3_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNUICallback
L21_1 = "apex_chat_screenshot"
function L22_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = A0_2.mode
    if L2_2 then
      goto lbl_7
    end
  end
  L2_2 = nil
  ::lbl_7::
  L3_2 = L15_1
  function L4_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3
    L3_3 = A1_2
    L4_3 = {}
    L4_3.ok = A0_3
    L4_3.base64 = A1_3
    L4_3.error = A2_3
    L3_3(L4_3)
  end
  L5_2 = L2_2
  L3_2(L4_2, L5_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNUICallback
L21_1 = "apex_chat_mugshot"
function L22_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A0_2 or nil
  if A0_2 then
    L2_2 = tonumber
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
  end
  if not L2_2 then
    L3_2 = A1_2
    L4_2 = {}
    L4_2.ok = false
    L3_2(L4_2)
    return
  end
  L3_2 = L12_1
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  L4_2 = A1_2
  L5_2 = {}
  L6_2 = nil ~= L3_2
  L5_2.ok = L6_2
  L5_2.url = L3_2
  L4_2(L5_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterCommand
L21_1 = L13_1
L21_1 = L21_1()
L21_1 = L21_1.command
if not L21_1 then
  L21_1 = "chatfoto"
end
function L22_1()
  local L0_2, L1_2
  L0_2 = L15_1
  function L1_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3
    if A0_3 then
      L3_3 = print
      L4_3 = "[apex_chat] Screen photo saved as base64 (%d chars)."
      L5_3 = L4_3
      L4_3 = L4_3.format
      L6_3 = #A1_3
      L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3, L6_3)
      L3_3(L4_3, L5_3, L6_3, L7_3)
    else
      L3_3 = print
      L4_3 = "[apex_chat] Screen photo failed: %s"
      L5_3 = L4_3
      L4_3 = L4_3.format
      L6_3 = tostring
      L7_3 = A2_3
      L6_3, L7_3 = L6_3(L7_3)
      L4_3, L5_3, L6_3, L7_3 = L4_3(L5_3, L6_3, L7_3)
      L3_3(L4_3, L5_3, L6_3, L7_3)
    end
  end
  L0_2(L1_2)
end
L23_1 = false
L20_1(L21_1, L22_1, L23_1)
L20_1 = RegisterCommand
L21_1 = "chatphoto"
function L22_1()
  local L0_2, L1_2
  L0_2 = ExecuteCommand
  L1_2 = L13_1
  L1_2 = L1_2()
  L1_2 = L1_2.command
  if not L1_2 then
    L1_2 = "chatfoto"
  end
  L0_2(L1_2)
end
L23_1 = false
L20_1(L21_1, L22_1, L23_1)
L20_1 = exports
L21_1 = "TakeScreenshotBase64"
function L22_1(A0_2)
  local L1_2, L2_2
  L1_2 = L15_1
  L2_2 = A0_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = exports
L21_1 = "GetLastScreenshotBase64"
function L22_1()
  local L0_2, L1_2, L2_2
  L0_2 = L4_1
  if L0_2 then
    L0_2 = L4_1
    return L0_2
  end
  L0_2 = L13_1
  L0_2 = L0_2()
  L1_2 = GetResourceKvpString
  L2_2 = L0_2.kvpKey
  if not L2_2 then
    L2_2 = "apex_chat:last_screen_photo_base64"
  end
  return L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = CreateThread
function L21_1()
  local L0_2, L1_2, L2_2
  L0_2 = pcall
  L1_2 = DeleteResourceKvp
  L2_2 = "apex_chat:history"
  L0_2(L1_2, L2_2)
end
L20_1(L21_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:hidden"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = true == A0_2
  L2_1 = L1_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_chat_hidden"
  L3_2 = L2_1
  L2_2.hidden = L3_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = exports
L21_1 = "IsChatHidden"
function L22_1()
  local L0_2, L1_2
  L0_2 = L2_1
  return L0_2
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:recv"
function L22_1(A0_2)
  local L1_2, L2_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = A0_2.senderId
  L2_2 = L7_1
  L2_2 = L2_2()
  L1_2 = L1_2 == L2_2
  A0_2.mine = L1_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_msg"
  L2_2.msg = A0_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_chat:cats:sync"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_cats"
  L3_2 = A0_2.tabs
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.tabs = L3_2
  L3_2 = A0_2.all
  L2_2.all = L3_2
  L3_2 = A0_2.isManager
  if not L3_2 then
    L3_2 = false
  end
  L2_2.isManager = L3_2
  L3_2 = A0_2.default
  if not L3_2 then
    L3_2 = Config
    L3_2 = L3_2.DefaultCategory
  end
  L2_2.default = L3_2
  L3_2 = ApexChat
  if L3_2 then
    L3_2 = ApexChat
    L4_2 = L3_2
    L3_2 = L3_2.GetPrefs
    L3_2 = L3_2(L4_2)
    L3_2 = L3_2.activeCategory
    if L3_2 then
      goto lbl_41
    end
  end
  L3_2 = Config
  L3_2 = L3_2.DefaultCategory
  ::lbl_41::
  L2_2.active = L3_2
  L1_2(L2_2)
end
L20_1(L21_1, L22_1)
L20_1 = CreateThread
function L21_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = false
  L1_2 = SetTextChatEnabled
  L2_2 = false
  L1_2(L2_2)
  while true do
    L1_2 = Wait
    L2_2 = 150
    L1_2(L2_2)
    L1_2 = SetTextChatEnabled
    L2_2 = false
    L1_2(L2_2)
    L1_2 = IsScreenFadedOut
    L1_2 = L1_2()
    if not L1_2 then
      L1_2 = IsPauseMenuActive
      L1_2 = L1_2()
      if not L1_2 then
        L1_2 = L1_1
      end
    end
    if L1_2 then
      L2_2 = L0_1
      if L2_2 then
        L2_2 = L18_1
        L2_2()
      end
    end
    if L1_2 ~= L0_2 then
      L0_2 = L1_2
      L2_2 = SendNUIMessage
      L3_2 = {}
      L3_2.action = "apex_screen"
      L3_2.shouldHide = L1_2
      L2_2(L3_2)
    end
  end
end
L20_1(L21_1)
L20_1 = CreateThread
function L21_1()
  local L0_2, L1_2
  while true do
    L0_2 = ApexChat
    if L0_2 then
      L0_2 = ApexChat
      L0_2 = L0_2.Prefs
      if L0_2 then
        break
      end
    end
    L0_2 = Wait
    L1_2 = 50
    L0_2(L1_2)
  end
  L0_2 = Wait
  L1_2 = 500
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "apex_chat:cats:request"
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "apex_chat:roster:request"
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "apex_chat:hidden:request"
  L0_2(L1_2)
end
L20_1(L21_1)
L20_1 = AddEventHandler
L21_1 = "onResourceStop"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 == L1_2 then
    L1_2 = pairs
    L2_2 = L5_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2 in L1_2, L2_2, L3_2, L4_2 do
      L6_2 = L9_1
      L7_2 = L5_2
      L6_2(L7_2)
    end
    L1_2 = {}
    L6_1 = L1_2
    L1_2 = L0_1
    if L1_2 then
      L1_2 = SetNuiFocus
      L2_2 = false
      L3_2 = false
      L1_2(L2_2, L3_2)
    end
  end
end
L20_1(L21_1, L22_1)
