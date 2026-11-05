local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1, L10_1, L11_1, L12_1, L13_1, L14_1, L15_1
L0_1 = ApexChat
if not L0_1 then
  L0_1 = {}
end
ApexChat = L0_1
L0_1 = ApexChat
L0_1.Prefs = nil
L0_1 = Shared
if L0_1 then
  L0_1 = Shared
  L0_1 = L0_1.Storage
  if L0_1 then
    L0_1 = Shared
    L0_1 = L0_1.Storage
    L0_1 = L0_1.clientPrefsKey
    if L0_1 then
      goto lbl_23
    end
  end
end
L0_1 = "apex_chat:prefs"
::lbl_23::
function L1_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return A0_2
  end
  L1_2 = {}
  L2_2 = pairs
  L3_2 = A0_2
  L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
  for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
    L8_2 = L1_1
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L1_2[L6_2] = L8_2
  end
  return L1_2
end
function L2_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = Config
  L0_2 = L0_2.DefaultTheme
  if not L0_2 then
    L0_2 = Config
    L0_2 = L0_2.DefaultPrefs
    if L0_2 then
      L0_2 = Config
      L0_2 = L0_2.DefaultPrefs
      L0_2 = L0_2.theme
      if L0_2 then
        goto lbl_15
      end
    end
    L0_2 = "apex"
  end
  ::lbl_15::
  L1_2 = L0_2
  L2_2 = type
  L3_2 = Config
  L3_2 = L3_2.Themes
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = Config
    L2_2 = L2_2.Themes
    L2_2 = L2_2[1]
    if L2_2 then
      L2_2 = Config
      L2_2 = L2_2.Themes
      L2_2 = L2_2[1]
      L2_2 = L2_2.id
      if L2_2 then
        L2_2 = Config
        L2_2 = L2_2.Themes
        L2_2 = L2_2[1]
        L1_2 = L2_2.id
        L2_2 = ipairs
        L3_2 = Config
        L3_2 = L3_2.Themes
        L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
        for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
          L8_2 = L7_2.id
          if L8_2 == L0_2 then
            return L0_2
          end
        end
      end
    end
  end
  return L1_2
end
function L3_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "string" ~= L1_2 or "" == A0_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = type
  L2_2 = Config
  L2_2 = L2_2.Themes
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    L1_2 = false
    return L1_2
  end
  L1_2 = ipairs
  L2_2 = Config
  L2_2 = L2_2.Themes
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L7_2 = L6_2.id
    if L7_2 == A0_2 then
      L7_2 = true
      return L7_2
    end
  end
  L1_2 = false
  return L1_2
end
function L4_1()
  local L0_2, L1_2
  L0_2 = L1_1
  L1_2 = Config
  L1_2 = L1_2.DefaultPrefs
  L0_2 = L0_2(L1_2)
  L1_2 = L2_1
  L1_2 = L1_2()
  L0_2.theme = L1_2
  L1_2 = L0_2.accentOverride
  L1_2 = true == L1_2
  L0_2.accentOverride = L1_2
  return L0_2
end
function L5_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  L1_2 = A0_2 or L1_2
  if "table" ~= L1_2 or not A0_2 then
    L1_2 = L4_1
    L1_2 = L1_2()
  end
  L2_2 = L3_1
  L3_2 = L1_2.theme
  L2_2 = L2_2(L3_2)
  if not L2_2 then
    L2_2 = L2_1
    L2_2 = L2_2()
    L1_2.theme = L2_2
    L1_2.accentOverride = false
  end
  L2_2 = L1_2.accentOverride
  L2_2 = true == L2_2
  L1_2.accentOverride = L2_2
  L2_2 = L1_2.accentOverride
  if true ~= L2_2 then
    L1_2.selectedColor = false
  end
  return L1_2
end
function L6_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2
  L0_2 = GetResourceKvpString
  L1_2 = L0_1
  L0_2 = L0_2(L1_2)
  if not L0_2 or "" == L0_2 then
    L1_2 = L4_1
    return L1_2()
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
  L3_2 = L4_1
  do return L3_2() end
  ::lbl_26::
  L3_2 = L4_1
  L3_2 = L3_2()
  L4_2 = pairs
  L5_2 = L2_2
  L4_2, L5_2, L6_2, L7_2 = L4_2(L5_2)
  for L8_2, L9_2 in L4_2, L5_2, L6_2, L7_2 do
    L3_2[L8_2] = L9_2
  end
  L4_2 = L5_1
  L5_2 = L3_2
  return L4_2(L5_2)
