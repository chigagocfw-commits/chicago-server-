local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
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
function L2_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2
  L2_2 = ipairs
  L3_2 = A1_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = ipairs
    L9_2 = GetPlayerIdentifiers
    L10_2 = A0_2
    L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2 = L9_2(L10_2)
    L8_2, L9_2, L10_2, L11_2 = L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2)
    for L12_2, L13_2 in L8_2, L9_2, L10_2, L11_2 do
      L14_2 = string
      L14_2 = L14_2.lower
      L15_2 = L13_2
      L14_2 = L14_2(L15_2)
      L15_2 = string
      L15_2 = L15_2.lower
      L16_2 = L7_2
      L15_2 = L15_2(L16_2)
      if L14_2 == L15_2 then
        L14_2 = true
        return L14_2
      end
    end
  end
  L2_2 = false
  return L2_2
end
function L3_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = showAll
  function L3_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = TriggerClientEvent
    L2_3 = "chat:addMessage"
    L3_3 = A0_3
    L4_3 = {}
    L5_3 = A0_2
    L4_3.template = L5_3
    L5_3 = A1_2
    L4_3.args = L5_3
    L1_3(L2_3, L3_3, L4_3)
  end
  L2_2(L3_2)
end
function L4_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = Config
  L2_2 = L2_2.ShowIDOnMessage
  if not L2_2 then
    return
  end
  L2_2 = showOnlyForAdmins
  function L3_2(A0_3)
    local L1_3, L2_3, L3_3, L4_3, L5_3
    L1_3 = TriggerClientEvent
    L2_3 = "chat:addMessage"
    L3_3 = A0_3
    L4_3 = {}
    L5_3 = A0_2
    L4_3.template = L5_3
    L5_3 = A1_2
    L4_3.args = L5_3
    L1_3(L2_3, L3_3, L4_3)
  end
  L2_2(L3_2)
end
function L5_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L3_2 = Webhook
  if "" == L3_2 then
    return
  end
  L3_2 = ExtractIdentifiers
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  L4_2 = discordWebhook
  L5_2 = {}
  L5_2.playerid = A0_2
  L6_2 = L3_2.license
  if not L6_2 then
    L6_2 = ""
  end
  L7_2 = L6_2
  L6_2 = L6_2.gsub
  L8_2 = "license:"
  L9_2 = ""
  L6_2 = L6_2(L7_2, L8_2, L9_2)
  L5_2.identifier = L6_2
  L6_2 = "<@"
  L7_2 = L3_2.discord
  if not L7_2 then
    L7_2 = ""
  end
  L8_2 = L7_2
  L7_2 = L7_2.gsub
  L9_2 = "discord:"
  L10_2 = ""
  L7_2 = L7_2(L8_2, L9_2, L10_2)
  L8_2 = ">"
  L6_2 = L6_2 .. L7_2 .. L8_2
  L5_2.discord = L6_2
  L6_2 = Config
  L6_2 = L6_2.WebhookText
  L6_2 = L6_2[A1_2]
  L5_2.type = L6_2
  L5_2.message = A2_2
  L4_2(L5_2)
end
L6_1 = Config
L6_1 = L6_1.EnableTwitchCommand
if L6_1 then
  L6_1 = RegisterCommand
  L7_1 = Config
  L7_1 = L7_1.TwitchCommand
  function L8_1(A0_2, A1_2, A2_2)
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
    L7_2 = L7_2.TwitchCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.ShowIDOnMessageForEveryone
    if L6_2 then
      L6_2 = getName
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      L7_2 = " ["
      L8_2 = A0_2
      L9_2 = "]"
      L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
      if L6_2 then
        goto lbl_39
      end
    end
    L6_2 = getName
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    ::lbl_39::
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L0_1
    L9_2 = A0_2
    L8_2(L9_2)
    L8_2 = isDead
    if L8_2 then
      return
    end
    L8_2 = L1_1
    L9_2 = A0_2
    L10_2 = L5_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      return
    end
    L9_2 = L4_2
    L8_2 = L4_2.gsub
    L10_2 = "%s+"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    if "" ~= L8_2 then
      L8_2 = chatsHidden
      L8_2 = L8_2[A0_2]
      if not L8_2 then
        goto lbl_71
      end
    end
    do return end
    ::lbl_71::
    L8_2 = L2_1
    L9_2 = A0_2
    L10_2 = Config
    L10_2 = L10_2.TwitchList
    L8_2 = L8_2(L9_2, L10_2)
    if not L8_2 then
      return
    end
    L8_2 = "<div class=\"chat-message twitch\"><i class=\""
    L9_2 = Config
    L9_2 = L9_2.TwitchIcon
    L10_2 = "\"></i> <b><span style=\"color: var(--apex-twitch, #9c70de)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L9_2 = L3_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L6_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L4_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L7_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L5_1
    L10_2 = A0_2
    L11_2 = "twitch"
    L12_2 = L4_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L6_1(L7_1, L8_1)
