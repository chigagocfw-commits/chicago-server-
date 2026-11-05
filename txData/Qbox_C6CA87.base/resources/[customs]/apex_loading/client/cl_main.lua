local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1
L0_1 = false
L1_1 = false
function L2_1()
  local L0_2, L1_2
  L0_2 = L0_1
  if L0_2 then
    return
  end
  L0_2 = true
  L0_1 = L0_2
  L0_2 = ShutdownLoadingScreenNui
  L0_2()
  L0_2 = ShutdownLoadingScreen
  L0_2()
end
L3_1 = RegisterNUICallback
L4_1 = "apexExit"
function L5_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = L2_1
  L2_2()
end
L3_1(L4_1, L5_1)
L3_1 = RegisterNUICallback
L4_1 = "diag"
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.msg
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = print
      L3_2 = "^5[apex_loading]^0 "
      L4_2 = A0_2.msg
      L5_2 = L4_2
      L4_2 = L4_2.sub
      L6_2 = 1
      L7_2 = 300
      L4_2 = L4_2(L5_2, L6_2, L7_2)
      L3_2 = L3_2 .. L4_2
      L2_2(L3_2)
    end
  end
end
L3_1(L4_1, L5_1)
function L3_1()
  local L0_2, L1_2
  L0_2 = NetworkIsSessionStarted
  L0_2 = L0_2()
  L1_2 = true == L0_2 or 1 == L0_2
  return L1_2
end
L4_1 = CreateThread
function L5_1()
  local L0_2, L1_2, L2_2
  while true do
    L0_2 = L3_1
    L0_2 = L0_2()
    if L0_2 then
      break
    end
    L0_2 = Wait
    L1_2 = 250
    L0_2(L1_2)
  end
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L1_2 = Config
  L1_2 = L1_2.Exit
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.Exit
    L1_2 = L1_2.maxSecondsAfterSpawn
    if L1_2 then
      goto lbl_21
    end
  end
  L1_2 = 30
  ::lbl_21::
  L1_2 = L1_2 * 1000
  L0_2 = L0_2 + L1_2
  while true do
    L1_2 = L0_1
    if L1_2 then
      break
    end
    L1_2 = GetGameTimer
    L1_2 = L1_2()
    if not (L0_2 > L1_2) then
      break
    end
    L1_2 = Wait
    L2_2 = 250
    L1_2(L2_2)
  end
  L1_2 = L2_1
  L1_2()
end
L4_1(L5_1)
function L4_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = A0_2
  L3_2.data = A1_2
  L2_2(L3_2)
end
function L5_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L2_2 = TriggerEvent
  L3_2 = "chat:addMessage"
  L4_2 = {}
  if A1_2 then
    L5_2 = {}
    L6_2 = 229
    L7_2 = 86
    L8_2 = 75
    L5_2[1] = L6_2
    L5_2[2] = L7_2
    L5_2[3] = L8_2
    if L5_2 then
      goto lbl_21
    end
  end
  L5_2 = {}
  L6_2 = 120
  L7_2 = 200
  L8_2 = 140
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L5_2[3] = L8_2
  ::lbl_21::
  L4_2.color = L5_2
  L5_2 = {}
  L6_2 = "APEX LOADING"
  L7_2 = A0_2
  L5_2[1] = L6_2
  L5_2[2] = L7_2
  L4_2.args = L5_2
  L2_2(L3_2, L4_2)
end
function L6_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = true
  L1_1 = L1_2
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = L4_1
  L2_2 = "openCreator"
  L3_2 = {}
  L4_2 = A0_2.design
  L3_2.design = L4_2
  L4_2 = GetLocales
  L4_2 = L4_2()
  L3_2.locales = L4_2
  L4_2 = A0_2.ai
  L4_2 = true == L4_2
  L3_2.ai = L4_2
  L4_2 = A0_2.yt
  L3_2.yt = L4_2
  L1_2(L2_2, L3_2)
