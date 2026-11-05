local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1, L16_1, L17_1, L18_1, L19_1, L20_1, L21_1, L22_1, L23_1, L24_1
L0_1 = GetCurrentResourceName
L0_1 = L0_1()
L1_1 = "apex_loading:design"
L2_1 = "apex_loading:design_meta"
L3_1 = "data/design.json"
L4_1 = 8388608
L5_1 = nil
L6_1 = {}
L6_1.kvp = false
L6_1.file = false
L6_1.savedAt = 0
L6_1.note = "nothing published yet"
function L7_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = pcall
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = A0_2
  L4_2, L5_2 = ...
  L1_2, L2_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L3_2 = print
  L4_2 = "^5[apex_loading]^0 "
  L5_2 = L2_2 or L5_2
  if not L1_2 or not L2_2 then
    L5_2 = A0_2
  end
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
end
function L8_1(A0_2, ...)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = pcall
  L2_2 = string
  L2_2 = L2_2.format
  L3_2 = A0_2
  L4_2, L5_2 = ...
  L1_2, L2_2 = L1_2(L2_2, L3_2, L4_2, L5_2)
  L3_2 = print
  L4_2 = "^3[apex_loading]^0 "
  L5_2 = L2_2 or L5_2
  if not L1_2 or not L2_2 then
    L5_2 = A0_2
  end
  L4_2 = L4_2 .. L5_2
  L3_2(L4_2)
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = 5381
  L2_2 = 1
  L3_2 = #A0_2
  L4_2 = 1
  for L5_2 = L2_2, L3_2, L4_2 do
    L6_2 = L1_2 * 31
    L7_2 = string
    L7_2 = L7_2.byte
    L8_2 = A0_2
    L9_2 = L5_2
    L7_2 = L7_2(L8_2, L9_2)
    L6_2 = L6_2 + L7_2
    L1_2 = L6_2 % 1048573
  end
  L2_2 = L1_2 * 64
  L3_2 = #A0_2
  L3_2 = L3_2 % 64
  L2_2 = L2_2 + L3_2
  return L2_2
end
function L10_1()
  local L0_2, L1_2, L2_2
  L0_2 = pcall
  L1_2 = os
  L1_2 = L1_2.time
  L0_2, L1_2 = L0_2(L1_2)
  L2_2 = L1_2 or L2_2
  if not L0_2 or not L1_2 then
    L2_2 = 0
  end
  return L2_2
end
function L11_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = pcall
  L1_2 = LoadResourceFile
  L2_2 = L0_1
  L3_2 = L3_1
  L0_2, L1_2 = L0_2(L1_2, L2_2, L3_2)
  if L0_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = #L1_2
      if not (L2_2 < 2) then
        goto lbl_18
      end
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_18::
  return L1_2
end
function L12_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = pcall
  L1_2 = GetResourceKvpString
  L2_2 = L1_1
  L0_2, L1_2 = L0_2(L1_2, L2_2)
  if L0_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = #L1_2
      if not (L2_2 < 2) then
        goto lbl_17
      end
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_17::
  return L1_2
end
function L13_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2
  L0_2 = pcall
  L1_2 = GetResourceKvpString
  L2_2 = L2_1
  L0_2, L1_2 = L0_2(L1_2, L2_2)
  if L0_2 then
    L2_2 = type
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = #L1_2
      if not (L2_2 < 2) then
        goto lbl_17
      end
    end
  end
  L2_2 = nil
  do return L2_2 end
  ::lbl_17::
  L2_2 = pcall
  L3_2 = json
  L3_2 = L3_2.decode
  L4_2 = L1_2
  L2_2, L3_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L4_2 = type
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if "table" == L4_2 then
      return L3_2
    end
  end
  L4_2 = nil
  return L4_2
end
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" == L1_2 then
    L1_2 = #A0_2
    if not (L1_2 < 2) then
      L1_2 = #A0_2
      L2_2 = L4_1
      if not (L1_2 > L2_2) then
        goto lbl_15
      end
    end
  end
  L1_2 = false
  do return L1_2 end
  ::lbl_15::
  L1_2 = pcall
  L2_2 = json
  L2_2 = L2_2.decode
  L3_2 = A0_2
  L1_2, L2_2 = L1_2(L2_2, L3_2)
  L3_2 = L1_2 or L3_2
  if L1_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    L3_2 = "table" == L3_2
  end
  return L3_2
