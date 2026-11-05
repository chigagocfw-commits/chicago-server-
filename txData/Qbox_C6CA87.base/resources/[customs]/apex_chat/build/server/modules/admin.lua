local L0_1, L1_1, L2_1, L3_1
function L0_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2
  L3_2 = Config
  L3_2 = L3_2.StaffSteamName
  if L3_2 then
    L3_2 = getSteamName
    L4_2 = A0_2
    return L3_2(L4_2)
  end
  L3_2 = Config
  L3_2 = L3_2.ShowIDOnMessageForEveryone
  if L3_2 or A2_2 then
    L3_2 = getName
    L4_2 = A0_2
    L3_2 = L3_2(L4_2)
    L4_2 = " ["
    L5_2 = A1_2
    L6_2 = "]"
    L3_2 = L3_2 .. L4_2 .. L5_2 .. L6_2
    return L3_2
  end
  L3_2 = getName
  L4_2 = A0_2
  return L3_2(L4_2)
end
L1_1 = Config
L1_1 = L1_1.EnableStaffCommand
if L1_1 then
  L1_1 = RegisterCommand
  L2_1 = Config
  L2_1 = L2_1.StaffCommand
  function L3_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
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
    L7_2 = L7_2.StaffCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L6_2 = L4_2
    L5_2 = L4_2.gsub
    L7_2 = "%s+"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "" ~= L5_2 then
      L5_2 = isAdmin
      L6_2 = L3_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        goto lbl_30
      end
    end
    do return end
    ::lbl_30::
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = L0_1
    L7_2 = L3_2
    L8_2 = A0_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = showToEveryoneNotHidden
    function L8_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = "<div class=\"chat-message staff\"><i class=\""
      L6_3 = Config
      L6_3 = L6_3.StaffIcon
      L7_3 = "\" style=\"vertical-align: middle;\"></i> <span style=\"vertical-align: middle;\"><b><span style=\"color: var(--apex-success, #34C77B);\">["
      L8_3 = Config
      L8_3 = L8_3.StaffMessageTitle
      L9_3 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b></span><div class=\"message\">{1}</div></div>"
      L5_3 = L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
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
    L7_2(L8_2)
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
      L10_2 = L10_2.staff_msg
      L9_2.type = L10_2
      L9_2.message = L4_2
      L8_2(L9_2)
    end
  end
  L1_1(L2_1, L3_1)
end
L1_1 = Config
L1_1 = L1_1.EnableStaffOnlyCommand
if L1_1 then
  L1_1 = RegisterCommand
  L2_1 = Config
  L2_1 = L2_1.StaffOnlyCommand
  function L3_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
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
    L7_2 = L7_2.StaffOnlyCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L6_2 = L4_2
    L5_2 = L4_2.gsub
    L7_2 = "%s+"
    L8_2 = ""
    L5_2 = L5_2(L6_2, L7_2, L8_2)
    if "" ~= L5_2 then
      L5_2 = isAdmin
      L6_2 = L3_2
      L5_2 = L5_2(L6_2)
      if L5_2 then
        L5_2 = chatsHidden
        L5_2 = L5_2[A0_2]
        if not L5_2 then
          goto lbl_34
        end
      end
    end
    do return end
    ::lbl_34::
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = L0_1
    L7_2 = L3_2
    L8_2 = A0_2
    L6_2 = L6_2(L7_2, L8_2)
    L7_2 = showOnlyForAdmins
    function L8_2(A0_3)
      local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
      L1_3 = TriggerClientEvent
      L2_3 = "chat:addMessage"
      L3_3 = A0_3
      L4_3 = {}
      L5_3 = "<div class=\"chat-message staffonly\"><i class=\""
      L6_3 = Config
      L6_3 = L6_3.StaffOnlyIcon
      L7_3 = "\"></i> <b><span style=\"color: var(--apex-text, #F4F4F5)\">["
      L8_3 = Config
      L8_3 = L8_3.StaffOnlyMessageTitle
      L9_3 = "] {0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
      L5_3 = L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
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
    L7_2(L8_2)
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
      L10_2 = L10_2.staff_chat_msg
      L9_2.type = L10_2
      L9_2.message = L4_2
      L8_2(L9_2)
    end
  end
  L1_1(L2_1, L3_1)