end
L7_1 = {}
L7_1.part = 16000
L7_1.rate = 90112
L7_1.burst = 196608
L7_1.perSecond = 20
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = {}
  L3_2 = "part"
  L4_2 = "rate"
  L5_2 = "burst"
  L6_2 = "perSecond"
  L2_2[1] = L3_2
  L2_2[2] = L4_2
  L2_2[3] = L5_2
  L2_2[4] = L6_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = tonumber
    L8_2 = A0_2[L6_2]
    L7_2 = L7_2(L8_2)
    if L7_2 and L7_2 > 0 then
      L8_2 = L7_1
      L8_2[L6_2] = L7_2
    end
  end
  L1_2 = math
  L1_2 = L1_2.max
  L2_2 = 4000
  L3_2 = math
  L3_2 = L3_2.floor
  L4_2 = L7_1.part
  L4_2 = L4_2 / 4
  L3_2 = L3_2(L4_2)
  L3_2 = L3_2 * 4
  L1_2 = L1_2(L2_2, L3_2)
  L7_1.part = L1_2
  L1_2 = math
  L1_2 = L1_2.max
  L2_2 = L7_1.burst
  L3_2 = L7_1.part
  L3_2 = L3_2 * 2
  L1_2 = L1_2(L2_2, L3_2)
  L7_1.burst = L1_2
