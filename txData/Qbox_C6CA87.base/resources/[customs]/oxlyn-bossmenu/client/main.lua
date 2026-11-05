

--------------------------------------------------------------------
-- oxlyn-bossmenu | main client script (cleaned)
-- Handles: NUI <-> server callbacks, open/close, command + keybind,
-- and the in-world computer locations (native / ox_target / qb-target).
--------------------------------------------------------------------

local RESOURCE_TAG = "oxlyn-bossmenu"

local isOpen  = false
local locales = {}

--------------------------------------------------------------------
-- Server callback wrapper (waits for Framework to be ready, 10s max)
--------------------------------------------------------------------
local function triggerCb(name, cb, ...)
    local args = table.pack(...)

    CreateThread(function()
        local waited = 0
        while not (Framework and Framework.ready) and waited < 10000 do
            Wait(50)
            waited = waited + 50
        end

        if not (Framework and Framework.ready) then
            print(("^1[%s] triggerCb timeout (10s) — Framework not ready. Callback %s was not sent.^7")
                :format(RESOURCE_TAG, name))
            if cb then cb(nil) end
            return
        end

        Framework.TriggerCallback(name, cb, table.unpack(args, 1, args.n))
    end)
end

--------------------------------------------------------------------
-- Locales
--------------------------------------------------------------------
local function loadLocales()
    local raw = LoadResourceFile(GetCurrentResourceName(), "locales/" .. Config.Locale .. ".json")
    if raw then
        locales = json.decode(raw) or {}
    end
end

-- Translate a key, replacing {placeholders} from `vars`.
local function t(key, vars)
    local text = locales[key] or key
    if vars then
        for k, v in pairs(vars) do
            text = text:gsub("{" .. k .. "}", tostring(v))
        end
    end
    return text
end

--------------------------------------------------------------------
-- Notifications (ox_lib / oxlyn-notify / framework fallback)
--------------------------------------------------------------------
local function notify(notifyType, message)
    if Config.NotifyType == "ox_lib" then
        if lib and lib.notify then
            lib.notify({
                type        = notifyType or "inform",
                description = message,
                duration    = Config.NotifyDuration,
            })
            return
        end
    elseif Config.NotifyType == "oxlyn-notify" then
        local notifyExport = exports["oxlyn-notify"]
        if notifyExport and notifyExport.ShowNotification then
            notifyExport:ShowNotification(notifyType or "info", "BossMenu", message, Config.NotifyDuration)
            return
        end
    end

    if Framework and Framework.Notify then
        Framework.Notify(notifyType or "inform", message)
    end
end

--------------------------------------------------------------------
-- NUI "open" payload
--------------------------------------------------------------------
local function buildOpenMessage(info)
    return {
        action = "open",
        config = {
            system      = Config.System,
            accounts    = (info and info.accounts) or {},
            wallpaper   = Config.Wallpaper,
            wallpapers  = Config.Wallpapers,
            cursorStyle = Config.CursorStyle,
            apps        = Config.Apps,
            store       = Config.Store,
            browser     = Config.Browser,
            calculator  = Config.Calculator,
            currency    = Config.Currency,
            company     = info and info.company or nil,
            playerId    = info and info.identifier or nil,
            playerName  = (info and (info.playerName or info.firstName)) or "Player",
            isBoss      = info ~= nil and info.isBoss == true,
            myAccess    = (info and info.myAccess) or "limited",
            myGrade     = (info and info.myGrade) or 0,
            settings    = info and info.settings or nil,
        },
        locales = locales,
    }
end

--------------------------------------------------------------------
-- NUI -> server bridges
--------------------------------------------------------------------
local function okReply(res)   return { ok = res } end
local function okOrFalse(res) return res or { ok = false } end

-- register(nuiName, serverEvent, getArgs(data) -> ..., buildReply(res) -> table)
local function register(nuiName, serverEvent, getArgs, buildReply)
    RegisterNUICallback(nuiName, function(data, cb)
        data = data or {}
        local args = getArgs and table.pack(getArgs(data)) or { n = 0 }
        triggerCb(serverEvent, function(res)
            cb(buildReply(res))
        end, table.unpack(args, 1, args.n))
    end)
end

-- Company / accounts
register("getCompanyData", "oxlyn-bossmenu:getCompanyData", nil,
    function(res) return res or {} end)

register("createAccount", "oxlyn-bossmenu:createAccount",
    function(d) return d.name or "", d.color or "", d.password or "", d.isMaster == true end,
    function(res) return { ok = res ~= nil, accounts = res } end)

