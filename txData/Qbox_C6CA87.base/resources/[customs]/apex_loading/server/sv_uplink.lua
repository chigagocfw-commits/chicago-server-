local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1
L0_1 = {}
Uplink = L0_1
L0_1 = {}
L1_1 = {}
L2_1 = Uplink
L2_1.last = nil
L2_1 = 16000
function L3_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = pcall
  L3_2 = GetConvar
  L4_2 = A0_2
  L5_2 = ""
  L2_2, L3_2 = L2_2(L3_2, L4_2, L5_2)
  if L2_2 then
    L4_2 = tonumber
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      goto lbl_14
    end
  end
  L4_2 = nil
  ::lbl_14::
  if not L4_2 or L4_2 <= 0 then
    return A1_2
  end
  return L4_2
end
L4_1 = Uplink
function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = L3_1
  L1_2 = "rateLimiter_netEventSize_rate"
  L2_2 = 131072
  L0_2 = L0_2(L1_2, L2_2)
  L1_2 = L3_1
  L2_2 = "rateLimiter_netEventSize_burst"
  L3_2 = 393216
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = L3_1
  L3_2 = "rateLimiter_netEvent_rate"
  L4_2 = 50
  L2_2 = L2_2(L3_2, L4_2)
  L3_2 = {}
  L4_2 = L2_1
  L3_2.part = L4_2
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = math
  L5_2 = L5_2.max
  L6_2 = 16384
  L7_2 = math
  L7_2 = L7_2.min
  L8_2 = L0_2 * 0.7
  L9_2 = 4194304
  L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2.rate = L4_2
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = math
  L5_2 = L5_2.max
  L6_2 = L2_1
  L6_2 = L6_2 * 2
  L7_2 = math
  L7_2 = L7_2.min
  L8_2 = L1_2 * 0.5
  L9_2 = 8388608
  L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2.burst = L4_2
  L4_2 = math
  L4_2 = L4_2.floor
  L5_2 = math
  L5_2 = L5_2.max
  L6_2 = 2
  L7_2 = math
  L7_2 = L7_2.min
  L8_2 = L2_2 * 0.4
  L9_2 = 20
  L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
  L5_2, L6_2, L7_2, L8_2, L9_2 = L5_2(L6_2, L7_2, L8_2, L9_2)
  L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
  L3_2.perSecond = L4_2
  L3_2.serverRate = L0_2
  L3_2.serverBurst = L1_2
  return L3_2
end
L4_1.Limits = L5_1
L4_1 = Uplink
function L5_1(A0_2, A1_2)
  local L2_2
  L2_2 = L0_1
  L2_2[A0_2] = A1_2
end
L4_1.Register = L5_1
function L4_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetPlayerName
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if not L1_2 then
    L1_2 = "player "
    L2_2 = tostring
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    L1_2 = L1_2 .. L2_2
  end
  return L1_2
end
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = TriggerClientEvent
  L4_2 = "apex_loading:client:UpFail"
  L5_2 = A0_2
  L6_2 = A1_2
  L7_2 = A2_2
  L3_2(L4_2, L5_2, L6_2, L7_2)
end
function L6_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Uplink
  L4_2 = {}
  L5_2 = A0_2.kind
  L4_2.kind = L5_2
  L5_2 = L4_1
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  L4_2.who = L5_2
  L5_2 = os
  L5_2 = L5_2.time
  L5_2 = L5_2()
  L4_2.at = L5_2
  L5_2 = A0_2.total
  L4_2.parts = L5_2
  L5_2 = A0_2.got
  L4_2.got = L5_2
  L5_2 = A0_2.bytes
  L4_2.bytes = L5_2
  L4_2.result = A2_2
  L3_2.last = L4_2
