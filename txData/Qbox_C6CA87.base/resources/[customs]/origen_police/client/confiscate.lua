-- Police vehicle confiscation/impound system - Client side

-- Exit if confiscate system is disabled
if not Config.Confiscate then
    return
end

-- Take out impounded vehicle
function TakeOutImpound(vehiclePlate, stationName)
    local spawnCoords = SpawnConfiscatedVehicles[stationName]
    
    if not spawnCoords then
        return ShowNotification("There isn't spawn coords for confiscated vehicles in this station")
    end
    
    FW_TriggerCallback("origen_police:server:TakeOutConfiscatedVehicle", function(vehicleData)
        if not vehicleData then
            return
        end
        
        -- Fade out screen
        DoScreenFadeOut(250)
        Wait(1000)
        
        -- Get vehicle model
        local vehicleModel
        if Config.Framework == "qbcore" and vehicleData.vehicle then
            vehicleModel = vehicleData.vehicle
        else
            vehicleModel = json.decode(vehicleData.vehicle).model
        end
        
        -- Load vehicle model
        RequestModel(vehicleModel)
        while not HasModelLoaded(vehicleModel) do
            Wait(0)
        end
        
        -- Spawn vehicle
        local vehicle = CreateVehicle(
            vehicleModel,
            spawnCoords.x,
            spawnCoords.y,
            spawnCoords.z,
            spawnCoords.w,
            true,
            true
        )
        
        -- Apply vehicle modifications
        local mods
        if Config.Framework == "qbcore" then
            mods = json.decode(vehicleData.mods)
        else
            mods = json.decode(vehicleData.vehicle)
        end
        
        if mods ~= nil and mods ~= {} then
            FW_SetVehicleProperties(vehicle, mods)
        end
        
        -- Set vehicle properties
        SetVehicleNumberPlateText(vehicle, vehicleData.plate)
        SetVehicleDirtLevel(vehicle, 0.0)
        SetEntityHeading(vehicle, spawnCoords.w)
        
        -- Give vehicle keys
        TriggerEvent("vehiclekeys:client:SetOwner", vehicleData.plate)
        
        -- Turn on engine
        SetVehicleEngineOn(vehicle, true, true)
        
        -- Put player in vehicle
        TaskEnterVehicle(PlayerPedId(), vehicle, 2000, -1, 0, 3, 0)
        
        Wait(600)
        DoScreenFadeIn(250)
    end, vehiclePlate)
end

-- Network event: Open confiscated vehicles menu
RegisterNetEvent("origen_police:client:openConfiscatedMenu", function(source, stationName)
    if not Config.Confiscate then
        return ShowNotification("The confiscate system is disabled")
    end
    
    local confiscatedVehicles = nil
    
    -- Get player's confiscated vehicles
    FW_TriggerCallback("origen_police:server:GetPlayerConfiscatedVehicles", function(vehicles)
        confiscatedVehicles = vehicles or {}
    end)
    
    -- Wait for callback
    while confiscatedVehicles == nil do
        Wait(0)
    end
    
    -- Build menu
    local menuItems = {}
    
    -- Header
    menuItems[1] = {
        header = Config.Translations.ImpoundedVehicles,
        isMenuHeader = true
    }
    
    -- Ensure vehicles is a table
    if type(confiscatedVehicles) ~= "table" then
        confiscatedVehicles = {}
    end
    
    -- Add vehicle entries
    for _, vehicleData in pairs(confiscatedVehicles) do
        table.insert(menuItems, {
            header = vehicleData.vehicle .. " - " .. vehicleData.billPrice .. "$",
            txt = vehicleData.plate,
            icon = "fa-solid fa-car",
            params = {
                isAction = true,
                event = function()
                    TakeOutImpound(vehicleData.plate, stationName)
                end
            }
        })
    end
    
    OpenMenu(menuItems)
end)