end
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2
  L1_2 = SetResourceKvp
  L2_2 = L0_1
  L3_2 = json
  L3_2 = L3_2.encode
  L4_2 = L5_1
  L5_2 = A0_2
  L4_2, L5_2 = L4_2(L5_2)
  L3_2, L4_2, L5_2 = L3_2(L4_2, L5_2)
  L1_2(L2_2, L3_2, L4_2, L5_2)
end
L8_1 = ApexChat
function L9_1(A0_2)
  local L1_2
  L1_2 = A0_2.Prefs
  if not L1_2 then
    L1_2 = L6_1
    L1_2 = L1_2()
    A0_2.Prefs = L1_2
  end
  L1_2 = A0_2.Prefs
  return L1_2
end
L8_1.GetPrefs = L9_1
L8_1 = ApexChat
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = L5_1
  L3_2 = A1_2
  L2_2 = L2_2(L3_2)
  A0_2.Prefs = L2_2
  L2_2 = L7_1
  L3_2 = A0_2.Prefs
  L2_2(L3_2)
  L2_2 = TriggerEvent
  L3_2 = "apex_chat:prefs:changed"
  L4_2 = A0_2.Prefs
  L2_2(L3_2, L4_2)
end
L8_1.SetPrefs = L9_1
function L8_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2
  L0_2 = {}
  L1_2 = pairs
  L2_2 = Locales
  if L2_2 then
    L2_2 = Locales
    L2_2 = L2_2.en
    if L2_2 then
      goto lbl_13
    end
  end
  L2_2 = {}
  ::lbl_13::
  L1_2, L2_2, L3_2, L4_2 = L1_2(L2_2)
  for L5_2, L6_2 in L1_2, L2_2, L3_2, L4_2 do
    L0_2[L5_2] = L6_2
  end
  L1_2 = Locales
  if L1_2 then
    L1_2 = Locales
    L2_2 = Shared
    if L2_2 then
      L2_2 = Shared
      L2_2 = L2_2.locale
      if L2_2 then
        goto lbl_31
      end
    end
    L2_2 = "en"
    ::lbl_31::
    L1_2 = L1_2[L2_2]
  end
  L2_2 = type
  L3_2 = L1_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = pairs
    L3_2 = L1_2
    L2_2, L3_2, L4_2, L5_2 = L2_2(L3_2)
    for L6_2, L7_2 in L2_2, L3_2, L4_2, L5_2 do
      L0_2[L6_2] = L7_2
    end
  end
  return L0_2
end
function L9_1()
  local L0_2, L1_2, L2_2, L3_2, L4_2, L5_2, L6_2, L7_2
  L0_2 = {}
  L1_2 = L8_1
  L1_2 = L1_2()
  L0_2.locale = L1_2
  L1_2 = Config
  L1_2 = L1_2.theme
  L0_2.theme = L1_2
  L1_2 = Config
  L1_2 = L1_2.Themes
  L0_2.themes = L1_2
  L1_2 = Config
  L1_2 = L1_2.colorPresets
  L0_2.presets = L1_2
  L1_2 = Config
  L1_2 = L1_2.Avatars
  L0_2.avatars = L1_2
  L1_2 = {}
  L1_2.small = 23
  L1_2.medium = 50
  L1_2.big = 70
  L0_2.sizes = L1_2
  L1_2 = {}
  L2_2 = "top-left"
  L3_2 = "top-center"
  L4_2 = "top-right"
  L5_2 = "bottom-left"
  L6_2 = "bottom-center"
  L7_2 = "bottom-right"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L1_2[6] = L7_2
  L0_2.positions = L1_2
  L1_2 = {}
  L2_2 = "always"
  L3_2 = "when-message"
  L4_2 = "when-active"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L0_2.visibilityModes = L1_2
  L1_2 = {}
  L2_2 = "open"
  L3_2 = "job"
  L4_2 = "grade"
  L5_2 = "staff"
  L6_2 = "role"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L0_2.ruleTypes = L1_2
  L1_2 = {}
  L2_2 = "rp"
  L3_2 = "steam"
  L4_2 = "anon"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L0_2.identities = L1_2
  L1_2 = {}
  L2_2 = "all"
  L3_2 = "staff"
  L4_2 = "sender"
  L5_2 = "role"
  L6_2 = "job"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L1_2[4] = L5_2
  L1_2[5] = L6_2
  L0_2.visScopes = L1_2
  L1_2 = {}
  L2_2 = "Press your assigned key while chat is open to execute commands"
  L3_2 = "Commands are sent directly as if you typed them manually"
  L4_2 = "Shortcuts work with any FiveM command including custom ones"
  L1_2[1] = L2_2
  L1_2[2] = L3_2
  L1_2[3] = L4_2
  L0_2.shortcutsHelp = L1_2
  return L0_2