end
L9_1 = 6
L10_1 = 20000
L11_1 = {}
L12_1 = {}
L11_1.queue = L12_1
L11_1.running = false
L11_1.cur = nil
L11_1.tokens = nil
L11_1.last = 0
L11_1.lastSend = 0
L12_1 = {}
function L13_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = L11_1.tokens
  if not L2_2 then
    L2_2 = L7_1.burst
    L11_1.last = L1_2
    L11_1.tokens = L2_2
  end
  L2_2 = math
  L2_2 = L2_2.ceil
  L3_2 = L7_1.perSecond
  L4_2 = 1000
  L3_2 = L4_2 / L3_2
  L2_2 = L2_2(L3_2)
  while true do
    L3_2 = GetGameTimer
    L3_2 = L3_2()
    L1_2 = L3_2
    L3_2 = math
    L3_2 = L3_2.min
    L4_2 = L7_1.burst
    L5_2 = L11_1.tokens
    L6_2 = L11_1.last
    L6_2 = L1_2 - L6_2
    L7_2 = L7_1.rate
    L6_2 = L6_2 * L7_2
    L6_2 = L6_2 / 1000
    L5_2 = L5_2 + L6_2
    L3_2 = L3_2(L4_2, L5_2)
    L11_1.tokens = L3_2
    L11_1.last = L1_2
    L3_2 = L11_1.tokens
    if A0_2 <= L3_2 then
      L3_2 = 0
      if L3_2 then
        goto lbl_53
      end
    end
    L3_2 = math
    L3_2 = L3_2.ceil
    L4_2 = L11_1.tokens
    L4_2 = A0_2 - L4_2
    L4_2 = L4_2 * 1000
    L5_2 = L7_1.rate
    L4_2 = L4_2 / L5_2
    L3_2 = L3_2(L4_2)
    ::lbl_53::
    L4_2 = L11_1.lastSend
    L4_2 = L4_2 + L2_2
    L4_2 = L4_2 - L1_2
    L5_2 = math
    L5_2 = L5_2.max
    L6_2 = L3_2
    L7_2 = L4_2
    L5_2 = L5_2(L6_2, L7_2)
    if L5_2 <= 0 then
      break
    end
    L6_2 = Wait
    L7_2 = math
    L7_2 = L7_2.min
    L8_2 = L5_2
    L9_2 = 250
    L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
    L6_2(L7_2, L8_2, L9_2)
  end
  L3_2 = L11_1.tokens
  L3_2 = L3_2 - A0_2
  L11_1.tokens = L3_2
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L11_1.lastSend = L3_2
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = A0_2.data
  L2_2 = L7_1.part
  L3_2 = math
  L3_2 = L3_2.max
  L4_2 = 1
  L5_2 = math
  L5_2 = L5_2.ceil
  L6_2 = #L1_2
  L6_2 = L6_2 / L2_2
  L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  L4_2 = {}
  L5_2 = A0_2.id
  L4_2.id = L5_2
  L4_2.acks = 0
  L4_2.began = false
  L4_2.fail = nil
  L5_2 = GetGameTimer
  L5_2 = L5_2()
  L4_2.lastAck = L5_2
  L4_2.painted = 0
  L11_1.cur = L4_2
  function L5_2()
    local L0_3, L1_3, L2_3
    L0_3 = math
    L0_3 = L0_3.floor
    L1_3 = L4_2.acks
    L2_3 = L3_2
    L1_3 = L1_3 / L2_3
    L1_3 = L1_3 * 100
    return L0_3(L1_3)
  end
  function L6_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = GetGameTimer
    L1_3 = L1_3()
    if not A0_3 then
      L2_3 = L4_2.painted
      L2_3 = L1_3 - L2_3
      L3_3 = 200
      if not (L2_3 > L3_3) then
        goto lbl_24
      end
    end
    L4_2.painted = L1_3
    L2_3 = L4_1
    L3_3 = "upProgress"
    L4_3 = {}
    L5_3 = A0_2.kind
    L4_3.kind = L5_3
    L5_3 = A0_2.id
    L4_3.id = L5_3
    L5_3 = L5_2
    L5_3 = L5_3()
    L4_3.pct = L5_3
    L2_3(L3_3, L4_3)
    ::lbl_24::
  end
  function L7_2()
    local L0_3, L1_3, L2_3
    L0_3 = GetGameTimer
    L0_3 = L0_3()
    L1_3 = L4_2.lastAck
    L0_3 = L0_3 - L1_3
    L1_3 = L10_1
    if L0_3 <= L1_3 then
      L0_3 = false
      return L0_3
    end
    L0_3 = L4_2.began
    if L0_3 then
      L0_3 = "the server stopped answering at %d%%. Run loading_diag in the server console."
      L1_3 = L0_3
      L0_3 = L0_3.format
      L2_3 = L5_2
      L2_3 = L2_3()
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        goto lbl_22
      end
    end
    L0_3 = "the server did not answer the publish request. Is apex_loading started on the server?"
    ::lbl_22::
    L4_2.fail = L0_3
    L0_3 = true
    return L0_3
  end
  L8_2 = L13_1
  L9_2 = 512
  L8_2(L9_2)
  L8_2 = TriggerServerEvent
  L9_2 = "apex_loading:server:UpBegin"
  L10_2 = A0_2.kind
  L11_2 = A0_2.id
  L12_2 = L3_2
  L13_2 = #L1_2
  L14_2 = A0_2.meta
  if not L14_2 then
    L14_2 = {}
  end
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2)
  while true do
    L8_2 = L4_2.began
    if L8_2 then
      break
    end
    L8_2 = L4_2.fail
    if L8_2 then
      break
    end
    L8_2 = L7_2
    L8_2 = L8_2()
    if L8_2 then
      break
    end
    L8_2 = Wait
    L9_2 = 50
    L8_2(L9_2)
  end
  L8_2 = 0
  while true do
    L9_2 = L4_2.fail
    if not (not L9_2 and L3_2 > L8_2) then
      break
    end
    L9_2 = L4_2.acks
    L9_2 = L8_2 - L9_2
    L10_2 = L9_1
    if L9_2 < L10_2 then
      L8_2 = L8_2 + 1
      L10_2 = L1_2
      L9_2 = L1_2.sub
      L11_2 = L8_2 - 1
      L11_2 = L11_2 * L2_2
      L11_2 = L11_2 + 1
      L12_2 = L8_2 * L2_2
      L9_2 = L9_2(L10_2, L11_2, L12_2)
      L10_2 = L13_1
      L11_2 = #L9_2
      L11_2 = L11_2 + 160
      L10_2(L11_2)
      L10_2 = L4_2.fail
      if L10_2 then
        break
      end
      L10_2 = TriggerServerEvent
      L11_2 = "apex_loading:server:UpPart"
      L12_2 = A0_2.id
      L13_2 = L8_2
      L14_2 = L9_2
      L10_2(L11_2, L12_2, L13_2, L14_2)
    else
      L9_2 = L7_2
      L9_2 = L9_2()
      if L9_2 then
        break
      end
      L9_2 = Wait
      L10_2 = 30
      L9_2(L10_2)
    end
    L9_2 = L6_2
    L10_2 = false
    L9_2(L10_2)
  end
  while true do
    L9_2 = L4_2.fail
    if L9_2 then
      break
    end
    L9_2 = L4_2.acks
    if not (L3_2 > L9_2) then
      break
    end
    L9_2 = L7_2
    L9_2 = L9_2()
    if L9_2 then
      break
    end
    L9_2 = Wait
    L10_2 = 50
    L9_2(L10_2)
    L9_2 = L6_2
    L10_2 = false
    L9_2(L10_2)
  end
  L9_2 = L6_2
  L10_2 = true
  L9_2(L10_2)
  L9_2 = L4_2.fail
  if L9_2 then
    L9_2 = print
    L10_2 = "^3[apex_loading]^0 the %s upload failed: %s"
    L11_2 = L10_2
    L10_2 = L10_2.format
    L12_2 = A0_2.kind
    L13_2 = L4_2.fail
    L10_2, L11_2, L12_2, L13_2, L14_2 = L10_2(L11_2, L12_2, L13_2)
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2)
    L9_2 = L4_1
    L10_2 = "upFail"
    L11_2 = {}
    L12_2 = A0_2.kind
    L11_2.kind = L12_2
    L12_2 = A0_2.id
    L11_2.id = L12_2
    L12_2 = L4_2.fail
    L11_2.error = L12_2
    L9_2(L10_2, L11_2)
    L9_2 = L1_1
    if not L9_2 then
      L9_2 = L5_1
      L10_2 = L4_2.fail
      L11_2 = true
      L9_2(L10_2, L11_2)
    end
  end
  L11_1.cur = nil
