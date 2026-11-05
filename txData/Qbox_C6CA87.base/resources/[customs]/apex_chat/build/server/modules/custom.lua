local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1
L0_1 = Shared
if L0_1 then
  L0_1 = Shared
  L0_1 = L0_1.Storage
  if L0_1 then
    L0_1 = Shared
    L0_1 = L0_1.Storage
    L0_1 = L0_1.serverCustomCmdsKey
    if L0_1 then
      goto lbl_15
    end
  end
end
L0_1 = "apex_chat:custom_commands"
::lbl_15::
L1_1 = {}
L2_1 = {}
function L3_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = GetResourceKvpString
  L1_2 = L0_1
  L0_2 = L0_2(L1_2)
  if not L0_2 or "" == L0_2 then
    L1_2 = {}
    return L1_2
  end
  L1_2 = pcall
  L2_2 = json
  L2_2 = L2_2.decode
  L3_2 = L0_2
  L1_2, L2_2 = L1_2(L2_2, L3_2)
  if L1_2 then
    L3_2 = type
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if "table" == L3_2 then
      goto lbl_26
    end
  end
  L3_2 = {}
  do return L3_2 end
  ::lbl_26::
  return L2_2
end
function L4_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SetResourceKvp
  L2_2 = L0_1
  L3_2 = json
  L3_2 = L3_2.encode
  L4_2 = A0_2
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if A0_2 then
    L1_2 = A0_2.PlayerData
    if L1_2 then
      goto lbl_8
    end
  end
  L1_2 = false
  do return L1_2 end
  ::lbl_8::
  L1_2 = Config
  L1_2 = L1_2.CustomCommands
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.CustomCommands
    L1_2 = L1_2.authorGroups
    if L1_2 then
      goto lbl_21
    end
  end
  L1_2 = {}
  L2_2 = "admin"
  L1_2[1] = L2_2
  ::lbl_21::
  L2_2 = ipairs
  L3_2 = L1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    if "everyone" == L7_2 then
      L8_2 = true
      return L8_2
    end
    L8_2 = QBCore
    L8_2 = L8_2.Functions
    L8_2 = L8_2.HasPermission
    L9_2 = A0_2.PlayerData
    L9_2 = L9_2.source
    L10_2 = L7_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      L8_2 = true
      return L8_2
    end
  end
  L2_2 = false
  return L2_2
end
function L6_1()
  local L0_2, L1_2
  L0_2 = {}
  L0_2.background = "linear-gradient(90deg, rgba(26,26,27,.92) 0%, rgba(31,94,255,.55) 100%)"
  L0_2.icon = "fas fa-bolt"
  L0_2.iconBg = "#1F5EFF"
  L0_2.titleColor = "#F4F4F5"
  L0_2.title = "CUSTOM"
  return L0_2
end
function L7_1()
  local L0_2, L1_2
  L0_2 = {}
  L0_2.type = "broadcast"
  L0_2.job = ""
  L0_2.distance = 20.0
  return L0_2