register("deleteAccount", "oxlyn-bossmenu:deleteAccount",
    function(d) return d.id or "" end,
    function(res) return { ok = res ~= nil, accounts = res } end)

-- Employees
register("listPlayers", "oxlyn-bossmenu:listOnlinePlayers", nil,
    function(res) return { players = res or {} } end)

register("hirePlayer", "oxlyn-bossmenu:hireEmployee",
    function(d) return d.source, d.grade or 0 end,
    okReply)

register("setGrade", "oxlyn-bossmenu:setEmployeeGrade",
    function(d) return d.identifier, d.grade or 0 end,
    okReply)

register("firePlayer", "oxlyn-bossmenu:fireEmployee",
    function(d) return d.identifier end,
    okReply)

register("setGradeSalary", "oxlyn-bossmenu:setGradeSalary",
    function(d) return d.grade, d.salary or 0 end,
    okReply)

-- Money
register("depositMoney", "oxlyn-bossmenu:depositMoney",
    function(d) return d.amount or 0, d.note or "" end,
    okOrFalse)

register("withdrawMoney", "oxlyn-bossmenu:withdrawMoney",
    function(d) return d.amount or 0, d.note or "" end,
    okOrFalse)

register("payBonus", "oxlyn-bossmenu:payBonus",
    function(d) return d.identifier, d.amount or 0, d.note or "" end,
    okOrFalse)

register("getTransactions", "oxlyn-bossmenu:getTransactions", nil,
    function(res) return res or { rows = {} } end)

-- Timesheet
register("getTimesheet", "oxlyn-bossmenu:getTimesheet", nil,
    function(res) return res or { shifts = {}, isBoss = false } end)

register("clockIn", "oxlyn-bossmenu:clockIn",
    function(d) return d.identifier or "" end,
    okOrFalse)

register("clockOut", "oxlyn-bossmenu:clockOut",
    function(d) return d.shiftId or 0 end,
    okOrFalse)

register("clearTimesheet", "oxlyn-bossmenu:clearTimesheet", nil,
    okReply)

-- Settings
register("getCompanySettings", "oxlyn-bossmenu:getCompanySettings", nil,
    function(res) return res or { allowedGrades = {}, tabAccess = {} } end)

register("setCompanySettings", "oxlyn-bossmenu:setCompanySettings",
    function(d) return d.settings or {} end,
    okReply)

-- Ranks
register("addRank", "oxlyn-bossmenu:addRank",
    function(d) return d end,
    okOrFalse)

register("updateRankLabel", "oxlyn-bossmenu:updateRankLabel",
    function(d) return d.grade, d.label or "" end,
    okOrFalse)

register("deleteRank", "oxlyn-bossmenu:deleteRank",
    function(d) return d.grade end,
    okOrFalse)

--------------------------------------------------------------------
-- Open / close
--------------------------------------------------------------------
local function openBossMenu()
    if isOpen then return end

    if not (Framework and Framework.ready) then
        local msg = t("lua_diag_framework_not_ready")
        print("^3" .. msg .. "^7")
        notify("error", msg)
        return
    end

    triggerCb("oxlyn-bossmenu:canOpen", function(canOpen)
        if canOpen == nil then
            notify("error", t("lua_diag_no_server_response"))
            return
        end

        if not canOpen then
            notify("error", t("no_permission"))
            return
        end

        triggerCb("oxlyn-bossmenu:getPlayerInfo", function(info)
            if not info then
                notify("error", t("lua_diag_no_permission_or_data_error"))
                return
            end

            isOpen = true
            SetNuiFocus(true, true)
            SendNUIMessage(buildOpenMessage(info))
        end)
    end)
end

local function closeBossMenu()
    if not isOpen then return end

    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = "close" })
end

RegisterNUICallback("close", function(_, cb)
    closeBossMenu()
    cb({ ok = true })
end)

RegisterNUICallback("ready", function(_, cb)
    cb({ ok = true })
end)

--------------------------------------------------------------------
-- Command, keybind, exports
--------------------------------------------------------------------
local computerEnabled = Config.Computer and Config.Computer.enabled
local disableCommand  = computerEnabled and Config.Computer.disableCommand

if Config.Command and Config.Command ~= "" and not disableCommand then
    RegisterCommand(Config.Command, function()
        openBossMenu()
    end, false)
end

if Config.OpenKey and Config.OpenKey ~= "" then
    RegisterKeyMapping("+oxlynBossmenu", t("lua_keymap_open_bossmenu"), "keyboard", Config.OpenKey)
    RegisterCommand("+oxlynBossmenu", function() openBossMenu() end, false)
    RegisterCommand("-oxlynBossmenu", function() end, false)