end
function L15_1()
  local L0_2, L1_2
  L0_2 = L11_1.running
  if L0_2 then
    return
  end
  L11_1.running = true
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
    while true do
      L0_3 = L11_1.queue
      L0_3 = #L0_3
      if not (L0_3 > 0) then
        break
      end
      L0_3 = table
      L0_3 = L0_3.remove
      L1_3 = L11_1.queue
      L2_3 = 1
      L0_3 = L0_3(L1_3, L2_3)
      L1_3 = pcall
      L2_3 = L14_1
      L3_3 = L0_3
      L1_3, L2_3 = L1_3(L2_3, L3_3)
      if not L1_3 then
        L11_1.cur = nil
        L3_3 = print
        L4_3 = "^1[apex_loading]^0 sending failed: "
        L5_3 = tostring
        L6_3 = L2_3
        L5_3 = L5_3(L6_3)
        L4_3 = L4_3 .. L5_3
        L3_3(L4_3)
        L3_3 = L4_1
        L4_3 = "upFail"
        L5_3 = {}
        L6_3 = L0_3.kind
        L5_3.kind = L6_3
        L6_3 = L0_3.id
        L5_3.id = L6_3
        L6_3 = "the game failed to send it: "
        L7_3 = tostring
        L8_3 = L2_3
        L7_3 = L7_3(L8_3)
        L6_3 = L6_3 .. L7_3
        L5_3.error = L6_3
        L3_3(L4_3, L5_3)
      end
    end
    L11_1.running = false
  end
  L0_2(L1_2)
end
function L16_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2
  L4_2 = L11_1.queue
  L5_2 = L11_1.queue
  L5_2 = #L5_2
  L5_2 = L5_2 + 1
  L6_2 = {}
  L6_2.kind = A0_2
  L6_2.id = A1_2
  L6_2.data = A2_2
  L7_2 = A3_2 or L7_2
  if not A3_2 then
    L7_2 = {}
  end
  L6_2.meta = L7_2
  L4_2[L5_2] = L6_2
  L4_2 = L15_1
  L4_2()