end
function L15_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = L11_1
  L0_2 = L0_2()
  L1_2 = L12_1
  L1_2 = L1_2()
  L2_2 = L13_1
  L2_2 = L2_2()
  if L1_2 then
    L3_2 = L14_1
    L4_2 = L1_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = L8_1
      L4_2 = "the saved design in the server key-value store is not readable JSON, ignoring it"
      L3_2(L4_2)
      L1_2 = nil
    end
  end
  if L0_2 then
    L3_2 = L14_1
    L4_2 = L0_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = L8_1
      L4_2 = "%s is not readable JSON, ignoring it"
      L5_2 = L3_1
      L3_2(L4_2, L5_2)
      L0_2 = nil
    end
  end
  if L1_2 then
    L5_1 = L1_2
    L3_2 = tonumber
    L4_2 = L2_2 or L4_2
    if L2_2 then
      L4_2 = L2_2.savedAt
    end
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      L3_2 = 0
    end
    L6_1.savedAt = L3_2
    L3_2 = true
    L4_2 = nil ~= L0_2
    L6_1.file = L4_2
    L6_1.kvp = L3_2
    L6_1.note = "loaded from the server key-value store"
    if L0_2 and L0_2 ~= L1_2 then
      L3_2 = L2_2 or L3_2
      if L2_2 then
        L3_2 = tonumber
        L4_2 = L2_2.hash
        L3_2 = L3_2(L4_2)
        L4_2 = L9_1
        L5_2 = L0_2
        L4_2 = L4_2(L5_2)
        L3_2 = L3_2 == L4_2
      end
      if not L3_2 then
        L4_2 = L8_1
        L5_2 = "%s does not match the published design."
        L6_2 = L3_1
        L4_2(L5_2, L6_2)
        L4_2 = L8_1
        L5_2 = "  This is normal right after a resource update or a reinstall: the file"
        L4_2(L5_2)
        L4_2 = L8_1
        L5_2 = "  came back from the package and the published design came from the server."
        L4_2(L5_2)
        L4_2 = L8_1
        L5_2 = "  Using the PUBLISHED design. To use the file instead, run in the console:"
        L4_2(L5_2)
        L4_2 = L8_1
        L5_2 = "    loading_use_file"
        L4_2(L5_2)
      end
    end
    return
  end
  if L0_2 then
    L5_1 = L0_2
    L6_1.savedAt = 0
    L3_2 = false
    L6_1.file = true
    L6_1.kvp = L3_2
    L3_2 = "loaded from "
    L4_2 = L3_1
    L5_2 = " (nothing published on this server yet)"
    L3_2 = L3_2 .. L4_2 .. L5_2
    L6_1.note = L3_2
    return
  end
  L3_2 = nil
  L5_1 = L3_2
  L3_2 = false
  L4_2 = false
  L6_1.savedAt = 0
  L6_1.file = L4_2
  L6_1.kvp = L3_2
  L6_1.note = "no design yet, the factory one is used"
end
function L16_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = pcall
  L2_2 = SaveResourceFile
  L3_2 = L0_1
  L4_2 = L3_1
  L5_2 = A0_2
  L6_2 = -1
  L1_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
  if not L1_2 then
    L2_2 = false
    return L2_2
  end
  L2_2 = L11_1
  L2_2 = L2_2()
  L2_2 = L2_2 == A0_2
  return L2_2
end
function L17_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = pcall
  L4_2 = SetResourceKvp
  L5_2 = L1_1
  L6_2 = A0_2
  L3_2 = L3_2(L4_2, L5_2, L6_2)
  if not L3_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = L12_1
  L4_2 = L4_2()
  if L4_2 ~= A0_2 then
    L4_2 = false
    return L4_2
  end
  L4_2 = pcall
  L5_2 = SetResourceKvp
  L6_2 = L2_1
  L7_2 = json
  L7_2 = L7_2.encode
  L8_2 = {}
  L8_2.savedAt = A1_2
  L9_2 = #A0_2
  L8_2.bytes = L9_2
  if A2_2 then
    L9_2 = L9_1
    L10_2 = A0_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      goto lbl_34
    end
  end
  L9_2 = 0
  ::lbl_34::
  L8_2.hash = L9_2
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  L4_2(L5_2, L6_2, L7_2, L8_2, L9_2, L10_2)
  L4_2 = pcall
  L5_2 = FlushResourceKvp
  L4_2(L5_2)
  L4_2 = true
  return L4_2
