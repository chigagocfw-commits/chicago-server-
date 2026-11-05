

-- Cleaned from decompiler output (register-style L0_1/L1_2 names -> readable names).
-- Logic is preserved; tangled goto/if chains were rebuilt by intent.

local resourceName = GetCurrentResourceName()
local version = GetResourceMetadata(resourceName, "version", 0) or "?"

local ready = false

local function log(msg)
    print(("[%s] %s"):format(resourceName, msg))
end

---------------------------------------------------------------------
-- Boot
---------------------------------------------------------------------

CreateThread(function()
    Framework.Wait()

    if GetResourceState("oxmysql") ~= "started" then
        log("^1oxmysql is not started — the garage system cannot work without it.^7")
        return
    end

    local ok, err = pcall(DB.Init)
    if not ok then
        log(("^1database init failed: %s^7"):format(tostring(err)))
        return
    end

    Settings.Load()
    Garages.Load()
    Park.Boot()
    Vehicles.Boot()
    Contract.Boot()

    ready = true

    -- Sync everyone who was already connected when the resource started
    for _, playerId in ipairs(GetPlayers()) do
        local src = tonumber(playerId)
        if src then
            Garages.SyncPlayer(src)
        end
    end

    log(("^2v%s ready^7 · framework %s · db %s · inventory %s · keys %s (bridge %s)"):format(
        version,
        Framework.Name or "standalone",
        tostring(DB.Mode),
        Inventory.Mode(),
        Keys.System(),
        Keys.Build or "?"
    ))
end)

---------------------------------------------------------------------
-- Player join
---------------------------------------------------------------------

--- Sync garages and deliver pending contract refunds to a player.
--- If boot hasn't finished yet, retry once after a short delay.
local function onPlayerReady(src)
    if not ready then
        SetTimeout(1500, function()
            if GetPlayerName(src) then -- still connected
                Garages.SyncPlayer(src)
                Contract.DeliverRefunds(src)
            end
        end)
        return
    end

    Garages.SyncPlayer(src)
    Contract.DeliverRefunds(src)
end

Framework.OnPlayerLoaded(onPlayerReady)

RegisterNetEvent(resourceName .. ":sv:ready", function()
    onPlayerReady(source)
end)

---------------------------------------------------------------------
-- Callbacks
---------------------------------------------------------------------

Framework.RegisterCallback("garage:init", function(src, cb)
    cb({
        ok         = ready,
        admin      = Framework.IsAdmin(src),
        now        = os.time(),
        keys       = Keys.System(),
        settings   = Settings.Get(),
        identifier = Framework.GetIdentifier(src),
    })
end)

---------------------------------------------------------------------
-- Exports
---------------------------------------------------------------------

exports("GetGarages", function()
    return Garages.All()
end)

exports("GetGarage", function(id)
    return Garages.Get(id)
end)

exports("IsAdmin", function(src)
    return Framework.IsAdmin(src)
end)

exports("CanAccessGarage", function(src, garageId)
    local garage = Garages.Get(garageId)
    return garage and Garages.CanAccess(src, garage) or false
end)

--- Returns: success (bool), garage (on success) or error string (on failure)
exports("SaveGarage", function(data, createdBy)
    local garage, err = Garages.Save(data, createdBy or "export")
    return garage ~= nil, garage or err
end)

exports("DeleteGarage", function(id)
    return Garages.Delete(id)
end)