end
L17_1 = RegisterNetEvent
L18_1 = "apex_loading:client:UpAck"
function L19_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L11_1.cur
  if L2_2 then
    L3_2 = L2_2.id
    if L3_2 == A0_2 then
      goto lbl_8
    end
  end
  do return end
  ::lbl_8::
  L3_2 = GetGameTimer
  L3_2 = L3_2()
  L2_2.lastAck = L3_2
  if 0 == A1_2 then
    L2_2.began = true
  else
    L3_2 = L2_2.acks
    L3_2 = L3_2 + 1
    L2_2.acks = L3_2
  end
end
L17_1(L18_1, L19_1)
L17_1 = RegisterNetEvent
L18_1 = "apex_loading:client:UpFail"
function L19_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L11_1.cur
  if L2_2 then
    L3_2 = L2_2.id
    if L3_2 == A0_2 then
      L3_2 = tostring
      L4_2 = A1_2
      L3_2 = L3_2(L4_2)
      L2_2.fail = L3_2
      return
    end
  end
  L3_2 = print
  L4_2 = "^3[apex_loading]^0 upload failed: %s"
  L5_2 = L4_2
  L4_2 = L4_2.format
  L6_2 = tostring
  L7_2 = A1_2
  L6_2, L7_2 = L6_2(L7_2)
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2, L6_2, L7_2)
  L3_2(L4_2, L5_2, L6_2, L7_2)
  L3_2 = L4_1
  L4_2 = "upFail"
  L5_2 = {}
  L5_2.id = A0_2
  L6_2 = tostring
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  L5_2.error = L6_2
  L3_2(L4_2, L5_2)
  L3_2 = L1_1
  if not L3_2 then
    L3_2 = L5_1
    L4_2 = tostring
    L5_2 = A1_2
    L4_2 = L4_2(L5_2)
    L5_2 = true
    L3_2(L4_2, L5_2)
  end
end
L17_1(L18_1, L19_1)
L17_1 = RegisterNUICallback
L18_1 = "upBegin"
function L19_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L1_1
  if L2_2 then
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = type
      L3_2 = A0_2.id
      L2_2 = L2_2(L3_2)
      if "string" == L2_2 then
        L2_2 = A0_2.id
        L2_2 = #L2_2
        if not (L2_2 > 64) then
          L2_2 = A0_2.kind
          if "design" == L2_2 then
            goto lbl_31
          end
          L2_2 = A0_2.kind
          if "media" == L2_2 then
            goto lbl_31
          end
        end
      end
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = false
  L3_2.error = "the creator is not open"
  L2_2(L3_2)
  do return end
  ::lbl_31::
  L3_2 = A0_2.id
  L2_2 = L12_1
  L4_2 = {}
  L5_2 = A0_2.kind
  L4_2.kind = L5_2
  L5_2 = tonumber
  L6_2 = A0_2.bytes
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = -1
  end
  L4_2.bytes = L5_2
  L5_2 = tonumber
  L6_2 = A0_2.parts
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = -1
  end
  L4_2.parts = L5_2
  L5_2 = type
  L6_2 = A0_2.meta
  L5_2 = L5_2(L6_2)
  if "table" == L5_2 then
    L5_2 = A0_2.meta
    if L5_2 then
      goto lbl_61
    end
  end
  L5_2 = {}
  ::lbl_61::
  L4_2.meta = L5_2
  L5_2 = {}
  L4_2.chunks = L5_2
  L4_2.n = 0
  L4_2.size = 0
  L2_2[L3_2] = L4_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L17_1(L18_1, L19_1)