end
function L10_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  L1_2 = SetNuiFocus
  L2_2 = true
  L3_2 = true
  L1_2(L2_2, L3_2)
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_open_panel"
  L2_2.panel = A0_2
  L3_2 = ApexChat
  L4_2 = L3_2
  L3_2 = L3_2.GetPrefs
  L3_2 = L3_2(L4_2)
  L2_2.prefs = L3_2
  L3_2 = L9_1
  L3_2 = L3_2()
  L2_2.config = L3_2
  L1_2(L2_2)
  if "categories" == A0_2 or "themes" == A0_2 then
    L1_2 = TriggerServerEvent
    L2_2 = "apex_chat:cats:request"
    L1_2(L2_2)
  end
end
function L11_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "apex_close_panel"
  L0_2(L1_2)
end
L12_1 = RegisterCommand
L13_1 = Config
L13_1 = L13_1.UICommands
L13_1 = L13_1.settings
function L14_1()
  local L0_2, L1_2
  L0_2 = L10_1
  L1_2 = "settings"
  L0_2(L1_2)
end
L15_1 = false
L12_1(L13_1, L14_1, L15_1)
L12_1 = RegisterCommand
L13_1 = Config
L13_1 = L13_1.UICommands
L13_1 = L13_1.commands
function L14_1()
  local L0_2, L1_2
  L0_2 = L10_1
  L1_2 = "categories"
  L0_2(L1_2)
end
L15_1 = false
L12_1(L13_1, L14_1, L15_1)
L12_1 = RegisterCommand
L13_1 = "chatthemes"
function L14_1()
  local L0_2, L1_2
  L0_2 = L10_1
  L1_2 = "themes"
  L0_2(L1_2)
