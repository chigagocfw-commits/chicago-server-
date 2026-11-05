

Client = Client or {}
Client.Ready = false
Client.Admin = false
Client.Focus = nil
Client.Server = { now = 0, at = 0 }
Client.KeysSystem = "none"
Client.Settings = nil

local RESOURCE = GetCurrentResourceName()

-- ---------------------------------------------------------------------------
-- Core helpers
-- ---------------------------------------------------------------------------

function Client.NUI(action, data)
    SendNUIMessage({ type = action, data = data })
end

function Client.ApplySettings(settings)
    local modeBefore
    if Garage and Garage.InteractionMode then
        modeBefore = Garage.InteractionMode()
    end

    Client.Settings = Utils.SanitiseSettings(settings)

    -- Rebuild world targets only if the interaction mode actually changed
    if Garage and Garage.RebuildTargets then
        if Garage.InteractionMode() ~= modeBefore then
            Garage.RebuildTargets()
        end
    end
end

-- Server time (seconds), extrapolated from the last sync
function Client.Now()
    if Client.Server.now == 0 then
        return 0
    end
    return Client.Server.now + math.floor((GetGameTimer() - Client.Server.at) / 1000)
end

-- Accepts (message, type, title) or a table { message, type, title }
function Client.Notify(message, kind, title)
    if type(message) == "table" then
        title = message.title
        kind = message.type
        message = message.message
    end

    message = tostring(message or "")
    if message == "" then return end

    kind = kind or "info"

    if NotifyBridge and NotifyBridge.Send(message, kind, title) then
        return
    end

    if Client.Ready then
        Client.NUI("toast", { type = kind, title = title, message = message })
    else
        Framework.BridgeNotify(message, kind, title)
    end
end

RegisterNetEvent(RESOURCE .. ":client:notify", function(data)
    Client.Notify(data)
end)

-- ---------------------------------------------------------------------------
-- NUI focus
-- ---------------------------------------------------------------------------

local hudLoopRunning = false

local function startHudLoop()
    if hudLoopRunning then return end
    hudLoopRunning = true

    CreateThread(function()
        while Client.Focus do
            if Config.UI.hideHudWhileOpen then
                HideHudAndRadarThisFrame()
            end
            Wait(0)
        end
        hudLoopRunning = false
    end)
end

function Client.SetFocus(name)
    Client.Focus = name
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    startHudLoop()
end

-- If a name is given, only release when that UI currently owns the focus
function Client.ReleaseFocus(name)
    if name and Client.Focus ~= name then return end

    Client.Focus = nil
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end

function Client.Busy()
    return Client.Focus ~= nil
end

-- ---------------------------------------------------------------------------
-- Init payload
-- ---------------------------------------------------------------------------

