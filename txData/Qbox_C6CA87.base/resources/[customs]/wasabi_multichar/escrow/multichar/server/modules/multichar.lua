function GetPlayerPrimaryIdentifier(source)
    if GetConvarInt("sv_fxdkMode", 0) == 1 then
        return "license:fxdk"
    end

    local identifiers = GetPlayerIdentifiers(source)

    for _, id in ipairs(identifiers) do
        if id:match("^license:") then
            return id
        end
    end

    for _, id in ipairs(identifiers) do
        if id:match("^license2:") then
            return id
        end
    end

    for _, id in ipairs(identifiers) do
        if id:match("^steam:") or id:match("^discord:") then
            return id
        end
    end

    return nil
end

function GetPlayerLicense2(source)
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if id:sub(1, #"license2:") == "license2:" then
            return id
        end
    end
    return nil
end

local bridgeModule = nil
local VipSlotsModule = nil

local Multichar = lib.class("Multichar")

function Multichar.init()
    bridgeModule = Modules.get("bridge")
    VipSlotsModule = Modules.require("VipSlots")
end

function Multichar:constructor()
    if not bridgeModule then
        lib.print.error("[wasabi_multichar] Bridge module not found! Make sure a framework bridge is loaded.")
        return
    end

    self.bridge = bridgeModule
    lib.print.debug(string.format("[wasabi_multichar] Using framework: %s", self.bridge.framework or "unknown"))

    self.vipSlots = VipSlotsModule and VipSlotsModule:new() or nil
    self.pendingNewSlots = {}
end

function Multichar:getCharacters(source)
    local identifier = GetPlayerPrimaryIdentifier(source)
    if not identifier then
        lib.print.warn(string.format("[wasabi_multichar] getCharacters: no identifier for source %s", source))
        return {}
    end

    local license2 = GetPlayerLicense2(source)
    local maxSlots = Config.MaxSlots or 5

    if self.vipSlots then
        maxSlots = maxSlots + self.vipSlots:getCount(source)
    end

    return self.bridge.getCharacters(source, identifier, license2, maxSlots)
end

function Multichar:createCharacter(source, characterData)
    local identifier = GetPlayerPrimaryIdentifier(source)
    if not identifier then
        lib.print.warn(string.format("[wasabi_multichar] createCharacter: no identifier for source %s", source))
        return false, "Could not identify player"
    end

    local maxSlots = Config.MaxSlots or 5
    if self.vipSlots then
        maxSlots = maxSlots + self.vipSlots:getCount(source)
    end

    lib.print.debug(string.format("[wasabi_multichar] createCharacter | source=%s maxSlots=%s", source, maxSlots))
    local success, slotOrError = self.bridge.createCharacter(source, identifier, characterData, maxSlots)
    lib.print.debug(string.format("[wasabi_multichar] createCharacter | success=%s slotOrError=%s", tostring(success), tostring(slotOrError)))

    if success and type(slotOrError) == "number" then
        self.pendingNewSlots[source] = slotOrError
    end

    return success, slotOrError
end

function Multichar:giveStarterItems(source, items)
    for _, item in ipairs(items) do
        if item.type == "account" then
            if self.bridge.addMoney then
                self.bridge.addMoney(source, item.name, item.amount)
            end
        elseif item.type == "item" then
            if self.bridge.addItem then
                self.bridge.addItem(source, item.name, item.amount)
            end
        end
    end
end

function Multichar:ownsCharacter(source, characterId)
    if type(characterId) ~= "string" or characterId == "" then
        return false
    end

    local identifier = GetPlayerPrimaryIdentifier(source)
    if not identifier then
        return false
    end

    local license2 = GetPlayerLicense2(source)
    if self.bridge.ownsCharacter then
        return self.bridge.ownsCharacter(identifier, characterId, license2)
    end

    return false
end

function Multichar:deleteCharacter(source, slot, characterId)
    if not Config.AllowDeletion then
        return false, "Character deletion is disabled"
    end

    if Config.DeleteCharacterRestricted then
        if not IsPlayerAceAllowed(source, "wasabi_multichar.delete") then
            return false, "Permission denied"
        end
    end

    local identifier = GetPlayerPrimaryIdentifier(source)
    if not identifier then
        lib.print.warn(string.format("[wasabi_multichar] deleteCharacter: no identifier for source %s", source))
        return false, "Could not identify player"
    end

    local license2 = GetPlayerLicense2(source)
    if type(slot) ~= "number" or slot < 1 or slot ~= math.floor(slot) then
        return false, "Invalid slot"
    end

    if type(characterId) ~= "string" or characterId == "" then
        return false, "Invalid character id"
    end

    local success, message = self.bridge.deleteCharacter(identifier, slot, characterId, license2)
    if success and AfterDeletingCharacter then
        AfterDeletingCharacter(characterId)
    end

    return success, message
end

function Multichar:selectCharacter(source, slot)
    local identifier = GetPlayerPrimaryIdentifier(source)
    if not identifier then
        lib.print.warn(string.format("[wasabi_multichar] selectCharacter: no identifier for source %s", source))
        return
    end

    local isNewCharacter = self.pendingNewSlots[source] == slot
    self.pendingNewSlots[source] = nil

    self.bridge.selectCharacter(source, identifier, slot, isNewCharacter)

    if isNewCharacter then
        local starterItems = nil
        if Config.StarterItems and Config.StarterItems.enabled and Config.StarterItems.items then
            starterItems = Config.StarterItems.items
        end

        if self.bridge.deferStarterItems then
            self.bridge.deferStarterItems(source, starterItems)
        elseif starterItems then
            self:giveStarterItems(source, starterItems)
        end
    end
end

function Multichar:logout(source)
    if self.bridge.logout then
        self.bridge.logout(source)
    end
end

Modules.register("Multichar", Multichar, {
    dependencies = { "VipSlots" },
    optionalDependencies = { "bridge" }
})
