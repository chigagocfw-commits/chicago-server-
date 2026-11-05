local L0_1, L1_1, L2_1, L3_1, L4_1
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
  L2_2 = IsMuted
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
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
    L8_2 = MuteRemaining
    L9_2 = A0_2
    L8_2, L9_2, L10_2 = L8_2(L9_2)
    L7_2 = L7_2(L8_2, L9_2, L10_2)
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
L2_1 = Config
L2_1 = L2_1.EnablePM
if L2_1 then
  L2_1 = RegisterCommand
  L3_1 = Config
  L3_1 = L3_1.PMCommand
  function L4_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
    L2_2 = QBCore
    L2_2 = L2_2.Functions
    L2_2 = L2_2.GetPlayer
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L3_2 = table
    L3_2 = L3_2.concat
    L4_2 = A1_2
    L5_2 = " "
    L6_2 = 2
    L3_2 = L3_2(L4_2, L5_2, L6_2)
    L4_2 = os
    L4_2 = L4_2.date
    L5_2 = Config
    L5_2 = L5_2.DateFormat
    L4_2 = L4_2(L5_2)
    L5_2 = tonumber
    L6_2 = A1_2[1]
    L5_2 = L5_2(L6_2)
    L6_2 = getName
    L7_2 = L2_2
    L6_2 = L6_2(L7_2)
    L7_2 = " ["
    L8_2 = A0_2
    L9_2 = "]"
    L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
    L7_2 = L0_1
    L8_2 = A0_2
    L7_2(L8_2)
    L7_2 = isDead
    if L7_2 then
      return
    end
    L7_2 = L1_1
    L8_2 = A0_2
    L9_2 = L4_2
    L7_2 = L7_2(L8_2, L9_2)
    if L7_2 then
      return
    end
    L8_2 = L3_2
    L7_2 = L3_2.gsub
    L9_2 = "%s+"
    L10_2 = ""
    L7_2 = L7_2(L8_2, L9_2, L10_2)
    if "" == L7_2 then
      return
    end
    if L5_2 == A0_2 then
      L7_2 = TriggerClientEvent
      L8_2 = "okokChat:Notification"
      L9_2 = A0_2
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_id_inv
      L11_2 = Config
      L11_2 = L11_2.NotificationsText
      L11_2 = L11_2.mute_id_inv
      L11_2 = L11_2.message
      L7_2(L8_2, L9_2, L10_2, L11_2)
      return
    end
    L7_2 = QBCore
    L7_2 = L7_2.Functions
    L7_2 = L7_2.GetPlayer
    L8_2 = L5_2
    L7_2 = L7_2(L8_2)
    if not L7_2 then
      L8_2 = TriggerClientEvent
      L9_2 = "okokChat:Notification"
      L10_2 = A0_2
      L11_2 = Config
      L11_2 = L11_2.NotificationsText
      L11_2 = L11_2.mute_id_inv
      L12_2 = Config
      L12_2 = L12_2.NotificationsText
      L12_2 = L12_2.mute_id_inv
      L12_2 = L12_2.message
      L8_2(L9_2, L10_2, L11_2, L12_2)
      return
    end
    L8_2 = getName
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L9_2 = chatsHidden
    L9_2 = L9_2[L5_2]
    if L9_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "okokChat:Notification"
      L11_2 = A0_2
      L12_2 = Config
      L12_2 = L12_2.NotificationsText
      L12_2 = L12_2.is_muted
      L13_2 = Config
      L13_2 = L13_2.NotificationsText
      L13_2 = L13_2.is_muted
      L13_2 = L13_2.message
      L9_2(L10_2, L11_2, L12_2, L13_2)
      return
    end
    L9_2 = "<div class=\"chat-message pm\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.PMIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-brand, #1F5EFF)\">["
    L12_2 = Config
    L12_2 = L12_2.PMMessageTitle
    L13_2 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2 .. L12_2 .. L13_2
    L10_2 = TriggerClientEvent
    L11_2 = "chat:addMessage"
    L12_2 = A0_2
    L13_2 = {}
    L13_2.template = L9_2
    L14_2 = {}
    L15_2 = L6_2
    L16_2 = L3_2
    L17_2 = L4_2
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L13_2.args = L14_2
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = TriggerClientEvent
    L11_2 = "chat:addMessage"
    L12_2 = L5_2
    L13_2 = {}
    L13_2.template = L9_2
    L14_2 = {}
    L15_2 = L6_2
    L16_2 = L3_2
    L17_2 = L4_2
    L14_2[1] = L15_2
    L14_2[2] = L16_2
    L14_2[3] = L17_2
    L13_2.args = L14_2
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = Webhook
    if "" ~= L10_2 then
      L10_2 = ExtractIdentifiers
      L11_2 = A0_2
      L10_2 = L10_2(L11_2)
      L11_2 = discordWebhook
      L12_2 = {}
      L12_2.playerid = A0_2
      L13_2 = L10_2.license
      if not L13_2 then
        L13_2 = ""
      end
      L14_2 = L13_2
      L13_2 = L13_2.gsub
      L15_2 = "license:"
      L16_2 = ""
      L13_2 = L13_2(L14_2, L15_2, L16_2)
      L12_2.identifier = L13_2
      L13_2 = "<@"
      L14_2 = L10_2.discord
      if not L14_2 then
        L14_2 = ""
      end
      L15_2 = L14_2
      L14_2 = L14_2.gsub
      L16_2 = "discord:"
      L17_2 = ""
      L14_2 = L14_2(L15_2, L16_2, L17_2)
      L15_2 = ">"
      L13_2 = L13_2 .. L14_2 .. L15_2
      L12_2.discord = L13_2
      L13_2 = interp
      L14_2 = Config
      L14_2 = L14_2.WebhookText
      L14_2 = L14_2.pm_chat
      L15_2 = {}
      L15_2.name = L8_2
      L15_2.id = L5_2
      L13_2 = L13_2(L14_2, L15_2)
      L12_2.type = L13_2
      L12_2.message = L3_2
      L11_2(L12_2)
    end
  end
  L2_1(L3_1, L4_1)