end
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = nil
    L2_2 = "invalid"
    return L1_2, L2_2
  end
  L1_2 = tostring
  L2_2 = A0_2.name
  if not L2_2 then
    L2_2 = ""
  end
  L1_2 = L1_2(L2_2)
  L2_2 = L1_2
  L1_2 = L1_2.gsub
  L3_2 = "%s+"
  L4_2 = ""
  L1_2 = L1_2(L2_2, L3_2, L4_2)
  L2_2 = L1_2
  L1_2 = L1_2.lower
  L1_2 = L1_2(L2_2)
  if "" == L1_2 then
    L2_2 = nil
    L3_2 = "name"
    return L2_2, L3_2
  end
  L3_2 = L1_2
  L2_2 = L1_2.match
  L4_2 = "^[%a_][%w_]*$"
  L2_2 = L2_2(L3_2, L4_2)
  if not L2_2 then
    L2_2 = nil
    L3_2 = "name-pattern"
    return L2_2, L3_2
  end
  L2_2 = #L1_2
  if L2_2 > 32 then
    L2_2 = nil
    L3_2 = "name-length"
    return L2_2, L3_2
  end
  L2_2 = A0_2.style
  if not L2_2 then
    L2_2 = {}
  end
  L3_2 = A0_2.logic
  if not L3_2 then
    L3_2 = {}
  end
  L4_2 = {}
  L5_2 = A0_2.id
  if not L5_2 then
    L5_2 = Utils
    L5_2 = L5_2.uuid
    L5_2 = L5_2()
  end
  L4_2.id = L5_2
  L4_2.name = L1_2
  L5_2 = tostring
  L6_2 = A0_2.description
  if not L6_2 then
    L6_2 = ""
  end
  L5_2 = L5_2(L6_2)
  L6_2 = L5_2
  L5_2 = L5_2.sub
  L7_2 = 1
  L8_2 = 200
  L5_2 = L5_2(L6_2, L7_2, L8_2)
  L4_2.description = L5_2
  L5_2 = A0_2.native
  L5_2 = false ~= L5_2
  L4_2.native = L5_2
  L5_2 = A0_2.duration
  if "auto-remove" == L5_2 then
    L5_2 = "auto-remove"
    if L5_2 then
      goto lbl_84
    end
  end
  L5_2 = "permanent"
  ::lbl_84::
  L4_2.duration = L5_2
  L5_2 = tonumber
  L6_2 = A0_2.durationMs
  L5_2 = L5_2(L6_2)
  if not L5_2 then
    L5_2 = Config
    L5_2 = L5_2.CustomCommands
    if L5_2 then
      L5_2 = Config
      L5_2 = L5_2.CustomCommands
      L5_2 = L5_2.defaultAutoMs
      if L5_2 then
        goto lbl_100
      end
    end
    L5_2 = 30000
  end
  ::lbl_100::
  L4_2.durationMs = L5_2
  L5_2 = {}
  L6_2 = L2_2.background
  if not L6_2 then
    L6_2 = L6_1
    L6_2 = L6_2()
    L6_2 = L6_2.background
  end
  L5_2.background = L6_2
  L6_2 = L2_2.icon
  if not L6_2 then
    L6_2 = L6_1
    L6_2 = L6_2()
    L6_2 = L6_2.icon
  end
  L5_2.icon = L6_2
  L6_2 = L2_2.iconBg
  if not L6_2 then
    L6_2 = L6_1
    L6_2 = L6_2()
    L6_2 = L6_2.iconBg
  end
  L5_2.iconBg = L6_2
  L6_2 = L2_2.titleColor
  if not L6_2 then
    L6_2 = L6_1
    L6_2 = L6_2()
    L6_2 = L6_2.titleColor
  end
  L5_2.titleColor = L6_2
  L6_2 = L2_2.title
  if L6_2 then
    L6_2 = L2_2.title
    L6_2 = #L6_2
    if L6_2 > 0 then
      L6_2 = L2_2.title
      if L6_2 then
        goto lbl_143
      end
    end
  end
  L7_2 = L1_2
  L6_2 = L1_2.upper
  L6_2 = L6_2(L7_2)
  ::lbl_143::
  L5_2.title = L6_2
  L4_2.style = L5_2
  L5_2 = {}
  L6_2 = {}
  L6_2.broadcast = 1
  L6_2.job = 1
  L6_2.distance = 1
  L6_2.self = 1
  L7_2 = L3_2.type
  if not L7_2 then
    L7_2 = "broadcast"
  end
  L6_2 = L6_2[L7_2]
  if L6_2 then
    L6_2 = L3_2.type
    if L6_2 then
      goto lbl_167
    end
    L6_2 = "broadcast"
    if L6_2 then
      goto lbl_167
    end
  end
  L6_2 = "broadcast"
  ::lbl_167::
  L5_2.type = L6_2
  L6_2 = L3_2.job
  if not L6_2 then
    L6_2 = ""
  end
  L5_2.job = L6_2
  L6_2 = tonumber
  L7_2 = L3_2.distance
  L6_2 = L6_2(L7_2)
  if not L6_2 then
    L6_2 = 20.0
  end
  L5_2.distance = L6_2
  L4_2.logic = L5_2
  return L4_2
