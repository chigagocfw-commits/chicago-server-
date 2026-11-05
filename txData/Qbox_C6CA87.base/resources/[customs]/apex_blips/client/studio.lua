local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1
L0_1 = false
L1_1 = false
function L2_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = Config
  if L1_2 then
    L1_2 = Config
    L1_2 = L1_2.debug
    if L1_2 then
      L1_2 = print
      L2_2 = "^5[apex_blips]^7 [studio] "
      L3_2 = A0_2
      L2_2 = L2_2 .. L3_2
      L1_2(L2_2)
    end
  end
end
function L3_1()
  local L0_2, L1_2, L2_2, L3_2
  L0_2 = Slots
  L0_2 = L0_2.Stats
  L0_2, L1_2 = L0_2()
  L2_2 = {}
  L2_2.used = L0_2
  L2_2.total = L1_2
  L3_2 = Slots
  L3_2 = L3_2.HijackedSprites
  L3_2 = L3_2()
  L2_2.hijacked = L3_2
  return L2_2
end
function L4_1()
  local L0_2, L1_2, L2_2
  L0_2 = L0_1
  if not L0_2 then
    return
  end
  L0_2 = false
  L0_1 = L0_2
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.action = "close"
  L0_2(L1_2)
  L0_2 = TriggerServerEvent
  L1_2 = "apex_blips:studioClosed"
  L0_2(L1_2)