end
function L18_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L2_2 = L14_1
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = false
    L3_2 = {}
    L3_2.kvp = false
    L3_2.file = false
    L3_2.note = "the design was not readable JSON"
    return L2_2, L3_2
  end
  L2_2 = L10_1
  L2_2 = L2_2()
  L3_2 = L16_1
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = L17_1
  L5_2 = A0_2
  L6_2 = L2_2
  L7_2 = L3_2
  L4_2 = L4_2(L5_2, L6_2, L7_2)
  L5_1 = A0_2
  L5_2 = {}
  L5_2.kvp = L4_2
  L5_2.file = L3_2
  L5_2.savedAt = L2_2
  L5_2.note = ""
  L6_1 = L5_2
  if L4_2 and L3_2 then
    L5_2 = "saved to the server key-value store and to "
    L6_2 = L3_1
    L5_2 = L5_2 .. L6_2
    L6_1.note = L5_2
  elseif L4_2 then
    L5_2 = "saved to the server key-value store. "
    L6_2 = L3_1
    L7_2 = " could not be written (a read-only resources folder does this), which is fine: the design survives restarts anyway"
    L5_2 = L5_2 .. L6_2 .. L7_2
    L6_1.note = L5_2
  elseif L3_2 then
    L5_2 = "saved to "
    L6_2 = L3_1
    L7_2 = " only. The server key-value store refused the write, so a resource update or a reinstall may put the old design back"
    L5_2 = L5_2 .. L6_2 .. L7_2
    L6_1.note = L5_2
  else
    L6_1.note = "COULD NOT BE SAVED. It is live for this session only and will be lost on the next restart"
  end
  if L4_2 or L3_2 then
    L5_2 = L7_1
    L6_2 = "%s published a new loading screen design (%.0f KB): %s"
    L7_2 = A1_2 or L7_2
    if not A1_2 then
      L7_2 = "someone"
    end
    L8_2 = #A0_2
    L8_2 = L8_2 / 1024
    L9_2 = L6_1.note
    L5_2(L6_2, L7_2, L8_2, L9_2)
  else
    L5_2 = L8_1
    L6_2 = "%s published a design but it %s"
    L7_2 = A1_2 or L7_2
    if not A1_2 then
      L7_2 = "someone"
    end
    L8_2 = L6_1.note
    L5_2(L6_2, L7_2, L8_2)
    L5_2 = L8_1
    L6_2 = "  Run  loading_diag  in the server console for the details."
    L5_2(L6_2)
  end
  if L4_2 and not L3_2 then
    L5_2 = L8_1
    L6_2 = "%s could not be written. The design is safe in the key-value store; run loading_diag for details."
    L7_2 = L3_1
    L5_2(L6_2, L7_2)
  end
  L5_2 = L4_2 or L5_2
  if not L4_2 then
    L5_2 = L3_2
  end
  L6_2 = L6_1
  return L5_2, L6_2
end
L19_1 = L15_1
L19_1()
function L19_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = GetConvar
  L1_2 = "sv_projectName"
  L2_2 = ""
  L0_2 = L0_2(L1_2, L2_2)
  if "" == L0_2 then
    L1_2 = GetConvar
    L2_2 = "sv_hostname"
    L3_2 = "FiveM Server"
    L1_2 = L1_2(L2_2, L3_2)
    L0_2 = L1_2
  end
  L2_2 = L0_2
  L1_2 = L0_2.gsub
  L3_2 = "%^%d"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = L1_2
  L1_2 = L1_2.gsub
  L3_2 = "~[%a]~"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L0_2 = L1_2
  L2_2 = L0_2
  L1_2 = L0_2.sub
  L3_2 = 1
  L4_2 = 60
  return L1_2(L2_2, L3_2, L4_2)
end
L20_1 = AddEventHandler
L21_1 = "playerConnecting"
function L22_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L3_2 = source
  L4_2 = A2_2.defer
  L4_2()
  L4_2 = Wait
  L5_2 = 0
  L4_2(L5_2)
  L4_2 = {}
  L5_2 = L5_1
  L4_2.design = L5_2
  L5_2 = GetLocales
  L5_2 = L5_2()
  L4_2.locales = L5_2
  L5_2 = YtBridgeUrl
  L5_2 = L5_2()
  L4_2.yt = L5_2
  L5_2 = Config
  L5_2 = L5_2.Handover
  L5_2 = L5_2.playerName
  if false ~= L5_2 then
    L5_2 = GetPlayerName
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L5_2 = "Player"
    end
    L6_2 = L5_2
    L5_2 = L5_2.sub
    L7_2 = 1
    L8_2 = 32
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    L4_2.name = L5_2
  end
  L5_2 = Config
  L5_2 = L5_2.Handover
  L5_2 = L5_2.playerCount
  if false ~= L5_2 then
    L5_2 = GetPlayers
    L5_2 = L5_2()
    L5_2 = #L5_2
    L4_2.players = L5_2
    L5_2 = GetConvarInt
    L6_2 = "sv_maxclients"
    L7_2 = 48
    L5_2 = L5_2(L6_2, L7_2)
    L4_2.max = L5_2
  end
  L5_2 = Config
  L5_2 = L5_2.Handover
  L5_2 = L5_2.serverName
  if false ~= L5_2 then
    L5_2 = L19_1
    L5_2 = L5_2()
    L4_2.server = L5_2
  end
  L5_2 = A2_2.handover
  L6_2 = {}
  L6_2.apexLoading = L4_2
  L5_2(L6_2)
  L5_2 = A2_2.done
  L5_2()