end
L6_1 = Config
L6_1 = L6_1.EnableYoutubeCommand
if L6_1 then
  L6_1 = RegisterCommand
  L7_1 = Config
  L7_1 = L7_1.YoutubeCommand
  function L8_1(A0_2, A1_2, A2_2)
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
    L7_2 = L7_2.YoutubeCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.ShowIDOnMessageForEveryone
    if L6_2 then
      L6_2 = getName
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      L7_2 = " ["
      L8_2 = A0_2
      L9_2 = "]"
      L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
      if L6_2 then
        goto lbl_39
      end
    end
    L6_2 = getName
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    ::lbl_39::
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L0_1
    L9_2 = A0_2
    L8_2(L9_2)
    L8_2 = isDead
    if L8_2 then
      return
    end
    L8_2 = L1_1
    L9_2 = A0_2
    L10_2 = L5_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      return
    end
    L9_2 = L4_2
    L8_2 = L4_2.gsub
    L10_2 = "%s+"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    if "" ~= L8_2 then
      L8_2 = chatsHidden
      L8_2 = L8_2[A0_2]
      if not L8_2 then
        goto lbl_71
      end
    end
    do return end
    ::lbl_71::
    L8_2 = L2_1
    L9_2 = A0_2
    L10_2 = Config
    L10_2 = L10_2.YoutubeList
    L8_2 = L8_2(L9_2, L10_2)
    if not L8_2 then
      return
    end
    L8_2 = "<div class=\"chat-message youtube\"><i class=\""
    L9_2 = Config
    L9_2 = L9_2.YoutubeIcon
    L10_2 = "\"></i> <b><span style=\"color: var(--apex-youtube, #ff3030)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L9_2 = L3_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L6_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L4_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L7_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L5_1
    L10_2 = A0_2
    L11_2 = "youtube"
    L12_2 = L4_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L6_1(L7_1, L8_1)
end
L6_1 = Config
L6_1 = L6_1.EnableTwitterCommand
if L6_1 then
  L6_1 = RegisterCommand
  L7_1 = Config
  L7_1 = L7_1.TwitterCommand
  function L8_1(A0_2, A1_2, A2_2)
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
    L7_2 = L7_2.TwitterCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.ShowIDOnMessageForEveryone
    if L6_2 then
      L6_2 = getName
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      L7_2 = " ["
      L8_2 = A0_2
      L9_2 = "]"
      L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
      if L6_2 then
        goto lbl_39
      end
    end
    L6_2 = getName
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    ::lbl_39::
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L0_1
    L9_2 = A0_2
    L8_2(L9_2)
    L8_2 = isDead
    if L8_2 then
      return
    end
    L8_2 = L1_1
    L9_2 = A0_2
    L10_2 = L5_2
    L8_2 = L8_2(L9_2, L10_2)
    if L8_2 then
      return
    end
    L9_2 = L4_2
    L8_2 = L4_2.gsub
    L10_2 = "%s+"
    L11_2 = ""
    L8_2 = L8_2(L9_2, L10_2, L11_2)
    if "" ~= L8_2 then
      L8_2 = chatsHidden
      L8_2 = L8_2[A0_2]
      if not L8_2 then
        goto lbl_71
      end
    end
    do return end
    ::lbl_71::
    L8_2 = "<div class=\"chat-message twitter\"><i class=\""
    L9_2 = Config
    L9_2 = L9_2.TwitterIcon
    L10_2 = "\"></i> <b><span style=\"color: var(--text, #C9CDD1)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L8_2 = L8_2 .. L9_2 .. L10_2
    L9_2 = L3_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L6_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L4_1
    L10_2 = L8_2
    L11_2 = {}
    L12_2 = L7_2
    L13_2 = L4_2
    L14_2 = L5_2
    L11_2[1] = L12_2
    L11_2[2] = L13_2
    L11_2[3] = L14_2
    L9_2(L10_2, L11_2)
    L9_2 = L5_1
    L10_2 = A0_2
    L11_2 = "twitter"
    L12_2 = L4_2
    L9_2(L10_2, L11_2, L12_2)
  end
  L6_1(L7_1, L8_1)
