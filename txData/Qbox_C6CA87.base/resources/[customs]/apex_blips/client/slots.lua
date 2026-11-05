local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1
L0_1 = {}
Slots = L0_1
L0_1 = nil
L1_1 = nil
L2_1 = {}
L2_1.duiObj = nil
L2_1.created = false
L2_1.replaced = false
L2_1.replacing = false
L2_1.txn = "sheet"
L3_1 = {}
L4_1 = {}
L5_1 = nil
function L6_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Config
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.debug
    if L1_2 then
      L1_2 = print
      L2_2 = "^5[apex_blips]^7 [slots] "
      L3_2 = A0_2
      L2_2 = L2_2 .. L3_2
      L1_2(L2_2)
    end
  end
end
function L7_1()
  local L0_2, L1_2
  L0_2 = Config
  L0_2 = L0_2.engine
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.engine
    L0_2 = L0_2.sheet
    if L0_2 then
      goto lbl_15
    end
  end
  L0_2 = {}
  L0_2.texture = "blips_texturesheet_ng_2"
  L0_2.size = 1024
  L0_2.cell = 64
  ::lbl_15::
  return L0_2
end
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = {}
  L3_1 = L0_2
  L0_2 = Config
  L0_2 = L0_2.engine
  if L0_2 then
    L0_2 = Config
    L0_2 = L0_2.engine
    L0_2 = L0_2.slots
    if L0_2 then
      goto lbl_15
    end
  end
  L0_2 = {}
  ::lbl_15::
  L1_2 = 1
  L2_2 = #L0_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L0_2[L4_2]
    L6_2 = type
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    if "table" == L6_2 then
      L6_2 = tonumber
      L7_2 = L5_2.sprite
      L6_2 = L6_2(L7_2)
      if L6_2 then
        L6_2 = type
        L7_2 = L5_2.cell
        L6_2 = L6_2(L7_2)
        if "table" == L6_2 then
          L6_2 = L3_1
          L6_2 = #L6_2
          L7_2 = L6_2 + 1
          L6_2 = L3_1
          L8_2 = {}
          L9_2 = math
          L9_2 = L9_2.floor
          L10_2 = tonumber
          L11_2 = L5_2.sprite
          L10_2, L11_2 = L10_2(L11_2)
          L9_2 = L9_2(L10_2, L11_2)
          L8_2.sprite = L9_2
          L9_2 = {}
          L10_2 = tonumber
          L11_2 = L5_2.cell
          L11_2 = L11_2.x
          L10_2 = L10_2(L11_2)
          if not L10_2 then
            L10_2 = 0
          end
          L9_2.x = L10_2
          L10_2 = tonumber
          L11_2 = L5_2.cell
          L11_2 = L11_2.y
          L10_2 = L10_2(L11_2)
          if not L10_2 then
            L10_2 = 0
          end
          L9_2.y = L10_2
          L8_2.cell = L9_2
          L8_2.imgId = nil
          L8_2.srcData = nil
          L8_2.payload = nil
          L6_2[L7_2] = L8_2
        end
      end
    end
  end
end
L9_1 = L8_1
L9_1()
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L0_2 = L1_1
  if nil ~= L0_2 then
    L0_2 = L1_1
    L0_2 = false ~= L0_2
    return L0_2
  end
  L0_2 = 1
  L1_2 = 3
  L2_2 = 1
  for L3_2 = L0_2, L1_2, L2_2 do
    L4_2 = "apxblips_%d_%d"
    L5_2 = L4_2
    L4_2 = L4_2.format
    L6_2 = GetGameTimer
    L6_2 = L6_2()
    L7_2 = math
    L7_2 = L7_2.random
    L8_2 = 1000
    L9_2 = 9999
    L7_2, L8_2, L9_2 = L7_2(L8_2, L9_2)
    L4_2 = L4_2(L5_2, L6_2, L7_2, L8_2, L9_2)
    L5_2 = CreateRuntimeTxd
    L6_2 = L4_2
    L5_2 = L5_2(L6_2)
    if nil ~= L5_2 and 0 ~= L5_2 then
      L6_2 = L4_2
      L1_1 = L5_2
      L0_1 = L6_2
      L6_2 = true
      return L6_2
    end
  end
  L0_2 = false
  L1_1 = L0_2
  L0_2 = print
  L1_2 = "^1[apex_blips]^7 CreateRuntimeTxd failed three times \226\128\148 image blips disabled this session."
  L0_2(L1_2)
  L0_2 = false
  return L0_2