end
function L9_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2, L18_2, L19_2, L20_2
  L1_2 = A0_2.duration
  if "auto-remove" == L1_2 then
    L1_2 = " data-auto=\""
    L2_2 = tostring
    L3_2 = A0_2.durationMs
    L2_2 = L2_2(L3_2)
    L3_2 = "\""
    L1_2 = L1_2 .. L2_2 .. L3_2
    if L1_2 then
      goto lbl_13
    end
  end
  L1_2 = ""
  ::lbl_13::
  L2_2 = "<div class=\"chat-message apex-custom apex-custom-"
  L3_2 = A0_2.id
  L4_2 = "\" style=\"background: "
  L5_2 = A0_2.style
  L5_2 = L5_2.background
  L6_2 = ";\""
  L7_2 = L1_2
  L8_2 = ">"
  L9_2 = "<i class=\""
  L10_2 = A0_2.style
  L10_2 = L10_2.icon
  L11_2 = "\" style=\"color:#fff;background-color:"
  L12_2 = A0_2.style
  L12_2 = L12_2.iconBg
  L13_2 = ";padding:5px;border-radius:5px;\"></i> "
  L14_2 = "<b><span style=\"color:"
  L15_2 = A0_2.style
  L15_2 = L15_2.titleColor
  L16_2 = "\">["
  L17_2 = A0_2.style
  L17_2 = L17_2.title
  L18_2 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b>"
  L19_2 = "<div class=\"message\">{1}</div>"
  L20_2 = "</div>"
  L2_2 = L2_2 .. L3_2 .. L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2 .. L17_2 .. L18_2 .. L19_2 .. L20_2
  return L2_2
end
function L10_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A0_2.logic
  L3_2 = L2_2.type
  if "self" == L3_2 then
    function L3_2(A0_3)
      local L1_3, L2_3
      L1_3 = A0_3
      L2_3 = A1_2
      L1_3(L2_3)
    end
    return L3_2
  else
    L3_2 = L2_2.type
    if "job" == L3_2 then
      function L3_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
        L1_3 = ipairs
        L2_3 = QBCore
        L2_3 = L2_3.Functions
        L2_3 = L2_3.GetPlayers
        L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3 = L2_3()
        L1_3, L2_3, L3_3, L4_3 = L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
        for L5_3, L6_3 in L1_3, L2_3, L3_3, L4_3 do
          L7_3 = QBCore
          L7_3 = L7_3.Functions
          L7_3 = L7_3.GetPlayer
          L8_3 = L6_3
          L7_3 = L7_3(L8_3)
          if L7_3 then
            L8_3 = L7_3.PlayerData
            L8_3 = L8_3.job
            L8_3 = L8_3.name
            L9_3 = L2_2.job
            if L8_3 == L9_3 then
              L8_3 = chatsHidden
              L9_3 = L7_3.PlayerData
              L9_3 = L9_3.source
              L8_3 = L8_3[L9_3]
              if nil == L8_3 then
                L8_3 = A0_3
                L9_3 = L6_3
                L8_3(L9_3)
              end
            end
          end
        end
      end
      return L3_2
    else
      L3_2 = L2_2.type
      if "distance" == L3_2 then
        function L3_2(A0_3)
          local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3
          L1_3 = GetPlayerPed
          L2_3 = A1_2
          L1_3 = L1_3(L2_3)
          L2_3 = GetEntityCoords
          L3_3 = L1_3
          L2_3 = L2_3(L3_3)
          L3_3 = ipairs
          L4_3 = QBCore
          L4_3 = L4_3.Functions
          L4_3 = L4_3.GetPlayers
          L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3 = L4_3()
          L3_3, L4_3, L5_3, L6_3 = L3_3(L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3)
          for L7_3, L8_3 in L3_3, L4_3, L5_3, L6_3 do
            L9_3 = QBCore
            L9_3 = L9_3.Functions
            L9_3 = L9_3.GetPlayer
            L10_3 = L8_3
            L9_3 = L9_3(L10_3)
            if L9_3 then
              L10_3 = chatsHidden
              L11_3 = L9_3.PlayerData
              L11_3 = L11_3.source
              L10_3 = L10_3[L11_3]
              if nil == L10_3 then
                L10_3 = GetEntityCoords
                L11_3 = GetPlayerPed
                L12_3 = L9_3.PlayerData
                L12_3 = L12_3.source
                L11_3, L12_3 = L11_3(L12_3)
                L10_3 = L10_3(L11_3, L12_3)
                L11_3 = L2_3 - L10_3
                L11_3 = #L11_3
                L12_3 = L2_2.distance
                if not L12_3 then
                  L12_3 = 20.0
                end
                if L11_3 < L12_3 then
                  L11_3 = A0_3
                  L12_3 = L8_3
                  L11_3(L12_3)
                end
              end
            end
          end
        end
        return L3_2
      else
        function L3_2(A0_3)
          local L1_3, L2_3
          L1_3 = showAll
          L2_3 = A0_3
          L1_3(L2_3)
        end
        return L3_2
      end
    end
  end
