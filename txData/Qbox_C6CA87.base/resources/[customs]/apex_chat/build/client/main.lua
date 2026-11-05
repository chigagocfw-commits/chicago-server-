local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1
L0_1 = RegisterNetEvent
L1_1 = "chat:addMessage"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "chat:addMessage"
function L2_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_legacy"
  L2_2.msg = A0_2
  L1_2(L2_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNetEvent
L1_1 = "chat:addSuggestion"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "chat:addSuggestion"
function L2_1(A0_2, A1_2, A2_2)
  local L3_2, L4_2, L5_2
  L3_2 = SendNUIMessage
  L4_2 = {}
  L4_2.action = "apex_sugg_add"
  L4_2.name = A0_2
  L4_2.help = A1_2
  L5_2 = A2_2 or L5_2
  if not A2_2 then
    L5_2 = {}
  end
  L4_2.params = L5_2
  L3_2(L4_2)
end
L0_1(L1_1, L2_1)
L0_1 = RegisterNetEvent
L1_1 = "chat:addSuggestions"
L0_1(L1_1)
L0_1 = AddEventHandler
L1_1 = "chat:addSuggestions"
function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_sugg_addmany"
  L3_2 = A0_2 or L3_2
  if not A0_2 then
    L3_2 = {}
  end
  L2_2.suggestions = L3_2
  L1_2(L2_2)
end
L0_1(L1_1, L2_1)
function L0_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2
  L0_2 = GetRegisteredCommands
  if not L0_2 then
    return
  end
  L0_2 = GetRegisteredCommands
  L0_2 = L0_2()
  L1_2 = {}
  L2_2 = ipairs
  L3_2 = L0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L7_2.name
    if L8_2 then
      L8_2 = L7_2.restricted
      if L8_2 then
        L8_2 = IsAceAllowed
        L9_2 = "command.%s"
        L10_2 = L9_2
        L9_2 = L9_2.format
        L11_2 = L7_2.name
        L9_2, L10_2, L11_2 = L9_2(L10_2, L11_2)
        L8_2 = L8_2(L9_2, L10_2, L11_2)
        if not L8_2 then
          goto lbl_38
        end
      end
      L8_2 = #L1_2
      L8_2 = L8_2 + 1
      L9_2 = {}
      L10_2 = "/"
      L11_2 = L7_2.name
      L10_2 = L10_2 .. L11_2
      L9_2.name = L10_2
      L9_2.help = ""
      L1_2[L8_2] = L9_2
    end
    ::lbl_38::
  end
  L2_2 = TriggerEvent
  L3_2 = "chat:addSuggestions"
  L4_2 = L1_2
  L2_2(L3_2, L4_2)
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:commands:request"
  L2_2(L3_2)
end
L1_1 = 0
L2_1 = false
function L3_1(A0_2)
  local L1_2, L2_2
  L1_2 = GetGameTimer
  L1_2 = L1_2()
  L2_2 = A0_2 or L2_2
  if not A0_2 then
    L2_2 = 1000
  end
  L1_2 = L1_2 + L2_2
  L1_1 = L1_2
  L1_2 = L2_1
  if L1_2 then
    return
  end
  L1_2 = true
  L2_1 = L1_2
  L1_2 = CreateThread
  function L2_2()
    local L0_3, L1_3
    while true do
      L0_3 = GetGameTimer
      L0_3 = L0_3()
      L1_3 = L1_1
      if not (L0_3 < L1_3) then
        break
      end
      L0_3 = Wait
      L1_3 = 250
      L0_3(L1_3)
    end
    L0_3 = false
    L2_1 = L0_3
    L0_3 = L0_1
    L0_3()
  end
  L1_2(L2_2)
end
L4_1 = AddEventHandler
L5_1 = "apex_chat:refreshCommands"
L6_1 = L0_1
L4_1(L5_1, L6_1)
L4_1 = AddEventHandler
L5_1 = "onClientResourceStart"
function L6_1()
  local L0_2, L1_2
  L0_2 = L3_1
  L1_2 = 1000
  L0_2(L1_2)
end
L4_1(L5_1, L6_1)
L4_1 = AddEventHandler
L5_1 = "onClientResourceStop"
function L6_1()
  local L0_2, L1_2
  L0_2 = L3_1
  L1_2 = 1000
  L0_2(L1_2)
end
L4_1(L5_1, L6_1)
L4_1 = L3_1
L5_1 = 1500
L4_1(L5_1)
L4_1 = RegisterNetEvent
L5_1 = "chat:removeSuggestion"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "chat:removeSuggestion"
function L6_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_sugg_remove"
  L2_2.name = A0_2
  L1_2(L2_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "chat:addTemplate"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "chat:addTemplate"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "apex_template"
  L3_2.id = A0_2
  L3_2.html = A1_2
  L2_2(L3_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "apex_chat:reactionUpdate"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "apex_chat:reactionUpdate"
function L6_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_reaction"
  L3_2 = A0_2.id
  L2_2.id = L3_2
  L3_2 = A0_2.reactions
  if not L3_2 then
    L3_2 = {}
  end
  L2_2.reactions = L3_2
  L1_2(L2_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "chat:clear"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "chat:clear"
function L6_1()
  local L0_2, L1_2
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "apex_clear"
  L0_2(L1_2)
end
L4_1(L5_1, L6_1)
L4_1 = exports
L5_1 = "Message"
function L6_1(A0_2, A1_2, A2_2, A3_2, A4_2, A5_2, A6_2, A7_2)
  local L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2
  L8_2 = TriggerServerEvent
  L9_2 = "okokChat:ServerMessage"
  L10_2 = A0_2
  L11_2 = A1_2
  L12_2 = A2_2
  L13_2 = A3_2
  L14_2 = A4_2
  L15_2 = A5_2
  L16_2 = A6_2
  L17_2 = A7_2
  L8_2(L9_2, L10_2, L11_2, L12_2, L13_2, L14_2, L15_2, L16_2, L17_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "okokChat:checkDeathStatus"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "okokChat:checkDeathStatus"
function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2
  L0_2 = PlayerPedId
  L0_2 = L0_2()
  L1_2 = TriggerServerEvent
  L2_2 = "okokChat:deathStatus"
  L3_2 = IsEntityDead
  L4_2 = L0_2
  L3_2, L4_2 = L3_2(L4_2)
  L1_2(L2_2, L3_2, L4_2)
end
L4_1(L5_1, L6_1)
L4_1 = RegisterNetEvent
L5_1 = "okokChat:Notification"
L4_1(L5_1)
L4_1 = AddEventHandler
L5_1 = "okokChat:Notification"
function L6_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L2_2 = GetResourceState
  L3_2 = "okokNotify"
  L2_2 = L2_2(L3_2)
  if "started" == L2_2 then
    L2_2 = exports
    L2_2 = L2_2.okokNotify
    L3_2 = L2_2
    L2_2 = L2_2.Alert
    L4_2 = A0_2.title
    L5_2 = A1_2
    L6_2 = A0_2.time
    L7_2 = A0_2.type
    L2_2(L3_2, L4_2, L5_2, L6_2, L7_2)
  else
    L2_2 = GetResourceState
    L3_2 = "ox_lib"
    L2_2 = L2_2(L3_2)
    if "started" == L2_2 then
      L2_2 = exports
      L2_2 = L2_2.ox_lib
      L3_2 = L2_2
      L2_2 = L2_2.notify
      L4_2 = {}
      L5_2 = A0_2.title
      L4_2.title = L5_2
      L4_2.description = A1_2
      L5_2 = A0_2.type
      L4_2.type = L5_2
      L5_2 = A0_2.time
      L4_2.duration = L5_2
      L2_2(L3_2, L4_2)
    else
      L2_2 = SetNotificationTextEntry
      L3_2 = "STRING"
      L2_2(L3_2)
      L2_2 = AddTextComponentString
      L3_2 = A1_2
      L2_2(L3_2)
      L2_2 = DrawNotification
      L3_2 = false
      L4_2 = true
      L2_2(L3_2, L4_2)
    end
  end
end
L4_1(L5_1, L6_1)
L4_1 = Citizen
L4_1 = L4_1.CreateThread
function L5_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  function L0_2(A0_3, A1_3, A2_3)
    local L3_3, L4_3, L5_3, L6_3, L7_3
    L3_3 = TriggerEvent
    L4_3 = "chat:addSuggestion"
    L5_3 = "/"
    L6_3 = A0_3
    L5_3 = L5_3 .. L6_3
    L6_3 = A1_3
    L7_3 = A2_3 or L7_3
    if not A2_3 then
      L7_3 = {}
    end
    L3_3(L4_3, L5_3, L6_3, L7_3)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableOOC
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.OOCCommand
    L3_2 = "OOC message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnablePM
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.PMCommand
    L3_2 = "Private message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "id"
    L5_2.help = "player id"
    L6_2 = {}
    L6_2.name = "message"
    L6_2.help = "message to send"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.AllowPlayersToClearTheirChat
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.ClearChatCommand
    L3_2 = "Clear chat"
    L1_2(L2_2, L3_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableHideChat
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.HideChatCommand
    L3_2 = "Hide chat"
    L1_2(L2_2, L3_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableStaffCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.StaffCommand
    L3_2 = "Send a message as staff"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.AllowStaffsToClearEveryonesChat
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.ClearEveryonesChatCommand
    L3_2 = "Clear everyone's chat"
    L1_2(L2_2, L3_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableStaffOnlyCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.StaffOnlyCommand
    L3_2 = "Staff only chat"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableServerAnnouncement
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.ServerAnnouncementCommand
    L3_2 = "Server announcement"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableAdvertisementCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.AdvertisementCommand
    L3_2 = "Make an advertisement"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "ad"
    L5_2.help = "advertisement message"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableAnonymousCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.AnonymousCommand
    L3_2 = "Send an anonymous message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableTwitchCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.TwitchCommand
    L3_2 = "Twitch message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableYoutubeCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.YoutubeCommand
    L3_2 = "YouTube message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableTwitterCommand
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.TwitterCommand
    L3_2 = "X message"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "message"
    L5_2.help = "message to send"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.TimeOutPlayers
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.TimeOutCommand
    L3_2 = "Mute player"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "id"
    L5_2.help = "id of the player to mute"
    L6_2 = {}
    L6_2.name = "time"
    L6_2.help = "time in minutes"
    L4_2[1] = L5_2
    L4_2[2] = L6_2
    L1_2(L2_2, L3_2, L4_2)
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.RemoveTimeOutCommand
    L3_2 = "Unmute player"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "id"
    L5_2.help = "id of the player to unmute"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableMe
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.MeCommand
    L3_2 = "Send a /me action"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "action"
    L5_2.help = "me action"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableDo
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.DoCommand
    L3_2 = "Send a /do action"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "action"
    L5_2.help = "do action"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = Config
  L1_2 = L1_2.EnableTry
  if L1_2 then
    L1_2 = L0_2
    L2_2 = Config
    L2_2 = L2_2.TryCommand
    L3_2 = "Try your luck"
    L4_2 = {}
    L5_2 = {}
    L5_2.name = "action"
    L5_2.help = "try action"
    L4_2[1] = L5_2
    L1_2(L2_2, L3_2, L4_2)
  end
  L1_2 = L0_2
  L2_2 = Config
  L2_2 = L2_2.UICommands
  L2_2 = L2_2.settings
  L3_2 = "Open Apex Chat settings"
  L1_2(L2_2, L3_2)
  L1_2 = L0_2
  L2_2 = Config
  L2_2 = L2_2.UICommands
  L2_2 = L2_2.commands
  L3_2 = "Open Apex Chat category manager"
  L1_2(L2_2, L3_2)
end
L4_1(L5_1)
