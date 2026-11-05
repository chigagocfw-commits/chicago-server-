-- ============================================================
--  GetFrameworkObject()
--  Returns the shared framework core object for whichever
--  framework is configured in CDM.Config.Framework.
--
--  Supported values:
--    "esx"    – ESX  (polls via exports until available)
--    "new-qb" – QBCore modern export style (immediate)
--    "old-qb" – QBCore legacy event style (polls until available)
-- ============================================================
function GetFrameworkObject()
    local frameworkObject = nil
    local configFramework = CDM.Config.Framework

    -- ── ESX ──────────────────────────────────────────────────
    -- Keeps calling getSharedObject() in a loop until it returns
    -- a non-nil value, yielding each iteration to avoid locking.
    if "esx" == configFramework then
        while nil == frameworkObject do
            local esxExports   = exports.es_extended
            frameworkObject    = esxExports:getSharedObject()
            Citizen.Wait(0)
        end
    end

    -- ── QBCore (modern export style) ─────────────────────────
    -- GetCoreObject() is available immediately via the qb-core export.
    -- No loop needed; the export returns the object synchronously.
    configFramework = CDM.Config.Framework
    if "new-qb" == configFramework then
        local qbExports    = exports["qb-core"]
        frameworkObject    = qbExports:GetCoreObject()
    end

    -- ── QBCore (legacy event style) ──────────────────────────
    -- Older QB builds did not expose an export; instead the core
    -- object is retrieved by triggering "QBCore:GetObject" with a
    -- callback. Polls every 200ms until the callback fires and
    -- populates frameworkObject.
    configFramework = CDM.Config.Framework
    if "old-qb" == configFramework then
        while nil == frameworkObject do
            TriggerEvent("QBCore:GetObject", function(coreObject)
                frameworkObject = coreObject
            end)
            Citizen.Wait(200)
        end
    end

    return frameworkObject
end