end

exports("open", openBossMenu)
exports("close", closeBossMenu)

RegisterCommand("bossmenu_reset", function()
    SendNUIMessage({ action = "factoryReset" })
    notify("inform", t("lua_notify_factory_reset", {
        _d = "PC reposto às definições de fábrica. Reabre o computador.",
    }))
end, false)

-- While open: block pause menu keys, ESC (200) closes the menu
CreateThread(function()
    while true do
        if isOpen then
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 322, true)
            if IsDisabledControlJustReleased(0, 200) then
                closeBossMenu()
            end
            Wait(0)
        else
            Wait(500)
        end
    end
end)

--------------------------------------------------------------------
-- Interaction prompt + 3D icon (NUI overlays)
--------------------------------------------------------------------
local promptShown    = false
local promptLocation = nil

local function showInteractPrompt(location)
    if promptShown and promptLocation == location then return end

    promptShown    = true
    promptLocation = location

    local labelKey = (location and location.label) or "lua_label_computer"
    local hintKey  = (Config.Computer and Config.Computer.promptHint) or "app_interact_hint"

    SendNUIMessage({
        action = "showInteractPrompt",
        label  = t(labelKey),
        hint   = t(hintKey),
        key    = "E",
    })
end

local function hideInteractPrompt()
    if not promptShown then return end

    promptShown    = false
    promptLocation = nil
    SendNUIMessage({ action = "hideInteractPrompt" })
end

-- Projects a world position to screen; scale shrinks with distance.
local function worldToScreen(coords, distance)
    local onScreen, sx, sy = World3dToScreen2d(coords.x, coords.y, coords.z)
    if not onScreen then return nil end

    local scale = math.max(0.55, math.min(1.15, 4.5 / math.max(0.5, distance)))
    return sx, sy, scale
end

local POS_EPSILON   = 0.0015
local SCALE_EPSILON = 0.01

local iconShown = false
local lastIconX, lastIconY, lastIconScale = -1.0, -1.0, -1.0

local function show3DIcon(x, y, scale)
    -- Skip redundant NUI messages when the icon barely moved
    if iconShown
        and math.abs(x - lastIconX) < POS_EPSILON
        and math.abs(y - lastIconY) < POS_EPSILON
        and math.abs(scale - lastIconScale) < SCALE_EPSILON then
        return
    end

    lastIconX, lastIconY, lastIconScale = x, y, scale
    iconShown = true

    SendNUIMessage({ action = "show3DIcon", x = x, y = y, scale = scale })
end

local function hide3DIcon()
    if not iconShown then return end

    iconShown = false
    lastIconX, lastIconY, lastIconScale = -1.0, -1.0, -1.0
    SendNUIMessage({ action = "hide3DIcon" })
end