end
L7_1 = AddEventHandler
L8_1 = "playerDropped"
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = source
  L1_2 = L1_1
  L1_2 = L1_2[L0_2]
  if L1_2 then
    L2_2 = L6_1
    L3_2 = L1_2
    L4_2 = L0_2
    L5_2 = "the player left before it finished"
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = L1_1
    L2_2[L0_2] = nil
  end
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "apex_loading:server:UpBegin"
function L9_1(A0_2, A1_2, A2_2, A3_2, A4_2)
  local L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
  L5_2 = source
  L6_2 = type
  L7_2 = A1_2
  L6_2 = L6_2(L7_2)
  if "string" == L6_2 then
    L6_2 = #A1_2
    if not (L6_2 < 1) then
      L6_2 = #A1_2
      if not (L6_2 > 64) then
        goto lbl_14
      end
    end
  end
  do return end
  ::lbl_14::
  L6_2 = L0_1
  L6_2 = L6_2[A0_2]
  if not L6_2 then
    L7_2 = L5_1
    L8_2 = L5_2
    L9_2 = A1_2
    L10_2 = "unknown upload type"
    L7_2(L8_2, L9_2, L10_2)
    return
  end
  L7_2 = tonumber
  L8_2 = A2_2
  L7_2 = L7_2(L8_2)
  L8_2 = tonumber
  L9_2 = A3_2
  L8_2 = L8_2(L9_2)
  A3_2 = L8_2
  A2_2 = L7_2
  if A2_2 and A3_2 and not (A2_2 < 1) and not (A3_2 < 1) then
    L7_2 = math
    L7_2 = L7_2.floor
    L8_2 = A2_2
    L7_2 = L7_2(L8_2)
    if A2_2 == L7_2 then
      L7_2 = math
      L7_2 = L7_2.ceil
      L8_2 = L6_2.maxBytes
      L8_2 = L8_2 / 1000
      L7_2 = L7_2(L8_2)
      if not (A2_2 > L7_2) then
        goto lbl_60
      end
    end
  end
  L7_2 = L5_1
  L8_2 = L5_2
  L9_2 = A1_2
  L10_2 = "the upload request was malformed"
  L7_2(L8_2, L9_2, L10_2)
  do return end
  ::lbl_60::
  L7_2 = L6_2.maxBytes
  if A3_2 > L7_2 then
    L7_2 = L5_1
    L8_2 = L5_2
    L9_2 = A1_2
    L10_2 = "it is %.1f MB, the limit is %.0f MB"
    L11_2 = L10_2
    L10_2 = L10_2.format
    L12_2 = A3_2 / 1048576
    L13_2 = L6_2.maxBytes
    L13_2 = L13_2 / 1048576
    L10_2, L11_2, L12_2, L13_2 = L10_2(L11_2, L12_2, L13_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    return
  end
  L7_2 = Access
  L7_2 = L7_2.Check
  L8_2 = L5_2
  L9_2 = "creator"
  L7_2 = L7_2(L8_2, L9_2)
  if not L7_2 then
    L7_2 = print
    L8_2 = "^3[apex_loading]^0 blocked an upload from %s (%s), no access"
    L9_2 = L8_2
    L8_2 = L8_2.format
    L10_2 = L4_1
    L11_2 = L5_2
    L10_2 = L10_2(L11_2)
    L11_2 = L5_2
    L8_2, L9_2, L10_2, L11_2, L12_2, L13_2 = L8_2(L9_2, L10_2, L11_2)
    L7_2(L8_2, L9_2, L10_2, L11_2, L12_2, L13_2)
    L7_2 = L5_1
    L8_2 = L5_2
    L9_2 = A1_2
    L10_2 = "you do not have access to publish"
    L7_2(L8_2, L9_2, L10_2)
    return
  end
  L7_2 = type
  L8_2 = A4_2
  L7_2 = L7_2(L8_2)
  if "table" ~= L7_2 then
    L7_2 = {}
    A4_2 = L7_2
  end
  L7_2 = L6_2.begin
  if L7_2 then
    L7_2 = L6_2.begin
    L8_2 = L5_2
    L9_2 = A4_2
    L7_2, L8_2 = L7_2(L8_2, L9_2)
    if not L7_2 then
      L9_2 = L5_1
      L10_2 = L5_2
      L11_2 = A1_2
      L12_2 = L8_2 or L12_2
      if not L8_2 then
        L12_2 = "refused"
      end
      L9_2(L10_2, L11_2, L12_2)
      return
    end
  end
  L7_2 = L1_1
  L7_2 = L7_2[L5_2]
  if L7_2 then
    L8_2 = L6_1
    L9_2 = L7_2
    L10_2 = L5_2
    L11_2 = "replaced by a newer upload"
    L8_2(L9_2, L10_2, L11_2)
  end
  L8_2 = L1_1
  L9_2 = {}
  L9_2.kind = A0_2
  L9_2.id = A1_2
  L9_2.total = A2_2
  L9_2.bytes = A3_2
  L9_2.meta = A4_2
  L10_2 = {}
  L9_2.parts = L10_2
  L9_2.got = 0
  L9_2.recv = 0
  L10_2 = os
  L10_2 = L10_2.time
  L10_2 = L10_2()
  L9_2.touched = L10_2
  L8_2[L5_2] = L9_2
  L8_2 = TriggerClientEvent
  L9_2 = "apex_loading:client:UpAck"
  L10_2 = L5_2
  L11_2 = A1_2
  L12_2 = 0
  L8_2(L9_2, L10_2, L11_2, L12_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNetEvent
L8_1 = "apex_loading:server:UpPart"
function L9_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L3_2 = source
  L4_2 = L1_1
  L4_2 = L4_2[L3_2]
  if L4_2 then
    L5_2 = L4_2.id
    if L5_2 == A0_2 then
      goto lbl_23
    end
  end
  L5_2 = type
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if "string" == L5_2 then
    L5_2 = #A0_2
    if L5_2 <= 64 then
      L5_2 = L5_1
      L6_2 = L3_2
      L7_2 = A0_2
      L8_2 = "the server lost this upload, publish again"
      L5_2(L6_2, L7_2, L8_2)
    end
  end
  do return end
  ::lbl_23::
  L5_2 = tonumber
  L6_2 = A1_2
  L5_2 = L5_2(L6_2)
  A1_2 = L5_2
  L5_2 = type
  L6_2 = A2_2
  L5_2 = L5_2(L6_2)
  if "string" == L5_2 and A1_2 and not (A1_2 < 1) then
    L5_2 = L4_2.total
    if not (A1_2 > L5_2) then
      L5_2 = math
      L5_2 = L5_2.floor
      L6_2 = A1_2
      L5_2 = L5_2(L6_2)
      if A1_2 == L5_2 then
        goto lbl_58
      end
    end
  end
  L5_2 = L1_1
  L5_2[L3_2] = nil
  L5_2 = L6_1
  L6_2 = L4_2
  L7_2 = L3_2
  L8_2 = "a malformed part arrived"
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = L5_1
  L6_2 = L3_2
  L7_2 = A0_2
  L8_2 = "a part arrived malformed, publish again"
  L5_2(L6_2, L7_2, L8_2)
  do return end
  ::lbl_58::
  L5_2 = L4_2.parts
  L5_2 = L5_2[A1_2]
  if L5_2 then
    return
  end
  L5_2 = L4_2.recv
  L6_2 = #A2_2
  L5_2 = L5_2 + L6_2
  L4_2.recv = L5_2
  L5_2 = L4_2.recv
  L6_2 = L4_2.bytes
  if L5_2 > L6_2 then
    L5_2 = L1_1
    L5_2[L3_2] = nil
    L5_2 = L6_1
    L6_2 = L4_2
    L7_2 = L3_2
    L8_2 = "more data arrived than was announced"
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L5_1
    L6_2 = L3_2
    L7_2 = A0_2
    L8_2 = "more data arrived than was announced, publish again"
    L5_2(L6_2, L7_2, L8_2)
    return
  end
  L5_2 = A2_2
  L7_2 = L4_2.kind
  L6_2 = L0_1
  L6_2 = L6_2[L7_2]
  L6_2 = L6_2.part
  if L6_2 then
    L6_2 = pcall
    L8_2 = L4_2.kind
    L7_2 = L0_1
    L7_2 = L7_2[L8_2]
    L7_2 = L7_2.part
    L8_2 = L4_2
    L9_2 = A2_2
    L10_2 = A1_2
    L6_2, L7_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
    if L6_2 then
      L8_2 = type
      L9_2 = L7_2
      L8_2 = L8_2(L9_2)
      if "string" == L8_2 then
        goto lbl_121
      end
    end
    L8_2 = L1_1
    L8_2[L3_2] = nil
    L8_2 = L6_1
    L9_2 = L4_2
    L10_2 = L3_2
    L11_2 = "a part could not be read"
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = L5_1
    L9_2 = L3_2
    L10_2 = A0_2
    L11_2 = "a part could not be read, publish again"
    L8_2(L9_2, L10_2, L11_2)
    do return end
    ::lbl_121::
    L5_2 = L7_2
  end
  L6_2 = L4_2.parts
  L6_2[A1_2] = L5_2
  L6_2 = L4_2.got
  L6_2 = L6_2 + 1
  L4_2.got = L6_2
  L6_2 = os
  L6_2 = L6_2.time
  L6_2 = L6_2()
  L4_2.touched = L6_2
  L6_2 = TriggerClientEvent
  L7_2 = "apex_loading:client:UpAck"
  L8_2 = L3_2
  L9_2 = A0_2
  L10_2 = A1_2
  L6_2(L7_2, L8_2, L9_2, L10_2)
  L6_2 = L4_2.got
  L7_2 = L4_2.total
  if L6_2 < L7_2 then
    return
  end
  L6_2 = L1_1
  L6_2[L3_2] = nil
  L6_2 = L4_2.recv
  L7_2 = L4_2.bytes
  if L6_2 ~= L7_2 then
    L6_2 = L6_1
    L7_2 = L4_2
    L8_2 = L3_2
    L9_2 = "arrived incomplete (%d of %d bytes)"
    L10_2 = L9_2
    L9_2 = L9_2.format
    L11_2 = L4_2.recv
    L12_2 = L4_2.bytes
    L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L9_2(L10_2, L11_2, L12_2)
    L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L6_2 = L5_1
    L7_2 = L3_2
    L8_2 = A0_2
    L9_2 = "it arrived incomplete, publish again"
    L6_2(L7_2, L8_2, L9_2)
    return
  end
  L6_2 = table
  L6_2 = L6_2.concat
  L7_2 = L4_2.parts
  L8_2 = ""
  L9_2 = 1
  L10_2 = L4_2.total
  L6_2 = L6_2(L7_2, L8_2, L9_2, L10_2)
  L4_2.parts = nil
  L7_2 = pcall
  L9_2 = L4_2.kind
  L8_2 = L0_1
  L8_2 = L8_2[L9_2]
  L8_2 = L8_2.done
  L9_2 = L3_2
  L10_2 = L6_2
  L11_2 = L4_2
  L7_2, L8_2 = L7_2(L8_2, L9_2, L10_2, L11_2)
  if not L7_2 then
    L9_2 = print
    L10_2 = "^1[apex_loading]^0 finishing the %s upload from %s failed: %s"
    L11_2 = L10_2
    L10_2 = L10_2.format
    L12_2 = L4_2.kind
    L13_2 = L4_1
    L14_2 = L3_2
    L13_2 = L13_2(L14_2)
    L14_2 = tostring
    L15_2 = L8_2
    L14_2, L15_2, L16_2 = L14_2(L15_2)
    L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L9_2(L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    L9_2 = L6_1
    L10_2 = L4_2
    L11_2 = L3_2
    L12_2 = "failed on the server: "
    L13_2 = tostring
    L14_2 = L8_2
    L13_2 = L13_2(L14_2)
    L12_2 = L12_2 .. L13_2
    L9_2(L10_2, L11_2, L12_2)
    L9_2 = L5_1
    L10_2 = L3_2
    L11_2 = A0_2
    L12_2 = "the server failed while storing it: "
    L13_2 = tostring
    L14_2 = L8_2
    L13_2 = L13_2(L14_2)
    L14_2 = L13_2
    L13_2 = L13_2.sub
    L15_2 = 1
    L16_2 = 160
    L13_2 = L13_2(L14_2, L15_2, L16_2)
    L12_2 = L12_2 .. L13_2
    L9_2(L10_2, L11_2, L12_2)
    return
  end
  L9_2 = L4_2.noted
  if not L9_2 then
    L9_2 = L6_1
    L10_2 = L4_2
    L11_2 = L3_2
    L12_2 = "received"
    L9_2(L10_2, L11_2, L12_2)
  end
end
L7_1(L8_1, L9_1)
L7_1 = Uplink
function L8_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  A1_2.noted = true
  L3_2 = L6_1
  L4_2 = A1_2
  L5_2 = A0_2
  L6_2 = A2_2
  L3_2(L4_2, L5_2, L6_2)
end
L7_1.Result = L8_1
L7_1 = CreateThread
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  while true do
    L0_2 = Wait
    L1_2 = 60000
    L0_2(L1_2)
    L0_2 = os
    L0_2 = L0_2.time
    L0_2 = L0_2()
    L1_2 = pairs
    L2_2 = L1_1
    L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
    for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
      L7_2 = L6_2.touched
      if not L7_2 then
        L7_2 = 0
      end
      L7_2 = L0_2 - L7_2
      if L7_2 > 120 then
        L7_2 = L6_1
        L8_2 = L6_2
        L9_2 = L5_2
        L10_2 = "abandoned half way"
        L7_2(L8_2, L9_2, L10_2)
        L7_2 = L1_1
        L7_2[L5_2] = nil
      end
    end
  end
end
L7_1(L8_1)
L7_1 = {}
Downlink = L7_1
L7_1 = 60000
L8_1 = 0
L9_1 = Downlink
function L10_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = L8_1
  L2_2 = L2_2 + 1
  L8_1 = L2_2
  L2_2 = "d%d_%d"
  L3_2 = L2_2
  L2_2 = L2_2.format
  L4_2 = L8_1
  L5_2 = os
  L5_2 = L5_2.time
  L5_2, L6_2, L7_2 = L5_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L3_2 = math
  L3_2 = L3_2.max
  L4_2 = 1
  L5_2 = math
  L5_2 = L5_2.ceil
  L6_2 = #A1_2
  L7_2 = L7_1
  L6_2 = L6_2 / L7_2
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L3_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L4_2 = CreateThread
  function L5_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
    L0_3 = Wait
    L1_3 = 0
    L0_3(L1_3)
    L0_3 = 1
    L1_3 = L3_2
    L2_3 = 1
    for L3_3 = L0_3, L1_3, L2_3 do
      L4_3 = GetPlayerName
      L5_3 = A0_2
      L4_3 = L4_3(L5_3)
      if not L4_3 then
        return
      end
      L4_3 = TriggerClientEvent
      L5_3 = "apex_loading:client:DownPart"
      L6_3 = A0_2
      L7_3 = L2_2
      L8_3 = L3_3
      L9_3 = A1_2
      L10_3 = L9_3
      L9_3 = L9_3.sub
      L11_3 = L3_3 - 1
      L12_3 = L7_1
      L11_3 = L11_3 * L12_3
      L11_3 = L11_3 + 1
      L12_3 = L7_1
      L12_3 = L3_3 * L12_3
      L9_3, L10_3, L11_3, L12_3 = L9_3(L10_3, L11_3, L12_3)
      L4_3(L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
      L4_3 = Wait
      L5_3 = 40
      L4_3(L5_3)
    end
  end
  L4_2(L5_2)
  L4_2 = {}
  L4_2.id = L2_2
  L4_2.parts = L3_2
  L5_2 = #A1_2
  L4_2.bytes = L5_2
  return L4_2
end
L9_1.Send = L10_1
L9_1 = Downlink
L9_1.PART = L7_1
