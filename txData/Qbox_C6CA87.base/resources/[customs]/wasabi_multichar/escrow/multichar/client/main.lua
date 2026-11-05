Modules.initAll()

local PedController = Modules.require("PedController")
local NuiController = Modules.require("NuiController")

local pedController = PedController:new()
local nuiController = NuiController:new(pedController)

exports("OpenUI", function()
    nuiController:open()
end)

exports("CloseUI", function()
    nuiController:close()
end)

exports("IsUIOpen", function()
    return nuiController:isUIOpen()
end)

RegisterNetEvent("wasabi_multichar:openUI")
AddEventHandler("wasabi_multichar:openUI", function()
    nuiController:open()
end)

RegisterNetEvent("wasabi_multichar:openFromLogout")
AddEventHandler("wasabi_multichar:openFromLogout", function()
    TriggerEvent("wasabi_multichar:resetSession")
    nuiController:resetFirstOpen()
    nuiController:open()
end)

RegisterNetEvent("wasabi_multichar:closeUI")
AddEventHandler("wasabi_multichar:closeUI", function()
    nuiController:close()
end)

RegisterNetEvent("wasabimulticharacter:closeNUI")
AddEventHandler("wasabimulticharacter:closeNUI", function()
    nuiController:close()
end)

RegisterNetEvent("wasabi_multichar:slotPurchased")
AddEventHandler("wasabi_multichar:slotPurchased", function()
    nuiController:refreshCharacters()
end)

RegisterNetEvent("wasabi_multichar:refreshCharacters")
AddEventHandler("wasabi_multichar:refreshCharacters", function(slot)
    nuiController:refreshCharacters(nil, slot)
end)

RegisterCommand("multichar", function()
    nuiController:open()
end, false)

AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then
        return
    end

    if pedController then
        pedController:destroy()
    end
end)

Modules.resolveEntry("multichar_client")
