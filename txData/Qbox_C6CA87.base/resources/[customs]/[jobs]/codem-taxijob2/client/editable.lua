-- FIXED VERSION - Addresses notification timing and mission state issues
function CreateCustomer(mission, vehicle)
    Config.Notify(locales.searching_customer)
    if missionActive then
        if DoesEntityExist(customerped) then
            DeleteEntity(customerped)
        end
        if DoesEntityExist(customerped_2) then
            DeleteEntity(customerped_2)
        end
        if DoesEntityExist(customerped_3) then
            DeleteEntity(customerped_3)
        end
        if DoesBlipExist(npcBlip) then
            RemoveBlip(npcBlip)
        end
    end

    taximeter.fare = 0
    setTaximeterData("fare", 0)
    taximeter.customerInVeh = false
    setTaximeterData("customerInVeh", taximeter.customerInVeh)
    changeLocation = false
    Wait(math.random(10000, 15000))
    
    -- Check if mission is still active after the wait
    if not missionActive then
        return
    end
    
    taximeter.playerMode = false
    taximeter.enabled = false
    setTaximeterData("playerMode", taximeter.playerMode)
    setTaximeterData("enabled", taximeter.enabled)
    local payment = math.random(mission.minPayment, mission.maxPayment)
    TriggerServerEvent('codem-taxijob:SetFare', payment)
    taximeter.fare = payment
    setTaximeterData("fare", payment)
    local selectedFinishCoords = mission.finishLocations[math.random(1, #mission.finishLocations)]
    local selectedCoords = mission.npcSpawnLocations[math.random(1, #mission.npcSpawnLocations)]
    local model = Config.NpcModels[math.random(1, #Config.NpcModels)]
    customerped = SpawnPed(model, selectedCoords, false)
    local finished = false
    
    -- Wait a bit before showing customer found notification
    Wait(500)
    Config.Notify(locales.customer_found)
    SetNewWaypoint(selectedCoords.x, selectedCoords.y)
    npcBlip = CreateBlip(selectedCoords, 388, 5, 0.7, locales.taxi_customer, true)
    SetVehicleBodyHealth(vehicle, 1000.0)
    
    CreateThread(function()
        while not taximeter.playerMode and not finished do
            Wait(100)
        end
        if not finished then
            DeleteEntity(customerped)
            DeleteWaypoint()
            RemoveBlip(npcBlip)
        end
    end)
    
    CreateThread(function()
        while not changeLocation do
            Wait(100)
        end
        DeleteEntity(customerped)
        DeleteWaypoint()
        RemoveBlip(npcBlip)
    end)
    
    CreateThread(function()
        local notification = false
        local callcustomer = false
        local finaldest = false
        while missionActive and DoesEntityExist(customerped) and not finaldest do
            local cd = 1000
            local playerCoords = GetEntityCoords(PlayerPedId())
            local customerCoords = GetEntityCoords(customerped)
            local dist = #(playerCoords - vector3(customerCoords.x, customerCoords.y, customerCoords.z))
            if dist < 4.0 and not IsPedInAnyVehicle(customerped) and not finished and not callcustomer then
                cd = 0
                DrawText3D(customerCoords.x, customerCoords.y, customerCoords.z, locales.call_customer)
                if IsControlJustPressed(0, Config.KeyBind.call_customer) then
                    callcustomer = true
                    SetVehicleDoorsLocked(vehicle, 1)
                    TaskEnterVehicle(customerped, vehicle, -1, GetFreeSeat(vehicle), 1.0, 1, 0)
                    while not IsPedInAnyVehicle(customerped) do
                        Wait(0)
                    end
                    local choice = math.random(1, 3)
                    if choice == 1 then
                        taximeter.npcDriveChoice = "careful"
                    elseif choice == 2 then
                        taximeter.npcDriveChoice = "fast"
                        taximeter.time = math.random(50, 100)
                        setTaximeterData("time", taximeter.time)
                        StartTimer(vehicle)
                        setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    elseif choice == 3 then
                        taximeter.npcDriveChoice = false
                    end
                    taximeter.customerInVeh = true
                    setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    setTaximeterData("customerInVeh", taximeter.customerInVeh)
                    SetNewWaypoint(selectedFinishCoords.x, selectedFinishCoords.y)
                    RemoveBlip(npcBlip)
                    Config.Notify(locales.take_customer)
                end
            end
            local finishDist = #(playerCoords - selectedFinishCoords)
            if finishDist < 30.0 and taximeter.customerInVeh then
                cd = 0
                local vehSpeed = GetEntitySpeed(vehicle)
                if not notification then
                    Config.Notify(locales.stop_vehicle)
                    notification = true
                end
                if vehSpeed <= 0.5 then
                    finished = true
                    TaskLeaveVehicle(customerped, vehicle, 0)
                    TaskWanderStandard(customerped, 10.0, 10)
                    local cutpercent = 100 - (math.floor(GetVehicleBodyHealth(vehicle)) / 10)
                    local cut = (taximeter.fare * cutpercent) / 100
                    if taximeter.npcDriveChoice == "careful" then
                        taximeter.fare = taximeter.fare - cut
                    end
                    if taximeter.npcDriveChoice == "fast" then
                        if taximeter.time <= 0 then
                            taximeter.fare = taximeter.fare / 2
                        end
                    end
                    setTaximeterData("fare", taximeter.fare)
                    TriggerServerEvent('codem-taxijob:Pay', taximeter.fare, math.random(mission.minXP, mission.maxXP),
                        key, mission.header)
                    TriggerServerEvent('codem-taxijob:AddDailyMissionProcess', "deliver_npc")
                    taximeter.npcDriveChoice = false
                    setTaximeterData("npcDriveChoice", taximeter.npcDriveChoice)
                    Wait(math.random(12000, 18000))
                    finaldest = true
                    
                    -- Check if mission is still active before creating new customer
                    if missionActive then
                        CreateCustomer(mission, vehicle)
                    end
                end
            end
            if taximeter.npcDriveChoice == 'careful' then
                setTaximeterData("vehicleHealth", math.floor(GetVehicleBodyHealth(vehicle)) / 10)
            end
            Wait(cd)
        end
    end)
end