L17_1 = RegisterNUICallback
L18_1 = "upPart"
function L19_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2.id
  L2_2 = L2_2(L3_2)
  L3_2 = A0_2.id
  L2_2 = L12_1
  L2_2 = "table" == L2_2 and L2_2
  L3_2 = L2_2 or L3_2
  if L2_2 then
    L3_2 = tonumber
    L4_2 = A0_2.index
    L3_2 = L3_2(L4_2)
  end
  if L2_2 and L3_2 then
    L4_2 = type
    L5_2 = A0_2.data
    L4_2 = L4_2(L5_2)
    if "string" == L4_2 then
      goto lbl_38
    end
  end
  L4_2 = A1_2
  L5_2 = {}
  L5_2.ok = false
  L5_2.error = "the game lost this upload, try again"
  L4_2(L5_2)
  do return end
  ::lbl_38::
  L4_2 = L2_2.chunks
  L4_2 = L4_2[L3_2]
  if not L4_2 then
    L4_2 = L2_2.chunks
    L5_2 = A0_2.data
    L4_2[L3_2] = L5_2
    L4_2 = L2_2.n
    L4_2 = L4_2 + 1
    L2_2.n = L4_2
    L4_2 = L2_2.size
    L5_2 = A0_2.data
    L5_2 = #L5_2
    L4_2 = L4_2 + L5_2
    L2_2.size = L4_2
  end
  L4_2 = A1_2
  L5_2 = {}
  L5_2.ok = true
  L4_2(L5_2)
end
L17_1(L18_1, L19_1)
L17_1 = RegisterNUICallback
L18_1 = "upCommit"
function L19_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = A0_2.id
      if L2_2 then
        goto lbl_15
      end
    end
  end
  L2_2 = nil
  ::lbl_15::
  L3_2 = L2_2 or L3_2
  if L2_2 then
    L3_2 = L12_1
    L3_2 = L3_2[L2_2]
  end
  if L2_2 then
    L4_2 = L12_1
    L4_2[L2_2] = nil
  end
  if not L3_2 then
    L4_2 = A1_2
    L5_2 = {}
    L5_2.ok = false
    L5_2.error = "the game lost this upload, try again"
    L4_2(L5_2)
    return
  end
  L4_2 = L3_2.n
  L5_2 = L3_2.parts
  if L4_2 == L5_2 then
    L4_2 = L3_2.size
    L5_2 = L3_2.bytes
    if L4_2 == L5_2 then
      goto lbl_52
    end
  end
  L4_2 = A1_2
  L5_2 = {}
  L5_2.ok = false
  L6_2 = "the game received %d of %d bytes from the creator, try again"
  L7_2 = L6_2
  L6_2 = L6_2.format
  L8_2 = L3_2.size
  L9_2 = L3_2.bytes
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L5_2.error = L6_2
  L4_2(L5_2)
  do return end
  ::lbl_52::
  L4_2 = L16_1
  L5_2 = L3_2.kind
  L6_2 = L2_2
  L7_2 = table
  L7_2 = L7_2.concat
  L8_2 = L3_2.chunks
  L9_2 = ""
  L10_2 = 1
  L11_2 = L3_2.n
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  L8_2 = L3_2.meta
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = A1_2
  L5_2 = {}
  L5_2.ok = true
  L4_2(L5_2)
end
L17_1(L18_1, L19_1)
L17_1 = nil
L18_1 = RegisterNetEvent
L19_1 = "apex_loading:client:Design"
function L20_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if A0_2 then
    L1_2 = A0_2.allowed
    if true == L1_2 then
      goto lbl_16
    end
  end
  L1_2 = L5_1
  L2_2 = GetLocales
  L2_2 = L2_2()
  L2_2 = L2_2.cr_noaccess
  if not L2_2 then
    L2_2 = "No access."
  end
  L3_2 = true
  L1_2(L2_2, L3_2)
  do return end
  ::lbl_16::
  L1_2 = L8_1
  L2_2 = A0_2.up
  L1_2(L2_2)
  L1_2 = type
  L2_2 = A0_2.down
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = L6_1
    L2_2 = A0_2
    L1_2(L2_2)
    return
  end
  L1_2 = {}
  L2_2 = A0_2.down
  L2_2 = L2_2.id
  L1_2.id = L2_2
  L2_2 = tonumber
  L3_2 = A0_2.down
  L3_2 = L3_2.parts
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = 0
  end
  L1_2.parts = L2_2
  L2_2 = {}
  L1_2.chunks = L2_2
  L1_2.got = 0
  L1_2.payload = A0_2
  L17_1 = L1_2
  L2_2 = SetTimeout
  L3_2 = 30000
  function L4_2()
    local L0_3, L1_3, L2_3
    L0_3 = L17_1
    L1_3 = L1_2
    if L0_3 == L1_3 then
      L0_3 = nil
      L17_1 = L0_3
      L0_3 = L5_1
      L1_3 = "The published design did not arrive in time. Open the creator again."
      L2_3 = true
      L0_3(L1_3, L2_3)
    end
  end
  L2_2(L3_2, L4_2)
