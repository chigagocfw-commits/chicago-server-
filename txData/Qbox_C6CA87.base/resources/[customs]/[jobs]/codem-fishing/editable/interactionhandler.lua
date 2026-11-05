function InitMenu()
    if Config.InteractionHandler == 'ox_target' then
        local zones = {
            {
                name = 'fishingjob-menu',
                coords = Config.FishingNPC.Coords,
                event = 'codem-fishingjob:OpenMenu',
                label = 'Open Menu'
            },
            {
                name = 'rent-menu',
                coords = Config.BoatRentPed.Coords,
                event = 'codem-fishingjob:OpenRentMenu',
                label = 'Open Menu'
            }
        }

        for k, v in pairs(Config.DailyDelivery) do
            table.insert(zones, {
                name = k,
                coords = v.npcCoords.coords,
                event = 'codem-fishingjob:client:deliverymission',
                label = 'Delivery Mission'
            })
        end

        for _, zone in ipairs(zones) do
            exports.ox_target:addBoxZone({
                name = zone.name,
                coords = vector3(zone.coords.x, zone.coords.y, zone.coords.z),
                size = vec3(3.6, 3.6, 3.6),
                drawSprite = true,
                options = {
                    {
                        name = zone.name .. '-open',
                        onSelect = function()
                            TriggerEvent(zone.event, zone.name)
                        end,
                        icon = 'fas fa-gears',
                        label = zone.label
                    }
                }
            })
        end
    end
    if Config.InteractionHandler == 'qb_target' then
        local zones = {
            {
                name = 'fishing-menu-open',
                coords = Config.FishingNPC.Coords,
                event = 'codem-fishingjob:OpenMenu',
                label = 'Open Menu'
            },
            {
                name = 'rent-menu-open',
                coords = Config.BoatRentPed.Coords,
                event = 'codem-fishingjob:OpenRentMenu',
                label = 'Open Rent Menu'
            }
        }

        for k, v in pairs(Config.DailyDelivery) do
            table.insert(zones, {
                name = k,
                coords = v.npcCoords.coords,
                event = 'codem-fishingjob:client:deliverymission',
                label = 'Delivery Mission'
            })
        end

        for _, zone in ipairs(zones) do
            exports['qb-target']:AddBoxZone(
                zone.name,
                vector3(zone.coords.x, zone.coords.y, zone.coords.z),
                1.5, 1.6,
                {
                    name = zone.name,
                    heading = 12.0,
                    debugPoly = false,
                    minZ = zone.coords.z - 1,
                    maxZ = zone.coords.z + 2,
                },
                {
                    options = {
                        {
                            num = 1,
                            type = "client",
                            icon = 'fas fa-gears',
                            label = zone.label,
                            targeticon = 'fas fa-gears',
                            action = function()
                                TriggerEvent(zone.event, zone.name)
                            end
                        }
                    },
                    distance = 2.5,
                }
            )
        end
    end
    local validHandlers = {
        qb_textui = true,
        esx_textui = true,
        drawtext = true,
        codem_textui = true,
        okok_textui = true,
        eth_textUi = true
    }

    if validHandlers[Config.InteractionHandler] then
        CreateThread(function()
            local textUiStates = {}
            while true do
                local cd = 1500
                local plyCoords = GetEntityCoords(PlayerPedId())

                local targets = {
                    {
                        id = "fishingnpc",
                        coords = vector3(Config.FishingNPC.Coords.x, Config.FishingNPC.Coords.y,
                            Config.FishingNPC.Coords.z + 1.0),
                        event = 'codem-fishingjob:OpenMenu',
                        value = false,
                        text = Locales[Config.Language]['presse']
                    },
                    {
                        id = "rentmenu",
                        coords = vector3(Config.BoatRentPed.Coords.x, Config.BoatRentPed.Coords.y,
                            Config.BoatRentPed.Coords.z + 1.0),
                        event = 'codem-fishingjob:OpenRentMenu',
                        value = false,
                        text = Locales[Config.Language]['presse']
                    }
                }

                for deliveryName, deliveryData in pairs(Config.DailyDelivery) do
                    table.insert(targets, {
                        id = deliveryName,
                        coords = vector3(deliveryData.npcCoords.coords.x, deliveryData.npcCoords.coords.y,
                            deliveryData.npcCoords.coords.z + 1.0),
                        event = 'codem-fishingjob:client:deliverymission',
                        value = deliveryName,
                        text = Locales[Config.Language]['presse']
                    })
                end

                for _, target in ipairs(targets) do
                    if not textUiStates[target.id] then
                        textUiStates[target.id] = false
                    end
                    local dist = #(target.coords - plyCoords)
                    if dist < 3.00 then
                        cd = 0

                        if not textUiStates[target.id] then
                            OpenTextUI()
                            textUiStates[target.id] = true
                        end

                        if Config.InteractionHandler == 'drawtext' then
                            DrawMarker(2, target.coords, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 255, 255, 255, 255,
                                false, false, false, true, false, false, false)
                            DrawText3D(target.coords.x, target.coords.y, target.coords.z, target.text)
                        end

                        if IsControlJustPressed(0, 38) then
                            TriggerEvent(target.event, target.value)
                        end
                    else
                        if textUiStates[target.id] then
                            CloseTextUI()
                            textUiStates[target.id] = false
                        end
                    end
                end

                Wait(cd)
            end
        end)
    end
