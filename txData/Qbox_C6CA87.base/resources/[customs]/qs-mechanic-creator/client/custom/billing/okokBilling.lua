if Config.Billing ~= 'okokBilling' then
    return
end

function OpenBillingMenu(shopId, shopData)
    local nearbyPlayers = GetNearbyPlayers(10.0)

    if #nearbyPlayers == 0 then
        lib.notify({
            title = _U('BILLING') or 'Billing',
            description = _U('NO_NEARBY_PLAYERS') or 'No players nearby',
            type = 'error'
        })
        return
    end

    local playerOptions = {}
    for _, player in ipairs(nearbyPlayers) do
        table.insert(playerOptions, {
            title = player.name,
            description = 'ID: ' .. player.id,
            icon = 'user',
            onSelect = function()
                CreateBillForPlayer(player.id, shopId, shopData)
            end
        })
    end

    lib.registerContext({
        id = 'mechanic_billing_select_player',
        title = _U('SELECT_PLAYER') or 'Select Player to Bill',
        options = playerOptions
    })

    lib.showContext('mechanic_billing_select_player')
end

function CreateBillForPlayer(targetId, shopId, shopData)
    local input = lib.inputDialog(_U('CREATE_BILL') or 'Create Bill', {
        {
            type = 'number',
            label = _U('BILL_AMOUNT') or 'Amount',
            description = _U('BILL_AMOUNT_DESC') or 'Enter the bill amount',
            icon = 'dollar-sign',
            required = true,
            min = 1
        },
        {
            type = 'input',
            label = _U('BILL_REASON') or 'Reason',
            description = _U('BILL_REASON_DESC') or 'Enter the reason for this bill',
            icon = 'file-alt',
            required = true,
            max = 100
        }
    })

    if not input then return end

    local amount = tonumber(input[1])
    local reason = input[2]

    if not amount or amount <= 0 then
        lib.notify({
            title = _U('BILLING') or 'Billing',
            description = _U('INVALID_AMOUNT') or 'Invalid amount',
            type = 'error'
        })
        return
    end

    local shopJob = shopData and shopData.job or 'mechanic'
    TriggerServerEvent('qs-mechanic-creator:server:sendOkokBill', targetId, amount, reason, shopJob, shopId)
end

function GetNearbyPlayers(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                if distance <= radius then
                    table.insert(players, {
                        id = GetPlayerServerId(playerId),
                        name = GetPlayerName(playerId),
                        distance = distance
                    })
                end
            end
        end
    end

    table.sort(players, function(a, b) return a.distance < b.distance end)
    return players
end

function HasBillingSystem()
    return GetResourceState('okokBilling') == 'started'
end