end
L18_1(L19_1, L20_1)
L18_1 = RegisterNetEvent
L19_1 = "apex_loading:client:DownPart"
function L20_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = L17_1
  if L3_2 then
    L4_2 = L3_2.id
    if L4_2 == A0_2 then
      L4_2 = type
      L5_2 = A2_2
      L4_2 = L4_2(L5_2)
      if "string" == L4_2 then
        goto lbl_13
      end
    end
  end
  do return end
  ::lbl_13::
  L4_2 = tonumber
  L5_2 = A1_2
  L4_2 = L4_2(L5_2)
  A1_2 = L4_2
  if A1_2 then
    L4_2 = L3_2.chunks
    L4_2 = L4_2[A1_2]
    if not L4_2 then
      goto lbl_24
    end
  end
  do return end
  ::lbl_24::
  L4_2 = L3_2.chunks
  L4_2[A1_2] = A2_2
  L4_2 = L3_2.got
  L4_2 = L4_2 + 1
  L3_2.got = L4_2
  L4_2 = L3_2.got
  L5_2 = L3_2.parts
  if L4_2 < L5_2 then
    return
  end
  L4_2 = nil
  L17_1 = L4_2
  L4_2 = table
  L4_2 = L4_2.concat
  L5_2 = L3_2.chunks
  L6_2 = ""
  L7_2 = 1
  L8_2 = L3_2.parts
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2)
  L5_2 = #L4_2
  L6_2 = tonumber
  L7_2 = L3_2.payload
  L7_2 = L7_2.down
  L7_2 = L7_2.bytes
  L6_2 = L6_2(L7_2)
  if L5_2 ~= L6_2 then
    L5_2 = L5_1
    L6_2 = "The published design arrived incomplete. Open the creator again."
    L7_2 = true
    L5_2(L6_2, L7_2)
    return
  end
  L5_2 = L3_2.payload
  L5_2.design = L4_2
  L5_2 = L6_1
  L6_2 = L3_2.payload
  L5_2(L6_2)
end
L18_1(L19_1, L20_1)
function L18_1()
  local L0_2, L1_2, L2_2
  L0_2 = L1_1
  if L0_2 then
    L0_2 = false
    L1_1 = L0_2
    L0_2 = SetNuiFocus
    L1_2 = false
    L2_2 = false
    L0_2(L1_2, L2_2)
    L0_2 = SendNUIMessage
    L1_2 = {}
    L1_2.action = "closeCreator"
    L0_2(L1_2)
    return
  end
  L0_2 = TriggerServerEvent
  L1_2 = "apex_loading:server:RequestDesign"
  L0_2(L1_2)
end
L19_1 = Config
L19_1 = L19_1.Creator
if L19_1 then
  L19_1 = RegisterCommand
  L20_1 = Config
  L20_1 = L20_1.Creator
  L20_1 = L20_1.command
  if not L20_1 then
    L20_1 = "loadingcreator"
  end
  L21_1 = L18_1
  L22_1 = false
  L19_1(L20_1, L21_1, L22_1)
  L19_1 = Config
  L19_1 = L19_1.Creator
  L19_1 = L19_1.aliasCommand
  if L19_1 then
    L19_1 = RegisterCommand
    L20_1 = Config
    L20_1 = L20_1.Creator
    L20_1 = L20_1.aliasCommand
    L21_1 = L18_1
    L22_1 = false
    L19_1(L20_1, L21_1, L22_1)
  end
