local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
function L0_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = TriggerClientEvent
  L2_2 = "okokChat:checkDeathStatus"
  L3_2 = A0_2
  L1_2(L2_2, L3_2)
  while true do
    L1_2 = checkedDeathStatus
    if L1_2 then
      break
    end
    L1_2 = Citizen
    L1_2 = L1_2.Wait
    L2_2 = 5
    L1_2(L2_2)
  end
  checkedDeathStatus = false
end
function L1_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L2_2 = mutedList
  L2_2 = L2_2[A0_2]
  if L2_2 then
    L2_2 = TriggerClientEvent
    L3_2 = "chat:addMessage"
    L4_2 = A0_2
    L5_2 = {}
    L6_2 = "<div class=\"chat-message muted\"><i class=\""
    L7_2 = Config
    L7_2 = L7_2.TimeOutIcon
    L8_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">"
    L9_2 = Config
    L9_2 = L9_2.MessageTitle
    L10_2 = "</span>&nbsp;<span class=\"time\">{1}</span></b><div class=\"message\">You are muted for <b>{0}</b></div></div>"
    L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2
    L5_2.template = L6_2
    L6_2 = {}
    L7_2 = SecondsToClock
    L8_2 = mutedList
    L8_2 = L8_2[A0_2]
    L8_2 = L8_2.timeLeft
    L7_2 = L7_2(L8_2)
    L8_2 = A1_2
    L6_2[1] = L7_2
    L6_2[2] = L8_2
    L5_2.args = L6_2
    L2_2(L3_2, L4_2, L5_2)
    L2_2 = true
    return L2_2
  end
  L2_2 = false
  return L2_2
end
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = Config
  L2_2 = L2_2.ShowIDOnMessageForEveryone
  if L2_2 then
    L2_2 = getName
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    L3_2 = " ["
    L4_2 = A1_2
    L5_2 = "]"
    L2_2 = L2_2 .. L3_2 .. L4_2 .. L5_2
    return L2_2
  end
  L2_2 = getName
  L3_2 = A0_2
  return L2_2(L3_2)
end
function L3_1(A0_2, A1_2, A2_2, A3_2)
  local L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L4_2 = Webhook
  if "" == L4_2 then
    return
  end
  L4_2 = ExtractIdentifiers
  L5_2 = A0_2
  L4_2 = L4_2(L5_2)
  L5_2 = discordWebhook
  L6_2 = {}
  L6_2.playerid = A0_2
  L7_2 = L4_2.license
  if not L7_2 then
    L7_2 = ""
  end
  L8_2 = L7_2
  L7_2 = L7_2.gsub
  L9_2 = "license:"
  L10_2 = ""
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L6_2.identifier = L7_2
  L7_2 = "<@"
  L8_2 = L4_2.discord
  if not L8_2 then
    L8_2 = ""
  end
  L9_2 = L8_2
  L8_2 = L8_2.gsub
  L10_2 = "discord:"
  L11_2 = ""
  L8_2 = L8_2(L9_2, L10_2, L11_2)
  L9_2 = ">"
  L7_2 = L7_2 .. L8_2 .. L9_2
  L6_2.discord = L7_2
  if A3_2 then
    L7_2 = interp
    L8_2 = Config
    L8_2 = L8_2.WebhookText
    L8_2 = L8_2[A1_2]
    L9_2 = A3_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      goto lbl_46
    end
  end
  L7_2 = Config
  L7_2 = L7_2.WebhookText
  L7_2 = L7_2[A1_2]
  ::lbl_46::
  L6_2.type = L7_2
  L6_2.message = A2_2
  L5_2(L6_2)