end
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_loading:server:RequestDesign"
function L22_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L0_2 = source
  L1_2 = Access
  L1_2 = L1_2.Check
  L2_2 = L0_2
  L3_2 = "creator"
  L1_2 = L1_2(L2_2, L3_2)
  L2_2 = {}
  L2_2.allowed = L1_2
  L3_2 = Config
  L3_2 = L3_2.AI
  if L3_2 then
    L3_2 = Config
    L3_2 = L3_2.AI
    L3_2 = L3_2.enabled
    L3_2 = AiConfigured
    L3_2 = false ~= L3_2 and L3_2
  end
  L2_2.ai = L3_2
  L3_2 = YtBridgeUrl
  L3_2 = L3_2()
  L2_2.yt = L3_2
  L3_2 = Uplink
  L3_2 = L3_2.Limits
  L3_2 = L3_2()
  L2_2.up = L3_2
  if L1_2 then
    L3_2 = L5_1
    if L3_2 then
      L3_2 = L5_1
      L3_2 = #L3_2
      L4_2 = Downlink
      L4_2 = L4_2.PART
      if L3_2 > L4_2 then
        L3_2 = Downlink
        L3_2 = L3_2.Send
        L4_2 = L0_2
        L5_2 = L5_1
        L3_2 = L3_2(L4_2, L5_2)
        L2_2.down = L3_2
      else
        L3_2 = L5_1
        L2_2.design = L3_2
      end
    end
  end
  L3_2 = TriggerClientEvent
  L4_2 = "apex_loading:client:Design"
  L5_2 = L0_2
  L6_2 = L2_2
  L3_2(L4_2, L5_2, L6_2)
end
L20_1(L21_1, L22_1)
L20_1 = Uplink
L20_1 = L20_1.Register
L21_1 = "design"
L22_1 = {}
L22_1.maxBytes = L4_1
function L23_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L3_2 = L18_1
  L4_2 = A1_2
  L5_2 = GetPlayerName
  L6_2 = A0_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = tostring
    L6_2 = A0_2
    L5_2 = L5_2(L6_2)
  end
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  L5_2 = Uplink
  L5_2 = L5_2.Result
  L6_2 = A0_2
  L7_2 = A2_2
  if L3_2 then
    L8_2 = L4_2.note
    if L8_2 then
      goto lbl_24
    end
  end
  L8_2 = "NOT saved: "
  L9_2 = L4_2.note
  L8_2 = L8_2 .. L9_2
  ::lbl_24::
  L5_2(L6_2, L7_2, L8_2)
  L5_2 = TriggerClientEvent
  L6_2 = "apex_loading:client:Saved"
  L7_2 = A0_2
  L8_2 = {}
  L8_2.ok = L3_2
  L9_2 = L4_2.note
  L8_2.note = L9_2
  L9_2 = A2_2.id
  L8_2.id = L9_2
  L5_2(L6_2, L7_2, L8_2)
end
L22_1.done = L23_1
L20_1(L21_1, L22_1)
L20_1 = RegisterNetEvent
L21_1 = "apex_loading:server:Save"
function L22_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = source
  function L2_2(A0_3, A1_3)
    local L2_3, L3_3, L4_3, L5_3
    L2_3 = TriggerClientEvent
    L3_3 = "apex_loading:client:Saved"
    L4_3 = L1_2
    L5_3 = {}
    L5_3.ok = A0_3
    L5_3.note = A1_3
    L2_3(L3_3, L4_3, L5_3)
  end
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "string" == L3_2 then
    L3_2 = #A0_2
    if not (L3_2 < 2) then
      goto lbl_16
    end
  end
  L3_2 = L2_2
  L4_2 = false
  L5_2 = "the creator sent nothing to save"
  L3_2(L4_2, L5_2)
  do return end
  ::lbl_16::
  L3_2 = #A0_2
  L4_2 = L4_1
  if L3_2 > L4_2 then
    L3_2 = L8_1
    L4_2 = "rejected a %.1f MB design from %s, the limit is %d MB"
    L5_2 = #A0_2
    L5_2 = L5_2 / 1048576
    L6_2 = GetPlayerName
    L7_2 = L1_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = L1_2
    end
    L7_2 = L4_1
    L7_2 = L7_2 / 1048576
    L3_2(L4_2, L5_2, L6_2, L7_2)
    L3_2 = L2_2
    L4_2 = false
    L5_2 = "this design is %.1f MB, the limit is %d MB. Remove an uploaded image."
    L6_2 = L5_2
    L5_2 = L5_2.format
    L7_2 = #A0_2
    L7_2 = L7_2 / 1048576
    L8_2 = L4_1
    L8_2 = L8_2 / 1048576
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2, L7_2, L8_2)
    L3_2(L4_2, L5_2, L6_2, L7_2, L8_2)
    return
  end
  L3_2 = Access
  L3_2 = L3_2.Check
  L4_2 = L1_2
  L5_2 = "creator"
  L3_2 = L3_2(L4_2, L5_2)
  if not L3_2 then
    L3_2 = L8_1
    L4_2 = "blocked a save from %s (%s), no access"
    L5_2 = GetPlayerName
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L5_2 = "?"
    end
    L6_2 = L1_2
    L3_2(L4_2, L5_2, L6_2)
    L3_2 = L2_2
    L4_2 = false
    L5_2 = "you do not have access to publish"
    L3_2(L4_2, L5_2)
    return
  end
  L3_2 = L18_1
  L4_2 = A0_2
  L5_2 = GetPlayerName
  L6_2 = L1_2
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = tostring
    L6_2 = L1_2
    L5_2 = L5_2(L6_2)
  end
  L3_2, L4_2 = L3_2(L4_2, L5_2)
  L5_2 = L2_2
  L6_2 = L3_2
  L7_2 = L4_2.note
  L5_2(L6_2, L7_2)
