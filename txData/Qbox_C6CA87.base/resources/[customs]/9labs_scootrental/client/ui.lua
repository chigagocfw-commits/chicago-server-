local UiModule = {
    visible = false
}
ScootUI = UiModule

local activeStationId = nil
local isOpeningPending = false
local isActionPending = false
local nextAllowedOpenTime = 0

function UiModule.close()
    if UiModule.visible then
        nextAllowedOpenTime = GetGameTimer() + 800
    end

    UiModule.visible = false
    activeStationId = nil

    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)

    SendNUIMessage({
        action = "closeMenu"
    })
end

function UiModule.open(stationId)
    if UiModule.visible or isOpeningPending or ScootPlacement.active or GetGameTimer() < nextAllowedOpenTime then
        return
    end

    isOpeningPending = true
    local ok, response = pcall(lib.callback.await, "scootbunker:menu", false, stationId)
    isOpeningPending = false

    if not ok or not response or not response.ok then
        local errorMsg = (response and response.error) or ScootT("connection_error")
        ScootBunker.notify(errorMsg)
        return
    end

    local bunker = ScootBunker.list[stationId]
    if bunker then
        local dist = #(GetEntityCoords(cache.ped) - bunker.coords)
        if dist > ScootConfig.interactDistance then
            return
        end
    end

    UiModule.visible = true
    activeStationId = stationId

    SetNuiFocus(true, true)

    if ScootConfig.debug then
        local ui = ScootConfig.ui or {}
        ScootBunker.debug(string.format(
            "theme accent=%s panel=%s menu=%s/%s,%s rental=%s",
            tostring(ui.accent),
            tostring(ui.panel),
            tostring(ui.menuAnchor),
            tostring(ui.menuOffsetX),
            tostring(ui.menuOffsetY),
            tostring(ui.rentalAnchor)
        ))
    end

    SendNUIMessage({
        action = "openMenu",
        data = response,
        locale = ScootTranslations(),
        theme = ScootTheme()
    })
end

RegisterNUICallback("close", function(_, cb)
    UiModule.close()
    if ScootPlacement.active then
        ScootPlacement.close()
    end
    cb({ ok = true })
end)

local function performRentalAction(actionType, data, cb)
    if not UiModule.visible or not activeStationId or isActionPending then
        cb({ ok = false, error = ScootT("busy") })
        return
    end

    isActionPending = true

    local payload = activeStationId
    if actionType == "rent" then
        payload = {
            id = activeStationId,
            plan = data.plan,
            account = data.account
        }
    end

    local ok, response = pcall(lib.callback.await, "scootbunker:" .. actionType, false, payload)
    isActionPending = false

    if not ok or not response then
        response = { ok = false, error = ScootT("connection_error") }
    end

    cb(response)

    if response.ok then
        if activeStationId == activeStationId then
            UiModule.close()
        end

        local notificationKey = (actionType == "returnRental") and "returned" or "rented"
        lib.notify({
            description = ScootT(notificationKey),
            type = "success"
        })
    end
end

RegisterNUICallback("rent", function(data, cb)
    performRentalAction("rent", data, cb)
end)

RegisterNUICallback("returnRental", function(data, cb)
    performRentalAction("returnRental", data, cb)
end)

RegisterNUICallback("recover", function(data, cb)
    performRentalAction("recover", data, cb)
end)

RegisterNetEvent("scootbunker:notify", function(message)
    if source ~= 65535 then
        return
    end
    lib.notify({
        description = message,
        type = "inform"
    })
end)

RegisterNetEvent("scootbunker:rentalUpdate", function(rentalData)
    if source ~= 65535 then
        return
    end
    SendNUIMessage({
        action = "rentalUpdate",
        rental = rentalData,
        locale = ScootTranslations(),
        theme = ScootTheme()
    })
end)

CreateThread(function()
    while true do
        Wait(750)
        if UiModule.visible then
            local bunker = activeStationId and ScootBunker.list[activeStationId]
            if bunker then
                local isDead = IsEntityDead(cache.ped)
                local dist = #(GetEntityCoords(cache.ped) - bunker.coords)
                if isDead or dist > (ScootConfig.interactDistance + 1.0) then
                    UiModule.close()
                end
            end
        end
    end
end)

CreateThread(function()
    Wait(4000)
    while true do
        local ok, response = pcall(lib.callback.await, "scootbunker:status", false)
        if ok and response and response.ok then
            SendNUIMessage({
                action = "rentalUpdate",
                rental = response.rental or false,
                locale = ScootTranslations(),
                theme = ScootTheme()
            })
        end
        Wait(15000)
    end
end)