end
L4_1 = Config
L4_1 = L4_1.EnablePoliceCommand
if L4_1 then
  L4_1 = RegisterCommand
  L5_1 = Config
  L5_1 = L5_1.PoliceCommand
  function L6_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
    L3_2 = QBCore
    L3_2 = L3_2.Functions
    L3_2 = L3_2.GetPlayer
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      return
    end
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = string
    L6_2 = L6_2.len
    L7_2 = Config
    L7_2 = L7_2.PoliceCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = L2_1
    L7_2 = L3_2
    L8_2 = A0_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L3_2.PlayerData
    L8_2 = L8_2.job
    L8_2 = L8_2.name
    L9_2 = L0_1
    L10_2 = A0_2
    L9_2(L10_2)
    L9_2 = isDead
    if L9_2 then
      return
    end
    L9_2 = L1_1
    L10_2 = A0_2
    L11_2 = L5_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      return
    end
    L10_2 = L4_2
    L9_2 = L4_2.gsub
    L11_2 = "%s+"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if "" ~= L9_2 then
      L9_2 = chatsHidden
      L9_2 = L9_2[A0_2]
      if not L9_2 then
        goto lbl_62
      end
    end
    do return end
    ::lbl_62::
    L9_2 = Config
    L9_2 = L9_2.PoliceJobName
    if L8_2 ~= L9_2 then
      return
    end
    L9_2 = "<div class=\"chat-message police\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.PoliceIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-brand, #1F5EFF)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L10_2 = showAll
    function L11_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = L9_2
      L4_3.template = L5_3
      L5_3 = {}
      L6_3 = L6_2
      L7_3 = L4_2
      L8_3 = L5_2
      L5_3[1] = L6_3
      L5_3[2] = L7_3
      L5_3[3] = L8_3
      L4_3.args = L5_3
      L1_3(L2_3, L3_3, L4_3)
    end
    L10_2(L11_2)
    L10_2 = Config
    L10_2 = L10_2.ShowIDOnMessage
    if L10_2 then
      L10_2 = showOnlyForAdmins
      function L11_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
        L1_3 = TriggerClientEvent
        L2_3 = "chat:addMessage"
        L3_3 = A0_3
        L4_3 = {}
        L5_3 = L9_2
        L4_3.template = L5_3
        L5_3 = {}
        L6_3 = L7_2
        L7_3 = L4_2
        L8_3 = L5_2
        L5_3[1] = L6_3
        L5_3[2] = L7_3
        L5_3[3] = L8_3
        L4_3.args = L5_3
        L1_3(L2_3, L3_3, L4_3)
      end
      L10_2(L11_2)
    end
    L10_2 = L3_1
    L11_2 = A0_2
    L12_2 = "police"
    L13_2 = L4_2
    L10_2(L11_2, L12_2, L13_2)
  end
  L4_1(L5_1, L6_1)
end
L4_1 = Config
L4_1 = L4_1.EnableAmbulanceCommand
if L4_1 then
  L4_1 = RegisterCommand
  L5_1 = Config
  L5_1 = L5_1.AmbulanceCommand
  function L6_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2
    L3_2 = QBCore
    L3_2 = L3_2.Functions
    L3_2 = L3_2.GetPlayer
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      return
    end
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = string
    L6_2 = L6_2.len
    L7_2 = Config
    L7_2 = L7_2.AmbulanceCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = L2_1
    L7_2 = L3_2
    L8_2 = A0_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L3_2.PlayerData
    L8_2 = L8_2.job
    L8_2 = L8_2.name
    L9_2 = L0_1
    L10_2 = A0_2
    L9_2(L10_2)
    L9_2 = isDead
    if L9_2 then
      return
    end
    L9_2 = L1_1
    L10_2 = A0_2
    L11_2 = L5_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      return
    end
    L10_2 = L4_2
    L9_2 = L4_2.gsub
    L11_2 = "%s+"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if "" ~= L9_2 then
      L9_2 = chatsHidden
      L9_2 = L9_2[A0_2]
      if not L9_2 then
        goto lbl_62
      end
    end
    do return end
    ::lbl_62::
    L9_2 = Config
    L9_2 = L9_2.AmbulanceJobName
    if L8_2 ~= L9_2 then
      return
    end
    L9_2 = "<div class=\"chat-message ambulance\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.AmbulanceIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L10_2 = showAll
    function L11_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = L9_2
      L4_3.template = L5_3
      L5_3 = {}
      L6_3 = L6_2
      L7_3 = L4_2
      L8_3 = L5_2
      L5_3[1] = L6_3
      L5_3[2] = L7_3
      L5_3[3] = L8_3
      L4_3.args = L5_3
      L1_3(L2_3, L3_3, L4_3)
    end
    L10_2(L11_2)
    L10_2 = Config
    L10_2 = L10_2.ShowIDOnMessage
    if L10_2 then
      L10_2 = showOnlyForAdmins
      function L11_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
        L1_3 = TriggerClientEvent
        L2_3 = "chat:addMessage"
        L3_3 = A0_3
        L4_3 = {}
        L5_3 = L9_2
        L4_3.template = L5_3
        L5_3 = {}
        L6_3 = L7_2
        L7_3 = L4_2
        L8_3 = L5_2
        L5_3[1] = L6_3
        L5_3[2] = L7_3
        L5_3[3] = L8_3
        L4_3.args = L5_3
        L1_3(L2_3, L3_3, L4_3)
      end
      L10_2(L11_2)
    end
    L10_2 = L3_1
    L11_2 = A0_2
    L12_2 = "ambulance"
    L13_2 = L4_2
    L10_2(L11_2, L12_2, L13_2)
  end
  L4_1(L5_1, L6_1)