local function buildInitPayload()
    local worldIcons = Config.Interaction.worldIcons

    return {
        locale = GetLocaleTable(),
        lang = GetCurrentLocale(),
        brandName = (type(Config.UI.brandName) == "string" and Config.UI.brandName) or "OXLYN Garage",
        settings = Client.Settings or Utils.SanitiseSettings({}),
        presets = Utils.PRESETS,
        currency = Config.Currency,
        key = Config.Interaction.keyLabel or "E",

        contract = {
            enabled = Config.Contract.enabled ~= false,
            min = Config.Contract.minPrice,
            max = Config.Contract.maxPrice,
            tax = Config.Contract.tax or 0,
            accounts = Config.Contract.accounts,
            offerMinutes = Config.Contract.offerMinutes or 5,
        },

        fees = {
            retrieve = Config.Garage.retrieveFee or 0,
            transfer = Config.Garage.transferFee or 0,
            global = Config.Garage.global == true,
        },

        admin = Client.Admin,
        garageTypes = Utils.GARAGE_TYPES,
        worldLabels = not worldIcons,

        -- NOTE: kept exactly as in the original (looks inverted, but that's what the script does)
        preview = { enabled = not Config.Garage.preview },

        world = {
            distance = (worldIcons and worldIcons.distance) or 12.0,
            fadeFrom = (worldIcons and worldIcons.fadeFrom) or 6.0,
            labelDistance = (worldIcons and worldIcons.labelDistance) or 5.0,
        },
    }
end

local function sendInit()
    if not Client.Ready then return end

    Client.NUI("init", buildInitPayload())

    if Garage and Garage.ResendPrompt then
        Garage.ResendPrompt()
    end
end

local function fetchInit(cb)
    Framework.TriggerCallback("garage:init", function(res)
        if res then
            Client.Admin = res.admin == true
            Client.KeysSystem = res.keys or "none"
            Client.Identifier = res.identifier

            if type(res.settings) == "table" then
                Client.ApplySettings(res.settings)
            end

            if res.now then
                Client.Server.now = res.now
                Client.Server.at = GetGameTimer()
            end

            sendInit()
        end

        if cb then cb(res) end
    end)
end

RegisterNetEvent(RESOURCE .. ":client:settings", function(settings)
    if type(settings) ~= "table" then return end

    Client.ApplySettings(settings)

    if Client.Ready then
        Client.NUI("settings", Client.Settings)
    end
end)

-- ---------------------------------------------------------------------------
-- NUI callbacks
-- ---------------------------------------------------------------------------

RegisterNUICallback("ready", function(_, cb)
    Client.Ready = true
    cb(1)
    sendInit()
end)

-- Routes the UI's close request to whichever module owns the focus
RegisterNUICallback("close", function(_, cb)
    cb(1)

    local focus = Client.Focus

    if focus == "garage" then
        if Garage then Garage.Close() end
    elseif focus == "adminGarage" then
        if AdminGarage then AdminGarage.Close() end
    elseif focus == "editor" then
        if Editor then Editor.Close() end
    elseif focus == "contract" then
        if ContractUI then ContractUI.Close() end
    elseif focus == "impoundtool" then
        if Garage then Garage.CloseImpoundTool() end
    elseif focus == "zone" then
        if Zone then Zone.End(nil) end
    else
        Client.ReleaseFocus()
    end
end)

-- ---------------------------------------------------------------------------
-- Startup / lifecycle
-- ---------------------------------------------------------------------------

CreateThread(function()
    Framework.Wait()
    Wait(500)
    TriggerServerEvent(RESOURCE .. ":sv:ready")
    fetchInit()
end)

AddEventHandler("playerSpawned", function()
    SetTimeout(1500, function()
        TriggerServerEvent(RESOURCE .. ":sv:ready")
        fetchInit()
    end)
end)

Framework.OnGroupsChanged(function()
    fetchInit()
    TriggerServerEvent(RESOURCE .. ":sv:requestSync")
end)

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName ~= RESOURCE then return end

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    if Garage and Garage.Cleanup then
        Garage.Cleanup()
    end
end)

-- ---------------------------------------------------------------------------
-- Commands
-- ---------------------------------------------------------------------------

if Config.Commands.garage then
    RegisterCommand(Config.Commands.garage, function(_, args)
        CreateThread(function()
            Wait(50)

            if args and args[1] then
                -- /garage <id> : admin view of another player's garage
                if AdminGarage then
                    AdminGarage.Open(args[1])
                end
            elseif Garage then
                Garage.OpenNearest()
            end
        end)
    end, false)
end

if Config.Commands.suggestions then
    local function addSuggestion(command, helpKey, params)
        pcall(TriggerEvent, "chat:addSuggestion", "/" .. command, _U(helpKey), params)
    end

    CreateThread(function()
        Wait(1000)

        local cmds = Config.Commands

        if cmds.garage then
            addSuggestion(cmds.garage, "cmd_garage", {
                { name = "ID", help = _U("cmd_garage_player") },
            })
        end

        if cmds.editor then
            addSuggestion(cmds.editor, "cmd_editor")
        end

        if cmds.impound then
            addSuggestion(cmds.impound, "cmd_impound", {
                { name = "fee", help = "release fee (optional)" },
                { name = "reason", help = "reason (optional)" },
            })
        end

        if cmds.admincar then
            addSuggestion(cmds.admincar, "cmd_admincar")
        end

        if cmds.contract then
            addSuggestion(cmds.contract, "cmd_contract_demo")
        end
    end)
end

-- ---------------------------------------------------------------------------
-- Exports
-- ---------------------------------------------------------------------------

exports("OpenGarage", function(garage)
    if Garage then Garage.OpenMenu(garage) end
end)

exports("OpenNearestGarage", function()
    if Garage then Garage.OpenNearest() end
end)

exports("OpenEditor", function()
    if Editor then Editor.Open() end
end)

exports("IsOpen", function()
    return Client.Focus ~= nil
end)

exports("GetGarages", function()
    return (Garage and Garage.List) or {}
end)

exports("GetNearestGarage", function()
    return Garage and Garage.Nearest()
end)

