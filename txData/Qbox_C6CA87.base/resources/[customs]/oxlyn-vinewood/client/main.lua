

-- Vinewood main client (cleaned from decompiled output)
-- Holds the shared scene state, the editor command, and server <-> UI glue.

Vinewood = {
    scene       = VinewoodMath.copy(Config.DefaultScene),
    revision    = 0,
    received    = false,   -- true once the server has sent us the current scene
    uiReady     = false,   -- true once the NUI has said "ready"
    pendingOpen = nil,     -- editor data waiting for the UI to become ready
}
local Core = Vinewood

---------------------------------------------------------------------
-- Notifications: always toast in the NUI; also a GTA feed ticker when the editor is closed
---------------------------------------------------------------------
function Core.Notify(message, kind)
    SendNUIMessage({
        action  = "toast",
        message = message,
        kind    = kind or "info",
    })

    if not (VinewoodEditor and VinewoodEditor.Active) then
        BeginTextCommandThefeedPost("STRING")
        AddTextComponentSubstringPlayerName(message)
        EndTextCommandThefeedPostTicker(false, false)
    end
end

---------------------------------------------------------------------
-- Locale helper: returns (localeTable, resolvedCode)
---------------------------------------------------------------------
local function getLocale(code)
    local locale, resolved = GetLocaleTable(code)
    return locale, resolved
end

---------------------------------------------------------------------
-- Opening the editor
---------------------------------------------------------------------
local function openEditor(data)
    VinewoodEditor.Open(data)

    -- /command was run in "showcase" mode: tell the UI once the editor is up
    if Core.pendingShowcase and VinewoodEditor.Active then
        SendNUIMessage({ action = "showcase" })
    end
    Core.pendingShowcase = nil
end

RegisterCommand(Config.Command, function(_, args)
    -- NOTE: as decompiled, `showcase` is true whenever `args` is a table, which is
    -- always the case for RegisterCommand. The original may have also checked
    -- args[1] (e.g. == "showcase"); verify against the original behaviour.
    local showcase = type(args) == "table"

    if VinewoodEditor.Active then
        if showcase then
            SendNUIMessage({ action = "showcase" })
        else
            VinewoodEditor.Cursor(true)
            SendNUIMessage({ action = "requestClose" })
        end
    else
        Core.pendingShowcase = showcase or nil
        TriggerServerEvent("oxlyn-vinewood:requestEditor")
    end
end, false)

---------------------------------------------------------------------
-- Server events
---------------------------------------------------------------------
-- Authoritative scene broadcast
RegisterNetEvent("oxlyn-vinewood:state", function(state)
    if type(state) ~= "table" or type(state.scene) ~= "table" then
        return
    end

    Core.received = true
    Core.revision = state.revision
    Core.scene    = state.scene

    if not VinewoodEditor.Active then
        VinewoodRender.SetScene(Core.scene)
    end
end)

-- Server allows us into the editor
RegisterNetEvent("oxlyn-vinewood:editorGranted", function(data)
    if not Core.uiReady then
        Core.pendingOpen = data   -- opened as soon as the NUI reports ready
        return
    end
    openEditor(data)
end)

RegisterNetEvent("oxlyn-vinewood:denied", function(message)
    Core.pendingShowcase = nil
    Core.Notify(message or L("editor_no_permission"), "error")
end)

RegisterNetEvent("oxlyn-vinewood:sessionExpired", function(message)
    Core.pendingOpen = nil
    if VinewoodEditor.Active then
        VinewoodEditor.Close()
    end
    Core.Notify(message or L("editor_session_ended"), "error")
end)

RegisterNetEvent("oxlyn-vinewood:saveResult", function(result)
    if result.ok then
        Core.revision = result.revision
        Core.scene    = result.scene

        if VinewoodEditor.Active then
            VinewoodEditor.Published(result.scene, result.revision)
        end
    end

    SendNUIMessage({
        action   = "saveResult",
        ok       = result.ok,
        error    = result.error,
        scene    = result.scene,
        revision = result.revision,
    })
end)

---------------------------------------------------------------------
-- NUI callbacks
---------------------------------------------------------------------
RegisterNUICallback("ready", function(_, cb)
    Core.uiReady = true

    SetLocale(nil)
    local locale, code = getLocale(Config.Locale)

    cb({
        ok      = true,
        locale  = locale,
        code    = code,
        locales = ListLocales(),
        keys    = Config.Keys,
        ui      = Config.UI,
        version = GetResourceMetadata(GetCurrentResourceName(), "version", 0) or "2.5.0",
    })

    -- an editor grant arrived before the UI was ready
    local pending = Core.pendingOpen
    if pending then
        Core.pendingOpen = nil
        openEditor(pending)
    end
end)

RegisterNUICallback("locale", function(data, cb)
    local requested = (type(data) == "table" and type(data.code) == "string" and data.code) or Config.Locale

    local locale, code = getLocale(requested)
    SetLocale(code)

    cb({ ok = true, locale = locale, code = code })
end)

---------------------------------------------------------------------
-- Ask the server for the scene until we get it
---------------------------------------------------------------------
CreateThread(function()
    while not Core.received do
        TriggerServerEvent("oxlyn-vinewood:requestState")
        Wait(5000)
    end
end)

