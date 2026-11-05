

ContractUI = ContractUI or {}
ContractUI.open = nil   -- "seller" | "buyer" | nil
ContractUI.id = nil     -- current contract/paper id
ContractUI.slot = nil   -- seller's vehicle slot

local RESOURCE = GetCurrentResourceName()

local function nui(name, data)
    Client.NUI(name, data)
end

--------------------------------------------------------------------------------
-- UI open / close
--------------------------------------------------------------------------------

function ContractUI.Close()
    if not ContractUI.open then return end

    ContractUI.open = nil
    ContractUI.id = nil
    ContractUI.slot = nil

    Client.ReleaseFocus("contract")
    nui("contract:close")
end

RegisterNetEvent(RESOURCE .. ":client:contractSeller", function(data)
    if Client.Busy() then
        return Client.Notify(_U("contract_busy"), "error")
    end

    Garage.Enrich(data.vehicle)

    ContractUI.open = "seller"
    ContractUI.id = nil
    ContractUI.slot = data.slot

    Client.SetFocus("contract")
    nui("contract:seller", {
        vehicle    = data.vehicle,
        passengers = Utils.Arr(data.passengers),
        slot       = data.slot,
        limits     = data.limits,
        sellerName = data.sellerName,
        date       = data.date,
        now        = data.now,
    })
end)

RegisterNetEvent(RESOURCE .. ":client:contractBuyer", function(data)
    if Client.Busy() then
        -- Try to close other UIs that are holding focus
        if Client.Focus == "garage" and Garage then
            Garage.Close()
        end
        if Client.Focus == "editor" and Editor then
            Editor.Close()
        end

        if Client.Busy() then
            return Client.Notify(_U("contract_busy"), "error")
        end
    end

    Garage.Enrich(data.vehicle)

    if data.now then
        Client.Server.now = data.now
        Client.Server.at = GetGameTimer()
    end

    ContractUI.open = "buyer"
    ContractUI.id = data.id
    ContractUI.slot = nil

    Client.SetFocus("contract")
    nui("contract:buyer", data)
end)

RegisterNetEvent(RESOURCE .. ":client:contractStatus", function(data)
    if not ContractUI.open then return end
    if ContractUI.id and data.id ~= ContractUI.id then return end

    nui("contract:status", data)

    if data.status ~= "signed" then
        local delay = (data.status == "paid") and 4200 or 2600

        SetTimeout(delay, function()
            if not ContractUI.open then return end
            if ContractUI.id and ContractUI.id ~= data.id then return end
            ContractUI.Close()
        end)
    end
end)

--------------------------------------------------------------------------------
-- NUI callbacks
--------------------------------------------------------------------------------

-- Shared handler: notify on result, then reply to the NUI
local function reply(cb, res, successType, failType)
    if res then
        if res.ok then
            if successType then Client.Notify(res.message, successType) end
        else
            Client.Notify(res.message, failType or "error")
        end
    end
    cb(res or { ok = false })
end

RegisterNUICallback("contract:close", function(_, cb)
    cb(1)

    if ContractUI.id then
        Framework.TriggerCallback("contract:cancel", function() end, ContractUI.id)
    end

    ContractUI.Close()
end)

RegisterNUICallback("contract:passengers", function(_, cb)
    Framework.TriggerCallback("contract:passengers", function(list)
        cb(Utils.Arr(list or {}))
    end)
end)

RegisterNUICallback("contract:offer", function(data, cb)
    local price = data and data.price
    local buyer = data and data.buyer
    local slot  = ContractUI.slot or (data and data.slot)

    Framework.TriggerCallback("contract:offer", function(res)
        if res and res.ok then
            ContractUI.id = res.paper and res.paper.id or nil

            if res.paper and res.paper.vehicle then
                Garage.Enrich(res.paper.vehicle)
            end

            Client.Notify(res.message, "success")
        elseif res then
            Client.Notify(res.message, "error")
        end

        cb(res or { ok = false })
    end, price, buyer, slot)
end)

RegisterNUICallback("contract:sign", function(data, cb)
    Framework.TriggerCallback("contract:sign", function(res)
        -- only errors are notified here
        if res and not res.ok then
            Client.Notify(res.message, "error")
        end
        cb(res or { ok = false })
    end, data and data.id)
end)

RegisterNUICallback("contract:pay", function(data, cb)
    Framework.TriggerCallback("contract:pay", function(res)
        reply(cb, res, "success", "error")
    end, data and data.id, data and data.account)
end)

RegisterNUICallback("contract:decline", function(data, cb)
    Framework.TriggerCallback("contract:decline", function(res)
        if res then
            Client.Notify(res.message, res.ok and "info" or "error")
        end
        cb(res or { ok = false })
    end, data and data.id)
end)

RegisterNUICallback("contract:cancel", function(data, cb)
    Framework.TriggerCallback("contract:cancel", function(res)
        if res then
            Client.Notify(res.message, res.ok and "info" or "error")
        end
        cb(res or { ok = false })
        ContractUI.Close()
    end, data and data.id)
end)

--------------------------------------------------------------------------------
-- Demo buyer ped (sits in passenger seat so a contract can be tested)
--------------------------------------------------------------------------------

local demo = { ped = nil, gen = 0 }