end
L1_1 = Config
L1_1 = L1_1.EnableServerAnnouncement
if L1_1 then
  L1_1 = RegisterCommand
  L2_1 = Config
  L2_1 = L2_1.ServerAnnouncementCommand
  function L3_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
    if A0_2 > 0 then
      L3_2 = QBCore
      L3_2 = L3_2.Functions
      L3_2 = L3_2.GetPlayer
      L4_2 = A0_2
      L3_2 = L3_2(L4_2)
      if L3_2 then
        goto lbl_11
      end
    end
    L3_2 = nil
    ::lbl_11::
    L5_2 = A2_2
    L4_2 = A2_2.sub
    L6_2 = string
    L6_2 = L6_2.len
    L7_2 = Config
    L7_2 = L7_2.ServerAnnouncementCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    if A0_2 > 0 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:checkDeathStatus"
      L8_2 = A0_2
      L6_2(L7_2, L8_2)
      while true do
        L6_2 = checkedDeathStatus
        if L6_2 then
          break
        end
        L6_2 = Citizen
        L6_2 = L6_2.Wait
        L7_2 = 5
        L6_2(L7_2)
      end
      checkedDeathStatus = false
      L6_2 = isDead
      if L6_2 then
        return
      end
    end
    L7_2 = L4_2
    L6_2 = L4_2.gsub
    L8_2 = "%s+"
    L9_2 = ""
    L6_2 = L6_2(L7_2, L8_2, L9_2)
    if "" == L6_2 then
      return
    end
    function L6_2()
      local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3
      L0_3 = TriggerClientEvent
      L1_3 = "chat:addMessage"
      L2_3 = -1
      L3_3 = {}
      L4_3 = "<div class=\"chat-message server-msg\"><i class=\""
      L5_3 = Config
      L5_3 = L5_3.AnnouncementIcon
      L6_3 = "\" style=\"vertical-align: middle;\"></i> <span style=\"vertical-align: middle;\"><b><span style=\"color: var(--apex-error, #E5564B);\">["
      L7_3 = Config
      L7_3 = L7_3.AnnouncementMessageTitle
      L8_3 = "]</span>&nbsp;<span class=\"time\">{1}</span></b></span><div class=\"message\">{0}</div></div>"
      L4_3 = L4_3 .. L5_3 .. L6_3 .. L7_3 .. L8_3
      L3_3.template = L4_3
      L4_3 = {}
      L5_3 = L4_2
      L6_3 = L5_2
      L4_3[1] = L5_3
      L4_3[2] = L6_3
      L3_3.args = L4_3
      L0_3(L1_3, L2_3, L3_3)
    end
    if A0_2 <= 0 then
      L7_2 = L6_2
      L7_2()
    else
      L7_2 = isAdmin
      L8_2 = L3_2
      L7_2 = L7_2(L8_2)
      if L7_2 then
        L7_2 = L6_2
        L7_2()
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
          L10_2 = L10_2.sv_an
          L9_2.type = L10_2
          L9_2.message = L4_2
          L8_2(L9_2)
        end
      end
    end
  end
  L1_1(L2_1, L3_1)