end
L6_1 = Config
L6_1 = L6_1.EnableAdvertisementCommand
if L6_1 then
  L6_1 = RegisterCommand
  L7_1 = Config
  L7_1 = L7_1.AdvertisementCommand
  function L8_1(A0_2, A1_2, A2_2)
    local L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
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
    L7_2 = L7_2.AdvertisementCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = Config
    L6_2 = L6_2.ShowIDOnMessageForEveryone
    if L6_2 then
      L6_2 = getName
      L7_2 = L3_2
      L6_2 = L6_2(L7_2)
      L7_2 = " ["
      L8_2 = A0_2
      L9_2 = "]"
      L6_2 = L6_2 .. L7_2 .. L8_2 .. L9_2
      if L6_2 then
        goto lbl_39
      end
    end
    L6_2 = getName
    L7_2 = L3_2
    L6_2 = L6_2(L7_2)
    ::lbl_39::
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L3_2.PlayerData
    L8_2 = L8_2.money
    L8_2 = L8_2.bank
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
        goto lbl_74
      end
    end
    do return end
    ::lbl_74::
    L9_2 = adsList
    L9_2 = L9_2[A0_2]
    if L9_2 then
      L9_2 = os
      L9_2 = L9_2.time
      L9_2 = L9_2()
      L10_2 = adsList
      L10_2 = L10_2[A0_2]
      L10_2 = L10_2.expires
      if L9_2 < L10_2 then
        L9_2 = TriggerClientEvent
        L10_2 = "okokChat:Notification"
        L11_2 = A0_2
        L12_2 = Config
        L12_2 = L12_2.NotificationsText
        L12_2 = L12_2.ad_too_quick
        L13_2 = Config
        L13_2 = L13_2.NotificationsText
        L13_2 = L13_2.ad_too_quick
        L13_2 = L13_2.message
        L9_2(L10_2, L11_2, L12_2, L13_2)
        return
      end
    end
    L9_2 = Config
    L9_2 = L9_2.AdvertisementPrice
    if L8_2 < L9_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "okokChat:Notification"
      L11_2 = A0_2
      L12_2 = Config
      L12_2 = L12_2.NotificationsText
      L12_2 = L12_2.ad_no_money
      L13_2 = Config
      L13_2 = L13_2.NotificationsText
      L13_2 = L13_2.ad_no_money
      L13_2 = L13_2.message
      L9_2(L10_2, L11_2, L12_2, L13_2)
      return
    end
    L9_2 = L3_2.Functions
    L9_2 = L9_2.RemoveMoney
    L10_2 = "bank"
    L11_2 = Config
    L11_2 = L11_2.AdvertisementPrice
    L9_2(L10_2, L11_2)
    L9_2 = "<div class=\"chat-message advertisement\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.AdvertisementIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-success, #34C77B)\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L10_2 = L3_1
    L11_2 = L9_2
    L12_2 = {}
    L13_2 = L6_2
    L14_2 = L4_2
    L15_2 = L5_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L10_2(L11_2, L12_2)
    L10_2 = L4_1
    L11_2 = L9_2
    L12_2 = {}
    L13_2 = L7_2
    L14_2 = L4_2
    L15_2 = L5_2
    L12_2[1] = L13_2
    L12_2[2] = L14_2
    L12_2[3] = L15_2
    L10_2(L11_2, L12_2)
    L10_2 = L5_1
    L11_2 = A0_2
    L12_2 = "ad"
    L13_2 = L4_2
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = TriggerClientEvent
    L11_2 = "okokChat:Notification"
    L12_2 = A0_2
    L13_2 = Config
    L13_2 = L13_2.NotificationsText
    L13_2 = L13_2.ad_success
    L14_2 = interp
    L15_2 = Config
    L15_2 = L15_2.NotificationsText
    L15_2 = L15_2.ad_success
    L15_2 = L15_2.message
    L16_2 = {}
    L17_2 = Config
    L17_2 = L17_2.AdvertisementPrice
    L16_2.price = L17_2
    L14_2, L15_2, L16_2, L17_2 = L14_2(L15_2, L16_2)
    L10_2(L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
    L10_2 = adsList
    L11_2 = {}
    L12_2 = os
    L12_2 = L12_2.time
    L12_2 = L12_2()
    L13_2 = Config
    L13_2 = L13_2.AdvertisementCooldown
    L13_2 = L13_2 * 60
    L12_2 = L12_2 + L13_2
    L11_2.expires = L12_2
    L10_2[A0_2] = L11_2
  end
  L6_1(L7_1, L8_1)
end
L6_1 = Config
L6_1 = L6_1.EnableAnonymousCommand
if L6_1 then
  L6_1 = RegisterCommand
  L7_1 = Config
  L7_1 = L7_1.AnonymousCommand
  function L8_1(A0_2, A1_2, A2_2)
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
    L7_2 = L7_2.AnonymousCommand
    L6_2 = L6_2(L7_2)
    L6_2 = L6_2 + 1
    L4_2 = L4_2(L5_2, L6_2)
    L5_2 = os
    L5_2 = L5_2.date
    L6_2 = Config
    L6_2 = L6_2.DateFormat
    L5_2 = L5_2(L6_2)
    L6_2 = "Anonymous"
    L7_2 = getName
    L8_2 = L3_2
    L7_2 = L7_2(L8_2)
    L8_2 = " ["
    L9_2 = A0_2
    L10_2 = "]"
    L7_2 = L7_2 .. L8_2 .. L9_2 .. L10_2
    L8_2 = L3_2.PlayerData
    L8_2 = L8_2.money
    L8_2 = L8_2.bank
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
    L9_2 = isAnonymousChatBlacklisted
    L10_2 = L3_2
    L9_2 = L9_2(L10_2)
    if L9_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "okokChat:Notification"
      L11_2 = A0_2
      L12_2 = Config
      L12_2 = L12_2.NotificationsText
      L12_2 = L12_2.an_not_allowed
      L13_2 = Config
      L13_2 = L13_2.NotificationsText
      L13_2 = L13_2.an_not_allowed
      L13_2 = L13_2.message
      L9_2(L10_2, L11_2, L12_2, L13_2)
      return
    end
    L9_2 = anonymousList
    L9_2 = L9_2[A0_2]
    if L9_2 then
      L9_2 = os
      L9_2 = L9_2.time
      L9_2 = L9_2()
      L10_2 = anonymousList
      L10_2 = L10_2[A0_2]
      L10_2 = L10_2.expires
      if L9_2 < L10_2 then
        L9_2 = TriggerClientEvent
        L10_2 = "okokChat:Notification"
        L11_2 = A0_2
        L12_2 = Config
        L12_2 = L12_2.NotificationsText
        L12_2 = L12_2.an_too_quick
        L13_2 = Config
        L13_2 = L13_2.NotificationsText
        L13_2 = L13_2.an_too_quick
        L13_2 = L13_2.message
        L9_2(L10_2, L11_2, L12_2, L13_2)
        return
      end
    end
    L9_2 = Config
    L9_2 = L9_2.AnonymousPrice
    if L8_2 < L9_2 then
      L9_2 = TriggerClientEvent
      L10_2 = "okokChat:Notification"
      L11_2 = A0_2
      L12_2 = Config
      L12_2 = L12_2.NotificationsText
      L12_2 = L12_2.an_no_money
      L13_2 = Config
      L13_2 = L13_2.NotificationsText
      L13_2 = L13_2.an_no_money
      L13_2 = L13_2.message
      L9_2(L10_2, L11_2, L12_2, L13_2)
      return
    end
    L9_2 = L3_2.Functions
    L9_2 = L9_2.RemoveMoney
    L10_2 = "bank"
    L11_2 = Config
    L11_2 = L11_2.AnonymousPrice
    L9_2(L10_2, L11_2)
    L9_2 = "<div class=\"chat-message anonymous\"><i class=\""
    L10_2 = Config
    L10_2 = L10_2.AnonymousIcon
    L11_2 = "\"></i> <b><span style=\"color: var(--apex-textSub, rgba(244,244,245,.55))\">{0}</span>&nbsp;<span class=\"time\">{2}</span></b><div class=\"message\">{1}</div></div>"
    L9_2 = L9_2 .. L10_2 .. L11_2
    L10_2 = showOnlyForAnonymous
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
      L10_2 = showOnlyForAdminsAnonymous
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
    L10_2 = L5_1
    L11_2 = A0_2
    L12_2 = "anon"
    L13_2 = L4_2
    L10_2(L11_2, L12_2, L13_2)
    L10_2 = TriggerClientEvent
    L11_2 = "okokChat:Notification"
    L12_2 = A0_2
    L13_2 = Config
    L13_2 = L13_2.NotificationsText
    L13_2 = L13_2.an_success
    L14_2 = Config
    L14_2 = L14_2.NotificationsText
    L14_2 = L14_2.an_success
    L14_2 = L14_2.message
    L10_2(L11_2, L12_2, L13_2, L14_2)
    L10_2 = anonymousList
    L11_2 = {}
    L12_2 = os
    L12_2 = L12_2.time
    L12_2 = L12_2()
    L13_2 = Config
    L13_2 = L13_2.AdvertisementCooldown
    L13_2 = L13_2 * 2
    L12_2 = L12_2 + L13_2
    L11_2.expires = L12_2
    L10_2[A0_2] = L11_2
  end
  L6_1(L7_1, L8_1)
end