end
L4_1 = Config
L4_1 = L4_1.JobChat
if L4_1 then
  L4_1 = RegisterCommand
  L5_1 = Config
  L5_1 = L5_1.JobCommand
  function L6_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
    L3_2 = QBCore
    L3_2 = L3_2.Functions
    L3_2 = L3_2.GetPlayer
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    if not L3_2 then
      return
    end
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = string
    L6_2 = L6_2.len
    L7_2 = Config
    L7_2 = L7_2.JobCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = L2_1
    L7_2 = L3_2
    L8_2 = A0_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = L6_2
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L3_2.PlayerData
    L8_2 = L8_2.job
    L9_2 = L0_1
    L10_2 = A0_2
    L9_2(L10_2)
    L9_2 = isDead
    if L9_2 then
      return
    end
    L9_2 = L1_1
    L10_2 = A0_2
    L11_2 = L5_2
    L9_2 = L9_2(L10_2, L11_2)
    if L9_2 then
      return
    end
    L10_2 = L4_2
    L9_2 = L4_2.gsub
    L11_2 = "%s+"
    L12_2 = ""
    L9_2 = L9_2(L10_2, L11_2, L12_2)
    if "" ~= L9_2 then
      L9_2 = chatsHidden
      L9_2 = L9_2[A0_2]
      if not L9_2 then
        goto lbl_59
      end
    end
    do return end
    ::lbl_59::
    L9_2 = "<div class=\"chat-message jobchat\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.JobIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-info, #4E9CE5)\">["
    L12_2 = L8_2.label
    if not L12_2 then
      L12_2 = L8_2.name
    end
    L13_2 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
    L10_2 = showForJob
    L11_2 = L8_2.name
    function L12_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = L9_2
      L4_3.template = L5_3
      L5_3 = {}
      L6_3 = L6_2
      L7_3 = L4_2
      L8_3 = L5_2
      L5_3[1] = L6_3
      L5_3[2] = L7_3
      L5_3[3] = L8_3
      L4_3.args = L5_3
      L1_3(L2_3, L3_3, L4_3)
    end
    L10_2(L11_2, L12_2)
    L10_2 = Config
    L10_2 = L10_2.ShowIDOnMessage
    if L10_2 then
      L10_2 = showForJobAdmins
      L11_2 = L8_2.name
      function L12_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
        L1_3 = TriggerClientEvent
        L2_3 = "chat:addMessage"
        L3_3 = A0_3
        L4_3 = {}
        L5_3 = L9_2
        L4_3.template = L5_3
        L5_3 = {}
        L6_3 = L7_2
        L7_3 = L4_2
        L8_3 = L5_2
        L5_3[1] = L6_3
        L5_3[2] = L7_3
        L5_3[3] = L8_3
        L4_3.args = L5_3
        L1_3(L2_3, L3_3, L4_3)
      end
      L10_2(L11_2, L12_2)
    end
    L10_2 = L3_1
    L11_2 = A0_2
    L12_2 = "job_chat"
    L13_2 = L4_2
    L14_2 = {}
    L15_2 = L8_2.label
    if not L15_2 then
      L15_2 = L8_2.name
    end
    L14_2.job = L15_2
    L10_2(L11_2, L12_2, L13_2, L14_2)
  end
  L4_1(L5_1, L6_1)
end