end
L20_1(L21_1, L22_1)
function L20_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2
  L0_2 = {}
  function L1_2(A0_3, ...)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = pcall
    L2_3 = string
    L2_3 = L2_3.format
    L3_3 = A0_3
    L4_3, L5_3 = ...
    L1_3, L2_3 = L1_3(L2_3, L3_3, L4_3, L5_3)
    L3_3 = L0_2
    L3_3 = #L3_3
    L4_3 = L3_3 + 1
    L3_3 = L0_2
    L5_3 = L2_3 or L5_3
    if not L1_3 or not L2_3 then
      L5_3 = A0_3
    end
    L3_3[L4_3] = L5_3
  end
  L2_2 = L11_1
  L2_2 = L2_2()
  L3_2 = L12_1
  L3_2 = L3_2()
  L4_2 = L13_1
  L4_2 = L4_2()
  L5_2 = L1_2
  L6_2 = "APEX LOADING storage"
  L5_2(L6_2)
  L5_2 = L1_2
  L6_2 = "  resource         %s"
  L7_2 = L0_1
  L5_2(L6_2, L7_2)
  L5_2 = pcall
  L6_2 = GetResourcePath
  L7_2 = L0_1
  L5_2, L6_2 = L5_2(L6_2, L7_2)
  L7_2 = L1_2
  L8_2 = "  folder           %s"
  L9_2 = L6_2 or L9_2
  if not L5_2 or not L6_2 then
    L9_2 = "unknown"
  end
  L7_2(L8_2, L9_2)
  L7_2 = L1_2
  L8_2 = "  in use           %s"
  L9_2 = L5_1
  if L9_2 then
    L9_2 = "%.0f KB"
    L10_2 = L9_2
    L9_2 = L9_2.format
    L11_2 = L5_1
    L11_2 = #L11_2
    L11_2 = L11_2 / 1024
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      goto lbl_44
    end
  end
  L9_2 = "none, the factory design is showing"
  ::lbl_44::
  L7_2(L8_2, L9_2)
  L7_2 = L1_2
  L8_2 = "  state            %s"
  L9_2 = L6_1.note
  L7_2(L8_2, L9_2)
  L7_2 = L1_2
  L8_2 = ""
  L7_2(L8_2)
  L7_2 = L1_2
  L8_2 = "  server key-value store (survives updates and reinstalls)"
  L7_2(L8_2)
  if L3_2 then
    L7_2 = L1_2
    L8_2 = "    design         %.0f KB"
    L9_2 = #L3_2
    L9_2 = L9_2 / 1024
    L7_2(L8_2, L9_2)
    L7_2 = L1_2
    L8_2 = "    published at   %s"
    if L4_2 then
      L9_2 = L4_2.savedAt
      if L9_2 then
        L9_2 = L4_2.savedAt
        if L9_2 > 0 then
          L9_2 = os
          L9_2 = L9_2.date
          L10_2 = "%Y-%m-%d %H:%M:%S"
          L11_2 = L4_2.savedAt
          L9_2 = L9_2(L10_2, L11_2)
          if L9_2 then
            goto lbl_81
          end
        end
      end
    end
    L9_2 = "unknown"
    ::lbl_81::
    L7_2(L8_2, L9_2)
  else
    L7_2 = L1_2
    L8_2 = "    design         EMPTY, nothing has been published on this server yet"
    L7_2(L8_2)
  end
  L7_2 = L1_2
  L8_2 = ""
  L7_2(L8_2)
  L7_2 = L1_2
  L8_2 = "  %s (portable copy, overwritten by a resource update)"
  L9_2 = L3_1
  L7_2(L8_2, L9_2)
  if L2_2 then
    L7_2 = L1_2
    L8_2 = "    design         %.0f KB"
    L9_2 = #L2_2
    L9_2 = L9_2 / 1024
    L7_2(L8_2, L9_2)
    if L3_2 and L2_2 ~= L3_2 then
      L7_2 = L4_2 or L7_2
      if L4_2 then
        L7_2 = tonumber
        L8_2 = L4_2.hash
        L7_2 = L7_2(L8_2)
        L8_2 = L9_1
        L9_2 = L2_2
        L8_2 = L8_2(L9_2)
        L7_2 = L7_2 == L8_2
      end
      L8_2 = L1_2
      L9_2 = "    status         DIFFERENT from the published design%s"
      if L7_2 then
        L10_2 = ""
        if L10_2 then
          goto lbl_125
        end
      end
      L10_2 = " (edited by hand, or restored by an update)"
      ::lbl_125::
      L8_2(L9_2, L10_2)
      L8_2 = L1_2
      L9_2 = "                   loading_use_file   makes the file the published design"
      L8_2(L9_2)
      L8_2 = L1_2
      L9_2 = "                   loading_use_saved  writes the published design back to the file"
      L8_2(L9_2)
    elseif L3_2 then
      L7_2 = L1_2
      L8_2 = "    status         matches the published design"
      L7_2(L8_2)
    else
      L7_2 = L1_2
      L8_2 = "    status         this is what players see"
      L7_2(L8_2)
    end
  else
    L7_2 = L1_2
    L8_2 = "    design         MISSING. Not a problem when the key-value store has one."
    L7_2(L8_2)
  end
  L7_2 = L1_2
  L8_2 = ""
  L7_2(L8_2)
  L7_2 = "{\"apex_loading_write_probe\":1}"
  L8_2 = false
  L9_2 = L2_2
  L10_2 = pcall
  L11_2 = SaveResourceFile
  L12_2 = L0_1
  L13_2 = "data/.probe"
  L14_2 = L7_2
  L15_2 = -1
  L10_2 = L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
  if L10_2 then
    L10_2 = pcall
    L11_2 = LoadResourceFile
    L12_2 = L0_1
    L13_2 = "data/.probe"
    L10_2, L11_2 = L10_2(L11_2, L12_2, L13_2)
    L8_2 = L10_2 or L8_2
    L8_2 = L10_2 and L11_2 == L7_2
    L12_2 = pcall
    L13_2 = SaveResourceFile
    L14_2 = L0_1
    L15_2 = "data/.probe"
    L16_2 = ""
    L17_2 = 0
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2)
  end
  if L9_2 then
    L10_2 = L11_1
    L10_2 = L10_2()
    if L10_2 ~= L9_2 then
      L10_2 = L8_1
      L11_2 = "the write probe disturbed %s, restoring it"
      L12_2 = L3_1
      L10_2(L11_2, L12_2)
      L10_2 = pcall
      L11_2 = SaveResourceFile
      L12_2 = L0_1
      L13_2 = L3_1
      L14_2 = L9_2
      L15_2 = -1
      L10_2(L11_2, L12_2, L13_2, L14_2, L15_2)
    end
  end
  L9_2 = false
  L10_2 = pcall
  L11_2 = SetResourceKvp
  L12_2 = "apex_loading:probe"
  L13_2 = L7_2
  L10_2 = L10_2(L11_2, L12_2, L13_2)
  if L10_2 then
    L10_2 = pcall
    L11_2 = GetResourceKvpString
    L12_2 = "apex_loading:probe"
    L10_2, L11_2 = L10_2(L11_2, L12_2)
    L9_2 = L10_2 or L9_2
    L9_2 = L10_2 and L11_2 == L7_2
    L12_2 = pcall
    L13_2 = DeleteResourceKvp
    L14_2 = "apex_loading:probe"
    L12_2(L13_2, L14_2)
  end
  L10_2 = L1_2
  L11_2 = "  write test       folder %s   key-value store %s"
  if L8_2 then
    L12_2 = "OK"
    if L12_2 then
      goto lbl_226
    end
  end
  L12_2 = "FAILED"
  ::lbl_226::
  if L9_2 then
    L13_2 = "OK"
    if L13_2 then
      goto lbl_232
    end
  end
  L13_2 = "FAILED"
  ::lbl_232::
  L10_2(L11_2, L12_2, L13_2)
  if not L9_2 and not L8_2 then
    L10_2 = L1_2
    L11_2 = "                   Nothing can be saved on this server. Check that the"
    L10_2(L11_2)
    L10_2 = L1_2
    L11_2 = "                   resources folder is writable and that the server is"
    L10_2(L11_2)
    L10_2 = L1_2
    L11_2 = "                   allowed to write its key-value database."
    L10_2(L11_2)
  elseif not L8_2 then
    L10_2 = L1_2
    L11_2 = "                   The folder is read-only. That is fine: publishing still"
    L10_2(L11_2)
    L10_2 = L1_2
    L11_2 = "                   works through the key-value store."
    L10_2(L11_2)
  end
  L10_2 = L1_2
  L11_2 = ""
  L10_2(L11_2)
  L10_2 = Uplink
  L10_2 = L10_2.Limits
  L10_2 = L10_2()
  L11_2 = L1_2
  L12_2 = "  network          publishes travel in %d KB parts at up to %.0f KB/s"
  L13_2 = math
  L13_2 = L13_2.floor
  L14_2 = L10_2.part
  L14_2 = L14_2 / 1000
  L13_2 = L13_2(L14_2)
  L14_2 = L10_2.rate
  L14_2 = L14_2 / 1024
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = L1_2
  L12_2 = "                   (server limit rateLimiter_netEventSize: %.0f KB/s, burst %.0f KB)"
  L13_2 = L10_2.serverRate
  L13_2 = L13_2 / 1024
  L14_2 = L10_2.serverBurst
  L14_2 = L14_2 / 1024
  L11_2(L12_2, L13_2, L14_2)
  L11_2 = Uplink
  L11_2 = L11_2.last
  if L11_2 then
    L12_2 = L1_2
    L13_2 = "  last upload      %s, %s by %s"
    L14_2 = os
    L14_2 = L14_2.date
    L15_2 = "%Y-%m-%d %H:%M:%S"
    L16_2 = L11_2.at
    L14_2 = L14_2(L15_2, L16_2)
    L15_2 = L11_2.kind
    L16_2 = L11_2.who
    L12_2(L13_2, L14_2, L15_2, L16_2)
    L12_2 = L1_2
    L13_2 = "                   %d of %d parts, %.0f KB: %s"
    L14_2 = L11_2.got
    if not L14_2 then
      L14_2 = 0
    end
    L15_2 = L11_2.parts
    if not L15_2 then
      L15_2 = 0
    end
    L16_2 = L11_2.bytes
    if not L16_2 then
      L16_2 = 0
    end
    L16_2 = L16_2 / 1024
    L17_2 = tostring
    L18_2 = L11_2.result
    L17_2, L18_2 = L17_2(L18_2)
    L12_2(L13_2, L14_2, L15_2, L16_2, L17_2, L18_2)
  else
    L12_2 = L1_2
    L13_2 = "  last upload      none since the resource started"
    L12_2(L13_2)
  end
  return L0_2