--------------------------------------------------------------------
-- In-world computer locations
--------------------------------------------------------------------
local locations = computerEnabled and Config.Computer.locations
if locations and #locations > 0 then
    local targetSystem = Config.Computer.targetSystem or "native"

    -- Precompute values used by the proximity loop
    for _, loc in ipairs(locations) do
        local c = loc.coords
        loc._cx, loc._cy, loc._cz = c.x + 0.0, c.y + 0.0, c.z + 0.0

        local renderDist   = loc.renderDist or 10.0
        local interactDist = loc.interactDist or 1.6
        loc._renderDist2   = renderDist * renderDist
        loc._interactDist2 = interactDist * interactDist

        loc._iconZ = loc._cz + (loc.iconHeight or 1.05)
        loc._key   = loc.key or 38 -- E
    end

    -- Spawn optional props
    CreateThread(function()
        for _, loc in ipairs(locations) do
            if loc.spawnProp and loc.propModel then
                local model = (type(loc.propModel) == "number" and loc.propModel)
                    or GetHashKey(loc.propModel)

                RequestModel(model)
                local waited = 0
                while not HasModelLoaded(model) and waited < 5000 do
                    Wait(50)
                    waited = waited + 50
                end

                if HasModelLoaded(model) then
                    local obj = CreateObject(model, loc.coords.x, loc.coords.y, loc.coords.z, false, false, false)
                    SetEntityHeading(obj, loc.heading or 0.0)
                    FreezeEntityPosition(obj, true)
                    SetEntityAsMissionEntity(obj, true, true)
                    loc._spawnedObj = obj
                end
                SetModelAsNoLongerNeeded(model)
            end
        end
    end)

    if targetSystem == "native" then
        -- Distance polling + 3D icon + prompt
        CreateThread(function()
            local count = #locations

            while true do
                local sleep      = 1000
                local nearest    = nil
                local iconDrawn  = false

                if not isOpen then
                    local p = GetEntityCoords(PlayerPedId())

                    for i = 1, count do
                        local loc = locations[i]
                        local dx, dy, dz = loc._cx - p.x, loc._cy - p.y, loc._cz - p.z
                        local dist2 = dx * dx + dy * dy + dz * dz

                        if dist2 < loc._renderDist2 then
                            sleep = 0

                            if not iconDrawn then
                                local sx, sy, scale = worldToScreen(
                                    vector3(loc._cx, loc._cy, loc._iconZ),
                                    math.sqrt(dist2)
                                )
                                if sx then
                                    show3DIcon(sx, sy, scale)
                                    iconDrawn = true
                                end
                            end

                            if dist2 < loc._interactDist2 and not nearest then
                                nearest = loc
                            end
                        end
                    end
                end

                if not iconDrawn then
                    hide3DIcon()
                end

                if nearest then
                    showInteractPrompt(nearest)
                    if IsControlJustReleased(0, nearest._key) then
                        openBossMenu()
                    end
                else
                    hideInteractPrompt()
                end

                Wait(sleep)
            end
        end)

    elseif targetSystem == "ox_target" then
        if GetResourceState("ox_target") ~= "started" then
            print(("^1[%s] targetSystem=\"ox_target\" but the ox_target resource is not started.^7"):format(RESOURCE_TAG))
        else
            CreateThread(function()
                for i, loc in ipairs(locations) do
                    exports.ox_target:addBoxZone({
                        name     = ("oxlyn_bossmenu_%d"):format(i),
                        coords   = loc.coords,
                        size     = vector3(1.2, 1.2, 1.4),
                        rotation = loc.heading or 0.0,
                        debug    = false,
                        options  = {
                            {
                                name     = ("oxlyn_bossmenu_open_%d"):format(i),
                                icon     = "fas fa-desktop",
                                label    = loc.label or t("lua_label_access_computer"),
                                distance = (loc.interactDist or 1.6) + 0.4,
                                onSelect = function() openBossMenu() end,
                            },
                        },
                    })
                end
            end)
        end

    elseif targetSystem == "qb-target" then
        if GetResourceState("qb-target") ~= "started" then
            print(("^1[%s] targetSystem=\"qb-target\" but the qb-target resource is not started.^7"):format(RESOURCE_TAG))
        else
            CreateThread(function()
                for i, loc in ipairs(locations) do
                    local zoneName = ("oxlyn_bossmenu_%d"):format(i)

                    exports["qb-target"]:AddBoxZone(
                        zoneName,
                        vector3(loc.coords.x, loc.coords.y, loc.coords.z),
                        1.2, 1.2,
                        {
                            name      = zoneName,
                            heading   = loc.heading or 0.0,
                            debugPoly = false,
                            minZ      = loc.coords.z - 1.0,
                            maxZ      = loc.coords.z + 1.0,
                        },
                        {
                            options = {
                                {
                                    type   = "client",
                                    icon   = "fas fa-desktop",
                                    label  = loc.label or t("lua_label_access_computer"),
                                    action = function() openBossMenu() end,
                                },
                            },
                            distance = (loc.interactDist or 1.6) + 0.4,
                        }
                    )
                end
            end)
        end

    else
        print(("^3[%s] targetSystem=\"%s\" unknown — use \"native\", \"ox_target\" or \"qb-target\".^7")
            :format(RESOURCE_TAG, tostring(targetSystem)))
    end

    -- Cleanup of props / target zones on stop
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName ~= GetCurrentResourceName() then return end

        for i, loc in ipairs(locations) do
            if loc._spawnedObj and DoesEntityExist(loc._spawnedObj) then
                DeleteObject(loc._spawnedObj)
            end

            if targetSystem == "ox_target" and GetResourceState("ox_target") == "started" then
                pcall(function()
                    exports.ox_target:removeZone(("oxlyn_bossmenu_%d"):format(i))
                end)
            elseif targetSystem == "qb-target" and GetResourceState("qb-target") == "started" then
                pcall(function()
                    exports["qb-target"]:RemoveZone(("oxlyn_bossmenu_%d"):format(i))
                end)
            end
        end
    end)
end

--------------------------------------------------------------------
-- Init / shutdown
--------------------------------------------------------------------
CreateThread(loadLocales)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() and isOpen then
        SetNuiFocus(false, false)
    end
end)

