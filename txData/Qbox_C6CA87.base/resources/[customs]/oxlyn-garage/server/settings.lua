

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved.

Settings = Settings or {}
Settings.Doc = nil -- the current, sanitised settings document

local resourceName = GetCurrentResourceName()

local function log(msg)
    print(("[%s] %s"):format(resourceName, msg))
end

--- Load settings from the database (falls back to defaults from Config.UI
--- via Utils.SanitiseSettings if they cannot be read).
function Settings.Load()
    local ok, stored = pcall(DB.LoadSettings)
    if not ok then
        log(("^3settings could not be read (%s) — using Config.UI^7"):format(tostring(stored)))
        stored = nil
    end

    Settings.Doc = Utils.SanitiseSettings(stored or {})
    return Settings.Doc
end

--- Current settings (lazily initialised with defaults).
function Settings.Get()
    if not Settings.Doc then
        Settings.Doc = Utils.SanitiseSettings({})
    end
    return Settings.Doc
end

--- Sanitise, persist and broadcast new settings to all clients.
function Settings.Save(data, updatedBy)
    local doc = Utils.SanitiseSettings(data)
    doc.updatedAt = os.time()
    doc.updatedBy = updatedBy

    Settings.Doc = doc
    DB.SaveSettings(doc)

    TriggerClientEvent(resourceName .. ":client:settings", -1, doc)
    TriggerEvent(resourceName .. ":server:settingsSaved", doc)

    return doc
end

--- Delete saved settings and go back to defaults.
function Settings.Reset()
    DB.DeleteSettings()

    Settings.Doc = Utils.SanitiseSettings({})
    TriggerClientEvent(resourceName .. ":client:settings", -1, Settings.Doc)

    return Settings.Doc
end

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("GetSettings", function()
    return Settings.Get()
end)

exports("SaveSettings", function(data, updatedBy)
    return Settings.Save(data, updatedBy or "export")
end)