end
L5_1 = RegisterNetEvent
L6_1 = "apex_blips:studio"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2, L5_2, L6_2
  L1_2 = type
  L2_2 = A0_2
  L1_2 = L1_2(L2_2)
  if "table" ~= L1_2 then
    return
  end
  L1_2 = L0_1
  if not L1_2 then
    L1_2 = true
    L0_1 = L1_2
    L1_2 = SetNuiFocus
    L2_2 = true
    L3_2 = true
    L1_2(L2_2, L3_2)
    L1_2 = PlayerPedId
    L1_2 = L1_2()
    L2_2 = GetEntityCoords
    L3_2 = L1_2
    L2_2 = L2_2(L3_2)
    L3_2 = SendNUIMessage
    L4_2 = {}
    L4_2.action = "open"
    L5_2 = LocaleTable
    L5_2 = L5_2()
    L4_2.locale = L5_2
    L5_2 = A0_2.blips
    if not L5_2 then
      L5_2 = {}
    end
    L4_2.blips = L5_2
    L5_2 = A0_2.images
    if not L5_2 then
      L5_2 = {}
    end
    L4_2.images = L5_2
    L5_2 = Config
    L5_2 = L5_2.defaults
    L4_2.defaults = L5_2
    L5_2 = {}
    L6_2 = Config
    L6_2 = L6_2.zones
    L6_2 = L6_2.maxRadius
    L5_2.maxRadius = L6_2
    L6_2 = Config
    L6_2 = L6_2.zones
    L6_2 = L6_2.maxSide
    L5_2.maxSide = L6_2
    L4_2.zones = L5_2
    L5_2 = Config
    L5_2 = L5_2.limits
    if not L5_2 then
      L5_2 = {}
    end
    L4_2.limits = L5_2
    L5_2 = {}
    L6_2 = Config
    L6_2 = L6_2.images
    L6_2 = L6_2.textureSize
    L5_2.size = L6_2
    L6_2 = Config
    L6_2 = L6_2.images
    L6_2 = L6_2.maxKB
    L5_2.maxKB = L6_2
    L6_2 = Config
    L6_2 = L6_2.images
    L6_2 = L6_2.maxCount
    L5_2.maxCount = L6_2
    L4_2.imgcfg = L5_2
    L5_2 = L3_1
    L5_2 = L5_2()
    L4_2.slots = L5_2
    L5_2 = {}
    L6_2 = L2_2.x
    L5_2.x = L6_2
    L6_2 = L2_2.y
    L5_2.y = L6_2
    L6_2 = L2_2.z
    L5_2.z = L6_2
    L4_2.myPos = L5_2
    L3_2(L4_2)
  else
    L1_2 = SendNUIMessage
    L2_2 = {}
    L2_2.action = "data"
    L3_2 = A0_2.blips
    if not L3_2 then
      L3_2 = {}
    end
    L2_2.blips = L3_2
    L3_2 = A0_2.images
    if not L3_2 then
      L3_2 = {}
    end
    L2_2.images = L3_2
    L3_2 = L3_1
    L3_2 = L3_2()
    L2_2.slots = L3_2
    L1_2(L2_2)
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNetEvent
L6_1 = "apex_blips:image"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  if L1_2 then
    L1_2 = type
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if "table" == L1_2 then
      L1_2 = type
      L2_2 = A0_2.id
      L1_2 = L1_2(L2_2)
      if "string" == L1_2 then
        goto lbl_15
      end
    end
  end
  do return end
  ::lbl_15::
  L1_2 = SendNUIMessage
  L2_2 = {}
  L2_2.action = "image"
  L3_2 = A0_2.id
  L2_2.id = L3_2
  L3_2 = A0_2.image
  L2_2.image = L3_2
  L3_2 = A0_2.removed
  L3_2 = true == L3_2
  L2_2.removed = L3_2
  L3_2 = L3_1
  L3_2 = L3_2()
  L2_2.slots = L3_2
  L1_2(L2_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterCommand
L6_1 = Config
L6_1 = L6_1.commands
L6_1 = L6_1.studio
function L7_1()
  local L0_2, L1_2
  L0_2 = L0_1
  if L0_2 then
    L0_2 = L4_1
    L0_2()
    return
  end
  L0_2 = TriggerServerEvent
  L1_2 = "apex_blips:requestStudio"
  L0_2(L1_2)
end
L8_1 = false
L5_1(L6_1, L7_1, L8_1)
L5_1 = type
L6_1 = Config
L6_1 = L6_1.keybind
L5_1 = L5_1(L6_1)
if "string" == L5_1 then
  L5_1 = Config
  L5_1 = L5_1.keybind
  if "" ~= L5_1 then
    L5_1 = RegisterKeyMapping
    L6_1 = Config
    L6_1 = L6_1.commands
    L6_1 = L6_1.studio
    L7_1 = L
    L8_1 = "keybind_desc"
    L7_1 = L7_1(L8_1)
    L8_1 = "keyboard"
    L9_1 = Config
    L9_1 = L9_1.keybind
    L5_1(L6_1, L7_1, L8_1, L9_1)
  end
end
L5_1 = RegisterNetEvent
L6_1 = "apex_blips:saved"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  if L1_2 then
    L1_2 = type
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if "table" == L1_2 then
      L1_2 = SendNUIMessage
      L2_2 = {}
      L2_2.action = "saved"
      L3_2 = A0_2.ok
      L3_2 = true == L3_2
      L2_2.ok = L3_2
      L3_2 = A0_2.id
      L2_2.id = L3_2
      L3_2 = A0_2.reason
      L2_2.reason = L3_2
      L1_2(L2_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNetEvent
L6_1 = "apex_blips:imageSaved"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = L0_1
  if L1_2 then
    L1_2 = type
    L2_2 = A0_2
    L1_2 = L1_2(L2_2)
    if "table" == L1_2 then
      L1_2 = SendNUIMessage
      L2_2 = {}
      L2_2.action = "imageSaved"
      L3_2 = A0_2.ok
      L3_2 = true == L3_2
      L2_2.ok = L3_2
      L3_2 = A0_2.id
      L2_2.id = L3_2
      L3_2 = A0_2.reason
      L2_2.reason = L3_2
      L1_2(L2_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "ready"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "close"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = L4_1
  L2_2()
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "save"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.def
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = TriggerServerEvent
      L3_2 = "apex_blips:save"
      L4_2 = A0_2.def
      L2_2(L3_2, L4_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "delete"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = TriggerServerEvent
      L3_2 = "apex_blips:delete"
      L4_2 = A0_2.id
      L2_2(L3_2, L4_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "saveImage"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" ~= L2_2 then
    return
  end
  L2_2 = type
  L3_2 = A0_2.data
  L2_2 = L2_2(L3_2)
  if "string" ~= L2_2 then
    L2_2 = type
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
    if "string" ~= L2_2 then
      return
    end
  end
  L2_2 = TriggerLatentServerEvent
  L3_2 = "apex_blips:saveImage"
  L4_2 = Config
  L4_2 = L4_2.sync
  L4_2 = L4_2.bps
  L5_2 = {}
  L6_2 = A0_2.id
  L5_2.id = L6_2
  L6_2 = A0_2.name
  L5_2.name = L6_2
  L6_2 = A0_2.data
  L5_2.data = L6_2
  L6_2 = A0_2.size
  L5_2.size = L6_2
  L6_2 = A0_2.badge
  L6_2 = true == L6_2
  L5_2.badge = L6_2
  L2_2(L3_2, L4_2, L5_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "deleteImage"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.id
    L2_2 = L2_2(L3_2)
    if "string" == L2_2 then
      L2_2 = TriggerServerEvent
      L3_2 = "apex_blips:deleteImage"
      L4_2 = A0_2.id
      L2_2(L3_2, L4_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "importAll"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = type
    L3_2 = A0_2.pack
    L2_2 = L2_2(L3_2)
    if "table" == L2_2 then
      L2_2 = TriggerLatentServerEvent
      L3_2 = "apex_blips:importAll"
      L4_2 = Config
      L4_2 = L4_2.sync
      L4_2 = L4_2.bps
      L5_2 = A0_2.pack
      L2_2(L3_2, L4_2, L5_2)
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "myPos"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = GetEntityCoords
  L3_2 = PlayerPedId
  L3_2, L4_2, L5_2 = L3_2()
  L2_2 = L2_2(L3_2, L4_2, L5_2)
  L3_2 = A1_2
  L4_2 = {}
  L4_2.ok = true
  L5_2 = L2_2.x
  L4_2.x = L5_2
  L5_2 = L2_2.y
  L4_2.y = L5_2
  L5_2 = L2_2.z
  L4_2.z = L5_2
  L3_2(L4_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "waypoint"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = IsWaypointActive
  L2_2 = L2_2()
  if L2_2 then
    L2_2 = GetFirstBlipInfoId
    L3_2 = 8
    L2_2 = L2_2(L3_2)
    L3_2 = DoesBlipExist
    L4_2 = L2_2
    L3_2 = L3_2(L4_2)
    if L3_2 then
      L3_2 = GetBlipInfoIdCoord
      L4_2 = L2_2
      L3_2 = L3_2(L4_2)
      L4_2 = A1_2
      L5_2 = {}
      L5_2.ok = true
      L6_2 = L3_2.x
      L5_2.x = L6_2
      L6_2 = L3_2.y
      L5_2.y = L6_2
      L5_2.z = 30.0
      L4_2(L5_2)
      return
    end
  end
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = false
  L2_2(L3_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "worldBlips"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2, L13_2, L14_2
  L2_2 = {}
  L3_2 = type
  L4_2 = GetRenderedBlipHandles
  L3_2 = L3_2(L4_2)
  if "function" == L3_2 then
    L3_2 = GetRenderedBlipHandles
    L3_2 = L3_2()
    L2_2 = L3_2
  end
  L3_2 = {}
  L4_2 = 1
  L5_2 = 957
  L6_2 = 1
  for L7_2 = L4_2, L5_2, L6_2 do
    L8_2 = GetFirstBlipInfoId
    L9_2 = L7_2
    L8_2 = L8_2(L9_2)
    L9_2 = 0
    while true do
      L10_2 = DoesBlipExist
      L11_2 = L8_2
      L10_2 = L10_2(L11_2)
      if not L10_2 then
        break
      end
      L10_2 = 256
      if not (L9_2 < L10_2) then
        break
      end
      L10_2 = L2_2[L8_2]
      if nil == L10_2 then
        L10_2 = GetBlipInfoIdCoord
        L11_2 = L8_2
        L10_2 = L10_2(L11_2)
        L11_2 = #L3_2
        L11_2 = L11_2 + 1
        L12_2 = {}
        L12_2.sprite = L7_2
        L13_2 = L10_2.x
        L12_2.x = L13_2
        L13_2 = L10_2.y
        L12_2.y = L13_2
        L13_2 = GetBlipColour
        L14_2 = L8_2
        L13_2 = L13_2(L14_2)
        L12_2.colour = L13_2
        L3_2[L11_2] = L12_2
      end
      L9_2 = L9_2 + 1
      L10_2 = GetNextBlipInfoId
      L11_2 = L7_2
      L10_2 = L10_2(L11_2)
      L8_2 = L10_2
    end
  end
  L4_2 = A1_2
  L5_2 = {}
  L5_2.ok = true
  L5_2.blips = L3_2
  L4_2(L5_2)
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "locate"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = type
  L3_2 = A0_2
  L2_2 = L2_2(L3_2)
  if "table" == L2_2 then
    L2_2 = tonumber
    L3_2 = A0_2.x
    L2_2 = L2_2(L3_2)
    if L2_2 then
      L2_2 = tonumber
      L3_2 = A0_2.y
      L2_2 = L2_2(L3_2)
      if L2_2 then
        L2_2 = SetNewWaypoint
        L3_2 = tonumber
        L4_2 = A0_2.x
        L3_2 = L3_2(L4_2)
        L3_2 = L3_2 + 0.0
        L4_2 = tonumber
        L5_2 = A0_2.y
        L4_2 = L4_2(L5_2)
        L4_2 = L4_2 + 0.0
        L2_2(L3_2, L4_2)
      end
    end
  end
end
L5_1(L6_1, L7_1)
L5_1 = RegisterNUICallback
L6_1 = "pickMap"
function L7_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2
  L2_2 = A1_2
  L3_2 = {}
  L3_2.ok = true
  L2_2(L3_2)
  L2_2 = L1_1
  if not L2_2 then
    L2_2 = L0_1
    if L2_2 then
      goto lbl_13
    end
  end
  do return end
  ::lbl_13::
  L2_2 = true
  L1_1 = L2_2
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.action = "pickHide"
  L2_2(L3_2)
  L2_2 = Notify
  L3_2 = L
  L4_2 = "n_pick_hint"
  L3_2, L4_2, L5_2, L6_2 = L3_2(L4_2)
  L2_2(L3_2, L4_2, L5_2, L6_2)
  L2_2 = nil
  L3_2 = IsWaypointActive
  L3_2 = L3_2()
  if L3_2 then
    L3_2 = GetFirstBlipInfoId
    L4_2 = 8
    L3_2 = L3_2(L4_2)
    L4_2 = DoesBlipExist
    L5_2 = L3_2
    L4_2 = L4_2(L5_2)
    if L4_2 then
      L4_2 = GetBlipInfoIdCoord
      L5_2 = L3_2
      L4_2 = L4_2(L5_2)
      L2_2 = L4_2
    end
  end
  L3_2 = ActivateFrontendMenu
  L4_2 = GetHashKey
  L5_2 = "FE_MENU_VERSION_MP_PAUSE"
  L4_2 = L4_2(L5_2)
  L5_2 = true
  L6_2 = -1
  L3_2(L4_2, L5_2, L6_2)
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3
    L0_3 = GetGameTimer
    L0_3 = L0_3()
    L0_3 = L0_3 + 60000
    L1_3 = nil
    L2_3 = Wait
    L3_3 = 600
    L2_3(L3_3)
    while true do
      L2_3 = GetGameTimer
      L2_3 = L2_3()
      if not (L0_3 > L2_3) then
        break
      end
      L2_3 = Wait
      L3_3 = 100
      L2_3(L3_3)
      L2_3 = IsWaypointActive
      L2_3 = L2_3()
      if L2_3 then
        L2_3 = GetFirstBlipInfoId
        L3_3 = 8
        L2_3 = L2_3(L3_3)
        L3_3 = DoesBlipExist
        L4_3 = L2_3
        L3_3 = L3_3(L4_3)
        if L3_3 then
          L3_3 = GetBlipInfoIdCoord
          L4_3 = L2_3
          L3_3 = L3_3(L4_3)
          L4_3 = L2_2
          if nil ~= L4_3 then
            L4_3 = math
            L4_3 = L4_3.abs
            L5_3 = L3_3.x
            L6_3 = L2_2.x
            L5_3 = L5_3 - L6_3
            L4_3 = L4_3(L5_3)
            L5_3 = math
            L5_3 = L5_3.abs
            L6_3 = L3_3.y
            L7_3 = L2_2.y
            L6_3 = L6_3 - L7_3
            L5_3 = L5_3(L6_3)
            L4_3 = L4_3 + L5_3
            if not (L4_3 > 1.0) then
              goto lbl_54
            end
          end
          L1_3 = L3_3
          break
        end
      end
      ::lbl_54::
      L2_3 = IsPauseMenuActive
      L2_3 = L2_3()
      if not L2_3 then
        break
      end
    end
    L2_3 = IsPauseMenuActive
    L2_3 = L2_3()
    if L2_3 then
      L2_3 = SetFrontendActive
      L3_3 = false
      L2_3(L3_3)
    end
    L2_3 = Wait
    L3_3 = 250
    L2_3(L3_3)
    L2_3 = false
    L1_1 = L2_3
    L2_3 = L0_1
    if not L2_3 then
      return
    end
    L2_3 = SetNuiFocus
    L3_3 = true
    L4_3 = true
    L2_3(L3_3, L4_3)
    if nil ~= L1_3 then
      L2_3 = SendNUIMessage
      L3_3 = {}
      L3_3.action = "pickResult"
      L3_3.ok = true
      L4_3 = L1_3.x
      L3_3.x = L4_3
      L4_3 = L1_3.y
      L3_3.y = L4_3
      L3_3.z = 30.0
      L2_3(L3_3)
    else
      L2_3 = SendNUIMessage
      L3_3 = {}
      L3_3.action = "pickResult"
      L3_3.ok = false
      L2_3(L3_3)
      L2_3 = Notify
      L3_3 = L
      L4_3 = "n_pick_cancel"
      L3_3, L4_3, L5_3, L6_3, L7_3 = L3_3(L4_3)
      L2_3(L3_3, L4_3, L5_3, L6_3, L7_3)
    end
  end
  L3_2(L4_2)
end
L5_1(L6_1, L7_1)
L5_1 = AddEventHandler
L6_1 = "onResourceStop"
function L7_1(A0_2)
  local L1_2, L2_2, L3_2
  L1_2 = GetCurrentResourceName
  L1_2 = L1_2()
  if A0_2 ~= L1_2 then
    return
  end
  L1_2 = L0_1
  if L1_2 then
    L1_2 = SetNuiFocus
    L2_2 = false
    L3_2 = false
    L1_2(L2_2, L3_2)
  end
end
L5_1(L6_1, L7_1)
L5_1 = exports
L6_1 = "OpenStudio"
function L7_1()
  local L0_2, L1_2
  L0_2 = L0_1
  if not L0_2 then
    L0_2 = TriggerServerEvent
    L1_2 = "apex_blips:requestStudio"
    L0_2(L1_2)
  end
end
L5_1(L6_1, L7_1)
