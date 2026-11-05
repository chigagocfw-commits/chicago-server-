local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1
L0_1 = GetGameTimer
L0_1 = L0_1()
L1_1 = Config
L1_1 = L1_1.DefaultPrefs
if L1_1 then
  L1_1 = Config
  L1_1 = L1_1.DefaultPrefs
  L1_1 = L1_1.visibility
  if L1_1 then
    goto lbl_14
  end
end
L1_1 = "always"
::lbl_14::
L2_1 = Config
L2_1 = L2_1.DefaultPrefs
if L2_1 then
  L2_1 = Config
  L2_1 = L2_1.DefaultPrefs
  L2_1 = L2_1.visibilityHideMs
  if L2_1 then
    goto lbl_24
  end
end
L2_1 = 8000
::lbl_24::
L3_1 = Config
L3_1 = L3_1.DefaultPrefs
if L3_1 then
  L3_1 = Config
  L3_1 = L3_1.DefaultPrefs
  L3_1 = L3_1.inactiveHideMs
  if L3_1 then
    goto lbl_34
  end
end
L3_1 = 10000
::lbl_34::
function L4_1()
  local L0_2, L1_2
  L0_2 = GetGameTimer
  L0_2 = L0_2()
  L0_1 = L0_2
end
L5_1 = AddEventHandler
L6_1 = "apex_chat:prefs:changed"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  if not A0_2 then
    return
  end
  L1_2 = A0_2.visibility
  if not L1_2 then
    L1_2 = L1_1
  end
  L1_1 = L1_2
  L1_2 = A0_2.visibilityHideMs
  if not L1_2 then
    L1_2 = L2_1
  end
  L2_1 = L1_2
  L1_2 = A0_2.inactiveHideMs
  if not L1_2 then
    L1_2 = L3_1
  end
  L3_1 = L1_2
  L1_2 = TriggerEvent
  L2_2 = "chat:addMessage"
  L3_2 = {}
  L3_2.templateId = "apex_chat_inject_vars"
  L4_2 = "<style>:root{--apex-visibility-mode:"
  L5_2 = L1_1
  L6_2 = ";--apex-hide-ms:"
  L7_2 = L2_1
  L8_2 = "ms;--apex-inactive-ms:"
  L9_2 = L3_1
  L10_2 = "ms;}</style>"
  L4_2 = L4_2 .. L5_2 .. L6_2 .. L7_2 .. L8_2 .. L9_2 .. L10_2
  L3_2.template = L4_2
  L4_2 = {}
  L3_2.args = L4_2
  L1_2(L2_2, L3_2)
end
L5_1(L6_1, L7_1)
L5_1 = AddEventHandler
L6_1 = "chatMessage"
function L7_1()
  local L0_2, L1_2
  L0_2 = L4_1
  L0_2()
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNetEvent
L6_1 = "chat:addMessage"
L7_1 = L4_1
L5_1(L6_1, L7_1)
L5_1 = RegisterCommand
L6_1 = "chat-toggle"
function L7_1()
  local L0_2, L1_2
  L0_2 = TriggerEvent
  L1_2 = "chat:hide"
  L0_2(L1_2)
end
L8_1 = false
L5_1(L6_1, L7_1, L8_1)
