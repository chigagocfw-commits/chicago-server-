if not Detection or not DUI or not ATM or not UI then
    error("Core modules must be loaded before functions.lua")
end

G_CurrentAtmHandler = {
    setCurrentATM = function(_, entity)
        ATM:setCurrentATM(entity)
    end,

    getCurrentATM = function()
        return ATM:getCurrentATM()
    end,

    getAtmObject = function()
        return ATM:getCurrentATM()
    end,

    getAtmType = function()
        local entity = ATM:getCurrentATM()
        if not entity or not DoesEntityExist(entity) then
            return nil
        end

        return GetEntityModel(entity)
    end,

    setCardObject = function(_, entity)
        ATM:setCurrentCardObject(entity)
    end,

    getCardObject = function()
        return ATM:getCurrentCardObject()
    end,

    clearCardObject = function()
        ATM:clearCardObject()
    end,

    clear = function()
        ATM:clearCardObject()
        ATM:setCurrentATM(nil)
    end,
}

CreateThread(function()
    while true do
        local waitMs = 1000

        if Config.DEBUG and ATM:getCurrentDUI() then
            waitMs = 0

            local cursorX = GetControlNormal(0, 239)
            local cursorY = GetControlNormal(0, 240)

            SetTextFont(4)
            SetTextProportional(true)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 255, 255, 255)
            SetTextEntry("STRING")
            AddTextComponentString(("Cursor: %.4f, %.4f"):format(cursorX, cursorY))
            DrawText(0.5, 0.02)
        end

        Wait(waitMs)
    end
end)

RegisterCommand("atm_debug", function(_, args)
    if args[1] == "on" then
        Config.DEBUG = true
        Debug("ATM Debug mode enabled")
        return
    end

    if args[1] == "off" then
        Config.DEBUG = false
        Debug("ATM Debug mode disabled")
        return
    end

    Config.DEBUG = not Config.DEBUG
    Debug("ATM Debug mode " .. (Config.DEBUG and "enabled" or "disabled"))
end, false)

RegisterCommand("atm_info", function()
    local isNearATM, atmEntity, interactionCoords = Detection.isPlayerCloseToATM()
    if not isNearATM or not atmEntity then
        Debug("Not near an ATM")
        return
    end

    local model = GetEntityModel(atmEntity)
    local atmCoords = GetEntityCoords(atmEntity)
    local playerCoords = GetEntityCoords(PlayerPedId())
    local distance = #(playerCoords - atmCoords)
    local variant = Detection.getVariantForEntity(atmEntity)
    local variantType = (variant and variant.uiType) or "unknown"

    Debug("=== ATM INFO ===")
    Debug(("ATM Model: %d"):format(model))
    Debug(("Variant Type: %s"):format(variantType))
    Debug(("Distance: %.2fm"):format(distance))
    Debug(("ATM Coords: X=%.2f Y=%.2f Z=%.2f"):format(atmCoords.x, atmCoords.y, atmCoords.z))
    Debug(("Player Coords: X=%.2f Y=%.2f Z=%.2f"):format(playerCoords.x, playerCoords.y, playerCoords.z))

    if interactionCoords then
        Debug(("Interaction Coords: X=%.2f Y=%.2f Z=%.2f"):format(
            interactionCoords.x,
            interactionCoords.y,
            interactionCoords.z
        ))
    end

    local dui = ATM:getCurrentDUI()
    if dui then
        Debug("DUI Handle: " .. tostring(dui))
        Debug("DUI is active for this ATM")
    end
end, false)
