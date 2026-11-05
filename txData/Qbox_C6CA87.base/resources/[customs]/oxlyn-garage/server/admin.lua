

Admin = Admin or {}

local RESOURCE = GetCurrentResourceName()

local function log(message)
    print(("[%s] %s"):format(RESOURCE, message))
end

--------------------------------------------------------------------------------
-- Permission check (with rate-limited denial logging)
--------------------------------------------------------------------------------

local lastDenyLog = {} -- source -> os.time() of last logged denial

local function isAdmin(src)
    local allowed, reason = Framework.EvaluateAdmin(src)
    if allowed then return true end

    -- Log at most once every 20s per player
    local now = os.time()
    if now >= (lastDenyLog[src] or 0) + 20 then
        lastDenyLog[src] = now
        log(("%s (%s) was denied the garage editor (%s). Run: %s %s"):format(
            GetPlayerName(src) or "?",
            src,
            reason,
            Config.Commands.access or "garageaccess",
            src
        ))
    end

    return false
end

AddEventHandler("playerDropped", function()
    lastDenyLog[source] = nil
end)

local function fail(cb, key, ...)
    cb({ ok = false, error = key, message = _U(key, ...) })
end

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

Framework.RegisterCallback("admin:open", function(source, cb)
    if not isAdmin(source) then
        return fail(cb, "no_permission")
    end

    cb({
        ok = true,
        garages = Garages.All(),
        settings = Settings.Get(),
        presets = Utils.PRESETS,
        defaults = {
            radius = Config.Garage.defaultRadius or 2.5,
            storeRadius = Config.Garage.defaultStoreRadius or 14.0,
            blips = Config.Blips,
            ped = {
                model = Config.Peds.defaultModel,
                scenario = Config.Peds.defaultScenario,
            },
            impoundFee = Config.Impound.defaultFee or 300,
            fleetPerPlayer = Config.Garage.fleetPerPlayer or 1,
            fleetRecall = Config.Garage.fleetRecall ~= false,
        },
    })
end)

Framework.RegisterCallback("admin:save", function(source, cb, data, extra)
    if not isAdmin(source) then
        return fail(cb, "no_permission")
    end

    if type(data) ~= "table" then
        return fail(cb, "editor_invalid", "no data")
    end

    local garage, err = Garages.Save(data, Framework.GetName(source), extra)

    if not garage then
        if err == "id_taken" then
            return fail(cb, "editor_id_taken")
        end
        return fail(cb, "editor_invalid", tostring(err))
    end

    log(('%s saved garage "%s"'):format(Framework.GetName(source), garage.id))

    cb({
        ok = true,
        garage = garage,
        garages = Garages.All(),
        message = _U("editor_saved", garage.label),
    })
end)

Framework.RegisterCallback("admin:saveSettings", function(source, cb, data)
    if not isAdmin(source) then
        return fail(cb, "no_permission")
    end

    if type(data) ~= "table" then
        return fail(cb, "editor_invalid", "no data")
    end

    local settings = Settings.Save(data, Framework.GetName(source))

    log(("%s saved the interface theme (%s · %s)"):format(
        Framework.GetName(source),
        settings.theme.preset,
        settings.style
    ))

    cb({
        ok = true,
        settings = settings,
        message = _U("ui_theme_saved"),
    })
end)

Framework.RegisterCallback("admin:resetSettings", function(source, cb)
    if not isAdmin(source) then
        return fail(cb, "no_permission")
    end

    cb({
        ok = true,
        settings = Settings.Reset(),
        message = _U("ui_theme_saved"),
    })
end)

Framework.RegisterCallback("admin:delete", function(source, cb, id)
    if not isAdmin(source) then
        return fail(cb, "no_permission")
    end

    local garage = Garages.Get(id)
    if not garage then
        return fail(cb, "garage_not_found")
    end

    Garages.Delete(id)
    log(('%s deleted garage "%s"'):format(Framework.GetName(source), id))

    cb({
        ok = true,
        garages = Garages.All(),
        message = _U("editor_deleted", garage.label),
    })
end)

--------------------------------------------------------------------------------
-- Editor command
--------------------------------------------------------------------------------

if Config.Commands.editor then
    RegisterCommand(Config.Commands.editor, function(source)
        if source == 0 then
            return log("the editor is an in-game tool")
        end

        if not isAdmin(source) then
            return Framework.Notify(source, _U("no_permission"), "error")
        end

        TriggerClientEvent(RESOURCE .. ":client:openEditor", source)
    end, false)
end

--------------------------------------------------------------------------------
-- Access diagnostics
--------------------------------------------------------------------------------

-- Builds a human-readable report on why a player does/doesn't have admin access
function Admin.Report(src)
    local lines = {}
    local function add(text) lines[#lines + 1] = text end

    local name = GetPlayerName(src) or "?"

    add(("── %s admin access report for %s (id %s) ──"):format(RESOURCE, name, src))
    add(("framework: %s   group: %s"):format(Framework.Name or "standalone", Framework.GetGroup(src)))

    local job = Framework.GetJob(src)
    if job then
        add(("job: %s grade %s%s"):format(job.name, job.grade, job.onDuty and "" or " (off duty)"))
    end

    local cfg = (type(Config.Admin) == "table" and Config.Admin) or {}
    add(("methods: %s   everyone: %s"):format(
        table.concat(cfg.methods or {}, ", "),
        tostring(cfg.everyone == true)
    ))

    local allowed, summary, trace = Framework.EvaluateAdmin(src)
    for _, entry in ipairs(trace) do
        add(("  %-10s %-6s %s"):format(entry.source, entry.verdict, entry.note))
    end

    add(("RESULT: %s (%s)"):format(
        allowed and _U("access_allowed") or _U("access_denied"),
        summary
    ))

    if not allowed then
        local license = GetPlayerIdentifierByType(src, "license") or "license:UNKNOWN"
        local ace = (cfg.aces and cfg.aces[1]) or "oxlyn.garage.admin"

        add("To allow this player, add to server.cfg (needs a full restart) or paste in the console:")
        add(("  add_ace group.admin %s allow"):format(ace))
        add(("  add_principal identifier.%s group.admin"):format(license))
        add("Or list them in Config.Admin.identifiers:")
        add(("  identifiers = { '%s' }"):format(license))
        add("Identifiers: " .. table.concat(Framework.IdentifiersOf(src), ", "))
    end

    return lines
end

if Config.Commands.access then
    RegisterCommand(Config.Commands.access, function(source, args)
        -- Target: explicit player id, otherwise the caller (not the console)
        local target = tonumber(args[1]) or (source ~= 0 and source or nil)

        if not (target and GetPlayerName(target)) then
            if source == 0 then
                log(("usage: %s <player id>"):format(Config.Commands.access))
            end
            return
        end

        if source ~= 0 and not Framework.IsAdmin(source) and not IsPlayerAceAllowed(source, "command") then
            return Framework.Notify(source, _U("no_permission"), "error")
        end

        for _, line in ipairs(Admin.Report(target)) do
            print(line)
            if source ~= 0 then
                TriggerClientEvent("chat:addMessage", source, { args = { "^3garage", line } })
            end
        end
    end, false)
end

