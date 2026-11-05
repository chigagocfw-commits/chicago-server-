Modules.initAll()

-- ⚠️ Placeholder function for logout validation (always allows logout by default)
function CanPlayerLogout(source)
    return true
end

local Multichar = Modules.require("Multichar")
local VipSlots = Modules.require("VipSlots")
local Appearance = Modules.require("Appearance")

local multichar = Multichar:new()
local vipSlots = VipSlots:new()

AddEventHandler("onResourceStart", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    vipSlots:ensureTable()
end)

RegisterNetEvent("wasabi_multichar:setNewWorld")
AddEventHandler("wasabi_multichar:setNewWorld", function()
    local src = source
    SetPlayerRoutingBucket(src, src)
end)

lib.callback.register("wasabi_multichar:getCharacters", function(source)
    return multichar:getCharacters(source)
end)

lib.callback.register("wasabi_multichar:getSlotConfig", function(source)
    local normalSlots = Config.MaxSlots or 5
    local vipSlotsCount = vipSlots:getCount(source)
    local canRedeem = type(Config.TebexPackageID) == "number" and Config.TebexPackageID > 0

    return {
        maxSlots = normalSlots + vipSlotsCount,
        normalSlots = normalSlots,
        vipSlots = vipSlotsCount,
        canRedeemSlot = canRedeem
    }
end)

lib.callback.register("wasabi_multichar:createCharacter", function(source, data)
    return multichar:createCharacter(source, data)
end)

lib.callback.register("wasabi_multichar:deleteCharacter", function(source, slot, characterId)
    local success, message = multichar:deleteCharacter(source, slot, characterId)
    if success then
        TriggerClientEvent("wasabi_multichar:refreshCharacters", source, slot)
    end
    return success, message
end)

lib.callback.register("wasabi_multichar:confirmTebexPurchase", function(source, transactionId)
    return vipSlots:confirmTebexPurchase(source, transactionId)
end)

lib.callback.register("wasabi_multichar:getPermissions", function(source)
    local canDelete = false
    if Config.AllowDeletion then
        canDelete = not Config.DeleteCharacterRestricted or IsPlayerAceAllowed(source, "wasabi_multichar.delete")
    end

    local canLogout = not Config.LogoutCommand.onlyStaff or IsPlayerAceAllowed(source, "wasabi_multichar.staff")

    return {
        canDelete = canDelete,
        canLogout = canLogout
    }
end)

lib.callback.register("wasabi_multichar:getPedPreview", function(source, characterId)
    if not characterId then
        return nil, "mp_m_freemode_01"
    end

    if not multichar:ownsCharacter(source, characterId) then
        lib.print.warn(string.format("[wasabi_multichar] getPedPreview: ownership mismatch source=%s characterId=%s", source, characterId))
        return nil, "mp_m_freemode_01"
    end

    return Appearance.getPedPreview(characterId)
end)

RegisterNetEvent("wasabi_multichar:selectCharacter")
AddEventHandler("wasabi_multichar:selectCharacter", function(characterData)
    local src = source
    if not characterData then
        return
    end

    SetPlayerRoutingBucket(src, 0)
    multichar:selectCharacter(src, characterData)
end)

local logoutRestricted = false
if Config.LogoutCommand.onlyStaff then
    logoutRestricted = "wasabi_multichar.staff"
end

lib.addCommand(Config.LogoutCommand.name, {
    help = Config.LogoutCommand.description,
    restricted = logoutRestricted
}, function(source)
    local canLogout, errorMessage = CanPlayerLogout(source)
    if not canLogout then
        lib.notify(source, {
            title = "Logout",
            description = errorMessage,
            type = "error"
        })
        return
    end

    multichar:logout(source)
    TriggerClientEvent("wasabi_multichar:openFromLogout", source)
end)

lib.addCommand(Config.AddVIPCommand.name, {
    help = Config.AddVIPCommand.description,
    restricted = "wasabi_multichar.addvip",
    params = {
        { name = "target", help = "License identifier or player server id" }
    }
}, function(source, args)
    local target = args.target
    local license
    local serverId = tonumber(target)

    if serverId then
        for _, identifier in ipairs(GetPlayerIdentifiers(serverId)) do
            if identifier:match("^license:") then
                license = identifier
                break
            end
        end

        if not license then
            lib.notify(source, {
                title = "AddVIP",
                description = "Player not found",
                type = "error"
            })
            return
        end
    else
        if type(target) == "string" and target:match("^license2?:%x+$") then
            license = target
        else
            lib.notify(source, {
                title = "AddVIP",
                description = "Invalid identifier (expected license:<hex>)",
                type = "error"
            })
            return
        end
    end

    local adminName = GetPlayerName(source) or "admin"
    if vipSlots:addManual(source, license, adminName) then
        lib.notify(source, {
            title = "AddVIP",
            description = "VIP slot added",
            type = "success"
        })
    end
end)

RegisterNetEvent("wasabi_multichar:quit")
AddEventHandler("wasabi_multichar:quit", function()
    local src = source
    DropPlayer(src, locale("dropped_player_message"))
end)

lib.print.debug(string.format("[%s] Server started.", GetCurrentResourceName()))
Modules.resolveEntry("multichar_server")