end
L21_1 = RegisterCommand
L22_1 = "loading_diag"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if 0 ~= A0_2 then
    return
  end
  L1_2 = ipairs
  L2_2 = L20_1
  L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2 = L2_2()
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = print
    L8_2 = L6_2
    L7_2(L8_2)
  end
end
L24_1 = true
L21_1(L22_1, L23_1, L24_1)
L21_1 = RegisterCommand
L22_1 = "loading_use_file"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  if 0 ~= A0_2 then
    return
  end
  L1_2 = L11_1
  L1_2 = L1_2()
  if not L1_2 then
    L2_2 = L8_1
    L3_2 = "%s has nothing readable in it."
    L4_2 = L3_1
    L2_2(L3_2, L4_2)
    return
  end
  L2_2 = L18_1
  L3_2 = L1_2
  L4_2 = "the console (loading_use_file)"
  L2_2 = L2_2(L3_2, L4_2)
  if L2_2 then
    L3_2 = L7_1
    L4_2 = "%s is now the published design."
    L5_2 = L3_1
    L3_2(L4_2, L5_2)
  end
end
L24_1 = true
L21_1(L22_1, L23_1, L24_1)
L21_1 = RegisterCommand
L22_1 = "loading_use_saved"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  if 0 ~= A0_2 then
    return
  end
  L1_2 = L5_1
  if not L1_2 then
    L1_2 = L8_1
    L2_2 = "there is no published design to write out."
    L1_2(L2_2)
    return
  end
  L1_2 = L16_1
  L2_2 = L5_1
  L1_2 = L1_2(L2_2)
  if L1_2 then
    L1_2 = L13_1
    L1_2 = L1_2()
    if not L1_2 then
      L1_2 = {}
    end
    L2_2 = pcall
    L3_2 = SetResourceKvp
    L4_2 = L2_1
    L5_2 = json
    L5_2 = L5_2.encode
    L6_2 = {}
    L7_2 = tonumber
    L8_2 = L1_2.savedAt
    L7_2 = L7_2(L8_2)
    if not L7_2 then
      L7_2 = L10_1
      L7_2 = L7_2()
    end
    L6_2.savedAt = L7_2
    L7_2 = L5_1
    L7_2 = #L7_2
    L6_2.bytes = L7_2
    L7_2 = L9_1
    L8_2 = L5_1
    L7_2 = L7_2(L8_2)
    L6_2.hash = L7_2
    L5_2, L6_2, L7_2, L8_2 = L5_2(L6_2)
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2, L8_2)
    L2_2 = pcall
    L3_2 = FlushResourceKvp
    L2_2(L3_2)
    L6_1.file = true
    L2_2 = L7_1
    L3_2 = "the published design was written to %s."
    L4_2 = L3_1
    L2_2(L3_2, L4_2)
  else
    L1_2 = L8_1
    L2_2 = "%s could not be written. The published design is unaffected."
    L3_2 = L3_1
    L1_2(L2_2, L3_2)
  end