end
function L11_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = A0_2.id
  L1_2 = L1_1
  L1_2 = L1_2[L2_2]
  if L1_2 then
    L2_2 = A0_2.id
    L1_2 = L2_1
    L1_2[L2_2] = A0_2
    return
  end
  L2_2 = A0_2.id
  L1_2 = L2_1
  L1_2[L2_2] = A0_2
  L2_2 = A0_2.id
  L1_2 = L1_1
  L1_2[L2_2] = true
  L1_2 = RegisterCommand
  L2_2 = A0_2.name
  function L3_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3, L10_3, L11_3, L12_3, L13_3, L14_3, L15_3, L16_3, L17_3
    L4_3 = A0_2.id
    L3_3 = L2_1
    L3_3 = L3_3[L4_3]
    if not L3_3 then
      return
    end
    L4_3 = QBCore
    L4_3 = L4_3.Functions
    L4_3 = L4_3.GetPlayer
    L5_3 = A0_3
    L4_3 = L4_3(L5_3)
    if not L4_3 then
      return
    end
    L6_3 = A2_3
    L5_3 = A2_3.sub
    L7_3 = string
    L7_3 = L7_3.len
    L8_3 = L3_3.name
    L7_3 = L7_3(L8_3)
    L7_3 = L7_3 + 1
    L5_3 = L5_3(L6_3, L7_3)
    L6_3 = L5_3
    L5_3 = L5_3.gsub
    L7_3 = "^%s+"
    L8_3 = ""
    L5_3 = L5_3(L6_3, L7_3, L8_3)
    if "" ~= L5_3 then
      L6_3 = chatsHidden
      L6_3 = L6_3[A0_3]
      if not L6_3 then
        goto lbl_34
      end
    end
    do return end
    ::lbl_34::
    L6_3 = mutedList
    L6_3 = L6_3[A0_3]
    if L6_3 then
      return
    end
    L6_3 = os
    L6_3 = L6_3.date
    L7_3 = Config
    L7_3 = L7_3.DateFormat
    L6_3 = L6_3(L7_3)
    L7_3 = Config
    L7_3 = L7_3.ShowIDOnMessageForEveryone
    if L7_3 then
      L7_3 = getName
      L8_3 = L4_3
      L7_3 = L7_3(L8_3)
      L8_3 = " ["
      L9_3 = A0_3
      L10_3 = "]"
      L7_3 = L7_3 .. L8_3 .. L9_3 .. L10_3
      if L7_3 then
        goto lbl_60
      end
    end
    L7_3 = getName
    L8_3 = L4_3
    L7_3 = L7_3(L8_3)
    ::lbl_60::
    L8_3 = L9_1
    L9_3 = L3_3
    L8_3 = L8_3(L9_3)
    L9_3 = L10_1
    L10_3 = L3_3
    L11_3 = A0_3
    L9_3 = L9_3(L10_3, L11_3)
    L10_3 = L9_3
    function L11_3(A0_4)
      local L1_4, L2_4, L3_4, L4_4, L5_4, L6_4, L7_4, L8_4
      L1_4 = TriggerClientEvent
      L2_4 = "chat:addMessage"
      L3_4 = A0_4
      L4_4 = {}
      L5_4 = L8_3
      L4_4.template = L5_4
      L5_4 = {}
      L6_4 = L7_3
      L7_4 = L5_3
      L8_4 = L6_3
      L5_4[1] = L6_4
      L5_4[2] = L7_4
      L5_4[3] = L8_4
      L4_4.args = L5_4
      L1_4(L2_4, L3_4, L4_4)
    end
    L10_3(L11_3)
    L10_3 = Webhook
    if "" ~= L10_3 then
      L10_3 = ExtractIdentifiers
      L11_3 = A0_3
      L10_3 = L10_3(L11_3)
      L11_3 = discordWebhook
      L12_3 = {}
      L12_3.playerid = A0_3
      L13_3 = L10_3.license
      if not L13_3 then
        L13_3 = ""
      end
      L14_3 = L13_3
      L13_3 = L13_3.gsub
      L15_3 = "license:"
      L16_3 = ""
      L13_3 = L13_3(L14_3, L15_3, L16_3)
      L12_3.identifier = L13_3
      L13_3 = "<@"
      L14_3 = L10_3.discord
      if not L14_3 then
        L14_3 = ""
      end
      L15_3 = L14_3
      L14_3 = L14_3.gsub
      L16_3 = "discord:"
      L17_3 = ""
      L14_3 = L14_3(L15_3, L16_3, L17_3)
      L15_3 = ">"
      L13_3 = L13_3 .. L14_3 .. L15_3
      L12_3.discord = L13_3
      L13_3 = interp
      L14_3 = Config
      L14_3 = L14_3.WebhookText
      L14_3 = L14_3.custom_cmd
      L15_3 = {}
      L16_3 = L3_3.name
      L15_3.name = L16_3
      L13_3 = L13_3(L14_3, L15_3)
      L12_3.type = L13_3
      L12_3.message = L5_3
      L11_3(L12_3)
    end
  end
  L4_2 = false
  L1_2(L2_2, L3_2, L4_2)
  L1_2 = TriggerClientEvent
  L2_2 = "chat:addSuggestion"
  L3_2 = -1
  L4_2 = "/"
  L5_2 = A0_2.name
  L4_2 = L4_2 .. L5_2
  L5_2 = A0_2.description
  if not L5_2 then
    L5_2 = ""
  end
  L6_2 = {}
  L7_2 = {}
  L7_2.name = "message"
  L7_2.help = "message to send"
  L6_2[1] = L7_2
  L1_2(L2_2, L3_2, L4_2, L5_2, L6_2)