end
L1_1 = Config
L1_1 = L1_1.TimeOutPlayers
if L1_1 then
  L1_1 = RegisterCommand
  L2_1 = Config
  L2_1 = L2_1.TimeOutCommand
  function L3_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
    L2_2 = QBCore
    L2_2 = L2_2.Functions
    L2_2 = L2_2.GetPlayer
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L3_2 = tonumber
    L4_2 = A1_2[1]
    L3_2 = L3_2(L4_2)
    L4_2 = tonumber
    L5_2 = A1_2[2]
    L4_2 = L4_2(L5_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = isAdmin
    L7_2 = L2_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_not_adm
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_not_adm
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    if not L3_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_id_inv
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_id_inv
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    if not L4_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_time_inv
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_time_inv
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    if L3_2 == A0_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_id_inv
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_id_inv
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    L6_2 = QBCore
    L6_2 = L6_2.Functions
    L6_2 = L6_2.GetPlayer
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    if not L6_2 then
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
    L7_2 = mutedList
    L7_2 = L7_2[L3_2]
    if L7_2 then
      L7_2 = TriggerClientEvent
      L8_2 = "okokChat:Notification"
      L9_2 = A0_2
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.alr_muted
      L11_2 = Config
      L11_2 = L11_2.NotificationsText
      L11_2 = L11_2.alr_muted
      L11_2 = L11_2.message
      L7_2(L8_2, L9_2, L10_2, L11_2)
      return
    end
    L7_2 = getName
    L8_2 = L6_2
    L7_2 = L7_2(L8_2)
    L8_2 = mutedList
    L9_2 = {}
    L10_2 = os
    L10_2 = L10_2.time
    L10_2 = L10_2()
    L11_2 = L4_2 * 60
    L10_2 = L10_2 + L11_2
    L9_2.expires = L10_2
    L8_2[L3_2] = L9_2
    L8_2 = Config
    L8_2 = L8_2.ShowTimeOutMessageForEveryone
    if L8_2 then
      L8_2 = showMuteMessageToEveryone
      L9_2 = L3_2
      function L10_2(A0_3)
        local L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
        L1_3 = TriggerClientEvent
        L2_3 = "chat:addMessage"
        L3_3 = A0_3
        L4_3 = {}
        L5_3 = "<div class=\"chat-message muted\"><i class=\""
        L6_3 = Config
        L6_3 = L6_3.TimeOutIcon
        L7_3 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">"
        L8_3 = Config
        L8_3 = L8_3.TimeOutMessages
        L8_3 = L8_3.muted_for
        L9_3 = "</div></div>"
        L5_3 = L5_3 .. L6_3 .. L7_3 .. L8_3 .. L9_3
        L4_3.template = L5_3
        L5_3 = {}
        L6_3 = Config
        L6_3 = L6_3.MessageTitle
        L7_3 = L4_2
        L8_3 = L5_2
        L9_3 = L7_2
        L5_3[1] = L6_3
        L5_3[2] = L7_3
        L5_3[3] = L8_3
        L5_3[4] = L9_3
        L4_3.args = L5_3
        L1_3(L2_3, L3_3, L4_3)
      end
      L8_2(L9_2, L10_2)
    else
      L8_2 = TriggerClientEvent
      L9_2 = "chat:addMessage"
      L10_2 = A0_2
      L11_2 = {}
      L12_2 = "<div class=\"chat-message muted\"><i class=\""
      L13_2 = Config
      L13_2 = L13_2.TimeOutIcon
      L14_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">"
      L15_2 = Config
      L15_2 = L15_2.TimeOutMessages
      L15_2 = L15_2.you_muted_for
      L16_2 = "</div></div>"
      L12_2 = L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2
      L11_2.template = L12_2
      L12_2 = {}
      L13_2 = Config
      L13_2 = L13_2.MessageTitle
      L14_2 = L4_2
      L15_2 = L5_2
      L16_2 = L7_2
      L12_2[1] = L13_2
      L12_2[2] = L14_2
      L12_2[3] = L15_2
      L12_2[4] = L16_2
      L11_2.args = L12_2
      L8_2(L9_2, L10_2, L11_2)
    end
    L8_2 = TriggerClientEvent
    L9_2 = "chat:addMessage"
    L10_2 = L3_2
    L11_2 = {}
    L12_2 = "<div class=\"chat-message muted\"><i class=\""
    L13_2 = Config
    L13_2 = L13_2.TimeOutIcon
    L14_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">SERVER</span>&nbsp;<span class=\"time\">{1}</span></b><div class=\"message\">"
    L15_2 = Config
    L15_2 = L15_2.TimeOutMessages
    L15_2 = L15_2.been_muted_for
    L16_2 = "</div></div>"
    L12_2 = L12_2 .. L13_2 .. L14_2 .. L15_2 .. L16_2
    L11_2.template = L12_2
    L12_2 = {}
    L13_2 = L4_2
    L14_2 = L5_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L11_2.args = L12_2
    L8_2(L9_2, L10_2, L11_2)
    L8_2 = Webhook
    if "" ~= L8_2 then
      L8_2 = ExtractIdentifiers
      L9_2 = A0_2
      L8_2 = L8_2(L9_2)
      L9_2 = discordWebhook
      L10_2 = {}
      L10_2.playerid = A0_2
      L11_2 = L8_2.license
      if not L11_2 then
        L11_2 = ""
      end
      L12_2 = L11_2
      L11_2 = L11_2.gsub
      L13_2 = "license:"
      L14_2 = ""
      L11_2 = L11_2(L12_2, L13_2, L14_2)
      L10_2.identifier = L11_2
      L11_2 = "<@"
      L12_2 = L8_2.discord
      if not L12_2 then
        L12_2 = ""
      end
      L13_2 = L12_2
      L12_2 = L12_2.gsub
      L14_2 = "discord:"
      L15_2 = ""
      L12_2 = L12_2(L13_2, L14_2, L15_2)
      L13_2 = ">"
      L11_2 = L11_2 .. L12_2 .. L13_2
      L10_2.discord = L11_2
      L11_2 = interp
      L12_2 = Config
      L12_2 = L12_2.WebhookText
      L12_2 = L12_2.muted
      L13_2 = {}
      L13_2.id = L3_2
      L11_2 = L11_2(L12_2, L13_2)
      L10_2.type = L11_2
      L11_2 = interp
      L12_2 = Config
      L12_2 = L12_2.WebhookText
      L12_2 = L12_2.muted_for
      L13_2 = {}
      L13_2.muteTime = L4_2
      L11_2 = L11_2(L12_2, L13_2)
      L10_2.message = L11_2
      L9_2(L10_2)
    end
  end
  L1_1(L2_1, L3_1)
  L1_1 = RegisterCommand
  L2_1 = Config
  L2_1 = L2_1.RemoveTimeOutCommand
  function L3_1(A0_2, A1_2)
    local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2
    L2_2 = QBCore
    L2_2 = L2_2.Functions
    L2_2 = L2_2.GetPlayer
    L3_2 = A0_2
    L2_2 = L2_2(L3_2)
    if not L2_2 then
      return
    end
    L3_2 = tonumber
    L4_2 = A1_2[1]
    L3_2 = L3_2(L4_2)
    L4_2 = os
    L4_2 = L4_2.date
    L5_2 = Config
    L5_2 = L5_2.DateFormat
    L4_2 = L4_2(L5_2)
    L5_2 = isAdmin
    L6_2 = L2_2
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L5_2 = TriggerClientEvent
      L6_2 = "okokChat:Notification"
      L7_2 = A0_2
      L8_2 = Config
      L8_2 = L8_2.NotificationsText
      L8_2 = L8_2.mute_not_adm
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_not_adm
      L9_2 = L9_2.message
      L5_2(L6_2, L7_2, L8_2, L9_2)
      return
    end
    if not L3_2 or L3_2 == A0_2 then
      L5_2 = TriggerClientEvent
      L6_2 = "okokChat:Notification"
      L7_2 = A0_2
      L8_2 = Config
      L8_2 = L8_2.NotificationsText
      L8_2 = L8_2.mute_id_inv
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_id_inv
      L9_2 = L9_2.message
      L5_2(L6_2, L7_2, L8_2, L9_2)
      return
    end
    L5_2 = QBCore
    L5_2 = L5_2.Functions
    L5_2 = L5_2.GetPlayer
    L6_2 = L3_2
    L5_2 = L5_2(L6_2)
    if not L5_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.mute_id_inv
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.mute_id_inv
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    L6_2 = mutedList
    L6_2 = L6_2[L3_2]
    if not L6_2 then
      L6_2 = TriggerClientEvent
      L7_2 = "okokChat:Notification"
      L8_2 = A0_2
      L9_2 = Config
      L9_2 = L9_2.NotificationsText
      L9_2 = L9_2.alr_unmuted
      L10_2 = Config
      L10_2 = L10_2.NotificationsText
      L10_2 = L10_2.alr_unmuted
      L10_2 = L10_2.message
      L6_2(L7_2, L8_2, L9_2, L10_2)
      return
    end
    L6_2 = getName
    L7_2 = L5_2
    L6_2 = L6_2(L7_2)
    L7_2 = TriggerClientEvent
    L8_2 = "chat:addMessage"
    L9_2 = A0_2
    L10_2 = {}
    L11_2 = "<div class=\"chat-message muted\"><i class=\""
    L12_2 = Config
    L12_2 = L12_2.TimeOutIcon
    L13_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">{0}</span>&nbsp;<span class=\"time\">{1}</span></b><div class=\"message\">"
    L14_2 = Config
    L14_2 = L14_2.TimeOutMessages
    L14_2 = L14_2.you_unmuted
    L15_2 = "</div></div>"
    L11_2 = L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2
    L10_2.template = L11_2
    L11_2 = {}
    L12_2 = Config
    L12_2 = L12_2.MessageTitle
    L13_2 = L4_2
    L14_2 = L6_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L10_2.args = L11_2
    L7_2(L8_2, L9_2, L10_2)
    L7_2 = TriggerClientEvent
    L8_2 = "chat:addMessage"
    L9_2 = L3_2
    L10_2 = {}
    L11_2 = "<div class=\"chat-message muted\"><i class=\""
    L12_2 = Config
    L12_2 = L12_2.TimeOutIcon
    L13_2 = "\"></i> <b><span style=\"color: var(--apex-warning, #E5A93C)\">{0}</span>&nbsp;<span class=\"time\">{1}</span></b><div class=\"message\">"
    L14_2 = Config
    L14_2 = L14_2.TimeOutMessages
    L14_2 = L14_2.been_unmuted
    L15_2 = "</div></div>"
    L11_2 = L11_2 .. L12_2 .. L13_2 .. L14_2 .. L15_2
    L10_2.template = L11_2
    L11_2 = {}
    L12_2 = Config
    L12_2 = L12_2.MessageTitle
    L13_2 = L4_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L10_2.args = L11_2
    L7_2(L8_2, L9_2, L10_2)
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
      L10_2 = interp
      L11_2 = Config
      L11_2 = L11_2.WebhookText
      L11_2 = L11_2.unmuted
      L12_2 = {}
      L12_2.id = L3_2
      L10_2 = L10_2(L11_2, L12_2)
      L9_2.type = L10_2
      L10_2 = Config
      L10_2 = L10_2.WebhookText
      L10_2 = L10_2.p_unmuted
      L9_2.message = L10_2
      L8_2(L9_2)
    end
    L7_2 = mutedList
    L7_2[L3_2] = nil
  end
  L1_1(L2_1, L3_1)
end
