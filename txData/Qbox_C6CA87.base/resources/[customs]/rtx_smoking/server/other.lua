--       _                           _   _             _                   _             _                
--   ___| | ___  __ _ _ __   ___  __| | | |__  _   _  | |__  _ __ __ _  __| |_   _   ___| |_ ___ _ __     
--  / __| |/ _ \/ _` | '_ \ / _ \/ _` | | '_ \| | | | | '_ \| '__/ _` |/ _` | | | | / __| __/ _ \ '_ \    
-- | (__| |  __/ (_| | | | |  __/ (_| | | |_) | |_| | | |_) | | | (_| | (_| | |_| | \__ \ ||  __/ | | |   
--  \___|_|\___|\__,_|_| |_|\___|\__,_| |_.__/ \__, | |_.__/|_|  \__,_|\__,_|\__, | |___/\__\___|_| |_|   
--  / _(_)_  _____  __| | | |__  _   _  | |__  |___/ ___(_)_ __ ___   | |__  |___/_ __ _ __ ___ _ __ __ _ 
-- | |_| \ \/ / _ \/ _` | | '_ \| | | | | '_ \ / _` |_  / | '_ ` _ \  | '_ \ / _ \ '__| '__/ _ \ '__/ _` |
-- |  _| |>  <  __/ (_| | | |_) | |_| | | | | | (_| |/ /| | | | | | | | | | |  __/ |  | | |  __/ | | (_| |
-- |_| |_/_/\_\___|\__,_| |_.__/ \__, | |_| |_|\__,_/___|_|_| |_| |_| |_| |_|\___|_|  |_|  \___|_|  \__,_|
--                               |___/
--   

-- ── événement local déclenché à chaque bouffée ───────────
AddEventHandler('rtx_smoking:client:OnPuff', function(data)
    -- data.type       : type de l'item ("cigarette","cigar","joint","bong","vape","hookah")
    -- data.amount     : force de la bouffée (0.1 à 10.0)
    -- data.holdDuration : durée de maintien en ms
    -- data.autoReleased : true si relâché automatiquement
    -- data.item       : nom exact de l'item
    -- data.hookahId   : uniquement si type == "hookah"
    -- data.stats      : stats actuelles de l'item
end)

-- ── affichage d'interaction ───────────────────────────────
function ShowGtaClassicInteraction(text)
    AddTextEntry('gtavclassicinteractionrtxaireastery', text)
    BeginTextCommandDisplayHelp('gtavclassicinteractionrtxaireastery')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

function showHelp(text, coords)
    local key = 'floatingHelpNotification' .. GetGameTimer() // 10000
    AddTextEntry(key, "<FONT SIZE='8'>" .. text)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0)
    BeginTextCommandDisplayHelp(key)
    EndTextCommandDisplayHelp(2, false, false, 0)
end

-- ── genre du joueur ───────────────────────────────────────
function GetPlayerGender()
    local ped   = PlayerPedId()
    local model = GetEntityModel(ped)
    if model == GetHashKey('mp_m_freemode_01') then return 'male'   end
    if model == GetHashKey('mp_f_freemode_01') then return 'female' end
    return 'unknown'
end

function GetCoughSoundKey()
    if GetPlayerGender() == 'female' then return 'cough_female' end
    return 'cough_male'
end

function GetExhaleSoundKey()
    if GetPlayerGender() == 'female' then return 'exhalefemale' end
    return 'exhalemale'
end

-- ── texte 3D ─────────────────────────────────────────────
function DrawText3D(x, y, z, text)
    local onScreen, sx, sy = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 255)
    SetTextEntry('STRING')
    SetTextCentre(1)
    AddTextComponentString(text)
    DrawText(sx, sy)
    local factor = #text / 240
    DrawRect(sx, sy + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 150)
end

-- ── système d'interaction ─────────────────────────────────
function ShowInteraction(textKey, coords)
    local system = Config.SmokingInteractionSystem
    if system == 1 then
        SendNUIMessage({
            message        = 'infonotifyshow',
            infonotifytext = Language[Config.Language][textKey .. '-normal'],
        })
        Citizen.Wait(500)
    elseif system == 2 then
        DrawText3D(coords.x, coords.y, coords.z, Language[Config.Language][textKey .. '-3d'])
    elseif system == 3 then
        ShowGtaClassicInteraction(Language[Config.Language][textKey .. '-classic'])
    elseif system == 4 then
        showHelp(Language[Config.Language][textKey .. '-float'], coords)
    end
end

function HideInteraction()
    if Config.SmokingInteractionSystem == 1 then
        SendNUIMessage({ message = 'hidenotify' })
    end
end

-- ── système de target ─────────────────────────────────────
function AddTargetZone(targetType, zoneName, targetData, heading, distance, label, icon, event)
    local t = Config.Targettype
    if t == 'qtarget' then
        if targetType == 'coords' then
            local coords = vector3(targetData.x, targetData.y, targetData.z + 0.5)
            exports[Config.TargetSystemsNames.qtarget]:AddBoxZone(zoneName, coords, 2.5, 2.5, {
                name     = zoneName,
                heading  = heading,
                debugPoly = false,
                minZ     = coords.z - 1.5,
                maxZ     = coords.z + 1.5,
            }, {
                options  = { { event = event, icon = icon, label = label } },
                distance = distance,
            })
        else
            exports[Config.TargetSystemsNames.qtarget]:AddTargetModel({ GetHashKey(targetData) }, {
                options  = { { name = zoneName, event = event, icon = icon, label = label } },
                distance = distance,
            })
        end
    elseif t == 'qbtarget' then
        if targetType == 'coords' then
            local coords = vector3(targetData.x, targetData.y, targetData.z + 0.5)
            exports[Config.TargetSystemsNames.qbtarget]:AddBoxZone(zoneName, coords, 2.5, 2.5, {
                name      = zoneName,
                heading   = heading,
                debugPoly = false,
                minZ      = coords.z - 1.5,
                maxZ      = coords.z + 1.5,
            }, {
                options = { {
                    type   = 'client',
                    action = function() TriggerEvent(event) end,
                    icon   = icon,
                    label  = label,
                } },
                distance = distance,
            })
        else
            exports[Config.TargetSystemsNames.qbtarget]:AddTargetModel({ GetHashKey(targetData) }, {
                options  = { { name = zoneName, event = event, icon = icon, label = label } },
                distance = distance,
            })
        end
    elseif t == 'oxtarget' then
        if targetType == 'coords' then
            local coords = vector3(targetData.x, targetData.y, targetData.z + 0.5)
            exports[Config.TargetSystemsNames.oxtarget]:addBoxZone({
                coords  = coords,
                size    = vec3(2, 2, 2),
                rotation = heading,
                options = { {
                    name       = zoneName,
                    event      = event,
                    icon       = icon,
                    distance   = distance,
                    label      = label,
                    canInteract = function() return true end,
                } },
            })
        else
            exports[Config.TargetSystemsNames.oxtarget]:addModel(GetHashKey(targetData), {
                { name = zoneName, event = event, icon = icon, label = label },
            })
        end
    end
end

-- ── barre de progression ──────────────────────────────────

-- ── notifications HelpNotify ──────────────────────────────
local HelpNotify = {}

function HelpNotify.Show(opts)
    opts = opts or {}
    SendNUIMessage({
        message    = 'HelpNotifyShow',
        title      = opts.title      or 'Help',
        text       = opts.text       or '',
        tagline    = opts.tagline    or nil,
        icon       = opts.icon       or 'fa-circle-info',
        keys       = opts.keys       or nil,
        autoHideMs = opts.autoHideMs or 0,
    })
end

function HelpNotify.Hide()
    SendNUIMessage({ message = 'HelpNotifyHide' })
end

exports('ShowHelpNotify', HelpNotify.Show)
exports('HideHelpNotify', HelpNotify.Hide)

-- ── notifications Notify ──────────────────────────────────
local notifyIdCounter = 0

local NotifySystem = {}

function NotifySystem.Show(opts)
    opts = opts or {}
    notifyIdCounter = notifyIdCounter + 1
    SendNUIMessage({
        message = 'NotifyShow',
        id      = notifyIdCounter,
        title   = opts.title   or 'Notification',
        text    = opts.text    or '',
        type    = opts.type    or 'info',
        timeout = opts.timeout or 5000,
        icon    = opts.icon    or nil,
    })
end

function NotifySystem.Hide(id)
    if not id then return end
    SendNUIMessage({ message = 'NotifyHide', id = id })
end

function NotifySystem.HideAll()
    SendNUIMessage({ message = 'NotifyHide' })
end

exports('ShowNotify',    NotifySystem.Show)
exports('HideNotify',    NotifySystem.Hide)
exports('HideAllNotify', NotifySystem.HideAll)

-- ── targets narguilé ─────────────────────────────────────
function CreateHookahTargets()
    local t = Config.Targettype
    local model = GetHashKey('rtx_sempre_smoking_shisha')
    local dist  = Config.HookahInteractDistance + 2.5
    local opts  = {
        { name = 'hookahinteract', event = 'rtx_smoking:Global:HookahInteractTarget', icon = Config.TargetIcons.hookahmanage, label = Language[Config.Language]['hookah']     },
        { name = 'hookahgrab',     event = 'rtx_smoking:Global:HookahHoseTarget',     icon = Config.TargetIcons.hookahgrab,    label = Language[Config.Language]['hookahhose'] },
    }
    if t == 'qtarget' then
        exports[Config.TargetSystemsNames.qtarget]:AddTargetModel({ model }, { options = opts, distance = dist })
    elseif t == 'qbtarget' then
        exports[Config.TargetSystemsNames.qbtarget]:AddTargetModel({ model }, { options = opts, distance = dist })
    elseif t == 'oxtarget' then
        exports[Config.TargetSystemsNames.oxtarget]:addModel(model, {
            { name = opts[1].name, event = opts[1].event, icon = opts[1].icon, label = opts[1].label },
            { name = opts[2].name, event = opts[2].event, icon = opts[2].icon, label = opts[2].label },
        })
    end
end