end
function L12_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = ipairs
  L2_2 = A0_2
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L8_1
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    if L7_2 then
      L8_2 = L11_1
      L9_2 = L7_2
      L8_2(L9_2)
    end
  end
end
L13_1 = Citizen
L13_1 = L13_1.CreateThread
function L14_1()
  local L0_2, L1_2
  L0_2 = L12_1
  L1_2 = L3_1
  L1_2 = L1_2()
  L0_2(L1_2)
end
L13_1(L14_1)
L13_1 = RegisterNetEvent
L14_1 = "apex_chat:cc:list"
function L15_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = source
  L1_2 = TriggerClientEvent
  L2_2 = "apex_chat:cc:list:resp"
  L3_2 = L0_2
  L4_2 = L3_1
  L4_2 = L4_2()
  L1_2(L2_2, L3_2, L4_2)
end
L13_1(L14_1, L15_1)
L13_1 = RegisterNetEvent
L14_1 = "apex_chat:cc:save"
function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L1_2 = source
  L2_2 = QBCore
  L2_2 = L2_2.Functions
  L2_2 = L2_2.GetPlayer
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = L5_1
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = TriggerClientEvent
    L4_2 = "okokChat:Notification"
    L5_2 = L1_2
    L6_2 = Config
    L6_2 = L6_2.NotificationsText
    L6_2 = L6_2.cc_denied
    L7_2 = Config
    L7_2 = L7_2.NotificationsText
    L7_2 = L7_2.cc_denied
    L7_2 = L7_2.message
    L3_2(L4_2, L5_2, L6_2, L7_2)
    return
  end
  L3_2 = L8_1
  L4_2 = A0_2
  L3_2, L4_2 = L3_2(L4_2)
  if not L3_2 then
    L5_2 = TriggerClientEvent
    L6_2 = "okokChat:Notification"
    L7_2 = L1_2
    L8_2 = Config
    L8_2 = L8_2.NotificationsText
    L8_2 = L8_2.cc_invalid
    L9_2 = Config
    L9_2 = L9_2.NotificationsText
    L9_2 = L9_2.cc_invalid
    L9_2 = L9_2.message
    L10_2 = " ("
    L11_2 = L4_2 or L11_2
    if not L4_2 then
      L11_2 = "?"
    end
    L12_2 = ")"
    L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2
    L5_2(L6_2, L7_2, L8_2, L9_2)
    return
  end
  L5_2 = L3_1
  L5_2 = L5_2()
  L6_2 = false
  L7_2 = ipairs
  L8_2 = L5_2
  L7_2, L8_2, L9_2, L10_2 = L7_2(L8_2)
  for L11_2, L12_2 in L7_2, L8_2, L9_2, L10_2 do
    L13_2 = L12_2.id
    L14_2 = L3_2.id
    if L13_2 ~= L14_2 then
      L13_2 = L12_2.name
      L14_2 = L3_2.name
      if L13_2 ~= L14_2 then
        goto lbl_65
      end
    end
    L5_2[L11_2] = L3_2
    L6_2 = true
    do break end
    ::lbl_65::
  end
  if not L6_2 then
    L7_2 = #L5_2
    L8_2 = Config
    L8_2 = L8_2.CustomCommands
    if L8_2 then
      L8_2 = Config
      L8_2 = L8_2.CustomCommands
      L8_2 = L8_2.maxTotal
      if L8_2 then
        goto lbl_81
      end
    end
    L8_2 = 100
    ::lbl_81::
    if L7_2 >= L8_2 then
      L7_2 = TriggerClientEvent
      L8_2 = "okokChat:Notification"
      L9_2 = L1_2
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.cc_invalid
      L11_2 = "Too many custom commands"
      L7_2(L8_2, L9_2, L10_2, L11_2)
      return
    end
    L7_2 = #L5_2
    L7_2 = L7_2 + 1
    L5_2[L7_2] = L3_2
  end
  L7_2 = L4_1
  L8_2 = L5_2
  L7_2(L8_2)
  L7_2 = L11_1
  L8_2 = L3_2
  L7_2(L8_2)
  L7_2 = TriggerClientEvent
  L8_2 = "okokChat:Notification"
  L9_2 = L1_2
  L10_2 = Config
  L10_2 = L10_2.NotificationsText
  L10_2 = L10_2.cc_saved
  L11_2 = Config
  L11_2 = L11_2.NotificationsText
  L11_2 = L11_2.cc_saved
  L11_2 = L11_2.message
  L7_2(L8_2, L9_2, L10_2, L11_2)
  L7_2 = TriggerClientEvent
  L8_2 = "apex_chat:cc:list:resp"
  L9_2 = L1_2
  L10_2 = L5_2
  L7_2(L8_2, L9_2, L10_2)