end
L2_1 = Config
L2_1 = L2_1.EnableOOC
if L2_1 then
  function L2_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
    L2_2 = QBCore
    L2_2 = L2_2.Functions
    L2_2 = L2_2.GetPlayer
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L3_2 = os
    L3_2 = L3_2.date
    L4_2 = Config
    L4_2 = L4_2.DateFormat
    L3_2 = L3_2(L4_2)
    L4_2 = Config
    L4_2 = L4_2.ShowIDOnMessageForEveryone
    if L4_2 then
      L4_2 = getName
      L5_2 = L2_2
      L4_2 = L4_2(L5_2)
      L5_2 = " ["
      L6_2 = A0_2
      L7_2 = "]"
      L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2
      if L4_2 then
        goto lbl_30
      end
    end
    L4_2 = getName
    L5_2 = L2_2
    L4_2 = L4_2(L5_2)
    ::lbl_30::
    L5_2 = L4_2
    L6_2 = " ["
    L7_2 = A0_2
    L8_2 = "]"
    L5_2 = L5_2 .. L6_2 .. L7_2 .. L8_2
    L6_2 = L0_1
    L7_2 = A0_2
    L6_2(L7_2)
    L6_2 = isDead
    if L6_2 then
      return
    end
    L6_2 = L1_1
    L7_2 = A0_2
    L8_2 = L3_2
    L6_2 = L6_2(L7_2, L8_2)
    if L6_2 then
      return
    end
    L7_2 = A1_2
    L6_2 = A1_2.gsub
    L8_2 = "%s+"
    L9_2 = ""
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    if "" ~= L6_2 then
      L6_2 = chatsHidden
      L6_2 = L6_2[A0_2]
      if not L6_2 then
        goto lbl_60
      end
    end
    do return end
    ::lbl_60::
    L6_2 = "<div class=\"chat-message ooc\"><i class=\""
    L7_2 = Config
    L7_2 = L7_2.OOCIcon
    L8_2 = "\"></i> <b><span style=\"color: var(--apex-textSub, rgba(244,244,245,.55))\">["
    L9_2 = Config
    L9_2 = L9_2.OOCMessageTitle
    L10_2 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2
    L7_2 = showToClosePlayers
    L8_2 = A0_2
    function L9_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = L6_2
      L4_3.template = L5_3
      L5_3 = {}
      L6_3 = L4_2
      L7_3 = A1_2
      L8_3 = L3_2
      L5_3[1] = L6_3
      L5_3[2] = L7_3
      L5_3[3] = L8_3
      L4_3.args = L5_3
      L1_3(L2_3, L3_3, L4_3)
    end
    L7_2(L8_2, L9_2)
    L7_2 = Config
    L7_2 = L7_2.ShowIDOnMessage
    if L7_2 then
      L7_2 = showToClosePlayersAdmins
      L8_2 = A0_2
      function L9_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
        L1_3 = TriggerClientEvent
        L2_3 = "chat:addMessage"
        L3_3 = A0_3
        L4_3 = {}
        L5_3 = L6_2
        L4_3.template = L5_3
        L5_3 = {}
        L6_3 = L5_2
        L7_3 = A1_2
        L8_3 = L3_2
        L5_3[1] = L6_3
        L5_3[2] = L7_3
        L5_3[3] = L8_3
        L4_3.args = L5_3
        L1_3(L2_3, L3_3, L4_3)
      end
      L7_2(L8_2, L9_2)
    end
    L7_2 = Webhook
    if "" ~= L7_2 then
      L7_2 = ExtractIdentifiers
      L8_2 = A0_2
      L7_2 = L7_2(L8_2)
      L8_2 = discordWebhook
      L9_2 = {}
      L9_2.playerid = A0_2
      L10_2 = L7_2.license
      if not L10_2 then
        L10_2 = ""
      end
      L11_2 = L10_2
      L10_2 = L10_2.gsub
      L12_2 = "license:"
      L13_2 = ""
      L10_2 = L10_2(L11_2, L12_2, L13_2)
      L9_2.identifier = L10_2
      L10_2 = "<@"
      L11_2 = L7_2.discord
      if not L11_2 then
        L11_2 = ""
      end
      L12_2 = L11_2
      L11_2 = L11_2.gsub
      L13_2 = "discord:"
      L14_2 = ""
      L11_2 = L11_2(L12_2, L13_2, L14_2)
      L12_2 = ">"
      L10_2 = L10_2 .. L11_2 .. L12_2
      L9_2.discord = L10_2
      L10_2 = Config
      L10_2 = L10_2.WebhookText
      L10_2 = L10_2.ooc
      L9_2.type = L10_2
      L9_2.message = A1_2
      L8_2(L9_2)
    end
  end
  OOC = L2_1
  L2_1 = RegisterCommand
  L3_1 = Config
  L3_1 = L3_1.OOCCommand
  function L4_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2
    L4_2 = A2_2
    L3_2 = A2_2.sub
    L5_2 = string
    L5_2 = L5_2.len
    L6_2 = Config
    L6_2 = L6_2.OOCCommand
    L5_2 = L5_2(L6_2)
    L5_2 = L5_2 + 1
    L3_2 = L3_2(L4_2, L5_2)
    L4_2 = OOC
    L5_2 = A0_2
    L6_2 = L3_2
    L4_2(L5_2, L6_2)
  end
  L2_1(L3_1, L4_1)
end