end

function OpenTextUI()
    local shopText = Locales[Config.Language]['presse']
    if Config.InteractionHandler == 'codem_textui' then
        exports["codem-textui"]:OpenTextUI(shopText, 'E', 'thema-1')
    elseif Config.InteractionHandler == 'okok_textui' then
        exports['okokTextUI']:Open(shopText, 'green', 'left')
    elseif Config.InteractionHandler == 'eth_textUi' then
        exports['eth-textUi']:Show('', shopText)
    elseif Config.InteractionHandler == 'qb_textui' then
        TriggerEvent('qb-core:client:DrawText', shopText, 'left')
    elseif Config.InteractionHandler == 'esx_textui' then
        TriggerEvent('ESX:TextUI', shopText)
    end
end

function CloseTextUI()
    if Config.InteractionHandler == 'codem_textui' then
        exports["codem-textui"]:CloseTextUI()
    end
    if Config.InteractionHandler == 'okok_textui' then
        exports['okokTextUI']:Close()
    end
    if Config.InteractionHandler == 'eth_textUi' then
        exports['eth-textUi']:Close()
    end
    if Config.InteractionHandler == 'esx_textui' then
        TriggerEvent('ESX:HideUI')
    end
    if Config.InteractionHandler == 'qb_textui' then
        TriggerEvent('qb-core:client:HideText')
    end
end

RegisterNetEvent('codem-fishingjob:OpenMenu', function()
    OpenFishingMenu()
end)
RegisterNetEvent('codem-fishingjob:OpenRentMenu', function()
    OpenFishingRentMenu()
end)

function OpenFishingMenu()
    local invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
    if invehicle then return end

    if not CharacterLoaded then
        return
    end
    local result = TriggerCallback('codem-fishingjob:GetPlayerMoney')

    CreateCamera()
    NuiMessage('OPEN_UI')
    NuiMessage('GET_PLAYER_MONEY', result)
    TriggerServerEvent('codem-fishingjob:getplayerinventory')
    SetNuiFocus(true, true)
end

function OpenFishingRentMenu()
    local invehicle = IsPedInAnyVehicle(PlayerPedId(), false)
    if invehicle then return end

    if not CharacterLoaded then
        return
    end
    NuiMessage('OPEN_RENT_UI')
    SetNuiFocus(true, true)
end

RegisterNUICallback('CloseUI', function(body, resultCallback)
    SetNuiFocus(false, false)
    DestroyCamera()
    resultCallback('ok')

    PlayerData.StartFishing = false
    PlayerData.SelectedBait = {
        itemname = nil,
        amount = 0,
        label = nil,
    }
end)


local cooldownEndTime = 0
Citizen.CreateThread(function()
    local cooldown = 1000
    while true do
        local ped = PlayerPedId()
        local plyCoords = GetEntityCoords(ped)

        for k, v in pairs(Config.RentVehicleDeliveryPoint) do
            local dist = #(v.coords - plyCoords)
            local invehicle = IsPedInAnyVehicle(PlayerPedId(), false)

            if dist < 30.0 and invehicle then
                cooldown = 0
                if v.marker then
                    DrawMarkers(35, v.coords.x, v.coords.y, v.coords.z + 2.0 - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0,
                        2.0,
                        2.0,
                        255, 0, 0, 100, false, true, 2, nil, nil, false)
                end
                if v.text then
                    DrawText3D(v.coords.x, v.coords.y, v.coords.z + 2.0, SelectedLocalesData['vehicledelivery'])
                end

                if IsControlJustPressed(0, 38) then
                    local currentTime = GetGameTimer()
                    if currentTime < cooldownEndTime then
                        Config.Notify(SelectedLocalesData['info'],
                            string.format(Locales[Config.Language]['waitcooldown'],
                                math.ceil((cooldownEndTime - currentTime) / 1000)))
                        break
                    end
                    cooldownEndTime = currentTime + 3000
                    local vehicle = GetVehiclePedIsIn(ped, false)
                    local plate = GetVehicleNumberPlateText(vehicle)
                    if plate == PlayerData.VehiclePlate then
                        SetEntityCoords(ped, Config.TeleportAfterVehicleWipeCoords.x,
                            Config.TeleportAfterVehicleWipeCoords.y,
                            Config.TeleportAfterVehicleWipeCoords.z)
                        SetEntityHeading(ped, Config.TeleportAfterVehicleWipeCoords.w)
                        Citizen.Wait(100)
                        DeleteEntity(vehicle)
                        TriggerServerEvent('codem-fishingjob:depositrentprice')
                        PlayerData.VehiclePlate = nil
                    else
                        Config.Notify(Locales[Config.Language]['error'], Locales[Config.Language]['notvehicle'])
                    end
                end
            end
        end
        Wait(cooldown)
    end
end)