end
L19_1 = RegisterNUICallback
L20_1 = "closeCreator"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = false
  L1_1 = L2_2
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "save"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = L1_1
  if L2_2 then
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = type
      L3_2 = A0_2.json
      L2_2 = L2_2(L3_2)
      if "string" == L2_2 then
        L2_2 = A0_2.json
        L2_2 = #L2_2
        if L2_2 > 1 then
          L2_2 = L16_1
          L3_2 = "design"
          L4_2 = "legacy_%d"
          L5_2 = L4_2
          L4_2 = L4_2.format
          L6_2 = GetGameTimer
          L6_2 = L6_2()
          L4_2 = L4_2(L5_2, L6_2)
          L5_2 = A0_2.json
          L6_2 = {}
          L2_2(L3_2, L4_2, L5_2, L6_2)
        end
      end
    end
  end
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "apex_loading:client:Saved"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = L4_1
  L2_2 = "saved"
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = {}
  end
  L1_2(L2_2, L3_2)
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" == L1_2 then
    L1_2 = A0_2.ok
    if true ~= L1_2 then
      L1_2 = print
      L2_2 = "^3[apex_loading]^0 the design was NOT saved: "
      L3_2 = tostring
      L4_2 = A0_2.note
      if not L4_2 then
        L4_2 = "unknown reason"
      end
      L3_2 = L3_2(L4_2)
      L2_2 = L2_2 .. L3_2
      L1_2(L2_2)
      L1_2 = L1_1
      if not L1_2 then
        L1_2 = L5_1
        L2_2 = "The design was NOT saved: "
        L3_2 = tostring
        L4_2 = A0_2.note
        L3_2 = L3_2(L4_2)
        L2_2 = L2_2 .. L3_2
        L3_2 = true
        L1_2(L2_2, L3_2)
      end
  end
  else
    L1_2 = L1_1
    if not L1_2 then
      L1_2 = L5_1
      L2_2 = GetLocales
      L2_2 = L2_2()
      L2_2 = L2_2.cr_saved
      if not L2_2 then
        L2_2 = "Published."
      end
      L1_2(L2_2)
    end
  end
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "mediaList"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = L1_1
  if L2_2 then
    L2_2 = TriggerServerEvent
    L3_2 = "apex_loading:server:MediaList"
    L2_2(L3_2)
  end
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "mediaDelete"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = L1_1
  if L2_2 then
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = type
      L3_2 = A0_2.name
      L2_2 = L2_2(L3_2)
      if "string" == L2_2 then
        L2_2 = TriggerServerEvent
        L3_2 = "apex_loading:server:MediaDelete"
        L4_2 = A0_2.name
        L2_2(L3_2, L4_2)
      end
    end
  end
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "apex_loading:client:MediaDone"
function L21_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = SendNUIMessage
  L4_2 = {}
  L4_2.action = "mediaDone"
  L5_2 = {}
  L5_2.ok = A0_2
  L5_2.name = A1_2
  L5_2.size = A2_2
  L4_2.data = L5_2
  L3_2(L4_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "apex_loading:client:MediaList"
function L21_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "mediaList"
  L3_2 = {}
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = {}
  end
  L3_2.files = L4_2
  L2_2.data = L3_2
  L1_2(L2_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNUICallback
L20_1 = "aiAsk"
function L21_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2
  L3_2 = "ok"
  L2_2(L3_2)
  L2_2 = L1_1
  if L2_2 then
    L2_2 = type
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      goto lbl_13
    end
  end
  do return end
  ::lbl_13::
  L2_2 = type
  L3_2 = A0_2.id
  L2_2 = L2_2(L3_2)
  if "string" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.system
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = type
      L3_2 = A0_2.user
      L2_2 = L2_2(L3_2)
      if "string" == L2_2 then
        goto lbl_29
      end
    end
  end
  do return end
  ::lbl_29::
  L2_2 = TriggerServerEvent
  L3_2 = "apex_loading:server:AiAsk"
  L4_2 = A0_2.id
  L5_2 = A0_2.system
  L6_2 = A0_2.user
  L2_2(L3_2, L4_2, L5_2, L6_2)
end
L19_1(L20_1, L21_1)
L19_1 = RegisterNetEvent
L20_1 = "apex_loading:client:AiReply"
function L21_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "aiReply"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L19_1(L20_1, L21_1)