end
L10_1 = false
function L11_1()
  local L0_2, L1_2, L2_2
  L0_2 = Config
  L0_2 = L0_2.engine
  L0_2 = L0_2.radarPoke
  if false == L0_2 then
    return
  end
  L0_2 = L10_1
  if L0_2 then
    return
  end
  L0_2 = true
  L10_1 = L0_2
  L0_2 = SetTimeout
  L1_2 = 600
  function L2_2()
    local L0_3, L1_3
    L0_3 = false
    L10_1 = L0_3
    L0_3 = CreateThread
    function L1_3()
      local L0_4, L1_4, L2_4
      L0_4 = SetBigmapActive
      L1_4 = true
      L2_4 = false
      L0_4(L1_4, L2_4)
      L0_4 = Wait
      L1_4 = 50
      L0_4(L1_4)
      L0_4 = SetBigmapActive
      L1_4 = false
      L2_4 = false
      L0_4(L1_4, L2_4)
    end
    L0_3(L1_3)
  end
  L0_2(L1_2, L2_2)
end
function L12_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = L2_1.created
  if L0_2 then
    L0_2 = true
    return L0_2
  end
  L0_2 = L9_1
  L0_2 = L0_2()
  if not L0_2 then
    L0_2 = false
    return L0_2
  end
  L0_2 = L7_1
  L0_2 = L0_2()
  L0_2 = L0_2.size
  if not L0_2 then
    L0_2 = 1024
  end
  L1_2 = "nui://%s/html/dui.html?v=4"
  L2_2 = L1_2
  L1_2 = L1_2.format
  L3_2 = GetCurrentResourceName
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2()
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = CreateDui
  L3_2 = L1_2
  L4_2 = L0_2
  L5_2 = L0_2
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L2_1.duiObj = L2_2
  L2_2 = L2_1.duiObj
  if nil == L2_2 then
    L2_2 = print
    L3_2 = "^1[apex_blips]^7 CreateDui failed \226\128\148 image blips unavailable."
    L2_2(L3_2)
    L2_2 = false
    return L2_2
  end
  L2_2 = CreateRuntimeTextureFromDuiHandle
  L3_2 = L1_1
  L4_2 = L2_1.txn
  L5_2 = GetDuiHandle
  L6_2 = L2_1.duiObj
  L5_2, L6_2, L7_2 = L5_2(L6_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_1.created = true
  L2_2 = L6_1
  L3_2 = "sheet surface up (%s/%s -> %s)"
  L4_2 = L3_2
  L3_2 = L3_2.format
  L5_2 = L0_1
  L6_2 = L2_1.txn
  L7_2 = L7_1
  L7_2 = L7_2()
  L7_2 = L7_2.texture
  L3_2, L4_2, L5_2, L6_2, L7_2 = L3_2(L4_2, L5_2, L6_2, L7_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = true
  return L2_2
end
function L13_1()
  local L0_2, L1_2
  L0_2 = L2_1.replaced
  if not L0_2 then
    L0_2 = L2_1.replacing
    if not L0_2 then
      goto lbl_8
    end
  end
  do return end
  ::lbl_8::
  L2_1.replacing = true
  L0_2 = CreateThread
  function L1_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3
    L0_3 = GetGameTimer
    L0_3 = L0_3()
    while true do
      L1_3 = IsDuiAvailable
      L2_3 = L2_1.duiObj
      L1_3 = L1_3(L2_3)
      if L1_3 then
        break
      end
      L1_3 = GetGameTimer
      L1_3 = L1_3()
      L1_3 = L1_3 - L0_3
      L2_3 = 10000
      if not (L1_3 < L2_3) then
        break
      end
      L1_3 = Wait
      L2_3 = 50
      L1_3(L2_3)
    end
    L1_3 = Wait
    L2_3 = Config
    L2_3 = L2_3.engine
    L2_3 = L2_3.baseDelayMs
    if not L2_3 then
      L2_3 = 1200
    end
    L1_3(L2_3)
    L1_3 = false
    L2_3 = 1
    L3_3 = L3_1
    L3_3 = #L3_3
    L4_3 = 1
    for L5_3 = L2_3, L3_3, L4_3 do
      L6_3 = L3_1
      L6_3 = L6_3[L5_3]
      L6_3 = L6_3.imgId
      if nil ~= L6_3 then
        L1_3 = true
        break
      end
    end
    if L1_3 then
      L2_3 = L2_1.created
      if L2_3 then
        L2_3 = AddReplaceTexture
        L3_3 = Config
        L3_3 = L3_3.engine
        L3_3 = L3_3.dict
        L4_3 = L7_1
        L4_3 = L4_3()
        L4_3 = L4_3.texture
        L5_3 = L0_1
        L6_3 = L2_1.txn
        L2_3(L3_3, L4_3, L5_3, L6_3)
        L2_1.replaced = true
        L2_3 = L11_1
        L2_3()
        L2_3 = L6_1
        L3_3 = "sheet replaced live"
        L2_3(L3_3)
      end
    end
    L2_1.replacing = false
  end
  L0_2(L1_2)
end
function L14_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = L2_1.replaced
  if not L0_2 then
    return
  end
  L0_2 = 1
  L1_2 = L3_1
  L1_2 = #L1_2
  L2_2 = 1
  for L3_2 = L0_2, L1_2, L2_2 do
    L4_2 = L3_1
    L4_2 = L4_2[L3_2]
    L4_2 = L4_2.imgId
    if nil ~= L4_2 then
      return
    end
  end
  L0_2 = RemoveReplaceTexture
  L1_2 = Config
  L1_2 = L1_2.engine
  L1_2 = L1_2.dict
  L2_2 = L7_1
  L2_2 = L2_2()
  L2_2 = L2_2.texture
  L0_2(L1_2, L2_2)
  L2_1.replaced = false
  L0_2 = L11_1
  L0_2()
  L0_2 = L6_1
  L1_2 = "vanilla sheet restored"
  L0_2(L1_2)
end
function L15_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = CreateThread
  function L3_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3
    L0_3 = GetGameTimer
    L0_3 = L0_3()
    while true do
      L1_3 = A0_2.imgId
      L2_3 = A1_2
      if L1_3 ~= L2_3 then
        break
      end
      L1_3 = IsDuiAvailable
      L2_3 = L2_1.duiObj
      L1_3 = L1_3(L2_3)
      if L1_3 then
        break
      end
      L1_3 = GetGameTimer
      L1_3 = L1_3()
      L1_3 = L1_3 - L0_3
      L2_3 = 10000
      if L1_3 > L2_3 then
        return
      end
      L1_3 = Wait
      L2_3 = 50
      L1_3(L2_3)
    end
    L1_3 = GetGameTimer
    L1_3 = L1_3()
    L2_3 = Config
    L2_3 = L2_3.engine
    L2_3 = L2_3.resendMs
    if not L2_3 then
      L2_3 = 6000
    end
    L1_3 = L1_3 + L2_3
    while true do
      L2_3 = A0_2.imgId
      L3_3 = A1_2
      if L2_3 ~= L3_3 then
        break
      end
      L2_3 = A0_2.payload
      if nil == L2_3 then
        break
      end
      L2_3 = SendDuiMessage
      L3_3 = L2_1.duiObj
      L4_3 = A0_2.payload
      L2_3(L3_3, L4_3)
      L2_3 = GetGameTimer
      L2_3 = L2_3()
      if L1_3 > L2_3 then
        L2_3 = Wait
        L3_3 = Config
        L3_3 = L3_3.engine
        L3_3 = L3_3.resendEvery
        if not L3_3 then
          L3_3 = 400
        end
        L2_3(L3_3)
      else
        L2_3 = Wait
        L3_3 = Config
        L3_3 = L3_3.engine
        L3_3 = L3_3.heartbeatMs
        if not L3_3 then
          L3_3 = 2500
        end
        L2_3(L3_3)
      end
    end
  end
  L2_2(L3_2)
end
function L16_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2
  L3_2 = L7_1
  L3_2 = L3_2()
  L3_2 = L3_2.cell
  if not L3_2 then
    L3_2 = 64
  end
  L4_2 = A1_2.data
  A0_2.srcData = L4_2
  L4_2 = json
  L4_2 = L4_2.encode
  L5_2 = {}
  L6_2 = {}
  L7_2 = A0_2.sprite
  L6_2.sprite = L7_2
  L7_2 = A0_2.cell
  L7_2 = L7_2.x
  L6_2.x = L7_2
  L7_2 = A0_2.cell
  L7_2 = L7_2.y
  L6_2.y = L7_2
  L6_2.w = L3_2
  L6_2.h = L3_2
  L7_2 = A1_2.data
  L6_2.image = L7_2
  L7_2 = A2_2 or L7_2
  if "none" == A2_2 or not A2_2 then
    L7_2 = nil
  end
  L6_2.shape = L7_2
  L5_2.set = L6_2
  L4_2 = L4_2(L5_2)
  A0_2.payload = L4_2
end
L17_1 = Slots
function L18_1(A0_2)
  local L1_2
  L5_1 = A0_2
end
L17_1.OnReady = L18_1
L17_1 = Slots
function L18_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = false
  L2_2 = 1
  L3_2 = L3_1
  L3_2 = #L3_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = L3_1
    L6_2 = L6_2[L5_2]
    L7_2 = L6_2.imgId
    if nil ~= L7_2 then
      L7_2 = L6_2.imgId
      L7_2 = A0_2[L7_2]
      if nil == L7_2 then
        L7_2 = L6_1
        L8_2 = "releasing sprite "
        L9_2 = L6_2.sprite
        L10_2 = " ("
        L11_2 = tostring
        L12_2 = L6_2.imgId
        L11_2 = L11_2(L12_2)
        L12_2 = ")"
        L8_2 = L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2
        L7_2(L8_2)
        L8_2 = L6_2.imgId
        L7_2 = L4_1
        L7_2[L8_2] = nil
        L7_2 = nil
        L8_2 = nil
        L6_2.payload = nil
        L6_2.srcData = L8_2
        L6_2.imgId = L7_2
        L7_2 = L2_1.created
        if L7_2 then
          L7_2 = json
          L7_2 = L7_2.encode
          L8_2 = {}
          L9_2 = {}
          L10_2 = L6_2.sprite
          L9_2.sprite = L10_2
          L8_2.clear = L9_2
          L7_2 = L7_2(L8_2)
          L8_2 = SendDuiMessage
          L9_2 = L2_1.duiObj
          L10_2 = L7_2
          L8_2(L9_2, L10_2)
          L8_2 = SetTimeout
          L9_2 = 600
          function L10_2()
            local L0_3, L1_3, L2_3
            L0_3 = L6_2.imgId
            if nil == L0_3 then
              L0_3 = L2_1.created
              if L0_3 then
                L0_3 = SendDuiMessage
                L1_3 = L2_1.duiObj
                L2_3 = L7_2
                L0_3(L1_3, L2_3)
              end
            end
          end
          L8_2(L9_2, L10_2)
        end
        L1_2 = true
      end
    end
  end
  if L1_2 then
    L2_2 = L14_1
    L2_2()
  end
end
L17_1.Prune = L18_1
L17_1 = Slots
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = type
      L3_2 = A0_2.data
      L2_2 = L2_2(L3_2)
      if "string" == L2_2 then
        goto lbl_18
      end
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_18::
  if "rounded" ~= A1_2 and "circle" ~= A1_2 then
    A1_2 = "none"
  end
  L2_2 = A0_2.id
  L3_2 = "|"
  L4_2 = A1_2
  L2_2 = L2_2 .. L3_2 .. L4_2
  L3_2 = L4_1
  L3_2 = L3_2[L2_2]
  if nil ~= L3_2 then
    L4_2 = L3_1
    L4_2 = L4_2[L3_2]
    L5_2 = L4_2.srcData
    L6_2 = A0_2.data
    if L5_2 ~= L6_2 then
      L5_2 = L16_1
      L6_2 = L4_2
      L7_2 = A0_2
      L8_2 = A1_2
      L5_2(L6_2, L7_2, L8_2)
      L5_2 = L2_1.created
      if L5_2 then
        L5_2 = IsDuiAvailable
        L6_2 = L2_1.duiObj
        L5_2 = L5_2(L6_2)
        if L5_2 then
          L5_2 = SendDuiMessage
          L6_2 = L2_1.duiObj
          L7_2 = L4_2.payload
          L5_2(L6_2, L7_2)
        end
      end
    end
    L5_2 = L4_2.sprite
    return L5_2
  end
  L4_2 = nil
  L5_2 = 1
  L6_2 = L3_1
  L6_2 = #L6_2
  L7_2 = 1
  for L8_2 = L5_2, L6_2, L7_2 do
    L9_2 = L3_1
    L9_2 = L9_2[L8_2]
    L9_2 = L9_2.imgId
    if nil == L9_2 then
      L4_2 = L8_2
      break
    end
  end
  if nil == L4_2 then
    L5_2 = L6_1
    L6_2 = "no free image cells ("
    L7_2 = L3_1
    L7_2 = #L7_2
    L8_2 = " in config)"
    L6_2 = L6_2 .. L7_2 .. L8_2
    L5_2(L6_2)
    L5_2 = nil
    return L5_2
  end
  L5_2 = L12_1
  L5_2 = L5_2()
  if not L5_2 then
    L5_2 = nil
    return L5_2
  end
  L5_2 = L3_1
  L5_2 = L5_2[L4_2]
  L5_2.imgId = L2_2
  L6_2 = L16_1
  L7_2 = L5_2
  L8_2 = A0_2
  L9_2 = A1_2
  L6_2(L7_2, L8_2, L9_2)
  L6_2 = L4_1
  L6_2[L2_2] = L4_2
  L6_2 = L15_1
  L7_2 = L5_2
  L8_2 = L2_2
  L6_2(L7_2, L8_2)
  L6_2 = L13_1
  L6_2()
  L6_2 = L11_1
  L6_2()
  L6_2 = L6_1
  L7_2 = "image %s -> sprite %d @ %d,%d"
  L8_2 = L7_2
  L7_2 = L7_2.format
  L9_2 = L2_2
  L10_2 = L5_2.sprite
  L11_2 = L5_2.cell
  L11_2 = L11_2.x
  L12_2 = L5_2.cell
  L12_2 = L12_2.y
  L7_2, L8_2, L9_2, L10_2, L11_2, L12_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2(L7_2, L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_2 = L5_2.sprite
  return L6_2
end
L17_1.SpriteFor = L18_1
L17_1 = Slots
function L18_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = 0
  L1_2 = 1
  L2_2 = L3_1
  L2_2 = #L2_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = L3_1
    L5_2 = L5_2[L4_2]
    L5_2 = L5_2.imgId
    if nil ~= L5_2 then
      L0_2 = L0_2 + 1
    end
  end
  L1_2 = L0_2
  L2_2 = L3_1
  L2_2 = #L2_2
  return L1_2, L2_2
end
L17_1.Stats = L18_1
L17_1 = Slots
function L18_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = {}
  L1_2 = 1
  L2_2 = L3_1
  L2_2 = #L2_2
  L3_2 = 1
  for L4_2 = L1_2, L2_2, L3_2 do
    L5_2 = #L0_2
    L5_2 = L5_2 + 1
    L6_2 = L3_1
    L6_2 = L6_2[L4_2]
    L6_2 = L6_2.sprite
    L0_2[L5_2] = L6_2
  end
  return L0_2
end
L17_1.HijackedSprites = L18_1
L17_1 = RegisterCommand
L18_1 = "blipsdebug"
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = print
  L1_2 = "^5[apex_blips]^7 txd=%s surface=%s dui=%s replaced=%s"
  L2_2 = L1_2
  L1_2 = L1_2.format
  L3_2 = tostring
  L4_2 = L0_1
  L3_2 = L3_2(L4_2)
  L4_2 = L2_1.created
  if L4_2 then
    L4_2 = "up"
    if L4_2 then
      goto lbl_14
    end
  end
  L4_2 = "none"
  ::lbl_14::
  L5_2 = L2_1.created
  if L5_2 then
    L5_2 = IsDuiAvailable
    L6_2 = L2_1.duiObj
    L5_2 = L5_2(L6_2)
    if L5_2 then
      L5_2 = "ready"
      if L5_2 then
        goto lbl_29
      end
    end
    L5_2 = "loading"
    if L5_2 then
      goto lbl_29
    end
  end
  L5_2 = "-"
  ::lbl_29::
  L6_2 = tostring
  L7_2 = L2_1.replaced
  L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2)
  L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L0_2(L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
  L0_2 = 1
  L1_2 = L3_1
  L1_2 = #L1_2
  L2_2 = 1
  for L3_2 = L0_2, L1_2, L2_2 do
    L4_2 = L3_1
    L4_2 = L4_2[L3_2]
    L5_2 = L4_2.imgId
    if nil ~= L5_2 then
      L5_2 = print
      L6_2 = "^5[apex_blips]^7 sprite %d @ %d,%d <- %s"
      L7_2 = L6_2
      L6_2 = L6_2.format
      L8_2 = L4_2.sprite
      L9_2 = L4_2.cell
      L9_2 = L9_2.x
      L10_2 = L4_2.cell
      L10_2 = L10_2.y
      L11_2 = L4_2.imgId
      L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L6_2(L7_2, L8_2, L9_2, L10_2, L11_2)
      L5_2(L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
    end
  end
  L0_2 = Slots
  L0_2 = L0_2.Stats
  L0_2, L1_2 = L0_2()
  L2_2 = print
  L3_2 = "^5[apex_blips]^7 %d/%d cells in use"
  L4_2 = L3_2
  L3_2 = L3_2.format
  L5_2 = L0_2
  L6_2 = L1_2
  L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2 = L3_2(L4_2, L5_2, L6_2)
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2)
end
L20_1 = false
L17_1(L18_1, L19_1, L20_1)
L17_1 = AddEventHandler
L18_1 = "onResourceStop"
function L19_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = L2_1.replaced
  if L1_2 then
    L1_2 = RemoveReplaceTexture
    L2_2 = Config
    L2_2 = L2_2.engine
    L2_2 = L2_2.dict
    L3_2 = L7_1
    L3_2 = L3_2()
    L3_2 = L3_2.texture
    L1_2(L2_2, L3_2)
  end
  L1_2 = L2_1.created
  if L1_2 then
    L1_2 = L2_1.duiObj
    if nil ~= L1_2 then
      L1_2 = DestroyDui
      L2_2 = L2_1.duiObj
      L1_2(L2_2)
    end
  end
end
L17_1(L18_1, L19_1)