end
L24_1 = true
L21_1(L22_1, L23_1, L24_1)
L21_1 = RegisterCommand
L22_1 = "loading_reset"
function L23_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  if 0 ~= A0_2 then
    return
  end
  L2_2 = tostring
  L3_2 = A1_2 or L3_2
  if not A1_2 then
    L3_2 = {}
  end
  L3_2 = L3_2[1]
  if not L3_2 then
    L3_2 = ""
  end
  L2_2 = L2_2(L3_2)
  if "confirm" ~= L2_2 then
    L2_2 = L8_1
    L3_2 = "this clears the published design and brings back the factory one."
    L2_2(L3_2)
    L2_2 = L8_1
    L3_2 = "run:  loading_reset confirm"
    L2_2(L3_2)
    return
  end
  L2_2 = pcall
  L3_2 = DeleteResourceKvp
  L4_2 = L1_1
  L2_2(L3_2, L4_2)
  L2_2 = pcall
  L3_2 = DeleteResourceKvp
  L4_2 = L2_1
  L2_2(L3_2, L4_2)
  L2_2 = pcall
  L3_2 = FlushResourceKvp
  L2_2(L3_2)
  L2_2 = pcall
  L3_2 = SaveResourceFile
  L4_2 = L0_1
  L5_2 = L3_1
  L6_2 = ""
  L7_2 = 0
  L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  L2_2 = nil
  L5_1 = L2_2
  L2_2 = {}
  L2_2.kvp = false
  L2_2.file = false
  L2_2.savedAt = 0
  L2_2.note = "reset to the factory design"
  L6_1 = L2_2
  L2_2 = L7_1
  L3_2 = "the published design was cleared. Players now get the factory design."
  L2_2(L3_2)