local DEMO_MODELS = {
    female = { "a_f_y_business_02", "a_f_y_business_04" },
    male   = { "a_m_y_business_03", "a_m_y_business_02" },
}

-- Removes the current demo ped. If `walkAway` is true the ped leaves the
-- vehicle, wanders off, and is deleted after 20s; otherwise deleted instantly.
local function clearDemoPed(walkAway)
    demo.gen = demo.gen + 1

    local ped = demo.ped
    demo.ped = nil

    TriggerServerEvent(RESOURCE .. ":sv:contractDemoSeated", false)

    if not ped or not DoesEntityExist(ped) then return end

    if not walkAway then
        return DeleteEntity(ped)
    end

    CreateThread(function()
        local veh = GetVehiclePedIsIn(ped, false)
        if veh ~= 0 then
            TaskLeaveVehicle(ped, veh, 0)
            Wait(2600)
        end

        TaskWanderStandard(ped, 10.0, 10)
        Wait(20000)

        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end)
end

-- Finds a spot behind/beside the vehicle to spawn the ped
local function getDemoSpawnPoint(veh)
    local pos = GetOffsetFromEntityInWorldCoords(veh, 5.5, -9.0, 0.0)

    local found, safe = GetSafeCoordForPed(pos.x, pos.y, pos.z, true, 16)
    if found and safe then
        local safePos = vector3(safe.x, safe.y, safe.z)
        if #(safePos - pos) < 12.0 then
            pos = safePos
        end
    end

    local hasGround, groundZ = GetGroundZFor_3dCoord(pos.x, pos.y, pos.z + 2.0, false)
    if hasGround then
        pos = vector3(pos.x, pos.y, groundZ)
    end

    return pos
end

function ContractUI.Demo()
    local playerPed = PlayerPedId()
    local veh = GetVehiclePedIsIn(playerPed, false)

    if veh == 0 or GetPedInVehicleSeat(veh, -1) ~= playerPed then
        return Client.Notify(_U("contract_demo_driver"), "error")
    end

    if demo.ped then
        clearDemoPed(false)
    end

    local seats = GetVehicleModelNumberOfSeats(GetEntityModel(veh))
    if seats < 2 or not IsVehicleSeatFree(veh, 0) then
        return Client.Notify(_U("contract_demo_seat"), "error")
    end

    Framework.TriggerCallback("contract:demo", function(res)
        if not (res and res.ok) then
            return Client.Notify((res and res.message) or _U("no_permission"), "error")
        end

        CreateThread(function()
            -- Pick and load a model
            local pool = res.female and DEMO_MODELS.female or DEMO_MODELS.male
            local model = joaat(pool[math.random(1, #pool)])

            RequestModel(model)
            local started = GetGameTimer()
            while not HasModelLoaded(model) and (GetGameTimer() - started) < 5000 do
                Wait(20)
            end

            if not HasModelLoaded(model) then
                return Client.Notify(_U("contract_demo_lost"), "error")
            end

            -- Spawn ped facing the vehicle
            local spawn = getDemoSpawnPoint(veh)
            local vehPos = GetEntityCoords(veh)
            local heading = GetHeadingFromVector_2d(vehPos.x - spawn.x, vehPos.y - spawn.y)

            local ped = CreatePed(4, model, spawn.x, spawn.y, spawn.z, heading, true, true)
            SetModelAsNoLongerNeeded(model)

            if not DoesEntityExist(ped) then
                return Client.Notify(_U("contract_demo_lost"), "error")
            end

            demo.gen = demo.gen + 1
            local gen = demo.gen
            demo.ped = ped

            SetEntityAsMissionEntity(ped, true, true)
            SetBlockingOfNonTemporaryEvents(ped, true)
            SetPedFleeAttributes(ped, 0, false)
            SetPedCanBeDraggedOut(ped, false)
            SetPedKeepTask(ped, true)
            SetVehicleDoorsLocked(veh, 1)

            Client.Notify(_U("contract_demo_coming", res.name), "info")
            TaskEnterVehicle(ped, veh, 30000, 0, 1.0, 1, 0)

            -- Wait for the ped to sit down (or time out / get cancelled)
            local deadline = GetGameTimer() + 32000
            while gen == demo.gen
                and DoesEntityExist(ped)
                and GetPedInVehicleSeat(veh, 0) ~= ped
                and deadline > GetGameTimer() do
                Wait(250)
            end

            if gen ~= demo.gen or not DoesEntityExist(ped) then return end

            -- Force them in if they didn't make it
            if GetPedInVehicleSeat(veh, 0) ~= ped then
                TaskWarpPedIntoVehicle(ped, veh, 0)
                Wait(300)
            end

            TriggerServerEvent(RESOURCE .. ":sv:contractDemoSeated", true)
            Client.Notify(_U("contract_demo_ready", res.name), "success")
        end)
    end)
end

RegisterNetEvent(RESOURCE .. ":client:contractDemoDone", function()
    SetTimeout(5500, function()
        clearDemoPed(true)
    end)
end)

if Config.Commands.contract then
    RegisterCommand(Config.Commands.contract, function()
        ContractUI.Demo()
    end, false)
end

AddEventHandler("onResourceStop", function(resource)
    if resource == RESOURCE and demo.ped and DoesEntityExist(demo.ped) then
        DeleteEntity(demo.ped)
    end
end)