end
L15_1 = false
L12_1(L13_1, L14_1, L15_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_open_req"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L10_1
  if A0_2 then
    L3_2 = A0_2.panel
    if L3_2 then
      goto lbl_8
    end
  end
  L3_2 = "settings"
  ::lbl_8::
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_nui_ready"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "apex_init"
  L4_2 = ApexChat
  L5_2 = L4_2
  L4_2 = L4_2.GetPrefs
  L4_2 = L4_2(L5_2)
  L3_2.prefs = L4_2
  L4_2 = L9_1
  L4_2 = L4_2()
  L3_2.config = L4_2
  L2_2(L3_2)
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:cats:request"
  L2_2(L3_2)
  L2_2 = TriggerEvent
  L3_2 = "apex_chat:refreshCommands"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_close"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L11_1
  L2_2()
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_save_prefs"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = ApexChat
    L3_2 = L2_2
    L2_2 = L2_2.SetPrefs
    L4_2 = A0_2
    L2_2(L3_2, L4_2)
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_save_theme"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  if A0_2 then
    L2_2 = L3_1
    L3_2 = A0_2.theme
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = ApexChat
      L3_2 = L2_2
      L2_2 = L2_2.GetPrefs
      L2_2 = L2_2(L3_2)
      L3_2 = A0_2.theme
      L2_2.theme = L3_2
      L2_2.accentOverride = false
      L2_2.selectedColor = false
      L3_2 = ApexChat
      L4_2 = L3_2
      L3_2 = L3_2.SetPrefs
      L5_2 = L2_2
      L3_2(L4_2, L5_2)
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_reset_prefs"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = ApexChat
  L3_2 = L2_2
  L2_2 = L2_2.SetPrefs
  L4_2 = L4_1
  L4_2, L5_2 = L4_2()
  L2_2(L3_2, L4_2, L5_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L4_2 = ApexChat
  L5_2 = L4_2
  L4_2 = L4_2.GetPrefs
  L4_2 = L4_2(L5_2)
  L3_2.prefs = L4_2
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_get_prefs"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L4_2 = ApexChat
  L5_2 = L4_2
  L4_2 = L4_2.GetPrefs
  L4_2 = L4_2(L5_2)
  L3_2.prefs = L4_2
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_cat_list"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:cats:request"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_cat_save"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:cats:save"
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_cat_delete"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:cats:delete"
  L4_2 = A0_2 or L4_2
  if A0_2 then
    L4_2 = A0_2.id
  end
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_tags_list"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:tags:request"
  L2_2(L3_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_tags_save"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:tags:save"
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_tags_delete"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:tags:delete"
  L4_2 = A0_2 or L4_2
  if A0_2 then
    L4_2 = A0_2.id
  end
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_tags_search"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:tags:search"
  if A0_2 then
    L4_2 = A0_2.term
    if L4_2 then
      goto lbl_9
    end
  end
  L4_2 = ""
  ::lbl_9::
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_tags_assign"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:tags:assign"
  L4_2 = A0_2
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNetEvent
L13_1 = "apex_chat:tags:sync"
function L14_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_tags_sync"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNetEvent
L13_1 = "apex_chat:tags:results"
function L14_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_tags_results"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNetEvent
L13_1 = "apex_chat:tags:player"
function L14_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_tags_player"
  L2_2.data = A0_2
  L1_2(L2_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNUICallback
L13_1 = "apex_theme_broadcast"
function L14_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = TriggerServerEvent
  L3_2 = "apex_chat:theme:broadcast"
  L4_2 = A0_2 or L4_2
  if not A0_2 then
    L4_2 = {}
  end
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L12_1(L13_1, L14_1)
L12_1 = RegisterNetEvent
L13_1 = "apex_chat:theme:apply"
function L14_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = nil
  L2_2 = nil
  L3_2 = type
  L4_2 = A0_2
  L3_2 = L3_2(L4_2)
  if "table" == L3_2 then
    L1_2 = A0_2.theme
    L2_2 = A0_2.accent
  else
    L1_2 = A0_2
  end
  if (not L1_2 or "" == L1_2) and (not L2_2 or "" == L2_2) then
    return
  end
  L3_2 = ApexChat
  L4_2 = L3_2
  L3_2 = L3_2.GetPrefs
  L3_2 = L3_2(L4_2)
  if L1_2 and "" ~= L1_2 then
    L3_2.theme = L1_2
    L3_2.accentOverride = false
    L3_2.selectedColor = false
  end
  if L2_2 and "" ~= L2_2 then
    L3_2.accentOverride = true
    L3_2.customAccent = L2_2
  end
  L4_2 = ApexChat
  L5_2 = L4_2
  L4_2 = L4_2.SetPrefs
  L6_2 = L3_2
  L4_2(L5_2, L6_2)
  L4_2 = SendNUIMessage
  L5_2 = {}
  L5_2.action = "apex_apply_theme"
  L5_2.theme = L1_2
  L5_2.accent = L2_2
  L4_2(L5_2)
end
L12_1(L13_1, L14_1)
L12_1 = AddEventHandler
L13_1 = "apex_chat:prefs:changed"
function L14_1(A0_2)
  local L1_2, L2_2
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "apex_prefs"
  L2_2.prefs = A0_2
  L1_2(L2_2)
end
L12_1(L13_1, L14_1)
L12_1 = CreateThread
function L13_1()
  local L0_2, L1_2, L2_2
  L0_2 = ApexChat
  L1_2 = L0_2
  L0_2 = L0_2.GetPrefs
  L0_2(L1_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "apex_init"
  L2_2 = ApexChat
  L2_2 = L2_2.Prefs
  L1_2.prefs = L2_2
  L2_2 = L9_1
  L2_2 = L2_2()
  L1_2.config = L2_2
  L0_2(L1_2)
  L0_2 = TriggerEvent
  L1_2 = "apex_chat:prefs:changed"
  L2_2 = ApexChat
  L2_2 = L2_2.Prefs
  L0_2(L1_2, L2_2)
end
L12_1(L13_1)