end
L13_1(L14_1, L15_1)
L13_1 = RegisterNetEvent
L14_1 = "apex_chat:cc:delete"
function L15_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L1_2 = source
  L2_2 = QBCore
  L2_2 = L2_2.Functions
  L2_2 = L2_2.GetPlayer
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  L3_2 = L5_1
  L4_2 = L2_2
  L3_2 = L3_2(L4_2)
  if not L3_2 then
    L3_2 = TriggerClientEvent
    L4_2 = "okokChat:Notification"
    L5_2 = L1_2
    L6_2 = Config
    L6_2 = L6_2.NotificationsText
    L6_2 = L6_2.cc_denied
    L7_2 = Config
    L7_2 = L7_2.NotificationsText
    L7_2 = L7_2.cc_denied
    L7_2 = L7_2.message
    L3_2(L4_2, L5_2, L6_2, L7_2)
    return
  end
  L3_2 = L3_1
  L3_2 = L3_2()
  L4_2 = ipairs
  L5_2 = L3_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L10_2 = L9_2.id
    if L10_2 == A0_2 then
      L10_2 = table
      L10_2 = L10_2.remove
      L11_2 = L3_2
      L12_2 = L8_2
      L10_2(L11_2, L12_2)
      L10_2 = L2_1
      L10_2[A0_2] = nil
      break
    end
  end
  L4_2 = L4_1
  L5_2 = L3_2
  L4_2(L5_2)
  L4_2 = TriggerClientEvent
  L5_2 = "okokChat:Notification"
  L6_2 = L1_2
  L7_2 = Config
  L7_2 = L7_2.NotificationsText
  L7_2 = L7_2.cc_deleted
  L8_2 = Config
  L8_2 = L8_2.NotificationsText
  L8_2 = L8_2.cc_deleted
  L8_2 = L8_2.message
  L4_2(L5_2, L6_2, L7_2, L8_2)
  L4_2 = TriggerClientEvent
  L5_2 = "apex_chat:cc:list:resp"
  L6_2 = L1_2
  L7_2 = L3_2
  L4_2(L5_2, L6_2, L7_2)
end
L13_1(L14_1, L15_1)
L13_1 = exports
L14_1 = "GetCustomCommands"
function L15_1()
  local L0_2, L1_2
  L0_2 = L3_1
  return L0_2()
end
L13_1(L14_1, L15_1)