end
L24_1 = true
L21_1(L22_1, L23_1, L24_1)
L21_1 = CreateThread
function L22_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Wait
  L1_2 = 1500
  L0_2(L1_2)
  L0_2 = L5_1
  if L0_2 then
    L0_2 = L7_1
    L1_2 = "loading screen ready: design %.0f KB, %s"
    L2_2 = L5_1
    L2_2 = #L2_2
    L2_2 = L2_2 / 1024
    L3_2 = L6_1.note
    L0_2(L1_2, L2_2, L3_2)
  else
    L0_2 = L7_1
    L1_2 = "loading screen ready: no published design yet, the factory one is showing. /%s to build one."
    L2_2 = Config
    L2_2 = L2_2.Creator
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.Creator
      L2_2 = L2_2.command
      if L2_2 then
        goto lbl_28
      end
    end
    L2_2 = "loadingcreator"
    ::lbl_28::
    L0_2(L1_2, L2_2)
  end
end
L21_1(L22_1)
L21_1 = exports
L22_1 = "GetDesignJson"
function L23_1()
  local L0_2, L1_2
  L0_2 = L5_1
  return L0_2
end
L21_1(L22_1, L23_1)
L21_1 = exports
L22_1 = "SetDesignJson"
function L23_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = L18_1
  L2_2 = A0_2
  L3_2 = "another resource"
  L1_2 = L1_2(L2_2, L3_2)
  return L1_2
end
L21_1(L22_1, L23_1)
L21_1 = exports
L22_1 = "GetStorageState"
function L23_1()
  local L0_2, L1_2
  L0_2 = {}
  L1_2 = L5_1
  if L1_2 then
    L1_2 = L5_1
    L1_2 = #L1_2
    if L1_2 then
      goto lbl_11
    end
  end
  L1_2 = 0
  ::lbl_11::
  L0_2.design = L1_2
  L1_2 = L6_1.kvp
  L0_2.kvp = L1_2
  L1_2 = L6_1.file
  L0_2.file = L1_2
  L1_2 = L6_1.savedAt
  L0_2.savedAt = L1_2
  L1_2 = L6_1.note
  L0_2.note = L1_2
  return L0_2
end
L21_1(L22_1, L23_1)
